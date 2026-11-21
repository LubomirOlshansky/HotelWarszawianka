"""Bake the surface map for v0.9's water and wet streets: one RGBA texel per 2 m over the map.

Usage: python3 -I tools/bake_water.py game/map

Reads  game/map/centrum.json (water areas, fountains, plazas, paving, footways, roads,
       carriageway areas, bridge decks), game/map/terrain.json (the ground under decks)
Writes game/map/water.bin: uint32 width, uint32 height, float32 x0, z0, metres per pixel,
       then width*height RGBA bytes:
  R  distance to the shore inside water, 4 per metre (255 = 64 m or more; 0 off the
     water): the river's depth colour and the shore foam (ground.gdshader)
  G  the way the water flows, an angle: 128 = north, +-127 = +-180 degrees (east is
     positive); only where B says river
  B  what the top surface is: 0 nothing that reflects (grass, buildings, rails),
     64 paving (plazas, footways, paved squares), 128 road (strips, carriageway areas,
     bridge decks), 192 still water (ponds, fountains), 255 the river (flowing):
     post.gdshader's reflections and the wet sheen use it
  A  the height of a bridge deck over this point, (y + 32) * 4 (0 = no deck): the
     ground and water under a deck get no lamp pools (the lamps stand on the deck)

The river flows north. Its direction per row of the map comes from the middle of the
main river body in that row, smoothed along the river, so the flow turns with the
banks; ponds and fountains (water bodies under 20,000 m2) are still. Map-edge water
doesn't count as shore (the river runs off the map).
"""
import json
import math
import os
import struct
import sys

PX = 2.0
RIVER_AREA = 20000.0
NONE, PAVING, ROAD, STILL, RIVER = 0, 64, 128, 192, 255
# Fountains that are a water mirror on flush granite (a point inside each ring): they reflect like
# still water but are no water to drive into. The same list as map_builder.gd's DRY_FOUNTAINS.
DRY_FOUNTAINS = [(515.0, -660.5)]


def inside(pt, poly):
    """Whether point pt lies inside polygon poly (even-odd rule)."""
    x, z = pt
    hit = False
    j = len(poly) - 1
    for i in range(len(poly)):
        (xi, zi), (xj, zj) = poly[i], poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            hit = not hit
        j = i
    return hit


def ring(flat):
    return list(zip(flat[0::2], flat[1::2]))


def area(poly):
    s = 0.0
    for (ax, az), (bx, bz) in zip(poly, poly[1:] + poly[:1]):
        s += ax * bz - bx * az
    return abs(s) * 0.5


class Grid:
    def __init__(self, x0, z0, w, h):
        self.x0, self.z0, self.w, self.h = x0, z0, w, h

    def fill(self, buf, poly, value, mode="set"):
        """Scanline fill (even-odd) of a polygon, at pixel centres."""
        if len(poly) < 3:
            return
        zs = [p[1] for p in poly]
        j0 = max(0, int((min(zs) - self.z0) / PX))
        j1 = min(self.h - 1, int((max(zs) - self.z0) / PX) + 1)
        n = len(poly)
        for j in range(j0, j1 + 1):
            zc = self.z0 + (j + 0.5) * PX
            xs = []
            for k in range(n):
                ax, az = poly[k]
                bx, bz = poly[(k + 1) % n]
                if (az > zc) != (bz > zc):
                    xs.append(ax + (zc - az) * (bx - ax) / (bz - az))
            xs.sort()
            row = j * self.w
            for a, b in zip(xs[0::2], xs[1::2]):
                i0 = max(0, int(math.ceil((a - self.x0) / PX - 0.5)))
                i1 = min(self.w - 1, int(math.floor((b - self.x0) / PX - 0.5)))
                for i in range(i0, i1 + 1):
                    if mode == "max":
                        buf[row + i] = max(buf[row + i], value)
                    else:
                        buf[row + i] = value

    def strip(self, buf, pts, half, value, shift=0.0, heights=None):
        """A polyline `half` metres either side (its line moved `shift` to the right);
        with `heights` (one per point), writes the interpolated height (max) instead."""
        for k in range(len(pts) - 1):
            (ax, az), (bx, bz) = pts[k], pts[k + 1]
            length = math.hypot(bx - ax, bz - az)
            if length < 0.01:
                continue
            dx, dz = (bx - ax) / length, (bz - az) / length
            rx, rz = -dz, dx
            ax, az, bx, bz = ax + rx * shift, az + rz * shift, bx + rx * shift, bz + rz * shift
            lo_x = min(ax, bx) - half - PX
            hi_x = max(ax, bx) + half + PX
            lo_z = min(az, bz) - half - PX
            hi_z = max(az, bz) + half + PX
            i0 = max(0, int((lo_x - self.x0) / PX))
            i1 = min(self.w - 1, int((hi_x - self.x0) / PX))
            j0 = max(0, int((lo_z - self.z0) / PX))
            j1 = min(self.h - 1, int((hi_z - self.z0) / PX))
            for j in range(j0, j1 + 1):
                zc = self.z0 + (j + 0.5) * PX
                row = j * self.w
                for i in range(i0, i1 + 1):
                    xc = self.x0 + (i + 0.5) * PX
                    t = ((xc - ax) * dx + (zc - az) * dz) / length
                    if t < -0.02 or t > 1.02:
                        continue
                    across = abs((xc - ax) * rx + (zc - az) * rz)
                    if across > half:
                        continue
                    if heights is None:
                        buf[row + i] = value
                    else:
                        y = heights[k] + (heights[k + 1] - heights[k]) * min(1.0, max(0.0, t))
                        code = max(1, min(255, int(round((y + 32.0) * 4.0))))
                        buf[row + i] = max(buf[row + i], code)


def distance(water, w, h):
    """Chamfer distance (metres) from each water pixel to the nearest dry one; pixels
    beyond the map's edge count as water."""
    inf = 1e9
    d = [inf if water[k] else 0.0 for k in range(w * h)]
    a, b = PX, PX * math.sqrt(2.0)
    for j in range(h):
        row = j * w
        for i in range(w):
            k = row + i
            v = d[k]
            if v == 0.0:
                continue
            if i > 0:
                v = min(v, d[k - 1] + a)
            if j > 0:
                v = min(v, d[k - w] + a)
                if i > 0:
                    v = min(v, d[k - w - 1] + b)
                if i < w - 1:
                    v = min(v, d[k - w + 1] + b)
            d[k] = v
    for j in range(h - 1, -1, -1):
        row = j * w
        for i in range(w - 1, -1, -1):
            k = row + i
            v = d[k]
            if v == 0.0:
                continue
            if i < w - 1:
                v = min(v, d[k + 1] + a)
            if j < h - 1:
                v = min(v, d[k + w] + a)
                if i < w - 1:
                    v = min(v, d[k + w + 1] + b)
                if i > 0:
                    v = min(v, d[k + w - 1] + b)
            d[k] = v
    return d


def main(map_dir):
    data = json.load(open(os.path.join(map_dir, "centrum.json")))
    x0, z0, x1, z1 = data["bounds"]
    w = int(math.ceil((x1 - x0) / PX))
    h = int(math.ceil((z1 - z0) / PX))
    g = Grid(x0, z0, w, h)
    kind = bytearray(w * h)
    deck = bytearray(w * h)

    # What reflects: paving, then roads over it, then water over everything.
    for a in data["areas"]:
        if a["k"] == "plaza":
            g.fill(kind, ring(a["p"]), PAVING)
    for s in data.get("surfaces", []):
        if s["k"] in ("paving", "granite"):
            g.fill(kind, ring(s["p"]), PAVING)
    for p in data["paths"]:
        if p["k"] in ("foot", "cycle"):
            g.strip(kind, ring(p["p"]), float(p["w"]) * 0.5, PAVING)
    for r in data["roads"]:
        g.strip(kind, ring(r["p"]), float(r["w"]) * 0.5, ROAD, float(r.get("c", 0.0)))
    for c in data.get("carriage", []):
        g.fill(kind, ring(c["p"]), ROAD)
    water = bytearray(w * h)
    river = bytearray(w * h)
    for a in data["areas"]:
        if a["k"] != "water":
            continue
        poly = ring(a["p"])
        flowing = area(poly) >= RIVER_AREA
        g.fill(water, poly, 1)
        g.fill(kind, poly, RIVER if flowing else STILL)
        if flowing:
            g.fill(river, poly, 1)
    for s in data.get("surfaces", []):
        if s["k"] == "fountain":
            poly = ring(s["p"])
            if any(inside(q, poly) for q in DRY_FOUNTAINS):
                g.fill(kind, poly, STILL)  # a water mirror: it reflects, but it is dry ground
                continue
            g.fill(water, poly, 1)
            g.fill(kind, poly, STILL)
    # Bridge decks: their top is a road or a footway; the height goes into A.
    for piece in data.get("decks", {}).get("pieces", []):
        pts = ring(piece["p"])
        half = (float(piece["l"]) + float(piece["r"])) * 0.5 + 0.2
        shift = (float(piece["r"]) - float(piece["l"])) * 0.5
        g.strip(deck, pts, half, 0, shift, piece["h"])
        if piece["k"] in ("road", "path"):
            g.strip(kind, pts, half, ROAD if piece["k"] == "road" else PAVING, shift)

    dist = distance(water, w, h)
    shore = bytearray(min(255, int(round(dist[k] * 4.0))) if water[k] else 0 for k in range(w * h))

    # The river's direction: the middle of the river in each row, smoothed along z.
    mids = []
    for j in range(h):
        row = j * w
        xs = [i for i in range(w) if river[row + i]]
        mids.append(sum(xs) / len(xs) * PX + x0 if xs else None)
    known = [(j, m) for j, m in enumerate(mids) if m is not None]
    smooth = [None] * h
    reach = int(120.0 / PX)
    for j, _ in known:
        near = [m for jj, m in known if abs(jj - j) <= reach]
        smooth[j] = sum(near) / len(near)
    flow = bytearray(w * h)
    for j in range(h):
        if smooth[j] is None:
            continue
        a = smooth[max(0, j - 10)] if smooth[max(0, j - 10)] is not None else smooth[j]
        b = smooth[min(h - 1, j + 10)] if smooth[min(h - 1, j + 10)] is not None else smooth[j]
        # Northwards (towards -z): from row j+10 to row j-10.
        fx = a - b
        fz = -20.0 * PX
        ang = math.atan2(fx, -fz)                 # 0 = north, + = east
        code = max(1, min(255, int(round(128 + ang / math.pi * 127))))
        row = j * w
        for i in range(w):
            if river[row + i]:
                flow[row + i] = code

    out = bytearray(w * h * 4)
    out[0::4] = shore
    out[1::4] = flow
    out[2::4] = kind
    out[3::4] = deck
    path = os.path.join(map_dir, "water.bin")
    with open(path, "wb") as f:
        f.write(struct.pack("<IIfff", w, h, x0, z0, PX))
        f.write(bytes(out))
    counts = {}
    for v in kind:
        counts[v] = counts.get(v, 0) + 1
    deep = max(dist[k] for k in range(w * h) if water[k]) if any(water) else 0
    angles = sorted(set(flow) - {0})
    print("%s: %dx%d at %.0f m, water %d px (deepest %.0f m from a shore), river flow %.0f..%.0f degrees, "
          "paving %d, road %d, still water %d, river %d, under decks %d px" % (
              path, w, h, PX, sum(water), deep,
              (angles[0] - 128) / 127 * 180 if angles else 0, (angles[-1] - 128) / 127 * 180 if angles else 0,
              counts.get(PAVING, 0), counts.get(ROAD, 0), counts.get(STILL, 0), counts.get(RIVER, 0),
              sum(1 for v in deck if v)))


if __name__ == "__main__":
    main(sys.argv[1])
