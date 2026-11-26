- Zebra crossings are full width again: the stripes were about half as long as real ones on almost every crossing in the city.

## Backlog
- fixed: 2,021 of the map's 2,117 zebras drew 2.0 m bars since #474 (2026-11-07): `map_builder.gd` `_zebra_bar` read the bake's footway default width (2.2 m) as the crossing's width; now at least 3.6 m, road design's wider zebras unchanged
- found: the city generation audit and Fable's roads review (2026-11-26): tech-debt TD-31 heights owner, TD-32 places baked ahead, TD-33 road quick wins, TD-34 protected places for road fixes, TD-35 sites registry, TD-36 map_builder.gd split
