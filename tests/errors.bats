#!/usr/bin/env bats

setup() {
  load "test_helper/common"
  _common_setup
}

teardown() {
  _common_teardown
}

@test "no arguments prints usage" {
  run bash "$SETUP_SH"
  assert_success  # usage exits 0
  assert_output --partial "Usage"
}

@test "non-existent target errors" {
  run bash "$SETUP_SH" "/nonexistent/path/$$"
  assert_failure
  assert_output --partial "does not exist"
}

@test "non-directory target errors" {
  local tmpfile="$TEST_TEMP_DIR/not-a-dir"
  touch "$tmpfile"
  run bash "$SETUP_SH" "$tmpfile"
  assert_failure
  assert_output --partial "not a directory"
}

@test "unknown flag errors" {
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --banana
  assert_failure
  assert_output --partial "Unknown option"
}

@test "multiple targets error" {
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" "/tmp"
  assert_failure
  assert_output --partial "Unexpected argument"
}

@test "--version prints version" {
  run bash "$SETUP_SH" --version
  assert_success
  assert_output --partial "claude-secure-config"
}
