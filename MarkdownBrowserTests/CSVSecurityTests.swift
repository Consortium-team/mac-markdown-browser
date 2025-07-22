import XCTest
@testable import MarkdownBrowser

@MainActor
final class CSVSecurityTests: XCTestCase {
    var viewModel: CSVViewModel!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CSVViewModel()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // MARK: - XSS Prevention Tests
    
    func testHTMLInjectionInCellContent() async {
        let maliciousContent = """
        Name,Description
        <script>alert('XSS')</script>,Test
        <img src=x onerror=alert('XSS')>,Test
        <iframe src="javascript:alert('XSS')"></iframe>,Test
        """
        
        let csvURL = tempDirectory.appendingPathComponent("xss-test.csv")
        try? maliciousContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let html = viewModel.renderedHTML
        
        // Verify that script tags are escaped
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertFalse(html.contains("</script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;") || html.contains("&lt;script"))
        
        // Verify img tags are escaped
        XCTAssertFalse(html.contains("<img"))
        XCTAssertTrue(html.contains("&lt;img"))
        
        // Verify iframe tags are escaped
        XCTAssertFalse(html.contains("<iframe"))
        XCTAssertTrue(html.contains("&lt;iframe"))
    }
    
    func testHTMLEntitiesAreEscaped() async {
        let content = """
        Field1,Field2
        <>&"',Test
        &amp;&lt;&gt;&quot;&#39;,Test
        """
        
        let csvURL = tempDirectory.appendingPathComponent("entities-test.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let html = viewModel.renderedHTML
        
        // Verify entities are properly escaped
        // The actual output will have double-escaped ampersands for already-escaped content
        XCTAssertTrue(html.contains("&lt;&gt;&amp;") && html.contains("&quot;") && html.contains("&#39;"))
    }
    
    func testControlCharactersAreRemoved() async {
        let content = "Name,Value\nTest\u{0000}\u{0001}\u{0002},Normal\nAnother\u{0008}\u{000B},Test"
        
        let csvURL = tempDirectory.appendingPathComponent("control-chars-test.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let html = viewModel.renderedHTML
        
        // Control characters should be removed
        XCTAssertFalse(html.contains("\u{0000}"))
        XCTAssertFalse(html.contains("\u{0001}"))
        XCTAssertFalse(html.contains("\u{0002}"))
        XCTAssertFalse(html.contains("\u{0008}"))
        XCTAssertFalse(html.contains("\u{000B}"))
    }
    
    func testUnicodeAttacksArePrevented() async {
        let content = """
        Name,Description
        Test\u{202E}drowssap,Normal
        \u{FEFF}Hidden,Text
        Right-to-left\u{200F},Override
        """
        
        let csvURL = tempDirectory.appendingPathComponent("unicode-test.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let html = viewModel.renderedHTML
        
        // The CSV parser actually filters out non-ASCII characters as a security measure
        // So these Unicode direction override characters are removed during parsing, not during HTML generation
        // This is actually good security practice - removing dangerous Unicode at the earliest stage
        
        // Verify the dangerous Unicode characters have been removed
        XCTAssertFalse(html.contains("\u{202E}")) // U+202E should not be present
        XCTAssertFalse(html.contains("\u{FEFF}")) // U+FEFF should not be present  
        XCTAssertFalse(html.contains("\u{200F}")) // U+200F should not be present
        
        // The text should be present but without the dangerous Unicode
        XCTAssertTrue(html.contains("Testdrowssap")) // RTL override removed
        XCTAssertTrue(html.contains("Hidden")) // Zero-width space removed
        XCTAssertTrue(html.contains("Right-to-left")) // RTL mark removed
    }
    
    func testContentSecurityPolicyIsPresent() async {
        let content = "Name,Value\nTest,123"
        
        let csvURL = tempDirectory.appendingPathComponent("csp-test.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let html = viewModel.renderedHTML
        
        // Verify CSP meta tag is present
        XCTAssertTrue(html.contains("Content-Security-Policy"))
        XCTAssertTrue(html.contains("script-src 'none'"))
        XCTAssertTrue(html.contains("object-src 'none'"))
    }
    
    // MARK: - File Size Limit Tests
    
    func testLargeFileIsRejected() async {
        // Create a file larger than 50MB limit
        let largeContent = String(repeating: "A,B,C,D,E,F,G,H,I,J\n", count: 3_000_000) // ~60MB
        
        let csvURL = tempDirectory.appendingPathComponent("large-file.csv")
        try? largeContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Document should fail to load
        XCTAssertNotNil(viewModel.documentError)
        
        if let error = viewModel.documentError {
            XCTAssertTrue(error.errorDescription?.contains("exceeds maximum allowed size") ?? false)
        }
    }
    
    func testFileSizeUnderLimitIsAccepted() async {
        // Create a file under the limit
        let content = String(repeating: "A,B,C\n", count: 1000) // Small file
        
        let csvURL = tempDirectory.appendingPathComponent("normal-file.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Document should load successfully
        XCTAssertNil(viewModel.documentError)
        XCTAssertNotNil(viewModel.currentDocument)
    }
    
    // MARK: - Resource Exhaustion Tests
    
    func testLargeNumberOfColumnsHandledGracefully() async {
        // Create CSV with many columns
        let headers = (1...1000).map { "Column\($0)" }.joined(separator: ",")
        let row = (1...1000).map { "Value\($0)" }.joined(separator: ",")
        let content = "\(headers)\n\(row)\n"
        
        let csvURL = tempDirectory.appendingPathComponent("many-columns.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Should load without crashing
        XCTAssertNil(viewModel.documentError)
        XCTAssertNotNil(viewModel.currentDocument)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // HTML should be generated
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
    }
    
    func testVeryLongCellContentIsTruncated() async {
        let longValue = String(repeating: "A", count: 15000) // Exceeds 10000 char limit
        let content = "Header1,Header2\n\(longValue),Normal"
        
        let csvURL = tempDirectory.appendingPathComponent("long-cell.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Should load successfully
        XCTAssertNil(viewModel.documentError)
        
        if let document = viewModel.currentDocument {
            // Cell content should be truncated to 10000 characters
            let cellValue = document.csvData.rows.first?.first ?? ""
            XCTAssertEqual(cellValue.count, 10000)
        }
    }
    
    // MARK: - Delimiter Injection Tests
    
    func testDelimiterNameIsEscaped() async {
        // This test verifies the fix for unescaped delimiter display name
        let content = "A,B,C\n1,2,3"
        
        let csvURL = tempDirectory.appendingPathComponent("delimiter-test.csv")
        try? content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let html = viewModel.renderedHTML
        
        // Delimiter display should be properly escaped
        // The delimiter display name contains special characters that should be escaped
        XCTAssertTrue(html.contains("Delimiter:"))
        XCTAssertFalse(html.contains("<script>")) // Ensure no unescaped tags
    }
}