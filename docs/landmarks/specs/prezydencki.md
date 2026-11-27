# Pałac Prezydencki (the Presidential Palace): spec

**v2, 2026-11-26 (Krakowskie Przedmieście rework for the trailer, F's go): a whole rebuild for the
Codex queue.** Read "v2 changes" first; sections 1-8 below are the v1 spec, still right where v2
does not overrule them. Refs (gitignored, never committed): `refs/kp_prezydencki/3dtiles/` (Google
3D Tiles, 8 orbit views and the top, 2026-11-26), `refs/kp_sv/streetview/` (Street View from the
street, 2020-2021), F's night photos of 2026-11-26 (`/mnt/project-files/uploads/hearth/`, pack 2:
the north wing's street end with a lion, the forecourt at night with the statue and the main block).

## v2 changes (what the rebuild fixes)

v1 was 1,181 triangles for a hero site seen in the trailer from the street and from the dzik's
flight. v2 is **L3, budget 7,000** (`check_mesh_quality.gd` BUDGET). The v2 build measures 6,990 (2026-11-27), so the budget leaves no headroom: any added part must take its triangles from another, or the budget is raised on purpose with a reason.

1. **The wings** (u 0..84 / 0..88): two storeys over a rusticated ground floor, as the photos show
   (eaves 10.5 m kept): ground floor 4.2 m, banded rustication, **round-headed** windows (1.4 x
   2.6 m) every 3.6 m, an iron wall lantern between every second pair (M_LAMP, warm, 2.6 m up);
   first and second floor tall sash windows (1.3 x 2.3 m and 1.3 x 1.9 m) in plain surrounds with
   a sill band; a crowning cornice 0.45 m proud; facade kit `kit_window SILL_HEAD` for the upper
   floors, `kit_window ARCH` for the ground floor. The roof is **dark grey slate** (#4a4e52), hipped,
   rise 4.2 m, with a row of small flat dormers on the courtyard side every 7.2 m (3D Tiles views
   000 and 045). The courtyard faces are the same as the street-end faces (they are what the
   player sees).
2. **The street pavilions** (the wings' ends on Krakowskie, u 84..92 / 88..96): three storeys,
   their street face a temple front: a pediment 3.2 m high over four Ionic pilasters (first and
   second floor), a balcony with an iron railing on the first floor across the middle three bays,
   rusticated ground floor with a round-headed door. Pediment tympanum plain. The pavilion's long
   side towards the forecourt keeps the wing's rhythm.
3. **The main block** (u -25..0): three storeys and an attic over a rusticated ground floor, 15
   bays to each side of the risalit; the risalit (v ±14) as v1 (seven arches, six engaged columns,
   balustrade with figures) but the columns **Corinthian** (a 0.6 m capital block flared) and two
   flagpoles on the balustrade at v ±4 (flags as flat panels, white-over-red; the EU flag left
   out). Roof: low hipped grey sheet (#7d8a87), nearly flat on top (3D Tiles top view), with the
   balustrade running the full front.
4. **The forecourt's front on the street** (u 94): **no iron fence on the street**: a row of
   white stone bollards (0.45 m square, 1.1 m) every 4.5 m joined by dark iron chains (sagging
   0.25 m, as boxes in 3 straight pieces) from v -25 to -9 and 9 to 22.5; the **four lions**
   reclining on long white plinths (plinth 2.8 x 1.3 x 1.6 m; lion 2.4 m long: body, mane block,
   head, front paws, tail down the side) at v ±7 and ±11, two each side of the opening, facing
   the street. Lit plaques: two white panels (1.2 x 0.9 m on legs) in front of the statue, glowing
   at night (M_LAMP, cream).
5. **The inner fence**: tall black iron railings (2.6 m, posts every 2.2 m, gilt tips as KP gold
   M_GOLD) across the forecourt at u 22 from wing to wing, the gate open in the middle (v ±5) with
   two stone piers 3.4 m high; two **sentry boxes** (plain white with a grey pyramid
   roof, 1.4 x 1.4 x 2.6 m) at v ±7 just inside.
6. **Poniatowski** on a tall **black polished granite** pedestal (#24262a, 3.0 x 5.2 m, 4.2 m
   high, a lighter cornice band 0.3 m with gilt letters as a darker band), horse and rider dark
   bronze, the horse walking towards the street (one foreleg raised), the rider in a Roman
   tunic with a sword held low and forward. Placed at u 70, v 0 (Street View and F's photo:
   between the lions' line and the inner fence, nearer the street).
7. **Night** (the trailer): the site is in `FLOODLIT_SITES`: every M_STONE and M_MONUMENT wall
   is washed cream-white automatically (`facade_kit.gd _flooded`). Keep walls in those two modes
   so they light; the wall lanterns and plaques glow (M_LAMP); the roof stays dark.
8. **Shots**: turntable sheet (`tools/turntable.sh prezydencki`), then city shots: from the street
   at the lions by night (`--at=-561,-955 --heading=250 --time=night --prebuilt`) and the dzik's
   view (`--heli --at=-575,-1010 --time=night --prebuilt`).

### v2 parts table (added and replaced rows; the v1 table below is otherwise kept)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wing_gf | rusticated band, round-headed windows | 4.2 m, windows 1.4 x 2.6 every 3.6 m | both wings, street and courtyard faces | M_STONE #ddd6c4, kit_window ARCH | 1 U |
| wing_upper | sash windows, sill band, cornice | 1.3 x 2.3 / 1.3 x 1.9 m, 3.6 m bays | both wings, floors 1-2 | M_MONUMENT #efe9da, kit_window SILL_HEAD | 1 U |
| wing_lanterns | iron wall lanterns | 0.3 x 0.5 m | every 7.2 m, 2.6 m up, forecourt faces | M_LAMP #ffd9a0 | night |
| wing_roof | hipped slate, dormers | rise 4.2 m, dormers 1.2 x 1.0 m every 7.2 m | both wings | M_STONE #4a4e52 | 5 roofs |
| pavilion_front | pediment, 4 Ionic pilasters, balcony | pediment 3.2 m, balcony 7 m wide | wing ends on the street, u 92 / 96 | M_MONUMENT, M_STONE, kit_balcony IRON | 5 pediments |
| main_columns | engaged Corinthian | r 0.5, capital 0.6 m | risalit, v ±2.3, ±6.9, ±11.5 | M_STONE #efe9da | 2 risalit |
| flags | 2 poles, 2 flat flags | 6 m poles, 1.8 x 1.1 m | balustrade, v ±4 | M_STONE #f2f2f2 / #c8102e | 2 risalit |
| bollards | square posts, chains | 0.45 x 1.1 m every 4.5 m | u 94, v -25..-9 and 9..22.5 | M_STONE #ece6d8, chain M_STONE #2a2c2e | 4 front |
| lions | plinth, body, mane, head, paws, tail | plinth 2.8 x 1.3 x 1.6 m, lion 2.4 m | u 94, v ±7, ±11, facing +u | M_STONE #e6e0d2 | 4 lions |
| plaques | two lit panels on legs | 1.2 x 0.9 m | u 88, v ±3 | M_LAMP #f3ead6 | night |
| inner_fence | iron railings, two piers, open gate | 2.6 m, piers 3.4 m | u 22, wing to wing, gate v ±5 | M_STONE #1f2224, tips M_GOLD | 4 gate |
| sentries | box with pyramid roof | 1.4 x 1.4 x 2.6 m | u 20, v ±7 | M_MONUMENT, roof M_STONE #6b7275 | 4 gate |
| statue_base | polished granite block, cornice | 3.0 x 5.2 x 4.2 m | u 70, v 0 | M_STONE #24262a | 3 statue |
| horse_rider | horse with a raised foreleg, rider with sword | horse 2.8 m long | on the base, facing +u | M_STONE #3a403c | 3 statue |


Site key `prezydencki` in `game/scripts/landmarks.gd` (`_find_prezydencki`,
`_build_prezydencki`). Written 2026-10-31 in a cloud thread from the OpenStreetMap outline (a U
round the forecourt, open to Krakowskie Przedmieście), GUGiK's LoD2 heights and the mapped lawn
in the forecourt; until now the palace was a skin (LoD2's massing in cream). No photo was
available here: the values marked *(photo check)* wait for the Mac's `refs/`, and the Geoportal
blurs parts round the palace, so the orthophoto helps less here than elsewhere.

## 1. Identity

The palace (rebuilt in classical form by Chrystian Piotr Aigner, 1818-1819) behind its
forecourt on Krakowskie Przedmieście, the President's seat.

1. **A U of cream wings round a forecourt**, open to the street, the main block across the back.
2. **A risalit in the middle of the main block**: an arcade of round-headed openings in the rusticated ground floor, engaged columns over it to the cornice, a balustrade with stone figures along the top (F's front photo T08-03, 2026-11-08: no free portico, no pediment).
3. **Thorvaldsen's Prince Józef Poniatowski on horseback** in the forecourt, on a granite
   pedestal, facing the street.
4. **Four stone lions** on pedestals by the gate in the iron fence, and two small guardhouses.
5. **Pediments on the wings' street ends** and grey-green sheet roofs.

## 2. Massing

Plan frame: origin (-514.0, -1005.5), the middle of the main block's front; u towards the
street, axis (-0.9089, 0.4170) (WNW); v across (v < 0 north). From the outline: main block
u -25..0, v -41..42 (with a garden annex u -25..-14, v 42..50); north wing u 0..84, v -40.5..-25.5;
south wing u 0..88, v 23..40; street pavilions u 84..92 (north) and 88..96 (south). Heights from
LoD2 (ground 7.1 m): main block eaves 15.5 m, ridge ~21 m; wings eaves 10.5 m, ridge ~14 m;
pavilions 12 m to the cornice *(photo check: storeys)*. The forecourt between the wings is about
48 m wide and 90 m deep; the zone is the outline's hull so the LoD2 run (centred in the
forecourt) goes too.

## 3. Facade, base to top

- **Base**: rusticated, 4 m (the ground floor), a step darker.
- **Floors**: tall windows between pilasters (M_MONUMENT) to the eaves; a cornice 0.4 m proud.
- **Risalit** (photo pass 2026-11-08): 1.2 m proud, v ±14, rusticated to 4 m with seven dark
  round-headed openings (2.2 m wide, to 3.5 m) at v 0, ±4, ±8, ±12; six engaged columns (r 0.5 m)
  from 4.2 to 15.4 m at v ±2.3, ±6.9, ±11.5; cornice to 16.4 m; a 1 m balustrade on top with a
  figure (1.9 m on a 0.5 m plinth) over each column. The balustrade runs along the whole main
  block's front, with four more figures at v ±27 and ±38.
- **Street pavilions**: the wings' last 8-9 m, a storey taller, with a pediment 3.2 m high to the
  street.

## 4. Roof

Hipped over each block from the cornice: main block rise 5 m, wings 3.6 m, garden annex 3 m;
gable roofs on the pavilions; pyramid roofs on the guardhouses. Grey-green sheet.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls, columns, pediments | #efe9da | M_MONUMENT (floors), M_STONE |
| Base | #ddd6c4 | M_STONE |
| Main block roof | #7d8a87 grey-green sheet | M_STONE |
| Wings' and pavilions' roofs | #6b7275 slate (aerial T08-04) | M_STONE |
| Arcade openings | #4d4a42 | M_GLASS |
| Figures | #e4ded0 | M_STONE |
| Statue | #3f4a45 (patinated bronze) | M_STONE |
| Pedestal | #8d8a86 granite | M_STONE |
| Lions | #d8d2c4 | M_STONE |
| Fence | #2f3432 | M_STONE |

## 6. Ground and night

The forecourt's paving, drive and lawn are the map's. The statue at u 66, v -0.5: a granite
step 6 x 3.2 m, the pedestal to 3.6 m, a cornice, the horse stepping towards the street, the
rider with his sword forward *(photo check: place and pose)*. The fence at u 94 from v -25 to
22.5 with the gate open between v -6 and 6; the lions on pedestals at v ±6 and ±9.4, looking
out; guardhouses inside the gate at u 88.5, v -15.5 and 14 *(photo check)*. The car is stopped
by the outline, the fence, the pedestals and the statue. Card: "Pałac Prezydencki", PL "Przed nim
książę Józef Poniatowski na koniu i cztery kamienne lwy.", EN "Prince Józef Poniatowski on
horseback and four stone lions before it."

## 7. Detail level and budget

L2 for the wings, L3 for the portico, the statue and the gate: triangle budget 1300 (1181
measured after the 2026-11-08 photo pass, in `check_mesh_quality.gd`). Shots: `--solo=prezydencki
--solo-look=sil` and `flat`, then in the city from the street at the gate.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| main | box, cornice, hip roof | 25 x 83 m | u -25..0, v -41..42, eaves 15.5 | M_STONE base, M_MONUMENT | 1 U |
| annex | box, cornice, hip roof | 11 x 8 m | u -25..-14, v 42..50, eaves 12 | M_MONUMENT | 1 U |
| wing_n | box, cornice, hip roof | 84 x 15 m | u 0..84, v -40.5..-25.5, eaves 10.5 | M_MONUMENT | 1 U |
| wing_s | box, cornice, hip roof | 88 x 17 m | u 0..88, v 23..40, eaves 10.5 | M_MONUMENT | 1 U |
| pavilions | box, cornice, gable | 9 x 16-18 m | u 84..92 and 88..96, to 12.7 m, apex 15.9 m | M_MONUMENT, M_STONE | 5 pediments |
| risalit | 2 boxes, cornice | 1.2 x 28 m | u 0..1.2, v ±14, to 16.4 m | M_STONE #ddd6c4, M_MONUMENT | 2 risalit |
| arches | 7 walls + heads | 2.2 m wide, to 3.5 m | u 1.23, v 0, ±4, ±8, ±12 | M_GLASS #4d4a42 | 2 risalit |
| columns | 6 engaged | r 0.5, 11.2 m | u 1.45, v ±2.3, ±6.9, ±11.5 | M_STONE #efe9da | 2 risalit |
| balustrade | 2 boxes | 1 m high | main block front, risalit top | M_STONE | 2 risalit |
| figures | 10 (plinth, body) | 0.4 x 0.44 x 1.9 m | over the columns, v ±27, ±38 | M_STONE #e4ded0 | 2 risalit |
| statue_base | 3 boxes | 6 x 3.2 m, to 3.95 m | u 66, v -0.5 | M_STONE #8d8a86 | 3 statue |
| horse | body, 4 legs, neck, head | 2.3 x 0.8 x 1 m body | on the pedestal, head to +u | M_STONE #3f4a45 | 3 statue |
| rider | body, head, sword arm | 0.5 x 0.6 x 1.5 m | on the horse | M_STONE #3f4a45 | 3 statue |
| fence | 2 rails and posts per side | 19 and 16.5 m long, 2.1 m | u 94, v -25..-6 and 6..22.5 | M_STONE #2f3432 | 4 gate |
| lions | pedestal, body, head | 1.8 x 1.2 x 2.6 m pedestal | u 94, v ±6, ±9.4 | M_STONE #d8d2c4 | 4 lions |
| guardhouses | box, cornice, pyramid | 4.4 x 4.4 m, to 6.2 m | u 88.5, v -15.5 and 14 | M_MONUMENT, M_STONE | 4 gate |
