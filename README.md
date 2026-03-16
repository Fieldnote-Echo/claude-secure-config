# claude-secure-config

Shared security and convention rules for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) projects.

AI-generated code produces [1.7x more issues per PR](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) than human code, [87% of AI PRs contain security vulnerabilities](https://www.helpnetsecurity.com/2026/03/13/claude-code-openai-codex-google-gemini-ai-coding-agent-security/), and [only 10% of developers scan AI code](https://www.cybersecuritydive.com/news/security-issues-ai-generated-code-snyk/705926/). These rules give Claude guardrails where it matters most.

## What's included

| File | Purpose |
|------|---------|
| `rules/security.md` | Input validation, access control, injection, XSS, SSRF, secrets, auth, async safety, CORS, headers, supply chain, crypto, logging |
| `rules/git-conventions.md` | Commit format, branch naming, safety rules for destructive operations |
| `rules/code-hygiene.md` | Type safety, error handling, search-before-create, verify-before-use, debt management, AI-specific discipline |
| `hooks.md` | Hook patterns, template `settings.json`, exit code reference |

Informed by [OWASP Top 10:2025](https://owasp.org/Top10/2025/), [CWE Top 25 2024](https://cwe.mitre.org/top25/archive/2024/2024_cwe_top25.html), and the [OpenSSF AI Code Assistant Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html).

## Installation

### Option 1: Symlink (recommended for your own repos)

```bash
git clone https://github.com/Fieldnote-Echo/claude-secure-config.git
bash claude-secure-config/setup.sh /path/to/your-repo
```

This creates `.claude/rules/org/` in your repo with symlinks back to this repo. Add to `.gitignore`:

```
.claude/rules/org/
```

### Option 2: Copy (for repos you want to commit rules into)

```bash
bash claude-secure-config/setup.sh /path/to/your-repo --copy
```

### Option 3: Manual

Copy any individual rule file into your project's `.claude/rules/` directory.

### Option 4: @import (no symlinks)

Reference rules directly from your `CLAUDE.md`:

```markdown
@/path/to/claude-secure-config/rules/security.md
@/path/to/claude-secure-config/rules/code-hygiene.md
```

## How it works

Claude Code loads `.md` files from `.claude/rules/` as project instructions. The 3-layer structure:

```
.claude/CLAUDE.md          → Your project overview + critical rules (keep under 200 lines)
.claude/rules/*.md         → Your project-specific rules (framework, testing, etc.)
.claude/rules/org/*.md     → Shared org/team rules (from this repo)
```

## Hooks (enforcement, not suggestions)

Text instructions can be ignored. Hooks can't. See [`hooks.md`](hooks.md) for:

- **PreToolUse:** Block destructive commands (`rm -rf`, `git push --force`, pushes to main)
- **PostToolUse:** Auto-format files after Claude edits them
- **Permissions:** Hard-deny reading `.env` files; pre-allow safe commands

Copy the template `settings.json` from `hooks.md` into your project's `.claude/settings.json`.

Use `.claude/settings.local.json` (gitignored) for personal overrides.

## Path scoping

Add YAML frontmatter to restrict when a rule loads:

```yaml
---
paths:
  - "src/**/*.ts"
  - "tests/**/*.ts"
---
```

**Known limitation:** Path-scoped rules trigger on file reads, not writes. They may not fire when creating new files in a scoped directory.

## Internal rules (private, gitignored)

For org-specific or sensitive rules you don't want public:

1. Fork this repo
2. Create an `internal/` directory (it's gitignored)
3. Add `.md` rule files there
4. Run `setup.sh` — it installs both `rules/` and `internal/`

Claude Code reads from the filesystem, not from git — gitignored files still load. Your internal rules stay private even if your fork is public.

## Compaction survival

Add this to your project's `CLAUDE.md` to prevent context loss in long sessions:

```markdown
## When Compacting

Always preserve: the current task goal, all modified file paths, test commands and their output, and error messages being debugged.
```

## Customizing

These rules are intentionally generic. For project-specific rules:

1. Keep shared rules in `.claude/rules/org/` (from this repo)
2. Add project-specific rules as `.claude/rules/your-framework.md`
3. Put the most critical 3-5 rules in `.claude/CLAUDE.md` for primacy bias (top of file = highest attention)
4. Keep your total rules under 200 lines — every token competes for attention

## Contributing

PRs welcome. Keep rules:
- Generic (no project-specific paths or tool names)
- Positive framing first ("always do X"), then the boundary ("never do Y") — [research shows this works better](https://gadlet.com/posts/negative-prompting/)
- Concise (every token costs context window budget)
- Backed by data where possible (cite sources for claims)

## License

MIT
