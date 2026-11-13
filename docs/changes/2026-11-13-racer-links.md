- Rivals know the city's back ways now: Pani Halina, Taksiarz Zbyszek and the others cut through yards, car parks and alleys where it saves them time, and only where your own car fits through too.

## Backlog
- fixed: "Step 5: race links (alleys, courtyards, car parks, wrong-way hops), each proven with the player's car" of the Racer AI rebuild, its yards, car parks and alleys (docs/design/race-ai.md 5.4): 52 links found in the map's service ways (`tools/race_links.py`, `game/data/race_links.json`), each driven by the player's car in the prebuilt city along the curve a rival takes (`tools/race_links.sh`): 37 proven, 15 refused; known per rival by `yards` and dared by `narrow` (ladder.gd); verify steps `racelinks` (quick) and `racelinks-drive` (smoke)
- found: Step 5b of the Racer AI rebuild: wrong-way hops on short one-way streets for Seba and Mike (question 3 in docs/QUESTIONS.md, default: 150 m at most, only where the player's car can); needs the driver to see the town's cars coming at it on the street it drives the wrong way
- found: 15 race links the player's car could not drive in its test (10 strayed over 2.5 m from the curve in a tight yard corner, 1 touched a wall, 4 with no street into them or no way on; `refused` in game/data/race_links.json); a smoother curve through the yard's corners, or a slower test driver, may prove some of them
- found: a race link is proven from one street into it and one way on; the other ways in and on differ only in the junction's curve
- found: the night club's pack race (street_meet.gd) has no race links (step 6b)
- found: a race difficulty option (F, 2026-11-13: "maybe later"): an easier / harder setting for the rivals' pace and passing in traffic, built on the skill profiles (ladder.gd), never a rubber band; after step 6a's tuning

## Roadmap
- ticked: "Racer AI rebuild, step 5: rivals take yards, car parks and alleys, each one driven first by the player's car in the built city (race-ai.md 5.4)"; the open line becomes "steps 5b-6b"
- added: "Race difficulty option (F, 2026-11-13, later): easier / harder rivals by skill, after step 6a"
