#!/usr/bin/env bash

# Load bats helpers
load "bats-support/load"
load "bats-assert/load"

# Path to the setup.sh under test
SETUP_SH="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)/setup.sh"
export SETUP_SH

# --- Setup / Teardown ---

setup() {
  # Create isolated temp directory for each test
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
}

teardown() {
  # Clean up temp directory
  if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# --- Helpers ---

# Create a fake git repo in the temp directory (only call when test needs it)
create_git_target() {
  git init "$TEST_TEMP_DIR" >/dev/null 2>&1
}

# Count .md files in the installed org/ directory
count_installed_rules() {
  local dest="$TEST_TEMP_DIR/.claude/rules/org"
  local count=0
  if [ -d "$dest" ]; then
    for f in "$dest"/*.md; do
      [ -f "$f" ] && count=$((count + 1))
    done
  fi
  echo "$count"
}

# Validate marker file structure (shape, not content)
assert_marker_shape() {
  local marker="$TEST_TEMP_DIR/.claude/rules/org/.claude-secure-config"
  assert [ -f "$marker" ]

  # Line 1: comment
  local line1
  line1="$(sed -n '1p' "$marker")"
  assert [ "${line1:0:1}" = "#" ]

  # Line 2: source path is a directory
  local line2
  line2="$(sed -n '2p' "$marker")"
  assert [ -d "$line2" ]

  # Line 3: ISO-8601 UTC timestamp
  local line3
  line3="$(sed -n '3p' "$marker")"
  assert [[ "$line3" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]

  # Line 4: version is non-empty
  local line4
  line4="$(sed -n '4p' "$marker")"
  assert [ -n "$line4" ]

  # Line 5: empty or --copy
  local line5
  line5="$(sed -n '5p' "$marker")"
  assert [[ -z "$line5" || "$line5" = "--copy" ]]
}

# Skip symlink tests on Windows copy-only mode
skip_if_copy_only() {
  if [ "${COPY_MODE_ONLY:-}" = "true" ]; then
    skip "Symlink tests skipped (COPY_MODE_ONLY=true)"
  fi
}
