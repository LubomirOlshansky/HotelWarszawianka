# Road design system: research and the Palace POC

**Status (2026-11-06):** research + a proof of concept on a branch. F (2026-11-06, four phone shots by the
Palace of Culture: lanes merging and splitting with jagged asphalt, notched kerbs, paint crossing islands):
"make the research how real roads are designed, how roads are designed in games and maps and how it is
done in projects, how to avoid artifacts, and rebuild these roads around the Palace from zero, like a road
working simulator: gather the roads' needs and rebuild them instead of changing and fixing. It should align
with the original Warsaw roads and crosswalks."

Results, numbers and before/after shots: [road-design-palace-results.md](road-design-palace-results.md).
The workflow is the skill `road-design` (`.claude/skills/road-design/SKILL.md`).

Contents:
1. [Why the roads break today](#1-why-the-roads-break-today)
2. [How real roads are designed](#2-how-real-roads-are-designed)
3. [How games, map tools and simulators build roads](#3-how-games-map-tools-and-simulators-build-roads)
4. [Where artifacts come from, and the rules that avoid them](#4-where-artifacts-come-from-and-the-rules-that-avoid-them)
5. [The design: streets as cross-sections, junctions as shapes](#5-the-design-streets-as-cross-sections-junctions-as-shapes)
6. [Gathering a street's needs](#6-gathering-a-streets-needs)
7. [Sources](#7-sources)

---

## 1. Why the roads break today

The bake draws **every OpenStreetMap way as its own ribbon** (`roads[].p`, `w`), sized from its own lane
count (`w = lanes × 3.25`), with a round disc at every bend. OSM splits a street into a new way wherever
any tag changes (a turn lane starts, a bus lane ends, a bridge, a speed limit), and maps a dual
carriageway as two separate one-way ways. So the Palace's four streets are **102 separate ways**, and at
each join the next way can be a different width, a different offset and a slightly different angle.

Since 2026-10-29 eleven repair passes have been added on top (`tools/road_smooth.py`, 2,818 lines, and
large parts of `bake_roads.py`, 3,714 lines): tapers at joins, line stitching, kink rounding, kerb
fitting, rail-bed fitting, zebra cuts, asphalt pocket fills. Each fixes one symptom where it was seen; the
next shot finds the next one. F's shots show what is left:

| Shot | What F sees | Cause in the data |
| --- | --- | --- |
| IMG_7262 (Marszałkowska × Świętokrzyska) | lane lines that stop and restart, an arrow box drawn across a lane line, a kerb notch by the tram stop | the junction is the overlap of 9 ribbons; lines come from each way separately |
| IMG_7264 (Emilii Plater north of Jerozolimskie) | a "Y" where 2 lanes become 4: two ribbons fanning out with a wedge of pavement between them | two OSM ways (`lanes=2` / `lanes=4`, `placement=middle_of:3`) meet at an angle; each keeps its own width |
| IMG_7266 (Emilii Plater, south end) | a jagged step of asphalt where the street widens; the kerb jumps sideways twice | a 1-lane way, a 2-lane way and a 3-lane way end-to-end; the taper only rounds the step |
| IMG_7267 (Emilii Plater by the Palace park) | the carriageway splits into two around a pavement triangle, lane lines cut across it | a turning way joins at 25°; its ribbon overlaps the street's and the pavement shows through |

None of these are bugs of one pass. They come from the model: **a street is not a list of ways**. In the
real world (and in every serious road tool, section 3) a street is one reference line with a
cross-section that changes along it, and a junction is a shape of its own.

## 2. How real roads are designed

Road engineers (Polish practice: *Rozporządzenie w sprawie warunków technicznych, jakim powinny
odpowiadać drogi publiczne*, Dz.U. 2016 poz. 124 and the 2022 update; markings: *Rozporządzenie w sprawie
szczegółowych warunków technicznych dla znaków i sygnałów drogowych*, Dz.U. 2019 poz. 2311, załącznik 2)
work in this order:

1. **Alignment (trasa).** One reference line per street: straights joined by circular arcs (and
   clothoid transitions on fast roads). The centreline never has a kink; a bend has a radius.
2. **Cross-section (przekrój poprzeczny).** Across the reference line, left to right: pavement, cycle
   track, verge with trees, kerb, lanes (city lanes 3.0-3.5 m, bus lanes 3.0-3.5 m, turn lanes 2.75-3.0 m),
   median or tram bed (a double tram track ~6.0-7.0 m including clearance), lanes, kerb, pavement. A
   typical Warsaw *aleja* (Marszałkowska, Jerozolimskie) is a dual carriageway with the tram in the middle.
3. **Changes along the street are planned as transitions, not steps.** The kerb line stays straight
   (or a long curve); a lane is added by **widening into a taper** (typically 1:10 to 1:20 in the city,
   20-50 m) or, much more often in a dense centre, **by repainting the same asphalt**: a lane line starts,
   a dropped lane is filled with chevron hatching (P-21). Kerbs move only for a bus bay, a parking lane
   or a junction flare, and then with a rounded taper.
4. **Junctions are designed as one shape.** The kerb lines of two neighbouring arms are joined by a
   **kerb return** (a corner arc, R ≈ 6-12 m in the city centre, larger where buses turn). The
   approach lanes end at a **stop line** (P-12, a solid line ~0.5 m wide), 1-2 m before the **zebra**
   (P-10: white bars ~0.5 m wide with equal gaps, 4 m or more across). Lane lines turn solid (P-2) over
   the last 20-50 m. Turn arrows (P-8) sit in each lane, the first a few metres before the stop line,
   repeated further back. A refuge island (raised, kerbed) splits a long crossing; the median of a dual
   carriageway ends in a rounded **nose** a little before the crossing.
5. **Markings follow the lanes, never the other way round.** Every painted line is the boundary between
   two lanes of the cross-section; a line ends where its lane ends. Paint never crosses a kerb or an
   island.
6. **Trams** run on their own bed (ballast or grass, kerbed) between the carriageways, and cross the
   junction embedded in the asphalt; pedestrian crossings over the bed have a walkway of slabs.

The rule of thumb that matters most for us: **the cross-section is the requirement; the drawing is
generated from it**. Engineers check widths, radii and sight lines on the cross-section and the
alignment, not on the drawing.

## 3. How games, map tools and simulators build roads

| Tool | Street model | Junction model | What we take |
| --- | --- | --- | --- |
| **ASAM OpenDRIVE** (driving simulators, CARLA, HD maps) | a road = a **reference line** (lines, arcs, spirals) with **lane sections** along `s`; each lane's width is a cubic polynomial of `s`, road marks per lane boundary | a junction = **connecting roads** (one per allowed movement) between incoming lane ends; the junction surface is what they cover | the core: reference line + lane sections + width functions, marks as lane boundaries |
| **osm2streets / A/B Street** (Dustin Carlino) | OSM ways → a road graph; each road a centreline + an ordered **lane list** (travel, bus, bike, parking, sidewalk, median) from `lanes`, `turn:lanes`, `cycleway`, `placement` | each intersection gets **its own polygon**: road centrelines are **trimmed back** until their thickened edges stop overlapping, the trimmed corners are joined; transformations first collapse short roads and **merge dual carriageways** into one road | the trim-back junction polygon and the lesson that raw OSM ways must be merged into streets first |
| **Esri CityEngine** | a graph of **segments** (with street width, lanes, sidewalk widths) and **nodes** | each node generates a **crossing / junction / roundabout / freeway** shape by type; sidewalks and corner radii are node parameters; too-close nodes conflict (flagged red) | node-type templates and the conflict flag |
| **Cities: Skylines** (I and II) | a road **prefab** = one fixed cross-section (lanes, medians, props), segments are Bézier curves | the node mesh is generated from the arms' prefabs; mods (Node Controller, TM:PE) fix what the generator gets wrong; II adds lane-level junction editing | every street drawn from one cross-section; curves, not polylines |
| **Streetmix / Complete Streets** | a cross-section editor: a list of strips with widths | none | the authoring format a person can read and change |
| **GTA / AAA open worlds** | hand-modelled road meshes, procedural tools (Houdini road networks) generate from splines + profiles, artists fix junctions | junction kits (templates) | splines + profile, junctions from a small kit |
| **OSM lane tagging** (`lanes`, `turn:lanes`, `placement`, `width:lanes`, `change:lanes`, `area:highway`) | the data that a cross-section needs | `area:highway` lets mappers draw the exact surface | read every lane tag; area polygons are evidence, not geometry to stack |

All of them separate **what the street needs** (a cross-section, per stretch) from **how it is drawn**
(meshes generated from that), and all of them treat **junctions as their own objects**. None of them
draws a street as a chain of independently sized pieces.

## 4. Where artifacts come from, and the rules that avoid them

| Artifact (F's shots) | Root cause | Rule in the new system |
| --- | --- | --- |
| Jagged asphalt where lanes are added | each way sized from its own lane count | **width belongs to the street section**, kerbs are continuous functions of `s` with tapers; lane count changes the paint only |
| Pavement wedge in a "Y" | two ways fanning out, each its own ribbon | a dual carriageway is **one street** with a median strip that opens and closes with a nose |
| Notched kerbs | kerbs traced from ribbon edges, then cut and patched | kerbs are **generated** as the outer edges of the cross-section and the junction's kerb returns; broken only at crossings (lowered kerb) |
| Paint across islands, arrow boxes over lines | lines from each way, stitched afterwards | lines are **lane boundaries**; they exist only where both lanes exist and end at the stop line |
| Discs at bends | polyline centrelines | the reference line is **filleted** (arcs) before anything is offset |
| Overlapping rectangles at junctions | ribbons crossing | arms are **trimmed** to the junction; the junction polygon is built from kerb lines + corner arcs |
| One fix revealing the next | repairs on finished geometry | the generator is the only writer of a designed area; to change the look you change the spec and rebuild |

Checks that keep it so (in `tools/road_design.py --check`): every lane boundary lies inside the
carriageway; no kerb crosses another; every crossing ends on a kerb or an island; no carriageway polygon
self-intersects; the designed area's kerb lines are continuous (no gap over 0.2 m outside crossings and
mouths); the tram tracks lie inside their bed.

## 5. The design: streets as cross-sections, junctions as shapes

`tools/road_design.py` (standard library) reads a design spec, `docs/roads/<area>.json`, and writes the
road layers of that area into `game/map/centrum.json` after the old ones there are removed. It is the
OpenDRIVE model cut down to what a top-down arcade game shows:

- **Street** = `axis` (a polyline in map metres, filleted with 40 m arcs and resampled every metre) +
  `sections`, each from `s` on: the **carriageways** `cw` between their kerb offsets `l` and `r` (+ is
  right of the axis), each an ordered list of **lanes** from its left kerb to its right: `d` ±1 (along
  or against the axis), `k` (`lane`, `bus`, `bike` painted cycle lane, `park`, `gap` painted hatched
  area), `t` turn arrows (`L`, `T`, `R`, `LT`, `TR`, `U`) and `w` width. Between two carriageways lies a
  `med`: `tram` (a bed for the tracks), `grass` or `island` (raised, with rounded noses) or `none`.
  Pavements are not strips: they are the ground outside the outer kerbs. A street also lists its own
  mid-block `crossings`, `openings` (a side road or driveway: kerb break, two small kerb returns) and
  `gaps` (the median broken for a cross street or U-turn).
- Between two sections each strip boundary moves along a **smoothstep taper** (`taper`, default 25 m), so
  a kerb never steps. A lane that appears or disappears does so by paint (its line starts, or a hatched
  wedge closes it).
- **Junction** = a list of street ends meeting at a point. The generator trims each arm back to its
  **mouth** (where the corner arcs to its neighbours start), joins neighbouring arms' outer kerbs with a
  **kerb return** of radius `R`, and fills the rest with asphalt. Each arm gets a **crossing** (zebra,
  width 4 m) just outside the mouth, a **stop line** 1.2 m behind it, solid lane lines over the last
  `solid` metres, and turn **arrows** from the lanes' `turn`. A median reaching the junction ends in a
  rounded nose behind the crossing; where a crossing passes a median it leaves a refuge.
- Trams keep their OSM tracks (they are accurate to ~0.5 m); the tram strip is centred on them.

Outputs, all existing layers, so the renderer is unchanged and both city paths (runtime and prebuilt
sectors) work: `carriage` (asphalt polygons), `kerbs`, `islands` (median noses and refuges), `medians`
(tram bed / grass strips), `markings` (`lane`, `solid`, `stop`, `bus`, `cycle`, `cyclefill`, `stripe`
hatching), `symbols` (`arrow`, `bus`, `bike`), `paths` (`zebra`), `tram_xings`. What it removes: inside
the designed footprint (the union of its carriageways, buffered 2.5 m) every old road ribbon is hidden
(`hide` ranges), and old carriage areas, kerbs, islands, medians, markings, symbols, zebras and tram
crossings are dropped or clipped.

## 6. Gathering a street's needs

The spec is written from evidence, in this order (the skill has the commands):

1. **OSM tags** of every way of the street: `lanes`, `lanes:forward/backward`, `turn:lanes`,
   `bus:lanes`/`psv:lanes`, `cycleway:*`, `placement`, `width`, the crossings (`highway=crossing` nodes and
   `footway=crossing` ways), tram tracks. `road_design.py --needs AREA` prints them per street, ordered
   along it.
2. **The GUGiK orthophoto** (0.1 m, fetched on the Mac): kerb lines, median and tram bed edges, where
   lanes start and end, crossings, stop lines, arrows. `tools/road_design_plot.py unroll` straightens
   the photo along a street's axis with a 1 m ruler, so a cross-section is read straight off it, and
   `--map` draws the generated kerbs and lines over it; `road_design_plot.py flat` renders a map's road
   layers over the photo. Offsets are tuned until the generated kerbs sit on the photo's kerbs (within
   ~0.5 m). Tall buildings lean over the street in the photo (relief): read those stretches from OSM.
3. **Street photos** (Mapillary, Panoramax via `tools/street_photos.py`) where the photo is unclear: the
   arrows, a bus lane's paint, tree pits.

The spec is the only place a street's shape lives; a fix is an edit of the spec and a rebuild.

## 7. Sources

- ASAM OpenDRIVE 1.8 specification (reference line, lane sections, junctions): https://www.asam.net/standards/detail/opendrive/
- osm2streets, intersection geometry and transformations: https://github.com/a-b-street/osm2streets ;
  talk "osm2streets" (State of the Map 2022): https://dabreegster.github.io/talks/sotm_2022/slides.html ;
  `general_case.rs` (trim-back intersection polygons): https://github.com/a-b-street/osm2streets/blob/d222c5f0074c007b24dc534b15749b866728e91f/osm2streets/src/geometry/general_case.rs
- Esri CityEngine, street and intersection shapes: https://doc.arcgis.com/en/cityengine/latest/help/help-street-and-crossing-shapes.htm
- Cities: Skylines roads, nodes, segments and lanes (TM:PE wiki): https://github.com/CitiesSkylinesMods/TMPE/wiki/Nodes,-Segments,-Lanes ;
  traffic deep dive: https://gamedeveloper.com/design/game-design-deep-dive-traffic-systems-in-i-cities-skylines-i-
- Polish road markings (P-1 … P-27): https://en.wikipedia.org/wiki/Road_signs_in_Poland ; regulation text
  §85-94: https://lexlege.pl/znaki-dr/rozdzial-4-znaki-drogowe-poziome/14197/ ; lane line rules:
  https://arslege.pl/znaki-wyznaczajace-pasy-ruchu/k1026/a69164/
- OSM lane tagging: https://wiki.openstreetmap.org/wiki/Key:turn , https://wiki.openstreetmap.org/wiki/Proposal:Placement ,
  https://wiki.openstreetmap.org/wiki/Key:area:highway
- Streetmix (cross-section editor): https://streetmix.net
- Earlier project research: docs/design/roads-and-objects-plan.md (RS1-RS9), docs/design/operation-unslop.md,
  the lane lesson (F, 2026-11-05: kerbs stay straight, lane count changes are paint).
