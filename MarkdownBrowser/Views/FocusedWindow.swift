import SwiftUI
import AppKit

// Custom window that ensures it becomes key
class FocusedWindow: NSWindow {
    override func becomeKey() {
        super.becomeKey()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Window accessor to customize sheet windows
struct WindowAccessor: NSViewRepresentable {
    let onWindowAvailable: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowAvailable(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                self.onWindowAvailable(window)
            }
        }
    }
}

// View modifier to ensure window activation
struct EnsureWindowActivation: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    // Force activation
                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                    window.makeMain()
                    
                    // Set level temporarily to ensure it's on top
                    window.level = .floating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        window.level = .normal
                    }
                }
                .frame(width: 0, height: 0)
            )
    }
}

extension View {
    func ensureWindowActivation() -> some View {
        modifier(EnsureWindowActivation())
    }
}