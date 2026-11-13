# Walls, fences and rails that look like the real ones

**Status (2026-11-13):** research and a phased plan. No game code changed. Implementation is for
Opus threads, one phase per PR (section 10).

F (2026-11-13): "How to make these walls look more like in life. There are the walls now, but
they should represent the real type of object and texture, and how to handle it if it is ruined:
the memory of it and the recovery."

This page owns **what each wall, fence, hedge and rail is and how it looks, whole and broken**.
Its sister page `docs/design/drivable-city-build.md` owns what the car does to them and how a
broken one is remembered and repaired (its section 5). The seam between the two is section 7 here.
It builds on `drivable-city.md` (the five solidity classes, rule R2 "solid looks solid"),
`road-objects.md` 3.4 (the object library) and `building-pipeline-review.md` (the shader budget).

Contents: [1 The answer in short](#1-the-answer-in-short) ·
[2 What is drawn today](#2-what-is-drawn-today-measured) ·
[3 What a phone pixel can show](#3-what-a-phone-pixel-can-show) ·
[4 The types](#4-the-types-warsaws-walls-fences-and-rails) ·
[5 How a line gets its type](#5-how-a-line-gets-its-type) ·
[6 How a type is drawn](#6-how-a-type-is-drawn) ·
[7 Broken looks](#7-broken-looks-the-seam-with-the-drivable-city-plan) ·
[8 Cost on the phone](#8-cost-on-the-phone) ·
[9 Fallbacks and recovery](#9-fallbacks-and-recovery) ·
[10 The plan](#10-the-plan-in-phases) · [11 Questions for F](#11-questions-for-f) ·
[12 How this was measured](#12-how-this-was-measured)

---

## 1. The answer in short

1. **Four fifths of the barriers have no type at all.** The map has 279 km of walls, fences and
   hedges. 155.5 of 188 km of fence and 56.8 of 70 km of wall carry no OpenStreetMap detail, so
   they are drawn as one grey band (fence) or one beige slab (wall). Tags alone will never fix
   this; the type has to come from **what the barrier stands next to**.
2. **Context can name most of them.** A prototype that looks at the tram tracks, railway, roads,
   stairs, parks, pitches and building kinds beside each line gives a specific setting to 60 % of
   the fence metres with the data already in the map (section 5). The rest needs land-use
   outlines the bake drops today (schools' grounds, cemeteries, building sites, allotments,
   embassies, railway land).
3. **"Texture" on this game's screen is not a brick pattern.** One pixel of the game's image is
   10 to 17 cm of street at the default zoom. A brick, a fence bar and a mesh wire are smaller
   than a pixel. What the player can read is the colour, the height, the outline (foot, cap,
   piers), the rhythm of posts and panels every 2 to 4 m, and whether the thing is see-through.
   A type is those five things, plus a few big marks (graffiti, a poster band).
4. **Two families, drawn two ways.** Heavy things that stop the car (walls, parapets, noise
   screens, crash barriers) stay in the city's mesh as shaped geometry with colour: no new draw
   call and no shader change. Light things that break (fences, hedges, low walls) become
   **instanced panels** with one small shader of their own. That makes them see-through, gives
   each type its look as a row of data, and lets one panel fall when the car goes through it.
5. **The building shader is not touched.** It stands at 502 of 505 on the Adreno budget. The new
   panel shader is separate and is designed with no branches.
6. **The broken look** follows the drivable-city plan's memory: debris only first (its version
   1), then the hit panel lies down and stays down until the city repairs it out of sight. Each
   type has its own way of being broken (section 7).
7. **The cost is draw calls, not memory.** Panels add one draw call per visible sector (1 to 4
   in a normal view) and take about 335,000 triangles out of the city meshes. The lookup
   texture is 2 KB. If the phone bench fails, there is a switch back to today's drawing and a
   ladder of cheaper steps before that (section 9).

## 2. What is drawn today, measured

From `game/map/centrum.json` on main (05b7c9c), `lines` without the stop platforms:

| Kind | Length | Lines | With any OSM detail (`h`, `m`, `ft`) or a placed style (`st`) | Drawn as |
| --- | --- | --- | --- | --- |
| Fence | 188.2 km | 4,909 | 32.7 km (17 %): 29.4 km railing, 0.7 km mesh, 0.5 km wood, 1.8 km height only, 0.2 km stair balustrade | untagged: a solid grey band 0.12 × 1.6 m. Railing: posts and two rails. Mesh: the same rails in grey |
| Wall | 69.6 km | 2,055 | 12.8 km (18 %): 5.5 km height only, 2.2 km noise screens, 2.2 km concrete, 1.5 km stair balustrade, 0.8 km gabion, 0.4 km brick, 0.2 km stone, 0.1 km glass and wood | untagged: a beige slab 0.35 × 1.9 m. A material changes only the colour |
| Hedge | 21.0 km | 964 | 3.1 km with a height | a green slab 0.9 × 1.2 m |

Beside these: 24.4 km of guard rails (`guards`, one steel beam on posts for every bridge edge and
mapped crash barrier), 20.7 km of structure walls (`walls`: 761 concrete, 731 stone, 27 tunnel),
22 city-wall pieces in the Old Town, and the hand-placed styles of `BARRIER_STYLE` in
`map_builder.gd` (tram railing, three balustrades, the Palace's low walls, garden rings, basin
rims).

How they are drawn: `_wall_along` makes a box per segment (10 triangles), `_railing_along` posts
and two rails; both go into the sector's building mesh with the "prop" code in UV2, so
`building.gdshader` gives them the flat vertex colour with a little noise and nothing else. All
barriers together are about 458,000 triangles city-wide (fences 293,000, walls 123,000, hedges
42,000). A fence casts the shadow of a solid band.

What is wrong with that picture, in order of metres:

1. 155 km of fence is an opaque grey strip. Real fences are see-through; this one reads as a wall.
2. 57 km of wall is one height and one colour with no foot, no cap and no piers.
3. Hedges are 1.2 m everywhere; in the parks they are knee-high (photo pilot, section 12).
4. Every bridge has the same motorway crash barrier, whatever its real parapet is.
5. OSM's own kind is sometimes wrong for the look: a mapped `fence` at the western edge of the
   map is a 2.5 m concrete wall covered in graffiti; a mapped `wall` by the Filtry is plastered
   piers with iron panels between them.

## 3. What a phone pixel can show

The city is drawn into a small pixel image and scaled up. The image has 480 to 828 lines; the
default view is 80 m tall, the closest 40 m, the widest 125 m; the camera looks down at 30°, so a
vertical face shows 87 % of its height.

| Zoom | One image pixel is | A 1.6 m fence is | A brick course (7 cm) | Bars 12 cm apart | Posts 2.5 m apart |
| --- | --- | --- | --- | --- | --- |
| Closest (40 m) | 5 to 8 cm | 17 to 29 px | about 1 px | 1.5 to 2.4 px | 30 to 50 px |
| Default (80 m) | 10 to 17 cm | 8 to 14 px | under 1 px | under 1.2 px | 15 to 25 px |
| Widest (125 m) | 15 to 26 cm | 5 to 9 px | no | no | 10 to 16 px |

So the detail ladder for a barrier is:

| Size of the detail | Examples | How it is shown |
| --- | --- | --- |
| Under 15 cm | bricks, bars, wires, boards, mortar | never drawn one by one. It becomes the **tone** (brick red with a speckle), or the **openness** (how much you see through) |
| 0.3 to 1 m | foot band, coping, panel joints, corrugation, a poster band, cage of a gabion | 2 to 6 px: a band of another shade, or a tone change from one panel to the next. No thin lines: a 3 cm joint line flickers at this scale |
| 2 to 5 m | posts, piers, panel length, gates, steps in height | clear shapes. This is where a type is recognised |
| The whole thing | height, thickness, straight or leafy outline, shadow | read first, at 40 km/h |

The rule for bars and meshes: draw **posts and the top rail solid, and fill the rest with as many
bars as there are pixels for**, never thinner than one pixel, fixed to the fence so they do not
crawl when the car moves. At the default zoom a 2 m panel then shows about five bars instead of
sixteen: what a pixel artist would draw. This rule is the main thing the first trial (W3) checks.

## 4. The types: Warsaw's walls, fences and rails

Class is the solidity class of `drivable-city.md`: H stops the car, S breaks, R is ridden over.
The class comes from the bake (`sc`); the type must never contradict it (rule R2):

- **H looks heavy**: closed from foot to top, at least 0.25 m thick, a dark foot band and a
  lighter cap, a shadow. Or a steel beam at bumper height.
- **S looks light**: at least half see-through or leafy, thin, no foot higher than 0.3 m, no
  shadow band, slim posts.
- **R looks low**: under 0.6 m, drawn as a kerb or a rim.

Sizes and colours below are first values from the pilot photos (section 12) and general knowledge
of the city; phase W0 confirms each type against 6 to 10 photos before it is built.

### 4.1 Light: fences, rails and hedges (Smash)

| Type | The real thing | Where | Look (whole) | Height |
| --- | --- | --- | --- | --- |
| `rail_street` | the street guard railing: grey or graphite steel, posts, a top rail and a mid rail, older ones yellow | kerbs at crossings and stops, medians, school exits | posts every 2 m, two rails, nothing between | 1.1 m |
| `rail_tram` | the fence between or beside tram tracks: grey or green welded panels, older black railing | tram beds, platform backs | posts every 2 m, top rail, sparse bars; green or grey by line | 1.1 to 1.2 m |
| `bars_black` | black steel bars, often spear tops, on a low concrete foot | tenement yards, churches, offices, newer housing (pilot: Praga church, a Wola yard gate) | foot 0.3 m, posts every 2 m, bars | 1.6 to 2.0 m |
| `bars_pier` | iron panels between plastered or brick piers on a plinth | university, ministries, embassies, palaces, old parks, the Filtry (pilot) | plinth 0.5 m, piers 0.4 m square every 4 m with a cap, bars between | 2.0 to 2.5 m |
| `mesh_panel` | welded mesh panels, green or grey | schools, kindergartens, playgrounds, dog runs, new estates | posts every 2 m, top edge, fine fill (reads as a tint) | 1.2 to 2.0 m |
| `chain_link` | old wire netting on thin posts, grey, often leaning | allotments, garages, back plots, railway land | thin posts every 4 m, faint fill, uneven top | 1.5 m |
| `ball_net` | ball-stop net on tall posts | pitches | posts every 4 m, very faint fill | 4 to 6 m |
| `low_lawn` | the knee-high lawn guard: hoops or a flat rail, green or black | lawns and paths in parks and estates (pilot: a park path) | one rail on short posts | 0.4 to 0.8 m |
| `wood` | board fence | rare (0.5 km) | brown boards, small gaps | 1.5 m |
| `hoarding` | building-site hoarding: sheet metal or boards with the developer's poster band; mesh panels on concrete feet | building sites | closed sheet, a poster band at eye height with parody developer names, feet | 2.0 m |
| `green_fence` | a fence grown over with ivy and bushes | villa gardens of Saska Kępa and Mokotów (pilot) | bars with a leafy mass over most of it | 1.6 m |
| `hedge_low`, `hedge_tall` | clipped hedge | parks and squares (low), villas and embassies (tall) | leafy box with a soft, uneven top; lighter than tree crowns | 0.6 m, 1.5 to 2.5 m |
| `chain_posts` | posts with a chain | monuments, palace forecourts, the Old Town | short posts, a sagging line | 0.7 m |
| `low_wall` | low masonry: brick, plaster, granite planter edge | squares, planters, terraces | body and a cap; under 0.6 m it is class R and drawn as a rim | 0.3 to 1.2 m |

### 4.2 Heavy: walls, screens and barriers (Hard)

| Type | The real thing | Where | Look | Height |
| --- | --- | --- | --- | --- |
| `wall_brick` | red brick with a cap and piers | old factories (Praga, Wola), church yards, barracks | brick red, dark foot, pale cap, piers every 3.5 m | 2.2 to 3.0 m |
| `wall_plaster` | rendered masonry, cream or grey | yards, institutions | plain body, foot band, tile or concrete cap | 1.8 to 2.5 m |
| `wall_precast` | the precast concrete fence: posts with stacked slabs, grey, tagged and stained | works, depots, garages, railway land (pilot: the map's west edge) | posts every 2.5 m, panels a shade apart, graffiti band low down | 2.0 to 2.5 m |
| `wall_stone` | sandstone or granite blocks | the escarpment, palace gardens, the boulevards, Old Town terraces | large blocks as tone patches, heavy cap | by `h` |
| `retaining` | structure walls (`walls`): concrete or stone under a road or a slope | approaches, trenches, tunnels | coping, darker foot, a joint tone step every 5 m, drip stains under the coping | from the bake |
| `noise_screen` | steel posts with cassette panels, the top band clear | Trasa Łazienkowska, parts of Wisłostrada, Wał Miedzeszyński (pilot: rust-brown panels, clear top), the railway | posts every 4 m, lower panels green or rust-brown, a pale see-through top band | 4 to 6 m |
| `gabion` | wire cages of stone | newer landscaping | 1 m cages as tone blocks, speckled | by `h` |
| `guard_rail` | the steel beam on posts (exists) | fast roads, drops | as now, plus a turned-down end | 0.75 m |
| `jersey` | concrete barrier, sloped sides | medians of the fast roads, roadworks | 3 m pieces a shade apart, wide foot, sloped end piece | 0.8 m |
| `parapet_concrete` | estacade parapet with a steel top rail | viaducts and ramps | solid upstand, rail on top, drip line | 1.1 m |
| `deck_railing` | steel posts and rails with infill | Most Świętokrzyski (pilot), footbridges | stout posts, top rail, kerb upstand under it | 1.1 m |
| `rail_waterfront` | stainless posts with cables on a granite kerb | Vistula boulevards (pilot) | posts every 2 m, kerb 0.3 m, top rail | 1.1 m |
| `balustrade_*` | stair-hole balustrades: granite, glass, concrete with a rail, white (exist) | metro and underpass stairs, terraces | as now | 1.0 m |
| `city_wall` | the Old Town's brick defence walls (exists) | Old Town | as now | mapped |

Bridge parapets belong to each bridge's own model (Poniatowski's stone balustrade is the bridge
thread's); the types above are for the decks that have no model of their own.

**A hazard fence is not always a crash barrier.** The drivable-city plan makes a fence hard when a
drop, a railway or water is behind it and draws it as a guard rail. A steel beam is right along a
road. On the boulevards it is wrong: there the hard version is `rail_waterfront`; at a railway it
is `wall_precast`; at a drop beside a walk it is `parapet_concrete`. So: the bake writes the class
(`sc: H`) and the reason, and the type table picks the heavy look for that reason.

**Heights by setting** (correcting the 1.9 m default for walls with no height, item 8 of the
build plan): park or square 0.5 m; planter or basin ring 0.45 m; housing yard 1.2 m; church,
school and institution 2.0 m; works, depot, railway 2.4 m; cemetery and barracks 2.6 m; noise
screen 4 m, 6 m along the railway; unknown 1.6 m (not 1.9).

## 5. How a line gets its type

In the bake, once, in bulk. Each line gets `ty` (the type) and `tc` (how sure: `tag`,
`structure`, `context`, `default`). First match wins:

| Step | Source | Examples |
| --- | --- | --- |
| 0 | the street passes' override file (`game/data/road_objects.json`), by stable id | a named place a sweep has looked at |
| 1 | a landmark site that builds the wall itself (`SITE_WALLS`, the Palace's grounds) | unchanged |
| 2 | **OSM tags**, read in full (today three groups are kept): `fence_type` (bars, railing, chain_link, wire, net, panel, corrugated_metal, temporary, glass, paling, slatted, concrete), `material`, `wall=noise_barrier`, `colour`, `height`, and the barrier kinds the bake drops (`jersey_barrier`, `handrail`, `chain`, `cable_barrier`, bollard rows) | `fence_type=chain_link` → `chain_link`; `fence_type=panel` is OSM's word for slabs in grooved posts → `wall_precast`; `temporary` → `hoarding` |
| 3 | **the structure it belongs to** | along a tram bed → `rail_tram`; round a stair hole → balustrade; along a deck → the bridge's parapet; along a railway → `wall_precast` or `noise_screen`; along water → `rail_waterfront`; along a main road's edge → `rail_street` |
| 4 | **the land it encloses or borders** | school or kindergarten → `mesh_panel`; church, embassy, university, ministry → `bars_pier`; cemetery, barracks → `wall_brick`; works, depot, garages → `wall_precast`; building site → `hoarding`; pitch → `ball_net` or `mesh_panel` by height; allotments → `chain_link`; villa → `green_fence`; park or lawn, short and beside a path → `low_lawn`; tenement or housing yard → `bars_black` |
| 5 | **its shape** | a closed ring under 6 m → rim; a fragment under 4 m with nothing near → removed (build plan, item 8) |
| 6 | **default by kind** | fence → a thin dark see-through railing 1.4 m; wall → `wall_plaster` 1.6 m; hedge → 0.8 m in a park, 1.2 m elsewhere |

**What the map's own data gives today** (prototype `wall_context.py`, section 12; share of metres):

| Setting | Fence (188 km) | Wall (70 km) | Hedge (21 km) |
| --- | --- | --- | --- |
| Tram bed | 6 % | 1 % | 9 % |
| Railway | 2 % | 3 % | |
| Stairs | 1 % | 7 % | |
| Main road edge | 3 % | 1 % | |
| Park | 14 % | 25 % | 54 % |
| Pitch | 2 % | | |
| School | 4 % | 1 % | 1 % |
| Church | 1 % | 1 % | |
| Institution (government, university, hospital) | 2 % | 5 % | 2 % |
| Works, garages | 3 % | 2 % | |
| Villa garden | 6 % | | |
| Housing yard | 15 % | 8 % | 8 % |
| Waterside | | 4 % | |
| **Some other building near** | 16 % | 18 % | 8 % |
| **Open ground, nothing known** | 24 % | 23 % | 18 % |

The last two rows (40 % of the fences) are what the map cannot name yet. Most of that ground has
an OSM outline the bake does not keep: `amenity` school, kindergarten, university, hospital,
embassy, place of worship and parking; `landuse` cemetery, construction, allotments, industrial,
railway, military, religious; `leisure` playground, dog park, sports centre, garden. Phase W1
adds them to the bake as one list of context outlines (`ctx`), used only for this.

**Checking the rules without a verdict per object.** For each rule, a tool draws 20 random lines,
fetches the nearest street-level photos (`tools/street_photos.py`, already working in the cloud)
onto one contact sheet, and a reviewer marks right or wrong. A rule ships when at least 16 of 20
are right; a rule that fails is narrowed or dropped to the default. The pilot (23 photos at 14
places) already found the two traps in section 2, point 5, and confirmed tram, church, yard,
park, villa, waterside and noise-screen settings. Mapillary's own detections (fence, wall, guard
rail as classes in a photo) may settle fence against wall where OSM is wrong; that is untested.

**Keeping it honest.** `check_map_data.py` records the metres per type and the share with
`tc: default`; the default share only goes down. A plot coloured by type (one PNG for the whole
map) is the review picture for F.

## 6. How a type is drawn

### 6.1 One table of types

`game/data/barrier_kit.json`: one row per type with its family, height, thickness, colours (body,
foot, cap, post), post or pier spacing, panel length, openness, bar spacing, the broken look and
the sound and debris kind. `map_builder.gd` and the panel shader both read it, so a new type or a
retexture is a data row, as `road-objects.md` 3.4 asked. `BARRIER_STYLE` and `WALL_MATERIAL`
move into it.

### 6.2 Heavy types: shaped geometry in the city mesh

A wall builder next to `_wall_along` that makes, per run: the foot band, the body cut into panels
(each panel's colour a step lighter or darker, so the rhythm survives any zoom), the cap with a
small overhang, piers or posts at the spacing, and an end piece (a pier, a sloped end, a
turned-down rail) where the build plan's item 7 asks for a taper. Noise screens get posts, opaque
lower panels and a pale top band. Graffiti and poster bands are a few colour patches low on the
wall on `wall_precast` and `wall_plaster`, picked by a seed.

No new material and no shader change: the prop path of `building.gdshader` already adds a fine
speckle to flat colours. Cost: triangles only (section 8).

### 6.3 Light types: instanced panels with their own shader

- **One mesh for everything**: a unit box without a bottom (10 triangles). An instance is one
  panel: placed at its foot, turned along the line, stretched to the panel's length, height and
  thickness, sheared to follow the slope. A panel is 2 m of the line, the same 2 m that
  `soft_things` remembers, so posts stand every 2 m or every 4 m (real panels are 2.5 m; at
  this pixel size the difference does not show).
- **One `MultiMesh` per sector**, made in the bake for the prebuilt path and by `map_builder.gd`
  for the runtime path from the same sector list, written through `instance_buffers.gd`. The
  instance colour is the tint; the custom data carries the type's row, a seed and the state
  (whole, down, stub).
- **One small shader, `panel.gdshader`**: reads the type's row from a 16 × 32 lookup texture made
  from the kit (a texture read is not control flow, so it costs nothing on the Adreno budget) and
  draws foot, posts at the panel's ends, top rail, bars by the rule of section 3, the fill tint
  and the leafy edge of hedges, all with `step` and `mix` and no branch. Holes are cut with
  `discard`, as the building shader's ghost already does. It reads the shared day, night and
  rain globals, never its own copy.
- **No shadow** for panels (a see-through fence has almost none; hedges get a dark foot in the
  shader instead). This also takes today's fence bands out of the shadow pass.
- **Colliders** are not this page's: the build plan's item 3 removes them for class S; a panel is
  only a picture plus an entry in `soft_things`.

Why not the other ways: more patterns in `building.gdshader` has no room (502 of 505); posts and
bars as real geometry for 188 km is what the railings do today (160,000 triangles for 31 km) and
still cannot fall over; a photo texture per type shows nothing at this pixel size and would add a
material per type.

## 7. Broken looks: the seam with the drivable-city plan

`drivable-city-build.md` section 5 owns the memory: `soft_things.gd` keeps each broken panel by
the line's stable id and the panel's index for the session and repairs it out of sight after
about ten minutes. It offered three ways to show a broken thing. The choice:

1. **First: debris only** (its way 1), with item 3 of the build plan. Nothing here is needed.
2. **Then: the panel goes down** (its way 3), which the instanced panels give for free: on
   `soft_things.broke(id, panel, kind, at, direction, speed)` the panel's state changes in the
   `MultiMesh` (one small buffer write, no rebuild), and when a sector is built again the bake's
   panel list is checked against `is_broken(id, panel)`.
3. Not chosen: the damage map in the building shader (way 2). There is no room for it, and it
   cannot give a type its own way of breaking.

The broken look, by type:

| Type | When the car goes through | What stays until the repair |
| --- | --- | --- |
| `rail_street`, `rail_tram`, `bars_black`, `mesh_panel` | the panel swings down away from the hit; a clang; bars fly | the panel flat on the ground, a shade darker, a few degrees askew. Posts of the neighbours stand. The gap is the mark |
| `bars_pier` | the iron panel goes down, the piers stay | piers with an empty bay |
| `chain_link`, `ball_net` | the net tears and sags | the fill gone in that bay, posts standing or leaning |
| `low_lawn`, `chain_posts` | flattened | nothing drawn in that bay |
| `wood` | boards fly | the bay empty, two boards on the ground |
| `hoarding` | the sheet falls flat | the sheet on the ground, poster side up |
| `green_fence`, hedges | leaves burst | a gap with a low brown stub (a quarter of the height) |
| `low_wall` (0.6 to 1.2 m) | dust, bricks | a notch: the bay at 0.2 m in a rubble tone |
| every Hard type | nothing breaks | nothing (scrape marks are not planned) |

What this page asks of `soft_things`:

- the panel index is `floor(distance along the line / 2 m)`, the same in the bake's panel list;
- a `repaired(id, panel)` event as well as `broke`: a repair happens 150 m away and out of view,
  but a sector is 512 m, so the panel may still be loaded and must stand up again;
- `sc: H` with its reason on the line instead of a fixed `st: guard`, so the heavy look can fit
  the place (section 4.2).

Debris colour, particle shape and sound come from the type's row in the kit, so a brick wall
throws red dust and a hedge throws leaves without code per type.

## 8. Cost on the phone

The budgets are in the archive's "Performance budgets": draw calls are the gate, triangles are
not, and the building shader has no room.

| What | Today | With this plan | Note |
| --- | --- | --- | --- |
| Draw calls, main pass | barriers ride in the building mesh: 0 of their own | **+1 per visible sector** for the panels: 1 to 4 in a default view (sectors are 512 m), more from the helicopter | the one real cost; measured at the four `--probe` views in W3 |
| Draw calls, shadow pass | fences and hedges cast | panels do not | goes down or stays |
| Triangles in the city meshes | 458,000 for all barriers | fences and hedges leave (335,000 out); heavy walls gain foot, cap and piers (about +330,000 for 90 km) | about even |
| Triangles drawn as panels | 0 | 10 per panel, about 115,000 panels city-wide, about 1,300 in a sector | small beside the 0.25 to 0.36 M of a frame |
| Shader budget (Adreno) | building 502 of 505 | building unchanged; `panel.gdshader` is a new lit shader with a budget of 260 and no branches in its design | `check_shader_budget.gd` counts it from the first commit |
| Memory | | lookup texture 2 KB; panel buffers 80 bytes a panel, about 0.1 MB a sector; no image textures | not a risk: video memory at the spawn is about 300 MB |
| Sector load | a frame that loads a sector must stay under 33 ms (the iPhone 11 is already over on some) | the panel buffer is made in the bake; the city mesh gets a little smaller | `check_streaming.gd` before and after |
| Pixels | opaque bands | `discard` on the panels' pixels | small area; needs the phone to be sure |

What only the phone can show: the frame with `discard` panels on the iPhone 11 and on the Adreno
6xx test phone, and whether bars shimmer while driving.

## 9. Fallbacks and recovery

If a gate fails, step down this ladder; each step is a switch, not a rewrite.

| If | Then |
| --- | --- |
| Draw calls over the ceiling in the helicopter or zoomed-out view | panels get a visibility range (as `fine_detail`, 170 m), so far sectors cost nothing; hedges and low walls, which are opaque, can stay in the city mesh as today |
| The frame drops on the iPhone 11 | a field in `tiers.gd`: on Low the panels are drawn closed with the type's tint (no `discard`); the governor never touches it |
| `panel.gdshader` fails to link on Adreno 6xx | a lite path for that GPU as the building shader has: closed panels with posts and rail only |
| Bars shimmer or crawl | fall back to posts, rails and an even tint for the fill at that zoom |
| A sector load goes over 33 ms | cap the panels per sector; the longest plain runs merge to 5 m panels |
| The panels disappoint on the phone altogether | **`--barriers=classic`** and the same setting in the bake: today's builder, kept until the phone bench has passed twice. The heavy kit and the types still apply; the broken look stays at debris only |
| A type looks wrong | it is a row: set its row to the default look, or override a line by id in `road_objects.json` |
| A rule mislabels a setting | the rule is dropped to `default`; `check_map_data.py` shows the metres that moved |
| The two city paths disagree | the panel list is baked once and read by both; a check compares panel counts per sector on both paths |

Recovery of broken things in play (the car never trapped, repair out of sight, a whole city on a
new launch, `--no-soft` for developers) is the build plan's section 5 and needs nothing more
from the look, except that a repaired panel stands up again (section 7).

## 10. The plan, in phases

One PR each. W1 and W2 do not wait for anything. W3 to W5 follow the build plan's item 3 (both
edit the barrier builder in `map_builder.gd`), so they are agreed with that thread before they
start.

| # | Phase | What | Model | Gate |
| --- | --- | --- | --- | --- |
| **W0** | Type sheet | 6 to 10 reference photos per type in `refs/` (never committed), a card per type (sizes, colours, rhythm, broken look); 20-sample check of each context rule | Sonnet, Haiku scout for photos; Opus art-director accepts | light (docs) |
| **W1** | Types in the bake | `tools/barrier_types.py`: full tags, context outlines (`ctx`), `ty` and `tc` on every line; counts in `check_map_data.py` and the archive's "Map data"; the type plot; a verify step. Nothing looks different yet. Needs a re-bake on the Mac (the raw OSM is there) | Opus (map-engineer) | full map chain, both paths unchanged |
| **W2** | Heavy kit | `barrier_kit.json`; the wall builder with foot, cap, piers, panels and end pieces; types of 4.2; heights by setting; guard rails only where a road is | Opus for the builder, Sonnet (object-modeler) per type | full: shots both paths, bench (triangles, draw calls unchanged) |
| **W3** | Panel trial | `panel.gdshader` and the sector `MultiMesh` on one stretch (Marszałkowska in the centre) behind `--barriers=panels`: the bar rule at three zooms, by day, night and rain; draw calls at the four probe views; the Adreno count | Opus (perf-engineer with gameplay-dev) | F looks at phone-size shots; bench; phone run when F allows |
| **W4** | Panels city-wide | all types of 4.1 as kit rows, both city paths, the old fence geometry behind the switch | Opus, rows by Sonnet | full, `--ios`, the streaming soak |
| **W5** | Broken looks | `soft_things` events to panel states, per-type looks of section 7, debris and sound from the kit | Opus | full; `check_soft_things` extended |
| **W6** | Content | hoarding posters with parody developers, graffiti patches, open and closed gates where paths cross fences, bollard rows, night tint | Sonnet, PixelLab inside the loop's limit | light, shots |
| **W7** | Sweeps and ratchet | the street-pass skill takes a type per line; the default share only goes down | sweep skill | per street |

Architecture owners: types and looks are data in `game/data/barrier_kit.json`; the builder stays
in `map_builder.gd`; panel buffers go through `instance_buffers.gd`; the cost switch is a field
in `tiers.gd`; broken state is `soft_things.gd`'s; new scripts get their rows in
`docs/architecture/systems.md`. Add-ons: not used (no agent behaviour, no dialogue).

## 11. Questions for F

Parked in `docs/QUESTIONS.md` with the default each phase would build.

1. **Old pier-and-iron fences** (university, ministries, embassies, churches): do they break like
   other fences? Default: yes, the iron panel falls and the piers stand. The other way: they are
   hard, as walls are.
2. **Graffiti on concrete and plaster walls**: default yes, original tags and parody slogans.
3. **Building-site hoardings with parody developer posters**: default yes.
4. **A fence nothing is known about**: default a thin dark see-through railing 1.4 m high. The
   other way: grey mesh.

## 12. How this was measured

- Lengths, tags and triangle counts: `game/map/centrum.json` on main 05b7c9c, and the builders in
  `game/scripts/map_builder.gd` (`BARRIER_STYLE`, `_mapped_style`, `_wall_along`,
  `_railing_along`, `_build_barriers`, `_build_guard_rails`), `tools/barrier_tags.py`.
- Pixel sizes: `follow_camera.gd` (views 40 to 125 m, pitch 30°), `tiers.gd` (480 lines at
  least; 828 on the iPhone 11 at Sharp).
- The context prototype: `/mnt/project-files/walls-research/wall_context.py` (research only, not
  a bake step). It samples each line every 4 m and votes on tram and rail tracks within 5 and
  14 m, roads within 9 m, steps within 6 m, the area 2 m to each side and the nearest building's
  kind within 12 m. Its thresholds are untuned.
- The photo pilot: 23 Mapillary photos (CC BY-SA 4.0) at 14 places picked by the prototype, two
  per setting where photos exist, read on contact sheets in the same folder. Reference only,
  never committed or shipped. Among them: 1505989927822671 (bars on a foot by a Praga church),
  1444414827202883 (a black bar gate in a Wola yard), 970824793456423 (the graffiti wall mapped
  as a fence), 162602436441635 (piers and iron panels by the Filtry), 136869858384962 (the
  boulevard railing), 1576903606561952 (noise screens), 475545233512398 (a lawn guard and hedge
  in a park), 378134946853997 (overgrown villa fences), 1031851339496432 (Most Świętokrzyski's
  railing). No photos were found near the sampled school, institution and waterside-wall lines.
- OSM tagging: the wiki pages `Key:fence_type` and `Key:barrier` (read 2026-11-13). Warsaw's
  street-furniture catalogue (Katalog elementów małej architektury) has cards for railings and
  bollards; its 72 MB file was not read, so the colours of `rail_street` are from photos only.
- Not measured: draw calls and frame time of the panels (W3), how many context rules pass the
  20-sample check (W0), what the land-use outlines add (W1).
