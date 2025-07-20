import SwiftUI

struct DirectoryBrowser2: View {
    @ObservedObject var viewModel: FileSystemViewModel2
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // File browser using OutlineGroup
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.rootItems.isEmpty {
                    Text("No files to display")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredItems) { item in
                            if item.isDirectory && item.children != nil {
                                // Directory with children - use DisclosureGroup
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { viewModel.isExpanded(item) },
                                        set: { _ in viewModel.toggleExpansion(for: item) }
                                    )
                                ) {
                                    // Load children on demand
                                    ChildrenView(
                                        item: item,
                                        viewModel: viewModel,
                                        searchText: searchText
                                    )
                                } label: {
                                    FileRowView(
                                        item: item,
                                        isSelected: viewModel.selectedItem == item,
                                        viewModel: viewModel
                                    )
                                }
                            } else {
                                // File or empty directory
                                FileRowView(
                                    item: item,
                                    isSelected: viewModel.selectedItem == item,
                                    viewModel: viewModel
                                )
                                .onTapGesture {
                                    viewModel.selectItem(item)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var filteredItems: [FileItem] {
        if searchText.isEmpty {
            return viewModel.rootItems
        } else {
            return viewModel.rootItems.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                containsMatchingChild(item)
            }
        }
    }
    
    private func containsMatchingChild(_ item: FileItem) -> Bool {
        guard let children = item.children else { return false }
        return children.contains { child in
            child.name.localizedCaseInsensitiveContains(searchText) ||
            containsMatchingChild(child)
        }
    }
}

// View for loading and displaying children
struct ChildrenView: View {
    let item: FileItem
    @ObservedObject var viewModel: FileSystemViewModel2
    let searchText: String
    @State private var children: [FileItem] = []
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.leading, 20)
            } else {
                ForEach(filteredChildren) { child in
                    if child.isDirectory && child.children != nil {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { viewModel.isExpanded(child) },
                                set: { _ in viewModel.toggleExpansion(for: child) }
                            )
                        ) {
                            ChildrenView(
                                item: child,
                                viewModel: viewModel,
                                searchText: searchText
                            )
                            .padding(.leading, 20)
                        } label: {
                            FileRowView(
                                item: child,
                                isSelected: viewModel.selectedItem == child,
                                viewModel: viewModel
                            )
                        }
                    } else {
                        FileRowView(
                            item: child,
                            isSelected: viewModel.selectedItem == child,
                            viewModel: viewModel
                        )
                        .padding(.leading, 20)
                        .onTapGesture {
                            viewModel.selectItem(child)
                        }
                    }
                }
            }
        }
        .task {
            if children.isEmpty && !isLoading {
                isLoading = true
                children = await viewModel.loadChildren(for: item)
                isLoading = false
            }
        }
    }
    
    private var filteredChildren: [FileItem] {
        if searchText.isEmpty {
            return children
        } else {
            return children.filter { child in
                child.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// Individual file/folder row
struct FileRowView: View {
    let item: FileItem
    let isSelected: Bool
    @ObservedObject var viewModel: FileSystemViewModel2
    @State private var isDropTarget = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: item.fileType.iconName)
                .font(.system(size: 13))
                .foregroundColor(item.isDirectory ? .blue : .secondary)
            
            Text(item.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor : 
                      isDropTarget ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDropTarget ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        // Add drag source for files
        .if(!item.isDirectory) { view in
            view.draggable(item.url)
        }
        // Add drop target for directories
        .if(item.isDirectory) { view in
            view.onDrop(of: [.fileURL], delegate: SimpleDropDelegate(
                item: item,
                viewModel: viewModel,
                isTargeted: $isDropTarget
            ))
        }
    }
}

// Simplified drop delegate
struct SimpleDropDelegate: DropDelegate {
    let item: FileItem
    let viewModel: FileSystemViewModel2
    @Binding var isTargeted: Bool
    
    func validateDrop(info: DropInfo) -> Bool {
        item.isDirectory && info.hasItemsConforming(to: [.fileURL])
    }
    
    func dropEntered(info: DropInfo) {
        isTargeted = true
    }
    
    func dropExited(info: DropInfo) {
        isTargeted = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false
        
        guard let provider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            Task { @MainActor in
                let destinationURL = self.item.url.appendingPathComponent(url.lastPathComponent)
                
                do {
                    try await viewModel.moveFile(from: url, to: destinationURL)
                } catch {
                    print("Failed to move file: \(error)")
                }
            }
        }
        
        return true
    }
}

// Remove this extension as it's already defined in DirectoryPanel.swift