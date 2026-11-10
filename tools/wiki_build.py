"""Build the game-design wiki: a private website about everything in the game, made from the repo.

Usage: python3 -I tools/wiki_build.py [--out DIR]

Writes the wiki to build/wiki/ (or DIR): static HTML pages, one CSS file, one small search
script and the pictures. Every page is read from the game's own data and docs each time this
runs, so it always says what the game says (only the one-line pitches in ACTIVITIES are written here). Edit the game, run this
again, and the wiki follows.

  game/data/*.json          the eggs, places, Fotka spots, then cards, radio, lines, police, brands
  game/scripts/*.gd         each system's description (the `##` lines at the top) and its tuning
                            constants (with their comments), the landmarks, rivals and race finishes
  docs/*.md, docs/design/   the pillars, the plans, progress, the backlog and the parked questions
  wiki/media.json, wiki/img the pictures (and site/public/img/game, the landing's screenshots)
  wiki/static/              the wiki's look (wiki.css, wiki.js)

Every item says which file (and line) to edit to change it, with a link that opens the file on
GitHub. The wiki is served by wiki/worker.js (wiki/README.md), open to anyone with the link; it is full of
spoilers and plans, so it is never linked from the landing and asks search engines to stay away.
The Markdown converter knows what the docs use: headings, paragraphs, nested lists, tables,
code, **bold**, *italic*, ~~struck~~, `code` and [links](url).
"""

from __future__ import annotations

import argparse
import ast
import datetime
import html
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
DATA = GAME / "data"
SCRIPTS = GAME / "scripts"
DOCS = ROOT / "docs"
WIKI = ROOT / "wiki"

# ---------------------------------------------------------------------------------------------
# Small helpers

def esc(s) -> str:
    return html.escape(str(s), quote=True)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def load(rel: str):
    return json.loads(read(rel))


def gh(rel: str, line: int | None = None) -> str:
    """The repo path of a file (at a line when given); the repo itself is not linked publicly."""
    return rel + (f":{line}" if line else "")


def edit_link(rel: str, line: int | None = None, label: str | None = None) -> str:
    """The "where to change it" chip: the file and line, opening on GitHub."""
    text = label or (f"{rel}:{line}" if line else rel)
    return f'<span class="edit" title="Where to change it">✎ {esc(text)}</span>'


def line_of(rel: str, pattern: str, start: int = 0) -> int | None:
    """The 1-based line of the first match of a regex in a file (from line `start`)."""
    for i, ln in enumerate(read(rel).splitlines()[start:], start + 1):
        if re.search(pattern, ln):
            return i
    return None


def slug(text: str) -> str:
    s = re.sub(r"[`*_~\[\]()]", "", text).strip().lower()
    s = re.sub(r"[^\w\- ]+", "", s)
    return re.sub(r"[\s]+", "-", s)[:70] or "section"


def pl_en(pair) -> str:
    """A [Polish, English] pair as two lines."""
    if isinstance(pair, (list, tuple)) and len(pair) >= 2:
        return f'<span class="pl">{esc(pair[0])}</span><span class="en">{esc(pair[1])}</span>'
    return esc(pair)


def bar(done: int, total: int, label: str = "") -> str:
    pct = round(100 * done / total) if total else 0
    return (f'<div class="bar" title="{done} of {total}"><div class="bar-fill" style="width:{pct}%"></div>'
            f'<span class="bar-text">{esc(label) + " · " if label else ""}{done} / {total} · {pct} %</span></div>')


def table(head: list[str], rows: list[list[str]], cls: str = "") -> str:
    """An HTML table; cells are HTML already."""
    th = "".join(f"<th>{h}</th>" for h in head)
    body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f'<div class="tw"><table class="{cls}"><thead><tr>{th}</tr></thead><tbody>{body}</tbody></table></div>'


def chip(text: str, kind: str = "") -> str:
    return f'<span class="chip {kind}">{esc(text)}</span>'


def swatch(colour: str) -> str:
    return f'<span class="sw" style="background:{esc(colour)}" title="{esc(colour)}"></span>'


# ---------------------------------------------------------------------------------------------
# Markdown (what the docs use)

INLINE_CODE = re.compile(r"`([^`]+)`")


def md_inline(text: str, base: str = "docs") -> str:
    """Inline Markdown to HTML: code, links, bold, italic, struck."""
    codes: list[str] = []

    def keep(m):
        codes.append(f"<code>{esc(m.group(1))}</code>")
        return f"\x00{len(codes) - 1}\x00"

    t = INLINE_CODE.sub(keep, text)
    t = esc(t)

    def link(m):
        label, url = m.group(1), html.unescape(m.group(2))
        if not re.match(r"[a-z]+:|#", url):
            # a repo-relative link: the repo is not linked publicly, show the label only
            return label
        return f'<a href="{esc(url)}">{label}</a>'

    t = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", link, t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"~~(.+?)~~", r"<del>\1</del>", t)
    t = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"<em>\1</em>", t)
    t = re.sub(r"(?<![\w])_(?!\s)([^_]+?)(?<!\s)_(?![\w])", r"<em>\1</em>", t)
    return re.sub(r"\x00(\d+)\x00", lambda m: codes[int(m.group(1))], t)


def md(text: str, base: str = "docs", shift: int = 0, toc: list | None = None) -> str:
    """Block Markdown to HTML. `shift` pushes headings down; `toc` collects (level, id, text)."""
    lines = text.splitlines()
    out: list[str] = []
    i = 0
    used: set[str] = set()

    def heading_id(t: str) -> str:
        s = slug(t)
        n, k = s, 2
        while n in used:
            n, k = f"{s}-{k}", k + 1
        used.add(n)
        return n

    def is_block_start(ln: str) -> bool:
        return bool(re.match(r"\s*(#{1,6} |```|\||[-*+] |\d+\. |> |---\s*$)", ln))

    while i < len(lines):
        ln = lines[i]
        if not ln.strip():
            i += 1
            continue
        m = re.match(r"(#{1,6}) (.*)", ln)
        if m:
            level = min(6, len(m.group(1)) + shift)
            hid = heading_id(m.group(2))
            if toc is not None:
                toc.append((level, hid, m.group(2)))
            out.append(f'<h{level} id="{hid}">{md_inline(m.group(2), base)}</h{level}>')
            i += 1
            continue
        if ln.startswith("```"):
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                j += 1
            out.append("<pre><code>" + esc("\n".join(lines[i + 1:j])) + "</code></pre>")
            i = j + 1
            continue
        if re.match(r"\s*---+\s*$", ln):
            out.append("<hr>")
            i += 1
            continue
        if ln.lstrip().startswith("|"):
            rows = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                rows.append(lines[i].strip())
                i += 1
            cells = [split_row(r) for r in rows]
            if len(cells) >= 2 and all(re.match(r"^:?-{2,}:?$", c.strip()) for c in cells[1] if c.strip()):
                head, body = cells[0], cells[2:]
            else:
                head, body = [], cells
            out.append(table([md_inline(c, base) for c in head], [[md_inline(c, base) for c in r] for r in body]))
            continue
        if ln.startswith("> "):
            quote = []
            while i < len(lines) and lines[i].startswith(">"):
                quote.append(lines[i][1:].lstrip())
                i += 1
            out.append("<blockquote>" + md("\n".join(quote), base) + "</blockquote>")
            continue
        if re.match(r"\s*([-*+]|\d+\.) ", ln):
            block = []
            while i < len(lines) and lines[i].strip() and (re.match(r"\s*([-*+]|\d+\.) ", lines[i]) or lines[i].startswith((" ", "\t")) or not is_block_start(lines[i])):
                block.append(lines[i])
                i += 1
            out.append(md_list(block, base))
            continue
        para = [ln.strip()]
        i += 1
        while i < len(lines) and lines[i].strip() and not is_block_start(lines[i]):
            para.append(lines[i].strip())
            i += 1
        out.append(f"<p>{md_inline(' '.join(para), base)}</p>")
    return "\n".join(out)


def split_row(row: str) -> list[str]:
    row = row.strip()
    if row.startswith("|"):
        row = row[1:]
    if row.endswith("|"):
        row = row[:-1]
    cells, cur, in_code = [], "", False
    for ch in row:
        if ch == "`":
            in_code = not in_code
        if ch == "|" and not in_code and not cur.endswith("\\"):
            cells.append(cur.strip())
            cur = ""
        else:
            cur += ch
    cells.append(cur.strip())
    return cells


def md_list(block: list[str], base: str) -> str:
    """A (nested) list: items by their marker, deeper indents nest."""
    items: list[tuple[int, bool, list[str]]] = []
    for ln in block:
        m = re.match(r"(\s*)([-*+]|\d+\.) (.*)", ln)
        if m:
            items.append((len(m.group(1).expandtabs(4)), m.group(2)[0].isdigit(), [m.group(3)]))
        elif items:
            items[-1][2].append(ln.strip())
    out: list[str] = []
    stack: list[tuple[int, str]] = []
    for indent, ordered, text in items:
        tag = "ol" if ordered else "ul"
        while stack and indent < stack[-1][0]:
            out.append(f"</li></{stack.pop()[1]}>")
        if not stack or indent > stack[-1][0]:
            out.append(f"<{tag}>")
            stack.append((indent, tag))
        else:
            out.append("</li>")
        out.append("<li>" + md_inline(" ".join(text), base))
    while stack:
        out.append(f"</li></{stack.pop()[1]}>")
    return "".join(out)


def md_section(text: str, heading: str) -> str:
    """The body under the first heading that starts with `heading`, up to the next heading of
    the same or a higher level."""
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        m = re.match(r"(#{1,6}) (.*)", ln)
        if m and m.group(2).strip().startswith(heading):
            level = len(m.group(1))
            j = i + 1
            while j < len(lines):
                n = re.match(r"(#{1,6}) ", lines[j])
                if n and len(n.group(1)) <= level:
                    break
                j += 1
            return "\n".join(lines[i + 1:j])
    return ""


# ---------------------------------------------------------------------------------------------
# GDScript: descriptions, constants and literal tables

def strip_comments(src: str) -> str:
    out, in_str, quote, i = [], False, "", 0
    while i < len(src):
        ch = src[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < len(src):
                out.append(src[i + 1])
                i += 2
                continue
            if ch == quote:
                in_str = False
        elif ch in "\"'":
            in_str, quote = True, ch
            out.append(ch)
        elif ch == "#":
            while i < len(src) and src[i] != "\n":
                i += 1
            continue
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def gd_eval(src: str):
    """A GDScript literal (array, dictionary, number, string) as Python, or None."""
    src = strip_comments(src)
    parts = re.split(r'("(?:[^"\\]|\\.)*")', src)
    for k in range(0, len(parts), 2):
        p = parts[k]
        p = re.sub(r"\b(Vector[234]i?|Color|PackedStringArray|PackedVector2Array|PackedFloat32Array|PackedInt32Array|Array)\(", "(", p)
        p = p.replace("&", "")
        p = re.sub(r"\btrue\b", "True", p)
        p = re.sub(r"\bfalse\b", "False", p)
        p = re.sub(r"\bnull\b", "None", p)
        p = re.sub(r"(?<![\w.\"])([A-Za-z_][\w]*(?:\.[A-Za-z_]\w*)*)(?![\w(\"])",
                   lambda m: m.group(1) if m.group(1) in ("True", "False", "None") else f'"{m.group(1)}"', p)
        parts[k] = p
    try:
        return ast.literal_eval("".join(parts))
    except (ValueError, SyntaxError, TypeError, MemoryError, RecursionError):
        return None


def gd_header(rel: str) -> str:
    """The `##` description at the top of a script (before the first code line)."""
    out = []
    for ln in read(rel).splitlines()[1:]:
        if ln.startswith("##"):
            out.append(ln[2:].strip() if len(ln) > 2 else "")
        elif not ln.strip() and out:
            break
        elif ln.startswith(("extends", "class_name", "@")) or not ln.strip():
            continue
        else:
            break
    return "\n".join(out).strip()


def gd_consts(rel: str) -> list[dict]:
    """Top-level constants: name, value text, what it does (its `##` and `#` comments), line,
    and the parsed value when it is a literal."""
    lines = read(rel).splitlines()
    out = []
    i = 0
    while i < len(lines):
        m = re.match(r"const (\w+)\s*(?::\s*[\w\[\]]+\s*)?:?=\s*(.*)$", lines[i])
        if not m:
            i += 1
            continue
        name, rest = m.group(1), m.group(2)
        if re.match(r"(pre)?load\(", rest):
            i += 1
            continue
        start = i
        text = rest
        depth = strip_comments(text).count("[") + strip_comments(text).count("{") + strip_comments(text).count("(") \
            - strip_comments(text).count("]") - strip_comments(text).count("}") - strip_comments(text).count(")")
        while depth > 0 and i + 1 < len(lines):
            i += 1
            text += "\n" + lines[i]
            s = strip_comments(lines[i])
            depth += s.count("[") + s.count("{") + s.count("(") - s.count("]") - s.count("}") - s.count(")")
        doc = []
        j = start - 1
        while j >= 0 and lines[j].startswith("##"):
            doc.insert(0, lines[j][2:].strip())
            j -= 1
        trailing = ""
        if "\n" not in text:
            code = strip_comments(text)
            if len(code) < len(text):
                trailing = text[len(code):].lstrip("# ").strip()
            text = code.strip()
        out.append({"name": name, "text": text, "doc": " ".join(d for d in doc if d), "note": trailing,
                    "line": start + 1, "multi": "\n" in text, "value": gd_eval(text)})
        i += 1
    return out


def gd_table(rel: str, name: str):
    for c in gd_consts(rel):
        if c["name"] == name:
            return c["value"], c["line"]
    return None, None


# ---------------------------------------------------------------------------------------------
# Pages

NAV = [
    ("", "Home", "⌂"),
    ("pillars/", "Pillars and the loop", "◆"),
    ("progress/", "Progress", "▤"),
    ("models/", "Model progress", "▦"),
    ("activities/", "Quests and jobs", "★"),
    ("landmarks/", "Landmarks", "▲"),
    ("places/", "Places and venues", "●"),
    ("secrets/", "Secrets", "✦"),
    ("radio/", "Radio", "♫"),
    ("lines/", "Lines and dialogue", "❝"),
    ("parodies/", "Parody names", "☺"),
    ("systems/", "Systems and tuning", "⚙"),
    ("settings/", "Settings and flags", "☰"),
    ("questions/", "Open questions", "?"),
    ("docs/", "Design documents", "▣"),
    ("how-to/", "How to change things", "✎"),
]

SEARCH: list[dict] = []


class Site:
    def __init__(self, out: Path):
        self.out = out
        self.media = load("wiki/media.json")
        self.used_media: set[str] = set()
        self.built = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    def pics(self, key: str, limit: int = 4) -> str:
        items = self.media.get(key) or []
        if not items:
            return ""
        figs = []
        for src, caption in items[:limit]:
            if src.startswith("site:"):
                name = src[5:]
                url = f"img/site/{name}"
                self.used_media.add(src)
            else:
                url = f"img/{src}"
                self.used_media.add(src)
            figs.append(f'<figure><a href="/{url}" target="_blank"><img src="/{url}" alt="{esc(caption)}" loading="lazy"></a>'
                        f'<figcaption>{esc(caption)}</figcaption></figure>')
        return f'<div class="pics">{"".join(figs)}</div>'

    def page(self, path: str, title: str, body: str, intro: str = "", toc: list | None = None) -> None:
        title, body, intro = scrub(title), scrub(body), scrub(intro)
        nav = "".join(
            f'<a href="/{p}"{" aria-current=page" if p == path else ""}><span class="ni">{icon}</span>{esc(t)}</a>'
            for p, t, icon in NAV)
        toc_html = ""
        if toc:
            links = "".join(f'<a class="t{min(lvl, 4)}" href="#{hid}">{md_inline(txt)}</a>' for lvl, hid, txt in toc if lvl <= 2)
            toc_html = f'<nav class="toc"><div class="toc-h">On this page</div>{links}</nav>'
        doc = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow, noarchive">
<title>{esc(title)} · Around Warsaw wiki</title>
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="/wiki.css">
</head>
<body>
<header class="top">
  <button class="menu" aria-label="Menu" onclick="document.body.classList.toggle('nav-open')">☰</button>
  <a class="brand" href="/"><img src="/favicon.svg" alt="" width="22" height="22"> Around Warsaw <span>design wiki</span></a>
  <form class="search" action="/search/" role="search"><input name="q" type="search" placeholder="Search the wiki…" aria-label="Search the wiki"></form>
</header>
<div class="wrap">
<nav class="side">{nav}<div class="built">Built {esc(self.built)} from the repo</div></nav>
<main>
<h1>{esc(title)}</h1>
{f'<p class="lead">{intro}</p>' if intro else ''}
{toc_html}
{body}
</main>
</div>
<script src="/wiki.js" defer></script>
</body>
</html>
"""
        dest = self.out / path / "index.html"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(doc, encoding="utf-8")
        text = re.sub(r"<[^>]+>", " ", body)
        text = re.sub(r"\s+", " ", html.unescape(text))
        SEARCH.append({"url": "/" + path, "title": title, "text": text[:60000]})


def filter_box(placeholder: str = "Filter this page…") -> str:
    return f'<input class="filter" type="search" placeholder="{esc(placeholder)}" aria-label="Filter">'


# ---- data -------------------------------------------------------------------------------------

def dialogue() -> dict:
    return load("game/data/dialogue.json")


def dialogue_line(ref) -> list | None:
    d = dialogue()
    if isinstance(ref, list) and len(ref) == 2 and ref[0] in d:
        try:
            return d[ref[0]][ref[1]]
        except (IndexError, TypeError):
            return None
    return None


def places() -> dict:
    return load("game/data/places.json")


def place_names() -> dict:
    return {p["id"]: p["name_pl"] for p in places()["places"]}


def eggs_status() -> tuple[int, int, dict]:
    e = load("game/data/eggs.json")
    live = sum(1 for x in e["eggs"] if x["trigger"]["kind"] != "waits")
    return live, len(e["eggs"]), e


# ---- progress -----------------------------------------------------------------------------------

# Rounds whose work landed under another name in the progress log.
ROUND_ALIASES = {"3f": ["landmark models", "rondo towers", "mdm", "historic lanterns", "warsaw spire", "złota 44"],
                 "MW-2": ["storefront", "shop front"], "3i": ["puddles", "night water", "banded headlights"]}


def changelog():
    """tools/changelog.py, the day-by-day changelog (imported by path: `python3 -I`)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("changelog", ROOT / "tools" / "changelog.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def progress_log() -> list[list[str]]:
    sec = md_section(read("docs/ROADMAP.md"), "Progress log")
    rows = []
    for ln in sec.splitlines():
        if re.match(r"\|\s*20\d\d-", ln):
            c = split_row(ln)
            if len(c) >= 3:
                rows.append(c[:3])
    return rows


def round_ids(text: str) -> list[str]:
    """Loop ids in a round's name: "MW-0 – MW-2" → MW-0, MW-1, MW-2; "3h + 3i" → 3h, 3i."""
    text = re.sub(r"\*", "", text)
    ids: list[str] = []
    for a, b in re.findall(r"MW-(\d)\s*[–-]\s*MW-(\d)", text):
        ids += [f"MW-{n}" for n in range(int(a), int(b) + 1)]
    for t in re.findall(r"\b(MW-\d|\d[a-z](?:-\d[a-z]?)?)\b", text):
        if t not in ids:
            ids.append(t)
    return ids


def loop_done(loop_id: str, versions: list[str]) -> bool:
    """The loop is in the progress log under its own id."""
    lid = loop_id.lower()
    return any(re.search(r"(^|[\s(])(loop )?" + re.escape(lid) + r"([a-z]|\b)", v.lower()) for v in versions)


def loop_started(loop_id: str, versions: list[str]) -> bool:
    """Part of the loop's work landed under another name (ROUND_ALIASES)."""
    return any(a in v.lower() for v in versions for a in ROUND_ALIASES.get(loop_id, []))


def backlog_sections() -> list[tuple[str, int, int]]:
    """(section, open, fixed) for each BACKLOG.md section: a struck-through entry is fixed."""
    out = []
    cur, open_, fixed = None, 0, 0
    for ln in read("docs/BACKLOG.md").splitlines():
        m = re.match(r"## (.*)", ln)
        if m:
            if cur:
                out.append((cur, open_, fixed))
            # "Decided ..." sections hold decisions, not problems to fix
            cur, open_, fixed = (None if m.group(1).startswith("Decided") else m.group(1)), 0, 0
            continue
        if cur and re.match(r"- ", ln):
            body = ln[2:].strip()
            head = body[:160].lower()
            if (body.startswith(("~~", "**~~")) or re.match(r"(\*\*)?(fixed|done)\b", head)
                    or re.search(r"\((fixed|done)\b", head) or "**done" in head or "landed" in head[:60]):
                fixed += 1
            else:
                open_ += 1
    if cur:
        out.append((cur, open_, fixed))
    return out


def inventory() -> list[tuple[str, str, str, str]]:
    """What the game holds today: (what, how many, page, source file)."""
    info, _ = gd_table("game/scripts/landmarks.gd", "INFO")
    towers, _ = gd_table("game/scripts/landmarks.gd", "TOWERS")
    rivals, _ = gd_table("game/scripts/rivals.gd", "RIVALS")
    fins, _ = gd_table("game/scripts/rivals.gd", "FINISHES")
    live, total, _ = eggs_status()
    radio = load("game/data/radio.json")["stations"]
    d = dialogue()
    return [
        ("Activities (quests and jobs)", str(sum(1 for a in ACTIVITIES if (ROOT / a[2]).exists())), "activities/", "game/scripts"),
        ("Landmarks with a card", f"{len(info or {})} (of them {len(towers or [])} skyscrapers)", "landmarks/", "game/scripts/landmarks.gd"),
        ("Notebook places", str(len(places()["places"])), "places/", "game/data/places.json"),
        ("Easter eggs", f"{total} ({live} playable, {total - live} waiting on a feature)", "secrets/", "game/data/eggs.json"),
        ("Fotka shot spots", str(len(load("game/data/kadr.json")["kadr"])), "secrets/#fotka", "game/data/kadr.json"),
        ("KASETA then cards", str(len(load("game/data/then_cards.json")["then_cards"])), "secrets/#kaseta", "game/data/then_cards.json"),
        ("Radio stations and tracks", f"{len(radio)} stations, {sum(len(r.get('tracks', [])) for r in radio)} tracks", "radio/", "game/data/radio.json"),
        ("Lines of dialogue", f"{sum(len(v) for k, v in d.items() if not k.startswith('_'))} in {sum(1 for k in d if not k.startswith('_'))} groups", "lines/", "game/data/dialogue.json"),
        ("Rivals and race finishes", f"{len(rivals or [])} rivals, {len(fins or [])} finishes", "activities/#races", "game/scripts/rivals.gd"),
        ("Speed traps and guard posts", f"{len(load('game/data/police_traps.json')['traps'])} traps, {len(load('game/data/police_guards.json')['posts'])} posts", "activities/#police", "game/data/police_traps.json"),
        ("Systems (scripts)", str(sum(1 for p in SCRIPTS.rglob("*.gd") if "/bt/" not in p.as_posix())), "systems/", "game/scripts"),
    ]


def page_progress(site: Site) -> dict:
    road = md_section(read("docs/ROADMAP.md"), "The road to the 1.0 demo")
    versions = [r[1] for r in progress_log()]
    rows, done_rounds, total_rounds = [], 0, 0
    lanes_md = md_section(read("docs/QUESTIONS.md"), "In progress")
    lanes_text = lanes_md.lower()
    for ln in road.splitlines():
        if not re.match(r"\|\s*\d+\s*\|", ln):
            continue
        c = split_row(ln)
        ids = round_ids(c[1])
        done = [i for i in ids if loop_done(i, versions)]
        busy = [i for i in ids if i not in done and (loop_started(i, versions) or re.search(r"\b" + re.escape(i.lower()) + r"\b", lanes_text))]
        total_rounds += 1
        if ids and len(done) == len(ids):
            status, kind = "Done", "ok"
            done_rounds += 1
        elif done or busy:
            status, kind = "In progress", "mid"
        else:
            status, kind = "Not started", "no"
        detail = ", ".join(f"{i} ✓" if i in done else (f"{i} …" if i in busy else i) for i in ids)
        rows.append([esc(c[0]), md_inline(c[1]), md_inline(c[2]), chip(status, kind) + f'<div class="small">{esc(detail)}</div>', esc(c[3])])

    live, total_eggs, _ = eggs_status()
    bl = backlog_sections()
    bl_open = sum(o for _, o, _ in bl)
    bl_fixed = sum(f for _, _, f in bl)
    body = [
        '<div class="cards stats">',
        f'<div class="card"><div class="big">{done_rounds}/{total_rounds}</div>rounds to the 1.0 demo done{bar(done_rounds, total_rounds)}</div>',
        f'<div class="card"><div class="big">{live}/{total_eggs}</div>easter eggs playable (the rest wait on a feature){bar(live, total_eggs)}</div>',
        f'<div class="card"><div class="big">{bl_fixed}/{bl_open + bl_fixed}</div>backlog entries fixed{bar(bl_fixed, bl_open + bl_fixed)}</div>',
        f'<div class="card"><div class="big">{len(versions)}</div>updates in the progress log</div>',
        "</div>",
        '<h2 id="inventory">What is in the game today</h2>',
        table(["Content", "How many", "Source"], [[f'<a href="/{pg}">{esc(w)}</a>', esc(n), f"<code>{esc(src)}</code>"] for w, n, pg, src in inventory()]),
        '<p><a href="/models/">Model progress</a>: every ranked place in the city, with its tier, the plan and how far its model is.</p>',
        '<h2 id="road">The road to the 1.0 demo</h2>',
        '<p>The order of work the project follows (docs/ROADMAP.md). A round is <b>done</b> when every loop in it '
        'appears in the progress log, <b>in progress</b> when some have landed or a session is on it now. '
        + edit_link("docs/ROADMAP.md", line_of("docs/ROADMAP.md", r"^### The road to the 1.0 demo")) + "</p>",
        table(["#", "Round", "What it delivers", "Status", "Estimate (Claude hours)"], rows),
        '<h2 id="lanes">Who is working on what right now</h2>',
        "<p>One session per area. " + edit_link("docs/QUESTIONS.md", line_of("docs/QUESTIONS.md", r"^## In progress")) + "</p>",
        md(lanes_md),
        '<h2 id="backlog">Backlog by area</h2>',
        "<p>Problems and ideas found along the way; a struck-through entry is fixed. " + edit_link("docs/BACKLOG.md") + "</p>",
        table(["Area", "Fixed", "Open", "Progress"],
              [[esc(s), str(f), str(o), bar(f, o + f)] for s, o, f in bl if o + f]),
        '<h2 id="days">Day by day</h2>',
        "<p>The short version, as on aroundwarsaw.app/progress/. " + edit_link("docs/CHANGELOG.md") + "</p>",
        changelog().html_days("h3"),
        '<h2 id="log">Progress log (newest first)</h2>',
        filter_box("Filter the log…"),
        table(["Date", "Update", "What landed"], [[esc(d), esc(v), md_inline(w)] for d, v, w in reversed(progress_log())], "log"),
    ]
    site.page("progress/", "Progress", "\n".join(body),
              "How complete each part of the game is, worked out from the roadmap, the progress log, the backlog and the eggs every time the wiki is built.",
              toc=[(2, "inventory", "What is in the game"), (2, "road", "The road to the 1.0 demo"), (2, "lanes", "Who is working on what"), (2, "backlog", "Backlog by area"), (2, "days", "Day by day"), (2, "log", "Progress log")])
    return {"rounds": (done_rounds, total_rounds), "eggs": (live, total_eggs), "backlog": (bl_fixed, bl_open + bl_fixed)}


# ---- model progress -------------------------------------------------------------------------------

# Names that never appear on the public wiki (the generator scrubs them from the inventory's text).
SCRUB = [(re.compile(r"(Bank )?Pekao( Tower)?", re.I), "the bank-named tower")]

# Part 1's status mark -> (stage, chip colour). "Researching" is a row whose Next cell says
# "photos gathered" (the Mac's refs/<slug>/ and REPORT exist) or that is marked in progress.
MODEL_STAGES = [
    ("done_photos", "Done from photos", "ok"),
    ("done_outline", "Done from outline", "mid"),
    ("researching", "Researching", "mid"),
    ("dress", "Dress only", "no"),
    ("planned", "Planned", "no"),
]


def scrub(text: str) -> str:
    for rx, repl in SCRUB:
        text = rx.sub(repl, text)
    return text


def model_rows() -> list[dict]:
    """Part 1 of docs/CITY_INVENTORY.md as dicts: num, place, street, kind, tier, mark, stage, next."""
    text = read("docs/CITY_INVENTORY.md")
    out, tier = [], ""
    for ln in text.split("## Part 2")[0].splitlines():
        m = re.match(r"### Tier (\w):", ln)
        if m:
            tier = m.group(1)
            continue
        if not tier or not re.match(r"\|\s*\d+\s*\|", ln):
            continue
        c = split_row(ln)
        if len(c) < 6:
            continue
        mark = next((x for x in ("★", "◐", "○", "⏳", "✗") if x in c[4]), "✗")
        nxt = c[5]
        if mark == "★":
            stage = "done_photos"
        elif mark == "⏳" or "photos gathered" in nxt.lower():
            stage = "researching"
        elif mark == "◐":
            stage = "done_outline"
        elif mark == "○":
            stage = "dress"
        else:
            stage = "planned"
        out.append({"num": c[0], "place": c[1], "street": c[2], "kind": c[3], "tier": tier,
                    "mark": mark, "stage": stage, "next": nxt})
    return out


def page_models(site: Site) -> int:
    rows = model_rows()
    names = {k: (label, kind) for k, label, kind in MODEL_STAGES}
    n = len(rows)
    by_stage = {k: sum(1 for r in rows if r["stage"] == k) for k, _, _ in MODEL_STAGES}
    cards = ['<div class="cards stats">']
    for k, label, _ in MODEL_STAGES:
        cards.append(f'<div class="card"><div class="big">{by_stage[k]}</div>{esc(label)}{bar(by_stage[k], n)}</div>')
    cards.append("</div>")

    tier_names = {"S": "Tier S: the city's faces", "A": "Tier A: iconic, seen often", "B": "Tier B: characteristic, gives a street its identity"}
    tier_html, toc = [], [(2, "plan", "The plan"), (2, "tiers", "By tier")]
    for t in "SAB":
        tr = [r for r in rows if r["tier"] == t]
        if not tr:
            continue
        built = sum(1 for r in tr if r["stage"] in ("done_photos", "done_outline"))
        photo = sum(1 for r in tr if r["stage"] == "done_photos")
        trows = []
        for r in tr:
            label, kind = names[r["stage"]]
            trows.append([esc(r["num"]), md_inline(scrub(r["place"])), esc(scrub(r["street"])), esc(scrub(r["kind"])),
                          chip(label, kind), md_inline(scrub(r["next"]))])
        tier_html += [
            f'<h3 id="tier-{t.lower()}">{esc(tier_names[t])}</h3>',
            f'<p>{photo} of {len(tr)} done from photos, {built} of {len(tr)} have a model of their own.</p>',
            bar(built, len(tr)),
            table(["#", "Place", "Street", "Kind", "Stage", "Next"], trows),
        ]
        toc.append((3, f"tier-{t.lower()}", tier_names[t]))

    inv = read("docs/CITY_INVENTORY.md")
    plan_md = md_section(inv, "Part 3.")
    counts = re.search(r"<!-- counts:start -->\s*(.*?)\s*<!-- counts:end -->", inv, re.S)
    body = [
        "<p>Every characteristic place in the map box, ranked, with how far its model is. "
        "This page is generated from <code>docs/CITY_INVENTORY.md</code> (Part 1), so it follows the inventory "
        "on every build. " + edit_link("docs/CITY_INVENTORY.md") + "</p>",
        '<p><b>Stages.</b> <i>Planned</i>: a plain grey block, or not in the game. <i>Researching</i>: photos gathered '
        '(F\'s own, or <code>refs/&lt;slug&gt;/</code> with a REPORT from the Mac) or a thread is on it now. '
        '<i>Done from outline</i>: an own model from the OpenStreetMap outline, LoD2 heights and published facts, '
        'its photo re-pass still to do. <i>Done from photos</i>: built from photos or checked side by side with them. '
        '<i>Dress only</i>: a colour skin, a sign or a card, no model of its own. '
        'A row is marked <i>researching</i> when its inventory line says "photos gathered".</p>',
        *cards,
        '<h2 id="plan">The plan: next threads, in order</h2>',
        "<p>Photos first, then the model, then the side-by-side check (the model-from-photos recipe).</p>",
        md(scrub(plan_md)),
        '<h2 id="tiers">Every place, by tier</h2>',
        filter_box("Filter places…"),
        *tier_html,
    ]
    if counts:
        body.append("<p class=\"small\">" + md_inline(scrub(counts.group(1).replace("\n", " "))) + "</p>")
    site.page("models/", "Model progress", "\n".join(body),
              "Every ranked place in the city, the plan for building it and how far its model is, generated from the city inventory.",
              toc=toc)
    return n


# ---- pillars -------------------------------------------------------------------------------------

def page_pillars(site: Site) -> None:
    vision = read("docs/design/vision.md")
    demo = read("docs/DEMO.md")
    toc: list = []
    parts = [
        '<h2 id="vision">The vision</h2>',
        "<p>" + edit_link("docs/design/vision.md", line_of("docs/design/vision.md", r"^## 1\. The vision")) + "</p>",
        md(md_section(vision, "1. The vision"), "docs/design", 1),
        '<h2 id="pillars">Design pillars</h2>',
        "<p>Every feature should serve at least one of these. " + edit_link("docs/design/vision.md", line_of("docs/design/vision.md", r"^## 2\. Pillars")) + "</p>",
        md(md_section(vision, "2. Pillars"), "docs/design", 1),
        '<h2 id="one-screen">The demo in one screen</h2>',
        "<p>" + edit_link("docs/DEMO.md", line_of("docs/DEMO.md", r"^## 0\. In one screen")) + "</p>",
        md(md_section(demo, "0. In one screen"), "docs", 1),
        '<h2 id="first-10">The first 10 minutes</h2>',
        md(md_section(demo, "6.2 The first 10 minutes"), "docs", 1),
        '<h2 id="first-hour">The first hour</h2>',
        md(md_section(demo, "6.3 The first hour"), "docs", 1),
        '<h2 id="bar">The quality bar</h2>',
        md(md_section(demo, "1.2 The bar for this game"), "docs", 1),
    ]
    toc = [(2, "vision", "The vision"), (2, "pillars", "Design pillars"), (2, "one-screen", "The demo in one screen"),
           (2, "first-10", "The first 10 minutes"), (2, "first-hour", "The first hour"), (2, "bar", "The quality bar")]
    site.page("pillars/", "Pillars and the core loop", "\n".join(parts),
              "What the game is about, the rules every feature is judged by, and what a player does in their first minutes and hour.", toc)


# ---- activities ------------------------------------------------------------------------------------

def lines_block(groups: list[str], limit: int = 6) -> str:
    d = dialogue()
    out = []
    for g in groups:
        if g not in d:
            continue
        ln = line_of("game/data/dialogue.json", rf'^\s*"{re.escape(g)}": \[')
        items = d[g]
        lis = "".join(f"<li>{pl_en(x)}</li>" for x in items[:limit])
        more = f'<li class="small">…and {len(items) - limit} more on the Lines page</li>' if len(items) > limit else ""
        out.append(f'<details><summary><b>{esc(g)}</b> · {len(items)} lines {edit_link("game/data/dialogue.json", ln)}</summary><ul class="lines">{lis}{more}</ul></details>')
    return "".join(out)


def consts_table(rel: str, names: list[str] | None = None) -> str:
    rows = []
    for c in gd_consts(rel):
        if names is not None and c["name"] not in names:
            continue
        if names is None and (c["multi"] or re.match(r"[A-Z]\w*\.", c["text"])):
            continue
        what = c["doc"] or c["note"]
        if c["doc"] and c["note"]:
            what = f'{c["doc"]} ({c["note"]})'
        val = c["text"] if not c["multi"] else f'a table of {len(c["value"]) if isinstance(c["value"], (list, dict)) else "several"} entries'
        rows.append([f"<code>{esc(c['name'])}</code>", f"<code>{esc(val[:120])}</code>", md_inline(what) if what else '<span class="small">—</span>',
                     edit_link(rel, c["line"], f"line {c['line']}")])
    if not rows:
        return ""
    return table(["Setting", "Value", "What it does", "Edit"], rows, "consts")


ACTIVITIES = [
    # key, title, script, dialogue groups, test flag, picture key, the pitch (one line for the overview)
    ("rescues", "Rescue missions (WEZWANIE)", "game/scripts/missions.gd", ["rescue_pickup", "rescue_kid", "rescue_hospital", "rescue_fail"], "--mission=N", "police",
     "A call comes in: someone on a roof, a street, a park or the river bank. Get there by car or helicopter and bring them to a hospital in time."),
    ("kebab", "Kebab delivery", "game/scripts/jobs.gd", ["kebab_order", "kebab_hot", "kebab_cold"], "--kebab=N", None,
     "Pull into a kebab stand, take an order to a real address 400–1500 m away; the hotter it arrives, the bigger the tip. Nights pay more."),
    ("sloiki", "The słoiki run", "game/scripts/jobs.gd", ["sloik_start", "sloik_bump", "sloik_crash", "sloik_done", "sloik_broken", "passenger"], "--sloik[=K]", None,
     "Sunday evening at Centralny: drive a newcomer and mum's six jars to Powiśle without breaking them."),
    ("podwozka", "Podwózka, the app-taxi", "game/scripts/rides.gd", ["podwozka_request", "podwozka_board", "podwozka_done", "podwozka_cancel", "podwozka_gps", "podwozka_chat"], "--ride=N", None,
     "Ride requests from the parody taxi app: find the passenger (the pin is a bit off), ignore the app's odd route, earn stars."),
    ("trend", "Na czasie, the trend job", "game/scripts/trend_job.gd", ["trend_job"], "", "wiralek",
     "Deliver to the café that is trending this week, before the queue moves on."),
    ("races", "Street races (rivals)", "game/scripts/rivals.gd", [], "--race=N --rival=N", None,
     "Flash your lights behind one of six Warsaw characters to race them to a landmark for their stake."),
    ("police", "The police", "game/scripts/police.gd", [], "", "police",
     "Speed traps, chases, pull-overs, city guards in the car-free zones, wheel clamps and escorts to the hospital."),
    ("notebook", "MOJA WARSZAWA, the city notebook", "game/scripts/notebook.gd", [], "", "notebook",
     "Collect the city's 72 places by passing slowly, stopping or flying low; each has a fact and a joke."),
    ("fotka", "Fotka, photo moments", "game/scripts/fotka.gd", [], "--fotka", "fotka",
     "A photo mode with 15 spots that want a certain light."),
    ("kaseta", "KASETA, the time tape", "game/scripts/tape.gd", [], "", "kaseta",
     "Play the tape at a place to see and hear what stood there in another year."),
    ("spacer", "Spacer, wander mode", "game/scripts/spacer.gd", [], "", None,
     "Nothing comes by itself: just drive and discover."),
    ("heli", "The helicopter", "game/scripts/heli.gd", [], "--heli", "skyline",
     "Swap the car for a helicopter: fly over the city, land on roofs, rescue from above."),
]


def page_activities(site: Site) -> None:
    d = dialogue()
    overview, sections, toc = [], [], []
    for key, title, rel, groups, flag, media, pitch in ACTIVITIES:
        if not (ROOT / rel).exists():
            continue
        desc = gd_header(rel)
        overview.append([f'<a href="#{key}">{esc(title)}</a>', esc(pitch), edit_link(rel)])
        toc.append((2, key, title))
        groups = [g for g in groups if g in d] + [g for g in d if not g.startswith("_") and g.split("_")[0] in (key.rstrip("s"), key) and g not in groups]
        block = [f'<h2 id="{key}">{esc(title)}</h2>',
                 f'<p class="meta">{edit_link(rel)}{" · test flag <code>" + esc(flag) + "</code>" if flag else ""}</p>',
                 site.pics(media) if media else "",
                 '<div class="desc">' + md(desc.replace("\n\n", "\n\n"), "game/scripts") + "</div>"]
        if key == "races":
            block.append(races_html())
        if key == "police":
            block.append(police_html())
        if key == "rescues":
            titles, ln = gd_table(rel, "TITLES")
            titles_pl, _ = gd_table(rel, "TITLES_PL")
            if titles:
                block.append("<h3>The four kinds</h3>" + table(["English", "Polish"], [[esc(a), esc(b)] for a, b in zip(titles, titles_pl or [""] * len(titles))]))
        if groups:
            block.append("<h3>Lines</h3>" + lines_block(groups))
        ct = consts_table(rel)
        if ct:
            block.append(f'<details class="tuning"><summary>Tuning: the numbers behind it</summary>{ct}</details>')
        sections.append("\n".join(block))
    body = ['<h2 id="all">Everything the player can do</h2>', table(["Activity", "In one line", "Where it lives"], overview)] + sections
    site.page("activities/", "Quests and jobs", "\n".join(body),
              "Every activity in the game: what it is, how it starts and ends, what it pays, its lines and the numbers that tune it. "
              "One activity runs at a time.", [(2, "all", "Everything the player can do")] + toc)


def races_html() -> str:
    rel = "game/scripts/rivals.gd"
    rivals, ln = gd_table(rel, "RIVALS")
    fin, fln = gd_table(rel, "FINISHES")
    out = []
    if rivals:
        rows = []
        for r in rivals:
            col = r.get("colour") if isinstance(r.get("colour"), str) else ""
            rl = line_of(rel, rf'"name": "{re.escape(r.get("name", ""))}"')
            lines = "".join(f"<li>{pl_en(x)}</li>" for x in r.get("challenge", [])[:2])
            rows.append([swatch(col) + " <b>" + esc(r.get("name", "")) + "</b>", esc(r.get("about", "")), f'{r.get("stake", "")} zł',
                         f'<ul class="lines">{lines}</ul>', edit_link(rel, rl, f"line {rl}")])
        out.append("<h3>The rivals</h3><p>Flash your lights (L) behind one of them to start a race. They pay their stake when you win.</p>"
                   + table(["Rival", "Who they are", "Stake", "Challenges", "Edit"], rows))
    if fin:
        out.append("<h3>Race finishes</h3>" + table(["Finish", "Polish", "English"], [[esc(f["name"]), esc(f.get("pl", "")), esc(f.get("en", ""))] for f in fin])
                   + f'<p>{edit_link(rel, fln)}</p>')
    return "".join(out)


def police_html() -> str:
    traps = load("game/data/police_traps.json")["traps"]
    guards = load("game/data/police_guards.json")["posts"]
    out = ["<h3>Speed traps</h3>", table(["#", "Road", "Where", "Measured", "Limit", "Edit"],
           [[str(t["id"]), esc(t["road"]), esc(t["where"]), esc(t["measured"]), f'{t["limit_kmh"]} km/h',
             edit_link("game/data/police_traps.json", line_of("game/data/police_traps.json", rf'"id": {t["id"]}\b'))] for t in traps]),
           "<h3>City guard posts</h3>", table(["Post", "Where", "Edit"],
           [[esc(g["id"]), esc(g["name"]), edit_link("game/data/police_guards.json", line_of("game/data/police_guards.json", rf'"id": "{g["id"]}"'))] for g in guards]),
           f'<p>The whole design: <a href="/docs/police/">the police design doc</a>. Their lines are the <code>police_*</code> groups on the <a href="/lines/">Lines</a> page.</p>']
    return "".join(out)


# ---- landmarks --------------------------------------------------------------------------------------

def page_landmarks(site: Site) -> int:
    rel = "game/scripts/landmarks.gd"
    info, info_ln = gd_table(rel, "INFO")
    towers, _ = gd_table(rel, "TOWERS")
    skins, _ = gd_table(rel, "SKINS")
    towers = {t["key"]: t for t in towers or []}
    skins = {s["key"]: s for s in skins or []}
    hero = ["palace", "tarasy", "rotunda", "varso", "stadium", "centralna", "poniatowski"]
    groups = {"Hero models (built piece by piece in code)": [], "Skyscrapers": [], "Low-rise landmarks": []}
    for key, card in (info or {}).items():
        if key in towers:
            groups["Skyscrapers"].append(key)
        elif key in hero:
            groups["Hero models (built piece by piece in code)"].append(key)
        else:
            groups["Low-rise landmarks"].append(key)
    body, toc = [filter_box("Find a landmark…")], []
    for g, keys in groups.items():
        gid = slug(g)
        toc.append((2, gid, g))
        cards = []
        for key in keys:
            card = info[key]
            ln = line_of(rel, rf'^\t"{re.escape(key)}": \[')
            look, look_ln = "", None
            if key in towers:
                t = towers[key]
                look_ln = line_of(rel, rf'\{{"key": "{re.escape(key)}"')
                look = (f'Skin <code>{esc(t.get("style", ""))}</code> · glass {swatch(t.get("glass", ""))} roof {swatch(t.get("roof", ""))}'
                        + (f' · top <code>{esc(t["crest"])}</code>' if t.get("crest") else "")
                        + (f' · mapped as “{esc(t["osm"])}”' if t.get("osm") else ""))
            elif key in skins:
                s = skins[key]
                look_ln = line_of(rel, rf'\{{"key": "{re.escape(key)}"', look_ln or 0)
                look = f'Walls {swatch(s.get("wall", ""))} roof {swatch(s.get("roof", ""))} · style <code>{esc(s.get("mode", ""))}</code> · mapped as “{esc(s.get("osm", ""))}”'
            edits = edit_link(rel, ln, "card text") + (" " + edit_link(rel, look_ln, "look") if look_ln else "")
            cards.append(f'<article class="card lm" id="lm-{esc(key)}">{site.pics(key, 1)}<h3>{esc(card[0])}</h3>'
                         f'<p>{pl_en(card[1:3])}</p>{"<p class=small>" + look + "</p>" if look else ""}'
                         f'<p class="meta"><code>{esc(key)}</code> {edits}</p></article>')
        body.append(f'<h2 id="{gid}">{esc(g)} <span class="count">{len(keys)}</span></h2><div class="cards">{"".join(cards)}</div>')
    body.append('<h2 id="street-furniture">Street furniture and the skyline</h2>' + site.pics("street_furniture", 6) + site.pics("skyline"))
    toc.append((2, "street-furniture", "Street furniture and the skyline"))
    desc = gd_header(rel)
    body.insert(0, '<details><summary>How landmarks are made</summary>' + md(desc, "game/scripts") + "</details>")
    site.page("landmarks/", "Landmarks", "\n".join(body),
              f"The {len(info or {})} buildings that make it Warsaw at a glance. Tap one in the game to see its card; the text here is that card. "
              "To change what a card says, edit its line; to change a tower's colours, edit its look.", toc)
    return len(info or {})


# ---- places ------------------------------------------------------------------------------------------

def page_places(site: Site) -> int:
    p = places()
    rel = "game/data/places.json"
    clubs, cln = gd_table("game/scripts/crowds.gd", "CLUBS")
    body, toc = [filter_box("Find a place, street or tag…")], []
    body.append("<p>The 72 places of the MOJA WARSZAWA notebook, in its chapters. Each is found by passing slowly, stopping in it "
                "or flying low over it. " + edit_link(rel) + "</p>" + site.pics("notebook", 3))
    for ch in p["chapters"]:
        items = [x for x in p["places"] if x["chapter"] == ch["id"]]
        toc.append((2, ch["id"], ch["name_en"]))
        rows = []
        for x in items:
            ln = line_of(rel, rf'"id": "{re.escape(x["id"])}"')
            extra = ""
            if clubs and x["id"] in clubs:
                c = clubs[x["id"]]
                extra = f'<div class="small">Club queue up to {c.get("max")} · curve <code>{esc(c.get("curve"))}</code>{" · police" if c.get("police") else ""}{" · dawn crowd" if c.get("dawn") else ""}</div>'
            rows.append([f'<b>{esc(x["name_pl"])}</b>' + (f'<div class="small">{esc(x["name_en"])}</div>' if x["name_en"] != x["name_pl"] else "") + site.pics(x["id"], 1),
                         esc(x.get("address", "")) + (f'<div class="small">{esc(x["hours"])}</div>' if x.get("hours") else "") + extra,
                         pl_en(x.get("fact", "")), pl_en(x.get("joke", "")),
                         " ".join(chip(t) for t in x.get("tags", [])), edit_link(rel, ln, f"line {ln}")])
        body.append(f'<h2 id="{ch["id"]}">{esc(ch["name_pl"])} · {esc(ch["name_en"])} <span class="count">{len(items)}</span></h2>'
                    + table(["Place", "Address, hours", "Fact", "Joke", "Tags", "Edit"], rows, "places"))
    site.page("places/", "Places and venues", "\n".join(body),
              "Clubs, bars, river steps, trend cafés, metro, food, everyday spots, retro places and then-and-now spots: the city as the main character.", toc)
    return len(p["places"])


# ---- secrets ----------------------------------------------------------------------------------------

TRIGGER_WORDS = {
    "legacy": "found on the map (the first five eggs)", "stop": "stop at the place", "waits": "waits for a feature",
    "event": "happens during an event", "hover": "hover the helicopter there", "pass": "drive past",
    "lap": "drive a lap", "tape": "play KASETA there", "street": "drive the street", "land": "land the helicopter",
    "circle": "circle it", "between": "drive between two points",
}


def page_secrets(site: Site) -> dict:
    live, total, e = eggs_status()
    rel = "game/data/eggs.json"
    names = place_names()
    rows = []
    for x in e["eggs"]:
        trig = x["trigger"]
        kind = trig.get("kind", "")
        status = chip("waits: " + x.get("waits", ""), "no") if kind == "waits" else chip("playable", "ok")
        line = x.get("line") or dialogue_line(x.get("line_ref"))
        cond = ", ".join(f"{k} {v}" for k, v in trig.items() if k != "kind")
        reward = ", ".join(f"{v} {k}" for k, v in x.get("reward", {}).items())
        ln = line_of(rel, rf'"id": "{re.escape(x["id"])}"')
        rows.append([f'<code>{esc(x["id"])}</code>', pl_en(x["name"]) + site.pics(x["id"], 1), esc(names.get(x.get("place", ""), x.get("place", ""))),
                     esc(TRIGGER_WORDS.get(kind, kind)) + (f'<div class="small">{esc(cond)}</div>' if cond else ""),
                     pl_en(line) if line else "", esc(reward), status, edit_link(rel, ln, f"line {ln}")])
    waits = e.get("waits", {})
    kadr = load("game/data/kadr.json")["kadr"]
    then = load("game/data/then_cards.json")["then_cards"]
    body = [filter_box("Find an egg, a place or a year…"),
            f'<div class="cards stats"><div class="card"><div class="big">{live}/{total}</div>eggs playable now{bar(live, total)}</div>'
            f'<div class="card"><div class="big">{len(kadr)}</div>Fotka shot spots</div><div class="card"><div class="big">{len(then)}</div>KASETA then cards</div></div>',
            '<h2 id="eggs">Easter eggs</h2>', "<p>Each egg is a card in the notebook's secrets page. "
            + edit_link(rel) + "</p>" + site.pics("eggs", 1),
            table(["Id", "Name", "Place", "How it is found", "Line", "Reward", "Status", "Edit"], rows, "eggs"),
            '<h3 id="waits">Features the waiting eggs need</h3>',
            table(["Feature", "What it is", "Eggs waiting"], [[f"<code>{esc(k)}</code>", esc(v), str(sum(1 for x in e["eggs"] if x.get("waits") == k))] for k, v in waits.items()]),
            '<h2 id="fotka">Fotka: the shot spots</h2>', site.pics("fotka", 1),
            table(["Id", "Shot", "Place", "Light", "Opened by", "Edit"],
                  [[f'<code>{esc(k["id"])}</code>', pl_en(k["name"]), esc(names.get(k["place"], k["place"])), esc(k.get("look") or "any"), esc(k.get("locked_by", "")),
                    edit_link("game/data/kadr.json", line_of("game/data/kadr.json", rf'"id": "{k["id"]}"'))] for k in kadr]),
            '<h2 id="kaseta">KASETA: the then cards</h2>', site.pics("kaseta", 1),
            table(["Year", "Place", "What the tape says", "The ghost you see", "Edit"],
                  [[str(t["year"]), esc(names.get(t["place"], t["place"])), pl_en(t["line"]), esc(t.get("ghost", "")),
                    edit_link("game/data/then_cards.json", line_of("game/data/then_cards.json", rf'"id": "{t["id"]}"'))] for t in sorted(then, key=lambda t: t["year"])]),
            '<h2 id="design">The eggs in the design</h2>', md(md_section(read("docs/design/vision.md"), "8. Easter eggs"), "docs/design", 1)]
    site.page("secrets/", "Secrets", "\n".join(body),
              "Spoilers. The easter eggs, the photo spots and the time tape's then cards: where they are, how they are found and what they give.",
              [(2, "eggs", "Easter eggs"), (2, "fotka", "Fotka shot spots"), (2, "kaseta", "KASETA then cards"), (2, "design", "The eggs in the design")])
    return {"eggs": total, "kadr": len(kadr), "then": len(then)}


# ---- radio ------------------------------------------------------------------------------------------

def page_radio(site: Site) -> int:
    r = load("game/data/radio.json")
    rel = "game/data/radio.json"
    body, toc, n = [], [], 0
    for s in r["stations"]:
        toc.append((2, s["id"], s["name"]))
        ln = line_of(rel, rf'"id": "{re.escape(s["id"])}"')
        tracks = s.get("tracks", [])
        n += len(tracks)
        mins = sum(t.get("seconds", 0) for t in tracks) / 60
        body.append(f'<h2 id="{esc(s["id"])}">{swatch(s.get("colour", ""))} {esc(s["name"])} <span class="count">{esc(s["freq"])}</span></h2>'
                    f'<p class="meta">{len(tracks)} tracks · {mins:.1f} minutes · {edit_link(rel, ln)}</p>'
                    + table(["Track", "Artist", "Length", "Licence"],
                            [[esc(t["title"]), esc(t.get("artist", "")), f'{int(t.get("seconds", 0)) // 60}:{int(t.get("seconds", 0)) % 60:02d}', esc(t.get("licence", ""))] for t in tracks]))
    body.insert(0, '<p>The plan for the beta\'s songs, the opening theme and the announcer\'s voice: '
                '<a href="/docs/sound/">Music and voices</a>; every prompt: <a href="/docs/music/">Music prompts</a>.</p>')
    body.append('<h2 id="host">The radio host</h2>' + lines_block([g for g in dialogue() if g.startswith(("radio", "polnoc"))], 40))
    toc.append((2, "host", "The radio host"))
    body.append('<h2 id="music">Adding music</h2><p>Drop a song in <code>data/raw/music/&lt;station&gt;/</code> and run <code>tools/add_music.py</code>; '
                f'the whole recipe is in docs/archive/DEVELOPMENT-full.md. {edit_link("docs/archive/DEVELOPMENT-full.md", line_of("docs/archive/DEVELOPMENT-full.md", r"^## Adding music"), "Adding music")}</p>'
                '<details class="tuning"><summary>Tuning: radio.gd</summary>' + consts_table("game/scripts/radio.gd") + "</details>")
    toc.append((2, "music", "Adding music"))
    site.page("radio/", "Radio", "\n".join(body), "The stations on the car radio, their playlists and the host's lines.", toc)
    return n


# ---- lines -------------------------------------------------------------------------------------------

def page_lines(site: Site) -> int:
    d = dialogue()
    rel = "game/data/dialogue.json"
    body, toc, n = [filter_box("Find a line in Polish or English…"), "<p>" + md_inline(d.get("_about", "")) + "</p>"], [], 0
    for g, items in d.items():
        if g.startswith("_"):
            continue
        n += len(items)
        ln = line_of(rel, rf'^\s*"{re.escape(g)}": \[')
        toc.append((3, g, g))
        rows = []
        for x in items:
            notes = x[2] if len(x) > 2 and isinstance(x[2], dict) else {}
            rows.append([esc(x[0]), esc(x[1]), " ".join(chip(f"{k}: {v if isinstance(v, str) else ', '.join(map(str, v))}") for k, v in notes.items())])
        body.append(f'<h3 id="{esc(g)}">{esc(g)} <span class="count">{len(items)}</span> {edit_link(rel, ln)}</h3>' + table(["Polish", "English", "When"], rows, "lines-t"))
    site.page("lines/", "Lines and dialogue", "\n".join(body), f"All {n} lines the game says, in Polish and English, by group.", None)
    return n


# ---- parodies ---------------------------------------------------------------------------------------

def page_parodies(site: Site) -> None:
    par = read("docs/design/parodies.md")
    vision = read("docs/design/vision.md")
    deny = load("game/data/brand_denylist.json")
    body = ["<p>Real brands appear only as parodies: no real names or logos. Real place names are fine.</p>",
            '<h2 id="vision">Moja Warszawa parody names</h2>', "<p>" + edit_link("docs/design/vision.md", line_of("docs/design/vision.md", r"^### 3\.0")) + "</p>",
            md(md_section(vision, "3.0 Parody names"), "docs/design", 1),
            '<h2 id="loop-2d">Shops, apps and riders</h2>', "<p>" + edit_link("docs/design/parodies.md", line_of("docs/design/parodies.md", r"^## 1\.")) + "</p>",
            md(md_section(par, "1. Final names"), "docs/design", 1),
            '<h2 id="never">Names that must never appear</h2>',
            "<p>The game's check fails if any of these shows up on screen. " + edit_link("game/data/brand_denylist.json") + "</p>",
            "<p>" + " ".join(chip(x) for x in deny.get("names", [])) + "</p>",
            "<h3>Rejected parody names (too close to a real one)</h3><p>" + " ".join(chip(x, "no") for x in deny.get("rejected", [])) + "</p>"]
    site.page("parodies/", "Parody names", "\n".join(body), "The invented names that stand in for real businesses and brands, and the list that keeps real ones out.",
              [(2, "vision", "Moja Warszawa parody names"), (2, "loop-2d", "Shops, apps and riders"), (2, "never", "Names that must never appear")])


# ---- systems -----------------------------------------------------------------------------------------

SYSTEM_GROUPS = [
    ("Activities", ["missions", "jobs", "rides", "ride_rules", "trend_job", "rivals", "gps_moments", "wallet", "police", "police/police_unit", "police/guards", "police/guard_unit", "police/police_talk", "police/police_tree", "police/police_balloon"]),
    ("Moja Warszawa (the city's soul)", ["notebook", "notebook_page", "eggs", "egg_book", "fotka", "spacer", "tape", "crowds", "city_life", "city_sounds", "radio"]),
    ("Driving, flying and the camera", ["car", "drive_controls", "follow_camera", "camera_shots", "heli", "skids", "tunnel_xray"]),
    ("The living city", ["traffic", "trams", "pedestrians", "ped_zones", "lane_graph", "landmarks", "neon_signs", "props", "models", "time_of_day", "weather"]),
    ("Screen, sound and settings", ["hud", "settings", "settings_panel", "bubbles", "dialogue", "title", "splash", "sfx", "pixel_font", "screen_points", "beacon"]),
    ("Engine and performance", ["main", "map_builder", "tiers", "governor", "sector_streamer", "sector_packs", "sector_proxies", "city_maps", "index_pack", "instance_buffers", "chunked_surface", "bench", "debug_roads"]),
]


def page_systems(site: Site) -> None:
    seen = set()
    groups = []
    for g, names in SYSTEM_GROUPS:
        groups.append((g, [n for n in names if (SCRIPTS / f"{n}.gd").exists()]))
        seen.update(names)
    rest = sorted(p.relative_to(SCRIPTS).with_suffix("").as_posix() for p in SCRIPTS.rglob("*.gd") if p.relative_to(SCRIPTS).with_suffix("").as_posix() not in seen and "/bt/" not in p.as_posix())
    if rest:
        groups.append(("Other", rest))
    body, toc = [filter_box("Find a system or a setting…"),
                 "<p>Each part of the game is one script. Its description is the comment at the top of the file; its tuning is the list of "
                 "constants, with the comment that says what each does. Change a number, run the game, and see.</p>"], []
    for g, names in groups:
        gid = slug(g)
        toc.append((2, gid, g))
        body.append(f'<h2 id="{gid}">{esc(g)}</h2>')
        for n in names:
            rel = f"game/scripts/{n}.gd"
            desc = gd_header(rel)
            ct = consts_table(rel)
            nlines = len(read(rel).splitlines())
            body.append(f'<section class="sys" id="{slug(n)}"><h3>{esc(n)}.gd <span class="count">{nlines} lines</span> {edit_link(rel)}</h3>'
                        + md(desc, "game/scripts", 3)
                        + (f'<details class="tuning"><summary>Tuning ({ct.count("<tr>") - 1} settings)</summary>{ct}</details>' if ct else "")
                        + "</section>")
    site.page("systems/", "Systems and tuning", "\n".join(body), "How each part of the game works, in its own words, and every number that tunes it.", toc)


# ---- settings ----------------------------------------------------------------------------------------

def page_settings(site: Site) -> None:
    dev = read("docs/archive/DEVELOPMENT-full.md")
    flags = ""
    for block in re.split(r"\n(?=## )", dev):
        if "| `--demo`" in block:
            m = re.search(r"((?:^\|.*\n?)+)", block[block.index("| `--demo`") - 3000:], re.M)
            start = block.rfind("\n\n", 0, block.index("| `--demo`"))
            end = block.find("\n\n", block.index("| `--demo`"))
            flags = block[start:end if end > 0 else None]
            break
    body = ['<h2 id="player">What the player can set</h2>', "<p>The Settings card in the game, kept between sessions.</p>",
            '<div class="desc">' + md(gd_header("game/scripts/settings.gd"), "game/scripts") + "</div>",
            consts_table("game/scripts/settings.gd"),
            '<h2 id="controls">Controls</h2>', md(md_section(dev, "Controls"), "docs", 1),
            '<h2 id="flags">Test flags</h2>', "<p>Flags start the game straight into a situation (a race, a job, night, rain…) for testing. "
            + edit_link("docs/archive/DEVELOPMENT-full.md") + "</p>", filter_box("Find a flag…"), md(flags, "docs"),
            '<h2 id="budgets">Performance budgets</h2>', "<p>The phone's limits every change must keep.</p>",
            md(md_section(dev, "Performance budgets"), "docs", 1)]
    site.page("settings/", "Settings and flags", "\n".join(body), "The player's settings, the controls, the test flags and the performance budgets.",
              [(2, "player", "What the player can set"), (2, "controls", "Controls"), (2, "flags", "Test flags"), (2, "budgets", "Performance budgets")])


# ---- questions, docs, how-to, search --------------------------------------------------------------------

DOC_PAGES = [
    ("vision", "Moja Warszawa: the vision", "docs/design/vision.md"),
    ("demo", "The demo plan", "docs/DEMO.md"),
    ("roadmap", "Roadmap", "docs/ROADMAP.md"),
    ("backlog", "Backlog", "docs/BACKLOG.md"),
    ("police", "Police design", "docs/design/police.md"),
    ("parodies", "Parodies design", "docs/design/parodies.md"),
    ("graphics", "Graphics", "docs/design/graphics.md"),
    ("sound", "Music and voices", "docs/design/sound.md"),
    ("music", "Music prompts", "docs/MUSIC.md"),
    ("workflow", "How the work is run", "docs/WORKFLOW.md"),
    ("development", "Development (every detail)", "docs/archive/DEVELOPMENT-full.md"),
]


def page_docs(site: Site) -> None:
    cards = []
    for key, title, rel in DOC_PAGES:
        if not (ROOT / rel).exists():
            continue
        toc: list = []
        text = read(rel)
        body = f"<p>{edit_link(rel)}</p>" + md(text, str(Path(rel).parent), 1, toc)
        site.page(f"docs/{key}/", title, body, "", [t for t in toc if t[0] <= 3])
        first = next((ln for ln in text.splitlines()[1:] if ln.strip() and not ln.startswith(("#", "|", "-"))), "")
        cards.append(f'<a class="card link" href="/docs/{key}/"><h3>{esc(title)}</h3><p class="small">{md_inline(first[:200])}</p><p class="meta">{esc(rel)} · {len(text) // 1000} KB</p></a>')
    site.page("docs/", "Design documents", f'<div class="cards">{"".join(cards)}</div>', "The full design documents, as written, readable here.")


def page_questions(site: Site) -> None:
    q = read("docs/QUESTIONS.md")
    toc: list = []
    body = f"<p>Questions waiting for your answer. Each says the default that was built meanwhile; answer in the project chat. {edit_link('docs/QUESTIONS.md')}</p>" + md(q.split("\n", 1)[1], "docs", 0, toc)
    site.page("questions/", "Open questions", body, "Decisions that are yours to make.", [t for t in toc if t[0] <= 2])


def page_howto(site: Site) -> None:
    rows = [
        ["A landmark's card text or colours", "game/scripts/landmarks.gd", "the Landmarks page links each card's line"],
        ["A place in the notebook (name, address, fact, joke, hours)", "game/data/places.json", "keep both languages; 70 characters a line"],
        ["An easter egg", "game/data/eggs.json", "the trigger kinds are on the Secrets page"],
        ["A Fotka spot", "game/data/kadr.json", ""],
        ["A KASETA then card", "game/data/then_cards.json", ""],
        ["Any line the game says", "game/data/dialogue.json", "each line is [Polish, English]"],
        ["Radio stations and songs", "game/data/radio.json", "songs: tools/add_music.py (DEVELOPMENT.md \"Adding music\")"],
        ["A rival or a race finish", "game/scripts/rivals.gd", ""],
        ["Speed traps and city guards", "game/data/police_traps.json, game/data/police_guards.json", ""],
        ["Pay, distances, timings", "the script on the Systems page", "the Tuning table under each system"],
        ["A brand that must never appear", "game/data/brand_denylist.json", ""],
        ["A design decision or the plan", "docs/design/vision.md, docs/DEMO.md, docs/ROADMAP.md", ""],
        ["A picture in this wiki", "wiki/media.json and wiki/img/", ""],
    ]
    body = ["<h2 id='ways'>Two ways to change the game</h2>",
            "<ol><li><b>Ask Claude.</b> Say what you want in the project chat, in your own words (for example: “make the kebab pay twice as much at night” "
            "or “change Seba's win line”). Link the item from this wiki if it helps. Claude finds the file, changes it, runs the checks and opens a pull request.</li>"
            "<li><b>Edit it yourself.</b> Every item here has a ✎ link that opens its file and line on GitHub. Press the pencil icon there, change the text or "
            "number, and choose “Create a new branch and start a pull request”. The checks run by themselves; merge when they are green.</li></ol>",
            "<p>The wiki rebuilds itself from the repo, so after a change lands it shows the new value (once the wiki is deployed again).</p>",
            "<h2 id='where'>Where things live</h2>", table(["To change…", "Edit", "Notes"], [[esc(a), f"<code>{esc(b)}</code>", esc(c)] for a, b, c in rows]),
            "<h2 id='rules'>Rules every change keeps</h2>",
            "<ul><li>On-screen text in Polish with English; affectionate humour about the city, never about real private people.</li>"
            "<li>Real place names are fine; brands only as parodies (the Parody names page).</li>"
            "<li>The phone's performance budgets (Settings and flags page).</li></ul>",
            "<h2 id='rebuild'>Rebuilding this wiki</h2>",
            "<p><code>python3 -I tools/wiki_build.py</code> writes it to <code>build/wiki/</code>; <code>wiki/README.md</code> says how it is deployed and protected.</p>"]
    site.page("how-to/", "How to change things", "\n".join(body), "For game design without programming: where each thing lives and how to change it.",
              [(2, "ways", "Two ways to change the game"), (2, "where", "Where things live"), (2, "rules", "Rules every change keeps"), (2, "rebuild", "Rebuilding this wiki")])


def page_home(site: Site, counts: dict, progress: dict) -> None:
    tiles = [
        ("activities/", "Quests and jobs", f"{counts['activities']} activities: rescues, kebab, słoiki, Podwózka, races, police…"),
        ("models/", "Model progress", f"{counts['models']} ranked places: planned, researching, done"),
        ("landmarks/", "Landmarks", f"{counts['landmarks']} landmarks with their cards and looks"),
        ("places/", "Places and venues", f"{counts['places']} notebook places in 9 chapters"),
        ("secrets/", "Secrets", f"{counts['eggs']} eggs, {counts['kadr']} photo spots, {counts['then']} then cards"),
        ("radio/", "Radio", f"{counts['stations']} stations, {counts['tracks']} tracks"),
        ("lines/", "Lines and dialogue", f"{counts['lines']} lines in Polish and English"),
        ("parodies/", "Parody names", "the invented brands and the names to keep out"),
        ("systems/", "Systems and tuning", f"{counts['scripts']} systems and every number that tunes them"),
        ("settings/", "Settings and flags", "the player's settings, controls, test flags, budgets"),
        ("pillars/", "Pillars and the loop", "the vision, the pillars, the first 10 minutes and hour"),
        ("questions/", "Open questions", "decisions waiting for you"),
        ("how-to/", "How to change things", "where each thing lives, and how to change it"),
    ]
    dr, tr = progress["rounds"]
    le, te = progress["eggs"]
    bf, bt = progress["backlog"]
    log = progress_log()[-8:]
    body = [
        '<div class="cards stats">',
        f'<a class="card link" href="/progress/#road"><div class="big">{dr}/{tr}</div>rounds to the 1.0 demo{bar(dr, tr)}</a>',
        f'<a class="card link" href="/secrets/"><div class="big">{le}/{te}</div>easter eggs playable{bar(le, te)}</a>',
        f'<a class="card link" href="/progress/#backlog"><div class="big">{bf}/{bt}</div>backlog entries fixed{bar(bf, bt)}</a>',
        "</div>",
        '<div class="cards">' + "".join(f'<a class="card link" href="/{p}"><h3>{esc(t)}</h3><p class="small">{esc(d)}</p></a>' for p, t, d in tiles) + "</div>",
        '<h2 id="latest">Latest updates</h2>',
        table(["Date", "Update", "What landed"], [[esc(d), esc(v), md_inline(w[:400] + ("…" if len(w) > 400 else ""))] for d, v, w in reversed(log)], "log"),
        '<p><a href="/progress/#log">The whole progress log →</a></p>',
    ]
    site.page("", "The game, as a designer sees it", "\n".join(body),
              "Everything in Around Warsaw in one place: what the player can do, where, what it says, what is hidden, and how far each part has come. "
              "Built from the game's own files, so it is always up to date. Private: spoilers and plans.")


def page_search(site: Site) -> None:
    body = '<div id="results"><p class="small">Type in the search box above.</p></div>'
    site.page("search/", "Search", body)


# ---------------------------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default=str(ROOT / "build" / "wiki"))
    args = ap.parse_args()
    out = Path(args.out).resolve()
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    site = Site(out)

    progress = page_progress(site)
    counts_models = page_models(site)
    page_pillars(site)
    page_activities(site)
    counts = {"activities": sum(1 for a in ACTIVITIES if (ROOT / a[2]).exists()), "models": counts_models}
    counts["landmarks"] = page_landmarks(site)
    counts["places"] = page_places(site)
    counts.update(page_secrets(site))
    counts["tracks"] = page_radio(site)
    counts["stations"] = len(load("game/data/radio.json")["stations"])
    counts["lines"] = page_lines(site)
    page_parodies(site)
    page_systems(site)
    counts["scripts"] = sum(1 for p in SCRIPTS.rglob("*.gd") if "/bt/" not in p.as_posix())
    page_settings(site)
    page_questions(site)
    page_docs(site)
    page_howto(site)
    page_search(site)
    page_home(site, counts, progress)

    # The look, the search, the pictures, the fonts
    for f in (WIKI / "static").iterdir():
        shutil.copy2(f, out / f.name)
    shutil.copy2(ROOT / "site/public/favicon.svg", out / "favicon.svg")
    (out / "fonts").mkdir()
    for f in (ROOT / "site/public/fonts").glob("*.woff2"):
        shutil.copy2(f, out / "fonts" / f.name)
    (out / "img" / "site").mkdir(parents=True)
    missing = []
    for src in sorted(site.used_media):
        if src.startswith("site:"):
            p = ROOT / "site/public/img/game" / src[5:]
            dest = out / "img/site" / src[5:]
        else:
            p = WIKI / "img" / src
            dest = out / "img" / src
        if p.exists():
            shutil.copy2(p, dest)
        else:
            missing.append(src)
    (out / "search.json").write_text(json.dumps(SEARCH, ensure_ascii=False), encoding="utf-8")
    (out / "robots.txt").write_text("User-agent: *\nDisallow: /\n", encoding="utf-8")
    (out / "404.html").write_text('<!doctype html><meta charset="utf-8"><meta name="robots" content="noindex"><title>Not found</title>'
                                  '<link rel="stylesheet" href="/wiki.css"><main style="padding:2rem"><h1>Not found</h1><p><a href="/">The wiki\'s home</a></p></main>', encoding="utf-8")
    pages = sum(1 for _ in out.rglob("index.html"))
    size = sum(p.stat().st_size for p in out.rglob("*") if p.is_file())
    if missing:
        print("wiki: missing pictures: " + ", ".join(missing), file=sys.stderr)
        return 1
    print(f"wiki: OK, {pages} pages, {size / 1e6:.1f} MB in {out.relative_to(ROOT) if out.is_relative_to(ROOT) else out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
