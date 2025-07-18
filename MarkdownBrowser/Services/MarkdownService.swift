import Foundation
import Markdown
import WebKit

enum MarkdownError: LocalizedError {
    case parsingFailed(String)
    case renderingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .parsingFailed(let details):
            return "Failed to parse Markdown: \(details)"
        case .renderingFailed(let details):
            return "Failed to render Markdown: \(details)"
        }
    }
}

struct ParsedMarkdown {
    let document: Document
    let htmlContent: String
    let mermaidBlocks: [MermaidBlock]
}

struct MermaidBlock {
    let code: String
    let startLine: Int
    let endLine: Int
    let placeholder: String
}

class MarkdownService {
    
    private var githubCSS: String {
        """
        <style>
        /* GitHub-compatible CSS */
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            font-size: 16px;
            line-height: 1.5;
            word-wrap: break-word;
            padding: 20px;
            max-width: 980px;
            margin: 0 auto;
            color: var(--text-color, #24292e);
            background-color: var(--bg-color, #ffffff);
        }
        
        @media (prefers-color-scheme: dark) {
            body {
                --text-color: #e1e4e8;
                --bg-color: #0d1117;
                --border-color: #30363d;
                --code-bg: #161b22;
                --code-text: #e1e4e8;
                --blockquote-text: #8b949e;
                --link-color: #58a6ff;
                --table-border: #30363d;
                --table-row-bg: #161b22;
            }
        }
        
        @media (prefers-color-scheme: light) {
            body {
                --text-color: #24292e;
                --bg-color: #ffffff;
                --border-color: #e1e4e8;
                --code-bg: #f6f8fa;
                --code-text: #24292e;
                --blockquote-text: #57606a;
                --link-color: #0366d6;
                --table-border: #e1e4e8;
                --table-row-bg: #f6f8fa;
            }
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; border-bottom: 1px solid var(--border-color); padding-bottom: .3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid var(--border-color); padding-bottom: .3em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: .875em; }
        h6 { font-size: .85em; color: var(--blockquote-text); }
        
        p { margin-top: 0; margin-bottom: 10px; }
        
        a {
            color: var(--link-color);
            text-decoration: none;
        }
        
        a:hover { text-decoration: underline; }
        
        code {
            padding: .2em .4em;
            margin: 0;
            font-size: 85%;
            background-color: var(--code-bg);
            border-radius: 3px;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
            color: var(--code-text);
        }
        
        pre {
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: var(--code-bg);
            border-radius: 6px;
            margin-top: 0;
            margin-bottom: 16px;
        }
        
        pre code {
            display: inline;
            max-width: auto;
            padding: 0;
            margin: 0;
            overflow: visible;
            line-height: inherit;
            word-wrap: normal;
            background-color: transparent;
            border: 0;
        }
        
        blockquote {
            padding: 0 1em;
            color: var(--blockquote-text);
            border-left: .25em solid var(--border-color);
            margin: 0;
            margin-bottom: 16px;
        }
        
        table {
            display: block;
            width: 100%;
            overflow: auto;
            border-spacing: 0;
            border-collapse: collapse;
            margin-bottom: 16px;
        }
        
        table th, table td {
            padding: 6px 13px;
            border: 1px solid var(--table-border);
        }
        
        table tr {
            background-color: var(--bg-color);
            border-top: 1px solid var(--table-border);
        }
        
        table tr:nth-child(2n) {
            background-color: var(--table-row-bg);
        }
        
        ul, ol {
            padding-left: 2em;
            margin-top: 0;
            margin-bottom: 16px;
        }
        
        li + li { margin-top: .25em; }
        
        img {
            max-width: 100%;
            box-sizing: content-box;
            background-color: var(--bg-color);
        }
        
        hr {
            height: .25em;
            padding: 0;
            margin: 24px 0;
            background-color: var(--border-color);
            border: 0;
        }
        
        /* Syntax highlighting */
        .highlight { background: var(--code-bg); }
        .highlight .c { color: #6a737d; font-style: italic; } /* Comment */
        .highlight .k { color: #d73a49; } /* Keyword */
        .highlight .s { color: #032f62; } /* String */
        .highlight .n { color: #24292e; } /* Name */
        .highlight .o { color: #d73a49; } /* Operator */
        .highlight .p { color: #24292e; } /* Punctuation */
        
        /* Math expressions */
        .katex { font-size: 1em; }
        .katex-display { overflow: auto; }
        
        /* Mermaid placeholder */
        .mermaid-placeholder {
            background-color: var(--code-bg);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 16px;
            margin: 16px 0;
            text-align: center;
            font-family: monospace;
            color: var(--blockquote-text);
        }
        </style>
        """
    }
    
    func parseMarkdown(_ content: String) async throws -> ParsedMarkdown {
        return await Task.detached {
            let document = Document(parsing: content)
            
            let mermaidBlocks = self.extractMermaidBlocks(from: content)
            
            var processedContent = content
            for (index, block) in mermaidBlocks.enumerated() {
                let placeholder = "<!-- MERMAID_PLACEHOLDER_\(index) -->"
                processedContent = processedContent.replacingOccurrences(
                    of: block.code,
                    with: placeholder
                )
            }
            
            let processedDocument = Document(parsing: processedContent)
            var renderer = HTMLRenderer()
            let html = renderer.render(processedDocument)
            
            let fullHTML = self.wrapHTMLContent(html, mermaidBlocks: mermaidBlocks)
            
            return ParsedMarkdown(
                document: document,
                htmlContent: fullHTML,
                mermaidBlocks: mermaidBlocks
            )
        }.value
    }
    
    func renderToHTML(_ markdown: ParsedMarkdown) async -> String {
        return markdown.htmlContent
    }
    
    func extractMermaidBlocks(from content: String) -> [MermaidBlock] {
        var blocks: [MermaidBlock] = []
        let lines = content.components(separatedBy: .newlines)
        
        var inMermaidBlock = false
        var currentBlock = ""
        var startLine = 0
        
        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```mermaid") {
                inMermaidBlock = true
                startLine = index
                currentBlock = line + "\n"
            } else if inMermaidBlock && line.trimmingCharacters(in: .whitespaces) == "```" {
                currentBlock += line
                let placeholder = "<div class=\"mermaid-placeholder\" data-mermaid-index=\"\(blocks.count)\">Mermaid Diagram (Loading...)</div>"
                blocks.append(MermaidBlock(
                    code: currentBlock,
                    startLine: startLine,
                    endLine: index,
                    placeholder: placeholder
                ))
                inMermaidBlock = false
                currentBlock = ""
            } else if inMermaidBlock {
                currentBlock += line + "\n"
            }
        }
        
        return blocks
    }
    
    private func wrapHTMLContent(_ html: String, mermaidBlocks: [MermaidBlock]) -> String {
        var processedHTML = html
        
        for (index, block) in mermaidBlocks.enumerated() {
            let placeholder = "<!-- MERMAID_PLACEHOLDER_\(index) -->"
            processedHTML = processedHTML.replacingOccurrences(
                of: placeholder,
                with: block.placeholder
            )
        }
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(githubCSS)
        </head>
        <body>
            \(processedHTML)
        </body>
        </html>
        """
    }
}

private struct HTMLRenderer: MarkupVisitor {
    typealias Result = String
    
    mutating func defaultVisit(_ markup: any Markup) -> String {
        return markup.children.map { visit($0) }.joined()
    }
    
    mutating func visitDocument(_ document: Document) -> String {
        return document.children.map { visit($0) }.joined()
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        return "<p>\(paragraph.children.map { visit($0) }.joined())</p>\n"
    }
    
    mutating func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        let content = heading.children.map { visit($0) }.joined()
        return "<h\(level)>\(content)</h\(level)>\n"
    }
    
    mutating func visitText(_ text: Text) -> String {
        return escapeHTML(text.string)
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        return "<em>\(emphasis.children.map { visit($0) }.joined())</em>"
    }
    
    mutating func visitStrong(_ strong: Strong) -> String {
        return "<strong>\(strong.children.map { visit($0) }.joined())</strong>"
    }
    
    mutating func visitLink(_ link: Link) -> String {
        let content = link.children.map { visit($0) }.joined()
        let href = escapeHTML(link.destination ?? "")
        let title = link.title.map { " title=\"\(escapeHTML($0))\"" } ?? ""
        return "<a href=\"\(href)\"\(title)>\(content)</a>"
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let code = escapeHTML(codeBlock.code)
        let languageClass = codeBlock.language.map { " class=\"language-\(escapeHTML($0))\"" } ?? ""
        return "<pre><code\(languageClass)>\(code)</code></pre>\n"
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        return "<code>\(escapeHTML(inlineCode.code))</code>"
    }
    
    mutating func visitUnorderedList(_ list: UnorderedList) -> String {
        return "<ul>\n\(list.children.map { visit($0) }.joined())</ul>\n"
    }
    
    mutating func visitOrderedList(_ list: OrderedList) -> String {
        return "<ol>\n\(list.children.map { visit($0) }.joined())</ol>\n"
    }
    
    mutating func visitListItem(_ item: ListItem) -> String {
        let content = item.children.map { visit($0) }.joined()
        // Remove paragraph tags from list items if they're the only content
        let cleanContent = content
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "<li>\(cleanContent)</li>\n"
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        return "<blockquote>\n\(blockQuote.children.map { visit($0) }.joined())</blockquote>\n"
    }
    
    mutating func visitTable(_ table: Table) -> String {
        var html = "<table>\n"
        
        html += "<thead>\n"
        html += visit(table.head)
        html += "</thead>\n"
        
        html += "<tbody>\n"
        html += visit(table.body)
        html += "</tbody>\n"
        
        html += "</table>\n"
        return html
    }
    
    mutating func visitTableHead(_ head: Table.Head) -> String {
        return head.children.map { visit($0) }.joined()
    }
    
    mutating func visitTableBody(_ body: Table.Body) -> String {
        return body.children.map { visit($0) }.joined()
    }
    
    mutating func visitTableRow(_ row: Table.Row) -> String {
        return "<tr>\n\(row.children.map { visit($0) }.joined())</tr>\n"
    }
    
    mutating func visitTableCell(_ cell: Table.Cell) -> String {
        let isHeader = cell.parent is Table.Row && cell.parent?.parent is Table.Head
        let tag = isHeader ? "th" : "td"
        let content = cell.children.map { visit($0) }.joined()
        return "<\(tag)>\(content)</\(tag)>\n"
    }
    
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        return "<hr>\n"
    }
    
    mutating func visitImage(_ image: Image) -> String {
        let src = escapeHTML(image.source ?? "")
        let alt = image.children.map { visit($0) }.joined()
        let title = image.title.map { " title=\"\(escapeHTML($0))\"" } ?? ""
        return "<img src=\"\(src)\" alt=\"\(escapeHTML(alt))\"\(title)>"
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br>\n"
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }
    
    mutating func visitInlineHTML(_ html: InlineHTML) -> String {
        return html.rawHTML
    }
    
    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        return html.rawHTML + "\n"
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    mutating func render(_ document: Document) -> String {
        return visit(document)
    }
}