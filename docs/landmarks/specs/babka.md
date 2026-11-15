# Babka Tower (Rondo Zgrupowania AK "Radosław"): spec

Site key `babka` (a TOWERS entry, new 2026-11-15; `_babka` in `game/scripts/landmarks/skyline.gd`).
Written 2026-11-15 in a cloud thread from F's six photos in
`refs/_f/warsaw-needed-photos/top-50/T42/` (reference only, never shipped): the tower over the
roundabout from the south (three), from the east over the flats block (two), and from the Palace's
terrace. Massing from the one OpenStreetMap part "Babka Tower" in `centrum.json` (96 m), unchanged;
the seven-storey flats block that wraps it (34 m) stays the map's own building.

## 1. Identity

1. The north's tallest flats tower (2000): a slim white slab in a fine grid of loggias and
   windows, over a base of grey office glass (photos 1 to 4).
2. Its corner bays are glazed in blue glass from the base to under the crown (1, 2, 4).
3. A white ledge where the offices end and the flats begin, at about 31 m (1, 2).
4. A white crown band with the cable firm's name and a small mast on the roof (all).

## 2. Massing (the mapped part)

One part, 0 to 96 m: a slab about 24 by 40 m with its corners stepped in (fifteen corners). The
flats block (34 m) and the low wings round the roundabout are the map's.

## 3. Facade, base to top

- **Offices**: grey glass (#5d6f7e, M_GLASS: mullions, lit rooms at night) 0.12 m proud of the
  shaft, from the ground to 31 m.
- **Ledge**: a white slab (#eceae4) 0.9 m out and 0.6 m deep at 31 m, its underside shaded.
- **Flats**: the kit's slab skin (S_SLAB, plaster and loggia bands) in #e3e2dc from 31 m up.
- **Corner glass**: blue glass (#5e86ad, M_GLASS) 2 m wide at both ends of every face longer
  than 6 m, 6 cm proud, from the ledge to 4 m under the roof.
- **Crown**: a white band (#eceae4) over the top 4 m, 0.1 m proud, the parody name WEKTRA lit on
  it.

## 4. Roof

Flat, #9b9794 (mapped). A white mast 9 m tall in the middle with a red band and the red lamp on
top.

## 5. Colour and material

Shaft #e3e2dc (S_SLAB); office glass #5d6f7e and corner glass #5e86ad (M_GLASS); ledge and crown
#eceae4 (building material); roof #9b9794; mast band #c8322b; lamp DUSK_RED (M_LAMP); the name in
DUSK_WARM. No new material.

## 6. Ground and night

The roundabout, the tram tracks and the flats block are the map's. Car collision on the mapped
part. Night: the offices' and the corner bays' rooms lit (M_GLASS), the name on the crown, the
mast's red lamp and the aviation lights.

## 7. Detail level and budget

L1 (a tower at the map's north edge, seen from Jana Pawła II and the Palace). 287 triangles,
budget 400 (check_mesh_quality BUDGET "babka"); 0 z-fights; no draw call, no shader change
(building.gdshader stays 501 of 505).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | prism | mapped, 0 to 96 m | the mapped part | S_SLAB #e3e2dc | 1 white loggia slab |
| offices | prism | ring + 0.12 m, to 31 m | the shaft's base | M_GLASS #5d6f7e | 1 office base |
| ledge | prism + soffit | ring + 0.9 m, 0.6 m | 31 m | #eceae4 | 3 ledge |
| corner glass | walls | 2 m wide | both ends of each face over 6 m, 31.6 to 92 m | M_GLASS #5e86ad | 2 glazed corners |
| crown | prism | ring + 0.1 m, 4 m | 92 to 96 m | #eceae4 | 4 crown band |
| name | dusk sign | the crown's height | the crown, S and E | DUSK_WARM | 4 name |
| mast | prisms | 0.8 m, 9 m | roof middle | #c9c7c2, band #c8322b | 4 mast |
| lamp | box | 0.4 m | mast head | DUSK_RED (M_LAMP) | 4 mast |

## 9. Not built, and what only the phone can show

- The loggias' glass balustrades and the roof terrace's planting at the ledge (photo 1).
- The flats block round the tower stays the map's plain building (a pass of its own).
- Phone: the corner glass reading at the game's zoom; the name at night.
