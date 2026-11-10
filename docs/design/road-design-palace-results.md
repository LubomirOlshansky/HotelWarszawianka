# Road design POC: the Palace streets rebuilt from zero (results)

2026-11-06. The research and the design are in [road-design-system.md](road-design-system.md); the
workflow is the skill `road-design`. This page says what the proof of concept built, how it looks next
to main, and what is left.

**Not applied to the shipped map in this PR.** Apply it locally to see it:
`python3 -I tools/road_design.py palace` (writes `game/map/centrum.json`; refused on a map that has it
already), then `python3 -I tools/bake_sectors.py`. Where a designed street ends mid-block the old lane
lines carry on beside the new ones (up to 2.4 m off), which the road ratchets catch (7 more line jogs
for `road_smooth --check`, street_pass K2/L2 up on the three streets). Round 2 closes the area on
junctions first.

## What was rebuilt

Spec: `docs/roads/palace.json` (about 200 lines). Generator: `tools/road_design.py palace`. Pictures:
`tools/road_design_plot.py`.

| Street | Stretch | Length | What the spec says |
| --- | --- | --- | --- |
| Marszałkowska | 57 m north of Świętokrzyska | 57 m | tram bed in the middle, 3 + 3 lanes, T T R arrows |
| Marszałkowska | Świętokrzyska to Złota | 493 m | tram bed, 3 + 3 lanes; parking strip from s 73; a bus lane and a hatched gap from s 360; two zebras with cycle crossings (s 177 and 303, from OSM: the photo predates them); Fangora, Sienkiewicza and a service road open into it |
| Świętokrzyska | 85 m east, 120 m west of Marszałkowska | 205 m | 5 lanes with T T L arrows and a cycle lane east; TR LT arrows, a hatched gap and parking west |
| Emilii Plater | Pańska/Śliska to 170 m short of Jerozolimskie | 400 m | two carriageways of 3 lanes + a red cycle lane, a raised median with trees, two U-turn gaps, two zebras with refuges, 9 side roads and driveways |
| Junction | Marszałkowska × Świętokrzyska | | 4 arms, 6 m kerb returns, 4 zebras (8.5, 9.5, 7, 8 m wide, as painted), 4 cycle crossings, stop lines, solid lines before them |

In total 1,155 m of street and one big junction: 265 carriageway pieces, 58 kerb runs, 149 lane lines,
40 arrows and words, 14 zebras, `--check` 0 problems. Applying it hid 62 old OSM road ribbons where
they ran inside the new streets, and dropped or clipped the old layers there (223 marking pieces, 109
kerb pieces, 70 symbols, 27 zebras and cycle crossings, 25 old median grass patches, 16 planter walls).

## Before and after

All shots: cloud renderer (`--quality=low`), daylight, no traffic, `--yaw=20.2 --size=40`, the same
spots on main's map and on the designed map. The images are on the POC's before/after page (linked
from the PR); they are not committed.

| Spot | Where | Before (main) | After (design) |
| --- | --- | --- | --- |
| `ms` | Marszałkowska × Świętokrzyska from the south | short zebra bars, the stop line far behind the zebra, lane lines running on through the junction box | one asphalt shape with round corners; each arm a full-width zebra as painted (8.5-9.5 m) beside a red cycle crossing; stop line, solid lines and T T R arrows on the approach |
| `ms2` | Marszałkowska 150 m south | a slip road with a pavement triangle, an asphalt flare on the east kerb | Fangora opens with kerb returns; zebra and cycle crossing over both carriageways and the tram |
| `ms3` | Marszałkowska by the metro | a U-turn through the tram bed with kerb bulges and lane lines bending round it | zebra and cycle crossing, straight kerbs; the U-turn is not designed yet (below) |
| `ep` | Emilii Plater by the Palace | small jogs in the median edge and a grass patch where two OSM ways meet | straight kerbs, median and cycle lanes along the whole stretch |
| `ep2` | Emilii Plater U-turn | two noses of different shapes | a gap with matching round noses |
| `ep3` | Emilii Plater zebra by the Palace | turn arrows painted past the zebra, a median gap behind it, zebras 3.5 m | the zebra across both carriageways with a refuge in the median, side roads opening into the street |
| `ep4` | Emilii Plater at Śliska | similar to after | the same gap; the side street gets kerb returns |

Flat views (from `road_design_plot.py flat`, the old map on the left): the junction shows the main
difference best. The old one is the overlap of 9 ribbons with an island left over by the tram stop;
the new one is one shape drawn from the four arms.

## What it fixed and why it stays fixed

- No joins: each street is one axis with cross-sections, so there is nothing to stitch. A lane that
  starts or ends is paint; the kerbs only move where the real kerb moves, over a 12-25 m taper.
- The junction is built from its arms (mouths, kerb returns, crossings, stop lines), so its lines cannot
  cross each other.
- Changing a street is an edit of its spec and a rebuild, checked by `road_design.py --check-all` (the
  new verify step `design`).

## What is left

1. **The two ends of Emilii Plater** that IMG_7264 and IMG_7266 show (the "Y" north of Jerozolimskie,
   the stepped widening by Świętokrzyska) are not rebuilt yet. They need the Emilii Plater ×
   Jerozolimskie and Emilii Plater × Świętokrzyska junctions, with the 4-lane left|left|through|right
   approach and the island at s 495-600 measured on the ortho. Next, with Aleje Jerozolimskie from
   Emilii Plater to Marszałkowska.
2. **Tram U-turns**: Marszałkowska has two links through the tram bed (s 191 and 283-291 from the
   junction) that the old map drew; the spec has no way to say "a paved gap in a tram median" yet.
3. **Traffic inside junctions**: the street edges now run on the designed lanes (round 1b, below);
   the turn links inside the junction box still come from OSM and should come from the arm arrows.
4. **Bake integration**: the design is applied to `centrum.json` by hand after the bake (and not yet in this PR).
   `apply_all()` is ready for `bake_osm.py` to call after `road_smooth`.
5. **Phone check**: none yet. The draw call count is unchanged in kind (the same layers), but the
   carriageway comes in 8 m pieces, so a bench run is due before this goes beyond a POC.

## Round 1b and 1c (same day, after F's review)

- **Side roads** are found from the map: every road ribbon (not footways) that crosses a designed
  street's kerb gets an opening, kerb returns turned to the side road's own angle (kept within 65
  degrees of square), and up to 9 m of the side road paved so it meets the mouth. Two one-way
  ribbons of one mouth (a Y) become one opening as wide as both roads.
- **Median ends** are square with 0.8 m rounded corners, as kerbed on Emilii Plater.
- **Traffic**: `retarget_graph` moves the OSM traffic edges of the designed streets onto the designed
  lanes (44 edges), blending over 12 m at free ends.
- **Driving**: `game/tools/check_lane_drive.gd --streets=Marszałkowska,Świętokrzyska,Emilii Plater
  --box=-1500,-160,-930,470` drives the three streets both ways, and `--route=` 34 routes into and out
  of the side roads: all pass on main and on the designed map, at the same speeds.

## Round 2b: continuous footways and cycle tracks (F, 2026-11-06)

F's review: after the rebuild the zebras and cycle crossings no longer met the footways and cycle
tracks, and the Emilii Plater approach to Jerozolimskie had the island in the wrong place.

- **Continuity gate.** `continuity()` checks every path end the new asphalt cut: it must be on a
  crossing of its kind, joined to another path, a cycle track running into a painted cycle lane, or a
  real dead end listed in `open_ends`. It runs after `--out` and in `--check-all` (verify.sh
  `design`). On the Palace area it found 65 failures before the fixes and 0 after.
- **Fixes in apply_design.** Pavements and cycle tracks the wider kerb now covers move out to the new
  kerb (16; a footway goes beyond a cycle track, never on it); cut ends bend onto the nearest crossing
  of their kind over their last metres without crossing asphalt (53); a pavement cut by a side
  road's mouth gets a zebra or cycle crossing over the mouth.
- **Missing crossings** the gate found and the ortho confirms: Emilii Plater by the bus loop (zebra
  s 483 + cycle crossing) and Świętokrzyska west (s 271 + cycle crossing).
- **Emilii Plater approach** (e_mid s 495-639): no island from 495 to 553 (paved, as on the photo),
  then the island −5.0..0.5 to the crossing; northbound 2 lanes + a 2 m cycle lane, southbound
  4 lanes widening to 5 at the stop line (L, L, T, T, R; 17 m of asphalt on the ortho).
- **Round 2c (same evening, F's corners).** Paths that stopped near the new kerb without being cut
  (they ended at the old crossings) are led to the new crossings too; every crossing end on a kerb
  gets a short link from the nearest path of its kind; dead stubs to old crossings go; the gate
  checks both ways (path end -> crossing and crossing end -> path). Two more lost crossings back
  (j_mid cycle crossing s 303, e_nn zebra s 122). Marszałkowska south arm re-measured: 15 m zebra,
  lanes 5.8..15.0 / -15.0..-5.3 at the tram stop. Emilii Plater's 5th southbound lane is a bus lane
  (BUS painted on the photo).
