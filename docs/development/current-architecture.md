# Current Architecture

## Overview

MarkdownBrowser is a macOS application built with SwiftUI that provides a dual-pane interface for browsing and editing Markdown files. The application follows MVVM architecture patterns and uses a combination of SwiftUI and AppKit components.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        App[MarkdownBrowserApp]
        VSCodeExplorer[VSCodeStyleExplorer]
    end
    
    subgraph "View Layer"
        FileTreeView[FileTreeView]
        FavoriteItemView[FavoriteItemView]
        FilePreviewView[FilePreviewView]
        ProperMarkdownEditor[ProperMarkdownEditor]
        EditWindowManager[EditWindowManager]
        MarkdownPreviewView[MarkdownPreviewView]
        CSVSplitView[CSVSplitView]
        CSVEditorView[CSVEditorView]
        CSVPreviewView[CSVPreviewView]
    end
    
    subgraph "ViewModels"
        ExplorerModel[VSCodeExplorerModel]
        FavoritesVM[FavoritesViewModel]
        MarkdownVM[MarkdownViewModel]
        EditorVM[MarkdownEditorViewModel]
        CSVVM[CSVViewModel]
    end
    
    subgraph "Services"
        FileSystemService[FileSystemService]
        MarkdownService[MarkdownService]
        MermaidRenderer[MermaidRenderer]
        ScrollSync[ScrollSynchronizer]
        CSVParser[CSVParser]
        PerformanceMonitor[PerformanceMonitor]
    end
    
    subgraph "Models"
        FileNode[FileNode]
        FavoriteDirectory[FavoriteDirectory]
        MarkdownDocument[MarkdownDocument]
        UserPreferences[UserPreferences]
        CSVDocument[CSVDocument]
    end
    
    App --> VSCodeExplorer
    VSCodeExplorer --> FileTreeView
    VSCodeExplorer --> FavoriteItemView
    VSCodeExplorer --> FilePreviewView
    FilePreviewView --> MarkdownPreviewView
    FilePreviewView --> CSVSplitView
    CSVSplitView --> CSVEditorView
    CSVSplitView --> CSVPreviewView
    FilePreviewView --> EditWindowManager
    EditWindowManager --> ProperMarkdownEditor
    
    VSCodeExplorer --> ExplorerModel
    VSCodeExplorer --> FavoritesVM
    FileTreeView --> FavoritesVM
    FilePreviewView --> MarkdownVM
    ProperMarkdownEditor --> EditorVM
    CSVSplitView --> CSVVM
    
    ExplorerModel --> FileNode
    FavoritesVM --> UserPreferences
    FavoritesVM --> FavoriteDirectory
    MarkdownVM --> MarkdownService
    MarkdownVM --> MarkdownDocument
    EditorVM --> MarkdownService
    CSVVM --> CSVParser
    CSVVM --> CSVDocument
    CSVVM --> PerformanceMonitor
```

## Component Details

### Views

```mermaid
classDiagram
    class VSCodeStyleExplorer {
        +VSCodeExplorerModel explorerModel
        +FavoritesViewModel favoritesVM
        +FileNode selectedFile
        +CGFloat dividerPosition
        +body: View
    }
    
    class FileTreeView {
        +FileNode node
        +FileNode selectedFile
        +Set~URL~ expandedNodes
        +VSCodeExplorerModel explorerModel
        +FavoritesViewModel favoritesVM
        +body: View
    }
    
    class FavoriteItemView {
        +FavoriteDirectory favorite
        +FavoritesViewModel favoritesVM
        +VSCodeExplorerModel explorerModel
        +body: View
    }
    
    class FilePreviewView {
        +URL fileURL
        +MarkdownViewModel viewModel
        +showingEditView: Bool
        +body: View
    }
    
    VSCodeStyleExplorer --> FileTreeView
    VSCodeStyleExplorer --> FavoriteItemView
    VSCodeStyleExplorer --> FilePreviewView
    FilePreviewView --> EditWindowManager
```

### ViewModels

```mermaid
classDiagram
    class MarkdownEditorViewModel {
        +String markdownText
        +String htmlContent
        +Bool hasUnsavedChanges
        +Bool isSaving
        -String originalText
        -Timer autoSaveTimer
        -MarkdownService markdownService
        +updatePreview(markdown: String)
        +loadFile(from: URL)
        +saveFile()
        +scheduleAutoSave()
    }
    
    class MarkdownViewModel {
        +MarkdownDocument? currentDocument
        +String renderedHTML
        +Bool hasUnsavedChanges
        +Error? renderError
        +loadDocument(at: URL)
        +updateContent(String)
        +saveCurrentDocument()
        +renderDocument(MarkdownDocument)
        -detectsHTMLFiles()
    }
    
    class VSCodeExplorerModel {
        +FileNode? rootNode
        +Set~URL~ expandedNodes
        +Bool isRefreshing
        +openFolder()
        +refreshRoot()
    }
    
    class FavoritesViewModel {
        +Array~FavoriteDirectory~ favorites
        +FavoriteDirectory? selectedFavorite
        +Bool isDraggingOverFavorites
        +addFavorite(URL, String?)
        +removeFavorite(FavoriteDirectory)
        +navigateToFavoriteByShortcut(Int)
        +handleDrop(Array~URL~)
    }
```

### Services

```mermaid
classDiagram
    class MarkdownService {
        -String githubCSS
        -MermaidHTMLGenerator mermaidGenerator
        +parseMarkdown(String) ParsedMarkdown
        +renderToHTML(Document) String
    }
    
    class FileSystemService {
        +BookmarkManager bookmarkManager
        +loadDirectory(URL) DirectoryNode
        +startMonitoring(URL)
        +stopMonitoring(URL)
        -enumerationOptions: Based on UserPreferences.showHiddenFiles
    }
    
    class MermaidRenderer {
        +renderMermaidDiagram(String) String
        -generateMermaidHTML(String) String
    }
    
    class CSVParser {
        +parseCSV(String, CSVDelimiter) CSVData
        +detectDelimiter(String) CSVDelimiter
        -handleQuotedValues(String) String
        -sanitizeCell(String) String
    }
    
    class PerformanceMonitor {
        +measureBlock(String, () -> T) T
        +logMetrics()
        -trackMemoryUsage()
        -trackExecutionTime()
    }
    
    MarkdownService --> MermaidHTMLGenerator
    MarkdownService --> MermaidRenderer
```

## Data Flow

### Edit Mode Flow

```mermaid
sequenceDiagram
    participant User
    participant FilePreviewView
    participant EditWindowManager
    participant ProperMarkdownEditor
    participant EditorViewModel
    participant MarkdownService
    
    User->>FilePreviewView: Click Edit Button
    FilePreviewView->>EditWindowManager: openEditWindow(fileURL)
    EditWindowManager->>ProperMarkdownEditor: Create new window
    ProperMarkdownEditor->>EditorViewModel: loadFile(url)
    EditorViewModel->>EditorViewModel: Load file content
    
    User->>ProperMarkdownEditor: Type in editor
    ProperMarkdownEditor->>EditorViewModel: Update markdownText
    EditorViewModel->>EditorViewModel: Debounce (300ms)
    EditorViewModel->>MarkdownService: parseMarkdown()
    MarkdownService->>EditorViewModel: Return HTML
    EditorViewModel->>ProperMarkdownEditor: Update preview
```

### Window Management

```mermaid
classDiagram
    class EditWindowManager {
        -static EditWindowManager shared
        -Dictionary~URL,NSWindow~ windows
        +openEditWindow(URL)
        +cleanupWindow(URL)
        +windowWillClose(Notification)
    }
    
    EditWindowManager --|> NSWindowDelegate
```

### Notification System

The app uses NotificationCenter for cross-component communication:
- `markdownFileSaved`: Posted when a file is saved in the editor
  - Contains URL in userInfo dictionary
  - FilePreviewView listens to reload content

### Keyboard Shortcuts

The app implements several keyboard shortcuts:
- **Cmd+S**: Save using SwiftUI's FocusedValue system
  - `SaveActionKey`: Custom FocusedValueKey for save action
  - Main app adds File > Save menu item
  - ProperMarkdownEditor provides save action via `.focusedSceneValue`
- **Cmd+1 to Cmd+9**: Quick navigation to favorited directories
  - Implemented using `.keyboardShortcut` modifier
  - FavoritesViewModel manages shortcut assignments
- **Cmd+Shift+.**: Toggle hidden files visibility
  - Added to View menu in MarkdownBrowserApp
  - Toggles UserPreferences.showHiddenFiles
  - Triggers automatic file tree refresh

### Known Issues

```mermaid
graph TD
    subgraph "Current Issues"
        ScrollSync[Scroll Sync Not Implemented]
        MermaidPreview[Mermaid Not Rendering in Preview]
    end
    
    subgraph "Working Features"
        FileNavigation[File Navigation ✓]
        MarkdownEdit[Markdown Editing ✓]
        LivePreview[Live Preview ✓]
        Favorites[Favorites Management ✓]
        SaveFunction[Save with Cmd+S ✓]
        AutoSave[Auto-save after 2s ✓]
        UnsavedIndicator[Unsaved Changes Indicator ✓]
    end
```

## File Type Support

The application now supports multiple document types through a unified type system:

```mermaid
classDiagram
    class FileType {
        <<enumeration>>
        +markdown
        +html
        +directory
        +other
        +init(from: URL)
        +iconName: String
        +isSupported: Bool
    }
    
    class URL {
        +fileType: FileType
        +isMarkdownFile: Bool
        +isHTMLFile: Bool
        +isSupportedDocument: Bool
    }
    
    FileType --> URL : extends
```

### Supported Document Types
- **Markdown**: `.md`, `.markdown` - Parsed and rendered with GitHub-style CSS
- **HTML**: `.html`, `.htm` - Rendered directly in WKWebView
- **CSV**: `.csv`, `.tsv` - Parsed and displayed as tables with syntax highlighting

## Technology Stack

- **UI Framework**: SwiftUI
- **Text Editing**: NSTextView (AppKit)
- **Web Preview**: WKWebView (WebKit)
- **Markdown Parsing**: swift-markdown (Apple)
- **HTML Rendering**: Direct WKWebView display
- **Reactive Programming**: Combine
- **Concurrency**: Swift async/await
- **File System**: FSEvents API

## Build System

```mermaid
graph LR
    subgraph "Build Scripts"
        RunApp[run-app.sh]
        CreateBundle[create-app-bundle.sh]
        RunDev[run.sh]
    end
    
    subgraph "Build Output"
        Debug[.build/debug/MarkdownBrowser]
        Release[.build/release/MarkdownBrowser]
        AppBundle[MarkdownBrowser.app]
    end
    
    RunApp --> CreateBundle
    CreateBundle --> Release
    CreateBundle --> AppBundle
    RunDev --> Debug
```

## App Bundle Structure

```
MarkdownBrowser.app/
├── Contents/
│   ├── MacOS/
│   │   └── MarkdownBrowser (executable)
│   ├── Resources/
│   └── Info.plist
```

## VSCode-Style Explorer

The application uses a VSCode-inspired file explorer interface:

```mermaid
graph TD
    subgraph "Explorer Layout"
        Favorites[Favorites Section]
        Divider[Draggable Divider]
        Explorer[File Explorer]
    end
    
    subgraph "Favorites Features"
        DragDrop[Drag & Drop Support]
        ContextMenu[Context Menu - Add to Favorites]
        Shortcuts[Keyboard Shortcuts Cmd+1-9]
        Persistence[UserPreferences Storage]
    end
    
    Favorites --> DragDrop
    Favorites --> Shortcuts
    Favorites --> Persistence
    Explorer --> ContextMenu
```

### Favorites System Architecture

```mermaid
classDiagram
    class FavoriteDirectory {
        +UUID id
        +String name
        +URL url
        +Data bookmarkData
        +Int? keyboardShortcut
        +String displayName
    }
    
    class FavoritesViewModel {
        +addFavorite(URL, name?)
        +removeFavorite(FavoriteDirectory)
        +navigateToFavoriteByShortcut(Int)
        +handleDrop([URL])
        +resolveFavoriteURL(FavoriteDirectory)
    }
    
    class UserPreferences {
        +favoriteDirectories: [FavoriteDirectory]
        +showHiddenFiles: Bool = true
        +addFavoriteDirectory(URL, name?)
        +removeFavoriteDirectory(FavoriteDirectory)
        -assignNextAvailableShortcut()
        +loadFileFiltering()
        +resetToDefaults()
    }
    
    FavoritesViewModel --> UserPreferences
    FavoritesViewModel --> FavoriteDirectory
    UserPreferences --> FavoriteDirectory
```

## Key Architectural Decisions

1. **VSCode-Style Interface**: Familiar developer interface with favorites section
2. **Separate Windows for Editing**: Edit mode opens in a new window managed by `EditWindowManager`
3. **MVVM Pattern**: Clear separation between Views and ViewModels
4. **Debounced Preview Updates**: 300ms delay prevents excessive rendering
5. **App Bundle for Keyboard Focus**: Proper macOS app bundle ensures keyboard input works correctly
6. **NSViewRepresentable for Text Editing**: Wraps NSTextView for better text editing capabilities than SwiftUI's TextEditor
7. **Security-Scoped Bookmarks**: Favorites use bookmarks for persistent access in sandboxed environment
8. **Dynamic File Enumeration**: FileManager enumeration options controlled by UserPreferences.showHiddenFiles
   - All file loading methods respect the preference
   - Automatic tree refresh on preference change via @ObservedObject