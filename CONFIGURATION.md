# Configuration Guide

Tune SearXNG, Redis, and the OpenClaw search integration.

---

## Configuration files

| File | Purpose | Location |
| --- | --- | --- |
| `settings.yml` | SearXNG configuration | `/etc/searxng/settings.yml` |
| `openclaw.json` | OpenClaw plugin/provider configuration | `~/.openclaw/openclaw.json` |
| `searxng.service` | systemd unit | `/etc/systemd/system/searxng.service` |
| `settings.yml.template` | Reference template | [`configs/settings.yml.template`](configs/settings.yml.template) |
| `openclaw-plugin.template` | Reference plugin block | [`configs/openclaw-plugin.template`](configs/openclaw-plugin.template) |

After editing SearXNG settings:

```bash
sudo systemctl restart searxng
```

After editing OpenClaw configuration:

```bash
systemctl --user restart openclaw-gateway.service
openclaw doctor
```

---

## SearXNG configuration

### Inherit SearXNG's defaults

A partial settings file must start with `use_default_settings`. Without it, SearXNG
uses the user file as the complete configuration instead of merging it with the
defaults. `keep_only` limits the merged engine catalogue to the seven engines this
setup enables:

```yaml
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
```

Add or remove engine names in `keep_only` when you change the enabled set. The
`engines:` list below then overrides shortcuts and flags for those engines.

### Minimum settings for OpenClaw

```yaml
search:
  formats:
    - html
    - json            # required by the plugin

server:
  limiter: false      # safe only while bound to loopback
  bind_address: "127.0.0.1"
  port: 8080

redis:
  url: "redis://localhost:6379/0"
```

`json` must be present. If the API returns HTML, this is the first setting to check.

### Engines enabled by the installer

The installer enables seven engines. SearXNG ships with 70+; enable additional ones
by adding their `name` and `engine` entries under `engines:`.

```yaml
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
```

The template adds news engines:

```yaml
  - name: google news
    engine: google_news
    shortcut: gn
    disabled: false
  - name: duckduckgo news
    engine: duckduckgo_news
    shortcut: dn
    disabled: false
```

Enable only engines you need. More engines usually means slower queries and a higher
chance that one upstream engine rate-limits your server.

### Timeouts and connection pools

```yaml
outgoing:
  request_timeout: 10.0       # seconds per request
  max_request_timeout: 30.0   # hard ceiling
  pool_connections: 100
  pool_maxsize: 50
  enable_http2: true
```

`max_request_timeout` belongs under `outgoing`, not `server`.

For a small host (512 MB–1 GB RAM), reduce the pool sizes:

```yaml
outgoing:
  request_timeout: 10.0
  max_request_timeout: 20.0
  pool_connections: 50
  pool_maxsize: 25
```

For a larger host, you can raise them. There is no benchmark in this repository that
justifies a specific number; change one value at a time and measure with your own
queries.

### Security settings

```yaml
server:
  secret_key: "<64 hex characters>"
  limiter: false
  image_proxy: true
```

Generate the key with:

```bash
openssl rand -hex 32
```

`limiter: false` is acceptable only because the service binds to `127.0.0.1`. If you
expose SearXNG beyond loopback, enable the limiter and put authentication and TLS in
front of it. `image_proxy: true` proxies remote images through SearXNG, which hides
your browser's address from image hosts at the cost of extra traffic through the
server.

---

## OpenClaw configuration

### Plugin block used by this repository

The bundled `configure-openclaw.sh` writes this block for the `searxng-search`
plugin:

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

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `baseUrl` | string | `http://localhost:8080` | SearXNG base URL |
| `timeoutMs` | number | `60000` | Request timeout in milliseconds |
| `defaultCount` | number | `100` | Results requested per search |
| `enableMultiPage` | boolean | `true` | Allow multi-page retrieval |

These keys are specific to the plugin this project was built around. Check that your
installed plugin accepts them; `openclaw doctor` reports unknown keys.

### Built-in SearXNG provider (newer OpenClaw)

OpenClaw 2026.6.9+ documents SearXNG as a built-in `web_search` provider. Its
configuration shape is different:

```json5
{
  tools: {
    web: {
      search: {
        provider: "searxng",
        maxResults: 10,
        timeoutSeconds: 60
      }
    }
  },
  plugins: {
    entries: {
      searxng: {
        config: {
          webSearch: {
            baseUrl: "http://127.0.0.1:8080",
            language: "en"
          }
        }
      }
    }
  }
}
```

Notes from the OpenClaw documentation:

- The plugin is installed with `openclaw plugins install @openclaw/searxng-plugin`.
- `baseUrl` lives under `plugins.entries.searxng.config.webSearch`.
- A per-call `count` accepts 1–10 results.
- `http://` base URLs must target a private or loopback host; public hosts require
  `https://`.
- SearXNG must expose `format=json`.

Use one integration style at a time. Do not configure both `searxng-search` and the
built-in `searxng` provider unless you have verified that your OpenClaw release
supports both without conflict.

### Context management

Large search payloads can crowd an agent's context window. If you see context
overflow, lower the result count for the plugin/provider and keep compaction enabled:

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "reserveTokensFloor": 80000,
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 15000
        }
      },
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "6h",
        "keepLastAssistants": 5
      }
    }
  }
}
```

These are OpenClaw agent settings, not SearXNG settings. Confirm the key names
against the docs for your OpenClaw version.

---

## Monitoring

Enable metrics in `settings.yml`:

```yaml
general:
  enable_metrics: true
```

Check service health:

```bash
sudo systemctl status searxng
sudo journalctl -u searxng -f
redis-cli ping
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.unresponsive_engines'
```

The JSON response's `unresponsive_engines` array is the quickest way to see which
upstream engines failed for a query.

---

## Verification

```bash
# YAML syntax
python3 -c "import yaml; yaml.safe_load(open('/etc/searxng/settings.yml'))"

# Redis
redis-cli ping

# SearXNG
sudo systemctl restart searxng
sudo systemctl is-active searxng

# JSON API
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.results | length'

# Page 2
curl -s "http://127.0.0.1:8080/search?q=python&format=json&pageno=2" | jq '.results | length'

# Category search
curl -s "http://127.0.0.1:8080/search?q=code&categories=it&format=json" | jq '.results | length'

# OpenClaw
openclaw doctor 2>&1 | grep -i searxng
```

---

## Redis security

Redis binds to loopback by default on Ubuntu and Debian. For a single-user host that
is usually sufficient. To add a password:

```bash
sudo nano /etc/redis/redis.conf
```

```conf
bind 127.0.0.1
requirepass <generate-a-strong-password>
```

Then update SearXNG:

```yaml
redis:
  url: "redis://:<generate-a-strong-password>@localhost:6379/0"
```

Restart both services:

```bash
sudo systemctl restart redis-server
sudo systemctl restart searxng
```

Do not reuse the SearXNG `secret_key` as the Redis password.

---

## Firewall

SearXNG is loopback-only, so no inbound firewall rule is required. If you deliberately
expose it on a LAN, allow only the specific subnet and understand that there is no
authentication:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp
```

Do not expose port 6379 (Redis) or 8080 directly to the internet.

---

## Configuration checklist

- [ ] `search.formats` includes `json`
- [ ] `server.secret_key` is set to a random value
- [ ] `server.bind_address` is `127.0.0.1`
- [ ] `server.limiter` is `false` only while loopback-bound
- [ ] `redis.url` points at the local Redis instance
- [ ] Required engines are enabled and slow/unused engines are disabled
- [ ] `outgoing.max_request_timeout` is under `outgoing`, not `server`
- [ ] OpenClaw uses one plugin/provider configuration, not both
- [ ] `openclaw doctor` reports no invalid keys
- [ ] `curl ...&format=json` returns results
- [ ] Page 2 returns results for an engine that supports pagination

---

## Next steps

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — common failures and fixes
- [SECURITY.md](SECURITY.md) — threat model and hardening
- [Documentation site](https://searxng.danubelabs.net) — install, usage, maintenance
- [OpenClaw SearXNG provider docs](https://docs.openclaw.ai/tools/searxng-search)

**Configuration time:** about 10 minutes.
