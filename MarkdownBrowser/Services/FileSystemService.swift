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
                    let contents = try self.fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey],
                        options: [.skipsHiddenFiles]
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
        }
    }
}