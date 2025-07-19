import SwiftUI

enum LayoutMode {
    case sideBySide
    case fullscreenEdit
    case fullscreenPreview
}

struct MarkdownEditView: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MarkdownViewModel()
    @State private var editingContent: String = ""
    @State private var layoutMode: LayoutMode = .sideBySide
    @State private var isLoading = true
    @State private var dividerPosition: CGFloat = 0.5
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch layoutMode {
                case .sideBySide:
                    HSplitView {
                        // Editor pane
                        VStack(spacing: 0) {
                            editorHeader
                            Divider()
                            MarkdownEditorView(
                                content: $editingContent,
                                isEditable: true,
                                onContentChange: { newContent in
                                    viewModel.updateContent(newContent)
                                }
                            )
                            .focused($isEditorFocused)
                        }
                        .frame(minWidth: 300)
                        
                        // Preview pane
                        VStack(spacing: 0) {
                            previewHeader
                            Divider()
                            if isLoading {
                                ProgressView("Loading...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                MarkdownPreviewView(htmlContent: viewModel.renderedHTML)
                            }
                        }
                        .frame(minWidth: 300)
                    }
                    
                case .fullscreenEdit:
                    VStack(spacing: 0) {
                        editorHeader
                        Divider()
                        MarkdownEditorView(
                            content: $editingContent,
                            isEditable: true,
                            onContentChange: { newContent in
                                viewModel.updateContent(newContent)
                            }
                        )
                        .focused($isEditorFocused)
                    }
                    
                case .fullscreenPreview:
                    VStack(spacing: 0) {
                        previewHeader
                        Divider()
                        if isLoading {
                            ProgressView("Loading...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            MarkdownPreviewView(htmlContent: viewModel.renderedHTML)
                        }
                    }
                }
                
                // Layout mode toggle buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        layoutToggleButtons
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDocument(at: fileURL)
                editingContent = viewModel.currentDocument?.content ?? ""
                isLoading = false
                // Focus editor after content loads
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isEditorFocused = true
                }
            }
        }
        .onChange(of: fileURL) { newURL in
            Task {
                if viewModel.hasUnsavedChanges {
                    await viewModel.saveCurrentDocument()
                }
                await viewModel.loadDocument(at: newURL)
                editingContent = viewModel.currentDocument?.content ?? ""
                isLoading = false
            }
        }
    }
    
    private var editorHeader: some View {
        HStack {
            Image(systemName: "pencil")
                .foregroundColor(.secondary)
            Text("Editor")
                .font(.headline)
            
            if viewModel.hasUnsavedChanges {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button(action: saveDocument) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("s", modifiers: .command)
            .help("Save (⌘S)")
            .disabled(!viewModel.hasUnsavedChanges)
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Close (ESC)")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var previewHeader: some View {
        HStack {
            Image(systemName: "eye")
                .foregroundColor(.secondary)
            Text("Preview")
                .font(.headline)
            Spacer()
            
            if layoutMode == .fullscreenPreview {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.escape, modifiers: [])
                .help("Close (ESC)")
            }
            
            Button(action: { 
                // Force re-render by updating content
                viewModel.updateContent(editingContent)
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh (⌘R)")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var layoutToggleButtons: some View {
        HStack(spacing: 4) {
            Button(action: { withAnimation { layoutMode = .fullscreenEdit } }) {
                Image(systemName: "square.lefthalf.filled")
                    .help("Editor Only")
            }
            .buttonStyle(.bordered)
            .disabled(layoutMode == .fullscreenEdit)
            
            Button(action: { withAnimation { layoutMode = .sideBySide } }) {
                Image(systemName: "square.split.2x1")
                    .help("Side by Side")
            }
            .buttonStyle(.bordered)
            .disabled(layoutMode == .sideBySide)
            
            Button(action: { withAnimation { layoutMode = .fullscreenPreview } }) {
                Image(systemName: "square.righthalf.filled")
                    .help("Preview Only")
            }
            .buttonStyle(.bordered)
            .disabled(layoutMode == .fullscreenPreview)
        }
        .background(.regularMaterial)
        .cornerRadius(8)
    }
    
    private func saveDocument() {
        Task {
            await viewModel.saveCurrentDocument()
        }
    }
}