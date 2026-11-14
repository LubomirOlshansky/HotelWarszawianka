# Kościół Ewangelicko-Augsburski Świętej Trójcy (Holy Trinity): spec

Site key `trojca` in `game/scripts/landmarks.gd` (`_find_trojca`, `_build_trojca`, `_trojca_ring`).
First written 2026-10-31 from the OpenStreetMap outline and LoD2 alone; **rebuilt 2026-11-14 from
photos** (churches review, Krakowskie Przedmieście set): the whole building, every side, the dome and
the lantern. Sources in the shared store `refs/trojca/` (SOURCES.md): two close Mapillary photos of
the north-west portico and the drum (2011), the dome and lantern from Plac Piłsudskiego (2019), and
GUGiK LoD2 for every height. Commons is blocked from the cloud; trees hide the church from every
other Mapillary spot, Panoramax has nothing here.

## 1. Identity

Szymon Bogumił Zug's Lutheran church (1777-1781, rebuilt 1948-1953) on Plac Małachowskiego, beside
Zachęta. Read at a glance, in this order:

1. **A white round drum** on a Greek-cross plan, 33.4 m across, banded all over in horizontal courses.
2. **A low green copper dome** springing straight off the cornice, small dormers round its foot.
3. **A glazed lantern**: a collar, tall windows between piers, an overhanging cornice, a ribbed
   cap, a knob and a cross (58 m).
4. **Four porticoes** of four fluted Doric columns under pediments, one on each arm.
5. **Tall round-arched windows** low on the drum and **framed oculi** high on it.

What the 2026-10-31 model got wrong (photo check): the lower drum was the monument shader's grid of
tall windows (really rusticated courses and eight arched windows), sixteen small oculi (really
eight big framed ones), plain Tuscan columns up to 10.7 m and copper pediment roofs (really fluted
Doric columns up to 12 m, a triglyph frieze, an entablature to 15 m as LoD2 says, grey roofs and a
lunette in each tympanum), no doors, a lantern 2 m too low with a thin cap.

## 2. Massing

Centre (-854.6, -508.6), a circle fitted to the outline's 28 drum points: radius 16.7 m. The four
arms turn -24.6° (ENE), 65.4°, 155.4° and 245.4° (in the game's x/z angle); their fronts 21.8,
24.1, 21.7 and 21.3 m from the centre (the outline's corners). The drum's rings (`_trojca_ring`)
turn with the arms, so with 32 sides a flat facet faces each arm, each diagonal and every 11.25°.

LoD2 over the ground (12.2 m abs.): drum cornice 26.6 m; dome 29.4 m at r 15, 34.1 m at r 11,
36.9 m at r 8; lantern foot 37.9 m, its stage to 49.7 m, cap apex 53 m; the arms all alike, eaves
15 m and pediment apex 18 m (so all four are porticoes; only the NNW one is photographed).

## 3. Facade, base to top

- **Plinth**: grey, 0.3 m proud, to 1 m.
- **Lower drum** (1-13 m): white with a shadow line every 2.4 m (the rustication's courses).
  **Eight arched windows**, two in each quarter at 11.25° either side of the diagonal: glass 2.8 m
  wide from 2.5 m to the spring at 9.6 m (11 m at the crown) in a light surround, a keystone.
- **Band** 13-13.9 m, 0.32 m proud, a darker dentil line under it.
- **Upper drum** (13.9-24.4 m): courses every 1.5 m. **Eight oculi** at 19.6 m, over each portico
  (just above its pediment) and on the diagonals: glass r 1.45 m, a light ring r 1.8, a moulding
  ring r 2.05, a patera r 0.42 above and below, all on a raised panel 4 m wide.
- **Entablature** 24.4-25.8 m (architrave, frieze) and a **cornice** 25.8-26.6 m, 0.6 m proud.
- **Porticoes** (each arm): a vestibule 12 m wide back to the drum, its front 4.2 m behind the
  column line; three steps; four fluted Doric columns r 0.68 m (v ±1.85, ±5.0) to 12 m;
  architrave 12-12.9, frieze 12.9-14.1 with seven triglyphs, cornice 14.1-15 m; a pediment 3 m
  high under a grey roof, a lunette (r 1.2 m glass in a light ring) in its tympanum. On the
  vestibule's front an arched niche 4.6 m wide to 8 m, a dark door 2.4 x 3.9 m, a gilt glory over
  it (the NNW door's, photographed; the other three are assumed the same).

## 4. Roof

The dome in five bands of 32 facets from r 16.6 at 26.6 m to r 5.6 at 37.5 m, lighter upwards;
eight small dormers on its lower slope (between the oculi). The lantern: a dark copper collar
r 5 m to 39.6 m with a rail, the glazed stage r 4.4 m to 47.6 m (monument shader windows) between
eight piers, an overhanging cornice r 5.3 m to 48.4 m, a ribbed cap in three bands to 51.7 m, a
gilt knob to 52.6 m and a cross to 57 m (bar at 55.4 m).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Drum, porticoes, columns | #e9e7e1, trims lightened | M_STONE |
| Courses, dentils, triglyphs, oculus mouldings | #bdb9af | M_STONE |
| Plinth, steps | #a9a59d | M_STONE |
| Dome, lantern | #79a796 lightening upwards; collar, piers, cornice #557f72 | M_STONE, M_MONUMENT (lantern stage) |
| Portico and vestibule roofs | #6d7377 | M_STONE |
| Windows, oculi, lunettes, dormer panes | #3c4a52 | M_PANE (lit by chance at night) |
| Doors | #4a3a2e | M_STONE |
| Glories, knob and cross | #c9a24a | M_STONE |

No new material or draw call: everything goes into the city's building surface.

## 6. Ground and night

The square's paving round it (the map's). The car is stopped by the drum and the porticoes (one
merged ring). At night the arched windows, oculi and lunettes light by chance, the lantern's
windows are the monument shader's. Card unchanged: "Kościół Świętej Trójcy", PL "Luterańska rotunda
Zuga z 1781 roku przy placu Małachowskiego.", EN "Zug's Lutheran rotunda of 1781 on Plac
Małachowskiego."

## 7. Detail level and budget

L3, triangle budget 3700 (3361 measured, `check_mesh_quality.gd`). Turntable:
`tools/turntable.sh trojca`. Close view of the photographed portico:
`--solo=trojca --solo-look=lit --lift=15 --cams=nnw:-862.9,,-526.8,210,-12,45`. LoD2 lies inside the
site's circle and is dropped there (no `lod2_tops` cut needed; checked from above on the prebuilt
city).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | 32-gon prism | r 17.0 | y -0.5..1 | M_STONE #a9a59d | 1 drum |
| drum_low | 32-gon prism | r 16.7 | y 1..13 | M_STONE #e9e7e1 | 1 drum |
| courses | 8 thin 32-gon rings | r 16.72, 0.16 m | y 3.4, 5.8, 8.2, 10.6, 16.4, 17.9, 21.4, 22.9 | #bdb9af | 1 drum |
| arched windows | 8 arch panels + keystones | glass 2.8 m wide, trim 3.5 m | y 2.5..11, at ±33.75°, ±56.25° per quarter | M_PANE #3c4a52 | 5 windows |
| band | 32-gon prism + dentil ring | r 17.02 | y 12.75..13.9 | M_STONE | 1 drum |
| drum_high | 32-gon prism | r 16.7 | y 13.9..24.4 | M_STONE | 1 drum |
| oculi | 8 x (panel, 3 discs, 2 paterae) | glass r 1.45, frame r 2.05 | y 19.6, every 45° from an arm | M_PANE, #bdb9af | 5 windows |
| entablature, cornice | 32-gon prisms | r 16.85, 16.8, 17.3 | y 24.4..26.6 | M_STONE | 1 drum |
| dome | 5 frustum bands, 32 facets | r 16.6 to 5.6 | y 26.6..37.5 | #79a796 | 2 dome |
| dormers | 8 boxes, panes, gables | 1 x 1 x 1.6 m | r 15, y 29..31.1, between the oculi | #557f72 | 2 dome |
| collar, rail | 16-gon prisms | r 5.0, 5.15 | y 37.3..39.9 | #557f72 | 3 lantern |
| lantern | 16-gon prism + 8 piers | r 4.4 | y 39.6..47.6 | M_MONUMENT #79a796 | 3 lantern |
| cornice, cap | prism + 3 frustum bands | r 5.3 to 0.35 | y 47.6..51.7 | #557f72, #79a796 | 3 lantern |
| knob, cross | hexagon, upright, bar | 0.9 m knob, 4.4 m upright, 1.6 m bar | y 51.7..57 | #c9a24a | 3 lantern |
| vestibule | box per arm | 12 m wide | from r 14.7 to 4.2 m behind the columns, y -0.5..15 | M_STONE, roof #6d7377 | 4 porticoes |
| door, niche, glory | arch panel, wall, half disc | niche 4.6 m, door 2.4 x 3.9, glory r 1.6 | vestibule front | #4a3a2e, #c9a24a | 4 porticoes |
| steps | 3 boxes per arm | up to 1.1 m | arm front | M_STONE #a9a59d | 4 porticoes |
| columns | 4 per arm | r 0.68, to 12 m | 0.9 m behind the front, v ±1.85, ±5.0 | M_STONE | 4 porticoes |
| entablature | 3 boxes + 7 triglyphs per arm | 12.8-13.4 m wide | y 12..15 | M_STONE | 4 porticoes |
| pediment, lunette | gable, 2 half discs | 13.4 m wide, 3 m high; lunette r 1.5 | y 15..18 | M_STONE, roof #6d7377 | 4 porticoes |

## 9. Open (QUESTIONS)

- Only the NNW portico is photographed; the other three are built like it (LoD2 gives them the same
  heights). Which is the main entrance and whether all four doors carry the glory is unchecked.
- The drum's lower windows: two per quarter is read from the photos beside the NNW portico.
- The dome's ribs (copper seams) are not modelled.
