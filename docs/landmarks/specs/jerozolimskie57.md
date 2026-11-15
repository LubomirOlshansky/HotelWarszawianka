# Aleje Jerozolimskie 57-63, the tenement row across from the Palace: spec

Site key `jerozolimskie57` (`_find_jerozolimskie57`, `_build_jerozolimskie57` and the `_jr_*` helpers in
`game/scripts/landmarks/srodmiescie.gd`). Written 2026-11-15 in a cloud thread from F's six photos of
the row (reference only, never shipped) and the five OpenStreetMap outlines. No. 57 is where the club
Nowa Jerozolima was (a multi-floor club in a former children's hospital tenement, per the Warsaw Insider page).

## 1. Where it is

The south side of Al. Jerozolimskie, the block between Emilii Plater (Centrum LIM's tower beyond it, the
"SAMSONG" mid band in the photos) and Poznańska, 148.7 m of front. The photos are taken from the Palace
side. From the east (the left in the photos): the neighbouring pale yellow tenements (not built here), then
1. the restored red tenement (no. 57), u 0 to 26.2;
2. the plain white house under a large white wrap on its roof (no. 59), u 26.2 to 70.0;
3. the white house with the arched gate and tall brown-framed windows, u 70.0 to 104.3;
4. the ornate white house with the zinc mansard at the Emilii Plater corner, u 104.3 to 148.7.
Frame: u from the east end (-1115.5, 581.2) west along the front line, v out to the street.

## 2. Plan and massing

OSM outlines 116, 117 (the ornate house), 849 (arched), 847 and 848 (plain and red) are cut into the four
houses by perpendicular party walls and built whole: the front range (13 m deep) to its eaves, the plan behind
it 2.4 m lower with a flat roof. A 2.5 m rim along the front line closes the outlines' small jogs. Eaves over the
ground: red 23.0 (ridge about 32.5), plain 18.2 (wrap to 28.6), arched 22.4, ornate 22.6 (mansard to 27.0).
The party walls are read off the photos and the OSM boundaries: 849|117 and 847|849 follow OSM; red|plain is
a guess inside outline 848 (OSM has one outline for both). Unverified.

## 3. Fronts

- **Red**: banded red ground floor and first floor (#a0463d, lighter red window frames), a red balustrade balcony
  across the left part under the white floors (pale lilac plaster #ddd8de) and another under the red top floor
  of paired piers; two white iron balconies between; red cornice; steep orange tile (#c4602f) hip roof with three
  zinc dormers and a stepped gable at the east end; a forward bay on the west side (three windows a floor,
  a big arch under it, red crown); a gabled entrance with an arched door.
- **Plain**: white, a grey rusticated ground floor of shops, fifteen axes of small framed windows on four rows,
  an arched gate at u 42.4 with an iron balcony and a tall door over it, cornice and parapet, the white wrap
  (a thin screen 10.4 m high set back 3 m, seams every 7 m).
- **Arched**: seven wide axes, brown-framed tall windows, arched on the second floor, stone balconies on the
  first, an arched gate on the middle axis, a lounge door with the sign TUTAJ (parody; invented name
  is not used).
- **Ornate**: twelve axes, hooded first floor, pedimented second, arched third, stone balconies in two long runs, pilasters at the ends,
  a coffee house with the sign PARZYBUDA (parody; no real chain), zinc mansard with six dormers and a raised box at the west end.
- **Pavement**: two green steel arcade canopies (u 50.5 to 83.5 and 110.7 to 140.7) with lit ad showcases
  (colour panels only, no text); striped red-and-white barriers and a low scaffold at the red house.

## 4. Not built / guessed

The tram wires and tracks are the map's. Colours are read from daylight photos; the red house's carved entrance,
the first-floor reliefs of the ornate house, the real shop signs and the roof of the plain house behind its wrap
are not built. Back walls have plain panes. Axes counts are estimates. The 59 plate and the parking sign are left to street details.

## 5. Budget

9,179 triangles (check_mesh_quality budget 10,000): about 200 windows. One building surface, no draw call added.
