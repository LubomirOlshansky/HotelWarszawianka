## Backlog
- found: the barrier types (`tools/object_types.py`, city objects plan step 5) are in the committed centrum.json only after the next full re-bake on the Mac; this change was run and checked in the cloud on map evidence alone, because Overpass is blocked there
- found: most context rules are unproven by the 20-sample check (fewer than five judged lines per rule: villa, housing, office, works and garages, school, pitch, stairs); judge them on the Mac orthophoto or in a further photo round
- found: the palette (`game/data/object_palette.json` "types") has no rows yet for the new type ids (rail_tram, rail_street, guard_rail, deck_railing, rail_waterfront, basin_rim, low_lawn and others); add them in W2 before the game reads `ty`
- found: 8.4 km of fences are hard by a hazard (the plan expected 4 to 5 km): drop 3.3 km (retaining walls 1.7, terrain 0.9, fills 0.7), deck 2.0, railway 2.0, water 1.1
