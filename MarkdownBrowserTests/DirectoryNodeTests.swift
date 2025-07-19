import XCTest
import Foundation
@testable import MarkdownBrowser

final class DirectoryNodeTests: XCTestCase {
    
    var tempDirectory: URL!
    var testDirectory: URL!
    var testFile: URL!
    var testMarkdownFile: URL!
    var testHTMLFile: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create temporary directory structure for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Create test subdirectory
        testDirectory = tempDirectory.appendingPathComponent("TestDir")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Create test files
        testFile = tempDirectory.appendingPathComponent("test.txt")
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)
        
        testMarkdownFile = tempDirectory.appendingPathComponent("test.md")
        try "# Test Markdown".write(to: testMarkdownFile, atomically: true, encoding: .utf8)
        
        testHTMLFile = tempDirectory.appendingPathComponent("test.html")
        try "<h1>Test HTML</h1>".write(to: testHTMLFile, atomically: true, encoding: .utf8)
        
        // Create markdown file in subdirectory
        let subMarkdownFile = testDirectory.appendingPathComponent("sub.md")
        try "## Sub Markdown".write(to: subMarkdownFile, atomically: true, encoding: .utf8)
        
        // Create HTML file in subdirectory
        let subHTMLFile = testDirectory.appendingPathComponent("sub.html")
        try "<h2>Sub HTML</h2>".write(to: subHTMLFile, atomically: true, encoding: .utf8)
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    func testDirectoryNodeInitialization() {
        let dirNode = DirectoryNode(url: testDirectory)
        
        XCTAssertEqual(dirNode.url, testDirectory)
        XCTAssertEqual(dirNode.name, "TestDir")
        XCTAssertTrue(dirNode.isDirectory)
        XCTAssertFalse(dirNode.isExpanded)
        XCTAssertTrue(dirNode.children.isEmpty)
        XCTAssertFalse(dirNode.isLoading)
    }
    
    func testFileNodeInitialization() {
        let fileNode = DirectoryNode(url: testFile)
        
        XCTAssertEqual(fileNode.url, testFile)
        XCTAssertEqual(fileNode.name, "test.txt")
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertFalse(fileNode.isExpanded)
        XCTAssertTrue(fileNode.children.isEmpty)
    }
    
    func testLoadChildren() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        
        await dirNode.loadChildren()
        
        XCTAssertFalse(dirNode.children.isEmpty)
        XCTAssertTrue(dirNode.children.count >= 4) // TestDir, test.txt, test.md, test.html
        
        // Verify children are sorted (directories first, then alphabetically)
        _ = dirNode.children.map { $0.name }
        let directories = dirNode.children.filter { $0.isDirectory }.map { $0.name }
        let files = dirNode.children.filter { !$0.isDirectory }.map { $0.name }
        
        XCTAssertTrue(directories.contains("TestDir"))
        XCTAssertTrue(files.contains("test.txt"))
        XCTAssertTrue(files.contains("test.md"))
        XCTAssertTrue(files.contains("test.html"))
    }
    
    func testToggleExpanded() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        
        XCTAssertFalse(dirNode.isExpanded)
        XCTAssertTrue(dirNode.children.isEmpty)
        
        await dirNode.toggleExpanded()
        
        XCTAssertTrue(dirNode.isExpanded)
        XCTAssertFalse(dirNode.children.isEmpty)
        
        await dirNode.toggleExpanded()
        
        XCTAssertFalse(dirNode.isExpanded)
        XCTAssertFalse(dirNode.children.isEmpty) // Children should remain loaded
    }
    
    func testMarkdownFilteredChildren() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        await dirNode.loadChildren()
        
        let filteredChildren = dirNode.markdownFilteredChildren
        let filteredNames = filteredChildren.map { $0.name }
        
        XCTAssertTrue(filteredNames.contains("TestDir")) // Directory should be included
        XCTAssertTrue(filteredNames.contains("test.md")) // Markdown file should be included
        XCTAssertFalse(filteredNames.contains("test.txt")) // Non-markdown file should be excluded
    }
    
    func testSupportedDocumentFilteredChildren() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        await dirNode.loadChildren()
        
        let filteredChildren = dirNode.supportedDocumentFilteredChildren
        let filteredNames = filteredChildren.map { $0.name }
        
        XCTAssertTrue(filteredNames.contains("TestDir")) // Directory should be included
        XCTAssertTrue(filteredNames.contains("test.md")) // Markdown file should be included
        XCTAssertTrue(filteredNames.contains("test.html")) // HTML file should be included
        XCTAssertFalse(filteredNames.contains("test.txt")) // Non-supported file should be excluded
    }
    
    func testSearch() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        await dirNode.loadChildren()
        
        // Load children of subdirectory
        if let subDir = dirNode.children.first(where: { $0.name == "TestDir" }) {
            await subDir.loadChildren()
        }
        
        let results = dirNode.search(query: "test")
        let resultNames = results.map { $0.name }
        
        XCTAssertTrue(resultNames.contains("test.txt"))
        XCTAssertTrue(resultNames.contains("test.md"))
        XCTAssertTrue(resultNames.contains("test.html"))
    }
    
    func testFindChild() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        await dirNode.loadChildren()
        
        // Look for the markdown file by name
        let markdownChild = dirNode.children.first { $0.name == "test.md" }
        XCTAssertNotNil(markdownChild, "Should find test.md in children")
        
        if let markdownChild = markdownChild {
            let foundChild = dirNode.findChild(with: markdownChild.url)
            XCTAssertNotNil(foundChild)
            XCTAssertEqual(foundChild?.name, "test.md")
        }
        
        let notFoundChild = dirNode.findChild(with: URL(fileURLWithPath: "/nonexistent"))
        XCTAssertNil(notFoundChild)
    }
    
    func testRefresh() async {
        let dirNode = DirectoryNode(url: tempDirectory)
        await dirNode.loadChildren()
        await dirNode.toggleExpanded()
        
        let initialChildCount = dirNode.children.count
        
        // Create a new file
        let newFile = tempDirectory.appendingPathComponent("new.md")
        do {
            try "# New file".write(to: newFile, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to write file: \(error)")
            return
        }
        
        await dirNode.refresh()
        
        XCTAssertTrue(dirNode.children.count > initialChildCount)
        XCTAssertTrue(dirNode.children.contains { $0.name == "new.md" })
        
        // Clean up
        try? FileManager.default.removeItem(at: newFile)
    }
    
    func testEquality() {
        let node1 = DirectoryNode(url: testFile)
        let node2 = DirectoryNode(url: testFile)
        let node3 = DirectoryNode(url: testMarkdownFile)
        
        XCTAssertEqual(node1, node2)
        XCTAssertNotEqual(node1, node3)
    }
    
    func testHashable() {
        let node1 = DirectoryNode(url: testFile)
        let node2 = DirectoryNode(url: testFile)
        let node3 = DirectoryNode(url: testMarkdownFile)
        
        let set: Set<DirectoryNode> = [node1, node2, node3]
        XCTAssertEqual(set.count, 2) // node1 and node2 should be considered the same
    }
}