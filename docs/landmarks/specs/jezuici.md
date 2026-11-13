# Kościół Jezuitów (Sanktuarium Matki Bożej Łaskawej): spec

Site key `jezuici` in `game/scripts/landmarks.gd` (`_build_jezuici`; the mass is the skin
`jezuici`, the model is the street front). Written 2026-11-13 (churches review, Old Town set)
from two Mapillary photos of Świętojańska (2010 with the front in salmon, 2018 after the repaint
to ochre; `refs/jezuici`, never committed or shipped) and the GUGiK LoD2 heights in the map pack.

## 1. Identity

The Jesuit church of 1609-1626 on Świętojańska 10, next to the Cathedral, its front to the
south-west, to the street. What makes it read as itself:

1. **A baroque front in ochre with white flat pilasters** in a giant order, two storeys tall.
2. **A round-headed portal with a statue niche over it** and a tall triangular pediment.
3. **A wing at the street end** (the tower's base), 4.5 m forward of the main front.
4. The brick tower behind, over the roofs (kept: LoD2 mass with the skin's `upper` brick).

## 2. Massing

Frame: origin (-764.2, -1648.3) (the wing's NW corner), u along the street to the south-east
(axis (0.685, 0.729)), +v out to the street. LoD2 heights above the ground: the wing's eaves
14.0 m at v 0 (u 0.4 to 7.7); the main front at v -4.5, u 7.9 to 20.8 (12.9 m), its wall to
22.8 m and the gable apex 33.6 m over the middle (u 14.35).

## 3. Facade

Main front: a grey plinth 1.1 m, four pilasters (0.9 m wide, in two pairs at u 14.35 +- 2.35
and +- 5.95) to 20.5 m, a string course at 9.6 m, a framed window each side below (sill 2.3 m)
and a pedimented one above (sill 11.4 m); the centre bay has the arched portal (4.6 m, oak
leaf) under a small pediment, a statue niche over it (11.4 to 14.2 m) with a pale statue; a big
cornice at 20.6 m and a plain attic.
Wing: the same plinth, two pilasters, a string course at 8.6 m, two windows a storey, a cornice at 13.4 m.

## 4. Roof

A tall triangular pediment (apex 32.7 m, hw 6.4 m, the LoD2 gable's slope) over the attic, a
gold cross on it; its raking slopes in the roof tone. The nave roof stays LoD2's.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster (front, wing, pediment) | #d6a447 (the 2018 photo, the skin's wall colour) | M_STONE |
| Pilasters, cornices, surrounds, statue | #ebe8df (PAL_WHITE_STONE) | M_STONE |
| Plinth | #a8a49c (PAL_GREY_STONE) | M_STONE |
| Windows | #323a40 (PAL_GLASS_DARK) | M_PANE (kit) |
| Portal leaf | #5e432f (PAL_OAK) | M_STONE |
| Pediment slopes | #8a4a38 | M_STONE |
| Cross | #c9a24c (PAL_GOLD) | M_STONE |

No new material, shader instruction or draw call.

## 6. Ground and night

The front stands on the LoD2 mass's own collision; the model adds none. Card kept: "Kościół
Jezuitów". Windows are the kit's `M_PANE`, lit by chance at night.

## 7. Detail level and budget

L2, triangle budget 1100 (measured 844; `check_mesh_quality.gd`). Shots: `--at=-758,-1640
--yaw=313 --pitch=-35 --size=45 --no-ghost`, on both city paths.
Open photo checks: the real number of bays and the portal's pediment shape (segmental in the
2010 photo); the tower and the apse stay the LoD2 mass.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front wall | kit_wall slab | 12.9 x 22.4 m | v -4.47 | M_STONE | 3 front |
| plinth | kit_ledge | 12.9 x 1.1 m | foot | M_STONE | 3 front |
| pilasters | 4 kit_pilaster | 0.9 m, 0.8 to 20.5 m | u 14.35 +- 2.35, 5.95 | M_STONE | 1 order |
| string course | kit_ledge | 12.9 m | 9.6 m | M_STONE | 3 front |
| cornice and attic | kit_cornice, kit_attic | 12.9 m | 20.6 m | M_STONE | 3 front |
| windows | 4 + 4 kit_window | 1.1 to 1.4 m wide | side bays | M_PANE | 3 front |
| portal | kit_door arched | 2.2 x 4.6 m | u 14.35 | M_STONE | 2 portal |
| niche and statue | arch panels + box | 2.1 m wide | 11.4 to 14.4 m | M_STONE | 2 portal |
| pediment | kit_pediment | hw 6.4, 10.5 m | 22.2 m | M_STONE | 4 roof |
| cross | 2 boxes | 2.8 m | apex | M_STONE | 4 roof |
| wing | wall, plinth, 2 pilasters, string, cornice, 4 windows | 7.3 x 13.6 m | v 0.03 | M_STONE | 3 wing |
