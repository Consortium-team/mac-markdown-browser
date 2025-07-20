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
        print("🔍 validateDrop called for target: \(targetNode.name) (isDirectory: \(targetNode.isDirectory))")
        
        // Only allow drops on directories
        guard targetNode.isDirectory else {
            print("❌ validateDrop: Target is not a directory")
            return false
        }
        
        // Check if we have file URLs
        guard info.hasItemsConforming(to: [.fileURL]) else {
            print("❌ validateDrop: No file URLs in drag info")
            return false
        }
        
        // Get the dragged items
        let providers = info.itemProviders(for: [.fileURL])
        
        print("✅ validateDrop: Found \(providers.count) file URL providers")
        
        // For now, we'll do basic validation
        // More complex validation (preventing drops into self/children) will be done in performDrop
        return !providers.isEmpty
    }
    
    /// Called when a drag enters the drop target
    func dropEntered(info: DropInfo) {
        print("📥 dropEntered for target: \(targetNode.name)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = true
        }
        
        // Set up spring-loaded folder expansion
        if targetNode.isDirectory && !targetNode.isExpanded {
            print("⏰ Setting up spring-loaded expansion for: \(targetNode.name)")
            hoverTimer?.invalidate()
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                print("🔓 Expanding directory: \(self.targetNode.name)")
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
        print("🎯 performDrop called for target: \(targetNode.name)")
        print("   Target URL: \(targetNode.url.path)")
        
        isTargeted = false
        
        // Cancel any pending hover timer
        hoverTimer?.invalidate()
        hoverTimer = nil
        
        let providers = info.itemProviders(for: [.fileURL])
        print("📦 Found \(providers.count) item providers")
        
        // Process each provider
        for (index, provider) in providers.enumerated() {
            print("🔄 Processing provider \(index + 1) of \(providers.count)")
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                print("📨 Provider callback executed for provider \(index + 1)")
                
                if let error = error {
                    print("❌ Error loading item: \(error.localizedDescription)")
                    return
                }
                
                // Handle different types of items that might be provided
                var url: URL?
                
                if let data = item as? Data {
                    // Try to create URL from data
                    url = URL(dataRepresentation: data, relativeTo: nil)
                    print("📄 Loaded URL from Data")
                } else if let itemURL = item as? URL {
                    // Direct URL
                    url = itemURL
                    print("🔗 Loaded URL directly")
                } else if let nsurl = item as? NSURL {
                    // NSURL (what we're providing in onDrag)
                    url = nsurl as URL
                    print("🔗 Loaded URL from NSURL")
                } else {
                    print("❌ Unknown item type: \(type(of: item))")
                    return
                }
                
                guard let url = url else {
                    print("❌ Failed to extract URL from item")
                    return
                }
                
                print("📁 Source URL: \(url.path)")
                
                // Perform validation and move on the main thread
                Task { @MainActor in
                    print("🏃 Running on main thread for URL: \(url.lastPathComponent)")
                    
                    // Prevent dropping a file into itself
                    if url == self.targetNode.url {
                        print("❌ Cannot move a directory into itself")
                        return
                    }
                    
                    // Prevent dropping a parent into its child
                    if self.isChildOf(child: self.targetNode.url, parent: url) {
                        print("❌ Cannot move a directory into its subdirectory")
                        return
                    }
                    
                    // Get the file/directory name
                    let fileName = url.lastPathComponent
                    let destinationURL = self.targetNode.url.appendingPathComponent(fileName)
                    
                    print("📍 Destination URL: \(destinationURL.path)")
                    
                    // Check if destination already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        print("❌ A file with the same name already exists at the destination")
                        self.fileSystemVM.errorMessage = "A file named '\(fileName)' already exists in \(self.targetNode.name)"
                        return
                    }
                    
                    // Check if we have access to the source file
                    if !FileManager.default.isReadableFile(atPath: url.path) {
                        print("❌ No read access to source file")
                        self.fileSystemVM.errorMessage = "Cannot read source file. The app may not have permission to access this location."
                        return
                    }
                    
                    // Check if we have write access to destination
                    if !FileManager.default.isWritableFile(atPath: self.targetNode.url.path) {
                        print("❌ No write access to destination directory")
                        self.fileSystemVM.errorMessage = "Cannot write to destination. The app may not have permission to access this location."
                        return
                    }
                    
                    // Perform the move operation
                    print("🚀 Calling moveFile from: \(url.path) to: \(destinationURL.path)")
                    do {
                        try await self.fileSystemVM.moveFile(from: url, to: destinationURL)
                        print("✅ Successfully moved \(url.lastPathComponent) to \(self.targetNode.name)")
                    } catch {
                        print("❌ Failed to move file: \(error)")
                        print("   Error type: \(type(of: error))")
                        print("   Localized description: \(error.localizedDescription)")
                        self.fileSystemVM.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        print("✅ performDrop returning true")
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