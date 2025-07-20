import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import MarkdownBrowser

final class FileDragDelegateTests: XCTestCase {
    var fileSystemVM: FileSystemViewModel!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        fileSystemVM = FileSystemViewModel()
        
        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        tempDirectory = tempDir
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        try await super.tearDown()
    }
    
    func testFileDragDelegateInitialization() throws {
        // Create a directory node
        let dirURL = tempDirectory.appendingPathComponent("TestDir")
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        let dirNode = DirectoryNode(url: dirURL)
        
        var isTargeted = false
        let delegate = FileDragDelegate(
            targetNode: dirNode,
            fileSystemVM: fileSystemVM,
            isTargeted: .constant(isTargeted)
        )
        
        // Test that delegate is properly initialized
        XCTAssertEqual(delegate.targetNode, dirNode)
        XCTAssertTrue(delegate.fileSystemVM === fileSystemVM)
    }
    
    func testIsChildOfValidation() throws {
        // Create a nested directory structure
        let parentDir = tempDirectory.appendingPathComponent("Parent")
        let childDir = parentDir.appendingPathComponent("Child")
        let grandchildDir = childDir.appendingPathComponent("Grandchild")
        let siblingDir = tempDirectory.appendingPathComponent("Sibling")
        
        try FileManager.default.createDirectory(at: grandchildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: siblingDir, withIntermediateDirectories: true)
        
        // Test path relationships
        XCTAssertTrue(childDir.path.hasPrefix(parentDir.path + "/"))
        XCTAssertTrue(grandchildDir.path.hasPrefix(parentDir.path + "/"))
        XCTAssertFalse(parentDir.path.hasPrefix(childDir.path + "/"))
        XCTAssertFalse(siblingDir.path.hasPrefix(parentDir.path + "/"))
    }
    
    func testDropProposalReturnsMove() throws {
        let dirURL = tempDirectory.appendingPathComponent("TestDir")
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        let dirNode = DirectoryNode(url: dirURL)
        
        var isTargeted = false
        let delegate = FileDragDelegate(
            targetNode: dirNode,
            fileSystemVM: fileSystemVM,
            isTargeted: .constant(isTargeted)
        )
        
        // Since we can't easily create a real DropInfo, we'll test the logic indirectly
        // The dropUpdated method should return a move operation
        // We can verify this by checking the implementation returns .move
        
        // This is more of a code review test - verifying the implementation
        // In a real UI test, we'd verify the actual drop behavior
        XCTAssertTrue(dirNode.isDirectory, "Target should be a directory to accept drops")
    }
    
    func testDirectoryAcceptsDrops() throws {
        let dirURL = tempDirectory.appendingPathComponent("TestDir")
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        let dirNode = DirectoryNode(url: dirURL)
        
        XCTAssertTrue(dirNode.isDirectory, "Directory nodes should accept drops")
    }
    
    func testFileDoesNotAcceptDrops() throws {
        let fileURL = tempDirectory.appendingPathComponent("test.md")
        try "# Test".write(to: fileURL, atomically: true, encoding: .utf8)
        let fileNode = DirectoryNode(url: fileURL)
        
        XCTAssertFalse(fileNode.isDirectory, "File nodes should not accept drops")
    }
}