- Fences and hedges along the streets no longer stop the car dead: drive through one and it costs a little speed, with a crunch and flying bits.

## Backlog
- fixed: the sloppy driver's dead stops on fences and hedges (the city objects plan, step 7: the bake's S fences and hedges have no collider; `soft_things.gd` breaks them at a cost per panel, `--no-soft` puts the old colliders back, verify step `softthings`)
- found: the bake chain cannot reproduce main's map from scratch: (1) `bake_structures.py` `clear_carriageways` drops OSM `h`, `m` and `ft` on every wall, fence and hedge line; (2) `bake_osm.py` never calls `road_design.apply_all`; (3) even with both put right the structure solver drifts by about 25 fills, walls and asphalt fills (details in docs/changes/2026-11-14-barrier-types-stamped.md). Needs its own thread.
- found: a broken fence or hedge still stands drawn (the car passes through the panel; only the debris shows it went): the falling panels are "Fences and hedges as see-through instanced panels that fall when broken" (W3 to W5)
- found: two soft railings the car cannot get back out of (`check_lane_drive.gd --wander`): the tram stop's railing on Jerozolimskie by Centrum (-1329,638; the tram island between the platforms and the hard tram railings) and the Vistula boulevard's railing at Powiśle (95,-1134; the promenade a level down); left soft (an Open Question of step 7)
- found: 12 landmark sites are closed to the car at bumper height only by a fence or hedge that now breaks (`check_landmarks`' car rays; Grób Nieznanego Żołnierza from the Saxon Garden, Westynka, Pałac Krasińskich, Kościół Świętej Trójcy and 8 more): their own models leave a way in (an arcade, a gate, a garden)
- found: `map_builder.gd` `build_sector` depends on the order the sectors are built in (sector 0,-1 has 233,655 vertices built after its neighbours in index order, 239,556 built with only three others first); the same on main

## Roadmap
- ticked (half): "Fences and hedges break when driven through (Smash class, in bulk); parked cars can be pushed, thinned in pinches": the fences and hedges part; the parked cars stay open
