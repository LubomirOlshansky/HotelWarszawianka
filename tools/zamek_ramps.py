"""Grodzka's slip road by the Royal Castle (F, 2026-11-13, four phone screenshots: "these ramps are
broken"): the one-lane ramp from Wybrzeże Gdańskie that climbs past Pałac pod Blachą along the
foot of the Trasa W-Z embankment and joins the W-Z just before its tunnel under Plac Zamkowy.

The real road (OpenStreetMap ways "Grodzka", ids in the bake as roads 247 and 3708) is one smooth
climb of about 5 % from the boulevard's level up to the tunnel mouth, with a pavement on its north
side and the W-Z's retaining wall on its south side. The 10 m terrain grid blurs the W-Z's 7 m
embankment into the road, so the road's level along its middle went -13.3, -10.7, -9.9 (a hump),
-11.6 (a dip), -8.6 (a hump), -10.3 (a dip). The bake bridged the two dips with flat "pit" fills
(tools/bake_roads.py PIT_SPAN) and bake_structures stood stone retaining walls along their edges:
the ramp came out as steps and short walls in a trench (the screenshots' "road into a wall").

This gives the ramp its real profile on the finished map data (after the structures), as one
ground profile ("s": 1, map_builder.gd `_fill_height_base`, the same kind loop 3e makes):
- the pit fills on the ramp and their walls go;
- a set fill along the ramp from where it leaves the flat boulevard (-13.5) to where the grid
  climbs smoothly again (-8.7, 5.5 % on): a Hermite curve that meets both ends' slopes, over the
  carriageway, the north pavement and the strip up to the W-Z's wall (never into the W-Z's own
  approach fills);
- the W-Z retaining wall's foot follows the ramp down (the wall stands from the ramp's level).
The ramp is the same road; nothing new is drawn. Re-run tools/bake_sectors.py and bake_city.gd after it.

The second ramp by the Castle, Nowy Zjazd's slip road up to the Śląsko-Dąbrowski bridgehead
(F, 2026-11-14), gets the same kind of profile: see "Nowy Zjazd" below. Each ramp keeps its own
record, so either can be redone without the other.

    python3 -I tools/zamek_ramps.py [MAP_DIR]          fixes game/map/centrum.json in place (idempotent)
    python3 -I tools/zamek_ramps.py --check [MAP_DIR]  exit 1 unless the map has it (verify.sh step `zamekramps`)

tools/bake_osm.py runs `apply` after centralny_ramp.
"""
import json
import math
import os
import sys

VERSION = 1
KEY = "zamek_ramps"
SITE = (-700.0, -1520.0, -470.0, -1395.0)   # x0, z0, x1, z1
NAME = "Grodzka"
START = (-492.4, -1499.2)   # the ramp's foot (its way leaves the north loop here)
# The profile, by distance along the ramp from START (metres, its OSM line): flat boulevard up to
# S0, the climb to S1, the grid's own smooth climb on from there.
S0, H0, M0 = 49.2, -13.5, 0.02
S1, H1, M1 = 134.5, -8.7, 0.055
STEP = 2.0
NORTH = 5.4        # the corridor north of the ramp's line: the lane's half and the pavement (P513, 2.2 m at ~4.2 m)
SOUTH = 3.7        # south: up to the W-Z's retaining wall (3.6-4.5 m off the line), short of the W-Z's pavement fill
WALL_REACH = 4.4   # a wall vertex this near the ramp's line stands on it
CLEAR = 0.15       # the corridor keeps this clear of any other approach's corridor


def _pairs(p):
    return list(zip(p[0::2], p[1::2]))


def _flat(pts, nd=2):
    return [round(v, nd) for q in pts for v in q]


def _cum(pts):
    out = [0.0]
    for a, b in zip(pts, pts[1:]):
        out.append(out[-1] + math.dist(a, b))
    return out


def _at(pts, cum, s):
    for k in range(len(pts) - 1):
        if cum[k + 1] >= s:
            t = (s - cum[k]) / max(cum[k + 1] - cum[k], 1e-9)
            return (pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t)
    return pts[-1]


def _seg(q, a, b):
    """(distance, t along) from q to segment ab."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    l2 = dx * dx + dz * dz
    t = 0.0 if l2 <= 0 else max(0.0, min(1.0, ((q[0] - a[0]) * dx + (q[1] - a[1]) * dz) / l2))
    return math.dist(q, (a[0] + dx * t, a[1] + dz * t)), t


def _station(q, pts, cum):
    """(distance to the line, distance along it) of point q."""
    best = (1e9, 0.0)
    for k in range(len(pts) - 1):
        d, t = _seg(q, pts[k], pts[k + 1])
        if d < best[0]:
            best = (d, cum[k] + (cum[k + 1] - cum[k]) * t)
    return best


def _hermite(s, s0, h0, m0, s1, h1, m1):
    """A Hermite climb from (s0, h0) at slope m0 to (s1, h1) at slope m1, at distance s."""
    L = s1 - s0
    t = max(0.0, min(1.0, (s - s0) / L))
    t2, t3 = t * t, t * t * t
    return ((2 * t3 - 3 * t2 + 1) * h0 + (t3 - 2 * t2 + t) * m0 * L
            + (-2 * t3 + 3 * t2) * h1 + (t3 - t2) * m1 * L)


def level(s):
    """Grodzka's ramp's level at distance s along it (S0..S1)."""
    return _hermite(s, S0, H0, M0, S1, H1, M1)


def _in_site(p):
    xs, zs = p[0::2], p[1::2]
    return min(xs) >= SITE[0] and max(xs) <= SITE[2] and min(zs) >= SITE[1] and max(zs) <= SITE[3]


def _meets_site(p):
    return any(SITE[0] <= x <= SITE[2] and SITE[1] <= z <= SITE[3] for x, z in zip(p[0::2], p[1::2]))


def ramp_line(out):
    """The ramp's OSM line from START westwards: the chained ways named Grodzka in the site."""
    ways = [_pairs(r["p"]) for r in out["roads"] if r.get("name") == NAME and _in_site(r["p"])]
    line = None
    for w in ways:
        if math.dist(w[0], START) < 0.5:
            line = list(w)
    if line is None:
        return None
    grew = True
    while grew:
        grew = False
        for w in ways:
            if math.dist(w[0], line[-1]) < 0.5 and math.dist(w[-1], line[-2]) > 0.5 and len(line) < 400:
                line += w[1:]
                ways.remove(w)
                grew = True
                break
    return line


def apply(out, map_dir=None):
    """Both ramps, each idempotent on its own record."""
    del map_dir
    return apply_grodzka(out) + "; " + apply_nowy_zjazd(out)


def apply_grodzka(out):
    line = ramp_line(out)
    if line is None:
        return "Grodzka's ramp not found (nothing changed)"
    cum = _cum(line)
    if cum[-1] < S1 + 4.0:
        return "Grodzka's ramp shorter than its profile (nothing changed)"
    if out.get(KEY, {}).get("v") == VERSION:
        return "already applied"
    # 1. The pit fills on the ramp (flat, not "set") and the walls that line them.
    gone_fills = []
    keep = []
    for f in out["fills"]:
        pts = _pairs(f["p"])
        on = f.get("k") == "road" and not f.get("s") and _in_site(f["p"]) and \
            all(_station(q, line, cum)[0] < 0.6 for q in pts)
        (gone_fills if on else keep).append(f)
    out["fills"] = keep
    walls_out = 0
    if gone_fills:
        lines = [_pairs(f["p"]) for f in gone_fills]
        reach = max(max(f["l"], f["r"]) for f in gone_fills) + 0.8
        kept = []
        for w in out["walls"]:
            pts = _pairs(w["p"])
            hugs = _in_site(w["p"]) and all(min(_station(q, ln, _cum(ln))[0] for ln in lines) < reach for q in pts)
            if hugs:
                walls_out += 1
            else:
                kept.append(w)
        out["walls"] = kept
    # 2. The profile: stations every STEP from S0 - 6 to S1 + 4 (its ends on the grid's own level
    # there are within a few cm: the curve meets them flat and at the grid's slope).
    a, b = S0 - 6.0, S1 + 4.0
    n = int(math.ceil((b - a) / STEP))
    ss = [a + (b - a) * k / n for k in range(n + 1)]
    pts = [_at(line, cum, s) for s in ss]
    hs = [round(level(s) if s <= S1 else H1 + M1 * (s - S1), 2) for s in ss]
    for k in range(len(ss)):
        if ss[k] < S0:
            hs[k] = round(H0 - M0 * (S0 - ss[k]), 2)
    # Which side is north: the points go west; lat > 0 is to the right of the way (map_builder: r).
    ax, az = pts[0]
    bx, bz = pts[-1]
    north_is_r = (bx - ax) * (-1.0) - (bz - az) * 0.0 > 0.0   # cross(ab, (0, -1)) > 0
    side_r, side_l = (NORTH, SOUTH) if north_is_r else (SOUTH, NORTH)
    # Never into another approach's corridor (the W-Z's road, tram and pavement fills).
    for f in out["fills"]:
        if f.get("s") or not _meets_site(f["p"]):
            continue
        fp = _pairs(f["p"])
        for q in pts:
            d, _ = _station(q, fp, _cum(fp))
            room = d - max(f["l"], f["r"]) - CLEAR
            if room < min(NORTH, SOUTH):
                return f"the W-Z's approach {room:.1f} m from the ramp (nothing changed)"
    out["fills"].append({"p": _flat(pts), "h": hs, "l": side_l, "r": side_r, "k": "road", "s": 1})
    # 3. The W-Z's retaining wall stands from the ramp's level where it lines it.
    lowered = 0
    for w in out["walls"]:
        if not _in_site(w["p"]) or "b" not in w:
            continue
        wp = _pairs(w["p"])
        for k, q in enumerate(wp):
            d, s = _station(q, line, cum)
            if d <= WALL_REACH and a <= s <= b and k < len(w["b"]):
                h = level(s) if s <= S1 else H1 + M1 * (s - S1)
                if h < w["b"][k] - 0.05:
                    w["b"][k] = round(h - 0.05, 2)
                    lowered += 1
    out[KEY] = {"v": VERSION, "fills_out": len(gone_fills), "walls_out": walls_out, "wall_feet": lowered}
    return (f"Grodzka's ramp {b - a:.0f} m on one profile {hs[0]:.1f} to {hs[-1]:.1f} m; "
            f"{len(gone_fills)} pit fills and {walls_out} walls out, {lowered} wall feet lowered")


def check(out):
    ok_g, msg_g = check_grodzka(out)
    ok_n, msg_n = check_nowy_zjazd(out)
    return ok_g and ok_n, msg_g + "; " + msg_n


def check_grodzka(out):
    line = ramp_line(out)
    if line is None:
        return False, "Grodzka's ramp not found"
    if out.get(KEY, {}).get("v") != VERSION:
        return False, "not applied (python3 -I tools/zamek_ramps.py)"
    cum = _cum(line)
    pits = [f for f in out["fills"] if f.get("k") == "road" and not f.get("s") and _in_site(f["p"])
            and all(_station(q, line, cum)[0] < 0.6 for q in _pairs(f["p"]))]
    if pits:
        return False, f"{len(pits)} pit fills on the ramp"
    prof = [f for f in out["fills"] if f.get("s") and _in_site(f["p"])
            and all(_station(q, line, cum)[0] < 0.6 for q in _pairs(f["p"]))
            and S0 - 7.0 <= _station(_pairs(f["p"])[0], line, cum)[1] <= S1]
    if len(prof) != 1:
        return False, f"{len(prof)} profiles on the ramp (want 1)"
    hs = prof[0]["h"]
    worst = max(abs((hs[k + 1] - hs[k]) / STEP) for k in range(len(hs) - 1))
    rises = all(hs[k + 1] >= hs[k] - 0.01 for k in range(len(hs) - 1))
    if not rises or worst > 0.09:
        return False, f"the profile is not one climb (steepest {worst * 100:.1f} %)"
    return True, f"Grodzka's ramp one climb {hs[0]:.1f} to {hs[-1]:.1f} m, steepest {worst * 100:.1f} %"


# --- Nowy Zjazd's slip road by the Śląsko-Dąbrowski bridgehead (F, 2026-11-14) ------------------
# F's screenshot ("where is it and why this road looks broken"): the one-way ramp of Nowy Zjazd
# that leaves the loop under the W-Z, runs south-east along the foot of the W-Z's embankment past
# the office block on Wybrzeże Gdańskie and joins the W-Z at the bridgehead. The real road is one
# steady climb of about 3 % (the boulevard's level to the bridge's), its pavement on the river side
# held by a retaining wall over the office block's lower yard. On the map the road had no profile
# of its own: it lay on the 10 m grid, which blurs the W-Z's 7 m embankment on one side and the
# yard's 14 m pit on the other into it, so its middle went -9.6, -8.4, -11.3 (a 3 m pit beside the
# office), -8.0, tilting up to 2 m across; its pavement fill had humps of its own (-10.5, -8.9,
# -10.5). The ground poked through the asphalt in torn grey and beige patches.
#
# This lays one ground profile along it (two "s" pieces: the 7.5 m two-lane part, then the one-lane
# part squeezed against the W-Z's pavement), puts the pavement fills beside it on the same level,
# sets the river-side retaining walls' tops to it and lowers the W-Z side walls' feet to it.
NZ_KEY = "nowy_zjazd"
NZ_VERSION = 1
NZ_SITE = (-440.0, -1560.0, -330.0, -1420.0)
NZ_START = (-413.6, -1430.5)   # where the ramp leaves the loop (the end of Nowy Zjazd's loop way)
NZ_END = (-350.9, -1540.5)     # where it joins the W-Z at the bridgehead
# The profile by distance along the ramp from NZ_START: the grid's own smooth climb up to NZ_S0,
# the set climb to NZ_S1 (where the bridgehead's road fill takes over), then on at NZ_M1.
NZ_S0, NZ_H0, NZ_M0 = 36.0, -9.66, 0.034
NZ_S1, NZ_H1, NZ_M1 = 118.0, -7.42, 0.024
NZ_HEAD, NZ_TAIL = 6.0, 4.0
NZ_SPLIT = 100.0               # the two-lane part ends here (the way narrows to one lane)
NZ_SIDES = ((4.0, 5.2), (2.0, 5.2))   # (W-Z side, river side) of each piece
NZ_PAVE = 6.0                  # a pavement fill point this near the line, on the river side, is the ramp's
NZ_WALL_IN = 7.0               # river-side retaining walls this near the line take the ramp's level
NZ_WALL_WZ = 7.5               # W-Z side walls this near stand from the ramp's level
NZ_LANE_WALL = 1.2             # a wall foot this near the line stands in the lane: it goes


def nz_level(s):
    if s < NZ_S0:
        return NZ_H0 - NZ_M0 * (NZ_S0 - s)
    if s > NZ_S1:
        return NZ_H1 + NZ_M1 * (s - NZ_S1)
    return _hermite(s, NZ_S0, NZ_H0, NZ_M0, NZ_S1, NZ_H1, NZ_M1)


def _nz_in_site(p):
    xs, zs = p[0::2], p[1::2]
    return min(xs) >= NZ_SITE[0] and max(xs) <= NZ_SITE[2] and min(zs) >= NZ_SITE[1] and max(zs) <= NZ_SITE[3]


def _nz_meets(p):
    return any(NZ_SITE[0] <= x <= NZ_SITE[2] and NZ_SITE[1] <= z <= NZ_SITE[3] for x, z in zip(p[0::2], p[1::2]))


def nz_line(out):
    """The ramp's OSM line, NZ_START to NZ_END: the chained one-way secondary ways in the site."""
    ways = [_pairs(r["p"]) for r in out["roads"] if r.get("k") == "secondary" and r.get("oneway")
            and not r.get("bridge") and _nz_in_site(r["p"])]
    line = [NZ_START]
    while math.dist(line[-1], NZ_END) > 0.5 and len(line) < 400:
        nxt = [w for w in ways if math.dist(w[0], line[-1]) < 0.5]
        if len(nxt) != 1:
            return None
        line += nxt[0][1:]
        ways.remove(nxt[0])
    return line if len(line) > 1 else None


def _signed(q, pts, cum):
    """(distance, station, signed lateral: > 0 on the river side) of q from the line."""
    best = (1e9, 0.0, 0.0)
    for k in range(len(pts) - 1):
        a, b = pts[k], pts[k + 1]
        d, t = _seg(q, a, b)
        if d < best[0]:
            dx, dz = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx, dz) or 1.0
            lat = ((q[0] - a[0]) * -dz + (q[1] - a[1]) * dx) / ln
            best = (d, cum[k] + (cum[k + 1] - cum[k]) * t, lat)
    return best


def apply_nowy_zjazd(out):
    line = nz_line(out)
    if line is None:
        return "Nowy Zjazd's ramp not found (nothing changed)"
    cum = _cum(line)
    if cum[-1] < NZ_S1 + NZ_TAIL + 2.0:
        return "Nowy Zjazd's ramp shorter than its profile (nothing changed)"
    rec = out.setdefault(KEY, {})
    if rec.get(NZ_KEY, {}).get("v") == NZ_VERSION:
        return "Nowy Zjazd already applied"
    a, b = NZ_S0 - NZ_HEAD, NZ_S1 + NZ_TAIL
    # 1. The profile, two pieces sharing the vertex at NZ_SPLIT.
    pieces = 0
    for (s_from, s_to), (wz, river) in zip(((a, NZ_SPLIT), (NZ_SPLIT, b)), NZ_SIDES):
        n = int(math.ceil((s_to - s_from) / STEP))
        ss = [s_from + (s_to - s_from) * k / n for k in range(n + 1)]
        pts = [_at(line, cum, s) for s in ss]
        # The river side is lat > 0 (_signed), the right of the way going on: map_builder's r.
        out["fills"].append({"p": _flat(pts), "h": [round(nz_level(s), 2) for s in ss],
                             "l": wz, "r": river, "k": "road", "s": 1})
        pieces += 1
    # 2. The pavement beside it (non-set path fills on the river side) on the ramp's level.
    paved = 0
    for f in out["fills"]:
        if f.get("s") or f.get("k") != "path" or not _nz_meets(f["p"]):
            continue
        for k, q in enumerate(_pairs(f["p"])):
            d, s, lat = _signed(q, line, cum)
            if a <= s <= b and 0.0 < lat <= NZ_PAVE and d <= NZ_PAVE:
                f["h"][k] = round(nz_level(s), 2)
                paved += 1
    # 3. The walls: on the river side their tops hold the ramp's level; on the W-Z side their feet
    # stand on it; a short wall standing in the lane goes.
    tops = feet = 0
    kept = []
    for w in out["walls"]:
        if not _nz_meets(w["p"]) or "b" not in w:
            kept.append(w)
            continue
        st = [_signed(q, line, cum) for q in _pairs(w["p"])]
        if len(st) == 2 and any(d <= NZ_LANE_WALL and a <= s <= b for d, s, _ in st):
            continue
        for k, (d, s, lat) in enumerate(st):
            if not (a <= s <= b) or k >= len(w["b"]):
                continue
            h = nz_level(s)
            if 0.0 < lat <= NZ_WALL_IN and w["t"][k] < h + 0.5:
                if abs(w["t"][k] - h) > 0.01:
                    w["t"][k] = round(h, 2)
                    tops += 1
                if w["b"][k] > h - 0.3:
                    w["b"][k] = round(h - 0.3, 2)
            elif -NZ_WALL_WZ <= lat <= 0.0 and w["b"][k] > h - 0.05:
                w["b"][k] = round(h - 0.05, 2)
                feet += 1
        kept.append(w)
    gone = len(out["walls"]) - len(kept)
    out["walls"] = kept
    rec[NZ_KEY] = {"v": NZ_VERSION, "pieces": pieces, "paved": paved, "wall_tops": tops, "wall_feet": feet,
                   "walls_out": gone}
    return (f"Nowy Zjazd's ramp {b - a:.0f} m on one profile {nz_level(a):.1f} to {nz_level(b):.1f} m; "
            f"{paved} pavement points, {tops} wall tops, {feet} wall feet, {gone} lane walls out")


def check_nowy_zjazd(out):
    line = nz_line(out)
    if line is None:
        return False, "Nowy Zjazd's ramp not found"
    if out.get(KEY, {}).get(NZ_KEY, {}).get("v") != NZ_VERSION:
        return False, "Nowy Zjazd not applied (python3 -I tools/zamek_ramps.py)"
    cum = _cum(line)
    a, b = NZ_S0 - NZ_HEAD, NZ_S1 + NZ_TAIL
    prof = [f for f in out["fills"] if f.get("s") and _nz_in_site(f["p"])
            and all(_station(q, line, cum)[0] < 0.6 for q in _pairs(f["p"]))]
    if len(prof) != 2:
        return False, f"{len(prof)} profiles on Nowy Zjazd's ramp (want 2)"
    hs = []
    for f in sorted(prof, key=lambda f: _station(_pairs(f["p"])[0], line, cum)[1]):
        hs += f["h"] if not hs else f["h"][1:]
    worst = max(abs((hs[k + 1] - hs[k]) / STEP) for k in range(len(hs) - 1))
    rises = all(hs[k + 1] >= hs[k] - 0.01 for k in range(len(hs) - 1))
    if not rises or worst > 0.06:
        return False, f"Nowy Zjazd's profile is not one climb (steepest {worst * 100:.1f} %)"
    for f in out["fills"]:
        if f.get("s") or f.get("k") != "path" or not _nz_meets(f["p"]):
            continue
        for q, h in zip(_pairs(f["p"]), f["h"]):
            d, s, lat = _signed(q, line, cum)
            if a <= s <= b and 0.0 < lat <= NZ_PAVE and abs(h - nz_level(s)) > 0.02:
                return False, f"Nowy Zjazd's pavement off the ramp's level at {q[0]:.0f},{q[1]:.0f}"
    return True, f"Nowy Zjazd's ramp one climb {hs[0]:.1f} to {hs[-1]:.1f} m, steepest {worst * 100:.1f} %"

def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    map_dir = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map")
    path = os.path.join(map_dir, "centrum.json")
    out = json.load(open(path))
    if "--check" in argv:
        ok, msg = check(out)
        print("zamek_ramps: " + msg)
        return 0 if ok else 1
    print("zamek_ramps: " + apply(out, map_dir))
    with open(path, "w") as fh:
        json.dump(out, fh, separators=(",", ":"), ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
