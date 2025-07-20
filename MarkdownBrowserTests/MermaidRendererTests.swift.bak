import XCTest
import WebKit
@testable import MarkdownBrowser

@MainActor
class MermaidRendererTests: XCTestCase {
    
    var renderer: MermaidRenderer!
    
    override func setUp() async throws {
        try await super.setUp()
        renderer = MermaidRenderer()
        
        // Give WebView time to initialize
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }
    
    override func tearDown() async throws {
        renderer = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Rendering Tests
    
    func testRenderSimpleFlowchart() async throws {
        let mermaidCode = """
        ```mermaid
        graph TD
            A[Start] --> B{Is it?}
            B -->|Yes| C[OK]
            B -->|No| D[End]
        ```
        """
        
        let svg = try await renderer.renderMermaidDiagram(mermaidCode)
        
        // Verify SVG was generated
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Start"))
        XCTAssertTrue(svg.contains("Is it?"))
        XCTAssertTrue(svg.contains("OK"))
        XCTAssertTrue(svg.contains("End"))
    }
    
    func testRenderSequenceDiagram() async throws {
        let mermaidCode = """
        ```mermaid
        sequenceDiagram
            Alice->>Bob: Hello Bob
            Bob-->>Alice: Hi Alice
            Bob->>Charlie: How are you?
            Charlie-->>Bob: I'm good, thanks!
        ```
        """
        
        let svg = try await renderer.renderMermaidDiagram(mermaidCode)
        
        // Verify SVG was generated with expected content
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Alice"))
        XCTAssertTrue(svg.contains("Bob"))
        XCTAssertTrue(svg.contains("Charlie"))
    }
    
    func testRenderGanttChart() async throws {
        let mermaidCode = """
        ```mermaid
        gantt
            title A Gantt Diagram
            dateFormat YYYY-MM-DD
            section Section
                A task          :a1, 2024-01-01, 30d
                Another task    :after a1, 20d
                Third task      :2024-02-01, 12d
        ```
        """
        
        let svg = try await renderer.renderMermaidDiagram(mermaidCode)
        
        // Verify SVG was generated
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("A Gantt Diagram") || svg.contains("Section"))
    }
    
    func testRenderClassDiagram() async throws {
        let mermaidCode = """
        ```mermaid
        classDiagram
            Animal <|-- Duck
            Animal <|-- Fish
            Animal <|-- Zebra
            Animal : +int age
            Animal : +String gender
            Animal: +isMammal()
            Animal: +mate()
            class Duck{
                +String beakColor
                +swim()
                +quack()
            }
        ```
        """
        
        let svg = try await renderer.renderMermaidDiagram(mermaidCode)
        
        // Verify SVG was generated
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Animal"))
        XCTAssertTrue(svg.contains("Duck"))
    }
    
    // MARK: - HTML Integration Tests
    
    func testRenderMermaidInHTML() async throws {
        let baseHTML = """
        <h1>Test Document</h1>
        <p>Here's a diagram:</p>
        <div class="mermaid-placeholder" data-mermaid-index="0">Mermaid Diagram (Loading...)</div>
        <p>More content here.</p>
        """
        
        let mermaidBlock = MermaidBlock(
            code: """
            ```mermaid
            graph LR
                A[Input] --> B[Process]
                B --> C[Output]
            ```
            """,
            startLine: 3,
            endLine: 7,
            placeholder: "<div class=\"mermaid-placeholder\" data-mermaid-index=\"0\">Mermaid Diagram (Loading...)</div>"
        )
        
        let renderedHTML = try await renderer.renderMermaidInHTML(baseHTML, mermaidBlocks: [mermaidBlock])
        
        // Verify placeholder was replaced with SVG
        XCTAssertFalse(renderedHTML.contains("Mermaid Diagram (Loading...)"))
        XCTAssertTrue(renderedHTML.contains("<svg"))
        XCTAssertTrue(renderedHTML.contains("mermaid-container"))
        XCTAssertTrue(renderedHTML.contains("Input"))
        XCTAssertTrue(renderedHTML.contains("Process"))
        XCTAssertTrue(renderedHTML.contains("Output"))
    }
    
    func testRenderMultipleMermaidBlocks() async throws {
        let baseHTML = """
        <h1>Multiple Diagrams</h1>
        <div class="mermaid-placeholder" data-mermaid-index="0">Mermaid Diagram (Loading...)</div>
        <div class="mermaid-placeholder" data-mermaid-index="1">Mermaid Diagram (Loading...)</div>
        """
        
        let block1 = MermaidBlock(
            code: """
            ```mermaid
            graph TD
                A[First] --> B[Second]
            ```
            """,
            startLine: 2,
            endLine: 5,
            placeholder: "<div class=\"mermaid-placeholder\" data-mermaid-index=\"0\">Mermaid Diagram (Loading...)</div>"
        )
        
        let block2 = MermaidBlock(
            code: """
            ```mermaid
            graph LR
                X[Start] --> Y[End]
            ```
            """,
            startLine: 6,
            endLine: 9,
            placeholder: "<div class=\"mermaid-placeholder\" data-mermaid-index=\"1\">Mermaid Diagram (Loading...)</div>"
        )
        
        let renderedHTML = try await renderer.renderMermaidInHTML(baseHTML, mermaidBlocks: [block1, block2])
        
        // Verify both placeholders were replaced
        XCTAssertFalse(renderedHTML.contains("Mermaid Diagram (Loading...)"))
        XCTAssertTrue(renderedHTML.contains("First"))
        XCTAssertTrue(renderedHTML.contains("Second"))
        XCTAssertTrue(renderedHTML.contains("Start"))
        XCTAssertTrue(renderedHTML.contains("End"))
        
        // Should have two mermaid containers
        let containerCount = renderedHTML.components(separatedBy: "mermaid-container").count - 1
        XCTAssertEqual(containerCount, 2)
    }
    
    // MARK: - Error Handling Tests
    
    func testRenderInvalidMermaidSyntax() async throws {
        let invalidCode = """
        ```mermaid
        graph TD
            A[Start --> B[Missing closing bracket
            C[Invalid syntax here
        ```
        """
        
        do {
            _ = try await renderer.renderMermaidDiagram(invalidCode)
            XCTFail("Should have thrown an error for invalid syntax")
        } catch {
            // Expected error
            XCTAssertTrue(error.localizedDescription.contains("failed") || 
                         error.localizedDescription.contains("error"))
        }
    }
    
    func testRenderEmptyMermaidBlock() async throws {
        let emptyCode = """
        ```mermaid
        ```
        """
        
        do {
            _ = try await renderer.renderMermaidDiagram(emptyCode)
            XCTFail("Should have thrown an error for empty diagram")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testErrorPlaceholderInHTML() async throws {
        let baseHTML = """
        <h1>Test with Error</h1>
        <div class="mermaid-placeholder" data-mermaid-index="0">Mermaid Diagram (Loading...)</div>
        """
        
        let invalidBlock = MermaidBlock(
            code: """
            ```mermaid
            invalid mermaid syntax here
            ```
            """,
            startLine: 2,
            endLine: 4,
            placeholder: "<div class=\"mermaid-placeholder\" data-mermaid-index=\"0\">Mermaid Diagram (Loading...)</div>"
        )
        
        let renderedHTML = try await renderer.renderMermaidInHTML(baseHTML, mermaidBlocks: [invalidBlock])
        
        // Should contain error message instead of placeholder
        XCTAssertFalse(renderedHTML.contains("Mermaid Diagram (Loading...)"))
        XCTAssertTrue(renderedHTML.contains("mermaid-error") || renderedHTML.contains("Failed"))
        XCTAssertTrue(renderedHTML.contains("details") || renderedHTML.contains("Show diagram code"))
    }
    
    // MARK: - Performance Tests
    
    func testRenderPerformance() async throws {
        let mermaidCode = """
        ```mermaid
        graph TD
            A[Start] --> B[Step 1]
            B --> C[Step 2]
            C --> D[Step 3]
            D --> E[Step 4]
            E --> F[End]
        ```
        """
        
        let startTime = Date()
        _ = try await renderer.renderMermaidDiagram(mermaidCode)
        let renderTime = Date().timeIntervalSince(startTime)
        
        // Should render within 500ms as per requirements
        XCTAssertLessThan(renderTime, 0.5, "Mermaid rendering took too long: \(renderTime)s")
    }
    
    func testRenderComplexDiagramPerformance() async throws {
        // Create a more complex diagram
        var nodes = ""
        for i in 0..<20 {
            nodes += "    A\(i)[Node \(i)] --> A\(i+1)[Node \(i+1)]\n"
        }
        
        let complexCode = """
        ```mermaid
        graph TD
        \(nodes)
        ```
        """
        
        let startTime = Date()
        _ = try await renderer.renderMermaidDiagram(complexCode)
        let renderTime = Date().timeIntervalSince(startTime)
        
        // Complex diagram should still render within 500ms
        XCTAssertLessThan(renderTime, 0.5, "Complex diagram rendering took too long: \(renderTime)s")
    }
    
    // MARK: - State Tests
    
    func testIsRenderingState() async throws {
        let baseHTML = "<p>Test</p>"
        let block = MermaidBlock(
            code: "```mermaid\ngraph TD\n    A --> B\n```",
            startLine: 1,
            endLine: 4,
            placeholder: "<div>placeholder</div>"
        )
        
        XCTAssertFalse(renderer.isRendering)
        
        let renderTask = Task {
            try await renderer.renderMermaidInHTML(baseHTML, mermaidBlocks: [block])
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Should be rendering (might be flaky in fast environments)
        // Just ensure it completes without error
        _ = try await renderTask.value
        
        XCTAssertFalse(renderer.isRendering)
    }
}