import SwiftUI
import AppKit

struct CSVEditorView: NSViewRepresentable {
    @Binding var content: String
    let delimiter: CSVDelimiter
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
        
        // Show line numbers
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        // Make the text view first responder to enable typing
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }
        
        setupSyntaxHighlighting(textView, delimiter: delimiter)
        
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
            
            setupSyntaxHighlighting(textView, delimiter: delimiter)
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
    
    private func setupSyntaxHighlighting(_ textView: NSTextView, delimiter: CSVDelimiter) {
        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)
        
        // Clear existing attributes
        storage.removeAttribute(.foregroundColor, range: fullRange)
        storage.removeAttribute(.backgroundColor, range: fullRange)
        storage.removeAttribute(.font, range: fullRange)
        
        // Set default attributes
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ]
        storage.addAttributes(defaultAttributes, range: fullRange)
        
        let lines = storage.string.components(separatedBy: .newlines)
        var location = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let lineRange = NSRange(location: location, length: line.count)
            
            // Alternate row background coloring
            if lineIndex > 0 && lineIndex % 2 == 0 {
                storage.addAttribute(.backgroundColor, 
                                   value: NSColor.alternatingContentBackgroundColors[1], 
                                   range: lineRange)
            }
            
            // Highlight delimiter characters
            highlightDelimiters(in: line, at: location, delimiter: delimiter, storage: storage)
            
            // Highlight quoted values
            highlightQuotedValues(in: line, at: location, storage: storage)
            
            // Move to next line (add 1 for newline character)
            location += line.count + (lineIndex < lines.count - 1 ? 1 : 0)
        }
    }
    
    private func highlightDelimiters(in line: String, at baseLocation: Int, delimiter: CSVDelimiter, storage: NSTextStorage) {
        let delimiterChar = delimiter.rawValue
        let delimiterColor = NSColor.systemBlue.withAlphaComponent(0.7)
        
        for (index, char) in line.enumerated() {
            if String(char) == delimiterChar {
                let range = NSRange(location: baseLocation + index, length: 1)
                storage.addAttribute(.foregroundColor, value: delimiterColor, range: range)
                storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold), range: range)
            }
        }
    }
    
    private func highlightQuotedValues(in line: String, at baseLocation: Int, storage: NSTextStorage) {
        let quotedColor = NSColor.systemGreen.withAlphaComponent(0.8)
        var inQuotes = false
        var quoteStart = 0
        
        for (index, char) in line.enumerated() {
            if char == "\"" {
                if !inQuotes {
                    inQuotes = true
                    quoteStart = index
                } else {
                    // Check if it's an escaped quote
                    let nextIndex = line.index(line.startIndex, offsetBy: index + 1)
                    if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                        // Skip escaped quote
                        continue
                    }
                    
                    // End of quoted value
                    let range = NSRange(location: baseLocation + quoteStart, 
                                      length: index - quoteStart + 1)
                    storage.addAttribute(.foregroundColor, value: quotedColor, range: range)
                    inQuotes = false
                }
            }
        }
        
        // Handle unclosed quotes
        if inQuotes {
            let range = NSRange(location: baseLocation + quoteStart, 
                              length: line.count - quoteStart)
            storage.addAttribute(.foregroundColor, value: quotedColor, range: range)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CSVEditorView
        
        init(_ parent: CSVEditorView) {
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
                    self.parent.setupSyntaxHighlighting(textView, delimiter: self.parent.delimiter)
                }
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                // Navigate to next cell in CSV
                return handleTabNavigation(textView, forward: true)
            } else if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                // Navigate to previous cell in CSV
                return handleTabNavigation(textView, forward: false)
            }
            return false
        }
        
        private func handleTabNavigation(_ textView: NSTextView, forward: Bool) -> Bool {
            let currentPosition = textView.selectedRange().location
            let content = textView.string
            let delimiter = parent.delimiter.rawValue
            
            guard !content.isEmpty else { return false }
            
            if forward {
                // Find next delimiter or newline
                if let range = content.range(of: delimiter, 
                                            options: [], 
                                            range: content.index(content.startIndex, offsetBy: currentPosition)..<content.endIndex) {
                    let newPosition = content.distance(from: content.startIndex, to: range.upperBound)
                    textView.setSelectedRange(NSRange(location: newPosition, length: 0))
                    return true
                }
            } else {
                // Find previous delimiter or newline
                if currentPosition > 0 {
                    let searchRange = content.startIndex..<content.index(content.startIndex, offsetBy: currentPosition)
                    if let range = content.range(of: delimiter, options: .backwards, range: searchRange) {
                        let newPosition = content.distance(from: content.startIndex, to: range.upperBound)
                        textView.setSelectedRange(NSRange(location: newPosition, length: 0))
                        return true
                    }
                }
            }
            
            return false
        }
    }
}