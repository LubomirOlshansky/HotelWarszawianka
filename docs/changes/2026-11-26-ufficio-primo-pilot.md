- Ufficio Primo on Wspólna is now its real self: the pale stone cube with paired windows, a deep cornice, two bronze doors with their guardians, and the big dome full of round skylights on the roof.

## Backlog
- fixed: Ufficio Primo (Wspólna 62) was a plain 17.5 m office block; now the whole 24 m building from Street View and Google 3D Tiles references
- fixed: an older street-block model (blk_25911097) stood in the same outline and drew its dome and windows over the new model in the city; `_find_blocks` skips it, and check_sites now fails on any new landmark over a street block
- found: 17 more street blocks stand inside other landmarks' outlines (Jerozolimskie 57, Prosta 28, Asbud, Torwar, Kino Muranów, Equator I and II, Dom Chłopa and more), listed as KNOWN_OVERLAPS in check_sites.gd; each needs a look and probably a skip
- found: the GUGiK orthophoto WMS (mapy.geoportal.gov.pl) is blocked from the cloud proxy and from the Mac's VM; 3D Tiles top views stand in
- found: a new site on an unnamed OSM outline needs a SITE_AREAS box in bake_sectors.py or the runtime city draws nothing there, and no check catches it
- found: cloud city shots take about 14 min each (software Vulkan); the turntable (80 s) and the new reference sheet are the inner loop
- found: Street View sees nothing of buildings set back in gardens (the Sts Peter and Paul church); 3D Tiles is their only new source
- found: the whole-map mesh check takes 6.5 min in the cloud; `--site=KEY` takes 14 s

## Roadmap
- added: "Modelling workflow: 3D Tiles and Street View first, reference-versus-model sheet, per-site checks (pilot on Ufficio Primo)"
