#!/usr/bin/env bats

setup() {
  load "test_helper/common"
  _common_setup
}

teardown() {
  _common_teardown
}

@test "symlink mode creates org/ with symlinks" {
  skip_if_copy_only
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_success
  assert [ -d "$TEST_TEMP_DIR/.claude/rules/org" ]

  # Verify at least one file is a symlink
  local first_md
  first_md="$(ls "$TEST_TEMP_DIR/.claude/rules/org/"*.md | head -1)"
  assert [ -L "$first_md" ]
}

@test "copy mode creates regular files" {
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  assert_success
  assert [ -d "$TEST_TEMP_DIR/.claude/rules/org" ]

  # Verify files are NOT symlinks
  local first_md
  first_md="$(ls "$TEST_TEMP_DIR/.claude/rules/org/"*.md | head -1)"
  assert [ ! -L "$first_md" ]
  assert [ -f "$first_md" ]
}

@test "marker file has correct shape" {
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_success
  assert_marker_shape
}

@test "copy mode marker records --copy" {
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  assert_success
  local line5
  line5="$(sed -n '5p' "$TEST_TEMP_DIR/.claude/rules/org/.claude-secure-config")"
  assert_equal "$line5" "--copy"
}

@test "install is idempotent" {
  create_git_target
  if [ "${COPY_MODE_ONLY:-}" = "true" ]; then
    # Copy mode: re-install with --copy --force (copies are regular files,
    # conflict detection fires without --force)
    run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
    assert_success
    local count1
    count1="$(count_installed_rules)"

    run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy --force
    assert_success
  else
    # Symlink mode: ln -sf overwrites existing symlinks cleanly
    run bash "$SETUP_SH" "$TEST_TEMP_DIR"
    assert_success
    local count1
    count1="$(count_installed_rules)"

    run bash "$SETUP_SH" "$TEST_TEMP_DIR"
    assert_success
  fi
  local count2
  count2="$(count_installed_rules)"

  assert_equal "$count1" "$count2"
}

@test "installs correct number of rule files" {
  create_git_target
  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_success
  local count
  count="$(count_installed_rules)"
  assert_equal "$count" "7"
}

@test "internal rules installed when present" {
  skip_if_copy_only
  create_git_target

  # Create a fake internal rule
  local script_dir
  script_dir="$(cd "$(dirname "$SETUP_SH")" && pwd)"
  mkdir -p "$script_dir/internal"
  echo "# test rule" > "$script_dir/internal/test-internal.md"

  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --internal --yes
  assert_success
  assert [ -e "$TEST_TEMP_DIR/.claude/rules/org/test-internal.md" ]
  assert_output --partial "internal"

  # Clean up
  rm -rf "$script_dir/internal"
}

@test "gitignore reminder shown for symlink mode only" {
  skip_if_copy_only
  create_git_target

  run bash "$SETUP_SH" "$TEST_TEMP_DIR"
  assert_success
  assert_output --partial "gitignore"

  # Copy mode should not show reminder
  rm -rf "$TEST_TEMP_DIR/.claude"
  run bash "$SETUP_SH" "$TEST_TEMP_DIR" --copy
  assert_success
  refute_output --partial "gitignore"
}
