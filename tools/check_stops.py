"""Checks the bus stops, benches and cafe chairs of the baked map (G8, G9; tools/snap_props.py).

    python3 -I tools/check_stops.py

Fails (exit 1) when
  K1  a shelter beside a bus road (SNAP_MAX of its kerb lane's edge, not a tram stop) is not on the
      kerb: more than KERB_TRIES[-1] + 0.15 m past the kerb lane's edge (so its roof's front edge is
      within 1.5 m of the kerb), except LEFT_MAX that have no clear spot;
  K2  such a shelter does not face the road (its -z side, the way the glass back is turned from it);
  K3  a shelter or bench stands in a lane, a building, the water or a carriageway polygon;
  K4  a bench does not face the nearest footway or path (within 0.3 rad), BENCH_LEFT_MAX excepted;
  K5  a cafe set (game/data/street_details.json) is not against a shopfront on paving: not CAFE_FRONT
      from a building outline, or in a park or on a lawn;
  K6  the stops' paint (tools/bus_stops.py) is missing or out of place: the map's `stopzz` and
      `stopkerb` markings differ from what bus_stops.py makes of it now (re-run it), a zigzag point
      is outside the lanes or on a zebra's, cycle crossing's or stop line's reach, a yellow kerb line
      point is in a lane, or fewer than ZZ_MIN_COUNT zigzags are on the map.
Prints `check_stops: OK` and the counts. Standard library only.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import snap_props as S  # noqa: E402
import bake_street_details as B  # noqa: E402
import bus_stops as BS  # noqa: E402

LEFT_MAX = 25
BENCH_LEFT_MAX = 80
BENCH_TOL = 0.3
ZZ_MIN_COUNT = 150   # 167 on 2026-11-07


def main():
    with open(S.MAP, encoding="utf-8") as f:
        d = json.load(f)
    w = S.World(d)
    bad = []
    sh = d["shelters"]
    n_stop = n_left = n_tram = 0
    for i in range(0, len(sh) - 2, 3):
        x, z, yaw = sh[i], sh[i + 1], sh[i + 2]
        hit = w.bus_stop_edge(x, z)
        if hit is not None and not w.tram_near(x, z):
            info, k, foot, t, r, lat, out = hit
            n_stop += 1
            if out > S.KERB_TRIES[-1] + 0.15:
                n_left += 1
            want = math.atan2(r[0], r[1])
            if abs(math.remainder(yaw - want, 2 * math.pi)) > 0.2:
                bad.append("K2 shelter at %.1f, %.1f does not face its road (yaw %.2f, want %.2f)" % (x, z, yaw, want))
        elif hit is not None:
            n_tram += 1
        if hit is None or w.tram_near(x, z):
            continue
        c, s = math.cos(yaw), math.sin(yaw)
        for u in (-S.HALF_ROOF + 0.15, 0.0, S.HALF_ROOF - 0.15):
            for wd in (-S.FRONT + 0.15, 0.0, S.BACK):
                px, pz = x + c * u + s * wd, z - s * u + c * wd
                if w.polys.inside(px, pz, skip=("platforms", "islands")) or w.in_lane(px, pz, 0.0):
                    bad.append("K3 shelter at %.1f, %.1f stands in %s" % (x, z, w.polys.inside(px, pz) or "a lane"))
                    break
            else:
                continue
            break
    if n_left > LEFT_MAX:
        bad.append("K1 %d bus-road shelters are not on the kerb (at most %d without a clear spot)" % (n_left, LEFT_MAX))
    bn = d["benches"]
    n_bench = n_blind = 0
    for i in range(0, len(bn) - 2, 3):
        x, z, yaw = bn[i], bn[i + 1], bn[i + 2]
        n_bench += 1
        if w.polys.inside(x, z) in ("building", "water", "carriageway"):
            bad.append("K3 bench at %.1f, %.1f stands in %s" % (x, z, w.polys.inside(x, z)))
            continue
        best = None
        for a, b, wd in w.paths.near(x, z):
            dd = S.P.seg_dist(x, z, a, b)
            if dd <= 25.0 and (best is None or dd < best[0]):
                dx, dz = b[0] - a[0], b[1] - a[1]
                ln = dx * dx + dz * dz
                u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
                best = (dd, a[0] + dx * u - x, a[1] + dz * u - z)
        if best is None or best[0] < 0.1:
            n_blind += 1
            continue
        want = math.atan2(-best[1], -best[2])
        if abs(math.remainder(yaw - want, 2 * math.pi)) > BENCH_TOL:
            n_blind += 1
    if n_blind > BENCH_LEFT_MAX + 0:
        bad.append("K4 %d benches do not face the walk (at most %d)" % (n_blind, BENCH_LEFT_MAX))
    with open(B.OUT, encoding="utf-8") as f:
        doc = json.load(f)
    pl = B.Placer(d)
    n_cafe = 0
    for kind, x, z, yaw, colour in doc["items"]:
        if kind != "cafe":
            continue
        n_cafe += 1
        gap = pl.solids.segs.dist(x, z, "building")
        if pl.green.inside(x, z) or not (B.CAFE_FRONT[0] - 0.2 <= gap <= B.CAFE_FRONT[1] + 0.2):
            bad.append("K5 cafe set at %.1f, %.1f is not on paving against a shopfront" % (x, z))
    n_zz, n_kb = stop_paint(d, w, bad)
    print("check_stops counts: %d bus-road shelters (%d without a clear spot, %d tram stops skipped), %d benches "
          "(%d not facing a walk), %d cafe sets, %d stop zigzags, %d yellow kerb lines"
          % (n_stop, n_left, n_tram, n_bench, n_blind, n_cafe, n_zz, n_kb))
    for b in bad[:30]:
        print("check_stops: FAIL " + b)
    if bad:
        print("check_stops: %d problems" % len(bad))
        return 1
    print("check_stops: OK")
    return 0


def stop_paint(d, w, bad):
    """K6: the stops' zigzags and kerb lines; returns their counts."""
    have = [m for m in d["markings"] if m["k"] in BS.KINDS]
    fresh = {"markings": [m for m in d["markings"] if m["k"] not in BS.KINDS]}
    fresh.update({k: v for k, v in d.items() if k != "markings"})
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        BS.apply(fresh)
    want = [m for m in fresh["markings"] if m["k"] in BS.KINDS]
    if sorted(json.dumps(m, sort_keys=True) for m in have) != sorted(json.dumps(m, sort_keys=True) for m in want):
        bad.append("K6 the stops' paint is stale (%d markings, bus_stops.py makes %d): python3 -I tools/bus_stops.py"
                   % (len(have), len(want)))
    blocks = BS.Blocks(d)
    n_zz = n_kb = 0
    for m in have:
        pts = list(zip(m["p"][0::2], m["p"][1::2]))
        if m["k"] == "stopzz":
            n_zz += 1
            for x, z in pts:
                if not w.in_lane(x, z, 0.05):
                    bad.append("K6 a stop zigzag's point at %.1f, %.1f is outside the lanes" % (x, z))
                    break
                if blocks.hit(x, z) and blocks.segs.near(x, z, -BS.END_GAP + 0.3) is not None:
                    bad.append("K6 a stop zigzag's point at %.1f, %.1f is on a crossing or stop line" % (x, z))
                    break
        else:
            n_kb += 1
            for x, z in pts:
                if w.in_lane(x, z, 0.0):
                    bad.append("K6 a yellow kerb line's point at %.1f, %.1f is in a lane" % (x, z))
                    break
    if n_zz < ZZ_MIN_COUNT:
        bad.append("K6 only %d stop zigzags (at least %d)" % (n_zz, ZZ_MIN_COUNT))
    return n_zz, n_kb


if __name__ == "__main__":
    sys.exit(main())
