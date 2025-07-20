import SwiftUI

struct StandardContentView: View {
    @StateObject private var fileManager = StandardFileManager()
    @State private var selectedFile: FileItem?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - Standard macOS source list
            List(selection: $selectedFile) {
                Section("Favorites") {
                    ForEach(fileManager.favorites) { item in
                        FileListRow(item: item)
                            .tag(item)
                    }
                }
                
                Section("Documents") {
                    ForEach(fileManager.rootItems, id: \.self) { item in
                        if item.isDirectory {
                            DisclosureGroup {
                                ForEach(item.children ?? []) { child in
                                    FileListRow(item: child)
                                        .tag(child)
                                }
                            } label: {
                                Label(item.name, systemImage: "folder")
                            }
                        } else {
                            FileListRow(item: item)
                                .tag(item)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Files")
            .frame(minWidth: 250)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
        } detail: {
            // Detail view - File preview
            if let selectedFile = selectedFile {
                FilePreviewView(fileURL: selectedFile.url)
                    .navigationTitle(selectedFile.name)
                    .navigationSubtitle(selectedFile.url.path)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a File")
                        .font(.title)
                        .padding(.top)
                    Text("Choose a file from the sidebar to preview")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct FileListRow: View {
    let item: FileItem
    
    var body: some View {
        Label {
            Text(item.name)
        } icon: {
            Image(systemName: item.fileType.iconName)
                .foregroundColor(item.isDirectory ? .blue : .secondary)
        }
    }
}

// Simple file manager for standard file operations
class StandardFileManager: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var favorites: [FileItem] = []
    private let fileSystemService = FileSystemService()
    
    init() {
        loadInitialData()
    }
    
    private func loadInitialData() {
        // Load favorites (you'd restore these from UserDefaults)
        Task {
            // For now, just load the home directory
            let home = FileManager.default.homeDirectoryForCurrentUser
            do {
                var rootItem = FileItem(url: home)
                try rootItem.loadChildren()
                
                let children = rootItem.children ?? []
                let docsFolder = children.first(where: { $0.name == "Documents" })
                
                await MainActor.run {
                    self.rootItems = children
                    
                    // Add some default favorites
                    if let docs = docsFolder {
                        self.favorites.append(docs)
                    }
                }
            } catch {
                print("Failed to load files: \(error)")
            }
        }
    }
    
    func addToFavorites(_ item: FileItem) {
        if !favorites.contains(item) {
            favorites.append(item)
        }
    }
    
    func removeFromFavorites(_ item: FileItem) {
        favorites.removeAll { $0 == item }
    }
}