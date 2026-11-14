"""Lane drops tapered like real streets (F, 2026-11-14: "this connect from two lanes to one lane can
be smoother, like in real life"): where a street goes from two lanes to one (or any lane-sized width
change between two OpenStreetMap ways of one street), the asphalt edge, the kerb and the edge line
drift over a real-life taper instead of a step or a wedge of a few metres.

    python3 -I tools/lane_tapers.py [MAP.json] [--dry] [--list]
        rewrites the map in place (idempotent: a map already tapered is left alone);
        --dry measures and changes nothing; --list prints every abrupt join with its place.
    python3 -I tools/lane_tapers.py --check [MAP.json]
        exit 1 unless the map is tapered and at most CHECK_ABRUPT lane drops stay steeper than
        ABRUPT_RATIO (verify.sh step `tapers`; a ratchet: lower it, never raise it).

Why. tools/road_smooth.py tapers a join inside the NARROWER way only, over at most half of it,
and skips the join when that leaves under 4 m. OpenStreetMap splits a street into short pieces (at
every crossing, bus stop, bridge end), each with its own lane count, so after a short piece the
taper was squeezed into a few metres (the wedge in F's crop at the top of Nowy Zjazd, a 6 m piece)
or skipped (a hard step); and even where there was room it ran 20-30 m along a smoothstep, about
1:8 in its middle. The 2026-11-14 census of main: of 477 lane-sized joins away from junctions,
111 were abrupt (32 steps, 79 squeezed to 1:2-1:5) and 122 more 1:5-1:10; after this pass 26.

Real streets (docs/design/lane-drops.md): a lane is closed or opened along a taper. At city speed
(50 km/h) the edge moves about 1 m sideways every 15 m (the US formula L = W S^2 / 60 gives 1:15 at
30 mph; Polish practice is close: a P-6 warning line, P-9 arrows, a P-21 hatched wedge over 40-60
m); a small street does it in about 1:10.

What, on the finished map data (bake_osm.py calls `apply(out)` after road_fixes; it also runs on a
baked map, as the cloud has no OpenStreetMap download):

1. Joins: two drivable ways that meet end to end at a node, carry on within road_smooth.CHAIN_COS,
   on one deck level and one-way flag, of one name (or renamed, where no other street leaves the
   node and they are of one kind), whose drawn edge differs by STEP_MIN..STEP_MAX m on a side.
   A side where another street leaves the node is left alone (its kerb turns into that street),
   and so is a way drawn by a carriageway area by the node (`hide`: the area's outline is the edge).
2. Taper: a side steeper than FINE_SHARE of its target is redrawn as one straight taper with
   rounded ends (`ease`), as long as RATIO times its sideways shift, at least L_MIN and at most
   L_MAX m. It runs on the narrower side first, through as many ways of the street as it needs
   (stopping at a junction), so a lane opens or closes after the node; only the part that does
   not fit there (at most WIDE_SHARE) goes onto the wider way before the node. The ways get
   per-vertex widths and centre offsets (`wv`, `cv`, vertices added every TAPER_STEP m without
   moving the line, so `hide` distances stay true), the old squeezed flare is replaced.
3. Kerbs follow the new edge (each the way whose old edge it lies on; along it they keep their
   distance, across it they go onto the new edge, the old step's face goes onto it); an edge line
   beside a kerb moves exactly as the kerb did; a lane line next to a closing edge ends where the
   taper starts, and one closer than LANE_CLEAR m to any new edge is cut.
4. The new asphalt keeps CLEAR m off buildings, walls, barriers, platforms, islands and tree
   trunks (the taper is shortened), the wider way never narrows over a zebra, and a taper is kept
   only when its join comes out flatter and no neighbouring join steeper.

The lane graph is not touched: the lanes on the narrower side stay inside the wider asphalt, and
the wider way narrows at most WIDE_SHARE of the shift before the node, outside its outer lane.
Re-run road_smooth's pole and edge-line seating after it (apply does), then tools/bake_sectors.py
and bake_city.gd. Deterministic, standard library only.
"""
import json
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import road_smooth as rs  # noqa: E402

KEY = "lane_tapers"
VERSION = 1
# --check (2026-11-14, first pass): lane drops away from junctions steeper than 1:ABRUPT_RATIO.
# 111 before the first pass, 41 after it (ways drawn by a carriageway area are not counted: the
# area's outline is the edge there); lower it when a change leaves fewer, never raise it.
CHECK_ABRUPT = 41
ABRUPT_RATIO = 5.0
STEP_MIN = 0.3          # m: a smaller edge change is invisible
STEP_MAX = 6.0          # m: a bigger one is a bay, a slip or a parking strip, not a lane
RATIO_MAIN = 15.0       # m along per metre aside at 50 km/h (main streets)
RATIO_SMALL = 10.0      # residential and unclassified streets
SMALL = {"residential", "unclassified"}
ROUND = 0.2             # share of the taper rounded at each end (the straight middle is 1 / (1 - ROUND) steeper)
L_MIN = 12.0
L_MAX = 60.0
FINE_SHARE = 0.75       # a side already at least this share of its target ratio is left alone
WIDE_SHARE = 0.4        # most of a taper that may go onto the wider way (before the node)
TAPER_STEP = 2.5        # m between the taper's vertices
LOOK = 30.0             # m each side of the node the present steepness is measured over
BAND = 0.9              # m: a kerb or edge-line point this near the old edge follows it
PAR_STEP = 3            # m (points) either side where a following line's distance from the old edge is compared
PAIR = 0.8              # m: an edge line this near a kerb moves with it
PAR_MAX = 0.5          # m it may change over PAR_STEP and the line still runs along the edge
STEP_REACH = 4.0        # m from a way's end where an old step's face (across the road) may lie
STEP_FACE = 2.5         # m inside the nearer edge such a face's points still follow the new edge
KERB_INSET = 0.0        # m outward of the asphalt edge (measured: kerbs sit on it)
EDGE_INSET = -0.35      # m: edge lines run 0.35 m inside it
CUT_KEEP = 3.0          # m: a lane-line piece left shorter than this by the cut goes too
LANE_CLEAR = 1.1        # m: a lane line nearer a closing edge than this is cut there
CAR_HALF = 0.95         # m: half a car and a little: the outer lane keeps this much asphalt beside its middle
PATH_HALF = {"cycle": 1.0}   # m: half a cycle track (kept off new asphalt)
ZEBRA_CLEAR = 3.0       # m a narrowing wider way stops before a zebra crossing it
CLEAR = 0.3             # m the new asphalt keeps from a wall, barrier, building or platform
PASSES = 1              # one round over the joins, each on the ways as the earlier ones left them
MOVE_KINDS = ("edge",)
CUT_KINDS = ("lane",)


def ease(t):
    """0..1 along a taper -> 0..1 across: straight in the middle, rounded over ROUND at each end."""
    t = min(max(t, 0.0), 1.0)
    r = ROUND
    k = 1.0 / (2.0 * r * (1.0 - r))
    if t < r:
        return t * t * k
    if t > 1.0 - r:
        return 1.0 - (1.0 - t) * (1.0 - t) * k
    return (t - r * 0.5) / (1.0 - r)


def ratio_for(kind):
    return RATIO_SMALL if kind in SMALL else RATIO_MAIN


def taper_len(kind, shift):
    """The full taper length for a sideways shift, so its straight middle is 1:ratio."""
    return min(max(ratio_for(kind) * abs(shift) / (1.0 - ROUND), L_MIN), L_MAX)


# --- road geometry ---------------------------------------------------------------------------

class Way:
    """One road's centreline, distances and drawn edges per vertex (own frame: + to the right)."""

    def __init__(self, r):
        self.r = r
        self.pts = rs.pts_of(r["p"])
        self.cum = rs.cumulative(self.pts)
        self.len = self.cum[-1]
        if "wv" in r and len(r["wv"]) == len(self.pts):
            self.edges = [(float(c) - float(w) * 0.5, float(c) + float(w) * 0.5) for w, c in zip(r["wv"], r["cv"])]
        else:
            c, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
            self.edges = [(c - hw, c + hw)] * len(self.pts)

    def edge(self, s, side):
        return rs._interp_edges(self.cum, self.edges, s)[side]


def end_info(w, last):
    """(node, away direction) of a way's end."""
    p = w.pts
    if last:
        return p[-1], rs.unit(p[-1], p[-2])
    return p[0], rs.unit(p[0], p[1])


def nkey(pt):
    return (round(pt[0], 1), round(pt[1], 1))


def build_ends(roads, ways):
    ends = defaultdict(list)
    for i, r in enumerate(roads):
        if r["k"] in rs.MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away = end_info(ways[i], last)
            if away is not None:
                ends[nkey(node)].append((i, last, node, away))
    return ends


def pair_at(roads, ends, key, need=None):
    """The best end-to-end pair of ways at a node: (cos, (ia, last_a, away_a), (ib, last_b, away_b))
    or None. `need`: one end (i, last) that must be in the pair."""
    lst = ends.get(key, [])
    best = None
    for x in range(len(lst)):
        for y in range(x + 1, len(lst)):
            ia, la_, _, aa = lst[x]
            ib, lb_, _, ab = lst[y]
            if ia == ib:
                continue
            if need is not None and need not in ((ia, la_), (ib, lb_)):
                continue
            A, B = roads[ia], roads[ib]
            if int(A.get("dk", -1)) != int(B.get("dk", -1)) or bool(A.get("oneway")) != bool(B.get("oneway")):
                continue
            cos = aa[0] * ab[0] + aa[1] * ab[1]
            if cos > -rs.CHAIN_COS:
                continue
            na, nb = A.get("name") or "", B.get("name") or ""
            if na != nb or not na:
                # renamed (or unnamed) continuation: one kind, and no other street at the node
                if A["k"] != B["k"] or len({j for j in rs._NODE_ROADS.get(key, ()) if roads[j]["k"] not in rs.MINOR}) > 2:
                    continue
            if best is None or cos < best[0]:
                best = (cos, (ia, la_, aa), (ib, lb_, ab))
    return best


def away_edge(w, last, u, side):
    """The drawn edge offset u m from an end, in that end's away frame (side 0 left, 1 right)."""
    s = w.len - u if last else u
    s = min(max(s, 0.0), w.len)
    if last:   # the away frame runs backwards: its left is the road's right, offsets mirrored
        return -w.edge(s, 1 - side)
    return w.edge(s, side)


# --- 1. joins and their present steepness ----------------------------------------------------

def open_from(r, length, at_end):
    """Metres from a way's end (its last point when at_end) to the first stretch hidden under a
    carriageway area (`hide`: the area's polygon is the drawn road there, not this strip)."""
    best = float("inf")
    for a, b in r.get("hide", ()):
        a, b = float(a), float(b)
        d = (length - b) if at_end else a
        best = min(best, max(0.0, d))
    return best


def hidden_at(r, s):
    return any(float(a) - 0.5 <= s <= float(b) + 0.5 for a, b in r.get("hide", ()))


def find_joins(roads, ways, ends):
    """[(key, node, (ia, last_a, aa), (ib, last_b, ab), blocked sides)] for every end-to-end pair
    whose edge changes by STEP_MIN..STEP_MAX m across the node (over LOOK m each side, or at it)."""
    out = []
    for key in sorted(ends):
        pr = pair_at(roads, ends, key)
        if pr is None:
            continue
        _, (ia, la_, aa), (ib, lb_, ab) = pr
        node = ends[key][0][2]
        blocked = rs.major_sides(roads, key, ia, ib, aa)
        a, b = (ia, la_, aa), (ib, lb_, ab)
        # a way drawn by a carriageway area by the node: the area's outline is the edge there
        if min(open_from(roads[ia], ways[ia].len, la_), open_from(roads[ib], ways[ib].len, lb_)) < LOOK:
            continue
        steps = []
        for k in (0, 1):
            ch, _ = steepness(ways, a, b, k)
            jump = abs(profile(ways, a, b, k, 0.0) - profile(ways, a, b, k, -1e-6))
            steps.append(max(ch, jump))
        if max(steps) <= STEP_MIN or max(steps) > STEP_MAX:
            continue
        out.append((key, node, a, b, blocked))
    return out


_CTX = {}   # "roads", "ends" of the map being measured; "chains": (road, end) -> measuring chain


def set_context(roads, ends):
    _CTX.clear()
    _CTX.update(roads=roads, ends=ends, chains={})


def measure_chain(ways, i, last):
    """The street's ways from a node along way i (its end `last` at the node), LOOK m or up to a
    junction, whatever their widths: [(way, end at the near node, metres where it starts)]."""
    key = (i, last)
    ch = _CTX["chains"].get(key)
    if ch is None:
        roads, ends = _CTX["roads"], _CTX["ends"]
        ch = [(i, last, 0.0)]
        got = ways[i].len
        seen = {i}
        while got < LOOK:
            j, lj, _ = ch[-1]
            node, _ = end_info(ways[j], not lj)
            k = nkey(node)
            pr = pair_at(roads, ends, k, need=(j, not lj))
            if pr is None:
                break
            _, p, q = pr
            nxt = q if (p[0], p[1]) == (j, not lj) else p
            if nxt[0] in seen or rs.major_sides(roads, k, p[0], q[0], p[2]):
                break
            ch.append((nxt[0], nxt[1], got))
            seen.add(nxt[0])
            got += ways[nxt[0]].len
        _CTX["chains"][key] = ch
    return ch


def profile(ways, a, b, side, x):
    """A join's edge on `side` (a's away frame) at x m from the node: x >= 0 along a's side of the
    street, < 0 along b's (through the next ways of the street when a way is shorter)."""
    if x >= 0.0:
        w, sd, u, sg = a, side, x, 1.0
    else:
        w, sd, u, sg = b, 1 - side, -x, -1.0
    if not _CTX:
        return sg * away_edge(ways[w[0]], w[1], u, sd)
    for j, at_end, s0 in reversed(measure_chain(ways, w[0], w[1])):
        if u >= s0 - 1e-9:
            return sg * away_edge(ways[j], at_end, u - s0, sd)
    return sg * away_edge(ways[w[0]], w[1], u, sd)


def steepness(ways, a, b, side):
    """(change across the join over LOOK m, flattest ratio of its steepest 2 m: m along per m
    aside; 0 for a step at the node itself bigger than STEP_MIN)."""
    if _CTX:
        ca, cb = measure_chain(ways, a[0], a[1]), measure_chain(ways, b[0], b[1])
        la = ca[-1][2] + ways[ca[-1][0]].len
        lb = cb[-1][2] + ways[cb[-1][0]].len
    else:
        la, lb = ways[a[0]].len, ways[b[0]].len
    xs = [x * 0.5 for x in range(-int(min(LOOK, lb) * 2), int(min(LOOK, la) * 2) + 1)]
    vals = [profile(ways, a, b, side, x) if x != 0.0 else None for x in xs]
    k0 = xs.index(0.0)
    # at the node: each way's own end (a step between them shows as one)
    jump = abs(profile(ways, a, b, side, 0.0) - profile(ways, a, b, side, -1e-6))
    vals[k0] = profile(ways, a, b, side, 0.0)
    if jump > STEP_MIN:
        ms = 1e3
    else:
        ms = 0.0
        vals[k0] = None   # a smaller step at the node is invisible: measure across it
    pts = [(x, v) for x, v in zip(xs, vals) if v is not None]
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            if pts[j][0] - pts[i][0] >= 2.0 - 1e-6:
                if not (pts[i][0] < 0.0 < pts[j][0] and jump > STEP_MIN):
                    ms = max(ms, abs(pts[j][1] - pts[i][1]) / (pts[j][0] - pts[i][0]))
                break
    return abs(pts[-1][1] - pts[0][1]), (1.0 / ms if ms > 1e-6 else 999.0)


# --- 2. taper ---------------------------------------------------------------------------------

def walk_chain(roads, ways, ends, start, need, stop=()):
    """The ways of the street from a node along way `start` = (i, last at the node), up to `need`
    metres: [(i, at_end, s0 along the chain where the way starts)] and the length found. Stops at
    a junction (another street at the next node), at another lane change (`stop`: the joins' nodes)
    and where the next way's width differs."""
    i, last = start
    chain = [(i, last, 0.0)]
    got = ways[i].len
    seen = {i}
    if roads[i].get("hide"):
        return chain, min(got, open_from(roads[i], ways[i].len, last))
    while got < need:
        w = ways[i]
        far_last = not last          # the way's other end
        node, away = end_info(w, far_last)
        key = nkey(node)
        if key in stop:
            break
        pr = pair_at(roads, ends, key, need=(i, far_last))
        if pr is None:
            break
        _, a, b = pr
        nxt = b if (a[0], a[1]) == (i, far_last) else a
        if nxt[0] in seen or rs.major_sides(roads, key, a[0], b[0], a[2]):
            break
        # the next way carries on at the same drawn width (else another join starts there)
        j, lj, _ = nxt
        if roads[j].get("hide"):
            break
        if any(abs(away_edge(w, far_last, 0.0, k) + away_edge(ways[j], lj, 0.0, 1 - k)) > STEP_MIN for k in (0, 1)):
            break
        chain.append((j, lj, got))
        seen.add(j)
        i, last = j, lj
        got += ways[j].len
    return chain, got


def frame_sign(ways, i, at_end, direction):
    """+1 when a way's own + side is the + side of a frame running along `direction` away from
    the way's end `at_end` (the way runs that way from that end), else -1."""
    return -1.0 if at_end else 1.0


def lane_count(r):
    """The way's lane count: its tag, else a guess from its width (a two-way street has an even count)."""
    n = int(r.get("lanes") or 0)
    if n:
        return n
    w = float(r["w"])
    return max(1, round(w / 3.25)) if r.get("oneway") else max(2, 2 * round(w / 6.5))


def wide_part(L, Ln, shift, max_in, wide_len):
    """How much of a taper goes onto the wider way (before the node): what does not fit on the
    narrow side, at most WIDE_SHARE of it, half the way, and no more than closes the wider way in
    by max_in m at the node."""
    if Ln >= L:
        return 0.0
    La = min(L - Ln, WIDE_SHARE * L, wide_len * 0.5)
    # the inward shift at the node is shift * ease(La / (La + Ln)): shorten La until it fits
    for _ in range(40):
        if La <= 0.0 or shift * ease(La / (La + Ln)) <= max_in + 1e-6:
            break
        La *= 0.9
    return La if La > 0.5 else 0.0


def chain_edge(ways, chain, side, u):
    """The drawn edge (the chain's away frame) u m along a chain from its node."""
    for j, at_end, s0 in reversed(chain):
        if u >= s0 - 1e-9:
            return away_edge(ways[j], at_end, min(u - s0, ways[j].len), side)
    j, at_end, _ = chain[0]
    return away_edge(ways[j], at_end, 0.0, side)


def first_block(ways, chain, side, E, Ln, out_sgn):
    """Metres from the node to the first point where the widened edge would meet an obstacle."""
    for j, at_end, s0 in chain:
        w = ways[j]
        u = 0.0
        while u <= w.len and s0 + u <= Ln:
            new = E(s0 + u)
            old = away_edge(w, at_end, u, side)
            if (new - old) * out_sgn > 0.05 and blocked_at(w, at_end, u, side, new, old):
                return s0 + u
            u += 1.0
    return None


class Plan:
    """Per road: the edge targets of every taper on it, to apply in one go."""

    def __init__(self):
        self.ops = defaultdict(list)   # road -> [(s0, s1, own side, mode, fn(s) -> own offset, clear_s0, clear_s1)]

    def add(self, i, s0, s1, side, mode, fn, clear=None):
        self.ops[i].append((s0, s1, side, mode, fn, clear))


def plan_side(roads, ways, ends, join, side, plan, stats, stop=()):
    """Plans the taper of one side of a join; returns True when planned."""
    key, node, a, b, blocked = join
    ia, la_, aa = a
    ib, lb_, ab = b
    ea = profile(ways, a, b, side, 0.0)
    eb = profile(ways, a, b, side, -1e-6)
    # which way is narrower on this side: outward is - on side 0, + on side 1
    sgn = 1.0 if side == 1 else -1.0
    if (ea - eb) * sgn > 0:      # a is wider here: b is the narrow way, x < 0 is its side
        wide, narrow, wide_side, narrow_side = a, b, side, 1 - side
    else:
        wide, narrow, wide_side, narrow_side = b, a, 1 - side, side
    kind = roads[ia]["k"]
    # the narrow way's own settled edge (beyond its old flare) and the wide way's at the node
    wn, ww = ways[narrow[0]], ways[wide[0]]
    flare = min(rs.TAPER_MAX, wn.len * 0.5)
    e_wide = away_edge(ww, wide[1], 0.0, wide_side)
    e_narrow = min((away_edge(wn, narrow[1], u, narrow_side) * (1 if narrow_side == 1 else -1)
                    for u in [x * 0.5 for x in range(int(flare * 2) + 1)]))
    e_narrow *= (1 if narrow_side == 1 else -1)
    e_w_n = -e_wide   # the wide edge seen in the narrow way's away frame (mirrored)
    shift = abs(e_w_n - e_narrow)
    if shift <= STEP_MIN:
        return False
    L = taper_len(kind, shift)
    chain, got = walk_chain(roads, ways, ends, (narrow[0], narrow[1]), L, stop)
    out_sgn = 1.0 if narrow_side == 1 else -1.0    # outward in the narrow frame
    # the most the wider way may close in at the node: its outer lane's car stays on the asphalt
    rw = roads[wide[0]]
    n_l = lane_count(rw)
    max_in = max(0.0, float(rw["w"]) / n_l * 0.5 - CAR_HALF)
    Ln = min(got, L)
    for _ in range(6):
        # the taper ends on the narrow side's edge as it stands there (another join's taper may
        # already have drawn the next stretch), so the far end of this one meets it exactly
        e_narrow = chain_edge(ways, chain, narrow_side, Ln) if Ln > 0.0 else e_narrow
        La = wide_part(L, Ln, shift, max_in, ww.len)
        # the wider way does not close in over a zebra or a cycle crossing (it would hang off)
        if La > 0.0:
            La = min(La, max(0.0, open_from(rw, ww.len, wide[1]) - 1.0))
        zs = [(ww.len - z) if wide[1] else z for z in _ZEB.get(wide[0], ())]
        if zs and La > 0.0:
            La = min(La, max(0.0, min(zs) - ZEBRA_CLEAR))
        if Ln + La < L_MIN * 0.5:
            stats["no_room"] += 1
            return False
        total = Ln + La

        def E(u, La=La, total=total, e_narrow=e_narrow):
            return e_w_n + (e_narrow - e_w_n) * ease((u + La) / total)
        hit = first_block(ways, chain, narrow_side, E, Ln, out_sgn)
        if hit is None:
            break
        Ln = max(0.0, hit - 2.0)
    else:
        stats["blocked"] += 1
        return False
    if hit is not None:
        stats["blocked"] += 1
        return False
    stats["shortened"] += 1 if Ln < min(got, L) - 0.5 else 0
    for j, at_end, s0 in chain:
        if s0 >= Ln:
            break
        w = ways[j]
        own_side = narrow_side if not at_end else 1 - narrow_side
        span0, span1 = s0, min(Ln, s0 + w.len)

        def fn(s, s0=s0, at_end=at_end, w=w):
            u = s0 + ((w.len - s) if at_end else s)
            v = E(u)
            return -v if at_end else v
        if at_end:
            r0, r1 = w.len - (span1 - s0), w.len
        else:
            r0, r1 = 0.0, span1 - s0
        clear = None
        if j == narrow[0]:   # its own old flare by the node goes
            c = min(flare, w.len)
            clear = (w.len - c, w.len) if at_end else (0.0, c)
        plan.add(j, r0, r1, own_side, "out", fn, clear)
    if La > 0.0:
        own_side = wide_side if not wide[1] else 1 - wide_side

        def fw(s, w=ww, at_end=wide[1]):
            u = -((w.len - s) if at_end else s)
            v = -E(u)     # back into the wide way's away frame
            return -v if at_end else v
        r0, r1 = ((ww.len - La, ww.len) if wide[1] else (0.0, La))
        plan.add(wide[0], r0, r1, own_side, "in", fw)
    stats["sides"] += 1
    stats["wide_part"] += 1 if La > 0.0 else 0
    return True


# --- obstacles -------------------------------------------------------------------------------

_OBST = None
_ZEB = {}   # road -> distances along it where a zebra or cycle crossing crosses it


def build_crossings(out, roads):
    """{road: [s, ...]} of the zebras and cycle crossings across each road."""
    g = road_grid(roads)
    res = defaultdict(list)
    for pa in out.get("paths", []):
        if pa["k"] not in ("zebra", "cyclecross"):
            continue
        q = rs.pts_of(pa["p"])
        if len(q) < 2:
            continue
        for x, z in densify(q, 1.0):
            for i, (s, off, dist) in _near_roads(g, x, z, 12.0, slack=3.0).items():
                r = roads[i]
                if abs(off) <= float(r["w"]) * 0.5 + abs(float(r.get("c", 0.0))) + 1.0 and dist < 12.0:
                    res[i].append(s)
    return res


def build_obstacles(out):
    """Segments with a half width (walls, barriers, building outlines, platform and island
    outlines, tree trunks, cycle tracks and footways beside the road) on a grid."""
    g = rs.Grid(8.0)
    segs = []
    asphalt = rs._street_tests(out)[0]

    def add_line(p, closed=False, half=0.0, off_road=False):
        q = rs.pts_of(p)
        if closed and len(q) > 2:
            q = q + [q[0]]
        for a, b in zip(q, q[1:]):
            if off_road and asphalt((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5):
                continue   # a path across the carriageway (a crossing) is no edge
            segs.append((a, b, half))
            n = len(segs) - 1
            for t in (0.0, 0.5, 1.0):
                g.add(n, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            ln = math.dist(a, b)
            for k in range(1, int(ln / 6.0)):
                t = k * 6.0 / ln
                g.add(n, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    for w in out.get("walls", []):
        add_line(w["p"])
    for ln in out.get("lines", []):
        if ln.get("k") in ("wall", "fence", "hedge", "platform"):
            add_line(ln["p"])
    for gd in out.get("guards", []):
        if isinstance(gd, dict) and "p" in gd:
            add_line(gd["p"])
    for key in ("platforms", "islands", "buildings"):
        for e in out.get(key, []):
            if isinstance(e, dict) and isinstance(e.get("p"), list) and e["p"] and not isinstance(e["p"][0], list):
                add_line(e["p"], closed=True)
    # scanned tree trunks (x, z, height, crown radius, crown base, kind): a trunk stays off the asphalt
    t3 = out.get("trees3d", [])
    for k in range(0, len(t3) - 5, 6):
        x, z = float(t3[k]), float(t3[k + 1])
        add_line([x, z, x + 0.05, z])
    # a cycle track or a footway beside the road keeps its width (the road does not eat it)
    for pa in out.get("paths", []):
        if pa.get("k") in PATH_HALF:
            add_line(pa["p"], half=PATH_HALF[pa["k"]], off_road=True)
    return g, segs


def blocked_at(w, at_end, u, side, new, old):
    """True when the strip of new asphalt (side, from offset `old` to `new` in the away frame) u m
    from the end comes within CLEAR m of an obstacle (or of a path's side)."""
    g, segs = _OBST
    s = (w.len - u) if at_end else u
    s = min(max(s, 0.0), w.len)
    k = 0
    while k < len(w.cum) - 2 and w.cum[k + 1] < s:
        k += 1
    a, b = w.pts[k], w.pts[min(k + 1, len(w.pts) - 1)]
    d = rs.unit(a, b) or (1.0, 0.0)
    t = (s - w.cum[k])
    px, pz = a[0] + d[0] * t, a[1] + d[1] * t
    sg = -1.0 if at_end else 1.0
    nx, nz = -d[1], d[0]
    n = max(1, int(abs(new - old) / 0.25))
    probes = [(px + nx * sg * (old + (new - old) * m / n), pz + nz * sg * (old + (new - old) * m / n))
              for m in range(n + 1)]
    qx, qz = probes[-1]
    for idx in set(g.near(qx, qz, 6.0 + abs(new - old))):
        sa, sb, half = segs[idx]
        for q in probes:
            if rs.seg_dist(q, sa, sb) < CLEAR + half:
                return True
    return False


# --- applying a plan to the roads ------------------------------------------------------------

def apply_plan(roads, ways, plan):
    """Sets `wv`/`cv` on every planned road and refreshes its Way in `ways`; returns the roads."""
    for i, ops in plan.ops.items():
        w = ways[i]
        pts = w.pts
        for s0, s1, _, _, _, clear in ops:
            pts = rs.resample_between(pts, s0, s1, TAPER_STEP)
            if clear:
                pts = rs.resample_between(pts, clear[0], clear[1], TAPER_STEP)
        cum = rs.cumulative(pts)
        old = [w.edge(s, 0) for s in cum], [w.edge(s, 1) for s in cum]
        base = [list(old[0]), list(old[1])]
        # the old squeezed flare by the node goes: the edge settles to its innermost value there
        for s0, s1, side, mode, fn, clear in ops:
            if not clear or mode != "out":
                continue
            out_sgn = 1.0 if side == 1 else -1.0
            idx = [k for k, s in enumerate(cum) if clear[0] - 1e-6 <= s <= clear[1] + 1e-6]
            if not idx:
                continue
            settled = min(base[side][k] * out_sgn for k in idx) * out_sgn
            for k in idx:
                base[side][k] = settled
        new = [list(base[0]), list(base[1])]
        for s0, s1, side, mode, fn, clear in ops:
            out_sgn = 1.0 if side == 1 else -1.0
            for k, s in enumerate(cum):
                if s < s0 - 1e-6 or s > s1 + 1e-6:
                    continue
                v = fn(s)
                if mode == "out":
                    if (v - new[side][k]) * out_sgn > 0:
                        new[side][k] = v
                elif (v - new[side][k]) * out_sgn < 0:
                    new[side][k] = v
        r = roads[i]
        r["p"] = rs.flat_of(pts)
        r["wv"] = [round(new[1][k] - new[0][k], 3) for k in range(len(cum))]
        r["cv"] = [round((new[1][k] + new[0][k]) * 0.5, 3) for k in range(len(cum))]
        ways[i] = Way(r)
    return set(plan.ops)


def joins_of(roads_idx, ways, by_road):
    """{node key: join} of every join on the given roads."""
    return {jn[0]: jn for i in roads_idx for jn in by_road.get(i, ())}


def changes(orig, ways, roads, idx):
    """{road: (points, distances, old edges, new edges)} per vertex of the final line (the taper
    only adds vertices, so the original way's edges are read at the same distances)."""
    out = {}
    for i in idx:
        w = ways[i]
        o = orig[i]
        old = [o.edge(s, 0) for s in w.cum], [o.edge(s, 1) for s in w.cum]
        new = [e[0] for e in w.edges], [e[1] for e in w.edges]
        out[i] = (w.pts, w.cum, old, new)
    return out


# --- 3. kerbs, edge lines and lane lines -----------------------------------------------------

def _near_roads(grid, x, z, reach, slack=0.0):
    """{road: (s along, signed offset, distance)} of each road's nearest centreline segment within
    reach (a segment's projection may overshoot its ends by 2 % or `slack` m)."""
    best = {}
    for (i, k, a, b, s0) in grid.near(x, z, reach):
        dx, dz = b[0] - a[0], b[1] - a[1]
        l2 = dx * dx + dz * dz
        if l2 < 1e-9:
            continue
        t = ((x - a[0]) * dx + (z - a[1]) * dz) / l2
        over = max(0.02, slack / math.sqrt(l2))
        if t < -over or t > 1.0 + over:
            continue
        t = min(max(t, 0.0), 1.0)
        qx, qz = a[0] + dx * t, a[1] + dz * t
        ln = math.sqrt(l2)
        off = ((x - a[0]) * -dz + (z - a[1]) * dx) / ln
        dist = math.hypot(x - qx, z - qz)
        if dist <= reach and (i not in best or dist < best[i][2]):
            best[i] = (s0 + t * ln, off, dist)
    return best


def _at(pts, cum, s, nw):
    """The point offset nw from the centreline at distance s."""
    k = 0
    while k < len(cum) - 2 and cum[k + 1] < s:
        k += 1
    a, b = pts[k], pts[k + 1]
    d = rs.unit(a, b) or (1.0, 0.0)
    t = s - cum[k]
    return (a[0] + d[0] * t - d[1] * nw, a[1] + d[1] * t + d[0] * nw)


def road_grid(roads, only=None):
    g = rs.Grid(16.0)
    for i, r in enumerate(roads):
        if only is not None and i not in only:
            continue
        if r["k"] in rs.MINOR:
            continue
        p = rs.pts_of(r["p"])
        s = 0.0
        for k, (a, b) in enumerate(zip(p, p[1:])):
            ln = math.dist(a, b)
            n = max(1, int(ln / 8.0))
            for m in range(n + 1):
                t = m / n
                g.add((i, k, a, b, s), a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            s += ln
    return g


def _edges_at(cum, edges, s):
    return rs._interp_edges(cum, list(zip(edges[0], edges[1])), s)


def move_lines(out, roads, changed, orig):
    """Moves kerb and edge-line points along a changed edge; cuts lane lines a closing edge reaches.
    `orig`: every road's Way before the pass (the old edges). Returns (points moved, lane-line
    points cut)."""
    allg = road_grid(roads)
    zone = rs.Grid(16.0)
    for i, (pts, cum, old, new) in changed.items():
        for k, s in enumerate(cum):
            if abs(old[0][k] - new[0][k]) > 0.02 or abs(old[1][k] - new[1][k]) > 0.02:
                zone.add(i, pts[k][0], pts[k][1])

    def in_zone(x, z):
        return any(True for _ in zone.near(x, z, 12.0))

    def old_edges(i, s):
        if i in changed:
            pts, cum, old, new = changed[i]
            return _edges_at(cum, old, s), _edges_at(cum, new, s)
        e = (orig[i].edge(s, 0), orig[i].edge(s, 1))
        return e, e

    def target(x, z, inset):
        """(new place or None, distance from the nearest old edge, that edge's road and side) of a
        kerb or edge-line point. The point belongs to the road whose OLD edge (with the line's
        inset) it lies nearest, so a kerb between two carriageways or at a node follows its own
        way, not the nearest centreline."""
        cands = _near_roads(allg, x, z, 14.0)
        best = None
        for i, (s, off, _) in cands.items():
            if hidden_at(roads[i], s):
                continue   # under a carriageway area: its strip is not drawn
            (lo, ro), (ln, rn) = old_edges(i, s)
            for side, eo, en, sg in ((0, lo, ln, -1.0), (1, ro, rn, 1.0)):
                rel = (off - eo) * sg - inset
                if best is None or abs(rel) < abs(best[0]):
                    best = (rel, i, s, off, eo, en, sg)
        if best is None:
            return None, None, None, None
        own = (best[1], best[6])
        if abs(best[0]) <= BAND:
            rel, i, s, off, eo, en, sg = best
            if i not in changed or abs(eo - en) < 0.02:
                return None, rel, own, None
            pts, cum = changed[i][0], changed[i][1]
            # shifted with the edge, keeping its own distance from it
            return _at(pts, cum, s, off + (en - eo)), rel, own, _at(pts, cum, s, en + inset * sg)
        # by a way's end the old step's face ran across the road: where the edge now opens
        # outward there, the face's points between the old and the new edge go onto the new one
        for i, (s, off, _) in cands.items():
            if i not in changed:
                continue
            pts, cum = changed[i][0], changed[i][1]
            if not (s < STEP_REACH or s > cum[-1] - STEP_REACH):
                continue
            (lo, ro), (ln, rn) = old_edges(i, s)
            for eo, en, sg in ((lo, ln, -1.0), (ro, rn, 1.0)):
                if (en - eo) * sg < 0.1:
                    continue
                if eo * sg - STEP_FACE <= off * sg <= en * sg + BAND:
                    return _at(pts, cum, s, en + inset * sg), None, None, None
        return None, best[0], own, None

    def lane_target(x, z):
        """(road, s, offset, new edge, sign, old edge) of the edge nearest a lane-line point, on
        the changed road whose old asphalt holds it, or None."""
        best = None
        for i, (s, off, _) in _near_roads(allg, x, z, 14.0).items():
            (lo, ro), (ln, rn) = old_edges(i, s)
            if not (lo - 0.1 <= off <= ro + 0.1):
                continue
            c = (lo + ro) * 0.5
            if best is None or abs(off - c) < best[0]:
                side = 1 if off > c else 0
                eo, en = (ro, rn) if side else (lo, ln)
                best = (abs(off - c), i, s, off, en, 1.0 if side else -1.0, eo)
        if best is None or best[1] not in changed or abs(best[6] - best[4]) < 0.02:
            return None
        return best[1:]

    moved = 0
    kgrid = rs.Grid(4.0)   # every kerb point near a change, with how far it moved
    for lst, inset, is_kerb in ((out.get("kerbs", []), KERB_INSET, True),
                                ([m for m in out.get("markings", []) if m["k"] in MOVE_KINDS], EDGE_INSET, False)):
        for e in lst:
            q = rs.pts_of(e["p"])
            if len(q) > 3 and math.dist(q[0], q[-1]) < 0.5:
                continue   # a painted island's closed outline keeps its shape
            if not any(in_zone(x, z) for x, z in q) and not any(
                    in_zone((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) for a, b in zip(q, q[1:])):
                continue
            dense = densify(q, 1.0)
            hits = [target(x, z, inset) if in_zone(x, z) else (None, None, None, None) for x, z in dense]
            dis = []
            for k, ((x, z), (t, rel, own, onto)) in enumerate(zip(dense, hits)):
                # a line that runs across the old edge (its distance from it changing fast) was
                # not drawn along it: shifted with the edge it would bend, so it goes onto the new
                # edge instead (where the asphalt now ends)
                if t is not None and rel is not None:
                    for j in (k - PAR_STEP, k + PAR_STEP):
                        if 0 <= j < len(hits) and hits[j][2] == own and hits[j][1] is not None \
                                and abs(hits[j][1] - rel) > PAR_MAX:
                            t = onto
                            break
                d = (0.0, 0.0) if t is None else (t[0] - x, t[1] - z)
                if not is_kerb:
                    # an edge line beside a kerb moves exactly as that kerb did, so the two
                    # never cross
                    near = None
                    for (kx, kz, kd) in kgrid.near(x, z, PAIR):
                        dd = math.hypot(kx - x, kz - z)
                        if dd <= PAIR and (near is None or dd < near[0]):
                            near = (dd, kd)
                    if near is not None:
                        d = near[1]
                dis.append(d)
            # a lone point given to another way (a node, a carriageway's other side) would make a
            # spike: the moves are filtered with a median of five along the line
            sm = []
            for k in range(len(dense)):
                win = dis[max(0, k - 2):k + 3]
                sm.append((sorted(d[0] for d in win)[len(win) // 2], sorted(d[1] for d in win)[len(win) // 2]))
            if is_kerb:
                for (x, z), d in zip(dense, sm):
                    kgrid.add((x, z, d), x, z)
            if not any(abs(dx) + abs(dz) > 1e-6 for dx, dz in sm):
                continue
            res = rs.simplify([(x + d[0], z + d[1]) for (x, z), d in zip(dense, sm)], 0.03)
            moved += 1
            e["p"] = rs.flat_of(res)
    # lane lines a closing edge reaches: cut there
    cut = 0
    keep = []
    for m in out.get("markings", []):
        if m["k"] not in CUT_KINDS:
            keep.append(m)
            continue
        q = rs.pts_of(m["p"])
        if not any(in_zone(x, z) for x, z in q):
            keep.append(m)
            continue
        dense = densify(q, 1.0)
        # 0 keep, 1 beside a closing edge (soft), 2 too near any new edge (hard)
        flag = []
        for x, z in dense:
            t = lane_target(x, z) if in_zone(x, z) else None
            f = 0
            if t is not None:
                i, s, off, en, sg, eo = t
                # beside a closing edge (a lane ending before the node) the line between the lanes
                # ends where the taper starts, as a real lane line ends at the hatching
                lw = float(roads[i]["w"]) / lane_count(roads[i])
                closing = (eo - en) * sg > 0.15
                gap = (en - off) * sg
                f = 2 if gap < LANE_CLEAR else (1 if closing and gap < lw + 0.3 else 0)
            flag.append(f)
        # a soft cut with the line going on beyond it is no lane drop for this line (the lane
        # only narrows there): that stretch stays
        k = 0
        while k < len(flag):
            if flag[k] == 0:
                k += 1
                continue
            e = k
            while e < len(flag) and flag[e] != 0:
                e += 1
            if k > 0 and e < len(flag) and max(flag[k:e]) == 1 \
                    and rs.length(dense[:k]) >= CUT_KEEP and rs.length(dense[e:]) >= CUT_KEEP:
                for m2 in range(k, e):
                    flag[m2] = 0
            k = e
        runs, cur = [], []
        for (x, z), f in zip(dense, flag):
            if f:
                cut += 1
                if len(cur) >= 2:
                    runs.append(cur)
                cur = []
            else:
                cur.append((x, z))
        if len(cur) >= 2:
            runs.append(cur)
        if len(runs) == 1 and len(runs[0]) == len(dense):
            keep.append(m)
            continue
        for run in runs:
            # a stub shorter than a dash and its gap is dropped: the line ends before the taper
            if rs.length(run) >= CUT_KEEP:
                keep.append({**m, "p": rs.flat_of(rs.simplify(run, 0.03))})
    out["markings"] = keep
    return moved, cut


def densify(pts, step):
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        ln = math.dist(a, b)
        n = max(1, int(math.ceil(ln / step)))
        for k in range(1, n + 1):
            t = k / n
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


# --- census and check ------------------------------------------------------------------------

def census(out):
    """[(node, side, change m, ratio, kind, names)] of every lane-sized join side away from
    junctions, with its present steepness."""
    roads = out["roads"]
    rs.index_nodes(roads)
    ways = [Way(r) for r in roads]
    ends = build_ends(roads, ways)
    set_context(roads, ends)
    rows = []
    for key, node, a, b, blocked in find_joins(roads, ways, ends):
        for side in (0, 1):
            if side in blocked:
                continue
            ch, ratio = steepness(ways, a, b, side)
            jump = abs(profile(ways, a, b, side, 0.0) - profile(ways, a, b, side, -1e-6))
            if max(ch, jump) <= STEP_MIN:
                continue
            rows.append((node, side, round(max(ch, jump), 2), round(ratio, 1), roads[a[0]]["k"],
                         (roads[a[0]].get("name") or "", roads[b[0]].get("name") or "")))
    return rows


def abrupt(rows):
    """Joins (not sides) with a side steeper than 1:ABRUPT_RATIO."""
    return sorted({r[0] for r in rows if r[3] < ABRUPT_RATIO})


def apply(out):
    """Tapers the lane drops of the finished map data in place; returns a one-line summary."""
    global _OBST
    if int(out.get(KEY, 0)) >= VERSION:
        return "already tapered"
    roads = out["roads"]
    before = census(out)
    rs.index_nodes(roads)
    ways = [Way(r) for r in roads]
    ends = build_ends(roads, ways)
    set_context(roads, ends)
    _OBST = build_obstacles(out)
    _ZEB.clear()
    _ZEB.update(build_crossings(out, roads))
    orig = list(ways)
    stats = defaultdict(int)
    touched = set()
    joins = find_joins(roads, ways, ends)
    # a taper runs on through a node where only the measurement sees a change (the two ways are
    # drawn alike there; the change is a short way further on), not through a real width change
    stop = {j[0] for j in joins
            if abs(float(roads[j[2][0]]["w"]) - float(roads[j[3][0]]["w"])) > STEP_MIN
            or abs(abs(float(roads[j[2][0]].get("c", 0.0))) - abs(float(roads[j[3][0]].get("c", 0.0)))) > STEP_MIN}
    by_road = defaultdict(list)
    for jn in joins:
        by_road[jn[2][0]].append(jn)
        by_road[jn[3][0]].append(jn)
    # one join side at a time, on the ways as the earlier ones left them (two passes: a short way
    # between two joins is seen again once both have been drawn)
    for rnd in range(PASSES):
        for join in joins:
            key, node, a, b, blocked = join
            for side in (0, 1):
                if side in blocked:
                    continue
                ch, ratio = steepness(ways, a, b, side)
                jump = abs(profile(ways, a, b, side, 0.0) - profile(ways, a, b, side, -1e-6))
                if max(ch, jump) <= STEP_MIN:
                    continue
                if ratio >= FINE_SHARE * ratio_for(roads[a[0]]["k"]):
                    stats["fine"] += 1 if rnd == 0 else 0
                    continue
                plan = Plan()
                st = defaultdict(int)
                if not plan_side(roads, ways, ends, join, side, plan, st, stop):
                    for k, v in st.items():
                        stats[k] += v
                    continue
                # kept only if it makes this join flatter and no join at the ends of the ways it
                # touched steeper (an obstacle may leave too little room to beat the old taper)
                saved = {i: (roads[i]["p"], roads[i].get("wv"), roads[i].get("cv"), ways[i]) for i in plan.ops}
                near = joins_of(saved, ways, by_road)
                was = {(jk, sd): steepness(ways, jn[2], jn[3], sd)[1] for jk, jn in near.items() for sd in (0, 1)}
                apply_plan(roads, ways, plan)
                now = {(jk, sd): steepness(ways, jn[2], jn[3], sd)[1] for jk, jn in near.items() for sd in (0, 1)}
                better = now[(key, side)] > was[(key, side)] * 1.05
                worse = any(now[k] < min(was[k], ABRUPT_RATIO * 3) * 0.95 for k in was if k != (key, side))
                if better and not worse:
                    touched |= set(plan.ops)
                    for k, v in st.items():
                        stats[k] += v
                    continue
                stats["kept"] += 1
                for i, (p, wv, cv, w) in saved.items():
                    roads[i]["p"] = p
                    for k2, v2 in (("wv", wv), ("cv", cv)):
                        if v2 is None:
                            roads[i].pop(k2, None)
                        else:
                            roads[i][k2] = v2
                    ways[i] = w
    changed = changes(orig, ways, roads, touched)
    moved, cut = move_lines(out, roads, changed, orig)
    asphalt = rs._street_tests(out)[0]
    poles = rs.clear_poles(out, asphalt)
    seated = rs.seat_edges(out)
    after = census(out)
    out[KEY] = VERSION
    return (f"{stats['sides']} join sides tapered on {len(changed)} ways ({stats['wide_part']} partly before the node), "
            f"{stats['fine']} already fine, {stats['kept']} kept (no flatter taper fits), {stats['shortened']} shortened by an obstacle, {stats['blocked']} blocked by a wall or building, {stats['no_room']} without room; "
            f"{moved} kerbs and edge lines moved, {cut} lane-line points cut, {poles} poles stepped off, "
            f"{seated} edge-line points seated; abrupt lane drops {len(abrupt(before))} -> {len(abrupt(after))}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    path = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    if "--check" in sys.argv or "--list" in sys.argv or "--dry" in sys.argv:
        rows = census(d)
        bad = abrupt(rows)
        if "--list" in sys.argv:
            for r in sorted(rows, key=lambda r: r[3]):
                if r[3] < ABRUPT_RATIO:
                    print(f"  {r[0][0]:.0f},{r[0][1]:.0f} side {r[1]} change {r[2]} m ratio 1:{r[3]} {r[4]} {r[5][0]!r} / {r[5][1]!r}")
        ok = bool(d.get(KEY)) and len(bad) <= CHECK_ABRUPT
        why = "" if d.get(KEY) else " (the map was never tapered: run tools/lane_tapers.py)"
        print(f"lane_tapers: {'OK' if ok else 'FAIL'}: abrupt lane drops {len(bad)} (max {CHECK_ABRUPT}), "
              f"lane-sized joins {len({r[0] for r in rows})}{why}")
        return 0 if (ok or "--check" not in sys.argv) else 1
    print("lane_tapers: " + apply(d))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(d, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
