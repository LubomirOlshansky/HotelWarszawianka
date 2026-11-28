# Road objects and collisions: a city that drives smoothly

**Status (2026-11-04):** research and a plan, plus one cloud tool (`tools/road_objects.py`, the
census in section 2) and the skill and agent that run the plan street by street (section 6). No
game code changed with it. Part of the driving-first work (docs/GAMEPLAY_PLAN.md); it builds on
GAMEPLAY_PLAN 1.4 (the drivability sweep) and PR #427 (`check_lane_drive`).

F (2026-11-04): "As the city was made from the map, there are a lot of objects on the roads that
make the arcade driving harder, and a lot of them you can't even tell what they are for. How do we
check every object on the road, street by street, and decide: is it a real object that should be
drawn (like the metro entrance was), something to leave out so driving is easier, or a wall that
matters (on a bridge or an estacade) and needs a better texture or the real object in its place?
And rework the collisions: objects should not stop the player, *walls redirect, never stop*, for
buildings and other cars too. Find the balance: not so casual that it's boring, not hard to drive.
Game cities are designed for smooth handling; mine is a real city with small roads and a lot of
buildings. Driving comes first."

Contents:
1. [Every kind of solid thing beside the road](#1-every-kind-of-solid-thing-beside-the-road): where it comes from, how it collides
2. [The census: what the car can hit, measured](#2-the-census-what-the-car-can-hit-measured)
3. [The classification pipeline, street by street](#3-the-classification-pipeline-street-by-street)
4. [Collision rework: walls redirect, never stop](#4-collision-rework-walls-redirect-never-stop)
5. [Making narrow Warsaw streets drive well](#5-making-narrow-warsaw-streets-drive-well)
6. [Skills, agents and tests that run it](#6-skills-agents-and-tests-that-run-it)
7. [Order of work and the first steps](#7-order-of-work-and-the-first-steps)
8. [How the agents work, and how F checks progress](#8-how-the-agents-work-and-how-f-checks-progress)
9. [Sources](#9-sources)

---

## 1. Every kind of solid thing beside the road

Everything the car collides with ends up in one of two places: the city's collider faces
(`map_builder.gd` `_wall_faces`, one `ConcavePolygonShape3D` per 1,000 faces per sector,
backface collision on), or a few `StaticBody3D` boxes made by the prop scripts. Traffic cars and
trams are `AnimatableBody3D`s (moving, "not fixed" to the car). Lamps, signals, trees, benches,
bins, bike racks, advertising columns, kerbs, islands, medians and low platforms have **no
collider** (the easy-driving loop and loop 3b took them out).

| # | Object | Source (bake) | Drawn as | Collider (game) | Cleared from lanes today |
| --- | --- | --- | --- | --- | --- |
| O1 | **Fences** (191 km) | OSM `barrier=fence` → `lines` k fence (`bake_osm.py` ~l.1020) | a flat grey slab 0.12 × 1.6 m (`BARRIER_STYLE`) | both faces, 3.1 m tall (`_wall_along`) | parts in a carriageway or a lane's 1.7 m corridor cut (`bake_structures.clear_carriageways`) |
| O2 | **Walls** (71 km) | OSM `barrier=wall`, `retaining_wall` → `lines` k wall | grey slab 0.35 × 1.9 m | 3.4 m | as O1; Castle garden rings drawn as 0.45 m kerbs (`GARDEN_RINGS`) but still solid |
| O3 | **Hedges** (22 km) | OSM `barrier=hedge` → `lines` k hedge | green slab 0.9 × 1.2 m | 2.7 m | as O1 |
| O4 | **Stairwell walls** of underpasses and metro stairs (~100 within 3 m of a lane) | OSM `barrier=wall/fence` around `highway=steps` | the same 1.9 m slab (real balustrades are ~1 m: BACKLOG "Rondo Dmowskiego") | solid | no special rule |
| O5 | **Retaining and structure walls** (1,495 + 20 tunnel) | `bake_structures.place_walls` / `place_tunnels` → `walls` k stone/concrete/tunnel | stone or concrete faces with a coping | `_build_walls` | they *are* the road's edge on approaches, ramps and tunnels |
| O6 | **Guard rails** (364) | `bake_roads` on every deck edge + OSM `barrier=guard_rail` → `guards` | steel beam on posts, 0.55-0.85 m | 1.9 m faces | deck rails lose the parts in a lane on their own deck |
| O7 | **Piers and portal legs** (359) | `bake_structures` R5 → `decks.piers` | concrete boxes under decks | `_pier`, `_ms_pier`, `_pn_pier`, `_pv_pier` | slid along the deck until clear of every lane (PT-18: more beside main roads) |
| O8 | **Rail platforms** (144 with h ≥ 0.5 m) | OSM `railway=platform` areas → `platforms` | a 0.9 m slab | edges not along a road (`SOLID_PLATFORM`, `_by_road`) | edges beside roads are open |
| O9 | **Parked cars** (4,901) | `bake_osm` parking lanes → `parked` | the parked saloon | a 1.8 × 4.2 × 1.5 m box | a car whose box reaches a lane corridor left out |
| O10 | **Shelters** (385 solid) | OSM `shelter`/`amenity=shelter` → `shelters` | tram/bus shelter | a 4 × 1 × 2 m box (`_props` solid 4.0) | footprint in a lane left out |
| O11 | **Buildings** (7,367 low-based) | OSM outlines / GUGiK LoD2 | the city | every wall face with a base under 2 m, 5 m tall (`_build_buildings`, `_build_lod2`) | LoD2 walls inside a lane not solid (`lod2_open`, 330 boxes) |
| O12 | **Small buildings** (3,080): canopies (`roof` parts with a low base: 64 solid at 4 m), `steps` as buildings, `column`, `kiosk`, `service`, garages, sheds | OSM `building=*` small outlines | an extruded box | as O11 (a canopy over a petrol station or a metro stair is a solid block) | under 30 m² inside a lane left out |
| O13 | **Pocket walls** (~22,600) | runtime `_bridge_pockets` (PT-7, PT-17) | nothing (invisible) | 2.4 m faces across slits, notches, bays and steps | never on a carriageway |
| O14 | **Street-detail props**: kiosks, stalls, carts | `bake_street_details.py` → `game/data/street_details.json` | the character props | boxes (`street_details.gd` SOLID) | kept clear of every solid and the carriageway |
| O15 | **Monuments** (818, 286 solid kinds) | `bake_monuments.py` → `monuments.json` | generic statues, stones, steles | boxes (`monuments.gd` SOLID) | moved off roads within SNAP m |
| O16 | **Park pieces** (fountains, carousels, gazebos...) | `bake_park_details.py` | park kit | boxes | inside parks only |
| O17 | **Landmarks** (hand-built) | `landmarks.gd` sites | the landmark | `_collide_raw` + pocket rings | per site |
| O18 | **Tunnel portals, frames, garage doors, aprons** | `bake_structures` | portal faces | `_build_portals`, `_build_garage_doors` | by construction |
| O19 | **Edge roadworks** | `edge_roadworks.gd` | barriers at the map edge | one box per closure | at the map edge only |
| O20 | **Moving**: traffic, trams, buses, police | `traffic.gd`, `trams.gd` | | `AnimatableBody3D`; the player shoves them (`_shove`) | |
| O21 | **Map edge** | `_add_edge_walls` | nothing | boxes 5 m in | |

So the bake already removes anything *in* a lane. What F feels is the next ring out: the
objects standing 0-3 m past a lane's edge (a car on the outer half of a lane, cutting a corner,
swerving round traffic, or driving on the pavement, as arcade players do), and the objects whose
look doesn't explain them (a 1.9 m grey slab that is really a 1 m balustrade, a 4 m block that is
really a canopy on posts, 191 km of identical fence slabs).

### 1.1 How the car collides today (`car.gd`, 2026-11-04)

- `move_and_slide`, then the part of the velocity going into each contact is taken out; what slides
  along is kept, less a scrape of `SCRAPE` 1.2/s scaled by how hard it presses (PT-1).
- **Glancing** (the nose 3°-64° off the wall): the nose turns along the wall at `WALL_TURN` 3 rad/s.
- **Head-on** (over ~64°): no turn; the speed into the wall is lost and the car is pushed back
  `min(lost × 0.12, 1.2)` m/s. **At 50 km/h into a wall the car stops dead and rolls back 1.2 m/s.**
- **Corner slip**: a front corner clipping something small sidesteps the car up to 0.6 m (`_corner_slip`).
- **Pinned** 1.5 s → turned out of the wall (`_unstick`); pinned again → towed; stalled 8 s → tow offer.
- **Wall follow**: pointing into a wall it touches, the car follows the wall. This lives in the
  *point-to-steer* branch only (`target_dir`). Since 2026-11-04 the default controls are
  **Classic** (steer + GAZ/HAMULEC), so the default player no longer gets it. This is the single
  biggest reason a head-on hit now "stops" the player.
- **Traffic**: the hit car is shoved (`SHOVE_ALONG` 0.4, `SHOVE_SIDE` 0.4); the player keeps
  `CAR_KEEP` 0.5 of the speed that went into it; held 1.5 s the player ghosts through for 3 s.

---

## 2. The census: what the car can hit, measured

`python3 -I tools/road_objects.py [--json=OUT] [--street=NAME]` (new, standard library, 3 s, reads
`game/map/centrum.json` and the prop files, so it runs in the cloud). For every object above that
is solid it samples a point a metre and measures the gap to the nearest lane's edge (lane centre ±
half its width; ground objects against ground lanes, deck rails against their own deck's lanes,
tunnel walls against tunnel lanes). Main, 2026-11-04:

| Class | Objects | In a lane | 0-1 m past the edge | 1-3 m | 3-6 m | at a junction (<14 m) | solid metres within 3 m |
| --- | --- | --- | --- | --- | --- | --- | --- |
| barrier (fence, wall, hedge) | 8,098 | 18 | 486 | 682 | 1,186 | 275 | 24,131 |
| guard rail | 364 | 11 | 310 | 20 | 10 | 78 | 21,766 |
| building | 7,367 | 48 | 53 | 315 | 1,433 | 103 | 7,738 |
| structure wall | 1,515 | 73 | 164 | 176 | 113 | 100 | 5,632 |
| rail platform | 144 | 69* | 18 | 9 | 16 | 18 | 5,189* |
| parked car | 4,901 | 41 | 371 | 268 | 102 | 44 | 3,435 |
| shelter | 385 | 0 | 14 | 257 | 44 | 15 | 2,283 |
| small building | 3,080 | 0 | 12 | 89 | 222 | 7 | 747 |
| pier | 359 | 0 | 0 | 22 | 64 | 3 | 92 |
| street prop, monument, park piece | 321 | 0 | 1 | 26 | 30 | 4 | 113 |

\* the census doesn't yet apply `_by_road` (platform edges along a road are open in the game), so
platforms are over-counted; the rows "in a lane" are mostly those open edges. Buildings "in a
lane" (48) are lanes through gateways (`bramy`) and passages, where the game draws LoD2 and opens
`lod2_open`: each needs a look (section 3, rule B4).

What it says:

1. **Fences are the biggest class by far** (410 fence objects within 1 m of a lane, 114 of them at
   a junction). Most are real (tram-track fences in the medians of Jerozolimskie, Marszałkowska,
   Jana Pawła II, Okopowa, Prosta; school and park fences), but they are all the same flat slab,
   so the player can't read them, and the median fences are exactly where a car swerving round
   traffic touches.
2. **Parked cars** are the second (412 within 1 m): on residential streets (Wspólna, Noakowskiego,
   Polna) the parked row stands at the lane's edge, so a 1.8 m car on a 2.75 m lane has 0.5 m each side.
3. **Guard rails and structure walls** are the road's real edge on bridges, estacades, ramps and
   tunnels (Armii Ludowej, Most Łazienkowski, Poniatowski, Świętokrzyski, the primary links, Tunel
   Wisłostrady). They *should* be there and be solid; what they need is the collision rework
   (section 4) and a look that reads as a barrier.
4. **Living streets and courtyards** (`(unnamed living_street)`: 2,008 building metres within 3 m)
   are the narrow, walled part. Most are service ways into yards the player has no reason to enter.
5. **Stairwell walls** (~100 within 3 m of a lane, F's metro example) stand at 1.9 m in junction
   islands and on pavements: real balustrades are ~1 m and read as part of the metro entrance.
6. **Canopies as solid blocks** (`roof` parts with a low base, 64): petrol stations, metro and
   tram canopies, drawn and collided as 4 m boxes where the real thing is a roof on posts.

Top streets by solid metres within 3 m of a lane's edge: Aleje Jerozolimskie 5,091 (guard rails,
tram platforms, median fences), Armii Ludowej 4,457 (deck rails, tunnel walls), Jana Pawła II
4,117, the primary links 3,753, living streets 3,256, Tunel Wisłostrady 2,491, Most Łazienkowski
2,313, Solidarności 2,178, Poniatowski 2,124, Most Świętokrzyski 1,932, **Marszałkowska 1,760**
(tram platforms, median fences, shelters), Wybrzeże Kościuszkowskie 1,757, Prosta 1,537, Okopowa 1,500.

---

## 3. The classification pipeline, street by street

One loop that runs the same way for every street, so that what stays on the road is a decision,
not a leftover of the bake. Driving first, city fidelity second: when the two disagree on a
public street the player drives, drivability wins and the look is kept by other means (a lower
object, a texture, a decal).

### 3.1 The verdicts

| Verdict | Meaning | How it is applied |
| --- | --- | --- |
| **KEEP** | real, reads right, drives fine | nothing |
| **RETEXTURE** | real and in the right place, but it reads as a grey slab (a fence, a balustrade, a guard rail, an estacade wall) | a style from the object library (3.4): height, material, posts, openness; collider unchanged or lower |
| **REPLACE** | a real object, drawn wrong (a canopy as a block, steps as a box, stairwell walls as 1.9 m slabs) | the real model from the library (metro canopy, balustrade, petrol-station roof on posts); the collider follows the real shape (posts, not a block) |
| **SOFTEN** | real and drawn, but the car should not be stopped by it | drawn, but the collider becomes a soft one (section 4.4): fences, hedges, parked-car corners, bollards, low walls a car would push or ride over in an arcade game |
| **REMOVE** | not worth what it costs the driving, and the player won't miss it (a fence across a service mouth, a parked car in a pinch, a wall fragment with no purpose) | left out in the bake |
| **CHECK** | the pipeline can't decide: needs the orthophoto, street-level imagery, F's photos or a playtest | listed per street with the evidence missing; never silently kept |
| **A/B** | the decision is a feel question (keep the Marszałkowska tram fences solid or soft?) | both versions behind a test flag; Autopilot row and `check_lane_drive` numbers for each; F decides on the phone |

### 3.2 The stages

| Stage | What | Where it runs | Tool |
| --- | --- | --- | --- |
| S1 **Census** | every solid object with a stable id (class, kind, rounded centre), band, gap, street, junction | cloud | `tools/road_objects.py --json` (built) |
| S2 **Rules** | the automatic verdict from map context (3.3) | cloud | `tools/road_objects.py --classify` (to build, in the same file) |
| S3 **Drive evidence** | which objects the real car actually touches: `check_lane_drive` along every lane of the street (and `check_drivability` when it exists) with a contact log (point, normal, collider, speed lost); each contact is matched to the census id it hit | cloud (headless Godot, the cloud recipe) or Mac | `check_lane_drive.gd --street=NAME --contacts=FILE` (to add to #427's check) |
| S4 **Aerial evidence** | for every CHECK and every contact: a 40 × 40 m crop of the GUGiK orthophoto with the object and the lanes drawn on it (`tools/overlay_ortho.py`, `overlay_structures.py`) | **Mac** (the orthophoto is in `data/work/demo/ortho.bmp`; GUGiK is blocked from the cloud) | `overlay_ortho.py` per row (a `--rows=FILE` batch mode to add) |
| S5 **Street-level evidence** | the nearest open street-level photos of each CHECK object, facing it | **cloud** (`tools/street_photos.py X Z --list`; F allowed the hosts and made a Mapillary app 2026-11-04) | Mapillary (CC BY-SA 4.0, the client token `MAPILLARY_TOKEN` from F's free developer app), Panoramax (open licences, no key), KartaView (CC BY-SA). Google Street View via `tools/streetview_fetch.py` (F, 2026-11-26; reference only, key `GOOGLE_STREETVIEW_KEY`); Bing Streetside only to corroborate, never copied. Photos are evidence for the decision, not textures: nothing from them is drawn in the game |
| S6 **F's photos** | landmarks and anything tier S/A (the photos-only rule): F's own photos or a `refs/<slug>/` Mac gather | Mac / F | `model-from-photos` skill |
| S7 **Decide** | an agent (`road-auditor`, section 6) reads S1-S6 per street and writes the verdicts into `game/data/road_objects.json` (`{id: [verdict, style, note]}`), the one override file the bake and `map_builder.gd` read | cloud | the skill `road-objects-sweep` |
| S8 **Apply** | REMOVE / SOFTEN / RETEXTURE / REPLACE by id in the bake (`bake_structures` reads the override file next to `clear_carriageways`) or in `map_builder.gd` (styles, soft colliders) | cloud + Mac re-bake | |
| S9 **Verify** | `check_lane_drive` on the street before and after (contacts per km, speed kept, pins), `check_stuck_spots`, shots by day and night, `--prebuilt` too; A/B rows to Autopilot | cloud + Mac | |
| S10 **Keep it fixed** | the street's contact numbers join a baseline (`tools/road_objects_baseline.json`); a later bake that adds a solid within 1 m of a lane on a swept street fails `check_map_data.py` | CI | |

The stable id is what makes it street by street: a re-bake that moves a fence by 10 cm keeps its
id (rounded to 2 m cells plus class and kind), and the override file survives re-bakes, as
`check_roads_allow.json` does today.

### 3.3 The automatic rules (S2), by class

Each rule gives a verdict and a confidence; anything under "sure" becomes CHECK.

| Rule | Condition (map data only) | Verdict |
| --- | --- | --- |
| B1 deck edge | guard rail or structure wall on a deck, a ramp, an approach or in a tunnel | KEEP solid (the road's edge), RETEXTURE where it reads as a slab; collisions handled by section 4 |
| B2 median fence | fence in a median or tram bed, parallel (< 15°) to the lane, within 3 m | KEEP, SOFTEN in A/B (the PT-1 fence on Marszałkowska) |
| B3 fence across a mouth | fence or wall crossing a service way, a driveway or a junction mouth within 3 m of a lane | REMOVE (a gate left open) or REPLACE with a gate model if it is a yard's gate (CHECK) |
| B4 lane through a building | a lane under a building outline (a `brama`, a passage) | CHECK (aerial + street level): open the passage (`lod2_open`) and draw the arch, or take the lane out |
| B5 stairwell | wall or fence within 8 m of `highway=steps` or a `subway_entrance`, closed or U-shaped round the stair | REPLACE with the balustrade (1 m, glass or steel by station: library) and, at metro stairs, the canopy (`Props.add_metro_entrance`) |
| B6 canopy | `roof` part or a small building with a low base under 30 m² near a road, a station or a fuel `amenity` | REPLACE: a roof on posts (posts solid, the space under drivable or a pedestrian zone) |
| B7 parked in a pinch | parked car whose lane's free width (lane width + gap each side) is under 3.6 m, or within 15 m of a junction | REMOVE (keep every other one on narrow residential streets) |
| B8 parked row | the rest of the parked cars | KEEP, SOFTEN corners (section 4.4) |
| B9 hedge, low wall | hedge or wall under 1.2 m real height beside a lane | SOFTEN (rides through with a scrape, leaves) |
| B10 garden ring | closed wall ring under 6 m across (fountain basins, beds) | RETEXTURE as a kerb and not solid (today: drawn low, still solid) |
| B11 courtyard wall | wall or fence of a yard, school or park, parallel to the street on the far side of the pavement (> 3 m) | KEEP |
| B12 unexplained fragment | a barrier piece under 4 m long with no building, steps or area near it | REMOVE |
| B13 shelter | shelter within 1 m of a lane, on a tram island | KEEP; corner SOFTEN |
| B14 living-street yard | a dead-end living street or service way into a yard (no POI, no quest uses it) | gate it at the mouth (a closed gate model, a soft barrier) so the player never drives in to get stuck; GAMEPLAY_PLAN 2.4 |
| B15 monument, kiosk | solid monument or kiosk within 3 m of a lane | KEEP if real (CHECK against the ortho), else move to the pavement's far side |

### 3.4 The object library (what RETEXTURE and REPLACE draw)

A short kit, one material each where possible (the draw-call gate): fence styles (tram-track
railing: low steel with posts; park fence: black steel bars; construction hoarding; school
mesh), balustrade (granite with a steel rail; glass for the newer metro), guard rail (exists),
estacade parapet (concrete with a coping and a darker drip line, the Trasa Łazienkowska look),
concrete Jersey barrier, bollard rows, canopy on posts (station, fuel), metro entrance forms
(exist: vault, stairwell, tube), yard gate (closed, open). Styles ride in the override file, so a
retexture is data, not code. Photo-way rule: a style for a named landmark's surroundings comes
from F's or the Mac's photos.

---

## 4. Collision rework: walls redirect, never stop

### 4.1 What the arcade city games do

| Game | Walls | Traffic | What we take |
| --- | --- | --- | --- |
| Burnout 3 / Paradise | scraping a wall at a shallow angle never crashes you: you grind along it with sparks, keep most of the speed, and only a near head-on hit at speed is a "crash" | traffic cars are light: you check them aside (Takedowns) | a shallow hit keeps 90 %+, the sparks are the cost |
| Mario Kart | a wall bounces you back a little and turns you; you are never pinned, and lap time is the penalty | rival karts bump and both lose a little | a small, readable cost per hit, never a stop |
| Crazy Taxi | you smash through small props, bounce off cars; buildings redirect; the timer is the penalty | cars are knocked aside | the penalty is time and fares, not physics |
| GTA 2, Chinatown Wars (top-down) | cars pivot round building corners; small props (fences, bins, hydrants) break | cars push and spin | breakable small things, pivot on corners |
| Micro Machines, Art of Rally (high camera) | the camera is close to the handling; a hit is clear on screen | | the hit must read on a small screen |

The shared rule: **the cost of a mistake is time, money or a star, never a dead stop**. The
physics only stops you for a deliberate full-speed head-on, and even then you can drive on at once.

### 4.2 The target response, by angle of impact

The angle θ between the car's velocity and the wall (0° parallel, 90° head-on). Numbers are the
starting point for the A/B, measured on the phone; Cruise is the default profile.

| θ | Today (car.gd) | Target, Cruise | Target, Sport |
| --- | --- | --- | --- |
| < 15° (grind) | keeps cos θ, nose turned along, scrape 0.18-1.2/s | keeps 97 %, nose turned along, sparks, no haptic | 95 % |
| 15-45° (glance) | keeps cos θ (71 % at 45°), turned along at 3 rad/s | keeps 85 % (at 45°), turned along at 6 rad/s, one knock sound | 75 % |
| 45-75° (hard) | keeps cos θ (26 % at 75°), turned along only to 64° | keeps 55 %, **deflected** along the wall towards the side the nose leans (the reflection, damped: 60 % tangential, 15 % normal bounce) | 40 % |
| > 75° (head-on) | stops, 1.2 m/s back, pinned after 1.5 s | keeps 30 % as a bounce **and** a yaw kick of 35-50° towards the freer side (a box-cast left and right), so the next frame drives away; no pin possible | 20 %, smaller kick |
| a corner of a building or wall (convex) | corner slip only for small things | pivot round it (GTA 2): the contact point becomes a pivot, the car keeps 80 % and rotates round the corner | |

F (2026-11-04): "97 % of the speed is too arcade; test it later." So these numbers are the
upper end of a range, not the pick: collision v2 reads them from one table (a "Zderzenia" /
collisions strength setting or a test flag with 2-3 presets, e.g. grind keep 97 / 90 / 80 %),
and F chooses on the phone. Start the A/B at the middle preset.

That is not trivial: a hard hit still costs 45 % of the speed, sparks, a sound and a haptic, and
(through the game, not physics) a ride star, race time, police interest. It just never leaves the
player facing a wall at 0 km/h.

How it maps onto `car.gd` (no new physics engine, the same `move_and_slide`):

- **C1 angle response**: after `move_and_slide`, compute θ from `vel` and the summed normal; set the
  new velocity from the table (tangential keep × speed along the wall's tangent on the side the
  nose leans, plus a normal bounce), instead of today's "remove the normal part" plus
  `WALL_PUSH`. Turn the nose towards the new velocity at `WALL_TURN` 6 rad/s (Cruise).
- **C2 wall follow for every control scheme**: the point-to-steer wall follow moves out of the
  `target_dir` branch: with Classic, steering towards the wall while touching it follows the
  wall; no steering picks the side the nose leans. This restores the old feel to the new default.
- **C3 head-on kick**: θ > 75° and speed > 4 m/s: two `test_move` box casts (yaw ± 45°) pick the
  freer side; the yaw kick goes that way. Under 4 m/s nothing (a gentle nudge parks against walls).
- **C4 no pin by design**: with C1-C3 the pinned timer should never fire except in a real trap;
  keep it as the safety net, and log every unstick in the drive checks as a defect.
- **C5 corner pivot**: a contact within 0.6 m of a convex collider corner (the contact normal
  turns more than 40° within a frame or two) rotates the car round the contact; the bake's
  forgiveness bevels (GAMEPLAY_PLAN 2.3) do the same in the geometry and are cheaper: do both,
  bevels first.
- **C6 the feedback stays**: sparks (`scraped`), the knock sound, a haptic only above 4 m/s lost,
  and the chatter budget's single reaction. The costs a player cares about live in the game:
  ride stars, race seconds, police.

### 4.3 Traffic cars

Today the player keeps half of the speed that went into a car and the car is shoved 0.4 of it.
In a city full of traffic this is where most "stops" come from after walls.

| Case | Target |
| --- | --- |
| Rear-ending a car (θ < 30°) | the player keeps 75 % (Cruise), the car is shoved forward and a little aside, the player is steered round it (the corner slip with a bigger reach, 1.0 m, for cars) |
| Side swipe | both keep most of their speed, the traffic car is pushed off its line and recovers (traffic's `SHOVE_SIDE`) |
| T-bone, head-on into a car | the traffic car spins out of the lane (a light car: Burnout's check), the player keeps 40 % and is deflected like a wall's C1 |
| Queue at a red | unchanged: nosing into the car ahead is not a hit |
| Mass | traffic cars are treated as 0.6 of the player's car for the shove, buses and trams as walls (C1) |
| Held against cars | ghost after 1.5 s (exists), lower to 0.8 s in Cruise |

### 4.4 Soft colliders (SOFTEN)

A soft object is drawn, and the car slows and is nudged by it but never stopped: a separate
collision layer the car reads with a `test_move`/`intersect_shape` per frame (no physics
response), giving drag (fence 20 %, hedge 35 % of the speed per second while inside), a sideways
push out of it, sparks or leaves, and a sound. For a fence, the knocked-flat look (a few bent
panels, reset when the sector reloads) is the GTA 2 / Crazy Taxi reward. Hedges and low walls
the same with leaves or dust. Parked cars: their corners soft (the car slides off the rounded
corner), their long sides solid (they read as cars).

Perf: one shape query per frame against a small layer (the soft objects within 10 m), only above
5 km/h; the bench before/after is part of the change (the performance gate).

### 4.5 Measuring the balance

"Not trivial, not hard" needs numbers the checks report for every street and every A/B:

- **contacts per km** at the street's speed (target under 0.5 on a main street, under 2 on a
  narrow one), **speed kept per contact** (target ≥ 70 % median), **time to full speed after a
  hit** (target under 2 s), **unsticks and tows** (target 0), and the **share of the drive above
  80 % of the speed limit**.
- They come from `check_lane_drive` (PR #427) with a contact log, and later `check_drivability`
  (GAMEPLAY_PLAN 1.1) over every lane and turn. A "sloppy driver" mode (aims 1.5 m off the lane
  centre, late in corners, ±10° noise) measures what a phone player meets, not what a perfect
  line meets.
- Autopilot rows (section 6) for the feel the numbers can't give; F's phone run decides.

---

## 5. Making narrow Warsaw streets drive well

GAMEPLAY_PLAN 1.3 found ~300 lanes under 2.5 m (Frascati, Hoża, Ordynacka, Sienna, Aleja 3 Maja,
the living streets) and PT-21 found hard slow-downs on four of them. Ideas, the cheapest first:

1. **The collision corridor is wider than the drawn street.** The player's car collides with a
   "drive hull", not the drawn geometry: buildings' collider faces are pushed 0.3-0.5 m back from
   the facade on streets under 8 m between facades (the facade still draws where it is; at the
   game's camera nobody sees a car's mirror inside a wall). Same for walls and fences beside a
   lane. A bake rule on collider faces only, per street class.
2. **Parked cars on narrow streets**: rule B7 (every other one, none within 15 m of a junction),
   or move the row half onto the pavement as Warsaw actually parks (`parking:lane=half_on_kerb`
   is in OSM on many of these streets).
3. **One-way streets as one wide lane**: a one-way street under 6 m gets one lane in the middle
   (traffic drives the centre), not a lane hugging a kerb. Lane graph data (GAMEPLAY_PLAN 1.2).
4. **Kerbs that don't jolt in narrow streets**: no kerb jolt on streets under 8 m (the car rides
   half on the pavement all the time there).
5. **Glancing deflection** (4.2 C1) does most of the rest: in a narrow street every touch is a
   graze, and a graze keeps 97 %.
6. **Lane assist** ("Asysta pasa", GAMEPLAY_PLAN 1.5 #1): strongest where the street is narrow
   (k from the free width: 1.5/s on avenues, 3/s under 4 m), so the car centres itself between
   the walls when the player isn't steering hard.
7. **Wall look-ahead** (GAMEPLAY_PLAN 1.5 #2): a 0.5 s box cast ahead; a shallow wall gets a
   small steer away. In narrow streets this is the "auto-steer" that makes threading easy.
8. **Corner fillets and bevels**: kinks over 45° filleted in the lane graph, convex collider
   corners within 3 m of a lane chamfered 1-2 m (GAMEPLAY_PLAN 2.3).
9. **Speed shapes the street**: a street's zone cap (the pedestrian zone's 20 km/h exists) for
   living streets and courtyards, so the car arrives slowly where it's tight; race routes avoid
   them unless authored as a shortcut.
10. **Trap dead ends gated** (B14), public ones with turning space.
11. **Camera**: in a street under 10 m wide, zoom in one step and lead the look-ahead along the
   street; the ghost already dithers buildings in front.

Order for the narrow streets: 5 (with section 4), 1, 2, then 6-7 behind settings; 3 and 8 are
lane-graph and bake work with a Mac re-bake.

---

## 6. Skills, agents and tests that run it

Added with this plan:

- **Skill `road-objects-sweep`** (`.claude/skills/road-objects-sweep/SKILL.md`): the per-street
  loop (S1-S10): pick the street (the order in section 7), census, rules, drive evidence, the
  Mac evidence list, verdicts into the override file, apply, verify, baseline. One street group
  per thread and PR, with before/after numbers.
- **Agent `road-auditor`** (`.claude/agents/road-auditor.md`, Opus: map geometry and driving
  judgement): reads one street's census rows, contacts and crops, writes verdicts and the CHECK
  list; never edits game code. Bulk rule runs and counts go to `scout` (Haiku); applying a spec
  of retextures to `object-modeler` (Sonnet).

Tests, new and extended (the drive numbers are the gate):

| Id | Check | What |
| --- | --- | --- |
| RO1 | `tools/road_objects.py` | the census (built); `--classify` adds S2; a summary line in `check_map_data.py` later (S10) |
| RO2 | `check_lane_drive.gd` (#427) | `--street=`, `--contacts=` with the collider and census id, a sloppy-driver mode, the 4.5 numbers per street |
| RO3 | `check_steering.gd` | angle cases for 4.2: 10°, 30°, 60°, 90° into a wall at 30 and 60 km/h, Classic and Point; speed kept and heading after 1 s; never pinned |
| RO4 | `check_handling.gd` | traffic cases for 4.3: rear-end, side swipe, T-bone |
| RO5 | `check_stuck_spots.gd` | every spot a sweep fixes (as today) |
| RO6 | `check_drivability.gd` (GAMEPLAY_PLAN 1.1) | every lane and turn; per-street score; uses the same contact log |

Autopilot rows (Mac, under 6 minutes each), to add to docs/PLAYTEST.md when first run:

| # | Area | Kind | What to look for |
| --- | --- | --- | --- |
| P18 | Marszałkowska and Jerozolimskie at traffic speed, weaving round traffic | test | every contact with a median fence, a shelter, a parked car; speed after each |
| P19 | A/B: the same route with the collision rework on and off (`--collide=v2`) | test | contacts, time lost, unsticks; the frames at each hit |
| P20 | Narrow streets steered (Hoża, Wilcza, Poznańska, Frascati) with lane assist on and off | test | grazes, stops, how often the car sits at 0 km/h |

---

## 7. Order of work and the first steps

Driving first. Each line is one thread and one PR.

| # | Task | Who | Needs |
| --- | --- | --- | --- |
| **1** | **Collision rework v2 (4.2 C1-C4, 4.3)** behind `--collide=v2` and a setting, with RO3/RO4; Classic gets the wall follow (C2) at once, since it is a regression of today's default | Opus (gameplay feel) | cloud; then F's phone A/B |
| **2** | `check_lane_drive` contact log, `--street=`, sloppy driver (RO2) on top of #427 | Opus or Codex for the harness | #427 merged |
| **3** | First street group with the sweep skill: **Marszałkowska + Świętokrzyska + Jerozolimskie** (first-10 streets, top of the census): S1-S3 in the cloud, S4-S5 list for the Mac | Opus (`road-auditor`) | the Mac for the ortho crops and street-level photos |
| 4 | Stairwell balustrades and metro canopies city-wide (B5, B6): the "metro entrance" class, a REPLACE with no doubt | Sonnet (`object-modeler`) | none (the forms exist) |
| 5 | Soft colliders (4.4) for fences, hedges, parked-car corners; A/B on Marszałkowska's median fences | Opus + bench | phone bench |
| 6 | Narrow streets: drive hull (5.1), parked cars B7 (5.2), kerbs (5.4); then the lane assist and wall look-ahead (GAMEPLAY_PLAN 3.1-3.2) | Opus | Mac re-bake for 5.1 |
| 7 | The rest of the centre street by street (the census order), with the override file and the baseline | the sweep skill, one group per thread | the Mac for evidence |

Recommended first steps for F: say yes to **1** (the biggest feel change, and it fixes the head-on
stop that the Classic default brought back), let **2** follow #427, and let **3** use the Mac
for the orthophoto crops. The street-level photos now come from the cloud: F allowed
`graph.mapillary.com`, `*.fbcdn.net` and `api.panoramax.xyz` and made a Mapillary developer app
(2026-11-04, token in the environment as `MAPILLARY_TOKEN`). Panoramax's own images sit on
`panoramax.openstreetmap.fr`, which needs allowing too before they can be saved.

F (2026-11-04) liked the plan. The progress console F asked for at the same time (a local map of
every built thing by approach, data used, roads, objects, and what waits for F) is its own thread
("Build city progress console"); the census JSON here is one of its layers.

---

## 8. How the agents work, and how F checks progress

### 8.1 Who does what in one street sweep

```
coordinator (project chat)        hands out one street group per thread, the merge queue
  └─ thread session (Opus)        runs the road-objects-sweep skill, owns the PR
       ├─ scout (Haiku)           counts: census rows per class, contact logs, before/after tables
       ├─ road-auditor (Opus)     the judgement: a verdict per object with its evidence, the CHECK list
       ├─ object-modeler (Sonnet) builds the RETEXTURE / REPLACE styles and models from a spec
       ├─ gameplay-dev (Sonnet)   applies a specified collision or assist change
       └─ qa-tester (Sonnet)      verify.sh, shots, check_lane_drive before/after
  Mac (only with F's yes)         orthophoto crops, Commons photos, Autopilot rows, the phone
```

A sweep thread, start to end:

1. **Measure** (cloud, minutes): `road_objects.py --street=` for the group, `check_lane_drive
   --only=` both ways and on `--prebuilt` → the "before" (contacts per km, speed kept, unsticks).
2. **Evidence** (cloud): `street_photos.py` for every object the rules can't decide; one batch
   request to the Mac for the orthophoto crops.
3. **Decide**: road-auditor writes a verdict per object; anything it can't back up stays CHECK.
4. **Apply**: the override file by id, the bake or map builder rule, the library styles and models.
5. **Verify**: the same drive → the "after"; stuck spots joined; shots day and night; bench if
   anything was added.
6. **PR**: before/after table, the CHECK and A/B list, BACKLOG and ROADMAP ticked; merge when green
   and the coordinator gives the slot.

### 8.2 What F looks at, and when

| Where | What it shows | When it changes |
| --- | --- | --- |
| **The PR** of each street group | the before/after table (contacts per km, speed kept, unsticks), the verdict counts, shots of the changed objects | every sweep |
| **ROADMAP "v1.0 checklist"**, "Left: road objects and collisions" | one ticked line per finished step | every PR |
| **BACKLOG** "Road objects and collisions" | the open steps and new finds | every PR |
| **QUESTIONS** | every CHECK and A/B that waits for F: what was built as the default, what to look at | when a sweep parks one |
| **The progress console** (its own thread) | the map: every object by verdict, streets by score, buildings by approach and data used, what waits for F | after each merge |
| **The phone** | the feel: Cruise and Sport, collision v2 on and off | F's device runs |

What needs F, always: the A/B feel calls (collision v2, soft fences, lane assist strength), any
landmark's photo look check, device runs, and the Mac runs (Autopilot rows bill F's Aura account).
Everything else a sweep decides itself and lists in its PR.


---

## 9. Sources

- GAMEPLAY_PLAN 1.1's sources (Game Developer on arcade track design, top-down racing cameras;
  Jalopnik on Art of Rally's camera).
- [Avoiding walls in Mario Kart DS and wall-assisted bouncing](https://setsideb.com/?p=10010): how
  Mario Kart's walls bounce and turn the kart instead of stopping it.
- [Burnout 2: Point of Impact preview (Gaming Nexus)](https://www.gamingnexus.com/Article/231/Preview)
  and [Crazy Taxi (Hardcore Gaming 101)](https://www.hardcoregaming101.net/crazy-taxi/): crashes,
  traffic and the time penalty in arcade city driving.
- [Street-level imagery services (OpenStreetMap wiki)](https://wiki.openstreetmap.org/wiki/Street-level_imagery_services):
  Mapillary and KartaView CC BY-SA, Panoramax open licences (CC BY-SA 4.0, etalab 2.0), Bing
  Streetside only as corroboration, Google Street View not usable.
- [Mapillary (OpenStreetMap wiki)](https://wiki.openstreetmap.org/wiki/Mapillary).
