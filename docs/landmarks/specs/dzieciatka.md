# Kościół parafialny pw. Dzieciątka Jezus (the Child Jesus parish church), by Lindleya: spec

Site key `church_dzieciatka` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_dzieciatka`): the whole church is one model that replaces the
kit church. Written 2026-11-14 from Mapillary photos (refs/dzieciatka, never shipped): rmikke
2019-02-25 from the north-west corner (the tower's door, the nave's north wall), andpol_2288
2019-10-31 from the south along the street (the tower's west face from bottom to cross),
2026-05-21 views from Chałubińskiego and 2021-06-08 from Oczki; the OSM outline and GUGiK's LoD2.
Panoramax has nothing here; Wikipedia and Commons are not reachable from the cloud.

The kit church it replaces (2026-11-01) was a beige "modern" box with a pyramid tower on the
**east** end. The real church is **red brick neo-Gothic** and its tower stands in the middle of
the **west** front (LoD2's tower, 28 m, at the outline's west end; the door is in its west face).

## 1. Identity
What makes it read as itself:
1. **Red brick** all over, cream plastered fields in the pointed recesses.
2. A **slender west tower**: a tall cream pointed recess with the door at its foot and a lancet
   over it, a **stepped gable** with cream blind lancets standing on its face, a belfry with two
   louvred lancets a side and an oculus, four corner pinnacles, a green copper hipped roof, a cross.
3. One **big steep roof** (45 degrees) over nave and aisles in dark green copper.
4. Short **transepts with stepped gables**, buttresses and tall lancets along the sides.
5. A lower **chancel with a three-sided east end** and low annexes round it.

## 2. Massing
Frame: origin (-1842.0, 980.0), u along the church to the east (axis (0.9353, -0.3539)), +v to
the south; the front faces -u (west). The axis is v 4.875. Ground g is the terrain 3 m before the
tower (14.5; the plot is flat). Walls run down to g - 1.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave and aisles | u 0.4 to 19.6, v -2.2 to 11.95 | eaves 11; one gable along u, ridge 18 |
| tower | u -0.6 to 4.6, v 1.925 to 7.825 | walls 23; hip to 28; cross to 30 |
| transepts | u 9.4 to 15.5, out to v -3.8 and 13.65 | eaves 8; gable along v, ridge 12.7; stepped gables to about 12.8 |
| chancel | u 19.6 to 31.5, v 0.9 to 8.85, east corners cut | eaves 11.3; ridge 15; three roof faces over the east end |
| north annex | u 15.5 to 27.6, v -4.1 to 0.9 | 3.4, flat copper |
| south annex | u 19.6 to 27.6, v 8.85 to 11.95 | 4.4, flat copper |
| sacristy | u 31.4 to 35.4, v 0.7 to 9.3 | 9.2, low hip to 10 |

LoD2 (ground 14.5): the nave's eaves 11.1 north and 11.3 south, the ridge 18 at v 4.85 from u 0 to
19; the tower's eaves 23 and ridge 28; the transepts' gables 8 to 12.7 at u 12.45; the chancel 11.3
to 15 with the east end's slope down to 10 at u 31.5; the annexes 3.3 to 4.2 (north), 3.5 to 6.6
(south); the sacristy 9.5. OSM gives 30 m (the cross).

## 3. Facade: the front (west), base to top
Steps (granite) out to u -2.5. The tower's lower stage: a cream pointed recess (2.7 m wide, 0.4 to
11 m) holding the dark door (1.9 m, to 4.3) and a lancet window (1.6 m, 4.7 to 10); stepped corner
buttresses to 9.8 and 11.6. String courses at 11.6 and 16.9. On the face over the first string
course a stepped gable in four steps (4.9 m wide, 11.95 to 15.75) with three cream blind lancets.
The belfry (all four faces): two louvred lancets in lighter brick frames (17.4 to 20.3), a cream
oculus at 21.5, the brick eaves band at 22.4, four pinnacles from 23 to 26.2, the copper hip, the
cross. Either side of the tower the aisles' west walls with one lancet each and corner buttresses.

## 4. Facade: the sides and the back
The nave's long walls: buttresses at u 0.75 and 4.95 (stepped, to 9.4), lancets in cream recesses
in the two western bays (3 to 9.2) and one higher in the bay east of the transepts (over the
annexes). The transept ends: a big lancet (2.5 to 7.2) and the stepped gable (five steps,
lighter brick copings) with three cream blind lancets. The chancel: two small lancets a side over
the annexes; the annexes and the sacristy small lancets. The east end and the south side are seen
only from far off (default, see QUESTIONS).

## 5. Roof
Dark green copper (#4f6b5c) on the nave, transepts, chancel and annexes; paler verdigris
(#6e9a86) on the tower's hip.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #a5482f | M_STONE |
| Bands, copings, frames | #b65c40 | M_STONE |
| Recesses, blind lancets, oculi | #e4d6b6 | M_STONE |
| Nave roofs | #4f6b5c | M_STONE |
| Tower roof | #6e9a86 | M_STONE |
| Plinth, steps | #8e8a82 | M_STONE |
| Door | #3b2e2a | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |
| Louvres | CHURCH_DARK | M_STONE |

No new material, shader instruction or draw call. Recess and pane layers stand 4 cm apart.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text unchanged: "Kościół Dzieciątka Jezus",
"Kościół parafialny z wysoką wieżą." / "A parish church with a tall tower." No floodlights.

## 8. Detail level and budget
L2, triangle budget 1800 (measured 1594, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_dzieciatka`; city `--cams=nw:-1824,,979,315,-28,80`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | box | 19.2 x 14.15 m | u 0.4..19.6, v -2.2..11.95, y -1..11 | M_STONE #a5482f | 3 roof |
| nave roof | gable | rise 7, half 7.45 | over the nave, y 11..18 | #4f6b5c | 3 roof |
| bands | ring slabs | 0.7 m, 0.18 proud | nave y 10.3, chancel 10.7, plinth -1..0.6 | #b65c40, #8e8a82 | 4 sides |
| tower | box | 5.2 x 5.9 m | u -0.6..4.6, y -1..23 | M_STONE #a5482f | 2 tower |
| tower roof | hip + 4 pinnacles + cross | rise 5 | y 23..30 | #6e9a86 | 2 tower |
| portal | 3 lancet panels + steps | recess 2.7 m | tower west face, y 0.4..11 | #e4d6b6, door, glass | 2 tower |
| tower gable | 4 steps + 3 blind lancets | 4.9 m wide | tower west face, y 11.95..15.75 | #a5482f, #e4d6b6 | 2 tower |
| belfry | 8 framed louvres + 4 oculi | 0.84 m lancets | all faces, y 17.4..22 | #b65c40, CHURCH_DARK, #e4d6b6 | 2 tower |
| buttresses | stepped boxes | 0.7 x 0.75 m | nave sides u 0.75, 4.95; tower west corners | M_STONE | 4 sides |
| side lancets | lancet panels | 1.4 m panes in 1.9 m recesses | nave, chancel, annexes | glass, #e4d6b6 | 4 sides |
| transepts | box + gable + 5 steps | 6.1 x 1.6 m | u 9.4..15.5 both sides, y to 12.8 | M_STONE, #4f6b5c | 4 transepts |
| chancel | prism + gable + 3 roof faces | 11.9 x 7.95 m | u 19.6..31.5, y to 15 | M_STONE, #4f6b5c | 5 chancel |
| annexes, sacristy | 3 prisms, flat caps, low hip | 3.4 to 9.2 m | north, south, east | M_STONE, #4f6b5c | 5 chancel |
