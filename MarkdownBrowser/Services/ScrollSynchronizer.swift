import Foundation
import AppKit
import WebKit

class ScrollSynchronizer: ObservableObject {
    private var isUpdatingScroll = false
    private var scrollTimer: Timer?
    private let scrollDebounceInterval: TimeInterval = 0.1
    
    func setupTextViewScrollObserver(textView: NSTextView, onScroll: @escaping (Double) -> Void) {
        guard let scrollView = textView.enclosingScrollView else { return }
        
        // Enable bounds change notifications
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        // Observe scroll changes
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  !self.isUpdatingScroll,
                  let clipView = notification.object as? NSClipView else { return }
            
            // Debounce rapid scroll events
            self.scrollTimer?.invalidate()
            self.scrollTimer = Timer.scheduledTimer(withTimeInterval: self.scrollDebounceInterval, repeats: false) { _ in
                let visibleRect = clipView.visibleRect
                let documentHeight = clipView.documentRect.height
                let scrollPercentage = min(1.0, max(0.0, Double(visibleRect.origin.y / max(1, documentHeight - visibleRect.height))))
                
                onScroll(scrollPercentage)
            }
        }
    }
    
    func scrollWebView(_ webView: WKWebView, toPercentage percentage: Double) {
        guard !isUpdatingScroll else { return }
        
        isUpdatingScroll = true
        let script = """
            var scrollHeight = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
            window.scrollTo({
                top: scrollHeight * \(percentage),
                behavior: 'smooth'
            });
        """
        
        webView.evaluateJavaScript(script) { [weak self] _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.isUpdatingScroll = false
            }
        }
    }
    
    func scrollTextView(_ textView: NSTextView, toPercentage percentage: Double) {
        guard !isUpdatingScroll,
              let scrollView = textView.enclosingScrollView else { return }
        
        isUpdatingScroll = true
        
        let documentHeight = scrollView.documentView?.frame.height ?? 0
        let viewportHeight = scrollView.contentView.frame.height
        let maxScrollY = max(0, documentHeight - viewportHeight)
        let targetY = maxScrollY * CGFloat(percentage)
        
        let newOrigin = NSPoint(x: 0, y: targetY)
        scrollView.contentView.scroll(to: newOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isUpdatingScroll = false
        }
    }
    
    func setupWebViewScrollObserver(webView: WKWebView, onScroll: @escaping (Double) -> Void) {
        // Inject JavaScript to monitor scroll events
        let script = """
            // Check if scroll handler already exists
            if (!window.scrollHandlerInstalled) {
                window.scrollHandlerInstalled = true;
                var lastScrollPosition = 0;
                var scrollTimer = null;
                
                window.addEventListener('scroll', function() {
                    if (scrollTimer !== null) {
                        clearTimeout(scrollTimer);
                    }
                    
                    scrollTimer = setTimeout(function() {
                        var scrollHeight = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
                        var currentScroll = window.pageYOffset || document.documentElement.scrollTop;
                        var scrollPercentage = Math.min(1.0, Math.max(0.0, currentScroll / scrollHeight));
                        
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.scrollHandler) {
                            window.webkit.messageHandlers.scrollHandler.postMessage({
                                percentage: scrollPercentage
                            });
                        }
                    }, 100);
                }, false);
            }
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
        
        // Set up message handler
        let contentController = webView.configuration.userContentController
        
        // Remove existing handler if present to avoid duplicate handler error
        contentController.removeScriptMessageHandler(forName: "scrollHandler")
        
        // Add new handler
        contentController.add(ScrollMessageHandler(onScroll: { [weak self] percentage in
            guard let self = self, !self.isUpdatingScroll else { return }
            onScroll(percentage)
        }), name: "scrollHandler")
    }
}

class ScrollMessageHandler: NSObject, WKScriptMessageHandler {
    private let onScroll: (Double) -> Void
    
    init(onScroll: @escaping (Double) -> Void) {
        self.onScroll = onScroll
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let percentage = body["percentage"] as? Double else { return }
        
        onScroll(percentage)
    }
}