import Foundation
import AppKit

@MainActor
class DownloadSaveManager: ObservableObject {
    static let shared = DownloadSaveManager()
    
    private init() {}
    
    func saveToDownloads(data: Data, baseFilename: String, fileExtension: String = "pdf") async throws -> URL {
        let downloadsURL = try getDownloadsDirectory()
        
        let filename = generateUniqueFilename(
            baseFilename: baseFilename,
            fileExtension: fileExtension,
            in: downloadsURL
        )
        
        let fileURL = downloadsURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    func saveToUserSelectedLocation(data: Data, suggestedFilename: String) async throws -> URL? {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.title = "Save PDF"
        savePanel.message = "Choose where to save your PDF document"
        
        let response = await savePanel.beginSheetModal(for: NSApp.mainWindow!)
        
        guard response == .OK, let url = savePanel.url else {
            return nil
        }
        
        try data.write(to: url)
        
        return url
    }
    
    func showInFinder(url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    private func getDownloadsDirectory() throws -> URL {
        let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        guard let downloadsURL = paths.first else {
            throw DownloadSaveError.downloadsDirectoryNotFound
        }
        return downloadsURL
    }
    
    private func generateUniqueFilename(baseFilename: String, fileExtension: String, in directory: URL) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sanitizedBase = sanitizeFilename(baseFilename)
        var filename = "\(sanitizedBase)_\(timestamp).\(fileExtension)"
        
        var counter = 1
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(filename).path) {
            filename = "\(sanitizedBase)_\(timestamp)_\(counter).\(fileExtension)"
            counter += 1
        }
        
        return filename
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let sanitized = filename.components(separatedBy: invalidCharacters).joined(separator: "-")
        
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmed.isEmpty ? "document" : String(trimmed.prefix(200))
    }
    
    func checkDownloadsPermission() -> Bool {
        do {
            let downloadsURL = try getDownloadsDirectory()
            return FileManager.default.isWritableFile(atPath: downloadsURL.path)
        } catch {
            return false
        }
    }
}

enum DownloadSaveError: LocalizedError {
    case downloadsDirectoryNotFound
    case insufficientPermissions
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .downloadsDirectoryNotFound:
            return "Downloads directory not found"
        case .insufficientPermissions:
            return "Insufficient permissions to save to Downloads folder"
        case .saveFailed(let message):
            return "Failed to save file: \(message)"
        }
    }
}