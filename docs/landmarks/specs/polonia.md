# Hotel Polonia Palace: spec

Site key `polonia` in `game/scripts/landmarks.gd` (`_build_polonia`, shared builder `_palace_hotel`). Written 2026-11-01 in a cloud thread (hotels pass) from the OpenStreetMap outline in `centrum.json`. **Photo pass 2026-11-08** from F's four photos (`/mnt/project-files/pkin-surroundings/photos/S2-polonia/`: 1 the Jerozolimskie front, 2 the roof and corner from above, 3 the roofline along the avenue, 4 the upper facade with the balconies) and Mapillary street views (`refs/polonia/street/`, 2022-2026, CC BY-SA 4.0); LoD2 now gives 29.5-32 m over the block. The OSM outline is a 4.3 m shed, so the model builds the whole building (and its car walls).

## 1. Identity

The hotel of 1913 on Al. Jerozolimskie 45, the grand hotel that stood through the Uprising. What makes it read (photos 1, 3, 4): the warm cream stone front of six storeys; the steep grey-blue zinc mansard a storey and a half high with a dormer at every bay; the middle bays' wide low pediment with its oval window rising into the mansard, the gold name on the frieze under it; the long iron-railed balconies on the first and fourth floors; the pale ground floor of tall shop windows.

## 2. Massing

The mapped outline simplified (0.7 m), 25.5 m to the cornice (ground floor 5.4 m and five storeys, photo 1), the mansard to 31.45 m (LoD2: 29.5-32 m). The shared east wall with Hotel Metropol carries no trim and no windows.

## 3. Facade, base to top

A plinth of rusticated courses (four or five, alternating tone) to 5.4 m with tall dark ground-floor openings; a balcony band over it (0.45 m out, 0.45 m deep); the upper floors in the M_MONUMENT window shader; a string course under the top floor; a cornice (frieze, then a ledge 0.8 m out); a parapet plinth. On the longest public front a forward bay 10 m wide stands 1 m out: the lit glass door between two trim surrounds, a canopy on two posts (two lamps), a dark board with the name in gold neon. Over the cornice the wide pediment (`_wide_pediment`): a cornice block 17.6 m wide, a gable 3.8 m high and 3.6 m deep, an oval window (a 0.85 m dark disc in a 1.2 m pale ring), and POLONIA PALACE HOTEL in gold letters on the frieze 3.4 m under the cornice. Balconies: a slab 0.6 m out with a 0.6 m dark railing at 9.2 m and 20.4 m, all round (photo 4 shows them on the front; the sides are a simplification).

## 4. Roof

A grey-blue zinc mansard (inset 0.9 m to 2.8 m over 5.6 m, `mansard_h`) with a flat top, and a hipped dormer 2.4 m tall with a window every 4.4 m on every public front longer than 9 m (photos 2, 4).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Wall | #e2d0aa | M_MONUMENT |
| Plinth | #d3c19c | M_STONE |
| Trim | #efe5cf | M_STONE |
| Zinc | #626b72 | M_STONE |
| Railings | #5a5450 | M_STONE |
| Canopy | #6b2a2f | M_STONE |
| Door | #f3d9a8 | M_PAVILION |

No new material or draw call.

## 6. Ground and night

The model builds the mass, so it brings its own car walls (8 along the simplified ring). The door glows and the name board burns gold at night. Card: "Hotel Polonia Palace". Still open: the rounded corners at both ends of the front (photo 2) are not modelled; the side and back faces have no photos (the sides carry the front's bands).

## 7. Detail level and budget

L2; 1306 triangles measured (1202 before the photo pass), budget 1450 (`check_mesh_quality.gd`).

Shot: `--at=-930,540 --heading=20 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | simplified outline prism | 25.5 m high | ground to roof | M_STONE courses, M_MONUMENT | 2 massing |
| plinth | 4-5 stacked rings | 6 m high, 0.25 m out | ground | M_STONE | 3 facade |
| balcony band | ring | 0.45 m high, 0.45 m out | 5.4 m | M_STONE | 3 facade |
| cornice | 3 rings | 2 m high, up to 0.8 m out | 25.5 m, top | M_STONE | 3 facade |
| mansard | frustum | 5.6 m high | above the parapet | M_STONE | 4 roof |
| balconies | slab and railing rings | 0.25 m slab, 0.6 m railing, 0.6 m out | 9.2 m and 20.4 m | M_STONE | 3 facade |
| pediment | cornice block, gable, oval disc | 17.6 m wide, 3.8 m high | over the bay, in the mansard | M_STONE, M_GLASS | 1 identity |
| name | neon POLONIA PALACE HOTEL | 25 m wide | frieze 3.4 m under the cornice | sign | 1 identity |
| dormers | boxes with hips | 1.1 m wide | every 4.4 m on the mansard | M_STONE, M_GLASS | 4 roof |
| entrance bay | box | 10 m wide, 1 m out | longest public front | M_MONUMENT | 3 facade |
| canopy, board | boxes | 7.4 m wide canopy | over the door | M_STONE | 3 facade |
