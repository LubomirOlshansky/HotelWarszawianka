# Kościół Jezuitów (Sanktuarium Matki Bożej Łaskawej): spec

Site key `jezuici` in `game/scripts/landmarks.gd` (`_build_jezuici`; the mass is the skin
`jezuici`, the model is what the eye reads on it). Written 2026-11-13 (churches review, Old Town
set), rebuilt the same day from F's four photos (the stepped front by day and by night from the
side, the front looking up, the tower's helm), two Mapillary street photos (`refs/jezuici`, never
committed or shipped) and the GUGiK LoD2 heights in the map pack.

## 1. Identity

The Jesuit church of 1609-1626 on Świętojańska 10, next to the Cathedral, its front to the
south-west, to the street. What makes it read as itself:

1. **A stepped baroque front in dusty pink with cream pilasters**: a tall tier of giant pilasters
   with carved capitals, then three narrower tiers, scroll buttresses between them, cream
   pinnacles with gold balls and a gold cross.
2. **A low wing at the street end** with a statue niche, forward of the main front.
3. **A tall tower** behind, a decagon with cream corner pilasters and arched openings, a green
   copper helm, a lantern and an onion cap with a gold ball and cross; a smaller green turret on the roof.

## 2. Massing

Frame: origin (-764.2, -1648.3) (the wing's NW corner), u along the street to the south-east
(axis (0.685, 0.729)), +v out to the street. LoD2 heights above the ground: the wing's eaves
14.0 m (u 0.4 to 7.7, v 0); the main front at v -4.5, u 7.9 to 20.8, wall to 22.8 m, gable apex
33.6 m (u 14.35); the tower a decagon r 3.2 at u 6.3, v -32 (walls from 20 m, ring 45 m, tip
56 m); the roof turret at u 13.2, v -32.1 (base 29 m, tip 38 m); the side wall at u 19.9 with
0.5 m pilaster bumps every 6 m.

## 3. Facade

Front (kit parts on a pink wall slab): plinth 1.1 m; tier 1 (12.9 m wide, to 14 m): four pilasters
1.0 m wide (u 14.35 +- 2.35 and 5.95) with carved capital blocks, a string course at 6.6 m,
framed windows below and arched ones above in the side bays, an arched portal (4.6 m) under a
small pediment and a tall pedimented window over it, a cornice; tier 2 (8.2 m, to 22.4 m): two
pilasters, an arched window, a cornice; tier 3 (5.2 m, to 28.4 m): two pilasters, a window, a
cornice; tier 4 (3.2 m, to 33.2 m): a small window and a pediment with a cross. Scroll
buttresses (three steps each side of tier 2, two of tier 3, one of tier 4), pinnacles with gold
balls on the cornices.
Wing: plinth, two pilasters, a door, a framed window, a statue niche over it, an arched window, a cornice.
Side wall (20 m toward the Cathedral): four pilasters on the outline's bumps, three tall framed windows, a cornice at 15 m.
Tower: a pink shaft inside the LoD2 walls (so it stands in the flat check), ten cream corner
pilasters, a string course at 33 m, ten arched openings (35.8 to 40.6 m), a double cornice at 44 m.

## 4. Roof

The green copper helm: a flared lip, a waist, a cream lantern with four dark openings, an onion
cap, a gold ball and cross (to 59 m); the turret in the same green with a cream lantern and a
cross. The nave roof stays LoD2's (skin roof dark grey-brown, as in the photos).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster (front, wing, side wall, tower) | #dd8f82 (F's day photos, the skin's wall colour) | M_STONE |
| Pilasters, cornices, surrounds, statue | #efe6d2 | M_STONE |
| Plinth | #a8a49c (PAL_GREY_STONE) | M_STONE |
| Windows, tower openings | #323a40 (PAL_GLASS_DARK) | M_PANE / M_GLASS |
| Portal and door leaves | #5e432f (PAL_OAK) | M_STONE |
| Pediment slopes, nave roof | #6a4d44 | M_STONE |
| Helm, cap, turret | #6f9a8a (PAL_PATINA_COPPER) | M_STONE |
| Balls, crosses | #c9a24c (PAL_GOLD) | M_STONE |

No new material, shader instruction or draw call.

## 6. Ground and night

The model stands on the LoD2 mass's own collision; it adds none. Card kept: "Kościół Jezuitów".
Windows are the kit's `M_PANE`, lit by chance at night (F's night photo shows the front floodlit
warm and the arched windows glowing: floodlights are not built).

## 7. Detail level and budget

L3, triangle budget 2900 (measured 2585; `check_mesh_quality.gd`). Shots: the turntable
(`tools/turntable.sh jezuici`), then in the city `--at=-758,-1640 --yaw=313 --pitch=-35 --size=45
--no-ghost`, on both city paths.
Open photo checks: the volute shapes are stepped boxes, not curves; the portal's pediment is a
triangle (segmental in the photos); the nave's east side beyond 24 m and the apse stay LoD2's;
the tower's bell stage has ten identical openings (the photos show pairs between pilasters).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front wall | 4 kit_wall slabs | 12.9 m down to 3.2 m, 33.5 m | v -4.47 | M_STONE | 1 front |
| pilasters | 4 + 2 + 2 kit_pilaster and capital blocks | 0.7 to 1.0 m | tiers 1 to 3 | M_STONE | 1 front |
| cornices | 4 kit_cornice, string course | 12.9 to 5.2 m | 6.6, 14, 22.4, 28.4 m | M_STONE | 1 front |
| windows and portal | 8 kit_window, kit_door arched | 1.1 to 1.8 m wide | all tiers | M_PANE | 1 front |
| scrolls and pinnacles | 11 stepped boxes, 6 pinnacles | to 2.2 m | between tiers | M_STONE | 1 front |
| pediment and cross | kit_pediment, 2 boxes | 3.6 m, 3 m | 33.2 m | M_STONE | 1 front |
| wing | wall, plinth, 2 pilasters, cornice, door, window, niche, statue | 7.3 x 13.6 m | v 0.03 | M_STONE | 2 wing |
| side wall | wall, plinth, 4 pilasters, 3 windows, cornice | 20 x 15 m | u 19.93 | M_STONE | 1 front |
| tower | shaft, 10 pilasters, 3 rings, 10 arched openings | r 3.2, 45 m | u 6.3, v -32 | M_STONE | 3 tower |
| helm | 3 frustums, lantern, cap, ball, cross | r 3.55 to 0.3 | 45 to 59 m | M_STONE | 3 tower |
| turret | shaft, 2 frustums, lantern, cap, ball, cross | r 3.3 to 0.3 | u 13.2 | M_STONE | 3 tower |
