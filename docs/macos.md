# MacBook Pro Setup

> Reference narrative. The automated flow in `./setup.sh` (see the [README](../README.md)) supersedes the manual steps below — run that first. This guide is kept for context, debugging, and the steps that still need a human.

## Create Accounts

- Google `@ubundi.co.za`
- Claude
- Wise

## Download

- Slack
- Claude
- VS Code
- Google Drive
- Foxglove
- 1Password

## 1Password

`brew install --cask 1password` installs version 8, which carries the Safari
extension inside the app — there is no separate cask, and the standalone
"1Password for Safari" is the version 7 companion. Two human steps remain:

1. Sign in to the Ubundi account (the work vault; a personal account can sit
   alongside it in the same app).
2. Safari → Settings → Extensions → tick **1Password**. Nothing populates a
   browser until this is on.

Machines still running 1Password 7 get version 8 installed beside it — the cask
does not migrate or remove the old app.

### CLI

`1password-cli` installs `op`, which reads a secret at run time so a token never
lands in a dotfile:

```bash
op signin                        # once per session
op run -- ./deploy.sh            # injects op:// refs from the environment
op read "op://Ubundi/GitHub/token"
```

It authorises through the desktop app: 1Password → Settings → Developer → **Integrate
with 1Password CLI**. Without that, `op` asks for the account password each call.

## Install

- **Homebrew** — `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Claude Code** — `curl -fsSL https://claude.ai/install.sh | bash`
- **GH CLI** — `brew install gh`
- **UV** (fast Python package installer) — `brew install uv`
- **Python** — `brew install python`
- **Node** — `brew install node`
- **Cloudflare Wrangler** — `brew install cloudflare-wrangler`
- **OrbStack** — `brew install --cask orbstack`
- **XcodeGen** — `brew install xcodegen`

## Xcode

Still a human step: Homebrew cannot install Xcode (App Store only), and the
post-install wiring needs `sudo`. Only iOS work needs it — the macOS Swift repos
build on the Command Line Tools alone.

```bash
# 1. Install Xcode from the App Store (~10 GB), or:
brew install --cask xcodes    # a GUI for installing and switching Xcode versions

# 2. Point the toolchain at it. Skip this and the machine stays on
#    /Library/Developer/CommandLineTools, where every xcodebuild call fails.
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -license accept

# 3. Xcode 26 ships without the iOS platform — no simulator until it lands.
xcodebuild -downloadPlatform iOS    # ~8 GB

# Verify
xcodebuild -version
xcrun simctl list runtimes          # at least one iOS runtime
```

Consumer: the iOS capture companion in
[`fm-desktop`](https://github.com/first-motive/fm-desktop) (`ios/`), whose Xcode
project XcodeGen generates from a committed `project.yml`.

## Claude Code Plugins

- **Cloudflare** — `claude plugin install cloudflare@claude-plugins-official`
  - Bundles 8 skills: `cloudflare`, `wrangler`, `durable-objects`, `agents-sdk`, `sandbox-sdk`, `workers-best-practices`, `cloudflare-email-service`, `web-perf`

## Foxglove Extensions

Built from source and installed into the native app (`./setup.sh --only foxglove-extensions`). The extension list lives in `scripts/manifest.sh` (`MACOS_FOXGLOVE_EXTENSIONS`).

- **Joint State Publisher** — [`rogy-ken/foxglove-joint-state-publisher`](https://github.com/rogy-ken/foxglove-joint-state-publisher). Cloned to the build cache, then `npm install && npm run local-install` drops the unpacked extension into `~/.foxglove-studio/extensions/`. Restart Foxglove Studio to load it. Needs Node (`brew install node`).

## Tailscale

`./setup.sh --only tailscale` installs the app (`brew install --cask
tailscale-app`, skipped when an App Store copy is already there) and links the
CLI onto PATH.

The one-time CLI shim is the part that catches people out. On Linux the
installer drops `tailscale` in `/usr/bin`; on macOS the binary stays inside the
app bundle, so a shell finds nothing.

A symlink — the fix most guides reach for — does not work. The binary locates
its own bundle from its executable path, and through a symlink that path lands
outside the bundle, so every call dies with:

```
Tailscale/BundleIdentifiers.swift:47: Fatal error: The current bundleIdentifier is unknown to the registry
```

A shim that execs the real path keeps the bundle resolvable:

```bash
cat > "$(brew --prefix)/bin/tailscale" <<'EOF'
#!/bin/sh
exec "/Applications/Tailscale.app/Contents/MacOS/Tailscale" "$@"
EOF
chmod +x "$(brew --prefix)/bin/tailscale"
```

The Homebrew prefix is user-writable, so this needs no `sudo`. Then start the
app, sign in, and confirm the tailnet:

```bash
tailscale status      # lists every machine and its 100.x address
```

SSH to a peer by its tailnet name once its SSH server is up (Ubuntu machines get
one from the `ssh-server` step):

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub <user>@<host>
ssh <user>@<host>
```

## Sign In

- **GitHub** — `gh auth login`
- **Claude Code** — `claude /login`

## Setup

- **SSH Key** — `ssh-keygen -t ed25519 -C "<user>@ubundi.co.za"`

## Robotics Installations

### Mujoco

```bash
uv venv ~/.venvs/mujoco --python 3.11
source ~/.venvs/mujoco/bin/activate
uv pip install mujoco

# Test
python -c "import mujoco; print(mujoco.__version__)"
python -m mujoco.viewer  # interactive viewer with a demo scene
```

### Hugging Face CLI

```bash
uv tool install huggingface_hub
huggingface-cli login
```

### Aliases

```bash
echo 'alias mj="source ~/.venvs/mujoco/bin/activate"' >> ~/.zshrc
source ~/.zshrc
```
