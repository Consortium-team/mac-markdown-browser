import SwiftUI

@main
struct MarkdownBrowserApp: App {
    @FocusedValue(\.saveAction) var saveAction
    
    var body: some Scene {
        WindowGroup {
            VSCodeStyleExplorer() // Using VSCode-style file explorer
            // ContentView() // Original implementation with favorites
            // NativeFileBrowser() // Native Mac file browser attempt
            // StandardContentView() // NavigationSplitView attempt
            // TestContentView() // OutlineGroup attempt
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
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