import Foundation
import SwiftUI

/// Represents a node in the file system tree structure
class DirectoryNode: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let fileType: FileType
    
    @Published var children: [DirectoryNode] = []
    @Published var isExpanded = false
    @Published var isLoading = false
    
    private var hasLoadedChildren = false
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.fileType = FileType(from: url)
        
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
    }
    
    /// Lazily loads children for directory nodes
    @MainActor
    func loadChildren() async {
        guard isDirectory && !hasLoadedChildren else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let options: FileManager.DirectoryEnumerationOptions = UserPreferences.shared.showHiddenFiles ? [] : [.skipsHiddenFiles]
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: options
            )
            
            let sortedContents = contents.sorted { url1, url2 in
                // Directories first, then files, both alphabetically
                let isDir1 = (try? url1.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let isDir2 = (try? url2.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                
                if isDir1 != isDir2 {
                    return isDir1 && !isDir2
                }
                return url1.lastPathComponent.localizedCaseInsensitiveCompare(url2.lastPathComponent) == .orderedAscending
            }
            
            children = sortedContents.map { DirectoryNode(url: $0) }
            hasLoadedChildren = true
        } catch {
            print("Error loading directory contents for \(url.path): \(error)")
            children = []
        }
    }
    
    /// Toggles the expanded state and loads children if needed
    @MainActor
    func toggleExpanded() async {
        if !isExpanded && !hasLoadedChildren {
            await loadChildren()
        }
        isExpanded.toggle()
    }
    
    /// Filters children to show only supported document files and directories
    var supportedDocumentFilteredChildren: [DirectoryNode] {
        children.filter { node in
            node.isDirectory || node.fileType.isSupported
        }
    }
    
    /// Legacy property for backward compatibility
    var markdownFilteredChildren: [DirectoryNode] {
        supportedDocumentFilteredChildren
    }
    
    /// Searches for nodes matching the given query
    func search(query: String) -> [DirectoryNode] {
        var results: [DirectoryNode] = []
        
        // Check if current node matches
        if name.localizedCaseInsensitiveContains(query) {
            results.append(self)
        }
        
        // Search children recursively
        for child in children {
            results.append(contentsOf: child.search(query: query))
        }
        
        return results
    }
    
    /// Finds a child node by URL
    func findChild(with url: URL) -> DirectoryNode? {
        if self.url == url {
            return self
        }
        
        for child in children {
            if let found = child.findChild(with: url) {
                return found
            }
        }
        
        return nil
    }
    
    /// Refreshes the node by reloading its children
    @MainActor
    func refresh() async {
        guard isDirectory else { return }
        
        print("🔄 DirectoryNode.refresh() called for: \(name)")
        
        // Show loading state
        isLoading = true
        
        // Force SwiftUI to notice the change by explicitly triggering objectWillChange
        objectWillChange.send()
        
        // Remember expanded state
        let wasExpanded = isExpanded
        
        // Clear existing state
        hasLoadedChildren = false
        children = []
        
        // Always reload children to get fresh state
        await loadChildren()
        
        // Restore expanded state
        isExpanded = wasExpanded
        
        // Trigger again after loading to ensure the view updates
        objectWillChange.send()
        
        // Hide loading state
        isLoading = false
        
        print("✅ DirectoryNode.refresh() completed for: \(name), children count: \(children.count)")
    }
}

// MARK: - Equatable
extension DirectoryNode: Equatable {
    static func == (lhs: DirectoryNode, rhs: DirectoryNode) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Hashable
extension DirectoryNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}