# MDBrowser - macOS Markdown Browser

A native macOS desktop application that combines dual-pane file browsing with rich Markdown preview capabilities, featuring Mermaid diagram support and configurable favorites.

## Overview

MDBrowser is designed for technical consultants, developers, and documentation specialists who work with Markdown-heavy directory structures. It provides a seamless experience for navigating and previewing Markdown files with advanced features like syntax highlighting, Mermaid diagram rendering, and quick access shortcuts.

### Key Features

- **Dual-pane interface**: File browser on the left, rich Markdown preview on the right
- **Rich Markdown rendering**: GitHub-compatible styling with syntax highlighting
- **Mermaid diagram support**: Inline rendering of flowcharts, sequence diagrams, and more
- **Configurable favorites**: Quick access with Cmd+1-9 keyboard shortcuts
- **Native macOS performance**: Built with SwiftUI for optimal system integration
- **Real-time file monitoring**: Automatic updates when files change externally

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for development)
- Swift 5.9+

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/your-org/MDBrowser.git
cd MDBrowser

# Build using Swift Package Manager
swift build -c release

# Or open in Xcode
open MarkdownBrowser.xcodeproj
```

## Development

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run the application
swift run
```

### Testing

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter DirectoryNode
```

## Development Workflow

This project uses Claude Code with custom slash commands for a structured development workflow. The workflow follows six core activities:

### 1. Capture Change Requests

When you have a new feature idea or change request:

```bash
/change-request Add support for exporting Markdown to PDF with custom styling
```

This command:
- Uses the Product Manager persona to analyze the request
- Creates a formal change request document in `docs/feedback/`
- Evaluates user impact and strategic alignment
- Provides a recommendation with clear rationale

### 2. Create Feature Branch

After the change request is approved:

```bash
/feature-branch pdf-export
```

This command:
- Creates a new Git branch named `feature/pdf-export`
- Pushes the branch upstream for tracking
- Ensures you're starting from an up-to-date main branch

### 3. Baseline Understanding

Before starting implementation:

```bash
/baseline
```

This command:
- Reviews current features from `docs/requirements/current-features.md`
- Analyzes the architecture from `docs/development/current-architecture.md`
- Provides context for making informed implementation decisions

### 4. Design and Plan

Create technical design and implementation plan:

```bash
/design-plan pdf-export
```

This command:
- Uses Context7 to research relevant APIs and libraries
- Creates a software design document in `docs/development/`
- Generates an implementation plan in `docs/planning/`
- Breaks down work into specific, testable tasks

### 5. Implementation

Execute the implementation plan:

```bash
/implement pdf-export
```

This command:
- Reads the plan and finds where you left off
- Implements the next task/sub-task
- Writes tests for each major component
- Checks off completed tasks
- Can be run multiple times to continue work

### 6. Capture Learnings

When implementation is complete:

```bash
/capture-learnings pdf-export
```

This command:
- Updates `docs/requirements/current-features.md` with new capabilities
- Updates `docs/development/current-architecture.md` with architectural changes
- Archives completed documents to appropriate folders
- Creates a pull request with all changes

### Complete Example Workflow

Here's a real-world example of implementing a new feature:

```bash
# 1. Start with an idea
/change-request Add a search feature that allows users to search across all Markdown files in the selected directory

# 2. After approval, create a branch
/feature-branch markdown-search

# 3. Understand the current system
/baseline

# 4. Design the solution
/design-plan markdown-search

# 5. Implement (run multiple times as needed)
/implement markdown-search
# ... work for a while, then continue later ...
/implement markdown-search

# 6. When complete, update docs and create PR
/capture-learnings markdown-search
```

### Additional Examples

**Quick Bug Fix:**
```bash
/change-request Fix crash when opening files with special characters in filename
/feature-branch special-char-fix
/design-plan special-char-fix
/implement special-char-fix
/capture-learnings special-char-fix
```

**UI Enhancement:**
```bash
/change-request Add dark mode theme switcher in preferences
/feature-branch dark-mode-switcher
/baseline
/design-plan dark-mode-switcher
/implement dark-mode-switcher
/capture-learnings dark-mode-switcher
```

## Architecture

MDBrowser follows MVVM architecture with these key components:

- **Models**: `DirectoryNode`, `MarkdownDocument`, `UserPreferences`
- **Services**: `FileSystemService` for file operations and monitoring
- **Views**: SwiftUI views for the dual-pane interface
- **ViewModels**: Business logic and state management

See `docs/development/current-architecture.md` for detailed architecture documentation.

## Contributing

1. Follow the development workflow described above
2. Ensure all tests pass before submitting PRs
3. Follow Apple's Human Interface Guidelines for macOS
4. Use Context7 for API documentation lookups
5. Search reputable sources for implementation best practices

## License

[License information to be added]

## Support

For issues and feature requests, please use the GitHub issue tracker.