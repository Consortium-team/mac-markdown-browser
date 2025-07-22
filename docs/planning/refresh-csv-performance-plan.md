# Implementation Plan: CSV Support, Refresh Functionality, Synchronized Scrolling, and Performance Optimization

## Date: 2025-07-22
## Author: Tech Lead
## Version: 1.0

## Overview

This implementation plan breaks down the four-phase enhancement project into actionable tasks with clear dependencies and acceptance criteria. Phase 1 (CSV Support) is the priority, followed by quick wins in Phases 2-3.

## Phase 1: CSV File Support (Priority 1)

### Prerequisites
- [ ] Review existing document handling patterns (MarkdownDocument, FilePreviewView)
- [ ] Set up CSV test files (various sizes, delimiters, edge cases)
- [ ] Research CSV parsing libraries vs custom implementation

### Task 1: Extend File Type System
**Estimated Time**: 2 hours

- [x] Add CSV case to FileType enum
  - [x] Add "csv" and "tsv" to file extension detection
  - [x] Add "tablecells" SF Symbol for CSV icon
  - [x] Include CSV in isSupported property
  - [x] Write unit tests for CSV file type detection

**Acceptance Criteria**:
- CSV files show correct icon in file browser
- CSV files are recognized as supported documents
- Unit tests pass for FileType.csv

### Task 2: Create CSV Document Model
**Estimated Time**: 4 hours

- [x] Create CSVDocument.swift based on MarkdownDocument pattern
  - [x] Define CSVData struct (headers, rows, metadata)
  - [x] Define CSVDelimiter enum (comma, tab, semicolon)
  - [x] Implement loadContent() with file reading
  - [x] Implement saveContent() with atomic writes
  - [x] Add file system monitoring
  - [x] Implement delimiter auto-detection
  - [x] Add error handling (DocumentError cases)

- [x] Write CSVDocument tests
  - [x] Test file loading/saving
  - [x] Test delimiter detection
  - [x] Test change tracking
  - [x] Test external file change detection

**Acceptance Criteria**:
- Can load CSV files into memory
- Correctly detects delimiter type
- Tracks unsaved changes
- Monitors external file changes

### Task 3: Implement CSV Parser Service
**Estimated Time**: 6 hours

- [x] Create CSVParser.swift
  - [x] Implement streaming parser for memory efficiency
  - [x] Handle quoted values and escaped characters
  - [x] Support configurable delimiters
  - [x] Implement row/column limits for performance
  - [x] Add cell content sanitization
  - [x] Handle various line endings (CRLF, LF, CR)

- [x] Create comprehensive parser tests
  - [x] Test basic CSV parsing
  - [x] Test quoted values with commas
  - [x] Test escaped quotes
  - [x] Test newlines in cells
  - [x] Test Unicode and special characters
  - [x] Test malformed CSV handling
  - [x] Performance test with large files

**Acceptance Criteria**:
- Parses standard CSV files correctly
- Handles all edge cases without crashes
- Completes parsing in < 200ms for 1MB files
- Memory usage scales linearly

### Task 4: Build CSV View Model
**Estimated Time**: 4 hours

- [x] Create CSVViewModel.swift
  - [x] Implement document loading
  - [x] Add content update handling with debouncing
  - [x] Generate HTML table from parsed data
  - [x] Handle delimiter changes
  - [x] Add error state management
  - [x] Implement preview generation

- [x] Add view model tests
  - [x] Test document lifecycle
  - [x] Test preview generation
  - [x] Test delimiter switching
  - [x] Test error handling

**Acceptance Criteria**:
- Loads and displays CSV documents
- Updates preview within 300ms of edits
- Handles delimiter changes smoothly
- Shows appropriate error messages

### Task 5: Create CSV Editor View
**Estimated Time**: 3 hours

- [x] Create CSVEditorView.swift (NSViewRepresentable)
  - [x] Base on MarkdownEditorView pattern
  - [x] Add CSV-specific syntax highlighting
    - [x] Highlight delimiter characters
    - [x] Alternate row coloring in raw view
    - [x] Highlight quoted values
  - [x] Implement cell navigation with Tab/Shift+Tab
  - [x] Add line numbers
  - [x] Support find/replace

**Acceptance Criteria**:
- Displays raw CSV with syntax highlighting
- Allows editing with proper text controls
- Tab navigation works between cells
- Maintains cursor position during updates

### Task 6: Create CSV Preview View
**Estimated Time**: 3 hours

- [x] Create CSVPreviewView.swift
  - [x] Render HTML table using WKWebView
  - [x] Apply GitHub-style table CSS
  - [x] Add row/column count overlay
  - [x] Implement responsive table design
  - [x] Add zebra striping for readability
  - [x] Show loading state for large files

- [x] Create preview styling
  - [x] Match existing app theme
  - [x] Ensure readable on all screen sizes
  - [x] Support dark mode

**Acceptance Criteria**:
- Displays formatted table view
- Responsive to window resizing
- Shows metadata (rows x columns)
- Smooth scrolling performance

### Task 7: Integrate CSV Support into FilePreviewView
**Estimated Time**: 4 hours

- [x] Modify FilePreviewView.swift
  - [x] Add CSV file type detection
  - [x] Create CSVSplitView component
  - [x] Implement edit mode toggle
  - [x] Add CSV-specific toolbar items
    - [x] Delimiter selector
    - [x] Export options
  - [x] Handle view transitions

- [x] Update ContentView if needed
  - [x] Ensure CSV files trigger correct preview
  - [x] Test navigation between file types

**Acceptance Criteria**:
- CSV files open in split view
- Edit button toggles edit mode
- Delimiter can be changed via UI
- Smooth transitions between files

### Task 8: Security Hardening
**Estimated Time**: 3 hours

- [ ] Implement content sanitization
  - [ ] HTML escape all cell values
  - [ ] Strip control characters
  - [ ] Limit cell content length
  - [ ] Validate Unicode sequences

- [ ] Add security tests
  - [ ] Test XSS prevention
  - [ ] Test injection attacks
  - [ ] Test resource exhaustion
  - [ ] Test malicious CSV files

- [ ] Configure WebView security
  - [ ] Disable JavaScript for CSV preview
  - [ ] Set restrictive Content Security Policy
  - [ ] Disable external resource loading

**Acceptance Criteria**:
- No XSS vulnerabilities in preview
- Malicious content is sanitized
- Resource limits enforced
- WebView properly sandboxed

### Task 9: Performance Optimization
**Estimated Time**: 4 hours

- [ ] Implement virtual scrolling for large tables
  - [ ] Render only visible rows
  - [ ] Add scroll position indicators
  - [ ] Maintain scroll performance

- [ ] Add performance monitoring
  - [ ] Log parse times
  - [ ] Monitor memory usage
  - [ ] Track preview render time

- [ ] Performance testing
  - [ ] Test with 10,000 row files
  - [ ] Test with 100 column files
  - [ ] Measure memory growth
  - [ ] Profile CPU usage

**Acceptance Criteria**:
- 10,000 row files scroll at 60fps
- Memory usage < 100MB for large files
- Parse time < 500ms for 10MB files
- No UI freezes during operations

### Task 10: End-to-End Testing
**Estimated Time**: 3 hours

- [ ] Create CSV sample files
  - [ ] Simple CSV (10 rows)
  - [ ] Complex CSV (quotes, newlines)
  - [ ] Large CSV (10,000 rows)
  - [ ] Wide CSV (100 columns)
  - [ ] Each delimiter type

- [ ] Manual testing checklist
  - [ ] Open each sample file
  - [ ] Edit and save changes
  - [ ] Switch delimiters
  - [ ] Test undo/redo
  - [ ] Verify auto-save
  - [ ] Test keyboard shortcuts

- [ ] Integration tests
  - [ ] File navigation to CSV
  - [ ] Edit mode transitions
  - [ ] Save and reload
  - [ ] External file changes

**Acceptance Criteria**:
- All sample files display correctly
- Editing works reliably
- No data loss on save
- Smooth user experience

## Phase 2: Refresh Button Fix (Priority 2)

### Task 1: Diagnose Current Issue
**Estimated Time**: 1 hour

- [ ] Debug current refresh implementation
  - [ ] Trace execution path in DirectoryNode.refresh()
  - [ ] Identify why UI doesn't update
  - [ ] Understand parent traversal issue
  - [ ] Document findings

**Acceptance Criteria**:
- Clear understanding of bug cause
- Reproducible test case created

### Task 2: Fix Refresh Logic
**Estimated Time**: 2 hours

- [ ] Modify DirectoryNode.refresh()
  - [ ] Remove parent directory traversal
  - [ ] Ensure only selected folder refreshes
  - [ ] Add proper state management
  - [ ] Force SwiftUI view updates

- [ ] Add refresh state tracking
  - [ ] Add isRefreshing published property
  - [ ] Clear file system cache for node
  - [ ] Maintain expansion state

**Acceptance Criteria**:
- Refresh only affects selected folder
- No navigation to parent directories
- UI updates immediately

### Task 3: Add Visual Feedback
**Estimated Time**: 2 hours

- [ ] Update DirectoryBrowser context menu
  - [ ] Show progress indicator during refresh
  - [ ] Disable refresh button while in progress
  - [ ] Update button text/icon dynamically

- [ ] Add loading overlay to FileTreeView
  - [ ] Semi-transparent overlay during refresh
  - [ ] Progress indicator on refreshing node
  - [ ] Maintain tree interaction

**Acceptance Criteria**:
- Clear visual indication of refresh
- UI remains responsive
- Progress shown on correct node

### Task 4: Test Refresh Functionality
**Estimated Time**: 1 hour

- [ ] Create test scenarios
  - [ ] Refresh root directory
  - [ ] Refresh nested directory
  - [ ] Refresh with file changes
  - [ ] Refresh with new files
  - [ ] Refresh with deleted files

- [ ] Verify fixes
  - [ ] No parent traversal
  - [ ] UI updates properly
  - [ ] State consistency maintained
  - [ ] Performance acceptable

**Acceptance Criteria**:
- All test scenarios pass
- Refresh completes in < 500ms
- No regression in functionality

## Phase 3: Enable Synchronized Scrolling (Priority 3)

### Task 1: Review Existing Implementation
**Estimated Time**: 1 hour

- [ ] Examine ScrollSynchronizer service
- [ ] Review SynchronizedPreviewView
- [ ] Review SynchronizedMarkdownEditView
- [ ] Understand integration points

**Acceptance Criteria**:
- Full understanding of existing code
- Integration plan documented

### Task 2: Integrate into ProperMarkdownEditor
**Estimated Time**: 2 hours

- [ ] Replace current split view components
  - [ ] Use SynchronizedMarkdownEditView for editor
  - [ ] Use SynchronizedPreviewView for preview
  - [ ] Initialize ScrollSynchronizer
  - [ ] Connect components

- [ ] Test integration
  - [ ] Verify scroll syncing works
  - [ ] Check performance impact
  - [ ] Ensure no UI glitches

**Acceptance Criteria**:
- Scrolling is synchronized
- No performance degradation
- Smooth scroll experience

### Task 3: Add User Preference
**Estimated Time**: 1 hour

- [ ] Add preference to UserPreferences
  - [ ] Add enableScrollSync property
  - [ ] Default to true
  - [ ] Persist with @AppStorage

- [ ] Add menu toggle
  - [ ] Add to View menu
  - [ ] Assign Cmd+Y shortcut
  - [ ] Connect to preference

- [ ] Make sync conditional
  - [ ] Check preference in editor
  - [ ] Enable/disable synchronizer
  - [ ] Update UI accordingly

**Acceptance Criteria**:
- Preference toggles sync on/off
- Setting persists across launches
- Keyboard shortcut works

### Task 4: Test Synchronized Scrolling
**Estimated Time**: 1 hour

- [ ] Test with various documents
  - [ ] Short documents
  - [ ] Long documents (1000+ lines)
  - [ ] Documents with images
  - [ ] Documents with code blocks

- [ ] Performance testing
  - [ ] Measure sync latency
  - [ ] Check CPU usage
  - [ ] Verify 60fps maintained

**Acceptance Criteria**:
- Sync latency < 50ms
- No visible lag
- Works with all content types

## Phase 4: Directory Loading Performance (Priority 4)

### Prerequisites
- [ ] Research current SwiftUI performance limitations with tree views
- [ ] Benchmark current implementation with 1000+ files
- [ ] Document baseline performance metrics

### Task 1: Performance Research and Benchmarking
**Estimated Time**: 3 hours

- [ ] Benchmark current performance
  - [ ] Test with 100, 1000, 10000 file directories
  - [ ] Measure initial load time
  - [ ] Measure memory usage
  - [ ] Identify SwiftUI OutlineGroup bottlenecks

- [ ] Research findings documentation
  - [ ] Document that OutlineGroup loads all children immediately
  - [ ] Note that .id() modifier breaks lazy loading
  - [ ] Compare LazyVStack vs List vs OutlineGroup performance

**Acceptance Criteria**:
- Clear performance baseline established
- Bottlenecks identified and documented
- Decision made on SwiftUI vs NSOutlineView approach

### Task 2: Implement Proxy-Based Lazy Loading
**Estimated Time**: 6 hours

- [ ] Create FileNodeProxy struct
  - [ ] Lightweight structure with minimal memory footprint
  - [ ] Store only essential metadata (URL, name, type)
  - [ ] Implement Identifiable protocol
  
- [ ] Create LazyFileNode class
  - [ ] Implement proxy-based child management
  - [ ] Add loadMetadata() for initial directory scan
  - [ ] Implement loadChild() for on-demand node creation
  - [ ] Add memory-efficient batch loading

- [ ] Update existing FileNode
  - [ ] Support conversion from proxy
  - [ ] Maintain compatibility with existing code
  - [ ] Add lazy loading flags

**Acceptance Criteria**:
- Proxy objects use < 200 bytes each
- Directory metadata loads in < 50ms
- Full nodes created only when visible
- No regression in existing functionality

### Task 3: Build Optimized Tree View
**Estimated Time**: 6 hours

- [ ] Create OptimizedFileTreeView
  - [ ] Replace List/OutlineGroup with ScrollView + LazyVStack
  - [ ] Implement custom indentation logic
  - [ ] Add expand/collapse without .id() modifier
  - [ ] Implement ProxyFileRow for on-demand loading

- [ ] Optimize rendering pipeline
  - [ ] Avoid ForEach with .id() modifier
  - [ ] Use explicit identity management
  - [ ] Implement view recycling pattern
  - [ ] Add viewport-based loading

- [ ] Handle user interactions
  - [ ] Selection without full node loading
  - [ ] Expansion state management
  - [ ] Context menu integration
  - [ ] Keyboard navigation

- [ ] Preserve drag and drop functionality
  - [ ] Implement onDrag for proxy rows using proxy URL
  - [ ] Create ProxyDropDelegate that loads nodes on demand
  - [ ] Maintain spring-loaded folder expansion
  - [ ] Ensure drop target highlighting works with virtualized views

**Acceptance Criteria**:
- Scrolling maintains 60fps with 10,000 items
- Initial render < 100ms for any directory size
- Expansion/collapse < 50ms response time
- Memory usage scales with visible items only
- Drag and drop continues to work exactly as before
- Spring-loaded folders expand after 1 second hover

### Task 4: NSOutlineView Fallback Implementation
**Estimated Time**: 4 hours

- [ ] Create NativeFileTreeView (NSViewRepresentable)
  - [ ] Wrap NSOutlineView for true lazy loading
  - [ ] Implement data source with on-demand loading
  - [ ] Add delegate for selection and expansion
  - [ ] Bridge SwiftUI state management

- [ ] Feature parity with SwiftUI version
  - [ ] Context menus
  - [ ] Drag and drop support
  - [ ] Keyboard shortcuts
  - [ ] Theme integration

**Acceptance Criteria**:
- Handles 100,000+ files without performance degradation
- Seamless integration with SwiftUI app
- All features work identically to SwiftUI version
- Decision point: Use if SwiftUI performance inadequate

### Task 5: Performance Optimization Infrastructure
**Estimated Time**: 4 hours

- [ ] Implement PerformanceOptimizedFileSystem
  - [ ] NSCache for file metadata
  - [ ] Batch file system operations
  - [ ] Concurrent loading with operation queues
  - [ ] Smart prefetching based on scroll position

- [ ] Add performance monitoring
  - [ ] FPS counter for development builds
  - [ ] Memory usage tracking
  - [ ] Load time instrumentation
  - [ ] Automatic performance regression alerts

- [ ] Caching strategy
  - [ ] LRU cache for file metadata
  - [ ] Persistent cache for frequently accessed directories
  - [ ] Cache invalidation on file system changes
  - [ ] Memory pressure handling

**Acceptance Criteria**:
- Second visit to directory < 20ms load time
- Cache hit rate > 90% for common operations
- Graceful degradation under memory pressure
- No stale data in cache

### Task 6: Drag and Drop Compatibility Testing
**Estimated Time**: 3 hours

- [ ] Test drag operations with proxy rows
  - [ ] Drag single file from lazy-loaded directory
  - [ ] Drag multiple files with selection
  - [ ] Drag folder to another location
  - [ ] Verify drag preview appears correctly

- [ ] Test drop operations on virtualized views
  - [ ] Drop file onto lazy-loaded folder
  - [ ] Drop during scroll (auto-scroll behavior)
  - [ ] Spring-loaded folder expansion timing
  - [ ] Drop target highlighting performance

- [ ] Test edge cases
  - [ ] Drag from/to directories with 10,000+ items
  - [ ] Drop validation with circular move prevention
  - [ ] Drag and drop during directory refresh
  - [ ] Memory usage during drag operations

- [ ] Integration with favorites
  - [ ] Drag from file tree to favorites
  - [ ] Ensure FavoritesDropDelegate still works
  - [ ] Test reordering in favorites section

**Acceptance Criteria**:
- All existing drag and drop features work identically
- No performance degradation during drag operations
- Visual feedback remains responsive
- File move operations complete successfully
- No memory leaks during drag and drop

### Task 7: Comprehensive Performance Testing
**Estimated Time**: 4 hours

- [ ] Create test scenarios
  - [ ] Directories with 100, 1000, 10000, 100000 files
  - [ ] Deep nesting (20+ levels)
  - [ ] Mixed file types and sizes
  - [ ] Rapid scrolling patterns
  - [ ] Expand/collapse stress test

- [ ] Automated performance tests
  - [ ] Load time regression tests
  - [ ] Memory usage limits
  - [ ] FPS maintenance tests
  - [ ] CPU usage monitoring

- [ ] Profile and optimize
  - [ ] Instruments profiling for bottlenecks
  - [ ] Memory graph analysis
  - [ ] Time profiler for hot paths
  - [ ] Energy impact assessment

**Acceptance Criteria**:
- All performance targets met consistently
- No memory leaks detected
- CPU usage < 10% during idle
- Battery impact negligible

### Task 8: Migration and Compatibility
**Estimated Time**: 3 hours

- [ ] Create migration path
  - [ ] Gradual rollout with feature flag
  - [ ] Fallback to old implementation if needed
  - [ ] A/B testing framework for performance comparison

- [ ] Update existing code
  - [ ] DirectoryBrowser to use new view
  - [ ] Search functionality with lazy loading
  - [ ] Favorites integration
  - [ ] File system monitoring compatibility
  - [ ] Ensure FileDragDelegate works with new architecture

**Acceptance Criteria**:
- Zero breaking changes for users
- Seamless upgrade path
- Performance improvements visible immediately
- All existing features continue working
- Drag and drop functionality preserved

## Testing Strategy

### Unit Testing
- [ ] CSV parser edge cases
- [ ] File type detection
- [ ] View model logic
- [ ] Performance benchmarks

### Integration Testing  
- [ ] File navigation flows
- [ ] Edit/save cycles
- [ ] Cross-feature interactions
- [ ] State persistence

### UI Testing
- [ ] Visual regression tests
- [ ] Accessibility compliance
- [ ] Keyboard navigation
- [ ] Error states

### Security Testing
- [ ] XSS prevention
- [ ] Resource limits
- [ ] Input validation
- [ ] Sandbox compliance

## Rollout Plan

### Week 1: CSV Support Foundation
- Complete Tasks 1-4 of Phase 1
- Begin parser implementation

### Week 2: CSV UI and Integration  
- Complete Tasks 5-7 of Phase 1
- Implement security hardening
- Begin testing

### Week 3: Quick Wins
- Complete Phase 2 (Refresh Fix)
- Complete Phase 3 (Sync Scrolling)
- Finish Phase 1 testing

### Week 4: Performance and Polish
- Begin Phase 4 implementation
- Complete all testing
- Documentation updates
- Prepare for release

## Risk Mitigation

### Technical Risks
1. **CSV Parser Complexity**: Use incremental approach, test extensively
2. **Memory Issues**: Implement limits early, monitor continuously
3. **UI Performance**: Profile regularly, optimize proactively

### Schedule Risks
1. **Feature Creep**: Stick to defined scope
2. **Testing Time**: Automate where possible
3. **Integration Issues**: Test continuously

## Success Metrics

- CSV files load and display correctly
- Refresh works as expected  
- Scroll sync improves workflow
- Large directories handle smoothly
- No security vulnerabilities
- Performance targets met
- User satisfaction increased

## Next Steps

1. Review and approve this plan
2. Set up development environment
3. Create test data sets
4. Begin Phase 1 implementation
5. Schedule daily check-ins