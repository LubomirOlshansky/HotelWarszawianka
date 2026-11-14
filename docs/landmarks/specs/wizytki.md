# Kościół Wizytek (the Visitationists' church), Krakowskie Przedmieście 34: spec

Site key `wizytki` in `game/scripts/landmarks.gd` (`_find_skins` finds it; its SKINS entry has
`model`, so the model replaces the church's LoD2 inside the OSM outline; `_build_wizytki`). Rebuilt
2026-11-14 as the whole building from F's straight-on photo of the front and his close-up of the
turret (refs `_f/warsaw-needed-photos/top-50/T29`), 14 Panoramax views from the street and the
square in front (2024, refs/wizytki_far, never shipped) and GUGiK's LoD2. Mapillary had nothing
facing it; Commons is blocked from the cloud.

The 2026-11-01 model (566 tris on the kept LoD2 skin) had put the front on the east end, facing
away from the street. The outline's toothed end (the column pairs) and every photo put it on the
west end, facing Krakowskie Przedmieście, the square and Cardinal Wyszyński's statue.

## 1. Identity
Late-baroque church of the Visitation nuns (Karol Bay 1728-1733; the front by Ephraim Schröger,
1756-1761), one of the few in the centre that came through 1944 whole. What makes it read as itself:
1. The **cream two-storey front** facing the street: a lower order of six pairs of Corinthian
   columns over the whole width, an upper order of four pairs, **concave sweeps with urns** on
   both storeys, and a **crown** with a statue group in a niche, saints on the cornice and angels
   on scrolled corners, a ball and a cross. No towers.
2. A **steep red tile roof** over a tall cream nave behind it (the front's crown hides the ridge).
3. A small **green copper turret** on the ridge: an open arched stage, a bell cap, an onion.

## 2. Massing
Frame: origin (-474.2, -782.6) at the front's middle on the main wall line, u along the front
(axis (-0.527, -0.850), +u north), +v into the church (east-north-east). The front is built in the
swapped frame (u' = 12.1 - u, v' = -v). Heights over the ground in front (LoD2 matches the photo
scaled to the outline's 24.2 m width when the ground is the terrain's, 9.1 m; LoD2's own base
sits lower).
- Front: lower storey 24.2 m wide, cornice 9.4 m; a forward block 16.4 m wide carries the middle
  four pairs to the upper cornice at 18.5 m; crown 8.6 m wide to 23.0, its middle pedestal to 25.3,
  the cross to 27.5 m (LoD2 34.4 abs = 25.3 over the ground).
- Aisles (chapels) u -11.2 to 11.0, v 0 to 35, cornice 9.6 m, lean-to roofs up to 11.4 m; the
  north chapel's bump (u 10.4 to 12.6, v 26.2 to 30.8).
- Nave 14.4 m wide (u ±7.2), v 0 to 35, eaves 18.6 m, ridge 25.2 m, hip from v 28 to 35.5.
- Chancel v 35 to 48.4, walls 9.4 m, its own roof along the axis, ridge 14 m.
- South wing u -19.9 to -11.2, v 22 to 36, walls 10.8 m, hip to 15.2 m.
- Turret on the ridge at v 29.5 (where the hip starts); its foot inside the roof, the open stage
  25.0 to 27.6 m, the cross to 34.7 m.

## 3. Facade
From F's straight-on photo (scale 1.77 cm per pixel at 1920 px):
- Plinth to 1.1 m. Lower columns at u' ±2.2, ±3.2, ±6.4, ±7.4 (on the forward block) and ±10.6,
  ±11.6 (on the back plane), 1.1 to 7.4 m, Corinthian, r 0.4; entablature 7.4 to 8.9, cornice to
  9.4, breaking forward over the block.
- Blind arched niches at ±4.8 and ±9.0 (2.4 to 5.7 m) with medallions over them at 6.55 m.
- The middle bay: the iron-black door (1.9 x 3.0 m) in a frame, a stone balcony at 4.3 m, an arched
  window over it, a cartouche.
- Pedestals over the lower cornice; two urns at each end (±10.6, ±11.6); the lower concave sweeps
  from the upper storey's side (8.2 m out, 13.4 m up) down to the urn pedestals.
- Upper columns at ±2.2, ±3.2, ±6.4, ±7.4 (10.3 to 16.8 m, r 0.36); bishops in arched niches at
  ±4.8 with relief medallions over them; the great arched window (1.6 x 3.4 m) at 10.9 m with a hood
  and a cartouche; entablature to 18.0, cornice to 18.5; a low pediment over the middle.
- On the cornice: urns at ±6.4 and ±7.4, saints at ±2.0 and ±3.4.
- Crown: the upper sweeps from ±6.3 at 18.5 to ±4.3 at 22.0, four pilasters, the niche with the
  two-figure group (the Visitation), a cornice at 23.0, scrolled corners at ±3.5 with angels, the
  middle pedestal, a gilt ball and the iron cross.

## 4. Roof
Red tile (#a3553f) on the nave (gable at the front, hidden behind the crown; hip at the east), the
aisles' lean-tos, the chancel and the south wing (hip). The turret is green copper (#5f9884): an
octagonal foot, four corner piers round a dark open stage, a flared eave, a bell cap, a neck, an
onion, a small lantern, a gilt ball and an iron cross (F's close-up photo).

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #ead9b8 | M_STONE |
| Columns, cornices, surrounds | #f3e9d4 | M_STONE |
| Niches, reliefs | #d9c6a2 | M_STONE |
| Plinths | #bdb19a | M_STONE |
| Roofs | #a3553f | M_STONE |
| Turret | #5f9884 | M_STONE |
| Door | #2c2d2f | M_STONE |
| Windows | PAL_GLASS_DARK | M_PANE (lit by chance) |
| Statues | PAL_GREY_STONE | M_STONE |

No new material or draw call.

## 6. Ground and night
The car meets the outline (the column teeth included). The card is unchanged. Night: the windows
light by chance like every kit window; no floodlights.

## 7. Detail level and budget
L3, triangle budget 3600 (measured 3248, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
wizytki`, in the city `--at=-457,-793 --yaw=Y --pitch=-28 --size=70`.
Open photo checks: the chancel and the south wing (no photo of the back; LoD2 only), the turret's
place along the ridge (built where the hip starts; F's close-up shows it right behind the front's
sweep, so it may stand nearer the front), the side windows' count, the reliefs.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| aisles | prism, plinth, cornice ring | 22.2 x 35 m, 9.6 m | v 0 to 35 | M_STONE | 2 massing |
| lean-tos | 2 quads | 4 x 35 m | over the aisles | M_STONE | 2 roof |
| nave | box, cornice, gable roof, hip | 14.4 x 35 m, eaves 18.6, ridge 25.2 | u 0 | M_STONE | 2 roof |
| chancel | prism, cornice, gable roof | 21 x 13.4 m, 9.4 m, ridge 14 | v 35 to 48.4 | M_STONE | 2 massing |
| south wing | prism, cornice, hip | 8.7 x 13.9 m, 10.8 m | u -15.55, v 29 | M_STONE | 2 massing |
| sides | 8 clerestory arches, 10 lesenes, 7 aisle arches, 12 lesenes | arches 1.6 m wide, 4.4 and 4.2 m tall | nave and aisle walls | M_STONE / M_PANE | 3 sides |
| turret | foot, piers, dark stage, cap, onion, lantern, ball, cross | r 1.9 m, 22 to 34.7 m | u 0, v 29.5 | M_STONE | 1 turret |
| lower front | wall, forward block, plinth, 12 columns, entablature, cornice | 24.2 m, 9.4 m | v 0 to -2 | M_STONE | 1 front |
| lower details | 4 niches, 4 medallions, door, balcony, window, cartouche, 4 urns | niches 1.4 x 3.3 m, door 1.9 x 3.0 m, urns 1.7 m | u' ±4.8, ±9.0, middle bay, ends | M_STONE / M_PANE | 1 front |
| sweeps | 4 concave sweeps (face, back, top) | 2 m wide each | both storeys | M_STONE | 1 front |
| upper front | 8 columns, 2 niches with bishops, window, entablature, cornice, pediment | 16.4 m, to 18.5 | forward block | M_STONE / M_PANE | 1 front |
| cornice figures | 4 urns, 4 saints | urns 1.9 m, saints 2.3 m | upper cornice | M_STONE | 1 crown |
| crown | wall, 4 pilasters, niche with 2 figures, cornice, scrolls, 2 angels, pedestal, ball, cross | 8.6 m, to 27.5 | middle | M_STONE | 1 crown |
