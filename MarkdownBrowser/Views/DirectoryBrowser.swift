import SwiftUI

struct DirectoryBrowser: View {
    @ObservedObject var fileSystemVM: FileSystemViewModel
    @State private var searchQuery = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search in current directory...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch()
                    }
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Directory tree
            ScrollView {
                if let rootNode = fileSystemVM.rootNode {
                    VStack(alignment: .leading, spacing: 0) {
                        DirectoryNodeView(
                            node: rootNode,
                            fileSystemVM: fileSystemVM,
                            searchQuery: searchQuery
                        )
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack {
                        Text("No directory selected")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .keyboardNavigation(fileSystemVM: fileSystemVM)
        .onAppear {
            isFocused = true
        }
    }
    
    private func performSearch() {
        // Search functionality will be enhanced later
        // For now, the search query filters nodes in DirectoryNodeView
    }
}

struct DirectoryNodeView: View {
    @ObservedObject var node: DirectoryNode
    @ObservedObject var fileSystemVM: FileSystemViewModel
    let searchQuery: String
    let indentLevel: Int = 0
    
    private var shouldShow: Bool {
        searchQuery.isEmpty || node.name.localizedCaseInsensitiveContains(searchQuery)
    }
    
    private var filteredChildren: [DirectoryNode] {
        if fileSystemVM.showOnlyMarkdownFiles {
            return node.markdownFilteredChildren
        }
        return node.children
    }
    
    var body: some View {
        if shouldShow || hasMatchingChildren {
            VStack(alignment: .leading, spacing: 0) {
                // Node row
                HStack(spacing: 4) {
                    // Indentation
                    ForEach(0..<indentLevel, id: \.self) { _ in
                        Spacer()
                            .frame(width: 20)
                    }
                    
                    // Expansion chevron for directories
                    if node.isDirectory {
                        Button(action: {
                            Task {
                                await node.toggleExpanded()
                            }
                        }) {
                            Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                            .frame(width: 16)
                    }
                    
                    // Icon
                    Image(systemName: node.isDirectory ? "folder" : "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(node.isDirectory ? .accentColor : .secondary)
                    
                    // Name
                    Text(node.name)
                        .font(.system(size: 12))
                        .foregroundColor(fileSystemVM.selectedNode == node ? .white : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    // Loading indicator
                    if node.isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fileSystemVM.selectedNode == node ? Color.accentColor : Color.clear)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if !node.isDirectory {
                        fileSystemVM.selectNode(node)
                    } else {
                        Task {
                            await node.toggleExpanded()
                        }
                    }
                }
                .contextMenu {
                    if node.isDirectory {
                        Button("Open in Finder") {
                            NSWorkspace.shared.open(node.url)
                        }
                        Divider()
                        Button("Refresh") {
                            Task {
                                await node.refresh()
                            }
                        }
                    } else {
                        Button("Open in Default App") {
                            NSWorkspace.shared.open(node.url)
                        }
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([node.url])
                        }
                    }
                }
                
                // Children (if expanded)
                if node.isDirectory && node.isExpanded {
                    ForEach(filteredChildren) { child in
                        DirectoryNodeView(
                            node: child,
                            fileSystemVM: fileSystemVM,
                            searchQuery: searchQuery
                        )
                        .environment(\.indentLevel, indentLevel + 1)
                    }
                }
            }
        }
    }
    
    private var hasMatchingChildren: Bool {
        if searchQuery.isEmpty { return true }
        return filteredChildren.contains { child in
            child.name.localizedCaseInsensitiveContains(searchQuery) ||
            (child.isDirectory && hasMatchingChildrenRecursive(child))
        }
    }
    
    private func hasMatchingChildrenRecursive(_ node: DirectoryNode) -> Bool {
        let children = fileSystemVM.showOnlyMarkdownFiles ? node.markdownFilteredChildren : node.children
        return children.contains { child in
            child.name.localizedCaseInsensitiveContains(searchQuery) ||
            (child.isDirectory && hasMatchingChildrenRecursive(child))
        }
    }
}

// Environment key for indent level
private struct IndentLevelKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    var indentLevel: Int {
        get { self[IndentLevelKey.self] }
        set { self[IndentLevelKey.self] = newValue }
    }
}

#Preview {
    DirectoryBrowser(fileSystemVM: FileSystemViewModel())
        .frame(width: 350, height: 600)
}