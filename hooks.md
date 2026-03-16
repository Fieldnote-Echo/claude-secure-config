# Hook Patterns for Claude Code

Hooks enforce rules deterministically — text rules can be ignored, hooks can't. But hooks are only as strong as their implementation: test yours, treat a failed parse as a block not a pass.

## Exit Code Semantics

| Exit code | Behavior |
|-----------|----------|
| `0` | Allow — tool call proceeds |
| `1` | Warning — tool call proceeds, message shown |
| `2` | **Block** — tool call is prevented |

**Use `exit 2` to block.** `exit 1` only warns.

## Prerequisites

The hooks below require `jq` for JSON parsing. All regex uses `grep -E` (POSIX Extended) for cross-platform compatibility — `grep -P` (PCRE) silently fails on macOS and Git Bash, which would disable all safety checks.

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
        "command": "bash -c 'command -v jq >/dev/null || { echo \"BLOCKED: jq required for safety hooks\" >&2; exit 2; }; CMD=$(printf \"%s\" \"$CLAUDE_TOOL_INPUT\" | jq -r \".command // .tool_input.command // empty\" 2>/dev/null); if [ -z \"$CMD\" ]; then exit 0; fi; CMD=$(printf \"%s\" \"$CMD\" | tr \"\\n\\r\" \"  \"); if printf \"%s\" \"$CMD\" | grep -qE \"(^|[;|&])[ ]*((/usr/bin/|/bin/)?rm[ ]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive|--force))\"; then echo \"BLOCKED: Recursive force-delete detected. Use explicit file paths.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"git[ ]+push[ ]+.*(-f|--force)\" && ! printf \"%s\" \"$CMD\" | grep -qE \"--force-with-lease|--force-if-includes\"; then echo \"BLOCKED: Use --force-with-lease instead of --force.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"git[ ]+push[ ]+[^ ]+[ ]+(main|master)([ ]|$)|git[ ]+push[ ]+[^ ]+[ ]+[^ ]*:(main|master)\"; then echo \"BLOCKED: Direct push to main/master. Use a PR.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"git[ ]+(checkout[ ]+(--[ ]+)?\\\\.([ ]|$)|restore[ ]+\\\\.|reset[ ]+--hard|clean[ ]+-[a-zA-Z]*f|branch[ ]+(-D|.*--force)|stash[ ]+(drop|clear)|push[ ]+[^ ]+[ ]+--delete)\"; then echo \"BLOCKED: Destructive git command. Confirm with user first.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"git[ ]+(commit|merge|push|rebase|cherry-pick)[ ]+.*--no-verify\"; then echo \"BLOCKED: Never skip pre-commit hooks.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"[|][ ]*(bash|sh|zsh)([[:space:]]|$)\"; then echo \"BLOCKED: Pipe to shell detected. Run commands directly.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"(^|[;|&])[ ]*(bash|sh)[ ]+-c[ ]\"; then echo \"BLOCKED: Nested shell execution. Run commands directly.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"(^|[;|&])[ ]*eval[ ]\"; then echo \"BLOCKED: eval detected. Use explicit commands.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"(cat|less|more|head|tail|source|cp|mv|base64|xxd|grep)[ ]+(.*\\\\.env([[:space:]]|$)|.*secrets/)\"; then echo \"BLOCKED: Direct access to .env or secrets/ via Bash. Use project configuration.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"chmod[ ]+(-R[ ]+)?(777|000)[ ]\"; then echo \"BLOCKED: Dangerous permission change.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"dd[ ]+.*of=/dev/\"; then echo \"BLOCKED: dd write to device.\" >&2; exit 2; fi; if printf \"%s\" \"$CMD\" | grep -qE \"ln[ ]+.*\\\\.env\"; then echo \"BLOCKED: Symlink involving .env detected.\" >&2; exit 2; fi'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash -c 'FILE=$(printf \"%s\" \"$CLAUDE_TOOL_INPUT\" | jq -r \".file_path // .tool_input.file_path // empty\" 2>/dev/null); if [ -n \"$FILE\" ] && [ -f \"node_modules/.bin/prettier\" ] && printf \"%s\" \"$FILE\" | grep -qE \"\\.(ts|tsx|js|jsx|json|md|css)$\"; then npx prettier --write \"$FILE\" 2>/dev/null; fi'"
      }
    ]
  }
}
```

## What Each Hook Does

### PreToolUse: Destructive Command Blocker

Fail-closed design: if `jq` is missing or JSON parsing fails, the hook blocks. All regex uses `grep -E` (works on macOS, Linux, WSL, Git Bash).

**Blocked patterns:**
- `rm` with any combination of recursive + force flags (`-rf`, `-fr`, `-r -f`, `--recursive`, `--force`), including path-qualified `/bin/rm`
- `git push --force` and `git push -f` (allows safe `--force-with-lease` and `--force-if-includes`)
- Direct pushes to main/master, including refspec syntax (`HEAD:main`)
- `git checkout .`, `git checkout -- .`, `git restore .`, `git reset --hard`, `git clean -f`, `git branch -D`, `git stash drop`, `git stash clear`, `git push --delete`
- `--no-verify` only on git commands (won't false-positive on commit messages or echo statements)
- Pipe to shell (`| bash`, `| sh`)
- Nested shell execution (`bash -c`, `sh -c`)
- `eval` calls
- Bash-level access to `.env` files and `secrets/` (`cat .env`, `source .env`, `cp .env`, etc.)
- Symlinks involving `.env`
- `chmod 777`/`chmod 000`, `dd` to block devices

### PostToolUse: Auto-Format on Save
Runs Prettier on edited files if installed as a project dependency. Uses `printf` instead of `echo` for portable path handling.

### Permissions: Deny Secret Files
Hard-blocks Read/Write/Edit on `.env` files and `secrets/` directories via tool-level permissions. The PreToolUse hook extends this to Bash-level access (`cat`, `source`, `cp`, etc.).

### Permissions: Allow Safe Commands
Pre-approves lint, test, typecheck, and format commands.

## Known Limitations

- **Indirect execution**: Variable indirection (`CMD="rm"; $CMD -rf /`), Python/Node one-liners (`python3 -c "import shutil; shutil.rmtree('/')"`) can bypass pattern matching. For defense against these, use Claude Code's built-in sandbox mode.
- **Schema dependency**: Hooks parse `$CLAUDE_TOOL_INPUT` expecting `{"command": "..."}` for Bash and `{"file_path": "..."}` for Edit/Write. If Claude Code changes these field names, PreToolUse fails closed (blocks all); PostToolUse fails open (skips formatting).
- **Symlink bypass**: Filename-based deny rules can be bypassed by symlinking `.env` to another name. The symlink check in the hook mitigates this partially.

## Custom Hooks

Add project-specific patterns by extending the PreToolUse command string:

```bash
# Example: block Node.js APIs in Cloudflare Workers files
if printf "%s" "$CMD" | grep -qE "require\(|from .node:"; then
  echo "BLOCKED: No Node.js APIs in Workers." >&2; exit 2
fi
```

## Platform Support

All hooks use POSIX-compatible tools: `bash`, `jq`, `grep -E`, `printf`. Tested on:
- Linux (GNU grep)
- macOS (BSD grep)
- WSL (Windows Subsystem for Linux)
- Git Bash (Windows)

## Personal Overrides

Use `.claude/settings.local.json` (gitignored by convention) for personal hook customization.

**Security note:** Local settings can override shared deny rules. If your threat model includes insider risk, enforce critical deny rules at the user level (`~/.claude/settings.json`) rather than the project level.
