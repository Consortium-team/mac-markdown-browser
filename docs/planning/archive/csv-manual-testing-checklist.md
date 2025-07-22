# CSV Manual Testing Checklist

## Date: 2025-07-22
## Feature: CSV Support with Performance Optimization

This checklist covers manual testing for the newly implemented CSV support in MDBrowser.

## Test Files Location
All test files are available in the `test_csvs/` directory:
- `simple.csv` - Basic 5-row CSV with 3 columns
- `complex.csv` - CSV with quoted values, newlines, and special characters  
- `large.csv` - 1000 rows × 5 columns for performance testing
- `wide.csv` - 5 rows × 50 columns for wide table testing
- `tab_separated.tsv` - Tab-delimited file for delimiter testing

## Basic Functionality Tests

### ✅ File Loading and Display
- [ ] Open `simple.csv` in the file browser
- [ ] Verify file shows correct icon (tablecells symbol)
- [ ] Click on file to preview in right pane
- [ ] Verify table displays with proper headers and data
- [ ] Check metadata shows "5 rows × 3 columns"

### ✅ Delimiter Detection
- [ ] Open `simple.csv` (comma-delimited)
  - [ ] Verify delimiter shows as "Comma (,)" in metadata
- [ ] Open `tab_separated.tsv` (tab-delimited)  
  - [ ] Verify delimiter shows as "Tab" in metadata
- [ ] Create a semicolon-separated file and test detection

### ✅ Complex Data Handling
- [ ] Open `complex.csv`
- [ ] Verify quoted values display correctly:
  - [ ] Product names with quotes show properly
  - [ ] Multi-line descriptions render correctly
  - [ ] Commas inside quotes don't break columns
- [ ] Check that special characters display without XSS issues

## Performance Tests

### ✅ Large File Performance
- [ ] Open `large.csv` (1000 rows)
- [ ] Time the loading - should be under 2 seconds
- [ ] Verify virtual scrolling kicks in:
  - [ ] Table uses split header/body layout
  - [ ] Smooth scrolling performance
  - [ ] Memory usage reasonable (check Activity Monitor)
- [ ] Check metadata shows correct row/column count

### ✅ Wide Table Handling  
- [ ] Open `wide.csv` (50 columns)
- [ ] Verify horizontal scrolling works
- [ ] Check that column headers stay aligned with data
- [ ] Verify responsive design maintains readability

## Edit Mode Tests

### ✅ Edit Functionality
- [ ] Open any CSV file
- [ ] Click "Edit" button to enter edit mode
- [ ] Verify split-pane interface appears:
  - [ ] Left side: raw CSV text editor
  - [ ] Right side: formatted table preview
- [ ] Make changes to raw CSV:
  - [ ] Add a new row
  - [ ] Modify existing data
  - [ ] Change delimiter (e.g., comma to semicolon)
- [ ] Verify preview updates in real-time (300ms debounce)

### ✅ Save and Auto-save
- [ ] Make edits and verify save button becomes enabled
- [ ] Save manually using Cmd+S
- [ ] Verify file is updated on disk
- [ ] Test auto-save by waiting 2+ seconds after edit
- [ ] Verify unsaved changes indicator works correctly

## Delimiter Switching

### ✅ Delimiter Change UI
- [ ] Open CSV file with comma delimiter
- [ ] Look for delimiter selector in toolbar/interface
- [ ] Switch between different delimiters:
  - [ ] Comma to Tab
  - [ ] Tab to Semicolon  
  - [ ] Semicolon back to Comma
- [ ] Verify preview updates immediately
- [ ] Check that data parses correctly with new delimiter

## Error Handling

### ✅ Malformed CSV
- [ ] Create CSV with unmatched quotes
- [ ] Create CSV with inconsistent column counts
- [ ] Verify app doesn't crash
- [ ] Check error messages are user-friendly

### ✅ Large File Limits
- [ ] Try opening very large CSV (>50MB)
- [ ] Verify appropriate error message for file size limit
- [ ] Ensure app remains responsive

### ✅ Empty/Invalid Files
- [ ] Open empty CSV file
- [ ] Open non-CSV file with .csv extension
- [ ] Verify graceful error handling

## Integration Tests

### ✅ File Navigation
- [ ] Navigate between CSV and Markdown files
- [ ] Verify correct preview modes for each file type
- [ ] Test favorites with CSV files:
  - [ ] Add CSV file to favorites
  - [ ] Access via keyboard shortcuts (Cmd+1-9)

### ✅ Search Integration
- [ ] If search is implemented, test finding CSV files
- [ ] Verify CSV content doesn't break search functionality

### ✅ Window Management
- [ ] Open CSV file in separate edit window
- [ ] Verify edit window has all CSV features
- [ ] Test multiple CSV files open simultaneously

## Security Tests

### ✅ XSS Prevention
- [ ] Create CSV with HTML content (`<script>`, `<img>` tags)
- [ ] Verify HTML is escaped and not executed
- [ ] Check that JavaScript is disabled in preview

### ✅ File Access Security
- [ ] Verify CSV files respect sandbox permissions
- [ ] Test with files outside accessible directories
- [ ] Ensure proper permission requests

## UI/UX Tests

### ✅ Visual Design
- [ ] Verify dark mode support in CSV preview
- [ ] Check table styling matches app theme
- [ ] Verify responsive table design on different window sizes
- [ ] Test zebra striping and hover effects

### ✅ Accessibility
- [ ] Test keyboard navigation in table
- [ ] Verify screen reader compatibility (if possible)
- [ ] Check color contrast in table cells

### ✅ Apple HIG Compliance
- [ ] Verify toolbar items follow standard conventions
- [ ] Check that keyboard shortcuts are intuitive
- [ ] Ensure standard macOS behaviors (copy, paste, etc.)

## Performance Benchmarks

### ✅ Target Performance Metrics
Record actual performance and compare to targets:

- [ ] Small CSV (100 rows): Load + render < 100ms
- [ ] Medium CSV (1000 rows): Load + render < 500ms  
- [ ] Large CSV (10000 rows): Load + render < 2000ms
- [ ] Memory usage: < 100MB for files under 10MB
- [ ] Scrolling: Maintains 60fps

### ✅ Resource Monitoring
- [ ] Monitor CPU usage during CSV operations
- [ ] Check memory usage with Activity Monitor
- [ ] Verify no memory leaks after closing CSV files
- [ ] Test app responsiveness during large file operations

## Edge Cases

### ✅ Special Characters
- [ ] Unicode characters in CSV
- [ ] Emoji in cell values
- [ ] Different language content
- [ ] Very long cell values (>1000 characters)

### ✅ File System Events
- [ ] Modify CSV file externally while open in app
- [ ] Verify external change detection works
- [ ] Test reload functionality

### ✅ Concurrent Operations
- [ ] Open multiple CSV files simultaneously
- [ ] Edit multiple files at the same time
- [ ] Verify no conflicts or crashes

## Regression Tests

### ✅ Existing Functionality
- [ ] Verify Markdown preview still works
- [ ] Check that other file types are unaffected
- [ ] Test favorites functionality
- [ ] Verify file browser navigation
- [ ] Check that hidden files toggle still works

## Test Results

### Issues Found
- [ ] List any bugs or issues discovered
- [ ] Note performance problems
- [ ] Document any UX concerns

### Performance Results
- [ ] Record actual load times for test files
- [ ] Note memory usage measurements
- [ ] Document any performance regressions

### Overall Assessment
- [ ] CSV feature ready for production: Yes/No
- [ ] Performance targets met: Yes/No
- [ ] Security requirements satisfied: Yes/No
- [ ] User experience acceptable: Yes/No

## Sign-off

**Tester:** ____________________  
**Date:** ____________________  
**Test Environment:** ____________________  
**Overall Result:** PASS / FAIL / NEEDS_WORK

**Notes:**
_Additional comments and observations_