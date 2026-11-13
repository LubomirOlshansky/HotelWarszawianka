---
name: verify-game
description: Runs the Around Warsaw verification set with tools/verify.sh (map-data invariants, the check scripts, headless game runs with --nosave, optionally the iOS export and unsigned Xcode build) and names what it cannot prove. Use after any change under game/ or tools/, before reporting a loop or task done, and when asked "is it green?", "verify", "run the checks".
argument-hint: "[--quick | --ios | --only=step,step]"
---

# Verify a Around Warsaw change

## 1. Before running

- `pgrep -lx Godot`: if another Godot is running, someone may be measuring frame times.
  The script says so and goes on; don't start the full set beside a bench you were told about.
- Know your scope: list the files you changed (no git yet: `find game tools docs -newer <marker>
  -type f`; once the repo exists: `git status --short`). Unexpected files: stop and report.

## 2. Run

```zsh
tools/verify.sh $ARGUMENTS        # default: everything but the iOS build (~1-2 min on an M4 Pro)
tools/verify.sh --quick           # while iterating (~30 s)
tools/verify.sh --only=race,kebab # re-run just the steps that failed
tools/verify.sh --ios             # at the end of a loop: also export + unsigned xcodebuild
```

`--ios` runs `tools/export_ios.sh`, which **splits the map and rebuilds the prebuilt sectors**
(loop 3c: `game/map/sectors/*.scn`, `index.res`, `proxies.scn`) with a renderer (a window
opens): use it only when your task may change the city or at a loop's end. The `streaming`
step (loop 3c) also opens a window for a minute or two.

## 3. Read the table

- **FAIL**: open the log path in the row, read the first `ERROR` / `SCRIPT ERROR` line and
  its `at:` line, fix, re-run that step with `--only=`.
- **WARN map data / sector split missing**: a fresh clone (loop 3d-1: the derived files aren't
  committed); verify.sh runs `tools/setup_map.sh` itself when they are missing, or run it once.
  **WARN GUGiK outputs missing** (`lod2.*`, `terrain.json`): `tools/setup_map.sh --full`, which needs
  GUGiK's raw data in `data/raw` (it says what to fetch when it isn't there).
- **WARN map data / sector files or prebuilt sectors made from another ...** (their stamps' hashes
  don't match today's inputs): run
  `tools/bake_sectors.py` and/or rebuild the prebuilt sectors with a renderer (bake-map skill),
  then check the look on both paths (`--prebuilt`).
- **FAIL streaming**: the log's `PROBLEM` lines: `identity:` names the tile or kind where a sector
  differs from the whole city (a builder stage reading something outside the sector's file: widen
  bake_sectors.py's selection for it); `pixels:` the spot (`diff_NN.png`, `pair_NN.png` in the
  step's `streaming/` log folder); `soak:` missing sectors. Its streaming times are reported,
  not failed on (the Mac's move with whatever else runs on it).
- **WARN run: race / kebab / heli, no outcome line**: the autopilot didn't finish in the
  frames given. Look at the log's tail: a stuck autopilot is a bug; a longer route only needs
  more frames (edit the frame count in `tools/verify.sh` and say why).
- A **counts FAIL** after a deliberate re-bake: update `EXPECTED` in `tools/check_map_data.py`
  and the counts in DEVELOPMENT.md "Map data" in the same change, and say why they changed.

## 4. What the script does not prove (do these by hand when they apply)

| When | Do |
| --- | --- |
| Anything visible changed | `tools/shots.sh` (screenshot-review skill), then **look** at every shot; runtime and `--prebuilt` paths |
| Anything that runs per frame, or new geometry, materials, lights | bench before/after (godot-mobile-perf skill), compared with DEVELOPMENT.md "Performance budgets" |
| Controls or the car | `check_steering.gd` is in the set; the feel on the phone is the user's to judge: say what to try |
| Sound | `check_sfx.gd` checks loops; nobody has heard it on a phone: say so |
| Device-only behaviour (Metal, thermal, touch, haptics, audio session) | device-run skill, only when the user allowed it |

## 5. Gotchas

- Engine flags (`--headless --fixed-fps --quit-after --resolution --script`) go **before**
  `--`; game flags (`--nosave --prebuilt --time=` ...) go after it. Godot ignores unknown
  flags silently, so a typo'd flag just does nothing: check the log shows its effect.
- Every game run: `--nosave` and a way to quit (`--quit-after N` or `--shots=`). Autopilot runs
  never quit by themselves.
- `check_landmarks.gd` always exits 0: the script reads its `landmark check: OK` line.
- macOS has no `timeout` (the scripts use `perl -e 'alarm ...'`); never name a zsh loop
  variable `path`; `pgrep -f X` inside a wait loop matches the loop itself (use `pgrep -x Godot`).

## 6. Keep the set complete

A loop that adds a check (loop 3b added `game/tools/check_drive.gd`) adds it as a step in `tools/verify.sh` in the same change, with
its OK line, and lists it in this skill. A check that only exists outside the script gets
forgotten.

In the set now: `check_streaming.gd` (loop 3c: `streaming`, with a renderer: the sectors are the
whole city, pixels at 10 spots, a 3-minute soak; loop 3d-2b: and a helicopter and a car pass,
0 frames missing a sector in view; the loading fix: five more passes, the helicopter low and
turning, a car→helicopter switch, the start, looks at far targets and jumps, no proxy over 5 % of
the view's ground; ~13 min), `check_map_data.py` (map), `check_roads.py` (roads, loop 3a: C1-C10 over the
whole map, ~4 s; any rule FAILs (loop 3b; until then C4, C5, C9, C10 were a WARN); the counts in the
row), `check_drape.gd` (loop 3b-2: `drape`, the bare ground poking through the water, grass,
plazas and sand, from the builder's own meshes; ~10 s), `check_ground.gd` (loop 3d-2a: `ground`,
not in `--quick`: no ground left under what covers it whole, no hole where it was left out, the
ground mesh on the height rule; ~2 min), `check_drive.gd` (loop 3b: `drive` and `drive-prebuilt`: a car and a bus along every lane
against the colliders, the autopilot over 20 routes across bridges and tunnels; ~10 s and ~2 s),
`check_solids.gd` (the city objects plan step 1: `solids`, the collider faces per solid class the same
in six runtime and prebuilt sectors, their recorded total, every city collider body classed),
`check_steering.gd`, `check_settings.gd`, `check_tiers.gd` and `check_governor.gd` (loop G1:
`tiers`, model id → quality level and the pixel image's size at the phones' screens against loop
2b's rule; `governor`, the frame governor's rules on scripted frames; ~1 s each),
`check_hud.gd` (loop 2e: `hud`, the HUD at four screen sizes: 44 pt controls, 11 / 13 pt text,
the safe area, no overlaps; it lists the passing panels that waited for room),
`check_rides.gd` (loop 2d-1: `rides`, Podwózka's star and pay tables, the streak, the cancel
rules and its dialogue groups on synthetic events; under a second), `check_cost_cuts.gd`
(2026-10-30: `cost`, the index's packed arrays keep their numbers and packing twice changes
nothing; traffic's on-screen test agrees with Camera3D.unproject_position; under a second),
`check_landmarks.gd`, `check_sfx.gd`, `check_radio.gd` (radio-playlists loop: `radio`, radio.json, the Ogg tracks, the playlists, each looping station's loop point; an unknown licence is a WARN), `check_water.gd` (loop 10a:
`water` and `water-prebuilt`, where a car can get into the water, ~17 s and ~10 s) and the
game runs, among them `splash` (loop 10a: `--drive-into-water=1015,-85 --kebab=0`, the tow
within 2 s with a job running) and `ride` (loop 2d-1: `--ride=8 --passenger=believer
--ride-quirk=river --autopilot --parody-log`, a Podwózka ride to its `ride: pay` line), `ride-police`
(the same ride with a pull-over at frame 1500: exactly one star). Loop 3g-1: `police` (`check_police.gd`: the police's lines and
the conversation's flow, P11; the state machine on synthetic inputs, P12; ~1 s), `police-runs`
(P1-P7 as nine game runs on the prebuilt city, each judged by its `police:` lines and the wallet
line; ~30 s) and `police-soak` (P13, the autopilot in Busy traffic with the police on at once;
`NW_SOAK_MINUTES`, default 3, ~20 s; the full 10 minutes ~70 s).

## 7. Report

Paste the final table and the `RESULT:` line, the extra checks from section 4 you ran (with
numbers), and the ones you could not run, each with the reason.
