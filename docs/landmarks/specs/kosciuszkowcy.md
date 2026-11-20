# Pomnik Kościuszkowców: spec

Site key `kosciuszkowcy` in `game/scripts/landmarks/praga.gd` (`_find_kosciuszkowcy`,
`_build_kosciuszkowcy`). Written 2026-11-20 from 30 Mapillary street photos (2019-2025) round the
plaza at Wybrzeże Szczecińskie and the Most Świętokrzyski ramp (refs/kosciuszkowcy; the best is
the view from the bridge ramp, heading 126°; never shipped), the encyclopedia articles on the
monument and the OSM plaza. F asked for it with the skaters round it (2026-11-20).

## 1. Identity
1. The **1st Tadeusz Kościuszko Infantry Division's monument** (Andrzej Kasten, Bogusław
   Chyliński, unveiled 1985): a 12 m bronze soldier on a dark granite plinth, 16 m in all, at the
   Praga end of Most Świętokrzyski, facing west across the Vistula, the way the division tried to
   cross in September 1944.
2. The **pose**: striding west, the left leg forward and bent; the left arm flung up and out with
   the hand open (Warsaw calls it "Pięć piw proszę", five beers please); the PPSh at the right hip;
   the hood over the helmet; a huge **cape** sweeping back and to his right like a sail, as wide as
   he is tall, down to the plinth.
3. The **plaza** round it: grey granite paving, low granite blocks the skaters use.

## 2. Massing
Plinth: a step 14.8 x 7.8 m, the granite block 12.8 x 6 m tapering to 12 x 5.4 m, 3.65 m high, a
dark cap. Figure: 12 m from the plinth's top to the raised hand (scale k = 12 / 3.3 on a 3.3 m
pose). Ledges: two 10 x 0.9 m at u 11, v ±7.5 and one 7 x 0.9 m at u 24 (u west from the
monument), 0.45 m high.

## 3. Facade, base to top
Step, block, cap; legs (beams), feet, the body (a frustum leaning into the stride), neck, hooded
head and the helmet's brim; the left arm and five fingers; the right arm, the PPSh's barrel and
drum; the cape as five quads plus a three-quad fold behind it for bulk.

## 4. Roof
None: the figure's top is the open hand at about 16 m.

## 5. Colour and material
Bronze patina #55604f (green-grey in every photo), the cape darker by 8-22 %; granite #77736d, the
cap darker; paving step #b9b4aa; ledges granite lightened. All M_STONE.

## 6. Ground and night
No lights of its own (the plaza lamps light it). By day and evening (9:00-22:30) four skaters ride
the plaza: three loop round the ledges with an ollie every 4 s, one rides along the west ledge
and pops up onto it (city_life.gd SKATERS, the scooters' MultiMesh: no new draw call). People sit
on the ledges watching them (crowds.gd `chill_kosc_ledges`, talk "port_praski").

## 7. Detail level and budget
L2, triangle budget 400 (check_mesh_quality BUDGET; measured 244). The helicopter does not fly
over it: the figure is a tall obstacle.

## 8. Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| step | box | 14.8 x 7.8 x 0.65 m | under the plinth | paving | the plinth's step |
| plinth | frustum | 12.8 x 6 to 12 x 5.4, 3.65 m | KOSC_AT | dark granite | tapering block, cap |
| legs | beams | 1 m thick | on the plinth | bronze | the stride west |
| body, head | frustums | 1.9 x 2.4 m, 4 m high | over the hips | bronze | hood, helmet brim |
| left arm | beam, 5 fingers | 4.5 m | shoulder up and out | bronze | "five beers" |
| PPSh | beam, drum | 3.5 m | at the right hip | darker bronze | barrel forward |
| cape | 8 quads | 10 x 9 m | behind, to his right | darker bronze | the sail and its fold |
| ledges | boxes | 10 or 7 x 0.9 x 0.45 m | west on the plaza | light granite | skaters' ledges, collide |
