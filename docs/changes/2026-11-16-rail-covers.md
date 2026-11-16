- Plac Zawiszy: the Al. Jerozolimskie arm over the railway is one solid slab again, with no open rail pit between narrow bridges. Żelazna by Al. Jerozolimskie is a flat street over the tunnel, with no fake bridge, ramps or sunken asphalt.

## Backlog
- fixed: F's playtest report, build 11 (2026-11-16): the open pit at Plac Zawiszy, and Żelazna x Al. Jerozolimskie with a floating deck, wing walls and a road that dropped under it
- found: the cause is generic (every OpenStreetMap bridge=yes way becomes its own deck, joined to its neighbours only under 6 m apart, whatever the ground under it); the sweep (`tools/rail_covers.py --sweep`) lists the road deck groups with 6-12 m gaps: 1, 5, 7, 8, 19, 21 are river and road bridges whose gaps look real, left as they are
- found: a street over a short rail tunnel needs a `COVERS` line in tools/rail_covers.py

