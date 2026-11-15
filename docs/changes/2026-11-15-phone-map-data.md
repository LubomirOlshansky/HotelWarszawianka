- On the phone, Tamka's red-and-white bollards and Powiśle's blue street name plates are back, and Pasaż Wiecha has all eleven of its white Y lamp masts again (eight were missing everywhere).

## Backlog
- fixed: the prebuilt city (the phone's path) left `map.data` empty, so every place script that read it built nothing there: Tamka's 4,140 bollards and 58 street plates (114,290 triangles on the runtime city, 3,630 on the prebuilt one), the Warsaw Spire's LED band and night lines (6,076 against 480; #813 fixed that one script), and the people on the University Library's roof garden walked on the ground (map_builder's footway_lift: 25 lifted paths now, 0 before)
- fixed: Pasaż Wiecha's Y masts read the map's lamps, a sector-only list neither streamed city keeps, so 8 of the 11 stood on no path the game plays (16,466 triangles now on both paths, 15,698 before)
- added: check_place_scripts builds every place again on the phone's map (`Fakes.PhoneMap`: only the prebuilt index, `data` as SectorStreamer.open hands it over) and fails when one builds other triangles or parts than on the whole map; places.gd reports an error when it is handed a map whose index is full and `data` empty (every prebuilt game run then fails)
- found: Tamka's street plates keep clear of the houses, but the houses are sector-only, so both streamed cities place one more plate (Zajęcza and Dynasy) against no house (check_place_scripts PHONE_SHORT, +192 triangles)
- found: the prebuilt city's heights differ from the runtime city's in 685 of 240,464 samples (every 10 m): the railway cutting west of Centralna (up to 7 m), Patelnia's sunken square and its stairs, the Rotunda stair, Złote Tarasy's plaza, because the sunken places, the rail cut and the rail yard are not saved in the prebuilt index (map_builder `_sunk`, `_cut`, `_yard`); the people on the four island platforms walk on the tracks' level on the phone too (next pull request)
- found: city_barriers.gd reads `map.data` only while a sector is built (its data is then the sector's file), so both paths match there; hud.gd, jobs.gd and rides.gd read the data main.gd hands them (the index on both paths)

## Roadmap
- ticked: none (a phone-path fix)
