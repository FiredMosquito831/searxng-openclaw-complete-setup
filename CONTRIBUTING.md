# Contributing

Thanks for helping improve the setup. Bug reports, tested compatibility reports, and
documentation fixes are all valuable.

## Before you open an issue

- Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md) and [FAQ.md](FAQ.md).
- Run `bash scripts/test-setup.sh` and include the summary.
- Collect diagnostics with the block at the end of TROUBLESHOOTING.md.
- Redact tokens, hostnames, public IPs, and Redis passwords.

Security issues should go through [SECURITY.md](SECURITY.md), not a public issue.

## Repository layout

| Path | Purpose |
| --- | --- |
| `scripts/*.sh` | Install, configure, test, update, backup, uninstall |
| `configs/` | Reference SearXNG and OpenClaw configuration |
| `site/templates/` | Jinja2 page templates for the docs site |
| `site/static/` | CSS, JS, and favicon |
| `site/data/` | FAQ and troubleshooting data (JSON) |
| `site/og.html` | Social card source |
| `scripts/build_site.py` | Site builder and `--check` validator |
| `docs/` | Generated output committed for GitHub Pages |

Do not edit files under `docs/` by hand. Edit `site/` or `scripts/build_site.py` and
regenerate.

## Development setup

Requirements: Python 3.10+, Jinja2, and Playwright only if you regenerate the social
card.

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install "jinja2==3.1.6"
```

Build and validate:

```bash
python scripts/build_site.py
python scripts/build_site.py --check
```

Regenerate the 1200x630 social card after design changes:

```bash
pip install playwright
python -m playwright install chromium
python scripts/build_site.py --og
```

Serve the generated site locally:

```bash
python -m http.server 8765 --directory docs
```

Then open `http://127.0.0.1:8765/`.

## Shell scripts

- Target Bash on Ubuntu 20.04+/Debian 11+.
- Keep `set -e` where it does not hide error reporting.
- Quote variables and use `"${BASH_SOURCE[0]}"` when resolving script paths.
- Do not execute the installer as part of the docs build or CI.
- Check syntax before opening a PR:

```bash
for f in scripts/*.sh; do bash -n "$f"; done
```

- Test destructive changes (`uninstall.sh`, `update-searxng.sh`) on a disposable VM
  or container.
- Preserve user configuration on re-runs. The installer must not overwrite an
  existing `/etc/searxng/settings.yml` silently.

## Content guidelines

- Every command in the docs must be copy-paste runnable on a supported host.
- Do not advertise unimplemented features. Put them under an explicit "not
  implemented" section.
- Do not invent performance numbers, result counts, or prices. If a number is not
  measured by this repository, say so.
- Distinguish "SearXNG ships with 70+ engines" from "the installer enables seven".
- Keep the privacy language accurate: SearXNG does not log queries, but upstream
  engines still see the server's IP.
- Prefer links to the repository files over external mirrors.
- Keep the OpenClaw version and plugin shape claims scoped to what was tested.

## Pull requests

1. Fork the repository and create a topic branch.
2. Make the change, regenerate the site, and run:
   ```bash
   python scripts/build_site.py --check
   for f in scripts/*.sh; do bash -n "$f"; done
   ```
3. Update `CHANGELOG.md` for user-visible changes.
4. Open a PR describing:
   - what changed and why,
   - how it was tested (distribution, OpenClaw version),
   - any documentation or compatibility impact.
5. Use the PR template if one is present.

Keep commits focused. Generated `docs/` changes should come from a single build of
the source changes in the same PR.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
