# A city built for driving: the build plan

**Status (2026-11-13):** the detailed plan for building `docs/design/drivable-city.md` (the
research: five solidity classes, a verdict per object type, rules R1-R9). No game code changed.
Research and plan on Fable; **each item below is built by its own Opus thread** from its section
here, which is written to be that thread's brief.

**The order of work is now in `docs/design/city-objects-plan.md`** (the single plan that joins this
page with the walls plan, 2026-11-13). The items below remain the build briefs.

F (2026-11-13): "make the very detailed plan and research with Fable, implementation with Opus.
And as a separate task: how to make the walls look more like in life, representing the real type
of object and texture, and how to handle it when it is ruined: the memory of it and the recovery."

Two threads share that message. **This page**: what is solid, how a hit is answered, what the
game remembers about a broken thing and how it comes back (section 5). **The walls-look thread**:
what each wall, fence and rail looks like, whole and broken. The seam between them is section 5.5.

Contents: [1 What the code looks like today](#1-what-the-code-looks-like-today) ·
[2 New measurements](#2-new-measurements) · [3 The order and what depends on what](#3-the-order-and-what-depends-on-what) ·
[4 The items](#4-the-items) · [5 Broken things: memory and recovery](#5-broken-things-memory-and-recovery) ·
[6 Gates for every item](#6-gates-for-every-item) · [7 Risks](#7-risks) ·
[8 Who else is in these files](#8-who-else-is-in-these-files) · [9 Open questions](#9-open-questions)

---

## 1. What the code looks like today

Facts the items build on, read from main 05b7c9c.

**One bag of collider faces.** `map_builder.gd` appends every solid thing's triangles to one array,
`_wall_faces` (about 40 call sites: buildings, LoD2, barriers, railings, structure walls, portals,
piers, guard rails, platforms, parked cars, props, pocket walls, garage doors, landmarks). At the
end `_build_collision` cuts it into `ConcavePolygonShape3D` patches of at most 1,000 faces
(`COLLIDER_CHUNK`, `backface_collision` on) under one `StaticBody3D` per sector. The prebuilt path
saves those patches (`game/tools/bake_city.gd`, "the collider's patches").
**So a contact cannot say what it touched**: the collider is the sector's body, whatever was hit.

**One physics layer.** Everything is on layer 1. A dozen places write `car.collision_mask = 0` or
`= 1` as literals (main.gd, police.gd, rides.gd, jobs.gd, city_life.gd, the boat, the phone
camera). A second physics layer for soft things would have to survive all of them.

**Barriers** (`_build_barriers`, `_wall_along`, `_railing_along`): the style is
`[colour, width, height, (railing)]` from `BARRIER_STYLE`, a wall's own rules (`GARDEN_RING`,
`LOW_WALL`, `ISLAND_EDGE`, `PKIN_WALL`, `BASIN_RIM`, the mapped `h`), the line's `st`, then the
override file. Solid when the style is 0.3 m or taller (`BARRIER_SOLID_MIN`). The collider is the
slab's two long faces, from 0.3 m under the ground to `height + 1.5` m. Railings always collide.

**Parked cars** (`_build_props` end): `MultiMesh` instances per 512 m tile, and four faces of a
1.8 × 4.2 × 1.5 m box each into `_wall_faces`. 19,572 / 4 = 4,893 cars.

**The car** (`car.gd` `_physics_process`, after `move_and_slide`): the velocity going into each
contact is removed; what slides is kept less `SCRAPE`; a glancing nose (into 0.05-0.9) is turned
along the wall at `WALL_TURN` 3 rad/s; a first contact pushes back `lost × 0.12`, at most 1.2 m/s;
against something not fixed (`AnimatableBody3D`: traffic, trams) it keeps `CAR_KEEP` 0.5 of what
went in. `_corner_slip` sidesteps small clipped corners. `_classic_wall_steer` (2026-11-04) turns
a Classic car along a wall it noses into. Pinned 1.5 s: `_unstick`. Signals out: `bumped`
(collider, speed lost), `impact`, `scraped`.

**The drive check** (`game/tools/check_lane_drive.gd`, 500 lines): the real car steered along
lane-graph routes with a careful driver (`target_dir` at a point `LOOK` m ahead), no traffic. It
knows "touching something fixed" but not what. Modes: the P14 narrow streets, Trzy mosty,
`--streets`, `--route`, `--links` (the racers' proven links: "never touches anything fixed").

**Owners** (`docs/architecture/extending.md`): a kept value goes in `wallet.gd`; a sound is a row
in `Sfx.SHOTS`; a bubble goes through `bubbles.say_reaction`; a vibration through `Access.buzz`;
a test flag is parsed in `main.gd` `_parse_args`; testable numbers live in a pure static script
with a `check_*.gd`; a new script gets a row in `systems.md`.

## 2. New measurements

Made for this plan from `game/map/centrum.json` (main 05b7c9c). Scripts were one-off; the items
that need the numbers again build them into their tools.

| Question | Answer | What it means |
| --- | --- | --- |
| How many fences and hedges would have to stay hard because something dangerous is behind them? | **4.7 km of 209 km (2.2 %)**: within 6 m of a railway line 2.0 km, within 3 m of a retaining wall over 1.5 m 1.0 km, within 5 m of the water 1.0 km, along a guard rail 0.7 km. A proxy from map data; the bake measures it exactly with the terrain | the bulk rule "fences and hedges break" is safe: 98 % of them have nothing behind |
| How many barrier walls have a height to decide by? | 168 of 1,935 lines (7.3 of 68 km): under 0.6 m 2.7 km, 0.6-1.2 m 2.4 km, over 1.2 m 2.2 km. **60.8 km carry no height** | a rule by height alone covers a tenth. Untagged walls need a rule by context (section 4, item 8) and stay hard until then |
| What do fences carry? | 4,079 of 4,892 lines no tag at all; 768 a fence type (`ft`), 133 a height | the walls-look thread has little to draw from in the data: the type must come from context |
| How many parked cars sit at a lane's edge? | 475 groups in the edge band, 152 of them within 0.3 m; 285 on residential streets, 102 tertiary, 69 secondary | thinning touches a few hundred cars, not thousands |
| What does the census not see? | **209 km of service ways** (45 % of all drawn road length) are drawn and driven but are not in the lane graph, so nothing along them is measured. Yards, car parks and back lanes are exactly where players get stuck | item 1 extends the census to service ways before anything is judged "fine" |
| Dead ends in the lane graph | 61 edges end with no way out (5.3 km), most at the map edge | traps are in the service ways, not in the graph |

### The drive baseline (item 1, 2026-11-14, main bf9e8d4)

**What was run.** Route set A (`check_lane_drive.gd --set=A`, `SET_A_CENSUS` + `SET_A_FIRST10` +
the P14 streets + the three Trzy mosty legs): 61 routes, ~99 km for the sloppy driver and 95 km
for the careful one (the careful one ends a route where it fails). Each street from end to end both
ways; 8 streets one way only (their far ends are one-way: a dual carriageway's, a slip road's), and
street ends behind the edge roadworks are left out. Both drivers, in the two handling profiles the
brief calls "Cruise and Grounded" (car.gd `Handling.CRUISE`, the default, and `Handling.GROUNDED`,
`--handling=grounded`), on the **prebuilt** city; the runtime city as a cross-check on three
streets (Hoża, Marszałkowska, Most Świętokrzyski, both ways, and Trzy mosty's second leg, 14 km):
its contact log is **identical, line for line,** to the prebuilt city's on the same routes, for
both drivers. The sloppy run is deterministic (two runs, identical contact files and output). The
careful driver's default run (`check_lane_drive` with no flags) prints exactly what main printed,
on both paths. To repeat:

```
cd game && godot --headless --path . --fixed-fps 60 --script res://tools/check_lane_drive.gd -- \
    --prebuilt --set=A --driver=sloppy [--handling=grounded] --contacts=/tmp/sloppy.tsv
python3 -I tools/drive_report.py sloppy=/tmp/sloppy.tsv [careful=...] [--census] [--md] [--baseline=tools/drive_baseline.json]
```

The numbers per street for every run are in `tools/drive_baseline.json`. Every contact had a
class (0 `unknown`); 96 % of the sloppy contacts join to a census object within 2.5 m of the car.

| Run | km | contacts / km | by class (per km) | speed kept | dead stops | unsticks | tows (water) | at speed | unknown |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sloppy, Cruise, prebuilt | 98.8 | 2.71 | guard_deck 1.58, fence 0.48, guard_ground 0.20, tunnel 0.14, pier 0.12 | 0.91 | 20 | 11 | 8 (3) | 0.94 | 0 |
| careful, Cruise, prebuilt | 95.1 | 0.05 | guard_deck 0.04, tunnel 0.01 | 0.99 | 0 | 0 | 0 (3) | 0.81 | 0 |
| sloppy, Grounded, prebuilt | 100.2 | 4.72 | guard_deck 2.34, fence 1.07, tunnel 0.44, guard_ground 0.33, pier 0.15 | 0.92 | 26 | 9 | 11 (3) | 0.96 | 0 |
| careful, Grounded, prebuilt | 95.1 | 0.05 | guard_deck 0.04, tunnel 0.01 | 0.98 | 0 | 0 | 0 (3) | 0.80 | 0 |
| sloppy, Cruise, runtime (3 streets) | 14.0 | 1.36 | guard_deck 0.93, fence 0.29, parked 0.07, wall 0.07 | 0.91 | 0 | 0 | 0 (0) | 0.96 | 0 |
| careful, Cruise, runtime (3 streets) | 13.8 | 0.00 | - | - | 0 | 0 | 0 (0) | 0.86 | 0 |

"Speed kept" is the median of (lowest speed in the second after a contact) / (speed going in);
"at speed" the share of the time above 80 % of the street's limit; "water" the careful driver's
stalls too (it is not towed). The ten worst streets of the sloppy driver (at least 0.25 km driven,
ranked by contacts per km plus five times the stops per km; the speed taken is the m/s lost
summed by class; the objects are the census ids, `tools/road_objects.py` `oid`):

| Street (Cruise) | km | contacts / km | dead stops / unsticks / tows | speed kept | what takes the speed | most hit |
| --- | --- | --- | --- | --- | --- | --- |
| Juliana Ursyna Niemcewicza | 0.49 | 6.1 | 2 / 0 / 0 | 0.00 | parked 21 | two parked cars at -2918,1353 |
| (unnamed secondary_link) (the slip roads by Most Poniatowskiego) | 3.73 | 7.2 | 5 / 3 / 1 | 0.88 | guard_deck 49, pier 42 | the deck rail at 917,-14 (6×), 988,8 |
| Aleja Armii Ludowej | 1.17 | 13.7 | 1 / 0 / 0 | 0.94 | guard_deck 29, guard_ground 9 | the deck rail at 857,1313 (7×), the ground rail at 92,1621 |
| (unnamed primary_link) (by the Łazienkowski) | 1.24 | 8.9 | 2 / 0 / 0 | 0.84 | guard_deck 22, struct_wall 3 | deck rails at 1209,1048 and 1306,957 |
| Tytusa Chałubińskiego | 2.67 | 6.7 | 3 / 2 / 0 | 0.90 | pier 32, small_building 14, guard_deck 10 | the viaduct's rail at -1432,894 (7×), its piers at -1449,806 |
| Okopowa | 0.28 | 14.1 | 0 / 0 / 0 | 0.96 | fence 3 | the fence at -2984,-290 (4×) |
| Aleja Jana Pawła II | 4.74 | 4.0 | 4 / 4 / 1 | 0.71 | fence 46, wall 19, pier 14 | the fence and wall at -1567,566 (7×) |
| Williama Heerleina Lindleya | 0.35 | 11.3 | 0 / 0 / 0 | 0.94 | fence 3 | the fence at -1909,862 |
| Aleje Jerozolimskie | 7.35 | 6.4 | 3 / 2 / 1 | 0.92 | guard_deck 85, fence 4 | Poniatowski bridge's rails at 441,30 (11×), 195,105 (7×) |
| Wał Miedzeszyński | 0.51 | 0.0 | 0 / 0 / 1 | - | - | (off the route at a fork, towed) |

| Street (Grounded) | km | contacts / km | dead stops / unsticks / tows | speed kept | what takes the speed | most hit |
| --- | --- | --- | --- | --- | --- | --- |
| Juliana Ursyna Niemcewicza | 0.50 | 16.0 | 2 / 0 / 0 | 0.95 | parked 22, fence 2 | the parked cars at -2918,1353 |
| Most Świętokrzyski | 2.09 | 17.2 | 2 / 0 / 0 | 0.92 | guard_deck 51, fence 12 | the deck rails at 508,-737 (11×), 867,-989 |
| Okopowa | 0.29 | 20.7 | 0 / 0 / 0 | 0.94 | fence 5 | the fence at -2984,-290 |
| (unnamed secondary_link) | 3.82 | 9.7 | 4 / 2 / 1 | 0.90 | pier 34, guard_deck 33, struct_wall 13 | the deck rail at 917,-14 |
| Tunel Wisłostrady | 2.96 | 12.9 | 0 / 0 / 3 | 0.93 | tunnel 53 | the tunnel's walls at 157,-1051 (19×), 165,-1060 |
| Solec | 0.95 | 2.1 | 1 / 1 / 1 | 0.02 | shelter 15 | the shelter at 635,-94 |
| Tytusa Chałubińskiego | 2.71 | 7.7 | 3 / 2 / 0 | 0.88 | pier 27, guard_deck 22, small_building 15 | the viaduct's rail at -1432,894 (12×) |
| Aleja Jana Pawła II | 4.78 | 6.5 | 5 / 4 / 1 | 0.90 | fence 34, pier 24, small_building 23 | the rail at -1514,688, the fence at -1567,566 |
| Most Łazienkowski | 1.17 | 12.0 | 1 / 0 / 0 | 0.93 | guard_deck 36 | the deck rail at 1750,944 (7×) |
| Aleja Armii Ludowej | 1.18 | 16.2 | 0 / 0 / 0 | 0.95 | guard_ground 18, guard_deck 7 | the ground rail at 92,1621 |

**What it says.** Guard rails (on decks and on the ground) are two thirds of the sloppy driver's
contacts in Cruise (176 of 268) and mostly glancing (0.9 of the speed kept), but a deck rail taken
nose-on at a slip road's bend is still the commonest dead stop (8 of 20), then piers (6), parked
cars and small buildings (2 each); the dead stops sit on the slip roads by Most Poniatowskiego (5)
and the Łazienkowski (2), Jana Pawła II (4), Chałubińskiego (3), Jerozolimskie (3) and
Niemcewicza (2). Grounded touches 1.7 times as often as Cruise (it slides wider at the same pace)
with a few more dead stops (26), piers first (7), then small buildings and fences (4 each). The
careful driver touches almost nothing (5 glancing contacts in 95 km): the checks so far drove a
player nobody is.

**Found by it** (not fixed here; for the map lane): (1) **the water test fires inside Tunel
Wisłostrady**: at 527,-671 and 382,-847 the tunnel's own lanes lie under a water area, and
`map_builder.in_water` (water above, the car under the terrain) puts the car "in the water": the
careful driver stalls there on the lane's centre in both directions and the sloppy one is towed.
A player driving the tunnel would be splashed and towed the same way. `check_water` leaves tunnel
lanes out on purpose, so nothing caught it. Over the whole lane graph (every lane every 3 m at its
lane height) the class is 9 of 1,777 tunnel lane points, all in those two spots of Tunel
Wisłostrady; no deck or ground lane point (157,413) is in the water. The fix belongs in
`in_water` (not under a tunnel's roof), for the map lane after step 2 lands. (2) The sloppy driver ends up 3 m under the road at
the east end of Most Poniatowskiego (1537,-169; Cruise once, Grounded once on Trzy mosty's leg 3).

**The census of service ways** (`tools/road_objects.py`, the second pass, apart from the lane
bands, which print as before): 209 km of service ways drawn; 1,685 solid objects stand on a
service way itself (790 barriers, 655 buildings, 108 structure walls, 76 parked cars) and 4,967
within 1 m of its edge; 45,050 m of building wall and 30,653 m of barrier lie within 3 m of a
service way's edge. 98 % of the solid metres on or within 3 m of a service way are on unnamed ones (yards, car parks, back
lanes). Not split by cause yet (a way ending in a wall, a gate, a passage the bake does not open):
item 6's work list (`--json` writes them as `service_items`).

## 3. The order and what depends on what

```
0  Solid classes in the collider ─┬─> 1  Contact log, sloppy driver, baseline
                                  │         │
                                  │         ├─> 2  Collision answer v2 ──> 4  Parked cars: Push
                                  │         │
                                  └─────────┴─> 3  Smash: fences and hedges ──> 9  Small things
                                                    │
5  Collider honesty (R2)  <─ 0                      └─> 10 Ratchets <─ 4
6  Narrow streets and yards <─ 1
7  Tapers and chamfers <─ 1
8  Walls by context, platforms, canopies <─ 3
11 Street sweeps <─ 10
```

| # | Item | Size | Changes the feel? | Model |
| --- | --- | --- | --- | --- |
| 0 | Solid classes in the collider | small, mechanical, wide | no (must be identical) | Opus |
| 1 | Contact log, sloppy driver, census of service ways, baseline | medium | no | Opus |
| 2 | Collision answer v2 | medium, delicate | **yes, the most** | Opus, with the controls thread |
| 3 | Smash class: fences and hedges | large | **yes** | Opus |
| 4 | Parked cars: Push and thinning | large | yes | Opus |
| 5 | Collider honesty: R2 check, collider view, pocket-wall audit | medium | fixes only | Opus |
| 6 | Narrow streets and yards | medium, re-bake | yes | Opus |
| 7 | Tapers and chamfers | medium, re-bake | fixes | Opus |
| 8 | Walls by context, tram platforms, canopies | medium | some | Opus for the rule, Sonnet to apply |
| 9 | Stalls, carts, small monuments | small | fun | Sonnet with this spec |
| 10 | Ratchets | small | no | Sonnet |
| 11 | Street sweeps of the exceptions | ongoing | fixes | the sweep skill |

Items 0 and 1 go first and alone: every later item reports its effect with item 1's numbers.
Items 2 and 3 can then run side by side (2 is `car.gd`, 3 is the map and a new script).

## 4. The items

Each section: goal, design, steps, acceptance, traps. "Both paths" means the runtime city and the
prebuilt sectors.

### Item 0. Solid classes in the collider

**Goal.** Every collider face knows its class, so a contact can be named, a class can be moved to
another answer, and rule R2 can be checked. No change in behaviour.

**Design.**
- `_wall_faces` becomes faces by class. One helper in `map_builder.gd`:
  `_solid(cls: StringName, faces: PackedVector3Array)`; every `_wall_faces.append_array` site
  calls it with its class. Classes (the census's names where they exist): `building`, `lod2`,
  `small_building`, `fence`, `hedge`, `wall`, `stair_wall`, `railing`, `struct_wall`, `tunnel`,
  `portal`, `guard_deck`, `guard_ground`, `pier`, `platform`, `parked`, `shelter`, `prop`,
  `pocket`, `garage_door`, `landmark`, `edge`. The list lives in one place: a new pure static
  script `game/scripts/solidity.gd` (class names, the answer each class gets: H, S, P, R, G, and
  later the cost table). It is the "table as data" of the research.
- `_build_collision` makes one `StaticBody3D` per class per sector, named `Solid_<class>`, with
  `set_meta("solid", cls)`, each cut into `COLLIDER_CHUNK` patches as now. All on layer 1.
- `bake_city.gd` saves and the prebuilt loader restores the bodies with their names and meta.
- `landmarks.gd` `_collide_raw` and the prop scripts' own bodies (`street_details.gd`,
  `monuments.gd`, `park_details.gd`, `edge_roadworks.gd`, `tamka.gd`) set the same meta.

**Steps.** 1 `solidity.gd` and its row in `systems.md`. 2 the helper and the call sites, class by
class. 3 `_build_collision` and `bake_city.gd`. 4 the other scripts' bodies. 5 a new check
`check_solids.gd` (verify step `solids`, group `smoke`): for a fixed set of sectors, face count
per class equal on both paths and equal in total to a recorded number; no body without the meta.

**Acceptance.** The whole verify set unchanged; `check_lane_drive`, `check_stuck_spots`,
`check_steering` pass with no number moved; sector load time on the bench within noise (more,
smaller shapes: report the sectors' shape counts before and after); `check_map_data.py --fresh`.

**Traps.** Sorting faces by class changes patch contents: a face must land in exactly one patch,
as now. Faces filtered per sector by their centre (`_sector_rect`) must keep that rule per class.
`backface_collision` stays on. Do not rename the body other scripts look up (grep for the sector
body's name first).

### Item 1. Contact log, sloppy driver, the census of service ways, the baseline

**Built (2026-11-14):** `contact_log.gd`, `--contacts=FILE` (main.gd and the check),
`check_lane_drive --driver=sloppy --set=A`, `tools/drive_report.py`, the service-way pass of
`tools/road_objects.py`, `tools/drive_baseline.json`, verify step `drivelog`; the numbers are in
section 2, "The drive baseline". Choices made in the build: the sloppy driver presses the game's
own Classic controls (drive_controls.gd: the fixed arrows, GAS and BRAKE all or nothing, the lane
assist on as the settings default) with no change to car.gd; it is towed where a player would
call the tow (stuck 8 s, in the water, 12 m off the route, under the road); a street's km and its
contacts count the route's own edge, so they add up.

**Goal.** A number for "how hard is this street" that a phone player would recognise, and a name
for whatever stopped the car.

**Design.**
- **Contact record** (a small pure script `contact_log.gd`, used by the check and by dev runs):
  one line per contact episode (first frame of a contact until 0.25 s free): time, x, z, class
  (the body's `solid` meta, or `traffic`, `tram`), speed in, lowest speed in the next 1 s, impact
  angle (velocity against the summed normal), street (nearest graph edge's name), and flags:
  `dead_stop` (lost 60 % or more and at least 5 m/s within 0.3 s), `unstick`, `tow`.
- **In the game**: `--contacts=FILE` (parsed in `main.gd`, noted in the flags table) writes the
  same lines from `car.bumped` / `car.impact` during any run, Autopilot's included. Release
  builds ignore it. This is what gives PT-36, PT-44 and PT-45 a cause.
- **In `check_lane_drive.gd`**: `--contacts=FILE`, `--streets=` already exists; a new
  `--driver=careful|sloppy` (default careful, so today's gates do not move). Sloppy, with a fixed
  seed: aims up to 1.5 m off the lane centre (slow noise, both sides), turns in late (`LOOK`
  shortened by a third), ±10° heading noise, holds 90 % of the limit instead of the bend speed
  until 15 m before a bend. `--traffic` stays off here: traffic contacts come from Autopilot and
  item 2's cases.
- **Report** (`tools/drive_report.py`, standard library): per street and overall: km driven,
  contacts per km by class, median share of speed kept, dead stops, unsticks, tows, share of the
  time above 80 % of the limit. Joins each contact to the census id (`tools/road_objects.py
  --json`: nearest object of that class within 1.5 m).
- **Census of service ways** (`tools/road_objects.py`): a second pass measuring solids against
  the drawn service ways' edges (`roads` with `k: service`, half the width each side), reported
  apart from the lane bands so the old numbers stay comparable.
- **Baseline** `tools/drive_baseline.json`: the report's numbers for a fixed route set, both
  drivers. Route set A (CI, about 60 km): the census's top 25 streets, the first-ten-minutes
  streets, the P14 narrow streets, Trzy mosty. Route set B (local, by hand): every named street.

**Steps.** 1 `contact_log.gd` and the flag. 2 the sloppy driver. 3 the report and the join.
4 the service-way pass. 5 run set A on both paths, both drivers, Cruise and Grounded; write the
baseline and a table into this file's section 2. 6 verify step `drivelog` (slow, `smoke`): runs
set A sloppy and prints the table; it gates nothing yet (item 10 makes it a ratchet).

**Acceptance.** The careful driver's results identical to today's. The sloppy run deterministic
(two runs, same lines). Every contact line has a class. The table in the PR, with the ten worst
streets and the classes that stop the car there.

**Traps.** The check's driver uses point-to-steer (`target_dir`); the default controls are
Classic. The sloppy driver should drive **Classic inputs** (`steer`, `throttle`), or the wall
follow it meets is not the one players have. Headless runs need `--fixed-fps 60`. A whole-city
runtime build takes about 280 s in the cloud, the prebuilt 7 s after a 430 s bake
(cloud-verify-setup): run long sets on the prebuilt path and a short cross-check on the runtime.

### Item 2. Collision answer v2

**Goal.** A hit never leaves the car facing a wall at 0 km/h. The targets are
`road-objects.md` 4.2 (walls by angle) and 4.3 (traffic); this section says how.

**Design.**
- **Rules as data**: a pure static script `collide_rules.gd`: for a preset and a handling profile,
  `answer(speed, angle_deg, cls) -> {keep_along, bounce, yaw_rate, kick_deg}`. Presets
  `v1` (today's behaviour, reproduced exactly), `soft`, `mid`, `firm` (graze keeps 97 / 90 / 80 %;
  F: "97 % is too arcade, start from the middle"). `check_collide_rules.gd` tests the table:
  monotonic in the angle, never more speed out than in, v1 equals today's formulas.
- **In `car.gd`**, replacing the block from "var n := Vector3.ZERO" to "_contact = 0.25" for
  fixed contacts when the preset is not v1:
  1. θ from `vel` and the summed horizontal normal (as now).
  2. tangent `t` = the wall direction on the side the velocity leans (or the steering strip's
     side when it leans past `CLASSIC_WALL_LEAN`).
  3. new velocity = `t × speed × keep_along(θ) + n × speed × bounce(θ)`.
  4. the nose turns toward the new velocity at `yaw_rate` (6 rad/s Cruise).
  5. head-on (θ over 75°, speed over 4 m/s): two `test_move` casts at yaw ±45° pick the freer
     side; a yaw kick of 35-50° that way, once per contact episode.
  6. corner pivot: if the contact normal turned more than 40° within two frames and the contact
     is within 0.6 m of the car's front corner, keep 80 % and rotate about the contact.
  `_corner_slip`, `_classic_wall_steer`, the scrape sparks, sounds and haptics stay. `_unstick`
  stays as the net; every unstick in a check is a failure.
- **Traffic** (`not fixed`): `CAR_KEEP` from the table by angle (rear-end 0.75, side 0.85,
  T-bone 0.4 with the wall's deflection); `traffic.gd` `_shove` gets the closing angle so a
  T-boned car spins out of the lane (`SHOVE_SIDE` up to 0.8 for that case). Trams and buses
  answer as walls. `GHOST_PUSH_TIME` 1.5 → 0.8 s in Cruise.
- **Flag and setting**: `--collide=v1|soft|mid|firm`; default stays `v1` until F's phone A/B,
  then a setting "Zderzenia" in `settings.gd` + `settings_panel.gd`.

**Steps.** 1 `collide_rules.gd` + check, v1 proven equal (the check drives the same 12 wall cases
with the old code path and the table). 2 the wall answer. 3 the head-on kick and pivot.
4 traffic. 5 cases in `check_steering.gd` (10°, 30°, 60°, 90° at 30 and 60 km/h; Classic, Point,
Fixed; Cruise, Sport, Grounded: speed kept after 1 s, heading, pinned time, no unstick) and in
`check_handling.gd` (rear-end, side swipe, T-bone, queue at a red unchanged). 6 item 1's set A
with each preset: the table.

**Acceptance.** v1 runs bit-identical (the race bench and `check_lane_drive` do not move).
With `mid`: no dead stop in any wall case under 60 km/h; head-on at 50 km/h is driving again at
15 km/h or more within 1 s; sloppy set A dead stops down by at least 80 %; no unstick anywhere.
Bench unchanged (two `test_move` casts only in a head-on frame).

**Traps.** The racers (`race-ai.md`) drive links proven with "never touches anything fixed", so
their routes do not change, but the **race bench's marks are measured with the player's car
model**: a new default preset moves them. Changing the default is its own small PR that
re-records the marks on purpose, agreed with the racer thread (step 6a is pending there).
Grounded handling keeps its own grip code (`_weighty_speed`, `_grounded_grip`): the answer sets
`vel`, then both profiles derive `speed` and `lateral` from it, as the current code does.
`check_stuck_offer`'s pen and the tow offer rely on being pinned: keep a case where the car
really is boxed in and must still get the offer. The controls thread is editing steering in the
same file: build this in that thread, or after it merges, never in parallel.

### Item 3. Smash class: fences and hedges

**Goal.** 209 km of fence and hedge stop being walls. Driving through one costs a little speed,
makes a noise and throws debris; the street looks the same before the hit.

**Design: the soft things are data, not physics.** No second physics layer (section 1: the mask
literals). The car asks a small spatial index each frame.

- **Bake** (`tools/bake_structures.py`, next to `clear_carriageways`): for every `lines` entry
  of kind fence or hedge, decide `sc` (solidity class) and write it on the line:
  - `H` if a hazard is behind it: the terrain drops more than 1.5 m within 3 m on either side
    (the bake has the terrain), a railway line within 6 m, open water within 5 m, a retaining
    wall over 1.5 m within 3 m, or the line runs along a deck or guard rail. Such a line also
    gets its reason, `hz: drop | railway | water | deck`, and no fixed style: the walls-look
    thread's type table picks the heavy look from the reason (a steel beam along a road, a stout
    railing on a granite kerb on the boulevards, a precast wall at a railway, a parapet at a
    drop beside a walk). Rule R2: hard looks hard. Expect about 4-5 km.
  - `S` otherwise.
  Lines already styled as railings (`tram_railing`, stair balustrades) keep H: they guard a
  track bed edge or a stair hole. (Whether tram railings in medians should break is an A/B for
  F after the baseline: PT-1 was one.)
- **Sector data**: `tools/bake_sectors.py` writes each sector's soft segments into its data
  (a, b, kind, height, id, panel count). Both paths read the same list at sector load, so the
  runtime and the prebuilt city cannot differ.
- **`map_builder.gd`**: a line with `sc: S` is drawn as now and adds no collider faces.
- **New script `soft_things.gd`** (a row in `systems.md`; made by `main.gd` in a
  `_build_soft_things(world)` step; fed by the streamer's `sector_ready` and on unload): an 8 m
  cell hash of segments for loaded sectors. Each physics frame, only when the car moves over
  2 m/s and `collision_mask != 0`: the segments in the car's cell and its neighbours are tested
  against the car's box swept by this frame's motion. A crossed panel (2 m of the segment):
  - cost: `speed *= 1 - cost(kind)` once per panel, at most 15 % per 0.5 s however many panels:
    fence 6 %, hedge 10 %, per `solidity.gd`. Grinding **along** a fence (angle under 15°)
    costs 3 % a second and knocks the panels down as it goes.
  - a sideways nudge of 0.3 m/s out of the line when grinding, none when crossing.
  - feedback: `sfx.play_at` (`smash_fence_metal`, `smash_fence_wood`, `smash_hedge`: rows in
    `Sfx.SHOTS` with a voice limit of 2), debris from one pooled `GPUParticles3D` (bars or
    leaves; one draw call while it plays), `Access.buzz` light, and now and then
    `bubbles.say_reaction("smash")` (inside the chatter budget; 6-8 lines in `dialogue.json`,
    Polish and English, warsaw-tone).
  - memory: the panel is marked broken (section 5). A panel's index is
    `floor(distance along the line / 2 m)`, the same in the bake's panel list and in the look
    thread's instanced panels.
- **Other cars**: traffic, racers and police follow lanes and never needed fences; nothing
  changes for them. Pedestrians do not use the collider.

**Version 1 look**: debris flies, the fence stays drawn. It is honest enough at the game's
camera for a first build and adds no draw call at rest. **Version 2** (the broken panel stays
down) is section 5.5, agreed with the walls-look thread.

**Steps.** 1 the bake rule and `sc`; the count of H fences by reason into `check_map_data.py`.
2 sector data, both paths. 3 `map_builder.gd` skips the collider for S. 4 `soft_things.gd`,
the cost table in `solidity.gd`, `check_soft_things.gd` (pure: box-against-segment cases, the
cost cap, grinding, both directions, a broken panel costs nothing the second time). 5 sound,
debris, lines. 6 `check_stuck_spots` and `check_lane_drive` re-run; spots that relied on a
fence as a wall listed. 7 item 1's set A before and after. 8 bench before and after, both paths.

**Acceptance.** Sloppy set A: fence and hedge contacts no longer appear as hard contacts; dead
stops on Marszałkowska, Jerozolimskie, Jana Pawła II, Okopowa and Prosta down to the structure
ones. Hard metres within 1 m of a lane: fences 12.1 km → the H ones only. Bench: draw calls
unchanged at rest, script time for `soft_things` under 0.05 ms a frame on the bench route.
No sector has a soft segment on one path and not the other (`check_soft_things` reads both).

**Traps.**
- **Things that were closed by a fence**: a yard, a school ground, a park, a construction site,
  the tram bed. With fences soft the car can enter all of them. Before merging, run the sloppy
  driver *off* the lanes on purpose (a `--wander` mode: aim at the fence lines) and list every
  place the car then cannot leave or falls through the world (ground with no surface, water with
  no shore rule, a railway cutting the proxy missed). Each is either H in the bake or a hole to
  close. Rule R6 is the test.
- **Quests and jobs** that put a ring, a customer or a parked target behind a fence: grep the
  data for points within 2 m of an S line; none should depend on the fence stopping the car.
- **The police**: escaping through a fence must not be free forever. Patrol cars follow the lane
  graph; a player in a park is "out of sight" quickly. Report what `check_police` shows; tuning
  it is the police owner's call, not this item's.
- **The boat and the helicopter** set `collision_mask = 0`: the test is skipped, as intended.
- The 1.5 m extra collider height above every barrier was hiding a second job: it kept the car
  from *riding over* low hedges on slopes. With no collider, the car simply passes: fine.

### Item 4. Parked cars: Push, and thinned in the pinches

**Goal.** A parked car at the lane's edge costs speed and gets shoved, never a stop; the
tightest rows lose every other car.

**Design.**
- **Thinning, in the bake** (`tools/bake_osm.py` parking lanes, or a pass in `object_fixes.py`):
  drop every other car of a row where the lane's free width (lane width + gap to the row +
  gap on the other side) is under 3.6 m, and every car within 15 m of a junction node whose box
  is within 1 m of a lane edge. Deterministic (by index along the row). Expect a few hundred of
  4,893. New counts recorded on purpose in `check_map_data.py`.
- **Push**: parked cars leave `_wall_faces` and join `soft_things.gd` as boxes (the same cell
  hash; an oriented box test against the car's box).
  On a hit: the player keeps `1 - 0.25 × |cos θ|` of the speed going into it (25 % head-on into
  its end, almost nothing brushing its side); the parked car gets a velocity (the player's
  normal component × 0.6) and a small spin, slides with 6 m/s² of friction, and stops. One
  `PhysicsDirectSpaceState3D.cast_motion` of its box along the slide, at the moment of the hit,
  clamps the distance so it does not enter a building.
  The `MultiMesh` instance's transform is updated while it slides (each tile's node carries the
  source indices of its instances in its meta, so an index in the data finds its instance).
- **A car that cannot move** (slide clamped under 0.5 m: against a wall or another car): the
  player gets the wall answer of item 2 from the box's face. This is why item 2 comes first.
- **Traffic** never reads parked cars today (they stand outside the lane corridors, the bake
  guarantees it). A pushed car must not come to rest inside a lane corridor: the slide is
  extended or shortened to the nearest free spot, and if none is found the car is flagged
  `towed` and removed when out of sight (section 5).

**Steps.** 1 the thinning and its counts. 2 the boxes in `soft_things.gd`, the answer, the
slide, the instance update, both paths. 3 `check_soft_things` cases (end-on, side, wedged,
chain of two, rest never in a lane). 4 sound (`smash_car`: the existing knock, pitched), a
reaction line. 5 set A before and after (Krucza, Wspólna, Polna, Noakowskiego, Hoża added to
the set). 6 bench.

**Acceptance.** No dead stop on a parked car in sloppy set A; median speed kept on a parked-car
contact at least 75 %. `check_lane_drive --links` proofs still pass (the racers' links never
touched them anyway). Bench: no change at rest; while 3 cars slide, under 0.1 ms.

**Traps.** The shade map bakes parked cars' shadows into the ground (the "parked cars' and
trees'" channel): a pushed car leaves its dark patch behind. Accept in version 1 (it reads as
an oil stain), or the walls-look thread decides. Shadows from the sun follow the instance, so
only the baked shade is wrong. Missions that use a *specific* parked car (the dead EVs, crash
scenes) have their own bodies and are not in this list: check `ev_tow.gd`, `crash_scenes.gd`.

### Item 5. Collider honesty: rule R2 as a check

**Goal.** Nothing invisible stops the car, and nothing collides far outside its drawing.

**Design.**
- `_solid()` (item 0) gets two more arguments at each call site: the drawn height at that place
  and whether the collider's plan is the drawing's plan. `check_solids.gd` fails on: a hard
  class whose drawing is under 0.3 m (PT-47's kind); a collider more than 0.5 m outside its
  drawing in plan; any class not in `solidity.gd`.
- **Pocket walls** (`_bridge_pockets`, about 22,600): each must have both ends within 0.3 m of
  a building face and span a gap under 1.9 m, or close a notch of at most 4.5 × 3 m, or be a
  taper before a step. The check lists the rest. Expect a few hundred to look at.
- **Collider view**: `--colliders` (a test flag): hard faces as a translucent red skin, soft
  segments yellow, pushables blue, pocket walls magenta. For `tools/shots.sh` sets in sweeps and
  for F to see what the car sees.
- **Tram islands and stop platforms**: the track-side faces of a 0.3 m island are solid today
  (PT-1's fix kept them so the car slides along instead of climbing onto the shelter). Measure
  with the contact log whether they stop cars; if they do, make them Ride and keep only the
  shelter hard.

**Acceptance.** The check passes with a short, explained allow-list; before and after contact
tables for the spots it changes; `check_stuck_spots` passes (PT-7 and PT-17 are in it).

### Item 6. Narrow streets and yards

**Goal.** The 16 km of lanes under 2.6 m and the service ways stop feeling like corridors.

**Design.**
- **Collider set back**: for building faces along a street narrower than 8 m between fronts
  (measured in the bake from the lane and the footprints), the collider face moves 0.4 m into
  the building; the drawing stays. Convex corners keep their position (item 7 chamfers them).
- **Yards**: every dead-end service way and living street with no place the game uses (no POI,
  quest point, job stop, garage, drivable bank within 30 m: the bake has all of these) gets a
  gate at its mouth, in the class the look thread draws: closed and hard where the yard behind
  is a trap (no turning room of 8 m), open otherwise. A list of the gated mouths in the PR.
- **Kerb jolt** off on streets under 8 m (`_feel_kerbs`: a flag per lane edge from the bake).

**Acceptance.** Sloppy set A on the P14 streets and ten service-way routes: contacts per km
down by half, no dead stop, no tow. Nothing the game sends the player to is behind a gate
(a check walks every quest, job and ride point to a lane).

**Traps.** The camera's building ghost and the occlusion tests use the drawn walls, not the
collider: unchanged. A car 0.4 m "inside" a facade must not z-fight the ghost: shots at 2532 ×
1170 on Hoża and Kozia, day and night.

### Item 7. Tapers and chamfers

**Goal.** No hard thing ends square to the traffic (rule R3).

**Design.** A bake pass over hard polylines and footprints within 3 m of a lane or service-way
edge: (a) an open end of a wall, guard rail, railing or pier facing along the road gets a
collider-only lead-in of 1:4 (the pattern exists: `WALL_TAPER_LEN`, PT-40's fix on
Poniatowski); (b) a convex building corner with an angle under 120° gets a collider chamfer of
1.2 m. Drawn geometry is not touched; where the lead-in would be invisible and long, the look
thread gets the spot for a drawn end piece (a rail's turned-down end, a bollard).

**Acceptance.** The contact log's "head-on into an end" class (angle over 60° within 1 m of a
polyline end) empty on set A; PT-40's spot in `check_stuck_spots`.

### Item 8. Walls by context, tram platforms, canopies

**Design.**
- **Walls with a height**: under 0.6 m Ride (drawn as a kerb, no collider: `BARRIER_SOLID_MIN`
  already does it under 0.3 m), 0.6-1.2 m Smash (masonry: `smash_wall`, dust, 12 % cost),
  over 1.2 m Hard.
- **Walls with no height** (60.8 km): a context rule in the bake, in this order: around a stair
  or a drop → Hard, 1.0 m balustrade; a closed ring under 6 m across → Ride (a basin, a bed);
  inside a park, a green or a square → 0.5 m, Ride; along a churchyard, a cemetery, an embassy,
  a school, a barracks or an industrial plot (the area's tags) → Hard, drawn as that
  wall; a fragment under 4 m with nothing within 5 m → removed; the rest → Hard, listed per
  street for the sweeps. Heights, from the walls-look thread (it owns what each wall is): park
  or square 0.5 m, planter or basin ring 0.45, housing yard 1.2, church, school or institution
  2.0, works, depot or railway 2.4, cemetery or barracks 2.6, noise screen 4 (6 at a railway),
  unknown 1.6 instead of today's 1.9. A housing-yard wall at 1.2 m sits on the boundary of
  Smash and Hard: it is Hard (masonry on a footing); only walls from 0.6 to under 1.2 m break.
- **Canopies**: `roof` parts with a low base become posts (hard, 0.3 m) and an open underside.

### Item 9. Small things

Stalls Smash (wood and cloth debris, 8 %), carts Push (through item 4's code), kiosks stay Hard
until the look thread has a broken kiosk; busts, stones and steles under 1 m Ghost; a monument
within 1 m of a lane moves back in `bake_monuments.py`; Tamka's bollards Smash for the sound.
Benches, bins and racks stay Ghost; a "scatter" effect for them is a later treat, not a need.

### Item 10. Ratchets

`check_map_data.py`: hard metres within 1 m of a lane by class, and within 1 m of a service
way, may not rise (numbers recorded with each item). Verify step `drivelog` (item 1) becomes a
gate: dead stops, tows and unsticks on set A at most the baseline; contacts per km by street at
most baseline + 10 %.

### Item 11. Street sweeps

The `road-objects-sweep` skill, reading the contact table first: a street is swept when its
numbers are worse than its class's median, and the sweep decides only what the class rules
could not (exceptions into `game/data/road_objects.json`, landmark rings, look).

## 5. Broken things: memory and recovery

F: "how to handle it when it is ruined: the memory of it and the recovery."

### 5.1 What is remembered

One owner: `soft_things.gd`. Not the sector's nodes (they are freed when the sector unloads),
not the save file.

| Thing | Key | What is kept |
| --- | --- | --- |
| A broken fence, hedge or wall panel | the line's stable id (`barrier:fence:x:z`, the census id) + the panel's index along it | when it broke (game clock), from which side |
| A pushed parked car or cart | its index in the map's list | where it came to rest (x, z, yaw), when |
| A smashed stall | its id in `street_details.json` | when |

A dictionary, at most 600 entries; over that, the oldest out-of-sight entry is repaired first.
At 16 bytes an entry this is nothing for memory, and nothing is written to disk while playing.

### 5.2 Three lifetimes, and the one recommended

| Option | What the player sees | Cost | Verdict |
| --- | --- | --- | --- |
| A. Forget on sector unload | drive round the block and the fence is whole again | none | too cheap: it reads as a glitch when the player turns back within a minute |
| **B. Session memory, repaired out of sight** | what you broke stays broken while you are around; come back later and the city has fixed it | the dictionary | **recommended** |
| C. Saved for ever | the city keeps every scar across launches | save size and migration, a city that slowly looks wrecked, and no way back without a repair mechanic | not for version 1; a later "the city sends the bill" feature could build on B's counter |

**Rule B in full.** A broken thing is repaired when all three hold: it is more than 150 m from
the car, it is not in the camera's view, and at least 10 minutes of play (or one in-game dawn,
whichever comes first) have passed since it broke. Repair is instant and unseen: the entry is
dropped, and the next time the sector shows, the thing is whole. A pushed car returns to its
bay under the same rule; one flagged `towed` (it would have rested in a lane) is hidden until
then, as if the tow truck took it. A new launch starts with a whole city.

**What is saved** (`wallet.gd`, a key in an existing section, with its case in `check_save.gd`):
only counters: panels broken, cars pushed, by kind. They cost nothing, give the records screen
a line ("Płoty: 214"), and are what a later invoice, an achievement or a police rule would read.

### 5.3 Recovery for the player

- **Never trapped**: soft things break from both sides (R6), debris has no collider, and a
  pushed car that cannot move answers as a wall that turns the car away (item 2).
- **After a tow or a teleport** (`_tow_to_lane`, POMOC DROGOWA): nothing to reset; the car lands
  on a lane, and lanes never hold a soft thing (the bake cuts them out).
- **Missions**: when an activity starts or resets its scene, it may ask
  `soft_things.repair_near(point, radius)` so a race start or a quest's meeting place is whole.
- **The stuck offer** still works: it counts time spent trying near one spot, whatever the cause.

### 5.4 Recovery for the developer

- `--no-soft` (test flag): every soft thing is hard again, for A/B and for bisecting a bug.
- `soft_things.reset()` on a new game and on `Continue` (session memory never leaks between
  saves).
- The contact log (item 1) records soft contacts too, with their class, so the before-and-after
  tables show what moved from "hard" to "smash".

### 5.5 The seam with the walls-look thread

That thread decides what a fence, a wall or a rail is and how it looks, whole and broken. This
plan gives it three things and asks for one.

- It gets: the class of every barrier (`sc` on each line, and `hz`, the reason, on the hard
  ones, from item 3's bake rule); the events
  `soft_things.broke(id, panel, kind, at, direction, speed)` and
  `soft_things.repaired(id, panel)` (a repair happens 150 m away, but a sector is 512 m, so the
  panel can still be loaded and must stand up again); the query
  `soft_things.is_broken(id, panel)` for when a sector is built again while the entry lives.
  The panel index is `floor(distance along the line / 2 m)` on both sides.
- It decides the broken look, from three ways that cost differently:

| Way | What it is | Draw calls | Needs |
| --- | --- | --- | --- |
| 1 Debris only | panels fly as particles; the fence stays drawn | +1 while a burst plays | nothing (version 1 of item 3) |
| 2 Damage map | the fence's vertices are pushed flat in the vertex shader where a small per-sector texture (one texel per 2 m) says "broken" | 0 | room in the building shader, which is at 504 of 505 on the Adreno budget: it must be slimmed first, or barriers move to their own small shader (+1 material) |
| 3 Instanced panels | fences are `MultiMesh` panels, a broken one swaps to a flat or bent mesh | +1 to +3 a sector | the bench; it also gives the look thread real panel models per fence type |

  Way 3 fits best with "the real type of object" (a panel model per type), way 2 is free at
  runtime, way 1 is what ships first. The choice is that thread's, with the bench as the gate.
  **Chosen (walls-look thread, 2026-11-13, `docs/design/walls-true-to-life.md` section 7)**:
  way 1 with item 3, then way 3: smash things become instanced 2 m panels, one MultiMesh a
  sector with its own small shader, so the building shader is not touched. Way 2 is not used.
  Its steps W1 (types in the bake) and W2 (the heavy kit) do not depend on this plan; W3 to W5
  (panels, broken looks) come after item 3, because both edit `_build_barriers`.
- It is asked for: a drawn difference between Hard and Smash things that a player reads at
  40 km/h (rule R2): heavy and continuous for hard (concrete, stone, steel beam), light and
  see-through for smash (bars, mesh, boards, leaves).

## 6. Gates for every item

Full definition of done (gameplay, geometry, per-frame): `tools/verify.sh`, `--ios`, shots at
phone size day and night on both paths, the bench before and after.

| Gate | Where |
| --- | --- |
| Item 1's table before and after, sloppy and careful, both paths | every item from 2 on |
| `check_stuck_spots`, `check_lane_drive` (streets, Trzy mosty, `--links`), `check_steering`, `check_handling`, `check_stuck_offer`, `check_police`, the race bench's quick marks | every item |
| `python3 -I tools/check_map_data.py` with the new counts recorded on purpose; the whole bake chain after a `centrum.json` change (`bake_sectors.py`, `bake_city.gd` with a renderer) | items 3, 4, 6, 7, 8, 9 |
| Bench: draw calls, script time, sector load time; the phone only with F's yes | items 0, 3, 4, 5 |
| What only the phone can show: how a smash and a push feel through the haptics, whether the debris reads at phone size, the preset F prefers | items 2, 3, 4 |
| Architecture: `solidity.gd`, `contact_log.gd`, `collide_rules.gd`, `soft_things.gd` each with a row in `systems.md`; sounds in `Sfx.SHOTS`; counters in `wallet.gd`; flags in `main.gd` | the item that adds it |
| Add-ons: Beehave and Dialogue Manager not used (no NPC behaviour, reaction lines are line bags) | stated in each PR |

## 7. Risks

| Risk | Likelihood | What limits it |
| --- | --- | --- |
| The car gets into places that were closed by fences and cannot leave, or falls out of the world | high, in a few dozen places | item 3's `--wander` run before merge; hazard fences stay hard; R6 as a check |
| The game gets too easy: nothing to avoid | medium | the presets (F starts from the middle); costs are numbers in one table; structure edges, buildings and traffic are still there; stars, time and police are the price |
| Race marks and ride ratings move | certain for item 2's default change, likely for 3 and 4 | the default changes in its own PR with re-recorded marks, agreed with the racer thread |
| Runtime and prebuilt cities drift apart | medium | soft things come from sector data, not from built nodes; `check_solids` and `check_soft_things` compare both |
| A per-frame script cost on the phone | low | a cell hash, no physics queries except one cast per pushed car; bench gate |
| The shader budget blocks the damage-map look | certain today | way 1 first; way 3 as the alternative |
| Two threads in `car.gd` | certain without care | item 2 inside or after the controls thread |

## 8. Who else is in these files

| File | Other work | Rule |
| --- | --- | --- |
| `car.gd` | the controls thread (steering, lane assist); the racer AI (6a) reads the car model | item 2 with or after the controls thread; marks re-recorded with the racer thread |
| `map_builder.gd` `_build_barriers`, `BARRIER_STYLE` | the walls-look thread; street passes | item 0 lands first (it touches every collider site once); after it, class is data and look is style: separate lines |
| `tools/bake_structures.py`, `object_fixes.py`, `centrum.json` | the road smoothness thread, landmark threads | one map PR at a time through the audit; conflicts in `centrum.json` are resolved by re-running the chain, never by hand |
| `tools/ci_steps.txt`, `verify.sh` | everyone | a sorted line per new step |

## 9. Open questions

For F (in docs/QUESTIONS.md):

1. The four defaults of the research still stand (fences and hedges break everywhere except by
   a hazard; parked cars can be pushed; breaking costs only speed and noise; shelters stay solid).
2. **Memory**: broken things stay broken while you are near and are repaired out of sight after
   about ten minutes; a new launch starts whole (rule B). Or should the city keep its scars
   across launches (C)?
3. **Tram railings in the medians** (Marszałkowska, Jerozolimskie): stay hard, or break like
   fences? Default: hard, decided after the baseline shows how often they are hit.
4. **Go**: items 0 and 1 change nothing a player can feel and can start at once on Opus.

For the walls-look thread: answered 2026-11-13 (the broken look in 5.5, the heights in item
8); still open: the drawn ends for item 7's long lead-ins. It parked one question for F: old
pier-and-iron fences (the university, ministries, churches) break like other fences by default,
the piers stay standing. For this plan a pier is then a Hard post of its own between Smash
panels, which item 3's bake must emit.
