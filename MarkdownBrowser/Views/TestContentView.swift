import SwiftUI

struct TestContentView: View {
    @StateObject private var viewModel = FileSystemViewModel2()
    
    var body: some View {
        HSplitView {
            // File browser sidebar
            DirectoryBrowser2(viewModel: viewModel)
                .frame(minWidth: 250, idealWidth: 300)
            
            // Preview area
            VStack {
                if let selectedItem = viewModel.selectedItem, !selectedItem.isDirectory {
                    FilePreviewView(fileURL: selectedItem.url)
                } else {
                    Text("Select a file to preview")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Load home directory on startup
            Task {
                let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
                await viewModel.navigateToDirectory(homeDirectory)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}