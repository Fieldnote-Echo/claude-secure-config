#!/usr/bin/env bats

setup() {
  load "test_helper/common"
  source "$(dirname "$BATS_TEST_DIRNAME")/tests/fixtures/hook-commands.bash"
}

@test "rm -rf is blocked" {
  run run_pretooluse_hook '{"command": "rm -rf /"}'
  assert_failure
  assert [ "$status" -eq 2 ]
}

@test "git push --force is blocked" {
  run run_pretooluse_hook '{"command": "git push --force origin main"}'
  assert_failure
  assert [ "$status" -eq 2 ]
}

@test "git push -f (short flag) is blocked" {
  run run_pretooluse_hook '{"command": "git push -f origin main"}'
  assert_failure
  assert [ "$status" -eq 2 ]
}

@test "cat .env is blocked" {
  run run_pretooluse_hook '{"command": "cat .env"}'
  assert_failure
  assert [ "$status" -eq 2 ]
}

@test "safe command passes through" {
  run run_pretooluse_hook '{"command": "npm run test"}'
  assert_success
}

@test "git push --force-with-lease is allowed (no false positive)" {
  run run_pretooluse_hook '{"command": "git push --force-with-lease origin feature"}'
  assert_success
}

@test "--no-verify in echo is not blocked (no false positive)" {
  run run_pretooluse_hook '{"command": "echo \"do not use --no-verify\""}'
  assert_success
}

@test "hooks.md template command blocks rm -rf (docs wiring smoke test)" {
  # Extract the literal PreToolUse command from hooks.md and verify it works
  local hooks_md
  hooks_md="$(dirname "$BATS_TEST_DIRNAME")/hooks.md"
  local hook_cmd
  # Extract the command value from the JSON template in hooks.md
  hook_cmd="$(sed -n '/"matcher": "Bash"/,/"command":/{ s/.*"command": "//; s/"$//; p; }' "$hooks_md" | head -1)"

  if [ -z "$hook_cmd" ]; then
    skip "Could not extract hook command from hooks.md"
  fi

  export CLAUDE_TOOL_INPUT='{"command": "rm -rf /"}'
  run eval "$hook_cmd"
  assert_failure
  assert [ "$status" -eq 2 ]
}
