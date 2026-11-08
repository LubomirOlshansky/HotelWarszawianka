"""Guessed heights for small OpenStreetMap buildings (F, 2026-11-07: "revise all the thin blocks
across the map, categorise what they are, rework or remove").

    python3 -I tools/building_heights.py [MAP.json] [--dry] [--list]
        rewrites the map in place (idempotent: a building already guessed is left alone);
        --dry counts and changes nothing; --list prints every thin stand-alone block left
        (index, centre x z, height, footprint, kind) with its category.
    python3 -I tools/building_heights.py --check [MAP.json]
        exit 1 if a small building still stands at the old 14 m guess (verify.sh step `heights`).

Why. bake_osm.make_building gave every building with neither `height` nor `building:levels` a
flat 14 m, a four-storey block. On a tenement that is a fair guess; on a 12 m² metro lift
housing, a kiosk, a garden shed or a tram stop's ticket booth it stood up as a thin windowed
tower (F's crop: two at Ratusz-Arsenał, by the tram stop on Solidarności, OSM `building=service`
lift housings of 12 m², x -1517 z -1162). 929 buildings had the guess; 448 of them under 40 m².
LoD2 (GUGiK) replaces most big ones, not these: no LoD2 footprint there, so they stay OSM.

What. `default_height(kind, area)` is the guess for a building with no height tags: by its kind
first (KIND_HEIGHTS: kiosks, sheds, garages, lift housings, booths, boats ...) while it is under
KIND_AREA m², then by its footprint (under 40 m² one storey, under 100 m² two), else 14 m as
before. bake_osm.make_building calls it, and this file applies the same rule to a baked map
(the cloud has no OpenStreetMap download): a building at exactly 14.0 m (the old guess) with a
footprint under 150 m² gets the new guess. Tagged heights are kept, even thin ones (pillars under
a raised floor, chimneys, a tagged 10 m industrial shed): they are real.
"""
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP = os.path.join(ROOT, "game", "map", "centrum.json")

OLD_GUESS = 14.0
# Metres for a small building of this `building=` kind with no height tags (one storey and a roof
# or less; a boat sits low on the water).
KIND_HEIGHTS = {
    "kiosk": 3.2, "toilets": 3.2, "guardhouse": 3.2, "gatehouse": 4.5, "booth": 3.0,
    "ticket_booth": 3.0, "garbage_shed": 2.5, "shed": 2.8, "hut": 2.8, "cabin": 3.2,
    "carport": 2.8, "garage": 3.0, "garages": 3.0, "roof": 4.0, "elevator": 4.5,
    "elevator_housing": 4.5, "elvator_housing": 4.5, "service": 4.0, "kiosk;yes": 3.2,
    "houseboat": 3.5, "boat": 2.5, "boathouse": 4.5, "bunker": 3.0, "summer_house": 3.5,
    "container": 2.6, "pavilion": 4.5, "outbuilding": 4.5, "storage_tank": 6.0,
}
KIND_AREA = 150.0   # a kind guess only under this footprint (a big "service" hall is no booth)
ONE_STOREY = 40.0   # m² under which an untagged building of any other kind is one storey
TWO_STOREYS = 100.0  # ... and two
MIGRATE_AREA = 150.0  # this file only touches 14.0 m buildings under this footprint
THIN = 6.0          # --list: a block this narrow (or under 80 m²) ...
TALL = 9.0          # ... and this tall is a "thin tower"


def default_height(kind, area):
    """The guessed height (m) of a building with neither height nor building:levels."""
    kind = (kind or "").lower()
    if kind in KIND_HEIGHTS and area < KIND_AREA:
        return KIND_HEIGHTS[kind]
    if area < ONE_STOREY:
        return 3.5
    if area < TWO_STOREYS:
        return 6.6
    return OLD_GUESS


def area_of(flat):
    """Footprint area (m²) of a flat [x, z, x, z ...] ring."""
    n = len(flat) // 2
    a = 0.0
    for i in range(n):
        j = (i + 1) % n
        a += flat[2 * i] * flat[2 * j + 1] - flat[2 * j] * flat[2 * i + 1]
    return abs(a) / 2.0


def min_width(flat):
    """The narrowest width (m) of a ring, over its edge directions (a rotating-callipers guess)."""
    pts = [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]
    best = math.inf
    for i in range(len(pts)):
        ax, az = pts[i]
        bx, bz = pts[(i + 1) % len(pts)]
        length = math.hypot(bx - ax, bz - az)
        if length < 0.3:
            continue
        ux, uz = (bx - ax) / length, (bz - az) / length
        across = [(x - ax) * -uz + (z - az) * ux for x, z in pts]
        best = min(best, max(across) - min(across))
    return best if best < math.inf else 0.0


def stale(b):
    """Whether a baked building still carries the old 14 m guess where the new rule differs."""
    if b.get("h") != OLD_GUESS or b.get("mh", 0.0) > 0.0:
        return False
    area = area_of(b["p"])
    return area < MIGRATE_AREA and default_height(b.get("kind", ""), area) != OLD_GUESS


USES_FILE = os.path.join(ROOT, "game", "data", "small_buildings.json")
# Uses small_buildings.gd draws (LOOK there); "part" and "none" are left out of the map.
USES = {"lift", "metro_vent", "metro_vent_tower", "metro_entrance_roof", "kiosk", "pavilion",
        "bin_shelter", "substation", "toilet", "guard_booth", "ticket_booth", "garage", "shed",
        "canopy", "bus_tram_shelter", "houseboat", "boathouse", "chapel_shrine",
        "monument_structure", "staircase_or_lift_head", "historic", "unknown", "part", "none"}
# Heights (m) for a researched use when no height was seen (small_buildings.gd LOOK keeps the same).
USE_HEIGHTS = {"lift": 3.6, "metro_vent": 4.0, "metro_vent_tower": 5.5, "metro_entrance_roof": 3.2,
               "kiosk": 2.8, "pavilion": 3.6, "bin_shelter": 2.0, "substation": 2.7, "toilet": 2.8,
               "guard_booth": 2.6, "ticket_booth": 2.6, "garage": 2.5, "shed": 2.6, "canopy": 3.0,
               "bus_tram_shelter": 2.6, "houseboat": 3.2, "boathouse": 4.2, "chapel_shrine": 3.5,
               "monument_structure": 3.0, "staircase_or_lift_head": 3.2, "historic": 4.0, "unknown": 3.0}
MATCH = 1.0  # m: a researched row names the building whose outline's centre is this close


def centre(flat):
    xs, zs = flat[0::2], flat[1::2]
    return sum(xs) / len(xs), sum(zs) / len(zs)


def researched(out, path=USES_FILE):
    """{building index: row} for the rows of small_buildings.json, matched by outline centre."""
    try:
        with open(path, encoding="utf-8") as f:
            rows = json.load(f)["buildings"]
    except OSError:
        return {}, []
    grid = {}
    for i, b in enumerate(out.get("buildings", [])):
        if len(b["p"]) < 6:
            continue
        x, z = centre(b["p"])
        grid.setdefault((int(x // 10), int(z // 10)), []).append((x, z, i))
    found, missing = {}, []
    for r in rows:
        best = None
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for x, z, i in grid.get((int(r["x"] // 10) + dx, int(r["z"] // 10) + dz), []):
                    d = math.hypot(x - r["x"], z - r["z"])
                    if d < MATCH and (best is None or d < best[0]):
                        best = (d, i)
        if best is None:
            missing.append(r)
        else:
            found[best[1]] = r
    return found, missing


def apply(out):
    """Re-guess the stale buildings of a baked map in place and write each researched one's use
    (`u`) and seen height; returns a one-line summary."""
    changed = 0
    for b in out.get("buildings", []):
        if stale(b):
            b["h"] = default_height(b.get("kind", ""), area_of(b["p"]))
            changed += 1
    found, missing = researched(out)
    for i, r in found.items():
        b = out["buildings"][i]
        b["u"] = r["u"]
        if "h" in r:
            b["h"] = float(r["h"])
        elif r["u"] in USE_HEIGHTS:
            b["h"] = USE_HEIGHTS[r["u"]]
    return (f"{changed} small buildings lowered from the old {OLD_GUESS:.0f} m guess, "
            f"{len(found)} researched uses written ({len(missing)} rows not found)")


def category(b, area, width):
    """Why a thin block left on the map is that tall (for --list)."""
    h = b["h"] - b.get("mh", 0.0)
    if b.get("mh", 0.0) > 0.0 and width < 2.5:
        return "pillar under a raised floor (tagged, real)"
    if b["h"] == OLD_GUESS:
        return "old 14 m guess, over the migrate area"
    if width < 2.0 and area < 6.0:
        return "column or chimney (tagged)"
    if h >= 20.0:
        return "tagged tall part (tower, stair core, silo)"
    return "tagged height (real)"


def thin_list(out):
    """[(index, x, z, h, area, width, kind, category)] of every thin tall OSM building."""
    rows = []
    for i, b in enumerate(out.get("buildings", [])):
        if b.get("br") or b.get("cutd") or len(b["p"]) < 6:
            continue
        h = b["h"] - b.get("mh", 0.0)
        if h < TALL:
            continue
        area = area_of(b["p"])
        width = min_width(b["p"])
        if not (area <= 80.0 or width <= THIN) or h / max(width, 0.5) < 1.6:
            continue
        xs, zs = b["p"][0::2], b["p"][1::2]
        rows.append((i, round(sum(xs) / len(xs)), round(sum(zs) / len(zs)), b["h"], round(area),
                     round(width, 1), b.get("kind", ""), category(b, area, width)))
    return rows


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else MAP
    with open(path, encoding="utf-8") as f:
        out = json.load(f)
    if "--check" in argv:
        left = [i for i, b in enumerate(out.get("buildings", [])) if stale(b)]
        if left:
            print(f"building_heights: FAIL · {len(left)} small buildings at the old 14 m guess "
                  f"(first: {left[:5]}); run python3 -I tools/building_heights.py")
            return 1
        found, missing = researched(out)
        bad = [r for r in found.values() if r["u"] not in USES]
        unwritten = [i for i, r in found.items() if out["buildings"][i].get("u") != r["u"]]
        if missing or bad or unwritten:
            print(f"building_heights: FAIL · {len(missing)} researched rows match no building, "
                  f"{len(bad)} unknown uses, {len(unwritten)} uses not written (run the tool)")
            return 1
        uses = {}
        for r in found.values():
            uses[r["u"]] = uses.get(r["u"], 0) + 1
        print(f"building_heights: OK · no small building at the old 14 m guess, {len(found)} "
              f"researched ({', '.join(f'{k} {v}' for k, v in sorted(uses.items(), key=lambda kv: -kv[1]))})")
        return 0
    if "--list" in argv:
        for row in thin_list(out):
            print("%6d  x %6d z %6d  h %5.1f  %4d m²  w %4.1f  %-16s %s" % row)
        return 0
    if "--dry" in argv:
        print(f"building_heights: {sum(1 for b in out.get('buildings', []) if stale(b))} would change")
        return 0
    print("building_heights: " + apply(out))
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
