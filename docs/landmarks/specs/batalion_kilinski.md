# Pomnik Batalionu AK „Kiliński” (Plac Powstańców Warszawy): spec

Site key `batalion_kilinski` (`_build_batalion_kilinski` in `game/scripts/landmarks/works.gd`).
Written 2026-11-16 in a cloud thread from F's photo of the monument (the slab, the stelae, the
blocks and the flower bowls, seen from the south-west) and Mapillary frames of the square from
2021-2022 (`refs/kilinski_plac`); reference only, never shipped. It replaces the generic stele
that `tools/bake_monuments.py` stood here (now in its SKIP list).

## 1. Identity

1. A dark granite slab, tilted, low at the west and high at the east, with lines of inscription
   cut in it (F's photo).
2. White stelae on a step behind the slab with AK, 1939, the Kotwica and 1945 on them, facing the
   square to the west (F's photo).
3. White stone blocks scattered round it and round flower bowls with red flowers and a white heart
   in the middle (F's photo).

## 2. Massing (heights over the ground under the site)

A white base 0.15 m tall under the slab; the slab 7.2 x 3.8 m, its top from 0.45 m at the west to
1.35 m at the east; a white step 0.3 m tall behind it (1.8 m deep); four stelae 0.6 m wide,
1.6-2.2 m tall, on the step; eleven blocks 0.5-1.2 m on a side, 0.3-0.6 m tall; five bowls 1.2 m
across and 0.45 m tall.

## 3. Facade, base to top

- **Slab**: dark granite sides, its top face lighter, five inscription lines of dark ink across
  the top face, 0.18 m wide each, 3.5 cm over it.
- **Stelae**: white, the text on the face to the west in dark ink: AK, 1939, P over W (the
  Kotwica), 1945, pixel letters 0.35-0.5 m tall.
- **Blocks**: white stone boxes round the slab and on the square's south side.

## 4. Roof

None: the slab's tilted top is the monument's top; the stelae have flat tops a shade lighter.

## 5. Colour and material

Granite #5f6366, its sides #4c5053, its lines #2a2d30; the base and blocks #e4dfd3, the stelae
#eeeae1, the ink #1d1f21; the bowls #bdb8ad with red #c8282a flowers and a white #f0efe9 heart.
All M_STONE except the flowers (M_STONE too, flat colour). No new material, no shader change.

## 6. Ground and night

Three collision boxes: the slab with its base, the step with the stelae, the west blocks. They
stand on the square's paving, away from the road. At night the square's lamps light it; nothing of
its own glows.

## 7. Detail level and budget

L2 (a monument on a square the player drives round and flies over). 722 triangles; budget 1100
(check_mesh_quality BUDGET "batalion_kilinski"); no draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | box | 10 x 4.8 x 0.15 m | under the slab | M_STONE #e4dfd3 | 2 massing |
| slab | tilted prism | 7.2 x 3.8 m, 0.45-1.35 m | the middle | M_STONE #5f6366 | 1.1 slab |
| lines | quads | 5 lines, 0.18 m | the slab's top | M_STONE #2a2d30 | 1.1 inscription |
| step | box | 10 x 1.8 x 0.3 m | east of the slab | M_STONE #e4dfd3 | 1.2 stelae |
| stelae | boxes | 4 of 0.6 m, 1.6-2.2 m | on the step | M_STONE #eeeae1 | 1.2 stelae |
| stele text | pixel faces | 0.35-0.5 m letters | the stelae's west faces | M_STONE #1d1f21 | 1.2 AK 1939 1945 |
| blocks | boxes | 11, 0.5-1.2 m | round the slab | M_STONE #e4dfd3 | 1.3 blocks |
| bowls | octagons | 5 of 1.2 m | south and west | M_STONE #bdb8ad | 1.3 bowls |
| flowers | octagons | 1 m, a 0.3 m heart | in the bowls | M_STONE #c8282a, #f0efe9 | 1.3 flowers |

## 9. Not built, and what only the phone can show

- The real inscription's words (lines stand in), the battalion's badge, the corten planters with
  lavender and the bust at the square's end (waiting on F's word that they stand there today).
- Phone: whether the stelae's text reads from the default camera, and whether the slab reads as
  tilted, not as a box.
