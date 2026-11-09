"""Bus shelters on the kerb and benches facing the walk (G8, G9 of the gameplay pass, 2026-11-01).

    python3 -I tools/snap_props.py [MAP.json] [--dry] [--face-only]   (rewrites the map in place, idempotent;
                                    --face-only: only `face_shelters`, the last pass bake_osm.py runs)

The OpenStreetMap shelter and bench nodes were given their yaw from the nearest road's *direction*
(bake_osm.py `road_yaw`): a shelter's roof ran across the road, half of them with their glass back
to the lane and the bench side to the kerb, and many stood on the lawn 6-12 m behind the footway.
This module fixes both on the finished map data (bake_osm.py calls `apply(out)` right after
bake_structures; this file is also a command line tool for a map that is already baked, as the
cloud has no OpenStreetMap download):

- **Shelters** beside a bus road (a graph edge of class 0 or 1 (lane_graph.gd `_class_of`), the
  shelter on its right within SNAP_MAX m of the kerb lane's edge): moved along the normal so its
  centre stands KERB_OUT m past the kerb lane's edge (roof 0.8 m clear of the kerb), turned with its
  roof along the road and the glass back away from it (map_builder.gd: the road is on its -z side).
  A spot that is blocked (building, water, a lane or carriageway, a tram track, a lamp, a tree,
  another shelter) is tried again further from the kerb and slid along the road; else the shelter
  keeps its place and only turns. A tram stop's shelter (a tram track within TRAM_NEAR) is left.
  buses.gd `stop_from` takes the stop from the shelter's place, so the bay follows. The roof
  scooters standing on a moved shelter move with it.
- **Every other shelter** (`face_shelters`, also run once more at the end of bake_osm.py, after the
  later passes have moved them): a tram stop's (a track within TRAM_NEAR) is turned open side to the
  nearest track, the boarding edge; one off the bus roads open side to the nearest road within
  FACE_REACH. They had kept `road_yaw`: the roof across the street, the open side along it (F,
  2026-11-08: "the stops at Ratusz Arsenał are turned the wrong way").
- **Benches** are turned to face the nearest footway or path (or the kerb where there is none):
  the seat looks across the walk, not along it. A bench within BENCH_LANE m of a lane slides out.

Deterministic, standard library only. tools/check_stops.py checks the result.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as P  # noqa: E402

MAP = os.path.join(ROOT, "game", "map", "centrum.json")
SNAP_MAX = 14.0          # a shelter this far or nearer to a bus road's kerb lane edge is a bus stop
KERB_OUT = 1.7           # its centre this far past that edge (the roof's front edge 0.8 m clear)
KERB_TRIES = (1.7, 2.1, 2.6, 3.3)
SLIDES = (0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0, 8.0, -8.0)
HALF_ROOF = 2.15         # the roof's half length (along the road) and its depth either side of the origin
FRONT, BACK = 0.9, 1.0
TRAM_NEAR = 6.0          # a tram track this near: a tram stop's shelter, not ours
TRAM_CLEAR = 1.8
LANE_PAD = 0.25
SHELTER_GAP = 4.5
BENCH_LANE = 1.0         # a bench stands at least this far from a lane
BENCH_PATHS = ("foot", "cycle")
CELL = 32.0
SCOOTER_CLEAR = 3.4      # a lying scooter this near a shelter's origin (the roof's end plus the scooter) is moved
ROOF_RADIUS = 2.6        # a poi this near a moved shelter's origin is on its roof
FACE_REACH = 16.0        # a shelter off any bus road faces the nearest road this near (else it is left)
TRAM_HALF = 1.3          # a tram's half width: its side is this far from the track's centre line
TRACK_ON = 1.0           # a tram stop's shelter nearer a track than this stands on it: left as it is


def _cell(x, z):
    return int(math.floor(x / CELL)), int(math.floor(z / CELL))


class Grid:
    def __init__(self):
        self.cells = {}

    def add_seg(self, a, b, item, reach=0.0):
        for i in range(int(math.floor((min(a[0], b[0]) - reach) / CELL)), int(math.floor((max(a[0], b[0]) + reach) / CELL)) + 1):
            for j in range(int(math.floor((min(a[1], b[1]) - reach) / CELL)), int(math.floor((max(a[1], b[1]) + reach) / CELL)) + 1):
                self.cells.setdefault((i, j), []).append((a, b, item))

    def add_pt(self, x, z, item=None):
        self.cells.setdefault(_cell(x, z), []).append(((x, z), (x, z), item))

    def near(self, x, z):
        return self.cells.get(_cell(x, z), ())


def class_of(kind):
    """lane_graph.gd `_class_of`."""
    if kind in ("primary", "secondary", "trunk", "motorway"):
        return 0
    if kind in ("residential", "unclassified"):
        return 2
    if kind == "living_street":
        return 3
    return 1


class World:
    """What a shelter or bench must keep clear of, from the finished map data."""

    def __init__(self, d):
        self.d = d
        self.edges = []
        self.edge_grid = Grid()
        for e in d["graph"]["edges"]:
            if e.get("dk", -1) >= 0 or e.get("tn", -1) >= 0 or e.get("br", 0):
                continue
            p = P.pairs(e["p"])
            if len(p) < 2:
                continue
            cum = [0.0]
            for a, b in zip(p, p[1:]):
                cum.append(cum[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
            info = {"p": p, "cum": cum, "cls": class_of(e["k"]), "n": e["n"], "lw": e["lw"], "o": e["o"],
                    "left": e["o"] - e["lw"] * 0.5, "right": e["o"] + e["lw"] * (e["n"] - 1) + e["lw"] * 0.5,
                    "s0": e["s0"], "s1": e["s1"], "k": e["k"], "i": len(self.edges)}
            self.edges.append(info)
            for k, (a, b) in enumerate(zip(p, p[1:])):
                self.edge_grid.add_seg(a, b, (info, k), SNAP_MAX + 6.0)
        self.polys = P.Polys()
        self.walls = P.Segs()
        for b in d.get("buildings", []):
            if b.get("cutd"):
                continue
            pts = P.pairs(b["p"])
            self.polys.add(pts, "building")
            self.walls.add_line(pts + pts[:1], 0.2, "building")
        for a in d.get("areas", []):
            if a["k"] == "water":
                pts = P.pairs(a["p"])
                self.polys.add(pts, "water")
                self.walls.add_line(pts + pts[:1], 0.5, "water")
        for c in d.get("carriage", []):
            self.polys.add(P.pairs(c["p"]), "carriageway")
        for key in ("platforms", "islands"):
            for a in d.get(key, []):
                self.polys.add(P.pairs(a["p"]), key)
        for t in d.get("trams", []):
            self.walls.add_line(P.pairs(t["p"]), TRAM_CLEAR, "tram")
        self.tram_grid = Grid()
        for t in d.get("trams", []):
            p = P.pairs(t["p"])
            for a, b in zip(p, p[1:]):
                self.tram_grid.add_seg(a, b, None, TRAM_NEAR)
        self.pts = Grid()   # lamps, signals, columns, bikes, bins, trees: stride, clear radius
        for key, stride, r in (("lamps", 2, 0.5), ("signals", 3, 0.6), ("columns", 3, 1.0), ("bikes", 3, 1.0),
                               ("trees3d", 6, 0.7)):
            v = d.get(key, [])
            for i in range(0, len(v) - stride + 1, stride):
                self.pts.add_pt(v[i], v[i + 1], r)
        self.shelters = Grid()
        sh = d.get("shelters", [])
        for i in range(0, len(sh) - 2, 3):
            self.shelters.add_pt(sh[i], sh[i + 1], i)
        self.paths = Grid()
        for pa in d.get("paths", []):
            if pa["k"] in BENCH_PATHS:
                p = P.pairs(pa["p"])
                for a, b in zip(p, p[1:]):
                    self.paths.add_seg(a, b, pa["w"], 30.0)

    # --- the road ------------------------------------------------------------------------------

    @staticmethod
    def frame(info, k, x, z):
        """(foot point, tangent, right normal, lateral offset to the right, along s) at segment k."""
        a, b = info["p"][k], info["p"][k + 1]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dz) or 1.0
        t = (dx / ln, dz / ln)
        u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / (ln * ln)))
        foot = (a[0] + dx * u, a[1] + dz * u)
        r = (-t[1], t[0])
        lat = (x - foot[0]) * r[0] + (z - foot[1]) * r[1]
        return foot, t, r, lat, info["cum"][k] + ln * u, u

    def in_lane(self, x, z, pad=LANE_PAD):
        """True if (x, z) stands over a graph edge's lanes (and `pad`) beside a segment's inside."""
        for a, b, (info, k) in self.edge_grid.near(x, z):
            foot, t, r, lat, s, u = self.frame(info, k, x, z)
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            # a point past a segment's end is the next segment's: only those inside count
            if (u <= 0.0 or u >= 1.0) and not (u <= 0.0 and k == 0) and not (u >= 1.0 and k == len(info["p"]) - 2):
                if math.hypot(x - foot[0], z - foot[1]) > info["right"] + pad:
                    continue
            if info["left"] - pad < lat < info["right"] + pad:
                return True
        return False

    def bus_stop_edge(self, x, z):
        """The bus road (class 0-1) whose kerb lane's edge the point is on the right of, nearest first:
        (info, k, foot, t, r, lat, out) or None."""
        best = None
        for a, b, (info, k) in self.edge_grid.near(x, z):
            if info["cls"] > 1:
                continue
            foot, t, r, lat, s, u = self.frame(info, k, x, z)
            if u <= 0.0 or u >= 1.0:
                continue
            if s < info["s0"] - 1.0 or s > info["s1"] + 1.0:
                continue
            out = lat - info["right"]
            if -0.6 <= out <= SNAP_MAX and (best is None or out < best[6]):
                best = (info, k, foot, t, r, lat, out)
        return best

    def tram_near(self, x, z):
        for a, b, _ in self.tram_grid.near(x, z):
            if P.seg_dist(x, z, a, b) < TRAM_NEAR:
                return True
        return False

    # --- a shelter's footprint -----------------------------------------------------------------

    def shelter_clear(self, x, z, tx, tz, nx, nz, own=-1):
        """Footprint (HALF_ROOF either side along (tx, tz), FRONT toward the road (nx, nz) and BACK
        behind) clear of everything."""
        spots = [(x + tx * u + nx * w, z + tz * u + nz * w) for u in (-HALF_ROOF, 0.0, HALF_ROOF) for w in (FRONT, 0.0, -BACK)]
        for px, pz in spots:
            if self.polys.inside(px, pz):
                return False
            if self.in_lane(px, pz):
                return False
        for px, pz in spots:
            if self.walls.near(px, pz, 0.0):
                return False
        for a, b, r in self.pts.near(x, z):
            ux, uz = a[0] - x, a[1] - z
            u = ux * tx + uz * tz
            w = ux * nx + uz * nz
            if abs(u) < HALF_ROOF + r and -BACK - r < w < FRONT + r:
                return False
        for a, b, i in self.shelters.near(x, z):
            if i != own and math.hypot(a[0] - x, a[1] - z) < SHELTER_GAP:
                return False
        return True


def snap_shelters(d, world=None):
    """Move and turn the shelters on bus roads; returns (moved, turned, left, tram, off_road, moves, dropped) with
    `moves` = [(old x, old z, old yaw, new x, new z, new yaw)]."""
    w = world or World(d)
    sh = d.get("shelters", [])
    moved = turned = left = tram = off = 0
    moves = []
    drop = []
    for i in range(0, len(sh) - 2, 3):
        x, z, yaw = sh[i], sh[i + 1], sh[i + 2]
        hit = w.bus_stop_edge(x, z)
        if hit is None:
            off += 1
            continue
        if w.tram_near(x, z):
            tram += 1
            continue
        info, k, foot, t, r, lat, out = hit
        # the road is on its -z side: the way to the road is -r, so Basis(UP, yaw)'s -z is -r
        nx, nz = -r[0], -r[1]
        new_yaw = round(math.atan2(r[0], r[1]), 2)
        if abs(new_yaw - yaw) <= 0.08 and KERB_TRIES[0] - 0.15 <= out <= KERB_TRIES[-1] + 0.15 \
                and w.shelter_clear(x, z, t[0], t[1], nx, nz, own=i):
            sh[i + 2] = new_yaw
            continue   # already on the kerb (a second run changes nothing)
        placed = None
        for kerb in KERB_TRIES:
            for slide in SLIDES:
                px = foot[0] + t[0] * slide + r[0] * (info["right"] + kerb)
                pz = foot[1] + t[1] * slide + r[1] * (info["right"] + kerb)
                # the same road's lane there (a bend): the lateral must still be ours
                if w.shelter_clear(px, pz, t[0], t[1], nx, nz, own=i):
                    placed = (px, pz)
                    break
            if placed:
                break
        if placed is None and not w.shelter_clear(x, z, t[0], t[1], nx, nz, own=i):
            drop.append(i)   # no clear spot and its own is in a lane or a building: left out
            continue
        if placed is None:
            if abs(new_yaw - yaw) > 0.005:
                sh[i + 2] = new_yaw
                turned += 1
                moves.append((x, z, yaw, x, z, new_yaw))
            left += 1
            continue
        nxp, nzp = round(placed[0], 1), round(placed[1], 1)
        if (nxp, nzp, new_yaw) != (x, z, yaw):
            w.shelters.cells[_cell(x, z)] = [c for c in w.shelters.cells.get(_cell(x, z), ()) if c[2] != i]
            w.shelters.add_pt(nxp, nzp, i)
            sh[i], sh[i + 1], sh[i + 2] = nxp, nzp, new_yaw
            moved += 1
            moves.append((x, z, yaw, nxp, nzp, new_yaw))
    for i in reversed(drop):
        del sh[i:i + 3]
    return moved, turned, left, tram, off, moves, len(drop)


def _front_yaw(x, z, fx, fz):
    """The yaw that turns a shelter at (x, z) open side (-z, map_builder.gd) toward (fx, fz)."""
    return round(math.atan2(-(fx - x), -(fz - z)), 2)


def _nearest_track(w, x, z):
    """(distance, foot) of the nearest tram track within TRAM_NEAR, or None."""
    best = None
    for a, b, _ in w.tram_grid.near(x, z):
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = dx * dx + dz * dz
        if ln == 0:
            continue
        u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
        foot = (a[0] + dx * u, a[1] + dz * u)
        dd = math.hypot(x - foot[0], z - foot[1])
        if dd < TRAM_NEAR and (best is None or dd < best[0]):
            best = (dd, foot)
    return best


def _on_tram_island(w, x, z):
    """True on a tram island (tools/tram_stops.py `tram` platforms): it boards from its tracks."""
    if not hasattr(w, "tram_islands"):
        w.tram_islands = P.Polys()
        for a in w.d.get("platforms", []):
            if a.get("tram"):
                w.tram_islands.add(P.pairs(a["p"]), "tram")
    return w.tram_islands.inside(x, z) is not None


def _nearest_road(w, x, z):
    """(distance, foot) of the nearest road's centre line within FACE_REACH (any class), a segment's
    inside before its ends (at a junction the end's foot would turn the shelter diagonally), or None."""
    best = None
    for a, b, (info, k) in w.edge_grid.near(x, z):
        foot, t, r, lat, s, u = w.frame(info, k, x, z)
        dd = math.hypot(x - foot[0], z - foot[1])
        if dd > FACE_REACH:
            continue
        key = (0 if 0.0 < u < 1.0 else 1, dd)
        if best is None or key < best[0]:
            best = (key, foot)
    return None if best is None else (best[0][1], best[1])


def shelter_want(w, x, z):
    """What a shelter at (x, z) must face (PT, F 2026-11-08: Ratusz Arsenał's stood turned the wrong
    way): ("bus", yaw) beside a bus road (unless a tram track is nearer than its kerb, or it stands on a
    tram island) (snap_shelters' own turn: roof along the road, open side to
    the kerb), ("tram", yaw) at a tram stop (open side to the nearest track, the boarding edge),
    ("road", yaw) off the bus roads (open side to the nearest road within FACE_REACH), or (kind, None)
    when nothing decides it (no road near, or a track right under it)."""
    tr = _nearest_track(w, x, z)
    hit = w.bus_stop_edge(x, z)
    if tr is not None and hit is not None and not _on_tram_island(w, x, z) and hit[6] < tr[0] - TRAM_HALF:
        tr = None   # on the pavement with the kerb nearer than the tram's side: the bus stop's
    if tr is not None:
        return ("tram", None) if tr[0] < TRACK_ON else ("tram", _front_yaw(x, z, *tr[1]))
    if hit is not None:
        r = hit[4]
        return "bus", round(math.atan2(r[0], r[1]), 2)
    rd = _nearest_road(w, x, z)
    return ("road", None) if rd is None else ("road", _front_yaw(x, z, *rd[1]))


def face_shelters(d, world=None):
    """Turn every shelter open side to its boarding edge (`shelter_want`): the tram stops' and those
    off the bus roads, which snap_shelters leaves, and any a later pass moved off its turn. bake_osm.py `road_yaw` gave them the nearest
    road's *direction*, so their roof ran across the street with the open side along it, and a tram
    island's could turn its glass back to the track. Returns (tram turned, road turned, left)."""
    w = world or World(d)
    sh = d.get("shelters", [])
    n_tram = n_road = left = 0
    for i in range(0, len(sh) - 2, 3):
        kind, want = shelter_want(w, sh[i], sh[i + 1])
        if want is None:
            left += 1
            continue
        if abs(math.remainder(sh[i + 2] - want, 2 * math.pi)) > 0.005:
            sh[i + 2] = want
            if kind == "tram":
                n_tram += 1
            else:
                n_road += 1   # off the bus roads, or a bus stop by a track snap_shelters left
    return n_tram, n_road, left


def move_roof_pois(d, moves):
    """The Leżaks on a moved shelter's roof ride along (the bake's order is shelters first, so this is
    only for a map that is already baked): p == "roof" pois within ROOF_RADIUS of an old origin."""
    n = 0
    for p in d.get("pois", []):
        if p.get("p") != "roof":
            continue
        best = None
        for ox, oz, oy, nx, nz, ny in moves:
            dd = math.hypot(p["x"] - ox, p["z"] - oz)
            if dd < ROOF_RADIUS and (best is None or dd < best[0]):
                best = (dd, ox, oz, oy, nx, nz, ny)
        if best is None:
            continue
        _, ox, oz, oy, nx, nz, ny = best
        # local coordinates in the old frame: X = (cos, -sin), Z = (sin, cos)
        ax = (p["x"] - ox) * math.cos(oy) - (p["z"] - oz) * math.sin(oy)
        az = (p["x"] - ox) * math.sin(oy) + (p["z"] - oz) * math.cos(oy)
        p["x"] = round(nx + ax * math.cos(ny) + az * math.sin(ny), 1)
        p["z"] = round(nz - ax * math.sin(ny) + az * math.cos(ny), 1)
        p["yaw"] = round((p["yaw"] + ny - oy) % (2 * math.pi), 2)
        n += 1
    # A scooter lying beside a shelter's old spot may now be under its roof: nudged out along the
    # shelter's own axis (the Leżaks are only ever beside it, never part of the stop).
    sh = d.get("shelters", [])
    solids = None
    lost = []
    for p in d.get("pois", []):
        if p.get("k") != "scooter" or p.get("p") in ("roof", "stand"):
            continue
        for i in range(0, len(sh) - 2, 3):
            dx, dz = p["x"] - sh[i], p["z"] - sh[i + 1]
            if math.hypot(dx, dz) >= SCOOTER_CLEAR:
                continue
            c, sn = math.cos(sh[i + 2]), math.sin(sh[i + 2])
            along = dx * c - dz * sn
            first = 1.0 if along >= 0 else -1.0
            if solids is None:
                solids = P.Solids(d)
            spot = None
            for reach in (HALF_ROOF + 1.2, HALF_ROOF + 2.4, HALF_ROOF + 4.0):
                for side in (first, -first):
                    q = (sh[i] + c * side * reach, sh[i + 1] - sn * side * reach)
                    if solids.blocked(q[0], q[1], P.R, skip=("shelter",)) is None:
                        spot = q
                        break
                if spot:
                    break
            if spot:
                p["x"], p["z"] = round(spot[0], 1), round(spot[1], 1)
                n += 1
            else:
                lost.append(p)   # nowhere clear beside the stop: this Leżak is left out
            break
    if lost:
        d["pois"] = [p for p in d["pois"] if not any(p is q for q in lost)]
        print("stops: %d lying scooters with no clear spot beside their stop left out" % len(lost))
    return n


def face_benches(d, world=None):
    """Turn the benches to face the nearest footway/path or kerb, slide the ones within BENCH_LANE of a lane
    out. Returns (turned, slid, left, gone)."""
    w = world or World(d)
    bn = d.get("benches", [])
    turned = slid = left = 0
    keep = []
    for i in range(0, len(bn) - 2, 3):   # G9: a bench inside a building or the water is left out
        if w.polys.inside(bn[i], bn[i + 1]) in ("building", "water", "carriageway"):
            continue
        keep += bn[i:i + 3]
    gone = (len(bn) - len(keep)) // 3
    bn[:] = keep
    for i in range(0, len(bn) - 2, 3):
        x, z, yaw = bn[i], bn[i + 1], bn[i + 2]
        best = None   # (distance, nx, nz) toward the thing it faces
        for a, b, wd in w.paths.near(x, z):
            dd = P.seg_dist(x, z, a, b)
            if dd > 25.0:
                continue
            if best is None or dd < best[0]:
                dx, dz = b[0] - a[0], b[1] - a[1]
                ln = dx * dx + dz * dz
                u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
                fx, fz = a[0] + dx * u, a[1] + dz * u
                if dd < 0.05:
                    l = math.sqrt(ln) or 1.0
                    best = (dd, -dz / l, dx / l)
                else:
                    best = (dd, (fx - x) / dd, (fz - z) / dd)
        kerb = None
        for a, b, (info, k) in w.edge_grid.near(x, z):
            foot, t, r, lat, s, u = w.frame(info, k, x, z)
            if u <= 0.0 or u >= 1.0:
                continue
            edge = info["right"] if lat > 0 else -info["left"]
            dd = abs(lat) - edge
            if kerb is None or dd < kerb[0]:
                kerb = (dd, foot, r if lat > 0 else (-r[0], -r[1]), lat)
        nx = nz = None
        if best is not None and (kerb is None or best[0] <= kerb[0] + 6.0):
            nx, nz = best[1], best[2]
        elif kerb is not None and kerb[0] < 25.0:
            f = kerb[1]
            dd = math.hypot(f[0] - x, f[1] - z) or 1.0
            nx, nz = (f[0] - x) / dd, (f[1] - z) / dd
        if nx is None:
            left += 1
            continue
        new_yaw = round(math.atan2(-nx, -nz), 2)
        if kerb is not None and 0 <= kerb[0] < BENCH_LANE:
            side = kerb[2]
            want = BENCH_LANE - kerb[0] + 0.1
            px, pz = x + side[0] * want, z + side[1] * want
            if not w.polys.inside(px, pz) and not w.in_lane(px, pz, 0.0) and not w.walls.near(px, pz, 0.0):
                bn[i], bn[i + 1] = round(px, 1), round(pz, 1)
                slid += 1
        if abs(new_yaw - yaw) > 0.005:
            bn[i + 2] = new_yaw
            turned += 1
    return turned, slid, left, gone


def apply(d, roof_pois=False):
    """bake_osm.py: snap the shelters and benches of the finished map data `d`; prints one line."""
    w = World(d)
    moved, turned, left, tram, off, moves, dropped = snap_shelters(d, w)
    roof = move_roof_pois(d, moves) if roof_pois else 0
    bt, bs, bl, bg = face_benches(d, w)
    ft, fr, fl = face_shelters(d, w)
    msg = (f"stops (G8/G9): {moved} shelters moved to the kerb, {turned} turned only, {left} kept in place (no clear spot), {dropped} left out (no clear spot, their own in a lane or a building), "
           f"facing: {ft} tram stop and {fr} other shelters turned open side to the track or road, {fl} left (nothing near or a track under them); "
           f"{tram} tram stops and {off} off any bus road left; {roof} roof scooters moved along; "
           f"benches: {bt} turned to face the walk, {bs} slid out of a lane's reach, {bl} left, {bg} inside a building or the water left out")
    print(msg)
    return msg


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else MAP
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if "--face-only" in argv:
        print("face_shelters: %d tram, %d road turned, %d left" % face_shelters(d))
    else:
        apply(d, roof_pois=True)
    if "--dry" in argv:
        return 0
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
