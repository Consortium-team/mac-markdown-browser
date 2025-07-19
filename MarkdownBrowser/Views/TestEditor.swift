import SwiftUI
import AppKit

// Minimal test case to debug text input issue
struct TestEditor: View {
    @State private var text = "Initial text"
    
    var body: some View {
        VStack {
            Text("Test Editor - Type below:")
                .font(.headline)
            
            TestEditorView(text: $text)
                .frame(height: 200)
                .border(Color.blue, width: 2)
            
            Text("Current text: \(text)")
                .font(.caption)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct TestEditorView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        
        // Basic setup
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 14)
        
        // IMPORTANT: Set delegate
        textView.delegate = context.coordinator
        
        // Debug: Print when view is created
        print("TestEditorView: makeNSView called")
        
        return textView
    }
    
    func updateNSView(_ textView: NSTextView, context: Context) {
        // Update text if changed externally
        if textView.string != text {
            textView.string = text
        }
        
        // Debug: Check first responder status
        DispatchQueue.main.async {
            if let window = textView.window {
                print("TestEditorView: Window exists, firstResponder: \(window.firstResponder)")
                if window.firstResponder != textView {
                    print("TestEditorView: Making text view first responder")
                    window.makeFirstResponder(textView)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TestEditorView
        
        init(_ parent: TestEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            print("TestEditorView: Text changed to: \(textView.string)")
            parent.text = textView.string
        }
    }
}

// Add this test view to ContentView for testing
struct TestEditorWrapper: View {
    var body: some View {
        TestEditor()
    }
}