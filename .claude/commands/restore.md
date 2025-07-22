# Restore Command

## Purpose
Safely reverts the working directory to the last commit, undoing all changes since the last checkpoint or regular commit. This command provides a quick way to abandon experimental changes and return to a known good state. It includes safety checks to prevent accidental data loss.

Revert to the last committed state with safety checks.

## Arguments
- `--force` - Skip safety prompts and force restoration (use with caution)
- `--soft` - Keep changes as unstaged modifications instead of discarding them
- No arguments - Interactive mode with safety confirmations

## Process

1. **Safety Check**
   - Run `git status` to show current changes
   - Display list of files that will be affected
   - Count new files, modified files, and deletions
   - If no changes, inform user and exit

2. **Show Last Commit**
   - Display the commit you'll restore to
   - Show commit hash, message, and timestamp
   - Especially helpful to see if it's a checkpoint commit

3. **Confirm Action** (unless --force)
   - List what will be lost:
     - Uncommitted changes
     - Untracked files (will be preserved)
     - Staged changes
   - Require explicit confirmation
   - Offer option to checkpoint first

4. **Perform Restoration**
   - If `--soft`:
     - Run `git reset HEAD~1` to undo last commit but keep changes
   - If normal mode:
     - Run `git reset --hard HEAD` to discard all changes
     - Clean working directory to match last commit
   - Preserve untracked files (they're not removed)

5. **Confirm Success**
   - Show the commit you've restored to
   - List what was reverted
   - Remind about untracked files if any remain

## Safety Features

- **Untracked files are preserved** - Only tracked files are reverted
- **Shows preview** - See what will be lost before confirming
- **Suggests checkpoint** - Offers to create checkpoint before reverting
- **Requires confirmation** - Must type 'yes' to proceed (unless --force)

## Usage Examples

```
# Interactive restore with confirmations
/restore

# Force restore without prompts (dangerous!)
/restore --force

# Soft restore - undo last commit but keep changes
/restore --soft
```

## Output Format

### Preview Mode
```
⚠️  Restore will revert to:

Commit: abc1234
Message: 🔖 Checkpoint: 2025-01-21 14:30:45
Author: AI Assistant
Date: 2 minutes ago

Changes that will be lost:
- 🔴 Modified: frontend/src/components/GameGrid.tsx
- 🔴 Modified: backend/src/routes/game.routes.ts
- 🟡 New file: frontend/src/hooks/useWebSocket.ts
- 🟢 Untracked: .env.local (will be preserved)

Total: 3 tracked changes will be lost

Would you like to:
1. Create checkpoint first (recommended)
2. Proceed with restore
3. Cancel

Choose (1/2/3):
```

### Success Output
```
✅ Successfully restored to commit abc1234

Reverted files:
- ✓ frontend/src/components/GameGrid.tsx
- ✓ backend/src/routes/game.routes.ts
- ✓ frontend/src/hooks/useWebSocket.ts (deleted)

Preserved files:
- ↳ .env.local (untracked)

Working directory is now clean.
```

## Important Notes

- Cannot be undone unless you checkpoint first
- Untracked files are never deleted
- Use `--soft` to experiment with keeping changes
- Consider using `git stash` for temporary storage instead
- Always prefer `/checkpoint` before `/restore` for safety

## Common Scenarios

1. **Failed experiment**: Use `/restore` to abandon changes
2. **Broken build**: Quickly return to working state
3. **Wrong branch**: Restore, switch branch, reapply with `--soft`
4. **Before context switch**: Checkpoint current, restore to help elsewhere