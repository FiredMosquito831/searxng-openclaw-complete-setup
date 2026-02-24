# 🔍 SearXNG + OpenClaw Complete Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange)](https://ubuntu.com)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.2.23%2B-green)](https://openclaw.ai)
[![Stars](https://img.shields.io/github/stars/YOUR_USERNAME/searxng-openclaw-complete)](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/stargazers)

> **Unlimited, privacy-respecting search for OpenClaw with 70+ search engines. Zero API costs. One-command installation.**

---

## ⚡ Quick Start (5 Minutes)

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/searxng-openclaw-complete
cd searxng-openclaw-complete

# Run automated installer
sudo bash scripts/install-all.sh

# Test installation
bash scripts/test-setup.sh
```

**That's it!** You now have unlimited search in OpenClaw.

---

## ✨ Features

| Feature | Benefit |
|---------|---------|
| 🚀 **Unlimited Searches** | No API rate limits or quotas |
| 💰 **$0 Monthly Cost** | Save $3-10/month on API fees |
| 🔒 **Complete Privacy** | No tracking, no logging |
| 🌐 **70+ Search Engines** | Google, DuckDuckGo, Brave, Bing, Wikipedia, GitHub, YouTube & more |
| 📄 **Multi-Page Search** | Get 100-300+ results per query |
| ⚙️ **Auto-Start** | Runs automatically on boot |
| 🛠️ **Easy Maintenance** | Automated update scripts |

---

## 🎯 What You Get

```
✅ Local SearXNG instance (http://localhost:8080)
✅ Redis cache for performance
✅ OpenClaw searxng-search plugin configured
✅ Multi-page search (100-300+ results)
✅ Systemd services (auto-start on boot)
✅ Monitoring & backup scripts
✅ Complete documentation
✅ $0/month search costs
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| **[INSTALL.md](INSTALL.md)** | Detailed installation guide |
| **[CONFIGURATION.md](CONFIGURATION.md)** | Configuration options & tuning |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues & solutions |
| **[FAQ.md](FAQ.md)** | Frequently asked questions |
| **[PERFORMANCE.md](docs/PERFORMANCE.md)** | Performance optimization |
| **[SECURITY.md](docs/SECURITY.md)** | Security hardening |

---

## 🚀 Installation Methods

### Method 1: Automated (Recommended)

```bash
git clone https://github.com/YOUR_USERNAME/searxng-openclaw-complete
cd searxng-openclaw-complete
sudo bash scripts/install-all.sh
```

### Method 2: Manual

See **[INSTALL.md](INSTALL.md)** for step-by-step manual installation.

### Method 3: Docker (Coming Soon)

```bash
docker-compose up -d
```

---

## ✅ Verify Installation

```bash
# Run test suite
bash scripts/test-setup.sh

# Test SearXNG
curl "http://localhost:8080/search?q=test&format=json" | jq '.results | length'

# Test OpenClaw integration
openclaw doctor 2>&1 | grep searxng

# Check services
sudo systemctl status searxng
systemctl --user status openclaw-gateway.service
```

**Expected:** All checks pass ✅

---

## 🎯 Usage Examples

### Basic Search (via Telegram)

Send to your OpenClaw bot:
```
Search for Python tutorials using SearXNG
```

### Multi-Page Search (100+ Results)

```
Search for AI developments with 100 results
Search for coding tutorials with 5 pages
```

### Advanced Search

```
Search for Rust programming with categories: it,science
Search for climate change news with time_range: month
```

---

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| **Search Latency** | 2-5 seconds |
| **Results per Page** | 20-40 |
| **Max Pages** | 10 (200-400 results) |
| **Memory Usage** | 200-500MB |
| **Disk Usage** | 1-2GB |
| **CPU Usage** | 10-30% (during search) |

---

## 🆚 Comparison

| Feature | Brave API | Google API | **SearXNG (This)** |
|---------|-----------|------------|-------------------|
| **Monthly Cost** | $3-10 | $5-20 | **$0** |
| **Search Limit** | 2,000/mo | 100/day | **UNLIMITED** |
| **Engines** | 1 | 1 | **70+** |
| **Privacy** | ❌ Tracked | ❌ Tracked | **✅ Private** |
| **Setup Time** | 5 min | 10 min | **20 min** |
| **Maintenance** | None | None | **Low** |

---

## 🛠️ Maintenance

### Update SearXNG

```bash
bash scripts/update-searxng.sh
```

### Backup Configuration

```bash
bash scripts/backup-searxng.sh
```

### Check Status

```bash
bash scripts/check-status.sh
```

### View Logs

```bash
# SearXNG logs
sudo journalctl -u searxng -f

# OpenClaw logs
journalctl --user -u openclaw-gateway.service -f
```

---

## 🤝 Contributing

Contributions are welcome! Please see:
- **[CONTRIBUTING.md](.github/CONTRIBUTING.md)** - How to contribute
- **[CODE_OF_CONDUCT.md](.github/CODE_OF_CONDUCT.md)** - Community guidelines

### Ways to Contribute:
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star this repository

---

## 📋 Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Ubuntu 20.04 | Ubuntu 22.04+ |
| **RAM** | 512MB | 2GB |
| **Disk** | 1GB | 5GB |
| **CPU** | 1 core | 2+ cores |
| **Network** | Required | Broadband |

---

## 🆘 Support

### Get Help

- 📖 Read **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
- 💬 Ask in **[GitHub Discussions](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/discussions)**
- 🐛 Report issues: **[GitHub Issues](https://github.com/YOUR_USERNAME/searxng-openclaw-complete/issues)**

### Common Commands

```bash
# Restart SearXNG
sudo systemctl restart searxng

# Restart OpenClaw
systemctl --user restart openclaw-gateway.service

# Test API
curl "http://localhost:8080/search?q=test&format=json" | jq '.'

# Check logs
sudo journalctl -u searxng -n 50
```

---

## 📄 License

This project is licensed under the **[MIT License](LICENSE)**.

```
Copyright (c) 2026 YOUR_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files...
```

---

## 🙏 Acknowledgments

- **[SearXNG](https://github.com/searxng/searxng)** - Privacy-respecting metasearch engine
- **[OpenClaw](https://openclaw.ai)** - Open-source AI assistant framework
- **[Redis](https://redis.io)** - In-memory data store

---

## 📊 Repository Stats

![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/searxng-openclaw-complete?style=social)
![GitHub forks](https://img.shields.io/github/forks/YOUR_USERNAME/searxng-openclaw-complete?style=social)
![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/searxng-openclaw-complete)
![GitHub pull requests](https://img.shields.io/github/issues-pr/YOUR_USERNAME/searxng-openclaw-complete)
![License](https://img.shields.io/github/license/YOUR_USERNAME/searxng-openclaw-complete)

---

## 🚀 Quick Links

- **[Installation Guide](INSTALL.md)** - Get started in 20 minutes
- **[Configuration](CONFIGURATION.md)** - Optimize your setup
- **[Troubleshooting](TROUBLESHOOTING.md)** - Fix common issues
- **[FAQ](FAQ.md)** - Common questions answered

---

**Made with ❤️ for the privacy-conscious community**

**Last Updated:** 2026-02-24  
**Version:** 1.0.0  
**Tested On:** Ubuntu 22.04 (WSL2), OpenClaw 2026.2.23
