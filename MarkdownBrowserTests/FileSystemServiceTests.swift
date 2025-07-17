import XCTest
import Foundation
@testable import MarkdownBrowser

final class FileSystemServiceTests: XCTestCase {
    
    var fileSystemService: FileSystemService!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        fileSystemService = FileSystemService()
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileSystemServiceTests")
            .appendingPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        fileSystemService = nil
        super.tearDown()
    }
    
    // MARK: - Directory Loading Tests
    
    func testLoadEmptyDirectory() async throws {
        let nodes = try await fileSystemService.loadDirectory(tempDirectory)
        XCTAssertTrue(nodes.isEmpty, "Empty directory should return no nodes")
    }
    
    func testLoadDirectoryWithFiles() async throws {
        // Create test files
        let file1 = tempDirectory.appendingPathComponent("test1.md")
        let file2 = tempDirectory.appendingPathComponent("test2.txt")
        let subdir = tempDirectory.appendingPathComponent("subdir")
        
        try "# Test 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Test content".write(to: file2, atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true, attributes: nil)
        
        let nodes = try await fileSystemService.loadDirectory(tempDirectory)
        
        XCTAssertEqual(nodes.count, 3, "Should find 3 items")
        
        let sortedNodes = nodes.sorted { $0.name < $1.name }
        XCTAssertEqual(sortedNodes[0].name, "subdir")
        XCTAssertTrue(sortedNodes[0].isDirectory)
        XCTAssertEqual(sortedNodes[1].name, "test1.md")
        XCTAssertFalse(sortedNodes[1].isDirectory)
        XCTAssertEqual(sortedNodes[2].name, "test2.txt")
        XCTAssertFalse(sortedNodes[2].isDirectory)
    }
    
    func testLoadNonExistentDirectory() async {
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent")
        
        do {
            _ = try await fileSystemService.loadDirectory(nonExistentURL)
            XCTFail("Should throw error for non-existent directory")
        } catch {
            XCTAssertTrue(error is FileSystemError, "Should throw FileSystemError")
        }
    }
    
    // MARK: - Bookmark Tests
    
    func testCreateAndResolveBookmark() {
        // Create bookmark
        guard let bookmarkData = fileSystemService.createBookmark(for: tempDirectory) else {
            XCTFail("Failed to create bookmark")
            return
        }
        
        XCTAssertFalse(bookmarkData.isEmpty, "Bookmark data should not be empty")
        
        // Resolve bookmark
        guard let resolvedURL = fileSystemService.resolveBookmark(bookmarkData) else {
            XCTFail("Failed to resolve bookmark")
            return
        }
        
        XCTAssertEqual(resolvedURL.standardizedFileURL.path, tempDirectory.standardizedFileURL.path, "Resolved URL should match original")
        
        // Clean up security-scoped resource
        fileSystemService.stopAccessingSecurityScopedResource(resolvedURL)
    }
    
    func testResolveInvalidBookmark() {
        let invalidData = Data([0x00, 0x01, 0x02])
        let resolvedURL = fileSystemService.resolveBookmark(invalidData)
        XCTAssertNil(resolvedURL, "Should return nil for invalid bookmark data")
    }
    
    // MARK: - Accessibility Tests
    
    func testIsAccessible() {
        XCTAssertTrue(fileSystemService.isAccessible(tempDirectory), "Temp directory should be accessible")
        
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent")
        XCTAssertFalse(fileSystemService.isAccessible(nonExistentURL), "Non-existent path should not be accessible")
    }
    
    // MARK: - File Attributes Tests
    
    func testGetFileAttributes() throws {
        let testFile = tempDirectory.appendingPathComponent("test.md")
        try "# Test".write(to: testFile, atomically: true, encoding: .utf8)
        
        let attributes = try fileSystemService.getFileAttributes(for: testFile)
        
        XCTAssertNotNil(attributes[.size], "Should have file size")
        XCTAssertNotNil(attributes[.modificationDate], "Should have modification date")
        XCTAssertNotNil(attributes[.type], "Should have file type")
    }
    
    func testGetFileAttributesForNonExistentFile() {
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.md")
        
        XCTAssertThrowsError(try fileSystemService.getFileAttributes(for: nonExistentFile)) { error in
            XCTAssertTrue(error is CocoaError, "Should throw CocoaError for non-existent file")
        }
    }
    
    // MARK: - File System Monitoring Tests
    
    func testFileSystemMonitoring() async throws {
        let expectation = XCTestExpectation(description: "File system event received")
        expectation.expectedFulfillmentCount = 1
        
        let monitoringTask = Task {
            let eventStream = fileSystemService.monitorChanges(at: tempDirectory)
            
            for await event in eventStream {
                if event.path.contains("newfile.md") {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Give monitoring a moment to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Create a new file to trigger an event
        let newFile = tempDirectory.appendingPathComponent("newfile.md")
        try "# New File".write(to: newFile, atomically: true, encoding: .utf8)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        monitoringTask.cancel()
    }
    
    // MARK: - Performance Tests
    
    func testLoadDirectoryPerformance() throws {
        // Create many files for performance testing
        for i in 0..<100 {
            let file = tempDirectory.appendingPathComponent("file\(i).md")
            try "# File \(i)".write(to: file, atomically: true, encoding: .utf8)
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Directory loaded")
            
            Task {
                do {
                    _ = try await fileSystemService.loadDirectory(tempDirectory)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to load directory: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFileSystemErrorDescriptions() {
        let url = URL(fileURLWithPath: "/test/path")
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let directoryError = FileSystemError.directoryLoadFailed(url, underlyingError)
        XCTAssertTrue(directoryError.errorDescription?.contains("/test/path") == true)
        XCTAssertTrue(directoryError.errorDescription?.contains("Test error") == true)
        
        let bookmarkError = FileSystemError.bookmarkCreationFailed(url)
        XCTAssertTrue(bookmarkError.errorDescription?.contains("/test/path") == true)
        
        let resolutionError = FileSystemError.bookmarkResolutionFailed
        XCTAssertNotNil(resolutionError.errorDescription)
        
        let serviceError = FileSystemError.serviceUnavailable
        XCTAssertNotNil(serviceError.errorDescription)
        
        let accessError = FileSystemError.accessDenied(url)
        XCTAssertTrue(accessError.errorDescription?.contains("/test/path") == true)
    }
}

// MARK: - FileSystemEvent Tests

final class FileSystemEventTests: XCTestCase {
    
    func testFileSystemEventProperties() {
        let event = FileSystemEvent(
            path: "/test/path/file.md",
            flags: [.itemCreated, .itemIsFile],
            eventId: 12345
        )
        
        XCTAssertEqual(event.path, "/test/path/file.md")
        XCTAssertEqual(event.url.path, "/test/path/file.md")
        XCTAssertEqual(event.eventId, 12345)
        XCTAssertTrue(event.isCreated)
        XCTAssertFalse(event.isModified)
        XCTAssertFalse(event.isRemoved)
        XCTAssertFalse(event.isRenamed)
    }
    
    func testFileSystemEventFlags() {
        let createdEvent = FileSystemEvent(
            path: "/test",
            flags: .itemCreated,
            eventId: 1
        )
        XCTAssertTrue(createdEvent.isCreated)
        
        let modifiedEvent = FileSystemEvent(
            path: "/test",
            flags: .itemModified,
            eventId: 2
        )
        XCTAssertTrue(modifiedEvent.isModified)
        
        let removedEvent = FileSystemEvent(
            path: "/test",
            flags: .itemRemoved,
            eventId: 3
        )
        XCTAssertTrue(removedEvent.isRemoved)
        
        let renamedEvent = FileSystemEvent(
            path: "/test",
            flags: .itemRenamed,
            eventId: 4
        )
        XCTAssertTrue(renamedEvent.isRenamed)
    }
}