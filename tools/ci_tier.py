#!/usr/bin/env python3
"""Picks the CI tier of a change from the paths it touches, and the verify steps that tier runs.

Usage:
    python3 -I tools/ci_tier.py PATH...          print the tier and its steps for these paths
    git diff --name-only A B | python3 -I tools/ci_tier.py --stdin [--github-output]
    python3 -I tools/ci_tier.py --full [--github-output]   the full set (pushes to main)
    python3 -I tools/ci_tier.py --check          tools/ci_steps.txt is sorted and lists every verify.sh step
    python3 -I tools/ci_tier.py --selftest       the path rules on known examples

Why: every pull request used to run the whole set (46-61 min), so eight new ride stories waited
for the road, ground and water checks they cannot break. The definition of done already has a
light and a full size (docs/WORKFLOW.md); this makes CI follow it. A change takes the highest
tier any of its paths asks for, and a path no rule knows is `full`, so a new folder is never
under-checked. Pushes to main always run the full set: that run is the net under the tiers.

    docs       text, the site, the wiki, agent files: the Python checks in the tier job only
    content    game data, dialogue, audio and art that the city build doesn't read: quick
    code       gameplay scripts and check scripts: quick + the prebuilt city (smoke)
    landmarks  landmark, model, sign and prop code and their data: code + the landmark check
    full       map data, bakes, the map builder, streaming, shaders, CI itself, anything unknown

--github-output appends tier, quick, quick_steps, map and matrix to $GITHUB_OUTPUT
(.github/workflows/verify.yml reads them).
"""
from __future__ import annotations

import fnmatch
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIERS = ["docs", "content", "code", "landmarks", "full"]

# Text and pictures under docs/ are docs; a JSON there (docs/roads/*.json feeds the road design
# bake) is not, and falls through to `full`.
DOC_SUFFIXES = (".md", ".txt", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg")
TOP_DOCS = ["*.md", "LICENSE*", ".gitignore", ".gitattributes"]  # in the repo's root only
DOCS = [
    "site/*", "wiki/*", "console/*", ".claude/*",
    # The page builders: the site and wiki workflows run them.
    "tools/site_build.py", "tools/wiki_build.py", "tools/console.py", "tools/console_page.html",
    "tools/status_page.py", "tools/changelog.py", "tools/shot_sheet.py",
]
# game/data files no city-building script reads (checked 2026-11-12 with grep over game/scripts).
CONTENT_DATA = [
    "bar_crawl", "boat_race", "brand_denylist", "cassettes", "dialogue", "districts", "eggs", "kadr",
    "palace_lights", "places", "police_guards", "police_traps", "race_bench", "race_cuts", "radio",
    "shisha", "syrenki", "taxi_stories", "then_cards",
]
CONTENT = ["game/dialogue/*", "game/audio/*", "game/art/*", "game/icon.png"] + [
    "game/data/%s.json" % name for name in CONTENT_DATA
]
# Objects built in code and the data they read: they change the city's meshes and colliders,
# not the roads or the ground.
LANDMARK_SCRIPTS = [
    "landmarks", "facade_kit", "models", "props", "storefronts", "neon_signs", "monuments", "small_buildings",
    "powisle_houses", "roof_dress", "tenement_trim", "osm_roofs", "old_town_roofs", "tarasy_screen",
    "spire_motion", "skwer_zlota", "plac_pieciu_rogow", "ratusz_hub", "rail_yard", "park_props_life",
    "park_props_play", "park_props_water", "patelnia", "places", "place", "first_scene", "tamka",
]
LANDMARKS = ["game/scripts/%s.gd" % name for name in LANDMARK_SCRIPTS] + [
    "game/data/courts.json", "game/data/eastern_wall_shops.json", "game/data/monuments.json",
    "game/data/photo_fronts.json", "game/data/small_buildings.json", "game/data/street_blocks/*",
]
# The map builder, the lane graph, streaming and what else shapes roads, ground or sectors.
MAP_SCRIPTS = [
    "map_builder", "lane_graph", "chunked_surface", "sector_streamer", "sector_proxies", "index_pack",
    "instance_buffers", "street_details", "park_details", "map_edge", "edge_roadworks",
    "centralny_ramp", "rail_cut", "tunnel_xray", "load_yield", "city_maps", "city_barriers",
]
FULL = ["game/scripts/%s.gd" % name for name in MAP_SCRIPTS] + [
    "game/shaders/*", "game/map/*", "game/tools/bake_city.gd", "tools/*", ".github/*",
]
CODE = [
    "game/scripts/*", "game/tools/*", "game/addons/*", "game/project.godot", "game/main.tscn",
    "game/export_presets.cfg",
]

# The shards of the full set: (name, groups from tools/ci_steps.txt). Each pays the map setup
# (6-12 min on a cache miss, seconds on a hit). Measured on the first run (2026-11-12, #665):
# smoke 11 min, roads 19, ground 26, landmarks 12, runs 22; a slow runner adds up to 45 %. Smoke
# with roads was the long shard (42 min with its setup), so smoke went with landmarks and water.
# Later that day (main, cache hit) that shard was the long one at 34 min beside roads at 15, so
# `water` (12 min) moved to the roads group; `firstlife` joined runs; `tunnelcut`,
# `roadworks-prebuilt`, `oldtowndrive` and `railsignals` (under a minute together) joined smoke:
# they read the sector split or the terrain, which the quick job doesn't have.
FULL_SHARDS = [
    ("smoke and landmarks", ["smoke", "landmarks"]),
    ("roads, drive and water", ["roads"]),
    ("drape and ground", ["ground"]),
    ("runs", ["runs"]),
]


def matches(path: str, patterns: list[str]) -> bool:
    """fnmatch, where `*` also crosses `/` (so "site/*" is everything under site/)."""
    return any(fnmatch.fnmatchcase(path, p) for p in patterns)


def tier_of(path: str) -> str:
    """The tier one changed path asks for."""
    path = path.strip().lstrip("./")
    # Godot's sidecar files follow the file they belong to.
    for suffix in (".uid", ".import"):
        if path.endswith(suffix):
            path = path[: -len(suffix)]
    if matches(path, DOCS) or ("/" not in path and matches(path, TOP_DOCS)):
        return "docs"
    if path.startswith("docs/") and path.endswith(DOC_SUFFIXES):
        return "docs"
    if matches(path, CONTENT):
        return "content"
    if matches(path, LANDMARKS):
        return "landmarks"
    if matches(path, FULL):
        return "full"
    if matches(path, CODE):
        return "code"
    return "full"


def tier_for(paths: list[str]) -> str:
    """The highest tier among the paths; no paths at all is `full` (nothing to go by)."""
    paths = [p for p in paths if p.strip()]
    if not paths:
        return "full"
    return max((tier_of(p) for p in paths), key=TIERS.index)


# A step CI never runs (the Mac's tools/verify.sh does): the long autopilot runs and the soaks.
LOCAL = "local"


def step_lines() -> list[tuple[str, str, str]]:
    """tools/ci_steps.txt as (step, group, flag) in the file's order; flag is "" or "slow"."""
    out = []
    for line in (ROOT / "tools" / "ci_steps.txt").read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) not in (2, 3) or (len(parts) == 3 and parts[2] != "slow"):
            raise ValueError("not 'step group' or 'step group slow': %r" % line)
        out.append((parts[0], parts[1], parts[2] if len(parts) == 3 else ""))
    return out


def steps() -> dict[str, list[str]]:
    """The steps CI runs: group -> its steps, in the file's order (the `local` group left out)."""
    groups: dict[str, list[str]] = {}
    for name, group, _flag in step_lines():
        if group != LOCAL:
            groups.setdefault(group, []).append(name)
    return groups


def verify_cases() -> list[str]:
    """The steps tools/verify.sh has a case for (its `case $s in` block), without `ios`."""
    text = (ROOT / "tools" / "verify.sh").read_text(encoding="utf-8")
    block = text[text.index("\tcase $s in\n"):]
    return [n for n in re.findall(r"^\t\t([a-z0-9][a-z0-9-]*)\)", block, re.M) if n != "ios"]


def plan(tier: str) -> dict:
    """What the verify workflow runs for a tier."""
    groups = steps()
    shards: list[tuple[str, list[str]]] = []
    if tier == "code":
        shards = [("smoke", groups["smoke"])]
    elif tier == "landmarks":
        shards = [("smoke and landmarks", groups["smoke"] + ["landmarks"])]
    elif tier == "full":
        shards = [(name, [s for g in gs for s in groups[g]]) for name, gs in FULL_SHARDS]
    quick = tier != "docs"
    return {
        "tier": tier,
        "quick": quick,
        "quick_steps": ",".join(groups["quick"]) if quick else "",
        "map": bool(shards),
        # Never empty: an empty matrix is an error even on a skipped job.
        "matrix": {"include": [{"part": n, "steps": ",".join(s)} for n, s in shards] or [{"part": "none", "steps": ""}]},
    }


def check() -> int:
    """ci_steps.txt is sorted, has no step twice, and lists exactly the steps tools/verify.sh has."""
    try:
        lines = step_lines()
    except ValueError as e:
        print("ci_tier: FAIL: %s" % e)
        return 1
    names = [n for n, _g, _f in lines]
    known_groups = {"quick", LOCAL} | {g for _, gs in FULL_SHARDS for g in gs}
    bad = sorted({g for _n, g, _f in lines} - known_groups)
    if bad:
        print("ci_tier: FAIL: unknown group(s) %s (known: %s)" % (", ".join(bad), ", ".join(sorted(known_groups))))
        return 1
    if names != sorted(names):
        print("ci_tier: FAIL: tools/ci_steps.txt is not sorted by step name")
        return 1
    twice = sorted({n for n in names if names.count(n) > 1})
    if twice:
        print("ci_tier: FAIL: listed twice: " + ", ".join(twice))
        return 1
    cases = verify_cases()
    no_case = [n for n in names if n not in cases]
    if no_case:
        print("ci_tier: FAIL: no case in tools/verify.sh for: " + ", ".join(no_case))
        return 1
    # 2026-11-12: 42 steps had a case and no CI line, so CI never ran them (24 of them short).
    no_line = [n for n in cases if n not in names]
    if no_line:
        print("ci_tier: FAIL: tools/verify.sh has a case and tools/ci_steps.txt no line for: %s "
              "(add 'name group'; group `local` keeps a step out of CI)" % ", ".join(no_line))
        return 1
    in_ci = sum(len(v) for v in steps().values())
    print("ci_tier: OK (%d steps, %d in CI in %d groups, %d local)" % (len(names), in_ci, len(steps()), len(names) - in_ci))
    return 0


def selftest() -> int:
    cases = [
        (["docs/BACKLOG.md"], "docs"),
        (["docs/changes/2026-11-12-ride-stories.md", "CLAUDE.md"], "docs"),
        (["site/src/index.html", "tools/site_build.py"], "docs"),
        (["docs/roads/marszalkowska.json"], "full"),
        (["game/data/taxi_stories.json", "docs/changes/x.md"], "content"),
        (["game/audio/nocna_fm/track1.ogg"], "content"),
        (["game/data/street_details.json"], "full"),
        (["game/scripts/hud.gd", "game/data/dialogue.json"], "code"),
        (["game/scripts/police/police_talk.gd"], "code"),
        (["game/tools/check_hud.gd", "game/tools/check_hud.gd.uid"], "code"),
        (["game/scripts/landmarks.gd", "game/scripts/hud.gd"], "landmarks"),
        (["game/data/courts.json"], "landmarks"),
        (["game/scripts/map_builder.gd"], "full"),
        (["game/scripts/map_builder.gd.uid"], "full"),
        (["game/scripts/city_barriers.gd"], "full"),
        (["game/shaders/building.gdshader"], "full"),
        (["game/map/centrum.json"], "full"),
        (["tools/verify.sh"], "full"),
        ([".github/workflows/verify.yml"], "full"),
        (["some/new/folder/file.bin"], "full"),
        ([], "full"),
    ]
    failed = 0
    for paths, want in cases:
        got = tier_for(paths)
        if got != want:
            print("ci_tier selftest: FAIL: %s -> %s, expected %s" % (paths, got, want))
            failed += 1
    for tier in TIERS:
        p = plan(tier)
        if p["map"] != (tier in ("code", "landmarks", "full")) or p["quick"] != (tier != "docs"):
            print("ci_tier selftest: FAIL: plan(%s) = %s" % (tier, p))
            failed += 1
    full = [s for row in plan("full")["matrix"]["include"] for s in row["steps"].split(",")]
    listed = [s for g, names in steps().items() if g != "quick" for s in names]
    if sorted(full) != sorted(listed):
        print("ci_tier selftest: FAIL: the full set's shards don't cover every map step once")
        failed += 1
    print("ci_tier selftest: %s (%d cases)" % ("FAIL" if failed else "OK", len(cases)))
    return 1 if failed else 0


def main() -> int:
    args = sys.argv[1:]
    if "--check" in args:
        return check()
    if "--selftest" in args:
        return selftest()
    paths = [a for a in args if not a.startswith("--")]
    if "--stdin" in args:
        paths += sys.stdin.read().splitlines()
    result = plan("full" if "--full" in args else tier_for(paths))
    print("tier: %s" % result["tier"])
    print("quick: %s" % ("yes" if result["quick"] else "no"))
    for row in result["matrix"]["include"]:
        if row["steps"]:
            print("map (%s): %s" % (row["part"], row["steps"]))
    if "--github-output" in args:
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as out:
            out.write("tier=%s\n" % result["tier"])
            out.write("quick=%s\n" % str(result["quick"]).lower())
            out.write("quick_steps=%s\n" % result["quick_steps"])
            out.write("map=%s\n" % str(result["map"]).lower())
            out.write("matrix=%s\n" % json.dumps(result["matrix"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
