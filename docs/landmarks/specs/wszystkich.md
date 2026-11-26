# Kościół Wszystkich Świętych (All Saints, Plac Grzybowski 3/5): spec

Site key `wszystkich` (`_build_wszystkich` in `game/scripts/landmarks/churches.gd`). **Rebuilt
whole 2026-11-26** (the Codex pilot, F): the church is one model that replaces the LoD2 mass
(its SKINS entry in `fronts.gd` gets `"model": true`, like `jezuici` and `wizytki`). The 2026-11-01
version kept the LoD2 skin and modelled only the front and the towers, with domes the photos do
not show.

Written in a cloud thread from: Google Photorealistic 3D Tiles (`refs/wszystkich/3dtiles/`: eight
orbit views at pitch -25, four face views at pitch -10, the top view), six Street View images
(`refs/wszystkich/streetview/`; the church stands behind trees on both long sides, so they show
little), the Mac photo report `docs/landmarks/photo-reports/wszystkich.md` (three Commons photos
and the GUGiK orthophoto, 2026-11-06) and the LoD2 roof heights. All reference only, never
shipped or committed. The building: Enrico Marconi's design, built 1861-1892 (Józef Pius
Dziekoński finished it); neo-Renaissance, a Latin-cross basilica, one of the largest churches in
Warsaw.

## 1. Identity

1. **Twin square towers** at the two front corners, four stages each: a plain shaft, a stage with
   one tall arched window a face, a **belfry** with one large round-arched opening a face under a
   heavy cornice with corner urns, then a **round open lantern stage** (eight arched openings)
   under a **green copper bell cap**, a small lantern, a gilt ball and cross (about 55 m).
   No domes on square drums, no spires (face view 157, orbit views 135/180).
2. **The two-storey stone front** between the towers: three round-arched portals below (the middle
   one tall and wide), paired pilasters, a full entablature; above, a large round-arched window in
   a framed niche between two pedimented windows; a **low wide pediment** with a cross (face 157).
3. **Open arcades** of round arches running out from both towers along the square, one storey,
   pale stone, a low copper roof (orbit 135/180, face 157, photo report).
4. **The crossing drum**: a round drum with windows standing well above the roofs, a ribbed copper
   dome and a small lantern, near the far (south) end (top view, face 337, orbits 000/270).
5. **One huge pale-green copper roof** over the nave, hipped at the front, crossed by the
   transept's gabled roofs (top view, every orbit).

## 2. Massing

**Frame.** Origin `WSZ := Vector2(-1410.12, -159.08)`, the middle of the front on the outline.
`+v` = axis `(0.3829, 0.9238)`: from the front into the church (south-south-east; the front looks
north-north-west onto Plac Grzybowski). `+u` = `(-0.9238, 0.3829)` (west-south-west). World point
= `WSZ + u * U + v * V` with `U = (-0.9238, 0.3829)`, `V = (0.3829, 0.9238)`. Heights above the
site's ground `g` (terrain at the front middle).

The OSM outline in this frame (u, v), going round:

| part | u | v |
| --- | --- | --- |
| front (towers and screen) | -18.1 .. 18.7 | 0 |
| tower blocks reach back to | abs(u) 15.6 .. 18.7 | 0 .. 7.8 |
| nave walls | abs(u) 15.5 .. 15.8 | 7.8 .. 48.3 |
| transept arms | abs(u) up to 20.8 | 48.3 .. 63.6 |
| chancel walls | abs(u) 15.3 .. 15.8 | 63.6 .. 77.3 |
| sanctuary end (lower block) | -7.1 .. 6.6 | 77.3 .. 80.4 |

| volume | footprint (u, v) | heights |
| --- | --- | --- |
| towers W and E | u ±(10.9 .. 18.7), v 0 .. 7.8 (7.8 m square, centres u ±14.8, v 3.9) | shaft 0 .. 20, window stage 20 .. 27.5, belfry 27.5 .. 36, lantern stage 36 .. 43.5, cap 43.5 .. 48.5, small lantern 48.5 .. 51.5, ball and cross to 55 |
| front screen | u -10.9 .. 10.9, v 0 .. 1.8 (projects 0.6 m with the order) | lower storey 0 .. 11.5, upper storey 11.5 .. 21, pediment apex 24.5, cross 27 |
| nave | u -15.5 .. 15.5, v 1.8 .. 48.3 | eave 17, ridge 26 (pitch about 30°), hipped at the front end down to the pediment |
| transept | u -20.8 .. 20.8, v 48.3 .. 63.6 | eave 16, ridge 26; gable ends facing ±u with a pediment |
| crossing drum | round, centre u 0, v 56, r 5.6 | wall 24 .. 33.5, dome 33.5 .. 38.5, lantern 38.5 .. 41.5, cross to 44 |
| chancel | u -15.5 .. 15.5, v 63.6 .. 77.3 | eave 15, ridge 24, hipped at the back |
| sanctuary end | u -7.1 .. 6.6, v 77.3 .. 80.4 | eave 10, hipped roof to 12 |
| arcades W and E | u ±(18.7 .. 38.7), v 0 .. 4.5 (out from each tower along the front line, outside the OSM outline) | arches 0 .. 7.2, cornice to 8, low hip to 9.5 |

LoD2 agrees: towers' belfry tops 34-38 m, nave eave 16 m, nave and transept ridges 24-27 m,
crossing drum top 38 m (the lantern and the tower caps are above what LoD2 holds).

## 3. Facade

**Front screen (face 157).** Plinth 0 .. 1.2 (darker stone) with a broad flight of steps in front
(u -9 .. 9, v -3 .. 0, five steps to 1.2). Lower storey: three round-arched portals in deep
reveals (0.5 m): middle u ±2.4, 1.2 .. 9.6 (spring at 7.2); sides at u ±6.6, 2.6 wide, 1.2 .. 6.8
(spring 5.5). Four pairs of pilasters (0.6 wide, 0.35 proud) at u ±4.4 and ±8.8, 1.2 .. 10.5;
entablature 10.5 .. 11.5 with a projecting cornice (0.6). Upper storey: a large round-arched
window u ±1.8, 13 .. 19.2 (spring 17.4), framed by two columns and a small pediment; two
pedimented windows u ±6.6, 1.6 x 3.6 at 13.8 .. 17.4; paired pilasters on the same lines as below,
11.5 .. 20.2; entablature 20.2 .. 21 with the frieze; low pediment u ±10.9, apex 24.5, a dark
round relief on the tympanum, a cross 24.5 .. 27. Short stepped shoulders (scrolls as blocks)
link the upper storey to the towers.

**Towers.** Shaft 0 .. 20 with corner pilaster strips, a plinth 0 .. 1.2 like the screen, a string
course at 11.5 (the screen's cornice runs round), a small round window at 14 .. 16 on the front
and outer faces, a cornice at 20. Window stage 20 .. 27.5: one tall round-arched window a face
(1.6 x 4.5, sill at 21.8), corner pilasters, cornice 27 .. 27.5. Belfry 27.5 .. 36: one large
round-arched opening a face (2.6 wide, 29 .. 34.5, dark), paired corner pilasters, heavy cornice
35.2 .. 36, an urn on each corner (to 37.5). Lantern stage 36 .. 43.5: a round drum r 2.9 (16
sides), eight arched openings (dark) between eight pilasters, a ring cornice at 43. Cap 43.5 ..
48.5: a copper bell (ogee) from r 3.1 to r 0.9; small lantern r 0.8 48.5 .. 51.5 with four openings
and a tiny copper cap; gilt ball and cross to 55.

**Nave and chancel side walls (faces 067, 247, orbits 225/315).** Pilaster strips at each bay
(bays of about 8 m: v 8, 16, 24, 32, 40, 48), a plinth 0 .. 1.2, a full cornice 16 .. 17. One tall
window a bay, 2.2 x 6, 8 .. 14, under a segmental pediment. The chancel the same at its eave 15.
Transept ends: two tiers of pilasters, one large round-arched window (3 x 7, 6 .. 13), the gable's
pediment from the eave (16) to the ridge (26) with a cornice frame.

**Arcades.** Five round arches a side, bays of 4 m (piers 1.1 wide, openings 2.9 wide, spring at
5, crown 6.5), rusticated piers, a cornice 7.2 .. 8, a low copper hip roof to 9.5. The openings are
dark (seen through); a back wall at v 4.5 in the stone colour.

## 4. Roof

From the 3D Tiles top view (`refs/wszystkich/3dtiles/wszystkich_top.png`) and orbits 000/180:
- Nave: one pitched roof, ridge along v at 26, eaves 17, **hipped at the front** (a triangular
  hip face leaning back from the pediment, from v 1.8 to about v 10 at the ridge); pale copper.
- Transept: gabled, ridge across at 26 meeting the nave ridge; the gable ends carry the pediments.
- Crossing drum stands through the roofs at u 0, v 56 (centre); its top half (24 .. 33.5) shows
  above the ridge. 16 windows: eight pairs of round-arched windows (1.0 x 3.4 at 27 .. 30.4)
  between eight pilasters; a ring cornice at 33 .. 33.5; the dome 8 ribs, copper; the lantern
  octagonal r 1.4 with arched openings and a small cap.
- Chancel: pitched, ridge at 24, hipped at the back end; the sanctuary end a low hip at 12.
- Tower caps and arcade roofs as above. No skylights or plant on the copper.

## 5. Colour and material

Calmed from the 3D Tiles colours and the photo report:

| part | colour | material code |
| --- | --- | --- |
| walls, shafts, screen, arcades | `#c6b186` weathered sandy ochre (shade `#a8977a` is the light's job) | M_STONE (walls), M_MONUMENT on big plain wall slabs |
| order, cornices, frames, pediments, urns | `#d6c9a6` lighter trim | M_STONE |
| plinth, steps | `#b5aa8e` | M_STONE |
| copper roofs, caps, dome | `#96b8a4` pale green copper (the 3D views read paler than the old `#6e8f7e`) | M_STONE |
| openings, portals, belfry and arcade voids, windows | `#3a3d40` | M_GLASS for windows and doors, M_STONE for open voids |
| ball and crosses | `#c9a24a` gilt | M_STONE |
| tympanum relief | `#8f8466` | M_STONE |

No new material, light or draw call: everything is triangles in the site's mesh with the shared
building material (existing material codes only).

## 6. Ground and night

Steps across the front (part `steps`), the arcades' paving inside the arches at ground, nothing
else (the square's planter wall, benches and bollards belong to Plac Grzybowski's place work).
Collision: the outline, the steps and both arcades' footprints. The card stays: "Kościół
Wszystkich Świętych", PL "Przy placu Grzybowskim.", EN "On Plac Grzybowski." Night: the existing
landmark night look (window glow of M_GLASS) only, no new lights.

## 7. Detail level and budget

**L3** (a hero church on the first-hour route, the tallest towers on this side of the Palace).
Budget **7,000 triangles** in `check_mesh_quality.gd` BUDGET (`"wszystkich"`). Curves: towers'
lantern stage 16 sides, caps 16, crossing drum 24 sides, dome 16. Arches as the common `_arch`
helpers or 6-segment fans. Shots: `tools/turntable.sh wszystkich`, then
`tools/refs_compare.py wszystkich`, then one city shot from the square
(`--at=-1420,-185 --yaw=200 --pitch=-25`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wsz_tower | 2 square shafts + stages | 7.8 x 7.8 m, 0 .. 36 m | centres u ±14.8, v 3.9 | M_STONE | 1 towers |
| wsz_tower_windows | arched dark panels | 1.6 x 4.5 m, belfry 2.6 x 5.5 m | each face, 21.8 and 29 m | M_GLASS / M_STONE | 1 towers |
| wsz_tower_urns | small stacked boxes | 0.7 m, 1.5 m high | belfry corners, 36 m | M_STONE | 1 towers |
| wsz_tower_lantern | 16-sided open drum | r 2.9, 36 .. 43.5 m, 8 openings | on each tower | M_STONE | 1 towers |
| wsz_tower_cap | 16-sided copper bell | r 3.1 to 0.9, 43.5 .. 48.5 m | on each tower | M_STONE | 1 towers |
| wsz_tower_top | small lantern, ball, cross | r 0.8, 48.5 .. 55 m | on each tower | M_STONE | 1 towers |
| wsz_screen_lower | wall + 8 pilasters + entablature | 21.8 x 1.8 m, 0 .. 11.5 m | u -10.9 .. 10.9, v 0 .. 1.8 | M_STONE | 2 front |
| wsz_portals | 3 round-arched portals | middle 4.8 x 8.4 m, sides 2.6 x 5.6 m | u 0 and ±6.6 | M_GLASS | 2 front |
| wsz_screen_upper | wall + pilasters + entablature | 21.8 m, 11.5 .. 21 m | as lower | M_STONE | 2 front |
| wsz_front_window | arched window with columns and pediment | 3.6 x 6.2 m | u 0, 13 .. 19.2 m | M_GLASS + M_STONE | 2 front |
| wsz_side_windows | 2 pedimented windows | 1.6 x 3.6 m | u ±6.6, 13.8 m | M_GLASS + M_STONE | 2 front |
| wsz_pediment | low gable + relief + cross | 21.8 m wide, rise 3.5 m | apex 24.5 m, cross to 27 m | M_STONE | 2 front |
| wsz_steps | 5 stacked slabs | 18 x 3 m, to 1.2 m | u -9 .. 9, v -3 .. 0 | M_STONE | 2 front |
| wsz_nave | walls + pilasters + cornice | 31 x 46.5 m, eave 17 m | u ±15.5, v 1.8 .. 48.3 | M_STONE | 5 roof |
| wsz_nave_windows | 5 arched windows a side with segmental pediments | 2.2 x 6 m | bays v 12 .. 44, 8 .. 14 m | M_GLASS + M_STONE | 5 roof |
| wsz_nave_roof | pitched roof, hipped front | ridge 26 m | over the nave | M_STONE | 5 roof |
| wsz_transept | walls + gabled roof + pediments | 41.6 x 15.3 m, eave 16, ridge 26 m | u ±20.8, v 48.3 .. 63.6 | M_STONE | 5 roof |
| wsz_drum | 24-sided drum with 8 window pairs | r 5.6, 24 .. 33.5 m | u 0, v 56 | M_STONE + M_GLASS | 4 drum |
| wsz_dome | 16-sided ribbed copper dome | r 5.8 to 1.4, 33.5 .. 38.5 m | on the drum | M_STONE | 4 drum |
| wsz_dome_lantern | octagonal lantern + cross | r 1.4, 38.5 .. 44 m | on the dome | M_STONE | 4 drum |
| wsz_chancel | walls + pitched roof, hipped back | 31 x 13.7 m, eave 15, ridge 24 m | u ±15.5, v 63.6 .. 77.3 | M_STONE | 5 roof |
| wsz_sanctuary | low block + hip roof | 13.7 x 3.1 m, 10 .. 12 m | u -7.1 .. 6.6, v 77.3 .. 80.4 | M_STONE | 5 roof |
| wsz_arcade | 5 round arches a side + cornice + hip | 20 x 4.5 m, 0 .. 9.5 m | u ±(18.7 .. 38.7), v 0 .. 4.5 | M_STONE | 3 arcades |
