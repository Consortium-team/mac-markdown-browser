import Foundation
import SwiftUI
import Combine

/// View model for managing file system navigation and directory tree state
class FileSystemViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var rootNode: DirectoryNode?
    @Published var selectedNode: DirectoryNode?
    @Published var expandedNodes: Set<UUID> = []
    @Published var searchText: String = ""
    @Published var showAllFiles: Bool = false
    @Published var showOnlyMarkdownFiles: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let fileSystemService: FileSystemService
    private var cancellables = Set<AnyCancellable>()
    private var fileSystemMonitorTask: Task<Void, Never>?
    private let searchDebouncer = PassthroughSubject<String, Never>()
    
    // MARK: - Computed Properties
    
    var fileFilter: FileFilter {
        showAllFiles ? .allFiles : .markdownOnly
    }
    
    var filteredNodes: [DirectoryNode] {
        guard let root = rootNode else { return [] }
        
        if searchText.isEmpty {
            return filterNodes([root])
        } else {
            return searchNodes([root], matching: searchText)
        }
    }
    
    // MARK: - Initialization
    
    init(fileSystemService: FileSystemService = FileSystemService()) {
        self.fileSystemService = fileSystemService
        setupSearchDebouncer()
    }
    
    deinit {
        fileSystemMonitorTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Navigate to a specific directory
    /// - Parameter url: Directory URL to navigate to
    func navigateToDirectory(_ url: URL) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load directory contents
            let nodes = try await fileSystemService.loadDirectory(url)
            
            await MainActor.run {
                self.rootNode = DirectoryNode(url: url)
                self.rootNode!.children = nodes
                self.expandedNodes.removeAll()
                self.expandedNodes.insert(self.rootNode!.id)
                self.isLoading = false
            }
            
            // Start monitoring for file system changes
            startFileSystemMonitoring(for: url)
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Load children for a directory node
    /// - Parameter node: Directory node to load children for
    func loadChildren(for node: DirectoryNode) async {
        guard node.isDirectory && node.children.isEmpty else { return }
        
        do {
            let children = try await fileSystemService.loadDirectory(node.url)
            
            await MainActor.run {
                node.children = children
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load directory: \(error.localizedDescription)"
            }
        }
    }
    
    /// Toggle expansion state of a directory node
    /// - Parameter node: Directory node to toggle
    func toggleExpansion(for node: DirectoryNode) {
        if expandedNodes.contains(node.id) {
            expandedNodes.remove(node.id)
            node.isExpanded = false
        } else {
            expandedNodes.insert(node.id)
            node.isExpanded = true
            
            // Load children if needed
            if node.children.isEmpty {
                Task {
                    await loadChildren(for: node)
                }
            }
        }
    }
    
    /// Select a node
    /// - Parameter node: Node to select
    func selectNode(_ node: DirectoryNode) {
        selectedNode = node
        
        // If it's a directory, toggle expansion
        if node.isDirectory {
            toggleExpansion(for: node)
        }
    }
    
    /// Navigate with keyboard
    /// - Parameter direction: Navigation direction
    func navigateWithKeyboard(_ direction: KeyboardNavigationDirection) {
        guard let root = rootNode else { return }
        
        let visibleNodes = getVisibleNodes(from: root)
        guard !visibleNodes.isEmpty else { return }
        
        if let selected = selectedNode,
           let currentIndex = visibleNodes.firstIndex(where: { $0.id == selected.id }) {
            
            let newIndex: Int
            switch direction {
            case .up:
                newIndex = max(0, currentIndex - 1)
            case .down:
                newIndex = min(visibleNodes.count - 1, currentIndex + 1)
            case .left:
                // Collapse if expanded, otherwise select parent
                if selected.isDirectory && expandedNodes.contains(selected.id) {
                    toggleExpansion(for: selected)
                    return
                } else if let parent = findParent(of: selected, in: root) {
                    selectNode(parent)
                    return
                }
                newIndex = currentIndex
            case .right:
                // Expand if directory
                if selected.isDirectory && !expandedNodes.contains(selected.id) {
                    toggleExpansion(for: selected)
                    return
                }
                newIndex = currentIndex
            }
            
            if newIndex != currentIndex {
                selectNode(visibleNodes[newIndex])
            }
        } else {
            // No selection, select first node
            selectNode(visibleNodes[0])
        }
    }
    
    /// Refresh current directory
    func refresh() async {
        if let root = rootNode {
            await navigateToDirectory(root.url)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebouncer() {
        searchDebouncer
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
        
        $searchText
            .sink { [weak self] text in
                self?.searchDebouncer.send(text)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ searchText: String) {
        // Search is performed via computed property filteredNodes
        // This method is here for future enhancements
    }
    
    private func filterNodes(_ nodes: [DirectoryNode]) -> [DirectoryNode] {
        nodes.flatMap { node -> [DirectoryNode] in
            var result: [DirectoryNode] = []
            
            // Check if node matches filter
            if node.isDirectory || (fileFilter == .allFiles || node.isMarkdownFile) {
                result.append(node)
            }
            
            // Recursively filter children if expanded
            if expandedNodes.contains(node.id) && !node.children.isEmpty {
                result.append(contentsOf: filterNodes(node.children))
            }
            
            return result
        }
    }
    
    private func searchNodes(_ nodes: [DirectoryNode], matching searchText: String) -> [DirectoryNode] {
        let lowercasedSearch = searchText.lowercased()
        
        return nodes.flatMap { node -> [DirectoryNode] in
            var result: [DirectoryNode] = []
            
            // Check if node name contains search text
            if node.name.lowercased().contains(lowercasedSearch) {
                if node.isDirectory || (fileFilter == .allFiles || node.isMarkdownFile) {
                    result.append(node)
                }
            }
            
            // Always search in children, regardless of expansion state during search
            if !node.children.isEmpty {
                result.append(contentsOf: searchNodes(node.children, matching: searchText))
            }
            
            return result
        }
    }
    
    private func getVisibleNodes(from node: DirectoryNode) -> [DirectoryNode] {
        var visibleNodes: [DirectoryNode] = []
        
        func collectVisibleNodes(_ node: DirectoryNode, level: Int = 0) {
            if level > 0 { // Don't include root node
                visibleNodes.append(node)
            }
            
            if expandedNodes.contains(node.id) {
                for child in node.children {
                    collectVisibleNodes(child, level: level + 1)
                }
            }
        }
        
        collectVisibleNodes(node)
        return visibleNodes
    }
    
    private func findParent(of node: DirectoryNode, in root: DirectoryNode) -> DirectoryNode? {
        if root.children.contains(where: { $0.id == node.id }) {
            return root
        }
        
        for child in root.children where child.isDirectory {
            if let parent = findParent(of: node, in: child) {
                return parent
            }
        }
        
        return nil
    }
    
    private func startFileSystemMonitoring(for url: URL) {
        // Cancel existing monitoring
        fileSystemMonitorTask?.cancel()
        
        // Start new monitoring
        fileSystemMonitorTask = Task { [weak self] in
            let eventStream = self?.fileSystemService.monitorChanges(at: url)
            
            guard let eventStream = eventStream else { return }
            
            for await event in eventStream {
                guard !Task.isCancelled else { break }
                
                // Handle file system events
                await self?.handleFileSystemEvent(event)
            }
        }
    }
    
    private func handleFileSystemEvent(_ event: FileSystemEvent) async {
        // Refresh the directory if something changed
        if event.isCreated || event.isRemoved || event.isRenamed || event.isModified {
            await refresh()
        }
    }
}

// MARK: - Supporting Types

enum KeyboardNavigationDirection {
    case up
    case down
    case left
    case right
}

enum FileFilter {
    case markdownOnly
    case allFiles
}

// MARK: - DirectoryNode Extensions

extension DirectoryNode {
    var isMarkdownFile: Bool {
        guard !isDirectory else { return false }
        return url.pathExtension.lowercased() == "md"
    }
}