# Kościół św. Karola Boromeusza (St Charles Borromeo), Chłodna 21: spec

Site key `church_karol` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_karol`): the whole church is one model that replaces the kit
church. Written 2026-11-14 from Mapillary photos along Elektoralna (2019 to 2026, the apse end,
the north side and the towers over the roofs; refs/karol, never shipped), the OSM outline and
GUGiK's LoD2. The west front on Chłodna is not photographed.

The kit church it replaces (2026-11-01) was a beige box with a kit tower, and its card placed it
"by Powązki Cemetery" (that is the other St Charles, at the map edge). The real church is Henryk
Marconi's **cream classicist basilica** (1841-49, rebuilt after 1944).

## 1. Identity
1. **Cream plaster**, white pilasters and cornices, grey roofs.
2. **Two slim towers** on the west front: square shaft, arched belfry with corner urns,
   octagonal arcaded lantern, small grey dome, cross.
3. The **round apse** toward Elektoralna under a **grey-green half dome**, ringed by pilasters,
   the nave's east pediment over it with a little bell-cote and cross.
4. The tall **nave with its clerestory** of round-headed windows over lower **aisles** with
   pilasters and tall relief panels; the **transept's** pediments.

## 2. Massing
Frame: origin (-2151.7, -460.7), u along the church to the east (axis (0.8643, -0.5029)), +v to
the south; the axis is v = -0.1. Ground g is the lowest terrain under the outline (14.2).

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave and clerestory | u -13.3 to 23.7, v ±4.7 | eaves 15.8; low gable along u, ridge 17.4 |
| aisles | u -8.3 to 17.1, v ±4.7 to ±8.4 | 10.3, flat |
| west block | u -13.3 to -8.3, v ±6.5 | 10.3, flat |
| transept | u 17.1 to 23.7, v -11 to 10.4 | eaves 10.8; low gable along v, ridge 12.3 |
| apse | half circle r 4.9 round (23.7, -0.1) | 11.4; cornice to 11.8; half dome to 14.6 |
| towers (2) | 3.2 m square at u -11.75, v -0.1 ± 4.9 | shaft to 20; belfry to 24; lantern to 27.2; dome to 28.9; cross to 30.3 |

LoD2 (ground 14.2): the nave 30 to 31 abs (16 to 17), the aisles and west block 24 to 25
(10 to 11), the transept 24 to 25, the apse 25 to 28. The towers are in neither OSM nor LoD2.

## 3. Facade: the west front (default, unphotographed)
Four pilasters, a round-headed portal (2.1 m, to 4.5) under a pediment, a tall round-headed
window (2.4 m, to 14.6) over it in the nave's front, a white band and the low pediment.

## 4. Facade: the sides and the east
Aisles: eight pilasters a side, a tall relief panel (0.9 x 4.4 m) in each bay, small basement
windows in the grey plinth. Clerestory: eight round-headed windows (1.3 m, 11.4 to 14.25) a side.
Transept ends: four pilasters, a door (1.6 x 3.2 m) under a small pediment, a lunette window, the
pediment. Apse: seven pilasters and six arched relief niches between them.

## 5. Roof
Grey sheet (#70757a) on the nave and transept, a paler grey on the flat aisle tops; the apse's
half dome #5f6f68 in three rings; the towers' domes #7d8287, iron crosses.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6d6a8 | M_STONE |
| Pilasters, cornices, pediments | #f1e9cf | M_STONE |
| Relief panels, niches | #d3c296 | M_STONE |
| Roofs | #70757a | M_STONE |
| Half dome | #5f6f68 | M_STONE |
| Tower domes | #7d8287 | M_STONE |
| Plinth | #a29d91 | M_STONE |
| Doors | #4a3a30 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text fixed to Chłodna. No floodlights.

## 8. Detail level and budget
L2, triangle budget 1850 (measured 1693, `check_mesh_quality.gd`): pilasters as single boxes and
clerestory panes without surrounds to stay lean. Shots: `tools/turntable.sh church_karol`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism + gable | 37 x 9.4 m | u -13.3..23.7, y to 17.4 | M_STONE #e6d6a8, #70757a | 4 clerestory |
| aisles | 2 prisms | 25.4 x 3.7 m | v ±4.7..8.4, y to 10.3 | M_STONE | 4 aisles |
| west block | prism | 5 x 13 m | u -13.3..-8.3, y to 10.3 | M_STONE | 3 west front |
| transept | prism + gable | 6.6 x 21.4 m | u 17.1..23.7, y to 12.3 | M_STONE, #70757a | 4 transept |
| apse | half prism, cornice, 3 dome rings | r 4.9 m | east end, y to 14.6 | M_STONE, #5f6f68 | 3 apse |
| towers | box, belfry, 4 urns, octagon, 2 dome rings, cross | 3.2 m | west corners, y to 30.3 | M_STONE, #7d8287 | 2 towers |
| pilasters, reliefs | boxes | 0.6 m | aisles, transept, apse, front | #f1e9cf, #d3c296 | 4 aisles |
| windows | arched panes | 1.3 to 2.4 m | clerestory, front, transept | PAL_GLASS_DARK | 4 clerestory |
| bell-cote | box, arch, cross | 1.4 m | east pediment | M_STONE | 3 apse |
