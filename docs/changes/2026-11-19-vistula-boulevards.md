- Bulwary nad Wisłą ożyły: schodki z ludźmi, patrol z psem i mandaty, bary, barki i Muzeum nad Wisłą. / The Vistula boulevards came alive: the steps full of people, a police patrol with a dog and tickets, bars, barges and the Museum by the river.
- On the steps, groups sit on picnic blankets with beer, speakers and backpacks, and the patrol's officer walks up to a real seated group to write the ticket.
- The terraces of Palomka and Zachodni Brzeżek, the barges (Nowa Falka, Zanurzenie, Wirek, Kalmar, BarKa) and the beach bars under Most Poniatowskiego have guests at their tables and barmen behind the counters, busiest on summer evenings.
- The MUZEUM letters now stand tall and lit on a steel frame over the pavilion's roof, and its line murals cover most of every wall.

## Backlog
- found: the real steps' rise and tread are in no source (0.41 m rise is a guess; needs a photo check on the Mac)
- found: footways crossing the band are walked on the ground under the steps, not on the treads
- found: the bike family's four morph shapes are all used (commuter, Rowerilo, cargo, parked), so the scooters needed their own small MultiMesh (+1 draw call); a fifth shape would need a fourth custom channel in the actor shader
- found: guest figures that stand still (the food queues) keep swinging their legs, as every pedestrian slot does
- found: the inventory pins Zachodni Brzeg on "the ground floor of The Tides", but no outline stands at that pin; the bar is dressed on the rowing club's glass block, the nearest real wall (a Mac look check settles the building)
- found: the OSM Marina Warszawa barge is 40 m, F's aerial photo shows an 80 m barge in front of the Pawilon: built as a new neighbour, NOWA FALKA (which inventory row it is wants F's eye)
- found: the barge and beach-bar pins are estimates good to 30 to 60 m, snapped to the river's bank; the Mac look check can move them
- found: the bars' seat plans (river.gd `bulwar_bar_plans`) repeat each builder's table layout from the map data, because the prebuilt city has no builder at run time; a change to a builder's layout must change its plan too (check_crowds counts the seats, not their positions)
- found: the steps' props (blankets, bottles, speakers, backpacks, pizza box) are one MultiMesh of unit boxes of its own (+1 draw call while the steps are on screen, +1 shader `steps_props.gdshader`)

## Roadmap
- ticked: "People and life on the Vistula boulevard steps"
- added: "Boulevards phase C (F, 2026-11-19)": ticked, the Pawilon Tańca with Palomka, the kiosk row, five bar barges, Zachodni Brzeżek and the Płyta Desantu beach bars are built (sites `pawilon_tanca`, `barka_nowa_falka`, `barka_zanurzenie`, `barka_wirek`, `barka_kalmar`, `barka_barkas`, `zachodni_brzezek`, `plyta_desantu`) and peopled (Phase D); the Mac look check for their pins is parked
