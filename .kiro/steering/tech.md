# Technology Stack & Build System

## Core Technologies
- **Platform**: macOS 13.0+ (native Mac application)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI with AppKit integration for advanced file operations
- **Build System**: Swift Package Manager (SPM)

## Key Dependencies
- **swift-markdown**: Apple's official Swift Markdown parsing library (v0.3.0+)
- **Down**: Swift wrapper for cmark with additional rendering capabilities (v0.11.0+)
- **WKWebView**: For Mermaid diagram rendering with JavaScript integration

## Architecture Patterns
- **MVVM**: SwiftUI with ObservableObject view models
- **Reactive Programming**: @Published properties for UI state management
- **Async/Await**: Modern Swift concurrency for file operations
- **Security-Scoped Bookmarks**: For persistent directory access in sandboxed environment

## Project Structure
```
MarkdownBrowser/
├── Models/           # Data models (DirectoryNode, MarkdownDocument, UserPreferences)
├── Views/            # SwiftUI views and components
├── ViewModels/       # Business logic and state management
├── Services/         # File system operations and rendering services
└── Assets.xcassets/  # App icons and resources
```

## Common Commands

### Building
```bash
# Build the project
swift build

# Build for release
swift build -c release

# Clean build artifacts
swift package clean
```

### Testing
```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test target
swift test --filter MarkdownBrowserTests
```

### Development
```bash
# Open in Xcode
open MarkdownBrowser.xcodeproj

# Generate Xcode project (if needed)
swift package generate-xcodeproj

# Resolve dependencies
swift package resolve
```

## Code Style Guidelines
- Follow Swift API Design Guidelines
- Use SwiftUI property wrappers (@State, @Published, @ObservedObject)
- Implement proper error handling with Result types
- Use async/await for file operations
- Maintain separation of concerns between Models, Views, and ViewModels

## Apple Human Interface Guidelines Compliance

### Window Management
- **Window Controls**: Use standard macOS window controls (red/yellow/green "traffic light" buttons)
  - Do NOT add custom close/minimize/maximize buttons
  - Let NSWindow handle the standard window controls automatically
  - Access via: `window.standardWindowButton(.closeButton)` if needed
- **Window Styles**: Use appropriate NSWindow style masks:
  ```swift
  [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
  ```
- **Document Windows**: For document-based windows, show unsaved changes indicator (dot in close button)

### General macOS Design Principles
- **Native Controls**: Always use native macOS controls and behaviors
- **Keyboard Shortcuts**: Follow standard macOS keyboard shortcuts (Cmd+S for save, Cmd+W for close window, etc.)
- **Window Behavior**: Windows should behave consistently with other macOS apps
- **Dark Mode**: Support both light and dark appearance modes
- **Accessibility**: Ensure all UI elements are accessible via VoiceOver

### Resources
- Consult Apple's Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Use native NSWindow/SwiftUI window management APIs
- Test on actual macOS to ensure native behavior