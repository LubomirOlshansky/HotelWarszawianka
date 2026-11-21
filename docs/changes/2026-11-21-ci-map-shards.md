## Backlog
- fixed: main's `gate` red since #980 (the Jarmark market): the roads shard's `water` step stopped at the 900 s step limit and `drive` took 873 s. `water` now has a CI shard of its own, the map job's step limit is 1500 s and its timeout 90 min
- found: after #980 every runtime-city build is slower (landmarks 85 -> 137 s, the CI setup bake 9 -> 15 min, the smoke and landmarks shard 64 min of 75); the Jarmark market's build cost in the runtime city is the next thing to cut (defer or cache its props), so the limits can come back down
