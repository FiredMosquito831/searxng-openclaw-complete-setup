# SearXNG + OpenClaw Complete Setup

[![License: MIT](https://img.shields.io/badge/license-MIT-4ee1c1.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?logo=ubuntu&logoColor=white)](INSTALL.md)
[![Debian](https://img.shields.io/badge/Debian-11%2B-A81D33?logo=debian&logoColor=white)](INSTALL.md)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.2.23%20tested-6cb6ff)](https://openclaw.ai)
[![Docs](https://img.shields.io/badge/docs-searxng.danubelabs.net-4ee1c1)](https://searxng.danubelabs.net)
[![Site build](https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/actions/workflows/site.yml/badge.svg)](https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/actions/workflows/site.yml)

**Documentation site: [searxng.danubelabs.net](https://searxng.danubelabs.net)**

Self-hosted, privacy-respecting web search for OpenClaw. This repository installs a
local SearXNG instance, enables its JSON API, connects it to Redis for caching, and
provides the configuration and scripts needed to use it as an OpenClaw search
provider — without a commercial search API key.

SearXNG ships with 70+ built-in engines. The installer enables seven of them
(Google, DuckDuckGo, Brave, Bing, Wikipedia, GitHub, YouTube); you can enable more
in `settings.yml`. SearXNG's `pageno` parameter supports multi-page result retrieval.

---

## Quick start

Requirements: Ubuntu 20.04+ or Debian 11+, `sudo`, and an OpenClaw installation if
you want the agent integration. Windows users can run this inside WSL2 with an
Ubuntu distribution.

```bash
# 1. Clone
git clone https://github.com/FiredMosquito831/searxng-openclaw-complete-setup.git
cd searxng-openclaw-complete-setup

# 2. Install SearXNG, Redis, and the systemd unit
sudo bash scripts/install-all.sh

# 3. Configure the OpenClaw plugin (run as your OpenClaw user, without sudo)
bash scripts/configure-openclaw.sh

# 4. Verify
bash scripts/test-setup.sh
```

The installer does **not** configure OpenClaw. Step 3 does. If OpenClaw is not
installed, SearXNG still works at `http://127.0.0.1:8080` and the test suite marks
the OpenClaw checks as warnings.

### OpenClaw plugin compatibility

`configure-openclaw.sh` writes a `plugins.entries["searxng-search"]` block, which is
the configuration used by the plugin this project was built around (OpenClaw
2026.2.x). Newer OpenClaw releases also ship SearXNG as a built-in provider with a
different config shape (`tools.web.search.provider` and
`plugins.entries.searxng.config.webSearch.baseUrl`). See
[Configuration](https://searxng.danubelabs.net/configuration/) for both forms and
check `openclaw doctor` after changing provider settings.

---

## What you get

| Piece | Detail |
| --- | --- |
| SearXNG | Local instance on `127.0.0.1:8080`, HTML UI and `format=json` API |
| Redis | Local cache at `redis://localhost:6379/0` |
| systemd unit | `searxng.service`, starts on boot and restarts on failure |
| OpenClaw config | Backs up `openclaw.json`, adds the search plugin, validates and restarts the gateway |
| Multi-page search | Native SearXNG `pageno` support; the plugin template requests 100 results |
| Scripts | Install, configure, test, update, backup, restore helper, uninstall |
| Documentation | Install, configuration, usage, maintenance, security, troubleshooting, FAQ |

---

## Architecture

```text
Telegram / CLI / other channel
              |
              v
     OpenClaw gateway
              |
              v
   searxng-search plugin
              |
              |  HTTP + JSON over loopback
              v
   SearXNG  127.0.0.1:8080  <---->  Redis 127.0.0.1:6379
              |
              +--> Google
              +--> DuckDuckGo
              +--> Brave
              +--> Bing
              +--> Wikipedia
              +--> GitHub
              +--> YouTube
```

SearXNG is bound to loopback only. It is not a public search engine, and there is no
authentication or TLS in front of it by default (see [Security](#security)).

---

## Verify the installation

```bash
# Service state
sudo systemctl status searxng
redis-cli ping

# JSON API (expects a positive result count; engines can be rate-limited)
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.results | length'

# Which upstream engines did not answer
curl -s "http://127.0.0.1:8080/search?q=test&format=json" | jq '.unresponsive_engines'

# OpenClaw plugin visibility
openclaw doctor 2>&1 | grep -i searxng

# Full test suite
bash scripts/test-setup.sh
```

The test suite treats a missing OpenClaw installation or an undetected plugin as a
warning, not a failure, so you can validate a standalone SearXNG deployment.

---

## Usage

Ask your OpenClaw agent in natural language:

```text
Search for Rust async programming using SearXNG
Search for AI policy news with time_range: month
Search for Python packaging with categories: it,science
```

Query the API directly:

```bash
# Basic JSON search
curl -s "http://127.0.0.1:8080/search?q=python&format=json" | jq '.results[] | {title, url}'

# Page 2
curl -s "http://127.0.0.1:8080/search?q=python&format=json&pageno=2" | jq '.results | length'

# Category filter
curl -s "http://127.0.0.1:8080/search?q=rust&categories=it&format=json" | jq '.results | length'
```

Result counts depend on which engines answer and whether upstream engines rate-limit
your server. Multi-page retrieval is a SearXNG API feature; the bundled plugin
template enables it. OpenClaw's built-in provider caps a single `count` argument at
10 results and exposes `pageno` only through the SearXNG API, not through a
multi-page plugin option.

---

## Documentation

| Document | Contents |
| --- | --- |
| [Documentation site](https://searxng.danubelabs.net) | Install, configuration, usage, maintenance, security, troubleshooting, FAQ |
| [INSTALL.md](INSTALL.md) | Automated and manual installation, step by step |
| [CONFIGURATION.md](CONFIGURATION.md) | SearXNG settings, engines, Redis, OpenClaw config, tuning |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common failures and fixes |
| [FAQ.md](FAQ.md) | 30+ questions about cost, privacy, installation, and limits |
| [SECURITY.md](SECURITY.md) | Threat model, prompt-injection boundaries, hardening |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development, site build, and PR workflow |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [REPOSITORY_SUMMARY.md](REPOSITORY_SUMMARY.md) | File map, data flow, and script reference |
| [FINAL_100_PERCENT_COMPLETE.md](FINAL_100_PERCENT_COMPLETE.md) | Verified scope and explicit non-goals |

---

## Requirements

| Requirement | Minimum | Recommended |
| --- | --- | --- |
| OS | Ubuntu 20.04 / Debian 11 | Ubuntu 22.04+ |
| RAM | 512 MB | 2 GB |
| Disk | 1 GB | 5 GB |
| CPU | 1 core | 2+ cores |
| Network | Outbound HTTPS to search engines | Broadband |
| Access | `sudo` | — |
| Agent | OpenClaw (optional for standalone SearXNG) | OpenClaw with a SearXNG plugin |

The installer refuses to run on distributions other than Ubuntu and Debian. It has
been tested on Ubuntu 22.04 under WSL2 with OpenClaw 2026.2.23. Other Debian-derived
systems may work but are not covered by the scripts.

---

## Security

- SearXNG binds to `127.0.0.1` and Redis binds to loopback. Do not expose either port
  to the internet without adding TLS, authentication, and rate limiting.
- No commercial search API keys are used or stored. The SearXNG `secret_key` is
  generated with `openssl rand -hex 32`.
- OpenClaw treats web search results as untrusted external content. It wraps results
  in `<<<EXTERNAL_UNTRUSTED_CONTENT ...>>>` boundary markers and strips chat-template
  special tokens before the model sees them. That protection does not replace
  allowlists, exec approvals, sandboxing, or channel policy; see
  [SECURITY.md](SECURITY.md) and the
  [OpenClaw prompt-injection guide](https://docs.openclaw.ai/gateway/security/prompt-injection).
- Upstream engines still see requests from your server's IP address. SearXNG does not
  log queries or create profiles, but it is not an anonymity network.
- The scripts are designed for a single-user local deployment. Read them before
  running them on a shared host.

For vulnerability reporting, see [SECURITY.md](SECURITY.md).

---

## Maintenance

```bash
# Update SearXNG from its current branch (creates a backup first)
sudo bash scripts/update-searxng.sh

# Back up /etc/searxng, the systemd unit, and openclaw.json
bash scripts/backup-searxng.sh

# Logs
sudo journalctl -u searxng -f
journalctl --user -u openclaw-gateway.service -f

# Restart after a config change
sudo systemctl restart searxng
systemctl --user restart openclaw-gateway.service

# Remove everything (interactive)
sudo bash scripts/uninstall.sh
```

Backups are written to `~/searxng-backups/` as timestamped `.tar.gz` archives with
an embedded `restore.sh`.

---

## Scope and non-goals

This repository is deliberately a local, scripted deployment. The following are
**not** implemented and are not advertised as available:

- Docker Compose or container deployment.
- A reverse proxy, TLS termination, or authentication for SearXNG.
- Hardening for a public or multi-tenant SearXNG instance.
- A packaged OpenClaw plugin; the repo configures an existing plugin/provider.
- A benchmark suite. No latency, memory, or result-count guarantee is made beyond
  the requirements table.
- Fedora, RHEL, Arch, or macOS installers. The scripts reject non-Ubuntu/Debian
  distributions.

See [FINAL_100_PERCENT_COMPLETE.md](FINAL_100_PERCENT_COMPLETE.md) for the verified
scope.

---

## Contributing

Bug reports, documentation fixes, and tested compatibility reports are welcome. Open
an issue or a pull request; see [CONTRIBUTING.md](CONTRIBUTING.md). The docs site is
generated from `site/` with `scripts/build_site.py` and validated in CI with
`python scripts/build_site.py --check`.

## License

[MIT](LICENSE) © 2026 FiredMosquito831

SearXNG and OpenClaw are separate projects with their own licenses and trademarks.
This repository is not affiliated with either project.

**Version:** 1.1.0 · **Docs site updated:** 2026-10-22
