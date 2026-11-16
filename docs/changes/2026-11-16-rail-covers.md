- Plac Zawiszy no longer has an open rail pit with tracks running between two narrow bridges: the Towarowa arm is one solid slab over the line, with the cutting ending in a wall and a tunnel mouth each side. Żelazna by Aleje Jerozolimskie is a flat street beside the cutting's wall again, with no fake bridge, ramps or dark underpass.

## Backlog
- fixed: F's playtest report, build 11 (2026-11-16): the hole at Plac Zawiszy, and Żelazna x Al. Jerozolimskie with a floating deck, wing walls and a road that dropped under it
- found: the cause is generic (every OpenStreetMap bridge=yes way becomes a deck, whatever the ground under it is); the sweep over all 28 road deck groups found only these two; group 27 (-1716, 733, two 8 m spans over the Śródmieście WKD trench) and 17/18 (Praga, 3 m air) are small real spans and were left
- found: a road in the real cutting's tunnel stretch under a junction needs a `COVERS` entry in tools/rail_covers.py; a rail tunnel the bake cannot see is still only known to trains.gd TUNNELS and PORTALS

## Roadmap
- ticked: "Rail cutting and bridges true to life" (Plac Zawiszy tunnel stretch, Żelazna deck)
