# Implementation Plan

- [X] 1. Project Setup and Infrastructure
  - Initialize Xcode project with SwiftUI macOS target (macOS 13.0+)
  - Configure project structure with proper folder organization
  - Set up Package.swift with required dependencies (Down, Swift Markdown)
  - Create Git repository and connect to consortium.team organization
  - Set up documentation structure (/docs with requirements, feedback, planning, development folders)
  - _Requirements: 7.1, 7.3_

- [x] 2. Core Data Models and Foundation
  - [x] 2.1 Create DirectoryNode model with file system representation
    - Implement DirectoryNode class with URL, name, isDirectory properties
    - Add children array and isExpanded state for tree navigation
    - Include lazy loading capabilities for performance
    - Write unit tests for DirectoryNode functionality
    - _Requirements: 5.1, 5.2, 6.2_

  - [x] 2.2 Create MarkdownDocument model for content management
    - Implement MarkdownDocument class with content, renderedHTML, and change tracking
    - Add file loading and saving capabilities
    - Include lastModified date tracking
    - Write unit tests for document operations
    - _Requirements: 2.1, 9.7, 10.1_

  - [x] 2.3 Create UserPreferences model for application settings
    - Implement UserPreferences class with favorite directories, theme, and window state
    - Add persistent storage using UserDefaults
    - Include security-scoped bookmarks for directory access
    - Write unit tests for preferences management
    - _Requirements: 4.4, 8.1, 8.3_

- [x] 3. File System Services and Navigation
  - [x] 3.1 Implement FileSystemService for file operations
    - Create FileSystemService class with NSFileManager integration
    - Add directory loading with lazy loading support
    - Implement FSEvents monitoring for real-time file system changes
    - Include security-scoped bookmark creation and resolution
    - Write unit tests for file system operations
    - _Requirements: 5.1, 5.5, 6.3, 7.4_

  - [x] 3.2 Create FileSystemViewModel for directory navigation
    - Implement FileSystemViewModel with ObservableObject protocol
    - Add directory tree state management and navigation logic
    - Include file filtering (.md files by default) and search functionality
    - Implement keyboard navigation support
    - Write unit tests for view model logic
    - _Requirements: 5.2, 5.3, 5.4_

- [x] 4. Favorites Management System
  - [x] 4.1 Implement FavoritesViewModel for bookmark management
    - Create FavoritesViewModel with favorite directories management
    - Add drag-and-drop support for adding favorites
    - Implement keyboard shortcuts (Cmd+1-9) for quick access
    - Include context menu operations (rename, remove, reorder)
    - Write unit tests for favorites functionality
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

  - [x] 4.2 Create FavoritesSection UI component
    - Implement SwiftUI view for favorites display
    - Add drag-and-drop visual feedback and handling
    - Include context menu with management options
    - Implement keyboard shortcut handling
    - Write UI tests for favorites interactions
    - _Requirements: 4.1, 4.3_

- [x] 5. Basic Dual-Pane Interface
  - [x] 5.1 Create ContentView with dual-pane layout
    - Implement main ContentView with HSplitView
    - Add adjustable pane sizing with minimum/maximum constraints
    - Include window size management (1000x700 minimum)
    - Implement focus switching between panes (Tab key)
    - Write UI tests for layout and resizing
    - _Requirements: 1.1, 1.2, 1.4, 7.1_

  - [x] 5.2 Implement DirectoryPanel for left pane
    - Create DirectoryPanel SwiftUI view
    - Integrate FavoritesSection at the top
    - Add DirectoryBrowser for file tree navigation
    - Include search functionality within current directory
    - Write UI tests for directory panel interactions
    - _Requirements: 1.1, 5.3, 5.4_

- [X] 6. Markdown Processing and Rendering
  - [x] 6.1 Create MarkdownService for content processing
    - Implement MarkdownService with Swift Markdown integration
    - Add GitHub-compatible HTML rendering with CSS styling
    - Include syntax highlighting for code blocks
    - Implement table rendering and image display support
    - Write unit tests for Markdown parsing and rendering
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [X] 6.2 Implement MarkdownViewModel for content management
    - Create MarkdownViewModel with content state management
    - Add file loading and rendering coordination
    - Include performance optimization with caching
    - Implement error handling for parsing failures
    - Write unit tests for view model logic
    - _Requirements: 2.1, 6.1, 6.3, 10.3_

- [X] 7. Basic Preview Panel Implementation
  - [X] 7.1 Create PreviewPanel for right pane content display
    - Implement PreviewPanel SwiftUI view with toolbar
    - Add basic Markdown content display using WKWebView
    - Include scroll synchronization and smooth interactions
    - Implement theme support (light/dark mode following system)
    - Write UI tests for preview panel functionality
    - _Requirements: 1.1, 2.1, 7.2_

  - [X] 7.2 Integrate file selection with preview updates
    - Connect DirectoryPanel file selection to PreviewPanel updates
    - Implement sub-100ms file switching performance
    - Add loading indicators for content processing
    - Include error display for unreadable files
    - Write integration tests for file selection workflow
    - _Requirements: 6.1, 10.1_

- [X] 8. Mermaid Diagram Integration
  - [X] 8.1 Create MermaidRenderer for diagram processing
    - Implement MermaidRenderer class with WKWebView integration
    - Add Mermaid.js library integration with security sandbox
    - Include diagram extraction from Markdown content
    - Implement error handling with fallback to raw code display
    - Write unit tests for Mermaid processing
    - _Requirements: 3.1, 3.3, 3.4_

  - [X] 8.2 Integrate Mermaid rendering into preview pipeline
    - Add Mermaid block detection in MarkdownService
    - Implement seamless diagram rendering within content
    - Include zoom and pan capabilities for complex diagrams
    - Add 500ms rendering performance target
    - Write integration tests for Mermaid workflow
    - _Requirements: 3.1, 3.2, 6.4_

- [X] 9. Markdown Editing Capabilities
  - [X] 9.1 Create MarkdownEditor component
    - Implement MarkdownEditor SwiftUI view with syntax highlighting
    - Add text editing capabilities with Markdown-specific features
    - Include real-time preview updates or manual refresh option
    - Implement save functionality (Cmd+S) and unsaved changes tracking
    - Write UI tests for editor functionality
    - _Requirements: 9.1, 9.2, 9.7_

  - [X] 9.2 Implement edit mode switching and layouts
    - Add toggle between preview and edit modes (Cmd+E)
    - Implement fullscreen and side-by-side edit layouts
    - Include cursor position and scroll location preservation
    - Add unsaved changes prompts when navigating away
    - Write UI tests for mode switching and layout changes
    - _Requirements: 9.1, 9.3, 9.5, 9.6, 9.8_
  - [X] 9.3 Fix the critical issues identified in current-features.md

- [ ] 10. HTML Document Rendering Support
  - [ ] 10.1 Extend file type support to include HTML files
    - Update FileSystemViewModel to recognize .html and .htm files
    - Add HTML file icons and visual indicators in directory browser
    - Modify file filtering to include HTML files alongside Markdown
    - Update DirectoryNode to properly identify HTML files
    - Write unit tests for HTML file detection
    - _Requirements: 5.2, 5.3_

  - [ ] 10.2 Implement HTML preview functionality
    - Create HTMLPreviewView component using WKWebView
    - Add security sandboxing for safe HTML rendering
    - Implement local resource loading (CSS, images, JavaScript)
    - Add base URL support for relative links
    - Write UI tests for HTML preview functionality
    - _Requirements: 2.1, 7.2_

  - [ ] 10.3 Create unified preview system for Markdown and HTML
    - Refactor FilePreviewView to support multiple file types
    - Implement file type detection and appropriate renderer selection
    - Ensure consistent UI between Markdown and HTML previews
    - Add smooth transitions when switching between file types
    - Write integration tests for unified preview system
    - _Requirements: 1.1, 2.1_

  - [ ] 10.4 Add HTML-specific features
    - Implement zoom controls for HTML content
    - Add print support for HTML documents
    - Include view source option for HTML files
    - Add developer tools access (optional, for debugging)
    - Write UI tests for HTML-specific features
    - _Requirements: 7.2, 8.2_

  - [ ] 10.5 Ensure performance and security
    - Implement content security policies for HTML rendering
    - Add performance optimizations for large HTML files
    - Include error handling for malformed HTML
    - Test with various HTML5 features and edge cases
    - Write security and performance tests
    - _Requirements: 6.1, 10.1, 10.2_

- [ ] 11. Enhanced User Interface and Interactions
  - [ ] 11.1 Implement comprehensive keyboard shortcuts
    - Add keyboard shortcuts for all major functions
    - Include focus management and navigation shortcuts
    - Implement favorites quick access (Cmd+1-9)
    - Add edit mode toggle and save shortcuts
    - Write UI tests for keyboard interaction workflows
    - _Requirements: 1.3, 4.5, 7.3, 9.1_

  - [ ] 11.2 Create PreferencesView for application settings
    - Implement PreferencesView with all configurable options
    - Add file filtering preferences and theme selection
    - Include keyboard shortcut customization
    - Implement window state and session restoration
    - Write UI tests for preferences functionality
    - _Requirements: 8.1, 8.2, 8.4_

- [ ] 12. Performance Optimization and Caching
  - [ ] 12.1 Implement intelligent caching system
    - Add rendered content caching for frequently accessed files
    - Implement memory management with automatic cleanup
    - Include background processing for file operations
    - Add performance monitoring and optimization
    - Write performance tests for caching effectiveness
    - _Requirements: 6.1, 6.3, 6.4_

  - [ ] 12.2 Optimize file system operations
    - Implement lazy loading for large directory structures
    - Add background queues for file operations
    - Include progress indicators for long-running operations
    - Optimize memory usage for large file handling
    - Write performance tests for file system operations
    - _Requirements: 6.2, 6.5, 10.5_

- [ ] 13. Error Handling and Reliability
  - [ ] 13.1 Implement comprehensive error handling
    - Add error handling for all file system operations
    - Implement graceful degradation for parsing failures
    - Include user-friendly error messages and recovery options
    - Add logging system for debugging and monitoring
    - Write unit tests for error scenarios
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ] 13.2 Add application stability and recovery features
    - Implement crash recovery and state restoration
    - Add automatic backup of unsaved changes
    - Include network timeout handling for remote directories
    - Implement memory pressure handling
    - Write integration tests for stability scenarios
    - _Requirements: 10.5, 9.8_

- [ ] 14. Testing and Quality Assurance
  - [ ] 14.1 Create comprehensive test suite
    - Write unit tests for all models, services, and view models
    - Add integration tests for file system and rendering workflows
    - Include UI tests for all user interactions
    - Implement performance tests for response time requirements
    - Set up continuous integration for automated testing
    - _Requirements: All requirements validation_

  - [ ] 14.2 Conduct user acceptance testing
    - Test with real-world documentation repositories
    - Validate performance targets (100ms file switching, 500ms Mermaid rendering)
    - Verify accessibility compliance and keyboard navigation
    - Test with various file sizes and directory structures
    - Conduct usability testing with target user personas
    - _Requirements: 6.1, 6.4, 7.3_

- [ ] 15. Documentation and Deployment Preparation
  - [ ] 15.1 Create user documentation
    - Write user guide covering all application features
    - Create keyboard shortcut reference
    - Add troubleshooting guide for common issues
    - Include screenshots and workflow examples
    - _Requirements: User experience optimization_

  - [ ] 15.2 Prepare for distribution
    - Configure code signing for distribution
    - Create installer package (DMG) with proper notarization
    - Set up build automation for release preparation
    - Prepare App Store submission materials (if applicable)
    - _Requirements: 7.4, 7.5_