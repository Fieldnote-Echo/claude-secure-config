#!/usr/bin/env bash

# Canonical hook commands for testing.
# These must match the logic documented in hooks.md.
# If hook logic changes, update BOTH this fixture AND hooks.md.

run_pretooluse_hook() {
  local tool_input="$1"
  export CLAUDE_TOOL_INPUT="$tool_input"

  # This is the same logic as the PreToolUse hook in hooks.md
  bash -c '
    command -v jq >/dev/null || { echo "BLOCKED: jq required" >&2; exit 2; }
    CMD=$(printf "%s" "$CLAUDE_TOOL_INPUT" | jq -r ".command // .tool_input.command // empty" 2>/dev/null)
    if [ -z "$CMD" ]; then exit 0; fi

    # rm with recursive+force
    if printf "%s" "$CMD" | grep -qE "(^|[;|&])[ ]*((/usr/bin/|/bin/)?rm[ ]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive|--force))"; then
      echo "BLOCKED: Recursive force-delete detected." >&2; exit 2
    fi

    # git push --force (allow --force-with-lease and --force-if-includes)
    if printf "%s" "$CMD" | grep -qE "git[ ]+push[ ]+.*(-f|--force)" && \
       ! printf "%s" "$CMD" | grep -qE -- "--force-with-lease|--force-if-includes"; then
      echo "BLOCKED: Use --force-with-lease instead of --force." >&2; exit 2
    fi

    # git push to main/master (including refspec)
    if printf "%s" "$CMD" | grep -qE "git[ ]+push[ ]+[^ ]+[ ]+(main|master)([ ]|$)|git[ ]+push[ ]+[^ ]+[ ]+[^ ]*:(main|master)"; then
      echo "BLOCKED: Direct push to main/master." >&2; exit 2
    fi

    # Destructive git commands
    if printf "%s" "$CMD" | grep -qE "git[ ]+(checkout[ ]+(--[ ]+)?\.([ ]|$)|restore[ ]+\.|reset[ ]+--hard|clean[ ]+-[a-zA-Z]*f|branch[ ]+(-D|.*--force)|stash[ ]+(drop|clear)|push[ ]+[^ ]+[ ]+--delete)"; then
      echo "BLOCKED: Destructive git command." >&2; exit 2
    fi

    # --no-verify on git commands only
    if printf "%s" "$CMD" | grep -qE "git[ ]+(commit|merge|push|rebase|cherry-pick)[ ]+.*--no-verify"; then
      echo "BLOCKED: Never skip pre-commit hooks." >&2; exit 2
    fi

    # Pipe to shell
    if printf "%s" "$CMD" | grep -qE "[|][ ]*(bash|sh|zsh)([[:space:]]|$)"; then
      echo "BLOCKED: Pipe to shell detected." >&2; exit 2
    fi

    # Nested shell / eval
    if printf "%s" "$CMD" | grep -qE "(^|[;|&])[ ]*(bash|sh)[ ]+-c[ ]"; then
      echo "BLOCKED: Nested shell execution." >&2; exit 2
    fi
    if printf "%s" "$CMD" | grep -qE "(^|[;|&])[ ]*eval[ ]"; then
      echo "BLOCKED: eval detected." >&2; exit 2
    fi

    # Bash access to .env / secrets
    if printf "%s" "$CMD" | grep -qE "(cat|less|more|head|tail|source|cp|mv|base64|xxd|grep)[ ]+.*\.env([[:space:]]|$)|secrets/"; then
      echo "BLOCKED: Direct access to .env or secrets/." >&2; exit 2
    fi

    # chmod 777/000
    if printf "%s" "$CMD" | grep -qE "chmod[ ]+(-R[ ]+)?(777|000)[ ]"; then
      echo "BLOCKED: Dangerous permission change." >&2; exit 2
    fi

    # dd to device
    if printf "%s" "$CMD" | grep -qE "dd[ ]+.*of=/dev/"; then
      echo "BLOCKED: dd write to device." >&2; exit 2
    fi

    # Symlink to .env
    if printf "%s" "$CMD" | grep -qE "ln[ ]+.*\.env"; then
      echo "BLOCKED: Symlink involving .env." >&2; exit 2
    fi

    exit 0
  '
}
