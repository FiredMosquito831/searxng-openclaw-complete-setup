# 🐛 Troubleshooting Guide

**Common issues and solutions**

---

## 🔍 **DIAGNOSTIC COMMANDS**

```bash
# Check SearXNG status
sudo systemctl status searxng

# Check Redis status
redis-cli ping
sudo systemctl status redis-server

# Check OpenClaw status
openclaw doctor
systemctl --user status openclaw-gateway.service

# View logs
sudo journalctl -u searxng -f
journalctl --user -u openclaw-gateway.service -f

# Test API
curl "http://localhost:8080/search?q=test&format=json" | jq '.'
```

---

## 🚨 **COMMON ISSUES**

### Issue 1: SearXNG Service Won't Start

**Symptoms:**
```
sudo systemctl status searxng
● searxng.service - SearXNG...
     Active: failed (Result: exit-code)
```

**Solutions:**

1. **Check logs:**
   ```bash
   sudo journalctl -u searxng -n 50 --no-pager
   ```

2. **Common causes:**
   - Port 8080 already in use
   - Redis not running
   - Configuration error

3. **Fix port conflict:**
   ```bash
   sudo lsof -i :8080
   sudo kill <PID>
   sudo systemctl restart searxng
   ```

4. **Fix Redis connection:**
   ```bash
   sudo systemctl start redis-server
   sudo systemctl restart searxng
   ```

5. **Fix configuration:**
   ```bash
   sudo python3 -c "import yaml; yaml.safe_load(open('/etc/searxng/settings.yml'))"
   sudo nano /etc/searxng/settings.yml
   sudo systemctl restart searxng
   ```

---

### Issue 2: JSON API Returns HTML Instead of JSON

**Symptoms:**
```bash
curl "http://localhost:8080/search?q=test&format=json"
<!doctype html>
<html>...
```

**Solution:**

Edit `/etc/searxng/settings.yml`:
```yaml
search:
  formats:
    - html
    - json  # ⚠️ MUST include json!
```

Restart:
```bash
sudo systemctl restart searxng
```

---

### Issue 3: No Results Returned

**Symptoms:**
```bash
curl "http://localhost:8080/search?q=test&format=json" | jq '.results | length'
0
```

**Solutions:**

1. **Check engine status:**
   ```bash
   curl http://localhost:8080/stats | jq '.engines'
   ```

2. **Enable engines:**
   Edit `/etc/searxng/settings.yml`:
   ```yaml
   engines:
     - name: google
       engine: google
       disabled: false  # Must be false!
   ```

3. **Wait for warmup:**
   Some engines need time to initialize. Wait 5 minutes and try again.

4. **Check network:**
   ```bash
   ping -c 3 google.com
   ```

---

### Issue 4: Redis Connection Refused

**Symptoms:**
```
redis.exceptions.ConnectionError: Error 111 connecting to localhost:6379. Connection refused.
```

**Solutions:**

1. **Start Redis:**
   ```bash
   sudo systemctl start redis-server
   sudo systemctl enable redis-server
   ```

2. **Check Redis:**
   ```bash
   redis-cli ping
   # Expected: PONG
   ```

3. **Check Redis config:**
   ```bash
   sudo nano /etc/redis/redis.conf
   # Ensure: bind 127.0.0.1
   # Ensure: port 6379
   sudo systemctl restart redis-server
   ```

---

### Issue 5: Port 8080 Already in Use

**Symptoms:**
```
OSError: [Errno 98] Address already in use
```

**Solutions:**

1. **Find process:**
   ```bash
   sudo lsof -i :8080
   ```

2. **Kill process:**
   ```bash
   sudo kill <PID>
   ```

3. **Or change port:**
   Edit `/etc/searxng/settings.yml`:
   ```yaml
   server:
     port: 8081  # Change to different port
   ```

4. **Restart:**
   ```bash
   sudo systemctl restart searxng
   ```

---

### Issue 6: OpenClaw Plugin Not Loading

**Symptoms:**
```bash
openclaw doctor 2>&1 | grep searxng
# No output
```

**Solutions:**

1. **Check plugin config:**
   ```bash
   nano ~/.openclaw/openclaw.json
   ```

   Ensure:
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

2. **Fix invalid config:**
   ```bash
   openclaw doctor --fix
   ```

3. **Restart OpenClaw:**
   ```bash
   systemctl --user restart openclaw-gateway.service
   ```

4. **Check logs:**
   ```bash
   journalctl --user -u openclaw-gateway.service -f
   ```

---

### Issue 7: Context Overflow in OpenClaw

**Symptoms:**
```
Error: prompt too large for the model
```

**Solutions:**

1. **Adjust compaction:**
   Edit `~/.openclaw/openclaw.json`:
   ```json
   {
     "compaction": {
       "reserveTokensFloor": 80000,
       "softThresholdTokens": 15000
     }
   }
   ```

2. **Force compaction:**
   ```
   /compact
   ```

3. **Reduce search results:**
   ```json
   {
     "plugins": {
       "searxng-search": {
         "config": {
           "defaultCount": 50
         }
       }
     }
   }
   ```

---

### Issue 8: Multi-Page Search Not Working

**Symptoms:**
```bash
curl "http://localhost:8080/search?q=test&format=json&pageno=2"
# Returns 0 results
```

**Solutions:**

1. **Check engine supports pagination:**
   Some engines don't support pagination. Try different engines.

2. **Increase max_page:**
   Edit `/etc/searxng/settings.yml`:
   ```yaml
   search:
     max_page: 10  # Allow up to 10 pages
   ```

3. **Restart:**
   ```bash
   sudo systemctl restart searxng
   ```

---

### Issue 9: Slow Search Performance

**Symptoms:**
```
Search takes > 10 seconds
```

**Solutions:**

1. **Disable slow engines:**
   Edit `/etc/searxng/settings.yml`:
   ```yaml
   engines:
     - name: slow_engine
       disabled: true
   ```

2. **Reduce timeout:**
   ```yaml
   outgoing:
     request_timeout: 5.0
     max_request_timeout: 15.0
   ```

3. **Enable caching:**
   Ensure Redis is configured:
   ```yaml
   redis:
     url: "redis://localhost:6379/0"
   ```

4. **Reduce concurrent requests:**
   ```yaml
   outgoing:
     pool_connections: 50
     pool_maxsize: 25
   ```

---

### Issue 10: Permission Denied Errors

**Symptoms:**
```
PermissionError: [Errno 13] Permission denied
```

**Solutions:**

1. **Fix ownership:**
   ```bash
   sudo chown -R searxng:searxng /usr/local/searxng
   sudo chown -R searxng:searxng /etc/searxng
   ```

2. **Fix permissions:**
   ```bash
   sudo chmod 755 /usr/local/searxng
   sudo chmod 644 /etc/searxng/settings.yml
   ```

3. **Restart:**
   ```bash
   sudo systemctl restart searxng
   ```

---

## 🆘 **GETTING MORE HELP**

### Check Logs

```bash
# SearXNG logs
sudo journalctl -u searxng -n 100 --no-pager

# Redis logs
sudo journalctl -u redis-server -n 50

# OpenClaw logs
journalctl --user -u openclaw-gateway.service -n 50
```

### Run Diagnostics

```bash
# Full test suite
bash scripts/test-setup.sh

# Check configuration
python3 -c "import yaml; yaml.safe_load(open('/etc/searxng/settings.yml'))"

# Check Redis
redis-cli ping

# Check API
curl "http://localhost:8080/search?q=test&format=json" | jq '.'
```

### Get Support

- 📖 Read **[FAQ.md](FAQ.md)**
- 💬 Ask in **[GitHub Discussions](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/discussions)**
- 🐛 Report issues: **[GitHub Issues](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/issues)**

---

## 📊 **ERROR CODES**

| Error | Meaning | Solution |
|-------|---------|----------|
| `503 Service Unavailable` | SearXNG not running | `sudo systemctl start searxng` |
| `504 Gateway Timeout` | Engine timeout | Increase timeout in settings |
| `429 Too Many Requests` | Rate limited | Disable limiter in settings |
| `Connection refused` | Redis not running | `sudo systemctl start redis-server` |
| `Address already in use` | Port conflict | Change port or kill process |

---

**Last Updated:** 2026-02-24  
**Difficulty:** Intermediate
