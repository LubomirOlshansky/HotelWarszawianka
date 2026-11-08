# Street objects unslopped (F, 2026-11-07)

F: "rework the objects on the roads ... analyse objects, walls, look for the artifacts, consider our
experience how to make this better street by street, unslop the objects, add some details, and remove
or change the objects that are not in place or mean something else than what is on the map now".
Road layout is not touched (F dropped the road geometry rework for now).

Tools: `tools/object_audit.py` measures, `tools/object_fixes.py` applies (run by bake_osm.py after
road_smooth, also on a baked map in the cloud), verify step `objects` keeps it at zero.

## What the audit looks for

Every lamp, signal pole, bench, bin, bike rack, advertising column, shelter, parked car and every
fence, wall and hedge from OpenStreetMap, tested against the finished map:

| Rule | Artifact | Found | Verdict |
| --- | --- | --- | --- |
| P1 | inside a building at least 1.5 m high (pokes out of the wall) | 138 (64 parked cars, 42 bike racks, 18 bins, 13 lamps) | REMOVE |
| P2 | a pavement object in a carriageway; a lamp or signal pole only on the asphalt as drawn (check_streets S1's test: the nominal OSM width is wider than the drawn road, 60 poles there are fine) | 22 bins | MOVE to the pavement (13), else REMOVE (9) |
| P3 | on the middle of a zebra | 0 | REMOVE |
| P4 | on the tram rails (under 1.2 m from a track; centre poles stay) | 4 lamps | REMOVE |
| P5 | in the river | 2 lamps | REMOVE (the bridge has the bake's own deck lamps) |
| P6 | under a bridge or viaduct deck: drawn on the ground in the slab's shade | 23 (13 signals) | REMOVE |
| P7 | the same object twice within 0.5-2 m | 14 (lamps and signal pairs) | REMOVE the second |
| P8 | a bench, bin or rack on a flight of steps | 10 | CHECK (amphitheatre seats are real) |
| P9 | a signal pole over 30 m from any junction or crossing | 14 | CHECK |
| P10 | a "bus shelter" away from any road a bus or tram uses: OSM's amenity=shelter in a park, a yard or a car park; drawn as a bus stop it also became a stop for the ring buses | 17 | REPLACE with a bench |
| P11 | a parked car on a zebra, a lane or another car | 0 | REMOVE |
| L1 | a barrier mostly inside a building | 160 (90 hedges) | TRIM the parts inside walls, keep the rest |
| L2 | a barrier stub under 1.5 m touching nothing | 127 | REMOVE |
| L3 | a barrier on top of another (two OSM ways for one fence) | 58 | REMOVE the shorter |
| L4 | a fence or wall across a footway or a zebra (OSM's gates are nodes the bake never read) | 153 | GATE: cut as wide as the path |
| L5 | the wall or fence that frames a flight of steps (underpass, metro, park stairs), drawn as the 1.6-1.9 m grey slab | 192 | RESTYLE as the 1 m `balustrade_rail` (street_pass B5, now city-wide) |

Barriers with a street-pass override (game/data/road_objects.json) are never touched.
After the fix: 750 findings → 24, all CHECK (P8 10, P9 14).

## Street by street (before → after)

The table counts the first rule set (poles judged on the OSM width; 60 of them were off the drawn asphalt and now stay). Findings within 30 m of a named street (`python3 -I tools/object_audit.py --by-street`). 433 more are
off the streets (yards, parks, courtyards). After the fix every street below is at 0 except the
CHECK rules.

| Street | Before | What |
| --- | --- | --- |
| Aleje Jerozolimskie | 33 | 14 stair slabs → balustrades, 10 lamps/bins out of the carriageway, 4 stubs |
| Aleja Jana Pawła II | 29 | 10 signals under the deck, 7 stair slabs, 4 in buildings (its 4 "in the road" poles are off the drawn asphalt and stay) |
| Lubelska | 18 | bins standing in the road (the lamps there are off the drawn asphalt and stay) |
| Aleja „Solidarności” | 17 | 8 fences across footways, 6 stair slabs |
| Piotra Antoniego Steinkellera | 13 | 7 barriers inside buildings, 3 doubles |
| Prosta | 12 | 4 lamps on the tram rails, 2 in the road, stairs, gates |
| Grodzka | 12 | 6 stair slabs, 4 doubled walls |
| Marszałkowska | 11 | 4 stair slabs, 2 lamps in buildings, 2 in the road, a double (the street pass overrides stay) |
| Aleja Armii Ludowej | 11 | 5 objects under the deck, 4 stair slabs |
| Wybrzeże Gdańskie | 11 | 10 stair slabs |
| Most Łazienkowski | 11 | 11 stair slabs |
| Solec | 10 | 5 fences across footways |
| Podwale, Andersa, Most Poniatowskiego, Brzozowa | 9 each | stair slabs, gates |
| Francuska | 7 | 7 fence stubs |

## Before/after shots

Project files `street-objects/` (cloud, day, `--quality=low`, runtime path):
A bus shelter in a car park (gone, a bench instead); B Lubelska's crossing (the shot is of the first rule set, which also moved the poles; poles now stay unless on the drawn asphalt); C the
underpass stair walls by Most Świętokrzyski become open balustrades and the park fence gets its gate;
D the stair walls by the Emilii Plater cycle paths; F a lamp off Jerozolimskie's asphalt; G, H
signals and bins under decks and inside the station.

## Left for a person (CHECK)

- P9 lone signals, checked on Mapillary's detections (2026-11-08): all 14 are real, each has
  detected traffic lights within 1-7 m. Wybrzeże Szczecińskie (976, -71) ×3, Aleja Waszyngtona
  (2000, -490) ×4, Wioślarska (1160, -698) ×4 and Targowa (1093, -1826) also show stop lines and
  zebras there that the map lacks; Plac Piłsudskiego (-824, -879) ×2 are pedestrian lights. KEEP;
  the missing crossings go to the roads backlog.
- P8 benches on steps: (-7, -1021) ×2 and (129, 1506) ×2 are amphitheatre steps (real); (-434, -722),
  (386, -1849), bins at (-651, -1165), (-1451, 742), (-842, -1521), a rack at (-2293, -2741).

## Next

- Details: a bench under each P10 park roof is the first; next the real picnic roof and smoking
  shelter models, bollards at the gates cut into fences, and the CHECK list against Mapillary.
- Stairs: the balustrade style is one look for every stair; metro entrances want the granite
  `balustrade` and the yellow Metro sign (the stairs thread maps them).
