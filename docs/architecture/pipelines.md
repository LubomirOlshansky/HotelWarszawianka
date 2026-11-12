# Pipelines: from data to the phone

Five flows every change passes through. Each section names the commands and the one rule that
breaks things most often.

## 1. Map data (offline, Python)

```
data/raw/ (OSM extract, GUGiK LoD2 sheets, terrain, orthophoto; gitignored)
   │ tools/bake_all.sh → bake_osm.py, bake_gugik.py, bake_terrain.py, bake_structures.py,
   │                     bake_ao.py, bake_lights.py, bake_water.py, fixes (road_fixes, object_fixes ...)
   ▼
game/map/centrum.json, ao.bin, lights.bin, water.bin   (committed: the ODbL database)
game/map/lod2.*, terrain.json                          (derived; the "map pack" release asset)
   │ tools/bake_sectors.py
   ▼
game/map/index.json + sectors/<i>_<j>.json             (derived, gitignored)
   │ godot --script res://tools/bake_city.gd (with a renderer, never --headless)
   ▼
sectors/s_<i>_<j>.scn, proxies.scn, index.res, shared/*.res   (the prebuilt city)
```

- A fresh clone runs `tools/setup_map.sh` once (`--full` with the GUGiK raw data).
- After any re-bake: the whole chain, then `python3 -I tools/check_map_data.py`. New counts only on
  purpose, recorded in that script and the archive's "Map data" together.
- Skill `bake-map` before editing any bake. Roads have their own system (skill `road-design`).

## 2. Loading (main.gd `_ready`)

1. Flags (`_parse_args`), gamepad, settings, audio buses.
2. Title screen first, so the first frame isn't blank; the radio starts.
3. Wallet (the save), then the city: runtime build or prebuilt sectors (`sector_streamer.gd`).
4. Every system in a fixed order of `_build_*` calls, each followed by `LoadYield.tick` so the
   loading bar moves; then `traffic.setup`, `trams.setup`, `trains.setup`, walkers, rivals,
   crowds, city life, police.
5. Title dismissed: the camera fly-in, the HUD, the guide (`first10.gd`) on a fresh save.

A new system adds its `_build_x` at the right place in this list. Anything that reads another
system must be built after it.

## 3. The save

- `user://save.cfg` (ConfigFile), owned by `wallet.gd`. `VERSION` 2; `migrate` upgrades older
  files in memory; unknown sections are kept as they were, so an older build doesn't destroy a
  newer save. `[session]` keeps the car's last spot for KONTYNUUJ.
- `user://settings.cfg`, owned by `settings.gd`, separate so a new game keeps the settings.
- `main.gd` `_notification` remembers the spot when the app goes to the background, and
  `_remember_frame` about every 5 s of driving; each of these rewrites the whole file.
- **Every write is safe** (`safe_file.gd`, TD-8): a temp file, read back, then one rename over the
  old file, for the save and the settings. A file the game writes starts with `[save] sealed=true`
  and ends with `[end] ok=true`.
- **A damaged file is never written over.** Half a ConfigFile loads without an error, so
  `wallet.gd` `damage` decides: empty, not text, not a save, `[save]` without `[wallet]`, or sealed
  without its end. The file is moved aside as `save.bad-<unix time>.cfg` (the last 3 are kept),
  the last launch's copy `save.bak.cfg` is loaded and written back, and main.gd tells the player
  (`_save_note`). No good copy: a fresh start. A missing `save.cfg` is a fresh start too, copy or
  no copy, so deleting it still resets the game.
- Tests: `check_save.gd`. Runs pass `--nosave` so a test never writes your save.

## 4. Testing

| Layer | What | Command |
| --- | --- | --- |
| Map data | invariants and counts | `python3 -I tools/check_map_data.py`, `check_roads.py`, `check_streets.py` ... |
| Rules | pure scripts, no map | `game/tools/check_*.gd` (about 200), each prints `<name>: OK` |
| Headless runs | the game for N seconds with flags | `tools/verify.sh` steps `plain`, `prebuilt`, `police-runs` ... |
| All of it | one PASS / WARN / FAIL table | `tools/verify.sh [--quick]`; CI runs quick + map jobs |
| Looks | phone-size screenshots | `tools/shots.sh`, skill `screenshot-review` |
| Cost | frame, draw calls, scripts | `--bench`, `--probe`; the phone's BENCH card |
| Play | Autopilot (AI player) on the Mac | skill `autopilot-playtest`, bug log PT-n in docs/PLAYTEST.md |

Test flags (`--at=`, `--time=`, `--shots=`, `--kino-tour=go` ...) are parsed only in `main.gd` and
listed in the archive's flags table. Every run passes `--nosave` and quits.

## 5. Builds

- iOS: `tools/export_ios.sh` (splits the map, prebuilds sectors, exports `build/ios`), then Xcode.
  TestFlight builds use the release template, which reads no flags (`release.gd`).
- Android: `tools/export_android.sh` (signed Play AAB).
- Device runs (skill `device-run`) only when F says so for the current loop.
- Never overlap `export_ios.sh` and `xcodebuild`; turn Autopilot off before exports.
