- The Warsaw Spire's GeoBent LED sign and its night lines of light now show on the phone's city too (they were missing there).

## Backlog
- fixed: the Spire's lights mesh (LED band, night lines) was empty on the prebuilt city path: it read the tower's outline from `map.data`, which the prebuilt city leaves empty (480 triangles of jets only instead of 6076)
- found: other place scripts reading `map.data` may be empty on the prebuilt path too (first_scene.gd reads `map.data.get("lamps")`, city_barriers.gd reads steps, islands, paths): worth a sweep

## Roadmap
- ticked: none (fix to the merged Spire day/night pass)
