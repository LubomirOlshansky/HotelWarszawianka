#!/usr/bin/env python3
"""The footbridge over Port Czerniakowski's mouth, by Majami Wawa, as one flat deck (F, 2026-11-08).

    python3 -I tools/port_bridge.py [game/map/centrum.json] [--dry]   (rewrites the map in place)
    python3 -I tools/port_bridge.py --check [game/map/centrum.json]
        exit 1 unless the map holds the bridge (VERSION) and none of what it took out is back
        (verify.sh step `portbridge`).

F (2026-11-08, screenshots by the Miami Wars bar): "something unclear here, make a proper bridge".
In the game the boulevard's cycle path ran down into the mouth's cutting (7 m: the 10 m terrain
grid blurs the narrow channel into a trough) between crooked grey walls, broke off at the water
(OpenStreetMap's 6 m bridge way had no deck) and the car stuck at the gap. Today's bridge (F's
aerial and Street View, Mapillary 2021 and 2025: GanderPL, awizonosz) is a straight, flat, paved
deck about 56 m long and 5 m wide, wide enough for bikes and the odd service car, between bright
green steel railings, with lamps along it and the Veturilo dock at the spit's end.

North-west of it, in the same screenshots, the car stopped at grey "walls" across a sandy plaza:
OpenStreetMap's construction site between the boulevard and Solec, fenced. The works are long
finished (the photos show a car park with lawns and the Y of paths), so that lot is asphalt now and
its site fences are gone.

What this does, on the finished map data (bake_osm.py calls `apply(out, terrain)` before
tools/bake_structures.py, so the structures see the new deck; this file is also a command line
tool for a baked map):

- `decks.pieces`: one path deck (its own group) from W to E, straight, its ends at the ground's
  height there and a gentle hump (HUMP) in the middle; `rail` makes map_builder.gd draw the green
  steel railing (posts, rails and bars) instead of the concrete parapet, `lp` its lamps.
- `paths`: the cycle path ends at W and starts again at E, its stretch between laid on the deck
  (`dk`, so the walkers and riders cross on it; the 6 m stub over the water goes);
  the spit's footpath that left it in the cutting starts at E instead.
- `fills`: the cycle path's approaches end at W and E; the spit path's starts at E.
- `walls` (bake_structures' retaining walls of the old approaches in the cutting) and the parts of
  the mapped walls (`lines` k wall) inside the bridge's corridor go; of a wall cut there only runs of
  WALL_KEEP m or more stay (the channel's quays), the short crooked bits by the abutments go.
- The construction lot (`surfaces` k construction, the one holding LOT) becomes a `parking`
  surface (asphalt, map_builder.gd SURFACE_STYLE) and the fences along its outline go.

Idempotent: the map carries `port_bridge` = VERSION once done; a second run changes nothing.
Standard library only, deterministic. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
VERSION = 1

W = (1332.0, 678.64)        # the deck's west end, on the boulevard's cycle path (ground -13.2)
E = (1386.0, 695.25)        # its east end, on the spit by Majami Wawa (ground -13.2)
HALF = 2.6                  # half the deck's width (the photos: ~5 m between the railings)
HUMP = 0.35                 # the deck's middle stands this much over the line between its ends
STEP = 5.0                  # the deck's points this far apart
CORRIDOR = HALF + 0.8       # walls and fills within this of the deck's line (between W and E) go
WALL_KEEP = 25.0            # a mapped wall cut by the corridor keeps only its runs at least this long
RAIL = "#46b83a"            # the railings' green (Mapillary 2025)
LAMPS = (0.08, 0.5, 0.92)   # lamps at these shares of the length, on the north (left) side
# The cycle path's ends at the old gap and the spit path's first point (OpenStreetMap's nodes).
CYCLE_W_END = (1357.0, 685.5)
CYCLE_E_START = (1362.8, 687.2)
SPIT_START = (1375.3, 691.9)
SPIT_NEW = [(1383.2, 704.5)]  # the spit path from E bends south here to its old line
# The construction lot north-west of the bridge (a point inside it) and how close a fence must run
# to its outline to count as the site's.
LOT = (1300.0, 685.0)
LOT_FENCE = 1.5


def _pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def _flat(pts):
    return [round(c, 2) for p in pts for c in p]


def _frame():
    dx, dz = E[0] - W[0], E[1] - W[1]
    length = math.hypot(dx, dz)
    return length, (dx / length, dz / length)


def _local(p):
    """(along from W, across to the right) of the deck's line."""
    length, (ux, uz) = _frame()
    vx, vz = p[0] - W[0], p[1] - W[1]
    return vx * ux + vz * uz, -(vx * uz - vz * ux)


def _in_corridor(p, reach=CORRIDOR):
    s, t = _local(p)
    length, _ = _frame()
    return -0.5 <= s <= length + 0.5 and abs(t) <= reach


def _near(a, b, tol=0.2):
    return math.dist(a, b) <= tol


def _point_in_poly(p, poly):
    x, z = p
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi:
            inside = not inside
        j = i
    return inside


def _seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    l2 = ax * ax + az * az
    u = 0.0 if l2 < 1e-12 else max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / l2))
    return math.dist(p, (a[0] + ax * u, a[1] + az * u))


def _poly_dist(p, poly):
    return min(_seg_dist(p, poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly)))


def _clip_line(pts, keep):
    """Runs of the polyline whose 0.5 m pieces `keep` accepts (by the piece's middle); the original
    vertices are kept, cuts land within 0.5 m."""
    runs, run = [], []
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.ceil(math.dist(a, b) / 0.5)))
        for k in range(n):
            p0 = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
            p1 = (a[0] + (b[0] - a[0]) * (k + 1) / n, a[1] + (b[1] - a[1]) * (k + 1) / n)
            if keep(((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)):
                if not run:
                    run = [p0]
                if k == n - 1 or k == 0 and run[-1] != p0:
                    pass
                run.append(p1)
            elif run:
                runs.append(run)
                run = []
    if run:
        runs.append(run)
    out = []
    for r in runs:
        # Drop the in-between sample points on straight stretches (keep the original corners).
        simple = [r[0]]
        for i in range(1, len(r) - 1):
            ax, az = r[i][0] - simple[-1][0], r[i][1] - simple[-1][1]
            bx, bz = r[i + 1][0] - r[i][0], r[i + 1][1] - r[i][1]
            if abs(ax * bz - az * bx) > 1e-6 * (math.hypot(ax, az) * math.hypot(bx, bz) + 1e-9) * 1e3:
                simple.append(r[i])
        simple.append(r[-1])
        if sum(math.dist(a, b) for a, b in zip(simple, simple[1:])) >= 0.6:
            out.append(simple)
    return out


def _deck_piece(d, terrain):
    length, (ux, uz) = _frame()
    n = max(2, int(round(length / STEP)) + 1)
    h0, h1 = terrain(*W), terrain(*E)
    pts, hs = [], []
    for k in range(n):
        f = k / (n - 1)
        pts.append((W[0] + ux * length * f, W[1] + uz * length * f))
        hs.append(round(h0 + (h1 - h0) * f + HUMP * 4.0 * f * (1.0 - f), 2))
    groups = d["decks"].get("groups", 0)
    g = groups if isinstance(groups, int) else len(groups)
    used = [pc["g"] for pc in d["decks"]["pieces"]]
    g = max([g - 1] + used) + 1
    d["decks"]["groups"] = g + 1 if isinstance(groups, int) else groups
    return {"p": _flat(pts), "h": hs, "l": HALF, "r": HALF, "g": g, "k": "path", "o": [3] * n,
            "rail": RAIL, "lp": list(LAMPS)}


def _end_h(d_piece, end):
    return d_piece["h"][0] if end == W else d_piece["h"][-1]


def plan(d, terrain):
    """What apply() would change: a dict of counts and the new pieces (nothing is written)."""
    return apply(json.loads(json.dumps(d)), terrain, dry=True)


def apply(d, terrain, dry=False):
    if d.get("port_bridge") == VERSION:
        return "already built"
    notes = []
    deck = _deck_piece(d, terrain)
    d["decks"]["pieces"].append(deck)
    notes.append(f"deck {math.dist(W, E):.1f} m in group {deck['g']}")

    # Paths: the cycle path over the deck, the stub out, the spit path from E.
    paths, n_cut, spit_line = [], 0, None
    for p in d["paths"]:
        pts = _pairs(p["p"])
        if len(pts) == 2 and {pts[0], pts[1]} == {CYCLE_W_END, CYCLE_E_START}:
            n_cut += 1
            continue
        if _near(pts[-1], CYCLE_W_END):
            keep = [q for q in pts if not _in_corridor(q)]
            p = dict(p, p=_flat(keep + [W]))
            # The deck's own stretch, laid on it (`dk`: its group, as bake_roads marks a path on a deck).
            paths.append({"p": _flat([W, E]), "w": p.get("w", 2.0), "k": p.get("k", "cycle"), "dk": deck["g"]})
            n_cut += 1
        elif _near(pts[0], CYCLE_E_START):
            keep = [q for q in pts if not _in_corridor(q)]
            p = dict(p, p=_flat([E] + keep))
            n_cut += 1
        elif _near(pts[0], SPIT_START):
            keep = [q for q in pts[1:] if math.dist(q, E) > 6.0 and q[1] > SPIT_NEW[0][1] + 2.0]
            spit_line = [E] + SPIT_NEW + keep
            p = dict(p, p=_flat(spit_line))
            n_cut += 1
        paths.append(p)
    d["paths"] = paths
    notes.append(f"{n_cut} paths rejoined")

    # Fills: the approaches end at the deck's ends; the spit path's starts at E.
    fills, n_fill = [], 0
    for f in d["fills"]:
        pts, hs = _pairs(f["p"]), list(f["h"])
        if f.get("k") != "path" or not any(_in_corridor(q) for q in pts):
            fills.append(f)
            continue
        n_fill += 1
        if _near(pts[0], SPIT_START) and spit_line:
            # The new line's own points: the old fill's height where a point is one of its nodes.
            old = {q: h for q, h in zip(pts, hs)}
            new = [(E, _end_h(deck, E))] + [(q, old.get(q, round(terrain(*q), 2))) for q in spit_line[1:]]
        else:
            out = [(q, h) for q, h in zip(pts, hs) if not _in_corridor(q)]
            if not out:
                continue
            s_first, _ = _local(out[0][0])
            s_last, _ = _local(out[-1][0])
            length, _ = _frame()
            # The kept run lies before W (its end joins W) or past E (its start joins E).
            if s_last < length / 2 and s_first < length / 2:
                new = out + [(W, _end_h(deck, W))]
            else:
                new = [(E, _end_h(deck, E))] + out
        if len(new) >= 2:
            fills.append(dict(f, p=_flat([q for q, _ in new]), h=[h for _, h in new]))
    d["fills"] = fills
    notes.append(f"{n_fill} fills cut")

    # The old approaches' retaining walls in the cutting, and the spit path's.
    old_spit = [SPIT_START, (1377.1, 700.6), (1382.9, 712.6), (1382.6, 715.0), (1383.0, 718.0)]
    walls = []
    for w in d.get("walls", []):
        pts = _pairs(w["p"])
        if all(_in_corridor(q, CORRIDOR + 2.0) for q in pts) or all(
                min(_seg_dist(q, a, b) for a, b in zip(old_spit, old_spit[1:])) < 2.5 for q in pts):
            continue
        walls.append(w)
    notes.append(f"{len(d.get('walls', [])) - len(walls)} retaining walls out")
    d["walls"] = walls

    # The lot: asphalt, its fences out; the mapped walls cut out of the bridge's corridor.
    lot = None
    for s in d.get("surfaces", []):
        if lot is None and s.get("k") == "construction" and _point_in_poly(LOT, _pairs(s["p"])):
            lot = _pairs(s["p"])
            s["k"] = "parking"
    lines, n_fence, n_wall = [], 0, 0
    for ln in d.get("lines", []):
        pts = _pairs(ln["p"])
        if lot is not None and ln.get("k") == "fence" and all(
                _poly_dist(q, lot) <= LOT_FENCE or _point_in_poly(q, lot) for q in pts):
            n_fence += 1
            continue
        if ln.get("k") == "wall" and any(_in_corridor(q, CORRIDOR + 1.0) for q in pts) or ln.get("k") == "wall" and any(
                _in_corridor(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)) for a, b in zip(pts, pts[1:])):
            runs = _clip_line(pts, lambda q: not _in_corridor(q))
            n_wall += 1
            for r in runs:
                # What is left of a mapped wall beside the abutments is a crooked slab on the lawn
                # (F's screenshot); the long quay walls along the channel to the river stay.
                if sum(math.dist(a, b) for a, b in zip(r, r[1:])) >= WALL_KEEP:
                    lines.append(dict(ln, p=_flat(r)))
            continue
        lines.append(ln)
    d["lines"] = lines
    notes.append(f"lot {'parking' if lot else 'not found'}, {n_fence} site fences out, {n_wall} walls cut")
    d["port_bridge"] = VERSION
    return ", ".join(notes)


def check(d):
    bad = []
    if d.get("port_bridge") != VERSION:
        bad.append(f"the map has port_bridge {d.get('port_bridge')}, want {VERSION} (run tools/port_bridge.py)")
        return bad
    decks = [pc for pc in d["decks"]["pieces"] if pc.get("rail") == RAIL and _near(_pairs(pc["p"])[0], W, 0.1)]
    if len(decks) != 1:
        bad.append(f"{len(decks)} bridge decks at W, want 1")
    else:
        hs = decks[0]["h"]
        if max(hs) - min(hs) > HUMP + 0.5:
            bad.append(f"the deck is not flat: {min(hs)}..{max(hs)}")
    for p in d["paths"]:
        pts = _pairs(p["p"])
        if len(pts) == 2 and {pts[0], pts[1]} == {CYCLE_W_END, CYCLE_E_START}:
            bad.append("the 6 m cycle stub over the water is back")
    on_deck = [p for p in d["paths"] if _pairs(p["p"]) == [W, E] and decks and p.get("dk") == decks[0]["g"]]
    if len(on_deck) != 1:
        bad.append(f"{len(on_deck)} paths laid on the deck from W to E, want 1")
    for f in d["fills"]:
        if f.get("k") == "path" and any(_in_corridor(q, HALF) and min(math.dist(q, W), math.dist(q, E)) > 0.5
                                        for q in _pairs(f["p"])):
            bad.append(f"a path fill runs on the bridge's line at {_pairs(f['p'])[0]}")
    for ln in d["lines"]:
        if ln.get("k") == "wall" and any(_in_corridor(q, HALF) for q in _pairs(ln["p"])):
            bad.append(f"a wall stands on the bridge at {_pairs(ln['p'])[0]}")
    for s in d.get("surfaces", []):
        if s.get("k") == "construction" and _point_in_poly(LOT, _pairs(s["p"])):
            bad.append("the finished construction lot is back")
    lots = [_pairs(s["p"]) for s in d.get("surfaces", []) if s.get("k") == "parking" and _point_in_poly(LOT, _pairs(s["p"]))]
    if len(lots) != 1:
        bad.append(f"{len(lots)} car parks at LOT, want 1")
    for ln in d["lines"]:
        if lots and ln.get("k") == "fence" and all(
                _poly_dist(q, lots[0]) <= LOT_FENCE or _point_in_poly(q, lots[0]) for q in _pairs(ln["p"])):
            bad.append(f"a site fence stands round the car park at {_pairs(ln['p'])[0]}")
    return bad


def terrain_of(map_dir, d):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import cycle_hang
    return cycle_hang.terrain_of(map_dir, d)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else os.path.join(ROOT, "game", "map", "centrum.json")
    d = json.load(open(path))
    if "--check" in argv:
        bad = check(d)
        for b in bad:
            print("port_bridge: " + b)
        print("port_bridge: " + ("OK" if not bad else f"{len(bad)} problems"))
        return 1 if bad else 0
    msg = apply(d, terrain_of(os.path.dirname(os.path.abspath(path)), d), dry="--dry" in argv)
    print("port_bridge: " + msg)
    if "--dry" not in argv and msg != "already built":
        with open(path, "w") as fh:
            json.dump(d, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
