# Pałac Krasińskich: spec

Site key `krasinski` in `game/scripts/landmarks.gd` (`_find_krasinski`, `_build_krasinski`). Written
2026-11-02 from the Mac's reference set (`refs/krasinski/`, 17 Wikimedia Commons photos, GUGiK
orthophoto, OSM way 34614532; REPORT.md there) and GUGiK LoD2 (eaves ~16.5 m, ridge ~21.5 m).

## 1. Identity

The Krasiński Palace (Tylman van Gameren, 1677-1683; the National Library's special collections),
the white baroque palace on Plac Krasińskich. What makes it read:

1. **A long white block under a mint-green copper hip roof** (OSM says grey: wrong), a stone
   balustrade with vases along the eaves.
2. **A central risalit on both fronts under a pediment full of relief**, a statue on its apex and
   on each foot.
3. **Four corner pavilions under their own pyramid roofs**, and on the street front the wings'
   round-arched loggias and the balcony porch over the main door.

## 2. Massing

Frame: the outline's minimum rectangle (77.6 x 29.7 m): origin (-1374.23, -1687.33), u along the
axis to the SSE (0.5592, 0.8290), +v to the garden (WSW). The street front (ENE) is at v = -13.8.

| Part | Where (cu, cv, hu, hv) | Heights over the ground |
| --- | --- | --- |
| Main block | 0, -0.45, 34.3, 13.35 | -0.8 to 16.0 m |
| Corner pavilions | ±34.4, -10.2 / 10.4, 4.3, 4.1-4.4 | the same, pyramid roofs to 22.3 m |
| Street risalit | 0, -13.9, 10.4, 0.9 | the same, pediment 16.5 to 21.9 m |
| Garden risalit | 0, 13.6, 10.2, 0.8 | the same |
| Cornice | the union grown 0.45 m | 16.0 to 16.5 m, balustrade to 17.35 m |
| Main roof | 0, -0.6, 34.0, 10.6 | 16.5 m, rise 5.2 m (ridge 21.7 m) |

## 3. Facade, base to top

Plinth (the union grown 0.15 m) to 0.9 m; ground floor; a string course at 5.0-5.35 m; the piano
nobile and the top floor in M_MONUMENT's window rhythm; the cornice. Street front: six round arches
(dark navy, 2.2 m) in each wing's loggia at 6.0-10.7 m and six on the ground floor; an arched
window over the door; the carved double door in a stone portal; four columns carrying a balcony
with a balustrade at 5.0 m; three steps. Garden front: the garden door under a small balcony,
seven arches in the wings' ground floor, three steps.

## 4. Roof

Copper hip over the block inside lead walkways (the cornice's top, #a0a7ac) along both eaves; a
pyramid on each corner pavilion; the pediments' roofs run back into it. Twelve dormers (six a long
slope) with dark louvres, eight white chimneys (1.1 m, to 21.6 m). Counted from photo 11 and the
ortho (ridge along the axis, transverse gables at the risalits).

## 5. Colour and material

Walls #e6e5e0 (photos #e0e1e3, OSM's #dde0c8 is too yellow), M_MONUMENT; trim, cornice,
balustrade #c3c5bc; pediment relief #b9bbba; statues #cfd0cb; roof copper #80ad95 (the photos'
lit #a9cdb4 calmed); walkways #a0a7ac; arches #1d2a3a; door #5e432f. No new material.

## 6. Ground and night

The block sits on the terrain under its plan (`_ground_under`, plinth from -0.8 m). East: the lawn
and Andersa; west: the garden's fountain is park_details' (already there). At night the windows
take the city's glow; no floodlights. Collision: the OSM outline.

## 7. Detail level and budget

L2, 1508 triangles, budget 1810 (check_mesh_quality BUDGET "krasinski"). Shots: the street front
`--at=-1335,-1700 --yaw=90 --size=45 --pitch=-30`, the roof `--yaw=270`, the garden `--at=-1420,-1675
--yaw=180`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | union of the plan, -0.8 to 16 m | the frame | M_MONUMENT #e6e5e0 | 1 the white block |
| plinth | band | +0.15 m, to 0.9 m | the union | M_STONE #c3c5bc | facade base |
| string | band | +0.12 m, 5.0-5.35 m | the union | M_STONE #c3c5bc | facade |
| cornice | band | +0.45 m, 16-16.5 m | the union | M_STONE #c3c5bc, top #a0a7ac | 1 the eaves |
| balustrade | parapet | 0.85 m | the union +0.3 m | M_STONE #c3c5bc | 1 the balustrade |
| vases | 34 boxes | 0.44 x 0.65 m | every 3.3 m on both long fronts | M_STONE #c3c5bc | 1 the vases |
| roof | hip | 68 x 21.2 m, rise 5.2 m | 0, -0.6 | M_STONE #80ad95 | 1 the green roof |
| pavilion_roofs | 4 pyramids | 8.2 x 7.8 m, rise 5.8 m | the corners | M_STONE #80ad95 | 3 the pavilions |
| pediments | 2 gables | 21.6 m wide, 5.4 m | both risalits | M_STONE #c3c5bc | 2 the pediment |
| relief | 2 triangles | 19.2 x 4.1 m | in each pediment | M_STONE #b9bbba | 2 the relief |
| statues | 6 figures | 2.5-3.6 m | apex and feet | M_STONE #cfd0cb | 2 the statues |
| dormers | 12 boxes | 1.3 x 1.1 x 1.1 m | u ±14, ±20, ±27 | M_STONE roof, louvre #1d2a3a | 4 roof |
| chimneys | 8 boxes | 1.1 x 2.6 m | u ±12.5, ±24 | M_STONE #e5e5e0 | 4 roof |
| arches | 19 openings | 1.8-2.2 m wide | the wings | M_STONE #1d2a3a | 3 the loggias |
| porch | 4 columns, slab, rail | 6.8 x 1.9 m at 5 m | street door | M_STONE #c3c5bc | 3 the porch |
| doors | 2 portals | 3.2 x 4.3 m | both fronts | M_STONE #c3c5bc, door #5e432f | facade |
| steps | 6 boxes | 6.8-8.4 m wide | both doors | M_STONE #c3c5bc | ground |

## The garden (2026-11-06, F's aerial photos)
Site `krasinski_ogrod`, no card: the flower ring round the two fountains, a cross of lawn on gravel with flower corners and four clipped cones, two hedged lawn panels, all on the palace's axis and inside the mapped paths. Budget 900.
