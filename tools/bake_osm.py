"""Bake an Overpass JSON export into the compact map file the game loads.

Usage: python3 -I tools/bake_osm.py data/raw/osm_centrum.json data/raw/osm_trees.json game/map/centrum.json [data/raw/osm_extras.json]

Everything is clipped to the bounding box, so the map ends in a clean edge.

Coordinates are metres on a local flat projection: +x east, +z south
(Godot's -Z is north), origin at ORIGIN (52.2340 N 21.0240 E; loop 3d-1: no longer the box's centre).
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cycleways  # noqa: E402  (cycle paths: gaps closed, split ways joined, corners smoothed)
import bake_roads  # noqa: E402  (v0.75: carriageways, decks, markings, kerbs)
from map_shape import Shape  # noqa: E402  (map north: the box with its north extension)
import stairs  # noqa: E402  (stairs across the city: OSM stair tags)
import barrier_tags  # noqa: E402  (walls, fences, hedges: heights, materials; the city walls)

# Loop 3d-1: the demo box (docs/DEMO.md 2.1, the user's decision 2026-10-29): Rondo Daszyńskiego
# to past the stadium and Most Łazienkowski, MDM to just past the Barbakan, 5,318 × 3,782 m =
# 20.1 km² (the east edge 21.050 → 21.056, the user's yes, loop 3d-1). Until loop 3c it was
# (52.2260, 20.9980, 52.2420, 21.0500), Śródmieście to the stadium.
BBOX = (52.2183, 20.9780, 52.2525, 21.0560)  # south, west, north, east (loop 3d-1: east 21.050 -> 21.056, the user's yes: Most Łazienkowski whole)
# The origin is no longer the box's centre: it stays where the first box had it, so every
# hard-coded map coordinate (GUGIK_NOT_TREES, EXTRA_KEBAB, the allowlists, landmark search boxes,
# police traps, test spots, README) keeps meaning the same place. The flat projection's error at
# the far corners is under 2 m.
ORIGIN = (52.2340, 21.0240)
LAT0, LON0 = ORIGIN
M_PER_DEG_LAT = 110574.0
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(LAT0))
# Map north (2026-10-31, the user's ask: Rondo Radosława with its flag, Arkadia and the Forest
# tower): the map grows north on its west side only, by this box on top of BBOX's north edge
# (south, west, north, east). North 52.2591 (z -2,775) is Arkadia's outline (52.2587) and its ring
# road Kłopot (z -2,755) + 20 m, short of the ring railway and Dworzec Gdański's platforms, inside
# the demo fetch (52.2595); the viaducts of Jana Pawła II and Andersa over the railway end at
# z -2,850 and are cut at the edge (check_roads C6 allows the rim). The east edge is x -1,706.12,
# a column of the 10 m terrain lattice (so the ground stops there cell by cell), east of Andersa
# (x -1,790 to -1,920), which closes the street net: Słomińskiego from the roundabout to Andersa,
# Andersa south into the old map. Everything east of it and north of BBOX stays off the map
# (centrum.json `outside`, tools/map_shape.py).
BBOX_NORTH = (BBOX[2], BBOX[1], 52.2591, LON0 - 1706.12 / M_PER_DEG_LON)

# Loop 3d-1: the demo box's inputs, prepared from data/raw (read-only) by tools/prepare_demo.py:
# the OSM export cut to the box, the aerial photo joined and cut, the 10 m grid cut, links to the
# LoD2 and tree sheets that meet the box, and bake_trees_gugik.py's output.
WORK = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "work", "demo"))
OSM_SRC = os.path.join(WORK, "osm_demo.json")
ORTHO = os.path.join(WORK, "ortho.bmp")
# Real trees from the GUGiK 2023 laser scan (tools/bake_trees_gugik.py), used where present.
GUGIK_TREES = os.path.join(WORK, "trees_area.json")


def ortho_box():
    """The aerial photo's own box (south, west, north, east): ortho.json, cut at whole pixels."""
    meta = os.path.join(WORK, "ortho.json")
    return tuple(json.load(open(meta))["bbox"]) if os.path.exists(meta) else HULL


# Map north: the boxes the map is made of, their bounding box (south, west, north, east) and the
# map in metres: a Shape (tools/map_shape.py), the bounding rectangle (x0, z0, x1, z1) with the
# corner that is not map in `outside`.
BOXES = [BBOX, BBOX_NORTH]
HULL = (min(b[0] for b in BOXES), min(b[1] for b in BOXES), max(b[2] for b in BOXES), max(b[3] for b in BOXES))


def map_shape():
    sw, ne = project(HULL[0], HULL[1]), project(HULL[2], HULL[3])
    hull = (sw[0], ne[1], ne[0], sw[1])
    nsw, nne = project(BBOX_NORTH[0], BBOX_NORTH[1]), project(BBOX_NORTH[2], BBOX_NORTH[3])
    msw, mne = project(BBOX[0], BBOX[1]), project(BBOX[2], BBOX[3])
    # The strip north of BBOX east of BBOX_NORTH (the extension shares BBOX's west edge).
    return Shape(hull, [(nne[0], hull[1], hull[2], mne[1])] if nne[0] < hull[2] else [])

# Laser-scan records that are not trees (loop 1): (x, z in map metres as trees_area.json has
# them, height, what it is). They are left out of trees3d; one marked "palm" is where the
# game's Palm stands (centrum.json "palm", eggs.gd).
GUGIK_NOT_TREES = [
    (-213.9, 238.5, 14.5, "palm",
     "the artificial palm on Rondo de Gaulle'a (Palma, about 15 m): scanned as a 14.5 m tree, crown 4 m"),
]

# Loop 3d-1 (docs/design/police.md 5.6 and 13): the pedestrian zones, where the player's car is
# capped at 20 km/h and the city guards keep watch (traffic never enters: highway=pedestrian is
# not in the lane graph). (id, x0, z0, x1, z1 in map metres, what it covers): inside each box
# every highway=pedestrian way (as a strip its width + PED_ZONE_PAD each side) and area, and
# every place=square, becomes a `ped_zones` polygon with that id.
PED_ZONES = [
    ("oldtown", -1180.0, -2046.0, -380.0, -1380.0,
     "the Old Town, the New Town's market and Freta, Plac Zamkowy, Krakowskie Przedmieście's car-free north end"),
]
PED_ZONE_PAD = 1.5
MERMAID_RIVER = 150.0   # loop 3d-1: a mapped Mermaid farther than this from the river isn't the egg's

# Where the car starts: Marszałkowska, east of the Palace of Culture.
SPAWN_LATLON = (52.2312, 21.0094)

DRIVABLE = {
    "motorway": 10.0, "trunk": 9.0, "primary": 8.0, "secondary": 7.5,
    "tertiary": 6.5, "unclassified": 5.5, "residential": 5.5,
    "living_street": 4.5, "service": 3.5,
    "motorway_link": 5.0, "trunk_link": 5.0, "primary_link": 5.0,
    "secondary_link": 5.0, "tertiary_link": 5.0,
}
PATHS = {"footway": 2.2, "pedestrian": 5.0, "path": 2.0, "cycleway": 2.0}
GREEN = {
    ("leisure", "park"): "park", ("leisure", "garden"): "park",
    ("landuse", "grass"): "grass", ("landuse", "recreation_ground"): "grass",
    ("landuse", "forest"): "park", ("natural", "wood"): "park",
    ("natural", "scrub"): "grass", ("leisure", "pitch"): "pitch",
    ("natural", "water"): "water",
}


def project(lat, lon):
    return ((lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT)


def num(value):
    if value is None:
        return None
    try:
        return float(str(value).split(";")[0].replace("m", "").replace(",", ".").strip())
    except ValueError:
        return None


def ring_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, z1 = pts[i]
        x2, z2 = pts[(i + 1) % len(pts)]
        a += x1 * z2 - x2 * z1
    return a / 2


def point_in_poly(x, z, pts):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, zi = pts[i]
        xj, zj = pts[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            inside = not inside
        j = i
    return inside


def centroid(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def in_bbox(lat, lon, pad=0.0):
    """Inside the map's boxes (map north: BBOX or BBOX_NORTH), grown by pad degrees."""
    for b in BOXES:
        if b[0] - pad <= lat <= b[2] + pad and b[1] - pad <= lon <= b[3] + pad:
            return True
    return False


def stitch(member_ways):
    """Join open member ways into closed rings (lists of node ids)."""
    rings, open_ = [], [list(w) for w in member_ways if w]
    while open_:
        cur = open_.pop(0)
        changed = True
        while cur[0] != cur[-1] and changed:
            changed = False
            for i, w in enumerate(open_):
                if w[0] == cur[-1]:
                    cur += w[1:]
                elif w[-1] == cur[-1]:
                    cur += w[-2::-1]
                elif w[-1] == cur[0]:
                    cur = w[:-1] + cur
                elif w[0] == cur[0]:
                    cur = w[:0:-1] + cur
                else:
                    continue
                open_.pop(i)
                changed = True
                break
        if cur[0] == cur[-1] and len(cur) >= 4:
            rings.append(cur)
    return rings


def flat(pts):
    out = []
    for x, z in pts:
        out += [round(x, 1), round(z, 1)]
    return out


def main(src, trees_src, dst, extras_src=None, more_src=None):
    els = json.load(open(src, encoding="utf-8"))["elements"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    ways = {e["id"]: e for e in els if e["type"] == "way"}

    def coords(ids):
        return [project(*nodes[i]) for i in ids if i in nodes]

    split_legs = bake_roads.mark_split_legs(ways, coords, DRIVABLE)
    print(f"widths (map review C): {split_legs} one-lane one-way legs of a split street kept one lane wide")

    def touches_bbox(ids):
        return any(i in nodes and in_bbox(*nodes[i]) for i in ids)

    roads, paths, trams, areas, buildings = [], [], [], [], []
    tunnel_roads = []  # loop 3a (R4): drivable tunnels, baked as tunnel pieces

    for w in ways.values():
        t = w.get("tags", {})
        ids = w.get("nodes", [])
        if len(ids) < 2 or not touches_bbox(ids):
            continue
        closed = ids[0] == ids[-1] and len(ids) >= 4
        hw = t.get("highway")
        underground = t.get("tunnel") in ("yes", "building_passage") or num(t.get("layer")) is not None and num(t.get("layer")) < 0

        bridge = t.get("bridge") not in (None, "no")
        layer = num(t.get("layer")) or (1 if bridge else 0)
        # Loop 3a (R4): a drivable tunnel is kept as a tunnel road (not drawn on the surface;
        # loop 3b builds it), a way below ground that is no tunnel (layer < 0: a cutting) is an
        # ordinary road. Building passages and service tunnels (garage interiors, R9) stay out.
        tunnel = t.get("tunnel") == "yes" and hw in DRIVABLE and hw != "service" and t.get("area") != "yes"
        if tunnel and is_passage(coords(ids)):
            continue  # loop 3b: a short "tunnel" under a building is a gate (a building passage)
        cutting = t.get("tunnel") in (None, "no") and num(t.get("layer")) is not None and num(t.get("layer")) < 0
        if hw in DRIVABLE and (not underground or cutting or tunnel) and t.get("area") != "yes":
            width = bake_roads.road_width(t)[0]
            lanes = num(t.get("lanes"))
            (tunnel_roads if tunnel else roads).append({
                "p": flat(coords(ids)), "w": round(width, 1), "k": hw,
                "oneway": t.get("oneway") == "yes", "lanes": int(lanes or 0),
                "name": t.get("name", ""),
                "bridge": bridge,
                "_id": w["id"], "_t": t, "_ly": layer,
            })
        elif hw in PATHS and not underground:
            if closed and (t.get("area") == "yes" or hw == "pedestrian"):
                areas.append({"p": flat(coords(ids[:-1])), "k": "plaza"})
            else:
                width = num(t.get("width")) or PATHS[hw]
                kind = "cycle" if hw == "cycleway" or t.get("bicycle") == "designated" and hw != "footway" else "foot"
                if t.get("footway") == "crossing" or (hw == "path" and "crossing" in t):
                    kind = "zebra"
                elif t.get("cycleway") == "crossing":
                    kind = "cyclecross"
                paths.append({"p": flat(coords(ids)), "w": round(min(width, 8.0), 1), "k": kind,
                              "_br": bridge and kind in ("foot", "cycle"), "_ly": layer})
        elif t.get("railway") == "tram" and not underground:
            trams.append({"p": flat(coords(ids)), "_br": bridge, "_ly": layer})

        if closed:
            for (key, val), kind in GREEN.items():
                if t.get(key) == val:
                    areas.append({"p": flat(coords(ids[:-1])), "k": kind})
                    break
            if ("building" in t or "building:part" in t) and t.get("building") != "roof" and not underground:
                buildings.append(make_building(t, coords(ids[:-1]), "building:part" in t))

    for r in (e for e in els if e["type"] == "relation"):
        t = r.get("tags", {})
        if t.get("type") != "multipolygon":
            continue
        outer = [ways[m["ref"]]["nodes"] for m in r.get("members", [])
                 if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways]
        for ring in stitch(outer):
            if not touches_bbox(ring):
                continue
            pts = coords(ring[:-1])
            if "building" in t or "building:part" in t:
                buildings.append(dict(make_building(t, pts, "building:part" in t), _mp=True))
            else:
                for (key, val), kind in GREEN.items():
                    if t.get(key) == val:
                        areas.append({"p": flat(pts), "k": kind})
                        break

    landmarks = [{"name": b["name"], "p": flat(b["_pts"])} for b in buildings if b["name"]]

    # A building outline that holds mapped parts is drawn through its parts instead.
    parts = [b for b in buildings if b["part"]]
    part_centres = [centroid(b["_pts"]) for b in parts]
    # Loop 3d-1: the part centres in 50 m cells (this was every outline against every part:
    # 100 s on the demo box).
    part_cells = {}
    for k, (cx, cz) in enumerate(part_centres):
        part_cells.setdefault((int(cx // 50), int(cz // 50)), []).append(k)

    def holds_part(pts):
        xs, zs = [q[0] for q in pts], [q[1] for q in pts]
        for gi in range(int(min(xs) // 50), int(max(xs) // 50) + 1):
            for gj in range(int(min(zs) // 50), int(max(zs) // 50) + 1):
                for k in part_cells.get((gi, gj), ()):
                    if point_in_poly(part_centres[k][0], part_centres[k][1], pts):
                        return True
        return False

    kept = []
    for b in buildings:
        if not b["part"] and holds_part(b["_pts"]):
            continue
        kept.append(b)
    for b in kept:
        b["p"] = flat(b.pop("_pts"))
        del b["part"]

    rect = map_shape()  # x0, z0, x1, z1 (map north: a Shape, the box and its north extension)
    roads, dropped_roof = roof_aisles(roads, buildings)
    paths, dropped_bridges = cut_footbridges(paths, roads, rect)
    print(f"map north: {dropped_roof} roof car park ways left out (a parking aisle on a building's roof, "
          f"mapped with no layer, and its ramps); {dropped_bridges} footbridge ways the map's edge cuts left out")
    roads = clip_lines(roads, rect)
    tunnel_roads = clip_lines(tunnel_roads, rect)
    roads, garages = garage_ramps(roads, os.path.join(os.path.dirname(os.path.abspath(dst)), "terrain.json"))
    paths = clip_lines(paths, rect)
    paths, cyc = cycleways.tidy(paths)   # gaps closed, split ways joined, spikes and sharp corners smoothed
    print(f"cycle paths tidied: {cyc}")
    trams = clip_lines(trams, rect)
    areas = [dict(a, p=flat(c)) for a in areas
             for c in [clip_polygon(list(zip(a["p"][0::2], a["p"][1::2])), rect)] if len(c) >= 3]
    # Buildings stay only if they don't hang over the edge of the map by more than a few metres.
    grown = rect.grow(6)
    kept = [b for b in kept if all(inside(grown, x, z) for x, z in zip(b["p"][0::2], b["p"][1::2]))]

    gugik = json.load(open(GUGIK_TREES)) if os.path.exists(GUGIK_TREES) else None
    trees, trees3d, not_trees = bake_trees(trees_src, areas, gugik)
    palm = next(([x, z] for x, z, kind in not_trees if kind == "palm"), None)
    details = bake_details(els, nodes, ways, more_src, roads, rect) if more_src else {}

    # v0.75: carriageway shapes and widths, bridge decks, kerbs, markings.
    bed = bake_roads.Roadbed(ways, nodes, project, in_bbox, clip_polygon, rect,
                             os.path.join(os.path.dirname(os.path.abspath(dst)), "terrain.json"),
                             roads, paths, trams, details, areas)
    # Loop 3b (R2): the scanned trees' crowns (the surface model sees them, not the deck) and
    # the small mapped buildings that are a viaduct's pillars.
    bed.set_trees(trees3d)
    bed.set_pillars(kept)
    bed.tunnel_roads = tunnel_roads   # loop 3e: their portals seed the ground profiles
    bed.solve_decks()
    bed.solve_tunnels(tunnel_roads)
    bed.fill_pits()
    bed.assign_levels()
    bed.level_surfaces(details.get("surfaces", []))
    bed.measure()
    bed.finish_roads()
    bed.set_corridors()
    bed.build_region()
    # Junction lines (2026-11-02): the medians first, so the short ones inside a junction, painted
    # (hatched) instead, are an edge line and no kerb to bake_edges.
    bed.bake_medians()
    bed.bake_edges()
    bed.bake_lane_lines()
    bed.bake_hatching()
    bed.clip_crossings()   # map review B (2026-10-29): zebras only on the asphalt
    bed.bake_guards(clip_lines)
    bed.bake_shore()
    # Loop 3b-2: which banks are built (the granite edge) and which natural (wet sand, foam),
    # the sand on land and the sandbars on the river (tools/bake_banks.py).
    import bake_banks
    banks = bake_banks.bake(bed, els, nodes, ways, project, in_bbox, clip_polygon, bed.land, stitch,
                            paths, roads, areas, details)
    # Loop 3b-2: the scanned crowns a road runs under are drawn at 3/4 of their size.
    crowns = crown_scales(trees3d, roads)

    extras = bake_extras(extras_src, roads, rect) if extras_src else {}
    bed.clear_poles(extras)   # map review B (2026-10-29): lamps and signal poles off the asphalt
    pois = bake_pois(els, nodes, ways, roads, paths, areas, rect)
    dry_pois(pois, areas, roads)
    ped_zones = bake_ped_zones(ways, nodes, rect)
    levels = {}   # loop 3a (R8): way id -> ("dk", deck group) or ("tn", tunnel)
    for r in roads:
        if r.get("dk", -1) >= 0:
            levels.setdefault(r["_id"], ("dk", r["dk"]))
    for r in tunnel_roads:
        levels.setdefault(r["_id"], ("tn", r["tn"]))
    graph = bake_graph(els, nodes, ways, rect, extras_src, extras.get("signals", []), bed, levels)
    # Loop 3b: a tunnel edge's ends that are portals (`po`: 1 its start, 2 its end): traffic
    # deeper inside than 15 m from a portal is hidden (traffic.gd).
    portals = bed.tunnel_json(tunnel_roads)["portals"]
    for e in graph["edges"]:
        if "tn" in e:
            ps = e["p"]
            po = 0
            for bit, (x, z) in ((1, (ps[0], ps[1])), (2, (ps[-2], ps[-1]))):
                if any(math.hypot(x - px, z - pz) < 12.0 for px, pz, _ in portals):
                    po |= bit
            e["po"] = po
    bed.bake_lane_marks(graph["edges"])
    for e in graph["edges"]:
        for k in [k for k in e if k.startswith("_")]:
            del e[k]
    markings = bed.edge_lines + bed.lane_lines + bed.lane_marks + bed.hatching
    # Map north (tools/check_outline.py O1): lines offset from a road clipped at the map's edge
    # (the lane and edge lines, the cycle lanes) ran up to 1.5 m past it, over nothing.
    markings = clip_lines(markings, rect)
    print("markings: " + ", ".join(f"{k} {sum(1 for m in markings if m['k'] == k)}" for k in sorted({m["k"] for m in markings})))
    for item in roads + paths + trams + details.get("rails", []) + details.get("islands", []) + details.get("surfaces", []):
        if item.get("dk", -1) < 0:
            item.pop("dk", None)
    for r in tunnel_roads:
        r["w"] = round(r["w"], 2)
    for r in roads:
        r["w"] = round(r["w"], 2)
        if r.get("c") == 0:
            del r["c"]

    sx, sz = project(*SPAWN_LATLON)
    spawn = nearest_road_point(roads, sx, sz)
    out = {
        "origin": [LAT0, LON0],
        "bounds": [round(v, 1) for v in rect],
        # Map north: the parts of the bounds that are not map (tools/map_shape.py; map_builder.gd).
        "outside": [[round(v, 1) if any(abs(v - b) < 1e-6 for b in rect) else round(v, 2) for v in o] for o in rect.outside],
        "spawn": spawn,
        "roads": roads, "paths": paths, "trams": trams, "areas": areas, "buildings": kept,
        "trees": trees, "trees3d": trees3d, "landmarks": landmarks, "markings": markings, "pois": pois,
        "graph": graph,
        "carriage": [_lv({"p": flat(c["p"]), "k": c["k"]}, c["dk"]) for c in bed.carriage + bed.hatch],
        "kerbs": [_lv({"p": k["p"]}, k["dk"]) for k in bed.kerbs],
        "medians": [_lv({"s": sm, "k": m["k"]}, m["dk"]) for m in bed.medians for sm in [trim_strip(m["s"], rect)] if len(sm) >= 8],
        "guards": [_lv({"p": g["p"]}, g["dk"]) for g in bed.guards],
        "symbols": [_lv({k: v for k, v in m.items() if k != "dk"}, m["dk"]) for m in bed.symbols],
        "decks": bed.deck_json(),
        "fills": bed.fill_json(),
        "tunnels": bed.tunnel_json(tunnel_roads),
        "garages": garages,
        # Loop 3a (R3): underpass dips the deck solver asked for (none on today's map); the
        # builder doesn't lower the ground for them yet (loop 3b), so check_roads C3 still sees them.
        "dips": [{"x": round(d["x"], 1), "z": round(d["z"], 1), "d": d["d"], "name": d["name"]} for d in bed.dips],
        "shore": bed.shore,
        "sand": banks["sand"],
        "sandbars": banks["sandbars"],
        "trees3d_crown": crowns,
        "ped_zones": ped_zones,
        "attribution": "© OpenStreetMap contributors, ODbL" + ("; trees © GUGiK, CC BY 4.0" if trees3d else ""),
    }
    if palm is not None:
        out["palm"] = palm
    out.update(extras)
    out.update(details)
    for key in ("markings",):
        out[key] = [_lv({k: v for k, v in m.items() if k != "dk"}, m.get("dk", -1)) for m in out[key]]
    _strip_private(out)
    final_poles(out)
    # Loop 3b: the builder's structures (piers, retaining walls, building cuts, the
    # Poniatowski towers' seats), placed on the finished map data (tools/bake_structures.py).
    import bake_structures
    map_dir = os.path.dirname(os.path.abspath(dst))
    bake_structures.add_structures(out, map_dir, json.load(open(os.path.join(map_dir, "terrain.json"))))
    # G8/G9 (2026-11-01): shelters onto the kerb of their bus road, turned roof along it; benches
    # turned to face the walk (tools/snap_props.py; the same code runs on a baked map).
    import snap_props
    snap_props.apply(out)
    # F (2026-11-02): streets closed to cars since OpenStreetMap drew them (Złota's linear park):
    # their roads out, their graph edges car-free, a pedestrian zone, the new trees (tools/car_free.py).
    import car_free
    print("car_free: " + car_free.apply(out))
    # Idea #9 (2026-11-02): the white bike pictograms on the cycle paths (tools/bike_marks.py).
    import bike_marks
    print("bike_marks: " + bike_marks.apply(out))
    # Idea #9: contraflow, bus-lane and sharrow bikes from the tags (tools/bike_network.py).
    import bike_network
    print("bike_network: " + bike_network.apply(out, els))
    # Krajobraz places (2026-11-02): the young trees of the newest streets that the laser scan
    # predates (ul. Bracka's woonerf), before the content POIs, which keep clear of trees.
    import planted_trees
    planted_trees.apply(out)
    # Krajobraz places K5 (2026-11-02): the plazas of Rondo Daszyńskiego's towers (tools/plaza_gardens.py).
    import plaza_gardens
    plaza_gardens.apply(out)
    # Plac Centralny (F's photos, 2026-11-05): the square's young trees, beds and benches (tools/plac_centralny.py).
    import plac_centralny
    plac_centralny.apply(out)
    # Smooth roads (F, 2026-11-05): the width steps where two ways of a carriageway meet tapered,
    # the lane lines stitched across them, small line kinks rounded (tools/road_smooth.py).
    import road_smooth
    print("road_smooth: " + road_smooth.apply(out))
    # Main's road bugs (F, 2026-11-07, "main as base, small fixes"): lane lines and arrows out of the
    # junctions' mouths, zebras and cycle crossings run on to the kerbs (tools/road_fixes.py).
    import road_fixes
    print("road_fixes: " + road_fixes.apply(out))
    # Loop "content POIs" (2026-10-31): the corner shops, metro entrances, city bike docks, the
    # places' missing addresses and the Leżaks with their zones, appended after every older poi
    # on the finished data (they keep clear of its solids; tools/bake_street_pois.py).
    import bake_street_pois
    bake_street_pois.add(out, els, nodes, ways, map_dir)
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"tunnels: {len(tunnel_roads)} tunnel roads, {len(out['tunnels']['pieces'])} pieces, "
          f"{len(out['tunnels']['portals'])} portals; garages: {len(garages)} doors (R9)")
    print(f"roads {len(roads)} paths {len(paths)} trams {len(trams)} areas {len(areas)} "
          f"trees {len(trees) // 4} + GUGiK {len(trees3d) // 6} buildings {len(kept)} (dropped {len(buildings) - len(kept)} outlines with parts) spawn {spawn}")


# Map north (2026-10-31, check_roads C1/C5 at Arkadia): a service way that lies this share of its
# length inside building outlines and has no layer, level or covered tag is a car park on the roof
# (Arkadia's, mapped flat): drawn on the ground it ran through the mall. It is left out with the
# bridge ramps that climb to it. The raw way stays in the OSM export for the landmarks lane.
ROOF_SHARE = 0.75
ROOF_MIN = 50.0
ROOF_STUB = 15.0   # a service way shorter than this between the ramps goes with them


def roof_aisles(roads, buildings):
    """Map north: (roads without the roof car parks and their ramps, how many ways went)."""
    # Outlines with courtyards (multipolygons: their inner rings aren't in the list) would hold
    # every courtyard's car park: only closed building ways count.
    outlines = [b["_pts"] if "_pts" in b else list(zip(b["p"][0::2], b["p"][1::2])) for b in buildings if not b.get("_mp")]
    boxes = [(min(q[0] for q in o), min(q[1] for q in o), max(q[0] for q in o), max(q[1] for q in o)) for o in outlines]
    cells = {}
    for k, b in enumerate(boxes):
        for i in range(int(b[0] // 50), int(b[2] // 50) + 1):
            for j in range(int(b[1] // 50), int(b[3] // 50) + 1):
                cells.setdefault((i, j), []).append(k)

    def in_building(x, z):
        for k in cells.get((int(x // 50), int(z // 50)), ()):
            b = boxes[k]
            if b[0] <= x <= b[2] and b[1] <= z <= b[3] and point_in_poly(x, z, outlines[k]):
                return True
        return False

    roof = []
    for r in roads:
        t = r["_t"]
        if r["k"] != "service" or t.get("service") != "parking_aisle" or r["bridge"] \
                or any(k in t for k in ("layer", "level", "covered", "tunnel")):
            continue
        pts = list(zip(r["p"][0::2], r["p"][1::2]))
        total = inside = 0.0
        for a, b in zip(pts, pts[1:]):
            ln = math.dist(a, b)
            n = max(1, int(ln))
            for k in range(n):
                total += ln / n
                if in_building(a[0] + (b[0] - a[0]) * (k + 0.5) / n, a[1] + (b[1] - a[1]) * (k + 0.5) / n):
                    inside += ln / n
        if total >= ROOF_MIN and inside >= ROOF_SHARE * total:
            roof.append(r)
    for r in roof:
        print(f"map north: roof car park way {r['_id']} at ({r['p'][0]:.0f}, {r['p'][1]:.0f}) left out")
    # The ramps: service bridges, and the short service stubs between them, joined to the roof
    # car park way by way.
    gone = {id(r) for r in roof}
    ends = {(round(x, 2), round(z, 2)) for r in roof for x, z in zip(r["p"][0::2], r["p"][1::2])}
    grew = bool(roof)
    while grew:
        grew = False
        for r in roads:
            if id(r) in gone or r["k"] != "service":
                continue
            pts = list(zip(r["p"][0::2], r["p"][1::2]))
            short = sum(math.dist(a, b) for a, b in zip(pts, pts[1:])) < ROOF_STUB
            if (r["bridge"] or short) and any((round(x, 2), round(z, 2)) in ends for x, z in pts):
                gone.add(id(r))
                ends.update((round(x, 2), round(z, 2)) for x, z in pts)
                grew = True
    return [r for r in roads if id(r) not in gone], len(gone)


def trim_strip(s4, shape):
    """Map north (tools/check_outline.py O1): a median strip (pairs of side points, 4 values a
    pair) offset from a road clipped at the map's edge reached up to 2 m past it: its end pairs
    off the map are dropped and a side point past the edge is moved back onto it."""
    pairs_ = [list(s4[k:k + 4]) for k in range(0, len(s4) - 3, 4)]

    def side_in(p, j):
        return shape.contains(p[j], p[j + 1])

    for _ in range(2):
        while len(pairs_) >= 3 and not any(side_in(pairs_[0], j) or side_in(pairs_[1], j) for j in (0, 2)):
            pairs_.pop(0)
        if len(pairs_) >= 2:
            for j in (0, 2):
                p, q = pairs_[0], pairs_[1]
                if not side_in(p, j) and side_in(q, j):
                    segs = shape.clip_segments((q[j], q[j + 1]), (p[j], p[j + 1]))
                    if segs:
                        p[j], p[j + 1] = round(segs[0][1][0], 2), round(segs[0][1][1], 2)
        pairs_.reverse()
    return [v for p in pairs_ for v in p]


FOOTBRIDGE_BESIDE = 12.0   # map north: a bridge footway this near a road bridge is its pavement


def cut_footbridges(paths, roads, shape):
    """Map north (2026-10-31, check_roads C3/C9 at Dworzec Gdański): a footbridge (the bridge
    footways joined at their ends) that the map's edge cuts can't be solved from one end (it led
    over the railway at 3 m and through a station building) and leads off the map: left out whole.
    A road bridge's pavements (bridge footways that run beside a road bridge for most of their
    points) stay with it. Returns (paths, how many ways went)."""
    br = [k for k, p in enumerate(paths) if p.get("_br")]
    parent = {k: k for k in br}

    def find(k):
        while parent[k] != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k

    at = {}
    for k in br:
        for x, z in zip(paths[k]["p"][0::2], paths[k]["p"][1::2]):
            q = (round(x, 2), round(z, 2))
            if q in at:
                parent[find(k)] = find(at[q])
            else:
                at[q] = k
    groups = {}
    for k in br:
        groups.setdefault(find(k), []).append(k)
    decks = [list(zip(r["p"][0::2], r["p"][1::2])) for r in roads if r["bridge"]]

    def beside(x, z):
        for d in decks:
            for a, b in zip(d, d[1:]):
                if seg_distance(x, z, a, b) < FOOTBRIDGE_BESIDE:
                    return True
        return False

    gone = set()
    for members in groups.values():
        pts = [(x, z) for k in members for x, z in zip(paths[k]["p"][0::2], paths[k]["p"][1::2])]
        if all(shape.contains(x, z) for x, z in pts):
            continue
        # A road bridge's pavement runs along it; a footbridge only meets one (Dworzec Gdański's
        # footbridge leaves Andersa's bridge over the platforms).
        if sum(1 for x, z in pts if beside(x, z)) >= 0.5 * len(pts):
            continue
        gone.update(members)
    return [p for k, p in enumerate(paths) if k not in gone], len(gone)


CROWN_NEAR = 12.0    # loop 3b-2: a scanned tree this close to a road's edge (m)...
CROWN_FAR = 20.0     # ...has its crown drawn at CROWN_SCALE, rising to full size here...
CROWN_SCALE = 0.75   # ...(the user, 2026-10-28: the scanned crowns read as gumdrops over the streets)


def crown_scales(trees3d, roads):
    """Loop 3b-2: one crown scale per scanned tree, in hundredths: CROWN_SCALE within
    CROWN_NEAR m of a drivable road's edge, full size from CROWN_FAR m (in parks), a ramp
    between. map_builder.gd scales the crown's radius and depth by it (its base stays), and
    bake_ao.py its shade. trees3d itself is unchanged."""
    grid = bake_roads.Grid(16.0)
    for r in roads:
        half = float(r["w"]) * 0.5
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        for a, b in zip(p, p[1:]):
            pad = half + CROWN_FAR
            grid.add((a, b, half), min(a[0], b[0]) - pad, min(a[1], b[1]) - pad, max(a[0], b[0]) + pad, max(a[1], b[1]) + pad)
    out = []
    near = 0
    for k in range(0, len(trees3d) - 5, 6):
        x, z = trees3d[k], trees3d[k + 1]
        d = min((bake_roads.seg_dist(x, z, a, b) - half for a, b, half in grid.at(x, z)), default=1e9)
        f = CROWN_SCALE + (1.0 - CROWN_SCALE) * min(1.0, max(0.0, (d - CROWN_NEAR) / (CROWN_FAR - CROWN_NEAR)))
        near += d <= CROWN_NEAR
        out.append(int(round(f * 100)))
    print(f"crowns: {near} of {len(out)} scanned trees within {CROWN_NEAR:.0f} m of a road at {CROWN_SCALE:.2f}, "
          f"{sum(1 for v in out if v < 100)} scaled down")
    return out


GARAGE_DROP = 2.0    # R9: a service way whose terrain falls this far below its start...
GARAGE_REACH = 30.0  # ...within this many metres...
GARAGE_GRADE = 0.20  # ...somewhere steeper than this, is diving into a garage


PASSAGE_MAX = 15.0   # loop 3b: a drivable tunnel=yes way no longer than this is a gate under a building


def is_passage(pts):
    """Loop 3b: a drivable `tunnel=yes` way this short (Warecka's 7 m under a building) is a
    gate through a building, not a tunnel: like `tunnel=building_passage` it is left out
    (check_roads C7 counts it under the building passages)."""
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:])) <= PASSAGE_MAX


def garage_ramps(roads, terrain_path):
    """Loop 3a (R9): a service way that dives into an underground garage follows the
    terrain grid down its ramp (C1 found 78 of them at 15-86 %). Walking a service way from
    its end that meets another road (the higher end, if neither does) towards a dead end,
    the first point from which the terrain falls GARAGE_DROP below it within GARAGE_REACH,
    somewhere steeper than GARAGE_GRADE, is the ramp's top: the way ends there and the rest
    is left out; a garage door [x, z, dx, dz] (the way in) is written there for loop 3b to
    draw. A way that meets roads at both ends is left as it is."""
    t = bake_roads.Terrain(terrain_path)
    verts = {}
    for r in roads:
        for q in zip(r["p"][0::2], r["p"][1::2]):
            k = (round(q[0] * 2), round(q[1] * 2))
            verts[k] = verts.get(k, 0) + 1
    out, doors = [], []
    for r in roads:
        pts = list(zip(r["p"][0::2], r["p"][1::2]))
        if r["k"] != "service" or len(pts) < 2:
            out.append(r)
            continue
        c0 = verts.get((round(pts[0][0] * 2), round(pts[0][1] * 2)), 0) >= 2
        c1 = verts.get((round(pts[-1][0] * 2), round(pts[-1][1] * 2)), 0) >= 2
        if c0 and c1:
            out.append(r)
            continue
        forward = c0 if c0 != c1 else t.h(*pts[0]) >= t.h(*pts[-1])
        ps = bake_roads.resample(pts if forward else pts[::-1], 2.0)
        cum = [0.0]
        for a, b in zip(ps, ps[1:]):
            cum.append(cum[-1] + math.dist(a, b))
        hs = [t.h(*q) for q in ps]
        cut = None
        for k in range(len(ps) - 1):
            steep = False
            for j in range(k + 1, len(ps)):
                if cum[j] - cum[k] > GARAGE_REACH:
                    break
                if (hs[j - 1] - hs[j]) / max(cum[j] - cum[j - 1], 1e-3) > GARAGE_GRADE:
                    steep = True
                if hs[j] < hs[k] - GARAGE_DROP and steep:
                    top = max(q for q in range(k, j + 1) if hs[q] >= hs[k] - 0.5)
                    cut = top
                    break
            if cut is not None:
                break
        if cut is None:
            out.append(r)
            continue
        keep = ps[:cut + 1]
        if len(keep) >= 2 and cum[cut] >= 2.0:
            out.append(dict(r, p=flat(keep if forward else keep[::-1])))
        door, down = ps[cut], ps[cut + 1]
        d = math.dist(door, down) or 1.0
        doors.append([round(door[0], 1), round(door[1], 1), round((down[0] - door[0]) / d, 3),
                      round((down[1] - door[1]) / d, 3)])
    print(f"garages: {len(doors)} service ways end at a garage ramp (R9)")
    return out, doors


def _lv(item, level):
    """A deck group ("dk") on things that lie on a bridge; nothing for the ground."""
    if level is not None and level >= 0:
        item["dk"] = level
    return item


def _strip_private(obj):
    """Drop the bake's own working keys ("_id", "_t", ...) before writing."""
    if isinstance(obj, dict):
        for k in [k for k in obj if isinstance(k, str) and k.startswith("_")]:
            del obj[k]
        for v in obj.values():
            _strip_private(v)
    elif isinstance(obj, list):
        for v in obj:
            if isinstance(v, (dict, list)):
                _strip_private(v)


def make_building(t, pts, is_part):
    if ring_area(pts) < 0:
        pts = pts[::-1]
    height = num(t.get("height"))
    levels = num(t.get("building:levels"))
    if height is None and levels is not None:
        height = levels * 3.3 + 1.0
    if height is None:
        height = 14.0
    min_height = num(t.get("min_height"))
    if min_height is None and num(t.get("building:min_level")) is not None:
        min_height = num(t.get("building:min_level")) * 3.3
    out = {
        "_pts": pts, "part": is_part,
        "h": round(max(height, 2.5), 1), "mh": round(min_height or 0.0, 1),
        "c": t.get("building:colour", ""), "rc": t.get("roof:colour", ""),
        "kind": t.get("building") or t.get("building:part") or "",
        "name": t.get("name", ""),
    }
    # A 3D-mapped bridge (man_made=bridge as a building part): the bridge decks draw it,
    # so the game skips it ("br"). It stays in the list: lod2.json's keep_osm counts on
    # the buildings' order.
    if t.get("man_made") == "bridge" or t.get("building") == "bridge" or "bridge:structure" in t:
        out["br"] = 1
    return out


def nearest_road_point(roads, x, z):
    best = None
    for r in roads:
        if r["k"] in ("service", "living_street"):
            continue
        p = r["p"]
        for i in range(0, len(p) - 2, 2):
            ax, az, bx, bz = p[i], p[i + 1], p[i + 2], p[i + 3]
            dx, dz = bx - ax, bz - az
            ln = dx * dx + dz * dz
            if ln == 0:
                continue
            u = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / ln))
            px, pz = ax + u * dx, az + u * dz
            d = (px - x) ** 2 + (pz - z) ** 2
            if best is None or d < best[0]:
                best = (d, px, pz, math.atan2(-dx, -dz))
    return {"x": round(best[1], 1), "z": round(best[2], 1), "yaw": round(best[3], 3)}


def bake_trees(src, areas, gugik=None):
    """Mapped trees and tree rows, plus filler trees in parks that have few mapped ones.

    Where the GUGiK laser-scanned trees cover the map (whole sheets that parsed to the end),
    they replace all of these, because they are every real tree with its real size.

    Returns two flat lists: OSM trees as x, z, scale, kind (0 broadleaved, 1 needleleaved),
    and GUGiK trees as x, z, height, crown radius, crown base, kind; and the scanned records
    left out as not trees (GUGIK_NOT_TREES) as (x, z, kind).
    """
    els = json.load(open(src, encoding="utf-8"))["elements"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    spots = []
    for e in els:
        t = e.get("tags", {})
        if e["type"] == "node" and t.get("natural") == "tree" and in_bbox(e["lat"], e["lon"]):
            spots.append((*project(e["lat"], e["lon"]), t.get("leaf_type") == "needleleaved"))
        elif e["type"] == "way" and t.get("natural") == "tree_row":
            pts = [project(*nodes[i]) for i in e.get("nodes", []) if i in nodes]
            for (ax, az), (bx, bz) in zip(pts, pts[1:]):
                n = max(1, int(math.hypot(bx - ax, bz - az) / 7.0))
                for k in range(n):
                    spots.append((ax + (bx - ax) * k / n, az + (bz - az) * k / n, False))

    cell = 6.0
    mapped_cells = {(int(x // cell), int(z // cell)) for x, z, _ in spots}
    for a in areas:
        if a["k"] not in ("park", "grass"):
            continue
        poly = list(zip(a["p"][0::2], a["p"][1::2]))
        area = abs(ring_area(poly))
        if area < 250:
            continue
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        spacing = 8.0 if a["k"] == "park" else 14.0
        x = min(xs) + spacing / 2
        while x < max(xs):
            z = min(zs) + spacing / 2
            while z < max(zs):
                h = (math.sin(x * 12.9898 + z * 78.233) * 43758.5453) % 1.0
                px = x + (h - 0.5) * spacing * 0.7
                pz = z + ((h * 7.0) % 1.0 - 0.5) * spacing * 0.7
                key = (int(px // cell), int(pz // cell))
                near_mapped = any((key[0] + i, key[1] + j) in mapped_cells for i in (-1, 0, 1) for j in (-1, 0, 1))
                if not near_mapped and point_in_poly(px, pz, poly):
                    spots.append((px, pz, h < 0.06))
                z += spacing
            x += spacing

    real = []
    dropped = []
    if gugik:
        sheets = [list(zip(c[0::2], c[1::2])) for c in gugik["sheets"]]

        def covered(x, z):
            return any(point_in_poly(x, z, sheet) for sheet in sheets)

        # GUGiK has no species; a crown takes the conifer shape only where OSM maps one.
        needles = {(int(x // 3), int(z // 3)) for x, z, needle in spots if needle}
        t = gugik["trees"]
        for k in range(0, len(t) - 4, 5):
            x, z = t[k], t[k + 1]
            what = next((n for n in GUGIK_NOT_TREES
                         if math.hypot(x - n[0], z - n[1]) < 1.0 and abs(t[k + 2] - n[2]) < 0.6), None)
            if what is not None:
                dropped.append((x, z, what[3]))
                continue
            if covered(x, z):
                needle = any((int(x // 3) + i, int(z // 3) + j) in needles for i in (-1, 0, 1) for j in (-1, 0, 1))
                real += t[k:k + 5] + [1 if needle else 0]
        spots = [s for s in spots if not covered(s[0], s[1])]

    out = []
    for x, z, needle in spots:
        h = (math.sin(x * 3.17 + z * 7.31) * 9301.17) % 1.0
        out += [round(x, 1), round(z, 1), round(0.85 + h * 0.7, 2), 1 if needle else 0]
    if dropped:
        print("GUGiK records left out as not trees: " + ", ".join(f"{kind} at {x:.1f},{z:.1f}" for x, z, kind in dropped))
    return out, real, dropped


def inside(rect, x, z):
    if isinstance(rect, Shape):
        return rect.contains(x, z)
    return rect[0] <= x <= rect[2] and rect[1] <= z <= rect[3]


def clip_segments(a, b, rect):
    """Map north: the pieces of a-b inside rect (a Shape: up to two), as (p, q) pairs."""
    if isinstance(rect, Shape) and rect.outside:
        return rect.clip_segments(a, b)
    seg = clip_segment(a, b, rect)
    return [] if seg is None else [seg]


def clip_segment(a, b, rect):
    """Liang-Barsky: the part of segment a-b inside rect, or None."""
    x0, z0, x1, z1 = rect
    dx, dz = b[0] - a[0], b[1] - a[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, a[0] - x0), (dx, x1 - a[0]), (-dz, a[1] - z0), (dz, z1 - a[1])):
        if p == 0:
            if q < 0:
                return None
            continue
        r = q / p
        if p < 0:
            t0 = max(t0, r)
        else:
            t1 = min(t1, r)
        if t0 > t1:
            return None
    return (a[0] + dx * t0, a[1] + dz * t0), (a[0] + dx * t1, a[1] + dz * t1)


def clip_lines(items, rect):
    """Split each polyline at the map edge and keep only the pieces inside."""
    out = []
    for item in items:
        pts = list(zip(item["p"][0::2], item["p"][1::2]))
        piece = []
        for a, b in zip(pts, pts[1:]):
            segs = clip_segments(a, b, rect)
            if not segs:
                if len(piece) >= 2:
                    out.append(dict(item, p=flat(piece)))
                piece = []
                continue
            for seg in segs:
                if piece and piece[-1] == seg[0]:
                    piece.append(seg[1])
                else:
                    if len(piece) >= 2:
                        out.append(dict(item, p=flat(piece)))
                    piece = [seg[0], seg[1]]
                if seg[1] != b:
                    out.append(dict(item, p=flat(piece)))
                    piece = []
        if len(piece) >= 2:
            out.append(dict(item, p=flat(piece)))
    return out


def clip_polygon(poly, rect):
    """Sutherland-Hodgman against the four edges of rect. Map north: for a Shape, a polygon
    that reaches into a part left `outside` is cut to each of the map's rectangles and the
    larger piece kept (only outlines across the extension's inner corner have two)."""
    out = _clip_rect(poly, rect)
    if isinstance(rect, Shape) and rect.outside and out:
        if all(abs(ring_area(_clip_rect(out, o))) < 1e-6 for o in rect.outside):
            return out
        pieces = [_clip_rect(out, r) for r in rect.parts()]
        return max(pieces, key=lambda c: abs(ring_area(c)) if len(c) >= 3 else -1.0)
    return out


def _clip_rect(poly, rect):
    x0, z0, x1, z1 = rect
    edges = [(lambda p: p[0] >= x0, lambda a, b: (x0, a[1] + (b[1] - a[1]) * (x0 - a[0]) / (b[0] - a[0]))),
             (lambda p: p[0] <= x1, lambda a, b: (x1, a[1] + (b[1] - a[1]) * (x1 - a[0]) / (b[0] - a[0]))),
             (lambda p: p[1] >= z0, lambda a, b: (a[0] + (b[0] - a[0]) * (z0 - a[1]) / (b[1] - a[1]), z0)),
             (lambda p: p[1] <= z1, lambda a, b: (a[0] + (b[0] - a[0]) * (z1 - a[1]) / (b[1] - a[1]), z1))]
    for keep, cut in edges:
        if not poly:
            break
        out = []
        for i in range(len(poly)):
            a, b = poly[i - 1], poly[i]
            if keep(b):
                if not keep(a):
                    out.append(cut(a, b))
                out.append(b)
            elif keep(a):
                out.append(cut(a, b))
        poly = out
    return poly


def bake_details(els, nodes, ways, more_src, roads, rect):
    """Street details: rail tracks, platforms, shelters, benches, bins, bike racks,
    advertising columns, hedges, fences, walls, steps, traffic islands, sidewalk
    areas, flowerbeds, construction sites, fountains and playgrounds."""
    more = json.load(open(more_src, encoding="utf-8"))["elements"]
    nodes = dict(nodes)
    nodes.update({e["id"]: (e["lat"], e["lon"]) for e in more if e["type"] == "node"})
    all_ways = dict(ways)
    all_ways.update({e["id"]: e for e in more if e["type"] == "way"})

    def underground(t):
        layer = num(t.get("layer"))
        if t.get("tunnel") not in (None, "no") or t.get("indoor") == "yes" or t.get("location") == "underground":
            return True
        # A negative layer is open air when it's a cutting (the WKD line runs in one).
        return layer is not None and layer < 0 and t.get("cutting") != "yes" and "railway" not in t

    def line(ids):
        return [project(*nodes[i]) for i in ids if i in nodes]

    out = {k: [] for k in ("rails", "platforms", "islands", "lines", "surfaces", "steps", "citywalls")}
    rail_ends = []   # loop 3d-1: (first node, last node, has no layer of its own, all nodes) per rail
    for w in all_ways.values():
        t = w.get("tags", {})
        ids = w.get("nodes", [])
        if len(ids) < 2 or underground(t) or not any(i in nodes and in_bbox(*nodes[i]) for i in ids):
            continue
        closed = ids[0] == ids[-1] and len(ids) >= 4
        pts = line(ids)
        if t.get("railway") in ("rail", "light_rail", "narrow_gauge"):
            br = t.get("bridge") not in (None, "no")
            out["rails"].append({"p": flat(pts), "_br": br, "_ly": num(t.get("layer")) or (1 if br else 0)})
            rail_ends.append((ids[0], ids[-1], t.get("layer") is None and not br, set(ids)))
        elif t.get("railway") == "platform" or t.get("public_transport") == "platform" or t.get("highway") == "platform":
            if closed:
                out["platforms"].append({"p": flat(pts[:-1]), "h": 0.9 if t.get("railway") == "platform" else 0.25})
            else:
                out["lines"].append({"k": "platform", "p": flat(pts)})
        elif t.get("area:highway") == "traffic_island" and closed:
            out["islands"].append({"p": flat(pts[:-1])})
        elif t.get("area:highway") in ("footway", "pedestrian") and closed:
            out["surfaces"].append({"k": "paving", "p": flat(pts[:-1])})
        elif t.get("barrier") in ("hedge", "fence", "wall", "retaining_wall"):
            kind = {"retaining_wall": "wall"}.get(t["barrier"], t["barrier"])
            # Stairs and walls (2026-11-07): a barrier's mapped height, a wall's material and a
            # fence's type (tools/barrier_tags.py), instead of one height and colour per kind.
            out["lines"].append(dict({"k": kind, "p": flat(pts)}, **barrier_tags.barrier_fields(t)))
        elif t.get("barrier") == "city_wall":
            # The Old Town's defence walls (OSM areas), drawn as brick walls (map_builder.gd).
            cw = barrier_tags.city_wall(t, pts)
            if cw:
                out["citywalls"].append(cw)
        elif t.get("highway") == "steps":
            out["steps"].append(dict({"p": flat(pts)}, **stairs.stair_tags(t)))
        elif closed and (t.get("landuse") in ("railway", "flowerbed", "construction", "brownfield")
                         or t.get("leisure") in ("playground", "fountain") or t.get("amenity") == "fountain"
                         or t.get("man_made") == "planter"):
            kind = (t.get("landuse") or t.get("leisure") or t.get("amenity") or t.get("man_made"))
            kind = {"brownfield": "construction", "railway": "ballast", "planter": "flowerbed"}.get(kind, kind)
            out["surfaces"].append({"k": kind, "p": flat(pts[:-1])})

    # Loop 3d-1: a rail way with no layer of its own whose both ends meet only cutting tracks
    # (layer < 0) is in the cutting too (a crossover by Żelazna is mapped so): it takes their
    # layer, so a deck over it is judged like one over the cutting (bake_roads `cuttings_under`).
    grade_nodes, cut_nodes = {}, {}   # node -> how many tracks at grade hold it; node -> cutting layer
    for (a, b, bare, allids), r in zip(rail_ends, out["rails"]):
        for i in allids:
            if r["_ly"] < 0:
                cut_nodes[i] = r["_ly"]
            else:
                grade_nodes[i] = grade_nodes.get(i, 0) + 1
    sunk = 0
    for (a, b, bare, allids), r in zip(rail_ends, out["rails"]):
        if bare and r["_ly"] == 0:
            if a in cut_nodes and b in cut_nodes and grade_nodes.get(a, 0) <= 1 and grade_nodes.get(b, 0) <= 1:
                r["_ly"] = max(cut_nodes[a], cut_nodes[b])
                sunk += 1
    if sunk:
        print(f"rails: {sunk} tracks with no layer between cutting tracks put in the cutting (loop 3d-1)")
    out["rails"] = clip_lines(out["rails"], rect)
    out["steps"] = clip_lines(out["steps"], rect)
    out["lines"] = clip_lines(out["lines"], rect)
    for key in ("platforms", "islands", "surfaces"):
        out[key] = [dict(a, p=flat(c)) for a in out[key]
                    for c in [clip_polygon(list(zip(a["p"][0::2], a["p"][1::2])), rect)] if len(c) >= 3]

    # Point props, turned to face along the nearest road where there is one.
    segs = []
    for r in roads:
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        segs += list(zip(p, p[1:]))

    # Loop 3d-1: the segments by their ends' x in 10 m bins (every prop against every road
    # segment took 100 s on the demo box); the same segments, in the same order, as before.
    seg_bins = {}
    for k, (a, b) in enumerate(segs):
        for bx in {int(a[0] // 10), int(b[0] // 10)}:
            seg_bins.setdefault(bx, []).append(k)

    def road_yaw(x, z):
        best = None
        near = set()
        for bx in range(int((x - 40) // 10), int((x + 40) // 10) + 1):
            near.update(seg_bins.get(bx, ()))
        for k in sorted(near):
            a, b = segs[k]
            if abs(a[0] - x) > 40 and abs(b[0] - x) > 40:
                continue
            dx, dz = b[0] - a[0], b[1] - a[1]
            ln = dx * dx + dz * dz
            if ln == 0:
                continue
            u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
            d = math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)
            if best is None or d < best[0]:
                best = (d, math.atan2(-dx, -dz))
        return best[1] if best and best[0] < 25 else (math.sin(x * 1.3 + z * 0.7) * math.pi)

    props = {"benches": [], "bins": [], "bikes": [], "columns": [], "shelters": []}
    for e in more:
        t = e.get("tags", {})
        if e["type"] != "node" or not t or not in_bbox(e["lat"], e["lon"]):
            continue
        x, z = project(e["lat"], e["lon"])
        key = None
        if t.get("amenity") == "bench":
            key = "benches"
        elif t.get("amenity") == "waste_basket":
            key = "bins"
        elif t.get("amenity") == "bicycle_parking":
            key = "bikes"
        elif t.get("advertising") == "column":
            key = "columns"
        elif t.get("shelter") == "yes" or t.get("amenity") == "shelter":
            key = "shelters"
        elif t.get("amenity") == "fountain":
            out["surfaces"].append({"k": "fountain", "p": flat([(x + math.cos(a / 4 * math.pi) * 2.5, z + math.sin(a / 4 * math.pi) * 2.5) for a in range(8)])})
        if key:
            props[key] += [round(x, 1), round(z, 1), round(road_yaw(x, z), 2)]
    out.update(props)
    print("details: " + ", ".join(f"{k} {len(v) // 3 if k in props else len(v)}" for k, v in list(out.items())))
    return out


# Places the rescue missions use: (tag, value) -> kind.
POI_KINDS = {
    ("amenity", "hospital"): "hospital", ("healthcare", "hospital"): "hospital",
    ("natural", "beach"): "beach", ("natural", "shoal"): "sandbar",
    ("leisure", "park"): "park", ("leisure", "stadium"): "stadium", ("place", "square"): "square",
}


def inner_point(pts):
    """A point well inside a polygon (the centroid can fall outside a bent one):
    the grid sample farthest from the outline."""
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    step = max(2.0, max(max(xs) - min(xs), max(zs) - min(zs)) / 24)
    best = None
    x = min(xs) + step / 2
    while x < max(xs):
        z = min(zs) + step / 2
        while z < max(zs):
            if point_in_poly(x, z, pts):
                d = min(seg_distance(x, z, pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))
                if best is None or d > best[0]:
                    best = (d, x, z)
            z += step
        x += step
    return (best[1], best[2]) if best else centroid(pts)


def seg_distance(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = dx * dx + dz * dz
    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
    return math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)


def bake_pois(els, nodes, ways, roads, paths, areas, rect):
    """Named places for the rescue missions: hospitals (with the nearest point on a road,
    where an ambulance or a helicopter would stop), Vistula beaches, dry sandbars (an
    island in the drawn river stays "sandbar"; one joined to the bank becomes "shore"),
    parks, squares and the stadium. Each gets a point well inside its outline. Then the
    side jobs' and easter eggs' places (bake_job_pois)."""
    water = [list(zip(a["p"][0::2], a["p"][1::2])) for a in areas if a["k"] == "water"]
    segs = []
    for r in roads:
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        segs += list(zip(p, p[1:]))
    grown = rect.grow(-25) if isinstance(rect, Shape) else (rect[0] + 25, rect[1] + 25, rect[2] - 25, rect[3] - 25)
    out = []
    for e in els:
        t = e.get("tags", {})
        kind = next((k for (key, val), k in POI_KINDS.items() if t.get(key) == val), None)
        if kind is None:
            continue
        name = t.get("name", "")
        if not name and kind not in ("beach", "sandbar"):
            continue  # a mission needs a place it can name
        if e["type"] == "node":
            x, z = project(e["lat"], e["lon"])
        else:
            if e["type"] == "way":
                rings = [e.get("nodes", [])]
            else:
                rings = stitch([ways[m["ref"]]["nodes"] for m in e.get("members", [])
                                if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways])
            rings = [[project(*nodes[i]) for i in ring[:-1] if i in nodes] for ring in rings if ring and ring[0] == ring[-1]]
            rings = [r for r in rings if len(r) >= 3]
            if not rings:
                continue
            x, z = inner_point(max(rings, key=lambda r: abs(ring_area(r))))
        if not inside(grown, x, z):
            continue
        # A sandbar under the drawn river would leave the person standing on water.
        if kind == "sandbar" and any(point_in_poly(x, z, w) for w in water):
            continue
        # Water on nearly every side 40 m out: an island only a helicopter reaches.
        if kind == "sandbar":
            ring = [(x + math.cos(k * math.pi / 6) * 40, z + math.sin(k * math.pi / 6) * 40) for k in range(12)]
            if sum(1 for px, pz in ring if any(point_in_poly(px, pz, w) for w in water)) < 9:
                kind = "shore"
        poi = {"k": kind, "name": name, "x": round(x, 1), "z": round(z, 1)}
        if kind == "hospital":
            _, a, b = min(((seg_distance(x, z, a, b), a, b) for a, b in segs), key=lambda s: s[0])
            dx, dz = b[0] - a[0], b[1] - a[1]
            ln = dx * dx + dz * dz
            u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
            poi["door"] = [round(a[0] + u * dx, 1), round(a[1] + u * dz, 1)]
        out.append(poi)
    out += bake_job_pois(els, nodes, ways, roads, paths, areas, grown)
    print("pois: " + ", ".join(f"{k} {sum(1 for p in out if p['k'] == k)}" for k in sorted({p["k"] for p in out})))
    return out


# Side jobs and easter eggs (v0.65). Streets a car pulls up on (the lane graph's roads,
# without the short links), and the buildings people order kebabs to.
JOB_ROADS = {"primary", "secondary", "tertiary", "unclassified", "residential", "living_street"}
HOMES = {"apartments", "residential", "house", "detached", "semidetached_house", "terrace", "dormitory"}
# The mapped kebab places sit inside the central station and a food hall, so a few
# stands on busy corners join them. Positions only; no shop is ever named.
EXTRA_KEBAB = [
    (52.23022, 21.01253),    # Rondo Dmowskiego, by the Rotunda
    (52.237165, 21.019805),  # Nowy Świat at Świętokrzyska
    (52.234271, 21.034649),  # Solec, at the foot of Most Poniatowskiego
    (52.234995, 21.009332),  # Marszałkowska at Świętokrzyska
    (52.23695, 21.04680),    # Al. Poniatowskiego opposite PGE Narodowy, on the Praga bank (orders across the river)
]
STAND_SPACING = 150.0  # a stand closer than this to an earlier one is dropped


class SegGrid:
    """Road segments in 50 m cells, for nearest-road queries."""

    CELL = 50.0

    def __init__(self, roads, kinds):
        self.cells = {}
        for r in roads:
            if r["k"] not in kinds:
                continue
            p = list(zip(r["p"][0::2], r["p"][1::2]))
            for a, b in zip(p, p[1:]):
                x0, x1 = sorted((a[0], b[0]))
                z0, z1 = sorted((a[1], b[1]))
                for i in range(int(math.floor(x0 / self.CELL)), int(math.floor(x1 / self.CELL)) + 1):
                    for j in range(int(math.floor(z0 / self.CELL)), int(math.floor(z1 / self.CELL)) + 1):
                        self.cells.setdefault((i, j), []).append((a, b, r))

    def nearest(self, x, z, reach):
        """(distance, point, road) of the road point nearest (x, z) within reach, or None."""
        best = None
        n = int(math.ceil(reach / self.CELL))
        ci, cj = int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))
        for i in range(ci - n, ci + n + 1):
            for j in range(cj - n, cj + n + 1):
                for a, b, r in self.cells.get((i, j), ()):
                    dx, dz = b[0] - a[0], b[1] - a[1]
                    ln = dx * dx + dz * dz
                    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
                    q = (a[0] + u * dx, a[1] + u * dz)
                    d = math.hypot(q[0] - x, q[1] - z)
                    if d <= reach and (best is None or d < best[0]):
                        best = (d, q, r)
        return best


def element_point(e, nodes, ways):
    """A point inside a node, way or multipolygon (the centroid when it falls inside)."""
    if e["type"] == "node":
        return project(e["lat"], e["lon"])
    if e["type"] == "way":
        rings = [e.get("nodes", [])]
    else:
        rings = stitch([ways[m["ref"]]["nodes"] for m in e.get("members", [])
                        if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways])
    rings = [[project(*nodes[i]) for i in ring[:-1] if i in nodes] for ring in rings if ring and ring[0] == ring[-1]]
    rings = [r for r in rings if len(r) >= 3]
    if not rings:
        return None
    ring = max(rings, key=lambda r: abs(ring_area(r)))
    c = centroid(ring)
    return c if point_in_poly(c[0], c[1], ring) else inner_point(ring)


def bake_job_pois(els, nodes, ways, roads, paths, areas, inner):
    """Places for the side jobs and easter eggs: kebab stands ("kebab": where it is and
    the road point a car pulls up at, "w" that road's width), homes and offices with a
    street address ("address": "Hoża 41", the road point at its door, "o" for an office,
    "d" = "powisle", or "praga" across the river), the central station ("station", where
    the słoiki run starts), Patelnia, Plac Defilad, and the Mermaid ("syrenka": a mapped
    statue, else a spot on the Powiśle boulevard by the river, facing the water)."""
    grid = SegGrid(roads, JOB_ROADS)
    river = max((list(zip(a["p"][0::2], a["p"][1::2])) for a in areas if a["k"] == "water"),
                key=lambda r: abs(ring_area(r)), default=[])
    out = []

    def door(x, z, reach):
        hit = grid.nearest(x, z, reach)
        if hit is None:
            return None
        return [round(hit[1][0], 1), round(hit[1][1], 1)], hit[2]

    def east_of_river(x, z):
        # Water somewhere due west of the point: it is on the far (Praga) bank.
        for (ax, az), (bx, bz) in zip(river, river[1:] + river[:1]):
            if (az > z) != (bz > z) and ax + (z - az) * (bx - ax) / (bz - az) < x:
                return True
        return False

    def extremes(name, axis):
        pts = [(r["p"][i], r["p"][i + 1]) for r in roads if r["name"] == name for i in range(0, len(r["p"]) - 1, 2)]
        return (min(pts, key=lambda p: p[axis]), max(pts, key=lambda p: p[axis])) if pts else None

    def side(p, line):
        # Positive to the left of the line's direction, seen from above (+x east, +z south).
        (ax, az), (bx, bz) = line
        dx, dz = bx - ax, bz - az
        return ((p[0] - ax) * dz - (p[1] - az) * dx) / (math.hypot(dx, dz) or 1.0)

    # Powiśle: west of the river, east of the escarpment (150 m past Nowy Świat, which runs
    # south) and north of Al. Jerozolimskie (which runs east).
    nowy = extremes("Nowy Świat", 1)
    aleje = extremes("Aleje Jerozolimskie", 0)

    def district(x, z):
        if river and east_of_river(x, z):
            return "praga"
        if nowy and aleje and side((x, z), nowy) > 150.0 and side((x, z), aleje) > 40.0:
            return "powisle"
        return ""

    # Kebab stands: the mapped kebab places, then the extra corners.
    spots = []
    for e in els:
        t = e.get("tags", {})
        if t.get("amenity") == "fast_food" and ("kebab" in t.get("cuisine", "").lower() or "kebab" in t.get("name", "").lower()):
            p = element_point(e, nodes, ways)
            if p:
                spots.append(p)
    spots += [project(lat, lon) for lat, lon in EXTRA_KEBAB]
    stands = []
    for x, z in spots:
        if not inside(inner, x, z) or any(math.hypot(x - s[0], z - s[1]) < STAND_SPACING for s in stands):
            continue
        d = door(x, z, 80.0)
        if d is None:
            continue
        stands.append((x, z))
        out.append({"k": "kebab", "x": round(x, 1), "z": round(z, 1), "door": d[0], "w": d[1]["w"]})

    # Homes and offices with a street address.
    seen = set()
    for e in els:
        t = e.get("tags", {})
        b = t.get("building")
        if e["type"] == "node" or not t.get("addr:street") or not t.get("addr:housenumber"):
            continue
        if b not in HOMES and b != "office":
            continue
        name = f'{t["addr:street"]} {t["addr:housenumber"]}'
        if name in seen:
            continue
        p = element_point(e, nodes, ways)
        if p is None or not inside(inner, p[0], p[1]):
            continue
        d = door(p[0], p[1], 70.0)
        if d is None:
            continue
        seen.add(name)
        poi = {"k": "address", "name": name, "x": round(p[0], 1), "z": round(p[1], 1), "door": d[0]}
        if b == "office":
            poi["o"] = 1
        where = district(p[0], p[1])
        if where:
            poi["d"] = where
        out.append(poi)

    # The central station, Patelnia, Plac Defilad, and the Mermaid if she is mapped.
    mermaid = None
    for e in els:
        t = e.get("tags", {})
        name = t.get("name", "")
        kind = None
        if name == "Warszawa Centralna" and t.get("building") == "train_station":
            kind = "station"
        elif name == "Patelnia" and t.get("highway") == "pedestrian":
            kind = "patelnia"
        elif name == "Plac Defilad" and t.get("amenity") == "bus_station":
            kind = "defilad"
        elif t.get("tourism") == "artwork" and ("syren" in name.lower() or "mermaid" in name.lower()):
            kind = "syrenka"
        if kind is None:
            continue
        p = element_point(e, nodes, ways)
        if p is None or not inside(inner, p[0], p[1]):
            continue
        poi = {"k": kind, "name": "Dworzec Centralny" if kind == "station" else name,
               "x": round(p[0], 1), "z": round(p[1], 1)}
        if kind == "station":
            d = door(p[0], p[1], 120.0)
            if d is None:
                continue
            poi["door"] = d[0]
            poi["w"] = d[1]["w"]
        if kind == "syrenka":
            # Loop 3d-1: the egg is the Mermaid by the river; a mapped one far from it (the demo box
            # maps a small "Syrenka" artwork 1.5 km inland, at -1453, -555) leaves the boulevard
            # spot below to stand in for the riverside one, as on the first box.
            if river and min(math.hypot(poi["x"] - rx, poi["z"] - rz) for rx, rz in river) > MERMAID_RIVER:
                continue
            mermaid = poi
        out.append(poi)
    if mermaid is None and river:
        spot = boulevard_spot(roads, paths, river)
        if spot:
            out.append({"k": "syrenka", "name": "", "x": spot[0], "z": spot[1], "yaw": spot[2]})
    return out


def boulevard_spot(roads, paths, river):
    """The footway point on the west bank 8-30 m from the Vistula and 10 m clear of any
    road nearest the foot of Tamka (where Warsaw's riverside Mermaid stands), and the
    yaw that faces the water."""
    tamka = [(r["p"][i], r["p"][i + 1]) for r in roads if r["name"] == "Tamka" for i in range(0, len(r["p"]) - 1, 2)]
    if not tamka:
        return None
    tx, tz = max(tamka, key=lambda p: p[0])
    edges = list(zip(river, river[1:] + river[:1]))
    roads_grid = SegGrid(roads, {r["k"] for r in roads})  # off the roads, on the promenade

    def to_water(x, z):
        return min(((seg_distance(x, z, e0, e1), e0, e1) for e0, e1 in edges), key=lambda s: s[0])

    best = None
    for p in paths:
        if p["k"] != "foot":
            continue
        pts = list(zip(p["p"][0::2], p["p"][1::2]))
        for a, b in zip(pts, pts[1:]):
            n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 2.0))
            for k in range(n + 1):
                x = a[0] + (b[0] - a[0]) * k / n
                z = a[1] + (b[1] - a[1]) * k / n
                near = math.hypot(x - tx, z - tz)
                if near > 300.0 or x < tx or (best is not None and near >= best[0]) or point_in_poly(x, z, river):
                    continue
                if 8.0 <= to_water(x, z)[0] <= 30.0 and roads_grid.nearest(x, z, 10.0) is None:
                    best = (near, x, z)
    if best is None:
        return None
    _, x, z = best
    _, e0, e1 = to_water(x, z)
    dx, dz = e1[0] - e0[0], e1[1] - e0[1]
    ln = dx * dx + dz * dz
    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - e0[0]) * dx + (z - e0[1]) * dz) / ln))
    wx, wz = e0[0] + u * dx, e0[1] + u * dz
    # Godot's yaw for a model whose front is -Z, turned to face the water.
    return round(x, 1), round(z, 1), round(math.atan2(-(wx - x), -(wz - z)), 3)


# AI traffic: free-flow speed in m/s when a road has no maxspeed tag.
TRAFFIC_SPEED = {
    "motorway": 22.0, "trunk": 19.0, "primary": 13.9, "secondary": 13.9, "tertiary": 12.5,
    "unclassified": 9.7, "residential": 9.7, "living_street": 5.6,
    "motorway_link": 13.9, "trunk_link": 12.5, "primary_link": 11.1,
    "secondary_link": 11.1, "tertiary_link": 11.1,
}
SIGNAL_CLUSTER = 45.0  # junction nodes this close together are one signalled junction
JUNCTION_REACH = 55.0  # a stop line further than this from a junction is a crossing light


def oneway_of(t):
    """1 = only along the way, -1 = only against it, 0 = both directions."""
    ow = t.get("oneway")
    if ow in ("yes", "true", "1"):
        return 1
    if ow in ("-1", "reverse"):
        return -1
    if ow != "no" and t.get("junction") in ("roundabout", "circular"):
        return 1
    return 0


def heading_at(pts, s):
    """Unit direction of a polyline at distance s along it."""
    for a, b in zip(pts, pts[1:]):
        ln = math.hypot(b[0] - a[0], b[1] - a[1])
        if ln > 0 and (s <= ln or (a, b) == (pts[-2], pts[-1])):
            return ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)
        s -= ln
    return (1.0, 0.0)


def point_at(pts, s):
    for a, b in zip(pts, pts[1:]):
        ln = math.hypot(b[0] - a[0], b[1] - a[1])
        if s <= ln and ln > 0:
            return (a[0] + (b[0] - a[0]) * s / ln, a[1] + (b[1] - a[1]) * s / ln)
        s -= ln
    return pts[-1]


def turn_codes(value):
    """turn:lanes ("left|through;right|") as one arrow code per lane, left to right:
    "L", "T", "R" and their combinations ("TR", "LT", "LTR"); "" for no arrow."""
    out = []
    for lane in value.split("|"):
        parts = set(lane.split(";"))
        code = ""
        if parts & {"left", "slight_left", "sharp_left"}:
            code += "L"
        if "through" in parts:
            code += "T"
        if parts & {"right", "slight_right", "sharp_right"}:
            code += "R"
        out.append(code)
    return out if any(out) else None


def bus_lanes(t, suffix, n):
    """Indices (0 = leftmost) of the lanes kept for buses in one direction."""
    for key in ("bus:lanes", "psv:lanes"):
        v = t.get(key + suffix)
        if v:
            marks = v.split("|")
            return [i for i, m in enumerate(marks) if m == "designated"] if len(marks) == n else \
                [n - (len(marks) - i) for i, m in enumerate(marks) if m == "designated" and n - (len(marks) - i) >= 0]
    for key in ("lanes:bus", "lanes:psv"):
        c = num(t.get(key + suffix))
        if c and suffix != "" or (c and oneway_of(t) != 0):
            return list(range(max(0, n - int(c)), n))
    return []


JOIN_REACH = 60.0     # a lone stop line this close before a signalled junction joins its cycle
JOIN_NEAR = 25.0      # ...or this close to one of its nodes, either side
PAIR_REACH = 35.0     # lone stop lines this close together are one crossing
PORTAL_REACH = 260.0  # roads leaving the map join roads coming back within this, off the map


def dry_pois(pois, areas, roads):
    """Loop 3d-1: a point of interest the game sends the car to that stands in water (a square's
    or a park's centre in its fountain: Skwer Hoovera on Krakowskie Przedmieście) moves to the
    nearest road point (check_water 5d)."""
    water = []
    for a in areas:
        if a["k"] == "water":
            pts = list(zip(a["p"][0::2], a["p"][1::2]))
            xs, zs = [q[0] for q in pts], [q[1] for q in pts]
            water.append((min(xs), min(zs), max(xs), max(zs), pts))
    moved = []
    for p in pois:
        if "x" not in p or "z" not in p:
            continue
        x, z = p["x"], p["z"]
        if any(x0 <= x <= x1 and z0 <= z <= z1 and point_in_poly(x, z, pts) for x0, z0, x1, z1, pts in water):
            q = nearest_road_point(roads, x, z)
            p["x"], p["z"] = q["x"], q["z"]
            moved.append(p.get("name") or p["k"])
    print(f"pois: {len(moved)} in water moved to the nearest road point (loop 3d-1): {', '.join(moved)}")


def final_poles(out):
    """Loop 3d-1: the last word on poles, with check_streets S1's own test on the finished data
    (bake_roads clear_poles works on the roadbed before the carriageway strips are final): a
    lamp or signal pole still on the ground's asphalt moves to the nearest spot within
    bake_roads.POLE_FAR that S1 sees as off it; a lamp with none is left out."""
    import check_streets
    asphalt, raised = check_streets.pole_tests(out)

    def bad(x, z):
        return asphalt(x, z) and not raised(x, z)
    moved = dropped = 0
    for key, stride in (("lamps", 2), ("signals", 3)):
        v = out.get(key, [])
        keep = []
        for k in range(0, len(v) - stride + 1, stride):
            x, z = v[k], v[k + 1]
            if bad(x, z):
                spot = None
                r = 0.5
                while spot is None and r <= bake_roads.POLE_FAR:
                    for a in range(24):
                        px, pz = x + math.cos(a * math.pi / 12) * r, z + math.sin(a * math.pi / 12) * r
                        if not bad(px, pz) and not any(bad(px + math.cos(b * math.pi / 4) * bake_roads.POLE_CLEAR,
                                                           pz + math.sin(b * math.pi / 4) * bake_roads.POLE_CLEAR) for b in range(8)):
                            spot = (round(px, 1), round(pz, 1))
                            break
                    r += 0.5
                if spot is None and key == "lamps":
                    dropped += 1
                    continue
                if spot is not None:
                    v[k], v[k + 1] = spot
                    moved += 1
            keep.extend(v[k:k + stride])
        out[key] = keep
    print(f"poles (loop 3d-1): {moved} more moved off the asphalt as check_streets sees it, {dropped} lamps left out")


def bake_ped_zones(ways, nodes, rect):
    """Loop 3d-1: the pedestrian zones' polygons (PED_ZONES): [{"z": id, "p": flat ring}]."""
    out = []
    for zid, x0, z0, x1, z1, _ in PED_ZONES:
        for w in ways.values():
            t = w.get("tags", {})
            if t.get("highway") != "pedestrian" and t.get("area:highway") != "pedestrian" and t.get("place") != "square":
                continue
            ids = w.get("nodes", [])
            pts = [project(*nodes[i]) for i in ids if i in nodes]
            if len(pts) < 2:
                continue
            cx, cz = centroid(pts)
            if not (x0 <= cx <= x1 and z0 <= cz <= z1):
                continue
            closed = ids[0] == ids[-1] and len(pts) >= 4
            if closed and (t.get("area") == "yes" or t.get("place") == "square" or "area:highway" in t):
                ring = pts[:-1]
            elif t.get("highway") == "pedestrian":
                half = (num(t.get("width")) or PATHS["pedestrian"]) / 2 + PED_ZONE_PAD
                ring = bake_roads.offset_line(pts, half) + bake_roads.offset_line(pts, -half)[::-1]
            else:
                continue
            ring = clip_polygon(ring, rect)
            if len(ring) >= 3:
                out.append({"z": zid, "p": flat(ring)})
    print("ped_zones: " + ", ".join("%s %d polygons" % (z[0], sum(1 for o in out if o["z"] == z[0])) for z in PED_ZONES))
    return out


def bake_graph(els, nodes, ways, rect, signal_src, poles, bed=None, levels=None):
    """The lane graph the AI traffic and the rivals drive on.

    Drivable ways (no service roads, tunnels or private roads) are split wherever
    two of them share a node, clipped to the map, and turned into directed edges:
    one for a one-way road, two for a two-way road (Poland drives on the right).
    Each edge carries its lanes (count, width, offset of the first lane right of the
    centreline), its free-flow speed, and the stretch [s0, s1] its lanes use: the
    ends are cut back at junctions so cars turn on curves across the junction box.

    Traffic lights come from highway=traffic_signals nodes on the roads (Warsaw maps
    them on the stop lines, with traffic_signals:direction). Signal nodes close
    together form one junction controller with two groups of approaches (the two
    crossing axes); each edge gets the stop lines it passes. The signal poles drawn by
    the game get the controller and group whose colour they show.
    """
    levels = levels or {}
    picked = []
    for w in ways.values():
        t = w.get("tags", {})
        if t.get("highway") not in TRAFFIC_SPEED or t.get("area") == "yes":
            continue
        # Loop 3a (R4): tunnels (baked as tunnel pieces) and cuttings are in the graph;
        # building passages are not.
        if t.get("tunnel") == "building_passage" or (t.get("tunnel") == "yes" and levels.get(w["id"], ("",))[0] != "tn"):
            continue  # (loop 3b: short tunnels under a building, `is_passage`, are gates too)
        if t.get("access") in ("no", "private") or t.get("motor_vehicle") in ("no", "private"):
            continue
        ids = [i for i in w.get("nodes", []) if i in nodes]
        if len(ids) >= 2:
            picked.append((t, ids, w["id"]))

    use = {}
    for _, ids, _ in picked:
        for i in ids:
            use[i] = use.get(i, 0) + 1
    segments = []
    for t, ids, wid in picked:
        cur = [ids[0]]
        for k, i in enumerate(ids[1:], 1):
            cur.append(i)
            if use[i] > 1 or k == len(ids) - 1:
                segments.append((dict(t, _wid=wid, _first=ids[0], _last=ids[-1]), cur))
                cur = [i]

    # Clip to the map. Vertices keep their node id; points cut at the edge get none.
    pieces = []
    for t, ids in segments:
        pts = [project(*nodes[i]) for i in ids]
        cur = []
        for k in range(len(pts) - 1):
            a, b = pts[k], pts[k + 1]
            segs = clip_segments(a, b, rect)
            if not segs:
                if len(cur) >= 2:
                    pieces.append((t, cur))
                cur = []
                continue
            for seg in segs:
                pa = (seg[0][0], seg[0][1], ids[k] if math.dist(seg[0], a) < 1e-6 else None)
                pb = (seg[1][0], seg[1][1], ids[k + 1] if math.dist(seg[1], b) < 1e-6 else None)
                if cur and math.dist(cur[-1][:2], pa[:2]) > 1e-6:
                    if len(cur) >= 2:
                        pieces.append((t, cur))
                    cur = []
                if not cur:
                    cur = [pa]
                cur.append(pb)
                if pb[2] is None:
                    pieces.append((t, cur))
                    cur = []
        if len(cur) >= 2:
            pieces.append((t, cur))

    index, node_xz = {}, []

    def node_of(p):
        key = ("n", p[2]) if p[2] is not None else ("c", round(p[0], 1), round(p[1], 1))
        if key not in index:
            index[key] = len(node_xz)
            node_xz.append((p[0], p[1]))
        return index[key]

    def extents_of(t):
        """(left, right, cars' left, cars' right): the carriageway either side of the
        centreline, as the drawn road has it (measured under an area, else from tags)."""
        ext = bed.way_ext.get(t["_wid"]) if bed is not None else None
        if ext is None:
            w, bl, br = bake_roads.road_width(t)
            ext = (w / 2, w / 2, w / 2 - bl, w / 2 - br, bl, br)
            if ext[2] + ext[3] < 2.6:
                ext = (w / 2, w / 2, w / 2, w / 2, 0.0, 0.0)
        return ext

    def width_of(t):
        e = extents_of(t)
        return e[0] + e[1]

    degree, half_width = {}, {}
    ends = []
    for t, cur in pieces:
        a, b = node_of(cur[0]), node_of(cur[-1])
        ends.append((a, b))
        for n in (a, b):
            degree[n] = degree.get(n, 0) + 1
            half_width[n] = max(half_width.get(n, 0.0), width_of(t) / 2)

    def trim(n):
        if degree.get(n, 0) >= 3:
            return half_width[n] + 2.0
        return 1.5 if degree.get(n, 0) == 2 else 0.0

    edges, piece_edges, edge_pts = [], [], []
    for (t, cur), (a, b) in zip(pieces, ends):
        pts = [(p[0], p[1]) for p in cur]
        length = sum(math.dist(p, q) for p, q in zip(pts, pts[1:]))
        if length < 0.5:
            piece_edges.append([])
            continue
        _, _, cl, cr, _, _ = extents_of(t)
        width = cl + cr
        # Lanes narrower than a car would put cars off the drawn road (lane_split drops them).
        ow, nf, nb = bake_roads.lane_split(t, width)
        total = nf + nb if ow == 0 else nf
        lw = width / total
        speed = num(t.get("maxspeed"))
        speed = speed / 3.6 if speed else TRAFFIC_SPEED[t["highway"]]
        speed = max(4.0, min(speed, 22.0))
        made = []
        for forward in (True, False):
            if (forward and ow < 0) or (not forward and ow > 0):
                continue
            n = nf if forward else nb
            path = pts if forward else pts[::-1]
            na, nb_ = (a, b) if forward else (b, a)
            s0 = min(trim(na), 0.4 * length)
            s1 = length - min(trim(nb_), 0.4 * length)
            made.append((len(edges), forward))
            edge_pts.append(path)
            # The lanes fill the right-hand part of the carriageway (the way's right side
            # going forward, its left side going back), as the painted lines have them.
            right = cr if forward else cl
            if forward:
                turn = t.get("turn:lanes:forward") or (t.get("turn:lanes") if ow >= 0 else None)
                last = cur[-1][2] == t["_last"]
            else:
                turn = t.get("turn:lanes:backward") or (t.get("turn:lanes") if ow < 0 else None)
                last = cur[0][2] == t["_first"]
            suffix = "" if ow != 0 else (":forward" if forward else ":backward")
            edges.append({"a": na, "b": nb_, "p": flat(path), "k": t["highway"], "n": n,
                          "lw": round(lw, 2), "o": round(right - (n - 0.5) * lw, 2),
                          "v": round(speed, 1), "s0": round(s0, 2), "s1": round(s1, 2),
                          "name": t.get("name", ""), "br": 1 if t.get("bridge") not in (None, "no") else 0,
                          **({levels[t["_wid"]][0]: levels[t["_wid"]][1]} if t["_wid"] in levels else {}),
                          "_len": length, "_turn": turn_codes(turn) if turn else None, "_last": last,
                          "_bus": bus_lanes(t, suffix, n),
                          "_rb": t.get("junction") in ("roundabout", "circular")})
        piece_edges.append(made)

    # Off the map: a road that leaves the map joins the roads that come back in nearby
    # on the same side (the streets out there connect them). Cars can't drive these
    # "portals"; route planning can, and a rival that drives off the map comes back
    # through one. Without them the little Praga streets, which only meet the rest of
    # the network out east, would be a dead end.
    # Map north: the sides are the map's outline's (six for the box with its north extension).
    ring = rect.outline() if isinstance(rect, Shape) else [(rect[0], rect[1]), (rect[2], rect[1]), (rect[2], rect[3]), (rect[0], rect[3])]
    sides = [(ring[k - 1], ring[k]) for k in range(len(ring))]
    upright = [abs(a[0] - b[0]) < 1e-6 for a, b in sides]

    def rim_side(p):
        for side, (a, b) in enumerate(sides):
            if upright[side]:
                if abs(p[0] - a[0]) < 0.5 and min(a[1], b[1]) - 0.5 <= p[1] <= max(a[1], b[1]) + 0.5:
                    return side
            elif abs(p[1] - a[1]) < 0.5 and min(a[0], b[0]) - 0.5 <= p[0] <= max(a[0], b[0]) + 0.5:
                return side
        return -1

    outs_of, ins_of = {}, {}
    for i, e in enumerate(edges):
        outs_of.setdefault(e["a"], []).append(i)
        ins_of.setdefault(e["b"], []).append(i)
    exits, entries = [], []
    for i, e in enumerate(edges):
        if rim_side(node_xz[e["b"]]) >= 0 and not [f for f in outs_of.get(e["b"], []) if edges[f]["b"] != e["a"]]:
            exits.append(i)
        if rim_side(node_xz[e["a"]]) >= 0 and not [f for f in ins_of.get(e["a"], []) if edges[f]["a"] != e["b"]]:
            entries.append(i)
    portals = []
    for i in exits:
        p = node_xz[edges[i]["b"]]
        side = rim_side(p)
        near = []
        for j in entries:
            q = node_xz[edges[j]["a"]]
            if rim_side(q) != side:
                continue
            d = abs(p[1] - q[1]) if upright[side] else abs(p[0] - q[0])
            if d <= PORTAL_REACH:
                near.append((d, j))
        for d, j in sorted(near)[:3]:
            portals.append([i, j, round(d * 1.4 + 30.0, 1)])

    # The biggest strongly connected part: from any node in it a car can reach any
    # other, so rivals cruising and racing inside it never get stuck.
    out_edges = {}
    for i, e in enumerate(edges):
        out_edges.setdefault(e["a"], []).append(e["b"])   # loop 3b: tunnels are driven too
    for i, j, _ in portals:
        out_edges.setdefault(edges[i]["b"], []).append(edges[j]["a"])
    order, low, on_stack, stack, comps, counter = {}, {}, set(), [], [], [0]
    for root in range(len(node_xz)):
        if root in order:
            continue
        work = [(root, iter(out_edges.get(root, [])))]
        order[root] = low[root] = counter[0]
        counter[0] += 1
        stack.append(root)
        on_stack.add(root)
        while work:
            v, it = work[-1]
            advanced = False
            for w_ in it:
                if w_ not in order:
                    order[w_] = low[w_] = counter[0]
                    counter[0] += 1
                    stack.append(w_)
                    on_stack.add(w_)
                    work.append((w_, iter(out_edges.get(w_, []))))
                    advanced = True
                    break
                elif w_ in on_stack:
                    low[v] = min(low[v], order[w_])
            if advanced:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[v])
            if low[v] == order[v]:
                comp = []
                while True:
                    x = stack.pop()
                    on_stack.discard(x)
                    comp.append(x)
                    if x == v:
                        break
                comps.append(comp)
    biggest = set(max(comps, key=len)) if comps else set()

    # Signal nodes on the graph, and where each sits along the edges through it.
    sig_els = json.load(open(signal_src, encoding="utf-8"))["elements"] if signal_src else els
    signals = {e["id"]: e.get("tags", {}).get("traffic_signals:direction") for e in sig_els
               if e["type"] == "node" and e.get("tags", {}).get("highway") == "traffic_signals"}
    sig_at = {}  # node id -> [(edge, s)]
    for (t, cur), made in zip(pieces, piece_edges):
        if not made:
            continue
        pts = [(p[0], p[1]) for p in cur]
        length = edges[made[0][0]]["_len"]
        s = 0.0
        for k, p in enumerate(cur):
            if k > 0:
                s += math.dist(pts[k - 1], pts[k])
            if p[2] in signals:
                for ei, forward in made:
                    rule = signals[p[2]]
                    if (rule == "forward" and not forward) or (rule == "backward" and forward):
                        continue
                    sig_at.setdefault(p[2], []).append((ei, s if forward else length - s))
    sig_ids = sorted(sig_at)
    sig_xz = [project(*nodes[i]) for i in sig_ids]

    # The junction a stop line protects: walk downstream past plain way joins to the
    # first node where three or more roads meet (none within reach: a crossing light).
    node_out_e = {}
    for i, e in enumerate(edges):
        node_out_e.setdefault(e["a"], []).append(i)

    def protects(ei, s):
        dist, e = edges[ei]["_len"] - s, ei
        for _ in range(12):
            n = edges[e]["b"]
            if degree.get(n, 0) >= 3:
                return n, dist
            nxt = [f for f in node_out_e.get(n, []) if edges[f]["b"] != edges[e]["a"]]
            if dist > JUNCTION_REACH or len(nxt) != 1:
                break
            e = nxt[0]
            dist += edges[e]["_len"]
        return None, dist

    # Stop lines: (edge, s, signal index, junction node or None).
    cand = []
    for i, sid in enumerate(sig_ids):
        mine = []
        for ei, s in sig_at[sid]:
            if s < 0.5:
                continue  # just past the light: leaving the junction
            n, dist = protects(ei, s)
            mine.append((ei, s, i, n if dist <= JUNCTION_REACH else None))
        # An untagged light on a two-way road: only the side heading into a junction
        # stops; with no junction near, it is a crossing light for both directions.
        if signals[sid] is None and any(m[3] is not None for m in mine):
            mine = [m for m in mine if m[3] is not None]
        cand += mine

    # A lone stop line just before a signalled junction (the walk downstream gave up at a
    # fork or a long link) belongs to that junction's cycle, not a crossing of its own.
    signalled = sorted({c[3] for c in cand if c[3] is not None})
    joined = 0
    for k, (ei, s, i, n) in enumerate(cand):
        if n is not None:
            continue
        p = point_at(edge_pts[ei], s)
        d = heading_at(edge_pts[ei], s)
        best = None
        for m in signalled:
            q = node_xz[m]
            dist = math.dist(p, q)
            ahead = (q[0] - p[0]) * d[0] + (q[1] - p[1]) * d[1]
            # Ahead of it, or right at it (a light just past one node of a junction that
            # spreads over several, like a dual carriageway or a big roundabout).
            if (dist <= JOIN_NEAR or (dist <= JOIN_REACH and ahead > -5.0)) and (best is None or dist < best[0]):
                best = (dist, m)
        if best is not None:
            cand[k] = (ei, s, i, best[1])
            joined += 1

    # Lone stop lines close together (both directions of one crossing) share one light.
    lone = [k for k, c in enumerate(cand) if c[3] is None]
    lone_parent = {k: k for k in lone}

    def lone_find(k):
        while lone_parent[k] != k:
            lone_parent[k] = lone_parent[lone_parent[k]]
            k = lone_parent[k]
        return k

    for a_, ka in enumerate(lone):
        pa = point_at(edge_pts[cand[ka][0]], cand[ka][1])
        for kb in lone[a_ + 1:]:
            pb = point_at(edge_pts[cand[kb][0]], cand[kb][1])
            if math.dist(pa, pb) <= PAIR_REACH:
                lone_parent[lone_find(ka)] = lone_find(kb)

    # Junction nodes close together (a dual carriageway crossing another) are one
    # junction with one controller; a crossing light is its own.
    junctions = sorted({c[3] for c in cand if c[3] is not None})
    parent = {n: n for n in junctions}

    def find(n):
        while parent[n] != n:
            parent[n] = parent[parent[n]]
            n = parent[n]
        return n

    for i, a in enumerate(junctions):
        for b in junctions[i + 1:]:
            if math.dist(node_xz[a], node_xz[b]) < SIGNAL_CLUSTER:
                parent[find(a)] = find(b)
    clusters = {}
    for k, (ei, s, i, n) in enumerate(cand):
        key = ("j", find(n)) if n is not None else ("s", cand[lone_find(k)][2])
        clusters.setdefault(key, []).append((ei, s, i))

    rank = ["motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential", "living_street"]
    controllers, sig_ctrl, stops = [], {}, {}
    for key, members in clusters.items():
        if key[0] == "j":
            group_nodes = [n for n in junctions if find(n) == key[1]]
            cx = sum(node_xz[n][0] for n in group_nodes) / len(group_nodes)
            cz = sum(node_xz[n][1] for n in group_nodes) / len(group_nodes)
        else:
            cx, cz = sig_xz[key[1]]
        lines = [(ei, s, i, math.atan2(*heading_at(edge_pts[ei], s)[::-1])) for ei, s, i in members]
        lead = min(lines, key=lambda c: (rank.index(edges[c[0]]["k"].replace("_link", "")) if edges[c[0]]["k"].replace("_link", "") in rank else 9, -edges[c[0]]["_len"]))
        axis = lead[3]
        # A signalled roundabout entry: the ring and the road coming in take turns,
        # whatever their headings.
        ring = {ei for ei, _, _, _ in lines if edges[ei]["_rb"]}
        by_ring = 0 < len(ring) < len({ei for ei, _, _, _ in lines})
        ci = len(controllers)
        groups = set()
        best = {}
        for ei, s, i, ang in lines:
            d = abs((ang - axis + math.pi / 2) % math.pi - math.pi / 2)
            g = 0 if d < math.pi / 4 else 1
            if by_ring:
                g = 1 if ei in ring else 0
            groups.add(g)
            if ei not in best or s < best[ei][0]:
                best[ei] = (s, g)
            sig_ctrl[i] = ci
        for ei, (s, g) in best.items():
            stops.setdefault(ei, []).append([round(min(s, edges[ei]["s1"]), 2), ci, g])
        controllers.append([round(cx, 1), round(cz, 1), len(groups), round(axis, 3)])

    pole_out = []
    for k in range(0, len(poles) - 2, 3):
        px, pz, yaw = poles[k], poles[k + 1], poles[k + 2]
        best = None
        for i, (sx, sz) in enumerate(sig_xz):
            d = math.hypot(sx - px, sz - pz)
            if i in sig_ctrl and d < 16.0 and (best is None or d < best[0]):
                best = (d, sig_ctrl[i])
        if best is None:
            pole_out += [-1, 0]
            continue
        c = controllers[best[1]]
        ang = math.atan2(-math.cos(yaw), -math.sin(yaw))
        d = abs((ang - c[3] + math.pi / 2) % math.pi - math.pi / 2)
        pole_out += [best[1], 0 if d < math.pi / 4 or c[2] == 1 else 1]

    for i, e in enumerate(edges):
        if i in stops:
            e["st"] = sorted(stops[i])
        del e["_len"]
    print(f"graph: {len(node_xz)} nodes ({len(biggest)} connected), {len(edges)} directed edges, "
          f"{len(portals)} off-map links, {len(controllers)} signal controllers "
          f"({sum(1 for c in controllers if c[2] == 1)} single-axis; {joined} lone stop lines joined a junction), "
          f"{sum(len(v) for v in stops.values())} stop lines, "
          f"{sum(1 for k in range(0, len(pole_out), 2) if pole_out[k] >= 0)} of {len(pole_out) // 2} poles lit")
    return {
        "nodes": [round(v, 1) for p in node_xz for v in p],
        "scc": [1 if n in biggest else 0 for n in range(len(node_xz))],
        "edges": edges,
        "ctrl": controllers,
        "poles": pole_out,
        "portals": portals,
    }


CAR_COLOURS = 10  # the game's parked-car palette size
PARKED_FILL = 0.27  # share of car-park bays with a car (the user, 2026-10-30: about a third of the old 0.8)


def bake_extras(src, roads, rect):
    """Street lamps, traffic-light poles beside the road, and cars parked in surface car parks."""
    els = json.load(open(src, encoding="utf-8"))["elements"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    ways = {e["id"]: e for e in els if e["type"] == "way"}

    segs = []
    for r in roads:
        p = list(zip(r["p"][0::2], r["p"][1::2]))
        for a, b in zip(p, p[1:]):
            segs.append((a, b, r["w"], r["k"], r.get("c", 0.0)))
    cell = 25.0
    grid = {}
    for k, (a, b, _, _, _) in enumerate(segs):
        for gi in range(int(min(a[0], b[0]) // cell) - 1, int(max(a[0], b[0]) // cell) + 2):
            for gj in range(int(min(a[1], b[1]) // cell) - 1, int(max(a[1], b[1]) // cell) + 2):
                grid.setdefault((gi, gj), []).append(k)

    def nearest_seg(x, z, kinds=None):
        best = None
        for k in grid.get((int(x // cell), int(z // cell)), []):
            a, b, w, kind, c = segs[k]
            if kinds and kind not in kinds:
                continue
            dx, dz = b[0] - a[0], b[1] - a[1]
            ln = dx * dx + dz * dz
            if ln == 0:
                continue
            u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
            d = math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)
            if best is None or d < best[0]:
                best = (d, a, b, w, c)
        return best

    lamps, signals = [], []
    for e in els:
        t = e.get("tags", {})
        if e["type"] != "node" or not in_bbox(e["lat"], e["lon"]):
            continue
        x, z = project(e["lat"], e["lon"])
        if t.get("highway") == "street_lamp":
            lamps += [round(x, 1), round(z, 1)]
        elif t.get("highway") == "traffic_signals":
            hit = nearest_seg(x, z, set(DRIVABLE) - {"service"})
            if not hit or hit[0] > 12:
                continue
            _, a, b, w, c = hit
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            dx, dz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            yaw = math.atan2(-dx, -dz)
            for side in (-1, 1):
                # Beside the kerb: the carriageway is `w` wide around the centreline + c.
                px = x + -dz * (c + side * (w / 2 + 0.9))
                pz = z + dx * (c + side * (w / 2 + 0.9))
                if all(math.hypot(px - signals[i], pz - signals[i + 1]) > 3 for i in range(0, len(signals), 3)):
                    signals += [round(px, 1), round(pz, 1), round(yaw, 2)]

    cars = []
    lots = []
    for w in ways.values():
        t = w.get("tags", {})
        ids = w.get("nodes", [])
        if t.get("amenity") == "parking" and ids and ids[0] == ids[-1]:
            lots.append((t, [project(*nodes[i]) for i in ids[:-1] if i in nodes]))
    for r in (e for e in els if e["type"] == "relation" and e.get("tags", {}).get("amenity") == "parking"):
        outer = [ways[m["ref"]]["nodes"] for m in r.get("members", []) if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways]
        for ring in stitch(outer):
            lots.append((r["tags"], [project(*nodes[i]) for i in ring[:-1] if i in nodes]))
    for t, poly in lots:
        if t.get("parking", "surface") not in ("surface", "street_side", "lane") or len(poly) < 3:
            continue
        if abs(ring_area(poly)) < 60 or not inside(rect, *centroid(poly)):
            continue
        # Rows run along the lot's longest side: a double row of 5 m bays, then a 6 m aisle.
        a, b = max(((poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly))),
                   key=lambda e: math.hypot(e[1][0] - e[0][0], e[1][1] - e[0][1]))
        ln = math.hypot(b[0] - a[0], b[1] - a[1])
        ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
        vx, vz = -uz, ux
        us = [(p[0] - a[0]) * ux + (p[1] - a[1]) * uz for p in poly]
        vs = [(p[0] - a[0]) * vx + (p[1] - a[1]) * vz for p in poly]
        v = min(vs) + 2.5
        row = 0
        while v < max(vs) - 2.5:
            u = min(us) + 1.25
            while u < max(us) - 1.25:
                cx, cz = a[0] + ux * u + vx * v, a[1] + uz * u + vz * v
                corners = [(cx + ux * du + vx * dv, cz + uz * du + vz * dv) for du in (-1.1, 1.1) for dv in (-2.3, 2.3)]
                h = (math.sin(cx * 3.1 + cz * 1.7) * 43758.5453) % 1.0
                near = nearest_seg(cx, cz)
                clear = near is None or near[0] > near[3] / 2 + 1.3
                # Map north (tools/check_outline.py O4): and on the map: a lot across the map's edge
                # put cars up to 70 m past it, over nothing (the lot's centre is on the map).
                if h < PARKED_FILL and clear and all(point_in_poly(px, pz, poly) and inside(rect, px, pz) for px, pz in corners):
                    yaw = math.atan2(-vx, -vz) + (math.pi if row % 2 else 0.0)
                    cars += [round(cx, 1), round(cz, 1), round(yaw, 2), int(h * 1000) % CAR_COLOURS]
                u += 2.5
            row += 1
            v += 5.0 if row % 2 else 11.0
    print(f"extras: lamps {len(lamps) // 2} signal poles {len(signals) // 3} parked cars {len(cars) // 4} in {len(lots)} lots")
    return {"lamps": lamps, "signals": signals, "parked": cars}


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None,
         sys.argv[5] if len(sys.argv) > 5 else None)
