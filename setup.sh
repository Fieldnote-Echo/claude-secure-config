#!/bin/bash
set -euo pipefail

# claude-secure-config setup
# Symlinks shared rules into a target repo's .claude/rules/org/ directory.
#
# Usage:
#   bash setup.sh /path/to/target-repo
#   bash setup.sh /path/to/target-repo --copy  # copy instead of symlink
#
# Requires: this repo cloned locally.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"

if [ -z "${1:-}" ]; then
  echo "Usage: bash setup.sh /path/to/target-repo [--copy]"
  echo ""
  echo "Options:"
  echo "  --copy    Copy files instead of symlinking (for repos that can't follow symlinks)"
  exit 1
fi

TARGET="$1"
MODE="${2:-symlink}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

DEST="$TARGET/.claude/rules/org"
mkdir -p "$DEST"

for rule in "$RULES_DIR"/*.md; do
  filename="$(basename "$rule")"
  if [ "$MODE" = "--copy" ]; then
    cp "$rule" "$DEST/$filename"
    echo "Copied $filename → $DEST/$filename"
  else
    ln -sf "$rule" "$DEST/$filename"
    echo "Linked $filename → $DEST/$filename"
  fi
done

echo ""
echo "Done. Org rules installed at $DEST"
echo "Add .claude/rules/org/ to .gitignore if using symlinks."
