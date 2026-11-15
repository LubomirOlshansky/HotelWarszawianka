# Dom Generalny Zgromadzenia Sióstr Sług Jezusa (the Servants of Jesus' generalate): spec

Written 2026-11-15 from two Mapillary photos up the street (2020, refs/churches/sluzki_dom_generalny,
CC BY-SA, reference only, never shipped), the OSM outline and GUGiK's LoD2. The roof and the yard
wing are seen by no photo, so they are defaults until one arrives (docs/QUESTIONS.md).

Site key `church_sluzki_dom_generalny` in `game/scripts/landmarks/churches.gd` (`_find_churches`
finds it by the OSM outline under `at`, `_build_church` hands it to `_build_sluzki_dom_generalny`):
one model that replaces the plain OpenStreetMap block (building 835, tagged `apartments`, named
"Dom Generalny Zgromadzenia Sługi Jezusa"). Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **six-storey house in ochre plaster** along its street, an L with a wing into the yard.
2. **Tall windows in even rows**, a light band over the ground floor, the **entrance under a small
   metal canopy** near the south corner.

## 2. Massing
Frame: origin (-206.4, -500.9), the front's south corner; u along (-0.400, -0.917) to the
north-north-west along the street, v to the east-north-east into the block. Heights over g (LoD2;
g about 6.2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u 0..28.5, v 0..29.6) | eaves 19.5 |
| range on the street | u 0..28.3, v 0..17.7 | hip ridge 23 |
| yard wing | u 18.9..28.5, v 14.8..29.6 | hip ridge 22.5 |

## 3. Facade (the street, -v)
Window columns every 2.9 m, five rows of tall windows (g+1.3, 4.7, 8.0, 11.3, 14.6) and a lower
attic row (g+17.4); a light band at g+3.6, a cornice under the eaves, a darker plinth; the door
near the south corner under a dark metal canopy.

## 4. The other sides
As section 3 on every wall (defaults: no photo of the yard).

## 5. Roof
Hipped, grey sheet (#6b6c6c, a default), one hip per range.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e3c48e (photos) | M_STONE |
| Bands, cornice | #efe2c4 | M_STONE |
| Roof | #6b6c6c (a default) | M_STONE |
| Door | #5a4632 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Dom Generalny Sióstr Sług Jezusa". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1200 (measured 798, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_sluzki_dom_generalny`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 19.5 m | — | #e3c48e | cornice and plinth rings |
| roofs | 2 hips | per range | over the ranges | #6b6c6c | — |
| entrance | kit door + canopy | 1.5 x 2.6 m | near the south corner | #5a4632 | metal canopy |
