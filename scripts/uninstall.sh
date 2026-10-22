#!/bin/bash
# SearXNG + OpenClaw - Uninstall Script
# Usage: sudo bash scripts/uninstall.sh

set -e

echo "=========================================="
echo "  SearXNG + OpenClaw Uninstall"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo"
    exit 1
fi

echo "⚠️  WARNING: This will uninstall SearXNG and remove all data!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_info "Uninstall cancelled"
    exit 0
fi

# Stop services
log_info "Stopping services..."
systemctl stop searxng.service 2>/dev/null || true
systemctl disable searxng.service 2>/dev/null || true
rm -f /etc/systemd/system/searxng.service
systemctl daemon-reload 2>/dev/null || true

# Remove SearXNG user and directories
log_info "Removing SearXNG installation..."
userdel -r searxng 2>/dev/null || true
rm -rf /usr/local/searxng
rm -rf /etc/searxng

# Remove Redis (optional)
echo ""
read -p "Remove Redis? (y/n): " REMOVE_REDIS
if [ "$REMOVE_REDIS" = "y" ]; then
    log_info "Removing Redis..."
    systemctl stop redis-server 2>/dev/null || true
    systemctl disable redis-server 2>/dev/null || true
    apt remove -y redis-server
    rm -rf /var/lib/redis
fi

# Remove OpenClaw configuration (optional)
echo ""
read -p "Remove OpenClaw SearXNG configuration? (y/n): " REMOVE_OPENCLAW
if [ "$REMOVE_OPENCLAW" = "y" ]; then
    log_info "Removing OpenClaw configuration..."
    if [ -f "$HOME/.openclaw/openclaw.json" ]; then
        # Backup before removing
        cp "$HOME/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json.searxng-backup"
        # Remove searxng-search plugin config
        if command -v jq &>/dev/null; then
            jq 'del(.plugins.entries["searxng-search"])' "$HOME/.openclaw/openclaw.json" > "${HOME}/.openclaw/openclaw.json.tmp" && \
            mv "${HOME}/.openclaw/openclaw.json.tmp" "$HOME/.openclaw/openclaw.json"
        fi
    fi
fi

# Remove scripts
log_info "Removing scripts..."
rm -f /usr/local/bin/searxng-*

echo ""
echo "=========================================="
echo "  ✅ Uninstall Complete!"
echo "=========================================="
echo ""
echo "The following were removed:"
echo "  - SearXNG service and files"
if [ "$REMOVE_REDIS" = "y" ]; then
    echo "  - Redis service and files"
fi
if [ "$REMOVE_OPENCLAW" = "y" ]; then
    echo "  - OpenClaw SearXNG configuration"
fi
echo ""
echo "The following were NOT removed:"
echo "  - This uninstall script"
echo "  - Repository files (delete manually if needed)"
echo ""
log_info "To reinstall, run: sudo bash scripts/install-all.sh"
