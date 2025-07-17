import SwiftUI

struct ContentView: View {
    @StateObject private var fileSystemVM = FileSystemViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var focusedPane: FocusedPane = .directory
    @FocusState private var isDirectoryFocused: Bool
    @FocusState private var isPreviewFocused: Bool
    
    enum FocusedPane {
        case directory
        case preview
    }
    
    var body: some View {
        HSplitView {
            // Left Panel - Directory Browser
            DirectoryPanel(
                fileSystemVM: fileSystemVM,
                favoritesVM: favoritesVM
            )
            .frame(minWidth: 300, maxWidth: 500)
            .focused($isDirectoryFocused)
            .background(
                Color(NSColor.controlBackgroundColor)
                    .opacity(focusedPane == .directory ? 1.0 : 0.8)
            )
            
            // Right Panel - Preview Area
            VStack {
                Text("Preview Panel")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400)
            .background(Color(NSColor.textBackgroundColor))
            .focused($isPreviewFocused)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onChange(of: isDirectoryFocused) { newValue in
            if newValue {
                focusedPane = .directory
            }
        }
        .onChange(of: isPreviewFocused) { newValue in
            if newValue {
                focusedPane = .preview
            }
        }
        .onAppear {
            // Load home directory on startup
            Task {
                let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
                await fileSystemVM.navigateToDirectory(homeDirectory)
                
                // Add default favorites if they don't exist
                let defaultFavorites: [(path: String, name: String)] = [
                    ("", "Home"),
                    ("ConsortiumTeam_ClientFiles", "Client Files"),
                    ("Downloads", "Downloads"),
                    ("dev", "Development")
                ]
                
                for (path, name) in defaultFavorites {
                    let url = path.isEmpty ? homeDirectory : homeDirectory.appendingPathComponent(path)
                    if !favoritesVM.favorites.contains(where: { $0.url == url }) {
                        // Check if the directory exists before adding
                        var isDirectory: ObjCBool = false
                        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                            favoritesVM.addFavorite(url, name: name)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}