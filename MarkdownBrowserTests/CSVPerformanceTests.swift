import XCTest
import Combine
@testable import MarkdownBrowser

@MainActor
class CSVPerformanceTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        PerformanceMonitor.shared.clearMetrics()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - CSV Generation Helpers
    
    func generateCSVContent(rows: Int, columns: Int) -> String {
        var csv = ""
        
        // Generate headers
        let headers = (1...columns).map { "Column_\($0)" }
        csv += headers.joined(separator: ",") + "\n"
        
        // Generate rows
        for row in 1...rows {
            let rowData = (1...columns).map { "R\(row)C\($0)" }
            csv += rowData.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    func createTemporaryCSVFile(rows: Int, columns: Int) throws -> URL {
        let content = generateCSVContent(rows: rows, columns: columns)
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_\(rows)x\(columns).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Performance Tests
    
    func testSmallCSVPerformance() async throws {
        // Test with 100 rows x 10 columns
        let fileURL = try createTemporaryCSVFile(rows: 100, columns: 10)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        measure {
            let expectation = XCTestExpectation(description: "Load and render small CSV")
            
            Task {
                let viewModel = CSVViewModel()
                await viewModel.loadDocument(at: fileURL)
                
                // Wait for rendering to complete
                viewModel.$renderedHTML
                    .dropFirst()
                    .first()
                    .sink { _ in
                        expectation.fulfill()
                    }
                    .store(in: &cancellables)
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
        
        // Verify performance metrics were recorded
        if let loadStats = PerformanceMonitor.shared.getStatistics(for: "CSV_FileLoad") {
            XCTAssertLessThan(loadStats.average, 0.05) // 50ms
        }
        
        if let parseStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Parse") {
            XCTAssertLessThan(parseStats.average, 0.02) // 20ms
        }
        
        if let renderStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Render") {
            XCTAssertLessThan(renderStats.average, 0.05) // 50ms
        }
    }
    
    func testMediumCSVPerformance() async throws {
        // Test with 1,000 rows x 20 columns
        let fileURL = try createTemporaryCSVFile(rows: 1000, columns: 20)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        measure {
            let expectation = XCTestExpectation(description: "Load and render medium CSV")
            
            Task {
                let viewModel = CSVViewModel()
                await viewModel.loadDocument(at: fileURL)
                
                // Wait for rendering to complete
                viewModel.$renderedHTML
                    .dropFirst()
                    .first()
                    .sink { _ in
                        expectation.fulfill()
                    }
                    .store(in: &cancellables)
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
        
        // Verify performance metrics
        if let parseStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Parse") {
            XCTAssertLessThan(parseStats.average, 0.2) // 200ms
        }
        
        if let renderStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Render") {
            XCTAssertLessThan(renderStats.average, 0.3) // 300ms
        }
    }
    
    func testLargeCSVPerformance() async throws {
        // Test with 10,000 rows x 30 columns
        let fileURL = try createTemporaryCSVFile(rows: 10000, columns: 30)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let expectation = XCTestExpectation(description: "Load and render large CSV")
        
        let startTime = Date()
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        // Wait for rendering to complete
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Verify total time is under 5 seconds
        XCTAssertLessThan(totalTime, 5.0, "Large CSV should load and render in under 5 seconds")
        
        // Verify performance metrics
        if let parseStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Parse") {
            XCTAssertLessThan(parseStats.max, 0.5) // 500ms max
            print("Parse performance: \(parseStats.summary)")
        }
        
        if let renderStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Render") {
            XCTAssertLessThan(renderStats.max, 1.0) // 1000ms max
            print("Render performance: \(renderStats.summary)")
        }
        
        // Log final performance summary
        PerformanceMonitor.shared.logCSVPerformanceSummary()
    }
    
    func testWideCSVPerformance() async throws {
        // Test with 500 rows x 100 columns
        let fileURL = try createTemporaryCSVFile(rows: 500, columns: 100)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let expectation = XCTestExpectation(description: "Load and render wide CSV")
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        // Wait for rendering to complete
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 20.0)
        
        // Verify the HTML was generated with virtual scrolling for large datasets
        XCTAssertTrue(viewModel.renderedHTML.contains("table-wrapper"))
        XCTAssertTrue(viewModel.renderedHTML.contains("contain: layout"))
    }
    
    func testMemoryUsageWithLargeCSV() async throws {
        // Test memory usage with 5,000 rows x 50 columns
        let fileURL = try createTemporaryCSVFile(rows: 5000, columns: 50)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // Log initial memory
        PerformanceMonitor.shared.logMemoryUsage(context: "Before_CSV_Load")
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        // Log memory after load
        PerformanceMonitor.shared.logMemoryUsage(context: "After_CSV_Load")
        
        let expectation = XCTestExpectation(description: "Render CSV")
        
        // Wait for rendering to complete
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 20.0)
        
        // Log memory after render
        PerformanceMonitor.shared.logMemoryUsage(context: "After_CSV_Render")
        
        // The memory usage logs will be visible in test output
    }
    
    func testCSVScrollingPerformance() async throws {
        // Test that large CSV uses optimized rendering
        let fileURL = try createTemporaryCSVFile(rows: 2500, columns: 25)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        let expectation = XCTestExpectation(description: "Render CSV")
        
        // Wait for rendering to complete
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { html in
                // Verify that virtual scrolling is being used
                XCTAssertTrue(html.contains("Showing first 2000"))
                XCTAssertTrue(html.contains("table-wrapper"))
                XCTAssertTrue(html.contains("header-container"))
                XCTAssertTrue(html.contains("body-container"))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testCSVParsingPerformanceWithComplexData() async throws {
        // Generate CSV with quoted values, newlines, and special characters
        var csv = "Name,Description,Value,Notes\n"
        for i in 1...1000 {
            csv += "\"Item \(i)\",\"Description with, comma and \"\"quotes\"\"\",\(i * 100),\"Multi\nline\nnotes\"\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("complex_test.csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let expectation = XCTestExpectation(description: "Parse complex CSV")
        
        let viewModel = CSVViewModel()
        await viewModel.loadDocument(at: fileURL)
        
        // Wait for rendering to complete
        viewModel.$renderedHTML
            .dropFirst()
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify performance even with complex data
        if let parseStats = PerformanceMonitor.shared.getStatistics(for: "CSV_Parse") {
            XCTAssertLessThan(parseStats.average, 0.3) // 300ms for complex parsing
        }
    }
}