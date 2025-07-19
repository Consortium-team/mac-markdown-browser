import SwiftUI

struct FilePreviewView: View {
    let fileURL: URL
    @StateObject private var viewModel = MarkdownViewModel()
    @State private var showingEditView = false
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // File header with edit controls
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if viewModel.hasUnsavedChanges {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Edit mode toggle for markdown files
                if fileURL.pathExtension.lowercased() == "md" {
                    // Use window instead of sheet
                    EditWindowButton(fileURL: fileURL)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content area
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.renderError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Error loading file")
                        .font(.title2)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if fileURL.pathExtension.lowercased() == "md" {
                MarkdownPreviewView(htmlContent: viewModel.renderedHTML)
            } else {
                // Show raw text for non-markdown files
                ScrollView {
                    Text(viewModel.currentDocument?.content ?? "")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDocument(at: fileURL)
                isLoading = false
            }
        }
        .onChange(of: fileURL) { newURL in
            // Check for unsaved changes before switching
            if viewModel.hasUnsavedChanges {
                // In a real app, we'd show an alert here
                // For now, just save automatically
                Task {
                    await viewModel.saveCurrentDocument()
                    await viewModel.loadDocument(at: newURL)
                    isLoading = false
                }
            } else {
                Task {
                    await viewModel.loadDocument(at: newURL)
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    FilePreviewView(fileURL: URL(fileURLWithPath: "/tmp/test.md"))
}