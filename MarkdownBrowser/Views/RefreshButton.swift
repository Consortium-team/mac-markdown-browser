import SwiftUI
import Foundation

/// A refresh button component that reloads the current document from disk
struct RefreshButton: View {
    @ObservedObject var viewModel: MarkdownViewModel
    @State private var isPressed = false
    
    var body: some View {
        Button(action: refresh) {
            Image(systemName: "arrow.clockwise")
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .keyboardShortcut("r", modifiers: .command)
        .help("Reload file from disk (⌘R)")
        .accessibilityLabel("Refresh file from disk")
    }
    
    private func refresh() {
        // Quick press animation
        isPressed = true
        
        // Fire and forget the refresh
        Task {
            await viewModel.refreshContent()
        }
        
        // Reset button state immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }
}

#Preview {
    RefreshButton(viewModel: MarkdownViewModel())
        .padding()
}