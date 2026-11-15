# Aleje Jerozolimskie 57-63, the tenement row across from the Palace: spec

Site key `jerozolimskie57` (`_find_jerozolimskie57`, `_build_jerozolimskie57` and the `_jr_*` helpers in
`game/scripts/landmarks/srodmiescie.gd`). Written 2026-11-15 in a cloud thread from F's six photos of
the row (reference only, never shipped) and the five OpenStreetMap outlines. No. 57 is where the club
Nowa Jerozolima was (a multi-floor club in a former children's hospital tenement, per the Warsaw Insider page).

## 1. Identity

The south side of Al. Jerozolimskie, the block between Emilii Plater (Centrum LIM's tower beyond it, the
"SAMSONG" mid band in the photos) and Poznańska, 148.7 m of front. The photos are taken from the Palace
side. From the east (the left in the photos): the neighbouring pale yellow tenements (not built here), then
1. the restored red tenement (no. 57), u 0 to 26.2;
2. the plain white house under a large white wrap on its roof (no. 59), u 26.2 to 70.0;
3. the white house with the arched gate and tall brown-framed windows, u 70.0 to 104.3;
4. the ornate white house with the zinc mansard at the Emilii Plater corner, u 104.3 to 148.7.
Frame: u from the east end (-1115.5, 581.2) west along the front line, v out to the street.

## 2. Massing

OSM outlines 116, 117 (the ornate house), 849 (arched), 847 and 848 (plain and red) are cut into the four
houses by perpendicular party walls and built whole: the front range (13 m deep) to its eaves, the plan behind
it 2.4 m lower with a flat roof. A 2.5 m rim along the front line closes the outlines' small jogs. Eaves over the
ground: red 23.0 (ridge about 32.5), plain 18.2 (wrap to 28.6), arched 22.4, ornate 22.6 (mansard to 27.0).
The party walls are read off the photos and the OSM boundaries: 849|117 and 847|849 follow OSM; red|plain is
a guess inside outline 848 (OSM has one outline for both). Unverified.

## 3. Facade

- **Red**: banded red ground floor and first floor (#a0463d, lighter red window frames), a red balustrade balcony
  across the left part under the white floors (pale lilac plaster #ddd8de) and another under the red top floor
  of paired piers; two white iron balconies between; red cornice; a forward bay on the west side (three
  windows a floor, a big arch under it, red crown); a gabled entrance with an arched door.
- **Plain**: white, a grey rusticated ground floor of shops, fifteen axes of small framed windows on four rows,
  an arched gate at u 42.4 with an iron balcony and a tall door over it, cornice and parapet.
- **Arched**: seven wide axes, brown-framed tall windows, arched on the second floor, stone balconies on the
  first, an arched gate on the middle axis, a lounge door with the sign TUTAJ (an invented name).
- **Ornate**: twelve axes, hooded first floor, pedimented second, arched third, stone balconies in two long
  runs, pilasters at the ends, a coffee house with the sign PARZYBUDA (an invented name).
- Back walls have plain panes. Axes counts are estimates.

## 4. Roof

Red: steep orange tile (#c4602f) hip roof with three zinc dormers and a stepped gable at the east end. Plain: the
white wrap (a thin screen 10.4 m high set back 3 m, seams every 7 m); the real roof behind it is not built.
Ornate: zinc mansard with six dormers and a raised box at the west end. Arched: a flat roof behind a parapet.

## 5. Colour and material

Colours are read from daylight photos: white plaster, red #a0463d, pale lilac #ddd8de, orange tile #c4602f,
grey zinc, brown window frames, green steel canopies. All in the existing building materials; no new material,
shader instruction or draw call.

## 6. Ground and night

Pavement: two green steel arcade canopies (u 50.5 to 83.5 and 110.7 to 140.7) with lit ad showcases (colour
panels only, no text); striped red-and-white barriers and a low scaffold at the red house. The tram wires
and tracks are the map's. The car is stopped by the outline (`_collide`). Night: the two invented neon signs and
lit windows by chance. Not built: the red house's carved entrance, the ornate house's first-floor reliefs, real
shop signs, the 59 plate and the parking sign (left to street details).

## 7. Detail level and budget

L3, triangle budget 9,179 measured (check_mesh_quality budget 10,000), an exception to the L3 limit of 8,000: a
148 m front of four houses with about 200 windows built as one site. One building surface, no draw call added.
Shots: `tools/turntable.sh jerozolimskie57`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| red | outline prism + hip roof | 26 x 13 m, eaves 23.0 | u 0 to 26.2 | building walls, tile | restored tenement, bay, gabled entrance |
| plain | outline prism + screen | 44 x 13 m, eaves 18.2 | u 26.2 to 70.0 | building walls | gate, white wrap |
| arched | outline prism | 34 x 13 m, eaves 22.4 | u 70.0 to 104.3 | building walls | arched gate, TUTAJ sign |
| ornate | outline prism + mansard | 44 x 13 m, eaves 22.6 | u 104.3 to 148.7 | building walls, zinc | twelve axes, PARZYBUDA sign |
| canopies | two steel arcades | 33 m and 30 m long | on the pavement in front of the arched and ornate houses | green steel | lit ad showcases |
| site | barriers and scaffold | low | in front of the red house | striped plastic, steel | building site |
