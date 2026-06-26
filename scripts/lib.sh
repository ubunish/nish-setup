#!/usr/bin/env bash
# Shared helpers for setup scripts. Source, don't execute.

set -euo pipefail

# Pull in the manifest (step registries + package arrays). Sourcing here means
# every step that sources lib.sh also sees the manifest arrays.
# shellcheck source=scripts/manifest.sh
source "$(dirname "${BASH_SOURCE[0]}")/manifest.sh"

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'

log()    { printf '%s\n' "${BLUE}==>${RESET} ${BOLD}$*${RESET}"; }
info()   { printf '%s\n' "    $*"; }
ok()     { printf '%s\n' "${GREEN}    ✓${RESET} $*"; }
skip()   { printf '%s\n' "${DIM}    ↷ $* (skip)${RESET}"; }
warn()   { printf '%s\n' "${YELLOW}    !${RESET} $*"; }
err()    { printf '%s\n' "${RED}    ✗${RESET} $*" >&2; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ensure_line FILE LINE — append LINE to FILE once. Creates FILE if absent.
# Idempotent: a re-run finds the exact line already present and skips.
ensure_line() {
  local file="$1" line="$2"
  [[ -f "$file" ]] || touch "$file"
  grep -qF "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >>"$file"
}

# strip_line FILE LINE — remove every exact-match LINE from FILE (uninstall side).
strip_line() {
  local file="$1" line="$2"
  [[ -f "$file" ]] || return 0
  grep -vxF "$line" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
}

# pause "message" — print and wait for Enter (skipped under NONINTERACTIVE=1)
pause() {
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    warn "$* (NONINTERACTIVE — skipping pause)"
    return
  fi
  printf '%s\n' "${YELLOW}    →${RESET} $*"
  read -r -p "    Press Enter to continue… " _
}

# confirm "question" — y/N prompt; returns 0 on yes (auto-no under NONINTERACTIVE=1)
confirm() {
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    warn "$* — auto-declined (NONINTERACTIVE)"
    return 1
  fi
  local reply
  read -r -p "    ${YELLOW}?${RESET} $* [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

require_macos() { [[ "$(uname -s)" == "Darwin" ]] || { err "macOS only"; exit 1; }; }
require_linux() { [[ "$(uname -s)" == "Linux"  ]] || { err "Linux only";  exit 1; }; }

# --- Step gating -----------------------------------------------------------
# setup.sh fills DISABLED (from --skip) and ONLY (from --only) before iterating
# the manifest. These default empty so a step sourced standalone always runs.
DISABLED=("${DISABLED[@]:-}")
ONLY=("${ONLY[@]:-}")

# _in_list NEEDLE ITEM... — 0 if NEEDLE equals one of the ITEMs.
_in_list() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# is_enabled ID DEFAULT — decide whether step ID runs.
#   --only set   → run only ids in ONLY
#   id in DISABLED → skip
#   otherwise    → follow DEFAULT (on|off)
is_enabled() {
  local id="$1" default="$2"
  if ((${#ONLY[@]})) && [[ -n "${ONLY[0]:-}" ]]; then
    _in_list "$id" "${ONLY[@]}"
    return
  fi
  if ((${#DISABLED[@]})) && [[ -n "${DISABLED[0]:-}" ]]; then
    _in_list "$id" "${DISABLED[@]}" && return 1
  fi
  [[ "$default" == "on" ]]
}

# dispatch [MODE] — route a retrofitted step to its do_<mode> function.
# Steps define do_check / do_install / do_uninstall, then call: dispatch "$@"
dispatch() {
  local mode="${1:-install}"
  case "$mode" in
    check)     do_check ;;
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *) err "unknown mode: $mode (use check|install|uninstall)"; exit 1 ;;
  esac
}
