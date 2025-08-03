# Current Features

## Overview

This document describes the current state of implemented features in MarkdownBrowser as of the latest development iteration.

**Last Updated: 2025-01-03**

## Feature Status

### ✅ Fully Implemented Features

#### 1. File System Navigation
- Browse directories starting from home directory
- Tree view with expand/collapse functionality
- File type icons and visual indicators
- Real-time file system monitoring with FSEvents
- Security-scoped bookmarks for persistent access
- **Hidden files visibility** (new):
  - Shows hidden files and directories by default
  - Toggle visibility via View menu → "Show Hidden Files"
  - Keyboard shortcut: Cmd+Shift+.
  - Preference persists across app sessions
  - File tree refreshes instantly when toggled

#### 2. Favorites Management ✅
- **VSCode-style favorites section** at top of sidebar
  - Draggable divider to resize favorites area
  - Empty state with helpful message
- **Multiple ways to add favorites**:
  - Right-click any directory → "Add to Favorites"
  - Drag and drop directories into favorites section
- **Favorites features**:
  - Click to navigate instantly to favorited directory
  - Keyboard shortcuts (Cmd+1 through Cmd+9) for quick access
  - Shows shortcut indicator next to each favorite
  - Custom names for favorites (default: directory name)
- **Management options**:
  - Right-click to remove from favorites
  - Right-click to show in Finder
  - Persistent storage across app sessions
- **Visual design**:
  - Consistent with VSCode explorer styling
  - Hover effects for better interactivity
  - Folder icons with accent color

#### 3. Markdown Preview
- Render markdown files with GitHub-flavored CSS
- Syntax support for:
  - Headers (H1-H6)
  - Bold and italic text
  - Links
  - Code blocks
  - Lists (ordered and unordered)
  - Tables
  - Blockquotes
- Dark mode support
- Responsive layout

#### 4. Markdown Editing ✅
- Open markdown files in separate edit windows
- Split-pane interface with editor and preview
- Live preview updates (with 300ms debounce)
- Basic text editing with monospace font
- Proper window management following Apple HIG
- Save functionality with Cmd+S keyboard shortcut
- Auto-save after 2 seconds of inactivity
- Unsaved changes indicators:
  - "— Edited" text in status bar
  - Dot in window close button (macOS standard)
- Undo/Redo support
- Preview in main window updates automatically after save

#### 5. Refresh Button for Preview ✅
- **Refresh button in toolbar** for Markdown and HTML files
  - System icon: "arrow.clockwise"
  - Simple press animation (scales to 90% for 0.1s)
  - No loading states - immediate reactivation
- **Keyboard shortcut**: Cmd+R
- **Functionality**:
  - Reloads current document from disk
  - Invalidates render cache for current document
  - Rate limited to prevent rapid refreshes (500ms minimum interval)
  - Uses existing security-scoped bookmarks
- **Known limitation**: CSV files do not have refresh button (needs separate implementation)

### ⚠️ Partially Implemented Features

#### 1. Mermaid Diagram Support
**Implemented but not rendering:**
- Mermaid block detection in markdown
- HTML generation for mermaid diagrams
- MermaidRenderer service exists
- Preview does not display mermaid diagrams

### 🚧 Features In Progress

#### 1. Synchronized Scrolling
- ScrollSynchronizer service created
- Not integrated into ProperMarkdownEditor
- Would sync scroll position between editor and preview panes

#### 5. HTML Document Support
- Browse and preview HTML files (.html, .htm extensions)
- Distinct file icons:
  - Markdown files: "doc.text" SF Symbol
  - HTML files: "doc.richtext" SF Symbol
- Direct HTML rendering without parsing
- CSS and inline styles are preserved
- JavaScript execution supported by WKWebView
- Unified file type system with FileType enum
- File filtering supports:
  - All files mode
  - Markdown only mode
  - Supported documents mode (Markdown + HTML)

#### 6. CSV File Support ✅
- **Full CSV file handling** with table preview and editing
  - Automatic delimiter detection (comma, tab, semicolon)
  - Syntax highlighting in raw editor view
  - Table preview with GitHub-style CSS
  - Row/column count overlay
  - Virtual scrolling for large files (>100 rows)
- **Security-hardened implementation**:
  - XSS prevention with HTML escaping
  - Content sanitization and Unicode filtering
  - Resource limits (10MB files, 10k chars per cell)
  - JavaScript disabled in preview
- **Performance optimized**:
  - Streaming CSV parser
  - Parse time <100ms for normal files
  - Render time <10ms with virtual scrolling
  - Memory-efficient for large datasets
- **Integration with file browser**:
  - CSV files show "tablecells" SF Symbol
  - Click to preview in split-pane view
  - Edit mode for raw CSV editing
  - Auto-save and change tracking

#### 7. Refresh Button Functionality ✅
- **Fixed refresh behavior** in file explorer
  - Refresh button in Explorer header
  - Refreshes only the selected directory (no parent traversal)
  - Visual feedback with progress spinner
  - Maintains folder expansion state
  - Updates file list to show new/deleted files
  - Completes in <500ms for normal directories
- **User-verified functionality**: "I can verify that Phase 3, which is the refresh button, is working as expected."

#### 8. Refresh Button for Markdown/HTML Preview ✅
- **Manual refresh functionality** for preview pane
  - Refresh button in FilePreviewView toolbar
  - System "arrow.clockwise" icon with press animation
  - Refreshes current Markdown/HTML document from disk
  - Uses existing security-scoped bookmarks (no new entitlements)
- **Rate limiting implementation**:
  - 500ms throttle between refresh attempts
  - Prevents DoS from rapid clicking
  - canRefresh() method enforces minimum interval
- **Implementation details**:
  - RefreshButton component with simple press animation
  - Uses existing reloadFromDisk() and invalidateCache() methods
  - No loading states or progress indicators (simple implementation)
  - Button placement: after file info, before Export/Edit buttons
- **Known limitation**: CSV files do not have refresh button (requires separate change request)

### ❌ Not Implemented Features

#### 1. Search Functionality
- No file search
- No content search within files
- No search in directory tree

#### 2. Advanced Editing Features
- No syntax highlighting in editor
- No markdown formatting shortcuts
- No auto-completion
- No find/replace within editor

#### 3. Export Options
- No PDF export
- No HTML export
- No print functionality

#### 4. Theme Customization
- No editor theme options
- No preview theme customization
- No font size adjustment

## Known Issues

### Minor Issues

1. **Mermaid Diagrams Not Rendering**
   - **Description**: Mermaid code blocks are detected but not rendered as diagrams in the edit preview pane
   - **Impact**: Medium - Feature exists but is non-functional

2. **No Scroll Synchronization**
   - **Description**: Editor and preview panes scroll independently
   - **Impact**: Low - Usability issue for long documents

## Usage Instructions

### Running the Application

1. **For Normal Use** (with working keyboard input):
   ```bash
   ./run-app.sh
   ```

2. **For Development** (with console output):
   ```bash
   ./run.sh
   ```

### Current Workflow

1. **Browse Files**: Navigate through directories in the VSCode-style explorer
2. **Manage Favorites**:
   - Right-click any directory → "Add to Favorites"
   - Or drag directories to the favorites section
   - Use Cmd+1 through Cmd+9 to quickly jump to favorites
3. **Preview Markdown**: Click on any .md file to see rendered preview
4. **Edit Markdown**: 
   - Click "Edit" button in preview
   - Make changes in the left editor pane
   - See live preview updates on the right
   - Save with Cmd+S or auto-save after 2 seconds

### Keyboard Shortcuts

- **Cmd+1 to Cmd+9**: Jump to favorited directories
- **ESC**: Close edit window
- **Cmd+S**: Save markdown edits
- **Cmd+Shift+.**: Toggle hidden files visibility

## Development Status

The application has evolved to use a VSCode-style explorer interface with robust favorites management. Core functionality is stable with markdown viewing, editing, and file management features working well. The app provides a familiar interface for developers while maintaining native macOS integration.