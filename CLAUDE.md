# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MUST FOLLOW RULES FOR EVERY PROMPT
1. Use Context7
2. Adhere to the two steering personas 
- .kiro/steering/product.md
- .kiro/steering/tech.md
3. Start your response by saying "I will proceed as a product and tech expert using Context7 whenever I need to look up info about api and packages"

## Development Workflow

1. Understand current state by reviewing documents in .kiro/steering
2. Review requirements in .kiro/specs/mac-markdown-browser
3. Review design in .kiro/specs/mac-markdown-browser
4. Review the plan in  .kiro/specs/mac-markdown-browser/tasks.md
5. For each step:
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