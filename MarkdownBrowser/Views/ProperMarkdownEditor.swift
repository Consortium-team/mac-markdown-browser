import SwiftUI
import WebKit
import Combine
import AppKit

// MARK: - View Model
class MarkdownEditorViewModel: ObservableObject {
    @Published var markdownText: String = "" {
        didSet {
            if markdownText != originalText {
                hasUnsavedChanges = true
            }
        }
    }
    @Published var htmlContent: String = ""
    @Published var hasUnsavedChanges: Bool = false
    @Published var isSaving: Bool = false
    
    private var originalText: String = ""
    private var cancellables = Set<AnyCancellable>()
    private let markdownService = MarkdownService()
    private var autoSaveTimer: Timer?
    private var fileURL: URL?
    
    init() {
        // Debounce markdown changes to avoid excessive updates
        $markdownText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                self?.updatePreview(markdown: newText)
                self?.scheduleAutoSave()
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
    
    private func scheduleAutoSave() {
        // Cancel existing timer
        autoSaveTimer?.invalidate()
        
        // Schedule new auto-save after 2 seconds of inactivity
        guard hasUnsavedChanges else { return }
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task {
                await self?.autoSave()
            }
        }
    }
    
    func loadFile(from url: URL) async {
        self.fileURL = url
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            await MainActor.run {
                self.originalText = content
                self.markdownText = content
                self.hasUnsavedChanges = false
            }
        } catch {
            print("Error loading file: \(error)")
        }
    }
    
    func saveFile() async {
        guard let url = fileURL else { return }
        
        await MainActor.run {
            self.isSaving = true
        }
        
        do {
            try markdownText.write(to: url, atomically: true, encoding: .utf8)
            await MainActor.run {
                self.originalText = self.markdownText
                self.hasUnsavedChanges = false
                self.isSaving = false
                
                // Post notification that file was saved
                NotificationCenter.default.post(
                    name: .markdownFileSaved,
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        } catch {
            print("Error saving file: \(error)")
            await MainActor.run {
                self.isSaving = false
            }
        }
    }
    
    private func autoSave() async {
        await saveFile()
    }
}

// MARK: - Main Editor View
struct ProperMarkdownEditor: View {
    let fileURL: URL
    @StateObject private var viewModel = MarkdownEditorViewModel()
    @State private var splitRatio: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                
                if viewModel.hasUnsavedChanges {
                    Text("— Edited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
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
        .onAppear {
            // Setup window tracking when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateWindowDocumentState()
            }
        }
        .onChange(of: viewModel.hasUnsavedChanges) { hasChanges in
            updateWindowDocumentState()
        }
        // Add menu bar with File > Save
        .focusedSceneValue(\.saveAction) {
            Task {
                await viewModel.saveFile()
            }
        }
    }
    
    private func updateWindowDocumentState() {
        // Find the window containing this view
        for window in NSApp.windows {
            if window.title == fileURL.lastPathComponent {
                window.isDocumentEdited = viewModel.hasUnsavedChanges
                break
            }
        }
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
        textView.allowsUndo = true
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text actually changed to avoid cursor jumping
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            // Restore cursor position
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
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

// MARK: - Focused Value for Save Action
struct SaveActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var saveAction: (() -> Void)? {
        get { self[SaveActionKey.self] }
        set { self[SaveActionKey.self] = newValue }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let markdownFileSaved = Notification.Name("markdownFileSaved")
}