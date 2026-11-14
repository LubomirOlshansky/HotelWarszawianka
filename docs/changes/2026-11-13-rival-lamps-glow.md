- The rivals' brake lights, indicators and headlight flashes are bigger now and throw a soft glow on the road, so you can see them from the normal camera.

## Backlog
- fixed: the Mac's look at racer AI step 6a (2026-11-13): at the normal camera (80 m view) a rival is about 10 px long and its lamps were 1 to 2 px, too small to read. The lamps are 1.3 times bigger and each has a glow pool of its colour on the road, in the lamp's own mesh, so a lit lamp is still one draw (`race_signals.gd`; `check_race_signals` holds one surface and a glow at least 2 m across)
- found: on the Mac, next to Słoik's result card the radio host's bubble cuts off mid-word ("...I've g")
- found: on the Mac, Pani Halina turned back on Rondo Dmowskiego 41.6 s into her race to the Palace and stood 19.4 s (`--race=3 --autopilot`, she still won in 73.6 s against a plan of 64 s); not traced
