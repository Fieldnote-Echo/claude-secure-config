#!/usr/bin/env bats

setup() {
  load "test_helper/common"
}

@test "uninstall removes rules and marker" {
  create_git_target
  bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --uninstall
  assert_success
  assert_output --partial "Removed"
  assert [ ! -f "$TEST_TEMP_DIR/.claude/rules/org/.claude-secure-config" ]
  local count
  count="$(count_installed_rules)"
  assert_equal "$count" "0"
}

@test "uninstall removes empty org/ directory" {
  create_git_target
  bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --uninstall
  assert_success
  assert [ ! -d "$TEST_TEMP_DIR/.claude/rules/org" ]
}

@test "uninstall refuses without marker" {
  create_git_target
  mkdir -p "$TEST_TEMP_DIR/.claude/rules/org"
  echo "# not managed" > "$TEST_TEMP_DIR/.claude/rules/org/rogue.md"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --uninstall
  assert_failure
  assert_output --partial "not installed by claude-secure-config"
}

@test "uninstall --force overrides marker check" {
  create_git_target
  mkdir -p "$TEST_TEMP_DIR/.claude/rules/org"
  echo "# not managed" > "$TEST_TEMP_DIR/.claude/rules/org/rogue.md"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --uninstall --force
  assert_success
  assert_output --partial "Removed"
}

@test "uninstall --dry-run does not remove files" {
  create_git_target
  bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --uninstall --dry-run
  assert_success
  assert_output --partial "dry run"
  assert [ -f "$TEST_TEMP_DIR/.claude/rules/org/.claude-secure-config" ]
  local count
  count="$(count_installed_rules)"
  assert [ "$count" -gt 0 ]
}
