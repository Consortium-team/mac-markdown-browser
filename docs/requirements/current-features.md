# Current Features

## Overview

This document describes the current state of implemented features in MarkdownBrowser as of the latest development iteration.

## Feature Status

### ✅ Fully Implemented Features

#### 1. File System Navigation
- Browse directories starting from home directory
- Tree view with expand/collapse functionality
- File type icons and visual indicators
- Real-time file system monitoring with FSEvents
- Security-scoped bookmarks for persistent access

#### 2. Favorites Management
- Add directories to favorites
- Remove favorites
- Keyboard shortcuts (Cmd+1 through Cmd+9)
- Persistent storage of favorites
- Visual indication of favorited items

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

1. **Browse Files**: Navigate through directories in the left panel
2. **Preview Markdown**: Click on any .md file to see rendered preview
3. **Edit Markdown**: 
   - Click "Edit" button in preview
   - Make changes in the left editor pane
   - See live preview updates on the right
   - ⚠️ **Do not attempt to save** - will crash

### Keyboard Shortcuts

- **Cmd+1 to Cmd+9**: Jump to favorited directories
- **ESC**: Close edit window
- **Cmd+S**: Save (⚠️ **Currently crashes app**)

## Development Status

The application is in active development with core functionality implemented but critical issues preventing full usability. The save crash issue must be resolved before the editing feature can be considered complete.