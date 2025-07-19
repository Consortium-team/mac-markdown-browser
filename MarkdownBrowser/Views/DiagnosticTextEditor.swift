import SwiftUI
import AppKit

struct DiagnosticTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        print("🔵 DiagnosticTextEditor: makeCoordinator called")
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        print("🔵 DiagnosticTextEditor: makeNSView called")
        
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            print("❌ DiagnosticTextEditor: Failed to get text view from scroll view")
            return scrollView
        }
        
        // Store reference
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
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
        
        // Text settings
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        
        // Layout
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        print("🔵 DiagnosticTextEditor: Text view configured")
        print("   - isEditable: \(textView.isEditable)")
        print("   - isSelectable: \(textView.isSelectable)")
        print("   - acceptsFirstResponder: \(textView.acceptsFirstResponder)")
        
        // Add observer for window changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let window = notification.object as? NSWindow,
               window == textView.window {
                print("🟢 DiagnosticTextEditor: Window became key")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSView.didUpdateTrackingAreasNotification,
            object: textView,
            queue: .main
        ) { _ in
            print("🔵 DiagnosticTextEditor: Tracking areas updated")
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        print("🔵 DiagnosticTextEditor: updateNSView called")
        print("   - Window: \(textView.window != nil ? "exists" : "nil")")
        print("   - Window is key: \(textView.window?.isKeyWindow ?? false)")
        print("   - First responder: \(textView.window?.firstResponder)")
        print("   - Text view is first responder: \(textView.window?.firstResponder == textView)")
        
        // Update text
        if textView.string != text && !context.coordinator.isUpdating {
            textView.string = text
        }
        
        // Try to make first responder
        if let window = textView.window {
            DispatchQueue.main.async {
                print("🟡 DiagnosticTextEditor: Attempting to make first responder")
                let success = window.makeFirstResponder(textView)
                print("   - Success: \(success)")
                print("   - First responder after: \(window.firstResponder)")
                
                if !window.isKeyWindow {
                    print("🟡 DiagnosticTextEditor: Making window key")
                    window.makeKey()
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DiagnosticTextEditor
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdating = false
        
        init(_ parent: DiagnosticTextEditor) {
            self.parent = parent
            super.init()
            print("🔵 DiagnosticTextEditor.Coordinator: init")
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            print("✅ DiagnosticTextEditor: textDidChange - text: \(textView.string)")
            
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            isUpdating = false
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("🔵 DiagnosticTextEditor: doCommandBy - selector: \(commandSelector)")
            
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }
        
        // Additional delegate methods for debugging
        func textDidBeginEditing(_ notification: Notification) {
            print("✅ DiagnosticTextEditor: textDidBeginEditing")
        }
        
        func textDidEndEditing(_ notification: Notification) {
            print("🛑 DiagnosticTextEditor: textDidEndEditing")
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            print("🔵 DiagnosticTextEditor: selection changed - range: \(textView.selectedRange())")
        }
    }
}