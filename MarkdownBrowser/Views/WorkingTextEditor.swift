import SwiftUI
import AppKit

struct WorkingTextEditor: NSViewRepresentable {
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
        
        // Text settings
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
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // IMPORTANT: Make the app active and bring window to front
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let window = textView.window {
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(textView)
            }
        }
        
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
        
        // Ensure window is key and text view is first responder
        if let window = textView.window {
            if !window.isKeyWindow || window.firstResponder != textView {
                DispatchQueue.main.async {
                    // Activate the app to take focus from terminal
                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                    window.makeFirstResponder(textView)
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: WorkingTextEditor
        weak var textView: NSTextView?
        var isUpdating = false
        
        init(_ parent: WorkingTextEditor) {
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
    }
}

// Sheet wrapper that ensures proper activation
struct ActivatedSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        EmptyView()
            .sheet(isPresented: $isPresented) {
                content()
                    .onAppear {
                        // Force app activation when sheet appears
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.windows.last {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
            }
    }
}