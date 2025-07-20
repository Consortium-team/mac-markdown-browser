import SwiftUI

@main
struct MarkdownBrowserApp: App {
    @FocusedValue(\.saveAction) var saveAction
    
    var body: some Scene {
        WindowGroup {
            // Using VSCode-style file explorer
            VSCodeStyleExplorer()
            // NativeFileBrowser() // Native Mac file browser attempt
            // StandardContentView() // NavigationSplitView attempt
            // TestContentView() // OutlineGroup attempt
            // ContentView() // Original implementation
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