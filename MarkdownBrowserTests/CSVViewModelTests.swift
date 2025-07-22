import XCTest
@testable import MarkdownBrowser

@MainActor
final class CSVViewModelTests: XCTestCase {
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
    
    // MARK: - Document Loading Tests
    
    func testLoadCSVDocument() async {
        let csvContent = """
        Name,Age,City
        John,30,New York
        Jane,25,Los Angeles
        """
        
        let csvURL = tempDirectory.appendingPathComponent("test.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        XCTAssertNotNil(viewModel.currentDocument)
        XCTAssertEqual(viewModel.documentName, "test.csv")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertNil(viewModel.documentError)
    }
    
    func testRenderCSVContent() async {
        let csvContent = """
        Product,Price,Stock
        Apple,1.99,100
        Banana,0.99,150
        """
        
        let csvURL = tempDirectory.appendingPathComponent("products.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
        XCTAssertTrue(viewModel.renderedHTML.contains("Product"))
        XCTAssertTrue(viewModel.renderedHTML.contains("Apple"))
        XCTAssertTrue(viewModel.renderedHTML.contains("1.99"))
        XCTAssertNil(viewModel.renderError)
    }
    
    // MARK: - Content Update Tests
    
    func testUpdateContent() async {
        let initialContent = "A,B\n1,2"
        let csvURL = tempDirectory.appendingPathComponent("update.csv")
        try? initialContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        let newContent = "A,B\n1,2\n3,4"
        viewModel.updateContent(newContent)
        
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.currentDocument?.content, newContent)
        
        // Wait for debounced render
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        XCTAssertTrue(viewModel.renderedHTML.contains("3"))
        XCTAssertTrue(viewModel.renderedHTML.contains("4"))
    }
    
    // MARK: - Delimiter Tests
    
    func testChangeDelimiter() async {
        let csvContent = "Name;Age;City"
        let csvURL = tempDirectory.appendingPathComponent("semicolon.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Should auto-detect semicolon
        XCTAssertEqual(viewModel.selectedDelimiter, .semicolon)
        
        // Change to comma
        viewModel.changeDelimiter(.comma)
        
        // Wait for re-render
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(viewModel.selectedDelimiter, .comma)
        // With comma delimiter, the whole line becomes one column
        XCTAssertTrue(viewModel.renderedHTML.contains("Name;Age;City"))
    }
    
    func testDelimiterAutoDetection() async {
        // Test tab-delimited
        let tsvContent = "Name\tAge\tCity\nJohn\t30\tNY"
        let tsvURL = tempDirectory.appendingPathComponent("data.tsv")
        try? tsvContent.write(to: tsvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: tsvURL)
        XCTAssertEqual(viewModel.selectedDelimiter, .tab)
        
        // Test comma-delimited
        let csvContent = "Name,Age,City\nJohn,30,NY"
        let csvURL = tempDirectory.appendingPathComponent("data.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        XCTAssertEqual(viewModel.selectedDelimiter, .comma)
    }
    
    // MARK: - Save and Reload Tests
    
    func testSaveDocument() async {
        let csvContent = "A,B\n1,2"
        let csvURL = tempDirectory.appendingPathComponent("save.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        viewModel.updateContent("A,B\n1,2\n3,4")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        
        await viewModel.saveCurrentDocument()
        
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        
        // Verify file was saved
        let savedContent = try? String(contentsOf: csvURL)
        XCTAssertEqual(savedContent, "A,B\n1,2\n3,4")
    }
    
    func testReloadDocument() async {
        let initialContent = "A,B\n1,2"
        let csvURL = tempDirectory.appendingPathComponent("reload.csv")
        try? initialContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Modify content
        viewModel.updateContent("A,B\n1,2\nModified")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        
        // Reload from disk
        await viewModel.reloadCurrentDocument()
        
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.currentDocument?.content, initialContent)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadNonExistentFile() async {
        let csvURL = tempDirectory.appendingPathComponent("nonexistent.csv")
        
        await viewModel.loadDocument(at: csvURL)
        
        XCTAssertNotNil(viewModel.documentError)
        XCTAssertTrue(viewModel.renderedHTML.contains("Error") || viewModel.renderedHTML.isEmpty)
    }
    
    func testRenderEmptyCSV() async {
        let csvURL = tempDirectory.appendingPathComponent("empty.csv")
        try? "".write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertTrue(viewModel.renderedHTML.isEmpty || viewModel.renderedHTML.contains("No CSV data"))
        XCTAssertNil(viewModel.renderError)
    }
    
    // MARK: - Performance Tests
    
    func testRenderPerformance() async {
        // Create a moderately large CSV
        var csvContent = "ID,Name,Email,Phone,Address\n"
        for i in 1...1000 {
            csvContent += "\(i),User\(i),user\(i)@example.com,555-\(i),\(i) Main St\n"
        }
        
        let csvURL = tempDirectory.appendingPathComponent("large.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Check that it rendered
        XCTAssertFalse(viewModel.renderedHTML.isEmpty)
        XCTAssertTrue(viewModel.renderedHTML.contains("1000 rows"))
        
        // Check render time
        if let renderTime = viewModel.lastRenderTime {
            // Should render in under 500ms
            XCTAssertLessThan(renderTime, 0.5)
        }
    }
    
    // MARK: - HTML Security Tests
    
    func testHTMLEscaping() async {
        let csvContent = """
        Name,Description
        <script>alert('XSS')</script>,<img src=x onerror="alert('XSS')">
        """
        
        let csvURL = tempDirectory.appendingPathComponent("xss.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        // Wait for rendering
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Check that HTML is escaped
        XCTAssertTrue(viewModel.renderedHTML.contains("&lt;script&gt;"))
        XCTAssertTrue(viewModel.renderedHTML.contains("&lt;img"))
        XCTAssertFalse(viewModel.renderedHTML.contains("<script>"))
        XCTAssertFalse(viewModel.renderedHTML.contains("<img src"))
    }
    
    // MARK: - Metadata Tests
    
    func testDocumentMetadata() async {
        let csvContent = """
        A,B,C,D,E
        1,2,3,4,5
        6,7,8,9,10
        11,12,13,14,15
        """
        
        let csvURL = tempDirectory.appendingPathComponent("metadata.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        await viewModel.loadDocument(at: csvURL)
        
        XCTAssertEqual(viewModel.documentMetadata, "3 rows × 5 columns")
        XCTAssertTrue(viewModel.renderedHTML.contains("3 rows × 5 columns"))
    }
}