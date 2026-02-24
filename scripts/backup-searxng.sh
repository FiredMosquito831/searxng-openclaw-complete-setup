#!/bin/bash
# SearXNG + OpenClaw - Backup Script
# Usage: bash scripts/backup-searxng.sh

set -e

echo "=========================================="
echo "  SearXNG Backup"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Create backup directory
BACKUP_DIR="$HOME/searxng-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_info "Creating backup in: $BACKUP_DIR"

# Backup configuration files
log_info "Backing up configuration..."
if [ -f "/etc/searxng/settings.yml" ]; then
    sudo cp /etc/searxng/settings.yml "$BACKUP_DIR/"
    log_info "✅ settings.yml backed up"
else
    log_warn "⚠️  /etc/searxng/settings.yml not found"
fi

if [ -f "/etc/searxng/limiter.toml" ]; then
    sudo cp /etc/searxng/limiter.toml "$BACKUP_DIR/"
    log_info "✅ limiter.toml backed up"
fi

# Backup systemd service
if [ -f "/etc/systemd/system/searxng.service" ]; then
    sudo cp /etc/systemd/system/searxng.service "$BACKUP_DIR/"
    log_info "✅ searxng.service backed up"
fi

# Backup OpenClaw config
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    cp "$HOME/.openclaw/openclaw.json" "$BACKUP_DIR/"
    log_info "✅ openclaw.json backed up"
fi

# Create restore script
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE'
#!/bin/bash
# Restore SearXNG backup

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restoring SearXNG from backup..."

# Restore configuration
if [ -f "$BACKUP_DIR/settings.yml" ]; then
    sudo cp "$BACKUP_DIR/settings.yml" /etc/searxng/
    echo "✅ settings.yml restored"
fi

if [ -f "$BACKUP_DIR/limiter.toml" ]; then
    sudo cp "$BACKUP_DIR/limiter.toml" /etc/searxng/
    echo "✅ limiter.toml restored"
fi

if [ -f "$BACKUP_DIR/searxng.service" ]; then
    sudo cp "$BACKUP_DIR/searxng.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    echo "✅ searxng.service restored"
fi

if [ -f "$BACKUP_DIR/openclaw.json" ]; then
    cp "$BACKUP_DIR/openclaw.json" "$HOME/.openclaw/"
    echo "✅ openclaw.json restored"
fi

echo ""
echo "Restarting services..."
sudo systemctl restart searxng
systemctl --user restart openclaw-gateway.service

echo ""
echo "✅ Restore complete!"
RESTORE

chmod +x "$BACKUP_DIR/restore.sh"

# Create archive
cd "$HOME/searxng-backups"
tar -czf "searxng-backup-$(date +%Y%m%d-%H%M%S).tar.gz" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo ""
echo "=========================================="
echo "  ✅ Backup Complete!"
echo "=========================================="
echo ""
echo "Backup location: $HOME/searxng-backups/searxng-backup-*.tar.gz"
echo ""
echo "To restore:"
echo "  1. Extract: tar -xzf searxng-backup-*.tar.gz"
echo "  2. Run: cd <extracted_dir> && bash restore.sh"
echo ""
