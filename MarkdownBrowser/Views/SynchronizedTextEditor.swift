import SwiftUI
import AppKit

struct SynchronizedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    var scrollSynchronizer: ScrollSynchronizer?
    var onScrollChange: ((Double) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        
        // Store reference
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
        // Set up scroll observer
        if let synchronizer = scrollSynchronizer, let onScroll = onScrollChange {
            synchronizer.setupTextViewScrollObserver(textView: textView, onScroll: onScroll)
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update text if needed
        if textView.string != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange()
            textView.string = text
            
            // Restore selection if valid
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
        
        // Handle external scroll updates
        if let percentage = context.coordinator.pendingScrollPercentage {
            context.coordinator.pendingScrollPercentage = nil
            scrollSynchronizer?.scrollTextView(textView, toPercentage: percentage)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SynchronizedTextEditor
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdating = false
        var pendingScrollPercentage: Double?
        
        init(_ parent: SynchronizedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            isUpdating = false
        }
        
        func scrollToPercentage(_ percentage: Double) {
            pendingScrollPercentage = percentage
        }
    }
}