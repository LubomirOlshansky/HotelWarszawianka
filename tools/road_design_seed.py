"""road_design_seed.py: a first draft of a street's design spec, read from the map's OSM ribbons.

Designing a street by hand from the aerial photo is slow; most of what the spec needs is already in
the map: the ribbons of a street (one per OSM way, each with its width, lane count and direction),
the tram tracks between them and the zebras across them. This reads those and writes the street as
road_design.py wants it: one axis through the middle of the street, sections where the cross-section
changes (carriageways from the touching ribbons of one direction, a tram/island/none median between
them), the mid-block zebras. The draft is a start, not the answer: check it against the ortho
(road_design_plot.py flat --ortho) and fix the numbers by hand, as the `road-design` skill says.

Usage:
  python3 -I tools/road_design_seed.py --street "Aleje Jerozolimskie" --box x0,z0,x1,z1 [--id jz]
          [--map game/map/centrum.json] [--every 10] [--k secondary] [--axis '[[x,z],[x,z]]']
(--axis: use this axis, e.g. the tram tracks' middle, instead of the middle of the ribbons)
Prints the street's JSON (one line per section) to stdout.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import road_design as rd  # noqa: E402

LANE_MAX = 3.5      # m: a ribbon wider than lanes x this gets more lanes' worth of width left as is
TOUCH = 1.2         # m: two ribbons of one direction closer than this are one carriageway
MOVE = 0.8          # m: a kerb that moves more than this starts a new section


def opt(argv, name, default=None):
    if name in argv:
        i = argv.index(name)
        return argv[i + 1]
    return default


def pts_of(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def in_box(p, box):
    return box[0] <= p[0] <= box[2] and box[1] <= p[1] <= box[3]


def simplify(pts, tol):
    """Douglas-Peucker."""
    if len(pts) < 3:
        return pts
    a, b = pts[0], pts[-1]
    ab = rd.sub(b, a)
    L = math.hypot(*ab) or 1e-9
    best, bi = -1.0, 0
    for i in range(1, len(pts) - 1):
        d = abs(ab[0] * (pts[i][1] - a[1]) - ab[1] * (pts[i][0] - a[0])) / L
        if d > best:
            best, bi = d, i
    if best <= tol:
        return [a, b]
    return simplify(pts[:bi + 1], tol)[:-1] + simplify(pts[bi:], tol)


def axis_of(ribbons):
    """The middle of the street: the mid-point of its outer edges, every 10 m along its main direction."""
    allp = [q for r in ribbons for q in r["dense"]]
    cx = sum(q[0] for q in allp) / len(allp)
    cz = sum(q[1] for q in allp) / len(allp)
    sxx = sum((q[0] - cx) ** 2 for q in allp)
    szz = sum((q[1] - cz) ** 2 for q in allp)
    sxz = sum((q[0] - cx) * (q[1] - cz) for q in allp)
    ang = 0.5 * math.atan2(2 * sxz, sxx - szz)
    u = (math.cos(ang), math.sin(ang))
    n = rd.right_of(u)
    bins = {}
    for r in ribbons:
        half = r["w"] / 2.0
        for q in r["dense"]:
            t = rd.dot(rd.sub(q, (cx, cz)), u)
            o = rd.dot(rd.sub(q, (cx, cz)), n)
            b = bins.setdefault(int(math.floor(t / 10.0)), [1e9, -1e9, 0.0, 0])
            b[0] = min(b[0], o - half)
            b[1] = max(b[1], o + half)
            b[2] += t
            b[3] += 1
    out = []
    for k in sorted(bins):
        lo, hi, ts, cnt = bins[k]
        t = ts / cnt
        o = (lo + hi) / 2.0
        out.append(rd.add((cx, cz), rd.add(rd.mul(u, t), rd.mul(n, o))))
    # light smoothing, then keep only the corners that matter
    sm = [out[0]] + [rd.mul(rd.add(rd.add(out[i - 1], out[i + 1]), rd.mul(out[i], 2.0)), 0.25)
                     for i in range(1, len(out) - 1)] + [out[-1]]
    return [[round(p[0], 2), round(p[1], 2)] for p in simplify(sm, 0.6)]


def main(argv):
    name = opt(argv, "--street")
    box = [float(v) for v in opt(argv, "--box").split(",")]
    box = [min(box[0], box[2]), min(box[1], box[3]), max(box[0], box[2]), max(box[1], box[3])]
    sid = opt(argv, "--id", "street")
    every = float(opt(argv, "--every", "10"))
    m = json.load(open(opt(argv, "--map", rd.MAP), encoding="utf-8"))
    ribbons = []
    for r in m["roads"]:
        if r.get("name") != name:
            continue
        pts = [q for q in rd.dense(pts_of(r["p"]), 1.0) if in_box(q, box)]
        if len(pts) < 3:
            continue
        ribbons.append({"r": r, "dense": pts, "w": float(r.get("w", 6.0)), "lanes": int(r.get("lanes", 0) or 0),
                        "oneway": bool(r.get("oneway")), "k": r.get("k", "secondary")})
    if not ribbons:
        sys.exit("no ribbons named %s in the box" % name)
    axis = json.loads(opt(argv, "--axis")) if opt(argv, "--axis") else axis_of(ribbons)
    probe = rd.Street({"id": sid, "axis": axis, "sections": [{"s": 0, "cw": [{"l": -3, "r": 3, "lanes": [{"d": 1}]}]}]})
    # each ribbon's samples on the axis: (s, off, dir) with dir +1 along the axis
    for rb in ribbons:
        rows = []
        q = rb["dense"]
        for i in range(len(q) - 1):
            s, off = rd.project(probe, q[i])
            s2, _ = rd.project(probe, q[i + 1])
            if s is None or s2 is None:
                continue
            rows.append((s, off, 1 if s2 >= s else -1))
        rb["rows"] = rows
    trams = []
    for t in m.get("trams", []):
        for q in rd.dense(pts_of(t["p"]), 2.0):
            if in_box(q, box):
                s, off = rd.project(probe, q)
                if s is not None and abs(off) < 30:
                    trams.append((s, off))
    sections = []
    last = None
    s = 0.0
    while s <= probe.L:
        parts = []
        for rb in ribbons:
            near = [row for row in rb["rows"] if abs(row[0] - s) < every / 2.0]
            if not near:
                continue
            off = sum(row[1] for row in near) / len(near)
            d = 1 if sum(row[2] for row in near) >= 0 else -1
            if not rb["oneway"]:
                d = 0
            parts.append([off - rb["w"] / 2.0, off + rb["w"] / 2.0, d, rb["lanes"]])
        parts.sort()
        cws = []
        for p in parts:
            if cws and cws[-1][2] == p[2] and p[0] - cws[-1][1] < TOUCH:
                c = cws[-1]
                over = min(c[1], p[1]) - p[0]
                # one ribbon after the other (overlapping at the join): the lanes are the same lanes;
                # side by side: they add up
                c[3] = max(c[3], p[3]) if over > 0.5 * (p[1] - p[0]) else c[3] + p[3]
                c[1] = max(c[1], p[1])
            else:
                cws.append(list(p))
        if not cws:
            s += every
            continue
        meds = []
        for a, b in zip(cws, cws[1:]):
            tram = any(abs(ts - s) < every and a[1] - 1.0 < to < b[0] + 1.0 for ts, to in trams)
            meds.append("tram" if tram else ("island" if b[0] - a[1] > 1.5 else "none"))
        sig = ([(c[2], c[3]) for c in cws], meds)
        moved = last is not None and len(last[1]) == len(cws) and any(
            abs(x[0] - y[0]) > MOVE or abs(x[1] - y[1]) > MOVE for x, y in zip(last[1], cws))
        if last is None or last[0] != sig or moved:
            cw = []
            for c in cws:
                n = max(1, c[3] or round((c[1] - c[0]) / 3.2))
                d = c[2] or 1
                cw.append({"l": round(c[0], 1), "r": round(c[1], 1), "lanes": [{"d": d} for _ in range(n)]})
                if c[2] == 0:     # two-way ribbon: half each way
                    h = n // 2
                    cw[-1]["lanes"] = [{"d": -1} for _ in range(n - max(1, h))] + [{"d": 1} for _ in range(max(1, h))]
            sections.append({"s": round(s, 1), "med": meds, "cw": cw})
            last = (sig, [list(c) for c in cws])
        s += every
    # a blip (one step long, the same before and after) is a join between two ribbons, not a change
    i = 1
    while i < len(sections) - 1:
        a, b, c = sections[i - 1], sections[i], sections[i + 1]
        if c["s"] - b["s"] <= every + 0.1 and len(a["cw"]) == len(c["cw"]) and \
                [len(x["lanes"]) for x in a["cw"]] == [len(x["lanes"]) for x in c["cw"]]:
            del sections[i]
            continue
        i += 1
    crossings = []
    for p in m["paths"]:
        if p.get("k") != "zebra":
            continue
        q = pts_of(p["p"])
        if not any(in_box(x, box) for x in q):
            continue
        offs = [rd.project(probe, x) for x in q]
        offs = [o for o in offs if o[0] is not None and abs(o[1]) < 30]
        if len(offs) < 2:
            continue
        ss = [o[0] for o in offs]
        span = max(o[1] for o in offs) - min(o[1] for o in offs)
        # a zebra over one carriageway: across the axis (its offsets spread, its s does not)
        if span > 2.5 and max(ss) - min(ss) < span and 5 < sum(ss) / len(ss) < probe.L - 5:
            sm = sum(ss) / len(ss)
            for c in crossings:
                if abs(c["s"] - sm) < 5.0:
                    c["n"] += 1
                    break
            else:
                crossings.append({"s": round(sm, 1), "w": max(4.0, float(p.get("w", 4.0))), "n": 1})
    crossings.sort(key=lambda c: c["s"])
    k = opt(argv, "--k", ribbons[0]["k"])
    spec = {"id": sid, "name": name, "k": k, "axis": axis, "crossings": crossings, "sections": sections}
    print("{" + ", ".join('"%s": %s' % (key, json.dumps(spec[key], ensure_ascii=False))
                          for key in ("id", "name", "k", "axis", "crossings")) + ', "sections": [')
    print(",\n".join("  " + json.dumps(sec, ensure_ascii=False) for sec in sections))
    print("]}")
    print("seed: %s %.0f m, %d ribbons, %d sections, %d crossings" % (name, probe.L, len(ribbons), len(sections),
                                                                      len(crossings)), file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
