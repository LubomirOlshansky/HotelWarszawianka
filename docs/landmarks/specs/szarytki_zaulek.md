# Domy Szarytek przy zaułku (the Sisters of Charity's two houses by Zaułek Ku Szarytkom; site `szarytki_zaulek`)

Site key `szarytki_zaulek` in `game/scripts/landmarks.gd` (found by the OSM outlines under
`SZZ_AT` in `game/scripts/landmarks/churches.gd`: buildings 2380 and 2379; its area is in
`tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from GUGiK's LoD2 and the convent's spec
(`szarytki.md`). **Provisional:** no photo shows these two houses. The street photos near them
(Mapillary 2026, refs/churches/szarytki_zaulek, reference only, never shipped) look along Tamka,
and the convent's Commons photos show the ranges round its courtyard.

## 1. Identity
1. Two **houses of the Sisters of Charity** north of their convent on Tamka, by the lane Zaułek Ku
   Szarytkom: the tall one (2380) with a **steep gable roof**, the low one (2379) east of it.
2. They read as part of the **same white house with green copper roofs** as the convent.
3. Before this site they were plain LoD2 blocks in the district's default colours.

## 2. Massing
LoD2's mass kept as it is: 2380 has eaves about 14 m and a steep ridge about 17 m over its ground;
2379 is about 8 m tall.

## 3. Facade
LoD2's walls in the convent's white plaster; the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
LoD2's roofs in the convent's dull green copper (`steep` 0.3: the steep roof keeps the roof colour).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e9e7e0 (`SZT_WALL`) | skin (M_MONUMENT) |
| Roofs | #7c9171 (`SZT_ROOF`) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision. Card: "Domy Szarytek przy zaułku". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: dormers, doors, anything a photo would have to show.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the two outlines | — | skin | white plaster, green copper roofs |
