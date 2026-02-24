#!/bin/bash
# SearXNG + OpenClaw - Update Script
# Usage: sudo bash scripts/update-searxng.sh

set -e

echo "=========================================="
echo "  SearXNG Update"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo"
    exit 1
fi

# Check if SearXNG is installed
if ! id -u searxng &>/dev/null; then
    log_error "SearXNG is not installed"
    exit 1
fi

log_info "Checking for updates..."

# Backup before update
log_info "Creating backup before update..."
bash scripts/backup-searxng.sh || log_warn "Backup failed, continuing anyway"

# Update SearXNG
log_info "Updating SearXNG..."
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
git fetch origin
CURRENT_COMMIT=$(git rev-parse HEAD)
git checkout main
git pull origin main
NEW_COMMIT=$(git rev-parse HEAD)

if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
    echo "NO_UPDATE_NEEDED"
else
    echo "UPDATED"
fi
EOF

# Check if update was needed
UPDATE_STATUS=$(sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
git rev-parse HEAD
EOF
)

# Reinstall dependencies
log_info "Reinstalling dependencies..."
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --upgrade pip
pip install --use-pep517 --no-build-isolation -e .
EOF

# Restart service
log_info "Restarting SearXNG service..."
systemctl restart searxng.service
sleep 5

# Verify
if systemctl is-active --quiet searxng.service; then
    log_info "✅ SearXNG updated successfully"
else
    log_error "❌ SearXNG failed to start after update"
    log_info "Check logs: sudo journalctl -u searxng -n 50"
    exit 1
fi

# Test API
log_info "Testing API..."
RESULT_COUNT=$(curl -s "http://localhost:8080/search?q=test&format=json" | jq -r '.results | length' 2>/dev/null || echo "0")

if [ "$RESULT_COUNT" -gt 0 ]; then
    log_info "✅ API working ($RESULT_COUNT results)"
else
    log_warn "⚠️  API returned no results (may need warmup)"
fi

echo ""
echo "=========================================="
echo "  ✅ Update Complete!"
echo "=========================================="
echo ""
echo "Backup location: $HOME/searxng-backups/"
echo ""
echo "If you encounter issues, restore backup:"
echo "  cd ~/searxng-backups/<backup_dir>"
echo "  bash restore.sh"
echo ""
