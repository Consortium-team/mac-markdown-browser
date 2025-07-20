import XCTest
import PDFKit
@testable import MarkdownBrowser

@MainActor
final class PDFPaginationTests: XCTestCase {
    var sut: PDFExportService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PDFExportService.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    func testPDFPagination() async throws {
        // Create a long markdown document that should span multiple pages
        var longMarkdown = "# Long Document Test\n\n"
        
        // Add enough content to ensure multiple pages
        for i in 1...50 {
            longMarkdown += "## Section \(i)\n\n"
            longMarkdown += "This is paragraph \(i) with some content to fill the page. "
            longMarkdown += "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
            longMarkdown += "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n\n"
            
            if i % 5 == 0 {
                // Add a code block every 5 sections
                longMarkdown += """
                ```swift
                func example\(i)() {
                    print("This is example code block \(i)")
                    let result = performCalculation()
                    return result
                }
                ```
                
                """
            }
            
            if i % 10 == 0 {
                // Add a table every 10 sections
                longMarkdown += """
                | Column 1 | Column 2 | Column 3 |
                |----------|----------|----------|
                | Data 1   | Data 2   | Data 3   |
                | Data 4   | Data 5   | Data 6   |
                
                """
            }
        }
        
        let pdfData = try await sut.exportMarkdownToPDF(content: longMarkdown)
        
        // Verify PDF was created
        XCTAssertFalse(pdfData.isEmpty)
        
        // Create PDFDocument to check pagination
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDF document")
            return
        }
        
        // Note: WKWebView on macOS creates single-page PDFs by default
        // This is a known limitation we're documenting in tests
        let pageCount = pdfDocument.pageCount
        
        // For now, we expect a single page (this is the current behavior)
        // TODO: Implement proper pagination in a future update
        XCTAssertEqual(pageCount, 1, "Current implementation creates single-page PDFs")
        
        // Check that the page has reasonable width (A4-ish)
        if let firstPage = pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            
            // A4 width is approximately 595 points
            XCTAssertGreaterThan(bounds.width, 500)
            XCTAssertLessThan(bounds.width, 700)
            
            // Height will be tall for long content
            XCTAssertGreaterThan(bounds.height, 1000, "Long documents create tall single pages")
        }
    }
    
    func testPDFPageBreaks() async throws {
        // Test that page breaks are respected
        let markdownWithPageBreaks = """
        # Document with Page Breaks
        
        This is the first page content.
        
        ## Section 1
        
        Some content for section 1.
        
        <div style="page-break-before: always;"></div>
        
        # Second Page
        
        This should appear on a new page.
        
        ## Section 2
        
        More content here.
        """
        
        let pdfData = try await sut.exportMarkdownToPDF(content: markdownWithPageBreaks)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDF document")
            return
        }
        
        // Note: Page breaks in HTML/CSS are not respected by WKWebView's createPDF
        // This is a known limitation on macOS
        XCTAssertEqual(pdfDocument.pageCount, 1, "WKWebView ignores page breaks on macOS")
    }
    
    func testShortDocumentSinglePage() async throws {
        // Test that short documents stay on one page
        let shortMarkdown = """
        # Short Document
        
        This is a very short document that should fit on a single page.
        
        ## Conclusion
        
        The end.
        """
        
        let pdfData = try await sut.exportMarkdownToPDF(content: shortMarkdown)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDF document")
            return
        }
        
        // Should have exactly 1 page
        XCTAssertEqual(pdfDocument.pageCount, 1)
    }
}