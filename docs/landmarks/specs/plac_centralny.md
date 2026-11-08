# Plac Centralny (the new square before the Palace of Culture): spec

Site keys `trybuna` (with a card), `plac_centralny` and `plac_centralny_lamps` (no cards) in `game/scripts/landmarks.gd` (`_find_plac_centralny`, `_build_trybuna`, `_build_plac_centralny`, `_build_plac_centralny_lamps`), the planting in `tools/plac_centralny.py` (map data: trees, beds, benches). Written 2026-11-05 in a cloud thread from F's three reference photos and the mapped lawns, plazas and pool in `centrum.json`; reworked 2026-11-08 from F's five photos of the tribune (its south face, the planters being planted, the lawn by the pool, the aerial render, the game as it was). The square's ground slabs (tenement outlines, setts) stay `ground.gdshader`'s `centralny()` (R2).

The 2026-11-05 build misplaced the composition by about 45 m: the tribune was read as a 1.1 m "stone seat-wall" 38 m west of its real spot, and the striped field was laid west of it, over the tribune's own place, where OSM's walls and steps of the tribune drew as low grey walls and a ramp. The aerial render and the OSM outline agree: the tribune sits in the middle of the square on the axis, the striped field runs from its east face towards Marszałkowska, the lawn with the pool is north of the field, the big lawn south of it.

## 1. Identity

The square laid in 2024-25 between Marszałkowska and the Palace: pale paved plazas, big lawns round a wide axis, loose groves of young trees (locust, ash, ginkgo, magnolia), the low pool on the north lawn by the museum, the old parade tribune (trybuna honorowa, 1955) rebuilt in its original granite cladding as a multi-level viewing garden, before it the striped field of granite slabs with grass joints round a pale heart, the red WARSZAWA letters, green deckchairs, tall historic lamps.

## 2. Massing

Local frame: Marszałkowska's frame (s north, t east of the street's axis), origin s 64, t -130; u north, v east.

| Volume | Plan (u, v) | Height | Source |
| --- | --- | --- | --- |
| Tribune core | u -14.5..10.5, v -0.4..10, walls battered 0.15 m | 2.4 m | OSM walls, photo 7595 |
| Sitting steps | u -13.7..9.7, v 1.2..4.6, three steps | 2.8 / 3.25 / 3.7 m | photo 7595 (the zig-zag) |
| Walk | v 4.6..6.4 | 4.1 m | render |
| East planter | v 6.4..10, coping rim 0.25 m | soil 4.3, rim 4.55 m | photos 7594, 7595 |
| Side cheeks | 0.8 m thick, a step above the seats | 3.15..4.45 m | photo 7595 |
| Corner piers | u ±12.1 from the middle, v -0.4..1.2 | 3.3 m | photo 7595 (the plaque) |
| West stair | u -1.5..4.5, v -4.5..-0.4, 15 risers | to 2.4 m | OSM steps and west wall |
| Stair planters | u -5.3..-1.5 and 4.5..8.4, v -4.5..-0.4 | 1.2 m | OSM west wall, photo 7594 |
| Striped field | u -15..19, v 10.4..48, 24 rows | 0.07 m | render |
| Pale heart | u -3..7, v 10.4..36 | 0.09 m | render (the lost tenement's outline) |
| Sign | at the heart's east end, facing east | letters 1.9 m on posts 1.3 m | photo 3 (2026-11-05) |

## 3. Facade, base to top

Tribune: light grey granite ashlar (#bab6ad), lighter coping (#d4d0c6). The east face to Marszałkowska is a plain 4.3 m wall under the planter's rim. The south and north faces step up with the seats behind them (the photo's zig-zag). A dark bronze plaque with the old photo on the south pier's south face.

## 4. Roof

The top is the garden: the paved landing, the three granite sitting steps, the walk and the long planter with five young trees; two more trees and low shrubs in the stair planters.

## 5. Colour and material

Granite #bab6ad, coping #d4d0c6, soil #5f7d3c, leaves #7fa04a, trunks #5a4a3a, plaque #3a3833; field slabs #c4beb3, grass joints #6f9e42, pale heart #d3cbbf, letters red #c9242b, deckchairs green #58a85a, lamp posts #3d4146.

## 6. Ground and night

Lamp heads glow (M_LAMP). The sign is a landmark sign (lit day and night). OSM's wall lines and flights inside the tribune are not drawn (map_builder.gd `TRYBUNA_ZONE`): the model has its own.

## 7. Detail level and budget

L2. Triangle budgets in `check_mesh_quality.gd`: `trybuna`, `plac_centralny`, `plac_centralny_lamps`. Shots: `--at=-1078,196 --size=40` from the default angle and with `--yaw=180`.

## 8. Open (photo check)

The real heights (the east face and the piers are read off one photo by eye), the stair's exact width and the shrubs' spots; whether the field's stripes are granite with grass joints (ZDM's "zielona fuga") or wooden decking.
