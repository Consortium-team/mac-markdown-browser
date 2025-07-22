import XCTest
@testable import MarkdownBrowser

final class CSVDocumentTests: XCTestCase {
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testCSVDocumentInitialization() {
        let csvURL = tempDirectory.appendingPathComponent("test.csv")
        let document = CSVDocument(url: csvURL)
        
        XCTAssertEqual(document.url, csvURL)
        XCTAssertEqual(document.name, "test.csv")
        XCTAssertFalse(document.isLoading)
        XCTAssertFalse(document.hasUnsavedChanges)
        XCTAssertTrue(document.content.isEmpty)
        XCTAssertTrue(document.csvData.headers.isEmpty)
        XCTAssertTrue(document.csvData.rows.isEmpty)
    }
    
    func testLoadSimpleCSV() async {
        let csvContent = """
        Name,Age,City
        John,30,New York
        Jane,25,Los Angeles
        Bob,35,Chicago
        """
        
        let csvURL = tempDirectory.appendingPathComponent("simple.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        let document = CSVDocument(url: csvURL)
        await document.loadContent()
        
        XCTAssertEqual(document.content, csvContent)
        XCTAssertEqual(document.csvData.delimiter, .comma)
        XCTAssertEqual(document.csvData.headers, ["Name", "Age", "City"])
        XCTAssertEqual(document.csvData.rowCount, 3)
        XCTAssertEqual(document.csvData.columnCount, 3)
        XCTAssertEqual(document.csvData.rows[0], ["John", "30", "New York"])
        XCTAssertFalse(document.hasUnsavedChanges)
        XCTAssertNil(document.error)
    }
    
    func testDelimiterDetection() async {
        // Test tab-delimited
        let tsvContent = """
        Name\tAge\tCity
        John\t30\tNew York
        Jane\t25\tLos Angeles
        """
        
        let tsvURL = tempDirectory.appendingPathComponent("data.tsv")
        try? tsvContent.write(to: tsvURL, atomically: true, encoding: .utf8)
        
        let tsvDocument = CSVDocument(url: tsvURL)
        await tsvDocument.loadContent()
        
        XCTAssertEqual(tsvDocument.csvData.delimiter, .tab)
        XCTAssertEqual(tsvDocument.csvData.headers, ["Name", "Age", "City"])
        
        // Test semicolon-delimited
        let semicolonContent = """
        Name;Age;City
        John;30;New York
        Jane;25;Los Angeles
        """
        
        let semicolonURL = tempDirectory.appendingPathComponent("data-semicolon.csv")
        try? semicolonContent.write(to: semicolonURL, atomically: true, encoding: .utf8)
        
        let semicolonDocument = CSVDocument(url: semicolonURL)
        await semicolonDocument.loadContent()
        
        XCTAssertEqual(semicolonDocument.csvData.delimiter, .semicolon)
        XCTAssertEqual(semicolonDocument.csvData.headers, ["Name", "Age", "City"])
    }
    
    func testUpdateContent() {
        let csvURL = tempDirectory.appendingPathComponent("update.csv")
        let document = CSVDocument(url: csvURL)
        
        let originalContent = "Name,Age\nJohn,30"
        document.updateContent(originalContent)
        
        XCTAssertEqual(document.content, originalContent)
        XCTAssertTrue(document.hasUnsavedChanges)
        XCTAssertEqual(document.csvData.headers, ["Name", "Age"])
        XCTAssertEqual(document.csvData.rows.count, 1)
        
        let newContent = "Name,Age\nJohn,30\nJane,25"
        document.updateContent(newContent)
        
        XCTAssertEqual(document.content, newContent)
        XCTAssertTrue(document.hasUnsavedChanges)
        XCTAssertEqual(document.csvData.rows.count, 2)
    }
    
    func testChangeDelimiter() {
        let csvURL = tempDirectory.appendingPathComponent("delimiter.csv")
        let document = CSVDocument(url: csvURL)
        
        let content = "Name,Age,City"
        document.updateContent(content)
        
        XCTAssertEqual(document.csvData.delimiter, .comma)
        XCTAssertEqual(document.csvData.headers, ["Name", "Age", "City"])
        
        // Change delimiter interpretation
        document.changeDelimiter(.semicolon)
        XCTAssertEqual(document.csvData.delimiter, .semicolon)
        XCTAssertEqual(document.csvData.headers, ["Name,Age,City"]) // Now it's one column
    }
    
    func testSaveContent() async {
        let csvContent = "Name,Age\nJohn,30"
        let csvURL = tempDirectory.appendingPathComponent("save.csv")
        try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        let document = CSVDocument(url: csvURL)
        await document.loadContent()
        
        document.updateContent("Name,Age\nJohn,30\nJane,25")
        XCTAssertTrue(document.hasUnsavedChanges)
        
        await document.saveContent()
        
        XCTAssertFalse(document.hasUnsavedChanges)
        
        // Verify file was written
        let savedContent = try? String(contentsOf: csvURL)
        XCTAssertEqual(savedContent, "Name,Age\nJohn,30\nJane,25")
    }
    
    func testLoadNonExistentFile() async {
        let csvURL = tempDirectory.appendingPathComponent("nonexistent.csv")
        let document = CSVDocument(url: csvURL)
        
        await document.loadContent()
        
        XCTAssertNotNil(document.error)
        if case .loadFailed = document.error {
            // Expected error
        } else {
            XCTFail("Expected loadFailed error")
        }
    }
    
    func testEmptyCSV() {
        let csvURL = tempDirectory.appendingPathComponent("empty.csv")
        let document = CSVDocument(url: csvURL)
        
        document.updateContent("")
        
        XCTAssertTrue(document.csvData.headers.isEmpty)
        XCTAssertTrue(document.csvData.rows.isEmpty)
        XCTAssertEqual(document.csvData.rowCount, 0)
        XCTAssertEqual(document.csvData.columnCount, 0)
    }
    
    func testCSVWithEmptyLines() {
        let csvURL = tempDirectory.appendingPathComponent("empty-lines.csv")
        let document = CSVDocument(url: csvURL)
        
        let content = """
        Name,Age
        
        John,30
        
        Jane,25
        
        """
        
        document.updateContent(content)
        
        XCTAssertEqual(document.csvData.headers, ["Name", "Age"])
        XCTAssertEqual(document.csvData.rowCount, 2)
        XCTAssertEqual(document.csvData.rows[0], ["John", "30"])
        XCTAssertEqual(document.csvData.rows[1], ["Jane", "25"])
    }
    
    func testMetadata() {
        let csvURL = tempDirectory.appendingPathComponent("metadata.csv")
        let document = CSVDocument(url: csvURL)
        
        document.updateContent("A,B,C,D,E\n1,2,3,4,5\n6,7,8,9,10")
        
        XCTAssertEqual(document.metadata, "2 rows × 5 columns")
    }
    
    func testEquatable() {
        let url1 = tempDirectory.appendingPathComponent("doc1.csv")
        let url2 = tempDirectory.appendingPathComponent("doc2.csv")
        
        let doc1a = CSVDocument(url: url1)
        let doc1b = CSVDocument(url: url1)
        let doc2 = CSVDocument(url: url2)
        
        XCTAssertEqual(doc1a, doc1b)
        XCTAssertNotEqual(doc1a, doc2)
    }
    
    func testHashable() {
        let url = tempDirectory.appendingPathComponent("doc.csv")
        let doc1 = CSVDocument(url: url)
        let doc2 = CSVDocument(url: url)
        
        var set = Set<CSVDocument>()
        set.insert(doc1)
        set.insert(doc2)
        
        XCTAssertEqual(set.count, 1) // Should be the same document
    }
}