import SwiftUI
import AppKit

struct DebugTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // Configure text view
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        
        // Set up font and appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Disable rich text
        textView.isRichText = false
        textView.importsGraphics = false
        
        // Disable automatic substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        
        // Layout
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        // Store reference
        context.coordinator.textView = textView
        
        print("🔍 DebugTextEditor: Text view created")
        print("   - isEditable: \(textView.isEditable)")
        print("   - isSelectable: \(textView.isSelectable)")
        print("   - acceptsFirstResponder: \(textView.acceptsFirstResponder)")
        print("   - canBecomeKeyView: \(textView.canBecomeKeyView)")
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update text if needed
        if textView.string != text && !context.coordinator.isUpdating {
            textView.string = text
        }
        
        // Ensure proper focus
        DispatchQueue.main.async {
            if let window = textView.window {
                // Activate app
                NSApp.activate(ignoringOtherApps: true)
                
                // Make window key and order front
                window.makeKeyAndOrderFront(nil)
                
                // Make text view first responder
                if window.firstResponder != textView {
                    let success = window.makeFirstResponder(textView)
                    print("🔍 DebugTextEditor: makeFirstResponder = \(success)")
                }
                
                // Debug window state
                print("🔍 DebugTextEditor: Window state")
                print("   - isKeyWindow: \(window.isKeyWindow)")
                print("   - isMainWindow: \(window.isMainWindow)")
                print("   - firstResponder type: \(type(of: window.firstResponder))")
                print("   - firstResponder == textView: \(window.firstResponder == textView)")
                
                // Check modal session
                if let modalWindow = NSApp.modalWindow {
                    print("   - Modal window active: \(modalWindow)")
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DebugTextEditor
        weak var textView: NSTextView?
        var isUpdating = false
        
        init(_ parent: DebugTextEditor) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - NSTextViewDelegate
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            print("✅ DebugTextEditor: textDidChange called - length: \(textView.string.count)")
            
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            isUpdating = false
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("🔍 DebugTextEditor: doCommandBy selector: \(commandSelector)")
            
            // List common selectors
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                print("   - Insert newline")
            case #selector(NSResponder.insertTab(_:)):
                print("   - Insert tab")
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            case #selector(NSResponder.deleteBackward(_:)):
                print("   - Delete backward")
            case #selector(NSResponder.deleteForward(_:)):
                print("   - Delete forward")
            case #selector(NSResponder.insertText(_:)):
                print("   - Insert text")
            default:
                print("   - Other: \(NSStringFromSelector(commandSelector))")
            }
            
            // Return false to let NSTextView handle the command
            return false
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            print("🔍 DebugTextEditor: Selection changed to: \(textView.selectedRange())")
        }
        
        // Check if text should change
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            print("🔍 DebugTextEditor: shouldChangeTextIn range: \(affectedCharRange), replacement: \(replacementString ?? "nil")")
            return true
        }
        
        // Additional debugging
        override func responds(to aSelector: Selector!) -> Bool {
            let responds = super.responds(to: aSelector)
            if !responds && aSelector != nil {
                let selectorName = NSStringFromSelector(aSelector)
                if selectorName.contains("insert") || selectorName.contains("text") {
                    print("❌ DebugTextEditor: Does not respond to: \(selectorName)")
                }
            }
            return responds
        }
    }
}