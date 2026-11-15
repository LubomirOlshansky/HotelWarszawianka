# Trees review, seasons and weather plan

Fable's review and plan, 2026-11-15. Opus builds from this. Read from the uncommitted diff
(`map_builder.gd`, `foliage.gdshader`, `sector_proxies.gd`), the four screenshots, `weather.gd`,
`time_of_day.gd`, `main.gd _crowd_calendar`, `crowds.gd`, the shaders and `docs/architecture/`.
Nothing here was run: every number marked *est.* is arithmetic from the code, not a measurement.

---

## 1. Verdict on the trees work

**The approach is right, the November look is not ready, and one design choice blocks T4.**

Right:
- One mesh, one material, the kind in instance custom data, silhouettes in the vertex shader: +0 draw
  calls (131 → 131). This is the correct shape for this phone budget. Keep it.
- Bare trees at night (street-night-after.png) read well: clean dark branches against lit ground.
- Poplars as columns, pines against spruces, a small lean: cheap and they do break the sameness.

Wrong or risky, worst first:

| # | Problem | Evidence | Why it matters |
| --- | --- | --- | --- |
| 1 | **The season is baked into every instance** (`_tree_colour` → instance colour, `leaves` → custom.g) and into the proxies' vertex colours | `_tree_custom`, `_tree_colour`, `sector_proxies._trees` read `season` at build time | The prebuilt sectors and `proxies.scn` freeze the season of the day `bake_city.gd` ran. T4 ("season by date") would work on the runtime path only: the two city paths would differ. Must be fixed before T4, cheapest to fix now |
| 2 | **Partly-leafed crowns are shrunk pom-poms on antlers** | Shader: crown scale = `smoothstep(0.08, 0.4, leaves) * (0.6 + 0.4 * leaves)`. A lime (0.30) is a 55 % ball, a chestnut (0.15) a 9 % dot, while the limbs stand at 87-110 %. Jitter of ±0.15 straddles the steep part, so neighbours of one kind differ 6x in crown size. Seen in street-before-after.png, bottom left | The middle states are the ugly ones and November puts most trees in them |
| 3 | **Colour got duller, not more varied** | `TWIG.lerp(leaf, 0.6 + 0.4 * g)` greys every thin crown; the dapple darkens to 0.62 on up to 62 % of cells; `autumn()` removes orange. park-before had five readable hues, park-after is olive, khaki and brown | F's complaint was "all the same". Shapes now differ; colour now does not |
| 4 | **Limbs poke through leafed crowns** | Limbs scale uniformly round the foot and ignore `crown_shape` (taper 0.65 on a poplar, `high` 0.6 on a robinia) and the lumps (oak: 0.2 × 2.1 × up to 1.6 = dents of −40 % of the radius or more) | Seen issue; the cause is that the two parts use different maths |
| 5 | **Limb thickness follows the instance scale** | Rods are 2.5-20 cm in mesh space; `sxz` is 0.45-7.0, so limbs are 1 cm to 1.4 m thick. Thin ones are under a pixel (crawl when the camera moves); every limb gets a dark outline each side from `post.gdshader`'s depth edges (1 px limb → 3 px black line) | The "thicket" in park-after is mostly outline. At phone zoom it is noise |
| 6 | **Triangles: 20 → 176 per broadleaf crown** (80 crown + 16 rods × 6), in both passes | Measured: main 0.29 → 0.60 M, shadow 0.20 → 0.51 M | Draw calls are the gate, so this is probably fine, but it is unproven on the phone, the 96 limb triangles are invisible for seven months of the year, and there is no knob to turn it down |
| 7 | **The guessed kinds make squares** | 40 m grid cells, each one kind, each kind its own colour and leaf state; cell edges ignore streets and parks | From the helicopter over Łazienki this is a checkerboard; a street's row changes kind at an arbitrary grid line |
| 8 | **Shape rules over-claim** | `top > 4 * radius` → birch, `top > 14 and top > 4.5 * radius` → poplar. Young street limes and tightly segmented rows have narrow scan crowns | Nobody has counted the result. Likely far too many birches and poplars |
| 9 | **`trees3d_kind` as a parallel array is fragile** | `kinds[i / 6]`; 25+ tools read or edit `trees3d` (`object_fixes.py`, `street_pass.py`, `planted_trees.py`, `bake_sectors.py` ...) | One pass that drops a tree shifts every kind after it, silently. And `bake_sectors.py` would have to split a second key per sector |
| 10 | **Mesh follows the needle flag, shape follows the kind** | `is_needle` picks the mesh; a T1 kind that disagrees sends a conifer mesh through `crown_shape` | Garbage shape, no error |
| 11 | One crown fills the bottom fifth of park-after.png | Probably lumps × `wide` on a large crown near the camera | Check; cap the lump amplitude |
| 12 | Green summer grass under bare November trees | Ground has no season | Not this PR, but the picture is half a season |

Smaller: the `if (kind == …)` chain in the vertex shader should be constant arrays (no branches,
safer on Adreno); `custom_aabb.grow(12.0)` no longer covers a 16.8 m crown plus lean (use 20);
`check_*` for trees does not exist; PHONE-CHECK row 14q is good, keep it.

Not a problem: custom data cost (+16 bytes × 44,872 = 0.7 MB; the +2.2 MB of the prebuilt scenes
is this plus the larger shared mesh per sector); the sin hashes are deterministic enough in
64-bit GDScript for both paths.

---

## 2. Fixes before merge

One PR (**T-fix**, Opus), amending the uncommitted diff. Numbers are starting values to tune on shots.

| # | Fix | Concretely |
| --- | --- | --- |
| F1 | **Season out of the instance data** | Instance colour = the tree's own jitter only (brightness ±0.25, a warm/cool shift), grey-white based. Custom = (kind / 16, seed, stand density 0..1, spare). The leaf colour, leaves left, blossom and snow come from shader globals (section 3) and a per-kind table. Until S1 lands the globals are set once from `map.season` by `map_builder.gd`, so this PR looks the same as today but nothing seasonal is baked. `map.season` then stops being read at build time |
| F2 | **One per-kind table, one owner** | `TREE_LOOK` stays the single source in `map_builder.gd`. At load it is written into a 16 × 4 RGBA8 texture set on `leaf_material` (`tree_look`): row 0 summer colour, row 1 autumn colour, row 2 blossom colour + amount, row 3 fall start, fall length, leaves kept in winter, spare. The shader reads it with `texelFetch` in `vertex()`. No colour is typed twice. Silhouette parameters stay in the shader as `const float LOW[11]`, `HIGH[11]`, `TAPER[11]`, `WIDE[11]`, `DROOP[11]`, `LUMPY[11]`: no `if` chain |
| F3 | **Three leaf states, not a continuum** | Per tree, from its leaves value `L` and seed: `L >= 0.55` full crown, full size; `0.2 <= L < 0.55` **thin**: full size and silhouette, holes cut by world-space cells (the existing 0.45 m `pick` hash; discard where `pick > L + 0.25`), leaf colour undimmed; `L < 0.2` **bare** (F4). Never scale the crown below 0.85. Holes are world-anchored, so they do not shimmer. Foliage already has a `discard` (the fade near the car), so no pipeline change |
| F4 | **Bare tree = limbs + a twig haze** | Keep the crown shell on a bare tree at 30-35 % cell coverage in `TWIG`, with no dapple and no lumps above 1.0. From above a bare park then reads as soft grey-violet masses with trunks, as real ones do, not as a thicket. It is also what snow will sit on (section 4) |
| F5 | **Fewer, thicker limbs** | Drop the 10 secondary branches: leader + 5 limbs = 6 rods, 36 triangles. Crown 80 + 36 = **116** (was 176, −34 %). *Est.* for the measured park view (about 2,000 crowns): main pass 0.60 → 0.48 M, shadow 0.51 → 0.39 M |
| F6 | **Limbs in world metres, at least a pixel** | Store each limb vertex's centre-line point in a custom vertex attribute (`CUSTOM0`). In `vertex()`: shape the centre-line point, then offset by a width in world metres: 0.32 m at the foot to 0.12 m at the tip, `max`ed with 1.2 × the pixel image's metres per pixel (a new global `px_m`, written where the pixel image size is set). No more 1.4 m or 1 cm limbs |
| F7 | **Limbs follow the crown** | Pass the limb's centre-line point through the same radial profile `r(u)` and `y` remap as `crown_shape` (no lumps). When not bare, cap its reach at 0.55 of the crown's local radius. When full (`L >= 0.55`), collapse limb vertices to the foot (degenerate, zero fill): they are invisible anyway |
| F8 | **Cap the lumps** | `LUMPS * lumpy` ≤ 0.30 after all multipliers (today up to 0.67 on a thin oak). Remove the `1 + 0.6 * (1 - leaves)` boost |
| F9 | **Colour back** | No `TWIG.lerp` on leafed or thin crowns. Dapple stays 0.78 / threshold 0.42 for all leafed states. Autumn per kind stays yellow, russet and red-brown (the jobs' orange stays reserved: keep `autumn()`), but raise saturation: lime `#d4b032`, maple `#d9a020` with 1 in 4 `#b5482a`, oak `#9a5a2c`, birch `#e0c63e`, chestnut `#96602e`. Target on the park shot: at least 4 hues a viewer can name |
| F10 | **Mesh by kind** | `kind >= SPRUCE` picks the conifer mesh; the needle flag is only the fallback when no kind is stored |
| F11 | **Kill the squares (until T1)** | Jitter the cell lookup by ±12 m of low-frequency noise per tree and mix 3 kinds per cell (60 / 25 / 15) instead of 1 + 20 % random. Tighten the shape rules: poplar `top > 18 and top > 5.5 * radius`, birch `top > 5 * radius and top < 16`. Print the kind histogram at build under a dev flag; expected poplar ≤ 4 %, birch ≤ 8 % |
| F12 | **A knob** | `tiers.gd` field `tree_limbs` (Low: off → limbs collapsed, bare trees are haze + trunk only). No governor step (not CPU) |
| F13 | **A check** | `game/tools/check_trees.gd`, joined to `tools/verify.sh`: (a) every TreeKind has a `TREE_LOOK` row and shader table entries; (b) on a small fixed city, the per-sector tree count, kind histogram and a hash of the instance buffers are equal on the runtime and prebuilt paths; (c) no instance colour or custom value depends on `season` (build twice with two seasons, buffers equal); (d) `foliage.gdshader` under `check_shader_budget` |
| F14 | Housekeeping | `custom_aabb.grow(20.0)`; `tools/turntable.sh`-style sheet of the 11 kinds × 3 leaf states (one image) attached to the PR; shots by day and night, runtime and `--prebuilt`; bench before/after; PHONE-CHECK 14q kept |

The shadow pass: `shadow_mesh` is ignored by MultiMesh, so do not chase it. F5 and F7 take a third
of the triangles out; if Godot 4.7's spatial shaders expose a shadow-pass flag (verify in the
engine, do not assume), also collapse limbs there for leafed trees. Only the phone bench says
whether 0.39 M shadow triangles matter: that is a device run and needs F's yes (question Q7).

**Merge gate for T-fix:** no shrunken crowns, no limb through a full crown in 20 sampled trees per
kind, at least 4 nameable hues on the park shot, draw calls unchanged, triangles ≤ 1.1 M on the
park view, `check_trees: OK`, both city paths identical.

---

## 3. Season system

### 3.1 What "the game's date" is (recommendation)

Today there are two truths: trees say `"autumn"` always; crowds, the old tram and the radio say
month 7 unless the look is Live (`main.gd _crowd_calendar`). One calendar must own both.

| Option | For | Against |
| --- | --- | --- |
| **A. The device's real date in Warsaw time, always (recommended)**, with a setting to pin a season | What F picked. The city matches the window. Live already works this way. Free replay value through the year | A November launch shows a bare city; store shots and the demo need the pin |
| B. An in-game calendar that advances with play | Every player sees every season | A new saved value, a new HUD element, a pacing design. Not worth it for a driving toy |
| C. A setting only | Simple | Nobody finds it; the city never surprises |

**Build A.** Setting "Pora roku / Season": Auto (today) · Wiosna · Lato · Jesień · Zima. A pinned
season stands for a fixed date (15 May, 15 July, 20 October, 20 January) and that date also feeds
Live's sun (so winter gets its early dusk). Dev flags: `--date=YYYYMMDD` exists; add
`--season=spring|summer|autumn|winter`. Shots and the bench always pin a date (the shot sets pass
`--date=`), so screenshots do not change with the day they were taken.

The fixed looks (Day, Dusk, Night, Dawn) take the season from the same calendar. This overrides
vision.md Open Question 5 ("without Live it is always summer") and is question Q2 for F.

### 3.2 Owners

| Piece | Owner | Notes |
| --- | --- | --- |
| Season rules | **new `season.gd`**, pure static (like `ride_rules.gd`), row in systems.md §7, `check_season.gd` | `Season.at(ymd) -> {season, month, bud, turn, fall, bloom, cold, snow_day}`. Curves by day of year (table below). No nodes |
| The calendar | `main.gd _crowd_calendar` becomes a thin call into `season.gd` + `time_of_day.gd` (main.gd is under a size ratchet: the logic moves out, it does not grow) | The same dictionary every consumer already takes (`crowds`, `city_life`, `event_day`, `old_tram`, `rave`, `street_meet`), with `season` and the curves added. No consumer gets its own date maths |
| Shader globals | `time_of_day.gd` writes them (it owns the look's globals) from `season.gd`'s values | `season` vec4 = (bud, turn, fall, bloom); `snow` float (cover, written by `weather.gd`); `px_m` float. Declared in `project.godot [shader_globals]` |
| Precipitation, cover, fog | `weather.gd` | States: Clear, Rain, Snow, Fog. `amount`, `wet` as today; new `snow_fall`, `cover`, `fog` |
| The setting | `settings.gd` + `settings_panel.gd` | A Polish/English pair per label |
| Season-tied places | `Places.TABLE` rows with a new `when` field | Section 6 |
| Season-tied dated events | `event_day.gd` (already gates 11 November on the calendar) and `palace_lights.gd` (dated light patterns) | Extend their tables, no new event system |

### 3.3 Curves (Warsaw, day of year; `check_season` pins these)

| Value | 0 → 1 | Used by |
| --- | --- | --- |
| `bud` | 5 Apr → 5 May | leaves come out (light yellow-green first) |
| `bloom` | 0 → 1 → 0 over 15 Apr-20 May (chestnut candles 5-25 May, robinia 25 May-12 Jun by a per-kind offset) | blossom |
| `turn` | 20 Sep → 25 Oct | summer colour → autumn colour |
| `fall` | 10 Oct → 30 Nov | leaves drop; per kind `start` in `TREE_LOOK` (chestnut 0.0, poplar 0.1, lime 0.15, birch 0.2, maple 0.25, robinia 0.3, plane 0.4, willow 0.55, oak 0.6 and it keeps 0.4 brown all winter) |
| `cold` | 1 from 1 Dec to 28 Feb, ramps 15 Nov and 15 Mar | coats, breath, rain becomes snow |
| `snow_day` | hash of the date, true on about 60 % of days with `cold` = 1 | whether the day starts with cover (Q4) |

A season change needs no rebuild: everything in the static city reacts through globals. Places with
a `when` are built at load, so they change at the next launch (the settings row says so).

### 3.4 Two city paths

- After F1 the tree buffers hold nothing seasonal, so prebuilt sectors are season-free.
- **Proxies** (`proxies.scn`, StandardMaterial3D, vertex colours) cannot read a global. Mark tree
  vertices at build (UV = (1, blob seed)) and recolour them on the CPU at load and on a season
  change from `TREE_LOOK` + `season.gd` (a one-off loop spread with `LoadYield`, 0 per frame, +0
  draw calls). `check_trees` compares a proxy's tree colours on both paths for two dates.
- Every season PR shows the same view at four pinned dates on the runtime path and `--prebuilt`.

---

## 4. Winter

All static-city effects are a `mix` on a global in an existing shader: **+0 draw calls**.

| Item | What changes | Owner | Phone cost | Check | Two-path risk |
| --- | --- | --- | --- | --- | --- |
| **Snowfall** | Flakes in the post pass: the rain's `rain_layer` with other numbers (speed 40-70, length 1-2 px, a sideways drift), blended by a `snowy` uniform, not a second branch | `weather.gd` (state Snow), `post.gdshader` | 0 draws; same per-pixel work as rain at the pixel image's size | `check_shader_budget` (post); shots day and night | none |
| **Cover on the ground** | `ground.gdshader`: one `mix(base, SNOW, snow * k[id] * patch)` before the wetness block. `k`: grass, parks, sand 1.0; pavements and plazas 0.7 with darker trodden lanes (noise bands); roads 0.2 as broken patches; rails and tram bed 0.5; water 0 | `ground.gdshader`, global `snow` | 0 draws; a few ALU ops | budget check; shots at the spawn, Marszałkowska, a park | none (same shader both paths) |
| **Ploughed roads, slush at kerbs** | Grey-brown slush band at the road's edges **only if** the road ribbons already carry a cross-road coordinate (Opus: check the road layer's UVs first). If not, slush is noise patches along the road; do not add geometry for it | `ground.gdshader` | 0 draws | shots | none |
| **Snow on roofs** | `building.gdshader`: `mix` by the world normal's y (`smoothstep(0.5, 0.8, n.y)`) and `snow`; ledges and cornices catch it for free | `building.gdshader` + the lite copy | 0 draws. **Risk: the lite shader stands at 501 of 505** on Adreno. A `mix` + `smoothstep` adds no control flow, but graphics.md says the next change must slim it first. Do it as its own PR; if the lite copy cannot take it, Adreno 6xx gets no roof snow | `check_shader_budget` must print ≤ 505; Android device note in the PR | none |
| **Snow on trees** | Conifers: up-facing facets white. Bare trees: the twig haze's cells white on the upper half, a white top line on limbs (limb normals). Leafed evergreens only | `foliage.gdshader` | 0 draws | the kinds sheet at `snow` 0, 0.5, 1 | none after F1 |
| **Snow on parked cars** | Parked cars use `foliage.gdshader` with `sway = 0`: white on up-facing faces above 0.9 m of `lift_h`. Moving cars stay clean (they are driven) | `foliage.gdshader` | 0 draws | shot of a parked row | none |
| **Vistula ice** | `ground.gdshader` water branch (id 3): the surface map already has shore distance and flow. Ice shelf where shore distance < 5-12 m (noisy edge), and floes ("kra") drifting with the flow in mid-river when `cold` | `ground.gdshader`, `tools/bake_water.py` data as is | 0 draws | shots from Most Świętokrzyski; `check_water` unchanged | none. Gameplay: visual only; the boat and its race are unaffected (Q6) |
| **Fog, frost** | Weather state Fog: `time_of_day.set_weather` flattens the light as for rain; the post pass adds mist by world height (it already rebuilds the position from depth): thick below about 6 m above the river, thin in the streets. Winter mornings and autumn evenings start foggy by the date's hash | `weather.gd`, `post.gdshader`, `edge_haze` | 0 draws; one more depth read per pixel is already there | budget; night shots (lamps in fog must not wash out the HUD) | none |
| **Early dark** | Already true in Live (`sun_position` by date). A pinned season feeds its date to Live. Fixed looks unchanged | `time_of_day.gd` | 0 | `check_season`: sunset on 20 Jan before 16:15 | none |
| **Driving on snow** | New `car.slip` 0..1 beside `car.wet` (the same pattern): main roads 0.25, side streets 0.6, off-road 1.0. Grip × (1 − 0.30 slip), brakes × (1 − 0.25 slip), drift grip × (1 − 0.40 slip): handbrake slides go further and hold longer, top speed and acceleration untouched. Tyre upgrade "Zimówki" in `upgrades.gd` halves it. Traffic drives 15 % slower. A powder trail behind the car instead of the rain hiss | `car.gd` (numbers in the handling presets), `upgrades.gd`, `traffic.gd`, `sfx.gd` (`Sfx.SHOTS` row) | 0 draws; no new per-frame system | `check_steering.gd` (`--fixed-fps 60`) with a snow case: the slalom still passes, the stop from 80 km/h is at most 30 % longer; timed activities (rides, races) checked for par times | none |
| **People in coats** | `cold` > 0.5: the pedestrians' palette swaps to winter (navy, black, grey, camel, a few red hats and scarves); a breath puff is skipped (too small at this zoom) | `pedestrians.gd` palette, `crowds.gd` month factors (already there) | 0 draws (instance colours) | `check_crowds`; a street shot | none |
| **Christmas, rink** | Section 6 | | | | |

How snow stays fun: it is the drift mode. Nothing gets slower except braking, mistakes cost a
slide, not a stop; the police and rivals slip too. It is opt-out (Q5).

---

## 5. Other seasons and weather

Ranked by value for cost. "Build" = in the PR order; "later" = backlog.

| Rank | Item | What | Owner | Cost | Verdict |
| --- | --- | --- | --- | --- | --- |
| 1 | **Trees through the year** | Spring: bud (small yellow-green crowns growing to full over `bud`), blossom (white chestnut candles, cream robinia, pink-white cherries and crab apples where OSM names Prunus / Malus: holes filled with the bloom colour by cells). Summer: the summer row. Autumn: `turn` then `fall` per kind. Winter: bare + haze, oak brown, conifers, snow | `foliage.gdshader`, `TREE_LOOK` | 0 draws | **Build (T4)** |
| 2 | **Ground by season** | Park grass: spring bright, summer as now, a little dry-yellow in August, olive-brown in November, under cover in winter. Autumn leaf litter: a tint under trees from the AO map's green channel (trees' shade), yellow-brown, densest in `fall` 0.3-1.0 | `ground.gdshader` | 0 draws | **Build**: it finishes the picture the trees start |
| 3 | **Falling leaves and wind** | Leaves in the post pass (the snow layer in leaf colours, sparse, only when `fall` is 0.2-0.9 and wind is up). Wind = a global `wind` 0..1 scaling the crowns' sway and the flakes' drift; gusty days by the date's hash | `weather.gd`, `post.gdshader`, `foliage.gdshader` | 0 draws | **Build** (rides on the snowfall PR) |
| 4 | **Summer thunderstorm** | Rain exists. Add: lightning as a 2-frame lift of `daylight` in the post pass, thunder 1-4 s later (`Sfx.SHOTS` row, a duck in `Sfx.DUCKS`), heavier streaks | `weather.gd`, `post.gdshader`, `sfx.gd` | 0 draws | **Build**, small. Photosensitivity: off under `access.gd`'s reduced-flash setting |
| 5 | **Spring showers** | A short rain that starts and clears by itself on spring dates | `weather.gd` | 0 | **Build** with Q3 (auto weather) |
| 6 | **Fog over the river** | The Fog state of section 4, on autumn and winter mornings | `weather.gd`, `post.gdshader` | 0 draws | **Build** with winter |
| 7 | Heat haze | A shimmer over asphalt | `post.gdshader` | 0 draws, but a UV wobble blurs pixel art | **Skip.** Show heat with light instead: a warmer, harder July noon in `time_of_day.gd` LOOKS |
| 8 | Rainbow, hail, sleet | | | | Skip |

---

## 6. Season life in the city

Places are built at load by `_build_places` on both city paths, so a season gate is safe there.
Add `"when"` to `Places.TABLE` rows (a `season.gd` window: months, or dates); a row outside its
window is not built and costs nothing. `check_places` (or the places step) lists what each of
four dates builds.

| Rank | Item | When | What | Owner | Cost |
| --- | --- | --- | --- | --- | --- |
| 1 | **Christmas lights and the tree at Plac Zamkowy; Jarmark stalls on the Barbakan side** | 1 Dec-6 Jan | The 27 m tree with lights (night glow), 10-14 wooden stalls, light strings over Krakowskie Przedmieście and Nowy Świat; Chmielna's strings in the trees (BACKLOG P5R-2) and the Pasaż Wiecha tree (BACKLOG, F said yes) | a `place.gd` script + `Places.TABLE` row (`when`), `glow.gdshader` gated by `lights_on`; stall crowds rent pedestrian slots (`crowds.gd`) | poured: ≤ 2 draws per sector; `own` ≤ 1 for the lights. ~20 k triangles |
| 2 | **Beach bars on the Vistula open / shut** | open May-Sep | `landmarks/river.gd` already draws pavilions "open or shuttered for the season": feed it the calendar instead of a constant; deck crowds already follow `month_factor` | `landmarks/river.gd`, `crowds.gd` | 0 new |
| 3 | **Ice rink by the Palace** | Dec-Feb | A white slab, boards, a hut; 8-12 skaters as pedestrian slots moving on an oval; music ducks the radio near it (`Sfx.DUCKS`) | a place + `crowds.gd` | ≤ 1 draw, ~6 k triangles |
| 4 | **New Year fireworks** | 31 Dec 23:55-00:20 | Bursts over the Palace and the river; `event_day.gd` is the dated-event owner (it has 11 November); `palace_lights.gd` gets its pattern | `event_day.gd`, `palace_lights.gd`, `glow.gdshader` | particles drawn as one additive mesh: 1 draw while it runs |
| 5 | **Wszystkich Świętych** | 1-2 Nov | Clusters of red and white candle glows at church yards and monuments inside the map (night only) | a place with `when`, `glow.gdshader` | 1 draw per sector at night |
| 6 | **Wianki** | the Saturday nearest 21 Jun | Fireworks over the river (reuses 4), a full boulevard (`crowds.gd`), wreaths as small lit dots drifting with the water's flow | `event_day.gd`, `ground.gdshader` water branch | 0-1 draws |
| 7 | Ice-cream kiosks | May-Sep | 3-5 kiosks with short queues; the gelato queue exists all year (ROADMAP) | a place | poured |
| 8 | Chestnuts on the pavement, kids collecting | Sep-Oct | Under chestnut-kind trees in parks | `park_details` | Later |
| 9 | Radio and dialogue by season | all | The host's greeting already takes month and rain: add snow, fog, heat and first-snow lines to `game/data/dialogue.json` (warsaw-tone skill; Sonnet) | `dialogue.gd`, `dialogue.json` | 0 |

---

## 7. Phone budget

| Item | Draw calls | Fill / overdraw | Triangles | Notes |
| --- | --- | --- | --- | --- |
| Trees after T-fix | +0 | thin and bare crowns let pixels behind show (alpha-tested cells): small at the pixel image's size | park view ~1.08 M total *est.* (was 0.70 M before the thread, 1.32 M now) | the only item that needs a phone bench |
| Season globals, tree table | +0 | 0 | 0 | one 16 × 4 texture |
| Ground, roof, tree, parked-car snow; ice | +0 | a few ALU ops per pixel | 0 | watch the Adreno control-flow ceiling: `mix` / `step` only |
| Snowfall, leaves, fog, lightning | +0 | per-pixel hash work equal to rain; never rain and snow together | 0 | post pass runs at the low resolution |
| Proxies recolour | +0 | 0 | 0 | CPU at load only |
| Christmas, rink, kiosks, candles | ≤ 2 per visible sector, only in season | small | ≤ 30 k in season | each row's `tris` and `own` in `Places.TABLE` |
| Driving, coats, crowds | +0 | 0 | 0 | no new per-frame script; `car.slip` is one multiply |

Rules for every PR below: bench before and after at the spawn, a park and the helicopter view;
draw calls must not rise outside the "in season" rows; `check_shader_budget` for any shader
touched; shots at four pinned dates on the runtime path and `--prebuilt`; name what only the
phone can show (the shadow pass with 116-triangle crowns, thermal over a snow drive, Adreno).

---

## 8. PR order

Each is one thread, guarded by its check, with a change note. Model per CLAUDE.md routing.

| # | PR | Contents | Check | Model | Needs F |
| --- | --- | --- | --- | --- | --- |
| 1 | **T-fix** | Section 2, F1-F14 | new `check_trees`; bench; kinds sheet; both paths | Opus | Q7 (phone bench) |
| 2 | **T1 kinds in the map** | A guarded, idempotent pass `tools/tree_kinds.py` under TD-25 (listed in `check_post_passes.py`, called from `bake_osm.py`). **Store the kind in the existing flag field**: `flag = needle + 2 × (kind + 1)`, old 0 / 1 still valid, readers change `== 1` to `& 1` (grep all 25+ readers). No parallel array, no new key, no stride change. Sources in order: OSM species / genus; the same kind along a tree row (trees within 12 m of one road segment, per side, per block); parks: 3 kinds per park polygon mixed by warped noise; willows only within 40 m of water; shape rules last. A small curated `tools/tree_kinds.json` (street or park → genus, with a source column). Warsaw's inventory stays out until someone can fetch it from the Mac | `check_map_data.py` with the kind histogram recorded on purpose; `postpasses`; `check_trees` | Opus | Q8 |
| 3 | **S1 season core** | `season.gd` + `check_season`, the calendar unified, globals, the setting, `--season=`, shot sets pin a date. No look change except what already reads the month | `check_season`, `check_crowds`, `architecture` | Opus (design) | Q1, Q2 |
| 4 | **T4 trees by season** | Shader reads `season`; bud, bloom, turn, fall; proxies recolour | `check_trees` (two dates, both paths); kinds sheet × 4 dates | Opus | none |
| 5 | **S2 ground by season** | Grass tint, leaf litter | budget; shots × 4 dates | Sonnet applying this spec; Opus if the budget fails | none |
| 6 | **W1 snow** | Weather state Snow, snowfall, `snow` cover on ground, trees, parked cars; falling leaves and `wind` ride along | budget; `check_weather` (new: state machine, cover builds and melts); bench | Opus | Q3, Q4 |
| 7 | **W2 roof snow** | `building.gdshader` and the lite copy, alone | `check_shader_budget` ≤ 505; parity shots of 6 landmarks | Opus | none |
| 8 | **W3 driving on snow** | `car.slip`, the tyre upgrade, traffic, sound, radio lines | `check_steering` snow case; activity par times | Opus (feel) | Q5 |
| 9 | **W4 ice and fog** | Vistula ice, Fog state, river mist | budget; `check_water`; night shots | Opus | Q6 |
| 10 | **W5 winter people** | Coat palette, crowd factors review | `check_crowds` | Sonnet | none |
| 11 | **L1 Christmas** | `when` in `Places.TABLE`, Plac Zamkowy tree and stalls, light strings, Chmielna, Pasaż Wiecha | places budget; turntable of the tree and a stall; night shots | Opus spec, Sonnet build | Q9 |
| 12 | **L2 rink, beach bars by calendar, kiosks** | | places budget; `check_crowds` | Sonnet | none |
| 13 | **O1 thunderstorm, spring showers** | | budget; `check_weather`; `check_mixer` | Sonnet | Q3 |
| 14 | **L3 dated nights** | New Year, Wianki, 1 November candles | `event_day` check; bench while it runs | Sonnet, Opus for the fireworks' cost | none |

PRs 1-4 are the trees thread F asked for. 5-9 are winter. 10-14 can run in any order after 3.

---

## 9. Questions for F, with defaults

Work does not wait: each default is what gets built; park these in `docs/QUESTIONS.md`.

| # | Question | Default built |
| --- | --- | --- |
| Q1 | What is "the game's date"? | The device's real date in Warsaw time, with a Season setting to pin spring, summer, autumn or winter |
| Q2 | Do the fixed looks (Day, Dusk, Night) follow the season too? Today they are always July for crowds | Yes, one calendar for everything. Side effect: in November the Vistula steps are nearly empty in every look |
| Q3 | Does the weather change by itself? Today rain is only the button | Yes, gently: the day's hash picks a start (clear, shower, fog, snow) for the season; the button still cycles Clear → Rain (Snow when cold) → Fog |
| Q4 | Is winter always white? Real Warsaw winters often are not | About 60 % of winter days start with cover; a setting "Śnieg / Snow": Auto · Always · Never |
| Q5 | Should snow change the driving? | Yes, mild (grip −30 % at most, longer slides, the "Zimówki" upgrade halves it), with an off switch under comfort settings |
| Q6 | Does river ice stop the boat and its race? | No. Ice is at the banks and as drifting floes, visual only |
| Q7 | A phone bench for the trees (shadow pass, parks from the helicopter) | Ask for one device run after T-fix; until then merge on draw calls unchanged and the `tree_limbs` knob |
| Q8 | Tree kinds: who fetches Warsaw's tree inventory (blocked from the cloud)? | Nobody for now: OSM + rows + parks + the curated table; a Mac session can add the inventory later as one more source in the same pass |
| Q9 | Store shots and the demo: which season? | Pinned to July (the vision's summer evening) until F says otherwise; the live game follows the date |
| Q10 | Blossom: only where OSM names cherries and crab apples, or also a few invented rows for looks? | Real data only, plus chestnut candles and robinia, which the kinds already give |
