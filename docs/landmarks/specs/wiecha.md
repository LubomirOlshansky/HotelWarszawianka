# Pasaż Wiecha's pavilions: spec

Site key `wiecha` in `game/scripts/landmarks.gd` (`_find_wiecha`, `_build_wiecha`); the pasaż's
lamp masts and furniture in `game/scripts/first_scene.gd` (`PASAZ`, `PASAZ_MASTS`, ITEMS) and
`props.gd` `add_y_mast`. Written 2026-11-02 from the Mac photo report
`docs/landmarks/photo-reports/dt_pawilony.md` (three Commons photos of the pasaż, the 2025 GUGiK
orthophoto, F's Mac, refs/dt_pawilony/) and four OpenStreetMap outlines in `centrum.json`, found
by their vertex average (`WIECHA_AT`). Card: "Pasaż Wiecha".

## 1. Identity

The walkway behind the Eastern Wall's three stores, named after the writer Stefan Wiechecki
("Wiech"), lined with low shop pavilions under the 1960s slabs. What makes it read:

1. **Two-storey modernist pavilions**: a black and dark grey shop storey of glass under a dark
   fascia, a white upper band with one strip window round it, a flat roof.
2. **Tall white Y masts** on the pasaż's axis, about every 25 m: one pole splitting into two arms
   with long flat lamp blades.
3. **Light grey slabs underfoot**, café gardens under white parasols, planters, black bollards.

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Shop storey | each outline (simplified at 0.4 m) | -0.4 to 3.8 m |
| Fascia | the outline grown 0.9 m | 3.8 to 4.2 m |
| Upper band | the outline | 4.2 to 7.2 m |
| Strip window | the outline grown 0.04 m | 4.9 to 6.1 m |
| Parapet | the outline, its top a ring 0.25 m wide | 7.2 to 7.55 m |
| Plant boxes | two 1.8 m squares near the roof's centre | 7.2 to 8.3 m |

The four outlines, north to south: the podium row under the slab behind Sawa (L-shaped, along
the slab's west and north faces), the block by tower75, the pavilion on the square by Chmielna
(OSM name withheld), the podium under the south slab by Aleje Jerozolimskie. OSM says 4.3-7.6 m;
the photos show two storeys, so all are 7.2 m. The zone is each outline grown 1 m. The strip in
front of Scena Relax stays in the theatre's LoD2 model (one mass with it in GUGiK's data).

## 3. Facade, base to top

- **Shop storey**: dark glass #2b3035 (M_PAVILION, lit warm at night) with thin frames #1b1d20
  every 2.2 m.
- **Fascia**: #1b1d20 face, its top and underside a little lighter.
- **Upper band**: white #e9e8e3 (M_STONE); the strip window #3b4753 (M_PAVILION + 0.5, cool at
  night) with frames every 1.5 m.

## 4. Roof

Flat, #8b8c89, a white parapet 0.35 m high, two plant boxes #a9aaa6.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shop glass | #2b3035 | M_PAVILION |
| Frames, fascia | #1b1d20 | M_STONE |
| Upper band, parapet | #e9e8e3 | M_STONE |
| Strip window | #3b4753 | M_PAVILION + 0.5 |
| Roof | #8b8c89 | M_STONE |
| Y masts | white #eeeeea, blades lit #fff4dc | actors' material, LIT_SIGN |

No new material: the landmarks' surface and the first-scene mesh (+0 draw calls).

## 6. Ground and night

The car stops at each outline. The pasaż's ground is the start box's grey slabs (ground.gdshader
START_BOX). The map's lamps on the pasaż (OSM) become Y masts (map_builder.gd skips them; their
light pools in lights.bin stay), plus three to close the gaps. At night the shop storeys glow
warm, the strip windows cool, the masts' blades lit.

## 7. Detail level and budget

L2, triangle budget 1800 (1522 measured on 2026-11-02, `check_mesh_quality.gd` BUDGET). The
masts and furniture are in first_scene.gd's one mesh (~90 triangles a mast).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism of the outline | 4.2 m tall | y -0.4..3.8 | M_PAVILION #2b3035 | 1 pavilions |
| frames | mullion quads every 2.2 m | 0.14 m wide | round the shop storey | M_STONE #1b1d20 | 1 pavilions |
| fascia | prism of the outline grown 0.9 m, top ring, soffit | 0.4 m | y 3.8..4.2 | M_STONE #1b1d20 | 1 pavilions |
| band | prism of the outline, roof | 3 m | y 4.2..7.2 | M_STONE #e9e8e3 | 1 pavilions |
| strip | prism of the outline grown 0.04 m, frames every 1.5 m | 1.2 m | y 4.9..6.1 | M_PAVILION + 0.5 #3b4753 | 1 pavilions |
| parapet | prism and top ring | 0.35 m | y 7.2..7.55 | M_STONE #e9e8e3 | 1 pavilions |
| plant | two boxes | 1.8 x 1.8 x 1.1 m | roof centre ± (2.2, 0.8) | M_STONE #a9aaa6 | 1 pavilions |
| mast | pole, two arms, two blades | 0.24 m pole, 9.5 m tall, blades 1.5 m | the pasaż's axis, OSM lamps + PASAZ_MASTS | actors' material | 2 masts |
| cafes | café sets, white parasols | 2.6 m | in front of the pavilions | actors' material | 3 ground |
| bollards | rows of 5 across the pasaż | 0.9 m | both ends | actors' material | 3 ground |

F's look check (2026-11-03): slabs light warm grey with balcony bands (slabs.md); Y masts taller and stouter (props.gd add_y_mast); a Christmas tree for a winter event is in BACKLOG.

## 9. Night life (2026-11-19, F's "Warsaw 3 a.m." teaser)

`_wiecha_life` in `landmarks/centre.gd`, one pass per pavilion, all in the site's one mesh (+0 draw
calls, 2346 tris measured, budget 2500). Per bay between two frames (2.2 m): about 70 % are lit
window displays (M_LAMP pane in one of five warm or cool tints, with a dark shelf), the rest stay
dark and shut; on the pasaż-facing front a few bays get a striped awning; each longer face carries
a small light-box word on the fascia (parody words from neon_signs.gd). The first pavilion's front
holds the 24 h kebab hatch: a hot orange window over a counter, an awning, a two-sided blade sign
"KEBAB 24H" and a string of bulbs. No crowd site: the pavilions lie outside the crowds' start box
(x > -880), so customers at the hatch need a place for them there first (BACKLOG).
Not done: umbrellas (the teaser thread's), a night café terrace, reflections beyond the ground shader's lamp pools.
