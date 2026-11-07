"""Stairs across the city (F, 2026-11-07: "look on the map to the places where we have stairs,
map them and improve"): every OpenStreetMap flight of steps on the map, its tags carried into the
map data, and a ranked inventory of how each one is built in the game.

    python3 -I tools/stairs.py tags [MAP.json] [--osm data/raw/stairs/stairs_osm.json]
        copies the stair tags of each matching OSM way onto centrum.json's `steps` (idempotent):
        n  step count (step_count)            w  width in metres (width)
        up 0/1: which end is the top (incline up = the way climbs towards its last point)
        hr handrails: 1 left, 2 right, 4 centre (handrail=yes: 3)
        rp 1 when the flight has a ramp for prams or bikes (ramp, ramp:stroller, ramp:bicycle)
        sf surface: "sett", "concrete", "metal", "wood" or "stone" (paving stones, granite)
        cv 1 for an escalator (conveying)      br 1 on a bridge or a footbridge
        (the walls' heights, materials and the fences' types are tools/barrier_tags.py's).
        bake_osm.py calls stair_tags() for a full re-bake, so the Mac's bake keeps them too.
        After it, re-run tools/bake_street_details.py and tools/bake_park_details.py (their stamps
        follow centrum.json, or the quick checks go red).
    python3 -I tools/stairs.py report [MAP.json] [--osm ...] [--out DIR]
        the inventory (stairs.json + stairs.md in DIR, default build/stairs): every flight with
        its place, length, its real drop (step count x 0.16 m) against what the 10 m terrain grid
        gives there, walls drawn across it or beside it, and fountain or basin edges by it; the
        flights ranked for a photo pass, with map pins.
    python3 -I tools/stairs.py --check [MAP.json]
        exit 1 unless the map's steps carry the tags (verify.sh step `stairs`).

The OSM extract (data/raw/stairs/stairs_osm.json, gitignored) is made on the Mac from the demo
export: every highway=steps way with its tags and node coordinates, plus the walls, retaining
walls and fountain edges (`edges`). The cloud can't reach Overpass; once the tags are on
centrum.json, the game needs nothing else.
"""
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map", "centrum.json")
OSM = os.path.join(ROOT, "data", "raw", "stairs", "stairs_osm.json")
TERRAIN = os.path.join(ROOT, "game", "map", "terrain.json")
LAT0, LON0 = 52.2340, 21.0240
M_PER_DEG_LAT = 110574.0
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(LAT0))
RISER = 0.16          # a typical Warsaw outdoor riser, m
MATCH = 1.2           # a map flight within this mean distance of an OSM way is that way, m
TAG_KEYS = ("n", "w", "up", "hr", "rp", "sf", "cv", "br")


def project(lat, lon):
    return ((lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT)


def unproject(x, z):
    return (LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON)


def num(v):
    try:
        return float(str(v).split(";")[0].replace("m", "").replace(",", ".").strip())
    except (TypeError, ValueError):
        return None


def stair_tags(t):
    """The compact stair fields for one OSM steps way's tags (see the module docstring)."""
    out = {}
    n = num(t.get("step_count"))
    if n and 1 <= n <= 300:
        out["n"] = int(n)
    w = num(t.get("width"))
    if w and 0.8 <= w <= 40:
        out["w"] = round(w, 1)
    inc = t.get("incline")
    if inc == "up":
        out["up"] = 1
    elif inc == "down":
        out["up"] = 0
    hr = 0
    if t.get("handrail") == "yes":
        hr |= 3
    for side, bit in (("left", 1), ("right", 2), ("center", 4)):
        if t.get("handrail:" + side) == "yes":
            hr |= bit
        elif t.get("handrail:" + side) == "no":
            hr &= ~bit
    if hr:
        out["hr"] = hr
    if any(t.get(k) == "yes" for k in ("ramp", "ramp:stroller", "ramp:bicycle", "ramp:wheelchair")):
        out["rp"] = 1
    sf = t.get("surface", "")
    m = t.get("material", "")
    kind = {"sett": "sett", "cobblestone": "sett", "concrete": "concrete", "metal": "metal",
            "wood": "wood", "paving_stones": "stone", "granite": "stone", "stone": "stone"}.get(sf)
    if m in ("granite", "stone"):
        kind = "stone"
    if kind:
        out["sf"] = kind
    if t.get("conveying") in ("yes", "forward", "backward", "reversible"):
        out["cv"] = 1
    if t.get("bridge") not in (None, "no"):
        out["br"] = 1
    return out


def wall_height(t):
    """A wall's mapped height in metres (OSM height), or None (the game's 1.9 m)."""
    h = num(t.get("height"))
    return round(h, 2) if h is not None and 0.1 <= h <= 8.0 else None


def pairs(flat):
    return list(zip(flat[0::2], flat[1::2]))


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    l2 = ax * ax + az * az
    u = 0.0 if l2 < 1e-9 else max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / l2))
    return math.hypot(p[0] - a[0] - ax * u, p[1] - a[1] - az * u), u


def poly_dist(p, pts):
    """Distance from p to a polyline, and the position along it (0..1 of its length)."""
    best, at, run = math.inf, 0.0, 0.0
    total = sum(math.dist(a, b) for a, b in zip(pts, pts[1:])) or 1.0
    for a, b in zip(pts, pts[1:]):
        d, u = seg_dist(p, a, b)
        if d < best:
            best, at = d, (run + u * math.dist(a, b)) / total
        run += math.dist(a, b)
    return best, at


class Grid:
    """A coarse cell index of polylines."""
    def __init__(self, items, cell=25.0):
        self.cell, self.cells = cell, {}
        for i, pts in enumerate(items):
            for p in pts:
                self.cells.setdefault((int(p[0] // cell), int(p[1] // cell)), set()).add(i)

    def near(self, p, r=1):
        cx, cz = int(p[0] // self.cell), int(p[1] // self.cell)
        out = set()
        for dx in range(-r, r + 1):
            for dz in range(-r, r + 1):
                out |= self.cells.get((cx + dx, cz + dz), set())
        return out


def load_osm(path):
    d = json.load(open(path, encoding="utf-8"))
    ways = []
    for w in d["ways"]:
        pts = [project(*g) for g in w["g"] if g]
        if len(pts) >= 2:
            ways.append((w, pts))
    edges = []
    for e in d.get("edges", []):
        pts = [project(*g) for g in e["g"] if g]
        if len(pts) >= 2:
            edges.append((e, pts))
    return ways, edges


def dense(pts, every=1.0):
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.dist(a, b) / every))
        out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(1, n + 1)]
    return out


def match(steps, ways):
    """For each map flight, (its OSM way, the way's position at the flight's first and last
    points) or None."""
    grid = Grid([p for _, p in ways])
    out = []
    for s in steps:
        p = pairs(s["p"])
        cand = grid.near(p[0]) | grid.near(p[-1])
        best = (MATCH, None)
        for i in cand:
            wpts = ways[i][1]
            ds = [poly_dist(q, wpts)[0] for q in dense(p, 1.0)]
            m = sum(ds) / len(ds)
            if m < best[0]:
                best = (m, i)
        if best[1] is None:
            out.append(None)
            continue
        wpts = ways[best[1]][1]
        out.append((ways[best[1]][0], poly_dist(p[0], wpts)[1], poly_dist(p[-1], wpts)[1]))
    return out


def apply_tags(steps, ways):
    """Writes the tags onto `steps` in place; returns (matched, tagged)."""
    matched = tagged = 0
    for s, m in zip(steps, match(steps, ways)):
        for k in TAG_KEYS:
            s.pop(k, None)
        if m is None:
            continue
        matched += 1
        w, u0, u1 = m
        tags = stair_tags(w["tags"])
        if "up" in tags:
            # The way climbs towards its last node (incline=up); the map piece may run the other
            # way round or be a clipped part of it.
            climbs_to_end = tags["up"] == 1
            tags["up"] = 1 if climbs_to_end == (u1 >= u0) else 0
        if u1 < u0 and tags.get("hr", 0) & 3 in (1, 2):
            # Left and right are the OSM way's; the map piece runs the other way round.
            tags["hr"] ^= 3
        n_piece = abs(u1 - u0)
        if "n" in tags and n_piece < 0.9:
            # A piece clipped at the map edge keeps its share of the steps.
            tags["n"] = max(1, round(tags["n"] * n_piece))
        s.update(tags)
        tagged += bool(tags)
    return matched, tagged


class Terrain:
    def __init__(self, path):
        t = json.load(open(path, encoding="utf-8"))
        self.x0, self.z0, self.step = t["x0"], t["z0"], t["step"]
        self.nx, self.nz, self.h = t["nx"], t["nz"], t["h"]

    def at(self, x, z):
        fx = max(0.0, min(self.nx - 1.001, (x - self.x0) / self.step))
        fz = max(0.0, min(self.nz - 1.001, (z - self.z0) / self.step))
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        h = self.h
        a = h[j * self.nx + i]
        b = h[j * self.nx + i + 1]
        c = h[(j + 1) * self.nx + i]
        d = h[(j + 1) * self.nx + i + 1]
        return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v


def seg_cross(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    o1, o2, o3, o4 = orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b)
    return (o1 > 0) != (o2 > 0) and (o3 > 0) != (o4 > 0)


def report(d, ways, edges, out_dir):
    steps = d.get("steps", [])
    terr = Terrain(TERRAIN) if os.path.exists(TERRAIN) else None
    walls = [pairs(l["p"]) for l in d.get("lines", []) if l.get("k") == "wall"]
    wgrid = Grid(walls)
    fountain_edges = [(e, p) for e, p in edges if e["tags"].get("amenity") == "fountain"
                      or e["tags"].get("water") in ("basin", "reflecting_pool", "pond")]
    fgrid = Grid([p for _, p in fountain_edges])
    pois = {(p["x"], p["z"]) for p in d.get("pois", []) if p.get("k") == "subway_entrance"}
    lm = [(l.get("name") or l.get("k") or "", l.get("x"), l.get("z")) for l in d.get("landmarks", [])
          if isinstance(l, dict) and "x" in l]
    names = {}
    for w, _ in ways:
        if "name" in w["tags"]:
            names[w["id"]] = w["tags"]["name"]
    matches = match(steps, ways)
    rows = []
    for i, (s, m) in enumerate(zip(steps, matches)):
        p = pairs(s["p"])
        length = sum(math.dist(a, b) for a, b in zip(p, p[1:]))
        cx = sum(q[0] for q in p) / len(p)
        cz = sum(q[1] for q in p) / len(p)
        h0 = terr.at(*p[0]) if terr else 0.0
        h1 = terr.at(*p[-1]) if terr else 0.0
        grid_drop = abs(h1 - h0)
        real = s.get("n", 0) * RISER if "n" in s else None
        # Walls across the flight (a line crossing its centreline) and beside it (both ends of a
        # wall piece within 2.5 m of the flight, the stairwell walls drawn 1.9 m high).
        across, beside = 0, 0
        for wi in wgrid.near((cx, cz), 2):
            wp = walls[wi]
            if any(seg_cross(a, b, c, e) for a, b in zip(p, p[1:]) for c, e in zip(wp, wp[1:])):
                across += 1
            elif all(poly_dist(q, p)[0] < 2.5 + s.get("w", 2.4) / 2 for q in dense(wp, 2.0)):
                beside += 1
        basin = 0
        for fi in fgrid.near((cx, cz), 1):
            fp = fountain_edges[fi][1]
            if min(poly_dist(q, fp)[0] for q in (p[0], p[-1])) < 3.0:
                basin += 1
        metro = any(math.hypot(q[0] - x, q[1] - z) < 6.0 for q in (p[0], p[-1]) for x, z in pois)
        w = m[0] if m else None
        name = names.get(w["id"]) if w else None
        near_lm = min(((math.hypot(cx - x, cz - z), n) for n, x, z in lm), default=(math.inf, ""))
        flags = []
        if real is not None and real - grid_drop > 1.0:
            flags.append("flat: grid %.1f m of %.1f m" % (grid_drop, real))
        if across:
            flags.append("wall across")
        if beside:
            flags.append("walls beside (1.9 m)")
        if basin:
            flags.append("by a fountain/basin edge")
        if metro:
            flags.append("metro")
        if s.get("cv"):
            flags.append("escalator")
        drop = real if real is not None else grid_drop
        score = drop * 2.0 + length * 0.15 + (8 if name else 0) + (6 if across else 0) + \
            (4 if basin else 0) + (3 if beside else 0) + (5 if near_lm[0] < 60 else 0)
        lat, lon = unproject(cx, cz)
        rows.append({"i": i, "x": round(cx, 1), "z": round(cz, 1), "lat": round(lat, 6), "lon": round(lon, 6),
                     "len": round(length, 1), "n": s.get("n"), "w": s.get("w"), "drop": round(drop, 1),
                     "grid": round(grid_drop, 2), "osm": w["id"] if w else None, "name": name,
                     "near": near_lm[1] if near_lm[0] < 60 else "", "flags": flags, "score": round(score, 1),
                     "hr": s.get("hr", 0), "rp": s.get("rp", 0), "sf": s.get("sf", "")})
    rows.sort(key=lambda r: -r["score"])
    os.makedirs(out_dir, exist_ok=True)
    json.dump(rows, open(os.path.join(out_dir, "stairs.json"), "w"), indent=0)
    write_md(d, rows, os.path.join(out_dir, "stairs.md"))
    return rows


def street_names(d):
    out = []
    for r in d.get("roads", []) + d.get("paths", []):
        if r.get("name"):
            out.append((r["name"], pairs(r["p"])))
    return Grid([p for _, p in out], 50.0), out


def nearest_name(grid, named, x, z):
    best = (math.inf, "")
    for i in grid.near((x, z), 1):
        dd = poly_dist((x, z), named[i][1])[0]
        if dd < best[0]:
            best = (dd, named[i][0])
    return best[1] if best[0] < 60 else ""


def places(rows, reach=35.0):
    """Flights grouped into places: each joins the first place whose centre is within `reach`."""
    out = []
    for r in sorted(rows, key=lambda r: -r["score"]):
        for p in out:
            if math.hypot(p["x"] - r["x"], p["z"] - r["z"]) < reach:
                p["rows"].append(r)
                break
        else:
            out.append({"x": r["x"], "z": r["z"], "rows": [r]})
    for p in out:
        p["score"] = sum(r["score"] for r in p["rows"])
    out.sort(key=lambda p: -p["score"])
    return out


def write_md(d, rows, path, top=60):
    grid, named = street_names(d)
    ps = places(rows)
    lines = ["# Stairs across the city: the inventory", "",
             "Made by `python3 -I tools/stairs.py report` from the map's %d OSM flights (tags from the "
             "Mac's OpenStreetMap export). Drop: the mapped step count x %.2f m, else what the 10 m "
             "ground grid gives. Places are flights within 35 m of each other, ranked by drop, "
             "length, a name, and walls or basins by them." % (len(rows), RISER), "",
             "| # | Place | Pin | Flights | Steps | Drop m | Grid m | Notes |", "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    for k, p in enumerate(ps[:top], 1):
        rs = p["rows"]
        lat, lon = unproject(p["x"], p["z"])
        name = next((r["name"] for r in rs if r["name"]), "") or nearest_name(grid, named, p["x"], p["z"])
        steps = sum(r["n"] or 0 for r in rs)
        drop = max(r["drop"] for r in rs)
        g = max(r["grid"] for r in rs)
        flags = sorted({f.split(":")[0] for r in rs for f in r["flags"]})
        lines.append("| %d | %s | [%.5f, %.5f](https://www.google.com/maps?q=%.6f,%.6f) | %d | %s | %.1f | %.1f | %s |" % (
            k, name, lat, lon, lat, lon, len(rs), steps or "?", drop, g, ", ".join(flags)))
    open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = {a.split("=")[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv if a.startswith("--")}
    cmd = args[0] if args else ""
    path = args[1] if len(args) > 1 else MAP
    if "--check" in opt:
        d = json.load(open(path, encoding="utf-8"))
        tagged = sum(1 for s in d.get("steps", []) if any(k in s for k in TAG_KEYS))
        ok = tagged * 2 >= len(d.get("steps", []))
        print("stairs: %s (%d of %d flights carry OSM tags)" % ("OK" if ok else "FAIL", tagged, len(d.get("steps", []))))
        return 0 if ok else 1
    osm = opt.get("--osm", OSM)
    if cmd not in ("tags", "report"):
        print(__doc__)
        return 2
    d = json.load(open(path, encoding="utf-8"))
    ways, edges = load_osm(osm)
    if cmd == "tags":
        matched, tagged = apply_tags(d["steps"], ways)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, separators=(",", ":"), ensure_ascii=False)
        print("stairs: %d flights, %d matched to OSM, %d tagged" % (len(d["steps"]), matched, tagged))
        return 0
    rows = report(d, ways, edges, opt.get("--out", os.path.join(ROOT, "build", "stairs")))
    print("stairs: %d flights reported" % len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
