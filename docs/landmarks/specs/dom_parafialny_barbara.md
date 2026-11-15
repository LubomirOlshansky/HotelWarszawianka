# Dom Parafialny im. Prymasa Tysiąclecia (St Barbara's parish house, Świętej Barbary; site `dom_parafialny_barbara`)

Site key `dom_parafialny_barbara` in `game/scripts/landmarks.gd` (found by the OSM outline under
`DPB_AT` in `game/scripts/landmarks/churches.gd`: building 1525; its area is in
`tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from three Mapillary photos along Świętej
Barbary (2020, refs/churches/dom_parafialny_barbara, reference only, never shipped) and GUGiK's
LoD2. The photos show the house only at a slant, behind the street's trees: pale yellow plaster, a
gate, barred ground-floor windows, a ramp with railings to a side door.

## 1. Identity
1. St Barbara's **parish house**, a **pale yellow plastered** house along the west side of Świętej
   Barbary, south of the church.
2. Before this site it was a plain LoD2 block in the district's default colours.

## 2. Massing
LoD2's mass kept as it is: a taller block at the south end (about 14 m) and a low range along the
street. The outline has 18 corners and the roofs two heights, which is why it is a skin and not a
model.

## 3. Facade
LoD2's walls in yellow plaster; the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
LoD2's roofs in a grey sheet (a default: no photo shows the roof).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6d49e | skin (M_MONUMENT) |
| Roofs | #6c6a66 (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision. Card: "Dom Parafialny im. Prymasa Tysiąclecia". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: the gate, the ramp and its railings, the barred windows.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the outline | — | skin | yellow plaster, grey roofs |
