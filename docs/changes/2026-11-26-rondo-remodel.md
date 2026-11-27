- Rondo Dmowskiego looks like today's: open stairs that really go down into the underpass, with low railings and glass lifts instead of the old blue tubes, real flower beds on the island and the arm islands, and the new green square by the Empik pavilion, with the passage beside Hotel Metropol planted and lit.
- Marszałkowska at ul. Widok rebuilt: a clean taxi bay along the Rotunda that closes before the corner, one smooth kerb into Widok with a zebra and a cycle crossing across it, continuous lane lines and kerbs, and cars turning in from the kerb lane.

## Backlog
- fixed: Rondo Dmowskiego to trailer quality (island beds, paving bands, arm islands)
- fixed: Rondo Dmowskiego's underpass entrances (the twelve tubes are open stairwells; sunk 3.5 m with treads and a tunnel mouth, map_builder SUNKEN rondo_w*, site rondo_wells; the map's 1.9 m stone walls round them are gone; three lifts)
- fixed: grass on Rondo Dmowskiego's traffic islands (planted beds with a flower ribbon, as the real ones)
- fixed: the empty square next to the Empik pavilion rebuilt as the city plans it
- found: lamp masts by the rondo are blue (the real ones are grey); the neon-green boxes at the tram stops read as debug; a mirrored "WARS" sign on Wars's back face (Fable's critique, 2026-11-26)
- found: the city page "zielona-metamorfoza-placu-obok-ronda-dmowskiego" is blocked from the cloud; sizes are from the renders
- fixed: "Marszałkowska at ul. Widok, 10 out of 10" (road design area `widok`, docs/roads/widok.json): the taxi bay's 2.5 m kerb step, the boxed north corner, the 5 m gap in the tram-side kerb, 20 m without lane lines, Widok's lane starting on the carriageway's middle line (now from the kerb lane, round the return; only the right lane may turn, T arrows on the others), the taxi-bay footway's walkers on the road (36 m of footway in the junction -> 7 m, on the southbound side outside the design)
- found: footways whose walkers stand on the carriageway, a whole-map class: 9820 m on 397 footways (tools/check_foot_on_road.py, verify step `footroad`, ratcheted); the worst ones listed with `--list`
- found: the cycle crossing over Widok's mouth (OSM's) ends at the Rotunda's pavement with no cycle track on it (open end in the spec)
- found: the satellite (older imagery) shows the taxi strip running straight into the corner with hatching; the map follows OSM (bay closing before the corner): check on the Mac's GUGiK ortho

## Roadmap
- added (done): Rondo Dmowskiego for the teaser: open stairwells with lifts, the real beds, the square by the Empik pavilion
- ticked: "NEXT, 2026-11-26: Marszałkowska at ul. Widok to 10 out of 10" (day shots on the runtime city; the night shot and the prebuilt city wait for a bake_city run)
