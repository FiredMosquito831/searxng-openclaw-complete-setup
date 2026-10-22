#!/bin/bash
# SearXNG + OpenClaw Complete Setup - Automated Installer
# Usage: sudo bash scripts/install-all.sh

set -e

echo "=========================================="
echo "  SearXNG + OpenClaw Complete Setup"
echo "  Version 1.1.0"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo"
    exit 1
fi

# Check OS
if [ ! -f /etc/os-release ]; then
    log_error "Cannot detect OS. Only Ubuntu/Debian supported."
    exit 1
fi

source /etc/os-release
if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
    log_error "Only Ubuntu and Debian are supported. Detected: $ID"
    exit 1
fi

log_info "Detected: $PRETTY_NAME"

# Step 1: Install dependencies
log_step "[1/8] Installing dependencies..."
apt update
apt install -y python3 python3-pip python3-venv redis-server \
    build-essential libxslt1-dev zlib1g-dev libffi-dev libssl-dev \
    git curl wget jq

if ! command -v redis-server &> /dev/null; then
    log_error "Failed to install dependencies"
    exit 1
fi
log_info "Dependencies installed"

# Step 2: Create searxng user
log_step "[2/8] Creating searxng user..."
if ! id -u searxng &>/dev/null; then
    useradd --shell /bin/bash --system \
        --home-dir "/usr/local/searxng" \
        --comment "SearXNG user" \
        searxng
    log_info "User created"
else
    log_info "User already exists"
fi

mkdir -p /usr/local/searxng /etc/searxng
chown -R searxng:searxng /usr/local/searxng /etc/searxng

# Step 3: Clone repository
log_step "[3/8] Cloning SearXNG repository..."
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
if [ ! -d "searxng-src" ]; then
    git clone https://github.com/searxng/searxng.git searxng-src
    echo "[INFO] Repository cloned"
else
    echo "[INFO] Repository already exists"
fi
EOF

# Step 4: Create virtualenv
log_step "[4/8] Setting up Python virtualenv..."
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
if [ ! -d "searx-pyenv" ]; then
    python3 -m venv searx-pyenv
    echo "[INFO] Virtualenv created"
else
    echo "[INFO] Virtualenv already exists"
fi
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --upgrade pip setuptools wheel pyyaml
EOF

# Step 5: Install SearXNG
log_step "[5/8] Installing SearXNG..."
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --use-pep517 --no-build-isolation -e .
EOF
log_info "SearXNG installed"

# Step 6: Configure settings
log_step "[6/8] Configuring SearXNG..."
if [ -f "/etc/searxng/settings.yml" ]; then
    SETTINGS_BACKUP="/etc/searxng/settings.yml.bak.$(date +%Y%m%d-%H%M%S)"
    cp /etc/searxng/settings.yml "$SETTINGS_BACKUP"
    log_warn "Existing settings preserved; backup written to $SETTINGS_BACKUP"
    log_warn "Edit /etc/searxng/settings.yml manually if you need to apply the new defaults"
else
    # Generate secret key
    SECRET_KEY=$(openssl rand -hex 32)

    # Create optimized configuration
    cat > /etc/searxng/settings.yml << SETTINGS
# Merge with SearXNG's defaults, but keep only these engines
use_default_settings:
  engines:
    keep_only:
      - google
      - duckduckgo
      - brave
      - bing
      - wikipedia
      - github
      - youtube

general:
  debug: false
  instance_name: "SearXNG"
  enable_metrics: true

search:
  safe_search: 0
  autocomplete: "google"
  default_lang: "en"
  formats:
    - html
    - json

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: true
  http_protocol_version: "1.0"
  bind_address: "127.0.0.1"
  port: 8080
  base_url: false

redis:
  url: "redis://localhost:6379/0"

ui:
  default_theme: simple
  default_locale: "en"
  query_in_title: true
  infinite_scroll: true
  center_alignment: true
  results_on_new_tab: true

outgoing:
  request_timeout: 10.0
  max_request_timeout: 30.0
  useragent_suffix: ""
  pool_connections: 100
  pool_maxsize: 50
  enable_http2: true

engines:
  - name: google
    engine: google
    shortcut: g
    disabled: false
  - name: duckduckgo
    engine: duckduckgo
    shortcut: d
    disabled: false
  - name: brave
    engine: brave
    shortcut: b
    disabled: false
  - name: bing
    engine: bing
    shortcut: i
    disabled: false
  - name: wikipedia
    engine: wikipedia
    shortcut: w
    disabled: false
  - name: github
    engine: github
    shortcut: gh
    disabled: false
  - name: youtube
    engine: youtube
    shortcut: yt
    disabled: false
SETTINGS
fi

chown searxng:searxng /etc/searxng/settings.yml
log_info "SearXNG configured"

# Step 7: Configure Redis
log_step "[7/8] Configuring Redis..."
systemctl start redis-server
systemctl enable redis-server
sleep 2

if ! redis-cli ping &>/dev/null; then
    log_error "Redis failed to start"
    exit 1
fi
log_info "Redis running"

# Step 8: Create systemd service
log_step "[8/8] Creating systemd service..."
cat > /etc/systemd/system/searxng.service << 'SERVICE'
[Unit]
Description=SearXNG Privacy-Respecting Metasearch Engine
After=network.target redis-server.service
Wants=redis-server.service

[Service]
Type=simple
User=searxng
Group=searxng
WorkingDirectory=/usr/local/searxng/searxng-src

Environment="SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
Environment="PYTHONPATH=/usr/local/searxng/searxng-src"

ExecStart=/usr/local/searxng/searx-pyenv/bin/python -m searx.webapp --port 8080 --bind 127.0.0.1

Restart=always
RestartSec=10
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable searxng.service
systemctl start searxng.service

# Wait for service to start
sleep 10

# Verification
log_info "Verifying installation..."
echo ""

ERRORS=0

if systemctl is-active --quiet searxng.service; then
    log_info "✅ SearXNG service is running"
else
    log_error "❌ SearXNG service failed to start"
    ERRORS=$((ERRORS + 1))
fi

if redis-cli ping &>/dev/null; then
    log_info "✅ Redis is running"
else
    log_error "❌ Redis is not running"
    ERRORS=$((ERRORS + 1))
fi

# Test API
RESPONSE=$(curl -s "http://localhost:8080/search?q=test&format=json")
RESULT_COUNT=$(echo "$RESPONSE" | jq -r '.results | length' 2>/dev/null || echo "0")

if [ "$RESULT_COUNT" -gt 0 ]; then
    log_info "✅ JSON API working ($RESULT_COUNT results)"
else
    log_warn "⚠️  JSON API returned no results (may need warmup)"
fi

# Check OpenClaw integration
if command -v openclaw &>/dev/null; then
    log_info "OpenClaw detected"
    log_warn "The SearXNG service is ready, but the OpenClaw plugin is configured separately."
    log_info "Run this as your OpenClaw user (not with sudo):"
    log_info "  bash scripts/configure-openclaw.sh"
    log_info "Then verify with: openclaw doctor 2>&1 | grep searxng"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}  ✅ Installation Complete!${NC}"
else
    echo -e "${RED}  ⚠️  Installation completed with $ERRORS errors${NC}"
fi
echo "=========================================="
echo ""
echo "SearXNG URL: http://localhost:8080"
echo "JSON API: http://localhost:8080/search?q=QUERY&format=json"
echo ""
echo "Test commands:"
echo "  curl \"http://localhost:8080/search?q=test&format=json\" | jq '.results | length'"
echo "  sudo systemctl status searxng"
echo "  sudo journalctl -u searxng -f"
echo ""
if command -v openclaw &>/dev/null; then
    echo "OpenClaw commands:"
    echo "  openclaw doctor"
    echo "  systemctl --user status openclaw-gateway.service"
fi
echo ""
echo "Next steps:"
echo "  1. Test SearXNG: curl \"http://localhost:8080/search?q=test&format=json\" | jq '.'"
echo "  2. Configure OpenClaw (as your user): bash scripts/configure-openclaw.sh"
echo "  3. Run tests: bash scripts/test-setup.sh"
echo "=========================================="

exit $ERRORS
