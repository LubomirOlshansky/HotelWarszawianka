"""The drive report: the contact logs of check_lane_drive (or a game run's --contacts=FILE) per street.
    python3 -I tools/drive_report.py [NAME=]LOG.tsv [[NAME=]LOG2.tsv ...] [--top=10] [--min-km=0.25]
            [--census] [--md] [--baseline=OUT.json] [--set=A] [--seed=N]

The city objects plan, step 3 (docs/design/drivable-city-build.md, item 1). A log's lines come from
game/scripts/contact_log.gd: `contact` (one contact episode: where, the class of what was touched,
the speed going in and the lowest in the next second, the impact angle, the street, the flags
dead_stop / unstick / tow), `event` (a flag given after its episode ended: a tow) and `drive` (a
street leg: metres, seconds, seconds above 80 % of the limit).

For each log (a run: one driver, one city path, one handling) it prints, per street and overall:
km driven, contacts per km (all, and by class), the median share of the speed kept through a
contact (lowest / in, contacts at 2 m/s or more), dead stops, unsticks, tows, and the share of the
time above 80 % of the street's limit; then the ten worst streets (at least --min-km driven) by
contacts per km plus five times the stops (dead stops, unsticks, tows) per km, with the classes
that took the most speed there. `unknown` contacts (a body without a solid class) are counted and
listed: there should be none.

--census joins each contact to the census (tools/road_objects.py: the nearest object of a matching
census class within JOIN m of the contact, its `oid`), and lists the objects hit most.
--md prints the tables as Markdown (for the build plan's section 2). --baseline=OUT writes the
numbers of every run given (NAME=LOG names it) as JSON: tools/drive_baseline.json. Standard library.
"""
import json
import math
import os
import statistics
import sys
from collections import Counter, defaultdict

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
# A census object counts as what was hit within this of the contact's car centre plus the car's
# half width (the log's x, z are the car's centre, not the touch point).
JOIN = 1.5 + 1.0
# Solid classes (game/data/object_palette.json) to the census's classes (tools/road_objects.py).
CENSUS_OF = {"fence": ("barrier",), "hedge": ("barrier",), "wall": ("barrier",), "stair_wall": ("barrier",),
             "railing": ("barrier", "struct_wall"), "struct_wall": ("struct_wall",), "tunnel": ("struct_wall",),
             "portal": ("struct_wall",), "guard_deck": ("guard_rail",), "guard_ground": ("guard_rail",),
             "pier": ("pier",), "platform": ("platform",), "parked": ("parked_car",), "shelter": ("shelter",),
             "building": ("building", "small_building"), "small_building": ("small_building", "building"),
             "prop": ("street_prop", "monument", "park_piece")}
STOP_WEIGHT = 5.0


def read_log(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if not parts or parts[0] not in ("contact", "event", "drive"):
                continue
            r = {"kind": parts[0]}
            for p in parts[1:]:
                k, _, v = p.partition("=")
                r[k] = v
            rows.append(r)
    return rows


def street_name(r):
    return r.get("street") or "(no street)"


def summarise(rows, top=10, min_km=0.25, joiner=None):
    """{"overall": {...}, "streets": {name: {...}}, "worst": [...], "unknown": [...]} for one log."""
    st = defaultdict(lambda: {"m": 0.0, "s": 0.0, "fast": 0.0, "contacts": 0, "by": Counter(), "kept": [],
                              "dead": 0, "unstick": 0, "tow": 0, "water": 0, "lost": Counter(), "objects": Counter()})
    unknown = []
    joined = 0
    for r in rows:
        s = st[street_name(r)]
        if r["kind"] == "drive":
            s["m"] += float(r["m"])
            s["s"] += float(r["s"])
            s["fast"] += float(r["fast"])
        elif r["kind"] == "event":
            if r.get("flag") in ("tow", "unstick", "water"):
                s[r["flag"]] += 1
        else:
            cls = r.get("class") or "unknown"
            s["contacts"] += 1
            s["by"][cls] += 1
            v_in, low = float(r["in"]), float(r["low"])
            if v_in >= 2.0:
                s["kept"].append(low / v_in)
            s["lost"][cls] += max(v_in - low, 0.0)
            flags = [f for f in r.get("flags", "").split(",") if f]
            s["dead"] += "dead_stop" in flags
            s["unstick"] += "unstick" in flags
            s["tow"] += "tow" in flags
            s["water"] += "water" in flags
            if cls == "unknown":
                unknown.append(f"{r.get('x')},{r.get('z')} {r.get('body', '')}")
            if joiner is not None:
                oid = joiner(cls, float(r["x"]), float(r["z"]))
                if oid:
                    joined += 1
                    s["objects"][oid] += 1

    def numbers(s):
        km = s["m"] / 1000.0
        return {"km": round(km, 3), "contacts": s["contacts"],
                "per_km": round(s["contacts"] / km, 2) if km > 0 else None,
                "by_class_per_km": {k: round(v / km, 2) for k, v in sorted(s["by"].items())} if km > 0 else {},
                "by_class": dict(sorted(s["by"].items())),
                "kept_median": round(statistics.median(s["kept"]), 2) if s["kept"] else None,
                "dead_stops": s["dead"], "unsticks": s["unstick"], "tows": s["tow"], "water": s["water"],
                "fast_share": round(s["fast"] / s["s"], 2) if s["s"] > 0 else None,
                "lost_by_class": {k: round(v, 1) for k, v in s["lost"].most_common()},
                "objects": dict(s["objects"].most_common(5))}

    total = {"m": 0.0, "s": 0.0, "fast": 0.0, "contacts": 0, "by": Counter(), "kept": [], "dead": 0, "unstick": 0,
             "tow": 0, "water": 0, "lost": Counter(), "objects": Counter()}
    for s in st.values():
        for k in ("m", "s", "fast", "contacts", "dead", "unstick", "tow", "water"):
            total[k] += s[k]
        total["by"].update(s["by"])
        total["kept"] += s["kept"]
        total["lost"].update(s["lost"])
        total["objects"].update(s["objects"])
    streets = {name: numbers(s) for name, s in sorted(st.items())}
    ranked = []
    for name, n in streets.items():
        if n["km"] >= min_km and (n["contacts"] or n["dead_stops"] or n["unsticks"] or n["tows"]):
            stops = n["dead_stops"] + n["unsticks"] + n["tows"]
            score = (n["contacts"] + STOP_WEIGHT * stops) / n["km"]
            ranked.append((-score, name))
    ranked.sort()
    overall = numbers(total)
    overall["unknown"] = len(unknown)
    overall["joined"] = joined
    return {"overall": overall, "streets": streets, "worst": [name for _, name in ranked[:top]], "unknown": unknown}


def census_joiner():
    """(solid class, x, z) -> the census oid of the nearest matching object within JOIN m, or ''."""
    import road_objects as RO
    d = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json"), encoding="utf-8"))
    cell = 8.0
    grid = defaultdict(list)
    for cls, kind, pts, _level in RO.objects(d, os.path.join(ROOT, "game", "data")):
        oid = RO.oid(cls, kind, pts)
        for a, b in zip(pts, pts[1:]):
            for i in range(math.floor((min(a[0], b[0]) - JOIN) / cell), math.floor((max(a[0], b[0]) + JOIN) / cell) + 1):
                for j in range(math.floor((min(a[1], b[1]) - JOIN) / cell), math.floor((max(a[1], b[1]) + JOIN) / cell) + 1):
                    grid[(i, j)].append((a, b, cls, oid))

    def join(solid, x, z):
        want = CENSUS_OF.get(solid)
        if not want:
            return ""
        best, best_d = "", JOIN
        for a, b, cls, oid in grid.get((math.floor(x / cell), math.floor(z / cell)), ()):
            if cls in want:
                g = RO.seg_dist(x, z, a, b)
                if g < best_d:
                    best, best_d = oid, g
        return best
    return join


STREET_KEYS = ("km", "contacts", "by_class", "kept_median", "dead_stops", "unsticks", "tows", "water", "fast_share")


def write_baseline(path, runs, route_set, seed):
    """The runs' numbers as JSON, a run's overall on one line and each street on its own (diffable)."""
    j = lambda v: json.dumps(v, ensure_ascii=False, sort_keys=True)
    out = ["{", ' "_about": ' + j("tools/drive_report.py --baseline: the city objects plan's drive baseline "
                                     "(docs/design/drivable-city-build.md item 1, section 2). Per run (driver, city path, "
                                     "handling): overall and per street, km, contacts (by solid class), the median share of "
                                     "the speed kept through a contact, dead stops, unsticks, tows (out of the water), the "
                                     "share of the time above 80 % of the limit. Made by tools/drive_report.py NAME=LOG ... "
                                     "--baseline=tools/drive_baseline.json from check_lane_drive --set=A --contacts=LOG runs") + ",",
           ' "set": ' + j(route_set) + ",", ' "seed": ' + j(int(seed) if seed else None) + ",", ' "runs": {']
    names = list(runs)
    for i, name in enumerate(names):
        r = runs[name]
        overall = {k: v for k, v in r["overall"].items() if k not in ("objects", "joined", "by_class_per_km")}
        out.append(f'  {j(name)}: {{')
        out.append(f'   "overall": {j(overall)},')
        out.append(f'   "worst": {j(r["worst"])},')
        out.append('   "streets": {')
        # (Streets under 100 m with nothing on them are left out: a junction's corner, a crossing.)
        streets = [(k, n) for k, n in r["streets"].items()
                   if n["km"] >= 0.1 or n["contacts"] or n["dead_stops"] or n["unsticks"] or n["tows"] or n["water"]]
        for k, (s_name, n) in enumerate(streets):
            out.append(f'    {j(s_name)}: {j({key: n[key] for key in STREET_KEYS})}' + ("," if k + 1 < len(streets) else ""))
        out.append("   }")
        out.append("  }" + ("," if i + 1 < len(names) else ""))
    out += [" }", "}"]
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")


def fmt(v, spec=".2f"):
    return "-" if v is None else format(v, spec)


def classes_line(n, key="by_class_per_km", k=4):
    items = sorted(n[key].items(), key=lambda kv: -kv[1])[:k]
    return ", ".join(f"{c} {fmt(v, '.2f' if key == 'by_class_per_km' else '.0f')}" for c, v in items) or "-"


def print_run(name, rep, md, top):
    o = rep["overall"]
    if md:
        print(f"\n**{name}**: {o['km']:.1f} km, {o['contacts']} contacts ({fmt(o['per_km'])} per km), "
              f"speed kept median {fmt(o['kept_median'])}, {o['dead_stops']} dead stops, {o['unsticks']} unsticks, "
              f"{o['tows']} tows ({o['water']} out of the water), {fmt(o['fast_share'])} of the time above 80 % of the limit, "
              f"{o['unknown']} unknown. Contacts per km by class: {classes_line(o, k=8)}.\n")
        print("| Street | km | contacts / km | by class (per km) | speed kept | dead stops | unsticks | tows | at speed | what takes the speed (m/s lost) |")
        print("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
        for s in rep["worst"]:
            n = rep["streets"][s]
            print(f"| {s} | {n['km']:.2f} | {fmt(n['per_km'])} | {classes_line(n)} | {fmt(n['kept_median'])} | "
                  f"{n['dead_stops']} | {n['unsticks']} | {n['tows']} | {fmt(n['fast_share'])} | "
                  f"{classes_line(n, 'lost_by_class', 3)} |")
        return
    print(f"\n== {name}: {o['km']:.1f} km, {o['contacts']} contacts ({fmt(o['per_km'])}/km), kept {fmt(o['kept_median'])}, "
          f"dead stops {o['dead_stops']}, unsticks {o['unsticks']}, tows {o['tows']} (water {o['water']}), at speed {fmt(o['fast_share'])}, "
          f"unknown {o['unknown']}" + (f", joined to the census {o['joined']}" if o["joined"] else ""))
    print(f"   by class per km: {classes_line(o, k=10)}")
    print(f"   {'street':38s} {'km':>6s} {'c/km':>6s} {'kept':>5s} {'dead':>4s} {'unst':>4s} {'tows':>4s} {'fast':>5s}  classes per km")
    for s, n in sorted(rep["streets"].items(), key=lambda kv: -kv[1]["km"]):
        print(f"   {s[:38]:38s} {n['km']:6.2f} {fmt(n['per_km']):>6s} {fmt(n['kept_median']):>5s} {n['dead_stops']:4d} "
              f"{n['unsticks']:4d} {n['tows']:4d} {fmt(n['fast_share']):>5s}  {classes_line(n)}")
    print(f"   the {top} worst streets (contacts per km + {STOP_WEIGHT:.0f} x stops per km):")
    for i, s in enumerate(rep["worst"], 1):
        n = rep["streets"][s]
        objs = ", ".join(f"{k} x{v}" for k, v in n["objects"].items())
        print(f"   {i:2d}. {s}: {fmt(n['per_km'])}/km, {n['dead_stops']} dead stops, {n['unsticks']} unsticks, {n['tows']} tows;"
              f" the speed taken by {classes_line(n, 'lost_by_class', 3)}" + (f"; most hit: {objs}" if objs else ""))
    for u in rep["unknown"][:10]:
        print(f"   unknown contact at {u}")


def main():
    args = sys.argv[1:]
    if not args or "-h" in args or "--help" in args:
        print(__doc__)
        return 2
    opt = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else "") for a in args if a.startswith("--")}
    top = int(opt.get("--top") or 10)
    min_km = float(opt.get("--min-km") or 0.25)
    md = "--md" in opt
    joiner = census_joiner() if "--census" in opt else None
    runs = {}
    for a in args:
        if a.startswith("--"):
            continue
        name, _, path = a.rpartition("=")
        name = name or os.path.splitext(os.path.basename(path))[0]
        if not os.path.exists(path):
            print(f"drive_report: no log {path}")
            return 1
        runs[name] = summarise(read_log(path), top, min_km, joiner)
    if md:
        print("| Run | km | contacts / km | by class (per km) | speed kept | dead stops | unsticks | tows (water) | at speed | unknown |")
        print("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
        for name, r in runs.items():
            o = r["overall"]
            print(f"| {name} | {o['km']:.1f} | {fmt(o['per_km'])} | {classes_line(o, k=5)} | {fmt(o['kept_median'])} | "
                  f"{o['dead_stops']} | {o['unsticks']} | {o['tows']} ({o['water']}) | {fmt(o['fast_share'])} | {o['unknown']} |")
    for name, r in runs.items():
        print_run(name, r, md, top)
    unknown = sum(r["overall"]["unknown"] for r in runs.values())
    if "--baseline" in opt:
        write_baseline(opt["--baseline"], runs, opt.get("--set", ""), opt.get("--seed", ""))
        print(f"\ndrive_report: baseline of {len(runs)} runs -> {opt['--baseline']}")
    print(f"drive_report: OK ({len(runs)} runs, {sum(r['overall']['contacts'] for r in runs.values())} contacts, {unknown} unknown)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
