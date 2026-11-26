# Złota 44: spec

Site key `zlota44` in `game/scripts/landmarks.gd` (TOWERS row `zlota44`, `_build_tower`,
`_zlota_sail`, `_zlota_point`, `_zlota_flare`, `_zlota_garden`; facade skin `S_SAIL` in
`building.gdshader`). Rebuilt 2026-11-02 in a cloud thread from F's two photos (the street view
from the east, by the curved Lumen block; the aerial from the Palace, looking south-west) and the
OpenStreetMap plan and parts in `centrum.json`. Facts: 192 m, 52-54 storeys, Daniel Libeskind,
the "sail" (Żagiel); cladding about 60 % silver aluminium cassettes and 40 % glass (Greisch's
project sheet). No terrain or LoD2 heights were needed: the tower is built from its own numbers.
Values marked *(photo check)* have not been compared on the Mac.

## 1. Identity

1. **The wing**: the south-east corner leans out as the tower climbs, a long concave curve that
   ends in an overhang at the top; at the foot a thin glass wedge, a waist in between.
2. **The tip**: the roof is cut on one slope, so the south-east corner ends in a sharp point,
   the highest thing on the tower.
3. **The crown box**: a darker glazed screen on the north and west part of the roof, nearly as
   high as the tip, set back from the east face.
4. **The white facade**: silver-white cladding in floor bands, the glass between them broken and
   staggered, so the tower reads white with fine grey stripes, never as blue glass.
5. **The podium garden**: a low block in front of the east face with lawn and trees on its roof.

## 2. Massing

World plan (x east, z south). The mapped core: NE (-1469.5, 291.8), SE (-1462.1, 325.6),
SW (-1488.5, 334.8), NW (-1501.1, 298.5), about 30 x 37 m.

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Shaft | the core, east face bowed out 2.5 m, SW and NW corners rounded (r 4 m), lofted through 14 rings | ground to the roof slope | OSM core and the east "192 m" part (the curve) |
| Wing | the SE corner pushed out along (east normal + 0.4 south normal): 2.6 m at the foot, 0 at 64 m, then 9 m x ((h - 64) / 128)^1.7 | 0 to 192 m | photo 2 (left edge), OSM 99 m and 192 m skin parts |
| Roof slope | one plane from the tip (SE corner at the top) down to the north face's middle | 192 m to 150 m | photo 2: the east face's top falls about 35 m |
| Crown box | the roof plan from 45 % of the slope on, 4.5 m back from the east face | from the slope to 184 m | photos 1 and 2 *(photo check: height, extent)* |
| Podium | the mapped low parts (32 m east, 28 m north) | as mapped | OSM parts |

## 3. Facade, base to top

- **Base**: the podium's mapped parts in the same banded skin; the tower runs to the ground on
  the south and west.
- **Shaft**: floors every 3.55 m; per floor a white cassette band (half the floor) and a glass
  slot; each 4.5 m panel picks a tall pane (25 %), the usual slot or a solid panel (14 %), so the
  bands stagger; white mullions every 1.5 m (S_SAIL).
- **Top**: the slope cut with no parapet; the crown box above it in dark glass with fins every
  2.4 m (S_FINS).

## 4. Roof

The sloped roof is glazed in the tower's glass (lighter towards the roof grey); the crown box has
a flat top in a darker blue-grey. No orthophoto in the cloud (Geoportal is blocked), and towers
lean in it anyway, so the plan is OSM's. Aviation lights: three on the crown box, one on the tip.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shaft glass | #bccdd8 | M_SKIN + S_SAIL (cassettes white 0.93) |
| Sloped roof | glass lerped 30 % to #e4e8ea | M_SKIN |
| Crown box | #58788c | M_SKIN + S_FINS |
| Crown top | #58788c lerped 60 % to #e4e8ea | M_STONE |
| Garden | deck, beds, trees as Varso's terraces | M_STONE, M_PAVILION rail |

## 6. Ground and night

The tower stands on the lowest ground under its plan (the site's `g`). At night the apartments
light floor by floor (the skin's lit windows), the crown box stays dark glass, red lights on the
crown and the tip. The garden is lit only by the city's light.

## 7. Detail level and budget

L3 (skyline tower in the hero view from the Palace), triangle budget 1800: the shaft 14 rings x
22 sides (about 570), the slope 40, the crown box 40, lights 50, the podium parts and the garden
about 700. No new materials and no new draw calls (one building mesh).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | lofted rings, 14 | 30 x 37 x 192 | the mapped core | M_SKIN S_SAIL | the white banded tower |
| wing | the SE corner's offset in every ring | 9 m out at the top | SE corner | M_SKIN S_SAIL | the flaring wing |
| slope | one planar cap | 40 x 37 | the top ring | M_SKIN | the sharp tip |
| crown | prism from the slope | about 25 x 30 x 4-34 | north and west of the roof | M_SKIN S_FINS | the crown box |
| lights | five 0.7 m boxes | 0.7 x 0.7 x 0.9 | crown corners and the tip | M_LAMP | night |
| garden | deck, rail, beds, trees, benches | the podium roofs less the tower | the 28-32 m podium | M_STONE | the podium garden |

## Update 2026-11-26 (3D Tiles + Street View pass)

Written by the Opus spec pass for a Sonnet builder with no photos: every observation is a value
below. Sources (reference only, gitignored, never copied, attached or committed):
`refs/tarasy_area/3dtiles/tarasy_area_top.png` (top-down, north up: the roof and the garden; the
tower's top is pushed out by the perspective, 434 / (434 - 192) = 1.79 times, so its roof shows at
about 5.5 px/m, checked against the 30 x 37 m core) and the orbit views h000, h045, h090, h225
(the faces; every orbit frame cuts the tower at about 150 m, so none shows the tip or the crown
from the side), Street View `refs/zlota44/streetview/` (cQ5 h130/h180: the north-east foot, from
about (-1461, 278); vEkL2 h000: the south face and its entrance from Złota, from about
(-1470, 342)).

### Keep (do not change, do not remove, do not re-colour)

- The shaft's loft (`ZLOTA_RINGS`, the four corners, `ZLOTA_CURVE`), the wing (`_zlota_flare`:
  wedge 2.6 m, waist at 64 m, flare 9 m), the cut roof and the tip (`ZLOTA_TIP` 192, `ZLOTA_LOW`
  150) with its red light, the crown box's dark glass walls (S_FINS, `ZLOTA_CROWN` 184,
  `ZLOTA_CROWN_FROM`, `ZLOTA_CROWN_SET`) and the aviation lights.
- The blue LED line up the wing edge (`_zlota_edge_light`, `ZLOTA_EDGE`).
- The S_SAIL skin's white cassette bands, its colours (#bccdd8 glass, #e4e8ea roof) and its share
  of glass (about 40 %).
- The podium garden (`_zlota_garden` through `_varso_garden`: deck, rail, beds, trees, benches).
- Triangle budgets only go up.

### Gaps, ranked by how visible they are (helicopter, then the street iso camera)

| rank | gap | reference | now |
| --- | --- | --- | --- |
| 1 | blue glass along the wing's crease | vEkL2 h000: saturated blue panes in patches on both sides of the diagonal crease, from about 20 m up; h000 orbit: the same darker cells | the crease is as white as the rest |
| 2 | the roof | top view: a pale frame round an open roof full of plant (one big plant block, ducts) | a closed dark-blue lid at 184 m |
| 3 | the south entrance on Złota | vEkL2 h000: a dark double-height lobby (about 12 m wide, 8 m high) in a black portal, a thin white blade canopy over it at about 8 m | the skin runs to the ground |
| 4 | paired glass cells | h000 and h090 orbit, the top view's south face: the dark cells are two floors tall and come in side-by-side pairs, staggered | single-floor tall panes at random |
| 5 | the dark plinth | cQ5 h130/h180: about 4 m of dark grey panels with diagonal joints at the foot | the white skin to the ground |
| 6 | the garden's pool and path | top view: a small pale-blue pool at the garden's north end, a diagonal paved path across the lawn | beds and trees only |
| 7 | the crown's coping | top view: a pale frame along the top of the crown screen | the dark glass ends bare |
| 8 | night at the foot | (follows 3, 6) | the foot is dark |

### Additions, with values

All in the site's one building surface with existing codes (M_SKIN, M_STONE, M_PAVILION,
M_LAMP, M_LAMP + 0.5) and `facade_kit.gd` helpers (`_quad`, `_prism`, `_beam`, `_cap`,
`kit_ledge_ring`); no new material, light, MultiMesh, landmark helper or draw call.

1. **z26_blue** (in `_zlota_sail`, no new triangles): the shaft quads of two edges, the east face's
   last segment (edge index ZLOTA_EAST_SEGS - 1) and the south face's first (ZLOTA_EAST_SEGS),
   from ring index 2 up (above about 10 % of the height), take the glass colour lerped towards
   #5f84b8: 0.55 on even ring indices, 0.35 on odd ones, so the blue reads in patches up the crease.
   The LED line stays on the corner.
2. **z26_well and z26_coping**: the crown box's lid moves from g + 184.0 down to g + 181.0; the
   crown's walls stay to 184; the inner faces of the walls from 181 to 184 are drawn (the box ring
   reversed, same S_FINS mode, #58788c darkened 0.2). A coping on the walls' top:
   `kit_ledge_ring(box, g + 183.6, 0.4, #e4e8ea, 0.05)` (question 2).
3. **z26_plant** inside the well, on the lid: one plant block 12 x 18 m, 2.5 m high (top at
   g + 183.5), centred on the box's centre, its long side along the slope axis, walls
   PAL_PALE_CONCRETE #d4d0c6, top PAL_ROOF_GRAVEL #b9b7b1; 4 duct runs (`_beam` 1.0 m,
   PAL_ALUMINIUM #c3c7ca) at g + 181.6: two along the block's long sides 1.5 m off it, two across
   its ends 1.5 m off it, each clipped to the box minus 1 m. M_STONE.
4. **z26_lobby and z26_portal**: on the foot ring's south face (`_zlota_ring(0.0)`, from the SE
   point towards the SW one), centred at 0.35 of the face's length from the SE end (about
   (-1471.3, 328.8) on the mapped line, pushed out by the wedge on the foot ring), 12 m wide,
   g to g + 8.0: a dark glass quad #2c3a44, M_PAVILION (+0, warm at night), 0.08 m out from the
   skin; a black portal round it, three `_beam`s 0.6 m in PAL_IRON #2a2c2f (two jambs, one head),
   0.25 m proud.
5. **z26_blade**: a canopy prism from g + 8.0 to g + 8.5, 18 m along the south face from the SE
   corner, 3.0 m out from the foot ring's face, its east end cut to a 45 degree point (a 5-point
   plan), colour #e9ecee, M_STONE; under its front edge a 0.15 m strip in #f6e7c2, M_LAMP (lit at
   night).
6. **z26_plinth**: on every edge of the foot ring whose midpoint is outside every mapped podium part
   of the site with h of 20 m or more, and not across the lobby: a band from g - 0.4 to g + 4.2,
   0.25 m proud, as panels 4.5 m wide; each panel's two triangles split along its rising diagonal,
   one in PAL_DARK_GRANITE #4a4744 and one in #4a4744 lightened 0.06 (the diagonal joints), and a
   0.25 m top in #4a4744 lightened 0.12. M_STONE.
7. **z26_cells** (building.gdshader, the S_SAIL branch only; S_SAIL is used by Złota 44 alone, so no
   other building changes, and no new material): hash the tall-pane choice on
   (floor(panel / 2), floor(floor / 2)) instead of (panel, floor), so a tall pane is two panels
   wide (9 m) and two floors high (7.1 m); keep its 25 % share and the solid panels' 14 %.
8. **z26_pool and z26_path** on the 32 m podium part (x -1470..-1446, z 286..326): a pool 5.0 x
   3.6 m centred (-1457.0, 289.0), long side east-west, water #7fc4c0 at the deck + 0.05 in
   M_LAMP + 0.5 (cool glow at night) inside a 0.25 m coping in PAL_PALE_CONCRETE #d4d0c6 to the
   deck + 0.3; a path 2.0 m wide from (-1455.0, 292.0) to (-1450.0, 322.0) at the deck + 0.04
   (y + 0.16) in #d4d0c6, M_STONE, staying under any bed it crosses. Both drawn after the deck,
   with `_no_roof` as the garden does.

### Roof from the top view (tarasy_area_top.png, counted)

| element | count | where | height |
| --- | --- | --- | --- |
| crown frame (coping) | 1 ring | the crown box's outline | 183.6-184 m |
| plant block | 1 | the crown box's centre, about 12 x 18 m | 181-183.5 m |
| duct runs | 4 | round the plant block | 181.6 m |
| the sloped sail face and its overhang edge | KEEP | south-east | to 192 m |
| garden pool | 1 | (-1457, 289), 5 x 3.6 m | 32 m roof |
| garden path | 1 | (-1455, 292) to (-1450, 322) | 32 m roof |
| trees on the garden | none seen in the top view; `_varso_garden`'s trees stay (KEEP) | | |

### Night

The lobby glows warm (M_PAVILION), the blade's front strip glows warm, the pool glows cool. The
blue patches are glass and light with the skin's lit windows like the rest. The well's plant stays
dark; the aviation lights, the tip light and the LED edge are unchanged.

### Budget and shots

L3, triangle budget 2160 (tightened to 1.3x of the measured 1659 at the audit) (was 1800, raise only): blue 0, well inner walls 20, coping 30, plant and
ducts 50, lobby and portal 40, blade 30, plinth about 110, pool and path 30, cells 0: about 310
new. The builder writes the measured count in the BUDGET comment of `check_mesh_quality.gd`; if
the measured count plus 20 % is over 2200, the budget is that number. Draw calls: 0 new (bench
before/after anyway).
Shots: `tools/turntable.sh zlota44` (lit, flat, sil, the top: the well and its plant, the blue
crease on the south and east sides, the plinth), then `tools/shots.sh` at 2532x1170: the street
iso from Złota by the entrance (lobby, blade, blue crease), from the Palace side (east face,
garden), the helicopter over the crown, day and night, runtime and `--prebuilt`.

### Questions (defaults built)

1. The tip and the crown from the side: no source in this pass shows the top 40 m (the orbit
   frames cut the tower); the slope, tip and crown height stay as they are.
2. The crown's closed lid becomes an open well with plant (the top view shows plant inside a
   frame); default: built. F to confirm.
3. The 3D Tiles show the glass greener-grey than #bccdd8; not changed (KEEP colours).
4. How far up the blue patches go: vEkL2 h000 shows them to about 120 m; default: to the top.

### Parts table (new parts of this update)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| z26_blue | colour of existing shaft quads | 2 edges, rings 2 to 13 | the SE crease | M_SKIN S_SAIL, glass lerped to #5f84b8 | 1 the wing |
| z26_well | lid lowered, inner walls | 3 m deep | the crown box | M_SKIN S_FINS #58788c darkened 0.2 | 3 the crown box |
| z26_coping | ring slab | 0.4 m high, 0.05 proud | the crown's top, 183.6 m | M_STONE #e4e8ea | 3 the crown box |
| z26_plant | box and 4 beams | 12 x 18 x 2.5 m, ducts 1.0 m | the crown's centre, 181 m | M_STONE #d4d0c6 / #b9b7b1 / #c3c7ca | 3 the crown box |
| z26_lobby | glass quad | 12 x 8 m | south face, 0.35 from SE, about (-1471.3, 328.8) | M_PAVILION #2c3a44 | 4 the white facade's foot |
| z26_portal | 3 beams | 0.6 m | round the lobby | M_STONE PAL_IRON #2a2c2f | 4 the white facade's foot |
| z26_blade | 5-point prism with a lit front strip | 18 x 3 x 0.5 m at 8 m | south face from the SE corner | M_STONE #e9ecee, M_LAMP #f6e7c2 | 1 the wing |
| z26_plinth | split panels and a top | 4.6 m high, 4.5 m panels, 0.25 proud | the foot ring outside the podium | M_STONE PAL_DARK_GRANITE #4a4744 | 4 the white facade's foot |
| z26_cells | S_SAIL hash change | 9 x 7.1 m tall panes | the whole shaft | M_SKIN S_SAIL | 4 the white facade |
| z26_pool | coping prism and water cap | 5.0 x 3.6 m | (-1457, 289), 32 m roof | M_STONE #d4d0c6, M_LAMP + 0.5 #7fc4c0 | 5 the podium garden |
| z26_path | strip | 2.0 m wide, 30 m long | (-1455, 292) to (-1450, 322) | M_STONE #d4d0c6 | 5 the podium garden |
