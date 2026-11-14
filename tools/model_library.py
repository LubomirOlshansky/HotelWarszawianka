"""The model library: every model the game can draw, where its code is, how many the map places, and
the models a street pass asked for that don't exist yet. The dev console's Models tab reads it.

    python3 -I tools/model_library.py [--json=docs/models/library.json] [--md=docs/models/library.md] [--check]

F (2026-11-05): "there should be a step that classifies each object like the models we have in the
app; if there is such a model, use it, if not, model it and add it; there should be a database of
which models we have, also in the CRM." This is that database. It is worked out from the code each
time (nothing hand-kept but the WANTED list's reasons):

  prop        Props static builders (game/scripts/props.gd: `add_*` and mesh functions)
  instanced   map_builder.gd's shared instanced meshes (bench, bin, lamp, shelter, trees...)
              with the count the map data places
  barrier     the placed barrier types of game/data/object_palette.json "types" (the drawn style of
              OSM fences, walls, hedges; game/scripts/city_barriers.gd draws them) and the guard rail
  detail      street_details.gd, park_details.gd and monuments.gd kinds, counted in game/data
  metro       Props.add_metro_entrance forms
  vehicle     Models (game/scripts/models.gd) vehicle and people meshes
  landmark    landmarks.gd sites (one hand-built model each)
  wanted      what street passes need and the game lacks (docs/streets/*.json objects whose
              `model` is not in the library), with the streets and how many objects ask for it

Each entry: id, cat, name, about (the doc comment's first line), file:line, count (or null), used_by.
--check fails (exit 1) when a street record names a model id that is neither in the library nor
on the wanted list. Standard library only.
"""
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
S = os.path.join(ROOT, "game", "scripts")

# What a street pass may ask for that the game does not draw yet: id -> (name, why it is needed).
# A model leaves this list when its code exists (the scan then finds it under its own id, or as a
# placed palette type "barrier:<id>", as tram_railing and balustrade did on 2026-11-05).
WANTED = {
    "balustrade": ("Stair and metro balustrade (granite with a steel rail; glass for newer stations)",
                   "road-objects B5: stair walls drawn as 1.9 m grey slabs"),
    "tram_railing": ("Tram-median railing (low steel with posts)", "road-objects B2 and the library 3.4"),
    "canopy_posts": ("Canopy on posts (station, fuel, pavilion)", "road-objects B6: canopies drawn as solid blocks"),
    "jersey_barrier": ("Concrete Jersey barrier", "road-objects 3.4"),
    "yard_gate": ("Yard gate, closed and open", "road-objects B3 and B14"),
    "park_fence": ("Black steel park fence", "road-objects 3.4: park and square fences read as grey"),
}


def doc_before(lines, i):
    out = []
    j = i - 1
    while j >= 0 and lines[j].lstrip().startswith("##"):
        out.insert(0, lines[j].lstrip()[2:].strip())
        j -= 1
    return out[0] if out else ""


def scan_funcs(rel, pattern, cat, prefix, skip=()):
    path = os.path.join(ROOT, rel)
    lines = open(path, encoding="utf-8").read().split("\n")
    out = []
    for i, ln in enumerate(lines):
        m = re.match(pattern, ln)
        if m and m.group(1) not in skip and not m.group(1).startswith("_"):
            name = m.group(1)
            out.append({"id": prefix + name.removeprefix("add_"), "cat": cat, "name": name.removeprefix("add_").replace("_", " "),
                        "about": doc_before(lines, i), "file": f"{rel}:{i + 1}", "count": None, "used_by": []})
    return out


def map_counts():
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    if not os.path.exists(path):
        return {}, Counter()
    d = json.load(open(path, encoding="utf-8"))
    n = {"bench": len(d.get("benches", [])) // 3, "bin": len(d.get("bins", [])) // 3, "rack": len(d.get("bikes", [])) // 3,
         "column": len(d.get("columns", [])) // 3, "shelter": len(d.get("shelters", [])) // 3,
         "lamp": len(d.get("lamps", [])) // 2, "parked": len(d.get("parked", [])) // 4,
         "broadleaf": sum(1 for k in range(5, len(d.get("trees3d", [])), 6) if d["trees3d"][k] == 0),
         "conifer": sum(1 for k in range(5, len(d.get("trees3d", [])), 6) if d["trees3d"][k] != 0),
         "signal": len(d.get("signals", [])) // 3}
    return n, Counter(ln["k"] for ln in d.get("lines", []))


def items_count(fname):
    path = os.path.join(ROOT, "game", "data", fname)
    if not os.path.exists(path):
        return Counter()
    return Counter(it[0] for it in json.load(open(path, encoding="utf-8")).get("items", []))


def build():
    lib = []
    skip = {"box", "obox", "beam", "tri", "glow_material", "halo", "material", "fin", "family", "spec", "renew_parked", "headlight_pools"}
    lib += scan_funcs("game/scripts/props.gd", r"^static func ([a-z_0-9]+)\(", "prop", "prop:", skip)
    lib += scan_funcs("game/scripts/models.gd", r"^static func ([a-z_0-9]+)\(", "vehicle", "vehicle:", skip)
    mb = open(os.path.join(S, "map_builder.gd"), encoding="utf-8").read().split("\n")
    counts, line_kinds = map_counts()
    seen = set()
    for i, ln in enumerate(mb):
        m = re.search(r'_shared\["([a-z_0-9]+)"\] = ', ln)
        if m and m.group(1) not in seen and m.group(1) in counts:
            k = m.group(1)
            seen.add(k)
            lib.append({"id": "instanced:" + k, "cat": "instanced", "name": k.replace("_", " "), "about": doc_before(mb, i),
                        "file": f"game/scripts/map_builder.gd:{i + 1}", "count": counts.get(k), "used_by": ["centrum.json"]})
    # The placed barrier types (step 2 of the city objects plan: the looks are palette rows).
    pal = os.path.join(ROOT, "game", "data", "object_palette.json")
    pal_lines = open(pal, encoding="utf-8").read().split("\n")
    types_at = next((i for i, ln in enumerate(pal_lines) if ln.strip().startswith('"types"')), 0)
    for row in json.load(open(pal, encoding="utf-8")).get("types", []):
        if not row.get("placed"):
            continue
        k = row["id"]
        kind = "open railing" if row.get("draw") == "railing" else f"{row['thickness']} m thick"
        line = next((i + 1 for i, ln in enumerate(pal_lines) if i > types_at and f'"id": "{k}"' in ln), 1)
        lib.append({"id": "barrier:" + k, "cat": "barrier", "name": k, "about": f"{row['colour']}, {kind}, {row['height']} m high (one style for every {k})",
                    "file": f"game/data/object_palette.json:{line}", "count": line_kinds.get(k), "used_by": ["centrum.json lines"]})
    cb = open(os.path.join(S, "city_barriers.gd"), encoding="utf-8").read().split("\n")
    for i, ln in enumerate(cb):
        if ln.startswith("func build_guard_rails("):
            lib.append({"id": "barrier:guard_rail", "cat": "barrier", "name": "guard rail", "about": doc_before(cb, i),
                        "file": f"game/scripts/city_barriers.gd:{i + 1}", "count": None, "used_by": ["centrum.json guards"]})
    for rel, fname, cat in (("game/scripts/street_details.gd", "street_details.json", "detail"),
                            ("game/scripts/park_details.gd", "park_details.json", "park"),
                            ("game/scripts/monuments.gd", "monuments.json", "monument")):
        lines = open(os.path.join(ROOT, rel), encoding="utf-8").read().split("\n")
        n = items_count(fname)
        kinds = {}
        for i, ln in enumerate(lines):
            m = re.match(r'^\t\t"([a-z_]+)":\s*$', ln)
            if m and m.group(1) not in kinds:
                kinds[m.group(1)] = i + 1
        for k in sorted(set(kinds) | set(n)):
            lib.append({"id": f"{cat}:{k}", "cat": cat, "name": k, "about": "", "file": f"{rel}:{kinds.get(k, 1)}",
                        "count": n.get(k, 0), "used_by": ["game/data/" + fname]})
    pr = open(os.path.join(S, "props.gd"), encoding="utf-8").read().split("\n")
    forms = sorted(set(re.findall(r'form == "([a-z_]+)"', "\n".join(pr))))
    line = next((i + 1 for i, ln in enumerate(pr) if "func add_metro_entrance" in ln), 1)
    for f in forms:
        lib.append({"id": "metro:" + f, "cat": "metro", "name": f"metro entrance, {f}", "about": "", "file": f"game/scripts/props.gd:{line}",
                    "count": None, "used_by": ["pois subway_entrance"]})
    lm = open(os.path.join(S, "landmarks.gd"), encoding="utf-8").read().split("\n")
    start = next(i for i, ln in enumerate(lm) if ln.startswith("func build(surface"))
    for i in range(start, len(lm)):
        m = re.match(r'^\t\t\t"([a-z_0-9]+)":\s*$', lm[i])
        if m:
            fn = re.search(r"(_build_[a-z_0-9]+)\(", lm[i + 1]) if i + 1 < len(lm) else None
            about, fline = "", i + 1
            if fn:
                for j, l2 in enumerate(lm):
                    if l2.startswith("func " + fn.group(1) + "("):
                        about, fline = doc_before(lm, j), j + 1
                        break
            lib.append({"id": "landmark:" + m.group(1), "cat": "landmark", "name": m.group(1), "about": about,
                        "file": f"game/scripts/landmarks.gd:{fline}", "count": 1, "used_by": ["landmarks.gd sites"]})
        if i > start + 5 and lm[i].startswith("func "):
            break
    ids = {e["id"] for e in lib}
    # What the street passes ask for.
    asked = defaultdict(lambda: {"objects": 0, "streets": set()})
    for path in sorted(glob.glob(os.path.join(ROOT, "docs", "streets", "*.json"))):
        if path.endswith("streets.json"):
            continue
        rec = json.load(open(path, encoding="utf-8"))
        for o in rec.get("objects", []):
            mid = o.get("model")
            if mid and mid not in ids:
                asked[mid]["objects"] += 1
                asked[mid]["streets"].add(rec["slug"])
    for k, (name, why) in WANTED.items():
        if k in ids or "barrier:" + k in ids:
            continue
        a = asked.get(k, {"objects": 0, "streets": set()})
        lib.append({"id": k, "cat": "wanted", "name": name, "about": why, "file": "", "count": a["objects"],
                    "used_by": sorted(a["streets"])})
    unknown = sorted(k for k in asked if k not in ids and k not in WANTED)
    lib.sort(key=lambda e: (["wanted", "landmark", "instanced", "barrier", "metro", "detail", "park", "monument", "prop", "vehicle"].index(e["cat"]), e["id"]))
    return lib, unknown


def main():
    args = sys.argv[1:]
    opt = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in args}
    lib, unknown = build()
    if "--check" in opt:
        c = Counter(e["cat"] for e in lib)
        print("model_library counts: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())))
        if unknown:
            print("street records name models that are neither in the library nor WANTED: " + ", ".join(unknown))
            print("model_library: FAIL")
            return 1
        print("model_library: OK")
        return 0
    jpath = opt.get("--json", os.path.join(ROOT, "docs", "models", "library.json"))
    mpath = opt.get("--md", os.path.join(ROOT, "docs", "models", "library.md"))
    os.makedirs(os.path.dirname(jpath), exist_ok=True)
    with open(jpath, "w", encoding="utf-8") as f:
        json.dump({"_about": "tools/model_library.py: every model the game draws, and the ones street passes want", "models": lib},
                  f, ensure_ascii=False, indent=0)
        f.write("\n")
    c = Counter(e["cat"] for e in lib)
    md = ["# Model library", "", "Generated by `python3 -I tools/model_library.py`; do not edit by hand. The street pass's "
          "match step (docs/design/operation-unslop.md) gives every classified object a model id from this list, or a "
          "**wanted** id when the game has no such model yet.", "",
          "Counts: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())) + ".", ""]
    for cat in ["wanted", "landmark", "instanced", "barrier", "metro", "detail", "park", "monument", "prop", "vehicle"]:
        rows = [e for e in lib if e["cat"] == cat]
        if not rows:
            continue
        md += [f"## {cat} ({len(rows)})", "", "| Id | Name | In the map | Code | About |", "| --- | --- | --- | --- | --- |"]
        for e in rows:
            cnt = "" if e["count"] is None else str(e["count"])
            if cat == "wanted":
                cnt = f"{e['count']} asked ({', '.join(e['used_by']) or 'no street yet'})"
            md.append(f"| `{e['id']}` | {e['name']} | {cnt} | {e['file']} | {e['about'][:140]} |")
        md.append("")
    with open(mpath, "w", encoding="utf-8") as f:
        f.write("\n".join(md))
    print(f"model_library: {len(lib)} models (" + ", ".join(f"{k} {v}" for k, v in sorted(c.items())) + f") -> {os.path.relpath(jpath, ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
