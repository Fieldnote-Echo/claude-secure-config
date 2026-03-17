# claude-secure-config

Security rules, cognitive scaffolding, and hook enforcement for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) projects.

## Quick start

```bash
git clone https://github.com/Fieldnote-Echo/claude-secure-config.git
bash claude-secure-config/setup.sh /path/to/your-repo
```

Add `.claude/rules/org/` to your `.gitignore`. Updates arrive automatically via `git pull`.

## The problem

AI-generated code produces [1.7x more issues per PR](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) than human code. [87% of AI-generated PRs](https://www.helpnetsecurity.com/2026/03/13/claude-code-openai-codex-google-gemini-ai-coding-agent-security/) contain security vulnerabilities. Developers who delegate to AI [score 17% lower](https://www.anthropic.com/research/AI-assistance-coding-skills) on comprehension — while those who use AI for *conceptual inquiry* score highest of all.

The problem isn't AI. It's AI without structure.

## Three layers

```
Layer 1: Hooks      → "You can't do this"      (deterministic enforcement)
Layer 2: Rules      → "Here's how to do this"   (security, hygiene, conventions)
Layer 3: Scaffold   → "Why are we doing this?"  (cognitive partnership)
```

### Layer 1: Enforcement

Hooks are deterministic — they can't be ignored or summarized away.

| File | What it does |
|------|-------------|
| [`hooks.md`](hooks.md) | Blocks `rm -rf`, `git push --force`, `--no-verify`, `.env` access. Template `settings.json` you copy into your project. |

### Layer 2: Rules

Text instructions the model follows during code generation. Structured as pre-flight checks, non-derivable specifics, and eval anchors.

| File | What it catches |
|------|----------------|
| [`security.md`](rules/security.md) | Trust boundary violations, injection, XSS, unsafe deserialization, secret leaks, supply chain risks, MCP/tool trust |
| [`code-hygiene.md`](rules/code-hygiene.md) | Weak types, swallowed errors, fire-and-forget async, code duplication, unverified completion claims |
| [`git-conventions.md`](rules/git-conventions.md) | Force-pushes, skipped hooks, `git add .`, scope creep, AI mis-attribution |

### Layer 3: Partnership

Shapes *how* the model works with you, not just what it produces.

| File | What it changes |
|------|----------------|
| [`cognitive-scaffold.md`](rules/cognitive-scaffold.md) | Reduces sycophancy, surfaces trade-offs, flags unfamiliar patterns, monitors for dependency formation |
| [`deliberation.md`](rules/deliberation.md) | Pauses before irreversible actions, builds trust progressively, pushes back when something seems off |
| [`task-protocol.md`](rules/task-protocol.md) | Preflight questions before non-trivial tasks |

~255 lines, ~2,922 tokens total. Compliance degrades as instruction volume grows — keep loaded rules concise and verify behavior after changes.

## Installation options

The quick start above uses **symlinks** (recommended). Other options:

| Method | Command | Updates |
|--------|---------|---------|
| Copy | `setup.sh /path/to/repo --copy` | Re-run to update |
| Manual | Copy individual files to `.claude/rules/` | Manual |
| @import | `@/path/to/rules/security.md` in CLAUDE.md | Automatic (path must resolve on every dev machine) |

Run `setup.sh --help` for all flags. See the [setup.sh reference](https://github.com/Fieldnote-Echo/claude-secure-config/wiki/Setup.sh-Reference) for provenance tracking and advanced configuration.

## Hooks

Text rules can be ignored. Hooks can't. Copy the template from [`hooks.md`](hooks.md) into `.claude/settings.json`.

For isolation beyond hooks: [Anthropic's built-in sandbox](https://www.anthropic.com/engineering/claude-code-sandboxing) or [Trail of Bits' devcontainer](https://github.com/trailofbits/claude-code-devcontainer).

## Customization

```
.claude/CLAUDE.md          → Your critical project rules (top of file = highest attention)
.claude/rules/*.md         → Your project-specific rules
.claude/rules/org/*.md     → Shared rules from this repo
internal/*.md              → Private rules (gitignored, install with --internal)
```

See the wiki for [customization patterns](https://github.com/Fieldnote-Echo/claude-secure-config/wiki/Customization-Patterns), [internal rules](https://github.com/Fieldnote-Echo/claude-secure-config/wiki/Customization-Patterns#how-do-i-add-internal-or-private-rules), and [compaction survival](https://github.com/Fieldnote-Echo/claude-secure-config/wiki/Customization-Patterns#how-do-i-keep-rules-from-being-lost-during-long-sessions).

## Limitations

- Not a replacement for SAST/DAST — these are authoring-time guardrails
- Not runtime security — implement CSP, rate limiting, and auth middleware in your code
- Text rules can be compacted away in long sessions — hooks are immune
- `--dangerously-skip-permissions` disables all hooks and deny rules
- AI training can override text instructions — hooks are stronger than rules

## Sources

Built on [OWASP Top 10:2025](https://owasp.org/Top10/2025/), [OWASP Agentic Top 10](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/), [CWE Top 25](https://cwe.mitre.org/top25/archive/2024/2024_cwe_top25.html), [OpenSSF AI Code Assistant Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html), and research on [cognitive scaffolding](https://arxiv.org/abs/2507.19483), [deliberative alignment](https://arxiv.org/abs/2412.16339), and [human-AI feedback loops](https://www.nature.com/articles/s41562-024-02077-2).

## Contributing

PRs welcome. Keep rules generic, concise, and backed by data where possible. See the [contributing guide](https://github.com/Fieldnote-Echo/claude-secure-config/wiki/Contributing) for rule design principles and testing requirements.

## License

MIT
