# Troubleshooting Guide

Common failures and fixes for a local SearXNG + OpenClaw deployment.

---

## First diagnostics

```bash
# Services
sudo systemctl status searxng --no-pager
sudo systemctl status redis-server --no-pager
redis-cli ping

# OpenClaw
openclaw doctor
systemctl --user status openclaw-gateway.service --no-pager

# Logs
sudo journalctl -u searxng -n 100 --no-pager
journalctl --user -u openclaw-gateway.service -n 100 --no-pager

# JSON API
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '{results: (.results | length), unresponsive: .unresponsive_engines}'

# Full suite
bash scripts/test-setup.sh
```

---

## Issue 1: SearXNG service will not start

**Symptoms**

```text
● searxng.service
     Active: failed (Result: exit-code)
```

**Check the logs**

```bash
sudo journalctl -u searxng -n 100 --no-pager
```

**Common causes**

- Port 8080 is already in use.
- Redis is not running.
- `settings.yml` is invalid YAML.
- File ownership is wrong.

**Port conflict**

```bash
sudo lsof -i :8080
```

Stop the conflicting process. If you would rather move SearXNG, change `server.port`
in `/etc/searxng/settings.yml` **and** the `--port` argument in the `ExecStart` line
of `/etc/systemd/system/searxng.service`, then:

```bash
sudo systemctl daemon-reload
sudo systemctl restart searxng
```

**Redis not running**

```bash
sudo systemctl start redis-server
sudo systemctl restart searxng
```

**Invalid configuration**

```bash
python3 -c "import yaml; yaml.safe_load(open('/etc/searxng/settings.yml'))"
sudo nano /etc/searxng/settings.yml
sudo systemctl restart searxng
```

**Ownership**

```bash
sudo chown -R searxng:searxng /usr/local/searxng /etc/searxng
sudo chmod 644 /etc/searxng/settings.yml
sudo systemctl restart searxng
```

---

## Issue 2: JSON API returns HTML

**Symptoms**

```bash
curl "http://127.0.0.1:8080/search?q=test&format=json"
```

returns `<!doctype html>` instead of JSON.

**Fix**

`/etc/searxng/settings.yml` must contain:

```yaml
search:
  formats:
    - html
    - json
```

Then:

```bash
sudo systemctl restart searxng
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.results | length'
```

The same symptom appears if the plugin uses the wrong base URL and reaches an HTML
page instead of SearXNG.

---

## Issue 3: No results returned

**Symptoms**

```bash
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.results | length'
0
```

**Check which engines failed**

```bash
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.unresponsive_engines'
```

**Check that engines are enabled**

```yaml
engines:
  - name: google
    engine: google
    disabled: false
```

**Check outbound network access**

```bash
curl -I https://www.google.com
ping -c 3 duckduckgo.com
```

**Check for rate limiting**

Upstream engines may temporarily block or throttle your server. Wait and retry, or
disable the engine that is failing. There is no fixed warmup period; results should
appear as soon as an engine answers.

**Check the system clock**

A large clock skew can break HTTPS requests:

```bash
timedatectl
```

---

## Issue 4: Redis connection refused

**Symptoms**

```text
redis.exceptions.ConnectionError: Error 111 connecting to localhost:6379. Connection refused.
```

**Fix**

```bash
sudo systemctl start redis-server
sudo systemctl enable redis-server
redis-cli ping
```

Expected: `PONG`.

If it still fails:

```bash
sudo systemctl status redis-server --no-pager
sudo journalctl -u redis-server -n 50 --no-pager
sudo nano /etc/redis/redis.conf
```

Confirm `bind 127.0.0.1` and `port 6379`, then:

```bash
sudo systemctl restart redis-server
sudo systemctl restart searxng
```

---

## Issue 5: Port 8080 already in use

**Symptoms**

```text
OSError: [Errno 98] Address already in use
```

**Find the process**

```bash
sudo lsof -i :8080
# or
sudo ss -ltnp | grep :8080
```

Stop it, or move SearXNG:

```yaml
server:
  port: 8081
```

Also update `ExecStart=... --port 8081` in the systemd unit, then:

```bash
sudo systemctl daemon-reload
sudo systemctl restart searxng
```

If you move the port, update `baseUrl` in the OpenClaw plugin configuration as well.

---

## Issue 6: OpenClaw plugin not loading

**Symptoms**

```bash
openclaw doctor 2>&1 | grep -i searxng
# no output
```

**Check the configuration**

```bash
nano ~/.openclaw/openclaw.json
```

For the plugin this repository targets:

```json
{
  "plugins": {
    "entries": {
      "searxng-search": {
        "enabled": true,
        "config": {
          "baseUrl": "http://localhost:8080"
        }
      }
    }
  }
}
```

**Check plugin compatibility**

Newer OpenClaw releases use the built-in provider id `searxng` and keys under
`plugins.entries.searxng.config.webSearch`. Using the wrong shape for your release
leaves the plugin unloaded. See
[CONFIGURATION.md](CONFIGURATION.md#openclaw-configuration).

**Validate and restart**

```bash
openclaw doctor
openclaw doctor --fix
systemctl --user restart openclaw-gateway.service
openclaw doctor 2>&1 | grep -i searxng
```

**Check the gateway log**

```bash
journalctl --user -u openclaw-gateway.service -n 100 --no-pager
```

Confirm that SearXNG answers on the configured URL:

```bash
curl -s "http://localhost:8080/search?q=test&format=json" | jq '.results | length'
```

---

## Issue 7: Context overflow in OpenClaw

**Symptoms**

```text
Error: prompt too large for the model
```

**Reduce result volume**

For the `searxng-search` plugin:

```json
{
  "plugins": {
    "entries": {
      "searxng-search": {
        "config": {
          "defaultCount": 25
        }
      }
    }
  }
}
```

For the built-in provider, set `tools.web.search.maxResults` and keep per-call
`count` small.

**Keep compaction enabled**

```json
{
  "compaction": {
    "reserveTokensFloor": 80000,
    "softThresholdTokens": 15000
  }
}
```

Then restart the gateway and, in an interactive session, run `/compact` if your
OpenClaw version supports it. Key names vary by release; check `openclaw doctor`.

---

## Issue 8: Multi-page search returns nothing

**Symptoms**

```bash
curl -s "http://127.0.0.1:8080/search?q=test&format=json&pageno=2" | jq '.results | length'
0
```

**Causes**

- The enabled engines do not support pagination for that query.
- Upstream engines are rate-limiting the instance.
- The query has few results to begin with.

**Try another query or engine**

```bash
curl -s "http://127.0.0.1:8080/search?q=python&format=json&pageno=2" | jq '.results | length'
curl -s "http://127.0.0.1:8080/search?q=python&format=json&pageno=2&engines=google" | jq '.results | length'
```

If your SearXNG version supports `search.max_page`, you can raise the page limit:

```yaml
search:
  max_page: 10
```

Not every release supports this key; if SearXNG rejects it, remove it and rely on the
default pagination behavior.

---

## Issue 9: Slow searches

**Symptoms**

Search takes more than roughly ten seconds.

**Reduce the engine set**

Disable engines you do not need:

```yaml
engines:
  - name: unused_engine
    disabled: true
```

**Use the `unresponsive_engines` field**

```bash
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.unresponsive_engines'
```

A single slow or blocked engine can hold up the merged response.

**Lower timeouts**

```yaml
outgoing:
  request_timeout: 5.0
  max_request_timeout: 15.0
```

**Reduce connection pool sizes on small hosts**

```yaml
outgoing:
  pool_connections: 50
  pool_maxsize: 25
```

**Check resources**

```bash
free -h
df -h /
uptime
```

There is no benchmark in this repository that promises a specific latency. Measure
with your own queries and engine set.

---

## Issue 10: Permission denied

**Symptoms**

```text
PermissionError: [Errno 13] Permission denied
```

**Fix ownership**

```bash
sudo chown -R searxng:searxng /usr/local/searxng
sudo chown -R searxng:searxng /etc/searxng
sudo chmod 755 /usr/local/searxng
sudo chmod 644 /etc/searxng/settings.yml
sudo systemctl restart searxng
```

Do not run the SearXNG service as `root`. The supplied unit uses the `searxng` user
and sandboxing directives.

---

## Issue 11: Installer preserved an old configuration

This is intentional. On re-run, `install-all.sh` does not overwrite
`/etc/searxng/settings.yml`. It writes a timestamped backup and prints its path. If
you want the new defaults, compare and merge manually:

```bash
ls -l /etc/searxng/settings.yml*
sudo diff -u /etc/searxng/settings.yml.bak.YYYYMMDD-HHMMSS /etc/searxng/settings.yml
sudo nano /etc/searxng/settings.yml
sudo systemctl restart searxng
```

---

## Issue 12: Update script fails at `git pull`

The update script pulls the branch that is checked out in
`/usr/local/searxng/searxng-src` and uses `--ff-only`. Failure usually means local
modifications or a diverged checkout.

```bash
sudo -u searxng -i
cd /usr/local/searxng/searxng-src
git status
git branch --show-current
git log --oneline -5
exit
```

Back up local changes before resetting. SearXNG's upstream default branch is
`master`.

---

## Error reference

| Error | Meaning | Fix |
| --- | --- | --- |
| `503 Service Unavailable` | SearXNG is not running or is starting | `sudo systemctl start searxng`; check logs |
| `504 Gateway Timeout` | Upstream engine or proxy timeout | Increase `outgoing.request_timeout`; disable slow engines |
| `429 Too Many Requests` | SearXNG limiter or an upstream engine is throttling | If SearXNG's limiter is on, turn it off for loopback use; otherwise wait and reduce engines |
| `Connection refused` | Redis or SearXNG is not listening | `sudo systemctl start redis-server searxng` |
| `Address already in use` | Port conflict | Change port or stop the conflicting process |
| `JSONDecodeError` | The client received HTML, not JSON | Enable `json` in `search.formats`; check `baseUrl` |
| `No such file or directory` | Wrong path or missing install | Re-run `sudo bash scripts/install-all.sh` |

---

## Collecting information for an issue

```bash
{
  echo "== OS =="; cat /etc/os-release
  echo "== SearXNG =="; systemctl is-active searxng; systemctl is-enabled searxng
  echo "== Redis =="; redis-cli ping
  echo "== API =="; curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '{results: (.results | length), unresponsive: .unresponsive_engines}'
  echo "== Logs =="; sudo journalctl -u searxng -n 50 --no-pager
} > /tmp/searxng-diagnostics.txt
```

Review the file for secrets before attaching it to an issue.

---

## Get help

- [FAQ.md](FAQ.md)
- [GitHub Issues](https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/issues)
- [Documentation site](https://searxng.danubelabs.net)

**Last updated:** 2026-10-22
