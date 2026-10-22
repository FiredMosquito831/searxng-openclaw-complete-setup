#!/usr/bin/env python3
"""Build the SearXNG + OpenClaw documentation site.

Sources live in site/; the generated GitHub Pages output is written to docs/.
The build is deterministic: no timestamps, stable ordering, and a --check mode
that fails when docs/ differs from a fresh render.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from html import unescape
from pathlib import Path
from urllib.parse import urldefrag, urlparse
from xml.sax.saxutils import escape as xml_escape

try:
    from jinja2 import Environment, FileSystemLoader, StrictUndefined
except ImportError:  # pragma: no cover - exercised by missing dependency only
    sys.exit("Jinja2 is required: pip install 'jinja2==3.1.6'")

ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = ROOT / "site"
TEMPLATES_DIR = SITE_DIR / "templates"
STATIC_DIR = SITE_DIR / "static"
DATA_DIR = SITE_DIR / "data"
DOCS_DIR = ROOT / "docs"

# Single source of truth for the deployed origin.
SITE_URL = "https://searxng.danubelabs.net"
REPO_URL = "https://github.com/FiredMosquito831/searxng-openclaw-complete-setup"
VERSION = "1.1.0"
LAST_UPDATED = "2026-10-22"
AUTHOR = "FiredMosquito831"

FORBIDDEN_TEXT = [
    "YOUR_USERNAME",
    "YOUR_NAME",
    "YOUR_EMAIL",
    "LINK_HERE",
    "Coming Soon",
    "docs/PERFORMANCE.md",
    "docs/SECURITY.md",
    ".github/CONTRIBUTING.md",
    "check-status.sh",
]

PAGES = [
    {
        "slug": "",
        "out": "index.html",
        "template": "home.html",
        "nav": "Home",
        "title": "SearXNG + OpenClaw: Private self-hosted search",
        "description": (
            "Install a local SearXNG instance for OpenClaw: JSON search, Redis cache, "
            "multi-page results, 70+ engines available, and no search API keys."
        ),
        "keywords": (
            "SearXNG, OpenClaw, self-hosted search, private search, metasearch, "
            "Redis, Ubuntu, Debian, local search API"
        ),
        "path": "/",
        "priority": "1.0",
        "changefreq": "weekly",
        "jsonld": ["website", "software"],
    },
    {
        "slug": "install",
        "out": "install/index.html",
        "template": "install.html",
        "nav": "Install",
        "title": "Install SearXNG for OpenClaw (automated or manual)",
        "description": (
            "Install SearXNG, Redis, and a systemd service on Ubuntu or Debian, then "
            "connect the JSON search API to OpenClaw. Automated and manual steps."
        ),
        "keywords": (
            "install SearXNG, OpenClaw setup, Ubuntu SearXNG, Debian, Redis, systemd, "
            "manual installation, search plugin"
        ),
        "path": "/install/",
        "priority": "0.9",
        "changefreq": "monthly",
        "jsonld": ["howto", "breadcrumb"],
    },
    {
        "slug": "configuration",
        "out": "configuration/index.html",
        "template": "configuration.html",
        "nav": "Configure",
        "title": "Configuration: SearXNG, Redis, and OpenClaw",
        "description": (
            "Configure SearXNG JSON output, engines, Redis, timeouts, and the OpenClaw "
            "search plugin. Includes both plugin configuration shapes."
        ),
        "keywords": (
            "SearXNG configuration, settings.yml, OpenClaw config, Redis, JSON API, "
            "search engines, timeouts"
        ),
        "path": "/configuration/",
        "priority": "0.8",
        "changefreq": "monthly",
        "jsonld": ["breadcrumb"],
    },
    {
        "slug": "usage",
        "out": "usage/index.html",
        "template": "usage.html",
        "nav": "Usage",
        "title": "Usage: search from OpenClaw, Telegram, or HTTP",
        "description": (
            "Use SearXNG through OpenClaw and Telegram, query the JSON API with curl, "
            "page results with pageno, and filter by category or time range."
        ),
        "keywords": (
            "OpenClaw search usage, Telegram search bot, SearXNG JSON API, pageno, "
            "search categories, curl"
        ),
        "path": "/usage/",
        "priority": "0.8",
        "changefreq": "monthly",
        "jsonld": ["breadcrumb"],
    },
    {
        "slug": "maintenance",
        "out": "maintenance/index.html",
        "template": "maintenance.html",
        "nav": "Maintain",
        "title": "Maintenance: update, backup, status, and logs",
        "description": (
            "Maintain the local SearXNG deployment: update from upstream, back up "
            "configuration, inspect systemd logs, run tests, and uninstall safely."
        ),
        "keywords": (
            "SearXNG update, backup SearXNG, systemd logs, journalctl, Redis, "
            "uninstall, maintenance"
        ),
        "path": "/maintenance/",
        "priority": "0.7",
        "changefreq": "monthly",
        "jsonld": ["breadcrumb"],
    },
    {
        "slug": "security",
        "out": "security/index.html",
        "template": "security.html",
        "nav": "Security",
        "title": "Security: local-only posture and prompt injection",
        "description": (
            "Understand what the SearXNG setup exposes, how OpenClaw wraps untrusted "
            "search results, and which hardening steps are left to the operator."
        ),
        "keywords": (
            "SearXNG security, prompt injection, untrusted content, loopback, Redis "
            "security, OpenClaw security, privacy"
        ),
        "path": "/security/",
        "priority": "0.8",
        "changefreq": "monthly",
        "jsonld": ["breadcrumb"],
    },
    {
        "slug": "troubleshooting",
        "out": "troubleshooting/index.html",
        "template": "troubleshooting.html",
        "nav": "Troubleshooting",
        "title": "Troubleshooting SearXNG and OpenClaw integration",
        "description": (
            "Fix SearXNG service failures, HTML instead of JSON, zero results, Redis "
            "connection errors, port conflicts, and OpenClaw plugin problems."
        ),
        "keywords": (
            "SearXNG troubleshooting, Redis connection refused, JSON API HTML, "
            "OpenClaw plugin not loading, port 8080, systemd"
        ),
        "path": "/troubleshooting/",
        "priority": "0.8",
        "changefreq": "monthly",
        "jsonld": ["breadcrumb"],
    },
    {
        "slug": "faq",
        "out": "faq/index.html",
        "template": "faq.html",
        "nav": "FAQ",
        "title": "FAQ: cost, privacy, limits, and compatibility",
        "description": (
            "Answers about SearXNG cost, privacy, engine counts, result limits, "
            "OpenClaw plugin compatibility, updates, and backups."
        ),
        "keywords": (
            "SearXNG FAQ, OpenClaw search cost, privacy, search limits, plugin "
            "compatibility, self-hosted search"
        ),
        "path": "/faq/",
        "priority": "0.8",
        "changefreq": "monthly",
        "jsonld": ["faq", "breadcrumb"],
    },
    {
        "slug": "about",
        "out": "about/index.html",
        "template": "about.html",
        "nav": "About",
        "title": "About this project and its MIT license",
        "description": (
            "About the SearXNG + OpenClaw setup: maintainer, license, project scope, "
            "documentation sources, and how to contribute or report issues."
        ),
        "keywords": (
            "SearXNG OpenClaw project, MIT license, Danube Labs, contribute, "
            "documentation"
        ),
        "path": "/about/",
        "priority": "0.5",
        "changefreq": "yearly",
        "jsonld": ["person", "breadcrumb"],
    },
    {
        "slug": "404",
        "out": "404.html",
        "template": "404.html",
        "nav": None,
        "title": "Page not found",
        "description": (
            "The requested page was not found on searxng.danubelabs.net. Use the "
            "documentation index to find installation, configuration, usage, security, "
            "or troubleshooting."
        ),
        "keywords": "404, page not found",
        "path": "/404.html",
        "priority": "0.0",
        "changefreq": "yearly",
        "robots": "noindex,nofollow",
        "jsonld": [],
        "sitemap": False,
    },
]


def load_json(name: str):
    with (DATA_DIR / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def engine_facts() -> tuple[list[str], int]:
    """Read the enabled engine names from the installer so the site cannot drift."""
    text = (ROOT / "scripts" / "install-all.sh").read_text(encoding="utf-8")
    try:
        block = text.split("\nengines:", 1)[1].split("SETTINGS", 1)[0]
    except IndexError:
        return [], 0
    names = re.findall(r"^\s*- name:\s*(.+?)\s*$", block, flags=re.MULTILINE)
    return names, len(names)


def breadcrumb_ld(page: dict) -> dict:
    items = [
        {
            "@type": "ListItem",
            "position": 1,
            "name": "Home",
            "item": SITE_URL + "/",
        }
    ]
    if page["slug"] not in ("", "404"):
        items.append(
            {
                "@type": "ListItem",
                "position": 2,
                "name": page["nav"],
                "item": SITE_URL + page["path"],
            }
        )
    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": items,
    }


def software_ld(page: dict) -> dict:
    return {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": "SearXNG + OpenClaw Complete Setup",
        "applicationCategory": "DeveloperApplication",
        "applicationSubCategory": "Search",
        "operatingSystem": "Ubuntu 20.04+, Debian 11+",
        "softwareVersion": VERSION,
        "url": SITE_URL + "/",
        "codeRepository": REPO_URL,
        "license": REPO_URL + "/blob/main/LICENSE",
        "description": page["description"],
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "author": {"@type": "Person", "name": AUTHOR},
    }


def website_ld() -> dict:
    return {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "SearXNG + OpenClaw",
        "alternateName": "SearXNG + OpenClaw Complete Setup",
        "url": SITE_URL + "/",
        "description": (
            "Documentation for a local, self-hosted SearXNG search backend for "
            "OpenClaw, with Redis caching and no commercial search API keys."
        ),
        "inLanguage": "en",
        "publisher": {"@type": "Person", "name": AUTHOR},
    }


def howto_ld(page: dict) -> dict:
    steps = [
        (
            "Clone the repository",
            "git clone https://github.com/FiredMosquito831/"
            "searxng-openclaw-complete-setup.git",
        ),
        (
            "Install SearXNG and Redis",
            "sudo bash scripts/install-all.sh",
        ),
        (
            "Configure OpenClaw",
            "bash scripts/configure-openclaw.sh (run as the OpenClaw user, without sudo)",
        ),
        (
            "Verify the installation",
            "bash scripts/test-setup.sh",
        ),
    ]
    return {
        "@context": "https://schema.org",
        "@type": "HowTo",
        "name": "Install SearXNG for OpenClaw on Ubuntu or Debian",
        "description": page["description"],
        "totalTime": "PT30M",
        "estimatedCost": {"@type": "MonetaryAmount", "currency": "USD", "value": "0"},
        "tool": [
            {"@type": "HowToTool", "name": "Ubuntu 20.04+ or Debian 11+"},
            {"@type": "HowToTool", "name": "sudo access"},
        ],
        "step": [
            {
                "@type": "HowToStep",
                "position": index,
                "name": name,
                "text": text,
                "url": SITE_URL + "/install/#" + re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-"),
            }
            for index, (name, text) in enumerate(steps, start=1)
        ],
    }


def faq_ld(items: list[dict]) -> dict:
    return {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {
                "@type": "Question",
                "name": item["q"],
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": unescape(re.sub(r"<[^>]+>", "", item["a"])).strip(),
                },
            }
            for item in items
        ],
    }


def person_ld() -> dict:
    return {
        "@context": "https://schema.org",
        "@type": "Person",
        "name": AUTHOR,
        "url": "https://github.com/FiredMosquito831",
        "worksFor": {"@type": "Organization", "name": "Danube Labs"},
    }


def build_jsonld(page: dict, faq_items: list[dict]) -> list[str]:
    builders = {
        "website": lambda: website_ld(),
        "software": lambda: software_ld(page),
        "howto": lambda: howto_ld(page),
        "faq": lambda: faq_ld(faq_items),
        "person": lambda: person_ld(),
        "breadcrumb": lambda: breadcrumb_ld(page),
    }
    blocks = []
    for name in page.get("jsonld", []):
        blocks.append(json.dumps(builders[name](), indent=2, ensure_ascii=False).replace("</", "<\\/"))
    return blocks


def render_site() -> dict[str, bytes]:
    faq_items = load_json("faq.json")
    engines, engine_count = engine_facts()

    env = Environment(
        loader=FileSystemLoader(TEMPLATES_DIR),
        autoescape=True,
        trim_blocks=True,
        lstrip_blocks=True,
        undefined=StrictUndefined,
    )
    env.filters["safe_json"] = (
        lambda value: json.dumps(value, ensure_ascii=False).replace("</", "<\\/")
    )

    nav_pages = [page for page in PAGES if page.get("nav")]
    outputs: dict[str, bytes] = {}

    for index, page in enumerate(PAGES):
        prev_page = PAGES[index - 1] if index > 0 else None
        next_page = PAGES[index + 1] if index + 1 < len(PAGES) else None
        if prev_page is not None and prev_page["slug"] == "404":
            prev_page = None
        if next_page is not None and next_page["slug"] == "404":
            next_page = None

        template = env.get_template(page["template"])
        rendered = template.render(
            page=page,
            pages=nav_pages,
            all_pages=PAGES,
            site_url=SITE_URL,
            repo_url=REPO_URL,
            version=VERSION,
            last_updated=LAST_UPDATED,
            author=AUTHOR,
            faq=faq_items,
            engines=engines,
            engine_count=engine_count,
            jsonld=build_jsonld(page, faq_items),
            prev_page=prev_page,
            next_page=next_page,
            canonical=SITE_URL + page["path"],
        )
        outputs[page["out"]] = rendered.encode("utf-8")

    # Static assets
    for source in sorted(STATIC_DIR.rglob("*")):
        if source.is_file():
            relative = source.relative_to(STATIC_DIR).as_posix()
            outputs[f"assets/{relative}"] = source.read_bytes()

    # Generated metadata files
    outputs[".nojekyll"] = b""
    outputs["CNAME"] = (SITE_URL.replace("https://", "").rstrip("/") + "\n").encode("utf-8")
    outputs["robots.txt"] = (
        "User-agent: *\n"
        "Allow: /\n"
        "\n"
        f"Sitemap: {SITE_URL}/sitemap.xml\n"
    ).encode("utf-8")
    outputs["sitemap.xml"] = build_sitemap().encode("utf-8")
    return outputs


def build_sitemap() -> str:
    entries = []
    for page in PAGES:
        if page.get("sitemap") is False:
            continue
        entries.append(
            "  <url>\n"
            f"    <loc>{xml_escape(SITE_URL + page['path'])}</loc>\n"
            f"    <lastmod>{LAST_UPDATED}</lastmod>\n"
            f"    <changefreq>{page['changefreq']}</changefreq>\n"
            f"    <priority>{page['priority']}</priority>\n"
            "  </url>"
        )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(entries)
        + "\n</urlset>\n"
    )


def png_size(path: Path) -> tuple[int, int] | None:
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    return width, height


def check_links(outputs: dict[str, bytes], errors: list[str]) -> None:
    href_re = re.compile(r'(?:href|src)="([^"]+)"')
    for name, payload in outputs.items():
        if not name.endswith(".html"):
            continue
        text = payload.decode("utf-8")
        for raw in href_re.findall(text):
            target = raw.strip()
            if not target or target.startswith(("#", "mailto:", "tel:", "data:")):
                continue
            parsed = urlparse(target)
            if parsed.scheme in ("http", "https"):
                continue
            clean, fragment = urldefrag(target)
            if clean.startswith("/"):
                resolved = clean.lstrip("/")
            else:
                base = Path(name).parent.as_posix()
                resolved = (base + "/" + clean) if base not in ("", ".") else clean
            resolved = re.sub(r"/+", "/", resolved)
            while resolved.startswith("../"):
                resolved = resolved[3:]
            if resolved in ("", "."):
                resolved = name
            if resolved.endswith("/"):
                resolved += "index.html"
            if resolved not in outputs:
                errors.append(f"{name}: broken internal link {raw!r} -> {resolved}")
            elif fragment and resolved.endswith(".html"):
                target_text = outputs[resolved].decode("utf-8")
                if f'id="{fragment}"' not in target_text:
                    errors.append(
                        f"{name}: broken fragment {raw!r} -> no id={fragment!r} in {resolved}"
                    )


def validate(outputs: dict[str, bytes], errors: list[str]) -> None:
    required = {".nojekyll", "CNAME", "robots.txt", "sitemap.xml", "404.html", "index.html"}
    for name in sorted(required):
        if name not in outputs:
            errors.append(f"missing required output: {name}")

    expected_cname = SITE_URL.replace("https://", "").rstrip("/") + "\n"
    if outputs.get("CNAME", b"").decode("utf-8") != expected_cname:
        errors.append("CNAME does not match SITE_URL")

    for name, payload in outputs.items():
        if not name.endswith(".html"):
            continue
        text = payload.decode("utf-8")
        if f'<link rel="canonical" href="{SITE_URL}' not in text:
            errors.append(f"{name}: missing canonical URL for SITE_URL")
        if f'property="og:image" content="{SITE_URL}/og.png"' not in text:
            errors.append(f"{name}: missing OG image")
        if '<meta name="description"' not in text:
            errors.append(f"{name}: missing meta description")
        if text.count("<h1") != 1:
            errors.append(f"{name}: expected exactly one h1")
        for block in re.findall(
            r'<script type="application/ld\+json">(.*?)</script>', text, re.DOTALL
        ):
            try:
                json.loads(block)
            except json.JSONDecodeError as exc:
                errors.append(f"{name}: invalid JSON-LD ({exc})")
        for forbidden in FORBIDDEN_TEXT:
            if forbidden in text:
                errors.append(f"{name}: forbidden placeholder/claim {forbidden!r}")

    for md in sorted(ROOT.glob("*.md")):
        text = md.read_text(encoding="utf-8")
        for forbidden in FORBIDDEN_TEXT:
            if forbidden in text:
                errors.append(f"{md.name}: forbidden placeholder/claim {forbidden!r}")

    sitemap = outputs.get("sitemap.xml", b"").decode("utf-8")
    for page in PAGES:
        if page.get("sitemap") is False:
            continue
        if f"<loc>{SITE_URL + page['path']}</loc>" not in sitemap:
            errors.append(f"sitemap missing {page['path']}")

    check_links(outputs, errors)


def write_outputs(outputs: dict[str, bytes]) -> None:
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    for name, payload in sorted(outputs.items()):
        target = DOCS_DIR / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)


def check_outputs(outputs: dict[str, bytes]) -> list[str]:
    errors: list[str] = []
    for name, payload in sorted(outputs.items()):
        target = DOCS_DIR / name
        if not target.is_file():
            errors.append(f"missing: docs/{name} (run without --check)")
        elif target.read_bytes() != payload:
            errors.append(f"stale: docs/{name} (run without --check)")
    if not errors:
        validate(outputs, errors)
        og_path = DOCS_DIR / "og.png"
        if not og_path.is_file():
            errors.append("missing docs/og.png (run with --og)")
        else:
            size = png_size(og_path)
            if size != (1200, 630):
                errors.append(f"docs/og.png is {size}, expected 1200x630")
    return errors


def generate_og() -> None:
    from playwright.sync_api import sync_playwright

    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    source = SITE_DIR / "og.html"
    target = DOCS_DIR / "og.png"
    env = Environment(
        loader=FileSystemLoader(SITE_DIR),
        autoescape=True,
        trim_blocks=True,
        lstrip_blocks=True,
    )
    html = env.from_string(source.read_text(encoding="utf-8")).render(
        site_url=SITE_URL, version=VERSION
    )
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch()
        page = browser.new_page(viewport={"width": 1200, "height": 630}, device_scale_factor=1)
        page.set_content(html, wait_until="load")
        page.wait_for_timeout(300)
        page.screenshot(path=str(target))
        browser.close()
    print(f"wrote docs/og.png ({png_size(target)[0]}x{png_size(target)[1]})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify docs/ is current")
    parser.add_argument("--og", action="store_true", help="regenerate docs/og.png with Playwright")
    args = parser.parse_args()

    outputs = render_site()
    errors: list[str] = []
    validate(outputs, errors)

    if args.check:
        errors.extend(check_outputs(outputs))
        if errors:
            print("Site check failed:", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            return 1
        print(f"Site check OK: {len(PAGES)} pages, {len(outputs)} files")
        return 0

    if errors:
        print("Site validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    write_outputs(outputs)
    print(f"Wrote {len(outputs)} files to docs/ ({len(PAGES)} pages)")

    if args.og:
        generate_og()
    elif not (DOCS_DIR / "og.png").is_file():
        print("Note: docs/og.png is missing; run with --og to generate it.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
