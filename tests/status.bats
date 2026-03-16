#!/usr/bin/env bats

setup() {
  load "test_helper/common"
}

@test "status shows installed files" {
  create_git_target
  bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --status
  assert_success
  assert_output --partial "Installed"
  assert_output --partial "security.md"
}

@test "status detects broken symlinks" {
  skip_if_copy_only
  create_git_target
  mkdir -p "$TEST_TEMP_DIR/.claude/rules/org"
  ln -sf "/nonexistent/path/fake.md" "$TEST_TEMP_DIR/.claude/rules/org/broken.md"
  echo "# marker" > "$TEST_TEMP_DIR/.claude/rules/org/.claude-secure-config"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --status
  assert_success
  assert_output --partial "BROKEN"
}

@test "status reports not installed when org/ missing" {
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --status
  assert_success
  assert_output --partial "Not installed"
}

@test "status reports not managed without marker" {
  create_git_target
  mkdir -p "$TEST_TEMP_DIR/.claude/rules/org"
  echo "# rogue" > "$TEST_TEMP_DIR/.claude/rules/org/rogue.md"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --status
  assert_success
  assert_output --partial "NOT managed"
}
