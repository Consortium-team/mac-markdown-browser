import XCTest
import Foundation
@testable import MarkdownBrowser

@MainActor
final class DownloadSaveManagerTests: XCTestCase {
    var sut: DownloadSaveManager!
    var testDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = DownloadSaveManager.shared
        
        // Create a test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("DownloadSaveManagerTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        
        sut = nil
        try await super.tearDown()
    }
    
    func testSaveToDownloads() async throws {
        let testData = "Test PDF Content".data(using: .utf8)!
        let baseFilename = "test-document"
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: baseFilename,
            fileExtension: "pdf"
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertTrue(savedURL.lastPathComponent.contains(baseFilename))
        XCTAssertTrue(savedURL.pathExtension == "pdf")
        
        // Check file content
        let savedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(savedData, testData)
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testGenerateUniqueFilename() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let baseFilename = "duplicate-test"
        
        // Save first file
        let firstURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: baseFilename
        )
        
        // Save second file with same base name
        let secondURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: baseFilename
        )
        
        // Files should have different names
        XCTAssertNotEqual(firstURL.lastPathComponent, secondURL.lastPathComponent)
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))
        
        // Clean up
        try? FileManager.default.removeItem(at: firstURL)
        try? FileManager.default.removeItem(at: secondURL)
    }
    
    func testSanitizeFilename() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let problematicFilename = "test/file:with*illegal|characters?"
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: problematicFilename
        )
        
        // Check that illegal characters were replaced
        let filename = savedURL.lastPathComponent
        XCTAssertFalse(filename.contains("/"))
        XCTAssertFalse(filename.contains(":"))
        XCTAssertFalse(filename.contains("*"))
        XCTAssertFalse(filename.contains("|"))
        XCTAssertFalse(filename.contains("?"))
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testEmptyFilename() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let emptyFilename = "   "
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: emptyFilename
        )
        
        // Should use default filename
        XCTAssertTrue(savedURL.lastPathComponent.contains("document"))
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testLongFilename() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let longFilename = String(repeating: "a", count: 300)
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: longFilename
        )
        
        // Filename should be truncated
        let filenameWithoutExtension = savedURL.deletingPathExtension().lastPathComponent
        // Remove timestamp part to check base name length
        let parts = filenameWithoutExtension.split(separator: "_")
        if let firstPart = parts.first {
            XCTAssertLessThanOrEqual(firstPart.count, 200)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testCheckDownloadsPermission() {
        let hasPermission = sut.checkDownloadsPermission()
        // Should have permission in test environment
        XCTAssertTrue(hasPermission)
    }
    
    func testCustomFileExtension() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let baseFilename = "test-document"
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: baseFilename,
            fileExtension: "txt"
        )
        
        XCTAssertEqual(savedURL.pathExtension, "txt")
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testTimestampFormat() async throws {
        let testData = "Test Content".data(using: .utf8)!
        let baseFilename = "timestamp-test"
        
        let savedURL = try await sut.saveToDownloads(
            data: testData,
            baseFilename: baseFilename
        )
        
        let filename = savedURL.lastPathComponent
        
        // Check timestamp format (should contain date pattern)
        let datePattern = #"\d{4}-\d{2}-\d{2}_\d{6}"#
        let regex = try NSRegularExpression(pattern: datePattern)
        let range = NSRange(location: 0, length: filename.utf16.count)
        let matches = regex.matches(in: filename, range: range)
        
        XCTAssertFalse(matches.isEmpty, "Filename should contain timestamp")
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
}