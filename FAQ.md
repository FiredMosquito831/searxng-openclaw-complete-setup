# ❓ Frequently Asked Questions

**Common questions about SearXNG + OpenClaw**

---

## 📖 **GENERAL QUESTIONS**

### Q: What is SearXNG?

**A:** SearXNG is a free, open-source, privacy-respecting metasearch engine. It searches 70+ search engines simultaneously and combines results into one unified list. Unlike Google or Bing, it doesn't track you or log your searches.

---

### Q: Why use SearXNG with OpenClaw?

**A:** Three main reasons:

1. **Unlimited searches** - No API rate limits or quotas
2. **$0 cost** - Save $3-10/month on API fees
3. **Privacy** - Your searches stay private

---

### Q: Is this legal?

**A:** Yes! SearXNG is completely legal. It's just a tool that searches public search engines on your behalf, similar to how you would search them manually.

---

### Q: Do I need technical skills?

**A:** Basic Linux command line knowledge helps, but our automated installer makes it easy. If you can copy/paste commands, you can install this!

---

## 💰 **COST QUESTIONS**

### Q: Is this really free?

**A:** Yes! 100% free. No hidden costs, no subscriptions, no API fees.

---

### Q: What are the ongoing costs?

**A:** $0/month. You only pay for:
- Your internet connection
- Electricity to run your server (minimal)

---

### Q: How much do I save vs API services?

**A:** Typical API costs:
- Brave Search API: $3-10/month
- Google Custom Search: $5-20/month
- Bing Search API: $15-50/month

**You save:** $36-600/year!

---

## 🔧 **INSTALLATION QUESTIONS**

### Q: How long does installation take?

**A:** 
- Automated install: 20 minutes
- Manual install: 30 minutes
- Verification: 5 minutes

---

### Q: What OS is supported?

**A:** 
- ✅ Ubuntu 20.04+
- ✅ Ubuntu 22.04+ (recommended)
- ✅ Debian 11+
- ✅ WSL2 (Windows Subsystem for Linux)

---

### Q: Can I install on Windows/Mac?

**A:** 
- **Windows:** Use WSL2 (Windows Subsystem for Linux)
- **Mac:** Not officially supported, but possible with Homebrew
- **Docker:** Coming soon (will work on any OS)

---

### Q: Do I need a separate server?

**A:** No! It runs on your existing machine. Requirements:
- 512MB RAM (minimum)
- 2GB RAM (recommended)
- 1GB disk space (minimum)
- 5GB disk space (recommended)

---

## 🔒 **PRIVACY & SECURITY**

### Q: Is my search history private?

**A:** Yes! SearXNG:
- Doesn't log your searches
- Doesn't track you
- Doesn't share data with third parties
- Runs on your own hardware

---

### Q: Is it secure?

**A:** Yes! By default:
- Binds to localhost only (not exposed to internet)
- No external access unless you configure it
- Uses HTTPS for outgoing requests
- Redis cache is local-only

---

### Q: Can others on my network use it?

**A:** By default, no. It only accepts connections from localhost (your machine). To share on your LAN, you need to configure it (see SECURITY.md).

---

### Q: Does SearXNG store my data?

**A:** No. SearXNG:
- Doesn't store search queries
- Doesn't store IP addresses
- Doesn't create user profiles
- Only caches results temporarily in Redis

---

## 🚀 **USAGE QUESTIONS**

### Q: How do I search?

**A:** Three ways:

1. **Web interface:** http://localhost:8080
2. **OpenClaw:** "Search for X using SearXNG"
3. **Direct API:** `curl "http://localhost:8080/search?q=X&format=json"`

---

### Q: How many results can I get?

**A:** 
- Per page: 20-40 results
- Maximum pages: 10
- **Total:** 200-400 results per query

---

### Q: Can I search specific categories?

**A:** Yes! Categories include:
- `general` - General web search
- `images` - Image search
- `videos` - Video search
- `news` - News search
- `it` - IT/tech search
- `science` - Scientific search

Example:
```
Search for Python with categories: it,science
```

---

### Q: Which search engines are included?

**A:** 70+ engines including:
- Google
- DuckDuckGo
- Brave
- Bing
- Wikipedia
- GitHub
- YouTube
- And 64 more!

---

## 🔧 **MAINTENANCE QUESTIONS**

### Q: How do I update SearXNG?

**A:** 
```bash
bash scripts/update-searxng.sh
```

Or manually:
```bash
sudo -u searxng -i
cd /usr/local/searxng/searxng-src
git pull
exit
sudo systemctl restart searxng
```

---

### Q: How often should I update?

**A:** Once a month is sufficient. Updates include:
- Engine fixes
- Security patches
- New features

---

### Q: How do I backup my configuration?

**A:** 
```bash
bash scripts/backup-searxng.sh
```

Or manually:
```bash
sudo cp /etc/searxng/settings.yml ~/searxng-backup.yml
```

---

### Q: What if something breaks?

**A:** 
1. Check **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
2. Run diagnostics: `bash scripts/test-setup.sh`
3. Check logs: `sudo journalctl -u searxng -f`
4. Ask for help: **[GitHub Discussions](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/discussions)**

---

## 🆚 **COMPARISON QUESTIONS**

### Q: SearXNG vs Brave Search API?

| Feature | SearXNG | Brave API |
|---------|---------|-----------|
| Cost | $0 | $3-10/month |
| Limit | Unlimited | 2,000/month |
| Engines | 70+ | 1 |
| Privacy | ✅ Yes | ❌ Tracked |
| Setup | 20 min | 5 min |

**Winner:** SearXNG for heavy users, Brave API for light users

---

### Q: SearXNG vs Google Custom Search?

| Feature | SearXNG | Google API |
|---------|---------|------------|
| Cost | $0 | $5-20/month |
| Limit | Unlimited | 100/day |
| Privacy | ✅ Yes | ❌ Tracked |
| Quality | Good | Excellent |

**Winner:** SearXNG for privacy, Google for quality

---

### Q: Why not just use DuckDuckGo directly?

**A:** SearXNG searches DuckDuckGo PLUS 69+ other engines. You get:
- More comprehensive results
- No tracking (even DuckDuckGo tracks somewhat)
- Customizable
- Self-hosted control

---

## 🐛 **TROUBLESHOOTING QUESTIONS**

### Q: Why am I getting 0 results?

**A:** Common causes:
1. Engines disabled - Check `/etc/searxng/settings.yml`
2. Network issues - Check internet connection
3. Redis not running - `sudo systemctl start redis-server`

See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for detailed solutions.

---

### Q: Why is search slow?

**A:** Common causes:
1. Too many engines enabled
2. Slow network
3. Low server resources

**Solutions:**
- Disable slow engines
- Increase timeout in settings
- Add more RAM/CPU

---

### Q: Why does OpenClaw say "plugin not found"?

**A:** Check:
1. Plugin enabled in `~/.openclaw/openclaw.json`
2. SearXNG running on `http://localhost:8080`
3. Restart OpenClaw: `systemctl --user restart openclaw-gateway.service`

---

## 📊 **PERFORMANCE QUESTIONS**

### Q: How fast is search?

**A:** Typical latency:
- Fast engines (Google, DDG): 1-2 seconds
- Medium engines (GitHub, Wikipedia): 2-4 seconds
- Slow engines (news, academic): 4-8 seconds

**Average:** 2-5 seconds for full results

---

### Q: How much RAM does it use?

**A:** 
- Idle: 200-300MB
- During search: 400-600MB
- Peak: 800MB-1GB

---

### Q: Can I use it on a Raspberry Pi?

**A:** Yes! Works great on:
- Raspberry Pi 4 (4GB recommended)
- Raspberry Pi 3 (may be slow)

---

## 🤝 **CONTRIBUTION QUESTIONS**

### Q: How can I contribute?

**A:** Many ways to help:
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository
- 💬 Help others in discussions

See **[CONTRIBUTING.md](.github/CONTRIBUTING.md)** for details.

---

### Q: Can I sell this?

**A:** Yes! MIT License allows commercial use. Just include the license and copyright notice.

---

### Q: Can I modify it?

**A:** Yes! MIT License allows modifications. Just document your changes.

---

## 📚 **LEARNING QUESTIONS**

### Q: Where can I learn more?

**A:** Resources:
- **[SearXNG Documentation](https://docs.searxng.org/)**
- **[OpenClaw Documentation](https://docs.openclaw.ai/)**
- **[GitHub Repository](https://github.com/YOUR_USERNAME/searxng-openclaw-complete)**
- **[Community Discussions](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/discussions)**

---

### Q: Are there video tutorials?

**A:** Coming soon! Check our **[YouTube channel](LINK_HERE)** for video tutorials.

---

## 🎯 **STILL HAVE QUESTIONS?**

- 💬 Ask in **[GitHub Discussions](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/discussions)**
- 📖 Read **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
- 🐛 Report issues: **[GitHub Issues](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/issues)**

---

**Last Updated:** 2026-02-24  
**Questions Answered:** 30+
