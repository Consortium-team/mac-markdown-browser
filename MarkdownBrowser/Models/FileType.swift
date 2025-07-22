import Foundation

/// Represents supported file types in the browser
enum FileType: CaseIterable {
    case markdown
    case html
    case csv
    case directory
    case other
    
    /// Initialize from a URL
    init(from url: URL) {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        
        if isDir.boolValue {
            self = .directory
        } else {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "md", "markdown":
                self = .markdown
            case "html", "htm":
                self = .html
            case "csv", "tsv":
                self = .csv
            default:
                self = .other
            }
        }
    }
    
    /// Get the appropriate SF Symbol icon for this file type
    var iconName: String {
        switch self {
        case .markdown:
            return "doc.text"
        case .html:
            return "doc.richtext"
        case .csv:
            return "tablecells"
        case .directory:
            return "folder"
        case .other:
            return "doc"
        }
    }
    
    /// Check if this is a supported document type
    var isSupported: Bool {
        switch self {
        case .markdown, .html, .csv:
            return true
        case .directory, .other:
            return false
        }
    }
}

/// Extension to URL for file type detection
extension URL {
    var fileType: FileType {
        FileType(from: self)
    }
    
    var isMarkdownFile: Bool {
        fileType == .markdown
    }
    
    var isHTMLFile: Bool {
        fileType == .html
    }
    
    var isCSVFile: Bool {
        fileType == .csv
    }
    
    var isSupportedDocument: Bool {
        fileType.isSupported
    }
}