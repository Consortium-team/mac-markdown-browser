# CHANGE REQUEST: Refresh Button for Preview

**Date**: 2025-01-31
**Priority**: P1
**Requested By**: User
**Security Review**: Optional

## Overview
Add a refresh button to the preview panel that allows users to manually reload the file content from disk. This addresses the issue where file changes (especially external modifications) may show cached content instead of the current disk state, ensuring users always have access to the latest version of their documents.

## User Value
- **Immediate File Updates**: Users can instantly see external changes made by other applications or team members
- **Cache Control**: Provides explicit control over when content is refreshed, avoiding confusion from stale content
- **Workflow Continuity**: Enables smooth collaboration workflows where files may be modified by external tools or scripts
- **Confidence in Content**: Users can verify they're viewing the latest version without restarting the application

## Success Metrics
- **User Action Response Time**: Refresh completes in < 100ms for typical Markdown files
- **Cache Hit Rate**: Maintain 80%+ cache hit rate for non-refreshed views
- **User Adoption**: 60% of users utilize refresh button when external changes detected
- **Error Rate**: < 0.1% failure rate for refresh operations

## Technical Scope
- **UI Component**: Add refresh button to FilePreviewView toolbar
- **ViewModel Updates**: Enhance MarkdownViewModel with explicit refresh method
- **Cache Management**: Implement cache invalidation on manual refresh
- **Keyboard Shortcut**: Add Cmd+R shortcut for refresh action
- **Visual Feedback**: Show loading indicator during refresh operation

## Security Considerations
### Sandboxing Impact
- No new entitlements required - operates within existing file access permissions
- Uses already-granted security-scoped bookmarks for file access
- No changes to existing sandboxing restrictions

### Data Protection Requirements
- File access limited to already-opened documents (no new file access)
- Security-scoped bookmarks remain valid during refresh
- No additional local storage requirements
- Maintains existing file monitoring infrastructure

### Potential Security Risks
- **Path Validation**: Ensure file path hasn't changed during refresh
- **Resource Management**: Prevent rapid refresh attempts causing resource exhaustion
- **File Handle Leaks**: Ensure proper cleanup of file handles during refresh
- **Concurrent Access**: Handle race conditions with file system monitoring

### Privacy Impact
- Local Data Storage: No new data storage requirements
- File Access Patterns: No additional file access beyond current scope
- No Cloud/Network: Confirms purely local file system operation

## macOS Integration
- Leverages native NSDocument reload patterns
- Follows macOS HIG for toolbar refresh buttons (system symbol: "arrow.clockwise")
- Integrates with existing FSEvents monitoring without conflicts
- Maintains app responsiveness during refresh operations

## Security Requirements for Implementation
- **Rate Limiting**: Implement refresh throttling (max 1 refresh per 500ms)
- **Error Boundaries**: Graceful handling of file access errors
- **Resource Cleanup**: Ensure file handles are properly released
- **State Validation**: Verify document state consistency after refresh
- **Testing Requirements**: 
  - Test rapid refresh attempts
  - Verify memory usage doesn't increase with repeated refreshes
  - Ensure file locks are properly handled

## Implementation Notes
The application already has infrastructure for file reloading:
- `MarkdownDocument.reloadFromDisk()` method exists
- `MarkdownViewModel.reloadCurrentDocument()` provides the refresh logic
- File system monitoring detects external changes
- Cache invalidation logic is in place

The main work involves:
1. Adding the UI button to the toolbar
2. Wiring the button action to the existing reload functionality
3. Adding visual feedback during refresh
4. Implementing keyboard shortcut
5. Adding rate limiting for security

## User Experience Considerations
- Button should be visually distinct but not prominent (secondary style)
- Show subtle animation during refresh (rotating arrow icon)
- Preserve scroll position after refresh when possible
- Display toast notification if refresh fails
- Disable button during active refresh to prevent double-clicks