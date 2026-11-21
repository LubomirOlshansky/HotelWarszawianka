# Graphics options, loading and frame rate: research and plan (2026-11-19)

Research and plan only. No code was changed, nothing was run. Numbers come from
`docs/builds/perf-bisect-2026-11-19.md` unless marked *est.* (my estimate, with the reasoning) or
*unverified* (could not be confirmed from Godot's docs or the code). Code read at the snapshot of
main (2026-11-19).

Contents: 1 where the time goes · 2 options design · 3 loading · 4 fps per bottleneck ·
5 C++ · 6 ranked work items (15) · 7 what Godot offers (research notes) · sources.

---

## 1. Where the frame and the load go

### The frame

| Device, level | fps | What limits it |
| --- | --- | --- |
| Mac M4 Pro, Ultra | 145 | Nothing. But the image is 756x491 (x4, nearest, no AA) on a 3024x1964 screen |
| Mac, Experimental, 3024x1890 full res | 90 day, 116 night, 74-98 flying | Nothing steady; single stalls of 0.5-1.0 s (flying, night rain) |
| iPhone 16 Pro Max, Ultra (x2, 1434x660, 0.95 MP) | 60, 1 % low 48 | The cap |
| iPhone 16 Pro Max, Experimental (x1, 3.79 MP, MSAA 4x, 8K soft shadows) | 37 cool, 30 warm | **Pixels.** The same extras at x2 held 60 (46-55 after a minute of heat). x1 is 4x the pixels of x2 |
| Nothing Phone 1 (Adreno 642L), High | 17.8 | GPU 45 ms **and** CPU 33 ms (scripts 26 + physics 6.5-7) |
| Nothing Phone 1, Medium (x3) | 22.8 | GPU 30.8, scripts 20.6, physics 4.4 |
| Nothing Phone 1, Low (x3, no shadows) | 28.5 | GPU 21.8, scripts 16.3, physics 3.3 |

Three facts to plan against:

1. **Apple devices have headroom at the pixel image, and lose it only at full resolution.** MSAA 4x
   and the 8K soft shadow map are affordable at x2 on the A18 Pro. That fits how tile-based GPUs
   work (MSAA resolves inside the tile). So "more detailed" on Apple is a choice of resolution
   step, not of effects.
2. **The Adreno 642L cannot reach 60 by any setting.** At Low the CPU alone is about 20 ms and the
   GPU 22 ms. A steady 30 is the honest target; today Low is 28.5 uncapped, so even 30 has no
   margin. Both the GPU and the CPU need about 25 % off before 30 is steady.
3. **Triangles per pixel are high.** 0.66 M main-pass triangles go onto 0.29 MP (Low on the Nothing
   Phone), 0.65 MP (High there) or 0.95 MP (iPhone Ultra): 0.7 to 2.2 triangles a pixel, plus as
   many again in the shadow pass. Trees alone were measured at only 2 ms of 45 on the Adreno, so no
   single mesh is the cost; nobody has split the Adreno's 45 ms by pass yet. That split is the first
   job there (section 4A).

Two things I found in the code that the bisect does not name (hypotheses, not measured):

- **`discard` in the three biggest shaders.** `building.gdshader` (lines 1124-1205),
  `ground.gdshader` (340, 346) and `foliage.gdshader` (240) all `discard` for the occlusion ghost
  and the tunnel cutaway. A shader that can discard loses the tile GPU's hidden-surface removal
  (Apple) and early depth write (Adreno) for **every pixel it draws**, not only near the car. The
  project already knows this rule for fence panels (`tiers.gd` `panel_holes`). Walls, ground and
  crowns cover nearly the whole image.
- **The export scripts export with `--headless`** (`tools/export_ios.sh:23`,
  `tools/export_android.sh:71,84`). Godot's shader baker does not run in a headless export, and
  `gpu_quirks.gd building_shader()` builds the Adreno shader from a string at run time, which no
  baker can see.

### The load (launch to "city built", prebuilt city)

| Step | iPhone 16 PM | Nothing Phone | Mac |
| --- | --- | --- | --- |
| Whole load | 7.3-7.8 s | 19.7 s (27.4 s first launch after an install or update) | 7.1-7.5 s |
| of which **places** (`places.gd`, 446k triangles built in GDScript) | 2.3 s | 6.1 s | 2.1 s |
| of which Tamka alone (114k triangles of bollards and plates) | 1.4 s | 3.2 s | 1.2 s |
| First launch after an update (shader and pipeline compile, *est.* cause) | not measured | +7.6 s | |
| Edge roadworks (351k triangles), attached after the first frame | | 1.8 s | |
| NOWA GRA: `reload_current_scene` builds the city again (`main.gd:1219`) | | | +6.6-6.9 s |
| Opening flight | 12 s, with dips to 14-45 fps on the Mac (CPU) | | |

Places is the one new step and it is pure GDScript mesh building of data that never changes: it
belongs in the bake.

---

## 2. Graphics options design

### 2.1 Principles

- **Presets stay the main control**; a short list of individual switches sits under "Więcej ·
  More". Changing any switch shows the preset as "Własne · Custom".
- **A manual choice is the player's.** Nothing steps a manual level down, ever. The governor acts
  only in Auto. On a manual level it only counts, and can raise **one suggestion toast** per
  session.
- **Every option is a field in `tiers.gd`**, tested by `check_tiers.gd`. Features do not test the
  device themselves (the rule in `docs/architecture/graphics.md` section 3).
- **Never** in any level: landmarks, the ghost, the river, the night lights (unchanged).

### 2.2 Presets

Rename Experimental to **Max** and show it to everyone (today it is hidden behind the DEV page,
`settings_panel.gd:323`). Keep `EXPERIMENTAL` as the enum name; `--quality=experimental` keeps
working, add `max`.

| | Low | Medium | High | Ultra | Max |
| --- | --- | --- | --- | --- | --- |
| Image step (2.3) | Coarse | Coarse | Pixel | Pixel | Sharp |
| Budget, MP | 0.5 | 0.5 | 0.96 | 1.6 | none |
| Anti-aliasing | off | off | off | off (MSAA 4x on a Mac) | MSAA 4x |
| Sun shadows | off | 1024 hard | 2048 hard | 4096 hard | 8192 soft |
| Small things cast shadows | no | no | yes | yes | yes |
| Reflection steps | 0 | 6 | 10 | 16 | 16 |
| Glow at night | no | yes | yes | yes | yes |
| Rain density | 0.4 | 0.7 | 1.0 | 1.0 | 1.0 |
| Traffic share / people | 0.55 / 24 | 0.8 / 40 | 1.0 / 60 | 1.0 / 60 | 1.0 / 60 |
| Trees | simple crown, no limbs | simple crown for shadows | full | full | full |
| Fine detail range | 170 m | 170 m | 170 m | 240 m | 240 m |
| Anisotropic filter | default | default | default | default | 16x |

The one real change to a preset: **Max is "Sharp", not "Full"** (x2 where Pixel is x2 on a phone
is the same image, so on the iPhone 16 Pro Max Max becomes x2 + MSAA 4x + 8K soft, the combination
that held 60 on 2026-11-11). Full resolution becomes the top step of its own switch (2.3), for
anyone who wants it and accepts 30-37 fps. That is the bisect's fix 2, "make full resolution its
own switch".

### 2.3 The image step: how render resolution fits the pixel look

Today: each style has its **lines** (Sharp 480); the image is drawn at screen height / k, k a whole
number, and scaled up with nearest filtering (`tiers.gd own_scale`, `image_scale`;
`main.gd _apply_style` sets `view.stretch_shrink`). Keep whole-number scaling: it is what keeps
pixels square. Offer k as named steps, counted from the style's own scale `k0`:

| Step | k | iPhone 16 PM (1320 px tall, k0 = 2) | MacBook 14" (1964 px, k0 = 4) | Nothing Phone 1 (1080 px, k0 = 2) |
| --- | --- | --- | --- | --- |
| Zgrubny · Coarse | k0 + 1 | x3, 440 lines | x5, 393 lines | x3, 360 lines |
| Piksel · Pixel | k0 | x2, 660 lines | x4, 491 lines | x2, 540 lines |
| Ostry · Sharp | max(1, k0 / 2 rounded up) | x1 (same as Full) → shown as x2 kept, see note | x2, 982 lines | x1 |
| Pełny · Full | 1 | x1, 1320 lines | x1, 1964 lines | x1 |

Note: on a phone k0 is already 2, so "Sharp" and "Full" are the same step; the control shows only
the steps that differ on this screen, each labelled with its lines ("660 linii"). The level's
megapixel budget still applies in Auto; a step picked by hand ignores the budget (the player's
choice).

**The Mac needs a different k0, not a different rule.** The iPhone shows 230 image pixels per inch
(460 ppi / 2). The MacBook at x4 shows 63: each image pixel is 3.6 times larger, on a screen held
about 1.7 times further away. Matching the phone's look at the eye is about 135 per inch, which is
x2 on the MacBook. So: lines are a property of the style **and the screen class**: 480 on a phone,
960 on a screen of 11 inches or more (`DisplayServer.screen_get_dpi()` and the screen size give the
diagonal; *unverified* what dpi the iPhone app reports on a Mac, so the Mac detection in 2.6 decides
if dpi is unreliable). On the MacBook that gives x2, 1512x982 = 1.48 MP, inside Ultra's 1.6 MP.

Two look details the implementer must handle, and F must judge:

- **Outline weight.** `post.gdshader` draws outlines one image pixel wide. At a finer step the
  outline gets thinner on screen. Either accept it (finer image, finer line) or sample the depth
  jump at `k0 / k` texels so the line keeps its screen width. Shots of both.
- **A step between x2 and x1** (the iPhone has nothing between 0.95 MP at 60 fps and 3.79 MP at
  37). x1.5 (880 lines, 1.68 MP) would likely hold 60 on the A18 Pro (*est.*: fill-bound, 1.77x
  the pixels of x2, which has headroom). `stretch_shrink` cannot do it; it needs the SubViewport's
  size set by hand and a "sharp bilinear" upscale (nearest inside each pixel, a one-screen-pixel
  blend at its edges), the usual way emulators show pixel art at uneven scales. An experiment, not
  part of the first build.

Godot's own `scaling_3d_scale` / FSR / MetalFX are **not** the tool here: FSR 1 and FSR 2 are
Forward+ only, and smoothing upscalers fight the pixel look (section 7).

### 2.4 Individual switches

Stored as overrides on top of the preset: `settings.gfx := {}` (key → value), saved in
`settings.gd`; `main.gd` reads `Tiers.value(quality, key, overrides)` everywhere it now reads
`QUALITY[quality][key]`. "Przywróć · Reset" clears the overrides.

| Switch (PL · EN) | Values | Applies through | Note |
| --- | --- | --- | --- |
| Ostrość obrazu · Image | the steps of 2.3 | `_apply_style` | The biggest GPU lever in both directions |
| Wygładzanie · Anti-aliasing | Wył. / MSAA 2x / MSAA 4x | `sv.msaa_3d` | Changing MSAA recompiles pipelines (Godot docs): apply while the settings card is open, behind a half-second "applying"; at launch set it before the city loads. No FXAA (it blurs the pixel image). SMAA exists on Mobile since 4.5 and is cheaper than MSAA: try it on Android only if MSAA costs there |
| Cienie · Shadows | Wył. / 1024 / 2048 / 4096 / 8192 | `directional_shadow_atlas_set_size` | Reallocating hitches: fine in settings |
| Miękkie cienie · Soft shadows | Ostre / Miękkie | `directional_soft_shadow_filter_set_quality` | The art bible said hard; F chose soft for Experimental. His call per level |
| Cienie drobiazgów · Small shadows | on / off | `SMALL_CASTERS` group | |
| Odbicia · Reflections | Wył. / 6 / 10 / 16 | `post_mat reflect_steps` | Wet roads only |
| Drzewa · Trees | Proste / Pełne | crown mesh and `limbs` | Needs the simple crown kept as a second mesh (4A) |
| Zasięg detali · Detail distance | Blisko / Normalnie / Daleko | `fine_detail` range (170 / 240 m), streamer radius | |
| Życie miasta · City life | Mniej / Normalnie / Więcej | `_crowd_scale`, `walkers.limit` | Traffic keeps its own existing level in Settings |
| Poświata · Night glow | on / off | `tod.glow_allowed` | |
| Klatki · Frame cap | 30 / 60 / 120 | `_apply_fps` | 120 only where the screen does it. On iOS it needs `allow_high_refresh_rate=true` in the project, and then 60 must come from `Engine.max_fps`, which paced worse on the 16 Pro Max (7.8 % of frames late against 4.6 %, `main.gd:2310`). So: 120 on the Mac and Android first; iPhone 120 is a separate device-gated trial |
| Oszczędzanie baterii · Battery saver | on / off | one switch | = 30 fps, image one step coarser, shadows 1024 hard, no MSAA, city life "Mniej". Replaces today's "30 bateria" wording; the frame cap stays its own row |
| Pilnuj płynności · Keep it smooth | on / off | the governor | On in Auto (and greyed there), **off by default on every manual level** |

Phone screens are small: the Obraz tab keeps today's rows (style, angle, quality, frame cap) and
gets one "Więcej · More" button that opens the switches as a second page, like the DEV page does.

### 2.5 What Auto picks

Pick by **GPU name** first (`RenderingServer.get_video_adapter_name()`, already used by
`gpu_quirks.gd`), by model id where the name is not enough. One table, `tiers.gd for_device(model,
adapter, os)`, replacing `for_model`.

| Device | Auto | Why |
| --- | --- | --- |
| iPhone 8 / X (`iPhone10,x`, A11) | Low | as today |
| iPhone XS / XR (`iPhone11,x`, A12) | Medium | as today |
| iPhone 11 to 15, SE 2 / 3, 16e (A13-A16, A18 4-core) | High, sharp/fallback rule | as today (measured on the 11) |
| iPhone 15 Pro and newer (A17 Pro, A18, A19) | Ultra | measured: 60 fps. Max stays a manual choice |
| iPad | by chip from the adapter name: A12 Medium, A13-A16 High, A17 / M-series Ultra | *est.*, none measured; today every iPad gets High |
| Mac (the iPhone app on Apple silicon, or a macOS build) | Ultra effects + lines 960 (x2 on the MacBook) + MSAA 4x | measured: 145 fps at Ultra x4, 90 at full res with everything. *est.* 110-130 at x2 + MSAA 4x |
| Android, Adreno 5xx / 6xx (`GpuQuirks.is_old_adreno`) | **Low + 30 fps cap** | measured: High 17.8, Low 28.5 |
| Android, Adreno 7xx | High | *est.* (730 is about 2x the 642L, 740/750 3-4x); the governor guards |
| Android, Adreno 8xx | Ultra | *est.* |
| Android, Mali-G5x/G6x/G7x below G710, PowerVR, unknown | Medium + 30 cap | *est.*; unknown names start safe |
| Android, Mali-G710 and up, Immortalis, Xclipse | High | *est.* |

Only one Android phone is measured. For the rest Auto needs a way up as well as down: reuse the
G1b machinery (`tiers.gd sharp_*`): a session that was calm for 3 minutes with the cap at 30 and
under 1 % missed refreshes tries the next level on the next launch, on trial, with the same doubling
wait when it fails. That makes the table a starting guess, not a verdict.

### 2.6 Detecting the iPhone app on a Mac

There is no Godot API for it. Apple's is `ProcessInfo.isiOSAppOnMac` (iOS 14+). Options, cheapest
first:

1. **Model id** (*unverified*, one look settles it): Godot's iOS `OS.get_model_name()` reads the
   machine id, which on a Mac should not start with `iPhone`, `iPad` or `iPod`. Rule:
   `OS.get_name() == "iOS"` and the model id is none of those three → a Mac. F can read the id on
   his Mac today: Settings → the device line of the report (`main.gd:1176`, `2335`).
2. **Adapter name** as a cross-check: "Apple M…" (but an iPad Pro is also an M chip, so not alone).
3. **Native call**: `isiOSAppOnMac` in the small iOS plugin already planned for haptics and
   `thermalState` (`docs/design/graphics.md` 4.4). Exact, but needs the plugin.

Use 1 + 2 now, 3 when the plugin exists. A native macOS export preset is a separate decision (it
gives a resizable window, real 120 Hz, keyboard defaults); the options design is the same either way.
On a Mac the window can be resized: `_apply_style` is already connected to `size_changed`
(`main.gd:1804`).

### 2.7 The governor

Today (`main.gd _govern`, `_experimental_drop`): the governor runs on every level; on Experimental
its first GPU drop sets Ultra for the session. One 0.5-1 s stall is enough to trigger it (5 % of a
3-second window), which is what F saw.

New behaviour:

| Choice | Governor | What can change by itself |
| --- | --- | --- |
| Auto | **acts**, as today | extras (reflection steps, small shadows, traffic, people); the image through the sharp/fallback rule between launches |
| Any manual level, "Keep it smooth" off (default) | **advises**: counts, changes nothing | nothing |
| Any manual level, "Keep it smooth" on | acts on extras only | extras; never the level, the image, MSAA or shadows |

Advise mode, concretely:

- `governor.gd`: add `mode` (ACT, ADVISE). In ADVISE `tick()` computes the same drop decision but
  returns no change; it keeps *virtual* levels so the existing tally (`gpu_down_s`, `bad_minutes`,
  `struggled()`) still works. `track` becomes true for manual levels too.
- **The suggestion**: when `struggled()` latches (60 s of virtual GPU drop making up 10 % of play,
  or 3 minutes in a row over 2 % missed), show once: "Obraz Max jest za ciężki na ten telefon
  (31 kl./s). Zmienić na Ultra?" with **Zmień** and **Zostaw**. Never during the opening, a load,
  the title, a wide view or flying (the tally already skips those). "Zostaw" is remembered per
  level (`settings.gfx_advice[level] = true`): no second toast on that level, ever, until the
  player changes level. A stall cannot trigger it: `struggled()` needs a minute.
- Delete `_experimental_drop` and its call in `_govern`.
- **Save Max like any level.** It is not saved today because a phone that crashes on the 8192
  shadow map would be locked out (`_set_quality` comment). Replace that with a boot guard: write
  `gfx_pending = true` before applying a level's heavy parts, clear it after 10 s of drawn frames;
  a launch that finds it still set falls back to the last good level once and says so. That covers
  a crash without refusing to remember the choice.
- Heat: no change on a manual level either. When the iOS plugin can read `thermalState`, "serious"
  may raise the same one suggestion (battery saver), nothing more.

---

## 3. Loading plan

Targets: iPhone 16 Pro Max 7.5 → **≤ 5.2 s**; Nothing Phone 19.7 → **≤ 13.5 s** (first launch
27.4 → ≤ 18 s); Mac 7.3 → ≤ 5.2 s; NOWA GRA +6.8 → **≤ 1 s**.

### 3.1 Bake the places into the prebuilt sectors (the big one)

`places.gd` already merges every place's dressing into one mesh per 512 m sector and shadow setting
(`places_<cx>_<cz>`, 87 meshes). That is exactly a sector's shape.

- `game/tools/bake_city.gd`: after the city is built, run `places.build`, and save each
  `places_<cx>_<cz>` mesh into that sector's resource (or a `places` resource beside it, loaded by
  `sector_streamer.gd` with the sector). The meshes then arrive with the sector, on the streamer's
  worker thread, instead of being generated at launch.
- Split every place script (`place.gd`) into **dressing** (what it pours: static, bakeable) and
  **live** (its own parts, movers, colliders, signals: 5 own parts in all). On the prebuilt path
  only `live()` runs. The cost is generating the meshes, not merging them, so skipping `_merge`
  alone would save nothing. Start with the three that hold 85 % of the triangles: `tamka.gd`
  (138k), `park_details.gd` (142k), `street_details.gd` (96k).
- **Tamka's bollards and plates as MultiMeshes** (one post mesh, N instances per sector): 114k
  triangles of repeated geometry become a few kB of transforms. Costs one draw call (plus one in
  the shadow pass if they cast) per sector in view: bench it against the ceiling (165 at the spawn).
- Both city paths: the runtime path keeps building at load (it is the dev path). `check_places.gd`
  gets a row comparing triangle counts and AABBs of the baked meshes with the runtime ones.
- Colliders the places build must still be made at load or baked with the sector's collider.

Gain (measured cost of the step): **-2.3 s iPhone, -6.1 s Nothing Phone, -2.1 s Mac**. Risk to the
look: none if the check holds. Effort: medium (15 scripts, but mechanical after the first three).

### 3.2 Edge roadworks (351k triangles, 1.8 s after the first frame on the Nothing Phone)

`edge_roadworks.gd` already uses `WorkerThreadPool`. It cannot be fully baked: placement depends
on the day (`--barriers=YYYYMMDD`) and the boards carry words (rebuilt on a language change). So:
bake the **parts** (barrier, board blank, cone) as shared meshes and place them as MultiMeshes per
sector when the sector streams in; text as one small mesh per board. That also removes one suspect
for the stalls (4E).

### 3.3 Threading: what is safe in Godot

- Safe on a worker (`WorkerThreadPool`, `Thread`): reading data, building `PackedVector3Array`
  and the other arrays of a mesh, `ResourceLoader.load_threaded_request` of a baked resource.
- Main thread only: adding nodes to the tree. Creating the GPU buffers happens in the render server
  when the mesh is first made or used: the skill notes 25-60 ms per sector on the iPhone 11 for
  that. The fix there is size, not threads: **smaller sector resources, one piece a frame** (loop
  3d-2b did this for colliders on the Mac: 23.8 → 13.0 ms).
- Rule for anything still built at load: compute arrays on workers in parallel (the places that
  stay runtime, the roadworks), make the mesh and the node on the main thread, one per frame under
  the title (`LoadYield`).

### 3.4 First launch after an update: the shader baker and pipeline warm-up

Two different things (Godot docs, "Reducing stutter from shader (pipeline) compilations"):

- **Shader baker** (export option, Godot 4.5+): compiles shader source to the driver's format at
  export, so the first launch does not. Supported for Metal and Vulkan when exporting from macOS.
  Off by default. Not supported in a `--headless` export. To use it:
  1. turn on "Shader Baker > Enabled" in both presets of `game/export_presets.cfg`;
  2. change the export step in `tools/export_ios.sh` and `tools/export_android.sh` to run with a
     renderer (the scripts already do this for the city bake);
  3. make the Adreno "lite" building shader a real file (`building_lite.gdshader` that includes
     the shared code with `#define BUILDING_LITE`) instead of a string built in
     `gpu_quirks.gd building_shader()`; `check_shader_budget.gd` then reads the file.
  Gain: *est.* 2-4 s of the Nothing Phone's +7.6 s; the docs say the win is largest on Metal and
  D3D12 (their demo loaded 20x faster) and do not give a Vulkan number. The iPhone's first-launch
  time has not been measured: measure it before and after.
- **Pipeline precompilation** (ubershaders, since 4.4, Forward+ and Mobile): Godot compiles the
  pipelines for what it sees **during loading**. Anything first shown mid-game compiles then, as a
  hitch. Here that is: rain, the wet-road post path, night glow and neon, the helicopter, the LED
  screen, event fog, fence panels, and any MSAA change. Fix: a **warm-up** under the title: one
  small instance of each of those materials inside the 3D SubViewport for a frame, with the saved
  MSAA already set. Godot's debugger has monitors that count pipeline compilations by cause
  (canvas, mesh, surface, draw, specialization); log them in the bench (4E).

### 3.5 NOWA GRA builds the city twice

`_on_new_game` → `reload_current_scene` (`main.gd:1219`) frees and rebuilds everything. Keep the
static city across the reload: before reloading, move the map node, the streamer's loaded sectors
and "Places" to a small autoload ("CityKeeper"); `_build_world` adopts them when present instead of
building. Gain: about -6.5 s (the whole city build). Risk: systems that keep references to the old
map or signals into freed objects; needs `verify.sh` and an autopilot run of NOWA GRA → first
mission. Effort: medium.

### 3.6 The opening flight

12 s (7.5 before #911), dips to 14-45 fps on the Mac, CPU-bound.

- Load the sectors along the flight's path **before** it starts (the path is fixed:
  `docs/design/opening-flyover.md`), so it streams nothing while flying.
- Start traffic, people and the other spawners in stages after the flight, not during it.
- Hold the governor during the flight (it is held under the title only today).
- Whether it goes back toward 7.5 s is F's call (pace against the music).

### 3.7 Find the next step

After places, nobody knows the order of the rest. Add `--load-log`: one table of every `LoadYield`
step with its milliseconds, sorted, printed at "city built". Known candidate: `map/index.res`
(103 MB of static memory at "city built", archive "Where the memory goes").

### 3.8 Lazy activities, on top of TD-4 (b)

TD-4 (b) gave each activity its own `install(ctx)` / `setup_in(ctx)` / `joined(ctx)`
(`activity.gd:211-228`; `main.gd _install`, `_add`, `_join`, lines 3700-3725; 6 of 12 merged). The
per-commit benches show it changed neither the frame nor the load, as expected: every activity is
still installed, set up and joined at launch, in a fixed order, and its `_process` runs every frame
from then on. The hook is what makes a saving possible: build and start an activity only when the
player is near its place or its quest is active.

What there is to save (not measured per activity yet; `--load-log`, 3.7, and the bench's
per-system lines give the numbers before anyone builds this):

- **Load**: each activity's `setup(world)` (nodes, meshes, MultiMeshes, data parsing). The archive
  puts the side jobs at 17 MB of static memory at the spawn (rides 7.5, jobs and eggs 4.8 each),
  a sign of real setup work.
- **CPU**: one `_process` per activity every frame while idle (`activity.gd:321` → `_idle_tick`),
  plus `_physics_process` in `rides.gd` and `jobs.gd`. On the Nothing Phone this is part of the
  7.5 ms "game loop" and of lines like `jobs+eggs`, `rides physics`, `meet`. *Est.* 1-2 ms there,
  tenths of a millisecond on Apple.

Design: split each activity into a **light** half and a **heavy** half.

- Light (always there, costs nothing a frame): its place in the director's order, its call clock,
  what the save says about it, its test for "wanted now". Ticked by the director at 2-4 Hz, not by
  its own `_process`.
- Heavy (`setup_in`: world nodes, meshes, actors, per-frame work): built when wanted, over a few
  frames through `LoadYield`, and switched off again (`set_process(false)`, hidden, bodies off;
  not freed) some time after it stops being wanted.
- "Wanted" = the player within its range of one of its places (range > the streamer's radius, so
  it is ready before it is seen), **or** its quest is the active or next one in the quest book,
  **or** its call is due within about 30 s, **or** a test flag starts it.

What this needs from TD-4:

1. **All 12 activities on the kit's install** (6 are). A lazy director with half the activities
   still hand-wired in main.gd would need two paths.
2. **A context that outlives the build.** Today `install` "does not keep `ctx`, so it sees only
   what existed at its place in the build" (`activity.gd:209`). A late install must see the same
   services whenever it runs: `GameCtx` becomes complete and stable once the build ends (main.gd
   already keeps `_ctx`), and `install` may be called at any time after that.
3. **The join without the setup.** The order of the joins is the director's order (M and K, the
   ✕, the arrow, the stop assist ask the first one first: `main.gd:3713`). `activities.add` must
   accept an activity that is installed but not set up, so the order stays fixed while the heavy
   half comes later. `_install` splits into "install + add" at launch and "setup_in" on demand.
4. **Each activity declares where and when** (two small overrides on `activity.gd`): `places()`
   (points and a range, or none for "anywhere") and `wanted(ctx)` for rules of its own. And a
   split of `setup` where one script does both: the call clock and save state in the light half,
   everything that touches the world in the heavy one.
5. **`joined`'s test starts keep working**: a test flag (`--meet-at=`, `--crawl=`) forces the heavy
   half at the join, so the checks and autopilot runs behave as today.
6. **Cross-references guarded.** Other systems hold activities directly (police.gd reads
   missions' State; rivals waits for another activity's request card): they must ask the director
   and accept "not built yet". Missions (the rescue line) and anything with a city-wide presence
   (rides, the kebab job, rivals) stay eager; the lazy set is the place-bound ones (tour, bar
   crawl, shisha, rave, street meet, boat race, the Leżak round-up, the EV tow).

Risk: an activity that is not there when its call should ring, or that pops in beside the player.
The check: an autopilot run of every activity from a cold start and from a save in the middle of
its quest, plus a new `check_lazy_activities.gd` that asserts each one is built before its range
edge is on screen.

---

## 4. FPS plan, per bottleneck

### 4A. GPU on the Adreno 642L (45 ms at High, 22 ms at Low)

| # | Change | Godot feature | Expected gain | Risk to the look | Effort |
| --- | --- | --- | --- | --- | --- |
| A1 | Auto picks Low + 30 cap on Adreno 5xx/6xx | `tiers.gd for_device` | 17.8 → 28.5 fps at once (measured) | It is Low: no sun shadows, no glow. F judges whether Low is acceptable as this phone's face, or whether "Low + 1024 shadows" (Medium's 30.8 ms GPU) is worth 22 fps | small |
| A2 | **Split the 45 ms by pass before cutting anything** | `--exp=` switches in side-by-side APKs (the bisect's recipe), or Android GPU Inspector | none itself; decides A3-A6 | none | small |
| A3 | Ghost-free shader variants: tiles further than the ghost radius from the car use a copy of `building` / `ground` / `foliage` without `discard` | a second material per shader, swapped per 128 m tile | *est.* 10-25 % of fill where buildings overlap (hypothesis: early depth and hidden-surface removal come back for most of the screen). Test first with an `--exp=nodiscard` switch | none if the swap radius covers the ghost; a pop if it does not | medium; the building shader is at the Adreno budget (503 / 505) but this removes branches |
| A4 | Shadow pass draws simpler meshes | `ArrayMesh.shadow_mesh` (a separate mesh for the shadow pass): the 20-face crown for tree shadows; no small casters below High (already) | shadow pass is half the triangles (0.65 M of 1.31 M). Trees are a quarter of each pass: about -12 % triangles overall; measured value of the whole tree change on the Adreno was 2 ms, so *est.* 1 ms here, more at full res with MSAA on the iPhone | shadow outlines of trees slightly rounder; invisible at 2048 | small |
| A5 | Simple crowns (20 faces, no limbs) in the main pass at Low and Medium | swap the trees' MultiMesh mesh by tier | measured: 2 ms of 45 at High | trees look as they did before #857 on Low/Medium only | small |
| A6 | Post pass cost: `post.gdshader` reads the screen and depth textures (a copy of the frame on a tile GPU) and loops `reflect_steps` | measure with `--exp`; on Low keep reflections 0 (already) | unknown until A2 | none | measure only |

Mesh LOD (Godot's automatic LOD) is **not** the answer for this city: the city meshes are built in
code as `ArrayMesh` (no LODs unless generated with `ImporterMesh.generate_lods()` at bake), they
are merged tiles of boxes (little to simplify), and the camera is orthographic, so every object has
the same size on screen: a LOD threshold would switch the whole city at once. Per-tier meshes (A4,
A5) do the same job on purpose. Occlusion culling likewise: a 30-50° view from above has few
occluders, and it costs CPU, which this phone lacks most.

Target: Low uncapped **28.5 → ≥ 36 fps** (so the 30 cap holds with 1 % low ≥ 27); High
**17.8 → ≥ 22** (above 2026-11-11's 20.2).

### 4B. iPhone at full resolution (37 fps cool, 30 warm)

| # | Change | Expected | Risk | Effort |
| --- | --- | --- | --- | --- |
| B1 | Max = x2 + MSAA 4x + 8K soft; Full res a separate step (2.2, 2.3) | 60 cool (measured 2026-11-11), 46-55 after a minute of heat | Max is less sharp than today's Experimental; Full is one tap away | small |
| B2 | A3 (ghost-free variants) and A4 (shadow meshes) | *est.* x1: 37 → 42-48. With MSAA 4x every hidden pixel saved counts four samples | as above | shared with 4A |
| B3 | 8K soft shadows → 4096 soft at x2 as an option | 8192 is 4x the shadow texels of 4096; *est.* 1-2 ms | F compares shots: 0.09 m against 0.18 m texels | small |
| B4 | x1.5 step with sharp-bilinear upscale (2.3) | *est.* 60 fps at 880 lines | the pixels are no longer exactly square; F judges | medium, experiment |
| B5 | Heat: a 5-minute soak for whatever becomes Max, not a 10-second bench | | | device run |

Ultra must not move: 60 fps, 1 % low ≥ 48.

### 4C. CPU scripts (26 ms on the Nothing Phone; fine on Apple)

Measured there: game loop 7.5 ms, traffic 5.2, trams 2.5, people 1.9, hud + minimap 1.7, crazy
drivers 0.6-1.1, traffic bodies 0.8-1.1, `eggs+tape+spacer` 1.9 in a played save.

| # | Change | Expected | Risk | Effort |
| --- | --- | --- | --- | --- |
| C1 | **The game loop (7.5 ms)**: `main.gd _process` calls dozens of `_x_frame()` every frame. Give each a rate: every frame (input, camera, car), 30 Hz, 10 Hz, 2 Hz; spread the slow ones over different frames | *est.* -3 to -4 ms | a late hint or offer by 1-5 frames: invisible | medium; `--bench` per-call timing first |
| C2 | Traffic by distance: cars near the player every frame; mid-range every 2nd; far or off screen every 4th, moved between updates by their speed (physics interpolation is already on project-wide) | *est.* -2 to -3 ms of 5.2 | far cars slightly late at lights; check with the lane checks | medium |
| C3 | Trams, people, crazy drivers: the same rule | *est.* -2 ms of 5.5 | as C2 | small each |
| C4 | HUD and minimap redraw at 20-30 Hz, only when something changed | *est.* -1 ms of 1.7 | minimap arrow less smooth: keep the arrow every frame | small |
| C5 | `eggs+tape+spacer` 1.9 ms in a played save against 0.03 fresh: it scales with the save. Find the loop over collected things | -1.8 ms for long-time players | none | small, root cause |
| C6 | Low and Medium: `Governor.TRAFFIC`-style shares already cut counts; make the **update rates** tier fields too | | | with C2 |

Target on the Nothing Phone at Low: scripts **16.3 → ≤ 11 ms**; at High **26.2 → ≤ 18 ms**. On the
Mac "scripts, all systems" stays ≤ 1.3 ms (the budget).

### 4D. Physics (6.5-7.1 ms on the Nothing Phone, 4.8 on 2026-11-11)

The rise came from smashable fences on by default (#892) and the cars' bodies (#893).

| # | Change | Expected | Risk | Effort |
| --- | --- | --- | --- | --- |
| D1 | Fences and hedges (`soft_things.gd`): a body only within about 60 m of the player, from a pool; the rest have none | *est.* back toward 4.8 ms | none if the radius beats the car's speed | small |
| D2 | Traffic bodies (`traffic.gd` `AnimatableBody3D`): bodies only for cars near the player; the others are positions only | *est.* -1 ms, and less in "traffic bodies" script time | far cars cannot be hit by other physics things: nothing else is there | small |
| D3 | **Jolt trial**: `physics/3d/physics_engine = "Jolt Physics"` | built in since 4.4, the default for new projects since 4.6; this project has no setting, so it runs GodotPhysics3D. Godot calls Jolt "generally faster"; no trustworthy number: A/B on the phone | **driving feel**: the car is a `CharacterBody3D`; `move_and_slide` behaves a little differently. Area-against-static overlaps are off by default in Jolt. `check_steering.gd`, the collision checks and F's hands decide | small to try, medium to accept |
| D4 | Collision layers: make sure static things never test against static things, sleeping allowed on everything that rests | small | none | small |

Target: physics **6.5 → ≤ 4 ms** at High on the Nothing Phone.

### 4E. The 0.5-1 s stalls (Mac: flying, night rain) and the opening dips

Not fps, but they are what F feels, and they cost Experimental its level today.

- Add `--stall-log`: for every frame over 100 ms print what happened in it: the pipeline
  compilation counters (Godot's monitors), the streamer's state (`--stream-log`), roadworks and
  places tasks, which `_x_frame` took longest.
- Suspects, in order: (1) pipeline compiles on first use: night rain is the first time rain, wet
  reflections and night lights are all on screen (fix: 3.4 warm-up); (2) a sector's GPU buffers
  created in one frame while flying (fix: smaller pieces, one a frame); (3) the edge roadworks
  attached at once (fix: 3.2).
- Target: no frame over 100 ms in the bench's flying and night-rain runs on the Mac (today 518-1,010 ms).

---

## 5. C++ / GDExtension: recommendation

**Do not port anything now.** Reasons, from the numbers:

- On the Mac the scripts cost about 1-2 ms; the iPhones hold 60. Only the mid-range Android phone
  is CPU-bound, and there the GPU is the larger problem (45 ms): with scripts at zero it would
  still run at 22 fps.
- The cheap GDScript fixes are not done yet (4C): update rates and distance tiers typically take a
  third to a half off, at no build cost.
- The cost of a GDExtension is permanent: a C++ toolchain per platform (an iOS xcframework, an
  Android `.so` per ABI, a macOS library for the editor), godot-cpp pinned to the engine version
  and rebuilt on every Godot update, a second language in a codebase where `traffic.gd` (5,072
  lines) changes weekly, and cloud sessions that cannot build the iOS library. godot-rust has the
  same costs plus Rust.
- C++ helps **pure computation in tight loops**. Code that mostly calls engine functions gains
  little (one forum measurement: 1.4 s → 1.3 s). Community numbers for pure math run from 10x up,
  but none are rigorous (*unverified*).

**When it would pay off**, and what to port then: after 4C and 4D are done, if F decides mid-range
Android must reach 60 and traffic + people + trams still cost over about 4 ms there. Then port
only narrow kernels with data in, data out, no nodes:

1. the traffic step: per car, lane following, the gap to the car ahead, signals; state in packed
   arrays, one `step(dt)` call that returns the transforms buffer for the MultiMesh;
2. the pedestrians' position update, same shape;
3. the minimap's geometry if it shows up.

Keep the rules and the content (who drives where, missions, jokes) in GDScript. Prepare for it now
at no cost: when doing C2, keep traffic's per-car state in packed arrays rather than objects; that
is faster in GDScript too and makes a later port a file, not a rewrite.

"C++ for free" comes first: work Godot already does in C++: MultiMesh instead of nodes, one
`multimesh.buffer` write instead of per-instance calls (`instance_buffers.gd` does this), physics
interpolation instead of per-frame moves, `PhysicsServer3D` bodies without nodes, Jolt.

---

## 6. Ranked work items (one thread each)

Each is full definition of done (verify, shots, bench, `--ios`) unless marked light. Device runs
need F's yes for the loop.

| # | Item | Lane | Model | Acceptance (numbers to beat) | F judges by eye |
| --- | --- | --- | --- | --- | --- |
| 1 | **Manual levels are never stepped down**: governor ADVISE mode, one suggestion toast, delete `_experimental_drop`, save Max with the boot guard (2.7). `governor.gd`, `main.gd _govern` / `_set_quality`, `settings.gd`, `check_tiers.gd` | performance | Opus | Mac `--quality=experimental --governor=log`, 3-minute drive with a flight and night rain: level never changes; a forced 1 s stall raises no toast; a forced steady 30 fps raises exactly one. Ultra bench unchanged (Mac 145, iPhone 60) | the toast's wording and timing |
| 2 | **Places out of the load**: bake into prebuilt sectors, dressing / live split, Tamka as MultiMeshes (3.1). `bake_city.gd`, `places.gd`, `place.gd`, `tamka.gd`, `park_details.gd`, `street_details.gd`, `sector_streamer.gd`, `check_places.gd` | map | Opus | "city built": iPhone ≤ 5.5 s (7.3-7.8), Nothing Phone ≤ 14 s (19.7), Mac ≤ 5.2 s; draw calls at the spawn ≤ 165; triangle counts equal on both city paths | Tamka, Patelnia and a park, before / after shots, both paths |
| 3 | **The Mac picture**: screen class lines (960 on big screens), Mac detection (2.6), MSAA 4x at Ultra on a Mac. `tiers.gd`, `main.gd _apply_style` / `_apply_experimental` | visuals | Opus | MacBook: image 1512x982 at Auto; ≥ 100 fps on the bench at 3024x1964 (145 today at x4, 90 at full res); the iPhone's image unchanged (1434x660) | **the look at x2 with MSAA against x4**; outline weight (two variants) |
| 4 | **Android Auto**: `for_device` by GPU name, Adreno 5xx/6xx → Low + 30 cap; the way up on calm sessions (2.5). `tiers.gd`, `gpu_quirks.gd`, `check_tiers.gd` | performance | Sonnet (a table and a check; Opus if the trial rule is included) | Nothing Phone at Auto: 30 fps capped, fewer than 5 % missed refreshes on the bench route (17.8 fps today) | whether Low is an acceptable face for that phone |
| 5 | **Options: Max preset and the switches** (2.2-2.4): `Tiers.value` with overrides, the "Więcej" page, Custom, Reset, battery saver, frame cap 120 on the Mac and Android. `tiers.gd`, `settings.gd`, `settings_panel.gd`, `main.gd` | performance + UI | Opus for `tiers`/`main`, Sonnet for the panel and the PL/EN text (warsaw-tone) | every preset renders the same as before with no overrides (shots equal); iPhone Max (x2, MSAA 4x, 8K soft): 60 cool, ≥ 55 after 5 minutes; Full step ≥ 37; `check_tiers` covers every key | the page's layout on the phone; names of the steps |
| 6 | **Stall log and warm-up** (3.4, 4E): `--stall-log`, pipeline monitors in the bench, warm-up of rain / night / heli / event materials under the title | performance | Opus (root cause) | Mac bench flying and night rain: no frame over 100 ms (518-1,010 ms today); opening flight ≥ 50 fps throughout on the Mac | none (it is smoothness) |
| 7 | **Adreno GPU split, then the shader variants** (4A A2, A3, A6): `--exp=nodiscard` and per-pass switches; if it pays, ghost-free variants of `building` / `ground` / `foliage` | performance | Opus | a table of the 45 ms by pass; if A3 ships: Nothing Phone High GPU ≤ 38 ms (45), iPhone Full step ≥ 42 fps (37); `check_shader_budget` green | the ghost round the car and the tunnel cutaway unchanged, driving shots |
| 8 | **Script rates** (4C C1-C6) | performance | Opus | Nothing Phone High: scripts ≤ 18 ms (26.2); Low ≤ 11 (16.3); Mac scripts ≤ 1.3 ms; lane and steering checks green | traffic at junctions at mid distance; the minimap arrow |
| 9 | **Tree and shadow meshes by tier** (4A A4, A5): `shadow_mesh` for crowns, simple crown at Low / Medium | visuals | Sonnet to apply, Opus accepts | shadow-pass triangles at the spawn ≤ 0.55 M (0.65-0.71); Nothing Phone Low uncapped ≥ 32 with item 8 → ≥ 36 | tree shadows at High; trees at Low |
| 10 | **Physics** (4D D1, D2, D4), then the **Jolt trial** (D3) as its own thread | driving | Opus (feel) | Nothing Phone High physics ≤ 4 ms (6.5-7.1); Jolt only if `check_steering` passes and F accepts the feel | **the car's feel**, fence smashes |
| 11 | **Shader baker** (3.4): presets, non-headless export step, the lite shader as a file | store / performance | Sonnet, Opus if the Adreno shader breaks | first launch after install on the Nothing Phone ≤ 22 s before item 2, ≤ 18 s with it (27.4); the city draws on the Adreno (no pipeline errors in logcat); export size growth named | none |
| 12 | **NOWA GRA keeps the city** (3.5) | gameplay | Opus | NOWA GRA to play on the Mac ≤ 1 s over a normal start (+6.6-6.9 s); autopilot NOWA GRA → first mission green | none |
| 13 | **Edge roadworks as parts** (3.2) and `--load-log` (3.7) | map | Opus | nothing over 33 ms attached after the first frame (1.8 s on the Nothing Phone) | the boards' text in both languages |
| 14 | Experiments, each a short thread with shots for F: x1.5 sharp-bilinear step (B4); 4096 soft against 8192 soft (B3); 120 Hz on the iPhone; Auto with MSAA 2x on A18 Pro and newer (20-minute soak) | visuals / performance | Opus | per experiment | all of them are his call |
| 15 | **Lazy activities** (3.8), after TD-4 (b) has all 12 on the kit: light / heavy split, the director builds an activity when the player is near or its quest is active. First `--load-log` and the bench's per-activity lines, to see what there is to win | gameplay / architecture | Opus | "city built" down by the sum of the lazy activities' setup times from `--load-log` (set the number then); Nothing Phone "game loop" + activity lines ≥ 1 ms lower at the spawn; every activity's autopilot run green from a cold start and from a mid-quest save | none if it works: no activity may pop in on screen |

Order rationale: 1 fixes what F reported and is small; 2 is the largest measured gain; 3 and 4
change what two devices show at first launch; 5 builds on 1 and 3; 6-10 are the frame work, each
measured before it is cut; 11-13 finish the load; 15 waits for TD-4 (b) to finish and for
`--load-log` to show its size (the TD-4 benches say the hook alone saves nothing). Items 1, 2, 3, 4 touch different files and can
run side by side (lanes: performance, map, visuals; 4 waits for 1 if both edit `tiers.gd`).

What only a phone can show: everything in the acceptance column that names the iPhone or the
Nothing Phone; heat after 5 minutes; the first launch after an install.

---

## 7. What Godot offers: research notes (4.4 to 4.7)

| Feature | Status for this game | Verified |
| --- | --- | --- |
| **MSAA** | Available in every renderer, Mobile included. Docs: 2x "may be usable", higher "unlikely to run smoothly on mobile GPUs" (a general note; the A18 Pro held 4x at x2). Changing MSAA at run time recompiles pipelines; different MSAA on different viewports stutters | docs 4.7 |
| **FXAA, SMAA** | Both work on Mobile (SMAA since 4.5). FXAA blurs, worst at low resolution: wrong for a 480-660 line pixel image. SMAA is sharper and cheap: an Android fallback if MSAA costs there | docs 4.7 |
| **TAA, FSR 2** | Forward+ only. Not available | docs 4.7 |
| **FSR 1 upscaling** | Forward+ only according to the 4.7 "Resolution scaling" page; Mobile falls back to bilinear | docs 4.7 |
| **MetalFX spatial / temporal** | `Viewport.SCALING_3D_MODE_METALFX_SPATIAL/TEMPORAL` exist (since 4.4), Metal only (macOS, iOS). Whether the **Mobile** renderer supports them is not stated in the class docs. Either way a smoothing upscaler is against the pixel look; only of interest for a future "smooth" style | exists: docs 4.7; on Mobile: *unverified* |
| **`scaling_3d_scale`** | Bilinear in every renderer. Not used: the game scales with `SubViewportContainer.stretch_shrink` and nearest filtering, which is right for whole-pixel art | docs 4.7, code |
| **Ubershaders and pipeline precompilation** | Since 4.4, Forward+ and Mobile: pipelines for what is seen during loading are compiled then; optimized variants compile in the background. First use mid-game still hitches. 2D has no precompilation | docs 4.7 |
| **Shader baker** | Export option since 4.5; bakes source to the driver's format; cuts first-launch load, "generally will not resolve existing stutters"; Metal and Vulkan from a macOS editor; not with `--headless`, not Compatibility | docs 4.7 |
| **Pipeline monitors** | Debugger monitors count pipeline compilations by cause | docs 4.7 |
| **Mesh LOD** (automatic) | Works for imported meshes; code-built `ArrayMesh` needs `ImporterMesh.generate_lods()`. `Viewport.mesh_lod_threshold` (Experimental sets 0 = off). Poor fit: merged box tiles, orthographic camera (4A) | docs 4.7; the orthographic behaviour is my reasoning, *unverified* |
| **Visibility ranges (HLOD)** | In use (`sector_proxies.gd`, `fine_detail`). `decisions.md` already records why distance from an orthographic camera 500 m back is a weak signal | code |
| **`ArrayMesh.shadow_mesh`** | A separate, simpler mesh for the shadow pass. Not used yet; a direct fit for tree crowns | engine API from memory, *unverified against 4.7 docs* |
| **Occlusion culling** (`OccluderInstance3D`) | Works in Mobile; software rasterisation on the CPU. Docs: not worth it in open scenes with few occluders. A high isometric view is that scene | docs 4.4-4.6 |
| **MultiMesh** | In use everywhere it should be; Tamka's posts and the roadworks are the two places that still build repeated geometry as unique triangles | code |
| **Threaded loading** | `ResourceLoader.load_threaded_request` (in use in `boot.gd`), `WorkerThreadPool` (roadworks), a `Thread` in the streamer. GPU upload still lands on the render side: keep resources small. A separate render thread exists (`--render-thread separate`, noted in the skill) | code; forum reports agree on the upload hitch |
| **Jolt physics** | Built in since 4.4, default for **new** projects since 4.6; existing projects keep GodotPhysics3D until the setting is changed. Behaviour differences listed in "Using Jolt Physics" | docs 4.6 |
| **Thermal state / Low Power Mode** | No Godot API on either platform (`main.gd:2343` says the same). iOS: `ProcessInfo.thermalState`, `isLowPowerModeEnabled` through a small plugin. Android: `PowerManager` thermal status (API 29+) through the existing export plugin (`addons/nw_android_export`) | search; no Godot plugin found |
| **4.7 itself** | HDR output (Apple, desktop; Forward+ and Mobile), Vulkan subsampled images for XR foveation, the Android build environment. Nothing that changes this plan | secondary reports only, *not checked against the official notes* |

**What shipped mobile games do** (general practice, from engine vendors' guidance and common
shipped settings menus; I did not find one authoritative source in this pass, so treat as *partly
unverified*): 3-5 presets plus a short advanced list; a resolution scale control; a 30 / 60 (and
120 where the screen allows) frame cap as its own setting; a battery or power-saving mode that
bundles 30 fps with lower resolution; an Auto that picks by device at first launch; adaptive
systems (Unity's Adaptive Performance on Samsung, the FrameReflex add-on for Godot) that change
**resolution scale and extras** when the device warms, and that respect a manual choice by asking
rather than overriding. The design in section 2 is that pattern, with whole-pixel steps instead of
a percentage slider because of the pixel look.

---

## Sources

- Godot docs 4.7, Reducing stutter from shader (pipeline) compilations: https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html
- Godot docs 4.7, Resolution scaling: https://docs.godotengine.org/en/4.7/tutorials/3d/resolution_scaling.html
- Godot docs 4.7, 3D antialiasing: https://docs.godotengine.org/en/4.7/tutorials/3d/3d_antialiasing.html
- Godot docs 4.7, Viewport class (Scaling3DMode, ScreenSpaceAA, mesh_lod_threshold): https://docs.godotengine.org/en/4.7/classes/class_viewport.html
- Godot 4.5 release page (shader baker, SMAA): https://godotengine.org/releases/4.5/
- Godot docs 4.6, Using Jolt Physics: https://docs.godotengine.org/en/4.6/tutorials/physics/using_jolt_physics.html
- Godot docs 4.6, Occlusion culling: https://docs.godotengine.org/en/4.6/tutorials/3d/occlusion_culling.html
- Godot docs, The .gdextension file (per-platform libraries): https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/gdextension_file.html
- godot-cpp template (CI matrix with iOS and Android arm64): https://github.com/godotengine/godot-cpp-template
- Godot forum, C++ creating nodes barely faster than GDScript: https://forum.godotengine.org/t/c-create-nodes-slower-than-gdscript-what-i-am-doing-wrong/55520
- Godot forum, Performance implications of native code instead of GDScript: https://forum.godotengine.org/t/performance-implications-of-using-native-code-instead-of-gdscript/120365
- Godot forum, Multithreaded resource loading is still laggy (GPU upload): https://forum.godotengine.org/t/multithreaded-resource-loading-is-still-laggy/10946
- Godot PR 87590 (resource loading and transfers in the background): https://github.com/godotengine/godot/pull/87590
- Apple Developer Forums, detecting an iOS app on an Apple silicon Mac (`isiOSAppOnMac`): https://developer.apple.com/forums/thread/656122
- Unity docs, `iOS.Device.iosAppOnMac` (the same idea in another engine): https://docs.unity3d.com/ScriptReference/iOS.Device-iosAppOnMac.html
- Android docs, thermal mitigation: https://source.android.com/docs/core/power/thermal-mitigation
- FrameReflex, an adaptive quality add-on for Godot (its preset ranges): https://rax-dev.itch.io/framereflex
- Godot 4.7 coverage (secondary): https://www.gamingonlinux.com/2026/06/godot-engine-4-7-is-out-bringing-a-new-asset-store-hdr-support-steam-frame-support/
