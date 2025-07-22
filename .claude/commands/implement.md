# Implementation Command

## Purpose
Executes the implementation plan by systematically working through each task, writing code, and tests while maintaining alignment with both product and technical requirements. This command uses TodoWrite to track progress and ensures quality through testing at each step. Use this after completing the design and planning phase.

Implement $ARGUMENTS following the plan with integrated security verification.

## Arguments
- If provided: Use the specified feature name
- If not provided: Check `/docs/feedback/` for a single change request
  - If exactly one change request found: Use it
  - If zero found: Error - "No change request found in /docs/feedback/"
  - If multiple found: Error - "Multiple change requests found. Please specify which one."

## Implementation Process

1. **Pre-Implementation Setup**
   - Load product manager from `/docs/personas/product-manager.md`
   - Load technical lead from `/docs/personas/tech-lead.md`
   - Load cybersecurity specialist from `/docs/personas/cybersecurity-specialist.md`
   - Review checklist in `/docs/planning/[feature]-checklist.md`
   - Review design in `/docs/development/[feature]-design.md`
   - Review security requirements from design document
   - Verify on correct feature branch
   - Use TodoWrite to load tasks from checklist
   - Use Context7 if you need to look up APIs, libraries, or packages
   - Research reputable online sources for best practices and examples for similar functionality

2. **Security Pre-Implementation Checks**
   - Review Package.swift dependencies
   - Verify sandboxing entitlements are minimal
   - Check for security updates to Swift packages
   - Review Apple security guidelines for macOS apps

3. **Development Workflow**
   - Work through checklist tasks in order
   - Mark each task as in_progress when starting
   - Follow technical lead's architecture patterns
   - Apply product manager's UX priorities
   - **Apply security specialist's controls at each step**
   - Use Context7 MCP for all API documentation
   - Use WebSearch for current best practice solutions when encountering errors

4. **For Each Task**
   - Start: Mark as in_progress in TodoWrite
   - **Security Check**: Review security requirements for this component
   - Implement: Follow design document with security controls
   - **Security Scan**: Run automated security checks
   - Test: Write tests as specified in checklist
   - **Security Test**: Verify security controls work
   - **VERIFY: Actually test the implementation**
     - For servers: Start them and verify they run
     - For endpoints: Make actual HTTP requests and verify responses
     - For UI components: Verify they render without errors
     - For database operations: Test connections and queries
     - **For auth**: Test with valid/invalid tokens
     - **For inputs**: Test with malicious payloads
     - Document the exact commands used and outputs received
   - Complete: ONLY mark as completed after successful verification
   - If verification fails: Keep as in_progress and document the issue

5. **Code Standards with Security**
   - Swift strict type safety
   - Comprehensive error handling with proper user messaging
   - SwiftUI best practices and MVVM architecture
   - Proper memory management with weak references
   - Performance optimization (sub-100ms UI response)
   - No print statements with file paths in release
   - **Security-scoped bookmark proper cleanup**
   - **HTML content sanitization for WebView**
   - **Path validation for file operations**

6. **Security Verification Checkpoints**
   ```bash
   # After implementing file operations
   swift test --filter FileSystemServiceTests
   # Verify: All file access tests pass
   
   # After implementing WebView rendering
   swift test --filter MarkdownPreviewTests
   # Verify: XSS prevention tests pass
   
   # Check entitlements
   codesign -d --entitlements - DerivedData/.../MarkdownBrowser.app
   # Verify: Only necessary entitlements present
   
   # Run app in sandbox
   swift run
   # Verify: No sandbox violations in Console.app
   ```

7. **Verification Requirements**
   **NEVER mark a task complete without verification:**
   - **SwiftUI Views**: Must render without runtime errors
   - **File Operations**: Must handle both success and error cases
   - **WebView Tasks**: Must render content without JavaScript errors
   - **Build Tasks**: Must complete without warnings/errors
   - **Test Tasks**: Must see all tests passing
   - **Security Tasks**: Must verify sandboxing works
   
   **Security Verification Examples**:
   ```bash
   # Test file access outside sandbox
   # In app, try to access ~/Documents without permission
   # Verify: Access denied error shown
   
   # Test malicious Markdown
   # Create test.md with: <script>alert('XSS')</script>
   # Verify: Script doesn't execute in preview
   
   # Test resource cleanup
   # Open many directories rapidly
   # Verify: No "too many files" errors
   ```

8. **Quality Assurance with Security**
   ```bash
   # Run after each major task
   swift test
   swift build --warnings-as-errors
   
   # Run security checks
   # Check for hardcoded paths
   grep -r "/Users/" . --include="*.swift"
   
   # Run before marking feature complete
   swift build -c release
   
   # Verify sandboxing
   codesign --verify --deep --strict MarkdownBrowser.app
   ```

9. **Progress Tracking**
   - Update checklist file with ✅ ONLY after verification
   - Add verification notes showing exact test performed
   - **Document security tests performed**
   - Document blockers or issues
   - Keep TodoWrite in sync
   - **Update security assessment if new risks found**
   - **Golden Rule**: If you didn't test it (including security), it's not complete

## Security Integration

The cybersecurity specialist persona will:
- Review code for security vulnerabilities during implementation
- Ensure sandboxing controls are properly implemented
- Run security tests at defined checkpoints
- Verify no hardcoded file paths
- Check for rendering vulnerabilities (XSS)
- Validate HTML sanitization in WebView
- Ensure proper resource cleanup

## Verification Principle
"Trust, but verify" - Every implementation must be tested with actual commands and documented outputs. Security controls must be verified to work as designed. No assumptions about functionality or security without empirical evidence.

## Usage
`/implement pdf-export`