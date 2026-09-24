"""Builds Mohingo's public web pages: support, privacy, terms, delete account.

The App Store and Google Play both need these at public URLs. The privacy
policy and terms are rendered from the app's own copies in assets/legal/,
so the pages can never say something the app does not; the support and
delete-account pages come from tool/legal/site/. Every page exists in
English and Arabic.

    python3 tool/legal/build_site.py     # -> build/legal_site/

`firebase deploy --only hosting` runs this first (firebase.json). It stops
with an error while tool/legal/site.json has no support email: every store
listing and the delete-account page need a real one. Standard library only.
"""

from __future__ import annotations

import html
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEGAL = ROOT / "assets" / "legal"
SITE = Path(__file__).resolve().parent / "site"
CONFIG = Path(__file__).resolve().parent / "site.json"
OUT = ROOT / "build" / "legal_site"

# (output path without language prefix, source, page title en, page title ar)
PAGES = [
    ("privacy", LEGAL / "privacy_{lang}.md", "Privacy Policy", "سياسة الخصوصية"),
    ("terms", LEGAL / "terms_{lang}.md", "Terms of Use", "شروط الاستخدام"),
    (
        "delete-account",
        SITE / "delete_account_{lang}.md",
        "Delete your account",
        "حذف حسابك",
    ),
]

_LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")
_BOLD = re.compile(r"\*\*(.+?)\*\*")


def _inline(text: str, email: str) -> str:
    """Escapes [text] and renders links, bold and the support email."""
    out = html.escape(text, quote=False)
    out = _LINK.sub(lambda m: f'<a href="{m.group(2)}">{m.group(1)}</a>', out)
    out = _BOLD.sub(r"<strong>\1</strong>", out)
    return out.replace(
        "{supportEmail}", f'<a href="mailto:{email}" dir="ltr">{email}</a>'
    )


def render_markdown(source: str, email: str) -> str:
    """The small Markdown subset the legal texts use: #/## headings,
    paragraphs, "- " and "1. " lists, links and bold."""
    blocks: list[str] = []
    paragraph: list[str] = []
    list_tag: str | None = None
    items: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            blocks.append(f"<p>{_inline(' '.join(paragraph), email)}</p>")
            paragraph.clear()

    def flush_list() -> None:
        nonlocal list_tag
        if list_tag:
            body = "".join(f"<li>{_inline(i, email)}</li>" for i in items)
            blocks.append(f"<{list_tag}>{body}</{list_tag}>")
            items.clear()
            list_tag = None

    for raw in source.splitlines():
        line = raw.strip()
        bullet = re.match(r"^[-*] (.+)$", line)
        numbered = re.match(r"^\d+\. (.+)$", line)
        heading = re.match(r"^(#{1,3}) (.+)$", line)
        if not line:
            flush_paragraph()
            flush_list()
        elif heading:
            flush_paragraph()
            flush_list()
            level = len(heading.group(1))
            blocks.append(f"<h{level}>{_inline(heading.group(2), email)}</h{level}>")
        elif bullet or numbered:
            flush_paragraph()
            tag = "ul" if bullet else "ol"
            if list_tag != tag:
                flush_list()
                list_tag = tag
            items.append((bullet or numbered).group(1))
        else:
            flush_list()
            paragraph.append(line)
    flush_paragraph()
    flush_list()
    return "\n".join(blocks)


_STYLE = """
:root { color-scheme: light dark; --bg: #ffffff; --text: #1a1c1c;
  --muted: #5b6365; --accent: #007a87; --rule: #dde3e4; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #111415; --text: #e2e3e3; --muted: #a6adaf;
    --accent: #3de8ff; --rule: #2b3133; } }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto,
    "Noto Sans Arabic", "Geeza Pro", sans-serif; }
header, main, footer { max-width: 42rem; margin: 0 auto; padding: 0 16px; }
header { display: flex; justify-content: space-between; align-items: center;
  padding-top: 20px; padding-bottom: 12px; border-bottom: 1px solid var(--rule); }
.brand { font-weight: 700; font-size: 1.15rem; color: var(--text);
  text-decoration: none; }
a { color: var(--accent); }
h1 { font-size: 1.7rem; line-height: 1.25; margin: 28px 0 8px; }
h2 { font-size: 1.2rem; margin: 28px 0 6px; }
ul, ol { padding-inline-start: 1.4rem; }
li { margin: 4px 0; }
section + section { border-top: 1px solid var(--rule); margin-top: 32px; }
footer { color: var(--muted); font-size: 0.9rem; margin-top: 40px;
  padding-top: 16px; padding-bottom: 32px; border-top: 1px solid var(--rule); }
footer a { margin-inline-end: 16px; }
"""


def _page(lang: str, title: str, body: str, switch_href: str | None) -> str:
    direction = "rtl" if lang == "ar" else "ltr"
    prefix = "/ar" if lang == "ar" else ""
    switch = ""
    if switch_href:
        other, label = ("en", "English") if lang == "ar" else ("ar", "العربية")
        switch = f'<a href="{switch_href}" lang="{other}" hreflang="{other}">{label}</a>'
    footer_links = (
        ("سياسة الخصوصية", "شروط الاستخدام", "حذف الحساب")
        if lang == "ar"
        else ("Privacy Policy", "Terms of Use", "Delete account")
    )
    footer = "".join(
        f'<a href="{prefix}/{path}">{label}</a>'
        for path, label in zip(("privacy", "terms", "delete-account"), footer_links)
    )
    return f"""<!doctype html>
<html lang="{lang}" dir="{direction}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} · Mohingo</title>
<style>{_STYLE}</style>
</head>
<body>
<header><a class="brand" href="/" dir="ltr">Mohingo</a>{switch}</header>
<main>
{body}
</main>
<footer>{footer}</footer>
</body>
</html>
"""


def support_email() -> str:
    email = json.loads(CONFIG.read_text(encoding="utf-8")).get("supportEmail", "")
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email or ""):
        sys.exit(
            f"{CONFIG.relative_to(ROOT)}: set supportEmail to the address "
            "learners should write to. The store listings and the "
            "delete-account page publish it."
        )
    return email


def build(out: Path = OUT, email: str | None = None) -> list[Path]:
    email = email or support_email()
    if out.exists():
        shutil.rmtree(out)
    written: list[Path] = []

    def write(path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        written.append(path)

    for slug, source, title_en, title_ar in PAGES:
        for lang, title in (("en", title_en), ("ar", title_ar)):
            body = render_markdown(
                Path(str(source).format(lang=lang)).read_text(encoding="utf-8"),
                email,
            )
            other = f"/{slug}" if lang == "ar" else f"/ar/{slug}"
            target = out / (f"ar/{slug}.html" if lang == "ar" else f"{slug}.html")
            write(target, _page(lang, title, body, other))

    # The support page — the App Store's Support URL — carries both
    # languages, so it needs no language switch.
    sections = "\n".join(
        f'<section lang="{lang}" dir="{"rtl" if lang == "ar" else "ltr"}">\n'
        + render_markdown((SITE / f"support_{lang}.md").read_text(encoding="utf-8"), email)
        + "\n</section>"
        for lang in ("en", "ar")
    )
    write(out / "index.html", _page("en", "Support", sections, None))
    return written


if __name__ == "__main__":
    for page in build():
        print(page.relative_to(ROOT))
