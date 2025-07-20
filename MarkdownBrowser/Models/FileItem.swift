import Foundation
import SwiftUI

/// A simple file item model for use with SwiftUI's OutlineGroup
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let fileType: FileType
    var children: [FileItem]?
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.fileType = FileType(from: url)
        
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        
        // Children will be loaded lazily
        self.children = isDirectory ? [] : nil
    }
    
    /// Load children for this directory
    mutating func loadChildren() throws {
        guard isDirectory else { return }
        
        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        children = contents
            .map { FileItem(url: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Check if this item matches the file filter
    func matchesFilter(_ filter: FileFilter) -> Bool {
        guard !isDirectory else { return true }
        
        switch filter {
        case .allFiles:
            return true
        case .markdownOnly:
            return fileType == .markdown
        case .supportedDocuments:
            return fileType.isSupported
        }
    }
}

// Make FileItem Equatable based on URL
extension FileItem: Equatable {
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}