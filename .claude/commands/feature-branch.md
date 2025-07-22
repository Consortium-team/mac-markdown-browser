# Feature Branch Command

## Purpose
Creates a dedicated Git branch for implementing a specific change request, ensuring clean separation of features and enabling parallel development. This command handles all the Git operations needed to start work on a new feature. Use this after creating a change request and before starting any implementation work.

Create and push a Git feature branch for $ARGUMENTS.

## Arguments
- If provided: Use the specified name for the branch
- If not provided: Check `/docs/feedback/` for a single change request
  - If exactly one change request found: Use its name
  - If zero found: Error - "No change request found in /docs/feedback/"
  - If multiple found: Error - "Multiple change requests found. Please specify which one."

## Process

1. **Verify Prerequisites**
   - Ensure we're on main branch
   - Check for uncommitted changes
   - Pull latest from origin

2. **Create Feature Branch**
   - Branch naming: `feature/[change-request-name]`
   - Convert spaces to hyphens
   - Use lowercase

3. **Git Operations**
   ```bash
   # Ensure on main and up to date
   git checkout main
   git pull origin main
   
   # Create and switch to feature branch
   git checkout -b feature/[branch-name]
   
   # Push to remote with tracking
   git push -u origin feature/[branch-name]
   ```

4. **Post-Creation**
   - Confirm branch creation
   - Show current branch status
   - Remind about change request document

## Usage Examples
- `/feature-branch tournament-mode`
- `/feature-branch achievement-badges`
- `/feature-branch real-time-leaderboard`