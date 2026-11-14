# Klasztor Ojców Kapucynów (the Capuchin monastery), Miodowa 13: spec

Site key `church_kapucyni_klasztor` in `game/scripts/landmarks.gd` (`_find_churches` finds it by
the OSM outline under `at`, `_build_church` hands it to `_build_kapucyni_klasztor`): the
monastery beside the Capuchin church (`church_kapucyni`) as one model that replaces the plain
OpenStreetMap block (building 821). Its area is in `tools/bake_sectors.py` SITE_AREAS. Written
2026-11-14 from 12 Commons photos (refs/churches/capuchins_miodowa: 06-09 and 11 show the
monastery from Kapucyńska and the W-Z route; reference only, never shipped), the OSM outline and
GUGiK's LoD2.

## 1. Identity
1. **Three-storey pale yellow ranges** round a courtyard.
2. **Hipped green copper roofs**, one per range.
3. Plain rows of windows and a white cornice.

## 2. Massing
The outline (33 points) is a C round the courtyard, open to the north-east where the church's
sacristy closes it. The ranges stand at three angles, so each roof has its own frame. Heights over g.

| Part | Frame | Plan (u, v) | Height over g |
| --- | --- | --- | --- |
| walls | — | the whole outline | eaves 11.5 |
| north range roof | KK_O1 (-1025.7, -1410.4), axis (0.8453, -0.5343) | u -0.2..35.7, v -0.2..9.2 | hip, rise 4.2 |
| west block roof | KK_O1 | u -10.4..0.2, v -5.05..9.15 | hip, rise 4.6 |
| east range roof | KK_O2 (-990.3, -1383.3), axis (0.6097, -0.7926) | u -0.15..26.05, v -11.1..0.1 | hip, rise 4.2 |
| south range roof | KK_O3 (-1018.4, -1397.6), axis (0.8912, 0.4535) | u -0.15..31.65, v -10.6..0.4 | hip, rise 4.2 |

## 3. Facade: Kapucyńska and the W-Z side
Pale yellow plaster, a white plinth band to 0.6 m over the ground, three floors of windows
(sills at 1.2, 4.8 and 8.3, 1.1 x 1.8 m) about every 3 m on every wall at least 3 m long, a white
cornice under the eaves.

## 4. The other sides
The courtyard walls have the same windows (defaults: no photo looks into the courtyard).

## 5. Roof
Green copper (#86a993), a hip over each range; where two ranges meet, the hips cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ecdcae | M_STONE |
| Cornice, plinth | #f1ece0 | M_STONE |
| Roof | #86a993 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor Kapucynów". No floodlights.

## 8. Detail level and budget
L1, triangle budget 900 (measured 797, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_kapucyni_klasztor`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 11.5 m | — | #ecdcae | cornice, plinth |
| roofs | 4 hips | 36 x 9, 10.6 x 14, 26 x 11, 32 x 11 m | the ranges | #86a993 | — |
| windows | panes | 1.1 x 1.8 m | every wall | PAL_GLASS_DARK | 3 floors |
