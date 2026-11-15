# Forest (Burakowska / Aleja Jana Pawła II): spec

Site key `forest` in `game/scripts/landmarks.gd` (`_find_forest`, `_build_forest`, `_forest_tower`,
`_forest_wing`, `_forest_fins`, `_forest_sign`, `_forest_garden`, `_forest_terrace`,
`_forest_courtyard`). Rebuilt 2026-11-03 from F's seven photos (the tower from the street, the
tower's crown at dusk, the wings from Burakowska, two aerials of the roof gardens, the courtyard
from above, a corten planter bed from above; copies in the project files, `forest/photos/`), the
OSM parts and public facts (HRA Architekci, finished 2022, tower 120 m and 29 storeys, the wings
6 to 8 storeys). The tenant's real name is never used: the crown says PEPEO ŻUBR, F's parody.

## 1. Identity

1. **The tower**: dark green-black glass in three slabs that step up to the east, each under a
   dark crown band; the east slab hung with orange, red and green vertical fins.
2. **PEPEO ŻUBR** in white in the east slab's crown band.
3. **The wings**: glass behind dense multicoloured fins (orange most of all), a black-clad top
   storey set back over a planted ledge, and green roofs with corten planters and timber decks.
4. **The courtyard**: young trees, curved grass steps (an amphitheatre) and a corten pavilion.

## 2. Massing

From the four OSM parts of 20 m and more in FOREST_BOX: the tower (120 m, about 51 x 37 m) cut
along its long axis into slabs at u 17 and 34 m, tops 110, 115.5 and 120 m (the photos' step); the
U-shaped west and south wing (OSM 20.8 m), the north wing (OSM 20.8 m) and the north-east wing (27.4 m,
the terrace). The two low wings are built 31 m high, eight storeys estimated from F's photos (F,
2026-11-03), not OSM's 20.8 m; the terrace wing keeps 27.4 m for its crowd. Wings: glass to 4 m
under the top, then the black storey set back 1.6 m.

## 3. Facade, base to top

- Tower glass #3f5552 (M_SKIN S_FINS: mullions and floor lines), 0..top-6 m; crown band #2b2d2f
  (M_SKIN S_DARK) the top 6 m of each slab.
- Fins: flat coloured blades 0.32 m wide, 12 cm proud, from 4.5 m up to the crown band: every
  1.25 m on the east slab's faces, every 3.6 m on the two lower slabs (the photos' faint colour).
- Wings: glass #55707a (M_SKIN S_FINS) to top-4 m with blades every 1.5 m from 4 m up; a 0.7 m
  hedge on the ledge; the black storey (M_SKIN S_DARK) above.
- Fin colours (hashed by position): oranges #e07a2a #d0601f #e8923a, reds #b8322a #c4452a, greens
  #6f8f3a #86a046, mustard #d9a32b, brown #7a4a2a.
- PEPEO ŻUBR: neon word, white #fff7e6, scale 1.6 (about 19 m) on the east face and 1.15 on the
  south and north faces, 0.6 m over the crown band's foot.

## 4. Roof

- Tower: a 4.4 m plant box 2.4 m high on each slab.
- Roof gardens as they are (F, 2026-11-15; four photos of the public green roof: Corten planters and
  pavilions, lawn, wavy shrub beds, a black louvred top storey, black railing with corten posts, a
  white stretch tent): on the black storey's roof of each low wing a lawn #6fa04a, a dark paved walk
  (#5b5e61, 1.8 m) inside the black railing (corten posts every 4 m, black rails), wavy corten-edged
  beds 1.7 m wide along the edges (silver-green and deep-green shrub in turn, young trees every ~9 m),
  and in the middle of each wide piece a corten pavilion 5.6 x 3.6 x 3.3 m with a glass front, a dark
  coping and a gravel roof. The ledge over the glass is a low sedum carpet, not a hedge.
- The tallest slab also carries a 10 m cobalt-blue motor bowrider on a steel cradle (F's joke, 2026-11-06; `_forest_boat`): white hull with a blue sheer, windshield, seats, sun pad, turned 25 degrees, clear of the plant box and the crown sign. About 120 triangles, no new draw call.
- The 27.4 m wing, the free public terrace: a grey deck inside the black railing, the wavy beds along
  it, a lawn strip across, a corten pavilion with a glass front at the south end, a white stretch tent
  (two peaks on poles) over high tables at the north end, patio heaters down the deck; crowd
  `forest_terrace` 11-23 h as before (all of it out of the roof grid).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tower glass | #3f5552 | M_SKIN S_FINS |
| Wing glass | #55707a | M_SKIN S_FINS |
| Crown bands, black storeys | #2b2d2f | M_SKIN S_DARK |
| Fins | nine colours above | M_STONE |
| Planters, pavilion | #8e4a24 corten | M_STONE |
| Stair houses | #9b5b36 copper | M_STONE |
| Decks | #a98457 | M_STONE |
| Roofs, ledges | #5d8f45 | M_STONE |

## 6. Ground and night

The courtyard, placed from the mapped paths, grass and fountain (every piece 1.8 m clear of
them): the amphitheatre at (-3051, -2403.5), four grass steps 1.2 m deep and 0.4 m up on arcs from
110 to 250 degrees opening east to the fountain, timber edges, three benches in front; the corten
pavilion (8 sides, r 3.2 m, 3.2 m, planted roof) at (-2973.5, -2398.5); 43 young trees 5 to 7.5 m
(slim trunk, five-sided crown) 6 m apart. Car walls: every part's mapped outline (`_collide`, also
handed to `pocket_rings`), the amphitheatre's top step, the pavilion, each trunk. At night the
glass shows the skins' lit windows; PEPEO ŻUBR is a neon word.

## 7. Detail level and budget

L2, triangle budget 8100 (an exception to the L2 limit: four buildings, their fins, the real green roofs and a
courtyard of 43 trees in one site; 6739 measured plus 20 %, one landmark mesh, no new draw call). Shots: `--at=-2905,-2330 --yaw=200`, the courtyard `--at=-3010,-2398 --lift=10`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| slabs | 3 prisms of the outline | 110, 115.5, 120 m | tower, u 0..17..34..51 | M_SKIN S_FINS | 1 tower |
| crowns | 3 prisms | 6 m | slab tops | M_SKIN S_DARK | 1 tower |
| tower fins | blades | 0.32 m, every 1.25 / 3.6 m | slab faces | M_STONE | 1 tower |
| sign | 3 neon words | 19 m, 13 m | east slab crown | neon | 2 sign |
| wing glass | prisms of the outlines | to top-4 m | 3 wings | M_SKIN S_FINS | 3 wings |
| wing fins | blades | 0.34 m, every 1.5 m | wing faces | M_STONE | 3 wings |
| black storeys | inset prisms | 4 m, 1.6 m in | wing tops | M_SKIN S_DARK | 3 wings |
| gardens | planters, decks, stair houses | 10 m grid | 31 m roofs | M_STONE | 3 wings |
| terrace | deck, balustrade, planters, parasols | 26 x 54 m | wing, y 27.4 | M_STONE | 3 wings |
| amphitheatre | 4 arc steps, 3 benches | r 4..8.8 m | (-3051, -2403.5) | M_STONE | 4 courtyard |
| pavilion | 8-gon | r 3.2 m, 3.2 m | (-2973.5, -2398.5) | M_STONE | 4 courtyard |
| trees | trunk, frustum, pyramid | 5..7.5 m | 43 spots | M_STONE | 4 courtyard |
