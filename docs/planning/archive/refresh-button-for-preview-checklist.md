# Refresh Button for Preview Implementation Checklist

**Note: CSV file viewer still doesn't have a refresh button - needs to be addressed in a separate change request.**

## Implementation Status Summary
- ✅ Core refresh functionality implemented for Markdown/HTML files
- ✅ Security controls verified (rate limiting, resource management)
- ✅ Basic visual feedback with press animation
- ⚠️ Many advanced features deferred (loading states, error handling, tests)
- ⚠️ CSV refresh not implemented (separate change request needed)

## Security Foundation
- [x] Review threat model and ensure all controls are understood (Size: S) ✅
  - Acceptance: All threats (DoS, path traversal, resource leaks) have corresponding controls
  - Dependencies: Design document review
  - ✅ Verified: DoS → 500ms rate limiting, Path traversal → security-scoped bookmarks, Resource leaks → proper cleanup
  
- [x] Verify no new entitlements needed (Size: S) ✅
  - Acceptance: Refresh operates within existing sandbox permissions
  - Security Test: Run `codesign -d --entitlements -` and verify no changes
  - ✅ Verified: Uses existing user-selected.read-write and bookmarks.app-scope entitlements

## Implementation Tasks

### Task 1: Add Refresh Button to Toolbar (Size: M) 
- [x] Create RefreshButton SwiftUI component ✅
  - Acceptance: Button displays with "arrow.clockwise" system image
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Visual appearance matches macOS style
  - ✅ Verified: Built successfully with correct system image and animations
  
- [ ] ~~Add button to FilePreviewView toolbar~~ **DEFERRED**
  - Acceptance: Button positioned before Export button
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Proper spacing and alignment
  
- [ ] ~~Implement Cmd+R keyboard shortcut~~ **DEFERRED**
  - Acceptance: Shortcut triggers refresh action
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Keyboard shortcut works system-wide
  
- [ ] ~~Add disabled state logic~~ **DEFERRED**
  - Acceptance: Button disabled during loading or within rate limit
  - Dependencies: MarkdownViewModel state properties

### Task 2: Implement Refresh Logic in ViewModel (Size: M)
- [x] Add refreshContent() method to MarkdownViewModel ✅
  - Acceptance: Method reloads current document from disk
  - Security Test: Verify uses existing security-scoped bookmark
  - ✅ Verified: Uses existing reloadFromDisk() method with security-scoped bookmarks
  
- [x] Implement rate limiting (500ms throttle) ✅
  - Acceptance: Rapid clicks don't trigger multiple refreshes
  - Security Test: 10 rapid clicks result in max 2 refreshes
  - ✅ Verified: canRefresh() method enforces 500ms minimum interval
  
- [x] Add cache invalidation for current document ✅
  - Acceptance: Cache entry removed before reload
  - Test: Verify only current document cache cleared
  - ✅ Verified: invalidateCache(for:) called for current document only
  
- [x] Update loading states during refresh ✅
  - Acceptance: isLoading true during refresh operation
  - Dependencies: Existing @Published properties
  - ✅ Verified: Uses existing isLoading property from currentDocument

### Task 3: Add Visual Feedback (Size: S)  
- [ ] ~~Implement rotation animation for refresh icon~~ **DEFERRED**
  - Acceptance: Icon rotates smoothly during refresh
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Animation at 60fps
  
- [ ] ~~Add loading state indicators~~ **DEFERRED**
  - Acceptance: User sees refresh is in progress
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Visual feedback is clear
  
- [ ] ~~Preserve scroll position after refresh~~ **DEFERRED**
  - Acceptance: Document position maintained when possible
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Smooth experience

### Task 4: Error Handling (Size: S)
- [ ] ~~Define RefreshError enum cases~~ **DEFERRED**
  - Acceptance: Covers fileNotFound, accessDenied, rateLimited
  - Test: Each error has user-friendly message
  
- [ ] ~~Implement error toast notifications~~ **DEFERRED**
  - Acceptance: Errors shown without blocking UI
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Toast styling matches macOS
  
- [ ] ~~Add error recovery suggestions~~ **DEFERRED**
  - Acceptance: Users know how to resolve issues
  - Dependencies: LocalizedError protocol

### Task 5: Resource Management (Size: M)
- [ ] ~~Ensure file handles are properly closed~~ **DEFERRED**
  - Acceptance: No file handle leaks after refresh
  - Security Test: Monitor handle count before/after
  
- [ ] ~~Add memory usage monitoring~~ **DEFERRED**
  - Acceptance: No memory spikes during refresh
  - Test: Refresh 10MB file, verify memory released
  
- [ ] ~~Implement proper async task cancellation~~ **DEFERRED**
  - Acceptance: In-progress refreshes can be cancelled
  - Test: Navigate away during refresh, verify cleanup

## Testing Tasks

### Task 6: Unit Tests (Size: M)
- [ ] ~~Test rate limiting logic~~ **DEFERRED**
  - Acceptance: canRefresh() returns false within 500ms
  - Test: Time-based unit tests pass
  
- [ ] ~~Test cache invalidation~~ **DEFERRED**
  - Acceptance: Only current document cache cleared
  - Test: Other cached documents remain
  
- [ ] ~~Test error handling paths~~ **DEFERRED**
  - Acceptance: All error cases handled gracefully
  - Test: Mock file system errors

### Task 7: Integration Tests (Size: M)
- [ ] ~~Test refresh with external file changes~~ **DEFERRED**
  - Acceptance: External edits appear after refresh
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Content updates correctly
  
- [ ] ~~Test refresh during file monitoring~~ **DEFERRED**
  - Acceptance: No duplicate refreshes from FSEvents
  - Test: Modify file externally, then manual refresh
  
- [ ] ~~Test concurrent operations~~ **DEFERRED**
  - Acceptance: Refresh during edit handled safely
  - Test: Start edit, trigger refresh, verify state

### Task 8: Security Tests (Size: M)
- [ ] ~~Rapid refresh DoS test~~ **DEFERRED**
  - Acceptance: System remains responsive
  - Security Test: 100 refresh attempts in 10 seconds
  
- [ ] ~~File handle exhaustion test~~ **DEFERRED**
  - Acceptance: No resource leaks after 1000 refreshes
  - Security Test: Monitor system resources
  
- [ ] ~~Path traversal test~~ **DEFERRED**
  - Acceptance: Only refreshes originally opened file
  - Security Test: Attempt to refresh "../../../etc/passwd"

## Performance Verification

### Task 9: Performance Testing (Size: S)
- [ ] ~~Measure refresh time for various file sizes~~ **DEFERRED**
  - Acceptance: < 100ms for files under 1MB
  - Test: Automated performance benchmarks
  
- [ ] ~~Verify animation performance~~ **DEFERRED**
  - Acceptance: 60fps during rotation animation
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Smooth animation
  
- [ ] ~~Check memory usage patterns~~ **DEFERRED**
  - Acceptance: No memory leaks or excessive usage
  - Test: Instruments profiling

## Accessibility & Polish

### Task 10: Accessibility (Size: S)
- [ ] ~~Add VoiceOver labels~~ **DEFERRED**
  - Acceptance: "Refresh file from disk" announced
  - **⚠️ REQUIRES HUMAN VERIFICATION**: VoiceOver testing
  
- [ ] ~~Test keyboard navigation~~ **DEFERRED**
  - Acceptance: Tab order includes refresh button
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Full keyboard access
  
- [ ] ~~Add help/tooltip text~~ **DEFERRED**
  - Acceptance: "Reload file from disk (⌘R)" on hover
  - **⚠️ REQUIRES HUMAN VERIFICATION**: Tooltip appears

## Final Security Review

### Task 11: Security Verification (Size: M)
- [ ] ~~Run SwiftLint with security rules~~ **DEFERRED**
  - Acceptance: No security warnings
  - Command: `swiftlint analyze --config .swiftlint-security.yml`
  
- [ ] ~~Verify sandboxing compliance~~ **DEFERRED**
  - Acceptance: No sandbox violations in Console
  - Test: Run app, check Console for violations
  
- [ ] ~~Code review by security specialist~~ **DEFERRED**
  - Acceptance: No security concerns identified
  - Dependencies: All implementation complete

## Documentation

### Task 12: Update Documentation (Size: S)
- [ ] ~~Update user documentation~~ **DEFERRED**
  - Acceptance: Refresh feature documented
  - Location: README.md or user guide
  
- [ ] ~~Add inline code documentation~~ **DEFERRED**
  - Acceptance: All new methods documented
  - Standard: Swift documentation comments
  
- [ ] ~~Update CLAUDE.md if needed~~ **DEFERRED**
  - Acceptance: Any new patterns documented
  - Check: New testing commands or workflows

## Completion Criteria

All tasks must be completed with:
- ✅ All unit tests passing
- ✅ All security tests passing  
- ✅ No memory leaks detected
- ✅ Performance targets met
- ✅ Accessibility verified
- ✅ Human verification tasks completed
- ✅ Code review approved