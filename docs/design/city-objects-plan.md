# The city's objects: one plan

**Status (2026-11-13):** the single plan. It joins the two plans of the same day into one order of
work with one architecture. No game code changed.

F (2026-11-13): "I want to merge this plan with the other one about making the city friendlier to
drive, because with that plan some walls can be destroyed and objects change their behaviour. One
plan for identifying and changing walls, their behaviour and the objects' behaviour. Plan by
Fable; implementing by Opus and Sonnet, with Fable for judging, complex work and decisions. Maybe
the walls near Narodowy can return. And think about the architecture of all of it: the wall
builder or palette, the system for the car's behaviour and the objects' behaviour."

**What this page is.** The order, the architecture, who builds and who judges. The detail of each
step stays where it was written, and each step below names its brief:

- `drivable-city.md`: the research (five solidity classes, a verdict per object type, rules R1-R9).
- `drivable-city-build.md`: items 0 to 11 (colliders, the car's answer, breaking, pushing,
  memory and repair), each written as a build brief.
- `walls-true-to-life.md`: the types of wall, fence and rail, how a line gets its type, how each
  is drawn whole and broken (phases W2 to W10; W0 and W1 were done in step 5).

**Review of 2026-11-14** (`tech-plans-review.md` sections 5 and 9): it proposes mending the bake
chain before any step that re-bakes, a settings row for the collision preset, the panel trial
(step 11) before heavy walls (step 9), and the next feel step picked from a fresh baseline. The
order in section 5 stands until F picks.

**Second review, 2026-11-15** (`tech-plans-review-2.md` sections 3, 4 and 10), after F's picks of
2026-11-14 (mend the bake chain first; main's map stays the base; soft fences behind a switch,
off by default). It changes this page: section 5.1 below is the order from here on, and it wins
over the tables of stages B to D where they differ.

**The walls look re-planned, 2026-11-15** (F answered the walls' four defaults as recommended and
asked for more detail; `walls-true-to-life.md` was reviewed against main and fresh photos and its
sections 6, 8, 9 and 10 written again). It changes this page: section 5.2 below is stage C from
here on, and it wins over the stage C table and over rows f, i and j of section 5.1.

Where this page and those disagree, this page wins. The order tables in those two plans are
replaced by section 5 here.

Contents: [1 In short](#1-in-short) · [2 One question, four answers](#2-one-question-four-answers) ·
[3 The architecture](#3-the-architecture) · [4 Stadion Narodowy](#4-stadion-narodowy-the-walls-stay) ·
[5 The steps](#5-the-steps-in-order) ([5.1 from 2026-11-15](#51-the-order-from-2026-11-15-second-review), [5.2 stage C](#52-stage-c-from-2026-11-15-the-look-re-planned)) · [6 Who builds, who judges](#6-who-builds-who-judges) ·
[7 Gates](#7-gates-and-what-f-sees) · [8 Risks](#8-risks) · [9 Questions for F](#9-questions-for-f)

---

## 1. In short

1. **One table decides everything about an object.** Each kind of thing in the street (a school
   fence, a brick wall, a hedge, a parked car, a stall, a kerb) is one row in one data file, the
   **object palette**. The row says what it is, how it looks, what happens when the car meets it,
   how it looks broken, what it sounds like and what it costs. Today those answers are spread
   over `map_builder.gd`, `car.gd` and five prop scripts.
2. **The map bake names every object once.** One bake tool identifies the type (from OSM tags,
   the structure it belongs to, the land beside it) and writes the type and the class on the
   object. The game never guesses.
3. **The car knows classes, never objects.** Five classes: Hard, Smash, Push, Ride, Ghost. The
   car asks one pure rule table what to do with a class at an angle and a speed.
4. **Things that yield have one owner.** One system breaks, pushes, remembers and repairs. It
   tells the drawing side "this panel broke" and "this panel is repaired".
5. **The walls near Stadion Narodowy stay.** The open pull request that deletes them (#642) is
   not merged. With this plan the fences and hedges there break when driven through, and the
   stadium grounds are the first place each step is looked at (section 4).
6. **Sixteen steps in three stages**: first the foundations nobody can feel (classes, the
   measuring, the types), then the feel (the car's answer, breaking, pushing), then the look
   (heavy walls, see-through panels, broken panels). F looks at the phone after each stage.
7. **Fable plans, briefs and judges; Opus and Sonnet build.** One Fable thread runs the steps in
   order with one pull request open at a time on the map side, and the car's answer goes through
   the controls thread.

## 2. One question, four answers

For any object the game has to answer four things. Today each has a different home; the plan
gives each one home and makes them read the same row.

| Question | Today | In the plan |
| --- | --- | --- |
| **What is it?** | OSM's kind (fence, wall, hedge) and, for a fifth of them, a tag; styles and special cases in `map_builder.gd` | `ty` on the object, written by the bake (`tools/object_types.py`): tags, then structure, then setting, then shape, then a default. Exceptions by id in `game/data/road_objects.json` |
| **How does it look?** | `BARRIER_STYLE`, `WALL_MATERIAL` and a dozen constants in `map_builder.gd`; one grey band, one beige slab | the palette row's look: heavy things as shaped geometry in the city mesh, light things as instanced panels |
| **What does the car do?** | everything 0.3 m or taller is a wall; one bag of collider faces; the answer is code in `car.gd` | the palette row's class; `collide_rules.gd` answers by class, angle and speed |
| **What happens to it?** | nothing: nothing breaks or moves | `soft_things.gd`: break, push, remember, repair; the palette row's broken look, debris and sound |

## 3. The architecture

### 3.1 The picture

```
 BAKE (Python, once)                DATA                          GAME
 ─────────────────────              ─────────────────────         ─────────────────────────────────────
 tools/object_types.py              game/data/                    solidity.gd  (pure: reads the palette)
   identify  → ty, tc     ────────► object_palette.json ────────►   class of a type, costs, presets
   classify  → sc, hz                 one row per type              │
   heights   → h                    road_objects.json               ├──► collide_rules.gd (pure)
 tools/bake_sectors.py                exceptions by id              │      answer(speed, angle, class)
   per sector: hard runs,                                           │        ▲
   panels, pushables      ────────► sector data ──────┐             │      car.gd  (knows classes only)
                                                      │             │        │ asks each frame
                                                      ▼             ▼        ▼
                                    city_barriers.gd (the wall builder)    soft_things.gd
                                      heavy types → city mesh              break, push, memory, repair
                                      colliders  → _solid(class, faces)      │ broke / repaired
                                      light types → panel list               ▼
                                                      │             panels (MultiMesh per sector,
                                                      └───────────►  panel.gdshader), debris, sound,
                                                                     haptics, bubbles, counters
                                    contact_log.gd (measuring) listens to the car and to soft_things
```

Arrows go one way. The car never reads an object's type. An object never changes the car's
physics; it returns a cost and the car applies it. The drawing side never decides behaviour; it
is told.

### 3.2 The parts

| Part | Kind | Owns | Does not |
| --- | --- | --- | --- |
| `game/data/object_palette.json` | data | one row per object type: family (heavy, light, low, pushable), default class, sizes, colours, rhythm (posts, piers, panel length), openness, broken look, debris, sound, cost. For barriers: `types` (today's looks), `looks` (one row per `ty`, walls doc 6.2) and `barrier_look`, the key that picks between them (`classic` until F's phone look) | hold anything about one single object |
| `tools/object_types.py` | bake | identifying each barrier line and street object; class and hazard reason; heights by setting; the counts in `check_map_data.py`; the type plot | draw anything |
| `game/data/road_objects.json` | data | exceptions by stable id (a type, a class, a removal), written by street sweeps | become the main list: R8 says class rules first |
| `solidity.gd` | pure script | reading the palette; the class of a type; the cost table; the collision presets | touch nodes |
| `collide_rules.gd` | pure script | the car's answer to a contact by class, angle and speed | know types or the map |
| `car.gd` | node | applying the answer; asking `soft_things` once a frame; the signals `bumped`, `impact`, `scraped` | hold numbers that belong in the two pure scripts |
| `city_barriers.gd` | builder, new, taken out of `map_builder.gd` | walls, fences, hedges, rails, guard rails: geometry for heavy types, the panel list for light ones, colliders through `_solid(class, faces)` | pick a type or a class |
| `soft_things.gd` | node | every thing that yields: the cell index, the crossing test, the cost returned to the car, session memory, repair, the events `broke` and `repaired` | draw |
| panels (`instance_buffers.gd` + `panel.gdshader` + `panel_states.gd`) | drawing | one `MultiMesh` per sector of 2 m panels; a panel's state (whole, down, torn, stub), written by `panel_states.gd` when `soft_things` says so | decide when something breaks |
| `contact_log.gd`, `tools/drive_report.py` | measuring | what was hit, how hard, on which street; the baseline and the ratchets | change behaviour |
| `main.gd` | composition root | building and wiring the above, the test flags (`--collide=`, `--colliders`, `--contacts=`, `--no-soft`, `--barriers=`) | hold rules |

`map_builder.gd` is 12,615 lines and the barrier code in it is about 1,200. This plan adds more
to that part than to any other, so the wall builder moves out first (step 2), proved identical
by a hash of each sector's vertices and collider faces on both city paths, the way an activity is
proved against its old script before the old one is deleted.

### 3.3 One frame, one hit

1. `car.gd` moves. A hard contact carries the collider body's class; `collide_rules.answer`
   gives what to keep along the wall, the bounce and the turn.
2. `car.gd` hands its box and this frame's motion to `soft_things.sweep`. It gets back a cost
   (a share of the speed) and, when grinding along, a small nudge. Nothing else.
3. `soft_things` records what broke or was pushed and emits `broke(id, panel, kind, at,
   direction, speed)`. Wired in `main.gd`: the panel lies down, debris flies in the type's
   colour, the type's sound plays through `Sfx`, the phone buzzes through `Access.buzz`, now and
   then a bubble, a counter in `wallet.gd`, a line in the contact log.
4. Later, out of sight, `soft_things` drops the entry and emits `repaired(id, panel)`.

### 3.4 Decisions this makes

For `docs/architecture/decisions.md` when the first step lands:

- **An object's type and class are decided in the bake, never at run time.** Both city paths read
  the same sector data.
- **The car knows classes, not objects.** A new object type never needs a change in `car.gd`.
- **Things that yield are data in one system, not physics bodies.** No second physics layer (a
  dozen scripts write the car's collision mask as a literal).
- **A look is a palette row.** A retexture or a new fence type is data; code changes only for a
  new family.
- **No event bus.** `soft_things` has two signals; `main.gd` connects them.

`docs/architecture/extending.md` gets two rows ("a wall, fence or street object type" and "what
happens when the car hits something") and `tech-debt.md` a row for the debt this removes, in the
same pull request as step 1.

## 4. Stadion Narodowy: the walls stay

Pull request #642 (open since 2026-11-10) deletes every fence, hedge and wall in the stadium
grounds (the box x 1230 to 1720, z -850 to -400) because they made driving there hard. On main
they are all still there: 35 fences (2.5 km, 16 of them 6.2 m tall), 6 walls (0.4 km) and 127
hedges (1.1 km).

With this plan the cause goes away without deleting anything, so #642 should be closed unmerged:

- the fences and hedges become Smash: the car drives through, a panel falls, leaves fly;
- the 6.2 m fences get their real type. By the general rule a fence that tall beside a pitch is a
  ball net, which is wrong here: they are the stadium's own tall perimeter fence. That is exactly
  what the exception file is for, and the first test of it;
- the six walls get a height from their setting and a class from that height.

The stadium grounds are also the **review place**: wide, open, known to F, with all three kinds
in one view. Each step that changes something a player sees shows its before and after there
first, then on Marszałkowska in the centre.

## 5. The steps, in order

One pull request per step. "Brief" is the section a builder works from. Steps on the same line
of the picture can run side by side.

```
 Stage A, foundations     1 ─ 2 ─┬─ 3 ─ 4
 (nothing to feel)               └─ 5
 Stage B, the feel        6 (car lane, with the controls thread)      7 ─ 8
 Stage C, the look        9 ─ 10      11 ─ 12
 Stage D, the rest        13   14   15   16
```

### Stage A: foundations (a player feels nothing)

| # | Step | What | Brief | Builder | Proof |
| --- | --- | --- | --- | --- | --- |
| **1** | Solid classes | every collider face knows its class; one body per class per sector; `solidity.gd` with the class list; the palette file started with the classes | build plan, item 0 | Opus | every existing check passes with no number moved; `check_solids` on both paths |
| **2** | The wall builder and the palette | barrier code out of `map_builder.gd` into `city_barriers.gd`; today's styles become palette rows with today's looks | this page 3.2; walls doc 6.1 | Opus; Fable writes the hash proof | vertex and collider hash per sector identical before and after, both paths |
| **3** | Measuring | the contact log, the sloppy driver, the census of service ways, the baseline table | build plan, item 1 | Opus | careful driver unchanged; sloppy run repeats exactly |
| **4** | Honest colliders | the `--colliders` view; rule R2 as a check (no collider without a drawing, none much bigger than it); the pocket-wall audit | build plan, item 5 | Opus; Sonnet for the audit list | the check passes with a short allow-list |
| **5** | Identify | `tools/object_types.py`: type, sureness, class, hazard reason and height on every line; the context outlines from OSM; counts and the type plot. Beside it the type sheet: photos per type and the 20-sample check of each rule. The game still ignores all of it | walls doc 5 and W0, W1; build plan item 3 "bake" and item 8 "walls with no height" | Opus (map-engineer); Haiku gathers photos; Fable judges each rule | the map chain green; each rule at least 16 of 20 right or dropped |

**F's look 1**: the type plot of the whole map, the collider view at the stadium, the baseline
table (which streets stop the car and what stops it).

### Stage B: the feel

| # | Step | What | Brief | Builder | Proof |
| --- | --- | --- | --- | --- | --- |
| **6** | The car's answer | `collide_rules.gd`; answer by angle; the head-on kick; the corner pivot; traffic shoved; presets behind `--collide=` | build plan, item 2 | Opus, inside or after the controls thread (same file) | preset v1 identical to today; with `mid`, no dead stop under 60 km/h |
| **7** | Things that break | `soft_things.gd`; fences and hedges leave the hard collider by their class; cost, debris, sound, memory and repair; hazard fences stay hard | build plan, item 3 and section 5 | Opus | sloppy table before and after; the `--wander` run finds no trap |
| **8** | Parked cars | pushed and settling; thinned where the lane is pinched | build plan, item 4 | Opus | no dead stop on a parked car; nothing comes to rest in a lane |

**F's look 2**, on the phone: the three presets of step 6, driving through the stadium's fences,
shoving cars on Krucza. After it the default preset changes in its own small pull request, with
the race marks recorded again.

### Stage C: the look

**Replaced on 2026-11-15 by section 5.2.** The table below is the first plan's and is kept for the
record.

| # | Step | What | Brief | Builder | Proof |
| --- | --- | --- | --- | --- | --- |
| **9** | Heavy walls | the heavy families in `city_barriers.gd` (foot, cap, piers, panels a shade apart); brick, plaster, precast, stone, noise screens, jersey, parapets; walls by height and setting get their class | walls doc 4.2, 6.2, W2; build plan item 8 | Opus for the families, Sonnet (object-modeler) for the rows | shots both paths; draw calls unchanged |
| **10** | Ends and corners | collider tapers and chamfers; a drawn end piece where a hard thing ends near a lane | build plan, item 7 | Opus | no head-on into an end in the sloppy table |
| **11** | Panel trial | `panel.gdshader` and the sector `MultiMesh` at the stadium and on Marszałkowska behind `--barriers=panels`; the bar rule at three zooms | walls doc 6.3, 8, 9, W3 | Opus (perf-engineer) | draw calls at the four probe views; the Adreno count; F's look |
| **12** | Panels everywhere, and broken | every light type as a row; both paths; a hit panel lies down until repaired; debris and sound by type | walls doc 7, W4, W5 | Opus; Sonnet for the rows | full set, `--ios`, the streaming soak |

**F's look 3**: before and after at the stadium, Marszałkowska, a school, a works wall, a park.

### Stage D: the rest (any order, as F picks)

| # | Step | What | Brief | Builder |
| --- | --- | --- | --- | --- |
| **13** | Narrow streets and yards | colliders set back from house fronts; dead-end yards gated with a gate from the palette | build plan, item 6 | Opus |
| **14** | Small things | stalls break, carts are pushed, low stones are passed through, tram islands are ridden over, canopies stand on posts | build plan, items 8 and 9 | Sonnet with the brief |
| **15** | Content | hoarding posters with parody developers, graffiti, ivy (walls doc W9); bollard rows are a type now (`post_row`, W3); gates are W8 | walls doc W8, W9 | Sonnet |
| **16** | Keeping it | the ratchets (hard metres by a lane, dead stops, the share of default types only go down); then street sweeps for the exceptions | build plan, items 10 and 11; walls doc W10 | Sonnet; the sweep skill |

What depends on what: 2 after 1 (both touch every collider site); 5 after 2; 7 after 1, 3 and 5;
8 after 6 and 7; 9 after 5; 11 after 7 (both edit the builder); 12 after 11. Step 6 depends only
on 3. Steps 3 and 4 can run beside 5.

### 5.1 The order from 2026-11-15 (second review)

**State.** Stage A is merged (steps 1 to 5). Stage B: 6 merged (#760, #765; the default is still
v1), 7 merged (#776), both behind Settings → Świat since #780 ("Zderzenia", and "Łamliwe płoty",
off by default). Step 8 is split: **8a** pushing (in work, no map change) and **8b** thinning in
the pinches (a map change).

**Four rules added.**

1. **The map changes by passes, never by a full bake.** Main's `centrum.json` is the base (F,
   2026-11-14) and a from-scratch bake does not reproduce it, also after #778. Every step below
   that changes the map (8b, 9's classes by setting, 10, 13) is written as a pass: it reads
   main's file and writes it, a second run changes nothing, it is stamp-guarded, it runs inside
   `bake_osm.py` as well, and it is listed in `tools/check_post_passes.py`. Where a step's brief
   says "re-bake", read "run the pass". The data stays at its present extract until one planned
   re-stamp after the demo (tech-debt TD-25).
2. **The default path is the cheap path.** While the switch is off by default, a sector carries
   its hard colliders ready and going soft removes them; nothing is rebuilt at sector load for a
   player who does not have the feature (TD-26). Any step that adds a kind of thing to
   `soft_things.gd` reports the cost of a sector load with the switch off, before and after.
3. **The car applies every cost itself.** `soft_things.gd` reports a share of the speed, a nudge
   or a wall answer; `car.gd` applies it in its own step through one hook (this closes TD-24).
   No new write to `car.vel` from outside the car.
4. **No step of stage C starts and no default changes before a build with steps 6, 7 and 8a has
   been on F's phone** (`docs/PHONE-CHECK.md`, lines 4 to 7). *Amended 2026-11-15:* F said go for
   the look. Stage C's phases may be built now, each behind the palette's `barrier_look` key,
   which stays `classic`. The second half stands: no default changes, and nothing a tester sees
   changes, before F's phone look (section 5.2).

**The order.**

| # | Step | What | Waits for |
| --- | --- | --- | --- |
| a | **8a** Parked cars pushed | as its brief, plus: the car-side hook (rule 3); `harden_usec` per sector load reported (rule 2); the switch renamed "Miękkie miasto · Soft city", one switch for fences and parked cars; the acceptance run gives the **whole** sloppy table by class with `--soft` and `mid`, not only the parked rows | nothing |
| b | **Hard colliders ready in the sector** | rule 2, for fences, hedges and parked cars, both city paths | a |
| c | **Cutting through, measured** | the race bench with a scripted player who crosses two fence lines and pushes one car: seconds gained in a race, whether a chase is lost at once. In `race-ai.md`; run by the racer bench's thread, not the conductor | a |
| d | **F's look 2** on the phone | the presets, the smash, the push, the hitch with the switch off | a build |
| e | **The default preset** | its own small pull request; race marks recorded again | d |
| f | **10 Ends, corners and piers**: still waits for d and is still the first feel step after it (deck rails and piers were 14 of the baseline's 20 dead stops). **11 the panel trial** no longer waits: it is W4 of section 5.2 | d; #778 for the parts that are passes |
| g | **8b** Thinning in the pinches | a pass; the rule may be written and counted dry before | #778 |
| h | **The switch on for everyone** | when a broken fence falls (W6 of section 5.2, on a build baked with `panels`), c's numbers are acceptable or rivals and chasers got the same ways through, and F says so | c, W6, F |
| i | **9 Heavy walls** | re-planned in section 5.2 as 9a (palette rows: height, colour, thin rails; W2), 9b (the heavy kit as geometry and vertex colour on the building shader's existing prop path; W7) and 9c (low walls by class). No phase edits `building.gdshader`; each one's gate is `check_shader_budget` unchanged at 501, so TD-9 does not block them | see 5.2 |
| j | **12, 13, 14, 15, 16** | 12 is W5 and W6 of section 5.2. The rest re-planned after d; 13 only for traps the wander run finds; 14 and 15 belong to the street-by-street loop (15's walls content is W9); 16's ratchets name the CI machine | d |

A pushed car is not seen by the town's rail cars while it slides (about a second); it never
rests in a lane. Accepted for 8a and written into `soft_things.gd`'s row in `systems.md`.

### 5.2 Stage C from 2026-11-15 (the look, re-planned)

F (2026-11-15) answered the walls' four defaults as recommended and asked for more detail. The
build briefs are `walls-true-to-life.md` sections 6 to 10; the first phase's brief is written out
in `/mnt/project-files/walls-research/look-plan/brief-phase1.md`.

**Three rules for the whole stage.**

1. **One key, off by default.** The palette's `barrier_look` is `classic` on main through every
   phase. `--barriers=typed|panels` picks the new look for a run and for a city bake. Each phase
   proves the classic path bit-equal to main by the sector hashes. A tester's build is baked
   `classic` until F has looked at the new look on the phone (a device run, or a build F allows)
   and says go.
2. **The building shader is not edited.** Heavy detail is geometry and vertex colour. Light
   detail is the panels' own small shader. Every phase's gate: `check_shader_budget` prints 501
   for `building.gdshader`.
3. **A map change is a pass** (rule 1 of section 5.1): W3 and W8 are passes on main's map.

**The phases**, one pull request each, in this order. "Step" is this plan's number.

| Phase | Step | What | Builder | Proof beyond the common gates | Waits for |
| --- | --- | --- | --- | --- | --- |
| **W2** | 9a | The game reads `ty`: a look row for every type, heights from `hs`, light fences as thin posts and rails in the city mesh, the `barrier_look` key and `--barriers=` | Opus | every type has a row; draw calls unchanged; barrier triangles at most 0.75 M; sector load p99 at most +5 % | nothing |
| **W3** | 5b | Type fixes from the photos, as `object_types.py` version 2: planter edges in squares, bollard rows, the stadium's tall fence (with its lines in the exception file, section 4), tall hedges; the pass joins `check_post_passes.py` | Opus (`map-engineer`); Haiku for photos; the conductor judges | each new rule 16 of 20 or dropped; default share 12 % to at most 9 % | W2 merged (one map-side pull request at a time) |
| **W4** | 11 | The panel trial: `panel.gdshader`, one `MultiMesh` per sector, six light types as panels (173 km), both city paths | Opus (`perf-engineer`) | draw calls at most +3 at the spawn and the river view, +6 zoomed out, +9 from the helicopter; the shader under 200 of 260; the bar rule as a pure check | W2 |
| **W5** | 12a | Every light type as a panel | Opus; Sonnet for rows and shots | as W4; the art-director accepts the shot set | W4 |
| **W6** | 12b | Broken panels: a hit panel lies down, tears or leaves a stub by its type, stays so, and stands again on repair | Opus | every broken kind in a shot; state survives leaving and coming back; zero state writes with the soft switch off | W5 |
| **W7** | 9b | The heavy kit: foot, cap, bays, piers, noise screens; pier-and-iron fences with piers that stand (F's answer 1) | Opus; Sonnet for rows and shots | draw calls unchanged; no new dead stop in the sloppy table | W6 (the same builder file) |
| **10** | 10 | Ends, corners and piers (colliders); W7 draws the end piece where this step put a taper | Opus | as its brief | F's look 2 (row f of 5.1) |
| **W8** | 15 | Gates and gaps where a path or a drive crosses a line, as a pass `barrier_gates` | Opus (`map-engineer`) | idempotent; the wander run finds no new trap | W7 |
| **W9** | 15 | Marks: graffiti, parody slogans, hoarding banners, ivy, stains (F's answers 2 and 3) | Sonnet; PixelLab in the loop's limit | at most +1 draw call per sector with a slogan in view | W7 |
| **9c** | 9c | Low walls by class: under 0.6 m ridden over, 0.6 to 1.2 m broken with a notch. A feel change, behind the "Miękkie miasto" switch, with the hard colliders carried ready (rule 2 of 5.1) | Opus | the sloppy table | F's look 2 |
| **W10** | 16 | Sweeps write a type per line; the default share only goes down; classic drawing deleted two builds after the key leaves `classic` | Sonnet; the sweep skill | per street | the key changed |

**F's look 3** is in two parts, each a device run or a build F allows: a city baked `typed`
(after W2 and W3), then one baked `panels` with the soft switch on (after W6). The lines for
`docs/PHONE-CHECK.md` are in the walls doc, section 10. After the second part the key changes in
its own one-line pull request, and row h of section 5.1 (the soft switch on for everyone) can
follow.

**Cost** (walls doc, section 8): W2 and W7 add triangles only (about +0.2 M and +0.6 M
city-wide). Panels add one draw call per visible sector with fences: 1 to 4 in a default view.
Nothing adds a light, and the only new material is the one panel shader.

## 6. Who builds, who judges

| Role | Model | Does |
| --- | --- | --- |
| Conductor | Fable, one thread | keeps this plan; writes each step's brief from its section, with the acceptance checks; writes the proofs that need design (the hash proof of step 2, the v1 parity of step 6, the 20-sample rule check); decides palette rows that are a judgement (what a type is, its class at the boundary); reads each result against the gates and says go or back |
| Builders of geometry, physics, performance and the bake | Opus (`map-engineer`, `perf-engineer`, or an Opus thread) | steps 1 to 13 as marked |
| Builders with a spec | Sonnet (`gameplay-dev`, `object-modeler`) | palette rows, checks from a written table, content, small things, the ratchets |
| Evidence | Haiku (`scout`, `street-scout`) | photo sets, counts, logs into tables |
| Look review | Opus (`art-director`) | shot sets against the type sheet |

Rules:

- **One pull request open at a time on the map side** (steps 1, 2, 5, 7 to 16 all touch the
  builder or the bake). The car lane (step 6) runs beside it in the controls thread.
- **A cheaper run that fails its gates is run again one tier up**, not patched (project rule).
- **Fable never accepts its own build.** Where Fable writes a proof, the builder runs it; where
  a builder writes code, Fable or the audit reads it.
- Every pull request goes through the audit thread as usual.

## 7. Gates, and what F sees

Each step's own acceptance is in its brief. For all of them:

| Gate | Steps |
| --- | --- |
| The verify set; both city paths; `check_map_data.py` with new counts recorded on purpose | all |
| The baseline table before and after (contacts per km by class, dead stops, speed kept) | 6 onward |
| Bench: draw calls, script time, sector load | 1, 7, 8, 9, 11, 12 |
| Shots at phone size, day and night, at the stadium and on Marszałkowska (stage C: the seven review places of the walls doc, section 10, classic beside the new look) | 7, 9, 11, 12 |
| Stage C: with `barrier_look` at `classic` the sector hashes equal main's; `building.gdshader` unchanged at 501 of 505 | W2 to W9 |
| The phone, only with F's yes: the presets, the feel of a smash and a push, the panels' frame time and shimmer | after stages B and C |
| Architecture: a row in `systems.md` for each new script; the owner named in the pull request | the step that adds it |

## 8. Risks

| Risk | What limits it |
| --- | --- |
| Step 2 moves 1,200 lines that both city paths depend on | a pure move, proved by hashes, no look change in the same pull request |
| With soft fences the car gets into places it cannot leave | step 7's wander run before merging; hazard fences stay hard; yards gated in step 13 |
| The game gets too easy | the cost table and the presets are numbers in one file; F starts from the middle preset |
| Race marks move when the default preset changes | its own pull request, agreed with the racer thread |
| Panels cost too much on the phone | the trial (W4) before the roll-out; the fallback ladder of the walls doc (section 9): a shorter visibility range, no holes on the low tiers, then `typed` (thin rails in the city mesh), then `classic` |
| The new look reaches testers before F has seen it | the palette's `barrier_look` stays `classic`; a build is baked in one look and the prebuilt index is stamped with it |
| Two threads in `car.gd` or in `map_builder.gd` | the lanes of section 6; step 1 first, because it touches every collider site once |
| The palette becomes a second place for the same fact | step 2 deletes `BARRIER_STYLE` and `WALL_MATERIAL` when it adds the rows; `solidity.gd` is the only reader |

## 9. Questions for F

Parked in `docs/QUESTIONS.md`. The defaults of the two earlier plans still stand (fences and
hedges break; parked cars can be pushed; breaking costs only speed and noise; shelters stay
solid; broken things are repaired out of sight after about ten minutes; old pier-and-iron fences
break and their piers stand; graffiti and parody hoardings yes; an unknown fence is a thin dark
railing). The four about walls were **answered 2026-11-15 (F): all as the defaults.** New here:

1. **Close #642** (delete the stadium's fences) unmerged, since this plan keeps them and makes
   them breakable. Default: close it when step 7 lands; until then it stays open and unmerged.
2. **Who runs it**: one Fable thread as the conductor, starting the builders for each step.
   Default: this thread.
3. **Go for stage A** (steps 1 to 5): nothing a player can feel, so it can start at once.
