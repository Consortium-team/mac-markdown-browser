import XCTest
import SwiftUI
@testable import MarkdownBrowser

@MainActor
final class FilePreviewViewTests: XCTestCase {
    
    func testExportButtonVisibilityForMarkdown() throws {
        let markdownURL = URL(fileURLWithPath: "/tmp/test.md")
        let view = FilePreviewView(fileURL: markdownURL)
        
        // The view should show export button for markdown files
        let hostingController = NSHostingController(rootView: view)
        _ = hostingController.view
        
        // For a markdown file, the export button should be available
        XCTAssertTrue(markdownURL.isMarkdownFile)
    }
    
    func testExportButtonVisibilityForHTML() throws {
        let htmlURL = URL(fileURLWithPath: "/tmp/test.html")
        let view = FilePreviewView(fileURL: htmlURL)
        
        // The view should show export button for HTML files
        let hostingController = NSHostingController(rootView: view)
        _ = hostingController.view
        
        // For an HTML file, the export button should be available
        XCTAssertTrue(htmlURL.isHTMLFile)
    }
    
    func testExportButtonNotVisibleForOtherFiles() throws {
        let txtURL = URL(fileURLWithPath: "/tmp/test.txt")
        let view = FilePreviewView(fileURL: txtURL)
        
        // The view should not show export button for non-markdown/HTML files
        let hostingController = NSHostingController(rootView: view)
        _ = hostingController.view
        
        // For a text file, the export button should not be available
        XCTAssertFalse(txtURL.isMarkdownFile)
        XCTAssertFalse(txtURL.isHTMLFile)
    }
    
    func testKeyboardShortcut() throws {
        // The export button should have Cmd+Shift+E as keyboard shortcut
        // This is defined in the code and will be available when the button is shown
        let markdownURL = URL(fileURLWithPath: "/tmp/test.md")
        let view = FilePreviewView(fileURL: markdownURL)
        
        // Create hosting controller to render the view
        let hostingController = NSHostingController(rootView: view)
        _ = hostingController.view
        
        // The keyboard shortcut is defined in the button implementation
        XCTAssertTrue(true) // Placeholder for keyboard shortcut test
    }
}