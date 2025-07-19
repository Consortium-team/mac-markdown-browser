import SwiftUI
import WebKit

struct SynchronizedPreviewView: NSViewRepresentable {
    let htmlContent: String
    var scrollSynchronizer: ScrollSynchronizer?
    var onScrollChange: ((Double) -> Void)?
    @Binding var scrollPercentage: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Load HTML if changed
        if context.coordinator.lastLoadedHTML != htmlContent {
            context.coordinator.lastLoadedHTML = htmlContent
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
        
        // Handle external scroll updates
        if let percentage = context.coordinator.pendingScrollPercentage {
            context.coordinator.pendingScrollPercentage = nil
            scrollSynchronizer?.scrollWebView(webView, toPercentage: percentage)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SynchronizedPreviewView
        weak var webView: WKWebView?
        var lastLoadedHTML: String = ""
        var pendingScrollPercentage: Double?
        var hasSetupScrollObserver = false
        
        init(_ parent: SynchronizedPreviewView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Set up scroll observer after content loads (only once per coordinator)
            if !hasSetupScrollObserver,
               let synchronizer = parent.scrollSynchronizer,
               let onScroll = parent.onScrollChange {
                synchronizer.setupWebViewScrollObserver(webView: webView, onScroll: onScroll)
                hasSetupScrollObserver = true
            }
            
            // Apply pending scroll if any
            if let percentage = pendingScrollPercentage {
                pendingScrollPercentage = nil
                parent.scrollSynchronizer?.scrollWebView(webView, toPercentage: percentage)
            }
        }
        
        func scrollToPercentage(_ percentage: Double) {
            if let webView = webView {
                parent.scrollSynchronizer?.scrollWebView(webView, toPercentage: percentage)
            } else {
                pendingScrollPercentage = percentage
            }
        }
    }
}