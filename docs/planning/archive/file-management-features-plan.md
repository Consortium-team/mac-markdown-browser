# Implementation Plan: File Management Features

## Overview

This plan details the implementation of drag-and-drop file movement and PDF export functionality for MDBrowser. Tasks are prioritized based on dependencies and user value.

## Timeline Estimate

**Total Effort**: 2-3 days
- Drag-and-Drop: 1.5 days
- PDF Export: 1 day
- Testing & Polish: 0.5 day

## Implementation Tasks

### [x] Phase 1: Drag-and-Drop Foundation (Day 1)

#### [x] Task 1.1: Create FileDragDelegate
**Priority**: High  
**Effort**: 2 hours  
**Acceptance Criteria**:
- [x] Create FileDragDelegate class implementing DropDelegate protocol
- [x] Implement validateDrop to check valid drop targets
- [x] Add visual feedback for valid/invalid drop zones
- [x] Prevent dropping files into themselves or their children
- [x] Unit tests for validation logic

**Performance Requirements**:
- Drop validation < 10ms
- Visual feedback updates < 16ms

#### [x] Task 1.2: Add Drag Source to DirectoryPanel
**Priority**: High  
**Effort**: 1 hour  
**Dependencies**: None  
**Acceptance Criteria**:
- [x] Add draggable modifier to file items in DirectoryNodeView
- [x] Create custom drag preview showing file icon and name
- [x] Only enable dragging for files, not directories (initial implementation)
- [x] Test drag gesture recognition

#### [x] Task 1.3: Add Drop Target to DirectoryPanel
**Priority**: High  
**Effort**: 2 hours  
**Dependencies**: Task 1.1  
**Acceptance Criteria**:
- [x] Add onDrop modifier to directory nodes
- [x] Connect to FileDragDelegate
- [x] Show hover state when dragging over valid targets
- [x] Clear visual indication of drop target
- [x] Test drop target activation

### [x] Phase 2: File Movement Implementation (Day 1-2)

#### [x] Task 2.1: Implement FileSystemService.moveFile
**Priority**: High  
**Effort**: 3 hours  
**Dependencies**: None  
**Acceptance Criteria**:
- [x] Add async moveFile method to FileSystemService
- [x] Handle security-scoped bookmarks for both source and destination
- [x] Implement atomic move with FileManager
- [x] Add proper error handling for all failure cases
- [x] Update FSEvents monitoring after successful move
- [x] Comprehensive unit tests

**Performance Requirements**:
- Local file moves < 100ms
- Network drive timeout: 30 seconds

#### [x] Task 2.2: Integrate Drag-Drop with File Movement
**Priority**: High  
**Effort**: 2 hours  
**Dependencies**: Tasks 1.3, 2.1  
**Acceptance Criteria**:
- [x] Connect FileDragDelegate.performDrop to FileSystemService.moveFile
- [x] Show progress indicator for long operations
- [x] Update UI immediately after successful move
- [x] Show error alerts for failed moves
- [x] End-to-end testing

#### [x] Task 2.3: Polish Drag-Drop Experience
**Priority**: Medium  
**Effort**: 1 hour  
**Dependencies**: Task 2.2  
**Acceptance Criteria**:
- [x] Add spring-loaded folder expansion (hover 1s to expand)
- [x] Support Escape key to cancel drag (system-handled)
- [x] Accessibility: VoiceOver announcements
- [x] Smooth animations for all transitions

### [x] Phase 3: PDF Export Foundation (Day 2)

#### [x] Task 3.1: Create PDFExportService
**Priority**: High  
**Effort**: 2 hours  
**Dependencies**: None  
**Acceptance Criteria**:
- [x] Create PDFExportService class
- [x] Implement exportToPDF using WKWebView.createPDF
- [x] Configure WKPDFConfiguration for A4 page size
- [x] Handle both Markdown and HTML documents
- [x] Unit tests with mock WebView

**Performance Requirements**:
- PDF generation < 2 seconds for typical documents
- Support documents up to 100 pages

#### [x] Task 3.2: Create DownloadSaveManager
**Priority**: High  
**Effort**: 1 hour  
**Dependencies**: None  
**Acceptance Criteria**:
- [x] Create DownloadSaveManager class
- [x] Implement saveToDownloads with proper permissions
- [x] Generate unique filenames with timestamps
- [x] Handle Downloads folder access errors
- [x] Unit tests for filename generation

### [x] Phase 4: PDF Export UI Integration (Day 2-3)

#### [x] Task 4.1: Add Export Button to FilePreviewView
**Priority**: High  
**Effort**: 1 hour  
**Dependencies**: None  
**Acceptance Criteria**:
- [x] Add "Export PDF" button to toolbar
- [x] Use SF Symbol "square.and.arrow.up"
- [x] Only enable for Markdown and HTML files
- [x] Follow Apple HIG for toolbar buttons
- [x] Keyboard shortcut: Cmd+Shift+E

#### [x] Task 4.2: Implement PDF Export Flow
**Priority**: High  
**Effort**: 2 hours  
**Dependencies**: Tasks 3.1, 3.2, 4.1  
**Acceptance Criteria**:
- [x] Connect button to PDFExportService
- [x] Show progress sheet during export
- [x] Display success notification with file location
- [x] Show error alert for failures
- [x] Allow cancellation of long exports
- [x] Integration testing

#### [x] Task 4.3: Optimize PDF Rendering
**Priority**: Medium  
**Effort**: 2 hours  
**Dependencies**: Task 4.2  
**Acceptance Criteria**:
- [x] Ensure Mermaid diagrams render in PDF (Note: rendered as code blocks)
- [x] Preserve syntax highlighting (basic code formatting preserved)
- [x] Optimize page breaks for readability (Note: Platform limitation - single page PDFs)
- [x] Add document metadata (title, creation date) (metadata included in HTML)
- [x] Test with various document sizes

### [DEFER TO FUTURE CR ] Phase 5: Testing and Polish (Day 3)

#### [ ] Task 5.1: Comprehensive Testing
**Priority**: High  
**Effort**: 2 hours  
**Dependencies**: All previous tasks  
**Acceptance Criteria**:
- [ ] Manual testing of all workflows
- [ ] Edge case testing (large files, special characters)
- [ ] Performance testing with stress scenarios
- [ ] Accessibility testing with VoiceOver
- [ ] Cross-version testing (macOS 13, 14, 15)

#### [DEFER TO FUTURE CR ] Task 5.2: Documentation Updates
**Priority**: Medium  
**Effort**: 1 hour  
**Dependencies**: Task 5.1  
**Acceptance Criteria**:
- [ ] Update current-features.md
- [ ] Update user documentation
- [ ] Add inline code documentation
- [ ] Create demo video/screenshots

## Known Issues
- Mermaid diagrams not rendered in PDF Export

## Key changes
- Deprecated ContentView() and now use VSCodeStyleExplorer

## Risk Mitigation

### Technical Risks
1. **FSEvents Lag**: Pre-fetch directory contents on hover
2. **Large PDF Memory**: Stream rendering for documents > 50 pages
3. **Permission Errors**: Graceful fallback to save dialog

### Schedule Risks
1. **Mermaid Rendering Issues**: Allocate buffer time in Task 4.3
2. **Complex Edge Cases**: Start testing early in parallel

## Success Metrics

### Functional Success
- [ ] All acceptance criteria met
- [ ] Zero data loss incidents in testing
- [ ] Sub-second response for common operations

### User Experience Success
- [ ] Drag-drop feels native and responsive
- [ ] PDF export completes within user expectations
- [ ] Clear feedback for all operations

### Code Quality Success
- [ ] Test coverage > 80%
- [ ] No memory leaks detected
- [ ] All linting rules pass

## Next Steps

1. Review plan with stakeholders
2. Set up feature branch tracking
3. Begin with Task 1.1 (FileDragDelegate)
4. Daily progress updates in standup
5. Incremental commits with clear messages