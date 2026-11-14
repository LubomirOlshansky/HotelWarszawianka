- Fences and hedges along the streets now break when you drive through them: the car loses a little speed, bits fly, and the panel stands again later, once you are far away and looking elsewhere.

## Backlog
- fixed: the sloppy driver's dead stops on fences and hedges (the city objects plan, step 7: the bake's S fences and hedges have no collider; `soft_things.gd` breaks them at a cost per panel, `--no-soft` puts the old colliders back, verify step `softthings`)
- found: the bake chain cannot reproduce main's map from scratch: (1) `bake_structures.py` `clear_carriageways` drops OSM `h`, `m` and `ft` on every wall, fence and hedge line; (2) `bake_osm.py` never calls `road_design.apply_all`; (3) even with both put right the structure solver drifts by about 25 fills, walls and asphalt fills (details in docs/changes/2026-11-14-barrier-types-stamped.md). Needs its own thread.

## Roadmap
- ticked (half): "Fences and hedges break when driven through (Smash class, in bulk); parked cars can be pushed, thinned in pinches": the fences and hedges part; the parked cars stay open
