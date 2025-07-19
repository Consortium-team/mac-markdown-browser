import XCTest
@testable import MarkdownBrowser

@MainActor
class MarkdownViewModelTests: XCTestCase {
    
    var viewModel: MarkdownViewModel!
    var testFileURL: URL!
    var testDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        viewModel = MarkdownViewModel()
        
        // Create test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("MarkdownViewModelTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Create test file
        testFileURL = testDirectory.appendingPathComponent("test.md")
        let testContent = """
        # Test Document
        
        This is a test paragraph with **bold** and *italic* text.
        
        ## Code Example
        
        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```
        
        ## Links and Images
        
        [Example Link](https://example.com)
        
        ## Table
        
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        
        try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
    }
    
    override func tearDown() async throws {
        // Clean up test files
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
        
        viewModel = nil
        testFileURL = nil
        testDirectory = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Document Loading Tests
    
    func testLoadDocument() async throws {
        // Load document
        await viewModel.loadDocument(at: testFileURL)
        
        // Verify document is loaded
        XCTAssertNotNil(viewModel.currentDocument)
        XCTAssertEqual(viewModel.currentDocument?.url, testFileURL)
        XCTAssertFalse(viewModel.currentDocument?.content.isEmpty ?? true)
        
        // Verify rendering occurred
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Test Document</h1>"))
        XCTAssertTrue(viewModel.renderedHTML.contains("<strong>bold</strong>"))
        XCTAssertTrue(viewModel.renderedHTML.contains("<em>italic</em>"))
    }
    
    func testLoadNonExistentDocument() async throws {
        let nonExistentURL = testDirectory.appendingPathComponent("nonexistent.md")
        
        await viewModel.loadDocument(at: nonExistentURL)
        
        XCTAssertNotNil(viewModel.currentDocument)
        XCTAssertNotNil(viewModel.currentDocument?.error)
        XCTAssertTrue(viewModel.renderedHTML.isEmpty || viewModel.renderedHTML.contains("error"))
    }
    
    // MARK: - Rendering Tests
    
    func testRenderCurrentDocument() async throws {
        // Load document first
        await viewModel.loadDocument(at: testFileURL)
        
        // Clear rendered HTML
        viewModel.renderedHTML = ""
        
        // Re-render
        await viewModel.renderCurrentDocument()
        
        // Verify rendering
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Test Document</h1>"))
    }
    
    func testRenderPerformance() async throws {
        // Create large document
        let largeURL = testDirectory.appendingPathComponent("large.md")
        var largeContent = "# Large Document\n\n"
        
        // Add 1000 paragraphs
        for i in 0..<1000 {
            largeContent += "This is paragraph \(i) with some **bold** text and *italic* text.\n\n"
        }
        
        try largeContent.write(to: largeURL, atomically: true, encoding: .utf8)
        
        // Measure performance
        let startTime = Date()
        await viewModel.loadDocument(at: largeURL)
        let renderTime = Date().timeIntervalSince(startTime)
        
        // Should render within 100ms as per requirements (allowing some margin for test environment)
        XCTAssertLessThan(renderTime, 0.15, "Rendering took too long: \(renderTime)s")
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
    }
    
    // MARK: - Content Update Tests
    
    func testUpdateContent() async throws {
        // Load document
        await viewModel.loadDocument(at: testFileURL)
        
        let newContent = "# Updated Content\n\nThis is new content."
        
        // Update content
        viewModel.updateContent(newContent)
        
        // Verify document is marked as having unsaved changes
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.currentDocument?.content, newContent)
        
        // Wait for debounced rendering
        try await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        // Verify new content is rendered
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Updated Content</h1>"))
    }
    
    // MARK: - Save Tests
    
    func testSaveDocument() async throws {
        // Load document
        await viewModel.loadDocument(at: testFileURL)
        
        // Update content
        let newContent = "# Saved Content\n\nThis content will be saved."
        viewModel.updateContent(newContent)
        
        // Save
        await viewModel.saveCurrentDocument()
        
        // Verify save
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        
        // Verify file was actually saved
        let savedContent = try String(contentsOf: testFileURL)
        XCTAssertEqual(savedContent, newContent)
    }
    
    // MARK: - Cache Tests
    
    func testCaching() async throws {
        // Load document - should cache
        await viewModel.loadDocument(at: testFileURL)
        let firstHTML = viewModel.renderedHTML
        
        // Clear current document
        viewModel.currentDocument = nil
        viewModel.renderedHTML = ""
        
        // Load same document again - should use cache
        let startTime = Date()
        await viewModel.loadDocument(at: testFileURL)
        let cacheTime = Date().timeIntervalSince(startTime)
        
        // Cache retrieval should be very fast
        XCTAssertLessThan(cacheTime, 0.01, "Cache retrieval took too long")
        XCTAssertEqual(viewModel.renderedHTML, firstHTML)
    }
    
    func testCacheInvalidation() async throws {
        // Load document
        await viewModel.loadDocument(at: testFileURL)
        
        // Modify file externally
        let newContent = "# Modified Externally"
        try newContent.write(to: testFileURL, atomically: true, encoding: .utf8)
        
        // Wait a bit for file system
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Load again - cache should be invalidated
        await viewModel.loadDocument(at: testFileURL)
        
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Modified Externally</h1>"))
    }
    
    func testClearCache() async throws {
        // Load multiple documents to populate cache
        for i in 0..<5 {
            let url = testDirectory.appendingPathComponent("test\(i).md")
            try "# Document \(i)".write(to: url, atomically: true, encoding: .utf8)
            await viewModel.loadDocument(at: url)
        }
        
        // Clear cache
        viewModel.clearCache()
        
        // Load first document again - should not use cache
        await viewModel.loadDocument(at: testDirectory.appendingPathComponent("test0.md"))
        
        // If we had a way to check cache misses, we would verify here
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Document 0</h1>"))
    }
    
    // MARK: - Mermaid Tests
    
    func testMermaidBlockExtraction() async throws {
        let mermaidURL = testDirectory.appendingPathComponent("mermaid.md")
        let mermaidContent = """
        # Mermaid Test
        
        Here's a flowchart:
        
        ```mermaid
        graph TD
            A[Start] --> B{Is it?}
            B -->|Yes| C[OK]
            B -->|No| D[End]
        ```
        
        And another diagram:
        
        ```mermaid
        sequenceDiagram
            Alice->>Bob: Hello Bob
            Bob-->>Alice: Hi Alice
        ```
        """
        
        try mermaidContent.write(to: mermaidURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: mermaidURL)
        
        // Verify Mermaid blocks were extracted
        XCTAssertEqual(viewModel.mermaidBlocks.count, 2)
        XCTAssertTrue(viewModel.mermaidBlocks[0].code.contains("graph TD"))
        XCTAssertTrue(viewModel.mermaidBlocks[1].code.contains("sequenceDiagram"))
        
        // Verify placeholders in HTML
        XCTAssertTrue(viewModel.renderedHTML.contains("mermaid-placeholder"))
    }
    
    // MARK: - Error Handling Tests
    
    func testRenderingError() async throws {
        // This is a bit tricky to test since swift-markdown is quite robust
        // We'll test with an empty document
        let emptyURL = testDirectory.appendingPathComponent("empty.md")
        try "".write(to: emptyURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: emptyURL)
        
        // Should handle empty content gracefully
        XCTAssertTrue(viewModel.renderedHTML.isEmpty || viewModel.renderedHTML.contains("<body>"))
        XCTAssertNil(viewModel.renderError)
    }
    
    // MARK: - Reload Tests
    
    func testReloadDocument() async throws {
        // Load document
        await viewModel.loadDocument(at: testFileURL)
        
        // Modify content
        viewModel.updateContent("# Modified Content")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        
        // Reload from disk
        await viewModel.reloadCurrentDocument()
        
        // Should discard changes
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertTrue(viewModel.renderedHTML.contains("<h1>Test Document</h1>"))
    }
    
    // MARK: - Computed Properties Tests
    
    func testComputedProperties() async throws {
        // Before loading
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.documentName, "Untitled")
        XCTAssertEqual(viewModel.documentSize, "0 KB")
        XCTAssertNil(viewModel.lastModified)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.documentError)
        
        // After loading
        await viewModel.loadDocument(at: testFileURL)
        
        XCTAssertEqual(viewModel.documentName, "test.md")
        // File size assertion depends on actual content length
        XCTAssertFalse(viewModel.documentSize.isEmpty)
        XCTAssertNotNil(viewModel.lastModified)
    }
}