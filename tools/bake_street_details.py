"""Street details along the main line (docs/design/street-details.md, BACKLOG audit item 5).

    python3 -I tools/bake_street_details.py [MAP.json] [--out=FILE]

Reads the finished map data (default game/map/centrum.json; nothing else, so it runs in the
cloud) and writes game/data/street_details.json: the character props (newspaper kiosks, flower
stalls, café tables, planters, ad columns, bollards, an ice-cream cart, tram and bus stop kits)
on the pavements of the streets the main line sends the player down (CORRIDORS), as

    {"_about", "src": <sha1 of the map keys read>, "kinds": [...],
     "items": [[kind, x, z, yaw, colour], ...]}

`yaw` is atan2(ax, az) with (ax, az) the way from the street to the prop, so Basis(UP, yaw) turns
+z away from the street and the prop's -z front faces it (as first_scene.gd). The first scene's
own rectangle, the Palm and the Rotunda are left alone. The props keep clear of everything
bake_street_pois.Solids knows (carriageway, kerbs, tracks, buildings, platforms, lamps, trees,
benches, bins, shelters, parked cars...). Deterministic: hashes of positions, never Python's
hash. Re-run after every centrum.json re-bake; game/tools/check_street_details.gd fails when
`src` no longer matches. Standard library only.
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

SEED = "street-details-2026"
OUT = os.path.join(ROOT, "game", "data", "street_details.json")
SRC_KEYS = ("roads", "carriage", "kerbs", "paths", "trams", "rails", "buildings", "lines", "walls", "steps",
            "guards", "medians", "areas", "platforms", "islands", "surfaces", "lamps", "signals", "benches",
            "bins", "bikes", "columns", "shelters", "parked", "trees3d", "palm", "pois", "landmarks")

# [id, character, waypoints (game x, z)] (the spec's section 1: the places the guide, the ladder and
# the final send the player through, and the streets between them).
CORRIDORS = [
    ("C1", "avenue", [(-1091, -256), (-977, 53), (-952, 172), (-872, 411)]),
    ("C2", "avenue", [(-872, 411), (-711, 426), (-433, 330), (-195, 253), (-44, 197), (150, 131), (300, 80)]),
    ("C3", "cafe", [(-195, 253), (-300, 0), (-430, -330), (-242, -285)]),
    ("C4", "cafe", [(-242, -285), (38, -323), (81, -497), (-95, -717), (-215, -958), (-221, -1201)]),
    ("C5", "river", [(-25, -1225), (162, -1057), (404, -478), (566, -22)]),
    ("C6", "avenue", [(-2644, 412), (-2149, 242), (-1671, 75), (-1181, -94)]),
    ("C7", "avenue", [(73, -1835), (900, -1800), (1321, -1948)]),
    ("C8", "avenue", [(1417, -292), (1722, -391), (1611, -372), (1496, -601)]),
    # Marszałkowska street by street (F, 2026-11-01): the rest of the street, north of C1 (past
    # Plac Bankowy, whose own thread owns the square) and south of the Rotunda to Plac Zbawiciela.
    ("C9", "avenue", [(-1337, -615), (-1238, -520), (-1166, -465), (-1126, -350), (-1091, -256)]),
    ("C10", "avenue", [(-872, 411), (-792, 544), (-750, 669), (-672, 876), (-594, 1095)]),
]
# Streets that are one long café terrace in life (Nowy Świat, F 2026-11-01): a cluster every
# `base` + up to `jitter` m instead of every 70-110 m, so the row reads continuous.
DENSE = {"Nowy Świat": (11.0, 6.0)}
REACH = 38.0                     # a road is on a corridor when its middle is this near the waypoints' line
ROAD_KINDS = {"primary", "secondary", "tertiary", "unclassified", "residential", "living_street", "trunk"}
NOT_NAMES = {"Wybrzeże Szczecińskie", "Nowy Zjazd"}
FIRST_SCENE = (-1080.0 - 30.0, -160.0 - 30.0, -880.0 + 30.0, 260.0 + 30.0)   # main.gd FIRST_SCENE grown by 30 m
DISCS = [(-852.0, 334.0, 40.0),   # the Rotunda (jobs.gd FIRST_PAST); the Palm is added from the map
         (-836.4, 461.0, 29.0)]   # Rondo Dmowskiego's island (landmarks.gd RONDO_C): beds and tracks, no pavement
# Rondo Dmowskiego (F's photos, 2026-11-02, docs/landmarks/specs/rondo-dmowskiego.md): the street furniture
# round the roundabout, placed by hand on its corners' paving before the walk along the corridors
# (a flower stall 93 m south and the mapped ad columns already stand near, and keep their spacing):
# [kind, x, z, colour]; each faces the island. The east Jerozolimskie tram island (no mapped
# shelter) gets a shelter beside its kit's bench (platform_kits, RONDO_SHELTER).
RONDO_C = (-836.4, 461.0)
RONDO = [
    ("kiosk", -885.2, 442.9, ""),           # north-west, by the Patelnia's stairs: PRASA
    ("cart", -872.6, 503.6, "#e63946"),     # south-west: ice cream
]
RONDO_SHELTER = 80.0     # a stop kit this near the island gets a shelter too
RONDO_SHELTER_OFF = 5.0  # along the island from the bench
LANDMARK_CLEAR = 6.0
# Props: footprint radius (m), own-kind spacing (m), poster/awning colours.
RADIUS = {"kiosk": 2.2, "stall": 1.9, "cafe": 1.7, "planter": 0.9, "column": 1.2, "bollards": 1.0,
          "cart": 1.4, "post": 0.5, "ticket": 0.7, "bench": 1.0, "heater": 0.45, "shelter": 2.2}
SPACING = {"kiosk": 250.0, "stall": 250.0, "column": 150.0, "cart": 400.0}
SOLID = ("kiosk", "stall", "cart")
KINDS = ["kiosk", "stall", "cafe", "planter", "column", "bollards", "cart", "post", "ticket", "bench", "heater", "shelter"]
# A stop kit on a tram island (a platform with no mapped shelter) carries this colour: the prop
# stands on the slab (street_details.gd: map_builder.platform_top). Marszałkowska pass, 2026-11-02.
ON_PLATFORM = "platform"
# An island lies inside the carriageway polygon is edged by its own kerb and lies beside the tram tracks; everything else still blocks a kit piece.
PLATFORM_SKIP = ("shelter", "platform", "island", "carriageway", "kerb", "tram track", "ballast")
PLATFORM_R = 0.5         # the clearance of a kit piece on the slab (it is 2-3 m wide)
KIT_AREA = 150.0         # a platform smaller than this (m2) is no stop
KIT_SHELTER_GAP = 25.0   # a mapped shelter this near already has its kit
KIT_OFFSET = 9.0         # the post and the ticket machine stand this far from the bench along the island
FLOWERS = ["#e63946", "#ffd23f", "#9b5de5", "#f4a261", "#e8a6b8"]
PARASOLS = ["#2f6b4f", "#f4f1de", "#24324a", "#c8282a", "#e07a5f"]
POSTERS = ["#e07a5f", "#9db4d8", "#e8d36a", "#81b29a", "#e8a6b8"]
AWNINGS = ["#e63946", "#2a9d8f", "#ffd23f"]
MAX_ITEMS = 900
MAX_SECTOR = 85  # the placer stops here; the stop kits may add a few more, up to the loader's 100
SECTOR = 512.0
PROBE_FROM, PROBE_TO, PROBE_STEP = 1.5, 8.0, 0.5
STOP_REACH = 40.0
# G9: a café set's centre this far from the nearest building outline (the solids keep 2.25 m clear
# of a wall for its 1.7 m footprint): the shop's own frontage, a terrace at most 2 m deep.
CAFE_FRONT = (2.25, 4.3)


def h01(*key):
    s = SEED + "|" + "|".join(("%.1f" % k) if isinstance(k, float) else str(k) for k in key)
    return int.from_bytes(hashlib.sha1(s.encode("utf-8")).digest()[:7], "big") / float(1 << 56)


def pick(seq, *key):
    return seq[int(h01(*key) * len(seq)) % len(seq)]


def src_hash(data):
    h = hashlib.sha1()
    for k in SRC_KEYS:
        h.update(json.dumps(data.get(k), separators=(",", ":"), sort_keys=True).encode("utf-8"))
    return h.hexdigest()


def line_dist(x, z, pts):
    return min(P.seg_dist(x, z, a, b) for a, b in zip(pts, pts[1:]))


class Placer:
    def __init__(self, data):
        self.data = data
        self.solids = P.Solids(data)
        s = self.solids.segs
        for lm in data.get("landmarks", []):
            pts = P.pairs(lm["p"])
            s.add_line(pts + pts[:1], LANDMARK_CLEAR, "landmark")
        for p in data.get("pois", []):
            if p["k"] in ("kebab", "scooter", "scooter_zone", "subway_entrance"):
                s.add((p["x"], p["z"]), (p["x"], p["z"]), 2.0, "poi")
        self.discs = list(DISCS)
        if data.get("palm"):
            self.discs.append((data["palm"][0], data["palm"][1], 40.0))
        self.items = []
        self.by_kind = {}
        self.sector = {}
        # G9 (2026-11-01): a café set stands on paving against a shopfront, never on a lawn.
        self.green = P.Polys()
        for a in data.get("areas", []):
            if a["k"] in ("grass", "park", "pitch", "water"):
                self.green.add(P.pairs(a["p"]), a["k"])

    def frontage(self, x, z):
        """True if (x, z) is on paving CAFE_FRONT m from a building's front: not in a park or a lawn,
        not nearer the wall than a parasol's reach, not farther than a terrace's depth."""
        if self.green.inside(x, z):
            return False
        gap = self.solids.segs.dist(x, z, "building")
        return CAFE_FRONT[0] <= gap <= CAFE_FRONT[1]

    def excluded(self, x, z):
        if FIRST_SCENE[0] <= x <= FIRST_SCENE[2] and FIRST_SCENE[1] <= z <= FIRST_SCENE[3]:
            return True
        return any(math.hypot(x - cx, z - cz) < r for cx, cz, r in self.discs)

    def spaced(self, kind, x, z):
        gap = SPACING.get(kind)
        if gap is None:
            return True
        near = [o for o in self.by_kind.get(kind, ()) if abs(o[0] - x) < gap and abs(o[1] - z) < gap]
        if any(math.hypot(o[0] - x, o[1] - z) < gap for o in near):
            return False
        if kind == "column":
            c = self.data.get("columns", [])
            for i in range(0, len(c) - 2, 3):
                if math.hypot(c[i] - x, c[i + 1] - z) < gap:
                    return False
        return True

    def clear(self, kind, x, z, skip=()):
        if self.excluded(x, z):
            return False
        if len(self.items) >= MAX_ITEMS:
            return False
        key = (int(x // SECTOR), int(z // SECTOR))
        if self.sector.get(key, 0) >= MAX_SECTOR:
            return False
        if self.solids.blocked(x, z, RADIUS[kind] + 0.15, skip=skip) is not None:
            return False
        for o in self.items:   # no two props overlap (cheap: lists are short per area)
            if abs(o[1] - x) < 4.0 and abs(o[2] - z) < 4.0 and math.hypot(o[1] - x, o[2] - z) < RADIUS[kind] + RADIUS[o[0]]:
                return False
        return self.spaced(kind, x, z)

    def add(self, kind, x, z, face, colour="", count=True):
        yaw = math.atan2(face[0], face[1])
        item = [kind, round(x, 1), round(z, 1), round(yaw, 2), colour]
        self.items.append(item)
        self.by_kind.setdefault(kind, []).append((item[1], item[2]))
        key = (int(x // SECTOR), int(z // SECTOR))
        self.sector[key] = self.sector.get(key, 0) + 1

    def pavement(self, kind, ax, az, tx, tz, nx, nz, half_w, lateral=0.0, ok=None):
        """The first clear pavement point out from the road's edge on the normal's side, at `lateral`
        m along the road from (ax, az): (x, z) or None."""
        d = half_w + PROBE_FROM
        while d <= half_w + PROBE_TO:
            x = ax + tx * lateral + nx * d
            z = az + tz * lateral + nz * d
            if self.clear(kind, x, z) and (ok is None or ok(x, z)):
                return x, z
            d += PROBE_STEP
        return None


def corridor_roads(data):
    """[(character, road)] for every road on a corridor: not a bridge, a street class, middle near the line."""
    out = []
    for r in data["roads"]:
        if r.get("bridge") or r["k"] not in ROAD_KINDS or r.get("name", "") in NOT_NAMES:
            continue
        p = P.pairs(r["p"])
        if len(p) < 2:
            continue
        mid = p[len(p) // 2]
        for cid, ch, way in CORRIDORS:
            if line_dist(mid[0], mid[1], way) < REACH:
                out.append((ch, r))
                break
    return out


def cluster(pl, ch, road, side, x0, z0, tx, tz, nx, nz, w, anchor_key, corner):
    """One cluster at the anchor point; `corner`: a junction is near."""
    face = (nx, nz)   # the way from the street to the prop = the normal's side
    half = w * 0.5
    r = h01(*anchor_key, "kind")

    def put(kind, lateral, colour=""):
        at = pl.pavement(kind, x0, z0, tx, tz, nx, nz, half, lateral, pl.frontage if kind == "cafe" else None)
        if at is None:
            return None
        pl.add(kind, at[0], at[1], face, colour)
        return at

    if ch == "avenue":
        if corner:
            kind = "stall" if r < 0.45 else "kiosk"
            if put(kind, 0.0) is None:
                put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
            put("planter", 6.0, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", -6.0, pick(FLOWERS, *anchor_key, "p2"))
        elif r < 0.5:
            put("planter", -1.5, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", 1.5, pick(FLOWERS, *anchor_key, "p2"))
        elif r < 0.8:
            put("bollards", 0.0)
        else:
            put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
    elif ch == "cafe":
        if r < 0.15 and corner:
            put("stall", 0.0)
        elif r < 0.25:
            put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
        else:
            n = 2 + int(h01(*anchor_key, "n") * 2)
            if road.get("name", "") in DENSE:
                n = 1 + int(h01(*anchor_key, "n") * 2)   # a terrace between two planters, closer together
            first = -3.5 * (n - 1) * 0.5
            sets = [put("cafe", first + 3.5 * k, pick(PARASOLS, *anchor_key, "cafe", k)) for k in range(n)]
            if any(sets) and road.get("name") == "Nowy Świat":
                # Nowy Świat pass 2: the terraces are gardens, a patio heater between and beside the sets.
                for k in range(n):
                    put("heater", first + 3.5 * k + 1.75)
                put("heater", first - 2.4)
            if any(sets):   # G9: the planters only flank a terrace that stands against a shopfront
                put("planter", first - 4.0, pick(FLOWERS, *anchor_key, "pa"))
                put("planter", first + 3.5 * (n - 1) + 4.0, pick(FLOWERS, *anchor_key, "pb"))
    else:   # river: the boulevard side only (the buildings/areas side has no free pavement)
        if r < 0.3:
            put("cart", 0.0, pick(AWNINGS, *anchor_key, "a"))
        elif r < 0.6:
            put("cafe", -2.0, pick(PARASOLS, *anchor_key, "k1"))
            put("cafe", 2.0, pick(PARASOLS, *anchor_key, "k2"))
        else:
            put("planter", -1.5, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", 1.5, pick(FLOWERS, *anchor_key, "p2"))


def stop_kits(pl, roads):
    """A stop post (and for a tram stop a ticket machine) beside every map shelter on a corridor, inside
    the shelter's own cleared disc's reach (so no new obstruction on a platform)."""
    data = pl.data
    sh = data.get("shelters", [])
    plat = [P.pairs(p["p"]) for p in data.get("platforms", [])]
    segs = []
    for ch, r in roads:
        p = P.pairs(r["p"])
        segs.extend(zip(p, p[1:]))
    n = 0
    for i in range(0, len(sh) - 2, 3):
        x, z = sh[i], sh[i + 1]
        best = None
        for a, b in segs:
            d = P.seg_dist(x, z, a, b)
            if d < STOP_REACH and (best is None or d < best[0]):
                best = (d, a, b)
        if best is None or pl.excluded(x, z):
            continue
        _, a, b = best
        ln = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
        tx, tz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
        # the way from the road to the shelter = the prop's face-away direction
        u = max(0.0, min(1.0, ((x - a[0]) * tx + (z - a[1]) * tz) / ln))
        qx, qz = a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u
        dx, dz = x - qx, z - qz
        dl = math.hypot(dx, dz) or 1.0
        face = (dx / dl, dz / dl)
        tram = any(P.point_in_poly(x, z, poly) or min(P.seg_dist(x, z, p, q) for p, q in zip(poly, poly[1:] + poly[:1])) < 3.0 for poly in plat)
        for kind, sign in (("post", 2.3), ("ticket", -2.3)):
            if kind == "ticket" and not tram:
                continue
            px, pz = x + tx * sign, z + tz * sign
            if pl.excluded(px, pz) or len(pl.items) >= MAX_ITEMS:
                continue
            if pl.solids.blocked(px, pz, RADIUS[kind], skip=("shelter", "platform", "island")) is not None:
                continue
            # Tram stops (2026-11-07): a post or a machine by a shelter on a tram island stands on its top.
            pl.add(kind, px, pz, face, ON_PLATFORM if on_platform(data, px, pz) else "")
            n += 1
    return n


def platform_kits(pl, roads):
    """Tram islands on a corridor road with no mapped shelter near: a bench in the middle, a stop post
    at one end and a ticket machine at the other (all on the slab, facing the tracks)."""
    data = pl.data
    sh = data.get("shelters", [])
    segs = []
    for ch, r in roads:
        p = P.pairs(r["p"])
        segs.extend(zip(p, p[1:]))
    n = 0
    for plat in data.get("platforms", []):
        poly = P.pairs(plat["p"])
        if len(poly) < 3 or abs(P._area(poly)) < KIT_AREA:
            continue
        cx = sum(q[0] for q in poly) / len(poly)
        cz = sum(q[1] for q in poly) / len(poly)
        if pl.excluded(cx, cz):
            continue
        if any(math.hypot(sh[i] - cx, sh[i + 1] - cz) < KIT_SHELTER_GAP for i in range(0, len(sh) - 2, 3)):
            continue
        best = None
        for a, b in segs:
            d = P.seg_dist(cx, cz, a, b)
            if d < STOP_REACH and (best is None or d < best[0]):
                best = (d, a, b)
        if best is None:
            continue
        # the island's long axis = its longest edge
        edge = max(zip(poly, poly[1:] + poly[:1]), key=lambda e: math.hypot(e[1][0] - e[0][0], e[1][1] - e[0][1]))
        ln = math.hypot(edge[1][0] - edge[0][0], edge[1][1] - edge[0][1]) or 1.0
        tx, tz = (edge[1][0] - edge[0][0]) / ln, (edge[1][1] - edge[0][1]) / ln
        _, a, b = best
        sl = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
        u = max(0.0, min(1.0, ((cx - a[0]) * (b[0] - a[0]) + (cz - a[1]) * (b[1] - a[1])) / (sl * sl)))
        qx, qz = a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u
        dl = math.hypot(cx - qx, cz - qz) or 1.0
        face = ((cx - qx) / dl, (cz - qz) / dl)
        kit = [("bench", 0.0), ("post", -KIT_OFFSET), ("ticket", KIT_OFFSET)]
        if math.hypot(cx - RONDO_C[0], cz - RONDO_C[1]) < RONDO_SHELTER:
            kit.append(("shelter", RONDO_SHELTER_OFF))
        for kind, off in kit:
            x, z = cx + tx * off, cz + tz * off
            if not P.point_in_poly(x, z, poly):
                continue
            if min(P.seg_dist(x, z, p, q) for p, q in zip(poly, poly[1:] + poly[:1])) < 0.7:
                continue   # the slab's edge (its kerb) is no place for a prop
            if len(pl.items) >= MAX_ITEMS:
                continue
            if pl.solids.blocked(x, z, PLATFORM_R, skip=PLATFORM_SKIP) is not None:
                continue
            pl.add(kind, x, z, face, ON_PLATFORM)
            n += 1
    return n


TRAM_KIT_END = 3.0       # the stop post stands this far in from an island's end (where the crossing comes in)
TRAM_KIT_TICKET = 4.5    # the ticket machine this far in from the other end
TRAM_KIT_POSTED = 20.0   # an island with a post this near already has its kit
LOADER_SECTOR = 100      # street_details.gd MAX_SECTOR


def on_platform(data, x, z):
    return any(P.point_in_poly(x, z, P.pairs(p["p"])) for p in data.get("platforms", [])
               if abs(p["p"][0] - x) < 150.0 and abs(p["p"][1] - z) < 150.0)


def tram_island_kits(pl):
    """Tram stops (F, 2026-11-07): every tram island on the map (tools/tram_stops.py `tram`), not only
    the corridors', gets its stop post at one end and a ticket machine at the other, and a bench in
    the middle when no shelter is mapped there; all on the slab, facing the tracks."""
    data = pl.data
    sh = data.get("shelters", [])
    tracks = []
    for t in data.get("trams", []):
        q = P.pairs(t["p"])
        tracks.extend(zip(q, q[1:]))
    n = 0
    for plat in data.get("platforms", []):
        if not plat.get("tram"):
            continue
        poly = P.pairs(plat["p"])
        cx = sum(q[0] for q in poly) / len(poly)
        cz = sum(q[1] for q in poly) / len(poly)
        if pl.excluded(cx, cz):
            continue
        if any(abs(o[0] - cx) < 60 and abs(o[1] - cz) < 60 and P.point_in_poly(o[0], o[1], poly)
               for o in pl.by_kind.get("post", ())):
            continue
        edge = max(zip(poly, poly[1:] + poly[:1]), key=lambda e: math.hypot(e[1][0] - e[0][0], e[1][1] - e[0][1]))
        ln = math.hypot(edge[1][0] - edge[0][0], edge[1][1] - edge[0][1]) or 1.0
        tx, tz = (edge[1][0] - edge[0][0]) / ln, (edge[1][1] - edge[0][1]) / ln
        ss = [(q[0] - cx) * tx + (q[1] - cz) * tz for q in poly]
        s0, s1 = min(ss), max(ss)
        if s1 - s0 < 15.0:
            continue
        # the side the tracks are on: items face away from the nearest track
        best = min(tracks, key=lambda ab: P.seg_dist(cx, cz, ab[0], ab[1])) if tracks else None
        if best is None:
            continue
        a, b = best
        sl = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
        u = max(0.0, min(1.0, ((cx - a[0]) * (b[0] - a[0]) + (cz - a[1]) * (b[1] - a[1])) / (sl * sl)))
        qx, qz = a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u
        dl = math.hypot(cx - qx, cz - qz) or 1.0
        face = ((cx - qx) / dl, (cz - qz) / dl)
        kit = [("post", s0 + TRAM_KIT_END)]
        if s1 - s0 >= 30.0:
            kit.append(("ticket", s1 - TRAM_KIT_TICKET))
        if not any(math.hypot(sh[i] - cx, sh[i + 1] - cz) < KIT_SHELTER_GAP for i in range(0, len(sh) - 2, 3)):
            kit.append(("bench", (s0 + s1) * 0.5))
        for kind, along in kit:
            if len(pl.items) >= MAX_ITEMS:
                break
            for lateral in (0.0, 0.6, -0.6, 1.2, -1.2):
                x = cx + tx * along - tz * lateral
                z = cz + tz * along + tx * lateral
                if not P.point_in_poly(x, z, poly):
                    continue
                if min(P.seg_dist(x, z, p, q) for p, q in zip(poly, poly[1:] + poly[:1])) < 0.8:
                    continue
                key = (int(x // SECTOR), int(z // SECTOR))
                if pl.sector.get(key, 0) >= LOADER_SECTOR:
                    break
                if pl.solids.blocked(x, z, PLATFORM_R, skip=PLATFORM_SKIP) is not None:
                    continue
                if any(abs(o[1] - x) < 3.0 and abs(o[2] - z) < 3.0 for o in pl.items):
                    continue
                pl.add(kind, x, z, face, ON_PLATFORM)
                n += 1
                break
    return n


# Plac Zbawiciela's café terraces (F's street-by-street, 2026-11-02; BACKLOG "Marszałkowska"): the
# square is a roundabout (ring road centre, radius) and the MDM blocks stand back from it on a wide
# footway. A terrace is a row of café sets on that footway in front of a block: [x, z of the row's
# middle, sets in the row]. The sets face outward (away from the ring), the row runs along the
# ring's tangent, and a planter stands at each end. Spots come from the mapped outlines (no photo);
# a spot the solids block (a tree, a lamp, a kerb) or off the shopfront (Placer.frontage, check_stops
# K5) simply loses that set.
SQUARE = (-411.0, 1566.0)
TERRACES = [
    (-371.5, 1578.5, 3),   # the south-east block's north-west face, towards Nowowiejska
    (-380.0, 1594.0, 3),   # the same block, round the corner on Marszałkowska
    (-382.0, 1530.0, 3),   # the north-east block's south-west face
    (-372.0, 1546.0, 3),   # and its east end, by Nowowiejska
    (-456.0, 1584.0, 3),   # the south-west arc, towards Mokotowska
    (-443.0, 1600.0, 2),   # and where it meets Marszałkowska
]


def square_terraces(pl):
    """Café sets in a row on each TERRACES spot; returns how many sets stood."""
    n = 0
    for k, (x, z, sets) in enumerate(TERRACES):
        dx, dz = x - SQUARE[0], z - SQUARE[1]
        dl = math.hypot(dx, dz) or 1.0
        nx, nz = dx / dl, dz / dl          # outward from the ring
        tx, tz = -nz, nx                   # along the ring
        first = -3.5 * (sets - 1) * 0.5
        placed = 0
        for j in range(sets):
            lat = first + 3.5 * j
            px, pz = x + tx * lat, z + tz * lat
            if pl.frontage(px, pz) and pl.clear("cafe", px, pz) and len(pl.items) < MAX_ITEMS:
                pl.add("cafe", px, pz, (nx, nz), pick(PARASOLS, "zb", k, j))
                placed += 1
        if placed:
            for sd, edge in ((-1, first - 3.8), (1, first + 3.5 * (sets - 1) + 3.8)):
                px, pz = x + tx * edge, z + tz * edge
                if pl.clear("planter", px, pz) and len(pl.items) < MAX_ITEMS:
                    pl.add("planter", px, pz, (nx, nz), pick(FLOWERS, "zb", k, sd))
        n += placed
    return n


def rondo_items(pl):
    """The hand-placed furniture round Rondo Dmowskiego (RONDO), facing the island; a spot the map
    has since filled is left out (and said)."""
    for kind, x, z, colour in RONDO:
        if not pl.clear(kind, x, z):
            print("street details: Rondo Dmowskiego's %s at %.1f, %.1f is blocked: left out" % (kind, x, z))
            continue
        d = math.hypot(x - RONDO_C[0], z - RONDO_C[1]) or 1.0
        pl.add(kind, x, z, ((x - RONDO_C[0]) / d, (z - RONDO_C[1]) / d), colour)


# Zielona Świętokrzyska (Krajobraz K4; RS Architektura Krajobrazu, 2018, Marszałkowska to Nowy
# Świat): 194 trees along the street and, where a tree could not go (the metro, the utilities under
# the pavement), big planters. The 2023 scan carries the trees (docs/design/krajobraz-places.md);
# the planters go on the pavement where a stretch of the street has no tree within TREE_REACH m,
# every PLANTER_STEP m along each side, as a pair of flower-filled concrete tubs.
ZS_NAME = "Świętokrzyska"
ZS_X = (-1100.0, -275.0)   # game x of the stretch: Marszałkowska on the west, Nowy Świat on the east
ZS_STEP = 8.0              # walk the street's edge at this pitch
ZS_TREE_REACH = 5.0        # no planter within this of a trunk (the trees stand in their own pits)
ZS_GAP = 10.0              # planters stand at least this far apart on one side
ZS_ENDS = 16.0             # keep this clear of the crossings' ends of a road piece


def zielona_planters(pl):
    """Planters on the pavements of ul. Świętokrzyska where the scanned trees leave a gap; returns the count."""
    trees = pl.data.get("trees3d", [])
    tp = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    last = {}
    n = 0
    for r in pl.data["roads"]:
        if r.get("name") != ZS_NAME or r.get("bridge") or r["k"] not in ROAD_KINDS:
            continue
        p = P.pairs(r["p"])
        total = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(p, p[1:]))
        run = 0.0
        for a, b in zip(p, p[1:]):
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            if ln < 1.0:
                continue
            tx, tz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            pos = ZS_STEP * 0.5
            while pos < ln:
                at = run + pos
                x0, z0 = a[0] + tx * pos, a[1] + tz * pos
                pos += ZS_STEP
                if not ZS_X[0] <= x0 <= ZS_X[1] or at < ZS_ENDS or total - at < ZS_ENDS:
                    continue
                for side in (1, -1):
                    nx, nz = -tz * side, tx * side
                    got = pl.pavement("planter", x0, z0, 0.0, 0.0, nx, nz, r["w"] * 0.5, 0.0)
                    if not got:
                        continue
                    x, z = got
                    if any(abs(tx_ - x) < ZS_TREE_REACH and abs(tz_ - z) < ZS_TREE_REACH
                           and math.hypot(tx_ - x, tz_ - z) < ZS_TREE_REACH for tx_, tz_ in tp):
                        continue
                    if any(math.hypot(x - qx, z - qz) < ZS_GAP for qx, qz in last.get(side, ())):
                        continue
                    pl.add("planter", x, z, (-nx, -nz), pick(FLOWERS, "zs", round(x), round(z)))
                    last.setdefault(side, []).append((x, z))
                    n += 1
            run += ln
    return n


def bake(data):
    pl = Placer(data)
    rondo_items(pl)
    roads = corridor_roads(data)
    for ch, r in roads:
        p = P.pairs(r["p"])
        side_key = (r.get("name", ""), r["k"])
        base, jitter = DENSE.get(r.get("name", ""), (70.0, 40.0))
        walked = {1: h01(*side_key, p[0][0], p[0][1], 1.0) * base, -1: h01(*side_key, p[0][0], p[0][1], -1.0) * base}
        total = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(p, p[1:]))
        run = 0.0
        for a, b in zip(p, p[1:]):
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            if ln < 1.0:
                continue
            tx, tz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            for side in (1, -1):
                nx, nz = -tz * side, tx * side
                pos = walked[side]
                while pos < run + ln:
                    if pos >= run + 4.0:
                        x0, z0 = a[0] + tx * (pos - run), a[1] + tz * (pos - run)
                        to_end = min(pos, total - pos)
                        corner = 15.0 <= to_end <= 40.0 or (total < 80.0 and to_end < 40.0)
                        key = (round(x0, 0), round(z0, 0), side)
                        cluster(pl, ch, r, side, x0, z0, tx, tz, nx, nz, r["w"], key, corner)
                    pos += base + h01(round(a[0]), round(a[1]), round(pos), side) * jitter
                walked[side] = pos
            run += ln
    stops = stop_kits(pl, roads) + platform_kits(pl, roads) + tram_island_kits(pl)
    square_terraces(pl)
    zielona_planters(pl)
    items = sorted(pl.items, key=lambda i: (i[1], i[2], i[0]))
    return items, stops


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    out = OUT
    for a in argv:
        if a.startswith("--out="):
            out = a[6:]
        else:
            path = a
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    items, stops = bake(data)
    counts = {}
    for it in items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    doc = {"_about": "Street details along the main line (tools/bake_street_details.py, docs/design/street-details.md): "
                     "[kind, x, z, yaw, colour]; yaw turns +z away from the street. Derived from game/map/centrum.json.",
           "src": src_hash(data), "kinds": KINDS, "items": items}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    print("street details: %d items (%s), %d stop kit pieces -> %s" % (len(items), ", ".join("%s %d" % kv for kv in sorted(counts.items())), stops, out))


if __name__ == "__main__":
    main(sys.argv[1:])
