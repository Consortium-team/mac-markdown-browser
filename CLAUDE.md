# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Security-First Development

MDBrowser has known security vulnerabilities that must be considered during development:
- XSS risks in Markdown/HTML rendering
- Overly permissive entitlements
- Resource leak potential

Always run `/security-check` before implementing new features that:
- Handle file system access
- Render user content
- Modify entitlements
- Add external dependencies

## MDBrowser Development Workflow

### Core Activities & Slash Commands

1. **Capture Change Request**: `/change-request <feature description>`
   - Creates formal change request document in docs/feedback/
   - Uses Product Manager persona from docs/personas/product-manager.md
   - Includes security analysis from cybersecurity specialist

2. **Create Feature Branch**: `/feature-branch <change-request-name>`
   - Creates and pushes Git feature branch
   - Naming convention: feature/[change-request-name]

3. **Baseline Understanding**: `/baseline`
   - Reviews current features and architecture
   - Provides context for informed decisions
   - Use `/baseline --security` for full security posture review

4. **Design & Plan**: `/design-plan <change-request-name>`
   - Creates software design document in docs/development/
   - Creates implementation plan in docs/planning/
   - Uses Product, Tech, and Cybersecurity personas
   - Includes threat modeling for macOS sandbox

5. **Implementation**: `/implement <change-request-name>`
   - Follows the plan, checking off tasks
   - Writes tests for each major task
   - Includes security verification at checkpoints
   - Uses Context7 and Web Search as needed

6. **Capture Learnings**: `/capture-learnings <change-request-name>`
   - Updates current-features.md and current-architecture.md
   - Updates security assessment with implementation findings
   - Archives completed documents
   - Creates PR when complete

### Additional Development Commands

7. **Security Assessment**: `/security-check [options]`
   - Performs comprehensive security analysis
   - Uses cybersecurity specialist persona
   - Options: `--focus webview`, `--focus filesystem`, `--sandbox`, `--quick`
   - Updates docs/security/current-security-assessment.md
   - Run before new features and after major changes

8. **Save Development State**: `/checkpoint "<description>"`
   - Creates a named checkpoint of current work
   - Useful before experiments or refactoring
   - Preserves code and documentation state

9. **Restore Previous State**: `/restore`
   - Lists available checkpoints
   - Allows restoration to previous state
   - Helps recover from experimental changes

### Quick Reference
- Always use Context7 for API/library documentation
- Use Web Search for implementation difficulties
- Follow Apple HIG for all UI decisions
- Write tests before moving to next major task
- Update documentation as you complete features
- Run security checks before implementing file/rendering features
- Use checkpoints before major refactoring

## Git Configuration

When making commits, use co-author: Sonjaya Tandon, sonjayatandon@gmail.com

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
Core models and services are implemented. The application features a fully functional CSV preview system, Markdown editing, favorites management, and hidden files visibility. See `docs/planning/` for current implementation plans and `docs/requirements/current-features.md` for detailed feature status.

## Important Considerations

### Sandboxing
The app is sandboxed with these entitlements:
- User-selected file read/write
- App-scoped bookmarks
- Network client (SHOULD BE REMOVED - see security assessment)
- Downloads folder access
- Executable permission (SHOULD BE REMOVED - see security assessment)

Always test file access with security-scoped bookmarks when implementing new features.

### Security Considerations
- The app currently has XSS vulnerabilities in Markdown preview
- Resource cleanup needs improvement to prevent kernel resource exhaustion
- Entitlements should be minimized (remove network.client and executable)
- See docs/security/current-security-assessment.md for full details

### Performance Targets
- File switching: < 100ms
- Mermaid diagram rendering: < 500ms
- Use lazy loading for large directories

### File System Monitoring
FileSystemService uses FSEvents. When implementing UI, ensure proper cleanup of monitors to prevent resource leaks.

## Cybersecurity Specialist Persona

The project includes a dedicated cybersecurity specialist persona (docs/personas/cybersecurity-specialist.md) that focuses on:
- macOS application security and sandboxing
- WebKit/WKWebView vulnerabilities
- File system access security
- Path traversal prevention
- Resource management
- Content Security Policy implementation

This persona is automatically engaged during:
- `/change-request` - For security analysis of new features
- `/design-plan` - For threat modeling
- `/implement` - For security verification
- `/security-check` - For comprehensive assessments
- `/capture-learnings` - For documenting security improvements