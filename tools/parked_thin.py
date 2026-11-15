"""Parked rows thinned where the lane is pinched (the city objects plan, item 4, step 8b; F, 2026-11-15):
a pass on the finished map data (main's centrum.json, docs/architecture/tech-debt.md TD-25).

    python3 -I tools/parked_thin.py [MAP.json] [--dry] [--tsv=FILE] [--list]
        rewrites the map in place (stamp-guarded: a map already thinned is left alone);
        --dry measures and changes nothing (on a thinned map: what it would do on a fresh copy
        without the stamp); --tsv writes every car's verdict by street; --list prints the drops.
    python3 -I tools/parked_thin.py --check [MAP.json]
        the defect classes over the whole map (verify.sh step `parkedthin`): exit 1 unless the map
        carries the stamp and has no bay in a lane, no two side-by-side pinched bays and no car by a
        junction within JUNCTION_EDGE m of a lane.

Why. The bake (bake_osm.py bake_extras) fills about a quarter of the bays of each mapped car park,
street-side strips included, and keeps a car's centre off the carriageway; a phone player on a
one-way street between two rows (Krucza, Wspólna, Hoża) drives a gap of 3 m or less, and at the
mouths of junctions the rows reach to the lanes' edges where the car turns. The game's parked
cars are hard with the soft things off (the testers' default) and pushable with them on (step 8a):
either way a pinch is where the sloppy driver of check_lane_drive hits them.

The rules, on the lane graph's corridors (every edge but the tunnels; each edge's lanes from
o - lw / 2 to o + lw (n - 1/2) right of its centreline, as soft_things.gd corridor_segments) and a
parked car's box (CAR_HALF, soft_things.gd's):

    IN    a bay already inside a lane (soft_things.gd in_corridor: its corners, side middles and
          three points down its middle, a hair inside the edges): REMOVE (moving it is not safe
          in a pass: the nearest free spot is a pavement, a zebra or another bay)
    JN    a car within JUNCTION_R m of a junction node (a graph node with three or more
          neighbours) whose box is within JUNCTION_EDGE m of a lane's edge: REMOVE
    PINCH a car whose free width is under FREE_MIN m: the nearest lane's width (all the lanes of
          its edge) + the gap from its edge to the car's box + the clear width past the lane's far
          edge (the asphalt and the other lanes, up to a kerb, a building or another parked car's
          box), measured straight across from the car's middle. Every other car of a row goes: the
          row's cars (one heading within ROW_YAW, one line within ROW_LINE m, neighbours within
          ROW_GAP m) by index along the row, and a pinched car with an odd index is removed

The rules read the map as it was before the pass (the other cars as the bake left them), so the
result does not depend on the order. bake_osm.py calls apply(out) after object_fixes and the
stops (the cars as they finally stand); on main's map run this, then tools/bake_ao.py (the shade
map's parked channel), tools/bake_sectors.py and bake_city.gd. Deterministic, standard library.
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.normpath(os.path.join(HERE, ".."))

KEY = "parked_thin"
VERSION = 1
FREE_MIN = 3.6        # m: a lane narrower than this between a row and the other side is a pinch
JUNCTION_R = 15.0     # m from a junction node...
JUNCTION_EDGE = 1.0   # ...where a car's box within this of a lane's edge goes
CAR_HALF = (0.9, 2.1)  # half width, half length (soft_things.gd CAR_HALF)
HAIR = 0.05           # soft_things.gd in_corridor: a hair inside the lanes' edges
LANE_LEVEL = 2.5      # m: soft_things.gd LANE_LEVEL, a deck's lane this close to the ground counts
IN_CLEAR = 0.15       # m: a bay in a lane moves out of it by its depth and this much...
IN_SHIFT_MAX = 0.6    # m: ...at most; one that would move further, or onto something, goes
STRIDE = 4            # x, z, yaw, colour
ROW_YAW = 0.12        # rad: neighbours in a row share a heading (mod pi)...
ROW_LINE = 0.4        # m: ...stand on one line (plus ROW_BEND m a metre apart: a row round a bend)...
ROW_BEND = 0.06
ROW_GAP = 10.0        # m: ...and the next one is at most this far along it side by side (2.5 m bays)
ROW_GAP_TAIL = 12.0   # m: or nose to tail (road_design.py PARK_EVERY 5.8 m, a space left empty)
PAIR_GAP = {"side": 3.0, "tail": 7.0}   # m: two cars of a row this close stand in neighbouring bays
STEP = 0.1            # m: the march across the far side
CELL = 16.0
# --check: what may be left over the whole map after the pass (a ratchet: lower, never raise).
CHECK_LEFT = {"IN": 0, "JN": 0, "PAIR": 0}


def _cell(x, z):
    return (int(math.floor(x / CELL)), int(math.floor(z / CELL)))


class Lanes:
    """The lane graph's corridors as segments [ax, az, bx, bz, from, to, edge] in a grid. A deck's
    lanes count only where their surface is within LANE_LEVEL m of the ground (soft_things.gd
    corridor_segments' level test: a bridge's ramp end, not the slab over a car park), which needs
    terrain.json (`map_dir`); without it no deck lane counts."""

    def __init__(self, d, map_dir=None):
        g = d["graph"]
        self.edges = g["edges"]
        self.heights = None
        tp = os.path.join(map_dir, "terrain.json") if map_dir else ""
        if tp and os.path.exists(tp):
            import check_roads as cr
            with open(tp, encoding="utf-8") as f:
                self.heights = cr.Map.from_data(map_dir, d, json.load(f))
        self._level = {}
        self.segs = []
        self.grid = defaultdict(list)
        for ei, e in enumerate(self.edges):
            if int(e.get("tn", -1)) >= 0:
                continue  # in a tunnel: never beside a parked car on the ground
            lw = float(e["lw"])
            fr = float(e["o"]) - lw * 0.5
            to = float(e["o"]) + lw * (int(e["n"]) - 0.5)
            p = e["p"]
            grow = max(abs(fr), abs(to)) + 4.0
            for k in range(0, len(p) - 3, 2):
                ax, az, bx, bz = p[k], p[k + 1], p[k + 2], p[k + 3]
                if (bx - ax) ** 2 + (bz - az) ** 2 < 1e-6:
                    continue
                si = len(self.segs)
                self.segs.append((ax, az, bx, bz, fr, to, ei))
                for cx in range(_cell(min(ax, bx) - grow, 0)[0], _cell(max(ax, bx) + grow, 0)[0] + 1):
                    for cz in range(_cell(0, min(az, bz) - grow)[1], _cell(0, max(az, bz) + grow)[1] + 1):
                        self.grid[(cx, cz)].append(si)
        # Junctions: nodes with three or more distinct neighbours.
        nb = defaultdict(set)
        for e in self.edges:
            nb[int(e["a"])].add(int(e["b"]))
            nb[int(e["b"])].add(int(e["a"]))
        flat = g["nodes"]
        self.junctions = defaultdict(list)
        for n, s in nb.items():
            if len(s) >= 3:
                x, z = flat[2 * n], flat[2 * n + 1]
                self.junctions[_cell(x, z)].append((x, z))

    def near(self, x, z):
        """The corridor segments in the cell of (x, z) on the ground's level there."""
        return [si for si in self.grid.get(_cell(x, z), ()) if self.on_level(si, x, z)]

    def on_level(self, si, x, z):
        dk = int(self.edges[self.segs[si][6]].get("dk", -1))
        if dk < 0:
            return True
        if self.heights is None:
            return False
        key = (dk, round(x), round(z))
        if key not in self._level:
            m = self.heights
            self._level[key] = abs(m.deck_height(dk, x, z) - m.terrain(x, z)) <= LANE_LEVEL
        return self._level[key]

    def in_any(self, q):
        """Whether the point q lies inside any lane corridor."""
        for si in self.near(*q):
            ax, az, bx, bz, fr, to, _ = self.segs[si]
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz
            t = ((q[0] - ax) * dx + (q[1] - az) * dz) / l2
            if 0.0 <= t <= 1.0:
                side = ((q[0] - ax) * -dz + (q[1] - az) * dx) / math.sqrt(l2)
                if fr <= side <= to:
                    return True
        return False

    def near_junction(self, x, z, r):
        c = _cell(x, z)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for jx, jz in self.junctions.get((c[0] + i, c[1] + j), ()):
                    if (jx - x) ** 2 + (jz - z) ** 2 <= r * r:
                        return True
        return False


def axes(yaw):
    """(right, back): the car's width and length directions on the map (Basis(UP, yaw).x / .z)."""
    return (math.cos(yaw), -math.sin(yaw)), (math.sin(yaw), math.cos(yaw))


def box_points(x, z, yaw):
    """soft_things.gd in_corridor's nine points of the car's box."""
    (rx, rz), (bx, bz) = axes(yaw)
    rx, rz, bx, bz = rx * CAR_HALF[0], rz * CAR_HALF[0], bx * CAR_HALF[1], bz * CAR_HALF[1]
    o = (x, z)
    return [(o[0] + rx + bx, o[1] + rz + bz), (o[0] + rx - bx, o[1] + rz - bz),
            (o[0] - rx - bx, o[1] - rz - bz), (o[0] - rx + bx, o[1] - rz + bz),
            (o[0] + rx, o[1] + rz), (o[0] - rx, o[1] - rz), o,
            (o[0] + bx * 0.5, o[1] + bz * 0.5), (o[0] - bx * 0.5, o[1] - bz * 0.5)]


def in_box(q, car):
    x, z, yaw = car
    (rx, rz), (bx, bz) = axes(yaw)
    dx, dz = q[0] - x, q[1] - z
    return abs(dx * rx + dz * rz) <= CAR_HALF[0] and abs(dx * bx + dz * bz) <= CAR_HALF[1]


def in_lane(lanes, car):
    """IN: soft_things.gd in_corridor over every corridor segment near the car."""
    x, z, yaw = car
    pts = box_points(x, z, yaw)
    for si in lanes.near(x, z):
        ax, az, bx, bz, fr, to, _ = lanes.segs[si]
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        n = math.sqrt(l2)
        for q in pts:
            t = ((q[0] - ax) * dx + (q[1] - az) * dz) / l2
            if t < 0.0 or t > 1.0:
                continue
            side = ((q[0] - ax) * -dz + (q[1] - az) * dx) / n
            if fr + HAIR < side < to - HAIR:
                return True
    return False


def lane_gaps(lanes, car):
    """[(gap, seg index, the car's side: -1 left of the corridor, 1 right, 0 across it, t)] for every
    corridor segment the car's box lies beside (its length overlaps the segment's): the gap from the
    corridor's nearer edge to the box (0 when they overlap)."""
    x, z, yaw = car
    (rx, rz), (bkx, bkz) = axes(yaw)
    out = []
    for si in lanes.near(x, z):
        ax, az, bx, bz, fr, to, _ = lanes.segs[si]
        dx, dz = bx - ax, bz - az
        n = math.hypot(dx, dz)
        ux, uz = dx / n, dz / n
        nx, nz = -uz, ux
        along = (x - ax) * ux + (z - az) * uz
        side = (x - ax) * nx + (z - az) * nz
        ha = abs(rx * ux + rz * uz) * CAR_HALF[0] + abs(bkx * ux + bkz * uz) * CAR_HALF[1]
        hs = abs(rx * nx + rz * nz) * CAR_HALF[0] + abs(bkx * nx + bkz * nz) * CAR_HALF[1]
        if along + ha < 0.0 or along - ha > n:
            continue
        if side + hs < fr:
            out.append((fr - (side + hs), si, -1, max(0.0, min(1.0, along / n))))
        elif side - hs > to:
            out.append(((side - hs) - to, si, 1, max(0.0, min(1.0, along / n))))
        else:
            out.append((0.0, si, 0, max(0.0, min(1.0, along / n))))
    return out


class Blockers:
    """What ends the clear width past a lane's far edge: another parked car, a building, off the asphalt."""

    def __init__(self, d, cars, lanes):
        import object_audit as oa
        self.w = oa.World(d)
        self.lanes = lanes
        self.cars = cars
        self.grid = defaultdict(list)
        for i, c in enumerate(cars):
            cc = _cell(c[0], c[1])
            for a in (-1, 0, 1):
                for b in (-1, 0, 1):
                    self.grid[(cc[0] + a, cc[1] + b)].append(i)

    def blocked(self, q, me):
        for i in self.grid.get(_cell(*q), ()):
            if i != me and in_box(q, self.cars[i]):
                return True
        if self.w.in_building(q, 0.0):
            return True
        return not self.w.on_road(q) or self.lanes.in_any(q)


def free_width(lanes, blk, car, me, gaps):
    """PINCH: (free width, edge index) of the lane the car stands beside (the nearest one), or None:
    its width + the gap from its edge to the car's box + the clear asphalt past its far edge, up to
    the next lane (another lane of its street or the other way's: traffic drives there), a kerb, a
    building or another parked car."""
    beside = [g for g in gaps if g[2] != 0]
    if not beside:
        return None
    gap, si, sgn, t = min(beside)
    ax, az, bx, bz, fr, to, ei = lanes.segs[si]
    lw = float(lanes.edges[ei]["lw"])
    need = FREE_MIN - gap - lw
    if need <= 0.0:
        return gap + lw, ei
    dx, dz = bx - ax, bz - az
    n = math.hypot(dx, dz)
    nx, nz = -dz / n, dx / n
    fx, fz = ax + dx * t, az + dz * t
    # March away from the car past the near lane's far edge: a car left of the corridor (its first
    # lane from `fr`) looks right, a car right of it (its last lane, to `to`) looks left.
    far, out = (fr + lw, 1.0) if sgn < 0 else (to - lw, -1.0)
    s = 0.0
    while s < need:
        q = (fx + nx * (far + out * (s + STEP * 0.5)), fz + nz * (far + out * (s + STEP * 0.5)))
        if blk.blocked(q, me):
            break
        s += STEP
    return gap + lw + min(s, need + STEP), ei


def rows(cars):
    """[(kind, [car index, ...] sorted along the row)] for the parked cars (x, z, yaw): "side" rows
    stand side by side (a car park's bays, bake_osm.py bake_extras), "tail" rows nose to tail (a
    parking lane, road_design.py park_cars), "one" a car alone."""
    parent = list(range(len(cars)))
    kind = {}

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    cell = max(ROW_GAP, ROW_GAP_TAIL)
    grid = defaultdict(list)
    for i, c in enumerate(cars):
        grid[(int(c[0] // cell), int(c[1] // cell))].append(i)
    for i, (x, z, yaw) in enumerate(cars):
        (rx, rz), (bx, bz) = axes(yaw)
        ci, cj = int(x // cell), int(z // cell)
        for a in (-1, 0, 1):
            for b in (-1, 0, 1):
                for j in grid.get((ci + a, cj + b), ()):
                    if j <= i:
                        continue
                    x2, z2, y2 = cars[j]
                    if abs((yaw - y2 + math.pi / 2) % math.pi - math.pi / 2) > ROW_YAW:
                        continue
                    ddx, ddz = x2 - x, z2 - z
                    across, along = ddx * rx + ddz * rz, ddx * bx + ddz * bz
                    dist = math.hypot(ddx, ddz)
                    if abs(along) <= ROW_LINE + ROW_BEND * dist and abs(across) <= ROW_GAP:
                        k = "side"
                    elif abs(across) <= ROW_LINE + ROW_BEND * dist and abs(along) <= ROW_GAP_TAIL:
                        k = "tail"
                    else:
                        continue
                    pi_, pj = find(i), find(j)
                    if pi_ != pj:
                        lo, hi = min(pi_, pj), max(pi_, pj)
                        parent[hi] = lo
                        kind[lo] = kind.get(lo) or kind.get(hi) or k
    groups = defaultdict(list)
    for i in range(len(cars)):
        groups[find(i)].append(i)
    out = []
    for root, g in groups.items():
        k = kind.get(root, "one")
        # Along the row: the first car's width (side) or length (tail) direction, its heading taken
        # mod pi so the two facings of one line agree.
        (rx, rz), (bx, bz) = axes(cars[g[0]][2] % math.pi)
        ux, uz = (bx, bz) if k == "tail" else (rx, rz)
        g.sort(key=lambda i: (round(cars[i][0] * ux + cars[i][1] * uz, 2), cars[i][0], cars[i][1]))
        out.append((k, g))
    out.sort(key=lambda kg: kg[1][0])
    return out


def lane_depth(lanes, car):
    """(depth, push x, push z) of the deepest of the box's points inside a lane corridor (the way
    out across that corridor's nearer edge), or None when the box is clear (in_lane's test)."""
    x, z, yaw = car
    best = None
    for si in lanes.near(x, z):
        ax, az, bx, bz, fr, to, _ = lanes.segs[si]
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        n = math.sqrt(l2)
        for q in box_points(x, z, yaw):
            t = ((q[0] - ax) * dx + (q[1] - az) * dz) / l2
            if t < 0.0 or t > 1.0:
                continue
            side = ((q[0] - ax) * -dz + (q[1] - az) * dx) / n
            if fr + HAIR < side < to - HAIR:
                dep, sgn = (side - fr, -1.0) if side - fr < to - side else (to - side, 1.0)
                if best is None or dep > best[0]:
                    best = (dep, -dz / n * sgn, dx / n * sgn)
    return best


def boxes_meet(a, b):
    """Whether two parked cars' boxes overlap (separating axes: each box's two axes)."""
    for yaw in (a[2], b[2]):
        for ux, uz in axes(yaw):
            pa = a[0] * ux + a[1] * uz
            pb = b[0] * ux + b[1] * uz
            ra = sum(abs(px * ux + pz * uz) * h for (px, pz), h in zip(axes(a[2]), CAR_HALF))
            rb = sum(abs(px * ux + pz * uz) * h for (px, pz), h in zip(axes(b[2]), CAR_HALF))
            if abs(pa - pb) > ra + rb:
                return False
    return True


def move_out(lanes, blk, car, me):
    """IN: the bay `car` moved straight out of the lane it reaches into, by its depth and IN_CLEAR
    (steps of 0.1 m up to IN_SHIFT_MAX), to a spot clear of every lane, building, zebra, tram track
    and other parked car; or None."""
    hit = lane_depth(lanes, car)
    if hit is None:
        return None
    dep, px, pz = hit
    shift = dep + IN_CLEAR
    w = blk.w
    while shift <= IN_SHIFT_MAX + 1e-6:
        q = (round(car[0] + px * shift, 1), round(car[1] + pz * shift, 1), car[2])
        shift += 0.1
        if in_lane(lanes, q):
            continue
        if any(w.in_building(c, 0.0) for c in box_points(*q)[:4] + [q[:2]]):
            continue
        if w.on_line(w.zebras, q[:2], pad=0.2) or w.on_track(q[:2]):
            continue
        if any(i != me and boxes_meet(q, blk.cars[i]) for i in blk.grid.get(_cell(q[0], q[1]), ())):
            continue
        return q[:2]
    return None


def plan(d, map_dir=None):
    """({car index: rule} of the cars to remove, {car index: (x, z)} of the bays moved out of a lane,
    per-car notes [(index, x, z, street, free width, rule or "", row, index along the row, row
    length, pinched, row kind)] for the report)."""
    flat = d.get("parked", [])
    cars = [(float(flat[i]), float(flat[i + 1]), float(flat[i + 2])) for i in range(0, len(flat) - STRIDE + 1, STRIDE)]
    lanes = Lanes(d, map_dir)
    blk = Blockers(d, cars, lanes)
    drop = {}
    moves = {}
    pinched = {}
    street = {}
    free = {}
    for i, car in enumerate(cars):
        gaps = lane_gaps(lanes, car)
        near = min(gaps)[1] if gaps else None
        street[i] = lanes.edges[lanes.segs[near][6]].get("name", "") if near is not None else ""
        if in_lane(lanes, car):
            q = move_out(lanes, blk, car, i)
            if q is None:
                drop[i] = "IN"
                continue
            moves[i] = q
            car = (q[0], q[1], car[2])
            gaps = lane_gaps(lanes, car)
        if gaps and min(g[0] for g in gaps) < JUNCTION_EDGE and lanes.near_junction(car[0], car[1], JUNCTION_R):
            drop[i] = "JN"
            moves.pop(i, None)
            continue
        fw = free_width(lanes, blk, car, i, gaps)
        if fw is not None:
            free[i] = fw[0]
            street[i] = lanes.edges[fw[1]].get("name", "") or street[i]
            if fw[0] < FREE_MIN:
                pinched[i] = True
    notes = []
    row_of = {}
    for ri, (kind, g) in enumerate(rows(cars)):
        for k, i in enumerate(g):
            row_of[i] = (ri, k, len(g), kind)
            if i in pinched and k % 2 == 1 and i not in drop:
                drop[i] = "PINCH"
                moves.pop(i, None)
    for i, (x, z, _) in enumerate(cars):
        ri, k, n, kind = row_of[i]
        rule = drop.get(i, "MOVED" if i in moves else "")
        notes.append((i, x, z, street[i], free.get(i), rule, ri, k, n, i in pinched, kind))
    return drop, moves, notes


def thin(d, drop, moves):
    flat = d.get("parked", [])
    keep = []
    for k in range(len(flat) // STRIDE):
        if k in drop:
            continue
        rec = list(flat[k * STRIDE:(k + 1) * STRIDE])
        if k in moves:
            rec[0], rec[1] = moves[k]
        keep += rec
    d["parked"] = keep


def summary(drop, moves, n):
    c = Counter(drop.values())
    return "%d of %d parked cars removed (in a lane %d, by a junction %d, pinched rows %d), %d moved out of a lane" % (
        len(drop), n, c.get("IN", 0), c.get("JN", 0), c.get("PINCH", 0), len(moves))


def apply(out, map_dir=None, dry=False):
    """Thins the parked rows of the finished map data in place; returns a one-line summary.
    `map_dir`: the folder with terrain.json (the deck lanes' level test), the map's own."""
    if int(out.get(KEY, 0)) >= VERSION and not dry:
        return "already thinned"
    drop, moves, _ = plan(out, map_dir)
    msg = summary(drop, moves, len(out.get("parked", [])) // STRIDE)
    if dry:
        return "would: " + msg
    thin(out, drop, moves)
    out[KEY] = VERSION
    return msg


def census(d, map_dir=None):
    """The defect classes on the map as it is: IN bays in a lane (moved or not), JN cars by a junction
    within JUNCTION_EDGE m of a lane, PAIR two pinched cars of a row in neighbouring bays."""
    drop, moves, notes = plan(d, map_dir)
    c = Counter(r for r in drop.values() if r != "PINCH")
    c["IN"] += len(moves)
    by_row = defaultdict(list)
    for i, x, z, st, fw, rule, ri, k, n, p, kind in notes:
        by_row[ri].append((k, x, z, p, rule, kind))
    pairs = []
    for ri, cs in by_row.items():
        cs.sort()
        for a, b in zip(cs, cs[1:]):
            if a[3] and b[3] and a[4] not in ("IN", "JN") and b[4] not in ("IN", "JN") \
                    and a[5] != "one" and math.hypot(a[1] - b[1], a[2] - b[2]) < PAIR_GAP[a[5]]:
                pairs.append((a[1], a[2]))
    c["PAIR"] = len(pairs)
    return c, drop, pairs


def write_tsv(path, notes):
    """Per street (the nearest lane's name): cars before and after, removed by rule, moved; then
    every car the pass touches."""
    by = defaultdict(lambda: [0, Counter()])
    for i, x, z, st, fw, rule, ri, k, n, p, kind in notes:
        s = by[st or "(no lane near)"]
        s[0] += 1
        s[1][rule] += 1
    with open(path, "w", encoding="utf-8") as f:
        f.write("street\tbefore\tafter\tremoved\tin_lane\tjunction\tpinch\tmoved_out_of_lane\tpinched_kept\n")
        rows_ = []
        for st, (b, c) in by.items():
            gone = c["IN"] + c["JN"] + c["PINCH"]
            rows_.append((-gone, -c["MOVED"], st, b, b - gone, gone, c["IN"], c["JN"], c["PINCH"], c["MOVED"]))
        kept = Counter(st or "(no lane near)" for i, x, z, st, fw, rule, ri, k, n, p, kind in notes if p and rule in ("", "MOVED"))
        for r in sorted(rows_):
            f.write("%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n" % (r[2:] + (kept.get(r[2], 0),)))
        tot = [sum(1 for _ in notes), 0, 0, 0, 0, 0, 0]
        for i, x, z, st, fw, rule, ri, k, n, p, kind in notes:
            tot[2] += rule == "IN"
            tot[3] += rule == "JN"
            tot[4] += rule == "PINCH"
            tot[5] += rule == "MOVED"
            tot[6] += bool(p) and rule in ("", "MOVED")
        gone = tot[2] + tot[3] + tot[4]
        f.write("TOTAL\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n" % (tot[0], tot[0] - gone, gone, tot[2], tot[3], tot[4], tot[5], tot[6]))
        f.write("\n# every car the pass touches: rule, x, z, street, free width (m), row kind, index in row / row length\n")
        for i, x, z, st, fw, rule, ri, k, n, p, kind in notes:
            if rule:
                f.write("%s\t%.1f\t%.1f\t%s\t%s\t%s\t%d/%d\n" % (rule, x, z, st, "" if fw is None else "%.2f" % fw, kind, k, n))


def check(path):
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if int(d.get(KEY, 0)) < VERSION:
        print("parked_thin: FAIL the map is not thinned: run python3 -I tools/parked_thin.py")
        return 1
    c, _, _ = census(d, os.path.dirname(os.path.abspath(path)))
    info = "bays in a lane %d, by a junction within %.0f m of a lane %d, pinched pairs in neighbouring bays %d; %d parked cars" % (
        c.get("IN", 0), JUNCTION_EDGE, c.get("JN", 0), c.get("PAIR", 0), len(d.get("parked", [])) // STRIDE)
    bad = [f"{r} {c.get(r, 0)} > {n}" for r, n in CHECK_LEFT.items() if c.get(r, 0) > n]
    if bad:
        print("parked_thin: FAIL " + "; ".join(bad) + " (" + info + ")")
        return 1
    print("parked_thin: OK (" + info + ")")
    return 0


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    opt = {}
    for a in argv:
        if a.startswith("--"):
            k, _, v = a[2:].partition("=")
            opt[k] = v or "1"
        else:
            path = a
    if "check" in opt:
        return check(path)
    map_dir = os.path.dirname(os.path.abspath(path))
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if "census" in opt:
        c, _, _ = census(d, map_dir)
        print("parked_thin census: in a lane %d, by a junction %d, pinched pairs in neighbouring bays %d; %d parked cars" % (
            c.get("IN", 0), c.get("JN", 0), c.get("PAIR", 0), len(d.get("parked", [])) // STRIDE))
        return 0
    dry = "dry" in opt
    if "tsv" in opt or "list" in opt:
        drop, moves, notes = plan(d, map_dir)
        if "tsv" in opt:
            write_tsv(opt["tsv"], notes)
        if "list" in opt:
            for i, x, z, st, fw, rule, ri, k, n, p, kind in notes:
                if rule:
                    print("  %-5s %8.1f %8.1f  %-28s free %s  %s row %d/%d%s" % (
                        rule, x, z, st, "-" if fw is None else "%.2f" % fw, kind, k, n,
                        "  -> %.1f, %.1f" % moves[i] if i in moves else ""))
    msg = apply(d, map_dir, dry)
    print("parked_thin: " + msg)
    if not dry and msg != "already thinned":
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
