"""Whole-map check of the roads, bridge decks, tunnels and the lane graph (loop 3a; the
rules C1-C10 of docs/DEMO.md section 4.5).

Usage: python3 -I tools/check_roads.py [--map=game/map] [--osm=data/work/demo/osm_demo.json]
           [--rules=C1,C3] [--later=C4,C5] [--json=shots/check_roads.json]
           [--png=shots/check_roads.png | --no-png] [--allow=tools/check_roads_allow.json] [--all] [--quiet]

It mirrors the game's height rules (map_builder.gd: the terrain's two triangles per 10 m
cell, the deck corridors, `deck_height`, `drive_height`, the tunnel pieces; lane_graph.gd:
lane heights every 8 m) and reads `centrum.json`, `terrain.json`, `lod2.json` + `lod2.bin`
and the raw OpenStreetMap export (for C7 only; skipped when it isn't there).

| Rule | A finding |
| C1  grade      | a drivable road's own surface rises > 12 % over any 6 m (service roads 20 %) |
| C2  joints     | roads sharing a vertex differ by > 0.15 m in surface height there; or (map review A) a kerb or edge line runs across the road at a deck's joint with the ground (3 m or more within 4 m of the end) |
| C3  clearance  | a ground road, tram or rail under a deck with 0.3 m < clearance < 4.7 m (footways < 2.5 m) |
| C4  piers      | a pier footprint (the bake's `decks.piers`, loop 3b) within 1 m of a road (half-width), tram or rail under it |
| C5  solids     | a road or lane runs >= 4 m inside a building / landmark footprint around its height |
| C6  deck ends  | a deck piece ends > 1 m above the terrain with nothing continuing (the map's rim allowed) |
| C7  dropped    | the raw OSM has a drivable tunnel or cutting the map file doesn't |
| C8  lanes      | a lane's height steps > 0.5 m within 4 m, or edges meeting at a node differ by > 0.2 m |
| C9  thru decks | a building's top is above a deck's slab bottom inside the deck's corridor; or (map review A) a scanned tree's crown reaches into a deck between its slab's bottom and the head room over it |
| C10 landmarks  | a landmark collider within 0.5 m of a lane corridor (lane offset +- 1.2 m) |
| C11 under      | (map round 2) a road's, carriageway's, tram's or rail's surface on the ground lies more than 0.1 m under the drawn ground (map_builder `_build_ground`'s mesh) |

Each finding prints with map coordinates and a ready `--at=` view. Findings listed in
tools/check_roads_allow.json (each entry: rule, at, r, reason, source; optional name) are
allowed. Writes a JSON report and an image of the findings over the orthophoto
(data/raw/gugik/ortho.bmp; standard library only: a BMP reader and a PNG writer below).
Exit 0 when every finding is allowed, 1 otherwise, 2 for a usage or data error; 3 when the
only findings not allowed are in the `--later` rules (loop 3a's verify step used it for C4, C5,
C9, C10; since loop 3b every rule FAILs in tools/verify.sh).
Loop 3b: the builder's structures are the bake's (tools/bake_structures.py): C4 checks the
placed piers, C5/C9 see the buildings cut under decks (`cut`, `lod2_cuts`), C10 the seated
Poniatowski towers (`towers`), the terrain includes the `aprons` at structure ends.
"""
import array
import json
import math
import os
import struct
import sys
import time
import zlib
from collections import defaultdict

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_osm  # noqa: E402  (bounding box, projection, clipping)
import map_shape  # noqa: E402  (map north: the box and its north extension)

DRIVABLE = set(bake_osm.DRIVABLE)
GRADE_MAX = 0.12          # C1
GRADE_MAX_SERVICE = 0.20
GRADE_RUN = 6.0
JOINT_MAX = 0.15          # C2
JOINT_ALONG, JOINT_RUN = 4.0, 3.0   # C2 (map review A): kerbs / edge lines across a deck's joint
CLEAR_MIN, CLEAR_MAX, CLEAR_FOOT = 0.3, 4.7, 2.5   # C3
PIER_PAD = 1.0            # C4
SOLID_RUN = 4.0           # C5
SOLID_ABOVE = 3.0
AIR_MAX = 1.0             # C6
LANE_STEP, LANE_JUMP, LANE_NODE = 4.0, 0.5, 0.2   # C8
SLAB = 1.3 + 0.08         # C9: the slab under every deck (map_builder _build_bridge_structures)
TREE_HEAD = {"road": 3.5, "rail": 3.5, "tram": 3.5, "path": 2.5}   # C9 (map review A): bake_structures CROWN_HEAD
LANDMARK_PAD = 0.5        # C10
UNDER_MAX = 0.10          # C11 (map round 2): a surface this far under the drawn ground is hidden (the rail beds' 0.2 m depth bias holds 0.1 m at the 30 degree view; roads 0.3 m hold 0.15 m)
LANE_HALF = 1.2
TRAM_HALF, RAIL_HALF = 1.5, 2.0
HEIGHT_STEP = 8.0         # lane_graph.gd
DECK_CELL = 16.0          # map_builder.gd
APRON_TAPER = 3.0         # map_builder.gd APRON_TAPER (map round 2): an apron fades out past its sides
FILL_SEAM = 0.4           # map_builder.gd FILL_SEAM (PT-41): a sliver between two approaches takes the lower level
FILL_SEAM_STEP = 1.0      # map_builder.gd FILL_SEAM_STEP: ...when their levels there are this close
SET_SINK = 0.1            # map_builder.gd SET_SINK (loop 3e): the drawn ground under a lowering ground profile
SET_FINE = 0.001          # map_builder.gd SET_FINE (loop 3e): sub-cells only where a profile lies this far under the grid
TUNNEL_MOUTH = 4.8        # tools/bake_structures.py MOUTH: a tunnel's mouth (C5 over a tunnel, loop 3e)
APRON_IN = 4.0            # tools/bake_structures.py: an apron starts this far inside a structure's end (its `i`)

RULES = [("C1", "grade"), ("C2", "joints"), ("C3", "clearance"), ("C4", "piers"), ("C5", "solids"),
         ("C6", "deck ends in the air"), ("C7", "dropped ways"), ("C8", "lanes"), ("C9", "through decks"),
         ("C10", "landmarks"), ("C11", "under the ground")]
COLOURS = {"C1": (255, 60, 60), "C2": (255, 140, 0), "C3": (255, 230, 0), "C4": (0, 220, 255),
           "C5": (255, 80, 255), "C6": (120, 255, 120), "C7": (255, 255, 255), "C8": (80, 140, 255),
           "C9": (190, 120, 255), "C10": (255, 170, 170), "C11": (255, 255, 120)}


# Most Poniatowskiego's tower shafts and stair turrets (landmarks.gd PT_SHAFT, PT_SHAFT_U,
# PT_SHAFT_V, PT_TURRET): the shaft's half size, its centre past the seat's land end and out
# from its deck-side face; the turret's (along, out, radius) in the seat's frame.
PT_SHAFT, PT_SHAFT_U, PT_SHAFT_V = 3.5, 0.5, 3.5
PT_TURRET = (3.5, 9.5, 2.5)
PT_RAMP_BOX = (-0.6, 6.6, 11.8)   # the north groups' stair (landmarks.gd PT_RAMP_BOX: u0, u1, v1; v0 = hv)

def pairs(f):
    return list(zip(f[0::2], f[1::2]))


def cum_of(pts):
    c = [0.0]
    for a, b in zip(pts, pts[1:]):
        c.append(c[-1] + math.dist(a, b))
    return c


def sample(pts, step):
    """Points every `step` metres along a polyline (its own end included)."""
    out = []
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.dist(a, b) / step))
        for k in range(n):
            t = k / n
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    out.append(pts[-1])
    return out


def seg_dist2(x, z, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    l2 = abx * abx + abz * abz
    t = 0.0 if l2 < 1e-12 else min(max(((x - a[0]) * abx + (z - a[1]) * abz) / l2, 0.0), 1.0)
    return (x - a[0] - abx * t) ** 2 + (z - a[1] - abz * t) ** 2


def seg_seg_dist(a, b, c, d):
    if _cross(a, b, c, d):
        return 0.0
    return math.sqrt(min(seg_dist2(a[0], a[1], c, d), seg_dist2(b[0], b[1], c, d),
                         seg_dist2(c[0], c[1], a, b), seg_dist2(d[0], d[1], a, b)))


def _cross(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    o1, o2, o3, o4 = orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b)
    return (o1 > 0) != (o2 > 0) and (o3 > 0) != (o4 > 0)


def point_in_poly(x, z, q):
    inside = False
    j = len(q) - 1
    for i in range(len(q)):
        xi, zi = q[i]
        xj, zj = q[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            inside = not inside
        j = i
    return inside


def offset_line(pts, off):
    out = []
    for i in range(len(pts)):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        d = math.dist(a, b)
        if d < 1e-6:
            out.append(pts[i])
            continue
        out.append((pts[i][0] - (b[1] - a[1]) / d * off, pts[i][1] + (b[0] - a[0]) / d * off))
    return out


class Grid:
    def __init__(self, cell=16.0):
        self.cell = cell
        self.cells = defaultdict(list)

    def add(self, item, x0, z0, x1, z1):
        c = self.cell
        for i in range(math.floor(x0 / c), math.floor(x1 / c) + 1):
            for j in range(math.floor(z0 / c), math.floor(z1 / c) + 1):
                self.cells[(i, j)].append(item)

    def at(self, x, z):
        return self.cells.get((math.floor(x / self.cell), math.floor(z / self.cell)), ())


# --- the map, as the game sees it ---------------------------------------------------------

class Pieces:
    """Deck (or tunnel) pieces with map_builder.gd's lookups: the corridors over a point
    (`at`, as `_decks_at`) and a group's height at a point (`height`, as `deck_height`)."""

    def __init__(self, raw):
        self.p = []
        for pc in raw:
            pts = pairs(pc["p"])
            self.p.append({"pts": pts, "cum": cum_of(pts), "h": pc["h"], "l": pc["l"], "r": pc["r"], "g": pc["g"],
                           "k": pc.get("k", "road"), "s": bool(pc.get("s"))})
        self.any = defaultdict(list)
        self.byg = defaultdict(list)
        self.groups = defaultdict(list)
        for i, d in enumerate(self.p):
            self.groups[d["g"]].append(i)
            reach = max(d["l"], d["r"]) + 1.0
            for k in range(len(d["pts"]) - 1):
                a, b = d["pts"][k], d["pts"][k + 1]
                for cz in range(math.floor((min(a[1], b[1]) - reach) / DECK_CELL), math.floor((max(a[1], b[1]) + reach) / DECK_CELL) + 1):
                    for cx in range(math.floor((min(a[0], b[0]) - reach) / DECK_CELL), math.floor((max(a[0], b[0]) + reach) / DECK_CELL) + 1):
                        self.any[(cx, cz)].append((i, k))
                        self.byg[(cx, cz, d["g"])].append((i, k))

    def at(self, x, z, ends=False):
        """[(height, group, piece)] of the corridors holding the point (`ends`: also a little
        past a piece's ends, as map_builder's fills)."""
        near = {}
        for i, k in self.any.get((math.floor(x / DECK_CELL), math.floor(z / DECK_CELL)), ()):
            d = self.p[i]
            a, b = d["pts"][k], d["pts"][k + 1]
            abx, abz = b[0] - a[0], b[1] - a[1]
            l2 = max(abx * abx + abz * abz, 1e-6)
            u = ((x - a[0]) * abx + (z - a[1]) * abz) / l2
            t = min(max(u, 0.0), 1.0)
            d2 = (x - a[0] - abx * t) ** 2 + (z - a[1] - abz * t) ** 2
            if i not in near or d2 < near[i][0]:
                near[i] = (d2, k, u)
        out = []
        for i, (d2, k, u) in near.items():
            d = self.p[i]
            if ends:
                if (u < 0 and k > 0) or (u > 1 and k < len(d["pts"]) - 2) or u < -0.05 or u > 1.05:
                    continue
            elif (k == 0 and u < 0) or (k == len(d["pts"]) - 2 and u > 1):
                continue
            a, b = d["pts"][k], d["pts"][k + 1]
            abx, abz = b[0] - a[0], b[1] - a[1]
            lat = (abx * (z - a[1]) - abz * (x - a[0])) / max(math.hypot(abx, abz), 1e-3)
            if -d["l"] <= lat <= d["r"]:
                t = min(max(u, 0.0), 1.0)
                out.append((d["h"][k] + (d["h"][k + 1] - d["h"][k]) * t, d["g"], i))
        return out

    def height(self, g, x, z, fallback):
        best, h = 1e18, fallback
        cx, cz = math.floor(x / DECK_CELL), math.floor(z / DECK_CELL)
        for dz in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for i, k in self.byg.get((cx + dx, cz + dz, g), ()):
                    d = self.p[i]
                    a, b = d["pts"][k], d["pts"][k + 1]
                    abx, abz = b[0] - a[0], b[1] - a[1]
                    t = min(max(((x - a[0]) * abx + (z - a[1]) * abz) / max(abx * abx + abz * abz, 1e-6), 0.0), 1.0)
                    d2 = (x - a[0] - abx * t) ** 2 + (z - a[1] - abz * t) ** 2
                    if d2 < best:
                        best = d2
                        h = d["h"][k] + (d["h"][k + 1] - d["h"][k]) * t
        if best < 1e18:
            return h
        for i in self.groups.get(g, ()):
            d = self.p[i]
            for k in range(len(d["pts"]) - 1):
                a, b = d["pts"][k], d["pts"][k + 1]
                abx, abz = b[0] - a[0], b[1] - a[1]
                t = min(max(((x - a[0]) * abx + (z - a[1]) * abz) / max(abx * abx + abz * abz, 1e-6), 0.0), 1.0)
                d2 = (x - a[0] - abx * t) ** 2 + (z - a[1] - abz * t) ** 2
                if d2 < best:
                    best = d2
                    h = d["h"][k] + (d["h"][k + 1] - d["h"][k]) * t
        return h


class Map:
    def __init__(self, map_dir):
        self._setup(map_dir, json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8")),
                    json.load(open(os.path.join(map_dir, "terrain.json"))))

    @classmethod
    def from_data(cls, map_dir, d, terrain):
        """Loop 3b: the map as the game will see it, from a map file still being baked
        (tools/bake_structures.py places the piers, walls and cuts with these lookups)."""
        m = cls.__new__(cls)
        m._setup(map_dir, d, terrain)
        return m

    def _setup(self, map_dir, d, t):
        self.dir = map_dir
        self.d = d
        self.tx0, self.tz0, self.step, self.nx, self.nz = t["x0"], t["z0"], t["step"], t["nx"], t["nz"]
        self.th = list(t["h"])
        # Loop 3a: underpass dips cut into the terrain (`cuts` in centrum.json), as map_builder applies them.
        for c in self.d.get("cuts", []):
            nx = self.nx
            for k in range(0, len(c["n"]), 2):
                self.th[c["n"][k]] -= c["n"][k + 1]
        self.bounds = self.d["bounds"]
        self.shape = map_shape.of(self.d)   # map north: the bounds without what is `outside`
        # Loop 3a: the approaches correct the ground under their corridors (map_builder
        # terrain_height: the higher of the grid and the fill).
        self.fills = Pieces([dict(f, g=k) for k, f in enumerate(self.d.get("fills", []))])
        self.fill_cells = defaultdict(list)
        for i, d in enumerate(self.fills.p):
            reach = max(d["l"], d["r"]) + 0.5
            for k in range(len(d["pts"]) - 1):
                a, b = d["pts"][k], d["pts"][k + 1]
                for cz in range(math.floor((min(a[1], b[1]) - reach) / 16.0), math.floor((max(a[1], b[1]) + reach) / 16.0) + 1):
                    for cx in range(math.floor((min(a[0], b[0]) - reach) / 16.0), math.floor((max(a[0], b[0]) + reach) / 16.0) + 1):
                        self.fill_cells[(cx, cz)].append((i, k))
        self.decks = Pieces(self.d.get("decks", {}).get("pieces", []))
        self.tunnels = Pieces(self.d.get("tunnels", {}).get("pieces", []))
        # Loop 3b: aprons where a structure's end meets the ground (map_builder terrain_height).
        self.aprons = []
        for a in self.d.get("aprons", []):
            x0, z0, x1, z1 = a["p"]
            ln = math.hypot(x1 - x0, z1 - z0) or 1.0
            self.aprons.append((x0, z0, (x1 - x0) / ln, (z1 - z0) / ln, ln, a["h"], a["l"], a["r"], a.get("i", APRON_IN)))
        self.fine = None   # C11: the grid cells the drawn ground subdivides (built on first use)
        self.apron_cells = defaultdict(list)
        for k, (x0, z0, ux, uz, ln, h, l, r, inner) in enumerate(self.aprons):
            reach = max(l, r) + APRON_TAPER + ln
            for cz in range(math.floor((z0 - reach) / 16.0), math.floor((z0 + reach) / 16.0) + 1):
                for cx in range(math.floor((x0 - reach) / 16.0), math.floor((x0 + reach) / 16.0) + 1):
                    self.apron_cells[(cx, cz)].append(k)

    def terrain(self, x, z):
        """map_builder terrain_height: the grid, raised to any approach whose corridor holds the
        point; loop 3e: a ground profile's ("s" fills) level where one holds it (the nearest)."""
        h = self.grid(x, z)
        set_h, set_lat = None, 1e9
        held, seam = False, {}   # PT-41: map_builder FILL_SEAM
        for i, k in self.fill_cells.get((math.floor(x / 16.0), math.floor(z / 16.0)), ()):
            d = self.fills.p[i]
            a, b = d["pts"][k], d["pts"][k + 1]
            abx, abz = b[0] - a[0], b[1] - a[1]
            l2 = abx * abx + abz * abz
            if l2 < 1e-6:
                continue
            u = ((x - a[0]) * abx + (z - a[1]) * abz) / l2
            if d["s"]:
                # Loop 3e: a ground profile's corridor has round joins (a disc at each vertex: no
                # wedge of the grid left on the outside of a bend or between two pieces).
                w = min(d["l"], d["r"])
                for q, hq in ((a, d["h"][k]), (b, d["h"][k + 1])):
                    dq = math.hypot(x - q[0], z - q[1])
                    if dq <= w and dq < set_lat:
                        set_h, set_lat = hq, dq
            if (u < 0 and k > 0) or (u > 1 and k < len(d["pts"]) - 2) or u < -0.05 or u > 1.05:
                continue
            lat = (abx * (z - a[1]) - abz * (x - a[0])) / math.sqrt(l2)
            if -d["l"] <= lat <= d["r"]:
                t = min(max(u, 0.0), 1.0)
                v = d["h"][k] + (d["h"][k + 1] - d["h"][k]) * t
                if d["s"]:
                    if abs(lat) < set_lat:
                        set_h, set_lat = v, abs(lat)
                else:
                    h = max(h, v)
                    held = True
            elif not d["s"] and -d["l"] - FILL_SEAM <= lat <= d["r"] + FILL_SEAM:
                t = min(max(u, 0.0), 1.0)
                seam[i] = max(seam.get(i, -1e9), d["h"][k] + (d["h"][k + 1] - d["h"][k]) * t)
        if not held and len(seam) >= 2:
            # PT-41: between two approaches side by side (the first two found), the lower one's level.
            ha, hb = list(seam.values())[:2]
            if abs(ha - hb) <= FILL_SEAM_STEP:
                h = max(h, min(ha, hb))
        self.set_hit = set_h is not None
        if set_h is not None:
            h = set_h
        for k in self.apron_cells.get((math.floor(x / 16.0), math.floor(z / 16.0)), ()):
            x0, z0, ux, uz, ln, ha, l, r, inner = self.aprons[k]
            along = (x - x0) * ux + (z - z0) * uz
            lat = (z - z0) * ux - (x - x0) * uz
            out = max(-l - lat, lat - r)   # map round 2: the apron fades out past its sides
            if 0.0 <= along <= ln and out < APRON_TAPER:
                target = min(h, ha) if along < inner else ha + (h - ha) * ((along - inner) / (ln - inner))
                h = target if out <= 0.0 else target + (h - target) * (out / APRON_TAPER)
        return h

    def grid(self, x, z):
        fx = min(max((x - self.tx0) / self.step, 0.0), self.nx - 1.0001)
        fz = min(max((z - self.tz0) / self.step, 0.0), self.nz - 1.0001)
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        nx, h = self.nx, self.th
        h00, h10 = h[j * nx + i], h[j * nx + i + 1]
        h01, h11 = h[(j + 1) * nx + i], h[(j + 1) * nx + i + 1]
        if u >= v:
            return h00 + (h10 - h00) * u + (h11 - h10) * v
        return h00 + (h11 - h01) * u + (h01 - h00) * v

    GROUND_SUB = 10   # map_builder GROUND_SUB
    SET_SUB = 10      # map_builder SET_SUB (loop 3e): a cell only a ground profile reaches

    def drawn(self, x, z):
        """C11 (map round 2): the drawn ground mesh's height (map_builder `_drawn_height`): the
        10 m grid's two triangles per cell, and in the cells an apron reaches GROUND_SUB x
        GROUND_SUB sub-cells at min(grid, terrain)."""
        if self.fine is None:
            self.fine = {}   # (i, j) -> sub-cells a side (map_builder _fine_cells)
            # Loop 3e: and the cells a ground profile ("s" fill) reaches (map_builder _fine_index).
            for d in self.fills.p:
                if not d["s"]:
                    continue
                reach = max(d["l"], d["r"])
                for k in range(len(d["pts"]) - 1):
                    a, b = d["pts"][k], d["pts"][k + 1]
                    # Only where it lowers the ground (map_builder _set_lowers).
                    h = min(d["h"][k], d["h"][k + 1])
                    ln = math.hypot(b[0] - a[0], b[1] - a[1])
                    nx, nz = ((-(b[1] - a[1]) / ln * reach, (b[0] - a[0]) / ln * reach) if ln > 1e-3 else (0.0, 0.0))
                    if not any(h < self.grid(px, pz) - SET_FINE for px, pz in
                               (a, b, (a[0] + nx, a[1] + nz), (a[0] - nx, a[1] - nz), (b[0] + nx, b[1] + nz), (b[0] - nx, b[1] - nz))):
                        continue
                    for j in range(min(max(math.floor((min(a[1], b[1]) - reach - self.tz0) / self.step), 0), self.nz - 2),
                                   min(max(math.floor((max(a[1], b[1]) + reach - self.tz0) / self.step), 0), self.nz - 2) + 1):
                        for i in range(min(max(math.floor((min(a[0], b[0]) - reach - self.tx0) / self.step), 0), self.nx - 2),
                                       min(max(math.floor((max(a[0], b[0]) + reach - self.tx0) / self.step), 0), self.nx - 2) + 1):
                            self.fine[(i, j)] = max(self.fine.get((i, j), 0), self.SET_SUB)
            for x0, z0, ux, uz, ln, h, l, r, inner in self.aprons:
                xs, zs = [], []
                for along in (0.0, ln):
                    for lat in (-l - APRON_TAPER, r + APRON_TAPER):
                        xs.append(x0 + ux * along - uz * lat)
                        zs.append(z0 + uz * along + ux * lat)
                for j in range(min(max(math.floor((min(zs) - self.tz0) / self.step), 0), self.nz - 2),
                               min(max(math.floor((max(zs) - self.tz0) / self.step), 0), self.nz - 2) + 1):
                    for i in range(min(max(math.floor((min(xs) - self.tx0) / self.step), 0), self.nx - 2),
                                   min(max(math.floor((max(xs) - self.tx0) / self.step), 0), self.nx - 2) + 1):
                        self.fine[(i, j)] = self.GROUND_SUB
        fx = min(max((x - self.tx0) / self.step, 0.0), self.nx - 1.0001)
        fz = min(max((z - self.tz0) / self.step, 0.0), self.nz - 1.0001)
        i, j = int(fx), int(fz)
        if (i, j) not in self.fine:
            return self.grid(x, z)
        n = self.fine[(i, j)]
        sub = self.step / n
        si = min(max(int((fx - i) * n), 0), n - 1)
        sj = min(max(int((fz - j) * n), 0), n - 1)
        x0 = self.tx0 + i * self.step + si * sub
        z0 = self.tz0 + j * self.step + sj * sub
        u = min(max((x - x0) / sub, 0.0), 1.0)
        v = min(max((z - z0) / sub, 0.0), 1.0)

        def c(px, pz):
            g, t = self.grid(px, pz), self.terrain(px, pz)
            if self.set_hit and t < g - 0.001:
                t -= SET_SINK   # loop 3e: map_builder _drawn_corner
            return min(g, t)
        h00, h10, h01, h11 = c(x0, z0), c(x0 + sub, z0), c(x0, z0 + sub), c(x0 + sub, z0 + sub)
        if u >= v:
            return h00 + (h10 - h00) * u + (h11 - h10) * v
        return h00 + (h11 - h01) * u + (h01 - h00) * v

    def deck_height(self, g, x, z):
        if g is None or g < 0:
            return self.terrain(x, z)
        return self.decks.height(g, x, z, self.terrain(x, z))

    def tunnel_height(self, t, x, z):
        return self.tunnels.height(t, x, z, self.terrain(x, z))

    def ground_height(self, x, z):
        h = self.terrain(x, z)
        for hd, _, _ in self.decks.at(x, z):
            h = max(h, hd)
        return h

    def surface(self, item, x, z):
        """The surface a road, track or footway is drawn on: its deck, its tunnel or the terrain."""
        if item.get("tn") is not None:
            return self.tunnel_height(item["tn"], x, z)
        g = item.get("dk")
        return self.deck_height(g, x, z) if g is not None and g >= 0 else self.terrain(x, z)

    def on_rim(self, x, z, pad=1.0):
        return self.shape.rim(x, z) < pad


# --- buildings and landmarks (C5, C9, C10) -------------------------------------------------

class Landmarks:
    """The landmark sites of landmarks.gd (zones that replace LoD2/OSM lumps) and the car
    colliders it builds: Most Poniatowskiego's towers exactly, the others by their outline."""

    def __init__(self, d):
        self.zones = []      # [(key, [polys], [keep polys])]
        self.colliders = []  # [(key, poly)]
        blds = d["buildings"]
        lm = {l["name"]: pairs(l["p"]) for l in d.get("landmarks", [])}

        def centre(q):
            return (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))

        # The Copernicus Science Centre and its planetarium (spec kopernik.md) collide along
        # their outlines, the overhanging corner included; the University Library (spec buw.md)
        # along its outline too (its copper plates and columns on Dobra have car walls of their own).
        for key, name in (("palace", "Pałac Kultury i Nauki"), ("rotunda", "Rotunda PKO"), ("varso", "Varso Tower"),
                          ("kopernik", "Centrum Nauki Kopernik"), ("kopernik", "Planetarium Niebo Kopernika"),
                          ("buw", "Biblioteka Uniwersytecka")):
            if len(lm.get(name, [])) >= 3:
                self.zones.append((key, [lm[name]], []))
                self.colliders.append((key, lm[name]))
        # The library's court in the south notch: Collegium Iuridicum II, built by the site (pass 3).
        for b in blds:
            if b.get("name") == "Collegium Iuridicum II" and len(b["p"]) >= 6:
                self.zones.append(("buw", [pairs(b["p"])], []))
                self.colliders.append(("buw", pairs(b["p"])))
        tar = lm.get("Złote Tarasy", [])
        if len(tar) >= 3:
            # The whole complex inside its outline is the landmark (spec tarasy.md): the domes
            # collide along the wave's rim, the parts standing on the ground along their own.
            inside = [b for b in blds if len(b["p"]) >= 6 and b["h"] > b["mh"] and not b.get("br")
                      and point_in_poly(*centre(pairs(b["p"])), tar)]
            if inside:
                self.zones.append(("tarasy", [tar], []))
                self.colliders += [("tarasy", pairs(b["p"])) for b in inside
                                   if (str(b["c"]).lower() == "#336699" and b["h"] >= 20.0) or b["mh"] < 0.5]
        # Stadion Narodowy: the zone from its outer masts (landmarks.gd _find_stadium).
        inner, outer = [], []
        for b in blds:
            q = pairs(b["p"])
            if len(q) < 3:
                continue
            c = centre(q)
            if not (1250 <= c[0] <= 1700 and -820 <= c[1] <= -370):
                continue
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            if math.hypot(max(xs) - min(xs), max(zs) - min(zs)) > 2.5:
                continue
            if abs(b["h"] - 50.0) < 0.5 and b["mh"] < 0.5:
                inner.append(c)
            elif abs(b["h"] - 60.0) < 0.5 and abs(b["mh"] - 44.0) < 0.5:
                outer.append(c)
        if len(inner) >= 24 and len(inner) == len(outer):
            cx = sum(p[0] for p in inner) / len(inner)
            cz = sum(p[1] for p in inner) / len(inner)
            outer.sort(key=lambda p: math.atan2(p[1] - cz, p[0] - cx))
            zone = [(cx + (p[0] - cx) * 1.08, cz + (p[1] - cz) * 1.08) for p in outer]
            self.zones.append(("stadium", [zone], []))
            inner.sort(key=lambda p: math.atan2(p[1] - cz, p[0] - cx))
            self.colliders.append(("stadium", inner))
        # Warszawa Centralna (a fixed frame).
        a = (math.cos(math.radians(-19.4)), math.sin(math.radians(-19.4)))
        bvec = (-a[1], a[0])
        cen = (-1420.0, 572.5)

        def frame(u, v):
            return (cen[0] + a[0] * u + bvec[0] * v, cen[1] + a[1] * u + bvec[1] * v)
        self.zones.append(("centralna", [[frame(u, v) for u, v in ((-73, -45.5), (73, -45.5), (73, 46.5), (-73, 46.5))]], []))
        # The model's car walls (spec centralna.md): the mapped hall and wings, the vestibules
        # and the pillars, as landmarks.gd _find_centralna sorts the parts in the zone (the
        # pillars and vestibules inside the hall or a wing add nothing, so all are listed).
        czone = [frame(u, v) for u, v in ((-73, -45.5), (73, -45.5), (73, 46.5), (-73, 46.5))]
        for b in blds:
            q = pairs(b["p"])
            if len(q) < 3 or b["h"] <= b["mh"] or not point_in_poly(*centre(q), czone):
                continue
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            span = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
            area = abs(sum(q[i][0] * q[(i + 1) % len(q)][1] - q[(i + 1) % len(q)][0] * q[i][1] for i in range(len(q)))) / 2
            pillar = abs(b["h"] - 15.0) < 0.5 and b["mh"] < 0.5 and span < 3.0
            walls = b["mh"] < 11.0 and ((b["h"] >= 11.0 and area > 300.0) or (b["h"] <= 3.5 and area < 500.0))
            if pillar or walls:
                self.colliders.append(("centralna", q))
        # Most Poniatowskiego's towers. Loop 3b (R7): the bake's seats (`towers`,
        # tools/bake_structures.py), as landmarks.gd builds them: the plinth (0.6 m round the
        # shaft) is the collider, the zone is the one the bake wrote.
        # Since the photo build (landmarks.gd `_pt_group`) each group is also its shaft at the
        # land end (PT_SHAFT*) and, on the south groups, a stair turret (PT_TURRET), on the north
        # ones the switchback stair (PT_RAMP_BOX), all solid.
        seats = d.get("towers", [])
        if len(seats) == 4:
            self.towers = []
            zone = []
            mx = sum(t["c"][0] for t in seats) / 4.0
            mz = sum(t["c"][1] for t in seats) / 4.0
            for t in seats:
                cx, cz = t["c"]
                ax = t["a"]
                if (cx - mx) * ax[0] + (cz - mz) * ax[1] < 0.0:
                    ax = (-ax[0], -ax[1])
                bv = (-ax[1], ax[0])
                other = min((o for o in seats if o is not t), key=lambda o: math.dist(o["c"], t["c"]))
                px, pz = (cx + other["c"][0]) * 0.5, (cz + other["c"][1]) * 0.5
                if (cx - px) * bv[0] + (cz - pz) * bv[1] < 0.0:
                    bv = (-bv[0], -bv[1])

                def at(u, v):
                    return (cx + ax[0] * u + bv[0] * v, cz + ax[1] * u + bv[1] * v)
                hu, hv = t["hu"] + 0.6, t["hv"] + 0.6
                rect = [at(u, v) for u, v in ((-hu, -hv), (hu, -hv), (hu, hv), (-hu, hv))]
                self.towers.append(rect)
                self.colliders.append(("poniatowski tower", rect))
                su, sv, r = t["hu"] + PT_SHAFT_U, -t["hv"] + PT_SHAFT_V, PT_SHAFT + 0.3
                self.colliders.append(("poniatowski tower", [at(su + u, sv + v) for u, v in ((-r, -r), (r, -r), (r, r), (-r, r))]))
                if cz > pz:
                    tu, tv, tr = PT_TURRET
                    self.colliders.append(("poniatowski tower", [at(tu + tr * math.cos(k * math.pi / 4), tv + tr * math.sin(k * math.pi / 4)) for k in range(8)]))
                else:
                    u0, u1, v1 = PT_RAMP_BOX
                    v0 = t["hv"]
                    self.colliders.append(("poniatowski tower", [at(u, v) for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))]))
                zone.append(pairs(t["zone"]))
            self.zones.append(("poniatowski", zone, []))
            return
        found = []
        for area in ((910, -165, 40, 60), (1398, -332, 45, 65)):
            for b in blds:
                q = pairs(b["p"])
                if len(q) < 3:
                    continue
                c = centre(q)
                if not (area[0] <= c[0] <= area[0] + area[2] and area[1] <= c[1] <= area[1] + area[3]):
                    continue
                xs, zs = [p[0] for p in q], [p[1] for p in q]
                span = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
                if span < 7.0 or span > 24.0:
                    continue
                if not any(math.dist(centre(f), c) < 9.0 for f in found):
                    found.append(q)
        self.towers = []
        if len(found) == 4:
            zone = []
            for q in found:
                c = centre(q)
                best, ax = 0.0, (1.0, 0.0)
                for i in range(len(q)):
                    e = (q[(i + 1) % len(q)][0] - q[i][0], q[(i + 1) % len(q)][1] - q[i][1])
                    ln = math.hypot(*e)
                    if ln > best:
                        best, ax = ln, (e[0] / ln, e[1] / ln)
                bv = (-ax[1], ax[0])
                hu = min(max(abs((p[0] - c[0]) * ax[0] + (p[1] - c[1]) * ax[1]) for p in q), 8.0) + 0.6
                hv = min(max(abs((p[0] - c[0]) * bv[0] + (p[1] - c[1]) * bv[1]) for p in q), 6.0) + 0.6
                rect = [(c[0] + ax[0] * u + bv[0] * v, c[1] + ax[1] * u + bv[1] * v) for u, v in ((-hu, -hv), (hu, -hv), (hu, hv), (-hu, hv))]
                self.towers.append(rect)
                self.colliders.append(("poniatowski tower", rect))
                zone.append(_grow(q, 3.0))
            self.zones.append(("poniatowski", zone, []))

    def replaces(self, x, z):
        for _, zone, keep in self.zones:
            if any(point_in_poly(x, z, q) for q in zone) and not any(point_in_poly(x, z, q) for q in keep):
                return True
        return False


def _grow(q, by):
    """A polygon pushed out by `by` metres (good enough for convex-ish outlines)."""
    c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
    out = []
    for p in q:
        d = math.dist(p, c) or 1.0
        out.append((p[0] + (p[0] - c[0]) / d * by, p[1] + (p[1] - c[1]) / d * by))
    return out


class Solids:
    """Footprints with a base and a top: the OSM buildings the game draws, the LoD2 buildings
    (heights from lod2.bin) and the landmarks."""

    def __init__(self, m, marks):
        self.items = []   # (poly, base, top, label, bbox, key)
        d = m.d
        # Loop 3b: buildings cut under a deck (tools/bake_structures.py): an OpenStreetMap
        # building's `cut` (its new top; `cutd` 1 = left out; `pil` 1 = a viaduct's pillar,
        # cut or lengthened to the slab), a LoD2 building's by its
        # triangle run's centre (`lod2_cuts`: [x, z, top, left out]).
        self.lod2_cuts = {(round(c[0], 1), round(c[1], 1)): (c[2], c[3]) for c in d.get("lod2_cuts", [])}
        lod_json = os.path.join(m.dir, "lod2.json")
        keep = None
        if os.path.exists(lod_json) and os.path.exists(os.path.join(m.dir, "lod2.bin")):
            meta = json.load(open(lod_json))
            keep = set(meta["keep_osm"])
            self._lod2(m, meta["footprints"], marks)
        for i, b in enumerate(d["buildings"]):
            if keep is not None and i not in keep:
                continue
            q = pairs(b["p"])
            if len(q) < 3 or b.get("br") or b["h"] <= b["mh"] or b.get("cutd"):
                continue
            c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
            if marks.replaces(*c):
                continue
            ground = min(m.terrain(x, z) for x, z in q)
            base = ground + b["mh"] - (0.4 if b["mh"] < 0.5 else 0.0)
            top = b["cut"] if b.get("pil") else min(ground + b["h"], b.get("cut", 1e9))
            self._add(q, base, top, "building " + (b.get("name") or b.get("kind") or ""), ("osm", i))
        for key, q in marks.colliders:
            g = min(m.terrain(x, z) for x, z in q)
            self._add(q, g - 1.0, g + 30.0, "landmark " + key, ("landmark", key))
        self.grid = Grid(16.0)
        for k, it in enumerate(self.items):
            self.grid.add(k, *it[4])

    def _add(self, q, base, top, label, key=None):
        xs, zs = [p[0] for p in q], [p[1] for p in q]
        self.items.append((q, base, top, label, (min(xs), min(zs), max(xs), max(zs)), key))

    def _lod2(self, m, footprints, marks):
        raw = open(os.path.join(m.dir, "lod2.bin"), "rb").read()
        count = struct.unpack_from("<I", raw, 0)[0]
        f = array.array("f")
        f.frombytes(raw[4:4 + count * 14 * 4])
        if sys.byteorder != "little":
            f.byteswap()
        o_u2 = count * 12
        runs = []  # (x0, z0, x1, z1, ymin, ymax)
        t0 = 0
        while t0 < count:
            seed = f[o_u2 + t0 * 2]
            fx, fz = f[t0 * 3], f[t0 * 3 + 2]
            x0 = x1 = fx
            z0 = z1 = fz
            y0 = y1 = f[t0 * 3 + 1]
            t1 = t0
            while t1 < count and f[o_u2 + t1 * 2] == seed and math.hypot(f[t1 * 3] - fx, f[t1 * 3 + 2] - fz) < 300.0:
                for k in range(3):
                    x, y, z = f[(t1 + k) * 3], f[(t1 + k) * 3 + 1], f[(t1 + k) * 3 + 2]
                    x0, x1, z0, z1 = min(x0, x), max(x1, x), min(z0, z), max(z1, z)
                    y0, y1 = min(y0, y), max(y1, y)
                t1 += 3
            if not marks.replaces((x0 + x1) * 0.5, (z0 + z1) * 0.5):
                key = (round((x0 + x1) * 0.5, 1), round((z0 + z1) * 0.5, 1))
                cut = self.lod2_cuts.get(key)
                if cut is None or not cut[1]:
                    runs.append((x0, z0, x1, z1, y0, y1 if cut is None else min(y1, cut[0]), key))
            t0 = t1
        grid = Grid(32.0)
        for r in runs:
            grid.add(r, r[0], r[1], r[2], r[3])
        for fp in footprints:
            q = pairs(fp)
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            fb = (min(xs), min(zs), max(xs), max(zs))
            fa = max((fb[2] - fb[0]) * (fb[3] - fb[1]), 1e-3)
            best = None
            seen = set()
            for cell in {(math.floor(x / 32.0), math.floor(z / 32.0)) for x, z in q}:
                for r in grid.cells.get(cell, ()):
                    if id(r) in seen:
                        continue
                    seen.add(id(r))
                    ix = min(fb[2], r[2]) - max(fb[0], r[0])
                    iz = min(fb[3], r[3]) - max(fb[1], r[1])
                    if ix <= 0 or iz <= 0:
                        continue
                    inter = ix * iz
                    iou = inter / (fa + (r[2] - r[0]) * (r[3] - r[1]) - inter)
                    if best is None or iou > best[0]:
                        best = (iou, r)
            # The run that matches the footprint best (one building, several footprints:
            # each overlaps its own run's box more than a neighbour's).
            if best is not None and best[0] > 0.2:
                self._add(q, best[1][4], best[1][5], "LoD2 building", ("lod2", best[1][6]))

    def at(self, x, z):
        for k in self.grid.at(x, z):
            q, base, top, label, bb, _ = self.items[k]
            if bb[0] <= x <= bb[2] and bb[1] <= z <= bb[3] and point_in_poly(x, z, q):
                yield self.items[k]


# --- the rules ------------------------------------------------------------------------------

class Check:
    def __init__(self, m, osm_path, rules):
        self.m = m
        self.osm_path = osm_path
        self.rules = rules
        self.findings = []
        self.notes = {}
        d = m.d
        # The roads, with the tunnel roads (loop 3a, R4: `tunnels.roads`, each with its `tn`).
        self.roads = [r for r in d["roads"] + d.get("tunnels", {}).get("roads", []) if r["k"] in DRIVABLE]
        self._marks = None
        self._solids = None

    def add(self, rule, x, z, what, name="", value=0.0):
        self.findings.append({"rule": rule, "x": round(x, 1), "z": round(z, 1), "what": what, "name": name,
                              "value": round(value, 3)})

    @property
    def marks(self):
        if self._marks is None:
            self._marks = Landmarks(self.m.d)
        return self._marks

    @property
    def solids(self):
        if self._solids is None:
            self._solids = Solids(self.m, self.marks)
        return self._solids

    def run(self):
        for rule, _ in RULES:
            if rule in self.rules:
                t0 = time.time()
                getattr(self, "c" + rule[1:])()
                self.notes.setdefault(rule, {})["s"] = round(time.time() - t0, 2)

    @staticmethod
    def name(r):
        return r.get("name") or r["k"]

    def level(self, r):
        if r.get("tn") is not None:
            return f" tunnel {r['tn']}"
        return f" deck {r['dk']}" if r.get("dk") is not None else ""

    # C1: grade along a road's own surface.
    def c1(self):
        m = self.m
        for r in self.roads:
            ps = sample(pairs(r["p"]), 2.0)
            cm = cum_of(ps)
            hs = [m.surface(r, x, z) for x, z in ps]
            limit = GRADE_MAX_SERVICE if r["k"] == "service" else GRADE_MAX
            worst = None
            j = 0
            for k in range(len(ps)):
                j = max(j, k)
                while j < len(ps) - 1 and cm[j] - cm[k] < GRADE_RUN:
                    j += 1
                run = cm[j] - cm[k]
                if run < GRADE_RUN - 0.5:
                    continue
                g = abs(hs[j] - hs[k]) / run
                if g > limit and (worst is None or g > worst[0]):
                    worst = (g, k, j)
            if worst is not None:
                g, k, j = worst
                x, z = ps[k]
                self.add("C1", x, z, f"{self.name(r)} [{r['k']}{self.level(r)}] {g * 100:.0f} % over {cm[j] - cm[k]:.0f} m "
                         f"({hs[k]:.1f} -> {hs[j]:.1f} m; limit {limit * 100:.0f} %)", self.name(r), g)

    # C2: roads meeting at a vertex at different heights.
    def c2(self):
        m = self.m
        at = defaultdict(list)
        for r in self.roads:
            for x, z in pairs(r["p"]):
                at[(round(x * 2), round(z * 2))].append((r, m.surface(r, x, z)))
        for (kx, kz), lst in at.items():
            if len({id(r) for r, _ in lst}) < 2:
                continue
            hs = [h for _, h in lst]
            if max(hs) - min(hs) > JOINT_MAX:
                txt = ", ".join(f"{self.name(r)}{self.level(r)} {h:.2f}" for r, h in lst)
                self.add("C2", kx / 2, kz / 2, f"{max(hs) - min(hs):.2f} m apart: {txt}", self.name(lst[0][0]), max(hs) - min(hs))
        # Map review A (2026-10-29): a kerb or an edge line across the road where a road or tram
        # deck's end meets the ground (bake_roads bake_edges JOINT_*: it read as a stop line, and
        # the car felt the ground side's kerb). Per end: the kerb or edge-line segments within
        # JOINT_ALONG of it, inside its corridor + 2 m, running across it (> 50 degrees).
        ends = []
        for dp in m.decks.p:
            if dp["k"] not in ("road", "tram") or len(dp["pts"]) < 2:
                continue
            for e, f, h in ((dp["pts"][0], dp["pts"][1], dp["h"][0]), (dp["pts"][-1], dp["pts"][-2], dp["h"][-1])):
                ln = math.dist(e, f)
                if ln < 1e-6 or abs(h - m.terrain(*e)) > 0.5:
                    continue
                ends.append((e, ((f[0] - e[0]) / ln, (f[1] - e[1]) / ln), max(dp["l"], dp["r"]) + 2.0, dp["g"]))
        grid = Grid(16.0)
        for k, (e, u, half, g) in enumerate(ends):
            r = half + JOINT_ALONG
            grid.add(k, e[0] - r, e[1] - r, e[0] + r, e[1] + r)
        lines = [("kerb", kb["p"]) for kb in m.d.get("kerbs", [])]
        lines += [("edge line", mk["p"]) for mk in m.d.get("markings", []) if mk.get("k") == "edge"]
        run = defaultdict(float)
        for label, flat in lines:
            ps = pairs(flat)
            for a, b in zip(ps, ps[1:]):
                ln = math.dist(a, b)
                if ln < 0.3:
                    continue
                mx, mz = (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5
                for k in grid.at(mx, mz):
                    e, u, half, g = ends[k]
                    if abs((mx - e[0]) * u[0] + (mz - e[1]) * u[1]) > JOINT_ALONG or math.hypot(mx - e[0], mz - e[1]) > half:
                        continue
                    if abs((b[0] - a[0]) * u[0] + (b[1] - a[1]) * u[1]) / ln < math.cos(math.radians(50)):
                        run[(k, label)] += ln
                        break
        for (k, label), ln in sorted(run.items()):
            if ln >= JOINT_RUN:
                e, u, half, g = ends[k]
                self.add("C2", e[0], e[1], f"{ln:.1f} m of {label} across the road at deck {g}'s joint with the ground",
                         label, ln)

    # C3: what runs under a deck too close to its slab.
    def c3(self):
        m = self.m
        # Loop 3d-1: a service way (garage driveway, parking aisle; no traffic) needs a car's height.
        items = [(r, self.name(r), CLEAR_FOOT if r.get("k") == "service" else CLEAR_MAX) for r in self.roads]
        items += [(t, "tram", CLEAR_MAX) for t in m.d.get("trams", [])]
        items += [(t, "rail", CLEAR_MAX) for t in m.d.get("rails", [])]
        items += [(p, "footway" if p["k"] == "foot" else p["k"], CLEAR_FOOT) for p in m.d.get("paths", [])
                  if p["k"] in ("foot", "cycle")]
        samples = 0
        for it, label, limit in items:
            own = it.get("dk")
            for x, z in sample(pairs(it["p"]), 2.0):
                decks = m.decks.at(x, z)
                if not decks:
                    continue
                hg = m.surface(it, x, z)
                for hd, g, i in decks:
                    if own is not None and g == own:
                        continue
                    c = hd - hg
                    if CLEAR_MIN < c < limit:
                        samples += 1
                        self.add("C3", x, z, f"{label}{self.level(it)} at {hg:.1f} m under deck {g} ({m.decks.p[i]['k']}) "
                                 f"at {hd:.1f} m: clearance {c:.1f} m (needs {limit:.1f})", label, c)
                        break
        self.notes.setdefault("C3", {})["unit"] = "2 m samples"

    # C4: piers (map_builder _build_bridge_structures) standing on what runs under.
    def c4(self):
        m = self.m
        under = Grid(16.0)

        def put(it, half, label):
            ps = pairs(it["p"])
            for a, b in zip(ps, ps[1:]):
                under.add((a, b, half, label, it), min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                          max(a[0], b[0]) + half, max(a[1], b[1]) + half)
        for r in self.roads:
            put(r, r["w"] * 0.5, self.name(r))
        for t in m.d.get("trams", []):
            put(t, TRAM_HALF, "tram")
        for t in m.d.get("rails", []):
            put(t, RAIL_HALF, "rail")
        # Loop 3b (R5): the piers, portal legs and cap beams the bake placed (`decks.piers`,
        # tools/bake_structures.py), as the game builds and collides them; each footprint
        # against what runs under it (anything not on the pier's own deck and lower than
        # its top by a metre).
        total = legs = 0
        for p in m.d.get("decks", {}).get("piers", []):
            if p["k"] == "cap":
                continue
            total += 1
            legs += p["k"] == "leg"
            x, z = p["c"]
            ux, uz = p["d"]
            across, along = p["s"][0] * 0.5, p["s"][1] * 0.5
            dy = p["y"][1] + 1.3
            rect = [(x + ux * u - uz * v, z + uz * u + ux * v) for u, v in
                    ((-along, -across), (along, -across), (along, across), (-along, across))]
            own = self.pier_deck(x, z, dy)
            seen = set()
            for cell in {(math.floor(px / 16), math.floor(pz / 16)) for px, pz in rect}:
                for sa, sb, half, label, it in under.cells.get(cell, ()):
                    if id(it) in seen or (own is not None and it.get("dk") == own):
                        continue
                    if it.get("dk") is not None and m.surface(it, x, z) > dy - 1.0:
                        continue
                    dist = min(seg_seg_dist(rect[q], rect[(q + 1) % 4], sa, sb) for q in range(4))
                    if point_in_poly(sa[0], sa[1], rect):
                        dist = 0.0
                    if dist < half + PIER_PAD:
                        seen.add(id(it))
                        self.add("C4", x, z, f"{p['k']} of deck {own} {dist - half:+.1f} m from the edge of {label}",
                                 label, dist - half)
                        break
                if seen:
                    break
        self.notes.setdefault("C4", {})["piers"] = total
        self.notes["C4"]["portal legs"] = legs

    def pier_deck(self, x, z, top):
        """The deck group a pier at (x, z) carries: the one over it at `top` (or nearest)."""
        best = None
        for hd, g, i in self.m.decks.at(x, z) + [hit for dx, dz in ((4, 0), (-4, 0), (0, 4), (0, -4))
                                                  for hit in self.m.decks.at(x + dx, z + dz)]:
            if best is None or abs(hd - top) < best[0]:
                best = (abs(hd - top), g)
        return best[1] if best is not None and best[0] < 1.0 else None

    # C5: roads and lanes inside solid footprints.
    def c5(self):
        m = self.m
        sol = self.solids
        runs = 0

        def walk(pts, height, label, kind):
            nonlocal runs
            run, first = 0, None
            for x, z, y in (pts if height is None else ((x, z, height(x, z)) for x, z in sample(pts, 2.0))):
                hit = None
                if m.terrain(x, z) - y >= TUNNEL_MOUTH and m.tunnels.at(x, z):
                    # Loop 3e: under the ground in a tunnel, what stands on the ground over it
                    # (the Copernicus Science Centre over the Wisłostrada's tubes) is not in the
                    # way; its walls reaching down into the tube are check_drive's (lod2_open).
                    run, first = 0, None
                    continue
                for q, base, top, lab, _, _ in sol.at(x, z):
                    if base < y + SOLID_ABOVE and top > y:
                        hit = lab
                        break
                if hit:
                    run += 1
                    first = first or (x, z, hit)
                    if run * 2.0 >= SOLID_RUN and run * 2.0 < SOLID_RUN + 2.0:
                        runs += 1
                        self.add("C5", first[0], first[1], f"{kind} {label} runs inside {first[2]}", label, run * 2.0)
                else:
                    run, first = 0, None
        for r in self.roads:
            walk(pairs(r["p"]), lambda x, z, r=r: m.surface(r, x, z), f"{self.name(r)} [{r['k']}]", "road")
        for e, lane, ps in self.lanes():
            walk(ps, None, f"{e.get('name') or e['k']} lane {lane}", "lane")

    def lanes(self):
        """(edge, lane index, [(x, z, lane height)] every 2 m) for every lane, cached."""
        if getattr(self, "_lanes", None) is None:
            self._lanes = []
            for e in self.m.d["graph"]["edges"]:
                pts = pairs(e["p"])
                cm = cum_of(pts)
                hf = self.lane_height_fn(e)
                for k in range(e["n"]):
                    q = offset_line(pts, e["o"] + e["lw"] * k)
                    ps = []
                    for i in range(len(pts) - 1):
                        seg = cm[i + 1] - cm[i]
                        n = max(1, int(seg / 2.0))
                        for j in range(n):
                            t = j / n
                            ps.append((q[i][0] + (q[i + 1][0] - q[i][0]) * t, q[i][1] + (q[i + 1][1] - q[i][1]) * t,
                                       hf(cm[i] + seg * t)))
                    ps.append((q[-1][0], q[-1][1], hf(cm[-1])))
                    self._lanes.append((e, k, ps))
        return self._lanes

    def lane_height_fn(self, e):
        """lane_graph.gd height(e, s): knots every 8 m on the centreline, lerped."""
        m = self.m
        pts = pairs(e["p"])
        cm = cum_of(pts)
        length = cm[-1]
        n = max(2, math.ceil(length / HEIGHT_STEP - 0.001) + 1)
        hs = []
        for k in range(n):
            s = min(k * HEIGHT_STEP, length)
            x, z = _at(pts, cm, s)
            if e.get("tn") is not None:
                hs.append(m.tunnel_height(e["tn"], x, z))
            elif e.get("dk") is not None:
                hs.append(m.deck_height(e["dk"], x, z))
            elif e.get("br") == 1:
                hs.append(m.ground_height(x, z))
            else:
                hs.append(m.terrain(x, z))

        def height(s):
            k = min(max(int(s / HEIGHT_STEP), 0), len(hs) - 2)
            seg = min(HEIGHT_STEP, length - k * HEIGHT_STEP)
            t = min(max((s - k * HEIGHT_STEP) / seg, 0.0), 1.0) if seg > 0.001 else 0.0
            return hs[k] + (hs[k + 1] - hs[k]) * t
        height.length = length
        return height

    # C6: deck pieces ending in the air.
    def c6(self):
        m = self.m
        steps = Grid(16.0)
        for st in m.d.get("steps", []):
            for x, z in pairs(st["p"]):
                steps.add((x, z), x, z, x, z)
        rim = 0
        for i, d in enumerate(m.decks.p):
            for end in (0, -1):
                x, z = d["pts"][end]
                air = d["h"][end] - m.terrain(x, z)
                if air <= AIR_MAX:
                    continue
                cont = False
                for j, k in m.decks.any.get((math.floor(x / DECK_CELL), math.floor(z / DECK_CELL)), ()):
                    if j == i:
                        continue
                    o = m.decks.p[j]
                    for q in (k, k + 1):
                        if math.dist(o["pts"][q], (x, z)) < 1.5 and abs(o["h"][q] - d["h"][end]) < 0.5:
                            cont = True
                if not cont:
                    # On another deck of its structure at its height (a footway ending beside the road deck).
                    for hd, g, j in m.decks.at(x, z) + [hit for dx, dz in ((3, 0), (-3, 0), (0, 3), (0, -3))
                                                          for hit in m.decks.at(x + dx, z + dz)]:
                        if j != i and g == d["g"] and abs(hd - d["h"][end]) < 0.5:
                            cont = True
                            break
                if not cont and d["k"] == "path":
                    cont = any(math.dist(p, (x, z)) < 4.0 for cell in _cells3(x, z, 16.0) for p in steps.cells.get(cell, ()))
                if cont:
                    continue
                if m.on_rim(x, z):
                    rim += 1
                    continue
                self.add("C6", x, z, f"deck {d['g']} {d['k']} piece ends {air:.1f} m above the terrain, nothing continues", d["k"], air)
        self.notes.setdefault("C6", {})["rim"] = rim

    # C7: drivable tunnels and cuttings in the raw OSM that the map file lacks.
    def c7(self):
        m = self.m
        if not os.path.exists(self.osm_path):
            self.notes["C7"] = {"skipped": f"no {os.path.relpath(self.osm_path, ROOT)}"}
            return
        els = json.load(open(self.osm_path, encoding="utf-8"))["elements"]
        nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
        have = Grid(16.0)
        doors = [(g[0], g[1]) for g in m.d.get("garages", [])]
        for r in self.roads:
            ps = pairs(r["p"])
            for a, b in zip(ps, ps[1:]):
                have.add((a, b), min(a[0], b[0]) - 1, min(a[1], b[1]) - 1, max(a[0], b[0]) + 1, max(a[1], b[1]) + 1)
        rect = m.shape
        ruled_out = defaultdict(int)
        for w in els:
            if w["type"] != "way":
                continue
            t = w.get("tags", {})
            hw = t.get("highway")
            if hw not in DRIVABLE or t.get("area") == "yes":
                continue
            layer = bake_osm.num(t.get("layer"))
            tunnel = t.get("tunnel")
            cutting = layer is not None and layer < 0 and tunnel in (None, "no")
            if not (tunnel == "yes" or cutting or tunnel == "building_passage"):
                continue
            ids = [i for i in w.get("nodes", []) if i in nodes]
            if len(ids) < 2 or not any(bake_osm.in_bbox(*nodes[i]) for i in ids):
                continue
            if tunnel == "yes" and hw == "service":
                ruled_out["service tunnels (garage interiors; R9)"] += 1
                continue
            if tunnel == "building_passage" or (tunnel == "yes" and bake_osm.is_passage(
                    [bake_osm.project(*nodes[i]) for i in ids])):
                ruled_out["building passages (gates through a building, never drawn)"] += 1
                continue
            pts = [bake_osm.project(*nodes[i]) for i in ids]
            covered = total = 0
            first = None
            for a, b in zip(pts, pts[1:]):
                for seg in bake_osm.clip_segments(a, b, rect):
                    for x, z in sample(list(seg), 2.0):
                        total += 1
                        if any(seg_dist2(x, z, sa, sb) < 1.0 for sa, sb in have.at(x, z)):
                            covered += 1
                        elif first is None:
                            first = (x, z)
            if total and covered < 0.8 * total and any(seg_dist2(dr[0], dr[1], a, b) < 16.0 for dr in doors
                                                         for a, b in zip(pts, pts[1:])):
                ruled_out["ended at a garage door (R9)"] += 1
                continue
            if total and covered < 0.8 * total:
                kind = "tunnel" if tunnel == "yes" else "cutting (layer<0)"
                self.add("C7", first[0], first[1], f"OSM way {w['id']} {hw} {t.get('name', '')} {kind}: "
                         f"{100 * covered // total} % of it in the map", t.get("name", "") or hw, total * 2.0)
        self.notes["C7"] = {"ruled out by rule": dict(ruled_out)}

    # C8: lanes stepping up or down, and edges meeting at different heights.
    def c8(self):
        g = self.m.d["graph"]
        nodes = g["nodes"]
        ends = defaultdict(list)
        steps = 0
        for e in g["edges"]:
            hf = self.lane_height_fn(e)
            length = hf.length
            worst = None
            s = 0.0
            while s + LANE_STEP <= length + 1e-6:
                dh = abs(hf(s + LANE_STEP) - hf(s))
                if dh > LANE_JUMP and (worst is None or dh > worst[0]):
                    worst = (dh, s)
                s += 1.0
            if worst is not None:
                steps += 1
                x, z = _at(pairs(e["p"]), cum_of(pairs(e["p"])), worst[1])
                self.add("C8", x, z, f"lane edge {e.get('name') or e['k']}{self.level(e)} steps {worst[0]:.2f} m within 4 m "
                         f"at s={worst[1]:.0f}/{length:.0f}", e.get("name") or e["k"], worst[0])
            ends[e["b"]].append((hf(length), e))
            ends[e["a"]].append((hf(0.0), e))
        nodes_bad = 0
        for n, lst in ends.items():
            hs = [h for h, _ in lst]
            if max(hs) - min(hs) > LANE_NODE:
                nodes_bad += 1
                self.add("C8", nodes[n * 2], nodes[n * 2 + 1], f"lane node {n}: edges meet at {min(hs):.2f}..{max(hs):.2f} m",
                         lst[0][1].get("name") or lst[0][1]["k"], max(hs) - min(hs))
        self.notes["C8"] = {"edges": steps, "nodes": nodes_bad}

    # C9: buildings poking up through a deck.
    def c9(self):
        m = self.m
        sol = self.solids
        hit = set()
        for k, (q, base, top, label, bb, _) in enumerate(sol.items):
            if label.startswith("landmark"):
                continue
            pts = list(q)
            for x in _frange(bb[0], bb[2], 2.0):
                for z in _frange(bb[1], bb[3], 2.0):
                    if point_in_poly(x, z, q):
                        pts.append((x, z))
            for x, z in pts:
                for hd, g, i in m.decks.at(x, z):
                    bottom = hd - SLAB
                    if top > bottom + 0.05 and base < bottom:
                        hit.add(k)
                        self.add("C9", x, z, f"{label} (top {top:.1f} m) through deck {g} ({m.decks.p[i]['k']}) "
                                 f"slab bottom {bottom:.1f} m", label, top - bottom)
                        break
                if k in hit:
                    break
        # Map review A (2026-10-29): a scanned tree's crown (map_builder _build_trees: its base
        # and top over the ground, the radius and the top scaled by `trees3d_crown`) reaching into
        # a deck beside it, between the slab's bottom and the head room over the deck
        # (bake_structures trim_crowns shrinks them); a crown over a deck higher than that stays.
        real, crowns = m.d.get("trees3d", []), m.d.get("trees3d_crown", [])
        for t, i in enumerate(range(0, len(real) - 5, 6)):
            x, z, height, radius, crown_base = real[i:i + 5]
            f = crowns[t] / 100.0 if t < len(crowns) else 1.0
            base = min(crown_base, height - 1.5)
            top = base + (height - base) * f
            ground = m.terrain(x, z) - 0.2
            rr = radius * f * 0.8
            found = None
            for dx, dz in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7)):
                for hd, g, pi in m.decks.at(x + dx * rr, z + dz * rr):
                    kind = m.decks.p[pi]["k"]
                    if hd > ground + 0.6 and ground + base < hd + TREE_HEAD.get(kind, 3.5) and ground + top > hd - SLAB + 0.05:
                        found = (g, kind, ground + top - (hd - SLAB))
                        break
                if found:
                    break
            if found:
                self.add("C9", x, z, f"scanned tree (crown {base:.1f}-{top:.1f} m over the ground, scale {f:.2f}) into deck "
                         f"{found[0]} ({found[1]}) by {found[2]:.1f} m", "tree", found[2])

    # C10: landmark colliders crowding a lane.
    def c10(self):
        cols = self.marks.colliders
        grid = Grid(16.0)
        for key, q in cols:
            for a, b in zip(q, q[1:] + q[:1]):
                grid.add((a, b, key), min(a[0], b[0]) - 3, min(a[1], b[1]) - 3, max(a[0], b[0]) + 3, max(a[1], b[1]) + 3)
        reach = LANE_HALF + LANDMARK_PAD
        for e, lane, ps in self.lanes():
            if e.get("tn") is not None:
                continue  # under the ground
            worst = None
            for x, z, _ in ps:
                for a, b, key in grid.at(x, z):
                    dd = math.sqrt(seg_dist2(x, z, a, b))
                    if dd < reach and (worst is None or dd < worst[0]):
                        worst = (dd, x, z, key)
            if worst:
                self.add("C10", worst[1], worst[2], f"{e.get('name') or e['k']} lane {lane}: {worst[3]} collider "
                         f"{worst[0] - LANE_HALF:+.1f} m from the lane corridor", worst[3], worst[0])


    # C11 (map round 2, 2026-10-29): what is drawn on the ground (roads, carriageway areas, tram and
    # rail beds) at `terrain()` must not lie under the drawn ground mesh (`drawn()`): loop 3b's
    # aprons held the ground under a structure's end below the 10 m grid, and the road there
    # vanished under a beige wedge of bare ground (the viaduct's west end, 0.65 m).
    def c11(self):
        m = self.m
        samples = 0

        def probe(x, z, label, name):
            nonlocal samples
            samples += 1
            d = m.drawn(x, z) - m.terrain(x, z)
            if d > UNDER_MAX:
                self.add("C11", x, z, f"{label} {d:.2f} m under the drawn ground", name, d)
                return True
            return False
        for r in m.d["roads"]:
            if r.get("dk") is not None or r.get("tn") is not None:
                continue
            ps = sample(pairs(r["p"]), 2.0)
            half = max(r["w"] * 0.5 - 0.3, 0.0)
            for k, (x, z) in enumerate(ps):
                a, b = ps[max(k - 1, 0)], ps[min(k + 1, len(ps) - 1)]
                ln = math.dist(a, b) or 1.0
                nx, nz = -(b[1] - a[1]) / ln, (b[0] - a[0]) / ln
                for o in (-half, 0.0, half):
                    if probe(x + nx * o, z + nz * o, f"road {self.name(r)}", self.name(r)):
                        break
        for c in m.d.get("carriage", []):
            if c.get("dk") is not None:
                continue
            q = pairs(c["p"])
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            for x in _frange(min(xs), max(xs), 2.0):
                for z in _frange(min(zs), max(zs), 2.0):
                    if point_in_poly(x, z, q):
                        probe(x, z, f"carriageway area ({c.get('k')})", c.get("k", ""))
        for key, label in (("trams", "tram bed"), ("rails", "rail bed")):
            for t in m.d.get(key, []):
                if t.get("dk") is not None:
                    continue
                for x, z in sample(pairs(t["p"]), 2.0):
                    probe(x, z, label, label)
        self.notes["C11"] = {"samples": samples}


def _cells3(x, z, c):
    i, j = math.floor(x / c), math.floor(z / c)
    return [(i + dx, j + dz) for dx in (-1, 0, 1) for dz in (-1, 0, 1)]


def _frange(a, b, step):
    v = a + step * 0.5
    while v < b:
        yield v
        v += step


def _at(pts, cm, s):
    for k in range(len(pts) - 1):
        if s <= cm[k + 1] or k == len(pts) - 2:
            seg = cm[k + 1] - cm[k]
            t = 0.0 if seg <= 0 else min(max((s - cm[k]) / seg, 0.0), 1.0)
            return (pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t)
    return pts[-1]


def _project_s(pts, x, z):
    best, bs, run = 1e18, 0.0, 0.0
    for a, b in zip(pts, pts[1:]):
        abx, abz = b[0] - a[0], b[1] - a[1]
        l2 = abx * abx + abz * abz
        ln = math.sqrt(l2)
        t = 0.0 if l2 < 1e-12 else min(max(((x - a[0]) * abx + (z - a[1]) * abz) / l2, 0.0), 1.0)
        d2 = (x - a[0] - abx * t) ** 2 + (z - a[1] - abz * t) ** 2
        if d2 < best:
            best, bs = d2, run + t * ln
        run += ln
    return bs


# --- places, the allowlist, the report ---------------------------------------------------

def places(findings, reach):
    """Findings of one rule grouped by distance: [{x, z, n, worst}]."""
    out = []
    for f in sorted(findings, key=lambda f: -abs(f["value"])):
        for p in out:
            if math.hypot(p["x"] - f["x"], p["z"] - f["z"]) < reach:
                p["n"] += 1
                break
        else:
            out.append({"x": f["x"], "z": f["z"], "n": 1, "worst": f})
    return out


REACH = {"C1": 30.0, "C2": 20.0, "C3": 40.0, "C4": 20.0, "C5": 25.0, "C6": 10.0, "C7": 50.0, "C8": 30.0, "C9": 30.0, "C10": 20.0, "C11": 20.0}


def load_allow(path):
    if not os.path.exists(path):
        return []
    doc = json.load(open(path, encoding="utf-8"))
    out = []
    for k, a in enumerate(doc.get("allow", [])):
        for key in ("rule", "at", "r", "reason", "source"):
            if key not in a or a[key] in ("", None):
                raise ValueError(f"{os.path.relpath(path, ROOT)}: entry {k} has no '{key}' (every entry needs rule, at, r, reason, source)")
        out.append(a)
    return out


def allowed(f, allow):
    for a in allow:
        if a["rule"] != f["rule"]:
            continue
        if math.hypot(f["x"] - a["at"][0], f["z"] - a["at"][1]) > a["r"]:
            continue
        if a.get("name") and a["name"].lower() not in (f["name"] + " " + f["what"]).lower():
            continue
        return a
    return None


VIEW = "--at={x:.0f},{z:.0f}"


def main(argv):
    opts = {"map": os.path.join(ROOT, "game", "map"), "osm": bake_osm.OSM_SRC,
            "json": os.path.join(ROOT, "shots", "check_roads.json"), "png": os.path.join(ROOT, "shots", "check_roads.png"),
            "allow": os.path.join(TOOLS, "check_roads_allow.json"), "rules": ",".join(r for r, _ in RULES),
            "later": ""}
    flags = set()
    for a in argv:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            if k not in opts:
                print(f"unknown option {a}"); return 2
            opts[k] = v
        elif a in ("--no-png", "--all", "--quiet"):
            flags.add(a[2:])
        else:
            print(__doc__.split("\n\n")[1]); return 2
    rules = [r.strip().upper() for r in opts["rules"].split(",") if r.strip()]
    later = {r.strip().upper() for r in opts["later"].split(",") if r.strip()}
    t0 = time.time()
    try:
        m = Map(opts["map"])
        allow = load_allow(opts["allow"])
    except (OSError, ValueError, KeyError) as e:
        print(f"check_roads: ERROR {e}"); return 2
    chk = Check(m, opts["osm"], rules)
    chk.run()
    by_rule = defaultdict(list)
    used = set()
    for f in chk.findings:
        a = allowed(f, allow)
        f["allowed"] = a is not None
        if a is not None:
            f["reason"] = a["reason"]
            used.add(id(a))
        by_rule[f["rule"]].append(f)
    table = []
    bad_total = 0
    bad_later = 0
    for rule, label in RULES:
        if rule not in rules:
            continue
        fs = by_rule.get(rule, [])
        bad = [f for f in fs if not f["allowed"]]
        if rule in later:
            bad_later += len(bad)
        else:
            bad_total += len(bad)
        pl = places(fs, REACH[rule])
        note = chk.notes.get(rule, {})
        extra = ", ".join(f"{k} {v}" for k, v in note.items() if k not in ("s",))
        table.append((rule, label, len(fs), len(fs) - len(bad), len(pl), extra, note.get("s", 0)))
        if not ("quiet" in flags) and fs:
            print(f"{rule} {label}: {len(fs)} findings ({len(fs) - len(bad)} allowed) in {len(pl)} places")
            show = pl if "all" in flags else pl[:12]
            for p in show:
                w = p["worst"]
                tag = "allowed" if w["allowed"] else "FINDING"
                print(f"  {tag} ({p['x']:.0f},{p['z']:.0f}) x{p['n']}: {w['what']}  [{VIEW.format(**p)}]")
            if len(pl) > len(show):
                print(f"  ... {len(pl) - len(show)} more places (--all)")
    stale = [a for a in allow if id(a) not in used and a["rule"] in rules]
    for a in stale:
        print(f"note: allowlist entry no longer matches anything: {a['rule']} at {a['at']} ({a.get('name', '')})")
    print("")
    print("rule  what                   findings  allowed  places  detail")
    for rule, label, n, ok, npl, extra, secs in table:
        print(f"{rule:<5} {label:<22} {n:>8}  {ok:>7}  {npl:>6}  {extra}")
    secs = time.time() - t0
    report = {"map": os.path.relpath(opts["map"], ROOT), "seconds": round(secs, 1),
              "counts": {rule: {"findings": n, "allowed": ok, "places": npl, "detail": chk.notes.get(rule, {})}
                         for rule, label, n, ok, npl, extra, s in table},
              "findings": chk.findings}
    os.makedirs(os.path.dirname(opts["json"]), exist_ok=True)
    with open(opts["json"], "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=1)
    if "no-png" not in flags:
        try:
            draw_png(m, chk.findings, opts["png"], rules)
        except OSError as e:
            print(f"note: no image ({e})")
    ok = bad_total == 0
    status = "FAIL" if not ok else ("LATER" if bad_later else "OK")
    later_txt = f", {bad_later} in rules left for later ({','.join(sorted(later))})" if later else ""
    print(f"check_roads: {status} ({bad_total} findings not allowed{later_txt}, "
          f"{sum(t[3] for t in table)} allowed; {secs:.1f} s; report {os.path.relpath(opts['json'], ROOT)})")
    print("check_roads counts: " + " ".join(f"{t[0]} {t[2] - t[3]}/{t[2]}" for t in table))
    return 1 if not ok else (3 if bad_later else 0)


# --- the findings image (standard library: BMP in, PNG out) -----------------------------

FONT = {  # 3x5 pixel glyphs, rows top to bottom, bits left to right
    "0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
    "4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010",
    "8": "111101111101111", "9": "111101111001111", "C": "111100100100111", " ": "000000000000000",
    "A": "010101111101101", "D": "110101101101110", "E": "111100111100111", "G": "111100101101111",
    "I": "111010010010111", "J": "001001001101111", "K": "101101110101101", "L": "100100100100111",
    "N": "110101101101101", "O": "111101101101111", "P": "111101111100100", "R": "110101110101101",
    "S": "111100111001111", "T": "111010010010010", "U": "101101101101111", "H": "101101111101101",
    "W": "101101101111101", "B": "110101110101110", "M": "101111111101101", "F": "111100111100100",
    "Y": "101101010010010", ".": "000000000000010", "-": "000000111000000", "%": "101001010100101",
}


def draw_png(m, findings, path, rules):
    bmp = bake_osm.ORTHO
    raw = open(bmp, "rb").read()
    off = struct.unpack_from("<I", raw, 10)[0]
    w, h = struct.unpack_from("<ii", raw, 18)
    bpp = struct.unpack_from("<H", raw, 28)[0]
    if bpp != 24:
        raise OSError(f"ortho.bmp is {bpp}-bit, expected 24")
    stride = (w * 3 + 3) & ~3
    k = 2
    ow, oh = w // k, abs(h) // k
    dark = bytes(int(v * 0.55) for v in range(256))
    img = bytearray(ow * oh * 3)
    for y in range(oh):
        sy = y * k if h < 0 else abs(h) - 1 - y * k
        row = raw[off + sy * stride: off + sy * stride + ow * k * 3]
        line = bytearray(ow * 3)
        line[0::3] = row[2::3 * k]
        line[1::3] = row[1::3 * k]
        line[2::3] = row[0::3 * k]
        img[y * ow * 3:(y + 1) * ow * 3] = line.translate(dark)
    s, wl, n, e = bake_osm.ortho_box()
    x0, z0 = bake_osm.project(n, wl)
    x1, z1 = bake_osm.project(s, e)

    def px(x, z):
        return int((x - x0) / (x1 - x0) * ow), int((z - z0) / (z1 - z0) * oh)

    def put(x, y, c):
        if 0 <= x < ow and 0 <= y < oh:
            i = (y * ow + x) * 3
            img[i:i + 3] = bytes(c)

    def ring(cx, cy, r, c, width=2):
        for yy in range(-r - width, r + width + 1):
            for xx in range(-r - width, r + width + 1):
                d = math.hypot(xx, yy)
                if r - width <= d <= r:
                    put(cx + xx, cy + yy, c)

    def text(x, y, s_, c, scale=2):
        for ch in s_.upper():
            g = FONT.get(ch, FONT[" "])
            for row in range(5):
                for col in range(3):
                    if g[row * 3 + col] == "1":
                        for a in range(scale):
                            for b in range(scale):
                                put(x + col * scale + a, y + row * scale + b, c)
            x += 4 * scale
    for d in m.decks.p:
        for a, b in zip(d["pts"], d["pts"][1:]):
            pa, pb = px(*a), px(*b)
            steps_ = max(abs(pb[0] - pa[0]), abs(pb[1] - pa[1]), 1)
            for t in range(steps_ + 1):
                put(pa[0] + (pb[0] - pa[0]) * t // steps_, pa[1] + (pb[1] - pa[1]) * t // steps_, (170, 170, 170))
    for rule, _ in RULES:
        if rule not in rules:
            continue
        for p in places([f for f in findings if f["rule"] == rule], REACH[rule]):
            c = COLOURS[rule] if not p["worst"]["allowed"] else tuple(v // 2 + 60 for v in COLOURS[rule])
            cx, cy = px(p["x"], p["z"])
            ring(cx, cy, 6 + min(p["n"], 30) // 3, c)
            if not p["worst"]["allowed"]:
                text(cx + 10, cy - 5, rule, c)
    y = 8
    for rule, label in RULES:
        if rule in rules:
            n = sum(1 for f in findings if f["rule"] == rule)
            bad = sum(1 for f in findings if f["rule"] == rule and not f["allowed"])
            text(8, y, f"{rule} {label.upper()} {bad} OF {n}", COLOURS[rule])
            y += 14
    text(8, y + 4, "DIM RING ALLOWED", (200, 200, 200))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    rows = b"".join(b"\x00" + bytes(img[y * ow * 3:(y + 1) * ow * 3]) for y in range(oh))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", ow, oh, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
