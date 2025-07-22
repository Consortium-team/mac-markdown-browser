import XCTest
import Combine
@testable import MarkdownBrowser

@MainActor
class CSVEndToEndTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Creation
    
    func createSimpleCSV() throws -> URL {
        let content = """
        Name,Age,City
        John,25,New York
        Jane,30,San Francisco
        Bob,35,Chicago
        """
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_simple.csv")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    func createTabSeparatedCSV() throws -> URL {
        let content = "Name\tAge\tCity\nJohn\t25\tNew York\nJane\t30\tSan Francisco"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_tabs.tsv")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Basic CSV Tests
    
    func testSimpleCSVLoading() async throws {
        let fileURL = try createSimpleCSV()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        // Wait a bit for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Verify document was loaded
        XCTAssertNotNil(viewModel.currentDocument)
        XCTAssertEqual(viewModel.currentDocument?.csvData.rowCount, 3)
        XCTAssertEqual(viewModel.currentDocument?.csvData.columnCount, 3)
        
        // Verify headers
        let headers = viewModel.currentDocument?.csvData.headers ?? []
        XCTAssertEqual(headers, ["Name", "Age", "City"])
        
        // Verify first row
        let firstRow = viewModel.currentDocument?.csvData.rows.first ?? []
        XCTAssertEqual(firstRow, ["John", "25", "New York"])
    }
    
    func testTabDelimiterDetection() async throws {
        let fileURL = try createTabSeparatedCSV()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Verify tab delimiter was detected
        XCTAssertEqual(viewModel.currentDocument?.csvData.delimiter, .tab)
        XCTAssertEqual(viewModel.selectedDelimiter, .tab)
    }
    
    func testCSVRendering() async throws {
        let fileURL = try createSimpleCSV()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let expectation = XCTestExpectation(description: "HTML rendered")
        
        let viewModel = CSVViewModel()
        
        // Observe HTML changes
        viewModel.$renderedHTML
            .dropFirst() // Skip initial empty value
            .first()
            .sink { html in
                XCTAssertFalse(html.isEmpty)
                XCTAssertTrue(html.contains("<table"))
                XCTAssertTrue(html.contains("Name"))
                XCTAssertTrue(html.contains("John"))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await viewModel.loadDocument(at: fileURL)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDelimiterChange() async throws {
        // Create a semicolon-separated file
        let content = "Name;Age;City\nJohn;25;New York\nJane;30;San Francisco"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_semicolon.csv")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Initially should detect semicolon
        XCTAssertEqual(viewModel.selectedDelimiter, .semicolon)
        
        // Change to comma (this will re-parse incorrectly, but tests the mechanism)
        viewModel.changeDelimiter(.comma)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(viewModel.selectedDelimiter, .comma)
    }
    
    func testCSVWithQuotedValues() async throws {
        let content = """
        Name,Description,Price
        "iPhone 14","A smartphone with ""advanced"" features",999.99
        "Coffee Maker","Makes great coffee, very popular",59.99
        """
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_quoted.csv")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Verify parsing handled quotes correctly
        let firstRow = viewModel.currentDocument?.csvData.rows.first ?? []
        XCTAssertEqual(firstRow[0], "iPhone 14")
        XCTAssertEqual(firstRow[1], "A smartphone with \"advanced\" features")
        XCTAssertEqual(firstRow[2], "999.99")
    }
    
    func testVirtualScrollingForLargeCSV() async throws {
        // Create a CSV with more than 100 rows to trigger virtual scrolling
        var content = "ID,Name,Value\n"
        for i in 1...150 {
            content += "\(i),Item\(i),\(i * 10)\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_large.csv")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let expectation = XCTestExpectation(description: "Large CSV rendered")
        
        let viewModel = CSVViewModel()
        
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { html in
                // Should use virtual scrolling template for > 100 rows
                XCTAssertTrue(html.contains("table-wrapper"))
                XCTAssertTrue(html.contains("header-container"))
                XCTAssertTrue(html.contains("body-container"))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await viewModel.loadDocument(at: fileURL)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testErrorHandling() async throws {
        // Test with empty file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("empty.csv")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Should handle empty file gracefully
        XCTAssertNotNil(viewModel.currentDocument)
        XCTAssertEqual(viewModel.currentDocument?.csvData.rowCount, 0)
    }
    
    func testEditingAndSaving() async throws {
        let fileURL = try createSimpleCSV()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Modify content
        let newContent = "Name,Age,City\nAlice,22,Boston\nCharlie,45,Miami"
        viewModel.updateContent(newContent)
        
        // Save
        await viewModel.saveCurrentDocument()
        
        // Verify file was updated
        let savedContent = try String(contentsOf: fileURL)
        XCTAssertTrue(savedContent.contains("Alice"))
        XCTAssertTrue(savedContent.contains("Boston"))
    }
}