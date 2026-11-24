#!/usr/bin/env python3
"""Take the street fronts off party walls in game/data/photo_fronts.json.

    python3 -I tools/photo_fronts_party.py            rewrite photo_fronts.json without them
    python3 -I tools/photo_fronts_party.py --check    exit 1 when one is left (verify step `photofronts`)

F, 2026-11-22 (a phone screenshot on Krakowskie Przedmieście by Holy Cross: "what is this wall
sticking up?"): a flat 0.3 m slab 27 m tall with windows stood over the roofs of Krakowskie
Przedmieście 14 and 16/18. Both houses had a "street front" (fronts.gd `_pf_front`: a wall box
with windows, sills and a cornice, drawn 0.12-0.28 m out of its outline edge) on the wall they
share, 31.4 m tall where the houses are 15-21 m. A front on a party wall is never a street front:
when the neighbour is as tall it hides inside it, when it is lower its windows show on what is
really a blank wall, and when the front is taller than both houses it is the free slab F saw.
The fronts were read from photos and Mapillary per outline edge (2026-11-06 to -08) without
looking at what stands on the edge's other side: 434 of the 1245 fronts in 289 houses faced
straight into another building.

A front is on a party wall when the point PROBE m out from the middle of its edge (the side the
front faces, fronts.gd `_b`) lies inside another building's outline (game/map/centrum.json
`buildings`) that is MIN_NEIGHBOUR_H m tall or more. A lower neighbour (a one-storey shop, a
garage, a kiosk built against a house) leaves the front: the house's street front shows over it.
A building mapped twice (the same outline, a building part) is on both sides of the edge, never
only outside, so its fronts stay. The house keeps its LoD2 mass in its plaster there (the site's
skin), as every edge without a front does. Standard library only; reads only committed files.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FRONTS = ROOT / "game" / "data" / "photo_fronts.json"
MAP = ROOT / "game" / "map" / "centrum.json"
PROBE = 1.0            # m out of the front's edge
MIN_NEIGHBOUR_H = 8.0  # m, a neighbour this tall makes the edge a party wall
CELL = 32.0            # m, the outline index's cells


def point_in_poly(x, z, p):
    inside = False
    n = len(p) // 2
    j = n - 1
    for i in range(n):
        xi, zi, xj, zj = p[2 * i], p[2 * i + 1], p[2 * j], p[2 * j + 1]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            inside = not inside
        j = i
    return inside


def index_buildings(buildings):
    cells = {}
    for k, b in enumerate(buildings):
        p = b["p"]
        if len(p) < 6 or float(b.get("h", 0.0)) < MIN_NEIGHBOUR_H:
            continue
        xs, zs = p[0::2], p[1::2]
        for gx in range(int(min(xs) // CELL), int(max(xs) // CELL) + 1):
            for gz in range(int(min(zs) // CELL), int(max(zs) // CELL) + 1):
                cells.setdefault((gx, gz), []).append(k)
    return cells


def party_wall(front, buildings, cells):
    """The index of the building the front faces into, or None."""
    (ax, az), (bx, bz) = front["a"], front["b"]
    dx, dz = bx - ax, bz - az
    length = (dx * dx + dz * dz) ** 0.5
    if length < 0.01:
        return None
    # fronts.gd: _a = (b - a) normalised, _b = (-_a.y, _a.x) is out of the front.
    ox, oz = -dz / length, dx / length
    x, z = (ax + bx) * 0.5 + ox * PROBE, (az + bz) * 0.5 + oz * PROBE
    for k in cells.get((int(x // CELL), int(z // CELL)), ()):
        if point_in_poly(x, z, buildings[k]["p"]):
            return k
    return None


def main(argv):
    check = "--check" in argv
    text = FRONTS.read_text(encoding="utf-8")
    houses = json.loads(text)
    buildings = json.loads(MAP.read_text(encoding="utf-8"))["buildings"]
    cells = index_buildings(buildings)
    found = []
    for d in houses:
        keep = []
        for f in d["fronts"]:
            k = party_wall(f, buildings, cells)
            if k is None:
                keep.append(f)
            else:
                found.append((d["id"], d["name"], f, k))
        d["fronts"] = keep
    total = sum(len(d["fronts"]) for d in houses) + len(found)
    houses_hit = len({h for h, _, _, _ in found})
    if check:
        for h, name, f, k in found[:20]:
            print(f"  {h} {name}: front {f['a']} -> {f['b']} ({f['h']} m) faces into building {k}")
        state = "OK" if not found else f"{len(found)} fronts on party walls in {houses_hit} houses"
        print(f"photo_fronts_party: {state} ({total} fronts in {len(houses)} houses)")
        return 0 if not found else 1
    out = json.dumps(houses, separators=(",", ":"), ensure_ascii=False)
    if out != text:
        FRONTS.write_text(out, encoding="utf-8")
    print(f"photo_fronts_party: took {len(found)} fronts off party walls in {houses_hit} houses "
          f"({total - len(found)} of {total} fronts left)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
