# Git Conventions

## Safety

- Never force-push to main/master. On feature branches, use `--force-with-lease` (checks that remote hasn't changed since your last fetch).
- Never skip pre-commit hooks (`--no-verify`). If a hook fails, fix the underlying issue — the hook caught something real.
- Never amend commits that have been pushed to a shared branch — create new fixup commits instead. Amending your own unpushed feature branch is fine.
- Stage specific files (`git add <file>`), never `git add -A` or `git add .`

## Destructive Operations

Before destructive git operations (force-push, reset --hard, branch deletion, rebase of shared branches): show what will be affected (e.g., `git log` of commits to be lost, `git diff` of changes to be discarded), then wait for explicit approval.

## Undoing Changes (without reset --hard)

- Undo last commit, keep changes staged: `git reset --soft HEAD~1`
- Undo last commit, unstage changes: `git reset HEAD~1`
- Discard changes to one file: `git checkout -- <file>`
- Undo a merge: `git revert -m 1 <merge-sha>`
- Pull in specific fixes: `git cherry-pick <sha>`
- Match remote exactly: `git fetch && git checkout -B branch origin/branch`

Every undo should be scoped and reversible. If `reset --hard` feels necessary, checkpoint first (`git stash` or `git branch backup-<name>`).
