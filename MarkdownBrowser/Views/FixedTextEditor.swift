import SwiftUI
import AppKit

// Custom NSTextView that properly handles keyboard input
class CustomTextView: NSTextView {
    override func insertText(_ string: Any, replacementRange: NSRange) {
        // Ensure we handle text insertion properly
        super.insertText(string, replacementRange: replacementRange)
    }
    
    override func keyDown(with event: NSEvent) {
        // Let the text view handle the key event
        self.interpretKeyEvents([event])
    }
}

struct FixedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // Create custom text view
        let textView = CustomTextView()
        textView.delegate = context.coordinator
        
        // Configure text view
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Font and appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Disable rich text features
        textView.isRichText = false
        textView.importsGraphics = false
        
        // Disable automatic substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Layout
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = .width
        
        // Set up scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        
        // Store reference
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CustomTextView else { return }
        
        // Update text if needed
        if textView.string != text && !context.coordinator.isUpdating {
            textView.string = text
        }
        
        // Make first responder
        DispatchQueue.main.async {
            if let window = textView.window {
                window.makeFirstResponder(textView)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FixedTextEditor
        weak var textView: CustomTextView?
        var isUpdating = false
        
        init(_ parent: FixedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? CustomTextView else { return }
            
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            isUpdating = false
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