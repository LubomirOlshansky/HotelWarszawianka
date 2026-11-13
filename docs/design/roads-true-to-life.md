# Roads true to life: how to find what is wrong, and the order to fix it

Research and the checker for F's ask of 2026-11-13: "make the roads smoother, connected, fix artifacts, less
sloppy, look like real; how to find the problems where it does not look like real roads; lanes
that change to others, roundabouts, U-turns". Nothing in the game or the map changed.
The standing rule holds throughout (F, 2026-11-07): main's roads are the base, small fixes, no
new geometry without a good reason, and nothing main has (medians, arrows, islands, slip lanes,
cycle paths) is removed.

## 1. Where we are

Three post-passes already repair the drawn road, and each has a ratchet in `tools/verify.sh`:

| Pass | What it repairs | Left today (its own `--check`) |
| --- | --- | --- |
| `tools/road_smooth.py` | width steps at way joins, line jogs, kinks in lines | edge steps 10, line jogs 20, edge lines across kerbs 392 |
| `tools/road_fixes.py` | lines in junction mouths, arrows past zebras, half zebras, street splits | split paint 105 m, split kerb gaps 508 m, 85 loose line ends in 25 splits |
| `tools/road_design.py` | three designed areas (krucza, marsz_defilad, marsz_sienkiewicza) | continuity 0 |
| `tools/check_streets.py` | poles and zebras off the asphalt, medians in junctions | S3 33 and S5 90, reported only |
| `tools/street_pass.py` | the per-street score (L1-L4, K1, K2) | **only 5 streets have a record** |

So the paint and kerbs at way joins are mostly handled. What nothing checks is the **lane level**:
which lane leads into which, where a lane appears or ends, how a turn or a roundabout is driven.
That is exactly what F names. The causes are in the bake, not in single places:

1. **Lane links through a junction are guessed.** `lane_graph.gd` `next_lane` sends a right turn
   to the rightmost lane, a left turn to the leftmost, and straight on to "the same position,
   shifted by half the difference in lane count". OSM's `turn:lanes` is read only to paint the
   arrows (`bake_osm.turn_codes`), never to link the lanes. So cars drift from one lane into
   another across a junction, and the arrows on the road can say something the traffic does not do.
2. **Turn restrictions are thrown away.** `tools/prepare_demo.py` keeps only multipolygon
   relations, so OSM's `restriction` relations (no left turn, no U-turn, only straight on) never
   reach the bake. Every exit of a node is allowed.
3. **Each OSM way has its own lane count.** Mappers cut a street into many ways, and a short way
   with one lane more or less becomes a lane that pops up and is gone again. `road_smooth` tapers
   the asphalt edge, but nothing decides on which side the lane is added and paints it as a real
   street does (kerb stays, a new dashed line starts, hatching fills the spare width).
4. **Roundabouts are OSM rings drawn as ribbons.** Fourteen rings are in the lane graph. The
   lane count changes inside several rings, the big signalised ones (ONZ, Daszyńskiego, de Gaulle'a)
   are not circles in OSM, and only rings of 3 lanes and 25 m radius get spiral lines.
5. **OSM vertices are sparse.** A bend mapped with one vertex is a kink the car and the lane lines
   both show.

## 2. What the checker finds

`tools/road_truth.py` (built 2026-11-13, verify step `roadtruth`) on main's map, 4,710 graph edges:

| Rule | Finding | Count | Worst examples |
| --- | --- | --- | --- |
| R1 | Lane count changes where no side road joins | 379 | Grzybowska, Kłopot, Marszałkowska |
| R2 | A stretch under 60 m with another lane count than the same street before and after it | 71 | Miedziana 1-2-1, Nowogrodzka 1-2-1, Koszykowa 1-2-1 |
| R3 | A lane going straight on that lands more than 1.75 m to the side | 403 | Lubelska 15.7 m, Raszyńska 10.4 m, Plac Konstytucji 8.2 m |
| R4 | Two lanes of one approach cross going straight on | 0 | |
| R5 | A link that turns back by more than 137° away from a dead end | 144 | Krucza, Senatorska, Żelazna, Srebrna |
| R6 | A kink over 20° at one point of a main road, or a left-right wiggle | 83 | Plac Piłsudskiego 43°, Senatorska 37° |
| R7 | Edges with less than 3 m to drive between their junction curves | 262 | the small roundabouts in Muranów |
| R8 | A turn arrow with no such exit at the junction ahead | 56 | Plac Konstytucji, Towarowa, Okrzei |
| R9 | A roundabout ring with a changing lane count, or not round | 21 on 22 rings | de Gaulle'a 2/3/4 lanes, ONZ radius 31.5 to 43.9 m |
| R10 | A turn tighter than 3.5 m radius (the car pivots on the spot) | 266 | Szpitalna into Przeskok, Sienna into Twarda |

Against the raw OpenStreetMap export (`--osm=`, run on the Mac, reported only):

| Rule | Finding | Count |
| --- | --- | --- |
| T1 | A turn restriction the lane graph ignores (of 556 relations in the export) | 264: no left turn 87, no U-turn 84, only straight on 59, only right 18, no right 12, others 4 |
| T2 | An approach where lanes may take an exit their `turn:lanes` does not allow (547 edges have the tag) | 353 |

**Checked against the aerial photo** (Mac, 22 places, the worst of each rule inside the photo tiles,
the photo beside a flat plot of the game's road; 14 looked at closely): 12 clearly differ from the
real street. Żelazna and Miedziana draw a wedge where the photo's kerbs run straight; Nowogrodzka
bulges for 44 m; Senatorska's lanes cross over in a Y where the photo has one wide road with
hatching; Żelazna and Srebrna turn back where the photo has an island and no gap; Rondo ONZ is a
clean circle on the photo and a lumpy square in the game, with lane links crossing each other. One
kind was a false alarm and is now left out (the short piece inside a junction between a dual road's
halves, Wilcza at Marszałkowska), one was unclear (Koszykowa, a hatched pocket). The sheets are in
the project files under `roads-research/photo-check/`.

Known limits: R9 finds rings by shape and name because the graph does not say which edges are a
roundabout (RT-5 adds that flag in the bake). R8 only sees exits the lane graph has, so an arrow
into a service road counts. R3 and R10 measure the links as `lane_graph.gd` builds them today.

Streets with the most findings per kilometre: `python3 -I tools/road_truth.py --streets`.

## 3. The detectors

`tools/road_truth.py` reads the baked map, prints each finding with its `--at=` (`--list`), writes a
JSON (`--json=`), and `--check` is a ratchet (verify step `roadtruth`). Levels 1 and 2 are built;
levels 3 and 4 are RT-8 and RT-9. The table below is the plan as first written; the tool's own
docstring has the rules as built (R10 became the tight turn, the whole-map street score stays with
`street_pass`).

**Level 1: the baked map alone (cloud and CI, seconds).**

| Id | Rule | Real roads do this instead |
| --- | --- | --- |
| R1 | lane count changes with no side road, no junction within 40 m | a lane is added or dropped with a taper and paint |
| R2 | a short stretch whose lane count differs from both neighbours | a turn pocket before a junction, or nothing |
| R3 | a straight-on lane link lands more than half a lane to the side | lane k goes on as lane k |
| R4 | two lane links of one approach cross each other | links fan out, they never cross |
| R5 | a turn link under the car's turning radius; a turn back away from a dead end or a mapped median gap | U-turns only where the street has a gap or a sign |
| R6 | a kink over 15° at one point, or a left-right wiggle, on a main road | arcs |
| R7 | an edge too short to drive between two junction curves | one junction |
| R8 | an arrow with no matching lane link, a lane on an arrowed approach with no arrow | arrows and traffic agree |
| R9 | a roundabout ring: lane count changes inside, radius varies over 15 %, an arm with no give-way line, lines that are not spiral or concentric | one ring, one lane count |
| R10 | `street_pass` L1-L4, K1, K2 for every named street, not five (streets cut by name and chain automatically) | |

**Level 2: against OpenStreetMap's own tags (needs the raw export; today Mac only).**
`lanes`, `turn:lanes`, `placement`, `change:lanes` and the `restriction` relations compared with
the lane graph: a link OSM forbids, a turn lane the graph ignores, a way whose baked lane count is
not the tag's. To run it in the cloud and CI, the map pack gets a small extract (road ways with
those tags and the restriction relations, a few MB).

**Level 3: against the aerial photo (GUGiK orthophoto, Mac only).** For each cross-section every
20 m of a main road: the brightness profile across the street gives the paint peaks (how many
lanes the photo shows) and the asphalt's edges (where the kerb really is). Compared with the drawn
lane count and width. Trees, shadows, cars and the flight's age make this noisy, so it ranks
suspects for a look and is never a gate. `tools/road_design_plot.py flat --ortho` is the view for
that look.

**Level 4: how it drives.** `check_lane_drive` already drives the lanes. Logged per street: the
steering rate and sideways jerk of the lane follower (a kink or a lane jump shows as a spike), and
from a 5 minute traffic run the nodes where cars stand over 20 s, turn back, or change lane inside
a junction. This is the closest number to "feels sloppy" and it needs no photo.

Street-level photos (Mapillary, Panoramax, the `street-scout` agent) stay the judge for a single
finding, as today.

## 4. The fix order

Each step is one thread and one PR, with before/after shots, both city paths and the ratchet
lowered. Steps 1 to 3 add no geometry at all.

| # | Item | What changes | Why this rank |
| --- | --- | --- | --- |
| RT-1 | **Done 2026-11-13.** `tools/road_truth.py`, levels 1 and 2 (the console map layer is left) | a tool and a verify step, no map change | everything after it is measured by it |
| RT-2 | Lane links from `turn:lanes` | the bake writes each lane's allowed exits into the graph, `next_lane` uses them and keeps today's rule as the fallback; arrows are painted from the same data | the largest cause of "a lane changes into another", in traffic, rivals and arrows at once |
| RT-3 | Turn restrictions and honest U-turns | keep `restriction` relations in `prepare_demo.py`, drop forbidden links, a turn back only at a dead end or a mapped median gap | wrong turns and U-turns are what a player notices in traffic |
| RT-4 | Lane changes as paint | per R1/R2 place: a short blip joins its neighbours or becomes a turn pocket; a real add or drop gets its side (from `turn:lanes` and `placement`, else the straight kerb), a starting dashed line and hatching, the kerb stays | F's lesson of 2026-11-05; removes most of the leftover jogs too |
| RT-5 | Roundabouts, in groups of three or four | one lane count round the ring, an even radius where the real one is round, give-way lines at every arm, spiral or concentric lines by size; the signalised squares (Dmowskiego, ONZ, de Gaulle'a, Daszyńskiego, Czterdziestolatka) are checked against the photo first, because they are not classic roundabouts | fourteen places, each seen often |
| RT-6 | Kinks into arcs, short edges merged | main-road centrelines resampled through the same points (R6), junction nodes under 8 m apart become one junction (R7) | smoother driving and lines; touches many kerbs, so after the lane work |
| RT-7 | The split leftovers | the 25 splits `road_fixes` fix 6 leaves, by kind (forks, slip-road merges, medians at the node) | already in BACKLOG, ranked here |
| RT-8 | Level 2 and 3 detectors | the OSM extract in the map pack, the photo cross-sections on the Mac | finds what the map alone cannot: places where OSM itself is wrong or old |
| RT-9 | Level 4 drive log, then the street-by-street sweep | every street's score on the console, worst first (section 2's list is the starting order) | the long tail |

All of it is map-geometry or traffic work: Opus threads, `map-engineer` for the bakes. RT-2 and
RT-3 also touch `lane_graph.gd` and `traffic.gd`, so they wait for a free slot beside the racer
AI work (the race planner reads the same graph).

## 5. Defaults taken, for F to overrule

- The designed areas and the Royal Castle ramps (its own thread) are left out of the findings.
- A detector starts as a ratchet at today's count, never as a hard zero.
- The OSM extract for the cloud is road tags and restrictions only, free data, a few MB.
- Roundabout order: Dmowskiego, ONZ, de Gaulle'a first (the most driven), then the rest.

The first prototype scripts and a map of the findings are in the project files under
`roads-research/`; `tools/road_truth.py` replaces them.
