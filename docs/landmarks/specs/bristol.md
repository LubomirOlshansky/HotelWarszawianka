# Hotel Bristol (the corner tower): spec

**v2, 2026-11-26 (Krakowskie Przedmieście rework for the trailer, F's go): the whole hotel as one
model for the Codex queue, replacing the kept LoD2 skin and `_palace_hotel`'s generic body.** Read
"v2 changes" first; sections 1-9 are v1 and still hold where v2 does not overrule them. Refs
(gitignored): `refs/kp_bristol/3dtiles/` (Google 3D Tiles; Bristol is the pale building with the
inner court and the corner drum, the big green-roofed block across Karowa is Europejski), Street
View in `refs/kp_sv/`, F's night photos of 2026-11-26 (pack 2: four views of Bristol floodlit, the
belvedere lit blue).

## v2 changes (what the rebuild fixes)

v1 is 2,079 triangles: a LoD2 skin with a generic hotel body. v2 is **L3, budget 7,500**.

1. **The mass** from the outline (a closed block round an inner court, 3D Tiles top view), the skin
   dropped (`model: true` on its SKINS entry): ground floor 5.2 m with a 1.4 m mezzanine band,
   then four storeys (3.6 m each) to the main cornice at 25.2 m, then a **mansard storey** in dark
   slate (#5d6266) with a curb at 28.6 m and a low top to the LoD2 roof (32.4 m at the corner).
   The court faces are plain cream with a window grid (M_MONUMENT), no detail.
2. **The street fronts** (Krakowskie Przedmieście and Karowa; the third face to the Presidential
   Palace's garden is plain): the ground floor is tall dark shop glass in thin dark frames, bays
   4.4 m, under a cornice band; above it **giant paired pilasters** (0.6 m wide, 0.25 m proud) from
   the first floor to the cornice every second bay, windows between them with moulded heads
   (`kit_window SILL_HEAD`; on the first floor `kit_window PEDIMENT` heads); **iron balconies**:
   a long one across the middle five bays of each front on the first floor, single ones on the
   third floor every second bay (`kit_balcony IRON`). The Krakowskie front's middle three bays
   rise into a **segmental gable** 3.5 m high over the cornice with a cartouche; under the cornice
   there a band with the hotel's name (BRISTOL is a real hotel; keep the name off the facade,
   a plain band only; the gold neon board at the door stays as v1).
3. **The corner drum** (v1 rows, kept) is now the same height as the front's floors and carries
   the floor bands and windows round it; the belvedere on top glows deep blue at night (done in
   the night-look PR: the core is `M_LAMP + 0.5`, radius 2.6 m; keep it).
4. **The mansard**: a dormer every 4.4 m on both street fronts (hipped, slate, a dark window), a
   larger round-headed dormer over each pilaster pair at the corners.
5. **Night**: in `FLOODLIT_SITES`; keep walls in M_STONE / M_MONUMENT. The pilasters and cornice
   are the brightest (they stand out from the wall, as in F's photos), the mansard stays dark, the
   shop glass glows warm (M_PAVILION) on the Krakowskie front and at the corner café.
6. **Shots**: `tools/turntable.sh bristol`, then `--at=-592,-905 --heading=160 --time=night
   --prebuilt` and the dzik's view over Krakowskie.

### v2 parts table (new rows; v1 rows for the drum and belvedere kept)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | block round the court | outline, cornice 25.2 m | the mapped outline | M_MONUMENT #e9e1c8 | 1 mass |
| gf | shop glass bays, cornice band | 5.2 m + 1.4 m mezzanine, bays 4.4 m | both street fronts | M_PAVILION #33383e, M_STONE #cfc6ac | 3 facade |
| pilasters | paired, giant | 0.6 x 0.25 m, first floor to cornice | every second bay | M_STONE #f1eadb | 3 facade |
| windows | kit SILL_HEAD, first floor PEDIMENT | 1.4 x 2.4 m | every bay, floors 1-4 | M_MONUMENT, kit | 3 facade |
| balconies | kit IRON | 5 bays long (floor 1), single (floor 3) | middle of each front | M_STONE #2a2c2f | 3 facade |
| gable | segmental, cartouche | 3.5 m over the cornice, 3 bays wide | Krakowskie front middle | M_STONE #f1eadb | 3 facade |
| mansard | sloped storey, curb | 25.2-28.6 m, curb 0.3 m | all faces | M_STONE #5d6266 | 4 roof |
| dormers | hipped, round-headed at corners | 1.4 x 1.8 m every 4.4 m | both street fronts | M_STONE #5d6266, kit window | 4 roof |


Site key `bristol` in `game/scripts/landmarks.gd` (`_build_bristol`). Rewritten 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (photos 12-15; report `docs/landmarks/photo-reports/krakowskie.md` section 3) and the GUGiK LoD2 heights from the CI map pack. The mass stays the kept LoD2 skin, now cream (#e9e1c8) under a grey zinc mansard (#6f7477); the first pass had sand plaster, a brown roof and a copper dome.

## 1. Identity

The grand hotel of 1901 (Krakowskie Przedmieście 42/44): its rounded south-west corner at Karowa rises into a cream drum with pilasters, crowned by an **open round belvedere**: eight thin columns on a balustraded ring under a flat cream dome cap, ~5 m above the roof line.

## 2. Massing

Centre (-557.8, -894.0) on the mapped corner, which rounds at ~4 m radius (the report read (-551, -889) off the ortho, outside the outline, so the outline wins). A 12-sided drum r 3.4 m from the ground (inside the mass) to 32.4 m (LoD2 roof at the corner 32.7 m over the street), eight pilasters from 6 m; ring 0.5 m, balustrade r 3.6 m 0.8 m; columns r 0.2 m at 3 m radius, 2.7 m tall; entablature ring; dome cap to 38.6 m; gilt finial to 39.8 m. A dark core (r 1.7 m) inside the columns reads as the open belvedere's shade.

## 3. Facade, base to top

Drum in the cream plaster with windows (M_MONUMENT) and eight trim pilasters; the belvedere's ring, balustrade, columns and entablature in trim cream.

## 4. Roof

A flat cream dome cap in two frustums (r 3.3 to 2.0 to 0.5 m) and a gilt finial.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e9e1c8 | M_MONUMENT |
| Shade, plinth | #cfc6ac | M_STONE |
| Trim | #f1eadb | M_STONE |
| Mansard (skin and body) | #6f7477 | M_STONE |
| Belvedere core | #4a4842 | M_STONE |
| Gilt | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

No collision of its own (the hotel's mapped walls are the car's). Card: "Hotel Bristol" (now "z belwederem na rogu"). Photo 15: warm floodlight at night, the corner canopy lit (the hotels pass's lit door covers the second).

## 7. Detail level and budget

L2; 2079 triangles measured (tower and body), budget 2450 (`check_mesh_quality.gd`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| drum | 12-gon prism | r 3.4 m, to 32.4 m | the corner | M_MONUMENT | drum |
| pilasters | 8 prisms | r 0.3 m | round the drum, 6-32.4 m | M_STONE | pilasters |
| ring, balustrade | 12-gon prisms | r 3.9 / 3.6 m | 32.4-33.7 m | M_STONE | balustrade |
| columns | 8 prisms | r 0.2 m, 2.7 m | r 3 m, 33.7-36.4 m | M_STONE | open belvedere |
| core | 8-gon prism | r 1.7 m | 32.9-36.4 m | M_STONE #4a4842 | shade inside |
| cap | ring, 2 frustums | r 3.5 to 0.5 m | 36.4-38.6 m | M_STONE | flat dome |
| finial | prism | r 0.12 m, 1.2 m | top | M_STONE #c9a24a | finial |

## 9. The hotel's body (hotels pass, 2026-11-01)

The mass was a kept skin with only the corner tower ours; the shared `_palace_hotel` builder now adds the rest on the mapped outline (simplified 0.9 m): the rusticated plinth with dark ground-floor openings, the balcony band, string course, cornice, a grey zinc mansard (#6f7477, photos 13-14) with a hipped dormer every 4.4 m (none within 7.5 m of the tower), and on the longest public front (the Krakowskie Przedmieście side) a forward bay with the lit door, an iron canopy (#2b2b2b, photo 14: dark iron and glass over the corner café) on two posts, a dark board with BRISTOL in gold neon and a pediment. Trim #f1eadb, wall and plinth as in section 5. Budget 2450 triangles (2079 measured with the 2026-11-02 belvedere); see `polonia.md` for the shared rows of the parts table.

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | `_palace_hotel` | see polonia.md rows | the outline | M_STONE, M_GLASS | 3 facade, 4 roof |
