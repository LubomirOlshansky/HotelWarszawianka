# Technical plans: review and revised order (2026-11-14)

**Status (2026-11-14):** a review and a proposal. No game code changed. The three plans keep
their own orders until F picks; where F agrees, the conductor of that plan moves the change into
its own page.

**Followed on 2026-11-15** by `tech-plans-review-2.md`: what became of part 1 below, what F's
picks on the map and the fences mean for the plans, and the order from there.

F (2026-11-14): "the architectural work, the AI in game, the objects on the road and the plan for
one system for walls and driving: all this technical work, revise the plan and critique."

**What was read.** `docs/architecture/` (the order and rows of `tech-debt.md`, `city-ai.md`,
`systems.md`, `extending.md`), `docs/design/city-objects-plan.md` with its two briefs
(`drivable-city-build.md`, `walls-true-to-life.md`), `docs/design/race-ai.md`, the older road and
object plans, `docs/QUESTIONS.md`, the ROADMAP's v1.0 checklist. Every number below was counted
on main `8b2e4f2d` or read from the two pull requests open at the time (#774 the pacing numbers,
merged later the same day; #776 the soft fences, with the audit's go and not merged yet),
section 7.

Contents: [1 In short](#1-in-short) · [2 Plan against main](#2-plan-against-main) ·
[3 Architecture](#3-the-architecture-plan) · [4 City AI](#4-the-city-ai) ·
[5 City objects](#5-the-city-objects-plan) · [6 Across the plans](#6-across-the-three-plans) ·
[7 Measured](#7-how-this-was-measured) · [8 Cut or park](#8-what-to-cut-or-park) ·
[9 Revised order](#9-the-revised-order) · [10 Questions for F](#10-questions-for-f)

---

## 1. In short

The three plans were built fast and with real proofs (old against new, frame by frame; hashes of
every sector; a race bench). That part is good and should not change. What is wrong is around it:

1. **The work outruns what F has felt.** 99 pull requests merged since 2026-11-11. The collision
   presets, the soft fences, the racers' last four steps, fifteen activities on the kit and the
   sector streaming have never run on a phone. `QUESTIONS.md` holds 291 waiting entries, 62 of
   them a phone check. A release build hides script mistakes (TD-21), so all of it meets a
   phone for the first time in one build.
2. **The biggest driving win is built and switched off.** Autopilot hit 16 dead stops with
   today's collision answer and 4 to 6 with the new presets (step 6). The default is still the
   old one, and the preset is a command-line flag only, so F cannot try it on a TestFlight build
   at all. A settings row would unblock it.
3. **The map cannot be baked again from scratch** (found in #759 and #776: three causes). The
   objects plan decides every type and class in the bake, and four of its next steps need a
   re-bake. This is the largest risk in all three plans and has no owner.
4. **Two files grow faster than the plans shrink them.** `main.gd` is 9,456 lines (9,325 when the
   target of "under 6,000" was set). `landmarks.gd` is 42,830 lines (35,322 two days ago); its
   split waits for "no landmark pull request open", which never happens.
5. **The fences changed the rules for the player only.** The player now drives through 1,635
   fence and hedge lines. Rivals, police chasers and town traffic do not know. Nobody has
   measured what that does to a race or a chase.
6. **The city AI plan is a racer plan.** The racers' rebuild is complete (every race, chase and
   crazy driver on one driver). Town traffic, walkers, trams and buses have no plan at all, and
   the lane graph all of them drive on still guesses its lanes (TD-23, parked).
7. **The order inside the objects plan was fixed before its own measurement existed.** The
   baseline says deck rails and piers cause 14 of 20 dead stops; the plan's next step is parked
   cars (2 of 20), and the rail and pier step is three steps later.

The revised order (section 9) puts first the work that needs no feel and no answer from F (the
bake, the two big files, honest gates), then one phone sitting, then the feel steps in the order
the measurements give.

## 2. Plan against main

| Plan | Says | Main says |
| --- | --- | --- |
| Architecture: safety net (TD-8, TD-14, TD-15) | done | done, with checks |
| Architecture: activity kit (TD-1, TD-2, TD-16) | built, all 15 scripts | true. Left: `_free_block` (140 lines) and three variants (`_story_free`, `_world_free`, `_ev_free`) plus `_quest_running` still live in `main.gd`; the "who may interrupt whom" table is not built; 2 listeners of `card_pressed` remain (16 before) |
| Architecture: offer pacer (TD-3) | step 3, "M2" | #774 moves 53 numbers into `game/data/pacing.json` with today's values. Of the pacer's rules, one offer at a time is the director's (`may_start` and the run notices of M1) and a shared gap between friends' calls exists (`calls.gap`, 60 s). Variety and a shared quiet time after a finish are not built; they are questions for F |
| Architecture: marker registry (TD-13) | step 3 | not started |
| Architecture: background rows | TD-11, TD-18, TD-20, TD-5 done | true. TD-4 (a), TD-10, TD-19, TD-22 open; TD-17 dropped by F |
| Architecture: the measures | `main.gd` under 6,000; one busy list | `main.gd` 9,456 and rising; one list plus four variants |
| City AI: racers (`race-ai.md`, 8 steps) | all done in `race-ai.md` | true (12 pull requests). `city-ai.md` still said "steps 1 to 4a of 8" and "still to come" (fixed with this review); the ROADMAP line is still unticked |
| City AI: everything else | TD-6, TD-7, TD-12 "later"; TD-23 parked | nothing built, nothing planned beyond those rows |
| City objects: stage A (steps 1 to 5) | done | true, all merged with hash and count proofs |
| City objects: stage B (6, 7, 8) | 6 merged, 7 in its pull request | 6 merged with the old answer as default; 7 has the audit's go (#776); 8 not started |
| City objects: stages C and D (9 to 16) | waiting | not started |

## 3. The architecture plan

**What is good.** The order by risk was right: the save first, then the kit. Each port was proved
against the old script on tens of thousands of frames. The shared test stand-ins and the single
list of CI steps removed real sources of conflicts.

**Critique.**

- **The plan's own measures did not move.** The kit was meant to shrink `main.gd` and leave one
  answer to "is the player busy?". After fifteen ports `main.gd` is 131 lines longer and the
  busy test still has five forms. The ports moved state machines; the wiring and the tests in
  `main.gd` stayed. Nothing holds the line count: the ratchets the plan proposes ("lines in
  `main.gd`", "private `_x_free` tests") were never built, because they "wait for F's pick".
- **The kit grew a hook per port.** About thirty were added in two days (`flown`, `is_job`,
  `cards_low`, `offer_busy`, `cards_hold`, `request_up`, `pill_call`, `rescue_calls`,
  `other_started` and more). Several of them are the missing priority table written as single
  fields. If the table is not built now, the next activity adds hook thirty-one.
- **"The offer pacer" is a name ahead of the thing.** #774 is a good, safe step (one file F can
  tune) and the director already keeps one offer at a time, but two of the row's rules are not
  built: variety, and a shared quiet time after a finish. If the row is marked done, they are
  lost. It should say which parts are done and that those two wait for F.
- **TD-4 (a) is the best value on the page and sits under "any time".** The test harness is about
  2,300 lines of `main.gd`, it changes nothing a player sees, and `main.gd` changed in 46
  commits in four days, so every thread pays for its size.
- **TD-10 is deadlocked.** The landmarks split is queued behind "no landmark pull request open",
  while the church thread lands one about every hour, each adding a hundred lines or more to
  the same file. The proof tools exist (`site_dump.gd`, `site_parity.py`). It needs a planned pause of
  the church thread, not a quiet moment that will not come.
- **TD-13 has no pressing reason.** The marker registry is a new system that touches what the
  player sees on the map, with no bug driving it. It should wait until after a phone build.
- **TD-9 will bite the objects plan.** The building shader is at 501 of 505 on Adreno. Step 9
  (heavy walls in the city mesh) must say what it adds to that shader before it starts.

## 4. The city AI

**What is good.** One driver for every race, the police chasers and the crazy drivers; no rubber
band; a bench with pass marks; each step identical to main on the old races.

**Critique.**

- **There is no plan for the town.** F asked about "traffic, pedestrians, police and the moving
  objects on the road". All the design work of the last week went to racers. Town cars still
  pick a random way at junctions on a rail; about 60 walkers react to the horn and to nothing
  else; trams, buses, crowds, packs and fans each keep their own limits (TD-7). If the city is
  to "feel alive", this is where it does not yet, and no page says what would be built.
- **The lane graph guesses, and everything drives on it.** `road_truth.py` counts 403 lanes that
  go straight on into another lane's place, 144 turn-back links, 264 of 556 turn restrictions
  ignored. A player sees this at every big junction as cars drifting across lanes. RT-2 (lane
  links from `turn:lanes`) is the one AI item that would change what ordinary traffic looks
  like, and it is parked.
- **The gates for AI are local and partly by chance.** The race marks (`race`) and the police
  soak run only on the Mac or by hand. The soak fails about one run in six on main because its
  dice come from the clock. Two marks are recorded as failing or unsteady (Pack in traffic,
  Independence on the full matrix). The rule "any change to `traffic.gd` re-runs the bench" is
  a habit, not a check.
- **`traffic.gd` is the next `main.gd`.** 5,029 lines and 130 functions, with two drivers inside
  it (the rail car and the line car, switched by `lined(d)`), and the police's search, escort
  and roadblocks still on the old one. No more behaviour should go into it without the seam
  written down.
- **Step 8 of the objects plan would give parked cars two owners.** `traffic.gd` places and
  parks them (`add_parked_car`, `park`, `lane_free`); the objects plan wants `soft_things.gd`
  to push them and remember where they rest. Town cars on rails do not see a car pushed into
  their lane. This must be decided in the brief, not found in review.
- **TD-12 (one difficulty estimate)** contradicts the racers' design, where difficulty is the
  rival's own skill. Cut it.

## 5. The city objects plan

**What is good.** One palette, the bake names each object, the car knows classes only. Stage A
changed nothing a player feels and proved it. The measuring came before the feel. Six steps
merged and a seventh accepted in about a day.

**Critique.**

- **The map cannot be rebuilt.** #776's change note: `bake_structures.py` drops `h`, `m` and `ft`
  on every wall, fence and hedge line; `bake_osm.py` never calls `road_design.apply_all`; and
  with both mended the structure solver still drifts by about 25 fills. Main's map is now a
  file nobody can make again. Steps 9, 10, 13 and the next lane-taper or road-profile pass all
  re-bake. The same note found that `build_sector` gives a different vertex count by the order
  sectors are built in (233,655 against 239,556), which weakens every hash proof.
- **The order ignores the baseline.** In the sloppy driver's 20 dead stops, deck rails taken
  nose-on are 8, piers 6, parked cars 2, small buildings 2. Fences were 18 % of contacts. The
  plan did fences first (fair: they were the easy bulk), then schedules parked cars (large, a
  new kind of moving object) before ends, corners and piers. The table should be run again
  with the `mid` preset and the soft fences, and the next step picked from it.
- **The default preset cannot be tried where it matters.** `--collide=` is a flag with "no
  setting yet". F's "phone A/B" is only possible in a device run. Until then every tester
  drives the old answer, and the plan's largest gain stays on paper.
- **A broken fence still stands.** After #776 the car passes through a fence that is still
  drawn; only debris shows it broke. The fix is the panel work of stage C (steps 11 and 12),
  which the plan places after heavy walls and behind a phone trial. Either the panel trial
  moves up, or the next build ships a fence you drive through like a ghost.
- **The player cannot tell which fence yields.** 367 lines near landmarks, 17 by hand and every
  tram railing stay hard and look the same as the ones that break. Until looks follow types,
  this reads as random.
- **`soft_things.gd` writes the car's velocity itself** (`car.vel *= keep`), so that `car.gd`
  need not be edited. The plan's own rule is the opposite: an object returns a cost and the car
  applies it. There are now two writers of the car's speed, with no `WORKAROUND(arch)` mark and
  no tech-debt row. It was done to stay out of another thread's file; it should be recorded and
  mended when step 8 or the preset change next opens `car.gd`.
- **Races and chases were not measured with a player who cuts through.** #776 says "racers,
  traffic and police are unchanged". The 37 race links and the chase balance were proved on a
  map where a hedge was a wall for both sides.
- **The ratchets of step 16 need a repeatable number.** The drive log gives 248 contacts on CI
  and 268 in the cloud container for the same run. A ratchet must name the one machine it
  holds on.
- **Stage C is the costliest part and the least tied to driving.** Nine heavy wall families,
  panels in a new shader per sector, broken looks. Only the falling panel repairs something
  the earlier steps broke. The rest is look work that belongs with the street-by-street loop.

## 6. Across the three plans

- **Feel debt.** Every plan ends its stages with "F looks on the phone", and none of those looks
  has happened since the plans began. The plans are honest about it, each in its own list:
  `QUESTIONS.md`, the conductor's notes, the next-build list. There is no single list F could
  run in one sitting, in order, in twenty minutes.
- **The same files, four lanes.** `main.gd` (every thread), `car.gd` (controls, objects),
  `traffic.gd` (racers, objects step 8), `landmarks.gd` (churches, the split). The lane rules
  work, at the cost shown in section 5: a design rule bent to avoid a file.
- **Too many pages rule the same street.** `road-objects.md` and `roads-and-objects-plan.md`
  (2026-11-04), `operation-unslop.md`, `road-design-system.md` and its rollout,
  `roads-true-to-life.md`, `lane-drops.md`, `drivable-city.md` and its build plan,
  `walls-true-to-life.md`, `city-objects-plan.md`. Two tools classify the same object
  (`street_pass.py`'s B1 to B15 with a model per object, and `object_types.py`'s `ty`). The
  ROADMAP lists the collision rework twice and the soft fences twice. `walls-true-to-life.md`
  still says the builder stays in `map_builder.gd` and names `barrier_kit.json`; both changed
  in step 2. `city-objects-plan.md` is the master; the older pages should each say in their
  first lines which of their sections it replaced, and `street_pass.py` should read `ty`.
- **No plan owns the frame.** Soft things, debris, pushed cars, panels, more racers on the line
  and the walkers' shares all draw on one phone frame. The governor scales two shares
  (traffic, people). TD-7 is the only row about it and it is "later".

## 7. How this was measured

On main `8b2e4f2d`: `wc -l` on the scripts; `grep` for `_free_block` and its variants, the
`card_pressed` and `abort_pressed` connections, `lined(`, `collide`; `tools/ci_steps.txt` for
which steps CI runs (`race` and `police-soak` are `local`); `git log --since=2026-11-11` for the
count of merged pull requests (99) and the commits per file (`main.gd` 46, `landmarks.gd` 74); the Waiting
section of `QUESTIONS.md` (291 dated entries; 62 name the phone). From the open pull requests:
#776's description and change note (the bake chain, the soft line counts, `car.vel`), #774's
`QUESTIONS.md` entry. From the plans themselves: the drive baseline in
`drivable-city-build.md` section 2, the bench table in `race-ai.md` section 8. Not measured
here: nothing was run; no claim above is about how the game feels.

## 8. What to cut or park

| Item | Verdict | Why |
| --- | --- | --- |
| TD-12 one difficulty estimate | cut | the racers' design replaced it |
| TD-3 (b) variety between callers | cut unless F asks | no complaint behind it |
| TD-3 (b) a shared quiet time after a finish | park for F's feel of the first hour | play change |
| TD-13 marker registry | park until after a phone build | no bug drives it |
| TD-6 slot allocator | park until the next renter | cheap when needed |
| Moving the race driver out of `traffic.gd` | park; write the seam into `city-ai.md` only | no race work is planned |
| More racer AI steps | closed | the eight steps are done; only its known failing marks remain |
| Objects step 9, heavy wall families as new geometry | cut down to palette rows (height, colour) | look only; shader at 501 of 505 |
| Objects step 13, gates on every yard | park; build only for traps the wander run finds | 98 % of the solid metres are on unnamed yards |
| Objects step 14 small things, step 15 content | move to the street-by-street loop | not a system |
| Road design rollout by area | already replaced by "main as base, small fixes" (2026-11-07) | say so at the top of its page |

## 9. The revised order

Three lanes, one pull request open in each, as today. Part 1 needs nothing from F and changes
nothing a player feels, so it runs now. Part 2 is one sitting. Part 3 follows the measurements.

### Part 1: now (no feel change, no answer needed)

| # | Lane | Item | Proof |
| --- | --- | --- | --- |
| 1 | map | **The bake chain makes main's map again**: the three causes in #776's note, and `build_sector` no longer depending on build order. Before any step that re-bakes | a from-scratch bake on the Mac equals main's map by `check_map_data.py` and the sector hashes |
| 2 | architecture | After #774: **TD-4 (a)**, the test harness out of `main.gd`; then, in its own pull request, the **ratchets** in `check_architecture.py` at the new numbers (lines in `main.gd`, `_x_free` tests, `card_pressed` listeners) | every check and flag as before; the line count drops by about 2,300 and cannot rise |
| 3 | architecture | **Finish TD-1**: the priority table (who may interrupt whom) in the director, `_free_block` and its variants down to one, the single-purpose hooks that the table replaces removed | old against new on the whole-game runs the missions port used |
| 4 | landmarks | **TD-10**, the split of `landmarks.gd` by area, in a planned pause of the church thread of about an hour | `site_parity.py`: no vertex moves on 1,213 sites |
| 5 | AI | **Honest gates**: the police soak with seeded dice and a pinned clock; a short seeded race in CI; the two failing marks as tech-debt rows; the seam between the two drivers written into `city-ai.md` | the soak passes ten runs in ten |
| 6 | objects | Merge #776. Then **measure**: the sloppy table again with `mid` and soft fences; a race and a chase with a player who cuts through fences; mark `soft_things`' write to the car's speed as a workaround with its row | the two tables in the plan |
| 7 | objects | **A settings row for the collision preset** (beside the experimental graphics switch), default unchanged | `check_settings`; nothing differs at the default |
| 8 | all | **One phone list**: every open phone check of the three plans in driving order, about twenty minutes | a page F can follow |

### Part 2: F's phone sitting

The presets, the smash, a ladder race and a chase, the first ten minutes with the kit's calls, the
sector streaming. It answers questions 1 to 4 of section 10 at once.

### Part 3: after it, in this order

| # | Item | Depends on |
| --- | --- | --- |
| 9 | The default preset changes; race marks recorded again | F's pick in part 2 |
| 10 | The panel trial at the stadium (objects step 11), so a broken fence falls and a fence's look says whether it yields; then panels everywhere (step 12) only if the phone's frame allows | #776; the phone |
| 11 | Ends, corners and piers (step 10) or parked cars (step 8), whichever the new table ranks first. Parked cars only after the brief names their one owner | items 1 and 6 |
| 12 | Rivals and chasers through soft lines, as race links | item 6's numbers; question 4 |
| 13 | RT-2, lane links from `turn:lanes` | question 5 |
| 14 | A one-page plan for the town: what traffic, walkers and trams should do that they do not, with a budget per tier (TD-7) | F's wish list after part 2 |
| 15 | Ratchets (step 16) on the CI machine | items 9 to 11 |

What stays as it is: one pull request per step, the audit's go, old-against-new proofs, Fable
writes briefs and judges, Opus and Sonnet build.

## 10. Questions for F

Parked in `docs/QUESTIONS.md` with these defaults. None stops part 1.

1. **Collision preset.** Add a settings row so you can switch v1, soft, mid and firm on a
   TestFlight build? Default: yes, built in part 1, the default stays v1 until you pick.
2. **Soft fences in the next build.** They break but still stand drawn until the panel work.
   Default: ship them on, so you can feel them; the other way is to hold them off until fences
   fall.
3. **The first hour's calls.** The numbers are in one file after #774. Default: nothing more is
   built (no variety rule, no shared quiet time) unless the first hour feels crowded to you.
4. **May rivals and police drive through fences too?** Default: measure first; if a player who
   cuts through gains more than a few seconds in a race or shakes a chase off at once, they get
   the same ways through.
5. **Lane links at junctions (RT-2).** You parked the road fixes on 2026-11-13. Default: stays
   parked; it is the one item that would make ordinary traffic look right at big junctions.
6. **A pause of about an hour in the church work** to split `landmarks.gd`. Default: yes, at the
   next church's merge.
7. **The marker registry (TD-13)** waits until after a phone build. Default: yes, parked.
