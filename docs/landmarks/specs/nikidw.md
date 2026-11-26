# Instytut Kultury Wsi (NIKiDW, Krakowskie Przedmieście 66): spec

Site key `nikidw` (`_find_nikidw`, `_build_nikidw` in `game/scripts/landmarks/churches.gd`).
Written 2026-11-26 from Mapillary photos (refs/nikidw, local only), F's photos and the Google 3D
views of the block (refs/anna_3d). Replaces street block 43281056's front, which was stitched on
LoD2's mass (F: "the front like stitched on another front").

## 1. Identity

The long two-storey arcade on Krakowskie Przedmieście right past St Anne's: a ground floor of
rusticated piers and open round arches, the upper loggia of tall round arches between pilasters
with a balustrade in each, a cornice and a plain attic; wings behind it down the escarpment.

## 2. Massing

The OSM outline "Narodowy Instytut Kultury i Dziedzictwa Wsi" as one prism to the eave (12.3 m
over the street), its holes capped. Street frame: from the outline's north end (-680.2, -1328.7)
to its south end (-667.1, -1282.9), u south along it (47.6 m), +v out to the street. The east
wing down the escarpment and the short wing by the church in St Anne's frame.

## 3. Facade

- A front plane 0.35 m proud of the outline, foot to eave, channelled rustication on the ground
  floor (0.4..5.0 m) and a plinth band.
- 12 bays: ground arches 0.4..3.45 m spring, a cream archivolt (0.05 proud) round a shaded back
  wall (0.1 proud); a ledge at 5.1 m; upper arches 5.9..9.8 m spring with a balustrade in each.
- Pilasters between the upper arches (5.5..11.7 m), a frieze ledge at 11.7 m, the cornice at
  12.3 m.
- The wings: plain cream walls (M_STONE).

## 4. Roof

Grey hipped roofs #7d7f80 over the street range (3.4 m rise) and the short wing by the church;
the east wing down the escarpment under orange tile #b85f3e like St Anne's monastery (the 3D
top view).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #e8dcc0 | M_STONE |
| Trim, archivolts, pilasters, cornice | #f2ead8 | M_STONE |
| Loggia back walls | #b9ac92 (upper), darker by 0.22 (ground) | M_STONE |
| Street and short wing roofs | #7d7f80 | M_STONE |
| East wing roof | #b85f3e | M_STONE |

No new material or draw call.

## 6. Ground and night

The outline is solid for the car (`_collide`). No floodlight of its own; the street lamps light
it. Card "Instytut Kultury Wsi", PL "Długa arkada na Krakowskim Przedmieściu, tuż za kościołem
św. Anny.", EN "The long arcade on Krakowskie Przedmieście, right past St Anne's."

## 7. Detail level and budget

L2: 2268 triangles measured, budget 2400 (`check_mesh_quality.gd`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | outline prism | the OSM outline, to 12.3 m | world | M_STONE | 2 massing |
| front | box | 47.6 x 0.55 m, foot to eave | v -0.2..0.35 | M_STONE | 3 front |
| rustication | bands | every 0.5 m, 0.4..5.0 m | front | M_STONE | 3 ground floor |
| ground arches | 12 arch panels x 2 | half width 0.36 bay | 0.4..3.45 m spring | M_STONE | 3 arcade |
| upper arches | 12 arch panels x 2 | half width 0.34 bay | 5.9..9.8 m spring | M_STONE | 3 loggia |
| balustrades | 12 attics | 0.95 m | 5.9 m | M_STONE | 3 loggia |
| pilasters | 13 | 0.55 m wide | bay edges, 5.5..11.7 m | M_STONE | 3 loggia |
| cornice | ledge and cornice | 0.5 and 0.4 m | 11.7 and 12.3 m | M_STONE | 3 top |
| street roof | hip | 47.6 x 13.5 m, 3.4 m rise | eave | M_STONE | 4 roof |
| east wing roof | hip | 14.4 x 35 m, 3.0 m rise | St Anne's frame u 50.6, v -33.6 | M_STONE | 4 roof |
| short wing roof | hip | 11.6 x 10.6 m, 2.4 m rise | St Anne's frame u 30, v -11.45 | M_STONE | 4 roof |
