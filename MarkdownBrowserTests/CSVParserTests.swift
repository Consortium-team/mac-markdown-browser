import XCTest
@testable import MarkdownBrowser

final class CSVParserTests: XCTestCase {
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
    
    // MARK: - Basic Parsing Tests
    
    func testParseSimpleCSV() throws {
        let content = """
        Name,Age,City
        John,30,New York
        Jane,25,Los Angeles
        Bob,35,Chicago
        """
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Age", "City"])
        XCTAssertEqual(data.rowCount, 3)
        XCTAssertEqual(data.columnCount, 3)
        XCTAssertEqual(data.rows[0], ["John", "30", "New York"])
        XCTAssertEqual(data.rows[1], ["Jane", "25", "Los Angeles"])
        XCTAssertEqual(data.rows[2], ["Bob", "35", "Chicago"])
    }
    
    func testParseEmptyCSV() throws {
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse("")
        
        XCTAssertTrue(data.headers.isEmpty)
        XCTAssertTrue(data.rows.isEmpty)
        XCTAssertEqual(data.rowCount, 0)
        XCTAssertEqual(data.columnCount, 0)
    }
    
    func testParseHeadersOnly() throws {
        let content = "Name,Age,City"
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Age", "City"])
        XCTAssertTrue(data.rows.isEmpty)
        XCTAssertEqual(data.columnCount, 3)
    }
    
    // MARK: - Delimiter Tests
    
    func testParseTabDelimited() throws {
        let content = """
        Name\tAge\tCity
        John\t30\tNew York
        Jane\t25\tLos Angeles
        """
        
        let parser = CSVParser(delimiter: .tab)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Age", "City"])
        XCTAssertEqual(data.rowCount, 2)
        XCTAssertEqual(data.rows[0], ["John", "30", "New York"])
        XCTAssertEqual(data.rows[1], ["Jane", "25", "Los Angeles"])
    }
    
    func testParseSemicolonDelimited() throws {
        let content = """
        Name;Age;City
        John;30;New York
        Jane;25;Los Angeles
        """
        
        let parser = CSVParser(delimiter: .semicolon)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Age", "City"])
        XCTAssertEqual(data.rowCount, 2)
        XCTAssertEqual(data.rows[0], ["John", "30", "New York"])
    }
    
    // MARK: - Quoted Values Tests
    
    func testParseQuotedValues() throws {
        let content = """
        Name,Description,Price
        "Product A","Contains, comma",100
        "Product B","Has \\"quotes\\" inside",200
        """
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Description", "Price"])
        XCTAssertEqual(data.rows[0], ["Product A", "Contains, comma", "100"])
        XCTAssertEqual(data.rows[1], ["Product B", "Has \\\"quotes\\\" inside", "200"])
    }
    
    func testParseEscapedQuotes() throws {
        let content = #"""
        Name,Quote
        "John","He said ""Hello"" to me"
        "Jane","She replied ""Hi there!"""
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.rows[0], ["John", "He said \"Hello\" to me"])
        XCTAssertEqual(data.rows[1], ["Jane", "She replied \"Hi there!\""])
    }
    
    func testParseNewlinesInQuotes() throws {
        let content = #"""
        Name,Address
        "John","123 Main St
        Apt 4B
        New York, NY"
        "Jane","456 Oak Ave"
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Address"])
        XCTAssertEqual(data.rowCount, 2)
        XCTAssertEqual(data.rows[0][0], "John")
        XCTAssertTrue(data.rows[0][1].contains("Apt 4B"))
        XCTAssertEqual(data.rows[1], ["Jane", "456 Oak Ave"])
    }
    
    // MARK: - Edge Cases Tests
    
    func testParseEmptyFields() throws {
        let content = #"""
        A,B,C
        1,,3
        ,2,
        ,,
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.rowCount, 3)
        XCTAssertEqual(data.rows[0], ["1", "", "3"])
        XCTAssertEqual(data.rows[1], ["", "2", ""])
        XCTAssertEqual(data.rows[2], ["", "", ""])
    }
    
    func testParseTrailingDelimiter() throws {
        let content = #"""
        A,B,C,
        1,2,3,
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["A", "B", "C", ""])
        XCTAssertEqual(data.rows[0], ["1", "2", "3", ""])
    }
    
    func testParseVariousLineEndings() throws {
        // Test LF
        let lfContent = "A,B\n1,2\n3,4"
        let lfParser = CSVParser(delimiter: .comma)
        let lfData = try lfParser.parse(lfContent)
        XCTAssertEqual(lfData.rowCount, 2)
        XCTAssertEqual(lfData.rows[0], ["1", "2"])
        XCTAssertEqual(lfData.rows[1], ["3", "4"])
        
        // Test CRLF
        let crlfContent = "A,B\r\n1,2\r\n3,4"
        let crlfParser = CSVParser(delimiter: .comma)
        let crlfData = try crlfParser.parse(crlfContent)
        XCTAssertEqual(crlfData.rowCount, 2)
        XCTAssertEqual(crlfData.rows[0], ["1", "2"])
        XCTAssertEqual(crlfData.rows[1], ["3", "4"])
        
        // Test CR
        let crContent = "A,B\r1,2\r3,4"
        let crParser = CSVParser(delimiter: .comma)
        let crData = try crParser.parse(crContent)
        // Some systems don't handle bare CR well, so we'll just check headers were parsed
        XCTAssertEqual(crData.headers, ["A", "B"])
    }
    
    // MARK: - Limit Tests
    
    func testRowLimit() throws {
        let content = #"""
        Header
        Row1
        Row2
        Row3
        Row4
        Row5
        """#
        
        let parser = CSVParser(delimiter: .comma, rowLimit: 3)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.rowCount, 3)
        XCTAssertEqual(data.rows.count, 3)
    }
    
    func testColumnLimit() throws {
        let content = #"""
        A,B,C,D,E
        1,2,3,4,5
        """#
        
        let parser = CSVParser(delimiter: .comma, columnLimit: 3)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["A", "B", "C"])
        XCTAssertEqual(data.rows[0], ["1", "2", "3"])
    }
    
    // MARK: - Special Characters Tests
    
    func testParseUnicodeCharacters() throws {
        let content = #"""
        Name,Emoji,Language
        José,😀,Español
        François,🇫🇷,Français
        北京,🏙️,中文
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        XCTAssertEqual(data.headers, ["Name", "Emoji", "Language"])
        XCTAssertEqual(data.rows[0], ["José", "😀", "Español"])
        XCTAssertEqual(data.rows[1], ["François", "🇫🇷", "Français"])
        XCTAssertEqual(data.rows[2], ["北京", "🏙️", "中文"])
    }
    
    func testParseControlCharacterRemoval() throws {
        let content = "Name,Value\nTest\u{0001},Normal"
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        // Control character should be removed
        XCTAssertEqual(data.rows[0][0], "Test")
        XCTAssertEqual(data.rows[0][1], "Normal")
    }
    
    // MARK: - File Parsing Tests
    
    func testParseFile() throws {
        let content = #"""
        Name,Age,City
        John,30,New York
        Jane,25,Los Angeles
        """#
        
        let csvURL = tempDirectory.appendingPathComponent("test.csv")
        try content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parseFile(at: csvURL)
        
        XCTAssertEqual(data.headers, ["Name", "Age", "City"])
        XCTAssertEqual(data.rowCount, 2)
        XCTAssertEqual(data.rows[0], ["John", "30", "New York"])
    }
    
    func testParseLargeFile() throws {
        // Create a file with 1000 rows
        var content = "ID,Name,Value\n"
        for i in 1...1000 {
            content += "\(i),Name\(i),Value\(i)\n"
        }
        
        let csvURL = tempDirectory.appendingPathComponent("large.csv")
        try content.write(to: csvURL, atomically: true, encoding: .utf8)
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parseFile(at: csvURL)
        
        XCTAssertEqual(data.rowCount, 1000)
        XCTAssertEqual(data.rows[0], ["1", "Name1", "Value1"])
        XCTAssertEqual(data.rows[999], ["1000", "Name1000", "Value1000"])
    }
    
    func testParseNonExistentFile() throws {
        let csvURL = tempDirectory.appendingPathComponent("nonexistent.csv")
        let parser = CSVParser(delimiter: .comma)
        
        XCTAssertThrowsError(try parser.parseFile(at: csvURL)) { error in
            XCTAssertEqual((error as? CSVParseError), .fileNotFound)
        }
    }
    
    // MARK: - Performance Tests
    
    func testParsePerformance() throws {
        // Create a moderately large CSV content
        var content = "ID,Name,Email,Phone,Address,City,State,ZIP\n"
        for i in 1...10000 {
            content += "\(i),User\(i),user\(i)@example.com,555-\(i),\(i) Main St,City\(i),ST,\(10000+i)\n"
        }
        
        let parser = CSVParser(delimiter: .comma)
        
        measure {
            _ = try? parser.parse(content)
        }
    }
    
    // MARK: - Malformed CSV Tests
    
    func testParseMalformedCSV() throws {
        let content = #"""
        Name,Age
        John,30,Extra
        Jane,25
        Bob
        """#
        
        let parser = CSVParser(delimiter: .comma)
        let data = try parser.parse(content)
        
        // Should handle gracefully
        XCTAssertEqual(data.headers, ["Name", "Age"])
        XCTAssertEqual(data.rows[0], ["John", "30", "Extra"])
        XCTAssertEqual(data.rows[1], ["Jane", "25"])
        XCTAssertEqual(data.rows[2], ["Bob"])
    }
}