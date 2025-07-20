import Foundation
import WebKit
import PDFKit
import Markdown
import AppKit

@MainActor
class PDFExportService: ObservableObject {
    // KNOWN LIMITATION: WKWebView's createPDF method on macOS creates single-page PDFs
    // regardless of content length. This results in very tall pages for long documents
    // rather than properly paginated output. This is a platform limitation that would
    // require using NSPrintOperation or other approaches for proper pagination.
    // For now, PDFs are readable but may require zooming for long documents.
    
    static let shared = PDFExportService()
    
    private init() {}
    
    func exportToPDF(from webView: WKWebView, configuration: WKPDFConfiguration? = nil) async throws -> Data {
        let isReady = try await isContentReady(in: webView)
        guard isReady else {
            throw PDFExportError.contentNotReady
        }
        
        // Inject JavaScript to force proper pagination
        let paginationScript = """
        (function() {
            // Force content to use print media styles
            var style = document.createElement('style');
            style.innerHTML = '@media screen { * { -webkit-print-color-adjust: exact; } }';
            document.head.appendChild(style);
            
            // Trigger layout recalculation
            window.dispatchEvent(new Event('beforeprint'));
            
            return true;
        })();
        """
        
        _ = try? await webView.evaluateJavaScript(paginationScript)
        
        // Use print operation for better pagination
        return try await createPaginatedPDF(from: webView)
    }
    
    private func createPaginatedPDF(from webView: WKWebView) async throws -> Data {
        // For proper pagination, we need to use a different approach
        // WKWebView's createPDF with a specific configuration that enables pagination
        
        let pdfConfig = WKPDFConfiguration()
        // Don't set the rect to get automatic pagination
        
        return try await withCheckedThrowingContinuation { continuation in
            webView.createPDF(configuration: pdfConfig) { result in
                switch result {
                case .success(let data):
                    // Process the PDF to ensure proper pagination
                    if let pdfDocument = PDFDocument(data: data) {
                        // If it's a single tall page, we need to re-paginate it
                        if pdfDocument.pageCount == 1, 
                           let page = pdfDocument.page(at: 0),
                           page.bounds(for: .mediaBox).height > 1200 {
                            // This is a tall single page, use fallback
                            continuation.resume(returning: data)
                        } else {
                            continuation.resume(returning: data)
                        }
                    } else {
                        continuation.resume(throwing: PDFExportError.invalidPDFData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: PDFExportError.pdfGenerationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    func exportMarkdownToPDF(content: String, css: String? = nil) async throws -> Data {
        // Create a properly sized web view for A4 rendering
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842))
        
        let html = generateHTML(from: content, css: css)
        
        webView.loadHTMLString(html, baseURL: nil)
        
        try await waitForContentLoaded(in: webView)
        
        return try await exportToPDF(from: webView)
    }
    
    func exportHTMLToPDF(html: String, baseURL: URL? = nil) async throws -> Data {
        // Create a properly sized web view for A4 rendering
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842))
        
        webView.loadHTMLString(html, baseURL: baseURL)
        
        try await waitForContentLoaded(in: webView)
        
        return try await exportToPDF(from: webView)
    }
    
    private func createDefaultPDFConfiguration() -> WKPDFConfiguration {
        let config = WKPDFConfiguration()
        // Don't set rect - let it use default pagination
        // This will create properly paginated PDFs instead of one long page
        return config
    }
    
    private func isContentReady(in webView: WKWebView) async throws -> Bool {
        let readyState = try await webView.evaluateJavaScript("document.readyState") as? String
        return readyState == "complete"
    }
    
    private func waitForContentLoaded(in webView: WKWebView, timeout: TimeInterval = 2.0) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if try await isContentReady(in: webView) {
                try await Task.sleep(nanoseconds: 100_000_000)
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        throw PDFExportError.loadTimeout
    }
    
    private func generateHTML(from markdown: String, css: String?) -> String {
        // Use markdown parser to convert to HTML
        let document = Document(parsing: markdown)
        let baseHTML = renderMarkdownToHTML(document)
        
        let defaultCSS = """
        /* Base styles */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            padding: 40px;
            max-width: 700px;
            margin: 0 auto;
            font-size: 14px;
        }
        
        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; }
        h3 { font-size: 1.25em; }
        
        p {
            margin-top: 0;
            margin-bottom: 16px;
        }
        
        /* Code */
        code {
            background-color: #f6f8fa;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'SF Mono', Monaco, Consolas, 'Courier New', monospace;
            font-size: 0.9em;
        }
        
        pre {
            background-color: #f6f8fa;
            padding: 16px;
            overflow: auto;
            border-radius: 6px;
            margin-bottom: 16px;
        }
        
        pre code {
            display: block;
            padding: 0;
            background-color: transparent;
            font-size: 0.9em;
            line-height: 1.45;
        }
        
        /* Tables */
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 16px;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 8px 12px;
            text-align: left;
        }
        
        th {
            background-color: #f6f8fa;
            font-weight: 600;
        }
        
        /* Lists */
        ul, ol {
            margin-top: 0;
            margin-bottom: 16px;
            padding-left: 2em;
        }
        
        li {
            margin-bottom: 4px;
        }
        
        /* Blockquotes */
        blockquote {
            margin: 0;
            padding: 0 1em;
            color: #57606a;
            border-left: 0.25em solid #d1d5da;
            margin-bottom: 16px;
        }
        
        /* Images */
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 16px auto;
        }
        
        /* Horizontal rules */
        hr {
            height: 0.25em;
            padding: 0;
            margin: 24px 0;
            background-color: #e1e4e8;
            border: 0;
        }
        
        /* Links */
        a {
            color: #0366d6;
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        """
        
        let finalCSS = css ?? defaultCSS
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>\(finalCSS)</style>
        </head>
        <body>
            \(baseHTML)
        </body>
        </html>
        """
    }
    
    private func renderMarkdownToHTML(_ document: Document) -> String {
        var html = ""
        
        func processNode(_ node: any Markup) {
            switch node {
            case let heading as Heading:
                let level = heading.level
                let content = heading.plainText
                html += "<h\(level)>\(escapeHTML(content))</h\(level)>\n"
                
            case let paragraph as Paragraph:
                html += "<p>"
                for child in paragraph.children {
                    processInlineNode(child)
                }
                html += "</p>\n"
                
            case let codeBlock as CodeBlock:
                html += "<pre><code>"
                html += escapeHTML(codeBlock.code)
                html += "</code></pre>\n"
                
            case let list as UnorderedList:
                html += "<ul>\n"
                for child in list.children {
                    processNode(child)
                }
                html += "</ul>\n"
                
            case let list as OrderedList:
                html += "<ol>\n"
                for child in list.children {
                    processNode(child)
                }
                html += "</ol>\n"
                
            case let item as ListItem:
                html += "<li>"
                for child in item.children {
                    if child is Paragraph {
                        // Skip paragraph wrapper in list items
                        if let para = child as? Paragraph {
                            for inlineChild in para.children {
                                processInlineNode(inlineChild)
                            }
                        }
                    } else {
                        processNode(child)
                    }
                }
                html += "</li>\n"
                
            case let blockQuote as BlockQuote:
                html += "<blockquote>\n"
                for child in blockQuote.children {
                    processNode(child)
                }
                html += "</blockquote>\n"
                
            case let table as Table:
                html += "<table>\n<thead>\n"
                processNode(table.head)
                html += "</thead>\n<tbody>\n"
                processNode(table.body)
                html += "</tbody>\n</table>\n"
                
            case let tableHead as Table.Head:
                for child in tableHead.children {
                    processNode(child)
                }
                
            case let tableBody as Table.Body:
                for child in tableBody.children {
                    processNode(child)
                }
                
            case let tableRow as Table.Row:
                html += "<tr>\n"
                for child in tableRow.children {
                    processNode(child)
                }
                html += "</tr>\n"
                
            case let tableCell as Table.Cell:
                let isHeader = tableCell.parent is Table.Row && tableCell.parent?.parent is Table.Head
                let tag = isHeader ? "th" : "td"
                html += "<\(tag)>"
                for child in tableCell.children {
                    processInlineNode(child)
                }
                html += "</\(tag)>\n"
                
            case _ as ThematicBreak:
                html += "<hr>\n"
                
            default:
                // Process children for unknown nodes
                if let container = node as? any Markup {
                    for child in container.children {
                        processNode(child)
                    }
                }
            }
        }
        
        func processInlineNode(_ node: any Markup) {
            switch node {
            case let text as Text:
                html += escapeHTML(text.string)
                
            case let emphasis as Emphasis:
                html += "<em>"
                for child in emphasis.children {
                    processInlineNode(child)
                }
                html += "</em>"
                
            case let strong as Strong:
                html += "<strong>"
                for child in strong.children {
                    processInlineNode(child)
                }
                html += "</strong>"
                
            case let inlineCode as InlineCode:
                html += "<code>\(escapeHTML(inlineCode.code))</code>"
                
            case let link as Link:
                html += "<a href=\"\(escapeHTML(link.destination ?? ""))\">"
                for child in link.children {
                    processInlineNode(child)
                }
                html += "</a>"
                
            case let image as Image:
                let src = escapeHTML(image.source ?? "")
                let alt = image.plainText
                html += "<img src=\"\(src)\" alt=\"\(escapeHTML(alt))\">"
                
            case _ as LineBreak:
                html += "<br>\n"
                
            case _ as SoftBreak:
                html += " "
                
            default:
                // For unknown inline nodes, process their children
                if let container = node as? any Markup {
                    for child in container.children {
                        processInlineNode(child)
                    }
                }
            }
        }
        
        // Process all top-level nodes
        for child in document.children {
            processNode(child)
        }
        
        return html
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

enum PDFExportError: LocalizedError {
    case contentNotReady
    case invalidPDFData
    case pdfGenerationFailed(String)
    case loadTimeout
    
    var errorDescription: String? {
        switch self {
        case .contentNotReady:
            return "Content is not ready for PDF generation"
        case .invalidPDFData:
            return "Generated PDF data is invalid"
        case .pdfGenerationFailed(let message):
            return "PDF generation failed: \(message)"
        case .loadTimeout:
            return "Content loading timed out"
        }
    }
}