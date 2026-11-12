"""Fits the planner's traffic delay to the streets sampled on the race bench.

    python3 -I tools/race_traffic.py DIR

DIR holds samples_*.csv from game/tools/race_traffic.gd (tools/race_traffic.sh runs both): one
line a street of a race, with the racer's seconds there on clear roads and in the town's traffic.
The model is traffic.gd's `race_delay` (docs/design/race-ai.md 5):

    delay = density * (share * length * max(1 / RACE_STUCK_SPEED - 1 / v, 0)
                       + RACE_STUCK_END + RACE_STUCK_LIGHTS * lights)

with one share for a one-lane one-way street (no way past), one for a one-lane street with an
oncoming road and one for a street with several lanes. Prints, from the samples: the delay a
kilometre by rival and traffic level, the draw-to-draw spread of a race's time (what no model can
know), the shares, end and lights fitted by least squares at a few speeds behind a town car, and
how well the numbers now in game/scripts/traffic.gd give a race's time in traffic (by rival, level
and course, and with each course left out of the fit in turn).

Not a check: read the last lines, and move the constants in traffic.gd (and the figures in its
comment and in docs/design/race-ai.md) when the fit has moved, which it does whenever the way a
racer passes the town's cars changes. Standard library only. Exit 0; 2 without samples.
"""
import collections
import csv
import glob
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAFFIC = os.path.join(ROOT, "game", "scripts", "traffic.gd")
# The speeds behind a town car tried (m/s); traffic.gd's own is always among them.
SPEEDS = (6.0, 8.0, 10.0, 12.0)
TERMS = ("no way past", "oncoming road", "several lanes", "street's end", "a light")


def constants():
    """RACE_STUCK (three shares), RACE_STUCK_SPEED, RACE_STUCK_END, RACE_STUCK_LIGHTS of traffic.gd."""
    text = open(TRAFFIC, encoding="utf-8").read()

    def one(name):
        m = re.search(r"^const %s := (.+)$" % name, text, re.M)
        if m is None:
            raise SystemExit("race_traffic: no `const %s` in game/scripts/traffic.gd" % name)
        return m.group(1)

    shares = [float(x) for x in one("RACE_STUCK").strip("[]").split(",")]
    return shares, float(one("RACE_STUCK_SPEED")), float(one("RACE_STUCK_END")), float(one("RACE_STUCK_LIGHTS"))


def read(folder):
    rows = []
    for path in sorted(glob.glob(os.path.join(folder, "samples_*.csv"))):
        with open(path, encoding="utf-8") as f:
            for r in csv.DictReader(f):
                rows.append({
                    "race": (r["course"], r["rival"], int(r["level"]), int(r["seed"])),
                    "density": float(r["density"]),
                    "lanes": int(r["lanes"]), "twoway": int(r["twoway"]), "lights": int(r["lights"]),
                    "len": float(r["len"]), "v": float(r["v"]),
                    "clear": float(r["clear_s"]), "lost": float(r["traffic_s"]) - float(r["clear_s"]),
                })
    return rows


def features(r, speed):
    """The model's five terms for one street, each for a weight of 1 (TERMS' order)."""
    along = r["density"] * r["len"] * max(1.0 / speed - 1.0 / r["v"], 0.0)
    one = r["lanes"] == 1
    return (along if one and not r["twoway"] else 0.0, along if one and r["twoway"] else 0.0,
            along if not one else 0.0, r["density"], r["density"] * r["lights"])


def solve(a, b):
    """Gauss-Jordan with pivoting; a term the samples never use comes out 0."""
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for i in range(n):
        p = max(range(i, n), key=lambda k: abs(m[k][i]))
        m[i], m[p] = m[p], m[i]
        if abs(m[i][i]) < 1e-12:
            continue
        for k in range(n):
            if k != i:
                f = m[k][i] / m[i][i]
                for j in range(i, n + 1):
                    m[k][j] -= f * m[i][j]
    return [m[i][n] / m[i][i] if abs(m[i][i]) > 1e-12 else 0.0 for i in range(n)]


def fit(rows, speed):
    n = len(TERMS)
    a = [[0.0] * n for _ in range(n)]
    b = [0.0] * n
    for r in rows:
        x = features(r, speed)
        for i in range(n):
            b[i] += x[i] * r["lost"]
            for j in range(n):
                a[i][j] += x[i] * x[j]
    return solve(a, b)


def errors(rows, weights, speed):
    """Race -> the model's error of its time in traffic, as a share of that time."""
    total = collections.defaultdict(lambda: [0.0, 0.0, 0.0])
    for r in rows:
        t = total[r["race"]]
        t[0] += r["lost"]
        t[1] += sum(w * x for w, x in zip(weights, features(r, speed)))
        t[2] += r["clear"]
    return {race: (t[1] - t[0]) / (t[2] + t[0]) for race, t in total.items()}


def rms(values):
    values = list(values)
    return math.sqrt(sum(v * v for v in values) / len(values)) if values else 0.0


def mean(values):
    values = list(values)
    return sum(values) / len(values) if values else 0.0


def grouped(errs, part):
    by = collections.defaultdict(list)
    for race, e in errs.items():
        by[race[part]].append(e)
    return " | ".join("%s %+.1f %% (rms %.1f)" % (k, 100.0 * mean(v), 100.0 * rms(v)) for k, v in sorted(by.items()))


def main():
    if len(sys.argv) != 2:
        print("usage: python3 -I tools/race_traffic.py DIR")
        return 2
    rows = read(sys.argv[1])
    if not rows:
        print("race_traffic: no samples_*.csv with samples in %s" % sys.argv[1])
        return 2
    shares, speed_now, end_now, lights_now = constants()
    now = shares + [end_now, lights_now]
    races = {r["race"] for r in rows}
    print("race_traffic: %d street samples of %d races in traffic (%d courses, %d rivals)" % (
        len(rows), len(races), len({k[0] for k in races}), len({k[1] for k in races})))

    # What the traffic costs, as measured: seconds a kilometre by rival and level.
    lost = collections.defaultdict(float)
    metres = collections.defaultdict(float)
    density = {}
    for r in rows:
        key = (r["race"][1], r["race"][2])
        lost[key] += r["lost"]
        metres[key] += r["len"]
        density[r["race"][2]] = r["density"]
    levels = sorted(density)
    print("the delay a kilometre (s), at density " + ", ".join("%.2f" % density[l] for l in levels) + ":")
    for rival in sorted({k[0] for k in lost}):
        print("   %-16s %s" % (rival, "  ".join("%5.1f" % (1000.0 * lost[(rival, l)] / max(metres[(rival, l)], 1.0)) for l in levels)))

    # The town's draw of cars: the spread of one race's time over its draws, by level.
    time = collections.defaultdict(float)
    for r in rows:
        time[r["race"]] += r["clear"] + r["lost"]
    draws = collections.defaultdict(list)
    for race, t in time.items():
        draws[race[:3]].append(t)
    for l in levels:
        spread = []
        for key, v in draws.items():
            if key[2] == l and len(v) >= 2:
                m = mean(v)
                spread.append(math.sqrt(sum((x - m) ** 2 for x in v) / (len(v) - 1)) / m)
        if spread:
            print("level %d: one race's time moves %.1f %% with the draw of the town's cars (%d rival-courses, at most %.1f %%)" % (
                l, 100.0 * mean(spread), len(spread), 100.0 * max(spread)))

    # The fit, at a few speeds behind a town car.
    print("least squares, by the speed behind a town car (shares: %s):" % ", ".join(TERMS))
    best = None
    for speed in sorted(set(SPEEDS) | {speed_now}):
        w = fit(rows, speed)
        e = errors(rows, w, speed)
        line = (rms(e.values()), speed, w, e)
        if best is None or line[0] < best[0]:
            best = line
        print("   %4.1f m/s: %s | a race's time to %.1f %% (bias %+.1f %%)" % (
            speed, " ".join("%.3f" % x for x in w), 100.0 * line[0], 100.0 * mean(e.values())))
    w = fit(rows, speed_now)
    e = errors(rows, w, speed_now)

    # Each course left out of the fit in turn: the numbers are not the courses' own.
    out = []
    for course in sorted({k[0] for k in races}):
        w2 = fit([r for r in rows if r["race"][0] != course], speed_now)
        out.extend(errors([r for r in rows if r["race"][0] == course], w2, speed_now).values())
    print("at traffic.gd's %.1f m/s: fitted %s, a race's time to %.1f %%; with its own course left out of the fit %.1f %%" % (
        speed_now, " ".join("%.3f" % x for x in w), 100.0 * rms(e.values()), 100.0 * rms(out)))

    # The numbers in the game now.
    e_now = errors(rows, now, speed_now)
    print("traffic.gd now: RACE_STUCK %s at %.1f m/s, RACE_STUCK_END %.2f, RACE_STUCK_LIGHTS %.2f" % (shares, speed_now, end_now, lights_now))
    print("   by rival:  " + grouped(e_now, 1))
    print("   by level:  " + grouped(e_now, 2))
    print("   by course: " + grouped(e_now, 0))
    parts = [0.0] * len(TERMS)
    for r in rows:
        for i, x in enumerate(features(r, speed_now)):
            parts[i] += now[i] * x
    print("   the delay by term: " + ", ".join("%s %.0f %%" % (TERMS[i], 100.0 * parts[i] / max(sum(parts), 1e-9)) for i in range(len(TERMS))))
    print("race_traffic: traffic.gd's numbers give a race's time in traffic to %.1f %% (bias %+.1f %%); the fit's own %.1f %%, the best speed tried %.1f m/s (%.1f %%)" % (
        100.0 * rms(e_now.values()), 100.0 * mean(e_now.values()), 100.0 * rms(e.values()), best[1], 100.0 * best[0]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
