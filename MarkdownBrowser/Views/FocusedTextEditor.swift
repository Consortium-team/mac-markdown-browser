import SwiftUI
import AppKit

// Text editor that properly handles focus in SwiftUI sheets/windows
struct FocusedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    @Binding var isFocused: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // Store reference
        context.coordinator.textView = textView
        
        // Configure text view
        textView.delegate = context.coordinator
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.controlAccentColor
        
        // Disable rich text
        textView.isRichText = false
        textView.importsGraphics = false
        
        // Disable auto corrections
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
        
        // Text view already accepts first responder by default
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update text
        if textView.string != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange()
            textView.string = text
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
        
        // Handle focus
        if isFocused && textView.window != nil {
            // Use performSelector to ensure we're on the main run loop
            DispatchQueue.main.async {
                if let window = textView.window {
                    // Make window key if it isn't
                    if !window.isKeyWindow {
                        window.makeKey()
                    }
                    // Then make text view first responder
                    if window.firstResponder != textView {
                        window.makeFirstResponder(textView)
                    }
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FocusedTextEditor
        weak var textView: NSTextView?
        var isUpdating = false
        
        init(_ parent: FocusedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
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
        
        // Track focus state
        func textViewDidChangeSelection(_ notification: Notification) {
            if let textView = notification.object as? NSTextView,
               textView.window?.firstResponder == textView {
                parent.isFocused = true
            }
        }
    }
}