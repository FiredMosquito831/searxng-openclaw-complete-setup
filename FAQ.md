# Frequently Asked Questions

Common questions about SearXNG + OpenClaw. For installation details see
[INSTALL.md](INSTALL.md); for failures see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## General

### What is SearXNG?

SearXNG is a free, open-source metasearch engine. It sends a query to the search
engines you enable, then combines their results into one list. It does not require a
commercial search API key and does not build a user profile.

### What does this repository add?

It installs SearXNG on Ubuntu/Debian, enables the JSON API, configures Redis, creates
a systemd service, and supplies scripts and configuration for using SearXNG from
OpenClaw. It does not package SearXNG or OpenClaw.

### Why use SearXNG with OpenClaw?

1. No per-query API bill and no API key.
2. Results can come from many engines instead of one vendor.
3. The instance is local; searches go from your server to the engines, not through a
   commercial search API.
4. You control which engines are enabled and how long results are cached.

### Is this legal?

SearXNG is open-source software. It queries publicly reachable search engines on your
behalf. You are responsible for complying with each upstream engine's terms and with
local law. Running a heavily used public instance is a different situation from a
single-user local instance.

### Do I need technical skills?

You need to run a few commands with `sudo`. The automated installer handles the
steps; the manual guide explains each one. Basic Linux familiarity helps when
debugging.

### How many search engines are included?

SearXNG ships with 70+ built-in engines. The installer enables seven: Google,
DuckDuckGo, Brave, Bing, Wikipedia, GitHub, and YouTube. Add more in
`/etc/searxng/settings.yml`.

### What OpenClaw version is this for?

The scripts and config were tested with OpenClaw 2026.2.23 and the
`searxng-search` plugin. Newer OpenClaw releases also include a built-in SearXNG
provider with different configuration keys. See
[CONFIGURATION.md](CONFIGURATION.md#built-in-searxng-provider-newer-openclaw).

### Does this repository include the OpenClaw plugin?

No. It configures an existing plugin/provider. `configure-openclaw.sh` writes the
`searxng-search` block; the plugin itself must be installed in OpenClaw. The built-in
provider in newer OpenClaw releases is installed with
`openclaw plugins install @openclaw/searxng-plugin`.

### Is this affiliated with SearXNG or OpenClaw?

No. It is an independent setup repository. SearXNG and OpenClaw have their own
licenses, maintainers, and trademarks.

---

## Cost

### Is this really free?

The software is MIT-licensed and SearXNG has no license fee. There is no search API
subscription and no per-query charge. You pay for the machine, electricity, and
bandwidth you already use.

### What are the ongoing costs?

Nothing beyond hosting. A small VPS or an existing home server is enough. Running the
instance on hardware you already own has no additional service fee.

### How much does it save compared with search APIs?

It avoids metered search API fees entirely. Commercial search API prices and free
tiers change, so this repository does not quote a fixed saving. Compare current
vendor pricing with your actual query volume.

### Are there hidden limits?

Yes, but not billing limits. Upstream engines can rate-limit or block your server,
and SearXNG reports those engines in `unresponsive_engines`. Results also depend on
which engines you enable. "Unlimited" means no API key quota from this stack, not a
guarantee that every upstream engine answers every query.

---

## Installation

### How long does installation take?

About 15–30 minutes on a small VPS. Most of the time is `apt` and `pip` downloads
and the editable SearXNG install.

### What operating systems are supported?

- Ubuntu 20.04+
- Debian 11+
- WSL2 with an Ubuntu distribution

The installer checks `/etc/os-release` and refuses other distributions. Fedora, RHEL,
Arch, and macOS are not supported by the scripts.

### Can I install on Windows or macOS?

- **Windows:** use WSL2 with Ubuntu.
- **macOS:** not supported by these scripts. You can install SearXNG manually, but
  this repository's service unit and package steps are Linux-specific.
- **Docker:** not implemented in this repository. The scripts use apt, a system user,
  and systemd.

### Do I need a separate server?

No. It runs on your existing Linux machine. Minimum: 512 MB RAM and 1 GB free disk.
Recommended: 2 GB RAM and 5 GB free disk. A desktop used for other work is fine for a
single user.

### Can I run it on a Raspberry Pi?

Probably, with a 64-bit Raspberry Pi OS or Ubuntu install and at least 2 GB of RAM,
but this repository has not tested it. The installer requires a Debian/Ubuntu
`/etc/os-release`, so Raspberry Pi OS may be rejected even though it is
Debian-derived.

### Do I have to configure OpenClaw manually?

You have to run `bash scripts/configure-openclaw.sh` as your OpenClaw user. The
installer does not modify `~/.openclaw/openclaw.json`. If you skip it, SearXNG works
standalone but OpenClaw will not know about it.

### Can I rerun the installer?

Yes. It preserves an existing `/etc/searxng/settings.yml` and writes a timestamped
backup next to it. It also detects an existing `searxng` user, source checkout, and
virtual environment.

---

## Privacy and security

### Is my search history private?

SearXNG does not log queries, create accounts, or build profiles by default. It
temporarily caches results in local Redis. Your upstream requests still come from
your server's IP address, so the engines can see that IP. SearXNG is not an
anonymity network such as Tor.

### Is it secure?

For a single-user loopback deployment, the default posture is reasonable: SearXNG
binds to `127.0.0.1`, Redis is local, no API keys are stored, and the systemd unit
uses `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome`, and `PrivateTmp`.
There is no authentication or TLS because the service is not exposed.

### Can others on my network use it?

Not by default. It listens only on loopback. To share it, change the bind address
and add firewall rules, authentication, and TLS. Read [SECURITY.md](SECURITY.md)
first; the bundled configuration is not hardened for multi-user exposure.

### Does SearXNG store my data?

It does not store queries or user profiles. Redis caches results temporarily. Logs
are handled by systemd/journald and may contain service errors. Search engine
responses are not retained as a history.

### What about prompt injection from search results?

OpenClaw treats web search results as untrusted external content. It wraps them in
`<<<EXTERNAL_UNTRUSTED_CONTENT ...>>>` boundary markers and strips chat-template
special tokens before they reach the model. This reduces one class of attack but does
not replace tool allowlists, exec approvals, sandboxing, or channel policy. See
[SECURITY.md](SECURITY.md) and the
[OpenClaw prompt-injection guide](https://docs.openclaw.ai/gateway/security/prompt-injection).

### Is the SearXNG port exposed to the internet?

No, the installed configuration binds to `127.0.0.1:8080`. If you deliberately
change that, you own the TLS, authentication, rate limiting, and patching work.

---

## Usage

### How do I search?

Three ways:

1. Web interface: `http://127.0.0.1:8080`
2. OpenClaw: ask the agent to search, for example "Search for Python tutorials using
   SearXNG"
3. JSON API: `curl "http://127.0.0.1:8080/search?q=python&format=json"`

### How many results can I get?

A single SearXNG page usually returns a few dozen results, depending on engines and
upstream rate limits. Pagination is available with `pageno=2`, `pageno=3`, and so on.
The `searxng-search` plugin template requests 100 results and enables multi-page
retrieval. OpenClaw's built-in provider caps a single call's `count` at 10.

### Can I search specific categories?

Yes. SearXNG categories include `general`, `images`, `videos`, `news`, `it`, and
`science`. Example:

```text
Search for Python with categories: it,science
```

or directly:

```bash
curl -s "http://127.0.0.1:8080/search?q=python&categories=it,science&format=json"
```

### Can I restrict results by time?

Yes, with the `time_range` parameter where an engine supports it:

```bash
curl -s "http://127.0.0.1:8080/search?q=climate&time_range=month&format=json"
```

### Which engines are enabled?

Google, DuckDuckGo, Brave, Bing, Wikipedia, GitHub, and YouTube. The configuration
template adds Google News and DuckDuckGo News. More engines are available in
SearXNG's engine list.

### Why do I get different result counts on different days?

Upstream engines rate-limit, change their HTML, or temporarily fail. SearXNG reports
failed engines in `unresponsive_engines`. Cached results also affect timing. This is
normal for a metasearch instance.

---

## Maintenance

### How do I update SearXNG?

```bash
sudo bash scripts/update-searxng.sh
```

The script creates a backup, pulls the current branch of the SearXNG checkout
(`master` upstream, or whatever is checked out), reinstalls the editable package,
restarts the service, and checks the API.

Manual update:

```bash
sudo -u searxng -i
cd /usr/local/searxng/searxng-src
git pull --ff-only
exit
sudo systemctl restart searxng
```

### How often should I update?

Monthly is a reasonable cadence. SearXNG frequently fixes engine scrapers and ships
security patches. Update sooner if a specific engine stops working.

### How do I back up my configuration?

```bash
bash scripts/backup-searxng.sh
```

The archive goes to `~/searxng-backups/` and contains `settings.yml`, the systemd
unit, `openclaw.json` if present, and a generated `restore.sh`.

### How do I restore a backup?

```bash
cd ~/searxng-backups
tar -xzf searxng-backup-YYYYMMDD-HHMMSS.tar.gz
cd YYYYMMDD-HHMMSS
bash restore.sh
```

Run `restore.sh` as your user, not with `sudo`; it calls `sudo` for system files.

### What if something breaks?

1. Run `bash scripts/test-setup.sh`.
2. Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
3. Check `sudo journalctl -u searxng -n 100 --no-pager`.
4. Open an issue at
   [github.com/FiredMosquito831/searxng-openclaw-complete-setup/issues](https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/issues).

---

## Comparison

### SearXNG vs a commercial search API

| | SearXNG (this setup) | Commercial search API |
| --- | --- | --- |
| Cost | No search API fee | Metered or subscription |
| Key | None | Required |
| Sources | Multiple engines you choose | One vendor index |
| Quota | No vendor quota; upstream engines may rate-limit | Vendor-defined quota |
| Setup | 15–30 minutes on your host | Usually minutes |
| Operations | You patch and monitor it | Vendor operates it |
| Privacy | Queries go from your host to engines | Queries go to the vendor |

### Why not use DuckDuckGo directly?

SearXNG can query DuckDuckGo plus the other engines you enable, and it gives you one
JSON response. It also gives you control over categories, engines, and caching. It
does not make you anonymous to DuckDuckGo.

### Is the result quality as good as Google?

Sometimes, sometimes not. SearXNG aggregates whatever the enabled engines return.
Google's own ranking is not reproduced exactly, and engines can return different
result sets to a server IP than to a browser. For specialist or high-stakes queries,
compare results across engines.

---

## Contributing

### How can I contribute?

Report bugs, improve docs, test on another distribution, or send pull requests. See
[CONTRIBUTING.md](CONTRIBUTING.md). Tested compatibility reports are especially
useful.

### Can I sell or modify this?

Yes. The MIT License permits commercial use and modification, provided the copyright
and permission notice are included. SearXNG and OpenClaw have their own licenses.

---

## Still have questions?

- [Documentation site](https://searxng.danubelabs.net)
- [GitHub Issues](https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/issues)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Last updated:** 2026-10-22
