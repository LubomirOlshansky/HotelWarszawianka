# Syrenka na Powiślu: spec

Site `syrenka_powisle` in `game/scripts/landmarks/river.gd` (`_build_syrenka_powisle`,
`_syrenka_powisle_figure`, `_drape`); the plaza round it is the place `syrenka_plaza.gd`.
Rebuilt 2026-11-20 (F asked: "the mermaid is missing, and the new glowing fountains, and the metro
entrance; redo this plaza properly"). First written 2026-11-01 without photos, from the bake's
guessed point.

Sources (reference only, never committed or shipped): F's photos of 2026-11-20 (the statue close
up, July 2023; the plaza at night with the lamps in the paving, April 2024; the sandstone wall with
its spouts from the lower boulevard, July 2019), the refs store's `_f/warsaw-needed-photos/powisle/F03/`
(three Commons photos: day from behind, dusk side, detail), the GUGiK orthophoto (WMS
HighResolution, three crops round 52.2403 N, 21.0321 E, viewed on the Mac 2026-11-20), the
monument's Wikipedia article (statue 2.75 m, monument about 6 m, pedestal of three sandstone blocks
in a fountain basin; Ludwika Nitschowa, 1939; basin by Stanisław Pomian-Połujan).

## 1. Identity

The riverside Mermaid: a bronze mermaid, kneeling on her scaled tail on a rock of waves, the
round shield with the city's eagle on her left arm, a broad straight sword raised level over her
head, the tail sweeping up behind into a fan. She stands at the edge of the upper boulevard by the
Copernicus Science Centre, over the road tunnel, where the ground drops to the lower boulevard by
the river; the metro's stair is 17 m to her south-east. She faces down the slope, to the river and
Most Świętokrzyski. Until this rebuild she stood 48 m east on the lower promenade (the bake had no
mapped artwork there and guessed a point by the water).

## 2. Massing

Frame: origin (550.8, -692.0) (the centre of OSM's mapped basin, which matches the orthophoto), `u`
down the slope (0.755, -0.656), `v` her right.
The upper ground `g` is the higher of the terrain at the basin's back and under her; the foot is
the terrain 0.4 m past the wall (at least 0.9 m under `g`; the game's 10 m terrain grid makes the
real 3.4 m drop a slope, so the wall is lower than the real one).
Basin u -2.45..2.45, v ±5.15: a sandstone body from the foot to the water (g + 0.18), rim 0.4 m wide
to g + 0.5 on the back and sides. Front ledge u 2.45..3.7 to g - 0.35 with a sill; the wall's face at
u 3.7 down to the foot. Pedestal at u -0.3: footing 2.8 x 2.4 m to g + 1.0, the tall block
1.9 x 1.6 m to g + 2.55, the cap 2.2 x 1.9 m to g + 2.85; the bronze wave rock 1.76 x 1.36 m to
g + 3.3. The figure as cast (2.75 m to the sword) drawn 1.15 times: the head's top at about
g + 5.9, the sword at g + 6.4.

## 3. Facade

Sandstone, base to top: the wall's face in ashlar courses 0.47 m high with staggered joints
(1.2 m stones), three arched niches 0.64 m wide at v -2.6, 0, 2.6 with a bronze spout each and the
water falling to the strip at the foot; the ledge's sill; the rim. The pedestal's three blocks,
the middle one lighter. The bronze: the fish body from the hips forward onto the rock and round
her left side, up behind her into a five-rib fan, three light scale bands; hips, waist, chest and
shoulders as frustums; the neck, the head and the bun at the nape; the right arm up to the fist
over her head with the sword level and the blade to her left; the left forearm down to the
shield before her left hip, its face turned out and a little left, rim, face and boss.

## 4. Roof

None. The cobbles and the water strip are draped on the ground out of the roof grid; the basin,
wall and pedestal are in it (the helicopter lands on neither).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Sandstone (body, wall, rims, pedestal) | #cdb48a, light #dcc8a2, shade #b39a73 | M_STONE |
| Joints | #9a8462 | M_STONE |
| Basin water | #3f6f86 | M_STONE |
| Spouts' water | #bfe6f2 | M_LAMP (glows at night) |
| Water strip at the foot | #3f6f86 darkened | M_STONE |
| Cobbled slopes | #5d5f63 in a checker | M_STONE |
| Bronze | the Old Town set (#7ba892, #5a8873, #3f6656, #a8d0bb) | M_STONE |

No new material or draw call.

## 6. Ground and night

Card "Syrenka na Powiślu" (PL and EN). The car meets one collision ring round the basin and the
wall (u -2.45..3.7, v ±5.15). The cobbled slopes (v ±5.15..8.55, from u -0.8) and the water strip (u 3.7..6.1) are
draped 0.035-0.05 m over the ground in 0.5-0.6 m cells. At night the spouts' water glows, the egg's
cool floodlight (eggs.gd, now at her measured spot, 5.2 m up) lights her, and behind her the water
mirror's light strips and mist jets glow (syrenka_plaza.gd).

## 7. Detail level and budget

L2. Budget 1400 triangles (`check_mesh_quality.gd`); built 1076 on the turntable's flat map.
Turntable: `tools/turntable.sh syrenka_powisle`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| basin | box and three rim boxes | 4.9 x 10.3 m, rim 0.4 m | u -2.45..2.45 | M_STONE | 1 fountain basin |
| ledge | box, sill | 1.25 x 10.3 m | u 2.45..3.7 | M_STONE | 2 front |
| wall | courses, niches, spouts, falls | 10.3 m wide, foot to ledge | u 3.7 | M_STONE, M_LAMP | 2 front |
| strip | draped cells | 2.4 x 10.3 m | u 3.7..6.1 | M_STONE | 2 water at the foot |
| slopes | draped cells | 3.4 m wide each side | v ±5.15..8.55 | M_STONE | 2 cobbles |
| pedestal | three boxes | 2.8, 1.9, 2.2 m wide | u -0.3 | M_STONE | 3 pedestal |
| rock | box, three wave beams | 1.76 x 1.36 x 0.45 m | on the cap | M_STONE | 3 wave rock |
| figure | beams, frustums, prisms, discs | 2.75 m x 1.15 | on the rock | M_STONE | 4 bronze |
