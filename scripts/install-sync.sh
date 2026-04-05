#!/usr/bin/env bash
# install-sync.sh — Add Obsidian headless sync to an existing vault
# https://github.com/joshuaboys/llm-wiki-stack
#
# Usage (interactive):
#   bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-sync.sh)
#
# Usage (non-interactive):
#   VAULT_PATH=~/Vault VAULT_NAME="My Vault" bash <(curl -fsSL ...)

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/Vault}"
VAULT_NAME="${VAULT_NAME:-}"
DEVICE_NAME="${DEVICE_NAME:-$(hostname)}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[obs-sync]${NC} $*"; }
warn()  { echo -e "${YELLOW}[obs-sync]${NC} $*"; }
error() { echo -e "${RED}[obs-sync]${NC} $*" >&2; exit 1; }

[[ "$OSTYPE" == "linux-gnu"* ]] || error "Linux only."

NODE_BIN="$(command -v node 2>/dev/null)" || error "Node.js not found. Install it first: brew install node"

if ! command -v ob >/dev/null 2>&1; then
  info "Installing obsidian-headless..."
  npm install -g obsidian-headless
fi

OB_BIN="$(command -v ob)" || error "ob binary not found after install."

if ob whoami >/dev/null 2>&1; then
  info "Already logged in: $(ob whoami 2>/dev/null | head -1)"
else
  info "Logging in to Obsidian..."
  ob login || error "ob login failed."
fi

[[ -d "$VAULT_PATH" ]] || mkdir -p "$VAULT_PATH"

if [[ -z "$VAULT_NAME" ]]; then
  info "Available remote vaults:"
  ob sync-list-remote
  echo ""
  read -rp "$(echo -e "${YELLOW}?${NC} Vault name or ID to sync to $VAULT_PATH: ")" VAULT_NAME
fi

[[ -n "$VAULT_NAME" ]] || error "Vault name required. Set VAULT_NAME env var or enter at prompt."

ob sync-setup --vault "$VAULT_NAME" --path "$VAULT_PATH" --device-name "$DEVICE_NAME"
info "Running initial sync..."
ob sync --path "$VAULT_PATH"

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

# Enable linger so service survives logout on headless servers
command -v loginctl >/dev/null 2>&1 && loginctl enable-linger "$USER" \
  && info "Linger enabled — service will survive logout"

info "Sync active: $(systemctl --user is-active obsidian-sync.service)"
info "Logs: journalctl --user -u obsidian-sync -f"
