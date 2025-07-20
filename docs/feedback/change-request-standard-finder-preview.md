# Change Request: Standard macOS Finder with Preview Pane

## Executive Summary
Create a macOS Markdown browser that uses the **exact standard macOS file browser** (as seen in every Mac app's File→Open dialog) with an added preview pane for rendering Markdown and HTML files.

## Core Requirement
**The file browser MUST be the standard macOS file picker that every Mac application uses - NOT a custom implementation.**

## Problem Statement
Current implementation attempts have created custom file browsers that don't match the standard macOS experience. Users expect:
- The exact same file browser they see in EVERY Mac application
- The same look, feel, and functionality as Finder
- Zero learning curve because it's the standard interface

## Proposed Solution

### 1. Use Standard macOS File Browser Components
- Implement using the ACTUAL macOS file browser that appears in File→Open dialogs
- This is the same component every Mac app uses (NSOpenPanel, NSBrowser, or equivalent)
- Must include ALL standard features:
  - Sidebar with Favorites, Recents, iCloud Drive, etc.
  - Column view with file details (Date Modified, Size, Kind)
  - Standard navigation controls
  - Standard search functionality
  - Standard drag and drop
  - Standard keyboard shortcuts

### 2. Add Preview Pane
- Add a preview pane to the right of the standard file browser
- Preview pane renders:
  - Markdown files with full formatting
  - HTML files with styles
  - Mermaid diagrams within Markdown files
- Preview updates instantly when selecting different files

### 3. File Management Features
- **Drag and Drop**: Use the standard macOS drag/drop that's built into the file browser
- **PDF Export**: Export rendered Markdown/HTML as PDF to Downloads folder

## Technical Approach

### Best Practices Research
- Study how apps like Path Finder, ForkLift, and similar extend Finder
- Use standard Apple APIs, not custom implementations
- Follow Apple Human Interface Guidelines exactly

### Implementation Strategy
1. Research NSOpenPanel persistent mode or similar APIs
2. Embed standard file browser in application window
3. Add preview pane using split view
4. Integrate existing markdown rendering engine

## What This Is NOT
- NOT a custom tree view
- NOT a reimplementation of Finder
- NOT a unique file browser interface
- NOT anything that looks different from standard macOS

## Success Criteria
1. File browser looks EXACTLY like macOS Finder/Open dialog
2. File browser functions EXACTLY like macOS Finder/Open dialog
3. Preview pane successfully renders Markdown, HTML, and Mermaid
4. Zero learning curve for Mac users

## Reference Images
When complete, the file browser portion should be indistinguishable from:
- The dialog shown when selecting File→Open in any Mac app
- The column view in Finder
- The standard macOS file picker used universally

## Priority
**CRITICAL** - This is the fundamental requirement. Without using the standard macOS file browser, the application fails to meet user expectations.