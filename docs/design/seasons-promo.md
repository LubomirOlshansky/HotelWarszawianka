# Seasons for trailers and promos

F, 2026-11-20: "make the time of year (winter, summer, autumn, spring): trees, snow, other things;
good for trailers and promo videos; later show the real weather, but only on the backlog."

This is a design only. Nothing here is built. It sits on top of
[trees-and-seasons.md](trees-and-seasons.md) (Fable's plan, 2026-11-15: the season system S1, trees by
season T4, winter W1-W5, section 8's PR order). That plan is right but is a whole-game calendar. This
note asks a narrower question: **what is the smallest thing that gives a promo shot any season, on
the phone and on the Mac, without waiting for the calendar?** The answer is a pinned season, chosen
by a flag or by Promo Mode, that later becomes the calendar's pin (S1) without being thrown away.

## 1. What is in the code today (checked 2026-11-20, main a274481)

| Piece | State |
| --- | --- |
| `tree_season` shader global (vec4: x turn to autumn colour, y fall of leaves, z blossom, w snow) | Declared in `project.godot`, read by `foliage.gdshader`. **Nothing writes it**: it stands at (1, 0.5, 0, 0), a golden mid-November, always. `z` and `w` are read by nothing yet |
| `TREE_LOOK` (summer and autumn colour, fall start and length per kind) and the 16 x 4 table texture | In `map_builder.gd`; no colour is typed twice |
| Instance data | Season-free since the T-fix, so the prebuilt sectors follow the global too |
| `sector_proxies.gd _trees` | **Still bakes the season**: `map.season == "autumn"` picks `CANOPY_NOVEMBER`, else `CANOPY_SUMMER`, into vertex colours. `map_builder.season` is `"autumn"` and nothing sets it. Distant (helicopter) trees would disagree with the near ones |
| `--season=summer\|autumn` | **Built by the teaser thread, not merged** (branch `claude/project-thread-j47234`, `dev_flags.gd`): writes `tree_season` as (0,0,0,0) for summer, else mid-November, for the video shots. This is the switch S0 builds on; there is no second one |
| `weather.gd` | Two states, Clear and Rain, with `amount` and `wet`. The rain streaks live in `post.gdshader` (`rain_layer`); the tier knob is `tiers.gd "rain"` (Low 0.4, Medium 0.7, High 1.0) |
| Ground, buildings, cars, people | No season at all. Grass has a fixed tint (`ground.gdshader` GRASS_TINT, id 1); the crowds know the month only through `month_factor` |
| Time and date | `--time=live --clock=HH:MM --date=YYYYMMDD`, `--game-clock`; `time_of_day.gd` has the NOAA sun by date, so winter dusk already comes early in Live |
| Promo Mode | PR #977, not merged yet (branch `claude/project-thread-u37fgm`): a DEV setting, readout, shots, COPY of `--cam= --yaw= --pitch= --size= --game-clock --clock= --date=` |
| Tier knobs | `tiers.gd QUALITY`: `rain`, `tree_limbs` (Low hides the limbs), `shadows`, `people`. No season field |
| Shader budgets (`check_shader_budget`, last recorded) | Lit shaders 260; ground about 219; `building.gdshader` **501 of 505** on Adreno; post is unshaded (320) |

So the trees are one write away from any season, and everything else (ground, roofs, cars, flakes)
is new work.

## 2. What each season needs

"Shader global" means a value written once, read by shaders already on screen: +0 draw calls.

| Season | Trees | Ground | Weather and light | New cost |
| --- | --- | --- | --- | --- |
| **Summer** | `tree_season` = (0, 0, 0, 0): summer colours, all leaves. Works today the moment something writes it | As now | Sun by a July date (`--date=`) | none |
| **Autumn** | (1, 0.2-0.5, 0, 0): gold, russet, some bare; already the default look | Olive-brown grass, leaf litter later | Low sun, Live clock | none for the trees |
| **Winter** | (1, 1, 0, snow): bare limbs and twig haze (`tree_limbs` off on Low: haze and trunks only); the oak keeps its brown | White cover | Snowfall, overcast, early dusk by a January date | snow (section 3) |
| **Spring** | Needs T4: bud (small, light yellow-green crowns growing to full) and blossom (`z`); until then a pale green summer | Bright green, a touch more saturated | Showers | the bud/bloom branch in `foliage.gdshader` |

## 3. Options

### A. Pinned season preset (recommended first step, "S0")

A tiny pure-static `season.gd` with four presets and one function, `Season.apply(name)`. It writes
the shader globals (`tree_season`, plus two new ones: `snow` 0..1 and `ground_season`, a vec4 grass
tint and dryness) and tells `weather.gd` to start or stop snowfall. It is the same module S1 needs
(`season.gd`, section 3.2 of the plan), only with the calendar left out, so S1 later adds
`Season.at(date)` and the setting without changing the presets.

How it is chosen:
- `--season=` **already exists on the teaser branch** (summer or autumn, in `dev_flags.gd`). S0 keeps
  that flag and its name, moves its one `tree_season` write into `Season.apply`, and adds `winter`,
  `spring` and `--snow=0..1` to dial the cover. If the teaser PR has not merged when S0 starts, S0
  is built on top of it (merge it first), never beside it. Shot sets and the teaser's Movie Maker clips pass it
  next to `--date=`.
- Promo Mode (#977) gets one row, SEASON, that cycles the four and the snow dial; COPY adds
  `--season=` to the flags so the Mac renders the same frame. It stays a DEV setting, saved with
  `promo_shots`, never touching the player's saved season (there is none yet).
- The default stays today's look (autumn) until F says otherwise, so nothing changes for players.

Cost: a few dozen lines, one check (`check_season`: every preset writes values in range; the
trees' buffers equal with two seasons, which `check_trees` already proves), no draw calls.
**This alone makes the teaser's summer-green trees, and all four tree looks, a flag.**

### B. The full calendar first (the plan's S1 as written)

The device's real date drives every consumer (`_crowd_calendar`, crowds, city life, old tram, the
radio), with a setting to pin a season. Right as an end state and the plan recommends it. For
promo work it is the slower road: it moves `main.gd` logic, touches six consumers and needs F's
answers to Q1-Q2 (the fixed Day/Dusk/Night looks following the date, "the Vistula is empty in
November"). **Do it after A, not instead of it.**

### C. Edit the footage, not the game

Colour-grade a summer clip toward winter in post. Cheap and wrong: it cannot bare a tree, whiten a
roof or fall as flakes, and it does nothing for the live game. Rejected.

## 4. How snow is drawn: two techniques

| | (1) In each shader (the plan's W1/W2) | (2) Screen-space in the post pass (recommended for promo) |
| --- | --- | --- |
| What | `mix` toward white by `snow` in `ground`, `building`, `foliage`, parked cars | `post.gdshader` whitens every pixel whose depth-derived normal faces up, with a world-anchored noise, one pass for everything |
| Reaches | exactly what each shader touches | roofs, ledges, cars, tree tops, bridges, props, the Palace: all at once, including shaders at their budget |
| Phone cost | a few ALU ops per shader | the pass already rebuilds view positions from the neighbouring depth taps for the reflections (`vr vl vd vu`, `post.gdshader` about line 120): the normal is a few more ops; no new texture reads. Verify it is not gated by `reflect_steps` (Low has 0) |
| Budget risk | **`building` is at 501 of 505**: roofs cannot take it without first slimming the shader | none on the lit shaders (post is on the unshaded budget) |
| Look | best: can know about kerbs, trodden lanes, roads cleared | good for white tops; cannot tell a road from a lawn (both face up), so roads need the ground's own id: see below |
| Parity | both city paths read the same shaders | same: it runs on the screen, so runtime and prebuilt cannot differ |

Roads are the catch. A screen-space layer would bury asphalt as deeply as a lawn. The fix is cheap
and local: the ground shader already knows each layer's id, so it writes road and pavement into
the colour only as "ploughed" via the one `snow` global (roads 0.2, pavements 0.7, grass and parks
1.0, water 0, as in the plan's section 4), and the post pass handles everything the ground shader
does not draw (roofs, cars, trees, props). So the recommendation is **both, each where it is
cheapest**: ground in `ground.gdshader` (about 40 spare ops of its 260), the rest in the post pass.
The plan's per-shader roof snow (W2) stays a later, optional upgrade if the post pass looks too flat.

Flakes: a `snowfall` layer next to `rain_layer` in the post pass (the plan's section 4). Never rain
and snow together; the Low tier keeps its `rain` density factor (0.4) for flakes.

## 5. Per-tier cost (the phone is the constraint)

| Item | Draw calls | Low (Nothing Phone) | Medium / High / Ultra |
| --- | --- | --- | --- |
| Tree colours and bare winter trees | +0 | limbs off already (haze and trunks): bare winter is the cheapest tree there is | limbs on, 116-triangle crowns as today |
| Season globals | +0 | one `global_shader_parameter_set` per change | same |
| Proxy trees recoloured (CPU) | +0 | once at load or on a season change, spread with `LoadYield` | same |
| Ground cover and grass tint | +0 | a few ALU ops | same |
| Screen-space snow on roofs and cars | +0 | **off on Low** unless a bench says otherwise; Low keeps ground and tree snow | on |
| Snowfall flakes | +0 | density x 0.4 (as rain) | 0.7 / 1.0 |
| Spring bud and blossom | +0 | the bud only; no blossom cells | on |

A season never adds a draw call outside the "in season" places of the plan's section 6 (Christmas
stalls, rink), which are separate, later items. Anything per-frame needs the bench before and
after at the spawn, a park and the helicopter view (CLAUDE.md "Performance is a gate"), and a note
of what only the phone can show (thermal on a snow drive, Adreno on the ground shader).

## 6. Recommended order (each one thread, one change note)

| # | PR | What | Why now | Model |
| --- | --- | --- | --- | --- |
| 1 | **S0 pinned season** | `season.gd` presets behind the teaser's `--season=` (adds winter, spring), `--snow=`, trees' proxies recoloured from the global (no baked season), `check_season`, `check_trees` unchanged and green | Unblocks every trailer shot; the teaser's summer trees; foundation for all below | Opus (it chooses the globals' shape) |
| 2 | **S0b Promo Mode row** | SEASON and the snow dial in #977's panel, COPY prints `--season=` | F frames shots on the phone and renders them on the Mac | Sonnet (applying 1) |
| 3 | **W1 snow** | Weather state Snow, flakes, ground cover, tree snow (conifers, bare twigs), screen-space white tops, `check_weather` | Winter promo; the biggest visible change | Opus |
| 4 | **S2 ground by season** | Grass tint by season, autumn leaf litter, spring brightness | Finishes the picture the trees start | Sonnet |
| 5 | **T4 spring** | Bud and blossom in `foliage.gdshader` | Spring is the only season the trees cannot do | Opus |
| 6 | **S1 the calendar** | The plan's S1: the device's date drives everything, "Pora roku" setting, the pinned season of S0 becomes its pin | The game follows the year (Q1, Q2) | Opus |
| 7 | Plan's W2-W5, L1-L3 | roof snow in the building shader, driving on snow, ice, coats, Christmas, rink | After F's answers to Q4-Q6 | as in the plan |

Steps 1-2 are small and are the only ones a promo needs to start. Steps 3-5 can be shot as soon as
each lands. Shots for every step: the same view at four pinned dates, runtime path and `--prebuilt`,
day and night.

## 7. Real weather (backlog only, not planned)

Later idea, parked: show Warsaw's actual weather (clear, cloud, rain, snow, fog, temperature) from a
free weather service, so the game outside matches the window. Notes for whoever picks it up:
- It maps onto what exists: a fetched condition becomes a `Weather` state and a `snow` cover, the
  temperature feeds `cold` (coats, breath), cloud cover feeds `clouds`.
- **Offline and failure are the normal case**: the game must run exactly as now with no network,
  with a short timeout and a cached last answer; it must never block a frame or the loading.
- Privacy: the request carries only Warsaw's fixed coordinates, never the device's position or
  an identifier. Pick a service whose terms allow a free non-commercial app, and name it in the PR
  (CLAUDE.md "Downloads").
- It needs the calendar (step 6) first and a setting "Weather: Game / Real". Store review: say it
  in the privacy answers if the call leaves the device.

## 8. Questions parked for F (defaults are what gets built)

1. **Order**: promo first (S0, S0b, W1) before the calendar? *Default: yes.*
2. **Default season when no flag**: stay on autumn (today's look) or switch the shipped game to
   summer green until the calendar lands? *Default: stay on autumn; the store shots and the demo
   pin July through the flag (Q9 of the plan).*
3. **Winter white**: always full cover in a pinned winter, or patchy (the plan's 60 %)? *Default:
   full cover when pinned, patchy only by the calendar.*
4. **Spring** without blossom is a pale summer. Wait for T4, or ship a pale-green S0 spring?
   *Default: ship the pale green, label it in Promo Mode.*

Out of scope here: driving on snow (the plan's W3), the Christmas and rink places, thunderstorms.
They stay as the plan has them.
