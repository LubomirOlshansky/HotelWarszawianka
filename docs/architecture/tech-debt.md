# Tech debt and planned systems

Ranked by how often the debt causes bugs or slows changes. Each row has the evidence (counted on
main, 2026-11-11), the fix, and its state. When you add a workaround, mark it in code with
`# WORKAROUND(arch): ... see TD-n` and update the row. When a fix lands, mark it done here and
update extending.md.

| ID | Debt | Evidence | Fix | State |
| --- | --- | --- | --- | --- |
| TD-1 | **No activity director**: "is the player busy?" is copied | `_free_block()` in main.gd checks 15 activities one by one; 8 more private variants (`_kino_free`, `_boat_free`, `_rave_free`, `_meet_free`, `_ev_free`, `_story_free`, `_shisha_free`, `_dekalog_free`), each a different subset; 14 scripts have their own `busy()` | `activity.gd`: one owner at a time with a priority and an interrupt table; activities register; buttons and offers read it. Grow it from `story_quests.gd`'s registry | planned (rank 1) |
| TD-2 | **No objective channel**: the arrow, metres, map pin and route are set by each activity | 24 scripts touch the route line or the beacon; 15 call `hud.show_status`; PR #637 fixed a missing arrow and metres from a missed `return` | `objective.gd`: one current target (point, label, kind); HUD, minimap, beacon and camera read it; ending the activity clears it | planned (rank 3) |
| TD-3 | **No offer pacer**: each source rings on its own clock | rescue calls, Darek's meets, trend job, rides, EV tow, guide; `hud.call_ok()` (PR #652) is the first shared gap | `pacer.gd`: quiet time after a finish, one offer at a time, variety; first-hour numbers in one file | planned (rank 2), after TD-1 |
| TD-4 | **main.gd is 9,280 lines** with 277 functions | every new system edits it (const, var, `_build_x`, flag, free check); threads collide there | move each activity's wiring into the activity (TD-1 makes this one registration call); one activity per PR | ongoing with TD-1 |
| TD-5 | **Audio ducking is ad hoc** | ambience ducks under the radio in `sfx.gd`; `radio.duck_db` for the pull-over; greeting and opening clips turn the radio down themselves | a priority mixer in `sfx.gd`, like `messages.gd`: who ducks whom in one table | planned (rank 4) |
| TD-6 | **Pedestrian slots are agreed by hand** | `pedestrians.gd`: slots 0-2 trap officers, 3 first contact, 4-11 guards, then guests, stops, scenes, each owner writes its own range | a small allocator (`reserve(owner, n)`) with a per-tier total; the start of TD-7 | planned |
| TD-7 | **No shared population budget** | the governor steps traffic and walkers; crowds, city life, packs, fans, buses, trams and police each keep their own limits | one budget per tier for cars, people and props near the camera, mission actors first | planned (rank 6) |
| TD-8 | **The save is written in place** | `wallet.gd` `save()` calls `cfg.save(path)` over the old file | write a temp file, then rename; keep one backup; autosave at each activity's end | planned (rank 5, half a day) |
| TD-9 | **Building shader at the Adreno budget** | lite building shader 498 of about 508 (`check_shader_budget`) | landmarks in their own material (about 300 of the 498 are theirs) before the next building-shader feature | open |
| TD-10 | **landmarks.gd is 34,700 lines** | one file for every landmark | split by area into `landmarks/<area>.gd` with one shared helper file, when a landmark thread has time | open |
| TD-11 | **Test fakes drift** | 7+ checks carry their own `FakeDialogue` / `FakeBubbles`; a new speaker param breaks them all | one `game/tools/fakes.gd` the checks share | open |
| TD-12 | **Difficulty is per mode** | difficulty code only in `boat_race.gd` and `ladder.gd`; racer AI rebuild in progress | after race AI step 3: one soft skill estimate that race AI, timers and police heat read (no rubber band) | planned (rank 7) |
| TD-13 | **No map marker registry**: each layer has its own HUD setter that replaces a whole list | about a dozen `set_minimap_*` and `full_map.set_*` setters; `jobs.gd` and `roundup_job.gd` both write `set_minimap_pois`; quest focus uses its own busy test `_quest_running()` (6 activities) beside `_free_block()` (15) | `map_markers.gd`: markers declared once (layer, place, line, hours, gate); one rule table by context, vehicle and clock; minimap, full map, beacon and lists read it. Design in map-markers.md | planned, with TD-1 and TD-2 |

## How to pick the next one

TD-8 first (small, protects testers' progress). Then TD-1, TD-2 and TD-3 as one "directors" lane,
because the pacer and the objective channel both need to know the current activity. TD-5 is a day
on its own. TD-6, TD-7 and TD-12 wait for a phone run and the racer AI step 3. The ranks match the
recommendation doc of 2026-11-11 (thread "Recommend gameplay systems to improve next").
