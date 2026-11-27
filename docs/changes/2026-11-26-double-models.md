- Seventeen buildings that were drawn twice, one model inside another, now have one model each: no more flickering walls or mixed roofs at Aleje Jerozolimskie 57, Prosta 28, the Towarowa towers, Bellona, Marszałkowska 99, the blue tower on Plac Powstańców, Brama Zachodnia, Babka Tower, the Missionaries' house on Radna and Nowy Świat 4A; the Pekao and Equator towers keep their detailed street-block body.

## Backlog
- fixed: 17 street blocks inside landmark outlines (check_sites KNOWN_OVERLAPS, 2026-11-26): 11 blocks skipped (fronts.gd LM_BLOCKS), 3 towers build only their sign on the block (TOWERS `on_block`: pepeo_tower, equator, equator2), 3 kept as dress over the block by design (torwar, dom_chlopa, kino_muranow: check_sites DRESSES_BLOCK); about 59k triangles and their colliders gone, no draw-call change
- fixed: 4 photo-front houses inside a landmark's outline (Aleje Jerozolimskie 92 in brama, Radna 14 in church_misjonarze_radna, Babka Tower in babka, Nowy Świat 4A in ns4a, built whole by #1094), dropped from photo_fronts.json
- found: check_sites now fails on any street block, photo-front house or other site inside a landmark's outline (NESTED lists the 9 scenes that nest by design)
- found: Kino Muranów's own model, without the block under it, leaves a bare sloped deck: it needs a whole-building pass (3D Tiles workflow)
