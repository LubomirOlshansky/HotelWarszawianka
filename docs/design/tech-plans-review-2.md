# The plans in flight: second review and revised order (2026-11-15)

**Status (2026-11-15):** a review of the work running now, and the changes it makes to the plans.
No game code changed. It follows `tech-plans-review.md` (2026-11-14, #777) and does not repeat it:
section 2 says what became of that review's order, the rest is new.

F (2026-11-15): "make the review of plans of actual tasks with Fable and critique, then enhance
plans."

**What was read.** Main `3747f033`. The open pull requests #778 (bake chain), #779 (torn roads),
#789 (a convent). `docs/design/city-objects-plan.md` and the brief of its step 8a; the TD-4 plan
(a1 merged as #781, a2 being built); `docs/architecture/tech-debt.md` and `city-ai.md`;
`docs/design/churches.md`; the ROADMAP's v1.0 checklist; the Waiting list of `QUESTIONS.md`;
the change notes of #776 and #780. Nothing was run; no claim below is about how the game feels.

Contents: [1 In short](#1-in-short) · [2 The first review, a day later](#2-the-first-review-a-day-later) ·
[3 The map](#3-the-map-what-fs-pick-means) · [4 City objects](#4-city-objects-step-8-and-after) ·
[5 Architecture](#5-architecture-a2-the-ratchets-the-landmarks-file) · [6 Churches and landmarks](#6-churches-and-landmarks) ·
[7 The town](#7-the-town-a-first-outline) · [8 The build](#8-the-build-is-the-plan-nobody-owns) ·
[9 Over- and under-planned](#9-over--and-under-planned) · [10 Revised order](#10-the-revised-order) ·
[11 For F](#11-for-f)

---

## 1. In short

1. **The gap between main and a phone got wider, not narrower.** The first review's first
   finding was that the work outruns what F has felt. Since then 14 more changes landed on main
   (34 since the morning of 2026-11-14) and no build was cut. `QUESTIONS.md` holds 294 waiting entries (291 a day ago), 64 of them a
   phone check. The one page F could follow in a sitting (the first review's item 8) was never
   written; the list lives as a paragraph in the coordinator's notes. This page adds it:
   `docs/PHONE-CHECK.md`.
2. **F's pick on the map has a consequence no plan states.** Main's map stays the base, so even
   after #778 a from-scratch bake does not give main's map (28 of 70 keys still differ). "Wait
   for the bake chain, then re-bake" therefore has no meaning. The honest rule is: **the map
   changes only by small, guarded passes on main's file**, and the OpenStreetMap data stays at
   its present extract until a planned re-stamp. Five waiting steps must be rewritten to that
   shape (section 3).
3. **The testers' default became the slow path.** With fences hard, which is what every tester
   gets, each sector that streams in rebuilds its fence and hedge colliders on the main thread
   (#780's own note). Step 8a puts parked cars behind the same switch. The players who do not
   have the feature pay for it at every sector load, and that path has never run on a phone.
4. **One workaround is growing into a second collision system.** `soft_things.gd` writes the
   car's speed from outside (TD-24), to stay out of `car.gd`. Step 8a's brief adds a wall answer
   written the same way. No pull request touches `car.gd` today, and its last change was this
   plan's own step 6, so the reason for the workaround is gone. The hook belongs in 8a.
5. **TD-4 a2 has a path no check can reach.** The harness loads "when the argument list is not
   empty", and `--nosave`, which every run must pass, is itself a game flag. So a run without the
   harness exists only in a release build, where a call on a null typed value ends the app
   (TD-21). Section 5 gives the three conditions.
6. **The window for the landmarks split is now.** Every church has its own builder; what is left
   is about thirty plain blocks. `landmarks.gd` is 43,134 lines (42,830 a day ago). Split it
   after #789 and the two queued convents, before the next batch.
7. **The order of work has drifted from the milestone.** The next milestone is a demo on the
   iPhone. Of the ROADMAP's open lines, 9 are "the phone" and "TestFlight and the stores" and 2
   are the start of the game; none of the plans in flight ticks one of them. They are good
   foundations, and they are also the comfortable work: no answer from F is needed. Section 8
   proposes a build train so that foundations and feel meet on a fixed beat.

## 2. The first review, a day later

| # | Item of its part 1 | State on 2026-11-15 |
| --- | --- | --- |
| 1 | The bake chain makes main's map again | #778 open: deterministic, order-independent sectors, two guards. It does **not** reproduce main (F: keep main as the base). Full verify not run yet. See section 3 |
| 2 | TD-4 (a), then the ratchets | a1 merged (#781): `main.gd` 9,581 to 8,320 lines. a2 in work. Ratchets after it |
| 3 | Finish TD-1 (priority table, one busy test) | not started; after the ratchets |
| 4 | TD-10, the landmarks split | not started; the file grew by 304 lines in a day |
| 5 | Honest gates for the AI (seeded soak, a seeded race in CI) | not started; `race` and `police-soak` are still local steps |
| 6 | Merge #776, then measure again (the sloppy table with `mid` and soft fences; a race and a chase with a player who cuts through) | #776 merged. **Neither measurement was made.** Step 8a started instead |
| 7 | A settings row for the collision preset | done (#780), with the soft-fences switch, off by default |
| 8 | One phone list | not written (done by this review) |

Three of eight done or nearly. The pattern in what was skipped: items 5, 6 and 8 produce a
number or a page, not a feature, and no thread owns them. A plan that says "then measure" needs
a named owner for the measuring, or the next build step takes its place. In the revised order
each measuring item names its thread.

## 3. The map: what F's pick means

F picked twice on 2026-11-14: mend the bake chain before any re-bake, and keep main's map as the
base with guards, with no re-stamp from a from-scratch bake.

**What #778 gives.** The bake is deterministic. `build_sector` no longer depends on the order
sectors are built in. Two guards: `postpasses` (the four stamp-guarded passes leave main's map
unchanged) and `sectororder` (all 112 sectors, forward against reverse).

**What it does not give.** Main's map is 36 commits of "main's map plus one pass run again", not
one bake. From scratch, 28 keys still differ (about 600 of 472,641 elements, heights by 1 to
5 cm, 25 fills, 6 trees), and `check_streaming --only=identity` on the from-scratch map reports
138 problems. So nobody can make main's map from the raw data, today or after #778.

**Critique.**

- **The plans still say "re-bake".** Objects steps 8b (thinning), 9 (walls by setting), 10
  (ends and corners) and 13 (yards), and the torn roads (#779), all "wait for the bake chain".
  When #778 merges, a thread reading that will run a full bake on the Mac, get a map 28 keys
  away from main, and either stamp it (against F's pick) or lose a day finding out why its
  hashes moved.
- **The rule that follows from the pick is not written anywhere.** It is: a change to
  `centrum.json` is a **pass**: a function that reads main's file and writes main's file, is
  idempotent (a second run changes nothing), is stamp-guarded, runs inside `bake_osm.py` too so
  a later from-scratch bake has it, and is listed in `check_post_passes.py`. `lane_tapers`,
  `road_fixes`, `zamek_ramps` and `object_fixes` already work this way; `road_profiles` (#779)
  is written this way and joins the guard's list when it merges.
- **The data is frozen, and nobody said so.** With main as the base, new OpenStreetMap or GUGiK
  data cannot come in: a refresh is a from-scratch bake. For a demo of a fixed area that is
  acceptable and even good (no surprise from upstream edits). It should be a stated decision
  with an end: one planned re-stamp after the demo, when every pass can be run again on fresh
  data and the differences reviewed once.
- **`sectororder` is a local step of ten minutes.** A guard nobody runs is not a guard. It
  belongs to the build gate (section 8), with the other local steps.
- **#778 changes what the prebuilt city draws on main's own map**, not only on a from-scratch
  one: `platform_top` and two road-segment caches were filled from one sector (Tamka and Dobra,
  Nowy Świat). The pull request proves forward equals reverse; it does not yet show which
  sectors differ from today's prebuilt city, and what they look like. That is a look change in
  a pull request described as tooling.

**What changes in the plans** (applied in `city-objects-plan.md` section 5 and tech-debt TD-25):
the word "re-bake" is replaced by "a pass on main's map" in every waiting step; a step that
cannot be written as a pass (none is known) waits for the re-stamp after the demo.

## 4. City objects: step 8 and after

**What is good.** F's two picks were built within hours (#780). Step 8 was split so that the
half that needs no map change (8a, pushing) runs now. The brief keeps the switch-off path
hash-equal to main.

**Critique.**

- **The default path is the costly one** (finding 3 above). The sectors' data is "soft first":
  fences and hedges have no collider, and with the switch off `harden` builds them again as
  each sector comes in. #780's note says the phone should be watched for a hitch while
  streaming. 8a adds every parked car to the same work. It should be the other way round while
  the default is hard: the sector carries the hard colliders ready and going soft removes them,
  which is cheap. Until that lands, 8a reports `harden_usec` per sector load, before and after,
  on the stream soak.
- **TD-24 grows.** The smash's cost, the grind's nudge, and now (8a) the push's cost and a wall
  answer for a wedged car are all written into `car.vel` by `soft_things.gd`. That is a second
  place where the car's collision answer lives, outside the preset rules `collide_rules.gd` was
  built to own. The reason was "the controls lane owns `car.gd`". No pull request is open on
  that file. The hook (`car.apply_soft_cost(share, nudge)`, applied in the car's own step) is
  about twenty lines and belongs in 8a, with a fresh audit of `car.gd`.
- **One switch, two features, the wrong name.** "Łamliwe płoty · Smashable fences" will also
  turn on pushable parked cars. On the phone F cannot tell a fence's feel from a push's, and the
  label is untrue. Keep one switch (fewer combinations to test) and rename it when 8a merges:
  "Miękkie miasto · Soft city" with the hint naming both.
- **The measuring was skipped a second time.** The first review asked for the sloppy table with
  `mid` and soft fences before picking the next step. 8a's acceptance will produce part of it
  (set A with `--soft`). It should produce all of it: the full table by class, so that the
  choice between ends and piers (step 10) and the panel trial (step 11) is made from numbers.
  Deck rails and piers were 14 of 20 dead stops before any of this; nothing built so far
  touches them.
- **Races and chases with a player who cuts through: still not measured**, and 8a adds pushing
  a parked car out of the way. A race bench run with a scripted player line through two fence
  gaps is a day's work for the racer bench, which exists. Until it is done, the soft switch
  stays off by default, which F already chose; the plan should say that this measurement, not
  only "fences that fall", is a condition for turning it on for everyone.
- **A pushed car and the town's traffic.** The brief ends a slide outside any lane corridor,
  which answers the first review's worry about two owners at rest. While it slides, town cars
  on rails do not see it. Accepted for 8a (a slide lasts about a second); written into the row
  of `soft_things.gd` in `systems.md` as a known limit.
- **Stage B's gate is being walked past.** The plan says F looks on the phone after each stage.
  Stage A's look was plots and shots; stage B is nearly built with no build cut. Because
  everything is behind switches this is safe, but it must stop here: **no step of stage C
  starts, and no default changes, before a build with steps 6, 7 and 8a has been on F's
  phone.** The work that can run meanwhile is in section 10.

## 5. Architecture: a2, the ratchets, the landmarks file

**What is good.** The codemod. `main.gd` changes about twelve times a day, and a1 was
regenerated twice on a moving main without a hand merge. Splitting a1 from a2 kept each proof
small. `check_dev_flags` holds the result.

**Critique.**

- **a2's null path cannot be tested** (finding 5). The plan's own words differ in two places:
  the audit's condition 4 says "loads only when a test flag is set"; the a2 detail says "when
  the game's argument list is not empty". The second is what would be built, and under it every
  check, every Autopilot run and every debug run on the Mac has a harness, because all of them
  pass `--nosave`. Then:
  1. the harness loads only on a **named list of test flags** (the flags whose first reader is
     a moved function), so a run with only `--nosave --quit-after` has none;
  2. **no unguarded call**: every call site is `if harness != null:`, also inside expressions
     (a local with the default first), and `check_dev_flags` fails on a `harness.` that is not
     under that test;
  3. the proofs add **one whole-game run with only `--nosave`** on both sides (the seeded
     first-ten-minutes run), which is the only run that is like a tester's.
- **The ratchets wait for a number from F that F cannot judge.** "F weighs in on the numbers"
  (the audit's condition 6) puts a line count in front of the one person for whom it means
  nothing. The numbers are simply what main has after a2. Proposed: the audit thread sets them
  at the measured values, F is told in one line, and the pull request that lowers one updates
  it. That removes one more item from the Waiting list.
- **"Under 6,000 lines" will not be reached by TD-4 (a).** After a2 `main.gd` is about 7,340.
  The rest is TD-1's end (the busy tests and the hooks) and TD-4 (b), the wiring. The measure
  table should say which step is expected to bring which share, or the target reads as failed
  when (a) is done.
- **TD-10 has its window** (finding 6). The split's proof tools exist (`site_dump.gd`,
  `site_parity.py`); the cost is an hour without landmark merges. Two lanes add to the file
  beside the churches (the Spire and the light garden merged tonight; none is open). The order:
  #789 and the two queued convents merge, the church thread pauses, the split runs and merges,
  the church thread rebases onto `landmarks/<area>.gd` and goes on. A codemod, as for TD-4, so
  that a late landmark merge costs a re-run.
- **TD-9 is one feature from the wall.** The building shader is at 501 of 505 on Adreno, and
  three plans want that shader: heavy walls (step 9), panels (their own shader, good), the
  facade kit. "Landmarks in their own material" should be scheduled before step 9, not found by
  it.

## 6. Churches and landmarks

**What is good.** One church per pull request, the whole building, the turntable sheet, the
audit's go. About forty builders in two days with no regression in the checks.

**Critique.**

- **Returns are falling.** The named churches are done. What is left is 21 unnamed religious
  blocks and convent wings, built "from LoD2, provisional, no photo" with default colours. Each
  costs a pull request, an audit, a CI round and a waiting entry for F about colours no photo
  shows. 22 of the 294 waiting entries came from this lane in two days; they bury the
  entries that block something.
- **The frame was never measured as a whole.** Each pull request reports its own bench; the
  audit asked for one combined phone measurement of the set and it waits on a build. A Mac
  number needs nobody: draw calls and frame time at four church-dense views (Miodowa, Piwna and
  Świętojańska, Freta, Krakowskie Przedmieście by the Visitationists), main from 2026-11-12
  against today's, both city paths.
- **Proposed**: (1) the provisional blocks get **one** table in `docs/design/churches.md` in
  place of an entry each in `QUESTIONS.md`; (2) the combined Mac bench before the lane goes on;
  (3) after the split, the remaining plain blocks become part of the street-by-street loop
  (built when their street is done, with its photos), not a lane of their own. Point 3 changes
  F's standing order ("don't stop until all would be developed"), so it is his to decide; the
  default keeps the lane going.

## 7. The town: a first outline

The first review said the city AI plan is a racer plan and asked for one page on the town after
F's wish list. No wish list came, and waiting for one is a stall. This is the outline a design
thread (Opus, high effort, with the `game-designer` agent) can start from. It is not a plan
yet: nothing in it was measured.

**What the player sees today** (`docs/architecture/city-ai.md` sections 2, 5 and 6): town cars
are cursors on lanes that pick a random way at each junction, keep a gap, stop at red and for
the player. About 60 walkers react to the horn only. Trams brake for what is ahead. The lane
graph guesses its lanes (TD-23: 403 lanes that run straight into another lane's place).

| Step | What | Why it is first or later | Needs |
| --- | --- | --- | --- |
| T0 | **A town census**: at six junction views and two streets, per minute: cars that change lane inside a junction, cars stopped longer than a light, walkers on the carriageway, trams held. A check and a table | a plan for "alive" needs a number that says "dead" | nothing; reads `road_truth.py`'s findings and a seeded run |
| T1 | **Lane links from `turn:lanes`** (RT-2) | the one change that makes ordinary traffic look right at big junctions; every later step drives on it | F: he parked the road fixes on 2026-11-13 |
| T2 | **The seam in `traffic.gd`** written into `city-ai.md`: the rail car, the line car, who may add what | 5,029 lines and two drivers in one file; no behaviour goes in before this | nothing |
| T3 | **Walkers answer the car**: step back from a car that mounts the pavement, wait at a zebra and cross on green, look at a crash | today they answer the horn only; this is what a phone player meets in the first minute | the chatter budget; TD-6 for the slots |
| T4 | **One population budget per tier** (TD-7) | soft things, debris, pushed cars and walkers share one frame; the governor scales two shares | a phone number |
| T5 | **Trams and buses as a timetable** the player can read (a tram every few minutes on the real lines, a bus that pulls into its bay) | mood, after the traffic reads right | T1 |

T0 and T2 need no answer and change nothing a player feels; they can run now. T1 is F's call.

## 8. The build is the plan nobody owns

Every plan ends its stages with "F looks on the phone". No plan says when a build is cut, what
must be true of main at that commit, or who runs the checks that CI does not.

- **19 verify steps are `local`**: the autopilot runs, the soaks, the streaming walk, the race
  marks, and after #778 the sector order. CI never runs them. Nothing records when each last
  passed on main. A release build hides script mistakes (TD-21), so these debug runs are the
  only place a tester's crash can be caught first.
- **A build waits for a quiet moment that does not come.** TestFlight build 10 is from
  2026-11-14; 34 changes have landed on main since that morning and the list of things to look
  at has about twenty items.

**Proposed: a build train** (written into `docs/WORKFLOW.md` "Milestone gates").

1. **A beat.** A build is cut when `docs/PHONE-CHECK.md` reaches 15 open items or three days
   pass, whichever is first. The coordinator names the commit.
2. **The build gate at that commit**, on the Mac, by a `qa-tester` run: the whole local set of
   `tools/verify.sh` (it names each step and its result in the build's note), `--ios`, and the
   bench on both city paths against the last build's numbers. A red step is fixed or its
   feature is switched off for the build; the build does not wait for a redesign.
3. **F's yes** for the upload, as today. Then the sitting: `docs/PHONE-CHECK.md` top to bottom,
   about twenty minutes. Each line is answered "fine", "wrong: ..." or "skip"; answered lines
   leave the page.
4. **No default changes between builds without a line on that page.**

The first run of the gate can happen today without F: it only needs the Mac.

## 9. Over- and under-planned

| | Item | Verdict |
| --- | --- | --- |
| over | Stage C of the objects plan (nine wall families, panels in every sector, broken looks), written to the level of shader bars before stage B was felt | keep the panel trial only; the rest is re-planned after the phone |
| over | Per-church waiting entries for colours no photo shows | one table |
| over | F's go asked for things F cannot judge: ratchet numbers, the wording of CLAUDE.md's flag rule | the audit decides; F is told |
| over | Proofs at full strength on every regeneration of a codemod's move (a1 was regenerated twice) | keep the old-against-new proof each time; run the whole verify set once, on the final head |
| under | The build (section 8) | the build train |
| under | The frame on the phone as a whole: no owner, no budget split between soft things, debris, churches, racers | a perf pass at the build gate; TD-7 after the first numbers |
| under | The measuring steps the plans call for | each named to a thread in section 10 |
| under | What "re-bake" means on a frozen base | section 3 |
| under | The town | section 7 |
| under | The start of the game: the opening waits on F's "go" since 2026-11-13; it is the first thing an outside player sees and the Demo gate is "outside players finish the first ten minutes without help" | first line of the phone sitting |
| under | The 294 waiting entries: no triage, the old ones are never closed | at each build, entries older than two builds with a built default are closed as "default stands" and moved to Answered |

## 10. The revised order

Lanes as today, one pull request open in each. **Now** needs nothing from F.

### Now

| # | Lane and thread | Item | Done when |
| --- | --- | --- | --- |
| 1 | map (bake thread) | #778: full verify; name the prebuilt sectors that change on main's map, with shots. Merge. Then #779 as the audit set out, `road_profiles` added to `check_post_passes.py` | both merged; `postpasses` lists five passes |
| 2 | architecture | a2 with the three conditions of section 5. Then the ratchets at the measured numbers, set by the audit | `main.gd` about 7,340 and held |
| 3 | objects (walls conductor) | 8a with the car-side hook (TD-24 closed), `harden_usec` reported, the switch renamed; its acceptance run gives the **whole** sloppy table with `--soft` and `mid` | merged behind the switch; the table in the plan |
| 4 | objects | Sectors carry the hard colliders ready; going soft removes them (TD-26) | sector load with the switch off costs what it did before #776 |
| 5 | landmarks | TD-10, the split, by codemod, in the pause after #789 and the two queued convents | `site_parity.py`: no vertex moves; the church thread rebased |
| 6 | racer bench (a short Opus thread) | A race and a chase with a scripted player who cuts through two fence lines and pushes one car: seconds gained, chase lost or not | two numbers in `race-ai.md` |
| 7 | QA (Mac, `qa-tester`) | The first build gate: the local set, `--ios`, the bench on both paths, the church views against 2026-11-12 | a build note with every local step's result |
| 8 | AI | T0 the town census and T2 the seam (section 7); the police soak seeded | a table; the soak passes ten in ten |
| 9 | architecture | Finish TD-1: the priority table, one busy test | as the first review's item 3 |

### Then: the build and F's sitting

Build 11 from the commit that passed item 7, with 8a in it if it is merged, otherwise without.
`docs/PHONE-CHECK.md`, top to bottom.

### After the sitting

| # | Item | Depends on |
| --- | --- | --- |
| 10 | The default collision preset; race marks recorded again | F's pick on the phone |
| 11 | Ends, corners and piers (step 10) or the panel trial (step 11), whichever item 3's table and F's look rank first. Both as passes on main's map where they touch it | items 1, 3 |
| 12 | 8b, parked cars thinned in the pinches, as a pass | item 1 |
| 13 | The soft switch on for everyone | broken fences fall (step 11 or 12), item 6's numbers, F |
| 14 | T1 lane links, then T3 walkers | F on RT-2 |
| 15 | Landmarks in their own material (TD-9), before any heavy-wall look work | the phone's frame |
| 16 | One re-stamp of the map from fresh data, every pass run again | after the demo |

What stays as it is: one pull request per step, the audit's go, old-against-new proofs, Fable
writes briefs and judges, Opus and Sonnet build.

## 11. For F

Parked in `docs/QUESTIONS.md` with these defaults. Only the first needs you before anything
moves; the others have a default that is being followed.

1. **Cut build 11 and do one sitting.** The gate (item 7) runs on your Mac first. Default: the
   coordinator asks for your yes when the gate is green.
2. **The map's data stays at today's extract until after the demo**; changes are small guarded
   passes on main's file; one re-stamp from fresh data later. This follows from your pick of
   main as the base. Default: yes.
3. **The church lane.** Split `landmarks.gd` now (an hour's pause). Then either keep going
   through the 21 plain blocks one pull request each (your standing order, the default), or fold
   them into the street-by-street work.
4. **Lane links at junctions (RT-2)**, still parked by you. It is the first real step of making
   town traffic look right. Default: stays parked.
5. **A build every three days or at 15 open phone checks**, with the Mac gate before it.
   Default: yes, as a working rule; each upload still needs your yes.
