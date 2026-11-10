> **Development notes**, moved here from `README.md` on 2026-10-30 and otherwise unchanged: how every part of the game works, loop by loop. Where other docs, scripts and comments say "README", they mean this file; paths in it are from the repo root.

# Around Warsaw (prototype; Nocna Warszawa until 2026-10-30)

Arcade driving and flying through the real Warsaw, isometric pixel art, built in Godot 4.7.2
from OpenStreetMap and GUGiK open data. This prototype has real road shapes (mapped
carriageways, kerbs, stop lines, turn arrows, bus and cycle lanes, raised bridge decks), day, dusk and night (lit windows,
street-lamp pools, neon shop signs, headlights, the Palace of Culture floodlit), a vaporwave
title screen, grade and VHS overlay, a car radio, one car, a rescue helicopter and rescue
missions, AI traffic with working traffic lights, trams, pedestrians, rival drivers to race,
side jobs (3 a.m. kebab delivery, the Sunday słoiki run), a wallet that is saved, a city that
talks back, five easter eggs and Warsaw's landmarks built by hand in code (the Palace of
Culture, Złote Tarasy, the Rotunda, Varso Tower, Stadion Narodowy, Warszawa Centralna, the
towers of Most Poniatowskiego; tap one for its card): about 3.5 × 1.8 km from Śródmieście to
the National Stadium.

v0.9 adds sound (engine, tyres, rotor, collisions, the city by day and night, trams' bells,
horns, rain: all synthesised here), rain with wet streets and reflections, a river that flows
and mirrors its bridges, a Live time of day with the real sun over Warsaw, a performance
overlay and a quality setting for the device pass (see Water, weather and sound).

Loop 1 (polish) makes the occlusion ghost a light, thin dither that shows the street at
its own brightness, calms the river (deeper, slower, few glints; dark at night with the
lamps' reflections carrying it), puts the Palm where the laser scan found it, stops
Varso 2's top from floating, sets the Palace of Culture's clock to the time in Warsaw,
makes the roadworks read (red-and-white barriers, bigger cones, blinking amber lamps) and
puts joke posters on one advertising column in six (see Loop 1 below the water section).

Loop 2a (after the first play on an iPhone: "steering feels strange") fixes the steering, which
circled when the stick was held (the follow camera turned with the car, so the direction a held
stick meant kept turning too), adds three control schemes (Point, Classic, Fixed camera), a
settings panel behind a gear in the top left corner (controls, traffic, quality, sound, the
performance overlay; saved), a little less traffic by default with a Traffic setting, and a
closer default view (see Loop 2a: controls and settings).

Loop 2b (the iPhone showed 13–16 fps) takes the frame from ~6,800 draw calls to ~125–250: the
minimap drew every street of the map as its own polyline under a clip, every frame (6,500 draw
calls), and the sun's shadow covered a slab 2 km deep because Godot ignores the shadow distance
for an orthographic camera. It also adds a 60 fps cap with a 30 fps battery saver, a TEST ·
BENCH button with a result card to copy, real Medium and Low steps, a fix for the parked car
being "pinned" while the player flies, and the performance budgets for the next rounds (see
Loop 2b: frame rate on the iPhone, and Performance budgets).

Loop 10a (the user drove onto the Vistula, and across it at 91 km/h) makes the water
off-limits: a new whole-map check found 807 m of the water's edge open in 45 places (under
all four bridges, round all the fountains) and a helicopter that landed on the river and left
the car there; now a low granite edge runs round the river, the ponds and the fountains, the
helicopter won't land on the water, and a car that still gets in splashes, settles and is
towed back to a lane on dry land a second later with a line from the tow crew (see Loop 10a:
the river is off-limits).

Loop 2e (the HUD was sized for a 720-line window: ~24 pt buttons and ~8 pt text on the phone,
and a crowded top row) sizes the whole HUD in points (every control at least 44 pt, text 11 pt
and up, inside the safe area), thins the first screen to the gear, the speed, RADIO and
HELI / AUTO (plus a WEZWANIE button when a rescue call comes in; no call card and no
"prototype" label at the start), moves time of day, rain, VHS, the picture style and the camera
into a tabbed Settings panel, lays out every passing panel so none covers another (the kebab
bubble no longer hides under the radio ticker), puts every surface on one dark card recipe with
Polish above English, and adds `check_hud.gd` (see Loop 2e: the HUD at phone size).

The first-minute look (after the art review: in the first minute the eye found lime grass,
coral cycle lanes and an azure river before the player's car, which at night was darker than
the road) lights the red car from within at night and keeps red for it alone in traffic, calms
the day (no saturation boost by day, quieter grass, brick-red cycle lanes, a grey-green-blue
river with fewer glints), lets nothing glow inside the occlusion ghost, turns the lamp pools
into banded pixel light under the lit windows' brightness, gives half the LoD2 walls back their
windows (a sign test drew them as blank roofs) and makes the trees lumpier with rust and olive
autumn colours (see The first-minute look).

The camera loop (the user: "the follow camera is not working"; their phone had Classic with the
following switched off by CAM, so that part was the setting) rebuilds the follow camera on
measured laws (`follow_camera.gd`): it never turns faster than 64°/s (Classic turned at up to
108°/s, the helicopter's camera at 135°/s, and a Classic game began with a ~155° swing at
182°/s), eases in and out with no overshoot, still waits while Point's finger is down, starts
behind the car, looks further ahead at speed, no longer slides back when you brake (8 m before)
and ignores tiny wiggles. With Phantom Camera (Ramokz, MIT, the first add-on) it adds a fly-in
from over the city when the title screen goes and a short look at a new rescue or delivery
target and back, both skipped by any touch (see Camera loop: the follow camera).

Loop 2c (the user asked for nicer car models) rebuilds every vehicle from shaped pieces instead
of boxes (`models.gd`): a body lofted from its side profile with a sloped bonnet, a glasshouse
narrower at the roof with side windows and pillars, wheels in dark arches with hub caps,
bumpers, plates and lamps. The player's red hatch is the one retro hot hatch in town (white
stripes over the nose, bonnet, roof and tailgate, round lamps, a roof spoiler); traffic shows
hatches, saloons, estates, SUVs, a city taxi in an invented livery, Podwózka's app taxi with a
phone on the roof, panel and box vans and the bus, with no red or orange paint; the police
estate and the city guards' car are built for loop 3g; the rivals, the trams and the parked
cars get the new shapes too. Still one MultiMesh per kind: each draws several shapes, picked
per car in the vertex shader, and draws only the cars in use, so the frame costs the same draw
calls and fewer triangles at the default view (see Loop 2c: car models).

Loop 3g-1 (the police, part one, after docs/design/police.md and the user's choice of the
gentler police) puts patrol cars in the traffic and three speed traps ("suszarki") on the day's
roads, with an officer who waves the lizak at a speeder. A slip is a joke over a megaphone; two
in 45 s, a ram or an ignored lizak start a chase (koguty 1 to 3, with a blocker and a roadblock)
that always ends by itself ("Koniec zmiany!" at 30 / 40 / 45 s), or when you lose them (+15
respect), or when you stop and get a funny talking-to ending in a caution in the joke notebook.
Never a fine: nothing ever touches the złoty. Two new add-ons run it, beehave and Dialogue
Manager (see Loop 3g-1: the police, part one).

## Run it on your iPhone

1. `tools/export_ios.sh` (only needed after changing the game).
2. Open `build/ios/NocnaWarszawa.xcodeproj` in Xcode.
3. Pick your iPhone as the run destination, check Signing & Capabilities
   (team S6PVT5UP7G, automatic signing), press Run.
   The iPhone needs Developer Mode on (Settings → Privacy & Security).
4. For frame-rate numbers, stop it in Xcode and start the game from the iPhone's home screen:
   under Xcode's Run the debugger is attached, and Xcode's Metal API validation (on by default;
   `tools/export_ios.sh` now switches it and GPU frame capture off in the scheme) makes every
   draw call several times slower. Then Settings (the gear) → TEST, or the TEST · BENCH button
   on the performance overlay, and paste the card's text (KOPIUJ · COPY) into the chat.

## Android (Google Play)

```zsh
tools/export_android.sh              # split the map, prebuild the sectors, then the signed AAB
tools/export_android.sh --skip-city  # the AAB only (the tracked prebuilt sectors as they are)
tools/export_android.sh --apk        # a debug APK for `adb install` on a test phone
```

It writes `build/android/nocnawarszawa-<version name>-<version code>.aab` (0.1 and 2 now; ~68 MB:
the arm64 engine library ~71 MB uncompressed and the game's files ~45 MB, the same files as the
iOS `.pck`) and prints its size, package and version. The version lives in the **Android** preset
in `game/export_presets.cfg` (`version/name`, `version/code`): raise the code for every upload,
Play refuses a code it has seen. The city step is the same as `tools/export_ios.sh`'s and
rewrites the tracked `game/map/sectors/*.scn`, `index.res` and `proxies.scn` with a few bytes of
noise each; use `--skip-city` when the map hasn't changed.

The preset: package `com.olshanskysoft.nocnawarszawa`, Gradle build, AAB, arm64-v8a only, min
SDK 24, target SDK 36, sensor landscape (from the project's orientation; Godot writes
`userLandscape`, which follows the phone's rotation lock), the VIBRATE permission only (the
haptics; no INTERNET: the game makes no network calls), app backup off, the project icon
(`game/icon.svg`) as the launcher icon.

**Vulkan is required** (the user's choice, 2026-10-29): the Mobile renderer needs Vulkan, and
`rendering/rendering_device/fallback_to_opengl3` stays off, so Google Play must not offer the
game to phones with only OpenGL ES. Godot writes `android.hardware.vulkan.level` (1) and
`android.hardware.vulkan.version` (0x401000, Vulkan 1.1.0 in Godot 4.7) as *not required*; the
project's own editor plugin `game/addons/nw_android_export` (on in `project.godot`, editor only,
excluded from both exports) writes a build-variant manifest
(`android/build/src/standardRelease/` or `standardDebug/`) on every Android export that marks
both required, and Gradle's manifest merger ranks it above Godot's. It is tracked code, so a
fresh `--install-android-build-template` keeps the rule. `tools/export_android.sh` refuses an AAB
whose merged manifest doesn't have both required at the Vulkan version Godot asks for (after a
Godot upgrade that raises it, change `VERSION` in the plugin). **Expect Play Console's device
catalogue to list fewer supported devices** than before: the OpenGL-only phones (mostly old or
very cheap ones, and some with Vulkan 1.0 only) drop out. That is the point, not a fault.

**A fresh clone** (loop 3d-1: the map's derived files aren't in git) builds with the same
command: the script imports the project when Godot never has, makes `lod2.*` and
`terrain.json` when missing (`tools/setup_map.sh --full`, which needs GUGiK's raw data; or copy
the three files from a checkout that has them), then splits the map and prebuilds the sectors.
Checked 2026-10-30: `nocnawarszawa-0.1-2.aab`, 150 MB, upload-key SHA-256 fingerprint
`29:45:ED:ED:…:87:BF:59:9E`, `jarsigner -verify` "jar verified". Play needs a new
`version/code` (Android preset) for every upload: raise it before the next export once code 2
is on Play. A CI build isn't possible today: the map's GUGiK files need the raw downloads, and
the upload key must stay off GitHub (it would have to be a repository secret).

**The upload key** is `~/.android-keys/nocnawarszawa-upload.jks` (alias `upload`, RSA 2048,
10,000 days), outside every repo. Its password is only in the macOS login keychain (service
`nocnawarszawa-android-upload`, account `upload`; Keychain Access shows it). The script reads it
into `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD`, which Godot reads at export:
no key, user or password is ever in `export_presets.cfg`. Play App Signing holds the key that
signs what users install; this one only proves an upload is yours. **Back it up**: copy the
`.jks` and its password (from Keychain Access) to a password manager or an encrypted disk.
If it is lost, Play can reset the upload key (Play Console → Test and release → App integrity),
but that takes a support request and a few days.

**One-time setup on a new Mac** (already done on this one):
1. Godot 4.7.2's official export templates (github.com/godotengine/godot/releases, tag
   `4.7.2-stable`, `Godot_v4.7.2-stable_export_templates.tpz`, ~1.3 GB, checked against the
   release's `SHA512-SUMS.txt`): only `android_debug.apk`, `android_release.apk` and
   `android_source.zip` are needed, in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
2. The Android SDK (platform android-36, build-tools, platform-tools; no NDK or cmdline-tools
   needed) and a JDK 17 or 21, set in Godot's editor settings as `export/android/android_sdk_path`
   and `export/android/java_sdk_path`. Godot makes its own debug keystore the first time.
3. The Gradle build template: the script's first run passes `--install-android-build-template`,
   which puts it in `game/android/build/` (gitignored, kept out of the project by its own
   `.gdignore`). Gradle downloads itself and its libraries on the first build (a few hundred MB,
   cached in `~/.gradle`).
4. The upload key, as above (`keytool -genkeypair -keystore ~/.android-keys/nocnawarszawa-upload.jks
   -alias upload -keyalg RSA -keysize 2048 -validity 10000`, the password into the keychain with
   `security add-generic-password -a upload -s nocnawarszawa-android-upload -w`).

Play Console's forms (app details, content rating, target audience, data safety, the store
text) have ready answers in `docs/store/play-console.md`; the privacy policy is
`docs/privacy.md`. Nothing has run on an Android phone yet (see that file's checklist).

## Run it on the Mac

`godot --path game` (or open `game/project.godot` in the Godot editor and press F5).

## Controls

| | iPhone | Mac |
| --- | --- | --- |
| Start (title screen) | Tap anywhere | any key / click |
| Settings (driving, camera, time of day, weather, traffic, picture style, quality, VHS, frame rate, overlay, TEST, sound; the game pauses) | the gear, top left | Esc |
| Drive, **Point** (the default until 2026-11-04) | Drag anywhere on the left side: the car heads where you point, gas by how far you push; the camera waits while your finger is down | W A S D / arrows point in screen directions |
| Drive, **Classic** (the default since 2026-11-04) | Drag left / right on the left side to steer; GAS bottom right, BRAKE beside it (slide your thumb between them) | A / D steer, W gas, S brake |
| Drive, **Fixed camera** | As Point, the camera never turns | as Point |
| Brake, reverse when stopped | BRAKE button | Space (Classic: S too) |
| Camera follows the car / stays put (in Point and Fixed it switches between the two schemes; a toast says which, loop 2e) | Settings → Jazda → Kamera za autem · Camera follows the car: Wł. / Wył. (On / Off) | C |
| Rotate the camera 90° (the fixed camera) | a two-finger twist (loop 2e; with the camera following it does nothing) | Q / E (switches to fixed) |
| Zoom out / in (30–320 m view, default 80 m; 110 before loop 2a) | pinch with two fingers on the right | mouse wheel, `-` `=` |
| Switch visual style (Ostry · Sharp, Drobny · Fine, Czysty · Clean, Toporny · Chunky; saved) | Settings → Obraz → Styl obrazu | T |
| Time of day: Day → Dusk → Night → Live (the real sun now) (1.5 s blend) | Settings → Świat → Pora dnia | N |
| Radio: next station → … → Off | RADIO, top right (the station under the word) | R |
| Radio: the station's next track | hold RADIO for 0.5 s (a tap still changes the station) | Shift+R |
| VHS tape overlay on / off (saved) | Settings → Obraz → Kaseta VHS | V |
| Rain on / off (it sets in over 4 s; the streets dry slower) | Settings → Świat → Pogoda | O |
| Performance overlay on / off | three fingers down at once, or Settings → Obraz | P |
| Frame rate: 60 (default) or 30 (battery saver), loop 2b | Settings → Obraz → Klatki na sekundę · Frame rate | Settings (Esc) |
| Benchmark: a minute on the bench route, then a result card to copy (loop 2b) | Settings → Obraz → TEST | the same (or `--bench-button`) |
| Quality: Auto → Low → Medium → High → Ultra → Auto (loop G1; Auto, the default, picks a level for the device) | Settings → Obraz → Jakość obrazu | U |
| Car ↔ helicopter (from the start) | HELI / AUTO, top right | H |
| Horn (night-buses loop: dogs bark, walkers turn; stopped at a bus stop it calls a bus) | the round horn left of HAMULEC · brake | B |
| Fly (helicopter) | Drag on the left side: it flies where you point | W A S D / arrows (screen directions) |
| Climb / sink (helicopter) | ▲ ▼ pads (where HAMULEC · brake is) | Space / Shift (or F) |
| Open a rescue call that came in (loop 2e: 60 s into play, then 90 s after each one) | WEZWANIE · rescue call, top centre | M |
| Accept a rescue call / next call | PRZYJMIJ · Accept, NASTĘPNE · Next call | M |
| Skip a call | POMIŃ · Skip | K |
| Challenge the rival in front to a race | MRUGNIJ ŚWIATŁAMI · flash your lights | L |
| Take a side job | drive slowly (under ~30 km/h) into the dashed ring by a kebab stand or at Dworzec Centralny | |
| Job card: JEDZIEMY! · Go! / NIE TERAZ · Not now, then OK | the card's buttons (or just drive off: that is GO) | M / K |
| Give up a race, a rescue or a job | ✕ on the status panel | |
| A landmark's info card | tap it (a short tap; a drag still steers) | click it |

**The camera** in each scheme (camera loop; `follow_camera.gd`): in **Point** it holds still
while your finger is on the stick (so the direction you point stays put), then 0.6 s after you
let go eases round behind the car (in ~3 s, at most 64°/s); in **Classic** with CAM on it turns
with the car, easing in and out, at most 64°/s (Settings → Jazda, "Kamera za autem" off, or C:
it doesn't turn); with the camera **fixed** (Point with "Kamera za autem" off) it never turns by
itself (a two-finger twist turns it; on the Mac the `<` `>` keys turn it 90°). In every scheme the view looks ahead the way you go (more
at speed, about 4 s of road at 90 km/h), never slides back when you brake, ignores tiny wiggles,
and widens a quarter at top speed (back in slowly). The helicopter's camera waits while its
stick is held, then comes round the same way. A following camera starts behind the car. When
the title screen goes, the camera flies in from over the city (2.6 s); a new rescue call or
delivery address gets a short look (out ~1.2 s, a moment on the target, back ~1 s) when you
are slow and not touching the controls. Any touch, click or key skips either.

The helicopter takes off above the car and rises to 45 m; the car waits, parked. It holds its
height above the ground, never goes below the ground or through a building (roofs are solid:
it stops at walls and can land on flat roofs), and its blob shadow shows how high it is. CAR
lands it where it is and gives the car back next to it; over a roof it asks for open ground first.

Styles: **Sharp** (480-line pixel image, the default), **Fine** (360), **Clean** (240),
**Chunky** (170 lines, fewer colours).

Keys changed in v0.7: N now switches the time of day (skip a call moved to K), and R tunes
the radio (the helicopter climbs with Space and sinks with Shift or F). Loop 2e: the top row
holds only the gear and the speed (left), WEZWANIE when a call came in (centre), RADIO and
HELI / AUTO (right); the keys are unchanged.

## Night and vaporwave

- **Day** is the original look, calmed in the look loop (no saturation boost by day, quieter
  grass, brick-red cycle lanes, a grey-green-blue river; see The first-minute look). **Dusk** (the dusk loop, 2026-10-31, after the
  user's photos of Śródmieście at 16:20 in late October): the blue hour under an overcast sky, a
  slate-blue sky behind the diorama, flat cool light with no sun shadows (which pays for a soft
  glow, 0.4), glass towers reflecting the grey-blue sky, most windows and every lamp on, the
  Palace of Culture floodlit gold to the spire (`building.gdshader` `floodlight`; it was violet up
  the tower), lit names on the hotels' crowns and red aviation lights on the towers over 100 m
  (`landmarks.gd` `_dusk_details`, `_crown_signs`, `_aviation`; at Dusk and Night). Dawn keeps
  using Dusk's palette. **Night**: deep navy-violet ambient, a
  cold moon (no shadows, which pays for the glow), stars, and the lit city. A switch blends
  over 1.5 s.
- **Lit windows** (`building.gdshader`): a seeded share of each building's windows (some
  buildings mostly dark, some busy; offices more than flats), warm, cool or flickering
  TV-blue; whole floors and runs of bays in the curtain-wall towers; most shop fronts lit;
  neon tubes along the fascia over about 30% of buildings.
- **Neon shop signs** (`neon_signs.gd`, `neon.gdshader`): 361 signs in a 5×7 pixel font with
  generic Polish shop words only (KEBAB 24H, BAR MLECZNY, APTEKA, KWIATY, HOTEL, KANTOR, PIZZA,
  KLUB, NOCNY), on the street side of a third of the buildings, some on a dark plate, a few
  with a tired, flickering tube. Readable from about 70 m zoom in. Sweep 2: ghosted with
  their wall (they never were: a sign on a ghosted wall floated over the ghost, lit and
  mirrored); in the ghost's core a sign goes altogether, over its rim it is dithered.
- **Street lamps**: the 1,822 mapped lamps plus 224 added along the bridges (Most Poniatowskiego
  has none in OpenStreetMap) light the ground from a baked light map (`tools/bake_lights.py`,
  no real lights): warm sodium pools, cold white LED in parks, along footpaths and on about a
  quarter of the streets; pools stop at walls. The same map lights the lower facades, the tree
  crowns from below, parked cars and traffic. Lamp heads glow and wear a soft halo. On the Royal
  Route (Krakowskie Przedmieście, Nowy Świat, Senatorska, Miodowa, Podwale, Kozia, Brzozowa:
  within 8 m of the carriageway's edge, `ROYAL_STREETS`) and in the Old Town (`OLD_TOWN`, a
  190 m circle) the 213 mapped lamps are the historic cast-iron lantern instead (the landmarks
  loop: a dark green post, a lantern 4.4 m up under a cap and finial; `_shared["lantern"]`):
  one more MultiMesh in the 9 sectors that have them. Plac Konstytucji's lamps (`CANDELABRAS`, 75 m round the
  square) are MDM's candelabras: a stone plinth, a tall iron column and three lanterns (one more
  MultiMesh in its sector). The look
  loop made the pools on the ground pixel light: four hard bands with a one-pixel checker
  dither along each step (`night.gdshaderinc` `lamp_pool`, `pool_glow`), never brighter than
  ~80 % of a lit window (pale paving included), and on grass and cycle lanes the lamp tints
  the surface's own colour (sodium on grass reads warm olive, not chartreuse).
- **The player's car** (the look loop) lights from within at night (`actor.gdshader`'s hero
  part, `car.gd` `HERO_PAINT`): its red-orange paint and white stripes read over the dark road
  (it was 30-60 luma darker than the road), with tail lamps that wrap over the rear deck so the
  camera sees them, and a stronger, longer headlight cone than traffic's.
- **Vehicles**: head and tail lamps glow on every car, van, bus, tram and rival, with soft light
  on the road ahead and a red glow behind; bus and tram windows and taxi signs light up; Seba's
  underglow spills onto the road. The player's car also has one real spotlight. Signal lamps
  get halos; the helicopter blinks a red beacon and a white strobe and throws a searchlight.
- **The Palace of Culture** is floodlit: warm from below, violet up the tower, its gilded
  spire and clock dials glowing (v0.8 model, see Landmarks).
- **Grade and sky** (`post.gdshader`): magenta/cyan split-tone at dusk and night (none by day)
  and a dithered sky gradient where the map ends, with stars at night; a light bloom at night.
- **VHS** (`vhs.gdshader`, V): scanlines at screen resolution, red/blue pulled apart, faint
  noise and a tracking wobble that rolls up the picture every few seconds. It runs on the
  container that scales the pixel image up, so the scanlines stay sharp; the HUD stays clean.
- **Title screen** (`title.gd`): chrome AROUND WARSAW (`WORDMARK`; NOCNA WARSZAWA until
  2026-10-30) with the tagline under it, Polish above English (`TAGLINE_PL`, `TAGLINE_EN`), over a striped setting sun with the
  Palace of Culture in silhouette (drawn from the v0.8 model's tiers, in metres), the skyline, the palm from Rondo de Gaulle'a and a neon grid;
  the city builds behind it, then TAP TO DRIVE / DOTKNIJ, BY JECHAĆ. Test runs skip it.
- **Radio** (`radio.gd`, R): 87,3 KEBAB FM, 86,6 RONDO FM, 108,8 MORDOR FM, then Off; on by
  default at a moderate level. The stations and their tracks are in `game/data/radio.json`
  (loop radio-playlists; the built-in names are the fallback when the file is missing). A
  station with one track loops it (today each of the three: *Palma de Gaulle'a*, *Rondo
  Dmowskiego 3 A.M.*, *Mordor Mall Muzak*); a station with several plays them in an order
  shuffled by the date and the station (a day has its own, every run of it the same), each to
  its end, then the next, round and round. Tracks are Ogg Vorbis, decoded as they play (never a
  whole song in memory). A burst of tuning static covers a station change; a now-playing ticker
  at the bottom left shows "87,3 KEBAB FM · Title (Artist)" on a tune and at every new track.
  Between two songs the host (`dialogue.gd`, `radio_host` lines) speaks with a one in two
  chance, 5 s after the title's caption, through the same timer, so a Podwózka card still keeps
  him quiet. Hooks: `radio.announce(text)` puts any line on the ticker,
  `radio.station_changed(index, station)` fires on every change and
  `radio.track_changed(info, track, natural)` on every new track (`natural`: the last one ran
  out); `radio.next_track()` skips (no button yet). Silent in headless runs (no audio device).
  Adding songs: "Adding music" below.
- Synth UI sounds (`tools/make_ui_sounds.py`): a blip for TIME and VHS, the tuning static, a
  rising chord when the title is dismissed.

## Rescue missions

A call names a real place from the map data and the hospital to bring the person to:

| Call | Where | Vehicle |
| --- | --- | --- |
| Street rescue | the middle of a named street or square (OpenStreetMap road names) | car or helicopter |
| Roof rescue | the highest flat spot on a named building's roof, at least 20 m up | helicopter only |
| River rescue | a Vistula beach (Poniatówka and others), the shore, or a sandbar island in the river | island: helicopter only; others: either |
| Park rescue | a named park or square (a child, so the children's hospital if it's closer) | car or helicopter |

Drop-off is the nearest of the two hospitals inside the map, at the road point nearest each:
Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego (Czerniakowska) and Warszawski
Szpital dla Dzieci (children only). To pick up or hand over, stop the car within 6 m of the
beacon, or bring the helicopter within 8 m and less than 4 m above the person, and hold still
for 2 s. The clock is set from the straight-line trip; score is 500 + 10 per second left +
a bonus for the distance, and 8% of it is paid in złoty (+40 respect). The person (first names
only) says a line when picked up (roof, street, river, child or square lines), the crew another
at the hospital. Out of time: TRY AGAIN, NEXT CALL or FREE ROAM.

## A living city

- **Traffic**: cars (hatches, saloons, estates, SUVs), taxis (the city taxi: a white saloon
  with a lit roof sign and a band of dark squares; Podwózka, the app taxi: a hatch with a phone
  on the roof), delivery vans (panel and box vans) and red-and-yellow city
  buses (main roads only; loop 2c: the shapes) drive on a lane graph baked from OpenStreetMap (`graph` in
  `centrum.json`): right-hand traffic, the lane counts and one-way rules of the real streets,
  free-flow speed from `maxspeed` (or the road class), curves across each junction box. They keep
  their distance (an intelligent-driver model), give way to cars already crossing a junction and
  to trams, stop for red lights and for the player's car, and drive round it when it blocks the
  lane. Cars exist only in a band around the view: they appear and vanish out of sight, about
  40–50 on screen at the default zoom (more on main roads). Loop 2a: fewer by default and a
  Traffic setting (about 15 on screen at the new default view; see Loop 2a). At the map's edge they slide out
  under the diorama's rim. Roads that leave the map join the roads coming back in nearby on the
  same side through off-map links (`portals` in the graph, the streets out there): route
  planning uses them and a rival that drives off the map comes back in through one (the little
  Praga streets only meet the rest of the network out east, so this is how they connect).
- **Traffic lights**: 59 junction controllers from the mapped `traffic_signals` stop lines (signal
  nodes protecting the same junction share one controller; a lone stop line just before or at a
  signalled junction joins its cycle, and the two directions of one crossing share a light).
  Two groups of approaches (the two crossing axes; on a signalled roundabout the ring and the
  entries take turns): 18 s green, 3 s amber, 2 s all-red, then the other axis, with Polish
  red+amber before green; crossing lights give cars 26 s green in 40 s. The signal poles' lamps
  show the current colour.
- **Trams**: eight three-car trams in Warsaw yellow and red on the real tracks (Marszałkowska,
  Jerozolimskie, Świętokrzyska, Most Poniatowskiego), choosing a branch at random at points. They
  stop about 10 s at the platforms beside the track, obey the lights of the road running
  alongside, keep apart, brake for the player's car on the rails, and slide in and out at the
  map's edge. They are solid: give way.
- **Pedestrians**: up to 60 tiny people (48 at the Normal traffic level since loop 2a) (shirt, trousers, swinging legs) on the footways near
  the camera (bridge footways included, on the deck), turning into joining footways or back at
  dead ends.
- Hit a car and it is shoved: rear-ended it rolls on, hit from the side it slides off its line,
  and it coasts to a stop for a moment; rivals complain (the driving-feel loop, below).

## Side jobs, the wallet and the city's chatter (v0.65)

- **Wallet** (`wallet.gd`): złoty and respect, shown under the minimap (a coin and a star; a
  payment floats up as "+46 zł"). Races pay the rival's stake (60–300 zł) and +100 respect,
  rescues pay 8% of the score in złoty and +40 respect, side jobs pay fares and tips. Wallet,
  respect, jobs done, best times and easter eggs found are kept in `user://save.cfg` (a
  ConfigFile; on the Mac `~/Library/Application Support/Godot/app_userdata/Around Warsaw/`;
  `.../Nocna Warszawa/` before the rename of 2026-10-30, so a Mac's older save stays there; the
  phones keep theirs, as `user://` follows the unchanged bundle ID).
  No shop yet. Loop 3h slice 1: the save has a version (save v2, see "Save v2 and the districts").
- **Kebab delivery** (`jobs.gd`): seven stands (a kiosk with a pixel KEBAB board, a striped
  awning and a lit hatch; the board glows pink and gold at night) at the two mapped kebab places
  (by Dworzec Centralny, under the Jana Pawła II viaduct, and in the Powiśle food hall) and on
  five busy corners (Rondo Dmowskiego by the Rotunda, Nowy Świat at Świętokrzyska, Solec at the
  foot of Most Poniatowskiego, Marszałkowska at Świętokrzyska, and Al. Poniatowskiego opposite
  Stadion Narodowy on the Praga bank); a stand is never put on a bridge. They blink orange on the
  minimap and wear a dashed ring on the road while nothing else is on. Pull into the ring and the
  vendor talks, then reads the order: a real address ("Wspólna 47/49") 400–1500 m away by road,
  or now and then across the river ("basically the centre", up to 3.6 km by road; from the Rondo
  Dmowskiego stand to Praga and from the Narodowy stand to the west bank). The Praga streets are
  reached through an off-map link from Al. Poniatowskiego (they join the rest of the city east
  of the map): the order's distance counts it; the player drives in however they can, and the
  autopilot jumps it. Same stand and order number, same order (`--kebab=N` takes stand N mod 7). No hard clock: a steam icon and heat bar fade on the way (HOT, WARM, COLD), the
  tip goes with the heat, nights pay ×1.5. The customer waits at the door and tells you how it
  arrived (`kebab_hot` / `kebab_cold`).
- **Słoiki run**: a newcomer with two bags of mum's jars waits by Dworzec Centralny (teal ring).
  Take them to a rented flat in Powiśle (1–2.4 km by road). Six jars in the status panel: hard
  bumps (closing speed over 3 m/s), braking harder than 16 m/s² and cornering over 14 m/s²
  stress them, and a jar breaks when the stress fills (the jars rattle first and the passenger
  warns you). A full stop from 50 km/h or a corner at 30 km/h is fine; slamming the brakes from
  90 or throwing it round a corner at 50 is not. The passenger chats on the way (`passenger`);
  pay is 40 zł + 30 zł a jar (50 + 35 until the designer pass of 2026-11-01,
  docs/design/pay-tables.md), +30 respect with all six.
- **One activity at a time**: a job starts only with no rescue or race under way and not from
  the helicopter; while it runs, rescue calls and race challenges wait, and the helicopter
  stays parked (the order rides in the car).
- **Dialogue** (`dialogue.gd`): loads `data/dialogue.json` (95 original Polish lines with
  English subtitles; a line can be tagged for a situation, e.g. roof-rescue or across-the-river
  lines) and picks lines per group from a shuffled bag, never the same twice in a row. An AI
  driver you hit, or hold up for a few seconds, sometimes shouts a `traffic` line from its car
  (9 s cooldown); the rescued person talks at pickup and the crew at the hospital; the radio
  host reads a `radio_host` line on the ticker (with the English underneath) every 60–120 s on
  a station.
- **Easter eggs** (`eggs.gd`, 5 to find, a small card counts them): **the Palm** on the island
  of Rondo de Gaulle'a (13 m, pink neon ring and violet uplight at night); **pigeons** in front
  of the Palace of Culture's east side on Plac Defilad, pecking, bursting into the air when the
  car or the helicopter comes close and landing again later; **roadworks** (barriers, cones, a
  dig, REMONT and OBJAZD signs) on a different street every day, seeded by the date, that the car
  knocks about (loop 1: 2 m red-and-white barriers, four a side and one at each end, 0.75 m
  cones with a white band, amber lamps on the barriers that blink at dusk and at night, with
  halos); a **crowd at Patelnia** by Metro Centrum; **the Mermaid** with sword and shield on
  the Powiśle boulevard (no Syrenka is mapped inside the area, so she stands on the promenade
  nearest the foot of Tamka). Each says a line the first time you come close. Five joke
  billboards in pixel letters (`signs`: UWAGA: GOŁĘBIE, PALMA · NIE PODLEWAĆ, KEBAB 24H ·
  NAPRAWDĘ 24H, the Marszałkowska roadworks phase 47 of 312, OBJAZD → OBJAZD → OBJAZD) stand
  nearby and show their line with the English when you pass.
- **Joke posters** (loop 1): one green advertising column in six (24 of 141, picked by a
  hash of where each stands) wears a poster wrapped round its band with a `column_posters`
  line from `dialogue.json` (16 original lines: a missing pigeon, a 9 m² room for 3999 zł,
  the tram that just left, Mordor hiring orcs, quiet hours 3:00-3:05...) in the 5×7 pixel
  font, twice (one copy faces the nearest road); passing within 12 m shows the line with the
  English. The letters read close up; at the default zoom the poster is a splash of colour
  and the bubble carries the joke, like the billboards. One shared material (an atlas).

## Rivals and street races

Six made-up rivals cruise the city in their own cars (dots in their colours on the minimap,
name tags up close): **Seba z Pragi** (lowered purple coupe with a neon underglow), **Mordor Mike** (grey
company estate with a roof box, an office guy from Domaniewska), **Pani Halina** (tiny mint
hatch with a basket on the roof, a pensioner late for the bazaar), **Słoik z Radomia** (white
van with a pickle-green stripe and mum's jars on the rack), **Taksiarz Zbyszek** (black taxi, every shortcut
since '87) and **Bulwar Bartek** (neon-green hatch with a speaker on the roof). Seba always
starts near you.

Drive up close behind one (within 15 m, both moving) and FLASH LIGHTS appears (L). Flash, and
the rival names a finish 600–1800 m away by road at a real place: Pałac Kultury, Rondo
Dmowskiego, Stadion Narodowy, the far end of Most Poniatowskiego, the Palm on Rondo de Gaulle'a, Plac
Trzech Krzyży, Kopernik, Złote Tarasy, Rondo ONZ, Varso, Dworzec Powiśle. 3-2-1, then the rival
takes the shortest path on the lane graph (Dijkstra), changes lanes past slower traffic and runs
some reds; you take any route. A beacon, the edge arrow, the distance, the clock and your
position (1ST / 2ND) show the race; reach the beacon (within 16 m) first to win. A card and a
trash-talk bubble end it: win and you get the rival's stake in złoty (Pani Halina 60, Słoik 90,
Bartek 120, Seba 150, Zbyszek 200, Mordor Mike 300) and +100 respect. Only one activity at a
time: no race during a rescue or a side job, rescue calls wait while a race is on, and the
helicopter waits until it is over.

Loop 3h slice 3: the rivals are a ladder now, in order of stake, each opened by the one before and by
respect, each with its own pace, and the final "Trzy mosty" at night ("The rival ladder and the final
"Trzy mosty"" below).

Rivals talk in speech bubbles, Polish with English subtitles (`bubbles.gd`, reusable: anything
can talk, `bubbles.say(node_or_callable, speaker, polish, english)`; `bubbles.tag()` for name
labels).

## Real roads (v0.75)

Roads are most of the screen while driving, so they follow the real streets
(`tools/bake_roads.py`, run by `bake_osm.py`):

- **Carriageway shapes**: where OpenStreetMap maps the carriageway as an area (`area:highway`:
  the main arteries, junction boxes, Rondo Dmowskiego, bus bays; 202 areas), that polygon is
  the road surface and the road's own strip is hidden under it ("hide" ranges on the road).
  Under an area the carriageway's left and right edges are measured from the centreline, so the
  strip, the painted lines and the lane graph's lanes all sit on the drawn asphalt even where
  the mapped line is off-centre (`w` and `c`, the shift right of the line). Elsewhere the width
  comes from `width`, then `lanes:forward` + `lanes:backward` (or `lanes`) at 3.25 m a lane on
  main roads and 3 m on others, plus 1.5 m per painted cycle lane, then the road class.
- **Markings**, all cut where other roads cross and kept off islands and hatched areas: edge
  lines along the carriageway's edges (main roads), lane lines on the lane boundaries (the
  direction line solid on big roads), stop lines at every signal-controlled approach (where the
  cars stop), turn arrows from `turn:lanes` 7 m (and 38 m on long approaches) before the junction
  (left, right, through and their combinations, as pixel shapes), bus lanes from `bus:lanes` /
  `psv:lanes` / `lanes:psv` (a wide solid line and BUS every 60 m), painted cycle lanes
  (`cycleway*=lane`: a line, red surface and a bike every 40 m), hatched areas
  (`area:highway=emergency/prohibited`: an outline and stripes, chevrons in long thin ones).
  Loop 3b-2: spiral lane lines on Rondo Dmowskiego, no arrows on roundabout rings, chevrons
  pointing at the oncoming traffic, wider-celled combined arrows (see Loop 3b-2).
- **Kerbs**: a 14 cm granite kerb (light top, darker face) wherever the carriageway meets
  something that isn't road: pavements, medians, tram beds, islands (121 km). Traffic islands
  are raised to kerb height with a kerb all round. Dual carriageways (two one-way roads running
  opposite ways side by side) get their median: raised grass, or paving at road level where
  trams run in it (mapped grass, islands and hatching stay as mapped). Loop 3b-2: the car feels
  them (lifted onto islands and grass medians, a jolt over a kerb), and the tram bed is a
  concrete track slab.
- **Bridges**: a deck solver gives every bridge road a height profile that clears what runs
  under it (5 m over roads, rails and tram tracks, 7.5 m over the river), ramps at 6 % and meets
  the roads at its ends (12 % at most); bridge footways, tram tracks and rails take the height of
  the deck beside them, and a bridge with no road (the railway bridge, footbridges) solves its
  own. Decks are pieces with a height every 6 m, in groups (one structure each, `decks` in
  `centrum.json`); everything baked onto a bridge carries its group (`dk`). Under every piece a
  concrete slab, parapets on the outer sides and piers; the car drives the deck it is on
  (`map_builder.drive_height`: a deck 5 m overhead is not the road), traffic, trams and
  pedestrians use their own deck. The Jana Pawła II viaduct now rises over Al. Jerozolimskie
  (its OSM 3D model, `man_made=bridge` building parts, is skipped: `br` on those buildings).
  Loop 3a replaced the deck solver: structures are solved with their approaches as chains, the
  clearance is a hard minimum, approaches correct the ground (`fills`), tunnels are kept (see
  Loop 3a).
- **Guard rails**: a steel beam on posts along the carriageway's edges on every bridge and along
  the mapped `barrier=guard_rail` ways (9.6 km), solid for the car.
- **The river's edge** is solid too: the car stops at the water. Loop 10a: a low granite edge
  you can see, under the bridges too and round the fountains (see Loop 10a). Loop 3b-2: granite
  only where the bank is built; natural banks get wet sand and a foam line (see Loop 3b-2).

Check against the aerial photo: `python3 tools/overlay_ortho.py OUT.png X Z HALF` draws the
road areas (red), kerbs (cyan), lines, and the lane graph's lanes (magenta) over the GUGiK
orthophoto (`shots/v075_overlay_*.png`). `godot --path game --resolution 320x180 --script
res://tools/count_vertices.gd` prints the city's vertex count.

## Landmarks (v0.8)

The buildings that make it Warsaw at a glance are built in code (`landmarks.gd`), sized and
placed from the real footprints and heights in `centrum.json` (OpenStreetMap outlines and
`building:part`s with `height` / `min_height`), and replace their LoD2 / OpenStreetMap lumps:
whole LoD2 buildings whose middle lies in a landmark's zone are left out (the bake writes each
building as one run of triangles sharing its style seed, UV2.x), and so are the OpenStreetMap
outlines and parts centred in it (and their neon shop signs). Checked over the GUGiK orthophoto
(`tools/overlay_landmarks.py`, `shots/v08_overlay_*.png`).

- **Pałac Kultury i Nauki**: in its own frame (the Śródmieście grid, from the mapped 139-168 m
  clock tier): the base round its two courtyards and the Congress Hall's drum, the corner
  pavilions, the annexes and the east portico; the four corner towers to 67 m, the ribbed shaft
  to 139 m, the clock tier to 168 m with a dial (6.3 m) on every face showing the time in
  Warsaw (loop 1),
  the lantern's dark arches to 188 m, the patina crown and the gilded spire to 237 m. Every
  tier ends in a crenellated attic (the shader cuts the merlons: one quad per wall) with
  pinnacles at the corners. Its stone wears tall windows between piers with a pilaster every
  fourth bay; at night it is floodlit as before.
- **Złote Tarasy**: the glass wave is one surface over the eight mapped glass domes, each a cap
  to its mapped height (35 m by the offices, 22 m towards the station), blended where they meet
  (log-sum-exp, 2.6 m) so it rolls instead of creasing, laid on the ground's slope, with glass
  walls round its rim; a diamond lattice by day, glowing gold at night. Lumen and Skylight stay
  LoD2. The landmarks loop: the glass is golden (`#d4b066`, with less sky in it and a whiter
  lattice; it read as ice before).
- **Rotunda**: a granite plinth, two storeys of glass lit from inside, a lit band under the
  overhanging white roof, which rises in ribs to a glass oculus.
- **Varso Tower**: from its mapped parts (the glass slabs, the dark spines at both ends, the glass
  crown 193-234 m, a lantern lit cool white at night); the spire's thin parts become one mast to
  310 m with its five rings and a red beacon.
- **Stadion Narodowy**: its outline at every angle from the 72 pairs of mapped masts: the woven
  red-and-white skin leaning out like a basket from the old embankment's crest to the roof's
  edge (two families of diagonal strips, red over white then white over red, lit at night),
  72 masts leaning with it and spiking over the roof, the white membrane round the open middle,
  red stands with grey gangways down to a striped pitch, the needle hanging over the centre
  (30-100 m, a red light on its tip) on its cables, a paved promenade on the crest. The
  embankment is the terrain (the old Stadion Dziesięciolecia's bowl); the mapped 14 m podium
  that covered the bowl is dropped. **The grass embankment** (2026-11-01, `landmarks.gd`
  `_find_embankment`, laid by `map_builder.gd` `_build_areas` at `BANK_Y`): along each mast's
  ray the bank's slope is found on the terrain (from 1.15 x the inner masts' radius: the
  ground falls 15 % or more once 2.5 m under the start, its foot where it flattens under 9 %,
  cap 1.75 x), and a grass band per mast gap is laid on the ground's grid under every mapped
  area, so only the bare slopes turn green; the plaza, its lawns and stairs, paths and roads
  stay on top. No new draw call (the flat layer), the terrain and the drive are unchanged.
- **Warszawa Centralna** (mapped in 3D, its outline underground): a 140 x 57 m roof of
  hyperbolic-paraboloid shells on the mapped pillars (saddles whose corners rise and fall in
  turn, so the eaves zigzag), the glass hall under it, the canopy round it to 140 x 86 m.
- **Most Poniatowskiego**: its four towers at the ends of the river span (mapped outlines, no
  heights): plinth, shaft and cornice to 15 m over the deck, an arcade, a pointed roof, a finial.
- **The skyline's towers** (the landmarks loop, 2026-10-30; `landmarks.gd` `TOWERS`): Złota 44,
  Warsaw Spire, Q22, Rondo 1, Emilii Plater 49 (the hotel with the gap), Cosmopolitan, Warsaw
  Trade Tower, Skyliner, Warsaw Unit, Mennica Legacy Tower, Generation Park Y, Skysawa,
  Błękitny Wieżowiec, Warszawskie Centrum Finansowe, Centrum LIM, Chałubińskiego 8, Spektrum
  Tower and The Bridge, and in a second pass Grzybowska 63, Jana Pawła II 21 and Marszałkowska
  94/98 (the hotels, under parody names on their cards: Chilton, Westynka, Nowotel), Central Tower, Ilmet, Platinum Towers A and B, Łucka
  City and Widok Towers, were all the same blue box. Each is now built from its mapped parts
  (what else stands in its outline, LoD2 or OpenStreetMap, is dropped; the outline itself is
  left out when parts are mapped; a part starting in the air with nothing mapped under it
  stands on the ground; parts under 9 m across are painted steel: masts, rings) in its own
  glass colour, roof colour and skin (`M_SKIN`, the fraction picks `S_*`, `building.gdshader`
  `skin()`): Złota 44's white exoskeleton (floor bands and long diagonals) with its top cut on
  a slope, Warsaw Spire's diamonds, silver floor bands (Q22, WTT, Unit, Skysawa, Spektrum),
  vertical fins (Rondo 1, Skyliner, Mennica, The Bridge, Chałubińskiego 8's white ribs in their
  mapped colours), the hotel's white grid, Cosmopolitan's white balcony slabs, dark glass (WCF,
  LIM, Generation Park Y), gold glass (Błękitny Wieżowiec) and Rondo 1's open crown frame from
  its roof to 192 m (`S_FRAME`: the panes are cut away). Q22 stood 55 m tall (its LoD2 model
  predates the tower); it is 155 m now. Each has an info card; the far skyline (proxies) takes
  each tower's glass colour.
- **Złota 44's sail** (after the user's phone look, "a rectangle, not curvy"; `_zlota_sail`):
  the tower is lofted through 8 rings from the mapped core's corners: a straight west front,
  soft corners, and the east front a curve that swells as it climbs (4 m out at the foot, 14 m
  at the crown), the crown cut on a slope from 192 m at the north to 158 m and glazed like the
  walls. Only the podium is still built from its OpenStreetMap parts.
- **Warsaw Spire** (after the user's phone look, "not recognisable at all"; `_spire`):
  OpenStreetMap has the 180 m tower only as its outline (the crown and masts are parts from
  180 m up), so it stood as a lump. It is lofted from the outline through 6 rings, narrowing to
  84 % at 180 m, with an open frame of fins to 196 m and a mast to 220 m. Its brand's parody,
  SAMSONG, glows on the east and west faces near the top: a landmark sign (`signs`,
  `map_builder._build_landmark_signs`, `neon_signs.gd` `LANDMARK_WORDS`, never a shop's word),
  drawn with the neon signs' shader but lit by day too (`INSTANCE_CUSTOM.z` = 2) and outside the
  night lights' holder. The two 55 m buildings beside it come from their parts.
- **Rondo Daszyńskiego** (after the user's look, "too simple with rooftops"): The Warsaw HUB's two
  130 m towers are landmarks too, found by a point rather than an OSM id (`_tallest_at`: the
  tallest kept outline holding that point; `bake_sectors.py` `SITE_AREAS` has their box), in
  pale glass with white fins and a card. Their tops, Mennica Legacy's and Generation Park Y's
  are cut on a slope (`"crest": "slope"`), and every sloped roof is glazed in the walls' glass
  tinted toward the roof colour, since a pale slab tilted to the camera blew out.
- **Old Town and New Town tenements** (after the user's look, "kind of generic"; map_builder
  `_tenement_facades`, `HISTORIC`): GUGiK models a whole block as one LoD2 building (Rynek's
  sides are 49 and 84 OpenStreetMap houses in one model), so a block stood in one colour. In the
  two historic districts each LoD2 wall takes the colour (OSM `building:colour`, else the
  `TENEMENTS` palette) and window seed of the OSM house a metre behind it, and each pitched roof
  is half mixed toward a tile red (`TILES`). Churches keep their own (`NOT_TENEMENTS`). Load time
  only; the same on both city paths.
- **Brick Gothic and the Metropolitan** (after the user's look, "churches look like default
  buildings"): the Cathedral and the Barbican are drawn in brick Gothic (`M_GOTHIC`,
  `building.gdshader` `gothic()`): brick in slow patches, a stone plinth, a buttress every
  6.5 m and tall pointed lancets on walls over 9 m, their stained glass faintly lit at night.
  Foster's Metropolitan on Plac Piłsudskiego wore the towers' fin skin (`S_FINS`) in grey glass,
  with a card (a model since Plac Piłsudskiego part 2, below).
- **Kolumna Zygmunta** (`_build_zygmunt`): OpenStreetMap maps the column in a dozen tiny 3D
  parts that the builder dropped as specks, leaving a dark cube on Plac Zamkowy. It is built
  as a landmark in a circle zone: three granite steps, the pedestal, the 12 m shaft, the
  capital and the king in bronze with his cross raised and his sabre, to 22.9 m, with a card.
- **Map north** (the user's ask; docs/DEMO.md 2.1 "Hand-over"): **Arkadia** (`_build_arkadia`)
  is its OpenStreetMap outline lifted as one block: a glass storey lit from inside, pale panels
  to 21 m, the grey roof deck with three long skylights along its axis, and the 37 m entrance
  tower with the parody of its name, ARKADKA, lit on both faces (a landmark sign, `LANDMARK_WORDS`;
  card "Arkadka"). **Forest** (`_build_forest`) from its mapped parts in `FOREST_BOX`: the 120 m
  tower in dark green glass with fins, the lower wings in glass bands under planted roof
  terraces with a hedge round each. **The flag on Rondo Radosława** (`_build_flag`; not in
  OpenStreetMap): a 57.8 m steel mast with a gilded finial at (−2,850, −2,295) and a 16 × 10 m
  white-and-red flag in folds, flying east.
- **Most Świętokrzyski** (`_build_swieto`; the user's ask): the decks are map_builder's, the
  landmark adds what made it a plain viaduct before: the concrete pylon on the Praga bank in
  the 2.6 m median, from the ground through the deck to 70 m (map y), leaning 7 m back east, a
  red aviation light on top, and its stays in one plane along the median, 12 over the main span
  west and 9 back east, landing a metre over the deck's profile (`_swieto_deck`, a parabola
  through the bake's crown). The site is the median strip under the stays, so every sector
  they cross builds them.
- **Muzeum Narodowe** (the museum and Plac Piłsudskiego loop, 2026-10-31; `_build_muzeum`): the
  landmarks loop kept the LoD2 model in stone (`skin_at`); now it is a model like the Palace. The
  mapped outline (481 points: every pier) is straightened to 18 corners (`_simplify`,
  Douglas-Peucker at 1 m) and stands at 18.5 m (`MUZEUM_WINGS`; it was the mapped 14.2 m) on a darker plinth, with a
  parapet; tall narrow window bays every 4.4 m on every front (`_bays`: panes 0.07 m proud in
  the curtain-wall glass, `M_GLASS`, a transom every 4 m, some lit at night); at the back of the
  forecourt (Dziedziniec Lorentza, open to Al. Jerozolimskie) the raised entrance block to 25 m (`MUZEUM_TOP`, was 20):
  a recessed glazed portal behind four square piers under a lintel, a tall bay either side,
  steps. In the east courtyard the army museum's hardware on concrete pads: a tank and a field
  gun. The zone is the outline plus its courtyards (the convex hull's pieces outside it over
  1,000 m²: the LoD2 model's centre falls in one), so the LoD2 or OpenStreetMap model is dropped
  and the garages beside it stay. About 690 triangles, in the city's building mesh (no draw call
  of its own); its card as before.
- **Plac Piłsudskiego's edges** (the same loop): **Hotel Europejski** (`_build_europejski`, its
  mapped outline straightened at 0.8 m) in cream: a rusticated ground floor and mezzanine to 6 m
  (five stone courses, each with its light edge, `M_STONE`) with tall dark openings every 4.6 m,
  three floors of windows between pilasters above (`M_MONUMENT`) to the 19 m cornice, a
  projecting cornice, a low hipped roof in grey-green sheet, and a central bay stepping forward
  on the Krakowskie Przedmieście front and on the square's (an attic over it, a tall entrance);
  about 400 triangles, a card. **Grób Nieznanego Żołnierza** (`_build_grob`, a fixed place like
  Sigismund's Column; the zone is its mapped outline grown 1 m, which drops the hundred tiny 3D
  parts it is mapped in): the three arches left of the Saxon Palace's colonnade on a granite
  platform: two rows of four piers, round arches on both long faces (`_arch`), the entablature
  and cornice to 7.65 m, the tomb slab with wreaths and the eternal flame (`M_LAMP`, lit at
  night) on the square's side; about 280 triangles, a card.
  Rendered draw calls are unchanged (`--probe` on lavapipe: 100 → 100 at the museum's front,
  133 → 133 on the square): every model is in the city's building mesh and material.
- **Plac Piłsudskiego, part 2** (2026-10-31; `landmarks.gd` `_find_plac2` and the builders after
  it). **The Metropolitan** (`_build_metropolitan`, its mapped outline straightened at 0.4 m): a
  model instead of the fin skin: the curved fronts in curtain-wall glass (`M_GLASS`) behind real
  granite fins (`_fins`: 0.34 m thick, 0.9 m deep, one every 1.8 m round the outline, from the
  ground to the parapet, with tops), the circular courtyard (centre and 25.4 m radius from the
  blocks' mapped inner arcs) in glass with painted fins (`S_FINS`), the three passages as dark
  openings 6 m wide and 6.6 m high under a granite lintel on both faces (no fins there), a flat
  roof and parapet at 20.8 m, the seventh storey set back 2 m to 24.1 m, the three blocks'
  plant rooms to 27.4 m, and in the courtyard the paving, the round fountain (a dark pool in a
  granite rim) and eight jets. About 2,600 triangles; its card as before. **Hotel Wiktoria**
  (`_build_wiktoria`; the parody name of the 1976 hotel on Królewska, mapped as an outline
  only: LoD2 drew it, OpenStreetMap has no building there, so without GUGiK's data the plot
  was empty): a podium over the whole outline in dark glass (`S_DARK`, its lobby lit at night)
  under a pale stone fascia, the slab along the Królewska front 18 m deep in ribbon windows of
  bronze-tinted glass between pale bands (`S_BANDS`), a parapet and a plant room; about 190
  triangles, a card. **The Królewska edge** keeps its LoD2 or OpenStreetMap shapes in its own
  stone (`PLAC_SKINS`, `skin_at`): Dom bez Kantów (pale grey stone, the city's plain window rows:
  a skin `mode` under 1 is that seed) and the Departament Wojskowej Służby Zdrowia (pale stone,
  `M_MONUMENT`), each with a card, and the unnamed block on the square's south-east corner
  (`KROLEWSKA_BLOCK`, a point in its west wing; `bake_sectors.py` `SITE_AREAS` carries it) in
  pale stone with no card (so it isn't on the picking grid). The far skyline takes each wall
  colour (`PLAC_WALLS` through `tower_colour`).
  **Heights, known and estimated**: the Metropolitan's 20.8 / 24.1 / 27.4 m are the mapped parts'
  (OpenStreetMap `building:levels`: six, seven and eight storeys at 3.3 m + 1 m; known to be seven
  storeys round a courtyard, about 30 m: close). Hotel Wiktoria's are estimates: the slab 30 m
  (nine storeys over a two-storey podium), the podium's fascia 8 m, the slab 18 m deep. Muzeum
  Narodowe: the wings 18.5 m and the entrance block 25 m are estimates (OpenStreetMap says four
  storeys, which the bake makes 14.2 m at 3.3 m each; a museum's storeys are taller);
  Hotel Europejski's 19 m cornice stays an estimate. Photos would set all of these.
  Rendered draw calls (`--probe` on lavapipe, 2532×1170): the museum's front 100 → 100, Plac
  Piłsudskiego (`--at=-760,-820`) 134 → 133, in front of the Metropolitan 97 → 96 (its
  OpenStreetMap parts went; every model is in the city's building mesh and material).
- **Low-rise landmarks** (`landmarks.gd` `SKINS`, the third pass): 15 buildings players pass
  every few minutes keep their LoD2 or OpenStreetMap shapes but take their real stone, brick
  and roof colours through `skin_at` (as Muzeum Narodowe did before its model): Teatr Wielki's pale stone
  and green copper, Zamek Królewski's brick red, Barbakan's and the Archikatedra's brick,
  Centrum Nauki Kopernik's dark grey with a green roof, the Library's green roof, St Anne's,
  the Holy Cross, All Saints' and St Alexander's, the Presidential Palace, Staszic Palace,
  Zachęta, the Mirowska halls and the Sejm. Each has an info card; the far skyline takes each
  wall colour. The Planetarium and the Church of the Saviour
  stay as they were (their outlines carry no roof the helicopter check accepts).
- **MDM** (`landmarks.gd` `_find_mdm`): the unnamed blocks over 15 m round Plac Konstytucji
  (95 m) and along Marszałkowska to Plac Zbawiciela (50 m from the axis) in pale sandstone with
  tall windows (`M_MONUMENT`, `#cdbfa3`) and grey roofs, one card. `skin_at` takes a whole box
  only for a site of one outline; for MDM's many blocks a model's centre must be
  in one of them. `bake_sectors.py` `SITE_AREAS` carries its parts.
- **Bus and tram shelters** (the landmarks loop; `map_builder.gd` `_make_shared`): Warsaw's
  glass shelter as the game's camera sees it: a pale glass roof in a graphite frame overhanging
  the kerb, a dark fascia, glass back and end, three posts, a bench, a poster box at the far end
  whose faces glow at night (`SHELTER_POSTER`, drawn with the street lamps' `fixture.gdshader`,
  `SHELTER_GLOW` in each instance's custom data) and the stop's blue D-15 sign on its own pole.
  Still one MultiMesh per tile (the draw calls are unchanged); 288 triangles a shelter (was 48).

Materials (`building.gdshader`): UV2.x >= 2 is a material code (`landmarks.gd` `M_*`: monument
stone with windows, plain stone, crenellated attic, gold, clock dial, woven skin, glass wave,
lit glass pavilion, curtain wall, lamp, membrane, a tower's skin), its fraction a parameter; UV2.y the wall's
top; UV the metres along and up a wall. Every landmark triangle also goes into the helicopter's
roof grid (the Palace's spire stands 236 m in its cells, so it can't be flown through; roofs
can be landed on) and into a grid of which landmark covers each 4 m cell; their walls at street
level stop the car. Roof rescues still come from the landmarks' outlines and the roof grid (on
the Palace now a 28 m roof: the tiers are crowned by attics and pinnacles).

**Info cards**: a short tap (under 0.35 s and 16 px, not on a control, not a pinch) goes out as
`hud.tapped`; the game walks the ray from that pixel through the roof grid (1 m steps) and, if
the first thing standing is a landmark, shows its card in the note card's place for 8 s: name,
one or two Polish lines, the English under them. Landmark card fix: the note and landmark cards
stand first in the right-hand column under the top row, beside the car (the status panel's and
the ride card's column), at most 236 pt wide and no wider than the room right of the car's spot
(`side_card_width()`); on a 375-pt phone they used to find no room and never showed.
`--tap=X,Y` taps a screen pixel at frame 60.
Sweep 2: the walk steps on through whatever the occlusion ghost has made see-through (half its
pixels or more gone, ghost.gdshaderinc's test on the frame's values, main.gd
`_pick_unghosted`), so a tap on the cut-away part of a tower in front of the car picks what
shows through the cut (a landmark, or nothing on the street), not the tower.

**Occlusion ghost** (reworked in loop 1, `shaders/ghost.gdshaderinc`): besides the small
see-through hole round the car (which opens fully), everything standing on the camera's side
of the car (more than a metre nearer the camera, measured along the ground, full from 4 m)
inside a region round the car on screen (an ellipse 0.22 x the view's height, wider than tall,
lifted a little, its upper half stretched 1.35 times so a tower's top fades out instead of
ending at a cut) turns into a thin ghost: in the core only 3 pixels in 16 stay
(`ghost_keep` 0.19), and a dithered rim (0.65-0.9 of the radius since the look loop; it was
0.55-1.0 and speckled roofs that don't hide the car) runs out to the whole wall. Every fragment
goes, near walls, far walls and roofs alike, and looking into a cut building its inner faces go
too. What the ghost keeps has no outlines (the post pass outlined every kept pixel, which turned
the ghost into a dark stipple) and nothing in it glows (the look loop: its windows, shop fronts
and neon tubes lose all their light with the ghost's fade; loop 1 kept 30 %); the inner faces
of a cut building seen through it are unlit and flat, a step darker than the street. Under the ghost the
ground lifts the buildings' baked shade (the AO map's buildings channel; the trees' and
parked cars' shade stays) and, inside a ghosted footprint, which its own building always
shades, gives back the sunlight (all of it with a sun above 40 degrees, none below 15: the
streets round it lie in long shadows then; none at night or without shadows). Not in the
shadow pass, so the ghosted towers still cast their shadows on the street. `--ghost-debug=1`
paints the ghost magenta and the other buildings green and prints the ghost's ellipse in
screen pixels with every screenshot (for measuring), `--ghost-debug=2` cuts it fully.

What showed through before loop 1, measured with debug renders (full cut, `--no-ao`, Low
quality for no shadows): the ground inside the footprint, at 0.28 of its brightness from the
baked AO and in its own building's shadow (the dark stain), plus every kept wall pixel
darkened by the depth outline; the clear colour never showed, and back faces only where the
car stood inside a footprint. Mean luma inside the ghost (the pixels a `--ghost-debug=1`
mask marks, within 0.8 of its radius) against a ring of ground 1.02-1.3 radii out (ratio,
before → after): spawn by day 0.80 → 0.99, spawn following the car
(`--demo`) 0.89 → 0.92, Live 08:00 by the glass tower 0.98 → 1.06 (pixels under 60: 9% →
7%), the Palace from the north-west 0.70 → 0.83 (the rest is the Palace's own shadow, which
lies over the car), the v0.8 Palace close-up 0.68 → 0.85, Rondo Dmowskiego at night in the
rain 1.14 → 1.14 (in v0.9's rain shot, where the ghost only catches a tower's edge, 0.68 →
0.74).

**The Palm** stands where the laser scan found it (loop 1): the 14.5 m "tree" with a 4 m
crown alone on Rondo de Gaulle'a's island is the Palm itself (about 15 m), so the bake leaves
it out of the trees (`GUGIK_NOT_TREES` in `tools/bake_osm.py`) and writes where it stands as
`palm` in `centrum.json`; `eggs.gd` stands the Palm there.

**Floating parts** (loop 1, `map_builder.gd`): an OpenStreetMap building part is drawn from
its `min_height` up; where the parts under it are not mapped it hung in the air (Varso 2's
80-90 m top over a 72 m neighbour: a broken lamp post from the south-west). A part starting
10 m or more up that rests on something (a part reaching to within 3 m of its bottom, or
within 2.5 m a LoD2 building or a landmark) under less than half of its footprint is lowered
to the highest roof below that carries half of it, or to the ground; tiny ones (under 12 m²)
are left out. In this map: 17 floating parts, 5 lowered to the ground (Varso 2's 80-90 m
top; a 78 x 19 m slab at 14-35 m beside Złote Tarasy, at -1491,522; two 12 m parts at 23 m
at -300,360; one at 25 m at -1497,-170) and 12 tiny ones left out (a stack of spire parts
at 155-195 m on the map's west edge, at -1766,-176, with no tower under them in the data).
Lower overhangs (canopies, passages, pilotis under 10 m) stay as mapped. The build prints
the count.

**The Palace clock** (loop 1): the four dials' hands are drawn by `building.gdshader` from the
disc's UVs (the point on the dial in radii) and a `clock_hands` uniform that `main.gd` sets
when the minute changes, from the device's clock in Warsaw time (or `--clock=` /
`--date=`): no geometry, nothing per frame.

`godot --headless --path game --script res://tools/check_landmarks.gd` checks each landmark: its
tallest roof-grid cell, that a tap finds it, that a car driving in from 12 directions is stopped,
that the helicopter (heli.gd stepped by hand) flying at it at half its height is stopped outside
it and then lands on open ground beside it, the roof rescues on the replaced outlines and the
cells round the Palace's spire.

`godot --headless --path game --script res://tools/check_mesh_quality.gd` (verify step `meshq`, in the
quick set and in CI; landmarks plan 0.1 and 0.2) builds EVERY landmark site alone (`landmarks.build(surface, near, only)`
on a stub map, from the committed `centrum.json`) and checks its mesh: a triangle BUDGET per site (a
site with none fails, so detail never goes in without a limit), every triangle in a landmark material code
(no draw call of its own), z-fighting (same-facing triangles on one plane within 2 cm overlapping by
more than 0.01 m2), zero-area triangles, normals that disagree with their geometry, and parts floating
clear of the ground and of every other part. `KNOWN` (a per-site ratchet) is empty since 2026-10-31: every site is at zero, and
any new defect fails at once. The builder cuts coplanar walls, roof caps and sloped crowns back to what
shows (`landmarks._wall`, `_cap`). A new site gets its
`BUDGET` line (measured + about 20 %) in the same change; the art-director judges only after this passes.

`godot --headless --path game --script res://tools/check_sites.gd` (verify step `sites`, in the
quick set and in CI; the museum and Plac loop) checks the models at Muzeum Narodowe, Hotel
Europejski and the Tomb from the committed `centrum.json` alone (a stub map, flat ground): each
site found (the museum a model, not a skin), what it replaces dropped and its neighbours kept
(the garages, the papal cross, Pałac Potockich, Teatr Narodowy, Zachęta), and each built alone within its triangle
budget (2,500, 1,500, 600), every triangle in a landmark material code (the one building
material: no draw call of its own) and inside its box + `SITE_REACH`, with car walls, tap cells
and a card whose Polish and English lines are at most 70 characters. Plac Piłsudskiego part 2
added the Metropolitan (a model, not a skin; its parts dropped, its LoD2 model's centre in the
courtyard replaced; budget 3,200) and Hotel Wiktoria (the LoD2 centre in its plot replaced, the
canopy part dropped, the outbuilding behind kept; budget 900; no card may name the real hotel),
and the Królewska edge's skins: each found, the building at its point kept and in its colours,
a card for the named two and none for the unnamed block.

## Money pops and district beds (v1.0 juice, 2026-11-01)

`money_pop.gd`: wallet `changed` with `gained > 0` shows a gold "+54 zł" (4 Label3D in a ring,
billboard, unshaded, no depth test; size grows to 200 zł; rises 3 m over 1.5 s following the
vehicle; a young pop pushes the next one up; calm mode: no pop-in and no rise) and `sfx.coin()`.
No script runs while no pop lives. `--pop=<zl>` pays once 2 s in for shots.
District beds: `districts.gd` emits `entered(id)`; `sfx.set_district` fades one of four loops
(`amb_river` Powiśle, `amb_park` Ujazdów i Łazienki, `amb_square` Old Town and Royal Route,
`amb_yard` Praga and Muranów; centre, Wola, south keep the city bed) over ~3 s, quieter in rain,
at night and in the helicopter. All from `tools/make_sfx.py`. Check: `check_juice.gd` J6, J7.

## Water, weather and sound (v0.9)

**Sound** (`sfx.gd`, every file made by `tools/make_sfx.py`: oscillators, noise and filters,
no samples). Buses: Master, **Music** (the radio, player at -9 dB), **SFX** (-3 dB) and
**Ambience** (-9 dB, and 4 dB lower while a station plays, so the radio keeps priority).

- The car: three engine loops of a tired 1.2 l four-cylinder hatchback (850, 2400 and
  4500 rpm; one weak cylinder, a little timing jitter, a tinny back box), crossfaded and
  pitched by a five-speed box (upshifts at 23, 45, 68 and 92 km/h with a short dip in the
  sound, a slipping clutch from rest, a hunting idle); load from the throttle (or, for the
  autopilot, how hard it speeds up). Tyres rolling on dry asphalt by speed, a hiss instead on
  a wet road, a squeal in slides and under hard braking (quieter in the rain).
- Collisions where the haptics are (`car.impact`): a soft thump, a hard one, a crash, by
  closing speed; a guard rail clangs (a 4 m grid of the mapped rails); the słoiki run's jars
  clink at every bump and warning and shatter when one breaks.
- The helicopter's rotor (four-blade slap at 18 Hz, turbine whine, tail rotor) winds up with
  the blades after take-off and down after landing; pitched by speed and climb.
- The city: a day bed (distant traffic, cars passing far off) and a quieter night one,
  stereo; birds every 7-16 s by day (not in rain); at night, every 45-110 s, a far siren or
  a dog. Rain has its own bed.
- Positional (AudioStreamPlayer3D, a pool of six: the cap on voices; heard within 85 m of a
  listener 12 m over the camera's focus): a tram's two-tone bell when it leaves a stop or
  brakes for your car on its track, a horn (sometimes) from a driver you hold up or hit, the
  pigeons flushing on Plac Defilad.
- iOS: the audio session is **Ambient** (`audio/general/ios/session_category=0` in
  project.godot): the phone's silent switch mutes the game, and your own music keeps
  playing under it.
- Checks: `python3 -I tools/make_sfx.py game/audio/sfx` prints peak, RMS,
  the loop seam (step and slope across the loop point against the 99.9th percentile
  elsewhere), the share of energy under 2 kHz and the roll-off for every file; `godot --headless --path game --script res://tools/check_sfx.gd` checks the
  imports (Forward loops, QOA) and decodes across each loop point; `godot --path game --
  --sound-check` (with an audio device) plays every one-shot and prints each bus's peak;
  the bench prints the buses' peaks while driving.

**Rain** (`weather.gd`, RAIN / O / `--weather=rain`): Clear or Rain, separate from the time of
day. `amount` (how hard it rains) drives the streaks, the rain bed and an overcast light
(the sun 45% weaker, a greyer sky and ambient, shadows at half strength); `wet` (how wet the
streets are; dries three times slower) is the shader global `wetness`:

- Streaks: three layers of one-pixel streaks in the post pass (far: short and slow; near:
  long and fast), slanting with the wind, drifting a little with the view; a grey veil by day.
  Screen-space: cheaper than particles on the Mobile renderer, and they follow the camera.
- Wet ground (`ground.gdshader`): asphalt 38% darker, paving 26%, markings 18%; a sheen of
  the sky; puddles from a noise mask on roads and paving only (never kerbs, islands, grass or
  roofs), darker, mirror-like, with rings where the drops land.
- Reflections (`post.gdshader`): on a level surface that the surface map calls water, road or
  paving, the mirrored view ray is marched up the screen through the depth buffer (10 steps on
  High) and what it hits is mixed in, smeared a little along the ray: every lamp, neon sign,
  signal, headlight and lit window stretches into a vertical streak on the wet asphalt at dusk
  and night; puddles mirror most. The street lamps' light map adds broken columns of lamp
  light on wet ground and water too (so even Low, with no mirror, has them).
- Grip: 22% less sideways grip and 15% less braking on a wet road: the tail lets go a little
  sooner. Wet tyres hiss instead of rolling.

**The river** (`tools/bake_water.py` → `map/water.bin`, the *surface map*: RGBA per 2 m, inside
`city.scn` like the light map): distance to the shore inside the water (the depth colour: light
and a little green at the edge, deep blue mid-river; ponds go deep sooner), the Vistula's flow
(north, turning with the banks: the middle of the river per row, smoothed over 120 m), what
reflects (paving, road, still water, the river) and the height of any bridge deck.

- The water slides downstream (a flow map in two crossfading phases, 0.7 m/s), stretched
  along the river; ponds and fountains are still. Shore foam laps in a broken band (thin
  round ponds and fountains); a rare sun glint flickers on the highest crests by day.
  Loop 1 calmed it to a slow lowland river: a touch deeper and greyer, the flow a
  low-contrast drift (half that again at night), the glints fewer and smaller. The look loop:
  by day the depth shading starts from a grey-green-blue (`DAY_WATER`; the mapped azure read
  as an open sea), the pale crests a third as strong and the sun sparkles a quarter as many
  (1-2 px each); at night the water is as before.
- Bridges: by day a bridge shows on the water beside it as a darker shaded band (loop 1; the
  pale mirrored copy of the concrete read as a wake; half as strong since the look loop), the
  water under the deck in its shade; at dusk and night the mirror carries the lamps and lights.
- At night the water gets no lamp pools any more: the bridge lamps and the boulevard lights
  reflect as shimmering columns of broken light, and the mirror catches their heads, the
  cars' lights and the lit windows. Loop 1: the pink and cyan glints that washed over half
  the river (the "camouflage") are gone; the water is dark and calm. (Backlog fix: nothing under a bridge deck gets the deck
  lamps' pools now, ground or water.)
- Ponds and fountains share the shader.

**Live** (TIME's fourth mode, `--time=live`): the real sun over Warsaw (52.23 N, 21.01 E) for
the device's clock, from NOAA's solar-position formulas (UTC in, so the time zone only matters
for the label and `--clock`): Day above 10 degrees of elevation, blending to Dusk round sunset
(10 to -2) and to Night below -10; the sun turned to its real azimuth with its pitch held
between 20 and 55 degrees (midday still has shadows; a low sun doesn't throw them across the
map). Rechecked every 10 s. The TIME button shows "Live 13:05" (Warsaw time: CET, CEST from
the last Sunday of March to the last Sunday of October). `--clock=HH:MM --date=YYYYMMDD` start
the clock at a Warsaw time for screenshots (it then runs on); `godot --headless --path game
--script res://tools/check_sun.gd` prints the sun for a few dates and times. Day is still the
starting mode.

**Performance overlay** (three fingers down at once, P, `--perf`, Settings; reworked in loop 2b):
updated twice a second, fps, the average and worst frame since the last update, the main
thread's split (CPU: process = every script's `_process` and the 2D redraws, physics, draw =
building and handing the frame to the GPU, which grows when the GPU is behind or the display
makes it wait), the 3D view's GPU time (n/a on Metal, so n/a on the iPhone; Vulkan on the Mac
shows it), draw calls split into the pixel image's 3D pass, its shadow pass and the 2D pass
(HUD and the scale-up), objects, triangles (and the shadow pass's), static and video memory,
the pixel image's size, time of day, weather, the frame-rate cap and sound voices, then
**QUALITY** and **TEST · BENCH**. It costs a timestamp per frame phase and one label update
every half second. (Godot's own "process" monitor, which the overlay showed before, is the
slowest whole frame of the last second, rendering included: on the iPhone it read 60 ms because
the frame did.) Loop 2e cut it to four lines; loop G1 made the last one the quality, its pixel
scale and the governor (`High ×2 · gov GPU 2/2 · CPU 2/2 · wide`); objects and the shadow pass's
triangles are on the BENCH card.

**Quality** (QUALITY, U, Settings, `--quality=auto|low|medium|high|ultra`; saved since loop 2a;
loop 2b made Medium and Low real steps; loop G1 added **Auto**, the default, and **Ultra**,
`tiers.gd`):

| | Ultra | High | Medium | Low |
| --- | --- | --- | --- | --- |
| Auto picks it on (model id, `OS.get_model_name()`) | 15 Pro and newer: `iPhone16,x`, `iPhone17,1`–`4`, `iPhone18,x` and up | 11 to 15, SE 2 / 3, 16e (`iPhone12,x`–`15,x`, `17,5`); iPads, Macs, anything unknown | XS / XR (`iPhone11,x`) | 8 / X (`iPhone10,x`) |
| Pixel size (whole screen pixels per image pixel): the style's own scale (Sharp: the most that keep 480 lines), Low and Medium one coarser, then coarser until the image fits the budget | budget 1.6 MP: the iPhone 11 at 1 (1792×828), the Pro Max at 2 (1434×660) | budget 0.96 MP (the Pro Max's 1434×660): 2 on every iPhone, the iPhone 11 and SE included (896×414, 667×375). **Under Auto (loop G1b)** the iPhone 11 and the SE 2 / 3 draw Sharp at 1 (1792×828, 1334×750) with High's effects, and at 2 for the next launches after a session there struggled (the fallback, below) | one coarser, budget 0.5 MP (956×440 / 844×390 / 896×414) | as Medium |
| Sun shadows | **4096** map, everything over a metre tall | 2048 map, everything over a metre tall | 1024 map, buildings and trees only | off |
| Night glow | on | on | on | off |
| Rain streaks | all | all | 70% | 40% |
| Mirror reflections (steps per pixel) | **16** | 10 | 6 | off |
| Traffic (share of the usual, × the Traffic setting) | 100% | 100% | 80% | 55% |
| Pedestrians (most at once, × the Traffic setting's share) | 60 | 60 | 40 | 24 |
| Draw calls at the default view (river, iPhone 16 Pro Max, loop 2b) | as High | 124 | 118 | 99 |

Before loop 2b Medium's 0.85 render scale gave High's image on a 1170-line phone and Low's on a
1320-line one, and its shadow map was 2048 against High's 4096 over a 2 km slab. Before loop G1
High was the default and drew the iPhone 11's 828 lines at 1 (1792×828, 1.48 MP, the most pixels
of any phone); a settings file saved before G1 that says High loads as Auto, once (High was the
default then, not a choice). The **frame governor** and the **view rule** (loop G1, below) take
extras away when frames are missed and in wide views, never the pixel size or the shadow map.
Loop G1b: **Auto starts sharp, with a fallback** (section "Loop G1b" below): where High's budget
would make Sharp coarser than its own scale (only the iPhone 11 and the SE 2 / 3, and Mac windows
under 960 lines over 0.96 MP), Auto draws the style's own scale with High's effects (not Ultra's);
if a session there struggled (the governor's GPU extras down a minute and a tenth of the play, or
3 minutes in a row missing over 2 % of refreshes GPU-bound), the next launches draw the budget's
×2, and the sharp image comes back after 2 calm sessions, the wait doubling (to 16) each time it
struggles again on trial. The manual levels keep G1's rule (Wysoka ×2 on the iPhone 11, Ultra ×1).
Settings → Obraz's Auto button says what it draws: `auto · High ostry` (sharp), `auto · High ×2`
(the fallback), `auto · High` (where the budget doesn't bind); the overlay's last line
`High ×1 sharp` / `High ×2 fallback`; the BENCH card `Auto→High sharp (iPhone12,1)`.

## Loop 1 (polish, 2026-10-28)

What looked worst in the screenshots, fixed (details in the sections above):

- **The occlusion ghost** is a thin, light dither that shows the street at its own brightness
  (Landmarks: Occlusion ghost, with the before/after luma).
- **The river** is a slow lowland river: deeper and a little greyer, a low-contrast drift,
  rare small glints, a darker band beside a bridge by day; dark and calm at night with the
  lamps' columns carrying it (ponds share it). (Water, weather and sound.)
- **The Palm** stands where the laser scan found it; the scanned "tree" is gone (trees3d
  12,555 → 12,554 trees). **Varso 2** no longer floats (Floating parts). **The Palace clock**
  shows the time in Warsaw.
- **Roadworks** read at the default zoom; amber lamps blink at dusk and night. **Joke
  posters** on one advertising column in six. (Side jobs, the wallet and the city's chatter.)

Screenshots: `shots/loop1_*.png` (44: before/after pairs `*_before.png` / `*_after.png`, the
before images rendered from the v0.9 code and data; the ghost and the night river also on the
prebuilt path).

Cost (bench, same session, the v0.9 code and data run alongside from a copy, before →
after): Vulkan GPU 2.40 / 2.42 → 2.39 / 2.31 ms by day, 2.10 / 2.23 → 2.08 / 2.24 at night,
2.30 / 2.36 → 2.15 / 2.32 at night in the rain; Metal frame 3.65 → 3.64 ms by day, 3.66 →
3.73 at night, 3.60 → 3.64 in the rain; traffic, trams and people 0.79-0.87 ms either way,
side jobs + eggs 0.03 → 0.04 ms (the posters' passing check, ten more knockables). The Mac
ran uncapped this time (220-280 fps), not at the display's 120 Hz as in earlier sessions,
so these numbers don't line up with the v0.9 ones below (the same v0.9 code read Vulkan GPU
1.78-1.90 ms at the start of this session, still capped). Vertices: the city 6,070,773 →
6,069,970 (the floating bits left out, the clock hands now in the shader, one tree fewer);
the runtime props (`eggs.gd`, not in that count) +3,516 (bigger barriers and cones, their
halos, the 24 posters).

## Loop 2a: controls and settings (2026-10-28)

After the first play on an iPhone ("steering feels strange"; and a little less traffic, or an
option for it).

**Why the steering felt strange.** The stick points in screen space and the car steers towards
that direction in the world, but the Follow camera (the default) kept turning towards the car's
heading, so the world direction a held stick meant kept turning with the car. Measured with the
input replay (`tools/check_steering.gd -- --legacy`, the code before loop 2a): stick held to
the right at 50 km/h, the car turned 1151° in 10 s (3.2 circles, ~115°/s, the camera chasing
~50° behind) and never settled; held 15° off the nose it drifted 155° off in 8 s; pointed
straight back, 2.6 circles. The same inputs with the camera fixed settled in 0.3-1.8 s. Also
measured: a 4 g swerve at speed (full-lock radius 2.3 m at 20 km/h, 6.4 m at 50, 11.5 m at
78), no turning at all from a standstill (it needed 5 m/s for full lock), and walls that stopped
the car dead (8 % of the speed lost every frame of contact: a glancing hit at 93 km/h was down
to 11 km/h a second later, a head-on push stayed pinned for good).

**Three control schemes** (Settings → Controls, `--controls=`; `drive_controls.gd` maps the
stick, keys and pedals for the game and the replay test alike):

- **Point** (the default until 2026-11-04, one thumb): point where you want to go. The follow camera holds still
  while your finger is down, so a held direction stays put on screen and in the world; 0.6 s
  after you let go it eases round behind the car (it reaches it in ~3 s, at most ~64°/s; it was
  up to 116°/s). Gas by how far you push (a target speed; full from three quarters out);
  pointing well behind at speed brakes first, then turns; a big turn holds the speed until it is
  done. Keys: W A S D point in screen directions (like the helicopter), Space brakes.
- **Classic** (two thumbs; the default since 2026-11-04, F's call, settings.gd `DEFAULT_CONTROLS`; a save still on the old Point default moves to Classic once): drag left / right on the left side to steer (a strip, car-relative,
  a gentle curve near the middle), GAS bottom right and BRAKE / REVERSE beside it (a thumb can
  slide from one to the other); the camera turns with the car. Keys: A / D steer, W gas, S or
  Space brake.
- **Fixed camera**: Point with a camera that never turns (the v0.4 scheme). CAM / C switch
  between Point and Fixed; in Classic CAM turns the following on or off.

The helicopter keeps its own controls; since loop 2a the follow camera also waits while its
stick (or a key) is held, for the same reason.

**The car's feel** (`car.gd`, all schemes; numbers from `check_steering.gd`, before → after):

| | before | after |
| --- | --- | --- |
| Full-lock radius at 20 / 50 / 90 km/h | 2.3 / 6.4 / 11.5 m (at 78; 1.4 / 3.1 / 4.2 g) | 2.5 / 8.6 / 23.5 m (1.3 / 2.4 / 2.7 g) |
| Held stick 90° right at 50 km/h (Follow) | 3.2 circles in 10 s, never settles | within 5° in 1.2 s, 0° overshoot, stays |
| 45° / 15° off the nose (Follow) | 1.4 circles / 155° off after 8 s | settled in 0.7 / 0.4 s |
| Pointed straight back at 50 km/h (Follow) | 2.6 circles | brakes 0.4 s (to 17 km/h), turned round in 1.7 s, no overshoot |
| 90° turn from a standstill | 0.90 s circling on (Follow), 1.08 s (Fixed) | 1.00 s (Point), 0.87 s (Classic) |
| 90° turn from 50 / 90 km/h (Point, Fixed camera before) | 1.02 / 1.15 s, 10.6 / 18.4 m | 1.20 / 1.65 s, 11.0 / 26.4 m, 0° overshoot |
| Glancing wall hit at 93 km/h (30°): speed 1 s later | 11 km/h (12 %) | 86 km/h (92 %), slides 47 m along it in 2 s |
| Pushing head-on into a wall | pinned for good | Point follows the wall (0.4 s); Classic is turned out after 1.5 s |
| Into an inside corner, then pointing out | pinned 2 s | turned out after 1.5 s, drives away |
| Classic: steer, then let go | stops turning at once | stops 0.27 s later (input smoothing), 5° more |

How: the most it turns is ~2.3 rad/s when slow and 18 m/s² / speed + 0.35 rad/s at speed
(sharp when slow, calm when fast); it pivots a little from a standstill with the gas on (full
lock from 2 m/s); steering input smoothed over 0.08 s; point-to-steer turns at a rate set by
the heading error (6/s) with a touch of yaw damping, and never flip-flops when pointed straight
back. Walls: the part of the velocity going into a wall is taken off (Godot's floating
`move_and_slide` leaves it in), the rest is kept less a little scrape (1.2/s), a glancing hit
turns the nose along the wall (3 rad/s), a head-on one pushes it back a little; pointing into a
wall it touches, Point follows the wall the way the stick leans; pinned (touching something fixed,
the gas or brake on, under a metre of progress; nosing into the car ahead in a queue doesn't
count) for 1.5 s, the car is turned out of everything it touched and sent off at walking pace;
pinned again within 5 s, it is towed back onto the nearest lane on its level, facing the lane's
way ("Pomoc drogowa: wyciągnięci! · Towed free"). Point follows only fixed walls, not cars
(since the driving-feel loop it also goes round a car it has pushed into for 0.35 s).

**The view.** The default view is 80 m high (110 before): the 4 m car is ~58 px long side-on on
an iPhone's 1170 lines (43 before; ~3.2 mm on the glass instead of 2.3), and there is still
~80 m of road above the car, ~3 s at 90 km/h, plus the 25 % zoom-out at top speed. The view
leads by half a second of the car's velocity, smoothed over 0.7 s so a turn swings it round
gently, at most a fifth of the view (it was 0.6 s of the raw velocity, up to 22 m); the car's
place on screen moves at most 73 px/s with Point and 91 px/s with the Fixed camera in the
replay's turns at 80 m (up to 143 px/s before, at the 1.4× wider 110 m view). `−` / `+` and pinching still zoom (30-320 m; not saved).

**Settings** (the gear in the top left corner, Esc; `settings_panel.gd`): a dark card like the
mission panels, Polish over English, every control at least 44 pt (on a computer the window is
taken as a 390-pt-tall phone screen, so screenshots show the phone's sizes). The game pauses
under it (the radio plays on). Controls (with a line saying what the scheme does), Traffic,
Quality (also still on the performance overlay and U), Sound (Głośność / Volume, Radio, Efekty /
Effects: − and + in tenths or drag along the bar; zero mutes), and the performance overlay.
Saved in `user://settings.cfg` (`settings.gd`; beside the wallet's `save.cfg`, which
`wallet.gd` rewrites whole); `--nosave` neither reads nor writes it; command-line flags win
for that run and are not saved.

**Traffic** (Settings → Traffic, `--traffic=`; × Quality's share). Busy is the old level. Its
target (70 cars in the band round the view at 80 m) is more than the spawner can place there
(~44, the spacing rules), so the levels are set from the cars that really appear (bench route,
default view, day):

| | traffic density | cars on screen | driving | traffic + trams + people | pedestrians (most) |
| --- | --- | --- | --- | --- | --- |
| Pustawo · Almost empty | 0.10 | 5 | 14 | 0.28 ms | 27 |
| Mało · Low | 0.22 | 9 | 21 | 0.35 ms | 39 |
| Normalnie · Normal (default) | 0.38 | 15 | 32 | 0.42 ms | 48 |
| Tłoczno · Busy (before loop 2a) | 1.0 | 25 | 52 | 0.63 ms | 60 |

(Before loop 2a, at the 110 m view: 33-36 on screen, 71-77 driving, 0.76-0.86 ms.)

**Checks.** `godot --headless --path game --fixed-fps 60 --script res://tools/check_steering.gd`
(add `-- --legacy` for the numbers before loop 2a, `-- --verbose` for a line every 0.5 s,
`-- --only=NAME`): the input replay on a flat test ground with walls, through the game's own
mapping and camera code; it exits 1 on a held direction that circles, oscillates or doesn't
settle, a 90° turn that overshoots, or a car left pinned. `godot --headless --path game --script
res://tools/check_settings.gd`: the settings round trip, the defaults, and that `--nosave`
writes nothing (scratch files only).

Screenshots: `shots/loop2a_*.png` at 1920×1080 (`_1920`) and the iPhone's 2532×1170
(`_iphone`): the settings panel, each scheme's on-screen controls (`point`, `classic`,
`fixed`, the stick held), the default driving view before (110 m, Busy) and after
(`view_before` / `view_after`), and the four traffic levels on Marszałkowska 20 s after the
start (`traffic_empty|low|normal|busy`).

## Loop 2b: frame rate on the iPhone (2026-10-28)

The user's iPhone 16 Pro Max (iPhone17,2, A18 Pro, 2868×1320, so a 1434×660 pixel image at
High) showed 16 fps at the default view over the river (6,747 draw calls, 0.34 M triangles),
14 fps zoomed out (7,191 draw calls) and 13 fps from the helicopter (7,672): the frame grew
with the draw calls (~10 µs each), not the triangles. Those readings came from a game started
with Xcode's Run. Started on the phone with `xcrun devicectl` (no debugger), the same code ran
at the display's 120 Hz with 6,771 draw calls in the street views (64 fps, 1 % low 30, from the
helicopter), and 18.9 fps with Metal API validation switched on as Xcode's Run has it: the cost
per draw call is what Xcode adds, and 6,500 of those draw calls were the minimap. `tools/export_ios.sh` now switches validation and GPU frame capture off in
the Xcode scheme, and the frame has ~125–250 draw calls either way.

**Where a frame went (before, ranked).** Measured with the new `--probe` at five places (the
spawn, Marszałkowska, the Palace from the north-west, Most Poniatowskiego over the river,
Rondo Dmowskiego), by day, at night and at night in the rain, on the Mac (M4 Pro) at
2532×1170 (and the phone's three views at its 2868×1320), Metal for the frame and the counters
(the same counters the phone's overlay shows: they match its readings within a few per cent),
Vulkan for the GPU's passes (`--gpu-profile`):

| # | Cost | Before | Why |
| --- | --- | --- | --- |
| 1 | The minimap | 6,533–6,542 of 6,590–7,044 draw calls (the 2D pass), at every place and zoom; the Mac's main thread spent 2.5 ms a frame handing them over (0.75 without the minimap), the GPU 0.9–1.0 ms | every street, park and pond of the whole map drawn as its own polyline or polygon, every frame, under a `clip_children` clip |
| 2 | The sun's shadow | shadow pass 126–347 draw calls, 2–4 × the main pass; GPU 0.5–1.0 ms by day, 2.35 ms zoomed out; a 4096 map at ~0.49 m a texel | Godot ignores the light's max distance for an orthographic camera and shadows its whole depth: the far plane was 1,500 m past the view, so the shadow map covered a sphere ~2 km across and drew every caster in it |
| 3 | The main pass's objects | 47–175 draw calls; GPU 1.1–1.8 ms (2.6 zoomed out) | the Mobile renderer has no automatic instancing: every node is a draw call. 128 m tiles × 3 meshes (ground, walls, LoD2 buildings), 256 m tiles × 11 instanced kinds, the player's car as 18 boxes with 18 materials |
| 4 | Pedestrians on bridge decks | 1.0 ms of script at the river (0.08 elsewhere) | the deck solver asked per walker per frame |
| 5 | The other scripts | 0.6–0.9 ms (traffic 0.24, trams 0.09, people 0.09, HUD and minimap 0.12–0.18, the game loop 0.1, the rest under 0.05) | |
| 6 | Transparent passes (the post pass, glow, halos) | GPU 0.18 ms by day, 0.25–0.46 at night, 0.42–0.62 in the rain | at the pixel image's size already |
| 7 | Physics, tonemap, memory | physics 0.13–0.17 ms; tonemap 0.04 ms; 221 MB static, 330–364 MB video | |

Full-screen passes at screen resolution are the scale-up container (one textured quad) and the
VHS overlay when it is on: both cheap next to the above, and VHS's scanlines are meant to be
screen pixels, so they stay.

**What changed, per cost.**

1. **Minimap** (`hud.gd`): the streets, parks, water, the map's edge and the Palace's dot are
   built once into one 2D mesh, the same triangles `draw_polyline` / `draw_colored_polygon`
   made, drawn with one call; a four-line shader cuts it to the circle (no `clip_children`).
   It looks the same (`shots/` pairs: the only differences are the city behind it). 6,540 → 1
   draw call. (A one-time texture was tried first: it smeared the lines when the map turns.)
2. **Shadow** (`main.gd` `_camera_far`): the camera's far plane now ends 130 m past the lowest
   ground the view can show (the river below the city, the slab's walls), and its depth is
   chosen so the shadow's bounding sphere keeps one size while the view widens with speed (or
   the shadows' pixel edges would crawl): it changes only with the zoom. The shadow map is
   2048 on High (was 4096) and 1024 on Medium (was 2048): over the smaller sphere 2048 gives
   0.37 m texels, finer than 4096 gave (0.49 m). Things under a metre tall (benches, bins, bike
   racks) cast no shadow (a few texels at most); on Medium only buildings and trees do. Shadow
   pass at the spawn 186 → 35 draw calls, zoomed out 347 → 60; GPU 0.55 → 0.14 ms, zoomed out
   2.35 → 0.26 ms. The look: the same shadows with slightly finer pixel edges (the day pairs
   differ in 4–6 % of pixels, mostly along shadow edges).
3. **Objects** (`chunked_surface.gd`, `map_builder.gd`, `car.gd`): city tiles of 256 m (were
   128), each tile's LoD2 buildings in the same mesh as its other walls (one draw call, not
   two), instanced things in 512 m tiles (were 256): one MultiMesh is one draw call and the
   triangles of a bigger tile cost the phone nothing it notices. The player's car is one mesh
   with vertex colours plus one per lamp pair (3 draw calls, was 18; same colours and shading).
   Benches, bins and bike racks hide in a view wider than 170 m, where a bin is under two
   pixels (`fine_detail` group). Vertices unchanged: 6,055,540.
4. **Pedestrians** (`pedestrians.gd`): a deck footway's heights are sampled every 4 m once and
   interpolated: 1.0 → 0.08 ms at the river.
5. **The overlay** is cheaper (twice a second, no per-frame clock reads of its own) and shows
   what matters (the main thread's split and draw calls by pass); see Water, weather and sound.

Not changed, measured and kept: the post pass (outlines, reflections, rain) and glow run at
the pixel image's size already; the occlusion ghost, the river, the landmarks and the night
lights are untouched.

**Before → after** (the same places, Mac M4 Pro at 2532×1170, `--probe` medians over 1,500
frames, Metal frame and counters, Vulkan GPU passes; the night has no sun shadow):

| Place | Time | Draw calls, 3D + shadow + 2D: before → after | Metal frame (ms) | Vulkan GPU (ms): total (shadows / opaque / 2D) |
| --- | --- | --- | --- | --- |
| Spawn | day | 6,847 (92 + 222 + 6,533) → 145 (53 + 35 + 57) | 3.52 → 1.86 | 3.15 (0.73 / 1.30 / 0.98) → 1.21 (0.21 / 0.60 / 0.16) |
| Spawn | night | 6,637 (104 + 0 + 6,533) → 121 (64 + 0 + 57) | 3.55 → 2.28 | 2.68 (0.00 / 1.52 / 1.01) → 1.06 (0.00 / 0.75 / 0.17) |
| Spawn | night, rain | 6,637 (104 + 0 + 6,533) → 122 (64 + 0 + 58) | 3.50 → 1.96 | 3.13 (0.00 / 1.42 / 0.98) → 1.23 (0.00 / 0.71 / 0.16) |
| Marszałkowska | day | 6,789 (87 + 167 + 6,535) → 140 (48 + 33 + 59) | 3.49 → 1.54 | 3.37 (1.00 / 1.12 / 0.91) → 1.21 (0.24 / 0.64 / 0.17) |
| Marszałkowska | night | 6,634 (99 + 0 + 6,535) → 117 (58 + 0 + 58) | 3.58 → 2.13 | 3.18 (0.00 / 1.42 / 1.05) → 1.26 (0.00 / 0.80 / 0.20) |
| Marszałkowska | night, rain | 6,634 (99 + 0 + 6,535) → 118 (58 + 0 + 59) | 3.44 → 1.71 | 3.09 (0.00 / 1.56 / 1.01) → 1.32 (0.00 / 0.68 / 0.16) |
| Palace (NW) | day | 6,740 (81 + 126 + 6,533) → 158 (62 + 39 + 57) | 3.39 → 1.50 | 3.18 (0.48 / 1.40 / 0.99) → 1.24 (0.19 / 0.63 / 0.16) |
| Palace (NW) | night | 6,624 (91 + 0 + 6,533) → 131 (74 + 0 + 57) | 3.33 → 1.49 | 3.44 (0.00 / 1.68 / 0.98) → 1.03 (0.00 / 0.68 / 0.15) |
| Palace (NW) | night, rain | 6,624 (91 + 0 + 6,533) → 131 (74 + 0 + 57) | 3.33 → 1.54 | 3.27 (0.00 / 1.50 / 0.97) → 1.33 (0.00 / 0.70 / 0.15) |
| Most Poniatowskiego | day | 6,765 (47 + 183 + 6,535) → 119 (35 + 24 + 59) | 4.36 → 1.94 | 3.42 (0.56 / 1.49 / 0.86) → 1.24 (0.15 / 0.65 / 0.13) |
| Most Poniatowskiego | night | 6,590 (55 + 0 + 6,535) → 101 (43 + 0 + 58) | 4.28 → 1.85 | 3.69 (0.00 / 1.84 / 0.91) → 1.21 (0.00 / 0.75 / 0.13) |
| Most Poniatowskiego | night, rain | 6,590 (55 + 0 + 6,535) → 102 (43 + 0 + 59) | 4.25 → 1.52 | 3.40 (0.00 / 1.77 / 0.89) → 1.33 (0.00 / 0.76 / 0.12) |
| Rondo Dmowskiego | day | 6,848 (96 + 217 + 6,535) → 163 (57 + 47 + 59) | 3.85 → 2.67 | 3.54 (0.69 / 1.38 / 0.99) → 1.22 (0.22 / 0.59 / 0.14) |
| Rondo Dmowskiego | night | 6,651 (115 + 0 + 6,536) → 132 (73 + 0 + 59) | 3.74 → 1.96 | 3.31 (0.00 / 1.64 / 1.05) → 1.06 (0.00 / 0.78 / 0.18) |
| Rondo Dmowskiego | night, rain | 6,650 (115 + 0 + 6,535) → 133 (73 + 0 + 59) | 3.61 → 2.35 | 3.47 (0.00 / 1.61 / 1.00) → 1.25 (0.00 / 0.72 / 0.15) |

The Mac is not the target: its uncapped frame halves, but the phone pays per draw call.

**On the phone** (iPhone 16 Pro Max, started with `devicectl`, no debugger; `--probe` for 10 s
after a short settle, Quality High, traffic Normal, Classic, day; "before" = the code before
this round with only the bench added; the last column with Metal API validation on, as Xcode's
Run has it, `MTL_DEBUG_LAYER=1`):

| View | Draw calls (3D + shadow + 2D) before → after | Before (no debugger) | After | Before / after with Metal validation |
| --- | --- | --- | --- | --- |
| Default, 80 m, over the river | 6,771 (47 + 182 + 6,542) → 124 (35 + 24 + 65) | 120 fps (the display's limit) | 60 fps (the cap), 1 % low 57.4, worst 17.5 ms; main thread: process 3.3, physics 0.6, draw 2.0 ms | 18.9 fps (53 ms, 47.6 of it handing over draw calls) / 60 fps, 1 % low 58.3 |
| Zoomed out, 220 m | 7,020 (131 + 347 + 6,542) → 191 (66 + 60 + 65) | 120 fps | 60 fps, 1 % low 57.9, worst 17.3 ms | |
| Helicopter, 150 m | 7,045 (175 + 334 + 6,536) → 245 (100 + 86 + 59) | 64 fps, 1 % low 29.7, 28 % of frames over 16.7 ms | 60 fps, 1 % low 57.9, worst 17.3 ms | |
| `--bench` route | never finished (it sat on the title screen: the launcher ate the `--`) | | 60 fps, 1 % low 57.5, 154 draw calls, ends by a 30 s cap | |
| TEST · BENCH, one minute | | | 60 fps, 1 % low 57.0, worst 17.9 ms, 60 in every 10 s, 168 draw calls | |

Run order on the phone: after (an earlier build of this round) default, zoomed, helicopter, the
frame-rate cap tests, `--bench`, Medium, Low; before default, zoomed, helicopter, default with
validation; then the final build: default, zoomed, helicopter, default with validation, the
one-minute BENCH. No run lasted over a minute; the BENCH's fps per 10 s stayed at 60 (no
throttling seen). Medium and Low: 118 and 99 draw calls, image 956×440, 60 fps.

So the user's 16 fps (from Xcode) was 6,800 draw calls × Xcode's Metal validation; the old
build started from the home screen held 120 Hz in the street views and dropped to 30 in the
helicopter's. With ~125–250 draw calls the game holds 60 either way.

**Frame rate** (Settings → Klatki na sekundę · Frame rate, `settings.gd` `fps`, `--fps=`): 60 by
default, 30 as a battery saver. The iPhone 16 Pro Max has a 120 Hz display; the game used to
ask for it (Godot's `display/window/ios/allow_high_refresh_rate` defaults to on) and ran its
frames twice as often, warm. `project.godot` now turns that off, so iOS runs it at 60 Hz, and the
60 setting leaves the pacing to the display: on the phone `Engine.max_fps = 60` on top of it
left 7.8 % of frames slightly late against 4.6 % without it. 30 sets `Engine.max_fps = 30`
(measured: 30.0 fps, 1 % low 27.6, worst 36 ms). On the Mac the setting is `Engine.max_fps`.
`--bench` and `--probe` run uncapped.

**TEST · BENCH** (the performance overlay, Settings → TEST, `--bench-button`): the car rides
the bench route's ghost driver from the spawn at the default view for 5 s to settle and 55 s
measured, at the current quality, traffic, time, weather and frame-rate cap; nothing else
starts on the way (no side job), the wallet is put back as it was and not saved, the car goes
back where it was. A countdown runs in the toast line; opening Settings cancels it. Then a card
(Polish over English, 44 pt buttons) shows the result, KOPIUJ · COPY puts it on the clipboard,
ZAMKNIJ · CLOSE hides it, and it is written to `user://bench_result.txt` too (the app's
Documents folder on the iPhone). The card from the phone (`bench.gd`):

```
NOCNA WARSZAWA bench (loop 2b) · BENCH button · 2026-10-28 14:52:02
device iPhone17,2 · iOS 27.0.1 · Apple A18 Pro GPU (Apple9) (metal, mobile) · Apple A18 Pro
screen 2868x1320 @ 120 Hz · image 1434x660 · view 80 m · quality High · traffic Normal · Day · Clear · cap 60 fps · Classic
thermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s
fps 60.0 avg · 1% low 57.0 · worst frame 17.9 ms · 6.3% of frames over 16.7 ms · 3300 frames in 55 s
fps per 10 s: 60 60 60 60 60 60
frame 16.67 ms · main thread: process 3.96, physics 0.49, draw 11.55 · 3D view: render CPU 0.58, GPU n/a (Metal)
draw calls 168 · objects 796 · triangles 0.39 M (all passes, as the overlay counts them)
main pass: 46 draws, 46 objects, 0.19 M tris · shadow pass: 41 draws, 41 objects, 0.13 M tris · 2D: 82 draws
scripts 3.77 ms: traffic 1.53 · traffic bodies 0.14 · trams 0.47 · people 0.36 · rivals 0.06 · jobs+eggs 0.15 · jobs physics 0.00 · sound 0.09 · hud+minimap 0.39 · bubbles 0.05 · dialogue 0.00 · weather+time 0.00 · car physics 0.14 · heli 0.00 · game loop 0.38
cars on screen 33 · driving 51 · people 48
memory: static 114 MB · video 335 MB (textures 24, buffers 155) · 3 pipeline compilations
```

The device model is `OS.get_model_name()`; Godot 4.7 has no
thermal API, hence the fps per 10 s. GPU time is n/a on Metal; with the display at 60 Hz the
main thread waits for it inside "draw", so a big "draw" share (11.6 ms above) is waiting, not
work: process + physics is the CPU's work. A frame counts as "over" when it is more than 0.5 ms past the budget.

**Expected to matter more on the phone than on the Mac.** Draw calls above all: the Mac hands
over 6,800 draw calls in ~2.5 ms, the phone under Xcode took ~60 ms, and even without the
debugger every call costs the phone's CPU several times the Mac's; the per-call savings (the
minimap, the shadow's casters, bigger tiles, the car) are what the phone feels. The shadow map
(4096 → 2048, a quarter of the memory traffic for its depth every frame) matters more on a
tile-based phone GPU that writes it to memory than on the Mac's. The 120 → 60 Hz cap halves the
phone's work per second; the Mac has no such thing to save. The script savings (the deck
pedestrians) count about 4–5× on the phone: GPU-less GDScript time measured 0.6–0.9 ms on the
Mac and 3.2–4.6 ms on the phone at 60 Hz, where iOS runs the CPU at lower clocks.

**The parked car** (`car.gd` `parked`): while the player flies, and on the title screen, the
game parks the car with the brake on, and a held brake at a standstill reverses, so the parked
car backed ~40 m away into a wall and was "turned out of the wall" every 1.5 s for the whole
flight (99 lines in `--mission=1 --heli --autopilot --fixed-fps 60 --quit-after 12000`). A car
the game has parked now holds still and never counts as pinned; a player holding BRAKE to
reverse still does. The log is clean (0 lines) and `check_steering.gd` passes.

**Known issues.** The device log starts with `ERROR: Mouse is not supported by this display
server` (display_server.cpp:536): it comes from the engine before any game script runs (no
script asks for the mouse, and switching touch-from-mouse emulation off on mobile didn't stop
it); harmless. The phone's GPU time can't be read (Metal), and at 60 Hz the main thread waits
for the display, so the phone's headroom under 16.7 ms isn't visible (a build that allows
120 Hz would show it as fps over 60; the old build managed 64 fps from the helicopter, the new
one's GPU work there is a quarter of the old on the Mac). The Mac's worst single frame in the
bench reads 17–20 ms (9–20 before) while the averages halved: one-off spikes, probably
first-sight pipeline compiles. With the 60 cap on the Mac's 120 Hz display (`Engine.max_fps`)
~20 % of frames come a little late; on the iPhone the display paces it.

Screenshots: `shots/loop2b_*.png` at 2532×1170: before/after pairs at High (`_before` from the
code before this round) at `spawn`, `marszalkowska`, `palace`, `river`, `rondo`, `_day` and
`_night`; `quality_high|medium|low` (with the overlay); `bench_card` (the result card on the
Mac).

## Loop 10a: the river is off-limits (2026-10-28)

After the user's play on the iPhone: "the car can drive on water, why so" (the hatchback at
0 km/h in the middle of the Vistula, and crossing it at 91 km/h). Over the river the terrain is
the water's flat surface, so a car that got onto it drove anywhere on it at full speed.

**How it got there, measured** (`game/tools/check_water.gd`, the whole map, before → after):

| | before | after |
| --- | --- | --- |
| The water's edge a car drives through at ground level (every 2 m round every water body, the car's box driven at it from the land, straight and 40° either side) | 807 m open in 45 places | 0 |
| ... under or beside a bridge: the bake leaves the shore wall open within 6 m of any deck, so from the boulevard under a bridge the car rolled into the river (Most Świętokrzyski west 15 m and 8 m by the map's rim; the railway bridge 32 m west, 35 m east and 65 m round the pond under it; Most Poniatowskiego 12 m west, 43 m east) | 9 places, 209 m | 0 |
| ... fountains (no edge at all) | 35 of 40, 586 m | 0 |
| ... a road ending at a canal (1343, 763), a seam between two baked runs (1140, 105) | 8 m, 4 m | 0 |
| The real car (`car.gd`) at 91 km/h flat out at the edge every 10 m, after 1.5 s | 11 of 631 in the river (all at bridges; no wall was tunnelled through) | 0 of 631 |
| Off a bridge deck's side or end onto the water (1,353 probes) | 0 | 0 |
| Helicopter: landing to take the car back allowed over the water (every 20 m; only a roof stopped it) | at 1,251 of 1,256 points | 0 (refused at all 1,256; allowed on the 39 deck points over it) |
| The car's free spot next to a landed helicopter or a tow, round the water's edge | in the water for 1,252 of 2,478 (and mid-river: the spot itself) | 0 |
| Lane-graph lanes / tram tracks at ground level in the water | 0 / 0 (1 lane point at Świętokrzyski's end past the edge walls) | the same |
| Footways people walk into the water | 10 footways (24 points; ponds, fountains, a beach path) | 0 (5 end a metre short of it, 9 nobody walks) |
| Anything that took the car out of the water | nothing | the tow, from every point (0 of 634 tows off a lane or wet) |

So the user's car most likely came down with the helicopter onto the river (the car is put next
to it), or rolled in under a bridge from the boulevard, and then drove the river's flat surface.

**What changed.**

- **The edge** (`map_builder.gd` `_build_shore_stone`, `_build_shore`): a low granite edge
  (0.45 m over the ground, 0.5 m wide, on the water's side of the line) round the river, the
  ponds and the 40 fountains, 9.4 km, laid on the ground like the kerbs: in the ground's mesh,
  so no new draw call and no shadow. Its collider stands on the line, 3 m up, under any deck
  above it, in 2 m pieces with the ground's height at each end. Along the bake's `shore` runs
  plus the stretches the bake left open by bridges wherever the deck is at least 3.2 m up (under
  all four bridges and beside them), the canal's slipway and the seam. The map's rim stays open
  (the edge walls close it).
- **The water test** (`map_builder.shore_distance`, `in_water`): the surface map's shore
  distance (water.bin's R channel), kept on the CPU and stored zstd-packed in `city.scn`, read
  bilinearly; a vehicle is in the water 2.5 m past the edge (so a car stopped by the stone, its
  centre a metre or two inland, never counts) and down at the water's level (a bridge deck
  over the river is not the water). One call per physics frame for the player's car: 0.8 µs on
  the Mac.
- **In the water** (`car.gd`): the car splashes once (`splashed`), takes no gas or steering,
  loses speed at 4/s (from 91 km/h it stops within ~6 m), settles 0.45 m nose first and bobs.
  A car with its collision off (the testing autopilots, the bench's ghost) or parked never
  splashes.
- **The splash** (`splash.gd`): 56 droplets thrown up and forward and a ring of 22 foam pieces
  spreading on the water, 1.3 s, boxes in one MultiMesh with the actors' material (no new
  shader; one draw call while it plays, none after, no shadow); the sound (`sfx.gd` `splash`)
  is the hard knock pitched down and a 0.9 s wash of the rain bed's noise: no new file; a buzz.
- **The tow** (`main.gd` `_tow_out_of_water`): 1.0 s after the splash the car is put on the
  nearest lane on the level it came from (where it last stood on dry land or a deck), else the
  lane nearest to the nearest dry land, else the nearest junction; on the free spot there, never
  in the water. A toast from the tow crew, Polish over English (`dialogue.json` `water_tow`,
  `river` / `pond`; the HUD's toast now takes an English gloss under its line): "Wisła nie jest
  drogą krajową." / "The Vistula is not a national road." No money is taken and nothing
  fails: a rescue, a delivery or a race carries on (`splash` in `tools/verify.sh`: a kebab
  delivery running, towed after 1.00 s to a lane 51 m away, the job still on, the wallet
  unchanged).
- **The helicopter** won't come down to give the car back over the water ("Tu nie wylądujesz:
  to woda. Szukaj brzegu." / "No landing on the water: find the bank."); it still flies over
  it, and lands on a bridge deck over it. The car's free spot next to a landed helicopter or a
  tow (`_free_car_spot`) is on the level of the spot (it was the top deck over each candidate:
  a tow under a bridge put the car up on the bridge) and never in the water; the stuck tow's
  "its level" is now the ground for a car on the ground (any lane on the terrain) or within 4 m
  on a deck.
- **People** (`pedestrians.gd`): a footway that runs into the water at an end stops a metre
  short of it (people turn back there); one that crosses water in between isn't walked. Worked
  out the first time someone could walk it (every 0.5 m).

**Checks.** `godot --headless --path game --script res://tools/check_water.gd` (~17 s; `--
--prebuilt` checks the exported game's `city.scn`, its colliders and stored water map, ~10 s;
`--verbose`, `--list=OUT.txt` for every gap sample, `--debug=X,Z` for every probe step near a
point) prints the five parts above and `check_water: OK`; both are steps in `tools/verify.sh`
(`water`, `water-prebuilt`), with the game run `splash` (`--drive-into-water=1015,-85
--kebab=0`: into the river from the boulevard by Most Poniatowskiego; PASS needs the tow within
2 s, on dry land by a lane, the job still on). Godot's `cast_motion` misses some of the concave
collision shape's thin walls, so the probe steps the box 0.5 m at a time and tests for overlap.

**Cost** (README's commands; Mac): the bench route (day, medians of 3) 8.33 → 8.33 ms a frame
(120 Hz display cap), scripts 1.66 → 1.66 ms, draw calls 134 → 134 (the bench's ghost car has
its collision off, so the water test doesn't run there); the probe at the four views (Metal,
2868×1320): spawn 152 → 153, default view over the river 124 → 124, zoomed out 189 → 191 (the
3D and shadow passes equal; the HUD's 2D pass 63 → 65), helicopter 245 → 245; car physics at
the river 0.05 → 0.05 ms; main-pass triangles at the river 0.19 → 0.20 M; the city's meshes
3,697,284 → 3,742,512 vertices (+1.2 %); `city.scn` 35.9 → 36.3 MB.

**Known issues.** The splash and the tow were judged on the Mac (screenshots, logs); how they
feel on the phone, and whether the splash reads at the default view, is the user's to say (the
sound was not heard: headless runs have no audio). The stone is the same granite edge
everywhere, the Praga beach included. A car that rolls in at a few km/h can stop with its
centre less than 2.5 m past the edge (the shallow first metres) and sit there until it drives
out; the stone makes that hard to reach. The minimap is unchanged (no lane is on the water).

Screenshots: `shots/loop10a_*.png` at 2532×1170: the shore at Most Poniatowskiego's west
boulevard (`poni`), the Praga beach by the stadium (`beach`) and Most Świętokrzyski (`swieto`),
`_day`, `_night` and `_day_prebuilt`, with `_before_*_day` from the code before this loop; the
splash (`splash`, `splash_night_prebuilt`), the tow's toast (`tow_toast`) and a fountain pool's
new edge (`fountains_day`, at -1075, 170).

**On the iPhone** (16 Pro Max, launched with `devicectl`, prebuilt city): the water test from
the boulevard splashed at 62 km/h and was towed 1.01 s later onto a lane 51 m away, dry, the
kebab job still on; standing on that boulevard (`--probe --at=1015,-85 --heading=45`): 60 fps
(the cap), 1 % low 55.3, worst frame 18.6 ms, 141 draw calls, car physics 0.15 ms.

## Loop 3a: roads I, the check and the bake (2026-10-28)

After the user's play on the iPhone: "I see huge problems with the estakady and roads in some
places". Their screenshot was Most Poniatowskiego's east end: Wybrzeże Szczecińskie passed
under the deck with 1.3 m to spare. docs/DEMO.md section 4 lists the classes of defect and their
causes (R1-R9); this loop built the whole-map check and fixed the causes that live in the bakes
(the builder's side, R5-R7 and buildings under decks, is loop 3b).

**The check** (`tools/check_roads.py`, standard library, ~4 s for the whole map): rules C1-C10
of DEMO.md 4.5, mirroring the game's height rules (the terrain's triangles and the approaches'
fills, `deck_height`, `drive_height`, the tunnels, lane_graph.gd's lane heights). Each finding
prints with map coordinates and its `--at=`; allowed ones are listed with a reason and a source
in `tools/check_roads_allow.json`; it writes `shots/check_roads.json` and
`shots/check_roads.png` (the findings over the orthophoto) and exits 1 on a finding not
allowed (3 when the only ones left are in the `--later` rules). `tools/verify.sh` step `roads`:
FAIL on C1-C3 and C6-C8, WARN on C4, C5, C9, C10 until loop 3b; it prints the counts.

| Rule (DEMO.md 4.5) | Today's map before | After | |
| --- | --- | --- | --- |
| C1 grade (> 12 % over 6 m, service 20 %) | 85 roads | 32, all allowed | Oboźna (the escarpment, real); 5 pits at junctions; 21 minor service ways |
| C2 joints (> 0.15 m at a shared vertex) | 0 | 0 | |
| C3 clearance under a deck (< 4.7 m; footways < 2.5 m) | 249 samples in 17 places | 54 in 7, all allowed | footbridges mapped schematically (Centralna, the science centre's roof), a footway along the viaduct ramp, the WKD cutting |
| C4 piers on a road, tram or rail | 31 of 161 piers | 31 of 171 | loop 3b (R5) |
| C5 roads and lanes through solids | 46 | 50 | loop 3b (the Arkada and the viaduct's LoD2 arcades, palace courtyards' service roads) |
| C6 deck ends in the air (> 1 m) | 4 (+6 at the rim) | 0 (+5 at the rim) | |
| C7 drivable tunnels and cuttings dropped | 9 | 0 | |
| C8 lane steps (> 0.5 m in 4 m) / edges meeting apart (> 0.2 m) | 19 edges / 12 nodes | 5 / 0, all allowed | Złota, Salezego, Oboźna |
| C9 buildings through a deck | 58 | 57 | loop 3b (mapped pillars under the Jana Pawła II viaduct, the Poniatowski viaduct's LoD2 arcades) |
| C10 landmark colliders by a lane | 1 | 1 | loop 3b (R7: a Poniatowski tower 0.3 m from lane 2) |

**What changed in the bake** (`tools/bake_roads.py`, `tools/bake_osm.py`):

- **Structure chains (R1).** A bridge is solved together with the ways that belong to it: the
  non-bridge ways between two bridge ways within 150 m (the abutments), embankments
  (`embankment=yes`, or 2 m above the terrain 15-25 m to both sides over most of the way: the
  railway across Powiśle) and the ways onto a bridge whose terrain within 40 m is steeper than
  12 % (the 10 m grid blurs the abutment's wall into a slope). Each family (rails, roads, then
  tram tracks and footways) is one graph of nodes every 6 m, solved by projected
  over-relaxation: smooth, never under the terrain, pinned only where a structure meets an
  ordinary way, the approaches pulled onto their terrain beyond 30 m from a bridge. Most
  Poniatowskiego's deck now runs at the abutments' level, -4.6 m at the west end to -5.7 m at the
  east (it dipped to -13.5 m at the ends), the viaduct climbs evenly to the escarpment, the
  railway runs on its embankment at -5 m over Kruczkowskiego and Solec. 26 bridge roads, 24
  approach roads, 39 rail ways.
- **Approaches are fills, not decks.** A structure way that is not a bridge corrects the ground
  under its corridor (`fills` in `centrum.json`: 80 pieces): `map_builder.terrain_height` is the
  higher of the terrain grid and a fill there, so the road, its kerbs, markings, carriageway
  areas, the lanes and the car all sit on the solved profile, and the bridges' decks meet them
  exactly. Where a fill stands above the grid (the blur at an abutment) a plain concrete face
  runs down each side (loop 3b turns these into retaining walls).
- **Pits.** The same fills bridge narrow pits of the bare-earth grid a street crosses at grade
  (underground stairwells, garage and construction pits): each road's terrain profile is closed
  over 20 m and filled where it stands 0.4 m or more above the grid, except where another way
  enters (98 stretches).
- **Hard clearance (R3).** 5 m over roads, rails and trams, 7.5 m over the river, 2.6 m for a
  footbridge over a footway, as lower bounds the solver never crosses; where one can't be met
  within 12 % of a pin the road under it dips (at most 2 m, 8 % ramps: written as `dips` for
  loop 3b to lower the ground; none was needed on today's map) and anything more fails the bake
  with the list of places. Ways in a cutting (`layer` < 0, the WKD
  by Centralna) are skipped and logged; footbridges and tram tracks that fall short are logged
  (C3 judges them).
- **Tunnels (R4).** `tunnel=yes` drivable ways are kept as tunnel pieces (`tunnels` in
  `centrum.json`: `pieces`, the `roads` with their `tn`, and the `portals` where a tunnel meets
  open road): 6 m under the terrain, ramps of at most 8 % from the portals. The Wisłostrada
  tunnel (both carriageways from the portal at 637, -554 to the map's north edge), the link under
  Most Poniatowskiego's west abutment and a short tunnel on Warecka. Ways below ground that are
  no tunnel (`layer` < 0: cuttings) are ordinary roads now. The game doesn't draw or drive the
  tunnels yet (loop 3b): their lane-graph edges have their heights but stay out of the
  adjacency, routing, spawning and snapping (`lane_graph.gd` `TUNNELS_DRIVEN`), so the trench at
  the portal is still a dead end, now marked.
- **Lanes know their deck (R8).** Every lane-graph edge on a bridge carries its deck group
  (`dk`), in a tunnel its tunnel (`tn`); `lane_graph.gd` takes its heights from that piece only
  (`surface`), never "the highest deck over the point"; the side jobs' road height uses it too.
  The lane height's last 8 m knot is now at the edge's end (edges met a few tenths apart on
  slopes).
- **Garage ramps (R9).** A service way that dives into a garage (from its end that meets a road,
  the terrain falls 2 m within 30 m, somewhere steeper than 20 %) ends at the ramp's top; a
  garage door is written there (`garages`: x, z and the way in, 27 of them) for loop 3b.
- **R2 hook.** `bake_roads.SurfaceModel` reads the 0.5 m surface model and 1 m terrain (DEMO.md
  4.4) as ASCII grids once `data/raw/demo/MANIFEST.md` is there; until then the chain solver
  works alone (the plan's fallback). The corridors now arriving are GeoTIFF, which it doesn't
  read yet.

**Testing aids.** `--debug-roads` draws the decks' corridors at their height (orange roads,
yellow footways, red tracks), the approaches (green), the tunnels (magenta), every lane at the
height traffic uses (blue) and the piers (cyan boxes) round the car, with the Debug Draw add-on
(`game/addons/debug_draw`, HardPixel, MIT; CREDITS.md); `tools/road_spots.txt` lists the road
render spots and `tools/shots.sh --set=roads [--game=DIR] [--tag=...]` renders them (frame 90,
`--no-traffic --fixed --size=70`). `NW_DECK_DEBUG=X,Z,R` makes the bake print the solver's nodes
(height / terrain / lower bound) near a point.

**Cost** (Mac, README's commands, the code before this loop run alongside from a copy). Other
agents' Godot runs overlapped the bench, so its frame times spread 1.6-7 ms on both sides and
say nothing; the counts do. The probe (Metal, 2868×1320), draw calls before → after: spawn 151 →
154 (3D 53 → 53, shadow 35 → 35, the HUD's 2D pass 63 → 66), the default view over the river
126 → 126, zoomed out 191 → 190, the helicopter 245 → 242, Most Poniatowskiego's east end 126 →
126; main-pass triangles unchanged (0.25 / 0.19 / 0.36 → 0.37 / 0.31 M). Scripts on the bench
route (medians of 3, interleaved): 0.67 → 0.67 ms by day, 0.73 → 0.60 at night, 0.68 → 0.62 in
the rain at night (lane heights are still sampled once per edge). Vertices 6,115,198 →
6,144,280 (+0.5 %; meshes 3,742,512 → 3,771,594: the approaches' side faces and the new deck
slabs). `centrum.json` 4.96 → 5.04 MB, `city.scn` 36.3 → 36.5 MB. The runtime city build 7.0 →
7.8 s (`terrain_height` looks the fills up for every draped vertex); the prebuilt city loads in
0.84 s as before.

**Known issues** (BACKLOG "From loop 3a"): decks still too low where something mapped stands
under them (C9: the Jana Pawła II viaduct's pillars, the Poniatowski viaduct's arcades), which
the surface model (R2, arriving as GeoTIFF) or the pillars as lower bounds would fix; the
approaches' sides are plain faces until loop 3b's walls; tunnels and garage doors are data only;
21 minor service ways and 5 junction pits keep a steep bit of the 10 m grid (allowed).

Screenshots: `shots/loop3a/*_before_2532x1170.png` and `*_after_2532x1170.png` at the eight
road spots (`tools/road_spots.txt`), `poniatowski_{west,east}_{before,after}_prebuilt_*` on
the prebuilt path, `poniatowski_east_debug_roads_*` (`--debug-roads`);
`shots/check_roads_baseline.png` and `shots/check_roads.png` (the findings over the orthophoto,
before and after).

## Loop 2e: the HUD at phone size (2026-10-28)

Loop 2a found that, outside the settings panel, the HUD was sized in 720-line units: on the
user's iPhone 16 Pro Max its top buttons were 27 pt tall and its text 9 pt (24 pt and 8 pt on a
6.1" phone; Apple's smallest comfortable tap is 44 pt), and the top row held TIME, RADIO, VHS,
RAIN, HELI, STYLE, CAM, `<` `>` `−` `+` and a RESCUE CALLS card at the start.

**In points.** `screen_points.gd` gives the screen in points (3 px each on these iPhones) and
its safe area (the Dynamic Island or notch, the rounded corners, the home indicator). On a
computer a window the size of a known iPhone gets that phone's points and insets (2868×1320 is
the Pro Max: 956×440 pt, 62 pt each side, 21 at the bottom; 2532×1170 the 6.1": 844×390 pt,
47 and 21); any other window is taken as a phone 390 pt tall with no insets, or 667 pt wide when it is
narrower than that (a 4:3 window); the iPads the store screenshots use (2752×2064, 2732×2048,
2420×1668, 2360×1640) are known at 2 px a point with 20 pt at the bottom. iOS insets both
sides alike in landscape, so the layout holds turned either way. Every tappable control is at
least 44 pt; the text is on one scale (`hud.gd` `T_*`): 44 pt the race banner, 22 the status
clock, 17 titles and toasts, 15 body, 13 secondary and English lines (body text never below
13), 11 labels.

| On the phone (Pro Max / 6.1") | before | after |
| --- | --- | --- |
| Top-row buttons | 27 / 24 pt tall | 44 pt (the gear 44×44) |
| Text | 9 / 8 pt (top buttons), 6–10 pt elsewhere (cards, ticker, bubbles, the credit line) | 11–17 pt (44 the banner) |
| Settings panel text | 8.6–16 / 7.6–14 pt | 11–22 pt |
| Minimap | 88 / 78 pt across | 96 pt |
| BRAKE (Point) | 71 / 63 pt across, a 1-px ring | 72 pt on a plate (touch 92 pt) |
| Stick reach | 43 / 38 pt | 42 pt |

**The first screen** (docs/DEMO.md 6.1): the gear and the speed top left; WEZWANIE · rescue
call in the middle of the top row, only when a call has come in; RADIO (the station under it)
and HELI / AUTO top right; the minimap and the wallet under the gear; HAMULEC · brake (Classic:
GAZ · gas, HAMULEC and the steering strip's place) bottom right; the credit line bottom left.
No "prototype" label and no call card at the start: the first call comes in 60 s into play
(`--call-in=S`), the next 90 s after each one ends or is put off (`missions.gd` `FIRST_CALL`,
`NEXT_CALL`, first guesses), with a toast and a buzz. The helicopter is there from the start
(the user's decision, 2026-10-28). Sweep 2: the haptic engine is built while the city loads
and started 2 s before each call (`missions.gd` `warm_haptics`): on iOS the first buzz built
and started Core Haptics' engine inside the call's frame (the call's 61–117 ms hitch on the
phones; the log's `haptics:` line at load, and `rescue call ringing (buzz N ms)`).

**Moved into Settings** (four tabs, so the panel fits a phone 390 pt tall without shrinking):
Jazda · Driving (G4, 2026-11-01: car.gd PROFILES, Cruise default and Sport = the loop 2a numbers, `Prowadzenie · Handling`, `Czułość · Steering` slider (settings.gd `sensitivity` 0..1, car.gd `steer_gain` 0.6..1.4), settings.gd `handling`, tools/check_handling.gd; "Tryb gry" moved to Świat): Controls (Point / Classic, with a line on what the scheme does) and "Kamera za
autem · Camera follows the car" On / Off (the old CAM button, now with its state in view: the
user had switched Classic's following off without noticing; Point with it off is the Fixed
camera scheme; C still toggles it and a toast says which way; loop MW-6 "Tryb gry · Game mode";
F's asks, 2026-10-30: "Strefy piesze 20 km/h · Pedestrian zones 20 km/h" Wył. / Wł., off by
default, saved as `[game] zone_cap`); Świat · World: time of day
(TIME), weather (RAIN), traffic; Obraz · Picture: style (STYLE), quality, VHS tape (VHS), frame
rate, the performance overlay and TEST; Dźwięk · Sound. Style and VHS are saved
(`display/style`, `display/vhs`); the time of day and the weather are the world's and start by
day and dry. Every key is unchanged. Zoom is a pinch (the `−` `+` buttons are gone); with the
fixed camera a two-finger twist turns the view 90° (the `<` `>` buttons are gone; Q / E stay).

**Nothing overlaps.** `hud.gd` `_layout` places the panels that come and go in order of
priority (the status, the call or job card, FLASH LIGHTS, the race banner, the toast, the
performance overlay, the note and landmark cards, the radio ticker), each at its spot or giving
way along its column (down from the top row, up from the bottom), clear of the fixed controls
(the top row, the minimap and wallet, the pedals' plates, the credit line) and of each other;
the passing ones also keep out of a 110×84 pt box in the middle of the screen, where the car
is. When there is no room even so (a 390-pt screen with a card, a status and the radio host
talking), the ticker, the note and landmark cards, a speech bubble and the overlay wait (their
time on screen starts when they show; a bubble is dropped after 6 s) rather than cover
something; the overlay first shrinks to its first two lines. Speech bubbles keep clear of every
HUD rect (the radio ticker too: the kebab stand's bubble used to hide under it), trying above
and below their speaker, beside what is in the way, and narrower or wider.

**One card recipe** (from the art director's review): every HUD surface is the settings panel's
near-black violet at 94 % with ink `#fbf7ee`, sub-text `#c9c2d8` and the accent `#ffd23f`
(nothing takes its colour from the street behind it); the radio ticker keeps its station's
colour as its left edge only; toasts (the tow crew's too) and the speed and wallet sit on
cards; speech bubbles are dark cards with the speaker's name in their colour; BRAKE, GAS, the
helicopter's pads and Classic's steering strip sit on solid plates (held: the accent); the
minimap takes a night palette as the lamps come on (light streets on a dark ground; it was the
brightest thing on a night screen).

**The full-screen map** (F's asks, 2026-10-30; `full_map.gd`, made on its first open): a tap on
the minimap (down and up on it within 0.35 s and 10 pt: hud.gd `map_pressed`) pauses the game
like the settings card and shows the minimap's own mesh north up over the whole screen, in its
day or night palette: the car's arrow, the mission target, the notebook's "?" marks (the ones the
minimap shows, 1.6× bigger) and the places found as gold dots, never names. One finger pans, two
pinch (from the whole map to 250 m across the screen's height; it opens at 1,400 m on the car),
the mouse wheel zooms. MAPA · map · north up top left, the ✕ (48 pt) top right, the hint
*Przesuń palcem · zbliż dwoma palcami / Drag to move · pinch to zoom* at the bottom; the ✕, Esc
or Android's back gesture close it. Closed it is hidden (no draws); open, the 2D pass has 39 draw
calls (29 with it closed) at any zoom. `check_hud` lays it out at its 6 screens (the ✕ 44 pt in
the safe area, the cards in it and apart, a tap on the minimap, a pan and a pinch).

**Polish above English** on the HUD: the top row, the cards' titles, text and buttons
(PRZYJMIJ · Accept, POMIŃ · Skip, JEDZIEMY! · Go! ...), the status panels' hints, the toasts, the
pedals, the egg note, the loading card and the title's call to action (DOTKNIJ, BY JECHAĆ over
"tap to drive"). The English under a card is a short gloss, not a second copy of the place
names, so a card fits a 390-pt screen.

**The performance overlay** is four 11-pt lines (fps, frame time, worst frame, cap · CPU process
+ physics + draw, GPU, memory · draw calls by pass · objects and triangles). Its QUALITY and
TEST · BENCH buttons are gone (Settings → Obraz has both; U still cycles the quality).

**Check.** `godot --headless --path game --script res://tools/check_hud.gd` (`tools/verify.sh`
step `hud`; `-- --verbose` prints every rect): builds the HUD at 2868×1320, 2532×1170, a
1280×720 window and the SE's 1334×750, walks it through 24 states each (the first screen in
Point, Classic and the helicopter, a call coming in, the call card, a payment, a rescue with the
radio host and an egg, a kebab offer with the stand talking, a delivery with the customer and
the stand talking where the ticker sits, a race, a rival to challenge, a landmark card, the tow
toast, six of them again with the performance overlay on), every settings tab and the bench
card, and fails on a control under 44 pt or outside the safe area, text under 11 pt (13 for
body text), words wider than their button, two HUD rects overlapping (speech bubbles
included), a passing panel over the car's spot, a panel with no room (the passing ones may
wait: it lists them), or the settings panel or bench card shrunk to fit.

**Cost** (probe, Metal, 2868×1320, Classic, traffic Normal, day; the code before loop 2e run
from a copy in the same session; draw calls are exact, frame times noisy):

| View | draw calls before → after | 2D pass before → after |
| --- | --- | --- |
| Spawn | 153 → 133 | 65 → 45 |
| Default view over the river | 124 → 105 | 65 → 46 |
| Zoomed out | 191 → 172 | 65 → 46 |
| Helicopter | 245 → 224 | 59 → 38 |

The HUD and minimap script stays at 0.06 ms a frame; the layout runs only when a panel comes,
goes or changes size. With a job card, a bubble, the ticker and the overlay all up the 2D pass
reads 53 (budget 80).

Screenshots: `shots/loop2e_*.png` at 2868×1320 and 2532×1170: the first screen before and after
(`first_day_before`, `first_day_after`) and at night (`first_night`), Point with the stick held
(`point_stick`), Classic (`classic`, `classic_steer`), the settings tabs (`settings_driving`,
`settings_world`, `settings_picture`, `settings_sound`), a call coming in (`call_ringing`), the
call card (`rescue_card`), a kebab offer with the stand talking and the ticker (`kebab_offer`),
a delivery (`kebab_delivery`), the tow toast (`tow_toast`), the overlay (`perf_overlay`), the
helicopter (`heli`).

## The first-minute look (2026-10-28)

After the art review of the day's screenshots: night had its own look, day didn't yet; in the
first minute the eye found lime grass, coral cycle lanes, an azure river and grey buttons
before the player's car, and at night the car was darker than the road. The user agreed:
calmer day colours; the car stays red, with red reserved for it; lumpier trees with rust and
olive autumn colours; today's smoother 2× pixel size kept (a retro look is a later loop). The
rules are in the art bible (`.claude/skills/screenshot-review/art-bible.md`). All measured on
the shots at 2532×1170 (luma 0-255 of the PNG, saturation = HSV), before from the code before
this loop, after from this one, same flags.

**What changed.**

1. **The player's car** (`car.gd`, `actor.gdshader`, `models.gd`): the body now uses the
   actors' material (no new shader, still one draw call) as a new *hero* part (UV.x 8): at night
   the paint and the stripes light from within (`HERO_PAINT` 1.4, `HERO_STRIPE` 0.3 of their own
   colour, a little brighter on faces that look up, the paint's glow a touch more orange so a
   saturated red can climb in luma: red-orange, hue ~13° at night, the jobs' beacon is 24°);
   the roof and bonnet stripes are a game pixel wider (0.18 → 0.3 m); the tail lamps are taller
   and wrap over the rear deck (the camera above never saw the 0.14 m lamps on the back); the
   night cone is stronger (peak 0.42 → 0.52) and longer (15 → 17 m) than traffic's. Traffic's
   red paint (`#a83a2e`, cars and vans) became slate `#6a7487`; the parked cars' red
   (map_builder.gd's palette, baked into `city.scn`) is repainted the same in `foliage.gdshader`
   on both city paths until the next bake.
2. **Calmer day ground**: the post pass's saturation boost now follows the time of day
   (`time_of_day.gd` `saturation_share`, `post.gdshader`): none by day (1.0), the style's own at
   dusk and night (Sharp 1.15), blended with the rest of the look. Grass less yellow and with
   less chroma (`ground.gdshader` `GRASS_TINT`, `GRASS_CHROMA`); cycle lanes and crossings brick
   red (`BRICK`).
3. **The river by day** starts its depth shading from a grey-green-blue (`DAY_WATER`) instead
   of the mapped azure; the pale crests a third as strong and the sun sparkles a quarter as many
   (1-2 px each); the water's mirror half as strong by day (the deck's shade band). Night water
   is untouched (the same colour path when `daylight` is 0). The pale jagged band south of Most
   Poniatowskiego that the review took for the deck's reflection stays with the mirror off
   (`--quality=low`): it is an area polygon on the water, map side (sandbars, loop 3b).
4. **The ghost** (`building.gdshader`, `ghost.gdshaderinc`): nothing it keeps glows (emission
   × (1 − fade); loop 1 kept 30 %); a cut building's inner faces (back faces inside the ghost's
   region) are unlit and flat, a step darker than the street (`INNER_DAY`, `INNER_NIGHT`); the
   dithered rim is narrower (0.65-0.9 of the radius, was 0.55-1.0: the same middle, so the
   ghost is the same size, with less speckle over roofs that don't hide the car). The gold wall
   the review saw "inside the cut tower" at the Palace by night is the shaft's own floodlit face
   beyond the car (a debug render: front faces past the car), not the cut's inner faces; it
   stays lit (see BACKLOG).
5. **Lamp pools as pixel light** (`night.gdshaderinc` `lamp_pool`, `pool_glow`; ground only):
   the baked pool strength is cut at 0.1 / 0.3 / 0.55 / 0.8 of one lamp into four hard bands
   (levels 0.07 / 0.27 / 0.52 / 0.85, the outermost a faint skirt) with a one-pixel checker
   dither along each step (the step's width from `fwidth`), every surface's top band capped at
   `POOL_CAP` (linear luma 0.3 of emission, so pale paving under an LED lamp no longer clips);
   sodium on the ground a touch more amber (dimmed, the full sodium red read pink on pale
   paving); grass, cycle lanes and flowerbeds tinted by a half-desaturated lamp colour instead
   of having it added (warm olive, not chartreuse). Facades, trees and vehicles keep the smooth
   light map.
6. **No blank walls** (`building.gdshader`): the bake writes a LoD2 wall's UV.x as its position
   along the wall's tangent in map metres (`tools/bake_gugik.py`), negative for 47,515 of the
   94,645 wall triangles (50.2 %), and the shader's wall test was `UV.x >= 0`, so half the LoD2
   walls were drawn as blank roofs: no windows, no shop band, solid navy at night (a debug
   render with UV as colour showed it). Roofs and windowless solids carry UV (−1, −1); the test
   is now `UV.x >= 0 || UV.y > −0.5`, and those walls get their window grid, the ground-floor
   shop band (lit at night), the lamp light on their lower floors and the Palace floodlight.
7. **Trees** (`foliage.gdshader`, shader side only): each crown is pushed out and in by three
   soft lobes seeded by where it stands (±20 % of its radius), with its facets' normals taken
   from the pixels so the light follows the new shape; a two-tone dapple of darker leaves in
   0.45 m cells; saturated orange crowns (hue 12-50°) turn rust, ochre or olive by their hue.

**Measured** (the review's measurements re-taken on the same shots; the car = the median luma
of its paint, the pixels in a 56×46 px box round it that are saturated red; the road = the
median of a 30 px ring round that box, lamp pools and the car's own cone included; a pool
cell = the brightest 24-px square of ground in a pool; lit windows = the median of the window
pixels over 140 in a lit facade of the same shot):

| | Before | After |
| --- | --- | --- |
| Car / road at night: the spawn (prebuilt) | 38 / 71 (−33) | 127 / 67 (+60) |
| … Marszałkowska | 38 / 97 (−58) | 126 / 90 (+36) |
| … the Praga beach (on the sand) | 38 / 76 (−38) | 115 / 76 (+39) |
| … the Palace from the north-west | 40 / 89 (−50) | 128 / 87 (+41) |
| … Rondo Dmowskiego in the rain | 30 / 30 (−1) | 126 / 27 (+100) |
| … Most Poniatowskiego (on the lamp-lit deck) | 64 / 151 (−86) | 125 / 127 (−2) |
| Car paint by day (spawn) | `#dc3002`, sat 0.99 | `#cf3e2a`, sat 0.79 (the most saturated thing near it) |
| Grass by day (two lawns at the spawn) | `#96c13c` 0.69, `#87ba2a` 0.77 (hue 79-81°) | `#98bd6b` 0.44, `#89b55d` 0.48 (hue 87-90°) |
| Cycle lane by day | `#e66d4c` 0.67 | `#ab5447` 0.58 (the review asked ~`#a9544a`) |
| The river by day (two stretches) | `#428acc` 0.68, luma 124, glints to 255 | `#517c8c` 0.42, luma 113, glints to 133 |
| Pool cells at night: the LED plaza by the spawn | 255 (clipped) | 169 (brightest pixel 172) |
| … sodium on the car park / the lawn and cycle lane | 168 / 163 | 145 / 150 |
| … Marszałkowska's pavement (two) | 207 / 117 | 157 / 87 |
| … Rondo Dmowskiego's paving ring / lawn, in the rain | 192 / 133 | 159 / 119 (brightest pixel 206 → 166) |
| … Most Poniatowskiego's deck | 200 | 153 |
| … the plaza east of the Palace | 221 | 171 (brightest pixel 233 → 176) |
| Lit windows (spawn / Marszałkowska / Rondo) | 226 / 220 / 241 | the same |

So at night every pool cell measured is under its shot's lit windows (most under 80 % of
them) and the brightest cells of the night shots are windows, lamp heads and neon, not
ground; the car is 36-100 over the road everywhere except on the lamp-lit bridge deck, where
lit ground sits above it on the value ladder and the paint stands out by colour (saturation
0.82 against the deck's ~0.35; a saturated red tops out at ~110-130 luma). LoD2 walls drawn
as roofs: 47,515 of 94,645 wall triangles → 0.

Shots: `shots/look_final/` (the core set before and after at 2532×1170 and 2868×1320, both
city paths; spawn_day_prebuilt, the night spots, dusk, the rain-day guide, the Ogród Saski
park), `shots/look_before/` (the extras before); `shots/look_probe/` (the debug renders: walls'
UVs as colour, back faces and faces past the car at the Palace, the river with the mirror off).

**Cost** (Mac M4 Pro, busy with other agents' runs; the code before this loop run alongside
from a copy, interleaved): the bench route on Vulkan Mobile at 1920×1080, uncapped, medians of
5: GPU 0.79 → 0.85 ms by day, 0.76 → 0.76 at night (B's first night run, 3.25 ms, was the new
shaders compiling once; the median leaves it out); frame 1.54 → 1.56 / 1.48 → 1.54 ms; scripts
0.54 → 0.53 / 0.52 → 0.53 ms. The zoomed-out view (220 m, Vulkan at 2868×1320, medians of 3):
GPU 1.38 → 1.39 ms by day, 1.27 → 1.30 at night. Draw calls at the budget's four views
(Metal, 2868×1320): 153 / 124 / 191 / 245, unchanged (main 53 / 35 / 66 / 100, shadow 35 / 24 /
60 / 86): the car's body changed material, not count (still 3 draw calls), and nothing new is a
shader of its own. Triangles: the car +24 (the tail lamps' deck pieces); the city's meshes
unchanged (6,100,768 vertices). The extra GPU by day is half the LoD2 walls running the facade
code instead of the roof grain, and the crowns' dapple and pixel normals.

**On the phone** (not run this loop): the frame rate at the default view and zoomed out (the
orchestrator's run), and the look at phone size: does the car read first at night and by day,
do the banded pools read as pixel light or as targets on the big lawns, is the river calm,
are the lumpy crowns better than the gumdrops.

## Camera loop: the follow camera (2026-10-28)

After the user's play on the iPhone: "now the follow camera is not working", and the wish for
the cinematic camera add-on (Phantom Camera). The phone's saved settings were Classic with
`classic_follow=false`: CAM had switched the following off, so the camera didn't turn by design
(making that setting explicit is the HUD loop's). Measured beyond the setting with a new camera
log (`--cam-log`) and scripted moments in the real city (`--cam-test=`), through the real touch
path (`--drag`, `--pedal`) on the Mac: **Point** held still while the finger was down (0°/s) and
came round 0.6 s after the release (3.2 s, at most 64°/s); **Fixed** never turned; but

- **Classic** started every game on the 45° diagonal: the first metres swung the camera ~155°
  round behind the car at up to **182°/s**; and it turned with the car at up to **108°/s** (a
  90° turn from a standstill; 91 at 20 km/h, 76 in the city at 50);
- **the helicopter's** camera waited while the stick was held, then 0.6 s later snapped round at
  up to **135°/s** (no ease, no limit);
- **braking** from 90 km/h, the view slid **8.0 m back** (7.5 m/s) as the look-ahead shrank with
  the speed, and the speed zoom came straight back in.

Docs/DEMO.md's comfort limit (Nesky) is 64°/s. All of that is fixed below; the rest is new.

**Phantom Camera** (Marcus Skov / Ramokz, MIT, 0.11.0.3 from the Godot Asset Store, 0.85 MB;
GDScript only, its C# files are optional wrappers a non-.NET Godot ignores) is in
`game/addons/phantom_camera/` without its examples folder; its manager is an autoload in
`project.godot`. The editor plugin is not switched on (it adds a dock and checks GitHub for
updates on every editor start, the headless exports included); switch it on in Project Settings
→ Plugins to see its nodes and gizmos. The follow camera itself is not a Phantom Camera follow
mode: none of them can hold still while Point's finger is down, cap the turn rate, snap to the
pixel grid, or keep the shadow's sphere through the speed zoom (`_camera_far`); it is the
game's own (`follow_camera.gd`), and Phantom Camera does the cinematic moments
(`camera_shots.gd`): its host runs in MANUAL mode under the camera, only while a moment plays,
and tweens between three of its cameras (the follow view, the target's, and a wider one
halfway). It sets `Engine.physics_jitter_fix = 0` when it starts (ignored with physics
interpolation on, as here).

**The follow camera** (`follow_camera.gd`, shared by `main.gd` and `tools/check_steering.gd`):

- **Turning**: the turn rate is the error × a gain (Classic 2.2/s as before; Point and the
  helicopter 1.1/s after a release, eased in over 0.8 s), the rate itself easing towards that
  (critically damped: no overshoot), never over **64°/s**; heading wiggles under 1° don't turn
  it. Point and the helicopter hold still while the stick (or a key) is held and 0.6 s after.
  Standing still Classic and Point hold still; the hovering helicopter's camera comes round (it
  stops within a second of a release). A following camera starts behind the vehicle (`--shots`,
  `--bench` and `--probe` keep the 45° start: their views are the reference screenshots and the
  budgets'); a tow turns it behind the car at once (not while Point's finger is down).
- **Look-ahead**: along the way the car goes, 0.40 s of its speed + 0.25 s more at top speed
  (15 m at 90 km/h, 12.5 before; 7 m at 50, as before), at most a fifth of the view, eased over
  0.7 s and never faster than 3.5 % of the view a second (2.8 m/s at 80 m, ≤ ~40 px/s on 1170
  lines), so the car drifts across the screen slowly when the way it goes turns. In Classic it
  lies along the camera's forward instead, so the car keeps its place on screen while the camera
  turns (along the car's way it swept the car round the middle by the camera's lag). **Braking**,
  it gives back at most half the car's own speed, so the view never moves back: it glides to rest
  ahead of the car and stays while the car stands.
- **Dead zone**: the view's centre follows a window 0.5 % of the view wide (0.4 m at 80 m, ~7 px
  on 1320 lines), then eases as before (6/s).
- **Speed zoom**: still a quarter wider at top speed and the 80 m default; out at 2.5/s, back in at
  0.8/s (it snapped in when braking); the zoom buttons and pinch at 2.5/s both ways. The shadow's
  sphere doesn't change through the speed zoom (unchanged, loop 2b).

**The cinematic moments** (normal launches only: never with `--notitle`, `--shots`, `--bench`,
`--probe` or the other testing flags; `--cinematic[=flyin|look]` forces them):

- **Fly-in** when the title screen goes: from a 200 m view 90 m along the car's way (the title
  still covers the cut) down to the follow view in 2.6 s (cubic in-out), turned like the follow
  camera all along, so the stick means the same on screen.
- **The opening flyover** (2026-10-31, docs/design/opening-flyover.md) replaces the fly-in on a
  fresh save's normal launch (when the guide runs; `--cinematic=opening` forces it): 7.5 s from a
  420 m view over the Palace (turned 115°, pitch -38°) over Plac Defilad (230 m, 40°) down to the
  follow view, one smootherstep over the flight through a Catmull-Rom of the keys and the live
  follow view (size in log space), placed by camera_shots.gd itself, not the host. A WARSZAWA
  caption (Śródmieście · Plac Defilad / the centre of Warsaw) fades in 0.6-5.4 s. The HUD is
  hidden and first10.gd's clock waits until it ends (done, skipped or stopped: `ended`).
  `check_opening.gd` samples it (ends on the follow view, ≤ 6 m, 1.5°, 3 % a frame).
- **A look at a new target** (a rescue call's place, a delivery address; not a race's
  checkpoints) when the vehicle is under 30 km/h, nothing is held and the target is over 40 m
  away: both in one view if they fit in 220 m, else over a 220 m view halfway (out 0.6 + 0.6 s,
  0.7 s on the target, back 0.5 + 0.5 s). Not during another moment, the title or a BENCH run
  (which stops a moment at once).
- **Any touch, click or key** skips a moment: back to the car in 0.3 s (not in the first 0.25 s:
  the tap that dismissed the title arrives twice, as a touch and as Godot's mouse click).

**Numbers** (`tools/check_steering.gd`; its new `--camera=2a` runs loop 2a's camera with today's
car, and every test now starts with the camera settled for the starting speed: loop 2a's px/s
above started it at the car, which counted the look-ahead catching up; 2532×1170, 80 m):

| | Loop 2a camera | Camera loop |
| --- | --- | --- |
| Camera's fastest turn: Classic 90° turn from 0 / 20 / 50 / 90 km/h | 108 / 91 / 65 / 52°/s | 64 / 64 / 64 / 54°/s, 0° overshoot |
| Point, held 90° right at 50 km/h | settles in 1.2 s, 0° overshoot, camera 0°/s | the same (the car's law) |
| Point, let go after 2.5 s | camera behind the car 3.2 s later, at most 64°/s | 2.9 s, at most 60°/s |
| Braking from 90 km/h (Classic, Point) | view slides back 8.0 m (7.5 m/s); car on screen ≤ 47 px/s | 0.0 m; ≤ 27 px/s; zoom 96.7 → 81.5 m 2.5 s on (80.0 before) |
| Road ahead at a steady 90 km/h (to the top edge) | 105 m, 4.2 s | 107 m, 4.3 s |
| Classic, the thumb wobbling ±0.35 at 1.2 Hz at 50 km/h (car ±1.5°) | camera wobbles 0.90° (the screen's side edge 20 px) | 0.29° (6 px) |
| Car's fastest move on screen in the 90° turns, Point / Fixed / Classic (0, 20, 50, 90 km/h) | 42 43 58 73 / 40 28 36 47 / 43 42 57 66 px/s | 41 41 40 34 / 43 31 26 22 / 47 43 52 61 px/s |

Run in the real city with `--cam-test` at 2868×1320 (`shots/loopcam/`: `before_*` from the code
before this loop, `after_*`, and `sheet_*` strips every 0.25 s; `cam:` lines in each `log.txt`):
the Classic turn at 50 km/h turns the view at most 64°/s (76 before; it lags up to 41° behind the
car, 33 before), the car at most 28 px off the middle sideways (37 before); the Point release
comes round in 2.9 s (3.2), at most 60°/s (64), the car at most 83 px from the middle (115); the
stop from 90 km/h leaves the car 46 px below the middle and still (before, the view slid back
until it was in the middle, from 51 px); `after_flyin` (200 → 80 m over Rondo Dmowskiego and
Marszałkowska) and `after_look` (`--mission=1`: a rescue 843 m away, over the city and back).

**Cost**: the follow camera's math +1.1 µs a frame on the Mac (0.33 → 1.39 µs, a micro-benchmark
of the two); a moment playing 8.7 µs a frame (Phantom Camera's host), 0.2 µs idle; no node
processes between moments. Bench (`--controls=fixed`, the same view both ways, 3 interleaved
runs): scripts 0.55–0.56 → 0.56–0.61 ms, game loop 0.05 → 0.05–0.06 ms, draw calls 148 → 148.
`--probe` at 2868×1320: spawn 153 → 153 draw calls, over the river 124 → 124, helicopter 245 →
245. The fly-in's first view (200 m) draws 217 and the look's widest (220 m) 219, for a second or
two (the zoomed-out budget view draws 190–215).

## Loop 3b: roads II, the builder (2026-10-28)

The builder's side of docs/DEMO.md section 4 (R2, R5-R7, buildings under decks, the tunnels),
so that **every rule C1-C10 passes over the whole map** (allowlist entries only with a reason and
a source) and **a car and a bus drive every lane without hitting anything**. The structures are
placed in the bake, on the finished map data (`tools/bake_structures.py`, run at the end of
`bake_osm.py`): the game draws what the data says, and `check_roads.py` and the new
`check_drive.gd` check the same data.

| Rule (DEMO.md 4.5) | Before (loop 3a) | After | Allowed, why |
| --- | --- | --- | --- |
| C1 grade | 32, all allowed | 32, all allowed | as loop 3a |
| C2 joints | 0 | 0 | |
| C3 clearance | 54 in 7 places, allowed | 36 in 6, allowed | the decks rose (R2); schematic footbridges, the WKD cutting |
| C4 piers | 31 of 171 | 0 of 174 (8 portal legs) | |
| C5 solids | 50 | 18 in 14 places, allowed | courtyard driveways ending at a gate (each with its OSM way) |
| C6 deck ends in the air | 0 (+5 rim) | 0 (+5 rim) | |
| C7 dropped ways | 0 | 0 | Warecka's 7 m `tunnel=yes` counts as a gate now |
| C8 lanes | 5, allowed | 5, allowed | as loop 3a |
| C9 through decks | 57 | 4 in 3 places, allowed | a footway deck grazing buildings (2-8 % of a footprint), the science centre's roof ramps |
| C10 landmarks | 1 | 0 | |

`check_drive.gd`: 2,276 lanes, 36,177 spots every 4 m, 0 car and 0 bus boxes in collision (the
first run on this loop's bake: 407 car + 1,171 bus boxes in 341 places); the autopilot over 20
routes (every deck and tunnel edge, both ways, 3 outer-lane repeats), 45,067 frames, 0 height
jumps over 0.3 m (first run: 3 on 10 routes).

**What changed** (DEMO.md 4.8 has the numbers per item):

- **Piers (R5)** are the bake's (`decks.piers`): a candidate every 38 m slides up to 12 m along
  its deck to a footprint 1.1 m clear of what runs under it (roads at half their width, trams,
  rail beds, kerbs, carriageway areas, lower decks, every lane's drive corridor); else a portal
  frame (two legs outside the road, the slab as the cross-head, a cap beam out to a leg past the
  deck's edge); else none. Solid. `--debug-roads` shows them.
- **Retaining walls (R6)** (`walls`): where an approach stands 0.35 m or more over the ground
  beside it, along its sides and across an end: stone (roads) or concrete (tracks), a light
  coping, a 0.9 m parapet from a 1 m drop, solid from 0.6 m, open where a way joins the approach
  or a tunnel passes under it. The same runs line the tunnels and their open ramps.
- **Most Poniatowskiego's towers (R7)** (`towers`, landmarks.gd): the outline by the deck, its
  footprint trimmed clear of the road decks, approaches, roads and lanes, base at the boulevard,
  shaft from the solved deck + 1.2 m; the zone grown 6 m, so the stair annex OpenStreetMap maps
  ~6 m out is no longer drawn as a building fused into the tower. Solid from the boulevard to
  over the deck.
- **Buildings under decks** (`cut`, `cutd`, `pil`, `lod2_cuts`): cut to the slab's bottom - 0.5 m
  under a road, rail or tram structure (the Poniatowski viaduct's LoD2 arcades and the Arkada;
  `_build_lod2` clips the LoD2 triangles and lays the roofs over the cut flat); a viaduct's
  mapped pillars fitted to the slab; a building only grazed (under 20 % of it) isn't cut.
- **True deck heights (R2)**: `tools/geotiff.py` reads the demo fetch's GeoTIFF corridors
  (`data/raw/demo/gugik/nmpt05`, `nmt1`; 17 windows reach this map) and `bake_roads.SurfaceModel`
  gives the solver the measured deck. Most Poniatowskiego's river span now has its camber (-5.6 /
  -4.5 m at the ends, -3.2 m mid-river; the solver alone had it nearly level), the Jana Pawła II
  viaduct rose 1-2 m onto its pillars, the viaduct over Powiśle stays within 0.3 m of loop 3a's.
- **Tunnels** are drawn and driven: the floor's road, dark walls (solid inside), portal frames,
  walls along the open ramps; `drive_height` drives a tunnel's floor (`map_builder.tunnel_floor`),
  traffic routes through them and is hidden deeper than 15 m from a portal; the car shows
  through the ground as a warm silhouette (`tunnel_xray.gd`); `--tunnel` starts inside one.
  Garage doors at the 27 ramp tops.
- **Clearing the lanes** (what `check_drive` found, by class): tram-stop platforms are kerb
  height and not solid any more; fences, walls, hedges and mapped guard rails are cut out of
  carriageways and lanes; benches, racks, shelters, parked cars and kiosks standing in one are
  left out; building colliders end at the building's top; deck parapets are solid only over a
  1 m drop; road decks narrowed (at most 0.4 m) beside a ground lane; LoD2 walls a metre into a
  lane not solid there; approaches widened to hold their lanes; `aprons` blend the ground at
  structure ends (the 10 m grid's cross slope made a car step 0.3-0.4 m off a deck or out of a
  tunnel); no pit fill in a tunnel's open ramp.
- `tools/verify.sh`: `roads` FAILs on any rule; new steps `drive` and `drive-prebuilt`.

**Cost** (Mac, README's commands; the loop 3a code and data in a copy, `game_before/`, run
alongside). Draw calls, probe at 2868x1320, before → after: spawn 153 → 154 (3D 53 → 53, shadow
35 → 35, 2D 65 → 66), the default view over the river 124 → 125, zoomed out 190 → 186, the
helicopter 242 → 245, Most Poniatowskiego's east end 123 → 122, the Wisłostrada portal 135 →
135, the Jana Pawła II viaduct 137 → 136; main-pass triangles unchanged (0.25 → 0.24 M at the
spawn, 0.37 → 0.36 M zoomed out). Every new piece (piers, walls, portals, garage doors) goes into
the existing tile meshes: no new material or draw call; the tunnel silhouette costs a draw call
per car mesh only while the car is in a tunnel. Vertices 6,144,280 → 6,060,970 (-1.4 %; meshes
3,771,594 → 3,766,836, instances 2,372,686 → 2,294,134: the parked cars and props cleared out of
the lanes). Scripts on the bench route (5 interleaved runs, medians): traffic + trams + people
0.65 → 0.63 ms, all 0.93 → 0.91 ms; the frame is capped at the display's 120 Hz on this Mac
(8.33 ms both), and other agents' Godot runs overlapped, so frame times say nothing. The runtime
city build 7.7 → 8.4 s (the LoD2 cut, the walls, the aprons in `terrain_height`); the prebuilt
city loads in 0.8 s as before. `centrum.json` 5.04 → 5.14 MB, `city.scn` 36.5 → 36.4 MB.

**Not done** (BACKLOG "From loop 3b"): the minimap's dashed tunnels (hud.gd), the art items
(natural banks, sandbars, tree crowns by roads) and the triage's 3b row (kerbs solid, markings);
loop 3b-2.

Screenshots: `shots/loop3b/` (the road spots before and after on both city paths, the tunnel
portal and the car in the tunnel, the towers, a pier beside a road; `c9_spots.png`).

## Loop 2c: car models (2026-10-28)

The user asked for nicer car models; the art review and the user had decided that red belongs
to the player's car (red-orange, white roof stripes, the hero material at night), that traffic
has no saturated red or orange (Warsaw's buses and trams keep their livery), that the police are
white with a blue band and a blue/red light bar, and the city guards mustard and dark red.
Every vehicle was built from boxes (`models.gd`, the player's in `car.gd`).

**The kit** (`models.gd` `Shape`, flat-shaded, vertex colours, the actors' material): a body
lofted from its side profile (front, nose, a sloped bonnet up to the windscreen's foot, the
waist, the rear deck or hatch, the rear), a glasshouse lofted on it and narrower at the roof
(a raked windscreen, the roof, the rear window), glass panes laid on it with pillars between
them (two side windows a side, the B pillar between), six-sided wheels (eight on the player's)
with a flat bottom and hub caps, standing in dark arches cut into the sides, black bumpers,
number plates, a grille, head and tail lamps. One table of measurements per body (`spec()`):
hatch, saloon, estate, SUV, panel van, box van, the player's hatch, a coupé and a city car.

**A family per traffic kind.** Traffic keeps one MultiMesh per kind (cars, taxis, vans, the
bus; same count as before). Each kind's mesh is a family of shapes with the same parts in the
same order (`family()`): the first shape is the mesh itself, up to three more ride in each
vertex's CUSTOM0..2 (position, and the normal packed into one float), and the vertex shader
(`actor.gdshader`, UV.x + 16 marks such a vertex) takes the shape the instance's custom alpha
names. A part one shape lacks shrinks to a point in that shape. So:

| Kind (MultiMesh, pool) | Shapes (share) | Triangles | Paints |
| --- | --- | --- | --- |
| CAR (112) | hatch 36 %, saloon 26 %, estate 22 % (roof rails), SUV 16 % (tall, high sill, rails) | 194 | greys, white, black, navy, slate, beige, green, olive, steel blue, plum |
| TAXI (16) | the city taxi 50 % (a white saloon, our own livery: a yellow band of dark squares on the doors, a lit yellow roof sign), Podwózka 50 % (parodies.md: a hatch in greys, black or navy with a phone on the roof, its screen lit, five dark stars) | 268 | |
| VAN (16) | panel van 60 % (a high roof, glass in the cab only), box van 40 % (a short cab under a box that reaches over it) | 228 | whites, greys, navy, slate, green |
| BUS (8) | the city bus: red below, yellow above, a window band with pillars (lit at night), a destination display, three doors on the right, the roof's air-conditioning box | 198 | fixed |

Each car's shape comes from its own random stream (`_looks`), so where and which kind of car
spawns is as before; its size (the gap it keeps, its body near the player) is the shape's
(`models.gd` `TRAFFIC`). Each MultiMesh now draws only up to its highest slot in use
(`visible_instance_count`; a freed slot is the next one taken), not its whole pool, so the
frame's triangles fell even though each model has more.

**The player's car** (`Models.player_meshes()`, still body + head lamps + tail lamps = 3 draw
calls): the same kit with shorter overhangs, a lower roof with more rake and a wider stance,
the twin white stripes over the nose, the bonnet, the roof and the tailgate, black bumpers, a
roof spoiler, round head lamps, light hub caps; the hero material, the tail lamps over the rear
deck and the lean and squat as before. 292 triangles (240 before). No mirrors: at the 80 m
view they would be one image pixel.

**The police and the city guards** (`Models.police_mesh()`, for loop 3g, not in traffic): one
family, so 3g's POLICE kind can draw both in one MultiMesh. Shape 0 is the patrol estate (4.7 m,
paint `POLICE_WHITE`): a blue band on the doors with "POLICJA" in the game's 5×7 pixel font
(5 cm pixels, white; it reads from views of ~15 m and closer, at 80 m it is a white streak), a
light bar with a blue and a red lamp that blink in turns (BLINK, UV.y shifts the beat; they
glow at night). Shape 1 is the guards' car, the same estate at 0.88 (paint `GUARD_MUSTARD`)
with a dark red band and two amber lamps. 636 triangles.

**The rivals** (their own meshes, all colours fixed, no saturated red): Seba's lowered purple
coupé with pink bonnet stripes and a big wing, Mordor Mike's grey estate with dark glass and a
roof box, Pani Halina's tiny mint city car with a cream roof and a basket (a cabbage and a loaf),
Słoik's white panel van with a pickle-green stripe (it was red) and the jars on a rack, Zbyszek's
long black saloon with a yellow sign and chequers, Bartek's neon-green hatch with a magenta wing
and the speaker. 204–288 triangles each.

**Trams**: the same kit, Warsaw's yellow over red kept: the cab's big windscreen leans back over
a rounded nose with a destination display above, two doors a side, the window band lit at
night, dark gangways where the cars join, an air-conditioning box on the cab cars and the
pantograph on the middle car. 98 triangles a cab car (120 before).

**Parked cars**: `map_builder.gd` now takes their mesh (`parked_mesh()`: a small saloon, 40
triangles, was 24) and their paints (`PARKED_PAINT`, no red) from `models.gd`. city.scn was not
re-baked (the map side's): when it loads, `main.gd` replaces its parked cars' shared mesh in
place (`Models.renew_parked`), so both city paths look the same; the old red instance colours
in the bake stay repainted slate by `foliage.gdshader` until the next bake. They stay one shape:
more kinds would cost a MultiMesh per kind per 512 m tile (BACKLOG).

**The actors' shader** (`actor.gdshader`, no new shader or material): the family shapes (a
vertex with UV.x ≥ 16 reads CUSTOM0..2 when INSTANCE_CUSTOM.a is 1..3), and BLINK (7) shifts its
beat by UV.y (0 for the roadwork lamps: unchanged).

**Testing aid**: `--lineup` puts every model round the car (the flags table), and prints each
one's triangles.

**Cost** (`--probe` at 2868×1320, Metal, Mobile, `--controls=classic`, High, Normal traffic,
day; the code before this loop from a copy, interleaved):

| View | Draw calls, all passes (main / shadow) | Main pass triangles | Shadow pass triangles | Ceiling after 2c |
| --- | --- | --- | --- | --- |
| Spawn | 134 → 132 (53 / 35 → 53 / 35) | 0.25 → 0.24 M | 0.14 → 0.13 M | 165, 0.32 M / 0.18 M |
| Default view over the river | 105 → 105 (35 / 24 → 35 / 24) | 0.19 → 0.17 M | 0.12 → 0.10 M | 140 |
| Zoomed out (`--size=220`) | 171 → 171 (64 / 60 → 64 / 60) | 0.37 → 0.37 M | 0.27 → 0.28 M | 215, 0.50 M / 0.35 M |
| Helicopter | 222 → 222 (98 / 86 → 98 / 86) | 0.32 → 0.32 M | 0.22 → 0.23 M | 270 |
| Bench route, day / night | 113 → 113 / 82 → 82 | 0.18 → 0.17 M | 0.15 → 0.14 M | |

(The 2D pass, the HUD, draws 44 or 46 from one run to the next, before and after alike.)

Triangles a model (before → after): a traffic car 144 → 194 (each of the four shapes), the taxi
300 → 268 (and Podwózka), a van 144 → 228, the bus 156 → 198, the player's car 240 → 292 (≤ 3,000),
the police and guards' car 636 (≤ 800), the rivals 144–336 → 204–288, a tram cab / middle car
120 / 108 → 98 / 102, a parked car 24 → 40.

Bench (Metal, 1280×720; 3 runs each, interleaved with the code before, medians): scripts
0.73 → 0.75 ms (traffic 0.28 → 0.29), draw calls 113 → 113; night (1 run each) 82 → 82 draw
calls, scripts 1.34 → 1.21 ms. Vulkan GPU at 1920×1080: 3.03 → 1.88 ms, but another agent's
Godot ran beside these runs (loop 2b measured 0.80–0.87 ms on a quiet Mac), so read it only as
"not worse".

Vertices of the city (`count_vertices.gd`): 6,144,280 → 6,200,700 (+0.9 %: the parked cars,
72 → 86 vertices each). The Metal frame times can't be compared this time (the runs were held
at the display's 120 Hz, 8.33 ms, and other agents ran Godot): the draw calls, triangles and
script times are the comparison.

Shots: `shots/loop2c/` (gitignored): `*_before_*` from the code before this loop, `*_after_*`,
at 2532×1170, 2868×1320 and 1792×828 (the iPhone 11): the spawn by day and at night (prebuilt
city), Marszałkowska in Busy traffic, the line-up at 25 m and 14 m (`after_lineup*`, and at night),
rival race starts (Seba, Zbyszek), the parked cars by the spawn.

What only the phone can tell: whether the hatch is found first in Busy traffic at 80 m (bar C1;
the marker helps), whether the shapes read at the iPhone 11's 2× pixel (585-line image), the
police lettering's legibility, and the frame at the zoomed-out and helicopter views with many
cars in view (the model has more triangles, the frame draws fewer).

## Loop 3b-2: map art and road details (2026-10-28)

The map side of the art review (items 4, 8, 9 and the tram-bed note) and the road details loop 3b
left (the triage's 3b row). New bake step `tools/bake_banks.py` (run by `bake_osm.py`), new check
`game/tools/check_drape.gd` (verify step `drape`).

**The class behind the "torn paper" sandbars and the beige patches, measured first.** The flat
areas (water, grass, parks, plazas) were laid on the ground in pieces up to 12 m whose planes
cut under the 10 m terrain grid's folds; where the bare-earth grid rises (the river's real
sandbars and a ridge along Most Poniatowskiego's piers in the GUGiK grid, lumps in the parks)
the ground poked through as jagged beige patches. `check_drape.gd` samples every area triangle
against the drawn ground: before **85,624 m² of grass and parks, 9,893 m² of plazas and 2,813 m²
of water** under the ground by more than 0.1 m; after **0 / 0 / 0** (and 0 of 57,354 m² of
sand). The areas are now laid on the grid's own triangles (`map_builder._fill_on_grid`: whole
cells where the outline doesn't cross, the cells it crosses clipped), never under the drawn
ground. Exact on the ground, they need almost no depth bias (0.05 → 0.01; their few millimetres
of height order them).

**The same class the other way round** (found in the orchestrator's review of the first beach
shots: the Praga beach's footpath came out dashed once the beach was sand): a footway is a
strip of 10 m pieces, each a plane through terrain points, that sags under the grid's folds;
where it sagged further than its depth bias lifted it over the area under it, the area hid it.
`check_drape.gd` part 2 samples every footway, cycle path, step, wet band, rim and foam strip
against the area triangles under it: with the areas at 0.05 **3,035 m² of footways and paving,
172 m² of cycle paths, 562 m² of steps and 22 m² of wet bands** were hidden; now **2 / 0 / 0 /
0 m²** (the 2: one footbridge's ramp ending 0.46 m under the park it lands in, the deck solver's,
allowed). Footways, cycle paths and steps on the ground are now laid on the grid's triangles too
(`_strip`, depth bias up to 0.12), and the areas' bias is 0.01.

**The pale band south of Most Poniatowskiego** was neither a reflection nor a sandbar: the
bridge's two pavements (`area:highway=footway`) and its tram bed (`landuse=railway`) are mapped
as areas, mostly without a layer, and were drawn on the ground, that is on the river under the
bridge (a pale and a grey band). `bake_roads.level_surfaces` puts a mapped surface on a deck
when most of it lies in the corridor of that deck's pieces of its own kind (paving on a footway
piece, ballast on a tram or rail piece) standing 2 m over the ground: 3 surfaces (all on Most
Poniatowskiego); what lies under a bridge (a pitch, Centralna's platforms, the pier shoals)
matches no such piece and stays on the ground.

1. **Natural banks.** `bake_banks.classify_shore` splits the water's edge (bake_roads' shore runs)
   into built and natural stretches every 2 m from OpenStreetMap: built where a footway or
   cycleway runs along the edge within 9 m (the Bulwary), a road within 10 m, paving or a plaza
   on the land side, a wall or embankment along it within 4 m, or a bridge deck within 20 m (the
   abutments); a sand, beach, shoal, wetland, scrub or wood polygon on the land side beats a
   promenade; stretches under 14 m take their neighbours' kind. **2.68 km built, 4.99 km
   natural** (the Praga bank, the beaches, the reeds north of the railway bridge, the west bank's
   natural stretch south of the bridge; park ponds with grass banks). Built stretches keep the
   granite edge (4.2 km with the bridges' and the fountains'); a natural one gets a wet band and
   a damper one (0.9 m each, sand, or dark earth on a green bank) inland from the waterline and a
   1-px foam line (0.22 m) on the water; `n` on the shore run (1 sandy, 2 green). **The car**
   is held back on a natural bank by the same collider on the waterline as before (invisible
   there): it stops at the foam, on the wet sand; nothing changed for the splash and tow
   (`check_water` 0 everywhere). The bake also dropped the seam between the Vistula's two
   multipolygons, which had put a granite edge and a wall across the river at z ~820. Sand
   (natural=beach / sand / shoal / shingle, 74 polygons, `sand` in `centrum.json`) is drawn as
   sand under the water, so nothing of it shows past the edge; the beige patches in the water
   were the ground poking through (above). OpenStreetMap leaves thin strips between its sand
   polygons (a beach cut round a groyne, a shingle bank mapped a few metres off the beach, two
   beaches split under the bridge); bare ground while the beach was bare ground, they showed as
   straight pale bands on the sand. `bake_banks.sand_gaps` fills the gaps up to 6 m wide in a
   group of sand polygons of 400 m² or more (closed by 3 m, less anything mapped there: grass,
   parks, plazas, paving), 103 fills, 1,885 m² (`f` on `sand`, drawn just under the sand). **At night** sand and the wet bands are 0.6× (the
   beach's luma 76 → 58 at night; by day 182 → 183), the foam 0.32×.
2. **Sandbars** (`sandbars`, 15, 5,874 m²): the sand polygons' part on the river, rasterised at
   0.5 m, opened by 1 m (nothing narrower than 2 m survives), traced, smoothed (Chaikin ×3) and
   simplified (0.12 m), pieces under 6 m² dropped; drawn over the water on the grid's triangles
   with a darker wet rim (1.1 m) inside the outline and a foam line round it; gravel shoals
   (surface=gravel: the rubble round Most Poniatowskiego's piers, `g`) in grey.
   For the car and the helicopter they stay river (water.bin is unchanged).
3. **Tree crowns by the roads.** `bake_osm.crown_scales` writes one scale per scanned tree
   (`trees3d_crown`, hundredths; `trees3d` keeps its 75,324 values): 0.75 within 12 m of a
   drivable road's edge, rising to full size at 20 m (parks, courtyards). 5,443 of 12,554 trees
   are at 0.75, 7,044 scaled at all. `map_builder` shrinks the crown's radius and depth (its base
   stays, so it still clears a bus), `bake_ao.py` its shade.
4. **Kerbs you feel.** `map_builder.drive_height` lifts the car 0.14 m onto a traffic island or a
   grass median at street level; `kerb_feel` (cells of the islands, medians and kerb lines, kept
   in `city.scn` for the prebuilt city) tells `car.gd` when a move crossed a kerb (the car keeps
   92 % of its speed and the body bounces 7 cm) and when it rolls on the raised ground (0.6/s
   drag; the driving-feel loop made it 97 %, once per 0.5 s, and 0.25/s). Driven at 40 km/h onto 30 islands: 35.3 km/h after 1.5 s (38.4 without), 0.14 m up.
   Not for a car with its collision off (the autopilots) or parked, not on decks; traffic keeps
   to its lanes and never feels them (`check_drive` 0 collisions, 0 height jumps).
5. **Markings.**
   - **Rondo Dmowskiego's spiral** (and the 4-lane ring by Centralna, the only other ring with 3+
     lanes and a 25 m radius): between two exits each lane line holds its lane for the first
     35 % of the way, then sweeps out by a lane into the exit; the outermost line meets the outer
     edge at the exit and a new one starts at the island (`bake_roads._spiral_rings`,
     `_paint_spiral`). The ring's own lane lines and **its turn arrows** (the arrow confetti from
     the ring's `turn:lanes`) are gone: arrows 491 → 442, none on any roundabout ring.
   - **Chevrons with the traffic**: 53 long hatched areas with the traffic going one way on both
     sides get chevrons whose points face the oncoming traffic (26 were turned round); 14 between
     opposite flows (or with no road alongside) get plain diagonals.
   - **Deck gaps**: two pieces of one bridge up to 6 m apart (road, tram bed, footway) no longer
     each get a parapet with the river showing between them: the slabs meet half way across the
     gap, and a low kerb marks each piece's edge (2,087 m of deck edges; the parapet's collider
     stays where there is a drop, so the car can't drive into the gap).
   - **Turn arrows**: the combined arrows (left + right, left + through + right) 9 cells wide
     (were 11) and the cells up to 0.3 m, so strokes and gaps stay whole at the default view.
   - **The tram bed** (a median with trams): a concrete track slab (`#8c887f`, a joint across it
     every 3 m, layer 19), darker than the pavements; tram rails thinner (0.16 m) and closer to
     it in tone: no longer pale pavement with a barcode on it.
   - **Medians on two-way roads**: no two-way road on today's map has its median mapped as a line
     (no `divider`, no barrier or kerb line along a two-way road's centre; the 3 gaps between a
     two-way road's carriageway areas are not medians), so nothing was built (BACKLOG).
6. **Parked cars' red**: city.scn is re-baked with `models.gd` `PARKED_PAINT` (no red), and the
   red-paint remap in `foliage.gdshader` is gone (the constants and two branches in its vertex
   function); `Models.renew_parked` in main.gd is harmless now.

**Shaders** (exactly): `ground.gdshader` layers 16 (sand: grain and soft drifts, 0.6× at night),
17 (wet bands and rims: vertex colour, grain, 0.6× at night), 18 (foam line: a slow shimmer,
0.32× at night), 19 (tram bed slabs, wet in the rain like the islands); `foliage.gdshader` the
parked-car red remap removed. The water shader (the water branch of `ground.gdshader`) is
unchanged.

**Checks.** `check_drape.gd` (above, both parts; verify step `drape`, ~11 s). `check_roads` C1-C10 unchanged
(all allowed as before), `check_drive` 0 / 0, `check_water` 0 on both city paths, the splash run
towed in 1.00 s. `check_map_data.py` expects `trees3d_crown` (12,554).

**Cost** (`--probe` at 2868×1320, Metal, Mobile, `--controls=classic`, High, Normal traffic, day;
the code before this loop from a copy): draw calls, all passes, spawn 135 → 134 (main 53 → 52,
shadow 35 → 35), the default view over the river 106 → 105, zoomed out 169 → 169, helicopter
223 → 223; main-pass triangles 0.23 → 0.23 M at the spawn, 0.18 → 0.18 M over the river, 0.36 →
0.37 M zoomed out. No new material, mesh or draw call: everything new is in the ground's tile
meshes. Vertices 6,111,678 → 6,119,007 (+0.1 %: meshes 3,766,836 → 3,774,165; the areas on the
grid's triangles took ~370 k off, the footways, cycle paths and steps on them put it back;
instances unchanged). `city.scn` 36.4 → 37.1 MB. The runtime city build 8.2-8.4 → ~10.7 s (the
clipping to the grid), the prebuilt city (the phone) loads in 0.9 s as before. Scripts: one
`kerb_feel` call per physics frame for the player's car (a cell lookup and a few segment tests).

Shots: `shots/loop3b2/` (gitignored), `*_before_*` from the code before this loop and
`*_after_*`, at 2868×1320 and 1792×828: the Praga beach by day and night (`beach_*`, and
prebuilt; `*_v1regressed_*` the first version with the pale bands and the dashed footpath), a
park footway on the grid's folds by the Bulwary (`footway_bulwary_after`), the Bulwary by day and night (`bulwary_*`, night prebuilt), the sandbars by Most
Poniatowskiego (`poni_river_day*`, and prebuilt), Marszałkowska (trees, tram bed), Rondo
Dmowskiego (`rondo_day*`, `rondo_top*`, and prebuilt), a chevron area (`chevron_day`), a kerbed
island (`island_day`), the bridge deck close up (`deckgap_*`); overlays `ov_banks_overview.png`
(built red, sandy yellow, green lime, sandbars pink), `ov_rondo_markings_after.png`.

What only the phone can tell: whether the kerb bump reads (and is not annoying) under a finger,
whether the 1-px foam line survives the 2× pixel on the iPhone 11, and whether the spiral reads
at the default view.

## Loop G1: device tiers and the frame governor (2026-10-28)

The iPhone 11 (`iPhone12,1`, A13, 1792×828, 60 Hz) is the minimum target. Sharp's whole-pixel
rule (`floor(828 / 480)` = 1) gave it the biggest pixel image of any phone, 1792×828 (1.48 MP,
against the Pro Max's 1434×660, 0.95 MP, with about half its GPU), and the orchestrator's first
bench there read 58.2 fps, 1 % low 25.1, worst frame 44 ms (docs/design/graphics.md predicted
it). What changed (`tiers.gd`, `governor.gd`, `main.gd`, `bench.gd`, `settings.gd`,
`settings_panel.gd`):

1. **The pixel image is a budget per level** (`Tiers.image_scale`): the style's own scale, Low
   and Medium one step coarser (as in loop 2b), then coarser until the image fits the level's
   megapixels: High 0.96 (the Pro Max's own image), Medium and Low 0.5, Ultra 1.6. So the iPhone
   11 at High draws 896×414 with High's shadows and effects (and the SE 2 / 3 667×375); every
   phone that already scaled by 2 or more is unchanged (the Pro Max 1434×660, the 6.1" 1266×585),
   and so are all four styles and Low and Medium everywhere (`check_tiers.gd` compares 48 sizes ×
   styles × levels with loop 2b's rule).
2. **Auto and Ultra** (the Quality table above): Auto, the default, picks the level from the model
   id at launch (`Tiers.for_model`); the settings panel's Obraz tab shows Auto (with the level it
   picked under it), Niska, Średnia, Wysoka, Ultra, now in three rows so five choices fit the SE.
   Ultra is High plus the 4096 shadow map and 16 reflection steps, with a budget that keeps a ×1
   image where a phone had one (the iPhone 11's look before G1, for anyone who picks it).
3. **The frame governor** (`governor.gd`, docs/design/graphics.md 4.3): it counts **missed
   refreshes** (each frame's time against the display's clock: a 61 ms frame misses 3, steady
   20 ms frames one in six, a 20 ms frame followed by a 13 ms one none) and, when more than 5 %
   of the refreshes in the last 3 s (and the last half second) were missed, drops one level of
   extras: the CPU's (traffic 100 → 80 → 60 %, pedestrians 100 → 70 → 50 %) when the late
   frames' own CPU work was over 12.5 ms, else the GPU's (reflection steps × 0.6, then the small
   things' sun shadows); it raises the last one back after 30 s with under 0.5 % missed, never
   in a wide view, at most one change every 10 s, the wait doubling (to 240 s) when a drop
   follows a raise within it. It never touches the pixel size, the shadow map, glow, the
   landmarks, the ghost, the river or the night lights. It runs in a normal launch; the bench,
   the probe, the BENCH minute and test runs hold it (`--governor=on|off|log`). Every change is a
   `governor:` line in the log; the overlay's last line shows its levels.
4. **The view rule** (fixed, not adaptive): in a view over 150 m (back under 135 m) or flying,
   the small things' sun shadows are off (lamps, signals, parked cars, columns, shelters: one or
   two pixels wide there): shadow pass −15 draw calls zoomed out (220 m), −11 from the helicopter.
5. **The BENCH card** shows the image and its scale, the quality as `Auto→High (iPhone12,1)`,
   frames **late** more than 1 ms past the frame interval, the **missed refreshes**, and the
   governor's state on the fps-per-10-s line; the log adds loop 2b's measure (0.5 ms past) and
   the late frames by how late, with the slowest and when they came. No rescue call comes in
   during the minute any more: the first call (60 s into play) landed in it and was every card's
   worst frame (61 ms on the iPhone 11, 100–117 ms on the Pro Max).

**On the phones** (started with `devicectl`, no debugger; the bench route's minute, day, traffic
Normal, Point; the iPhone 11 at room temperature, thermal state nominal; before = main at
`6d4629a`):

| Phone, build, quality | Image | fps | 1 % low | Worst frame | Late (> 17.7 ms) | Missed refreshes | > 17.2 ms (loop 2b's measure) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| iPhone 11, before, High (3 runs) | 1792×828 ×1 | 59.9 / 60.0 / 60.0 | 49.6 / 49.4 / 51.3 | 79.4 / 61.0 / 61.6 ms | | (the call's 61 ms frame: ~3) | 6.8 / 13.0 / 6.0 % |
| iPhone 11, after, Auto → High (3 runs) | 896×414 ×2 | 60.0 | 50.3 / 50.2 / 50.2 | 60.8 / 61.5 / 61.1 ms | 1.4 / 1.6 / 1.7 % | 3 (the call) | 7.0 / 7.6 / 7.0 % |
| iPhone 11, after, Auto, call held (final build) | 896×414 ×2 | 60.0 | **56.6** | **18.7 ms** | 0.4 % | **0** | 2.2 % |
| iPhone 11, after, High at ×1 (`--lines=480`, 2 runs) | 1792×828 ×1 | 59.9 | 48.9 / 53.1 | 61.1 / 66.6 ms | 6.3 / 0.1 % | 3 (the call) | 14.7 / 1.0 % |
| iPhone 11, after, High at ×1, 3 minutes, call held | 1792×828 ×1 | 60.0 | 57.2 | 18.0 ms | 0.1 % | 0 | 3.2 % |
| iPhone 11, after, Medium | 896×414 ×2 | 59.9 | 49.4 | 77.7 ms | 2.2 % | 4 (the call) | 3.1 % |
| iPhone 11, after, Ultra | 1792×828 ×1 | 59.9 | 53.0 | 66.7 ms | 0.0 % | 3 (the call) | 1.2 % |
| Pro Max, before, High | 1434×660 ×2 | 59.9 | 47.5 | 117.4 ms | | | 10.0 % |
| Pro Max, after, High | 1434×660 ×2 | 59.9 | 48.7 | 115.8 ms | 0.0 % | 6 (the call) | 5.9 % |
| Pro Max, after, Auto → Ultra | 1434×660 ×2 | 59.9 | 50.1 | 100.6 ms | 0.1 % | 5 (the call) | 2.2 % |
| Pro Max, after, Auto → Ultra, call held (final build) | 1434×660 ×2 | 60.0 | **57.3** | **18.1 ms** | 0.2 % | **0** | 1.5 % |

Probes on the iPhone 11 (30 s standing): helicopter (150 m) before ×1 60.0 fps, 1 % low 58.7,
222 draw calls (shadow 85); after Auto ×2 60.0, 52.9, 0 missed, 211 (shadow 74); zoomed out
(220 m) after 60.0, 58.8, 0 missed, 145 (shadow 45). Video memory: Ultra 360 MB on the Pro Max
against High's 336 (the 4096 map, +24 MB).

**What the numbers say.** A cool iPhone 11 no longer stutters at ×1 on the bench route (the
orchestrator's 25 fps 1 % low didn't come back in nine runs): the 1 % low and the worst frame on
the cards were the first rescue call's hitch and the display's pacing, not the frame. The GPU's
own time says why ×1 is still the wrong default: a Metal System Trace (`xcrun xctrace record
--template 'Metal System Trace' --device ID --all-processes`, 6 s at the spawn) shows the A13
busy **88 % of the time at ×1 (14.5 ms a frame: fragment 12.8, vertex 3.1), in its Medium GPU
performance state 95 % of the time**, and frames spanning 16.25 ms (p90 17.2, worst 21.4) on the
GPU; at ×2 it **sits in its Minimum state 99.9 % of the time** (78 % busy at that clock, frames
spanning 15.1 ms, worst 16.5). So ×1 holds 60 only by clocking the GPU up, with no room left for
heat (the A13 keeps ~76 % of its peak in UL's 20-minute stress test), the content loops (2d,
police) or the G2 per-pixel pack; ×2 holds it at the GPU's lowest clock. On the Pro Max the trace
reads High at the Minimum state 100 % of the time and Ultra 86 % (Medium 14 %): Ultra costs GPU
the Pro Max has. The trace's start stalls the app for ~11 s on iOS 27 (the trace windows were
2–3 s there); attaching by name or pid fails on both phones.

**Pacing modes.** A launch on the iPhone runs in one of two modes: the main thread waits for
the display inside "draw" (11.6 ms of it), and then 1.6–16 % of frames come 1–8 ms late with the
next as much early (every refresh still drawn: 59.95 fps over the minute), or it waits outside
the frame's phases (draw 1.1–1.9 ms) with almost no such jitter. Which one varies by launch at
either image size; ×1 jitters four times as often as ×2 in the first mode. That is why the card
counts missed refreshes and the governor reads only those: a governor on "frames over 17.7 ms"
would read 1.6 % late at ×2 and never come back up (it raises under 0.5 %).

**The governor on the phone** (`--notitle --free --governor=log --stress=wait:40
--stress-from=15 --stress-to=35`: 20 ms of waiting in the draw phase from 15 to 35 s): dropped
the GPU's level 0.8 s after the load began (7.1 % missed) and again 10 s later (25 %), none once
the load ended, then raised them back at 64.9 s and 95.0 s (0.28 % and 0.17 % missed over 30 s).
On the Mac the same. In ten minutes of calm frames, or of the display's jitter, it changes
nothing (`check_governor.gd`).

**On the Mac** (M4 Pro, Metal Mobile, the four budget views at 2868×1320, before → after, High):
draw calls spawn 3D 53 / shadow 35, river 36 / 24 unchanged (the 2D pass moves ±5 with what the
HUD shows); zoomed out shadow 59 → 44, helicopter 87 → 76 (the view rule). Bench (three
interleaved runs each, uncapped): traffic + trams + people 0.48 / 0.50 / 0.55 → 0.45 / 0.51 /
0.45 ms, the game loop (the governor's per-frame work is inside it) 0.08 / 0.08 / 0.07 → 0.06 /
0.09 / 0.06 ms. At High the Pro Max's image is pixel for pixel the same (0.00–0.01 % of pixels
differ at the spawn by day, by night and over the river at night); from the helicopter 0.39 %
(the small things' shadows). Ultra against High: 2.5 % by day, all on shadow edges (the 4096
map's finer texels), 0.23 % over the river at night (16 reflection steps), 0.01 % at night.

Screenshots: `shots/g1/` (1792×828 before / after Auto, 2868×1320 before / High / Auto→Ultra and
2532×1170 before / after, day, night, the river at night, the helicopter; the Obraz tab at
1792×828 and on the SE; the overlay).

## Loop G1b: a sharp picture with a fallback (2026-10-29)

The user's decision after the iPhone 11 before/after crops: the iPhone 11 gets the **sharp**
picture by default, with a fallback. G1 gave it High's 0.96 MP budget, so Sharp's ×1 (1792×828)
became ×2 (896×414); a cool iPhone 11 holds ×1 (G1's 3 minutes: 0 missed refreshes) but with the
A13 88 % busy in its Medium GPU state, and the governor never changes the pixel size live. What
changed (`tiers.gd`, `governor.gd`, `settings.gd`, `main.gd`'s quality and image code,
`settings_panel.gd`; docs/design/graphics.md 4.5):

1. **Auto starts sharp** (`Tiers.budget_binds`, `auto_scale`): under Auto, where the level's
   budget makes the image coarser than the style's own scale, Auto draws the style's own scale
   with that level's effects ("High ×1": not Ultra's 4096 shadows or 16 reflection steps). On
   the phones that is only High with Sharp on the iPhone 11 (`iPhone12,1`, 1792×828) and the SE
   2 / 3 (`iPhone12,8`, `iPhone14,6`, 1334×750); the iPhone 8 and the XR have those screens but
   Low / Medium (already ×2 by their step); every other phone and style has one scale either way
   (`check_tiers.gd` walks all 40 iPhone ids × 4 styles). Mac windows under 960 lines over
   0.96 MP (1366×768, 1440×900, the shots' 1792×828) are sharp too. Manual levels keep G1's rule
   (Wysoka ×2 on the iPhone 11, Ultra ×1); the Pro Max is Auto→Ultra ×2 as before.
2. **Struggled**, from the governor's own data (`governor.gd`'s session **tally**, counted only at
   Auto's image, past the 5 s settle after a start, a load or a pause, outside wide views and
   the helicopter): the GPU's extras dropped by a **GPU-bound** load for 60 s in all and a tenth
   of the counted play (one drop that a calm half minute undoes is 30 s, a passing load; a
   second, or one that didn't calm the frames, is the image; a 15-minute drive needs 90 s), or
   **3 counted minutes in a row** missing over 2 % of their refreshes GPU-bound (a steady loss
   under the governor's 5 % drop line). CPU-bound misses don't count, nor a GPU drop a CPU-bound
   load made once the CPU's extras were gone. **Calm**: 3 minutes counted without that. The
   verdict is written the moment it is known (iOS kills a backgrounded app without notice).
3. **The fallback and coming back** (`Tiers.sharp_*`, kept in `settings.cfg` `[auto_image]`):
   after a struggle the next launches draw the level's budget (×2); 2 calm sessions there bring
   the sharp image back on trial; a struggle on trial doubles the wait (2 → 4 → 8 → 16, capped),
   a passed trial (as many calm sessions as the wait) puts it back to 2, a struggle at the
   fallback restarts its count. A phone that struggled on one hot day is sharp again a day or
   two later; one that can't hold ×1 spends one launch in 17 on it once capped, with the governor
   guarding that one. The switch is per launch, never live.
4. **Never written** by `--nosave`, test runs (bench, probe, autopilot, shots) or
   `--last-session=struggled|calm` (start as if the last session struggled / was calm). The log's
   `quality:` lines say what Auto picked and why (`quality: Auto→High ×1 sharp (iPhone12,1) ·
   image 1792x828`; `quality: Auto→High ×2 fallback (last session: GPU extras down 74 s of 410) ·
   iPhone12,1 · the sharp image again after 2 calm sessions (0 so far) · image 896x414`) and the
   session's verdict (`quality: this session at High ×1 sharp was calm · tally …`).
   `--governor=log` adds the tally to its status lines and a `governor minute N:` line a minute.
5. **Where the player sees it**: Settings → Obraz's Auto button `auto · High ostry` / `auto · High
   ×2` (`auto · High` where the budget doesn't bind, e.g. the Fine style), kept up to date when the
   style changes; the overlay's last line `High ×1 sharp · gov …` / `High ×2 fallback · gov …`; the
   BENCH card `quality Auto→High sharp (iPhone12,1)` / `Auto→High fallback (iPhone12,1)` beside
   its `image 1792x828 (×1)`. Since 2026-10-30 the first launch at the fallback after a struggle
   at the sharp image also shows a toast once, when the city shows: `Obraz prostszy, żeby było
   płynnie` · `A coarser picture for a smoother ride · Settings → Obraz` (`main.gd`
   `_fallback_toast`; the state's `told` key, false after that struggle, true once shown and
   saved at once; never in `--shots=` runs; the log says `quality: the fallback's toast shown`).
6. **Thermal state**: still not readable from Godot 4.7.2 (no OS, DisplayServer, Engine,
   RenderingServer or Performance method), so it isn't part of the rule.

**On the iPhone 11** (iOS 26.5, started with `devicectl`, no debugger, day, traffic Normal, Point,
`--nosave`: the phone's own settings and save untouched; in run order):

| Run | Image | fps | 1 % low | Worst frame | Late (> 17.7 ms) | Missed refreshes | Governor |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BENCH minute at Auto (`--bench-button`), phone cool | 1792×828 ×1 sharp | 60.0 | 54.4 | 19.0 ms | 3.7 % | **0** | held |
| 15-minute drive, Auto, `--autopilot --governor=log` (17.7 min, 1062 s counted) | 1792×828 ×1 sharp | **60.0 every minute** (17 of 17) | | | | **5 of 63,728** (all in minute 1; 1 GPU-bound) | on: **0 changes**; calm at 180 s; the struggle rule never close (0 s down, no bad minute) |
| BENCH minute, `--last-session=struggled` (forced), after the drive | 896×414 ×2 fallback | 60.0 | 56.9 | 18.6 ms | 0.3 % | 0 | held |
| BENCH minute at Auto, final build, after both (phone warm) | 1792×828 ×1 sharp | 60.0 | 58.7 | 17.1 ms | 0.0 % | 0 | held |

The drive's per-minute lines (fps, missed refreshes, GPU-bound, GPU extras down) are 60.0 / 0 / 0
/ 0 s in every minute from 2 to 17 (minute 1: 5 missed, the arrival). Draw calls on the BENCH
cards 124 / 125 (main 45, shadow 41), as in G1; video memory 307 MB at ×1 against 276 at ×2. So
a room-temperature iPhone 11 drives 17 minutes of day traffic at ×1 without the governor
stepping in: the first data point for graphics.md's G0 soak (still to do: night, rain at night,
the 20-minute H3 bar, a warm room). The 1 % low and "late" on the first card are the display's
pacing mode (late frames with no refresh missed, Loop G1 "Pacing modes"), not the frame.

**On the Mac** (M4 Pro, Metal Mobile, `--bench` at 2868×1320, 3 runs each, before = `613ff38`):
the change adds no geometry, materials or draw calls (116–120 before, 116–118 after: traffic
varies); scripts 0.86 / 0.85 / 0.92 → 0.95 / 0.84 / 0.84 ms, the game loop (the governor and
the tally inside it) 0.11 / 0.11 / 0.14 → 0.16 / 0.12 / 0.13 ms, within the runs' spread (the
before runs came after the after runs, not interleaved). Per frame the tally adds a comparison
in `frame()` and a few additions in `tick()`; the verdict check is two booleans until a verdict
is due; a `minute` line is built once a minute.

Screenshots: `shots/g1b/` (the Obraz tab at 1792×828 at Auto sharp, `auto · High ostry`, and in
the forced fallback, `auto · High ×2`, with the ×2 city behind it).

## Loop 3g-1: the police, part one (2026-10-28)

The design is docs/design/police.md (the user chose the gentler police: warnings and jokes,
**never a fine, nothing taken from the wallet**, nobody arrested, nothing rammed, short chases
that end by themselves). Part one builds the patrol cars, the speed traps, the chases and the
pull-over; part two (loop 3g-2) the city guards, the guard car, the pedestrian-zone cap, the
clamp, the escort on rescues, the race and side-job ties, the chase framing (Phantom Camera),
the synthesised sounds and the PixelLab portraits.

**Who.** Patrol cars ("radiowóz": the white estate with the blue band and POLICJA from loop 2c)
drive in the traffic, main and secondary roads only, at most 0 / 1 / 2 / 3 at a time for the
Traffic levels Empty / Low / Normal / Busy (`traffic.gd`'s new POLICE kind). After one you met
leaves, the next comes 90-180 s later (*guess*: a 10-minute drive should meet two to four), after
one you never met 10 s later, and never within 200 m of you in a cooldown. **Speed traps**: the
seven spots of police.md, four of them in today's map (`game/data/police_traps.json`, found by
road name on the lane graph: Aleje Jerozolimskie by the National Museum, the Wisłostrada north
of the cross-city rail bridge, Jana Pawła II south of Rondo ONZ, Wybrzeże Szczecińskie); three
are out each day, picked by the date like the roadworks (`--barriers=YYYYMMDD` picks that day's).
A trap is a patrol car parked on the kerb facing the traffic, lights off, with an officer in
lemon hi-vis 3 m upstream (a pedestrian instance: +0 draw calls). Loop 3d moves the spots into
the bake.

**What they see** (`police.gd`, 5 times a second, every unit in one pass): distance, a 180° cone
in front of a patrol car, and sight along the roof grid (no raycasts); your lane, its speed limit
and the stop lines you cross from the lane graph. Offences: speeding past a patrol car (limit +
25 km/h within 40 m, in its cone), a red light within 60 m in sight, 3 s the wrong way up a
one-way street, bumping a police car (2-6 m/s); a ram (> 6 m/s) counts double. The helicopter is
never an offence; a rescue in pickup or drop-off is never seen.

**What happens** (police.md section 4):

| | Numbers |
| --- | --- |
| A warning | a megaphone bubble ("Policja"), a whoop, the first rooster's outline blinks 2 s, one strike; one fades every 45 s; at most one line every 8 s in the city and 20 s a unit |
| Koguty 1 | two strikes within 45 s, an ignored lizak, or a ram; one chaser, lights and siren on; cap 30 s |
| Koguty 2 / 3 | a ram (once in 10 s) or a second unit seeing you within 60 m (once the level has held 5 s, *guess*): + a blocker parked across the far lane at a junction 250-400 m ahead / + a two-car roadblock in a V at the next junction (a gap in the middle) and, at night, a searchlight; caps 40 / 45 s from the chase's start; no level rises in a cap's last 10 s |
| Chasers | the player's top speed × 0.92, 1.2 × traffic's acceleration, at least 10 m behind you (they never ram; they stop when you stop), through reds at 30 km/h, on the lane graph only (re-planned once a second, one unit a frame, `distances_to(…, 800 m)`; beyond that, the way whose end lies nearest you); cars ahead give way (the kerb lane, 5 m/s for 3 s) |
| Search | 120 m from every chaser, or 4 s out of sight: they drive to where they saw you, then round there; 8 s later (4 s under a bridge deck or in a tunnel) you escaped: +15 respect (`wallet.add_respect`), the toast *UCIECZKA! · ESCAPED!*; seen again within 50 m: back to the chase |
| End of shift | the cap: *KONIEC ZMIANY · END OF SHIFT*, nothing won or lost; taking off in the helicopter ends it too (its own line) |
| Lizak | over the limit + 20 km/h in a trap's 40 m: the officer turns and waves the paddle, two whistles, the pill *ZATRZYMAJ SIĘ PRZY POLICJANCIE*; stop within 20 m of the officer under 8 km/h: the pull-over; 30 m past the officer: koguty 1, the trap's car pulling out; the trap re-arms after 60 s |
| Pull-over | under 1 m/s with a chaser within 15 m (bumper to bumper) for 1.5 s, or the lizak stop: the car is held, the chaser stops behind with its lights on, the radio ducks 6 dB, the pedals step aside for the card; the conversation ends in a caution, one more in the **Zeszyt pouczeń** (the joke notebook in the save, counted per day; the fifth of a day has its own line) |
| Cooldown | 180 s after any of them: warnings still, no chase but for a ram |
| Start grace | no chase in the first 180 s of a session (no warnings at all in the first 60 s), unless the police have already met you |

**The pull-over** is a Dialogue Manager conversation (`game/dialogue/police.dialogue`: only the
flow, compiled at runtime; the words are in `dialogue.json`, picked by `police/police_talk.gd`):
the opener (Sierżant Bogdan, or Posterunkowy Kacper at a trap; tagged for the first contact, a
kebab or słoiki run, a trap, or generic), one or two reply buttons (the first is picked after
5 s), the caution. Every beat can be tapped through; about 7.5 s in all. The card
(`police/police_balloon.gd`) is the HUD's one card recipe: Polish over English, a police-blue
edge, the speaker's face from simple shapes (the PixelLab portraits come in part two).

**On screen** (`hud.gd`): the koguty (three light-bar domes beside the wallet: lit blue and red
in a chase, grey and blinking while searching), the pill with the end-of-shift countdown
(*POŚCIG · KONIEC ZMIANY ZA 0:27*), the edge breath (blue and red at the screen's edges, 10 % at
most, once a second), a rooster at the screen's edge for a chaser out of sight, the lizak paddle
over the officer, chasers and the known traps (after the radio host read them, or once you passed
one) on the minimap. The light bars flash in `actor.gdshader` (SIREN: off, the lenses dim; on,
blue and red in turns at 2.5 Hz, glowing by day too); at night their blue and red pools on the
road and the koguty-3 searchlight are one glow MultiMesh, shown only while a light bar flashes.
The sounds were placeholders here (loop 3g-2 replaced them with its own, from `make_sfx.py`);
the siren plays on one positional voice of the six.

**The add-ons.** beehave (bitbrain, 2.9.3) gives each police unit a behaviour tree
(`police/police_unit.gd`: pull-over, roadblock, blocker, search, chase, trap, patrol), ticked by
hand at 5 Hz right after the perception pass; escalation stays in `police.gd`, the trees only
move their car through the traffic API. Dialogue Manager (Nathan Hoad, 4.1.0) runs the
conversation. Both editor plugins are off: the trees use a lean `police/police_tree.gd` (no
debugger registration, no autoloads); `police.gd` creates Dialogue Manager and has it compile the
`.dialogue` text (~70 ms on the Mac, done while the city builds), and clears a reference cycle
Dialogue Manager 4.1.0 leaves in its resource (it leaked at exit). One local line in beehave: no
debugger messages without a debugger (headless runs printed an ERROR at every tree interrupt).

**Cost** (`--probe` at 2868×1320, Metal, Mobile, Classic, High, Normal traffic; before = the code
at `6d4629a`; "koguty 3" = `--police=3 --police-auto=still`, the chaser standing behind, the
blocker and the roadblock out of sight):

| View | Draw calls, all passes: before → after → koguty 3 | Main / shadow / 2D in koguty 3 (before) |
| --- | --- | --- |
| Spawn | 133 → 133 → 135 | 54 / 36 / 45 (53 / 35 / 45) |
| Default view over the river | 106 → 104 → 109 | 37 / 25 / 47 (36 / 24 / 46) |
| Zoomed out (`--size=220`) | 169 → 167 → 170 | 65 / 60 / 45 (64 / 59 / 46) |
| Helicopter | 223 → 222 → 225 | 100 / 87 / 37 (99 / 86 / 38) |
| Night: spawn / river | 110 / 91 → 107 / 88 → 112 / 94 | the halos +1 while a light bar flashes |

The POLICE MultiMesh is +1 in the main and +1 in the shadow pass (a small caster: none on Medium),
the halos +1 at night while lights flash: at most +3 at every view. The HUD's police shapes are
drawn as one triangle array a surface, and so are the minimap's marks now (they were a draw call
each: the 2D pass fell by 3-4 at every view, which pays for the pill). Triangles: 636 a police
car, at most five drawn in a koguty 3 chase (≤ +3.2 k a pass). Scripts (bench, Mac, three runs
each interleaved, capped at 120 Hz): police 0.03 ms calm, 0.07-0.08 ms in a koguty 3 chase, the
HUD +0.04 ms then; traffic unchanged (0.62-0.65 ms). Memory: +2 MB static, +4 MB more for
Dialogue Manager's scripts (loaded at the start). No new shader.

**Testing aids** (flags in the table below; the log with `--police-log`: `police: warn speed
(unit 2)`, `police: L1 (lizak ignored, 30.4 m past the officer)`, `police: escaped after 16.7 s`,
`police: caution n=1 today`, `police: wallet 0 zł → 0 zł`). `game/tools/check_police.gd`
(verify step `police`): P11, every group and tag in `dialogue.json` with Polish and English and
the lengths (bubbles ≤ 70 characters, replies ≤ 28), the flow compiles; P12, the state machine on
a synthetic road with a stand-in car, traffic, HUD and a wallet that fails on any write but
respect and the notebook (19 cases: grace, strikes, caps, the last-10-s rule, escape, hiding,
seen again, pull-over, cooldown, ram, helicopter, the złoty, starts = ends), and a scan of the
police's code for anything writing the złoty. `police-runs` (P1-P7 on the prebuilt city, each
judged by its `police:` lines and the wallet line) and `police-soak` (P13: the autopilot roaming
Busy traffic at twice the limit with the police on at once; 3 minutes in the verify set, the full
10: `NW_SOAK_MINUTES=10 tools/verify.sh --only=police-soak`, ~70 s).

**The frame governor** (loop G1) lowers the traffic's density when frames are CPU-bound; a police
car is never thinned out for it (`traffic.gd`), and a unit in a chase, a trap or a block is kept
until `police.gd` lets it go. The officers stand in the people's MultiMesh after the walkers'
slots, which the people's limit doesn't touch.

What only the phone can tell: the siren against the radio (a placeholder), how a chase feels at
60 fps (the chasers' 0.92 speed, the 30 km/h at reds, the 10 m gap), whether the edge breath is
too much or too little, whether the light bar reads by day at 80 m on the 2× pixel, and whether
the card's tap-through feels right.

Shots: `shots/loop3g1/` (gitignored), at 2868×1320 and 1792×828: a koguty 2 chase with the HUD by
day and at night (and close: the lenses taking turns, the blue pool at night), the four trap
spots close up, a trap at night, the lizak over the officer, the pull-over card (at a trap, and
the first contact).

## Loop 3g-2: the police, part two (2026-10-30)

Part two of docs/design/police.md (sections 5.6, 8, 10): the rescue escort, the race and side-job
ties, the city guards with the zone cap and the clamp, the scripted first contact, and the
synthesised police sounds. The user's rules hold everywhere: never a fine, nothing taken from the
wallet, chases end by themselves, and the guards never call the police.

**Rescues** (`police.gd`, police.md 8.1). On a rescue's pickup and drop-off the police see
nothing and start nothing (`police: speed seen, on a rescue (nothing)`); a trap's lizak isn't
waved. Accepting a rescue during a chase ends the chase (`missions.gd`'s new `accepted` signal):
the toast *POLICJA ODPUSZCZA: RATUJESZ KOGOŚ · THE POLICE BACK OFF: YOU'RE ON A RESCUE*, then the
usual 180 s cooldown. **The escort**: once the person is aboard, the nearest patrol car within
200 m joins, or one is placed out of sight 150-400 m ahead on the way to the hospital (always on a
session's first rescue, then one rescue in two, *guess*). It adds 10 s to the rescue clock
(`missions.add_time`; the pill *ESKORTA · +10 S · ESCORT · +10 S*), whoops once, says its
`police_escort` line and leads with lights and siren along the route (the hospital's lane-graph
node, its `distances_to` cached by node like the rivals' finishes): 15-25 m ahead of you along the
route, at 45 km/h (`ESCORT_PACE`, *guess*) or a little over your speed, faster when you close in
under 15 m, slower when you drop past 25 m; it stops and waits while you are more than 60 m
behind, and when you overtake it (4 m, held 1 s) it follows behind until you let it lead again.
It waits at the route's end (it drives like a chaser and never "arrives") and, when the rescue
ends, turns its lights off and goes back to patrolling (`police: escort left (at the hospital)`).
No escort in the helicopter (taking off sends it away).

**Races and side jobs** (8.2, 8.3). A race seen by a patrol or a trap's car within 60 m pulls in
koguty 1 (after the start grace and the cooldown, like any chase). Escaping the police during the
race marks it (`police: race marked +20 % for the escape`): a win then pays the stake × 1.2
(`rivals.gd`, `ESCAPE_BONUS`) with *· +20 % ZA UCIECZKĘ · +20 % FOR THE ESCAPE* inside the result
card's stake line. The kebab's heat stands still while the pull-over card is open (`jobs.gd`'s
`heat_frozen`; `police: kebab heat frozen at 100 %` / `runs again`); the słoiki are untouched. A
Podwózka passenger still takes one star for a pull-over (`rides.on_pulled_over()`, wired in 3g-1);
the first contact's routine check takes none.

**The city guards** (Straż Miejska, 5.6; `police/guards.gd`, `police/guard_unit.gd`, posts in
`game/data/police_guards.json` until loop 3d's `guard_post` POIs): two guards at each of four posts
(the car-free end of Krakowskie Przedmieście, Plac Zamkowy, the Rynek, Nowomiejska by the
Barbakan), in mustard jackets and dark trousers, drawn as fixed people in the pedestrians'
MultiMesh (`pedestrians.gd` set_fixed, slots 4-11 of `FIXED` 12: **+0 draw calls**). Up to 8 are
staffed within 300 m of you (out of sight; let go past 360 m), and the 6 nearest within 150 m tick
their beehave tree at 5 Hz (clamp → walk to the car; run → after the car at 5 m/s; talk → face the
car; else back to the post at a walk and stand facing the street). Their legs keep the walkers'
swing (a standing pose needs a new constant and a branch in `actor.gdshader`: the visuals lane).
- **The zone cap**: inside a pedestrian-zone polygon (`ped_zones.gd`, loop 3d-1) the car's gas is
  capped at 20 km/h through the existing `car.zone_cap` hook (no change to `car.gd`; a faster car
  coasts down to it), with the pill *STREFA PIESZA · 20 KM/H · PEDESTRIAN ZONE · 20 KM/H*.
  **Off by default since F's asks (2026-10-30)**: Settings → Jazda → *Strefy piesze 20 km/h ·
  Pedestrian zones 20 km/h* (Wył. / Wł., saved as `[game] zone_cap` in settings.gd; `--zone-cap` /
  `--no-zone-cap` for one run). Off: no cap, no pill, no whistle, run or guards' car (main.gd
  stops setting `car.zone_cap`; police.gd / guards.gd `zone_cap`); the guards still stand at their
  posts, the guard conversation and the clamp are unchanged; the `zone:` log line says
  `(no cap)`.
- **The whistle** (only with the zone switch on): moving in a zone with a guard within 60 m (once a zone a minute): the whistle,
  the guard's line (`guard`, tagged `oldtown` on the Rynek and Barbakan posts, the deptak line
  elsewhere), the guard runs after the car for 3 s, gives up with the `run` line. **The guards'
  car** (one at a time, the police mesh's shape 1, spawned out of sight 150-300 m away near a post)
  follows a whistle within 400 m at most 25 km/h with its amber beacon for 15 s, then turns away
  (lights off, the traffic's pace). Guards never start a strike, a chase or a call to the police.
- **The guard conversation**: stopping (under 1 m/s, 1.5 s) within 10 m of a guard opens the card
  (`police.dialogue`'s `~ guard_stop`: Strażnik Henio's line, one reply, the caution in the joke
  notebook); no cooldown after it; that guard waits 60 s before the next talk.
- **The clamp**: parked (under 0.5 m/s) 20 s on a footway or in a zone within 30 m of a guard: the
  guard walks over (the `clamp` line, a scribble), the pill *BLOKADA ZA 0:10 · CLAMP IN 0:10*
  counts down 10 s (driving off drops it), then the clamp goes on (a clank, a yellow box on the
  front left wheel, +1 draw call while shown) and holds the car 10 s under the card *BLOKADA NA
  KOLE · ZDEJMUJĘ ZA 0:10 · WHEEL CLAMP ON · OFF IN 0:10* with *Przepraszam · Sorry*, which takes it
  off at once.

**The first contact** (police.md 7.2): 6 s after the first race of a save ends, a patrol car is
parked by the kerb 150 m ahead on your road with an officer, who waves the lizak whatever your
speed: stopping opens the `routine` conversation; driving on starts koguty 1 like a trap. Either
way it is marked in the save (`wallet.keep["police_first_contact"]`) and never comes again; a
setup you drive away from (450 m) or that takes over 90 s is tried again 20 s later (4 tries).

**Sounds** (`tools/make_sfx.py`, all procedural, levels matched to the set): `police_siren` (the
two-tone, a seamless 1 s loop on the positional siren voice), `police_whoop`, `megaphone` (the
chirp before "Policja"), `whistle` (two short blasts), `scribble`, `stamp`, `clank` (the clamp).
They replace 3g-1's placeholders; the files already there are byte-identical.

**Cost** (Linux container: headless bench, `--fixed-fps 60`, two runs each interleaved, before =
the code at `8660ec4`; rendered with the software Vulkan driver at 1280×720, so draw calls only):

| | Before | After |
| --- | --- | --- |
| Police scripts, bench route (calm) | 0.06 ms | 0.09-0.10 ms |
| Police scripts, koguty 3 (`--police=3 --police-auto=still`) | 0.19-0.21 ms | 0.23-0.25 ms |
| Draw calls, bench route (main / shadow / 2D) | 114 (47 / 34 / 33) | 114 (47 / 35 / 33) |
| Draw calls, Plac Zamkowy probe (`--probe --at=-700,-1480`) | 106 (45 / 28 / 33) | 109 (46 / 28 / 36) |

The guards are +0 (fixed people in the walkers' MultiMesh: +40 instances in the probe); at Plac
Zamkowy the zone pill is +3 2D draws (a panel and two labels, as in 3g-1) and the guards' car +1 in
the main pass (the POLICE MultiMesh, out by then). The clamp box is +1 while shown. The container
runs 3g-1's scripts at about twice the Mac's times (0.06 here, 0.03 there), so the koguty 3 chase
should stay near 0.10 ms on the Mac, under police.md 12's 0.15 ms; the per-frame guard work is
~0.02 ms (the footway lookup runs only for a car stopped by a guard). No new shader or material.

**Testing aids** (flags in the table below; `--police-log` adds `guard: …` lines:
`guard: whistle (post kp_gate_1, 13 m, 26 km/h)`, `guard: clamp on (10.0 s after the countdown
began)`, `police: escort joined (unit 8, placed 150 m ahead …; rescue clock +10 s …)`).
`check_police.gd` adds P14, part two on the synthetic road (25 cases: rescue sees nothing, a
rescue ends a chase, the escort placed / joining a patrol / lights and route / waiting / leading /
pace / overtaken / leaving / not in the helicopter, a race seen, +20 %, the kebab's heat frozen, the
zone pill and cap, the guard's 3 s run, the guard car's 15 s at 25 km/h, guards never chase, the
clamp's 20 / 10 / 10 s and Przepraszam, the first contact once, the złoty), the new lines and the
guard cues; it now fails when no case ran. `police-runs` adds a second row, "police part two"
(the escort on rescue 9, `--guards`, `--guards=talk`, `--clamp`, `--clamp=sorry`, the first
contact, `--pullover=kebab` with a kebab order, a race's escape).

What only the phone can tell: the siren and whoop against the radio, whether 45 km/h feels like an
escort or a crawl in Normal traffic, whether the guards read as guards at 80 m (mustard on the 2×
pixel), whether the clamp box is visible at the default zoom, and how the 20 km/h zone feels.

Shots (scratch, not committed): the escort leading on rescue 9, a guard whistling on the
Krakowskie Przedmieście deptak with the zone pill, the clamp card on Plac Zamkowy, at 2532×1170
and 2868×1320.

## Sectors and streaming (loop 3c, 2026-10-29)

The city is built and loaded in 512 m sectors (docs/DEMO.md 2.4), keyed `floor(x / 512),
floor(z / 512)` from the map's origin: today's map is 8 × 4 = 32 of them (i −4..3, j −2..1).
The demo's bigger box (loop 3d) only adds sectors.

- **The split** (`tools/bake_sectors.py`, after the bake chain, ~1 s): `game/map/index.json` holds
  what the whole map needs at once (the lane graph, decks, approaches, aprons and tunnels, the
  water's edge, the kerbs and islands the car feels, the points of interest and addresses, the
  landmark outlines and `site_parts`, and what traffic, trams, people, missions, the minimap and
  the easter eggs read: roads, paths, areas, trams, platforms, signals, guard rails, columns,
  parked cars, scanned trees), and `sectors/<i>_<j>.json` each sector's features in
  centrum.json's shape: every way, area or building within 48 m of the sector, with its full
  geometry (a way crossing a border is in both), every point thing within 8 m, a floating
  part's supports, each building's surroundings for its shop sign (roads within 40 m, roofs
  within 8 m), the LoD2 buildings near it (`lod2_runs`: vertex ranges of `lod2.bin`). Loop 3d-2b:
  the AO, lamp-light and surface maps travel with the sectors as slices (see below).
- **One sector** (`map_builder.gd` `build_sector`) runs the same stages as the whole city over its
  file and keeps only the triangles (by their centre, so each 256 m tile is in exactly one
  sector), MultiMesh instances (by position, 512 m tiles = sectors) and collider faces (by centre)
  that lie in it, and its cells of the roof and picking grids. `build` (the whole city at once,
  `--monolithic`) is unchanged. **The sectors together are the whole city exactly**:
  `game/tools/check_streaming.gd` compares every tile mesh's vertices, every MultiMesh's instances,
  every collider face, the roof and picking grids and the landmark cards (559 meshes and
  MultiMeshes, 232,521 faces: identical).
- **The prebuilt city** (`tools/bake_city.gd`, with a renderer, ~16 s): `sectors/s_<i>_<j>.scn`
  (28.8 MB for 32), `proxies.scn` (2.7 MB), `index.res` (2.3 MB: the map node with its heights,
  decks, tunnels, water test, roof and picking grids, kerbs, sector heights and the game's part of
  the index) and `shared/*.res` (6 MB: the materials, textures and meshes every sector shares,
  saved once so all sectors use one copy and the per-frame uniforms reach them all).
- **Proxies** (`sector_proxies.gd`): one mesh and one material per sector from the index alone:
  the ground as a 32 m grid coloured by what covers it, the main roads as strips, the buildings
  and landmarks as a skyline of boxes from the roof grid (8 m, merged into rectangles; since the
  loading fix in each building's own roof and wall colours, noted while the sectors are built),
  trees as blobs per 24 m in the season's leaf colours; at most 15,000 triangles a sector, no
  shadows, visibility range 2,400 m with fade Disabled. A sector's proxy shows only while the
  sector is not in full detail (`--sectors=proxies` to see them).
- **The streamer** (`sector_streamer.gd`): full detail for the 3 × 3 round the camera's focus,
  the next row once the focus is within 192 m of its sector's edge (a square of 704 m round the
  focus), and every sector the view needs (its box from its lowest ground to its tallest roof,
  grown by 128 m, meets the camera's frustum: a tower two sectors off can stand in the view);
  out again 256 m past that (and out of the view grown by 256 m). One sector at a time, a
  thread loads and instantiates its scene (runtime path: builds it from its file); the main thread
  adds its nodes under a hidden root a few a frame (each kind's recent cost must still fit the
  frame's 3 ms), colliders first, and shows it (hiding the proxy) once all are in; the next load
  starts after that. The car's own sector and any within 40 m of it load at once if a jump put
  the car somewhere new (`forced`; the governor counts afresh after one). At the start the
  sectors within 320 m of the start go in at once, the rest of the ring streams in.
- **Both city paths**: the exported game and `--prebuilt` load the prebuilt sectors; the editor
  (runtime) path sets up the index from `index.json`, runs a roof pass over every sector's file
  (missions, eggs and the helicopter read the roof grid over the whole map at the start) and
  builds the sectors round the start, then the rest on a thread as the camera moves.
- **What the game's systems see**: the map node is the same object as before (heights,
  `drive_height`, the water test, `top_height`, the pick grid are global); traffic, rivals and
  missions live on the global lane graph; new sectors get the time of day, the quality's and the
  governor's small-caster shadows, the fine detail and `--exp` from main.gd (`_on_sector_ready`).
  The minimap stays one global mesh (today's map is small; loop 3d's pre-rendered image waits).
- **The AO, lamp-light and surface maps** (loop 3d-2b, "Loop 3d-2b" below): each sector carries
  its slices (the whole map's texels over the sector and 2 round it) and puts them into a slot of
  three texture arrays when it comes in (`city_maps.gd`); every shader reads them by world
  position through a one-texel-per-sector table (`city_maps.gdshaderinc`), the vehicles and the
  post pass included. Before, they were one texture each over the whole map (93 MB on the demo
  map).

| Loop 3c numbers (Mac, Metal, mobile renderer) | Before (monolithic `city.scn`) | After (streamed) |
| --- | --- | --- |
| Pixel diff, 10 spots at 2868×1320 (5 on borders), `--monolithic` vs prebuilt streamed | | at most 0.015 % of the pixels (the minimap's random markers); 3D view identical |
| Draw calls at the four probe views (3D + shadow): spawn, river, zoomed out, helicopter | 89, 61, 109, 175 | 87, 59, 108, 174 |
| Memory at the spawn (probe): static / video | 140 / 336 MB | 140 / 263 MB (−22 % video; the city's own buffers 158 → 86 MB) |
| Start, runtime path (`city built`, 3 runs) | 11.0, 10.9, 10.9 s | 5.99, 5.73, 5.75 s (2.0 s of it the roof pass over every sector) |
| Start, prebuilt path (3 runs) | 1.07, 1.07, 1.04 s | 0.61, 0.57, 0.58 s |
| Exported .pck | 47.3 MB (city.scn 37.1 + centrum.json 5.3) | 46.5 MB (sectors 28.8, shared 6.0, proxies 2.7, index 2.3; no JSON); 47.2 MB with loop 3g-1 merged |

Commands: `tools/verify.sh --only=streaming` (the identity, the pixels at 10 spots and a
3-minute soak, ~2-4 min, a window opens); the 15-minute soak:
`godot --path game --resolution 1280x720 --script res://tools/check_streaming.gd -- --only=soak --soak=15`.
On the phone (loop G0+): `tools/device_run.sh --label=stream_soak --wait=600 --done='^stream soak
stats:' -- --notitle --prebuilt --stream-soak=6 --stream-log` (each load's main-thread ms and the
soak's numbers; see Loop G0+ for the phone's).

## Map review A: the bridges, flyovers and tunnels (2026-10-29)

Every deck group (19: 73 pieces, 174 piers), the 3 tunnel roads and their 4 portals looked at
one by one at 1792×828 by day (both ends, the span from the side, from above), the lit ones by
night, and driven. What was wrong and is fixed, all in the bakes (no builder change):

- **A kerb and an edge line across the road at a deck's joint** (`bake_roads.bake_edges`, new
  `JOINT_ALONG` / `JOINT_SIDE`): where a deck's carriageway meets the next one across its pinned
  end, each side saw only its own level's road beyond it and ran a kerb and an edge line across
  the carriageway (Most Poniatowskiego's east end on both carriageways, its Praga ramps, the
  viaduct's west end, the Jana Pawła II viaduct's north end: 9 kerb runs, 49 m). It read as a
  stop line, and the ground side's kerb was in `kerb_feel`'s lines, so the car took a kerb's
  bump driving onto the bridge. Now open (135 m of joint).
- **A footbridge lying across Al. Jerozolimskie** at the viaduct's west end (`UNDER_END` in
  `solve_decks`): a footway bridge mapped on a lower layer (OSM 1172263249, layer 0) crossing
  a road deck within 15 m of its pinned end was held up to the road's height and drawn across
  the carriageway (a paving strip, parapet stubs and their shadow). It stays on the ground,
  where the road hides it.
- **Tram stop shelters on the tracks** (`bake_structures.clear_carriageways`): 14 shelters
  mapped at a stop's position on the rails (one on the viaduct's tram deck at its east end) are
  left out where the track runs at the ground's height.
- **Tree crowns through a deck's edge** (`bake_structures.trim_crowns`): 7 scanned trees beside
  the viaduct, Most Poniatowskiego and Most Średnicowy reached 2-11 m up through the deck's edge;
  their crown scale (`trees3d_crown`) shrinks until they clear the slab (floor 40 %; one 24 m
  tree on the Praga bank still brushes the footway, allowed). A crown over a deck higher than
  the head room (3.5 m, footways 2.5 m) stays.

`check_roads.py`: **C2** also finds a kerb or edge line across the road at a deck's joint with
the ground (3 m or more within 4 m of the end; 12 before, 1 allowed sliver after), **C9** a
scanned crown into a deck (7 before, 1 allowed after); a C3 entry allows the passage under the
viaduct's west end (0.8-2.2 m under the decks' first metres). `check_drive` 0 / 0,
`check_drape` 0. Draw calls at the four views unchanged in the 3D passes (spawn 132 → 134, the
2 in the HUD's 2D pass; river 105 → 105, zoomed out 152 → 154 (2D), helicopter 212 → 212);
vertices 6,119,007 → 6,115,605. Left for later (BACKLOG "From map review A"): aprons that sink
the road under the drawn 10 m ground at five structure ends (the beige wedge at the viaduct's
west end), the night's lamp pools on the ground beside and under decks, Most Poniatowskiego's
unlit approaches, rail tracks ending at different heights, the Tamka footbridge's dip.

## Map review B: the streets (2026-10-29)

Every street at grade, junction and roundabout looked at one by one (the bridges, flyovers, ramps
and tunnels are map review A's). The report with the shots is local (`.handoff/review/`); what
changed in the bake (`tools/bake_roads.py`, street-level functions in a commented block, run by
`bake_osm.py`), each counted over the whole map by the new `tools/check_streets.py` (verify step
`streets`; rules S1-S4, before → after):

- **Junction boxes between dual carriageways** (`Roadbed._junction_boxes`). Where two dual
  carriageways cross, OpenStreetMap maps the halves and leaves the junction's middle unmapped:
  `bake_medians` laid the tram bed (or grass) and its kerb across the junction, and the halves'
  short pieces inside it got lane lines. The quadrilateral where the halves cross is now a
  junction box (a carriageway area with `jn`: no median, no kerb, no lane lines in it): 3 on
  today's map (Al. Jerozolimskie × Emilii Plater, Marszałkowska × Królewska, Świętokrzyska ×
  Emilii Plater). S3 (medians inside a junction, reported only: it also counts real median noses
  at a junction's edge) 20 → 18.
- **Tram beds, not grass** (`bake_medians`): a median is the tram bed when a track runs anywhere
  across it (it looked only at the strip's middle, which a double track straddles): Al.
  Poniatowskiego's tram bed was raised grass with rails on it. S4 (grass medians on tram tracks)
  78 cross-sections → 0; median strips 137 → 134 (48 → 54 with trams).
- **Zebras on the asphalt only** (`clip_crossings`): crossing ways run from pavement to pavement
  and the road's width is an estimate, so the stripes ran on over the kerb, the pavement, tram
  beds and medians (1.0 m an end on average). The stripes are now cut to the carriageway (a red
  cycle path across the road keeps them), pieces under 1.5 m left out: 5,371 → 3,654 m of zebra.
  S2 (zebras with 0.75 m or more off the asphalt) 457 → 0.
- **Poles off the asphalt** (`clear_poles`): a street lamp mapped in a median the bake doesn't
  draw, or a signal pole placed beside the kerb of a width estimate, stood in a lane or a
  junction; each one on the ground's asphalt moves to the nearest spot within 6 m that is 0.5 m
  off it (pavement, island, median, clear of the tracks). 60 moved (the signals keep their order:
  the lane graph's `poles` refer to them by index). S1 58 → 0.

Unchanged: `check_roads` C1-C10, `check_drive`, `check_drape`, the lane graph, stop lines, arrows
and the counts `check_map_data.py` checks. Draw calls at the four probe views unchanged in the 3D
passes (spawn 52 + 35, river 35 + 24, zoomed out 65 + 44, helicopter 100 + 76; the 2D pass moves
by ±4 between runs of the same code), vertices 6,119,007 → 6,109,860 (-0.1 %: shorter zebras).

## Loop 2d-1: Podwózka, the app-taxi side job (2026-10-29)

*Podwózka* ("a lift") is the game's own app-taxi (docs/design/parodies.md section 3; no real app,
name or logo). The joke is the app and its GPS, never the driver or the passenger. Code:
`rides.gd` (the job), `ride_rules.gd` (the stars, the pay and the cards' words as plain rules),
`gps_moments.gd` (the app-taxis in traffic); lines in `data/dialogue.json` (`podwozka_*`).

- **How it's offered**: in the car with nothing else on (one activity at a time, like the kebab
  and słoiki jobs), never in the first 2 minutes of a session (the title screen doesn't count).
  A request card every 75–120 s (not modal; it goes after 10 s), or the top row's
  context button reads **PODWÓZKA · ride app** and a tap brings a request within 2 s. A rescue
  call ringing keeps the button (WEZWANIE) but not the card; taking a ride puts the call off, as
  any job does. Never during a race, a rescue or from the helicopter.
- **The request card** stands beside the car, never over it (`hud.gd` `show_side_card`: the
  right-hand column under the top row, as wide as the room right of the car's spot): `PODWÓZKA ·
  NOWY KURS` (at night `PODWÓZKA · MNOŻNIK ×1,5`, ×1,2 in the rain, ×1,8 both; the English in
  the title row says why), the passenger and their own stars, how far the pin is and the ride's
  length (`Kasia ★ 4,9 · 350 m · 1,8 km`), their note (`podwozka_request`) with its English;
  PRZYJMIJ · Accept, POMIŃ · Skip (M / K). Your rating is on the result card (on a 390-pt phone
  the request card has room for five lines of text beside the car).
- **Pickup**: the app's pin (a teal ring and column, the minimap dot and a dotted teal line) at a
  real address door 150–600 m by road. Half the time the passenger isn't there: they wait 30–60 m
  away along the street or across it, waving under a teal "!" (one mesh each), and say a
  `podwozka_pickup` line; near the pin the hint says "the pin is here, the passenger isn't" and
  the arrow turns to them. Stop within 7 m under 2.5 m/s for 1 s.
- **Passengers** (*guess*): normal 65 %, GPS believer 25 %, in a hurry 10 % (ETA × 0.8, tip ×
  1.2); first names from the jobs' list; they chat every 25–40 s (`podwozka_passenger`, half the
  time the słoiki passengers' `passenger` lines).
- **Where to**: a real address 600–2,500 m by road (west bank), or (30 %) a race finish (not the
  far end of a bridge, not one on the map's edge: Centrum Nauki Kopernik's lies on it). The beacon
  and the arrow always point at the real door.
- **The app's route** is the minimap's dotted teal line: the shortest road, except that 35 %
  of rides get one quirk, which "Nawigacja" announces 200 m before it (`podwozka_gps`):
  - `river`: out to the Vistula's edge and back. River spots come from the map's global water
    test (loop 3c: the streamed city's exported index has no shore runs): `shore_distance` on an
    8 m grid over the map, 3 rows a frame after the city is built (~48 ms in all), each dry-to-wet
    step a point on the edge; the water past it still deep 60 m out (the river, not a pond or a
    fountain), a waypoint 5 m in from the edge with no water within 3 m and no roof over it, a
    road within 70 m in a straight line over dry, open ground; one spot per road edge, both
    carriageways (9 on today's map, by Most Poniatowskiego and along Wybrzeże Kościuszkowskie,
    the same on both city paths). The ride takes the spot that adds least, at most 1.5 km.
  - `zone`: through a park's middle (in from the road on the passenger's side, out on the
    destination's; the city guards' reaction is loop 3g's). `oldtown` falls back to it: today's
    map has no Old Town square.
  - `reroute`: 40 % of the way in the app recalculates once and draws a new line that first turns
    back to the junction behind the car.
  - `rechotka` ("turn at the Frogs"; the shop was Rechotka 24 until 2026-10-30, the id stays) only by flag until loop 2d-2 places the shops.
  Ignoring the app is always allowed.
- **Stars** (live in the status panel, `★★★★½ 4,5`, a short toast for each change): from 5.0,
  −½ for a hard bump (closing speed over 4 m/s), braking over 18 m/s² or a corner over 15 m/s²
  (2 s apart, at most −2 in all; the słoiki's limits are 16 and 14), −½ per 15 s past the ETA
  (road / 9 m/s + 20 s; at most −1½), −1 for a police pull-over, +½ for arriving within 0.8 of
  the ETA, +½ when a believer's app leg is driven (the waypoint within 15 m; "No widzisz,
  aplikacja wie"). A believer whose leg you skip only grumbles. The final rating is the nearest
  half, 1 to 5.
- **Pay** (*guess*, between kebab and słoiki): fare 15 zł + 9 zł a km of road from the pickup ×
  the MNOŻNIK; tip 40 % of the fare at 5 ★, 25 % at 4½, 10 % at 4, none below; the 5-star streak
  pays +10 zł for each 5-star ride in a row before this one (at most +50; a 4½ keeps the streak,
  below 4½ or a cancel ends it); respect +25 at 5 ★, +10 at 4–4½. A 1.8 km ride by day at 5 ★:
  31 + 12 = 43 zł. **Your rating** is the average of the last 20 rides, the ones a new save
  hasn't driven counted as 4,87 (nobody has a 5.0); it and the streak are kept in
  `user://save.cfg` (`[keep]`, `wallet.gd`).
- **The end**: at the door (7 m, under 2.5 m/s) Nawigacja's "you have arrived" line, then 2.6 s
  later the result card beside the car (one thing at a time): the stars, the passenger's
  `podwozka_rating` comment (5, 4, low, or police if pulled over), the pay (the fare with the
  MNOŻNIK, the tip, the streak), your rating and what moved the stars. It has no button: it goes
  after 12 s or once the car is 25 m off (M closes it). While a ride's request or result card is
  up, the app-taxis' GPS bubbles and the radio host's next line wait (a caption already up slides
  out); they come after. **Cancel**: the ✕ on the status panel any time, or the passenger gives up after
  3 × the ETA (pickup and ride each): no pay, no stars lost, the streak ends.
- **The police**: `police.gd` calls `rides.on_pulled_over()` when a pull-over's conversation ends
  (police.md 8.3): exactly one star from a running ride (none while picking up), and the result's
  comment becomes the `police` one. Escaping a chase costs nothing. Verify step `ride-police`:
  ride 8 with `--pullover=generic --pullover-frame=1500` on the prebuilt city prints
  `ride: stars 4.0 (police −1.0)` once.
- **GPS moments in traffic** (`gps_moments.gd`, parodies.md 3.2): every 45–90 s one Podwózka car
  (the hatch with the phone on its roof, loop 2c) on screen within 80 m of the view's centre (and not behind a building)
  stops dead for 4 s ("you have arrived": the cars behind wait, one may shout), takes the way back
  at the next junction where a U-turn is possible (recalculating), or, on a road by the river,
  pulls up where it comes nearest the water, waits 3 s and turns away; its driver says a
  `podwozka_driver` line. Never two at once; no new geometry (`traffic.gd` `turn_next`).
- **Checks**: `game/tools/check_rides.gd` (verify step `rides`, under a second) feeds the rules
  synthetic events: the star table, the pay table (with the design's 43 zł), the streak, the
  cancel rules and the rating, and every dialogue group and tag the code asks for (Polish and
  English, bubbles ≤ 70 characters, buttons ≤ 28). The verify step `ride` drives ride 8 (a
  believer waiting 34 m from the pin, the river quirk) with the autopilot and `--parody-log`.
  `check_hud.gd` lays out the request card, the ride's status and two result cards at their
  longest, and fails a ride card that covers the car's spot.
- **Cost** (probe, Metal, 2868×1320, Classic, traffic Normal, day; before = 613ff38 from a copy
  in the same session, measured before the 3c streaming merge): the spawn view 134 draw calls (main 52, shadow 35, 2D 46) before and
  after, side jobs + eggs 0.039 → 0.044 ms. During a ride (ride 19 on the autopilot, Powiśle):
  126 draw calls (37 / 30 / 60), side jobs + eggs 0.088 ms; a kebab delivery measured the same
  way: 140 (46 / 29 / 65), 0.068 ms. Nothing new in the 3D passes but the ride's pin (the job
  beacon's ring and column), the waiting passenger (one mesh) and the "!" (one mesh), fewer than
  a kebab customer's beacon person; the minimap's dots draw in its overlay's existing canvas
  item. The river spots are found a few shore samples a frame after the city is built (683
  samples, 24 a frame).
- **Screenshots**: `shots/loop2d1/` at 2868×1320 and 1792×828: the request card (`pro`, `i11`
  frame 60), the pickup with the passenger under the "!" (`pickup_*`), the ride mid-way with the
  app's dotted route and Nawigacja's river line (`pro`, `i11` 1500 and 3000), the result card
  (`pro2`, `i112`; after the merge, beside the car: `end_i11`, `end_pro`), a GPS moment by the
  spawn (`gps_*`).

## Map round 2: the ground under structure ends, the night streets (2026-10-29)

What reviews A and B left, by rule (the demo box comes later, loop 3d):

- **D5, the road under the drawn ground** at structure ends. An apron holds `terrain_height`
  under a deck's or tunnel's end below the 10 m grid, but `_build_ground` drew the raw grid, so
  the road, its carriageway area, kerbs and rail beds lay under bare ground: the beige wedge at
  the viaduct's west end (0.65 m), the Wisłostrada portal (1 m), the abutment link's portals,
  the Kruczkowskiego rail viaduct, two ramps' feet. Now (`map_builder.gd`, the "map round 2
  (D5)" block) the grid cells an apron reaches are drawn as 1 m sub-cells at
  `min(grid, terrain_height)` (`_drawn_height`), the areas and footways laid on the grid use the
  same sub-cells, and an apron fades out over `APRON_TAPER` 3 m past its corridor's sides
  instead of a step inside a carriageway wider than the deck. **`check_roads` C11** (new): a
  road's, carriageway's, tram's or rail's surface on the ground more than 0.1 m under the drawn
  ground (`Map.drawn` mirrors the builder); 43 in 7 places → 0. `check_drape.gd` compares with the
  drawn ground too.
- **Tram-stop shelters**: the 14 that review A took off the rails are put beside their track
  (`bake_structures` `TRAM_SIDE`: 2.4-4.5 m out, clear of tracks, carriageways and lanes): 13
  placed, 1 left out (no clear spot). OpenStreetMap maps them on the stop position and none has a
  platform mapped within 25 m.
- **The night streets** (`bake_lights.street_lamps`): where OpenStreetMap maps no street lamps
  (Al. Jerozolimskie east of Rondo Dmowskiego, Nowy Świat at (-331, 18)), a lamp every 34 m at the
  kerb of every primary, secondary and tertiary street and of the named residential through
  streets (600 m or longer) wherever none stands within 22 m (not in a building, on a
  carriageway, a tram track or under a deck); Most Poniatowskiego's abutments between the towers
  (road `fills` meeting a deck's end, D7) get one every 20 m: 404 lamps in all. Sodium or LED by the
  street's name, as its mapped lamps; `map_builder` reads each added lamp's kind back from the
  light map. Lit map 13.7 → 16.8 %.
- **D6, deck lamps' pools on the river**: a lamp on a deck (2 m or more over the ground) lights
  only its deck's corridors (the pools fell on Most Poniatowskiego's gravel shoals); a bridge lamp
  just off a narrowed deck (the Jana Pawła II viaduct) moves in onto it instead of standing in the
  road under the viaduct. `check_streets` S1 now also checks the added lamps (14 on asphalt in the
  first try → 0).

Checks: `check_roads` C1-C11 all allowed or 0; `check_streets` S1 0, S2 0, S4 0; `check_drive` 0 / 0;
`check_drape` 0. Draw calls at the four probe views: the 3D passes +0 / +0 / +2 / +1 (lamp
MultiMeshes in a few more tiles); vertices 6,106,458 → 6,249,198 (+2.3 %: the subdivided cells
under the aprons, 404 lamps and their halos). Left (BACKLOG "From map round 2"): L1, D8-D10,
L4, L5, L2 and the Podwózka river spots.

## Map round 2b: river spots you can drive, the reviews' last items (2026-10-29)

- **The Podwózka river spots** (`bake_structures.place_bank`, index `drivable_bank`): loop 2d-1's
  `rides.gd` found a dry waypoint 5 m in from the river with a straight line to a lane over dry
  ground with no building (9 spots), but never tested whether a car can drive that line. The bake
  walks each of 832 candidates' lines to its nearest lane points (up to 10) every 0.5 m against
  retaining walls, fence, wall and hedge lines, guard rails, steps, piers, solid props, buildings,
  decks overhead and steps in the ground over 0.6 m in 2 m: 19 lines drive (blocked first by
  guard rails 51, steps in the ground 32, walls 32, decks 12, steps 10). `rides.gd` reads them
  (the "map round 2b" block, `_bank_spots`; a map without the list keeps the scan).
- **Lamp colour along a street**: a street that carries on from a bridge (a ground road sharing
  an end with a bridge road) is lit sodium like its bridge (Al. Poniatowskiego changed from the
  bridge's sodium to LED at the towers); a mapped lamp takes its kind from the nearest named
  street within 14 m (`bake_lights` `street_is_led`). 16 lamps LED → sodium.
- **D9** (`bake_roads`, `STUB_MAX`): a bridge footway of 8 m or less off another footbridge's
  middle with a free end (OpenStreetMap's stairs left out) is left out: its free end was pinned
  to the ground and pulled the Tamka footbridge down 2.2 m. 1 stub; the footbridge is level.
- **L5** (`bake_medians`): a median piece on the mapped tram bed (`landuse=railway`) is paved like
  it: the green rectangle on the tracks by Jerozolimskie × Krucza.
- **L1** judged: the lines in the three junction areas (Plac Trzech Krzyży, the Poniatowski
  ramps, Wał Miedzeszyński) are dashed lane guides through the junction and edge lines along its
  sides; the orthophoto (about 0.5 m a pixel) can't show painted lines, and Warsaw paints guide
  dashes through such junctions: kept. **L4** (Emilii Plater's weaving median walls), **L2**,
  **D8**, **D10**: not changed (BACKLOG).

## Loop 3d-1: the demo map, the 20.1 km² box (2026-10-29)

The map is docs/DEMO.md 2.1's box (south 52.2183, west 20.9780, north 52.2525, east 21.0560;
the east edge moved from 21.0500 with the user's yes so Most Łazienkowski is whole),
baked from the demo fetch already on disk (no downloads; README "Map data" for the chain,
`tools/bake_all.sh` to run it). The origin stays at 52.2340 N 21.0240 E (`bake_osm.py`
`ORIGIN`), so every coordinate written before means the same place.

- **Committed vs derived** (item 0, the user's decision): the split and the prebuilt sectors are
  no longer committed; a fresh clone runs `tools/setup_map.sh` once ("Map data").
- **The terrain from the 1 m NMT** (the user's yes: `tools/fetch_demo.py nmt1box`, 12 tiles,
  83 MB, `data/raw/demo/gugik/nmt1_box/`): `tools/prepare_demo.py` builds the 10 m grid's nodes
  from it: each node the median of the 1 m cells within 5 m, or, where 12 or more of them lie on a
  drivable road at grade, the median of those road cells (a node no longer reads an embankment's
  top or foot by chance: the old point samples moved up to 3 m with the demo fetch's lattice).
  Wybrzeże Kościuszkowskie's 2.4 m step at (625, −453) is real: the 1 m data shows the road in a
  5-6 m trench meeting the ground over the Wisłostrada tunnel's south portal; it is listed as
  loop 3e's (the portal's trench). A deck over a service way needs 2.6 m, not 5 m
  (`bake_roads.CLEAR_SERVICE`, check_roads C3 the same: garage ramps the 1 m data shows).
- **New steps**: `tools/prepare_demo.py` (the raw downloads cut to the box into `data/work/demo/`;
  `data/raw` is only read), `tools/bake_terrain.py` (the terrain on its own, first),
  `tools/bake_traps.py` (police traps 5-7 placed on the new graph by the first four's rules:
  Aleja „Solidarności” at (−778, −1390), Aleja Armii Ludowej (Trasa Łazienkowska) at (673, 1399),
  Aleje Ujazdowskie at (57, 1404); the blocks give 157-825 m runs, not police.md's 250 m).
  `bake_osm.py` runs twice (its structures read the box's LoD2). Its two quadratic loops (outlines
  holding parts, props facing their road) got grids: 240 s → 110 s for the whole bake.
- **Pedestrian zones** (police.md 5.6, 13): `bake_osm.py` `PED_ZONES` (the Old Town box, one
  small commented list) writes `ped_zones` (83 polygons: the `highway=pedestrian` ways as strips,
  the squares and pedestrian areas: the Old Town and New Town, Plac Zamkowy, Krakowskie
  Przedmieście's north end); traffic never enters (pedestrian ways are not in the lane graph);
  `game/scripts/ped_zones.gd` and `car.gd` `zone_cap` hold the player's car to 20 km/h there
  (`zone:` log lines) when Settings → Jazda's zone switch is on (off by default since 2026-10-30). The pill, the guards and the clamp are loop 3g-2's.
- **Classes fixed over the whole map** (each counted before → after): a vertex within 0.3 m of the
  one before it got no node in the deck solver (a crash on the box's rails: 1 → 0); a rail way with
  no layer between cutting tracks is in the cutting (Żelazna's crossover, an R3 failure that
  stopped the bake: 1 → 0); poles on the asphalt (S1 15 → 0: a lamp with no spot off the asphalt
  is left out, a signal looks 16 m out, the added lamps and a last pass use S1's own test); a deck
  lookup past a piece's end at a joint with the next piece (Most Świętokrzyski dropped the car
  7.6 m at its pylon: check_drive jumps there 2 → 0); building walls standing in a lane open by
  their triangles' edges, not centres, and for OpenStreetMap buildings too (lod2_open 92 → 140
  places; check_drive lane collisions outside the structures 6 → 1, a pillar, allowed); a point
  of interest in water moves to the nearest road point (Skwer Hoovera's fountain, check_water 5d:
  2 moved); a mapped Mermaid 150 m or more from the river isn't the egg's (a small "Syrenka"
  1.5 km inland had taken the boulevard spot's place); the map's edge walls stand on the map's
  edge, not the grid's, and the sector grid covers what the builder draws (`bake_sectors.reach`;
  check_streaming's identity: 26 ground and building tiles in no sector → 0).
- **What the checks found** in the new area (all listed in the allowlists with place and reason,
  `tools/check_roads_allow.json` and the new `tools/check_drive_allow.json`; 27 entries of the
  first box no longer matched and were dropped): the structures of DEMO 4.6, loop 3e's work: Trasa
  W-Z's tunnel and portals, Trasa Łazienkowska's trench at Plac Na Rozdrożu and its interchange,
  the Wisłostrada tunnel's north portal under the Copernicus Science Centre, Most Świętokrzyski's
  pylon, Most Śląsko-Dąbrowski's Praga end, Wiadukt Markiewicza, the railway cutting west of
  Centralna under Żelazna, Towarowa and Kasprzaka, the Praga viaducts by the zoo; and two classes
  of the 10 m grid: service ways and steep escarpment streets as before, and (new) roads whose
  ends meet a hump or pit of the new grid, which samples the NMT 3.5 m east and 5 m south of the
  old grid's nodes (Wybrzeże Kościuszkowskie by Tamka steps 2.4 m in 6 m: an open question).

| Loop 3d-1 numbers | First box (loop 3c) | Demo box (east edge 21.056, the 1 m terrain) |
| --- | --- | --- |
| Area, sectors | 3,545 × 1,769 m = 6.3 km², 32 | 5,318 × 3,782 m = 20.1 km², 108 (i −7..4, j −5..3: 96 for the box and a sliver row of 12 north of z −2,048 for the terrain and the buildings that reach 4-6 m past the edge) |
| centrum.json; lod2.bin, ao / lights / water.bin | 5.0; 26, 12 / 12 / 6 MB | 16.4; 87 (derived since loop 3d-1), 40 / 40 / 20 MB |
| Roads, paths, buildings (OSM kept / LoD2) | | 8,038, 19,464, 12,610 (4,667 kept / 6,025 LoD2, 1.55 M vertices) |
| Scanned trees, pois, addresses | 12,554, 1,020, 973 | 42,578 (every OSM tree replaced), 3,548, 3,332 |
| Lane graph | 966 nodes (96.3 % strongly connected), 1,497 edges | 2,714 nodes (2,615: 96.4 %), 4,427 edges, 183 signal controllers |
| Vertices (`count_vertices.gd`) | 6.25 M | 19.49 M (0.97 M a km²) |
| Sector files / index.json | 9.2 / 3.3 MB | 29.4 / 10.2 MB |
| Prebuilt: sectors, index.res, proxies.scn | 29.3, 2.3, 2.7 MB | 91.3, 7.7, 8.5 MB |
| check_roads findings (all allowed) | C1 32, C2 1, C3 40, C5 18, C8 5, C9 5 | C1 81, C2 1, C3 137, C5 72, C6 4, C8 30, C9 12, C11 1 (in the 18.6 km² of the first demo bake: C1 84 → 72, C8 32 → 25 with the 1 m terrain) |
| check_drive (both paths) | 0 | 0 not allowed (174 allowed, at loop 3e's structures, one pillar and one median fence) |
| check_streets | S1 0, S3 18 | S1 0, S3 40 |
| Probe draw calls (spawn, river, zoomed out, helicopter) | 132, 103, 153, 211 | 134, 103, 148, 217 |
| Memory at the spawn (probe): static / video | 147 / 263 MB (textures 24) | 244 / 421 MB (textures 94: the AO, light and surface maps 100 MB whole) |
| check_water, check_drape | OK | OK (2 places listed in check_water's `ALLOWED`, 1 in check_drape's `EXCUSED`: loop 3e) |
| Exported .pck | 47.2 MB | 140.0 MB (budget 300) |
| check_streaming | identity, ≤ 0.015 % at 10 spots | identity OK (108 sectors), soak OK; spot 8 at 0.789 % under its own limit of 1 % (`SPOT_MAX`: single texels of lamp-pole shadow edges, 0.14 % by more than 8/255; in the game the 12 streamed sectors against all 108 differ in 0.07 % visibly, nothing moves) |

## Adding music (loop radio-playlists, 2026-10-29)

The radio plays songs you make yourself (a synth, or an AI music tool such as Suno). Three steps:

1. **Make the song** and export a WAV or MP3 (flac, m4a and aiff work too).
2. **Put it in `data/raw/music/<station>/`**, where `<station>` is a station's `id` in
   `game/data/radio.json`: `nocna_fm`, `rondo_fm` or `mordor_fm` (the folder is ignored by
   version control: raw music is never committed). The song's file name is its title on the
   radio: `Night_on_Smolna.wav` shows as "Night on Smolna". To say more, put a text file with
   the same name next to it, `Night_on_Smolna.txt`, with one line (the licence), or lines
   starting `licence:`, `title:` and `artist:`:
   ```
   licence: Suno Pro plan, owned
   title: Noc na Smolnej
   artist: Lubomir
   ```
3. **Run `python3 -I tools/add_music.py`** (needs `ffmpeg`; `oggenc` from vorbis-tools makes the smallest files). Then `tools/verify.sh --only=radio`,
   and commit `game/audio/radio/`, `game/data/radio.json` and the new `.import` files.

What the tool does to each new song (the docstring of `tools/add_music.py` has the details):
decodes to 44.1 kHz stereo, trims silence at both ends (below -50 dBFS, 0.2 s kept), measures
the loudness (EBU R128) and applies **one static gain** so the song sits at the radio's level,
**-14.0 LUFS** (the mean of the three original loops: -14.6, -14.2 and -13.2), lowered further
if its true peak would pass -1 dBTP. No limiter, compressor or loudnorm: they flatten music. It
encodes Ogg Vorbis to `game/audio/radio/<station>/<name>.ogg` and appends the track to
`radio.json` (file, title, artist, seconds, gain_db, licence, source). `--station=<id>` limits it
to one station, `--force` converts every file again, `--dry-run` says what it would do, `--list`
prints the stations and tracks with their sizes, `--licence="..."` sets the licence of this
run's files. A folder in `data/raw/music/` that is not a station in radio.json is not turned
into one: the tool prints the line to add to radio.json (id, name, frequency, colour).

A station with one song loops it; with two or more it plays them in a shuffled order (the date
seeds it), each to its end, with the host's lines between songs now and then.

Loop MW-5: a station may set its own encoding in radio.json, `"encode": {"rate": 22050, "kbps":
40}` (PÓŁNOC FM: lo-fi made at 22.05 kHz), and lock tracks with `"free": N` (its first N play,
the rest open by notebook chapters or `radio.unlock_track`; track numbers follow radio.json's
order, which `add_music.py` takes from the file names: name them `01_…`, `02_…`). See "PÓŁNOC FM
and the city's sounds".

**Sizes.** The tool encodes with `oggenc` (vorbis-tools: `brew install vorbis-tools`) when it
is on PATH: ffmpeg decodes, trims and applies the gain to a temporary 44.1 kHz stereo 16-bit
WAV, `oggenc -b 96` writes the Ogg (about 96 kbps on average, about 2 MB for a 3-minute song),
and the WAV is deleted. Without `oggenc` it uses ffmpeg's `libvorbis` if `ffmpeg -encoders`
lists it. The Homebrew ffmpeg on the Mac has no libvorbis, and its built-in `vorbis` encoder,
the last fallback (the tool says so), ignores the bitrate and writes about 185 kb/s, 4.1 MB for
3 minutes. The three original loops (2.4 minutes together) were 12.6 MB as WAV; encoded with
`oggenc` they are 1.5 MB as Ogg (0.56, 0.50 and 0.44 MB).

**Licences.** A song whose licence is not given stays `unknown`; the radio check
(`tools/verify.sh`, step `radio`) lists those as a WARN. **Check every `unknown` track before a
release**: an AI music tool's free plan may not allow its songs in a published game (paid plans
usually do, by the tool's current terms: keep the plan's receipt or the song's page). CREDITS.md
lists every track and its licence line; update it when you add songs.

## Loop G0+: streaming and heat on the iPhone 11 (2026-10-29)

Loop 3c's streaming and G1b's sharp ×1 picture, measured on the iPhone 11 (`iPhone12,1`, iOS
26.5, started with `devicectl`, no debugger, Auto = High ×1 sharp 1792×828, `--nosave`: the
phone's own settings and save untouched).

1. **Why the phone's log had no streaming lines.** devicectl swallows the `--`, so on the phone
   the game's flags arrive among the engine's own. `main.gd`'s `_parse_args` fell back to those
   (loop 2b); `_parse_stream_args` read only the user args, so `--stream-soak` and
   `--stream-log` did nothing: the game just played (traffic, a rescue call) until
   `device_run.sh` stopped it, and the log held only its start-up lines (the governor's lines
   in the first run came from that play). Now both parsers read one `game_args()`. The soak also
   writes `user://stream_soak_result.txt` (on the iPhone `get_tree().quit()` does nothing and the
   app is stopped from outside), `print` flushes the log file
   (`application/run/flush_stdout_on_print`), and `tools/device_run.sh` keeps each run's log as
   `<label>_<date-time>.log`, never lets a short copy replace a longer one, copies once more 3 s
   after the done line, copies the soak's result file, and exits 3 when the done line never came.
2. **Sector adds were 60× over the budget on the phone; the cause was physics interpolation.**
   The project has it on (for the cars); the sectors inherited it, and adding a MultiMesh node
   under an interpolated parent cost the main thread 14 ms on average (37 ms at worst; the Mac
   1.4 ms, which loop 3c read as "a busy Mac"), a sector 188 ms spread over its load frames, and
   the 6-minute soak's CPU-bound misses walked the governor down to GPU 0/2 · CPU 0/2.
   `sector_streamer.gd` now sets `Sectors` and `Proxies` to `PHYSICS_INTERPOLATION_MODE_OFF`
   (nothing in them moves on the physics tick; the people, pigeons and police halos already had
   it off): 0.002 ms a MultiMesh, 0.35 ms a sector, 0 frames over 3 ms.
3. **What is left: one slow frame per load** (19-22 in a 6-minute soak, 25-65 ms, none with any
   of the streamer's own work in it). `--stream-log`'s new `worker` lines show it is the render
   server creating the sector's meshes and MultiMeshes (~1-1.6 MB of GPU buffers) on the main
   thread as the worker's load ends: the stall lands wherever the main thread next touches the
   render server (after the streamer's process, in the draw, before the next physics frame);
   with `--render-thread separate` it moves into the draw (the main thread waits for the render
   thread), 16-58 ms: no better. A fix needs the sector's resources in pieces the worker can load
   one a frame (a `bake_city.gd` change; BACKLOG "From loop G0+").

| Streaming soak, 6 min (`--stream-soak=6 --stream-log --prebuilt`, governor on) | Before (A1 / A2) | After (B1 / B2) |
| --- | --- | --- |
| A streamed sector's main-thread ms (43 of 49 loads): median / p99 / max | 188 / 247 / 247 · 182 / 235 / 235 | 0.35 / 0.55 / 0.55 · 0.34 / 0.53 / 0.53 |
| Streaming ms a frame: p99 over all frames / max | 16.4 / 37.1 · 16.5 / 32.4 | 0.82 / 1.17 · 0.82 / 1.45 |
| Frames whose streaming took over 3 ms | 493 · 485 | **0 · 0** |
| Adding a node, mean / worst ms: MultiMesh (428 adds), Node3D (83), mesh (298), collider (43) | 14.4 / 36.9, 16.0 / 29.1, 0.009 / 0.05, 0.018 / 0.03 | 0.002 / 0.02, 0.003 / 0.01, 0.002 / 0.01, 0.018 / 0.04 |
| Frames over 33 ms past the warm-up (of them with streaming work) | 78 (47) · 87 (59) | 22 (0) · 19 (0): the load hitch above |
| Frames missing a needed sector, forced loads | 0, 0 | 0, 0 |
| Governor | 10 changes, ended GPU 0/2 · CPU 0/2 (CPU-bound drops from 6 s) | **0 changes**, GPU 2/2 · CPU 2/2 |
| Start: 6 sectors in full / `city built in` | 242, 225 ms / 865, 832 ms | 189, 187 ms / 797, 871 ms |

| BENCH at Auto (`--bench`, 600 frames; the phone cool, before then after) | Before | After |
| --- | --- | --- |
| fps · 1 % low · worst · late · missed refreshes | 60.0 · 57.1 · 17.8 ms · 0.3 % · 0 | 60.0 · 58.7 · 17.1 ms · 0.0 % · 0 |
| Draw calls (main / shadow / 2D) · objects · triangles | 131 (52 / 45 / 34) · 310 · 0.40 M | 130 (51 / 45 / 34) · 305 · 0.40 M |
| Scripts · traffic · memory static / video | 4.28 · 1.68 ms · 132 / 233 MB | 4.17 · 1.56 ms · 134 / 233 MB |
| Start (the bench's launch): 6 sectors / `city built in` | 221 / 1079 ms | 185 / 1044 ms |

**G0's 20-minute soaks** (graphics.md §2.3 item 9; G1b asked for them): `--autopilot
--governor=log`, traffic Normal, governor on, Auto ×1 sharp, the build after the fix; each after
8 minutes of rest with the app stopped (day after the two benches), in this order:

| 20 min at Auto ×1 | fps every minute | Missed refreshes (GPU-bound) | Worst minute | Governor | G1b's rule |
| --- | --- | --- | --- | --- | --- |
| Day | 59.9–60.5 (60.0 in 16 of 20) | 23 of 72,308 (9): 0.03 % | minute 4: 6 missed | 0 changes | calm at 180 s; never close (GPU extras down 0 s, no minute over 2 %) |
| Night | 59.9–60.3 (60.0 in 17 of 20) | 18 of 72,206 (5): 0.025 % | minute 4: 7 missed | 0 changes | calm at 180 s; never close |
| Rain at night | 59.9–60.5 (60.0 in 17 of 20) | 20 of 72,283 (8): 0.028 % | minute 4: 7 missed | 0 changes | calm at 180 s; never close |

The first rain run was cut off at minute 18 (the session stopped and the app ran on its own for
2.5 hours before it was stopped); its 18 minutes read the same (11 missed of 65,102). The rain
row above is a second run after 15 minutes of rest. The soaks ran on the map before map round
2 (merged afterwards: +0.8 % vertices, the same 32 sectors).

Godot 4.7.2 can't read the thermal state, so how warm the phone got is the user's to feel; the
logs show no throttling (fps by minute flat, the governor never stepping in, the misses not
growing with time).

**On the Mac** (M4 Pro, Metal Mobile, `--bench`, before = the same code without the two
interpolation lines, interleaved, medians of 5 day / 3 night / 3 rain-night runs, uncapped):
frame 6.40 → 6.47 ms, 6.90 → 6.90, 8.33 → 8.33; scripts 1.25 → 1.20, 1.21 → 1.21, 1.40 →
1.43 ms; draw calls 114 → 114, 82 → 82 (the typical night run), 81 → 81; Vulkan GPU (1920×1080,
3 each) 1.11 → 1.14 ms. Draw calls, scripts and GPU unchanged; the phone's per-load main-thread
time is the change. Shots (`shots/g0/`, 2532×1170: spawn, Marszałkowska, the Palace, the river
by day and night, Rondo Dmowskiego in rain at night, the helicopter; runtime and prebuilt, day
and night): the 3D view identical before and after, only the minimap's random job markers differ
(≤ 0.019 % of the pixels); `check_streaming` pixels ≤ 0.015 % as in loop 3c.

Why it matters more on the phone than the Mac: the add's cost was main-thread work the A13 does
~10× slower (14 ms against the Mac's 1.4 ms), and the governor reads CPU-bound misses as a
reason to drop the extras; on the Mac the same frames fit inside 16.7 ms and nothing showed.

## The driving-feel loop: less sticky (2026-10-30)

The user: "driving is heavy, there are a lot of tiny objects on the road, and the car gets stuck
each time it hits another car". What did it, in the code:

- **A hit traffic car stopped dead in front of you** for 2.5 s (`traffic.gd` set `stun`, which
  forces its speed to 0 at once), and the car never steered round a car (Point follows fixed
  walls only), so rear-ending one was a 2.5 s stop behind it.
- **Every touch of a front corner was a dead stop**: Godot's slide takes the speed going into the
  contact out, so a bollard, a bench end or a parked car's corner caught at 40 km/h stopped the
  car as a wall would.
- **Kerbs**: each kerb line crossed kept 92 % of the speed, so an island (two kerbs) cost 15 %,
  and the raised ground dragged at 0.6/s; the roadworks' barriers and cones took 15 % each.

What changed:

1. **Corner slip** (`car.gd` `_corner_slip`): when every contact of a step is at one front corner
   (within 0.6 m of the side, in the front 1.2 m) and the way beside it is open (`test_move`
   0.6 m on from the side-stepped spot), the car steps sideways past it at up to 7 m/s and keeps
   96 % of its speed (100 % on the next frames of the same slip); the bump it reports is 35 % of a
   full one, once (traffic, the słoiki jars and ride stars read it). A square hit, a touch along
   the flank, both corners at once and a wall met at an angle don't slip.
2. **Cars are pushed, not walls** (`traffic.gd` `_shove`): the car it hit takes 70 % of the
   player's speed it lacks along its lane and slides off its line at 40 % of the player's
   sideways speed (≤ 4 m/s, slowing at 6 m/s², ≤ 1.6 m off); dazed for 2.5 s (police 1.5 s) it
   brakes at 4 m/s² instead of stopping at once and stays where it was pushed, then drifts back
   to its lane. `stun` stays the app taxi's hold (`gps_moments.gd`).
3. **Going round a car**: pushed into a car or a tram for 0.35 s with the gas on and getting
   nowhere, Point follows its side as it follows a wall; still pinned 1.5 s, it is turned out,
   but never towed to a free spot for it (that stays for walls).
4. **Kerbs and cones lighter**: a kerb keeps 97 % of the speed, once per 0.5 s (an island is one
   jolt), the raised ground drags at 0.25/s; barriers and cones keep 95 % (`eggs.gd` KNOCK_KEEP).

`check_steering` gains `post_clip`, `car_clip` (every scheme) and `car_behind` (Point, Fixed):
the car must get past each. Before → after (Point; Classic in brackets):

| Test (from 40 km/h, 25 for car_behind) | Before | After |
| --- | --- | --- |
| `post_clip`: a 0.3 m bollard under the right front corner | 36 km/h 1 s after the touch, past at 1.6 s (Classic: stopped, turned out, never past) | 91 km/h, past at 0.8 s (Classic the same) |
| `car_clip`: a stopped car's corner 0.5 m into the car's path | 32 km/h, past at 2.1 s (Classic: stopped, never past) | 93 km/h, past at 1.2 s (Classic the same) |
| `car_behind`: a stopped car square ahead | 22 km/h, past at 2.6 s | 26 km/h, past at 2.3 s |

Every older test (holds, turns, walls, the corner, the camera) reads the same as before. Street furniture stayed solid (benches, racks, columns, shelters,
parked cars): on that day's map 7 benches, 11 bike racks and 3 shelters overlapped a carriageway.
Since the easy-driving loop (below) only shelters and parked cars are.

## The roadworks loop: traffic and the helicopter knock the barriers (2026-10-30)

The day's roadworks (barriers and cones round a dig, `eggs.gd`) moved only for the player's car;
AI cars drove through the ones knocked into their lane, and the helicopter's downwash left them
standing. Now `_barriers` also takes every moving traffic car within 30 m of the roadworks: a
barrier or cone under its box (its length plus 0.4 m, 1.3 m either side of its centreline) is
knocked along at 75 % of the car's speed and 1.5 m/s out to the side. The helicopter under
14 m over the ground within 30 m blows the ones within 9 m outwards, up to 3.5 m/s at its centre.
Checked headless at Drewniana (the 2026-10-30 roadworks, `--at=145,-626`): 4 knocks by traffic in
60 s with the player parked, 14 gusts in 15 s with `--heli`, 0 errors. The cost is one pass over
the active drivers per frame, only on a day the roadworks are on the map.

## The ram test: traffic was a wall to the car (2026-10-30)

A new game run, `--ram-test` (verify step `ram`), drives the car into the back of a moving
traffic car in the real city. On main after the first driving-feel loop it showed the car still
stopping dead: hit at 65 km/h, 4 km/h a frame later, and never past in 10 s. The cause: Godot's
`AnimatableBody3D` (traffic's and the trams' bodies) is a `StaticBody3D`, so `car.gd` counted
every car and tram as a fixed wall (`_fixed_contact`): the slide took all the speed going into
it, Point followed it as a wall, and pinned against one the car was towed. Now:

- An `AnimatableBody3D` is not fixed. Hitting a car or a tram keeps half of the speed that went
  into it for the next frame (`CAR_KEEP` 0.5; something that doesn't move takes the rest on the
  next frames), and towing is for walls only.
- Rammed from behind, the traffic car also swerves away from the player's side at 0.35 of the
  closing speed (`SHOVE_SWERVE`), up to 2.0 m off its line (`SHOVE_ACROSS`, was 1.6), and takes
  40 % of the speed it lacks (`SHOVE_ALONG`, was 70 %: it shot off ahead and was hit again).

Ram test, same car at -918, 263 (23 km/h, the car from 29 km/h, Point at 65 km/h): before, hit
and 4 km/h after, never past (0.5 m behind after 10 s); after, 28 km/h after the hit, past it
2.6 s after, never unstuck. `check_steering` stays OK (`car_behind` 2.3 → 2.7 s now that the
stopped car is not followed as a wall until the 0.35 s push).

## Loop 3d-2a: the ground, part one (2026-10-30)

The map engine's ground half (ROADMAP "The road to the 1.0 demo", row 3d-2; the model is Slop New
York's "no ground under roads" and "coarser mesh on flat land", docs/design/slop-cities-research.md).
Measured first, with the new `game/tools/check_ground.gd` (verify step `ground`, ~2 min; `--whole`
builds the old ground for the before count, `--sectors` per sector, `--dump=FILE` for
`tools/overlay_ground.py`, the ground's wireframe over the aerial photo).

| Before (demo map) | |
| --- | --- |
| Ground | 470,275 triangles, 1.41 M vertices (7.2 % of the city's 19.49 M; the flat mesh is 8.36 M): 402,578 in the 10 m cells' halves, 67,697 in the 1 m sub-cells of 339 apron cells (14 % of the ground in 0.17 % of the cells), 7,391 edge-wall triangles; a full 512 m sector 5,202-5,305, sectors with aprons up to 12,139 |
| Ground under what covers it whole (grown 0.5 m) | 92,618 triangles (20 %): the river and ponds, parks and lawns, plazas; **1,109 under the road surface alone** (a 10 m triangle is rarely inside a carriageway with half a metre to spare: Marszałkowska, Aleje Jerozolimskie, the big junctions) |
| Flat 10 m cells | 44.4 % have four corners within 0.02 m of a plane, 89.9 % within 0.15 m; but blocks of them are not: within 1 cm (what keeps the heights within 2 cm) 1.9 % of the cells lie in planar 20 m blocks, 0.4 % in 40 m ones, 0 in 80 m; within 15 cm 47 % / 9.6 % / 2 % |

**Coarser ground (item 2), as measured.** The 1 m NMT's medians carry real relief of a few
centimetres (cambers, kerbs, lawns), so merging the 10 m grid into big quads within the 2 cm that
keeps every height rule saves about 2 % of the ground: not built. The coarsening that keeps the
heights exactly is under the aprons: `_ground_fine_cell` keeps the 1 m sub-cells only where they
touch a point an apron lowers (`min(grid, terrain_height)` more than 1 mm under the grid: 4,773 of
33,900 sub-cells, in 199 of the 339 cells), draws the rest of each half of the cell in runs along
the sub-rows on the half's own plane, and a half with no lowered point as the grid's own triangle:
67,697 → 15,001 triangles. `_fine_cells`, `_drawn_height`, the areas laid on the grid and
check_roads' `Map.drawn` are unchanged (the heights are the same to 1 mm).

**No ground under what covers it (item 3).** The ground is built after the flat layers now. The
layers that lie on the ground and hide it (the areas: water, grass, parks, plazas, sand; paving,
footways, steps, rail beds, roads, carriageway areas; not on a deck or in a tunnel) note each
triangle they draw whose centre lies within `COVER_GRADE` (-0.25 to +0.3 m) of the grid, per 10 m
cell; a 10 m triangle they cover whole grown by `COVER_MARGIN` 0.5 m (a layer stands up to ~0.3 m
over the ground, and at the 30 degree pitch a sight line under its edge reaches 1.7 times that) is
left out. Kept whatever covers them: the apron cells, the cells near an approach or an apron
(`ground_kept`: the road stands over or under the grid there), the grid's outer row (the edge
walls). The test (`_ground_hidden`): a cell's summed cover area, a cell and its eight neighbours
covered whole by one area, the triangle's middle and grown corners and sides under some piece,
then Clipper (`covers`: the triangle minus each piece; a piece that would cut a hole waits for the
others; it doesn't depend on the order). No new edges: the full cut (clipping the ground along the
road's outline, with skirts) would add triangles on every partly covered cell to save overdraw the
iPhone's tile GPU mostly removes anyway (opaque, one draw call).

| Loop 3d-2a | Before | After |
| --- | --- | --- |
| Ground triangles / vertices | 470,275 / 1,410,825 | 324,967 / 974,901 (-31 %) |
| 10 m halves left out | 0 | 92,612 (the river 2_0 -76 %, sectors 0_3, 0_-3, 1_-2 -70 %; the dense centre -2 to -3 %) |
| Apron sub-cell triangles | 67,697 | 15,001 |
| Hidden ground (check_ground, the class) | 92,618 (1,109 under roads alone) | 6 (0) (a test point on a seam between two pieces; allowed up to 30) |
| Holes (left out, not covered) | 0 | 0 |
| Ground off the height rule | 0.001 m | 0.001 m |
| City vertices (`count_vertices.gd`) | 19,488,688 | 19,052,803 (-435,885) |
| Flat-mesh vertices | 8,359,221 | 7,923,297 |
| Prebuilt sectors | 91.3 MB | 89.1 MB |
| Monolithic build (`count_vertices.gd`) / bake_city | 44 / 75 s | 58 / 90 s (the cover tests) |
| Probe draw calls, all passes (spawn, river, zoomed out, helicopter) | 134, 103, 148, 217 | 134, 101, 148, 217 |
| Probe main-pass triangles (same views) | 0.28, 0.21, 0.45, 0.48 M | 0.28, 0.20, 0.44, 0.47 M |
| Bench (Mac, Metal, 1280x720; medians of 3, interleaved with a copy of the old code): frame, draw calls, video buffers | day 8.36 ms, 107, 126 MB; night 8.35, 80, 125; rain at night 8.36, 80, 125 | day 8.36 ms, 107, 118 MB; night 8.35, 80, 117; rain at night 8.36, 80, 117 (the Mac holds its 120 Hz display in every run: frame time unchanged; 1 % low 70-96 either way, noise) |

Screenshots (`shots/loop3d2a_before`, `_after`: the core set at 2532x1170 and 1792x828 on both
paths, five ground-meets-road spots on slopes: Tamka by Wybrzeże Kościuszkowskie, both ends of
Most Poniatowskiego, Plac Na Rozdrożu, the Old Town's escarpment): 0.01-0.09 % of the pixels differ,
the minimap's random markers and single texels; overlays in `shots/loop3d2a_after/overlays/`.
check_drape, check_roads (C11 1 allowed), check_streaming (identity over 108 sectors, 0.789 % at
spot 8 as before) unchanged.

## Loop 3d-2b: the map engine, part two: maps per sector, look-ahead, the load hitch (2026-10-30)

ROADMAP "The road to the 1.0 demo" row 3d-2's second half (far levels, look-ahead streaming, the
one-frame-per-load hitch) and BACKLOG "From loop 3d-1"'s AO, lamp-light and surface maps.

**Measured first** (new probe line `probe far level:`: the proxies in the view and their triangles,
the sectors in full detail, and the nodes in view from sectors whose ground and low buildings are
out of the view; new `--heli-alt=M`; new `--stream-pass=heli|car` with `--stream-ahead=0`,
`--stream-slow=MS`, `--stream-gate=0`; new soak numbers `load_frame_ms`, `max_loaded`,
`missing_log`): the table below, before → after.

| Probe (2868×1320, Metal mobile, prebuilt) | Draw calls, all passes | Main-pass triangles | Static / video MB (textures) before | after | Sectors in full | Proxies in view |
| --- | --- | --- | --- | --- | --- | --- |
| Spawn | 135 → 135 | 0.28 → 0.28 M | 227 / 406 (94) | 228 / **300 (38)** | 12 | 0 |
| River (`--at=1135.7,-198.1 --heading=72`) | 103 → 103 | 0.21 → 0.21 M | 215 / 407 (94) | 216 / 286 (38) | 12 | 0 |
| Zoomed out (+ `--size=220`) | 148 → 148 | 0.44 → 0.44 M | 217 / 398 (94) | 217 / 291 (38) | 13 | 0 |
| Helicopter (`--at=1300,-420 --heading=60 --heli --size=150`) | 217 → 217 | 0.47 → 0.47 M | 221 / 398 (93) | 222 / 293 (37) | 16 | 0 |
| Helicopter at its highest over the centre (`--at=-800,100 --heli-alt=360`) | 359 → 357 | 0.67 → 0.67 M | 244 / 450 (93) | 245 / 344 (37) | 19 | 0 |
| Helicopter at its highest over Praga (`--at=1500,-500 --heli-alt=360`) | 272 → 272 | 0.54 → 0.54 M | 222 / 401 (93) | 223 / 293 (37) | 18 | 0 |

**1. The AO, lamp-light and surface maps per sector** (`scripts/city_maps.gd`,
`shaders/city_maps.gdshaderinc`). Each sector carries its slice of each map: the whole map's own
texels over the sector and `CityMaps.MARGIN` (2) round it, the map's edge repeated past its end
(`map_builder.gd` `map_slices`; 516² RG8 for the AO and light maps, 260² RGBA8 for the surface
map, 1.33 MB a sector). The prebuilt sector keeps them in its scene (`map_slices` metadata); the
runtime path reads them from the `.bin` files' rows as it builds a sector (the lamp-light map from
the image it keeps for the lamp heads); `--monolithic` puts every sector's in at once. When a sector is added the streamer puts its slices into a free layer of three
`Texture2DArray`s (one map a step within the frame's budget: 0.04 ms mean, 0.24 ms worst on the
Mac) and a table of one texel per sector (the layer + 1) says where; it gives the layer back when
the sector goes. Every shader reads the maps by world position through global uniforms
(`project.godot` `[shader_globals]` `city_*`): the ground (AO, surface), every `night.gdshaderinc`
user (lamp light: buildings, trees, props, the vehicles) and the post pass (surface): no per-material
maps any more, `map_maps`/`attach_maps`/`light_texture`/`water_texture` are gone. A slice's texels
are the whole map's at the same places, so sectors meet without a seam and the look is the same
(the 10 spots at night in rain against the old code: 0.003-0.10 % of the pixels differ, the
minimap's random markers and single depth-edge texels, as two runs of the old code differ;
check_streaming's 10 spots now 0.011-0.059 %, spot 8 0.015 % where it was 0.789 %). Where no
sector is in (a proxy) the maps read empty. The arrays have `CityMaps.SLOTS` = 24 layers (the
3-minute soak's most sectors in full at once: 23-24, the passes 15-20); a load that finds none free
takes the one of the farthest sector kept only by the hysteresis, and with none waits (proxy).
**Textures 94 → 38 MB, video at the spawn 406 → 300 MB**, at the highest view over the centre 450
→ 344 MB. The web loses its `.zst` first download (the slices travel in the sector packs).

**2. Look-ahead** (`sector_streamer.gd` `_look_ahead`): the focus's velocity (smoothed over a
quarter second; a jump of over 60 m resets it) × `LOOK_AHEAD` 4 s, at most 400 m: the sectors in the
square round that point and in the view moved there (its planes shifted) are wanted too (tested
for a quarter of the sectors each frame), and the next load is the wanted sector in the view first,
then the nearest the point ahead. The view tests take one corner a plane, not eight. With the
phone's slower loads played on the Mac (`--stream-slow=400`), the helicopter pass missed a sector
in view in **337 frames without the look-ahead, 0 with it**; the car pass 0 and 0. Streaming ms a
frame, p99 over all frames, helicopter pass: 0.56 before the loop, 0.62 with the look-ahead off,
0.72 on (max 1.24, budget 3).

**3. The load hitch, root cause and fix.** The slow frame came at the end of a sector's load, in
the frame's "to physics" phase. Loading a sector's pieces on the worker cost the main thread
nothing; loading its scene did (13-20 ms frames on the Mac against 9 for the plain frame), and of
the scene only its collider: the physics server builds a shape made on another thread on the main
thread, at once (a `set_faces` of 15,000 faces took 0.1 ms on the worker and stalled the main
thread 10-20 ms; in 2,000-face pieces, one a frame, no frame went over 10 ms). So: a sector's
collider faces are now patches of at most `COLLIDER_CHUNK` 1,000 faces, sorted by 64 m cell
(`map_builder.gd` `_collider_chunks`; the same faces, `check_streaming` identity unchanged), and
`bake_city.gd` saves every sector's own meshes, MultiMeshes and collider patches as files of their
own (`sectors/s_<i>_<j>/<n>.res`, 1,762, ~20 a sector), which the worker loads one a frame through a
gate the main thread opens each frame (four a frame while a sector in the view is missing:
`URGENT_PIECES`), before the scene that refers to them. The renderer then makes a piece's GPU
buffers a frame, and the physics server a patch a frame. Helicopter pass, the slowest frame
between a sector's load start and its last node: **median 16.9 → 10.3 ms, p90 23.0 → 11.6, max
23.8 → 13.0** (the frames' median 8.3-8.5 ms, the Mac's 120 Hz display). The web's sector packs
carry the pieces (`pack_sectors.gd`; the Web preset leaves `map/sectors/s_*/*` out of its pack).

**4. Far levels: measured, not built.** The camera is orthographic: every metre on screen is the
same size, so nothing in the view is far. In every probe view the sectors drawn have their ground
on screen (0 proxies in view; at the highest view over the centre 2 of 173 main-pass draws come
from a sector seen only by its towers), and the proxies show only while a sector loads. Painting
low buildings flat into the proxies would change what the player sees at full size; a far level by
zoom (the helicopter's highest views as proxies) is a look decision (docs/QUESTIONS.md). Where the
helicopter views' draw calls go: the helicopter itself is ~33 meshes (26 boxes) in the main and the
shadow pass (`heli.gd`, the gameplay lane: one mesh with vertex colours would save ~60 draws in
every flying view), the sectors' ground, building tiles and per-sector MultiMeshes the rest.
`landmarks.gd` exposes no LOD1 (a proxy needs one per landmark).

| Streaming (Mac, 1280×720, `--fixed-fps 60`, prebuilt) | Before | After |
| --- | --- | --- |
| 3-minute soak: loads, frames missing a sector, forced loads | 47, 0, 0 | 47, 0, 0 (at most 24 sectors in full) |
| Helicopter pass at 360 m and 35 m/s / car pass at 45 m/s: loads, missing | 30, 0 / 27, 0 | 27, 0 / 27, 0 |
| The same with `--stream-slow=400`, look-ahead off → on: frames missing a sector in view | | heli 337 → 0, car 0 → 0 |
| Slowest frame while a sector loaded, heli pass: median / p90 / max | 16.9 / 23.0 / 23.8 ms | 10.3 / 11.6 / 13.0 ms |
| Streaming ms a frame, heli pass: p99 over all frames / max | 0.56 / 0.75 | 0.72 / 1.24 |
| Map slices to the GPU, a map | | 0.04 ms mean, 0.24 ms worst |
| Prebuilt city (the phone's pack): sector scenes + pieces, shared | 89.0 + 19.7 MB | 109.5 + 0.1 MB |

| Bench (Mac, Metal, the default window, runtime path, medians of 3 interleaved with a copy of the old code) | Before | After |
| --- | --- | --- |
| Day: frame, draw calls, scripts, video (textures) | 8.35 ms, 107, 1.53 ms, 367 MB (138) | 8.33 ms, 107, 1.57 ms, 253 MB (82) |
| Night | 8.36 ms, 80, 1.55 ms, 357 MB (130) | 8.33 ms, 80, 1.59 ms, 244 MB (74) |
| Rain at night | 8.36 ms, 80, 1.59 ms, 357 MB (130) | 8.33 ms, 80, 1.70 ms, 240 MB (74) |
| Static memory, day | 318 MB | 304 MB (the runtime path reads a sector's AO and surface slices from the files' rows; the whole maps never sit in memory) |

The frame is the Mac's 120 Hz display either way; scripts +0.04 to +0.11 ms (the look-ahead's view
tests, a quarter of the sectors a frame; the run-to-run spread is ±0.1).

check_streaming has the two passes as its part (d) (verify step `streaming`, ~8 min now): no frame
may miss a sector the view needs, none load at once; the slowest frame while a sector loads is
printed, over 33 ms a NOTE. What only the phone can show: the iPhone 11's load frames (G0+: 25-65
ms, one per load) with the pieces one a frame; `tools/device_run.sh --label=stream_soak --wait=600
--done='^stream soak stats:' -- --notitle --prebuilt --stream-soak=6 --stream-log` reads it
(`load_frame_ms`).

## Loop 3e: the structures of the demo map (2026-10-30)

ROADMAP "The road to the 1.0 demo" row 3 (docs/DEMO.md 4.6): the W-Z tunnel, Most Śląsko-Dąbrowski,
Trasa Łazienkowska, the Wisłostrada's portals, Wiadukt Markiewicza, the rail cutting. Loop 3d-1 had
only allowlisted them. Measured first (render spots added to `tools/road_spots.txt`: 16, at both
W-Z portals, the W-Z viaduct, both ends of Most Śląsko-Dąbrowski, the Wisłostrada's north portal,
Plac Na Rozdrożu, Agrykola, the Czerniakowska interchange, both ends of Most Łazienkowski, Wiadukt
Markiewicza, Żelazna and Towarowa over the cutting, the zoo's viaducts and the Praga rail bridges;
`tools/overlay_structures.py` draws decks, tunnels, fills, walls, piers, portals and the findings
of check_roads and check_drive over the aerial photo). `check_drive.gd` drove 20 routes, which the
tunnels alone filled: now `ROUTES` 100 (all 98: every deck group and tunnel both ways, ~2 s);
`--no-allow` counts every finding, `--routes=N`.

**The causes, confirmed** (the 1 m NMT, `data/raw/demo/gugik/nmt1_box`, against the 10 m grid):

- **Portals pinned on the grid's blur.** A tunnel's portal took the grid's height at the mouth, where
  the 10 m node reads the ground over the tunnel: W-Z's east portal at −0.01 m while the trench
  before it is at −5.9 m (Nowy Zjazd 42 % over 7 m, a 1.6-2.1 m lane step); the Wisłostrada's
  south portals 3-3.5 m and north portals 2-3.6 m too high (Wybrzeże Kościuszkowskie 41 % at
  (625, −453) and 37 % at (642, −548), the two "main-road steps", and 43 % at the north ramp).
- **Tube floors at the cover's depth.** A tube's floor was "6 m under the ground over it", no
  steeper than 8 % *down* from a portal but not up: Plac Na Rozdrożu's short tubes followed the
  street over them in 0.3-0.8 m waves (16 autopilot jumps), W-Z's floor would have jumped 5 m.
- **Buildings over a tube solid into it**: the Copernicus Science Centre over the Wisłostrada's
  tubes, a block over W-Z's west end (68 + 15 lane spots in collision, C5 13).
- **Walls in the lanes**: a fill's or trench's wall at the foot of which another way's lanes run
  (Nowy Zjazd under the W-Z approach, Wiadukt Markiewicza's Karowa), the wall of the street over
  Plac Na Rozdrożu's tubes standing across their mouths.

**Fixes (classes, whole map):**

- **Ground profiles** (`bake_roads.py` `_ground_profiles`, `NMT`, `base_h`): the open ways near a
  tunnel's portal (within `PROFILE_REACH` 80 m along the streets) and every cutting (a way with
  layer < 0 and no tunnel) take their own level in the 1 m bare earth (every 2 m the median across
  the carriageway; pits under 6 m closed, humps under 30 m opened; one level at a shared vertex;
  a cross-section over a step has none), where it differs from the grid by 0.3 m or more, out to
  where they agree within 5 cm. They are written as **"set" fills** (`fills[].s`): inside the
  corridor (road half width + 1.5 m, round joins) the ground *is* that level, up or down
  (`map_builder.gd` `_fill_height`, check_roads `Map.terrain`); where one lowers the ground by
  more than 0.1 m its cells are drawn in the 1 m sub-cells like the aprons', 0.1 m under the road
  (`SET_SINK`, `SET_FINE`, `SET_SUB`; `_fine_index`, check_roads `Map.drawn`). A portal's level is
  the trench's floor (`PORTAL_PCT` of the 1 m cells 4-12 m out of the mouth), held over the last 8
  m of its ways; within 12 m of a bridge's end a way never goes under the grid. The structures'
  pins and the portals stand on these levels; an approach solved under the grid becomes a set fill
  too. 75 stretches of 62 ways, 951 m (54 lowered, at most 6.1 m).
- **Tubes**: a tube with a portal at each end runs straight between them, dipping only where the
  ground would come within `TUNNEL_HEAD` 5.6 m of its floor (15 m from the portals), ramps ≤ 8 %;
  and never steeper than 8 % up from a portal (`solve_tunnels`).
- **Trench walls** (`bake_structures.place_walls`): a set fill lower than the ground beside it gets a
  concrete wall facing the road (solid, a parapet from 1 m; under a deck it stops under the slab);
  no wall (trench or fill) where a ground lane runs within 3 m of it at its foot (`TRENCH_LANE`);
  a fill's wall over a tunnel keeps the mouth open wherever its foot would stand in it. The portal
  ramps' own walls give way to these inside a profile's corridor.
- **Buildings over tubes**: `lod2_open` also opens the walls of buildings that reach into a tube's
  lanes (bus half width); check_roads C5 skips a tube's ways where they run `TUNNEL_MOUTH` (4.8 m)
  under the ground (what stands over them is check_drive's).
- **Deck rails at a deck's end**: within 8 m of a piece's end a deck's guard rail clears 2.6 m
  round its lanes (cut twice: a cut end is looked at again).

| Loop 3e (demo map) | Before | After |
| --- | --- | --- |
| check_roads, all findings (allowed) | 338: C1 81, C2 1, C3 137, C5 72, C6 4, C8 30, C9 12, C11 1 | 304: C1 67, C2 1, C3 137, C5 60, C6 4, C8 17, C9 12, C11 6 |
| `tools/check_roads_allow.json` | 198 entries | 171 (33 fixed and gone, 6 new with their causes) |
| check_drive `--no-allow`, the 98 routes | 157 lane spots, 28 jumps | 51, 11 |
| `tools/check_drive_allow.json` | 15 entries (over 20 routes) | 11 (over 98 routes) |
| Portal floors (m): W-Z east / west; Wisłostrada S ×2 / N ×2; Plac Na Rozdrożu's 8 | −0.01 / 0.36; −15.8, −14.0 / −16.4, −17.8; 6.7-10.6 | −6.09 / −0.49; −18.9, −17.5 / −20.1, −20.0; 5.6-7.1 |
| Retaining walls | 15,283 m | 15,668 m (1,548 m along trenches; the portal ramps' 813 m → 51 m) |
| City vertices (`count_vertices.gd`): meshes, instances, total | 11,327,676, 8,034,004, 19,361,680 | 11,499,831 (+172,155, +0.89 % of the city: 294 more cells in 1 m sub-cells, 633 in all, and the trench walls), 7,199,724 (−834,280: a third of the parked cars), 18,699,555 |
| Monolithic build | 58 s | 75 s (the set fills' corridor tests in `terrain_height`) |
| Probe draw calls, all passes (2868×1320, Metal mobile, prebuilt): spawn, river, zoomed out, helicopter; W-Z east portal, Plac Na Rozdrożu | 135, 103, 148, 217; 125, 126 | 135, 103, 148, 217; 126, 124 (main pass 50 → 49 at both portals) |
| Probe main-pass + shadow triangles (all passes), same views | 0.62, 0.50, 0.91, 0.96 M | 0.59, 0.50, 0.90, 0.93 M (fewer parked cars) |
| Bench (Mac, Metal, runtime path, uncapped, medians of 3 interleaved with a copy of the old code): frame, draw calls, scripts, video | day 2.50 ms, 117, 0.96 ms, 227 MB; night 2.69, 88, 1.00, 217; rain at night 2.59, 88, 1.00, 217 | day 2.78 ms, 118, 1.04 ms, 224 MB; night 2.67, 88, 1.07, 211; rain at night 2.66, 88, 1.12, 211 (the day runs spread 2.39-2.87 either way; three more day pairs ran at the display's 120 Hz: 8.33 ms and 107 draw calls both) |
| Parked cars in the car parks (`bake_osm.py` `PARKED_FILL`, the user: about a third) | 14,637 (bays filled where the hash < 0.8) | 4,927 (`PARKED_FILL` 0.27) |

Per structure (check_roads + check_drive `--no-allow`, before → after): W-Z (tunnel, portals, Nowy
Zjazd, viaduct) C1 12 → 8, C5 2 → 0, C8 6 → 2, lane spots 24 → 6, jumps 1 → 0; the Wisłostrada's
north portal C1 2 → 0, C8 2 → 0, C5 11 → 1, lane spots 68 → 0 (C11 0 → 1); its south portals C1 2 → 0, C8 2 → 0 (C11 0 → 1); Plac Na Rozdrożu
C1 11 → 6, C8 8 → 4, C11 1 → 0, lane spots 26 → 9, jumps 20 → 4; Wiadukt Markiewicza lane spots
3 → 0; Most Łazienkowski's Praga end and the Czerniakowska interchange, the rail cutting, Most
Śląsko-Dąbrowski's Praga end (deck 4's parapet), the zoo's viaducts: unchanged, each left with its
cause (BACKLOG "From loop 3e").

**Not done, measured:** the deck seeds (every structure's way, not only portals and cuttings) fixed
Nowy Zjazd's pits and 40 more findings but drew 1,000 cells in 1 m sub-cells (+0.4 M vertices);
the rail cutting on its 1 m level (the WKD 7 m under the grid) is 24,000 m² of sub-cells (+0.5 M);
2 m sub-cells left the drawn ground over the road at the trenches' edges. All three need the ground
cut along a corridor (the trench floor drawn as one strip, the grid's triangles clipped round it)
instead of sub-cells: BACKLOG.

**G6, bridge entries off the lanes (2026-11-02).** `check_drive.gd` has a third pass, "entries": from
every road deck piece's end that is no joint and stands within 1.2 m of the ground (a ramp's foot),
the car drives straight onto the slab from 24 m out, every 0.8 m across the deck's width, at 0° and
±20°, its height from `drive_height` like car.gd's; a frame more than `UNDER` 1 m under the slab is
a finding (allowlist kind `under`). The routes flag the same on a deck's lanes. Before: 4 ends (the
ground beside the fill 1.5-2.4 m lower than the slab's end); `drive_height` now lets a car up to
`DECK_FOOT_UP` 3 m under the slab climb on over a foot's first `DECK_FOOT` 10 m (`_index_deck_feet`,
lazy, both paths): 0. Gameplay only (no geometry, no bake): no bench needed.

## Moja Warszawa notebook (loop MW-1, 2026-10-30)

MOJA WARSZAWA, the city notebook (docs/design/vision.md 4.1): the 72 places of
`game/data/places.json` (designer-owned; 9 chapters of 8; 75 since the L-shaped map loop, see
"The L-shaped map in gameplay") found by driving or flying past them,
kept in the save, read in the settings card's fifth tab. Code: `notebook.gd` (places, finding,
rewards, the minimap's marks), `notebook_page.gd` (the page), small hooks in `main.gd`
(`_build_notebook`, `_place_start`, `_put_at_place`, the flags), `hud.gd` (`set_minimap_unknown`,
`notebook_changed`, the "?" in the minimap's triangle array), `wallet.gd` (`notes`,
`chapters_done`) and `settings_panel.gd` (the ZESZYT tab, `show_notebook`).

- **Where a place is.** No bake resolves the places yet (BACKLOG "From loop MW-1": the map lane's
  `pois` kind `place`). At load (~35 ms, once) each place's `near` [lat, lon] goes through the
  bake's flat projection (`tools/bake_osm.py` `project`: the map's `origin`, 110 574 m a degree of
  latitude, 111 320 · cos(lat0) of longitude), then the first of these within reach of the hint
  wins: an `address` poi with the same number on a street whose last word matches ("Al.
  Jerozolimskie 6" finds "Aleje Jerozolimskie 6"; 600 m); a named square, park or landmark with the
  place's Polish name, or a landmark whose name starts with it ("Pałac Kultury i Nauki"; never a
  parody venue or a street; 600 m); a poi of the place's own kind (the Mermaid, Patelnia, Plac
  Defilad, the stadium; the nearest kebab stand for a kebab place; 300 m). Today: 5 by address,
  16 by name, 6 by poi, 45 on the hint; the furthest from their hints Smoła 359 m, Stara
  elektrownia 331 m, U Zdzicha 264 m. `--notes-log` prints a `notes: place <id> <source> N m from
  the hint (x, z)` line for each.
- **Finding** (`Notebook.finds`): in the car within `radius` (25 m; 40 m for squares, parks,
  bridges) at ≤ 30 km/h, or stopped inside it for 1 s; in the helicopter within `heli_radius` (60 m
  when the place has none) below 60 m over the ground. Checked twice a second through a 100 m grid
  of the places: one cell is looked at, so nothing runs per frame but a timer. Never on the title
  screen or during TEST · BENCH (its wallet is put back after; `--bench`'s route does find places); the game paused (settings) pauses it.
- **A new entry**: the save (`[notes]` id = yyyymmdd in `user://save.cfg`; with `--nosave` in
  memory only), +5 respect through the wallet's `pay`, a toast "NOWY WPIS · <name>" over "NEW
  ENTRY · <name> · k/8", the UI blip and a short buzz (25 ms). A chapter's eighth card: +50 zł and
  +30 respect once, a note card ROZDZIAŁ GOTOWY · CHAPTER DONE, and `[notes_chapters]` chapter id =
  yyyymmdd (MW-5's track unlocks will read it).
- **On the minimap**: the places not found yet within 400 m of the car as a gold "?" (3 × 5 pixels
  of 1.3 pt on a dark plate), never a name; drawn in the minimap's one triangle array, so no draw
  call of its own. (vision.md says "in a discovered district"; districts don't exist yet.)
- **The page** (Settings → ZESZYT · notebook; the card's title says MOJA WARSZAWA and "zeszyt
  miasta · k/72"): a row of the 9 chapters (the number stands in for the chapter's icon until
  PixelLab's; k/8 under it; gold when complete), the chapter's name, then its 8 cards in 4 × 2: a
  found card shows its name (Polish over English), a night venue's hours and the day found, one
  not found yet "?" and the chapter. A tap
  opens a card: name, fact and joke (Polish over English), the address (not for a venue: it could
  name the real business), the hours of a night venue (`otwarte PT–ND 04:00–12:00` over `open
  Fri–Sun …`) and the day found; WRÓĆ · back returns to the grid. At least 476 × 254 pt (as wide as
  the card's inside); every target at
  least 44 pt; the card fits the SE (633 × 349 pt of 667 × 375) without shrinking (`check_hud`
  walks the notebook's grid, a found card and an unfound one on all four screens). The settings
  card's line under its title is now two lines (Polish over English), so the fifth tab fits.
  The page is drawn by hand: its boxes in one triangle array, its words grouped by size, so it
  costs a handful of 2D draw calls whatever it shows, and nothing when the panel is closed.
- **Check**: `game/tools/check_places.gd` (verify step `places`, in the quick set and in CI: it
  reads only `centrum.json` and `places.json`): Polish and English for every name, fact and joke,
  Polish ≤ 70 characters (the toast too), 8 places a chapter, the hint inside the demo box and the
  place inside the map, no denylisted name in anything the notebook shows, reachability (a lane
  or footway within radius + 10 m: the misses are printed as a `check_places: WARN` line, not
  failed: 70/72 today), the finding rule on 11 synthetic cases, the 2 Hz tick through the grid
  (speed, away, distance, the helicopter's height) and a chapter paying once.

## The traffic loop: cars overlapping in junctions (2026-10-30)

A new testing aid, `--traffic-overlaps`, has the traffic count, every frame, the pairs of its
cars whose boxes overlap (a 2D separating-axis test with 0.15 m of slack) and prints one line at
the end: `traffic overlaps: N car-pair frames in F frames (J with a car on a junction curve),
S spots; worst W frames at x, z; K knots given up`. Cars in a junction used to look only at the
other car's centre in a 1.9 m strip ahead, so a car crossing at an angle was seen when its centre
reached the strip, too late, and two turn lanes merging into one lane were never checked against
each other (both are registered in the lane they merge into). Now (`traffic.gd` `_path_gap`):

- Each car looks for the other's whole body plus where it goes in the next 0.8 s (`PATH_LOOK`),
  sampled every metre, in its own corridor (both half widths and `PATH_MARGIN` 0.2 m) from beside
  its front half to 14 m ahead (`PATH_AHEAD`); the gap is to the nearest such point.
- Two cars on different junction curves are checked even when both end in the same lane.
- A car within 6 m of the start of the lane it came out on (`PATH_EXIT`) is still in the box.

Measured with `--traffic=busy --no-police --traffic-overlaps`, 3600 frames at `--fixed-fps 60`,
car-pair overlap frames before → after: the start 62 → 32, `--at=-918,263` 352 → 156,
`--at=145,-626` 395 → 27 (809 → 215 in all), no knot given up in either. What is left is mostly
two cars entering a short (3.5 m) merging curve in the same frame near -940, 210 and -890, 350.

## The traffic loop: trams and crossing cars (2026-10-30)

`--traffic-overlaps` also prints `traffic tram overlaps: N tram-car frames (M with the tram
moving), S spots; worst W frames at x, z; trams standing T tram frames`. On the demo map 8 trams
share 287 pieces of track, so a fixed `--at=` spot rarely sees one; `--tram-watch=N` keeps the car
(no collisions, standing still) 30 m ahead of tram N and 20 m to its side, moved on as the tram
draws level, so the view and the traffic ride through the city with that tram. Found and fixed:

- **A car on the rails was ignored** (`trams.gd`): the tram stopped only for a car whose centre
  was within 2.6 m of the head's straight line, and never for one that was waiting for it. Now it
  follows its rails ahead every 2 m to 30 m (`AHEAD_STEP`, `AHEAD_REACH`, round the curve) and
  stops 1.5 m (`STOP_SHORT`) before the first point that comes within its half width + 0.4 m
  (`CLEAR`) + 0.5 m (`SWEEP`, the straight bodies cutting inside a curve) of a car's box. A car
  running alongside counts only from 0.3 m (`ON_RAILS`) off its side.
- **A slanting car stopped with its corner in the way** (`traffic.gd` `_give_way_to_trams`): cars
  looked at three points of each tram car and stopped by the distance ahead. Now, where the car's
  way meets each tram car's line, if the body (or the front car's next 1.5 s, `TRAM_LOOK`) is
  there, the car stops with its box 0.8 m (`TRAM_MARGIN`) from the tram's side at any angle. A car
  already in front of a tram's nose drives on and clears it (the tram waits; both waiting was a
  standoff).
- **Cars were put down beside a passing tram**: `_try_spawn` keeps clear of the tram cars too.

Measured with `--traffic=busy --no-police --traffic-overlaps --tram-watch=0..3`, 10800 frames at
`--fixed-fps 60`, two rounds each: tram-car frames 1660 → 140 (all with the tram moving), car-pair
overlaps about the same (19 797 → 19 304), trams standing about the same. The runs are not
repeatable frame for frame (two runs of the same code differ), so compare totals over several.

## The traffic loop: a brush is not a crash (2026-10-30)

A traffic car the player hits is dazed (it brakes at 4 m/s² and slides off its line) for a time
that now grows with the hit (`traffic.gd` `on_player_bump`, the closing speed `car.gd` reports):
0.4 s (`DAZE_BRUSH`) for a knock at 3 m/s (`BRUSH_HIT`, about 11 km/h) or less, up to the whole
2.5 s (`DAZE`) from 8 m/s (`FULL_HIT`, about 29 km/h). Before, any bump over the car's 2 m/s
threshold, a clipped corner included, stopped the car dead for 2.5 s. The ram test (a 28 km/h
hit) is unchanged; police cars keep their own 1.5 s.

## PÓŁNOC FM and the city's sounds (loop MW-5, 2026-10-30)

PÓŁNOC FM, 86,0, the late-night station of docs/design/vision.md 4.6, and the city's sounds at
the notebook's places. Code: `radio.gd` (the station's rules, the locks, the log),
`dialogue.gd` (Kuba between the songs), `city_sounds.gd` (the emitters), `wallet.gd` (`tracks`,
`track_chapters`, section `[polnoc]` of the save), `time_of_day.gd` (`local_clock`),
`notebook.gd` (`chapter_done`), `sfx.gd` (`soften_engine`), hooks in `main.gd`.

- **The tracks** (`tools/make_music.py --set=polnoc`, 22.05 kHz, original and procedural like the
  other three; each a whole number of bars that loops seamlessly, with four bars of keys before
  the drums, a four-bar breakdown half way, the lead in the second half):

  | # | Title | BPM | Key | Bars | s | Parts |
  | --- | --- | --- | --- | --- | --- | --- |
  | 1 | Sód | 78 | D minor | 32 | 98.5 | dusty boom-bap, FM Rhodes 9th chords, sub bass, heavy crackle |
  | 2 | Wiadukt | 84 | A minor | 32 | 91.4 | swung hats and rim, muted piano stabs, a low string pad |
  | 3 | Nocna przesiadka | 80 | F minor | 32 | 96.0 | soft clap, the tram bell's falling third as a vibraphone motif, strong tape wobble |
  | 4 | Szkło na Woli | 88 | E minor | 40 | 109.1 | crisp kit, glassy FM plucks, a pad opening over each 8 bars |
  | 5 | Bulwar, 23:40 | 74 | C major 7 | 32 | 103.8 | brushes, nylon strums (Karplus-Strong) on three chords, the river |
  | 6 | Mgła nad Pałacem | 70 | B♭ minor | 32 | 109.7 | half-time drums, a formant "ah" choir pad, a gliding bass |
  | 7 | Świt na Smolnej | 90 | G major | 40 | 106.7 | brighter kit, birds, a piano line |

  To remake them: `python3 -I tools/make_music.py data/raw/music/polnoc_fm shots --set=polnoc`
  (about 2 minutes on 4 cores; it writes the WAVs and their `.txt` sidecars: title, artist,
  licence), then `python3 -I tools/add_music.py --station=polnoc_fm --force`. The station's
  `"encode": {"rate": 22050, "kbps": 40}` in radio.json keeps them small (3.93 MB for the seven).
- **On air** 22:00-06:00 by the game clock, and always in the Night (and a future Dawn) look
  (`Radio.on_air_at`). The game clock is `time_of_day.gd` `local_clock()`: Live's Warsaw clock,
  or the fixed looks' times (Day 14:00, Dusk 19:30, Night 01:30 on a Friday night, vision 4.5)
  running on from when the look was set. By day the station plays **reruns**: the same tracks at
  70 % (-3.1 dB), the caption "86,0 PÓŁNOC FM · powtórka · title" over "rerun · the host is back
  at 22:00", and the host silent (`host_group()` is "").
- **The host**, Kuba: `radio_polnoc` lines on the ticker every 60-120 s on air (the first after a
  tune is the station's ident, the line with "86,0"); between two songs he may come in early, but
  never sooner than 60 s after his last line (this rule now holds on every station).
- **The default station**: until the player presses R or RADIO this session (or passes `--radio=`
  / `--station=`), the radio follows the clock: PÓŁNOC FM on air, KEBAB FM off air (checked once a
  second).
- **Locked tracks**: radio.json's `"free": 2` on the station: tracks 1-2 play from the start; each
  finished notebook chapter opens the next locked one in order (`sync_chapters`; saves from before
  this loop catch up quietly at the start), so chapters 1-5 open tracks 3-7 and 6-9 open nothing
  yet. `radio.unlock_track(n, why)` opens one directly (the eggs E14 and E31 later). A locked
  track is never chosen (the playlist skips it). An unlock is saved and toasts "Kuba ma nową
  płytę: „title”" over "PÓŁNOC FM 86.0 · Kuba has a new record: title".
- **The city's sounds** (`city_sounds.gd`, sounds from `tools/make_sfx.py --only=…`): at every
  notebook place a sound fits: a club with hours (7) leaks its bass (`club_leak`, a 7.7 s loop at
  124 BPM behind a wall) while open by the game clock; the metro places (8) chime (`metro_chime`,
  our own three notes) every 180-240 s; the church and Old Town places (3) strike the hour on a
  bell (`church_bell`, 1-12 tolls 2.5 s apart); the Patelnia's busker (`busker`, a 9.6 s
  steel-string loop) plays 19:00-22:00. At most 8 players at once, the nearest sounding
  emitters within their kind's reach (60-260 m), decided at 2 Hz (about 20 µs a tick). **The
  02:00 beat**: on Plac Trzech Krzyży (the place tagged `quiet`) between 02:00 and 02:15, once a
  night, the radio (if on) goes to PÓŁNOC FM with the music 10 dB down while Kuba speaks at once,
  and the engine sounds at 45 % for 10 s.
- **Testing aids**: `--station=polnoc`, `--radio-log` (`radio:` lines: tunes, track changes, host
  lines with the gap since the last, unlocks, on air / reruns; `sounds:` lines: emitters on and
  off, chimes, tolls, the beat), `--unlock=all|N[,N]`. Headless runs play no audio, so the radio
  ends each track on its `seconds` there, and a `--fixed-fps 60` run logs game time.
- **Checks**: `check_radio.gd` (verify step `radio`) covers the station: the 7 files, titles,
  lengths and seams, the hours rule and the looks' clock on synthetic times, reruns and the
  silent host by day, the host every 60-120 s at night through `dialogue.gd`, following the clock,
  the unlock order, an egg's track, the save read back (a scratch file, never the player's save),
  locked tracks never played, the toast's length. `check_city_sounds.gd` (step `sounds`, quick
  set and CI): the emitters at their places, the hours, the cap of 8 nearest, reach, the bells,
  the metro's gaps, the 02:00 beat, the tick's cost.
- **Cost**: audio only, +0 draw calls; the emitters' tick ~0.001 ms a frame (bench line "city
  sounds 0.00"); ≤ 8 positional players (`MAX_LIVE`) besides sfx.gd's 6. App size: the radio's
  Ogg 1.50 → 5.43 MB (+3.93); the four city sounds +1.03 MB of WAV in the repo, about 0.2 MB as
  imported QOA in the app.

## Fotka, Spacer, KASETA and the eggs (loop MW-6, 2026-10-30)

docs/design/vision.md 4.2-4.4 and section 8. Code: `egg_book.gd` (the egg cards and their
triggers), `tape.gd` (KASETA), `spacer.gd` (wander mode), `fotka.gd` (the photo mode),
`notebook_page.gd` (the three new sections), `wallet.gd` (`eggs` id → day, `tapes`, `kadr`,
`kadr_photos`; save sections `[tapes]`, `[kadr]`, `[kadr_photos]`), `settings.gd` (`wander`,
`wander_offered`), `settings_panel.gd` (Tryb gry, FOTKA), quiet switches in `missions.gd`
(`calls_off`), `rides.gd` / `rivals.gd` (`quiet`), `police.gd` (`gentle`), `eggs.gd`
(`book`, `barrier_street`, `force_street`), hooks in `main.gd` (section "loop MW-6").
Data: `data/eggs.json` (45 cards) and `data/kadr.json` (15 spots); the then cards are
`data/then_cards.json` (unchanged).

- **The eggs** (`egg_book.gd`): the five eggs of v0.65 (eggs.gd still finds them, its spots and
  lines as before, kind `legacy`, now +10 respect) and vision's E01-E40 as cards. A first find
  saves the day it was found, pays the card's respect, opens its PÓŁNOC FM track
  (`radio.unlock_track`; if the track is already free it opens the next locked one: E31),
  stamps its then card (E38) or opens a Kadr spot (E13 opens k10, BUW), and shows the note
  "SEKRET k/45 · EASTER EGG" with the card's line. Kinds of trigger: `stop`, `pass`, `hover`,
  `land`, `circle`, `lap`, `street`, `between`, `tape` and the conditions (`night`, `after`,
  `hours`, `weekday`, `look`, `summer`, `dry`, `date`, `station`, `roadworks`): the list is
  `egg_book.gd`'s header. The game clock is `time_of_day.gd` `local_clock()`; `summer` is
  June-August in Live and always true in the fixed looks; Fat Thursday is from the computus
  (`fat_thursday(year)`, Live or `--date`). Checked at 2 Hz over a 200 m grid (one cell's eggs a
  check). **Reachable now: 29** (the 5 legacy, E02-E15 E17 E20 E22 E26 E31-E33 E36-E38; E03 E04
  E15 since MW-3, which also gave E10 and E14 their crowd conditions: the `crowd` and `days`
  conditions, "The night and the river" below).
  **Waiting: 16**, each with its card as "?" and a `waits` key that names what is missing: E01
  E21 the garage's paint; E16 E27 the dog walkers (MW-4); E18 E19 Wiralek's trend cycle
  (MW-4); E23 E25 the night buses; E24 the player's horn and the bus stops; E28 the riders
  (MW-4); E29 E30 Kolka and Hyrax (MW-4); E34 the armchair man (MW-4); E35 KASETA's older
  decades (T1); E39 a tram in old livery; E40 the payphone. The Frogs shop's two eggs wait for MW-2
  (not cards yet). Loop MW-4 woke E16 E18 E19 E27 E28 E29 E30 (a new kind, `event`: the
  moment is seen by `city_life.gd`, which calls `fire`; E27 E30 keep `stop` / `lap` with a
  crowd condition) and gave E20 the `lukrownia` crowd: **reachable 36, waiting 9** (E01 E21
  E23 E24 E25 E34 E35 E39 E40; "Everyday life and trends" below). Loop MW-2 added the Frogs and
  Leżak eggs (38 reachable); loop jobs-2 woke E34 (an `event`: the armchair man) and E40 (a `stop`
  at the payphone): **reachable 40, waiting 7** (E01 E21 E23 E24 E25 E35 E39). The night-buses loop woke E23
  E24 E25 (`event`s seen by `buses.gd`): **reachable 43, waiting 4** (E01 E21 E35 E39). The
  vintage-tram loop woke E39 (an `event` seen by `old_tram.gd`): **reachable 44, waiting 3** (E01
  E21 E35). The garage loop woke E01 (an `event`: `crowds.gd` at Lusterko's door) and E21 (a `stop`
  with the `paint` condition): **reachable 46, waiting 1** (E35; "The garage" below).
- **KASETA** (`tape.gd`): the 20 then cards at their notebook places. Within 40 m of one, on the
  ground under 12 km/h, the context button reads KASETA · time tape; a tap plays it: the VHS
  overlay for 6 s, a tape-rewind sound (procedural, seeded, no file), a dithered ghost of the
  place as it was (3-24 boxes from the cards' ghost notes, one mesh, one surface) that fades in
  over 1.5 s, holds and fades out after 24 s, and the then card as a note "KASETA · year". The
  first play of a card: +15 respect and its stamp (the day) in the notebook's KASETA page. The
  ghost uses the buildings' own shader (`building.gdshader`, in a material of its own) with
  its occlusion dither held on everywhere (the occluder set so the shader's side term is a
  constant): no new shader. It casts no shadow and has no emission, so at night it is dim.
- **Spacer** (wander mode; Settings → Jazda → Tryb gry: Miasto / Spacer, saved; offered once
  by a toast after the first pause): no rescue calls ringing and no clocks on a rescue started
  by hand, no Podwózka offers unless asked, the rivals don't call out, the speed traps warn
  and never chase. Every 180-300 s (seeded) a soft hint: the screen-edge arrow (gold, "? N m")
  points at the nearest notebook place not found yet within 1.5 km, for 15 s.
- **Fotka** (Settings → Obraz → FOTKA, or `--fotka`): the HUD goes, the car is held, an
  orthographic Camera3D of its own (`FotkaCamera`; `follow_camera.gd` untouched) orbits the
  car: one finger turns it (yaw all round, pitch 20-70°), − and + or a pinch zoom (30-250 m).
  The style and the VHS overlay apply (the post quad moves to Fotka's camera while open). The
  shutter (FOTKA) hides the controls for two frames and saves the screen as a PNG to
  `user://photos/fotka_YYYYMMDD_HHMMSS_mmm.png`. A photo with a Kadr spot's subject inside the
  frame's central 60 %, the focus within 300 m and at the spot's time of day (`look`) is a
  KADR: +20 respect the first time, the notebook's stamp and the photo (scaled to 120 px tall,
  loaded only while its card is open) on the spot's card. Sharing waits for the Share plugin.
  Closed, Fotka costs nothing: its layer is built at the first open, then hidden; its camera
  is not current; no `_process`.
- **The notebook**: after the nine chapters, three chips: SEKRETY (eggs, 45), KASETA (20),
  KADR (15). Each is a 5 × 3 grid of cards (‹ › for the next page); a found card shows its
  name, its line and the day it was found; one not found shows "?" and a hint (an egg: "not found yet", or
  "still asleep" for a waiting one; a then card: the place to play it; a Kadr spot: the place
  and its time of day).
- **Testing aids**: `--egg=<id>`, `--egg-log`, `--found-eggs=`, `--tape=<id|n>`, `--tape-log`,
  `--spacer` / `--wander`, `--no-spacer`, `--spacer-hint=S`, `--fotka` / `--photo`,
  `--kadr=<n|id>`, `--fotka-shot=S`, `--photo-log`, `--notebook=eggs|tape|kadr|<card id>`
  (flags table).
- **Checks**: `check_eggs.gd` (verify step `eggs`, quick set and CI): the 45 cards (two
  languages, ≤ 70 characters, a place that exists, a reward), every reachable egg's trigger on
  synthetic inputs (it fires with its conditions and not without them), the waiting ones
  listed, the rewards (respect, a track, a then card, a Kadr spot) once, Fat Thursday.
  `check_tape.gd` (step `tape`, quick set and CI): the 20 cards, each ghost (3-24 boxes, one
  surface, 36 vertices a box, no shadow, hidden until played), a grid walk over the map (no
  ghost built further than 150 m from a spot, kept to 200 m), the button's rules, the first
  play's reward once, the dither's kept share following the fade. `check_hud.gd` lays out the
  three sections (a found card, one not found, a later page) and Fotka's controls at its six
  screens.
- **Cost**: the eggs, KASETA's check and Spacer tick at 2 Hz: bench line "eggs+tape+spacer" 0.01 ms
  on the headless bench (budget 0.03). A playing ghost is +1 draw call in the main pass and 0
  in the shadow pass (probe at Plac Defilad, lavapipe 1280x720: main 46 → 47), only within
  150 m of a spot and while it shows; elsewhere and before a play, 0. The notebook's new pages
  draw as many 2D calls as a chapter page (51-52 at 2532x1170 with the card open). Fotka
  closed: 0 (25 2D draws with the HUD either way); open, 23 (the HUD hidden, its own controls).
  The rendered bench (lavapipe, 1280x720): 114 → 113 draw calls (traffic noise).

## The night and the river (loop MW-3, 2026-10-30)

docs/design/vision.md 3.1-3.3, 3.2's Plac Zbawiciela and 4.5. Code: `crowds.gd` (new: every crowd,
its rules as static functions, its drawing), hooks in `main.gd` (section "loop MW-3"),
`time_of_day.gd` (the Dawn look, `fixed_start`), `police.gd` (`club_park`, `club_leave`) and
`police/police_unit.gd` (a `Club` branch), `city_sounds.gd` (`add_crowd`, two loops),
`egg_book.gd` (`crowd`, `days`), `rides.gd` (`club_doors`), `settings_panel.gd` (Świt · Dawn),
`tools/make_sfx.py` (two loops). Data: `data/eggs.json` (E03 E04 E15 woken; E10 E14 a crowd
condition). Lines: the vision's groups already in `dialogue.json` (`club_door`, `clubbers`,
`dawn_crowd`, `schodki`, `police_club`), unchanged.

- **The clock and Świt · Dawn.** `--time=dawn` (and Settings → TIME's fifth segment, Świt ·
  Dawn) is Dusk's palette with the sun at 112.5° (east-north-east): an entry in
  `time_of_day.gd`'s look table, no new shader. Without Live, a night is always Friday's and a
  dawn always Saturday's (05:45); Live uses the real weekday. `--clock=HH:MM` now also sets the
  fixed looks' start (`tod.fixed_start`; the clock runs from it as before, the look stays).
  Eggs see the look as `Dawn`. DAWN is the enum's fifth value, after LIVE, so saved TIME
  settings keep their meaning.
- **The queues** (5 clubs of vision 4.5's table, `crowds.gd` `CLUBS`: Lusterko 24 on the
  after-hours curve, Smoła 24, Jasna 0, Lombard and Miłość Hipoteczna 16): `max × hour curve ×
  weekday`, rounded (Lusterko's Sunday 09-12 at 0.5), rewritten every 20-40 s (seeded), standing
  figures 0.7 m apart on the footway nearest the place (within 40 m; no storefronts until MW-2),
  dark clothes, a broader bouncer at the door. The door: a `club_door` `reject` bubble every
  30-60 s while a queue of 4 or more is on screen (the one turned away goes to the end, or for
  a kebab), a `clubbers` line every 35-60 s. The car at the door (under 10 km/h within 8 m):
  the bouncer's `car` line once per club per night (the garage loop: painted black, `car_black`;
  at Lusterko on a Friday or Saturday night 23:00-06:00 egg E01 and that line, queue or not).
- **Level 26's roof crowd**: built only where the roof grid has a tower over 40 m at the place.
  F's asks (2026-10-30): `places.json` `near` moved onto the tower at Plac Zawiszy (it was 520 m
  west of it; the map's 116 m tower, OSM "Atlas Tower" parts, centre about −2224, 1012), so it
  shows: `roof_ring` traces the roof grid in 48 rays to where it drops below the top floors; up
  to 16 figures stand 4.6 m in from that edge (the roof curve 22:00-03:59; a seeded order round
  the roof); a short queue (`level_26_door`, at most 8, the roof curve, the `club_door` lines and
  the bouncer) waits on the footway at the ground-floor door; while the club is open and the view
  is within 350 m, a violet band (`#a35cff`, 2 m tall, 1 m under the body's roof, one mesh in
  `Models.material()` as LIT_SIGN, so it glows only with the city's lights) rings the top floor.
  The club's bass (`city_sounds.gd`, its `club` tag and hours) comes from the tower's foot.
  Cost at night in view: +2 draw calls (the band, the crowd cell's MultiMesh); 0 by day or far.
- **The dawn crowd** (Sat/Sun 05:00-09:00, Live or the Dawn look): 20-40 walkers (curve 0.5 at
  05, 1.0 at 06-07, 0.4 at 08) in twos and threes from Lusterko, Smoła and Jasna 0 to the Palm,
  Metro Nowy Świat-Uniwersytet, the two nearest tram platforms and the two nearest kebab stands
  (18 routes, 94-1103 m: A* over the footways and crossings in the 128 m cells round the crowds, in a
  WorkerThreadPool task once a run, the first time the dawn crowd comes out). Each walker is a
  point moving along its route at 0.9-1.25 m/s (computed from the clock, not stepped), drawn
  only within 350 m of the view and moved at 10 Hz there; one at a route's end starts again
  from its club. A `dawn_crowd` bubble once per 25 s while walkers are in view; E03 is the
  Palm with walkers out. Podwózka at dawn: 70 % of requests come from an address within 60 m of
  a club door, with a `podwozka_request` `club` note (`rides.gd` `club_doors`).
- **The steps crowd** by Kopernik (vision 3.3): max 80 × hour (10:00 0.1 → 18:00 0.6 → the
  sunset's 1.0 → 23:00 0.7 → 01:00 0.3 → 03:00 0.05) × month (Live; the fixed looks are
  summer) × rain (0.1), in groups of 2-6 sitting in rows facing the river (from the shore) with
  standers at the water's edge; a guitarist (orange) from 8 people, 16:00-01:00. `schodki`
  lines every 35-60 s near it. Sounds: `crowd_murmur` (an 8 s loop, -13 dB, reach 55 m) at each
  queue, the steps and Plan C while 4 or more are out, `steps_guitar` (G C D at 92 BPM, 15.65 s, -12 dB, reach 25 m) with the
  guitarist, both procedural in `make_sfx.py` (seeds 75, 76) and played by `city_sounds.gd`
  inside its cap of 8. E14 needs the steps at 0.8 or more; E15 is the guitarist on three
  different days (the `days` condition: Live's date or the real one, kept in the save).
- **Plac Zbawiciela** (Plan C): up to 40 standing in groups round the square's footways
  (Fri/Sat 21:00-02:00, summer; rain 0.1; curve 0.5-1.0-0.7, a guess). E10's lap needs it out.
- **The police by the clubs** (Fri/Sat 00:00-08:00, Lusterko and Smoła): a patrol car parked on
  the far lane 8 m from the door (`police.gd` `club_park`: an ordinary police unit in a `club`
  role, the beehave branch `Club` keeps it parked, never a chase; spawned off screen within the
  trap band) and an officer in hi-vis standing by it; `police_club` lines to a slow car within
  15 m, at most every 45 s. When the window ends the car is dismissed. E04 is a stop by them.
- **Night buses at Centralny**: built by the night-buses loop (2026-10-31, "The night buses, the
  bus stops and the horn" below).
- **The mesh**: every still figure is the pedestrians' mesh and material (`Models.person_mesh`,
  `actor.gdshader` with `walk = 0`: the legs' swing off), one MultiMesh per 512 m cell with
  every crowd in it, no sun shadow, its AABB the figures' box; a sitter is a lower, longer
  instance (y × 0.6, z × 1.35), not a real pose (BACKLOG). The dawn walkers are one more
  MultiMesh (`walk` 0.16). A crowd further than 350 m from the view's focus has no figures, so
  a cell with nothing near is hidden. `--crowd=0` builds nothing; `--crowd=2` doubles every
  crowd (caps too); the Low tier halves them.
- **Testing aids** (flags table): `--time=dawn`, `--clock=HH:MM` on the fixed looks,
  `--crowd=0|1|2`, `--night-log` (`night:` lines: the minute's summary
  `night: 01:00 day 6 · queues lusterko 10, smola 24, … · rejections 1 · car lines 0 · dawn
  walkers 30 · roof 0, steps 24, plan_c 28 · police on`, every rejection, line, police unit and
  the dawn routes), `--club=<id>` (the car on the lane nearest that club's door, free roam).
- **Check**: `check_crowds.gd` (verify step `crowds`, quick set and CI; committed
  `centrum.json` and `places.json` only, seeded): the clock and the Dawn look, the queue formula
  on synthetic clocks and weekdays (Lusterko's Sunday, the caps, `--crowd` and Low), the door's
  timing (6 rejections in 300 s on screen, none off screen or under 4), the car at the door, the
  steps' curve (sunset, month, rain, the guitarist), Plan C's window, the police window, the
  dawn window and its walker count (30 at 05:45 Saturday, 40 on a Live Sunday at 06:00, none
  on a Wednesday or at 09:00), the dawn routes on the real footways (18), A* on a grid, and E03
  E04 E10 E14 E15 firing on synthetic inputs and not without them (E15 on its third day, paid
  once). `check_sfx.gd` loops the two new sounds.
- **Cost**: (Linux container; before = the code at HEAD from a copy; headless bench and probes with
  `--fixed-fps 60`, two runs each interleaved; draw calls rendered with the software Vulkan
  driver at 1280×720; `--crowd=0` is the A/B with this code):

  | | Before | After | `--crowd=0` |
  | --- | --- | --- | --- |
  | Bench route, day: bench line "crowds" | | 0.01 ms | 0 (not built) |
  | Bench route, day: scripts in all (noise ±0.2) | 3.37 / 3.55 ms | 3.30 / 3.75 ms | 3.20 / 3.60 ms |
  | Smolna 01:00 (`--probe --at=-168,104 --time=night --clock=01:00`): "crowds" | | 0.01 ms | 0 |
  | The Palm at dawn (`--probe --at=-213,250 --time=dawn`, 3000 frames, 30 walkers moving) | | 0.03 ms (0.04 over 600 frames that include the route search's start) | 0 |
  | The steps at dusk (`--probe --place=schodki_kopernik --time=dusk`): "crowds" | | 0.01 ms | 0 |
  | Draw calls, bench route, day (main / shadow / 2D) | 114 (46 / 34 / 33) | 114 (46 / 35 / 33) | 114 (45 / 36 / 33) |
  | Draw calls, Smolna 01:00 | 92 (58 / 0 / 33) | 93 (60 / 0 / 33) | 91 (59 / 0 / 33) |
  | Draw calls, the Palm at dawn (before: Dusk, no Dawn look) | 180 (82 / 61 / 37) | 202 (83 / 77 / 42) | 197 (82 / 77 / 38) |
  | Draw calls, the steps at dusk | 129 (48 / 44 / 37) | 130 (49 / 43 / 38) | 128 (48 / 44 / 36) |

  In view the crowds are +1 main-pass draw (a cell's still MultiMesh; +1 more where a second cell
  or the dawn walkers are in view) and 0 in the shadow pass; the 2D differences are the
  bubbles on screen at the probe's moment (+1 to +4, a speech bubble's panel and labels). The
  Palm's before/after gap is the Dawn look's sun (more shadow casters, 61 → 77), not the crowd:
  compare with `--crowd=0`. Triangles: a figure is the people's mesh; 80 on the steps is +0.01 M
  in the main pass (0.16 → 0.17 M), under the 25 k budget. Far from every crowd (more than
  350 m): no figures, the MultiMeshes hidden, the 2 Hz tick only (bench route, 0.01 ms).

## Everyday life and trends (loop MW-4, 2026-10-30)

docs/design/vision.md 3.4, 3.7, 4.7 and section 5's MW-4 row. Code: `city_life.gd` (new: the dog
walkers, riders, runners, Kolka, Hyrax, the Wiralek cycle, the fascias, its rules as static
functions, its two MultiMeshes), `trend_job.gd` (new: the "Na czasie" job), hooks in `main.gd`
(section "loop MW-4"), `crowds.gd` (`trend` sites: the slots' and Lukrownia's queues),
`pedestrians.gd` (48 `guest` instances after the fixed ones; its `custom_aabb` widened to 12 km, since the guests stand anywhere in the city; `take_guests` hands them over as one buffer), `jobs.gd` (`trend`, `side_busy`),
`rides.gd` (`hurry_to`), `egg_book.gd` (the `event` kind, `fire`, `move_egg`), `sfx.gd`
(`play_at`, seven one-shots), `city_sounds.gd` (the `queue` kind), `tools/make_sfx.py` (eight
sounds). Data: `data/eggs.json` (E16 E18 E19 E27-E30 woken; E20 a crowd condition). Lines: the
vision's groups already in `dialogue.json` (`dog_walkers`, `cyclists`, `runners`, `viral`),
unchanged.

- **Dog walkers** (06:30-09:00 and 19:00-22:30): 5 near the view, 10 within 450 m of Plac
  Zbawiciela or a Powiśle place (×`--life`, the Low tier halves them). Each is a walker (a
  pedestrian guest) on a footway (no deck) with a dog 1.6 m ahead on the lead, 0.9-1.2 m/s,
  joining the next footway at a path's end. Three dogs (long and low, squat and flat-faced, big
  and fluffy; 120 triangles at most, one mesh with the four shapes as a morph family, the
  people's material, no shadow; drawn 1.35× life size so they read at phone distance *guess*), eight
  coats. The dog stops 3-6 s at each tree within 3.5 m of
  its footway (12 m apart at least); the walker waits. A horn within 15 m of a dog: it barks
  (`bark_small` / `_mid` / `_big` by size, at most every 2 s per dog) and one walker says a
  `dog_walkers` `horn` line, at most once a minute. The AI cars' horns at the player count
  (`traffic.gd`'s `blocked_by_player` and `bumped_driver` signals, connected in `main.gd`). Since
  the night-buses loop the player's own horn counts too (the HUD's horn, B).
- **The influencer dog** at Plac Zbawiciela (07:00-21:00): a fluffy dog on the footway nearest
  the square with three photographers round it (guests), a `phone_shutter` every 5-11 s within
  60 m, the walker's `influencer` line to a slow car. E27 is a 2 s stop within 20 m of it (the
  egg moved there with `move_egg`; the `influencer` crowd level).
- **E16, the ball** (07:00-21:00): a ball on the highest roof by Centrum Nauki Kopernik, its dog
  on the open ground nearest it. Fly the helicopter within 4 m of the ball (it is carried), then
  within 8 m of the dog under 30 m: the dog's `dog_walkers` line and E16 (+40).
- **Cyclists** (06:00-22:00; 4 near the view, 8 at 07:00-09:30 and 16:00-19:00): on the 901
  `cycle` paths of the map at 4-6 m/s, 55 % commuters, 30 % Rowerilo (cream bike, grey
  basket), 15 % cargo bikes with a child box *guess*. A car stopped on a cycle path (within its
  half-width + 1 m) for 3 s: a `bike_bell` from the nearest rider and a `cyclists` `lane` line,
  once per 45 s. **The dock**: a row of 6-10 parked Rowerilo bikes (seeded: 9) by the
  `rowerilo_dock` place; the map has no `amenity=bicycle_rental` POIs (BACKLOG for the map
  lane). **E28**: a Rowerilo rider followed 400 m (within 25 m behind, over 8 km/h) "docks"
  with a `cyclists` line (the vision's "to a dock" is simplified: Open Question).
- **Runners** (06:00-08:00, 18:00-21:00): up to 6 within 300 m of a boulevard place or a park,
  3 m/s, a third in Kolka's colours; guests with the walking legs (no running stride yet:
  BACKLOG). **KOLKA** (Wednesdays; Live, or `--zajac`): 12-20 (by date) gather at 18:45, run at
  19:00 at 3 m/s in rows of three to Most Poniatowskiego and back (A* over the footways,
  crossings and cycle paths in the box round both ends, 1,261 m one way; the A* leaves the
  place by a detour, so the club starts at the route's last point within 500 m of it, on the
  boulevard), stand at the start until 19:45. A `runners` line every 40-70 s within 80 m, a
  `watch_beep` as it passes. **The Zając**: the car beside the club's front rows (≤ 25 m
  lateral) at 9-14 km/h for 600 m (a 2 s grace for a lamp post): the `runners` `zajac` cheer,
  a car horn behind, and E29 (+40 respect, once: a second pacing cheers but pays nothing).
- **Hyrax** (Saturdays 09:00-17:00; Live): on the open ground nearest the stadium's forecourt
  place, a ring of 24 roadworks barriers (the dogs' MultiMesh's fourth shape), 14 runners
  looping inside, a HYRAX banner (pixel font) on the side away from the stadium, `runners`
  `hyrax` lines. E30 is a lap round it at ≤ 20 km/h (the `hyrax` crowd level). That morning
  (07:00-10:00) Podwózka's `hurry` riders go to an address within 350 m of the stadium
  (`Hyrax · ...`).
- **The Wiralek cycle**: three slots (Plac Zbawiciela, Chmielna, Tamka), each a trend for 7
  days and a WKRÓTCE NOWE MIEJSCE day: day 1 NOWOŚĆ and a queue of 30, days 2-3 20, days 4-5 8,
  days 6-7 2, day 8 none. The slots are 0, 2 and 4 days apart; one cycle in 12 they line up
  (E19). The day: `--trend-day=N`, Live's date (days since Monday 2026-01-05), or without Live
  the session's (a trend lives four sessions: days 1, 4, 6 and 8; Open Question). The queue
  (crowds.gd's queue code, `trend` sites with brighter clothes and no bouncer) stands 08:00-20:00
  and says `viral` lines by its tag (`new`, `queue`, `gone`); a `queue_chatter` loop at each
  queue of 2 or more (city_sounds.gd, within its cap of 8). The **fascia** over each slot's door:
  WIRALEK (· NOWOŚĆ! on day 1) and the trend word in the pixel font, pink (grey on day 8), facing
  the street, built when the word changes and shown within 320 m. **E18**: one slot seen (within 70 m) on day 1,
  day 4 and day 8 of one trend (kept in the save's `keep`); **E19**: any slot seen while all
  three are on day 1. **Fat Thursday** (Live or `--date`, from the computus): Lukrownia's queue
  of 60, 06:00-18:00; E20 is its `pass` with the `lukrownia` crowd.
- **"Na czasie" · On trend** (`trend_job.gd`): passing an open slot (within 60 m, 08:00-20:00,
  days 1-7) with nothing else on: a request card (pink, #ff7ac8) from an office worker at Rondo
  Daszyńskiego, each slot again after 240 s. Accept: stop 2 s by the queue, then deliver to an
  address door within 300 m of the roundabout in 6 minutes. Pay 25 zł + 8 zł a km by road, +15
  respect, a 10 zł tip *guess*; days 6-7: the `viral` `late` line ("To już niemodne. Napiwku nie
  będzie, sorry.") and no tip; late: half the pay, no tip, no respect *guess*. One activity at
  a time (`jobs.busy()` and Podwózka's offers see it). `--trend-job[=1|2|3] --autopilot` drives
  it.
- **Not built**: one queuer in five holding a phone up (no pose without the shaders' lane), the
  pigeon on days 6-7, the influencer at the window, MERDAK pet shops (no `shop=pet` anchors in
  the places), the armchair man (E34 still waits), the PixelLab pictograms on the fascias
  (BACKLOG).
- **Testing aids** (flags table): `--life=0|1|2`, `--dogs-log` (`dogs: 07:30 day 5 · 10 walkers
  (Powiśle / Plac Zbawiciela ×2) · 2 at trees · barks 0 · horn lines 0` every minute, each bark
  and horn line), `--trend-log` (`trend: slot 1 day 3 queue 20 (WORD, id)` at the start and on
  every change, the slots seen for E18, the job's lines), `--life-log` (`life:` lines: riders,
  runners, Kolka, Hyrax, bells, the Zając), `--zajac` (Live, Wednesday 2026-10-28 19:00, the car
  by Kolka's start; with `--autopilot` the car paces the club 10 m to its side), `--trend-day=N`,
  `--trend-job[=N]`, `--life-soak`.
- **Checks**: `check_city_life.gd` (verify step `life`, quick set and CI; committed
  `centrum.json` and `places.json` only, seeded): the dogs' hours, zones and caps, the riders',
  runners', Kolka's and Hyrax's windows, the car's footprint and clearance, the horn (5 lines and
  150 barks for a horn every 0.5 s for 300 s), the Wiralek cycle on synthetic dates (days, queues,
  tags, words, offsets, the sync every 12 cycles, the sessions), the job's pay (the day-6 no-tip
  joke), the Zając (600 m at 12 km/h; too fast, too slow, too far, the grace), Fat Thursday
  2026-2028 and Lukrownia's queue, E16 E18 E19 E20 E27 E28 E29 E30 on synthetic inputs (each only
  with its conditions, each reward once; E34 still waits), the meshes, and the real city
  (10 walkers at Plac Zbawiciela at 07:30, none at 11:00, a parked car never overlapped, Kolka's
  route, the dock, nothing active 4 km out). `life-soak` (verify step, not in `--quick`):
  `--life-soak` drives the car at the nearest walker or rider at 7 m/s for 10 minutes of play
  (a Friday dusk) and counts every frame a dog, walker or rider is inside the car's footprint:
  0. `check_eggs.gd` knows the `event` kind; `check_sfx.gd` loops `queue_chatter`.
- **Cost**: (Linux container; before = the code at HEAD from a copy; headless `--probe` /
  `--bench` with `--fixed-fps 60`, two runs each interleaved; draw calls rendered with the
  software Vulkan driver at 1280×720, one run each):

  | | Before | After |
  | --- | --- | --- |
  | Plac Zbawiciela 07:30 (`--probe --place=plac_zbawiciela --time=day --clock=07:30`): bench line "city life" (first cut → the cost cut below) | | 0.08 / 0.08 → 0.04 / 0.04 ms |
  | The boulevards, Wednesday 19:02, Kolka running (`--probe --time=live --date=20261028 --clock=19:02 --at=1026,-711`): "city life" | | 0.10 / 0.10 → 0.03 / 0.04 ms |
  | A Wiralek slot (`--probe --place=wiralek_chmielna --time=day --clock=12:00 --trend-day=0`): "city life" | | 0.01 / 0.01 → 0.01 / 0.01 ms |
  | Bench route, day (`--bench`): "city life" | | 0.03 / 0.03 → 0.02 / 0.02 ms |
  | Bench route, day: scripts in all (noise ±0.3) | 3.36 / 3.81 ms | 3.21 / 3.60 ms |
  | "jobs+eggs" (the trend job inside), the four spots | 0.14-0.17 ms | 0.14-0.17 ms |
  | Draw calls, Plac Zbawiciela 07:30 (main / shadow / 2D) | 124 (52 / 35 / 37) | 126 (54 / 35 / 37) |
  | Draw calls, the boulevards 19:02 (night: no sun shadow) | 81 (47 / 0 / 34) | 82 (48 / 0 / 34) |
  | Draw calls, Chmielna's slot 12:00 | 113 (45 / 29 / 39) | 118 (45 / 29 / 44) |
  | Draw calls, a plain day start (`--probe --time=day`) | 124 (55 / 35 / 34) | 125 (56 / 35 / 34) |

  In view: the dogs' MultiMesh +1 and the bikes' +1 in the main pass (Plac Zbawiciela: both;
  the boulevards and the plain start: the bikes), 0 in the shadow pass; walkers, runners, Kolka,
  Hyrax and the queues are guests and crowd cells (+0); a fascia or the banner +1 near it (not
  in view at the slot's probe point, inside the block; the 2D +5 there are the queue's
  bubbles). Triangles: +0.01 M at most. Far from all of it: nothing drawn, the 2 Hz tick only.
  **The cost cut** (same loop, profiled at the two busy spots first; the window's own timer at
  Plac Zbawiciela ~55 → ~38 µs a frame, Kolka ~50 → ~34): the movers are typed `Mover` objects,
  not dictionaries; a step inside its path segment slides along it (no re-placing), a dog's
  tree stop is a binary search and a dog waiting at its tree is not touched; clearing the car
  shifts the walker and its dog by the shove instead of placing again, and near the car the
  shoves hold (they fade once the car is past `reach`, ≥ 10.5 m). Instances are written by the
  step that moved them into the slots of the last full write (a full write only when the lists
  or what is shown change, at a tick); the guests go to `pedestrians.gd` as one packed buffer
  (`take_guests`, merged natively before its send) instead of a call per figure. Kolka's members
  are packed arrays, half of them a step (7.5 Hz each, as the runners), all within `FAR_CAR` of
  the car. Who is on screen is read from traffic.gd's view rectangle (+8 m) at the tick: a mover
  off it steps every 4th step (3.75 Hz, time saved up). `FAR_CAR` 30 → 15 m. The tick reads the
  day number and Fat Thursday only when the date changes, the slots' states only when the day
  does, the tree stops once per path. A spawned mover is cleared of the car at once (a random
  point of a path could be under it: the 25-minute soak found one).

## Storefronts and parodies (loop MW-2, 2026-10-30)

docs/design/parodies.md 2-10 and vision.md section 5 row 3 (loop 2d-2 folded in). Code:
`storefronts.gd` (new: the Frogs, the venue neon, the Leżaks, the metro entrances, the stamp
card, the knock, the kebab boards and the five billboards, the two eggs' places), `props.gd`
(the meshes: `frogs_shop`, `lezak`, `add_scooter_zone`, `add_metro_entrance`, `pedzik_rider`,
`named_kebab_stand`), `city_life.gd` (the Pędzik couriers), `jobs.gd` (the stands as per-tile
MultiMeshes, `stand_points`, `name_stand`, `tag_stand`), `eggs.gd` (`billboard_line`; the KEBAB
billboard now finds its stand), `rides.gd` / `ride_rules.gd` (the `rechotka` quirk and the
`detour` passenger live), `main.gd` (flags, `_build_storefronts`, the sector hook), `sfx.gd` and
`tools/make_sfx.py` (`frog_chime`, `scooter_clatter`). Data: `dialogue.json` (parodies.md 7's
missing lines merged, none changed), `eggs.json` (`easter_rechotka`, `easter_lezak`: 47 cards).
Everything is built at runtime from the data, on both city paths (the prebuilt sectors hold
none of it); nothing new casts a sun shadow.

- **Where things stand (switch built 2026-10-31).** `storefronts.gd` reads the baked content POIs
  ("Content POIs" below): the Frogs are the 163 `convenience` pois with `fr` (the chain), 70 m
  apart (134 picked, plus the triple corners' 8 with spares; the wall rays decide which stand), not on a landmark or by a kebab stand or venue; the triple corners still come
  from the addresses and the junction's twelve sites. The Leżaks are the 468 `scooter` pois (`stand`
  upright, `roof` at `h` m over the ground, every other pose lies) and the zones the 56
  `scooter_zone` pois (the `egg` one holds the standing Leżak); the metro canopies are the street
  `subway_entrance` pois (not `u`), the open front away from `yaw` (the way down), `st` the
  station. The old runtime picks (junction scatter, `_pavement` for the entrances, the density
  caps) are gone, and with them the 108 Leżaks and 14 canopies that failed `check_pois.py`.
  Bike docks and the non-`fr` `convenience` shops are not used yet.
- **Frogs** (parodies.md 2): the real `fr` shops (above), off the landmarks and 20 m from the
  kebab pois and the venues, 70 m apart (`SPACING`); a fixed shuffle (no randomness at
  run time). The triple corners' addresses stand within 26 m of a junction (`JUNCTION_REACH`). **Triple corners**: Świętokrzyska × Marszałkowska and Plac Zbawiciela (`TRIPLES`),
  three Frogs 60° apart round one junction, from the addresses and then twelve sites round the
  junction looked for out to 80 m (`CORNER_FAR`), with spares that stand only if one of the
  three finds no wall. 248 picked, ~200 placed (a Frogs needs a wall).
- **On the wall.** Placement waits for the sector: when a sector is shown, rays at 1.2 m from
  the road point towards the building (`_wall`) find the sector's own wall collider, then a
  square-on ray from just in front of that hit and two more ±2.6 m along it must meet the same
  plane (within 0.35 m) under a roof 5 m up. The shop's mesh (5 × 0.9 m green fascia FROGS at a
  0.12 m letter pixel, the window, the door, a lily-pad blade sign with "24") goes 0.02 m out,
  in one MultiMesh per sector ("Frogs", +1 draw call where any is in view). LoD2 facades work the
  same way (they are colliders too); untested here (no `lod2.*` in this container).
- **The stamp card** (2.4): stopped (under 2 m/s for 2 s) within 8 m of a Frogs door: the
  `frog_chime`, a stamp (toast `FROGS · PIECZĄTKA n/10`), a `rechotka` `stamp` line; one a shop a
  day, ten a day; the 10th is the free hot dog (+10 respect, a note card, the `free` line), and
  the card starts again. Kept in the wallet's `keep` (`frogs_stamps`, `frogs_day`,
  `frogs_today`). `storefronts.gd stamp_rule` is the rule.
- **Podwózka**: the `rechotka` quirk is in the random pool once Frogs exist, at a junction with a
  Frogs within 30 m (a triple corner first); 15 % *guess* of passengers are `detour`: after 8 s
  they ask for a Frogs (`podwozka_passenger` `detour`), and a 2 s stop by one is +½ star once.
- **The venues** (vision 3.1-3.2): the 17 venues' parody names as neon on their facades (18
  signs: Glon twice; Syreni Szept is closed, dark), from the address, else the nearest road, else
  the nearest address within 140 m. Two-line names (MIŁOŚĆ / HIPOTECZNA, PRZEGRYZKI / ZAGRYZKI,
  KASA / BILETOWA); ŻWIR upstairs at 6.5 m. The rows are drawn into an extended copy of
  `neon_signs.gd`'s atlas at setup (that file and `pixel_font.gd` are prebuilt-sector inputs,
  so they stay as they are) and set on each sector's neon material; the sign quads join the
  sector's own `Neon` MultiMesh: **+0 draw calls**. Letter pixel 0.12 m, down to 0.08 m where the
  straight wall is short; 0.14 m off the facade.
- **Leżaks** (5): 30 a km² in the hero districts, 12 elsewhere, on the pavement 12-20 m out of
  junctions (never within 2 m of a lane's middle), lying at a random yaw; one Frogs door in 30
  has one; parking zones (a white 3 × 1.5 m rectangle) every 400 m in the hero districts with
  two or three lying round each, and the one standing in the zone nearest Metro Nowy
  Świat-Uniwersytet (`easter_lezak`). One MultiMesh per sector ("Lezaks", in `fine_detail`,
  hidden in wide views). **The knock**: the car within 1.2 m pushes one 1-3 m (not onto a lane),
  `scooter_clatter`, a `lezak` `knock` aside at most once a minute.
- **Pędzik** (4): couriers in magenta with the 0.45 m square backpack (200 triangles), 4 round
  the view by day and 6 at night (21-06), × the life amount; half on the cycle paths, half on the
  footways, 5-7 m/s; `city_life.gd`'s movers (they step aside from the car like the cyclists).
  One city MultiMesh of 16 ("Pedzik", +1 in view): the bike family's mesh already holds its four
  morph shapes. A near miss (within 4 m, the car over 10 km/h) gets a `pedzik` bubble, once per
  30 s. Loop jobs-2 built the race ("The courier race, the round-up, the payphone and the armchair
  man" below); loop couriers the kerb riders, the couriers waiting at the stands and the dodge ("The
  Pędzik couriers at the stands and on the kerb" below).
- **Metro entrances** (vision 3.5): up to three on the pavement within 70 m of each of nine
  station places (Ratusz Arsenał, Świętokrzyska, Centrum, Politechnika, Rondo ONZ, …), a glass
  canopy and an M post; they and the zones' paint are one "StreetProps" mesh per sector (+1 where
  any).
- **Kebab stands** (6.1): jobs.gd's 42 stands are now one MultiMesh per 512 m tile
  ("KebabStands", a small caster: its sun shadow on High only); U ZDZICHA (Hala Mirowska) and NA CIENKIM (Plac Zbawiciela) get a name board,
  the halls' and the stadium's stands their own `kebab_vendor` lines (`stand_tag`).
- **Billboards** (6.2): eggs.gd's five plus FROGS · TU TEŻ, PODWÓZKA · GPS WIE LEPIEJ, PĘDZIK,
  LEŻAK and WIRALEK (the `signs` lines), text only (PixelLab pictograms: BACKLOG); the KEBAB one
  now stands by its kebab poi.
- **The eggs**: `easter_rechotka` (stop 2 s within 30 m of the first triple corner's junction,
  +20 respect), `easter_lezak` (stop 2 s within 12 m of the standing Leżak, +20); egg_book's
  cards, moved to their places by `storefronts.gd` (`move_egg`).
- **Cost**: setup ~230 ms at the city's start (headless desktop); the wall rays once per sector
  as it shows (`_physics_process`); the hook a frame 3 µs headless (`check_parodies`); no
  per-frame scans (16 m cells for the knock, 64 m cells for the doors, a 2 Hz tick); the bench's
  `storefronts` 0.01 ms. Draw calls (software Vulkan, all passes, day / night): Nowy Świat
  116 → 121 / 95 → 100, Centrum 131 → 133 / 102 → 104, Świętokrzyska's triple corner 131 → 141 /
  108 → 115, zoomed out there (125 m) 155 → 167, the helicopter 210 → 220, the bench route
  120 → 121 (parodies.md 8's ceiling: +15 / 17 / 20). The new billboards cast a sun shadow like
  eggs.gd's older five (+2 shadow draws on High where one is in view).
- **Check**: `check_parodies.gd` (verify step `parodies`, CI too): the rules, the picks on
  `centrum.json` (spacing, density, triples, venues and names, walls in 2D from the outlines,
  Leżaks and metro off the lanes), the brand denylist, the lines and the font, the wall ray on a
  synthetic facade, the hooks (stamps, the free hot dog once, the knock, the two eggs once), the
  cost and the meshes' triangles.

## The courier race, the round-up, the payphone and the armchair man (loop jobs-2, 2026-10-31)

docs/design/parodies.md 4.3 and 5.3, vision.md 3.7 (E34) and 3.9 (T17, E40). Code: `courier_race.gd`
and `roundup_job.gd` (new; both children of `jobs.gd`, which steps them in its own `_process`, so
the bench's "jobs+eggs" line holds them, and answers `busy` / the target / the card keys / the
autopilot for them: one activity at a time, as every job), `storefronts.gd` (`lying_near`,
`collect`, `restore_collected`, the payphone), `props.gd` (`add_payphone`, `carried_armchair`),
`city_life.gd` (the armchair man), `main.gd` (flags, the round-up's construction, key L).
Data: `eggs.json` E34 (`event`) and E40 (`stop`, 8 m, 2 s): no words changed.

- **The courier race** (parodies.md 4.3): at night, a kebab order rolls (`CourierRace.roll`, by the
  order's number) and 1 in 4 (`CHANCE`) a Pędzik courier at the stand challenges: he appears by the
  kiosk, says the `pedzik` `challenge` line, and the rivals' FLASH LIGHTS button reads ŚCIGAJ ·
  PĘDZIK (key L) for 6 s. His way is an A* over the footways, crossings and cycle paths within 250 m
  of the stand and the door (`Crowds.build_routes`, in a worker thread while the order card is up);
  no challenge when it is over 1.6 × the straight line. Accepting starts the delivery (GO) too; he
  rides at 6.5 m/s (23 km/h; loop couriers: at his pace, below). The kebab's status gets the rivals' 1ST / 2ND badge and "Pędzik: N m
  przed tobą / za tobą" (the gap: his way left against the car's road distance to the door, either side of the street, at 5 Hz). At the
  door first: the kebab pays as usual plus **+30 zł +30 respect** (`wallet.pay`, kind `courier`) and
  his `lose` line; second: the kebab pays as usual, his `win` line when he arrives. The kebab's heat
  is untouched; dropping the order (✕) ends the race. On today's map his way is usually about as long
  as the road (footways follow the streets: stand 0 → Oboźna 1, 1,013 m against 1,023 m by road), so
  a clean drive wins; the autopilot (the job's ghost, 222 s for 1 km with the lights) loses at 6.5 m/s.
  The rider is one MeshInstance3D of the Pędzik mesh (shared actor material, no shadow), shown from
  the challenge to 8 s after the door: +1 draw call in view while a race runs.
- **The Leżak round-up** (parodies.md 5.3): **depots** at storefronts.gd's parking zones 1,200 m
  apart (`DEPOT_SPACING`; the standing Leżak's zone left out): 5 on today's map. At night, with
  nothing else on, a teal dashed ring at each and a teal square on the minimap; pull in (under
  8 m/s, within 7 m): the card ZBIERZ 10 LEŻAKÓW and the `lezak` `start` line (GO / NOT NOW; driving
  off is NOT NOW). GO: the 10 nearest lying Leżaks within 600 m (fewer than 4: "Tu już posprzątane")
  get violet pins on the minimap; the target arrow points at the nearest. Within 4 m under 15 km/h:
  the clatter, the Leżak is off the pavement (its sector's MultiMesh rewritten once), +1 in the boot
  (5); full or none left, back to the depot's ring (under 2.5 m/s) to unload; the status shows
  LEŻAKI n/10 · BAGAŻNIK n/5, the 6-minute clock and the hint. All back: **8 zł a Leżak, +40 zł if
  within 6 minutes, +40 respect**, the `done` line on the result card (`RoundupJob.pay`). ✕ pays the
  unloaded ones (no bonus, no respect). The collected ones lie about again when the night ends
  (`restore_collected`; a fixed Night look keeps them gone for the session). Nothing new is drawn but
  the rings (one mesh each, at night while no job runs) and the job's beacon at the depot on the way
  back.
- **The payphone** (E40, T17): an old card payphone (`Props.add_payphone`: a grey post, the box with
  a dark screen, a black handset and a cream card slot under a small blue-grey hood, no operator's
  colours or mark; 120 triangles) on the pavement 2.4 m past the outer lane within 70 m of Plac
  Konstytucji's point (32 m on today's map, -564, 1293), 8 m clear of the metro entrances, facing the
  road; it joins its sector's "StreetProps" mesh (**+0 draw calls**; no shadow). E40 moves onto it
  (`move_egg`): a 2 s stop within 8 m, +10 respect and its card (the T17 line). T17 itself is not a
  KASETA then card (the 20-card set is 2010 to today; Open Question).
- **The armchair man** (E34, vision 3.7): one day in three (`CityLife.armchair_day`, seeded by the
  cycle's day number: Live's date or the session's) in the shops' hours (08-20), a man in a rust
  shirt walks Mokotowska with a 1960s teal armchair upside down on his head: a pedestrians.gd guest
  (+0) on an A* footway way between the street's points 200 m each way of the `mokotowska` place
  (487 m on today's map, from near Plac Zbawiciela to Wilcza), there and back at 0.9 m/s (his place
  on it from the session's clock: nothing steps while he is far); the chair one MeshInstance3D
  (`Props.carried_armchair`, 96 triangles, no shadow) shown only while he is near the view (**+1
  draw call** there). The car within 8 m of him: E34 (`fire`, +20 respect once).
- **Cost** (headless bench, `--fixed-fps 60`; "jobs+eggs" holds the race and the round-up): see the
  table in the loop's report and ROADMAP's row; the race's step 2.6-5 µs a frame and the idle
  round-up's 0.6 µs (`check_side_jobs`); the A* once per challenged order in a worker thread.
- **Check**: `check_side_jobs.gd` (verify step `jobs2`, quick and CI): the race's rules (night, 1 in
  4 over 1,000 orders, the 1.6 × rule, the pay), a race on synthetic footways (a straight way
  challenged, a detour not, the rider's 310 m in 47.7 s, a loss paying nothing, a win +30/+30 once,
  the challenge gone after 6 s); the round-up's rules and a run on the real map's zones (the depots'
  spacing, the card, a full boot of 5, the pay once, late without the bonus, ✕, back by morning);
  the payphone's spot and mesh, E40 once. `check_city_life.gd` adds the armchair man (1 in 3 over 600
  days, there and back, his ends, his way on Mokotowska, the guest and the chair near him and none
  far, E34 once).

## The Pędzik couriers at the stands and on the kerb (loop couriers, 2026-10-31)

docs/design/parodies.md 4.2 and 4.3. Code: `city_life.gd` (the kerb riders, the dodge, the waiting
couriers, `waiting_at` / `take_waiting`), `props.gd` (`pedzik_rider` is now a two-shape morph family:
riding, and `PEDZIK_STANDING`), `courier_race.gd` (the challenger, `pace`, `decent_wins`), `jobs.gd`
(`stand_frames`, the stand's index to the race), `main.gd` (the wiring, `--pedzik-log`, `--pedzik-kerb`).

- **Couriers waiting at the kebab stands** (21:00-06:00): 1 or 2 by each stand within 200 m of the view
  (`waiting_count`, seeded by the stand and the night), standing on their bike's right with the bike
  pointing at the road, at the first two free spots 2.75 m (else 3.9 m) either side of the kiosk (no
  roof, no lane within 1.8 m); none by day. They are instances of the Pedzik MultiMesh after the riders,
  drawn with the rider mesh's standing shape (actor.gdshader's morph): **+0 draw calls**.
- **The courier race's challenger** is one of them: no courier waiting at night, no challenge (unless
  `--courier-race` forces it: then he appears at the kiosk as before). Through the offer he stands where
  he was (the challenge bubble over him); at ŚCIGAJ he gets on his bike (`take_waiting`: he leaves the
  MultiMesh and the race's rider appears riding on his spot) and his way starts there. A taken courier
  is back when the stand has been out of the band (300 m) or by the next night.
- **The race's pace** (BACKLOG "The courier rarely wins"): the rider's time is the order's road at
  `V_ROAD` 10 m/s (`pace`: his way × 10 / the road, 6.5-11 m/s); taking a decent player as 30-50 km/h
  door to door (8-14 m/s, spread evenly), the player wins 2 in 3 whatever the route's shape
  (`decent_wins`). The default route (stand 0 → Oboźna 1: his way 1,015 m from his spot, the road
  1,023 m): 9.9 m/s, 102 s. `--courier-v=` still fixes the speed for a test run. A faster rider, not a
  shortcut: the footways follow the streets (no courtyard paths in the bake).
- **Kerb riders**: 3 round the view by day, 5 at night (× the life amount; on top of the 4 / 6 on the
  cycle paths and footways), on the lane graph's roads with lanes 2.9 m wide or more (no living street,
  no tunnel), riding with the traffic on the outer lane's kerb line 0.45 m in from the kerb (parodies.md
  says 0.6: a traffic car's side is 0.63 m from the kerb on a 3 m lane), 5-7 m/s, across the junctions
  to a road going on (straight or right first, a left turn or the U-turn only when nothing else).
  Same pool of 16 and MultiMesh (+0).
- **The dodge** (every Pędzik rider, at the movers' step near the car): the closest approach of the
  rider and the car over the next second (`closest_approach`, both moving); within 4 m he **swerves**
  1.4 m past the kerb onto the footway (3 m/s sideways; a path rider is on the footway already and
  steps aside with the walkers' shove) or, where the footway there is under a roof, on another road or
  he is on a bridge, **hops** (0.3 s, 0.55 m up). Back to his line 1 s after the car is clear. The old
  clearing (CLEAR of the car's way) stays the backstop: never inside the car's footprint. A dodge with
  the car at 10 km/h or more is a near miss: a `pedzik` line over him, at most once per 30 s.
- **Testing aids**: `--pedzik-log` (`pedzik: 01:30 · 6 on the paths, 5 on the kerb · 3 waiting at 2
  stands · swerves 2 · hops 0 · lines 1` a minute, each swerve, hop, near miss and take),
  `--pedzik-kerb` (the kerb riders start 8-35 m from the view, for shots).
- **Check**: `check_couriers.gd` (verify step `couriers`, quick and CI; `centrum.json` and
  `places.json` only, the stands placed by jobs.gd's own kerb test on the lane graph, seeded): the
  counts (kerb 3 / 5, waiting 1-2 at night over 1,260 stand-nights and none by day, the night the same
  across midnight), the kerb roads, the dodge on synthetic inputs (head on, overtaken 3 m aside, wide,
  going away, far, parked), the hop's arc, the near miss's rate (10 lines in 300 s of near misses every
  2 s at 30 km/h, none under 10 km/h), the real city at night by a stand (its couriers, drawn standing
  after the riders, the race's take and its return, none by day), the kerb riders on their kerb lines
  and still on kerb roads after 20 s, a car driven at one at 10 m/s (a swerve onto the footway and back,
  0 overlaps, one line). `check_side_jobs.gd` adds the pace, the waiting challenger and `--courier-v`.
- **Cost** (Linux container; before = the code from a copy; headless `--fixed-fps 60`, two runs each;
  draw calls rendered with the software Vulkan driver at 2532×1170, one run each):

  | | Before | After |
  | --- | --- | --- |
  | Bench route, day (`--bench`): "city life" | 0.04 / 0.03 ms | 0.04 / 0.04 ms |
  | Kebab stand 0 at night (`--probe --at=632,-52 --time=night`): "city life" | 0.04 / 0.03 ms | 0.04 / 0.04 ms |
  | Draw calls, stand 0 at night (main / shadow / 2D) | 116 (68 / 0 / 47) | 115 (67 / 0 / 47) |
  | Draw calls, a plain day start (`--probe --time=day`) | 129 (59 / 35 / 35) | 129 (59 / 35 / 35) |

  The waiting couriers and the kerb riders are Pedzik MultiMesh instances (+0; the ±1 at the stand is
  which MultiMeshes happen to be in view). Triangles: the rider mesh 200 → 186 (the family drops the
  boxes' unseen bottoms). `check_couriers`: ~35 µs a 15 Hz step at a stand at night with everything
  near (≈ 9 µs a frame). No per-frame scans: the stands are looked at in the 2 Hz tick (42 of them), a
  stand's free spots once, the room for a swerve once per dodge.

## The night buses, the bus stops and the horn (loop night-buses, 2026-10-31)

`game/scripts/buses.gd` (built in `main.gd` after city life; docs/design/vision.md 3.5 "Buses").
It drives the traffic's own buses (`traffic.gd`'s BUS pool of 8, main roads only) and ticks on a
0.5 s timer, with no per-frame scans.

- **The N sign**: from 22:30 to 05:00 game time (`time_of_day.gd` `local_clock`; Night's fixed
  look is 01:30, so it is on) every traffic bus shows an amber **N** on a dark plate: on both
  sides above the windows, at the back and at the front. `traffic.gd` `night_sign` swaps the BUS
  MultiMesh's mesh for `night_bus_mesh()` (the same bus, +195 vertices, `LIT_SIGN` part so it
  glows with the lights). +0 draw calls, no shader change. No real operator's name or logo.
- **The night hub at Dworzec Centralny**: every half hour from 22:30 to 04:30 (13 a night), a
  ring of 5-8 buses (seeded by the day and the slot) gathers in two rows of 4 bays. The bays are
  at the kerb of Aleje Jerozolimskie in front of the station, by the shelters on both
  carriageways (`HUB_ROWS`; there is no bus loop in the lane graph). Each bus arrives within 50 s
  of the slot, stands 2-4 min and then drives on as any bus. The ring is only real while the
  view is within 330 m. Its buses come from the traffic first: a bus out of sight is taken over,
  else a free pool slot is used, so the traffic cap holds. A bus whose bay is out of sight is
  parked there at once. One whose bay is in sight drives in from upstream and pulls in.
  **E23**: the car within 60 m of the ring while 5 or more buses stand there. The `bus_stop`
  night line (index 4) plays once per gathering.
- **Bus stops**: the map's shelters (`highway=bus_stop`, the sector files' `shelters`) that stand
  right of a bus road's kerb lane (lane class 0-1, within 1.5-10 m). The 4 nearest within 170 m
  of the view get 1-2 waiting figures from 06:00 to 22:00, seeded per stop. At night the hub's
  stops get 2-3 figures while a ring stands. The figures are `pedestrians.gd`'s new 8 stop slots
  (the walkers' MultiMesh: +0 draw calls). Standing still (under 1 km/h) within 14 m of a stop with
  people at it gives a `bus_stop` bubble from them, at most every 25 s, and every 90 s per stop.
- **The horn**: a round horn button left of HAMULEC · brake (Classic: left of its brake), or **B**
  on the Mac (H is the helicopter). It plays `horn_player` (make_sfx.py: a two-tone 494/622 Hz
  square, 0.3 s). The dogs react through `city_life.gd` `horn`, and walkers within 9 m coming at
  the car turn round (`pedestrians.gd` `startle`). At most one honk every 0.6 s; it does nothing
  in the helicopter.
- **E24, Na żądanie**: stopped at a bus stop, a honk calls a bus. The car says the `bus_stop`
  request line ("Stoję na przystanku na żądanie. Żądam.", index 2). The nearest bus within 300 m
  with a lane route to the stop comes, or else one from the pool, spawned upstream out of sight.
  It pulls in by the car for 8 s (if the car blocks the kerb lane it stops where it is, within
  30 m). E24 fires when it stands there.
- **E25, Wyścig z nocnym**: a bus leaving the hub's eastbound row while the car is at the ring
  heads for Rondo de Gaulle'a (the Palm, about 1.3 km). If the car gets within 30 m of the Palm
  before the bus, and no speed trap flashed it since the start (`police.gd` `trap_flashes`), E25
  fires (+30 respect). There is no on-screen race card (BACKLOG). A bus on a route never
  chances a red light (the rivals still do).
- **Traffic hooks** (`traffic.gd`): a driver can be sent to a stop (`send_to_stop`: route, the
  kerb lane, pull in by 0.9-1 m, wait, `bus_halted` / `bus_left`), added from the pool
  (`add_bus`) and let go (`let_go`). Hub and called buses are `persistent` while held.
- **Shelters in the exported game**: the stops come from each sector's `res://map/sectors/i_j.json`
  `shelters` list when it is there (editor and Mac runs). Otherwise they come from the sector's
  shelter MultiMesh instances, read once per sector load (a GPU read-back on a real renderer).
  BACKLOG asks the map lane to put the shelters in the index.
- **Testing aids** (flags table): `--night-hub` (a gathering now, whatever the time; with
  `--time=night` the N signs too), `--bus-log` (`buses:` lines), `--honk=F1,F2` (honk on those
  frames). E24 can be tried with `--at=-1388,633 --time=day --honk=300`, and E25 with
  `--night-hub` plus a drive east.
- **Check**: `check_buses.gd` (verify step `buses`, CI too; `centrum.json` only). It covers the
  sign's hours and the night mesh, 13 gatherings a night with rings of 5-8 (88 plans), the
  standing count over a gathering, the hub's 8 bays, the stops on the real map (188 of 351
  shelters), the stop figures (1-2 by day, at most 8), the horn's rate limit and startles, and
  E23/E24/E25 once each through `EggBook` (+30/+15/+30).
- **Cost** (headless bench, two runs each; rendered draw calls with software Vulkan):

  | View | Before | After |
  | --- | --- | --- |
  | Bench route, day (headless, scripts total, 2 runs) | 4.61-4.9 ms | 4.62-5.31 ms (noise); "buses" 0.00 ms |
  | Centralny 01:30 with a ring of 7 (`--probe --at=-1392,640 --time=night --night-hub`, headless) | scripts 4.78-4.85 ms | 4.09-4.24 ms; "buses" 0.00 ms (under 5 µs a frame) |
  | Centralny at night, rendered: draw calls (main / shadow / 2D) | 110 (71 / 0 / 39) | 111 (71 / 0 / 40), the horn's one 2D draw; with the ring: main 71, 2D +4 more while the E23 note and the bubble show |
  | The stop by Centralny by day (`--at=-1388,633 --heading=290 --time=day`), rendered | 145 (61 / 45 / 39) | 149 (61 / 45 / 43): the horn +1, the stop's bubble +3 while it shows |

  The N sign, the ring and the stop figures add no 3D draw call (the bus and walkers' MultiMeshes);
  the horn is one triangle array (one 2D draw).

## The vintage tram and E39 (loop vintage-tram, 2026-10-31)

`game/scripts/old_tram.gd` (built in `main.gd` after the buses; docs/design/vision.md 8, egg E39
"Zabytkowy tramwaj"). It ticks on a 0.5 s timer, with no per-frame scans.

- **The set**: a rounded 1960s-style two-car set, our own shape (no operator's name or logo): a
  motor car with a diamond pantograph and a trailer, carmine red below and cream above, a thin red
  line over the windows, a grey-cream roof rounded at its edges and ends, a four-piece
  windscreen, two headlamps, a lit destination plate with a "T", doors on the right side only
  (a single-ended set), tail lamps on the trailer's back. Each car is one mesh of one surface on
  the actor material (`vintage_meshes()`, made once; 1,238 and 942 vertices, a modern cab car 240).
- **On the tracks**: it is one of `trams.gd`'s eight trams, recruited while out of sight
  (`set_vintage`): the meshes of its own MeshInstance3Ds are swapped and its third car hidden
  (`n_cars` 2, its length 21.7 m for the spacing). It runs like any tram (stops, lights, keeping
  apart) at 8 m/s (29 km/h, the modern ones 40): the trams behind it queue. **-1 draw call** while
  in view (two car meshes for three), never more.
- **When**: Saturdays and Sundays 09:00-19:00 by the game clock (`time_of_day.gd` `local_clock`,
  the weekday the crowds read); with Live, June to September only. One run an hour: it starts at
  a minute seeded by the day (Live: the date; the fixed looks: the weekday) and the hour, in the
  first half hour, and lasts 25 min. A run takes the out-of-sight tram nearest the car (`trams.gd`
  `in_sight`: within the trams' posing reach of the view); when it is over the set turns modern
  again once it is out of sight. The fixed looks' clock is Friday from 14:00 (Day), so without
  Live it shows on the game's Saturday: the Day look from `--clock=` before noon, or Dawn's
  Saturday after 09:00.
- **The sound**: a low creak (`tram_creak`, make_sfx.py: stick-slip pulses through two body
  resonances, 1.1 s) every 6-11 s while it moves within 85 m of the view, and its own two-tone
  gong (`old_tram_bell`, 784 / 622 Hz) where a modern tram rings (`trams.gd` `old_bell`). Both
  go through `sfx.gd`'s six positional voices.
- **E39**: the car (not the helicopter) within 40 m of the set's body, behind or beside it (at
  most 2 m past its nose), adds the metres the set moves; farther than 80 m starts the count
  again (`follow_step`). At 300 m: E39 (+30 respect) and the egg's own line ("Kiedyś skrzypiało.
  Teraz szumi. Tęsknimy za skrzypieniem.") in a bubble over the tram. Vision's reward also names
  the then card T13, which stays waiting: the then cards start in 2010 (QUESTIONS, answered).
- **Testing aids** (flags table): `--old-tram` (the set now on the track nearest the car, whatever
  the time; it stays), `--old-tram=follow` (and the car, with no collisions, kept 22 m behind its
  tail: the view goes with it and E39's count runs), `--tram-log` (`old tram:` lines).
- **Check**: `check_old_tram.gd` (verify step `oldtram`, quick set and CI; `centrum.json` only):
  the window with and without Live and on the fixed looks' clock, one 25-min run in each of 50
  hours with 26 different start minutes, the follow count (adds, holds, resets), the look (two
  cars of one surface, the recruited tram showing 2 of its 3 mesh nodes, no node added, the
  modern meshes back on the way out), and a run on the real tracks: taken out of sight, E39 once
  at 304 m (+30), the count reset 100 m back, modern again out of sight.
- **Cost** (headless bench, two runs each; rendered draw calls with software Vulkan, all passes):

  | View | Before | After |
  | --- | --- | --- |
  | Bench route, day (headless, scripts total) | 2.50-2.83 ms | 2.59-2.66 ms (noise); "old tram" 0.00 ms |
  | The set in view on Marszałkowska (`--probe --at=-1113.2,-263.4 --heading=160 --time=day --old-tram`, headless) | | scripts 2.63 ms, "old tram" 0.00 ms (under 5 µs a frame) |
  | Plain day at the spawn (`--probe --time=day`), rendered | 128 (main 58 / shadow 35 / 2D 35) | 128 (58 / 35 / 35) |
  | The same tram there as a modern three-car tram vs the old set, rendered | 134 (61 / 38 / 35) | 132 (60 / 37 / 35): one car fewer in each 3D pass |

## The garage: Warsztat u Mirka and the paint jobs (the garage loop, 2026-10-31)

docs/DEMO.md 6.2's 10:00 beat and 6.3 "Progression" (złoty buy paint jobs; collectibles open a gold
paint), checklist F4. Code: `garage.gd` (new: the place, the paints, the rules, a 4 Hz look at the
ring), `garage_card.gd` (new: the paint card), `wallet.gd` (`spend`, `paint`, `paints`; the save's
`[garage]` section), `car.gd` (`set_paint`), hooks in `main.gd` (section "the garage loop"),
`hud.gd` / `full_map.gd` (the diamond), `crowds.gd` (the black car at the doors), `egg_book.gd`
(the `paint` and `nights` conditions). Data: dialogue.json's `garage` group (Mirek's lines: `hello`,
`buy`, `black`, `green`, `gold`, `switch`, `short`, `locked`), eggs.json's E01 and E21 triggers.

- **The place**: "Warsztat u Mirka" on Brzeska in Praga (a real street, an invented workshop;
  Mirek is an invented type), at the lane graph's point nearest `Garage.SPOT` (1321, -1948). A
  dashed ring in the garage's blue (`#5aa0ff`, jobs.gd's pull-in look, radius 6 m) on the street,
  and a blue diamond on the minimap (pinned to the rim up to 1.5 km away) and the full map. No sign
  on the building (the venue neon path needs a places.json place; a later item).
- **When it shows**: once the player has earned anything (`open_rule`: a job done, złoty in the
  wallet, or a paint already bought); the default for the beat's "after the first earnings"
  (in the demo's first ten minutes that is the first kebab's pay). The first time, a toast:
  "Warsztat u Mirka otwarty: Brzeska, Praga. Lakier za złotówki." The ring is always open then.
- **The card**: drive into the ring and stop (under 1.5 m/s) with nothing else on (no job, ride,
  race, rescue, police, helicopter, map or settings open): the game pauses under the card like the
  settings card. Title and wallet, Mirek's line (Polish over English), the eight paints as
  swatches (the colour with its stripe, the Polish name, the price, "na aucie · on", "masz · yours"
  or "k/5 sekretów"), the action for the swatch picked (KUP ZA 300 ZŁ · Buy, LAKIERUJ · Paint it
  free, BRAKUJE 120 ZŁ, ZA 5 SEKRETÓW; greyed when it can't be done) and WYJAZD · Drive off (Esc
  too). Leaving takes 20 m before the card can open again.
- **The paints** (`Garage.PAINTS`; prices *guess*, tuned against the first ten minutes: a kebab
  pays ~25-45 zł, Seba's race 150, a rescue ~80-110, so the first paint is reachable by ~10 min):

  | id | Name | Price | Note |
  | --- | --- | --- | --- |
  | red | Fabryczna czerwień · Factory red | free | the default |
  | cream | Kremowy · Cream | 150 zł | red stripes |
  | green | Zielony groszek · Pea green | 180 zł | egg E21 |
  | blue | Wiślany błękit · Vistula blue | 200 zł | |
  | yellow | Żółty jak tramwaj · Tram yellow | 250 zł | dark stripes |
  | black | Czarny lakier · Black paint | 300 zł | egg E01; glows 4.5 (not 1.4) and wears silver stripes that glow 0.9, so it reads at night |
  | pink | Różowy pączek · Doughnut pink | 350 zł | |
  | gold | Złoto Syrenki · Mermaid gold | free at 5 egg cards found | DEMO 6.3's collectible unlock |

  Owned paints are kept (`wallet.paints`: id -> the day bought); switching between them is free.
  The save has no version number, so nothing was bumped: an old save without `[garage]` loads as
  the factory red with nothing owned.
- **The car**: `car.set_paint(body, stripes, glow, stripe_glow)` makes the body's one mesh again
  with the new vertex colours (actor.gdshader's hero part, the same shared material): once per
  change, no new material, node or draw call.
- **E01** (`Czarny lakier`, +50): the car painted black within 8 m of Lusterko's door under
  10 km/h, on a Friday or Saturday night (`nights` [5, 6]: 01:30 on a Saturday is Friday's night)
  between 23:00 and 06:00. `crowds.gd` `door_egg` sees it at the door and calls
  `egg_book.fire("e01")` (the egg's conditions are its paint, night and hours); the bouncer's
  `car_black` line comes with it, queue or not. Elsewhere a black car at a door gets `car_black`
  instead of `car`.
- **E21** (`Pasujesz do menu`, +15): stop 2 s within 25 m of Glon painted green; the café's
  `viral` `glon` line over the car.
- **Testing aids** (flags table): `--paint=<id>`, `--garage`, `--garage=ring`, `--garage-log`;
  `--egg=e01` / `--egg=e21` set the paint and put the car at Lusterko's door / Glon.
- **Check**: `check_garage.gd` (verify step `garage`, quick set and CI; needs no map): the paints
  (8, prices 150-400, black 300, gold behind 5 eggs), the rule in every case, buying with enough
  and too little money, switching free, the gold lock, 10 seeded walks of 200 taps (the wallet
  never below 0, paid = the prices of what was bought, nothing bought twice), the save round trip
  and an old save, the car's body recoloured with the same material and node count, Mirek's lines
  (every tag, both languages, ≤ 70 characters), E01 and E21 on synthetic inputs (not without their
  paint, night or hours; once each, +50 / +15). `check_hud.gd` lays out the card at its six screens
  in four states (on, to buy, short, locked).
- **Cost** (Linux container; before = the code at HEAD from a copy; headless bench with
  `--fixed-fps 60`, two runs each interleaved; draw calls rendered with the software Vulkan driver
  at 1280×720, `--probe --time=day`):

  | View | Before | After |
  | --- | --- | --- |
  | Bench route, day (headless, scripts total) | 5.11, 4.08 ms (earlier 5.03, 5.75) | 4.11, 5.26 ms (noise); "garage" 0.00 ms |
  | Plain day at the spawn, rendered (main / shadow / 2D) | 127 (57 / 35 / 35) | 127 (57 / 35 / 35) |
  | Brzeska by the garage, ring not shown (`--at=1310,-1959 --heading=138`) | 91 (34 / 22 / 35) | 92 (35 / 22 / 35), the same 35 nodes in view (a moving actor) |
  | The garage's ring in view (`--garage=ring`, its own camera) | | 97 (38 / 24 / 35); the ring is one unshaded mesh, no shadow: +1 main draw while in view, 0 away |

  The diamond joins the minimap's one triangle batch (+0 2D draws). The card, open, is a 2D panel
  of its own (the game paused); a new paint makes the body's mesh once (same material).

## The easy-driving loop: drive through the small props (2026-10-30)

The user's call: small things don't stop the car. Lamps and signal poles never had colliders;
now benches, bins, bike racks and advertising columns don't either (`map_builder.gd`
`_build_props`, their `solid` size 0, so `_props` adds no wall faces). Bus shelters, parked cars,
fences, walls, hedges, buildings and the landmarks stay solid. The roadworks' barriers and cones
were already knocked aside (the roadworks loop). The prebuilt sectors carry the colliders, so
they are rebuilt (`map_builder.gd` is one of `city.stamp`'s inputs: `tools/setup_map.sh
--if-needed` sees it). `check_drive`'s lane sweep, runtime city: 71 → 69 car and 176 → 168 bus
boxes in collision.

## The follow-camera loop: Point turns with the car, and a saved zoom (2026-10-30)

From the phone: the camera didn't follow the car while driving, it only swung round once the
finger lifted. That was loop 2a's design for Point (the default controls): the stick points in
screen directions, so a camera turning under a held finger turned the held direction with it
and the car circled (3.8 circles in 10 s, `check_steering --legacy`); the fix was a camera that
waited for the finger to lift. Now (`drive_controls.gd` `FOLLOW_HELD`, false brings the old
camera back):

- Point's camera turns with the car all the time, at the gentler `RETURN_GAIN` (Classic keeps
  `TURN_GAIN`), never over 64°/s, the pixel-grid snap unchanged (`main.gd _update_camera`).
- A held direction keeps the world direction it meant when it was set: it is read against the
  camera's yaw at that moment, so the camera coming round doesn't turn it and nothing circles.
  Moving the finger 20° or more (`REAIM`) sets it again, against the screen as it is then.
- `check_steering`: the held-stick tests (`hold_right`, `hold_diagonal`, `behind`, `release`,
  `keys_right`) read exactly as before (same errors, settling, no overshoot); the camera now
  turns up to 50-60°/s in Point's tests (it was 0), and the car stays nearer the screen's
  middle. The "never while the finger is down" rule applies to Fixed only.

The zoom: five steps of view height (`follow_camera.gd` `VIEWS`: 50, 65, 80, 100, 125 m; 80 is
the default). A pinch takes a step each time the fingers' span changes by 1.2× (`PINCH_STEP`),
the mouse wheel and − / + one step a notch. It is saved (`settings.gd` `view`, `[display]
view`); `--size=` overrides it. A pinch now works on the left half too: a second finger while the
stick's finger is still inside the dead zone (`hud.gd` `PINCH_STICK`) turns both into the pinch
(the first finger always took the stick, so a pinch there drove the car).

## The loading fix: the view's sectors first, proxies that look like the city (2026-10-31)

The user, flying the helicopter at ~44 m on the iPhone 16 Pro Max, saw flat brown slabs where the
city should be: the sector proxies (`sector_proxies.gd`), shown while a sector loads.

**Measured first.** The streamer now counts what the player sees of the proxies on every frame
(`sector_streamer.gd` `_count_proxies`, in the soak's and the passes' stats): a frame with a sector
in the camera's view still a proxy, the nearest such sector's square from the view's centre on the
ground (`proxy_near_m`), the most of the view's ground footprint the proxies covered
(`proxy_share_max`; frames over 5 %: `proxy_share_frames`) and the longest one sector stayed a
proxy in the view (`proxy_run_frames`). Five new passes (`--stream-pass=heli-low|start|switch|look|jump`,
flags table) try the suspects: the helicopter low, fast and turning, the start, a car→helicopter
switch, the camera's look at a new target, a jump.

**The cause, confirmed** on the Mac and on the iPhone 11: not flying (low, fast or turning: 0
frames; the 704 m square round the focus covers any turn of the view at 45 m) and not the start
(a few frames of a tower 366 m off), but **the camera's look at a new rescue or delivery target**
(`camera_shots.gd`: when the vehicle is slow, the camera flies 0.6-3 km to the target and back in
~3 s): the target's sectors weren't wanted until the frustum reached them, loaded one after
another at ~0.5 s each on the phone, and **a target over 1,800 m from the focus was never wanted
at all** (`VIEW_RANGE`: the view tests stopped there), so the whole look showed proxies. A
rescue call ringing while the helicopter hovers at its 45 m is exactly the user's case. Jumps (a
tow, a race start) showed some too: only the car's own sector loads at once.

**The fix** (`sector_streamer.gd`, `main.gd`):
- *The view wherever it reaches*: the frustum is cut to the map's lowest ground and tallest roof
  and kept as a rectangle on the map (`_view_box`); a sector over it gets the planes' tests,
  wherever it is (`VIEW_RANGE` is gone). Cheaper than before: fewer plane tests.
- *Order*: the sectors in the view now first, nearest the view's centre on the ground first (the
  camera's, not the car's: they differ during a look); then the ones a coming view needs
  (`expect_view`, below); then the rest by the look-ahead as before. A load in the view or a
  coming view loads `URGENT_PIECES` (4) pieces a frame; a worker busy with a sector of the last
  class gives it up at its next piece (`aborts`; the sector goes back in the queue).
- *A look waits for its sectors*: `main.gd` `_queue_look` tells the streamer the target's view
  (±137 m) and the halfway view's (±275 m) and starts the look once they are in, at most
  `LOOK_WAIT_MS` 1.5 s later (the camera stays on the vehicle meanwhile; a finger on the stick or
  the pedals cancels the look, as it did). On the iPhone 11 it waited 0.5-1.0 s for the far ones.
- *Jumps*: for `JUMP_FRAMES` (3) frames after a forced load, a sector whose ground is in the view
  loads at once too (the cut is already a stall; `jump_loads`, counted in `forced`).
- *The start*: under the title screen a sector's pieces load all at once (`hurry`), and the title
  offers "tap to drive" once nothing is left to load round the start (`TITLE_WAIT_MS` 8 s at
  most): on the iPhone 11 870 ms after the city is built.
- Turning-aware look-ahead: measured, not built (the helicopter at 360 m on the turning route: 72
  frames with a proxy in the view, the nearest 499 m off, 0.3 % of the ground at most).

**Proxies like the city** (`sector_proxies.gd`, `map_builder.gd`): while the sectors are built
(`bake_city.gd`, or the runtime path's roof pass when there is no `proxies.scn`) the builder notes,
per 4 m roof-grid cell, the colour of the roof that gives the cell its height and of a wall standing
in it (`proxy_colours`, `roof_colour`, `wall_colour`: the LoD2 triangles' and the OpenStreetMap
buildings' own colours; not saved, not in the exported game). The skyline's 8 m boxes take them
(quantised to 5 bits a channel) and merge into rectangles where height, landmark and colours agree;
the tree blobs take the season's leaf colours. Still one mesh and one material a sector (+0 draw
calls). The runtime path's own proxies (no `proxies.scn`) are the baked ones exactly (5 sectors
compared array for array). `proxies.scn` 8.63 → 8.75 MB; 732,384 → 712,774 triangles (at most
14,978 → 14,800 a sector). Shots: `shots/loadfix/proxy_close_before`, `_after`, `_after_runtime`
(`--sectors=proxies --heli --at=-570,100 --heading=90`).

| Passes (Mac, 1280×720, `--fixed-fps 60`, prebuilt) | Before | After |
| --- | --- | --- |
| look: frames with a proxy in view / nearest / most of the view's ground / frames over 5 % / longest (frames) | 417 / 0 m / 100 % / 337 / 81 | 95 / 148 m / 0 % / 0 / 41 (tower tops only) |
| jump (6 jumps): the same; forced loads | 123 / 60 m / 10 % / 12 / 28; 10 | 14 / 176 m / 0 % / 0 / 8; 16 |
| start | 12 / 674 m / 0 % / 0 / 12 | 0 |
| heli-low, switch, heli, car | 0 | 0 |
| Slowest frame while a sector loaded, heli-low: median / p90 / max | 9.7 / 10.9 / 11.7 ms | 9.9 / 11.7 / 13.2 ms |
| Streaming ms a frame, p99 over all frames (heli-low / look) | 0.80 / 0.74 | 0.70 / 0.88 |

| iPhone 11 (`tools/device_run.sh`, `--notitle --prebuilt --stream-log`) | Before | After |
| --- | --- | --- |
| look | 401 / 0 m / 100 % / 283 / 83 | 97 / 0 m / 100 % / **25** / 23 (glimpses as the camera flies past sectors on its way) |
| jump; frames over 33 ms | 120 / 60 m / 11 % / 10 / 29; 11 | 14 / 176 m / 0 % / 0 / 8; 15 (the jumps' at-once loads) |
| start | 19 / 366 m / 0 % / 0 / 16 | 3 / 366 m / 0 % / 0 / 3 |
| heli-low, switch | 0 | 0 |
| Slowest frame while a sector loaded, heli-low: median / p90 / max | 21.0 / 24.9 / 27.6 ms | 21.3 / 24.6 / 28.3 ms |
| 6-minute soak, two runs each (B, A, B, A): frame median, frames over 33 ms, slowest frame that streamed, streaming p99 all / that streamed | 16.67 / 16.66 ms; 3 / 1; 33.9 / 27.8 ms; 1.91 / 2.18, 3.52 / 4.17 ms | 16.67 / 16.67 ms; 3 / 3; 33.4 / 34.0 ms; 1.85 / 1.85, 3.78 / 3.81 ms (0 missing, 74 loads in each of the four) |

Probe (2868×1320, prebuilt): draw calls 138 / 103 / 149 / 220 → 138 / 103 / 149 / 220, video at
the spawn 304 → 304 MB. Vertices (`count_vertices.gd`) 18,701,187 → 18,701,187. Bench (Mac,
runtime path, medians of 3 interleaved): 8.33 → 8.33 ms, scripts 0.90 → 0.90 ms, draw calls 110 → 110.
check_streaming runs the seven passes in part (d): heli, car, heli-low and switch may miss
nothing; start, look and jump may show no proxy over 5 % of the view's ground; jump may load at once.

**The west sectors (2026-11-01).** The look pass failed on every Mac run (s_-6_0 loading at
530 m from the view's centre during the look at -2400, 600). `_queue_look`'s two squares (±137 m
round the target, ±275 m round the halfway view) were smaller than the views: turned 45° and
tipped 30°, a 110 m view covers ±147 m on the map before the towers behind it, which the view
test counts. And the expectation ran out on the wall clock, so on frames slower than real time it
ended mid-look. Now `CameraShots.look_keys` gives the look's views (the car's, MID's, the
target's), `_queue_look` adds the way between them every `LOOK_STEP` (60 m), and the streamer's
`expect_shot` wants every sector whose box meets one of those orthographic frusta
(`ortho_planes`; the target's view at rank 0, the way at rank 1, in the order the camera passes
them). The expectation runs on the streamer's game clock and `hold_expected` keeps it for the
whole look once it starts. The look now waits for 3-14 sectors. Cloud look pass (llvmpipe, about
3 fps, 2-9 s a load): 206 → 34 frames with a proxy in the view, 153 → 27 over 5 %, the look at
-2400, 600 40 → 0. Mac (`tools/verify.sh --only=streaming`, head 39c0ca2): the look pass
0 missing, no proxy in the view.

## Map north: Rondo Radosława, Arkadia and Forest (2026-10-31)

The user asked for Rondo Radosława with its flag, Arkadia and the Forest tower. The map grows north
on its **west side only** (docs/DEMO.md 2.1 "Map north" has the box and why; the hand-over to the
landmarks lane is the table under it).

- **The shape** (`tools/map_shape.py`, new): the map is its bounding rectangle (centrum.json
  `bounds`, as before: x −3,136 to +2,182, z −2,775 to +1,736) without the rectangles in
  `outside` (one: x −1,706 to +2,182, z −2,775 to −2,046, east of the extension and north of the
  old edge). `bake_osm.py` `BBOX_NORTH` is the extension (1,430 × 730 m = 1.04 km²; 21.2 km² in all),
  `BOXES`/`HULL` the boxes and their bounding box, `map_shape()` the Shape (a tuple of the bounds, so
  code that unpacks it is unchanged). It clips roads, lanes and lines to the shape (a line can leave
  and come back: `clip_segments`), cuts outlines across the inner corner to the larger piece, keeps
  points in either box (`in_bbox`), and the lane graph's off-map links pair ends along the outline's
  six sides. `map_builder.gd` has the same shape (`outside`, `in_map`, `map_outline`,
  `clip_to_map`): the earth wall and the invisible edge walls follow the six sides (at the inner
  corner they stop on it), no ground is drawn in the part left outside (the extension's east edge is
  a column of the 10 m lattice, so the ground ends there cell by cell), and the proxies, the sector
  heights, the river walls and `nearest_dry` keep to it. `bake_sectors.py` keeps the sectors that
  meet the map (+10 m): **112** (i −7..4, j −6..3: the box's 108 and i −7..−4 of row j −6; the other
  8 of that row would hold nothing). `check_drive.gd` leaves out the rim along the shape.
- **The data**: everything but the 1 m bare earth was in the demo fetch (it reaches 52.2595).
  Downloads (free, pre-approved): `tools/fetch_demo.py nmt1north`, GUGiK NMT 1 m for the extension
  (+20 m), 2 tiles, 4.6 MB, 38 s, `data/raw/demo/gugik/nmt1_north/` (`prepare_demo.py` and
  `bake_roads` read it with `nmt1_box/`); `tools/fetch_demo.py nmptsites`, the 0.5 m surface model
  over Arkadia, Forest and the roundabout, 3 windows, 2.9 MB, 46 s, `nmpt05_sites/` (the heights in
  DEMO.md's hand-over; no bake reads it). Licence as the rest of GUGiK's data (CREDITS.md). The
  terrain lattice now spans the bounding box (533 × 453 nodes); the box's nodes are unchanged
  (compared node by node), the extension's are from the 1 m data, the part outside keeps the 10 m
  grid's values and is never drawn.
- **Classes fixed over the whole map** (each a rule in the bake; counts by `tools/check_outline.py`,
  new, and check_roads):
  - things past the map's edge (O1-O4; on the old map 33 lines, 3 sand fills and 84 parked cars, up
    to 70 m past the west edge over nothing): parked cars only on the map, the lane, edge and
    cycle markings clipped to it, a median strip's ends and a retaining wall's ends cut back onto it,
    the sand gap fills clipped: **120 → 0** (the extension included);
  - a footbridge the map's edge cuts (Dworzec Gdański's two station footbridges over the platforms:
    3 m over the rails, through a station building; check_roads C3 13, C9 1): left out whole, as are
    any bridge footways joined to one that crosses the edge, unless they run beside a road bridge
    (its pavement): **2 → 0**, 22 ways;
  - a roof car park mapped flat (Arkadia's parking aisle, no layer, 83 % of it inside the mall: drawn
    on the ground through the building, with three bridge ramps rising into the wall; C1 2, C5 2): a
    parking aisle with three quarters of its length inside plain building outlines and no layer,
    level or covered tag is left out with its ramps: **1 → 0** (5 ways; the raw ways stay for the
    landmarks lane);
  - kerbs drawn across a road's end at the old north edge (the kerb walker stopped at the land's
    rectangle, which no longer ends there): the walker uses the shape (O1 23 → 0 on an
    extended bake before the fix).
  - the 4 m roof grid (the helicopter's heights, roof rescues, the landmarks' tap cells) anchored
    on the bounds' north edge moved every cell of the box 1.8 m (check_landmarks: the Presidential
    Palace's tallest cell lost its tap): it keeps the box's lines now (`_roof_z0` through the outside
    part's inner edge). check_ground, check_water and check_drive leave the rim and the part outside
    by the shape (`in_map`), not the rectangle.
- **Looser LoD2 ↔ OSM match** (`bake_gugik.py`): a LoD2 model whose biggest ground triangle's
  centroid misses every OSM outline is now also kept when **half its footprint** lies in OSM
  outlines (sampled every metre) and OSM's height there lies between its eaves and its top (± 6 m or
  25 %); it hides only the outlines the kept footprints cover by half. Of the 389 models the centroid
  rule drops, 13 overlap by half, 8 of them stand as tall (both Old Town blocks the diagnostic found
  among them); the other 5 are older buildings on a rebuilt site. **And a 2018 model under a much
  taller mapped building** (all models in an outline with a mapped height under half of it and
  10 m lower: Forest's 120 m tower had been drawn as a 6.8 m shed, and 45 more in Wola, Muranów and
  Praga) is left out, so the outline draws from OSM. `tools/check_lod2.py` (new) counts an OSM block
  drawn inside LoD2 (L1, doubled) and an outline drawn by neither (L2, lost): on the old map 16 / 81,
  on the extended map with the old rules 16 / 83, now **15 / 73**; against that bake 7 OSM blocks
  gained LoD2 and 57 outlines came back from 2018 models to their mapped height (LoD2 models
  6,157 → 6,119, vertices 1.61 → 1.61 M). L1 and L2 are FAILs above those counts.
- **The checks** in the new area: check_roads found C1 2, C3 22, C5 5, C9 2 not allowed on the first
  extended bake; the classes above took 25 of them; 4 are allowlisted with their reason (a footway
  0.1 m short under Andersa's tram deck, two driveways through a gate and under a colonnade, a
  scanned tree by the Jana Pawła II viaduct) and two old entries no longer match (their LoD2 sheds
  went with the newer-building rule). check_drive drives 22 routes through Rondo Radosława's ring
  and its approaches (`SPOTS`; Jana Pawła II both ways from the old edge to its viaduct, Okopowa,
  Słomińskiego, Andersa) besides every structure both ways (128 routes, 0 height jumps; `ROUTES`
  100 → 150, the extension has six more deck groups). No flag mast is mapped: the roundabout's
  island is bare ground for the landmarks lane (its mast stands in the surface model at (−2,850,
  −2,295), 57.8 m).

| Map north numbers | Before (the box) | After (the box and its north extension) |
| --- | --- | --- |
| Area, sectors | 20.1 km², 108 | 21.2 km², 112 (+4 in row j −6) |
| Roads, paths, trams, areas | 8,038, 19,464, 287, 11,750 | 8,487, 20,677, 334, 12,446 |
| Buildings: OSM outlines (drawn as blocks) / LoD2 models | 12,610 (4,667) / 6,025, 1.55 M vertices | 12,873 (4,825) / 6,119, 1.61 M vertices |
| Scanned trees, pois, addresses | 42,578, 3,548, 3,332 | 44,832, 3,601, 3,378 |
| Lane graph | 2,714 nodes (2,615: 96.4 %), 4,427 edges, 183 signal controllers, 221 off-map links | 2,902 nodes (2,803: 96.6 %), 4,710 edges, 195, 218 |
| Decks, retaining walls | 217 pieces in 55 structures, 1,426 runs | 242 pieces in 59 structures, 1,479 runs |
| centrum.json; ao / lights / water.bin (committed); lod2.bin | 16.3; 40.2 / 40.3 / 20.1; 86.8 MB | 17.1; 48.0 / 48.0 / 24.0; 90.0 MB (the maps span the bounding box) |
| Sector files, index.json; prebuilt sectors, index.res, proxies.scn | 29.4, 9.7 MB; 143 MB (with the pieces), 6.8, 8.8 MB | 31.0, 10.8 MB; 151 MB, 7.3, 9.3 MB |
| check_roads (not allowed / found) | 0 / 302 | 0 / 306 |
| check_outline (O1-O5) | 120 | 0 |
| check_lod2 (L1 doubled / L2 lost) | 16 / 81 | 15 / 73 |
| check_drive (both paths) | 0 not allowed, 62 allowed; 98 routes | 0 not allowed, 62 allowed; 128 routes (22 through the roundabout), 0 jumps |

**The joins loop (loop 3e leftovers, 2026-11-01).** `bake_structures.py`: a trench wall (`place_walls`)
no longer stands inside a tube's mouth (its foot under `MOUTH` over the floor: Plac Na Rozdrożu's west
portals); a low wall no longer stands where a lane runs at its foot (`in_lane` below `top - WALL_MIN * 0.8`,
was `top - 0.5`: Nowy Zjazd); a deck's guard rail is cut where a bus box on a deck lane of its group would
touch it (`BUS_BOX`, `BUS_STEP`, `BUS_PAD`, main roads only: lane_graph classes 0 and 1). Map numbers that
change: retaining wall runs 1,479 → 1,473 (16,094 → 16,042 m, solid 8,976 → 8,969 m), fences, walls and guard
rails cut from the lanes 12,813 → 12,913 m; centrum.json is the only committed bake output that moved.

**Skwer Linearny na Złotej (2026-11-02).** `tools/car_free.py` (`apply(out)`, called by `bake_osm.py` after
`snap_props`, and a command line tool for the baked map, idempotent): streets the city closed to cars after
OSM drew them. Złota between Marszałkowska and Jasna (the linear park, opened 3 August 2026): 6 roads out
(the one-way loop and three service stubs), 3 graph edges `cf: 1` (lane_graph.gd keeps the index but leaves
them out of the adjacency and the grid; 2 nodes off `scc`), 5 road-bed walls and fills out, ped zone
"zlota", 36 limes in `trees3d` (crown 100). Map numbers that change: roads 8,487 → 8,481, ped_zones 83 →
84, scanned trees 44,832 → 44,868 (check_map_data EXPECTED), walls 1,497 → 1,494, fills 682 → 680. ao.bin
keeps no shade under the new limes until the next full bake.
check_drive `--no-allow`: 51 lane spots → 26 (jumps 11, unchanged), allowlist 11 → 8 entries; check_roads
0 not allowed / 304 allowed (unchanged); the bench route is not near these places: 135 draw calls, 3.04 ms.
`check_drive.gd --who` prints the colliders a lane hit meets (the sector's one body, so only the sector).

**Plac Pięciu Rogów and Krucza (F, 2026-11-06).** `car_free.py` zones can be a polygon (`{"poly": ring, "pad": m}`):
zone `pieciu_rogow` is the OSM square (opened 5 July 2022). 5 roads out, 4 more hidden inside it (`hide` ranges),
Chmielna's and Zgoda's 4 graph edges `cf: 1`; the bus/permit route Szpitalna - Bracka/Krucza stays in the graph
(`KEEP_TRAFFIC`) with no asphalt under it. New surfaces `concrete` (#d8d5cd, over the whole outline and Chmielna's
granite) and `wet` (the flush 4.6 m "sadzawka" in place of OSM's raised 3 m pond and its bank). +3 field maples
(`EXTRA_XZ`): trees3d 271,734 → 271,752, crowns 45,289 → 45,292. Furniture: `game/scripts/plac_pieciu_rogow.gd`
(runtime, both city paths, one mesh): 17 wooden-top cubes + 6 plain, 7 lamps, 11 café sets, the egg, 3 bollard
rows, and Chmielna's 17 lamps and 26 café sets either side. Krucza Al. Jerozolimskie → Piękna (543 m) is road
design area `krucza` (docs/roads/krucza.json): 19-20 m one carriageway, 2+2 lanes (3 northbound at
Jerozolimskie), parking lanes, 8 zebras, side streets as openings; `park_cars: true` (new, area level) puts 58
parked cars in the parking lanes (6 old ones on the new asphalt out). Continuity 0.

**Marszałkowska by the art museum (F, 2026-11-08).** Road design area `marsz_defilad` (docs/roads/marsz_defilad.json,
plan docs/plan/marszalkowska-defilad.md): Marszałkowska s 170-328 from the Świętokrzyska junction (the Sienkiewicza
crossing to past Złota) as rebuilt in 2025-26, cross-section from OSM's 2026 crossing ways. 2+2 lanes, the tram bed
between kerbed green strips with 26 young columnar elms (greens `trees`, new; trees3d 271,740 → 271,896, crowns
45,290 → 45,316), the museum's parking lay-by (8 parked cars), no gap in the median: `close_median_links` (new,
area level) marks the OSM zawrotka's graph edge `cf: 1`. Old median strips that ran past a free end keep their rows
beyond it (`medians kept past free ends`). Continuity 0. On a baked map: road_design.py, then
`tools/bus_stops.py` (the bus stop's paint follows the new kerb), bake_sectors. street_pass
marszalkowska-centrum re-recorded: O1 8 → 16 (the lay-by's parked cars by the lane, B8 KEEP), L2 15 → 19 (lane ends at the crossings).

**Marszałkowska Sienkiewicza to Świętokrzyska (F, 2026-11-09).** Road design area `marsz_sienkiewicza`
(docs/roads/marsz_sienkiewicza.json): m_south s 50-170, from the Świętokrzyska junction's arrows to
marsz_defilad's north end, to the city's Zielona Marszałkowska traffic plan. Main painted three northbound
lanes from the crossing on a kerb that slid 2.5 m over 110 m (a lane out of nowhere) and FOOT_PAD had cut the
kerb 2.5 m short of marsz_defilad's seam (the notch). Now: two lanes out of the crossing, the kerb flaring over
17 m (where OSM's verge flares) into the bus stop lane, the west carriageway on a green strip with 10 columnar
elms (trees3d 269,172 → 269,232, crowns 44,862 → 44,872), Fangora's wide mouth keeping its island. road_design.py:
`keep_islands` (area level), LANE_MIN (no lane line while a kerb lane in a taper is under 1.5 m), PastEnds (kerbs,
lines, symbols and ribbons past a free end are not clipped by FOOT_PAD), walls cut only by new asphalt. Then
`tools/bus_stops.py`, bake_street_details, bake_park_details, bake_sectors. retarget_graph: past a free end an
edge keeps its median lane where it was (a centred, widened edge put the northbound inner lane on the Metro
Świętokrzyska platform's edge: check_drive found 13 car/bus hits). street_pass records unchanged.
| Vertices (`count_vertices.gd`) | 18.70 M (meshes 11.50, instances 7.20) | 19.70 M (12.15, 7.55): +1.00 M, the extension's (0.96 M a km²); LoD2 in the box 1,549,362 → 1,548,197 vertices |
| Probe draw calls (spawn, river, zoomed out, helicopter; 3D main / shadow) | 137, 104, 150, 220 (58/38, 36/25, 66/40, 111/74) | 138, 104, 151, 224 (58/38, 36/25, 66/41, 112/76): the city +0 (the helicopter view with `--no-traffic` 102/68 both); one more car or tram in view |
| Probe over Rondo Radosława (`--at=-2833,-2292 --heading=60 --heli --size=150`; the car on Jana Pawła II `--at=-2790,-2200 --heading=340`) | (the map's edge) | 203 (100/68), 115 (46/28): inside the helicopter's 224 |
| Bench (Mac, 1920×1080, medians of 3 interleaved with a copy of the old map) | 8.33 ms a frame (120 Hz cap), process 1.75 ms, scripts 0.86 ms, 111 draw calls | 8.33 ms, process 1.90 ms (runs 1.63-1.95), scripts 0.88 ms, 111 draw calls |
| Memory (probe at the spawn): static / video | 330 / 287 MB | 350 / 289 MB (the bigger index) |
| Build time, the whole city headless (check_drive) | 113 s | 119 s |
| check_streaming | identity OK (108 sectors) | identity OK (112 sectors, 1,806 meshes and MultiMeshes); 10 spots at most 0.059 % of pixels differ; every pass 0 missing (it caught the ground grid's last row past the north edge drawn over the corner left outside: `_cell_outside` treats the outside part's sides on the bounds as open) |

## Content POIs: corner shops, metro entrances, bike docks and the Leżaks (2026-10-31)

The content lane's asks (BACKLOG "From loop MW-2", parodies.md 5.2): the data its runtime placement
lacked, baked into `centrum.json` `pois` by `tools/bake_street_pois.py` (called at the end of
`bake_osm.py` on the finished data, after `bake_structures`; ~8 s). Data only: nothing reads the new
kinds yet, so nothing new is drawn. The new pois come **after** every older one (the older 3,601 are
byte for byte what they were); everything else in `centrum.json`, `ao.bin`, `lights.bin` and
`water.bin` is unchanged. Deterministic: the order and the random numbers are SHA-1 hashes of
positions (`SEED`), never Python's `hash` or a set's order (the full bake and the dry run below give
the same pois).

| Kind | Count | Fields |
| --- | --- | --- |
| `convenience` | 260 | `x, z` the shop (OSM shop=convenience; none below ground), `door` the road point at its door (as `address`), `fr` 1 for the chain the Frogs parody (163), `lv` a mapped level off the ground floor. No names (brands only as parodies) |
| `subway_entrance` | 84 | `x, z`; `yaw` the way down (`atan2(dx, dz)`: `Basis(Vector3.UP, yaw)` turns +Z to it) and `f` how it was found: `steps` (a stair or underground way through the node, its `incline`; 18), `canopy` (towards the centre of the canopy it sits on; 55), `footway` (along the nearest footway, either way; 11); `st` the station (the nearest railway=station station=subway within 400 m: 10 stations), `ref` the exit's number, `u` 1 when it opens off an underground passage only (3) |
| `bicycle_rental` | 92 | the city bike docks: `x, z`, `yaw` along the dock's long side (or the nearest street), `l` its length when mapped as an area (62) |
| `address` (more) | 11 | `name, x, z, door` as the others, `v` 1: the addresses of 11 places of the notebook and the venues that the address bake leaves out (not a home or office: Warszawa Powiśle's pavilion, Kruczkowskiego 3B, is a train_station building; the others address points or halls): `EXTRA_ADDRESSES`. Places resolved by address 5 → 15 of 72. Plac Żelaznej Bramy 1 (Hala Gwardii) is in no OSM element |
| `scooter_zone` | 56 | parodies.md 5.2: a 3 × 1.5 m painted zone on a footway beside a street in the hero districts (storefronts.gd's `HERO`), 400 m apart: `x, z`, `yaw` (the 3 m side along it); `egg` "easter_lezak" on the one that fits nearest a street exit of Metro Nowy Świat-Uniwersytet (within 60 m; at (−547, −308), 5 m off exit 5) |
| `scooter` | 468 | `x, z`, `yaw`, `p` the pose: `lie` 436 (on a footway, 15 m apart, 3 in 10 spots two, near a junction 30 m, a stop 20 m, a metro exit 20 m, the river 80 m or a park's edge 6 m; 2-3 round each zone with `zn` its zone's order), the odd places (1 in 15, 150 m apart): `grass` 5, `bench` 5 (across its front), `frogs` 5 (1 m out of the shop's wall towards its door), `hedge` 4 (half in it), `roof` 12 (1 in 40, on a bus shelter by a mapped stop, `h` 2.6 m over the ground: the shelter mesh's roof); `stand` 1 (the egg's, in its zone) |

- **Density** (parodies.md 5.2, *guess*): 30 a km² in the hero districts, 12 elsewhere, met per
  500 m square on its land (not water): a quota of 469, 468 placed (one square has too few clear
  footway points). storefronts.gd's runtime pick places 277 in 14 zones.
- **Clear of** (`Solids`, shared with the check): the carriageway areas, medians and road strips
  (width + 0.8 m), kerbs (0.6 m), crossings (width + 1.2 m) and their kerb ramps (3 m from a
  crossing's end and from OSM's kerb and crossing nodes), tram tracks (2 m), rails, buildings and
  LoD2 footprints, walls, fences, hedges, steps, guard rails, platforms, islands, fountains,
  flowerbeds, construction, water, piers, tunnel portals (15 m), garage ramps, the metro's stairs
  (3 m round the entrance and 8 m down its `yaw`), poles, trees, benches, bins, racks, columns,
  shelters, parked cars and the Palm; 10 m inside the map's outline.
- **The check** `tools/check_pois.py` (verify step `pois`, ~4 s; quick too): Q1 off the map, Q2 on
  the carriageway, Q3 on a crossing or kerb ramp, Q4 in or against anything solid, Q5 not on its
  spot (off the footway, the grass, the hedge, the bench, the shelter's roof), Q6 the rules (the
  density, zone spacing, one egg zone with one standing scooter, the odd and roof shares, a yaw on
  every entrance, a door on every shop): **0** each. Run on a dump of storefronts.gd's runtime
  picks (`--points=`): of its 277 Leżaks 108 fail (Q1 1, Q2 44: 36 on the carriageway and 8 on a
  tram track, Q3 44: 27 on a crossing and 17 on a kerb ramp, Q4 19); of its 25 metro entrances 14
  (4 on the carriageway, 2 on a crossing, 8 in a building, on steps or a platform).
- **Look**: `python3 tools/overlay_pois.py OUT.png X Z HALF` (Pillow) draws them over the photo.
- **Dry run**: `python3 -I tools/bake_street_pois.py [centrum.json] [osm_demo.json] --out=FILE` adds
  them to a finished map elsewhere (it won't write into `game/map`: re-bake with bake_osm.py).
- **Sizes**: centrum.json 17.11 → 17.17 MB (+64 KB), index.json 10.77 → 10.84 MB, index.res
  7.60 → 7.63 MB; the sector files and scenes, vertices, draw calls and the bench unchanged (no
  geometry). The kebab run's order 0 changed with the longer address list (Oboźna 1 → Emiliana
  Konopczyńskiego 3, 1,266 m by road): verify's `kebab` step runs 21,000 frames.

## The L-shaped map in gameplay (2026-10-31)

Since map north the map is its bounding rectangle without the north-east corner left `outside`
(see "Map north"). What still used the rectangle now uses `map_builder.gd`'s shape (`in_map`,
`map_outline`, `outside`; that file unchanged):

- **The helicopter** (`heli.gd`): `set_map(map)` takes the bounds and each outside part grown by
  the 12 m pad (`keep_out`); `clamp_to_map(from, to)` clamps to the bounds, then out of a part
  along the side the move crossed last (by the sweep's entry time), so it slides along that side,
  and round the inner corner without flicking between the two sides; a point already inside a part
  (a teleport) goes out by the nearest inner side. Two rectangle tests a frame. (A bug found on the
  way: a Vector2 clamp compared with the double-precision position zeroed the velocity every
  frame; axes are compared within 1 mm.)
- **The car's tow off-map test** (`main.gd` `_node_spot`): a junction lane `in_map(q, -12)`;
  `--stream-soak`'s tour skips a sector middle in the corner.
- **Rescue spots** (`missions.gd`, `EDGE_PAD` 40 m; `_inner` is gone, check_landmarks and
  check_water no longer set it), **the barriers' street** (`eggs.gd`, 120 m in: the day's street
  can change near the corner, as the pool of segments shrank), **Podwózka** (`rides.gd`): the
  named finishes 40 m inside the outline, the river spots (the baked `drivable_bank` and the scan's)
  `in_map(p, -SCAN)`.
- **The minimap and the full map** (`hud.gd` `_minimap_mesh`, one mesh: +0 draw calls): first the
  off-map ground (`OFF_MAP` #c8b48e, a frame 6 km round the bounds and each part left outside, so the
  corner reads as off the map at every zoom), then parks, streets and tunnels without any triangle
  whose middle lies in a part left outside, the edge line round the outline (six sides).
  `setup_minimap(data, outline, outside)` (defaults: the bounds' rectangle). The full map draws the
  same mesh; its pan stays in the outline's box (the bounds), the outside shaded.
- **Notebook places up north** (`game/data/places.json`, `near` hints, "?" like the rest): Rondo
  Radosława (chapter `kiedys`: the 63 m flag mast of 2014, flag over 100 m²), Arkadia
  (`codziennie`: opened 2004, about 230 shops) and Forest (`bary`, "new Warsaw": the 120 m tower,
  about 200 trees round it), radius 40, `heli_radius` 60, tag `north`. A chapter now holds 8 to
  `Notebook.MAX_PER_CHAPTER` (10) cards: the counts and the toast use the chapter's own size, a
  chapter over 8 draws its cards 5 x 2. `check_places`: the hints in the demo box or map north
  (`BOX_NORTH`), the places `in_map`.
- **check_police P12 "guard car follows 15 s"** was flaky (1 run in 12 alone): the guards' car is
  put on a road at a random spot 150-300 m out (guards.gd `_spawn_car`, the global `randf`), and on
  the check's one straight road 4 tries of 8 spots in 8 s could all miss. `_fresh` seeds the global
  random numbers (`FRESH_SEED`) for every case, the wait is up to 30 s (the car comes out at 0.5 s):
  20 of 20 alone, 21 of 21 three at a time.
- **check_edge.gd** (new, step `edge`, centrum.json only, CI too): E1 the helicopter's clamp
  (4,000 random moves, four flights past the inner corner: never off, never a step back, never
  stuck), E2 the rescue spots (591, all `in_map(p, -40)`), E3 the minimap mesh (no street or park
  in the corner, the off-map ground over it whole, the edge's vertex at the inner corner).
- **Cost** (Linux container, headless bench `--fixed-fps 60`, before = HEAD from a copy, runs
  interleaved): frame 6.57 / 6.70 → 5.60 / 6.76 ms, scripts 5.79 / 5.96 → 4.98 / 6.01 ms (noise),
  hud+minimap 0.15 / 0.14 → 0.13 / 0.15 ms, heli 0.00. Draw calls +0 (the off-map ground is in the
  minimap's one mesh), no new shader.

## Save v2 and the districts (loop 3h slice 1, 2026-10-31)

Part of loop 3h, the demo loop (`docs/design/loop-3h-handover.md`, DEMO 6.2-6.3, checklist G3).

**Save v2** (`wallet.gd`, `settings.gd`):

- `user://save.cfg` carries `[save] version = 2` (`Wallet.VERSION`). A file without it is version 1
  (every save before loop 3h). Loading one: `Wallet.migrate(cfg, 1)` in memory (nothing is renamed
  from v1 to v2: wallet, jobs, best, eggs, police, keep, notes, notes_chapters, polnoc, tapes, kadr,
  kadr_photos, garage all load as they were; an egg saved as `true`, v0.65, becomes 1, a `false` one
  is dropped), a copy of the old file is kept once as `user://save.v1.cfg` (`backup_path`), and the
  next save writes v2. The log says `wallet: save version 1 migrated to 2 (...)`; the `save:` line
  ends `save vN` (0: no file).
- New in v2: `[districts]` (id = the day discovered), `[district_jobs]` (id = jobs done there; `pay`
  with a kind counts one in `wallet.district`, the district the vehicle is in, set by districts.gd,
  not saved) and `[syrenki]` (id = the day; empty until the Syrenki slice). `reset()` clears them.
- A section this build doesn't know is kept and written back as it was (`_extra`). A file of a newer
  version (`newer`) is read but never overwritten (a warning says so). TEST · BENCH puts
  `district_jobs` back with the rest of the wallet.
- `user://settings.cfg` carries `[meta] version = 2` (`Settings.VERSION`); a file without it is
  version 1 and loads as before (loop G1's High → Auto rule is that migration); a newer one is never
  overwritten.
- `--nosave` still neither reads nor writes either file (no migration, no backup).
- `check_save.gd` (step `save`, CI too): a version-1 fixture built in the check with every section
  (and one "from a newer build") loads with every value, reports 1 → 2, keeps a byte-equal backup;
  the next save writes v2 and keeps the unknown section; the v2 sections round-trip; a job paid in a
  district counts there; a newer file is never overwritten; `--nosave` writes nothing and reads no
  v1 file; a missing file gives the defaults; settings.cfg's version, its v1 load and a newer file.
  Scratch files only (`user://check_save*.cfg`), deleted after.

**The districts** (`districts.gd`, new; `data/districts.json`, new):

- **Data.** Nine districts from DEMO 2.3, in priority order (a point belongs to the first whose area
  holds it): Praga (everything east of a river line traced from the map's water and the embankment
  roads), Stare Miasto, Muranów (with Arkadia), Śródmieście (and the Rondo de Gaulle'a corner, so
  the Palm is Śródmieście's), Trakt Królewski (Krakowskie Przedmieście, Nowy Świat, Plac Trzech
  Krzyży), Powiśle, Wola (Rondo Daszyńskiego), Śródmieście Południowe (Plac Zbawiciela, Koszyki,
  Politechnika; not in DEMO 2.3) and Ujazdów i Łazienki (the Sejm; the park is south of the map).
  The first five are DEMO's hero districts. Each has its names, a card line [pl, en], a label point
  and `jobs_goal` (3 for a hero district, 2 else). `places.json` and `eggs.json` gained a `district`
  field on every entry (computed once from the place's `near` hint; an egg takes its place's).
  Places per district: Śródmieście 22, Powiśle 15, Południe 10, Trakt 9, Praga 8, Muranów 5, Stare
  Miasto 4, Wola 2, Łazienki 0.
- **Discovery.** At 3 Hz (a timer, the notebook's probe) the vehicle's district is looked up: ≤ 9
  boxes, then the polygon (2.3 µs a lookup in the check). Entering one for the first time: the note
  card under the wallet, "Odkryto: Powiśle" over "Powiśle discovered", the district's line in Polish
  and English, "3 × ? na mapie · on the map", +10 respect (*guess*), the blip and a 40 ms buzz,
  saved. The district the game starts in is discovered quietly (DEMO A2: nothing between the first
  tap and driving). A v1 save's districts (those of every place or egg already found) are
  discovered quietly at setup. Nothing happens on the title screen or during TEST · BENCH.
- **The "?" marks.** In each discovered district its first three places not in the notebook
  (nearest its label first) are "?" on the minimap (when in its reach) and the full map; a place
  found makes room for the next (`notebook.gd` `extra_marks`, the notebook's own 400 m marks stay).
- **Completion** (`progress`, `percent`): places + eggs (those that can be found: no `waits`) +
  Syrenki found in the district, plus its jobs done up to `jobs_goal`, over the same in all, rounded
  down (100 % only when everything is done). The Syrenki are a hook: `add_syrenka(id, district)`
  lists one, the wallet's `syrenki` marks it found; none exist yet, so 0 of 0.
- **On the map** (`full_map.gd` `set_districts`, called by main.gd after the map opens): the
  districts not discovered yet under a light fog (each district's own shape, the earlier ones cut
  out, clipped to the bounds and triangulated once: a few dozen triangles in the overlay's one batch,
  +0 draw calls), each discovered one's name and per cent at its label, and the DZIELNICE ·
  districts card on the left: one row per district ("Powiśle · 7%", or "? ? ?"), "Razem · in all".
  The map is paused, so none of it costs a frame while driving.
- `check_districts.gd` (step `districts`, CI too, no map): the data (names, Polish lines ≤ 70, the
  labels in their own districts, the five heroes), a 50 m grid over the bounds all covered, eleven
  known spots in the right district, every place and egg tied (a place's to its hint, an egg's to
  its place's), ≥ 3 places in each hero district; the flow (quiet start, one card for Powiśle, +10
  respect, nothing while away), the marks (3 a district, refilled), completion (jobs up to the goal,
  an egg, a Syrenka listed and found, 100 % when all is done), the presets, a v1 record's quiet
  discoveries, the fog tiling the bounds exactly once (and none when all are found), the lookup's µs.
- **Testing aids**: `--district=<id>`, `--districts=all|none|<id>[:jobs],...`, `--districts-log`
  (the flags table); with `--fullmap` and `--found=` / `--found-eggs=` for the map's shots.
- **Cost** (Linux container, headless bench `--fixed-fps 60 --monolithic`, two runs each; before =
  HEAD before the change): frame 2.32 / 2.67 → 2.35 / 2.49 ms, scripts 1.99 / 2.32 → 2.03 / 2.14 ms
  (noise), "districts" 0.00 ms, hud+minimap 0.08 / 0.09 → 0.08 / 0.09. Draw calls +0 while driving
  (the card is the existing note card, the marks join the minimap's batch); the open full map adds
  its fog to the overlay's one batch, plus the card and the labels' text (the game is paused).

## Syrenki (loop 3h slice 2, 2026-10-31)

DEMO 6.3 and checklist F4: 20 small mermaid figurines by the kerb round the demo's districts, to
find by driving past. `scripts/syrenki.gd`, `data/syrenki.json` (the designer's words, written in
this slice for review).

- **Data.** Each entry: `id`, `district`, the anchor (`place`: a places.json id, or `near`:
  [lat, lon]), `real` (the Old Town's statue), `name` and `line` [pl, en] (at most 70 characters);
  `near` 7 m (the pickup radius), `respect` 5 a find, `rewards`: at 5 the paint "Łuska Syreny"
  (`scale`), at 10 150 zł + 50 respect, at 20 the paint "Srebro Syreny" (`silver`) + 300 zł, each
  with its card's words. Each is listed under its district (`districts.gd` `add_syrenka`), so it
  counts in that district's % on the full map.
- **Placing** (`place_all`, needs the lane graph and the ground): the nearest ground-level street
  within 150 m of the anchor (no tunnel, no deck, no bridge), the figurine on the kerb side
  towards the anchor, past the outer lane's edge plus 2 m, pushed out by 1 m steps until no lane
  centre is closer than half a lane and 1 m; facing the street. No random: the same every run.
  Height from `ground_height`. `--syrenki-log` prints each one's spot, its distance from the
  anchor and from the nearest lane centre.
- **The prop.** One MultiMesh for all 20 (+1 draw call in all the city, only while one is in
  view; under the world's SubViewport like every prop), one mesh (`figurine_mesh`): `Props.mermaid()`
  scaled to 3 m with a cyan cube stood on its corner floating at 4 m (Models `LIT_SIGN`: it glows
  at night), so a Syrenka reads from the follow camera; `Models.material()`, no shadow, no
  collision. At 1.7 m she was walker-sized and did not read in the shots. A found one is a zero-scale instance (at load too).
- **The find.** A 5 Hz timer compares the vehicle (the notebook's probe) with the figurines not
  found: under 7 m on the ground plane (flying: and under 20 m above the ground). First find:
  `wallet.syrenki[id]` = today (saved), +5 respect, the card `SYRENKA n/20 · MERMAID` (name, then
  the line in Polish and English), the blip and a short buzz. A count that reaches a reward's `at`
  gives it once (the count only grows): its card follows the find's after 5.8 s (`hud.show_note`
  shows one card at a time; cards queue in `syrenki.gd`). The paints are derived from the count:
  `garage.gd` PAINTS `syrenki` 5 and 20, `rule(..., syrenki)` says "locked" below it; the card
  shows "n/5 Syrenek". The garage card is now two rows of five swatches (ten paints).
- **On the map**: the districts card lists "Syrenki n/20" above the total (`full_map.gd`
  `set_districts`).
- **Checks**: `tools/verify.sh --only=syrenki` (`game/tools/check_syrenki.gd`, map-free): the
  data (20, unique, districts, anchors inside their districts, words), a find and its card, the
  repeat, the ladder (5, 10, 20, once each), the save round trip (a scratch file), the districts'
  completion, the look's µs.
- **Testing aids**: `--syrenki-log`, `--syrenki=all|none|<n>|<id>,...`, `--syrenka=<id|n>[:m]` (the
  flags table).
- **Cost**: the 20 distance checks at 5 Hz are about 8 µs a look (`spent_usec`, the bench's
  "syrenki" line); the figurines are one draw call and ~20 x the mesh's triangles.

## The rival ladder and the final "Trzy mosty" (loop 3h slice 3, 2026-10-31)

DEMO 6.3 "Rival ladder" and "Progression" ("Respect unlocks rivals and the final race").
`scripts/ladder.gd` (new: the order, gating and record, map-free), `scripts/trzy_mosty.gd` (new: the
final's route on the lane graph), the flow in `rivals.gd`.

- **The ladder.** Six rungs in order of stake: Pani Halina 60 → Słoik z Radomia 90 → Bulwar Bartek
  120 → Seba z Pragi 150 → Taksiarz Zbyszek 200 → Mordor Mike 300 zł, then the final. A rung is open
  when the one before it is beaten AND the respect is at least 0 / 100 / 250 / 400 / 600 / 850; the
  final needs Mike beaten and 1100. A race win is +100 respect, so from Bartek on the jobs, districts
  and Syrenki fill the gap between rungs (`check_ladder` proves race wins alone stop at Bartek). A
  beaten rung stays open: re-races pay the stake again, as before. A race started by `--race=N`
  ignores the gating and counts on the ladder only if the rung was open.
- **A locked rival** still shows the prompt behind it, grey: "SŁOIK Z RADOMIA · NAJPIERW HALINA" /
  "locked: beat Pani Halina first (L)", or "· SZACUNEK 250" / "respect 250". Flashing gets a refusal
  bubble in their voice (RIVALS `refuse`, Polish above English, ≤ 70 characters) and an 8 s pause
  before the prompt comes back; no race.
- **Pace** (the rival driver's `speed_factor` / `accel_factor`, was a flat 1.45 / 1.7): Halina 1.25 /
  1.5, Słoik 1.3 / 1.55, Bartek 1.35 / 1.6, Seba 1.4 / 1.65, Zbyszek 1.45 / 1.7, Mike 1.5 / 1.75; Seba
  in the final 1.45 / 1.7 (*guess*, for the phone: Halina should be beaten narrowly by an ordinary
  player). The `--autopilot` ghost is still 1.8 / 2.2. In a race these factors do not set a
  rival's speed (racer mode, 2026-11-04): since the racer AI rebuild's step 2 (2026-11-10) each
  rung races its skill profile (`share`, `race_accel`, `brake`, `lat`; docs/design/race-ai.md 6).
- **New rung open**: a toast "Nowy rywal: Słoik z Radomia" / "New rival: … · 90 zł" (and "Finał
  otwarty: Trzy mosty · w nocy") when the open count grows (the wallet's `changed`, or a rung beaten).
- **The record**: the save's `[ladder]` section (`wallet.ladder`: rung id `halina` … `mike` and
  `trzy_mosty` = the day first beaten). No version bump: a v2 file of slices 1-2 (or a v1 file) loads
  as nothing beaten, money kept; an older build keeps the section as an unknown one. `final_won` (the
  `trzy_mosty` key) is there for the end card (slice 4). `--nosave` writes nothing; TEST · BENCH
  puts the ladder back with the rest of the wallet.
- **On the full map**: the DRABINKA · rival ladder card top right (`full_map.gd` `set_ladder`, rows
  from `ladder.gd` `rows`): "★ Pani Halina · 60 zł" beaten, "→ Słoik z Radomia · 90 zł · szacunek ·
  respect 100" next (or "otwarty · open"), "· …" locked; the final last: "→ Finał · Trzy mosty · 500 zł
  · w nocy · at night" by day, "· Rondo Daszyńskiego" at night. Labels only, the game paused.
- **The final "Trzy mosty"** (`trzy_mosty.gd` builds it once at setup; `rivals: Trzy mosty: …` in
  the log): from Rondo Daszyńskiego (the start lane on Prosta by the roundabout, heading east) **east
  over Most Śląsko-Dąbrowski, back west over Most Świętokrzyski, east again over Most Poniatowskiego**
  to the National Stadium (the finish: the named street's node within 270 m of the PGE Narodowy poi
  nearest by road from the last bridge but at least 400 m on: Aleja Poniatowskiego at the stadium's
  south stands). 10.1 km by road. Each bridge is a checkpoint at the middle of its river span (the
  longest `br` edge of that name going that way, ~500 m), between the carriageways: it counts within
  20 m and 6 m of the deck's height (never from a road under a viaduct), in order, at 5 Hz.
- **At night only** (the Night look, or Live with the lights on: rides.gd's rule; the clock is never
  changed): once the final is open Seba waits at the start (moved there only out of sight, 180 m from
  both spots, and held), the race beacon in gold at the start with a gold diamond on the minimap
  (pinned to the rim at any distance, `hud.set_minimap_final`) and on the full map; hidden while a
  rescue or side job runs. Drive into it (10 m): Seba's challenge, the banner TRZY MOSTY, 3-2-1. By
  day the ladder card says "w nocy · at night".
- **The race**: the beacon on the next bridge's checkpoint (then the finish), the edge arrow and the
  minimap target follow it (`target_position`), a toast "MOST 1/3 · Most Śląsko-Dąbrowski" at each;
  the status reads "MOST 2/3 · TRZY MOSTY" (then "META"), the metres to it, the clock and 1ST /
  2ND (both measured along the route: the current leg's distance plus the legs after it). Seba
  drives seven legs on the lane graph (each span's near end, then its far end, so his shortest path
  really takes that bridge; then the stadium), re-targeted with `traffic.race_to` when he reaches
  each; the legs' distances are computed one a frame during the challenge (~8-12 ms each in the
  container), kept for a rematch. **Win**: the card "TRZY MOSTY · WYGRANA" (the first time "KRÓL
  NOCNEJ WARSZAWY!" / "King of Warsaw by night!"), +500 zł, +250 respect, a best time under
  `race:Trzy mosty`, `trzy_mosty` saved; a rematch pays the same. **Lose** (Seba at the stadium first,
  or the ✕): "Rewanż: Rondo Daszyńskiego, w nocy" and the marker comes back. Seba's final lines:
  `FINAL_LINES` (wait, challenge, win, lose).
- **Checks**: `tools/verify.sh --only=ladder` (`game/tools/check_ladder.gd`, CI too): the rung data
  against RIVALS, the gating and the missing words, a whole ladder walk, the rows, the words' lengths,
  the save (round trip, v2/v1 without the section, `--nosave`, `--ladder=N`) and, from the committed
  centrum.json, the route (the three spans east/west/east, each span its own shortest way, the legs
  route, the start and finish, a checkpoint not counting 10 m under or 30 m aside).
- **Testing aids**: `--ladder=N`, `--trzy-mosty` (with `--autopilot` the ghost drives the legs; the
  log's `trzy mosty:` lines: the start, the length, each checkpoint, Seba over each bridge, the
  result).
- **Cost**: the start look and the checkpoint test at 5 Hz (a few distance tests); the ladder's
  `open_count` (~20 µs) only when the wallet changes. +0 draw calls while driving: the start marker
  is the race's own Beacon, the diamond joins the minimap's batch, the card is labels on the paused map.

## The first 10 minutes and the end card (loop 3h slice 4, 2026-10-31)

DEMO 6.2 "The first 10 minutes" and 6.3 "The end of the demo". `scripts/first10.gd` (new: the
director and the end card; its rules are static functions, map-free), small hooks in `jobs.gd`
(the guided first order), `rivals.gd` (Halina's first race), `hud.gd` (the ghost finger, the HELI
chip, a card button's own two words), `missions.gd` (`held`, `ring_in`), `garage.gd` (`held`),
`police.gd` (`arm_first_contact`, `first_armed`), `wallet.gd` (`[intro]`, `jobs_done`) and `main.gd`.

- **Who gets it.** A normal launch (the title screen) on a fresh save: no job done, no złoty, no
  ladder rung and `[intro] done` not set (`First10.guide_due`). Test runs never, unless `--first10`.
  A player who quits before the first delivery gets the guide again next time; once anything is
  earned it never comes back, and nothing stays locked for a returning player.
- **A director, not rails.** Five looks a second on the seconds of play since the title; each beat
  is "met" when the player gets there alone and "fired" when the director pushes it (`decide`), and
  every push waits while a job, a race, a rescue, a police stop, the garage or a card is on. One
  `first10:` line per beat in the log.

| Beat | 6.2 | The guarantee (and its fallback) |
| --- | --- | --- |
| finger | 0:05 | The ghost finger after 4 s with no touch or key (`hud.ghost_finger`: drawn on the pad, a fingertip dragging up and right over the stick's spot, "Połóż palec i wskaż, dokąd jechać / Put a finger down and point the way"; with `--no-touch` the keys' line); gone at the first touch, click or key |
| stand | 0:15 | The edge arrow "KEBAB n m" to the stand by Marszałkowska × Świętokrzyska (`jobs.FIRST_STAND`, the stand nearest it) and a toast, until an order starts (any stand's). The first-10 polish: a guided run starts at `First10.START` (main.gd `_guide_start`: the northbound carriageway level with the Museum of Modern Art, heading 339.8°), so the stand is ~350 m straight ahead; the map's spawn (facing south, the stand behind) stays for the bench and the other runs |
| order | 0:30 | That stand's next order is the guided one (`jobs.pin_first` / `first_pick`). The first-10 polish: a door on `FIRST_STREET` (Marszałkowska) nearest `FIRST_ROAD` (300 m) on by road from the stand's lane, 150-600 m, no turning round (any door in that reach if the street has none); on the demo map Marszałkowska 142, 226 m straight on (it was Aleje Jerozolimskie 33, 926 m past the Rotunda with a U-turn) |
| race | 1:30 | 6 s after the first delivery's card but not before 1:15 (`RACE_EARLIEST`: the short first order is done by ~0:45), or at 3:00 without one, Pani Halina rolls up behind (`rivals.call_first`: put ~45 m back on the player's road, she drives up and stops, or appears 12 m back after 12 s), flashes and says "Synku! Babcia mruga. Do Palmy, kto pierwszy?"; the prompt "PANI HALINA MRUGA · MRUGNIJ" waits 20 s (a nudge at 8 s) or until the player drives 90 m off. Flash back: the race to the Palm (Rondo de Gaulle'a; an ordinary finish if the Palm is over 1.6 km away) on her gentle day (below). Declined: she tries twice more, 60 s apart |
| trap | 3:00 | The police's scripted first contact (loop 3g-2: a patrol car parked 150 m ahead after the first race, the lizak, the caution); with no race by 4:30 the director arms it (`police.arm_first_contact`) |
| rescue | 4:00 | The first call is held (`missions.held`) until 3:45 and the race (or 5:00), then rings 12 s later (`ring_in`; again if a job reset the countdown). Call 1 is a street rescue (the car) |
| heli | ~5:00 | The HELI chip is hidden and H says "Helikopter? Najpierw jedno wezwanie ratunkowe." until the first rescue is done ("Pogotowie lotnicze pożycza ci starego śmigłowca: HELI"), a helicopter-only call is up, or 7:00 |
| tape | 6:00 | From 5:30, once the helicopter is out, the arrow "KASETA" to the mixtape on the University Library's roof (cassettes.gd, `CASSETTE_ID` c01_buw) and a toast "Na dachu BUW leży kaseta z muzyką. Leć po nią helikopterem."; taken from the helicopter (within 9 m, under 16 m over the roof) it opens the next PÓŁNOC FM track (the "new song"). Without a placed cassette the old stand-in: KASETA's boulevard then card (`t_bulwary_2018`), whose first play opens the track |
| powisle | 8:00 | "Odkryto: Powiśle" comes from districts.gd (the boulevards are in Powiśle, so the tape usually brings it); not by 7:30, the arrow "POWIŚLE" to the district's label and its line. Behind a long Podwózka ride it does not wait past its window: at 8:40 (`POWISLE_LATEST`) the line shows over the ride, the ride's pin keeps the edge arrow, and the guide's arrow follows when the ride is done (2026-11-10: a ride of 4.5 min taken at 5:31 had held it to 9:20). Over a race, a call, the police or a card it still waits |
| garage | 10:00 | Mirek's garage stays hidden (`garage.held`) until 9:30 and the first earnings, then its own toast and an arrow "MIREK" for 90 s |

- **The end of the guide**: at the garage (or 15:00) every hold is let go and `done` is saved.
- **The cassettes** (the first-10 polish; cassettes.gd, `data/cassettes.json`, DEMO 6.3 "10
  cassettes"): mixtapes lying on landmarks' roofs (missions.gd `roof_spot`: the rescue's flat-roof
  spot, else the highest flat spot at least 6 m up), one mesh for all (a pink cassette 4 m wide and
  a glowing diamond over it; one draw call, hidden once all are taken). A 5 Hz look takes one when
  the helicopter is within 9 m and under 16 m over it: the save's `[cassettes]`, +10 respect, the card
  "KASETA Z MUZYKĄ · MIXTAPE" and the next PÓŁNOC FM track. One so far (the BUW roof);
  `check_cassettes.gd` (quick, CI) tests the data, the pickup rule, a pickup and the save.
- **The first race, her gentle day** (the racer AI rebuild's step 2, 2026-11-10,
  docs/design/race-ai.md 6): Halina drives `ladder.gd` `FIRST_RACER` (0.65 of the road's racing
  speed, pull 7, brakes 4, corner grip 5 m/s²) at her own pace from the line to the Palm, with
  every rival's effort on the time gap (`rivals.effort_of`: 0.9 of her pace with a 10 s lead, 1.04
  when 5 s behind) and nothing of the player's speed in it; she still waits at the line until the
  player moves (12 s at most, PT-11). `check_first10`'s 1-D race of 800 m: 43.0 s alone and −3 to
  +9 % with any player; a player at 76 km/h wins by 3.7 s, one at 34 km/h loses by 38 s, a fast one
  who stops for a minute loses by 19 s. A loss makes her next race 5 % slower (15 % at most), and
  she stays on the gentle day in every race until she has been beaten once (`ladder.gentle`). The
  win is her rung beaten (ladder.gd), as any win. Before step 2 a rubber band (`rivals.first_speed`,
  first `first_band`) paced her off the player's own progress so that an ordinary drive won
  narrowly; that script was the crawl F reported on 2026-11-09.
- **The save**: `[intro]` (`wallet.intro`: beat id → the day; `done`; `end_seen`), no version bump
  (a v2 file without it loads as nothing seen; an older build keeps it as an unknown section);
  `--nosave` writes nothing.
- **The end card** (any save, guide or not): once "Trzy mosty" is won (`trzy_mosty` in `[ladder]`)
  and 10 jobs are done (`wallet.jobs_done`: every paid kind but `race` and `courier`, whose bonus
  rides on a kebab delivery; an old save counts from its totals by kind), shown once when nothing
  else is on: "DZIĘKI ZA GRĘ! / Thanks for playing!", "To był koniec dema. Trzy mosty twoje, kebaby
  dowiezione, a Palma… dalej sztuczna.", that the city stays open with everything unlocked, the
  credits line (OpenStreetMap (ODbL) and GUGiK, the game MIT) and "Kod:
  github.com/LubomirOlshansky/AroundWarsaw" (text, no link); one button, "JEDŹ DALEJ / Free roam",
  closes it. `end_seen` is saved when it shows.
- **Checks**: `tools/verify.sh --only=first10` (`game/tools/check_first10.gd`, CI too: the beats
  and windows, who gets the guide, three synthetic players through `decide`, a beat waiting for a
  job, a long ride across Powiśle's window, `judge`, the first race's 1-D races, the words), `--only=endcard`
  (`game/tools/check_end_card.gd`, CI too: fixture wallets, an old save, the card and its button,
  `[intro]`), and `--only=first10-run` (not in `--quick`, ~12 min): the replay, `--first10
  --autopilot` on the real city, passes on `first10: OK` (each beat's trigger inside its window).
- **Testing aids**: `--first10`, `--end-card`, `--first-race` (flags table).
- **Cost**: the director's look at 5 Hz (a dozen state reads, no scan; the bench's `first10` line);
  Halina's roll-up a distance a frame while it lasts; the finger is drawn on the pad (no node) and
  only while shown; the arrow is the HUD's own; the end card is the HUD's card. +0 draw calls while
  driving.

## Adreno 6xx shader budget

Found 2026-11-08 on the Nothing Phone 1 (Adreno 642L, Vulkan driver 1.1.128, EV031.35.01.12):
the driver failed to link 8 pipelines ("Failed to link shaders", VkResult -13), all of
building.gdshader and ground.gdshader, so the ground, roads and buildings did not draw. A probe app
(each shader on a box, one at a time, logcat between) bisected it: no single construct is at fault;
the driver has a ceiling on the fragment stage's control flow, Godot's own lighting code included.
Each `if`, loop, early `return`, short-circuit `&&` / `||` and function call costs (a call costs its
callee's whole body again: the driver inlines it); a plain ternary, all() / any(), step() / mix() and
straight-line maths cost nothing. One extra trivial call or two `if`s turned a passing ground shader
into a failing one. The fix: hash12, value_noise and srgb_to_linear are macros (common.gdshaderinc,
same arithmetic), the conditions in building and ground are all()/any(), and on Adreno below 700
building.gdshader runs as a lite copy with `specular_disabled` (`gpu_quirks.gd`). Measured ceilings
(our counting, `check_shader_budget.gd`): ground passed at 275, failed at 285; the lite building
passed at 508, failed at 518 (it stands at 498: little room); led_screen (unshaded) passes at 309.
The GL Compatibility renderer linked the original shaders on the same phone, but it is not used.
Room for later: landmarks in their own material (their codes cost ~300 of building's 498).

## Performance budgets

Set in loop 2b from the measurements above; loop 2c (the player's car and the traffic as nicer
models) and loop 2d (many more props and jokes: corner shops, e-scooters, delivery riders,
app taxis) must stay inside them and report the same numbers before and after.

**How to measure** (on the Mac, at the iPhone's 2868×1320, Metal; the counters are the ones
the phone's overlay shows and match it):
`godot --path game --rendering-driver metal --rendering-method mobile --resolution 2868x1320 --fixed-fps 60 -- --probe --nosave --controls=classic [view]`
(without `--rendering-method mobile` Godot picks Forward+ on the Mac, not the phone's Mobile renderer)
for the four views below (the `draw calls` and `main pass` lines), the bench
(`cd game && godot --path . --disable-vsync -- --bench --nosave`, also `--time=night` and
`--weather=rain --time=night`; Vulkan with `--rendering-driver vulkan --rendering-method mobile
--resolution 1920x1080` for the GPU), and on the iPhone the TEST · BENCH card (started from the
home screen).

| Per frame (High, traffic Normal, day) | Now (loop 2b) | Ceiling after 2c | Ceiling after 2d |
| --- | --- | --- | --- |
| Draw calls, all passes: spawn (no `[view]`) | 149 (3D 53, shadow 35, 2D 61) | 165 | 230 |
| Draw calls: default view over the river (`--at=1135.7,-198.1 --heading=72`) | 124 | 140 | 200 |
| Draw calls: zoomed out (the same + `--size=220`) | 190 | 215 | 300 |
| Draw calls: helicopter (`--at=1300,-420 --heading=60 --heli --size=150`) | 245 | 270 | 360 |
| Draw calls at any view, ever | | 500 | 500 |

**Railway spots** (2026-11-01, the railway lane): two `--probe` views on the line, each with a
train brought into view by `--train=X,Z` (the same X,Z as `--at`): Powiśle station and its
tunnel mouth (`--at=171,89 --train=171,89`) and Most Średnicowy from Wybrzeże Szczecińskie
(`--at=1148,-720 --train=1148,-720`). Cloud lavapipe at 1266×585, High, day: 158 and 119 draw
calls (main pass 58 / 50, shadow 65 / 34), 0.64 / 0.51 M triangles in all passes, trains' script
0.26 ms on the cloud CPU. The Mac's and the phone's numbers are still to take (under the 200
ceiling for a default view).
| Triangles, main pass (spawn / zoomed out) | 0.25 M / 0.36 M | 0.32 M / 0.50 M | 0.45 M / 0.70 M |
| Triangles, shadow pass (spawn / zoomed out) | 0.14 M / 0.27 M | 0.18 M / 0.35 M | 0.25 M / 0.45 M |
| Scripts, all systems (`scripts … ms` at the spawn, Mac) | 0.6–0.9 ms | 1.0 ms | 1.3 ms |
| Metal frame, bench (Mac, uncapped; since 2026-10-30 at `--resolution 1920x1080`, see below) | 1.5–1.9 ms | 2.2 ms | 2.6 ms |
| GPU, Vulkan bench (Mac, 1920×1080) | 0.80–0.87 ms | 1.0 ms | 1.2 ms |
| GPU, Vulkan zoomed out at 2868×1320 (`--gpu-profile`) | 1.65 ms | 1.9 ms | 2.2 ms |
| iPhone TEST · BENCH at High, 60 fps cap | 60 fps, 1 % low ≥ 56 | 60, 1 % low ≥ 55 | 60, 1 % low ≥ 55 |
| Loop 3c: streaming, main thread a frame (Mac, `check_streaming.gd` soak, p99 of the frames that load) | | ≤ 3 ms | ≤ 3 ms |
| Loop G0+: the same on the iPhone 11 (6-minute `--stream-soak`, max of any frame) | 1.2–1.5 ms (was 32–37) | ≤ 3 ms | ≤ 3 ms |
| Loop 3c: a frame that loads a sector | | ≤ 33 ms | ≤ 33 ms |
| Loop G0+: the same on the iPhone 11 | **over**: 19–22 frames of 25–65 ms in 6 minutes, one per load (the render server building the sector's GPU buffers; BACKLOG); loop 3d-2b: the collider was most of it on the Mac (built on the main thread), now a sector's pieces load one a frame (Mac: the slowest load frame 23.8 → 13.0 ms); the phone's to measure | ≤ 33 ms | ≤ 33 ms |
| Loop 3d-2b: video memory at the spawn (probe, prebuilt) | 300 MB (textures 38: the baked maps' 24 slots, 32 MB) | no growth | no growth |
| Loop G0+: the iPhone 11 at Auto ×1, 20 minutes each by day, night and rain at night (`--autopilot --governor=log`) | 60.0 fps every minute (59.9 at worst), 18–23 missed refreshes of ~72,000, 0 governor changes, calm | no struggle verdict | no struggle verdict |
| Loop G1: TEST · BENCH at Auto on the iPhone 11 (High, 896×414) and the Pro Max (Ultra, 1434×660), 60 fps cap | 60 fps, 1 % low 56.6 / 57.3, 0 missed refreshes | 60, 0 missed refreshes, 1 % low ≥ 55 | 60, 0 missed refreshes, 1 % low ≥ 55 |
| Loop G1b: the iPhone 11 at Auto, now High ×1 sharp (1792×828): BENCH minute, and a 15-minute day drive with the governor on (missed refreshes, governor changes) | BENCH 60 fps, 0 missed, 1 % low 54.4 / 58.7 (cool / warm); drive 60.0 every minute, 5 missed in 17.7 min, 0 governor changes | 60, 0 missed refreshes, 1 % low ≥ 55; the drive with no struggle verdict | 60, 0 missed refreshes, 1 % low ≥ 55; the drive with no struggle verdict (else the content costs the iPhone 11 its sharp default) |

**The bench's window (performance lane, 2026-10-30).** On macOS 27 a small window waits about
4 ms in the draw/present step whatever is drawn: at the default 1280×720 the bench's frame
reads 5.6–6.3 ms (main-thread "draw" 4.0–4.6 ms) both before and after loop 3d-1, while at
1920×1080 and up "draw" is 0.6–1.1 ms. It doesn't follow pixels (1920×1080 at ×1 has 4.5× the
pixels and is 5× faster) or objects (`--size=40` against `200`). So the Metal frame row is now
measured with `--resolution 1920x1080`: 2.4 ms before loop 3d-1, 2.5–2.7 ms after (at the
ceiling). What 3d-1 really added: +0.5–0.7 ms of main-thread process (1.14 → 1.64–1.81 ms; with
`--no-traffic` it is 0.60), main-pass triangles 0.17 → 0.20 M, static memory 173 → ~330 MB (the
prebuilt city 241 MB). Draw calls 73–139 at every view measured, well inside.

**Where the memory goes (performance lane, 2026-10-30).** Measured on the Mac at the bench's
start, the prebuilt path (the phone's): the whole-map index (`map/index.res`, the game's copy of
index.json: areas, paths, roads, trees, the lane graph) was 103 MB of the 225 MB static at "city
built"; the six first sectors 16 MB; the game's systems 45 MB (side jobs 17: rides 7.5, jobs and
eggs 4.8 each; walkers 5.6, the lane graph 3, the HUD 4.5, police 2.9). Video is 381–399 MB, of
which textures 99 MB: the AO, light and surface maps alone are about 96 MB (5318×3782 RG8 twice
and 2659×1891 RGBA8, no mipmaps), and buffers 129–147 MB grow with the sectors in view.
`scripts/index_pack.gd` now turns the index's coordinates (every feature's flat outline `p`,
the scanned trees, the parked cars, the lane graph) from JSON's one-Variant-per-number Arrays
into PackedFloat32Arrays, after the builder's set-up has read them and before the prebuilt index
is saved: static at "city built" 224.7 → 204.8 MB prebuilt (index 103 → 83 MB) and 294 → 267
MB on the runtime path; at the bench's end 252 → 233 and 357 → 329 MB; index.res 7.7 → 6.8 MB.
Readers that still declare `var flat: Array = r["p"]` get a converted copy, so nothing else
changed; the frame is unchanged. `game/tools/check_cost_cuts.gd` (verify step `cost`, under a
second) checks the packing on a synthetic index: the numbers kept within float32, other keys
left alone, packing twice a no-op.

**What traffic costs (performance lane, 2026-10-30).** Timed per step on the Mac at 1920×1080
(the bench's view, ~33 active cars, ~13 of them at junctions): nothing in traffic grows with the
map itself; it costs about 10 µs a car. On the prebuilt path (the phone's) a frame is ~0.37 ms
with the timers in, 0.31 ms without: the drive loop 64 % (placing a car 66 µs, the leader search,
the crossing and red-light checks and the speed model about 35–55 µs each), the junction checks
18 %, writing the MultiMesh 8 %, the signal lamps 5 %; the runtime path runs the same code
about 35 % slower (its larger heap). `on_screen` now projects with the orthographic camera's own
axes (identical answers on 35 k calls) and the junction pairs are rejected on packed positions:
the junction checks −14 % (66 → 57 µs), too little to show on the bench card. What is left is
per car; fewer cars in the view band is the lever, a design call. `check_cost_cuts.gd` also
holds `on_screen` to `Camera3D.unproject_position` (5 orthographic views, 10 000 points, a
point and the one `height` above it).

Loop 3g-1 (the police; police.md section 12 allowed ≤ +3 draw calls at any view, ≤ +8 k
triangles, ≤ 0.15 ms of script, ≤ +2 MB) spent, in a koguty 3 chase: +1 to +3 draw calls at the
four views and at night (the POLICE MultiMesh in the main and shadow passes, the halos at night;
the HUD's 2D pass no higher than before, the minimap now drawing its marks in one call), ≤ +3.2 k
triangles a pass, 0.07-0.08 ms of police script plus 0.04 ms of HUD, and +2 MB (+4 MB more for
Dialogue Manager's scripts); see Loop 3g-1: the police, part one.
Loop 2c spent none of it: +0 draw calls at every view, and the triangles at the default view
went down (the traffic pools draw only the cars in use); its numbers are in Loop 2c: car models.
What 2c may spend: ~15–25 draw calls (a few traffic kinds' MultiMeshes in the main and shadow
passes, the player's lamps), 70 k triangles at the default view (150 k zoomed out), 0.1 ms of
script. What 2d may spend: ~65–90 draw calls (about six new kinds of things, each one MultiMesh
per 512 m tile, in the main pass and, if over a metre tall, the shadow pass), 130 k triangles at
the default view, 0.3 ms of script. The phone has more GPU room at the default view than when
zoomed out or flying (there the main thread already waits ~11 ms of the 16.7 for the GPU), so
anything seen from far away (roof clutter, more trees, more cars when zoomed out) is the
expensive kind. (Loop G1: the ~11 ms is mostly waiting for the display, not the GPU: the same
"draw" reads 1–2 ms in another launch at the same view. The GPU's own time comes from a Metal
System Trace: the iPhone 11 at ×2 holds 60 at its lowest GPU clock, Loop G1 above.)

**Rules.**

1. Anything that repeats (five or more) is a MultiMesh: static things one per kind per 512 m tile
   (`map_builder.gd` `_tree_multimesh`, `INSTANCE_TILE`), moving things one per kind for the whole
   city, written with one `RenderingServer.multimesh_set_buffer` a frame and only near the view
   (as `pedestrians.gd` and `traffic.gd` do). Never one node per copy: the Mobile renderer has no
   automatic instancing, every node is a draw call in each pass it is in.
2. A model is one mesh with vertex colours for each material it needs; only parts that glow get
   their own material (the player's car: body + headlights + tail lights = 3 draw calls). Per
   instance colour goes in the MultiMesh's colour or custom data, never in a material per copy.
3. Triangles: the player's car ≤ 3,000, a traffic or rival car model ≤ 800 (about a hundred are
   on screen zoomed out), a person or rider ≤ 300, a prop ≤ 300, a kiosk or shop front ≤ 1,500.
4. Shadows: nothing under a metre tall or thinner than 0.3 m casts a sun shadow
   (`SHADOW_CASTING_SETTING_OFF`); casters over a metre that aren't buildings or trees join the
   `small_casters` group (`map_builder.gd` `SMALL_CASTERS`: no shadow on Medium). Things under a
   metre also join `fine_detail` (hidden in views wider than 170 m).
5. No new shaders unless the look can't be had otherwise; reuse `Models.material()` (actors and
   props, lamps and signs that glow at night) and the props' metal `StandardMaterial3D`. A new
   shader adds pipelines to compile (a first-sight hitch on the phone) and draw calls can't share it.
6. The HUD: no `clip_children`; no `_draw` that issues more than ~20 primitives a frame (build a
   mesh once and draw it with one call, like the minimap); the 2D pass stays under 80 draw calls.
7. No new full-screen passes at screen resolution; image effects go in the post pass at the
   pixel image's size.
8. Don't push `cam.far` out (it sizes the sun's shadow: `_camera_far`), the shadow map back up
   (Ultra's 4096 is loop G1's, measured on the Pro Max: 0 missed refreshes, +24 MB), or the
   tiles (`chunked_surface.gd` 256 m, instances 512 m) back down.
9. Report before and after: the `draw calls` / `main pass` lines at the four views above, the
   bench medians, and a TEST · BENCH card from the phone: since loop G1 from **both phones at
   Auto** (the iPhone 11 at High, the Pro Max at Ultra), with its missed refreshes.
10. Loop G1: the pixel image belongs to `tiers.gd` (the level's budget): don't make it finer for a
   look. A new extra that only the stronger phones can pay for is a level's (a `tiers.gd`
   QUALITY field, a uniform, not a shader define); one the governor may take away when frames
   are missed goes into `governor.gd`'s levels; a per-object one that can't be seen in a view
   over 150 m goes under the view rule (`main.gd` `_apply_extras`, WIDE_VIEW). Never the
   landmarks, the ghost, the river or the night lights.

## Map data

**Trees and fences off the water and the roads (F, 2026-11-08)**: `tools/object_audit.py` rules T1 (a
scanned tree's trunk in a water area, a sandbar excepted), T2 (on the drawn asphalt at grade, check_streets
S1's test, not on an island or a median) and L6 (a fence or hedge more than `WET_IN` 0.6 m inside a water
area; walls are left: quays, breakwaters, fountain rims); `tools/object_fixes.py` VERSION 2 removes T1
(211), moves T2 up to `TREE_SHIFT` 3 m to a spot `TREE_CLEAR` 0.8 m off the asphalt (1,033) or removes it
(114; a moved tree beside a deck gets its crown trimmed by `bake_structures.trim_crowns`, check_roads C9), and trims L6's wet parts (6 fences, three of them by Most Łazienkowski at WTS DESKA). trees3d
271,896 → 269,946, crowns 45,316 → 44,991 (`check_map_data.py` EXPECTED). `verify.sh objects` holds T1, T2
and L6 at 0. ao.bin, street_details.json and park_details.json re-baked.
TR-1 (2026-11-09): object_audit rule T3 (a scanned tree inside a building outline 2.5 m or higher) with
`object_fixes.py` VERSION 3: moved like T2 to a free spot within 3 m (52) else removed (129); trees3d
269,946 → 269,172, crowns 44,991 → 44,862 (`check_map_data.py` EXPECTED). `verify.sh objects` holds T3 at 0.

**Dworzec Centralny's car park ramp (F, 2026-11-08)**: `tools/centralny_ramp.py` (bake_osm right after
bake_structures, or as a CLI on a baked map; idempotent, `--check` is verify step `centralnyramp`) makes the
service tunnel under Al. Jana Pawła II north of Chmielna a drive: tunnel group 10 (one 10.8 m tube on the
middle line of OSM's 30611690/143461289, floor 8.5 m = the entry ramp's foot, and a 22 × 22 m turning hall
under Złote Tarasy's forecourt, its west shoulders splayed), one portal and frame, the way out's lower 38 m
(143461245, which R9's `garage_ramps` cut) back as a road with a ground profile 8.5 → 10.6 m, its garage door
gone; the site's walls (box x −1690..−1530, z 395..500) placed again by `place_walls`/`place_tunnels`, 7 m of
fence across the mouth cut, 2 scanned trees on the way out taken out: trees3d 271,752 → 271,740, crowns
45,292 → 45,290. Signs and bollards: `game/scripts/centralny_ramp.gd` (runtime, both city paths, one mesh).
check_stuck_spots has 5 lines through it.

**Bike markings (idea #9, 2026-11-02)**: `tools/bike_marks.py` (bake_osm after car_free, or as a
CLI on a baked map) adds 660 `symbols` of kind `bike` marked `"on": "path"` on the cycle paths;
`map_builder.gd` edges each `cyclecross` with P-11 squares (`CROSS_SQ`, `CROSS_EDGE`). No counted
key changes. `tools/compare_cycleways.py` (reads only) measures how much of OSM's cycle network
the map draws; it needs the raw export (`data/work/demo/osm_demo.json`).
`tools/bike_network.py --osm <export>` (bake_osm after bike_marks) adds `bike` symbols marked
`contra` (an arrow ahead, against the one-way), `busway` and `sharrow` (two chevrons ahead), drawn by
`_build_symbols`; without the export it changes nothing, so the cloud keeps what the Mac's run wrote.

**Map review C (2026-11-02)**: one-lane one-way streets take `DEFAULT_WIDTH` (`bake_roads.py`
`road_width`, `mark_split_legs`), two-way `lanes=2` ones at least 7 m (`TWO_LANE_STREET`); pois 4,572 (`tools/check_map_data.py` EXPECTED; the Centralny Leżak
has its spot again). BACKLOG "From map review C".

**Map north (2026-10-31)**: the box grew north on its west side by `bake_osm.py` `BBOX_NORTH`
(Rondo Radosława, Arkadia, Forest; 1.04 km², 21.2 km² and 112 sectors in all): the map is the
bounding rectangle without its north-east corner (`outside`, `tools/map_shape.py`); the extension's
1 m NMT is `data/raw/demo/gugik/nmt1_north/` (`tools/fetch_demo.py nmt1north`). See "Map north"
for the counts; the chain below is unchanged.

**Loop 3d-1: the demo box.** The map is the box of docs/DEMO.md 2.1: south 52.2183, west
20.9780, north 52.2525, east 21.0560 (map metres x −3,136 to +2,182, z −2,046 to +1,736;
5,318 × 3,782 m = 20.1 km², 12 × 8 = 96 sectors and a sliver row). `bake_osm.py` `BBOX` is the box and `ORIGIN`
(52.2340 N 21.0240 E) the origin, no longer the box's centre, so every coordinate written down
before (allowlists, `GUGIK_NOT_TREES`, `EXTRA_KEBAB`, landmark search boxes, police traps, test
spots, this README) still means the same place. Everything comes from the demo fetch already on
disk (`data/raw/demo/MANIFEST.md`; nothing downloaded since) and `data/raw` is only read:
`tools/bake_all.sh` runs the whole chain (~10 min), in this order:

1. `python3 tools/prepare_demo.py` (Pillow, for the photo) → `data/work/demo/` (gitignored):
   the Overpass export cut to the box (`osm_demo.json`: nodes within 0.003° of it, the ways and
   multipolygons that reach it with all their nodes, no route relations: 76 MB of 187), the
   aerial photo's four tiles joined and cut (`ortho.bmp`, 6,112 × 4,346 px), the terrain
   (`terrain_10m.json`: the 10 m lattice, each node from the 1 m NMT of `data/raw/demo/gugik/nmt1_box`,
   see "Loop 3d-1"), links to the 9 LoD2 and 30 tree sheets that meet the box.
2. `python3 -I tools/bake_terrain.py` → `game/map/terrain.json` (its own step now: bake_osm
   reads it for the decks, and bake_gugik reads centrum.json, a circle once the box grew).
3. `python3 -I tools/bake_trees_gugik.py data/work/demo/trees data/work/demo/trees_area.json` (~5 min).
4. `W=data/work/demo/osm_demo.json && python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W`.
5. `python3 -I tools/bake_gugik.py data/work/demo game/map` → `lod2.bin`, `lod2.json`.
6. Step 4 again: its structures read `lod2.*` (the outlines bake_gugik keeps LoD2 by don't change).
7. `bake_ao.py`, `bake_lights.py`, `bake_water.py` (below), then `tools/setup_map.sh` (the split
   and the prebuilt sectors).

The steps below are the chain as it was for the first box; their order and what each writes
still hold, with the paths above.

0. Trees (optional, before step 1): the GUGiK 3D tree models, LoD1 2023, CC BY 4.0
   (`opendata.geoportal.gov.pl/InneDane/Drzewa3D/LOD1/2023/14/1465.zip`, 8.6 GB, no resume;
   stream it through `tar` keeping only the map's sheets into `data/raw/gugik/trees/1465/`), then
   `python3 -I tools/bake_trees_gugik.py data/raw/gugik/trees/1465 data/raw/gugik/trees_area.json`.
   Each tree is a trunk and a crown object; the crown gives the position, height, crown radius
   and crown base. `bake_osm.py` picks the file up by itself: inside every sheet that parsed to
   the end, the laser-scanned trees (`trees3d` in `centrum.json`) replace OSM trees and the park
   fillers; elsewhere the OSM trees stay.
   The scan is from 2023, older than the newest streets: `tools/planted_trees.py` (called by
   `bake_osm.py` after `snap_props`, idempotent, also a command line tool on a baked map) adds
   the young trees planted since into their mapped beds, per place in its `PLACES` (Krajobraz
   places, 2026-11-02: ul. Bracka's woonerf, +22 to its 11 scanned young trees, 33 in all;
   `trees3d` 268,992 → 269,124 values, `trees3d_crown` 44,832 → 44,854).
   `tools/plaza_gardens.py` (same hook, right after it; K5, 2026-11-02, spec
   docs/design/rondo-plazas.md) plants the open ground round Skyliner, Generation Park and Mennica
   Legacy Tower: +121 young trees (`trees3d` → 269,850 values, `trees3d_crown` → 44,975), 51
   "park" beds in `areas`, 11 benches; `plaza_gardens` in the map lists the places done, so it
   is idempotent.
   K3 (2026-11-02, `planted_trees.py` PLACE `varso`): +6 young trees in Chmielna's bare beds by
   Varso Place (`trees3d` → 269,886, `trees3d_crown` → 44,981).
   K2 (2026-11-02, `planted_trees.py` PLACE `chmielna`): one young tree per mapped tree pit on
   ul. Chmielna, +65 to the 20 scanned in its band, 85 in all (`trees3d` → 270,276,
   `trees3d_crown` → 45,046), and its two pedestrian areas re-tagged `granite`. One K5 plaza
   tree by Skyliner stood through a lying scooter (check_pois Q4) and was taken out;
   `plaza_gardens.py` keeps POI_GAP (1.6 m) from the map's POIs (→ 270,270 / 45,045).
   K9 (2026-11-02, `planted_trees.py` PLACE `stadion`, kind `grounds`: lime and plane rows on the
   Stadion Narodowy's entrance plazas, pollarded willow groups on its lawns, marked in
   `planted_places`): +80 trees (→ 270,966 / 45,161 on top of the Złota limes).
1. OpenStreetMap (Overpass) → `data/raw/osm_wide.json` (the whole map: roads, trees, lamps,
   traffic lights, car parks, street furniture), then
   `W=data/raw/osm_wide.json && python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W`.
   The public Overpass server is often busy (HTTP 502/504): retry with a back-off.
   Loop 3a: the bake also writes `fills` (approaches and pits: the ground corrected under a
   road), `tunnels` and `garages`, and the graph's `dk` / `tn`; check the result with
   `python3 -I tools/check_roads.py` (C1-C10, see Loop 3a).
   Loop 3b: it ends with `tools/bake_structures.py` (`decks.piers`, `walls`, `towers`, `cut` /
   `cutd` / `pil` on buildings, `lod2_cuts`, `lod2_open`, `aprons`, `tunnels.frames`,
   `garage_doors`, the graph edges' `po`; it reads `game/map/lod2.*`, so bake GUGiK first), and
   when `data/raw/demo/gugik/nmpt05` and `nmt1` are there (the demo fetch's 0.5 m surface model
   and 1 m terrain, float32 GeoTIFF; `data/raw/demo/MANIFEST.md`) the deck solver follows the
   measured decks (R2). Then `godot --headless --path game --script res://tools/check_drive.gd`.
   Laser-scan records that are not trees are left out (`GUGIK_NOT_TREES`: the Palm, written
   as `palm`). After a re-bake run steps 3-5 again.
   Loop 3e: the open ways by the tunnels' portals and the cuttings take their level from the 1 m
   NMT of the whole box (`data/raw/demo/gugik/nmt1_box`, `bake_roads._ground_profiles`, "set"
   fills `s`); without it the grid alone (see Loop 3e).
   Loop 3b-2: `tools/bake_banks.py` (after the shore runs) marks natural banks on `shore` (`n`)
   and writes `sand` and `sandbars` (`g`: gravel); `crown_scales` writes `trees3d_crown` (one
   crown scale per scanned tree, 12,554 values on the first box, 38,570 since loop 3d-1, checked by `check_map_data.py`);
   `level_surfaces` puts a bridge's mapped pavements and tram bed on its deck (`dk` on
   `surfaces`). See Loop 3b-2.
   For the side jobs and easter eggs the same bake writes more `pois`: `kebab` (the mapped
   kebab places, `amenity=fast_food` with cuisine or name kebab, by position only, never their
   names, plus the extra corners in `EXTRA_KEBAB`; each with the road point a car pulls up at),
   `address` (973 homes and offices with `addr:street` + `addr:housenumber`, the road point at
   the door, `o` = office, `d` = `powisle` or `praga` across the river), `station` (Warszawa
   Centralna, shown as "Dworzec Centralny"), `patelnia`, `defilad` and `syrenka` (the boulevard
   spot facing the water, as none is mapped).
   Content POIs (2026-10-31): at its end the bake runs `tools/bake_street_pois.py` on the finished
   data and appends, after every older poi, `convenience`, `subway_entrance`, `bicycle_rental`, 11
   more `address` (`v`), `scooter_zone` and `scooter` (see "Content POIs"; `tools/check_pois.py`).
2. GUGiK: the Warsaw LoD2 package (`integracja.gugik.gov.pl/Budynki3D/pobierz.php?plik=powiaty/1465_gml.zip`),
   the four sheets that cover the map unpacked into `data/raw/gugik/sheets/`
   (`python3 -I tools/find_sheets.py data/raw/gugik/1465_gml.zip tools` lists them), then
   `python3 -I tools/fetch_gugik.py data/raw/gugik` (aerial photo + 10 m elevation grid) and
   `python3 -I tools/bake_gugik.py data/raw/gugik game/map` → `lod2.bin`, `lod2.json`, `terrain.json`.
3. `python3 -I tools/bake_ao.py game/map` → `ao.bin`, the soft ground shadows next to walls,
   under parked cars and trees. Run it after both bakes above (it reads their output). Loop 1:
   two bytes per metre, the buildings' shade and the small things' (the occlusion ghost lifts
   only the first); the map builder still loads an old one-byte map.
4. `python3 -I tools/bake_lights.py game/map` → `lights.bin`, the street-lamp light map for
   the night (1 m per pixel, sodium and LED, cut off by buildings) and the lamps it adds on
   bridges. Run it after the bakes above. Like `ao.bin` it ends up in the prebuilt city (loop
   3d-2b: as each sector scene's slice, `map_builder.gd` `map_slices`), so the export leaves the
   raw file out. Its grid must be `ao.bin`'s (the two share a slot grid; the builder says so if not).

5. `python3 -I tools/bake_water.py game/map` → `water.bin`, the surface map (v0.9: shore distance,
   the river's flow, what reflects, bridge-deck heights); a second or two. Only needs
   `centrum.json`; like `lights.bin` it ends up in the prebuilt city (the sectors' slices and the
   index's water test), and the export leaves it out.

6. Loop 3c: `python3 -I tools/bake_sectors.py` → `index.json` and `sectors/<i>_<j>.json`, the map
   in 512 m sectors (about a second; see "Sectors and streaming"). After any of the steps above.
   Loop 3d-1: it also writes `sectors/split.stamp` (the SHA-256 of centrum.json, lod2.* and itself).
7. Loop 3c: the prebuilt city, **with a renderer** (`--headless` drops MultiMesh and texture
   data): `godot --path game --resolution 320x180 --script res://tools/bake_city.gd` →
   `sectors/s_<i>_<j>.scn` (32), `proxies.scn`, `index.res` and `shared/*.res` (~16 s; it checks
   the landmark sites found from the index against the whole map's). Loop 3d-2b: each sector's own
   meshes, MultiMeshes and collider patches as files of their own, `sectors/s_<i>_<j>/<n>.res`
   (1,762 on the demo map, ~20 a sector), and its map slices inside its scene. Also needed after any
   change to `map_builder.gd`, `chunked_surface.gd`, `landmarks.gd`, `neon_signs.gd`,
   `sector_proxies.gd`; `tools/export_ios.sh` runs 6 and 7. `city.scn` is gone (loop 3c).
   Loop 3d-1: it ends by writing `sectors/city.stamp` (the split's digest and the SHA-256 of the
   maps and scripts it builds from: `bake_city.gd` / `check_map_data.py` `CITY_INPUTS`).

**What is committed (loop 3d-1, the user's decisions 2026-10-29).** The bake chain's output that
carries OpenStreetMap is committed: `centrum.json`, `ao.bin`, `lights.bin`, `water.bin` (the
derived database under ODbL; the three maps mix OSM with LoD2, and a clone without raw data
needs them). What comes from GUGiK's data alone is derived like the sectors: `lod2.bin`,
`lod2.json` (the LoD2 buildings) and `terrain.json` (the NMT), gitignored; `tools/setup_map.sh
--full` (or their absence) rebuilds them from `data/raw` (`prepare_demo.py`, `bake_terrain.py`,
`bake_gugik.py`), and on a clone without the raw data it says what to fetch
(`tools/fetch_demo.py` for the demo fetch, the Warsaw LoD2 package, `data/raw/demo/MANIFEST.md`). Steps 6 and 7's files (`index.json`, `index.res`,
`proxies.scn`, `sectors/`, `shared/`) are gitignored: re-bakes grew the pack 194 → 340 MB in a
day. **A fresh clone runs `tools/setup_map.sh` once** (steps 6 and 7, then the check; ~20 s, a
small window opens; it imports the project first if Godot never opened it); `--if-needed` does
nothing when they are there and match their inputs. `tools/verify.sh` runs it when they are
missing, `tools/export_ios.sh` rebuilds them every time, and the game says "run
tools/setup_map.sh" instead of starting without a city. `check_map_data.py` reports missing ones
as a WARN ("missing: run tools/setup_map.sh") and stale ones by content: a stamp whose hashes
don't match today's inputs (a checkout scrambles file times, so they aren't used).

Audio: `python3 -I tools/make_sfx.py game/audio/sfx` (v0.9: every sound effect
and bed, with the numbers; loops imported Forward, loop end = the full length, QOA;
`res://tools/check_sfx.gd` checks them); `python3 -I tools/make_music.py data/raw/music/<station_id> shots`
(the three original radio loops, as WAV; they are not in the game as WAV any more: put them
through `tools/add_music.py`, "Adding music"; `godot --headless --path game --script
res://tools/check_radio.gd` checks radio.json, the Ogg files, the playlists and each looping
station's loop point) and `python3 -I tools/make_ui_sounds.py game/audio/ui`.

**The ground mesh** (loop 3d-2a, `map_builder.gd` `_build_ground`): the 10 m grid's two triangles
per cell, built after the flat layers and leaving out what they cover whole (the water, parks,
plazas, wide roads: 92,612 halves); the cells an apron reaches in 1 m sub-cells only where the apron
lowers the ground. The heights (`_grid_height`, `_drawn_height`, check_roads `Map.drawn`) are those of
the grid as before; `game/tools/check_ground.gd` checks the mesh against them, and that nothing is
left open ("Loop 3d-2a").

LoD2 is from 2018, so newer towers (Varso and others) come from OpenStreetMap; LoD2 buildings
no longer on the map are dropped. The terrain is bare earth, so bridges and viaducts get decks
solved from what they cross (see Real roads).

## The website (aroundwarsaw.app, 2026-10-29)

`site/` is the game's landing page (English at `/`, Polish at `/pl/`) and the privacy policy
and support pages the stores link to (`https://aroundwarsaw.app/privacy/`, `/support/`). All four
pages are built by `python3 -I tools/site_build.py` from `site/src/` (template and copy),
`docs/privacy.md` and `docs/support.md`. The store listings: `docs/store/`.
Plain HTML and CSS, self-hosted fonts, one small script for the beta and feedback form
(Formspree), no cookies, no analytics. It is a Cloudflare Worker with static assets only
(`site/wrangler.jsonc`, custom domains `aroundwarsaw.app` and `www.aroundwarsaw.app`);
`.github/workflows/site.yml` deploys it on a push to `main` once the repository has the
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets. Beta sign-ups and feedback arrive by
email through the form. Deploying by hand, the secrets and where the
beta links go: `site/README.md`.

## The design wiki (wiki.aroundwarsaw.app, 2026-10-30)

A private website for designing the game without reading code: every activity (with its lines
and tuning), the 53 landmarks with their cards, looks and pictures, the 72 notebook places, the
eggs, Fotka spots and KASETA cards, the radio, every line of dialogue, the parody names, each
script's description and constants, the settings, flags and budgets, the open questions, the
design docs, and a Progress page (the road to the 1.0 demo, the lanes, the backlog by area, the
log). `python3 -I tools/wiki_build.py` writes it to `build/wiki/` from the repo alone, so it
never needs hand-editing; each item links to its file and line on GitHub. Pictures:
`wiki/media.json` and `wiki/img/`. It is its own Worker (`wiki/wrangler.jsonc`,
`aroundwarsaw-wiki`, the subdomain `wiki.aroundwarsaw.app`) open to anyone with the link (`wiki/worker.js`; it asks for a
password only if the secret `WIKI_PASSWORD` is set, the user's call 2026-10-31), `noindex` everywhere and unlinked from the landing: it is spoilers
and plans. `.github/workflows/wiki.yml` checks the build on every change to the data, scripts or
docs and deploys only when run by hand. Details: `wiki/README.md`.

## Layout

**One-command checks.** `tools/verify.sh` runs the verification set and prints one
PASS/WARN/FAIL table: the map-data invariants (`tools/check_map_data.py`), the road check
(`tools/check_roads.py`, loop 3a), the check scripts
(steering, settings, the HUD at phone size, landmarks, sfx, radio, the water on both city paths) and eight headless game runs, each with

(the drape check (loop 3b-2), the drive check on both city paths (loop 3b), steering, settings, landmarks, sfx, radio,
the water on both city paths) and eight headless game runs, each with
`--nosave` (`--quick` for a short set, `--ios` adds the export and the unsigned Xcode build,
`--only=` picks steps). `tools/shots.sh` renders standard screenshots at a phone's size
(`--list` names them). `tools/device_run.sh` builds, installs and launches the game on a
connected iPhone and copies its log back (loop G0+: each run's own copy,
`build/device/<label>/<label>_<date-time>.log`, with the bench's and the streaming soak's result
files beside it; it exits 3 when the `--done` line never came). A guard hook (`tools/hooks/guard_godot.py`, on in
`.claude/settings.json`) stops Claude Code from running the game without `--nosave` or a quit
flag. How the work is run: `docs/WORKFLOW.md`, `CLAUDE.md`.

- `tools/bake_osm.py`: turns the Overpass export in `data/raw/` into `game/map/centrum.json`
  (the command is in "Map data", step 1).
  It reads `game/map/terrain.json` (for the bridge decks) and hands the road surface to
  `tools/bake_roads.py`: `carriage` (road and hatched areas), `kerbs`, `medians`, `guards`,
  `symbols` (turn arrows, BUS, bikes), `decks`, `shore` (the water's edge), the extra
  `markings` kinds and the roads' `w`/`c`/`hide`/`dk`.
- `game/scripts/map_builder.gd`: terrain with diorama edges, draped roads/markings/crossings/rails,
  carriageway areas, kerbs, raised islands and medians, turn arrows / BUS / bikes (pixel shapes),
  bridge decks (`ground_height`, `drive_height`, `deck_height`) with slabs, parapets and piers,
  guard rails, LoD2 + OSM buildings, trees, lamps, traffic lights, parked cars, collision (walls,
  guard rails, bridge parapets, the water's edge and its stone), the water test (`shore_distance`,
  `in_water`, `nearest_dry`, loop 10a). Flat layers are laid on the terrain (or their
  deck) in pieces no longer than the 10 m terrain grid. Everything is split
  into 128 m tiles (`chunked_surface.gd`) so off-screen tiles are culled.
- Loop 3c: `tools/bake_sectors.py` (the map split into 512 m sectors: `index.json`,
  `sectors/<i>_<j>.json`), `map_builder.gd` `setup_streamed` / `build_sector`,
  `game/scripts/sector_streamer.gd` (loads the sectors round the camera, both city paths),
  `game/scripts/sector_proxies.gd` (one low-detail mesh per sector), `game/tools/bake_city.gd`
  (the prebuilt sectors, proxies, index and shared resources), `game/tools/check_streaming.gd`
  (step `streaming`); see "Sectors and streaming".
- Map north: `tools/map_shape.py` (the map's shape: the bounds without the corner left `outside`),
  `tools/check_outline.py` (step `outline`: nothing off the map, every sector on it),
  `tools/check_lod2.py` (step `lod2`: LoD2 and OSM blocks never both, never neither); see "Map north".
- Content POIs: `tools/bake_street_pois.py` (run by `bake_osm.py`: corner shops, metro entrances,
  bike docks, the places' missing addresses, the Leżaks and their zones), `tools/check_pois.py`
  (step `pois`), `tools/overlay_pois.py` (them over the aerial photo); see "Content POIs".
- Loop 3a: `tools/check_roads.py` (+ `check_roads_allow.json`; the road rules C1-C10),
  `tools/road_spots.txt` (the road render spots for `tools/shots.sh --set=roads`),
  `game/scripts/debug_roads.gd` (`--debug-roads`), `game/addons/debug_draw/` (the Debug Draw
  add-on, HardPixel, MIT).
- `game/scripts/skids.gd`: tyre marks. The minimap lives in `hud.gd`. `splash.gd` (loop 10a): the
  car's splash in the water.
- `game/scripts/car.gd`: arcade car. `heli.gd`: helicopter (flight, rotor, blob shadow; it reads
  `map_builder.gd`'s 4 m grid of roof heights, so buildings are solid without physics queries).
  `missions.gd`: rescue calls, beacons (`beacon.gd`), timer and score. `hud.gd`: touch controls,
  mission card and status, target arrow. `main.gd`: camera, styles, vehicle switch, setup.
- `tools/bake_osm.py` also writes `pois` to `centrum.json`: hospitals (with the nearest road
  point), Vistula beaches, dry sandbars (`sandbar` if water surrounds it, else `shore`), named
  parks and squares, the stadium; and `graph`: the lane graph (nodes, directed edges with lanes,
  speed, junction cut-backs and stop lines, the largest strongly connected part, signal
  controllers and which controller each signal pole shows).
- The living city, all built at startup from the map data (about 0.1 s, both city paths):
  `lane_graph.gd` (lanes, junction curves, light timing, Dijkstra), `traffic.gd` (AI cars in
  MultiMeshes, spawning band, car following, lights, junction give-way, collision bodies near the
  player, signal lamps), `trams.gd`, `pedestrians.gd`, `rivals.gd` (rivals, races, their lines),
  `bubbles.gd` (speech bubbles and name tags in the HUD layer), `models.gd` (vehicles and people;
  loop 2c: the shape kit, the traffic families and their table `TRAFFIC`, the player's,
  rivals', police, parked and tram models) and `shaders/actor.gdshader` (per-instance paint,
  walking legs; loop 2c: the family shapes and the BLINK beat).
- `game/shaders/`: `common.gdshaderinc` (sRGB, noise, cloud shadows); `night.gdshaderinc` (the
  time-of-day globals `lights_on`, `daylight`, `sky_colour` from project.godot's shader globals,
  and the lamp light map; the look loop: the banded, capped lamp pools on the ground); `building` (per-building window rhythm from UV2, shop fronts, cornices,
  curtain walls, roof grain, see-through hole around the car, lit windows, neon tubes, floodlit
  Palace); `ground` (layer id in UV.y: paving slabs, asphalt, grass, worn paint, baked AO; depth
  bias in UV.x; lamp pools); `foliage` (sway, see-through, lamp light; the look loop: lumpy
  crowns, dapple, rust/olive autumn, the parked cars' red repainted); `actor` (vehicles and
  people; lamps and lit windows by UV.x; the player's car as the hero part); `fixture` (lamp posts with glowing heads); `neon`
  (signs); `glow` (additive light on the road, halos, the searchlight; drawn after the post
  pass); `post` (outlines, posterize, grading, vignette, split-tone, sky); `vhs`, `title`,
  `chrome` (the overlay and the title screen).
- `time_of_day.gd` (the three looks, the blend and Live; the post pass's saturation share), `radio.gd`, `title.gd`, `neon_signs.gd`.
- Loop 2e: `screen_points.gd` (the screen in points and its safe area; a known iPhone's on a
  computer), the HUD in points with its layout of passing panels (`hud.gd` `_layout`,
  `panel_rects`), the tabbed `settings_panel.gd`, bubbles clear of the HUD (`bubbles.gd`),
  rescue calls that come in during play (`missions.gd`), `tools/check_hud.gd`.

- `time_of_day.gd` (the three looks, the blend and Live), `radio.gd`, `title.gd`, `neon_signs.gd`.
- Loop 3g-1: `police.gd` (perception, strikes, the chase's state machine, the traps and the lizak,
  the pull-over, the HUD and halos, the test drivers), `police/police_unit.gd` (a unit and its
  beehave tree), `police/police_tree.gd`, `police/bt/` (the trees' leaves), `police/police_talk.gd`
  (the conversation's `talk`), `police/police_balloon.gd` (the card); `data/police_traps.json`,
  `dialogue/police.dialogue`; `tools/check_police.gd`; add-ons `addons/beehave/`,
  `addons/dialogue_manager/`.
- Camera loop: `follow_camera.gd` (the follow camera's laws: the turn, the look-ahead, the dead
  zone, the speed zoom; shared with `tools/check_steering.gd`), `camera_shots.gd` (the fly-in and
  the look at a target on Phantom Camera), `game/addons/phantom_camera/` (Phantom Camera 0.11.0.3,
  MIT, its autoload `PhantomCameraManager` in `project.godot`; the editor plugin is not switched
  on), the `--cam-log` / `--cam-test` / `--cinematic` aids and the camera's frame in `main.gd`
  (`_update_camera`, `_snap_to_pixels`, `_new_target`).
- Loop 2b: `bench.gd` (what a frame costs: frame times, the main thread's phases from the
  engine's frame signals, draw calls / objects / triangles by pass, the scripts by system,
  memory; for `--bench`, `--probe`, the BENCH button and the overlay), the minimap as one mesh
  in `hud.gd`, the camera's far plane (`_camera_far`), the fine-detail and small-caster groups,
  the frame-rate cap and the BENCH run in `main.gd`, `chunked_surface.gd`'s `add_arrays`.
- Loop 2a: `drive_controls.gd` (the control schemes: stick, keys and pedals to the car's
  controls and the finger's hold; the follow camera itself moved to `follow_camera.gd` in the
  camera loop; shared with the replay test),
  `settings.gd` (`user://settings.cfg`, the traffic levels), `settings_panel.gd` (the panel in
  the HUD), the car's turning and wall model in `car.gd`, the gear and Classic's pedals in
  `hud.gd`, `tools/check_steering.gd` (+ `tools/steering_legacy_car.gd`, the car before loop
  2a, for its `--legacy` numbers) and `tools/check_settings.gd`.
- Loop 1: `shaders/ghost.gdshaderinc` (the occlusion ghost's region, shared by the building,
  ground and post shaders), floating parts in `map_builder.gd` (`_part_bottoms`), the clock
  hands in `building.gdshader`, the column posters in `eggs.gd`, `BLINK` lamps in
  `models.gd` / `actor.gdshader`.
- v0.9: `sfx.gd` (buses, engine and tyres, rotor, beds, one-shots, positional voices),
  `weather.gd` (Clear / Rain, `wetness` and `rain` shader globals), `tools/make_sfx.py`,
  `tools/bake_water.py`, `game/tools/check_sfx.gd`, `game/tools/check_sun.gd`; the river, wet
  ground and lamp columns in `ground.gdshader`, the mirror reflections and rain in
  `post.gdshader`, the performance overlay in `hud.gd` and `main.gd`.
- v0.8: `landmarks.gd` (the hand-built landmarks, their zones, info cards and picking grid;
  map_builder.gd calls it), `tools/check_landmarks.gd`, `tools/overlay_landmarks.py`.
- v0.65: `wallet.gd` (wallet and save), `dialogue.gd` (lines from `data/dialogue.json`, drivers'
  shouts, the radio host), `jobs.gd` (kebab stands, orders, heat, the słoiki run, jars),
  `eggs.gd` (the Palm, pigeons, roadworks, Patelnia, the Mermaid, joke billboards), `props.gd`
  (their box-built models, drawn with the actors' material so lamps and signs glow at night),
  `pixel_font.gd` (a 5×7 font with Polish letters for signs and posters), `shaders/poster.gdshader`.
  All built at runtime on both city paths (nothing new in `city.scn`). The export includes
  `data/*.json`.
  Debug: `--debug-ao` shows the AO map, `--no-ao` turns it off.

Screenshots for review: `godot --path game -- --style=0 --size=380 --at=-110,-85 --shots=40 --out=$PWD/shots`.

Command-line options (after `--`):

| Option | Effect |
| --- | --- |
| `--palace-lights=ID` | the Palace of Culture's night lighting forced to one row of `data/palace_lights.json` (`independence`, `parade`, `christmas`...; `gold` the nightly gold), whatever the date (2026-11-07) |
| `--demo` | the car drives by itself; with `--heli` the helicopter flies a slow circle |
| `--shots=60,240` / `--out=DIR` | save screenshots at those frames (counted from when the city is built), then quit (sweep 2: the sounds are stopped 0.15 s before, so a windowed run no longer ends with leaked audio streams). The window never takes the keyboard focus, as with `--no-input`, and a run that ends before a shot prints `shots: missing [frames]` with the game and engine frame and the pause state (2026-10-30) |
| `--spots=NAME:X,Z[,HEADING];...` | with `--shots`: shoots every spot in one run (the city is built once; the car and camera jump to the next spot after each spot's last shot frame, the frames shift by the frames spent), files `NAME_FFFF.png`. `--out` is made when missing, and a PNG that can't be written ends the run with exit 1 (it used to exit 0 with no file) (Operation Unslop, 2026-11-05) |
| `--style=N` / `--lines=N` | visual style 0–3 (loop 2e: wins over the saved style for this run) / override the pixel image's line count |
| `--size=M` / `--yaw=deg` / `--fixed` | view height in metres (default 80) / camera turn / fixed camera (in Point: the Fixed camera scheme) |
| `--stops=FILE` | with `--shots=` far ahead: the camera stops at each `[x, z, yaw, pitch, size, name]` of the JSON list and saves `<name>.png` in `--out`, then quits; one run shoots a whole street |
| `--at=x,z` | start at map coordinates (metres, +x east, +z south), on top of a bridge deck if there is one |
| `--heading=deg` | the car's heading at the start (0 north, 90 east), for testing: with `--demo` it drives off that way |
| `--nohud` | hide the controls |
| `--left-handed` | accessibility (2026-11-01): the left-handed layout for this run (the pedals, the horn and the helicopter's pads bottom left, the stick's side and Classic's strip on the right, the credit line bottom right), as Settings → DOSTĘP → "Dla leworęcznych" sets it; for shots (`tools/check_hud.gd` checks it) |
| `--color-safe` | accessibility (2026-11-03): colour-safe markers for this run, as Settings → DOSTĘP sets them: the HUD's green and red tinted, the drop-off ring blue, the rescue pickup's ring dashed and the race ring chequered (`beacon.gd`); for shots |
| `--lang=pl\|en` | the language for this run (2026-11-02): over the saved choice and the phone's, not saved; `tools/check_language.gd` runs every screen in both |
| `--no-touch` | desktop (trailer loop, 2026-10-29): no touch-only controls on screen (the pedals and HAMULEC, the stick's knob and Classic's strip hint, the helicopter's ▲/▼ pads, the title's "tap to drive"); the top row, minimap, wallet, cards, bubbles and the radio caption stay, and the panels get the pedals' room; the keys still drive. For recording on the computer (`tools/check_hud.gd` checks it) |
| `--no-input` | loop 3d-1: the window never takes the keyboard focus (`WINDOW_FLAG_NO_FOCUS`): test renders whose windows hold the focus for minutes (`check_streaming.gd` passes it; keys typed in another app had toggled the time of day, the overlay and the radio) |
| `--prebuilt` | load the prebuilt sectors like the exported game (loop 3c: `map/index.res`, `map/proxies.scn`, `map/sectors/s_<i>_<j>.scn`; `city.scn` before) instead of building each sector from its file |
| `--monolithic` | loop 3c: build the whole city at once from `centrum.json`, as before loop 3c (no sectors, no streaming): the pixel diff's reference |
| `--sectors=all` / `--sectors=proxies` | loop 3c: load every sector at the start and keep them all (the old behaviour) / only the sectors the car stands in, every other one as its proxy (to look at the proxies) |
| `--stream-log` | loop 3c: print every sector load (`stream: frame N in s_i_j, X ms on the main thread ...`), unload, any frame whose streaming went over 3 ms and any node that took over 1 ms to add; loop G0+: each worker load (`stream: frame N worker s_i_j: load X ms, instantiate Y ms, K frames; slowest frame Z ms (overlapping the load end + instantiate; process after …, draw …, to physics …, physics …, process before …)`) |
| `--spots=X,Z,H/X,Z,H/...` | loop 3c, with `--shots=F1,F2,...`: the car jumps to spot k (heading H) 90 frames before shot k, the sectors the view needs are finished 30 frames before it (`tools/check_streaming.gd`) |
| `--stream-soak=MIN` | loop 3c: the car on autopilot over every sector's middle (row by row, through buildings), the view 80 m then 220 m every 20 s, the helicopter for the last third; then `stream soak:` lines and the game quits (no traffic); loop G0+: the same two lines also go to `user://stream_soak_result.txt` (`tools/device_run.sh` copies it back), and `stream soak stats:` adds `frames_over_budget` (frames whose streaming took over 3 ms), `slow_frames` (each frame over 33 ms past the warm-up: frame, ms, the streaming ms in it), `sector_ms` (median, p99, max of a streamed sector's main-thread ms) and `kinds` (per node class added, the hand-over, the finish and the unload: count, total and worst ms); loop 3d-2b: `stream soak stats:` adds `max_loaded` (most sectors in full at once), `slot_waits` and `evictions` (map slots), `missing_log` (the first frames that missed a sector in view: frame, sector, its state), `frame_median_ms` and `load_frame_ms` (per streamed sector the slowest frame from its worker's start to its last node: median, p90, max) |
| `--stream-pass=heli` / `--stream-pass=car` | loop 3d-2b: one fast pass instead of the soak's tour: the helicopter at its highest (360 m) and fastest west to east along z −300 (the Palace's north, the river, Praga), or the car at 45 m/s in its top-speed view east to west along z 250; it starts at the route's start facing along it, counts once nothing is left to load, then prints the soak's two lines and quits (no traffic) |
| `--stream-pass=heli-low` / `start` / `switch` / `look` / `jump` | the loading fix (2026-10-31), passes that look for a proxy close up, all from the spawn: `heli-low` the helicopter at 45 m (or `--heli-alt=M`), full speed, four legs with turns (300,279 · 300,−800 · −1400,−800 · −1400,900); `start` the first two legs from the very first frame (no waiting for the ring round the start); `switch` the car at 45 m/s on the first leg, then the helicopter takes off for two more; `look` hovering, a look at a target every 7 s (0.6, 1.0, 1.5, 2.1, 3.0 and 2.3 km off, as a new rescue or delivery target gets); `jump` the car put somewhere new every 7 s (six places, as a tow or a race start does). The soak's two lines then carry `proxy_near_m`, `proxy_share_max`, `proxy_share_frames`, `proxy_run_frames` (see "The loading fix") and each look or jump prints the frames with a proxy in the view since the one before |
| `--stream-ahead=0` | loop 3d-2b: no look-ahead (the streamer as before, for a before/after on one build) |
| `--stream-slow=MS` | loop 3d-2b: every worker load takes MS ms longer (the phone's slower loads on the Mac: `--stream-slow=400` with the look-ahead off misses 337 frames in the helicopter pass, with it 0) |
| `--stream-gate=0` | loop 3d-2b: a prebuilt sector's pieces load with its scene at once (the old one-frame load end), not one a frame |
| `--solo=KEY` / `--solo-look=lit\|flat\|sil` | landmarks 0.3: build one landmark site alone (key as in `landmarks.gd`: `palace`, `rotunda`, `varso`…), no ground, roads, buildings or traffic, on a plain background, runtime city path only (forces off `--prebuilt`). `flat` (default) = unlit in the site's colours on grey, `sil` = dark silhouette on near-white, `lit` = the normal look. Use `--time=day`; the judge's shots (model-from-photos skill section 5): `tools/shots.sh --set=first` |
| `--no-ghost` | 2026-10-31, for the landing's screenshots: no occlusion ghost and no see-through hole round the car (the dither and the hole that open buildings between the camera and the car), so a wide framed shot (`--yaw` / `--pitch` / `--size`) centred on a spot behind a building keeps it whole. The landing's Palace shot: `--at=-1180,215 --yaw=225 --pitch=-38 --size=400 --time=live --clock=18:15 --date=20260915 --nohud --no-ghost` at 1920x1080 |
| `--topdown` | 2026-11-07, F: road photos from height, like GTA: the camera looks straight down, north up, with no occlusion ghost, to check kerbs, asphalt and paint. T toggles the same road view in a running game (keyboard). With `--at=X,Z --size=55 --nohud --no-traffic --shots=30 --out=DIR` it makes a road plan shot of any spot |
| `--debug-ao` / `--no-ao` | show / switch off the baked ground shadows |
| `--lite-shaders` | 2026-11-08: the Adreno 6xx shaders on any GPU (`gpu_quirks.gd`: building.gdshader without its specular lobe), to see on the Mac what the Nothing Phone 1 draws |
| `--heli` | start in the helicopter |
| `--heli-stick=X,Z` | the L-shaped map loop (2026-10-31): the helicopter's stick held towards that world direction (x east, z south; length up to 1) the whole run, for screenshots of the clamp along the map's outline (with `--heli --at=`) |
| `--heli-alt=M` | loop 3d-2b: start in the helicopter M metres over the ground, placed there at once (360 = its highest; the memory and far-level probes) |
| `--mission=N` | start rescue call N at once (N = 1, 5, 9… streets, 2, 6… roofs, 3, 7… river, 4, 8… parks) |
| `--autopilot` | testing aid: fly (or, ghosting through walls, drive) to each mission target; in a race or a side job, drive the route; with `--rival`, tail the rival |
| `--ghost-pace=X` | testing aid (street races, 2026-11-04): the autopilot's speed factor in a race (default 1.8, an average player; 2.4 a quick one; `racer`: a skilled player in traffic.gd's racer mode at the car's top), for the race-AI runs (`tools/race_ai.sh`) |
| `--handling=cruise\|sport\|grounded` | Grounded handling (2026-11-08): drive this run in that profile (car.gd PROFILES), whatever Settings → Jazda says; `check_lane_drive.gd` takes it too |
| `--lane-assist=on\|off` | beta values (2026-11-04): the lane assist "Asysta pasa" (`lane_assist.gd`, Classic only) for this run, whatever Settings → Jazda says (off by default) |
| `--race-debug` | testing aid (street races, 2026-11-04): once a second while a racing rival or a chaser stands still, traffic.gd prints what holds it (the car ahead, the player, a crossing car, a red, the lane); and (2026-11-09, docs/design/race-ai.md) once a second of a race rivals.gd prints `race trace:` (the rival's speed, its skill share and effort, the road's class, the metres both have left, the player's speed, the rival's lead in metres and seconds, whether she is seen) |
| `--no-traffic` | no traffic, trams, pedestrians or rivals |
| `--lineup` | loop 2c: every vehicle model standing round the car, all facing its way (beside it the taxi, Podwózka, the police and guard cars and the two vans; a row ahead the cars' four shapes; behind, the six rivals, then the bus and a tram cab car), no traffic, and each model's triangles printed (`lineup:` lines). Close-ups: `--at=-1113.2,-263.4 --heading=160 --size=14 --nohud` (Marszałkowska) |
| `--race=N` | race rival N (1–6) at once: they are put just ahead of you |
| `--rival=N` | put rival N just ahead of you (with `--autopilot` you tail them, so the FLASH LIGHTS prompt shows) |
| `--bench` | drive a route through the traffic and print the average frame time over 600 frames, the scripts' cost and the 3D view's GPU time; loop 2b: also the bench's lines (see Loop 2b), a 30 s cap, the result in `user://bench_result.txt` (removed when a bench starts, so a run that ends early leaves none) |
| `--time=day\|dusk\|night\|dawn` | start at that time of day (default day); `dawn` (loop MW-3): Świt, Dusk's palette with the sun in the east-north-east at 05:45 on a Saturday (a fixed night is Friday's) |
| `--vhs` | VHS overlay on (for this run; Settings saves it since loop 2e) |
| `--radio=N` | radio station 1–4 (loop MW-5: any station in radio.json; 4 is PÓŁNOC FM), or 0 / `off` (default 1; the radio then doesn't follow the clock) |
| `--station=ID` | loop MW-5: a station by id (`polnoc_fm`), short id (`polnoc`), name or number; the radio then doesn't follow the clock |
| `--radio-log` | loop MW-5: print `radio:` lines (tunes, track changes, host lines with the gap since the last, unlocks, PÓŁNOC FM on air / reruns) and the city sounds' `sounds:` lines (emitters on and off, chimes, tolls, the 02:00 beat) |
| `--unlock=all\|N[,N]` | loop MW-5: every PÓŁNOC FM track for this run (nothing saved), or open track N as an egg would (toast, saved unless `--nosave`) |

| `--notitle` | skip the title screen (the testing flags `--demo --shots --autopilot --race --mission --rival --bench` skip it anyway) |
| `--title` | show the title screen even with those flags (for screenshots) |
| `--kebab=N` | put the car in a stand's ring and take kebab order N (the same N gives the same order; stand N mod 7) |
| `--sloik` / `--sloik=K` | start the słoiki run at Dworzec Centralny (K jars already broken); `--sloik-station=1` starts it at Dworzec Gdański (to Muranów) |
| `--ride=N` | loop 2d-1: Podwózka ride N's request, the car on the road 60 m before its passenger (the same N gives the same ride; with `--ride-quirk=river` or `zone` the passenger is picked near river spot / park N, so the leg fits); with `--autopilot` it is accepted after 2 s and driven |
| `--ride-quirk=river\|zone\|oldtown\|rechotka\|reroute` | loop 2d-1: force the ride's quirk (`oldtown` becomes `zone` on today's map; `rechotka`, the Frogs turn: in the random pool since loop MW-2) |
| `--crawl-call` / `--crawl-route=ID` / `--crawl-group=ID` / `--crawl=0` / `--crawl-log` | 2026-11-07: the bar crawl (bar_crawl.gd): the group rings a second in at any hour, that route (`klasyczna`, `nad_woda`, `odwazni`, `praga`) or group (`panienski`, `kawalerski`, `sesja`, `wdrozenie`), none of it, the `crawl:` log lines; with `--autopilot` the call is answered, accepted and driven |
| `--passenger=normal\|believer\|hurry\|detour` | loop 2d-1: force the passenger type (loop MW-2: `detour` asks for a Frogs stop, +½ star once) |
| `--ride-story=ID\|none` | 2026-11-07: that story passenger (`data/taxi_stories.json` id) on the rides, or `none` for the old chat |
| `--ride-answer=0\|1` | 2026-11-07: the autopilot's answer to the story passenger's question (default 0) |
| `--no-parodies` | loop MW-2: no storefronts (Frogs, venue neon, Leżaks, metro entrances, the new billboards) and no Pędzik couriers |
| `--rechotka` | loop MW-2: the car on the lane by the nearest placed Frogs' door, stopped (the stamp in 2 s) |
| `--stamps=K` | loop MW-2: the Frogs card starts at K stamps (9: the next stop is the free hot dog) |
| `--courier-race[=N]` | loop jobs-2: kebab order N (default 0) with the Pędzik courier's challenge forced (day or night); with `--autopilot` the challenge is taken after 1 s; `courier:` lines (the way vs the straight line and the road, the result, the pay) |
| `--courier-v=M` | loop jobs-2: the courier's speed in m/s for a test run (by default his pace: the order's road at 10 m/s, 6.5-11 m/s, loop couriers; `--courier-v=3` lets the autopilot win) |
| `--pedzik-log` | loop couriers: print `pedzik:` lines: the minute's riders on the paths and on the kerb, the couriers waiting (and at how many stands), the swerves, hops and lines; each swerve, hop and near miss; a waiting courier taken by the race |
| `--pedzik-kerb` | loop couriers: a testing aid for shots: the kerb riders start 8-35 m from the view (not 25-150 m), so one is in view at once |
| `--roundup` | loop jobs-2: the car in the ring of the Leżak depot nearest it and the round-up's card up (day or night); with `--autopilot` GO is taken and the car slides to each Leżak and back; `roundup:` lines |
| `--armchair` | loop jobs-2: the armchair man (E34) out today at any hour; the car on the lane nearest him once his way is known |
| `--stars=X` | loop 2d-1: the live rating starts at X (1–5; for card shots) |
| `--ignore-app` | loop 2d-1: the autopilot drives the shortest road to the door, not the app's route |
| `--parody-log` | loop 2d-1 (and MW-2: `storefronts:` lines, each Frogs and venue on its wall or not, each Leżak knocked): print `ride:` lines (the offer, the pickup, the quirk and its waypoint, every star change and why, the arrival, the pay with the wallet before and after, cancels, the autopilot's legs) and `gps:` lines (each GPS moment in traffic) |
| `--gps-in=S` | loop 2d-1: the app-taxis' first GPS moment is looked for S seconds in (screenshots) |
| `--pullover-frame=N` | loop 2d-1: the `--pullover=TAG` conversation at frame N instead of 60 (e.g. during a `--ride`) |
| `--heat=X` | the kebab's starting heat, 0–1 (for a cold-arrival screenshot) |
| `--craft=plain` | the autopilot takes the plain kebab at Zagłębie Kebabowe's craft shop (`--kebab=47`; by default it waits for the hand-carved one) |
| `--host-in=S` | the radio host's first line after S seconds |
| `--barriers=YYYYMMDD` | place the roadworks for that day |
| `--free` | free roam: no call (loop 2e: there's no call card at the start anyway; with `--free` the first call comes in 90 s into play instead of 60) |
| `--tap=X,Y` | tap that screen pixel at frame 60 (a landmark's info card) |
| `--reset-save` / `--nosave` | wipe the wallet and record / neither read nor write `user://save.cfg` (nor, since loop 2a, `user://settings.cfg`) |
| `--title-choice=continue\|new\|ask` | save and resume (2026-10-31): the title screen (forced on) picks KONTYNUUJ, NOWA GRA (wipes the save, a copy in `user://save.prev.cfg`, and starts the scene again), or shows NOWA GRA's question, once the start is in |
| `--resume=x,z[,heading]` | save and resume: a kept spot in memory (the title forced on; with `--nosave` the resume path without a real save) |
| `--time=live` | v0.9: the real sun for the device's clock (TIME's fourth mode) |
| `--clock=HH:MM` / `--date=YYYYMMDD` | start Live's clock at that Warsaw time (and date; default today); loop MW-3: with a fixed look (`--time=night --clock=01:00`) the game clock starts there, the look stays |
| `--weather=clear\|rain` | start dry or in the rain (default clear) |
| `--perf` | show the performance overlay (loop 2e: four lines: fps, frame time, worst, cap · CPU process + physics + draw, GPU, memory · draw calls by pass · objects, triangles) |
| `--quality=auto\|low\|medium\|high\|ultra` | the quality for this run (not saved; loop G1: default Auto, the level `tiers.gd` picks for the device; 0–3 are Low–Ultra) |
| `--model=ID` | loop G1: pick Auto's level as if on that device (`--model=iPhone12,1` is the iPhone 11: High; since loop G1b Auto draws it sharp, 1792×828 ×1, and 896×414 ×2 in the fallback; `iPhone17,2` the Pro Max: Ultra) |
| `--last-session=struggled\|calm` | loop G1b: start Auto as if the last session at the sharp image struggled (this launch is the ×2 fallback) or was calm (the sharp image), whatever the settings file says; nothing of it is written. The `quality:` lines say what Auto picked and why (`quality: Auto→High ×1 sharp (iPhone12,1) · image 1792x828`, `quality: Auto→High ×2 fallback (last session: GPU extras down 74 s of 410) · …`) |
| `--governor=on\|off\|log` | loop G1: the frame governor on or off for this run (default: on in a normal launch, held in test runs, the bench, the probe and the BENCH minute; `on` lets it act in those too); `log` is on plus a `governor status:` line every 5 s (loop G1b: with the session's tally where Auto's sharp rule applies) and a `governor minute N:` line per counted minute (fps, missed refreshes, GPU-bound ones, GPU extras down) |
| `--stress=cpu:N\|wait:N`, `--stress-from=S`, `--stress-to=S` | loop G1 testing aid: N × 0.5 ms of busy work a frame from S to S2 seconds after the city is up, in the game loop (`cpu`: the CPU's extras go first) or in the draw phase (`wait`: how waiting for the GPU looks to the main thread, the GPU's go first), to watch the governor drop and come back |
| `--sound-check` | play every sound once and print the bus meters, then quit (needs an audio device) |
| `--ghost-debug=1\|2` | loop 1: paint the occlusion ghost (1: ghosted magenta, other buildings green) or cut it fully (2), and print its ellipse in screen pixels with each screenshot |
| `--controls=point\|classic\|fixed` | loop 2a: the control scheme for this run (not saved) |
| `--traffic=empty\|low\|normal\|busy` (or 0-3) | loop 2a: the traffic level for this run (not saved) |
| `--settings` | loop 2a: open the settings panel at the start (screenshots) |
| `--fullmap` | F's asks (2026-10-30): open the full-screen map at the start (the game paused; screenshots) |
| `--fullmap=M` | 2026-10-31: the same, M metres across the screen's height (the game map's shots) |
| `--quest-pick=N` | G12 part 2 (2026-11-02): open the full map at the start and tap row N of the ZADANIA tab shown (the vehicle's); a place's pick closes the map and becomes the quest pin |
| `--quest-quit=S` | F 2026-11-08: S s into the run, open the full map and tap the quest card's "✕ Quit" button twice; prints `quest quit test:` lines (running before/after) |
| `--quest-tab=N` | quest map (2026-11-07): the full map's quest card opens on tab N (0 AUTO, 1 HELI, 2 WĄTKI) |
| `--story=ID` | quest map: questline ID (`boat`, `rave`) starts from the WĄTKI list 1.5 s in (its friend phones) |
| `--story-meet` | quest map: the friend's WCHODZĘ is pressed by itself a second after they walk up (the in-person start without a tap) |
| `--stories-log` | quest map (`story_quests.gd`): the questlines, quest focus, the friend walking up |
| `--map-jump=X,Z` | 2026-10-31: the full map's hold-to-teleport to X,Z at the start (prints the refusal, if any, and where the car went) |
| `--settings-tab=N` | loop 2e: open the settings panel at tab N (0 Jazda · Driving, 1 Świat · World, 2 Obraz · Picture, 3 Dźwięk · Sound; loop MW-1: 4 Zeszyt · the notebook) |
| `--notebook` / `--notebook=CHAPTER\|ID` | loop MW-1: open the settings card on MOJA WARSZAWA, the notebook (a chapter by id or number 1-9, or a place's card by its id; screenshots) |
| `--found=all\|none\|CHAPTER[:K],…` | loop MW-1: the notebook's record for this run, in memory, no rewards (a chapter by id or number, `:K` its first K places; `--found=1:4,9` half of the first chapter and all of the ninth). Use with `--nosave` (a later save would keep it) |
| `--place=ID` | loop MW-1: start at a notebook place (`places.json` id): the sectors round its hint first, then the car on the nearest lane if that is inside the place's radius, else on the place (found within a second, standing) |
| `--egg=<id>` | loop MW-6: the vehicle at that egg (`data/eggs.json` id, `e07` or `palma`) in its look, weather and day (`--time`, `--weather`, `--date` set for it), a motion trigger (lap, street, circle) driven along its path at 90 % of its speed limit; prints `egg: --egg=<id> <kind> at x, z (state)`, the find with its reward (`egg: found <id> <name> (k/45): +N respect[, track n][, then card ...][, kadr ... open]`) and `egg: --egg=<id> found S s after the start`; a waiting egg says what it waits for. Implies `--egg-log` |
| `--egg-log` | loop MW-6: print `egg:` lines: each trigger met (with the state), each find and reward, with `--egg` the state every 10 s until found |
| `--pop=<zl>` | v1.0 juice: pays that many złoty two seconds into the run, to see the money pop (`money_pop.gd`) and hear the coin. Use with `--nosave` |
| `--district=<id>` | loop 3h slice 1: that district's "discovered" card at the districts' first check (a screenshot aid; it is also discovered if the car is in it). Use with `--nosave` |
| `--districts=all\|none\|<id>[:jobs],…` | loop 3h slice 1: the districts discovered for this run (and the jobs done in each), in memory, no cards or rewards (the full map's shots). Use with `--nosave` |
| `--districts-log` | loop 3h slice 1: a `districts:` line when the vehicle changes district, discovers one, and the summary at the start |
| `--syrenki-log` | loop 3h slice 2: `syrenki:` lines: each figurine's spot, its metres from the anchor and from a lane centre, and every find |
| `--syrenki=all\|none\|<n>\|<id>,…` | loop 3h slice 2: the Syrenki found for this run (the first n, or those ids), in memory, no cards or rewards. Use with `--nosave` |
| `--ladder=N` | loop 3h slice 3: the first N rungs of the rival ladder beaten for this run (0-7; 6: only the final left, 7: the final won too), the respect raised to open the next, in memory (`ladder:` lines). Use with `--nosave` |
| `--first10` | loop 3h slice 4: the guided first 10 minutes in a test run (first10.gd: the guide as on a fresh save, no title; `first10:` lines per beat). With `--autopilot` the headless replay: the car taken to the first stand at 0:15, the flash back at Halina, the call answered, the boulevard tape played, the result cards closed; it prints `first10: OK (…)` when every beat's trigger fell inside its window (an error line per miss) and quits after the garage (~575 s of play), or judges at 700 s at the latest (missing beats fail; a NaN car fails at once). Use with `--nosave` |
| `--end-card` | loop 3h slice 4: the end card ("Dzięki za grę! / Thanks for playing!") at once, whatever the save (screenshots) |
| `--first-race` | loop 3h slice 4: Pani Halina rolls up behind the car a second in, for the guided first race (the prompt, then the race to the Palm on her gentle day; screenshots, the race's feel) |
| `--trzy-mosty[=N]` | loop 3h slice 3: the final race "Trzy mosty" at once (`=N`, 1-3: from the river span of bridge N, the bridges before it counted, Seba 12 m behind in the next lane: screenshots and a quick finish): the run at night, the ladder up to the final (as `--ladder=6` unless `--ladder` says), the car at its start at Rondo Daszyńskiego, Seba ahead, his challenge and the countdown; with `--autopilot` the ghost drives the seven legs (`trzy mosty:` lines: the start, the length, each checkpoint, Seba over each bridge, the result) |
| `--syrenka=<id\|n>[:m]` | loop 3h slice 2: the car on the street beside that Syrenka (an id or 1 to 20), m metres before it (25 by default; `:0` finds it at once), facing it (a screenshot aid) |
| `--found-eggs=all\|none\|reachable\|ID,…` | loop MW-6: the egg record for this run, in memory, no rewards (screenshots of the SEKRETY page). Use with `--nosave` |
| `--tape=<id\|n>` | loop MW-6: the car stopped at that then card (`then_cards.json` id or 1-20), the tape played at once (ghost, sound, card); implies `--tape-log` |
| `--tape-log` | loop MW-6: print `tape:` lines: the ghost built and dropped, each play (`tape: n <id> ghost ok (k boxes)[, first time: +15 respect]`) |
| `--spacer` / `--wander`, `--no-spacer` | loop MW-6: Spacer (wander mode) on or off for this run (not saved) |
| `--zone-cap`, `--no-zone-cap` | F's asks (2026-10-30): the pedestrian zones' 20 km/h cap, pill and whistle on or off for this run (not saved; the setting is off by default); verify.sh's G1 run passes `--zone-cap` |
| `--spacer-hint=S` | loop MW-6: Spacer's first hint after S s (default 180-300, seeded); `spacer:` lines log each hint (`spacer: hint n -> <place> (name), d m; next in s`) |
| `--fotka` / `--photo` | loop MW-6: open Fotka at the start (screenshots of the photo mode) |
| `--kadr=<n\|id>` | loop MW-6: Fotka open at that Kadr spot (`kadr.json`, 1-15 or `k07`), in its look, aimed at its subject, a photo 2 s later; implies `--photo-log` |
| `--fotka-shot=S` | loop MW-6: with `--fotka`, take a photo S s after it opens |
| `--photo-log` | loop MW-6: print `fotka:` lines (open, close, `fotka: saved user://photos/... (WxH)`) and `kadr:` lines (`kadr: n ok (<id> ...)` or `kadr: none (why)`) |
| `--crowd=0\|1\|2` | loop MW-3: the night and river crowds off (nothing built, no cost), normal (default) or doubled; the Low tier halves them |
| `--night-log` | loop MW-3: print `night:` lines: the sites at the start, a summary every minute (`night: 01:00 day 6 · queues … smola 24 … · rejections 1 · car lines 0 · dawn walkers 30 · roof 0, steps 24, plan_c 28 · police on`), each rejection, line, police unit and the dawn routes |
| `--life=0\|1\|2` | loop MW-4: everyday life (dogs, riders, runners, Kolka, Hyrax, the Wiralek fascias and the "Na czasie" job) off (nothing built), normal (default) or doubled; the Low tier halves it |
| `--dogs-log` | loop MW-4: print `dogs:` lines: the minute's summary (`dogs: 07:30 day 5 · 10 walkers (Powiśle / Plac Zbawiciela ×2) · 2 at trees · barks 0 · horn lines 0`), each bark and horn line |
| `--trend-log` | loop MW-4: print `trend:` lines: each slot's day and queue at the start and on every change (`trend: slot 1 day 3 queue 20 (CZEKOLADA Z PUSTYNI, wiralek_zbawiciela)`), Lukrownia on Fat Thursday, the slots seen for E18, and `trend job:` lines |
| `--life-log` | loop MW-4: print `life:` lines: the index, the minute's summary (riders, runners, Kolka, Hyrax, bells, the Zając), the bell, E28's follow, the Zając |
| `--zajac` | loop MW-4: Live on Wednesday 2026-10-28 at 19:00 (`--clock=` and a Wednesday `--date=` change them), the car by Kolka's start (free roam, no title); with `--autopilot` the car paces the club 10 m to its side from 19:00 (the Zając: `life: zajac paid +40 respect (E29)`) |
| `--trend-day=N` | loop MW-4: the Wiralek cycle's day number (0 = slot 1 on day 1, slot 2 on day 3, slot 3 on day 5; 88 = all three on day 1) instead of Live's date or the session's |
| `--trend-job[=1\|2\|3\|4\|5\|6\|7\|8]` | loop MW-4: start by that Wiralek slot (1 Plac Zbawiciela, 2 Chmielna, 3 Tamka; 4: PISTACJA's "Limitka" drop job, whatever the clock; 5: PADELNIA's "Czwarty"; 6: Mrożulo's van parked by the car near KUKŁA on Nowy Świat with his "Mlask" request, docs/design/gaulle-and-food-hype.md G5; 7: the DESKA padel call; 8: Mrożulo's "Dżemini" call, the car by DŻEMINI KEBAB on Świętokrzyska, G5b) with its request offered; with `--autopilot` accepted and driven (Mlask: the review card closes by itself); implies `--trend-log` |
| `--dzemini` | G5b: Mrożulo's MLASK already on DŻEMINI KEBAB (its queue for good, the sticker on its wall), the car by the shop; implies `--trend-log` (docs/design/gaulle-and-food-hype.md G5b) |
| `--night-hub` | night-buses loop: a gathering of night buses at Dworzec Centralny now, whatever the time (with `--time=night`, the N signs too); its buses park at their bays at once |
| `--train=X,Z[,K]` | railway T1 (docs/design/railway.md): a train put on the track nearest that point at the start, rolling on (shots); K picks its kind (trains.gd KINDS: 0 Koleje Mazowe, 1 SKiM, 2 the long-distance one) |
| `--old-tram` / `--old-tram=follow` | vintage-tram loop: the old two-car set now, on the track nearest the car, whatever the time (it stays); `=follow`: and the car (no collisions) kept 22 m behind its tail, so the view goes with it and E39's 300 m count runs |
| `--packs=0` | packs (docs/design/packs.md): no running clubs, cycling packs or coffee raves (`--crowd=0` drops them too) |
| `--packs-now` | packs: every club and every COFFEECHAIR café's rave on whatever the clock says; each pack whose loop passes within 300 m of the car's start is timed to stream past it a few seconds in (shots) |
| `--packs-log` | packs: print `packs:` lines: the routes' lengths, each club setting off and going home, each rave with its booth's position, the minute's summary (where each pack's head is), every line and meeting |
| `--fans=0` | the fans by Stadion Leguminy (fans.gd) off (also off with `--crowd=0`) |
| `--fans-now` | fans: the three groups out on whatever the clock says (shots, checks); otherwise only on match evenings (Wed 17:00-21:30, Sat 15:00-21:30, Sun 14:00-20:30) |
| `--fans-log` | fans: print `fans:` lines: out and home, each chant (and the horn's), every line |
| `--event-day` | 11 listopada (event_day.gd): the Independence Day event on whatever the date and clock say, full strength (the crowd and flags at Rondo Dmowskiego and Al. Jerozolimskie, the four barrier lines, the Palace, Złota 44 and Stadion Narodowy lit white and red, the glow and haze); otherwise it switches itself on only on 11 November (the Warsaw date, live clock) |
| `--event-day=0` | the event off even on the date |
| `--event-smoke=0` | the event without the glow pots, the haze and the smoke puffs (the "smoke off" look) |
| `--event-log` | event: print its build line (people, flags, glow pots, bands) |
| `--fans-phase=arrive\|match\|leave` | fans: the match day's phase whatever the clock (its busy part: arrive at 0.75, leave at 0.15), so shots show the walkers |
| `--fans-result=win\|draw` | fans: the result at full time instead of the roll (65 % win) |
| `--wellness=0` | wellness circles (docs/design/wellness.md): no sound-healing rings, techno-yoga rows, 40+ circles or kung-fu schools (`--crowd=0` drops them too) |
| `--wellness-now` | wellness: every spot on whatever the clock says (shots) |
| `--wellness-log` | wellness: print `wellness:` lines: each spot starting and packing up, every line and meeting, the minute's summary |
| `--tamka-log` | Tamka (tamka.gd): print `tamka:` lines: bollards built, the walk length, KEBONAFIDE's position every 0.5 s and each line he says |
| `--tram-log` | vintage-tram loop: print `old tram:` lines: each run taken out of sight and turned modern, the follow count every 50 m and its resets, E39 |
| `--bus-log` | night-buses loop: print `buses:` lines: the hub's bays and stops, each gathering and ring bus, the car at the ring, the race to the Palm, each honk and called bus, the stop lines, a summary every 20 s |
| `--crash=now` / `--crash=X,Z` / `--crash=on` / `--crash=0` | crash scenes (`crash_scenes.gd`): a scene now 45-130 m ahead of the car (shots; it may be in view), or on the fitting road nearest X,Z; `on`: the 3-5 minute timer in a test run too (it runs in a normal launch only); `0`: none |
| `--crash-log` | crash scenes: print `crash:` lines: the first scene's wait, each scene (where, street, lane, vehicles, distance, life), the radio line, every bubble line, each clear and the next wait |
| `--boat-race`, `--boat-race=call` | boat race (`boat_race.gd`): Szymek rings now, whatever the time |
| `--boat-race=race` | boat race: the car at the start pontoon and straight onto the grid (3-2-1) |
| `--boat-race=auto` | boat race: as `race`, with the player's boat driven by the rivals' driver (the shots and the full-race probe) |
| `--dekalog`, `--dekalog=call` | Kieślowski tour (`dekalog_tour.gd`): Claire rings now, whatever the time |
| `--dekalog=go` / `=auto` / `=0` | Kieślowski tour: the car at Centralna and the tour started (`auto`: the cards answer themselves); `0`: none |
| `--dekalog-log` | Kieślowski tour: print `dekalog:` lines (pickup, frames, shots, hits, the pay) |
| `--boat-race=free`, `=free0`..`=free2` | free ride: the car at the start pontoon, out in a fleet boat (0 jet ski Rekin X, 1 electric Srebrna Strzała, the default, 2 offshore Czarna Pantera; no rings, no rivals) |
| `--boat-race=marina` | the car at the start pontoon with the marina card up (REKIN X / STRZAŁA / PANTERA / WYŚCIG) |
| `--boat-race=0` | no boat race (no call, no pontoon) |
| `--boat-log` | boat race: `boat race:` lines (the call, the grid, misses, finishes, solid hits) |
| `--kino-tour`, `--kino-tour=call` | cinema tour (`kino_tour.gd`): Wiktor rings now, whatever the time |
| `--kino-tour=go` | cinema tour: the car at the pickup on Plac Zbawiciela and the tour started |
| `--kino-tour=auto` | cinema tour: as `go`, its cards answered by themselves |
| `--kino-tour=0` | no cinema tour |
| `--kino-log` | cinema tour: `kino:` lines (the call, pickup, shots, scratches, pitches, the premiere's pay) |
| `--rave-call` | secret rave (`rave.gd`): LEKTI's break-in on MORDOR FM now (with his voice) and Ziomek rings a second later, whatever the time |
| `--rave-smola` | secret rave: Ziomek rings now for the club night at Smoła (the door's three questions, then the room) |
| `--rave-club` | secret rave: straight into Smoła's cutaway room (option A: the jungle, the DJ, the dancers, the lights, TAŃCZ, PATIO and WYJDŹ) |
| `--padel-match[=HOUR]` | arcade padel (padel_match.gd): straight onto the DESKA court at HOUR (default 12; 20 is the floodlit night), the match plays itself, the game quits at its end |
| `--padel-log` | arcade padel: one line per point, the match's in and out |
| `--shisha-call` | shisha night (shisha.gd): Ivan rings now (ODBIERZ, then JADĘ!) |
| `--shisha-meet` | shisha night: the car at Ivan's kerb in 19. Dzielnica, Ivan gets in, on to Bogdan at the Żelazna court |
| `--shisha-lounge` | shisha night: straight into SENATOREK (lounge.gd), the mini-game playing itself (best jars, clean coal and draw), then PALIĆ |
| `--shisha-terrace` | shisha night: as `--shisha-lounge`, then TARAS (the terrace with the Palace) |
| `--shisha=0` / `--shisha-log` | no shisha night / its steps in the log (shisha: ..., lounge: ...) |
| `--rave-patio` | secret rave: straight into Smoła and out to its patio (the courtyard, the mirror ball, PÓŁNOC FM, SALA back in) |
| `--rave=on` / `--rave=day` / `--rave=0` | secret rave: the night rig on now (the lights in the lit look), the day rave's crowd now, or no raves and no calls |
| `--rave-spot=ID` | secret rave: tonight's spot (`wiadukt`, `zajezdnia`, `hala`; `plaza` is the day spot) |
| `--rave-log` | secret rave: print `rave:` lines (tease, the call, pickup, meeting point, door questions and answers, pay, the rig's mode, the room) |
| `--meet-call` | night racing club (`street_meet.gd`): Darek „Bawarka" rings now, whatever the time |
| `--meet=on` / `--meet=0` | night racing club: the night rules at any hour / none of it |
| `--meet-at=meet\|raid\|race\|meet2\|drag\|stage` | night racing club: jump to that beat (the car moved to it; `stage` puts it on the drag's line with the tree running) |
| `--meet-log` | night racing club: the call, meets, raids, race places and drag times in the log |
| `--ev-call` / `--ev-tow` / `--ev-tow=carry` / `--ev-stranded` / `--ev=0` | dead electric cars (`ev_tow.gd`): Bartek's call rings a second in; `--ev-tow`: accepted, the helicopter over his car; `=carry`: his car already on the sling, the helicopter climbing to 22 m; `--ev-stranded`: a stranded TESŁO about 30 m ahead now; `0`: none (the call and the stranded cars run on their timers in a normal launch only) |
| `--ev-log` | dead electric cars: print `ev:` lines: the chargers found, the timers, the call, the car's street and charger, the hook, Bartek's lines, the set-down and pay, each stranded car |
| `--loud=N` | loud cars (`loud_cars.gd`, city-life satire #1): at most N loud supercars in traffic at once (default 3, up to 16 for shots); `0`: none, and no car meet at Browary nor its crowd |
| `--crazy=N` | crazy drivers (`crazy_drivers.gd`, traffic.gd `CRAZY_*`, docs/design/crazy-drivers.md): at most N Szkoda Oktawia taxis, Szprynter couriers and the one Pasatini in racer mode in traffic at once (default 3, up to 12); `0`: none |
| `--crazy-log` | crazy drivers: print each cut-in or block near the player and KEBAB FM's Pasatini sightings |
| `--loud-log` | loud cars: print `loud:` lines: each rev (where), the meet's revs, KEBAB FM's line |
| `--honk=F1,F2,...` | night-buses loop: the player honks on those frames (as the horn button; rate-limited) |
| `--life-soak` | loop MW-4: a Friday dusk; the car is driven at the nearest dog walker or rider at 7 m/s, every frame counts a dog, walker or rider inside the car's footprint (`life: soak done … overlaps 0`); verify step `life-soak` |
| `--paint=<id>` | garage loop: the car starts in that paint (`red`, `cream`, `green`, `blue`, `yellow`, `black`, `pink`, `gold`), owned for the run (use with `--nosave`) |
| `--garage` / `--garage=ring` | garage loop: start in Warsztat u Mirka's ring on Brzeska, the garage shown whatever the wallet, the paint card open a moment in (free roam, no title; implies `--garage-log`); `=ring`: 16 m short of the ring, no card |
| `--garage=parts` | G13: like `--garage`, the card opens on the parts tab ("Części i auta") |
| `--pedal=nitro` | G13b: gas and the nitro disc held (with `--upgrades=nitro`), for shots of the tail flame |
| `--upgrades=all\|tt\|nitro` | G13: the car starts with the Ołdi TT, the nitro, and (all) tyres and engine at level 3, owned for the run (use with `--nosave`); the nitro is the N / Shift key or the bolt disc by the horn |
| `--garage-log` | garage loop: print `garage:` lines: the place, the card opening and closing, each buy and switch |
| `--club=<id>` | loop MW-3: start at that club (`lusterko`, `smola`, `jasna_0`, `lombard`, `milosc_hipoteczna`, or its name): the car on the lane nearest its door (within 60 m), free roam, no title |
| `--notes-log` | loop MW-1: print `notes:` lines: each place's resolution at load (`notes: place <id> address\|name\|poi\|near N m from the hint (x, z)`), each find (`notes: found <id> (chapter N, k/8)`) and each chapter completed |
| `--call-in=S` | loop 2e: the first rescue call comes in after S seconds of play (default 60) |
| `--stick=X,Y` / `--pedal=gas\|brake` | loop 2a: hold the stick at that deflection (-1..1, y down; Classic uses X) / a pedal, as if a finger were on it (screenshots, replays in the real city) |
| `--clicks=X:Y:F,...` / `--drag=X:Y:F:DX:DY:F2` | loop 2a testing aids: a click at screen pixel X,Y on frame F; a finger down at X,Y on frame F, moved by DX,DY over ten frames, lifted on frame F2 (through the real input path) |
| `--lift=M` | loop 1: aim the camera M metres above the vehicle (close-ups of tall landmarks: `--at=-1206,244 --lift=156 --yaw=110 --size=24 --lines=1080` looks at the Palace clock's east dial) |
| `--probe` | loop 2b: stand where `--at` / `--heading` put the car (free roam), let 240 frames (or 8 s) pass, measure the next `--bench-frames` (default 600, or `--bench-seconds`, default 30) and print the bench's lines plus what is in view (nodes, instances, shadow casters, materials, shaders, kinds); quits |
| `--no-map-edge` | railway lane (2026-11-01): the city without the land past the map's edge (`map_edge.gd`: the ring of ground, tree line, far blocks and the rails and roads running on), for a before/after `--probe` at the edge |
| `--no-edge-roadworks` | edge roadworks (2026-11-02): the city without the roadworks closing the roads at the map's edge (`edge_roadworks.gd`: meshes, halos and their colliders; the edge wall stays and the traffic still stops at the lines), for a before/after `--probe` at an edge |
| `--bench-frames=N` / `--bench-seconds=S` | loop 2b: frames to measure for `--bench` / `--probe` (default 600) and a time cap (default 30 s; with `--bench-button`, the BENCH run's length, default 55 s) |
| `--bench-button` | loop 2b: press TEST · BENCH at frame 60 (the phone's run, at the current settings and cap) |
| `--fps=N` | loop 2b: cap the frame rate for this run (0: none; else the setting, 60 or 30). `--bench` and `--probe` run uncapped, headless runs too |
| `--exp=a,b` | loop 2b, for ranking costs: switch one off: `nohud`, `nominimap`, `nobubbles`, `noshadow`, `nopost`, `notrees`, `noprops`, `nosmallcasters` (no shadows from instanced things), `nocasters`, `shadowsize=N` |
| `--debug-roads` | loop 3a: draw the bridge decks, approaches, tunnels, lane heights and piers round the car (Debug Draw add-on) |
| `--cam-log` | camera loop: print the camera every 0.25 s (`cam:` lines: scheme, finger, speed, the car's and the camera's compass headings, the camera's fastest turn since the last line, the car's place on screen, the view's height) |
| `--cam-test=classic_turn\|point_release\|brake` | camera loop: drive one camera moment in the real city (scripted inputs through the scheme's mapping, the car ghosting through walls, no traffic, 1 s parked first; implies `--cam-log`): Classic following, a 90° right turn at 50 km/h; Point, the stick held 90° right at 50 km/h for 2.5 s then let go; Classic following, flat out to 90 km/h then braking to a stop. Frame strips: add `--shots=` every 15 frames (`--at=-1113.2,-263.4 --heading=160` is Marszałkowska) |
| `--cinematic` / `--cinematic=flyin\|look\|opening` | camera loop: the cinematic moments in a test run too (they play only in a normal launch: never with `--notitle`, `--shots`, `--bench`, `--probe`, `--demo` or the other testing flags). With `--notitle` the fly-in starts at once; `--mission=1 --cinematic=look` shows the look at a rescue target. `=opening` forces the first launch's opening flyover (docs/design/opening-flyover.md; normally on a fresh save's normal launch only): `--first10 --cinematic=opening --shots=5,150,300,470` shows it |
| `--trailer=palace_time\|heli_dive\|palace_drift\|old_town\|card` [`--trailer-aa=0\|2\|4\|8`] | the beta trailer's scripted takes (game/scripts/trailer.gd), clocked by the frames' dt so a Movie Maker capture (`--write-movie f.png --fixed-fps 60`) plays them the same at any speed. No title, no HUD. `palace_time` 14 s: an orbit of the Palace while the light runs day, golden hour, dusk, night; `heli_dive` 10 s (dusk): the helicopter from the Palace to the Vistula and the stadium; `palace_drift` 10 s: donuts on Plac Defilad, a raid at 1.5 s and the camera widened to show the patrols coming (`--time=night` for the night version); `card` 5 s (night): JOIN THE BETA. Every take: Ultra held (no governor), full resolution (`--lines=1080` unless given), soft 8192 sun shadows, MSAA 4x (`--trailer-aa=`), 16x anisotropic, no see-through hole, the Palace's everyday gold light, no quest markers, a 6 km far plane |
| `--trailer=play` [`--trailer-len=S`] [`--trailer-say=PL\|EN`] | the beta trailer's gameplay takes (F 2026-11-10, the fast cut): the game as played, HUD (`--no-touch`), car, cards and jokes from whatever other flags start the moment (`--kebab=`, `--police=`, `--drive-into-water=`, `--meet-at=`, ...), with the capture's picture extras (Ultra held, full resolution, MSAA, 8192 shadows) and the job's beacon kept; quits after S s (default 10). `--trailer-say=` puts a caption band (Polish big, English under) over any take. Takes and flags: `tools/trailer.sh` |
| `--debug-roads` | loop 3a: draw the bridge decks, approaches, tunnels, lane heights and piers round the car (Debug Draw add-on); loop 3b: the piers, portal legs and cap beams the bake placed |
| `--tunnel` | loop 3b: with `--at`, start on the floor of the tunnel under that point (the car shows through the ground as a silhouette) |
| `--under` | GAMEPLAY_PLAN 0.3: with `--at`, start on the road under a bridge or viaduct deck there, not on top of it (the car shows through the deck as the tunnel silhouette) |
| `--drive-into-water=X,Z` | loop 10a: start at X,Z and drive flat out at the nearest water (within 120 m), the collision off until 3 m past the edge as if the car had jumped it; prints `water test:`, `water: splash at …` and `water: towed after … s …` (where to, how far from a lane, dry or not, the job / rescue / race / wallet), each with its frame. With `--kebab=0` a delivery is running (`tools/verify.sh` step `splash`) |
| `--ram-test` | the driving-feel loop: after 2 s, the car is put 14 m behind the moving traffic car with the longest straight lane ahead, 6 m/s faster, and drives on along that lane (Point, 65 km/h); prints `ram test:` lines: the hit (speed, the rammed car shoved to), then `past it N s after the hit` or `NEVER PAST it after 10 s` (`tools/verify.sh` step `ram`, with `--no-police`) |
| `--first-life` | first scene items 6-7 (2026-11-02): with `--at=` and `--heading=` on the start, after 15 s of play prints `first life: OK (...)` or its problems: walkers on Marszałkowska's busy pavements (6+, the boost on), people at the start's furniture (8+), a tram bell as one passes the car, the square's bed (`tools/verify.sh` step `firstlife`) |
| `--traffic-overlaps` | the traffic loop: the traffic counts the pairs of its cars whose boxes overlap each frame and prints `traffic overlaps:` at the end (car-pair frames, how many on a junction curve, the spots and the worst one, knots given up), then `traffic tram overlaps:` (tram-car frames, with the tram moving, spots, the tram frames standing); use with `--traffic=busy --no-police` and an engine `--quit-after` |
| `--tram-watch=N` | the traffic loop: the car (no collisions, standing still) is kept 30 m ahead of tram N and 20 m to its side, moved on as the tram draws level, so the view and the traffic go with that tram; with `--traffic-overlaps` |
| `--no-police` | loop 3g-1: no police, traps or patrol cars |
| `--police=1\|2\|3` | loop 3g-1: a chase at that level at frame 60, the chaser 40 m behind on your lane (and the blocker / the roadblock for 2 / 3) |
| `--trap=N` | loop 3g-1: start 150 m before speed trap N (1-4 in today's map), heading into it, and make it one of the day's; with `--pedal=gas` the car drives flat out along the road into the radar (through the traffic) |
| `--pullover=routine\|trap\|kebab\|sloik\|generic` | loop 3g-1: open that conversation at frame 60 with a patrol car stopped behind (screenshots; `--clicks` for the replies) |
| `--police-auto=escape\|stop\|hold\|still` | loop 3g-1: in a chase the car drives away flat out on the lane graph (since 2026-11-04 in traffic.gd's racer mode, as a skilled player) / stops at once (with a lizak waving: stops by the officer) / creeps along without escaping (cap tests) / stands without being pulled over (probes) |
| `--police-now` | loop 3g-1: no start grace, no cooldown (tests; with `--autopilot` the car roams at twice the limit: the soak) |
| `--police-log` | loop 3g-1: print every police state change with its frame (`police: …` lines; in a chase the car's place on screen each second, `police: b4 x … y …`) |
| `--police-offence=F:kind,…` | loop 3g-1: an offence at frame F (`speed`, `red`, `oneway`, `bump`, `ram`), seen by the nearest unit (the cooldown test P7) |
| `--escort` | loop 3g-2: with `--mission=N`, the car is put at the rescue's pickup at frame 30 and the person boards; the escort always comes (as on a session's first rescue) |
| `--police-auto=follow` | loop 3g-2: the test driver rides along the escort's route behind it (12-22 m back, through the traffic), the last stretch to the hospital's ring straight (the escort run E1) |
| `--guards[=talk]` | loop 3g-2: start at the south end of Krakowskie Przedmieście's car-free stretch and drive north into the pedestrian zone at 30 km/h (the zone caps it to 20) (with `--zone-cap`: the cap is off by default since 2026-10-30): the whistle, the 3 s run, the guards' car; `=talk` stops by the gate's guards instead (the guard conversation) |
| `--clamp[=sorry]` | loop 3g-2: start parked on Plac Zamkowy by a guard; the clamp's countdown at frame 60, the clamp 10 s later, off after 10 s (`=sorry`: Przepraszam tapped 1 s after it goes on) |
| `--first-contact` | loop 3g-2: arm the scripted first contact at frame 60 as if the first race had just ended (with `--pedal=gas`: drive into the officer; add `--police-auto=stop` to stop by him: the routine check) |

Godot's own `--time-scale 3` (before `--`) speeds a mission or race up for screenshots, and
`--fixed-fps 60` makes runs repeatable frame by frame.

Bench (`godot --path game --disable-vsync -- --bench`, MacBook, 1920×1080, default zoom): 120 fps
with and without traffic (the display's refresh caps it; macOS keeps vsync on), with the
traffic, trams and pedestrians scripts taking about 1.0–1.15 ms a frame for ~45 cars on screen and
~95 driving, by day and by night; the side jobs and easter eggs add 0.03 ms. The Metal driver reports no GPU time; run it on Vulkan to get it
(`godot --path game --rendering-driver vulkan --rendering-method mobile --resolution 1920x1080
--disable-vsync -- --bench --time=night`): the 3D view takes about 1.85 ms on the GPU by day
(1.81 in v0.65 measured the same day), 1.9–2.0 ms at dusk and 1.72 ms at night (1.71 in v0.65)
(M4 Pro; the night has no shadows, which pays for the glow). v0.75's roads cost nothing extra:
the flat layers are now cut into ≤ 10 m pieces instead of fans of slivers, so the city has
6.13 M vertices (6.19 M in v0.65) and builds in ~6 s at runtime (8.9 s), 0.9 s prebuilt.
v0.8's landmarks cost less than the lumps they replace: 6.07 M vertices (6.10 M before, same
day), 0.07 s to build; bench GPU 1.79-1.90 ms by day and 1.70-1.75 at night (1.90 / 1.73 before;
one day run read 3.13, a repeat 1.90 and 1.79), scripts 1.03-1.05 ms, worst frame 9.2-9.5 ms by
day, 9.4-9.8 at night (9.3 / 9.8 before).
v0.9 (same day, Vulkan, before → after): GPU by day 1.86-2.12 → 1.82-1.94 ms, at night 1.69 →
1.73-1.82, at night in the rain 1.82-2.11 (budget +0.6 over the dry night), by day in the rain
1.93-2.07 (the first run of a batch read 3.09-3.66 twice, like the day outliers above); scripts
1.00-1.13 ms as before, plus 0.02 ms for the sound; worst frame 9.2-9.8 ms (9.2-9.8 before);
vertices unchanged at 6.07 M (no new geometry: the river and the rain are shaders and one
texture). Quality Low at night in the rain: GPU 1.81 ms, scripts 0.72 ms (fewer cars and
people). The bench also prints the audio buses' peaks while driving (radio on, mean / loudest
dBFS): Music -18.2 / -11.5, SFX (engine, tyres) -20.0 / -17.4, Ambience -33 by day, -37 at
night, -26 in the rain; Master never above -8 dBFS.

Loop 2a (same session, the code before loop 2a run alongside from an APFS clone of `game/`
with the old scripts; five interleaved runs each, medians; the Mac ran uncapped, 200-300 fps,
with a few runs capped at 144 Hz or disturbed, left out): Vulkan GPU by day 2.27 ms before,
2.24 with the new defaults (80 m, Normal), 2.43 like with like (`--size=110 --traffic=busy
--controls=classic`); at night 2.21 before, 2.01 new, 2.20 like with like (the GPU time is the
3D view's only, so the HUD can't change it; the like-with-like spread is the view's path, as
the lead is smoothed now, and noise: one code's runs spread 2.06-2.90 ms). Scripts (traffic +
trams + people) 0.84 / 0.86 ms before → 0.43 / 0.43 with the new defaults, 0.83 / 0.83 like
with like. Frame (Vulkan) 4.69 / 4.58 ms before → 4.26 / 4.16 new; Metal 3.57 / 3.63 ms
before → 3.34 / 3.31 new, 3.65 / 3.62 like with like. GPU time is n/a on Metal.

Loop 2b (same session, the code before loop 2b run alongside from an APFS clone; three runs
each, interleaved, medians; uncapped; the commands above): Metal frame 3.61 → 1.54 ms by day,
3.58 → 1.56 at night, 3.55 → 1.85 at night in the rain; Vulkan (1920×1080) GPU 2.31 → 0.85,
2.00 → 0.80, 2.11 → 0.87 ms, frame 4.55 → 1.83, 4.32 → 1.64, 4.35 → 1.52 ms; traffic, trams and
people 0.44–0.46 → 0.39–0.45 ms; vertices 6,055,540 either way. The bench now also prints its
`bench detail:` lines (draw calls by pass, the main thread's phases, scripts by system, memory)
and writes them to `user://bench_result.txt`; with `--fixed-fps 60` the route covers the same
ground whatever the frame rate (without it, a faster run drives a shorter way in its 600 frames).

Map data © OpenStreetMap contributors, ODbL.

## The web build (2026-10-30)

The game in a browser at **https://play.aroundwarsaw.app** (aroundwarsaw.app/play/ redirects
there; the landing's "Play online" / "Zagraj online" button links to it). Same game, same
prebuilt city, desktop keyboard and the phone's touch controls as they are.

```zsh
tools/export_web.sh            # derived map files when missing, then the export in build/web
python3 -I tools/web/serve.py  # look at it: http://localhost:8060 (sends the COOP/COEP headers)
tools/export_web.sh --deploy   # also upload it (the user's yes first: it is public)
```

- **Preset "Web"** (`export_presets.cfg`): the iOS preset's file filters, threads on (the sector
  streamer keeps its worker thread), S3TC/BPTC and ETC2/ASTC textures. Godot draws the web with
  the **Compatibility** renderer (WebGL 2) whatever the project's renderer is, so the look is
  close to the phone's, not the same.
- **Threads need cross-origin isolation**: `tools/web/_headers` (copied into the build) sends
  `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
  That is why the game has its own origin and Worker: the landing's CSP and Formspree form
  stay as they are, and the landing's deploys (site/, also from GitHub) never touch the game.
- **Cloudflare's 25 MiB a file**: the pack is ~140 MB and the engine ~40 MB.
  `tools/web/split_parts.py` gzips each and cuts it into 20 MiB parts in `parts/` (names carry
  the contents' hash, so they are cached for a year) with a `<file>.parts.json` manifest;
  `tools/web/split_loader.js`, in the page's head, wraps `fetch` so Godot's loader gets the
  parts joined and unzipped as one file with the right size for its loading bar. The download
  is ~141 MB (the sector scenes barely compress); R2 is not enabled on the account and not needed.
- **The Worker**: `site/play/wrangler.jsonc`, `aroundwarsaw-play`, static assets from
  `build/web`, custom domain `play.aroundwarsaw.app` (wrangler makes the DNS record and the
  certificate on the first deploy).
- **Compatibility renderer fix** (`scripts/instance_buffers.gd`): Godot 4.7.2's gles3
  `scene.glsl` multiplies an instanced mesh's vertex COLOR by the instance colour even in a
  MultiMesh without colours, and `multimesh_set_buffer` leaves the custom data's raw bits in that
  slot, so traffic, pedestrians and the splash came out bright green. On that renderer those
  MultiMeshes carry white colours too and their 16-float buffers are widened to 20 floats when
  sent (traffic, pedestrians, splash); on Mobile (the phones) the helper passes straight through.
- **Sectors on demand** (web loop 2): the 108 sector scenes (96 MB) are not in the web pack.
  `game/tools/pack_sectors.gd` (run by the export script) makes each a pack of its own,
  `sectors/s_<i>_<j>.<hash>.pck` (~0.9 MB), and `res://map/web_sectors.json` lists them with the
  spawn. On the web `scripts/sector_packs.gd` downloads the sectors within the start's 320 m
  (6, ~9 MB) while the title shows, then the streamer asks for each wanted sector's pack (nearest
  first, 3 at a time) and loads it once it is mounted (`ProjectSettings.load_resource_pack`,
  only while the streamer's worker is idle); a sector not in yet shows its proxy. The first
  download is ~59 MB (engine 10, pack 40, start sectors 9) instead of ~141 MB. Other builds
  never see any of it (`SectorPacks.active()` needs the `web` feature and the manifest).
  HTTPRequest on the web reads one network chunk a frame, so a background tab (throttled to
  ~1 fps) loads sectors slowly; in a visible tab the start's six took 0.15-0.3 s locally.
- **The AO and lamp-light maps as zstd streams** (performance lane, 2026-10-30; superseded by
  loop 3d-2b: the maps are per-sector slices inside the sector scenes, so the web's sector packs
  carry them and the `.zst` files and `attach_maps` are gone): they were
  18.8 MB of the pack as RG8 `.res` files (Godot's resource compression works in 4 KB blocks,
  so they barely shrank). The prebuilt city now attaches them when it opens
  (`map_builder.gd` `attach_maps`; `bake_city.gd` `_detach_maps` records which materials read
  each and writes `map/shared/<name>.zst`: u32 width, u32 height, the RG8 texels as one zstd
  stream). Phones and desktops load the `.res` as before; the Web preset leaves the `.res` out
  and carries the `.zst` (8.3 + 2.7 MB), unpacked in ~0.3 s: −7.7 MB in the download and in the
  browser's memory, the texels identical (a desktop run forced to the `.zst` renders
  pixel-identical shots).
- **Phones' browsers** (web loop 2): an iPhone's Safari closed the first version's page (the
  whole 140 MB city in memory). Now a sector's pack file is deleted once its scene is loaded
  (fetched again from the browser's cache if the sector comes back), and Auto picks **Low** on a
  phone's browser (`web_ios`, `web_android` features; main.gd `_load_settings`). The pigeons'
  and the meeting point's crowd were green on the Compatibility renderer too (instance-by-
  instance MultiMeshes): `InstanceBuffers.whiten`.
- **Loading screen**: `tools/web/loading.css` (night colours, a pink bar, the title) and the
  loader's label "Ładujemy miasto · Loading the city, N / 50 MB" from the parts' gzipped sizes.
- **What the browser test covered** (Chrome in the desktop app's browser pane): the title, the
  fly-in, the prebuilt city, traffic colours, keyboard driving (WASD), the touch stick from
  synthetic touch events at 844×390. Web loop 2, with Playwright 1.63 on the Mac
  (`chromium` and `webkit` with the "iPhone 15 Pro landscape" device): the city built 5-6 s
  after opening locally, tap to start, WASD, the sectors streaming as the car moves, the loading
  screen on a throttled 40 Mbit/s link. Not covered: a real phone's browser (iOS Safari's memory
  with a 140 MB pack, the safe area: `OS.has_feature("mobile")` is false on the web), frame rate
  on a weak laptop, Firefox.

### Landmark spec check (LANDMARKS 0.4, 2026-10-31)

`tools/check_spec.py` (verify step `spec`, ~0.1 s, quick too; Python standard library) checks the
specs in `docs/landmarks/specs/*.md` before a build starts: S1 all eight sections of the
model-from-photos skill are present and not empty or TODO/TBD, S2 a detail level (L1-L3) and a
triangle budget are stated, S3 the parts table has the columns id, shape, size, position,
material, feature, at least one row, every cell filled and unique ids, S4 the budget is within
L1 1,500 / L2 3,000 / L3 8,000 unless the spec names an "exception". `--selftest` runs its own
cases (also in the verify step); `check_spec.py FILE.md` checks one file. No spec is checked in yet.
