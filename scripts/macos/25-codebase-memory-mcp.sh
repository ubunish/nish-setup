#!/usr/bin/env bash
# codebase-memory-mcp: codebase knowledge-graph MCP server for AI agents.
# Installs the static binary (no agent config) and registers it with Claude
# Code at user scope, so every project gets the graph tools.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
require_macos

CBM_BIN="$HOME/.local/bin/codebase-memory-mcp"
CBM_INSTALL_URL="https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh"

# mcp_registered — 0 if Claude Code already has the codebase-memory server.
mcp_registered() {
  has_cmd claude && claude mcp list 2>/dev/null | grep -q '^codebase-memory:'
}

do_check() {
  if [[ -x "$CBM_BIN" ]]; then
    ok "codebase-memory-mcp installed ($("$CBM_BIN" --version 2>/dev/null | head -1))"
  else
    warn "codebase-memory-mcp not installed"
  fi
  if mcp_registered; then
    ok "registered with Claude Code (user scope)"
  else
    warn "not registered with Claude Code"
  fi
  return 0
}

do_install() {
  # --skip-config: install the binary only. We wire Claude Code ourselves at
  # user scope below, rather than letting the installer touch every agent.
  if [[ -x "$CBM_BIN" ]]; then
    ok "codebase-memory-mcp already installed ($("$CBM_BIN" --version 2>/dev/null | head -1))"
  else
    log "Installing codebase-memory-mcp (binary only)"
    curl -fsSL "$CBM_INSTALL_URL" | bash -s -- --skip-config
    ok "codebase-memory-mcp installed"
  fi

  # Register with Claude Code at user scope so all projects see the graph tools.
  if ! has_cmd claude; then
    warn "Claude Code not found — skipping MCP registration (run the claude-code step first)"
    return 0
  fi
  if mcp_registered; then
    ok "already registered with Claude Code"
  else
    log "Registering codebase-memory with Claude Code (user scope)"
    claude mcp add --scope user codebase-memory "$CBM_BIN"
    ok "registered — restart Claude Code, then say \"Index this project\""
  fi
}

do_uninstall() {
  if mcp_registered; then
    log "Removing codebase-memory from Claude Code"
    claude mcp remove --scope user codebase-memory 2>/dev/null || true
    ok "unregistered from Claude Code"
  fi
  if [[ -x "$CBM_BIN" ]]; then
    rm -f "$CBM_BIN"
    ok "codebase-memory-mcp binary removed"
  fi
  # Cached graphs in ~/.cache/codebase-memory-mcp/ are left in place.
}

dispatch "$@"
