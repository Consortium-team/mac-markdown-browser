import XCTest
import Combine
@testable import MarkdownBrowser

final class FileSystemViewModelTests: XCTestCase {
    
    var viewModel: FileSystemViewModel!
    var mockFileSystemService: MockFileSystemService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockFileSystemService = MockFileSystemService()
        viewModel = FileSystemViewModel(fileSystemService: mockFileSystemService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockFileSystemService = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToDirectory() async {
        // Given
        let testURL = URL(fileURLWithPath: "/test/directory")
        let testNodes = [
            DirectoryNode(url: URL(fileURLWithPath: "/test/directory/file1.md")),
            DirectoryNode(url: URL(fileURLWithPath: "/test/directory/subfolder"))
        ]
        mockFileSystemService.mockNodes = testNodes
        
        // When
        await viewModel.navigateToDirectory(testURL)
        
        // Then
        XCTAssertNotNil(viewModel.rootNode)
        XCTAssertEqual(viewModel.rootNode?.url, testURL)
        XCTAssertEqual(viewModel.rootNode?.children.count, 2)
        XCTAssertTrue(viewModel.expandedNodes.contains(viewModel.rootNode!.id))
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testNavigateToDirectoryWithError() async {
        // Given
        let testURL = URL(fileURLWithPath: "/test/directory")
        mockFileSystemService.shouldThrowError = true
        
        // When
        await viewModel.navigateToDirectory(testURL)
        
        // Then
        XCTAssertNil(viewModel.rootNode)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Node Selection Tests
    
    func testSelectFileNode() async {
        // Given
        await setupTestDirectory()
        let fileNode = viewModel.rootNode!.children.first { !$0.isDirectory }!
        
        // When
        viewModel.selectNode(fileNode)
        
        // Then
        XCTAssertEqual(viewModel.selectedNode?.id, fileNode.id)
        XCTAssertFalse(viewModel.expandedNodes.contains(fileNode.id))
    }
    
    func testSelectDirectoryNode() async {
        // Given
        await setupTestDirectory()
        let dirNode = viewModel.rootNode!.children.first { $0.isDirectory }!
        
        // When
        viewModel.selectNode(dirNode)
        
        // Then
        XCTAssertEqual(viewModel.selectedNode?.id, dirNode.id)
        XCTAssertTrue(viewModel.expandedNodes.contains(dirNode.id))
    }
    
    // MARK: - Expansion Tests
    
    func testToggleExpansion() async {
        // Given
        await setupTestDirectory()
        let dirNode = viewModel.rootNode!.children.first { $0.isDirectory }!
        
        // When - First toggle (expand)
        viewModel.toggleExpansion(for: dirNode)
        
        // Then
        XCTAssertTrue(viewModel.expandedNodes.contains(dirNode.id))
        XCTAssertTrue(dirNode.isExpanded)
        
        // When - Second toggle (collapse)
        viewModel.toggleExpansion(for: dirNode)
        
        // Then
        XCTAssertFalse(viewModel.expandedNodes.contains(dirNode.id))
        XCTAssertFalse(dirNode.isExpanded)
    }
    
    // MARK: - Filtering Tests
    
    func testMarkdownOnlyFilter() async {
        // Given
        await setupTestDirectory()
        viewModel.showAllFiles = false
        
        // When
        let filtered = viewModel.filteredNodes
        
        // Then
        let nonDirectoryNodes = filtered.filter { !$0.isDirectory }
        XCTAssertTrue(nonDirectoryNodes.allSatisfy { $0.isMarkdownFile })
    }
    
    func testAllFilesFilter() async {
        // Given
        await setupTestDirectory()
        viewModel.showAllFiles = true
        
        // When
        let filtered = viewModel.filteredNodes
        
        // Then
        XCTAssertEqual(filtered.count, viewModel.rootNode!.children.count + 1) // +1 for root
    }
    
    // MARK: - Search Tests
    
    func testSearchFunctionality() async {
        // Given
        await setupTestDirectory()
        
        // When
        viewModel.searchText = "file1"
        
        // Wait for debouncer
        let expectation = XCTestExpectation(description: "Search debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        let filtered = viewModel.filteredNodes
        XCTAssertTrue(filtered.allSatisfy { $0.name.lowercased().contains("file1") })
    }
    
    func testEmptySearch() async {
        // Given
        await setupTestDirectory()
        viewModel.searchText = ""
        
        // When
        let filtered = viewModel.filteredNodes
        
        // Then
        XCTAssertTrue(filtered.count > 0)
    }
    
    // MARK: - Keyboard Navigation Tests
    
    func testKeyboardNavigationDown() async {
        // Given
        await setupTestDirectory()
        
        // Ensure we have visible nodes
        guard let root = viewModel.rootNode else {
            XCTFail("No root node")
            return
        }
        
        // The root should have children from our setup
        XCTAssertFalse(root.children.isEmpty, "Root should have children")
        
        // Select the first child
        let firstChild = root.children[0]
        viewModel.selectNode(firstChild)
        
        // When - navigate down
        viewModel.navigateWithKeyboard(.down)
        
        // Then - should select the second child
        if root.children.count > 1 {
            XCTAssertEqual(viewModel.selectedNode?.id, root.children[1].id)
        }
    }
    
    func testKeyboardNavigationUp() async {
        // Given
        await setupTestDirectory()
        
        guard let root = viewModel.rootNode else {
            XCTFail("No root node")
            return
        }
        
        XCTAssertTrue(root.children.count >= 2, "Need at least 2 children for this test")
        
        // Select the second child
        let secondChild = root.children[1]
        viewModel.selectNode(secondChild)
        
        // When - navigate up
        viewModel.navigateWithKeyboard(.up)
        
        // Then - should select the first child
        XCTAssertEqual(viewModel.selectedNode?.id, root.children[0].id)
    }
    
    func testKeyboardNavigationRightOnDirectory() async {
        // Given
        await setupTestDirectory()
        let dirNode = viewModel.rootNode!.children.first { $0.isDirectory }!
        viewModel.selectNode(dirNode)
        
        // Ensure it's not expanded
        if viewModel.expandedNodes.contains(dirNode.id) {
            viewModel.toggleExpansion(for: dirNode)
        }
        
        // When
        viewModel.navigateWithKeyboard(.right)
        
        // Then
        XCTAssertTrue(viewModel.expandedNodes.contains(dirNode.id))
    }
    
    func testKeyboardNavigationLeftOnExpandedDirectory() async {
        // Given
        await setupTestDirectory()
        
        guard let root = viewModel.rootNode else {
            XCTFail("No root node")
            return
        }
        
        // Find the directory node (subfolder)
        guard let dirNode = root.children.first(where: { $0.isDirectory }) else {
            XCTFail("No directory node found in test data")
            return
        }
        
        viewModel.selectNode(dirNode)
        viewModel.toggleExpansion(for: dirNode) // Expand it
        
        // When
        viewModel.navigateWithKeyboard(.left)
        
        // Then
        XCTAssertFalse(viewModel.expandedNodes.contains(dirNode.id))
    }
    
    // MARK: - Refresh Tests
    
    func testRefresh() async {
        // Given
        await setupTestDirectory()
        let originalNodeCount = viewModel.rootNode!.children.count
        
        // Modify mock data
        mockFileSystemService.mockNodes.append(
            DirectoryNode(url: URL(fileURLWithPath: "/test/directory/newfile.md"))
        )
        
        // When
        await viewModel.refresh()
        
        // Then
        XCTAssertEqual(viewModel.rootNode!.children.count, originalNodeCount + 1)
    }
    
    // MARK: - Helper Methods
    
    private func setupTestDirectory() async {
        // Create actual temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create test files and directories
        let file1URL = tempDir.appendingPathComponent("file1.md")
        let file2URL = tempDir.appendingPathComponent("file2.txt")
        let subfolderURL = tempDir.appendingPathComponent("subfolder")
        
        try! "# File 1".write(to: file1URL, atomically: true, encoding: .utf8)
        try! "File 2".write(to: file2URL, atomically: true, encoding: .utf8)
        try! FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
        
        // Create DirectoryNode objects
        let file1 = DirectoryNode(url: file1URL)
        let file2 = DirectoryNode(url: file2URL)
        let subfolder = DirectoryNode(url: subfolderURL)
        
        let testNodes = [file1, file2, subfolder]
        mockFileSystemService.mockNodes = testNodes
        await viewModel.navigateToDirectory(tempDir)
        
        // Ensure root node is expanded to show children
        if let root = viewModel.rootNode {
            viewModel.expandedNodes.insert(root.id)
        }
        
        // Clean up on test completion
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }
    }
    
    private func getVisibleNodes() -> [DirectoryNode] {
        guard let root = viewModel.rootNode else { return [] }
        return viewModel.filteredNodes.filter { $0.id != root.id }
    }
}

// MARK: - Mock FileSystemService

class MockFileSystemService: FileSystemService {
    var mockNodes: [DirectoryNode] = []
    var shouldThrowError = false
    var monitoringEvents: [FileSystemEvent] = []
    
    override func loadDirectory(_ url: URL) async throws -> [DirectoryNode] {
        if shouldThrowError {
            throw FileSystemError.directoryLoadFailed(url, NSError(domain: "Test", code: 1))
        }
        return mockNodes
    }
    
    override func monitorChanges(at url: URL) -> AsyncStream<FileSystemEvent> {
        return AsyncStream { continuation in
            for event in monitoringEvents {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}

// MARK: - FileFilter Tests

final class FileFilterTests: XCTestCase {
    
    func testFileFilterValues() {
        XCTAssertEqual(FileFilter.markdownOnly, FileFilter.markdownOnly)
        XCTAssertEqual(FileFilter.allFiles, FileFilter.allFiles)
        XCTAssertNotEqual(FileFilter.markdownOnly, FileFilter.allFiles)
    }
}

// MARK: - DirectoryNode Extension Tests

final class DirectoryNodeExtensionTests: XCTestCase {
    
    func testIsMarkdownFile() throws {
        // Create temp directory for testing
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Test regular markdown file
        let mdFile = tempDir.appendingPathComponent("file.md")
        try "# Test".write(to: mdFile, atomically: true, encoding: .utf8)
        let mdNode = DirectoryNode(url: mdFile)
        XCTAssertTrue(mdNode.isMarkdownFile)
        
        // Test text file
        let txtFile = tempDir.appendingPathComponent("file.txt")
        try "Test".write(to: txtFile, atomically: true, encoding: .utf8)
        let txtNode = DirectoryNode(url: txtFile)
        XCTAssertFalse(txtNode.isMarkdownFile)
        
        // Test directory with .md extension
        let mdDir = tempDir.appendingPathComponent("folder.md")
        try FileManager.default.createDirectory(at: mdDir, withIntermediateDirectories: true)
        let mdDirNode = DirectoryNode(url: mdDir)
        XCTAssertFalse(mdDirNode.isMarkdownFile)
        
        // Test uppercase markdown file
        let upperMdFile = tempDir.appendingPathComponent("file.MD")
        try "# Test".write(to: upperMdFile, atomically: true, encoding: .utf8)
        let upperMdNode = DirectoryNode(url: upperMdFile)
        XCTAssertTrue(upperMdNode.isMarkdownFile)
    }
}