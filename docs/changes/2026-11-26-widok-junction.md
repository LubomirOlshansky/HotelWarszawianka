- Marszałkowska at ul. Widok rebuilt: a clean taxi bay along the Rotunda that closes before the corner, one smooth kerb into Widok with a zebra and a cycle crossing across it, continuous lane lines and kerbs, and cars turning in from the kerb lane.

## Backlog
- fixed: "Marszałkowska at ul. Widok, 10 out of 10" (road design area `widok`, docs/roads/widok.json): the taxi bay's 2.5 m kerb step, the boxed north corner, the 5 m gap in the tram-side kerb, 20 m without lane lines, Widok's lane starting on the carriageway's middle line (now from the kerb lane, round the return; only the right lane may turn, T arrows on the others), the taxi-bay footway's walkers on the road (36 m of footway in the junction -> 7 m, on the southbound side outside the design)
- found: footways whose walkers stand on the carriageway, a whole-map class: 9820 m on 397 footways (tools/check_foot_on_road.py, verify step `footroad`, ratcheted); the worst ones listed with `--list`
- found: the cycle crossing over Widok's mouth (OSM's) ends at the Rotunda's pavement with no cycle track on it (open end in the spec)
- found: the satellite (older imagery) shows the taxi strip running straight into the corner with hatching; the map follows OSM (bay closing before the corner): check on the Mac's GUGiK ortho

## Roadmap
- ticked: "NEXT, 2026-11-26: Marszałkowska at ul. Widok to 10 out of 10" (day shots on the runtime city; the night shot and the prebuilt city wait for a bake_city run)
