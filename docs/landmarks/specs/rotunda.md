# Rotunda (Rotunda PKO): spec

Site key `rotunda` in `game/scripts/landmarks.gd` (`_build_rotunda`, `_rot_crown`, `_rot_fin`,
`_rot_door`). Written 2026-11-01 from the Mac photo check of the start area (main ed7e873,
start spot `--at=-961.6,95.0 --heading=339.8`, the Rondo photos) and the mapped outline
`Rotunda PKO` in `centrum.json` (a 96-point circle, mean radius 17.1 m, centre about
(-793.7, 391.6)).

**Photo rebuild, 2026-11-08** (thread "Rebuild Rotunda and Eastern Wall stores"): from F's photo set
`/mnt/project-files/pkin-surroundings/photos/E3-rotunda/` (street front, the crown close up, the
glazing under the overhang, the view from Varso, a night front), the Mac's `refs/rotunda/`
(Commons 1-5, the GUGiK ortho) and Mapillary 2026-05 panoramas (`refs/rotunda/street/`). What the
photos changed against the 2026-11-01 model:
- **40 bays, not 52**, with slim silver mullions (0.12 x 0.14 m), not proud fins; two thin transoms
  at 3.4 and 7.1 m (the panes in three rows).
- **The glass rises into a point over every mullion** (the street photos): one fold per bay, the
  ridges over the mullions at 12.3 m, the valleys over each bay's middle at 10.8 m. The "teeth" are
  not solid white triangles but a thin white zigzag edge (0.4 m) at the folds' ends, standing out
  0.6 m (not 2.2 m) from the glass.
- **The roof is a shallow funnel**: the folds slope DOWN from the rim (ridges 12.55 m, valleys
  11.05 m) to the oculus (11.9 / 11.5 m); the oculus's kerb stands 1.1 m over the folds (glass at
  12.6 m). From the street nothing shows over the edge (old photo 1); from the Palace the far half
  of the fan faces the camera.
- The two triangular plates on the edge are gone (none in the 2022-2026 photos); the canopies are white.
- Not changed: the outline (map radius 17.1 m), the glass colour, the doors, BANK POLSKA (parody).
- Still to shoot (only F): the crown's night lighting (the night photo shows a violet-lit edge:
  not built, a lit line would read wrong by day), the plaza door up close.

The sections below are the 2026-11-01 spec; where they differ, the list above wins.

## 1. Identity

The round glass bank pavilion (1966, rebuilt 2017) on the corner of Marszałkowska and Aleje
Jerozolimskie, by Rondo Dmowskiego, the city's classic meeting point ("pod Rotundą"). What makes
a passer-by say "the Rotunda":

1. **A low glass drum**, green-grey glass floor to eave between close silver mullions.
2. **The folded-plate crown**: a brushed-silver roof of radial folds whose ends make a ring of
   downward teeth round the eave.
3. **A raised oculus** in the middle of the shallow cone, a metal kerb round a glazed top.
4. **The entrances**: a flat silver canopy over the main door on the south, a smaller one on the
   plaza side (north-west).

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Plinth | the drum's 52-gon on the mapped radius (17.1 m, Ø 34.2 m: the photo check says 35-37 m; kept to the map, Widok Towers stands right against it) | -0.4 to 0.3 m |
| Glass drum | the same 52-gon, a mullion at every corner | 0.3 to 10.8 m |
| Overhang | out to the radius + 2.2 m (Ø 38.6 m) | soffit at 10.8 m |
| Crown | 48 folds from the edge to the oculus (radius 5.4 m, 10.8 m across) | ridges 12.3 m at the edge to 14.4 m at the oculus; valleys 10.8 to 14.0 m |
| Oculus kerb and glazed top | a 24-gon of radius 5.4 m | 13.9 to 15.3 m, the glass at 15.3 m |

## 3. Facade, base to top

- **Plinth**: a dark granite strip, 0.7 m.
- **Glass**: green-grey panes from the plinth to the eave (M_PAVILION param 0.75: plain panes,
  a silver transom 1.3-1.55 m under the eave, a little sky in the glass, lit warm at night).
- **Mullions**: 52 silver fins round the drum (about 2.07 m apart on the mapped radius), 0.18 m
  wide and 0.32 m proud, plinth to eave; one bay is centred on the south door.
- **Main entrance (south, towards Al. Jerozolimskie and Rondo Dmowskiego)**: three bays of dark
  glass doors to 3.2 m, a silver transom bar over them (the mid-height transom, only here), a
  flat silver canopy 8 m wide and 2 m deep at 4 m.
- **Plaza entrance (north-west)**: two door bays, a canopy 5 m by 1.5 m at 3.6 m.
- **Signs**: the bank's name as a parody, BANK POLSKA, white, on the glass either side of the
  south door (32° each side, at 5.2 m, letters about 0.9 m). The red and blue light in the glass
  and the old crown signs are gone.

## 4. Roof

A folded plate: 48 radial folds, each a ridge and a valley, facets alternating #d4d8db and
#b0b6bb. At the eave the valleys drop 1.5 m below the ridges, so the plates' ends read from the
street as a ring of downward triangular teeth (2.2 m wide at the eave, 1.5 m tall, white-silver
#e4e7e9) in front of a dark fascia set back 0.5 m. The cone rises gently to the oculus: a 1 m
metal kerb (#c3c8cc) round a flat glazed top (M_GLASS_ROOF, lit at night) crossed by three bars
each way (the 4 x 4 grid). Two flat triangular metal plates (5.2 m wide, 3.8 m tall) stand on the
edge at the north-east and the south-west.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass | #5e7f7a (shade #4d6f6b, lit #6f8f8a) | M_PAVILION + 0.75 |
| Mullions, kerb, canopies, oculus bars | #c3c8cc | M_STONE |
| Roof folds | #d4d8db / #b0b6bb | M_STONE |
| Teeth | #e4e7e9 | M_STONE |
| Fascia behind the teeth | #6d7378 | M_STONE |
| Soffit | #b9bec2 | M_STONE |
| Doors | #2e3a39 | M_STONE |
| Plinth | #55585c | M_STONE |
| Oculus glass | #8fb0ad | M_GLASS_ROOF |
| Triangular plates | #a9b0b5, back #8e959a | M_STONE |
| Signs | white (0.95, 0.97, 1.0) | neon atlas (LandmarkSigns) |

No new material: the city's building surface (+0 draw calls) and the landmark signs'
MultiMesh (+0).

## 6. Ground and night

The car stops at the drum (the 52-gon). At night the glass glows warm, nearly every pane, the
oculus glows, the names stay lit white. Context: Widok Towers right to the north-east is now a
green glass grid with white mullions (TOWERS `widok`: S_GRID, #5d8478) instead of a plain blue
box. Card unchanged.

## 7. Detail level and budget

L3, triangle budget 1380 (1144 measured on 2026-11-01, `check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism of the 52-gon | r 17.1 m, 0.7 m tall | y -0.4..0.3 | M_STONE #55585c | 1 drum |
| glass | prism of the 52-gon | 10.5 m tall | y 0.3..10.8 | M_PAVILION + 0.75 #5e7f7a | 1 drum |
| fins | 52 three-sided fins | 0.18 x 0.32 m | every drum corner | M_STONE #c3c8cc | 1 drum |
| folds | 48 x 2 facets | edge to r 5.4 m | y 10.8..14.4 | M_STONE #d4d8db / #b0b6bb | 2 crown |
| teeth | 48 triangles | 2.2 x 1.5 m | the edge, r 19.3 m | M_STONE #e4e7e9 | 2 crown |
| fascia | 48 quads | 1.5 m tall | r 18.8 m | M_STONE #6d7378 | 2 crown |
| soffit | 48 quads | r 16.9..19.3 m | y 10.8 | M_STONE #b9bec2 | 2 crown |
| kerb | prism of a 24-gon | r 5.4 m, 1.4 m tall | y 13.9..15.3 | M_STONE #c3c8cc | 3 oculus |
| oculus | flat glass cap and 6 bars | r 5.4 m | y 15.3 | M_GLASS_ROOF #8fb0ad | 3 oculus |
| canopy_s | flat box | 8 x 2 x 0.35 m | south, y 4.0 | M_STONE #c3c8cc | 4 entrances |
| canopy_nw | flat box | 5 x 1.5 x 0.35 m | north-west, y 3.6 | M_STONE #c3c8cc | 4 entrances |
| doors | dark panels and a transom | 3 bays south, 2 north-west, to 3.5 m | on the glass | M_STONE #2e3a39 | 4 entrances |
| plates | two triangles | 5.2 x 3.8 m | the edge, NE and SW | M_STONE #a9b0b5 | 2 crown |
| signs | neon word BANK POLSKA x 2 | letters 0.9 m | either side of the south door, y 5.2 | neon atlas | 4 entrances |
