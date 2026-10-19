#!/bin/bash
# Installs the root helpers to /Library/Doze and writes the sudoers entry.
#
# Usage:
#   sudo ./install.sh              install or update (shows a diff, asks first)
#   sudo ./install.sh --yes        install or update without asking
#   sudo ./install.sh --uninstall  remove the helpers and the sudoers entry
#
# The helpers run as root with passwordless sudo, so they must live where
# nothing running as your user can replace them. Every directory in
# /Library/Doze's path is root-owned; the copy in this repo is only the source.
# Re-run after every update that touches helpers/.
#
# It also prunes old doze sudo entries: any NOPASSWD line for a doze-on.sh or
# doze-off.sh outside /Library/Doze. Those point at user-writable paths (the
# repo, ~/.myscripts, ...), which anything running as you could replace to get
# root. Pruned files are backed up next to the original as <name>.doze-bak.

set -euo pipefail

INSTALL_DIR="/Library/Doze"
SUDOERS_DIR="/etc/sudoers.d"
SUDOERS_FILE="$SUDOERS_DIR/doze"
MAIN_SUDOERS="/etc/sudoers"
HELPERS=(doze-on.sh doze-off.sh)
SRC_DIR="$(cd "$(dirname "$0")" && pwd)/helpers"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'
else
  BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; CYAN=""
fi

header() { printf '\n%s🌙 Doze%s  %s%s%s\n%s──────────────────────────────────────────%s\n' "$BOLD" "$RESET" "$DIM" "$1" "$RESET" "$DIM" "$RESET"; }
step()   { printf '\n%s▸ %s%s\n' "$CYAN$BOLD" "$1" "$RESET"; }
ok()     { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
note()   { printf '  %s•%s %s\n' "$YELLOW" "$RESET" "$1"; }
info()   { printf '  %s%s%s\n' "$DIM" "$1" "$RESET"; }
fail()   { printf '\n%s✗ %s%s\n' "$RED$BOLD" "$1" "$RESET" >&2; exit 1; }

# Colors a unified diff and indents it.
show_diff() {
  diff -u "$1" "$2" | tail -n +3 | while IFS= read -r LINE; do
    case "$LINE" in
      @@*) printf '    %s%s%s\n' "$CYAN" "$LINE" "$RESET" ;;
      +*)  printf '    %s%s%s\n' "$GREEN" "$LINE" "$RESET" ;;
      -*)  printf '    %s%s%s\n' "$RED" "$LINE" "$RESET" ;;
      *)   printf '    %s%s%s\n' "$DIM" "$LINE" "$RESET" ;;
    esac
  done || true
}

# Prints a file's contents indented, so a first install can be reviewed too.
show_file() {
  while IFS= read -r LINE; do
    printf '    %s│%s %s\n' "$DIM" "$RESET" "$LINE"
  done < "$1"
}

# A stale entry grants NOPASSWD on a doze helper from outside INSTALL_DIR.
is_stale_line() {
  case "$1" in \#*) return 1 ;; esac
  [[ "$1" =~ NOPASSWD:.*/doze-(on|off)\.sh ]] || return 1
  [[ "$1" == *"$INSTALL_DIR/"* ]] && return 1
  return 0
}

# Fills STALE_REPORT with "<sudoers file><TAB><line>" for every stale entry.
# sudo ignores files in sudoers.d whose name contains a dot, so those are skipped.
scan_stale() {
  local FILE LINE
  : > "$STALE_REPORT"
  for FILE in "$MAIN_SUDOERS" "$SUDOERS_DIR"/*; do
    [ -f "$FILE" ] || continue
    case "$(basename "$FILE")" in *.*|*~) continue ;; esac
    while IFS= read -r LINE || [ -n "$LINE" ]; do
      if is_stale_line "$LINE"; then
        printf '%s\t%s\n' "$FILE" "$LINE" >> "$STALE_REPORT"
      fi
    done < "$FILE"
  done
}

# Removes stale lines from every file except our own (rewritten below) and the
# main sudoers file (left for visudo). Keeps a backup and validates before swapping.
prune_stale() {
  local FILE LINE KEEP
  while IFS= read -r FILE; do
    if [ "$FILE" = "$SUDOERS_FILE" ]; then
      continue
    fi
    if [ "$FILE" = "$MAIN_SUDOERS" ]; then
      note "$MAIN_SUDOERS has a stale entry: remove it by hand with 'sudo visudo'"
      continue
    fi
    KEEP="$(mktemp)"
    while IFS= read -r LINE || [ -n "$LINE" ]; do
      if ! is_stale_line "$LINE"; then
        printf '%s\n' "$LINE" >> "$KEEP"
      fi
    done < "$FILE"
    visudo -cf "$KEEP" > /dev/null || { rm -f "$KEEP"; fail "Pruned $FILE would be invalid, left untouched"; }
    cp -p "$FILE" "$FILE.doze-bak"
    if grep -qvE '^[[:space:]]*(#|$)' "$KEEP"; then
      install -o root -g wheel -m 440 "$KEEP" "$FILE"
      ok "Pruned $FILE  ${DIM}backup: $FILE.doze-bak${RESET}"
    else
      rm -f "$FILE"
      ok "Removed $FILE (only held doze entries)  ${DIM}backup: $FILE.doze-bak${RESET}"
    fi
    rm -f "$KEEP"
  done < <(cut -f1 "$STALE_REPORT" | sort -u)
}

if [ "$(id -u)" -ne 0 ]; then
  fail "Needs root. Run: sudo $0 $*"
fi

if [ "${1:-}" = "--uninstall" ]; then
  header "uninstall"
  step "Removing"
  rm -rf "$INSTALL_DIR"
  ok "Removed $INSTALL_DIR"
  rm -f "$SUDOERS_FILE"
  ok "Removed $SUDOERS_FILE"
  printf '\n%sDone.%s Doze commands will ask you to run ./install.sh again.\n\n' "$BOLD" "$RESET"
  exit 0
fi

ASSUME_YES=0
if [ "${1:-}" = "--yes" ]; then
  ASSUME_YES=1
elif [ -n "${1:-}" ]; then
  fail "Unknown option: $1 (use --yes or --uninstall)"
fi

# The sudoers entry is written for the user who invoked sudo.
if [ -z "${SUDO_USER:-}" ] || [ "$SUDO_USER" = "root" ] || ! [[ "$SUDO_USER" =~ ^[A-Za-z0-9._-]+$ ]]; then
  fail "Run via sudo from your normal user account (SUDO_USER is '${SUDO_USER:-}')"
fi

STALE_REPORT="$(mktemp)"
TMP_SUDOERS=""
trap 'rm -f "$STALE_REPORT" "$TMP_SUDOERS"' EXIT

header "installer"
info "Installs the root helpers to $INSTALL_DIR for user '$SUDO_USER'"

step "Checking helpers"
CHANGED=0
for HELPER in "${HELPERS[@]}"; do
  if [ ! -f "$SRC_DIR/$HELPER" ]; then
    fail "Missing source: $SRC_DIR/$HELPER"
  fi
  if [ ! -f "$INSTALL_DIR/$HELPER" ]; then
    note "$HELPER  ${YELLOW}new${RESET}"
    show_file "$SRC_DIR/$HELPER"
    CHANGED=1
  elif ! cmp -s "$SRC_DIR/$HELPER" "$INSTALL_DIR/$HELPER"; then
    note "$HELPER  ${YELLOW}changed${RESET}"
    show_diff "$INSTALL_DIR/$HELPER" "$SRC_DIR/$HELPER"
    CHANGED=1
  else
    ok "$HELPER  ${DIM}up to date${RESET}"
  fi
done

step "Checking for old sudo entries"
scan_stale
if [ -s "$STALE_REPORT" ]; then
  CHANGED=1
  while IFS="$(printf '\t')" read -r STALE_FILE STALE_LINE; do
    note "${STALE_FILE}  ${YELLOW}stale${RESET}"
    info "  $STALE_LINE"
    for STALE_PATH in $(printf '%s\n' "$STALE_LINE" | grep -oE '/[^ ,]*doze-(on|off)\.sh'); do
      if [ -e "$STALE_PATH" ]; then
        info "  ↳ $STALE_PATH exists, but sits outside root-owned $INSTALL_DIR"
      else
        info "  ↳ $STALE_PATH is missing: anything running as you could create it and run it as root"
      fi
    done
  done < "$STALE_REPORT"
else
  ok "None found"
fi

if [ "$CHANGED" -eq 1 ] && [ "$ASSUME_YES" -eq 0 ]; then
  printf '\n  %s⚠  These scripts will run as root.%s Review them above before continuing.\n' "$YELLOW$BOLD" "$RESET"
  printf '  Install to %s? %s[y/N]%s ' "$INSTALL_DIR" "$BOLD" "$RESET"
  read -r ANSWER < /dev/tty
  if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    fail "Aborted, nothing was changed"
  fi
fi

step "Installing helpers"
install -d -o root -g wheel -m 755 "$INSTALL_DIR"
for HELPER in "${HELPERS[@]}"; do
  install -o root -g wheel -m 555 "$SRC_DIR/$HELPER" "$INSTALL_DIR/$HELPER"
  ok "$INSTALL_DIR/$HELPER  ${DIM}root:wheel 555${RESET}"
done

step "Writing sudoers entry"
TMP_SUDOERS="$(mktemp)"
{
  echo "# Managed by doze install.sh. Re-run the installer instead of editing."
  for HELPER in "${HELPERS[@]}"; do
    echo "$SUDO_USER ALL=(ALL) NOPASSWD: $INSTALL_DIR/$HELPER"
  done
} > "$TMP_SUDOERS"

visudo -cf "$TMP_SUDOERS" > /dev/null
ok "Validated with visudo"
install -o root -g wheel -m 440 "$TMP_SUDOERS" "$SUDOERS_FILE"
ok "$SUDOERS_FILE  ${DIM}replaces any older doze entries${RESET}"

if [ -s "$STALE_REPORT" ]; then
  step "Pruning old sudo entries"
  prune_stale
fi

REPO_DIR="$(dirname "$SRC_DIR")"

printf '\n%s%s✓ Helpers installed.%s\n' "$GREEN" "$BOLD" "$RESET"

step "Last step: add Doze to Raycast (one time)"
printf '  %s1.%s Open Raycast Settings %s(⌘ ,)%s > %sExtensions%s > %sScript Commands%s\n' "$BOLD" "$RESET" "$DIM" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET"
printf '  %s2.%s Click %sAdd Directory%s and choose:\n' "$BOLD" "$RESET" "$BOLD" "$RESET"
printf '       %s%s%s\n' "$CYAN$BOLD" "$REPO_DIR" "$RESET"
printf '  %s3.%s Run %sDoze > Toggle%s in Raycast to try it\n' "$BOLD" "$RESET" "$BOLD" "$RESET"
info "Already added this folder before? Skip to step 3."
info "Check anytime: pmset -g | grep SleepDisabled"
printf '\n'
