# Złote Tarasy: spec

Site key `tarasy` in `game/scripts/landmarks.gd` (`_find_sites`, `_build_tarasy`,
`_tarasy_wave`). Written 2026-10-31 in a cloud thread from the OpenStreetMap parts in
`centrum.json` (the complex is mapped in 3D: eight glass domes for the roof, the mall's podium
parts at 14 to 17 m, the two Lumen wings on the podium, Skylight, the drum and the south
block's terraces, all with heights) and the earlier glass-wave model. The reference photos in
`refs/zlote_tarasy/` live on the Mac and were not reachable from the cloud: the values marked
*(photo check)* are the ones the side-by-side check on the Mac should confirm or move.

## 1. Identity

The Jerde Partnership's mall and offices (opened 2007) between Złota, Emilii Plater, Al. Jana
Pawła II and Warszawa Centralna, south-west of the Palace of Culture. What makes a passer-by
say its name:

1. **The rolling glass roof**: one undulating "bubble" of glass over the mall's atrium,
   highest by the offices (35 m), sweeping down towards the station (22 m and to the plaza).
2. **The terraced mall under it**: floors of shops stepping back under the glass, seen through
   the roof's rim walls, lit warm floor by floor at night.
3. **Lumen**: the office crescent wrapping the mall on Złota and Jana Pawła II, white ribbons
   between silver-blue glass, standing on the mall's podium.
4. **Skylight**: the 105 m tower on the Emilii Plater corner, a rounded blue-green curtain wall
   with a lit glass crown.
5. **The south block's terraces**: the cinema block stepping up from the plaza with a planted
   roof, and the round glass drum on the station side.

## 2. Massing

World plan (x east, z south, metres). The outline `Złote Tarasy` spans x -1581..-1355,
z 339..532. Everything with its centre inside it is the landmark; each part keeps its mapped
outline and heights (mh to h above the site's ground, the lowest terrain under the outline).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Glass wave | 8 domes, centres about (-1495, 409) to (-1432, 440), radii 18-22 m | caps to 35 m (6 domes) and 22 m (2 towards the station), rim a seventh of that | OSM parts #336699 h 35 / 22 |
| Wave floor | the 77-point glass part under the wave's south sweep | 0 to 3 m | OSM part #336699 h 3 |
| Mall podium | the parts round the wave, west, north and east | 0 to 14-17 m | OSM parts h 14-17 |
| Podium plates | the thin parts on the podium by Lumen and Skylight | 17 to 18 and 17 to 27 m | OSM parts |
| Lumen west wing | crescent, x -1548..-1481, z 362..460 | 17 to 55 m | OSM "Lumen" h 55, mh 17 |
| Lumen north wing | crescent, x -1478..-1387, z 355..394 | 17 to 55 m | OSM "Lumen" h 55, mh 17 |
| Skylight | rounded D, x -1413..-1355, z 403..440 | 0 to 105 m, crown to 113 m | OSM "Skylight" h 105 |
| Drum | circle about (-1459, 476), 27 points | 0 to 30 m, rim 30 to 30.5 m | OSM parts |
| South block | the hall at (-1503, 499) and the parts on it | 14 to 35 m, roofs 35 to 41 m | OSM parts |

## 3. Facade, base to top

- **Mall podium (0-17 m)**: sandstone walls with a white grid of golden shop glass (skin
  S_GRID), the bottom 4.5 m a lit lobby band (shopfronts). The planted terraces' parts
  (mapped #6EBE9F) the same walls under a green roof.
- **Wave rim**: where the wave stands clear of the ground, glass walls from the ground to the
  roof (M_PAVILION): mullions every 1.6 m, a floor every 4.2 m, lit warm bay by bay at night:
  the terraces of shops seen through the glass.
- **Lumen (17-55 m)**: horizontal white ribbons every 3.2 m between silver-blue glass, thin
  mullions every 3 m (skin S_RIBBON) *(photo check: the ribbons' share, the ends)*.
- **Skylight (0-105 m)**: blue-green curtain wall with silver floor bands and 1.5 m mullions
  (skin S_BANDS); the crown: the curtain wall carried 8 m above the roof and leaning in by 18 %
  of the way to the centre, glass lit cool white at night *(photo check: the crown's height
  and lean)*.
- **Drum (0-30 m)**: golden glass lit warm from inside, a sandstone rim on top.
- **Red boxes**: the small mapped parts at the Jana Pawła II entrance (mapped tomato), plain
  red stone *(photo check: what they are)*.

## 4. Roof

The glass wave: one surface over the eight domes, each a cap rising to its mapped height,
blended where they overlap so the roof rolls instead of creasing, on a 3 m grid, laid on the
ground's slope; a white diamond lattice every 3.4 m in the shader (M_GLASS_ROOF). The wave
floor's top in the same glass, so the roof reads as sweeping down to the plaza. Podium roofs
flat grey (#a49d90), the south block's terraces planted, Lumen's and Skylight's roofs flat grey.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass wave and the wave floor's top | #d4b066 (golden glass, the landmarks loop) | M_GLASS_ROOF |
| Wave rim walls, wave floor walls | #b9a983 | M_PAVILION (+0, warm at night) |
| Podium walls | #d9c7a0 sandstone, glass #c8b27e | M_SKIN S_GRID |
| Podium roofs | #a49d90 | M_STONE |
| Planted terraces' roofs | #8a9a72 | M_STONE |
| Lumen | glass #9fb0b8, roof #8e9497 | M_SKIN S_RIBBON |
| Skylight | glass #6f9cb0, roof #a7b3b8 | M_SKIN S_BANDS |
| Skylight's crown | #b9d2dc | M_PAVILION (+0.5, cool at night) |
| Drum | #c9b98f, rim #d9c7a0 | M_PAVILION (+0), M_STONE |
| Red boxes | #c0624c | M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

The plaza and the paths on the station side stay the map's. The car collides along the wave's
rim and along every part standing on the ground (as the map's buildings did). At night the
wave glows warm through its lattice, its rim walls and the drum glow floor by floor, Lumen's
and Skylight's offices are lit in their skins' share, Skylight's crown glows cool white over
the skyline. Card: "Złote Tarasy", PL "Centrum handlowe pod falującym szklanym dachem, obok
biurowce Lumen i Skylight. Otwarte w 2007 roku.", EN "A shopping centre under a rolling glass
roof, with the Lumen and Skylight office buildings. Opened in 2007."

## 7. Detail level and budget

L3 (a first-scene hero), triangle budget 5700 (4762 measured after the build, plus about 20 %,
in `check_mesh_quality.gd` BUDGET; the wave alone is about 2400). The podium, Lumen and
Skylight were drawn before as the map's plain buildings, so the city gains far fewer than the
difference. Shots: `--solo=tarasy --solo-look=sil` and `flat` (the `first` set), then in the
city at day and night from the station side.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wave | height field over 8 domes, 3 m grid | about 110 x 90 m, 22-35 m | the domes | M_GLASS_ROOF #d4b066 | 1 glass roof |
| rim | glass walls round the wave's edge | ground to the wave | where the wave stands clear | M_PAVILION #b9a983 | 2 terraces seen through |
| floor | mapped prism | 0-3 m | the 77-point part under the south sweep | M_PAVILION walls, M_GLASS_ROOF top | 1 glass roof |
| podium | mapped prisms | 0-14/17 m | round the wave | M_SKIN S_GRID #d9c7a0 / #c8b27e | 2 terraced mall |
| terraces | mapped prisms, green tops | 0-17, 35-41 m | west side, south block | M_SKIN S_GRID, roof #8a9a72 | 5 south terraces |
| lumen | 2 mapped crescents | 17-55 m | Złota and Jana Pawła II | M_SKIN S_RIBBON #9fb0b8 | 3 Lumen |
| skylight | mapped prism | 0-105 m | Emilii Plater corner | M_SKIN S_BANDS #6f9cb0 | 4 Skylight |
| crown | frustum, 18 % in | 105-113 m | on Skylight | M_PAVILION +0.5 #b9d2dc | 4 Skylight |
| drum | mapped cylinder and rim | 0-30.5 m | (-1459, 476) | M_PAVILION #c9b98f, rim M_STONE | 5 drum |
| red | mapped prisms | 0-11 m | Jana Pawła II entrance | M_STONE #c0624c | 5 entrance |

## Update 2026-11-05 (F's photos + the Mac gather, refs/skylight/REPORT.md)

- **Skylight** (`_tarasy_skylight`): light silver-grey cladding with a dark window dash per floor (not
  a blue-green curtain wall); 26 floors of about 3.3 m, 105 m as mapped; dark lobby glass with a 5 m
  canopy; a 4-floor glazed belt at 20-33 m. The lit glass frustum crown is gone: the east half
  of the roof stays at 105 m, the west half is scooped to 100 m with an oval glass cap.
- **The screen block**: the mapped plate over the entrance (x -1409..-1368, z 437..449) is a graphite
  box 17 to 38 m; the 3D LED screen (`tarasy_screen.gd`) hangs on its south face and curved west
  return, an L in plan, 44 x 20 m.
