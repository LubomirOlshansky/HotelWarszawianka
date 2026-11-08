# Warsaw Financial Centre (Warszawskie Centrum Finansowe): spec

Site key `wcf` in `game/scripts/landmarks.gd` (`TOWERS` entry, built by `_build_wcf`). Written 2026-11-08 in a cloud thread from F's photos (`/mnt/project-files/pkin-surroundings/photos/W4-wcf/`: 1 the whole tower from Varso, 2 its crown from Varso, 3 the street elevation along Emilii Plater, 4 the corner, 5 a dusk skyline that turned out to show another tower, not used) and the OpenStreetMap parts in `centrum.json`. Mapillary views (`refs/wcf/street/`) checked the podium.

## 1. Identity

1. Two slabs split on a curve: a taller white one (144 m) and a lower glass one (130 m) whose curved face it wraps (plan, photo 1).
2. The white slab's cladding: white piers and spandrels with punched dark windows (photos 2, 3).
3. The glass slab's ribbon glazing: dark teal glass between white bands at every floor (photos 1, 4).
4. A stone-and-glass podium, pink-beige granite at the street, green glass above (photos 1, 4).
5. The red-and-white mast on the white slab's roof (photo 3).

## 2. Massing

The plan is the two mapped parts (`WCF_HIGH`, `WCF_LOW`), together a 62 x 27 m rectangle turned like the grid, split on a concave curve. Podium 0 to 19.8 m over their union; the white slab to 144 m; the glass slab to 130 m with its top storey (126.4 to 130 m) set 1.6 m in.

## 3. Facade, base to top

Base: a granite ground floor 0.2 m proud (to 5.2 m), green glass in a fine grid to 18.6 m, a granite band to 20.1 m. Middle: S_PUNCHED in white on the white slab (punched windows in bands), S_RIBBON with teal glass on the glass slab. Top: a pale band at 126.4 m and the dark set-back top storey on the glass slab; a 1.5 m parapet round the white slab's roof.

## 4. Roof

The white slab: flat, pale, behind its parapet, two 8 m grey plant blocks on its straight west half (photo 2), the 24 m mast in six red and white pieces with a red lamp; the glass slab: flat, pale. Red aviation lights on both roofs.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| White slab | #d8d9d4 | M_SKIN S_PUNCHED |
| Glass slab | #2f5d60 | M_SKIN S_RIBBON |
| Podium glass | #7ea29e | M_SKIN S_GRID |
| Granite | #bba595 | M_STONE |
| Parapet | #cfd1cf | M_STONE |
| Mast | #c8302a, #ecebe6 | M_STONE |

No new material or draw call.

## 6. Ground and night

The podium brings the car walls. At night the punched windows and ribbons light by their skins' rules, red lamps on the mast and the roofs. No name on the crown (none in the photos).

## 7. Detail level and budget

L2; budget 1400 triangles in `check_mesh_quality.gd` (1319 measured with the street front below; 454 before it, 190 for the plain box).

Shots: `--at=-1525,62 --yaw=-45 --lift=75 --size=190` (from Varso, photo 1), day; `--solo=wcf --solo-look=lit`.

## 7b. The street front on Emilii Plater (F's 13 photos, 2026-11-08)

The entrance faces Emilii Plater (east). A black base band to 0.8 m, two granite bands on the
podium (8.4-10.6 m and 13.6-15.8 m), steel sun fins standing 1.1 m proud at 5.4, 10.8 and 16 m,
granite piers every 4.6 m along the east and north faces. The portico: a canopy 6-7 m deep with a
curved front edge at 5.6-6.1 m, nine downlights in it, one round steel column on a black foot,
a revolving-door drum (r 1.5 m, lit glass) with glass side doors, a black plinth. Letters
"EMILII PLATER 53" in silver over the door, "SENATOREK" in gold on the canopy's fascia (the
lounge upstairs, shisha quest), "COFFEECHAIR" over the ground-floor café. On the low roof a glass
rail round the edge and lamps every 6 m (the lounge's terrace). `_wcf_street`, `_wcf_terrace` in
landmarks.gd.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| podium | union prism | 62 x 27 m, 19.8 m | ground | S_GRID glass | 4 |
| plinth | ring 0.2 m proud | 5.6 m and 1.5 m bands | ground and 18.6 m | M_STONE granite | 4 |
| glass slab | curved prism | 130 m | south-east part | S_RIBBON | 1, 3 |
| top storey | inset prism | 3.3 m, 1.6 m in | 126.7 m | S_DARK | 3 |
| white slab | curved prism | 144 m | north-west part | S_PUNCHED | 1, 2 |
| parapet | ring | 1.5 m | 144 m | M_STONE | 2 |
| plant | two boxes | 8 x 8 x 4.2 m | roof's west half | M_STONE | 2 |
| mast | six stacked squares | 24 m | roof's west end | M_STONE red/white | 5 |
