# Złote Tarasy: spec

Site key `tarasy` in `game/scripts/landmarks.gd` (`_find_sites`, `_build_tarasy`,
`_tarasy_wave`). Written 2026-10-31 in a cloud thread from the OpenStreetMap parts in
`centrum.json` (the complex is mapped in 3D: eight glass domes for the roof, the mall's podium
parts at 14 to 17 m, the two Lumen wings on the podium, Skylight, the drum and the south
block's terraces, all with heights) and the earlier glass-wave model. The reference photos in
`refs/zlote_tarasy/` live on the Mac and were not reachable from the cloud: the values marked
*(photo check)* are the ones the side-by-side check on the Mac should confirm or move.

## 1. Identity

The Jerde Partnership's mall and offices (opened 2007) between Złota, Emilii Plater, Al. Jana
Pawła II and Warszawa Centralna, south-west of the Palace of Culture. What makes a passer-by
say its name:

1. **The rolling glass roof**: one undulating "bubble" of glass over the mall's atrium,
   highest by the offices (35 m), sweeping down towards the station (22 m and to the plaza).
2. **The terraced mall under it**: floors of shops stepping back under the glass, seen through
   the roof's rim walls, lit warm floor by floor at night.
3. **Lumen**: the office crescent wrapping the mall on Złota and Jana Pawła II, white ribbons
   between silver-blue glass, standing on the mall's podium.
4. **Skylight**: the 105 m tower on the Emilii Plater corner, a rounded blue-green curtain wall
   with a lit glass crown.
5. **The south block's terraces**: the cinema block stepping up from the plaza with a planted
   roof, and the round glass drum on the station side.

## 2. Massing

World plan (x east, z south, metres). The outline `Złote Tarasy` spans x -1581..-1355,
z 339..532. Everything with its centre inside it is the landmark; each part keeps its mapped
outline and heights (mh to h above the site's ground, the lowest terrain under the outline).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Glass wave | 8 domes, centres about (-1495, 409) to (-1432, 440), radii 18-22 m | caps to 35 m (6 domes) and 22 m (2 towards the station), rim a seventh of that | OSM parts #336699 h 35 / 22 |
| Wave floor | the 77-point glass part under the wave's south sweep | 0 to 3 m | OSM part #336699 h 3 |
| Mall podium | the parts round the wave, west, north and east | 0 to 14-17 m | OSM parts h 14-17 |
| Podium plates | the thin parts on the podium by Lumen and Skylight | 17 to 18 and 17 to 27 m | OSM parts |
| Lumen west wing | crescent, x -1548..-1481, z 362..460 | 17 to 55 m | OSM "Lumen" h 55, mh 17 |
| Lumen north wing | crescent, x -1478..-1387, z 355..394 | 17 to 55 m | OSM "Lumen" h 55, mh 17 |
| Skylight | rounded D, x -1413..-1355, z 403..440 | 0 to 105 m, crown to 113 m | OSM "Skylight" h 105 |
| Drum | circle about (-1459, 476), 27 points | 0 to 30 m, rim 30 to 30.5 m | OSM parts |
| South block | the hall at (-1503, 499) and the parts on it | 14 to 35 m, roofs 35 to 41 m | OSM parts |

## 3. Facade, base to top

- **Mall podium (0-17 m)**: sandstone walls with a white grid of golden shop glass (skin
  S_GRID), the bottom 4.5 m a lit lobby band (shopfronts). The planted terraces' parts
  (mapped #6EBE9F) the same walls under a green roof.
- **Wave rim**: where the wave stands clear of the ground, glass walls from the ground to the
  roof (M_PAVILION): mullions every 1.6 m, a floor every 4.2 m, lit warm bay by bay at night:
  the terraces of shops seen through the glass.
- **Lumen (17-55 m)**: horizontal white ribbons every 3.2 m between silver-blue glass, thin
  mullions every 3 m (skin S_RIBBON) *(photo check: the ribbons' share, the ends)*.
- **Skylight (0-105 m)**: blue-green curtain wall with silver floor bands and 1.5 m mullions
  (skin S_BANDS); the crown: the curtain wall carried 8 m above the roof and leaning in by 18 %
  of the way to the centre, glass lit cool white at night *(photo check: the crown's height
  and lean)*.
- **Drum (0-30 m)**: golden glass lit warm from inside, a sandstone rim on top.
- **Red boxes**: the small mapped parts at the Jana Pawła II entrance (mapped tomato), plain
  red stone *(photo check: what they are)*.

## 4. Roof

The glass wave: one surface over the eight domes, each a cap rising to its mapped height,
blended where they overlap so the roof rolls instead of creasing, on a 3 m grid, laid on the
ground's slope; a white diamond lattice every 3.4 m in the shader (M_GLASS_ROOF). The wave
floor's top in the same glass, so the roof reads as sweeping down to the plaza. Podium roofs
flat grey (#a49d90), the south block's terraces planted, Lumen's and Skylight's roofs flat grey.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass wave and the wave floor's top | #d4b066 (golden glass, the landmarks loop) | M_GLASS_ROOF |
| Wave rim walls, wave floor walls | #b9a983 | M_PAVILION (+0, warm at night) |
| Podium walls | #d9c7a0 sandstone, glass #c8b27e | M_SKIN S_GRID |
| Podium roofs | #a49d90 | M_STONE |
| Planted terraces' roofs | #8a9a72 | M_STONE |
| Lumen | glass #9fb0b8, roof #8e9497 | M_SKIN S_RIBBON |
| Skylight | glass #6f9cb0, roof #a7b3b8 | M_SKIN S_BANDS |
| Skylight's crown | #b9d2dc | M_PAVILION (+0.5, cool at night) |
| Drum | #c9b98f, rim #d9c7a0 | M_PAVILION (+0), M_STONE |
| Red boxes | #c0624c | M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

The plaza and the paths on the station side stay the map's. The car collides along the wave's
rim and along every part standing on the ground (as the map's buildings did). At night the
wave glows warm through its lattice, its rim walls and the drum glow floor by floor, Lumen's
and Skylight's offices are lit in their skins' share, Skylight's crown glows cool white over
the skyline. Card: "Złote Tarasy", PL "Centrum handlowe pod falującym szklanym dachem, obok
biurowce Lumen i Skylight. Otwarte w 2007 roku.", EN "A shopping centre under a rolling glass
roof, with the Lumen and Skylight office buildings. Opened in 2007."

## 7. Detail level and budget

L3 (a first-scene hero), triangle budget 5700 (4762 measured after the build, plus about 20 %,
in `check_mesh_quality.gd` BUDGET; the wave alone is about 2400). The podium, Lumen and
Skylight were drawn before as the map's plain buildings, so the city gains far fewer than the
difference. Shots: `--solo=tarasy --solo-look=sil` and `flat` (the `first` set), then in the
city at day and night from the station side.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wave | height field over 8 domes, 3 m grid | about 110 x 90 m, 22-35 m | the domes | M_GLASS_ROOF #d4b066 | 1 glass roof |
| rim | glass walls round the wave's edge | ground to the wave | where the wave stands clear | M_PAVILION #b9a983 | 2 terraces seen through |
| floor | mapped prism | 0-3 m | the 77-point part under the south sweep | M_PAVILION walls, M_GLASS_ROOF top | 1 glass roof |
| podium | mapped prisms | 0-14/17 m | round the wave | M_SKIN S_GRID #d9c7a0 / #c8b27e | 2 terraced mall |
| terraces | mapped prisms, green tops | 0-17, 35-41 m | west side, south block | M_SKIN S_GRID, roof #8a9a72 | 5 south terraces |
| lumen | 2 mapped crescents | 17-55 m | Złota and Jana Pawła II | M_SKIN S_RIBBON #9fb0b8 | 3 Lumen |
| skylight | mapped prism | 0-105 m | Emilii Plater corner | M_SKIN S_BANDS #6f9cb0 | 4 Skylight |
| crown | frustum, 18 % in | 105-113 m | on Skylight | M_PAVILION +0.5 #b9d2dc | 4 Skylight |
| drum | mapped cylinder and rim | 0-30.5 m | (-1459, 476) | M_PAVILION #c9b98f, rim M_STONE | 5 drum |
| red | mapped prisms | 0-11 m | Jana Pawła II entrance | M_STONE #c0624c | 5 entrance |

## Update 2026-11-05 (F's photos + the Mac gather, refs/skylight/REPORT.md)

- **Skylight** (`_tarasy_skylight`): light silver-grey cladding with a dark window dash per floor (not
  a blue-green curtain wall); 26 floors of about 3.3 m, 105 m as mapped; dark lobby glass with a 5 m
  canopy; a 4-floor glazed belt at 20-33 m. The lit glass frustum crown is gone: the east half
  of the roof stays at 105 m, the west half is scooped to 100 m with an oval glass cap.
- **The screen block**: the mapped plate over the entrance (x -1409..-1368, z 437..449) is a graphite
  box 17 to 38 m; the 3D LED screen (`tarasy_screen.gd`) hangs on its south face and curved west
  return, an L in plan, 44 x 20 m.

## Update 2026-11-11 (F: "it's actually blue glass", the screen is an L on the corner)

From F's 19 photos and an aerial view (reference only, never in the repo) and the orthophoto:

- **The wave** (`_tarasy_wave`): blue-grey glass, not gold. Its lattice is now equilateral triangles of
  about 3.2 m (rows offset half a pane), each pane flat with its own normal and a little colour of its
  own (a few in sky-pale glass), white steel bars along the pane edges (building.gdshader `glass_roof`'s
  pane mode, branchless: the budget stays at 502 of 505). The eight domes stand at different heights
  (21-36 m) so the silhouette is asymmetric, highest over the middle and falling to the south sweep.
  At night the bars glow pale blue and the panes warm.
- **The screen** (`tarasy_screen.gd`): moved from the plate's west end, where it curved, to Skylight's
  south-east corner over the street entrance: an L of two flat faces, the wide one (17 m) facing the
  station and the crossing, the return (10 m) facing Emilii Plater, 11.5 to 25 m up. The loop
  (`led_screen.gdshader`) is the tabby cat leaning out (its tail round the corner), the game's own
  promo (AROUND WARSAW over a striped sunset and a skyline with the Palace on the return) and the
  NOSE. agency's blue blocky mark popping out of a light box (F asked for it by name). The flowers are
  gone. The plate under it is a plain grey box again, with the mall's gold name on it as a parody
  (ZŁOTE big, TARASKI small).
- **The sunken plaza** on the station side (looked like a hole: the 10 m terrain grid had a pit there):
  a SUNKEN ring (`map_builder.gd` "tarasy_plaza", style `shops`) 6 m under the street, brick retaining
  walls with lit shopfronts along their foot, railings round the top, umbrellas on the floor; the grand
  stair from Emilii Plater down its east side ("tarasy_stair"); the grid nodes round it held up to the
  street (`GRID_HOLD`) so the terraces and pavements stay level.
- **The guitar** (`_tarasy_guitar`) at the Emilii Plater corner: a red guitar sign about 11 m tall on a
  black foot, cream badge "HARD BLOK CAFE" (parody), and the café's own sign over its terrace along the
  podium's south face with four white umbrellas (`_tarasy_cafe`).

## Update 2026-11-11 (2): the whole complex (F: "not only the roof")

- **Ground level.** The site's height is the median ground of its zone (`_median_ground`), not the lowest
  point: the car park ramp dips the zone to about 11 m while the streets are 14-16 m, and the shop floor sat
  under the pavement.
- **The podium** (`_tarasy_podium`): a 4.6 m glass shop floor over each part's mean ground (pavilion glass,
  lit warm at night), then sand stone (#dccaa2) to the terrace in the re-clad skin (S_PUNCHED: pale bands
  with punched windows, so the mass is not a blank block by day and has lit windows at night). Planted terraces get a 1.1 m glass rail.
- **Ledges** (`_tarasy_ledges`, `_tarasy_ledge`): the podium parts that span a level are merged into one ring,
  simplified (short and near-straight edges dropped, so no slivers fight) and drawn as a top and a front
  only: a 1.5 m canopy over the shops whose front is a warm lit strip (#f6e7c2) under a dark top, a pale
  ledge at 9.8 m and a cornice at 15.9 m.
- **Lumen** (`_tarasy_lumen`): ribbon glass (#7ea3c0) to 3.6 m under the top, a 1 m white parapet, the top
  floor stepped back 2.2 m, a plant box stepped back 6 m.
- **The drum**: blue-grey pavilion glass (#7f9fb4), warm from inside at night, with the deck roof.
- **Shop boards** (`_tarasy_shops`, `TARASY_BOARDS`): lit boards over the canopy with parody names: ZARAZA
  (black) and H·M·M (red) by the Emilii Plater entrance, MULTIKINKO (pink) on the Złota side, a red
  WYPRZEDAŻ banner on the station side. The mall's name is bigger (ZŁOTE at 1.2, TARASKI at 0.7).
- Budget: 9400 triangles for the site (7781 measured on the flat stub map).

## Update 2026-11-26 (3D Tiles + Street View pass)

Written by the Opus spec pass for a Sonnet builder with no photos: every observation is a value
below. Sources (reference only, gitignored, never copied, attached or committed):
`refs/tarasy_area/3dtiles/tarasy_area_top.png` (top-down, north up: the roof source) and the
eight orbit views `tarasy_area_h000..h315.png` (pitch -35, range 377 m; the towers' tops are cut
off by the frame), Street View `refs/tarasy/streetview/` (JD_1pya h000/h045: the station side;
p0yx h225/h270: the Emilii Plater entrance; vEkL2 h180: the Złota entrance; XGgOr h090 is the
car-park tunnel, ignored), `refs/skylight/streetview/` (Y9zv: Skylight and the screen from
Emilii Plater; ySX: inside the wave, the white triangle lattice).

**Top view scale (measured, use it to place anything else).** The top view is centred on game
(-1468, 412) and spans about 520 m across its 1600 px, not +-145 m: ground scale 3.07 px/m at
full size, and a thing at height h is pushed out from the centre by 434 / (434 - h). Checked on
four known plans: the drum's centre (-1459, 476), the teal box's four corners against its mapped
part (within 2 m), the white egg (-1510, 517) and Skylight's roof outline.

**What the first reading got right and wrong.** (a) Right: two teal (verdigris) roofs, but they
are the mapped parts coloured #6EBE9F: the big one is a box on the cinema hall's roof (35-40 m,
about 40 x 48 m, a very low hip, not 40 x 30 m), the "sliver" is a curved roof over the
Jana Pawła II wing on the WEST edge (not Emilii Plater, which is the east). Both are now drawn as
planted green terraces with a glass rail. (b) There is one white egg (the mapped #dddddd part on
the hall's roof, 11 x 16 m), not two domes; the other white oval is the drum's white ring, and the
third white thing is Skylight's roof cap. (c) Right: the drum's top is a white ring round a blue
glass oculus. (d) The wave shows 8 to 9 high points: the model's 8 domes match, no change.
(e) Right: two Lumen arcs; the striped band seen along their inner edges in the top view is their
courtyard facade foreshortened by the camera's perspective, not a roof element. (f) Right: the
hall's roofs are dark brown-grey with small vents. (g) Skylight's scooped roof and cap exist
already (see questions). (h) Złota 44: in its own spec.

### Keep (do not change, do not remove, do not re-colour)

- The 3D LED screen (`tarasy_screen.gd`, `led_screen.gdshader`) and its graphite block with the gold
  ZŁOTE / TARASKI names (`_tarasy_screen_block`, `_tarasy_signs`).
- The sunken plaza and the grand stair (`map_builder.gd` "tarasy_plaza", "tarasy_stair",
  `GRID_HOLD`, `_tarasy_plaza_dress` umbrellas).
- The guitar sign and the café with its umbrellas (`_tarasy_guitar`, `_tarasy_cafe`).
- The lit shop boards and their words (`TARASY_BOARDS`, `_tarasy_shops`).
- The wave: 8 domes, `TARASY_DOME_H`, the triangle-lattice pane mode (M_GLASS_ROOF + 0.5), its
  rim walls and the glass floor of the south sweep (`_tarasy_wave`).
- The podium's shop band (`_tarasy_podium` shop floor, TARASY_SHOP_H 4.6) and the three ledges
  (`TARASY_LEDGES`, `_tarasy_ledges`): every podium part stays in the `podium` array.
- Lumen's stepped top (`_tarasy_lumen`: parapet, 2.2 m setback, plant screen), Skylight
  (`_tarasy_skylight`, its cap and plant), the drum's walls, deck and rim (the oculus crown below
  is added on top of them), the red entrance boxes, the inner courtyard garden.
- Triangle budgets only go up.

### Gaps, ranked by how visible they are (helicopter, then the street iso camera)

| rank | gap | reference | now |
| --- | --- | --- | --- |
| 1 | the teal box on the hall (1876 m2 at 35-40 m, the biggest single colour field after the wave) | top, h000-h315: verdigris metal box, plain teal walls, a very low hip roof with faint fold lines, no rail | sandstone S_PUNCHED walls, green flat roof, glass rail |
| 2 | the drum's top | top, h000, h090: white ring of 20 panels, blue glass oculus with 16 white ribs and a small white hub | flat deck #a49d90 and a sandstone disc |
| 3 | the white egg on the hall's south-west roof | top, h000, h045: white half-ellipsoid, 11 x 16 m, about 6 m high | a 6 m sandstone box |
| 4 | the station-side glass band (14-35 m strip along the south curve) | JD h000/h045, h000: curved blue-grey glass with white floor bands, cantilevered about 3.5 m over the sandstone base on a white rounded soffit; two big blue parking "P" panels | sandstone S_PUNCHED, no soffit |
| 5 | the Jana Pawła II wing (west, 0-17 m) | h090, h045, top: teal glass walls, a teal roof that rolls down to a rounded eave on the street | sandstone walls, green flat roof, rail |
| 6 | the hall's flat roofs | top, h045: dark brown-grey membrane, 10 small dark vents | pale #a49d90 |
| 7 | Lumen's roofs | top: west arc 8 plant units in a row plus a lift overrun at its north end and 2 small boxes at its south end; north arc a long pale plant shed at its west end with 6 dark panels east of it | only the setback and parapet |
| 8 | the entrances' brick panels | vEkL2 h180 (Złota): a recessed red-brick panel with the mall's gold name; p0yx h225/h270 (Emilii Plater): a brick panel behind the shop names | sandstone only |
| 9 | the cinema name high on the hall's west face | h045, h090: big pink letters about 27 m up, facing Jana Pawła II | only the low MULTIKINKO board on the south |
| 10 | the lift box's open steel grid on top (south-east of the hall) | top, h000 | a plain roof |

### Additions, with values

All parts go into the site's one building surface through the existing material codes (M_STONE,
M_PAVILION, M_SKIN, M_GLASS_ROOF, M_LAMP) and the existing helpers of `facade_kit.gd`
(`_prism`, `_frustum`, `_pyramid`, `_soffit`, `_beam`, `_quad`, `kit_ledge_ring`); signs through
the existing `signs` list (words already in `neon_signs.gd`: P, ZŁOTE, TARASKI, MULTIKINKO).
No new material, light, MultiMesh, helper of the landmark's own or draw call. Colours are the
photo's mapped to the calmer palette (PAL_* where one fits, else the hex given).

1. **t26_teal_box** (the mapped part #6EBE9F, mh 35, h 40, 13 points, x -1544..-1485, z 461..512;
   match it by colour and mh 35). Walls from g + 35 to g + 40 in PAL_PATINA_COPPER #6f9a8a, M_STONE
   (plain metal, no skin). A fascia: `kit_ledge_ring(outline, g + 39.4, 0.6, #8cc0b2, 0.15)`.
   The roof: `_pyramid(outline, g + 40, g + 41.8, #82b8aa)` (13 facets: the fold lines of the low
   hip read as in the top view). No glass rail on this part (question 1). It stays in `podium`.
2. **t26_drum_crown** on the drum (centre (-1459, 476), radius 12.9). A white ring: `_frustum` from
   a 20-gon of radius 12.9 at g + 30.0 to a 20-gon of radius 7.2 at g + 31.4, colour PAL_WHITE_STONE
   #ebe8df, M_STONE, every second facet 6 % darker (the 20 panels). The oculus: a shallow 16-sided
   cone from radius 7.2 at g + 31.4 to the centre at g + 32.4 in TARASY_WAVE #4a74a6, M_GLASS_ROOF
   (plain, not the pane mode); 16 white ribs (`_beam`, 0.35 m, #ebe8df) from the ring's inner
   edge to the centre, 0.15 m over the glass; a white hub, a 10-gon of radius 1.0 at g + 32.55.
   The drum's own deck and rim stay in the mesh under it.
3. **t26_egg** (the mapped part #dddddd, mh 35, h 41, centre (-1509.5, 517), x -1515..-1504,
   z 509..525): instead of its prism, a half-ellipsoid with semi-axes 5.5 m (x) and 8.0 m (z),
   6.0 m high from g + 35: 20 sides, bands at height fractions 0, 0.35, 0.62, 0.82, 0.95 with the
   radius scaled by sqrt(1 - t^2) (1.0, 0.937, 0.785, 0.572, 0.312), then a cone to the apex at
   g + 41 (stacked `_frustum` calls of a scaled `_circle`). Colour #eceeed, each band 3 % darker
   towards the foot, M_STONE. Not in `podium` (it spans no ledge level).
4. **t26_south_band** (the mapped part #669999, mh 14, h 35, 29 points, the 3.3 m strip along the
   south curve z 512..532). Walls TARASY_DRUM_GLASS #7f9fb4 in M_SKIN + S_RIBBON / 16 (Lumen's
   ribbon skin: white floor bands between glass), roof #6b625a (as t26_roofs). Under it a white
   soffit `_soffit(outline, g + 14.0, #e6e8e6)` and a rounded fascia
   `kit_ledge_ring(outline, g + 13.0, 1.0, #e9ebea, 0.3)` (question 2).
   Two parking boards, M_LAMP, colour #2f5d9e, 7.0 m wide, 6.0 m tall, bottom at g + 22.0, 0.3 m
   out from the glass: P1 centre (-1507.5, 529.3) facing (-0.27, 0.96), P2 centre (-1488.5, 531.6)
   facing (0.20, 0.98); on each a sign "P", white, sized so the letter is about 4.5 m tall
   (compare ZŁOTE at 1.2 on the screen block), centred on the board.
5. **t26_wing** (the mapped part #6EBE9F, mh 0, h 17, 23 points, x -1581..-1552, z 406..453,
   along Jana Pawła II). The shop floor and the three ledges stay. Over the shop floor, walls to
   g + 16.2 in teal glass #6f9a8a, M_PAVILION (+0, warm at night) instead of the sandstone skin.
   The roof rolls over the 15.9 m cornice (which becomes its eave lip): `_frustum` from the outline
   at g + 16.2 to the outline offset -1.5 m at g + 17.4 (#7aaea0), then to the outline offset
   -3.0 m (fall back to -2.0 if the offset is empty) at g + 18.0 (#82b8aa), capped in #82b8aa,
   M_STONE. No rail on it (question 1). The two small #6EBE9F entrance parts by the red boxes
   (mh 4 and mh 9) keep their look.
6. **t26_roofs and t26_vents**: the hall's roof (the part kind "hall", mh 14, h 35) and the plate on
   it (mh 35, h 36, x -1528..-1453, z 489..528) get roof colour #6b625a (dark brown-grey membrane)
   instead of TARASY_DECK. On them 10 vents, boxes 1.2 x 1.2 x 0.9 m in PAL_DARK_STEEL #4a4e52,
   M_STONE, on the roof under each point: plate (-1485.9, 502.3), (-1474.0, 509.8),
   (-1459.8, 506.0), (-1493.4, 516.5), (-1465.8, 521.7), (-1484.4, 526.9); hall roof
   (-1478.4, 481.4), (-1475.5, 485.1), (-1468.7, 488.9), (-1483.0, 486.0). Skip a point that falls
   inside the teal box or the egg.
7. **t26_lumen_plant** on the two Lumen roofs (g + 55, on the inset top floor, never on the
   2.2 m step). West arc: 8 units 6.5 m along the arc x 4.5 m across x 2.0 m, walls PAL_ALUMINIUM
   #c3c7ca, tops PAL_ROOF_PALE #9a9c9c, M_STONE, centred 5.0 m in from the outer (west) wall,
   their long side along the arc, at 8 m pitch starting 6 m from the arc's north end; a lift
   overrun 9 x 7 x 3.5 m in PAL_PALE_CONCRETE #d4d0c6 at the north end (where the two arcs meet);
   2 boxes 3 x 3 x 1.5 m in #c3c7ca at the south end, 4 m apart. North arc: a plant shed
   26 x 10 x 3.0 m centred (-1449, 364), long side along the arc, walls PAL_ROOF_GRAVEL #b9b7b1,
   top #c3c7ca; east of it 6 panels 4 x 2 m tilted 15 degrees up to the south (their high edge
   0.9 m over the roof), PAL_GLASS_NAVY #3e4d5a, 1 m apart, the first 2 m east of the shed. Clip
   every footprint to the inset top floor; drop one that loses more than half its area.
8. **t26_brick** panels, PLAZA_BRICK #9c5a46, M_STONE, each a quad 0.1 m in front of the wall with a
   0.4 m frame of four quads in TARASY_STONE darkened 0.15 (the recess): Złota entrance, centre
   x -1470 on the podium's north wall (snap: the first podium wall south of (-1470, 330),
   z about 343), facing north (0, -1), 12 m wide, g + 5.0 to g + 13.5; on it the signs "ZŁOTE"
   (1.0) at g + 10.0 and "TARASKI" (0.6) at g + 8.2, TARASY_GOLD. Emilii Plater entrance: centre
   (-1362.0, 448.5), facing (0.94, -0.34), 14 m wide, g + 4.8 to g + 15.0, 0.12 m out from the wall,
   behind the ZARAZA and H·M·M boards (0.25 m out), which stay in front.
9. **t26_cinema_sign**: "MULTIKINKO", pink #e0457b, size 1.6, at (-1535.0, 497.0), g + 27.0,
   facing (-0.94, 0.33) (the hall's west face under the teal box, towards Jana Pawła II).
10. **t26_grid** on the lift box (the mapped part #BAC1C7, mh 14, h 28, x -1460..-1434,
   z 489..512): 3 beams east-west and 3 north-south, `_beam` 0.4 m, PAL_ALUMINIUM #c3c7ca, lying
   at g + 28.6 from edge to edge of its roof at the quarter points.

### Roof from the top view (tarasy_area_top.png, counted)

| element | count | where (game x, z) | height |
| --- | --- | --- | --- |
| wave domes (high points) | 8 (a 9th reading is the south sweep) | as mapped | KEEP |
| teal box, low hip | 1 | corners (-1545, 466), (-1506, 461), (-1486, 498), (-1530, 513) | 35-41.8 m |
| teal wing roof | 1 | x -1581..-1552, z 406..453 | eave 16.2, top 18 m |
| white egg | 1 | (-1509.5, 517) | 35-41 m |
| drum: ring panels, oculus ribs, hub | 20, 16, 1 | centre (-1459, 476); ring outer r 12.9, oculus r 7.2 | 30-32.5 m |
| hall roof vents | 10 | t26_vents | 35-36.9 m |
| Lumen west plant units, overrun, small boxes | 8, 1, 2 | t26_lumen_plant | 55-58.5 m |
| Lumen north shed, dark panels | 1, 6 | t26_lumen_plant | 55-58 m |
| lift box grid beams | 6 | (-1447, 500) | 28.6 m |
| Skylight roof cap | 1 | seen at about (-1404, 430), white; modelled at (-1396, 418) in glass | question 3 |

### Night

The teal wing's glass (M_PAVILION) glows warm floor by floor; the south band's glass lights in
its ribbon skin's share; the two P boards and the high MULTIKINKO glow (board M_LAMP, sign tubes);
the brick panels' gold names glow (signs are night-only, as the existing ones); the drum's oculus
glows warm through M_GLASS_ROOF like the wave. The egg, the teal box, the vents, the plant and the
grid stay unlit. No new light.

### Budget and shots

L3 (exception, named since 2026-11-11: the whole complex is one site). Estimated new triangles:
teal box 65, wing roof 115, egg +130 net, drum crown 215, south band 150, vents 100, Lumen plant
180, brick panels 20, grid 60: about 1035, so about 8820 measured on the flat stub map. Raise
`"tarasy"` in `check_mesh_quality.gd` BUDGET from 9400 to 10600 (the builder writes the measured
number in its comment; never lower). `tarasy_plaza` 2750 is untouched. Draw calls: 0 new (bench
before/after anyway, CLAUDE.md "Performance is a gate").
Shots: `tools/turntable.sh tarasy` (lit, flat, sil, the top: check the teal box, the egg, the
drum's ring from the top tile; the KEEP items unchanged against a before sheet), then city shots
with `tools/shots.sh` at 2532x1170: the helicopter over the complex, the street iso from the
station side (P boards, soffit, drum), from Jana Pawła II (wing, cinema name), from Złota (brick
panel), each by day and night, runtime and `--prebuilt`.

### Questions (defaults built)

1. The teal box and the wing lose their glass rail and green roof (the references show teal metal
   and no rail on both, in all nine 3D views); default: built as written; every other planted part
   keeps its rail. F to confirm it is not "a lost detail".
2. The station-side band changes from sandstone to glass (JD and h000 agree); default: built.
3. Skylight's roof cap: the top view shows it white and opaque at about (-1404, 430), 10 x 6 m,
   8-12 m from where it is modelled in glass; not changed (KEEP).
4. Skylight's shaft: the 2026-08 Street View (Y9zv) reads dark blue glass with a light grid, the
   2026-11-05 update made it silver-grey from the Mac photos; not changed (KEEP).
5. Is the white egg lit at night? Default: unlit.

### Parts table (new parts of this update)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| t26_teal_box | mapped prism, fascia ring, 13-facet low pyramid | about 40 x 48 m, 35-41.8 m | x -1544..-1485, z 461..512 | M_STONE #6f9a8a walls, #8cc0b2 fascia, #82b8aa roof | 5 south block |
| t26_drum_crown | 20-gon frustum ring, 16-gon cone, 16 beams, 10-gon hub | r 12.9 to 7.2, 30-32.55 m | centre (-1459, 476) | M_STONE #ebe8df, M_GLASS_ROOF #4a74a6 | 5 drum |
| t26_egg | half-ellipsoid, 20 sides, 5 bands and an apex cone | 11 x 16 x 6 m | (-1509.5, 517) on the hall | M_STONE #eceeed | 5 south block |
| t26_south_band | mapped strip re-skinned, soffit, fascia ring | 3.3 m deep, 14-35 m, fascia 1.0 m | the south curve, z 512..532 | M_SKIN S_RIBBON #7f9fb4, M_STONE #e6e8e6 / #e9ebea | 2 terraced mall |
| t26_p_boards | 2 lit boards with a P sign | 7 x 6 m, bottom 22 m | (-1507.5, 529.3), (-1488.5, 531.6) | M_LAMP #2f5d9e, sign white | 2 terraced mall |
| t26_wing | teal glass walls, 2-step frustum roof | 8 m deep, walls to 16.2 m, roof to 18 m | x -1581..-1552, z 406..453 | M_PAVILION #6f9a8a, M_STONE #7aaea0 / #82b8aa | 2 terraced mall |
| t26_roofs | roof colour of two mapped parts | the hall and its plate | x -1548..-1453, z 457..528 | M_STONE #6b625a | 5 south block |
| t26_vents | 10 boxes | 1.2 x 1.2 x 0.9 m | the 10 listed points | M_STONE PAL_DARK_STEEL #4a4e52 | 5 south block |
| t26_lumen_plant | 11 boxes on the west arc, a shed and 6 tilted panels on the north arc | units 6.5 x 4.5 x 2, overrun 9 x 7 x 3.5, shed 26 x 10 x 3, panels 4 x 2 | Lumen roofs at 55 m | M_STONE #c3c7ca / #9a9c9c / #d4d0c6 / #b9b7b1 / #3e4d5a | 3 Lumen |
| t26_brick | 2 recessed quads with frames, gold signs on one | 12 x 8.5 m and 14 x 10.2 m | Złota x -1470; Emilii Plater (-1362, 448.5) | M_STONE #9c5a46, signs TARASY_GOLD | 2 terraced mall |
| t26_cinema_sign | sign MULTIKINKO | size 1.6 | (-1535, 497), 27 m | sign #e0457b | 5 south block |
| t26_grid | 6 beams | 0.4 m, edge to edge | lift box roof, 28.6 m | M_STONE #c3c7ca | 5 south block |
