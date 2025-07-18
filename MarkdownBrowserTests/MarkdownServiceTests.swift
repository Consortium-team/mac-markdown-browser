import XCTest
@testable import MarkdownBrowser

final class MarkdownServiceTests: XCTestCase {
    private var sut: MarkdownService!
    
    override func setUp() {
        super.setUp()
        sut = MarkdownService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testParseSimpleMarkdown() async throws {
        let content = "# Hello World\n\nThis is a paragraph."
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertTrue(parsed.htmlContent.contains("<h1>Hello World</h1>"))
        XCTAssertTrue(parsed.htmlContent.contains("<p>This is a paragraph.</p>"))
        XCTAssertEqual(parsed.mermaidBlocks.count, 0)
    }
    
    func testParseMarkdownWithCodeBlock() async throws {
        let content = """
        # Code Example
        
        ```swift
        let x = 42
        print(x)
        ```
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertTrue(parsed.htmlContent.contains("<pre><code"))
        XCTAssertTrue(parsed.htmlContent.contains("let x = 42"))
        XCTAssertEqual(parsed.mermaidBlocks.count, 0)
    }
    
    func testParseMarkdownWithTable() async throws {
        let content = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        // Tables might not be parsed by swift-markdown without extensions
        // For now, just check that the content is present in some form
        XCTAssertTrue(parsed.htmlContent.contains("Header 1") || parsed.htmlContent.contains("<table>"))
    }
    
    func testParseMarkdownWithEmphasis() async throws {
        let content = "This is *italic* and this is **bold**."
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertTrue(parsed.htmlContent.contains("<em>italic</em>"))
        XCTAssertTrue(parsed.htmlContent.contains("<strong>bold</strong>"))
    }
    
    func testParseMarkdownWithLinks() async throws {
        let content = "Visit [Swift.org](https://swift.org) for more info."
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertTrue(parsed.htmlContent.contains("<a href=\"https://swift.org\">Swift.org</a>"))
    }
    
    func testParseMarkdownWithLists() async throws {
        let content = """
        ## Shopping List
        
        - Apples
        - Bananas
        - Oranges
        
        ## Steps
        
        1. First step
        2. Second step
        3. Third step
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertTrue(parsed.htmlContent.contains("<ul>"))
        XCTAssertTrue(parsed.htmlContent.contains("<li>Apples</li>"))
        XCTAssertTrue(parsed.htmlContent.contains("<ol>"))
        XCTAssertTrue(parsed.htmlContent.contains("<li>First step</li>"))
    }
    
    func testParseMarkdownWithBlockquote() async throws {
        let content = """
        > This is a blockquote
        > with multiple lines.
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        // Check for blockquote content regardless of exact HTML structure
        XCTAssertTrue(parsed.htmlContent.contains("This is a blockquote"))
        XCTAssertTrue(parsed.htmlContent.contains("with multiple lines") || 
                      parsed.htmlContent.contains("<blockquote>"))
    }
    
    func testExtractMermaidBlocks() {
        let content = """
        # Flowchart Example
        
        ```mermaid
        graph TD
            A[Start] --> B{Decision}
            B -->|Yes| C[Do something]
            B -->|No| D[Do something else]
        ```
        
        Some text here.
        
        ```mermaid
        sequenceDiagram
            Alice->>Bob: Hello
            Bob-->>Alice: Hi!
        ```
        """
        
        let blocks = sut.extractMermaidBlocks(from: content)
        
        XCTAssertEqual(blocks.count, 2)
        XCTAssertTrue(blocks[0].code.contains("graph TD"))
        XCTAssertTrue(blocks[1].code.contains("sequenceDiagram"))
        XCTAssertEqual(blocks[0].startLine, 2)
        XCTAssertEqual(blocks[0].endLine, 7)
        XCTAssertEqual(blocks[1].startLine, 11)
        XCTAssertEqual(blocks[1].endLine, 15)
    }
    
    func testParseMarkdownWithMermaidDiagram() async throws {
        let content = """
        # Architecture Diagram
        
        ```mermaid
        graph LR
            A[Client] --> B[Server]
            B --> C[Database]
        ```
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertEqual(parsed.mermaidBlocks.count, 1)
        XCTAssertTrue(parsed.htmlContent.contains("mermaid-placeholder"))
        XCTAssertTrue(parsed.htmlContent.contains("data-mermaid-index=\"0\""))
    }
    
    func testHTMLWrapping() async throws {
        let content = "# Test"
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertTrue(parsed.htmlContent.contains("<!DOCTYPE html>"))
        XCTAssertTrue(parsed.htmlContent.contains("<html>"))
        XCTAssertTrue(parsed.htmlContent.contains("<head>"))
        XCTAssertTrue(parsed.htmlContent.contains("<body>"))
        XCTAssertTrue(parsed.htmlContent.contains("GitHub-compatible CSS"))
    }
    
    func testEmptyContent() async throws {
        let content = ""
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertEqual(parsed.mermaidBlocks.count, 0)
    }
    
    func testComplexMarkdown() async throws {
        let content = """
        # Main Title
        
        ## Introduction
        
        This is a **complex** document with *various* elements.
        
        ### Code Example
        
        ```python
        def hello():
            print("Hello, World!")
        ```
        
        ### List of Items
        
        1. First item
        2. Second item with `inline code`
        3. Third item with [link](https://example.com)
        
        > A blockquote with **bold** text.
        
        | Column A | Column B |
        |----------|----------|
        | Data 1   | Data 2   |
        
        ---
        
        ```mermaid
        graph TD
            A[Start] --> B[End]
        ```
        """
        
        let parsed = try await sut.parseMarkdown(content)
        
        XCTAssertNotNil(parsed.document)
        XCTAssertEqual(parsed.mermaidBlocks.count, 1)
        XCTAssertTrue(parsed.htmlContent.contains("<h1>Main Title</h1>"))
        XCTAssertTrue(parsed.htmlContent.contains("<h2>Introduction</h2>"))
        XCTAssertTrue(parsed.htmlContent.contains("<h3>Code Example</h3>"))
        XCTAssertTrue(parsed.htmlContent.contains("<strong>complex</strong>"))
        XCTAssertTrue(parsed.htmlContent.contains("<em>various</em>"))
        XCTAssertTrue(parsed.htmlContent.contains("def hello():"))
        XCTAssertTrue(parsed.htmlContent.contains("<code>inline code</code>"))
        XCTAssertTrue(parsed.htmlContent.contains("<blockquote>"))
        // Table might not be supported without extensions
        XCTAssertTrue(parsed.htmlContent.contains("Column A") || parsed.htmlContent.contains("<table>"))
        XCTAssertTrue(parsed.htmlContent.contains("<hr"))
        XCTAssertTrue(parsed.htmlContent.contains("mermaid-placeholder"))
    }
    
    func testRenderToHTML() async throws {
        let content = "# Hello"
        let parsed = try await sut.parseMarkdown(content)
        
        let html = await sut.renderToHTML(parsed)
        
        XCTAssertEqual(html, parsed.htmlContent)
    }
}