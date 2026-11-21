# Wiadukt Markiewicza (the curved viaduct of Karowa; sites `wiadukt_markiewicza` and `szaja`)

Site key `wiadukt_markiewicza` in `game/scripts/landmarks/karowa.gd` (found by `_find_markiewicz`
from the map's Karowa pieces round the loop), with the memorial to Krzysztof "Szaya" Szaykowski as
site `szaja`. Written 2026-11-20 from F's 3 photos (the aerial of the viaduct and the loop, the
arch from the lower road, the Syrena), 39 Mapillary street photos and the 2023 orthophoto
(refs/wiadukt_markiewicza, reference only, never shipped). Built 1902-1904 to Stefan Szyller's
design (engineer Karol Sommer), sculpture by Jan Woydyga; rebuilt after 1944.

## 1. Identity
1. **A curved stone viaduct**: Karowa comes down the escarpment from Krakowskie Przedmieście,
   turns on the viaduct and passes **under itself** through two low arches to the lower road.
2. **Cream sandstone faces** on a granite plinth, pilasters at the arches, grey rendered
   spandrels, cream archivolts with keystones, a frieze and a heavy cornice.
3. **A balustrade** on both faces with **obelisk lamp posts** carrying lanterns.
4. **Woydyga's Syrena** (sword raised, shield) over the central pier on the inner face, and the
   allegorical group (Warsaw with the mural crown and the book, Labour with the cogwheel, the
   Vistula medallion, a torch) on the outer face.

## 2. Massing
A ring sector round one centre (-336, -939): the inner face at r 29.5 m over the pit in the loop,
the outer face at r 50.4 m over the lower road, from bearing 12° to 92°. The deck falls about 1 m
from west to east (-2.5 to -3.4 m); the lower road is at about -8 m, so the faces stand 4.5-5 m.
Two radial one-way passages at bearings 37.9° and 68.3°, 11.9 m wide, crown 0.85 m under the walk.

## 3. Facade, base to top
Granite plinth 0.6 m; sandstone wall; pilasters either side of each arch; impost band at the
springing; grey spandrels; cream archivolt ring 0.08 m proud with a keystone; frieze; cornice
0.35 m proud; balustrade 1.1 m (plinth, pierced panels, double-pitched rail, dies every 2.4 m).

## 4. Roof
The deck is the roof: the map's road ribbon in the middle, granite kerbs on its guard lines, the
setts by the kerbs and the paved walks out to the balustrades.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Faces, pilasters | PAL_SANDSTONE | M_STONE |
| Archivolts, bands, cornice, balustrade | PAL_CREAM_STONE | M_STONE |
| Spandrels | #b9b2a3 | M_STONE |
| Plinth | PAL_WARM_GRANITE | M_STONE |
| Vaults | #cfc4ad | M_STONE |
| Walks / setts | #b5afa4 / #8f8a83 | M_STONE |
| Figures | #d6cab0 | M_STONE |
| Lantern glass | #ffd9a0 | M_LAMP (glows at night) |

No new material: the viaduct lands in the site's existing buckets (+0 draw calls). The Royal
Route lanterns are one more MultiMesh in the one sector that had none: rendered probe (lavapipe,
1280x720) at the viaduct 143 → 145 and on the loop 138 → 140 draw calls (main +1, shadow +1).

## 6. Ground and night
map_builder.gd and city_barriers.gd leave the ring to this model (`Landmarks.mk_covers`): the
bake's deck slab and parapets, the tunnel portals and side walls, the deck's railings and lamps.
The guard lines along the roadway keep their colliders (drawn as kerbs). The bake's four retaining walls at
the passages' mouths (in the pit and along the lower road) are left out too (`mk_approach`, F
2026-11-21: an easier drive under the viaduct). Colliders: the faces and
the passages' sides (struct_wall), the balustrades (guard_deck). Karowa over the viaduct,
round the loop, through the arches and down to the bend at the escarpment's foot gets granite
setts in segmental arcs (ground shader, KR_LINE); a stone under about two pixels fades to a calm
mottle of three-stone patches so the phone shows no noise or crawl, the arcs stay and the Royal Route's cast-iron lanterns instead
of the modern street lamps (map_builder KAROWA_LANTERNS). At night the obelisk lanterns glow.

## 7. Detail level and budget
L3, triangle budget 8000 (`check_mesh_quality.gd`); the memorial L1, budget 60 (measured 36); the viaduct measured 6606. Shots:
turntable (`tools/turntable.sh wiadukt_markiewicza`), the city shots from the lower road, the
loop and the deck.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| faces | ring strips every 2° | 4.5-5 m high | r 29.5 and r 50.4 | M_STONE | sandstone on granite plinth |
| arches | segmental soffits | 11.9 m span | bearings 37.9° and 68.3° | M_STONE | cream archivolt, keystone |
| vaults | radial strips | 21 m long | the two passages | M_STONE | walks either side |
| bands | ring bands | 0.2-0.35 m | impost, frieze, cornice | M_STONE | cream |
| deck | ring strips | 21 m wide | between the faces | M_STONE | walks, setts, kerbs |
| balustrade | plinth, panels, rail, dies | 1.1 m | both faces | M_STONE | dies every 2.4 m |
| obelisks | pedestal, shaft, finial, lanterns | 4.2 m | 4 per face | M_STONE, M_LAMP | lit at night |
| syrena | pedestal, tail, body, shield, sword | 2.9 m | inner face, 53.1° | M_STONE | facing the pit |
| group | plinth, two seated figures, medallion, torch | 3 m | outer face, 53.1° | M_STONE | Warsaw and Labour |
| szaja | granite stone, bronze plaque | 1.2 m | the loop's island | M_STONE | facing the viaduct |
