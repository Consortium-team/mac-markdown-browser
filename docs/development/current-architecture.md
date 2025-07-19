# Current Architecture

## Overview

MarkdownBrowser is a macOS application built with SwiftUI that provides a dual-pane interface for browsing and editing Markdown files. The application follows MVVM architecture patterns and uses a combination of SwiftUI and AppKit components.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        App[MarkdownBrowserApp]
        ContentView[ContentView]
    end
    
    subgraph "View Layer"
        DirectoryPanel[DirectoryPanel]
        FilePreviewView[FilePreviewView]
        ProperMarkdownEditor[ProperMarkdownEditor]
        EditWindowManager[EditWindowManager]
        MarkdownPreviewView[MarkdownPreviewView]
    end
    
    subgraph "ViewModels"
        FileSystemVM[FileSystemViewModel]
        FavoritesVM[FavoritesViewModel]
        MarkdownVM[MarkdownViewModel]
        EditorVM[MarkdownEditorViewModel]
    end
    
    subgraph "Services"
        FileSystemService[FileSystemService]
        MarkdownService[MarkdownService]
        MermaidRenderer[MermaidRenderer]
        ScrollSync[ScrollSynchronizer]
    end
    
    subgraph "Models"
        DirectoryNode[DirectoryNode]
        MarkdownDocument[MarkdownDocument]
        UserPreferences[UserPreferences]
    end
    
    App --> ContentView
    ContentView --> DirectoryPanel
    ContentView --> FilePreviewView
    FilePreviewView --> MarkdownPreviewView
    FilePreviewView --> EditWindowManager
    EditWindowManager --> ProperMarkdownEditor
    
    DirectoryPanel --> FileSystemVM
    DirectoryPanel --> FavoritesVM
    FilePreviewView --> MarkdownVM
    ProperMarkdownEditor --> EditorVM
    
    FileSystemVM --> FileSystemService
    FileSystemVM --> DirectoryNode
    FavoritesVM --> UserPreferences
    MarkdownVM --> MarkdownService
    MarkdownVM --> MarkdownDocument
    EditorVM --> MarkdownService
```

## Component Details

### Views

```mermaid
classDiagram
    class ContentView {
        +FileSystemViewModel fileSystemVM
        +FavoritesViewModel favoritesVM
        +FocusedPane focusedPane
        +body: View
    }
    
    class DirectoryPanel {
        +FileSystemViewModel fileSystemVM
        +FavoritesViewModel favoritesVM
        +body: View
    }
    
    class FilePreviewView {
        +URL fileURL
        +MarkdownViewModel viewModel
        +showingEditView: Bool
        +body: View
    }
    
    class ProperMarkdownEditor {
        +URL fileURL
        +MarkdownEditorViewModel viewModel
        +Environment dismiss
        +CGFloat splitRatio
        +body: View
    }
    
    ContentView --> DirectoryPanel
    ContentView --> FilePreviewView
    FilePreviewView --> EditWindowManager
    EditWindowManager --> ProperMarkdownEditor
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
    }
    
    class FileSystemViewModel {
        +DirectoryNode? rootNode
        +DirectoryNode? selectedNode
        +navigateToDirectory(URL)
        +refreshDirectory()
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
    }
    
    class MermaidRenderer {
        +renderMermaidDiagram(String) String
        -generateMermaidHTML(String) String
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

The app implements Cmd+S using SwiftUI's FocusedValue system:
- `SaveActionKey`: Custom FocusedValueKey for save action
- Main app adds File > Save menu item
- ProperMarkdownEditor provides save action via `.focusedSceneValue`

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

## Technology Stack

- **UI Framework**: SwiftUI
- **Text Editing**: NSTextView (AppKit)
- **Web Preview**: WKWebView (WebKit)
- **Markdown Parsing**: swift-markdown (Apple)
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

## Key Architectural Decisions

1. **Separate Windows for Editing**: Edit mode opens in a new window managed by `EditWindowManager`
2. **MVVM Pattern**: Clear separation between Views and ViewModels
3. **Debounced Preview Updates**: 300ms delay prevents excessive rendering
4. **App Bundle for Keyboard Focus**: Proper macOS app bundle ensures keyboard input works correctly
5. **NSViewRepresentable for Text Editing**: Wraps NSTextView for better text editing capabilities than SwiftUI's TextEditor