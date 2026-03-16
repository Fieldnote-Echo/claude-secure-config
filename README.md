# claude-secure-config

Shared security and convention rules for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) projects.

These rules load automatically when Claude Code works on files in your repo, reducing common AI coding mistakes around security, git safety, and code quality.

## What's included

| File | Purpose |
|------|---------|
| `rules/security.md` | OWASP-informed security rules — secrets, auth, XSS, CORS, supply chain, crypto, logging |
| `rules/git-conventions.md` | Commit format, branch naming, safety rules for destructive operations |
| `rules/code-hygiene.md` | Debt management, AI-specific discipline, replacement = deletion |

## Installation

### Option 1: Symlink (recommended for your own repos)

Clone this repo, then symlink the rules into your project:

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

This copies the files directly. You can then commit them and customize as needed.

### Option 3: Manual

Copy any individual rule file into your project's `.claude/rules/` directory.

## How it works

Claude Code automatically loads `.md` files from `.claude/rules/` as project instructions. These rules are injected into every conversation, giving Claude guardrails around security, git operations, and code quality.

The 3-layer structure:

```
.claude/CLAUDE.md          → Your project overview + critical rules
.claude/rules/*.md         → Your project-specific rules (framework, testing, etc.)
.claude/rules/org/*.md     → Shared org/team rules (from this repo)
```

## Adding path scoping

You can add YAML frontmatter to restrict when a rule loads:

```yaml
---
paths:
  - "src/**/*.ts"
  - "tests/**/*.ts"
---
```

This means the rule only loads when Claude is working on files matching those patterns.

## Internal rules (private, gitignored)

For org-specific or sensitive rules you don't want public:

1. Fork this repo
2. Create an `internal/` directory (it's gitignored)
3. Add `.md` rule files there — e.g. `internal/infra-secrets.md`, `internal/deploy-policy.md`
4. Run `setup.sh` — it installs both `rules/` and `internal/` into your target project

```bash
mkdir internal
cat > internal/deploy-policy.md << 'EOF'
# Deploy Policy
- Production deploys require approval from #platform-eng
- Staging auto-deploys from main
- Never modify terraform state directly
EOF

bash setup.sh /path/to/your-repo
```

Claude Code reads from the filesystem, not from git — gitignored files still load into every session. Your internal rules stay private even if your fork is public.

## Customizing

These rules are intentionally generic. For project-specific rules:

1. Keep shared rules in `.claude/rules/org/` (from this repo)
2. Add project-specific rules as `.claude/rules/your-framework.md`
3. Put the most critical 3-5 rules in `.claude/CLAUDE.md` for primacy bias

## Contributing

PRs welcome. Keep rules:
- Generic (no project-specific paths or tool names)
- Actionable (tell Claude what to do or not do, not background info)
- Concise (every token in a rule file costs context window budget)

## License

MIT
