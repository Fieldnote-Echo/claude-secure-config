# Commit Preferences

## AI Attribution

Use git trailers that describe tool usage, not authorship. AI is a tool, not a co-author.

```
Coding-Agent: claude-code
Model: claude-opus-4-6
```

Do NOT use `Co-Authored-By` for AI tools. It implies shared authorship, which:
- Assigns agency where there is none — the developer is responsible for what the tool produces
- May call IP ownership into question — current US case law generally requires human authorship for copyright (this is not legal advice; the landscape is actively being litigated)
- Conflates a tool with a collaborator — `Co-Authored-By` was designed for humans exchanging drafts

**Note:** Claude Code adds `Co-Authored-By` by default. To override, add a PostToolUse hook that strips it, or configure your commit workflow to use trailers instead. See `hooks.md`.

Alternative trailers (pick what fits your team):

| Trailer | When to use |
|---------|-------------|
| `Coding-Agent: claude-code` | Identifies the tool |
| `Model: claude-opus-4-6` | Identifies the specific model |
| `AI-assisted: syntax, type search, text generation` | Describes what the AI contributed |
| `Helped-by: claude-code` | Git's existing trailer for tool/person assistance |

## Architecture Decision Records

Log decisions before implementing them. Use `docs/adr/` or `docs/decisions/`:

- One ADR per decision — don't combine multiple choices in one document
- File format: `NNNN-short-description.md` (e.g., `0001-use-postgres-over-sqlite.md`)
- Keep them close to the code (same repo, version controlled)
- Status lifecycle: `proposed` → `accepted` → `superseded` or `deprecated`

Minimum template:

```markdown
# NNNN: Title

**Status:** accepted
**Date:** YYYY-MM-DD

## Context
What is the issue or constraint that motivates this decision?

## Decision
What is the change we are making?

## Consequences
What becomes easier? What becomes harder?
```

## Commit Messages

- Format: `<type>: <description>`
- Types: feat, fix, refactor, test, chore, docs
- Imperative mood: "add auth check" not "added auth check"
- Body explains WHY, not WHAT (the diff shows what)
- Reference issues/tickets where applicable
