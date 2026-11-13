# Kościół Świętego Aleksandra (St Alexander's church): spec

Site key `aleksander` in `game/scripts/landmarks.gd` (`_find_aleksander`, `_build_aleksander`).
First written 2026-11-01 in a cloud thread from the OpenStreetMap outline alone. **Rebuilt
2026-11-13** (churches review order 2) from nine Mapillary photos of 2019-2026 (`refs/aleksander`,
never committed or shipped; the best: the south portico from Plac Trzech Krzyży's east side, the
drum close up, a 2026 panorama from the south) and the GUGiK LoD2 roof heights in the map pack.

## 1. Identity

Chrystian Piotr Aigner's church of 1818-1825, a rotunda in the manner of the Pantheon in the
middle of Plac Trzech Krzyży at the head of Nowy Świat. Given two towers in the 1890s, burnt in
1944, rebuilt after the war in Aigner's form, without the towers. What makes it read as itself:

1. **A tall, blank cream drum** (no windows at all on the lower drum) on a stepped stone podium.
2. **A lower, set-back upper drum** where round-headed windows alternate with blind arched niches.
3. **A low green copper dome** with only a small cross on top (no lantern).
4. **A portico of six white Corinthian columns** under a pediment with a cross, on both ends of
   the long axis (north to Nowy Świat, south to the square).

## 2. Massing

Centre (-110.8, 541.7), long axis (-0.232, -0.973), u to the north, +v east. The lower drum is a
circle fitted to the outline's arcs, radius 11.3 m; the porticoes are 12.8 m wide and reach
u = 18.0 (north) and -17.4 (south), as the outline maps them. Heights above the street, from
LoD2 (eaves ring 13.8 m, upper drum's roof 18.9 m, dome apex 25.7 m) and the photos' proportions:

| Part | Height |
| --- | --- |
| podium (a step to 0.4 m, platform) | 0.8 m |
| portico floor | 1.4 m |
| lower drum wall, string course at 9.7 m | to 11.0 m |
| dentilled cornice (two tiers, in line with the porticoes' entablature) | 11.0 to 11.9 m |
| set-back band and cap | to 13.8 m |
| upper drum (r 10.2) and its cornice | 13.8 to 18.9 m |
| attic ring (r 9.6) | to 20.0 m |
| dome apex | 25.0 m |
| cross on the dome | to 28.2 m |
| columns (with capitals) | 1.4 to 9.9 m |
| entablature | 9.9 to 11.9 m |
| pediment apex | 15.2 m |

## 3. Facade, base to top

- **Podium**: granite grey, one step all round 2.3 m out from the drum, the platform 1.4 m out.
  In front of each portico three steps down to the square.
- **Lower drum**: a plinth band, then smooth cream plaster with nothing on it (the photos show
  no windows), a thin white string course near the top, a white dentilled cornice in two tiers.
- **Set-back band**: plain plaster under a small cap (the LoD2 eaves ring).
- **Upper drum**: 24 faces lined up with the axis. The 10 even faces off the axis carry a
  round-headed window (white surround, dark glass, 1.44 m wide); the 12 odd faces a blind arched
  niche a shade darker than the wall. The two faces on the axis are left plain: the pediments
  stand in front of them. Then a white cornice.
- **Porticoes**: six columns across (centres at v ±1.15, ±3.45, ±5.75), one more on each side
  2.3 m behind the corner ones, antae at the cella front's corners. Each column: square plinth,
  eight-sided tapering shaft, a flared Corinthian capital, a square abacus. White architrave and
  frieze, a cornice over them, the pediment (cream tympanum) and a dark cross on its apex.
- **Cella**: a block from the drum to the cella front, 4.8 m behind the columns' front; a big
  door (2.6 x 5.9 m) in a white surround and a smaller door either side; two small windows, one
  over the other, in each side wall of the block (seen in the photos).

## 4. Roof

The dome in six steps of green copper, lighter toward the top, closed by a cap; a dark iron
cross on a small pedestal. The porticoes' pediment roofs in a darker green copper, sloping back
to the drum.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Drum walls, cella, tympanum | #ece5d3 | M_STONE (plain: the real drum has no windows) |
| Columns, cornices, surrounds | #f5f1e6 | M_STONE |
| Blind niches | #ddd5c1 | M_STONE |
| Plinth band | #b9b2a3 | M_STONE |
| Podium, steps, portico floor | #a5a197 | M_STONE |
| Dome | #6a9f86 to 15 % lighter | M_STONE |
| Portico roofs | #5f8a76 | M_STONE |
| Windows | #3a3f42 | M_GLASS |
| Doors | #4a3b31 | M_GLASS |
| Crosses | #3f4240 | M_STONE |

No new material, shader instruction or draw call: the old model used M_MONUMENT, M_STONE and
M_GLASS; the new one drops M_MONUMENT (whose painted windows the real drum doesn't have).

## 6. Ground and night

The car is stopped by one ring: the podium's outer step joined with both porticoes and their
steps. The church stands on its own pedestrian island, so the podium touches no road. Card:
"Kościół Świętego Aleksandra", PL "Rotunda Aignera z lat 1818-1825 z dwoma portykami; po wojnie
odbudowana bez dawnych wież.", EN "Aigner's rotunda of 1818-1825 with two porticoes; rebuilt
after the war without its later towers." Windows are plain dark glass, not lit.

## 7. Detail level and budget

L2, triangle budget 2550 (measured 2316, plus about 10 %; `check_mesh_quality.gd`). Shots:
`--solo=aleksander --solo-look=lit`, then in the city from Nowy Świat and from the square's
east side, on both city paths.

Open photo checks (no photo reached): the north portico is assumed the same as the south one;
the portico roofs' colour (assumed copper green); the true dome curve (LoD2 is coarse).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| podium | two 24-gon prisms | r 13.6 and 12.7, to 0.8 m | centre | M_STONE | 3 podium |
| plinth | 24-gon prism | r 11.45, 1 m | on the podium | M_STONE | 3 drum |
| drum | 24-gon prism | r 11.3, to 11 m | centre | M_STONE | 1 blank drum |
| string | 24-gon band | r 11.38, 0.25 m | y 9.7 | M_STONE | 3 drum |
| cornice | two 24-gon prisms | r 11.55 and 11.85 | y 11.0..11.9 | M_STONE | 3 cornice |
| band | 24-gon prism and cap | r 11.0 | y 11.9..13.8 | M_STONE | 3 band |
| upper drum | 24-gon prism | r 10.2 | y 13.8..18.0 | M_STONE | 2 upper drum |
| windows | 10 arch panels + surrounds | 1.44 x 2.4 m | even faces | M_GLASS | 2 upper drum |
| niches | 12 arch panels | 1.6 x 2.6 m | odd faces | M_STONE | 2 upper drum |
| upper cornice | 24-gon prism | r 10.65 | y 18.0..18.9 | M_STONE | 2 upper drum |
| attic | 24-gon prism | r 9.6 | y 18.9..20.0 | M_STONE | 3 dome |
| dome | 6 frustums | r 9.6 to 0.7 | y 20.0..25.0 | M_STONE | 3 dome |
| cross | pedestal + 2 boxes | 3.3 m | y 24.9..28.2 | M_STONE | 3 dome |
| cella | box | 12.2 m wide | each end | M_STONE | 4 porticoes |
| floor and steps | 4 boxes | 13.4 m wide | each end | M_STONE | 4 porticoes |
| columns | 8 Corinthian columns | r 0.46, 8.5 m | each end | M_STONE | 4 porticoes |
| antae | 2 boxes | 0.4 x 0.9 m | cella corners | M_STONE | 4 porticoes |
| entablature | 2 boxes | 13.4 m wide | y 9.9..11.9 | M_STONE | 4 porticoes |
| pediment | gable | rise 3.3 m | y 11.9 | M_STONE | 4 porticoes |
| doors | 3 panels + surround | 2.6 x 5.9 m and 1.2 x 3.2 m | cella front | M_GLASS | 4 porticoes |
| side windows | 4 panels | 0.7 x 1.1 m | cella sides | M_GLASS | 4 porticoes |
| pediment cross | 2 boxes | 1.7 m | apex | M_STONE | 4 porticoes |
