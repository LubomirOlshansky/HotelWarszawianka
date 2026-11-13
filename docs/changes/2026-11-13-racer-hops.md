- Seba z Pragi and Mordor Mike now dart the wrong way down a short one-way street when it is empty, and only where your own car can do the same. Nobody else dares.

## Backlog
- fixed: Step 5b of the Racer AI rebuild, wrong-way hops on short one-way streets for Seba and Mike (docs/design/race-ai.md 5.5; F's yes on 2026-11-13): 52 one-block hops found (`tools/race_links.py`, kind `wrong` in `game/data/race_links.json`), each driven by the player's car in the prebuilt city (48 proven, 4 refused); known by `hops` (ladder.gd); the racer looks down the street first, holds it while it is on it and refuses it for the race when it is not empty (traffic.gd `_hop_look`, `RacePlanner.Plan.refuse`); bench marks "Wrong-way hops" (quick and full) and "Wrong-way hops in traffic" (full)
- fixed: the wrong-way hops half of "R3 part 2: wrong-way hops along one-way streets (needs oncoming-car checks on a cut), routes by time, the rival's shortcut shown after a loss" (routes by time came with step 3; the shortcut shown after a loss is step 6a's result card)
- fixed: "still open: wrong-way hops for Seba and Mike only" in F's defaults of the Racer AI rebuild (answered and built); "rivals defend but never ram" stays open
- found: a wrong-way hop is one block; a one-way street of several blocks is not hopped as a chain (most of the centre's longer one-way streets)
- found: the planner does not price the chance that a hop is refused; a refused hop costs Seba about 7 s over the road way from the start on the bench's hop course
- found: 4 hops the player's car could not prove (3 with no street into them or no way on in the drive, 1 touched something fixed on Berka Joselewicza)
- found: the race bench's hop course ends at Rondo ONZ, where rivals in Low traffic still drive through a car on the roundabout and are stopped dead on Aleja Jana Pawła II (No ghosting, Honest car: recorded fails, not the hop's)
- found: "Wrong-way hops in traffic" is recorded as passed on Linux only; `tools/race_bench.sh --write` on the Mac makes it a pass (waits for F's go, with the other Mac marks)

## Roadmap
- ticked: "Racer AI rebuild, step 5b: Seba and Mike take short one-way streets the wrong way when they are empty, each one driven first by the player's car (race-ai.md 5.5)"; the open line becomes "steps 6a-6b"
- ticked: the wrong-way hops of "R3 part 2: wrong-way hops, the rival's shortcut shown after a loss"; the open line becomes "R3 part 2: the rival's shortcut shown after a loss (step 6a)"
