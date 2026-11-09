"""The car park ramp by Dworzec Centralny (F, 2026-11-08, Street View and an in-game screenshot):
the two one-way lanes off Aleja Jana Pawła II, north of Chmielna, that loop round a hedge island
down to a tunnel under the avenue, signposted "ZŁOTE TARASY ← / Dworzec Centralny TAXI BUS →",
3.3 m high, red and white bollards between the lanes, the block's stone retaining wall outside.

OpenStreetMap draws it as the way in (27569980, 307888832: down the inner loop to the portal),
the tunnel east under the avenue (30611690, `tunnel=yes`, `maxheight=3.3`, `taxi=yes`) to Złote
Tarasy's car park gates and the station's taxi road (185123967, 128214245), the tunnel back
(143461289) and the way out (143461245, 307888827: up the outer loop back to the avenue). The bake
leaves service tunnels out (garage interiors, R9), so the game had the inner ramp diving to a wall
and the outer one cut at a "garage door" halfway down: a spiral that went nowhere, with a stray
door across the way out (the screenshot).

This makes it a drive (one piece of the map, on the finished map data, after the structures):
- the way out's lower part, from the portal up to where the bake cut it, is a road again (its
  ground profile from the portal's floor up to the cut), and the garage door there goes;
- one tunnel (both lanes in one tube, as on the photo: the two OSM tubes' middle line, 10.8 m
  wide) runs from one portal under the avenue east to a turning hall under Złote Tarasy's forecourt
  (where the real lanes reach the car park's gates), its floor level with the ramps' foot; the
  lanes are its roads, the hall walled shut, so a car drives in, turns and drives back out;
- the portal's frame and the tube's walls, and the site's retaining walls placed again over the
  new ground (tools/bake_structures.py's own rules).
The signs, bollards and car park gates are drawn by game/scripts/centralny_ramp.gd.

    python3 -I tools/centralny_ramp.py [MAP_DIR]          fixes game/map/centrum.json in place (idempotent)
    python3 -I tools/centralny_ramp.py --check [MAP_DIR]  exit 1 unless the map has it (verify.sh step `centralnyramp`)

tools/bake_osm.py runs `apply` after bake_structures. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)

VERSION = 1
SITE = (-1690.0, 395.0, -1530.0, 500.0)   # x0, z0, x1, z1: the walls placed again inside this box

# OpenStreetMap's ways, in the map's frame (bake_osm.project; 2026-11-08's extract).
ENTRY_TUBE = [(-1642.4, 430.8), (-1637.4, 427.2), (-1631.7, 423.6), (-1626.2, 420.7), (-1620.7, 418.7),
              (-1615.6, 417.4), (-1610.9, 416.5), (-1605.8, 416.1), (-1600.6, 416.3), (-1595.7, 417.2),
              (-1590.0, 418.7), (-1584.8, 420.8), (-1579.9, 423.1), (-1575.3, 426.1), (-1571.1, 429.6)]  # 30611690
EXIT_TUBE = [(-1569.8, 420.9), (-1573.2, 418.8), (-1576.7, 417.0), (-1579.9, 415.2), (-1583.4, 413.6),
             (-1587.3, 412.2), (-1591.3, 410.9), (-1595.7, 410.0), (-1600.1, 409.4), (-1605.4, 409.2),
             (-1610.0, 409.5), (-1614.3, 410.1), (-1619.2, 411.2), (-1623.5, 412.6), (-1628.0, 414.3),
             (-1631.6, 416.1), (-1636.8, 418.9), (-1641.4, 421.7), (-1646.7, 425.2)]  # 143461289 (from its gate)
EXIT_RAMP = [(-1646.7, 425.2), (-1653.3, 431.5), (-1660.0, 439.3), (-1662.9, 444.0), (-1665.2, 448.7),
             (-1666.9, 453.2)]  # 143461245, the part the bake cut (R9), up to the cut
ENTRY_PORTAL = ENTRY_TUBE[0]
EXIT_PORTAL = EXIT_TUBE[-1]
CUT = (-1667.6, 456.4)        # where the bake ended the way out (its garage door)

TUBE_HALF = 5.4               # the tube's half width: both lanes (3.5 m) and the bollard strip
HALL_LEN = 22.0               # the turning hall at the east end: this long...
HALL_HALF = 11.0              # ...and twice this wide (a car turns in it with room)
SPLAY = 6.0                   # its west shoulders splay out from the tube's walls over this many metres
MOUTH_CLEAR = 8.0             # no scanned tree's trunk this far out in front of the mouth, across the tube's width
LANE_W = 3.5
FLOOR = 8.5                   # the floor if the entry ramp's profile doesn't say (its foot, 5.2 m under the avenue)
FILL_SIDE = 2.75              # the way out's ground profile reaches this far past its lane (the mapped area, the bollard strip)
GROUP_KEY = "centralny_ramp"


def _cum(pts):
    out = [0.0]
    for a, b in zip(pts, pts[1:]):
        out.append(out[-1] + math.dist(a, b))
    return out


def _at(pts, cum, s):
    s = max(0.0, min(s, cum[-1]))
    for k in range(len(pts) - 1):
        if s <= cum[k + 1] or k == len(pts) - 2:
            t = (s - cum[k]) / max(cum[k + 1] - cum[k], 1e-6)
            a, b = pts[k], pts[k + 1]
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    return pts[-1]


def _resample(pts, n):
    cum = _cum(pts)
    return [_at(pts, cum, cum[-1] * k / (n - 1)) for k in range(n)]


def _pairs(p):
    return list(zip(p[0::2], p[1::2]))


def _flat(pts, nd=2):
    return [round(v, nd) for q in pts for v in q]


def _seg_dist(q, line):
    best = 1e9
    for a, b in zip(line, line[1:]):
        vx, vz = b[0] - a[0], b[1] - a[1]
        l2 = vx * vx + vz * vz or 1e-9
        t = max(0.0, min(1.0, ((q[0] - a[0]) * vx + (q[1] - a[1]) * vz) / l2))
        best = min(best, math.dist(q, (a[0] + vx * t, a[1] + vz * t)))
    return best


def _simplify(pts):
    """Drop the in-between points of straight stretches (the 0.5 m samples of the cut)."""
    out = [pts[0]]
    for k in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[k], pts[k + 1]
        if abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])) > 0.01:
            out.append(b)
    out.append(pts[-1])
    return [(round(x, 2), round(z, 2)) for x, z in out]


def _near(p, q, r):
    return math.dist(p, q) < r


def tube_line():
    """The tube's middle line: the two OSM tubes walked together, west (the portal) to east."""
    n = 24
    a = _resample(ENTRY_TUBE, n)
    b = _resample(EXIT_TUBE[::-1], n)
    return [((p[0] + q[0]) * 0.5, (p[1] + q[1]) * 0.5) for p, q in zip(a, b)]


def hall_line(tube):
    """The turning hall: on along the tube's last heading, HALL_LEN long."""
    (x0, z0), (x1, z1) = tube[-2], tube[-1]
    d = math.dist((x0, z0), (x1, z1))
    ux, uz = (x1 - x0) / d, (z1 - z0) / d
    return [(x1 - ux * 2.0, z1 - uz * 2.0), (x1 + ux * HALL_LEN, z1 + uz * HALL_LEN)], (ux, uz)


def _floor(d):
    """The entry ramp's foot: its ground profile's height at the portal."""
    best = None
    for f in d.get("fills", []):
        for (x, z), h in zip(_pairs(f["p"]), f["h"]):
            dd = math.dist((x, z), ENTRY_PORTAL)
            if dd < 1.0 and (best is None or dd < best[0]):
                best = (dd, h)
    return best[1] if best else FLOOR


def _cut_height(d):
    """The way out's ground profile where the bake cut it (its first point, by the door)."""
    for f in d.get("fills", []):
        ps = _pairs(f["p"])
        if ps and _near(ps[0], CUT, 0.6):
            return f["h"][0]
    for g in d.get("garage_doors", []):
        if _near(tuple(g["c"]), CUT, 1.0):
            return g["y"]
    return None


def _wall_end_cap(a, b, floor, m):
    """A tunnel wall run from a to b (face to the right of a->b), floor up to the ground."""
    pts, tops, lows = [], [], []
    n = max(1, math.ceil(math.dist(a, b) / 3.0))
    for k in range(n + 1):
        q = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
        pts.append(q)
        tops.append(round(max(m.terrain(*q), floor + 4.8), 2))
        lows.append(round(floor, 2))
    return {"p": _flat(pts), "t": tops, "b": lows, "f": [5] * n, "k": "tunnel"}


def apply(out, map_dir, terrain=None):
    """Into the finished map data `out` (bake_osm.py, after bake_structures). Idempotent."""
    if out.get(GROUP_KEY, {}).get("v") == VERSION:
        return "already there"
    import check_roads as cr
    import bake_structures as bs
    if terrain is None:
        terrain = json.load(open(os.path.join(map_dir, "terrain.json")))
    roads = out["roads"]
    exit_road = next((r for r in roads if r["k"] == "service" and _near(_pairs(r["p"])[0], CUT, 0.6)), None)
    entry_road = next((r for r in roads if r["k"] == "service" and _near(_pairs(r["p"])[-1], ENTRY_PORTAL, 0.6)), None)
    if exit_road is None or entry_road is None:
        return "the ramps are not in this map (left alone)"
    floor = _floor(out)
    top = _cut_height(out)
    if top is None:
        top = floor + 2.1
    # 1. The way out's lower part, portal to the cut, its ground profile rising from the floor.
    ramp = EXIT_RAMP + [CUT]
    cum = _cum(ramp)
    n = max(2, math.ceil(cum[-1] / 1.5) + 1)
    rp = _resample(ramp, n)
    rc = _cum(rp)
    roads.append({"p": _flat(rp, 1), "w": LANE_W, "k": "service", "oneway": True, "lanes": 0, "name": "",
                  "bridge": False})
    half = LANE_W * 0.5 + FILL_SIDE   # wide enough to hold the mapped carriageway area round it
    out["fills"].append({"p": _flat(rp), "h": [round(floor + (top - floor) * c / rc[-1], 2) for c in rc],
                         "l": round(half, 2), "r": round(half, 2), "k": "road", "s": 1})
    # The garage door the bake put at the cut goes (the way runs on into the tunnel now).
    out["garages"] = [g for g in out.get("garages", []) if not _near((g[0], g[1]), CUT, 1.0)]
    out["garage_doors"] = [g for g in out.get("garage_doors", []) if not _near(tuple(g["c"]), CUT, 1.0)]
    # 2. The tunnel: the tube and the turning hall, level, one group.
    tn = out.setdefault("tunnels", {"pieces": [], "roads": [], "portals": [], "frames": []})
    g = 1 + max([p["g"] for p in tn.get("pieces", [])] + [-1])
    tube = tube_line()
    hall, (ux, uz) = hall_line(tube)
    pieces = []
    for pts, hw in ((tube, TUBE_HALF), (hall, HALL_HALF)):
        pc = {"p": _flat(pts), "h": [round(floor, 2)] * len(pts), "l": hw, "r": hw, "g": g, "k": "road"}
        pieces.append(pc)
        tn["pieces"].append(pc)
    # Its roads: the two lanes, each from its portal to the hall.
    tn["roads"].append({"p": _flat([ENTRY_PORTAL] + _offset_line(tube, 3.0)[1:] + [hall[1]], 1), "w": LANE_W,
                        "k": "service", "oneway": True, "lanes": 1, "name": "", "bridge": False, "tn": g})
    back = _offset_line(tube, -3.0)
    tn["roads"].append({"p": _flat([hall[1]] + back[::-1][:-1] + [EXIT_PORTAL], 1), "w": LANE_W,
                        "k": "service", "oneway": True, "lanes": 1, "name": "", "bridge": False, "tn": g})
    portal = tube[0]
    ux0, uz0 = (tube[1][0] - tube[0][0]) / math.dist(tube[0], tube[1]), (tube[1][1] - tube[0][1]) / math.dist(tube[0], tube[1])
    tn["portals"].append([round(portal[0], 1), round(portal[1], 1), g])
    # 3. The portal's frame and the tube's walls (bake_structures' rules), the hall shut, and the
    # site's retaining walls placed again over the new ground.
    m = cr.Map.from_data(map_dir, out, terrain)
    walls, _ = bs.place_walls(m)
    frames, twalls, _ = bs.place_tunnels(m)

    def in_site(w):
        ps = _pairs(w["p"])
        return all(SITE[0] <= x <= SITE[2] and SITE[1] <= z <= SITE[3] for x, z in ps)

    def ours(w):
        # A tunnel wall run of this tunnel: its points along our pieces' sides.
        ps = _pairs(w["p"])
        return w["k"] == "tunnel" and all(SITE[0] <= x <= SITE[2] and SITE[1] <= z <= SITE[3] for x, z in ps)
    site_walls = [w for w in bs._trim_walls(walls, m.shape) if in_site(w)]
    tube_walls = [w for w in bs._trim_walls(twalls, m.shape) if ours(w)]
    kept = [w for w in out.get("walls", []) if not in_site(w)]
    caps = []
    # The hall's west shoulders, splayed from the tube's walls out to its sides (a car turned
    # along a side wall is led back into the tube, not stopped on a square end), and its east end;
    # all facing in.
    tx, tz = tube[-1]
    ex, ez = hall[1]
    nx, nz = -uz, ux   # to the hall's right (looking east)
    th = TUBE_HALF + 0.3
    hh = HALL_HALF + 0.3
    sx, sz = tx + ux * SPLAY, tz + uz * SPLAY
    caps.append(_wall_end_cap((sx + nx * hh, sz + nz * hh), (tx + nx * th, tz + nz * th), floor, m))
    caps.append(_wall_end_cap((tx - nx * th, tz - nz * th), (sx - nx * hh, sz - nz * hh), floor, m))
    caps.append(_wall_end_cap((ex - nx * hh, ez - nz * hh), (ex + nx * hh, ez + nz * hh), floor, m))
    # The scanned trees whose trunks stand on the lanes by the mouth (GUGiK's scan of crowns over
    # the trench put them on the ramp's floor, in the way out).
    clear = [(rp, LANE_W * 0.5 + 1.0), (_pairs(entry_road["p"]), LANE_W * 0.5 + 1.0)]
    t3, crowns = out.get("trees3d", []), out.get("trees3d_crown")
    keep_t, keep_c, dropped = [], [], 0
    for k in range(0, len(t3), 6):
        q = (t3[k], t3[k + 1])
        a = (q[0] - portal[0]) * ux0 + (q[1] - portal[1]) * uz0
        across = abs(-(q[0] - portal[0]) * uz0 + (q[1] - portal[1]) * ux0)
        hit = -MOUTH_CLEAR <= a <= 1.0 and across <= TUBE_HALF + 1.0
        hit = hit or any(_seg_dist(q, line) <= r for line, r in clear)
        if hit:
            dropped += 1
            continue
        keep_t += t3[k:k + 6]
        if crowns is not None:
            keep_c.append(crowns[k // 6])
    out["trees3d"] = keep_t
    # The fences, walls and hedges (`lines`) that ran across the way out where the bake had no road
    # (the fence along the trench's top edge drops to the lanes' floor at the mouth): cut there,
    # as bake_structures.clear_carriageways cuts them out of every other lane.

    def blocked(q):
        a = (q[0] - portal[0]) * ux0 + (q[1] - portal[1]) * uz0
        across = abs(-(q[0] - portal[0]) * uz0 + (q[1] - portal[1]) * ux0)
        return (-MOUTH_CLEAR <= a <= 2.0 and across <= TUBE_HALF + 0.5) or _seg_dist(q, rp) <= LANE_W * 0.5 + 0.8
    cut_m = 0.0
    lines = []
    for ln in out.get("lines", []):
        ps = _pairs(ln["p"])
        if not any(SITE[0] <= x <= SITE[2] and SITE[1] <= z <= SITE[3] for x, z in ps):
            lines.append(ln)
            continue
        runs, cur, cut = [], [], False
        for a, b in zip(ps, ps[1:]):
            n = max(1, math.ceil(math.dist(a, b) / 0.5))
            for k in range(1 if cur else 0, n + 1):
                q = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
                if blocked(q):
                    if cur:
                        runs.append(cur)
                    cur, cut = [], True
                    cut_m += math.dist(a, b) / n
                else:
                    cur.append(q)
        if cur:
            runs.append(cur)
        if not cut:
            lines.append(ln)
            continue
        for r in runs:
            r = _simplify(r)
            if len(r) >= 2 and _cum(r)[-1] >= 0.5:
                lines.append(dict(ln, p=_flat(r)))
    out["lines"] = lines
    if crowns is not None:
        out["trees3d_crown"] = keep_c
    out["walls"] = kept + site_walls + tube_walls + caps
    tn["frames"] = [f for f in tn.get("frames", []) if not _near(tuple(f["c"]), portal, 1.0)] + \
        [f for f in frames if _near(tuple(f["c"]), portal, 1.0)]
    out[GROUP_KEY] = {"v": VERSION, "g": g, "portal": [round(portal[0], 1), round(portal[1], 1)],
                      "hall": _flat(hall, 1), "floor": round(floor, 2)}
    return (f"tunnel group {g}: the tube {_cum(tube)[-1]:.0f} m and a {HALL_LEN:.0f} x {2 * HALL_HALF:.0f} m hall at "
            f"{floor:.1f} m, the way out's lower {rc[-1]:.0f} m restored ({floor:.1f} -> {top:.1f} m), "
            f"{len(site_walls)} site walls, {len(tube_walls)} tube walls, {len(caps)} hall walls, "
            f"{dropped} scanned trees off the lanes, {cut_m:.0f} m of fences cut")


def _offset_line(pts, off):
    """pts moved `off` metres to the right (looking along them; x east, z south)."""
    out = []
    for k, (x, z) in enumerate(pts):
        a = pts[max(k - 1, 0)]
        b = pts[min(k + 1, len(pts) - 1)]
        d = math.dist(a, b) or 1.0
        ux, uz = (b[0] - a[0]) / d, (b[1] - a[1]) / d
        out.append((x - uz * off, z + ux * off))
    return out


def check(d):
    """The map has the drive: the tunnel group, no door at the cut, the restored way out."""
    errs = []
    info = d.get(GROUP_KEY)
    if not info or info.get("v") != VERSION:
        return ["no centralny_ramp marker (run tools/centralny_ramp.py)"]
    g = info["g"]
    if not any(p["g"] == g for p in d["tunnels"]["pieces"]):
        errs.append("no tunnel pieces of group %d" % g)
    if not any(p[2] == g for p in d["tunnels"]["portals"]):
        errs.append("no portal")
    if not any(_near(tuple(f["c"]), tuple(info["portal"]), 1.0) for f in d["tunnels"].get("frames", [])):
        errs.append("no portal frame")
    if any(_near(tuple(gd["c"]), CUT, 1.0) for gd in d.get("garage_doors", [])):
        errs.append("a garage door still stands across the way out")
    if not any(r["k"] == "service" and _near(_pairs(r["p"])[0], EXIT_PORTAL, 0.6) for r in d["roads"]):
        errs.append("the way out doesn't start at the portal")
    return errs


def main(argv):
    do_check = "--check" in argv
    args = [a for a in argv if not a.startswith("--")]
    map_dir = args[0] if args else os.path.join(TOOLS, "..", "game", "map")
    path = os.path.join(map_dir, "centrum.json")
    d = json.load(open(path, encoding="utf-8"))
    if do_check:
        errs = check(d)
        for e in errs:
            print("centralny_ramp: " + e)
        if errs:
            return 1
        print("centralny_ramp: OK")
        return 0
    print("centralny_ramp: " + apply(d, map_dir))
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
