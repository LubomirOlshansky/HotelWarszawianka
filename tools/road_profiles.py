"""Road profiles: one table of the places where a road lies on the blurred 10 m ground grid
(F, 2026-11-14: "find other places like Nowy Zjazd and fix them").

The pattern. A road without a height profile of its own is draped on the 10 m terrain grid. Beside
an embankment, a cutting, a retaining wall or a deep yard that grid smears the height step into
the road: its middle dips or humps over a few cells and its two edges sit at different heights.
The ground's triangles then poke through the asphalt in beige and grey patches (Nowy Zjazd and
Grodzka by the Castle, tools/zamek_ramps.py; Trasa Łazienkowska in its cutting at Plac na
Rozdrożu). The bake's own fix (tools/bake_roads.py `_ground_profiles`, loop 3e) reads the 1 m
bare earth, but only near the structures, so the rest kept the grid.

The fix. Every place is one entry in SPOTS: the road's two ends on the map (the way chain between
them is found along the streets), how its level is set, and how wide its corridor is. This pass
lays the ground profile ("s" fills, map_builder.gd `_fill_height_base`) along it, as two one-sided
halves (a profile's end has a round cap as wide as its narrower side, which held the end's level
a lane past it on a steep street). Inside the corridor the ground is the profile's level, flat
across, and the drawn ground follows it in 1 m sub-cells where it is lowered. Where a loop-3e
profile already holds the ground (`set_hit`), its level wins, blended over HELD_BLEND. Each side
road leaving the corridor gets a short ramp profile of its own (`_spurs`, SPUR, SPUR_GRADE; none
within STRUCT_CLEAR of a deck's or tunnel's end, whose approaches have levels of their own), and
the retaining walls inside the corridor stand from the new level. Where the profile stands BANK
over the ground past its side, a low stone retaining wall holds the edge (`_banks`). Nothing else
is drawn; the road is the same road.

An entry's level ("level"):
  "grid"   one smooth curve from the ground's level at one end to the other's, meeting both ends'
           slopes (the two ends sit where the grid is clean): a short dip or hump
  "floor"  the cutting's floor: the lowest of the ground across the carriageway every station,
           smoothed: a road in a trench or along the foot of a bank
  "mid"    the ground on the road's middle, smoothed: a road tilted across
plus "via": [[s, h], ...] (metres along the chain, level) to pin it where the photos or the 1 m
bare earth say so, and "h0"/"h1", "m0"/"m1" for the ends' level and slope. An entry's corridor:
the road's half width and "side" (default SIDE) on each side, or "l"/"r" (left and right of the
chain's direction, metres from its line) when given: narrow a side where a lower lane or a link
runs alongside (check_roads C1/C11 show it).

The scan (`scan`): where the ground shows through the asphalt. Every drivable surface road is
draped as map_builder lays it (pieces along the way, triangles split to DRAPE_EDGE, corners on
the higher of the surface and the drawn ground); inside each triangle the drawn ground (its 10 m
triangles or 1 m sub-cells, check_roads Map.drawn) is sampled, and a point where it stands over
the road by more than the road's depth bias (POKE, POKE_MINOR) is torn. Points within CLUSTER are
one place, scored by the sum of their pokes over the bias. `--propose=N|service` drafts entries
for the top N street (or the service-road) places that no entry covers yet. `--check` fails
unless every entry is applied and the scan finds no more places than the recorded counts (a
ratchet: the counts only go down, CHECK_STREETS and CHECK_SERVICE).

Cost: each lowered 10 m cell is drawn in 100 sub-cells (about 200 more triangles). An entry is
kept only where its fix is worth that (the first set: 695 -> 1256 such cells, 26 entries).

    python3 -I tools/road_profiles.py [MAP_DIR]            applies SPOTS to game/map/centrum.json (idempotent)
    python3 -I tools/road_profiles.py --check [MAP_DIR]    verify step `roadprofiles`
    python3 -I tools/road_profiles.py --scan [MAP_DIR] [--json=OUT] [--all]   the ranked list of torn places
    python3 -I tools/road_profiles.py --show=ID [MAP_DIR]  an entry's chain, profile and ground, station by station
    python3 -I tools/road_profiles.py --propose=N|service [MAP_DIR]   draft entries for the top places no entry covers

tools/bake_osm.py runs `apply` after zamek_ramps. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)

VERSION = 1
KEY = "road_profiles"
STEP = 2.0          # profile stations this far apart
SIDE = 1.5          # the corridor past the road's edge (loop 3e PROFILE_SIDE: a 1 m sub-cell past it)
SNAP = 3.0          # an entry's end point finds the road vertex this near it
SMOOTH = 15.0       # "floor"/"mid": the level's moving window (metres each side)
KNOT = 24.0         # "floor"/"mid": one knot of the smoothed level this often
WALL_REACH = 1.0    # a wall vertex this far past the corridor's side stands on the profile
BANK = 0.4          # where the profile stands this far over the ground past its side, a retaining wall
BANK_OUT = 0.5      # (the ground read this far out)
DRIVE = {"motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential",
         "living_street", "service", "primary_link", "secondary_link", "tertiary_link", "trunk_link",
         "motorway_link"}

CLUSTER = 40.0      # the scan: pokes this near are one place...
MIN_SCORE = 0.2     # ...and a place scoring less is a sliver (a few centimetres over the bias once)
# The ratchet: places the scan finds on today's map (streets, service roads). Lower them as places
# are fixed; never raise them without a reason in the pull request.
CHECK_STREETS = 27
CHECK_SERVICE = 73

# One entry per place, in the order they were fixed. "id" is the record's key; "a" and "b" the
# chain's ends (map metres); "name" keeps the chain on ways of that name (optional).
SPOTS = [
    # Trasa Łazienkowska in its cutting: the grid smeared the cutting's banks over the carriageways
    # (each way on its own floor; the west way's r side wide enough for the tunnel's outer lane at its
    # portal, the east way's kept off the link climbing out alongside it).
    {"id": "lazienkowska_w", "name": "Aleja Armii Ludowej", "a": (40.7, 1635.5), "b": (-211.3, 1736.0), "level": "floor", "r": 9.0},
    {"id": "lazienkowska_e", "name": "Aleja Armii Ludowej", "a": (-177.2, 1736.0), "b": (37.0, 1650.0), "level": "floor", "h0": 6.8, "m0": 0.0, "r": 6.0},
    # Wisłostrada by Bednarska: the grid tilted the road toward the river and the ground came up
    # through it in diamonds (r side kept off the boulevard's lower service lane).
    {"id": "wislostrada_bednarska_n", "name": "Wybrzeże Kościuszkowskie", "a": (-62.0, -1263.0), "b": (-181.0, -1387.0), "level": "mid", "r": 5.5},
    {"id": "wislostrada_bednarska_s", "name": "Wybrzeże Kościuszkowskie", "a": (-186.0, -1374.0), "b": (-72.0, -1255.0), "level": "mid"},
    {"id": "wislostrada_bednarska_w", "name": "Wybrzeże Kościuszkowskie", "a": (-181.3, -1386.6), "b": (-226.3, -1433.6), "level": "mid"},
    # Not here: the Wisłostrada tunnel's and Wał Miedzeszyński's deck approaches (a profile at a
    # portal or deck end moves the ground the lanes there read: check_drive height jumps).
    # The rest of the poke scan's street places (--propose, level "mid"), each checked with
    # check_roads and kept only where its fix is worth its 1 m ground sub-cells.
    {"id": "aleje_jerozolimskie_m2269_940", "name": "Aleje Jerozolimskie", "a": (-2217.9, 926.6), "b": (-2294.1, 951.6), "level": "mid", "side": 0.8},
    {"id": "miodowa_m884_m1407", "name": "Miodowa", "a": (-919.6, -1430.0), "b": (-856.0, -1392.8), "level": "mid"},
    {"id": "plac_powstancow_warszawy_m708_m162", "name": "Plac Powstańców Warszawy", "a": (-705.1, -152.0), "b": (-715.6, -183.1), "level": "mid"},
    {"id": "piekna_130_1100", "name": "Piękna", "a": (105.7, 1102.8), "b": (163.8, 1095.5), "level": "mid"},
    {"id": "pamietajcie_o_ogrodach_m2526_m2539", "name": "Pamiętajcie o Ogrodach", "a": (-2526.4, -2565.2), "b": (-2523.2, -2503.6), "level": "mid"},
    {"id": "wybrzeze_szczecinskie_498_m1446", "name": "Wybrzeże Szczecińskie", "a": (525.1, -1416.6), "b": (494.4, -1449.8), "level": "mid"},
    {"id": "service_498_m1446", "k": "service", "a": (519.2, -1441.5), "b": (502.1, -1458.2), "level": "mid"},
    {"id": "aleja_jana_chrystiana_szucha_54_1690", "name": "Aleja Jana Chrystiana Szucha", "a": (50.3, 1699.0), "b": (65.1, 1661.5), "level": "mid"},
    {"id": "secondary_m476_m1530", "k": "secondary", "a": (-462.5, -1509.6), "b": (-465.3, -1555.5), "level": "mid"},
    {"id": "aleja_armii_ludowej_198_1604", "name": "Aleja Armii Ludowej", "a": (177.7, 1612.9), "b": (246.8, 1574.6), "level": "mid"},
    {"id": "jakubowska_1769_m384", "name": "Jakubowska", "a": (1782.0, -376.6), "b": (1750.5, -375.5), "level": "mid"},
    {"id": "aleja_ksiecia_jozefa_poniatowskiego_1769_m384", "name": "Aleja Księcia Józefa Poniatowskiego", "a": (1758.7, -401.7), "b": (1790.2, -409.9), "level": "mid"},
    {"id": "olszowa_141_m1853", "name": "Olszowa", "a": (126.8, -1838.2), "b": (237.7, -1924.1), "level": "mid"},
    {"id": "sliska_m1748_250", "name": "Śliska", "a": (-1768.7, 256.7), "b": (-1727.1, 242.4), "level": "mid"},
    {"id": "service_m1748_250", "k": "service", "a": (-1737.5, 255.7), "b": (-1740.4, 247.2), "level": "mid"},
    {"id": "wybrzeze_gdanskie_m646_m2038", "name": "Wybrzeże Gdańskie", "a": (-630.0, -2012.6), "b": (-650.7, -2045.6), "level": "mid"},
    {"id": "plac_powstancow_warszawy_m686_m96", "name": "Plac Powstańców Warszawy", "a": (-684.2, -79.3), "b": (-693.7, -117.9), "level": "mid"},
    {"id": "emiliana_konopczynskiego_m207_m316", "name": "Emiliana Konopczyńskiego", "a": (-220.6, -316.9), "b": (-176.3, -322.3), "level": "mid"},
    {"id": "living_street_m1971_m1085", "k": "living_street", "a": (-1953.7, -1094.7), "b": (-1989.0, -1075.8), "level": "mid"},
    {"id": "gornoslaska_561_1030", "name": "Górnośląska", "a": (540.2, 1035.6), "b": (585.1, 1026.4), "level": "mid"},
    {"id": "karowa_m336_m900", "name": "Karowa", "a": (-335.0, -899.3), "b": (-352.2, -910.8), "level": "mid"},
]


# --- geometry --------------------------------------------------------------------------------

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
            return (pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t), k
    return pts[-1], len(pts) - 2


def _seg(q, a, b):
    """(distance, t along, signed lateral: map_builder's sign, > 0 on the corridor's r side)."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    l2 = dx * dx + dz * dz
    t = 0.0 if l2 <= 0 else max(0.0, min(1.0, ((q[0] - a[0]) * dx + (q[1] - a[1]) * dz) / l2))
    lat = (dx * (q[1] - a[1]) - dz * (q[0] - a[0])) / math.sqrt(l2) if l2 > 0 else 0.0
    return math.dist(q, (a[0] + dx * t, a[1] + dz * t)), t, lat


def _station(q, pts, cum):
    """(distance to the line, distance along it, signed lateral) of point q."""
    best = (1e9, 0.0, 0.0)
    for k in range(len(pts) - 1):
        d, t, lat = _seg(q, pts[k], pts[k + 1])
        if d < best[0]:
            best = (d, cum[k] + (cum[k + 1] - cum[k]) * t, lat)
    return best


def _hermite(s, s0, h0, m0, s1, h1, m1):
    L = s1 - s0
    t = max(0.0, min(1.0, (s - s0) / L)) if L > 0 else 0.0
    t2, t3 = t * t, t * t * t
    return ((2 * t3 - 3 * t2 + 1) * h0 + (t3 - 2 * t2 + t) * m0 * L
            + (-2 * t3 + 3 * t2) * h1 + (t3 - t2) * m1 * L)


def _spline(knots, m_first, m_last):
    """A C1 curve through knots [(s, h)] (sorted), Fritsch-Carlson slopes inside (no overshoot
    between two knots), the given slopes at both ends. Returns level(s)."""
    n = len(knots)
    ss = [k[0] for k in knots]
    hs = [k[1] for k in knots]
    sec = [(hs[i + 1] - hs[i]) / max(ss[i + 1] - ss[i], 1e-9) for i in range(n - 1)]
    m = [0.0] * n
    m[0], m[-1] = m_first, m_last
    for i in range(1, n - 1):
        if sec[i - 1] * sec[i] <= 0:
            m[i] = 0.0
        else:
            w1 = 2 * (ss[i + 1] - ss[i]) + (ss[i] - ss[i - 1])
            w2 = (ss[i + 1] - ss[i]) + 2 * (ss[i] - ss[i - 1])
            m[i] = (w1 + w2) / (w1 / sec[i - 1] + w2 / sec[i])

    def level(s):
        if s <= ss[0]:
            return hs[0] + m[0] * (s - ss[0])
        if s >= ss[-1]:
            return hs[-1] + m[-1] * (s - ss[-1])
        for i in range(n - 1):
            if s <= ss[i + 1]:
                return _hermite(s, ss[i], hs[i], m[i], ss[i + 1], hs[i + 1], m[i + 1])
        return hs[-1]
    return level


# --- the map as the game reads it ------------------------------------------------------------

def _ground(out, map_dir):
    """tools/check_roads.py's Map over this map data (the grid, the fills, the aprons)."""
    import check_roads
    terrain = json.load(open(os.path.join(map_dir, "terrain.json")))
    return check_roads.Map.from_data(map_dir, out, terrain)


def _surface_roads(out):
    return [(i, r) for i, r in enumerate(out["roads"]) if r["k"] in DRIVE and not r.get("bridge")
            and r.get("tn") is None and r.get("dk") is None]


def chain(out, spot):
    """The polyline from spot["a"] to spot["b"] along the surface roads (the shortest way; only
    ways named spot["name"], or of kind spot["k"], when given) and each segment's half width.
    The two ends are points on the roads (within SNAP of one): the chain starts and ends there,
    mid-way along a way if need be. None when not found."""
    import heapq
    name, kind = spot.get("name"), spot.get("k")
    nbr = {}
    coords = {}
    segs = []
    for i, r in _surface_roads(out):
        if (name and r.get("name") != name) or (kind and r["k"] != kind):
            continue
        q = _pairs(r["p"])
        for a, b in zip(q, q[1:]):
            ka, kb = (round(a[0], 1), round(a[1], 1)), (round(b[0], 1), round(b[1], 1))
            coords[ka], coords[kb] = a, b
            d = math.dist(a, b)
            nbr.setdefault(ka, []).append((kb, d, r["w"] * 0.5))
            nbr.setdefault(kb, []).append((ka, d, r["w"] * 0.5))
            segs.append((ka, kb, r["w"] * 0.5))
    A, B = (-1e9, 0.0), (-1e9, 1.0)   # the two ends' nodes (never a road vertex)
    ends = []
    for tag, p in ((A, spot["a"]), (B, spot["b"])):
        best = None
        for ka, kb, hw in segs:
            d, t, _ = _seg(p, coords[ka], coords[kb])
            if best is None or d < best[0]:
                best = (d, t, ka, kb, hw)
        if best is None or best[0] > SNAP:
            return None
        d, t, ka, kb, hw = best
        a, b = coords[ka], coords[kb]
        q = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
        coords[tag] = q
        L = math.dist(a, b)
        nbr.setdefault(tag, []).extend([(ka, L * t, hw), (kb, L * (1 - t), hw)])
        nbr.setdefault(ka, []).append((tag, L * t, hw))
        nbr.setdefault(kb, []).append((tag, L * (1 - t), hw))
        ends.append((tag, ka, kb, t, hw))
    if {ends[0][1], ends[0][2]} == {ends[1][1], ends[1][2]}:   # both on one segment
        hw = ends[0][4]
        return [coords[A], coords[B]], [hw]
    dist = {A: 0.0}
    prev = {}
    heap = [(0.0, A)]
    while heap:
        d, k = heapq.heappop(heap)
        if k == B:
            break
        if d > dist.get(k, 1e18):
            continue
        for o, w, hw in nbr.get(k, ()):
            if d + w < dist.get(o, 1e18):
                dist[o] = d + w
                prev[o] = (k, hw)
                heapq.heappush(heap, (d + w, o))
    if B not in dist:
        return None
    pts, half = [coords[B]], []
    k = B
    while k != A:
        k, hw = prev[k]
        pts.append(coords[k])
        half.append(hw)
    pts.reverse()
    half.reverse()
    keep = [0] + [i for i in range(1, len(pts)) if math.dist(pts[i], pts[i - 1]) > 0.05]
    return [pts[i] for i in keep], [half[i - 1] for i in keep[1:]]


def _corridor(spot, hw):
    """(l, r) of the corridor at a station whose road is hw wide on each side."""
    side = spot.get("side", SIDE)
    return spot.get("l", hw + side), spot.get("r", hw + side)


def stations(out, m, spot, line, half):
    """Every STEP along the chain: (s, point, half width, ground in the middle, lowest across, the
    grid alone in the middle)."""
    cum = _cum(line)
    n = max(1, int(math.ceil(cum[-1] / STEP)))
    rows = []
    for j in range(n + 1):
        s = cum[-1] * j / n
        p, k = _at(line, cum, s)
        a, b = line[k], line[min(k + 1, len(line) - 1)]
        ln = math.dist(a, b) or 1.0
        nx, nz = -(b[1] - a[1]) / ln, (b[0] - a[0]) / ln
        hw = half[min(k, len(half) - 1)]
        across = [m.terrain(p[0] + nx * o, p[1] + nz * o) for o in (-hw, -hw * 0.5, 0.0, hw * 0.5, hw)]
        top = max(max(m.terrain(p[0] + nx * hw * f, p[1] + nz * hw * f), m.grid(p[0] + nx * hw * f, p[1] + nz * hw * f))
                  for f in (-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0))
        m.terrain(*p)
        held = m.set_hit
        rows.append((s, p, hw, across[2], min(across), m.grid(*p), top, held))
    return rows


def _smoothed(rows, col):
    out = []
    for s, *_ in rows:
        vals = [r[col] for r in rows if abs(r[0] - s) <= SMOOTH]
        out.append(sum(vals) / len(vals))
    return out


def profile(rows, spot):
    """The entry's level(s) along its chain (see the module's doc)."""
    L = rows[-1][0]
    mode = spot.get("level", "grid")
    h0, h1 = rows[0][3], rows[-1][3]
    # The end slopes: the ground's own over the first and last 6 m.
    k6 = min(3, len(rows) - 1)
    m0 = (rows[k6][3] - rows[0][3]) / max(rows[k6][0] - rows[0][0], 1e-9)
    m1 = (rows[-1][3] - rows[-1 - k6][3]) / max(rows[-1][0] - rows[-1 - k6][0], 1e-9)
    h0, h1 = spot.get("h0", h0), spot.get("h1", h1)
    knots = [(0.0, h0)]
    if mode in ("floor", "mid"):
        sm = _smoothed(rows, 4 if mode == "floor" else 3)
        n = max(1, int(round(L / KNOT)))
        for j in range(1, n):
            s = L * j / n
            i = min(range(len(rows)), key=lambda i: abs(rows[i][0] - s))
            knots.append((rows[i][0], sm[i]))
    elif mode != "grid":
        raise ValueError("road_profiles: %s: unknown level %r" % (spot["id"], mode))
    for s, h in spot.get("via", ()):
        knots = [k for k in knots if abs(k[0] - s) > KNOT * 0.5] + [(float(s), float(h))]
    knots.append((L, h1))
    knots.sort()
    return _spline(knots, spot.get("m0", m0), spot.get("m1", m1))


# --- apply -----------------------------------------------------------------------------------

def _apply_spot(out, m, spot):
    found = chain(out, spot)
    if found is None:
        return None, "%s: chain not found" % spot["id"]
    line, half = found
    rows = stations(out, m, spot, line, half)
    level = profile(rows, spot)
    pts = [r[1] for r in rows]
    hs = [level(r[0]) for r in rows]
    # Where the bake's own ground profile (loop 3e, from the 1 m bare earth) already holds the
    # road, its level wins, blended in over HELD_BLEND on each side.
    held = [r[0] for r in rows if r[7]]
    if held:
        for i, row in enumerate(rows):
            d = min(abs(row[0] - s) for s in held)
            if d < HELD_BLEND:
                t = d / HELD_BLEND
                w = 1.0 - t * t * (3 - 2 * t)
                hs[i] = hs[i] + (row[3] - hs[i]) * w
    hs = [round(h, 2) for h in hs]
    l, r = _corridor(spot, max(half))
    fill = _halves(pts, hs, l, r, spot["id"])
    # Retaining walls along it stand from its level (their feet down to it).
    cum = _cum(pts)
    feet = 0
    for w in out.get("walls", []):
        if "b" not in w:
            continue
        for k, q in enumerate(_pairs(w["p"])):
            if k >= len(w["b"]):
                break
            d, s, lat = _station(q, pts, cum)
            if 0.0 < s < cum[-1] and -l - WALL_REACH <= lat <= r + WALL_REACH:
                h = level(s)
                # (counted whether lowered now or on an earlier run: the record stays the same)
                w["b"][k] = min(w["b"][k], round(h - 0.05, 2))
                feet += 1
    spurs = _spurs(out, m, spot, pts, cum, level, l, r)
    banks = _banks(m, pts, hs, l, r, _crossings(out, spot, pts, cum, l, r)) if spot.get("banks", True) else []
    worst = max(abs(hs[k + 1] - hs[k]) / max(cum[k + 1] - cum[k], 1e-9) for k in range(len(hs) - 1))
    rec = {"len": round(cum[-1], 1), "from": hs[0], "to": hs[-1], "steepest": round(worst, 3), "wall_feet": feet,
           "banks": round(sum(_len(_pairs(w["p"])) for w in banks), 1)}
    rec["spurs"] = len(spurs)
    return (fill + spurs, rec, banks), "%s: %.0f m, %.1f to %.1f m, steepest %.1f %%, %d side roads, %d wall feet, %.0f m of bank wall" % (
        spot["id"], cum[-1], hs[0], hs[-1], worst * 100, len(spurs), feet, rec["banks"])


HELD_BLEND = 8.0    # a profile meets the bake's own ground profiles over this

HALF = 0.05         # the inner side of each half's corridor


def _halves(pts, hs, l, r, sid):
    """A profile as ground profiles whose round end caps stay inside it. A ground profile's
    corridor has a disc at each vertex as wide as its narrower side (map_builder
    `_fill_height_base`): at a profile's two ends that disc held the end's level a lane's width
    past it (on a steep street a step where the way goes on), and between its vertices it fills
    the wedge outside each bend. So the middle is one whole profile that stops its cap's width
    short of each end, and each end's last stretch is two one-sided halves (each HALF over the
    line, HALF-wide discs) overlapping the middle by a station; a short profile is halves only.
    (Halves all along left the wedges outside the bends uncovered: single points on the old
    ground, check_drive's 0.3 m jump on Łazienkowska.)"""
    cum = _cum(pts)
    cap = min(l, r) + STEP
    i0 = next((i for i, c in enumerate(cum) if c >= cap), len(pts) - 1)
    i1 = max((i for i, c in enumerate(cum) if c <= cum[-1] - cap), default=0)

    def half(lo, hi):
        p = _flat(pts[lo:hi + 1])
        h = list(hs[lo:hi + 1])
        return [{"p": p, "h": h, "l": round(l, 2), "r": HALF, "k": "road", "s": 1, "rp": sid},
                {"p": list(p), "h": list(h), "l": HALF, "r": round(r, 2), "k": "road", "s": 1, "rp": sid}]
    if i1 - i0 < 1:
        return half(0, len(pts) - 1)
    whole = {"p": _flat(pts[i0:i1 + 1]), "h": list(hs[i0:i1 + 1]), "l": round(l, 2), "r": round(r, 2),
             "k": "road", "s": 1, "rp": sid}
    return half(0, i0 + 1) + [whole] + half(i1 - 1, len(pts) - 1)


SPUR = 12.0         # a side road leaving a profile's corridor ramps from its level to its own over this...
SPUR_GRADE = 0.08   # ...or longer, at no more than this


def _others(out, spot, pts, cum, l, r):
    """The other surface roads that meet the corridor: (road, its points, the indices inside)."""
    lo = (min(p[0] for p in pts) - max(l, r) - 1, min(p[1] for p in pts) - max(l, r) - 1)
    hi = (max(p[0] for p in pts) + max(l, r) + 1, max(p[1] for p in pts) + max(l, r) + 1)
    found = []
    for _, rd in _surface_roads(out):
        q = _pairs(rd["p"])
        if not any(min(a[0], b[0]) <= hi[0] and max(a[0], b[0]) >= lo[0] and min(a[1], b[1]) <= hi[1]
                   and max(a[1], b[1]) >= lo[1] for a, b in zip(q, q[1:])):
            continue
        inside = []
        on_line = 0
        reach = rd["w"] * 0.5 + 1.0   # its edge reaches into the corridor
        for k, v in enumerate(q):
            d, s, lat = _station(v, pts, cum)
            if 0.5 < s < cum[-1] - 0.5 and -l - reach <= lat <= r + reach:
                inside.append(k)
                on_line += d < 0.3
        if inside and on_line < len(q) - 1:   # not the chain's own way (all on the line)
            found.append((rd, q, set(inside)))
    return found


def _structure_ends(out):
    """The ends of the decks' pieces and the tunnels' portals: a side road ramp never reaches
    within STRUCT_CLEAR of one (their approaches have levels of their own)."""
    ends = [(p[0], p[1]) for p in out.get("tunnels", {}).get("portals", [])]
    for piece in out.get("decks", {}).get("pieces", []):
        q = _pairs(piece["p"])
        if q:
            ends += [q[0], q[-1]]
    return ends


STRUCT_CLEAR = 15.0


def _spurs(out, m, spot, pts, cum, level, l, r):
    """Each side road that leaves the corridor gets a short ground profile of its own, from the
    corridor's level where it leaves to its own ground SPUR (or more) further on: no step where
    the profile's edge crosses it, and the drawn ground follows it down or up."""
    fills = []
    ends = _structure_ends(out)
    for rd, q, inside in _others(out, spot, pts, cum, l, r):
        hw = rd["w"] * 0.5
        for k in sorted(inside):
            for step in (1, -1):
                j = k + step
                if not 0 <= j < len(q) or j in inside:
                    continue
                # From q[k] (inside) outwards along the road.
                start = q[k]
                h0 = level(_station(start, pts, cum)[1])
                line = [start] + (q[j:] if step > 0 else q[j::-1])
                lc = _cum(line)
                if any(math.dist(e, v) < STRUCT_CLEAR for e in ends for v in line[:4]):
                    continue
                g_far = m.terrain(*_at(line, lc, min(lc[-1], SPUR))[0])
                L = min(lc[-1], max(SPUR, abs(g_far - h0) / SPUR_GRADE))
                if L < 2.0:
                    continue
                h1 = m.terrain(*_at(line, lc, L)[0])
                if abs(h1 - h0) < 0.15:
                    continue
                n = max(2, int(math.ceil(L / STEP)))
                sp, sh = [], []
                for i in range(n + 1):
                    t = i / n
                    sp.append(_at(line, lc, L * t)[0])
                    sh.append(round(h0 + (h1 - h0) * t * t * (3 - 2 * t), 2))
                fills += _halves(sp, sh, hw + SIDE, hw + SIDE, spot["id"])
    return fills


def _crossings(out, spot, pts, cum, l, r):
    """Stations where another road crosses the corridor's sides (no bank wall across them)."""
    cut = []
    for rd, q, inside in _others(out, spot, pts, cum, l, r):
        for k in inside:
            cut.append((_station(q[k], pts, cum)[1], rd["w"] * 0.5 + 1.0))
    return cut


def _len(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def _banks(m, pts, hs, l, r, cut=()):
    """Retaining walls along the corridor's sides where the profile stands over the ground past
    them by BANK or more (a road on a bench over a lower boulevard): the ground there is drawn on
    the grid, so without a wall the road's edge would hang over it. Stone, open (not solid: the
    pavement's kerb is the edge a car meets), from the ground outside up to the profile. A wall's
    face looks to the left of its direction (map_builder `_build_walls`), so the r side's run
    goes with the chain and the l side's against it."""
    runs = []
    for sign, off in ((1.0, r), (-1.0, l)):
        run = []
        for k in range(len(pts)):
            a = pts[max(k - 1, 0)]
            b = pts[min(k + 1, len(pts) - 1)]
            ln = math.dist(a, b) or 1.0
            ox, oz = -(b[1] - a[1]) / ln * sign, (b[0] - a[0]) / ln * sign
            edge = (pts[k][0] + ox * off, pts[k][1] + oz * off)
            g = m.terrain(pts[k][0] + ox * (off + BANK_OUT), pts[k][1] + oz * (off + BANK_OUT))
            sk = STEP * k
            if hs[k] - g >= BANK and not any(abs(sk - s0) <= w for s0, w in cut):
                run.append((edge, hs[k], g))
                continue
            if len(run) >= 2:
                runs.append(run if sign > 0 else run[::-1])
            run = []
        if len(run) >= 2:
            runs.append(run if sign > 0 else run[::-1])
    return [_wall(run) for run in runs]


def _wall(run):
    return {"p": _flat([e for e, _, _ in run]), "t": [round(h, 2) for _, h, _ in run],
            "b": [round(g, 2) for _, _, g in run], "f": [0] * (len(run) - 1), "k": "stone"}


def apply(out, map_dir=None):
    """Lay every entry's profile (idempotent: an entry's old fill is replaced by its new one)."""
    if map_dir is None:
        map_dir = os.path.join(TOOLS, "..", "game", "map")
    ids = {s["id"] for s in SPOTS}
    out["fills"] = [f for f in out["fills"] if f.get("rp") not in ids]
    out["walls"] = [w for w in out.get("walls", []) if w.get("rp") not in ids]
    rec = {"v": VERSION, "spots": {}}
    msgs = []
    # The ground as it was without any of these profiles: each entry reads the grid and the
    # bake's own fills, never another entry's.
    m = _ground(out, map_dir)
    new = []
    for spot in SPOTS:
        got, msg = _apply_spot(out, m, spot)
        msgs.append(msg)
        if got:
            new += got[0]
            rec["spots"][spot["id"]] = got[1]
            for w in got[2]:
                w["rp"] = spot["id"]
                out["walls"].append(w)
    out["fills"] += new
    out[KEY] = rec
    return "%d of %d places on their own profile%s" % (len(rec["spots"]), len(SPOTS), ("; " + "; ".join(msgs)) if msgs else "")


# --- scan ------------------------------------------------------------------------------------

POKE = 0.3          # map_builder's roads' depth bias (_build_roads: 0.3 m towards the camera)...
POKE_MINOR = 0.25   # ...and the service roads' and living streets' (MINOR_ROAD_BIAS)
DRAPE_EDGE = 12.0   # map_builder _drape_edge: a draped triangle's longest edge
PIECE = 10.0        # map_builder _strip: a plain road's pieces...
PIECE_TAPERED = 2.0 # ...and a tapered one's (_band_var, BAND_PIECE)
SAMPLES = ((1 / 3, 1 / 3), (0.6, 0.2), (0.2, 0.6), (0.2, 0.2), (0.5, 0.5), (0.5, 0.0), (0.0, 0.5),
           (0.5, 0.25), (0.25, 0.5))


def scan(out, map_dir):
    """The torn places: where the drawn ground (map_builder `_build_ground`) stands over the road's
    own draped mesh by more than the road's depth bias, so it shows through the asphalt.

    The road is draped as map_builder lays it: pieces along the way (PIECE), two triangles a piece
    from edge to edge, each split at its longest edge until no edge is over DRAPE_EDGE, each corner
    lifted to the surface (never under the drawn ground, `_emit_draped`). Inside a triangle the
    mesh is flat; the ground's own 10 m triangles (or its 1 m sub-cells) are not, and where they
    fold upward inside it they poke through. Points within CLUSTER are one place, scored by the
    sum of their pokes over the bias. Returns [{x, z, n, worst, score, names, svc}], worst first."""
    m = _ground(out, map_dir)
    corner = {}

    def lifted(x, z):
        k = (round(x, 2), round(z, 2))
        if k not in corner:
            corner[k] = max(m.terrain(x, z), m.drawn(x, z))
        return corner[k]

    pokes = []

    def tri(a, b, c, bias, who, depth=0):
        e = (math.dist(a, b), math.dist(b, c), math.dist(c, a))
        if max(e) > DRAPE_EDGE and depth < 8:
            if e[0] >= e[1] and e[0] >= e[2]:
                h = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
                tri(a, h, c, bias, who, depth + 1)
                tri(h, b, c, bias, who, depth + 1)
            elif e[1] >= e[2]:
                h = ((b[0] + c[0]) / 2, (b[1] + c[1]) / 2)
                tri(a, b, h, bias, who, depth + 1)
                tri(a, h, c, bias, who, depth + 1)
            else:
                h = ((c[0] + a[0]) / 2, (c[1] + a[1]) / 2)
                tri(a, b, h, bias, who, depth + 1)
                tri(h, b, c, bias, who, depth + 1)
            return
        ha, hb, hc = lifted(*a), lifted(*b), lifted(*c)
        worst, at = 0.0, None
        for u, v in SAMPLES:
            w = 1.0 - u - v
            x, z = a[0] * w + b[0] * u + c[0] * v, a[1] * w + b[1] * u + c[1] * v
            pk = m.drawn(x, z) - (ha * w + hb * u + hc * v)
            if pk > worst:
                worst, at = pk, (x, z)
        if worst > bias:
            pokes.append((worst - bias, worst, at, who))

    for ri, r in _surface_roads(out):
        q = _pairs(r["p"])
        hw = r["w"] * 0.5
        bias = POKE_MINOR if r["k"] in ("service", "living_street") else POKE
        who = (r.get("name") or r["k"], r["k"] == "service", ri)
        piece = PIECE_TAPERED if "wv" in r else PIECE
        for a, b in zip(q, q[1:]):
            L = math.dist(a, b)
            if L < 0.01:
                continue
            sx, sz = -(b[1] - a[1]) / L * hw, (b[0] - a[0]) / L * hw
            n = max(1, math.ceil(L / piece))
            for k in range(n):
                p0 = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
                p1 = (a[0] + (b[0] - a[0]) * (k + 1) / n, a[1] + (b[1] - a[1]) * (k + 1) / n)
                c1, c2 = (p0[0] + sx, p0[1] + sz), (p1[0] + sx, p1[1] + sz)
                c3, c4 = (p1[0] - sx, p1[1] - sz), (p0[0] - sx, p0[1] - sz)
                tri(c1, c2, c3, bias, who)
                tri(c1, c3, c4, bias, who)
    places = []
    for over, worst, (x, z), (name, svc, ri) in sorted(pokes, key=lambda p: -p[0]):
        for c in places:
            if math.dist((x, z), (c["x"], c["z"])) < CLUSTER:
                c["n"] += 1
                c["score"] += over
                c["names"].add(name)
                c["svc"] = c["svc"] and svc
                c["at"].setdefault(ri, []).append((x, z))
                break
        else:
            places.append({"x": round(x, 1), "z": round(z, 1), "n": 1, "score": over, "worst": round(worst, 2),
                           "names": {name}, "svc": svc, "at": {ri: [(x, z)]}})
    for c in places:
        c["names"] = sorted(c["names"])
        c["score"] = round(c["score"], 2)
    places.sort(key=lambda c: -c["score"])
    return [c for c in places if c["score"] >= MIN_SCORE]


PROPOSE_RUN = 20.0  # --propose: an entry runs this far past the place's first and last poke


def propose(out, place):
    """Draft entries for one scan place: one a road whose mesh the ground pokes through, from
    PROPOSE_RUN before its first poke to PROPOSE_RUN past its last (within the way), level "mid"."""
    rows = []
    for ri, pts in sorted(place["at"].items()):
        r = out["roads"][ri]
        q = _pairs(r["p"])
        cum = _cum(q)
        ss = [_station(p, q, cum)[1] for p in pts]
        s0, s1 = max(0.0, min(ss) - PROPOSE_RUN), min(cum[-1], max(ss) + PROPOSE_RUN)
        a, b = _at(q, cum, s0)[0], _at(q, cum, s1)[0]
        entry = {"id": "", "a": (round(a[0], 1), round(a[1], 1)), "b": (round(b[0], 1), round(b[1], 1)), "level": "mid"}
        if r.get("name"):
            entry["name"] = r["name"]
        else:
            entry["k"] = r["k"]
        rows.append(entry)
    # Ways that run on from one another (one street split into ways at a junction) are one entry.
    merged = True
    while merged:
        merged = False
        for e in rows:
            for f in rows:
                if e is not f and e.get("name") == f.get("name") and e.get("k") == f.get("k") \
                        and math.dist(e["b"], f["a"]) < 0.5:
                    e["b"] = f["b"]
                    rows.remove(f)
                    merged = True
                    break
            if merged:
                break
    return rows


def _overlap(out, e, f):
    """Whether entries e and f lie on the same road somewhere (an end of one on the other's line)."""
    if e.get("name") != f.get("name") or e.get("k") != f.get("k"):
        return False
    ce, cf = chain(out, e), chain(out, f)
    if ce is None or cf is None:
        return False
    le, lf = ce[0], cf[0]
    return any(_station(p, lf, _cum(lf))[0] < 1.0 for p in (le[0], le[-1])) or \
        any(_station(p, le, _cum(le))[0] < 1.0 for p in (lf[0], lf[-1]))


def _union(out, e, f):
    """e grown to cover f: the two ends, of the four, farthest apart along the road."""
    ends = [e["a"], e["b"], f["a"], f["b"]]
    best = None
    for i in range(4):
        for j in range(i + 1, 4):
            c = chain(out, dict(e, a=ends[i], b=ends[j]))
            if c is not None:
                L = _cum(c[0])[-1]
                if best is None or L > best[0]:
                    best = (L, ends[i], ends[j])
    if best:
        e["a"], e["b"] = best[1], best[2]


def propose_all(out, places, have=()):
    """Draft entries for several places, merged where they share a road; an entry that overlaps
    one of `have` (the table's) is left out (grow the table's entry by hand instead)."""
    rows = []
    for c in places:
        for e in propose(out, c):
            e["_place"] = c
            if any(_overlap(out, e, h) for h in have):
                continue
            for f in rows:
                if _overlap(out, e, f):
                    _union(out, f, e)
                    break
            else:
                rows.append(e)
    return rows


def check(out, map_dir):
    rec = out.get(KEY, {})
    if rec.get("v") != VERSION:
        return False, "not applied (python3 -I tools/road_profiles.py)"
    missing = [s["id"] for s in SPOTS if s["id"] not in rec.get("spots", {})]
    if missing:
        return False, "not applied: " + ", ".join(missing)
    have = {f.get("rp") for f in out["fills"] if f.get("rp")}
    if have != {s["id"] for s in SPOTS}:
        return False, "the profiles in the map are not the table's (re-run python3 -I tools/road_profiles.py)"
    places = scan(out, map_dir)
    streets = sum(1 for c in places if not c["svc"])
    service = len(places) - streets
    msg = "%d places on their own profile; the scan: %d street and %d service-road places torn" % (
        len(SPOTS), streets, service)
    if CHECK_STREETS is not None and streets > CHECK_STREETS:
        worst = [c for c in places if not c["svc"]][:3]
        return False, msg + " (more than %d: %s)" % (CHECK_STREETS, ", ".join(
            "%s at %.0f,%.0f" % ("/".join(c["names"]), c["x"], c["z"]) for c in worst))
    if CHECK_SERVICE is not None and service > CHECK_SERVICE:
        return False, msg + " (more than %d service-road places)" % CHECK_SERVICE
    return True, msg


def show(out, map_dir, sid):
    spot = next((s for s in SPOTS if s["id"] == sid), None)
    if spot is None:
        print("road_profiles: no entry %s" % sid)
        return 1
    # Read the ground without this entry's own profile.
    out["fills"] = [f for f in out["fills"] if f.get("rp") != sid]
    m = _ground(out, map_dir)
    found = chain(out, spot)
    if found is None:
        print("road_profiles: %s: chain not found" % sid)
        return 1
    line, half = found
    rows = stations(out, m, spot, line, half)
    level = profile(rows, spot)
    print("   s       x       z    hw   middle  lowest    grid   level")
    for s, p, hw, mid, low, grid, *_ in rows:
        print("%6.1f %7.1f %7.1f %5.2f %7.2f %7.2f %7.2f %7.2f" % (s, p[0], p[1], hw, mid, low, grid, level(s)))
    return 0


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    map_dir = args[0] if args else os.path.join(TOOLS, "..", "game", "map")
    path = os.path.join(map_dir, "centrum.json")
    out = json.load(open(path, encoding="utf-8"))
    if "--check" in argv:
        ok, msg = check(out, map_dir)
        print("road_profiles: " + msg)
        return 0 if ok else 1
    if "--scan" in argv:
        places = scan(out, map_dir)
        js = [a.split("=", 1)[1] for a in argv if a.startswith("--json=")]
        if js:
            json.dump([{k: v for k, v in c.items() if k != "at"} for c in places], open(js[0], "w"),
                      ensure_ascii=False, indent=0)
        streets = [c for c in places if not c["svc"]]
        print("road_profiles: %d street and %d service-road places torn" % (len(streets), len(places) - len(streets)))
        for k, c in enumerate(places if "--all" in argv else streets[:40]):
            print("%3d %-45s %7.1f,%7.1f  n %3d  worst %.2f m  score %.2f%s" % (
                k + 1, ", ".join(c["names"])[:45], c["x"], c["z"], c["n"], c["worst"], c["score"],
                "  (service)" if c["svc"] else ""))
        return 0
    pr = [a.split("=", 1)[1] for a in argv if a.startswith("--propose=")]
    if pr:
        places = scan(out, map_dir)
        streets = [c for c in places if not c["svc"]]
        pick = streets if pr[0] != "service" else [c for c in places if c["svc"]]
        for k, c in enumerate(pick[:int(pr[-1]) if pr[-1].isdigit() else 20]):
            print("    # %s at %.0f,%.0f: %d pokes, worst %.2f m, score %.2f" % (
                ", ".join(c["names"]), c["x"], c["z"], c["n"], c["worst"], c["score"]))
            for e in propose(out, c):
                print("    " + json.dumps(e, ensure_ascii=False).replace("[", "(").replace("]", ")") + ",")
        return 0
    sh = [a.split("=", 1)[1] for a in argv if a.startswith("--show=")]
    if sh:
        return show(out, map_dir, sh[0])
    print("road_profiles: " + apply(out, map_dir))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(out, fh, separators=(",", ":"), ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
