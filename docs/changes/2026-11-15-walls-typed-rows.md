## Backlog
- fixed: the game reads the barrier types (walls look W2): a `looks` row per type in the palette, heights from `hs`, light fences as thin posts and rails, behind `barrier_look`, which stays `classic` (nothing changes by default; `--barriers=typed` for a run or a bake)
- found: the walls doc gives `rail_waterfront` no post width; the row has 0.06 m (the classic railing's) until it does
- found: under `typed` the two `removed` fragments (3.5 m each, by the Vistula and in Powiśle) are not drawn and stop colliding, as their row says; classic draws them
- found: thin typed rails and crossed-quad posts may flicker at the default zoom while driving: only the phone can show it (PHONE-CHECK part 2, row 7b)

## Roadmap
- ticked: "Left: walls, fences and rails that look real": the W2 half of "W2 the game reads the types: a look row per type, heights by setting, thin see-through fences, behind `barrier_look` (classic by default); W3 type fixes from the photos as a pass" (W3 stays open)
