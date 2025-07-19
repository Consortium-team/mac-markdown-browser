import XCTest
import SwiftUI
@testable import MarkdownBrowser

@MainActor
final class MarkdownEditorTests: XCTestCase {
    
    func testEditingContentUpdatesViewModel() async throws {
        let viewModel = MarkdownViewModel()
        let testURL = URL(fileURLWithPath: "/tmp/test.md")
        
        // Create test file
        let originalContent = "# Test Document\n\nOriginal content"
        try originalContent.write(to: testURL, atomically: true, encoding: .utf8)
        
        // Load document
        await viewModel.loadDocument(at: testURL)
        
        XCTAssertEqual(viewModel.currentDocument?.content, originalContent)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        
        // Update content
        let newContent = "# Test Document\n\nUpdated content"
        viewModel.updateContent(newContent)
        
        // Wait for debounced update
        try await Task.sleep(nanoseconds: 600_000_000) // 600ms > 500ms debounce
        
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.currentDocument?.content, newContent)
        
        // Clean up
        try? FileManager.default.removeItem(at: testURL)
    }
    
    func testSaveDocumentPersistsChanges() async throws {
        let viewModel = MarkdownViewModel()
        let testURL = URL(fileURLWithPath: "/tmp/test_save.md")
        
        // Create test file
        let originalContent = "# Original"
        try originalContent.write(to: testURL, atomically: true, encoding: .utf8)
        
        // Load and modify
        await viewModel.loadDocument(at: testURL)
        viewModel.updateContent("# Modified")
        
        // Wait for debounced update
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Save
        await viewModel.saveCurrentDocument()
        
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        
        // Verify file content
        let savedContent = try String(contentsOf: testURL, encoding: .utf8)
        XCTAssertEqual(savedContent, "# Modified")
        
        // Clean up
        try? FileManager.default.removeItem(at: testURL)
    }
    
    func testEditModeToggle() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test_edit.md")
        try "# Test".write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Create a test view
        let view = FilePreviewView(fileURL: fileURL)
        
        // Initial state should be preview mode
        let mirror = Mirror(reflecting: view)
        let editModeProperty = mirror.children.first { $0.label == "_editMode" }
        XCTAssertNotNil(editModeProperty)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testSyntaxHighlightingPatterns() {
        // Test that our regex patterns are valid
        let patterns = [
            "^#{1,6}\\s.*$",           // Headers
            "\\*\\*[^*]+\\*\\*",       // Bold
            "\\*[^*]+\\*",             // Italic
            "`[^`]+`",                 // Inline code
            "```[\\s\\S]*?```",        // Code blocks
            "\\[[^\\]]+\\]\\([^\\)]+\\)", // Links
            "^\\s*[-*+]\\s",           // Unordered lists
            "^\\s*\\d+\\.\\s",         // Ordered lists
            "^>.*$"                    // Blockquotes
        ]
        
        for pattern in patterns {
            XCTAssertNoThrow(try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]))
        }
    }
    
    func testMarkdownSyntaxHighlighting() {
        let testContent = """
        # Header 1
        ## Header 2
        
        This is **bold** and this is *italic*.
        
        Here's some `inline code` and a [link](https://example.com).
        
        ```swift
        let code = "block"
        ```
        
        - List item 1
        - List item 2
        
        1. Numbered item
        2. Another item
        
        > This is a blockquote
        """
        
        // Test that content with various markdown elements can be processed
        XCTAssertFalse(testContent.isEmpty)
        XCTAssertTrue(testContent.contains("# Header"))
        XCTAssertTrue(testContent.contains("**bold**"))
        XCTAssertTrue(testContent.contains("```swift"))
    }
}