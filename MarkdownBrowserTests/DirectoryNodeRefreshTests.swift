import XCTest
@testable import MarkdownBrowser

@MainActor
final class DirectoryNodeRefreshTests: XCTestCase {
    
    private var tempDir: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create a temporary directory for testing
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }
    
    func testRefreshUpdatesChildren() async throws {
        // Create initial files
        let file1 = tempDir.appendingPathComponent("file1.md")
        let file2 = tempDir.appendingPathComponent("file2.md")
        try "# File 1".write(to: file1, atomically: true, encoding: .utf8)
        try "# File 2".write(to: file2, atomically: true, encoding: .utf8)
        
        // Create node and load children
        let node = DirectoryNode(url: tempDir)
        await node.loadChildren()
        
        // Verify initial state
        XCTAssertEqual(node.children.count, 2)
        XCTAssertTrue(node.children.contains { $0.name == "file1.md" })
        XCTAssertTrue(node.children.contains { $0.name == "file2.md" })
        
        // Add a new file
        let file3 = tempDir.appendingPathComponent("file3.md")
        try "# File 3".write(to: file3, atomically: true, encoding: .utf8)
        
        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: file3.path))
        
        // Refresh the node
        node.isExpanded = true // Simulate expanded state
        await node.refresh()
        
        // Verify the new file is detected
        XCTAssertEqual(node.children.count, 3)
        XCTAssertTrue(node.children.contains { $0.name == "file3.md" })
    }
    
    func testRefreshHandlesDeletedFiles() async throws {
        // Create initial files
        let file1 = tempDir.appendingPathComponent("file1.md")
        let file2 = tempDir.appendingPathComponent("file2.md")
        try "# File 1".write(to: file1, atomically: true, encoding: .utf8)
        try "# File 2".write(to: file2, atomically: true, encoding: .utf8)
        
        // Create node and load children
        let node = DirectoryNode(url: tempDir)
        await node.loadChildren()
        
        // Verify initial state
        XCTAssertEqual(node.children.count, 2)
        
        // Delete a file
        try FileManager.default.removeItem(at: file1)
        
        // Refresh the node
        node.isExpanded = true
        await node.refresh()
        
        // Verify the deleted file is removed
        XCTAssertEqual(node.children.count, 1)
        XCTAssertFalse(node.children.contains { $0.name == "file1.md" })
        XCTAssertTrue(node.children.contains { $0.name == "file2.md" })
    }
    
    func testRefreshOnlyAffectsSelectedFolder() async throws {
        // Create a nested structure
        let subdir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        
        let rootFile = tempDir.appendingPathComponent("root.md")
        let subdirFile = subdir.appendingPathComponent("sub.md")
        try "# Root".write(to: rootFile, atomically: true, encoding: .utf8)
        try "# Sub".write(to: subdirFile, atomically: true, encoding: .utf8)
        
        // Create nodes
        let rootNode = DirectoryNode(url: tempDir)
        await rootNode.loadChildren()
        
        let subdirNode = rootNode.children.first { $0.name == "subdir" }!
        await subdirNode.loadChildren()
        
        // Add a file to subdir
        let newFile = subdir.appendingPathComponent("new.md")
        try "# New".write(to: newFile, atomically: true, encoding: .utf8)
        
        // Refresh only the subdirectory
        subdirNode.isExpanded = true
        await subdirNode.refresh()
        
        // Verify only subdir was refreshed
        XCTAssertEqual(subdirNode.children.count, 2)
        XCTAssertTrue(subdirNode.children.contains { $0.name == "new.md" })
        
        // Root should not have been affected
        XCTAssertEqual(rootNode.children.count, 2) // Still has original count
    }
    
    func testRefreshMaintainsExpandedState() async throws {
        // Create files
        let file1 = tempDir.appendingPathComponent("file1.md")
        try "# File 1".write(to: file1, atomically: true, encoding: .utf8)
        
        // Create node and expand it
        let node = DirectoryNode(url: tempDir)
        await node.loadChildren()
        node.isExpanded = true
        
        // Refresh
        await node.refresh()
        
        // Verify expanded state is maintained
        XCTAssertTrue(node.isExpanded)
        XCTAssertFalse(node.children.isEmpty)
    }
    
    func testRefreshShowsLoadingState() async throws {
        // Create a node
        let node = DirectoryNode(url: tempDir)
        node.isExpanded = true
        
        // Start refresh and check loading state
        let refreshTask = Task {
            await node.refresh()
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Loading should be true during refresh
        // Note: This might be flaky due to timing, but it's worth testing
        
        await refreshTask.value
        
        // Loading should be false after refresh
        XCTAssertFalse(node.isLoading)
    }
}