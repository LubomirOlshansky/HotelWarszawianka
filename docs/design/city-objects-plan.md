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
  is drawn whole and broken (phases W0 to W7).

Where this page and those disagree, this page wins. The order tables in those two plans are
replaced by section 5 here.

Contents: [1 In short](#1-in-short) · [2 One question, four answers](#2-one-question-four-answers) ·
[3 The architecture](#3-the-architecture) · [4 Stadion Narodowy](#4-stadion-narodowy-the-walls-stay) ·
[5 The steps](#5-the-steps-in-order) · [6 Who builds, who judges](#6-who-builds-who-judges) ·
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
| `game/data/object_palette.json` | data | one row per object type: family (heavy, light, low, pushable), default class, sizes, colours, rhythm (posts, piers, panel length), openness, broken look, debris, sound, cost | hold anything about one single object |
| `tools/object_types.py` | bake | identifying each barrier line and street object; class and hazard reason; heights by setting; the counts in `check_map_data.py`; the type plot | draw anything |
| `game/data/road_objects.json` | data | exceptions by stable id (a type, a class, a removal), written by street sweeps | become the main list: R8 says class rules first |
| `solidity.gd` | pure script | reading the palette; the class of a type; the cost table; the collision presets | touch nodes |
| `collide_rules.gd` | pure script | the car's answer to a contact by class, angle and speed | know types or the map |
| `car.gd` | node | applying the answer; asking `soft_things` once a frame; the signals `bumped`, `impact`, `scraped` | hold numbers that belong in the two pure scripts |
| `city_barriers.gd` | builder, new, taken out of `map_builder.gd` | walls, fences, hedges, rails, guard rails: geometry for heavy types, the panel list for light ones, colliders through `_solid(class, faces)` | pick a type or a class |
| `soft_things.gd` | node | every thing that yields: the cell index, the crossing test, the cost returned to the car, session memory, repair, the events `broke` and `repaired` | draw |
| panels (`instance_buffers.gd` + `panel.gdshader`) | drawing | one `MultiMesh` per sector of 2 m panels; a panel's state (whole, down, stub) | decide when something breaks |
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
| **15** | Content | hoarding posters with parody developers, graffiti, bollard rows, gates | walls doc W6 | Sonnet |
| **16** | Keeping it | the ratchets (hard metres by a lane, dead stops, the share of default types only go down); then street sweeps for the exceptions | build plan, items 10 and 11; walls doc W7 | Sonnet; the sweep skill |

What depends on what: 2 after 1 (both touch every collider site); 5 after 2; 7 after 1, 3 and 5;
8 after 6 and 7; 9 after 5; 11 after 7 (both edit the builder); 12 after 11. Step 6 depends only
on 3. Steps 3 and 4 can run beside 5.

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
| Shots at phone size, day and night, at the stadium and on Marszałkowska | 7, 9, 11, 12 |
| The phone, only with F's yes: the presets, the feel of a smash and a push, the panels' frame time and shimmer | after stages B and C |
| Architecture: a row in `systems.md` for each new script; the owner named in the pull request | the step that adds it |

## 8. Risks

| Risk | What limits it |
| --- | --- |
| Step 2 moves 1,200 lines that both city paths depend on | a pure move, proved by hashes, no look change in the same pull request |
| With soft fences the car gets into places it cannot leave | step 7's wander run before merging; hazard fences stay hard; yards gated in step 13 |
| The game gets too easy | the cost table and the presets are numbers in one file; F starts from the middle preset |
| Race marks move when the default preset changes | its own pull request, agreed with the racer thread |
| Panels cost too much on the phone | the trial (step 11) before the roll-out; the fallback ladder of the walls doc, ending in `--barriers=classic` |
| Two threads in `car.gd` or in `map_builder.gd` | the lanes of section 6; step 1 first, because it touches every collider site once |
| The palette becomes a second place for the same fact | step 2 deletes `BARRIER_STYLE` and `WALL_MATERIAL` when it adds the rows; `solidity.gd` is the only reader |

## 9. Questions for F

Parked in `docs/QUESTIONS.md`. The defaults of the two earlier plans still stand (fences and
hedges break; parked cars can be pushed; breaking costs only speed and noise; shelters stay
solid; broken things are repaired out of sight after about ten minutes; old pier-and-iron fences
break and their piers stand; graffiti and parody hoardings yes; an unknown fence is a thin dark
railing). New here:

1. **Close #642** (delete the stadium's fences) unmerged, since this plan keeps them and makes
   them breakable. Default: close it when step 7 lands; until then it stays open and unmerged.
2. **Who runs it**: one Fable thread as the conductor, starting the builders for each step.
   Default: this thread.
3. **Go for stage A** (steps 1 to 5): nothing a player can feel, so it can start at once.
