# Hook Patterns for Claude Code

Hooks enforce rules deterministically — they can't be ignored like text instructions.

## Exit Code Semantics

| Exit code | Behavior |
|-----------|----------|
| `0` | Allow — tool call proceeds |
| `1` | Warning — tool call proceeds, message shown |
| `2` | **Block** — tool call is prevented |

**Use `exit 2` to block.** `exit 1` only warns.

## Template: `.claude/settings.json`

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(secrets/**)"
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
        "command": "bash -c 'CMD=$(echo \"$CLAUDE_TOOL_INPUT\" | jq -r .command 2>/dev/null); if echo \"$CMD\" | grep -qP \"rm\\s+-rf|git\\s+push.*--force|git\\s+push.*(main|master)$|git\\s+checkout\\s+\\.|git\\s+reset\\s+--hard\"; then echo \"BLOCKED: Destructive command detected. Use explicit paths for rm, never force-push, never reset --hard without confirmation.\" >&2; exit 2; fi'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash -c 'FILE=$(echo \"$CLAUDE_TOOL_INPUT\" | jq -r .file_path 2>/dev/null); if [ -n \"$FILE\" ] && echo \"$FILE\" | grep -qP \"\\.(ts|tsx|js|jsx|json|md|css)$\"; then npx prettier --write \"$FILE\" 2>/dev/null; fi'"
      }
    ]
  }
}
```

## What Each Hook Does

### PreToolUse: Destructive Command Blocker
Blocks `rm -rf`, `git push --force`, direct pushes to main/master, `git checkout .`, and `git reset --hard`. Enforces the git safety rules from `git-conventions.md`.

### PostToolUse: Auto-Format on Save
Runs Prettier on any file Claude edits. Ensures consistent formatting without relying on Claude to remember style rules.

### Permissions: Deny Secret Files
Hard-blocks reading `.env` files and secrets directories. Supplements the secrets rules in `security.md` with enforcement.

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

## Personal Overrides

Use `.claude/settings.local.json` (gitignored by convention) for personal hook customization without modifying the shared settings.
