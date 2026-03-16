# Git Conventions

## Commits

- Format: `<type>: <description>`
- Types: feat, fix, refactor, test, chore, docs
- Keep descriptions concise and imperative ("add auth check", not "added auth check")

## Branches

- Format: `<type>/<slug>`
- Examples: `feat/user-auth`, `fix/rate-limit-race`, `docs/api-reference`

## Safety

- Never force-push to main/master
- Never skip pre-commit hooks (`--no-verify`)
- Never amend published commits — create new commits instead
- Stage specific files (`git add <file>`), never `git add -A` or `git add .`

## Destructive Operations

- Dry-run first, present the diff, wait for approval
- This includes: force-push, reset --hard, branch deletion, rebase of shared branches
