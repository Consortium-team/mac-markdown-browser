import XCTest
import Foundation
@testable import MarkdownBrowser

final class MarkdownDocumentTests: XCTestCase {
    
    var tempDirectory: URL!
    var testMarkdownFile: URL!
    var testDocument: MarkdownDocument!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Create test markdown file
        testMarkdownFile = tempDirectory.appendingPathComponent("test.md")
        let testContent = """
        # Test Document
        
        This is a test markdown document.
        
        ## Features
        
        - Lists
        - **Bold text**
        - *Italic text*
        
        ```swift
        let code = "example"
        ```
        """
        try testContent.write(to: testMarkdownFile, atomically: true, encoding: .utf8)
        
        testDocument = MarkdownDocument(url: testMarkdownFile)
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    func testDocumentInitialization() {
        XCTAssertEqual(testDocument.url, testMarkdownFile)
        XCTAssertEqual(testDocument.name, "test.md")
        XCTAssertTrue(testDocument.content.isEmpty)
        XCTAssertTrue(testDocument.renderedHTML.isEmpty)
        XCTAssertFalse(testDocument.isLoading)
        XCTAssertFalse(testDocument.hasUnsavedChanges)
        XCTAssertNil(testDocument.lastModified)
        XCTAssertNil(testDocument.error)
    }
    
    func testLoadContent() async {
        await testDocument.loadContent()
        
        XCTAssertFalse(testDocument.isLoading)
        XCTAssertFalse(testDocument.content.isEmpty)
        XCTAssertTrue(testDocument.content.contains("# Test Document"))
        XCTAssertTrue(testDocument.content.contains("This is a test markdown document"))
        XCTAssertFalse(testDocument.hasUnsavedChanges)
        XCTAssertNotNil(testDocument.lastModified)
        XCTAssertNil(testDocument.error)
    }
    
    func testLoadContentWithInvalidFile() async {
        let invalidFile = tempDirectory.appendingPathComponent("nonexistent.md")
        let invalidDocument = MarkdownDocument(url: invalidFile)
        
        await invalidDocument.loadContent()
        
        XCTAssertFalse(invalidDocument.isLoading)
        XCTAssertTrue(invalidDocument.content.isEmpty)
        XCTAssertNotNil(invalidDocument.error)
        
        if case .loadFailed = invalidDocument.error {
            // Expected error type
        } else {
            XCTFail("Expected loadFailed error")
        }
    }
    
    func testUpdateContent() async {
        await testDocument.loadContent()
        
        let newContent = "# Updated Document\n\nThis content has been updated."
        testDocument.updateContent(newContent)
        
        XCTAssertEqual(testDocument.content, newContent)
        XCTAssertTrue(testDocument.hasUnsavedChanges)
    }
    
    func testSaveContent() async {
        await testDocument.loadContent()
        
        let newContent = "# Updated Document\n\nThis content has been updated."
        testDocument.updateContent(newContent)
        
        XCTAssertTrue(testDocument.hasUnsavedChanges)
        
        await testDocument.saveContent()
        
        XCTAssertFalse(testDocument.hasUnsavedChanges)
        XCTAssertNil(testDocument.error)
        
        // Verify content was actually saved
        let savedContent = try? String(contentsOf: testMarkdownFile, encoding: .utf8)
        XCTAssertEqual(savedContent, newContent)
    }
    
    func testSaveContentWithoutChanges() async {
        await testDocument.loadContent()
        
        let originalModified = testDocument.lastModified
        
        // Save without making changes
        await testDocument.saveContent()
        
        // Should not have changed the file
        XCTAssertEqual(testDocument.lastModified, originalModified)
        XCTAssertFalse(testDocument.hasUnsavedChanges)
    }
    
    func testReloadFromDisk() async {
        await testDocument.loadContent()
        
        // Modify content in memory
        testDocument.updateContent("Modified content")
        XCTAssertTrue(testDocument.hasUnsavedChanges)
        
        // Reload from disk
        await testDocument.reloadFromDisk()
        
        XCTAssertFalse(testDocument.hasUnsavedChanges)
        XCTAssertTrue(testDocument.content.contains("# Test Document"))
        XCTAssertFalse(testDocument.content.contains("Modified content"))
    }
    
    func testHasExternalChanges() async {
        await testDocument.loadContent()
        
        // Initially no external changes
        XCTAssertFalse(testDocument.hasExternalChanges())
        
        // Modify file externally
        let externalContent = "# Externally Modified\n\nThis was changed externally."
        try? externalContent.write(to: testMarkdownFile, atomically: true, encoding: .utf8)
        
        // Small delay to ensure file modification time changes
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertTrue(testDocument.hasExternalChanges())
    }
    
    func testFileSize() async {
        await testDocument.loadContent()
        
        let fileSize = testDocument.fileSize
        XCTAssertGreaterThan(fileSize, 0)
        
        let formattedSize = testDocument.formattedFileSize
        XCTAssertFalse(formattedSize.isEmpty)
        XCTAssertTrue(formattedSize.contains("bytes") || formattedSize.contains("KB"))
    }
    
    func testIsMarkdownFile() {
        XCTAssertTrue(testDocument.isMarkdownFile)
        
        let textFile = tempDirectory.appendingPathComponent("test.txt")
        let textDocument = MarkdownDocument(url: textFile)
        XCTAssertFalse(textDocument.isMarkdownFile)
        
        let mdFile = tempDirectory.appendingPathComponent("test.MD")
        let mdDocument = MarkdownDocument(url: mdFile)
        XCTAssertTrue(mdDocument.isMarkdownFile) // Should handle uppercase extension
    }
    
    func testDocumentEquality() {
        let document1 = MarkdownDocument(url: testMarkdownFile)
        let document2 = MarkdownDocument(url: testMarkdownFile)
        
        XCTAssertEqual(document1, document2)
        
        let otherFile = tempDirectory.appendingPathComponent("other.md")
        let document3 = MarkdownDocument(url: otherFile)
        
        XCTAssertNotEqual(document1, document3)
    }
    
    func testDocumentHashable() {
        let document1 = MarkdownDocument(url: testMarkdownFile)
        let document2 = MarkdownDocument(url: testMarkdownFile)
        
        let set: Set<MarkdownDocument> = [document1, document2]
        XCTAssertEqual(set.count, 1) // Should be considered the same
        
        let otherFile = tempDirectory.appendingPathComponent("other.md")
        let document3 = MarkdownDocument(url: otherFile)
        
        let set2: Set<MarkdownDocument> = [document1, document3]
        XCTAssertEqual(set2.count, 2) // Should be different
    }
    
    func testDocumentErrorDescriptions() {
        let loadError = DocumentError.loadFailed("File not found")
        XCTAssertTrue(loadError.errorDescription?.contains("Failed to load") == true)
        XCTAssertTrue(loadError.recoverySuggestion?.contains("permission") == true)
        
        let saveError = DocumentError.saveFailed("Permission denied")
        XCTAssertTrue(saveError.errorDescription?.contains("Failed to save") == true)
        XCTAssertTrue(saveError.recoverySuggestion?.contains("permission") == true)
        
        let conflictError = DocumentError.conflictDetected
        XCTAssertTrue(conflictError.errorDescription?.contains("modified externally") == true)
        XCTAssertTrue(conflictError.recoverySuggestion?.contains("reload") == true)
        
        let formatError = DocumentError.invalidFormat
        XCTAssertTrue(formatError.errorDescription?.contains("not supported") == true)
        XCTAssertTrue(formatError.recoverySuggestion?.contains("valid Markdown") == true)
    }
    
    func testConcurrentLoadOperations() async {
        // Test that multiple load operations don't interfere with each other
        let task1 = Task { await testDocument.loadContent() }
        let task2 = Task { await testDocument.loadContent() }
        let task3 = Task { await testDocument.loadContent() }
        
        await task1.value
        await task2.value
        await task3.value
        
        XCTAssertFalse(testDocument.isLoading)
        XCTAssertFalse(testDocument.content.isEmpty)
        XCTAssertNil(testDocument.error)
    }
    
    func testLargeFileHandling() async {
        // Create a larger test file
        let largeContent = String(repeating: "This is a line of text that will be repeated many times.\n", count: 1000)
        let largeFile = tempDirectory.appendingPathComponent("large.md")
        try? largeContent.write(to: largeFile, atomically: true, encoding: .utf8)
        
        let largeDocument = MarkdownDocument(url: largeFile)
        await largeDocument.loadContent()
        
        XCTAssertFalse(largeDocument.isLoading)
        XCTAssertEqual(largeDocument.content.count, largeContent.count)
        XCTAssertGreaterThan(largeDocument.fileSize, 50000) // Should be > 50KB
        XCTAssertNil(largeDocument.error)
    }
}