# Security Check Command

## Purpose
Performs a comprehensive security assessment of the codebase using the cybersecurity specialist persona. This command analyzes the current implementation for vulnerabilities, reviews security controls, and maintains an up-to-date security assessment document. Use this command regularly to ensure the application maintains strong security posture and compliance with security best practices.

## Process

1. **Load Security Persona**
   - Apply the cybersecurity specialist persona from `/docs/personas/cybersecurity-specialist.md`
   - Adopt the security-first mindset and assessment methodology

2. **Codebase Security Analysis**
   - Scan for rendering vulnerabilities (XSS in Markdown/HTML)
   - Review file system access and path validation
   - Check for hardcoded paths or sensitive data exposure
   - Analyze WebView security configuration
   - Examine sandboxing implementation
   - Review Swift package dependencies for vulnerabilities

3. **Architecture Security Review**
   - Evaluate macOS sandbox boundaries
   - Assess security-scoped bookmark implementation
   - Review resource management and cleanup
   - Check entitlements configuration
   - Analyze file monitoring (FSEvents) security

4. **macOS-Specific Threat Assessment**
   - Check for path traversal vulnerabilities
   - Review WebView Content Security Policy
   - Assess resource exhaustion risks
   - Evaluate local storage security

5. **Compliance and Privacy Review**
   - Local-only data verification
   - UserDefaults privacy review
   - No network transmission confirmation
   - File access logging review

6. **Third-Party Risk Assessment**
   - Review Swift package dependencies
   - Check for outdated packages with security issues
   - Assess Mermaid.js CDN security implications

7. **Generate/Update Security Assessment**
   - Create or update `/docs/security/current-security-assessment.md`
   - Include executive summary with risk levels
   - Document specific vulnerabilities found
   - Provide prioritized remediation recommendations
   - Include code examples for fixes where applicable
   - Add testing recommendations
   - Update compliance status

8. **Research Current Threats**
   - Check Apple security updates for macOS
   - Review recent macOS app vulnerabilities
   - Search for WebKit/WKWebView vulnerabilities
   - Include relevant CVEs for Swift packages

## Output Format

The command creates/updates a structured security assessment following this format:

```markdown
# Security Assessment - MDBrowser
Generated: [Date]
Assessment Type: [Routine/Post-Implementation/Pre-Release]

## Executive Summary
- Overall Risk Level: [Critical/High/Medium/Low]
- Key Findings: [Bullet list of 3-5 major findings]
- Sandboxing Status: [Compliant/Issues Found]
- Immediate Actions Required: [Yes/No with count]

## Critical Findings
[Issues requiring immediate attention]

## High Priority Findings
[Issues to address within 7 days]

## Medium Priority Findings
[Issues to address within 30 days]

## Low Priority Findings
[Issues to track for future sprints]

## Positive Security Observations
[Good practices identified]

## Remediation Roadmap
[Prioritized list with effort estimates]

## Testing Recommendations
[Specific security tests to implement]

## Next Assessment
Recommended Date: [Date based on findings]
Focus Areas: [Specific areas to review]
```

## Usage Examples

- `/security-check` - Perform full security assessment
- `/security-check --focus webview` - Focus on WebView/rendering security
- `/security-check --focus filesystem` - Focus on file system access
- `/security-check --sandbox` - Emphasize sandbox compliance
- `/security-check --quick` - Quick scan for critical issues only

## Integration Points

- Run after major feature implementations
- Include in pre-release checklist
- Schedule monthly routine assessments
- Trigger after dependency updates
- Use findings for sprint planning

## Success Criteria

- All critical vulnerabilities documented with fixes
- Clear prioritization of security issues
- Actionable remediation steps provided
- Compliance gaps identified
- Security trends tracked over time