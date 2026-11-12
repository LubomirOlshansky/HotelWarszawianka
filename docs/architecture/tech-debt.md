# Tech debt and planned systems

Ranked by risk first (what a mistake costs a player), then by how often the debt causes bugs or
slows changes. Each row has the evidence (counted on main, 2026-11-12), the fix, and its state.
When you add a workaround, mark it in code with `# WORKAROUND(arch): ... see TD-n` and update the
row. When a fix lands, mark it done here and update extending.md. An id never changes; the order
does.

## The order (second review, 2026-11-12)

1. **Safety net** (about three days together): TD-8 safer saves, TD-14 error trap, TD-15 boot scene.
2. **Activity kit**: TD-1 (a base class and the director), with TD-2 (the target) and TD-16 (card
   owner) built into it. Activities move over one per PR, the simplest first.
3. **On top of the kit**: TD-3 offer pacer, TD-13 map marker registry.
4. **Background, any time, one PR each**: TD-4 (a) test harness out of main.gd, TD-17 save store,
   TD-11 shared fakes, TD-10 landmarks split, TD-18 check registry, TD-19 text, TD-20 pause count.
5. **Later**: TD-5 audio mixer, TD-6 and TD-7 population, TD-12 difficulty, TD-9 shader budget.

The first order (2026-11-11) ranked by what would feel best to play and put the save fifth. The
second review counted what the code repeats and where a mistake costs the most: a save that fails
to load is lost for good, so it goes first; three planned files (director, objective channel,
pacer) had one root cause, the copied activity state machine, so the base class comes before
them. The reasons and all the numbers are in the review doc of 2026-11-12 (thread "Review game
architecture"); what was decided against is in [decisions.md](decisions.md).

F picks what is built. Nothing below is started unless its state says so.

## The rows

| ID | Debt | Evidence | Fix | State |
| --- | --- | --- | --- | --- |
| TD-8 | **A damaged save becomes an empty save, and the save is written in place** | `wallet.gd` `load_save()` returns quietly when the file can't be parsed, so every field keeps its default, and the next `save()` writes those defaults over the file; `save()` ends with `cfg.save(path)` and ignores the result; `main.gd` `_remember_frame` saves about every 5 s of driving, and 15 scripts call `wallet.save()` directly | on a failed load move the file aside and try the backup, and never write over a file that wasn't read; write a temp file, then rename, and keep the last good file; one `save_soon()` (at most once every few seconds, and when the app goes to the background) in place of direct `save()`; `check_save` cases: empty, cut short, garbage, failed write | planned (step 1, first, about a day) |
| TD-14 | **No error capture on a device** | no `Logger` or `OS.add_logger` in the game; `verify.sh` finds script errors by reading the engine log, which exists on CI and the Mac but not on a tester's phone | `error_trap.gd`: a `Logger` that keeps the last 50 script errors (script, line, current activity, build); shown on the BENCH card with a copy button on test builds; every check fails on a trapped error | planned (step 1) |
| TD-15 | **The whole game compiles before the first frame** | all 490 `preload` lines point at scripts; loading `main.gd` with them took 6.3 s on one cloud CPU core (all 164 scripts 6.6 s, `landmarks.gd` alone 1.2 s); BACKLOG records about 8 s before the first frame on the Nothing Phone | a boot scene (the title picture and a script under 100 lines) that then loads the game; first one phone run to confirm the number; later `load()` at first use for rarely used scripts, and TD-10 | planned (step 1) |
| TD-1 | **No activity kit**: 15 copies of one state machine, and three answers to "is the player busy?" | 15 scripts have their own `enum State` in the same order (idle, ring, offer, stages, result); 11 their own `ring`, 15 their own beacon, 14 their own `busy()`, 12 their own autopilot; `_free_block()` in main.gd checks 15 activities, 8 private variants (`_kino_free`, `_boat_free`, `_rave_free`, `_meet_free`, `_ev_free`, `_story_free`, `_shisha_free`, `_dekalog_free`) check other subsets, `_quest_running()` checks 6 plus the stories, and the `hud.quest_on` lambda adds 6 more to that; `hud.context_now()` guesses QUEST and CHASE from widget state for `messages.gd` | `activity.gd`: a base class that owns the states, the call, the offer card, the target, abort, the log and the autopilot hook, and clears what it set when it ends. `activities.gd`: the director (register, the current one, who may start from a priority table, `context()` for `messages.gd`). Grow it from `story_quests.gd`'s registry. Pilot: the Kino and Dekalog tours (near copies, 479 and 541 lines) as one `tour.gd` and two data files | planned (step 2) |
| TD-2 | **No objective channel**: the arrow, metres, map pin and route are set by each activity | 24 scripts touch the route line or the beacon; 15 call `hud.show_status`; PR #637 fixed a missing arrow and metres from a missed `return` | part of TD-1's base class: `set_target(point, label, kind)`; HUD, minimap, beacon and camera read it; ending the activity clears it | planned (step 2, inside TD-1) |
| TD-16 | **Cards have no owner** | `hud.card_pressed(index)` goes to all 16 listeners and `abort_pressed` to 14; each decides "was that my card?"; `context_pressed(owner)` already carries its owner | `hud.show_card(..., owner)`, and the press goes to that owner only; after it `hud.gd` (4,528 lines, 109 public functions) can split along owners | planned (step 2) |
| TD-3 | **No offer pacer**: each source rings on its own clock | rescue calls, Darek's meets, trend job, rides, EV tow, guide; `hud.call_ok()` (PR #652) is the first shared gap; 11 scripts switch the rescue calls off by writing `missions.paused` (31 writes; some restore the old value, some just set false) | `pacer.gd`: quiet time after a finish, one offer at a time, variety; first-hour numbers in one file | planned (step 3), after TD-1 |
| TD-13 | **No map marker registry**: each layer has its own HUD setter that replaces a whole list | about a dozen `set_minimap_*` and `full_map.set_*` setters; `jobs.gd` and `roundup_job.gd` both write `set_minimap_pois` | `map_markers.gd`: markers declared once (layer, place, line, hours, gate); one rule table by context, vehicle and clock; minimap, full map, beacon and lists read it. Design in map-markers.md | planned (step 3), reads TD-1's context and targets |
| TD-4 | **main.gd is 9,325 lines** with 270 functions and 468 variables | `_parse_args` is 638 lines with 377 flag strings; about 25 test-only functions take about 1,660 lines; 463 wiring lines in `_build_*`; 20 copies of the `vehicle` lambda; it changed in 48 of the last 161 merges | (a) the test harness out: `dev_flags.gd` parses the flags into one object and `dev_harness.gd` holds the test-only functions, about 2,300 lines (the flag rule in CLAUDE.md and extending.md changes in the same PR); (b) each activity wires itself when it registers (TD-1) | (a) open, any time; (b) with TD-1 |
| TD-17 | **Any script can write any saved field** | 43 direct writes into the wallet's dictionaries from 15 scripts; the wallet has 38 public variables | sections with `get`, `set` and `bump`, validated in one place; callers move over a section at a time | open, after TD-8 |
| TD-11 | **Test fakes are copied** | 35 of 103 checks define their own: FakeMap 23, FakeHud 11, FakeDialogue 10, FakeBubbles 5, FakeWallet 3; a new parameter on `hud.toast` can break 11 checks; only 5 checks load the main scene | one `game/tools/fakes.gd` the checks share | open, any time |
| TD-10 | **landmarks.gd is 35,322 lines** | one file for every landmark, 977 functions; it changed in 41 of the last 161 merges and costs 1.2 s of script compile at launch | split by area into `landmarks/<area>.gd` with one shared helper file | open |
| TD-18 | **A new check is registered in three places** | `STEPS_ALL` and `STEPS_QUICK` in `tools/verify.sh` (1,222 lines, 155 case blocks) and the `--only` list in `verify.yml` | checks found by name, with a small tag for quick or full | open; belongs to the CI gate review (thread "Simplify CI gates and solo workflow") |
| TD-19 | **Most on-screen text is in code** | 1,737 string literals with Polish letters in scripts (landmark signs 456, trend job 177, rivals 118, main 75) against about 608 lines in `dialogue.json`; every toast has its English half (113 of 113), so this costs writers and reviewers, not the player | a ratchet first (the count outside sign scripts can't grow); spoken lines move to `dialogue.json` when their script is touched | open, low |
| TD-20 | **Pause has no owner count** | 9 places in main.gd set `get_tree().paused` directly; two reasons to pause at once can un-pause each other (no live bug found) | `_pause(reason)` and `_resume(reason)` over a set of reasons; paused while the set isn't empty | open, small |
| TD-5 | **Audio ducking is ad hoc** | ambience ducks under the radio in `sfx.gd`; `radio.duck_db` for the pull-over; greeting and opening clips turn the radio down themselves | a priority mixer in `sfx.gd`, like `messages.gd`: who ducks whom in one table | planned (later) |
| TD-6 | **Pedestrian slots are agreed by hand** | `pedestrians.gd`: slots 0-2 trap officers, 3 first contact, 4-11 guards, then guests, stops, scenes, each owner writes its own range | a small allocator (`reserve(owner, n)`) with a per-tier total; the start of TD-7 | planned (later) |
| TD-7 | **No shared population budget** | the governor steps traffic and walkers; crowds, city life, packs, fans, buses, trams and police each keep their own limits | one budget per tier for cars, people and props near the camera, mission actors first | planned (later) |
| TD-9 | **Building shader at the Adreno budget** | lite building shader 498 of about 508 (`check_shader_budget`) | landmarks in their own material (about 300 of the 498 are theirs) before the next building-shader feature | open |
| TD-12 | **Difficulty is per mode** | difficulty code only in `boat_race.gd` and `ladder.gd`; racer AI rebuild in progress | after race AI step 3: one soft skill estimate that race AI, timers and police heat read (no rubber band) | planned (later) |

## What is clean today, and the checks that would keep it so (proposed, not built)

These hold on main by habit. `tools/check_architecture.py` could hold them by rule in the existing
`architecture` step, for a few milliseconds:

- **Boundaries at zero**: `ConfigFile.new()` only in `wallet.gd` and `settings.gd`;
  `get_tree().paused =` only in `main.gd`; the command line read only in `release.gd` (and parsed
  in `main.gd`); `AudioServer` bus changes only in `sfx.gd`; `Input.vibrate_handheld` only in
  `haptics.gd`; no absolute node paths; no autoloads of the game's own.
- **Ratchets** (a number that may go down, not up; the PR that lowers it updates it): lines in
  `main.gd`, listeners of `card_pressed`, private `_x_free` tests, checks with private fakes,
  Polish literals outside sign scripts.

Adding them changes the gate, so it waits for F's pick and the CI gate review.

## How to know a step worked

| Measure | 2026-11-12 | Target |
| --- | --- | --- |
| Save damage cases in `check_save` | 0 | 4 |
| Script compile before the first frame | about 6.5 s (cloud core) | under 0.5 s |
| Lists that answer "is the player busy" | 3, plus 8 variants | 1 |
| Scripts that hear every card press | 16 | 0 |
| Lines in main.gd | 9,325 | under 6,000 |
| Checks with private fakes | 35 | 0 |
