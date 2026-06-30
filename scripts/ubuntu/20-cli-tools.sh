#!/usr/bin/env bash
# Claude Code, gh CLI, uv, starship.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
require_linux

do_check() {
  has_cmd claude && ok "Claude Code installed" || warn "Claude Code missing"
  if claude plugin list 2>/dev/null | grep -q '^cloudflare\b'; then
    ok "cloudflare plugin installed"
  else
    warn "cloudflare plugin missing"
  fi
  has_cmd gh && ok "gh installed" || warn "gh missing"
  has_cmd uv && ok "uv installed" || warn "uv missing"
  has_cmd starship && ok "starship installed" || warn "starship missing"
  return 0
}

do_install() {
  # Claude Code
  if has_cmd claude; then
    ok "Claude Code already installed"
  else
    log "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
    ok "Claude Code installed"
  fi

  # Cloudflare plugin — bundles cloudflare, wrangler, durable-objects, agents-sdk,
  # sandbox-sdk, workers-best-practices, cloudflare-email-service, web-perf skills.
  if claude plugin list 2>/dev/null | grep -q '^cloudflare\b'; then
    ok "cloudflare plugin already installed"
  else
    log "Installing cloudflare Claude Code plugin"
    claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
    claude plugin install cloudflare@claude-plugins-official
    ok "cloudflare plugin installed"
  fi

  # gh CLI — needs the GitHub apt repo on Ubuntu 22.04
  if has_cmd gh; then
    ok "gh already installed"
  else
    log "Adding GitHub CLI apt repo + installing gh"
    KEYRING=/usr/share/keyrings/githubcli-archive-keyring.gpg
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of="$KEYRING" status=none
    sudo chmod go+r "$KEYRING"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    ok "gh installed"
  fi

  # uv
  if has_cmd uv; then
    ok "uv already installed"
  else
    log "Installing uv"
    curl -Ls https://astral.sh/uv/install.sh | sh
    ok "uv installed"
    info "Open a new shell or 'source ~/.bashrc' to pick up the uv PATH change."
  fi

  # starship — official installer to ~/.local/bin (no sudo), init line in ~/.bashrc
  if has_cmd starship; then
    ok "starship already installed"
  else
    log "Installing starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    ok "starship installed"
  fi
  ensure_line "$HOME/.bashrc" 'eval "$(starship init bash)"'
  ok "starship init line in ~/.bashrc"
}

# do_uninstall [TOOL...] — remove named tools (claude|uv|starship), or all when
# none given. Each block runs only when its tool is targeted.
do_uninstall() {
  local targets=("$@")
  # _wanted NAME — true when no targets given, or NAME is among them.
  _wanted() { ((${#targets[@]})) || return 0; _in_list "$1" "${targets[@]}"; }
  # Claude Code + uv are installer-script tools; gh comes from an apt repo we leave behind.
  if _wanted claude && has_cmd claude; then
    log "Removing cloudflare plugin + Claude Code"
    claude plugin uninstall cloudflare@claude-plugins-official >/dev/null 2>&1 || true
    rm -rf "$HOME/.local/bin/claude" "$HOME/.claude" 2>/dev/null || true
    ok "Claude Code removed"
  fi
  if _wanted uv && has_cmd uv; then
    log "Removing uv"
    rm -rf "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx" "$HOME/.cargo/bin/uv" "$HOME/.cargo/bin/uvx" 2>/dev/null || true
    ok "uv removed"
  fi
  if _wanted starship && has_cmd starship; then
    log "Removing starship"
    rm -f "$HOME/.local/bin/starship" 2>/dev/null || true
    strip_line "$HOME/.bashrc" 'eval "$(starship init bash)"'
    ok "starship removed"
  fi
  _wanted gh && warn "gh and its GitHub apt repo are left in place — remove manually if unwanted."
  return 0
}

dispatch "$@"
