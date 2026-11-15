- On the phone, the ground in Patelnia's sunken square, on the stairs by the Rotunda, on Złote Tarasy's plaza and in the railway cutting west of Centralna is where it is drawn again, and people on the station's island platforms walk on the platforms.

## Backlog
- fixed: the prebuilt city's ground heights (`terrain_height`, `ground_height`) differed from the runtime city's in 685 of 240,464 samples every 10 m, up to 7.1 m in the railway cutting west of Centralna and up to 3 m on Patelnia's stairs, because map_builder made the sunken places, the rail cut, the rail yard and the decks over the cut in `_setup` only; the prebuilt map now makes the sunken places and the cut's decks again and keeps the cut and the yard in the index (`_rail_state`, +0.1 MB), so it opens no slower (1.6-1.8 s in the cloud, as before; sampling the cut again would have cost 0.6 s); 0 samples differ now
- fixed: the people on the four island platforms walked on the tracks' bed on the phone (footway_lift: 33 lifted paths now on both paths, 25 after #818, 0 before it)
- added: bake_city.gd opens the saved index as the game does and fails when its heights differ from the map it was saved from at any sample every 10 m; the prebuilt checks (stuck spots, the old town drive, the lane drive) open the prebuilt map as the game does (SectorStreamer.ready_prebuilt)

## Roadmap
- ticked: none (a phone-path fix)
