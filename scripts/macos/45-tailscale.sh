#!/usr/bin/env bash
# Tailscale, plus the one-time CLI shim.
#
# The macOS app keeps its `tailscale` binary inside the bundle, where nothing on
# PATH can reach it — unlike Linux, where the installer drops it in /usr/bin.
#
# A symlink does not work: the binary locates its own bundle from its executable
# path, and through a symlink that path lands outside the bundle, so every call
# dies with "The current bundleIdentifier is unknown to the registry". A shim
# that execs the real path keeps the bundle resolvable. The Homebrew prefix is
# user-writable, so no sudo.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
require_macos

TS_APP="/Applications/Tailscale.app"
TS_APP_BIN="$TS_APP/Contents/MacOS/Tailscale"
if has_cmd brew; then
  TS_SHIM="$(brew --prefix)/bin/tailscale"
else
  TS_SHIM="/usr/local/bin/tailscale"
fi

# Marker line identifying a shim this step wrote, so check and uninstall never
# touch a `tailscale` that arrived some other way.
TS_MARKER="# nish-setup: Tailscale.app CLI shim"

is_our_shim() {
  [[ -f "$TS_SHIM" ]] && grep -qF "$TS_MARKER" "$TS_SHIM" 2>/dev/null
}

write_shim() {
  cat >"$TS_SHIM" <<EOF
#!/bin/sh
$TS_MARKER
exec "$TS_APP_BIN" "\$@"
EOF
  chmod +x "$TS_SHIM"
}

do_check() {
  if [[ -x "$TS_APP_BIN" ]]; then
    ok "Tailscale.app installed"
  else
    warn "Tailscale.app missing"
  fi

  if is_our_shim; then
    ok "tailscale CLI shim installed ($TS_SHIM)"
  elif [[ -e "$TS_SHIM" ]]; then
    warn "$TS_SHIM exists but was not written by nish-setup — left alone"
  else
    warn "tailscale CLI not on PATH"
  fi
  return 0
}

do_install() {
  # The App Store build lands at the same path, so an existing app is left
  # alone — installing the cask over it would leave two copies.
  if [[ -d "$TS_APP" ]]; then
    skip "Tailscale.app already installed"
  elif has_cmd brew; then
    log "brew install --cask tailscale-app"
    brew install --cask tailscale-app
    ok "Tailscale.app installed"
  else
    err "brew missing and Tailscale.app absent — install it, then re-run"
    return 1
  fi

  if is_our_shim; then
    skip "tailscale CLI shim already installed"
  elif [[ -e "$TS_SHIM" ]]; then
    # Most likely the symlink Tailscale's own docs suggest, which is broken.
    warn "$TS_SHIM exists and was not written by nish-setup — replacing it"
    rm -f "$TS_SHIM"
    write_shim
    ok "tailscale CLI shim installed"
  else
    log "Installing tailscale CLI shim → $TS_SHIM"
    write_shim
    ok "tailscale CLI shim installed"
  fi

  info "Start the app and sign in, then confirm the tailnet with: tailscale status"
  info "Reach a peer over SSH by its tailnet name: ssh <user>@<host>"
}

do_uninstall() {
  if is_our_shim; then
    log "Removing $TS_SHIM"
    rm -f "$TS_SHIM"
    ok "tailscale CLI shim removed"
  else
    skip "no nish-setup tailscale shim to remove"
  fi

  # The app itself is left in place — it may have come from the App Store, and
  # removing it would drop the machine off the tailnet.
  if [[ -d "$TS_APP" ]]; then
    warn "Tailscale.app left in place — remove it manually to leave the tailnet"
  fi
}

dispatch "$@"
