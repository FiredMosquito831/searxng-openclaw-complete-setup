# 📖 Installation Guide

**Complete step-by-step installation instructions**

---

## ⏱️ Time Estimate

- **Automated Install:** 20 minutes
- **Manual Install:** 30 minutes
- **Verification:** 5 minutes

---

## 🚀 Method 1: Automated Installation (Recommended)

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/searxng-openclaw-complete
cd searxng-openclaw-complete
```

### Step 2: Run Installer

```bash
sudo bash scripts/install-all.sh
```

### Step 3: Verify

```bash
bash scripts/test-setup.sh
```

**Done!** ✅ Skip to [Usage](#usage) section.

---

## 🛠️ Method 2: Manual Installation

### Prerequisites

Check requirements:
```bash
# Check OS
cat /etc/os-release

# Check RAM
free -h

# Check disk
df -h /

# Check sudo access
sudo whoami
```

**Expected:**
- Ubuntu 20.04+ or Debian 11+
- 2GB+ RAM available
- 5GB+ disk space
- sudo access granted

---

### Step 1: Install Dependencies

```bash
sudo apt update

sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    redis-server \
    build-essential \
    libxslt-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    git \
    curl \
    wget \
    jq
```

---

### Step 2: Create SearXNG User

```bash
sudo useradd --shell /bin/bash --system \
    --home-dir "/usr/local/searxng" \
    --comment "SearXNG user" \
    searxng

sudo mkdir -p /usr/local/searxng /etc/searxng
sudo chown -R searxng:searxng /usr/local/searxng /etc/searxng
```

---

### Step 3: Clone SearXNG Repository

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
git clone https://github.com/searxng/searxng.git searxng-src
EOF
```

---

### Step 4: Create Python Virtual Environment

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
python3 -m venv searx-pyenv
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --upgrade pip setuptools wheel pyyaml
EOF
```

---

### Step 5: Install SearXNG

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --use-pep517 --no-build-isolation -e .
EOF
```

---

### Step 6: Configure SearXNG

```bash
# Copy default settings
sudo -u searxng cp /usr/local/searxng/searxng-src/utils/templates/etc/searxng/settings.yml /etc/searxng/settings.yml

# Generate secret key
SECRET_KEY=$(openssl rand -hex 32)

# Create optimized configuration
sudo bash -c "cat > /etc/searxng/settings.yml << SETTINGS
general:
  debug: false
  instance_name: \"SearXNG\"
  enable_metrics: true

search:
  safe_search: 0
  autocomplete: \"google\"
  default_lang: \"en\"
  formats:
    - html
    - json

server:
  secret_key: \"$SECRET_KEY\"
  limiter: false
  image_proxy: true
  http_protocol_version: \"1.0\"
  bind_address: \"127.0.0.1\"
  port: 8080
  base_url: false

redis:
  url: \"redis://localhost:6379/0\"

ui:
  default_theme: simple
  default_locale: \"en\"
  query_in_title: true
  infinite_scroll: true
  center_alignment: true
  results_on_new_tab: true

outgoing:
  request_timeout: 10.0
  max_request_timeout: 30.0
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
"

sudo chown searxng:searxng /etc/searxng/settings.yml
```

---

### Step 7: Start Redis

```bash
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify
redis-cli ping
# Expected: PONG
```

---

### Step 8: Create Systemd Service

```bash
sudo bash -c "cat > /etc/systemd/system/searxng.service << 'SERVICE'
[Unit]
Description=SearXNG Privacy-Respecting Metasearch Engine
After=network.target redis.service
Wants=redis.service

[Service]
Type=simple
User=searxng
Group=searxng
WorkingDirectory=/usr/local/searxng/searxng-src

Environment=\"SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml\"
Environment=\"PYTHONPATH=/usr/local/searxng/searxng-src\"

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
"

sudo systemctl daemon-reload
sudo systemctl enable searxng.service
sudo systemctl start searxng.service
```

---

### Step 9: Configure OpenClaw

```bash
# Backup current config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup

# Edit OpenClaw configuration
nano ~/.openclaw/openclaw.json
```

Add/update plugin configuration:
```json
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
```

Restart OpenClaw:
```bash
systemctl --user restart openclaw-gateway.service
sleep 10
```

---

### Step 10: Verify Installation

```bash
# Check SearXNG
sudo systemctl status searxng

# Check Redis
redis-cli ping

# Test API
curl "http://localhost:8080/search?q=test&format=json" | jq '.results | length'

# Check OpenClaw
openclaw doctor 2>&1 | grep searxng
```

**Expected:** All checks pass ✅

---

## 🎯 Usage

### Test Basic Search

```bash
curl "http://localhost:8080/search?q=python&format=json" | jq '.results | length'
# Expected: 20-40 results
```

### Test Multi-Page Search

```bash
curl "http://localhost:8080/search?q=python&format=json&pageno=2" | jq '.results | length'
# Expected: 20-40 results
```

### Test via OpenClaw

Send to your Telegram bot:
```
Search for Python tutorials using SearXNG
```

---

## 🔍 Troubleshooting

### Issue: Service won't start

```bash
# Check logs
sudo journalctl -u searxng -n 50

# Common fix: Restart everything
sudo systemctl restart redis-server
sudo systemctl restart searxng
```

### Issue: Port 8080 already in use

```bash
# Find process
sudo lsof -i :8080

# Kill or change port
sudo nano /etc/searxng/settings.yml
# Change: port: 8081
```

### Issue: No results returned

```bash
# Check engine status
curl http://localhost:8080/stats | jq '.engines'

# Enable engines in config
sudo nano /etc/searxng/settings.yml
```

### Issue: OpenClaw plugin not loading

```bash
# Check config
openclaw doctor

# Fix invalid keys
openclaw doctor --fix

# Restart gateway
systemctl --user restart openclaw-gateway.service
```

---

## ✅ Next Steps

1. **[CONFIGURATION.md](CONFIGURATION.md)** - Optimize settings
2. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues
3. **[FAQ.md](FAQ.md)** - Frequently asked questions

---

**Installation Complete!** 🎉

**Last Updated:** 2026-02-24  
**Installation Time:** 20-30 minutes
