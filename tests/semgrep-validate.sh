#!/usr/bin/env bash
# Validates semgrep rules against annotated test fixtures.
#
# Uses semgrep's native --test framework (# ruleid: / # ok: annotations).
# Copies rules and fixtures to a temp dir because semgrep --test
# skips hidden directories (.semgrep/).
#
# Convention: rule file stem matches test file stem.
#   .semgrep/no-eval.yaml  <-->  tests/fixtures/semgrep/no-eval.{js,py,...}
set -euo pipefail

RULES_DIR=".semgrep"
FIXTURES_DIR="tests/fixtures/semgrep"

if [[ ! -d "$RULES_DIR" ]]; then
  echo "ERROR: Rules directory not found: $RULES_DIR" >&2
  exit 2
fi

if [[ ! -d "$FIXTURES_DIR" ]]; then
  echo "ERROR: Fixtures directory not found: $FIXTURES_DIR" >&2
  exit 2
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

cp "$RULES_DIR"/*.yaml "$WORK_DIR/"
cp "$FIXTURES_DIR"/* "$WORK_DIR/"

semgrep --test "$WORK_DIR/"
