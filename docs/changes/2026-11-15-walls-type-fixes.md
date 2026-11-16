## Backlog
- fixed: walls look W3, the type fixes from the photos as a guarded pass (`tools/object_types.py` version 2, in `check_post_passes.py`): Plac Grzybowski's planting beds and 29 more default walls in squares are knee-high planter edges (low_wall, R); the 27 hedges of the Royal Castle's lower garden are tall hedges; the stadium's 19 perimeter lines carry #808's `stadium_fence` by id and its 6.2 m fences are ball-stop nets (`game/data/road_objects.json` `types`, the exception file's first use); one id, one look for `stadium_fence`. Nothing changes in the classic look
- found: the bollard-row rule (`kerb_posts`) failed its 20-sample check (0 of 6 judged right): the default share went 11.9 % to 11.5 %, not to the 9 % the walls doc aimed for (QUESTIONS)
- found: five of the stadium's 6.2 m fences on the podium's edge are hard by the drop and typed `parapet_concrete` / `guard_rail`; their light type (a net) would contradict the hard class (QUESTIONS)
- found: Legia's 6.4 m fences are tagged `fence_type=railing` (bars_black): the typed look clamps them to 2.5 m (QUESTIONS)

## Roadmap
- ticked: "Left: walls, fences and rails that look real": the W3 half of "W2 the game reads the types: ...; W3 type fixes from the photos as a pass (planter edges, bollard rows, the stadium's fence)" (with W2 the line is done; the bollard rows went to the sweeps, their rule failed its photo check)
