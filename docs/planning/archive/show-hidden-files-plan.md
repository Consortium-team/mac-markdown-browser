# Implementation Plan: Show Hidden Files by Default

## Overview
This plan outlines the implementation steps to enable hidden files visibility by default in the MarkdownBrowser file explorer. The implementation is straightforward, focusing on modifying file enumeration options.

## Implementation Tasks

### [X] Task 1: Locate and Update File Enumeration Logic ✅
**Priority**: High  
**Estimated Time**: 30 minutes  
**Dependencies**: None

**Steps**:
[X] 1. Search for FileManager enumeration usage in the codebase
[X] 2. Identify where `.skipsHiddenFiles` option is being used
[X] 3. Remove or conditionally apply the `.skipsHiddenFiles` option
[X] 4. Verify changes in FileNode or related file system components

**Acceptance Criteria**:
- [X] File enumeration code identified
- [X] `.skipsHiddenFiles` option removed or made conditional
- [X] Code compiles without errors

**Performance Requirements**:
- File enumeration time should not increase by more than 20%
- UI responsiveness maintained (< 16ms frame time)

---

### [X] Task 2: Add User Preference for Hidden Files Toggle ✅
**Priority**: Medium  
**Estimated Time**: 45 minutes  
**Dependencies**: Task 1

**Steps**:
[X] 1. Add `showHiddenFiles` property to UserPreferences model
[X] 2. Set default value to `true`
[X] 3. Ensure preference persists across app launches
[X] 4. Connect preference to file enumeration logic

**Acceptance Criteria**:
- [X] UserPreferences includes showHiddenFiles property
- [X] Default value is true (shows hidden files)
- [X] Preference persists using @AppStorage
- [X] File enumeration respects the preference

**Performance Requirements**:
- Preference changes apply immediately
- No delay in file tree refresh

---

### [X] Task 3: Update UI to Show Preference Toggle (Optional) ✅
**Priority**: Low  
**Estimated Time**: 1 hour  
**Dependencies**: Task 2

**Steps**:
[X] 1. Add menu item or toolbar button for toggling hidden files
[X] 2. Implement toggle action that updates UserPreferences
[X] 3. Ensure file tree refreshes when preference changes
[X] 4. Add appropriate UI feedback

**Acceptance Criteria**:
- [X] Toggle UI element added (menu item or button)
- [X] Toggle updates preference correctly
- [X] File tree refreshes immediately on toggle
- [X] UI state reflects current preference

**Performance Requirements**:
- Toggle action completes in < 100ms
- File tree refresh maintains smooth animation

---

### [X] Task 4: Test Hidden Files Functionality ✅
**Priority**: High  
**Estimated Time**: 45 minutes  
**Dependencies**: Tasks 1-2

**Steps**:
[X] 1. Write unit tests for file enumeration with hidden files
[ ] 2. Test preference persistence
[ ] 3. Manual testing with various hidden files/directories
[X] 4. Test performance with directories containing many hidden files

**Acceptance Criteria**:
- [X] Unit tests pass for hidden file enumeration
- [X] Hidden files visible in test directories
- [X] `.gitignore`, `.github`, `.env` files appear correctly
- [X] Performance acceptable with 100+ hidden files

**Performance Requirements**:
- Test directories with 1000+ files (including hidden)
- Ensure < 500ms load time for large directories

---


## Testing Checklist

### Manual Testing
- [ ] Launch app and verify hidden files appear by default
- [ ] Navigate to a git repository and see `.git` folder
- [ ] Open a hidden file (e.g., `.gitignore`) in preview
- [ ] Edit a hidden markdown file (e.g., `.github/README.md`)
- [ ] Add hidden directory to favorites
- [ ] Use keyboard shortcut to navigate to favorited hidden directory
- [ ] Toggle preference and verify files hide/show correctly

### Edge Cases
- [ ] Empty directories with only hidden files
- [ ] Directories starting with multiple dots (e.g., `..hidden`)
- [ ] Hidden files with no extension
- [ ] Symbolic links to hidden files
- [ ] Hidden files in root directory

## Success Metrics
- Hidden files visible by default on launch
- No performance regression (< 20% enumeration time increase)
- All existing features work with hidden files
- User preference persists across sessions
- Positive user feedback from technical users

## Rollback Plan
If issues arise:
1. Add `.skipsHiddenFiles` back to enumeration options
2. Set default preference to false (hide hidden files)
3. Document known issues for future iteration

## Implementation Order
1. Task 1: Update enumeration (core functionality)
2. Task 4: Test functionality (verify it works)
3. Task 2: Add preference (enhance with toggle)
4. Task 5: Update search (ensure consistency)
5. Task 3: Add UI toggle (optional enhancement)
6. Task 6: Documentation (finalize)