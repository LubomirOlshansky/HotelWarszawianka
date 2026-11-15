# Dom bez Kantów and Królewska 2, the block on the south-east corner of Plac Piłsudskiego: spec

Site key `bez_kantow` (`_find_plac2` and `_build_bez_kantow` in `game/scripts/landmarks/plac.gd`,
card in `landmarks.gd` INFO). Written 2026-11-15 in a cloud thread from seven of F's photos (the
cream corner from the square and from Królewska by day, the same corner floodlit at night, the
sandstone corner at Krakowskie Przedmieście and Tokarzewskiego-Karaszewicza, three photos;
reference only, never shipped), an orthophoto of the roofs F sent, OpenStreetMap's outline of Dom
bez Kantów and GUGiK's LoD2 (heights, the west and north walls). LoD2 draws only the west and
north wings and a low strip for the east one, and OpenStreetMap's outline holds only the south-east
wings: the whole ring is ours and replaces both (a site with no `skin`).

## 1. Identity

1. A long classicist block round a courtyard, four wings, every outer corner rounded in a bow, a
   deep cornice, a dark flat roof (all the photos, the orthophoto).
2. A deep arcade of round arches at street level along every outer front, shops behind it
   (Cukiernia, La Boutique on the north-east corner), arches about 3 m wide every 6 m.
3. The west part, Królewska 2: cream plaster, four storeys over a high rusticated ground floor,
   stone-framed windows, small stone balustrades under the first floor on the bowed corner on the
   square (F's four photos).
4. Dom bez Kantów, 1933-35, the east and south-east wings: pale sandstone ashlar, six storeys
   counting the arcade, a heavy string course between the second and third floor, a row of small
   horizontal attic windows under the cornice, the corners bowed (F's three sandstone photos;
   whitemad.pl on the building).
5. The columned eagle building beside it on Tokarzewskiego-Karaszewicza is not part of this site.

## 2. Massing (heights over the ground)

The block is a trapezoid in a frame turned 14 degrees to the grid: about 106 m along Królewska (s)
by 72 m deep (t), the origin at the south-west corner of its bounding rectangle (-650.7, -731.2 in
the map); the east side leans with Krakowskie Przedmieście. Wings: south 17.5 m deep, west 22 m,
east about 25 m, north 19 m; the courtyard between them is 56 by 35.5 m. The cream parts stand 21.8 m
to the eave, the sandstone wings 25.9 m (LoD2's wings reach 22 to 26 m). The sandstone starts at
s 27.5 on the Królewska front and at s 69.3 on the north front, where OpenStreetMap's outline of
Dom bez Kantów meets the cream block. The outline's corners are OpenStreetMap's for the east side and
8 m (south-west) and 7 m (north-west) for the cream corners.

## 3. Facade, base to top

- **Ground floor** to 6.3 m: the paler base, arches 3.2 m wide to a spring at 4.3 m about every 6 m
  along every outer front.
- **String course** at 6.3 m, 0.35 m tall, 0.2 m proud.
- **Cream parts**: four rows of windows, sills at 7.7, 10.9, 14.1 and 17.3 m, pane 1.2 by 1.9 m in
  a paler frame, a sill band under each row; balustrades under the first row on the bowed corner.
- **Sandstone parts**: five rows, sills at 7.9, 11.0, 14.1, 17.2 and 20.3 m; a heavy string course
  at 13.0 m; slit windows 0.9 by 0.45 m at 24.2 m.
- **Cornice** at the eave: a frieze and a slab 0.9 m proud.
- **Courtyard walls**: plain, windows from 1.3 m up, a small cornice.

## 4. Roof

Flat dark zinc at each part's eave; the courtyard left open; a step in the eave (4.1 m high) facing
west where the sandstone wings stand over the cream ones. Not built: the pitched edge, chimneys, the
lift boxes and the antenna on the roof.

## 5. Colour and material

Plaster #e9e2cf, plaster base #e4ddcb, stone trim #d6c8a8; sandstone #dac9a2, trim #cdbb94;
frames #ece7da; glass #323a40; roof #6d7470 (the palette's zinc). All M_STONE with the kit's
lit-by-chance panes. No new material, no shader change. The far skyline's colour is #dccdac.

## 6. Ground and night

The pavement and the road are the city's. Car collision runs round the outer outline. At night
the panes light by chance. F's night photo has the facade floodlit warm white, which the game does
not do for landmarks: the walls stay as the street lights them.

## 7. Detail level and budget

L2 (a big block on the square the first drive passes). About 6,700 triangles, budget 8000 (an
exception to L2's 3,000: one 106 by 72 m ring with about 70 arches and 600 panes; check_mesh_quality
BUDGET `bez_kantow`); no draw call, `building.gdshader` unchanged.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | walls | outer ring to 21.8 / 25.9 m | the whole outline | M_STONE plaster / ashlar | 1.1 |
| court walls | walls | the courtyard ring | s 22..78, t 17.5..53 | M_STONE | 1.1 |
| roofs | two flat caps | at 21.8 and 25.9 m | the two parts | M_STONE zinc | 1.1 |
| step | two walls | 4.1 m high | s 27.5 south, s 69.3 north | M_STONE ashlar | 3, 4 |
| arches | arched panels | 3.2 m wide | every 6 m, ground floor | M_STONE, M_GLASS | 2 |
| panes | quads | 1.2 by 1.9 m | every 3.1 m, 4 or 5 rows | lit panes | 3, 4 |
| bands | boxes | 0.18 to 0.4 m | under each row, at 6.3 and 13 m | M_STONE | 3, 4 |
| cornice | two boxes | 0.9 m proud | at the eave | M_STONE | 1 |
| balustrades | boxes | 2 by 0.85 m | first floor, bowed corner | M_STONE | 3 |

## 9. Not built, and what only the phone can show

- The real window rhythm on the bows (one pane per chord here), the masks over the arches, the
  signs and awnings of the shops, the lobby doors.
- The cream corners' real radii (LoD2 says 5 to 8 m, the photos look larger), where exactly the two
  materials meet (OpenStreetMap's line, an estimate), the west and north cream fronts beyond the
  corner photos, and the east front on Krakowskie Przedmieście in detail.
- The columned neighbour on Tokarzewskiego-Karaszewicza keeps LoD2's plain mass.
- Phone: whether the cream and the sandstone read apart at the game's zoom, the arcade's depth, and
  the 4 m step in the eave.
