#!/usr/bin/env python3
"""Hang Most Łazienkowski's cycle bridges at their real height, about 4 m under the road deck.

    python3 -I tools/cycle_hang.py [game/map/centrum.json] [--dry]   (rewrites the map in place)
    python3 -I tools/cycle_hang.py --check [game/map/centrum.json]
        exit 1 unless the map is hung already (a run would change nothing) and most nodes under the
        road (CHECK_SHARE) sit within HANG_TOL of HANG under it (verify.sh step `cyclehang`).

F (2026-11-07, the bridges thread): "why does the bike path hang in the air". The two cycle
bridges of 2017 hang on brackets under the deck's edges (F's photos LZ-1, LZ-1b, LZ-3c in
~/Documents/warsaw-needed-photos/bridges): the lower walkway's railing runs one storey under the
road's, and at the banks curved ramps take it down to the boulevards. The deck solver
(tools/bake_roads.py) knows nothing of the road above a path deck: it put both cycle decks at the
river's clearance (CLEAR_WATER), 8.6-11.7 m under the road, so they read as a separate bridge.

What this does, on the finished map data (bake_osm.py calls `apply(out, terrain)` before
tools/bake_structures.py; this file is also a command line tool for a baked map):

- The hung decks: every path deck piece of the deck groups that hold a piece starting at one of
  LZ_CYCLE (the same anchors as map_builder.gd's `_lazienkowski_cycle`).
- Its nodes form one graph (piece ends within JOIN metres are one node). An anchor is a node where
  the network meets the ground: a free end of a piece, or a shared end already within GROUND of
  the terrain. Anchors keep their heights, so every path, ramp, step and crossing that meets the
  decks there still meets them.
- A node with a road deck over it (a road piece's centreline within its half width + REACH, at
  least MIN_UNDER over the node) gets the target height: that road's height minus HANG.
- The new height of a node: its old height, raised to the targets (falling off at GRADE with the
  distance along the network from each target) but never over its anchors' heights plus GRADE
  times the distance from them. So over the river the decks run HANG under the road, and towards
  each anchor they come down at GRADE, the ramps' slope; nothing is ever lowered, and a node far
  from every target is left alone. Idempotent: a second run changes nothing.

Standard library only, deterministic. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import heapq
import json
import math
import os
import sys

LZ_CYCLE = [(1971.8, 858.2), (1974.2, 883.5)]   # map_builder.gd LZ_CYCLE: the cycle decks' pieces start here
START_NEAR = 1.0     # a piece starting this near an LZ_CYCLE point is one of the cycle decks
HANG = 4.0           # the cycle deck's surface under the road's (F's photos: one storey, the girder's depth)
REACH = 4.0          # a road piece's centreline within its half width plus this is over the node
MIN_UNDER = 2.0      # ...if it runs at least this much higher
GRADE = 0.06         # bake_roads.GRADE: the ramps' slope
JOIN = 0.3           # piece ends this close are one node
GROUND = 0.6         # a shared end this near the terrain is where the network meets the ground
HANG_TOL = 0.3       # --check: a node under the road this near its target height...
CHECK_SHARE = 0.6    # ...for at least this share of them (the rest come down the ramps to the anchors)
CELL = 32.0


def _pts(pc):
    q = pc["p"]
    return [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]


def hung_pieces(pieces):
    """The indices of the cycle decks' pieces: every path piece of a group holding a piece that
    starts at an LZ_CYCLE point."""
    groups = set()
    for pc in pieces:
        if pc["k"] == "path" and any(math.hypot(pc["p"][0] - x, pc["p"][1] - z) < START_NEAR for x, z in LZ_CYCLE):
            groups.add(pc["g"])
    return [i for i, pc in enumerate(pieces) if pc["k"] == "path" and pc["g"] in groups]


class Roads:
    """The road decks' segments, by grid cell, for the height of the road over a point."""

    def __init__(self, pieces):
        self.cells = {}
        for i, pc in enumerate(pieces):
            if pc["k"] != "road":
                continue
            pts, half = _pts(pc), max(pc["l"], pc["r"])
            for k in range(len(pts) - 1):
                a, b = pts[k], pts[k + 1]
                reach = half + REACH
                for cz in range(math.floor((min(a[1], b[1]) - reach) / CELL), math.floor((max(a[1], b[1]) + reach) / CELL) + 1):
                    for cx in range(math.floor((min(a[0], b[0]) - reach) / CELL), math.floor((max(a[0], b[0]) + reach) / CELL) + 1):
                        self.cells.setdefault((cx, cz), []).append((a, b, pc["h"][k], pc["h"][k + 1], half))

    def over(self, x, z, h):
        """The height of the highest road deck over (x, z) at least MIN_UNDER above h, or None."""
        best = None
        for a, b, ha, hb, half in self.cells.get((math.floor(x / CELL), math.floor(z / CELL)), ()):
            abx, abz = b[0] - a[0], b[1] - a[1]
            l2 = abx * abx + abz * abz
            t = 0.0 if l2 < 1e-9 else min(max(((x - a[0]) * abx + (z - a[1]) * abz) / l2, 0.0), 1.0)
            if math.hypot(x - a[0] - abx * t, z - a[1] - abz * t) > half + REACH:
                continue
            y = ha + (hb - ha) * t
            if y >= h + MIN_UNDER and (best is None or y > best):
                best = y
        return best


def _graph(pieces, idx):
    """Nodes (one per piece vertex, shared ends merged) and edges of the hung pieces.
    Returns (node of (piece, vertex), [(x, z)], adjacency {n: [(m, length)]}, degree of ends)."""
    node, xy, adj, ends = {}, [], {}, {}
    for i in idx:
        pts = _pts(pieces[i])
        for k, (x, z) in enumerate(pts):
            n = None
            if k in (0, len(pts) - 1):
                n = next((e for e in ends if math.hypot(xy[e][0] - x, xy[e][1] - z) < JOIN), None)
            if n is None:
                n = len(xy)
                xy.append((x, z))
                adj[n] = []
            if k in (0, len(pts) - 1):
                ends[n] = ends.get(n, 0) + 1
            node[(i, k)] = n
        for k in range(len(pts) - 1):
            a, b = node[(i, k)], node[(i, k + 1)]
            d = math.dist(pts[k], pts[k + 1])
            adj[a].append((b, d))
            adj[b].append((a, d))
    return node, xy, adj, ends


def _spread(adj, start, sign):
    """Multi-source Dijkstra: for every node the least of (start value + GRADE * distance) when
    sign is 1, or the greatest of (start value - GRADE * distance) when sign is -1."""
    best = {n: sign * v for n, v in start.items()}
    heap = [(v, n) for n, v in best.items()]
    heapq.heapify(heap)
    while heap:
        v, n = heapq.heappop(heap)
        if v > best.get(n, math.inf):
            continue
        for m, d in adj[n]:
            w = v + GRADE * d
            if w < best.get(m, math.inf) - 1e-9:
                best[m] = w
                heapq.heappush(heap, (w, m))
    return {n: sign * v for n, v in best.items()}


def plan(d, terrain):
    """The new height of every hung node: {(piece, vertex): h}, plus stats."""
    pieces = d.get("decks", {}).get("pieces", [])
    idx = hung_pieces(pieces)
    if not idx:
        return {}, {"pieces": 0}
    node, xy, adj, ends = _graph(pieces, idx)
    old = {}
    for (i, k), n in node.items():
        old[n] = pieces[i]["h"][k] if n not in old else min(old[n], pieces[i]["h"][k])
    roads = Roads(pieces)
    target = {}
    for n, (x, z) in enumerate(xy):
        y = roads.over(x, z, old[n])
        if y is not None:
            target[n] = round(y - HANG, 2)
    anchors = {n: old[n] for n, c in ends.items() if c == 1 or abs(old[n] - terrain(*xy[n])) <= GROUND}
    cap = _spread(adj, anchors, 1)
    rise = _spread(adj, target, -1)
    new, stats = {}, {"pieces": len(idx), "nodes": len(xy), "anchors": len(anchors), "targets": len(target),
                      "raised": 0, "most": 0.0}
    for n in range(len(xy)):
        h = old[n]
        if n in rise:
            h = max(h, min(rise[n], cap.get(n, math.inf)))
        h = round(h, 2)
        if h > old[n] + 0.005:
            stats["raised"] += 1
            stats["most"] = max(stats["most"], round(h - old[n], 2))
        new[n] = h
    return {key: new[n] for key, n in node.items()}, dict(stats, target=target, xy=xy, node=node, new=new, old=old)


def apply(d, terrain):
    """Raise the hung cycle decks in d (centrum.json's dict) in place; returns a one-line report."""
    heights, st = plan(d, terrain)
    pieces = d.get("decks", {}).get("pieces", [])
    for (i, k), h in heights.items():
        pieces[i]["h"][k] = h
    if not st.get("pieces"):
        return "no Łazienkowski cycle decks on this map"
    return (f"{st['pieces']} cycle deck pieces, {st['nodes']} nodes, {st['targets']} under the road, "
            f"{st['anchors']} ground anchors kept; {st['raised']} nodes raised, most {st['most']} m")


def check(d, terrain):
    """Problems: a node under the road off its target by more than HANG_TOL where no anchor holds
    it down, or a raised stretch steeper than GRADE."""
    heights, st = plan(d, terrain)
    if not st.get("pieces"):
        return ["no Łazienkowski cycle decks found (LZ_CYCLE)"]
    bad = []
    if any(abs(h - st["old"][st["node"][key]]) > 0.005 for key, h in heights.items()):
        bad.append(f"{st['raised']} nodes not hung yet (run tools/cycle_hang.py)")
    under = [n for n in st["target"] if abs(st["new"][n] - st["target"][n]) <= HANG_TOL]
    if len(under) < CHECK_SHARE * len(st["target"]):
        bad.append(f"only {len(under)} of {len(st['target'])} nodes under the road hang {HANG} m under it")
    return bad


def terrain_of(map_dir, d):
    """The map's terrain lookup (check_roads.Map.terrain) for a map file being baked or baked."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import check_roads
    m = check_roads.Map.from_data(map_dir, d, json.load(open(os.path.join(map_dir, "terrain.json"))))
    return m.terrain


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    d = json.load(open(path, encoding="utf-8"))
    terrain = terrain_of(os.path.dirname(os.path.abspath(path)), d)
    if "--check" in argv:
        bad = check(d, terrain)
        for b in bad[:20]:
            print("cycle_hang: " + b)
        print("cycle_hang: " + ("OK" if not bad else f"{len(bad)} problems"))
        return 1 if bad else 0
    print("cycle_hang: " + apply(d, terrain))
    if "--dry" not in argv:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
