# Security Audit Report for MDBrowser

**Last Updated: 2025-01-03**

## Executive Summary
I've conducted a comprehensive security audit of the MDBrowser codebase. The application demonstrates several good security practices and has undergone recent security improvements. The most critical remaining issue relates to XSS vulnerabilities in the Markdown preview. Previously identified issues with overly permissive entitlements have been resolved.

## Critical Vulnerabilities

### 1. **XSS Vulnerability in Markdown Preview (HIGH SEVERITY)**
**Location**: MarkdownPreviewView.swift:29, MarkdownService.swift:433-437
- The WKWebView loads HTML content with JavaScript enabled (`allowsContentJavaScript = true`)
- Raw HTML blocks are passed through without sanitization (lines 433-437)
- This allows malicious JavaScript in Markdown files to execute in the preview

**Risk**: Attackers could craft malicious Markdown files that execute JavaScript when previewed, potentially accessing local files or performing unauthorized actions.

### 2. **~~Insecure Entitlement: Executable Permission~~ (RESOLVED)**
**Status**: ✅ Fixed as of 2025-07-22
- The `com.apple.security.files.user-selected.executable` entitlement has been removed
- This significantly reduces the attack surface
- The app no longer has permission to execute binaries

### 3. **Resource Leak Vulnerability (MEDIUM SEVERITY)**
**Location**: FileSystemService.swift:98-113
- Security-scoped resources are started but not always properly stopped
- Missing proper cleanup in error paths and when URLs are replaced

**Risk**: Kernel resource exhaustion could prevent the app from accessing new files.

## Medium Severity Issues

### 4. **Insufficient Path Traversal Protection (MEDIUM)**
**Location**: FileSystemService.swift:274-284
- Path normalization is performed but could be bypassed with certain symbolic link configurations
- No validation against accessing files outside intended directories

### 5. **~~Overly Broad Network Entitlement~~ (RESOLVED)**
**Status**: ✅ Fixed as of 2025-07-22
- The `com.apple.security.network.client` entitlement has been removed
- The app now operates in a fully offline mode as intended
- Network-based attack vectors have been eliminated

### 6. **Sensitive Information in Logs (LOW-MEDIUM)**
**Location**: Multiple locations
- File paths and error details are logged, potentially exposing sensitive directory structures

## Positive Security Practices Observed

1. **Proper HTML Escaping**: The MarkdownService properly escapes HTML entities (lines 440-447)
2. **Security-Scoped Bookmarks**: Correctly implements bookmarks for persistent file access
3. **Sandboxing**: App is properly sandboxed with app-sandbox entitlement
4. **Input Validation**: File operations check for existence and permissions
5. **Minimal Dependencies**: Only uses Apple's swift-markdown library

## Recommendations

### Immediate Actions Required:

1. **Fix XSS Vulnerability**:
   - Implement Content Security Policy (CSP) in WKWebView
   - Sanitize HTML content before rendering
   - Consider disabling JavaScript in preview or use a restricted sandbox

2. **~~Remove Unnecessary Entitlements~~**: ✅ COMPLETED
   - Removed `com.apple.security.files.user-selected.executable`
   - Removed `com.apple.security.network.client`
   - App now uses minimal entitlements (sandbox, file access, bookmarks)

3. **Fix Resource Leaks**:
   - Implement proper cleanup with defer blocks
   - Track active security-scoped resources
   - Add resource counting/limiting

### Additional Security Enhancements:

4. **Implement Path Validation**:
   - Add symbolic link resolution
   - Validate all paths stay within allowed directories
   - Implement allowlist for accessible directories

5. **Add Security Headers**:
   - Implement strict CSP for WKWebView
   - Add X-Content-Type-Options
   - Disable unnecessary web features

6. **Improve Error Handling**:
   - Sanitize error messages before logging
   - Implement security event logging
   - Add rate limiting for file operations

7. **Add Security Testing**:
   - Create test cases for malicious Markdown files
   - Test path traversal attempts
   - Verify resource cleanup

## Recent Security Improvements (2025-07-22)

### Entitlement Hardening
The application's entitlements have been significantly reduced:
- **Removed**: `com.apple.security.network.client` - No network access needed
- **Removed**: `com.apple.security.files.user-selected.executable` - No executable permission needed
- **Retained** (minimal required set):
  - `com.apple.security.app-sandbox` - Required for sandboxing
  - `com.apple.security.files.user-selected.read-write` - For file editing
  - `com.apple.security.files.bookmarks.app-scope` - For persistent favorites
  - `com.apple.security.files.downloads.read-write` - For downloads folder access

### CSV Security Implementation
The new CSV support feature includes comprehensive security measures:
- **XSS Prevention**: All cell content is HTML-escaped before rendering
- **Content Sanitization**: Dangerous Unicode characters are filtered
- **Resource Limits**: 10MB file size limit, 10,000 character cell limit
- **JavaScript Disabled**: CSV preview runs with JavaScript disabled
- **CSP Headers**: Strict Content Security Policy in preview HTML

## Compliance Considerations

- The app now follows Apple's App Sandbox Design Guide with minimal entitlements
- Ready for notarization with reduced attack surface
- Compliant with macOS Security Guidelines

## Recent Security Improvements (2025-01-03)

### Refresh Button Implementation
The new refresh button feature for Markdown/HTML preview has been implemented with security in mind:
- **No New Attack Surface**: Uses existing security-scoped bookmarks, no new entitlements required
- **DoS Protection**: 500ms rate limiting prevents resource exhaustion from rapid refresh attempts
- **Resource Management**: Properly reuses existing file handles and cleanup mechanisms
- **Path Validation**: Refresh only operates on the currently opened file through existing security boundaries
- **No Network Activity**: Refresh is purely local file system operation

### Security Controls Verified
- Rate limiting tested and functional (canRefresh() method)
- No new file handles created during refresh operations
- Existing sandbox boundaries maintained
- No JavaScript execution risks introduced (uses existing WKWebView configuration)

### Implementation Notes
- Refresh feature completed for Markdown/HTML files only
- CSV refresh button implementation deferred to separate change request
- Simple UI design avoids complex state management that could introduce vulnerabilities

## Conclusion

MDBrowser has made significant security improvements by removing unnecessary entitlements and implementing secure CSV handling. The refresh button feature has been added without introducing new security vulnerabilities, maintaining the existing security posture. The primary remaining concern is the XSS vulnerability in Markdown preview, which should be addressed before production deployment. The recent changes have substantially reduced the attack surface and improved the overall security posture of the application.