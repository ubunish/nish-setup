#!/usr/bin/env bash
# CLI tools via Homebrew — the formula list is MACOS_FORMULAE in the manifest.
# starship also needs an init line in ~/.zshrc; the brew loop only drops the binary.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
require_macos
has_cmd brew || { err "brew missing — run 00-homebrew.sh first"; exit 1; }

do_check() {
  local f
  for f in "${MACOS_FORMULAE[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      ok "$f installed"
    else
      warn "$f not installed"
    fi
  done
  if grep -qF 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
    ok "starship init line in ~/.zshrc"
  else
    warn "starship init line missing from ~/.zshrc"
  fi
  return 0
}

do_install() {
  local f
  for f in "${MACOS_FORMULAE[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      skip "$f"
    else
      log "brew install $f"
      brew install "$f"
      ok "$f"
    fi
  done
  ensure_line "$HOME/.zshrc" 'eval "$(starship init zsh)"'
  ok "starship init line in ~/.zshrc"
}

# do_uninstall [FORMULA...] — remove named formulae, or every MACOS_FORMULAE when
# none given. The starship init line is only stripped when starship is a target.
do_uninstall() {
  local targets=("$@")
  ((${#targets[@]})) || targets=("${MACOS_FORMULAE[@]}")
  local f
  for f in "${targets[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      log "brew uninstall $f"
      brew uninstall "$f"
      ok "$f removed"
    else
      skip "$f not installed"
    fi
  done
  if _in_list starship "${targets[@]}"; then
    strip_line "$HOME/.zshrc" 'eval "$(starship init zsh)"'
    ok "starship init line removed from ~/.zshrc"
  fi
}

dispatch "$@"
