# claude-secure-config

Security rules, cognitive scaffolding, and hook enforcement for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) projects.

Not just guardrails — a framework for human-AI partnership where the AI leverages machine-speed strengths, surfaces gaps instead of hiding them, and guides toward robust upstream solutions.

## Why this exists

AI-generated code produces [1.7x more issues per PR](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) than human code (CodeRabbit, 470 PRs). In a [DryRun Security study](https://www.helpnetsecurity.com/2026/03/13/claude-code-openai-codex-google-gemini-ai-coding-agent-security/) of 30 AI-generated PRs, 87% contained security vulnerabilities. Meanwhile, developers using AI for code delegation [scored 17% lower](https://www.anthropic.com/research/AI-assistance-coding-skills) on comprehension than those who coded manually — while those who used AI for *conceptual inquiry* scored highest of all (Anthropic, Jan 2026).

The problem isn't AI. It's AI without structure. These rules provide that structure across three layers:

```
Layer 1: Hooks      → "You can't do this"      (deterministic enforcement)
Layer 2: Rules      → "Here's how to do this"   (security, hygiene, conventions)
Layer 3: Scaffold   → "Why are we doing this?"  (cognitive partnership)
```

## What's included

### Layer 3: Partnership

| File | Purpose |
|------|---------|
| `rules/cognitive-scaffold.md` | Reasoning/inference distinction, friction worth keeping, anti-sycophancy, comfort-growth awareness |
| `rules/deliberation.md` | When to pause vs act, progressive trust, consequence-reversibility matrix, pushing back |
| `rules/task-protocol.md` | Preflight/strategy/review scaffold for any non-trivial task |

### Layer 2: Rules

| File | Purpose |
|------|---------|
| `rules/security.md` | Input validation, access control, injection, XSS, SSRF, secrets, error handling, CORS, supply chain, MCP/tool security, AI tooling safety, crypto, headers, logging |
| `rules/code-hygiene.md` | Type safety, granular error handling, async safety, search-before-create, verification, debt budget, AI discipline |
| `rules/git-conventions.md` | Git safety, destructive operation protocol, commit format, AI attribution, scope discipline |

### Layer 1: Enforcement

| File | Purpose |
|------|---------|
| `hooks.md` | Template `settings.json` with destructive command blocking, secret protection, auto-format, exit code reference |

Draws from [OWASP Top 10:2025](https://owasp.org/Top10/2025/), [OWASP Agentic Top 10](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/), [CWE Top 25 2024](https://cwe.mitre.org/top25/archive/2024/2024_cwe_top25.html), [OpenSSF AI Code Assistant Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html), and research on [cognitive scaffolding](https://arxiv.org/abs/2507.19483), [deliberative alignment](https://arxiv.org/abs/2412.16339), and [human-AI feedback loops](https://www.nature.com/articles/s41562-024-02077-2).

## What this is NOT

- Not a replacement for SAST/DAST scanning — these are authoring-time guardrails, not analysis tools
- Not runtime security — CSP headers, rate limiting, and auth middleware must be implemented in your code
- Not immune to context compaction — in long sessions, Claude may summarize rules away. Hooks are immune; text rules are not
- Not bypass-proof — `--dangerously-skip-permissions` disables all hooks and deny rules
- Not immune to training — AI models have behaviors conditioned by their training pipeline that text rules cannot fully override. For example, Claude defaults to `Co-Authored-By` attribution in commits despite this repo's rules explicitly saying not to. Rules reduce the problem; they don't eliminate it. Hooks and deny rules are stronger than text instructions.

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

The path must resolve on every developer's machine. For teams, prefer symlinks or copies.

## setup.sh reference

| Flag | Description |
|------|-------------|
| `--copy` | Copy files instead of symlinking (required on Windows without WSL) |
| `--internal` | Also install custom rules from `internal/` (requires confirmation) |
| `--yes`, `-y` | Skip confirmation prompts (for CI/scripted usage) |
| `--uninstall` | Remove all rules installed by this tool |
| `--status` | Show what's currently installed |
| `--dry-run` | Preview what would happen without making changes |
| `--force` | Overwrite non-symlink files in `org/` without prompting |
| `--version` | Show version |
| `--help` | Show usage help |

### Provenance tracking

Each install writes a `.claude-secure-config` marker file to the target's `org/` directory, recording the source path, timestamp, version, and install mode. This enables `--status` to report installation details and `--uninstall` to verify ownership before removing files. Orphaned files (present in `org/` but no longer in the source) are detected and reported after each install.

## How it works

Claude Code loads `.md` files from `.claude/rules/` as project instructions:

```
.claude/CLAUDE.md          → Your project overview + critical rules (keep under 200 lines)
.claude/rules/*.md         → Your project-specific rules (framework, testing, etc.)
.claude/rules/org/*.md     → Shared rules (from this repo)
```

This repo's rules total ~309 lines (~3,675 tokens). There is no hard ceiling, but compliance degrades as instruction volume grows — keep total loaded rules (shared + project-specific) as concise as possible and verify behavior after changes.

## Hooks

Text rules can be ignored. Hooks can't. See [`hooks.md`](hooks.md) for:

- **PreToolUse:** Block destructive commands (`rm -rf`, `git push --force`, pushes to main, `--no-verify`)
- **PostToolUse:** Auto-format files after edits
- **Permissions:** Hard-deny reading/writing `.env` files; pre-allow safe commands

Copy the template `settings.json` from `hooks.md` into `.claude/settings.json`.

## Sandboxing

For isolation guarantees beyond hooks, run Claude Code in a sandbox:

- **Built-in:** OS-level sandboxing via [Anthropic's sandbox](https://www.anthropic.com/engineering/claude-code-sandboxing)
- **Container:** Docker or [Trail of Bits' devcontainer](https://github.com/trailofbits/claude-code-devcontainer) for untrusted repos

## Custom instructions

Place custom `.md` files in `internal/` to add your own instructions that complement the base rules. The `internal/custom-instructions.md` file is tracked and serves as the entry point; all other files in `internal/` are gitignored.

Custom instructions do not override the base rules — they complement them. Where there is ambiguity or conflict, the AI should ask rather than assume.

To install custom rules alongside the shared rules:

```bash
bash setup.sh /path/to/your-repo --internal
```

Custom rules are **never installed by default** — this is a security decision. The `--internal` flag lists every custom rule and requires explicit confirmation before installing. This prevents unreviewed instructions from silently entering a target project.

## Internal rules (private, gitignored)

1. Fork this repo
2. Add `.md` rule files to `internal/`
3. Run `setup.sh --internal` — installs both `rules/` and `internal/` (with confirmation)

Claude reads from the filesystem, not git — gitignored files still load. For truly sensitive rules, store them in `~/.claude/rules/` instead.

## Customizing

1. Shared rules in `.claude/rules/org/` (from this repo)
2. Project-specific rules as `.claude/rules/your-framework.md`
3. Most critical 3-5 rules in `.claude/CLAUDE.md` (top of file = highest attention)
4. Add compaction survival instructions for long sessions — see [example](https://code.claude.com/docs/en/memory)

## Contributing

PRs welcome. Keep rules:
- Generic (no project-specific paths or tool names)
- Non-prescriptive where possible — open questions over closed checklists
- Concise (every token costs context window budget)
- Backed by data where possible

## License

MIT
