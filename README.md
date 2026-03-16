# claude-secure-config

Shared security and convention rules for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) projects.

AI-generated code produces [1.7x more issues per PR](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) than human code (CodeRabbit, 470 PRs). In a [DryRun Security study](https://www.helpnetsecurity.com/2026/03/13/claude-code-openai-codex-google-gemini-ai-coding-agent-security/) of 30 AI-generated PRs, 87% contained security vulnerabilities. These rules give Claude guardrails where it matters most.

## What's included

| File | Lines | Purpose |
|------|-------|---------|
| `rules/security.md` | ~110 | Input validation, access control, injection, XSS, SSRF, secrets, error handling, async safety, CORS, headers, supply chain, MCP/tool security, AI tooling safety, crypto, logging |
| `rules/code-hygiene.md` | ~55 | Type safety, error handling, search-before-create, verification, replacement=deletion, debt budget, AI discipline |
| `rules/deliberation.md` | ~35 | When to pause vs act, progressive trust, pushing back |
| `rules/cognitive-scaffold.md` | ~40 | Reasoning/inference partnership, friction worth keeping, anti-sycophancy |
| `rules/git-conventions.md` | ~12 | Git safety, destructive operation protocol |
| `rules/commit-preferences.md` | ~30 | AI attribution (trailers not co-authorship), commit message format |
| `hooks.md` | ~105 | Hook patterns, template `settings.json`, exit code reference |

Draws from [OWASP Top 10:2025](https://owasp.org/Top10/2025/), [OWASP Agentic Top 10](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/), [CWE Top 25 2024](https://cwe.mitre.org/top25/archive/2024/2024_cwe_top25.html), and the [OpenSSF AI Code Assistant Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html). Coverage is not exhaustive; these are the rules most relevant to AI-assisted code generation.

## What this is NOT

- Not a replacement for SAST/DAST scanning — these are authoring-time guardrails, not analysis tools
- Not runtime security — CSP headers, rate limiting, and auth middleware must be implemented in your code
- Not immune to context compaction — in long sessions, Claude may summarize rules away. Hooks (which execute as code) are immune; text rules are not
- Not bypass-proof — `--dangerously-skip-permissions` disables all hooks and deny rules

## Installation

### Option 1: Symlink (recommended)

```bash
git clone https://github.com/Fieldnote-Echo/claude-secure-config.git
bash claude-secure-config/setup.sh /path/to/your-repo
```

Creates `.claude/rules/org/` with symlinks. Add to `.gitignore`:

```
.claude/rules/org/
```

Symlink users get updates automatically when you `git pull` this repo.

### Option 2: Copy

```bash
bash claude-secure-config/setup.sh /path/to/your-repo --copy
```

Copied files are snapshots. Re-run `setup.sh --copy` to get updates (it overwrites).

### Option 3: Manual

Copy any individual rule file into your project's `.claude/rules/` directory.

### Option 4: @import

Reference rules directly from your `CLAUDE.md`:

```markdown
@/path/to/claude-secure-config/rules/security.md
```

The path must resolve on every developer's machine. For teams, prefer symlinks (Option 1) or copies (Option 2).

## How it works

Claude Code loads `.md` files from `.claude/rules/` as project instructions. The 3-layer structure:

```
.claude/CLAUDE.md          → Your project overview + critical rules (keep under 200 lines)
.claude/rules/*.md         → Your project-specific rules (framework, testing, etc.)
.claude/rules/org/*.md     → Shared org/team rules (from this repo)
```

Total token budget across all loaded rules is roughly 500-800 lines before attention degrades. This repo's rules total ~210 lines, leaving room for project-specific additions.

## Hooks (enforcement, not suggestions)

Text rules can be ignored. Hooks can't. See [`hooks.md`](hooks.md) for:

- **PreToolUse:** Block destructive commands (`rm -rf`, `git push --force`, pushes to main, `--no-verify`)
- **PostToolUse:** Auto-format files after Claude edits them
- **Permissions:** Hard-deny reading/writing `.env` files; pre-allow safe commands

Copy the template `settings.json` from `hooks.md` into your project's `.claude/settings.json`.

## Sandboxing

Text rules and hooks are defense-in-depth. For isolation guarantees, run Claude Code in a sandbox:

- **Built-in:** Claude Code supports OS-level sandboxing. See [Anthropic's sandboxing docs](https://www.anthropic.com/engineering/claude-code-sandboxing).
- **Container:** For untrusted repos, use Docker or DevContainers. See [Trail of Bits' devcontainer](https://github.com/trailofbits/claude-code-devcontainer).

## Path scoping

Add YAML frontmatter to restrict when a rule loads:

```yaml
---
paths:
  - "src/**/*.ts"
---
```

**Known limitation:** Path-scoped rules trigger on file reads, not writes.

## Internal rules (private, gitignored)

1. Fork this repo
2. Create an `internal/` directory (it's gitignored)
3. Add `.md` rule files there
4. Run `setup.sh` — it installs both `rules/` and `internal/`

Claude Code reads from the filesystem, not git — gitignored files still load.

**Caveat:** `.gitignore` is not a security boundary. For truly sensitive rules, store them outside the repo (e.g., `~/.claude/rules/`) and use `@import`.

## Compaction survival

Add this to your project's `CLAUDE.md` to prevent context loss in long sessions:

```markdown
## When Compacting

Always preserve: the current task goal, all modified file paths, test commands and their output, and error messages being debugged.
```

## Customizing

1. Keep shared rules in `.claude/rules/org/` (from this repo)
2. Add project-specific rules as `.claude/rules/your-framework.md`
3. Put the most critical 3-5 rules in `.claude/CLAUDE.md` for primacy bias (top of file = highest attention)
4. Keep your project-specific `CLAUDE.md` under 200 lines

## Contributing

PRs welcome. Keep rules:
- Generic (no project-specific paths or tool names)
- Positive framing first ("always do X"), then the boundary ("never do Y")
- Concise (every token costs context window budget)
- Backed by data where possible (cite sources for claims)

## License

MIT
