#!/usr/bin/env python3
"""Pixel-art mocks for THE TAPCZAN's new inside UI and beer pong v2 (docs/design/tapczan-pong-v2.md).

Draws each screen on padel's pixel canvas (216 rows, the width from the phone's aspect: 467 px
for 2532x1170), scales it up nearest-neighbour to the phone's pixels the way padel_match.gd shows
its SubViewport, then adds the size notes (pink, in points) at the phone's own resolution.
The letters are the game's own 5x7 font, read from game/scripts/pixel_font.gd.

Usage (from the repo root; standard library only):
    python3 -I docs/design/tapczan-pong-v2-mocks.py            # writes the PNGs next to this file
    python3 -I docs/design/tapczan-pong-v2-mocks.py --plain    # the same without the size notes

Design material, not game code: the drawing calls here (rects, a few polygons, the font) are the
ones the game's view will make in `_draw`, so the sizes and colours can be copied across.
"""
import math
import os
import re
import struct
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT_W, OUT_H = 2532, 1170
H = 216
W = round(H * OUT_W / OUT_H)          # 467
K = max(OUT_W / W, OUT_H / H)         # 5.42 screen px per canvas px (KEEP_ASPECT_COVERED)
PT = 3.0                              # screen px per point on this phone
U = K / PT                            # 1.81 pt per canvas px
SAFE_X = 26                           # 47 pt of safe inset each side, in canvas px
SAFE_B = 12                           # 21 pt at the bottom


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


# --- the palette: padel's own colours first, then the pub's (section 2 of the brief) -----------
P = {k: rgb(v) for k, v in {
    # padel_match.gd
    "us": "#ff7a2a", "us_d": "#d4501c", "them": "#27c4dc", "them_d": "#1784a8",
    "ball": "#e4f23a", "line": "#f2f2ea", "frame": "#16191d", "court": "#2d3135", "gold": "#ffd23a",
    "wood": "#7a5232", "wood_d": "#4a3220", "jeans": "#262a36",
    "skin1": "#f1c8a4", "skin2": "#e2b08a", "skin3": "#d9a984", "skin4": "#c48d68",
    "hair_br": "#4a2e1a", "hair_bl": "#e2c060", "hair_gr": "#bcbcbc", "hair_bk": "#2a2a2a",
    "night0": "#0b1530", "night1": "#16264a", "night2": "#26365c",
    # the pub
    "brick": "#7a3324", "brick_l": "#93432e", "brick_d": "#5c2419", "mortar": "#431a12",
    "slate": "#2d3135", "slate_l": "#383d42", "slate_d": "#1f2327",
    "wood_l": "#9a6b40", "copper": "#c8743a", "copper_l": "#e89a58",
    "amber": "#ffb020", "amber_l": "#ffd98a", "beer": "#f2a51e", "foam": "#fbf1d0",
    "cup": "#d4282e", "cup_d": "#9a1c22", "cup_l": "#ee5a5a",
    "board": "#1b2224", "board_l": "#243033", "chalk": "#f2f2ea", "chalk_d": "#9aa6a0",
    "concrete": "#7c8088", "concrete_d": "#5f636b", "chrome": "#c9d2d8",
    "void": "#0a0a0c", "ink": "#16191d", "paper": "#fbf1d0", "paper_d": "#d9cba0",
    "go": "#5fd38a", "alert": "#ff4f6d", "note": "#ff4fd8", "purple": "#7a5ac8", "pearl": "#fff6e6",
}.items()}


# --- the game's 5x7 font --------------------------------------------------------------------------
def load_font():
    src = open(os.path.join(ROOT, "game", "scripts", "pixel_font.gd"), encoding="utf-8").read()
    glyphs = {}
    for m in re.finditer(r'^\t"((?:\\.|[^"\\])+)": \[([^\]]*)\],?$', src, re.M):
        key = m.group(1).replace('\\"', '"')
        glyphs[key] = re.findall(r'"([.#]+)"', m.group(2))
    glyphs["="] = ["....", "....", "####", "....", "####", "....", "...."]
    glyphs["x"] = [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"]   # a small cross
    return glyphs


GLYPHS = load_font()
MARKED = {"Ą": ("A", "ogonek"), "Ć": ("C", "acute"), "Ę": ("E", "ogonek"), "Ń": ("N", "acute"),
          "Ó": ("O", "acute"), "Ś": ("S", "acute"), "Ź": ("Z", "acute"), "Ż": ("Z", "dot")}


def glyph_pixels(ch):
    base, mark = MARKED.get(ch, (ch, ""))
    rows = GLYPHS.get(base)
    if rows is None:
        return [], 0
    out = [(x, 2 + y) for y, line in enumerate(rows) for x, c in enumerate(line) if c == "#"]
    if mark == "acute":
        out += [(3, 0), (2, 1)]
    elif mark == "dot":
        out.append((2, 0))
    elif mark == "ogonek":
        out.append((3, 9))
    return out, len(rows[0])


def text_pixels(s):
    """Lit pixels of a line (x, row 0..9) and its width; the cell is 10 rows, the letter rows 2..8."""
    s = "".join(c if c == "x" else c.upper() for c in s)
    out, x, first = [], 0, True
    for ch in s:
        if ch == " ":
            x += 3 + (0 if first else 1)
            first = True
            continue
        px, w = glyph_pixels(ch)
        if w == 0:
            continue
        if not first:
            x += 1
        out += [(x + a, b) for a, b in px]
        x += w
        first = False
    return out, x


def text_w(s):
    return text_pixels(s)[1]


def wrap(s, max_px):
    lines, line = [], ""
    for word in s.split(" "):
        trial = word if not line else line + " " + word
        if line and text_w(trial) > max_px:
            lines.append(line)
            line = word
        else:
            line = trial
    if line:
        lines.append(line)
    return lines


# --- a tiny canvas --------------------------------------------------------------------------------
class Canvas:
    def __init__(self, w, h, fill):
        self.w, self.h = w, h
        self.rows = [bytearray(bytes(fill) * w) for _ in range(h)]
        self.cover = None  # when set: a set of (x, y) the UI drew on (to measure how much it hides)

    def pset(self, x, y, c, a=1.0):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            row, i = self.rows[y], x * 3
            if a >= 1.0:
                row[i:i + 3] = bytes(c)
            else:
                for k in range(3):
                    row[i + k] = int(row[i + k] + (c[k] - row[i + k]) * a)
            if self.cover is not None:
                self.cover.add((x, y))

    def rect(self, x, y, w, h, c, a=1.0):
        x, y, w, h = int(round(x)), int(round(y)), int(round(w)), int(round(h))
        x0, x1, y0, y1 = max(x, 0), min(x + w, self.w), max(y, 0), min(y + h, self.h)
        if x1 <= x0 or y1 <= y0:
            return
        if a >= 1.0 and self.cover is None:
            span = bytes(c) * (x1 - x0)
            for yy in range(y0, y1):
                self.rows[yy][x0 * 3:x1 * 3] = span
        else:
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    self.pset(xx, yy, c, a)

    def line(self, x0, y0, x1, y1, c, a=1.0):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.pset(x0, y0, c, a)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def poly(self, pts, c, a=1.0):
        ys = [p[1] for p in pts]
        for y in range(max(int(math.floor(min(ys))), 0), min(int(math.ceil(max(ys))) + 1, self.h)):
            xs = []
            yc = y + 0.5
            for i in range(len(pts)):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % len(pts)]
                if (ya <= yc < yb) or (yb <= yc < ya):
                    xs.append(xa + (yc - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                x0, x1 = int(round(xs[i])), int(round(xs[i + 1]))
                if x1 > x0:
                    self.rect(x0, y, x1 - x0, 1, c, a)

    def disc(self, cx, cy, rx, ry, c, a=1.0):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / max(rx, 0.01)) ** 2 + ((y - cy) / max(ry, 0.01)) ** 2 <= 1.0:
                    self.pset(x, y, c, a)

    def ring(self, cx, cy, rx, ry, c, a=1.0):
        n = int(8 + 4 * max(rx, ry))
        seen = set()
        for i in range(n):
            t = math.tau * i / n
            p = (int(round(cx + math.cos(t) * rx)), int(round(cy + math.sin(t) * ry)))
            if p not in seen:
                seen.add(p)
                self.pset(p[0], p[1], c, a)

    def text(self, s, x, y, c, scale=1, centre=False, shadow=False, a=1.0):
        px, w = text_pixels(s)
        x0 = int(round(x - w * scale * 0.5)) if centre else int(round(x))
        y0 = int(round(y))
        if shadow:
            for gx, gy in px:
                self.rect(x0 + gx * scale + scale, y0 + gy * scale + scale, scale, scale, (0, 0, 0), 0.7)
        for gx, gy in px:
            self.rect(x0 + gx * scale, y0 + gy * scale, scale, scale, c, a)
        return w * scale

    def sprite(self, rows, x, y, pal, flip=False):
        for j, line in enumerate(rows):
            if flip:
                line = line[::-1]
            for i, ch in enumerate(line):
                if ch in pal:
                    self.pset(x + i, y + j, pal[ch])


def upscale(cv):
    """The canvas shown over the whole phone screen, nearest-filtered (padel_match.gd `_tex`)."""
    out = Canvas(OUT_W, OUT_H, (0, 0, 0))
    xmap = [min(int(x / K), cv.w - 1) for x in range(OUT_W)]
    cache = {}
    for y in range(OUT_H):
        sy = min(int(y / K), cv.h - 1)
        if sy not in cache:
            src = cv.rows[sy]
            cache = {sy: bytearray(b"".join(bytes(src[i * 3:i * 3 + 3]) for i in xmap))}
        out.rows[y] = bytearray(cache[sy])
    return out


def write_png(path, cv):
    raw = b"".join(b"\x00" + bytes(r) for r in cv.rows)

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", cv.w, cv.h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# --- the size notes (the phone's own pixels) ------------------------------------------------------
def note(big, x, y, w, h, label, side="below"):
    """A pink bracket round canvas rect (x, y, w, h) and its label, in points."""
    c = P["note"]
    X, Y, X2, Y2 = int(x * K), int(y * K), int((x + w) * K), int((y + h) * K)
    t = 3
    for (ax, ay, aw, ah) in ((X, Y, X2 - X, t), (X, Y2 - t, X2 - X, t), (X, Y, t, Y2 - Y), (X2 - t, Y, t, Y2 - Y)):
        big.rect(ax, ay, aw, ah, c)
    tw = text_w(label) * 3
    if side == "below":
        lx, ly = X, Y2 + 6
    elif side == "above":
        lx, ly = X, Y - 39
    elif side == "right":
        lx, ly = X2 + 8, (Y + Y2) // 2 - 16
    else:
        lx, ly = X - tw - 14, (Y + Y2) // 2 - 16
    lx = max(4, min(lx, OUT_W - tw - 12))
    ly = max(4, min(ly, OUT_H - 36))
    big.rect(lx - 4, ly, tw + 10, 33, (20, 8, 24), 0.88)
    big.text(label, lx, ly, c, 3)


def caption(big, label):
    """A plain pink line at the bottom left, inside the safe area."""
    x, y = int(SAFE_X * K), OUT_H - 36 - int(SAFE_B * K)
    big.rect(x - 4, y, text_w(label) * 3 + 10, 33, (20, 8, 24), 0.88)
    big.text(label, x, y, P["note"], 3)


def pts(v):
    return "%d" % round(v * U)


# --- shared pieces ----------------------------------------------------------------------------------
def chip(cv, x, y, label, c=None, icon=None, w=None, h=13, edge=None):
    """A slim strip: padel's black 45 % bar, a 1 px edge, an icon and the 5x7 words."""
    tw = text_w(label)
    iw = 11 if icon else 0
    ww = w or (tw + iw + 9)
    cv.rect(x, y, ww, h, P["ink"], 0.86)
    cv.rect(x, y, ww, 1, edge or P["slate_l"])
    cv.rect(x, y + h - 1, ww, 1, P["void"], 0.6)
    if icon:
        icon(cv, x + 3, y + 2)
    cv.text(label, x + 4 + iw, y + 1, c or P["line"])
    return ww


def icon_bill(cv, x, y):
    cv.rect(x, y, 7, 9, P["paper"])
    for i in range(0, 7, 2):
        cv.pset(x + i, y + 9, P["paper"])
    cv.rect(x + 1, y + 2, 5, 1, P["paper_d"])
    cv.rect(x + 1, y + 4, 3, 1, P["paper_d"])
    cv.rect(x + 1, y + 6, 5, 1, P["wood_d"])


def icon_wallet(cv, x, y):
    cv.rect(x, y + 1, 9, 7, P["wood"])
    cv.rect(x, y + 1, 9, 2, P["wood_l"])
    cv.rect(x + 5, y + 4, 4, 3, P["wood_d"])
    cv.pset(x + 6, y + 5, P["gold"])


def mug(cv, x, y, beer=None, s=1):
    """A 9x11 pint with a handle and a head (the tap list's glass and the PIWKO icon)."""
    beer = beer or P["beer"]
    cv.rect(x, y + 2 * s, 7 * s, 9 * s, beer)
    cv.rect(x, y + 2 * s, 2 * s, 9 * s, tuple(min(255, int(v * 1.18)) for v in beer))
    cv.rect(x - 1 * s, y, 9 * s, 3 * s, P["foam"])
    cv.rect(x + 1 * s, y - 1 * s, 3 * s, 1 * s, P["foam"])
    cv.rect(x + 7 * s, y + 4 * s, 2 * s, 1 * s, P["line"])
    cv.rect(x + 8 * s, y + 5 * s, 1 * s, 3 * s, P["line"])
    cv.rect(x + 7 * s, y + 8 * s, 2 * s, 1 * s, P["line"])
    cv.rect(x, y + 10 * s, 7 * s, 1 * s, tuple(int(v * 0.7) for v in beer))


def cup(cv, cx, top, a=1.0):
    """A red party cup, 9 px wide at the rim, 13 px tall, seen from the side; `cx` its centre."""
    cv.rect(cx - 4, top, 9, 2, P["line"], a)
    cv.rect(cx - 4, top + 2, 9, 5, P["cup"], a)
    cv.rect(cx - 3, top + 7, 7, 6, P["cup"], a)
    cv.rect(cx - 4, top + 2, 1, 5, P["cup_l"], a)
    cv.rect(cx - 3, top + 7, 1, 6, P["cup_l"], a)
    cv.rect(cx + 3, top + 2, 2, 5, P["cup_d"], a)
    cv.rect(cx + 2, top + 7, 2, 6, P["cup_d"], a)
    cv.rect(cx - 3, top + 4, 6, 1, P["cup_d"], a * 0.6)


def tulip(cv, cx, top):
    """Pan Hubert's tasting glass: a 7 px bowl (a 5 px mouth), a stem and a foot, 13 px tall."""
    cv.rect(cx - 2, top, 5, 1, P["line"])
    cv.rect(cx - 3, top + 1, 7, 6, P["beer"])
    cv.rect(cx - 2, top + 1, 5, 2, P["foam"])
    cv.rect(cx - 3, top + 1, 1, 6, P["amber_l"])
    cv.rect(cx - 2, top + 7, 5, 1, P["beer"])
    cv.rect(cx, top + 8, 1, 4, P["line"])
    cv.rect(cx - 2, top + 12, 5, 1, P["line"])


def ball(cv, x, y):
    cv.rect(x - 1, y - 1, 3, 3, P["ball"])
    cv.pset(x - 1, y - 1, (255, 255, 255))
    cv.pset(x + 1, y + 1, tuple(int(v * 0.65) for v in P["ball"]))


def glow(cv, cx, cy, r, c, a=0.10):
    for k in range(3):
        cv.disc(cx, cy, r * (1 - k * 0.28), r * (1 - k * 0.28), c, a)


def bubble(cv, x, y, w, name, lines, tail_x, tail_dir=1, name_c=None):
    """A speech bubble: a dark card with a 1 px light edge, the speaker's name on an amber tab."""
    h = 6 + len(lines) * 10
    cv.rect(x + 1, y, w - 2, h, P["ink"], 0.92)
    cv.rect(x, y + 1, w, h - 2, P["ink"], 0.92)
    cv.rect(x + 1, y, w - 2, 1, P["chalk_d"])
    cv.rect(x + 1, y + h - 1, w - 2, 1, P["chalk_d"])
    cv.rect(x, y + 1, 1, h - 2, P["chalk_d"])
    cv.rect(x + w - 1, y + 1, 1, h - 2, P["chalk_d"])
    for i in range(4):
        cv.rect(tail_x + (i if tail_dir > 0 else -i), y + h - 1 + i, 4 - i, 1, P["ink"], 0.92)
        cv.pset(tail_x + (i if tail_dir > 0 else -i) + (3 - i if tail_dir < 0 else 0) + (0 if tail_dir < 0 else 0), y + h + i, P["chalk_d"], 0.0)
    if name:
        nw = text_w(name) + 6
        cv.rect(x + 5, y - 6, nw, 9, name_c or P["amber"])
        cv.text(name, x + 8, y - 7, P["ink"])
    for i, ln in enumerate(lines):
        cv.text(ln, x + 5, y + 2 + i * 10, P["line"])
    return h


def tag(cv, cx, cy, label, icon, primary=True, point_to=None):
    """An action tile floating over an object in the room: 25x25 (45 pt), the word under it."""
    x, y = cx - 12, cy - 12
    edge = P["gold"] if primary else P["chalk_d"]
    cv.rect(x + 1, y, 23, 25, P["ink"], 0.94)
    cv.rect(x, y + 1, 25, 23, P["ink"], 0.94)
    cv.rect(x + 1, y, 23, 1, edge)
    cv.rect(x + 1, y + 24, 23, 1, edge)
    cv.rect(x, y + 1, 1, 23, edge)
    cv.rect(x + 24, y + 1, 1, 23, edge)
    icon(cv, x, y)
    tw = text_w(label)
    cv.rect(cx - tw // 2 - 3, y + 26, tw + 6, 10, P["ink"], 0.86)
    cv.text(label, cx, y + 25, edge, centre=True)
    if point_to:
        px, py = point_to
        steps = max(abs(px - cx), abs(py - (y + 37)))
        for i in range(0, steps, 3):
            t = i / max(steps, 1)
            cv.pset(cx + (px - cx) * t, y + 37 + (py - y - 37) * t, edge)


def icon_beer(cv, x, y):
    mug(cv, x + 8, y + 8)


def icon_pong(cv, x, y):
    cup(cv, x + 9, y + 9)
    ball(cv, x + 17, y + 6)
    cv.pset(x + 14, y + 4, P["gold"])
    cv.pset(x + 12, y + 5, P["gold"])


def icon_door(cv, x, y):
    cv.rect(x + 6, y + 5, 9, 15, P["wood"])
    cv.rect(x + 6, y + 5, 9, 1, P["wood_l"])
    cv.rect(x + 7, y + 7, 7, 5, P["wood_d"])
    cv.pset(x + 13, y + 14, P["gold"])
    for i in range(3):
        cv.rect(x + 17 + i, y + 12 - i, 1, 1 + i * 2, P["line"])
    cv.rect(x + 15, y + 12, 3, 1, P["line"])


def button(cv, x, y, w, label, primary=True, h=25):
    bg = P["gold"] if primary else P["slate"]
    fg = P["ink"] if primary else P["line"]
    cv.rect(x + 1, y, w - 2, h, bg)
    cv.rect(x, y + 1, w, h - 2, bg)
    cv.rect(x + 1, y + h - 3, w - 2, 2, tuple(int(v * 0.78) for v in bg))
    cv.rect(x + 1, y + 1, w - 2, 1, tuple(min(255, int(v * 1.15) + 10) for v in bg))
    cv.text(label, x + w // 2, y + h // 2 - 6, fg, centre=True)


def chibi(cv, cx, foot, face, kind, arm=-0.5, hold=None, sway=0):
    """A table-side figure, about 58 px: padel's chibi construction (rects, a shaded shirt) drawn larger."""
    kinds = {
        "you": dict(shirt=P["us"], shirt_d=P["us_d"], skin=P["skin1"], hair=P["hair_br"]),
        "gienia": dict(shirt=P["them"], shirt_d=P["them_d"], skin=P["skin2"], hair=P["hair_gr"]),
        "hubert": dict(shirt=P["them"], shirt_d=P["them_d"], skin=P["skin3"], hair=P["hair_bk"]),
        "crew": dict(shirt=P["them"], shirt_d=P["them_d"], skin=P["skin1"], hair=P["hair_bl"]),
    }
    k = kinds[kind]
    short = 4 if kind == "gienia" else 0
    x, y = cx + sway, foot
    cv.disc(cx, foot, 12, 2, (0, 0, 0), 0.35)
    # legs and shoes
    cv.rect(x - 7, y - 16, 6, 14, P["jeans"] if kind != "gienia" else P["purple"])
    cv.rect(x + 1, y - 16, 6, 14, P["jeans"] if kind != "gienia" else P["purple"])
    cv.rect(x - 8 + (1 if face > 0 else 0), y - 3, 8, 3, P["line"])
    cv.rect(x + (1 if face > 0 else 0), y - 3, 8, 3, P["line"])
    # torso
    top = y - 38 + short
    cv.rect(x - 9, top, 18, 23 - short, k["shirt"])
    cv.rect(x - 9 if face > 0 else x + 4, top, 5, 23 - short, k["shirt_d"])
    if kind == "you":      # the hoodie's pocket and strings
        cv.rect(x - 4, top + 13, 9, 5, k["shirt_d"])
        cv.rect(x + 2 * face, top + 1, 1, 6, P["line"])
    if kind == "gienia":   # a cardigan over a cream blouse, pearls
        cv.rect(x - 2 + 3 * face, top, 5, 19, P["pearl"])
        for i in range(3):
            cv.pset(x - 1 + 3 * face + i * 2, top + 2 + (i % 2), P["chalk_d"])
    if kind == "hubert":   # a waistcoat, a bow tie
        cv.rect(x - 3 + 3 * face, top, 7, 23, P["ink"])
        cv.rect(x - 1 + 3 * face, top + 2, 3, 2, P["alert"])
    # head
    hy = top - 20
    cv.rect(x - 9, hy + 1, 18, 18, k["skin"])
    cv.rect(x - 8, hy, 16, 20, k["skin"])
    cv.rect(x - 9 if face > 0 else x + 6, hy + 2, 3, 16, tuple(int(v * 0.88) for v in k["skin"]))
    ex = x + 4 * face
    cv.rect(ex, hy + 9, 2, 3, P["ink"])
    cv.rect(ex - 5 * face, hy + 9, 2, 3, P["ink"])
    cv.rect(x + 2 * face - 1, hy + 15, 4, 1, tuple(int(v * 0.7) for v in k["skin"]))
    if kind == "you":
        cv.rect(x - 9, hy - 2, 18, 6, k["hair"])
        cv.rect(x - 10 if face > 0 else x + 7, hy, 3, 10, k["hair"])
        cv.rect(x + 3 * face - 1, hy + 3, 6, 2, k["hair"])
    elif kind == "gienia":
        cv.rect(x - 9, hy - 2, 18, 6, k["hair"])
        cv.rect(x - 10, hy + 1, 3, 9, k["hair"])
        cv.rect(x + 7, hy + 1, 3, 9, k["hair"])
        cv.disc(x - 7 * face, hy - 4, 4, 4, k["hair"])           # the bun
        cv.rect(x - 9 * face - 1, hy - 5, 2, 1, P["alert"])       # its pin
        for gx in (ex - 1, ex - 5 * face - 1):                     # the glasses
            cv.rect(gx - 1, hy + 7, 6, 1, P["line"])
            cv.rect(gx - 1, hy + 13, 6, 1, P["line"])
            cv.rect(gx - 1, hy + 7, 1, 7, P["line"])
            cv.rect(gx + 4, hy + 7, 1, 7, P["line"])
    elif kind == "hubert":
        cv.rect(x - 9, hy - 1, 18, 4, k["hair"])
        cv.rect(x - 10 if face > 0 else x + 7, hy, 3, 12, k["hair"])
        cv.rect(x + 1 * face - 2, hy + 13, 8, 2, k["hair"])       # the moustache
        cv.rect(x + 2 * face - 1, hy + 17, 4, 3, k["hair"])       # the goatee
    else:
        cv.rect(x - 9, hy - 2, 18, 5, k["hair"])
        cv.rect(x - 4, top + 1, 1, 12, P["gold"])                 # the lanyard
        cv.rect(x - 5, top + 13, 4, 5, P["line"])
    # the throwing arm
    sx, sy = x + 7 * face, top + 4
    hx, hyy = sx + math.cos(arm) * 15 * face, sy + math.sin(arm) * 15
    for o in (-1, 0, 1):
        cv.line(sx, sy + o, hx, hyy + o, k["shirt"])
    cv.rect(hx - 2, hyy - 2, 5, 5, k["skin"])
    if hold == "ball":
        ball(cv, int(hx + 2 * face), int(hyy - 3))
    return (int(hx + 2 * face), int(hyy - 3))


def bust(cv, x, y, who, s=1, ring=None):
    """A 32x32 portrait tile (the rival card, the score strip at 20 px, the result at 2x)."""
    def r(ax, ay, aw, ah, c, a=1.0):
        cv.rect(x + ax * s, y + ay * s, aw * s, ah * s, c, a)
    spec = {
        "you": (P["us"], P["us_d"], P["skin1"], P["hair_br"], P["night1"]),
        "gienia": (P["them"], P["them_d"], P["skin2"], P["hair_gr"], P["brick_d"]),
        "hubert": (P["ink"], P["slate_d"], P["skin3"], P["hair_bk"], P["wood_d"]),
        "crew": (P["line"], P["chalk_d"], P["skin1"], P["hair_bl"], P["slate_d"]),
        "kuba": (P["ink"], P["slate_d"], P["skin4"], P["hair_bk"], P["wood_d"]),
    }[who]
    shirt, shirt_d, skin, hair, bg = spec
    r(0, 0, 32, 32, bg)
    r(0, 22, 32, 10, tuple(int(v * 0.75) for v in bg))
    r(5, 24, 22, 8, shirt)
    r(5, 24, 5, 8, shirt_d)
    r(13, 21, 6, 4, tuple(int(v * 0.85) for v in skin))
    r(9, 7, 14, 15, skin)
    r(8, 9, 16, 11, skin)
    r(8, 9, 2, 11, tuple(int(v * 0.88) for v in skin))
    r(12, 13, 2, 3, P["ink"])
    r(18, 13, 2, 3, P["ink"])
    r(14, 18, 5, 1, tuple(int(v * 0.65) for v in skin))
    if who == "you":
        r(8, 4, 16, 6, hair)
        r(7, 7, 3, 7, hair)
        r(17, 9, 6, 2, hair)
        r(14, 25, 1, 5, P["line"])
        r(17, 25, 1, 5, P["line"])
    elif who == "gienia":
        r(8, 4, 16, 6, hair)
        r(7, 6, 3, 9, hair)
        r(22, 6, 3, 9, hair)
        r(13, 0, 7, 5, hair)
        r(19, 1, 2, 1, P["alert"])
        for gx in (10, 17):
            r(gx, 12, 6, 1, P["line"])
            r(gx, 16, 6, 1, P["line"])
            r(gx, 12, 1, 5, P["line"])
            r(gx + 5, 12, 1, 5, P["line"])
        r(16, 13, 1, 1, P["line"])
        r(13, 24, 6, 8, P["pearl"])
        for i in range(4):
            r(11 + i * 3, 24 + (i % 2), 1, 1, P["pearl"])
        r(14, 18, 5, 1, P["alert"])
    elif who == "hubert":
        r(8, 5, 16, 4, hair)
        r(7, 7, 3, 9, hair)
        r(22, 7, 3, 9, hair)
        r(11, 17, 10, 2, hair)
        r(14, 20, 4, 3, hair)
        r(13, 24, 6, 8, P["line"])
        r(14, 25, 4, 2, P["alert"])
        r(24, 16, 5, 1, P["line"])       # the tasting glass he never puts down
        r(24, 17, 5, 5, P["beer"])
        r(26, 22, 1, 4, P["line"])
    elif who == "crew":
        r(8, 5, 16, 5, hair)
        r(13, 24, 1, 8, P["gold"])
        r(18, 24, 1, 8, P["gold"])
        r(0, 14, 5, 10, P["skin3"])      # two more heads behind: it's a crew
        r(0, 12, 5, 3, P["hair_bk"])
        r(27, 15, 5, 9, P["skin2"])
        r(27, 13, 5, 3, P["hair_br"])
    elif who == "kuba":
        r(8, 4, 16, 5, hair)
        r(8, 17, 16, 5, hair)            # the beard
        r(14, 18, 5, 1, skin)
        r(5, 24, 22, 8, P["wood_d"])     # the apron
        r(13, 24, 6, 8, P["line"])
    if ring:
        cv.rect(x - s, y - s, 32 * s + 2 * s, s, ring)
        cv.rect(x - s, y + 32 * s, 32 * s + 2 * s, s, ring)
        cv.rect(x - s, y - s, s, 32 * s + 2 * s, ring)
        cv.rect(x + 32 * s, y - s, s, 32 * s + 2 * s, ring)


def mini(cv, x, y, shirt, hair, skin=None, sit=False):
    """Padel's own 18 px chibi (the room's people at the room's scale)."""
    skin = skin or P["skin1"]
    if not sit:
        cv.rect(x - 3, y - 5, 2, 5, P["jeans"])
        cv.rect(x + 1, y - 5, 2, 5, P["jeans"])
    cv.rect(x - 3, y - 12 + (3 if sit else 0), 6, 7 - (0 if not sit else 1), shirt)
    cv.rect(x - 3, y - 12 + (3 if sit else 0), 2, 6, tuple(int(v * 0.8) for v in shirt))
    hy = y - 18 + (3 if sit else 0)
    cv.rect(x - 3, hy, 6, 6, skin)
    cv.rect(x - 3, hy - 1, 6, 2, hair)
    cv.pset(x + 1, hy + 3, P["ink"])


# --- the pub's wall and floor, side-on (the pong screen's backdrop) --------------------------------
def bricks(cv, x, y, w, h, seed=1):
    cv.rect(x, y, w, h, P["brick"])
    r = seed
    for row in range(0, h, 5):
        cv.rect(x, y + row + 4, w, 1, P["mortar"])
        off = 0 if (row // 5) % 2 == 0 else 6
        for bx in range(-off, w, 12):
            cv.rect(x + bx + 11, y + row, 1, 4, P["mortar"])
            r = (r * 1103515245 + 12345) & 0x7FFFFFFF
            if r % 7 == 0:
                cv.rect(x + max(bx, 0), y + row, min(11, w - bx), 4, P["brick_l"])
            elif r % 5 == 0:
                cv.rect(x + max(bx, 0), y + row, min(11, w - bx), 4, P["brick_d"])


def lamp(cv, x, y, drop=12):
    cv.rect(x, 9, 1, y - 9 + drop - 6, P["ink"])
    glow(cv, x, y + drop, 15, P["amber_l"], 0.09)
    cv.rect(x - 2, y + drop - 6, 5, 2, P["copper"])
    cv.rect(x - 3, y + drop - 4, 7, 6, P["amber"])
    cv.rect(x - 2, y + drop - 3, 2, 4, P["amber_l"])
    cv.rect(x - 2, y + drop + 2, 5, 1, P["amber"])


def pub_backdrop(cv):
    """The wall behind the pong table: brick, the black soffit and its ducts, lamps, the tap board,
    the concrete with BREW ENJOY EMPTY REPEAT, the regulars at the back, the slate floor."""
    bricks(cv, 0, 9, W, 122)
    cv.rect(0, 0, W, 9, P["frame"])
    cv.rect(0, 9, W, 2, P["void"])
    for dx in range(40, W, 150):                           # the silver ducts under the black ceiling
        cv.rect(dx, 2, 96, 4, P["concrete"])
        cv.rect(dx, 2, 96, 1, P["chrome"])
        for j in range(dx + 10, dx + 96, 14):
            cv.rect(j, 2, 1, 4, P["concrete_d"])
    # the concrete panel and its words
    cx = W - 150
    cv.rect(cx, 11, 124, 96, P["concrete"])
    cv.rect(cx, 11, 124, 1, P["chrome"])
    cv.rect(cx, 106, 124, 1, P["concrete_d"])
    for j in (cx + 41, cx + 82):
        cv.rect(j, 11, 1, 96, P["concrete_d"])
    for i, word in enumerate(("BREW", "ENJOY", "EMPTY", "REPEAT")):
        yy = 16 + i * 22
        w1 = text_w(word[0]) * 2
        cv.text(word[0], cx + 12, yy, P["line"], 2)
        cv.text(word[1:], cx + 12 + w1 + 2, yy, P["concrete_d"], 2)
    # the chalk tap board on the brick
    bx = 118
    cv.rect(bx - 2, 30, 112, 62, P["wood_d"])
    cv.rect(bx, 32, 108, 58, P["board"])
    cv.text("NA KRANIE", bx + 54, 33, P["chalk"], centre=True)
    cv.rect(bx + 26, 44, 56, 1, P["amber"])
    for i, (nm, pr) in enumerate((("MĘTNA SPRAWA", "28"), ("CZARNA OWCA", "32"), ("KWAŚNA MINA", "24"), ("DLA TEŚCIA", "16"))):
        cv.text(nm, bx + 5, 46 + i * 11, P["chalk_d"])
        cv.text(pr, bx + 103 - text_w(pr), 46 + i * 11, P["amber"])
    # the porthole
    cv.disc(64, 60, 15, 15, P["copper"])
    cv.disc(64, 60, 12, 12, P["night1"])
    cv.disc(60, 56, 4, 4, P["night2"])
    cv.rect(52, 60, 25, 1, P["copper"])
    cv.rect(64, 48, 1, 25, P["copper"])
    for lx in (38, 96, 258, 292):
        lamp(cv, lx, 14, 12 if lx != 96 else 16)
    # the wainscot and the floor
    cv.rect(0, 107, W, 24, P["wood_d"])
    cv.rect(0, 107, W, 2, P["wood"])
    for j in range(0, W, 23):
        cv.rect(j, 109, 1, 22, P["mortar"])
    cv.rect(0, 131, W, H - 131, P["slate"])
    cv.rect(0, 131, W, 2, P["slate_d"])
    for i, yy in enumerate((146, 166, 190)):
        cv.rect(0, yy, W, 1, P["slate_d"])
    for j in range(-40, W + 40, 46):
        cv.line(j, 216, j + (W / 2 - j) * 0.25, 131, P["slate_d"])
    # the regulars at the back table (dim, like padel's crowd behind the fence)
    cv.rect(176, 121, 60, 3, P["wood"])
    cv.rect(180, 124, 2, 9, P["wood_d"])
    cv.rect(230, 124, 2, 9, P["wood_d"])
    for i, (px, sh, hr) in enumerate(((168, P["purple"], P["hair_bk"]), (190, P["concrete"], P["hair_br"]), (224, P["go"], P["hair_bl"]), (244, P["brick_l"], P["hair_bk"]))):
        mini(cv, px, 134, tuple(int(v * 0.72) for v in sh), hr, tuple(int(v * 0.8) for v in P["skin2"]), sit=True)
    mug(cv, 198, 111)
    mug(cv, 214, 111, P["wood_d"])


TABLE_X0, TABLE_X1, TABLE_Y = 92, 375, 152
MY_CUPS = [106 + i * 14 for i in range(5)]
THEIR_CUPS = [305 + i * 14 for i in range(5)]


def pong_table(cv, mine, theirs, glasses=False):
    cv.disc((TABLE_X0 + TABLE_X1) // 2, 205, 150, 4, (0, 0, 0), 0.3)
    for lx in (TABLE_X0 + 12, TABLE_X1 - 16):
        cv.rect(lx, TABLE_Y + 6, 4, 50, P["concrete_d"])
        cv.rect(lx, TABLE_Y + 6, 1, 50, P["concrete"])
    cv.rect(TABLE_X0 + 14, TABLE_Y + 30, TABLE_X1 - TABLE_X0 - 28, 2, P["concrete_d"])
    cv.rect(TABLE_X0, TABLE_Y, TABLE_X1 - TABLE_X0, 6, P["frame"])
    cv.rect(TABLE_X0, TABLE_Y, TABLE_X1 - TABLE_X0, 1, P["line"])
    cv.rect(TABLE_X0, TABLE_Y + 5, TABLE_X1 - TABLE_X0, 1, P["void"])
    cv.rect((TABLE_X0 + TABLE_X1) // 2, TABLE_Y + 1, 1, 4, P["line"])
    for i in mine:
        cup(cv, MY_CUPS[i], TABLE_Y - 13)
    for i in theirs:
        (tulip if glasses else cup)(cv, THEIR_CUPS[i], TABLE_Y - 13)


def score_strip(cv, you, them, name, rnd, stake, who):
    """The top row: RUNDA chip, the score with cup pips and two 20 px busts, the stake, the quit ring."""
    chip(cv, SAFE_X, 4, "RUNDA %d/8" % rnd)
    mid = W // 2
    s = "TY  %d : %d  %s" % (you, them, name)
    tw = text_w(s)
    cv.rect(mid - tw // 2 - 34, 4, tw + 68, 13, P["ink"], 0.86)
    cv.rect(mid - tw // 2 - 34, 4, tw + 68, 1, P["slate_l"])
    cv.text(s, mid, 5, P["line"], centre=True)
    for i in range(5):
        cv.rect(mid - tw // 2 - 30 + i * 5, 9, 3, 3, P["us"] if i < you else P["slate_l"])
        cv.rect(mid + tw // 2 + 28 - i * 5, 9, 3, 3, P["them"] if i < them else P["slate_l"])
    sw = text_w("%d ZŁ" % stake) + 9
    chip(cv, W - SAFE_X - 30 - sw, 4, "%d ZŁ" % stake, P["gold"])
    return W - SAFE_X - 30 - sw, sw


def quit_ring(big, cx_pt_from_right=34, cy_pt=34):
    """Padel's own quit control, drawn at the phone's resolution: a 20 pt disc with a cross."""
    cx, cy, r = OUT_W - int((47 + cx_pt_from_right - 14) * PT), int(cy_pt * PT), int(20 * PT)
    big.disc(cx, cy, r, r, (0, 0, 0), 0.45)
    for i in range(-16, 17):
        for t in range(-2, 3):
            big.pset(cx + i + t, cy + i, (255, 255, 255), 0.95)
            big.pset(cx + i + t, cy - i, (255, 255, 255), 0.95)
    return cx, cy, r


# --- screen 2: the aim ---------------------------------------------------------------------------
def screen_aim(notes):
    cv = Canvas(W, H, P["void"])
    pub_backdrop(cv)
    theirs = [1, 3, 4]
    pong_table(cv, [0, 1, 2, 4], theirs)
    # Pani Gienia at the far end, her line in a bubble
    chibi(cv, 408, 206, -1, "gienia", arm=0.9)
    bubble(cv, 352, 84, 92, "PANI GIENIA", ["OJEJ, WPADŁO!", "SAMO!"], 404, 1, P["them"])
    # you, the arm swung forward, the ball in the hand
    hand = chibi(cv, 62, 206, 1, "you", arm=-0.75, hold="ball")
    # the swing's track under the table's lip: the breath is the track itself
    lo, hi = THEIR_CUPS[0] - 24, THEIR_CUPS[4] + 14
    cv.rect(lo, TABLE_Y + 9, hi - lo, 1, P["slate_l"])
    cv.rect(lo, TABLE_Y + 8, 1, 3, P["chalk_d"])
    cv.rect(hi, TABLE_Y + 8, 1, 3, P["chalk_d"])
    breath_w = 46
    cv.rect(lo, TABLE_Y + 12, hi - lo, 3, P["slate_d"])
    cv.rect(lo, TABLE_Y + 12, breath_w, 3, P["them"])
    cv.rect(lo, TABLE_Y + 12, breath_w, 1, P["line"], 0.5)
    cv.text("ODDECH", lo, TABLE_Y + 15, P["chalk_d"])
    # the ring over the cups' mouths, coming up to the far cup; a faint double (one drink)
    rx, ry = THEIR_CUPS[4] - 5, TABLE_Y - 14
    cv.ring(rx + 3, ry, 6, 2, P["gold"], 0.35)
    cv.ring(rx, ry, 6, 2, P["gold"])
    cv.rect(rx, ry - 1, 1, 3, P["gold"])
    cv.rect(rx, TABLE_Y + 7, 1, 5, P["gold"])
    for i in range(3):                                     # which way it is swinging
        cv.rect(rx + 9 + i * 3, ry - 6, 2, 1, P["gold"], 0.9 - i * 0.25)
    # the dotted arc from the hand to the ring
    x0, y0 = hand
    apex = 74
    n = 64
    for i in range(1, n):
        t = i / n
        ax = x0 + (rx - x0) * t
        ay = (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * (2 * apex - (y0 + ry) / 2) + t * t * ry
        if i % 2 == 0:
            cv.rect(ax, ay, 2, 2, P["gold"], 0.95 if i < n - 6 else 0.6)
    # the strips
    sx, sw = score_strip(cv, 2, 1, "GIENIA", 3, 150, "gienia")
    bx = SAFE_X + text_w("RUNDA 3/8") + 13
    cv.rect(bx, 4, 43, 13, P["ink"], 0.86)
    cv.rect(bx, 4, 43, 1, P["slate_l"])
    ball(cv, bx + 6, 10)
    cv.ring(bx + 14, 10, 2, 2, P["chalk_d"])
    mug(cv, bx + 23, 6, s=1)
    cv.text("1", bx + 35, 5, P["amber"])
    hint = "PRZYTRZYMAJ: ODDECH · PUŚĆ: RZUT"
    hw = text_w(hint)
    cv.rect(W // 2 - hw // 2 - 4, H - SAFE_B - 13, hw + 8, 12, P["ink"], 0.8)
    cv.text(hint, W // 2, H - SAFE_B - 13, P["line"], centre=True)
    notes += [
        (lambda b: note(b, SAFE_X, 4, text_w("RUNDA 3/8") + 9, 13, "STRIP H %s PT · 5x7 FONT, CAP %s PT" % (pts(13), pts(7)), "below")),
        (lambda b: note(b, MY_CUPS[4] - 5, TABLE_Y - 14, 10, 15, "CUP 9x13 PX = %sx%s PT" % (pts(9), pts(13)), "above")),
        (lambda b: note(b, rx - 7, ry - 3, 17, 6, "RING 13x5 PX · ITS DOUBLE = 1 DRINK", "above")),
        (lambda b: note(b, lo, TABLE_Y + 8, hi - lo + 1, 8, "SWING %s PX = %s PT · BREATH BAR UNDER IT" % (hi - lo, pts(hi - lo)), "below")),
        (lambda b: note(b, 43, 206 - 62, 38, 62, "FIGURE %s PT" % pts(58), "above")),
        (lambda b: note(b, bx, 4, 43, 13, "BALLS · DRINKS", "right")),
    ]
    return cv


def thumb(big, x_pt, y_pt, held=True):
    """Padel's touch look at the phone's resolution: a faint disc and a white ring where the thumb is."""
    cx, cy = int(x_pt * PT), int(y_pt * PT)
    r = int(30 * PT)
    big.disc(cx, cy, r, r, (255, 255, 255), 0.10)
    for k in range(4):
        big.ring(cx, cy, r - k, r - k, (255, 255, 255), 0.5)
    big.disc(cx, cy, int(13 * PT), int(13 * PT), (255, 255, 255), 0.28)


# --- screen 3: the win ---------------------------------------------------------------------------
def screen_result(notes):
    cv = Canvas(W, H, P["void"])
    pub_backdrop(cv)
    pong_table(cv, [0, 2], [])
    chibi(cv, 408, 206, -1, "gienia", arm=1.3)
    chibi(cv, 62, 203, 1, "you", arm=-1.15)
    ball(cv, THEIR_CUPS[2], TABLE_Y - 4)
    cv.rect(0, 0, W, H, P["void"], 0.62)
    # confetti in the two team colours and gold (padel's point burst)
    r = 11
    for i in range(70):
        r = (r * 1103515245 + 12345) & 0x7FFFFFFF
        px, py = r % W, (r >> 8) % 120
        cv.rect(px, py, 2, 1 + (r >> 4) % 2, (P["gold"], P["us"], P["them"], P["line"])[(r >> 12) % 4], 0.85)
    cv.text("WYGRANA!", W // 2, 14, P["gold"], 3, centre=True, shadow=True)
    # the card: her portrait and line on the left, the receipt on the right
    x0, y0, cw, ch = 96, 54, 275, 108
    cv.rect(x0 + 1, y0, cw - 2, ch, P["ink"], 0.95)
    cv.rect(x0, y0 + 1, cw, ch - 2, P["ink"], 0.95)
    cv.rect(x0 + 1, y0, cw - 2, 1, P["chalk_d"])
    cv.rect(x0 + 1, y0 + ch - 1, cw - 2, 1, P["void"])
    bust(cv, x0 + 10, y0 + 11, "gienia", 2, P["them"])
    cv.text("PANI GIENIA", x0 + 42, y0 + 78, P["them"], centre=True)
    cv.text("„PIERWSZY RAZ”", x0 + 42, y0 + 89, P["chalk_d"], centre=True)
    lines = wrap("NO PROSZĘ. NASTĘPNYM RAZEM NIE BĘDĘ TAKA GRZECZNA.", 92)
    for i, ln in enumerate(lines):
        cv.text(ln, x0 + 84, y0 + 8 + i * 10, P["line"])
    # the receipt
    rx, ry, rw, rh = x0 + 180, y0 + 8, 86, 88
    cv.rect(rx, ry, rw, rh, P["paper"])
    for i in range(0, rw, 4):
        cv.rect(rx + i, ry + rh, 2, 2, P["paper"])
    cv.text("THE TAPCZAN", rx + rw // 2, ry + 2, P["ink"], centre=True)
    cv.rect(rx + 5, ry + 14, rw - 10, 1, P["paper_d"])
    rows = [("KUBKI", "5 : 3"), ("STAWKA", "150 ZŁ"), ("WYPITE", "3"), ("RESPEKT", "+5")]
    for i, (a, b) in enumerate(rows):
        yy = ry + 16 + i * 11
        cv.text(a, rx + 5, yy, P["wood_d"])
        cv.text(b, rx + rw - 5 - text_w(b), yy, P["ink"])
    cv.rect(rx + 5, ry + 62, rw - 10, 1, P["paper_d"])
    for i in range(rx + 5, rx + rw - 5, 3):
        cv.pset(i, ry + 64, P["wood_d"])
    cv.text("RAZEM", rx + 5, ry + 66, P["ink"])
    cv.text("+150 ZŁ", rx + rw - 5 - text_w("+150 ZŁ"), ry + 66, P["us_d"])
    cv.rect(rx + 5, ry + 79, 30, 4, P["ink"])
    for i in range(rx + 38, rx + rw - 6, 2):
        cv.rect(i, ry + 79, 1, 4, P["ink"])
    # pips under her line: the cups
    for i in range(5):
        cup(cv, x0 + 90 + i * 12, y0 + 52, 1.0)
    for i in range(5):
        cup(cv, x0 + 90 + i * 12, y0 + 74, 1.0 if i < 3 else 0.22)
    cv.text("TY 5", x0 + 152, y0 + 54, P["us"])
    cv.text("ONA 3", x0 + 152, y0 + 76, P["them"])
    # the two buttons
    button(cv, W // 2 - 70, 170, 66, "REWANŻ", True)
    button(cv, W // 2 + 4, 170, 66, "DO BARU", False)
    chip(cv, SAFE_X, 4, "200 → 350 ZŁ", P["gold"], icon_wallet)
    notes += [
        (lambda b: note(b, W // 2 - 70, 170, 66, 25, "BUTTON 66x25 PX = %sx%s PT" % (pts(66), pts(25)), "below")),
        (lambda b: note(b, x0 + 10, y0 + 11, 64, 64, "BUST 32 PX ART AT 2x = %s PT" % pts(64), "left")),
        (lambda b: note(b, rx, ry, rw, rh + 2, "RECEIPT %sx%s PT" % (pts(rw), pts(rh)), "right")),
        (lambda b: note(b, x0, y0, cw, ch, "CARD %sx%s PT (%d %% OF THE SCREEN)" % (pts(cw), pts(ch), round(cw * ch * 100 / (W * H))), "below")),
        (lambda b: note(b, W // 2 - 73, 13, 146, 28, "CALLOUT: FONT x3, CAP %s PT" % pts(21), "right")),
    ]
    return cv


# --- screen 1: the room (a stand-in for the game's 3D cutaway) and the slim UI over it -------------
OX, OY = 214, 66
TW, TH, ZH = 10.0, 5.0, 9.0


def iso(x, y, z=0.0):
    return (OX + (x - y) * TW, OY + (x + y) * TH - z * ZH)


def box(cv, x0, y0, z0, x1, y1, z1, top, left, right):
    cv.poly([iso(x0, y1, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x0, y1, z1)], left)
    cv.poly([iso(x1, y0, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x1, y0, z1)], right)
    cv.poly([iso(x0, y0, z1), iso(x1, y0, z1), iso(x1, y1, z1), iso(x0, y1, z1)], top)


def dim(c, k):
    return tuple(int(v * k) for v in c)


def room(cv):
    """THE TAPCZAN's cutaway as the game draws it in 3D, redrawn flat for the mock: the brick wall
    with the bar, shelves and lamps, the concrete wall with its words, slate floor, tables, the
    pong table at the front, the door."""
    RX, RY, WH = 16.0, 11.0, 5.0
    # floor
    cv.poly([iso(0, 0), iso(RX, 0), iso(RX, RY), iso(0, RY)], P["slate"])
    for i in range(1, int(RX)):
        a, b = iso(i, 0), iso(i, RY)
        cv.line(a[0], a[1], b[0], b[1], P["slate_d"])
    for j in range(1, int(RY)):
        a, b = iso(0, j), iso(RX, j)
        cv.line(a[0], a[1], b[0], b[1], P["slate_d"])
    # wall A (y = 0): brick, lit warm near the bar
    cv.poly([iso(0, 0, 0), iso(RX, 0, 0), iso(RX, 0, WH), iso(0, 0, WH)], P["brick"])
    for k in range(1, 15):
        a, b = iso(0, 0, k * WH / 15), iso(RX, 0, k * WH / 15)
        cv.line(a[0], a[1], b[0], b[1], P["mortar"])
    for k in range(15):
        for i in range(0, 32):
            xx = i * 0.5 + (0.25 if k % 2 else 0.0)
            if xx < RX and (i * 7 + k * 3) % 5 == 0:
                a = iso(xx, 0, k * WH / 15 + 0.05)
                cv.rect(a[0], a[1] - 2, 4, 2, P["brick_l"] if (i + k) % 2 else P["brick_d"])
    a, b = iso(0, 0, WH), iso(RX, 0, WH)
    cv.line(a[0], a[1], b[0], b[1], P["copper_l"])
    # wall B (x = 0): concrete, the words
    cv.poly([iso(0, 0, 0), iso(0, RY, 0), iso(0, RY, WH), iso(0, 0, WH)], P["concrete_d"])
    for j in (3.7, 7.4):
        a, b = iso(0, j, 0), iso(0, j, WH)
        cv.line(a[0], a[1], b[0], b[1], dim(P["concrete_d"], 0.8))
    a, b = iso(0, 0, WH), iso(0, RY, WH)
    cv.line(a[0], a[1], b[0], b[1], P["concrete"])
    for i, word in enumerate(("BREW", "ENJOY", "EMPTY", "REPEAT")):
        base = iso(0, 9.6, 4.3 - i * 0.95)
        px, _ = text_pixels(word)
        first = text_w(word[0])
        for gx, gy in px:
            cv.pset(base[0] + gx, base[1] - gx * 0.5 + gy - 2, P["line"] if gx < first else P["concrete"])
    # the door in wall A (the way out): the night street behind an arch
    cv.poly([iso(13.0, 0, 0), iso(14.9, 0, 0), iso(14.9, 0, 2.7), iso(13.0, 0, 2.7)], P["wood_d"])
    cv.poly([iso(13.2, 0, 0), iso(14.7, 0, 0), iso(14.7, 0, 2.5), iso(13.2, 0, 2.5)], P["night1"])
    d = iso(14.2, 0, 1.5)
    glow(cv, d[0], d[1], 6, P["amber_l"], 0.12)
    cv.rect(d[0], d[1], 2, 2, P["amber"])
    # the back shelves, bottles and the amber lamps along wall A
    cv.poly([iso(1.5, 0, 1.3), iso(10.0, 0, 1.3), iso(10.0, 0, 3.3), iso(1.5, 0, 3.3)], P["wood_d"])
    for sh in (1.3, 2.0, 2.7):
        a, b = iso(1.5, 0, sh), iso(10.0, 0, sh)
        cv.line(a[0], a[1], b[0], b[1], P["wood"])
        for i in range(26):
            q = iso(1.7 + i * 0.32, 0, sh)
            cv.rect(q[0], q[1] - 3, 1, 3, (P["amber"], P["go"], P["line"], P["copper"], P["them"])[(i * 3 + int(sh * 10)) % 5])
    for i in range(6):
        q = iso(2.2 + i * 1.5, 0.4, 3.9)
        glow(cv, q[0], q[1] + 2, 9, P["amber_l"], 0.10)
        cv.rect(q[0] - 1, q[1], 3, 4, P["amber"])
        cv.pset(q[0] - 1, q[1] + 1, P["amber_l"])
    # the chalk soffit over the bar
    cv.poly([iso(1.5, 0, 4.0), iso(10.5, 0, 4.0), iso(10.5, 0, 4.7), iso(1.5, 0, 4.7)], P["board"])
    for i in range(12):
        q = iso(1.9 + i * 0.7, 0, 4.55)
        cv.rect(q[0], q[1], 4, 1, P["chalk_d"])
        cv.rect(q[0], q[1] + 2, 3, 1, P["amber"] if i % 3 == 0 else P["chalk_d"])
    # the barman behind the bar
    q = iso(5.2, 0.8, 0)
    mini(cv, int(q[0]), int(q[1]), P["ink"], P["hair_bk"], P["skin4"])
    # the bar: stone piers and slate, a copper-edged wooden top, two tap pipes
    box(cv, 1.5, 1.4, 0, 10.5, 2.3, 1.05, P["wood_l"], P["slate_d"], dim(P["slate_d"], 0.8))
    for i in range(5):
        a = iso(2.2 + i * 1.9, 2.3, 0)
        cv.rect(a[0] - 2, a[1] - 9, 5, 9, P["concrete_d"])
        cv.rect(a[0] - 2, a[1] - 9, 5, 1, P["concrete"])
    a, b = iso(1.5, 2.3, 1.05), iso(10.5, 2.3, 1.05)
    cv.line(a[0], a[1], b[0], b[1], P["copper_l"])
    for tx in (4.2, 7.6):
        q = iso(tx, 1.85, 1.05)
        cv.rect(q[0], q[1] - 9, 1, 9, P["chrome"])
        cv.rect(q[0] - 5, q[1] - 10, 11, 1, P["chrome"])
        for i in range(-2, 3):
            cv.rect(q[0] + i * 2, q[1] - 9, 1, 3, (P["amber"], P["alert"], P["line"], P["go"], P["them"])[i + 2])
    for sx in range(6):
        q = iso(2.3 + sx * 1.5, 3.0, 0)
        cv.rect(q[0] - 1, q[1] - 6, 3, 2, P["ink"])
        cv.rect(q[0], q[1] - 4, 1, 4, P["wood"])
    # tables with people
    people = [(P["purple"], P["hair_bk"]), (P["go"], P["hair_bl"]), (P["concrete"], P["hair_br"]), (P["alert"], P["hair_bk"]),
              (P["gold"], P["hair_br"]), (P["line"], P["hair_gr"]), (P["them_d"], P["hair_bl"]), (P["brick_l"], P["hair_bk"])]
    n = 0
    for (tx, ty) in ((3.0, 5.2), (6.0, 5.0), (3.2, 8.4), (6.4, 8.2), (9.4, 4.8)):
        for (dx, dy) in ((-0.9, 0.0), (0.0, -0.9)):
            q = iso(tx + dx + 0.4, ty + dy + 0.4, 0)
            mini(cv, int(q[0]), int(q[1]), people[n % 8][0], people[n % 8][1], sit=True)
            n += 1
        box(cv, tx, ty, 0.62, tx + 0.9, ty + 0.9, 0.75, P["wood_l"], P["wood"], P["wood_d"])
        q = iso(tx + 0.45, ty + 0.45, 0)
        cv.rect(q[0], q[1] - 6, 1, 6, P["wood_d"])
        q = iso(tx + 0.5, ty + 0.4, 0.75)
        cv.rect(q[0] - 1, q[1] - 3, 2, 3, P["beer"])
        cv.rect(q[0] - 1, q[1] - 4, 2, 1, P["foam"])
    # the pong table at the front, tonight's rivals by it
    for (dx, dy, sh, hr) in ((-0.5, -0.9, P["them"], P["hair_gr"]), (1.2, -0.9, P["them_d"], P["hair_bk"]), (2.9, -0.8, P["line"], P["hair_bl"])):
        q = iso(11.0 + dx, 7.4 + dy, 0)
        mini(cv, int(q[0]), int(q[1]), sh, hr)
    box(cv, 10.6, 7.4, 0.68, 13.1, 8.05, 0.76, P["frame"], P["void"], P["void"])
    a, b, c2, d2 = iso(10.6, 7.4, 0.76), iso(13.1, 7.4, 0.76), iso(13.1, 8.05, 0.76), iso(10.6, 8.05, 0.76)
    for (p, q2) in ((a, b), (b, c2), (c2, d2), (d2, a)):
        cv.line(p[0], p[1], q2[0], q2[1], P["line"])
    for ex in (10.85, 12.85):
        q = iso(ex, 7.72, 0.76)
        cv.rect(q[0] - 2, q[1] - 3, 4, 3, P["cup"])
        cv.rect(q[0] - 2, q[1] - 4, 4, 1, P["line"])
    for (lx, ly) in ((10.7, 8.0), (13.0, 8.0), (13.0, 7.45)):
        q = iso(lx, ly, 0)
        cv.rect(q[0], q[1] - 6, 1, 6, P["concrete_d"])
    # the cut edges of the floor (the cutaway's rim)
    a, b, c2 = iso(0, RY), iso(RX, RY), iso(RX, 0)
    cv.poly([a, b, (b[0], b[1] + 4), (a[0], a[1] + 4)], P["slate_d"])
    cv.poly([b, c2, (c2[0], c2[1] + 4), (b[0], b[1] + 4)], dim(P["slate_d"], 0.75))


def room_ui(cv, with_tags=True, with_bubble=True, piwko_on=False):
    x = SAFE_X
    x += chip(cv, x, 5, "THE TAPCZAN", P["amber"], edge=P["wood"]) + 3
    bill_x = x
    x += chip(cv, x, 5, "RACHUNEK 0 ZŁ", P["line"], icon_bill) + 3
    chip(cv, x, 5, "200 ZŁ", P["gold"], icon_wallet)
    out = {"bill": (bill_x, 5, x - 3 - bill_x, 13)}
    if with_bubble:
        q = iso(5.2, 0.8, 1.9)
        lines = wrap("DZIŚ NA KRANIE: IPA O SMAKU PONIEDZIAŁKU.", 132)
        bx, by = int(q[0]) - 138, int(q[1]) - 24 - len(lines) * 10 - 6
        hh = bubble(cv, bx, by, 142, "BARMAN KUBA", lines, int(q[0]) - 8, 1)
        out["bubble"] = (bx, by - 6, 142, hh + 6)
    if with_tags:
        t = iso(7.6, 1.85, 1.05)
        tag(cv, int(t[0]) + 14, int(t[1]) - 40, "PIWKO", icon_beer, True)
        out["tag"] = (int(t[0]) + 2, int(t[1]) - 52, 25, 25)
        t = iso(11.85, 7.7, 0.76)
        tag(cv, int(t[0]) + 2, int(t[1]) - 36, "GRAJ", icon_pong, True)
        t = iso(13.95, 0, 2.7)
        tag(cv, int(t[0]) + 4, int(t[1]) - 26, "WYJDŹ", icon_door, False)
    return out


def screen_room(notes):
    cv = Canvas(W, H, P["void"])
    room(cv)
    cv.cover = set()
    r = room_ui(cv)
    covered = len(cv.cover)
    cv.cover = None
    tg = r["tag"]
    bb = r["bubble"]
    notes += [
        (lambda b: note(b, SAFE_X, 5, 191, 13, "CHIPS H %s PT · 5x7 FONT · NOT BUTTONS" % pts(13), "right")),
        (lambda b: note(b, tg[0], tg[1], 25, 25, "TILE 25 PX = %s PT · HIT 40x37 PX = %sx%s PT" % (pts(25), pts(40), pts(37)), "right")),
        (lambda b: note(b, bb[0], bb[1], bb[2], bb[3], "BUBBLE %sx%s PT · GONE AFTER 4 S" % (pts(bb[2]), pts(bb[3])), "left")),
        (lambda b: caption(b, "UI COVERS %.1f %% OF THE SCREEN (WAS 52 %%) · 1 CANVAS PX = %.2f SCREEN PX = %.2f PT" % (covered * 100.0 / (W * H), K, U))),
    ]
    return cv, covered * 100.0 / (W * H)


TAPS = [("MĘTNA SPRAWA", "NEIPA · 6,5% · 0,4 L", 28, "#f2c14a"), ("CHMIEL, HONOR, OJCZYZNA", "WEST COAST IPA · 7% · 0,4 L", 26, "#e8962a"),
        ("CZARNA OWCA Z PRAGI", "IMPERIAL STOUT · 11% · 0,3 L", 32, "#3a2418"), ("KWAŚNA MINA", "MALINOWY SOUR · 4,2% · 0,4 L", 24, "#e0507a"),
        ("DLA TEŚCIA", "LAGER · 4,8% · 0,5 L", 16, "#f6dc6a"), ("TRZEŹWY KIEROWCA", "BEZALKOHOLOWE · 0% · 0,5 L", 12, "#cfe0a0")]


def screen_taps(notes):
    cv = Canvas(W, H, P["void"])
    room(cv)
    cv.cover = set()
    room_ui(cv, with_tags=False, with_bubble=False)
    q = iso(5.2, 0.8, 1.9)
    lines = wrap("MĘTNE JAK TWOJE PLANY NA ŻYCIE. DOBRY WYBÓR.", 118)
    bubble(cv, SAFE_X + 8, 34, 128, "BARMAN KUBA", lines, SAFE_X + 120, 1)
    # the chalkboard, docked right: a wooden frame, six rows
    bw, bh = 196, 22 + 6 * 26 + 6
    bx, by = W - SAFE_X - bw, 22
    cv.rect(bx - 3, by - 3, bw + 6, bh + 6, P["wood_d"])
    cv.rect(bx - 3, by - 3, bw + 6, 1, P["wood_l"])
    cv.rect(bx - 2, by - 2, bw + 4, bh + 4, P["wood"])
    cv.rect(bx, by, bw, bh, P["board"])
    r = 5
    for i in range(160):                                   # chalk dust
        r = (r * 1103515245 + 12345) & 0x7FFFFFFF
        cv.pset(bx + r % bw, by + (r >> 9) % bh, P["board_l"])
    cv.text("NA KRANIE", bx + 8, by + 3, P["chalk"], 1)
    cv.text("CO LEJEMY?", bx + 8 + text_w("NA KRANIE") + 8, by + 3, P["chalk_d"])
    for i in range(0, 58, 3):
        cv.rect(bx + 8 + i, by + 15 + (1 if (i // 3) % 2 else 0), 2, 1, P["amber"])
    cv.rect(bx + bw - 17, by + 4, 11, 11, P["board_l"])
    cv.text("x", bx + bw - 14, by + 2, P["chalk"])
    for i, (name, sub, price, colour) in enumerate(TAPS):
        yy = by + 22 + i * 26
        if i == 0:                                         # the row under the thumb: a gold tint and edge
            cv.rect(bx + 3, yy, bw - 6, 25, P["gold"], 0.16)
            cv.rect(bx + 3, yy, 1, 25, P["gold"])
        for j in range(bx + 6, bx + bw - 6, 3):
            cv.pset(j, yy + 25, P["chalk_d"], 0.5)
        mug(cv, bx + 9, yy + 7, rgb(colour))
        cv.text(name, bx + 24, yy + 2, P["chalk"])
        cv.text(sub, bx + 24, yy + 13, P["chalk_d"])
        ps = "%d ZŁ" % price
        cv.text(ps, bx + bw - 8 - text_w(ps), yy + 2, P["amber"])
    covered = (bw + 6) * (bh + 6)
    cv.cover = None
    notes += [
        (lambda b: note(b, bx + 3, by + 22 + 5 * 26, bw - 6, 25, "ROW %sx%s PT (THE WHOLE ROW IS THE BUTTON)" % (pts(bw - 6), pts(25)), "left")),
        (lambda b: note(b, bx - 3, by - 3, bw + 6, bh + 6, "BOARD %sx%s PT" % (pts(bw + 6), pts(bh + 6)), "above")),
        (lambda b: note(b, bx + bw - 24, by - 3, 25, 25, "CLOSE: HIT %s PT" % pts(25), "left")),
        (lambda b: caption(b, "THE BOARD COVERS %.0f %% WHILE OPEN · THE BAR STAYS IN VIEW" % (covered * 100.0 / (W * H)))),
    ]
    return cv


# --- screen 4: the sprite sheet -----------------------------------------------------------------
def screen_sprites(notes):
    cv = Canvas(W, H, P["slate_d"])
    cv.text("THE TAPCZAN · PONG V2 · SPRITES AND PALETTE (CANVAS PX)", SAFE_X, 4, P["line"])
    x = SAFE_X
    for who, nm in (("you", "TY"), ("gienia", "GIENIA"), ("hubert", "HUBERT"), ("crew", "EKIPA"), ("kuba", "KUBA")):
        bust(cv, x, 20, who, 1, P["them"] if who not in ("you", "kuba") else (P["us"] if who == "you" else P["amber"]))
        cv.text(nm, x + 16, 54, P["chalk_d"], centre=True)
        x += 44
    cv.text("BUSTS 32x32", SAFE_X, 66, P["note"])
    x = SAFE_X + 232
    for kind in ("you", "gienia", "hubert", "crew"):
        chibi(cv, x + 12, 82, 1 if kind == "you" else -1, kind, arm=-0.6 if kind == "you" else 0.9, hold="ball" if kind == "you" else None)
        x += 44
    cv.text("FIGURES ABOUT 58 PX, RECTS IN CODE", SAFE_X + 222, 86, P["note"])
    y = 104
    x = SAFE_X + 4
    cup(cv, x, y)
    tulip(cv, x + 16, y)
    ball(cv, x + 30, y + 6)
    cv.ring(x + 46, y + 6, 6, 2, P["gold"])
    mug(cv, x + 60, y + 1)
    icon_bill(cv, x + 78, y + 1)
    icon_wallet(cv, x + 92, y + 2)
    cv.text("CUP 9x13 · GLASS 7x13 · BALL 3x3 · RING 13x5 · MUG 9x11", SAFE_X, y + 18, P["note"])
    tag(cv, SAFE_X + 268, y + 6, "PIWKO", icon_beer)
    tag(cv, SAFE_X + 304, y + 6, "GRAJ", icon_pong)
    tag(cv, SAFE_X + 340, y + 6, "WYJDŹ", icon_door, False)
    button(cv, SAFE_X + 362, y - 8, 52, "REWANŻ")
    names = ["us", "us_d", "them", "them_d", "ball", "gold", "line", "frame", "court",
             "brick", "brick_l", "brick_d", "mortar", "wood", "wood_l", "wood_d", "copper", "copper_l",
             "amber", "amber_l", "beer", "foam", "cup", "cup_d", "cup_l", "board", "chalk", "chalk_d",
             "concrete", "concrete_d", "chrome", "paper", "skin1", "skin2", "skin3", "skin4"]
    for i, nm in enumerate(names):
        col, row = i % 18, i // 18
        px, py = SAFE_X + col * 23, 150 + row * 30
        cv.rect(px, py, 21, 12, P[nm])
        cv.rect(px, py + 12, 21, 1, P["void"])
        hexs = "%02X%02X%02X" % P[nm]
        cv.text(hexs[:3], px, py + 12, P["chalk_d"])
        cv.text(hexs[3:], px, py + 20, P["chalk_d"])
    cv.text("PALETTE: PADEL'S NINE FIRST, THEN THE PUB'S", SAFE_X, 138, P["note"])
    return cv


def main():
    plain = "--plain" in sys.argv
    jobs = [("1-room", screen_room), ("1b-taps", screen_taps), ("2-aim", screen_aim), ("3-result", screen_result), ("4-sprites", screen_sprites)]
    for name, fn in jobs:
        notes = []
        res = fn(notes)
        cv = res[0] if isinstance(res, tuple) else res
        big = upscale(cv)
        if name == "2-aim":
            thumb(big, 452, 306)
        if name in ("2-aim",):
            cx, cy, r = quit_ring(big)
            if not plain:
                note(big, (cx - 66) / K, (cy - 66) / K, 132 / K, 132 / K, "QUIT: 40 PT DISC, HIT 44 PT", "left")
        if name == "2-aim" and not plain:
            note(big, (452 * PT - 96) / K, (306 * PT - 96) / K, 192 / K, 192 / K, "THUMB ANYWHERE: HOLD = BREATH, LET GO = THROW", "left")
        if not plain:
            for n in notes:
                n(big)
        path = os.path.join(HERE, "tapczan-pong-v2-mock-%s.png" % name)
        write_png(path, big)
        extra = " (UI covers %.1f %%)" % res[1] if isinstance(res, tuple) else ""
        print("wrote %s%s" % (os.path.relpath(path, ROOT), extra))


if __name__ == "__main__":
    main()
