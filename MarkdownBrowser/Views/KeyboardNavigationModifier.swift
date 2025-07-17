import SwiftUI
import AppKit

struct KeyboardNavigationModifier: ViewModifier {
    @ObservedObject var fileSystemVM: FileSystemViewModel
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
            .background(
                KeyEventHandler(fileSystemVM: fileSystemVM)
            )
    }
}

// NSViewRepresentable to handle keyboard events for macOS 13.0+
struct KeyEventHandler: NSViewRepresentable {
    let fileSystemVM: FileSystemViewModel
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlingView()
        view.fileSystemVM = fileSystemVM
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyHandlingView: NSView {
    weak var fileSystemVM: FileSystemViewModel?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard let fileSystemVM = fileSystemVM else {
            super.keyDown(with: event)
            return
        }
        
        switch event.keyCode {
        case 126: // Up arrow
            fileSystemVM.navigateWithKeyboard(.up)
        case 125: // Down arrow
            fileSystemVM.navigateWithKeyboard(.down)
        case 123: // Left arrow
            fileSystemVM.navigateWithKeyboard(.left)
        case 124: // Right arrow
            fileSystemVM.navigateWithKeyboard(.right)
        case 36: // Return
            if let selected = fileSystemVM.selectedNode {
                if selected.isDirectory {
                    fileSystemVM.toggleExpansion(for: selected)
                } else {
                    fileSystemVM.selectNode(selected)
                }
            }
        case 49: // Space
            // Quick look preview (future enhancement)
            break
        default:
            super.keyDown(with: event)
        }
    }
}

extension View {
    func keyboardNavigation(fileSystemVM: FileSystemViewModel) -> some View {
        self.modifier(KeyboardNavigationModifier(fileSystemVM: fileSystemVM))
    }
}