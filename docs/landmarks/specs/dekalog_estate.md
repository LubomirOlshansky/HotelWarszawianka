# The Dekalog estate and the Inflancka pools: spec

Site keys `dekalog_estate` and `inflancka_pools` in `game/scripts/landmarks.gd`
(`_find_dekalog_estate`, `_build_dekalog_estate`, `_find_inflancka_pools`, `_build_inflancka_pools`).
Written 2026-11-07 from F's photo set (rows K01-K09 of the Kieślowski list: Dzika 6 from the south
in 2026, two 1970s fronts, the GUGiK ortho and the city's 2018 oblique flights, five 2022 summer
photos of the pools) and the OpenStreetMap outlines in `centrum.json`.

## 1. Identity

The large-panel estate between Inflancka, Dzika and Stawki in Muranów (1970s), where Kieślowski
shot most of the Dekalog (mapadekalogu.pl: Dzika 6, episodes I, IV and VI; Tomek watches Magda
from the next block). Across Inflancka, Ośrodek Sportowy Inflancka 8 with its summer pools.

1. **Long 14-storey slabs, each a chain of staggered segments**, pale cream plaster, punched windows.
2. **Ochre stair strips** where one segment steps back from the next; blank gable ends.
3. **White concrete balcony stacks** at both ends of each segment's long face, one per floor.
4. **The pools**: a white quilted air dome, a yellow deck with three round pools, a 25 m lap pool,
   a red slide and a green spiral, sand courts.

## 2. Massing

- Six slabs found by interior points (`DE_AT`): Dzika 6, Inflancka 15, Inflancka 19, Inflancka 11,
  Dzika 19/23, Stawki 6. OSM draws every balcony notch; the outline is simplified at 1.8 m to the
  segments and the balconies are built by the model.
- 14 floors at 2.95 m (the S_PUNCHED floor height) plus a 0.9 m attic, about 42 m.
- Lift houses 4.8 x 3.6 x 2.8 m, one every ~22 m along the slab's axis.
- Balcony stacks 3.2 m wide, 1.25 m deep, held 0.5 m in from each face end; slab 0.18 m, parapet 1.05 m.
- The four street blocks that stood in for these slabs (`DE_BLOCKS`) are skipped.
- Pools, measured on the ortho (0.15 m a pixel, matching OSM's lap pool to under 1 m): dome over
  OSM's outline at (-2336, -2370), 11 m high on a 1.1 m kerb; leisure deck with round pools of
  r 4.2, 6.4 and 6.2 m; lap pool on OSM's corners with five lanes, deck grown 3.5 m (+6 m at the
  slide end); slide tower at (-2255.8, -2385.8), deck 6.5 m, red chute, green spiral 1.5 turns.

## 3. Facade, base to top

- **Long faces**: cream plaster with the S_PUNCHED skin (a window every 3.2 m, floors 2.95 m, lit at night).
- **Short faces under 9 m facing along the axis**: the ochre stair strips, 0.6 m above the roof.
- **Gable ends**: blank cream.
- **Balconies**: white slab and solid parapet, floors 1-13, at both ends of each long face.

## 4. Roof

Dark flat roof; lift houses along the axis. The dome: a 16 x 11 quilted cushion on its kerb.

## 5. Colour and material

| Part | Colour |
| --- | --- |
| Plaster (long faces) | `#ece3c8` |
| Gable ends | `#e2d7b8` |
| Stair strips | `#d9b874` |
| Balcony slabs / parapets | `#f2f0ea` / `#e9e7df` |
| Roof / lift houses | `#55585c` / `#d8cfb4` |
| Dome / kerb | `#eef0ec` (every other cell 4% darker) / `#c9c7c0` |
| Leisure deck / lap deck | `#e1c35c` / `#d9b85a` |
| Round pools | `#8fd0e2`, `#b4806c` (painted floor), `#2f5e98` |
| Lap water / lanes | `#41c3e6` / `#1d5fa8` |
| Slide / spiral | `#d8343a` / `#3fa66a` |

## 6. Ground and night

Pool decks are 0.35 m slabs (OSM's pitch and grass under them never show through); the decks and
the volleyball court keep trees off (`tree_free` plans). At night the slabs' windows glow from the skin.

## 7. Detail level and budget

L2, triangle budget 18000 for the estate (exception: six 14-storey slabs in one site, about 2700 each; 16076 measured) and 1000 for the pools (714 measured), in
`check_sites.gd` and `check_mesh_quality.gd`. One material (the city's building material), no new draw calls.

## 8. Parts table

| Part | Shape | Size | Position | Material | Feature |
| --- | --- | --- | --- | --- | --- |
| slabs | staggered prism, 6x | 14 floors, 42 m | OSM outlines under `DE_AT` | cream plaster, S_PUNCHED | the Dekalog blocks |
| stairs | wall strip | short faces under 9 m | segment steps | ochre `#d9b874` | the staggered rhythm |
| balconies | slab + parapet stack | 3.2 x 1.25 m, floors 1-13 | both ends of each long face | white concrete | the 1970s look |
| lifts | box | 4.8 x 3.6 x 2.8 m | on the roof, every ~22 m | cream | the roofline |
| dome | superellipse cushion | 11 m on a 1.1 m kerb | OSM outline at `IP_DOME_AT` | white, quilted | the pools from the street |
| pools | discs and a rectangle | r 4.2-6.4 m; 25 x 12 m | the K09 ortho | blue water on yellow decks | summer swimming |
| slide | tower, chute, spiral | deck 6.5 m | (-2255.8, -2385.8) | red and green | seen from Inflancka |
| court | sand bed and net | 18 x 9 m | (-2220.5, -2374.5) | sand | beach volleyball |

## 9. Left for later

- The other estate blocks (Stawki 8, Dzika 4A, Stawki 4A tower) and the yards (K07, K08).
- The pools' fence, cashier and benches; the spiral's real path down.
- Night: lit windows come from the S_PUNCHED skin; the dome is not lit.
