#!/bin/bash
set -euo pipefail

# claude-secure-config setup
# Symlinks shared rules into a target repo's .claude/rules/org/ directory.
# Also installs internal rules from internal/ if present.
#
# Usage:
#   bash setup.sh /path/to/target-repo
#   bash setup.sh /path/to/target-repo --copy  # copy instead of symlink
#
# Requires: bash. Symlink mode requires a Unix-like OS (macOS, Linux, WSL).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
INTERNAL_DIR="$SCRIPT_DIR/internal"

if [ -z "${1:-}" ]; then
  echo "Usage: bash setup.sh /path/to/target-repo [--copy]"
  echo ""
  echo "Options:"
  echo "  --copy    Copy files instead of symlinking (required on Windows without WSL)"
  exit 1
fi

TARGET="$1"
MODE="${2:-}"

if [ -n "$MODE" ] && [ "$MODE" != "--copy" ]; then
  echo "Error: Unknown option '$MODE'. Use --copy or omit for symlink mode."
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "Warning: $TARGET does not appear to be a git repository" >&2
fi

DEST="$TARGET/.claude/rules/org"
mkdir -p "$DEST"

install_rules() {
  local src_dir="$1"
  local label="$2"

  for rule in "$src_dir"/*.md; do
    [ -f "$rule" ] || continue
    filename="$(basename "$rule")"
    if [ "$MODE" = "--copy" ]; then
      cp "$rule" "$DEST/$filename"
      echo "  Copied $filename ($label)"
    else
      ln -sf "$rule" "$DEST/$filename"
      echo "  Linked $filename ($label)"
    fi
  done
}

echo "Installing shared rules..."
install_rules "$RULES_DIR" "shared"

if [ -d "$INTERNAL_DIR" ] && ls "$INTERNAL_DIR"/*.md &>/dev/null; then
  echo ""
  echo "Installing internal rules..."
  install_rules "$INTERNAL_DIR" "internal"
fi

echo ""
echo "Done. Rules installed at $DEST"
echo "Add .claude/rules/org/ to .gitignore if using symlinks."
