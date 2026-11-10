# Road design quality checklist (AAA bar)

Every lesson from F's reviews of areas 1 and 2 (2026-11-06), in one list. An area is done only when
every line below holds for every street in its box, shown on its before/after page. When a photo is
ambiguous or a line cannot be met, ask F with the shot and the ortho crop. Do not guess.

## Measure, never assume

- Lane count, lane widths, bus lanes and median/island positions are measured on the ortho, section
  by section. OSM `lanes=` tags only seed the draft (Emilii Plater: 5 lanes, one of them a bus lane).
- Every arm of every junction is measured: stop line, kerb radius, island, mouth width (x, w, bx, bw).
- Zebras and cycle crossings are drawn as painted: their position, width (some are 15 m) and the
  cycle crossing's side (`bs`, `bw`). A crossing the old map had and the photo still shows stays.
- A street that changes width does it where the photo shows, with a taper (`taper`) and no step.

## Shape

- Kerbs stay straight. A change in lane count is paint, not a kerb jog.
- Median ends are square, as built in Warsaw, not pointed.
- A side road's mouth follows that side road's direction; a Y-shaped split gets one mouth.
- Openings stay within the clamp (no mouth wider than the side road plus its radii).
- Lane arrows and bus-lane paint ("BUS") are on every lane that has them in the photo.

## Continuous for people and bikes (quality gate, F 15:19)

- Roads, footways and cycle tracks are continuous. `continuity` reports 0 in both directions:
  every path end at the asphalt sits on a crossing of its kind, and every crossing has a path of
  its kind arriving at both kerbs.
- No free path ends mid-block. A real dead end is listed in `open_ends` with a note on what is
  there in the photo.
- Corners: the footway goes round the corner to the zebra; it does not stop at the kerb line.
- Never loosen the gate to pass. Fix the spec (a crossing, a `bs`, a `closed` stretch) or the map.

## Objects and surroundings

- Nothing stands on the new asphalt: lamps, trees, signs, bollards and stops are reseated off it.
- Pavements the wider kerb covers move out to the new kerb line.
- Tram tracks, platforms and stops keep their places; a lane next to a platform keeps its width.

## Drive and traffic

- `check_lane_drive.gd` passes on every street in the box, both ways and into the side roads.
- No car is spawned or routed across a median or into a closed stretch.
- Shots use `--no-traffic` until the traffic graph follows the spec's lanes; say so on the page.

## Proof for F

- Before/after shots from the same spots, same yaw and zoom, with footway/cycle overlays.
- The page lists what was measured, what changed per street, every `open_ends` entry and any
  question parked for F.
- Gates on the page: `--check` 0, continuity 0, lane drive PASS, `check_map_data.py`, bench when
  the area adds many carriageway pieces.
- The progress page (`tools/road_progress.py`) is updated in the same PR.

## Asking F

Ask, with a shot and an ortho crop, when: the photo does not show the lane paint (trees, shadow,
roadworks); the photo and the street view disagree; a crossing or a path seems gone in real life;
a change would cut a quest route, a landmark's forecourt or a parking spot used by the game.
Keep building the rest of the area while the question waits.
