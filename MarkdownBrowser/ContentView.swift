import SwiftUI

struct ContentView: View {
    @StateObject private var fileSystemVM = FileSystemViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    
    var body: some View {
        HSplitView {
            // Left Panel - Directory Browser
            VStack(alignment: .leading, spacing: 0) {
                // Favorites Section
                FavoritesSection(
                    favoritesVM: favoritesVM,
                    fileSystemVM: fileSystemVM
                )
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Directory Tree (placeholder for now)
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Directory Tree")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        
                        Text("(To be implemented)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 300, maxWidth: 500)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Right Panel - Preview Area
            VStack {
                Text("Preview Panel")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400)
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(minWidth: 1000, minHeight: 700)
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