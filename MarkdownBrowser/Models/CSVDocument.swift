import Foundation
import SwiftUI

/// Represents the structure of CSV data
struct CSVData {
    var headers: [String] = []
    var rows: [[String]] = []
    var delimiter: CSVDelimiter = .comma
    
    /// Total number of rows (excluding header)
    var rowCount: Int {
        rows.count
    }
    
    /// Total number of columns
    var columnCount: Int {
        headers.count
    }
}

/// Supported CSV delimiter types
enum CSVDelimiter: String, CaseIterable {
    case comma = ","
    case tab = "\t"
    case semicolon = ";"
    
    var displayName: String {
        switch self {
        case .comma:
            return "Comma (,)"
        case .tab:
            return "Tab"
        case .semicolon:
            return "Semicolon (;)"
        }
    }
}

/// Represents a CSV document with content and metadata
class CSVDocument: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    
    @Published var content: String = ""
    @Published var csvData: CSVData = CSVData()
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
            
            // Detect delimiter and parse CSV
            csvData.delimiter = detectDelimiter(in: fileContent)
            parseCSV()
            
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
        
        // Re-parse CSV data
        parseCSV()
    }
    
    /// Changes the delimiter and re-parses the content
    func changeDelimiter(_ newDelimiter: CSVDelimiter) {
        csvData.delimiter = newDelimiter
        parseCSV()
    }
    
    /// Detects the most likely delimiter in the content
    private func detectDelimiter(in content: String) -> CSVDelimiter {
        // Count occurrences of each delimiter
        let lines = content.components(separatedBy: .newlines).prefix(10) // Check first 10 lines
        var counts: [CSVDelimiter: Int] = [:]
        
        for delimiter in CSVDelimiter.allCases {
            var count = 0
            for line in lines {
                count += line.components(separatedBy: delimiter.rawValue).count - 1
            }
            counts[delimiter] = count
        }
        
        // Return the delimiter with highest count, default to comma
        return counts.max(by: { $0.value < $1.value })?.key ?? .comma
    }
    
    /// Parses the CSV content into structured data
    private func parseCSV() {
        let parser = CSVParser(delimiter: csvData.delimiter)
        
        do {
            csvData = try parser.parse(content)
        } catch {
            // On parse error, keep the current delimiter but clear the data
            csvData = CSVData(delimiter: csvData.delimiter)
            self.error = DocumentError.invalidFormat
        }
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
    
    /// Gets metadata about the CSV structure
    var metadata: String {
        "\(csvData.rowCount) rows × \(csvData.columnCount) columns"
    }
}

// MARK: - Equatable
extension CSVDocument: Equatable {
    static func == (lhs: CSVDocument, rhs: CSVDocument) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Hashable
extension CSVDocument: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}