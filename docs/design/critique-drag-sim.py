"""The drag on Aleja Zieleniecka: today's run model and the proposed one (critique-drag.md).

usage: python3 -I docs/design/critique-drag-sim.py

Part 1 ports street_meet.gd `sim_run` (car.gd `_pull`: the pull fades by 0.6 x speed / gear cap)
with the launch grades the game applies at green, and prints runs against Tadek's time.
Part 2 is the proposal: five gears with a pull per gear, a 0.12 s PERFECT, a bog for a short
shift, one bottle that only bites from third gear, and Tadek driven by the same model.
"""
Q = 402.0


def run(gears, pulls, top, accel=15.0, launch="perfect", shifts=None, nitro=None, react=0.0,
        n_accel=2.2, n_top=1.3, n_len=2.5, n_min_gear=0, p_w=0.35, g_w=0.8, short_bog=False):
    """shifts[g]: ("w", s after the needle reaches 0.96) or ("k", share of the gear's cap).
    nitro: None, ("t", seconds) or ("g", gear index entered)."""
    n = len(gears)
    shifts = shifts or [("w", 0.06)] * (n - 1)
    dt = 1 / 120
    t = s = v = 0.0
    gear = 0
    at = -1.0
    boost = bog = nt = 0.0
    bogk = 1.0
    used = False
    marks = []
    if launch == "perfect":
        boost = 1.1
    elif launch == "spin":
        bog, bogk = 0.9, 0.55
    elif launch == "bog":
        bog, bogk = 0.6, 0.6
    while s < Q and t < 60:
        t += dt
        if t < react:
            continue
        if nitro and not used and ((nitro[0] == "t" and t >= nitro[1]) or (nitro[0] == "g" and gear >= nitro[1])):
            used = True
            if gear < n_min_gear:
                bog, bogk = 0.9, 0.55  # the proposal: a bottle in a low gear is wheelspin
            else:
                nt = n_len
        nn = nt > 0
        cap = top * gears[gear] * (n_top if nn else 1)
        a = accel * pulls[gear] * (n_accel if nn else 1) * (1.7 if boost > 0 else 1) * (bogk if bog > 0 else 1)
        v = min(cap, v + a * dt * (1 - 0.6 * min(1, v / cap))) if v < cap else max(cap, v - 4 * dt)
        boost, bog, nt = max(0, boost - dt), max(0, bog - dt), max(0, nt - dt)
        if gear < n - 1:
            k = v / (top * gears[gear])
            kind, val = shifts[gear]
            if k >= 0.96 and at < 0:
                at = t
            do = False
            if kind == "k" and k >= val:
                do = True
                if val < 0.82:
                    bog, bogk = 0.6, 0.6  # today's "early"
                elif short_bog and val < 0.96:
                    bog, bogk = 0.7, 0.55 + 0.45 * (val - 0.82) / 0.14
            elif kind == "w" and at >= 0 and t - at >= min(val, 2.5):
                do = True
                if val <= p_w:
                    boost = 1.1
                elif short_bog and val > g_w:
                    bog, bogk = 0.5, 0.8
            if do:
                gear += 1
                at = -1.0
                marks.append(round(t, 2))
        s += v * dt
    return t, v * 3.6, marks


def table(title, rows, base, ref=None):
    print(title)
    for name, kw in rows:
        a = dict(base)
        a.update(kw)
        t, v, m = run(**a)
        vs = "" if ref is None else "  %+.2f vs Tadek" % (t - ref)
        print("  %-52s %5.2f s%s  %3.0f km/h  shifts %s" % (name, t, vs, v, m))


NOW = dict(gears=[0.34, 0.57, 0.79, 1.0], pulls=[1, 1, 1, 1], top=45.0)
ok = run(launch=None, react=0.28, shifts=[("w", 0.6)] * 3, **NOW)[0]
clean = run(launch=None, react=0.35, shifts=[("w", 0.15)] * 3, **NOW)[0]
tadek = (ok + clean) / 2
print("today: ok %.2f, clean %.2f, Tadek %.2f (street_meet.gd rival_run)" % (ok, clean, tadek))
table("1. today's rules", [
    ("perfect launch, three PERFECT", {}),
    ("perfect launch, three DOBRZE 0.6 s late", dict(shifts=[("w", 0.6)] * 3)),
    ("perfect launch, three 0.9 s late", dict(shifts=[("w", 0.9)] * 3)),
    ("perfect launch, tap at the first yellow (0.82)", dict(shifts=[("k", 0.82)] * 3)),
    ("wheelspin launch, three PERFECT", dict(launch="spin")),
    ("bogged launch, three PERFECT", dict(launch="bog")),
    ("bogged launch, three DOBRZE 0.6 s late", dict(launch="bog", shifts=[("w", 0.6)] * 3)),
    ("no taps at all", dict(shifts=[("w", 2.5)] * 3)),
    ("three PERFECT, both bottles from green", dict(nitro=("t", 0.0), n_len=5.0)),
    ("bogged, three 0.9 s late, both bottles from 1 s", dict(launch="bog", shifts=[("w", 0.9)] * 3, nitro=("t", 1.0), n_len=5.0)),
], NOW, tadek)

NEW = dict(gears=[0.26, 0.44, 0.62, 0.81, 1.0], pulls=[1.0, 0.60, 0.40, 0.29, 0.22], top=56.0,
           n_accel=1.6, n_top=1.15, n_min_gear=2, p_w=0.12, g_w=0.35, short_bog=True)
D = [("w", 0.25)] * 4
table("2. the proposal: the player", [
    ("perfect launch, four PERFECT", {}),
    ("perfect launch, two PERFECT two DOBRZE", dict(shifts=[("w", 0.06), ("w", 0.25), ("w", 0.06), ("w", 0.25)])),
    ("perfect launch, four DOBRZE", dict(shifts=D)),
    ("perfect launch, four late (0.6 s)", dict(shifts=[("w", 0.6)] * 4)),
    ("perfect launch, tap at the first yellow", dict(shifts=[("k", 0.82)] * 4)),
    ("wheelspin launch, four PERFECT", dict(launch="spin")),
    ("bogged launch, four DOBRZE", dict(launch="bog", shifts=D)),
    ("no taps at all", dict(shifts=[("w", 2.5)] * 4)),
    ("four PERFECT, bottle in 1st (wheelspin)", dict(nitro=("g", 0))),
    ("four PERFECT, bottle into 3rd", dict(nitro=("g", 2))),
    ("four PERFECT, bottle into 4th", dict(nitro=("g", 3))),
    ("four PERFECT, bottle into 5th", dict(nitro=("g", 4))),
    ("four DOBRZE, bottle into 3rd", dict(shifts=D, nitro=("g", 2))),
    ("four DOBRZE, bottle into 5th", dict(shifts=D, nitro=("g", 4))),
    ("first yellow taps, bottle into 3rd", dict(shifts=[("k", 0.82)] * 4, nitro=("g", 2))),
], NEW)
table("3. the proposal: Tadek's four nights", [
    ("night 1: plain launch, shifts +0.25, no bottle", dict(launch=None, react=0.15, shifts=D)),
    ("night 1 with his missed shift (+0.9 on 3rd)", dict(launch=None, react=0.15, shifts=[("w", 0.25), ("w", 0.25), ("w", 0.9), ("w", 0.25)])),
    ("night 2: plain launch, +0.20, bottle into 4th", dict(launch=None, react=0.10, shifts=[("w", 0.2)] * 4, nitro=("g", 3))),
    ("night 3: perfect launch, P/+0.2/P/+0.2, bottle 4th", dict(shifts=[("w", 0.06), ("w", 0.2), ("w", 0.06), ("w", 0.2)], nitro=("g", 3))),
    ("night 4: perfect, P/P/+0.2/P, bottle into 3rd", dict(shifts=[("w", 0.06), ("w", 0.06), ("w", 0.2), ("w", 0.06)], nitro=("g", 2))),
], NEW)
