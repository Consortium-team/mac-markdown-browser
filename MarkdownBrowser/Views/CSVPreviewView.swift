import SwiftUI
import WebKit

struct CSVPreviewView: NSViewRepresentable {
    let htmlContent: String
    let onLoadComplete: (() -> Void)?
    
    init(htmlContent: String, onLoadComplete: (() -> Void)? = nil) {
        self.htmlContent = htmlContent
        self.onLoadComplete = onLoadComplete
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Create web page preferences with JavaScript disabled for security
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        configuration.defaultWebpagePreferences = preferences
        
        // Security: Don't allow file access
        configuration.preferences.setValue(false, forKey: "allowFileAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Disable navigation gestures for CSV preview
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        
        // Set transparent background for dark mode support
        webView.setValue(false, forKey: "drawsBackground")
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if content has changed significantly
        if context.coordinator.lastLoadedContent != htmlContent {
            context.coordinator.lastLoadedContent = htmlContent
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadComplete: onLoadComplete)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedContent: String = ""
        let onLoadComplete: (() -> Void)?
        
        init(onLoadComplete: (() -> Void)?) {
            self.onLoadComplete = onLoadComplete
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Prevent any navigation for security
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadComplete?()
        }
    }
}

// MARK: - Loading Overlay View

struct CSVLoadingOverlay: View {
    let rowCount: Int
    let columnCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading CSV...")
                .font(.system(size: 14, weight: .medium))
            
            Text("\(rowCount) rows × \(columnCount) columns")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - CSV Preview Container

struct CSVPreviewContainer: View {
    @ObservedObject var viewModel: CSVViewModel
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            CSVPreviewView(
                htmlContent: viewModel.renderedHTML,
                onLoadComplete: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isLoading = false
                    }
                }
            )
            .opacity(isLoading ? 0 : 1)
            
            if isLoading && viewModel.currentDocument != nil {
                CSVLoadingOverlay(
                    rowCount: viewModel.currentDocument?.csvData.rowCount ?? 0,
                    columnCount: viewModel.currentDocument?.csvData.columnCount ?? 0
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.renderedHTML) { _ in
            isLoading = true
        }
    }
}