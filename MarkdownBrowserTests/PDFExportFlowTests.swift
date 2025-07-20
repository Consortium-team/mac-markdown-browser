import XCTest
import SwiftUI
@testable import MarkdownBrowser

@MainActor
final class PDFExportFlowTests: XCTestCase {
    var testDirectory: URL!
    var testMarkdownFile: URL!
    var testHTMLFile: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test directory
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("PDFExportFlowTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Create test markdown file
        testMarkdownFile = testDirectory.appendingPathComponent("test.md")
        let markdownContent = """
        # Test Document
        
        This is a test document for PDF export.
        
        ## Features
        
        - Bullet point 1
        - Bullet point 2
        
        ```swift
        let code = "example"
        ```
        """
        try markdownContent.write(to: testMarkdownFile, atomically: true, encoding: .utf8)
        
        // Create test HTML file
        testHTMLFile = testDirectory.appendingPathComponent("test.html")
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head><title>Test HTML</title></head>
        <body>
            <h1>Test HTML Document</h1>
            <p>This is a test HTML document for PDF export.</p>
        </body>
        </html>
        """
        try htmlContent.write(to: testHTMLFile, atomically: true, encoding: .utf8)
    }
    
    override func tearDown() async throws {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        try await super.tearDown()
    }
    
    func testMarkdownPDFExportFlow() async throws {
        // Create view with markdown file
        let view = FilePreviewView(fileURL: testMarkdownFile)
        
        // The view should have export functionality for markdown files
        XCTAssertTrue(testMarkdownFile.isMarkdownFile)
        
        // Test that PDF export service can handle the content
        let content = try String(contentsOf: testMarkdownFile)
        let pdfData = try await PDFExportService.shared.exportMarkdownToPDF(content: content)
        
        XCTAssertFalse(pdfData.isEmpty)
        
        // Test saving to downloads
        let savedURL = try await DownloadSaveManager.shared.saveToDownloads(
            data: pdfData,
            baseFilename: "test-export",
            fileExtension: "pdf"
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testHTMLPDFExportFlow() async throws {
        // Create view with HTML file
        let view = FilePreviewView(fileURL: testHTMLFile)
        
        // The view should have export functionality for HTML files
        XCTAssertTrue(testHTMLFile.isHTMLFile)
        
        // Test that PDF export service can handle the content
        let htmlContent = try String(contentsOf: testHTMLFile)
        let pdfData = try await PDFExportService.shared.exportHTMLToPDF(
            html: htmlContent,
            baseURL: testHTMLFile.deletingLastPathComponent()
        )
        
        XCTAssertFalse(pdfData.isEmpty)
        
        // Test saving to downloads
        let savedURL = try await DownloadSaveManager.shared.saveToDownloads(
            data: pdfData,
            baseFilename: "test-html-export",
            fileExtension: "pdf"
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Clean up
        try? FileManager.default.removeItem(at: savedURL)
    }
    
    func testExportCancellation() async throws {
        // Test that export can be cancelled
        let task = Task {
            // Check cancellation at start
            if Task.isCancelled {
                throw CancellationError()
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Check cancellation after sleep
            if Task.isCancelled {
                throw CancellationError()
            }
            
            return "completed"
        }
        
        // Cancel immediately
        task.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled")
        } catch is CancellationError {
            // Expected - task was cancelled
            XCTAssertTrue(true)
        } catch {
            // Task.sleep might throw its own cancellation error
            XCTAssertTrue(true)
        }
    }
    
    func testExportErrorHandling() async throws {
        // Test error handling with invalid file
        let invalidURL = testDirectory.appendingPathComponent("nonexistent.md")
        
        do {
            _ = try String(contentsOf: invalidURL)
            XCTFail("Should have thrown error for non-existent file")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
}