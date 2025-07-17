import Foundation
import SwiftUI

/// Represents a Markdown document with content and metadata
class MarkdownDocument: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    
    @Published var content: String = ""
    @Published var renderedHTML: String = ""
    @Published var isLoading = false
    @Published var hasUnsavedChanges = false
    @Published var lastModified: Date?
    @Published var error: DocumentError?
    
    private var originalContent: String = ""
    private var fileSystemWatcher: DispatchSourceFileSystemObject?
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
    
    deinit {
        stopWatchingFile()
    }
    
    /// Loads the document content from disk
    @MainActor
    func loadContent() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            content = fileContent
            originalContent = fileContent
            hasUnsavedChanges = false
            
            // Get file modification date
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            lastModified = attributes[.modificationDate] as? Date
            
            startWatchingFile()
        } catch {
            self.error = DocumentError.loadFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Saves the document content to disk
    @MainActor
    func saveContent() async {
        guard hasUnsavedChanges else { return }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            originalContent = content
            hasUnsavedChanges = false
            
            // Update modification date
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            lastModified = attributes[.modificationDate] as? Date
            
            error = nil
        } catch {
            self.error = DocumentError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Updates the content and tracks changes
    func updateContent(_ newContent: String) {
        content = newContent
        hasUnsavedChanges = (content != originalContent)
    }
    
    /// Reloads the document from disk, discarding unsaved changes
    @MainActor
    func reloadFromDisk() async {
        await loadContent()
    }
    
    /// Checks if the file has been modified externally
    func hasExternalChanges() -> Bool {
        guard let lastModified = lastModified else { return false }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let currentModified = attributes[.modificationDate] as? Date
            return currentModified != lastModified
        } catch {
            return false
        }
    }
    
    /// Starts watching the file for external changes
    private func startWatchingFile() {
        stopWatchingFile()
        
        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        fileSystemWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        fileSystemWatcher?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.handleExternalFileChange()
            }
        }
        
        fileSystemWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileSystemWatcher?.resume()
    }
    
    /// Stops watching the file for changes
    private func stopWatchingFile() {
        fileSystemWatcher?.cancel()
        fileSystemWatcher = nil
    }
    
    /// Handles external file changes
    @MainActor
    private func handleExternalFileChange() {
        if hasExternalChanges() {
            if hasUnsavedChanges {
                error = DocumentError.conflictDetected
            } else {
                Task {
                    await reloadFromDisk()
                }
            }
        }
    }
    
    /// Gets the file size in bytes
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Gets a formatted file size string
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Checks if the document is a Markdown file
    var isMarkdownFile: Bool {
        return url.pathExtension.lowercased() == "md"
    }
}

// MARK: - DocumentError
enum DocumentError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case conflictDetected
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load document: \(message)"
        case .saveFailed(let message):
            return "Failed to save document: \(message)"
        case .conflictDetected:
            return "The file has been modified externally. Please resolve the conflict."
        case .invalidFormat:
            return "The file format is not supported."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadFailed:
            return "Check if the file exists and you have permission to read it."
        case .saveFailed:
            return "Check if you have permission to write to this location."
        case .conflictDetected:
            return "Save your changes to a different location or reload the file to discard changes."
        case .invalidFormat:
            return "Please select a valid Markdown file."
        }
    }
}

// MARK: - Equatable
extension MarkdownDocument: Equatable {
    static func == (lhs: MarkdownDocument, rhs: MarkdownDocument) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Hashable
extension MarkdownDocument: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}