#!/usr/bin/env bash
# install-byterover.sh — Add ByteRover structured knowledge layer
# https://github.com/joshuaboys/llm-wiki-stack
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-byterover.sh | bash
#
# Use this if you just want ByteRover and already have the rest set up.

set -euo pipefail

BRV_DIR="${BRV_DIR:-$HOME/brv-context}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[byterover]${NC} $*"; }
warn()  { echo -e "${YELLOW}[byterover]${NC} $*"; }
error() { echo -e "${RED}[byterover]${NC} $*" >&2; exit 1; }

command -v node >/dev/null 2>&1 || error "Node.js not found. Install it first: brew install node"

# ── Install ───────────────────────────────────────────────────────────────────
if command -v brv >/dev/null 2>&1; then
  info "ByteRover already installed: $(brv --version 2>/dev/null || echo 'unknown')"
else
  info "Installing ByteRover..."
  npm install -g byterover-cli
fi

# ── Provider ──────────────────────────────────────────────────────────────────
echo ""
info "ByteRover needs an LLM provider:"
echo "  1) OpenAI"
echo "  2) Anthropic"
echo "  3) Skip (configure later with: brv providers connect)"
read -rp "$(echo -e "${YELLOW}?${NC} Choose [1/2/3]: ")" CHOICE

case "$CHOICE" in
  1)
    read -rsp "$(echo -e "${YELLOW}?${NC} OpenAI API key: ")" KEY; echo
    # Pass via env var to avoid key appearing in process list (ps aux)
    OPENAI_API_KEY="$KEY" brv providers connect openai
    ;;
  2)
    read -rsp "$(echo -e "${YELLOW}?${NC} Anthropic API key: ")" KEY; echo
    ANTHROPIC_API_KEY="$KEY" brv providers connect anthropic
    ;;
  *)
    warn "Skipping. Run later: brv providers connect openai"
    ;;
esac

# ── Context dir ───────────────────────────────────────────────────────────────
mkdir -p "$BRV_DIR"
cd "$BRV_DIR"
info "ByteRover context directory: $BRV_DIR"

echo ""
info "Done. Quick start:"
echo "  cd $BRV_DIR"
echo "  brv curate \"key fact about your project\""
echo "  brv query \"what do we know about X?\""
echo "  brv push   # sync to cloud"
echo ""
info "Docs: https://github.com/joshuaboys/llm-wiki-stack"
