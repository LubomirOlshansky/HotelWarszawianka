# Warsaw Spire: spec

Site key `spire` in `game/scripts/landmarks.gd` (TOWERS row `spire` with its `with` points,
`_build_tower`, `_spire`, `_spire_spines`, `_spire_crown`, `_spire_columns`, `_spire_canopy`,
`_spire_wing`, `_spire_plaza`, `_spire_water`) and the moving parts in `game/scripts/spire_motion.gd`
(the crown's LED ticker, the plaza's jets; shaders `spire_ticker.gdshader`, `spire_jets.gdshader`).
Rebuilt 2026-11-06 from F's ten photos (IMG_7328 to 7337 and the four of the second round, IMG_7349 to 7352: the tower from the plaza, the street,
the night plaza, the aerial at dusk, the canopy from below, the steel columns, Spire B and C, the
pebble channel, a design render) and the OpenStreetMap plan, parts, pools and planters in
`centrum.json`. The first rebuild (2026-11-02, three photos) gave the flaring shaft, the fin and the
beak canopy; this pass replaces them.

## 1. Identity

The Warsaw Spire (Plac Europejski, 2016): a 180 m glass tower (220 m with its masts) between two
55 m crescents, Spire B (east) and Spire C (north-west), round a plaza of pools and trees. What
makes a passer-by say its name:

1. **The flaring shaft**: slim at the lobby, its sides concave as it flares out to its widest at about 150 m, drawn in a little to the roof (IMG_7329, 7333; F: concave, not convex).
2. **The crown**: an open steel ring round a pale ribbed drum on the roof, rising to horns at the narrow ends (IMG_7351, 7352).
3. **The brand's moving sign** on the crown: here an LED ticker with the parody SAMSONG adverts.
4. **The polished steel columns** in Λ pairs round the set-back lobby (IMG_7337).
5. **The mirrored canopy** over the entrance, a wide bow with upswept tips (IMG_7336, 7337).
6. **Spire B and C**: blue glass, a pale stone top storey, a thin white roof edge (IMG_7330, 7331).
7. **The plaza**: a big pool with a fountain and planted islands, two small pools, a pebble channel,
   honey locusts and slim swamp cypresses (IMG_7330, 7332, 7334).
8. **Night**: the spines lit up each narrow end, the ticker glowing, the jets lit.

## 2. Massing

World plan (x east, z south). The tower's mapped outline is its widest plan: x -2743..-2698,
z 171..232, an egg 45 x 61 m, the long axis north-south; the entrance and canopy at the north end.

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Lobby | ring(10 m) x 0.9, set back | 0 to 10 m, lit glass | IMG_7337 |
| Shaft | outline x k(h): 0.66 + 0.34 (h/150)^1.9 (concave) to 1.0 at 150 m, 0.93 at 180 m (`SpireMotion.k_at`) | 10 to 180 m, 14 rings | IMG_7329, 7333 |
| Crown | an open steel ring on the roof rim (S_FRAME), a pale ribbed drum in two tiers inside | ring 186 m over the wide faces, horns to 198 m at the ends; drum 187 and 191 m | IMG_7349-7352 |
| Spines | 2 m strips 0.15 m proud on each narrow end | 10 m to the crown's tips | IMG_7332 |
| Ticker | a band on the shaft's ring, 0.25 m proud | 165.5 to 171.1 m | F's ask, IMG_7336 |
| Columns | about 18 Λ pairs, 0.75 m, heads under the shaft's edge | ground to 10 m | IMG_7337 |
| Canopy | a bow 16 m wide at the glass, 42 m at its tips, reaching 16 m out | 11 m at the glass, 12.2 m middle front, 18 m tips | IMG_7336, 7337 |
| Masts | two 1 m posts at the OSM parts' spots | 180 to 220 m | OSM parts |
| Spire B, C | the mapped crescents | glass 5-51 m, top storey 51-55 m, eave 1 m out, plant screen to 58 m | OSM (h 55), IMG_7330, 7331 |
| Plaza paving | a half disc 52 x 22 m north of the lobby, bollards | 3 cm | first rebuild |
| Pools | the three mapped pools, granite kerbs 0.45 m wide, 0.35 m high; the basin 0.55 m | ground | OSM, IMG_7334 |
| Islands | three 1.8 m round planters in the big pool, a tree each | 0.45 m | IMG_7332 |
| Channel | 2.6 m wide along Spire B's west face, z 181 to 215, kerbed | ground | IMG_7330 |
| Jets | 20: the basin's 3.4 m middle jet and a ring of 8, 2 in each small pool, bubblers in the channel | 0.45 to 3.4 m, bobbing | IMG_7330, 7332 |
| Trees | a honey locust on each mapped planter (18), 3 on the islands, 5 swamp cypresses | 6.5 to 11 m | IMG_7330, 7332, 7334 |

## 3. Facade, base to top

- **Lobby** (0 to 10 m): dark glass (#2c4656) lit cool at night (M_PAVILION + 0.5); the shaft's
  underside over it polished steel.
- **Shaft**: blue mirror glass (#5a8ecb, S_MIRROR: sky in slow streaks, a fine silver line at each
  floor, a hairline mullion every 2.4 m).
- **Spines**: #86acd0, lit cool white at night.
- **Crown**: the shaft's glass outside, pale grey-blue inside (#8ea4b5), a steel coping.
- **Ticker**: black LED panel, white slogans, SAMSONG in light blue, amber dots between; brighter at
  night. Text (Polish on the sign, English in `spire_motion.gd` ADS): SAMSONG GALAKTYKA Z26 ·
  SKŁADA SIĘ SZYBCIEJ NIŻ TWÓJ BUDŻET · BATERIA WYTRZYMA KOREK NA TOWAROWEJ · APARAT 200 MPX:
  WIDAĆ KONIEC REMONTU · RATY 0% DO 2050 ROKU. 7 m/s, seamless (a whole number of text laps).
- **Spire B, C**: blue mirror glass (#4778b0) over a dark lit ground floor (#28404e, 5 m); top
  storey pale stone panels between slim posts (#c4b69c, S_FINS); a thin white eave (#dfe4e7).

## 4. Roof

Flat at 180 m (#b9c4cc) inside the crown, a plant box, the two masts to 220 m, aviation lights.
Spire B and C: flat grey-blue stone, the eave, a plant screen set back 3.5 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shaft, crown outside | #5a8ecb | M_SKIN + S_MIRROR |
| Lobby | #2c4656 | M_PAVILION + 0.5 |
| Columns, legs, soffit, canopy | #c3ccd3, #d3dde4 top, #8e9aa3 under | M_GOLD + 0.5 (polished steel: sky streaks, no warm glow) |
| Canopy rim | #f0f3f4 | M_STONE |
| Spines | #86acd0 | M_PAVILION + 0.5 |
| Wings | #4778b0; top #c4b69c; eave #dfe4e7 | M_SKIN + S_MIRROR, M_SKIN + S_FINS, M_STONE |
| Kerbs, islands | #9a9a96, soil #56703a | M_STONE |
| Channel | #6f8f95 | M_STONE |
| Trees | locust #8daa48, cypress #5f7f36, trunk #4a3f35 | M_STONE |
| Ticker, jets | shader | their own ShaderMaterial (one draw call each) |

## 6. Ground and night

The tower and wings stand on the lowest ground under their outline; the plaza pieces on the
ground under each. At night: the lobby, the wings' ground floors and the spines glow; the ticker
brightens past the bloom threshold; the jets glow cool blue.

## 7. Detail level and budget

L3. Mesh budget 6600 triangles (check_mesh_quality; 6151 built), up from 2700: 13 shaft rings of ~60 sides,
the crown screen and coping, ~36 columns, the canopy bow (two skins of 24 quads and a rim), the wings'
extra storey and eaves, the kerbs, islands, channel and 26 trees. No new building materials (+0
draw calls in the city mesh). The ticker and the jets are two small meshes with their own shaders:
+2 draw calls when in view, no per-frame script. Phone bench still to run.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lobby | prism, ring(10 m) x 0.9 | 29 x 40 x 10 | outline centre | M_PAVILION + 0.5 | the set-back lit lobby |
| shaft | 14 lofted rings | 45 x 61 x 170 | outline centre | M_SKIN S_MIRROR | the flaring glass tower |
| crown | two-sided screen and coping | 39 x 52 x 2-11 | roof rim | M_SKIN S_MIRROR, M_STONE, steel | the saddle crown |
| spines | lofted strips | 2 x 0.15 x 190 | both narrow ends | M_PAVILION + 0.5 | the lit spines |
| columns | ~36 beams in Λ pairs | 0.75 x 0.75 x 10 | round the lobby | M_GOLD + 0.5 | the steel columns |
| canopy | bow of 24 quads, two skins, rim, 4 legs | 42 x 16 x 7 | north end, 11-18 m | M_GOLD + 0.5, M_STONE | the mirrored canopy |
| masts | two posts | 1 x 1 x 40 | OSM part spots | M_STONE | the beacon masts |
| ticker | strip on the ring | 155 x 5.6 | 165.5-171.1 m | spire_ticker.gdshader | the running adverts |
| wing-b, wing-c | crescent prisms, top storey, eave, plant screen | 22 x 76 x 58, 22 x 60 x 58 | mapped outlines | M_SKIN S_MIRROR, S_FINS, M_STONE | Spire B and C |
| plaza | half disc, 11 bollards | 52 x 22 x 0.9 | north of the lobby | M_STONE | the paved front |
| kerbs | granite rings | 0.45 x 0.35-0.55 | round the mapped pools and basin | M_STONE | the pools' edges |
| islands | round planters | 3.6 x 0.45 | in the big pool | M_STONE | the planted islands |
| channel | strip and kerb | 2.6 x 35 | Spire B's west face | M_STONE | the pebble channel |
| jets | 20 cones with splash rings | 0.45-3.4 m | basin, pools, channel | spire_jets.gdshader | the fountains |
| trees | trunk and cones | 6.5-11 m | planters, islands, by the pool | M_STONE | locusts and cypresses |

## 9. Open

- Phone look and bench (the ticker's text size from the follow camera, the jets' bob).
- The real canopy's double curve is a three-band bow here; the crown's points follow the photos'
  silhouette, not drawings.
- The design render (IMG_7335) shows rectangular fountain basins and café umbrellas; the photos
  show the pools as built, which we follow.
