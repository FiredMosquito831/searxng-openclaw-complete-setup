#!/bin/bash
# SearXNG + OpenClaw - OpenClaw Auto-Configuration
# Usage: bash scripts/configure-openclaw.sh

set -e

echo "=========================================="
echo "  OpenClaw Auto-Configuration"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if OpenClaw is installed
if ! command -v openclaw &>/dev/null; then
    log_error "OpenClaw is not installed"
    exit 1
fi

log_info "OpenClaw detected"

# Check if config exists
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ ! -f "$OPENCLAW_CONFIG" ]; then
    log_error "OpenClaw config not found at $OPENCLAW_CONFIG"
    exit 1
fi

# Backup current config
BACKUP_FILE="$OPENCLAW_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
cp "$OPENCLAW_CONFIG" "$BACKUP_FILE"
log_info "Config backed up to: $BACKUP_FILE"

# Configure SearXNG plugin
log_info "Configuring SearXNG plugin..."

# Use jq to update config
if command -v jq &>/dev/null; then
    # Create plugin config
    jq '.plugins.entries["searxng-search"] = {
        "enabled": true,
        "config": {
            "baseUrl": "http://localhost:8080",
            "timeoutMs": 60000,
            "defaultCount": 100,
            "enableMultiPage": true
        }
    }' "$OPENCLAW_CONFIG" > "${OPENCLAW_CONFIG}.tmp" && mv "${OPENCLAW_CONFIG}.tmp" "$OPENCLAW_CONFIG"
    
    log_info "SearXNG plugin configured"
else
    log_warn "jq not found, manual configuration required"
    log_info "Please add this to your $OPENCLAW_CONFIG:"
    cat << 'EOF'

{
  "plugins": {
    "entries": {
      "searxng-search": {
        "enabled": true,
        "config": {
          "baseUrl": "http://localhost:8080",
          "timeoutMs": 60000,
          "defaultCount": 100,
          "enableMultiPage": true
        }
      }
    }
  }
}
EOF
    exit 1
fi

# Validate config
log_info "Validating configuration..."
if openclaw doctor &>/dev/null; then
    log_info "Configuration is valid"
else
    log_warn "Configuration validation found issues"
    log_info "Running: openclaw doctor --fix"
    openclaw doctor --fix || true
fi

# Restart OpenClaw
log_info "Restarting OpenClaw gateway..."
if systemctl --user is-active --quiet openclaw-gateway.service; then
    systemctl --user restart openclaw-gateway.service
    sleep 5
    log_info "OpenClaw gateway restarted"
else
    log_warn "OpenClaw gateway is not running"
    log_info "Start it with: systemctl --user start openclaw-gateway.service"
fi

# Verify
log_info "Verifying configuration..."
sleep 5

if openclaw doctor 2>&1 | grep -q "searxng-search"; then
    log_info "✅ SearXNG plugin loaded successfully"
else
    log_warn "⚠️  SearXNG plugin may not be loaded"
    log_info "Check: openclaw doctor 2>&1 | grep searxng"
fi

echo ""
echo "=========================================="
echo "  ✅ Configuration Complete!"
echo "=========================================="
echo ""
echo "Test commands:"
echo "  openclaw doctor"
echo "  systemctl --user status openclaw-gateway.service"
echo ""
echo "Usage:"
echo "  Send to Telegram bot: 'Search for Python tutorials using SearXNG'"
echo ""
