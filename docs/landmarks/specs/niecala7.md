# Niecała 7 (Rezydencja Opera): spec

Site key `niecala7`, `game/scripts/landmarks/niecala.gd` (`_build_niecala7`). Written 2026-11-26 for F's "model Niecała 7 and the houses round it" (BACKLOG, Thursday 2026-11-26) from 22 reference photos (Commons: Nemo5576's P3289011 from the south, fotopolska.eu 340543 from Niecała; the developer's gallery on 8estate.pl: the balcony arc, the garden; Mapillary 2020-09 along Niecała; GUGiK ortho crop). Kept in the gitignored `refs/niecala7/`, never shipped.

## 1. Identity

Dom Development's Rezydencja Opera (2003-05, Andrzej and Barbara Kaliszewscy with Bohdan Napieralski): a pastiche of the pre-war tenement, eight storeys, 39 flats. Judged first:

1. The stacks of round balconies on iron brackets up the curved garden face and the street corner, a wrought iron rail on each, a half hoop over the topmost door.
2. Cream plaster over a honey-sandstone base two storeys high, with a glazed entrance hall and a glass canopy on two stone columns on Niecała.
3. The top: a zinc mansard storey set back, and over the garden's arc a pergola of timber slats on slim white columns.
4. The blank white south-west gable that stands over the Saxon Garden side.

## 2. Massing

OpenStreetMap's outline (centrum.json building 5544) simplified to 23 corners, about 45 x 45 m at its widest, with the concave garden arc (radius about 25 m) on the south side. LoD2 gives 27.4 m: sandstone base 5.0 m, six plaster storeys of 3.2 m to 24.2 m, the eave cornice, then the zinc storey 3.2 m, set back 1.9 m all round.

## 3. Facade, base to top

Base (0 to 5 m): sandstone, a ledge at its top, on Niecała dark shop-glass bays between sandstone piers and the hall at the middle of the third edge (door, two 0.42 m columns, a 2.6 m half-ellipse glass canopy at 3.9 m). Plaster storeys: on Niecała, a window every 2.9 m; round-balcony stacks only on every other edge (garden arc edges 9 and 11, the south face's 14, the street corners 17 and 22), with plain windows on the edges between and a window either side of a lone stack, as the photos run stack, windows, stack (Mac look check 2026-11-26: a stack on every edge read as one dark wall of glass); the balcony door 2.1 m tall; windows have sills and heads in a lighter sandstone. The party walls (north-east end, back) and the south-west gable stay plain cream (the photos show them blank). The gable is a firewall: it rises past the set-back zinc storey to a coping 0.9 m over its roof (Nemo5576's photo).

Green (F's photos, 2026-11-26): ivy climbs the plaster beside the garden-side stacks from the ground, a different height per stack, and about two balconies in three carry a box of red geraniums on the rail. Each balcony has two slim cream posts up to the bowl above, and the top one an iron half-hoop.

## 4. Roof

Flat. The terrace deck round the zinc storey is pale concrete; the zinc storey has a flat roof in lighter zinc and three chimney stacks. Over the arc's edges the pergola: slim columns every 1.9 m, an iron rail and timber slats every 0.9 m running back over the setback (ortho: the pergola's slatted arc and its garden court).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #eadfc5 | M_STONE |
| Sandstone base, balcony slabs | #c9a56c, trim #dcc08a | M_STONE |
| Zinc storey | #656d74, roof #7c8388 | M_STONE |
| Iron rails | #56606b | M_STONE |
| Pergola slats, door | #9a6a3c | M_STONE |
| Glass | #2c3640 | M_PANE (kit windows, lit by chance at night) |

No new material, no new draw call.

## 6. Ground and night

The pavement and the parked cars are the map's. The garden court and the lawn behind the arc are not built in this pass. Rooms light through the kit's windows (lit by chance); the canopy is dark glass.

## 7. Detail level and budget

L3, triangle budget 13000, an exception to the L3 limit of 8000 (the stacked round balconies are the building's identity; 8000 at first; raised the same day for the balconies, the ivy and the geranium boxes of F's photos) (`check_mesh_quality.gd`).

Shots: turntable `tools/turntable.sh niecala7`; `--at=-1043,-892 --yaw=40 --pitch=-25 --size=70` (from Niecała, photo fotopolska 340543), `--at=-1040,-880 --yaw=200 --pitch=-20 --size=70` (the garden arc, photos of the developer's gallery).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | prisms on the 23-corner outline | 45 x 45 m, 27.4 m | the outline | M_STONE | 2 base and plaster |
| cornices | ledge ring and cornice ring | 0.4 m | y 5.0 and 24.2 | M_STONE | 2 base and plaster |
| windows | kit windows, sill and head | 1.1 x 1.7 m | every storey, every windowed edge | M_PANE | 2 base and plaster |
| shop_bays | dark glass bays | 1.7 x 3.7 m | Niecała ground floor | M_PANE | 2 hall |
| entrance | door, two columns, half-ellipse canopy | 2.2 x 3.6 m, canopy 5.2 m | Niecała, third edge | M_STONE | 2 hall |
| balconies | half-ellipse cream bowl and light iron rail | 2.5 m wide, 1.45 m deep | edges 9, 11, 14, 17, 22, every storey | M_STONE | 1 balconies |
| zinc_storey | inset prism, flat roof | 3.2 m high | y 24.6 to 27.8 | M_STONE | 3 top |
| pergola | columns, rail, slats | 0.28 m columns, 2.7 m tall | the garden arc, top terrace | M_STONE | 3 top |
| chimneys | four-sided stacks | 1.1 m, 2 m high | the zinc roof | M_STONE | 3 top |
| gable | plain cream wall, rising past the zinc storey | 9.9 m wide, to 28.7 m | the south-west end | M_STONE | 4 gable |
