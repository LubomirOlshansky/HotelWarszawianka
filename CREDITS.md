# Credits and data licences

Around Warsaw is a free fan project. Its code and its own sounds, music and art are all rights
reserved (`LICENSE`). The city in it is built from open data under the
licences below; the files in `game/map/` are baked from these sources by the scripts in
`tools/` (see README.md, "Map data", for every step), and they are not covered by that
notice.

## OpenStreetMap

Map data © OpenStreetMap contributors, available under the Open Database License (ODbL) 1.0:
<https://www.openstreetmap.org/copyright>.

Roads, lanes, building outlines and parts, trees, street lamps, water, parks, places and their
names come from OpenStreetMap (via the Overpass API). The baked files that hold this data
(`game/map/centrum.json`, and the parts of `ao.bin`, `lights.bin`, `water.bin` and `city.scn`
made from it) are derived databases and are offered under the same licence, ODbL 1.0.

## GUGiK (Główny Urząd Geodezji i Kartografii)

Źródło danych / data source: Główny Urząd Geodezji i Kartografii, <https://www.geoportal.gov.pl>.

- **3D buildings (LoD2, Warsaw, 2018)**, the **elevation model (NMT)** and the **aerial
  photographs (orthophoto)**: open data, free to use for any purpose under the Polish geodetic
  and cartographic law (Prawo geodezyjne i kartograficzne, art. 40a ust. 2 pkt 1). Baked into
  `game/map/lod2.bin`, `lod2.json`, `terrain.json` and the roof colours.
- **3D tree models (LoD1, 2023)**: licensed under Creative Commons Attribution 4.0
  (CC BY 4.0, <https://creativecommons.org/licenses/by/4.0/>). Changed for the game: reduced to
  each tree's position, height and crown size (`trees3d` in `game/map/centrum.json`), and one
  scanned record left out because it is the artificial palm on Rondo de Gaulle'a, which the game
  draws itself.

The game keeps the main screen clear of credits. The full list (this file's data licences, the
"© OpenStreetMap contributors" and GUGiK lines, the engine, the add-ons and every radio track with
its licence) is on its own page, Settings → DŹWIĘK → LICENCJE (also the end card's credits line)
(`game/scripts/credits.gd`; `game/tools/check_credits.gd` keeps it, the add-on folders and
`radio.json` in step with this file).

## Music

The radio's tracks, as in `game/data/radio.json` (each with its licence line there; update this
list when `tools/add_music.py` adds a song, README "Adding music"). A licence of `unknown` is
not cleared for a release.

| Station | Track | Artist | Licence |
| --- | --- | --- | --- |
| 87,3 KEBAB FM | Neon na Marszałkowskiej | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 87,3 KEBAB FM | Palma de Gaulle'a | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 87,3 KEBAB FM | 87,3 MHz | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 87,3 KEBAB FM | Wisła w różu | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 87,3 KEBAB FM | Sos czosnkowy | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 87,3 KEBAB FM | Sos czosnkowy (druga wersja) | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 86,6 RONDO FM | Rondo Dmowskiego 3 A.M. | Around Warsaw | own: synthesised by `tools/make_music.py` (all rights reserved) |
| 108,8 MORDOR FM | Open Space | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 108,8 MORDOR FM | Deadline | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 108,8 MORDOR FM | Deadline (druga wersja) | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 108,8 MORDOR FM | Winda na 30. piętro | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 108,8 MORDOR FM | Służewiec 3:00 | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 108,8 MORDOR FM | Fajrant | Around Warsaw | own: generated with ElevenLabs (Creator plan, commercial licence) |
| 86,0 PÓŁNOC FM | Sód | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Wiadukt | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Nocna przesiadka | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Szkło na Woli | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Bulwar, 23:40 | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Mgła nad Pałacem | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |
| 86,0 PÓŁNOC FM | Świt na Smolnej | Around Warsaw | own: synthesised by `tools/make_music.py --set=polnoc` (all rights reserved) |

## Godot add-ons

- **Debug Draw** by HardPixel, MIT licence, version 1.1.0 (the Godot Asset Store's download
  4913, files dated 2026-08-10), <https://store.godotengine.org/asset/hardpixel/debug-draw/>
  (source <https://github.com/hardalex/godot-debug-draw>). In `game/addons/debug_draw/` with its
  `LICENSE`, unchanged. GDScript and shaders only; the game loads it only for the testing flag
  `--debug-roads` (loop 3a).

## Music, sounds and art

The sound effects and the interface sounds are generated by the game's own scripts
(`tools/make_sfx.py`, `tools/make_ui_sounds.py`); the radio's music is listed under Music
above. The models,
signs, posters and jokes are original to this project; brands in the game are parodies. All of
these are all rights reserved, like the code. The interface uses the device's system font. The game is made
with Godot Engine (MIT, <https://godotengine.org/license>).

## Godot add-ons

Each add-on lives in `game/addons/<name>/` with its own licence file, unchanged.

- **Autopilot** by the Aura team (ramenvr), version 1.0.0, Apache License 2.0, fonts under the SIL
  Open Font License, <https://github.com/ramenvr/autopilot>. A development-only playtest plugin: it
  lets an AI player drive the game in the editor to find bugs; it is not part of any build.
- **Phantom Camera** by Marcus Skov (Ramokz), version 0.11.0.3, MIT licence
  (`game/addons/phantom_camera/LICENSE`), <https://store.godotengine.org/asset/ramokz/phantom-camera/>
  (source: <https://github.com/ramokz/phantom-camera>). It moves the camera in the cinematic
  moments (`game/scripts/camera_shots.gd`); installed without its examples folder.
- **beehave** by bitbrain (Kenneth Lorenz) and contributors, version 2.9.3 (2026-08-18, for
  Godot 4.7), MIT licence (`game/addons/beehave/LICENSE`), <https://github.com/bitbrain/beehave>
  (the release's source archive, `addons/beehave/` only). The police units' behaviour trees
  (loop 3g-1, `game/scripts/police/`); the editor plugin is off. One local change, marked in the
  file: `debug/debugger_messages.gd` sends no debugger messages when no debugger is attached.
- **Dialogue Manager** by Nathan Hoad and contributors, version 4.1.0 (2026-09-04, for Godot
  4.6+), MIT licence (`game/addons/dialogue_manager/LICENSE`),
  <https://github.com/nathanhoad/godot_dialogue_manager> (the release's source archive,
  `addons/dialogue_manager/` only, unchanged). It runs the pull-over conversation
  (`game/dialogue/police.dialogue`, loop 3g-1); the editor plugin is off and its C# files are
  unused.

## Website fonts (aroundwarsaw.app only, not in the game)

- Pixelify Sans, The Pixelify Sans Project Authors, SIL Open Font License 1.1,
  https://github.com/eifetx/Pixelify-Sans (Google Fonts v3; `site/public/fonts/`, licence beside it)
- Manrope, The Manrope Project Authors, SIL Open Font License 1.1,
  https://github.com/googlefonts/manrope (Google Fonts v23; `site/public/fonts/`, licence beside it)
