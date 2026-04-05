#!/usr/bin/env bash
# install.sh — Full LLM Wiki Stack installer
# https://github.com/joshuaboys/llm-wiki-stack
#
# Usage (interactive):
#   bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install.sh)
#
# Usage (non-interactive, env vars):
#   VAULT_PATH=~/Vault VAULT_NAME="My Vault" BRV_PROVIDER=openai BRV_API_KEY=sk-... \
#     bash <(curl -fsSL .../install.sh)
#
# Environment variables:
#   VAULT_PATH       Local vault directory (default: ~/Vault)
#   VAULT_NAME       Remote Obsidian vault name or ID (skips prompt)
#   MIND_PATH        obsidian-mind directory (default: ~/Vault-mind)
#   MIND_VAULT_NAME  Remote vault name for obsidian-mind (skips prompt)
#   DEVICE_NAME      Device name for sync (default: hostname)
#   BRV_PROVIDER     byterover provider: openai|anthropic|skip (skips prompt)
#   BRV_API_KEY      API key for BRV_PROVIDER (skips prompt)
#   SKIP_MIND        Set to 1 to skip obsidian-mind install
#
# Prerequisites:
#   - Ubuntu / Debian Linux (headless or desktop)
#   - An Obsidian account with Sync subscription
#   - curl, git, systemctl

set -euo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
REPO="https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main"
VAULT_PATH="${VAULT_PATH:-$HOME/Vault}"
MIND_PATH="${MIND_PATH:-$HOME/Vault-mind}"
DEVICE_NAME="${DEVICE_NAME:-$(hostname)}"
VAULT_NAME="${VAULT_NAME:-}"
MIND_VAULT_NAME="${MIND_VAULT_NAME:-}"
BRV_PROVIDER="${BRV_PROVIDER:-}"
BRV_API_KEY="${BRV_API_KEY:-}"
SKIP_MIND="${SKIP_MIND:-0}"
SCAFFOLD_ONLY=false  # always initialised

# ── colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[llm-wiki-stack]${NC} $*"; }
warn()    { echo -e "${YELLOW}[llm-wiki-stack]${NC} $*"; }
error()   { echo -e "${RED}[llm-wiki-stack]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${GREEN}══ $* ══${NC}"; }

# ── TTY detection ─────────────────────────────────────────────────────────────
IS_INTERACTIVE=false
[[ -t 0 ]] && IS_INTERACTIVE=true

ask() {
  local prompt="$1" default="${2:-y}"
  if [[ "$IS_INTERACTIVE" == "true" ]]; then
    read -rp "$(echo -e "${YELLOW}?${NC} $prompt [${default}]: ")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
  else
    # Non-interactive: use default
    [[ "$default" =~ ^[Yy] ]]
  fi
}

prompt() {
  local var_name="$1" prompt_text="$2"
  if [[ -n "${!var_name:-}" ]]; then
    return  # already set via env var
  fi
  if [[ "$IS_INTERACTIVE" == "true" ]]; then
    read -rp "$(echo -e "${YELLOW}?${NC} $prompt_text: ")" answer
    eval "$var_name=\"\$answer\""
  else
    warn "Non-interactive mode: $var_name not set. Set via env var to skip this prompt."
  fi
}

prompt_secret() {
  local var_name="$1" prompt_text="$2"
  if [[ -n "${!var_name:-}" ]]; then
    return  # already set via env var
  fi
  if [[ "$IS_INTERACTIVE" == "true" ]]; then
    read -rsp "$(echo -e "${YELLOW}?${NC} $prompt_text: ")" answer; echo
    eval "$var_name=\"\$answer\""
  else
    warn "Non-interactive mode: $var_name not set. Set via env var."
  fi
}

# ── check OS ──────────────────────────────────────────────────────────────────
[[ "$OSTYPE" == "linux-gnu"* ]] || error "Linux only. See README for manual install."

echo ""
echo "  LLM Wiki Stack — Full Installer"
echo "  github.com/joshuaboys/llm-wiki-stack"
echo ""
if [[ "$IS_INTERACTIVE" == "false" ]]; then
  warn "Non-interactive mode detected (stdin is not a TTY)."
  warn "Set env vars to configure: VAULT_PATH, VAULT_NAME, BRV_PROVIDER, BRV_API_KEY"
  warn "See script header for full list."
  echo ""
fi

ask "Continue with install?" || exit 0

# ── 1. Linuxbrew ──────────────────────────────────────────────────────────────
section "Linuxbrew"
if command -v brew >/dev/null 2>&1; then
  info "Linuxbrew already installed: $(brew --version | head -1)"
else
  info "Installing Linuxbrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Detect install prefix
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    BREW_PREFIX=/home/linuxbrew/.linuxbrew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_PREFIX=/opt/homebrew
  else
    error "Homebrew installed but brew binary not found. Check your PATH."
  fi
  eval "$($BREW_PREFIX/bin/brew shellenv)"
  for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$profile" ]]; then
      echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$profile"
      info "Added brew to $profile"
      break
    fi
  done
fi

# ── 2. Node.js ────────────────────────────────────────────────────────────────
section "Node.js"
if command -v node >/dev/null 2>&1; then
  info "Node.js already installed: $(node --version)"
else
  info "Installing Node.js via Linuxbrew..."
  brew install node
fi
NODE_BIN="$(command -v node)"
info "Node: $NODE_BIN"

# ── 3. obsidian-headless ──────────────────────────────────────────────────────
section "obsidian-headless"
if ! command -v ob >/dev/null 2>&1; then
  info "Installing obsidian-headless..."
  npm install -g obsidian-headless
fi

# Verify ob binary exists
OB_BIN="$(command -v ob)" || error "ob binary not found after install. Check your PATH."
info "ob: $OB_BIN"

# Login (skip if already authenticated)
if ob whoami >/dev/null 2>&1; then
  info "Already logged in to Obsidian: $(ob whoami 2>/dev/null | head -1)"
else
  info "Logging in to Obsidian..."
  ob login || error "ob login failed. Check your credentials and try again."
fi

# ── 4. Vault template ─────────────────────────────────────────────────────────
section "Vault template"
if [[ -d "$VAULT_PATH" ]]; then
  warn "Vault directory already exists at $VAULT_PATH"
  if ask "Scaffold wiki structure inside existing vault?"; then
    SCAFFOLD_ONLY=true
  fi
fi

[[ -d "$VAULT_PATH" ]] || mkdir -p "$VAULT_PATH"

for dir in wiki/entities wiki/topics wiki/sources projects references inbox; do
  mkdir -p "$VAULT_PATH/$dir"
done

for file in wiki/index.md wiki/log.md wiki/entities/_template.md wiki/sources/_template.md; do
  target="$VAULT_PATH/$file"
  if [[ ! -f "$target" ]]; then
    curl -fsSL "$REPO/vault-template/$file" -o "$target" 2>/dev/null \
      || warn "Could not download $file — create manually"
  fi
done

if [[ ! -f "$VAULT_PATH/WIKI-SCHEMA.md" ]]; then
  curl -fsSL "$REPO/schema/WIKI-SCHEMA.md" -o "$VAULT_PATH/WIKI-SCHEMA.md"
  info "Wiki schema installed at $VAULT_PATH/WIKI-SCHEMA.md"
fi

# ── 5. Obsidian Sync ──────────────────────────────────────────────────────────
section "Obsidian Sync"
if [[ -z "$VAULT_NAME" ]]; then
  info "Available remote vaults:"
  ob sync-list-remote || true
  echo ""
  prompt VAULT_NAME "Vault name or ID to sync to $VAULT_PATH"
fi

if [[ -n "$VAULT_NAME" ]]; then
  ob sync-setup --vault "$VAULT_NAME" --path "$VAULT_PATH" --device-name "$DEVICE_NAME"
  info "Running initial sync..."
  ob sync --path "$VAULT_PATH"
else
  warn "Skipping sync setup. Run: ob sync-setup --vault <name> --path $VAULT_PATH"
fi

# ── 6. Sync daemon ────────────────────────────────────────────────────────────
section "Sync daemon"
SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/obsidian-sync.service" <<EOF
[Unit]
Description=Obsidian Headless Sync
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
ExecStart=$NODE_BIN $OB_BIN sync --path $VAULT_PATH --continuous
Restart=on-failure
RestartSec=30
Environment=HOME=$HOME

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable obsidian-sync.service
systemctl --user start obsidian-sync.service
info "Sync daemon: $(systemctl --user is-active obsidian-sync.service)"

# Enable linger so service survives logout on headless servers
if command -v loginctl >/dev/null 2>&1; then
  loginctl enable-linger "$USER" && info "Linger enabled for $USER (service survives logout)"
fi

# ── 7. ByteRover ─────────────────────────────────────────────────────────────
section "ByteRover"
if ! command -v brv >/dev/null 2>&1; then
  info "Installing ByteRover..."
  npm install -g byterover-cli
fi

mkdir -p "$HOME/brv-context"
cd "$HOME/brv-context"

if [[ -z "$BRV_PROVIDER" ]]; then
  if [[ "$IS_INTERACTIVE" == "true" ]]; then
    echo ""
    info "ByteRover needs an LLM provider:"
    echo "  1) OpenAI   2) Anthropic   3) Skip"
    read -rp "$(echo -e "${YELLOW}?${NC} Choose [1/2/3]: ")" BRV_CHOICE
    case "$BRV_CHOICE" in
      1) BRV_PROVIDER=openai ;;
      2) BRV_PROVIDER=anthropic ;;
      *) BRV_PROVIDER=skip ;;
    esac
  else
    BRV_PROVIDER=skip
    warn "BRV_PROVIDER not set — skipping ByteRover provider config."
  fi
fi

case "$BRV_PROVIDER" in
  openai)
    prompt_secret BRV_API_KEY "OpenAI API key"
    if [[ -n "$BRV_API_KEY" ]]; then
      # Pass via env var to avoid key appearing in process list
      OPENAI_API_KEY="$BRV_API_KEY" brv providers connect openai
    fi
    ;;
  anthropic)
    prompt_secret BRV_API_KEY "Anthropic API key"
    if [[ -n "$BRV_API_KEY" ]]; then
      ANTHROPIC_API_KEY="$BRV_API_KEY" brv providers connect anthropic
    fi
    ;;
  *)
    warn "Skipping ByteRover provider. Run: brv providers connect openai"
    ;;
esac

# ── 8. obsidian-mind ──────────────────────────────────────────────────────────
section "obsidian-mind (personal memory)"
if [[ "$SKIP_MIND" != "1" ]] && ask "Install obsidian-mind for personal memory?"; then
  [[ -d "$MIND_PATH" ]] || git clone https://github.com/breferrari/obsidian-mind.git "$MIND_PATH"

  if [[ -z "$MIND_VAULT_NAME" ]] && ask "Create a new remote vault for obsidian-mind?"; then
    prompt MIND_VAULT_NAME "Vault name (e.g. 'Mind')"
    if [[ -n "$MIND_VAULT_NAME" ]]; then
      ob sync-create-remote --name "$MIND_VAULT_NAME" --encryption e2ee || true
      ob sync-setup --vault "$MIND_VAULT_NAME" --path "$MIND_PATH" --device-name "$DEVICE_NAME"
      ob sync --path "$MIND_PATH"
    fi
  fi

  cat > "$SYSTEMD_DIR/obsidian-sync-mind.service" <<EOF
[Unit]
Description=Obsidian Headless Sync — Mind
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
ExecStart=$NODE_BIN $OB_BIN sync --path $MIND_PATH --continuous
Restart=on-failure
RestartSec=30
Environment=HOME=$HOME

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable obsidian-sync-mind.service
  systemctl --user start obsidian-sync-mind.service
  info "Mind sync: $(systemctl --user is-active obsidian-sync-mind.service)"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══ Done ══${NC}"
echo ""
info "Vault:       $VAULT_PATH"
info "Schema:      $VAULT_PATH/WIKI-SCHEMA.md"
info "ByteRover:   $HOME/brv-context"
info "Sync logs:   journalctl --user -u obsidian-sync -f"
echo ""
info "Next steps:"
echo "  1. Open $VAULT_PATH in Obsidian on another device"
echo "  2. Edit WIKI-SCHEMA.md to describe your domains"
echo "  3. Drop sources into references/ and ask your assistant to ingest them"
echo "  4. cd ~/brv-context && brv curate \"key fact about your project\""
echo ""
info "Troubleshoot: systemctl --user status obsidian-sync.service"
info "Full docs: https://github.com/joshuaboys/llm-wiki-stack"
