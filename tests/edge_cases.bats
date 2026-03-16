#!/usr/bin/env bats

setup() {
  load "test_helper/common"
  _common_setup
}

teardown() {
  _common_teardown
}

@test "paths with spaces work" {
  local spaced_dir="$TEST_TEMP_DIR/my project dir"
  mkdir -p "$spaced_dir"
  git init "$spaced_dir" >/dev/null 2>&1
  run bash "$SETUP_SH" "$spaced_dir" --copy
  assert_success
  assert [ -d "$spaced_dir/.claude/rules/org" ]
}

@test "relative path resolved correctly" {
  create_git_target
  local abs_path="$TEST_TEMP_DIR"
  local rel_path
  rel_path="$(python3 -c "import os; print(os.path.relpath('$abs_path'))" 2>/dev/null || echo "$abs_path")"
  run bash "$SETUP_SH" "$rel_path" --copy
  assert_success
  assert [ -d "$TEST_TEMP_DIR/.claude/rules/org" ]
}

@test "orphan detection warns about extra files" {
  skip_if_copy_only
  create_git_target
  bash "$SETUP_SH" "$TEST_TEMP_DIR"
  # Add an orphaned file
  echo "# orphan" > "$TEST_TEMP_DIR/.claude/rules/org/old-removed-rule.md"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_success
  assert_output --partial "Orphaned"
}

@test "conflict detection blocks without --force" {
  create_git_target
  mkdir -p "$TEST_TEMP_DIR/.claude/rules/org"
  echo "# hand-written" > "$TEST_TEMP_DIR/.claude/rules/org/security.md"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_failure
  assert_output --partial "regular files"
}

@test "non-git target warns but proceeds" {
  # TEST_TEMP_DIR has no .git — default setup() doesn't init one
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  assert_success
  assert_output --partial "does not appear to be a git"
}
