# Lane drops: two lanes into one, like a real street

F, 2026-11-14, on a crop of the top of Nowy Zjazd by the Śląsko-Dąbrowski bridgehead: "this
connect from two lanes to one lane can be smoother, like in real life; make the research, what is
the pattern, how many times I have it in the game, how to fix". Built in `tools/lane_tapers.py`
(verify step `tapers`).

## 1. How real streets do it

- **Geometry.** A lane is closed (or opened) along a taper, never at a corner. The length grows with
  speed and with how far the edge moves sideways. The US rule for 40 mph and under is
  L = W S² / 60 (feet, mph): at 30 mph a 12 ft lane takes 180 ft, a **1:15** taper; at 35 mph about
  1:20 ([Iowa DOT design manual 6C-1](https://iowadot.gov/design-manual/chapter-6-geometric-design/6c-1-adding-dropping-or-redirecting-through-lanes)).
  At Warsaw's 50 km/h, dropping a 3.25 m lane therefore takes about **50 m**; a small street at
  30-40 km/h does it in about 1:10.
- **Paint (Poland).** The lane that ends is marked before the taper: the line between the lanes turns
  into a P-6 warning line (dashes longer than the gaps), P-9 arrows ("strzałka naprowadzająca") tell
  the drivers in the ending lane to move over, and a P-21 hatched area ("powierzchnia wyłączona z
  ruchu") fills the wedge where the lane runs out (rozporządzenie w sprawie znaków i sygnałów
  drogowych, § 86-90). In the city centre the **kerb usually stays straight** and the lane ends
  in paint; where the carriageway itself narrows (a ramp, a bridgehead) the kerb drifts along the
  same long taper with small radii at both ends (F's satellite lesson of 2026-11-05 says the same).

## 2. The pattern in our map

OpenStreetMap splits a street into many ways (at every crossing, bus stop, bridge end), each with
its own lane count, and the bake sizes each way from its count. `tools/road_smooth.py` (2026-11-05)
tapers a width change where two ways meet, but:

1. only inside the **narrower** way, and at most over **half** of it;
2. when that leaves under 4 m it **skips** the join (a hard step: F's crop, where the one-lane piece
   is 6 m long);
3. even with room it runs 20-30 m along a smoothstep, about **1:8** in its steepest middle.

So after a short piece the taper is squeezed into a few metres (the dark wedge) or missing (the
step, with the wider way's square or round end).

## 3. How many (2026-11-14, main before this change)

`python3 -I tools/lane_tapers.py --list` measures every place where two ways of one street meet end
to end and the edge changes by 0.3-6 m, away from junctions (a side where another street leaves the
node is left out: its kerb turns into that street; a way drawn by a carriageway area is left out
too: the area's outline is the edge there). Measured along the street through the next ways, 30 m
each side; worst side per place:

| steepest 2 m of the change | before | after |
| --- | ---: | ---: |
| a step (steeper than 1:2) | 32 | 11 |
| 1:2 to 1:5 (a wedge) | 79 | 28 |
| 1:5 to 1:10 | 122 | 83 |
| 1:10 to 1:15 | 146 | 230 |
| 1:15 or flatter (real life) | 98 | 138 |

(477 places before, 490 after: the new vertices split no place, but a taper now reaching a way
that was flat adds it to the count. "Abrupt" = steeper than 1:5: **111 before, 39 after**.)

F's crop at the top of Nowy Zjazd: both sides go from a step to a taper, 1:15 on one side and 1:8
on the other (the river side, where the ramp's retaining wall stands close). The Nowy Zjazd height
fix (#770) removed the concrete wall stub that stood at the node.

## 4. The fix (`tools/lane_tapers.py`)

A post-pass on the finished map (bake_osm.py after road_fixes; it also runs on a baked map):

- Each side of each change gets one straight taper with rounded ends, **1:15** on main streets
  and **1:10** on residential ones (12-60 m), unless it is already at least 3/4 of that.
- It runs on the narrower side first, **through as many ways of the street as it needs**, so a lane
  opens or closes after the node; it stops at a junction, at the next real width change or at a
  way drawn by a carriageway area. The part that does not fit goes onto the wider way before the
  node, but only so far that the outer lane's car still has asphalt beside it (the lane graph is
  not touched) and never over a zebra or cycle crossing.
- The new asphalt keeps 0.3 m off walls, fences, hedges, barriers, buildings, platforms, islands,
  tree trunks and cycle tracks (the whole strip of new asphalt is checked, not only its edge); where one stands in the way the taper is shortened, and a taper that would come
  out no flatter than the old one (or makes a neighbour steeper) is not used.
- Kerbs follow the new edge: a kerb belongs to the way whose old edge it lies on (not the nearest
  centreline, so a dual carriageway's kerbs keep to their own side), a kerb that ran along the old
  edge keeps its distance from it, one that ran across it goes onto the new edge, and the old
  step's face across the road goes onto the new edge. An edge line beside a kerb moves exactly as
  the kerb did, so the two never cross; painted island outlines keep their shape.
- The dashed line between two lanes ends where the taper begins, as a real lane line ends at the
  hatching (a line that only passes a narrowing and goes on stays); lamps and signal poles step off
  new asphalt.

What is left (39): squares and short pieces between junctions (Plac Bankowy, Plac Narutowicza,
Plac Piłsudskiego, Plac Małachowskiego, Wierzbowa, Senatorska and Podwale by Plac Teatralny), and
streets where a wall, a tram platform or a cycle track stands right at the change (Targowa,
Anielewicza, Aleja Solidarności, Raszyńska, Most Łazienkowski, Sokola).
Most of those want the painted version below rather than a moved kerb.

## 5. Next

- The painted version for city streets: kerb straight, the lane ends in a P-21 hatched wedge with
  P-9 arrows before it (roads-true-to-life RT-4, parked in TD-23 until F asks).
- The leftovers on squares belong to the road design areas (docs/design/road-design-system.md).
