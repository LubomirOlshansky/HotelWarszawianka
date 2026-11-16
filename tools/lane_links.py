"""Lane links from turn:lanes (RT-2, docs/design/roads-true-to-life.md; TD-23): which lane of the
next street a car lands in after each lane of its own, and which exits each lane may take, written
into the lane graph so the game stops guessing at every junction.

    python3 -I tools/lane_links.py [MAP.json] [--dry] [--list]
        rewrites the map in place (a fixed point: run again it changes nothing); --dry measures and
        writes nothing; --list prints every link that changed with its `--at=`.

Why. lane_graph.gd `next_lane` guessed the lane after a junction: straight on it kept the lane's
number shifted by half the difference in lane counts, a turn took the outermost lane. Where the next
street's lanes do not sit where that number says (a street that widens on one side, a one-way half
of a dual road, two lanes that turn together), the car swerved across another lane's place inside
the junction: tools/road_truth.py rule R3 counted 403 such links on main (2026-11-13).

What, on the finished map data (bake_osm.py calls `apply(out)` after road_profiles; the same code
runs on main's map, as the cloud has no OpenStreetMap download):

1. `tl`, the lanes' turn codes. The map's own turn arrows ARE the ways' `turn:lanes` (bake_roads.py
   paints them from the tag, road_smooth's junction kit from the exits): the arrows of the row
   nearest an edge's end give each lane its code ("L", "T", "R", "TR", ...; "" for a lane with no
   arrow, which may take anything). An arrow is the lane's whose centre it is nearest.
2. The arrows painted from the same data: where a way's `turn:lanes` had more or fewer entries than
   the lanes the bake kept (lane_split drops a lane narrower than a car), the bake spread the
   arrows over the width and some stood between two lanes. Each such arrow moves onto its lane's
   centre, and two arrows that land in one lane become one with both codes. Inside the designed
   areas (road_design) the arrows stay where the design drew them.
3. `lk`, the links. For every exit f of edge e (not the way back), each lane k's landing lane j:
   - going on (a turn under TURN_MIN rad): the lanes keep their order, shifted by the one offset
     that puts them nearest to where their own lines lead (measured across the bisector, as
     road_truth R3 does), judged on the lanes that may go straight on (`tl` with a T, or no code);
     the old rule's shift wins a tie, so nothing moves without a reason;
   - turning, where two or more lanes may make that turn (`tl`): they land side by side from the
     outside lane in, the others take the outermost lane as before.
   Only the links that differ from the old rule are written: `lk` is flat [f, j0, j1, ..., f, ...]
   with one j per lane of e. lane_graph.gd `next_lane` reads them and keeps the old rule for the
   rest; `lane_allows` reads `tl` (traffic.gd: a town car in a left-turn lane turns left).

Nothing else moves: no kerb, lane line or edge geometry. Re-run tools/bake_sectors.py and
bake_city.gd after it (the arrows are in the sectors). Deterministic, standard library only.
"""
import json
import math
import os
import sys
from collections import defaultdict

KEY = "lane_links"
VERSION = 1
TURN_MIN = 0.6        # lane_graph.gd next_lane: a turn from here on takes the outer lane
THROUGH = 0.25        # road_truth.py: a link this straight is "straight on" (tl's T lanes judge it)
SLIGHT = 0.2          # lane_allows: an exit this far to a side counts as a turn to that side
ROW_REACH = 50.0      # m before an edge's end where its arrows stand (bake_roads: s1-7 and s1-38)
ROW_SAME = 3.0        # m: arrows this close along the edge are one row
SIDE_SLACK = 0.6      # m: an arrow up to this far outside the outer lanes' centres is still the edge's
ARROW_DIR = 0.9       # cos: an arrow points along its edge
ON_CENTRE = 0.3       # m: an arrow this close to its lane's centre is not moved
DESIGN_PAD = 25.0     # m round a designed area's ends where arrows are left alone
ORDER = "LTR"


def _pairs(p):
    return list(zip(p[0::2], p[1::2]))


class Edge:
    """One graph edge as lane_graph.gd reads it (seek, direction, mitred normals)."""

    def __init__(self, e):
        self.e = e
        self.P = _pairs(e["p"])
        cum = [0.0]
        for a, b in zip(self.P, self.P[1:]):
            cum.append(cum[-1] + math.dist(a, b))
        self.cum = cum
        self.len = cum[-1]
        self.n = int(e["n"])
        self.o = float(e["o"])
        self.lw = float(e["lw"])
        # the bake's own trims: tools/lane_changes.py (RT-4) stretches some links over a taper
        # and keeps the trims it replaced in `s0o`/`s1o`, so the links and arrows here are judged
        # where they were and this pass stays a fixed point of the map
        self.s0 = float(e.get("s0o", e["s0"]))
        self.s1 = max(float(e.get("s1o", e["s1"])), self.s0 + 0.1)
        self.nrm = self._normals()

    def _seg_dir(self, i):
        a, b = self.P[i], self.P[i + 1]
        ln = math.dist(a, b)
        return ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln) if ln > 1e-12 else (0.0, 0.0)

    def _normals(self):
        out = []
        n = len(self.P)
        for k in range(n):
            back = self._seg_dir(k - 1) if k > 0 else (0.0, 0.0)
            ahead = self._seg_dir(k) if k < n - 1 else (0.0, 0.0)
            if back == (0.0, 0.0):
                back = ahead
            if ahead == (0.0, 0.0):
                ahead = back
            r0 = (-back[1], back[0])
            r1 = (-ahead[1], ahead[0])
            mx, mz = r0[0] + r1[0], r0[1] + r1[1]
            ln = math.hypot(mx, mz)
            if ln < 1e-12:
                mx, mz = r1
            else:
                mx, mz = mx / ln, mz / ln
            d = max(mx * r1[0] + mz * r1[1], 0.5)
            out.append((mx / d, mz / d))
        return out

    def seek(self, s):
        i, last = 0, len(self.P) - 2
        while i < last and self.cum[i + 1] <= s:
            i += 1
        return i

    def direction(self, s):
        return self._seg_dir(self.seek(s))

    def point(self, s, off):
        i = self.seek(s)
        seg = self.cum[i + 1] - self.cum[i]
        t = min(max((s - self.cum[i]) / seg, 0.0), 1.0) if seg > 0.0001 else 0.0
        a, b = self.P[i], self.P[i + 1]
        na, nb = self.nrm[i], self.nrm[i + 1]
        return (a[0] + (b[0] - a[0]) * t + (na[0] + (nb[0] - na[0]) * t) * off,
                a[1] + (b[1] - a[1]) * t + (na[1] + (nb[1] - na[1]) * t) * off)

    def lane_off(self, k):
        return self.o + k * self.lw

    def project(self, p):
        """(distance to the centreline, s along it, metres right of it, the segment's direction)."""
        best = None
        for i, (a, b) in enumerate(zip(self.P, self.P[1:])):
            dx, dz = b[0] - a[0], b[1] - a[1]
            l2 = dx * dx + dz * dz
            if l2 < 1e-9:
                continue
            t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / l2))
            q = (a[0] + dx * t, a[1] + dz * t)
            d = math.dist(p, q)
            ln = math.sqrt(l2)
            if best is None or d < best[0]:
                best = (d, self.cum[i] + t * ln, ((p[0] - a[0]) * -dz + (p[1] - a[1]) * dx) / ln, (dx / ln, dz / ln))
        return best


def angle(d0, d1):
    """The turn from d0 to d1 in rad, as Vector2.angle_to: positive to the right (x east, z south)."""
    return math.atan2(d0[0] * d1[1] - d0[1] * d1[0], d0[0] * d1[0] + d0[1] * d1[1])


def old_lane(ne, k, nf, turn):
    """lane_graph.gd's rule before RT-2 (GDScript int division truncates toward zero)."""
    if nf == 1:
        return 0
    if turn > TURN_MIN:
        return nf - 1
    if turn < -TURN_MIN:
        return 0
    return max(0, min(nf - 1, k + int((nf - ne) / 2)))


def unit(x, z):
    ln = math.hypot(x, z) or 1e-9
    return x / ln, z / ln


def side_of(ge, gf, k, j):
    """How far lane k of e lands to the side of lane j of f, across the junction's bisector (R3)."""
    a = ge.point(ge.s1, ge.lane_off(k))
    b = gf.point(gf.s0, gf.lane_off(j))
    if math.dist(a, b) <= 0.5:
        return 0.0
    d1, d0 = ge.direction(ge.s1), gf.direction(gf.s0)
    bis = unit(d1[0] + d0[0], d1[1] + d0[1])
    return abs((b[0] - a[0]) * -bis[1] + (b[1] - a[1]) * bis[0])


def allows(code, turn):
    """Whether a lane with turn code `code` may take an exit that turns by `turn` rad."""
    if not code:
        return True
    return ("T" in code and abs(turn) < TURN_MIN) or ("R" in code and turn > SLIGHT) or ("L" in code and turn < -SLIGHT)


def links_for(ge, gf, turn, tl):
    """The landing lane on f for every lane of e (section 3 above)."""
    ne, nf = ge.n, gf.n
    old = [old_lane(ne, k, nf, turn) for k in range(ne)]
    if nf == 1:
        return old
    if abs(turn) <= TURN_MIN:
        judged = list(range(ne))
        if tl and abs(turn) < THROUGH:
            through = [k for k in range(ne) if not tl[k] or "T" in tl[k]]
            judged = through or judged
        q_old = int((nf - ne) / 2)
        # Two lanes that may go on never land in one while the next street has room for them all.
        lo, hi = -(ne - 1), nf - 1
        if max(judged) - min(judged) < nf:
            lo, hi = -min(judged), nf - 1 - max(judged)
        best = None
        for q in range(lo, hi + 1):
            js = [max(0, min(nf - 1, k + q)) for k in range(ne)]
            sides = [side_of(ge, gf, k, js[k]) for k in judged]
            key = (round(max(sides), 3), round(sum(sides), 3), abs(q - q_old))
            if best is None or key < best[0]:
                best = (key, js)
        return best[1]
    if not tl:
        return old
    c = "R" if turn > 0 else "L"
    lanes = [k for k in range(ne) if c in tl[k]]
    if len(lanes) < 2:
        return old
    out = list(old)
    if c == "R":
        for i, k in enumerate(sorted(lanes, reverse=True)):
            out[k] = max(0, nf - 1 - i)
    else:
        for i, k in enumerate(sorted(lanes)):
            out[k] = min(nf - 1, i)
    return out


def _merge(a, b):
    return "".join(c for c in ORDER if c in a or c in b)


def _design_boxes(out):
    boxes = []
    for rows in out.get("road_design_ends", {}).values():
        if rows:
            xs, zs = [r[0] for r in rows], [r[1] for r in rows]
            boxes.append((min(xs) - DESIGN_PAD, max(xs) + DESIGN_PAD, min(zs) - DESIGN_PAD, max(zs) + DESIGN_PAD))
    return boxes


def build(out):
    """The edges, the adjacency lane_graph.gd drives (closed streets out) and the way back."""
    edges = out["graph"]["edges"]
    G = [Edge(e) for e in edges]
    outs = defaultdict(list)
    by_ends = {}
    for i, e in enumerate(edges):
        if int(e.get("cf", 0)) == 0:
            outs[int(e["a"])].append(i)
        by_ends[(int(e["a"]), int(e["b"]))] = i
    rev = [by_ends.get((int(e["b"]), int(e["a"])), -1) for e in edges]
    return edges, G, outs, rev


def arrow_rows(out, edges, G):
    """Each arrow's edge, lane and along-position: {edge: [(s, lane, symbol index), ...]}."""
    grid = defaultdict(set)
    for i, ge in enumerate(G):
        if int(edges[i].get("cf", 0)):
            continue
        for a, b in zip(ge.P, ge.P[1:]):
            n = max(1, int(math.dist(a, b) / 4.0))
            for t in range(n + 1):
                x, z = a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n
                grid[(int(x // 16), int(z // 16))].add(i)
    rows = defaultdict(list)
    for si, s in enumerate(out.get("symbols", [])):
        if s.get("k") != "arrow":
            continue
        cx, cz = int(s["x"] // 16), int(s["z"] // 16)
        best = None
        for i in sorted({i for dx in (-1, 0, 1) for dz in (-1, 0, 1) for i in grid.get((cx + dx, cz + dz), ())}):
            ge = G[i]
            d, sv, side, dv = ge.project((s["x"], s["z"]))
            if dv[0] * s["d"][0] + dv[1] * s["d"][1] < ARROW_DIR:
                continue
            if not ge.o - SIDE_SLACK <= side <= ge.lane_off(ge.n - 1) + SIDE_SLACK:
                continue
            if not ge.s1 - ROW_REACH <= sv <= ge.s1 + 1.0 or abs(d - abs(side)) > 0.05:
                continue   # (beside the line, not off one of its ends)
            key = (round(ge.s1 - sv, 3), round(d, 3), i)
            if best is None or key < best[0]:
                best = (key, i, sv, side)
        if best is None:
            continue
        _, i, sv, side = best
        ge = G[i]
        k = max(0, min(ge.n - 1, int(math.floor((side - ge.o) / ge.lw + 0.5))))
        rows[i].append((sv, k, si, side, ge.project((s["x"], s["z"]))[3]))
    return rows


def apply(out, listing=None):
    """Writes `tl` and `lk` on the graph's edges and seats the arrows; returns a one-line summary."""
    edges, G, outs, rev = build(out)
    syms = out.get("symbols", [])
    boxes = _design_boxes(out)
    rows = arrow_rows(out, edges, G)
    moved = merged = 0
    drop = set()
    tls = {}
    for i in sorted(rows):
        ge = G[i]
        lst = sorted(rows[i], key=lambda r: (-r[0], r[1], r[2]))
        groups = []
        for r in lst:
            if groups and groups[-1][0][0] - r[0] <= ROW_SAME:
                groups[-1].append(r)
            else:
                groups.append([r])
        for g_i, group in enumerate(groups):
            by_lane = {}
            for sv, k, si, side, dv in sorted(group, key=lambda r: (r[1], r[2])):
                s = syms[si]
                if k in by_lane:
                    keep = syms[by_lane[k]]
                    t = _merge(keep["t"], s["t"])
                    if not any(b[0] <= s["x"] <= b[1] and b[2] <= s["z"] <= b[3] for b in boxes):
                        if t != keep["t"]:
                            keep["t"] = t
                        drop.add(si)
                        merged += 1
                    continue
                by_lane[k] = si
                if abs(side - ge.lane_off(k)) > ON_CENTRE and not any(b[0] <= s["x"] <= b[1] and b[2] <= s["z"] <= b[3] for b in boxes):
                    # straight across its segment, so the arrow keeps its place along the lane
                    shift = ge.lane_off(k) - side
                    s["x"], s["z"] = round(s["x"] - dv[1] * shift, 2), round(s["z"] + dv[0] * shift, 2)
                    moved += 1
            if g_i == 0:
                codes = [""] * ge.n
                for sv, k, si, side, dv in group:
                    codes[k] = _merge(codes[k], syms[si]["t"])
                tls[i] = codes
    if drop:
        out["symbols"] = [s for si, s in enumerate(syms) if si not in drop]
    written = changed_links = through_fixed = 0
    for i, e in enumerate(edges):
        e.pop("lk", None)
        e.pop("tl", None)
        if i in tls and any(tls[i]):
            e["tl"] = tls[i]
        if int(e.get("cf", 0)):
            continue
        ge = G[i]
        flat = []
        for f in outs[int(e["b"])]:
            if f == rev[i]:
                continue
            gf = G[f]
            turn = angle(ge.direction(ge.s1), gf.direction(gf.s0))
            js = links_for(ge, gf, turn, e.get("tl"))
            old = [old_lane(ge.n, k, gf.n, turn) for k in range(ge.n)]
            if js != old:
                flat += [f] + js
                changed_links += 1
                if abs(turn) < THROUGH:
                    through_fixed += 1
                if listing is not None:
                    p = ge.P[-1]
                    listing.append("--at=%.0f,%.0f  %s: lanes %s into %s were %s (turn %.2f)"
                                   % (p[0], p[1], e.get("name") or "(no name)", js, edges[f].get("name") or "a road", old, turn))
        if flat:
            e["lk"] = flat
            written += 1
    out[KEY] = VERSION
    return "%d edges with turn codes, %d links on %d edges differ from the old guess (%d straight on), %d arrows seated, %d merged" % (
        sum(1 for e in edges if "tl" in e), changed_links, written, through_fixed, moved, merged)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        out = json.load(fh)
    listing = [] if "--list" in argv else None
    print("lane_links: " + apply(out, listing))
    for line in listing or []:
        print(line)
    if "--dry" not in argv:
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(out, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
