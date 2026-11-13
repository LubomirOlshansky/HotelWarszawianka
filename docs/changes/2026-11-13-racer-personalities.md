- Rivals in a street race have lights that show what they do: brake lights, indicators, a flash of the headlights behind a slow car, hazard lights after a wrong turn. Each has its own habits: Pani Halina indicates early and never flashes, Seba never indicates and flashes at once.
- After a street race the result card shows both routes on a small map, yours and the rival's, and says what decided it: the route, the standing in traffic or the pace.
- Careful rivals wait for a longer gap before they overtake on the oncoming side, and every rival knows all the shortcuts of its own district.

## Backlog
- fixed: "Step 6a: personalities, visible decisions, the result card with both routes" of the Racer AI rebuild (docs/design/race-ai.md 6.1): four traits more per rival in `ladder.gd` (`dare`, `indicate`, `flash`, `home`), the lights in `race_signals.gd`, the result card's report in `race_report.gd` with a picture on the card (`hud.gd` `set_card_art`); checks `check_race_signals` and `check_race_report` (verify steps `racesignals`, `racereport`, CI's quick group), the nerve test in `check_race_planner`, bench marks "Ladder curve" and "Told apart". The open line becomes "Step 6b: one race session for the pack race, Trzy mosty, police chasers and crazy drivers"
- fixed: "Słoik's wrong turn ... make it a moment the player sees" (step 6a): after a wrong turn the rival lifts off for 0.9 s and its hazard lights blink for 2.4 s, and the result card counts the wrong turns
- fixed: ROADMAP "R3 part 2": "the rival's shortcut shown after a loss" (the result card's picture and its line of what the rival did; the wrong-way hops came with step 5b)
- fixed: the metres to the finish could lead through a shortcut that joins a street the rival had found blocked (`RaceCuts.links`; the time plan never took it, the distance shown and the bench's turn-back test did: 720 m short in Pani Halina's blocked race). The links leave out an exit onto a shut street
- found: a race difficulty option (F, 2026-11-13: "would be fine to add a difficulty option later"): easier or harder by the rivals' skill profiles (`ladder.gd`), never by a rival that waits for the player; after step 6a, with tech-debt TD-12 (the difficulty layer)
- found: the pack race, Trzy mosty's field and the police have no lights and no result report (step 6b)
- found: no street race is in Praga yet, so Seba's home district never shows (step 6b or a new race)
- found: Słoik and Pani Halina tie on the bench's short course from Marszałkowska (59.6 s each on clear roads): his wrong turn costs what his pace wins there. The Skill ladder mark allows it (1 % slack)
- found: Independence in traffic still fails: 37 % for the worst pair over its draws and 63 % in one race (Pani Halina's first race from Leszczyńska in Busy traffic behind a player who never moves); 31 and 47 % on main's run. Probably her home shortcuts changed which streets she queues in (not traced); the fix is still the delay by street and light (step 4b's found line)
- found: Route sense passes on the full matrix for the first time (2 of 2 free choices within 5 %): recorded once:Linux, held only after the Mac's `--write` (waits for F's typed go)
- found: nerve (`dare`) moves little on the bench: 4 of Pani Halina's 158 races in traffic change with it, and Słoik's 1.5 and Zbyszek's 1.3 changed none in these draws; it is held by the direct test in `check_race_planner`

## Roadmap
- ticked: "Racer AI rebuild, step 6a: personalities and the result card (2026-11-13)": every rival has its own nerve, lights and home district, and the result card shows both routes and what decided the race (race-ai.md 6.1); the open line becomes "step 6b"
- ticked: "R3 part 2: wrong-way hops, the rival's shortcut shown after a loss"
