# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MDBrowser Development Workflow

### Core Activities & Slash Commands

1. **Capture Change Request**: `/change-request <feature description>`
   - Creates formal change request document in docs/feedback/
   - Uses Product Manager persona from .kiro/steering/product.md

2. **Create Feature Branch**: `/feature-branch <change-request-name>`
   - Creates and pushes Git feature branch
   - Naming convention: feature/[change-request-name]

3. **Baseline Understanding**: `/baseline`
   - Reviews current features and architecture
   - Provides context for informed decisions

4. **Design & Plan**: `/design-plan <change-request-name>`
   - Creates software design document in docs/development/
   - Creates implementation plan in docs/planning/
   - Uses both Product and Tech personas

5. **Implementation**: `/implement <change-request-name>`
   - Follows the plan, checking off tasks
   - Writes tests for each major task
   - Uses Context7 and Web Search as needed

6. **Capture Learnings**: `/capture-learnings <change-request-name>`
   - Updates current-features.md and current-architecture.md
   - Archives completed documents
   - Creates PR when complete

### Quick Reference
- Always use Context7 for API/library documentation
- Use Web Search for implementation difficulties
- Follow Apple HIG for all UI decisions
- Write tests before moving to next major task
- Update documentation as you complete features

## Development Workflow

1. Understand current state by reviewing documents in:
- docs/requirements/current-features.md
- docs/development/current-architecture.md
2. Review requirements in .kiro/specs/mac-markdown-browser
3. Review the plan in  .kiro/specs/mac-markdown-browser/tasks.md
4. For each step:
- Use the mcp server Context7 when you need information about an api or package
- Implement the step, check complete in tasks.md when working for each sub-step (2.1, 2.2, etc)
- After each major step is complete (1,2,3, etc.), launch the app and way for human review feedback
- If human accepts, check the major step complete, commit that step in git and push, and then wait for next instruction.  The co-author should be me: Sonjaya Tandon, sonjayatandon@gmail.com

## Build and Development Commands

### Building and Running
```bash
# Using Swift Package Manager
swift build                    # Build debug version
swift build -c release        # Build release version  
swift run                     # Run the application

# Using Xcode
xcodebuild -scheme MarkdownBrowser    # Build via command line
open MarkdownBrowser.xcodeproj        # Open in Xcode
# Run in Xcode: Cmd+R
```

### Testing
```bash
swift test                           # Run all tests
swift test --filter DirectoryNode    # Run specific test class
```

### Linting and Type Checking
The project uses Swift's built-in type checking. Ensure clean compilation:
```bash
swift build --warnings-as-errors     # Treat warnings as errors
```

## Architecture Overview

This is a macOS Markdown browser application built with SwiftUI, following MVVM architecture with these key components:

### Core Models (MarkdownBrowser/Models/)
- **DirectoryNode**: File system tree representation with lazy loading and search
- **MarkdownDocument**: Document handling with change tracking and external file monitoring
- **UserPreferences**: Settings management including favorites, themes, and window state

### Services (MarkdownBrowser/Services/)
- **FileSystemService**: File operations with FSEvents monitoring and security-scoped bookmarks

### Planned UI Structure
- **Dual-pane interface**: Directory browser (left) and Markdown preview (right)
- **Favorites section**: Quick access with Cmd+1-9 shortcuts
- **Preview with Mermaid support**: WKWebView-based rendering

### Key Architectural Decisions
1. **Security-scoped bookmarks** for persistent directory access in sandboxed environment
2. **FSEvents** for real-time file system monitoring
3. **swift-markdown** for parsing, with planned HTML generation pipeline
4. **WKWebView** for preview rendering with Mermaid.js integration

### Development Status
Currently implementing core models and services. UI views are placeholders. See `.kiro/specs/mac-markdown-browser/tasks.md` for detailed implementation plan with requirement mappings.

## Important Considerations

### Sandboxing
The app is sandboxed with these entitlements:
- User-selected file read/write
- App-scoped bookmarks
- Network client
- Downloads folder access

Always test file access with security-scoped bookmarks when implementing new features.

### Performance Targets
- File switching: < 100ms
- Mermaid diagram rendering: < 500ms
- Use lazy loading for large directories

### File System Monitoring
FileSystemService uses FSEvents. When implementing UI, ensure proper cleanup of monitors to prevent resource leaks.