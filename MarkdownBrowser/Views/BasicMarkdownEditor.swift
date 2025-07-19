import SwiftUI
import AppKit

// Simple text editor that just works
struct BasicMarkdownEditor: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                Spacer()
                
                Button("Save") {
                    saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Editor
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                MacTextEditor(text: $content)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            loadFile()
        }
    }
    
    private func loadFile() {
        Task {
            do {
                content = try String(contentsOf: fileURL, encoding: .utf8)
                isLoading = false
            } catch {
                print("Error loading file: \(error)")
                content = ""
                isLoading = false
            }
        }
    }
    
    private func saveFile() {
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving file: \(error)")
        }
    }
}

// Ultra-simple NSTextView wrapper
struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.string = text
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.string != text && !context.coordinator.isUpdating {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: MacTextEditor
        var isUpdating = false
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            isUpdating = false
        }
    }
}