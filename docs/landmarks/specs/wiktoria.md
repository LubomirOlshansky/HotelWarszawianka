# Hotel Wiktoria (parody of the Sofitel Victoria on Królewska): spec

Site key `wiktoria` (`_find_plac2` and `_build_wiktoria` in `game/scripts/landmarks/plac.gd`, card in
`landmarks.gd` INFO). Rebuilt 2026-11-15 in a cloud thread from F's photos T27 (the hotel from the
corner of Plac Piłsudskiego and Królewska by day, and its front behind the Smolensk memorial; reference
only, never shipped). The outline is OpenStreetMap's "Sofitel Victoria" building (found by name), the
walls' heights are estimates from the photos. The real brand is not used: no sign text.

## 1. Identity

1. A 1970s white modernist hotel: a long slab and a lower wing on a glazed base (the photos).
2. The slab's front is a grid of white panels with a small window in a deep reveal on every floor,
   the windows of brown-tinted glass; its end walls are blank white (photo 1).
3. The base is two storeys of glass between marble piers; the slab overhangs it; a terrace at the
   first-floor level; a dark canopy at the west end of the Królewska front.

## 2. Massing (heights over the ground)

The outline is about 117 by 79 m in a frame turned to the Królewska front (u along it, v into the
plot). Glazed base 6.5 m, set back 1.2 m from the outline; terrace slab at 6.5 m over the whole outline;
the long slab along the Królewska front 17 m deep, eight floors of 3 m on a 1.2 m storey: roof at
about 31.7 m; the wing at the east end 19 m wide, running back to the outline's far edge, six floors:
roof at about 25.7 m. A plant room (9 by 4 by 3.2 m) on the slab.

## 3. Facade, base to top

- **Base**: dark glass (M_GLASS) to 6.5 m, the terrace slab on top of it; the canopy 4.6 to 5.3 m on two piers.
- **Volumes**: white (#e8e7e1) walls from 6.5 m; a window bay every 3 m, window (bay minus 1.1 m) by
  1.5 m, brown glass #7a5a38; a white fin 0.36 m wide and 0.3 m proud between the bays; a sill
  band 0.2 m tall and 0.3 m proud under each row.
- **Short fronts** (under 20 m) and fronts inside the other volume: no windows.
- **Parapet**: a thin cornice at the roof.

## 4. Roof

Flat grey roofs (#8d8c88) on both volumes; the terrace left as a pale deck. Not built: the plant room
detail, antennas and the roof terrace's furniture.

## 5. Colour and material

White #e8e7e1, glass base #44535a, windows #7a5a38, canopy #3b3d3e, roof #8d8c88. M_STONE for the
volumes, M_GLASS for the base; the kit's lit-by-chance panes at night. No new material, no shader change.

## 6. Ground and night

The pavement and road are the city's. Car collision runs round the outline. At night the panes
light by chance.

## 7. Detail level and budget

L2. About 4,100 triangles, budget 4500 (an exception to L2's 3,000: one 117 by 79 m outline with
about 270 windows and as many fins; check_mesh_quality BUDGET `wiktoria`); no draw call,
`building.gdshader` unchanged.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | prism | 6.5 m high, 1.2 m in | the outline | M_GLASS | 3 |
| terrace | cap | at 6.5 m | the outline | M_STONE | 3 |
| slab | prism | 17 m deep, 8 floors | Królewska front | M_STONE white | 1, 2 |
| wing | prism | 19 m wide, 6 floors | east end | M_STONE white | 1 |
| windows | quads | 1.9 by 1.5 m | every 3 m, each floor | lit panes | 2 |
| fins, sills | boxes | 0.36 m, 0.2 m | between and under | M_STONE | 2 |
| canopy | box and piers | 18 by 5 m | west end of the front | M_STONE dark | 3 |

## 9. Not built, and what only the phone can show

- The real window pitch, floor count and the wing's exact place and depth (estimates from two angles),
  the marble piers and glazing of the base, the restaurant terrace's detail, signs and the casino.
- Phone: whether the white slab and its niches read at the game's zoom, and the overhang over the base.
