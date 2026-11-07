"""The bus stops' paint: the white stop zigzag (P-17) in the kerb lane and the yellow line on the kerb.

    python3 -I tools/bus_stops.py [MAP.json] [--dry]       (rewrites the map in place, idempotent)

Street photos at our own stops (Mapillary 2021-2026, 22 of the 208 bus-road shelters; the "buses and
bus stops" thread, 2026-11-07) show the same two things at nearly every Warsaw bus stop on a
carriageway, and the map had neither:

- **P-17, the stop zigzag**: a white zigzag in the kerb lane where the bus stands and nobody else may
  stop (30-60 m by the regulation). Here ZZ_BACK m behind the shelter to ZZ_AHEAD m past it (the bus
  stops with its front 6 m past the shelter: buses.gd `stop_from`), cut short of a zebra, a cycle
  crossing or a stop line in the lane and of the edge's ends (the junctions), and left out when less
  than ZZ_MIN m is left. Its legs run ZZ_LEG m along the lane, from ZZ_IN m off the kerb to ZZ_OUT m
  (the lane's width less a margin), and it starts and ends on the kerb. Two stops on one edge whose
  runs overlap share one zigzag. A marking of kind `stopzz` (map_builder.gd STOPZZ_W: a 0.22 m line).
- **The yellow kerb line**: the platform's edge on the footway, a yellow line KERB_IN m in from the
  kerb along the bus's length (KB_BACK behind the shelter to KB_AHEAD past it), only where the shelter
  stands on the kerb (snap_props.py moved it there: out <= KB_OUT), cut where the footway ends (a
  lane or a carriageway, building or water outline under it). A marking of kind `stopkerb`, laid
  at the footway's height (map_builder.gd).

Tram stops (a track within snap_props TRAM_NEAR) and edges on decks or in tunnels are left out (the
same as snap_props.py and buses.gd). Runs on the finished map data: bake_osm.py calls `apply(out)`
after snap_props; this file is also a command line tool for a map that is already baked (the cloud
has no OpenStreetMap download). tools/check_stops.py K6 checks the result. Standard library only.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import snap_props as S  # noqa: E402
import bake_street_pois as P  # noqa: E402

MAP = S.MAP
KINDS = ("stopzz", "stopkerb")
ZZ_BACK = 22.0      # the zigzag starts this far behind the shelter (an 18 m bus and a margin)...
ZZ_AHEAD = 10.0     # ...and ends this far past it (the bus's front 6 m past, and a margin)
ZZ_MIN = 14.0       # a run cut shorter than this is left out
ZZ_LEG = 4.0        # each leg of the zigzag runs this far along the lane
ZZ_IN = 0.3         # the kerb side's points this far into the lane from its edge
ZZ_OUT = 2.1        # the far points this far in (at most the lane's width less ZZ_MARGIN)
ZZ_MARGIN = 0.55
END_GAP = 1.5       # this far short of the edge's ends (junctions) and of a crossing's stripes
STOPLINE_GAP = 2.0  # this far short of a stop line in the lane
KB_BACK = 14.0      # the yellow kerb line from this far behind the shelter...
KB_AHEAD = 7.0      # ...to this far past it
KB_OUT = 3.4        # only for a shelter whose middle is at most this far past the kerb lane's edge
KERB_IN = 0.45      # the yellow line this far in from the kerb (the kerb stone's width and a bit)
KB_MIN = 6.0        # a kerb line cut shorter than this is left out
STEP = 0.5


def point_at(info, s, lat):
    """The point `lat` m right of edge `info`'s line at distance `s` along it, and its tangent."""
    p, cum = info["p"], info["cum"]
    s = max(0.0, min(cum[-1], s))
    k = 0
    while k < len(p) - 2 and cum[k + 1] < s:
        k += 1
    a, b = p[k], p[k + 1]
    ln = (cum[k + 1] - cum[k]) or 1.0
    u = (s - cum[k]) / ln
    t = ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)
    r = (-t[1], t[0])
    return (a[0] + (b[0] - a[0]) * u + r[0] * lat, a[1] + (b[1] - a[1]) * u + r[1] * lat), t


class Blocks:
    """Zebras, cycle crossings and stop lines: what a stop's zigzag must stop short of."""

    def __init__(self, d):
        self.segs = P.Segs()
        for pa in d.get("paths", []):
            if pa["k"] in ("zebra", "cyclecross"):
                half = float(pa.get("w", 3.6)) * 0.5 if pa["k"] == "zebra" else 1.0
                self.segs.add_line(P.pairs(pa["p"]), half + END_GAP, pa["k"])
        for m in d.get("markings", []):
            if m["k"] == "stop":
                self.segs.add_line(P.pairs(m["p"]), 0.25 + STOPLINE_GAP, "stop line")

    def hit(self, x, z):
        return self.segs.near(x, z, 0.0) is not None


def runs(d, w):
    """[(info, s_from, s_to, kerb_line)] per bus-road shelter, merged per edge."""
    blocks = Blocks(d)
    per_edge = {}
    sh = d.get("shelters", [])
    for i in range(0, len(sh) - 2, 3):
        x, z = sh[i], sh[i + 1]
        hit = w.bus_stop_edge(x, z)
        if hit is None or w.tram_near(x, z):
            continue
        info, k, foot, t, r, lat, out = hit
        s_sh = info["cum"][k] + math.hypot(foot[0] - info["p"][k][0], foot[1] - info["p"][k][1])
        lo = max(info["s0"], 0.0) + END_GAP
        hi = min(info["s1"], info["cum"][-1]) - END_GAP
        if hi - lo < ZZ_MIN or not lo <= s_sh <= hi:
            continue
        lane_mid = info["right"] - info["lw"] * 0.5
        # Walk out from the shelter both ways until a crossing or a stop line in the kerb lane.
        a = b = s_sh
        while a - STEP >= max(lo, s_sh - ZZ_BACK):
            q, _ = point_at(info, a - STEP, lane_mid)
            if blocks.hit(q[0], q[1]):
                break
            a -= STEP
        while b + STEP <= min(hi, s_sh + ZZ_AHEAD):
            q, _ = point_at(info, b + STEP, lane_mid)
            if blocks.hit(q[0], q[1]):
                break
            b += STEP
        kerb = None
        if out <= KB_OUT:
            # Walk out along the kerb until it leaves the footway (a side street's mouth, a lane).
            def on_foot(s):
                q, _ = point_at(info, s, info["right"] + KERB_IN)
                return not w.in_lane(q[0], q[1], 0.15) and w.polys.inside(q[0], q[1], skip=("platforms", "islands")) is None
            ka = kb = s_sh
            if on_foot(s_sh):
                while ka - STEP >= max(lo, s_sh - KB_BACK) and on_foot(ka - STEP):
                    ka -= STEP
                while kb + STEP <= min(hi, s_sh + KB_AHEAD) and on_foot(kb + STEP):
                    kb += STEP
            kerb = (ka, kb) if kb - ka >= KB_MIN else None
        per_edge.setdefault(info["i"], (info, []))[1].append((a, b, kerb))
    out_runs = []
    for info, rs in per_edge.values():
        rs.sort()
        merged = []
        for a, b, kerb in rs:
            if merged and a <= merged[-1][1] + ZZ_LEG:
                pa, pb, pk = merged[-1]
                ks = [k for k in (pk, kerb) if k]
                merged[-1] = (pa, max(pb, b), ks)
            else:
                merged.append((a, b, [kerb] if kerb else []))
        for a, b, kerbs in merged:
            out_runs.append((info, a, b, kerbs))
    return out_runs


def zigzag(info, a, b):
    """The zigzag's points from s = a to s = b: on the kerb at both ends, legs of about ZZ_LEG."""
    legs = max(2, int(round((b - a) / ZZ_LEG)))
    if legs % 2:
        legs += 1   # an even count: the last point is on the kerb side again
    reach = min(ZZ_OUT, info["lw"] - ZZ_MARGIN)
    pts = []
    for j in range(legs + 1):
        s = a + (b - a) * j / legs
        lat = info["right"] - (ZZ_IN if j % 2 == 0 else reach)
        q, _ = point_at(info, s, lat)
        pts += [round(q[0], 2), round(q[1], 2)]
    return pts


def kerb_line(info, a, b):
    pts = []
    n = max(1, int(math.ceil((b - a) / 5.0)))
    for j in range(n + 1):
        q, _ = point_at(info, a + (b - a) * j / n, info["right"] + KERB_IN)
        pts += [round(q[0], 2), round(q[1], 2)]
    return pts


def apply(d):
    """bake_osm.py: the stops' zigzags and kerb lines on the finished map data `d`; prints one line."""
    d["markings"] = [m for m in d.get("markings", []) if m["k"] not in KINDS]
    w = S.World(d)
    n_zz = n_kb = 0
    total = 0.0
    for info, a, b, kerbs in runs(d, w):
        if b - a >= ZZ_MIN:
            d["markings"].append({"k": "stopzz", "p": zigzag(info, a, b)})
            n_zz += 1
            total += b - a
        for ka, kb in kerbs:
            if kb - ka >= KB_MIN:
                d["markings"].append({"k": "stopkerb", "p": kerb_line(info, ka, kb)})
                n_kb += 1
    msg = f"bus stops: {n_zz} stop zigzags ({total:.0f} m), {n_kb} yellow kerb lines"
    print(msg)
    return msg


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else MAP
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    apply(d)
    if "--dry" in argv:
        return 0
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
