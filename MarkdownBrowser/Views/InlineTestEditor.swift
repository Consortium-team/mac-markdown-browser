import SwiftUI

// Test editor that can be shown inline without a sheet
struct InlineTestEditor: View {
    @State private var text = "Type here..."
    @State private var showEditor = false
    
    var body: some View {
        VStack {
            Button("Toggle Editor") {
                showEditor.toggle()
            }
            .padding()
            
            if showEditor {
                Text("Editor is shown below:")
                DiagnosticTextEditor(text: $text)
                    .frame(height: 200)
                    .border(Color.red, width: 2)
                
                Text("Current text: \(text)")
                    .font(.caption)
            }
        }
        .padding()
    }
}