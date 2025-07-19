import SwiftUI
import AppKit

struct SimpleMarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = true
    var onTextChange: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.delegate = context.coordinator
        textView.string = text
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Text appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Disable rich text features
        textView.isRichText = false
        textView.importsGraphics = false
        
        // Disable auto substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Layout
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // Store references
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update content if changed externally
        if textView.string != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange()
            textView.string = text
            
            // Restore selection
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
        
        // Update editability
        textView.isEditable = isEditable
        
        // Ensure proper first responder status
        if isEditable && textView.window != nil {
            // Delay to ensure window is ready
            DispatchQueue.main.async {
                if textView.window?.firstResponder != textView && textView.acceptsFirstResponder {
                    textView.window?.makeFirstResponder(textView)
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleMarkdownEditor
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdating = false
        
        init(_ parent: SimpleMarkdownEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            isUpdating = false
        }
        
        // Ensure the text view can become first responder
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle tab key
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }
    }
}