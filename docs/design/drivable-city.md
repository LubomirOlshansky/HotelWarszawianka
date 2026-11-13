# A city built for driving: what is solid, what yields, what goes

**Status (2026-11-13):** research and a ranked plan. No game code changed. The build plan, item by item,
is `docs/design/drivable-city-build.md`. It is the follow-up to
`docs/design/road-objects.md` (2026-11-04: the object audit, the census tool, the street-by-street
pipeline, the collision targets). That plan still holds for the detail; this page says what
happened to it, changes one decision in it, and puts the work in a new order.

F (2026-11-13): "How to make the city environment best suited for the game. Now there are a lot of
walls and objects that make driving hard. What overall decision, how can we analyse the overall
situation and make it more of a game world: analysing objects, what the purpose is, which should
not be collidable, which to remove, which make the game unreasonably harder."

The roads themselves (joins, lane changes, roundabouts, U-turns) are the second half of the same
message and have their own thread. Steering and the lane assist are in the controls thread.

Contents: [1 The answer in short](#1-the-answer-in-short) ·
[2 Where we are, measured](#2-where-we-are-measured) ·
[3 The one decision: five solidity classes](#3-the-one-decision-five-solidity-classes) ·
[4 Every object type](#4-every-object-type-purpose-and-verdict) ·
[5 What makes the game unreasonably harder](#5-what-makes-the-game-unreasonably-harder-ranked) ·
[6 Design rules](#6-design-rules) · [7 The plan, in order](#7-the-plan-in-order) ·
[8 Questions for F](#8-questions-for-f) · [9 How this was measured](#9-how-this-was-measured)

---

## 1. The answer in short

1. **The city is still as solid as it was on 2026-11-04.** The census today gives the same numbers
   as nine days ago (section 2). The street-by-street sweep produced 11 object verdicts in that
   time, all of them a new look with the same collider. One verdict per object is too slow for
   8,000 barriers.
2. **Change the default.** Today everything OpenStreetMap maps as a barrier is a wall unless a
   sweep says otherwise. A game world works the other way round: **nothing stops the car unless it
   has earned it.** Four kinds of thing earn it: buildings, the edges of structures (bridges,
   tunnels, retaining walls, stair holes), water, and heavy vehicles (trams, buses). Everything
   else yields: it breaks, it is pushed, the car rides over it, or the car passes through it.
3. **Decide by class and context, in bulk, in the bake.** One table of five solidity classes
   (section 3) and a rule per object type (section 4). The per-object override file stays for the
   exceptions only.
4. **Two bulk rules do most of the work.** Fences and parked cars are 80 % of the hard metres
   within 1 m of a lane on ground-level streets (15.3 of 19.2 km). Fences that break and parked
   cars that can be pushed remove them without removing anything from the picture.
5. **The rest is how the car answers a hit**, not what it hits: 57 % of the hard metres within 1 m
   of a lane are bridge rails, tunnel walls and retaining walls, which must stay. There the fix is
   the collision response of road-objects.md section 4 (grind along, never a dead stop), of which
   only the first step is built.
6. **Measure before and after.** Several dead stops in the Autopilot log never got a cause (PT-36,
   PT-44, PT-45), because nothing records what the car hit. A contact log is the first item.

## 2. Where we are, measured

`python3 -I tools/road_objects.py` on main (d6a9645, 2026-11-13) against the plan's table of
2026-11-04. Solid objects by the gap to the nearest lane's edge:

| Class | Objects | 0-1 m past the lane's edge | 1-3 m | Solid metres within 3 m | 2026-11-04 |
| --- | --- | --- | --- | --- | --- |
| Barrier lines (fence, wall, hedge) | 7,928 | 460 | 682 | 23,980 | 24,131 |
| Guard rails | 364 | 310 | 20 | 21,766 | 21,766 |
| Buildings | 7,367 | 53 | 315 | 7,738 | 7,738 |
| Structure walls (retaining, tunnel) | 1,519 | 164 | 176 | 5,632 | 5,632 |
| Parked cars | 4,893 | 434 | 261 | 4,110 | 3,435 |
| Shelters | 365 | 6 | 247 | 2,248 | 2,283 |
| Small buildings, canopies | 3,080 | 12 | 89 | 747 | 747 |
| Piers, platforms, props, monuments | 691 | 4 | 49 | 405 | about 400 |

Nothing moved except parked cars (up, from re-bakes) and platforms (the census now reads them
right). The lane network is 528 lane-km, so there are about 130 m of solid edge within 3 m for
every lane-kilometre.

**Hard metres within 1 m of a lane's edge** (the band a car on the outer half of its lane touches),
about 45 km in all:

| What | km | Share | Must it stay hard? |
| --- | --- | --- | --- |
| Deck guard rails | 18.1 | 40 % | yes, it is the bridge's edge |
| Fences | 12.1 | 27 % | no (section 4) |
| Tunnel walls | 3.5 | 8 % | yes |
| Parked cars | 3.3 | 7 % | no |
| Guard rails on the ground | 3.0 | 6 % | mostly yes |
| Buildings | 2.1 | 5 % | yes, but set back (narrow streets) |
| Barrier walls | 1.5 | 3 % | by kind |
| Retaining walls | 1.5 | 3 % | yes |
| Everything else | 0.4 | 1 % | by kind |

**By road class** (solid metres within 3 m per lane-kilometre): primary links 680, primary 265,
living streets 196, secondary 124, residential 112, tertiary 62. The links and primaries are
bridges and estacades (rails and walls, correct). Living streets are the walled-in part: buildings
(2.3 km) and fences (0.9 km) along 19.6 km of lanes, 15.9 km of which are under 2.6 m wide.

**Junctions** are where fences hurt most: 7.9 km of fence stands within 14 m of a junction node,
more than any other class, exactly where a turning car cuts the corner.

**What the fix lists say.** Of the dead stops that got a cause in docs/PLAYTEST.md: a collider
bigger than what is drawn (PT-47 planter edges 0.2 m drawn, 1.9 m solid; PT-1 a stop platform),
gaps and notches between buildings (PT-7, PT-17, fixed with about 22,600 invisible pocket walls),
a wall ending square to the traffic (PT-40), a hole in a closure (PT-28), and traffic cars
(P3: "every on-road stop was a traffic-car bump"). Three more never got a cause.

**What is already right** (keep): lamps, signals, trees, benches, bins, bike racks, advertising
columns, kerbs, islands, medians and low platforms have no collider; solids inside a lane are cut
by the bake; barriers drawn under 0.3 m are not solid (since PT-47); stair walls are drawn as 1 m
balustrades city-wide.

## 3. The one decision: five solidity classes

Every object in the city gets exactly one class. The class decides the collider and the answer to
a hit. The look must say which class it is (rule R2).

| Class | What the car does | Cost of a hit | Looks like |
| --- | --- | --- | --- |
| **H Hard** | redirected along it, never through | by angle (road-objects.md 4.2): a graze is cheap, a head-on bounces and turns the car away | heavy: stone, concrete, steel beam, a building |
| **S Smash** | drives through; the object breaks, falls or flies | 5-15 % of the speed once, a crash sound, debris, a line from the city | light: thin bars, mesh, leaves, glass, wood |
| **P Push** | shoves it aside and keeps going | 20-25 % of the speed going into it; the thing slides and stays where it lands until the sector reloads | a car, a cart, a bin on wheels |
| **R Ride** | climbs or drops over it | the kerb jolt (3 % today) | low: kerb, island, platform, steps |
| **G Ghost** | passes through | none | thin and tall: poles, trunks, small furniture |

Today the game has H, R and G, a first Push (traffic cars) and no Smash. Smash is the class every
arcade city uses to keep the street furnished without making it a corridor of walls: Burnout and
Forza Horizon break fences and small walls, Crazy Taxi and GTA 2 scatter stalls and hydrants, and
the hard things are the ones that look hard.

A Smash object costs one shape query a frame against a small layer and no physics response
(road-objects.md 4.4). Version 1: the car passes, panels fly as particles, the fence itself stays
drawn. Version 2, only if the bench allows: the hit panels lie flat until the sector reloads
(needs fences as instanced panels, one more draw call a sector).

## 4. Every object type: purpose and verdict

"Near lanes" is solid metres within 3 m of a lane's edge. Verdicts: keep, make Smash, make Push,
make Ride or Ghost, simplify (same class, simpler or more readable shape), remove, move.

| Object | In the city | Near lanes | Purpose in a driving game | Today | Verdict |
| --- | --- | --- | --- | --- | --- |
| **Buildings** | 7,367 low-based | 7.7 km | the city itself; block edges | H, 5 m | **Keep H.** Collider set back 0.3-0.5 m on streets under 8 m between fronts; convex corners near lanes chamfered |
| **Deck guard rails** | 364 runs with the ground ones | 21.8 km with the ground ones, 18.1 km at the edge | stop the car leaving a bridge | H | **Keep H.** The answer is the grind response; ends tapered, never square |
| **Guard rails on the ground** | part of the above | 3.0 km at the edge | real crash barriers (Wisłostrada, links) | H | **Keep H** where a drop, water or opposing traffic is behind; else Smash. Decided by the bake from what lies behind |
| **Tunnel and retaining walls** | 1,519 | 5.6 km | the road's edge in a trench or on a ramp | H | **Keep H**; a darker foot and a coping so the edge reads at speed |
| **Bridge piers, portal legs** | 359 | 92 m | hold the deck | H | **Keep H**; a tapered lead-in on the side facing traffic |
| **Fences** | 188 km in 4,892 lines | 19.8 km | in the real city: keep people off tram tracks, mark a yard. In the game: nothing, except where a drop is behind | H, 3.1 m tall behind a 1.6 m slab | **Smash**, all of them, in one rule. Exception by the bake: a fence with a drop over 1.5 m, a railway cutting or water within 3 m behind it becomes a guard rail (H, drawn as one) |
| **Hedges** | 21 km in 964 lines | about 0.5 km | green edge of a park or yard | H, 2.7 m | **Smash** (leaves), all |
| **Barrier walls** | 68 km in 1,935 lines | 3.6 km | garden walls, yard walls, embankment walls | H, 3.4 m behind a 1.9 m slab | By drawn height: under 0.6 m **Ride** (a kerb), 0.6-1.2 m **Smash** (low masonry breaks in arcade games; dust), over 1.2 m **keep H**. Fragments under 4 m with nothing behind: **remove** |
| **Stair walls** (underpass, metro) | 137 lines, 1.7 km | about 100 by lanes | stop the car falling into a stair hole | H, drawn as a 1 m balustrade | **Keep H** (the hole is real). Stairs that run along a pavement with no hole: Ride |
| **Parked cars** | 4,893 solid boxes | 4.1 km, 434 at the lane's edge | make a street read as lived in | H box | **Push**, with the long sides giving way last. In a pinch (free width under 3.6 m, or within 15 m of a junction): **remove** every other one |
| **Tram and bus shelters** | 365 solid | 2.2 km, only 6 at the lane's edge | landmark of a stop; passengers stand in them | H box 4 × 1 m | **Keep H**, corners rounded (the corner slip already slides the car past) |
| **Tram islands, stop platforms** | 158 + 248 | sides solid where not along a road | where the tram stops | R on the road side, H on the track side | **Ride** on every side at 0.3 m; H only for rail platforms of 0.9 m |
| **Kerbs, medians, traffic islands** | 8,713 kerbs | | shape the road | R | **Keep R.** No jolt on streets under 8 m, where the car is half on the pavement anyway |
| **Canopies** (fuel stations, stop roofs; `roof` parts with a low base) | 64 solid | part of 747 m | a roof | H block 4 m | **Simplify**: posts H, the space under open |
| **Kiosks, sheds, garages, service huts** | about 3,000 small buildings | 747 m with the canopies | street character | H | Kiosk-size (under 12 m²): **Smash** candidates later; the rest keep H. Low priority: 12 objects at a lane's edge |
| **Stalls, carts** (street details) | 28 near lanes | 62 m | street character | H box | **Smash** (stall) and **Push** (cart): the Crazy Taxi moment, cheap and funny |
| **Monuments** | 279 solid | 55 m | landmarks | H box | **Keep H** for statues and obelisks; busts, stones and steles under 1 m **Ghost**. Any within 1 m of a lane: **move** back |
| **Park pieces** (fountains, carousels) | 6 near lanes | 0 | park life | H | Keep |
| **Bollards** (Tamka, Powiśle) | rows along kerbs | | keep cars off the pavement | drawn only | **Keep G** or make Smash for the sound; never H |
| **Lamps, signals, poles, trees** | 10,718 + 3,591 + 269,000 | | light, rules, green | G | **Keep G** |
| **Benches, bins, racks, columns** | 22,000 | | furniture | G | Keep G; **Smash** effects on the ones in the car's path are a cheap reward later |
| **Pocket walls** (invisible) | about 22,600 | never on a carriageway | close gaps a car would wedge into | H, not drawn | **Keep**, but audit: each must close a gap narrower than the car; any on open ground is a bug (rule R2) |
| **Landmarks** | hand-built | per site | the sights | H, per site | Keep; each site's ring checked for square ends and hidden steps when its street is swept |
| **Edge roadworks, map edge** | at the map's edge | | the end of the world | H | Keep; closed across every strip (PT-28) |
| **Traffic cars** | moving | | life, and the obstacle course | Push, player keeps 50 % | **Push harder**: player keeps 75 % on a rear-end, the car spins aside (road-objects.md 4.3) |
| **Trams, buses** | moving | | heavy traffic | H | Keep H, grind response |

## 5. What makes the game unreasonably harder, ranked

By how often a player meets it and how badly it ends, from the census, the Autopilot log and the
fix history. "Unreasonable" means the player did nothing a driving game should punish.

| # | What | Evidence | Fix |
| --- | --- | --- | --- |
| 1 | **A hit that stops the car dead**, whatever it hit. Head-on into a wall loses all the speed; a traffic car costs half | P3: every on-road stop was a traffic bump; collision rework v2 has only its first step (Classic wall follow) | collision v2: answer by angle, head-on kick, traffic shove |
| 2 | **Fences beside and between lanes**: 12.1 km within 1 m of a lane, 7.9 km at junctions, each a 3.1 m wall behind a thin slab | census; PT-1's line on Marszałkowska | Smash, in bulk |
| 3 | **Colliders you cannot see or that are bigger than the drawing** | PT-47, PT-1, PT-44/45 (no cause found), 22,600 pocket walls never audited | rule R2 as a check; a collider view for sweeps |
| 4 | **Parked cars at the lane's edge on narrow streets** (Krucza 649 m, Wspólna, Polna): 0.5 m each side of the car | census: 434 at the edge | Push; thin out the pinches |
| 5 | **Walled-in living streets and yards**: 15.9 km of lanes under 2.6 m between buildings and fences, many dead ends | census; PT-24 (a yard off Marszałkowska) | collider set back; yards with no reason to enter gated at the mouth |
| 6 | **Hard things that end square to the traffic** (wall ends, piers, tower bases, building corners at junctions) | PT-40; PT-7 | tapered lead-ins and chamfers as a bake rule |
| 7 | **Bridge and tunnel edges** at speed: correct, but 25 km of them | census | grind response (item 1); no object change |
| 8 | **Stops with no cause on record** | PT-36, PT-44, PT-45 | the contact log |

Not a problem, by the numbers: shelters (6 at a lane's edge), monuments (1), piers (0), small
buildings (12). They need no campaign, only their street's sweep.

## 6. Design rules

Every map change, landmark and street sweep is held to these. R2 and R4 become checks.

- **R1 Four things stop a car**: buildings, structure edges, water, heavy vehicles. Anything else
  that stops a car is a bug.
- **R2 Solid looks solid.** No collider without a drawn object, and no collider more than 0.5 m
  bigger than its drawing in plan. A hard object is drawn at least 0.8 m tall and in a heavy
  material. The only invisible colliders are pocket walls closing gaps narrower than the car, and
  the map edge.
- **R3 Hard edges run along the traffic, never across it.** A hard object never ends square to a
  lane within 3 m: it gets a taper of at least 1:4. A closed way is closed by a visible gate or
  roadworks, across its whole width.
- **R4 A clear zone.** On primary, secondary and tertiary streets, nothing hard within 1 m of a
  lane's edge except structure edges and buildings. Smash, Push, Ride and Ghost objects may stand
  there.
- **R5 A mistake costs time, money or a star, never a stop.** Smash 5-15 % of the speed, Push
  20-25 %, a hard graze under 15 %; only a head-on at speed costs more than half, and the car is
  turned away from it.
- **R6 No traps.** Every space a car can enter has a way out at least 3.5 m wide, or is gated.
  Smash objects break from both sides.
- **R7 Breaking things is content.** Each Smash kind has its sound, its debris and now and then a
  line from the city, inside the chatter budget.
- **R8 Class rules first, object verdicts second.** A new object type enters with its class in
  the table of section 4. The override file (`game/data/road_objects.json`) is for exceptions.
- **R9 The numbers only go down.** Hard metres within 1 m of a lane, by class, are a ratchet in
  `check_map_data.py`; contacts per kilometre and dead stops per street are a ratchet in the
  drive check.

## 7. The plan, in order

One thread and one PR each. Items 2 and 3 are the two that change how the game feels; the others
make them safe to do and keep them done.

| # | Item | What | Model | Needs |
| --- | --- | --- | --- | --- |
| **1** | **Contact log and the sloppy driver** | `check_lane_drive --contacts`: every contact with its collider's class and census id, speed before and after; a driver that aims 1.5 m off the lane centre and turns late. A dead-stop line in dev runs and Autopilot runs. Baseline per street: contacts per km, median speed kept, dead stops | Opus | none |
| **2** | **Collision rework v2** (road-objects.md 4.2, 4.3) | answer by angle, head-on kick, corner pivot, traffic shove, behind a flag with three presets | Opus | after or inside the controls thread (both edit `car.gd`); F's phone A/B |
| **3** | **Smash class, fences and hedges in bulk** | the solidity table as data; fences and hedges leave the hard collider and join a soft layer; drag, sound, debris; the drop-behind exception in the bake | Opus | bench before and after; both city paths |
| **4** | **Parked cars: Push, and thinned in pinches** | hit cars slide and settle; every other one out where the free width is under 3.6 m or by a junction | Opus | bench (4,893 boxes change kind); re-bake |
| **5** | **Rule R2 as a check, and the collider view** | a check that flags colliders with no drawing or far bigger than it; a `--colliders` view for shots; the pocket-wall audit | Opus | none |
| **6** | **Narrow streets and yards** | collider set back from fronts on streets under 8 m; dead-end yards gated; no kerb jolt there | Opus | re-bake |
| **7** | **Tapers and chamfers** | lead-ins on every hard end within 3 m of a lane; convex building corners near lanes chamfered | Opus | re-bake |
| 8 | Low walls by height; islands and tram platforms Ride on every side; canopies on posts | the remaining rows of section 4 | Sonnet with a spec | re-bake |
| 9 | Stalls, carts, kiosks, small monuments | Smash, Push and Ghost for the small things | Sonnet | none |
| 10 | The ratchets (R9) | `check_map_data.py` and the drive check hold the new numbers | Sonnet | after 3 and 4 |
| 11 | Street sweeps | now only for what the class rules leave: each street's exceptions, landmarks' rings, look | sweep skill | the Mac for evidence |

What to expect from 3 and 4 together: hard metres within 1 m of a lane on ground-level streets
fall from 19.2 km to about 4 km, before the fences the drop-behind rule keeps hard. With item 2, the 26 km of structure edges stop being stops.

## 8. Questions for F

Parked in docs/QUESTIONS.md with the default each item would build.

1. **Fences and hedges break when driven through, everywhere** (default: yes, except where a drop,
   a railway or water is behind). The alternative is only along streets, keeping yard fences hard.
2. **Parked cars can be pushed** (default: yes). The alternative keeps them solid and only thins
   the rows.
3. **Does breaking things cost anything?** Default: only speed and noise. An option for later: a
   joke invoice from the road authority at the end of the day.
4. **Tram shelters stay solid** (default: yes; only 6 stand at a lane's edge).

## 9. How this was measured

- `python3 -I tools/road_objects.py --json=...` on main d6a9645: classes, bands, streets, road
  classes, junction share. Lane-kilometres and lane widths from the lane graph in
  `game/map/centrum.json` (`graph.edges`, length × lanes).
- Barrier lines by kind and style from `lines` in the same file; the 11 overrides from
  `game/data/road_objects.json`.
- Collider facts from `game/scripts/map_builder.gd` (`BARRIER_STYLE`, `BARRIER_SOLID_MIN`,
  `_wall_along`, `_props`, the platform sides), `car.gd` (the collision constants), and the SOLID
  tables of `street_details.gd`, `monuments.gd` and `park_details.gd`.
- Stops and their causes from docs/PLAYTEST.md (PT-1 to PT-53) and the Autopilot bug log.
- The arcade games in section 3 are from general knowledge of those games, not from a new source
  search; road-objects.md section 9 lists the sources read on 2026-11-04.
- Not measured here: how many fences have a drop, a railway or water behind them (item 3 measures
  it), and how often players on phones hit each class (no contact log yet: item 1).
