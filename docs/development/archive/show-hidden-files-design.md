## Technical Design: Show Hidden Files by Default

### Problem Statement
The current file browser implementation filters out hidden files (files and directories starting with a dot) by default. Technical users working with development projects need visibility of these files to access configuration files like `.gitignore`, `.env`, `.github` directories, and other dot files that are critical to their workflows.

### Proposed Architecture
The solution involves modifying the file enumeration logic in the existing `FileNode` and related components to include hidden files by default. This is a configuration change rather than an architectural change, leveraging Swift's `FileManager.DirectoryEnumerationOptions`.

### Implementation Approach

1. **Update FileNode Enumeration Logic**
   - Modify the file enumeration in `FileNode` to remove the `.skipsHiddenFiles` option
   - Currently using `FileManager.DirectoryEnumerationOptions` with `.skipsHiddenFiles`
   - Change to enumerate all files including hidden ones

2. **Add User Preference for Toggle (Optional Enhancement)**
   - Add a boolean property to `UserPreferences` for `showHiddenFiles`
   - Default value: `true` (showing hidden files)
   - Allow users to toggle this preference in the UI

3. **Update File Filtering Logic**
   - Ensure search functionality includes hidden files
   - Update any file filtering operations to respect the hidden files setting

### API Design

#### UserPreferences Extension
```swift
extension UserPreferences {
    @AppStorage("showHiddenFiles") var showHiddenFiles: Bool = true
}
```

#### FileNode Enumeration Update
```swift
// Current approach (likely):
let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

// New approach:
let options: FileManager.DirectoryEnumerationOptions = preferences.showHiddenFiles ? 
    [.skipsPackageDescendants] : 
    [.skipsHiddenFiles, .skipsPackageDescendants]
```

### Data Flow
1. User launches application
2. FileNode enumerates directories without `.skipsHiddenFiles` option
3. Hidden files appear in the file tree view
4. Optional: User can toggle preference to hide/show hidden files
5. File tree refreshes based on preference change

### Error Handling Strategy
- No new error cases introduced
- Existing file access error handling remains sufficient
- Security-scoped bookmarks continue to work with hidden files

### Performance Considerations
- **Expected Impact**: Minimal performance impact
- **File Count**: Hidden files typically add 10-20% more files to enumerate
- **Lazy Loading**: Existing lazy loading mechanism handles additional files
- **Memory**: Negligible increase due to additional FileNode instances

### Testing Strategy

#### Unit Tests
- Test FileNode enumeration includes hidden files
- Test UserPreferences persistence for showHiddenFiles setting
- Test toggle functionality updates file tree correctly

#### Integration Tests
- Verify hidden files appear in UI
- Test navigation to hidden directories
- Verify favorites work with hidden directories

#### UI Tests
- Test hidden files are visible by default
- Test preference toggle (if implemented)
- Verify keyboard shortcuts work with hidden directories

### Security Considerations
- Hidden files often contain sensitive information (API keys, tokens)
- No changes to security model - files are already accessible via system
- Security-scoped bookmarks work identically for hidden files
- Users are technical professionals expected to handle sensitive files responsibly

### Compatibility
- No breaking changes to existing functionality
- All existing features continue to work
- Hidden files integrate seamlessly with favorites, editing, and preview features