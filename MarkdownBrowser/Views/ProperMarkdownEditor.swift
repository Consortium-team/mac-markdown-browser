import SwiftUI
import WebKit
import Combine

// MARK: - View Model
class MarkdownEditorViewModel: ObservableObject {
    @Published var markdownText: String = ""
    @Published var htmlContent: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let markdownService = MarkdownService()
    
    init() {
        // Debounce markdown changes to avoid excessive updates
        $markdownText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                self?.updatePreview(markdown: newText)
            }
            .store(in: &cancellables)
    }
    
    private func updatePreview(markdown: String) {
        Task { @MainActor in
            do {
                let parsed = try await markdownService.parseMarkdown(markdown)
                self.htmlContent = parsed.htmlContent
            } catch {
                print("Error parsing markdown: \(error)")
                self.htmlContent = "<p>Error rendering markdown</p>"
            }
        }
    }
    
    func loadFile(from url: URL) async {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            await MainActor.run {
                self.markdownText = content
            }
        } catch {
            print("Error loading file: \(error)")
        }
    }
    
    func saveFile(to url: URL) async {
        do {
            try markdownText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving file: \(error)")
        }
    }
}

// MARK: - Main Editor View
struct ProperMarkdownEditor: View {
    let fileURL: URL
    @StateObject private var viewModel = MarkdownEditorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var splitRatio: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            EditorToolbar(
                fileName: fileURL.lastPathComponent,
                onSave: { Task { await viewModel.saveFile(to: fileURL) } },
                onClose: { dismiss() }
            )
            
            Divider()
            
            // Split View
            GeometryReader { geometry in
                HSplitView {
                    // Editor
                    MarkdownTextEditor(text: $viewModel.markdownText)
                        .frame(width: geometry.size.width * splitRatio)
                    
                    // Preview
                    MarkdownPreview(htmlContent: viewModel.htmlContent)
                        .frame(width: geometry.size.width * (1 - splitRatio))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadFile(from: fileURL)
        }
    }
}

// MARK: - Toolbar
struct EditorToolbar: View {
    let fileName: String
    let onSave: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
            Text(fileName)
                .font(.headline)
            
            Spacer()
            
            Button(action: onSave) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button(action: onClose) {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Text Editor
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.string = text
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isRichText = false
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text actually changed to avoid cursor jumping
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        
        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - Web Preview
struct MarkdownPreview: NSViewRepresentable {
    let htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        // Handle navigation if needed
    }
}