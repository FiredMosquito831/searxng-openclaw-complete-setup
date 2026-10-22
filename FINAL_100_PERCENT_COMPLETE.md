# Project Status and Verified Scope

The filename is retained for link compatibility. It does **not** mean every
environment or integration has been tested. This page records what is verified in the
repository, what requires a Linux host, and what is deliberately out of scope.

**Last updated:** 2026-10-22

---

## Verified in this repository

| Area | Evidence |
| --- | --- |
| Shell syntax | Every `scripts/*.sh` file passes `bash -n` in CI |
| Site build | `python scripts/build_site.py --check` passes in CI |
| Site links | Internal page and asset links are validated by the builder |
| Site metadata | Canonical URLs, OG/Twitter tags, JSON-LD, sitemap, robots, CNAME |
| Social card | `docs/og.png` is a real 1200x630 render of `site/og.html` |
| Documentation consistency | Placeholder scan and source-link checks in the builder |
| Responsive layout | Site checked at 1440px and 390px widths |
| Local serving | `docs/` served over HTTP and swept for non-200 pages/assets |

The revamp also corrected the following issues:

- Removed username, author name, email, and link placeholders from the guides,
  badges, clone URLs, and license.
- Removed the unimplemented Docker option from the documentation.
- Removed references to documentation files and a status script that did not exist.
- Corrected the SearXNG update branch assumption (`master`, not `main`).
- Preserved an existing `/etc/searxng/settings.yml` on installer re-runs instead of
  overwriting it.
- Fixed the backup destination when the backup script is invoked through `sudo`.
- Added `use_default_settings` with `engines.keep_only` so partial settings inherit
  SearXNG defaults while keeping the documented engine set.
- Fixed the invalid `server.max_request_timeout` placement in the tuning guide.
- Replaced the non-JSON engine-status check with `unresponsive_engines` from the
  JSON API.
- Added `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and CI for the site.

---

## Requires a Linux host (not run in the docs environment)

These steps are documented and syntax-checked, but they were not executed in the
environment that generated the site. Run them on Ubuntu 20.04+/Debian 11+:

- `scripts/install-all.sh`
- `scripts/configure-openclaw.sh`
- `scripts/test-setup.sh`
- `scripts/update-searxng.sh`
- `scripts/backup-searxng.sh`
- `scripts/uninstall.sh`

The initial project notes report a successful run on Ubuntu 22.04 under WSL2 with
OpenClaw 2026.2.23. That is a historical report, not a CI result.

---

## Compatibility notes

### OpenClaw plugin shape

`configure-openclaw.sh` writes a `searxng-search` plugin entry. OpenClaw 2026.6.9+
documents a built-in SearXNG provider using:

- `tools.web.search.provider: "searxng"`
- `plugins.entries.searxng.config.webSearch.baseUrl`
- per-call `count` of 1–10

Use one shape that matches your installed OpenClaw release. `openclaw doctor` reports
invalid keys. Both shapes are documented in
[CONFIGURATION.md](CONFIGURATION.md#openclaw-configuration).

### SearXNG version

The installer clones the current SearXNG `master` branch and installs it in editable
mode. Settings keys can change upstream. If SearXNG rejects a key after an update,
compare `/etc/searxng/settings.yml` with the version's
`utils/templates/etc/searxng/settings.yml` and remove or migrate the key.

### Result counts

- The installer enables seven engines.
- SearXNG ships with 70+ engines.
- A single page usually returns a few dozen results, varying by engines and rate
  limits.
- Pagination uses `pageno`; it is not guaranteed that every engine returns page 2.
- The bundled plugin template requests 100 results and enables multi-page retrieval.
- OpenClaw's built-in provider caps a call's `count` at 10.

---

## Not implemented

The following are explicitly not part of this repository:

- Docker or Docker Compose deployment.
- A reverse proxy, TLS certificates, or authentication.
- Public or multi-tenant hardening for SearXNG.
- A packaged OpenClaw plugin (the repo configures a plugin/provider only).
- Fedora, RHEL, Arch, or macOS installers.
- A benchmark suite, performance guarantees, or capacity planning.
- Automated firewall configuration.
- Anonymity or Tor integration.

Do not advertise or assume these features. If you add one, update this file, the
README, and the documentation site together.

---

## Release checklist

Before tagging a release:

- [ ] `python scripts/build_site.py --check` passes.
- [ ] `for f in scripts/*.sh; do bash -n "$f"; done` passes.
- [ ] No placeholder strings remain: `grep -rn "YOUR_[A-Z]*\|LINK_[A-Z]*" .`
- [ ] No link points to a missing file.
- [ ] `docs/CNAME` contains `searxng.danubelabs.net`.
- [ ] `docs/og.png` is 1200x630 and current.
- [ ] Installer changes were tested on a clean Ubuntu 22.04 or Debian 12 host.
- [ ] OpenClaw integration was tested against the documented OpenClaw version.
- [ ] `CHANGELOG.md` has an entry for the release.
- [ ] The site and README agree on version, requirements, and scope.

---

## License

MIT © 2026 FiredMosquito831. See [LICENSE](LICENSE).

SearXNG and OpenClaw are separate projects and are not affiliated with this
repository.
