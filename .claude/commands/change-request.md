# Change Request Command

## Purpose
Captures new feature requests or modifications in a formal document that serves as the source of truth for what needs to be built. This command applies product thinking to ensure features align with user value, product goals, and technical feasibility. Use this at the very beginning when a new idea or requirement is presented.

Create a formal change request document for $ARGUMENTS using the product manager persona with integrated security analysis.

## Arguments
- If provided: Creates new change request for the specified feature
- If not provided: This command creates NEW change requests, so arguments are required

## Process

1. **Load Product Manager Persona**
   - Reference `/docs/personas/product-manager.md`
   - Apply product thinking to the request

2. **Load Cybersecurity Specialist Persona**
   - Reference `/docs/personas/cybersecurity-specialist.md`
   - Apply security analysis to identify risks early

3. **Analyze**
   - Ask user any clarifying questions if needed
   - If additional insights needed, conduct research via websearch using reputable sources
   - Identify security implications of the feature

4. **Create Change Request Document**
   - Save to `/docs/feedback/CHANGE REQUEST: [feature-name].md`
   - Include:
     - Feature overview and objectives
     - Impact on User Journeys
     - User value proposition
     - Success metrics
     - Technical considerations
     - Security considerations (NEW)
     - Privacy impact assessment (NEW)
     - Monetization opportunities
     - Priority level (P0-P3)

5. **Format Template**
   ```markdown
   # CHANGE REQUEST: [Feature Name]
   
   **Date**: [Current Date]
   **Priority**: P[0-3]
   **Requested By**: [User]
   **Security Review**: [Required/Optional]
   
   ## Overview
   [2-3 sentence description]
   
   ## User Value
   - [Benefit 1]
   - [Benefit 2]
   
   ## Success Metrics
   - [Metric 1 with target]
   - [Metric 2 with target]
   
   ## Technical Scope
   - [Component 1]
   - [Component 2]
   
   ## Security Considerations
   ### Sandboxing Impact
   - [Does this feature require new entitlements?]
   - [Does it affect existing sandboxing restrictions?]
   
   ### Data Protection Requirements
   - [What file access is needed?]
   - [How will security-scoped bookmarks be used?]
   - [Local storage requirements?]
   
   ### Potential Security Risks
   - [File system access risks]
   - [Markdown rendering vulnerabilities]
   - [Third-party integration risks]
   
   ### Privacy Impact
   - Local Data Storage: [What data is stored locally]
   - File Access Patterns: [What directories/files accessed]
   - No Cloud/Network: [Confirm no external data transmission]
   
   ## macOS Integration
   [How this leverages native macOS capabilities]
   
   ## Security Requirements for Implementation
   - [Required security controls]
   - [Security testing needed]
   - [Compliance checkpoints]
   ```

## Security Integration

The cybersecurity specialist persona will:
- Identify features requiring new entitlements or file system access
- Flag potential rendering vulnerabilities (XSS in Markdown/HTML)
- Assess sandboxing implications
- Recommend security controls before implementation begins
- Determine if feature requires security-scoped bookmark handling

## Usage
`/change-request add PDF export functionality for markdown files`