## Backlog
- fixed: W8 of the walls look, gates and gaps, is built behind `barrier_look` `typed` and `panels` (classic on main; nothing a tester sees changes): a new map pass, `tools/barrier_gates.py` (in `bake_osm.py` and `check_post_passes.py`, verify step `barriergates`), opens 326 gaps (834 m) where a footway crosses a fence, wall or hedge through OpenStreetMap's gate node (the old strict cut never saw them), and marks 556 line ends that already face an opening across a path or a drive; the builder leaves each gap open and stands gate posts 0.3 m taller than the line at its edges and at those ends. The car's openings are as wide as before; colliders only lose the gaps' lengths
- found: the open-gate leaves for drives failed their photo check (of the 14 service-road openings the street photos showed, 6 are gates and 8 are open car-park mouths, plaza drives, a barrier arm, a roller shutter, low lawn fences), so service openings get posts only; the leaf rule stays in the pass behind a switch for a better test (a gate node or `barrier=gate` from OpenStreetMap)
- found: one footway gap at Port Czerniakowski is a closed gate with a no-entry sign on the photos (a `barrier=gate` with `access=no` would say so: not read yet)
- found: 128 footways only end on a fence (a dead end on the map); they get no gap

## Roadmap
- progress on "Hoardings, graffiti, gates; types in the street sweeps, W6 and W7" (the gates are walls look W8, behind `barrier_look`; hoardings and graffiti are W9; the key waits for F's phone look): not ticked
