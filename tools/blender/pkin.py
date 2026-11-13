"""Build the Palace of Culture and Science (PKiN) in Blender and export it as glTF.

Usage (headless, from the repo root):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/pkin.py -- \
        [--lod=0|1] [--out=game/models/pkin/pkin_lod0.glb] [--blend=build/pkin.blend] [--render=DIR]

The Blender trial (2026-11-13): a hero landmark modelled in Blender instead of landmarks.gd's
code, to see whether Blender pays for the top landmarks. The model is built from the same plan
as `_build_palace` (the OSM parts in game/map/centrum.json, spec docs/landmarks/specs/palace.md)
and the reference photos, with the detail code makes awkward: profiled cornices, real round
columns, pinnacles with pedestals, shafts and finials, the lantern's open arches, the crowns of the
corner towers, the Congress Hall's stepped drum and the spire's rings and orb.

It keeps to the city's one building surface: every material is named `M<code>_<rrggbb>` after
landmarks.gd's M_* codes (M_ATTIC carries its height fraction, `M9.16`), UV map `wall` holds the
shader's wall coordinates (metres along the facade, metres above the ground; (-1, -1) on tops)
and UV map `top` holds (0, the wall's top above the ground). landmarks.gd `_palace_glb` reads the
glb and emits its triangles into the city mesh, so the Palace costs no draw call and no shader of
its own. Axes: Blender x = u (towards Marszałkowska), y = -v, z = metres above the ground; glTF
turns that into (u, h, v).

LOD 0 is the full model (the sectors); LOD 1 drops the small ornament (a far stand-in).
"""
import json
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector, geometry

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OPT = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in ARGS if a.startswith("--"))
LOD = int(OPT.get("lod", "0"))
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = OPT.get("out", os.path.join(ROOT, "game", "models", "pkin", "pkin_lod%d.glb" % LOD))

# --- landmarks.gd's material codes and the spec's colours -------------------------------------
M_MONUMENT, M_STONE, M_GOLD, M_DIAL, M_ATTIC = 2.0, 3.0, 4.0, 5.0, 9.0
SAND = "d8c49c"        # walls
SAND_D = "c7b490"      # courtyard walls (8 % darker)
LIGHT = "e6d6b2"       # attics, pinnacles, cornices, columns
PLINTH = "b8a888"      # the granite-ish plinth band
ROOF = "8f877a"
COURT = "a39c90"
METAL = "8d9398"       # the Congress Hall's roof
DARK = "3a3640"        # the lantern's open arches
PATINA = "9fbcae"
BRONZE = "5a4630"
GOLD = "d4a640"


def shade(hexcol, f):
    c = [int(hexcol[i:i + 2], 16) for i in (0, 2, 4)]
    c = [max(0, min(255, round(x * f))) for x in c]
    return "%02x%02x%02x" % tuple(c)


# --- the plan, copied from landmarks.gd (local u, v in metres from the clock tier's centre) -----
P_WINGS = [
    [-79.5, 68.7, -53.0, 119.7, 22.5], [-81.0, -120.9, -53.7, -70.5, 22.5],
    [53.9, -121.0, 80.4, -69.8, 22.5], [55.5, 68.3, 82.1, 119.4, 22.5],
    [28.0, -10.6, 46.4, 12.1, 22.5],
]
P_BLOCKS = [
    [[-7.7, 64.6], [-12.4, 64.6], [-12.4, 60.3], [-17.7, 60.3], [-17.8, 44.5], [-13.5, 44.5], [-13.4, 34.1],
     [-13.5, 21.4], [-10.3, 21.4], [-10.3, 20.0], [10.5, 20.1], [10.5, 21.6], [14.0, 21.6], [14.1, 34.1],
     [14.0, 45.4], [17.2, 45.4], [17.3, 60.1], [12.2, 60.1], [12.3, 64.6], [7.7, 64.7]],
    [[-12.2, -63.9], [-12.3, -68.2], [11.1, -68.0], [11.1, -63.7], [16.5, -63.7], [16.5, -49.9], [14.2, -49.9],
     [14.2, -21.8], [9.8, -21.7], [9.8, -20.2], [-10.6, -20.2], [-10.6, -21.8], [-15.0, -21.8], [-15.1, -50.2],
     [-17.6, -50.2], [-17.6, -63.9]],
]
P_TIER = [[-21.7, 10.8], [-20.4, 10.7], [-20.5, -10.3], [-22.3, -10.3], [-22.3, -17.6], [-32.6, -17.7],
          [-32.5, -35.4], [-15.1, -35.4], [-15.0, -21.8], [-10.6, -21.8], [-10.6, -20.2], [9.8, -20.2], [9.8, -21.7],
          [14.2, -21.8], [14.2, -35.8], [31.8, -35.7], [31.8, -17.7], [20.9, -17.7], [21.0, -9.3], [19.7, -9.3],
          [19.8, 10.8], [21.2, 10.7], [21.2, 16.6], [31.8, 16.6], [31.8, 34.2], [14.1, 34.1], [14.0, 21.6],
          [10.5, 21.6], [10.5, 20.1], [-10.3, 20.0], [-10.3, 21.4], [-13.4, 21.4], [-13.4, 34.1], [-31.6, 34.1],
          [-31.6, 16.6], [-21.6, 16.7]]
P_CORNERS = [[-32.6, -35.4, -15.0, -17.7], [14.2, -35.8, 31.8, -17.7], [14.1, 16.6, 31.8, 34.2],
             [-31.6, 16.6, -13.4, 34.1]]
P_SHAFT = [[-21.6, 16.7], [-21.7, 10.8], [-20.4, 10.7], [-20.5, -10.3], [-22.3, -10.3], [-22.3, -21.9],
           [-10.6, -21.8], [-10.6, -20.2], [9.8, -20.2], [9.8, -21.7], [21.0, -21.7], [21.0, -9.3], [19.7, -9.3],
           [19.8, 10.8], [21.2, 10.7], [21.2, 21.6], [10.5, 21.6], [10.5, 20.1], [-10.3, 20.0], [-10.3, 21.4],
           [-21.7, 21.3]]
P_BAYS = [[19.75, 0.75, 1.0, 0.0, 10.0], [-20.45, 0.2, -1.0, 0.0, 10.4], [0.1, 20.05, 0.0, 1.0, 10.4],
          [-0.4, -20.2, 0.0, -1.0, 10.2]]
P_COURTS = [
    [[-68.4, 40.7], [-67.6, 40.7], [-67.6, 36.1], [-48.8, 36.2], [-48.8, 32.8], [-34.4, 32.9], [-34.4, 65.1],
     [-48.2, 65.1], [-48.2, 63.9], [-68.4, 63.9]],
    [[-69.2, -41.8], [-69.2, -64.4], [-49.4, -64.3], [-49.4, -65.4], [-34.8, -65.4], [-34.7, -33.5],
     [-49.1, -33.5], [-49.1, -37.4], [-67.9, -37.4], [-67.9, -41.8]],
]
P_HALL = [[-93.6, 24.6], [-97.3, 23.1], [-101.6, 20.3], [-104.4, 18.0], [-107.7, 14.2], [-110.0, 10.0],
          [-111.8, 5.7], [-112.7, 1.3], [-112.6, -2.6], [-111.9, -6.8], [-110.5, -10.8], [-108.8, -14.4],
          [-106.6, -17.3], [-104.2, -20.2], [-101.2, -22.4], [-97.2, -24.6], [-93.3, -26.0], [-89.0, -26.8],
          [-80.5, -26.7], [-80.5, -34.2], [-65.8, -34.1], [-65.7, -22.4], [-63.3, -22.5], [-63.3, -20.0],
          [-55.3, -20.0], [-55.3, 18.8], [-62.4, 18.8], [-62.4, 20.9], [-65.1, 20.9], [-65.0, 33.4], [-80.3, 33.3],
          [-80.3, 25.3], [-89.3, 25.3]]


def palace_outline():
    """The base's mapped outline in the local frame, framed like landmarks.gd `_palace_frame`."""
    d = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json")))
    pts = None
    for lm in d["landmarks"]:
        if lm.get("name") == "Pałac Kultury i Nauki":
            p = lm["p"]
            pts = [(p[i], p[i + 1]) for i in range(0, len(p) - 1, 2)]
            break
    xs = [q[0] for q in pts]
    zs = [q[1] for q in pts]
    o, a = (-1214.25, 247.3), (0.9403, -0.3404)
    for b in d["buildings"]:
        if abs(float(b.get("h", 0)) - 168.0) < 0.5 and abs(float(b.get("mh", 0)) - 139.0) < 0.5:
            bp = b["p"]
            sq = [(bp[i], bp[i + 1]) for i in range(0, len(bp) - 1, 2)]
            c = (sum(q[0] for q in sq) / len(sq), sum(q[1] for q in sq) / len(sq))
            if min(xs) <= c[0] <= max(xs) and min(zs) <= c[1] <= max(zs):
                for i in range(len(sq)):
                    e = (sq[(i + 1) % len(sq)][0] - sq[i][0], sq[(i + 1) % len(sq)][1] - sq[i][1])
                    ln = math.hypot(*e)
                    if ln > 5.0 and abs(e[0] / ln) > 0.7:
                        s = 1.0 if e[0] > 0 else -1.0
                        o, a = c, (e[0] / ln * s, e[1] / ln * s)
                        break
                break
    b_ = (-a[1], a[0])
    loc = []
    for x, z in pts:
        dx, dz = x - o[0], z - o[1]
        loc.append([dx * a[0] + dz * a[1], dx * b_[0] + dz * b_[1]])
    if len(loc) > 1 and loc[0] == loc[-1]:
        loc.pop()
    return loc, o, a


# --- geometry accumulation ---------------------------------------------------------------------
class Model:
    """Triangles per material, with the shader's UVs worked out per face."""

    def __init__(self):
        self.verts = []        # Vector (u, v, h)
        self.faces = []        # (idx list, material key, smooth, uv list or None, top)
        self.mats = {}

    def mat(self, mode, col):
        key = ("M%g" % mode) + "_" + col
        self.mats.setdefault(key, len(self.mats))
        return key

    def face(self, pts, mode, col, smooth=False, wall_uv=None, top=None):
        """A planar polygon (u, v, h points, counter-clockwise seen from outside)."""
        base = len(self.verts)
        self.verts.extend(Vector(p) for p in pts)
        self.faces.append((list(range(base, base + len(pts))), self.mat(mode, col), smooth, wall_uv, top))

    # Plan helpers ------------------------------------------------------------------------------
    @staticmethod
    def ccw(poly):
        s = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1]
                for i in range(len(poly)))
        return poly if s > 0 else list(reversed(poly))

    def walls(self, poly, h0, h1, mode, col, outward=True, skip=None, smooth=False):
        """Vertical walls round a plan polygon from h0 to h1, facing out (or in for courtyards)."""
        poly = self.ccw(poly)
        if not outward:
            poly = list(reversed(poly))
        n = len(poly)
        for i in range(n):
            a, b = poly[i], poly[(i + 1) % n]
            if skip and skip(a, b):
                continue
            if math.hypot(b[0] - a[0], b[1] - a[1]) < 0.02:
                continue
            self.face([(a[0], a[1], h0), (b[0], b[1], h0), (b[0], b[1], h1), (a[0], a[1], h1)], mode, col,
                      smooth=smooth, top=h1)

    def cap(self, poly, h, mode, col, holes=(), down=False):
        """A flat top (with holes) at h."""
        rings = [[Vector((p[0], p[1], 0.0)) for p in self.ccw(poly)]]
        for hl in holes:
            rings.append([Vector((p[0], p[1], 0.0)) for p in reversed(self.ccw(hl))])
        tris = geometry.tessellate_polygon(rings)
        flat = [p for r in rings for p in r]
        for t in tris:
            pts = [(flat[k].x, flat[k].y, h) for k in t]
            # tessellate_polygon's winding is arbitrary: make it face up (or down).
            e1 = Vector(pts[1]) - Vector(pts[0])
            e2 = Vector(pts[2]) - Vector(pts[0])
            if (e1.cross(e2).z < 0) != down:
                pts = [pts[0], pts[2], pts[1]]
            self.face(pts, mode, col)

    def prism(self, poly, h0, h1, mode, col, top_mode=M_STONE, top_col=ROOF, cap=True):
        self.walls(poly, h0, h1, mode, col)
        if cap:
            self.cap(poly, h1, top_mode, top_col)

    def box(self, cu, cv, hu, hv, h0, h1, col, mode=M_STONE, top_col=None, bottom=False):
        poly = [(cu - hu, cv - hv), (cu + hu, cv - hv), (cu + hu, cv + hv), (cu - hu, cv + hv)]
        self.prism(poly, h0, h1, mode, col, M_STONE, top_col or col)
        if bottom:
            self.cap(poly, h0, M_STONE, col, down=True)

    def frustum(self, ring0, h0, ring1, h1, mode, col, smooth=False, top_col=None):
        n = len(ring0)
        for i in range(n):
            a0, b0 = ring0[i], ring0[(i + 1) % n]
            a1, b1 = ring1[i], ring1[(i + 1) % n]
            self.face([(a0[0], a0[1], h0), (b0[0], b0[1], h0), (b1[0], b1[1], h1), (a1[0], a1[1], h1)], mode, col,
                      smooth=smooth, top=h1)
        if top_col:
            self.cap(ring1, h1, M_STONE, top_col)

    def cone(self, ring, h0, apex, mode, col, smooth=False):
        n = len(ring)
        for i in range(n):
            a, b = ring[i], ring[(i + 1) % n]
            self.face([(a[0], a[1], h0), (b[0], b[1], h0), apex], mode, col, smooth=smooth, top=apex[2])

    @staticmethod
    def ngon(cu, cv, r, n, turn=0.0):
        return [(cu + r * math.cos(turn + 2 * math.pi * k / n), cv + r * math.sin(turn + 2 * math.pi * k / n))
                for k in range(n)]

    @staticmethod
    def rect(cu, cv, hu, hv):
        return [(cu - hu, cv - hv), (cu + hu, cv - hv), (cu + hu, cv + hv), (cu - hu, cv + hv)]


def offset(poly, d):
    """Mitred outward offset of a plan polygon by d metres (negative: inward)."""
    poly = Model.ccw(poly)
    n = len(poly)
    out = []
    for i in range(n):
        p0, p1, p2 = Vector(poly[i - 1]), Vector(poly[i]), Vector(poly[(i + 1) % n])
        e0 = (p1 - p0).normalized()
        e1 = (p2 - p1).normalized()
        n0 = Vector((e0.y, -e0.x))
        n1 = Vector((e1.y, -e1.x))
        m = n0 + n1
        if m.length < 1e-4:
            m = n0
        m.normalize()
        k = max(m.dot(n0), 0.35)
        q = p1 + m * (d / k)
        out.append((q.x, q.y))
    return out


def dedupe(poly, eps=0.05):
    out = []
    for p in poly:
        if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > eps:
            out.append(p)
    if len(out) > 2 and math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1]) <= eps:
        out.pop()
    return out


# --- the parts ---------------------------------------------------------------------------------
def cornice(m, poly, h, depth=0.8, height=1.4, col=LIGHT, steps=3):
    """A profiled cornice: `steps` corbelled bands stepping out to `depth`, topped by a slab."""
    for k in range(steps):
        d0 = depth * k / steps
        d1 = depth * (k + 1) / steps
        hh0 = h - height + height * k / steps
        hh1 = h - height + height * (k + 1) / steps
        ring = offset(poly, d1)
        m.walls(ring, hh0, hh1, M_STONE, col if k < steps - 1 else shade(col, 1.04))
        # The soffit under each step.
        inner = offset(poly, d0)
        m.cap_ring_band(inner, ring, hh0, col)
    m.cap_ring_band(poly, offset(poly, depth), h, col, up=True)


def cap_ring_band(self, inner, outer, h, col, up=False):
    """A flat band between two rings of the same corners (a cornice's top or soffit)."""
    inner = Model.ccw(inner)
    outer = Model.ccw(outer)
    n = len(inner)
    for i in range(n):
        a0, b0 = inner[i], inner[(i + 1) % n]
        a1, b1 = outer[i], outer[(i + 1) % n]
        pts = [(a0[0], a0[1], h), (a1[0], a1[1], h), (b1[0], b1[1], h), (b0[0], b0[1], h)]
        if up:
            pts = list(reversed(pts))
        self.face(pts, M_STONE, col)


Model.cap_ring_band = cap_ring_band


def attic(m, poly, h, height, col=LIGHT, closed=True):
    """A crenellated parapet: the shader cuts the merlons (M_ATTIC + height / 10)."""
    mode = M_ATTIC + min(height / 10.0, 0.99)
    poly = Model.ccw(poly)
    n = len(poly)
    for i in range(n if closed else n - 1):
        a, b = poly[i], poly[(i + 1) % n]
        m.face([(a[0], a[1], h), (b[0], b[1], h), (b[0], b[1], h + height), (a[0], a[1], h + height)], mode, col,
               top=h + height)


def pinnacle(m, cu, cv, w, h0, h, col=LIGHT):
    """A pinnacle as on the photos: a square pedestal with a cap moulding, a tapering octagonal
    obelisk, a ring and a finial ball on a point. LOD 1: the square shaft and cap of landmarks.gd."""
    r = w * 0.5
    if LOD > 0:
        m.box(cu, cv, r, r, h0, h0 + h * 0.62, col)
        m.cone(Model.rect(cu, cv, r * 1.15, r * 1.15), h0 + h * 0.62, (cu, cv, h0 + h), M_STONE, shade(col, 1.08))
        return
    hp = h0 + h * 0.28
    m.walls(Model.rect(cu, cv, r, r), h0, hp, M_STONE, col)
    m.frustum(Model.rect(cu, cv, r, r), hp, Model.rect(cu, cv, r * 1.18, r * 1.18), hp + h * 0.05, M_STONE,
              shade(col, 1.05))
    m.cap(Model.rect(cu, cv, r * 1.18, r * 1.18), hp + h * 0.05, M_STONE, shade(col, 1.05))
    o0 = Model.ngon(cu, cv, r * 0.78, 8, math.pi / 8)
    o1 = Model.ngon(cu, cv, r * 0.5, 8, math.pi / 8)
    hs = hp + h * 0.05
    ho = hs + h * 0.42
    m.frustum(o0, hs, o1, ho, M_STONE, col)
    ring = Model.ngon(cu, cv, r * 0.7, 8, math.pi / 8)
    m.frustum(o1, ho, ring, ho + h * 0.03, M_STONE, shade(col, 1.06))
    m.frustum(ring, ho + h * 0.03, o1, ho + h * 0.06, M_STONE, shade(col, 1.06))
    m.cone(o1, ho + h * 0.06, (cu, cv, h0 + h * 0.93), M_STONE, shade(col, 1.08))
    ball = Model.ngon(cu, cv, r * 0.32, 6)
    m.frustum(ball, h0 + h * 0.9, ball, h0 + h * 0.96, M_STONE, shade(col, 1.1))
    m.cone(ball, h0 + h * 0.96, (cu, cv, h0 + h), M_STONE, shade(col, 1.1))


def column(m, cu, cv, r, h0, h1, col=LIGHT, n=12):
    """A round column with a square base and a capital (smooth shaft)."""
    hb = h0 + 0.6
    m.box(cu, cv, r * 1.35, r * 1.35, h0, hb, col)
    shaft0 = Model.ngon(cu, cv, r, n)
    shaft1 = Model.ngon(cu, cv, r * 0.86, n)
    m.frustum(shaft0, hb, shaft1, h1 - 0.9, M_STONE, col, smooth=True)
    m.frustum(shaft1, h1 - 0.9, Model.ngon(cu, cv, r * 1.15, n), h1 - 0.45, M_STONE, shade(col, 1.04), smooth=True)
    m.box(cu, cv, r * 1.3, r * 1.3, h1 - 0.45, h1, shade(col, 1.04))


def crest(m, cu, cv, w, h0, h, nu, nv, col=LIGHT):
    """The corner towers' central cartouche (photo 1): a stepped scrolled block facing (nu, nv)."""
    if LOD > 0:
        m.box(cu, cv, w * 0.5, w * 0.5, h0, h0 + h * 0.6, col)
        return
    side = (-nv, nu)
    def pt(s, d, z):
        return (cu + side[0] * s + nu * d, cv + side[1] * s + nv * d, z)
    # The scroll's outline in the face plane (s, z), extruded 1.2 m deep.
    prof = [(-w / 2, 0), (w / 2, 0), (w / 2, h * 0.35), (w * 0.32, h * 0.5), (w * 0.22, h * 0.78), (0, h),
            (-w * 0.22, h * 0.78), (-w * 0.32, h * 0.5), (-w / 2, h * 0.35)]
    d = 0.6
    front = [pt(s, d, h0 + z) for s, z in prof]
    back = [pt(s, -d, h0 + z) for s, z in reversed(prof)]
    m.face(front, M_STONE, col, top=h0 + h)
    m.face(back, M_STONE, col, top=h0 + h)
    n = len(prof)
    for i in range(n):
        s0, z0 = prof[i]
        s1, z1 = prof[(i + 1) % n]
        m.face([pt(s1, d, h0 + z1), pt(s0, d, h0 + z0), pt(s0, -d, h0 + z0), pt(s1, -d, h0 + z1)], M_STONE,
               shade(col, 0.95), top=h0 + h)


def arch_face(m, cu, cv, nu, nv, half, h0, h1, arches, aw, a0, a1, col, depth=0.7, wall_mode=M_STONE):
    """One face of a square tier with `arches` open round-headed arches: the wall with arch-shaped
    holes, the reveals, and a dark back panel `depth` behind."""
    side = (-nv, nu)

    def pt(s, z, d=0.0):
        return (cu + nu * (half - d) + side[0] * s, cv + nv * (half - d) + side[1] * s, z)

    holes = []
    step = 2 * half / arches
    for k in range(arches):
        c = -half + step * (k + 0.5)
        ring = [(c - aw / 2, a0), (c + aw / 2, a0), (c + aw / 2, a1 - aw / 2)]
        segs = 6 if LOD == 0 else 2
        for j in range(1, segs):
            t = math.pi * j / segs
            ring.append((c + aw / 2 * math.cos(t), a1 - aw / 2 + aw / 2 * math.sin(t)))
        ring.append((c - aw / 2, a1 - aw / 2))
        holes.append(ring)
    outer = [Vector((-half, h0, 0)), Vector((half, h0, 0)), Vector((half, h1, 0)), Vector((-half, h1, 0))]
    rings = [outer] + [[Vector((s, z, 0)) for s, z in reversed(r)] for r in holes]
    flat = [p for r in rings for p in r]
    for t in geometry.tessellate_polygon(rings):
        p = [flat[k] for k in t]
        if (p[1] - p[0]).cross(p[2] - p[0]).z < 0:
            p = [p[0], p[2], p[1]]
        m.face([pt(q.x, q.y) for q in p], wall_mode, col, top=h1)
    for r in holes:
        n = len(r)
        for i in range(n):
            s0, z0 = r[i]
            s1, z1 = r[(i + 1) % n]
            m.face([pt(s0, z0), pt(s0, z0, depth), pt(s1, z1, depth), pt(s1, z1)], M_STONE, shade(col, 0.85),
                   top=h1)
        m.face([pt(s, z, depth) for s, z in r], M_STONE, DARK, top=h1)


def portico_on_edge(m, a, b, cols, h, out, r=0.6, depth=1.4):
    """Columns standing in front of a wall edge a-b (plan), facing `out`, with the dark loggia
    behind them, an entablature and a low attic on it: the pavilions' porticos and porches."""
    a, b, out = Vector(a), Vector(b), Vector(out)
    d = (b - a).normalized()
    ln = (b - a).length
    p0 = a + d * 0.5 + out * 0.05
    p1 = b - d * 0.5 + out * 0.05
    m.face([(p0.x, p0.y, 1.6), (p1.x, p1.y, 1.6), (p1.x, p1.y, h - 0.3), (p0.x, p0.y, h - 0.3)], M_STONE, DARK,
           top=h)
    for k in range(cols):
        c = a + d * (ln * (k + 0.5) / cols) + out * depth
        column(m, c.x, c.y, r, 0.0, h, n=12 if LOD == 0 else 6)
    e0 = a - d * 0.4
    e1 = b + d * 0.4
    q = [(e0.x, e0.y), (e1.x, e1.y), (e1.x + out.x * (depth + 1.1), e1.y + out.y * (depth + 1.1)),
         (e0.x + out.x * (depth + 1.1), e0.y + out.y * (depth + 1.1))]
    m.prism(q, h, h + 1.6, M_STONE, LIGHT, M_STONE, ROOF)
    m.cap(q, h, M_STONE, shade(LIGHT, 0.9), down=True)
    if LOD == 0:
        m.walls(offset(q, 0.25), h + 1.2, h + 1.6, M_STONE, shade(LIGHT, 1.04))


def build(m):
    outer, _o, _a = palace_outline()
    outer = dedupe(outer)
    light, stone = LIGHT, SAND

    # 1. The base (0-18 m): the plinth band, the walls with tall windows, a cornice, the roof round
    # the courtyards and the attic.
    m.walls(offset(outer, 0.25), -0.4, 1.6, M_STONE, PLINTH)
    m.cap_ring_band(outer, offset(outer, 0.25), 1.6, PLINTH, up=True)
    m.walls(outer, 1.6, 18.0 - 1.2, M_MONUMENT, stone)
    cornice(m, outer, 18.0, depth=0.9, height=1.2, steps=3 if LOD == 0 else 1)
    for ring in P_COURTS:
        m.walls(ring, 4.0, 18.0, M_MONUMENT, SAND_D, outward=False)
        m.cap(ring, 4.0, M_STONE, COURT)
    m.cap(outer, 18.0, M_STONE, ROOF, holes=P_COURTS)
    attic(m, offset(outer, 0.4), 18.0, 1.6)

    # 1b. The ground floor that the car sees (F, 2026-11-13: "make the elements near the ground
    # well"): porticos on the pavilions' outer ends, porches on their long sides (the outline's
    # shallow projections there, photos 4.jpg and Muzeum Techniki), the Congress Hall's colonnade
    # round its half-round end and the main entrance's steps.
    ring = Model.ccw(outer)
    targets = [((-68.2, -132.7), 4, 12.5), ((66.5, -133.2), 4, 12.5), ((68.2, 132.3), 4, 12.5),
               ((-66.0, 132.4), 4, 12.5),
               ((-91.5, -116.2), 4, 11.0), ((-90.9, -72.4), 4, 11.0), ((89.2, -116.9), 4, 11.0),
               ((89.4, -73.1), 4, 11.0), ((90.2, 71.0), 4, 11.0), ((90.6, 114.7), 4, 11.0),
               ((-89.4, 116.7), 4, 11.0), ((-89.9, 72.5), 4, 11.0)]
    for tgt, cols, h in targets:
        best = None
        for i in range(len(ring)):
            a, b = Vector(ring[i]), Vector(ring[(i + 1) % len(ring)])
            dd = ((a + b) / 2 - Vector(tgt)).length
            if (b - a).length > 8.0 and (best is None or dd < best[0]):
                best = (dd, a, b)
        if best and best[0] < 3.0:
            a, b = best[1], best[2]
            e = (b - a).normalized()
            portico_on_edge(m, a, b, cols, h, (e.y, -e.x))
    # The Congress Hall's colonnade: columns round the half-round west end, an entablature ring.
    arc = [Vector(q) for q in ring if q[0] < -92.0]
    if arc:
        centre = Vector((-88.0, 0.0))
        rr = sum((q - centre).length for q in arc) / len(arc)
        a0 = math.radians(112.0)
        a1 = math.radians(248.0)
        ncol = 18 if LOD == 0 else 9
        for k in range(ncol):
            t = a0 + (a1 - a0) * k / (ncol - 1)
            c = centre + Vector((math.cos(t), math.sin(t))) * (rr + 1.3)
            column(m, c.x, c.y, 0.55, 0.0, 9.5, n=10 if LOD == 0 else 6)
        nseg_e = 28 if LOD == 0 else 12
        band0 = [(centre.x + (rr + 0.1) * math.cos(a0 + (a1 - a0) * k / nseg_e),
                  centre.y + (rr + 0.1) * math.sin(a0 + (a1 - a0) * k / nseg_e)) for k in range(nseg_e + 1)]
        band1 = [(centre.x + (rr + 2.2) * math.cos(a0 + (a1 - a0) * k / nseg_e),
                  centre.y + (rr + 2.2) * math.sin(a0 + (a1 - a0) * k / nseg_e)) for k in range(nseg_e + 1)]
        for k in range(nseg_e):
            p0, p1, q0, q1 = band1[k], band1[k + 1], band0[k], band0[k + 1]
            m.face([(p0[0], p0[1], 9.5), (p1[0], p1[1], 9.5), (p1[0], p1[1], 11.0), (p0[0], p0[1], 11.0)],
                   M_STONE, LIGHT, top=11.0)
            m.face([(q0[0], q0[1], 11.0), (q1[0], q1[1], 11.0), (p1[0], p1[1], 11.0), (p0[0], p0[1], 11.0)],
                   M_STONE, LIGHT)
            m.face([(p0[0], p0[1], 9.5), (p1[0], p1[1], 9.5), (q1[0], q1[1], 9.5), (q0[0], q0[1], 9.5)],
                   M_STONE, shade(LIGHT, 0.85))
    # The main entrance's steps (three, 0.15 m) and the two seated monuments beside them.
    for k, (u0, h) in enumerate(((52.0, 0.45), (55.6, 0.3), (56.6, 0.15))):
        m.box((u0 + 57.6) / 2, 0.0, (57.6 - u0) / 2, 15.0 + k * 0.6, -0.2, h, shade(PLINTH, 1.05))
    # The two seated monuments beside the steps are the map's own (bake_monuments.py), not built here.

    # 2. The wings: the corner pavilions and the entrance block (to 22.5 m), each with a cornice,
    # an attic and pinnacles on its corners and halfway along its long sides.
    for w in P_WINGS:
        poly = [(w[0], w[1]), (w[2], w[1]), (w[2], w[3]), (w[0], w[3])]
        m.walls(poly, 17.0, w[4] - 0.9, M_MONUMENT, stone)
        cornice(m, poly, w[4], depth=0.7, height=0.9, steps=2 if LOD == 0 else 1)
        m.cap(poly, w[4], M_STONE, ROOF)
        attic(m, offset(poly, 0.3), w[4], 1.4)
        for k in range(4):
            cu = w[0] if k % 2 == 0 else w[2]
            cv = w[1] if k < 2 else w[3]
            pinnacle(m, cu, cv, 1.4, w[4], 4.2)
        if LOD == 0 and abs(w[3] - w[1]) > 40:
            for cu in (w[0], w[2]):
                for t in (0.33, 0.66):
                    pinnacle(m, cu, w[1] + (w[3] - w[1]) * t, 1.0, w[4], 3.2)

    # 3. The north and south blocks (to 30 m); no wall where they meet the tower.
    tier_set = P_TIER

    def on_tier(a, b):
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        for i in range(len(tier_set)):
            p, q = Vector(tier_set[i]), Vector(tier_set[(i + 1) % len(tier_set)])
            c, t = geometry.intersect_point_line(Vector(mid), p, q)
            t = max(0.0, min(1.0, t))
            if (p.lerp(q, t) - Vector(mid)).length < 0.4:
                return True
        return False

    for blk in P_BLOCKS:
        m.walls(blk, 17.0, 29.0, M_MONUMENT, stone, skip=on_tier)
        m.cap(blk, 30.0 - 0.0, M_STONE, ROOF)
        outer_end = [q for q in blk if abs(q[1]) > 40.0]
        # The cornice band round the block's outer part.
        m.walls(offset(blk, 0.5), 29.0, 30.0, M_STONE, light, skip=on_tier)
        attic(m, outer_end, 30.0, 1.4, closed=False)
        far = 60.2 if blk[0][1] > 0 else -63.8
        near = 45.0 if blk[0][1] > 0 else -50.0
        for cu in (-17.6, 17.2):
            pinnacle(m, cu, far, 1.6, 30.0, 5.0)
            pinnacle(m, cu, near, 1.6, 30.0, 5.0)

    # 4. The Congress Hall (to 22.5 m): the walls, a cornice, and its stepped metal roof: a
    # 24-sided drum over the auditorium in two steps and the vent on top.
    hall = dedupe(P_HALL)
    m.walls(hall, 17.0, 21.6, M_MONUMENT, stone)
    cornice(m, hall, 22.5, depth=0.7, height=0.9, steps=2 if LOD == 0 else 1)
    m.cap(hall, 22.5, M_STONE, METAL)
    attic(m, offset(hall, 0.3), 22.5, 1.2)
    nseg = 24 if LOD == 0 else 12
    d0 = Model.ngon(-86.0, 0.0, 24.0, nseg)
    d1 = Model.ngon(-86.0, 0.0, 21.0, nseg)
    m.walls(d0, 22.5, 24.5, M_STONE, shade(METAL, 0.88))
    m.cap_ring_band(d1, d0, 24.5, shade(METAL, 1.06), up=True)
    m.walls(d1, 24.5, 26.0, M_STONE, shade(METAL, 0.88))
    m.cap(d1, 26.0, M_STONE, shade(METAL, 1.06))
    m.box(-86.0, 0.0, 3.0, 3.0, 26.0, 27.0, shade(METAL, 0.8))

    # 5. The east entrance: six round columns, 13.5 m, under an entablature and a low attic.
    for k in range(6):
        column(m, 53.4, -12.0 + k * 4.8, 0.65, 0.45, 13.5, n=12 if LOD == 0 else 6)
    m.box(51.0, 0.0, 3.0, 13.4, 13.5, 15.6, light)
    if LOD == 0:
        m.box(51.2, 0.0, 3.1, 13.6, 15.6, 16.0, shade(light, 1.04))
    attic(m, [(54.0, -13.0), (54.0, 13.0)], 16.0, 1.2, closed=False)

    # 6. The tower's first tier (18-67 m) with a belt cornice at 52 m; the corner towers carry an
    # attic, a cornice, a crest on each outer face, and pinnacles on the corners and between.
    m.walls(P_TIER, 17.0, 66.0, M_MONUMENT, stone)
    for c in P_CORNERS:
        poly = [(c[0], c[1]), (c[2], c[1]), (c[2], c[3]), (c[0], c[3])]
        cu, cv = (c[0] + c[2]) / 2, (c[1] + c[3]) / 2
        if LOD == 0:
            m.walls(offset(poly, 0.35), 51.5, 52.5, M_STONE, light)
        cornice(m, poly, 67.0, depth=0.8, height=1.0, steps=2 if LOD == 0 else 1)
        m.cap(poly, 67.0, M_STONE, ROOF)
        attic(m, offset(poly, 0.3), 67.0, 2.2)
        # The stepped crown: a 9 m block to 70 m, a 5 m one to 73 m.
        m.prism(Model.rect(cu, cv, 4.5, 4.5), 67.0, 70.0, M_STONE, light, M_STONE, ROOF)
        m.prism(Model.rect(cu, cv, 2.6, 2.6), 70.0, 73.0, M_STONE, light, M_STONE, ROOF)
        pinnacle(m, cu, cv, 1.6, 73.0, 9.0)
        # Corner pinnacles that stand clear of the shaft, and one between them on outer faces.
        su = 1 if cu > 0 else -1
        sv = 1 if cv > 0 else -1
        for pu, pv in ((c[0], c[1]), (c[2], c[1]), (c[2], c[3]), (c[0], c[3])):
            if abs(pu) < 22.5 and abs(pv) < 22.5:
                continue
            pinnacle(m, pu, pv, 1.4, 67.0 + 2.2, 6.0)
        if LOD == 0:
            crest(m, cu + su * 7.6, cv, 3.6, 69.2, 4.2, su, 0)
            crest(m, cu, cv + sv * 7.6, 3.6, 69.2, 4.2, 0, sv)
            pinnacle(m, cu + su * 8.4, cv - sv * 4.4, 1.0, 69.2, 4.0)
            pinnacle(m, cu - su * 4.4, cv + sv * 8.4, 1.0, 69.2, 4.0)

    # 7. The shaft (67-139 m): the mapped plan (corner piers forward of the middle bays), the
    # ribs up each middle bay, the cornice band at 121.5 m, the terrace ledge at 114 m, the top
    # cornice, attic and pinnacles.
    m.walls(P_SHAFT, 66.0, 137.5, M_MONUMENT, stone)
    for bay in P_BAYS:
        nu, nv = bay[2], bay[3]
        for k in range(5):
            t = -bay[4] + bay[4] * 0.2 + k * bay[4] * 0.4
            ru = bay[0] + nu * 0.45 + abs(nv) * t
            rv = bay[1] + nv * 0.45 + abs(nu) * t
            hu = 0.45 if nu != 0 else 0.5
            hv = 0.45 if nv != 0 else 0.5
            m.box(ru, rv, hu, hv, 67.0, 121.5, light)
            m.box(ru, rv, hu, hv, 123.0, 136.0, light)
    # The top storeys' tall round-headed loggia openings between the ribs (F's close-up from
    # the 30th floor, 2026-11-13): a dark arch on each face's middle bay, 4 per face.
    if LOD == 0:
        for bay in P_BAYS:
            nu, nv = bay[2], bay[3]
            side = (-nv, nu)
            for k in range(4):
                t = -bay[4] + bay[4] * 0.4 + k * bay[4] * 0.4
                cu = bay[0] + nu * 0.06 + side[0] * t
                cv = bay[1] + nv * 0.06 + side[1] * t
                ring = [(-1.1, 127.0), (1.1, 127.0), (1.1, 133.9)]
                for j in range(1, 6):
                    a = math.pi * j / 6
                    ring.append((1.1 * math.cos(a), 133.9 + 1.1 * math.sin(a)))
                ring.append((-1.1, 133.9))
                m.face([(cu + side[0] * s_, cv + side[1] * s_, z) for s_, z in ring], M_STONE, DARK, top=136.0)
    m.walls(offset(P_SHAFT, 0.6), 121.5, 123.0, M_STONE, light)
    m.cap_ring_band(P_SHAFT, offset(P_SHAFT, 0.6), 123.0, light, up=True)
    m.cap_ring_band(P_SHAFT, offset(P_SHAFT, 0.6), 121.5, light)
    for su in (-1.0, 1.0):
        m.box(su * 21.5, 0.0, 0.95, 11.7, 113.5, 114.0, light, top_col=shade(light, 0.88), bottom=True)
        m.box(0.0, su * 21.5, 11.7, 0.95, 113.5, 114.0, light, top_col=shade(light, 0.88), bottom=True)
        m.box(su * 23.25, 0.0, 0.075, 11.7, 114.0, 115.1, light)
        m.box(0.0, su * 23.25, 11.7, 0.075, 114.0, 115.1, light)
    cornice(m, P_SHAFT, 139.0, depth=1.1, height=1.5, steps=3 if LOD == 0 else 1)
    m.cap(P_SHAFT, 139.0, M_STONE, ROOF)
    attic(m, offset(P_SHAFT, 0.5), 139.0, 3.0)
    for k in range(4):
        su = -1.0 if k % 2 == 0 else 1.0
        sv = -1.0 if k < 2 else 1.0
        pinnacle(m, su * 18.8, sv * 18.8, 3.4, 139.0, 14.0)
    for sd in (-1.0, 1.0):
        pinnacle(m, sd * 18.0, 0.0, 2.0, 139.0, 8.0)
        pinnacle(m, 0.0, sd * 18.0, 2.0, 139.0, 8.0)
        if LOD == 0:
            for t in (-9.0, 9.0):
                pinnacle(m, sd * 18.6, t, 1.4, 139.0, 5.5)
                pinnacle(m, t, sd * 18.6, 1.4, 139.0, 5.5)

    # 8. Over the shaft (photos 2026-11-13: the arcade stands UNDER the clocks, not over them): a
    # stepped plinth (139-143 m), the 17 m square tier in two parts, panelled stone to 157 m and
    # an arcade of five round-headed openings per face to 168 m (the OSM part's top), then a
    # cornice, attic and pinnacles.
    m.prism(Model.rect(0, 0, 12.5, 12.5), 139.0, 143.0, M_STONE, stone, M_STONE, ROOF)
    attic(m, Model.rect(0, 0, 12.5, 12.5), 143.0, 1.6)
    if LOD == 0:
        for k in range(4):
            pinnacle(m, -11.8 if k % 2 == 0 else 11.8, -11.8 if k < 2 else 11.8, 1.2, 143.0, 4.5)
    m.walls(Model.rect(0, 0, 8.5, 8.5), 143.0, 156.4, M_MONUMENT, stone)
    m.walls(Model.rect(0, 0, 8.85, 8.85), 156.4, 157.2, M_STONE, light)
    m.cap_ring_band(Model.rect(0, 0, 8.5, 8.5), Model.rect(0, 0, 8.85, 8.85), 157.2, light, up=True)
    for nu, nv in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        arch_face(m, 0.0, 0.0, nu, nv, 8.5, 157.2, 167.0, 5, 1.7, 158.6, 165.8, stone)
    cornice(m, Model.rect(0, 0, 8.5, 8.5), 168.0, depth=0.6, height=1.0, steps=2 if LOD == 0 else 1)
    m.cap(Model.rect(0, 0, 8.5, 8.5), 168.0, M_STONE, ROOF)
    attic(m, Model.rect(0, 0, 8.8, 8.8), 168.0, 2.0)
    for k in range(4):
        pinnacle(m, -7.6 if k % 2 == 0 else 7.6, -7.6 if k < 2 else 7.6, 1.6, 168.0, 7.5)
    if LOD == 0:
        for sd in (-1.0, 1.0):
            for t in (-3.8, 3.8):
                pinnacle(m, sd * 8.3, t, 0.9, 168.0, 4.0)
                pinnacle(m, t, sd * 8.3, 0.9, 168.0, 4.0)

    # 9. The clock tier (168-188 m, the OSM part to 204 m): plain stone on the 12.6 m square, the
    # dials (landmarks.gd `_dial`, so the hands keep Warsaw time) at 178 m, a cornice, an attic.
    m.walls(Model.rect(0, 0, 6.3, 6.3), 168.0, 187.2, M_STONE, stone)
    if LOD == 0:
        for k in range(4):
            cu = -6.3 if k % 2 == 0 else 6.3
            cv = -6.3 if k < 2 else 6.3
            m.box(cu, cv, 0.7, 0.7, 168.0, 187.2, light)
    cornice(m, Model.rect(0, 0, 6.3, 6.3), 188.0, depth=0.5, height=0.8, steps=2 if LOD == 0 else 1)
    m.cap(Model.rect(0, 0, 6.3, 6.3), 188.0, M_STONE, ROOF)
    attic(m, Model.rect(0, 0, 6.6, 6.6), 188.0, 1.2)
    if LOD == 0:
        for k in range(4):
            pinnacle(m, -6.0 if k % 2 == 0 else 6.0, -6.0 if k < 2 else 6.0, 0.9, 188.0, 3.5)

    # 10. The crown: a low flared patina cap, then the spire's bronze foot with an orb and the gold
    # spire with three rings and a small orb near the tip, to 237 m.
    n8 = 8
    t8 = math.pi / 8
    m.frustum(Model.ngon(0, 0, 6.2, n8, t8), 188.0, Model.ngon(0, 0, 4.0, n8, t8), 191.5, M_STONE, PATINA)
    m.frustum(Model.ngon(0, 0, 4.0, n8, t8), 191.5, Model.ngon(0, 0, 2.2, n8, t8), 198.0, M_STONE, PATINA,
              top_col=PATINA)
    m.walls(Model.ngon(0, 0, 1.6, n8, t8), 198.0, 205.0, M_STONE, BRONZE)
    orb_n = 10 if LOD == 0 else 6
    rings = [(205.0, 1.9), (205.6, 2.3), (206.5, 2.5), (207.4, 2.3), (208.0, 1.7)]
    for (z0, r0), (z1, r1) in zip(rings, rings[1:]):
        m.frustum(Model.ngon(0, 0, r0, orb_n), z0, Model.ngon(0, 0, r1, orb_n), z1, M_STONE, BRONZE, smooth=True)
    m.frustum(Model.ngon(0, 0, 1.7, n8, t8), 208.0, Model.ngon(0, 0, 0.95, n8, t8), 222.0, M_GOLD, GOLD)
    m.frustum(Model.ngon(0, 0, 0.95, n8, t8), 222.0, Model.ngon(0, 0, 0.3, n8, t8), 233.0, M_GOLD, GOLD)
    m.cone(Model.ngon(0, 0, 0.3, n8, t8), 233.0, (0, 0, 237.0), M_GOLD, GOLD)
    for z, r in ((211.0, 1.85), (214.5, 1.6), (225.0, 1.05)):
        m.frustum(Model.ngon(0, 0, r, n8, t8), z, Model.ngon(0, 0, r, n8, t8), z + 0.8, M_GOLD, GOLD,
                  top_col=GOLD)
    if LOD == 0:
        orb = Model.ngon(0, 0, 0.55, 6)
        m.frustum(Model.ngon(0, 0, 0.3, 6), 230.0, orb, 230.5, M_GOLD, GOLD, smooth=True)
        m.frustum(orb, 230.5, Model.ngon(0, 0, 0.3, 6), 231.1, M_GOLD, GOLD, smooth=True)


# --- into Blender ------------------------------------------------------------------------------
def to_blender(m, name):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bv = [bm.verts.new((p.x, -p.y, p.z)) for p in m.verts]
    uv_wall = bm.loops.layers.uv.new("wall")
    uv_top = bm.loops.layers.uv.new("top")
    mats = sorted(m.mats, key=lambda k: m.mats[k])
    for key in mats:
        mat = bpy.data.materials.get(key) or bpy.data.materials.new(key)
        col = key.split("_")[1]
        mat.diffuse_color = tuple(int(col[i:i + 2], 16) / 255.0 for i in (0, 2, 4)) + (1.0,)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = mat.diffuse_color
            bsdf.inputs["Roughness"].default_value = 0.85
        me.materials.append(mat)
    skipped = 0
    for idx, key, smooth, _uv, top in m.faces:
        try:
            f = bm.faces.new([bv[i] for i in idx])
        except ValueError:
            skipped += 1
            continue
        f.material_index = m.mats[key]
        f.smooth = smooth
        pts = [m.verts[i] for i in idx]
        n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
        if n.length > 1e-9:
            n.normalize()
        zmax = max(p.z for p in pts) if top is None else top
        wall = abs(n.z) < 0.3 and n.length > 0.5
        if wall:
            t = Vector((-n.y, n.x, 0.0))
            t.normalize()
        for loop, p in zip(f.loops, pts):
            if wall:
                loop[uv_wall].uv = (1000.0 + p.x * t.x + p.y * t.y, p.z)
            else:
                loop[uv_wall].uv = (-1.0, -1.0)
            loop[uv_top].uv = (0.0, zmax)
    # Weld coincident corners within a face set so smooth parts shade round, then normals out.
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    if skipped:
        print("pkin: %d faces skipped (duplicates)" % skipped)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def render_preview(ob, outdir):
    """Small Workbench renders from the four quarters and the top, for a quick look."""
    os.makedirs(outdir, exist_ok=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1200, 1500
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 50
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    sc.camera = cam
    target = Vector((0, 0, 95))
    for name, ang, el, dist in (("ne", 30, 12, 520), ("se", -60, 12, 520), ("sw", 210, 12, 520),
                                ("top", 30, 70, 600), ("crown", 30, 8, 150)):
        a = math.radians(ang)
        e = math.radians(el)
        tgt = Vector((0, 0, 200)) if name == "crown" else target
        cam.location = tgt + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * dist
        cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(outdir, "pkin_lod%d_%s.png" % (LOD, name))
        bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m = Model()
    build(m)
    ob = to_blender(m, "pkin_lod%d" % LOD)
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    print("pkin: LOD %d, %d triangles, %d materials" % (LOD, tris, len(ob.data.materials)))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_texcoords=True,
                              export_normals=True, export_materials="EXPORT", export_yup=True,
                              export_apply=True)
    print("pkin: wrote", OUT)
    if "blend" in OPT:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(OPT["blend"]))
    if "render" in OPT:
        render_preview(ob, OPT["render"])


main()
