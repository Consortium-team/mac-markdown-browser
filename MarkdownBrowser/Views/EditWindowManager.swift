import SwiftUI
import AppKit

class EditWindowManager {
    static let shared = EditWindowManager()
    private var editWindows: [URL: NSWindow] = [:]
    private var windowDelegates: [URL: WindowDelegate] = [:]
    
    func openEditWindow(for fileURL: URL) {
        // Check if window already exists
        if let existingWindow = editWindows[fileURL] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let contentView = ProperMarkdownEditor(fileURL: fileURL)
            .frame(minWidth: 1000, minHeight: 700)
            .onDisappear {
                self.editWindows.removeValue(forKey: fileURL)
            }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Edit: \(fileURL.lastPathComponent)"
        window.contentViewController = hostingController
        window.center()
        
        // Make window key and bring to front
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
        
        // Activate app
        NSApp.activate(ignoringOtherApps: true)
        
        // Store reference
        editWindows[fileURL] = window
        
        // Set delegate to clean up
        let delegate = WindowDelegate(fileURL: fileURL, manager: self)
        window.delegate = delegate
        windowDelegates[fileURL] = delegate
    }
    
    func closeEditWindow(for fileURL: URL) {
        editWindows[fileURL]?.close()
        editWindows.removeValue(forKey: fileURL)
        windowDelegates.removeValue(forKey: fileURL)
    }
    
    class WindowDelegate: NSObject, NSWindowDelegate {
        let fileURL: URL
        weak var manager: EditWindowManager?
        
        init(fileURL: URL, manager: EditWindowManager) {
            self.fileURL = fileURL
            self.manager = manager
        }
        
        func windowWillClose(_ notification: Notification) {
            manager?.editWindows.removeValue(forKey: fileURL)
            manager?.windowDelegates.removeValue(forKey: fileURL)
        }
    }
}

// View to open edit window instead of sheet
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