"""Monuments and plaques from OpenStreetMap (docs/CITY_INVENTORY.md Part 3 item 6, rows 142 and 144).

    python3 -I tools/bake_monuments.py [MAP.json] [--osm=FILE] [--out=FILE]

Reads the OpenStreetMap candidate cache (default docs/inventory/osm_candidates.json, tracked, made
by tools/city_list.py --fetch on the Mac) and the finished map data (default game/map/centrum.json)
and writes game/data/monuments.json:

    {"_about", "src": <sha1 of the OSM points used>, "kinds": [...],
     "items": [[kind, x, z, yaw, colour, name], ...]}

Every named memorial, statue, bust, stone, stele, obelisk, cross, sculpture and talking bench
(ławeczka) in the map's box becomes a small generic piece (game/scripts/monuments.gd builds them,
in park_details.gd's per-cell meshes), and every memorial plaque (Tchorek's Uprising plaques and
the others) a sandstone plaque on the nearest wall the game draws (game/map/lod2.json's LoD2 footprints
and the OSM outlines it keeps, so the map pack is needed) with candles below it. Murals, reliefs, neons,
installations and pavement plaques are left out (row 143 is its own pass). The places a hand-built
model already stands (SKIP: Sigismund's Column, the Mermaids, Mickiewicz, Prus, Wyszyński,
Poniatowski, Copernicus, de Gaulle, the Unknown Soldier, Ali's stone, the Palm, and since part 2 Nike,
Słowacki, Starzyński, Mały Powstaniec, Kiliński, Umschlagplatz and the Eastern memorial) and the two
monuments other threads own (Pomnik Powstania Warszawskiego, the Ghetto Heroes) are skipped with a
radius. Ogród Saski's allegories (unmemorial sandstone statues inside the garden) become `allegory`.

`yaw` follows street_details: Basis(UP, yaw) turns +z away from the nearest road (or into the wall
for a plaque), so the -z front faces the street. A piece that falls on a road, in a building or in
water moves to the nearest free spot within SNAP m, or is dropped. `src` hashes only the OSM points,
so a map re-bake does not make the file stale; tools/check_monuments.py checks the placement
against today's map. Deterministic. Standard library only.
"""
import hashlib
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as P  # noqa: E402

OUT = os.path.join(ROOT, "game", "data", "monuments.json")
OSM = os.path.join(ROOT, "docs", "inventory", "osm_candidates.json")
LAT0, LON0 = 52.2340, 21.0240  # the map's origin (bake_osm.ORIGIN)
M_LAT = 110574.0
M_LON = 111320.0 * math.cos(math.radians(LAT0))
KINDS = ["statue", "bust", "allegory", "stone", "stele", "obelisk", "cross", "sculpture", "bench", "plaque"]
RADIUS = {"statue": 1.3, "bust": 0.5, "allegory": 0.6, "stone": 0.7, "stele": 0.6, "obelisk": 1.0,
          "cross": 0.8, "sculpture": 0.9, "bench": 1.0, "plaque": 0.0}
MAX_ITEMS = 1200
SNAP = 8.0          # a free-standing piece moves at most this far off a road or a building
WALL = 12.0         # a plaque looks for a wall this close
PLAQUE_GAP = 1.2    # plaques on one wall stand at least this far apart

BRONZE = "#4a4f46"
GRANITE = "#8f8b85"
STONE = "#c9c0aa"
SANDSTONE = "#cfc3a6"
METAL = "#8c9196"
WOOD = "#7a5a3a"

# [name (substring), x, z, radius]: hand-built models stand here, or another thread owns the place.
SKIP = [
    ("Kolumna Zygmunta", -724.0, -1465.0, 20.0),
    ("Syrena", 551.0, -692.0, 60.0),                  # the riverside Mermaid (site syrenka_powisle)
    ("Syrenka Warszawska", -806.5, -1745.5, 10.0),    # the Old Town Mermaid (site syrenka)
    ("Adam Mickiewicz", -626.6, -1073.6, 15.0),
    ("Bolesław Prus", -519.7, -860.3, 15.0),
    ("Stefan Wyszyński", -503.0, -792.6, 15.0),
    ("Józef Poniatowski", -582.0, -973.0, 30.0),      # before the Presidential Palace (site prezydencki)
    ("Mikołaj Kopernik", -411.0, -460.0, 30.0),       # before Pałac Staszica (site staszic)
    ("Charles de Gaulle", -171.0, 273.0, 15.0),
    ("Grób Nieznanego Żołnierza", -865.75, -768.7, 20.0),
    # Plac Piłsudskiego from photos (2026-11-02): sites smolensk, pilsudski, kaczynski
    ("Pomnik Ofiar Tragedii Smoleńskiej", -763.0, -736.5, 12.0),
    ("Józef Piłsudski", -673.3, -817.8, 10.0),
    ("Lech Kaczyński", -671.3, -762.7, 10.0),
    ("August Agboola Browne", -846.0, 228.0, 15.0),   # Ali's stone (first_scene.gd)
    ("Palma", -214.0, 237.0, 15.0),
    ("", -1233.0, -1700.0, 45.0),                     # Pomnik Powstania Warszawskiego: its own thread
    ("", -2030.0, -1741.0, 35.0),                     # Pomnik Bohaterów Getta: the POLIN thread
    # The monuments pass, part 2 (2026-11-02): photo builds in landmarks.gd from the Mac's
    # docs/landmarks/photo-reports/ (sites nike, slowacki, starzynski, maly_powstaniec, kilinski,
    # umschlagplatz, pomnik_wschod).
    ("Warszawska Nike", -1010.0, -1317.0, 8.0),
    ("Juliusz Słowacki", -1480.0, -978.0, 10.0),
    ("Stefan Starzyński", -1499.0, -1101.0, 8.0),
    ("Mały Powstaniec", -981.0, -1689.0, 8.0),
    ("Jan Kiliński", -896.0, -1573.0, 8.0),
    ("Umschlagplatz", -2382.0, -2020.0, 10.0),
    ("Poległym i Pomordowanym na Wschodzie", -1718.0, -2183.0, 25.0),
]
# Still generic until their photo builds land and join SKIP: docs/CITY_INVENTORY.md rows 113-116.
SAXON = (-1125.2, -691.8)   # a point in Ogród Saski (bake_park_details.PARKS)


def project(lat, lon):
    return ((lon - LON0) * M_LON, (LAT0 - lat) * M_LAT)


def kind_of(t):
    """The generic piece for an OSM object's tags, or None to leave it out."""
    mem = t.get("memorial")
    art = t.get("artwork_type")
    if mem in ("plaque", "blue_plaque"):
        return "plaque"
    if mem in ("stolperstein", "pavement_plaque", "bell", "oak", "tree"):
        return None
    if art in ("mural", "graffiti", "relief", "mosaic", "neon", "tree", "dwarf", "architecture", "installation"):
        return None
    if mem == "bench" or "ławeczka" in t.get("name", "").lower():
        return "bench"
    if mem == "bust" or art == "bust":
        return "bust"
    if mem == "stone":
        return "stone"
    if mem in ("stele", "war_memorial") or (mem is None and t.get("historic") == "memorial"):
        return "stele"
    if mem == "obelisk":
        return "obelisk"
    if mem == "cross":
        return "cross"
    if mem == "sculpture" or art == "sculpture":
        return "sculpture"
    if mem == "statue" or art == "statue" or t.get("historic") == "monument":
        return "statue"
    if t.get("tourism") == "artwork" and art is None:
        return "sculpture"
    if mem is not None:
        return "stele"
    return None


def colour_of(kind, t):
    mat = t.get("material", "")
    if kind in ("stone", "stele", "obelisk"):
        return GRANITE if mat in ("", "granite", "stone") else STONE
    if kind == "allegory":
        return SANDSTONE
    if kind == "plaque":
        return SANDSTONE
    if kind == "cross":
        return WOOD if mat == "wood" else STONE
    if kind == "sculpture":
        return METAL if mat in ("metal", "stainless_steel", "steel", "cast_iron") else (BRONZE if mat == "bronze" else STONE)
    if kind == "statue" and mat in ("stone", "sandstone", "limestone", "marble"):
        return SANDSTONE
    return BRONZE


def points(osm):
    """[kind, x, z, name, tags] for every OSM object the bake keeps (ways and relations by their centre)."""
    out = []
    seen = set()
    for e in json.load(open(osm))["elements"]:
        t = e.get("tags", {})
        if not ("memorial" in t or t.get("historic") in ("memorial", "monument") or t.get("tourism") == "artwork"):
            continue
        if t.get("historic") in ("wayside_shrine", "wayside_cross", "boundary_stone") and "memorial" not in t:
            continue
        kind = kind_of(t)
        if kind is None:
            continue
        lat = e.get("lat", e.get("center", {}).get("lat"))
        lon = e.get("lon", e.get("center", {}).get("lon"))
        if lat is None:
            continue
        x, z = project(lat, lon)
        name = t.get("name", "")
        key = (name, round(x / 4.0), round(z / 4.0))
        if name and key in seen:   # the node and the way of one monument
            continue
        seen.add(key)
        out.append([kind, x, z, name, t, e["type"] + str(e["id"])])
    out.sort(key=lambda p: p[5])
    return out


def src_hash(pts):
    h = hashlib.sha1()
    for kind, x, z, name, _t, oid in pts:
        h.update(("%s|%s|%.1f|%.1f|%s\n" % (oid, kind, x, z, name)).encode("utf-8"))
    return h.hexdigest()


def skipped(name, x, z):
    for part, sx, sz, r in SKIP:
        if (part == "" or part in name) and math.hypot(x - sx, z - sz) < r:
            return True
    return False


def load_lod2():
    """game/map/lod2.json (the GUGiK LoD2 meta, from the map pack), or None when it is missing."""
    path = os.path.join(ROOT, "game", "map", "lod2.json")
    return json.load(open(path)) if os.path.exists(path) else None


class Baker:
    def __init__(self, data, lod2=None):
        self.data = data
        self.solids = P.Solids(data, lod2)
        self.items = []
        self.roads = [(P.pairs(r["p"]), r["w"]) for r in data["roads"]]
        # The walls the game draws: LoD2 footprints where GUGiK has the building, the OSM outlines it keeps.
        walls = [P.pairs(b["p"]) for b in data["buildings"]]
        if lod2:
            keep = set(lod2.get("keep_osm", []))
            walls = [w for i, w in enumerate(walls) if i in keep] + [P.pairs(fp) for fp in lod2.get("footprints", [])]
        self.buildings = []
        for pts in walls:
            xs = [q[0] for q in pts]
            zs = [q[1] for q in pts]
            self.buildings.append((pts, min(xs), max(xs), min(zs), max(zs)))
        self.saski = None
        for a in data["areas"]:
            pts = P.pairs(a["p"])
            if a["k"] == "park" and P.point_in_poly(SAXON[0], SAXON[1], pts):
                if self.saski is None or len(pts) > len(self.saski):
                    self.saski = pts

    def face_road(self, x, z):
        """The yaw that turns the piece's -z front to the nearest road."""
        best = None
        for pts, _w in self.roads:
            if abs(pts[0][0] - x) > 400 and abs(pts[-1][0] - x) > 400:
                continue
            for a, b in zip(pts, pts[1:]):
                d = P.seg_dist(x, z, a, b)
                if best is None or d < best[0]:
                    best = (d, a, b)
        if best is None:
            return 0.0
        _d, a, b = best
        ax, az = b[0] - a[0], b[1] - a[1]
        ln2 = ax * ax + az * az or 1.0
        t = max(0.0, min(1.0, ((x - a[0]) * ax + (z - a[1]) * az) / ln2))
        cx, cz = a[0] + ax * t, a[1] + az * t
        return math.atan2(x - cx, z - cz)

    def free(self, kind, x, z):
        for o in self.items:
            if o[0] != "plaque" and abs(o[1] - x) < 6 and abs(o[2] - z) < 6 and \
                    math.hypot(o[1] - x, o[2] - z) < RADIUS[kind] + RADIUS[o[0]] + 0.2:
                return False
        return self.solids.blocked(x, z, RADIUS[kind], skip=("tree", "bench", "pole", "bin", "bike rack", "column")) is None

    def snap(self, kind, x, z):
        for r in [0.0] + [0.75 * k for k in range(1, int(SNAP / 0.75) + 1)]:
            for k in range(1 if r == 0 else 16):
                a = k * math.tau / 16
                px, pz = x + math.cos(a) * r, z + math.sin(a) * r
                if self.free(kind, px, pz):
                    return px, pz
        return None

    def wall(self, x, z):
        """(px, pz, yaw) on the nearest building wall within WALL m, +z into the wall."""
        best = None
        for pts, x0, x1, z0, z1 in self.buildings:
            if x < x0 - WALL or x > x1 + WALL or z < z0 - WALL or z > z1 + WALL:
                continue
            for a, b in zip(pts, pts[1:] + pts[:1]):
                if abs(b[0] - a[0]) + abs(b[1] - a[1]) < 1.5:   # a plaque needs a wall at least this long
                    continue
                d = P.seg_dist(x, z, a, b)
                if d < WALL and (best is None or d < best[0]):
                    best = (d, a, b, pts)
        if best is None:
            return None
        _d, a, b, pts = best
        ax, az = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(ax, az)
        t = max(0.6 / ln, min(1.0 - 0.6 / ln, ((x - a[0]) * ax + (z - a[1]) * az) / (ln * ln)))
        cx, cz = a[0] + ax * t, a[1] + az * t
        nx, nz = az / ln, -ax / ln
        if P.point_in_poly(cx + nx * 0.4, cz + nz * 0.4, pts):
            nx, nz = -nx, -nz
        px, pz = cx + nx * 0.06, cz + nz * 0.06
        if self.solids.blocked(px + nx * 0.4, pz + nz * 0.4, 0.2, skip=("tree", "bench", "pole", "bin", "bike rack",
                                                                           "column", "building", "parked car")) in (
                "water", "rail", "map edge"):
            return None
        return px, pz, math.atan2(-nx, -nz)

    def put(self, kind, x, z, yaw, colour, name):
        self.items.append([kind, round(x, 2), round(z, 2), round(yaw, 3), colour, name])

    def run(self, pts):
        dropped = {}
        for kind, x, z, name, t, _oid in pts:
            if not self.solids.shape.contains(x, z) or self.solids.shape.rim(x, z) < 4.0 or skipped(name, x, z):
                continue
            if len(self.items) >= MAX_ITEMS:
                break
            if kind == "plaque":
                w = self.wall(x, z)
                if w is None or any(o[0] == "plaque" and math.hypot(o[1] - w[0], o[2] - w[1]) < PLAQUE_GAP for o in self.items):
                    dropped[kind] = dropped.get(kind, 0) + 1
                    continue
                self.put(kind, w[0], w[1], w[2], colour_of(kind, t), name)
                continue
            if kind == "statue" and "memorial" not in t and self.saski and P.point_in_poly(x, z, self.saski):
                kind = "allegory"
            spot = self.snap(kind, x, z)
            if spot is None:
                dropped[kind] = dropped.get(kind, 0) + 1
                continue
            self.put(kind, spot[0], spot[1], self.face_road(spot[0], spot[1]), colour_of(kind, t), name)
        return dropped


def main(argv):
    src = os.path.join(ROOT, "game", "map", "centrum.json")
    osm, out = OSM, OUT
    for a in argv:
        if a.startswith("--out="):
            out = a[6:]
        elif a.startswith("--osm="):
            osm = a[6:]
        elif not a.startswith("--"):
            src = a
    data = json.load(open(src))
    lod2 = load_lod2()
    if lod2 is None:
        sys.exit("bake_monuments: game/map/lod2.json is missing (python3 -I tools/map_pack.py fetch): plaques need the walls the game draws")
    pts = points(osm)
    b = Baker(data, lod2)
    dropped = b.run(pts)
    counts = {}
    for it in b.items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    doc = {"_about": "Monuments and plaques: tools/bake_monuments.py from docs/inventory/osm_candidates.json",
           "src": src_hash(pts), "kinds": KINDS, "items": b.items}
    with open(out, "w") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    print("bake_monuments: %d items %s, dropped %s" % (len(b.items), json.dumps(counts, sort_keys=True),
                                                       json.dumps(dropped, sort_keys=True)))


if __name__ == "__main__":
    main(sys.argv[1:])
