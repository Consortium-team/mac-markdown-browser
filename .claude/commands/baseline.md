# Baseline Command

## Purpose
Provides a comprehensive understanding of the current system state including features, architecture, and active development work. This command helps establish context before making changes or when returning to the project after time away. Use this whenever you need to understand what exists before planning new work.

Review current features and architecture to establish context for informed decisions.

## Arguments
- `--security` - Include full security posture review (recommended before starting new features)
- No arguments - Quick baseline without security check (useful during implementation)

## Process

1. **Review Current Features**
   - Read `/docs/requirements/current-features.md`
   - Summarize key functionality
   - Note recent changes

2. **Analyze Architecture**
   - Read `/docs/development/current-architecture.md`
   - Review technology stack
   - Understand component relationships
   - Note integration points

3. **Security Posture Review** (Only if --security flag is provided)
   - Load cybersecurity specialist from `/docs/personas/cybersecurity-specialist.md`
   - Read `/docs/security/current-security-assessment.md`
   - Check for outstanding security issues
   - Review implemented security controls
   - Note any pending security tasks
   - Identify security debt or risks

4. **Check Active Work**
   - List any open change requests in `/docs/feedback/`
   - Review in-progress work in `/docs/planning/`
   - Check current git branch
   - Note any security-related tasks in progress

5. **Mac App Specific Understanding**
   - Review sandboxing configuration in entitlements
   - Note file system access patterns
   - Identify security-scoped bookmark usage

6. **Dependency Security Check** (Only if --security flag is provided)
   - Review Package.swift for known vulnerabilities
   - Note any outdated Swift packages with security patches
   - Check for macOS security advisories

7. **Output Summary**
   - Current feature set overview
   - Architecture highlights
   - **Security status summary** (Only if --security flag is provided)
     - Overall risk level
     - Outstanding vulnerabilities
     - Implemented controls
     - Sandboxing compliance
   - Active development items
   - Key technical constraints
   - Recent builds/releases
   - **Security recommendations** for upcoming work (Only if --security flag is provided)

## Security Integration

The cybersecurity specialist persona will:
- Assess current security posture before new development
- Identify security debt that should be addressed
- Review authentication and authorization state
- Check for unresolved security findings
- Provide context on security controls in place
- Highlight security considerations for active work

## Usage
- `/baseline` - Quick context review without security check (use during implementation)
- `/baseline --security` - Full review including security posture (use before new features)

## Examples
```
# Quick baseline during implementation
/baseline

# Full baseline before starting a new feature
/baseline --security
```