# Security Policy

## Supported versions

Security fixes are applied to the current `main` branch. The project is a
single-user, local deployment helper; there are no maintained release branches.

| Version | Supported |
| --- | --- |
| 1.x (current) | Yes |
| Earlier snapshots | No |

## Reporting a vulnerability

Please report security issues privately through GitHub's **Report a vulnerability**
feature on the repository's Security tab:

<https://github.com/FiredMosquito831/searxng-openclaw-complete-setup/security/advisories/new>

Do not open a public issue for a vulnerability before a fix is available. Include:

- The affected file, script, or documentation page.
- Steps to reproduce, including the host distribution and OpenClaw version.
- The impact you believe is possible.
- Any suggested fix or mitigation.

You can expect an acknowledgement and a triage decision. This is a volunteer
project, so no fixed response SLA is promised.

Scope includes the scripts, configuration templates, generated site, and
documentation in this repository. Vulnerabilities in SearXNG, OpenClaw, Redis,
systemd, or upstream search engines should be reported to those projects; this
repository can still document a mitigation.

## Threat model

The supplied configuration is designed for **one user on one Linux host**:

- SearXNG listens on `127.0.0.1:8080`.
- Redis listens on loopback only (`127.0.0.1:6379`).
- The systemd unit runs as the unprivileged `searxng` user and sets
  `NoNewPrivileges=true`, `ProtectSystem=strict`, `ProtectHome=true`, and
  `PrivateTmp=true`.
- No commercial search API keys are stored.
- SearXNG makes outbound HTTPS requests to enabled upstream engines.

It is **not** a hardened public search service. There is no authentication, TLS
termination, per-user isolation, rate limiting (the limiter is disabled because the
service is loopback-bound), or multi-tenant cache separation.

## What is exposed

| Surface | Exposure | Notes |
| --- | --- | --- |
| SearXNG HTTP | `127.0.0.1:8080` | HTML UI and JSON API |
| Redis | `127.0.0.1:6379` | No password by default; loopback only |
| systemd unit | Local | Runs as `searxng`, sandboxing directives enabled |
| OpenClaw config | `~/.openclaw/openclaw.json` | Readable by the OpenClaw user |
| Backups | `~/searxng-backups/*.tar.gz` | Contains `settings.yml` and `openclaw.json`; protect as secrets |
| Outbound traffic | Enabled search engines | Engines see the server's IP address |

The SearXNG `secret_key` is generated locally with `openssl rand -hex 32` and is not
committed to the repository. If you copy a settings file between hosts, generate a
new key.

## Prompt injection and untrusted search results

Search results are untrusted input. A result snippet, title, or page can contain
instructions aimed at the model ("ignore previous instructions", "run this command",
"reveal your configuration"). The chat message is not the only attack surface.

OpenClaw's external-content handling is the relevant layer for agent safety:

- Web search and fetch results are wrapped in
  `<<<EXTERNAL_UNTRUSTED_CONTENT id="...">>>` boundary markers before they reach the
  model. The random identifier makes forged closing markers harder to inject.
- A sanitizer removes common chat-template special-token literals (ChatML, Llama,
  Gemma, Mistral, Phi, GPT-OSS, and similar) so an attacker cannot forge role
  boundaries or fake system turns.
- OpenClaw documents tool policy, exec approvals, sandboxing, channel allowlists,
  and reader-agent patterns as separate, necessary controls.
- The wrapping is explicitly not a substitute for those controls.

See:

- <https://docs.openclaw.ai/gateway/security/prompt-injection>
- <https://docs.openclaw.ai/tools/searxng-search>

What this repository does to reduce the attack surface:

- Uses SearXNG's structured JSON API instead of scraping arbitrary HTML into the
  agent context.
- Binds SearXNG to loopback, so remote clients cannot query it directly.
- Enables only a small default engine set.
- Keeps the service unprivileged and sandboxed.
- Does not store API keys or credentials in the repository.

What it does **not** do:

- It does not classify or sanitize prompt-injection attempts itself. That belongs to
  OpenClaw and to the model/tool policy around it.
- It does not sandbox tool execution.
- It does not prevent a user from pasting untrusted content into the chat.
- It does not make your server anonymous to upstream engines.

Recommended operator controls:

1. Keep `bind_address: 127.0.0.1` and do not port-forward 8080.
2. Keep SearXNG's limiter off only while loopback-bound; enable it if you expose the
   service.
3. Restrict `exec`, `browser`, `web_fetch`, and `web_search` to agents that need
   them; use OpenClaw's allowlists and approvals.
4. Keep external-content wrapping enabled and leave unsafe-content bypass flags off.
5. Use a current, capable model for any tool-enabled agent.
6. Protect backups: they contain configuration and the OpenClaw config.
7. Update SearXNG regularly; engine scrapers break and dependencies get patches.
8. Run `bash scripts/test-setup.sh` after host changes.

## Hardening before exposing SearXNG

If you deliberately make SearXNG reachable beyond loopback:

- Put it behind a reverse proxy with TLS.
- Add authentication at the proxy.
- Enable `server.limiter` and tune `limiter.toml`.
- Restrict inbound access with a firewall to known networks.
- Keep Redis on loopback and set `requirepass`.
- Use a distinct secret key and Redis password.
- Monitor logs and upstream engine failures.
- Re-read the SearXNG documentation for the settings of the version you run.

The scripts in this repository do not perform these steps.

## Secrets and repository hygiene

- `configs/settings.yml.template` contains `CHANGE_THIS_TO_RANDOM_64_CHAR_STRING` as
  an obvious placeholder. Do not deploy it unchanged.
- Backup archives can contain Redis passwords and OpenClaw configuration. Do not
  commit them or attach them unredacted to issues.
- Diagnostics pasted into issues should be reviewed for tokens, hostnames, and
  internal addresses.
