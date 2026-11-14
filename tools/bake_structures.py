"""Loop 3b: the city builder's structures, placed in the bake (docs/DEMO.md 4.4: R5, R6, R7 and
the buildings under decks) so that the game, tools/check_roads.py and game/tools/check_drive.gd
all read the same data.

Usage: imported by tools/bake_osm.py (`add_structures(out, map_dir)` on the finished map file,
before it is written). Standalone, on a baked map: python3 -I tools/bake_structures.py [MAP_DIR]
prints what it would place (nothing is written).

What it adds to the map file:
- `decks.piers` (R5): the boxes under the decks. A pier candidate stands every PIER_STEP metres
  along a road or rail deck where the deck clears the ground by PIER_MIN_AIR; it slides up to
  PIER_SLIDE metres along the deck to the nearest spot where its footprint is PIER_PAD clear of
  every road (half its width), tram and rail bed, kerb, carriageway area and lower deck under
  it (and of every lane's drive corridor; PT-18: first PIER_ROADSIDE more beside a main road,
  and clear of the street props, then without); where none is, two legs outside what runs under
  carry the deck (a portal frame, its cross-head the slab, a cap beam out to a leg that stands
  past the deck's edge), and where that fails too the pier is left out. The game draws them
  and makes them solid.
- `towers` (R7): Most Poniatowskiego's four towers seated (`place_towers`).
- `cut`, `cutd`, `pil` on buildings and `lod2_cuts` (C9): buildings under decks (`place_cuts`).
- `walls` (R6): retaining walls along the approaches, the tunnels and their open ramps
  (`place_walls`, `place_tunnels`); `tunnels.frames` (the portals) and `garage_doors`.
- `lines` and the solid props cleared out of the carriageways and lanes (`clear_carriageways`);
  fills widened to hold their lanes (`widen_fills`), road decks narrowed beside a ground lane
  (`narrow_decks`), LoD2 walls in a lane not solid
  (`lod2_open`), and `aprons` where a structure's end meets the ground (`place_aprons`).
- Map review A (2026-10-29): street furniture standing on a tram track left out
  (`clear_carriageways`), and `trees3d_crown` shrunk for scanned crowns through a deck's edge
  (`trim_crowns`).
"""
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)

PIER_FIRST = 20.0      # the first pier candidate this far along a deck piece...
PIER_STEP = 38.0       # ...then one every this many metres (map_builder.gd before loop 3b)
PIER_MIN_AIR = 2.5     # only where the deck stands this far over the ground
PIER_SLIDE = 12.0      # how far a pier may slide along its deck to a clear spot
PIER_PAD = 1.1         # clear of what runs under by this much (check_roads C4 wants 1.0)
PIER_ROADSIDE = 2.0    # PT-18: first try this much more beside a main road's carriageway (a car
                       # that drifts off its kerb lane rides on, not into a pier); else PIER_PAD
PIER_WIDE_KINDS = ("motorway", "trunk", "primary", "secondary", "tertiary")
# A pier that slides for PIER_ROADSIDE keeps this clear of the street props (key, stride, metres),
# so the room it takes from the road does not put it on a tram shelter.
PIER_PROPS = (("lamps", 2, 0.5), ("signals", 3, 0.5), ("benches", 3, 1.2), ("bins", 3, 0.7), ("bikes", 3, 1.2),
              ("columns", 3, 1.3), ("shelters", 3, 2.6), ("parked", 4, 2.8), ("trees3d", 6, 0.7))
PIER_ALONG = 1.6       # a pier's thickness along the deck
PIER_SHARE = 0.6       # its width across: this share of the deck's corridor
LEG_W = 1.2            # a portal leg: this wide across the deck...
LEG_REACH = 3.2        # ...standing at most this far past the deck's edge
LEG_SPAN_MIN = 3.0     # the two legs at least this far apart
SLAB = 1.3             # the slab under every deck (map_builder.gd)
TRAM_HALF, RAIL_HALF = 1.5, 2.0


def _seg_rect_dist(rect, a, b):
    """Distance from segment a-b to a convex quad (0 when it touches or crosses it)."""
    import check_roads as cr
    if cr.point_in_poly(a[0], a[1], rect) or cr.point_in_poly(b[0], b[1], rect):
        return 0.0
    return min(cr.seg_seg_dist(rect[q], rect[(q + 1) % 4], a, b) for q in range(4))


class Under:
    """What runs under the decks: segments with a half width, and carriageway polygons,
    each with the deck group it lies on (None on the ground)."""

    def __init__(self, m):
        import check_roads as cr
        self.m = m
        self.segs = cr.Grid(16.0)
        self.polys = cr.Grid(32.0)
        d = m.d

        def put(it, half, label):
            ps = cr.pairs(it["p"])
            for a, b in zip(ps, ps[1:]):
                self.segs.add((a, b, half, label, it), min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                              max(a[0], b[0]) + half, max(a[1], b[1]) + half)
        self.wide = set()
        self.props = cr.Grid(16.0)
        for key, stride, clear in PIER_PROPS:
            v = d.get(key, [])
            for i in range(0, len(v) - 1, stride):
                x, z = v[i], v[i + 1]
                self.props.add((x, z, clear), x - clear, z - clear, x + clear, z + clear)
        for r in d["roads"]:
            put(r, r["w"] * 0.5 + abs(r.get("c", 0.0)), r.get("name") or r["k"])
            if r["k"] in PIER_WIDE_KINDS or r.get("lanes", 0) >= 2:
                self.wide.add(id(r))
        for t in d.get("trams", []):
            put(t, TRAM_HALF, "tram")
        for t in d.get("rails", []):
            put(t, RAIL_HALF, "rail")
        for k in d.get("kerbs", []):
            put(k, 0.0, "kerb")
        for c in d.get("carriage", []):
            q = cr.pairs(c["p"])
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            self.polys.add((q, c), min(xs), min(zs), max(xs), max(zs))
        # The lanes' drive corridors (a bus's half width), with the edge's deck or tunnel.
        for e in d["graph"]["edges"]:
            if e.get("tn") is not None:
                continue
            pts = cr.pairs(e["p"])
            for k in range(e["n"]):
                q = cr.offset_line(pts, e["o"] + e["lw"] * k)
                for a, b in zip(q, q[1:]):
                    self.segs.add((a, b, 1.4, "lane", {"dk": e.get("dk"), "_lane": 1}),
                                  min(a[0], b[0]) - 1.4, min(a[1], b[1]) - 1.4, max(a[0], b[0]) + 1.4, max(a[1], b[1]) + 1.4)
        # Lower decks: their corridors, as segments with the corridor's half width.
        for i, pc in enumerate(m.decks.p):
            half = max(pc["l"], pc["r"]) + 0.2
            for k in range(len(pc["pts"]) - 1):
                a, b = pc["pts"][k], pc["pts"][k + 1]
                self.segs.add((a, b, half, f"deck {pc['g']}", {"dk": pc["g"], "_piece": i}),
                              min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                              max(a[0], b[0]) + half, max(a[1], b[1]) + half)

    def blocked(self, rect, g, top, x, z, roadside=0.0):
        """The first thing under deck group g (its top at `top`) a footprint comes within
        PIER_PAD of (`roadside` more for a main road), or None."""
        import check_roads as cr
        m = self.m
        seen = set()
        for cell in {(math.floor(px / 16.0), math.floor(pz / 16.0)) for px, pz in rect + [(x, z)]}:
            for a, b, half, label, it in self.segs.cells.get(cell, ()):
                key = (id(it), a, b)
                if key in seen:
                    continue
                seen.add(key)
                if it.get("dk") is not None:
                    # On a deck (its own included: a lower ramp of the same structure): its
                    # height where it passes nearest, against the pier's top.
                    abx, abz = b[0] - a[0], b[1] - a[1]
                    t = min(max(((x - a[0]) * abx + (z - a[1]) * abz) / max(abx * abx + abz * abz, 1e-6), 0.0), 1.0)
                    qx, qz = a[0] + abx * t, a[1] + abz * t
                    if m.decks.height(it["dk"], qx, qz, m.terrain(qx, qz)) > top - 1.0:
                        continue
                pad = PIER_PAD + (roadside if id(it) in self.wide else 0.0)
                if _seg_rect_dist(rect, a, b) < half + pad:
                    return label
        if roadside > 0.0:
            for cell in {(math.floor(px / 16.0), math.floor(pz / 16.0)) for px, pz in rect}:
                for px, pz, clear in self.props.cells.get(cell, ()):
                    if cr.point_in_poly(px, pz, rect) or min(
                            cr.seg_seg_dist(rect[q], rect[(q + 1) % 4], (px, pz), (px, pz)) for q in range(4)) < clear:
                        return "prop"
        for cell in {(math.floor(px / 32.0), math.floor(pz / 32.0)) for px, pz in rect}:
            for q, c in self.polys.cells.get(cell, ()):
                if c.get("dk") is not None:
                    continue
                if any(cr.point_in_poly(px, pz, q) for px, pz in rect + [(x, z)]):
                    return "carriageway"
        return None


def _rect(x, z, ux, uz, half_across, half_along, off=0.0):
    """A footprint centred `off` metres right of (x, z) across a deck running (ux, uz)."""
    cx, cz = x - uz * off, z + ux * off
    return [(cx + ux * u - uz * v, cz + uz * u + ux * v) for u, v in
            ((-half_along, -half_across), (half_along, -half_across), (half_along, half_across), (-half_along, half_across))]


def place_piers(m, under=None):
    """R5: the pier boxes under every road and rail deck (see the module's docstring).
    Returns (piers, stats); each pier {"c": [x, z], "d": [ux, uz] along the deck,
    "s": [across, along], "y": [bottom, top], "k": "pier" | "leg" | "cap"}."""
    under = under or Under(m)
    out = []
    stats = {"candidates": 0, "in place": 0, "slid": 0, "tight": 0, "portals": 0, "skipped": 0, "skipped at": []}
    for pc in m.decks.p:
        if pc["k"] not in ("road", "rail"):
            continue
        pts, cum, hs = pc["pts"], pc["cum"], pc["h"]
        length = cum[-1]
        l, r = pc["l"] + 0.2, pc["r"] + 0.2
        across = (l + r) * PIER_SHARE * 0.5

        def at(s):
            for k in range(len(pts) - 1):
                if s <= cum[k + 1] or k == len(pts) - 2:
                    seg = cum[k + 1] - cum[k]
                    if seg < 0.05:
                        continue
                    t = min(max((s - cum[k]) / seg, 0.0), 1.0)
                    ux, uz = (pts[k + 1][0] - pts[k][0]) / seg, (pts[k + 1][1] - pts[k][1]) / seg
                    return (pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t,
                            hs[k] + (hs[k + 1] - hs[k]) * t, ux, uz)
            return None

        def foot(rect):
            return min(m.terrain(px, pz) for px, pz in rect) - 0.5

        s = PIER_FIRST
        while s < length:
            here = at(s)
            if here is None or here[2] - m.terrain(here[0], here[1]) <= PIER_MIN_AIR:
                s += PIER_STEP
                continue
            stats["candidates"] += 1
            offs = [0.0]
            for k in range(1, int(PIER_SLIDE) + 1):
                offs += [float(k), -float(k)]
            placed = None
            for roadside in (PIER_ROADSIDE, 0.0):
                for off in offs:
                    s2 = s + off
                    if s2 < 2.0 or s2 > length - 2.0:
                        continue
                    x, z, dy, ux, uz = at(s2)
                    if dy - m.terrain(x, z) <= PIER_MIN_AIR:
                        continue
                    rect = _rect(x, z, ux, uz, across, PIER_ALONG * 0.5)
                    if under.blocked(rect, pc["g"], dy, x, z, roadside) is None:
                        placed = [{"c": [x, z], "d": [ux, uz], "s": [across * 2.0, PIER_ALONG],
                                   "y": [foot(rect), dy - SLAB], "k": "pier"}]
                        stats["in place" if off == 0.0 else "slid"] += 1
                        if roadside == 0.0:
                            stats["tight"] += 1
                        break
                if placed is not None:
                    break
            if placed is None:
                for off in offs:
                    s2 = s + off
                    if s2 < 2.0 or s2 > length - 2.0:
                        continue
                    x, z, dy, ux, uz = at(s2)
                    if dy - m.terrain(x, z) <= PIER_MIN_AIR:
                        continue
                    legs = []
                    for side, edge in ((-1.0, l), (1.0, r)):
                        # From under the deck's edge outwards, then inwards: the first clear spot.
                        cands = [edge * 0.8 + q * 0.5 for q in range(0, int((edge * 0.2 + LEG_REACH) / 0.5) + 1)]
                        cands += [edge * 0.8 - q * 0.5 for q in range(1, int(edge * 0.8 / 0.5))]
                        for u in cands:
                            rect = _rect(x, z, ux, uz, LEG_W * 0.5, PIER_ALONG * 0.5, side * u)
                            if under.blocked(rect, pc["g"], dy, x, z) is None:
                                legs.append((side * u, rect))
                                break
                    if len(legs) == 2 and legs[1][0] - legs[0][0] >= LEG_SPAN_MIN:
                        placed = []
                        for u, rect in legs:
                            cx, cz = x - uz * u, z + ux * u
                            placed.append({"c": [cx, cz], "d": [ux, uz], "s": [LEG_W, PIER_ALONG],
                                           "y": [foot(rect), dy - SLAB], "k": "leg"})
                            edge = -l if u < 0 else r
                            if abs(u) + LEG_W * 0.5 > abs(edge):
                                # The cap beam: the slab's depth, out from the deck's edge to the leg.
                                a, b = edge, u + (LEG_W * 0.5 if u > 0 else -LEG_W * 0.5)
                                mid = (a + b) * 0.5
                                placed.append({"c": [x - uz * mid, z + ux * mid], "d": [ux, uz], "s": [abs(b - a), PIER_ALONG],
                                               "y": [dy - SLAB, dy - 0.3], "k": "cap"})
                        stats["portals"] += 1
                        break
            if placed is None:
                stats["skipped"] += 1
                stats["skipped at"].append((round(here[0]), round(here[1])))
            else:
                for p in placed:
                    p["c"] = [round(v, 2) for v in p["c"]]
                    p["d"] = [round(v, 4) for v in p["d"]]
                    p["s"] = [round(v, 2) for v in p["s"]]
                    p["y"] = [round(v, 2) for v in p["y"]]
                out += placed
            s += PIER_STEP
    return out, stats


WALL_MIN = 0.35        # R6: a fill side this far over what lies outside it gets a wall...
WALL_SOLID = 0.6       # ...solid from this height...
WALL_PARAPET = 1.0     # ...and with a parapet on top (roads) from this height
WALL_STEP = 3.0        # wall points at most this far apart
WALL_OUT = 0.3         # the wall's face stands this far outside the fill's corridor
WALL_CROSS = 25.0      # a way meeting the side at more than this angle (degrees) crosses it
TRENCH_LANE = 3.0      # loop 3e: no trench wall this near a ground lane's centre (a bus's half width, the 3 m
                       # between the wall's points and a margin)


def place_walls(m):
    """R6: retaining walls where an approach (a fill: the ground corrected under a structure
    way's corridor) stands above what lies beside it: along both sides, and across an end
    that meets lower ground (the abutment under a deck's end). Each run {"p": the line along
    the wall's face (its outside to the right of the direction of travel), "t": the top of
    the fill there, "b": the ground outside, "f": per segment 1 solid, 2 a parapet,
    "k": "stone" (roads) or "concrete" (tracks)}. Where a road or footway crosses the side
    (it joins the approach), the wall stays drawn but is neither solid nor topped there."""
    import check_roads as cr
    d = m.d
    crossing = cr.Grid(16.0)
    for it in d["roads"] + d.get("paths", []):
        if it.get("tn") is not None:
            continue
        half = it["w"] * 0.5 if "w" in it else 1.0
        ps = cr.pairs(it["p"])
        for a, b in zip(ps, ps[1:]):
            crossing.add((a, b, half, it), min(a[0], b[0]) - half - 1, min(a[1], b[1]) - half - 1,
                         max(a[0], b[0]) + half + 1, max(a[1], b[1]) + half + 1)
    cos_cross = math.cos(math.radians(WALL_CROSS))

    def crossed(x, z, ux, uz, h):
        for a, b, half, it in crossing.at(x, z):
            ln = math.dist(a, b)
            if ln < 0.05:
                continue
            if abs((b[0] - a[0]) / ln * ux + (b[1] - a[1]) / ln * uz) > cos_cross:
                continue  # running alongside, not across
            if cr.seg_dist2(x, z, a, b) > (half + 0.8) ** 2:
                continue
            if it.get("dk") is not None and abs(m.surface(it, x, z) - h) > 1.0:
                continue  # on a deck above or below
            return True
        return False

    def outside(x, z, top):
        """The ground beside the wall: the terrain with the other fills, or a deck at the fill's level."""
        g = m.terrain(x, z)
        for hd, _, _ in m.decks.at(x, z):
            if abs(hd - top) < 0.6:
                g = max(g, hd)
        return g

    def over_tunnel(x, z):
        """The floor of a tunnel whose corridor holds (x, z), or None."""
        for hd, t, i in m.tunnels.at(x, z):
            return hd
        return None

    # Loop 3e: the ground lanes, so a trench wall never stands in a lane (a way merging into a
    # profiled way at a shallow angle: Nowy Zjazd under the W-Z viaduct).
    lanes = cr.Grid(16.0)
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None or e.get("tn") is not None:
            continue
        lpts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(lpts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                lanes.add((a, b), min(a[0], b[0]) - 3, min(a[1], b[1]) - 3, max(a[0], b[0]) + 3, max(a[1], b[1]) + 3)

    def in_lane(x, z, below=None):
        """A ground lane's centre within TRENCH_LANE of (x, z) (`below`: one whose ground there
        is under that height: a road at the foot of a wall, not on the fill it holds)."""
        for a, b in lanes.at(x, z):
            if cr.seg_dist2(x, z, a, b) < TRENCH_LANE ** 2:
                if below is None:
                    return True
                abx, abz = b[0] - a[0], b[1] - a[1]
                t = min(max(((x - a[0]) * abx + (z - a[1]) * abz) / max(abx * abx + abz * abz, 1e-9), 0.0), 1.0)
                if m.terrain(a[0] + abx * t, a[1] + abz * t) < below:
                    return True
        return False

    runs = []
    total = solid = 0.0
    trench = [0]
    for f in m.fills.p:
        pts, cum, hs = f["pts"], f["cum"], f["h"]
        if cum[-1] < 0.5:
            continue
        kind = "stone" if f["k"] == "road" else "concrete"
        # Samples along the fill: its vertices and every WALL_STEP between them.
        ss = []
        for k in range(len(pts) - 1):
            seg = cum[k + 1] - cum[k]
            n = max(1, math.ceil(seg / WALL_STEP))
            ss += [cum[k] + seg * q / n for q in range(n)]
        ss.append(cum[-1])
        for side in (-1.0, 1.0):
            off = (f["r"] if side > 0 else f["l"]) + WALL_OUT
            cur = None
            for s in ss:
                x, z = cr._at(pts, cum, s)
                ux, uz = _dir_at(pts, cum, s)
                nx, nz = -uz * side, ux * side      # outward
                top = _interp(cum, hs, s)
                px, pz = x + nx * off, z + nz * off
                low = outside(px + nx * 0.4, pz + nz * 0.4, top)
                if f["s"] and low - top >= WALL_MIN and not m.on_rim(px, pz, 2.0) and not in_lane(px, pz):
                    # Loop 3e: a ground profile lower than the ground beside it is a trench (a
                    # portal's open ramp, a cutting): a concrete wall facing the road, from the
                    # road up to the ground, solid and topped like the approaches' walls.
                    if cur is not None and cur["_side"] != -side:
                        if len(cur["p"]) >= 4:
                            runs.append(cur)
                        cur = None
                    # Loop 3e leftovers: not inside a tube's mouth either (a footway's profile in
                    # its cutting stood this wall's foot 2 m under the mouth's top across Plac Na
                    # Rozdrożu's west portals).
                    floor = over_tunnel(px, pz)
                    if floor is not None and top < floor + MOUTH:
                        if cur is not None and len(cur["p"]) >= 4:
                            runs.append(cur)
                        cur = None
                        continue
                    flag = 0
                    if not crossed(px, pz, ux, uz, top):
                        if low - top >= WALL_SOLID:
                            flag |= 1
                        if low - top >= WALL_PARAPET:
                            flag |= 2
                    # Under a deck over the trench (a bridge over a cutting) the wall stops under
                    # its slab, with no parapet (Towarowa's over the railway cutting).
                    for hd, _, _ in m.decks.at(px, pz):
                        if hd > top + 1.0:
                            low = min(low, hd - SLAB - 0.1)
                            flag &= ~2
                    if cur is None:
                        cur = {"p": [], "t": [], "b": [], "f": [], "k": "concrete", "_side": -side}
                    cur["p"] += [px, pz]
                    cur["t"].append(low)
                    cur["b"].append(top)
                    cur["f"].append(flag)
                    trench[0] += 1
                    continue
                if cur is not None and cur["_side"] != side:
                    if len(cur["p"]) >= 4:
                        runs.append(cur)
                    cur = None
                if top - low < WALL_MIN or m.on_rim(px, pz, 2.0) or in_lane(px, pz, top - WALL_MIN * 0.8):
                    # (loop 3e: nor where a lane runs at its foot: Plac Na Rozdrożu's street over
                    # the Trasa's tubes stood its wall across the open road before their portals;
                    # leftovers: a lane at the foot of a low wall is a WALL_MIN under its top, not
                    # a half metre: Nowy Zjazd beside the W-Z tram approach's 0.6 m side wall)
                    if cur is not None and len(cur["p"]) >= 4:
                        runs.append(cur)
                    cur = None
                    continue
                flag = 0
                if not crossed(px, pz, ux, uz, top):
                    if top - low >= WALL_SOLID:
                        flag |= 1
                    if kind == "stone" and top - low >= WALL_PARAPET:
                        flag |= 2
                floor = over_tunnel(px, pz)
                if floor is not None and floor < low + MOUTH:
                    # A tunnel passes under the approach: its mouth stays open (loop 3e: wherever
                    # the wall's foot would stand in it, not only under the tunnel's floor: Plac Na
                    # Rozdrożu's street over the Trasa's tubes walled their mouths at 8 m).
                    low = max(low, floor + MOUTH)
                    if top - low < WALL_MIN:
                        if cur is not None and len(cur["p"]) >= 4:
                            runs.append(cur)
                        cur = None
                        continue
                if cur is None:
                    cur = {"p": [], "t": [], "b": [], "f": [], "k": kind, "_side": side}
                cur["p"] += [px, pz]
                cur["t"].append(top)
                cur["b"].append(low)
                cur["f"].append(flag)
            if cur is not None and len(cur["p"]) >= 4:
                runs.append(cur)
        # The ends: an abutment face across the corridor where the ground beyond is lower.
        for end in (0, -1):
            s = 0.0 if end == 0 else cum[-1]
            x, z = pts[end]
            ux, uz = _dir_at(pts, cum, s)
            sgn = -1.0 if end == 0 else 1.0
            top = hs[end]
            qx, qz = x + ux * sgn * 0.6, z + uz * sgn * 0.6
            low = m.terrain(qx, qz)
            if top - low < WALL_MIN or f["s"]:
                continue   # (loop 3e: a ground profile goes on into its way's next one)
            # Across the corridor, the outside (along the fill, away from it) to the right.
            left = (x + uz * f["l"], z - ux * f["l"])
            right = (x - uz * f["r"], z + ux * f["r"])
            a, b = (left, right) if end == 0 else (right, left)
            runs.append({"p": [a[0], a[1], b[0], b[1]], "t": [top, top], "b": [low, low], "f": [0, 0], "k": kind, "_side": 0})
    for r in runs:
        ps = cr.pairs(r["p"])
        if r["_side"] < 0:
            # Left side walls: reverse so the outside is to the right of the direction.
            ps.reverse()
            for key in ("t", "b", "f"):
                r[key].reverse()
        # Per segment: solid (or topped) only where both its ends are.
        r["f"] = [r["f"][k] & r["f"][k + 1] for k in range(len(r["f"]) - 1)]
        for k, (a, b) in enumerate(zip(ps, ps[1:])):
            ln = math.dist(a, b)
            total += ln
            if r["f"][k] & 1:
                solid += ln
        r["p"] = [round(v, 2) for q in ps for v in q]
        r["t"] = [round(v, 2) for v in r["t"]]
        r["b"] = [round(v, 2) for v in r["b"]]
        del r["_side"]
    return runs, {"runs": len(runs), "m": total, "solid m": solid, "trench m": trench[0] * WALL_STEP}


TOWER_AREAS = ((910, -165, 40, 60), (1398, -332, 45, 65))   # landmarks.gd _find_towers
TOWER_PAD = 0.5        # R7: the plinth's footprint this far outside any corridor or lane...
TOWER_PLINTH = 0.6     # ...the plinth standing this far out round the shaft (landmarks.gd)
TOWER_LANE = 1.2       # a lane's corridor: its offset line +- this (check_roads C10)
TOWER_ZONE = 6.0       # the landmark zone: the tower's outlines grown this far
TOWER_MIN = (2.0, 1.5)  # the shaft's half sizes never trimmed below these


def place_towers(m):
    """R7: Most Poniatowskiego's four towers, seated. OpenStreetMap maps each tower twice: the
    tower by the deck and, ~6 m out, a second outline with a rounded end that the game drew as
    an ordinary 14 m building fused into the tower. Per tower: the outline nearest the deck is
    the tower; its footprint (the plinth, TOWER_PLINTH round the shaft) is trimmed side by side
    until it is TOWER_PAD clear of every deck, approach and road corridor and every lane; its
    base sits at the boulevard (the lowest ground or ground road beside it), its shaft starts
    1.2 m over the deck's solved profile; the zone it replaces is both outlines grown
    TOWER_ZONE. The footways are no obstacle: the bridge's pavements pass through the towers. Returns [{"c", "a" (the long axis), "hu", "hv" (the shaft's half sizes),
    "base", "deck", "zone" (flat polygon)}] and notes."""
    import check_roads as cr
    d = m.d
    found = []   # [[outline, ...]] per tower
    for ax0, az0, aw, ah in TOWER_AREAS:
        for b in d["buildings"]:
            q = cr.pairs(b["p"])
            if len(q) < 3:
                continue
            c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
            if not (ax0 <= c[0] <= ax0 + aw and az0 <= c[1] <= az0 + ah):
                continue
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            if not 7.0 <= math.hypot(max(xs) - min(xs), max(zs) - min(zs)) <= 24.0:
                continue
            for grp in found:
                g0 = grp[0]
                if math.dist(c, (sum(p[0] for p in g0) / len(g0), sum(p[1] for p in g0) / len(g0))) < 9.0:
                    grp.append(q)
                    break
            else:
                found.append([q])
    if len(found) != 4:
        return [], {"towers": len(found)}

    # Obstacles: deck corridors (with the slab's edge), approach (fill) corridors, ground
    # roads, and the lanes, each a segment with a half width.
    obst = cr.Grid(16.0)

    def put(a, b, half, what):
        obst.add((a, b, half, what), min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                 max(a[0], b[0]) + half, max(a[1], b[1]) + half)

    def put_corridor(pc, extra, what):
        # A corridor with l != r: its two edges as zero-width lines, and its line at the smaller half.
        ps = pc["pts"]
        for off in (-pc["l"] - extra, pc["r"] + extra):
            edge = cr.offset_line(ps, off)
            for a, b in zip(edge, edge[1:]):
                put(a, b, 0.0, what)
        for a, b in zip(ps, ps[1:]):
            put(a, b, min(pc["l"], pc["r"]) + extra, what)
    # Not the footways: the bridge's pavements pass through the towers' ground-floor arches.
    for pc in m.decks.p:
        if pc["k"] == "road":
            put_corridor(pc, 0.2, f"deck {pc['g']} ({pc['k']})")
    for pc in m.fills.p:
        if pc["k"] == "road":
            put_corridor(pc, 0.0, "approach")
    for r in d["roads"]:
        ps = cr.pairs(r["p"])
        for a, b in zip(ps, ps[1:]):
            put(a, b, r["w"] * 0.5 + abs(r.get("c", 0.0)), r.get("name") or r["k"])
    for e in d["graph"]["edges"]:
        if e.get("tn") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                put(a, b, TOWER_LANE, f"lane {e.get('name') or e['k']}")

    def conflicts(c, ax, bx, u0, u1, v0, v1):
        """[(u, v) local points of obstacles within reach of the plinth rect u0..u1 x v0..v1]."""
        rect = [(c[0] + ax[0] * u + bx[0] * v, c[1] + ax[1] * u + bx[1] * v) for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))]
        out = []
        seen = set()
        for cell in {(math.floor(px / 16.0), math.floor(pz / 16.0)) for px, pz in rect}:
            for a, b, half, what in obst.cells.get(cell, ()):
                if (a, b, half) in seen:
                    continue
                seen.add((a, b, half))
                if _seg_rect_dist(rect, a, b) >= half + TOWER_PAD:
                    continue
                # The obstacle's points that are too close, in local coordinates.
                n = max(1, int(math.dist(a, b) / 0.5))
                for k in range(n + 1):
                    px, pz = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
                    lu = (px - c[0]) * ax[0] + (pz - c[1]) * ax[1]
                    lv = (px - c[0]) * bx[0] + (pz - c[1]) * bx[1]
                    du = max(u0 - lu, lu - u1, 0.0)
                    dv = max(v0 - lv, lv - v1, 0.0)
                    if math.hypot(du, dv) < half + TOWER_PAD:
                        out.append((lu, lv, what))
        return out

    towers = []
    notes = {"trimmed": [], "outlines": sum(len(g) for g in found)}
    for grp in found:
        # The tower: the outline nearest a road deck.
        def deck_dist(q):
            c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
            return min((math.sqrt(cr.seg_dist2(c[0], c[1], a, b)) for pc in m.decks.p if pc["k"] == "road"
                        for a, b in zip(pc["pts"], pc["pts"][1:])), default=1e9)
        grp.sort(key=deck_dist)
        q = grp[0]
        c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
        best, ax = 0.0, (1.0, 0.0)
        for i in range(len(q)):
            e = (q[(i + 1) % len(q)][0] - q[i][0], q[(i + 1) % len(q)][1] - q[i][1])
            ln = math.hypot(*e)
            if ln > best:
                best, ax = ln, (e[0] / ln, e[1] / ln)
        bx = (-ax[1], ax[0])
        us = [(p[0] - c[0]) * ax[0] + (p[1] - c[1]) * ax[1] for p in q]
        vs = [(p[0] - c[0]) * bx[0] + (p[1] - c[1]) * bx[1] for p in q]
        # The shaft's extents (as landmarks.gd: at most 8 x 6 m half sizes), centred on the outline's box.
        cu, cv = (max(us) + min(us)) * 0.5, (max(vs) + min(vs)) * 0.5
        hu0, hv0 = min((max(us) - min(us)) * 0.5, 8.0), min((max(vs) - min(vs)) * 0.5, 6.0)
        side = [cu - hu0, cu + hu0, cv - hv0, cv + hv0]   # u0, u1, v0, v1 of the shaft
        orig = list(side)
        for _ in range(200):
            hits = conflicts(c, ax, bx, side[0] - TOWER_PLINTH, side[1] + TOWER_PLINTH,
                             side[2] - TOWER_PLINTH, side[3] + TOWER_PLINTH)
            if not hits:
                break
            # Push in the side the worst point presses on.
            mid_u, mid_v = (side[0] + side[1]) * 0.5, (side[2] + side[3]) * 0.5
            hu, hv = (side[1] - side[0]) * 0.5, (side[3] - side[2]) * 0.5
            lu, lv, _ = min(hits, key=lambda h: max(abs(h[0] - mid_u) - hu, abs(h[1] - mid_v) - hv))
            if abs(lv - mid_v) - hv > abs(lu - mid_u) - hu and hv > TOWER_MIN[1]:
                side[3 if lv > mid_v else 2] += -0.1 if lv > mid_v else 0.1
            elif hu > TOWER_MIN[0]:
                side[1 if lu > mid_u else 0] += -0.1 if lu > mid_u else 0.1
            elif hv > TOWER_MIN[1]:
                side[3 if lv > mid_v else 2] += -0.1 if lv > mid_v else 0.1
            else:
                break
        left = conflicts(c, ax, bx, side[0] - TOWER_PLINTH, side[1] + TOWER_PLINTH,
                         side[2] - TOWER_PLINTH, side[3] + TOWER_PLINTH)
        cu, cv = (side[0] + side[1]) * 0.5, (side[2] + side[3]) * 0.5
        hu, hv = (side[1] - side[0]) * 0.5, (side[3] - side[2]) * 0.5
        cx, cz = c[0] + ax[0] * cu + bx[0] * cv, c[1] + ax[1] * cu + bx[1] * cv
        plinth = [(cx + ax[0] * u + bx[0] * v, cz + ax[1] * u + bx[1] * v) for u, v in
                  ((-hu - TOWER_PLINTH, -hv - TOWER_PLINTH), (hu + TOWER_PLINTH, -hv - TOWER_PLINTH),
                   (hu + TOWER_PLINTH, hv + TOWER_PLINTH), (-hu - TOWER_PLINTH, hv + TOWER_PLINTH))]
        # The base: the boulevard, the lowest ground (or ground road) round the plinth.
        base = min(m.terrain(px, pz) for px, pz in plinth + [(cx, cz)])
        for r in d["roads"]:
            if r.get("dk") is not None:
                continue
            for x, z in cr.sample(cr.pairs(r["p"]), 2.0):
                if math.hypot(x - cx, z - cz) < 15.0:
                    base = min(base, m.terrain(x, z))
        # The deck: the road structure's solved profile beside the tower (deck or approach).
        deck = None
        for pcs in (m.decks.p, m.fills.p):
            for pc in pcs:
                if pc["k"] != "road":
                    continue
                for k in range(len(pc["pts"]) - 1):
                    a, b = pc["pts"][k], pc["pts"][k + 1]
                    if cr.seg_dist2(cx, cz, a, b) < 20.0 ** 2:
                        abx, abz = b[0] - a[0], b[1] - a[1]
                        t = min(max(((cx - a[0]) * abx + (cz - a[1]) * abz) / max(abx * abx + abz * abz, 1e-6), 0.0), 1.0)
                        h = pc["h"][k] + (pc["h"][k + 1] - pc["h"][k]) * t
                        deck = h if deck is None else max(deck, h)
        if deck is None:
            deck = base
        # The zone: every outline of this tower, in the tower's axes, grown TOWER_ZONE.
        allu = [(p[0] - cx) * ax[0] + (p[1] - cz) * ax[1] for qq in grp for p in qq] + [-hu, hu]
        allv = [(p[0] - cx) * bx[0] + (p[1] - cz) * bx[1] for qq in grp for p in qq] + [-hv, hv]
        u0, u1 = min(allu) - TOWER_ZONE, max(allu) + TOWER_ZONE
        v0, v1 = min(allv) - TOWER_ZONE, max(allv) + TOWER_ZONE
        zone = [(cx + ax[0] * u + bx[0] * v, cz + ax[1] * u + bx[1] * v) for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))]
        towers.append({"c": [round(cx, 2), round(cz, 2)], "a": [round(ax[0], 4), round(ax[1], 4)],
                       "hu": round(hu, 2), "hv": round(hv, 2), "base": round(base, 2), "deck": round(deck, 2),
                       "zone": [round(v, 2) for p in zone for v in p]})
        notes["trimmed"].append((round(cx), round(cz), round(sum(abs(a - b) for a, b in zip(side, orig)), 1),
                                 len(left), round(deck - base, 1)))
    return towers, notes


CUT_BELOW = 0.5        # a building under a deck is cut this far under the slab's bottom...
CUT_MIN = 2.5          # ...and left out when less than this would remain
CUT_SHARE = 0.2        # only when at least this share of its footprint lies under the deck
SLAB_C9 = 1.3 + 0.08   # the slab's bottom under the deck's surface (check_roads C9)
PILLAR_AREA = 12.0     # a building this small wholly under a road deck is one of its pillars (bake_roads.py)


def place_cuts(m):
    """Buildings under decks (check_roads C9): a building (OpenStreetMap or LoD2) whose top is
    above the slab's bottom where its footprint lies under a deck corridor is cut to the
    slab's lowest bottom over it - CUT_BELOW (the Poniatowski viaduct's LoD2 arcades, which
    are the viaduct's own arches, and the Arkada under it), and left out if less than CUT_MIN
    would remain. Footbridges (structures with footways only) cut nothing: OpenStreetMap maps
    them schematically (the science centre's roof-garden ramps run across its roof). A building only grazed by a corridor (under CUT_SHARE of its footprint: a
    footway deck mapped along a wall) is not cut; check_roads reports it and the allowlist
    says why. Writes `cut` / `cutd` on OpenStreetMap buildings and returns `lod2_cuts`
    ([run centre x, z, top, left out]) for the LoD2 runs (map_builder.gd `_build_lod2` clips
    their triangles)."""
    import check_roads as cr
    sol = cr.Solids(m, cr.Landmarks(m.d))
    # Structures that carry a road, a railway or trams (their footways cut too); footbridges don't.
    carrying = {pc["g"] for pc in m.decks.p if pc["k"] != "path"}
    lod = {}
    notes = {"cut": 0, "left out": 0, "grazed": []}
    for q, base, top, label, bb, key in sol.items:
        if key is None or key[0] == "landmark":
            continue
        pts = list(q)
        for x in cr._frange(bb[0], bb[2], 1.0):
            for z in cr._frange(bb[1], bb[3], 1.0):
                if cr.point_in_poly(x, z, q):
                    pts.append((x, z))
        under = 0
        bottom = None
        carried = False   # under a road, rail or tram deck somewhere (not footways only)
        for x, z in pts:
            hit = False
            for hd, g, i in m.decks.at(x, z):
                b = hd - SLAB_C9
                if b > base:
                    hit = True
                    bottom = b if bottom is None else min(bottom, b)
                    carried = carried or g in carrying
            under += hit
        if bottom is None or not carried:
            continue
        area = abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(q, q[1:] + q[:1]))) * 0.5
        if key[0] == "osm" and area <= PILLAR_AREA and under == len(pts):
            # A viaduct's mapped pillar (R2): fitted to the slab it carries (cut or lengthened).
            b = m.d["buildings"][key[1]]
            b["cut"] = round(bottom, 2)
            b["pil"] = 1
            notes["pillars"] = notes.get("pillars", 0) + 1
            continue
        if top <= bottom + 0.05:
            continue
        if under < CUT_SHARE * len(pts):
            c = (sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q))
            notes["grazed"].append((round(c[0]), round(c[1]), round(under / len(pts), 2)))
            continue
        cut = bottom - CUT_BELOW
        drop = cut - base < CUT_MIN
        notes["left out" if drop else "cut"] += 1
        if key[0] == "osm":
            b = m.d["buildings"][key[1]]
            b["cut"] = round(cut, 2)
            if drop:
                b["cutd"] = 1
        else:
            old = lod.get(key[1])
            lod[key[1]] = (min(cut, old[0]) if old else cut, drop or (old[1] if old else False))
    cuts = [[k[0], k[1], round(v[0], 2), 1 if v[1] else 0] for k, v in sorted(lod.items())]
    return cuts, notes


MOUTH = 4.8            # a tunnel's mouth: this high over its floor (a bus is 3.2 m)
TRENCH_REACH = 160.0   # the open ramp to a portal is looked for this far back along the road
TRENCH_SIDE = 7.0      # the ground this far past the road's edge...
TRENCH_DEPTH = 1.0     # ...standing this far over the road makes it a trench
GARAGE_W = 3.6         # a garage door's width...
GARAGE_H = 2.4         # ...and height


def place_tunnels(m):
    """Loop 3b: what the tunnels (`tunnels` in the map file: pieces, roads, portals) need
    drawn and made solid. Returns (frames, walls, notes):
    - a portal frame per portal ({"c", "d" (into the tunnel), "w" (the opening), "y" (the
      floor), "top" (the ground over the mouth)}): a concrete headwall over the mouth with its
      posts, the mouth MOUTH high;
    - the tunnel's side walls (kind "tunnel": dark concrete from the floor up to the ground,
      facing in; solid only inside the tunnel, flag 4) and the open ramp's retaining walls
      (kind "concrete": along the road that dives to a portal, while the ground beside it
      stands TRENCH_DEPTH over it; facing the road, solid, topped with a parapet)."""
    import check_roads as cr
    d = m.d
    frames, walls = [], []
    notes = {"portals": 0, "ramp m": 0.0, "tunnel m": 0.0}
    portals = d.get("tunnels", {}).get("portals", [])
    for pc in m.tunnels.p:
        pts, cum, hs = pc["pts"], pc["cum"], pc["h"]
        # The side walls, every WALL_STEP: kind tunnel, top = the ground, bottom = the floor.
        for side in (-1.0, 1.0):
            off = (pc["r"] if side > 0 else pc["l"]) + 0.3
            run = {"p": [], "t": [], "b": [], "f": [], "k": "tunnel", "_side": -side}
            s = 0.0
            while True:
                x, z = cr._at(pts, cum, min(s, cum[-1]))
                ux, uz = _dir_at(pts, cum, min(s, cum[-1]))
                px, pz = x - uz * side * off, z + ux * side * off
                floor = _interp(cum, hs, min(s, cum[-1]))
                run["p"] += [px, pz]
                run["t"].append(max(m.terrain(px, pz), floor + MOUTH))
                run["b"].append(floor)
                run["f"].append(1 | 4)
                if s >= cum[-1]:
                    break
                s = min(s + WALL_STEP, cum[-1])
            if len(run["p"]) >= 4:
                walls.append(run)
                notes["tunnel m"] += cum[-1]
        # The portals of this tunnel.
        for x, z, g in portals:
            if g != pc["g"]:
                continue
            for end, sgn in ((0, 1.0), (-1, -1.0)):
                if math.dist(pts[end], (x, z)) > 0.5:
                    continue
                ux, uz = _dir_at(pts, cum, 0.0 if end == 0 else cum[-1])
                ux, uz = ux * sgn, uz * sgn          # into the tunnel
                floor = hs[end]
                # The ground over the mouth: the highest within 6-14 m inside, at least the mouth.
                top = floor + MOUTH + 0.6
                for k in range(6, 15, 2):
                    s = k if end == 0 else cum[-1] - k
                    if 0.0 <= s <= cum[-1]:
                        qx, qz = cr._at(pts, cum, s)
                        top = max(top, m.terrain(qx, qz))
                frames.append({"c": [round(x, 2), round(z, 2)], "d": [round(ux, 4), round(uz, 4)],
                               "w": round(pc["l"] + pc["r"], 2), "y": round(floor, 2), "top": round(top, 2)})
                notes["portals"] += 1
                # The open ramp: the open road that dives to the portal, walled while in a trench.
                for r in d["roads"]:
                    if r.get("dk") is not None:
                        continue
                    ps = cr.pairs(r["p"])
                    if math.dist(ps[0], (x, z)) < 0.5:
                        ps = ps[::-1]
                    elif math.dist(ps[-1], (x, z)) >= 0.5:
                        continue
                    # ps runs towards the portal: walk back from it.
                    back = ps[::-1]
                    bcum = cr.cum_of(back)
                    half = r["w"] * 0.5 + abs(r.get("c", 0.0)) + 0.6
                    for side in (-1.0, 1.0):
                        run = {"p": [], "t": [], "b": [], "f": [], "k": "concrete", "_side": -side}
                        s = 0.0
                        while s <= min(TRENCH_REACH, bcum[-1]):
                            qx, qz = cr._at(back, bcum, s)
                            vx, vz = _dir_at(back, bcum, s)
                            if any(m.fills.p[i]["s"] for _, _, i in m.fills.at(qx, qz, ends=True)):
                                break   # loop 3e: a ground profile's trench walls (place_walls) take over
                            px, pz = qx - vz * side * half, qz + vx * side * half
                            road = m.terrain(qx, qz)
                            ox, oz = qx - vz * side * (half + TRENCH_SIDE), qz + vx * side * (half + TRENCH_SIDE)
                            outer = m.terrain(ox, oz)
                            if outer - road < TRENCH_DEPTH:
                                break
                            run["p"] += [px, pz]
                            run["t"].append(outer)
                            run["b"].append(road)
                            run["f"].append(1 | 2)
                            s += WALL_STEP
                        if len(run["p"]) >= 4:
                            walls.append(run)
                            notes["ramp m"] += s
    # Orientation: each run's face looks to the right of its direction, at its low side.
    for r in walls:
        ps = cr.pairs(r["p"])
        if r["_side"] < 0:
            ps.reverse()
            for key in ("t", "b", "f"):
                r[key].reverse()
        r["f"] = [r["f"][k] & r["f"][k + 1] for k in range(len(r["f"]) - 1)]
        r["p"] = [round(v, 2) for q in ps for v in q]
        r["t"] = [round(v, 2) for v in r["t"]]
        r["b"] = [round(v, 2) for v in r["b"]]
        del r["_side"]
    return frames, walls, notes


def place_garage_doors(m):
    """Loop 3b: a garage door at each of the 27 ramp tops R9 ended a service way at
    (`garages`: x, z and the way in): [{"c", "d" (into the garage), "w", "y"}]."""
    out = []
    for g in m.d.get("garages", []):
        x, z, dx, dz = g
        out.append({"c": [x, z], "d": [dx, dz], "w": GARAGE_W, "y": round(m.terrain(x, z), 2)})
    return out


BARRIER_HALF = {"fence": 0.06, "wall": 0.18, "hedge": 0.45}   # the palette's barrier types' thickness / 2 (game/data/object_palette.json)
PROP_SOLID = {"benches": 3.2, "bikes": 3.4, "columns": 1.4, "shelters": 4.0}   # map_builder.gd _build_props
DRIVE_HALF = 1.7       # a lane's drive corridor: a bus's half width (1.3), and 0.4 m for a 12 m
                       # bus box's chord on a bend and the game's mitred lane offsets
BARRIER_TOP = 2.5      # loop 3e leftovers: a barrier's top over the ground (the palette's wall type: 1.9 m) and a little
ROAD_INSET = 0.15      # a carriageway's own corridor: its half width less this
SMALL_BUILDING = 30.0  # a mapped building this small (a kiosk, a vent) in a lane is left out
GUARD_END = 8.0        # loop 3e: a deck's guard rail this near its piece's end clears a bus on the lanes there...
GUARD_END_LANE = 2.6   # ...by this from their centres (where they turn on and off the deck the box swings out)
BUS_BOX = (2.6, 12.0)  # loop 3e leftovers: check_drive.gd's bus box on the roads buses drive (lane_graph.gd classes 0, 1)...
BUS_STEP = 1.0         # ...placed on a deck lane every this many metres, its axles BUS_BOX[1] / 2 apart
BUS_PAD = 0.1          # ...and a rail this near it goes (check_drive sweeps every 4 m)
NO_BUS = ("residential", "unclassified", "living_street")


def _clear_guards(src, inside, in_deck_lane, deck_ends, notes, in_bus_box=None):
    """clear_carriageways' guard rails: the runs left once the parts in a lane are cut out."""
    import check_roads as cr
    guards = []
    for g in src:
        ps = cr.pairs(g["p"])
        run = []
        for a, b in zip(ps, ps[1:]):
            n = max(1, math.ceil(math.dist(a, b) / 0.5))
            for k in range(n + 1):
                if k == 0 and run:
                    continue
                x, z = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
                if (inside(x, z, 0.1) if g.get("dk") is None else in_deck_lane(x, z, g["dk"]) or
                        # Loop 3e leftovers: nor where a bus on a lane of its deck group would
                        # brush it (a ramp's rail on a tight loop, a rail where two ramps part).
                        (in_bus_box is not None and in_bus_box(x, z, g["dk"])) or
                        # Loop 3e: by a deck's end its rail bends round the corner, into the lanes
                        # running on or off it (deck 4's across Wybrzeże Szczecińskie): a bus's
                        # half width there, on the deck and on the ground.
                        (any(math.hypot(x - ex, z - ez) < GUARD_END for ex, ez in deck_ends.get(g["dk"], ())) and
                         (inside(x, z, 0.1) or in_deck_lane(x, z, g["dk"], GUARD_END_LANE)))):
                    notes["barrier m cut"] += math.dist(a, b) / n
                    if len(run) >= 2:
                        guards.append(dict(g, p=[round(v, 2) for q in _simplify(run) for v in q]))
                    run = []
                else:
                    run.append((x, z))
        if len(run) >= 2:
            guards.append(dict(g, p=[round(v, 2) for q in _simplify(run) for v in q]))
    return guards


def clear_carriageways(m):
    """Loop 3b (check_drive.gd): solid things OpenStreetMap puts where cars drive. A fence,
    wall or hedge line (`lines`) or a mapped guard rail loses the parts that run inside a
    carriageway (a fence across a gate, along a median a metre off) or a lane's drive corridor
    (DRIVE_HALF); a deck's guard rail loses the parts in a lane on its own deck; a solid prop
    (bench, bike rack, advertising column, shelter), a parked car, a viaduct's pillar or a kiosk
    (SMALL_BUILDING) whose footprint reaches into one is left out. Ground roads and lanes only (a deck's or a tunnel's are at another height). Returns
    notes; edits `lines` and the prop lists in place."""
    import check_roads as cr
    d = m.d
    grid = cr.Grid(16.0)

    def put(a, b, half):
        grid.add((a, b, half), min(a[0], b[0]) - half, min(a[1], b[1]) - half, max(a[0], b[0]) + half, max(a[1], b[1]) + half)
    for r in d["roads"]:
        if r.get("dk") is not None or r["k"] not in cr.DRIVABLE:
            continue
        ps = cr.offset_line(cr.pairs(r["p"]), r.get("c", 0.0)) if r.get("c") else cr.pairs(r["p"])
        for a, b in zip(ps, ps[1:]):
            put(a, b, max(r["w"] * 0.5 - ROAD_INSET, 0.5))
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None or e.get("tn") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                put(a, b, DRIVE_HALF)

    # Tunnel lanes under shallow cover (the link under Most Poniatowskiego's west abutment):
    # anything standing on the ground over them lower than the mouth's top is in the way.
    tun = cr.Grid(16.0)
    for e in d["graph"]["edges"]:
        if e.get("tn") is None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                tun.add((a, b, e["tn"]), min(a[0], b[0]) - DRIVE_HALF, min(a[1], b[1]) - DRIVE_HALF,
                        max(a[0], b[0]) + DRIVE_HALF, max(a[1], b[1]) + DRIVE_HALF)

    def inside(x, z, pad):
        for a, b, half in grid.at(x, z):
            if cr.seg_dist2(x, z, a, b) < (half + pad) ** 2:
                return True
        for a, b, t in tun.at(x, z):
            if cr.seg_dist2(x, z, a, b) < (DRIVE_HALF + pad) ** 2 and \
                    m.terrain(x, z) < m.tunnel_height(t, x, z) + MOUTH + 1.0:
                return True
        return False
    # Loop 3e leftovers (2026-11-02): a deck road's carriageway where the deck runs lower than a
    # barrier's top over the ground (its ends at grade): a wall mapped up to the kerb line there
    # stood 0.7 m into the slab at Wybrzeże Szczecińskie's deck 4 by Most Śląsko-Dąbrowski
    # ((409, -1519) and (423, -1523): check_drive's buses on its outer lanes).
    def in_deck_road(x, z):
        return any(m.decks.p[i]["k"] == "road" and h < m.terrain(x, z) + BARRIER_TOP for h, _, i in m.decks.at(x, z))
    notes = {"barrier m cut": 0.0, "barrier m cut on decks": 0.0, "props": 0}
    lines = []
    for ln in d.get("lines", []):
        pad = BARRIER_HALF.get(ln["k"])
        if pad is None:
            lines.append(ln)
            continue
        ps = cr.pairs(ln["p"])
        run = []
        for a, b in zip(ps, ps[1:]):
            n = max(1, math.ceil(math.dist(a, b) / 0.5))
            for k in range(n + 1):
                if k == 0 and run:
                    continue
                x, z = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
                on_deck = False
                if inside(x, z, pad) or (on_deck := in_deck_road(x, z)):
                    notes["barrier m cut"] += math.dist(a, b) / n
                    if on_deck:
                        notes["barrier m cut on decks"] += math.dist(a, b) / n
                    if len(run) >= 2:
                        lines.append({"k": ln["k"], "p": [round(v, 2) for q in _simplify(run) for v in q]})
                    run = []
                else:
                    run.append((x, z))
        if len(run) >= 2:
            lines.append({"k": ln["k"], "p": [round(v, 2) for q in _simplify(run) for v in q]})
    d["lines"] = lines
    # The lanes on decks, per deck group (a bus's half width and a little: a deck's own guard
    # rails run along its carriageway's edges, a lane's half width out).
    deck_lanes = cr.Grid(16.0)
    for e in d["graph"]["edges"]:
        if e.get("dk") is None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                deck_lanes.add((a, b, e["dk"]), min(a[0], b[0]) - GUARD_END_LANE, min(a[1], b[1]) - GUARD_END_LANE,
                               max(a[0], b[0]) + GUARD_END_LANE, max(a[1], b[1]) + GUARD_END_LANE)

    def in_deck_lane(x, z, g, r=1.4):
        return any(dg == g and cr.seg_dist2(x, z, a, b) < r ** 2 for a, b, dg in deck_lanes.at(x, z))
    # The bus boxes along the main roads' lanes on decks, as check_drive.gd places them: the
    # axles half the bus's length apart on the lane, the body along the line between them,
    # cut short at the lane's ends.
    bus_boxes = cr.Grid(16.0)
    half_w = BUS_BOX[0] * 0.5 + BUS_PAD
    for e in d["graph"]["edges"]:
        if e.get("dk") is None or e["k"] in NO_BUS:
            continue
        pts = cr.pairs(e["p"])
        clen = sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            cum = [0.0]
            for a, b in zip(q, q[1:]):
                cum.append(cum[-1] + math.dist(a, b))
            if cum[-1] < 1.0 or clen < 1.0:
                continue
            f = cum[-1] / clen
            s0, s1 = e["s0"] * f, e["s1"] * f

            def at(s, cum=cum, q=q):
                s = min(max(s, 0.0), cum[-1])
                j = max(i for i in range(len(cum) - 1) if cum[i] <= s) if s < cum[-1] else len(cum) - 2
                t = (s - cum[j]) / max(cum[j + 1] - cum[j], 1e-9)
                return q[j][0] + (q[j + 1][0] - q[j][0]) * t, q[j][1] + (q[j + 1][1] - q[j][1]) * t
            s = s0
            while True:
                sa, sb = max(s - BUS_BOX[1] * 0.25, s0), min(s + BUS_BOX[1] * 0.25, s1)
                a, b = at(sa), at(sb)
                ln = math.dist(a, b)
                if ln > 0.01:
                    ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
                    ms = (sa + sb) * 0.5
                    front, rear = min(BUS_BOX[1] * 0.5, s1 - ms), min(BUS_BOX[1] * 0.5, ms - s0)
                    length = max(front + rear, 1.0)
                    cx = (a[0] + b[0]) * 0.5 + ux * (front - rear) * 0.5
                    cz = (a[1] + b[1]) * 0.5 + uz * (front - rear) * 0.5
                    r = math.hypot(length * 0.5 + BUS_PAD, half_w)
                    bus_boxes.add((cx, cz, ux, uz, length * 0.5 + BUS_PAD, e["dk"]), cx - r, cz - r, cx + r, cz + r)
                if s >= s1:
                    break
                s = min(s + BUS_STEP, s1)

    def in_bus_box(x, z, g):
        for cx, cz, ux, uz, hl, dg in bus_boxes.at(x, z):
            if dg == g and abs((x - cx) * ux + (z - cz) * uz) <= hl and abs(-(x - cx) * uz + (z - cz) * ux) <= half_w:
                return True
        return False
    # Guard rails: a mapped one's parts in a carriageway or a lane; a deck's in a lane on its deck.
    deck_ends = {}
    for pc in m.decks.p:
        deck_ends.setdefault(pc["g"], []).extend([pc["pts"][0], pc["pts"][-1]])
    # (Loop 3e: twice: a rail cut by a lane leaves an end the second look clears round its corner.)
    for _ in range(2):
        d["guards"] = _clear_guards(d.get("guards", []), inside, in_deck_lane, deck_ends, notes, in_bus_box)
    # Small buildings (kiosks, vents: under SMALL_BUILDING m2) reaching into a ground lane.
    for b in d["buildings"]:
        q = cr.pairs(b["p"])
        if len(q) < 3 or b.get("cutd"):
            continue
        area = abs(sum(p[0] * r[1] - r[0] * p[1] for p, r in zip(q, q[1:] + q[:1]))) * 0.5
        if area <= SMALL_BUILDING and any(inside(px, pz, 0.0) for px, pz in q):
            b["cutd"] = 1
            notes["small buildings"] = notes.get("small buildings", 0) + 1
    # Parked cars (4 values each; a 1.8 x 4.2 m footprint, solid) in a carriageway or a lane.
    v = d.get("parked", [])
    keep = []
    for i in range(0, len(v) - 3, 4):
        x, z, yaw = v[i], v[i + 1], v[i + 2]
        c, s = math.cos(yaw), math.sin(yaw)
        corners = [(x + c * u + s * w, z - s * u + c * w) for u in (-0.9, 0.9) for w in (-2.1, 2.1)]
        if any(inside(px, pz, 0.0) for px, pz in corners + [(x, z)]):
            notes["parked"] = notes.get("parked", 0) + 1
            continue
        keep += v[i:i + 4]
    d["parked"] = keep
    # A viaduct's pillar (`pil`, place_cuts) standing in a lane under it is left out.
    for b in d["buildings"]:
        if b.get("pil") and any(inside(px, pz, 0.0) for px, pz in cr.pairs(b["p"])):
            b["cutd"] = 1
            notes["pillars"] = notes.get("pillars", 0) + 1
    for key, solid in PROP_SOLID.items():
        v = d.get(key, [])
        keep = []
        r = solid * 0.5
        for i in range(0, len(v) - 2, 3):
            x, z, yaw = v[i], v[i + 1], v[i + 2]
            c, s = math.cos(yaw), math.sin(yaw)
            # Its footprint (map_builder.gd _props: 2r across its x, 1 m along z), turned by yaw.
            corners = [(x + c * u + s * w, z - s * u + c * w) for u in (-r, r) for w in (-0.5, 0.5)]
            if any(inside(px, pz, 0.0) for px, pz in corners + [(x, z)]):
                notes["props"] += 1
                continue
            keep += [x, z, yaw]
        d[key] = keep
    # Map review A (2026-10-29): street furniture standing on a tram track (tram stops'
    # shelters mapped on the track's stop position: one at the Poniatowski viaduct's east end,
    # 14 over the map): one whose centre lies in the track's swept width (TRAM_HALF either side
    # of the rails' centreline), where the track runs at the ground's height (on the ground, or
    # a deck's end at grade), moves beside the track (below).
    track = cr.Grid(16.0)
    for t in d.get("trams", []):
        ps = cr.pairs(t["p"])
        for a, b in zip(ps, ps[1:]):
            if max(m.surface(t, *a) - m.terrain(*a), m.surface(t, *b) - m.terrain(*b)) > 1.0:
                continue
            track.add((a, b), min(a[0], b[0]) - TRAM_HALF, min(a[1], b[1]) - TRAM_HALF,
                      max(a[0], b[0]) + TRAM_HALF, max(a[1], b[1]) + TRAM_HALF)

    def on_track(x, z):
        return any(cr.seg_dist2(x, z, a, b) < TRAM_HALF ** 2 for a, b in track.at(x, z))

    def nearest_track(x, z):
        best = None
        for a, b in track.at(x, z):
            d2 = cr.seg_dist2(x, z, a, b)
            if best is None or d2 < best[0]:
                best = (d2, a, b)
        return best

    # Map round 2 (2026-10-29): such a prop goes beside the track, where its stop's platform is
    # (OpenStreetMap maps the shelter on the stop position; none of the 14 has a platform mapped
    # within 25 m): the first of TRAM_SIDE either side, along the track, whose footprint is clear
    # of every tram track's swept width, carriageway and lane; else it is left out.
    for key in list(PROP_SOLID) + ["bins"]:
        v = d.get(key, [])
        keep = []
        r = PROP_SOLID.get(key, 0.6) * 0.5
        for i in range(0, len(v) - 2, 3):
            x, z, yaw = v[i], v[i + 1], v[i + 2]
            if not on_track(x, z):
                keep += v[i:i + 3]
                continue
            near = nearest_track(x, z)
            placed = None
            if near is not None:
                _, a, b = near
                ln = math.dist(a, b) or 1.0
                ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
                along_yaw = math.atan2(-uz, ux)   # map_builder _props: Basis(UP, yaw) turns +X to (cos, -sin)
                c, s = math.cos(along_yaw), math.sin(along_yaw)
                for off in TRAM_SIDE:
                    for sgn in (1.0, -1.0):
                        px, pz = x - uz * off * sgn, z + ux * off * sgn
                        corners = [(px + c * u + s * w, pz - s * u + c * w) for u in (-r, r) for w in (-0.5, 0.5)]
                        if not any(on_track(qx, qz) or inside(qx, qz, 0.0) for qx, qz in corners + [(px, pz)]):
                            placed = (px, pz, along_yaw)
                            break
                    if placed:
                        break
            if placed:
                keep += [round(placed[0], 1), round(placed[1], 1), round(placed[2], 2)]
                notes["moved off tram tracks"] = notes.get("moved off tram tracks", 0) + 1
            else:
                notes["on tram tracks"] = notes.get("on tram tracks", 0) + 1
        d[key] = keep
    return notes


TRAM_HALF = 1.2        # map review A: a tram's half width (2.4 m) about its track's centreline
TRAM_SIDE = (2.4, 3.0, 3.6, 4.5)   # map round 2: a stop's shelter moved beside its track this far from it
CROWN_CLEAR = 0.3      # map review A: a crown beside a deck stays this far under its slab...
CROWN_HEAD = {"road": 3.5, "rail": 3.5, "tram": 3.5, "path": 2.5}   # ...unless its base is this far over the deck
CROWN_MIN = 40         # ...shrinking its scale (hundredths) no further than this


def trim_crowns(m):
    """Map review A (2026-10-29): a scanned tree beside a deck whose crown reaches over the
    deck's corridor between its slab's bottom and the head room over the deck (a tree's crown
    through Most Poniatowskiego's or the viaduct's edge, 9-11 m above the slab beside the
    viaduct's west end) gets a smaller crown (`trees3d_crown`, bake_osm.crown_scales' scale:
    the base stays, the radius and the top shrink with it) until it clears, down to CROWN_MIN.
    A crown that hangs over a deck higher than the head room (a park's footbridge under a
    tree) stays. Edits `trees3d_crown` in place; returns (trimmed, left)."""
    d = m.d
    real, crowns = d.get("trees3d", []), d.get("trees3d_crown", [])
    kinds = [pc["k"] for pc in m.decks.p]

    def conflict(x, z, ground, base, top, radius):
        for dx, dz in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7)):
            for h, g, i in m.decks.at(x + dx * radius * 0.8, z + dz * radius * 0.8):
                if h > ground + 0.6 and ground + base < h + CROWN_HEAD.get(kinds[i], 3.5) and \
                        ground + top > h - SLAB - 0.08 - CROWN_CLEAR:
                    return True
        return False
    trimmed, left = 0, 0
    for k, i in enumerate(range(0, len(real) - 5, 6)):
        if k >= len(crowns):
            break
        x, z, height, radius, crown_base = real[i], real[i + 1], real[i + 2], real[i + 3], real[i + 4]
        base = min(crown_base, height - 1.5)    # as map_builder.gd _build_trees
        ground = m.terrain(x, z) - 0.2

        def fits(f):
            return not conflict(x, z, ground, base, base + (height - base) * f / 100.0, radius * f / 100.0)
        f = int(crowns[k])
        if fits(f):
            continue
        while f > CROWN_MIN and not fits(f):
            f -= 5
        f = max(f, CROWN_MIN)
        crowns[k] = f
        trimmed += 1
        left += 0 if fits(f) else 1
    return trimmed, left


def _simplify(run):
    """The 0.5 m samples of a kept stretch back to its corners (collinear points dropped)."""
    out = [run[0]]
    for k in range(1, len(run) - 1):
        a, b, c = out[-1], run[k], run[k + 1]
        if abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])) > 0.01:
            out.append(b)
    out.append(run[-1])
    return out


def _dir_at(pts, cum, s):
    for k in range(len(pts) - 1):
        if (s <= cum[k + 1] or k == len(pts) - 2) and cum[k + 1] - cum[k] > 0.01:
            seg = cum[k + 1] - cum[k]
            return (pts[k + 1][0] - pts[k][0]) / seg, (pts[k + 1][1] - pts[k][1]) / seg
    a, b = pts[0], pts[-1]
    ln = max(math.dist(a, b), 1e-6)
    return (b[0] - a[0]) / ln, (b[1] - a[1]) / ln


def _interp(cum, hs, s):
    for k in range(len(cum) - 1):
        if s <= cum[k + 1] or k == len(cum) - 2:
            seg = cum[k + 1] - cum[k]
            t = 0.0 if seg <= 0 else min(max((s - cum[k]) / seg, 0.0), 1.0)
            return hs[k] + (hs[k + 1] - hs[k]) * t
    return hs[-1]


NARROW_MAX = 0.4       # a road deck's corridor gives up at most this on a side...
NARROW_HIGH = 5.0      # ...beside a ground lane it stands less than this over


def narrow_decks(m):
    """Loop 3b (check_drive.gd): where a road deck runs alongside a ground road low enough for
    its slab edge and parapet to be in a bus's way (the Jana Pawła II viaduct's ramps beside the
    avenue below), its corridor on that side is narrowed by the overlap (at most NARROW_MAX: the
    deck's own carriageway still fits). Edits `decks.pieces` l / r; returns the pieces narrowed."""
    import check_roads as cr
    d = m.d
    lanes = cr.Grid(16.0)
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None or e.get("tn") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                lanes.add((a, b), min(a[0], b[0]) - 3, min(a[1], b[1]) - 3, max(a[0], b[0]) + 3, max(a[1], b[1]) + 3)
    n = 0
    for raw, pc in zip(d["decks"]["pieces"], m.decks.p):
        if pc["k"] != "road":
            continue
        for key, side in (("l", -1.0), ("r", 1.0)):
            worst = 0.0
            edge = cr.offset_line(pc["pts"], side * (pc[key] + 0.2))
            for k, (x, z) in enumerate(edge):
                if pc["h"][k] - m.terrain(x, z) > NARROW_HIGH:
                    continue
                for a, b in lanes.at(x, z):
                    dd = math.sqrt(cr.seg_dist2(x, z, a, b))
                    worst = max(worst, DRIVE_HALF - 0.2 - dd)
            if worst > 0.0:
                raw[key] = round(max(pc[key] - min(worst + 0.05, NARROW_MAX), 0.5), 2)
                n += 1
    return n


def open_lod2(m):
    """Loop 3b (check_drive.gd): where a LoD2 building's wall stands in a lane's car corridor
    (lane +- 1.1 m: OpenStreetMap's road and GUGiK's outline a metre apart, a pavilion's corner
    at the Poniatowski viaduct's west end), its wall triangles there are not solid: [x, z, r]
    circles (map_builder.gd `_build_lod2`)."""
    import check_roads as cr
    d = m.d
    lanes = cr.Grid(16.0)
    tube = cr.Grid(16.0)   # loop 3e: the tunnels' lanes (a bus's half width: DRIVE_HALF)
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                (tube if e.get("tn") is not None else lanes).add(
                    (a, b), min(a[0], b[0]) - 2, min(a[1], b[1]) - 2, max(a[0], b[0]) + 2, max(a[1], b[1]) + 2)
    out = []
    lod_json = os.path.join(m.dir, "lod2.json")
    if not os.path.exists(lod_json):
        return out
    import json
    meta = json.load(open(lod_json))
    rings = list(meta["footprints"])
    # Loop 3d-1: the OpenStreetMap buildings drawn where LoD2 has none (keep_osm) too: in the demo
    # box five lanes ran into one's corner (a garage, an outbuilding, a block a courtyard lane
    # passes under with no building_passage mapped); map_builder.gd leaves those walls open too.
    blds = d.get("buildings", [])
    for k in meta.get("keep_osm", []):
        if k < len(blds) and float(blds[k].get("mh", 0.0)) < 2.0:
            rings.append(blds[k]["p"])
    for fp in rings:
        q = cr.pairs(fp)
        for a, b in zip(q, q[1:] + q[:1]):
            n = max(1, math.ceil(math.dist(a, b) / 0.5))
            for k in range(n + 1):
                x, z = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
                # Loop 3e: and where a building over a tunnel (the Copernicus Science Centre over the
                # Wisłostrada's tubes, a block over W-Z's west end) reaches down into a tube's lanes.
                if any(cr.seg_dist2(x, z, la, lb) < 1.1 ** 2 for la, lb in lanes.at(x, z)) or \
                        any(cr.seg_dist2(x, z, la, lb) < (DRIVE_HALF + 0.3) ** 2 for la, lb in tube.at(x, z)):
                    if not any(math.hypot(x - c[0], z - c[1]) < 1.5 for c in out):
                        out.append([round(x, 2), round(z, 2), 2.5])
    return out


APRON = 10.0           # a structure's end meets the ground over this many metres (an apron)...
APRON_IN = 4.0         # ...and the ground under its last metres is held under its end's height


def place_aprons(m):
    """Loop 3b (check_drive.gd: the car's height jumped 0.3-0.4 m in a frame at the viaduct's
    west end and at a Wisłostrada portal): a deck or tunnel is flat across, the 10 m terrain grid
    at its end often isn't (the escarpment, a trench), so a car beside the centreline stepped
    where the structure ended. At every end that meets the ground (within a metre of it, nothing
    continuing), an apron over the structure's corridor: under a deck's or tunnel's last
    APRON_IN metres the ground is held under the end's height (the deck stays the surface), then
    over APRON metres
    it blends from the end's height (flat across) to the terrain (map_builder.gd
    terrain_height, check_roads Map.terrain). [{"p": [x0, z0, x1, z1], "h", "l", "r", "i"}], p
    from i (APRON_IN or 0) inside the end to APRON past it."""
    out = []
    for kind, pieces in (("deck", m.decks.p), ("tunnel", m.tunnels.p)):
        for pc in pieces:
            if kind in ("deck", "fill") and pc["k"] not in ("road", "rail", "tram"):
                continue
            pts, cum, hs = pc["pts"], pc["cum"], pc["h"]
            if cum[-1] < 2.0:
                continue
            for end in (0, -1):
                ex, ez = pts[end]
                ux, uz = _dir_at(pts, cum, 0.0 if end == 0 else cum[-1])
                if end == 0:
                    ux, uz = -ux, -uz          # outward
                h = hs[end]
                if m.on_rim(ex, ez, 2.0):
                    continue
                px, pz = ex + ux * 1.0, ez + uz * 1.0
                if abs(m.terrain(px, pz) - h) > 1.0:
                    continue                    # not at the ground (a fill or another deck goes on)
                if any(abs(hd - h) < 0.5 for hd, _, _ in m.decks.at(px, pz)) or m.tunnels.at(px, pz):
                    continue                    # the structure goes on
                if any(abs(hf - h) < 0.5 for hf, g, i in m.fills.at(px, pz, ends=True) if m.fills.p[i] is not pc
                       and not (kind == "tunnel" and m.fills.p[i]["s"])):
                    continue                    # an approach goes on (loop 3e: a portal's open road on its
                                                # ground profile still needs the ground held under the mouth)
                inner = 0.0 if kind == "fill" else APRON_IN
                # Left and right of the apron's own direction (outward: reversed at a start).
                l, r = (pc["r"], pc["l"]) if end == 0 else (pc["l"], pc["r"])
                # From APRON_IN inside the end (where the ground may stand over the deck: it is
                # held under it) to APRON past it.
                out.append({"p": [round(ex - ux * inner, 2), round(ez - uz * inner, 2),
                                  round(ex + ux * APRON, 2), round(ez + uz * APRON, 2)],
                            "h": round(h, 2), "l": round(l, 2), "r": round(r, 2), "i": inner})
    return out


WIDEN_MAX = 2.0        # an approach's corridor grows by at most this to hold its lanes


def widen_fills(m):
    """Loop 3b (check_drive.gd: a car on the Wisłostrada's outer lane stepped 0.75 m off a pit
    fill's side): an approach or pit fill corrects the ground under its road's corridor, but the
    lane graph's lanes can run wider than the road's width estimate; each side of a fill grows
    (at most WIDEN_MAX) until it holds a bus (1.3 m) on every lane running along it at its
    height. Edits `fills` l / r; returns how many sides grew."""
    import check_roads as cr
    d = m.d
    lanes = cr.Grid(16.0)
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None or e.get("tn") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                lanes.add((a, b), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
    cos_par = math.cos(math.radians(25.0))
    n = 0
    for raw, pc in zip(d.get("fills", []), m.fills.p):
        need = {"l": pc["l"], "r": pc["r"]}
        pts = pc["pts"]
        for k in range(len(pts) - 1):
            a, b = pts[k], pts[k + 1]
            ln = math.dist(a, b)
            if ln < 0.05:
                continue
            ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            mx, mz = (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5
            seen = set()
            for cx in range(math.floor((mx - ln - 8) / 16.0), math.floor((mx + ln + 8) / 16.0) + 1):
                for cz in range(math.floor((mz - ln - 8) / 16.0), math.floor((mz + ln + 8) / 16.0) + 1):
                    for la, lb in lanes.cells.get((cx, cz), ()):
                        if (la, lb) in seen:
                            continue
                        seen.add((la, lb))
                        ll = math.dist(la, lb)
                        if ll < 0.05 or abs((lb[0] - la[0]) / ll * ux + (lb[1] - la[1]) / ll * uz) < cos_par:
                            continue
                        for q in (la, lb, ((la[0] + lb[0]) * 0.5, (la[1] + lb[1]) * 0.5)):
                            along = (q[0] - a[0]) * ux + (q[1] - a[1]) * uz
                            if along < 0.0 or along > ln:
                                continue
                            lat = (q[1] - a[1]) * ux - (q[0] - a[0]) * uz
                            side = "r" if lat > 0 else "l"
                            if abs(lat) > pc[side] + WIDEN_MAX:
                                continue
                            need[side] = max(need[side], min(abs(lat) + 1.3, pc[side] + WIDEN_MAX))
        for side in ("l", "r"):
            if need[side] > pc[side] + 0.05:
                raw[side] = round(need[side], 2)
                n += 1
    return n


BANK_STEP = 8.0        # map round 2b: a river spot candidate every this many metres of the river's edge...
BANK_INLAND = 5.0      # ...this far in from it (rides.gd RIVER_INLAND)...
BANK_DRY = 3.0         # ...dry this far round (RIVER_DRY)...
BANK_ROAD = 70.0       # ...with a lane within this (RIVER_ROAD)...
BANK_RIVER = 50000.0   # ...of a water area this big (the river, not a pond)
BANK_TRIES = 10        # ...trying the nearest lane points first, up to this many
BANK_STEP_UP = 0.6     # the line to the lane is no road for the car where the ground steps this much...
BANK_STEP_RUN = 2.0    # ...within this (a terrace, a boulevard's wall the grid blurs)


def place_bank(m):
    """Map round 2b (2026-10-29): the river spots the Podwózka job drives the car to (loop 2d-1
    `rides.gd` found them by scanning the water's edge at run time: a dry waypoint BANK_INLAND in
    from the river, a straight line to a lane within BANK_ROAD over dry ground with no building
    on it). The line was never tested against what stops a car: a retaining wall, a fence, a
    wall or hedge line, a guard rail, a flight of steps, a pier, a solid prop, or a step in the
    ground (the Bulwary lie 3-5 m under Wybrzeże Kościuszkowskie). Here every candidate's line
    to the nearest lane along the bank each way is walked every 0.5 m against all of them; the
    ones that pass are `drivable_bank`: [wx, wz, rx, rz] (waypoint, the lane point). Returns
    (spots, notes)."""
    import check_roads as cr
    d = m.d
    inner = m.shape.grow(-10.0)
    river = []
    for a in d.get("areas", []):
        if a.get("k") != "water":
            continue
        q = cr.pairs(a["p"])
        area = abs(sum(p[0] * r[1] - r[0] * p[1] for p, r in zip(q, q[1:] + q[:1]))) * 0.5
        if area >= BANK_RIVER:
            river.append(q)
    water = cr.Grid(32.0)
    for k, a in enumerate(d.get("areas", [])):
        if a.get("k") == "water":
            q = cr.pairs(a["p"])
            water.add(q, min(p[0] for p in q), min(p[1] for p in q), max(p[0] for p in q), max(p[1] for p in q))

    def wet(x, z):
        return any(cr.point_in_poly(x, z, q) for q in water.at(x, z))
    solids = cr.Solids(m, cr.Landmarks(d))
    segs = cr.Grid(8.0)   # (a, b, what): everything a car can't drive across

    def put(a, b, what, pad=0.3):
        segs.add((a, b, what, pad), min(a[0], b[0]) - pad, min(a[1], b[1]) - pad, max(a[0], b[0]) + pad, max(a[1], b[1]) + pad)
    for w in d.get("walls", []):
        ps = cr.pairs(w["p"])
        for k in range(len(ps) - 1):
            if max(w["t"][k] - w["b"][k], w["t"][k + 1] - w["b"][k + 1]) >= WALL_SOLID:
                put(ps[k], ps[k + 1], "wall")
    for ln in d.get("lines", []):
        if ln["k"] in BARRIER_HALF:
            ps = cr.pairs(ln["p"])
            for a, b in zip(ps, ps[1:]):
                put(a, b, ln["k"], BARRIER_HALF[ln["k"]] + 0.3)
    for g in d.get("guards", []):
        if g.get("dk") is None:
            ps = cr.pairs(g["p"])
            for a, b in zip(ps, ps[1:]):
                put(a, b, "guard rail")
    for st in d.get("steps", []):
        ps = cr.pairs(st["p"])
        for a, b in zip(ps, ps[1:]):
            put(a, b, "steps", 1.2)
    for p in d.get("decks", {}).get("piers", []):
        if p.get("k") == "cap":
            continue
        (cx, cz), (dx, dz), (across, along) = p["c"], p["d"], p["s"]
        rx, rz = -dz, dx
        cs = [(cx + dx * u * along * 0.5 + rx * v * across * 0.5, cz + dz * u * along * 0.5 + rz * v * across * 0.5)
              for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        for k in range(4):
            put(cs[k], cs[(k + 1) % 4], "pier")
    for key in PROP_SOLID:
        v = d.get(key, [])
        for i in range(0, len(v) - 2, 3):
            put((v[i], v[i + 1]), (v[i], v[i + 1]), key, PROP_SOLID[key] * 0.5 + 0.5)
    lanes = cr.Grid(32.0)
    for e in d["graph"]["edges"]:
        if e.get("dk") is not None or e.get("tn") is not None:
            continue
        pts = cr.pairs(e["p"])
        for k in range(e["n"]):
            q = cr.offset_line(pts, e["o"] + e["lw"] * k)
            for a, b in zip(q, q[1:]):
                lanes.add((a, b), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))

    def blocked(r, w):
        n = max(1, int(math.dist(r, w) / 0.5))
        prev = None
        hs = []
        for k in range(n + 1):
            x, z = r[0] + (w[0] - r[0]) * k / n, r[1] + (w[1] - r[1]) * k / n
            if k > 0 and wet(x, z):
                return "water"
            g = m.terrain(x, z)
            hs.append(g)
            for q, base, top, label, bb, _ in solids.at(x, z):
                if base < g + 3.0 and top > g + 0.5:
                    return "building"
            if m.decks.at(x, z) and any(abs(hd - g) < 4.5 for hd, _, _ in m.decks.at(x, z)):
                return "deck"   # under a deck too low to pass, or onto its end
            if prev is not None:
                for a, b, what, pad in segs.at(x, z):
                    if cr.seg_seg_dist(prev, (x, z), a, b) < pad:
                        return what
            prev = (x, z)
        run = max(1, int(BANK_STEP_RUN / 0.5))
        for k in range(len(hs) - run):
            if abs(hs[k + run] - hs[k]) > BANK_STEP_UP:
                return "step"
        return None
    out, why = [], {}
    cands = 0
    for q in river:
        ring = q + q[:1]
        for a, b in zip(ring, ring[1:]):
            ln = math.dist(a, b)
            if ln < 0.5:
                continue
            ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            s = 0.0
            while s < ln:
                ex, ez = a[0] + ux * s, a[1] + uz * s
                s += BANK_STEP
                # The land side of the edge.
                for sgn in (1.0, -1.0):
                    nx, nz = -uz * sgn, ux * sgn
                    if not wet(ex + nx * 1.0, ez + nz * 1.0):
                        break
                else:
                    continue
                w = (ex + nx * BANK_INLAND, ez + nz * BANK_INLAND)
                if not inner.contains(w[0], w[1]):   # map north: the map's shape, 10 m in
                    continue
                if wet(*w) or any(wet(w[0] + math.cos(t) * BANK_DRY * f, w[1] + math.sin(t) * BANK_DRY * f)
                                  for t in [k * math.tau / 12 for k in range(12)] for f in (0.5, 1.0)):
                    continue
                if any(True for _ in solids.at(*w)) or m.decks.at(*w):
                    continue
                cands += 1
                # The lanes within BANK_ROAD, nearest first (one point per lane segment); the
                # first whose line is drivable is the spot's road point.
                near, seen = [], set()
                for ci in range(-3, 4):
                    for cj in range(-3, 4):
                        for la, lb in lanes.at(w[0] + ci * 24.0, w[1] + cj * 24.0):
                            if (la, lb) in seen:
                                continue
                            seen.add((la, lb))
                            sx, sz = lb[0] - la[0], lb[1] - la[1]
                            l2 = sx * sx + sz * sz
                            if l2 < 1e-4:
                                continue
                            t = min(max(((w[0] - la[0]) * sx + (w[1] - la[1]) * sz) / l2, 0.0), 1.0)
                            p = (la[0] + sx * t, la[1] + sz * t)
                            dd = math.dist(p, w)
                            if dd <= BANK_ROAD:
                                near.append((dd, p))
                near.sort()
                found, first = None, None
                for dd, p in near[:BANK_TRIES]:
                    reason = blocked(p, w)
                    if reason is None:
                        found = p
                        break
                    first = first or reason
                if found:
                    out.append([round(w[0], 1), round(w[1], 1), round(found[0], 1), round(found[1], 1)])
                elif first:
                    why[first] = why.get(first, 0) + 1
    return out, {"candidates": cands, "blocked": why}


def _trim_walls(walls, shape):
    """Map north (tools/check_outline.py O1): a wall run's end past the map's edge (up to 1 m:
    a road's retaining wall clipped with its road, then offset) is cut back onto the edge, its
    top and bottom heights interpolated there. Runs wholly off the map are dropped."""
    out = []
    for w in walls:
        p = list(zip(w["p"][0::2], w["p"][1::2]))
        if all(shape.contains(x, z) for x, z in p):
            out.append(w)
            continue
        t, b, f = list(w["t"]), list(w["b"]), list(w.get("f", []))
        for end in (0, 1):
            if end == 1:
                p, t, b, f = p[::-1], t[::-1], b[::-1], f[::-1]
            while len(p) >= 2 and not shape.contains(*p[0]) and not shape.contains(*p[1]):
                p, t, b = p[1:], t[1:], b[1:]
                f = f[1:]
            if len(p) >= 2 and not shape.contains(*p[0]):
                segs = shape.clip_segments(p[1], p[0])
                if segs:
                    q = segs[0][1]
                    ln = math.dist(p[1], p[0]) or 1.0
                    u = math.dist(p[1], q) / ln
                    p[0] = q
                    t[0] = round(t[1] + (t[0] - t[1]) * u, 2)
                    b[0] = round(b[1] + (b[0] - b[1]) * u, 2)
            if end == 1:
                p, t, b, f = p[::-1], t[::-1], b[::-1], f[::-1]
        if len(p) >= 2 and all(shape.grow(0.01).contains(x, z) for x, z in p):
            w = dict(w, p=[round(c, 2) for q in p for c in q], t=t, b=b)
            if "f" in w:
                w["f"] = f
            out.append(w)
    return out


def add_structures(out, map_dir, terrain):
    """Everything this module adds, into the finished map file `out` (bake_osm.py)."""
    import check_roads as cr
    widened = widen_fills(cr.Map.from_data(map_dir, out, terrain))
    print(f"fills: {widened} approach and pit fill sides widened to hold their lanes (check_drive)")
    narrowed = narrow_decks(cr.Map.from_data(map_dir, out, terrain))
    out["aprons"] = place_aprons(cr.Map.from_data(map_dir, out, terrain))
    m = cr.Map.from_data(map_dir, out, terrain)
    print(f"aprons: {len(out['aprons'])} structure ends blended into the ground over {APRON:.0f} m (check_drive)")
    print(f"decks: {narrowed} road deck sides narrowed beside a ground lane (check_drive)")
    out["lod2_open"] = open_lod2(m)
    print(f"lod2: {len(out['lod2_open'])} places where a building's wall stands in a lane: not solid there (check_drive)")
    under = Under(m)
    piers, st = place_piers(m, under)
    out["decks"]["piers"] = piers
    towers, tst = place_towers(m)
    out["towers"] = towers
    print(f"towers (R7): {len(towers)} of Most Poniatowskiego's towers from {tst.get('outlines', 0)} outlines; "
          "per tower (x, z, metres trimmed, conflicts left, deck over base): "
          + ", ".join(str(t) for t in tst.get("trimmed", [])))
    cuts, cst = place_cuts(m)
    out["lod2_cuts"] = cuts
    print(f"cuts (C9): {cst['cut']} buildings cut under a deck, {cst['left out']} left out, {cst.get('pillars', 0)} "
          f"pillars fitted to the slab; grazed by a deck "
          f"corridor, not cut (x, z, share): {cst['grazed']}")
    cc = clear_carriageways(m)
    print(f"carriageways (check_drive): {cc['barrier m cut']:.0f} m of fences, walls, hedges and mapped guard rails "
          f"inside a carriageway or a lane cut out ({cc['barrier m cut on decks']:.0f} m of them on a deck road at grade); left out there: {cc['props']} solid props, "
          f"{cc.get('parked', 0)} parked cars, {cc.get('pillars', 0)} viaduct pillars, {cc.get('small buildings', 0)} kiosks; "
          f"{cc.get('moved off tram tracks', 0)} props on a tram track moved beside it, "
          f"{cc.get('on tram tracks', 0)} left out (map review A, round 2)")
    ct, cl = trim_crowns(m)
    print(f"trees (map review A): {ct} scanned crowns beside a deck shrunk to clear its slab ({cl} still reach it)")
    walls, wst = place_walls(m)
    frames, twalls, tst = place_tunnels(m)
    out["walls"] = _trim_walls(walls + twalls, m.shape)
    out.setdefault("tunnels", {})["frames"] = frames
    out["garage_doors"] = place_garage_doors(m)
    print(f"tunnels (loop 3b): {tst['portals']} portal frames, {tst['tunnel m']:.0f} m of tunnel walled, "
          f"{tst['ramp m']:.0f} m of open ramp walls; {len(out['garage_doors'])} garage doors")
    print(f"walls (R6): {wst['runs']} retaining wall runs, {wst['m']:.0f} m ({wst['solid m']:.0f} m solid; "
          f"loop 3e: {wst['trench m']:.0f} m along trenches)")
    print(f"piers (R5): {st['candidates']} places under the decks: {st['in place']} in place, {st['slid']} slid "
          f"along the deck to a clear spot ({st['tight']} with no room for PIER_ROADSIDE beside a main road), "
          f"{st['portals']} portal frames, {st['skipped']} left out"
          + (f" (at {', '.join(f'({x}, {z})' for x, z in st['skipped at'][:12])})" if st["skipped"] else ""))
    bank, bst = place_bank(m)
    out["drivable_bank"] = bank
    print(f"river spots (map round 2b): {len(bank)} drivable lines from {bst['candidates']} dry waypoints by the river; "
          f"blocked: " + ", ".join(f"{k} {v}" for k, v in sorted(bst["blocked"].items())))


def main(argv):
    import json
    map_dir = argv[0] if argv else os.path.join(os.path.dirname(TOOLS), "game", "map")
    d = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
    t = json.load(open(os.path.join(map_dir, "terrain.json")))
    add_structures(d, map_dir, t)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
