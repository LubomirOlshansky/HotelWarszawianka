# Torwar (Łazienkowska 6a): spec

Site key `torwar` (`_build_torwar` in `game/scripts/landmarks/works.gd`). Written 2026-11-15 in a
cloud thread from photos: F's T45 set (`refs/_f/warsaw-needed-photos/top-50/T45/` in the shared
store: the front straight on from Łazienkowska, the hall inside), Mapillary and Panoramax frames
round the hall (`refs/torwar/street`: the portico from the south-east, the east side over the car
park, the north end from the Trasa Łazienkowska viaduct); reference only, never shipped.

The hall's mass is the street block that already stood on the outline
(`game/data/street_blocks/25844922.bin`, its own site `blk_25844922`: the cream hall under its
roof, the brick annexes round it, the white entrance block with its glass front and a curved
parapet). This site dresses it and draws no walls of its own. The map's own outlines of the
entrance block and of the portico's roof (a grey box with windows until now) are in its zone and
dropped; the block draws that mass.

## 1. Identity

1. On Łazienkowska, a white portico across the whole glass front: twelve slender round white
   columns, a deep plain entablature with TORWAR across it in grey letters, a curved parapet
   rising over the middle (T45-01).
2. Behind the columns a dark glass curtain wall in three storeys over glazed doors (the block's).
3. The long sides: a cream upper storey with white pilasters and grey concrete lattice panels in
   the windows, under a white cornice, over a red brick single-storey annex (the east car park
   photo; the north end from the viaduct shows the same pilasters and lattice).

## 2. Massing (heights over the block's ground, the lowest under the hall)

The block's, unchanged: the hall's walls to 13.2 m and its roof to 19.4 m, the gables to 15.5 m,
the brick annexes 5.5 m, the entrance block 15.2 m with its arc to 18.2 m. The forecourt stands
about 2 m higher than that ground, so the front is about 13.8 m tall over the forecourt with the
parapet 2.5 m over that, as T45-01's proportions give (width to height about 3 to 1).

## 3. Facade, base to top

- **Portico** (u -21.6 to 21.6, 1.8 to 4.6 m out from the glass): twelve columns 0.72 m round,
  3.3 m apart, from the forecourt to 13.3 m; the entablature 13.3 to 15.9 m, its underside a
  shade darker; TORWAR in pixel letters (9.1 m long, 1.2 m tall) across its face, 14.0 to 15.2 m.
- **Parapet**: from the entablature's top a low curve to 18.4 m over the middle, 24 m wide and as
  deep as the entablature (it must cover the block's own arc and its letters behind; T45-01 shows
  the curve a little narrower).
- **Long sides**: a pilaster (1.4 m wide, 0.45 m proud) between each pair of the block's ten
  upper windows and at the corners, from the ground to 12.6 m; a lattice panel (3.2 m wide, 6.7
  to 11.3 m) in the middle of each window, the glass showing either side; the cornice 12.5 to
  13.4 m along the eaves.
- **North gable**: eleven pilasters 7.84 m apart, a lattice panel in each bay, the cornice across.

## 4. Roof

The block's: dark grey over the hall with its light ribs and the glass ridge strip; the
entablature's and the parapet's tops white.

## 5. Colour and material

Entablature and parapet #eeede6, columns #e8e7e0, pilasters and cornice #f0ece0, lattice frame
#d8d6cc and its pattern #8f948f (all M_STONE); the letters #6f757b in M_LAMP (grey by day, lit at
night). The block keeps its own colours (cream #e5ca87, white #efeee9, brick #9e4b3b, glass
#47636c). No new material, no shader change (building.gdshader stays 501 of 505), no neon row.

## 6. Ground and night

The car is stopped by the hall's outline (the block's collision) and by a box over the entrance
block and the portico (the map's outlines there, which stopped it before, are dropped). At night
the TORWAR letters glow and the block's glass front lights as its windows do.

## 7. Detail level and budget

L2 (a landmark on Łazienkowska beside the stadium, seen from above at an angle). 1254 triangles of
its own (the block's are the block site's), budget 1500 (check_mesh_quality BUDGET "torwar"); no
draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | street block | the whole hall | the outline and the entrance | its own | 2 massing |
| entablature | box + soffit | 43.2 x 2.8 m, 13.3 to 15.9 m | over the front | M_STONE #eeede6 | 1.1 portico |
| parapet | curved solid | 24 m, to 18.4 m | over the middle | M_STONE | 1.1 portico |
| columns | 8-sided prisms | 0.72 m, 12 | 3.4 m out, 3.3 m apart | M_STONE #e8e7e0 | 1.1 portico |
| letters | pixel faces | 9.1 x 1.2 m | the entablature's face | M_LAMP #6f757b | 1.1 portico, 6 night |
| pilasters | boxes | 1.4 m, to 12.6 m | the long sides, the north gable | M_STONE #f0ece0 | 1.3 sides |
| lattice | box + face | 3.2 x 4.6 m | in the upper windows | M_STONE #d8d6cc / #8f948f | 1.3 sides |
| cornices | boxes | 0.9 to 1.5 m deep | along the eaves | M_STONE #f0ece0 | 1.3 sides |

## 9. Not built, and what only the phone can show

- The loggia with four columns on the east side near the front, the lattice's own pattern, the
  red COS logo on the roof, the flags, the forecourt's lamp posts and benches, the billboard.
- The hall inside (T45-02, T45-03: the stands round the ice and the concert stage).
- Phone: whether TORWAR reads on the white entablature at phone zoom, and whether the lattice
  panels read as panels, not windows.
