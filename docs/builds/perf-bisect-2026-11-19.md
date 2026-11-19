# Performance bisect, 2026-11-19: loading, Experimental, Android, the Mac picture

F reported four regressions over the last builds: loading much slower; Experimental no longer
holding 40-60 fps on the iPhone 16 Pro Max and falling back to Ultra on the Mac; the Nothing
Phone 1 down from "60 fps" to about 17 at High; the Mac picture poorly antialiased even at Ultra.
This is what the benches show and what to fix, in order.

Builds compared: `556dbe13` (2026-11-11, the last iPhone graphics bench), `419be67e` (TestFlight 11),
`8b1fd133` (Play 12), `5e57b169` (TestFlight 12 and Play 13). Bench = `--bench` (the bench route
from the spawn on Marszałkowska, prebuilt city, governor held). Android numbers come from
side-by-side release APKs (package `...perf<tag>`, the bench flags baked in, a local patch that
lets a release build read them; nothing of that is committed). Phone thermal status was 0 at every
start.

## 1. The Mac: no regression between the builds

MacBook Pro M4 Pro, 2868x1320 unless said, prebuilt city.

| Build | Ultra fps | Experimental fps | draw calls | main + shadow tris | city built |
| --- | --- | --- | --- | --- | --- |
| TestFlight 11 (`419be67e`) | 145 | 108 | 146-149 | 0.63 + 0.68 M | 7.1-7.5 s |
| Play 12 (`8b1fd133`) | 145 | 108 | 121-146 | 0.65 + 0.70 M | 7.1-7.3 s |
| TestFlight 12 (`5e57b169`) | 145 | 105 | 146-149 | 0.65 + 0.70 M | 7.1-7.5 s |

Experimental at 3024x1890 (full resolution, MSAA 4x, 8K soft shadows): 90 fps by day, 116 at
night, 74-98 flying. A 3-minute drive with the governor on (`--governor=log`) never dropped it on
either build.

What the Mac does have, in both builds: **single stalls of 0.5-1.0 s** in some runs (flying, and
night rain: 1,010 ms, 943 ms, 841 ms, 518 ms), and the **opening flight** drops to 14-45 fps for a
few seconds (CPU-bound; it is 12 s long since #911, 7.5 s before). Experimental's rule is "the
governor's first GPU drop steps the session back to Ultra" (`main.gd _experimental_drop`), so one
such stall is enough to lose Experimental for the session.

**The game on F's Mac is the iPhone app.** The Mac has TestFlight build 11 installed through
TestFlight (`/Applications/Around Warsaw.app`, an iPhone app on Apple silicon); there is no macOS
export preset. Played that way, its numbers and its picture are the iPhone build's in a Mac window.

## 2. The Mac picture: the pixel image is 480 lines tall

Below Experimental the 3D image is drawn at the screen height / 480 lines (style Sharp,
`tiers.gd own_scale`), with no MSAA and no FXAA (`main.gd`: `msaa_3d` and `screen_space_aa` off),
then scaled up with nearest filtering. On the iPhone 16 Pro Max that is x2 (1434x660 on a 6.9"
screen). On the MacBook's 3024x1964 screen it is **x4: 756x491**, every image pixel 4x4 screen
pixels on a 14" screen, which reads as jagged edges, "poorly antialiased". Experimental is the only
level with MSAA and the native resolution, and it is the one the governor gives up first.

## 3. iPhone 16 Pro Max: no regression on the bench route

TestFlight 12's source (`5e57b169`), `tools/device_run.sh`:

| Level | 2026-11-11 (`556dbe13`) | 2026-11-19 (`5e57b169`) |
| --- | --- | --- |
| Ultra | 60 fps, 1% low 50-53 | 60.0 fps, 1% low 48 |
| Experimental (x1, MSAA 4x, 8K soft) | 29-37 fps | 37.1 fps cool; 30.1 on the next run (33 then 27 per 10 s, warm) |

Experimental at full resolution never held 60 on this route; 2026-11-11's split showed full
resolution is the cost (Experimental at x2 held 60 for 10 s, 46-55 after a minute of heat).
40-60 fps is what lighter places give. Main + shadow triangles at the spawn: 0.69 + 0.71 M.

## 4. Nothing Phone 1 (Adreno 642L): never 60 with the city drawn

| Build | fps | 1% low | GPU ms | scripts ms | physics ms | main + shadow tris |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-08, city not drawn (driver bug) | 57.8 | 28.4 | 8.1 | 7.4 | | |
| 2026-11-08, Adreno fix | 22.6 | 13.5 | 30.7 | 19.7 | | |
| `556dbe13` (11-11) | 20.2 / 19.3 | 11.7 | 37.6 / 40.0 | 21.9 | 4.8 | 0.51 + 0.48 M |
| `419be67e` (TestFlight 11's source) | 17.8 | 6.4 | 45.0 | 26.1 | 7.1 | 0.70 + 0.65 M |
| `5e57b169` (Play 13) | 17.8 / 18.0 | 6.1 | 44.8 / 45.2 | 26.2 | 6.5 | 0.66 + 0.65 M |
| Play 13 as installed, F's save | 16.8 | 7.2 | 50.5 | 29.0 | 7.1 | 0.68 + 0.58 M |
| `5e57b169` at Medium (x3) | 22.8 | 12.2 | 30.8 | 20.6 | 4.4 | 0.75 + 0.66 M |
| `5e57b169` at Low (x3, no shadows) | 28.5 | 13.9 | 21.8 | 16.3 | 3.3 | 0.64 + 0 M |

The "60 fps" was the 2026-11-08 build whose city did not draw. Since 11-11 High lost about 12 %
(20.2 to 17.8 fps), all of it between 11-11 and TestFlight 11; TestFlight 11 to Play 13 is flat.
Of that: **trees by kind (#857)** add 0.73 M vertices to the city (4.22 to 4.94 M) and a quarter
more triangles in both passes at the spawn (a crown is 80 faces plus 6 limbs, 116 triangles, was
20); with the old 20-face crown and no limbs the phone's GPU is 43.2 ms instead of 45.2, about
2 ms, so the trees are not the main cost on the Adreno. Scripts rose 21.9 to 26.2 ms (traffic 4.0
to 5.2, people 1.6 to 1.9, crazy drivers new at 0.6-1.1, traffic bodies 0.5 to 0.8-1.1) and physics
4.8 to 6.5-7.1 ms (smashable fences on by default since #892, the cars' bodies of #893). In F's
own save `eggs+tape+spacer` costs 1.9 ms a frame (0.03 ms in a fresh one).

## 5. Loading: the new "places" step

Phone, launch to "city built", prebuilt city:

| Build | Nothing Phone, first launch after install | Nothing Phone, next launch | iPhone 16 Pro Max | Mac |
| --- | --- | --- | --- | --- |
| `556dbe13` (11-11) | 19.8 s | 13.0 s | | |
| `5e57b169` | 27.4 s | 19.7 s | 7.3-7.8 s | 7.1-7.5 s |

The step that was not there on 11-11: **places** (`places.gd`: 15 places, 446,000 triangles merged
into 87 sector meshes at load, on both city paths): 6.1 s on the Nothing Phone, 2.3 s on the
iPhone, 2.1 s on the Mac. **Tamka** alone (its bollards and plates, 114,290 triangles) is 3.2 s /
1.4 s / 1.2 s. Patelnia 0.8 s on the Nothing Phone. Every update also starts with the slower first
launch (+7.6 s on the Nothing Phone). Three more things make the start feel long:
- NOWA GRA reloads the scene and builds the whole city a second time (+6.6-6.9 s on the Mac; old,
  since 2026-10-31);
- the opening flight is 12 s (was 7.5) and stutters (above);
- the far edge's roadworks (351,142 triangles) are attached after the first frame: 1.8 s on the
  Nothing Phone.

Not a cause: PostHog (exception capture off, one tick a second, nothing in the bench's script
list), the map bake (227 MB of sectors on every build, centrum.json +0.4 %), draw calls (146-153 on
every build).

## 6. Fixes, ranked

1. **Loading: take the places out of the load.** Bake the places' sector meshes into the prebuilt
   sectors (they are already one mesh per sector), or build each sector's share when the sector
   streams in; Tamka's bollards and plates as MultiMeshes. -2.3 s on the iPhone, about -6 s on the
   Nothing Phone. (Map lane, Opus.)
2. **Experimental: keep it while it can hold.** Step back to Ultra only on a sustained GPU struggle
   (the governor's `struggled()`, or a second drop within a minute), never in the opening, a load or
   a wide view; and make full resolution its own switch: x2 with MSAA 4x and the 8K soft shadows
   held 60 on 2026-11-11, full resolution is what costs. (Performance lane.)
3. **The Mac picture.** On a Mac (the iPhone app on Apple silicon, or a macOS build) draw the
   image at screen height / 2 (x2: 1512x982 on the MacBook, inside Ultra's 1.6 MP) instead of 480
   lines, and add MSAA 2x/4x at High and Ultra there (the Mac draws Ultra at 145 fps); or export a
   native macOS build. Detection needs checking first: what `OS.get_model_name()` returns for the
   iPhone app on a Mac. (Visuals lane; F decides the look.)
4. **Android tier.** Auto picks High for every Android phone (`tiers.gd for_model`). On Adreno 6xx
   (`gpu_quirks.gd` knows it) pick Low with the 30 fps cap: 28.5 fps uncapped, so a steady 30. High
   at 60 is out of reach on this phone (CPU alone is 26 ms). (Performance lane.)
5. **Script and physics cost on slow CPUs**: traffic (5 ms), the game loop (7.5 ms), trams
   (2.5 ms), hud + minimap (1.7 ms), physics 6.5-7.1 ms with smashable fences on;
   `eggs+tape+spacer` 1.9 ms in a played save. (Performance lane.)
6. **Trees**: limbs only in thinned and bare crowns (hidden in a full one), the 20-face crown for
   the shadow pass or far tiles: a quarter fewer triangles in both passes, which matters most at
   full resolution with MSAA. (Visuals lane, art check.)
7. **The 0.5-1 s stalls** while flying and in night rain on the Mac (both builds), and the opening
   flight's CPU dips: find what lands in those frames (sector streaming, the edge roadworks).

## Reproduce

- Mac: `godot --path game --resolution 2868x1320 --disable-vsync -- --bench --nosave --prebuilt
  --quality=experimental --bench-frames=3000`, in a plain folder per commit (`git archive`, then
  `bake_sectors.py` and `bake_city.gd`).
- Vertices and triangles per commit without a bake: the runtime city at `--quality=high` (about
  4 minutes a commit; several commits can run side by side, counts don't depend on load).
- Android: a release APK with another `package/unique_name`, the APK format and
  `command_line/extra_args="-- --bench --nosave --bench-frames=3000 --bench-seconds=50"` in a local
  copy of the preset, and `release.gd pick` letting the flags through in that copy only; it installs
  beside the Play app, so the player's save is untouched. Log: `adb logcat -s godot`.
- iPhone: `tools/device_run.sh --label=NAME -- --bench --quality=experimental` (replaces the
  TestFlight app until it is installed again from TestFlight).
