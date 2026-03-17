#!/bin/bash
set -euo pipefail

# claude-secure-config setup
# Symlinks shared rules into a target repo's .claude/rules/org/ directory.
# Also installs internal rules from internal/ if present.
#
# Usage:
#   bash setup.sh /path/to/target-repo
#   bash setup.sh /path/to/target-repo --copy       # copy instead of symlink
#   bash setup.sh /path/to/target-repo --uninstall   # remove installed rules
#   bash setup.sh /path/to/target-repo --status       # show what's installed
#   bash setup.sh /path/to/target-repo --dry-run      # preview without changes
#   bash setup.sh /path/to/target-repo --copy --dry-run
#
# Requires: bash 4+. Symlink mode requires a Unix-like OS (macOS, Linux, WSL).

readonly VERSION="1.0.0"
readonly MARKER=".claude-secure-config"

# --- Resolve script directory (follows symlinks to real location) ---

resolve_script_dir() {
  local source="$0"
  # Follow symlinks until we reach the actual file
  while [ -L "$source" ]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    # Handle relative symlink (resolve relative to the symlink's directory)
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
readonly SCRIPT_DIR
readonly RULES_DIR="$SCRIPT_DIR/rules"
readonly INTERNAL_DIR="$SCRIPT_DIR/internal"

# Explicit allowlist of shared rule files — no wildcards for security
# If you add a new rule file to rules/, add it here
readonly SHARED_RULES="code-hygiene.md cognitive-scaffold.md deliberation.md git-conventions.md security.md task-protocol.md"

# --- Helpers ---

die() {
  echo "Error: $*" >&2
  exit 1
}

warn() {
  echo "Warning: $*" >&2
}

# Canonicalize a path (resolve symlinks, .., spaces). Works on macOS and Linux.
# Falls back to cd+pwd if realpath is unavailable.
canonicalize() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
  elif command -v readlink >/dev/null 2>&1 && readlink -f "$path" >/dev/null 2>&1; then
    readlink -f "$path"
  else
    # Fallback: only works for directories
    (cd "$path" && pwd -P) || die "Failed to resolve path '$path'."
  fi
}

# Count .md files in a directory (without ls or glob expansion in an if-test)
count_md_files() {
  local dir="$1"
  local count=0
  for f in "$dir"/*.md; do
    [ -f "$f" ] && count=$((count + 1))
  done
  echo "$count"
}

# --- Usage ---

usage() {
  cat <<'USAGE'
Usage: bash setup.sh /path/to/target-repo [OPTIONS]

Install shared Claude Code rules into a target repository.

Options:
  --copy        Copy files instead of symlinking (required on Windows without WSL)
  --internal    Also install custom rules from internal/ (requires confirmation)
  --yes, -y     Skip confirmation prompts (for CI/scripted usage)
  --uninstall   Remove all rules installed by this tool
  --status      Show what's currently installed
  --dry-run     Preview what would happen without making changes
  --force       Overwrite non-symlink files in org/ without prompting
  --version     Show version
  --help        Show this help

Examples:
  bash setup.sh ~/projects/my-app              # symlink rules
  bash setup.sh ~/projects/my-app --copy       # copy instead
  bash setup.sh ~/projects/my-app --dry-run    # preview
  bash setup.sh ~/projects/my-app --uninstall  # clean up
USAGE
  exit 0
}

# --- Argument parsing ---

TARGET=""
MODE=""
ACTION="install"
DRY_RUN=false
FORCE=false
INSTALL_INTERNAL=false
CONFIRM_YES=false

while [ $# -gt 0 ]; do
  case "$1" in
    --copy)      MODE="--copy"; shift ;;
    --internal)  INSTALL_INTERNAL=true; shift ;;
    --yes|-y)    CONFIRM_YES=true; shift ;;
    --uninstall)
      if [ "$ACTION" != "install" ]; then die "Conflicting flags: cannot use --uninstall with --$ACTION."; fi
      ACTION="uninstall"; shift ;;
    --status)
      if [ "$ACTION" != "install" ]; then die "Conflicting flags: cannot use --status with --$ACTION."; fi
      ACTION="status"; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --force)     FORCE=true; shift ;;
    --version)   echo "claude-secure-config $VERSION"; exit 0 ;;
    --help|-h)   usage ;;
    -*)          die "Unknown option '$1'. See --help." ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        die "Unexpected argument '$1'. Only one target directory allowed."
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  usage
fi

# --- Validate target ---

if [ ! -e "$TARGET" ]; then
  die "'$TARGET' does not exist."
fi

if [ ! -d "$TARGET" ]; then
  die "'$TARGET' is not a directory."
fi

# Canonicalize target to handle spaces, relative paths, trailing slashes
TARGET="$(canonicalize "$TARGET")"
readonly TARGET

if [ ! -d "$TARGET/.git" ] && [ ! -f "$TARGET/.git" ]; then
  warn "'$TARGET' does not appear to be a git repository."
fi

readonly DEST="$TARGET/.claude/rules/org"

# --- Status command ---

do_status() {
  if [ ! -d "$DEST" ]; then
    echo "Not installed: $DEST does not exist."
    return
  fi

  local marker_file="$DEST/$MARKER"
  if [ -f "$marker_file" ]; then
    echo "Installed (managed by claude-secure-config):"
    echo "  Marker:  $marker_file"
    echo "  Source:  $(sed -n '2p' "$marker_file" 2>/dev/null || echo 'unknown')"
    echo "  Date:    $(sed -n '3p' "$marker_file" 2>/dev/null || echo 'unknown')"
    echo "  Version: $(sed -n '4p' "$marker_file" 2>/dev/null || echo 'unknown')"
    echo ""
  else
    echo "Directory exists but is NOT managed by claude-secure-config."
    echo "  Path: $DEST"
    echo ""
  fi

  echo "Contents:"
  local found=false
  for f in "$DEST"/*; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    found=true
    local name
    name="$(basename "$f")"
    if [ -L "$f" ]; then
      local link_target
      link_target="$(readlink "$f")"
      if [ -e "$f" ]; then
        echo "  $name -> $link_target"
      else
        echo "  $name -> $link_target  [BROKEN]"
      fi
    elif [ -f "$f" ]; then
      echo "  $name (file)"
    fi
  done
  if [ "$found" = false ]; then
    echo "  (empty)"
  fi
}

# --- Uninstall command ---

do_uninstall() {
  if [ ! -d "$DEST" ]; then
    echo "Nothing to uninstall: $DEST does not exist."
    return
  fi

  local marker_file="$DEST/$MARKER"
  if [ ! -f "$marker_file" ] && [ "$FORCE" = false ]; then
    die "$DEST exists but was not installed by claude-secure-config (no $MARKER file). Use --force to remove anyway."
  fi

  echo "Uninstalling rules from $DEST ..."
  local removed=0
  for f in "$DEST"/*.md; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    local name
    name="$(basename "$f")"
    if [ "$DRY_RUN" = true ]; then
      echo "  Would remove $name"
    else
      rm -f "$f"
      echo "  Removed $name"
    fi
    removed=$((removed + 1))
  done

  # Remove the marker file
  if [ -f "$marker_file" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  Would remove $MARKER"
    else
      rm -f "$marker_file"
      echo "  Removed $MARKER"
    fi
  fi

  # Remove org/ directory if empty
  if [ "$DRY_RUN" = false ] && [ -d "$DEST" ]; then
    if [ -z "$(ls -A "$DEST" 2>/dev/null)" ]; then
      rmdir "$DEST" 2>/dev/null || true
      echo "  Removed empty directory $DEST"
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "(dry run -- no changes made)"
  else
    echo ""
    echo "Done. Removed $removed rule(s)."
  fi
}

# --- Install command ---

do_install() {
  # Validate source rules exist
  if [ ! -d "$RULES_DIR" ]; then
    die "Rules directory not found at '$RULES_DIR'. Is this repo intact?"
  fi

  # Validate at least one allowlisted rule file exists
  local shared_count=0
  for _rule_name in $SHARED_RULES; do
    [ -f "$RULES_DIR/$_rule_name" ] && shared_count=$((shared_count + 1))
  done
  if [ "$shared_count" -eq 0 ]; then
    die "No allowlisted rule files found in '$RULES_DIR'. Is this repo intact?"
  fi

  # Check for non-managed files in destination that would be overwritten
  if [ -d "$DEST" ] && [ "$FORCE" = false ]; then
    local conflicts=""
    for name in $SHARED_RULES; do
      local dest_file="$DEST/$name"
      if [ -e "$dest_file" ] && [ ! -L "$dest_file" ]; then
        conflicts="${conflicts}  ${name}"$'\n'
      fi
    done
    if [ -d "$INTERNAL_DIR" ]; then
      for rule in "$INTERNAL_DIR"/*.md; do
        [ -f "$rule" ] || continue
        local name
        name="$(basename "$rule")"
        local dest_file="$DEST/$name"
        if [ -e "$dest_file" ] && [ ! -L "$dest_file" ]; then
          conflicts="${conflicts}  ${name}"$'\n'
        fi
      done
    fi
    if [ -n "$conflicts" ]; then
      echo "Warning: The following files in $DEST are regular files (not symlinks)" >&2
      echo "and would be overwritten:" >&2
      printf '%s' "$conflicts" >&2
      die "Use --force to overwrite, or back them up first."
    fi
  fi

  # Create destination
  if [ "$DRY_RUN" = true ]; then
    echo "[dry run] Would create $DEST"
  else
    local mkdir_err
    mkdir_err="$(mkdir -p "$DEST" 2>&1)" || die "Failed to create directory '$DEST': $mkdir_err"
  fi

  local installed=0

  # Install specific named files from a directory
  install_rules_explicit() {
    local src_dir="$1"
    local label="$2"
    shift 2

    for filename in "$@"; do
      local rule="$src_dir/$filename"
      if [ ! -f "$rule" ]; then
        warn "Expected rule file '$filename' not found in $src_dir — skipping."
        continue
      fi
      local dest_file="$DEST/$filename"

      if [ "$DRY_RUN" = true ]; then
        if [ "$MODE" = "--copy" ]; then
          echo "  Would copy $filename ($label)"
        else
          echo "  Would link $filename ($label)"
        fi
      elif [ "$MODE" = "--copy" ]; then
        if ! cp "$rule" "$dest_file"; then
          die "Failed to copy '$rule' to '$dest_file'."
        fi
        echo "  Copied $filename ($label)"
      else
        if ! ln -sf "$rule" "$dest_file"; then
          die "Failed to create symlink '$dest_file' -> '$rule'."
        fi
        echo "  Linked $filename ($label)"
      fi
      installed=$((installed + 1))
    done
  }

  # Install all .md files from a directory (used for internal/ only)
  install_rules_glob() {
    local src_dir="$1"
    local label="$2"

    for rule in "$src_dir"/*.md; do
      [ -f "$rule" ] || continue
      local filename
      filename="$(basename "$rule")"
      local dest_file="$DEST/$filename"

      if [ "$DRY_RUN" = true ]; then
        if [ "$MODE" = "--copy" ]; then
          echo "  Would copy $filename ($label)"
        else
          echo "  Would link $filename ($label)"
        fi
      elif [ "$MODE" = "--copy" ]; then
        if ! cp "$rule" "$dest_file"; then
          die "Failed to copy '$rule' to '$dest_file'."
        fi
        echo "  Copied $filename ($label)"
      else
        if ! ln -sf "$rule" "$dest_file"; then
          die "Failed to create symlink '$dest_file' -> '$rule'."
        fi
        echo "  Linked $filename ($label)"
      fi
      installed=$((installed + 1))
    done
  }

  _INSTALL_STARTED=true
  echo "Installing shared rules..."
  # shellcheck disable=SC2086 # Intentional word splitting — SHARED_RULES is a space-separated allowlist
  install_rules_explicit "$RULES_DIR" "shared" $SHARED_RULES

  # Install internal/custom rules only when explicitly requested
  if [ "$INSTALL_INTERNAL" = true ]; then
    if [ -d "$INTERNAL_DIR" ]; then
      local internal_count
      internal_count="$(count_md_files "$INTERNAL_DIR")"
      if [ "$internal_count" -gt 0 ]; then
        echo ""
        echo "Custom rules found in internal/:"
        for rule in "$INTERNAL_DIR"/*.md; do
          [ -f "$rule" ] || continue
          echo "  $(basename "$rule")"
        done
        if [ "$DRY_RUN" = false ]; then
          if [ "$CONFIRM_YES" = true ]; then
            echo ""
            echo "Installing internal rules (--yes confirmed)..."
            install_rules_glob "$INTERNAL_DIR" "internal"
          elif [ -t 0 ]; then
            printf "\nInstall these custom rules? [y/N] "
            read -r confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
              echo "Skipped internal rules."
            else
              echo ""
              echo "Installing internal rules..."
              install_rules_glob "$INTERNAL_DIR" "internal"
            fi
          else
            die "Non-interactive shell detected. Use --yes to confirm internal rule installation."
          fi
        else
          echo ""
          echo "Internal rules (dry run)..."
          install_rules_glob "$INTERNAL_DIR" "internal"
        fi
      fi
    else
      warn "internal/ directory not found. No custom rules to install."
    fi
  fi

  if [ "$installed" -eq 0 ]; then
    warn "No rule files were installed."
    return
  fi

  # Write marker file for provenance tracking
  if [ "$DRY_RUN" = false ]; then
    {
      printf '%s\n' "# Managed by claude-secure-config. Do not edit."
      printf '%s\n' "$SCRIPT_DIR"
      printf '%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      printf '%s\n' "$VERSION"
      printf '%s\n' "$MODE"
    } > "$DEST/$MARKER"
  fi

  # Detect and report orphaned files (installed previously but no longer in source)
  if [ -d "$DEST" ] && [ "$DRY_RUN" = false ]; then
    local orphans=""
    for existing in "$DEST"/*.md; do
      [ -e "$existing" ] || [ -L "$existing" ] || continue
      local name
      name="$(basename "$existing")"
      # Check if this file came from our source dirs
      if [ ! -f "$RULES_DIR/$name" ] && [ ! -f "$INTERNAL_DIR/$name" ]; then
        orphans="${orphans}  ${name}"
        # Report broken symlinks distinctly
        if [ -L "$existing" ] && [ ! -e "$existing" ]; then
          orphans="${orphans}  [BROKEN SYMLINK]"
        fi
        orphans="${orphans}"$'\n'
      fi
    done
    if [ -n "$orphans" ]; then
      echo ""
      warn "Orphaned files in $DEST (not in current source):"
      printf '%s' "$orphans" >&2
      echo "  Remove manually or run with --uninstall to clean up." >&2
    fi
  fi

  echo ""
  if [ "$DRY_RUN" = true ]; then
    echo "(dry run -- no changes made)"
  else
    echo "Done. $installed rule(s) installed to $DEST"
    if [ "$MODE" != "--copy" ]; then
      # Check if .gitignore already has the entry
      local gitignore="$TARGET/.gitignore"
      if [ -f "$gitignore" ] && grep -q "^\.claude/rules/org/" "$gitignore" 2>/dev/null; then
        : # already in .gitignore
      else
        echo "Reminder: Add .claude/rules/org/ to .gitignore (symlinks shouldn't be committed)."
      fi
    fi
  fi
}

# --- Cleanup trap ---

_cleanup_on_exit() {
  if [ -n "${_INSTALL_STARTED:-}" ] && [ -d "${DEST:-}" ] && [ ! -f "${DEST:-}/$MARKER" ]; then
    echo "Warning: Install was interrupted. Run --uninstall --force to clean up." >&2
  fi
}
trap _cleanup_on_exit EXIT

# --- Dispatch ---

case "$ACTION" in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  status)    do_status ;;
  *)         die "Unknown action: $ACTION" ;;
esac
