# Hook Patterns for Claude Code

Hooks enforce rules deterministically — they can't be ignored like text instructions. But hooks are only as strong as their implementation: test yours, and treat a failed parse as a block, not a pass.

## Exit Code Semantics

| Exit code | Behavior |
|-----------|----------|
| `0` | Allow — tool call proceeds |
| `1` | Warning — tool call proceeds, message shown |
| `2` | **Block** — tool call is prevented |

**Use `exit 2` to block.** `exit 1` only warns.

## Prerequisites

The hooks below require `jq` for JSON parsing. Verify before use:

```bash
command -v jq >/dev/null || { echo "hooks require jq: brew install jq / apt install jq"; exit 1; }
```

The PostToolUse auto-format hook assumes Prettier is a project dependency. Remove it if your project doesn't use Prettier.

## Template: `.claude/settings.json`

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(secrets/**)",
      "Write(.env)",
      "Write(.env.*)",
      "Write(secrets/**)",
      "Edit(.env)",
      "Edit(.env.*)",
      "Edit(secrets/**)"
    ],
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Bash(npm run typecheck)",
      "Bash(npm run format)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "bash -c 'command -v jq >/dev/null || { echo \"BLOCKED: jq is required for safety hooks. Install it: brew install jq / apt install jq\" >&2; exit 2; }; CMD=$(echo \"$CLAUDE_TOOL_INPUT\" | jq -r .command); if [ -z \"$CMD\" ] || [ \"$CMD\" = \"null\" ]; then echo \"BLOCKED: Could not parse command from tool input\" >&2; exit 2; fi; if echo \"$CMD\" | grep -qP \"rm\\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive)|-fr\\s|rm\\s+--force.*--recursive|rm\\s+--recursive.*--force\"; then echo \"BLOCKED: Recursive force-delete detected. Use explicit file paths instead.\" >&2; exit 2; fi; if echo \"$CMD\" | grep -qP \"git\\s+push\\s+.*--force(?!-with-lease)\"; then echo \"BLOCKED: Use --force-with-lease instead of --force.\" >&2; exit 2; fi; if echo \"$CMD\" | grep -qP \"git\\s+push\\s+\\S+\\s+(main|master)\\b\"; then echo \"BLOCKED: Direct push to main/master. Use a PR.\" >&2; exit 2; fi; if echo \"$CMD\" | grep -qP \"git\\s+(checkout\\s+\\.|reset\\s+--hard|clean\\s+-[a-zA-Z]*f|branch\\s+-D|stash\\s+drop)\"; then echo \"BLOCKED: Destructive git command. Confirm with user first.\" >&2; exit 2; fi; if echo \"$CMD\" | grep -qP \"--no-verify\"; then echo \"BLOCKED: Never skip pre-commit hooks.\" >&2; exit 2; fi'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash -c 'FILE=$(echo \"$CLAUDE_TOOL_INPUT\" | jq -r .file_path 2>/dev/null); if [ -n \"$FILE\" ] && [ -f \"node_modules/.bin/prettier\" ] && echo \"$FILE\" | grep -qP \"\\.(ts|tsx|js|jsx|json|md|css)$\"; then npx prettier --write \"$FILE\" 2>/dev/null; fi'"
      }
    ]
  }
}
```

## What Each Hook Does

### PreToolUse: Destructive Command Blocker
Blocks destructive operations with fail-closed behavior (if `jq` is missing or parsing fails, the command is blocked, not allowed):

- `rm` with any combination of recursive + force flags (`-rf`, `-fr`, `-r -f`, `--recursive --force`)
- `git push --force` (but allows safe `--force-with-lease`)
- Direct pushes to main/master
- `git checkout .`, `git reset --hard`, `git clean -f`, `git branch -D`, `git stash drop`
- `--no-verify` (skipping pre-commit hooks)

### PostToolUse: Auto-Format on Save
Runs Prettier on edited files, but only if Prettier is installed as a project dependency (`node_modules/.bin/prettier`). Does nothing in projects that don't use Prettier.

### Permissions: Deny Secret Files
Hard-blocks reading, writing, and editing `.env` files and secrets directories.

### Permissions: Allow Safe Commands
Pre-approves lint, test, typecheck, and format commands so Claude can run them without asking for permission each time.

## Custom Hooks

Add project-specific hooks by extending the arrays above. Common patterns:

```json
{
  "matcher": "Edit|Write",
  "command": "bash -c 'if echo \"$CLAUDE_TOOL_INPUT\" | grep -qP \"your-pattern\"; then echo \"BLOCKED: reason\" >&2; exit 2; fi'"
}
```

## Platform Support

These hooks require: bash, jq, grep with PCRE support (`-P` flag). Windows users should use WSL or Git Bash with jq installed.

## Personal Overrides

Use `.claude/settings.local.json` (gitignored by convention) for personal hook customization without modifying the shared settings.
