import SwiftUI
import Foundation

struct FilePreviewView: View {
    let fileURL: URL
    @StateObject private var viewModel = MarkdownViewModel()
    @State private var showingEditView = false
    @State private var isLoading = true
    @State private var isExportingPDF = false
    @State private var exportError: Error?
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL?
    @State private var exportTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            // File header with edit controls
            HStack {
                Image(systemName: fileURL.fileType.iconName)
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
                
                // Export PDF button for markdown and HTML files
                if fileURL.isMarkdownFile || fileURL.isHTMLFile {
                    Button(action: exportToPDF) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    .disabled(isExportingPDF || isLoading)
                    .padding(.trailing, 8)
                }
                
                // Edit mode toggle for markdown files
                if fileURL.isMarkdownFile {
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
            } else if fileURL.isSupportedDocument {
                // Preview for supported documents (Markdown and HTML)
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
        .onReceive(
            NotificationCenter.default.publisher(for: .markdownFileSaved)
        ) { notification in
            // Check if the saved file is the one we're displaying
            if let savedURL = notification.userInfo?["url"] as? URL,
               savedURL == fileURL {
                // Reload the document to show the latest changes
                Task {
                    await viewModel.loadDocument(at: fileURL)
                }
            }
        }
        .alert("Export Complete", isPresented: $showExportSuccess) {
            Button("Show in Finder") {
                if let url = exportedFileURL {
                    DownloadSaveManager.shared.showInFinder(url: url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            if let url = exportedFileURL {
                Text("PDF saved to: \(url.lastPathComponent)")
            }
        }
        .alert("Export Error", isPresented: .constant(exportError != nil)) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError?.localizedDescription ?? "Unknown error")
        }
        .sheet(isPresented: $isExportingPDF) {
            VStack(spacing: 20) {
                ProgressView("Exporting PDF...")
                Button("Cancel") {
                    exportTask?.cancel()
                    isExportingPDF = false
                }
                .keyboardShortcut(.escape)
            }
            .padding(40)
        }
    }
    
    private func exportToPDF() {
        isExportingPDF = true
        exportError = nil
        
        exportTask = Task {
            do {
                let pdfData: Data
                
                // Check for cancellation
                if Task.isCancelled {
                    isExportingPDF = false
                    return
                }
                
                if fileURL.isMarkdownFile {
                    // Export markdown to PDF
                    guard let content = viewModel.currentDocument?.content else {
                        throw PDFExportError.contentNotReady
                    }
                    pdfData = try await PDFExportService.shared.exportMarkdownToPDF(content: content)
                } else if fileURL.isHTMLFile {
                    // Export HTML to PDF
                    let htmlContent = try String(contentsOf: fileURL, encoding: .utf8)
                    pdfData = try await PDFExportService.shared.exportHTMLToPDF(
                        html: htmlContent,
                        baseURL: fileURL.deletingLastPathComponent()
                    )
                } else {
                    throw PDFExportError.contentNotReady
                }
                
                // Check for cancellation before saving
                if Task.isCancelled {
                    isExportingPDF = false
                    return
                }
                
                // Save to Downloads folder
                let baseFilename = fileURL.deletingPathExtension().lastPathComponent
                let savedURL = try await DownloadSaveManager.shared.saveToDownloads(
                    data: pdfData,
                    baseFilename: baseFilename,
                    fileExtension: "pdf"
                )
                
                exportedFileURL = savedURL
                showExportSuccess = true
                
            } catch {
                if !Task.isCancelled {
                    exportError = error
                }
            }
            
            isExportingPDF = false
        }
    }
}

#Preview {
    FilePreviewView(fileURL: URL(fileURLWithPath: "/tmp/test.md"))
}