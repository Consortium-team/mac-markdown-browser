import SwiftUI
import UniformTypeIdentifiers

/// Delegate for handling drag and drop operations on directory nodes
class FileDragDelegate: DropDelegate {
    let targetNode: DirectoryNode
    let fileSystemVM: FileSystemViewModel
    @Binding var isTargeted: Bool
    private var hoverTimer: Timer?
    
    init(targetNode: DirectoryNode, fileSystemVM: FileSystemViewModel, isTargeted: Binding<Bool>) {
        self.targetNode = targetNode
        self.fileSystemVM = fileSystemVM
        self._isTargeted = isTargeted
    }
    
    /// Validates whether the drop operation is allowed
    func validateDrop(info: DropInfo) -> Bool {
        // Only allow drops on directories
        guard targetNode.isDirectory else { return false }
        
        // Check if we have file URLs
        guard info.hasItemsConforming(to: [.fileURL]) else { return false }
        
        // Get the dragged items
        let providers = info.itemProviders(for: [.fileURL])
        
        // For now, we'll do basic validation
        // More complex validation (preventing drops into self/children) will be done in performDrop
        return !providers.isEmpty
    }
    
    /// Called when a drag enters the drop target
    func dropEntered(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = true
        }
        
        // Set up spring-loaded folder expansion
        if targetNode.isDirectory && !targetNode.isExpanded {
            hoverTimer?.invalidate()
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                Task { @MainActor in
                    await self.targetNode.toggleExpanded()
                }
            }
        }
    }
    
    /// Called when a drag exits the drop target
    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = false
        }
        
        // Cancel spring-loaded folder expansion
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    /// Called when the drag location changes within the drop target
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Return a drop proposal indicating we want to move (not copy) the files
        return DropProposal(operation: .move)
    }
    
    /// Performs the actual drop operation
    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false
        
        // Cancel any pending hover timer
        hoverTimer?.invalidate()
        hoverTimer = nil
        
        let providers = info.itemProviders(for: [.fileURL])
        
        // Process each provider
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    
                    // Perform validation and move on the main thread
                    Task { @MainActor in
                        // Prevent dropping a file into itself
                        if url == self.targetNode.url {
                            print("Cannot move a directory into itself")
                            return
                        }
                        
                        // Prevent dropping a parent into its child
                        if self.isChildOf(child: self.targetNode.url, parent: url) {
                            print("Cannot move a directory into its subdirectory")
                            return
                        }
                        
                        // Get the file/directory name
                        let fileName = url.lastPathComponent
                        let destinationURL = self.targetNode.url.appendingPathComponent(fileName)
                        
                        // Check if destination already exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            print("A file with the same name already exists at the destination")
                            self.fileSystemVM.errorMessage = "A file named '\(fileName)' already exists in \(self.targetNode.name)"
                            return
                        }
                        
                        // Perform the move operation
                        do {
                            try await self.fileSystemVM.moveFile(from: url, to: destinationURL)
                            print("Successfully moved \(url.lastPathComponent) to \(self.targetNode.name)")
                        } catch {
                            print("Failed to move file: \(error.localizedDescription)")
                            self.fileSystemVM.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        
        // Return true to indicate we accepted the drop (even if individual moves might fail)
        return true
    }
    
    /// Checks if a URL is a child of another URL
    private func isChildOf(child: URL, parent: URL) -> Bool {
        let childPath = child.path
        let parentPath = parent.path
        
        // Ensure we're comparing normalized paths
        let normalizedChildPath = (childPath as NSString).standardizingPath
        let normalizedParentPath = (parentPath as NSString).standardizingPath
        
        // A path is a child if it starts with the parent path followed by a separator
        return normalizedChildPath.hasPrefix(normalizedParentPath + "/")
    }
}