## Backlog
- found: the walls look was planned again after F's four answers (docs/design/walls-true-to-life.md sections 6, 8, 9, 10; docs/design/city-objects-plan.md section 5.2): phases W2 to W10, each behind the palette's `barrier_look` key, which stays `classic` until F's phone look
- found: every line has a type since step 5 and the game still draws by the old styles: 157 km of fence is one grey band, 62 km of wall one beige slab; W2 makes the game read `ty` and `hs`
- found: an unknown wall in a square is a knee-high planter edge, drawn 1.6 m and hard today (Plac Grzybowski: 10 of 10 lines on the photos of 2026-11-15); W3's pass `ctx_square`
- found: some unknown fences along Wola's kerbs are bollard rows (Prosta, Grzybowska); a new type `post_row`, W3
- found: the stadium's sixteen 6.2 m fences are typed as lawn guards and bar fences; a new type `stadium_fence` and their ids in the exception file, W3
- found: hedges mapped 3 to 5 m in the fountain park by Wybrzeże Gdańskie are typed `hedge_low`; W3
- found: `tools/object_types.py` is not in `tools/check_post_passes.py`'s list, so nothing holds it as a pass (TD-25); W3 adds it
- found: heavy wall detail needs no room in the building shader (geometry and vertex colour on its prop path), so TD-9 does not block it; each phase's gate is `check_shader_budget` unchanged at 501
- fixed: F's four defaults for walls and fences are answered (all as recommended) and out of the Waiting list

## Roadmap
- ticked: "Left: walls, fences and rails that look real": the types in the bake (W0, W1) are done since step 5 (#759); the three open lines there are replaced by the ones below
- added: "Left: walls, fences and rails that look real": "W2 the game reads the types: a look row per type, heights by setting, thin see-through fences, behind `barrier_look` (classic by default); W3 type fixes from the photos as a pass (planter edges, bollard rows, the stadium's fence)"
- added: "Left: walls, fences and rails that look real": "W4 the panel trial, W5 every light type as a panel, W6 panels that fall and stand again"
- added: "Left: walls, fences and rails that look real": "W7 walls with foot, cap, bays and piers; W8 gates where paths cross; W9 graffiti, hoardings, ivy; W10 sweeps and the ratchet"
- added: "Left: the phone": "F's look at a city baked `typed`, then `panels` (device run or a build F allows); then the `barrier_look` key changes"
