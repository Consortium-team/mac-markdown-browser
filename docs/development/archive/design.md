# Design Document

## Overview

The Mac Markdown File Browser Application is a native macOS application built with SwiftUI that combines efficient file browsing with rich Markdown preview and editing capabilities. The application follows a dual-pane architecture with a directory browser on the left and a content panel on the right that can switch between preview and edit modes.

## Architecture

### High-Level Architecture

The application follows the MVVM (Model-View-ViewModel) pattern with SwiftUI, organized into distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   ContentView   │  │ DirectoryPanel  │  │ PreviewPanel│ │
│  │   (Main UI)     │  │   (Left Pane)   │  │ (Right Pane)│ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ FileSystemVM    │  │ MarkdownVM      │  │ FavoritesVM │ │
│  │ (Navigation)    │  │ (Rendering)     │  │ (Bookmarks) │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ FileService     │  │ MarkdownService │  │ PrefsService│ │
│  │ (File I/O)      │  │ (Parsing)       │  │ (Settings)  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ DirectoryNode   │  │ MarkdownDoc     │  │ UserPrefs   │ │
│  │ (File Tree)     │  │ (Content)       │  │ (Settings)  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

1. **ContentView**: Main application window managing the dual-pane layout
2. **DirectoryPanel**: Left pane handling file system navigation and favorites
3. **PreviewPanel**: Right pane managing content display and editing
4. **ViewModels**: Business logic controllers for each major component
5. **Services**: Utility classes for file operations, Markdown processing, and preferences
6. **Models**: Data structures representing files, directories, and application state

## Components and Interfaces

### 1. Main Application Structure

#### ContentView
```swift
struct ContentView: View {
    @StateObject private var fileSystemVM = FileSystemViewModel()
    @StateObject private var markdownVM = MarkdownViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var splitPosition: CGFloat = 0.3
    
    var body: some View {
        HSplitView {
            DirectoryPanel()
                .frame(minWidth: 300, maxWidth: 500)
            PreviewPanel()
                .frame(minWidth: 400)
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}
```

#### Window Management
- Single window application using WindowGroup
- Persistent window state (position, size, split ratio)
- Minimum size enforcement (1000x700)
- Resizable with proportional pane sizing

### 2. Directory Panel (Left Pane)

#### FavoritesSection
```swift
struct FavoritesSection: View {
    @ObservedObject var favoritesVM: FavoritesViewModel
    
    // Drag-and-drop target for adding favorites
    // Context menu for management (rename, remove, reorder)
    // Keyboard shortcuts (Cmd+1-9)
}
```

#### DirectoryBrowser
```swift
struct DirectoryBrowser: View {
    @ObservedObject var fileSystemVM: FileSystemViewModel
    
    // Tree view with expandable directories
    // File filtering (.md files by default)
    // Search functionality
    // Keyboard navigation
}
```

### 3. Preview Panel (Right Pane)

#### PreviewPanel
```swift
struct PreviewPanel: View {
    @ObservedObject var markdownVM: MarkdownViewModel
    @State private var isEditMode = false
    @State private var editLayout: EditLayout = .fullscreen
    
    var body: some View {
        VStack {
            ToolbarView()
            if isEditMode {
                EditModeView(layout: editLayout)
            } else {
                PreviewModeView()
            }
        }
    }
}

enum EditLayout {
    case fullscreen
    case sideBySide
}
```

#### MarkdownRenderer
- GitHub-compatible styling using CSS
- Syntax highlighting for code blocks
- Table rendering with proper formatting
- Image display with scaling
- LaTeX/MathML support for mathematical expressions

#### MermaidRenderer
```swift
class MermaidRenderer: ObservableObject {
    private let webView = WKWebView()
    
    func renderDiagram(_ mermaidCode: String) -> AnyView {
        // WKWebView integration for Mermaid.js
        // Error handling for invalid syntax
        // Zoom and pan capabilities
        // Fallback to raw code display
    }
}
```

### 4. Editing System

#### MarkdownEditor
```swift
struct MarkdownEditor: View {
    @Binding var content: String
    @State private var hasUnsavedChanges = false
    
    // Syntax highlighting for Markdown
    // Real-time or manual preview updates
    // Save functionality (Cmd+S)
    // Unsaved changes tracking
}
```

#### Edit Mode Layouts
- **Fullscreen**: Editor occupies entire preview panel
- **Side-by-side**: Split preview panel between editor and rendered preview
- **Toggle mechanism**: Cmd+E to switch between preview and edit modes
- **State preservation**: Maintain cursor position and scroll location

## Data Models

### DirectoryNode
```swift
class DirectoryNode: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    @Published var children: [DirectoryNode] = []
    @Published var isExpanded = false
    
    // Lazy loading of child nodes
    // File filtering capabilities
    // Search functionality
}
```

### MarkdownDocument
```swift
class MarkdownDocument: ObservableObject {
    let url: URL
    @Published var content: String = ""
    @Published var renderedHTML: String = ""
    @Published var hasUnsavedChanges = false
    @Published var lastModified: Date
    
    // Content loading and saving
    // Change tracking
    // Markdown parsing and rendering
}
```

### UserPreferences
```swift
class UserPreferences: ObservableObject {
    @Published var favoriteDirectories: [URL] = []
    @Published var showHiddenFiles = false
    @Published var fileFilter: FileFilter = .markdownOnly
    @Published var theme: AppTheme = .system
    @Published var windowState: WindowState
    
    // Persistent storage using UserDefaults
    // Security-scoped bookmarks for directory access
}

enum FileFilter {
    case markdownOnly
    case allFiles
}

enum AppTheme {
    case light
    case dark
    case system
}
```

## File System Integration

### FileSystemService
```swift
class FileSystemService {
    // NSFileManager integration
    // FSEvents for real-time monitoring
    // Security-scoped bookmarks
    // Background file operations
    
    func loadDirectory(_ url: URL) async -> [DirectoryNode]
    func monitorChanges(at url: URL) -> AsyncStream<FileSystemEvent>
    func createBookmark(for url: URL) -> Data?
    func resolveBookmark(_ data: Data) -> URL?
}
```

### Performance Optimizations
- **Lazy Loading**: Load directory contents only when expanded
- **Background Processing**: File operations on background queues
- **Caching**: Intelligent caching of rendered content
- **Memory Management**: Automatic cleanup of unused resources

## Markdown Processing Pipeline

### MarkdownService
```swift
class MarkdownService {
    private let parser: MarkdownParser
    private let mermaidRenderer: MermaidRenderer
    
    func parseMarkdown(_ content: String) async -> ParsedMarkdown
    func renderToHTML(_ markdown: ParsedMarkdown) async -> String
    func extractMermaidBlocks(_ content: String) -> [MermaidBlock]
}
```

### Rendering Pipeline
1. **Parse**: Convert Markdown text to AST using Swift Markdown
2. **Process**: Handle special elements (Mermaid blocks, math expressions)
3. **Render**: Generate HTML with GitHub-compatible styling
4. **Display**: Present in WKWebView with custom CSS

### Mermaid Integration
- **WKWebView**: Sandboxed JavaScript execution for Mermaid.js
- **Error Handling**: Graceful fallback to raw code display
- **Performance**: Async rendering with loading indicators
- **Interactivity**: Zoom and pan for complex diagrams

## Error Handling

### Error Types
```swift
enum AppError: Error, LocalizedError {
    case fileNotFound(URL)
    case permissionDenied(URL)
    case markdownParsingFailed(String)
    case mermaidRenderingFailed(String)
    case bookmarkResolutionFailed
    
    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

### Error Recovery Strategies
- **File Access**: Graceful handling of permission issues
- **Parsing Errors**: Display raw content with error indicators
- **Network Issues**: Timeout handling for network-mounted directories
- **Memory Pressure**: Automatic cache cleanup and resource management

## Testing Strategy

### Unit Testing
- **Models**: Data structure validation and business logic
- **Services**: File operations, Markdown parsing, preferences management
- **ViewModels**: State management and user interaction handling

### Integration Testing
- **File System**: Directory navigation and file loading
- **Markdown Rendering**: End-to-end content processing pipeline
- **Preferences**: Persistent storage and bookmark resolution

### UI Testing
- **Navigation**: Directory browsing and file selection
- **Editing**: Mode switching and content modification
- **Favorites**: Drag-and-drop functionality and keyboard shortcuts

### Performance Testing
- **File Switching**: Sub-100ms response time validation
- **Memory Usage**: Resource consumption monitoring
- **Large Files**: Multi-megabyte Markdown file handling
- **Directory Scanning**: Performance with large directory structures

## Security Considerations

### Sandboxing
- **App Sandbox**: Full macOS sandbox compliance
- **Security-Scoped Bookmarks**: Persistent directory access
- **User-Selected Files**: Proper entitlements for file access

### Web Content Security
- **WKWebView**: Sandboxed JavaScript execution for Mermaid
- **Content Security Policy**: Restrict web content capabilities
- **Local Resource Access**: Controlled access to local files

## Accessibility

### VoiceOver Support
- **Navigation**: Proper accessibility labels for directory tree
- **Content**: Screen reader support for Markdown content
- **Editing**: Accessible text editing experience

### Keyboard Navigation
- **Full Keyboard Access**: Complete functionality without mouse
- **Custom Shortcuts**: Configurable keyboard shortcuts
- **Focus Management**: Logical tab order and focus indicators

## Localization

### Internationalization Support
- **String Externalization**: All user-facing strings in localization files
- **RTL Support**: Right-to-left language compatibility
- **Date/Time Formatting**: Locale-appropriate formatting

## Deployment and Distribution

### Build Configuration
- **Target**: macOS 13.0+ (Ventura and later)
- **Architecture**: Universal binary (Intel + Apple Silicon)
- **Code Signing**: Developer ID for distribution outside App Store

### Distribution Options
- **Direct Distribution**: Notarized DMG for direct download
- **Mac App Store**: Optional App Store distribution
- **Enterprise**: Internal distribution for ConsortiumTeam