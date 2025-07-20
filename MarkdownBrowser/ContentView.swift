import SwiftUI

struct ContentView: View {
    @StateObject private var fileSystemVM = FileSystemViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var focusedPane: FocusedPane = .directory
    @FocusState private var isDirectoryFocused: Bool
    @FocusState private var isPreviewFocused: Bool
    @State private var showingErrorAlert = false
    
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
                if let selectedNode = fileSystemVM.selectedNode, !selectedNode.isDirectory {
                    // Show file content
                    FilePreviewView(fileURL: selectedNode.url)
                        .id(selectedNode.id) // Force new view instance for each file
                } else {
                    Text("Select a file to preview")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
            }
        }
        .onChange(of: fileSystemVM.errorMessage) { newValue in
            showingErrorAlert = newValue != nil
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                fileSystemVM.errorMessage = nil
            }
        } message: {
            Text(fileSystemVM.errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview {
    ContentView()
}