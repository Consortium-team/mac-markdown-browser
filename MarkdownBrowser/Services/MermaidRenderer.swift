import Foundation
import WebKit
import SwiftUI

/// Simplified MermaidRenderer that's no longer needed for actual rendering
/// (kept for backward compatibility and future server-side rendering if needed)
@MainActor
class MermaidRenderer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRendering = false
    @Published var renderError: Error?
    
    // MARK: - Public Methods
    
    /// This method is no longer needed as rendering happens in the browser
    /// Kept for backward compatibility
    func renderMermaidInHTML(_ html: String, mermaidBlocks: [MermaidBlock]) async throws -> String {
        // Simply return the HTML as-is since MermaidHTMLGenerator handles everything
        return html
    }
}

// MARK: - MermaidError

enum MermaidError: LocalizedError {
    case webViewNotInitialized
    case renderTimeout
    case renderFailed(String)
    case javascriptError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .webViewNotInitialized:
            return "Mermaid renderer is not initialized"
        case .renderTimeout:
            return "Mermaid diagram rendering timed out"
        case .renderFailed(let message):
            return "Mermaid rendering failed: \(message)"
        case .javascriptError(let message):
            return "JavaScript error: \(message)"
        case .unknownError:
            return "An unknown error occurred during Mermaid rendering"
        }
    }
}