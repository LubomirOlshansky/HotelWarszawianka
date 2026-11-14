"""The type, class and height of every wall, fence and hedge, decided once in the bake (city
objects plan step 5, docs/design/city-objects-plan.md 3.2 and 3.4; walls doc
docs/design/walls-true-to-life.md sections 4 and 5, phases W0/W1; build plan
docs/design/drivable-city-build.md items 3 "bake" and 8 "walls with no height").

Every `lines` item of kind fence, wall or hedge gets:
    ty   the type id (walls doc 4: rail_tram, bars_pier, mesh_panel, wall_precast ...; TYPES below)
    tc   how sure: tag (OpenStreetMap's own tags, a placed style, a street pass's verdict),
         structure (what it belongs to: a tram bed, a stair, a deck, a railway, water, a main road),
         context (the land beside it: a school, a church, a park, a yard; and its shape) or default
    sc   the solidity class answer as data (H hard, S smash, R ride, G ghost; drivable-city.md).
         The game does not read it yet (step 7 does)
    hz   only where a fence or hedge must stay hard, or a wall was made hard: drop, railway,
         water or deck (build plan item 3)
    hs   the height by setting where OpenStreetMap maps none (`h` stays OSM's own and is what
         city_barriers.gd draws today; `hs` is a new key so the game is unchanged until a later
         step reads it: walls doc 4 "Heights by setting", build plan item 8)
and the map a stamp `object_types`: {"v": VERSION, "osm": barrier ways matched, "ctx": context
outlines used}. The game reads none of these keys (only city_barriers.gd reads `lines`, and only
k, p, h, m, ft, st): what is drawn and what collides does not change.

    python3 -I tools/object_types.py apply [MAP_DIR] [--osm=FILE] [--out=FILE] [--rows=FILE]
        types the map's lines (MAP_DIR/centrum.json, in place unless --out); --osm reads an
        OpenStreetMap JSON (the Overpass `out geom` of `fetch`, or the raw demo export) for the
        full barrier tags and the context outlines; --rows writes one row per line (its rule,
        evidence and first point) for the plot and the 20-sample check. Idempotent.
    python3 -I tools/object_types.py fetch [--out=data/raw/osm/object_context.json]
        the context outlines and the barrier ways with all their tags from the public Overpass
        API for the map's box (ODbL; gitignored data/raw). Not needed on the Mac: bake_osm.py
        passes its raw export.
    python3 -I tools/object_types.py sample ROWS.json RULE [--n=20] [--seed=5] [--skip=N]
        the 20-sample check's draw for one rule (tools/overlay_object_types.py sheet builds the
        contact sheet from it)
    python3 -I tools/object_types.py --check [MAP_DIR]
        exit 1 unless every barrier line carries ty, tc and sc (tools/check_map_data.py counts them)
    python3 -I tools/object_types.py --selftest
        the rules on synthetic lines, the OSM reader in both formats, and the hand lists below
        against city_barriers.gd (verify step `objecttypes`)

bake_osm.py runs `apply` last, on the finished lines (after object_fixes, tram_stops and the
content POIs), with its raw OpenStreetMap elements. Re-run tools/bake_sectors.py and bake_city.gd
after it, and tools/bake_street_details.py and tools/bake_park_details.py (their stamps hash `lines`).
"""
import collections
import json
import math
import os
import random
import re
import subprocess
import sys
import time

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
MAP_DIR = os.path.join(ROOT, "game", "map")
CTX_FILE = os.path.join(ROOT, "data", "raw", "osm", "object_context.json")
VERSION = 1
KEY = "object_types"
KINDS = ("fence", "wall", "hedge")
LON0, LAT0 = 21.0240, 52.2340
M_PER_DEG_LAT = 110574.0
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(LAT0))
# The map's whole box with its north extension (bake_osm.BBOX and BBOX_NORTH), south, west, north, east.
BOX = (52.2183, 20.9780, 52.2591, 21.0560)
OVERPASS = "https://overpass-api.de/api/interpreter"
UA = "AroundWarsaw-map-fetch/1.0 (open-source game)"

# The types (walls doc 4): family (light breaks, heavy stops, low is ridden over), the class that
# family answers, and the height a line of the type stands where nothing else says (m).
TYPES = {
    # 4.1 light (S)
    "rail_street": ("light", 1.1), "rail_tram": ("light", 1.15), "bars_black": ("light", 1.8),
    "bars_pier": ("light", 2.2), "mesh_panel": ("light", 1.6), "chain_link": ("light", 1.5),
    "ball_net": ("light", 5.0), "low_lawn": ("light", 0.6), "wood": ("light", 1.5),
    "hoarding": ("light", 2.0), "green_fence": ("light", 1.6), "hedge_low": ("light", 0.8),
    "hedge_tall": ("light", 1.8), "chain_posts": ("light", 0.7), "fence_plain": ("light", 1.4),
    # 4.1 low_wall: S from 0.6 m, R under it (by its height)
    "low_wall": ("low", 0.5), "basin_rim": ("low", 0.45), "island_edge": ("low", 0.2),
    # 4.2 heavy (H)
    "wall_brick": ("heavy", 2.4), "wall_plaster": ("heavy", 1.6), "wall_precast": ("heavy", 2.4),
    "wall_stone": ("heavy", 2.0), "noise_screen": ("heavy", 4.0), "gabion": ("heavy", 1.6),
    "glass_screen": ("heavy", 2.0), "guard_rail": ("heavy", 0.75), "parapet_concrete": ("heavy", 1.1),
    "deck_railing": ("heavy", 1.1), "rail_waterfront": ("heavy", 1.1), "balustrade": ("heavy", 1.0),
    "balustrade_rail": ("heavy", 1.0), "balustrade_white": ("heavy", 1.05),
    # not drawn from the line: a landmark site builds it, or nothing stands there
    "site": ("ghost", 0.0), "removed": ("ghost", 0.0),
}
FAMILY_CLASS = {"light": "S", "heavy": "H", "low": "R", "ghost": "G"}

# Walls with no mapped height, by setting (walls doc 4 "Heights by setting", build plan item 8).
WALL_H = {"park": 0.5, "plaza": 0.5, "ring": 0.45, "housing": 1.2, "church": 2.0, "school": 2.0,
          "institution": 2.0, "embassy": 2.0, "works": 2.4, "garages": 2.4, "railway": 2.4,
          "cemetery": 2.6, "military": 2.6, "noise": 4.0, "noise_rail": 6.0, "unknown": 1.6}
# Walls (build plan item 8): under RIDE_BELOW ridden over, up to SMASH_BELOW broken, the rest hard.
RIDE_BELOW, SMASH_BELOW = 0.6, 1.2

# --- the hand lists the wall builder keeps today (game/scripts/city_barriers.gd), by a line's first
# point. They stay there until the builder reads `ty`; --selftest checks these copies against it.
SITE_WALLS = [
    ((-1639.7, -1217.3), ""), ((-1667.0, -1217.7), "balustrade_white"), ((-1657.7, -1219.1), "balustrade_white"),
    ((-1644.7, -1190.0), "balustrade_white"), ((-1656.4, -1197.6), "balustrade_white"),
    ((-1624.6, -1230.3), "balustrade_rail"), ((-1621.2, -1219.2), "balustrade_rail"),
    ((-1625.5, -1232.3), "balustrade_rail"), ((-1628.1, -1232.1), "balustrade_rail"),
    ((-1635.1, -1234.3), "tram_railing"), ((-1635.7, -1235.6), "tram_railing"),
]
LOW_WALLS = [(-820.1, 345.4), (-807.1, 378.0), (-1627.1, -1219.5)]
GARDEN_RINGS = (-620.0, -1700.0, 190.0, 220.0)   # x, z, width, depth (Rect2)
# A placed palette style (the bake's `st`, a street pass's verdict, SITE_WALLS) as a type.
STYLE_TYPE = {"tram_railing": "rail_tram", "balustrade": "balustrade", "balustrade_rail": "balustrade_rail",
              "balustrade_white": "balustrade_white", "low_wall": "low_wall", "garden_ring": "basin_rim",
              "basin_rim": "basin_rim", "island_edge": "island_edge", "fence_railing": "bars_black",
              "fence_mesh": "chain_link", "fence_wood": "wood", "wall_brick": "wall_brick",
              "wall_stone": "wall_stone", "wall_concrete": "wall_precast", "wall_noise": "noise_screen",
              "hedge": "hedge_low", "fence": "fence_plain", "wall": "wall_plaster", "pkin_wall": "low_wall"}

# --- OpenStreetMap's tags (rule step 2). fence_type per the wiki's Key:fence_type (2026-11-13) and
# the walls doc: `panel` is slabs in grooved posts, a precast wall.
FENCE_TYPE = {"bars": "bars_black", "railing": "bars_black", "metal_bars": "bars_black", "metal": "bars_black",
              "balustrade": "bars_black", "chain_link": "chain_link", "wire": "chain_link", "barbed_wire": "chain_link",
              "net": "ball_net", "panel": "wall_precast", "concrete": "wall_precast", "corrugated_metal": "hoarding",
              "temporary": "hoarding", "glass": "glass_screen", "paling": "wood", "slatted": "wood", "wood": "wood",
              "split_rail": "wood", "post_and_rail": "rail_street", "chain": "chain_posts", "pipe": "rail_street",
              "mesh": "mesh_panel", "welded_mesh": "mesh_panel", "hedge": "hedge_low", "brick": "wall_brick",
              "stone": "wall_stone"}
WALL_TAG = {"noise_barrier": "noise_screen", "gabion": "gabion", "brick": "wall_brick", "stone": "wall_stone",
            "dry_stone": "wall_stone", "concrete": "wall_precast", "jersey_barrier": "wall_precast",
            "castle_wall": "wall_brick", "flood_wall": "wall_stone", "seawall": "wall_stone",
            "retaining_wall": "wall_stone", "pise": "wall_plaster", "plastered": "wall_plaster"}
MATERIAL = {"brick": "wall_brick", "stone": "wall_stone", "granite": "wall_stone", "sandstone": "wall_stone",
            "masonry": "wall_stone", "concrete": "wall_precast", "reinforced_concrete": "wall_precast",
            "glass": "glass_screen", "wood": "wood", "metal": "bars_black", "steel": "bars_black",
            "plaster": "wall_plaster", "gabion": "gabion"}
# the map's own compact tags (tools/barrier_tags.py): m on walls, ft on fences
MAP_M = {"noise": "noise_screen", "gabion": "gabion", "brick": "wall_brick", "stone": "wall_stone",
         "concrete": "wall_precast", "glass": "glass_screen", "wood": "wood", "metal": "bars_black"}
MAP_FT = {"railing": "bars_black", "mesh": "chain_link", "wood": "wood"}

# --- the land a line stands by (rule step 4). The settings, from the OSM outlines (`ctx`), the
# map's own areas and surfaces, the buildings' kinds and names.
CTX_TAGS = [  # (key, values, setting), first match per outline
    ("amenity", ("school", "kindergarten", "childcare", "college"), "school"),
    ("leisure", ("schoolyard",), "school"),
    ("landuse", ("education",), "school"),
    ("amenity", ("embassy",), "embassy"), ("office", ("diplomatic",), "embassy"), ("diplomatic", None, "embassy"),
    ("amenity", ("place_of_worship", "monastery"), "church"), ("landuse", ("religious",), "church"),
    ("amenity", ("grave_yard",), "cemetery"), ("landuse", ("cemetery",), "cemetery"),
    ("landuse", ("military",), "military"), ("military", None, "military"),
    ("amenity", ("university", "hospital", "clinic", "courthouse", "townhall", "prison", "police",
                 "fire_station", "research_institute", "library", "social_facility"), "institution"),
    ("office", ("government",), "institution"), ("government", None, "institution"),
    ("landuse", ("construction",), "construction"),
    ("landuse", ("allotments",), "allotments"),
    ("landuse", ("railway",), "railway"),
    ("landuse", ("industrial", "depot", "brownfield"), "works"), ("power", ("substation", "plant"), "works"),
    ("man_made", ("wastewater_plant", "water_works", "works"), "works"),
    ("landuse", ("garages",), "garages"), ("amenity", ("parking",), "garages"),
    ("leisure", ("pitch", "stadium", "track", "sports_centre"), "pitch"),
    ("leisure", ("playground", "dog_park", "fitness_station"), "playground"),
    ("leisure", ("park", "garden"), "park"), ("landuse", ("recreation_ground", "village_green"), "park"),
    ("landuse", ("residential",), "housing"),
]
BUILDING_KIND = {"school": "school", "kindergarten": "school", "college": "school",
                 "university": "institution", "hospital": "institution", "government": "institution",
                 "public": "institution", "civic": "institution", "palace": "embassy",
                 "church": "church", "cathedral": "church", "chapel": "church", "religious": "church",
                 "monastery": "church", "presbytery": "church", "convent": "church", "synagogue": "church",
                 "industrial": "works", "warehouse": "works", "service": "works", "transformer_tower": "works",
                 "garage": "garages", "garages": "garages", "construction": "construction",
                 "house": "villa", "detached": "villa", "semidetached_house": "villa", "villa": "villa",
                 "apartments": "housing", "residential": "housing", "dormitory": "housing", "terrace": "housing",
                 "office": "office", "commercial": "office", "retail": "office", "hotel": "office",
                 "barracks": "military"}
# A building's name says more than its kind (Polish, lower case, word starts).
NAME_SETTING = [
    (r"\b(ambasad|rezydencja ambasador|konsulat|wydział konsularny)", "embassy"),
    (r"\b(kości[oó]ł|bazylika|katedra|kaplica|plebania|klasztor|parafi|cerkiew|synagog|zbór)", "church"),
    (r"\b(szkoła|liceum|gimnazjum|przedszkole|technikum|zespół szkół)", "school"),
    (r"\b(ministerstw|urząd|sąd |sąd$|sejm|senat|kancelaria|najwyższa izba|prokuratur|komend)", "institution"),
    (r"\b(uniwersytet|politechnik|wydział|instytut|akademi|collegium|szpital|klinik)", "institution"),
    (r"\b(pałac|pałacyk|willa)", "embassy"),
]
# The priority of the settings when a line has several (the first wins; walls doc 5 step 4).
SETTING_ORDER = ["construction", "cemetery", "military", "embassy", "church", "school", "institution",
                 "pitch", "playground", "allotments", "railway", "works", "garages", "villa", "park",
                 "plaza", "housing", "office"]

# Every rule: id -> (doc step, tc). The type per kind is in `decide`.
RULES = {
    "override": (0, "tag"), "site": (1, "tag"), "site_list": (1, "tag"),
    "tag_style": (2, "structure"), "tag_osm": (2, "tag"), "tag_map": (2, "tag"),
    "stairs": (3, "structure"), "deck": (3, "structure"), "island": (3, "structure"),
    "platform": (3, "structure"), "tram": (3, "structure"), "railway": (3, "structure"),
    "water": (3, "structure"), "road_main": (3, "structure"),
    "ring_small": (5, "context"), "fragment": (5, "context"), "default": (6, "default"),
}
for _s in SETTING_ORDER:
    RULES["ctx_" + _s] = (4, "context")

# The 20-sample check (walls doc 5; 2026-11-14, Mapillary/Panoramax photos of each line's middle,
# tools/overlay_object_types.py sheet; right / wrong / no photo of 20 drawn, judged by the map engineer):
#   tag 7/1/12, tram and platform 5/2/13 (both wrong: railway platforms; the platform rule now reads
#   only the tram stops), road_main 5/0/9, hazard class (fences made hard) 15/1/4 (the wrong one a
#   pond's railing: water now needs WATER_MIN), stairs 1/0/19 (not seen from the street);
#   railway fences 2/4 (precast) of 6: dropped, they keep H and hz; railway walls 1/0;
#   water 2/8/6: narrowed (WATER_MIN, no rings); park walls 3/2/15: narrowed to walls inside a park;
#   park fences: lawn guards 2/0, long ones 0/2; school 2/1, pitch 0/1; church, institution and
#   embassy fences (bars_pier) 3/2/15: dropped; works and garages fences 0/2/7; villa 3/1/16;
#   housing 2/2/10; office 1/1/18; construction 3/5/12: dropped (the outlines are years old).
# A rule with fewer than five judged lines is kept as built and listed as unproven (the report).
DROPPED = {("fence", "church"), ("fence", "institution"), ("fence", "embassy"),
           ("fence", "construction"), ("wall", "construction"), ("hedge", "construction")}

# Evidence reaches (m) and shares (of a line's samples); the walls doc 12 prototype's, then the
# hazards of build plan item 3.
SAMPLE = 4.0
TRAM_R, RAIL_R, STEP_R, ROAD_EDGE_R, PATH_R, BLD_R, SIDE = 5.0, 14.0, 6.0, 3.0, 3.0, 12.0, 2.0
PARALLEL = math.radians(20.0)
HZ_RAIL, HZ_WATER, HZ_DROP_AT, HZ_DROP, HZ_WALL_R, HZ_GUARD = 6.0, 5.0, 3.0, 1.5, 3.0, 1.5
SHARE = 0.5          # a structure rule needs this share of the samples
LAWN_MAX = 40.0      # a park fence shorter than this is a lawn guard (longer: the park's own fence)
SHARE_CTX = 0.3      # a setting by buildings near
SHARE_AREA = 0.4     # a setting by an area or outline on either side
HZ_SHARE = 0.3       # a hazard along this share of the line
RING_SPAN = 6.0
FRAGMENT_L, FRAGMENT_NEAR = 4.0, 5.0
# Water areas at least this large are water for the hazards and the waterside rule (the river, the
# ports, the big ponds); smaller ones are a fountain's or a pond's basin (20-sample check, 2026-11-14:
# 8 of 10 "waterside" walls were basin rims).
WATER_MIN = 50000.0
# The cross-city railway's tunnel mouths: rails inside are underground (game/scripts/trains.gd
# TUNNELS, which trims them the same way; --selftest compares the copies).
RAIL_TUNNELS = [
    [(-2018.0, 850.0), (-1992.0, 834.0), (-1966.0, 825.0), (-1962.0, 806.0), (-1962.0, 760.0), (-1890.0, 760.0), (-1890.0, 860.0)],
    [(186.7, 100.5), (170.3, 53.3), (113.6, 73.0), (130.0, 120.2)],
]
MAIN_ROADS = ("primary", "secondary", "tertiary", "primary_link", "secondary_link", "tertiary_link", "trunk", "trunk_link")


def project(lat, lon):
    return ((lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT)


def pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def length(p):
    return sum(math.dist(p[i], p[i + 1]) for i in range(len(p) - 1))


def seg_dist(q, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    l2 = dx * dx + dz * dz
    t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((q[0] - a[0]) * dx + (q[1] - a[1]) * dz) / l2))
    return math.hypot(q[0] - a[0] - t * dx, q[1] - a[1] - t * dz)


def angle_off(a1, a2):
    """The angle between two directions, ignoring which way they run (0..pi/2)."""
    return abs((a1 - a2 + math.pi / 2) % math.pi - math.pi / 2)


class Segs:
    """A cell index of segments with a payload: nearest within r, with the segment's direction."""
    def __init__(self, cell=16.0):
        self.cell, self.c = cell, collections.defaultdict(list)

    def add(self, p, tag, closed=False):
        pts = list(p) + ([p[0]] if closed and p else [])
        for a, b in zip(pts, pts[1:]):
            x0, x1 = sorted((a[0], b[0]))
            z0, z1 = sorted((a[1], b[1]))
            for gx in range(int(x0 // self.cell), int(x1 // self.cell) + 1):
                for gz in range(int(z0 // self.cell), int(z1 // self.cell) + 1):
                    self.c[(gx, gz)].append((a, b, tag))

    def near(self, q, r, parallel_to=None, test=None):
        """(distance, tag) of the nearest segment within r (parallel within PARALLEL when an
        angle is given; `test(tag)` filters), or (None, None)."""
        best, tag_best = r, None
        n = int(r // self.cell) + 1
        gx, gz = int(q[0] // self.cell), int(q[1] // self.cell)
        for ix in range(gx - n, gx + n + 1):
            for iz in range(gz - n, gz + n + 1):
                for a, b, tag in self.c.get((ix, iz), ()):
                    if test is not None and not test(tag):
                        continue
                    d = seg_dist(q, a, b)
                    if d >= best:
                        continue
                    if parallel_to is not None and angle_off(parallel_to, math.atan2(b[1] - a[1], b[0] - a[0])) > PARALLEL:
                        continue
                    best, tag_best = d, tag
        return (best, tag_best) if tag_best is not None else (None, None)


class Polys:
    """A cell index of polygons with a payload: which contain a point."""
    def __init__(self, cell=32.0):
        self.cell, self.c = cell, collections.defaultdict(list)

    def add(self, p, tag):
        if len(p) < 3:
            return
        xs, zs = [q[0] for q in p], [q[1] for q in p]
        box = (min(xs), min(zs), max(xs), max(zs))
        for gx in range(int(box[0] // self.cell), int(box[2] // self.cell) + 1):
            for gz in range(int(box[1] // self.cell), int(box[3] // self.cell) + 1):
                self.c[(gx, gz)].append((p, box, tag))

    def at(self, q):
        out = []
        for p, box, tag in self.c.get((int(q[0] // self.cell), int(q[1] // self.cell)), ()):
            if not (box[0] <= q[0] <= box[2] and box[1] <= q[1] <= box[3]):
                continue
            if inside(q, p):
                out.append(tag)
        return out


def inside(q, p):
    hit = False
    j = len(p) - 1
    for i in range(len(p)):
        if (p[i][1] > q[1]) != (p[j][1] > q[1]) and q[0] < (p[j][0] - p[i][0]) * (q[1] - p[i][1]) / (p[j][1] - p[i][1]) + p[i][0]:
            hit = not hit
        j = i
    return hit


class Terrain:
    """game/map/terrain.json, the 10 m grid (bilinear), plus nothing: the hazards' drop test."""
    def __init__(self, t):
        self.x0, self.z0, self.step, self.nx, self.nz, self.h = t["x0"], t["z0"], t["step"], t["nx"], t["nz"], t["h"]

    def at(self, x, z):
        fx = max(0.0, min(self.nx - 1.001, (x - self.x0) / self.step))
        fz = max(0.0, min(self.nz - 1.001, (z - self.z0) / self.step))
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        h = self.h
        a, b = h[j * self.nx + i], h[j * self.nx + i + 1]
        c, d = h[(j + 1) * self.nx + i], h[(j + 1) * self.nx + i + 1]
        return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v


def stable_id(kind, flat):
    """city_barriers.gd barrier_id (tools/street_pass.py stable_id): the points' mean on a 2 m grid."""
    n = len(flat) // 2
    cx = sum(flat[0::2][:n]) / max(n, 1)
    cz = sum(flat[1::2][:n]) / max(n, 1)
    return "barrier:%s:%d:%d" % (kind, int(math.floor(cx / 2.0 + 0.5)) * 2, int(math.floor(cz / 2.0 + 0.5)) * 2)


# --- OpenStreetMap: barrier ways and context outlines from an element list ------------------

def osm_read(elements):
    """(barriers, ctx, points) from OpenStreetMap elements, either Overpass `out geom` (ways and
    relation members carry `geometry`) or `out body` with the nodes beside them (the raw export
    bake_osm.py reads). barriers: [(tags, [(x, z)...])]; ctx: [(setting, [(x, z)...] ring)];
    points: [(setting, (x, z))] for nodes (an embassy mapped as a point)."""
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in elements if e.get("type") == "node" and "lat" in e}
    ways = {e["id"]: e for e in elements if e.get("type") == "way"}

    def way_pts(w):
        if w.get("geometry"):
            return [project(g["lat"], g["lon"]) for g in w["geometry"] if g]
        return [project(*nodes[i]) for i in w.get("nodes", []) if i in nodes]

    barriers, ctx, points = [], [], []
    for e in elements:
        t = e.get("tags") or {}
        if not t:
            continue
        setting = ctx_setting(t)
        if e["type"] == "node":
            if setting and "lat" in e and t.get("amenity") != "parking":
                points.append((setting, project(e["lat"], e["lon"])))
            continue
        if e["type"] == "way":
            p = way_pts(e)
            if t.get("barrier") in ("fence", "wall", "hedge", "retaining_wall") and len(p) >= 2:
                barriers.append((t, p))
            if setting and len(p) >= 4 and math.dist(p[0], p[-1]) < 0.5:
                ctx.append((setting, p[:-1]))
        elif e["type"] == "relation" and setting and t.get("type") in ("multipolygon", "boundary", None):
            parts = []
            for m in e.get("members", []):
                if m.get("type") != "way" or m.get("role", "outer") not in ("outer", ""):
                    continue
                if m.get("geometry"):
                    parts.append([project(g["lat"], g["lon"]) for g in m["geometry"] if g])
                elif m.get("ref") in ways:
                    parts.append(way_pts(ways[m["ref"]]))
            for ring in rings(parts):
                ctx.append((setting, ring))
    return barriers, ctx, points


def ctx_setting(t):
    for key, values, setting in CTX_TAGS:
        v = t.get(key)
        if v is not None and (values is None or v in values):
            return setting
    return None


def rings(parts, eps=0.5):
    """Closed rings from a multipolygon's outer ways (joined end to end)."""
    parts = [list(p) for p in parts if len(p) >= 2]
    out = []
    while parts:
        cur = parts.pop()
        grown = True
        while grown and math.dist(cur[0], cur[-1]) > eps:
            grown = False
            for i, p in enumerate(parts):
                if math.dist(cur[-1], p[0]) <= eps:
                    cur += p[1:]
                elif math.dist(cur[-1], p[-1]) <= eps:
                    cur += p[-2::-1]
                elif math.dist(cur[0], p[-1]) <= eps:
                    cur = p[:-1] + cur
                elif math.dist(cur[0], p[0]) <= eps:
                    cur = p[:0:-1] + cur
                else:
                    continue
                parts.pop(i)
                grown = True
                break
        if len(cur) >= 4 and math.dist(cur[0], cur[-1]) <= eps:
            out.append(cur[:-1])
    return out


def osm_type(t, kind):
    """The type OpenStreetMap's own tags give (rule step 2), or None."""
    if t.get("wall") in WALL_TAG and kind == "wall":
        return WALL_TAG[t["wall"]]
    if t.get("barrier") == "retaining_wall":
        return "wall_stone"
    ft = t.get("fence_type")
    if ft in FENCE_TYPE and kind == "fence":
        return FENCE_TYPE[ft]
    m = t.get("material")
    if m in MATERIAL and kind != "hedge":
        ty = MATERIAL[m]
        if kind == "fence" and ty in ("wall_stone", "wall_brick", "wall_plaster"):
            return "bars_pier"   # a fence of stone or brick: iron between masonry piers
        return ty
    return None


def match_barriers(lines, barriers):
    """For every barrier line, the index of the OSM way it was drawn from (mean distance under
    0.6 m, the same kind), or None."""
    kinds = {"fence": "fence", "wall": "wall", "retaining_wall": "wall", "hedge": "hedge"}
    g = Segs(cell=25.0)
    for i, (t, p) in enumerate(barriers):
        g.add(p, i)
    out = []
    for l in lines:
        if l.get("k") not in KINDS:
            out.append(None)
            continue
        p = pairs(l["p"])
        cands = set()
        for q in (p[0], p[-1], p[len(p) // 2]):
            for ix in range(int(q[0] // 25) - 1, int(q[0] // 25) + 2):
                for iz in range(int(q[1] // 25) - 1, int(q[1] // 25) + 2):
                    cands |= {s[2] for s in g.c.get((ix, iz), ())}
        best = (0.6, None)
        dense = densify(p, 2.0)
        for i in cands:
            t, bp = barriers[i]
            if kinds.get(t.get("barrier")) != l["k"]:
                continue
            ds = [min(seg_dist(q, a, b) for a, b in zip(bp, bp[1:])) for q in dense]
            m = sum(ds) / len(ds)
            if m < best[0]:
                best = (m, i)
        out.append(best[1])
    return out


def densify(p, every):
    out = [p[0]]
    for a, b in zip(p, p[1:]):
        n = max(1, int(math.dist(a, b) / every))
        out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(1, n + 1)]
    return out


# --- the map's own evidence --------------------------------------------------------------------

class Evidence:
    """Everything a line's samples are measured against: built once from the map."""
    def __init__(self, d, terrain=None, ctx=(), points=()):
        self.tram, self.rail, self.road, self.step, self.bld = Segs(), Segs(), Segs(), Segs(), Segs()
        self.path, self.guard, self.deck, self.shore, self.retain, self.fill = Segs(), Segs(), Segs(), Segs(), Segs(), Segs()
        self.lines = Segs()
        for t in d.get("trams", []):
            self.tram.add(pairs(t["p"]), "tram")
        for r in d.get("rails", []):
            for piece in outside(pairs(r["p"]), RAIL_TUNNELS):
                self.rail.add(piece, "rail")
        for r in d.get("roads", []):
            self.road.add(pairs(r["p"]), (r.get("k", ""), float(r.get("w", 6.0))))
        for s in d.get("steps", []):
            self.step.add(pairs(s["p"]), "steps")
        for p in d.get("paths", []):
            if p.get("k") in ("foot", "cycle"):
                self.path.add(pairs(p["p"]), p["k"])
        for g in d.get("guards", []):
            self.guard.add(pairs(g["p"]), "guard")
        for pc in (d.get("decks") or {}).get("pieces", []):
            self.deck.add(pairs(pc["p"]), max(float(pc.get("l", 3.0)), float(pc.get("r", 3.0))))
        for s in d.get("shore", []):
            self.shore.add(pairs(s["p"]), "shore")
        for w in d.get("walls", []):
            tops, bots = w.get("t", []), w.get("b", [])
            hmax = max((a - b for a, b in zip(tops, bots)), default=0.0)
            if hmax > HZ_DROP:
                self.retain.add(pairs(w["p"]), hmax)
        self.terrain = terrain
        for f in d.get("fills", []):
            p = pairs(f["p"])
            hs = f.get("h", [])
            if terrain is None or len(hs) != len(p):
                continue
            rise = max((h - terrain.at(*q) for h, q in zip(hs, p)), default=0.0)
            if rise > HZ_DROP:
                self.fill.add(p, max(float(f.get("l", 3.0)), float(f.get("r", 3.0))))
        self.names = []
        for b in d.get("buildings", []):
            p = pairs(b["p"])
            setting = name_setting(b.get("name", "")) or BUILDING_KIND.get(b.get("kind", ""))
            self.bld.add(p, setting or "other", closed=True)
        self.areas = Polys()
        for a in d.get("areas", []):
            if a.get("k") in ("park", "pitch", "plaza"):
                self.areas.add(pairs(a["p"]), a["k"])
            elif a.get("k") == "water":
                # the river, the ports and the big ponds: a fountain's or a small pond's rim is no hazard
                self.areas.add(pairs(a["p"]), "water" if poly_area(pairs(a["p"])) >= WATER_MIN else "pond")
        for s in d.get("surfaces", []):
            k = {"construction": "construction", "playground": "playground", "garden": "park"}.get(s.get("k"))
            if k:
                self.areas.add(pairs(s["p"]), k)
        self.islands = Polys()
        for s in d.get("islands", []):
            self.islands.add(pairs(s["p"]), "island")
        self.platforms = Segs()
        for l in d.get("lines", []):
            if l.get("k") == "platform":
                self.platforms.add(pairs(l["p"]), "platform")
        self.ctx = Polys(cell=64.0)
        for setting, ring in ctx:
            self.ctx.add(ring, setting)
        self.points = list(points)
        for i, l in enumerate(d.get("lines", [])):
            if l.get("k") in KINDS:
                self.lines.add(pairs(l["p"]), i)

    def water_at(self, q):
        return "water" in self.areas.at(q)


def poly_area(p):
    return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(p, p[1:] + p[:1]))) / 2.0


def outside(p, polys):
    """The pieces of a polyline whose points lie outside every polygon (point by point: the
    tunnels' rails are long ways, their points dense enough)."""
    out, cur = [], []
    for q in p:
        if any(inside(q, poly) for poly in polys):
            if len(cur) >= 2:
                out.append(cur)
            cur = []
        else:
            cur.append(q)
    if len(cur) >= 2:
        out.append(cur)
    return out


def name_setting(name):
    n = name.lower()
    for pat, setting in NAME_SETTING:
        if re.search(pat, n):
            return setting
    return None


def samples(p):
    """A point every SAMPLE m along a line: (point, direction, normal)."""
    out = []
    for a, b in zip(p, p[1:]):
        sl = math.dist(a, b)
        if sl < 0.05:
            continue
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        nrm = (-(b[1] - a[1]) / sl, (b[0] - a[0]) / sl)
        k = max(1, int(sl / SAMPLE))
        for j in range(k):
            t = (j + 0.5) / k
            out.append(((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), ang, nrm))
    return out


def measure(i, l, ev):
    """The shares of a line's samples that meet each piece of evidence, and its shape."""
    p = pairs(l["p"])
    L = length(p)
    sm = samples(p)
    v = collections.Counter()
    n = len(sm)
    for q, ang, nrm in sm:
        side = [(q[0] + nrm[0] * SIDE, q[1] + nrm[1] * SIDE), (q[0] - nrm[0] * SIDE, q[1] - nrm[1] * SIDE)]
        if ev.tram.near(q, TRAM_R, ang)[1]:
            v["tram"] += 1
        if ev.rail.near(q, RAIL_R, ang)[1]:
            v["rail"] += 1
        if ev.rail.near(q, HZ_RAIL)[1]:
            v["hz_railway"] += 1
        if ev.step.near(q, STEP_R)[1]:
            v["steps"] += 1
        d, rk = ev.road.near(q, 25.0, ang, test=lambda t: t[0] in MAIN_ROADS)
        if d is not None and d - rk[1] / 2 < ROAD_EDGE_R:
            v["road_main"] += 1
        d, rk = ev.road.near(q, 25.0)
        if d is not None and d - rk[1] / 2 < ROAD_EDGE_R:
            v["road_any"] += 1
        if ev.path.near(q, PATH_R, ang)[1]:
            v["path"] += 1
        if ev.platforms.near(q, 1.5, ang)[1]:
            v["platform"] += 1
        if ev.islands.at(q):
            v["island"] += 1
        if ev.guard.near(q, HZ_GUARD, ang)[1]:
            v["hz_deck"] += 1
        else:
            d, w = ev.deck.near(q, 20.0, ang)
            if d is not None and d < w + 1.5:
                v["hz_deck"] += 1
        wat = [(q[0] + nrm[0] * HZ_WATER, q[1] + nrm[1] * HZ_WATER), (q[0] - nrm[0] * HZ_WATER, q[1] - nrm[1] * HZ_WATER)]
        if ev.shore.near(q, HZ_WATER)[1] or any(ev.water_at(s) for s in wat):
            v["hz_water"] += 1
        drop = False
        if ev.retain.near(q, HZ_WALL_R)[1]:
            drop = True
        else:
            d, w = ev.fill.near(q, 25.0, ang)
            if d is not None and abs(d - w) < HZ_DROP_AT:
                drop = True
        if not drop and ev.terrain is not None:
            h0 = ev.terrain.at(*q)
            for s in ((q[0] + nrm[0] * HZ_DROP_AT, q[1] + nrm[1] * HZ_DROP_AT), (q[0] - nrm[0] * HZ_DROP_AT, q[1] - nrm[1] * HZ_DROP_AT)):
                if h0 - ev.terrain.at(*s) > HZ_DROP:
                    drop = True
        if drop:
            v["hz_drop"] += 1
        sides = set()
        for s in side:
            sides.update(ev.areas.at(s))
            sides.update(ev.ctx.at(s))
        for s in ev.ctx.at(q):
            sides.add(s)
        for s in sides:
            v["area_" + s] += 1
        if all("park" in ev.areas.at(s) for s in side):
            v["park_in"] += 1
        _d, bk = ev.bld.near(q, BLD_R)
        if bk is not None:
            v["b_" + bk] += 1
    ring = len(p) > 3 and math.dist(p[0], p[-1]) < 0.5
    cx = sum(q[0] for q in p) / len(p)
    cz = sum(q[1] for q in p) / len(p)
    span = 2 * max(math.dist((cx, cz), q) for q in p)
    pond = False
    if ring:
        pond = any(k in ("pond", "water") for k in ev.areas.at((cx, cz)))
        for setting, pt in ev.points:
            if abs(pt[0] - cx) < span and abs(pt[1] - cz) < span and inside(pt, p):
                v["area_" + setting] += n
    near = 0
    if L < FRAGMENT_L:
        mid = p[len(p) // 2]
        for q in (p[0], mid, p[-1]):
            d, j = ev.lines.near(q, FRAGMENT_NEAR, test=lambda j: j != i)
            if j is not None:
                near += 1
            if ev.bld.near(q, FRAGMENT_NEAR)[1] or ev.road.near(q, FRAGMENT_NEAR + 4.0)[1] or ev.path.near(q, FRAGMENT_NEAR)[1]:
                near += 1
    share = {k: c / n for k, c in v.items()} if n else {}
    return {"L": L, "n": n, "ring": ring, "span": span, "share": share, "near": near, "pond": pond}


# --- the rules -----------------------------------------------------------------------------------

def settings_of(m):
    """The line's settings by the land beside it, in SETTING_ORDER (rule step 4)."""
    s = m["share"]
    return [setting for setting in SETTING_ORDER
            if s.get("area_" + setting, 0) > SHARE_AREA or s.get("b_" + setting, 0) > SHARE_CTX]


def decide(l, m, tags, override):
    """(rule, ty, hs or None, extra hazard reason or None) for one line (first match wins)."""
    k = l["k"]
    s = m["share"]
    first = tuple(l["p"][:2])
    h = l.get("h")
    # 0: the street passes' verdict by stable id
    if override is not None:
        verdict, style = override[0], (override[1] if len(override) > 1 else "")
        if verdict == "REMOVE":
            return "override", "removed", None
        return "override", STYLE_TYPE.get(style, default_type(k, None)), None
    # 1: a landmark site that builds the wall itself, and the builder's other hand lists
    for pt, style in SITE_WALLS:
        if math.dist(pt, first) < 0.05:
            return "site", (STYLE_TYPE[style] if style else "site"), None
    if k == "wall":
        if any(math.dist(pt, first) < 0.05 for pt in LOW_WALLS):
            return "site_list", "low_wall", 0.55
        gx, gz, gw, gd = GARDEN_RINGS
        if m["ring"] and m["span"] < RING_SPAN * 2 and gx <= first[0] <= gx + gw and gz <= first[1] <= gz + gd:
            return "site_list", "basin_rim", 0.45
    # 2: tags (a placed style first: the bake's `st` round stairs)
    st = l.get("st")
    if st and st in STYLE_TYPE:
        return "tag_style", STYLE_TYPE[st], None
    ty = osm_type(tags, k) if tags else None
    if ty is None and k == "wall" and l.get("m") in MAP_M:
        ty = MAP_M[l["m"]]
    if ty is None and k == "fence" and l.get("ft") in MAP_FT:
        ty = MAP_FT[l["ft"]]
    if ty is not None:
        # a tag names the family; the structure beside it names the railing within it
        if ty == "bars_black" and s.get("tram", 0) > SHARE:
            ty = "rail_tram"
        elif ty == "bars_black" and s.get("road_main", 0) > SHARE and m["L"] < 80:
            ty = "rail_street"
        elif ty == "noise_screen" and s.get("rail", 0) > SHARE:
            return "tag_osm" if tags else "tag_map", ty, (None if h else WALL_H["noise_rail"])
        return ("tag_osm" if tags and osm_type(tags, k) else "tag_map"), ty, None
    # 3: the structure it belongs to
    if s.get("steps", 0) > SHARE and m["L"] < 40 and k != "hedge":
        return "stairs", ("balustrade" if k == "wall" else "balustrade_rail"), None
    if s.get("hz_deck", 0) > SHARE and k != "hedge":
        return "deck", ("parapet_concrete" if k == "wall" else "deck_railing"), None
    if s.get("island", 0) > SHARE and k == "wall":
        return "island", "island_edge", None
    if s.get("platform", 0) > SHARE and k == "fence":
        return "platform", "rail_tram", None
    if s.get("tram", 0) > SHARE:
        if k == "fence":
            return "tram", "rail_tram", None
        if k == "hedge":
            return "tram", "hedge_low", None
    if s.get("rail", 0) > SHARE and k == "wall":
        # 20-sample check (2026-11-14): the walls by the tracks are precast slabs; the fences there are
        # mesh, railings or precast alike, so a fence keeps its other evidence (and H by its hazard)
        return "railway", "wall_precast", WALL_H["railway"]
    if m["ring"] and m.get("pond") and k == "wall":
        return "ring_small", "basin_rim", WALL_H["ring"]
    if s.get("hz_water", 0) > SHARE and k != "hedge" and not m["ring"]:
        return "water", ("wall_stone" if k == "wall" else "rail_waterfront"), (1.1 if k == "wall" else None)
    if s.get("road_main", 0) > SHARE and k == "fence" and not s.get("area_park", 0) > SHARE_AREA:
        return "road_main", "rail_street", None
    # 5 (before 4 for the small things): a closed ring under 6 m is a rim; a stray fragment goes
    if m["ring"] and m["span"] < RING_SPAN:
        if k == "wall":
            return "ring_small", "basin_rim", WALL_H["ring"]
        if k == "hedge":
            return "ring_small", "hedge_low", 0.6
    if m["L"] < FRAGMENT_L and m["near"] == 0:
        return "fragment", "removed", None
    # 4: the land it encloses or borders
    for setting in settings_of(m):
        if (k, setting) in DROPPED:
            continue
        ty, hs = context_type(k, setting, m, h)
        if ty:
            return "ctx_" + setting, ty, hs
    # 6: the default by kind
    return "default", default_type(k, m), None


def context_type(k, setting, m, h):
    """(type, height for a wall with no height) of a line by its setting (walls doc 5 step 4)."""
    s = m["share"]
    if k == "hedge":
        if setting in ("villa", "embassy", "institution", "church"):
            return "hedge_tall", None
        if setting in ("park", "plaza", "playground", "pitch", "school"):
            return "hedge_low", None
        return None, None
    if k == "fence":
        table = {"school": "mesh_panel", "playground": "mesh_panel", "embassy": "bars_pier", "church": "bars_pier",
                 "institution": "bars_pier", "cemetery": "bars_pier", "military": "wall_precast",
                 "construction": "hoarding", "allotments": "chain_link", "railway": "chain_link",
                 "works": "chain_link", "garages": "chain_link", "villa": "green_fence", "housing": "bars_black",
                 "office": "bars_black"}
        if setting == "pitch":
            return ("ball_net" if (h or 0) >= 3.0 else "mesh_panel"), None
        if setting in ("park", "plaza"):
            if m["L"] < LAWN_MAX:
                return "low_lawn", None
            return "bars_black", None
        return table.get(setting), None
    # walls
    table = {"school": ("wall_plaster", "school"), "embassy": ("wall_plaster", "embassy"),
             "church": ("wall_brick", "church"), "institution": ("wall_plaster", "institution"),
             "cemetery": ("wall_brick", "cemetery"), "military": ("wall_brick", "military"),
             "construction": ("wall_precast", "works"), "works": ("wall_precast", "works"),
             "garages": ("wall_precast", "garages"), "railway": ("wall_precast", "railway"),
             "park": ("low_wall", "park"), "plaza": ("low_wall", "plaza"), "housing": ("wall_plaster", "housing"),
             "villa": ("wall_plaster", "housing"), "allotments": ("wall_precast", "works")}
    if setting == "park" and not s.get("park_in", 0) > SHARE_AREA:
        return None, None   # a wall on a park's edge is its boundary wall, not a lawn's low wall (20-sample check)
    if setting in table:
        ty, hk = table[setting]
        return ty, WALL_H[hk]
    return None, None


def default_type(k, m):
    if k == "fence":
        return "fence_plain"
    if k == "hedge":
        return "hedge_low"
    return "wall_plaster"


def hazard(m):
    """The reason a line must stay hard (build plan item 3), or None: the strongest first."""
    s = m["share"]
    for reason in ("deck", "railway", "water", "drop"):
        if s.get("hz_" + reason, 0) > HZ_SHARE:
            return reason
    return None


# The heavy look of a fence a hazard makes hard (walls doc 4.2). Not at a railway: the 20-sample check
# (2026-11-14) found the fences there steel mesh and railings, so the type stays what was identified.
HAZARD_LOOK = {"deck": "deck_railing", "water": "rail_waterfront", "drop": "parapet_concrete"}


def classify(l, m, rule, ty, hs):
    """(sc, hz, ty, hs) from the type, the height and the hazards."""
    k = l["k"]
    fam = TYPES[ty][0]
    h = l.get("h")
    height = h if h is not None else (hs if hs is not None else TYPES[ty][1])
    hz = None
    if fam == "ghost":
        return "G", None, ty, None
    if k == "wall":
        if ty in ("balustrade", "balustrade_rail", "balustrade_white", "parapet_concrete"):
            sc = "H"
        else:
            sc = "R" if height < RIDE_BELOW else ("S" if height < SMASH_BELOW else "H")
        reason = hazard(m)
        if reason and sc != "H" and ty not in ("island_edge", "basin_rim"):
            sc, hz = "H", reason
            if ty in ("low_wall",):
                ty = "parapet_concrete"
                hs = None if h is not None else 1.1
        return sc, hz, ty, hs
    sc = FAMILY_CLASS[fam]
    if fam == "low":
        sc = "R" if height < RIDE_BELOW else "S"
    if ty in ("rail_tram", "balustrade_rail", "balustrade", "balustrade_white"):
        sc = "H"   # build plan item 3: tram railings and stair balustrades keep H (a track bed, a stair hole)
    reason = hazard(m)
    if reason:
        hz = reason
        if sc != "H":
            sc = "H"
            if k == "fence" and rule not in ("override", "site"):
                if reason in ("drop", "deck") and m["share"].get("road_any", 0) > SHARE:
                    ty = "guard_rail"
                elif reason in HAZARD_LOOK:
                    ty = HAZARD_LOOK[reason]
    return sc, hz, ty, hs


def type_height(k, ty, m, rule):
    """The height a line with no mapped height stands at: the setting's for walls, the type's for
    fences and hedges (a hedge outside a park 1.2 m, walls doc 5 step 6)."""
    if k == "hedge" and ty == "hedge_low" and not (m["share"].get("area_park", 0) > SHARE_AREA or rule in ("tram", "ring_small")):
        return 1.2
    if k == "wall" and rule == "default":
        return WALL_H["unknown"]
    return TYPES[ty][1]


def load_overrides():
    path = os.path.join(ROOT, "game", "data", "road_objects.json")
    if not os.path.exists(path):
        return {}
    return (json.load(open(path, encoding="utf-8")).get("items") or {})


def apply(d, map_dir=None, osm=None, rows=None, overrides=None):
    """Type every barrier line of the map data `d` in place. `osm`: OpenStreetMap elements (or
    None: the map's own evidence alone). Returns a summary string."""
    lines = d.get("lines", [])
    terrain = None
    if map_dir and os.path.exists(os.path.join(map_dir, "terrain.json")):
        terrain = Terrain(json.load(open(os.path.join(map_dir, "terrain.json"), encoding="utf-8")))
    barriers, ctx, points = osm_read(osm) if osm else ([], [], [])
    ev = Evidence(d, terrain, ctx, points)
    matched = match_barriers(lines, barriers) if barriers else [None] * len(lines)
    overrides = load_overrides() if overrides is None else overrides
    n_osm = 0
    for i, l in enumerate(lines):
        if l.get("k") not in KINDS:
            continue
        for key in ("ty", "tc", "sc", "hz", "hs"):
            l.pop(key, None)
        tags = barriers[matched[i]][0] if matched[i] is not None else None
        n_osm += tags is not None
        m = measure(i, l, ev)
        rule, ty, hs = decide(l, m, tags, overrides.get(stable_id(l["k"], l["p"])))
        sc, hz, ty, hs = classify(l, m, rule, ty, hs)
        if hs is None and sc != "G":
            hs = type_height(l["k"], ty, m, rule)
        l["ty"] = ty
        l["tc"] = RULES[rule][1] if not (hz and RULES[rule][1] == "default") else "structure"
        l["sc"] = sc
        if hz:
            l["hz"] = hz
        if "h" not in l and hs is not None and sc != "G":
            l["hs"] = round(hs, 2)
        if rows is not None:
            p = pairs(l["p"])
            mid = p[len(p) // 2] if len(p) > 2 else ((p[0][0] + p[-1][0]) / 2, (p[0][1] + p[-1][1]) / 2)
            rows.append({"i": i, "k": l["k"], "rule": rule, "ty": l["ty"], "tc": l["tc"], "sc": sc, "hz": hz or "",
                         "h": l.get("h", l.get("hs")), "L": round(m["L"], 1), "x": round(mid[0], 1), "z": round(mid[1], 1),
                         "osm": tags is not None,
                         "ev": {k: round(v, 2) for k, v in sorted(m["share"].items()) if v >= 0.1}})
    d[KEY] = {"v": VERSION, "osm": n_osm, "ctx": len(ctx)}
    return summary(d)


def summary(d):
    """One line: metres per class, the default share of the fences, the hard fences by reason."""
    per_kind = collections.defaultdict(float)
    default = collections.defaultdict(float)
    sc = collections.defaultdict(float)
    hz = collections.Counter()
    for l in d.get("lines", []):
        if l.get("k") not in KINDS or "ty" not in l:
            continue
        L = length(pairs(l["p"]))
        per_kind[l["k"]] += L
        sc[l["sc"]] += L
        if l["tc"] == "default":
            default[l["k"]] += L
        if l.get("hz") and l["k"] == "fence":
            hz[l["hz"]] += L
    stamp = d.get(KEY, {})
    return ("object_types: v%s, %d OSM ways matched, %d context outlines; fence default %.1f %% of %.1f km, "
            "wall default %.1f %%, hedge default %.1f %%; class km H %.1f S %.1f R %.1f G %.1f; hard fences km %s"
            % (stamp.get("v"), stamp.get("osm", 0), stamp.get("ctx", 0),
               100 * default["fence"] / max(per_kind["fence"], 1), per_kind["fence"] / 1000,
               100 * default["wall"] / max(per_kind["wall"], 1), 100 * default["hedge"] / max(per_kind["hedge"], 1),
               sc["H"] / 1000, sc["S"] / 1000, sc["R"] / 1000, sc["G"] / 1000,
               ", ".join("%s %.1f" % (k, v / 1000) for k, v in sorted(hz.items())) or "none"))


def per_type(d):
    """{(kind, ty): metres} of the typed lines."""
    out = collections.defaultdict(float)
    for l in d.get("lines", []):
        if l.get("k") in KINDS and "ty" in l:
            out[(l["k"], l["ty"])] += length(pairs(l["p"]))
    return out


# --- commands --------------------------------------------------------------------------------------

def fetch(out):
    """The context outlines and barrier ways from Overpass (ODbL), with a back-off."""
    s, w, n, e = BOX[0] - 0.002, BOX[1] - 0.003, BOX[2] + 0.002, BOX[3] + 0.003
    bb = "%.4f,%.4f,%.4f,%.4f" % (s, w, n, e)
    sel = []
    for key, values, _setting in CTX_TAGS:
        if values is None:
            sel.append('nwr["%s"]' % key)
        else:
            sel.append('nwr["%s"~"^(%s)$"]' % (key, "|".join(values)))
    sel.append('way["barrier"~"^(fence|wall|hedge|retaining_wall)$"]')
    q = "[out:json][timeout:300][bbox:%s];(%s;);out geom;" % (bb, ";".join(sel))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    for attempt in range(5):
        tmp = out + ".part"
        r = subprocess.run(["curl", "-sS", "-f", "-m", "600", "-A", UA, "--data-urlencode", "data=" + q,
                            "-o", tmp, OVERPASS])
        if r.returncode == 0:
            try:
                n_el = len(json.load(open(tmp, encoding="utf-8"))["elements"])
            except (ValueError, KeyError):
                n_el = -1
            if n_el > 0:
                os.replace(tmp, out)
                print("object_types fetch: %d elements, %.1f MB -> %s" % (n_el, os.path.getsize(out) / 1e6, out))
                return 0
        wait = 30 * (attempt + 1)
        print("object_types fetch: Overpass failed (try %d), waiting %d s" % (attempt + 1, wait))
        time.sleep(wait)
    return 1


def sample(rows, rule, n=20, seed=5, skip=0):
    """The 20-sample check's draw: `n` lines of one rule, fixed seed; `skip` draws past the first
    (replacements for lines with no photo)."""
    pool = [r for r in rows if r["rule"] == rule]
    rnd = random.Random("%s:%d" % (rule, seed))
    rnd.shuffle(pool)
    return pool[skip:skip + n]


def selftest():
    fails = []

    def check(name, got, want):
        if got != want:
            fails.append("%s: got %r, want %r" % (name, got, want))

    # the OSM reader: `out geom` and `out body`, a multipolygon joined from two ways
    def ll(x, z):
        return {"lat": LAT0 - z / M_PER_DEG_LAT, "lon": LON0 + x / M_PER_DEG_LON}
    sq = [(0, 0), (40, 0), (40, 40), (0, 40), (0, 0)]
    geom = [{"type": "way", "id": 1, "tags": {"amenity": "school"}, "geometry": [ll(*q) for q in sq]},
            {"type": "relation", "id": 2, "tags": {"type": "multipolygon", "landuse": "cemetery"},
             "members": [{"type": "way", "role": "outer", "geometry": [ll(100, 0), ll(140, 0), ll(140, 40)]},
                         {"type": "way", "role": "outer", "geometry": [ll(100, 0), ll(100, 40), ll(140, 40)]}]},
            {"type": "way", "id": 3, "tags": {"barrier": "fence", "fence_type": "chain_link"}, "geometry": [ll(0, 60), ll(30, 60)]},
            {"type": "node", "id": 4, "lat": ll(5, 5)["lat"], "lon": ll(5, 5)["lon"], "tags": {"office": "diplomatic"}}]
    b, c, p = osm_read(geom)
    check("geom barriers", len(b), 1)
    check("geom ctx", sorted(s for s, _ in c), ["cemetery", "school"])
    check("geom points", [s for s, _ in p], ["embassy"])
    body = [{"type": "node", "id": 10 + i, **ll(*q)} for i, q in enumerate(sq[:4])]
    body.append({"type": "way", "id": 20, "nodes": [10, 11, 12, 13, 10], "tags": {"leisure": "playground"}})
    b, c, p = osm_read(body)
    check("body ctx", [s for s, _ in c], ["playground"])
    check("osm_type panel", osm_type({"barrier": "fence", "fence_type": "panel"}, "fence"), "wall_precast")
    check("osm_type noise", osm_type({"barrier": "wall", "wall": "noise_barrier"}, "wall"), "noise_screen")
    check("osm_type temporary", osm_type({"barrier": "fence", "fence_type": "temporary"}, "fence"), "hoarding")
    # the rules on a small synthetic map
    d = {"trams": [{"p": [0, 100, 200, 100]}], "rails": [{"p": [0, 300, 200, 300]}],
         "roads": [{"p": [0, 500, 200, 500], "k": "primary", "w": 10.0}], "steps": [], "paths": [],
         "buildings": [{"p": [50, 700, 70, 700, 70, 720, 50, 720], "kind": "school", "name": ""}],
         "areas": [{"k": "park", "p": [0, 900, 200, 900, 200, 1000, 0, 1000]}], "surfaces": [], "islands": [],
         "platforms": [], "guards": [], "decks": {"pieces": []}, "shore": [], "walls": [], "fills": [],
         "lines": [{"k": "fence", "p": [0, 102, 100, 102]},          # tram bed
                   {"k": "fence", "p": [0, 305, 100, 305]},          # railway fence: H by its hazard, no type
                   {"k": "fence", "p": [0, 507, 60, 507]},           # main road edge
                   {"k": "fence", "p": [40, 725, 80, 725]},          # by a school
                   {"k": "hedge", "p": [10, 950, 100, 950]},         # park hedge
                   {"k": "wall", "p": [10, 960, 60, 960]},           # park wall: low, R
                   {"k": "wall", "p": [500, 500, 502, 500]},         # a stray fragment
                   {"k": "wall", "p": [300, 600, 302, 600, 302, 602, 300, 602, 300, 600]},  # a small ring
                   {"k": "fence", "p": [600, 1500, 700, 1500]},      # nothing known
                   {"k": "fence", "p": [600, 1600, 700, 1600], "ft": "mesh"},
                   {"k": "wall", "p": [0, 296, 100, 296]}]}         # railway wall: precast
    rows = []
    apply(d, None, None, rows, overrides={})
    got = [(r["rule"], r["ty"], r["sc"], r["hz"]) for r in rows]
    want = [("tram", "rail_tram", "H", ""), ("default", "fence_plain", "H", "railway"), ("road_main", "rail_street", "S", ""),
            ("ctx_school", "mesh_panel", "S", ""), ("ctx_park", "hedge_low", "S", ""), ("ctx_park", "low_wall", "R", ""),
            ("fragment", "removed", "G", ""), ("ring_small", "basin_rim", "R", ""), ("default", "fence_plain", "S", ""),
            ("tag_map", "chain_link", "S", ""), ("railway", "wall_precast", "H", "")]
    for g, w in zip(got, want):
        check("rule %s" % w[0], g, w)
    check("every line typed", all("ty" in l and "tc" in l and "sc" in l for l in d["lines"]), True)
    check("park wall height", d["lines"][5].get("hs"), 0.5)
    check("stamp", d[KEY]["v"], VERSION)
    # the hand lists against the wall builder's
    src = open(os.path.join(ROOT, "game", "scripts", "city_barriers.gd"), encoding="utf-8").read()
    gd_site = re.findall(r'\[Vector2\(([-\d.]+), ([-\d.]+)\), "([a-z_]*)"\]', src.split("const SITE_WALLS")[1].split("\n]")[0])
    check("SITE_WALLS", [((float(x), float(z)), s) for x, z, s in gd_site], SITE_WALLS)
    gd_low = re.findall(r"Vector2\(([-\d.]+), ([-\d.]+)\)", src.split("const LOW_WALLS")[1].split("\n")[0])
    check("LOW_WALLS", [(float(x), float(z)) for x, z in gd_low], LOW_WALLS)
    tr = open(os.path.join(ROOT, "game", "scripts", "trains.gd"), encoding="utf-8").read()
    gd_tun = []
    for name in ("TUNNEL_ZAWISZY", "TUNNEL_POWISLE"):
        body = tr.split("const %s := [" % name)[1].split("]\n")[0]
        gd_tun.append([(float(x), float(z)) for x, z in re.findall(r"Vector2\(([-\d.]+), ([-\d.]+)\)", body)])
    check("RAIL_TUNNELS", gd_tun, RAIL_TUNNELS)
    gd_rings = re.findall(r"[-\d.]+", src.split("const GARDEN_RINGS := Rect2(")[1].split(")")[0])
    check("GARDEN_RINGS", tuple(float(v) for v in gd_rings), GARDEN_RINGS)
    for ty in set(STYLE_TYPE.values()) | set(FENCE_TYPE.values()) | set(WALL_TAG.values()) | set(MATERIAL.values()) | set(HAZARD_LOOK.values()):
        if ty not in TYPES:
            fails.append("unknown type %s" % ty)
    for f in fails:
        print("object_types selftest: " + f)
    print("object_types selftest: %s (%d cases)" % ("OK" if not fails else "FAIL", 20 + len(want)))
    return 0 if not fails else 1


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = {a.split("=")[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv if a.startswith("--")}
    if "--selftest" in opt:
        return selftest()
    if "--check" in opt:
        map_dir = args[0] if args else MAP_DIR
        d = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
        bar = [l for l in d.get("lines", []) if l.get("k") in KINDS]
        typed = sum(1 for l in bar if "ty" in l and "tc" in l and "sc" in l)
        ok = bar and typed == len(bar)
        print("object_types: %s (%d of %d barrier lines typed)" % ("OK" if ok else "FAIL", typed, len(bar)))
        if typed:
            print(summary(d))
        return 0 if ok else 1
    if not args:
        print(__doc__)
        return 2
    cmd = args[0]
    if cmd == "fetch":
        return fetch(opt.get("--out", CTX_FILE))
    if cmd == "sample":
        rows = json.load(open(args[1], encoding="utf-8"))
        for r in sample(rows, args[2], int(opt.get("--n", 20)), int(opt.get("--seed", 5)), int(opt.get("--skip", 0))):
            print(json.dumps(r, ensure_ascii=False))
        return 0
    if cmd == "apply":
        map_dir = args[1] if len(args) > 1 else MAP_DIR
        src = os.path.join(map_dir, "centrum.json")
        d = json.load(open(src, encoding="utf-8"))
        osm = None
        if opt.get("--osm"):
            osm = json.load(open(opt["--osm"], encoding="utf-8"))["elements"]
        rows = [] if opt.get("--rows") else None
        print(apply(d, map_dir, osm, rows))
        with open(opt.get("--out", src), "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
        if rows is not None:
            with open(opt["--rows"], "w", encoding="utf-8") as f:
                json.dump(rows, f, ensure_ascii=False)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
