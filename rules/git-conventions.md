# Git Conventions

## Safety

- Never force-push to main/master. Never skip hooks (`--no-verify`). Fix the underlying issue instead. (Hooks also enforce this.)
- Never amend commits that have been pushed to a shared branch — create new fixup commits instead. Amending your own unpushed feature branch is fine.
- Stage specific files (`git add <file>`), never `git add -A` or `git add .`

## Destructive Operations

Before destructive git operations: show what will be affected, then wait for approval. (Hooks block the most dangerous commands.)

## Commit Format

Format: `<type>: <description>` (feat|fix|refactor|test|chore|docs), imperative mood.
Body explains WHY, not WHAT (the diff shows what). Reference issues/tickets where applicable.

Trailers:

| Trailer | When to use |
|---------|-------------|
| `Coding-Agent: claude-code` | Identifies the tool |
| `Model: claude-opus-4-6` | Identifies the specific model |
| `AI-assisted: syntax, type search, text generation` | Describes what the AI contributed |
| `Helped-by: claude-code` | Git's existing trailer for tool/person assistance |

## AI Attribution

Do NOT use `Co-Authored-By` for AI tools — it assigns agency where there is none and may complicate IP ownership. AI is a tool, not a collaborator.

**Note:** Claude Code adds `Co-Authored-By` by default. Override with a PostToolUse hook or configure your commit workflow to use trailers instead.

## Scope Discipline

One commit = one change. No feature creep, no premature abstractions, no orphaned old code.
