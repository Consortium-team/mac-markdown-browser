import SwiftUI
import AppKit

class EditWindowManager: NSObject {
    static let shared = EditWindowManager()
    private var windows: [URL: NSWindow] = [:]
    
    private override init() {
        super.init()
    }
    
    func openEditWindow(for fileURL: URL) {
        // Check if window already exists
        if let existingWindow = windows[fileURL] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Set up window properties
        window.title = fileURL.lastPathComponent
        window.center()
        window.isReleasedWhenClosed = false // Important: prevent premature deallocation
        
        // Create content view based on file type
        let contentView: AnyView
        if fileURL.isCSVFile {
            contentView = AnyView(ProperCSVEditor(fileURL: fileURL))
        } else {
            // Always use ProperMarkdownEditor for now
            contentView = AnyView(ProperMarkdownEditor(fileURL: fileURL))
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        window.contentViewController = hostingController
        
        // Store window reference
        windows[fileURL] = window
        
        // Set delegate to self
        window.delegate = self
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func cleanupWindow(for url: URL) {
        if let window = windows[url] {
            window.delegate = nil
            window.contentViewController = nil
            windows.removeValue(forKey: url)
        }
    }
}

// MARK: - NSWindowDelegate
extension EditWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Find the URL for this window
        for (url, win) in windows where win === window {
            cleanupWindow(for: url)
            break
        }
    }
}

// MARK: - Button View
struct EditWindowButton: View {
    let fileURL: URL
    
    var body: some View {
        Button(action: {
            EditWindowManager.shared.openEditWindow(for: fileURL)
        }) {
            Image(systemName: "pencil")
        }
        .buttonStyle(.borderless)
        .keyboardShortcut("e", modifiers: .command)
        .help("Edit (⌘E)")
    }
}