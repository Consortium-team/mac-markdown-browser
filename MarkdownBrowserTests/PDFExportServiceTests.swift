import XCTest
import WebKit
import PDFKit
@testable import MarkdownBrowser

@MainActor
final class PDFExportServiceTests: XCTestCase {
    var sut: PDFExportService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PDFExportService.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    func testExportMarkdownToPDF() async throws {
        let markdown = """
        # Test Document
        
        This is a test paragraph with **bold** and *italic* text.
        
        ## Code Example
        
        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```
        
        ## List
        
        - Item 1
        - Item 2
        - Item 3
        """
        
        let pdfData = try await sut.exportMarkdownToPDF(content: markdown)
        
        XCTAssertFalse(pdfData.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDF document from data")
            return
        }
        
        XCTAssertGreaterThan(pdfDocument.pageCount, 0)
    }
    
    func testExportHTMLToPDF() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Document</title>
        </head>
        <body>
            <h1>Test HTML Document</h1>
            <p>This is a test paragraph.</p>
            <ul>
                <li>Item 1</li>
                <li>Item 2</li>
            </ul>
        </body>
        </html>
        """
        
        let pdfData = try await sut.exportHTMLToPDF(html: html)
        
        XCTAssertFalse(pdfData.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDF document from data")
            return
        }
        
        XCTAssertGreaterThan(pdfDocument.pageCount, 0)
    }
    
    func testExportWithCustomCSS() async throws {
        let markdown = "# Custom Styled Document"
        let customCSS = """
        body {
            font-family: Georgia, serif;
            color: #0000FF;
        }
        h1 {
            color: #FF0000;
            font-size: 36px;
        }
        """
        
        let pdfData = try await sut.exportMarkdownToPDF(content: markdown, css: customCSS)
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertNotNil(PDFDocument(data: pdfData))
    }
    
    func testExportEmptyContent() async throws {
        let pdfData = try await sut.exportMarkdownToPDF(content: "")
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertNotNil(PDFDocument(data: pdfData))
    }
    
    func testExportComplexMarkdown() async throws {
        let complexMarkdown = """
        # Complex Document
        
        ## Table Example
        
        | Header 1 | Header 2 | Header 3 |
        |----------|----------|----------|
        | Cell 1   | Cell 2   | Cell 3   |
        | Cell 4   | Cell 5   | Cell 6   |
        
        ## Nested Lists
        
        1. First item
           - Nested bullet
           - Another nested bullet
        2. Second item
           1. Nested number
           2. Another nested number
        
        ## Block Quote
        
        > This is a block quote
        > with multiple lines
        
        ## Horizontal Rule
        
        ---
        
        ## Links
        
        [Visit Apple](https://www.apple.com)
        """
        
        let pdfData = try await sut.exportMarkdownToPDF(content: complexMarkdown)
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertNotNil(PDFDocument(data: pdfData))
    }
    
    func testExportFromWebView() async throws {
        let webView = WKWebView()
        let html = "<html><body><h1>Direct WebView Test</h1></body></html>"
        
        webView.loadHTMLString(html, baseURL: nil)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let pdfData = try await sut.exportToPDF(from: webView)
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertNotNil(PDFDocument(data: pdfData))
    }
    
    func testCustomPDFConfiguration() async throws {
        let webView = WKWebView()
        let html = "<html><body><h1>Custom Config Test</h1></body></html>"
        
        webView.loadHTMLString(html, baseURL: nil)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let customConfig = WKPDFConfiguration()
        customConfig.rect = CGRect(x: 0, y: 0, width: 420, height: 595)
        
        let pdfData = try await sut.exportToPDF(from: webView, configuration: customConfig)
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertNotNil(PDFDocument(data: pdfData))
    }
    
    func testPerformance() async throws {
        let markdown = """
        # Performance Test Document
        
        This document is used to test the performance of PDF generation.
        
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        """
        
        let startTime = Date()
        
        _ = try await sut.exportMarkdownToPDF(content: markdown)
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(elapsed, 2.0, "PDF generation should complete within 2 seconds")
    }
}