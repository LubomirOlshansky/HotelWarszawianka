"""Tram stops as Warsaw builds them (F, 2026-11-07: "improve the tram tracks and the tram stops"):
the islands at a tram's height, their track edge and their railing found once, on the map data.

    python3 -I tools/tram_stops.py [MAP.json] [--dry]
        tags the map in place (idempotent: a map already tagged is left alone);
        --dry prints what it would do and writes nothing.
    python3 -I tools/tram_stops.py --check [MAP.json]
        exit 1 unless the map is tagged and every tram island is low and has its track edge
        (verify.sh step `tramstops`).

Why. bake_osm.py makes every `railway=platform` 0.9 m high, a train's platform. Warsaw's tram
islands are mapped with that tag too, so the 126 islands beside the tram tracks stood 0.9 m over
the street: a concrete wall in the middle of Marszałkowska, with the mapped shelters, benches and
the waiting people sunk into it to the knees. A Warsaw tram island is 0.25-0.30 m over the rails
(the low-floor trams' step), edged on the track side by a light kerb band and a tactile strip,
fenced on the road side by the black steel railing, and open at its ends, where the crossings
come in.

What, on the finished map data (bake_osm.py calls `apply(out)` after road_smooth; this file also
runs on a baked map, as the cloud has no OpenStreetMap download):

1. A platform whose middle lies within TRAM_REACH m of a tram track and RAIL_CLEAR m or more from
   every railway track is a tram island: `h` = TRAM_H, `tram` = 1.
2. Its track edge (`te`): the runs of its outline that lie within TRACK_EDGE m of a track's
   centre line, as flat polylines. map_builder.gd lays the light band and the tactile strip
   along them.
3. Its railing (`re`): the runs of its outline (at least RAIL_MIN m) that face a road (the point
   ROAD_PROBE m out from the edge lies on a road's ribbon), trimmed RAIL_END m at both ends for
   the crossings; flat polylines. map_builder.gd draws the tram railing along them.

4. Stops with no island (`tram_halts`, flat [x, z, ...]): a mapped shelter within HALT_SHELTER m of
   a track and HALT_ISLAND m or more from every tram island is a stop on the pavement or a
   painted one (OpenStreetMap has no platform outline there: Muranowska's and Sanguszki's tracks
   ran 2 km without a stop). trams.gd stops at them as at the islands.

5. The real stops (F, 2026-11-07, "real tram stops all over the map"): game/data/tram_stops_osm.json
   holds every tram stop position and platform OpenStreetMap has inside the map box (taken from the
   full download on F's Mac, data/raw/demo/osm/osm_demo.json, with the stops mapped only as a point).
   Each island takes the name of the nearest one within NAME_REACH m (`name`, the stop's number cut
   off), and a stop position on a track with no island or halt within HALT_ISLAND m becomes a halt
   too (Rondo ONZ's, Raszyńska's and Dworzec Centralny's that had none).

Standard library only.
"""
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION = 2
OSM_STOPS = os.path.join(ROOT, "game", "data", "tram_stops_osm.json")
NAME_REACH = 40.0     # an island takes the name of an OSM stop this near its middle
STOP_ON_TRACK = 12.0  # an OSM stop position this near a track is on it
TRAM_H = 0.3          # a Warsaw tram island's height over the street (0.25-0.30 m)
TRAM_REACH = 7.5      # trams.gd _find_halts: a platform this near a track is a stop
RAIL_CLEAR = 12.0     # a railway track this near makes it a train's platform (0.9 m) after all
TRACK_EDGE = 3.4      # an edge this near a track's centre line is the boarding edge
ROAD_PROBE = 1.4      # how far out from an edge the road is looked for
RAIL_MIN = 6.0        # a road-side run shorter than this gets no railing
RAIL_END = 3.0        # the railing stops this short of each end of its run
HALT_SHELTER = 9.0     # a shelter this near a track is a tram stop's
HALT_ISLAND = 60.0    # ... unless a tram island is this near (its own shelter)
HALT_MERGE = 50.0     # shelters this close (both sides of the street) are one stop
CELL = 32.0


def pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def seg_dist(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = dx * dx + dz * dz
    t = 0.0 if ln == 0.0 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / ln))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dz)


class Grid:
    """Segments (a, b, payload) in CELL m cells, for nearest-distance questions."""

    def __init__(self):
        self.cells = {}

    def add(self, a, b, payload=None):
        x0, x1 = sorted((a[0], b[0]))
        z0, z1 = sorted((a[1], b[1]))
        for cx in range(math.floor(x0 / CELL), math.floor(x1 / CELL) + 1):
            for cz in range(math.floor(z0 / CELL), math.floor(z1 / CELL) + 1):
                self.cells.setdefault((cx, cz), []).append((a, b, payload))

    def near(self, p, reach):
        seen = set()
        for cx in range(math.floor((p[0] - reach) / CELL), math.floor((p[0] + reach) / CELL) + 1):
            for cz in range(math.floor((p[1] - reach) / CELL), math.floor((p[1] + reach) / CELL) + 1):
                for s in self.cells.get((cx, cz), ()):
                    if id(s) not in seen:
                        seen.add(id(s))
                        yield s

    def dist(self, p, reach):
        best = math.inf
        for a, b, _ in self.near(p, reach):
            best = min(best, seg_dist(p, a, b))
        return best


def lines_grid(items):
    g = Grid()
    for it in items:
        pts = pairs(it["p"])
        for a, b in zip(pts, pts[1:]):
            g.add(a, b)
    return g


def roads_grid(roads):
    g = Grid()
    for r in roads:
        if r.get("bridge"):
            continue
        pts = pairs(r["p"])
        for a, b in zip(pts, pts[1:]):
            g.add(a, b, float(r.get("w", 6.0)) * 0.5)
    return g


def on_road(p, roads):
    for a, b, half in roads.near(p, 16.0):
        if seg_dist(p, a, b) < half:
            return True
    return False


def runs(poly, keep):
    """The outline's runs of consecutive edges i (poly[i] -> poly[i + 1], closed) with keep[i], as
    point lists; a run through the closing edge is joined round."""
    n = len(poly)
    if all(keep):
        return [poly + [poly[0]]]
    start = next(i for i in range(n) if not keep[i])
    out = []
    cur = []
    for k in range(1, n + 1):
        i = (start + k) % n
        if keep[i]:
            if not cur:
                cur = [poly[i]]
            cur.append(poly[(i + 1) % n])
        elif cur:
            out.append(cur)
            cur = []
    if cur:
        out.append(cur)
    return out


def length(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def trim(pts, d0, d1):
    """The polyline from d0 m to (its length - d1) m."""
    total = length(pts)
    s0, s1 = d0, total - d1
    out = []
    run = 0.0
    for a, b in zip(pts, pts[1:]):
        ln = math.dist(a, b)
        if ln > 0 and run + ln >= s0 and run <= s1:
            f0 = max(0.0, min(1.0, (s0 - run) / ln))
            f1 = max(0.0, min(1.0, (s1 - run) / ln))
            if not out:
                out.append((a[0] + (b[0] - a[0]) * f0, a[1] + (b[1] - a[1]) * f0))
            out.append((a[0] + (b[0] - a[0]) * f1, a[1] + (b[1] - a[1]) * f1))
        run += ln
    return out


def flat(pts):
    return [round(v, 2) for q in pts for v in q]


def classify(out):
    """[(platform, track-edge runs, railing runs)] for the tram islands."""
    trams = lines_grid(out.get("trams", []))
    rails = lines_grid(out.get("rails", []))
    roads = roads_grid(out.get("roads", []))
    found = []
    for plat in out.get("platforms", []):
        poly = pairs(plat["p"])
        if len(poly) < 3:
            continue
        c = (sum(q[0] for q in poly) / len(poly), sum(q[1] for q in poly) / len(poly))
        if trams.dist(c, TRAM_REACH) >= TRAM_REACH or rails.dist(c, RAIL_CLEAR) < RAIL_CLEAR:
            continue
        area2 = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1]))
        sgn = 1.0 if area2 > 0 else -1.0   # outward normal of a counter-clockwise (x, z) ring: (dz, -dx)
        track, road = [], []
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            ln = math.dist(a, b)
            m = ((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
            near = ln >= 0.3 and trams.dist(m, TRACK_EDGE) < TRACK_EDGE
            track.append(near)
            if ln < 0.3 or near:
                road.append(False)
                continue
            nx, nz = (b[1] - a[1]) / ln * sgn, -(b[0] - a[0]) / ln * sgn
            road.append(on_road((m[0] + nx * ROAD_PROBE, m[1] + nz * ROAD_PROBE), roads))
        te = [r for r in runs(poly, track) if length(r) >= 2.0] if any(track) else []
        re = []
        if any(road):
            for r in runs(poly, road):
                if length(r) >= RAIL_MIN + 2.0 * RAIL_END:
                    re.append(trim(r, RAIL_END, RAIL_END))
        found.append((plat, te, re))
    return found


def halts(out, found):
    """[x, z] of the stops with no island (see 4.)."""
    trams = lines_grid(out.get("trams", []))
    centres = []
    for plat, _, _ in found:
        q = pairs(plat["p"])
        centres.append((sum(a[0] for a in q) / len(q), sum(a[1] for a in q) / len(q)))
    sh = out.get("shelters", [])
    got = []
    for i in range(0, len(sh) - 2, 3):
        p = (sh[i], sh[i + 1])
        if trams.dist(p, HALT_SHELTER) >= HALT_SHELTER:
            continue
        if any(math.dist(p, c) < HALT_ISLAND for c in centres) or any(math.dist(p, g) < HALT_MERGE for g in got):
            continue
        got.append(p)
    # 5.: the real stop positions with no island or halt near.
    for kind, _, x, z in osm_stops():
        p = (x, z)
        if kind != "stop" or trams.dist(p, STOP_ON_TRACK) >= STOP_ON_TRACK:
            continue
        if any(math.dist(p, c) < HALT_ISLAND for c in centres) or any(math.dist(p, g) < HALT_MERGE for g in got):
            continue
        got.append(p)
    return got


def osm_stops():
    """[kind, name, x, z] of tools/../game/data/tram_stops_osm.json, [] without it."""
    if not os.path.exists(OSM_STOPS):
        return []
    with open(OSM_STOPS, encoding="utf-8") as f:
        return json.load(f).get("stops", [])


def stop_name(name):
    """'Rondo ONZ 03' -> 'Rondo ONZ' (the stop's number off)."""
    parts = name.rsplit(" ", 1)
    return parts[0] if len(parts) == 2 and parts[1].isdigit() else name


def name_islands(found):
    stops = [s for s in osm_stops() if s[1]]
    named = 0
    for plat, _, _ in found:
        q = pairs(plat["p"])
        c = (sum(a[0] for a in q) / len(q), sum(a[1] for a in q) / len(q))
        best = min(stops, key=lambda s: math.dist(c, (s[2], s[3])), default=None)
        if best is not None and math.dist(c, (best[2], best[3])) < NAME_REACH:
            plat["name"] = stop_name(best[1])
            named += 1
    return named


def apply(out):
    """Tags the finished map data in place; returns a one-line summary."""
    if int(out.get("tram_stops", 0)) >= VERSION:
        return "already tagged"
    # An older tagging is redone whole (it only reads the outlines, tracks and roads).
    found = classify(out)
    edges = rails_n = 0
    for plat, te, re in found:
        plat["h"] = TRAM_H
        plat["tram"] = 1
        plat["te"] = [flat(r) for r in te]
        plat["re"] = [flat(r) for r in re]
        edges += len(te)
        rails_n += len(re)
    named = name_islands(found)
    extra = halts(out, found)
    out["tram_halts"] = flat(extra)
    out["tram_stops"] = VERSION
    return "%d tram islands at %.2f m (%d named), %d track edges, %d railings, %d stops with no island" % (
        len(found), TRAM_H, named, edges, rails_n, len(extra))


def check(out):
    problems = []
    if int(out.get("tram_stops", 0)) < VERSION:
        problems.append("the map is not tagged (run python3 -I tools/tram_stops.py)")
    islands = [p for p in out.get("platforms", []) if p.get("tram")]
    if len(islands) < 100:
        problems.append("only %d tram islands (expected 100+)" % len(islands))
    for p in islands:
        if float(p["h"]) > 0.35:
            problems.append("a tram island %.2f m high at %s" % (float(p["h"]), p["p"][:2]))
    named = sum(1 for p in islands if p.get("name"))
    if named < len(islands) * 9 // 10:
        problems.append("only %d of %d tram islands have their stop's name" % (named, len(islands)))
    bare = sum(1 for p in islands if not p.get("te"))
    if bare > len(islands) // 10:
        problems.append("%d of %d tram islands have no track edge" % (bare, len(islands)))
    return problems, len(islands), bare


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    args = [a for a in argv if not a.startswith("--")]
    if args:
        path = args[0]
    with open(path, encoding="utf-8") as f:
        out = json.load(f)
    if "--check" in argv:
        problems, n, bare = check(out)
        for p in problems[:20]:
            print("tramstops: " + p)
        if problems:
            sys.exit(1)
        print("tramstops: OK (%d tram islands, %d without a track edge)" % (n, bare))
        return
    if "--dry" in argv:
        found = classify(out)
        print("tram_stops (dry): %d tram islands, %d track edges, %d railings, %d stops with no island" % (
            len(found), sum(len(t) for _, t, _ in found), sum(len(r) for _, _, r in found), len(halts(out, found))))
        return
    print("tram_stops: " + apply(out))
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main(sys.argv[1:])
