# The Patelnia and the Rotunda's stair (sunken places): spec

Site key `sunken` in `game/scripts/landmarks.gd` (`_build_sunken`, `_sunk_edges`, `_sunk_treads`,
`_glass_barrel`, `_sunk_doorway`); the ground itself is `map_builder.gd` SUNKEN (`sunk_floor`,
`_load_sunken`). Written 2026-11-05 from F's aerial of the Patelnia (Google 3D, attached in the
Operation Unslop thread), F's game screenshots of the Rotunda's stair ("some walls") and the mapped
geometry in `centrum.json`: the plaza (`areas` k plaza), Metro Centrum's pavilions (`landmarks`
"Metro Centrum", `buildings` 4-4.5 m), the walls round them (`lines` k wall), the stairs (`steps`)
and the GUGiK terrain grid, whose own bottom there is 9.9-10.2 m against the street's 13.3-13.6 m.

## 1. Identity

The Patelnia is the sunken square at Metro Centrum's exit, between the Palace of Culture's lawns
and the Marszałkowska / Aleje Jerozolimskie corner. What makes it read:

1. **It lies low**: about 3.4 m under the street, walled on every side, railings along the top.
2. **Two glass barrels**: Metro Centrum's stairs down to the station under two ribbed vaults of
   smoky glass, open to the square, closed against the low row of shop pavilions behind them;
   between them the pharmacy's dark box.
3. **Stairs down**: from Marszałkowska at the north-east corner, and the wide, gentle steps in the
   south-west (Schody im. Kokota) up to the Palace's park.
4. **The mural** on the south wall (site `rondo`, unchanged; it now stands on the retaining wall).

The Rotunda's stair: north-west of Rotunda PKO, between two planters, a stair down to the
Rotunda's lower floor and the underpass, under a glazed doorway at its foot.

## 2. Massing

| Volume | Plan | Heights |
| --- | --- | --- |
| Patelnia floor | the plaza and the pavilions' outline (SUNKEN ring, 36 points) | floor 10.0 m (absolute) |
| North-east stair | 3 m wide between its walls, 10 m long | from the street (grid at its top) down to 10.0 |
| Kokota stair | 4.5-5 m wide, 14.6 m long | from the street (~12.8) down to 10.0 |
| Rotunda stair | the wedge between the planters, 7.5 m wide at the top, 23 m long | 11 m of stair, 3.6 m down, then the landing |
| Retaining face | every ring edge that drops, in pieces up to 2 m | floor - 0.3 to the street + 0.12 |
| Coping | 0.3 m on top of the face, street side | street + 0.12 |
| Band | from the coping out to 3.0 m (1.6 m by the Rotunda) | the grid + 0.05 (a stair's + 0.15) |
| Railing | on the coping, 0.12 m out | top rail 0.07 m at 1.0-1.07 m, a post per piece |
| Barrel | over each pavilion outline, 15.6 x 8.0 m | half barrel r 3.85 m springing from 0.45 m, crown 4.3 m |
| Rotunda door | across the landing 2.5 m past the last step | glass 0-2.4 m, lintel to the street |

## 3. Facade, base to top

- **Retaining faces**: plain concrete, one quad per piece, from just under the floor to the coping;
  the street side shows a short face from the band up to the coping.
- **Railing**: dark steel, thin two-sided bands (a post every piece, a top rail).
- **Treads**: risers ~0.16 m across the stair's whole ring (the strip between two risers cut by the
  ring), each level with the strip's higher end; alternate treads a shade darker.
- **Barrels**: nine flat strips round the half circle, a steel rib every ~1.3 m (the mouth's
  heavier), the far end closed by a glass half-disc, the mouth open; concrete sills along both
  sides; inside a dark well and three lighter steps at the mouth (the stair going down).
- **Rotunda door**: dark glass in three steel mullions under a concrete lintel.

## 4. Roof

The barrels' glass (the cool pavilion glass, M_PAVILION + 0.5); nothing else has a roof. The site
stays out of the roof grid (`_no_roof`): no cassette or helicopter landing on a railing or a vault.

## 5. Colour and material

| Part | Colour | Material |
| --- | --- | --- |
| Retaining face | #bfb9ad | M_STONE |
| Coping, band | #cdc7bb (band by the Rotunda: planting #5f8a3f) | M_STONE |
| Railing | #3b4046 | M_STONE |
| Treads | #c4beb1, risers darker | M_STONE |
| Barrel glass | #a9b9c2 | M_PAVILION + 0.5 |
| Barrel ribs | #5c666e | M_STONE |
| Barrel well | #2a2e33 | M_STONE |
| Rotunda door | #33424d glass, #3b4046 mullions | M_GLASS_ROOF, M_STONE |

## 6. Ground and night

The ground is `map_builder.gd`'s: inside each ring terrain_height is the floor (the car, people,
props, plazas and paths follow it); the drawn ground is lowered over the ring grown by one
sub-cell's diagonal, in 1 m sub-cells (0.5 m by the Rotunda), so no sub-cell's slope shows inside
the walls; the band covers the trench that leaves outside. Wall lines lying on a ring are the
site's (`_build_barriers` leaves those pieces out). The car collides with every walled edge from
the floor to 1.6 m over the coping; the stair tops stay open. The metro canopies the bake puts on
the Patelnia's three `subway_entrance` points go (form "none"): the barrels are the entrances. At
night the barrels' glass reads blue under the night light like the tubes on the roundabout.

## 7. Detail level and budget

L2, triangle budget 5600 (4509 measured 2026-11-05 on the flat stub, `check_mesh_quality.gd`
BUDGET): an exception to the L2 range of 3000, because the site is a whole square and a second
stair: ~250 m of walled edge (~16 triangles per 2 m piece), four stairs of treads (~1200) and two
barrels (~700 each).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| face | quad per piece | up to 2 m x the drop + 0.4 m | on each ring edge, facing in | M_STONE #bfb9ad | 1 lies low |
| coping | flat top, clipped at corners | 0.3 m wide | on the face, street side | M_STONE #cdc7bb | 1 lies low |
| band | flat top on the grid, clipped | 2.8 m (1.4 m) wide | past the coping | M_STONE #cdc7bb / #5f8a3f | 1 lies low |
| railing | two-sided bands | 1.07 m tall, rail 0.07 m | coping + 0.12 m out | M_STONE #3b4046 | 1 lies low |
| treads | prisms cut by the ring | riser ~0.16 m | each stair's ring | M_STONE #c4beb1 | 3 stairs |
| glass | 9 strips and a half-disc | 15.6 m x r 3.85 m | each barrel outline | M_PAVILION + 0.5 #a9b9c2 | 2 barrels |
| ribs | annular bands | 0.12-0.22 m, 0.1 m proud | every ~1.3 m | M_STONE #5c666e | 2 barrels |
| sills | two boxes | 15.6 x 0.28 m, 0.47 m tall | along each barrel side | M_STONE #bfb9ad | 2 barrels |
| well | dark quad and three steps | 7.3 x 14.8 m | inside each barrel | M_STONE #2a2e33 | 2 barrels |
| door | glass quad, lintel, three mullions | the landing's width x 2.4 m | 2.5 m past the Rotunda stair's foot | M_GLASS_ROOF / M_STONE | Rotunda stair |

## 9. The entrance's dressing (F, 2026-11-13, twelve photos)

`game/scripts/patelnia.gd`, built at runtime on both city paths like `centralny_ramp.gd`: one mesh in
the actors' material (`models.gd`), one draw call, no building-shader cost; signs, windows and the
globes glow by the material's own night parts (LIT_SIGN, LIT_WINDOW), no lights. Nothing in it is
solid. ~12,800 triangles (murals ~1,050 quads, text merged into runs).

| Part | What | From |
| --- | --- | --- |
| Barrels' mouths | blue steel arch on two posts, blue band at 2.4-3.0 m with a small roundel and CENTRUM, the big yellow roundel with the red M over it, yellow door frames folded back, a red ticket machine outside; the barrels' ribs now blue (`BARREL_RIB`) | photos 1, 3, 6, 9, 10 |
| Pasaż Handlowy box (OSM 5588) | lit glass front, blue mullions and fascia (APTEKA 24H, WEJŚCIE), the white sign box PASAŻ HANDLOWY with six tenant tiles, a poster (BAR MLECZNY POD PATELNIĄ), the green cross on a bracket, two ticket machines and a BANKOMAT | photos 1, 5, 6, 9, 10 |
| Courts beside it | three lit shopfronts across the back under blue fascias with name boards, a blue gateway with a PASAŻ HANDLOWY board, a PRASA kiosk / a flower stall | aerials 2, 12 |
| Roof billboards (on OSM 8058, 8059) | 9 x 3.2 m at 7.7 m, facing the square: KEBAB FM 87,3 and OPTYK SOKOLE OKO (parody ads) | photos 1, 6, 9 |
| Murals (ring points of SUNKEN "patelnia") | 24-29 skyline in a blue wave with DO ZOBACZENIA, 29-0 yellow pop faces and PATELNIA, 0-4 three readers with bubbles (POEZJA!, CZYTAJ, DOBROĆ), 4-7 orange ribbon on white, 13-22 teal drips on pink; 0.1 m pixels, 3.2 m tall, cut under the wall's top; our own pictures in the themes the real walls carried | photos 2, 4, 6, 7, 8, 11 |
| The slope over the south wall | shrubs leaning over the coping (30 % in pink blossom), globe lamps every 7.5 m 4.6 m out; six more globes by the Kokota stair | photos 2, 3, 4 |
| Stairs | a steel handrail down the middle of the Kokota and north-east stairs | photos 3, 4 |
| The square's life | a busker with an amp and open case and six listeners, a breakdancer in a handstand on cardboard with a boombox and ten watchers, a painter on a ladder at the skyline mural with spray cans, an easel painter and two watching, a gold living statue on a box, a four-colour market umbrella, a green tent, two advertising columns | photos 2, 9, 12 |
