import SwiftUI
import AppKit

// Direct NSTextView without ScrollView wrapper
struct DirectTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        // Create container view
        let containerView = NSView()
        
        // Create scroll view
        let scrollView = NSTextView.scrollableTextView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the text view
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        
        // Font and appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.controlAccentColor
        
        // Text features
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Layout
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        // Add to container
        containerView.addSubview(scrollView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Store references
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
        // Focus handling
        DispatchQueue.main.async {
            if let window = textView.window {
                window.makeFirstResponder(textView)
            }
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        // Update text if changed
        if textView.string != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange()
            textView.string = text
            
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
        
        // Ensure first responder
        if textView.window != nil && textView.window?.firstResponder != textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DirectTextEditor
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdating = false
        
        init(_ parent: DirectTextEditor) {
            self.parent = parent
            super.init()
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
    }
}