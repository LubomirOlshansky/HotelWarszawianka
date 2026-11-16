# Dom Chłopa (Plac Powstańców Warszawy 2): spec

Site key `dom_chlopa` (`_build_dom_chlopa` in `game/scripts/landmarks/works.gd`). Written
2026-11-16 in a cloud thread from photos: F's T14 set (`refs/_f/warsaw-needed-photos/top-50/T14/`
in the shared store: the north-west corner with the casino, the courtyard side, the long front on
the square with the hotel's sign) and 7 Mapillary frames along the square and Warecka
(`refs/dom_chlopa/street`); reference only, never shipped. The casino was moved to the south end
the same day from F's two night photos of it (the name on the roof, the lit panels, the blue
corner sign).

The mass is the street block that already stood on the outline
(`game/data/street_blocks/2250406.bin`, its own site `blk_2250406`: the cream walls round the
courtyard with their windows, the dark glass ground floor, the coping at 18.4 m). This site
dresses it and draws no walls of its own.

## 1. Identity

1. The roof edge of every street front is a row of shallow arcs, about two window bays each,
   over the cream walls (all three T14 photos, every Mapillary frame).
2. The hotel's name in big green letters on the roof over the north end of the front on the
   square, and a tall dark sign with HOTEL down the north-west corner (T14-03, the frames from the
   south).
3. The casino at the south end of the front on the square: its name in white on the roof and over
   a dark fascia, glass panels lit in changing colours under it, and a blue sign down the
   south-west corner (F's night photos).

## 2. Massing (heights over the block's ground, the lowest under its outline)

The block's, unchanged: the dark glass ground floor to 6.8 m, the cream floors to 17.7 m, the
coping to 18.4 m. The arcs rise from the coping to 1.5 m over it (1.3 m and their 0.2 m top).

## 3. Facade, base to top

- **Roof edge**: on every outline edge of 4 m or more, arcs of about 6.2 m (a whole number of
  them per edge), each arc five straight pieces (the outline's kinks under 4 m a flat piece); a cream band 0.3 m proud of the wall line from
  0.3 m under the coping, its underside shaded, its back and top.
- **GROMADKA**: pixel letters 2.5 m tall and 14 m long, centred 17 m from the north-west corner,
  standing 1.9 m back from the front on two dark beams resting on the roof edge, from 0.6 m over
  the coping.
- **HOTEL**: a dark pier 1.6 m wide, 0.5 m proud, from the ground to the coping, 1 m from the
  north-west corner; the five letters stacked down its upper part, 1 m tall each.
- **HOTEL fascia**: a dark fascia (4.8 to 6.6 m) running from the HOTEL pier 30 m along the ground
  floor's top, with no text.
- **KASYNO TRAF on the roof**: white pixel letters 2.1 m tall, centred 62 m from the north-west
  corner, standing 1.9 m back from the front on two dark beams, like GROMADKA's.
- **Casino fascia**: dark, 4.8 to 6.6 m, from 50 m to the south end, with KASYNO TRAF in white
  letters 1 m tall, top at 6.4 m.
- **Lit panels**: 11 glass panels from 51 m to 2.4 m short of the south end, from the ground to 4.2 m, in
  purple, blue, cyan, green and magenta.
- **Corner pier**: a dark pier 1.6 m wide, 0.45 m proud, from the ground to 16 m, at the south-west corner,
  with a blue lit strip 0.6 m wide from 7.2 to 15.4 m.

## 4. Roof

The block's flat roof; the arcs' tops a shade lighter than the band.

## 5. Colour and material

Band #e6e1cb, its back a shade darker, its underside darkened by a third (M_STONE); the sign panel
and posts #2c3133 (M_STONE); GROMADKA and HOTEL #3fbf4a, KASYNO TRAF #f2f2ee, the corner strip #3c8cff, the panels
#8a3cff/#5a4cff/#3c6cff/#3fb0f0/#3fd6c8/#4fe08a/#9a4cf0/#d04fc8, all M_LAMP (their own
colour by day, lit at night). No new material, no shader change (building.gdshader stays 501 of
505), no neon row.

## 6. Ground and night

The block's collision is unchanged; nothing of this site stands where a car drives. At night the
green name and HOTEL glow over the north end; at the south end the casino's names, its coloured
panels and the blue corner strip glow.

## 7. Detail level and budget

L2 (a big building on the square, seen from above at an angle). 2728 triangles of its own, most of
them the arcs round the whole block; budget 3000 (check_mesh_quality BUDGET "dom_chlopa"); no draw
call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | street block | the whole building | the outline | its own | 2 massing |
| roof edge | arcs, 5 pieces each | 6.2 m, 1.3 m rise, 0.3 m proud | every street front | M_STONE #e6e1cb | 1.1 roof edge |
| GROMADKA | pixel faces | 14 x 2.5 m | the roof over the north end | M_LAMP #3fbf4a | 1.2 signs, 6 night |
| beams | boxes | 0.3 x 2 m, 0.8 m tall | under GROMADKA, back to the roof edge | M_STONE #2c3133 | 1.2 signs |
| HOTEL pier | box | 1.6 m, ground to coping | the north-west corner | M_STONE #2c3133 | 1.2 signs |
| HOTEL fascia | box | 30.4 x 1.8 m | over the ground floor's north stretch | M_STONE #2c3133 | 1.2 signs |
| casino fascia | box | 26.3 x 1.8 m | over the ground floor's south stretch | M_STONE #2c3133 | 1.3 casino |
| corner pier | box | 1.6 m, ground to 16 m | the south-west corner | M_STONE #2c3133 | 1.3 casino |
| HOTEL | pixel faces | 1 m letters | down the panel | M_LAMP #3fbf4a | 1.2 signs, 6 night |
| KASYNO TRAF | pixel faces | 10 x 1 m | on the casino fascia | M_LAMP #f2f2ee | 1.3 casino |
| KASYNO TRAF roof | pixel faces | 13 x 2.1 m | the roof over the south end, on two beams | M_LAMP #f2f2ee | 1.3 casino, 6 night |
| panels | boxes | 11 of 2 x 3.6 m | under the casino fascia | M_LAMP, 8 colours | 1.3 casino, 6 night |
| corner strip | box | 0.6 x 8.2 m | down the corner pier | M_LAMP #3c8cff | 1.3 casino, 6 night |

## 9. Not built, and what only the phone can show

- The hotel's globe logo on the roof, the CASINO letters down the corner (a lit strip stands in),
  the star by the casino's name, the
  ground floor's granite piers and steps along the square, the glass link bridge in the courtyard
  (T14-02), the posters by the casino's door.
- Names: the hotel and the casino are real businesses; the game shows parodies (GROMADKA, KASYNO
  TRAF), never the real names.
- Phone: whether the arcs read as a wavy edge at phone zoom, not as noise, and whether GROMADKA
  reads from the square by night.
