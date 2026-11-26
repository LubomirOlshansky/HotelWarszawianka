# MDM: Plac Konstytucji's blocks, arcades and candelabras (spec, rebuild 2026-11-26)

Site key `mdm` in `game/scripts/landmarks.gd` (`_find_mdm` keeps LoD2's skin for the blocks,
`_build_mdm` in `landmarks/srodmiescie.gd` adds the model). First written 2026-11-01, reworked
2026-11-05 from F's Street View shots. This rebuild (F, 2026-11-26, before the dance reel's MDM
shot) is written from fresh references: Google Street View Static images from the square's
middle and its north and south approaches (`refs/mdm/streetview/`, panoramas of 2017-06,
2022-06 and 2024-08) and one Google 3D Tiles `--area=120` run of the square (`refs/mdm/3dtiles/`,
eight orbits at pitch -35 and the top). Reference only, never shipped or committed. The first
spec's known errors: the candelabras were a 7 m iron pole (real ones are about 19 m of stone),
the arcades were on every ring face, and the roofs were one grey.

Marszałkowska Dzielnica Mieszkaniowa (1950-52, Józef Sigalin and others, socialist realism).
The ring round the square is eight tall blocks in one language; the game keeps LoD2's mass
(skin `#e6dfcc`) and builds the stone work on it.

## 1. Identity

Judged in this order:

1. **The four stone candelabras** at the square's two ends (two flanking each end block): a
   stepped stone plinth, a long tapering stone shaft, an iron crown of five lanterns on curved
   arms and a taller lantern on top, about 19 m, roughly two thirds of the block height
   (Street View centre pano 2017, all four headings; the south gate pano 2022).
2. **The heavy stone base**: two storeys (ground and mezzanine, about 9.5 m) in sand-coloured
   rusticated stone, shop windows between broad piers, a strong string course above; on the
   square's south gate blocks the base is a **round-arched arcade** (centre pano h155, h245).
3. **Cream upper storeys**: a regular grid of tall windows, 6 storeys above the base on the
   30.7 m blocks, a thin sill band on every storey and iron balconettes on a few bays
   (Marszałkowska east face, 2024 pano h200: balconettes in pairs on the 3rd and 5th storeys).
4. **The deep cornice and a stepped attic** at every block end and corner, on the square a
   pale tower-like end pavilion with a small cupola-free flat cap (h065, h155).
5. **Roof colours from above**: grey flat roofs on most blocks, **dark red sheet** on the long
   east block of Marszałkowska (3D top view, 57 x 111 m block at about (-484, 1238)), a green
   copper patch on the south-west gate block.
6. The roof neons: red MDM and BYDŁO (silver) on the Hotel MDM gate block, XIAOMY (orange)
   on the south-east gate block, the hotel's own sign (kept from the earlier build, signs fixed in #1104).

## 2. Massing

LoD2 blocks stay (heights 27.4 and 30.7 m, three of 24.1 and 20.8 m). Added parts only. Block
list near the square (centre x z, height, bbox m), read from `centrum.json`:

| Block | Centre | Height | Size | Role |
| --- | --- | --- | --- | --- |
| NE long block | (-484, 1238) | 30.7 | 57 x 111 | Marszałkowska east, red roof |
| NW long block | (-602, 1288) | 30.7 | 58 x 111 | the west face, Samsung sign |
| SW gate block (Hotel MDM) | (-529, 1400) | 27.4 | 53 x 48 | MDM neons, arcade to the square |
| SE gate block | (-443, 1363) | 27.4 | 50 x 30 | XIAOMY, arcade |
| N end blocks | (-528, 1171), (-616, 1198) | 30.7, 27.4 | 35 x 23, 35 x 27 | corner towers |
| W end block | (-593, 1368) | 24.1 | 32 x 67 | west flank |
| E end block | (-433, 1319) | 24.1 | 32 x 80 | east flank |

Ground at the square is flat (about 0). Frame: the street grid `MDM_A` (0.349, 0.937).

## 3. Facade, base to top

For every long face that looks at the square or at Marszałkowska (dot 0.55, within 100 m):

- **Base** (0 to 9.5 m): wall 0.6 m proud, colour `#cdb98d`, rusticated: horizontal grooves
  every 0.9 m (a 0.04 m inset line, no extra triangles beyond the strip boxes).
  Ground floor to 5.2 m: broad piers 1.1 m wide every 5.4 m, dark shop glass between
  (`M_GLASS`, 4.4 m tall), a string course at 5.4-5.9 m. Mezzanine 5.9 to 9.0 m: a window per
  bay 1.4 x 2.2 m, a stone surround 0.12 m proud. Cornice 9.0-9.8 m, 0.5 m out.
- **Arcade on the gate blocks** (SW and SE only, the faces on the square): five arches per
  face, each 4.4 m wide and 5.8 m to the crown (a half-round of 8 segments), piers 1.5 m,
  2.9 m deep, an entablature at 6.4-7.0 m. The other ring faces get the base without arcade
  (the first build's arcade on every ring face was wrong).
- **Upper storeys** (9.8 m to the cornice): the skin stays; added: a sill band 0.15 m tall and
  0.08 m proud under every storey row, a thin vertical pilaster strip every 3rd bay on the
  Marszałkowska faces, and iron balconettes (a 1.4 x 0.9 m box with railing, `M_IRON`) on bays
  2, 3 and 6, 7 of every 10 on storeys 3 and 5 (read from the h200 pano).
- **Top**: a deep cornice, 0.9 m tall and 1.0 m out, a dentil row, then a parapet 0.7 m.

## 4. Roof

Source: `refs/mdm/3dtiles/mdm_top.png` and the orbit views.

- Roof colours: the NE long block `#7d3b36` (dark red sheet); the SW gate block's copper patch
  `#5f8f7d` on its west half; everything else grey `#7f7b74` (as the skin).
- End pavilions: at the four block ends the first build's stepped attic stays (cornice, attic
  4.5 m, cornice, flat cap, finials 1.6-2.4 m) but the cap is flat pale stone, no spire.
- Roof signs as built (Samsung and Orange signs are brands: keep parody names only, none added).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster (skin) | #e6dfcc | M_MONUMENT |
| Stone base | #cdb98d | M_MONUMENT |
| Piers, arcade, trim | #d3c39a, #ece4d0 | M_STONE |
| Shopfronts | #34383b | M_GLASS |
| Balconettes, candelabra crown | #2b2d2e | M_IRON |
| Candelabra stone | #a59b88 | M_STONE |
| Candelabra lanterns | warm white, lit at night | LAMP_HEAD |
| Roofs | #7d3b36, #5f8f7d, #7f7b74 | roof colours of the skin |

No new material or draw call: everything joins the building material; the candelabra stays the
shared `candelabra` mesh (MultiMesh), only larger.

## 6. Ground and night

Four candelabras on the square's pavement, each on a stepped plinth with a low kerb round it.
At night the six lanterns of each crown glow (the existing `candelabra` lamp heads, `_mark_head`).
Shop glass keeps the storefront night lighting. Car collision stays on each facade's front and
gains the four plinths (a 3 m square each).

## 7. Detail level and budget

L3. Current model: 3,403 triangles (budget 4,100 in `check_mesh_quality.gd`). Rebuild budget
**6,500** triangles for `mdm` (L3 range, within 8,000); the shared candelabra mesh at most 600
triangles (it is one mesh instanced four times and elsewhere). No zfight, degenerate, bad-normal
or floating parts. Shots: the turntable (the site is 340 m long: also `--cams` free shots from
the square's middle at each end, day and dusk), the Marszałkowska face at street level and the
square from the helicopter.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base_wall | wall plus ledge | 9.5 m high, 0.6 m proud | each ring and Marszałkowska face | M_MONUMENT, M_STONE | 2 base |
| base_rust | groove strips | 0.04 m inset every 0.9 m | on base_wall | M_STONE | 2 base |
| piers | boxes | 1.1 m wide, 5.2 m high | every 5.4 m | M_STONE | 2 ground floor |
| shopfronts | dark wall pieces | 4.4 m high | between piers | M_GLASS | 2 ground floor |
| mezzanine_windows | kit_window SILL_HEAD | 1.4 x 2.2 m | one per bay, 5.9-9.0 m | M_STONE | 2 base |
| arcade | round arches, piers, entablature | 5 arches of 4.4 m, 2.9 m deep | SW and SE gate faces on the square | M_STONE | 2 arcade |
| sill_bands | thin boxes | 0.15 m tall, 0.08 proud | every storey row, upper storeys | M_STONE | 3 upper storeys |
| pilasters | strips | 0.5 m wide, 0.1 m proud | every 3rd bay, Marszałkowska faces | M_STONE | 3 upper storeys |
| balconettes | kit_balcony IRON | 1.4 x 0.9 m | bays 2, 3, 6, 7 of 10, storeys 3 and 5 | M_IRON | 3 upper storeys |
| cornice | deep cornice and dentils | 0.9 m tall, 1.0 m out | top of every block face | M_STONE | 4 attic |
| attic_pavilion | windowed box, cornices, flat cap | 4.5 m attic | four block ends | M_MONUMENT, M_STONE | 4 attic |
| finials | pinnacles | 0.5-0.7 m wide, 1.6-2.4 m high | pavilion corners | M_STONE | 4 attic |
| roof_colours | roof tint per block | red, copper green, grey | NE long block, SW gate patch, rest | roof colours | 5 roofs |
| candelabra_plinth | three steps and a pedestal | 4.2, 3.4 and 2.6 m square, 0.4 m each, pedestal 1.8 m square 2.2 m high | four spots on the square | M_STONE | 1 candelabras |
| candelabra_shaft | tapering octagonal shaft | 1.1 m to 0.7 m across, 12 m high | on the pedestal | M_STONE | 1 candelabras |
| candelabra_crown | capital, five curved iron arms, central stem | arms reach 1.8 m out, crown to 19 m | top of the shaft | M_IRON | 1 candelabras |
| candelabra_lanterns | six hexagonal lanterns with finials | 0.5 m wide, 0.9 m high | one per arm and one on top | LAMP_HEAD | 1 candelabras |
| roof_signs | neon words | 8, 12 and 11 m wide | Hotel MDM roof, SE gate block | neon quad | 6 signs |
| hotel_sign | neon word | 5.2 m wide | Hotel MDM, 5.9 m up | neon quad | 6 signs |
