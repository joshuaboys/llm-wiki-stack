#!/usr/bin/env bash
# install.sh — Full LLM Wiki Stack installer
# https://github.com/joshuaboys/llm-wiki-stack
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install.sh | bash
#
# What this installs:
#   - Linuxbrew (if not present)
#   - Node.js (if not present)
#   - obsidian-headless (Obsidian Sync daemon)
#   - ByteRover CLI (structured knowledge layer)
#   - obsidian-mind vault template
#   - Vault template with wiki structure
#   - systemd user services for continuous sync
#
# Prerequisites:
#   - Ubuntu / Debian Linux (headless or desktop)
#   - An Obsidian account with Sync subscription
#   - curl, git, systemctl

set -euo pipefail

REPO="https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main"
VAULT_PATH="${VAULT_PATH:-$HOME/Vault}"
MIND_PATH="${MIND_PATH:-$HOME/Vault-mind}"
DEVICE_NAME="${DEVICE_NAME:-$(hostname)}"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[llm-wiki-stack]${NC} $*"; }
warn()    { echo -e "${YELLOW}[llm-wiki-stack]${NC} $*"; }
error()   { echo -e "${RED}[llm-wiki-stack]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${GREEN}══ $* ══${NC}"; }

# ── helpers ───────────────────────────────────────────────────────────────────
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1. Please install it and re-run."
}

ask() {
  local prompt="$1" default="${2:-y}"
  read -rp "$(echo -e "${YELLOW}?${NC} $prompt [${default}]: ")" answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]]
}

# ── check OS ──────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This script is for Linux only. For macOS, install manually — see README."
fi

echo ""
echo "  LLM Wiki Stack — Full Installer"
echo "  github.com/joshuaboys/llm-wiki-stack"
echo ""
warn "This will install: Linuxbrew (if needed), Node.js, obsidian-headless,"
warn "ByteRover CLI, obsidian-mind, vault template, and systemd sync services."
echo ""
ask "Continue?" || exit 0

# ── 1. Linuxbrew ──────────────────────────────────────────────────────────────
section "Linuxbrew"
if command -v brew >/dev/null 2>&1; then
  info "Linuxbrew already installed: $(brew --version | head -1)"
else
  info "Installing Linuxbrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  # Add to shell profile
  for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$profile" ]]; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$profile"
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

NODE_BIN="$(which node)"
NPM_GLOBAL="$(npm root -g)"
info "Node: $NODE_BIN"
info "npm global: $NPM_GLOBAL"

# ── 3. obsidian-headless ──────────────────────────────────────────────────────
section "obsidian-headless"
if command -v ob >/dev/null 2>&1; then
  info "obsidian-headless already installed: $(ob --version 2>/dev/null || echo 'unknown')"
else
  info "Installing obsidian-headless..."
  npm install -g obsidian-headless
fi

info "Logging in to Obsidian..."
ob login

# ── 4. Vault template ─────────────────────────────────────────────────────────
section "Vault template"
if [[ -d "$VAULT_PATH" ]]; then
  warn "Vault directory already exists at $VAULT_PATH"
  if ask "Scaffold wiki structure inside existing vault?"; then
    SCAFFOLD_ONLY=true
  else
    SCAFFOLD_ONLY=false
  fi
else
  SCAFFOLD_ONLY=false
fi

if [[ "$SCAFFOLD_ONLY" == "false" ]] && [[ ! -d "$VAULT_PATH" ]]; then
  info "Creating vault at $VAULT_PATH..."
  mkdir -p "$VAULT_PATH"
fi

# Scaffold wiki structure
for dir in wiki/entities wiki/topics wiki/sources projects references inbox; do
  mkdir -p "$VAULT_PATH/$dir"
done

# Download template files if not present
for file in wiki/index.md wiki/log.md wiki/entities/_template.md wiki/sources/_template.md; do
  target="$VAULT_PATH/$file"
  if [[ ! -f "$target" ]]; then
    curl -fsSL "$REPO/vault-template/$file" -o "$target" 2>/dev/null || warn "Could not download $file — create manually"
  fi
done

# Download schema
if [[ ! -f "$VAULT_PATH/WIKI-SCHEMA.md" ]]; then
  curl -fsSL "$REPO/schema/WIKI-SCHEMA.md" -o "$VAULT_PATH/WIKI-SCHEMA.md"
  info "Wiki schema installed at $VAULT_PATH/WIKI-SCHEMA.md"
fi

# ── 5. Obsidian Sync setup ────────────────────────────────────────────────────
section "Obsidian Sync"
info "Available remote vaults:"
ob sync-list-remote || true
echo ""

read -rp "$(echo -e "${YELLOW}?${NC} Vault name or ID to sync to $VAULT_PATH: ")" VAULT_NAME
if [[ -n "$VAULT_NAME" ]]; then
  ob sync-setup --vault "$VAULT_NAME" --path "$VAULT_PATH" --device-name "$DEVICE_NAME"
  info "Running initial sync..."
  ob sync --path "$VAULT_PATH"
else
  warn "Skipping sync setup. Run: ob sync-setup --vault <name> --path $VAULT_PATH"
fi

# ── 6. Sync daemon (systemd) ──────────────────────────────────────────────────
section "Sync daemon"
OB_CLI="$NPM_GLOBAL/obsidian-headless/cli.js"
SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/obsidian-sync.service" <<EOF
[Unit]
Description=Obsidian Headless Sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$NODE_BIN $OB_CLI sync --path $VAULT_PATH --continuous
Restart=on-failure
RestartSec=30
Environment=HOME=$HOME

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable obsidian-sync.service
systemctl --user start obsidian-sync.service
info "Sync daemon running: $(systemctl --user is-active obsidian-sync.service)"

# ── 7. ByteRover ─────────────────────────────────────────────────────────────
section "ByteRover"
if command -v brv >/dev/null 2>&1; then
  info "ByteRover already installed: $(brv --version 2>/dev/null || echo 'unknown')"
else
  info "Installing ByteRover..."
  npm install -g byterover-cli
fi

echo ""
info "ByteRover needs an LLM provider. Options:"
echo "  1) OpenAI (recommended)"
echo "  2) Anthropic"  
echo "  3) Skip (configure later with: brv providers connect)"
read -rp "$(echo -e "${YELLOW}?${NC} Choose [1/2/3]: ")" BRV_CHOICE

mkdir -p "$HOME/brv-context"
cd "$HOME/brv-context"

case "$BRV_CHOICE" in
  1)
    read -rp "$(echo -e "${YELLOW}?${NC} OpenAI API key: ")" -s OAI_KEY; echo
    brv providers connect openai --api-key "$OAI_KEY"
    ;;
  2)
    read -rp "$(echo -e "${YELLOW}?${NC} Anthropic API key: ")" -s ANT_KEY; echo
    brv providers connect anthropic --api-key "$ANT_KEY"
    ;;
  *)
    warn "Skipping. Run: brv providers connect openai --api-key YOUR_KEY"
    ;;
esac

# ── 8. obsidian-mind (optional) ───────────────────────────────────────────────
section "obsidian-mind (personal memory)"
if ask "Install obsidian-mind for personal memory (1:1s, decisions, people)?"; then
  if [[ -d "$MIND_PATH" ]]; then
    warn "obsidian-mind directory already exists at $MIND_PATH — skipping clone"
  else
    info "Cloning obsidian-mind..."
    git clone https://github.com/breferrari/obsidian-mind.git "$MIND_PATH"
  fi

  info "Available remote vaults:"
  ob sync-list-remote || true
  echo ""
  read -rp "$(echo -e "${YELLOW}?${NC} Create a new remote vault for obsidian-mind? [y/n]: ")" CREATE_MIND
  if [[ "$CREATE_MIND" =~ ^[Yy] ]]; then
    read -rp "$(echo -e "${YELLOW}?${NC} Vault name (e.g. 'Mind'): ")" MIND_VAULT_NAME
    ob sync-create-remote --name "$MIND_VAULT_NAME" --encryption e2ee || true
    ob sync-setup --vault "$MIND_VAULT_NAME" --path "$MIND_PATH" --device-name "$DEVICE_NAME"
    ob sync --path "$MIND_PATH"
  fi

  cat > "$SYSTEMD_DIR/obsidian-sync-mind.service" <<EOF
[Unit]
Description=Obsidian Headless Sync — Mind
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$NODE_BIN $OB_CLI sync --path $MIND_PATH --continuous
Restart=on-failure
RestartSec=30
Environment=HOME=$HOME

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable obsidian-sync-mind.service
  systemctl --user start obsidian-sync-mind.service
  info "Mind sync daemon running: $(systemctl --user is-active obsidian-sync-mind.service)"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══ Done ══${NC}"
echo ""
info "Vault:       $VAULT_PATH"
info "Schema:      $VAULT_PATH/WIKI-SCHEMA.md (adapt this to your domains)"
info "ByteRover:   $HOME/brv-context (run brv curate / brv query here)"
info "Sync status: systemctl --user status obsidian-sync.service"
echo ""
info "Next steps:"
echo "  1. Open $VAULT_PATH in Obsidian on another device"
echo "  2. Edit WIKI-SCHEMA.md to describe your domains and update triggers"
echo "  3. Drop sources into references/ and tell your assistant to ingest them"
echo "  4. Run: brv curate \"key fact about your project\" in brv-context/"
echo ""
info "Full docs: https://github.com/joshuaboys/llm-wiki-stack"
