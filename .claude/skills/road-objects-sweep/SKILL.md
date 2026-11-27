---
name: road-objects-sweep
description: Runs the road-objects and drivability sweep of Around Warsaw street by street (docs/design/road-objects.md): census of every solid thing near the lanes, automatic rules, drive evidence from the headless checks and Autopilot, Mac orthophoto and open street-level evidence, a verdict per object, apply, verify, baseline. Use when asked to clean up objects on the roads, make a street drive better, sweep a street, or check what an object by the road is.
---

# Road-objects sweep, one street group at a time

The plan and the reasons are in docs/design/road-objects.md (read sections 1-3 and 4.5 first).
Driving first, city fidelity second. One street group per thread and PR, in the order of
section 7 (the first-10 streets, then the race routes, then the census order).

Status of the tools (2026-11-04): S1 is built (`tools/road_objects.py`); `--classify` (S2), the
contact log in `check_lane_drive` (S3), the override file `game/data/road_objects.json` and its
reader in the bake (S7-S8) and the baseline (S10) are to build. Until a stage exists, do it by
hand in the thread and say so in the PR; the first sweep thread builds what it needs.

## 1. Pick and measure (cloud)

1. The street group from the brief, or the next in section 7. Check open PRs and "In progress"
   for anything touching the same streets.
2. Census: `python3 -I tools/road_objects.py --street="NAME" --json=$SCRATCH/NAME.json` per
   street (exact OSM names; `(unnamed living_street)` style names for unnamed ways). Note the
   counts per class and band.
3. Drive evidence: `check_lane_drive.gd --only=NAME` both ways (and `--prebuilt`), with the
   contact log when it exists; the cloud Godot recipe is in memory (`cloud-godot-shots`).
   Record contacts per km, speed kept per contact, unsticks, tows (section 4.5): this is the
   "before".

## 2. Classify

1. Rules B1-B15 (section 3.3) on every row; give each a verdict and a confidence.
2. Send the street's rows, the contacts and the rules' output to the `road-auditor` agent (Opus)
   for the judgement calls; counts and log crunching to `scout` (Haiku). Say which model each used.
3. Everything below "sure" is CHECK, with the evidence it needs:
   - **orthophoto crop** (Mac: `tools/overlay_ortho.py OUT.png X Z 20` per object; the GUGiK
     orthophoto is only on the Mac);
   - **open street-level photo** (cloud: `python3 -I tools/street_photos.py X Z --r=25
     --slug=road-<street>`, Mapillary with `MAPILLARY_TOKEN` and Panoramax; Google Street View via `tools/streetview_fetch.py`);
   - **F's photo** (landmarks, tier S/A: photos only);
   - **A/B playtest** (a feel question: both versions behind a flag, Autopilot row + the numbers).
4. Ask the Mac for the orthophoto crops in ONE batch per street group (a list of crops and photo
   lookups for a Mac session), never one by one. A device or Remote Control session starts only
   in reply to F's own message.

## 3. Apply

- Verdicts go into the override file by the census id, never as hand edits of `centrum.json`.
- REMOVE / SOFTEN: the bake (`bake_structures.py`, next to `clear_carriageways`) or
  `map_builder.gd`, by id. RETEXTURE / REPLACE: a style or model from the library (section 3.4),
  one material where possible; models through `object-modeler` (Sonnet) from a spec.
- After a map change: the whole chain (`bake_sectors.py`, prebuilt sectors with a renderer, never
  `--headless`), `check_map_data.py`; both city paths.

## 4. Verify and keep it fixed

- The same drive measures after: contacts per km down, speed kept up, unsticks and tows 0. Put
  before/after in the PR.
- Every fixed spot that was a stuck or a hard stop joins `check_stuck_spots.gd`.
- Shots by day and night at the changed objects (`--at=`, `--prebuilt` too): the street must still
  read as Warsaw.
- Bench before/after when the change adds geometry, materials or colliders (the performance gate).
- A/B items get their Autopilot row (PLAYTEST P18-P20 style, under 6 minutes, F's yes for the Mac
  run) and a line in QUESTIONS for F's phone call.
- The street's numbers join the baseline once S10 exists.

## 5. Bookkeeping

BACKLOG (the street's line ticked, new finds added), ROADMAP v1.0 checklist line ticked, CHANGELOG
only for what a player sees, and the street's CHECK leftovers in QUESTIONS with the default built.
