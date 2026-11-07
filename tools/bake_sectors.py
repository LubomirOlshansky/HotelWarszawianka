"""Loop 3c: split the baked map into 512 m sectors, so the game can stream the city.

    python3 -I tools/bake_sectors.py [MAP_DIR]          (MAP_DIR defaults to game/map)

Run it after the bake chain (bake_osm.py, bake_gugik.py, bake_ao.py, bake_lights.py,
bake_water.py) and before the prebuilt city (tools/bake_city.gd), as docs/DEVELOPMENT.md "Map data"
says. It reads centrum.json, lod2.bin and lod2.json and writes:

  index.json             the global index (docs/DEMO.md 2.4): what the whole map needs at
                         once: the lane graph, decks, approaches and tunnels, the points of
                         interest and addresses, the landmark outlines, the water's edge, the
                         kerbs and islands the car feels, and what the minimap, traffic,
                         trams, people, missions and easter eggs read (roads, paths, areas,
                         trams, signals, platforms, guard rails, columns, parked cars, the
                         scanned trees); `site_parts` (the building parts landmarks.gd finds
                         its sites in) and `sectors` (the grid).
  sectors/<i>_<j>.json   one sector's features, in the same shape as centrum.json: every
                         feature that comes within MARGIN of the sector (a way crossing a
                         border goes to both, with its full geometry, so kerbs and markings
                         meet), and every point thing (trees, lamps, parked cars, props)
                         within POINT_MARGIN. The map builder keeps only the triangles,
                         instances and colliders whose centre lies in the sector, so the
                         sectors together are the monolithic city exactly.
                         Its `lod2_runs` are the LoD2 buildings (whole ones) that come within
                         MARGIN: pairs of vertex indices into lod2.bin, one pair per building
                         (the builder's runs of one style seed, found here once on the whole
                         file, so a building never merges with a neighbour of the same seed).

Sector (i, j) covers x in [i * 512, (i + 1) * 512) and z in [j * 512, (j + 1) * 512), from the
map's origin (bake_osm.py LAT0/LON0; the origin and the box are unchanged by this loop).
The AO, lamp-light and surface maps stay whole (one texture each, shared by every sector):
see docs/DEVELOPMENT.md "Sectors and streaming" for why, and what loop 3d does instead.

Loop 3d-1: these files are derived and not committed (.gitignore); a fresh clone makes them
with tools/setup_map.sh. It also writes sectors/split.stamp: the SHA-256 of what it read (SPLIT_INPUTS),
so tools/check_map_data.py tells a stale split by content, not by file times (a checkout
scrambles those).

Standard library only; prints what it wrote.
"""
import hashlib
import json
import math
import os
import struct
import sys
from array import array

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import map_shape  # noqa: E402  (map north: the box and its north extension)

SECTOR = 512.0
BUILDING_SLACK = 6.0   # bake_osm.py keeps buildings hanging this far over the map's edge
# Loop 3d-1: what the split is made from (map-dir files, and this script), hashed into
# sectors/split.stamp; tools/check_map_data.py SPLIT_INPUTS reads the same names.
SPLIT_INPUTS = ["centrum.json", "lod2.bin", "lod2.json"]
# Features (ways, areas, buildings) go to every sector within this many metres of their box:
# their own triangles reach a road's width beyond its line (27.5 m wide, 10 m off its line at
# most), and the builder looks round them (a shop sign looks up to ~33 m ahead for a street).
# A part that may float (min_height >= 10 m, map_builder.gd FLOAT_MIN) brings along whatever
# could carry it (the parts and LoD2 footprints under it, however far it reaches).
MARGIN = 48.0
FLOAT_MIN = 10.0
FLOAT_SLACK = 2.5
# A shop sign looks this far from its building for a street, and this far for a roof in front.
SIGN_STREET = 40.0
SIGN_FRONT = 8.0
# Point things (trees, lamps, props, parked cars): their instances are filed by position,
# but a lamp's halo hangs 1.2 m off it and a parked car's collider reaches 2.1 m.
POINT_MARGIN = 8.0
# Map north: a sector is kept when it meets the map grown by this (the ground's 10 m cells on the
# map's edge, and the 6 m a building may hang over it).
GROUND_CELL = 10.0

# Per-sector feature lists of dictionaries, and where each keeps its geometry.
SECTOR_LISTS = {
    "roads": "p", "paths": "p", "trams": "p", "areas": "p", "buildings": "p", "markings": "p",
    "carriage": "p", "kerbs": "p", "medians": "s", "guards": "p", "symbols": "xz", "sand": "p",
    "sandbars": "p", "rails": "p", "platforms": "p", "islands": "p", "lines": "p", "surfaces": "p",
    "steps": "p", "walls": "p", "garage_doors": "c", "tram_xings": "p", "asphalt_fills": "p", "tram_noses": "p",
    "citywalls": "p",
}
# Flat point lists: values per thing.
SECTOR_POINTS = {"trees": 4, "lamps": 2, "signals": 3, "parked": 4, "benches": 3, "bins": 3,
                 "bikes": 3, "columns": 3, "shelters": 3}
# Small whole-map lists every sector's builder reads as they are.
SECTOR_WHOLE = ["lod2_cuts", "lod2_open"]
# Keys only the sectors need (the rest of centrum.json goes to the index). The rails stay in the
# index too: trains.gd runs on the whole network (docs/design/railway.md T1).
SECTOR_ONLY = {"buildings", "markings", "carriage", "symbols", "sand", "sandbars", "surfaces",
               "steps", "lines", "walls", "garage_doors", "lamps", "benches", "bins",
               "bikes", "shelters", "trees", "trees3d_crown", "tram_xings", "asphalt_fills", "tram_noses",
               "citywalls"}

# Where landmarks.gd looks for the building parts its sites are made of (it reads every
# building whose centre lies inside one of these): the outlines it finds by name and the
# areas it searches by position (landmarks.gd _find_sites, _find_stadium, _find_centralna,
# _find_towers, _palace_frame). tools/bake_city.gd checks the sites found from `site_parts`
# against the whole map's, so a landmark added there without a line here fails the bake.
SITE_NAMES = ["Pałac Kultury i Nauki", "Złote Tarasy", "Lumen", "Skylight", "Rotunda PKO", "Varso Tower",
              # Varso Place (Krajobraz K3, 2026-11-02): the roof terraces on Varso 1 and 2 (landmarks.gd
              # _build_varso_place reads their parts' heights; the buildings stay the map's)
              "Varso I", "Varso II",
              # the skyline's towers (landmarks.gd TOWERS, the landmarks loop)
              "Złota 44", "Warsaw Spire", "Q22", "Rondo 1", "InterContinental", "Cosmopolitan",
              "Warsaw Trade Tower", "Skyliner", "Warsaw Unit", "Mennica Legacy Tower", "Generation Park Y",
              # RD-3 (2026-11-06): the roof terraces on Generation Park Z and X (landmarks.gd _find_terraces)
              "Generation Park Z", "Generation Park X",
              "Skysawa", "Błękitny Wieżowiec", "Warszawskie Centrum Finansowe", "Centrum LIM", "Chałubińskiego 8",
              "Spektrum Tower", "The Bridge", "Bellona", "Hilton Warsaw City", "The Westin Warsaw", "Novotel Warszawa Centrum",
              "Central Tower", "Ilmet", "Platinum Tower A", "Platinum Tower B", "Łucka City", "Prosta Tower", "Widok Towers", "PZU Tower", "JM Tower",
              # map north (2026-10-31): Arkadia, for the landmarks lane (docs/DEMO.md 2.2)
              "Westfield Arkadia",
              # first scene item 3 (2026-10-31): the Eastern Wall's stores (landmarks.gd DTC)
              "Junior", "Sawa", "Wars",
              # the Copernicus Science Centre (2026-11-01): its low wings and the overhanging corner
              "Centrum Nauki Kopernik",
              # the University Library (2026-10-31): its roof houses and round lights
              "Biblioteka Uniwersytecka",
              # Hotel Metropol's roof sign (landmarks.gd _build_metropol_sign reads its parts' height)
              "Hotel Metropol",
              # Ujazdowski Castle (2026-11-01): a model on its mapped outline
              "Zamek Ujazdowski",
              # HOTEL PIURE's rooftop sign LORETKA (landmarks.gd _build_loretka reads its parts' height)
              "Puro Warszawa Centrum",
              # Level 26, the rooftop club on the Atlas Tower (landmarks.gd _build_level26_club reads its crown)
              "Atlas Tower",
              # Hortus (2026-11-02): its tenement-style flats on Drewniana, unnamed in OSM, found
              # by landmarks.gd HORTUS_FLATS_AT next to the outline
              "Hortus",
              # Plac Bankowy (2026-11-02): the Ratusz's colonnades stand on its mapped columns
              # (landmarks.gd _build_ratusz reads the building=column parts by the outline)
              "Urząd Miasta Stołecznego Warszawy"]
SITE_PAD = 12.0
# Building kinds landmarks.gd finds wherever they lie (the barges, 2026-11-01: _find_barges).
SITE_KINDS = ("boat", "houseboat")
SITE_AREAS = [
    (-1345.0, -1790.0, -1200.0, -1690.0),   # Sąd Najwyższy's colonnade (landmarks.gd SN_BOX: unnamed OSM columns)
    (-270.0, -1510.0, -20.0, -1260.0),      # the boulevards' bar pavilions (landmarks.gd BULWAR_PAW_BOX)
    (25.0, -1110.0, 65.0, -1065.0),         # and their containers and kiosks (BULWAR_BAR_BOXES)
    (195.0, -1068.0, 245.0, -1025.0),
    (670.0, -575.0, 712.0, -525.0),
    (1250.0, -820.0, 1700.0, -370.0),       # Stadion Narodowy's masts (Rect2(1250, -820, 450, 450))
    (-1520.0, 472.5, -1320.0, 672.5),       # Warszawa Centralna (CENTRALNA ± its 146 x 92 m zone)
    (910.0, -165.0, 950.0, -105.0),         # Most Poniatowskiego's towers (the fallback search)
    (1398.0, -332.0, 1443.0, -267.0),
    (1085.0, 1470.0, 1120.0, 1515.0),       # Stadion Leguminy's bowl (landmarks.gd LEGIA_AT, the 27 m outline: its vertices average near 1100, 1492)
    (-7.0, 235.0, 13.0, 255.0),             # Muzeum Narodowe (its outline's centre, by landmarks.gd MUZEUM)
    (-680.0, 1180.0, -350.0, 1620.0),       # MDM (Plac Konstytucji to Plac Zbawiciela, landmarks.gd _find_mdm)
    (-2690.0, 170.0, -2655.0, 215.0),       # Warsaw Spire's east wing (landmarks.gd TOWERS spire "with")
    (-2765.0, 135.0, -2735.0, 170.0),       # and its north-west wing
    (-2700.0, 560.0, -2655.0, 650.0),       # The Warsaw HUB's towers (landmarks.gd TOWERS "at")
    (-2723.0, 487.0, -2689.0, 538.0),       # and its round-ended hotel tower (TOWERS crowne "at")
    (-260.0, 325.0, -240.0, 345.0),         # the BGK building, Al. Jerozolimskie 7 (unnamed in OSM; landmarks.gd BGK_AT)
    (-165.0, 55.0, -155.0, 65.0),           # Foksal 13 (unnamed in OSM; landmarks.gd _find_foksal, its address point)
    (-193.0, 46.0, -183.0, 56.0),           # and Foksal 15
    (70.0, 20.0, 100.0, 45.0),              # Młotek, Smolna 8 (landmarks.gd ML_AT)
    (-820.0, -1185.0, -790.0, -1160.0),     # Kozia 9 (unnamed in OSM; landmarks.gd KZ_AT)
    (-475.0, -960.0, -450.0, -940.0),       # Karowa 18a (unnamed in OSM; landmarks.gd KR_AT)
    (-650.0, -790.0, -630.0, -765.0),       # Plac Piłsudskiego's south-east block (landmarks.gd KROLEWSKA_BLOCK)
    (-3105.0, -2455.0, -2920.0, -2335.0),   # map north: the Forest tower's office block (unnamed in OSM; docs/DEMO.md 2.2)
    (-2175.0, -2520.0, -1945.0, -2335.0),   # Gdański Business Center (unnamed in OSM; landmarks.gd GBC_BOX)
    (-445.0, 1605.0, -395.0, 1680.0),       # Kościół Najświętszego Zbawiciela (landmarks.gd ZB_NAVE_AT, ZB_TOWER_AT)
    (-2290.0, 185.0, -2165.0, 235.0),       # Norblin's old works (landmarks.gd NORBLIN_OLD, F's look check 2026-11-03)
    (-2254.0, 232.0, -2234.0, 252.0),       # and its glazed hall on Prosta ("Verit", NORBLIN_HALL_AT)
    (-2410.0, 160.0, -2345.0, 265.0),       # Prosta 28's tower, annex and wings (unnamed in OSM; landmarks.gd P28_BOX)
    # behind the Eastern Wall (landmarks.gd _find_behind): the 75 m tower and the four 1960s
    # slabs, unnamed in OSM, found by the outline under TOWER75_AT and SLAB_AT (their bboxes)
    (-837.0, 245.0, -804.0, 270.0),
    (-875.0, 66.0, -851.0, 108.0),
    (-874.0, 149.0, -841.0, 215.0),
    (-826.0, 185.0, -800.0, 229.0),
    (-793.0, 287.0, -764.0, 333.0),
    # Pasaż Wiecha's pavilions (landmarks.gd _find_wiecha, 2026-11-02): the four outlines whose
    # vertex average is WIECHA_AT (their bboxes)
    (-879.0, 144.0, -840.0, 219.0),
    (-835.0, 215.0, -818.0, 236.0),
    (-854.0, 167.0, -805.0, 197.0),
    (-823.0, 291.0, -777.0, 344.0),
    # Osiedle Za Żelazną Bramą (landmarks.gd _find_zelazna): eleven unnamed blocks, bboxes of
    # the outlines under ZELAZNA_AT
    (-2099.0, 285.0, -2070.0, 326.0),
    (-2046.0, 267.0, -2017.0, 307.0),
    (-1993.0, 249.0, -1964.0, 288.0),
    (-1940.0, 230.0, -1909.0, 270.0),
    (-2062.0, 320.0, -2031.0, 361.0),
    (-2032.0, 297.0, -1962.0, 352.0),
    (-1872.0, 300.0, -1851.0, 334.0),
    (-1873.0, 244.0, -1852.0, 278.0),
    (-1858.0, 202.0, -1837.0, 236.0),
    (-1889.0, 361.0, -1864.0, 409.0),
    (-1858.0, 350.0, -1832.0, 395.0),
    # Pokorna 2 (landmarks.gd _find_pokorna2): the 57 m residential block, found by the outline under POKORNA2_AT
    (-2141.0, -2234.0, -2105.0, -2198.0),
    # Kino Muranów (landmarks.gd _find_kino_muranow): the cinema pavilion's outline under KM_AT
    (-1700.0, -1240.0, -1640.0, -1170.0),
    (-450.0, 1580.0, -385.0, 1670.0),       # Kościół Zbawiciela's nave and towers (landmarks.gd ZB_*; MDM's box ends at z 1620)
    # the church kit (landmarks.gd CHURCHES): the outline under each church's `at` point
    (-853, -1629, -749, -1525),   # church_sw_marcin
    (-1019, -1461, -938, -1380),   # church_kapucyni
    (-676, -1276, -610, -1210),   # church_niepokalanego
    (-1210, -1693, -1121, -1604),   # church_katedra_polowa
    (-1060, -1881, -968, -1789),   # church_duch
    (-1048, -1993, -930, -1875),   # church_jacek
    (-1253, -1036, -1133, -916),   # church_antoniego
    (-1120, -1173, -1029, -1082),   # church_alberta
    (-1805, -1165, -1706, -1066),   # church_reformowany
    (936, 1286, 1031, 1381),   # church_jerozolimska
    (-1942, 276, -1846, 373),   # church_zielonoswiatkowy
    (-1869, 936, -1784, 1021),   # church_dzieciatka
    (-2007, -1014, -1926, -933),   # church_narodzenia
    (-2191, -510, -2100, -419),   # church_karol
    (-2478, -1240, -2362, -1124),   # church_augustyn
    (-2792, -733, -2704, -645),   # church_miloserdzie
    (-1172, 772, -1064, 879),   # church_piotr_pawel
    (1023, 229, 1102, 308),   # church_trojca_praga
    (1081, 813, 1173, 906),   # church_czestochowska
    (1914, -1434, 2018, -1330),   # church_zwycieska
    (-1058, -1559, -985, -1487),   # church_cerkiew
    (-1609, -268, -1529, -188),   # church_nozykow
    (1575.0, 1570.0, 1605.0, 1610.0),       # the sailing marina's club house (landmarks.gd MARINA_AT, unnamed in OSM)
    (1385.0, 670.0, 1480.0, 900.0),         # Port Czerniakowski's spit: Majami, WTW and the halls (landmarks.gd PORT_TIP, PORT_WTW, PORT_HALLS)
    (1025.0, -2032.0, 1135.0, -1962.0),     # Bazar Różyckiego's stalls (landmarks.gd BAZAR_BOX, unnamed retail outlines)
]


def bbox_flat(flat):
    xs = flat[0::2]
    zs = flat[1::2]
    if not xs:
        return None
    return (min(xs), min(zs), max(xs), max(zs))


def extent(item, how):
    if how == "xz":
        return (item["x"], item["z"], item["x"], item["z"])
    if how == "c":
        c = item["c"]
        return (c[0], c[1], c[0], c[1])
    return bbox_flat(item.get(how, []))


class Grid:
    def __init__(self, bounds, shape=None):
        self.i0 = math.floor(bounds[0] / SECTOR)
        self.i1 = math.floor(bounds[2] / SECTOR)
        self.j0 = math.floor(bounds[1] / SECTOR)
        self.j1 = math.floor(bounds[3] / SECTOR)
        # Map north: the sectors that meet the map (grown by a ground cell: the 10 m grid's cells
        # on its edge reach past it); those wholly in a part left `outside` are no sectors.
        self.shape = shape
        self._keys = [(i, j) for j in range(self.j0, self.j1 + 1) for i in range(self.i0, self.i1 + 1)
                      if shape is None or shape.meets((i * SECTOR, j * SECTOR, (i + 1) * SECTOR, (j + 1) * SECTOR))]
        self._have = set(self._keys)

    def keys(self):
        return list(self._keys)

    def touching(self, box, margin):
        """Sectors whose square grown by `margin` meets the box (x0, z0, x1, z1)."""
        if box is None:
            return []
        i0 = max(self.i0, math.floor((box[0] - margin) / SECTOR))
        i1 = min(self.i1, math.floor((box[2] + margin) / SECTOR))
        j0 = max(self.j0, math.floor((box[1] - margin) / SECTOR))
        j1 = min(self.j1, math.floor((box[3] + margin) / SECTOR))
        return [(i, j) for j in range(j0, j1 + 1) for i in range(i0, i1 + 1) if (i, j) in self._have]


def carry_closure(buildings, footprints, chosen, fp_chosen):
    """Per sector, add what could carry a floating part (map_builder.gd _part_bottoms): every
    part and LoD2 footprint whose box meets the box (grown by FLOAT_SLACK) of a part in the
    sector that starts FLOAT_MIN or more up, until nothing more comes in."""
    boxes = [bbox_flat(b["p"]) for b in buildings]
    fp_boxes = [bbox_flat(fp) for fp in footprints]

    def meets(a, b):
        return a is not None and b is not None and a[0] <= b[2] and b[0] <= a[2] and a[1] <= b[3] and b[1] <= a[3]

    high = [i for i, b in enumerate(buildings) if float(b.get("mh", 0)) >= FLOAT_MIN and boxes[i] is not None]
    under = {}
    for i in high:
        g = (boxes[i][0] - FLOAT_SLACK, boxes[i][1] - FLOAT_SLACK, boxes[i][2] + FLOAT_SLACK, boxes[i][3] + FLOAT_SLACK)
        under[i] = ([j for j, b in enumerate(boxes) if j != i and meets(g, b)],
                    [j for j, b in enumerate(fp_boxes) if meets(g, b)])
    added = 0
    for k, members in chosen.items():
        todo = [i for i in members if i in under]
        while todo:
            i = todo.pop()
            parts, fps = under[i]
            for j in parts:
                if j not in members:
                    members.add(j)
                    added += 1
                    if j in under:
                        todo.append(j)
            fp_chosen[k].update(fps)
    return added


class BoxIndex:
    """Boxes (x0, z0, x1, z1) in CELL-metre cells, for 'which boxes meet this one'."""
    CELL = 64.0

    def __init__(self, boxes):
        self.boxes = boxes
        self.cells = {}
        for i, b in enumerate(boxes):
            if b is None:
                continue
            for c in self._cells(b):
                self.cells.setdefault(c, []).append(i)

    def _cells(self, b):
        for cz in range(math.floor(b[1] / self.CELL), math.floor(b[3] / self.CELL) + 1):
            for cx in range(math.floor(b[0] / self.CELL), math.floor(b[2] / self.CELL) + 1):
                yield (cx, cz)

    def meeting(self, b):
        out = set()
        for c in self._cells(b):
            for i in self.cells.get(c, ()):
                o = self.boxes[i]
                if o[0] <= b[2] and b[0] <= o[2] and o[1] <= b[3] and b[1] <= o[3]:
                    out.add(i)
        return out


def grow(b, r):
    return (b[0] - r, b[1] - r, b[2] + r, b[3] + r)


def sign_context(data, footprints, chosen, fp_chosen, grid):
    """Shop signs (map_builder.gd _build_neon): a building picks the longest of all its walls
    with a street ahead (up to ~33 m off) and nothing built 4.5 m in front of it, so each of a
    sector's buildings brings the roads within SIGN_STREET of it and the buildings and LoD2
    footprints within SIGN_FRONT, however far it reaches out of the sector. Returns per sector
    the box of all that (the builder also builds the landmarks in it, for their roofs)."""
    buildings = data.get("buildings", [])
    bboxes = [bbox_flat(b["p"]) for b in buildings]
    roads = BoxIndex([bbox_flat(r["p"]) for r in data.get("roads", [])])
    parts = BoxIndex(bboxes)
    fps = BoxIndex([bbox_flat(fp) for fp in footprints])
    contexts = {}
    for k, members in chosen["buildings"].items():
        box = (k[0] * SECTOR - MARGIN, k[1] * SECTOR - MARGIN, (k[0] + 1) * SECTOR + MARGIN, (k[1] + 1) * SECTOR + MARGIN)
        for i in list(members):
            b = bboxes[i]
            if b is None:
                continue
            chosen["roads"][k] |= roads.meeting(grow(b, SIGN_STREET))
            members |= parts.meeting(grow(b, SIGN_FRONT))
            fp_chosen[k] |= fps.meeting(grow(b, SIGN_FRONT))
            g = grow(b, SIGN_STREET)
            box = (min(box[0], g[0]), min(box[1], g[1]), max(box[2], g[2]), max(box[3], g[3]))
        contexts[k] = box
    return contexts


def name(key):
    return "%d_%d" % key


def lod2_runs(f, n):
    """The builder's buildings in lod2.bin: runs of triangles sharing a style seed (UV2.x),
    each within 300 m of its first vertex (map_builder.gd _build_lod2 / _clip_lod2)."""
    o_u2 = n * 12
    runs = []
    near = 0
    t0 = 0
    while t0 < n:
        seed = f[o_u2 + t0 * 2]
        fx, fz = f[t0 * 3], f[t0 * 3 + 2]
        t1 = t0
        while t1 < n and f[o_u2 + t1 * 2] == seed:
            d = math.hypot(f[t1 * 3] - fx, f[t1 * 3 + 2] - fz)
            if abs(d - 300.0) < 0.01:
                near += 1
            if d >= 300.0:
                break
            t1 += 3
        runs.append((t0, t1))
        t0 = t1
    return runs, near


def reach(bounds, map_dir):
    """Loop 3d-1: the rectangle the builder may draw in: the map's bounds grown by the 6 m a
    building may hang over the edge (bake_osm.py) and the terrain grid's extent (the demo box's
    grid reaches 4 m past its north edge, which lies 2.4 m inside sector row -4: ground and
    buildings there were in no sector, check_streaming's identity)."""
    x0, z0, x1, z1 = bounds[0] - BUILDING_SLACK, bounds[1] - BUILDING_SLACK, bounds[2] + BUILDING_SLACK, bounds[3] + BUILDING_SLACK
    tp = os.path.join(map_dir, "terrain.json")
    if os.path.exists(tp):
        with open(tp) as fh:
            t = json.load(fh)
        x0, z0 = min(x0, t["x0"]), min(z0, t["z0"])
        x1, z1 = max(x1, t["x0"] + (t["nx"] - 1) * t["step"]), max(z1, t["z0"] + (t["nz"] - 1) * t["step"])
    return [x0, z0, x1, z1]


def main(map_dir):
    with open(os.path.join(map_dir, "centrum.json"), encoding="utf-8") as fh:
        data = json.load(fh)
    shape = map_shape.of(data)
    grid = Grid(reach(data["bounds"], map_dir), shape.grow(GROUND_CELL) if shape.outside else None)
    keys = grid.keys()
    sectors = {k: {"sector": list(k)} for k in keys}
    counts = {k: 0 for k in keys}

    keep = None
    footprints = []
    meta_path = os.path.join(map_dir, "lod2.json")
    if os.path.exists(meta_path):
        with open(meta_path, encoding="utf-8") as fh:
            meta = json.load(fh)
        keep = set(meta.get("keep_osm", []))
        footprints = meta.get("footprints", [])

    chosen = {}
    for key, how in SECTOR_LISTS.items():
        chosen[key] = {k: set() for k in keys}
        for index, item in enumerate(data.get(key, [])):
            for k in grid.touching(extent(item, how), MARGIN):
                chosen[key][k].add(index)
    fp_chosen = {k: set() for k in keys}
    for index, fp in enumerate(footprints):
        for k in grid.touching(bbox_flat(fp), MARGIN):
            fp_chosen[k].add(index)
    carry_closure(data.get("buildings", []), footprints, chosen["buildings"], fp_chosen)
    contexts = sign_context(data, footprints, chosen, fp_chosen, grid)
    carry_closure(data.get("buildings", []), footprints, chosen["buildings"], fp_chosen)
    for key in SECTOR_LISTS:
        items = data.get(key, [])
        for k in keys:
            out = []
            for index in sorted(chosen[key][k]):
                item = items[index]
                if key == "buildings" and keep is not None and index in keep:
                    item = dict(item)
                    item["keep"] = 1
                out.append(item)
            sectors[k][key] = out
            counts[k] += len(out)

    for key, stride in SECTOR_POINTS.items():
        for s in sectors.values():
            s[key] = []
        flat = data.get(key, [])
        for i in range(0, len(flat) - stride + 1, stride):
            x, z = flat[i], flat[i + 1]
            for k in grid.touching((x, z, x, z), POINT_MARGIN):
                sectors[k][key].extend(flat[i:i + stride])
                counts[k] += 1

    # The scanned trees and their crown scales, one scale per tree, kept in step.
    real = data.get("trees3d", [])
    crowns = data.get("trees3d_crown", [])
    for s in sectors.values():
        s["trees3d"] = []
        s["trees3d_crown"] = []
    for i in range(0, len(real) - 5, 6):
        x, z = real[i], real[i + 1]
        for k in grid.touching((x, z, x, z), POINT_MARGIN):
            sectors[k]["trees3d"].extend(real[i:i + 6])
            if i // 6 < len(crowns):
                sectors[k]["trees3d_crown"].append(crowns[i // 6])
            counts[k] += 1

    # Structures: the deck piers, the tunnels' portal frames and roads (their heights stay global).
    for s in sectors.values():
        s["decks"] = {"piers": []}
        s["tunnels"] = {"frames": [], "roads": []}
        s["lod2_footprints"] = []
        for key in SECTOR_WHOLE:
            s[key] = data.get(key, [])
    for p in data.get("decks", {}).get("piers", []):
        c = p["c"]
        for k in grid.touching((c[0], c[1], c[0], c[1]), MARGIN):
            sectors[k]["decks"]["piers"].append(p)
    for f in data.get("tunnels", {}).get("frames", []):
        c = f["c"]
        for k in grid.touching((c[0], c[1], c[0], c[1]), MARGIN):
            sectors[k]["tunnels"]["frames"].append(f)
    for r in data.get("tunnels", {}).get("roads", []):
        for k in grid.touching(bbox_flat(r["p"]), MARGIN):
            sectors[k]["tunnels"]["roads"].append(r)
    for k in keys:
        sectors[k]["lod2_footprints"] = [footprints[i] for i in sorted(fp_chosen[k])]
        sectors[k]["context"] = [round(v, 2) for v in contexts[k]]

    # LoD2: whole buildings (runs) to every sector they come near, as vertex ranges of lod2.bin.
    lod_counts = {k: 0 for k in keys}
    for s in sectors.values():
        s["lod2_runs"] = []
    bin_path = os.path.join(map_dir, "lod2.bin")
    if os.path.exists(bin_path):
        with open(bin_path, "rb") as fh:
            raw = fh.read()
        n = struct.unpack("<I", raw[:4])[0]
        f = array("f")
        f.frombytes(raw[4:4 + n * 14 * 4])
        runs, near = lod2_runs(f, n)
        if near:
            print("bake_sectors: warning: %d LoD2 triangles start ~300 m from their building's "
                  "first vertex (float rounding could split them differently in Godot)" % near)
        run_boxes = []
        for t0, t1 in runs:
            xs = f[t0 * 3:t1 * 3:3]
            zs = f[t0 * 3 + 2:t1 * 3:3]
            run_boxes.append((min(xs), min(zs), max(xs), max(zs)))
        per = {k: set() for k in keys}
        for r, b in enumerate(run_boxes):
            for k in grid.touching(b, MARGIN):
                per[k].add(r)
        # ...and the ones in front of a sector's buildings' walls (their roofs: sign_context).
        index = BoxIndex(run_boxes)
        bboxes = [bbox_flat(b["p"]) for b in data.get("buildings", [])]
        for k in keys:
            for i in chosen["buildings"][k]:
                if bboxes[i] is not None:
                    per[k] |= index.meeting(grow(bboxes[i], SIGN_FRONT))
        for k in keys:
            for r in sorted(per[k]):
                sectors[k]["lod2_runs"].extend(list(runs[r]))
                lod_counts[k] += 1

    out_dir = os.path.join(map_dir, "sectors")
    os.makedirs(out_dir, exist_ok=True)
    for old in os.listdir(out_dir):
        if old.endswith(".json"):
            os.remove(os.path.join(out_dir, old))

    sizes = {}
    for k, s in sectors.items():
        path = os.path.join(out_dir, name(k) + ".json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(s, fh, separators=(",", ":"), ensure_ascii=False)
        sizes[k] = os.path.getsize(path)

    index = {key: value for key, value in data.items() if key not in SECTOR_ONLY}
    # The parts landmarks.gd finds its sites in (see SITE_AREAS).
    named = []
    for lm in data.get("landmarks", []):
        if lm["name"] not in SITE_NAMES:
            continue
        b = bbox_flat(lm["p"])
        if b:
            named.append((b[0] - SITE_PAD, b[1] - SITE_PAD, b[2] + SITE_PAD, b[3] + SITE_PAD))
    site_parts = []
    for bld in data.get("buildings", []):
        p = bld["p"]
        if len(p) < 6:
            continue
        cx = sum(p[0::2]) / (len(p) // 2)
        cz = sum(p[1::2]) / (len(p) // 2)
        # The river's barges and houseboats (landmarks.gd _find_barges reads them by kind).
        if bld.get("kind") in SITE_KINDS or any(a[0] <= cx <= a[2] and a[1] <= cz <= a[3] for a in named + SITE_AREAS):
            site_parts.append(bld)
    index["site_parts"] = site_parts
    index["sectors"] = {"size": SECTOR, "margin": MARGIN, "point_margin": POINT_MARGIN,
                        "i": [grid.i0, grid.i1], "j": [grid.j0, grid.j1],
                        "keys": [list(k) for k in keys]}
    with open(os.path.join(map_dir, "index.json"), "w", encoding="utf-8") as fh:
        json.dump(index, fh, separators=(",", ":"), ensure_ascii=False)

    with open(os.path.join(out_dir, "split.stamp"), "w", encoding="utf-8") as fh:
        json.dump(split_stamp(map_dir), fh, indent=1, sort_keys=True)

    total = sum(sizes.values())
    print("bake_sectors: %d sectors of %d m (i %d..%d, j %d..%d), margin %d m (points %d m)" % (
        len(keys), SECTOR, grid.i0, grid.i1, grid.j0, grid.j1, MARGIN, POINT_MARGIN))
    print("bake_sectors: index.json %.2f MB (%d site parts), sector files %.2f MB (largest %s %.2f MB)" % (
        os.path.getsize(os.path.join(map_dir, "index.json")) / 1e6, len(site_parts), total / 1e6,
        name(max(sizes, key=sizes.get)), max(sizes.values()) / 1e6))
    for k in keys:
        print("  %-6s %6d features %6.2f MB  %4d LoD2 buildings" % (name(k), counts[k], sizes[k] / 1e6, lod_counts[k]))
    return 0


def sha256_file(path):
    """The file's SHA-256 (hex), or "" when it isn't there."""
    if not os.path.exists(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def split_stamp(map_dir):
    """Loop 3d-1: the inputs' hashes and one digest over them (the prebuilt city's stamp
    records the digest, so a new split makes the prebuilt sectors stale too)."""
    inputs = {f: sha256_file(os.path.join(map_dir, f)) for f in SPLIT_INPUTS}
    inputs["bake_sectors.py"] = sha256_file(os.path.abspath(__file__))
    digest = hashlib.sha256("".join("%s=%s\n" % kv for kv in sorted(inputs.items())).encode()).hexdigest()
    return {"inputs": inputs, "digest": digest}


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "game", "map")))
