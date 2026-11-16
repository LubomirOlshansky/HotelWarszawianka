# NBP, Oddział Okręgowy (Plac Powstańców Warszawy 4): spec

Site key `nbp` (`_build_nbp` in `game/scripts/landmarks/works.gd`, a SKINS entry with `model` in
`fronts.gd`: the whole building is the site's model and replaces LoD2's block). Written 2026-11-16
in a cloud thread from photos: F's T13 set (`refs/_f/warsaw-needed-photos/top-50/T13/` in the
shared store: T13-01 the branch's front on the square with the steps, the white wall and the
stair slot; T13-02 the headquarters' entrance on Świętokrzyska), Mapillary frames along the
square (`refs/nbp_oddzial/street`: the steps from the south, the plinth wall with its planters,
the front's top curving out); reference only, never shipped.

The headquarters on Świętokrzyska (inventory #75's other half) is the street block
`game/data/street_blocks/6182253.bin`, already modelled in its cream stone with its windows; this
site does not touch it.

## 1. Identity

1. A long, low block along the east side of Plac Powstańców Warszawy, 133 m of dark brown-grey
   metal panels in three horizontal bands, each leaning out over the one below with a lip, the
   top band curving out over the square to the roof's edge (T13-01, the Mapillary frames).
2. In the middle of the front, the glass ground floor stands back on a terrace reached by a wide
   flight of granite steps; a white wall left of the doors carries the eagle and NBP in grey
   (T13-01).
3. Right of the doors a narrow glazed stair slot runs up through the bands to the roof (T13-01).
4. North and south of the terrace the bands stand on a rough light stone plinth wall, with
   wooden planters of small trees along the south stretch (the Mapillary frames).

## 2. Massing (heights over the square in front of the steps)

LoD2's footprint (GUGiK), simplified to seven corners: 133 m along the square, 29 to 31 m deep.
The roof 14.0 m over the square (LoD2's roofs 24 to 28 m, the square at 11.3 m; OSM says 14),
flat, with two plant rooms 2.2 m tall near the ends. The ground falls inside the block; the
walls go down to the lowest ground under it.

## 3. Facade, base to top

- **Plinth** (u 0 to 26 and 84 to 133): rough stone 0.5 m proud of the wall line, to 3.0 m; over
  it the panels' dark foot to 5.6 m.
- **Terrace** (u 26 to 84): granite to 1.8 m, the glass ground floor 2.6 m back in light frames
  1.6 m apart with a transom at 4.9 m, the bands' dark soffit over it at 5.6 m.
- **Steps** (u 30 to 80): nine steps 0.2 m by 0.42 m from the square to the terrace, solid granite
  blocks at both ends to 0.9 m over the terrace, three handrails.
- **White wall** (u 40 to 50): from the terrace to the soffit; the eagle (1.6 m) and NBP (5 m
  long, 1.3 m tall) in grey pixel faces.
- **Bands** (5.6 to 14.0 m): 5.6 to 8.5 m leaning 0.4 m out, a lip, 8.5 to 11.3 m leaning 0.6 m
  out, a lip, then 11.3 to 14.0 m curving out to 1.75 m over the square; a lighter seam every
  ~4 m; the band ends closed at both corners.
- **Stair slot** (u 57 to 60.5): glass 1 m back from the wall line from 5.6 m to the roof, two
  mullions and two transoms; the bands' cheeks close it.
- **Back and ends**: plain dark panels to the roof, a dark seam where each band would meet.

## 4. Roof

Flat, grey gravel #6f7173; the two plant rooms a lighter grey; the bands' top rim lighter.

## 5. Colour and material

Panels #4d4446, seams and lips #625a5c, soffit and seams #2f2a2b, plinth stone #b9b2a5, granite
#a9a7a1, glass #5d6f78 (M_GLASS), frames #c9cbc8, white wall #eeeeea, letters and eagle #8a8d90,
planters #b08a5e with #6f8f4a trees. Everything M_STONE except the glass. No new material, no
shader change (building.gdshader stays 501 of 505), no neon row.

## 6. Ground and night

The car is stopped by the footprint, the plinth's strip and the steps with the terrace. At night
the glass ground floor and the stair slot light as glass does; the panels stay dark.

## 7. Detail level and budget

L2 (a big public building on the square, seen from above at an angle). Its own triangles are
823 triangles of its own, budget 1000 (check_mesh_quality BUDGET "nbp"); no draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | walls + flat roof | 133 x 30 m, 14 m | LoD2's footprint | M_STONE #4d4446 / #6f7173 | 2 massing |
| bands | sloped quads | 133 m, 5.6 to 14 m | the front, 0.2 to 1.75 m out | M_STONE #4d4446 | 1.1 bands |
| seams | thin faces | 0.1 m | every ~4 m on the bands | M_STONE #625a5c | 1.1 bands |
| slot | glass + frames | 3.5 m, 5.6 m to the roof | u 57 to 60.5, 1 m back | M_GLASS #5d6f78 | 1.3 slot |
| ground floor | glass + frames | 58 m, 1.8 to 5.6 m | u 26 to 84, 2.6 m back | M_GLASS | 1.2 terrace |
| terrace | box | 58 x 2.6 m, to 1.8 m | in front of the glass | M_STONE #a9a7a1 | 1.2 terrace |
| steps | nine boxes | 50 x 0.42 m each | u 30 to 80, out to 3.8 m | M_STONE #a9a7a1 | 1.2 terrace |
| white wall | box | 10 m, to 5.6 m | u 40 to 50 | M_STONE #eeeeea | 1.2 terrace |
| eagle, NBP | pixel faces | 1.6 m, 5 m | the white wall | M_STONE #8a8d90 | 1.2 terrace |
| plinth | boxes | 0.5 m proud, to 3 m | u 0 to 26, 84 to 133 | M_STONE #b9b2a5 | 1.4 plinth |
| planters | boxes + prisms | 1.2 m, trees to 2.6 m | u 92 to 127, 1.5 m out | M_STONE #b08a5e / #6f8f4a | 1.4 plinth |

## 9. Not built, and what only the phone can show

- The panels' fine vertical ribs and their sheen, the blue house number by the doors, the doors
  themselves, the granite posts along the steps, the flagpoles, the parked cars along the square.
- The headquarters' granite lower floors and its bronze "Narodowy Bank Polski" letters on
  Świętokrzyska (T13-02): the street block draws that front; dressing it is a later pass.
- Phone: whether the three bands read as leaning panels at phone zoom, not as one flat dark wall,
  and whether NBP reads on the white wall.
