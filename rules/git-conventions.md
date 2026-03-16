# Git Conventions

## Safety

- Never force-push to main/master
- Never skip pre-commit hooks (`--no-verify`)
- Never amend commits that have been pushed to a shared branch — create new commits instead. Amending your own unpushed feature branch is fine.
- Stage specific files (`git add <file>`), never `git add -A` or `git add .`

## Destructive Operations

Before destructive git operations (force-push, reset --hard, branch deletion, rebase of shared branches): show what will be affected (e.g., `git log` of commits to be lost, `git diff` of changes to be discarded), then wait for explicit approval.
