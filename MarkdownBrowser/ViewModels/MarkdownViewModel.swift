import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for managing Markdown content, rendering, and caching
@MainActor
class MarkdownViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentDocument: MarkdownDocument?
    @Published var renderedHTML: String = ""
    @Published var isRendering = false
    @Published var renderError: Error?
    @Published var mermaidBlocks: [MermaidBlock] = []
    
    // MARK: - Private Properties
    private let markdownService = MarkdownService()
    private var cancellables = Set<AnyCancellable>()
    private var renderTask: Task<Void, Never>?
    
    // Cache for rendered content (URL -> HTML)
    private var renderCache: [URL: CachedContent] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 50 // Maximum number of cached documents
    
    // Performance tracking
    private var renderStartTime: Date?
    
    // Refresh rate limiting
    private var lastRefreshTime: Date = .distantPast
    private let minimumRefreshInterval: TimeInterval = 0.5 // 500ms
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Loads and renders a Markdown or HTML document
    func loadDocument(at url: URL) async {
        // Cancel any existing render task
        renderTask?.cancel()
        
        // Check cache first
        if let cached = getCachedContent(for: url) {
            currentDocument = cached.document
            renderedHTML = cached.html
            mermaidBlocks = cached.mermaidBlocks
            return
        }
        
        // Create new document
        let document = MarkdownDocument(url: url)
        currentDocument = document
        
        // Load and render content
        await document.loadContent()
        
        if document.error == nil {
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
    
    /// Saves the current document
    func saveCurrentDocument() async {
        guard let document = currentDocument else { return }
        await document.saveContent()
        
        // Update cache after save
        if let url = currentDocument?.url {
            invalidateCache(for: url)
            await renderCurrentDocument()
        }
    }
    
    /// Reloads the current document from disk
    func reloadCurrentDocument() async {
        guard let document = currentDocument else { return }
        await document.reloadFromDisk()
        await renderDocument(document)
    }
    
    /// Refreshes the current document from disk with rate limiting
    func refreshContent() async {
        guard let document = currentDocument,
              canRefresh() else { return }
        
        lastRefreshTime = Date()
        
        // Invalidate cache for this document
        invalidateCache(for: document.url)
        
        // Reload from disk
        await document.reloadFromDisk()
        
        // Re-render the document
        await renderDocument(document)
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .documentRefreshed,
            object: nil,
            userInfo: ["url": document.url]
        )
    }
    
    /// Checks if refresh is allowed based on rate limiting
    func canRefresh() -> Bool {
        guard !isRendering else { return false }
        return Date().timeIntervalSince(lastRefreshTime) >= minimumRefreshInterval
    }
    
    /// Clears the render cache
    func clearCache() {
        renderCache.removeAll()
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
    
    private func observeDocument(_ document: MarkdownDocument) {
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
    
    private func renderDocument(_ document: MarkdownDocument) async {
        guard !document.content.isEmpty else {
            renderedHTML = ""
            mermaidBlocks = []
            return
        }
        
        isRendering = true
        renderError = nil
        renderStartTime = Date()
        
        do {
            var html: String
            var blocks: [MermaidBlock] = []
            
            // Check if it's an HTML file
            if document.url.isHTMLFile {
                // For HTML files, use the content directly
                html = document.content
                // HTML files don't have Mermaid blocks parsed from markdown
                blocks = []
            } else {
                // Parse and render Markdown
                let parsed = try await markdownService.parseMarkdown(document.content)
                html = await markdownService.renderToHTML(parsed)
                blocks = parsed.mermaidBlocks
                
                // Debug: Log Mermaid blocks found
                print("Found \(parsed.mermaidBlocks.count) Mermaid blocks")
                for (index, block) in parsed.mermaidBlocks.enumerated() {
                    print("Mermaid block \(index): \(block.code.prefix(50))...")
                }
                
                // Wrap HTML with Mermaid support if needed
                html = MermaidHTMLGenerator.wrapHTMLWithMermaid(html, mermaidBlocks: parsed.mermaidBlocks)
            }
            
            // Update UI
            renderedHTML = html
            mermaidBlocks = blocks
            
            // Cache the rendered content
            cacheContent(for: document.url, document: document, html: html, mermaidBlocks: blocks)
            
            // Log performance
            if let renderTime = lastRenderTime {
                let fileType = document.url.isHTMLFile ? "HTML" : "Markdown"
                print("\(fileType) rendered in \(String(format: "%.2f", renderTime * 1000))ms")
            }
            
        } catch {
            renderError = error
            renderedHTML = createErrorHTML(for: error)
            mermaidBlocks = []
        }
        
        isRendering = false
    }
    
    private func handleExternalChange() async {
        // In a real implementation, this would show a dialog
        // For now, we'll just reload if there are no unsaved changes
        guard let document = currentDocument else { return }
        
        if !document.hasUnsavedChanges {
            await reloadCurrentDocument()
        }
    }
    
    // MARK: - Caching
    
    private struct CachedContent {
        let document: MarkdownDocument
        let html: String
        let mermaidBlocks: [MermaidBlock]
        let timestamp: Date
    }
    
    private func getCachedContent(for url: URL) -> CachedContent? {
        guard let cached = renderCache[url] else { return nil }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > cacheExpirationTime {
            renderCache.removeValue(forKey: url)
            return nil
        }
        
        // Check if file has been modified
        if cached.document.hasExternalChanges() {
            renderCache.removeValue(forKey: url)
            return nil
        }
        
        return cached
    }
    
    private func cacheContent(for url: URL, document: MarkdownDocument, html: String, mermaidBlocks: [MermaidBlock]) {
        // Enforce cache size limit
        if renderCache.count >= maxCacheSize {
            // Remove oldest entries
            let sortedKeys = renderCache.keys.sorted { key1, key2 in
                let time1 = renderCache[key1]?.timestamp ?? Date.distantPast
                let time2 = renderCache[key2]?.timestamp ?? Date.distantPast
                return time1 < time2
            }
            
            // Remove oldest 20% of cache
            let removeCount = maxCacheSize / 5
            for i in 0..<removeCount {
                renderCache.removeValue(forKey: sortedKeys[i])
            }
        }
        
        renderCache[url] = CachedContent(
            document: document,
            html: html,
            mermaidBlocks: mermaidBlocks,
            timestamp: Date()
        )
    }
    
    private func invalidateCache(for url: URL) {
        renderCache.removeValue(forKey: url)
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
                <h2>Rendering Error</h2>
                <p>Failed to render the Markdown content:</p>
                <pre>\(message)</pre>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - Extensions

extension MarkdownViewModel {
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
}

// MARK: - Notification Names
extension Notification.Name {
    static let documentRefreshed = Notification.Name("documentRefreshed")
}