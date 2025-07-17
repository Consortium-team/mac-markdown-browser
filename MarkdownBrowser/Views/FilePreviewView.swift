import SwiftUI

struct FilePreviewView: View {
    let fileURL: URL
    @State private var fileContent: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    @State private var loadedURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // File header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content area
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
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
            } else {
                ScrollView {
                    Text(fileContent)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear {
            loadFile()
        }
        .onChange(of: fileURL) { newURL in
            if loadedURL != newURL {
                loadFile()
            }
        }
    }
    
    private func loadFile() {
        guard loadedURL != fileURL else { return }
        
        isLoading = true
        error = nil
        loadedURL = fileURL
        
        Task {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                await MainActor.run {
                    // Only update if this is still the current file
                    if self.loadedURL == fileURL {
                        self.fileContent = content
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // Only update if this is still the current file
                    if self.loadedURL == fileURL {
                        self.error = error
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    FilePreviewView(fileURL: URL(fileURLWithPath: "/tmp/test.md"))
}