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
- The last pass of `bake_osm.py` is `tools/object_types.py` (city objects plan step 5): each barrier
  line's type, class, hazard and height by setting are decided here, in the bake, never at run time;
  `tools/overlay_object_types.py` draws the type plot and the 20-sample check's contact sheets.

### 1b. A landmark from Blender (trial, 2026-11-13: the Palace only)

`tools/blender/pkin.py` builds the Palace in Blender from the same plan as `_build_palace` and
exports `game/models/pkin/pkin_lod0.glb` (and `_lod1`). Materials are named `M<code>_<rrggbb>`
after landmarks.gd's M_* codes; UV holds the wall coordinates, UV2.y the wall's top and UV2.x the
height of the terrace whose projectors light the face (`lamp_level`; it goes into the vertex alpha as
0.75 + metres / 1024 and building.gdshader's floodlight() fades the night light up from it).
`landmarks.gd` `_palace_glb` pours its triangles into the same city mesh as the code models, so
it costs no draw call and no shader. It is used only with `--palace=blender` (or `AW_PALACE=blender`
for `bake_city.gd`); the default stays the code model until F decides. Re-export after editing the
script: `Blender -b --factory-startup -P tools/blender/pkin.py -- --lod=0` (the glb import keeps
compression and auto-LODs off, so the codes in UV2 survive). No .blend is committed.

## 2. Loading (boot.gd, then main.gd `_ready`)

0. The boot scene (`boot.tscn`, the project's main scene; TD-15): `boot.gd` and the 8 scripts it
   needs load in about 22 ms. It starts the error trap (a debug
   build's; a release build has none). A player's launch (no flags: every
   release build) puts the title up in the first frames and loads `main.tscn`, which pulls in
   every other script (about 3.5 s in a release build on a cloud core), on a thread behind it.
   A run with flags (the checks, shots and bench) loads the game's scene at once, so its
   `--quit-after` and `--shots` frames mean what they did; `--boot` asks for the player's way.
   Then the game's scene takes the boot scene's place and `main.gd` takes over the title and
   the trap.
1. Flags (`_parse_args`), gamepad, settings, audio buses.
2. Title screen first (the boot scene's, or a new one in a run with flags), so the first frame
   isn't blank; the radio starts.
3. Wallet (the save), then the city: runtime build or prebuilt sectors (`sector_streamer.gd`).
4. Every system in a fixed order of `_build_*` calls, each followed by `LoadYield.tick` so the
   loading bar moves; then `traffic.setup`, `trams.setup`, `trains.setup`, walkers, rivals,
   crowds, city life, police.
5. Title dismissed: the camera fly-in, the HUD, the guide (`first10.gd`) on a fresh save.

The place scripts (first scene, the Patelnia, Tamka ...) are one step, `_build_places`, which builds the rows of `Places.TABLE` in order with a tick after each and then merges their dressing per sector; a new place is a table row, not a step. A new system adds its `_build_x` at the right place in this list. Anything that reads another
system must be built after it. Nothing new goes into step 0: every script `boot.gd` or `title.gd`
preloads is loaded before the title can show (`check_boot` holds the list).

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
- `user://session.log` and `session.prev.log` beside them are the error trap's (section 4), not
  the save's, and only a debug build writes them. They are the one kept file written in place: a
  log that grows line by line, starts again after 2,000 lines, and is never written by a release
  build, a test run or `--nosave`.

## 4. Testing

| Layer | What | Command |
| --- | --- | --- |
| Map data | invariants and counts | `python3 -I tools/check_map_data.py`, `check_roads.py`, `check_streets.py`, `road_truth.py` (lanes, turns, roundabouts) ... |
| Rules | pure scripts, no map | `game/tools/check_*.gd` (about 200), each prints `<name>: OK` |
| Headless runs | the game for N seconds with flags; `boot-run` starts it as a player's launch does (the title first, the game loaded behind it) | `tools/verify.sh` steps `plain`, `prebuilt`, `boot-run`, `police-runs` ... |
| All of it | one PASS / WARN / FAIL table | `tools/verify.sh [--quick]`; the steps and their sets are one list, `tools/ci_steps.txt`; CI picks its jobs from the changed paths (`tools/ci_tier.py`) and sums them up in one `gate` check; main runs every group |
| Looks | phone-size screenshots | `tools/shots.sh`, skill `screenshot-review` |
| Cost | frame, draw calls, scripts | `--bench`, `--probe`; the phone's BENCH card |
| Play | Autopilot (AI player) on the Mac | skill `autopilot-playtest`, bug log PT-n in docs/PLAYTEST.md |
| A debug run with no log to read (the phone, not plugged in) | the errors with counts, the last printed lines, whether the last session closed by itself | Settings → DŹWIĘK → RAPORT copies it (`error_trap.gd`, debug builds); `--report` prints it when a run ends |
| Testers' builds (release) | nothing: the release engine does not report a script's mistakes (tech-debt TD-21), so a quiet TestFlight proves nothing about the scripts | find them in the rows above |

Test flags (`--at=`, `--time=`, `--shots=`, `--kino-tour=go` ...) are parsed only in `main.gd` and
listed in the archive's flags table. Every run passes `--nosave` and quits.

## 5. Builds

- iOS: `tools/export_ios.sh` (splits the map, prebuilds sectors, exports `build/ios`), then Xcode.
  TestFlight builds use the release template, which reads no flags (`release.gd`).
- Android: `tools/export_android.sh` (signed Play AAB).
- Device runs (skill `device-run`) only when F says so for the current loop.
- Never overlap `export_ios.sh` and `xcodebuild`; turn Autopilot off before exports.

## 6. Reference photos

Photos of real buildings are modelling reference only: never committed, never shipped. Their home is the
shared store `/mnt/project-files/refs/<slug>/` (a network mount all cloud threads see; the Mac does not
mount it); the repo's gitignored `refs/<slug>/` is the working copy. `tools/refs_store.py` owns both:
`index` writes the store's `INDEX.md` and `INDEX.json` in the rank order of `docs/CITY_INVENTORY.md` Part 1
(slugs tied by `tools/refs_slugs.tsv`, folders that live elsewhere in the shared folder by the store's
`ALIASES.tsv`), `gaps` lists the places with no photo or no ortho (the Mac gather worklist), `show` and
`where` look a place up, `pull` and `push` sync the two copies (never deleting; a different size is a
conflict and the destination wins). Verify step `refs-store` runs its selftest.
