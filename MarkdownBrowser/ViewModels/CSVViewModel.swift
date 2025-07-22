import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for managing CSV content, rendering, and updates
@MainActor
class CSVViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentDocument: CSVDocument?
    @Published var renderedHTML: String = ""
    @Published var isRendering = false
    @Published var renderError: Error?
    @Published var selectedDelimiter: CSVDelimiter = .comma
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var renderTask: Task<Void, Never>?
    
    // Performance tracking
    private var renderStartTime: Date?
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Loads and renders a CSV document
    func loadDocument(at url: URL) async {
        // Cancel any existing render task
        renderTask?.cancel()
        
        // Create new document
        let document = CSVDocument(url: url)
        currentDocument = document
        
        // Load and render content
        await document.loadContent()
        
        if document.error == nil {
            selectedDelimiter = document.csvData.delimiter
            await renderDocument(document)
        }
    }
    
    /// Renders the current document's content
    func renderCurrentDocument() async {
        guard let document = currentDocument else { return }
        await renderDocument(document)
    }
    
    /// Updates the document content and triggers re-rendering
    func updateContent(_ newContent: String) {
        guard let document = currentDocument else { return }
        
        document.updateContent(newContent)
        
        // Debounce rendering for performance
        renderTask?.cancel()
        renderTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            
            if !Task.isCancelled {
                await renderDocument(document)
            }
        }
    }
    
    /// Changes the delimiter and re-renders
    func changeDelimiter(_ newDelimiter: CSVDelimiter) {
        guard let document = currentDocument else { return }
        
        selectedDelimiter = newDelimiter
        document.changeDelimiter(newDelimiter)
        
        Task {
            await renderDocument(document)
        }
    }
    
    /// Saves the current document
    func saveCurrentDocument() async {
        guard let document = currentDocument else { return }
        await document.saveContent()
    }
    
    /// Reloads the current document from disk
    func reloadCurrentDocument() async {
        guard let document = currentDocument else { return }
        await document.reloadFromDisk()
        selectedDelimiter = document.csvData.delimiter
        await renderDocument(document)
    }
    
    /// Gets performance metrics for the last render
    var lastRenderTime: TimeInterval? {
        guard let startTime = renderStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor document changes
        $currentDocument
            .compactMap { $0 }
            .sink { [weak self] document in
                self?.observeDocument(document)
            }
            .store(in: &cancellables)
    }
    
    private func observeDocument(_ document: CSVDocument) {
        // Cancel previous observations
        cancellables.removeAll()
        
        // Observe content changes
        document.$content
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.renderCurrentDocument()
                }
            }
            .store(in: &cancellables)
        
        // Observe external changes
        document.$error
            .compactMap { error -> DocumentError? in
                if case .conflictDetected = error {
                    return error
                }
                return nil
            }
            .sink { [weak self] _ in
                Task {
                    await self?.handleExternalChange()
                }
            }
            .store(in: &cancellables)
    }
    
    private func renderDocument(_ document: CSVDocument) async {
        guard !document.content.isEmpty else {
            renderedHTML = ""
            return
        }
        
        isRendering = true
        renderError = nil
        renderStartTime = Date()
        
        // Generate HTML table from CSV data
        let html = generateHTMLTable(from: document.csvData)
        
        // Update UI
        renderedHTML = html
        
        // Log performance
        if let renderTime = lastRenderTime {
            print("CSV rendered in \(String(format: "%.2f", renderTime * 1000))ms")
            print("Table size: \(document.csvData.rowCount) rows × \(document.csvData.columnCount) columns")
        }
        
        isRendering = false
    }
    
    private func generateHTMLTable(from csvData: CSVData) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                :root {
                    --background: #ffffff;
                    --text: #1a1a1a;
                    --border: #e1e4e8;
                    --header-bg: #f6f8fa;
                    --row-hover: #f3f4f6;
                    --row-even: #f9fafb;
                }
                
                @media (prefers-color-scheme: dark) {
                    :root {
                        --background: #0d1117;
                        --text: #c9d1d9;
                        --border: #30363d;
                        --header-bg: #161b22;
                        --row-hover: #161b22;
                        --row-even: #0d1117;
                    }
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    margin: 0;
                    padding: 20px;
                    background-color: var(--background);
                    color: var(--text);
                }
                
                .table-container {
                    overflow-x: auto;
                    border: 1px solid var(--border);
                    border-radius: 6px;
                    background-color: var(--background);
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    font-size: 14px;
                }
                
                th, td {
                    padding: 8px 12px;
                    text-align: left;
                    border-bottom: 1px solid var(--border);
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    max-width: 300px;
                }
                
                th {
                    background-color: var(--header-bg);
                    font-weight: 600;
                    position: sticky;
                    top: 0;
                    z-index: 10;
                }
                
                tr:nth-child(even) {
                    background-color: var(--row-even);
                }
                
                tr:hover {
                    background-color: var(--row-hover);
                }
                
                .metadata {
                    margin-bottom: 10px;
                    font-size: 12px;
                    color: var(--text);
                    opacity: 0.7;
                }
                
                .empty-state {
                    text-align: center;
                    padding: 40px;
                    color: var(--text);
                    opacity: 0.5;
                }
            </style>
        </head>
        <body>
        """
        
        // Add metadata
        html += """
            <div class="metadata">
                \(csvData.rowCount) rows × \(csvData.columnCount) columns
                • Delimiter: \(csvData.delimiter.displayName)
            </div>
        """
        
        if csvData.headers.isEmpty && csvData.rows.isEmpty {
            html += """
                <div class="empty-state">
                    <p>No CSV data to display</p>
                </div>
            """
        } else {
            html += """
                <div class="table-container">
                    <table>
            """
            
            // Add headers
            if !csvData.headers.isEmpty {
                html += "<thead><tr>"
                for header in csvData.headers {
                    let escaped = escapeHTML(header)
                    html += "<th>\(escaped)</th>"
                }
                html += "</tr></thead>"
            }
            
            // Add rows
            html += "<tbody>"
            
            // Limit rows for performance (show first 1000 rows)
            let displayRows = min(csvData.rows.count, 1000)
            for i in 0..<displayRows {
                html += "<tr>"
                let row = csvData.rows[i]
                
                // Ensure we have enough columns
                let columnCount = max(csvData.headers.count, row.count)
                for j in 0..<columnCount {
                    let value = j < row.count ? row[j] : ""
                    let escaped = escapeHTML(value)
                    html += "<td>\(escaped)</td>"
                }
                html += "</tr>"
            }
            
            if csvData.rows.count > 1000 {
                html += """
                    <tr>
                        <td colspan="\(csvData.columnCount)" style="text-align: center; opacity: 0.7;">
                            ... and \(csvData.rows.count - 1000) more rows
                        </td>
                    </tr>
                """
            }
            
            html += "</tbody></table></div>"
        }
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private func handleExternalChange() async {
        // In a real implementation, this would show a dialog
        // For now, we'll just reload if there are no unsaved changes
        guard let document = currentDocument else { return }
        
        if !document.hasUnsavedChanges {
            await reloadCurrentDocument()
        }
    }
    
    // MARK: - Error Handling
    
    private func createErrorHTML(for error: Error) -> String {
        let message = error.localizedDescription
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 20px;
                    color: #d32f2f;
                    background-color: #ffebee;
                }
                .error-container {
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                h2 { margin-top: 0; }
                pre {
                    background: #f5f5f5;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                }
            </style>
        </head>
        <body>
            <div class="error-container">
                <h2>CSV Rendering Error</h2>
                <p>Failed to render the CSV content:</p>
                <pre>\(message)</pre>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - Extensions

extension CSVViewModel {
    /// Convenience computed properties
    
    var hasUnsavedChanges: Bool {
        currentDocument?.hasUnsavedChanges ?? false
    }
    
    var documentName: String {
        currentDocument?.name ?? "Untitled"
    }
    
    var documentSize: String {
        currentDocument?.formattedFileSize ?? "0 KB"
    }
    
    var lastModified: Date? {
        currentDocument?.lastModified
    }
    
    var isLoading: Bool {
        currentDocument?.isLoading ?? false
    }
    
    var documentError: DocumentError? {
        currentDocument?.error
    }
    
    var documentMetadata: String {
        currentDocument?.metadata ?? "0 rows × 0 columns"
    }
}