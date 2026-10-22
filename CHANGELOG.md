# Changelog

All notable changes to this project. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-22

### Added

- Generated documentation site in `docs/` with a Jinja2 builder
  (`scripts/build_site.py`) and sources in `site/`.
- Pages for install, configuration, usage, maintenance, security, troubleshooting,
  FAQ, about/license, and a custom 404.
- SEO metadata per page, canonical URLs on `https://searxng.danubelabs.net`,
  Open Graph/Twitter cards, a 1200x630 `docs/og.png`, JSON-LD, sitemap, robots, and
  `.nojekyll`.
- `docs/CNAME` for `searxng.danubelabs.net`.
- CI workflow `.github/workflows/site.yml` for the site build and shell syntax.
- `SECURITY.md`, `CONTRIBUTING.md`, and this changelog.
- `--check` mode for deterministic site validation.

### Changed

- Rewrote the README with real badge URLs, a repository site link, accurate scope,
  and an explicit non-goals section.
- Removed GitHub username, author name, email, and link placeholders from badges,
  clone URLs, license, and guides.
- Removed the unimplemented Docker option and references to nonexistent files.
- Corrected engine counts: SearXNG ships with 70+ engines; the installer enables
  seven.
- Replaced unsupported performance claims with measured-scope language.
- Documented both the `searxng-search` plugin shape and the newer built-in
  `searxng` provider shape.
- Corrected the security/privacy posture: loopback-only, no TLS/auth included,
  upstream engines still see the server IP.
- Rewrote `REPOSITORY_SUMMARY.md` and `FINAL_100_PERCENT_COMPLETE.md` as accurate
  technical/status documents.

### Fixed

- Settings templates and the manual install now use `use_default_settings` with
  `engines.keep_only`. Without it, SearXNG treats a partial settings file as the
  complete configuration instead of merging it with its defaults.
- `install-all.sh`: preserve an existing `/etc/searxng/settings.yml` instead of
  overwriting it on re-run.
- `install-all.sh`: remove an OpenClaw backup step that used `/root` under `sudo`
  and could abort the installer.
- `install-all.sh`: replace undefined log helpers inside `sudo -u` heredocs.
- `install-all.sh`: use `libxslt1-dev` and the `redis-server.service` unit name.
- `update-searxng.sh`: pull the checked-out branch (`master` upstream) instead of
  assuming `main`; remove the unused status block.
- `backup-searxng.sh`: place backups in the invoking user's home when run via
  `sudo`; use one timestamp for the directory and archive.
- `test-setup.sh`: accept either `searxng-search` or `searxng` in `openclaw doctor`.
- `uninstall.sh`: reload systemd after removing the unit.
- `CONFIGURATION.md`: move `max_request_timeout` under `outgoing` (it was invalid
  under `server`).
- `TROUBLESHOOTING.md`: query `unresponsive_engines` from the JSON API instead of
  assuming `/stats` returns JSON.

## [1.0.0] - 2026-02-24

### Added

- Initial release: install, configure, test, update, backup, and uninstall scripts.
- SearXNG settings template with JSON API, Redis, and seven enabled engines.
- OpenClaw plugin configuration template.
- README, INSTALL, CONFIGURATION, TROUBLESHOOTING, FAQ, and MIT license.
