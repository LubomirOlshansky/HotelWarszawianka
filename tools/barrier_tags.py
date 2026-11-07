"""Walls, fences and hedges from the map's own data (F, 2026-11-07, after the stairs: "what else can
you improve in the city environment?"). Every OSM wall stood 1.9 m high in one beige, every fence
was a solid 1.6 m grey band and the Old Town's city walls were not on the map at all. OpenStreetMap
maps more than that; this copies it onto centrum.json's `lines`, and adds the city walls.

    python3 -I tools/barrier_tags.py tags [MAP.json] [--osm data/raw/stairs/barriers_osm.json]
        on every wall, fence and hedge in `lines` that matches an OSM barrier (idempotent):
        h   height in metres (OSM height)
        m   material: brick, stone, concrete, gabion, glass, wood, metal, noise (a noise barrier)
        ft  fence type: railing (railing, bars, balustrade, metal), mesh (chain link, wire), wood
        and `citywalls`: the Old Town's defence walls (OSM barrier=city_wall areas, brick, their
        mapped height or CITY_WALL_H), drawn by map_builder.gd as brick walls.
        After it, re-run tools/bake_street_details.py and tools/bake_park_details.py (their stamps
        follow centrum.json, or the quick checks go red).
    python3 -I tools/barrier_tags.py --check [MAP.json]
        exit 1 unless the map carries the barrier tags and the city walls (verify step `stairs`).

bake_osm.py calls barrier_fields() and city_wall() for a full re-bake. The OSM extract
(data/raw/stairs/barriers_osm.json, gitignored) is made on the Mac from the demo export: every
barrier=hedge/fence/wall/retaining_wall/city_wall way with its tags and node coordinates.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import stairs as S  # noqa: E402  (projection, matching helpers)

ROOT = S.ROOT
MAP = S.MAP
OSM = os.path.join(ROOT, "data", "raw", "stairs", "barriers_osm.json")
CITY_WALL_H = 5.0     # the Old Town's walls where OSM maps no height (the rebuilt curtain walls: 4-6 m)
MATCH = 0.6
KINDS = {"wall": "wall", "retaining_wall": "wall", "fence": "fence", "hedge": "hedge"}


def material(t):
    """The compact material of a barrier's tags, or None."""
    if t.get("wall") == "noise_barrier":
        return "noise"
    if t.get("wall") == "gabion":
        return "gabion"
    m = t.get("material") or t.get("wall") or ""
    return {"brick": "brick", "stone": "stone", "granite": "stone", "masonry": "stone",
            "concrete": "concrete", "reinforced_concrete": "concrete", "glass": "glass",
            "wood": "wood", "metal": "metal", "steel": "metal", "aluminium": "metal"}.get(m)


def fence_type(t):
    ft = t.get("fence_type", "")
    if ft in ("railing", "bars", "balustrade", "metal", "metal_bars", "post_and_rail"):
        return "railing"
    if ft in ("chain_link", "wire"):
        return "mesh"
    if ft in ("wood", "wood_panel"):
        return "wood"
    if material(t) == "metal":
        return "railing"
    if material(t) == "wood":
        return "wood"
    return None


def barrier_fields(t):
    """The extra fields for one OSM barrier way's `lines` item."""
    out = {}
    kind = KINDS.get(t.get("barrier"))
    h = S.num(t.get("height"))
    if h is not None and 0.1 <= h <= 8.0:
        out["h"] = round(h, 2)
    m = material(t)
    if m and kind == "wall":
        out["m"] = m
    if kind == "fence":
        ft = fence_type(t)
        if ft:
            out["ft"] = ft
    return out


def city_wall(t, ring):
    """A `citywalls` item for an OSM city_wall area (its outline), or None."""
    if len(ring) < 4 or math.dist(ring[0], ring[-1]) > 0.5:
        return None
    h = S.num(t.get("height"))
    h = round(h, 2) if h is not None and 0.5 <= h <= 20.0 else CITY_WALL_H
    return {"p": [round(c, 1) for q in ring[:-1] for c in q], "h": h, "name": t.get("name", "")}


def apply(d, barriers):
    lines = d.get("lines", [])
    osm = [(b, [S.project(*g) for g in b["g"] if g]) for b in barriers]
    osm = [(b, p) for b, p in osm if len(p) >= 2 and b["tags"].get("barrier") in KINDS]
    grid = S.Grid([p for _, p in osm])
    tagged = 0
    for l in lines:
        if l.get("k") not in ("wall", "fence", "hedge"):
            continue
        for k in ("h", "m", "ft"):
            l.pop(k, None)
        p = S.pairs(l["p"])
        best = (MATCH, None)
        for i in grid.near(p[0]) | grid.near(p[-1]):
            b, bp = osm[i]
            if KINDS[b["tags"]["barrier"]] != l["k"]:
                continue
            ds = [S.poly_dist(q, bp)[0] for q in S.dense(p, 1.0)]
            m = sum(ds) / len(ds)
            if m < best[0]:
                best = (m, i)
        if best[1] is not None:
            f = barrier_fields(osm[best[1]][0]["tags"])
            l.update(f)
            tagged += bool(f)
    bounds = d.get("bounds", [-1e9, -1e9, 1e9, 1e9])
    walls = []
    for b in barriers:
        if b["tags"].get("barrier") != "city_wall":
            continue
        ring = [S.project(*g) for g in b["g"] if g]
        if not ring or not all(bounds[0] <= q[0] <= bounds[2] and bounds[1] <= q[1] <= bounds[3] for q in ring):
            continue
        cw = city_wall(b["tags"], ring)
        if cw:
            walls.append(cw)
    d["citywalls"] = walls
    return tagged, len(walls)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = {a.split("=")[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv if a.startswith("--")}
    path = args[1] if len(args) > 1 else MAP
    if "--check" in opt:
        path = args[0] if args else MAP
        d = json.load(open(path, encoding="utf-8"))
        tagged = sum(1 for l in d.get("lines", []) if any(k in l for k in ("h", "m", "ft")))
        ok = tagged >= 500 and len(d.get("citywalls", [])) >= 10
        print("barrier_tags: %s (%d barriers tagged, %d city walls)" % ("OK" if ok else "FAIL", tagged, len(d.get("citywalls", []))))
        return 0 if ok else 1
    if not args or args[0] != "tags":
        print(__doc__)
        return 2
    d = json.load(open(path, encoding="utf-8"))
    barriers = json.load(open(opt.get("--osm", OSM), encoding="utf-8"))["barriers"]
    tagged, cw = apply(d, barriers)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, separators=(",", ":"), ensure_ascii=False)
    print("barrier_tags: %d barriers tagged, %d city walls" % (tagged, cw))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
