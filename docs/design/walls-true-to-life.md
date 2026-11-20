# Walls, fences and rails that look like the real ones

**Status (2026-11-15):** re-planned. The first plan (2026-11-13) was written before anything was
built. Since then steps 1 to 8a of `docs/design/city-objects-plan.md` are merged, F answered the
four defaults (section 11) and asked for more detail. This page was reviewed against the code on
main and against fresh street photos, and sections 6, 8, 9 and 10 were written again. No game
code changed in this review. The build is for Opus threads, one phase per pull request through
the audit (section 10).

**The order of work is in `docs/design/city-objects-plan.md`** (stage C, section 5.2 there). This
page is the build brief for the look. Where the two differ, that page wins.

F (2026-11-13): "How to make these walls look more like in life. There are the walls now, but
they should represent the real type of object and texture, and how to handle it if it is ruined:
the memory of it and the recovery."

F (2026-11-15): the four defaults as recommended; "adding more details always good".

This page owns **what each wall, fence, hedge and rail is and how it looks, whole and broken**.
`docs/design/drivable-city-build.md` owns what the car does to them and how a broken one is
remembered and repaired. The seam between the two is section 7 here.

Contents: [1 The answer in short](#1-the-answer-in-short) ·
[2 What is drawn today](#2-what-is-drawn-today-measured) ·
[3 What a phone pixel can show](#3-what-a-phone-pixel-can-show) ·
[4 The types](#4-the-types-warsaws-walls-fences-and-rails) ·
[5 How a line gets its type](#5-how-a-line-gets-its-type) ·
[6 How a type is drawn](#6-how-a-type-is-drawn) ·
[7 Broken looks](#7-broken-looks-the-seam-with-the-drivable-city-plan) ·
[8 Cost on the phone](#8-cost-on-the-phone) ·
[9 Fallbacks and recovery](#9-fallbacks-and-recovery) ·
[10 The plan](#10-the-plan-in-phases) · [11 F's answers](#11-fs-answers) ·
[12 How this was measured](#12-how-this-was-measured)

---

## 1. The answer in short

1. **Every line now has a type, and the game still ignores it.** Step 5 wrote `ty` (37 types),
   `tc` (how sure), `sc` (class), `hz` (hazard) and `hs` (height by setting) on all 7,928 lines.
   The game draws by the old styles: 157 km of fence is one grey band, 62 km of wall one beige
   slab. The first phase makes the game read `ty`. That alone removes the grey band.
2. **"Texture" on this game's screen is not a brick pattern.** One pixel of the game's image is
   10 to 17 cm of street at the default zoom. What the player can read is the colour, the height,
   the outline (foot, cap, piers), the rhythm of posts every 2 to 4 m, and whether the thing is
   see-through. A type is those five things, plus a few big marks (graffiti, a poster band, ivy).
3. **Three ways to draw, in the order they are built.** (a) *Typed rows*: every type gets its
   colour, height and thickness, and light fences become thin posts and rails in the city mesh.
   No draw call, no shader. (b) *Panels*: light fences and hedges become instanced 2 m panels
   with one small shader, so they show bars and mesh and one panel can fall. One draw call per
   visible sector. (c) *The heavy kit*: walls get a foot, a cap, bays and piers as shaped geometry
   in the city mesh. No draw call, no shader.
4. **The building shader is not touched by any phase.** It stands at 501 of 505 on the Adreno
   budget. Every heavy detail is geometry and vertex colour on the shader's existing "prop" path.
   The second plans review asked that new wall geometry wait for the landmarks' own material
   (TD-9). It does not need to: the gate of each phase is that `building.gdshader` is unchanged
   and `check_shader_budget` still prints 501.
5. **Nothing a tester sees changes by default.** The look is picked by one key in the palette,
   `barrier_look`, which stays `classic` until F has looked at a build on the phone. Both city
   paths read it when the city is built, so a build is baked in one look. F's look is a device
   run or a build cut with the new look, with F's yes (section 9).
6. **The type rules need one more pass.** The photos of 2026-11-15 show that an unknown wall in
   the centre is nearly always a knee-high planter edge, not a 1.6 m wall, and that some unknown
   fences along kerbs are rows of bollards. Phase W3 mends this as a guarded map pass.
7. **Details are ranked by what reads as Warsaw at the phone's zoom** (section 6.6): see-through
   fences with a post rhythm first, then heights by setting, then foot, cap and piers, then
   gates, graffiti, posters, ivy and the night look. Most cost triangles only.
8. **The broken look** follows the memory that already runs (`soft_things.gd`): the hit panel
   lies down, tears or leaves a stub by its type, and stands up again when the city repairs it
   out of sight (section 7). This is what lets the "Miękkie miasto" switch go on for everyone.

## 2. What is drawn today, measured

From `game/map/centrum.json` on main (f9d5823, 2026-11-15), `lines` of kind fence, wall, hedge:
7,928 lines, 278.8 km, 30,831 segments.

| Kind | Length | Drawn as (the palette's `types`, read by `city_barriers.gd`) |
| --- | --- | --- |
| Fence | 188 km | no fence type in the old tags: a solid grey band 0.12 × 1.6 m (157 km). Railing: posts and two rails. Mesh: the same in grey |
| Wall | 70 km | no material: a beige slab 0.35 × 1.9 m (62 km). A material changes only the colour |
| Hedge | 21 km | a green slab 0.9 × 1.2 m |

What the data now says they are (`ty`, km):

| Type | km | Sure by | Class |
| --- | --- | --- | --- |
| `bars_black` | 59.2 | context 45.2, tag 14.1 | S |
| `mesh_panel` | 41.0 | context | S |
| `chain_link` | 31.6 | context 30.9 | S (1.7 H) |
| `wall_plaster` | 24.0 | context 14.1, **default 9.9** | H |
| `wall_stone` | 20.9 | tag | H |
| `hedge_low` | 19.7 | context 11.8, **default 5.9** | S |
| `fence_plain` | 17.4 | **default 17.2** | S |
| `green_fence` | 11.5 | context | S |
| `rail_tram` | 11.2 | tag 9.1 | H |
| `wall_precast` | 9.1 | context 7.1 | H |
| `wall_brick` | 4.1 | context 3.7 | H |
| `low_wall` | 3.9 | context | R 2.9 |
| `low_lawn` | 3.7 | context | S |
| `rail_street` | 3.4 | tag 2.5 | S |
| `noise_screen`, `basin_rim`, `parapet_concrete` | 2.2, 2.1, 2.2 | tag, context, tag | H, R, H |
| the stair balustrades, `deck_railing`, `guard_rail`, `hedge_tall`, `rail_waterfront` | 1.0 to 1.6 each | structure, tag | H (hedge S) |
| `gabion`, `ball_net`, `wood`, `bars_pier`, `glass_screen`, `hoarding` | under 1 each | tag | |

Sureness over all: tag 57.5 km (21 %), structure 10.9 km (4 %), context 177.4 km (64 %), default
33.0 km (12 %).

Beside the lines: 24.4 km of guard rails (`guards`), 20.7 km of structure walls (`walls`), 22
city-wall pieces. They keep their own builders.

All barriers together are about 458,000 triangles city-wide. A fence casts the shadow of a solid
band.

What is wrong with the picture, in order of metres:

1. 157 km of fence is an opaque grey strip. Real fences are see-through; this one reads as a wall.
2. 62 km of wall is one height and one colour with no foot, no cap and no piers.
3. Hedges are 1.2 m everywhere; in the parks they are knee-high or, in the fountain park by
   Wybrzeże Gdańskie, taller than a person.
4. An unknown wall in a square stands 1.9 m where the real thing is a 0.5 m planter edge
   (Plac Grzybowski, section 12).
5. OSM's own kind is sometimes wrong for the look (a mapped `fence` that is a concrete wall; a
   mapped `wall` that is piers with iron panels).

## 3. What a phone pixel can show

The city is drawn into a small pixel image and scaled up. The image has 480 to 828 lines; the
default view is 80 m tall, the closest 40 m, the widest 125 m; the camera looks down at 30°, so a
vertical face shows 87 % of its height.

| Zoom | One image pixel is | A 1.6 m fence is | A brick course (7 cm) | Bars 12 cm apart | Posts 2 m apart |
| --- | --- | --- | --- | --- | --- |
| Closest (40 m) | 5 to 8 cm | 17 to 29 px | about 1 px | 1.5 to 2.4 px | 25 to 40 px |
| Default (80 m) | 10 to 17 cm | 8 to 14 px | under 1 px | under 1.2 px | 12 to 20 px |
| Widest (125 m) | 15 to 26 cm | 5 to 9 px | no | no | 8 to 13 px |

So the detail ladder for a barrier is:

| Size of the detail | Examples | How it is shown |
| --- | --- | --- |
| Under 15 cm | bricks, bars, wires, boards, mortar | never drawn one by one. It becomes the **tone** (brick red with a speckle), or the **openness** (how much you see through) |
| 0.3 to 1 m | foot band, coping, panel joints, a poster band, a gabion's cage, a tag | 2 to 6 px: a band of another shade, or a tone change from one bay to the next. No thin lines: a 3 cm joint line flickers at this scale |
| 2 to 5 m | posts, piers, bay length, gates, steps in height, a slogan | clear shapes. This is where a type is recognised |
| The whole thing | height, thickness, straight or leafy outline, shadow | read first, at 40 km/h |

The rule for bars and meshes: draw **posts and the top rail solid, and fill the rest with as many
bars as there are pixels for**, never thinner than one pixel, fixed to the fence so they do not
crawl when the car moves. At the default zoom a 2 m panel then shows about five bars instead of
sixteen: what a pixel artist would draw. The panel trial (W4) checks this rule.

## 4. The types: Warsaw's walls, fences and rails

Class is the solidity class of `drivable-city.md`: H stops the car, S breaks, R is ridden over.
The class comes from the bake (`sc`); the look must never contradict it (rule R2):

- **H looks heavy**: closed from foot to top, at least 0.25 m thick, a dark foot band and a
  lighter cap, a shadow. Or a steel beam at bumper height.
- **S looks light**: at least half see-through or leafy, thin, no foot higher than 0.3 m, no
  shadow band, slim posts.
- **R looks low**: under 0.6 m, drawn as a kerb or a rim.

The exact numbers of each type's look are the rows of section 6.2. The tables here say what the
real thing is.

### 4.1 Light: fences, rails and hedges (Smash)

| Type | The real thing | Where | Height |
| --- | --- | --- | --- |
| `rail_street` | the street guard railing: grey galvanised steel, posts, a top rail, upright bars; older ones yellow | kerbs at crossings and stops, medians, Wybrzeże Szczecińskie, Aleje Jerozolimskie | 1.1 m |
| `rail_tram` | the fence between or beside tram tracks: black or dark green railing with bars | tram beds, platform backs (Marszałkowska) | 1.15 m |
| `bars_black` | black steel bars on a low concrete foot | tenement yards, churches, offices, gated housing | 1.6 to 2.0 m |
| `bars_pier` | iron panels between plastered or brick piers on a plinth | university, ministries, embassies, palaces, old parks | 2.0 to 2.5 m |
| `mesh_panel` | welded mesh panels, graphite on new estates and offices, green at schools and pitches | schools, playgrounds, dog runs, new estates, by the railway at the stadium | 1.2 to 2.0 m |
| `chain_link` | old wire netting on thin posts, grey, often leaning | allotments, garages, back plots, railway land | 1.5 m |
| `ball_net` | ball-stop net on tall posts | pitches | 4 to 6 m |
| `low_lawn` | the knee-high lawn guard: a flat rail on short posts, green or black | lawns and paths in parks and estates | 0.4 to 0.8 m |
| `wood` | board fence | rare (0.5 km) | 1.5 m |
| `hoarding` | building-site hoarding: sheet metal in white, blue or green with a banner band | building sites (Wola: blue on Wronia, green with a banner on Towarowa) | 2.0 m |
| `green_fence` | a fence grown over with ivy and bushes | villa gardens of Saska Kępa and Mokotów | 1.6 m |
| `hedge_low`, `hedge_tall` | clipped hedge | parks and squares (low), villas, embassies, the fountain park (tall) | 0.6 to 0.8 m, 1.5 to 3 m |
| `chain_posts` | posts with a chain | monuments, palace forecourts, the Old Town | 0.7 m |
| `fence_plain` | **the unknown fence** (F's answer 4): a thin dark see-through railing | wherever nothing is known | 1.4 m |
| `post_row` (new, W3) | a row of black bollards, no rail | kerbs of Wola's office streets, plaza edges (photos: Prosta, Grzybowska, Plac Grzybowski) | 0.9 m |
| `stadium_fence` (new, W3) | Stadion Narodowy's own tall perimeter fence: grey posts and bars | the stadium grounds (16 lines of 6.2 m that the rules now call lawn guards and bars) | 6.2 m |

### 4.2 Heavy: walls, screens and barriers (Hard)

| Type | The real thing | Where | Height |
| --- | --- | --- | --- |
| `wall_brick` | red brick with a cap and piers | old factories (Praga, Wola), church yards, barracks | 2.2 to 3.0 m |
| `wall_plaster` | rendered masonry, cream or grey | yards, institutions | 1.6 to 2.5 m |
| `wall_precast` | the precast concrete fence: posts with stacked slabs, grey, tagged and stained | works, depots, garages, railway land | 2.0 to 2.5 m |
| `wall_stone` | sandstone or pale concrete blocks with strong joints; on the boulevards a steel handrail on top and graffiti | the escarpment, palace gardens, the Vistula boulevards (Wybrzeże Gdańskie) | by `h` |
| `noise_screen` | steel posts with cassette panels, the top band clear | Trasa Łazienkowska, parts of Wisłostrada, the railway | 4 to 6 m |
| `gabion` | wire cages of stone | newer landscaping | by `h` |
| `glass_screen` | glass panes in steel posts | tram stops (Marszałkowska), terraces | 2.0 m |
| `guard_rail` | the steel beam on posts (exists) | fast roads, drops | 0.75 m |
| `parapet_concrete` | a solid upstand with a steel top rail | viaducts, ramps, the boulevards' upper edge | 1.1 m |
| `deck_railing` | steel posts and rails on a kerb upstand | decks with no model of their own, footbridges | 1.1 m |
| `rail_waterfront` | stainless posts and a top rail on a granite kerb | Vistula boulevards | 1.1 m |
| `low_wall` | a planter or terrace edge: granite, dark stone or weathered steel | squares, planters, terraces (Plac Grzybowski, the Palace of Culture) | 0.3 to 0.8 m |
| `balustrade*`, `basin_rim`, `island_edge`, `city_wall` | exist, with F-approved looks | stairs, fountains, islands, the Old Town | as now |

Bridge parapets belong to each bridge's own model. Retaining walls (`walls`) and the guard rails
of `guards` keep their own builders; their looks are W7's last item.

**A hazard fence is not always a crash barrier.** The bake writes the class (`sc: H`) and the
reason (`hz`), and the type is already picked from the reason (`object_types.py` `HAZARD_LOOK`:
deck → `deck_railing`, water → `rail_waterfront`, drop → `parapet_concrete`).

**Heights by setting** are in the data as `hs` (7,577 lines; 348 have OSM's own `h`). The game
does not read `hs` yet. W2 does.

## 5. How a line gets its type

Built in step 5 (`tools/object_types.py`, verify step `objecttypes`). First match wins: a street
pass's override by stable id, a landmark site's own wall, OSM's tags, the structure it belongs
to, the land beside it, its shape, a default by kind. The 20-sample check of each rule is in that
file's comment above `DROPPED`; the contact sheets are in `/mnt/project-files/walls-research/step5/`.

What the check found, and what follows for the look:

- Most context rules have **fewer than five judged lines**: yard and school fences stand behind
  buildings and are not on street photos. They are unproven, not wrong. So the look of the big
  context types (`bars_black`, `mesh_panel`, `chain_link`: 132 km) must be **quiet and close to
  each other**: thin, dark or grey, see-through. A wrong guess then costs little. The loud looks
  (piers, brick, hoardings, graffiti) go only where a tag, a structure or a sweep names the type.
- Church, institution and embassy fences as `bars_pier` were dropped (3 right, 2 wrong, 15 with
  no photo). `bars_pier` is 0.1 km today. It comes back by street sweeps and by landmark sites.
- Building sites were dropped (the outlines are years old). `hoarding` is placed by sweeps.

**The type fixes of 2026-11-15** (phase W3, a guarded map pass; evidence in section 12):

| # | Finding | Rule | Proof |
| --- | --- | --- | --- |
| 1 | A `default` wall in a square or a pedestrian zone is a planter edge. Plac Grzybowski: 10 of 10 lines; the Palace of Culture's: already low | `ctx_square`: a wall that no other rule names, with half its samples inside a `ped_zones` outline or a plaza surface, or within 4 m of two or more footways and no building within 6 m, is `low_wall`, `hs` 0.5, class by height | 16 of 20 or dropped |
| 2 | A `default` fence along a kerb with no building near is often a bollard row (Prosta, Grzybowska: 2 of 5 photos) | `kerb_posts`: a `default` fence with 60 % of its samples within 2.5 m of a carriageway edge and no building within 6 m is `post_row`, class S | 16 of 20 or dropped; the row exists in the palette either way, for sweeps |
| 3 | The stadium's sixteen 6.2 m fences are typed `low_lawn`, `bars_black`, `fence_plain`, `parapet_concrete` | no light type but `ball_net` may stand over 3 m: a fence with a mapped height of 4 m or more that is not by a pitch is `stadium_fence` inside the stadium's box, `ball_net` elsewhere. The stadium's lines also go into `game/data/road_objects.json` by id, as the plan's section 4 asked | the type plot at the stadium |
| 4 | Hedges in the fountain park (Skwer 1 Dywizji Pancernej) are 3 to 5 m by their tags and read as `hedge_low` | a hedge with `h` of 1.5 m or more is `hedge_tall` | `--selftest` |
| 5 | `object_types` is not in `tools/check_post_passes.py` | it joins the list, so the pass is held like the other five (TD-25) | `postpasses` green |

The default share is recorded in `check_map_data.py` and only goes down: 12 % today, 9 % or less
after W3.

**Built in W3 (2026-11-15)**, `tools/object_types.py` version 2 (`fix_types`), verdicts and sheets
in `/mnt/project-files/walls-research/w3/`:

- `ctx_square`: 31 walls, 0.9 km, H to R (10 of 11 judged photos right, 7 of 18 with no usable
  photo; narrowed: a wall OSM maps 1.2 m or taller is left out, the one wrong line).
- `kerb_posts`: **dropped** (0 of 6 judged right: bar fences on piers, lawn fences along an estate's
  drive, a site fence; no bollard row). The `post_row` row stays for sweeps.
- The tall fences: on the current map 11 of the stadium's sixteen 6.2 m fences were already
  `ball_net` (the stadium's outline is a pitch setting) and 5 are hard by the podium's drop. They
  are not #808's 2.3 m perimeter railing (mapped height, on the podium's edge 166 to 196 m from the
  stadium's centre), so the rule gives `ball_net` everywhere and `stadium_fence` is #808's id alone:
  its 19 perimeter lines carry it by id (`road_objects.json` `types`, with the 11 nets), and its
  `looks` row is `draw: keep` (one look in every look). One more line changes city-wide (a 6 m
  school fence). OSM-tagged tall railings (Legia's 6.4 m) keep their tag's type.
- `hedge_tall`: 27 hedges, 2.0 km, all in the Royal Castle's lower garden (12 of 12 judged right).
- `object_types` joins `check_post_passes.py`.
- The default share: 11.9 % to 11.5 % (fences 9.1 %), the new ratchets in `check_map_data.py`. The
  9 % aim needed the bollard-row rule (parked in `docs/QUESTIONS.md`).

## 6. How a type is drawn

### 6.1 The palette owns the look, and one key picks it

`game/data/object_palette.json` is the one home of looks (`docs/architecture/extending.md`, row
"A wall, fence or hedge style"). The first plan's `barrier_kit.json` was never made and is not
needed. Two additions:

- **`"barrier_look"`**: `"classic"`, `"typed"` or `"panels"`. `classic` is today's drawing, by the
  `types` rows, bit for bit. `typed` is W2. `panels` is W4 onward. The key stays `classic` on main
  until F says so after a phone look. `--barriers=classic|typed|panels` overrides it for a run of
  the runtime city and for `bake_city.gd`. A prebuilt city is baked in one look; the prebuilt
  index is stamped with it and the game prints one line when a flag asks for another.
- **`"looks"`**: one row per `ty` (section 6.2), read through `solidity.gd` (`look_row(ty)`).
  The existing `types` rows are not edited by any phase, so the classic look cannot drift. They
  are deleted in W10, when classic retires.

`city_barriers.gd` decides the style of a line as today (the site walls, the garden rings, the
stairs, the placed styles, the overrides). Under `typed` or `panels`, **only where that chain
ends at a generic style** (the kind's own row, or what `_mapped_style` made of it) the line is
drawn from its `ty` row instead. Every hand-placed and F-approved look stays as it is.

Height of a typed line: OSM's `h` clamped to the row's `h_range`, else `hs`, else the row's `h`.
The collider is made from the same segments at the drawn height, so R2 holds. What collides and
what breaks does not change with the look (the soft list is the same lines).

### 6.2 The rows

Colours are sRGB hex. "alt" is a second colour that a share of the lines take, picked by a hash
of the line's stable id, so a street does not flicker between them. Posts stand every 2 m or 4 m:
a multiple of the 2 m panel that `soft_things.gd` remembers.

**Light rows** (`family: light`). `draw` is what W2 draws; from W4 a light row is a panel.

| `id` | `draw` | `h` | `thick` | `colour` | alt (share) | posts: every, width | rails | foot: h, colour | `open` | `bars` | `top` | `broken` | `debris` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `fence_plain` | rail | 1.4 | 0.05 | `#2a2e33` | | 2, 0.06 | 2 | | 0.85 | 0.25 | flat | down | metal |
| `bars_black` | rail | 1.8 | 0.05 | `#25282c` | | 2, 0.07 | 2 | 0.3, `#9a968e` | 0.70 | 0.12 | flat | down | metal |
| `bars_pier` | rail | 2.2 | 0.05 | `#25282c` | | 4, 0.07 (piers in W7) | 2 | 0.5, `#b8b0a0` | 0.70 | 0.12 | flat | down | metal |
| `mesh_panel` | rail | 1.6 | 0.05 | `#3d4145` | `#3f6b4a` (0.4) | 2, 0.06 | 1 | | 0.65 | 0 (a tint, ribs every 0.5 m) | flat | down | metal |
| `chain_link` | rail | 1.5 | 0.04 | `#8b9196` | | 4, 0.05 | 1 | | 0.78 | 0 | sag | torn | metal |
| `ball_net` | rail | 5.0 | 0.04 | `#6d7378` | | 4, 0.10 | 1 | | 0.88 | 0 | flat | torn | metal |
| `stadium_fence` | rail | 6.2 | 0.06 | `#9aa0a6` | | 4, 0.12 | 2 | | 0.80 | 0.15 | flat | down | metal |
| `rail_street` | rail | 1.1 | 0.05 | `#8d9398` | `#c9a227` (0.1) | 2, 0.06 | 2 | | 0.75 | 0.13 | flat | down | metal |
| `low_lawn` | rail | 0.6 | 0.04 | `#2f4f36` | `#25282c` (0.3) | 2, 0.05 | 1 | | 0.90 | 0 | flat | gap | metal |
| `chain_posts` | rail | 0.7 | 0.04 | `#2a2e33` | | 2, 0.10 | 1 | | 0.95 | 0 | sag | gap | metal |
| `post_row` | rail | 0.9 | 0.12 | `#1f2226` | | 2, 0.12 | 0 | | 1.0 | 0 | flat | gap | metal |
| `green_fence` | rail | 1.6 | 0.05 | `#25282c`, leaf `#4a7436` | | 2, 0.07 | 2 | 0.3, `#9a968e` | 0.30 | 0.12 | leafy | stub | leaf |
| `wood` | slab | 1.5 | 0.08 | `#7f6248` | | 2, 0.08 | | | 0.08 | 0.12 | flat | gap | wood |
| `hoarding` | slab | 2.0 | 0.06 | `#dcdcd6` | `#2d5fa8` (0.3), `#3c7a4c` (0.2) | 2, 0.06 | | | 0 | 0 | flat | flat | sheet |
| `hedge_low` | slab | 0.8 | 0.9 | `#4f7d39` | | | | | 0 | 0 | leafy | stub | leaf |
| `hedge_tall` | slab | 1.8 | 1.1 | `#47723a` | | | | | 0 | 0 | leafy | stub | leaf |

`h_range`: `[0.4, 2.5]` for the fences, `[3.0, 8.0]` for `ball_net` and `stadium_fence`,
`[0.3, 1.0]` for `low_lawn`, `chain_posts` and `post_row`, `[0.4, 1.4]` for `hedge_low`,
`[1.4, 5.0]` for `hedge_tall`.

**Heavy and low rows** (`family: heavy` or `low`). W2 draws each as a slab in `colour` at `thick`;
W7 adds what the other columns say.

| `id` | `h` | `thick` | `colour` | alt (share) | foot: h, darker by | cap: h, overhang, colour | bay, shade step | piers: every, width | `marks` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `wall_plaster` | 1.6 | 0.30 | `#cfc8b8` | `#b9b6ae` (0.4) | 0.3, 0.12 | 0.10, 0.04, `#8f5a48` (alt `#a9a59d`) | 4 m, 0 | | graffiti, ivy, stain |
| `wall_brick` | 2.4 | 0.38 | `#a8644b` | | 0.35, 0.12 | 0.12, 0.04, `#c9c2b4` | 3.5 m, 0.03 | 3.5, 0.5 | ivy, stain |
| `wall_precast` | 2.4 | 0.12 | `#a9a69f` | | | | 2.5 m, 0.05; posts 0.15 wide stand 0.03 proud | | graffiti, poster, stain |
| `wall_stone` | 2.0 | 0.45 | `#b9b2a5` | | 0.3, 0.08 | 0.18, 0.06, `#c8c2b6` | 3 m, 0.04 | | graffiti, stain; a steel top rail (`#6c7075`, 0.9 m) where `hz` is water or drop |
| `noise_screen` | 4.0 | 0.15 | `#5f7a5c` | `#8a5a3c` (0.4) | | top band 1.0 m, `#b9cdd0` | 4 m, 0.03; posts 0.2 wide `#6c7075` | | stain |
| `gabion` | 1.6 | 0.8 | `#8f897e` | | | | 1 m, 0.07 | | |
| `glass_screen` | 2.0 | 0.06 | `#a9bcc0` | | 0.15, 0.2 | | 2 m, 0; posts 0.08 `#6c7075` | | |
| `parapet_concrete` | 1.1 | 0.25 | `#a9a59d` | | | the upstand is 0.8 m; a rail `#6c7075` on posts every 2 m above it | 5 m, 0.03 | | stain |
| `deck_railing` | 1.1 | 0.05 | `#6c7075` | | 0.2, `#a9a59d` (a kerb upstand) | | | | drawn as `rail`: posts every 2 m 0.08 wide, 2 rails |
| `rail_waterfront` | 1.1 | 0.05 | `#b4b8bc` | | 0.3, `#8f8f8a` (granite kerb) | | | | drawn as `rail`: posts every 2 m, 1 rail |
| `guard_rail` (a line) | 0.75 | 0.06 | `#a7abb0` | | | | | | drawn as `rail`: posts every 4 m 0.1 wide `#6c7075`, 1 rail |
| `low_wall` | 0.5 | 0.4 | `#b3ada3` | `#5a5550` (0.3) | | 0.06, 0.03, lighter by 0.08 | | | |

`draw: keep` (drawn by today's chain, whatever the look): `rail_tram`, `balustrade`,
`balustrade_rail`, `balustrade_white`, `basin_rim`, `island_edge`. Not drawn: `site`, `removed`.

Later phases read `open`, `bars`, `top`, `broken`, `debris`, the foot, cap, bay, pier and `marks`
columns. They are written into the palette in W2 so that the look is decided once, here.

### 6.3 Typed rows: posts and rails in the city mesh (W2)

A new draw kind in `city_barriers.gd`, `rail_lite`, for the rows marked `rail`:

- a post is two crossed upright quads, `width` wide and the line's height tall (4 triangles);
- a rail is one upright quad 0.06 m tall: one under the top, and with `rails: 2` one at 0.35 m;
- a foot, where the row has one, is a slab of the foot's height and colour, 0.2 m thick;
- the building shader draws both sides of a triangle (`render_mode cull_disabled`), so one quad
  is a rail seen from both sides. Vertex colour only, the "prop" code in UV2, as every barrier.

It costs about 2.5 triangles a metre; today's `railing_along` costs about 7.5. It has no bars and
no mesh: at the default zoom it reads as a see-through fence of the right height and colour with
the right post rhythm. That is the whole of what the first plan called "a type", except openness.
It stays in the code after panels arrive as the cheap step of the fallback ladder (section 9).

Rows marked `slab` use `wall_along` as today, with the row's numbers.

### 6.4 Panels: instanced, with their own shader (W4 to W6)

- **One mesh for everything**: a unit box without a bottom (10 triangles). An instance is one
  piece of one panel: placed at its foot, its x axis the piece's vector along the line (the slope
  is in it, so posts stay upright), its y axis the height, its z axis the thickness.
- **A panel is 2 m of the line**, index `floor(metres along the line / 2)`: the same index
  `soft_things.gd` remembers (`city_barriers.gd` `PANEL`). A panel that crosses a corner of the
  line is two pieces with one index. Pieces under 0.05 m are skipped, as segments are today.
- **One `MultiMesh` per sector**, a child of the sector's root named `Panels`, built by
  `city_barriers.gd` from the same loop that draws the lines, on both city paths, and saved in
  the prebuilt sector's scene. Written through `instance_buffers.gd`. No shadow casting.
  Visibility range 400 m. The sector's root also carries a `panels` meta: per soft line id, the
  first instance and the panel index of each of its pieces, so a hit finds its instances.
- **Custom data, four floats**: the row's index; the metres along the line at the piece's start
  (so the post rhythm runs through corners); the state (0 whole, 1 down, 2 torn, 3 stub or gap);
  a seed from the line's stable id (the alt colour, the leafy edge).
- **One small shader, `panel.gdshader`**: lit, diffuse only (no specular), `cull_disabled`. It
  reads the row from a lookup texture (8 texels a row, 64 rows, made from the palette's `looks`
  when the game starts; a texture read is not control flow). In the fragment, with `u` the
  metres along the line and `v` the metres up, and `px` the metres one image pixel covers
  (`fwidth(u)`):
  - post: within half the post's width, or half a pixel if that is more, of a multiple of the
    post spacing;
  - rails and foot: bands in `v`, never thinner than a pixel;
  - bars: the row's spacing doubled until bars are at least 2.5 pixels apart
    (`spacing × exp2(ceil(log2(2.5 × px / spacing)))`, never under the spacing), each bar one
    pixel wide, placed in `u`, so they are fixed to the fence;
  - a tint fill (`bars: 0`): a stipple on a grid fixed to the fence whose cell is the pixel size
    rounded up to a power of two times 8 cm; a cell is kept when its hash is under `1 - open`;
  - `top: sag` lowers the top edge by up to 8 cm between posts; `top: leafy` cuts the top edge by
    a noise of the seed and darkens the lowest 0.2 m;
  - everything is `step`, `mix` and `max`; one `if` holds the `discard`. The count must stay
    under 200 of the lit budget of 260 (`check_shader_budget` from the first commit).
  - It reads the shared day, night and rain globals (`night.gdshaderinc`), never its own copy.
    At night a row's colour is lifted by 0.15 toward grey, so black bars do not vanish on dark
    ground.
- **States** are written by `main.gd`'s reaction to `soft_things.broke` and `repaired` through a
  small script, `panel_states.gd` (W6): it sets the instance's state and, for `down` and `flat`,
  its transform (the box laid on the ground on the far side of the hit). The whole transform is
  put back on `repaired`, from the baked buffer.

**Built in W4 (2026-11-16)**, behind `barrier_look` `panels` (the palette's key stays `classic`):

- The six rows carry `"panel": true` in the palette's `looks`; under `panels` their lines draw no
  triangles in the city mesh, only pieces in the sector's `Panels` (city_barriers.gd
  `panel_along`, map_builder.gd `_build_panels`), and file the colliders and soft lines their
  typed drawing files, face for face (`check_barrier_look` 6 and 7; the sloppy driver's route
  set A gives the same 232 contacts, byte for byte, under `typed` and `panels`). Every other row
  draws as `typed`.
- 96,325 pieces city-wide in 102 sectors, 4,484 of the 4,485 lines of the six rows (the one left
  keeps its classic drawing, as it does under `typed`); the same count per sector on both city paths (`check_barrier_look --paths
  --all`, 112 sectors), and the whole city's build (`--monolithic`) holds the same 102 tiles as
  the sectors, buffer for buffer (`check_streaming` identity). Prebuilt sectors 185.3 MB
  (classic 185.5, typed 188.5).
- The numbers live in `game/scripts/panel_rule.gd` (pure); `check_panel_rule` (verify
  `panelrule`) holds the shader's formulas to it and to the gate at 5, 10, 17 and 26 cm a pixel.
  `panel.gdshader` costs 3 by `check_shader_budget`'s counter, against its cap of 200 (its one
  `if` holds the `discard`); `building.gdshader` stays at 501. The lookup texture is 8 x 64 RGBA floats, made with the
  material in `_make_shared` (the prebuilt city keeps it in `map/shared/panel.res`).
- Draw calls (probe, medians of 3, `panels` against `typed`): main pass +3 at the spawn, +2 at
  the river view, +5 zoomed out, +2 from the helicopter, +3 at night; shadow pass +0 everywhere.
- Not built, each an open question: the "visibility range 400 m" (the camera sits 500 m back, so
  a range in metres hides everything; none is set); the Adreno 6xx fallback reaches only the
  runtime city (a prebuilt city baked `panels` has no typed fences to fall back to).

**Built in W5 (2026-11-20)**, behind `barrier_look` `panels` (the palette's key stays `classic`):

- Every light row but `rail_tram` carries `"panel": true`: the six of W4 and `green_fence`,
  `low_lawn`, `ball_net`, `wood`, `hoarding`, `hedge_tall`, `chain_posts`, `post_row`,
  `stadium_fence` and `bars_pier`, their numbers as the rows have them (none changed). Under
  `panels` no light line is drawn in the city mesh but the tram's railing (`draw: keep`, 181 lines,
  a hard rail; `check_barrier_look` 7 names them) and `bars_pier`'s posts: its row's `post.in_mesh`
  keeps them in the city mesh where typed stands them (the piers until W7), its panels hold the iron
  between, so a fallen panel leaves them standing. `chain_posts` and `post_row` have no line on
  the map yet.
- `stadium_fence` (#808) keeps its classic railing under `classic` and `typed`; under `panels` its
  19 lines are panels of its row at the types row's 2.3 m, posts every 1.5 m 0.06 wide (the row's
  new `post`, railing_along's), the 0.4 m dark band, bars 0.12; their colliders and soft list are
  railing_along's, face for face (`check_barrier_look` 6); the gates are drawn as ever.
- `panel.gdshader`: `sag` lowers the top rail and the fill under it by 4 t (1 - t) x 8 cm between
  posts; `leafy` cuts the leaves' top by a value noise of the seed (at most 0.15 m, 0.3 m cells)
  and darkens the lowest 0.2 m by 0.75; a hedge's top face sits 0.15 m lower so its sides' leafy
  edge stands over it. A row `open` 0.1 or less (wood, hoarding, the hedges) is closed: no holes,
  its bars drawn as joints 0.72 darker. A row with a `leaf` colour (green_fence) has leaves on
  1 - open of its fill's cells, in front of its bars. Alt colours by the seed as in W4 (hoarding's
  two). Its count stays 3 of the cap 200; `building.gdshader` unchanged from main (503 of 505).
- The pixel rule at a grazing view: a panel seen nearly end-on (a fence running almost along the
  view) has a pixel footprint metres long one way and centimetres the other, and W4's floors took
  the long side (`fwidth`), so every post, rail and bar was a pixel wide and together they filled
  the panel: a solid dark band (Pole Mokotowskie's lawn edge). The floors (never the bar spacing
  or the fill's cell) are now capped at `GRAZE` (2) times the footprint's narrow side; a face along
  u or v (the top, the ends) keeps W4's. Seen at 45 degrees or more nothing changes, pixel for
  pixel; at 4 to 6 degrees a third less is dark; the lawn edge's band went from 8 to 10 pixels
  wide to 4 to 6, a railing with its posts (typed: 2 to 4).
- Broken (section 7): `gap` is state 4, the box squashed to a point in `vertex()` (no fragment, no
  discard); a wood row's gap is state 5, the box laid down as a fallen panel and only two boards of
  it kept (at 0.6 and 1.35 m of the panel); `flat` lies down as `down`, the face the car saw up;
  `stub` (green_fence, hedge_tall) the low brown box, solid; `torn` (ball_net) and `down`
  (stadium_fence, bars_pier) as W6. `bars_pier`'s three lines are within the landmark guard, so
  they never break today. `check_panel_states` drives through stadium_fence, chain_link,
  green_fence, low_lawn (the stadium's grounds), ball_net, wood and hoarding on both paths.
- 110,185 pieces city-wide in 102 sectors, 5,435 of the 5,438 lines of the panel rows (the three
  left are left out in every look, before any drawing: a site wall, the Palace's forecourt, the
  tribune, the river or a street pass's REMOVE); prebuilt sectors 186.2 MB
  (classic 187.2, typed 190.2).
- Draw calls (probe, prebuilt, `panels` against `typed`): main pass +3 at the spawn, +2 at the
  river view, +3 zoomed out, +3 from the helicopter, +3 at night; shadow pass +0 (-1 zoomed out);
  a broken panel (boards, gap) adds none.

Why not the other ways: more patterns in `building.gdshader` has no room; bars as real geometry
for 190 km is about 4 million triangles and cannot fall over; a photo texture per type shows
nothing at this pixel size and adds a material per type; alpha blending needs sorting and costs
fill on the phone's GPU.

### 6.5 The heavy kit: shaped geometry in the city mesh (W7)

A wall builder beside `wall_along`, `wall_kit`, that makes, per run of a line: the foot band; the
body cut into bays, each bay a shade step from the last (so the rhythm survives any zoom); the
cap with its overhang; piers or proud posts at the spacing; and an end piece (a pier, or a sloped
end) where step 10 of the objects plan put a taper. Noise screens get posts, opaque lower panels
and the pale top band. `bars_pier` gets its piers here, with the plinth; the iron between them is
a panel.

A pier of an S line gets a **diamond collider** (a 0.5 m square turned 45° to the line), filed as
class `wall`. A car that clips it is turned into the bay instead of stopped. This is F's answer
1: the panel falls, the piers stand. The gate is the sloppy table at the review places: no new
dead stop.

No new material and no shader change. Cost: triangles only (section 8).

**Built in W7 (2026-11-20)**, behind `barrier_look` `typed` and `panels` (the key stays `classic`):

- `city_barriers.gd` `wall_kit` draws every heavy or low `slab` row that has a foot, a cap, bays or
  piers (the nine of 6.2: `wall_plaster`, `wall_brick`, `wall_precast`, `wall_stone`,
  `noise_screen`, `gabion`, `glass_screen`, `parapet_concrete`, `low_wall`) from the row's numbers,
  the same under `typed` and `panels`: the foot a band of the face `darken` darker; the body cut
  into bays, every other one `step` darker (no cut where `step` is 0); the cap a coping `over`
  wider each side in its colour (`wall_plaster`'s `alt` cap with the line's alt colour,
  `low_wall`'s the line's colour lightened); with `over` 0 a band of the face (the noise screen's
  pale 1 m top); `parapet_concrete` its 0.8 m upstand and a rail on posts every 2 m to 1.1 m;
  piers (`wall_brick`: 0.5 m every 3.5 m, rising 0.15 m, capped in the cap's colour) and proud
  posts at the bays' joints (`wall_precast` 0.15 m, 0.03 proud, 0.08 m over the top, a shade
  darker; `noise_screen` and `glass_screen` steel grey); at each end of a run a pier or a post
  (the end piece), else end faces; the long faces mitred at corners (up to a 120 degree turn), so
  a run has no inner end faces and no notch outside a corner. The kit's own shape is in
  constants (`KIT_*`); the rest is the row's.
- The end piece is a pier or a post, never a sloped end: step 10 of the objects plan (collider
  tapers) has not run, so there is no taper to follow yet.
- `bars_pier` (`_pier_fence_kit`): its row gains `pier` (every 4 m, 0.5 m square, the plinth's
  `#b8b0a0`) and a plinth thickness (`foot.thick` 0.3): the plinth is a slab in the city mesh and
  the piers rise 0.15 m over the iron; between them the rails (typed) or W5's panels (whose own
  foot band stands inside the plinth). On a soft line each pier files a diamond collider (0.5 m
  square turned 45 degrees, class `wall`, from 0.3 m under the ground to 1.5 m over the pier);
  none on a hard line or with the soft switch off (so `--no-soft` files main's faces). The three
  `bars_pier` lines on the map are inside the landmark guard, so today none stands.
- `wall_stone`'s `top_rail` (a 0.9 m rail on posts every 2 m) stands where the line's `hz` is in
  the row's list (water, drop): 8 lines by the river. Wybrzeże Gdańskie's boulevard walls have no
  `hz` (the bake writes one on a wall only when a hazard made it hard, and a 2 m wall is hard by
  its height), so they get no rail though the photos show one: an open question.
- Retaining walls (`map_builder.gd` `_build_walls`): under a look other than classic the coping
  gets a lip 0.06 m out of the face and 0.15 m deep.
- Colliders: every wall's are `wall_along`'s at the row's thickness and the line's height, face
  for face (`check_barrier_look` 3), and the pier diamonds; nothing else changed.
- Cost (the whole map built on a flat map): barrier triangles typed 688,324 -> 842,210, panels
  186,162 -> 340,118 (+0.154 M each, the gate +0.7 M); typed city mesh vertices (both paths)
  26,694,768 -> 27,225,948; draw calls unchanged at the four probe views and at night.

### 6.6 The details, ranked

Ranked by how much each makes the city read as Warsaw at the default zoom, with what it costs.

| # | Detail | Reads as | Drawn by | Cost | Phase |
| --- | --- | --- | --- | --- | --- |
| 1 | See-through fences with a post rhythm, in the type's colour | the single biggest change: 157 km stops being a grey wall | `rail_lite`, then panels | triangles; then one draw call a sector | W2, W4 |
| 2 | Heights by setting (`hs`): knee-high park hedges and planters, 2.4 m works walls, 6 m nets | streets open up; squares stop looking walled in | the row's height | none | W2 |
| 3 | Planter edges in squares, bollard rows, the stadium's fence | the centre's real street furniture | W3's pass, W2's rows | none | W3 |
| 4 | Bars and mesh by the pixel rule; green or graphite mesh; sagging wire | fence kinds tell apart at close zoom | panel shader | the shader | W4, W5 |
| 5 | A panel that falls, a net that tears, a hedge with a gap | the city answers the car | panel states | a buffer write on a hit | W6 |
| 6 | Foot band, cap and bays on walls; brick piers; precast posts | walls stop being slabs; brick reads as Praga and Wola | `wall_kit`, vertex colour | triangles | W7 |
| 7 | Piers with iron panels between them | the university, ministries, embassies | `wall_kit` piers + panels | triangles | W7 |
| 8 | Noise screens with posts and a pale top band; boulevard walls with a handrail | Trasa Łazienkowska, the Vistula | `wall_kit` | triangles | W7 |
| 9 | Gates and gaps where a path or a drive crosses a line | yards read as entered, and the car gets through | W8's pass; two taller posts and open leaves in the city mesh | triangles; a map pass | W8 |
| 10 | Graffiti: colour patches low on precast, plaster and boulevard walls; a few big slogans | Wola, the railway, the boulevards (F's answer 2) | quads in the city mesh 2 cm off the wall, vertex colour; slogans as posters on `props.gd`'s poster path (`poster.gdshader`) | triangles; no draw call if the existing poster item is reused, else one per sector with slogans in view | W9 |
| 11 | Hoardings with parody developer banners | building sites (F's answer 3) | panel row plus a banner on the poster path | as 10 | W9 |
| 12 | Ivy over wall tops and villa fences; drip stains under copings | age | green and dark quads by seed, vertex colour; the panel's `leafy` top | triangles | W9 |
| 13 | Night: bars lifted off the dark ground; a pale top band that catches the sky | fences stay readable at night | the panel shader's globals; vertex colour | none | W4, W9 |
| 14 | Rain: darker feet and wet caps | weather | the shared rain global in the panel shader; nothing for the city mesh (the building shader does its own) | none | W4 |

Not planned: scrape marks on hard walls, lamps on gate piers (a light each), true glass
transparency for noise screens (a blended material), textures of bricks or boards.

### 6.7 Gates and gaps (W8)

**Built in W8 (2026-11-20)**, behind `barrier_look` `typed` and `panels` (the key stays `classic`):

- The pass `tools/barrier_gates.py` (TD-25: stamp-guarded, last in `bake_osm.py`, in
  `tools/check_post_passes.py`, verify step `barriergates`) writes on S and H fences, walls and
  hedges without a hazard reason: `g`, the gaps where a footway, cycleway or crossing's centre line
  crosses the line (strictly, or through OSM's gate node: a vertex both share, the way going on to
  both sides), the way's width + 0.4 m over the crossing's sine; and `ge`, a gate post at a line's
  end that faces an opening the bake already cut across a way (`clear_carriageways` for drives,
  object_fixes L4 for footways). Not at a deck or in a tunnel; line ids, pieces and panel indices
  stay. Main's map: 761 lines, 326 gaps (834 m), all by footways; 0 by service roads (every line was
  already cut out of the drives); 556 gate ends, 244 by paths and 312 by service roads.
- A footway that only ends on a line (128) gets no gap. An end more than 0.15 m inside the way's
  width gets no post (66 path ends).
- The photo check (street photos nearest each point, walls-research/w8/photos/): the footway gaps
  19 right of 20 judged (the wrong one a closed gate with a no-entry sign at Port Czerniakowski); the
  open leaves at drives failed: of 14 service openings the photos showed, 6 are gates and 8 are open
  car-park mouths, a plaza drive, a barrier arm, a roller shutter, low lawn fences. So no leaves:
  `LEAVES = False` in the pass, the drives get posts only. The leaf rule (two open leaves swung back
  against the line on the yard side, the side the drive runs on for longer) stays behind the switch,
  for a better test (OSM's `barrier=gate` nodes, which the map does not keep yet).
- `city_barriers.gd`: a line with a typed look and gates is drawn as its pieces between the gaps,
  each the old way, with `_soft_run` and `_panel_run` at the piece's own metre (soft segments and
  panel indices are the whole line's); posts (`_gate_kit`) at each gap's edge and each `ge` end,
  0.3 m taller than the line, 0.14 m square (on a wall its thickness + 0.08, in the wall's colour
  lightened), centred half their width inside the line, from 0.2 m under the ground. They file no
  collider of their own: the line's collider holds them and stops at the gap, so the car's openings
  keep their width. Not on the stadium's railing (#808, its own gates) nor on lines drawn by a placed
  or site style. Classic ignores `g` and `ge`: its per-sector hashes are main's on both paths.
- Drawn on the whole map (flat build): 710 lines, 311 gaps, 1,033 posts. Barrier triangles typed
  842,210 -> 852,264, panels 340,118 -> 352,534 (panel pieces 110,185 -> 109,655); collider faces of
  walls 41,324 -> 41,268; typed city mesh vertices (both paths) 27,226,683 -> 27,256,845.
- The car: route set A with the sloppy driver under typed, 228 -> 229 contacts and 15 = 15 dead stops;
  the one more is a scrape along Okopowa's tram railing split in two by the physics' numerics (with
  only one gap 368 m away taken out the run is main's, byte for byte). The 30 fence contacts are
  along main streets (Prosta, Towarowa, Okopowa, Poniatowskiego ...), none at a path or a drive, so
  gates cannot move them.
- The wander run (typed): traps 0 -> 0; 1,613 -> 1,608 lines tested (5 tested where a gap now is),
  ok 1,548 -> 1,544, miss 65 -> 64.
- Draw calls at the five probe views: typed equal; panels equal but the helicopter's main pass, 124 ->
  123. Prebuilt sectors +0.05 % (typed and panels). `check_solids` TOTAL_TYPED unchanged (46,459).
- Shots (walls-research/w8/shots/): a Wola yard's footway, LO Batorego's drive on Myśliwiecka, Park
  Ujazdowski's railing (Pole Mokotowskie is south of the map), an iron gate between piers (line
  114), the mesh fence by the stadium: gaps and posts read at 26 m; the same on both paths.

## 7. Broken looks: the seam with the drivable-city plan

`soft_things.gd` (merged, #776) keeps each broken panel by the line's stable id and the panel's
index for the session, and repairs it out of sight after about ten minutes. It emits
`broke(id, panel, kind, at, direction, speed)` and `repaired(id, panel)`, and answers
`is_broken(id, panel)`. Today only debris shows a break; the fence stays drawn. W6 closes that.

The broken look, by the row's `broken`:

| `broken` | Types | When the car goes through | What stays until the repair |
| --- | --- | --- | --- |
| down | `fence_plain`, `bars_black`, `bars_pier`, `mesh_panel`, `rail_street`, `stadium_fence` | the panel swings down away from the hit; a clang; bars fly | the panel flat on the ground, a shade darker, a few degrees askew. Neighbours' posts stand. For `bars_pier` the piers stand with an empty bay |
| torn | `chain_link`, `ball_net` | the net tears | the fill gone in that panel, the posts standing |
| gap | `low_lawn`, `chain_posts`, `post_row`, `wood` | flattened; boards fly | nothing drawn in that panel (for `wood`: two boards on the ground) |
| flat | `hoarding` | the sheet falls flat | the sheet on the ground, banner side up |
| stub | `green_fence`, hedges | leaves burst | a gap with a low brown stub, a quarter of the height |
| notch | `low_wall` of class S (0.6 to 1.2 m), later | dust, bricks | the bay at 0.2 m in a rubble tone (step 9c of the objects plan, not this stage) |
| none | every Hard type | nothing breaks | nothing |

How it is wired (W6):

- `main.gd` connects `broke` and `repaired` to `panel_states.gd`, which finds the sector's
  `Panels` and the line's instances in its `panels` meta and writes the state.
- When a sector comes in, `panel_states.gd` asks `soft_things.is_broken` for the lines in its
  meta and sets those panels down, so a broken fence is still broken after a drive round the
  block.
- Debris colour comes from the row (`debris`), replacing `soft_things.gd`'s `DEBRIS_COLOUR`
  table; the sound stays a row of `Sfx.SHOTS` picked by `debris`.
- With the soft switch off nothing breaks, so no state is ever written. Panels are drawn the
  same either way.

**Built in W6 (2026-11-19)**, behind `barrier_look` `panels` (the palette's key stays `classic`):

- `game/scripts/panel_states.gd` (main.gd `panel_states.attach(soft_things)`, `_on_sector_ready`;
  the whole city's `Panels_i_j` on `--monolithic`). States in the custom data's third float: down
  1 (`fence_plain`, `bars_black`, `mesh_panel`, `rail_street`; `flat` will lie down the same), torn
  2 (`chain_link`), stub 3 (`hedge_low`; `gap` takes the slot until W5 draws it). A `down` piece's
  box is laid with its height along the ground on the side the car went, turned up to 7 degrees by
  a hash of the line and panel, its thickness standing, 4 cm over the ground at its foot; the posts
  of the neighbours stand.
- `panel.gdshader`: the box's height is its y axis' length (a fallen box's y lies flat); down a
  shade darker (0.7); torn drops the fill (bars or stipple) and keeps posts and rails, a hole even
  where `holes` is off; stub squashes the box in `vertex()` to a quarter of the height (a closed
  top) in a brown (#5c452b). Its count stays 3 of the cap 200; `building.gdshader` 501 of 505.
- The baked buffer is read once a tile, on its first write. On a RenderingDevice (the phone) the
  read is asynchronous (`buffer_get_data_async` on the MultiMesh's own buffer: a synchronous read
  stalled 1 to 2.3 ms on the cloud's software renderer) and the tile's writes follow it, two
  frames after the hit, behind the debris; then a write is one instance's 64 bytes
  (`buffer_update`). A write made inside the read's answer is accepted and lost (Godot 4.7.2,
  Mobile), so they are deferred. Elsewhere (Compatibility, headless) the MultiMesh path. A hit's
  script time: 10 to 11 µs median, 14 to 20 µs at the 95th centile (`check_panel_states` S5).
- Debris colour and the smash sound by the looks row's `debris` (the palette's `debris` table:
  metal, wood and leaf the old colours, sheet new); under every look this changes 484
  `green_fence` lines (leaves and the hedge's sound, metal before) and 4 `hoarding` lines (a light
  sheet and the metal sound, wood before).
- `check_panel_states` (verify `panelstates`); `--smash-fence=` for shots.

## 8. Cost on the phone

The budgets are in the archive's "Performance budgets": draw calls are the gate, triangles are
not, and the building shader has no room. Numbers below are estimates from the map's lengths;
each phase's gate measures them (section 10).

Per-sector counts on main's map (512 m sectors, 102 with barriers): light panels 95,000
city-wide, 840 in the middle sector, 1,600 at the ninth decile, 5,200 in the densest, 10,600 in
the densest block of four. Heavy walls 66 km, 460 m in the middle sector, 3.7 km in the densest.

| Phase | Draw calls, main pass | Draw calls, shadow pass | Triangles | Shader budget | Sector load | App size |
| --- | --- | --- | --- | --- | --- | --- |
| W2 typed rows | 0 | 0 | barriers 0.46 M → about 0.65 M city-wide; a default view gains 2,000 to 8,000 | none | the city mesh grows by under 2 %; soft off: no new work | under +10 MB of prebuilt sectors |
| W3 type fixes | 0 | 0 | none | none | none | none |
| W4, W5 panels | **+1 per visible sector with panels**: 1 to 4 in a default view, up to 6 zoomed out, up to 9 from the helicopter | 0 (panels cast none; the fence geometry leaves the shadow pass) | the `rail_lite` geometry leaves the city mesh (about −0.4 M); panels are 10 a piece, 0.95 M city-wide, 8,400 in the middle sector | `panel.gdshader` new, under 200 of 260; building unchanged at 501 | one buffer of 64 bytes a piece (54 KB in the middle sector, 330 KB in the densest) and a 2 KB lookup texture made once | +6 MB |
| W6 broken | 0 | 0 | none | none | a dictionary lookup per soft line of the sector, only while something is broken | none |
| W7 heavy kit | 0 | 0 | about 10 a metre for 66 km: +0.6 M city-wide, 4,600 in the middle sector, 37,000 in the densest | none | the city mesh grows by about 4 % | about +20 MB |
| W8 gates | 0 | 0 | about 60 a gate | none | none | none |
| W9 marks | 0 with the existing poster item; else +1 per sector with a slogan in view | 0 | 2 a patch, about 4,000 patches | none | none | none |

The frame's ceilings that must hold after every phase: draw calls 230 at the spawn, 200 at the
default river view, 300 zoomed out, 360 from the helicopter; main-pass triangles 0.45 M at the
spawn and 0.70 M zoomed out; a frame that loads a sector 33 ms.

Pixels: panels use `discard`. On a tile-based GPU that turns off the hidden-surface shortcut for
those triangles. Fences are a small share of the screen; only the phone can show the cost.

What only the phone can show: the frame with panels on the iPhone 11 and on the Adreno 6xx test
phone; whether bars shimmer while driving; whether `panel.gdshader` links on Adreno 6xx.

## 9. Fallbacks and recovery

**The switch.** `barrier_look` in the palette, `classic` on main. A phase is merged with the key
unchanged. The classic path is proved bit-equal to main in every phase (the sector hashes of
step 2's proof). A build for testers is always baked `classic` until F has looked at a `typed`
or `panels` build on the phone (a device run, or a build F allows) and says go. Changing the key
is then a one-line pull request with a line in `docs/PHONE-CHECK.md`.

If a gate fails, step down this ladder; each step is a switch, not a rewrite.

| If | Then |
| --- | --- |
| Draw calls over a ceiling in the helicopter or zoomed-out view | the panels' visibility range comes down from 400 m to 250 m; beyond it fences are not drawn (at that zoom a fence is 3 px) |
| The frame drops on the iPhone 11 with panels | a field in `tiers.gd`, `panel_holes`: on Low and Medium the panel shader skips `discard` and blends the row's colour toward the ground tone by `open`. The governor never touches it |
| `panel.gdshader` fails to link on Adreno 6xx | that GPU gets `typed` (`rail_lite`), picked in `gpu_quirks.gd`; panels are never the only way a fence is drawn |
| Bars shimmer or crawl | bars off (`bars: 0` for every row): posts, rails and the tint fill only |
| A sector load goes over 33 ms | the longest plain runs merge to 4 m pieces (two panel indices share an instance until one breaks) |
| Panels disappoint on the phone altogether | the key goes to `typed`. Broken looks then stay at debris only, and the soft switch waits |
| The typed look disappoints | the key stays `classic`; nothing was lost |
| A type looks wrong | it is a row: change the row, or override a line by id in `road_objects.json` |
| A rule mislabels a setting | the rule is dropped to `default` in `object_types.py`; `check_map_data.py` shows the metres that moved |
| The two city paths disagree | `check_barrier_look` compares the vertex count of the city mesh and the piece count of `Panels` per sector on both paths |

Recovery of broken things in play (the car never trapped, repair out of sight, a whole city on a
new launch, `--no-soft` for developers) is `soft_things.gd`'s and needs nothing more from the
look, except that a repaired panel stands up again (section 7).

## 10. The plan, in phases

W0 (the type sheet) and W1 (types in the bake) were done inside step 5 of the objects plan. One
pull request per phase from here, in this order, through the audit. Every phase leaves
`barrier_look` at `classic`.

**Gates for every phase**: `tools/verify.sh` green; both city paths; with `classic` the per-sector
vertex and collider hashes equal main's (the dump scripts of step 2's proof in
`/mnt/project-files/walls-research/`); `building.gdshader` unchanged and `check_shader_budget`
at 501; the bench before and after on both paths; shots at phone size, day and night, classic
beside the new look, at the review places: Stadion Narodowy (`--at=1300,-420`), Marszałkowska by
the Rotunda (`--at=-880,390`), Plac Grzybowski (`--at=-1410,-250`), Prosta by Wronia
(`--at=-2560,440`), a school fence (`--at=-1087,-934`), a works wall (`--at=-1621,1200`), the
boulevards (`--at=-560,-1950`).

| # | Phase (objects plan step) | What | Files and owners | Model | Gates beyond the common ones | Only the phone |
| --- | --- | --- | --- | --- | --- | --- |
| **W2** | Typed rows and the switch (9a) | `barrier_look` and `--barriers=`; the `looks` rows of 6.2; `rail_lite`; heights from `hs`; `check_barrier_look` | palette (`object_palette.json`), `solidity.gd` (reads it), `city_barriers.gd` (draws), `dev_flags.gd` and `main.gd` (the flag), `bake_city.gd`, the prebuilt index stamp, `tools/verify.sh` | Opus | every `ty` in the map has a row; no line falls to `barrier_default`; draw calls unchanged at the four probe views; barrier triangles at most 0.75 M city-wide; main-pass triangles at most +15,000 at the spawn and +40,000 zoomed out; prebuilt sectors at most +4 % in size; `check_streaming` load-frame p99 at most +5 %; the sloppy table with `typed` equals `classic` within noise | do thin rails read or flicker at the default zoom while driving |
| **W3** | Type fixes (5b) | the five fixes of section 5 as `object_types.py` version 2, a guarded pass; rows `post_row`, `stadium_fence` | `tools/object_types.py`, `tools/check_post_passes.py`, `tools/check_map_data.py`, `game/data/road_objects.json`, the palette | Opus (`map-engineer`); Haiku gathers the sample photos; the conductor judges | `postpasses` and `objecttypes` green; a second run changes nothing; each new rule 16 of 20 or dropped; default share at most 9 %; `classic` hashes equal main's except the sectors with a line whose `sc` changed, each named | nothing |
| **W4** | Panel trial (11) | `panel.gdshader`, the sector `Panels` MultiMesh and its meta, the lookup texture; six rows as panels (`fence_plain`, `bars_black`, `mesh_panel`, `chain_link`, `rail_street`, `hedge_low`: 173 km); the rest stay `typed` | `city_barriers.gd` (the piece list), `map_builder.gd` and `bake_city.gd` (the node, as the parked cars' MultiMesh), `instance_buffers.gd`, `game/shaders/panel.gdshader`, `tiers.gd` (`panel_holes`), `gpu_quirks.gd`, `check_shader_budget`, a pure `panel_rule.gd` with `check_panel_rule` | Opus (`perf-engineer`) | draw calls at most +3 at the spawn and the river view, +6 zoomed out, +9 from the helicopter, all under the ceilings; `panel.gdshader` under 200; `check_panel_rule`: bars never closer than 2.5 px and never thinner than 1 px at 5, 10, 17 and 26 cm a pixel; shots at three zooms by day, night and rain; piece counts equal on both paths; load-frame p99 at most +5 % | the frame on the iPhone 11 and the Adreno phone; shimmer of bars and stipple at 40 km/h; the shader links |
| **W5** | Panels for every light type (12a) | the other light rows as panels (`green_fence`, `low_lawn`, `ball_net`, `wood`, `hoarding`, `hedge_tall`, `chain_posts`, `post_row`, `stadium_fence`, `bars_pier`); `sag` and `leafy` tops; alt colours | the palette, `panel.gdshader`, `city_barriers.gd` | Opus for the shader, Sonnet (`object-modeler`) for rows and shots | as W4; no light line drawn in the city mesh under `panels` except `draw: keep`; the art-director accepts the shot set against section 4 | hedges without a shadow: do they sit on the ground |
| **W6** | Broken panels (12b) | `panel_states.gd`; states and transforms on `broke` and `repaired`; sectors that come in; debris colour from the row | `soft_things.gd` (owner of the events, unchanged signals), `main.gd` (wiring), new `panel_states.gd` (a row in `systems.md`), `check_soft_things` extended | Opus | every `broken` kind of section 7 shown in a shot at the stadium; a panel broken, driven away from and back to is still down; after `repair_near` it stands; soft off: zero state writes in a 3-minute soak; script time per hit under 0.1 ms | the feel of a fence that falls (PHONE-CHECK line 5 again) |
| **W7** | The heavy kit (9b) | `wall_kit`: foot, cap, bays, piers, proud posts, end pieces; noise screens; `bars_pier` piers with diamond colliders; the boulevards' top rail; retaining walls' coping | `city_barriers.gd`, the palette | Opus for the builder, Sonnet for rows and shots | draw calls unchanged; barrier triangles at most +0.7 M city-wide; main-pass triangles under the ceilings at the four views; prebuilt sectors at most +6 %; the sloppy table: no new dead stop, none at a pier | nothing new; the frame is in the BENCH line |
| **W8** | Gates and gaps | a pass `barrier_gates`: where a `paths` or service `roads` centre line crosses a line, a gap of the way's width plus 0.4 m, written as `g` on the line; the builder leaves the gap and stands two posts 0.3 m taller, with open leaves for a drive | `tools/barrier_gates.py` (in `bake_osm.py` and `check_post_passes.py`), `city_barriers.gd` | Opus (`map-engineer`) | the pass idempotent; gaps counted in `check_map_data.py`; the wander run finds no new trap; the sloppy table's fence contacts go down | nothing |
| **W9** | Marks | graffiti patches and slogans, hoarding banners, ivy, stains (6.6 rows 10 to 12), by seed and by the row's `marks`; text by the warsaw-tone skill | `city_barriers.gd` (patches), `props.gd`'s posters for slogans and banners, `game/data` for the texts | Sonnet; PixelLab inside the loop's limit; the art-director accepts | draw calls at most +1 per sector with a slogan in view, 0 if the poster item is shared; at most one slogan per 150 m of wall | nothing |
| **W10** | Sweeps and the ratchet (16) | the street-pass skill writes a type per line; the default share only goes down; when `barrier_look` has left `classic` for two builds, the `types` rows and the classic drawing are deleted | `tools/street_pass.py`, `check_map_data.py`, the palette | Sonnet; the sweep skill | per street | nothing |

**The lines for `docs/PHONE-CHECK.md`**, each added by its phase's pull request, part 2 or 5:

- W2: "A build baked with `typed`: drive Marszałkowska, Plac Grzybowski and the stadium. Do thin
  fences read as fences, or flicker? Are heights right (planters, park hedges)?"
- W4: "A build baked with `panels`: the same drive, at the closest, default and widest zoom, by
  day and at night. Bars and mesh steady while driving? BENCH against the last build."
- W6: "Miękkie miasto on, `panels` build: drive through a bar fence, a mesh fence, a net and a
  hedge at the stadium. Does the panel fall the right way; is it still down after a lap?"

**Architecture.** Looks are data in the palette's `looks`; `solidity.gd` reads them;
`city_barriers.gd` draws them; panel buffers go through `instance_buffers.gd`; the cost switch is
a field in `tiers.gd`; broken state is `soft_things.gd`'s and `panel_states.gd` only shows it;
map changes are passes (TD-25); new scripts get their rows in `docs/architecture/systems.md`,
and W2 widens the "A wall, fence or hedge style" row of `extending.md`. Add-ons: not used (no
agent behaviour, no dialogue).

**The first phase's brief**, written out for an Opus builder:
`/mnt/project-files/walls-research/look-plan/brief-phase1.md`.

## 11. F's answers

Answered 2026-11-15 (F): all four as the defaults.

1. **Old pier-and-iron fences** break like other fences: the iron panel falls, the piers stand.
   Built in W6 (the panel) and W7 (the piers and their diamond colliders).
2. **Graffiti on concrete and plaster walls**: yes, original tags and parody slogans. W9.
3. **Building-site hoardings with parody developer posters**: yes. W9; the hoardings themselves
   are placed by sweeps (section 5).
4. **A fence nothing is known about** is a thin dark see-through railing 1.4 m high. The row
   `fence_plain`, drawn from W2.

Open after the re-plan, parked in `docs/QUESTIONS.md` with these defaults:

1. **How F sees the new look on the phone.** Default: a device run of a build baked with
   `typed` (after W2) and with `panels` (after W4), when F allows a device run; testers' builds
   stay `classic` until F says go.
2. **Bollard rows** (`post_row`) break like fences (class S). Default: yes; the other way is
   hard posts, which would add dead stops along Wola's kerbs.
3. **Pier colliders.** Default: a pier is solid with a diamond collider that turns the car into
   the bay; the other way is piers the car passes through.

## 12. How this was measured

- Lengths, types and counts: `game/map/centrum.json` on main f9d5823 (2026-11-15), keys `k`,
  `ty`, `tc`, `sc`, `hz`, `h`, `hs`; per-sector counts by the middle of each segment on a 512 m
  grid.
- The code as it is: `game/data/object_palette.json` (`types`), `game/scripts/city_barriers.gd`
  (`build_barriers`, `_mapped_style`, `wall_along`, `railing_along`, `PANEL`, `_is_soft`),
  `solidity.gd`, `soft_things.gd` (signals, `is_broken`), `instance_buffers.gd`, `tiers.gd`,
  `game/tools/check_shader_budget.gd` (lit budget 260, building 505),
  `building.gdshader` (`cull_disabled`), `tools/object_types.py`, `tools/check_post_passes.py`.
- Pixel sizes: `follow_camera.gd` (views 40 to 125 m, pitch 30°), `tiers.gd` (480 lines at
  least; 828 on the iPhone 11 at Sharp). Section 3 was checked again and stands.
- **The photo research of 2026-11-15**: 86 Mapillary photos (CC BY-SA 4.0) at eight places, the
  newest photo within 28 m that faces the middle of a line, `default` lines first, then
  `context`. Kept in `/mnt/project-files/walls-research/look-plan/photos/` with a contact sheet
  and a `photos.json` per place. Reference only, never committed or shipped.

  | Place | Photos | What they show |
  | --- | --- | --- |
  | Emilii Plater, Złota, Świętokrzyska | 12 | the `default` walls are the Palace of Culture's knee-high granite planters (2 clear), one white site hoarding on Plac Defilad; the `default` hedges are low hedges in the street's planted strips |
  | Plac Grzybowski | 11 | all 10 `default` walls are the square's raised planting beds: dark edges 0.4 to 0.8 m. Drawn 1.6 m and hard they wall the square in |
  | Wola: Towarowa, Prosta, Wronia | 12 | of the `default` fences: two bollard rows, a grey steel fence on a low wall, a blue hoarding, a green hoarding with a banner; graffiti on plaster |
  | Jerozolimskie by Chałubińskiego | 11 | grey kerb railings with bars, bollards, a glass screen at the tram stop, a stone retaining wall along the cutting |
  | Wybrzeże Szczecińskie | 12 | long grey galvanised railings with bars on a kerb; green mesh by the railway; a brick wall with a hedge at a new block |
  | Wybrzeże Gdańskie | 12 | the boulevards' pale concrete walls with strong joints, a steel handrail on top, graffiti; hedges taller than a person in the fountain park |
  | Stadion Narodowy | 4 | poor cover (night shots); a red-and-white barrier on the ramp, mesh panels by the railway. The stadium is judged in the game |
  | Marszałkowska | 12 | black tram railings with bars; black cast bollards and planters; red-and-white roadworks barriers; low hedges |

- The step-5 contact sheets (`/mnt/project-files/walls-research/step5/`) were read again for the
  yard fences: most cells show no fence at all, because yard fences stand behind the houses.
- The first pilot (2026-11-13): 23 Mapillary photos at 14 places, among them 1505989927822671
  (bars on a foot by a Praga church), 970824793456423 (the graffiti wall mapped as a fence),
  162602436441635 (piers and iron panels by the Filtry), 136869858384962 (the boulevard
  railing), 1576903606561952 (noise screens), 475545233512398 (a lawn guard and hedge in a park),
  378134946853997 (overgrown villa fences).
- Not measured: draw calls and frame time of the panels (W4), today's draw calls at the four
  probe views (each phase takes them before and after), how many of W3's rules pass the
  20-sample check, the size of the prebuilt sectors (W2's gate takes it).
