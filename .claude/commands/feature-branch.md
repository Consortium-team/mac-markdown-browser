---
description: Create a Git feature branch for a change request
argument-hint: <change-request-name>
---

# Create Feature Branch

I will create a feature branch for the change request: $ARGUMENTS or whatever change request is in docs/feedback if $ARGUMENTS not provided

Steps:
1. Ensure we're on the main branch and up to date
2. Create a new branch with naming convention: feature/[change-request-name]
3. Push the branch upstream for tracking
4. Confirm branch creation and set upstream

The branch name will be based on the change request name provided (or the change request document if change request name not provided)