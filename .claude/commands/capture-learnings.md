# Capture Learnings Command

## Purpose
Finalizes the development cycle by updating all documentation to reflect implemented changes and archiving completed work. This command ensures knowledge is preserved, the system stays documented, and prepares everything for the pull request. Use this after implementation is complete and tested.

Update documentation, security assessments, and archive completed work for $ARGUMENTS.

## Arguments
- If provided: Use the specified feature name
- If not provided: Check `/docs/feedback/` for a single change request
  - If exactly one change request found: Use it
  - If zero found: Error - "No change request found in /docs/feedback/"
  - If multiple found: Error - "Multiple change requests found. Please specify which one."


 **Context updating**: Update all relevant documentation to reflect the changes:
    - **IMPORTANT**: First check the system date (shown in environment info) before adding any timestamps
    - `/docs/requirements/current-features.md` - Update with new features/changes
    - `/docs/development/current-architecture.md` - Update if architecture changed
    - `/docs/security/current-security-assessment.md` - Update security posture
    - Change request checklist in `/docs/planning` - Mark all items as completed
    - Design documents in `/docs/development` - Update as needed
    - `/CLAUDE.md` - Update if workflow or important context changed
## Archive Process
    - Move the change request document to `/docs/feedback/archive/`
    - Move the planning checklist to `/docs/planning/archive/`
    - Move the design document to `/docs/development/archive/`
    - IMPORTANT: files in archive are for historical reference and shouldn't be deleted, moved, or recovered via git to a non-archive directory by you, the LLM agent

## Process
**IMPORTANT**: First check the system date (shown in environment info) before adding any timestamps

1. **Update Current Features**
   - Edit `/docs/requirements/current-features.md`
   - Add new features/changes
   - Update last modified date
   - Include feature description and key functionality

2. **Update Architecture** (if changed)
   - Edit `/docs/development/current-architecture.md`
   - Document new components
   - Update data flow diagrams
   - Add new API endpoints
   - Update state management sections

3. **Update Security Assessment**
   - Load cybersecurity specialist from `/docs/personas/cybersecurity-specialist.md`
   - Edit `/docs/security/current-security-assessment.md`
   - Document implemented security controls
   - Update threat model if new components added
   - Record any security findings discovered during implementation
   - Update compliance status if data handling changed
   - Add security test results
   - Note any security debt or future improvements

4. **Security Learnings Documentation**
   - Document security patterns that worked well
   - Record any security challenges encountered
   - Update security best practices discovered
   - Note any security tools or libraries adopted
   - Document security testing approaches that were effective

5. **Complete Checklist**
   - Mark all items as completed in `/docs/planning/[feature]-checklist.md`
   - Add completion notes if relevant
   - Document any deviations from plan
   - **Include security verification results**

6. **Archive Documents**
   - Move change request: `/docs/feedback/` → `/docs/feedback/archive/`
   - Move checklist: `/docs/planning/` → `/docs/planning/archive/`
   - Move design doc: `/docs/development/` → `/docs/development/archive/`
   - Verify all files moved successfully

7. **Update CLAUDE.md** (if needed)
   - Add new development patterns
   - Update workflow if changed
   - Document new best practices
   - **Add security practices discovered**
   - Add important context

8. **Prepare for PR**
   - Summarize all changes
   - List updated documentation
   - **Include security improvements made**
   - Reference archived documents
   - Provide PR description template

## Output Format
```
## Learnings Captured for [Feature]

### Documentation Updated:
- ✅ current-features.md: [summary of additions]
- ✅ current-architecture.md: [summary of changes]
- ✅ current-security-assessment.md: [security updates]
- ✅ CLAUDE.md: [if updated]

### Security Improvements:
- [List of security controls implemented]
- [Security test coverage added]
- [Compliance updates]

### Files Archived:
- ✅ CHANGE REQUEST: [feature].md
- ✅ [feature]-checklist.md
- ✅ [feature]-design.md

### Ready for PR:
Title: [Feature]: [Description]
Body: [Generated PR description including security notes]
```

## Security Integration

The cybersecurity specialist persona will:
- Document all security controls implemented
- Update the security assessment with new findings
- Record security patterns for future reference
- Ensure security test results are captured
- Update threat model if architecture changed
- Document any security debt for future sprints

## Usage
`/capture-learnings pdf-export`