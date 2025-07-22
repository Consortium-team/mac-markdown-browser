# Design & Plan Command

## Purpose
Transforms a change request into detailed technical design and actionable implementation plan. This command bridges product requirements with technical execution by creating comprehensive documentation that guides development. Use this after creating a feature branch to plan the implementation before writing any code.

Create software design document and implementation plan for $ARGUMENTS using product, technical, and security personas.

## Arguments
- If provided: Use the specified feature name
- If not provided: Check `/docs/feedback/` for a single change request
  - If exactly one change request found: Use it
  - If zero found: Error - "No change request found in /docs/feedback/"
  - If multiple found: Error - "Multiple change requests found. Please specify which one."

## Process

1. **Load All Personas**
   - Product Manager: `/docs/personas/product-manager.md`
   - Technical Lead: `/docs/personas/tech-lead.md`
   - Cybersecurity Specialist: `/docs/personas/cybersecurity-specialist.md`

2. **Research**
   - Use Context7 if I need to look up APIs, libraries, or packages
   - Research reputable online sources for best practices, design ideas, and examples for how others approached adding similar functionality
   - Research security best practices for the chosen technologies

3. **Perform Threat Modeling**
   - Create threat model for macOS app sandbox boundaries
   - Identify file system access patterns and risks
   - Map potential rendering vulnerabilities (Markdown/HTML)
   - Define security controls for each threat

4. **Create Design Document**
   - Save to `/docs/development/[feature-name]-design.md`
   - Include:
     - Feature overview (product perspective)
     - Technical architecture (with Mermaid diagrams)
     - Security architecture (with threat model diagram)
     - SwiftUI component design
     - File system access patterns with security-scoped bookmarks
     - State management approach with @Published properties
     - UI/UX considerations following Apple HIG
     - Performance requirements for native app
     - Security requirements and sandboxing controls
     - Local data storage considerations

5. **Create Implementation Plan**
   - Save to `/docs/planning/[feature-name]-checklist.md`
   - Ordered task list with:
     - Clear acceptance criteria
     - Security testing checkpoints
     - Technical dependencies
     - Testing requirements (including security tests)
     - Estimated complexity (S/M/L)

6. **Design Document Template**
   ```markdown
   # [Feature Name] Design Document
   
   ## Overview
   [Product perspective - why this feature]
   
   ## Technical Architecture
   ```mermaid
   [Architecture diagram]
   ```
   
   ## Security Architecture
   ### Threat Model
   ```mermaid
   flowchart LR
     A[User] -->|Local Files| B[File System]
     B -->|Security Scoped| C[FileSystemService]
     C -->|Swift Markdown| D[MarkdownService]
     D -->|HTML| E[WKWebView]
     
     B -.->|Threat: Path Traversal| B
     C -.->|Threat: Resource Leak| C
     D -.->|Threat: XSS| D
     E -.->|Threat: Script Injection| E
   ```
   
   ### Security Controls
   - Sandboxing: [Entitlements configuration]
   - File Access: [Security-scoped bookmarks]
   - HTML Sanitization: [Markdown rendering controls]
   - WebView Security: [CSP and JavaScript restrictions]
   - Resource Management: [Proper cleanup of security-scoped resources]
   
   ## Implementation Details
   ### SwiftUI Components
   - View hierarchy and data flow
   - @StateObject and @ObservedObject usage
   - Environment values propagation
   
   ### File System Integration
   - FSEvents monitoring setup
   - Security-scoped bookmark persistence
   - Lazy loading for performance
   
   ### Markdown Rendering
   - swift-markdown integration
   - HTML generation pipeline
   - Mermaid.js security considerations
   
   ## Privacy Considerations
   - Local-only operation (no network calls)
   - UserDefaults for preferences
   - No telemetry or analytics
   
   ## Security Testing Strategy
   - SAST: [Static analysis tools to run]
   - DAST: [Dynamic testing approach]
   - Penetration Testing: [Scope and timing]
   
   ## Rollout Plan
   - Security Review Gates: [When reviews occur]
   - Monitoring: [Security metrics to track]
   ```

7. **Verification Requirements**
   
   When creating checklists, explicitly mark which tasks require human verification:
   
   **Tasks that typically REQUIRE HUMAN VERIFICATION:**
   - Visual UI/UX verification (button placement, colors, spacing)
   - Keyboard shortcut functionality (Cmd+1-9 for favorites)
   - Drag and drop behavior for favorites
   - File picker dialog interaction
   - Window resizing and split view behavior
   - Dark mode appearance
   - Accessibility with VoiceOver
   - Performance with large directories (1000+ files)
   - App bundle signing and notarization
   
   **Tasks that CAN BE AUTOMATED:**
   - Unit tests for models and services
   - File system operations testing
   - Build processes (swift build)
   - SwiftLint formatting checks
   - Markdown parsing tests
   - CSV parsing tests
   - Security-scoped bookmark tests
   
   **Marking Human Verification:**
   ```markdown
   - [ ] Task requiring human check
     - Acceptance: [criteria]
     - **⚠️ REQUIRES HUMAN VERIFICATION**: [What to check]
   ```

8. **Checklist Template**
   ```markdown
   # [Feature Name] Implementation Checklist
   
   ## Security Foundation
   - [ ] Threat model reviewed and approved (Size: S)
     - Acceptance: All STRIDE threats addressed
   - [ ] Security controls documented (Size: S)
     - Acceptance: Controls map to each threat
   
   ## Implementation Tasks
   - [ ] Task 1: File Browser UI (Size: S)
     - [ ] Implement directory tree view
       - Acceptance: Folders expand/collapse correctly
       - Security Test: Verify sandboxed paths only
     - [ ] Add file type icons
       - Acceptance: Correct icons for .md, .csv, .html
       - **⚠️ REQUIRES HUMAN VERIFICATION**: Visual appearance
     - Dependencies: DirectoryNode model
   
   - [ ] Task 2: Markdown Preview (Size: M)
     - [ ] Implement WebView with CSP
       - Acceptance: Markdown renders as HTML
       - Security Test: XSS attempts blocked
     - [ ] Add synchronized scrolling
       - Acceptance: Editor and preview scroll together
       - **⚠️ REQUIRES HUMAN VERIFICATION**: Smooth scrolling behavior
     - Tests: Unit tests for HTML generation, UI tests for rendering
   
   ## Security Verification
   - [ ] Run SAST scan (Size: S)
     - Acceptance: No high/critical findings
   - [ ] Perform security code review (Size: M)
     - Acceptance: Reviewed by security specialist
   - [ ] Execute security test suite (Size: M)
     - Acceptance: All security tests pass
   ```

## Security Integration

The cybersecurity specialist persona will:
- Perform threat modeling for macOS app sandbox
- Define security controls for file system access
- Create security test cases for rendering vulnerabilities
- Review Swift package dependencies for vulnerabilities
- Ensure local-only data handling
- Add sandboxing verification checkpoints

## Usage
`/design-plan pdf-export`