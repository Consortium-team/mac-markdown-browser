import Foundation
import Combine

/// Service for handling file system operations with security-scoped bookmarks and real-time monitoring
class FileSystemService: ObservableObject {
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private var fsEventStream: FSEventStreamRef?
    private let fileSystemQueue = DispatchQueue(label: "com.markdownbrowser.filesystem", qos: .userInitiated)
    
    // MARK: - Public Methods
    
    /// Load directory contents with lazy loading support
    /// - Parameter url: Directory URL to load
    /// - Returns: Array of DirectoryNode objects
    func loadDirectory(_ url: URL) async throws -> [DirectoryNode] {
        return try await withCheckedThrowingContinuation { continuation in
            fileSystemQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: FileSystemError.serviceUnavailable)
                    return
                }
                
                do {
                    let options: FileManager.DirectoryEnumerationOptions = UserPreferences.shared.showHiddenFiles ? [] : [.skipsHiddenFiles]
                    let contents = try self.fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey],
                        options: options
                    )
                    
                    let nodes = contents.map { fileURL -> DirectoryNode in
                        return DirectoryNode(url: fileURL)
                    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    
                    continuation.resume(returning: nodes)
                } catch {
                    continuation.resume(throwing: FileSystemError.directoryLoadFailed(url, error))
                }
            }
        }
    }
    
    /// Start monitoring file system changes at the specified URL
    /// - Parameter url: Directory URL to monitor
    /// - Returns: AsyncStream of FileSystemEvent objects
    func monitorChanges(at url: URL) -> AsyncStream<FileSystemEvent> {
        return AsyncStream { continuation in
            fileSystemQueue.async { [weak self] in
                self?.startFSEventsMonitoring(at: url) { event in
                    continuation.yield(event)
                }
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.stopFSEventsMonitoring()
            }
        }
    }
    
    /// Create a security-scoped bookmark for persistent directory access
    /// - Parameter url: Directory URL to create bookmark for
    /// - Returns: Bookmark data or nil if creation failed
    func createBookmark(for url: URL) -> Data? {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmarkData
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            return nil
        }
    }
    
    /// Resolve a security-scoped bookmark to get the URL
    /// - Parameter data: Bookmark data to resolve
    /// - Returns: Resolved URL or nil if resolution failed
    func resolveBookmark(_ data: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("Bookmark is stale, may need to be recreated")
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to start accessing security-scoped resource")
                return nil
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
    
    /// Stop accessing a security-scoped resource
    /// - Parameter url: URL to stop accessing
    func stopAccessingSecurityScopedResource(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
    
    /// Check if a URL is accessible
    /// - Parameter url: URL to check
    /// - Returns: True if accessible, false otherwise
    func isAccessible(_ url: URL) -> Bool {
        return fileManager.isReadableFile(atPath: url.path)
    }
    
    /// Get file attributes for a URL
    /// - Parameter url: File URL to get attributes for
    /// - Returns: File attributes dictionary
    func getFileAttributes(for url: URL) throws -> [FileAttributeKey: Any] {
        return try fileManager.attributesOfItem(atPath: url.path)
    }
    
    /// Move a file or directory to a new location
    /// - Parameters:
    ///   - source: Source URL to move from
    ///   - destination: Destination URL to move to
    /// - Throws: FileSystemError if move fails
    @MainActor
    func moveFile(from source: URL, to destination: URL) async throws {
        print("🚚 FileSystemService.moveFile called")
        print("   Source: \(source.path)")
        print("   Destination: \(destination.path)")
        
        // Check specific error conditions first
        if fileManager.fileExists(atPath: destination.path) {
            print("❌ Destination already exists: \(destination.path)")
            throw FileSystemError.fileExists(destination)
        }
        
        // Validate that we can move the file
        guard canMoveFile(from: source, to: destination) else {
            print("❌ canMoveFile returned false")
            throw FileSystemError.invalidMove(source, destination)
        }
        
        print("✅ Validation passed, proceeding with move")
        
        return try await withCheckedThrowingContinuation { continuation in
            fileSystemQueue.async { [weak self] in
                guard let self = self else {
                    print("❌ Service unavailable (self is nil)")
                    continuation.resume(throwing: FileSystemError.serviceUnavailable)
                    return
                }
                
                do {
                    // Check if source has security-scoped access
                    print("🔐 Attempting security-scoped access for source...")
                    let sourceAccessible = source.startAccessingSecurityScopedResource()
                    print("   Source accessible: \(sourceAccessible)")
                    defer {
                        if sourceAccessible {
                            print("🔓 Stopping security-scoped access for source")
                            source.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Check if destination directory has security-scoped access
                    let destDir = destination.deletingLastPathComponent()
                    print("🔐 Attempting security-scoped access for destination directory: \(destDir.path)")
                    let destAccessible = destDir.startAccessingSecurityScopedResource()
                    print("   Destination directory accessible: \(destAccessible)")
                    defer {
                        if destAccessible {
                            print("🔓 Stopping security-scoped access for destination directory")
                            destDir.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Perform the move
                    print("🏃 Calling FileManager.moveItem...")
                    try self.fileManager.moveItem(at: source, to: destination)
                    print("✅ FileManager.moveItem succeeded")
                    
                    // Notify FSEvents monitoring about the change
                    // The monitoring will automatically pick up the change
                    
                    continuation.resume(returning: ())
                } catch CocoaError.fileWriteFileExists {
                    // File already exists at destination
                    print("❌ CocoaError.fileWriteFileExists")
                    continuation.resume(throwing: FileSystemError.fileExists(destination))
                } catch CocoaError.fileWriteNoPermission {
                    // No permission to write to destination
                    print("❌ CocoaError.fileWriteNoPermission")
                    continuation.resume(throwing: FileSystemError.accessDenied(destination))
                } catch {
                    // Other errors
                    print("❌ Other error: \(error)")
                    print("   Error type: \(type(of: error))")
                    print("   Error domain: \((error as NSError).domain)")
                    print("   Error code: \((error as NSError).code)")
                    continuation.resume(throwing: FileSystemError.moveFailed(source, destination, error))
                }
            }
        }
    }
    
    /// Check if a file can be moved from source to destination
    /// - Parameters:
    ///   - source: Source URL
    ///   - destination: Destination URL
    /// - Returns: True if the move is valid
    func canMoveFile(from source: URL, to destination: URL) -> Bool {
        print("🔍 canMoveFile checking...")
        
        // Can't move to the same location
        if source == destination {
            print("❌ Source equals destination")
            return false
        }
        
        // Can't move a directory into itself or its children
        if isChildOf(child: destination, parent: source) {
            print("❌ Destination is child of source")
            return false
        }
        
        // Check if source exists
        guard fileManager.fileExists(atPath: source.path) else {
            print("❌ Source does not exist: \(source.path)")
            return false
        }
        print("✅ Source exists")
        
        // Check if destination already exists
        if fileManager.fileExists(atPath: destination.path) {
            print("❌ Destination already exists: \(destination.path)")
            return false
        }
        print("✅ Destination does not exist")
        
        // Check if we have read access to source
        guard fileManager.isReadableFile(atPath: source.path) else {
            print("❌ No read access to source: \(source.path)")
            return false
        }
        print("✅ Have read access to source")
        
        // Check if we have write access to destination directory
        let destDir = destination.deletingLastPathComponent()
        guard fileManager.isWritableFile(atPath: destDir.path) else {
            print("❌ No write access to destination directory: \(destDir.path)")
            return false
        }
        print("✅ Have write access to destination directory")
        
        print("✅ All validation checks passed")
        return true
    }
    
    /// Check if a URL is a child of another URL
    /// - Parameters:
    ///   - child: Potential child URL
    ///   - parent: Potential parent URL
    /// - Returns: True if child is under parent
    private func isChildOf(child: URL, parent: URL) -> Bool {
        let childPath = child.path
        let parentPath = parent.path
        
        // Ensure we're comparing normalized paths
        let normalizedChildPath = (childPath as NSString).standardizingPath
        let normalizedParentPath = (parentPath as NSString).standardizingPath
        
        // A path is a child if it starts with the parent path followed by a separator
        return normalizedChildPath.hasPrefix(normalizedParentPath + "/")
    }
    
    // MARK: - Private Methods
    
    private func startFSEventsMonitoring(at url: URL, callback: @escaping (FileSystemEvent) -> Void) {
        let pathsToWatch = [url.path] as CFArray
        let latency: CFTimeInterval = 0.5 // 500ms latency
        
        let context = UnsafeMutablePointer<((FileSystemEvent) -> Void)>.allocate(capacity: 1)
        context.initialize(to: callback)
        
        var fsEventContext = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(context),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        fsEventStream = FSEventStreamCreate(
            nil,
            { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let info = clientCallBackInfo else { return }
                let callback = info.assumingMemoryBound(to: ((FileSystemEvent) -> Void).self).pointee
                
                let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
                
                for i in 0..<numEvents {
                    let path = paths[Int(i)]
                    let flags = eventFlags[Int(i)]
                    let eventId = eventIds[Int(i)]
                    
                    let event = FileSystemEvent(
                        path: path,
                        flags: FileSystemEventFlags(rawValue: flags),
                        eventId: eventId
                    )
                    
                    callback(event)
                }
            },
            &fsEventContext,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )
        
        if let stream = fsEventStream {
            FSEventStreamSetDispatchQueue(stream, fileSystemQueue)
            FSEventStreamStart(stream)
        }
    }
    
    private func stopFSEventsMonitoring() {
        if let stream = fsEventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            fsEventStream = nil
        }
    }
    
    deinit {
        stopFSEventsMonitoring()
    }
}

// MARK: - Supporting Types

/// Represents a file system event
struct FileSystemEvent {
    let path: String
    let flags: FileSystemEventFlags
    let eventId: FSEventStreamEventId
    
    var url: URL {
        return URL(fileURLWithPath: path)
    }
    
    var isCreated: Bool {
        return flags.contains(.itemCreated)
    }
    
    var isModified: Bool {
        return flags.contains(.itemModified)
    }
    
    var isRemoved: Bool {
        return flags.contains(.itemRemoved)
    }
    
    var isRenamed: Bool {
        return flags.contains(.itemRenamed)
    }
}

/// File system event flags
struct FileSystemEventFlags: OptionSet {
    let rawValue: FSEventStreamEventFlags
    
    static let itemCreated = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
    static let itemRemoved = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
    static let itemModified = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))
    static let itemRenamed = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
    static let itemIsFile = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile))
    static let itemIsDir = FileSystemEventFlags(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir))
}

/// File system service errors
enum FileSystemError: Error, LocalizedError {
    case directoryLoadFailed(URL, Error)
    case bookmarkCreationFailed(URL)
    case bookmarkResolutionFailed
    case serviceUnavailable
    case accessDenied(URL)
    case invalidMove(URL, URL)
    case fileExists(URL)
    case moveFailed(URL, URL, Error)
    
    var errorDescription: String? {
        switch self {
        case .directoryLoadFailed(let url, let error):
            return "Failed to load directory at \(url.path): \(error.localizedDescription)"
        case .bookmarkCreationFailed(let url):
            return "Failed to create bookmark for \(url.path)"
        case .bookmarkResolutionFailed:
            return "Failed to resolve security-scoped bookmark"
        case .serviceUnavailable:
            return "File system service is unavailable"
        case .accessDenied(let url):
            return "Access denied to \(url.path)"
        case .invalidMove(let source, let destination):
            return "Cannot move \(source.lastPathComponent) to \(destination.path)"
        case .fileExists(let url):
            return "A file already exists at \(url.path)"
        case .moveFailed(let source, let destination, let error):
            return "Failed to move \(source.lastPathComponent) to \(destination.path): \(error.localizedDescription)"
        }
    }
}