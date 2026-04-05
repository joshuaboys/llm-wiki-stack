#!/usr/bin/env bash
# install-sync.sh — Add Obsidian headless sync to an existing vault
# https://github.com/joshuaboys/llm-wiki-stack
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-sync.sh | bash
#
# Use this if you already have a vault and just want continuous headless sync.

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/Vault}"
DEVICE_NAME="${DEVICE_NAME:-$(hostname)}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[obs-sync]${NC} $*"; }
warn()  { echo -e "${YELLOW}[obs-sync]${NC} $*"; }
error() { echo -e "${RED}[obs-sync]${NC} $*" >&2; exit 1; }

[[ "$OSTYPE" == "linux-gnu"* ]] || error "Linux only."

# ── Node ──────────────────────────────────────────────────────────────────────
NODE_BIN="$(command -v node 2>/dev/null)" || error "Node.js not found. Install it first: brew install node"
NPM_GLOBAL="$(npm root -g)"
info "Node: $NODE_BIN"

# ── obsidian-headless ─────────────────────────────────────────────────────────
if ! command -v ob >/dev/null 2>&1; then
  info "Installing obsidian-headless..."
  npm install -g obsidian-headless
fi

if ! ob login 2>/dev/null | grep -q "Logged in"; then
  info "Logging in to Obsidian..."
  ob login
fi

# ── Vault ─────────────────────────────────────────────────────────────────────
[[ -d "$VAULT_PATH" ]] || mkdir -p "$VAULT_PATH"

info "Available remote vaults:"
ob sync-list-remote

echo ""
read -rp "$(echo -e "${YELLOW}?${NC} Vault name or ID to sync to $VAULT_PATH: ")" VAULT_NAME
ob sync-setup --vault "$VAULT_NAME" --path "$VAULT_PATH" --device-name "$DEVICE_NAME"

info "Running initial sync..."
ob sync --path "$VAULT_PATH"

# ── systemd service ───────────────────────────────────────────────────────────
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

info "Done. Sync daemon active: $(systemctl --user is-active obsidian-sync.service)"
info "Check status: systemctl --user status obsidian-sync.service"
