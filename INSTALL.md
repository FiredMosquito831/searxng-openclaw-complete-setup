# Installation Guide

Complete instructions for installing SearXNG and connecting it to OpenClaw.

The automated path takes roughly 15–30 minutes on a small VPS, depending on apt and
pip download speed. You can rerun the installer; it preserves an existing
`/etc/searxng/settings.yml` and prints the path of a timestamped backup.

**Prerequisites**

- Ubuntu 20.04+ or Debian 11+ (including WSL2 with an Ubuntu distribution)
- `sudo` access
- 512 MB RAM minimum, 2 GB recommended
- 1 GB free disk minimum, 5 GB recommended
- Outbound HTTPS access to search engines
- OpenClaw installed, with a SearXNG plugin/provider available, if you want the
  agent integration

---

## Method 1: Automated installation (recommended)

### Step 1: Clone the repository

```bash
git clone https://github.com/FiredMosquito831/searxng-openclaw-complete-setup.git
cd searxng-openclaw-complete-setup
```

### Step 2: Run the installer

```bash
sudo bash scripts/install-all.sh
```

The installer:

1. Installs Python, Redis, and build dependencies with `apt`.
2. Creates the `searxng` system user.
3. Clones SearXNG into `/usr/local/searxng/searxng-src`.
4. Creates a Python virtual environment and installs SearXNG in editable mode.
5. Writes a settings file with the JSON API enabled, loopback binding, and Redis.
6. Starts and enables Redis.
7. Installs and starts `searxng.service`.
8. Checks the service, Redis, and JSON API.

It does **not** modify OpenClaw. Continue with step 3.

### Step 3: Configure OpenClaw

Run this as the user that owns `~/.openclaw`, **without** `sudo`:

```bash
bash scripts/configure-openclaw.sh
```

The script:

- Backs up `~/.openclaw/openclaw.json`.
- Adds a `plugins.entries["searxng-search"]` block pointing at
  `http://localhost:8080`.
- Runs `openclaw doctor`, applies `openclaw doctor --fix` if validation fails, and
  restarts the user gateway.
- Checks that the plugin is visible.

If `jq` is missing it prints the JSON block to add manually. If OpenClaw is not
installed, skip this step; SearXNG still works standalone.

> **Plugin compatibility:** the generated block targets the `searxng-search` plugin
> used by OpenClaw 2026.2.x. Newer OpenClaw releases ship a built-in SearXNG provider
> with different keys. See [CONFIGURATION.md](CONFIGURATION.md#openclaw-configuration)
> for the current form before changing provider settings.

### Step 4: Verify

```bash
bash scripts/test-setup.sh
```

The test suite checks the SearXNG service, Redis, the HTML endpoint, the JSON API,
page 2, OpenClaw installation, plugin visibility, and free disk space. OpenClaw
checks are warnings when OpenClaw is absent.

**Standalone SearXNG is ready at `http://127.0.0.1:8080`.**

---

## Method 2: Manual installation

Use this path if you want to inspect or customize every step.

### Step 0: Check the host

```bash
cat /etc/os-release
free -h
df -h /
sudo whoami
```

Expected: Ubuntu 20.04+ or Debian 11+, at least 512 MB RAM and 1 GB free disk, and
working `sudo`.

### Step 1: Install dependencies

```bash
sudo apt update

sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    redis-server \
    build-essential \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    git \
    curl \
    wget \
    jq
```

### Step 2: Create the SearXNG user and directories

```bash
sudo useradd --shell /bin/bash --system \
    --home-dir "/usr/local/searxng" \
    --comment "SearXNG user" \
    searxng

sudo mkdir -p /usr/local/searxng /etc/searxng
sudo chown -R searxng:searxng /usr/local/searxng /etc/searxng
```

If the user already exists, `useradd` prints a warning and the remaining commands
still work.

### Step 3: Clone SearXNG

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
git clone https://github.com/searxng/searxng.git searxng-src
EOF
```

### Step 4: Create the Python virtual environment

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng
python3 -m venv searx-pyenv
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --upgrade pip setuptools wheel pyyaml
EOF
```

### Step 5: Install SearXNG

```bash
sudo -u searxng -i << 'EOF'
cd /usr/local/searxng/searxng-src
source /usr/local/searxng/searx-pyenv/bin/activate
pip install --use-pep517 --no-build-isolation -e .
EOF
```

### Step 6: Write the configuration

```bash
SECRET_KEY=$(openssl rand -hex 32)
sudo bash -c "cat > /etc/searxng/settings.yml << SETTINGS
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
  useragent_suffix: \"\"
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

`search.formats` must contain `json` or OpenClaw cannot use the API. The template in
[`configs/settings.yml.template`](configs/settings.yml.template) also enables Google
News and DuckDuckGo News.

### Step 7: Start Redis

```bash
sudo systemctl start redis-server
sudo systemctl enable redis-server
redis-cli ping
```

Expected: `PONG`.

### Step 8: Create the systemd service

```bash
sudo bash -c "cat > /etc/systemd/system/searxng.service << 'SERVICE'
[Unit]
Description=SearXNG Privacy-Respecting Metasearch Engine
After=network.target redis-server.service
Wants=redis-server.service

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
sudo systemctl enable --now searxng.service
```

### Step 9: Configure OpenClaw

First install or select a SearXNG plugin/provider in OpenClaw for your release. This
repository supplies configuration, not the plugin package.

```bash
mkdir -p ~/.openclaw
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup 2>/dev/null || true
nano ~/.openclaw/openclaw.json
```

Add the block for the plugin this project targets:

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

If you use OpenClaw's built-in SearXNG provider instead, see the alternative block in
[CONFIGURATION.md](CONFIGURATION.md#openclaw-configuration).

Restart the gateway as your user:

```bash
systemctl --user restart openclaw-gateway.service
sleep 10
openclaw doctor 2>&1 | grep -i searxng
```

### Step 10: Verify

```bash
sudo systemctl status searxng
redis-cli ping
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.results | length'
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.unresponsive_engines'
```

A positive result count means the JSON API is working. The exact count varies by
engine availability and upstream rate limits. `unresponsive_engines` lists engines
that did not answer for that query.

---

## Usage checks

```bash
# Basic search
curl -s "http://127.0.0.1:8080/search?q=python&format=json" | jq '.results | length'

# Second page
curl -s "http://127.0.0.1:8080/search?q=python&format=json&pageno=2" | jq '.results | length'

# Category filter
curl -s "http://127.0.0.1:8080/search?q=rust&categories=it&format=json" | jq '.results | length'
```

From OpenClaw, ask in natural language:

```text
Search for Python tutorials using SearXNG
```

---

## Troubleshooting during install

### Service will not start

```bash
sudo journalctl -u searxng -n 50 --no-pager
sudo systemctl restart redis-server
sudo systemctl restart searxng
```

### Port 8080 is already in use

```bash
sudo lsof -i :8080
```

Stop the conflicting service, or change `server.port` in
`/etc/searxng/settings.yml` and the `--port` value in the systemd unit, then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart searxng
```

### JSON API returns HTML

Ensure `/etc/searxng/settings.yml` contains:

```yaml
search:
  formats:
    - html
    - json
```

Then restart SearXNG. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more.

### OpenClaw plugin is not detected

```bash
openclaw doctor
openclaw doctor --fix
systemctl --user restart openclaw-gateway.service
```

Confirm the plugin/provider is installed for your OpenClaw version and that
`baseUrl` points to `http://localhost:8080`.

---

## Next steps

- [CONFIGURATION.md](CONFIGURATION.md) — tune engines, Redis, and OpenClaw.
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — common failures.
- [FAQ.md](FAQ.md) — cost, privacy, and support questions.
- [Documentation site](https://searxng.danubelabs.net) — same material, searchable.

**Installation time:** 15–30 minutes (network dependent).
