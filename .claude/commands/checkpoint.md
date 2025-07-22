# Checkpoint Command

## Purpose
Creates a quick git commit of all current changes to establish a safe fallback point during development. This command provides a simple way to save your progress without the overhead of a full commit message, allowing you to experiment freely knowing you can easily revert if needed.

Save current work state with automatic commit message.

## Arguments
- Optional: Brief description to append to the automatic commit message
- If not provided: Uses a timestamp-based automatic message

## Process

1. **Check Git Status**
   - Run `git status` to see all changes
   - Verify there are changes to commit
   - If no changes, inform user and exit

2. **Stage All Changes**
   - Run `git add -A` to stage all changes
   - This includes new files, modifications, and deletions

3. **Create Checkpoint Commit**
   - Generate automatic commit message:
     - Format: `🔖 Checkpoint: [timestamp] [optional description]`
     - Example: `🔖 Checkpoint: 2025-01-21 14:30:45`
     - Example with arg: `🔖 Checkpoint: 2025-01-21 14:30:45 - before refactoring auth`
   - Commit with generated message

4. **Confirm Success**
   - Show the commit hash
   - Display files included in checkpoint
   - Remind user they can use `/restore` to revert

## Important Notes

- This creates a LOCAL commit only - does not push to remote
- Checkpoint commits are meant to be temporary
- Consider squashing checkpoint commits before creating a PR
- Use meaningful checkpoints before risky changes
- The 🔖 emoji helps identify checkpoint commits in git log

## Usage Examples

```
# Quick checkpoint with auto-generated message
/checkpoint

# Checkpoint with description
/checkpoint before adding websocket support

# Checkpoint before major refactoring
/checkpoint pre-refactor game logic
```

## Output Format

```
✅ Checkpoint created successfully!

Commit: abc1234
Message: 🔖 Checkpoint: 2025-01-21 14:30:45 - before adding websocket support

Files included (15):
- ✓ frontend/src/components/GameGrid.tsx
- ✓ backend/src/controllers/game.controller.ts
- ✓ docs/planning/websocket-design.md
... and 12 more files

💡 Use /restore to revert to this checkpoint if needed
```

## Integration with Development Workflow

Best used:
- Before experimental changes
- Before implementing complex features
- After completing a working subtask
- Before running potentially breaking migrations
- When switching context to help another task

Not recommended for:
- Final commits (use proper commit messages)
- After completing features (use git commit with meaningful message)
- Production-ready code (follow team commit conventions)