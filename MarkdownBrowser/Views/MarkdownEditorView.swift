import SwiftUI
import AppKit

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var content: String
    let isEditable: Bool
    let onContentChange: ((String) -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.string = content
        textView.isEditable = isEditable
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true
        
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.controlAccentColor
        
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.usesInspectorBar = false
        textView.isIncrementalSearchingEnabled = true
        
        textView.textContainerInset = NSSize(width: 16, height: 16)
        
        // Make the text view first responder to enable typing
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }
        
        setupSyntaxHighlighting(textView)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != content {
            let selectedRange = textView.selectedRange()
            textView.string = content
            
            if selectedRange.location <= content.count {
                textView.setSelectedRange(selectedRange)
            }
            
            setupSyntaxHighlighting(textView)
        }
        
        textView.isEditable = isEditable
        
        // Ensure text view can become first responder when needed
        if isEditable && textView.window?.firstResponder != textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupSyntaxHighlighting(_ textView: NSTextView) {
        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)
        
        storage.removeAttribute(.foregroundColor, range: fullRange)
        storage.removeAttribute(.font, range: fullRange)
        
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ]
        storage.addAttributes(defaultAttributes, range: fullRange)
        
        let patterns: [(pattern: String, attributes: [NSAttributedString.Key: Any])] = [
            ("^#{1,6}\\s.*$", [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            ("\\*\\*[^*]+\\*\\*", [.font: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            ("\\*[^*]+\\*", [.font: { () -> NSFont in
                let descriptor = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular).fontDescriptor.withSymbolicTraits(.italic)
                return NSFont(descriptor: descriptor, size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            }()]),
            ("`[^`]+`", [.foregroundColor: NSColor.systemRed, .backgroundColor: NSColor.systemRed.withAlphaComponent(0.1)]),
            ("```[\\s\\S]*?```", [.foregroundColor: NSColor.systemGreen]),
            ("\\[[^\\]]+\\]\\([^\\)]+\\)", [.foregroundColor: NSColor.systemPurple]),
            ("^\\s*[-*+]\\s", [.foregroundColor: NSColor.systemOrange]),
            ("^\\s*\\d+\\.\\s", [.foregroundColor: NSColor.systemOrange]),
            ("^>.*$", [.foregroundColor: NSColor.systemGray])
        ]
        
        for (pattern, attributes) in patterns {
            highlightPattern(pattern, in: storage, with: attributes)
        }
    }
    
    private func highlightPattern(_ pattern: String, in storage: NSTextStorage, with attributes: [NSAttributedString.Key: Any]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let matches = regex.matches(in: storage.string, options: [], range: NSRange(location: 0, length: storage.length))
            
            for match in matches {
                storage.addAttributes(attributes, range: match.range)
            }
        } catch {
            print("Regex error: \(error)")
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorView
        
        init(_ parent: MarkdownEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let newContent = textView.string
            if newContent != parent.content {
                parent.content = newContent
                parent.onContentChange?(newContent)
                
                DispatchQueue.main.async { [weak textView] in
                    guard let textView = textView else { return }
                    self.parent.setupSyntaxHighlighting(textView)
                }
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }
    }
}