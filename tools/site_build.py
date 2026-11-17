"""Build the website's pages: the landing in English and Polish, the privacy and support pages.

Usage: python3 -I tools/site_build.py

Writes site/public/index.html (English, the default) and site/public/pl/index.html from the
template site/src/index.html and the copy in site/src/strings.json ({{key}} placeholders;
the screenshot reel, the list of things to do and the form's topics are built here), and
site/public/privacy/index.html from docs/privacy.md, so the policy the stores link to
(https://aroundwarsaw.app/privacy/) always says what that file says, and
site/public/support/index.html from docs/support.md (the stores' support URL), and
site/public/progress/index.html, the day-by-day changelog (tools/changelog.py: docs/CHANGELOG.md and
ROADMAP's progress log). The Markdown
converter knows only what those files use: #/## headings, paragraphs, "- " lists, **bold**,
[links](url), "---".
"""

import datetime
import html
import importlib.util
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
# Copy that carries its own markup (links, separators); everything else is escaped.
RAW_KEYS = {"f_legal", "radio_lines", "and_privacy"}  # the author paragraphs are raw too (a link)

# --- A minimal QR encoder (byte mode, error correction M, versions 1-3) for the landing's TestFlight code.
# Tested by decoding its output with OpenCV's QRCodeDetector.
_VERSIONS = {1: (16, 10, ()), 2: (28, 16, (18,)), 3: (44, 26, (22,))}  # version: data codewords, ec codewords, alignment centre


def _rs_ec(data, n):
    exp, log, x = [0] * 512, [0] * 256, 1
    for i in range(255):
        exp[i], log[x] = x, i
        x <<= 1
        if x & 0x100:
            x ^= 0x11D
    for i in range(255, 512):
        exp[i] = exp[i - 255]
    gen = [1]
    for i in range(n):
        nxt = [0] * (len(gen) + 1)
        for j, c in enumerate(gen):
            nxt[j] ^= c
            if c:
                nxt[j + 1] ^= exp[log[c] + i]
        gen = nxt
    rem = [0] * n
    for b in data:
        f = b ^ rem[0]
        rem = rem[1:] + [0]
        if f:
            for j in range(n):
                if gen[j + 1]:
                    rem[j] ^= exp[log[gen[j + 1]] + log[f]]
    return rem


def qr_matrix(text):
    """The QR code of text as a list of rows of 0/1 (dark = 1), without the quiet zone."""
    raw = text.encode("utf-8")
    ver = next((v for v, (d, _, _) in _VERSIONS.items() if len(raw) <= d - 2), None)
    if ver is None:
        raise ValueError("qr: text too long for version 3-M (42 bytes)")
    ndata, nec, align = _VERSIONS[ver]
    bits = "0100" + format(len(raw), "08b") + "".join(format(b, "08b") for b in raw)
    bits += "0" * min(4, ndata * 8 - len(bits))
    bits += "0" * (-len(bits) % 8)
    words = [int(bits[i:i + 8], 2) for i in range(0, len(bits), 8)]
    for pad in range(ndata - len(words)):
        words.append(0xEC if pad % 2 == 0 else 0x11)
    words += _rs_ec(words, nec)
    stream = [(w >> k) & 1 for w in words for k in range(7, -1, -1)]
    n = 17 + 4 * ver
    mod = [[0] * n for _ in range(n)]
    fn = [[False] * n for _ in range(n)]

    def put(r, c, v):
        if 0 <= r < n and 0 <= c < n:
            mod[r][c], fn[r][c] = v, True

    for r0, c0 in ((0, 0), (0, n - 7), (n - 7, 0)):  # finders with their separators
        for dr in range(-1, 8):
            for dc in range(-1, 8):
                d = max(abs(dr - 3), abs(dc - 3))
                put(r0 + dr, c0 + dc, int(d != 2 and d != 4 and 0 <= dr <= 6 and 0 <= dc <= 6))
    for a in align:
        for dr in range(-2, 3):
            for dc in range(-2, 3):
                put(a + dr, a + dc, int(max(abs(dr), abs(dc)) != 1))
    for i in range(8, n - 8):  # timing
        put(6, i, int(i % 2 == 0))
        put(i, 6, int(i % 2 == 0))
    for i in range(9):  # reserve the format areas (the timing cells stay)
        if i != 6:
            put(8, i, 0), put(i, 8, 0)
    for i in range(8):
        put(8, n - 1 - i, 0), put(n - 1 - i, 8, 0)
    put(n - 8, 8, 1)  # the dark module

    def place(mask):
        m = [row[:] for row in mod]
        i, up = 0, True
        for c in range(n - 1, 0, -2):
            if c == 6:
                c = 5
            for k in range(n):
                r = n - 1 - k if up else k
                for cc in (c, c - 1):
                    if not fn[r][cc]:
                        bit = stream[i] if i < len(stream) else 0
                        i += 1
                        m[r][cc] = bit ^ int(_MASKS[mask](r, cc))
            up = not up
        return m

    # Format bits: written explicitly (bit k of the 15, per ISO 18004 figure 25).
    def with_format(m, mask):
        fmt = mask
        v = fmt << 10
        for k in range(4, -1, -1):
            if v >> (k + 10) & 1:
                v ^= 0x537 << k
        f = ((fmt << 10) | v) ^ 0x5412
        for k in range(15):
            b = f >> k & 1
            if k < 6:
                m[k][8] = b
            elif k < 8:
                m[k + 1][8] = b
            else:
                m[8][14 - k if k > 8 else 7] = b
            if k < 8:
                m[8][n - 1 - k] = b
            else:
                m[n - 15 + k][8] = b
        m[n - 8][8] = 1
        return m

    best = None
    for mask in range(8):
        m = with_format(place(mask), mask)
        s = _penalty(m)
        if best is None or s < best[0]:
            best = (s, m)
    return best[1]


_MASKS = [
    lambda r, c: (r + c) % 2 == 0, lambda r, c: r % 2 == 0, lambda r, c: c % 3 == 0,
    lambda r, c: (r + c) % 3 == 0, lambda r, c: (r // 2 + c // 3) % 2 == 0,
    lambda r, c: r * c % 2 + r * c % 3 == 0, lambda r, c: (r * c % 2 + r * c % 3) % 2 == 0,
    lambda r, c: ((r + c) % 2 + r * c % 3) % 2 == 0]


def _penalty(m):
    n, s = len(m), 0
    for grid in (m, [list(x) for x in zip(*m)]):
        for row in grid:
            run = 1
            for i in range(1, n):
                if row[i] == row[i - 1]:
                    run += 1
                    if run == 5:
                        s += 3
                    elif run > 5:
                        s += 1
                else:
                    run = 1
            line = "".join(map(str, row))
            s += 40 * (line.count("10111010000") + line.count("00001011101"))
    for r in range(n - 1):
        for c in range(n - 1):
            if m[r][c] == m[r][c + 1] == m[r + 1][c] == m[r + 1][c + 1]:
                s += 3
    dark = sum(map(sum, m)) * 100 // (n * n)
    return s + abs(dark - 50) // 5 * 10


def qr_svg(text, label, scale=4, quiet=4):
    """An inline <svg> (one path, no scripts, no external files) for text, with a white quiet zone."""
    m = qr_matrix(text)
    n = len(m)
    d = "".join(f"M{c + quiet} {r + quiet}h1v1h-1z" for r in range(n) for c in range(n) if m[r][c])
    size = n + 2 * quiet
    return (f'<svg class="qr" viewBox="0 0 {size} {size}" role="img" aria-label="{label}" shape-rendering="crispEdges">'
            f'<rect width="{size}" height="{size}" fill="#fff"/><path d="{d}" fill="#0b0d24"/></svg>')


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · Around Warsaw</title>
<meta name="description" content="{description}">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="/styles.css">
</head>
<body class="doc">
<header class="bar"><div class="bar-in"><a class="brand" href="/"><img src="/favicon.svg" alt="" width="28" height="28">Around Warsaw</a></div></header>
<main class="prose">
{body}
{extra}<p><a href="/">← aroundwarsaw.app</a></p>
</main>
</body>
</html>
"""

# The privacy page's part about the site itself (docs/privacy.md is about the game).
PRIVACY_SITE = """<h2>This website · Ta strona</h2>
<p>aroundwarsaw.app sets no cookies and runs no tracking scripts. It is served by
Cloudflare, which handles ordinary request data (such as IP addresses) only to deliver and
protect the site, and shows the developer anonymous totals (visits per day, country). Clicks
on the store buttons are counted as a number per button and country, with nothing about you. The beta and feedback form sends what you type (your email, phone type and
message) through Formspree to the developer's inbox. The email is used only to send a beta
invite or to reply, and is deleted on request (write on Telegram, @olshansky93, or through the
same form).</p>
<p>aroundwarsaw.app nie używa ciasteczek ani skryptów śledzących. Stronę serwuje Cloudflare,
który przetwarza zwykłe dane żądań (np. adresy IP) wyłącznie po to, by ją dostarczyć i chronić,
i pokazuje autorowi anonimowe sumy (odwiedziny dziennie, kraj). Kliknięcia przycisków sklepów
są liczone jako liczba na przycisk i kraj, bez żadnych danych o Tobie.
Formularz bety i opinii wysyła to, co wpiszesz (e-mail, rodzaj telefonu, wiadomość), przez
Formspree do skrzynki autora. E-mail służy tylko do wysłania zaproszenia do bety albo
odpowiedzi i zostanie usunięty na prośbę (napisz na Telegramie, @olshansky93, albo przez ten
sam formularz).</p>
"""


def inline(text: str) -> str:
    """Escapes text and turns **bold** into <strong> and [text](url) into a link."""
    text = html.escape(text, quote=False)
    text = re.sub(r"\[(.+?)\]\((\S+?)\)", r'<a href="\2">\1</a>', text)
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)


def convert(md: str) -> str:
    """Converts the small Markdown subset docs/privacy.md and docs/support.md use into HTML."""
    out: list[str] = []
    para: list[str] = []
    items: list[str] = []

    def flush() -> None:
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()
        if items:
            out.append("<ul>" + "".join("<li>" + inline(i) + "</li>" for i in items) + "</ul>")
            items.clear()

    for raw in md.splitlines():
        line = raw.strip()
        if not line:
            flush()
        elif line == "---":
            flush()
            out.append("<hr>")
        elif line.startswith("#"):
            flush()
            level = len(line) - len(line.lstrip("#"))
            title = line[level:].strip()
            out.append(f"<h{level}>{inline(title)}</h{level}>")
        elif line.startswith("- "):
            if para:
                flush()
            items.append(line[2:])
        elif items and raw.startswith("  "):
            items[-1] += " " + line
        else:
            para.append(line)
    flush()
    return "\n".join(out)


def fill(template: str, values: dict[str, str]) -> str:
    """Replaces every {{key}}; a key with no value is an error, so no placeholder ships."""

    def one(m: re.Match[str]) -> str:
        key = m.group(1)
        if key not in values:
            raise KeyError(f"site/src/index.html uses {{{{{key}}}}} but strings.json has no value")
        return values[key]

    return re.sub(r"\{\{(\w+)\}\}", one, template)


GO_IOS_QR = "https://aroundwarsaw.app/go/ios?src=qr"
MONTHS_PL = ["stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca", "lipca", "sierpnia", "września",
             "października", "listopada", "grudnia"]


# Phones show the wide shots as a 4:3 crop (the hero, the chapters, day/night): a 1920 x 884 frame
# cropped to 4:3 fills the width with 61% of the picture, so the browser must ask for 163vw.
PHONE_43 = "(max-width: 700px) 163vw, 100vw"


def pic(name: str, w: int, h: int, alt: str, lazy: bool = True, sizes: str = "100vw") -> str:
    """A <picture>: <name>-960.webp and <name>.webp (1920 px) as a width srcset, so a 3x phone
    takes the 1920 file (the 960 one alone looked soft on F's iPhone, 2026-11-17)."""
    load = ' loading="lazy" decoding="async"' if lazy else ""
    return (f'<img src="/img/game/{name}.webp" srcset="/img/game/{name}-960.webp 960w, /img/game/{name}.webp 1920w" '
            f'sizes="{sizes}" alt="{html.escape(alt)}" width="{w}" height="{h}"{load}>')


def video_sources(sets: list[tuple[str, str]], note: str) -> str:
    """<source> tags (data-src: site.js sets src, so nothing downloads before it decides) for the
    clips that exist in site/public/video/; empty when none does (the page then has no <video>)."""
    out = []
    for kind, base in sets:
        for ext, mime in (("webm", "video/webm"), ("mp4", "video/mp4")):
            if (SITE / "public" / f"{base}.{ext}".lstrip("/")).exists():
                out.append(f'      <source data-set="{kind}" data-src="{base}.{ext}" type="{mime}">')
    if not out:
        print(f"site_build: note: no video files for {note} (site/public{sets[0][1]}.mp4/.webm): left out")
    return "\n".join(out)


def first_sentence(text: str, limit: int = 140) -> str:
    """The first sentence of a changelog line, cut at a word if it is long."""
    text = re.sub(r"\*\*|`", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    m = re.match(r"(.+?[.!?])(\s|$)", text)
    sent = m.group(1) if m else text
    if len(sent) > limit:
        sent = sent[:limit].rsplit(" ", 1)[0].rstrip(",;:") + "…"
    return sent


def landing(strings: dict, lang: str) -> str:
    """The landing page in one language."""
    t = strings[lang]
    values = {k: (v if k in RAW_KEYS else html.escape(v)) for k, v in t.items()}
    live = bool(strings.get("android_live"))
    android_url = strings.get("android_url", "/go/android")
    e = html.escape

    # Hero: poster first (a <picture>), the loop on top when its files exist, a pause button for it.
    hv = strings["hero_video"]
    ver = hv["ver"]
    values.update(hero_poster=strings["hero"], hero_w=str(hv["w"]), hero_h=str(hv["h"]))
    src = video_sources([("desktop", f"/video/hero-{ver}"), ("phone", f"/video/hero-phone-{ver}")], "the hero loop")
    if src:
        values["hero_video"] = (f'    <video class="hero-video" data-hero muted playsinline loop preload="none" aria-hidden="true" '
                                f'poster="/img/game/{strings["hero"]}-960.webp">\n{src}\n    </video>')
        values["hero_button"] = (
            f'  <button class="vctl" type="button" hidden data-pause="{e(t["video_pause"])}" data-play="{e(t["video_play"])}" '
            f'aria-label="{e(t["video_pause"])}"><svg class="i-p" aria-hidden="true"><use href="#i-pause"/></svg>'
            f'<svg class="i-r" aria-hidden="true"><use href="#i-resume"/></svg></button>')
    else:
        values["hero_video"] = values["hero_button"] = ""

    # The two platform buttons: iPhone is live; Android is the Play slot (android_live in strings.json).
    ios_btn = f'<a class="btn btn-primary" data-for="ios" href="/go/ios"><svg aria-hidden="true"><use href="#i-apple"/></svg>{values["cta_ios"]}</a>'
    if live:
        and_btn = (f'<a class="btn btn-primary" data-for="android" href="{e(android_url)}"><svg aria-hidden="true">'
                   f'<use href="#i-play"/></svg>{values["cta_android_b"]}</a>')
        stk_and = f'<a class="btn btn-primary stk-a" href="{e(android_url)}">{values["sticky_android_b"]}</a>'
    else:
        and_btn = (f'<a class="btn btn-ghost" data-for="android" href="#android"><svg aria-hidden="true">'
                   f'<use href="#i-play"/></svg>{values["cta_android_a"]}</a>')
        stk_and = f'<a class="btn btn-ghost stk-a" href="#android">{values["sticky_android_a"]}</a>'
    values["hero_ctas"] = f"      {ios_btn}\n      {and_btn}"
    values["sticky_buttons"] = (f'  <a class="btn btn-primary stk-i" href="/go/ios">{values["sticky_ios"]}</a>\n  {stk_and}')

    # The Android card: a real button when live, else one email field that posts to the same Formspree form.
    vulkan = f'<p class="small">{values["and_vulkan"]}</p>'
    if live:
        values["android_card"] = (
            f'      <div class="plat-card" id="android">\n        <h3><svg aria-hidden="true"><use href="#i-play"/></svg>{values["and_title"]}</h3>\n'
            f'        <p>{values["and_text_b"]}</p>\n'
            f'        <a class="btn btn-primary" href="{e(android_url)}">{values["and_btn_b"]}<svg aria-hidden="true"><use href="#i-arrow"/></svg></a>\n'
            f'        {vulkan}\n      </div>')
    else:
        values["android_card"] = (
            f'      <div class="plat-card" id="android">\n        <h3><svg aria-hidden="true"><use href="#i-play"/></svg>{values["and_title"]}</h3>\n'
            f'        <p>{values["and_text_a"]}</p>\n'
            f'        <form class="notify" id="notify" action="https://formspree.io/f/mykaeqjp" method="POST" novalidate data-need="email">\n'
            f'          <label for="n-email">{values["n_email"]}</label>\n'
            f'          <div class="notify-row"><input id="n-email" name="email" type="email" required autocomplete="email" inputmode="email" aria-describedby="n-email-err">'
            f'<button class="btn btn-ghost send" type="submit">{values["and_btn_a"]}</button></div>\n'
            f'          <p class="err" id="n-email-err" aria-live="polite"></p>\n'
            f'          <input type="hidden" name="_subject" value="Around Warsaw: Android beta, notify">\n'
            f'          <input type="hidden" name="platform" value="Android">\n'
            f'          <input type="hidden" name="source" value="aroundwarsaw.app ({lang}) android notify">\n'
            f'          <div class="hp" aria-hidden="true"><label for="n-gotcha">Leave empty</label><input id="n-gotcha" type="text" name="_gotcha" tabindex="-1" autocomplete="off"></div>\n'
            f'          <p class="status" role="status" aria-live="polite" data-ok="{values["n_ok"]}" data-fail="{values["f_fail"]}" '
            f'data-need-email="{values["f_need_email"]}" data-bad-email="{values["f_bad_email"]}" data-sending="{values["f_sending"]}"></p>\n'
            f'          <p class="small">{values["and_privacy"]}</p>\n'
            f'        </form>\n        {vulkan}\n      </div>')
    values["qr_svg"] = qr_svg(GO_IOS_QR, t["qr_alt"])

    # The city: four full-bleed chapters; Wisła carries the day/night slider under it.
    chap = []
    for c in strings["chapters"]:
        x = c[lang]
        clip = c.get("clip")
        clip_src = video_sources([("desktop", f"/video/{clip}")], f"the {c['id']} chapter clip") if clip else ""
        vid = (f'\n      <video class="chap-video" muted playsinline loop preload="none" aria-hidden="true">\n{clip_src}\n      </video>'
               if clip_src else "")
        chap.append(
            f'  <article class="chap chap-{c["side"]}" id="{c["id"]}" aria-labelledby="h-{c["id"]}">\n'
            f'    <div class="chap-media">{pic(c["img"], c["w"], c["h"], x["alt"], sizes=PHONE_43)}{vid}</div>\n'
            f'    <div class="chap-in wrap"><h3 id="h-{c["id"]}">{e(x["name"])}</h3><p class="chap-line">{e(x["line"])}</p>'
            f'<p class="chap-where">{e(x["where"])}</p></div>\n  </article>')
        if c.get("slider"):
            dn = strings["dn"]
            chap.append(
                f'  <figure class="dn" id="daynight">\n    <div class="dn-stage">\n'
                f'      {pic(dn["night"], dn["w"], dn["h"], t["dn_alt_night"], sizes=PHONE_43)}\n'
                f'      <div class="dn-day">{pic(dn["day"], dn["w"], dn["h"], t["dn_alt_day"], sizes=PHONE_43)}</div>\n'
                f'      <span class="dn-tag dn-tag-l" aria-hidden="true">{values["dn_day"]}</span><span class="dn-tag dn-tag-r" aria-hidden="true">{values["dn_night"]}</span>\n'
                f'      <span class="dn-knob" aria-hidden="true"><svg><use href="#i-drag"/></svg></span>\n'
                f'      <input class="dn-range" type="range" min="0" max="100" value="50" aria-label="{values["dn_label"]}">\n    </div>\n'
                f'    <figcaption class="wrap"><h3>{values["dn_title"]}</h3><p>{values["dn_line"]}</p></figcaption>\n  </figure>')
    html_chap = "\n".join(chap)
    values["chapters"] = html_chap

    # What you do: the QUESTS-shaped frame and five rows.
    q = strings["quests"]
    fr = q["frame"]
    values["quests_frame"] = "        " + pic(fr["img"], fr["w"], fr["h"], t["quests_frame_alt"], sizes="(max-width: 900px) 100vw, 45vw")
    values["quests_rows"] = "\n".join(
        f'      <li class="row{" row-full" if r.get("crop") == "none" else ""}">'
        f'{pic(r["img"], r["w"], r["h"], r[lang]["alt"], sizes="(max-width: 700px) 136vw, 320px")}'
        f'<div><h3>{e(r[lang]["name"])}</h3><p>{e(r[lang]["line"])}</p></div></li>'
        for r in q["rows"])

    # New every day: the newest changelog day, three lines (the same source as /progress/).
    cl = changelog()
    days = cl.days()
    newest = days[0]
    lines = [x for d in days[:3] for x in d["lines"]][:3]
    d0 = datetime.date.fromisoformat(newest["date"])
    values["grow_iso"] = newest["date"]
    values["grow_date"] = (f"{d0.day} {MONTHS_PL[d0.month - 1]} {d0.year}" if lang == "pl"
                           else f"{d0.day} {d0.strftime('%B %Y')}")
    values["grow_items"] = "\n".join(f"      <li>{cl.inline(first_sentence(x))}</li>" for x in lines)

    # The join section's backdrop, the author block, the feedback form's topics.
    jb = strings["join_bg"]
    values.update(join_img=jb["img"], join_w=str(jb["w"]), join_h=str(jb["h"]))
    values["author_body"] = "\n".join(f"      <p>{p}</p>" for p in strings["author"][lang])
    values["topics"] = "\n".join(
        f'          <label><input type="radio" name="topic" value="{e(v)}"{" checked" if i == 0 else ""}>'
        f"<span>{e(label)}</span></label>"
        for i, (v, label) in enumerate(strings["topics"][lang]))
    return fill((SITE / "src" / "index.html").read_text(encoding="utf-8"), values)


def changelog():
    """tools/changelog.py (imported by path: `python3 -I` leaves the tools folder off sys.path)."""
    spec = importlib.util.spec_from_file_location("changelog", ROOT / "tools" / "changelog.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def progress_page() -> str:
    """/progress/: what was added or improved each day, from docs/CHANGELOG.md and ROADMAP's log."""
    cl = changelog()
    intro = (
        "<h1>Progress · Postępy</h1>\n"
        "<p>What was added or improved in Around Warsaw, day by day, newest first. "
        "Co dodano albo poprawiono, dzień po dniu.</p>\n"
        )
    return PAGE.format(title="Progress · Postępy", extra="",
                       description="What's new in Around Warsaw, day by day: what was added or improved, and the backlog.",
                       body=intro + cl.html_days())


def main() -> int:
    strings = json.loads((SITE / "src" / "strings.json").read_text(encoding="utf-8"))
    pages = {
        SITE / "public" / "index.html": landing(strings, "en"),
        SITE / "public" / "pl" / "index.html": landing(strings, "pl"),
        SITE / "public" / "privacy" / "index.html": PAGE.format(
            title="Privacy", extra=PRIVACY_SITE,
            description="Around Warsaw collects no personal data. Privacy policy for the game and this website.",
            body=convert((ROOT / "docs" / "privacy.md").read_text(encoding="utf-8"))),
        SITE / "public" / "support" / "index.html": PAGE.format(
            title="Support · Pomoc", extra="",
            description="Help with Around Warsaw and its beta: contact, TestFlight and Google Play testing, common questions.",
            body=convert((ROOT / "docs" / "support.md").read_text(encoding="utf-8"))),
        SITE / "public" / "progress" / "index.html": progress_page(),
    }
    for path, text in pages.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"site_build: wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
