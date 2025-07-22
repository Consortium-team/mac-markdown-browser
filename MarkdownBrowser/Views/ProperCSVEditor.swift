import SwiftUI
import Combine

struct ProperCSVEditor: View {
    let fileURL: URL
    @StateObject private var viewModel = CSVViewModel()
    @State private var editorContent: String = ""
    @State private var showingSaveAlert = false
    @Environment(\.window) private var window
    
    var body: some View {
        HSplitView {
            // Left side: Raw CSV editor
            VStack(spacing: 0) {
                // Editor header
                HStack {
                    Text("CSV Editor")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewModel.hasUnsavedChanges {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // CSV editor
                CSVEditorView(
                    content: $editorContent,
                    delimiter: viewModel.selectedDelimiter,
                    isEditable: true,
                    onContentChange: { newContent in
                        viewModel.updateContent(newContent)
                    }
                )
            }
            .frame(minWidth: 300)
            
            // Right side: Table preview
            VStack(spacing: 0) {
                // Preview header with delimiter selector
                HStack {
                    Text("Table Preview")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Delimiter selector
                    Menu {
                        ForEach(CSVDelimiter.allCases, id: \.self) { delimiter in
                            Button(action: { 
                                viewModel.changeDelimiter(delimiter)
                            }) {
                                HStack {
                                    Text(delimiter.displayName)
                                    if viewModel.selectedDelimiter == delimiter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Delimiter:")
                                .font(.system(size: 11))
                            Text(viewModel.selectedDelimiter.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    Text(viewModel.documentMetadata)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // CSV preview
                CSVPreviewContainer(viewModel: viewModel)
            }
            .frame(minWidth: 400)
        }
        .onAppear {
            loadDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
            if let closingWindow = notification.object as? NSWindow,
               closingWindow == window {
                // Save if there are unsaved changes
                if viewModel.hasUnsavedChanges {
                    Task {
                        await saveDocument()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await saveDocument()
                    }
                }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!viewModel.hasUnsavedChanges || viewModel.isLoading)
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .alert("Save Error", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to save the file. Please try again.")
        }
    }
    
    private func loadDocument() {
        Task {
            await viewModel.loadDocument(at: fileURL)
            if let content = viewModel.currentDocument?.content {
                editorContent = content
            }
        }
    }
    
    @MainActor
    private func saveDocument() async {
        guard viewModel.hasUnsavedChanges else { return }
        
        await viewModel.saveCurrentDocument()
        
        // Notify other views that the file was saved
        NotificationCenter.default.post(
            name: .csvFileSaved,
            object: nil,
            userInfo: ["url": fileURL]
        )
        
        if viewModel.documentError != nil {
            showingSaveAlert = true
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let csvFileSaved = Notification.Name("csvFileSaved")
}

// MARK: - Environment Key for Window
private struct WindowKey: EnvironmentKey {
    static let defaultValue: NSWindow? = nil
}

extension EnvironmentValues {
    var window: NSWindow? {
        get { self[WindowKey.self] }
        set { self[WindowKey.self] = newValue }
    }
}

// MARK: - Preview
#Preview {
    ProperCSVEditor(fileURL: URL(fileURLWithPath: "/tmp/test.csv"))
}