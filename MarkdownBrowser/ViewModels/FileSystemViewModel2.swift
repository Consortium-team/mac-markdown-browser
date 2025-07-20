import Foundation
import SwiftUI
import Combine

/// Simplified view model using FileItem for OutlineGroup
class FileSystemViewModel2: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var rootItems: [FileItem] = []
    @Published var selectedItem: FileItem?
    @Published var expandedItems: Set<FileItem> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var fileFilter: FileFilter = .supportedDocuments
    
    // MARK: - Private Properties
    
    private let fileSystemService: FileSystemService
    private var fileSystemMonitorTask: Task<Void, Never>?
    private var rootURL: URL?
    
    // MARK: - Initialization
    
    init(fileSystemService: FileSystemService = FileSystemService()) {
        self.fileSystemService = fileSystemService
    }
    
    // MARK: - Public Methods
    
    /// Navigate to a directory and load its contents
    @MainActor
    func navigateToDirectory(_ url: URL) async {
        isLoading = true
        errorMessage = nil
        rootURL = url
        
        do {
            var rootItem = FileItem(url: url)
            try rootItem.loadChildren()
            
            // Filter children based on current filter
            if let children = rootItem.children {
                rootItem.children = children.filter { $0.matchesFilter(fileFilter) }
            }
            
            rootItems = rootItem.children ?? []
            expandedItems.removeAll()
            isLoading = false
            
            // Start monitoring for changes
            startFileSystemMonitoring(for: url)
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Load children for a directory item
    @MainActor
    func loadChildren(for item: FileItem) async -> [FileItem] {
        guard item.isDirectory else { return [] }
        
        do {
            var mutableItem = item
            try mutableItem.loadChildren()
            
            // Filter children based on current filter
            if let children = mutableItem.children {
                return children.filter { $0.matchesFilter(fileFilter) }
            }
            return []
            
        } catch {
            print("Failed to load children for \(item.name): \(error)")
            return []
        }
    }
    
    /// Move a file from source to destination
    @MainActor
    func moveFile(from source: URL, to destination: URL) async throws {
        do {
            // Perform the move
            try await fileSystemService.moveFile(from: source, to: destination)
            
            // Reload the root directory to reflect changes
            if let rootURL = rootURL {
                await navigateToDirectory(rootURL)
                
                // Try to maintain expanded state
                // Note: This is simplified - in production you'd map old items to new
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Select a file item
    func selectItem(_ item: FileItem?) {
        selectedItem = item
    }
    
    /// Toggle expansion state for an item
    func toggleExpansion(for item: FileItem) {
        if expandedItems.contains(item) {
            expandedItems.remove(item)
        } else {
            expandedItems.insert(item)
        }
    }
    
    /// Check if an item is expanded
    func isExpanded(_ item: FileItem) -> Bool {
        expandedItems.contains(item)
    }
    
    /// Refresh the current directory
    func refresh() async {
        if let rootURL = rootURL {
            await navigateToDirectory(rootURL)
        }
    }
    
    // MARK: - Private Methods
    
    private func startFileSystemMonitoring(for url: URL) {
        // Cancel existing monitoring
        fileSystemMonitorTask?.cancel()
        
        // Start new monitoring
        fileSystemMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            let eventStream = self.fileSystemService.monitorChanges(at: url)
            
            for await event in eventStream {
                if !Task.isCancelled {
                    await self.handleFileSystemEvent(event)
                }
            }
        }
    }
    
    private func handleFileSystemEvent(_ event: FileSystemEvent) async {
        // Refresh on any change
        if event.isCreated || event.isRemoved || event.isRenamed || event.isModified {
            await refresh()
        }
    }
    
    deinit {
        fileSystemMonitorTask?.cancel()
    }
}