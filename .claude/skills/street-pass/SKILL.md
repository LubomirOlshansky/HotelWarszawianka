---
name: street-pass
description: Runs Operation Unslop on one street block of Around Warsaw (docs/design/operation-unslop.md): score the road surface, markings, lane splits, trees, props and barriers with tools/street_pass.py, classify every object and match it to a library model (tools/model_library.py), gather fresh evidence (Mapillary/Panoramax in the cloud, orthophoto on the Mac), fix, verify with before/after shots, and keep the street's record so the dev console shows progress. Use when asked to unslop, clean up, prettify or fix a street, its markings, lanes, trees, barriers or the buildings along it.
---

# Street pass: one street block at a time

The plan: docs/design/operation-unslop.md. It merges the earlier plans and does not replace them:
docs/design/roads-and-objects-plan.md (RS1-RS9 road shapes, the object budget, section 3a "log
everything, add only what earns its place") and docs/design/road-objects.md (verdicts, rules
B1-B15, collisions). One street block per thread and PR. The first street was Marszałkowska,
Rondo Dmowskiego to Świętokrzyska (`marszalkowska-centrum`, 70 → 83 on 2026-11-05).

## The pipeline at a glance (who does what, how long)

Quality comes from the gates (section 5), not from who types: every step below keeps its gate.
The coordinator picks the thread's model; only the main session spawns agents; a cheaper run that
fails its gate or comes back with open questions is re-run one tier up, not patched.

| # | Step | Tool (one call each) | Model | Time |
| --- | --- | --- | --- | --- |
| 0 | Claim the area, define the street | streets.json by hand | thread (Sonnet ok) | 10 min |
| 1 | Measure, record the baseline | `street_pass.py --street=SLUG --write` | thread | seconds |
| 2a | Evidence pack: newest photos per block side and per CHECK object | `street_pass.py --street=SLUG --photos` | `street-scout` (Haiku) | ~1 min |
| 2b | Block probe: ways, lines, zebras, objects, findings with causes | `street_pass.py --street=SLUG --dump[=BLOCK]` | `street-scout` (Haiku) | seconds |
| 2c | Orthophoto crops (Mac) | `overlay_ortho.py` | Sonnet (`qa-tester`) | minutes |
| 2e | Target image, once per block (optional) | Codex on the Mac from the block's camera shot | Sonnet runs, F may veto | ~3 min, ~25k Codex tokens |
| 3 | Audit: today's street vs the game, causes, verdicts, wanted models, the look pass and flags | reads 2a-2c, looks at the photos and shots | `street-unslopper` (Opus) | ~10 min |
| 4a | A bake rule (lanes, zebras, tapers, surface) | `bake_roads.py`, `bake_osm.py` | Opus (main or `map-engineer`) | |
| 4b | Overrides, verdicts, `--apply`, docs, record | `street_pass.py --apply --write` | Sonnet | |
| 4c | A wanted model from a written spec | game code | `object-modeler` (Sonnet), Opus accepts | |
| 5 | Re-bake (Mac), checks, after shots | `bake_all.sh --roads`, `--spots=` | Sonnet runs, Opus judges a rising class | ~10 min |
| 6 | The look of the street, A/B calls | shot sheet, phone | Opus + F | |

**Rounds, not tweaks** (smooth-roads review, 2026-11-05: one 9-hour thread, the full chain after
every tweak). A round is: one defect list with `--at=X,Z` (flags), one batch of rule changes, one
bake, one shot run at the fixed cameras, one review. Iterate in the cloud on the touched block with
`verify.sh --roads` and `--shots=60`; run `verify.sh --quick`, the prebuilt `bake_city` and both
city paths once at the end of the round. **One thread per round** (or per junction): close it with a
15-line handoff note in the street's record (done, open flags, cameras, commands, guesses) and start
the next round fresh; a long thread pays for its whole history on every call. Every report carries
a time-per-step line, so the slowest step is named, not guessed.

Escalate Sonnet to Opus when a score class grows, a check fails twice, or a spec needs a choice
(a lane count, a verdict). Haiku never edits and never judges: it fetches, counts and tables.

## 0. Claim and define

1. Check open PRs, "In progress" in docs/QUESTIONS.md and the project's other threads for the
   same area. A place another thread models (a square, a landmark) goes into the street's
   `owned` list: findings there are listed, never scored, never fixed by you.
2. Add the street to `docs/streets/streets.json`: its frame (`o`, `s`, `t` unit vectors: along
   and across), the box, `street_t` (the carriageways), blocks between junctions, `owned`,
   `changed` and `fresh_since`.
   - **changed**: every place rebuilt after the data was drawn (a car-free street, a new square,
     a rebuilt junction). OSM, the 2023 GUGiK scan and the orthophoto can be older than the
     street. A finding in a changed zone is not fixed until a fresh photo shows today's street.
   - **fresh_since**: street photos older than this are history, not evidence.

## 1. Measure (cloud, seconds)

```zsh
python3 -I tools/street_pass.py --street=SLUG --write    # record + baseline (first write)
python3 -I tools/model_library.py                        # refresh the model database
```

The record (`docs/streets/SLUG.json` and `.md`) holds the score per block, the findings
(L1 lane step, L2 loose lane line, L3 line on a kerb, L4 line through a zebra, T1 tree on the
drawn road, P1 prop on the drawn road, O1 solid within 1 m of a lane), every object within 3 m of
a lane with its rule, verdict and **model**, and the history with the score per block (the
console's City map colours each block by it).

## 2. Evidence: one pack, newest first

- **Evidence pack** (cloud, one call): `street_pass.py --street=SLUG --photos` writes
  `docs/streets/SLUG-photos.md`: the newest Mapillary and Panoramax photos for each block on
  both carriageways and for every CHECK object, with id, date and fresh yes/no, and prints the
  spots with no fresh photo (that list is what to ask F for). Fetch images only for the rows
  you will look at: `street_photos.py X Z --r=25 --max=3 --slug=road-SLUG-<spot>`.
- **Block probe** (cloud, one call per block): `street_pass.py --street=SLUG --dump=B` prints in
  s/t: the ways (direction, lanes, width, offset), every line's s range, zebras and cycle
  crossings, junction nodes, objects with verdict and model, findings with status, and the
  cause of each check. Never load centrum.json by hand to find these.
- **Orthophoto** (Mac): `tools/overlay_ortho.py` crops per block. The flight date is not
  logged (only the download date): say so in every note, and treat any `changed` zone as newer
  than the photo. Overlay crops hide paint: read arrows and zebras on a plain crop.
- **F's photos** and the Mac photo gather: landmarks and anything tier S/A (the photos-only rule).
- Mapillary detections (`tools/street_features.py --street=NAME`) count objects per stretch.
  Their positions are 10-20 m off, so use them as evidence, never as coordinates.

Google Street View is allowed as reference (`tools/streetview_fetch.py`, F 2026-11-26). Nothing from a photo is traced or shipped.

## 2d. Look pass and F's flags

The checks measure lanes and objects within 3 m of a lane; slop also lives in levels, walls,
stubs and behaviour (F's first phone look at Marszałkowska found 8 things the checks missed).
So every pass ends its evidence step with a look: the `--spots` shots of each block and the 30 m
either side, next to fresh photos, by the six classes in the agent file (walls that read wrong,
level changes drawn flat, asphalt stubs and ragged edges, lane jumps, people where they
shouldn't be, objects missing or doubled). Each item becomes a **flag** in streets.json
(`flags`: id, x, z, what, should, `approx` when the place is read off a screenshot, `done` when
fixed): check **F1**, 3 points each, so the score and the console show it until it is closed.
A screenshot F circles becomes flags the same day. A class seen twice becomes a check or a rule.

## 2e. Target image (optional, once per block)

The look moved most when the round had a picture to aim at (F's ChatGPT image of Marszałkowska ×
Złota, 2026-11-05). Make one per block, before the work, never inside the loop:
1. Shoot the block's camera (`street_pass.py --street=SLUG --spots`, no HUD, phone size).
2. On the Mac (F approves the quota use for the loop): prompt on stdin, the shot as `-i`:
   `codex exec --skip-git-repo-check -s workspace-write -i SHOT.png < prompt.txt`, asking it to
   keep the camera, palette, pixel density and buildings and to make the roads read as real
   Warsaw streets, and to save the PNG in the current folder. Add an orthophoto crop or F's photo
   as a second `-i` for Warsaw specifics. Save as `refs/SLUG/target-BLOCK.png` (gitignored).
3. The auditor turns it into a priority list with places, and checks each item against facts.

Limits: it invents things (a Palace of Culture in the wrong place, traffic lights OSM doesn't have),
so it is a target, never evidence; nothing from it is traced or shipped (original art). A built
item no fact supports is a **guess**: tag it template-default in the report and the record, so a
photo can confirm or remove it later.

## 3. Classify and match (the model step)

Every object gets a verdict (KEEP, RETEXTURE, REPLACE, SOFTEN, REMOVE, CHECK, A/B) and a model id.
- The model id comes from `docs/models/library.json` (console "Models" tab). Reuse a model that
  exists, even with a new colour, before asking for a new one.
- When nothing fits, the id is a **wanted** model (`WANTED` in tools/model_library.py, with
  the reason). The library lists how many objects on which streets ask for it, so the most-wanted
  model is built first, once, for every street. Hand it to `object-modeler` (Sonnet) with a spec
  from the photos, and Opus accepts it. When its code exists, remove it from WANTED.
- A hand call goes into the street's `decisions` in streets.json (id → verdict, model, evidence).
  Add a rule to `classify()` when you decide the same thing by hand twice.
- F's object rule: signs, poles, junction boxes, cones and CCTV are logged, never placed. A/B
  items (feel calls such as solid or soft median fences) go to F on the phone.

## 3b. Wall sweeps: a line's type by id (walls doc section 5, W10)

A wall, fence or hedge whose type (`ty`, tools/object_types.py) the photos show to be wrong gets
a TYPE decision: `"<stable id>": ["TYPE", "<ty>", "<what the photo shows>", "<photo URL or file>",
"<YYYY-MM-DD the photo was taken>"]`, in the street's `decisions`, or in a place's (`places` in
streets.json: `slug`, `title`, `at` [x, z], `r`, `decisions`) when the line is not on a street with
a record (a square, a yard, a riverbank). Rules:
- one line per decision, only on a photo you looked at (newest first; date recorded); KEEP and
  CHECK lines go into the sweep's verdict table, not into streets.json;
- the type is one of object_types.TYPES with a `looks` row in the palette; when no row fits what
  the photo shows, stop and ask (a new row is a design call), never pick the nearest;
- then `street_pass.py --apply` (writes road_objects.json `types`; the hand-kept entries stay),
  raise `VERSION` in tools/object_types.py by one (the guarded pass runs once more on main's map),
  `python3 -I tools/object_types.py apply` (only the decided lines change: check the diff of
  `lines`), `street_pass.py --check` and `check_post_passes.py`, then the map chain (bake_sectors,
  bake_city with a renderer, check_map_data: the default share only goes down, record it);
- a stable id two lines share (an OSM outline mapped twice) types both: say so in the reason.

## 4. Fix, in this order

The cause map (also printed by `--dump` and by a failing `--check`):

| Check | Where it comes from | Fix |
| --- | --- | --- |
| L1 lane step | `bake_roads.py bake_lane_lines`: each OSM way painted on its own | chain the carriageway, taper 20-30 m (RS3) |
| L2 loose line | `_paint_along` / `_crossed`: a cut nothing explains | continuity rule; a cut at a zebra is intended |
| L3 line on kerb | kerbs and paint read different `w` / `c` | one width source |
| L4 line through zebra | `_crossed` | zebras cut lines (ZEBRA_HALF + ZEBRA_GAP), done 2026-11-05 |
| T1 tree on road | the drawn strip covers a real median or pavement | narrow the strip, map the median |
| P1 prop on road | `snap_props` / street_details | snap clear |
| O1 solid near lane | the barrier's verdict | `decisions` + `--apply` (road_objects.json) |

1. **Lanes and markings**: lane counts and widths that match today's street, a taper instead
   of a step, one continuous line per lane boundary, arrows only on lanes that go there. Fix at
   the source (a bake rule, for the whole map) when the cause is a rule. Fix by an override keyed
   to the street when the cause is outdated OSM. Never hand-edit centrum.json without a script
   that re-applies it after a re-bake (the tools/car_free.py pattern).
2. **Trees and props on the drawn road**: when the scan shows a real median tree, the road
   surface is wrong, not the tree.
3. **Objects**: the verdicts by stable id (class, kind, 2 m cell), so a re-bake keeps them:
   `street_pass.py --apply` writes game/data/road_objects.json, map_builder draws it.
4. **Buildings along the street**, by the ladder in the plan (section 3). Landmarks go the
   photo-way. Ordinary fronts get a kit read from fresh street photos. Everything else keeps the
   data baseline.

**Batch the rule changes; one bake per batch.** A bake rule ships with its check change and a
tiny test in the same commit (the zebra cut first raised L2 16 → 40 because the check read every
cut as loose; that would have shown in the cloud before the Mac bake).

## 5. Re-bake, shots, gates

Re-bake on the Mac (raw OSM is not in the cloud):
- `zsh tools/bake_all.sh --roads` when only road or marking rules changed: it keeps the prepared
  data, terrain, trees and LoD2 and runs OSM pass 2, AO/lights/water and the split. A changed raw
  input or terrain: the full chain. Every step prints its time.
- Bakes write only inside the worktree: a `data/` symlink to the main checkout must not receive
  the worktree's `data/work` output.

Shots, one run for all cameras (the city is built once, ~70 s; was one launch per camera). The
cameras are fixed per street (`cameras` in streets.json: one per block plus every junction F has
looked at); `street_pass.py --street=SLUG --spots` prints the argument, so every round shoots the
same views. 30-60 frames are enough for a still (240 was 4x the cost for nothing):
```zsh
godot --path game --resolution 2532x1170 -- --nosave --nohud --no-traffic --shots=30 \
  --out=shots/unslop/SLUG_after "$(python3 -I tools/street_pass.py --street=SLUG --spots | tr -d '"')" \
  --time=day --size=70
```
Files are `NAME_0030.png`; the run makes `--out` if missing and exits 1 when a PNG can't be
written. Use the same `--spots` string before and after, and `--prebuilt` for the blocks you
changed. Open every shot you report: a shot nobody looked at is not evidence.

The gates (none is skipped to save time):
- `python3 -I tools/street_pass.py --check`: the ratchet. No class may grow on any street with a
  record. **A class that rises after a re-bake is a rule bug until shown otherwise**: the check
  prints the suspect rule. Re-record with `--write` only on purpose and say why in the PR.
- `python3 -I tools/check_map_data.py` and `tools/check_roads.py` after any re-bake; new counts
  only on purpose.
- `python3 -I tools/model_library.py --check`: every model id a record names exists or is WANTED.
- While iterating: `zsh tools/verify.sh --roads` (map data, road rules, street records, models,
  smoothing ratchet, drive, stuck spots; minutes, not the ~100-step `--quick`). Once per round and
  before the PR: `--quick` in the background, both city paths. A docs-only commit: `--only=` the
  steps it touches. The map jobs on CI must be green.
- A finding in a `changed` zone, or read off a crop with an unknown flight date, is listed, never
  called fixed.
- `python3 -I tools/shot_sheet.py BEFORE AFTER` as the PR's one review sheet; bench before and
  after for anything that adds geometry, materials or lights.

## 6. Record and report

`--write` again (stage: `baseline` → `evidence` → `fixed` → `accepted` when F says so; set
`stage` in streets.json). The PR shows the score before and after per block, the verdict counts,
the wanted models, the CHECK and A/B list for F, the no-fresh-photo spots, and the shot sheet.
Tick the street's line in ROADMAP and the Unslop item in docs/plan/city-plan.json. The dev console
shows all of it: Streets and Models tabs, and the City map's "Unslop only" view with each block
coloured by its score.
