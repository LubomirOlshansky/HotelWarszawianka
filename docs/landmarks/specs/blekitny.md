# Błękitny Wieżowiec (Plac Bankowy 2): spec

Site key `blekitny` (a TOWERS entry; `_blekitny_vault`, `_blekitny_roof` and `_blekitny_mast` in
`game/scripts/landmarks/skyline.gd`). Written 2026-11-15 in a cloud thread from seven photos,
reference only and never shipped: three Wikimedia Commons photos and the GUGiK ortho in the shared
store `refs/blekitny/` (1 the tower over the podium from the south-west, 2 the entrance and the
arched hall from below, 3 the side street with the hall's arched glass end) and F's three in
`refs/_f/warsaw-needed-photos/top-50/T21/` (the tower from Solidarności, at dusk, the stepped
podium). Massing from the OpenStreetMap parts in `centrum.json`, unchanged.

## 1. Identity

1. A 110 m slab of untinted reflective float glass that mirrors the sky, so it reads silver-blue
   (all photos; its first cladding was copper, the "Golden Tower").
2. One even grid of square panels over every face, no spandrel bands; the corners cut at 45
   degrees; the top 18 m set back a bay (F's T21 photos, 1).
3. A podium of stepped glass boxes, the same glass, stepping down from the tower (1, F's).
4. A glass barrel-vaulted hall on the podium's east side, its arched glass end facing the side
   street (2, 3, the ortho's glass tube).
5. On the roof a white plant box with a helipad's H inside a dark steel screen, and the antennas:
   two red and white masts and a grey pole (the ortho, F's T21 photos).

## 2. Massing (the mapped parts)

The tower part to 100 m on the podium (16.5 m), the setback crown 92.4 to 110 m, the stepped podium
parts at 10.9, 17.5, 24.1 and 30.7 m. The seven `darkslategray` strips (0 to 27.4 m) east of the
tower are the vaulted hall: built whole as one vault over their outline.

## 3. Facade, base to top

- **Glass** (#6f9cc6, M_GLASS: the shader's 1.5 m mullions and 4 m transoms, rooms lit at night)
  on the tower and every podium part.
- **The hall**: glass walls (#3d5f80) from the podium's roof (17 m) to the springing, arched glass
  ends from the ground, a half cylinder of eight glass panels to 27.4 m, a light rib (#c9d2d8,
  0.18 m) over every joint every ~3 m.

## 4. Roof

The tower's roof grey (#a99c99, mapped); a dark steel screen (#2c3136) 2.2 m tall round its edge;
a white plant box 18 by 11 by 4 m in the middle with the helipad's H on it; the podium roofs
mapped grey.

## 5. The antennas

On the box's back half: two square masts painted red and white in six bands, 22 and 17 m, each
with a red lamp, and a grey pole of 12 m.

## 6. Colour and material

Glass #6f9cc6 (M_GLASS); hall glass #3d5f80 (M_GLASS) and ribs #c9d2d8; screen #2c3136 (the kit's
frame skin); plant box #e6e8e6; masts #c8322b and #ececea; lamps DUSK_RED (M_LAMP). No new
material.

## 7. Ground and night

The square, the tram stop and the metro entrance are the map's. Car collision on the mapped parts
on the ground. Night: the rooms in the glass (M_GLASS) on the tower, the podium and the hall, the
red lamps on the masts and the aviation lights.

## 8. Detail level and budget

L2 (a tower on Plac Bankowy, seen from Solidarności and the square). 1,521 triangles, budget 1,850
(check_mesh_quality BUDGET "blekitny"); 0 z-fights; no draw call, no shader change
(building.gdshader stays 501 of 505).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tower | prisms | mapped, to 100 and 110 m | the mapped parts | M_GLASS #6f9cc6 | 1, 2 mirror slab |
| podium | prisms | mapped, 10.9 to 30.7 m | the mapped parts | M_GLASS #6f9cc6 | 3 stepped podium |
| hall walls | walls | 17 m to the springing | the strips' long sides | M_GLASS #3d5f80 | 4 vaulted hall |
| hall ends | quad + fan | the hall's width, ground to 27.4 m | the strips' two ends | M_GLASS #3d5f80 | 4 arched end |
| vault | 8 quads | r = half the width | over the strips | M_GLASS #3d5f80 | 4 barrel vault |
| ribs | beams | 0.18 m | every ~3 m along the vault | #c9d2d8 | 4 vault ribs |
| screen | prism | 2.2 m | the roof's edge | #2c3136 frame skin | 5 roof screen |
| plant box | prism | 18 x 11 x 4 m | the roof's middle | #e6e8e6 | 5 helipad box |
| H | 3 quads | 4.4 m | on the box | #2c3136 | 5 helipad |
| masts | stacked prisms | 0.7 m, 22 and 17 m | the box's back | #c8322b / #ececea | 5 antennas |
| pole | frustum | 12 m | the box's other end | #9aa0a4 | 5 antennas |

## 10. Not built, and what only the phone can show

- The white entrance portal and the name on the shaft (photo 2); the stepped podium's chamfered
  corners beyond the mapped outline.
- The masts' positions come from the ortho and two photos; their exact spots are a guess.
- Phone: the mirror glass against the sky at the game's zoom; the hall reads as a vault.
