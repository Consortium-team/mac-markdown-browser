import SwiftUI

@main
struct MarkdownBrowserApp: App {
    @FocusedValue(\.saveAction) var saveAction
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    saveAction?()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(saveAction == nil)
            }
        }
    }
}