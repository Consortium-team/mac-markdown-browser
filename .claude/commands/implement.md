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
   - **IMPORTANT**: TodoWrite is for tracking during implementation
   - **IMPORTANT**: The actual checklist file in `/docs/planning/[feature]-checklist.md` is the source of truth and must be updated
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
   **If task has "⚠️ REQUIRES HUMAN VERIFICATION":**
   - Complete the implementation
   - Run any automated tests you can
   - **STOP and inform the user**: "This task requires human verification: [what to check]"
   - Wait for user confirmation before marking complete
   - Do NOT mark as complete without user confirmation
   
   **If task can be automated:**
   - **VERIFY: Actually test the implementation**
     - For SwiftUI views: Build and verify they render without crashes
     - For file operations: Test with actual files and verify correct behavior
     - For UI components: Verify they respond to user interaction
     - For directory operations: Test with nested folders and verify traversal
     - **For file access**: Test with sandboxed/non-sandboxed paths
     - **For WebView content**: Test with malicious HTML/script injection
     - Document the exact commands used and outputs received
   - Complete: After successful verification:
     1. Mark as completed in TodoWrite
     2. **UPDATE THE CHECKLIST FILE**: Edit `/docs/planning/[feature]-checklist.md`
        - Change `[ ]` to `[x]` for this task
        - Add ✅ emoji after the task description
        - Add verification notes with actual output
   - If verification fails: Keep as in_progress and document the issue in BOTH places

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

**⚠️ CRITICAL: VERIFICATION IS MANDATORY ⚠️**
   
   **STOP! Before marking ANY task as complete, you MUST:**
   1. Run an actual command that tests the functionality
   2. See the expected output with your own "eyes"
   3. Document the exact command and output
   
   **If you cannot run a verification command, the task is NOT complete.**
   **If you did not see actual output, the task is NOT complete.**
   **If you're assuming it works, the task is NOT complete.**
   
   **NEVER mark a task complete without verification:**
   - **SwiftUI Views**: Must render without runtime errors
   - **File Operations**: Must handle both success and error cases
   - **WebView Tasks**: Must render content without JavaScript errors
   - **Build Tasks**: Must complete without warnings/errors
   - **Test Tasks**: Must see all tests passing
   - **Security Tasks**: Must verify sandboxing works
   
   **Example of WRONG behavior:**
   ```
   ❌ "I added the refresh button to Explorer" → Mark as complete
   ❌ "The file preview should work now" → Mark as complete
   ❌ "I configured the entitlements" → Mark as complete
   ```
   
   **Example of CORRECT behavior:**
   ```
   ✅ "I added the refresh button to Explorer"
   → Run: swift build && swift run
   → Click refresh button, add a file in Finder
   → Click refresh again, see new file appear
   → NOW mark as complete
   ```
   
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
   **⚠️ CRITICAL: TWO CHECKLISTS TO UPDATE ⚠️**
   
   **There are TWO task tracking systems you MUST update:**
   1. **TodoWrite Tool**: For real-time progress tracking during implementation
   2. **Checklist File**: The actual markdown file in `/docs/planning/[feature]-checklist.md`
   
   **⚠️ BEFORE MARKING ANY TASK COMPLETE ⚠️**
   
   Ask yourself these questions:
   1. Did I run a command to verify this works? (If no, STOP)
   2. Did I see actual output proving it works? (If no, STOP)
   3. Can I paste the exact command and output? (If no, STOP)
   
   **TodoWrite Rules (Implementation Tracking):**
   - A task stays "in_progress" until verification succeeds
   - If verification fails, document the failure and keep as "in_progress"
   - ONLY mark "completed" after seeing success output
   
   **Checklist File Update Rules (Source of Truth):**
   - **MANDATORY**: Update the actual checklist file in `/docs/planning/[feature]-checklist.md`
   - Change `[ ]` to `[x]` for completed tasks
   - Update checklist file with ✅ emoji ONLY after verification
   - Add verification notes showing exact test performed
   - Include the actual output you observed
   - **Document security tests performed**
   - Document blockers or issues
   - **Update security assessment if new risks found**
   
   **BOTH MUST BE UPDATED**: When you complete a task:
   1. Mark it complete in TodoWrite
   2. Update the checkbox to `[x]` in `/docs/planning/[feature]-checklist.md`
   3. Add ✅ emoji and verification notes to the checklist file
   
   **ENFORCEMENT**: If you mark something complete without verification output, you are violating the core principle of this workflow

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