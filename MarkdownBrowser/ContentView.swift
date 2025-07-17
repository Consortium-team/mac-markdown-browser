import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Markdown Browser")
        }
        .padding()
        .frame(minWidth: 1000, minHeight: 700)
    }
}

#Preview {
    ContentView()
}