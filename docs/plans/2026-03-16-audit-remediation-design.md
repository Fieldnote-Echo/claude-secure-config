# Audit Remediation Design

**Date:** 2026-03-16
**Status:** approved

## Context

Five-vector opus audit of the full repo identified 37+ findings across security/bypass, shell correctness, test coverage, CI supply chain, and docs consistency. This design covers the full sweep, organized into two PRs by risk profile.

## PR Structure

- **PR1 (fix/audit-security-shell):** Behavior-changing fixes — hook regex, setup.sh bugs, --internal hardening, docs sync
- **PR2 (fix/audit-tests-ci):** Additive-only — test expansion, CI supply chain, reliability fixes

PR1 merges first. PR2 tests the fixes from PR1.

## PR1: Security Fixes + Shell Hardening

### 1a. Hook regex fixes (hooks.md + fixture)

| Finding | Fix |
|---------|-----|
| C1: secrets/ ungrouped alternation | Group under verb prefix |
| C2: rm -r without -f passes | Block rm -r independently |
| H3: --force-with-lease exclusion bypass | Verify safe flag in same git push invocation |
| H2: bash -c doesn't cover other shells | Extend to bash/sh/dash/ksh/zsh/fish |
| H4: chmod u+s not caught | Add chmod.*+s and symbolic modes |
| H5: --no-verify gaps | Add git am to subcommand list |
| H6: Path-qualified .env verbs | Add (/usr/bin/\|/bin/)? prefix |
| H1: Newline injection | Strip newlines from $CMD before matching |
| M3: dd narrowness | Catch dd with output redirection |
| DRIFT-2/3: Fixture drift | Sync messages and \b pattern with hooks.md |

### 1b. Shell bugs in setup.sh

| Finding | Fix |
|---------|-----|
| BUG-1: Unquoted heredoc | Replace with printf '%s\n' |
| BUG-2: Unprotected rmdir | rmdir ... 2>/dev/null \|\| true |
| ROBUST-1: No signal trap | Add trap cleanup EXIT |
| ROBUST-2: Conflicting flags | Detect and error |
| ROBUST-3: printf %b backslash | Use actual newlines + printf '%s' |
| ROBUST-4: canonicalize cryptic error | Add \|\| die fallback |
| STYLE-2: No-op 2>/dev/null | Remove |
| STYLE-4: Generic mkdir error | Include OS error |

### 1c. --internal flag hardening

- Add --yes flag for non-interactive mode (CI)
- Detect non-interactive tty, error with guidance
- Code fix in PR1, tests in PR2

### 1d. README and docs sync

- Document all setup.sh flags (--uninstall, --status, --dry-run, --force, --version, --internal, --yes)
- Document marker file and orphan tracking
- Fix rm description in hooks.md ("recursive or force", not "recursive + force")
- Update line count

## PR2: Test Expansion + CI Hardening

### 2a. Hook test coverage (~20% to ~80%)

New tests for: protected branch pushes, refspec pushes, all destructive git commands, git am --no-verify, shell execution variants (zsh -c, dash -c, eval, curl|bash), secrets access variants (source, cp, base64, grep secrets/), chmod symbolic modes, dd, ln .env, false positives (safe commands that must pass), edge cases (empty/malformed JSON).

### 2b. setup.sh test coverage gaps

New tests for: --internal flag (with --yes, without flag, missing internal/), --help/-h, symlink-mode uninstall, symlink-mode status output, conflicting flags error, marker line 5 empty, gitignore entry suppression.

### 2c. Test reliability fixes

- Internal rules test: use temp copy instead of mutating live repo
- jq: add skip guard in hooks.bats
- python3: skip if unavailable
- Rule count: derive from source directory
- Hook assertions: remove redundant assert_failure, add message checks

### 2d. CI supply chain hardening

- Bats: add SHA verification after git clone
- shellcheck: pin version or download with checksum
- jq: pin or document as acceptable risk
- actions/checkout: update comment to v4.3.1
- Version bumps: bats-assert v2.2.4, evaluate markdownlint/lychee

### 2e. Remaining items

- STYLE-3: grep -qF for gitignore check
- STYLE-5: BASH_SOURCE guard
- All LOW items: document as known limitations
- STYLE-1 (MODE stores raw flag): document, don't change
