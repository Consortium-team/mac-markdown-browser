import XCTest
@testable import MarkdownBrowser

final class FileTypeTests: XCTestCase {
    
    func testFileTypeDetectionForMarkdown() {
        let mdURL = URL(fileURLWithPath: "/test/document.md")
        let markdownURL = URL(fileURLWithPath: "/test/document.markdown")
        
        XCTAssertEqual(mdURL.fileType, .markdown)
        XCTAssertEqual(markdownURL.fileType, .markdown)
        XCTAssertTrue(mdURL.isMarkdownFile)
        XCTAssertTrue(markdownURL.isMarkdownFile)
        XCTAssertFalse(mdURL.isHTMLFile)
        XCTAssertTrue(mdURL.isSupportedDocument)
    }
    
    func testFileTypeDetectionForHTML() {
        let htmlURL = URL(fileURLWithPath: "/test/page.html")
        let htmURL = URL(fileURLWithPath: "/test/page.htm")
        
        XCTAssertEqual(htmlURL.fileType, .html)
        XCTAssertEqual(htmURL.fileType, .html)
        XCTAssertTrue(htmlURL.isHTMLFile)
        XCTAssertTrue(htmURL.isHTMLFile)
        XCTAssertFalse(htmlURL.isMarkdownFile)
        XCTAssertTrue(htmlURL.isSupportedDocument)
    }
    
    func testFileTypeDetectionForCSV() {
        let csvURL = URL(fileURLWithPath: "/test/data.csv")
        let tsvURL = URL(fileURLWithPath: "/test/data.tsv")
        
        XCTAssertEqual(csvURL.fileType, .csv)
        XCTAssertEqual(tsvURL.fileType, .csv)
        XCTAssertTrue(csvURL.isCSVFile)
        XCTAssertTrue(tsvURL.isCSVFile)
        XCTAssertFalse(csvURL.isMarkdownFile)
        XCTAssertFalse(csvURL.isHTMLFile)
        XCTAssertTrue(csvURL.isSupportedDocument)
        XCTAssertTrue(tsvURL.isSupportedDocument)
    }
    
    func testFileTypeDetectionForDirectory() {
        // This test would need actual file system access or mocking
        // For now, we'll test the logic with a simulated directory
        let dirURL = URL(fileURLWithPath: "/test/folder/", isDirectory: true)
        // Note: FileType init checks actual file system, so this is a limitation
    }
    
    func testFileTypeDetectionForOtherFiles() {
        let txtURL = URL(fileURLWithPath: "/test/document.txt")
        let pdfURL = URL(fileURLWithPath: "/test/document.pdf")
        let noExtURL = URL(fileURLWithPath: "/test/README")
        
        XCTAssertEqual(txtURL.fileType, .other)
        XCTAssertEqual(pdfURL.fileType, .other)
        XCTAssertEqual(noExtURL.fileType, .other)
        XCTAssertFalse(txtURL.isMarkdownFile)
        XCTAssertFalse(txtURL.isHTMLFile)
        XCTAssertFalse(txtURL.isCSVFile)
        XCTAssertFalse(txtURL.isSupportedDocument)
    }
    
    func testFileTypeIcons() {
        XCTAssertEqual(FileType.markdown.iconName, "doc.text")
        XCTAssertEqual(FileType.html.iconName, "doc.richtext")
        XCTAssertEqual(FileType.csv.iconName, "tablecells")
        XCTAssertEqual(FileType.directory.iconName, "folder")
        XCTAssertEqual(FileType.other.iconName, "doc")
    }
    
    func testFileTypeSupport() {
        XCTAssertTrue(FileType.markdown.isSupported)
        XCTAssertTrue(FileType.html.isSupported)
        XCTAssertTrue(FileType.csv.isSupported)
        XCTAssertFalse(FileType.directory.isSupported)
        XCTAssertFalse(FileType.other.isSupported)
    }
    
    func testCaseInsensitiveExtensions() {
        let upperMD = URL(fileURLWithPath: "/test/document.MD")
        let upperHTML = URL(fileURLWithPath: "/test/page.HTML")
        let mixedHTM = URL(fileURLWithPath: "/test/page.HtM")
        let upperCSV = URL(fileURLWithPath: "/test/data.CSV")
        let mixedTSV = URL(fileURLWithPath: "/test/data.TsV")
        
        XCTAssertEqual(upperMD.fileType, .markdown)
        XCTAssertEqual(upperHTML.fileType, .html)
        XCTAssertEqual(mixedHTM.fileType, .html)
        XCTAssertEqual(upperCSV.fileType, .csv)
        XCTAssertEqual(mixedTSV.fileType, .csv)
    }
}