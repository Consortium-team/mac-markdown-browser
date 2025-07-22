# Change Request: CSV Support, Refresh Functionality, Synchronized Scrolling, and Performance Optimization

## Date: 2025-07-22
## Submitted By: User Request
## Priority: High

## Executive Summary

This change request addresses four distinct issues that impact user experience, ordered by user priority:
1. Lack of CSV file support limits the app's utility for data documentation (most wanted feature)
2. Directory refresh button exists but doesn't trigger actual file system refresh for the selected folder
3. Missing synchronized scrolling between editor and preview panes affects editing workflow
4. Performance issues with directory loading affecting user productivity

## Issue 1: CSV File Support

### User Problem
Users working with data documentation cannot preview CSV files within the app, requiring them to switch to external applications. This breaks their workflow when documenting data structures or API responses.

### Current Implementation Analysis
- FileType enum only supports Markdown and HTML files
- No CSV parsing or rendering capability exists
- The app architecture supports adding new file types

### Proposed Solution
Implement CSV support with:
- Raw CSV view in the editor pane (left side)
- Formatted table preview in the preview pane (right side)
- Basic CSV editing capabilities
- Support for common CSV formats (comma, tab, semicolon delimited)

### User Impact
- **Primary Users**: Technical consultants documenting data structures gain integrated CSV viewing
- **Secondary Users**: Developers can view data files alongside documentation
- **New Use Cases**: Data analysts could use the app for documentation workflows

### Implementation Considerations
- **Estimated Effort**: Medium
- **Technical Risks**: CSV parsing edge cases, large file performance
- **Dependencies**: May need CSV parsing library or custom implementation

## Issue 2: Refresh Button Not Working

### User Problem
Users report that the refresh button in the directory browser context menu doesn't actually refresh the directory contents for the selected folder. The button exists at line 204-208 in DirectoryBrowser.swift but calls `node.refresh()` which doesn't properly update the UI. Currently, it attempts to refresh from the home directory rather than just the selected folder.

### Current Implementation Analysis
- The refresh button exists in the context menu for directories
- It calls `await node.refresh()` which clears and reloads children
- The method uses `objectWillChange.send()` but the UI doesn't consistently update
- The issue appears to be related to SwiftUI view refresh mechanisms
- The refresh should only update the selected folder, not traverse up to home directory

### Proposed Solution
Fix the refresh functionality to ensure:
- Directory contents are properly reloaded from the file system for ONLY the selected folder
- UI updates reflect the refreshed state immediately
- Add visual feedback during refresh operation
- Prevent unnecessary traversal to parent directories

### User Impact
- **Primary Users**: Technical consultants will be able to see updated documentation without restarting the app
- **Secondary Users**: Developers can see newly generated files immediately
- **Frequency**: High - users frequently need to refresh after external file operations

## Issue 3: Synchronized Scrolling

### User Problem
Users editing long documents need to manually scroll both the editor and preview panes to keep them aligned. This disrupts the editing workflow and makes it difficult to verify changes in real-time.

### Current Implementation Analysis
- Synchronized scrolling infrastructure already exists in the codebase:
  - `ScrollSynchronizer.swift` service handles scroll coordination
  - `SynchronizedPreviewView.swift`, `SynchronizedMarkdownEditView.swift`, and `SynchronizedTextEditor.swift` provide the UI components
- The feature is implemented but not actively used in the main editor interface
- Listed as a "Future Enhancement" in current-features.md despite being already implemented

### Proposed Solution
Activate the existing synchronized scrolling functionality:
- Enable scroll synchronization between the raw editor (left pane) and preview (right pane)
- Ensure smooth scrolling performance
- Add user preference to enable/disable synchronized scrolling
- Test with large documents to ensure performance remains acceptable

### User Impact
- **Primary Users**: Document authors benefit from seamless editing experience
- **Secondary Users**: Reviewers can navigate documents more efficiently
- **Frequency**: High - affects every editing session

### Implementation Considerations
- **Estimated Effort**: Low (feature already implemented, needs activation)
- **Technical Risks**: Minimal - code already exists and tested
- **Dependencies**: None - uses existing infrastructure

## Issue 4: Directory Loading Performance

### User Problem
Users experience delays when navigating directories with many files. The current implementation loads all directory contents immediately, causing UI freezes with large directories.

### Current Implementation Analysis
- DirectoryNode loads all children synchronously in `loadChildren()`
- No pagination or lazy loading implemented
- File system operations block the UI during loading

### Proposed Solution
Implement lazy loading for directory contents:
- Load only visible items initially
- Implement virtual scrolling for large directories
- Add progressive loading with visual indicators
- Cache directory contents for faster navigation

### User Impact
- **Primary Users**: Consultants with large documentation repositories experience faster navigation
- **All Users**: Improved responsiveness when browsing any directory
- **Performance Target**: Initial directory load < 100ms for directories with 1000+ files

### Implementation Considerations
- **Estimated Effort**: Large
- **Technical Risks**: Complex state management, scroll position preservation
- **Dependencies**: May require custom virtualization implementation

## Prioritization Analysis

Using the product prioritization matrix:

### Issue 1: CSV Support
- **User Value**: 5/5 (Most requested feature, expands use cases significantly)
- **Strategic Fit**: 4/5 (Enhances data documentation workflows)
- **Technical Effort**: 3/5 (New feature, medium complexity)
- **Risk Level**: 2/5 (Parsing edge cases)
- **Priority Score**: (5 × 4) / (3 + 2) = 4.00

### Issue 2: Refresh Button
- **User Value**: 4/5 (High frequency pain point)
- **Strategic Fit**: 5/5 (Core browsing functionality)
- **Technical Effort**: 2/5 (Bug fix, low complexity)
- **Risk Level**: 1/5 (Low risk)
- **Priority Score**: (4 × 5) / (2 + 1) = 6.67

### Issue 3: Synchronized Scrolling
- **User Value**: 4/5 (Improves editing workflow significantly)
- **Strategic Fit**: 4/5 (Core editing experience)
- **Technical Effort**: 1/5 (Already implemented, needs activation)
- **Risk Level**: 1/5 (Minimal risk, code exists)
- **Priority Score**: (4 × 4) / (1 + 1) = 8.00

### Issue 4: Performance Optimization
- **User Value**: 5/5 (Affects all users)
- **Strategic Fit**: 5/5 (Core performance requirement)
- **Technical Effort**: 4/5 (Complex implementation)
- **Risk Level**: 3/5 (State management complexity)
- **Priority Score**: (5 × 5) / (4 + 3) = 3.57

## Recommendation

**Accept all four issues with phased implementation based on user priorities:**

1. **Phase 1 (Immediate)**: Add CSV file support
   - Most requested feature by users
   - Expands use cases for data documentation
   - Medium effort with high user value
   - Consider starting with read-only support, then add editing

2. **Phase 2 (Current Sprint)**: Fix refresh button functionality
   - Critical bug affecting existing functionality
   - Low effort, high impact
   - Ensure refresh only updates the selected folder, not entire tree

3. **Phase 3 (Current Sprint)**: Enable synchronized scrolling
   - Feature already implemented but not activated
   - Minimal effort required (1-2 days)
   - High impact on editing workflow
   - Can be completed alongside Phase 2

4. **Phase 4 (Next Sprint)**: Implement directory loading performance optimization
   - Addresses fundamental UX issue
   - Benefits all users but lower priority than new features
   - Foundation for future scalability

## Success Metrics

### CSV Support
- CSV files load in < 200ms for files under 1MB
- Table rendering supports files up to 10,000 rows
- User adoption: 30% of users view CSV files within first month
- Support for comma, tab, and semicolon delimited formats

### Refresh Button Fix
- Refresh completes in < 500ms for typical directories
- Only refreshes the selected folder, not parent directories
- 0 bug reports about refresh not working
- UI updates immediately reflect file system changes

### Synchronized Scrolling
- Scroll synchronization latency < 50ms
- No performance degradation with documents up to 10,000 lines
- User preference setting persists across sessions
- 80% of users enable the feature after trying it

### Performance Optimization
- Directory with 1000 files loads in < 100ms
- Smooth scrolling at 60fps for large directories
- Memory usage remains constant regardless of directory size

## Security Considerations

- CSV parsing must sanitize input to prevent injection attacks
- Large file handling must prevent memory exhaustion
- File system access remains within sandbox boundaries
- Synchronized scrolling JavaScript must be sandboxed in WKWebView
- Refresh operations must respect security-scoped bookmarks

## Next Steps

1. Evaluate CSV parsing libraries vs custom implementation for Phase 1
2. Create detailed technical design for refresh button fix (Phase 2)
3. Review and test existing synchronized scrolling implementation (Phase 3)
4. Research virtualization approaches for directory browsing (Phase 4)
5. Update test suite to cover all four improvements