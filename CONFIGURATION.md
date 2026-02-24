# ⚙️ Configuration Guide

**Optimize your SearXNG + OpenClaw setup**

---

## 📋 **CONFIGURATION FILES**

| File | Purpose | Location |
|------|---------|----------|
| `settings.yml` | SearXNG main config | `/etc/searxng/settings.yml` |
| `openclaw.json` | OpenClaw plugin config | `~/.openclaw/openclaw.json` |
| `searxng.service` | Systemd service | `/etc/systemd/system/searxng.service` |

---

## 🔧 **SEARXNG CONFIGURATION**

### Optimal Settings for OpenClaw

Edit `/etc/searxng/settings.yml`:

```yaml
# Critical for OpenClaw integration
search:
  formats:
    - html
    - json  # ⚠️ REQUIRED for OpenClaw!

server:
  limiter: false           # Disable for local use
  bind_address: "127.0.0.1"  # Localhost only (secure)
  port: 8080

redis:
  url: "redis://localhost:6379/0"  # Required for caching

# Enable these engines for best results
engines:
  - name: google
    engine: google
    disabled: false
  - name: duckduckgo
    engine: duckduckgo
    disabled: false
  - name: brave
    engine: brave
    disabled: false
  - name: github
    engine: github
    disabled: false
  - name: wikipedia
    engine: wikipedia
    disabled: false
```

### Performance Tuning

```yaml
outgoing:
  request_timeout: 10.0      # Seconds to wait
  max_request_timeout: 30.0  # Maximum timeout
  pool_connections: 100      # Connection pool
  pool_maxsize: 50          # Max connections per host
  enable_http2: true        # Enable HTTP/2
```

### Security Hardening

```yaml
server:
  secret_key: "GENERATE_64_CHAR_RANDOM_STRING"
  limiter: false           # OK for localhost
  image_proxy: true        # Proxy images for privacy
  
# Generate secret key:
# openssl rand -hex 32
```

---

## 🔧 **OPENCLAW CONFIGURATION**

### Plugin Configuration

Edit `~/.openclaw/openclaw.json`:

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

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseUrl` | string | `"http://localhost:8080"` | SearXNG instance URL |
| `timeoutMs` | number | `60000` | Request timeout (ms) |
| `defaultCount` | number | `100` | Default results to fetch |
| `enableMultiPage` | boolean | `true` | Enable multi-page search |

### Memory Search Enhancement

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "openai",
        "remote": {
          "baseUrl": "https://openrouter.ai/api/v1"
        },
        "model": "qwen/qwen3-embedding-8b",
        "query": {
          "hybrid": {
            "enabled": true,
            "vectorWeight": 0.7,
            "textWeight": 0.3,
            "candidateMultiplier": 4,
            "mmr": {
              "enabled": true,
              "lambda": 0.7
            },
            "temporalDecay": {
              "enabled": true,
              "halfLifeDays": 30
            }
          }
        }
      }
    }
  }
}
```

---

## ⚡ **PERFORMANCE OPTIMIZATION**

### For Low-Resource Systems (< 2GB RAM)

```yaml
# /etc/searxng/settings.yml
outgoing:
  pool_connections: 50
  pool_maxsize: 25
  
server:
  max_request_timeout: 20.0
```

### For High-Performance Systems (> 4GB RAM)

```yaml
# /etc/searxng/settings.yml
outgoing:
  pool_connections: 200
  pool_maxsize: 100
  
redis:
  url: "redis://localhost:6379/0"
  # Add Redis configuration for better caching
```

### OpenClaw Context Management

```json
{
  "compaction": {
    "reserveTokensFloor": 80000,
    "softThresholdTokens": 15000
  },
  "contextPruning": {
    "mode": "cache-ttl",
    "ttl": "6h",
    "keepLastAssistants": 5
  }
}
```

---

## 🎯 **ENGINE CONFIGURATION**

### Recommended Engines

```yaml
engines:
  # General Search
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

  # Knowledge
  - name: wikipedia
    engine: wikipedia
    shortcut: w
    disabled: false

  # Code
  - name: github
    engine: github
    shortcut: gh
    disabled: false

  # Video
  - name: youtube
    engine: youtube
    shortcut: yt
    disabled: false

  # News
  - name: google news
    engine: google_news
    shortcut: gn
    disabled: false
```

### Disable Slow Engines

```yaml
engines:
  - name: some_slow_engine
    engine: some_slow_engine
    disabled: true  # Disable slow engines
```

---

## 🔒 **SECURITY CONFIGURATION**

### Firewall Rules (UFW)

```bash
# Allow only localhost
sudo ufw allow from 127.0.0.1 to any port 8080

# If accessing from LAN (not recommended)
sudo ufw allow from 192.168.1.0/24 to any port 8080
```

### Redis Security

```bash
# Edit Redis config
sudo nano /etc/redis/redis.conf

# Add these lines:
bind 127.0.0.1
requirepass YOUR_STRONG_PASSWORD
```

Update SearXNG config:
```yaml
redis:
  url: "redis://:YOUR_STRONG_PASSWORD@localhost:6379/0"
```

---

## 📊 **MONITORING CONFIGURATION**

### Enable Metrics

```yaml
general:
  enable_metrics: true
```

Access metrics:
```bash
curl http://localhost:8080/stats
```

### Systemd Service Monitoring

```bash
# Check status
sudo systemctl status searxng

# View logs
sudo journalctl -u searxng -f

# Auto-restart on failure
# Already configured in searxng.service:
# Restart=always
# RestartSec=10
```

---

## ✅ **CONFIGURATION VERIFICATION**

### Test Configuration

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('/etc/searxng/settings.yml'))"

# Check Redis connection
redis-cli ping

# Test service
sudo systemctl restart searxng
sudo systemctl status searxng
```

### Test API Endpoints

```bash
# Basic search
curl "http://localhost:8080/search?q=test&format=json" | jq '.results | length'

# Multi-page search
curl "http://localhost:8080/search?q=python&format=json&pageno=2" | jq '.results | length'

# Category search
curl "http://localhost:8080/search?q=code&categories=it&format=json" | jq '.results | length'
```

### Test OpenClaw Integration

```bash
# Check plugin loaded
openclaw doctor 2>&1 | grep searxng

# Test search via Telegram
# Send to bot: "Search for Python tutorials using SearXNG"
```

---

## 🐛 **COMMON CONFIGURATION ISSUES**

### Issue: JSON API returns HTML

**Solution:** Check formats in settings.yml
```yaml
search:
  formats:
    - html
    - json  # Must include json!
```

### Issue: No results returned

**Solution:** Check engines are enabled
```bash
curl http://localhost:8080/stats | jq '.engines'
```

### Issue: Timeout errors

**Solution:** Increase timeouts
```yaml
outgoing:
  request_timeout: 20.0
  max_request_timeout: 60.0
```

### Issue: Redis connection error

**Solution:** Start Redis
```bash
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

---

## 📝 **CONFIGURATION CHECKLIST**

- [ ] `search.formats` includes `json`
- [ ] `server.secret_key` is changed
- [ ] `redis.url` is configured
- [ ] `server.limiter` is false (for local)
- [ ] `server.bind_address` is `127.0.0.1`
- [ ] Required engines are enabled
- [ ] Timeouts are appropriate
- [ ] OpenClaw plugin configured
- [ ] Service restarts successfully
- [ ] JSON API returns results
- [ ] Multi-page search works

---

## 🎯 **NEXT STEPS**

After configuration:

1. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues
2. **[PERFORMANCE.md](docs/PERFORMANCE.md)** - Performance tuning
3. **[SECURITY.md](docs/SECURITY.md)** - Security hardening

---

**Last Updated:** 2026-02-24  
**Configuration Time:** 10 minutes
