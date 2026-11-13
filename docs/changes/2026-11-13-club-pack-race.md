- The night club's drivers now race like the street racers: each has their own skill, they really overtake, take shortcuts, no longer drive through each other, and none of them is faster than your car.

## Backlog
- found: a club racer far from the player pays up to 170 s of the out-of-sight traffic delay on the 2.9 km club course in Busy traffic, about twice its clear-road time (`traffic.gd` `AWAY_*`, fitted on narrower streets); with nobody near, the eight still drive through 17 cars in Marszałkowska's queue (the old driver: 32)
- found: the race session's worst frame is one plan slice before the start (3.6 to 5 ms on the cloud machine, 19 ms seen once in a whole-game run, not traced): measure on the phone
- found: step 6b-2 (police chasers) and 6b-3 (crazy drivers) on the racers' driver
- fixed: "Step 6a ...; 6b: one race session ..." is done for the ladder, the first race, Trzy mosty and the pack race (6b-1); the pack race has a plan now (the ghost and `call_first` still have none)

## Roadmap
- noted: "Racer AI rebuild": 6b-1 done, 6b-2 and 6b-3 left
