# Repository Summary

A technical map of the repository: what each file does, how the pieces fit together,
and where to change behavior.

---

## Purpose

Provide a reproducible, local SearXNG deployment for OpenClaw on Ubuntu/Debian:

- SearXNG bound to loopback with the JSON API enabled.
- Redis for caching.
- A systemd unit with restart and sandboxing directives.
- Scripts for install, configuration, testing, update, backup, and uninstall.
- Documentation plus a generated static site.

The repository does not vendor SearXNG or OpenClaw, and it does not ship the OpenClaw
plugin package.

---

## File map

```text
.
├── README.md                        Project overview and quick start
├── INSTALL.md                       Automated and manual installation
├── CONFIGURATION.md                 SearXNG, Redis, and OpenClaw configuration
├── TROUBLESHOOTING.md               Failure modes and fixes
├── FAQ.md                           Cost, privacy, usage, and compatibility questions
├── SECURITY.md                      Threat model and reporting
├── CONTRIBUTING.md                  Development and contribution workflow
├── CHANGELOG.md                     Version history
├── REPOSITORY_SUMMARY.md            This file
├── FINAL_100_PERCENT_COMPLETE.md    Verified scope and non-goals
├── LICENSE                          MIT
├── configs/
│   ├── settings.yml.template        Annotated SearXNG settings
│   └── openclaw-plugin.template     OpenClaw plugin/agent settings
├── scripts/
│   ├── install-all.sh               Install packages, SearXNG, Redis, systemd unit
│   ├── configure-openclaw.sh        Back up and update openclaw.json
│   ├── test-setup.sh                Eight-point health check
│   ├── update-searxng.sh            Back up, pull, reinstall, restart, verify
│   ├── backup-searxng.sh            Archive configs plus a restore helper
│   └── uninstall.sh                 Remove services, user, files, optional Redis
├── site/                            Sources for the documentation site
│   ├── templates/                   Jinja2 page templates
│   ├── static/                      CSS, JS, favicon
│   ├── data/                        FAQ and troubleshooting content (JSON)
│   └── og.html                      1200x630 social card source
├── scripts/build_site.py            Deterministic site builder / checker
├── docs/                            Generated GitHub Pages output
└── .github/workflows/site.yml      CI for the site build and shell syntax
```

---

## Request flow

```text
Telegram / CLI / channel
        |
        v
OpenClaw gateway
        |
        v
SearXNG plugin/provider
        |
        | HTTP GET /search?q=...&format=json
        v
SearXNG on 127.0.0.1:8080
        |
        +--> Redis 127.0.0.1:6379 (cache)
        |
        +--> enabled upstream engines
             Google, DuckDuckGo, Brave, Bing,
             Wikipedia, GitHub, YouTube, ...
```

The only network boundary an operator must protect is loopback. SearXNG makes
outbound HTTPS requests to the enabled engines; it does not accept remote inbound
connections with the supplied configuration.

---

## Script reference

### `scripts/install-all.sh`

- Requires root and an Ubuntu/Debian host.
- Installs dependencies with `apt`.
- Creates the `searxng` system user and directories.
- Clones SearXNG and installs it into a virtual environment.
- Writes settings only if `/etc/searxng/settings.yml` is absent; otherwise preserves
  the file and writes a timestamped backup.
- Starts and enables Redis and `searxng.service`.
- Verifies the service, Redis, and JSON API.
- Does not modify OpenClaw; it prints the command to run as the OpenClaw user.

### `scripts/configure-openclaw.sh`

- Runs as the user that owns `~/.openclaw`.
- Requires `openclaw` and `jq`.
- Backs up `openclaw.json`, adds `plugins.entries["searxng-search"]`, validates with
  `openclaw doctor`, applies `--fix` if needed, restarts the user gateway, and greps
  for the plugin.

### `scripts/test-setup.sh`

Checks:

1. SearXNG service active
2. Redis reachable
3. HTTP endpoint returns 200
4. JSON API returns at least one result
5. Page 2 returns results (warning if not)
6. OpenClaw installed (warning if not)
7. Plugin visible (warning if not)
8. Disk below 90% used

Exit code is non-zero only when a failure counter is incremented.

### `scripts/update-searxng.sh`

- Requires root.
- Resolves its own directory so backups work from any working directory.
- Calls `backup-searxng.sh` first.
- Fetches and fast-forwards the currently checked-out SearXNG branch.
- Reinstalls the editable package and restarts the service.
- Verifies the service and API.

### `scripts/backup-searxng.sh`

- Writes `~/searxng-backups/searxng-backup-YYYYMMDD-HHMMSS.tar.gz`.
- When invoked through `sudo`, uses `SUDO_USER`'s home so archives do not land in
  `/root`.
- Includes `settings.yml`, optional `limiter.toml`, the systemd unit,
  `openclaw.json`, and a generated `restore.sh`.

### `scripts/uninstall.sh`

- Requires root and interactive confirmation.
- Stops and removes the service, user, `/usr/local/searxng`, and `/etc/searxng`.
- Optionally removes Redis and the OpenClaw `${...}` block.
- Leaves the repository checkout in place.

---

## Configuration templates

`configs/settings.yml.template` contains:

- `use_default_settings` with `engines.keep_only`, so the partial file inherits
  SearXNG's defaults while enabling only the listed engines
- `search.formats: [html, json]`
- loopback binding and port 8080
- Redis URL
- UI defaults
- timeouts and connection pools
- seven general engines plus two news engines

`configs/openclaw-plugin.template` contains:

- `plugins.entries["searxng-search"]` with `baseUrl`, `timeoutMs`,
  `defaultCount`, `enableMultiPage`
- agent compaction and context-pruning settings

Both templates contain example values that must be reviewed before use. The settings
template's `secret_key` is a placeholder; the installer generates a real key.

---

## Documentation site

`site/` is the source; `docs/` is generated and committed for GitHub Pages.

- `site/templates/base.html` defines metadata, navigation, footer, and JSON-LD hooks.
- Page templates contain the content, derived from the Markdown guides.
- `site/data/faq.json` and `site/data/troubleshooting.json` hold structured content
  used by both the page and its JSON-LD.
- `site/static/styles.css` defines the visual system; `app.js` adds navigation and
  copy buttons without requiring JavaScript for content.
- `site/og.html` is rendered by Playwright to `docs/og.png` (1200x630).

Build and check:

```bash
python scripts/build_site.py          # regenerate docs/
python scripts/build_site.py --check  # fail if docs/ is stale or invalid
python scripts/build_site.py --og     # regenerate docs/og.png
```

`--check` also validates required static files, internal links, canonical URLs, and
the absence of known placeholder strings in the Markdown guides.

The canonical origin is defined once in `scripts/build_site.py` as `SITE_URL`
(`https://searxng.danubelabs.net`).

---

## Design decisions

- **Loopback by default.** No auth or TLS is included because the service is not
  exposed. The security guide explains what to add before exposing it.
- **JSON, not scraping.** OpenClaw reads SearXNG's native JSON endpoint. HTML
  scraping is not used.
- **Seven engines, not seventy.** SearXNG ships 70+ engines; enabling all of them
  makes queries slower and increases rate-limit exposure. The installer chooses a
  practical default set.
- **No plugin vendoring.** The repository configures a plugin/provider that belongs
  to OpenClaw. Keeping it external avoids pinning a plugin to this repository.
- **No performance promises.** There is no benchmark harness, so documentation does
  not claim latency, memory, or result-count guarantees.
- **Deterministic docs build.** The site builder has no timestamps in output, sorts
  all generated lists, and supports a CI `--check` mode.

---

## Verification status

| Area | Verified in this repository |
| --- | --- |
| Shell syntax | `bash -n` for every script (CI) |
| Site build | `build_site.py --check` in CI |
| Internal links and assets | Checked by the site builder |
| Canonical/OG/sitemap/robots | Generated and checked |
| SearXNG install | Not executed in the docs/CI environment; requires Ubuntu/Debian |
| OpenClaw integration | Not executed in the docs/CI environment; requires OpenClaw |

See [FINAL_100_PERCENT_COMPLETE.md](FINAL_100_PERCENT_COMPLETE.md) for the explicit
scope and limitations.

**Last updated:** 2026-10-22
