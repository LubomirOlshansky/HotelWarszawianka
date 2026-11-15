# Dom Prowincjalny Sióstr Elżbietanek (the Elizabethan sisters' provincial house, behind Piekarska): spec

**Provisional, no photo** (2026-11-15). Built from LoD2 and the OSM outline only: no photo shows this range, so the plaster, the roofs and the rounded end are defaults until one does (docs/QUESTIONS.md).

Site key `elzbietanki` in `game/scripts/landmarks.gd` (found by the OSM outline under `ELZ_AT`,
the building OSM names "Dom Prowincjalny Sióstr Elżbietanek"; its area is in
`tools/bake_sectors.py` SITE_AREAS). It stands inside the block between Piekarska, Piwna and
Podwale, behind St Martin's, its long side over the Podwale gardens and the city wall. F's 12
Commons photos (refs/churches/elzbietanki_piekarska, reference only, never shipped) show
Piekarska's street fronts (nos. 2 to 6) and the corner by Kiliński, not this range.

## 1. Identity
1. A **two-storey range** along the Podwale gardens, with a **taller block** at its west end.
2. A **rounded east end** (read as the chapel's apse, a default) towards St Martin's.

## 2. Massing
LoD2's mass kept: the range eaves about 8.5 m over the ground, ridge 11; the west block 14; a
lean-to arm to the north. LoD2 has nothing over the rounded end, so it is ours: a drum r 2.9 m
round (-821.5, -1587.1) to g+7.6, a white cornice, a cone to g+10.6 (its inner half is hidden in
LoD2's mass).

## 3. Facade
LoD2's walls in pale ochre plaster, the windows are the skin's. On the rounded end: a white plinth
and two rows of three narrow windows (g+1.4, g+4.6).

## 4. The other sides
As section 3.

## 5. Roof
LoD2's roofs in red tiles (a default, as the Old Town's); the rounded end's cone in the same tiles
with a small iron cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e2cfa6 (a default) | skin (M_MONUMENT); the rounded end M_STONE |
| Cornice, plinth | #f1ebdd | M_STONE |
| Roofs | #a4553f (a default) | skin; the cone M_STONE |
| Cross | #2a2a2c | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision (the house is inside the block, off the roads). Card: "Siostry Elżbietanki". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 400 (measured 144, the rounded end only, `check_mesh_quality.gd`). Shots: the
city shot from the Podwale gardens (the turntable shows only the rounded end).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the outline | — | skin | ochre and red tiles |
| rounded end | drum, cornice, cone | r 2.9 m, 10.6 m | the east end | M_STONE | 6 windows, cross |
