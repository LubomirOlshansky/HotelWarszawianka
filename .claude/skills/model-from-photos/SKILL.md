---
name: model-from-photos
description: How Around Warsaw builds a landmark or building model that reads as the real one - reference photos first (any photo from the internet, any licence, as reference only; Commons, Mapillary/Panoramax and the rest, kept in the gitignored refs/ and never shipped), a spec written from the photos at a set detail level, the build, and a side-by-side check of the game shot against the photo with a scored checklist. Use when writing a landmark spec, building or reworking a model (landmarks.gd, models.gd, props.gd, map_builder facades), and when accepting one.
---

# Models from photos: the detail bar and the photo check

The user, 2026-10-31: "I want more detailed models", compared against real photos, the way a
good isometric city game builds each landmark as a small program from photos and maps, tested
for defects, with a person making the final pick. Until then specs came from the OSM outline,
GUGiK LoD2 heights and what the model remembered; nobody put a photo beside the shot.

## 1. Reference photos (before any spec)

**The order (Ufficio Primo pilot, F 2026-11-26).** Each source answers different questions; take
them in this order and write no spec line before steps 2 and 3 are back.

| Step | Source and command | Answers | Cost |
| --- | --- | --- | --- |
| 1 | Facts: Wikipedia, the owner's or architect's site (a `web-fetch` or Haiku `scout` run) | storeys, year, architect, materials, what stands on the roof | 1 min, ~50k tokens in a subagent |
| 2 | Google 3D Tiles: `node tools/tiles3d/render.mjs --building="NAME" --slug=KEY --angles=8 --pitch=-25` (start it first, in the background; 8 views at -25 match the turntable's low ring for `refs_compare.py`; the tool's default 6 at -28 pairs only 6 sides; with `--building` it adds 4 square-on face views at pitch -10 that show the whole height down to the ground, `--no-faces` skips them) | massing, true height, **the roof** (the game's main view), hidden and back faces, the neighbours | 5-7 min, 1 billable run |
| 3 | Street View: `python3 -I tools/streetview_fetch.py --building="NAME" --slug=KEY --fov=100` | bays and storeys per face, ground floor, doors, colour | 10 s, ≤ 16 images |
| 4 | Mapillary / Panoramax / Commons / F's photos (below) | only what 2-3 lack: older or newer state, night, a detail | as needed |
| 5 | GUGiK orthophoto (below) | true footprint under a leaning tower | optional: the cloud proxy blocks geoportal |

- `--building` takes the name as `game/map/centrum.json` has it (both tools). Street View picks one
  Google panorama per side of the outline's bounding rectangle, aims three shots (the side's
  middle and both ends), sets the pitch from the height, skips user photospheres and sides it sees
  more than 45° off square. **A building set back in a garden or a yard** (a church behind trees,
  a palace in a park) gets nothing useful from Street View: its faces come from 3D Tiles.
- **Google images stay local** (Street View, 3D Tiles, and any sheet that holds them such as
  `refs/KEY/KEY_vs_refs.png`): in `refs/` only, never in a PR, an artifact, a post or a message's
  attachment (show F the turntable and city shots instead), and not pushed to the shared store
  (`refs_store.py push` skips `streetview/` and `3dtiles/`). Delete them when the model is
  accepted (`rm -r refs/KEY/streetview refs/KEY/3dtiles`): what the spec measured from them is
  in the spec. Google's terms limit storing and deriving from its content; this is reference by
  eye only (F decides on anything more).
- **The shared folder holds our own pictures only**: `/mnt/project-files` (and any page or reply)
  gets the turntable, city shots and other renders of the game, never a Street View image, a 3D
  Tiles render or a compare sheet that shows one. To hand Google references to another thread,
  give it the command that renders them; it renders its own into its working copy's `refs/`.
- **A square, a street front or a block of houses is one 3D Tiles run**, not one per house: aim
  it with `--lat/--lon` (or game `X Z`) at the middle and `--area=R` with R holding the whole group
  (the Old Town, Plac Zamkowy: 8 orbits at pitch -35 plus the top), then crop per house from the views. Unnamed OSM
  buildings use the X Z forms of both tools.
- **Look at one sheet, not twenty files**: `montage refs/KEY/streetview/*.jpg -tile 4x -geometry
  420x420+2+2 /tmp/sv.jpg` (or `game/tools/shot_sheet.gd`), and the 3D renders the same way. A
  reviewer reads one image per source; a crop at full size only for a count (bays, skylights).
- **The spec may start while the render runs**, but its Roof section and the roof rows of the
  parts table say "pending top view" until the render is back, and the builder starts with the
  walls (the pilot's first spec guessed the roof and had it wrong).
- **Count and measure on the top view**: element counts (skylights, roof lights, chimneys), their
  size against the face length, and colours of the roof come from the 3D Tiles top view; the first
  Ufficio spec, written before it came, had the dome 40 % too small and the wrong colour.
- **OSM `h` is a guess** (Ufficio Primo: 17.5 m mapped, 24 m real): heights come from the storey
  count × the photo and the 3D Tiles side views.

- **Any photo from the internet (F, 2026-11-08)**: when a building lacks photos, download them yourself from anywhere (Commons, Mapillary, Panoramax, news, blogs, company or architect sites, any search result) without checking the licence: they are modelling references only, kept in the gitignored `refs/`, never shipped in the repo or the game. Don't wait for the user for photos.
- **Where**: the shared store `/mnt/project-files/refs/<slug>/` is the home (a network mount all cloud
  threads see; the Mac does not mount it). `refs/<slug>/` at the repo root, gitignored, is the working
  copy (other people's photos, whatever their licence, never go into the repo; Google's Street View and
  3D Tiles images live only in the working copy, never in the store). Before writing a spec
  `python3 -I tools/refs_store.py pull <slug>`; right after gathering `push <slug>` (it re-runs the index).
  A cloud thread reads the store's `INDEX.md` first (ranked like the inventory; `gaps` lists what is
  missing, `where TEXT` finds a slug) and asks for the Mac only for what the store lacks. `SOURCES.md` lists each file: Commons
  page URL, author, licence, and one line on what it shows (angle, which face). The slug is the site key in
  `landmarks.gd` when there is one; `tools/refs_slugs.tsv` ties slugs to inventory rows.
- **What**: 3-4 photos a building: one street-level front, one elevated or aerial view that
  shows the whole silhouette and roof (the game is seen from above), one detail (base,
  entrance, crown). Daylight; a night photo only for what lights up.
- **From**: Wikimedia Commons first (the API
  (`commons.wikimedia.org/w/api.php`, `generator=search`, `gsrnamespace=6`,
  `prop=imageinfo`, `iiprop=url|extmetadata`, `iiurlwidth=1600`), the 1600 px thumb, a
  descriptive User-Agent. Free downloads are pre-approved (CLAUDE.md "Hard rules").
- **Google Street View (F, 2026-11-26)**: `python3 -I tools/streetview_fetch.py --building="NAME" --slug=<slug>` (above), or one spot: `X Z --slug=<slug> [--headings=0,90,180,270 | --heading-to=LAT,LON]` (`--list` first; metadata is free); 640 px views into `refs/<slug>/streetview/` with SOURCES.md lines. Needs `GOOGLE_STREETVIEW_KEY` in the environment (setup: docs/design/streetview-setup.md). Often the best-dated and sharpest street view in Warsaw; use it next to Mapillary, Panoramax and fotopolska. Reference only: never committed, shipped or traced. Fetch few headings (images are the billable call).
- **Also from street level (F, 2026-11-04)**: Mapillary and Panoramax, both CC BY-SA 4.0 (Panoramax
  also etalab-2.0, per photo): `python3 -I tools/street_photos.py X Z --r=40 --slug=<slug>` saves the
  newest photos whose camera faces the point into `refs/<slug>/street/` with their SOURCES.md lines
  (`--list` to look first). This works **in the cloud** (Mapillary needs `MAPILLARY_TOKEN` in the
  environment, a client token from F's free developer app; Panoramax needs no key), so a cloud thread
  can gather street photos for a landmark itself. Use them for what Commons rarely has: the
  shopfronts and ground floor, the facade from the street the player drives, side and back faces,
  street furniture, recent changes (Commons photos are often years old; Mapillary is often 2024-26).
  Take several headings round the building (run it from 2-4 points on its streets). Car-mounted
  photos are low and wide-angle: verticals lean, so read storeys and bays, not proportions, from
  them. Faces and plates are blurred by the services; never crop a person into a reference. Google
  Street View only through `tools/streetview_fetch.py` (above).
- **Who**: Commons and the orthophoto from the Mac (or a Remote Control session on it); street-level
  photos from anywhere. Cloud containers get 403 from
  Wikimedia: a cloud thread fetches from other web sources itself, the Mac, or the photos the user drops in chat.
  Photos are never published, never traced into textures, and never shipped in the game.
- Open every photo before using it; drop the wrong building, crops and interiors.
- **The view from above: `refs/<slug>/ortho.jpg`**, a crop of GUGiK's orthophoto (geoportal.gov.pl,
  free open data since 2020; the official WMS, `PZGIK/ORTO/WMS/HighResolution`, else
  `StandardResolution`): the footprint plus 30 m (at least 120 m square, ~250 m for the Palace
  and the stadium), about 2048 px wide, with the WMS, layer, bbox and CRS in SOURCES.md. The
  game is seen from above, so this is the photo that shows what the player sees most: the roof
  (shape, skylights, plant, courtyards), the footprint against the OSM outline, what stands
  round it. Game x/z to lat/lon: the map's `origin` and `project` in `tools/bake_osm.py`.
  What worked (2026-10-31): `https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution`,
  layer `Raster`, WMS 1.3.0, EPSG:4326 (axis order lat,lon in the bbox), image/jpeg, up to
  4096 px, no key (a User-Agent only). It is not a true ortho: **towers lean**, their roofs
  shifted off the base (Varso, Złota 44, Warsaw Unit, WCF); take roof plans from low
  buildings, and a tower's footprint from OSM. Some sites are blurred by the Geoportal itself
  (Dom bez Kantów, parts round the Presidential Palace).
  Apple's 3D views may be looked at, never downloaded or copied (their terms); Google's only through
  `tools/tiles3d/render.mjs` (below), which keeps to Google's terms.
- **Google 3D renders: `refs/<slug>/3dtiles/`** (F, 2026-11-26). `node tools/tiles3d/render.mjs
  --building="NAME IN centrum.json" --slug=NAME` (or `--lat= --lon=`, or game `X Z`) renders the building live from Google Photorealistic
  3D Tiles: 6 orbit views and a top-down, Google's attribution on each image, in the cloud or on the
  Mac (docs/design/tiles3d-setup.md). Best for roof shapes, heights, back and courtyard faces. The saved screenshots are local-only references that
  never leave `refs/`: not in the repo, posts, PRs or artifacts. Look,
  measure by eye and write values into the spec; never export, cache, trace or import the mesh
  (Google's terms). One run is one billable root request: one run per building, not per view.

## 2. The spec (Opus, from the photos)

The spec is self-contained text: the Sonnet builder may have no photos, so everything the
photos say goes into the spec as values. Sections, every value filled:

1. **Identity**: the 3-5 features that make a passer-by say its name (Palace: the stepped
   tiers, the spire, the corner pinnacles, the attic parapets). These are judged first.
2. **Massing**: footprint from the OSM outline (`centrum.json`), heights from LoD2 and from the
   photos (storeys × ~3.2 m, or proportions measured against the footprint), each volume's
   setbacks.
3. **Facade, base to top**: the base (arcade, plinth, shop glass, entrance, steps), the middle
   (window grid: bays per face, storey bands, recess depth, piers or fins), the top (cornice,
   attic, parapet). Window rhythm in bays and storeys, not "some windows".
4. **Roof**: shape, crown, skylights, plant, spire, flagpole, counted and placed from a top view
   (the 3D Tiles `*_top.png`, or `ortho.jpg`), not guessed; the section names the file it read.
5. **Colour and material**: sampled from the daylight photos, then mapped to the art bible's
   palette (the game's colours stay calmer than the photo); which material code each part uses.
6. **Ground and night**: what stands at its foot (steps, a forecourt, a canopy, the sign under
   a parody name), what lights up at night.
7. **Detail level and budget** (below), and the shots to take.
8. **Parts table**: one row per part (id, shape, size, position, material code, which identity
   feature it serves). The builder names its functions after the part ids, and a failed check
   or a reviewer's fix points at a row, not at prose. Windows, balconies, ledges, cornices,
   pilasters, columns, pediments, porticos and lanterns are **facade kit parts**
   (`docs/design/facade-kit.md`): the shape cell names the part and its style
   (`kit_window SILL_HEAD`, `kit_balcony IRON`), and the material cell a palette name
   (`PAL_SANDSTONE`) unless the photo gives the building a colour of its own. A part the kit
   lacks is written as a new kit style, not as a helper of the landmark.

The spec lives at `docs/landmarks/specs/<slug>.md`, and `tools/check_spec.py` (a `verify.sh` step,
`spec`) FAILs one that lacks a section, a level, a budget number or a filled parts-table cell
(columns: id, shape, size, position, material, feature). Run it before handing a spec to the builder.

## 3. Detail levels

| Level | What it has | For |
| --- | --- | --- |
| L1 silhouette | the right massing, heights and colour | background buildings |
| L2 articulation | L1 + the facade's base/middle/top, real window rhythm, cornices, roof shape | every named landmark |
| L3 signature | L2 + every identity feature modelled in 3D (columns, pinnacles, fins, arcades, crowns, sculpture as blocks) and its ground | hero landmarks: the first scene (docs/design/first-scene.md), the Palace, the Old Town square, the Castle, the stadium, the bridges, the towers on the skyline |

**Detail costs triangles, not draw calls.** The phone's frame grows with draw calls
(DEVELOPMENT.md "Performance budgets"), so detail goes into the one shared building material
through the landmark material codes (no draw call of its own), merged into the site's mesh.
Budgets in triangles: L2 up to ~3,000, L3 up to ~8,000 a site (the Palace and the stadium may go
higher, named in the spec); the site's triangle budget goes into `BUDGET` in `game/tools/check_mesh_quality.gd` in the same change (a site without an entry fails the check).
No new material, light or MultiMesh without a measured before/after draw-call count. Window
grids belong in `building.gdshader`'s window rhythm, not one mesh per window.

## 4. The checks, in this order (research 2026-10-31)

Cheap checks first, the expensive eye last: retrying on error feedback is what makes code-built
models work; longer agent runs don't improve the shape, and the commonest failures (floating
parts, z-fighting) are ones a judge looking at shots misses.

1. **Automatic** (the builder, before any review): the site's triangle budget and the mesh check
   for the one site, in the inner loop (`godot --headless --path game --script
   res://tools/check_mesh_quality.gd -- --site=KEY`, 14 s; the whole run takes 6-7 min in the
   cloud and is the gate once, before the PR, with `tools/verify.sh --quick`): coplanar
   overlapping faces, zero-area and flipped triangles, parts touching neither the ground nor
   another part. A FAIL goes back to the builder, not to the reviewer. A new site on an **unnamed**
   OSM outline also needs its box in `tools/bake_sectors.py` `SITE_AREAS`, or the runtime city
   draws nothing there (no headless check catches it; the turntable does not either).
   **Another model may already stand in the outline**: a street block (`game/data/street_blocks`,
   `blk_<id>` sites), a photo front or a skin. The turntable builds the site alone and hides it;
   `check_sites.gd` (headless, seconds) fails on a landmark over a street block, and the fix is the
   block's id in `fronts.gd` `_find_blocks`' skip list (Ufficio Primo's first city shot showed the old
   block's dome over the new model). Run it with the mesh check, and take one city shot at the end.
2. **The builder's own look, in stages**: massing first (render, compare the silhouette with
   the photos), then the facade, then the roof and the small details, each stage rendered
   and compared before the next (a wrong silhouette is cheapest to fix before the facade).
   Measurable gaps (a height, a storey count, a setback) are fixed against the photo inside
   the stage; anything the photos don't settle goes to Escalate.
3. **The reviewer** (`art-director`, Opus), section 5 below.
4. **At most two fix rounds** between builder and reviewer; still failing after two, the spec
   is wrong or open: the lane session re-specs or asks the user. No third guess.

**Detail without draw calls.** The Mobile renderer has no automatic instancing: N copies of
a column as separate nodes cost N draw calls. Cornices, pilasters, columns, battlements and
lamps on a landmark are triangles merged into the site's mesh with the shared material; only a
kind repeated across the whole map gets one MultiMesh. No new node, material or decal per detail.

## 5. The photo check (after the build)

- **Matched shots**: for each reference photo that shows the silhouette, a game shot from the
  nearest angle (`--at=x,z` and the camera, helicopter for aerial views), at 2532x1170, day.
  For the top view, the turntable's top tile against the 3D Tiles top (`refs_compare.py` pairs
  them) or `ortho.jpg`.
  Plus the usual before/after at the default view.
- **Shots for the judge**: besides the lit matched shots, one unlit (flat colour) shot and one
  silhouette on a plain background per main angle, with the landmark alone when the flag
  exists: shape errors hide in lighting and street clutter.
- **References beside the model, on one sheet**: after the turntable,
  `python3 -I tools/refs_compare.py KEY` pastes the 3D Tiles renders (row 1) over the turntable
  tiles seen from the same side (row 2) and the two top views
  (`refs/KEY/KEY_vs_refs.png`). The builder's stage looks and the reviewer's scores
  start from this sheet; the Ufficio Primo fix round came from it in one look. It holds Google
  imagery: it stays in the working copy's `refs/`, never in a PR, a post or an artifact.
- **The turntable is the first look at any model**: `tools/turntable.sh KEY` (about a minute) gives
  every side of the site on one sheet (lit from 8 sides at two heights, flat, silhouette, top
  view), so a builder and F check the whole model before any single matched shot is taken. The
  sheet is `shots/turntable_KEY/KEY_turntable.png`; open it and look, then take matched shots for
  the sides that need a closer look. A kept skin (a SKINS entry, LoD2's mass recoloured) works the same:
  the sheet shows its LoD2 building alone, in the skin.
- **Show the turntable to F**: every "model done" reply opens with the turntable sheet, attached,
  and says in a line what it shows; city shots come after it. F judges the whole model from it
  (F, 2026-11-16: "why you do not show turntables after the modeling done"). When the thread
  can attach no more files, put the sheet on the lane's turntable page (an Artifact) and link it
  at the top of the reply; a path in the shared folder alone is not showing it.
- **Side by side, photo first**: the reviewer opens the photos and shots and scores them
  *before* reading the spec (a judge favours what it wrote or read; the spec comes after, to
  name what is missing). Scores 1-5 on silhouette, proportions, colour, identity features
  (each one named: there or missing), facade rhythm, roof (against the top view), ground. Every score cites what in the
  shot earns it ("the spire's base is 1.4x too wide against photo 2"). Pass: every score ≥ 4
  for L3, ≥ 3 for L2. A missing identity feature is a fail whatever the scores. A one-point
  difference is within a judge's noise: a borderline score is looked at again, not argued.
- **Anchors** (what the numbers mean, the same for every landmark):

  | Score | Silhouette and proportions | Colour | Identity features | Facade rhythm | Ground |
  | --- | --- | --- | --- | --- | --- |
  | 5 | reads as the photo's outline from its angle; every volume's ratio within ~10 % | the photo's hues, calmed to the palette, right light/dark split | all there and placed right | bays and storeys counted right, base/middle/top clear | what stands at its foot is there |
  | 3 | recognisable, one volume or ratio clearly off | right family, one part wrong | all there, one misplaced or crude | rhythm close, one band or level missing | partly |
  | 1 | could be another building | wrong colour family | one or more missing | generic grid | nothing |

- **Choosing between two builds**: compare them pairwise, twice with the order swapped; if the
  two answers disagree, call it a tie.
- **Defects** (automatic where a check exists, by eye always): z-fighting and flicker on
  coplanar faces, a part inside another, floating or sunken parts, gaps at joins, faces that
  vanish at a zoom.
- **The user picks last**: the report to the user shows photo, before and after for each hero
  landmark; the user's "no" sends it back.

**The list**: `docs/LANDMARKS.md` holds every landmark's state and the plan by priority; a
thread that lands an item ticks its row there. **A log per landmark**: `docs/landmarks/<slug>.md` (short): the spec's link, the scores per
pass, what was fixed, what still differs from the photos. The next thread reads it first.

## 6. Who does what

| Step | Who | Model | Pilot time (Ufficio Primo, cloud) |
| --- | --- | --- | --- |
| Facts | `web-fetch` or `scout` | Haiku | 1 min |
| 3D Tiles + Street View (section 1 steps 2-3), the sheets | the lane session runs the tools | (no model work) | 7 min in the background |
| Write the spec from the sheets | the lane session | Opus | 15 min |
| Build to the spec, mesh check per site, turntable | `object-modeler` | Sonnet | 55 min (most of it waiting on the whole mesh check, now `--site`) |
| Fix rounds from `refs_compare.py` | the lane session, small edits itself; a large one back to the builder | Opus | 10 min a round |
| Score against the photos (section 5) | `art-director`, every L2 and L3 site: one read of the compare sheet and the turntable, photo first, at most ~300 words, after the lane's first fix round (the pilot's author-made fix moved the dome's colour the wrong way; Fable's review caught it) | Opus | 5 min |
| City shots (before and after, both paths) | the lane session, once at the end | | 14 min a shot in the cloud (software Vulkan): two in parallel |
| Final pick | the user | | |

Fable (F, 2026-11-13) only for deciding: a hero landmark's acceptance or a disputed look.

## 6b. A place that is not a landmark site

Furniture, signs, standing people or a small structure at one spot (a bar's terrace, a kiosk row)
is a **place script**, not a site in `landmarks.gd` and not a `_build_x` hook in `main.gd`: a script
that `extends "res://scripts/place.gd"`, static meshes through `pour(...)`, plus one row in
`Places.TABLE` (`game/scripts/places.gd`) with its triangle budget. `check_place_scripts.gd` holds it
(docs/architecture/extending.md).

## 7. Evals (planned, not run yet)

To learn whether this skill beats a plain brief: build the **Palace**, the **Rotunda** and the
**Muzeum Sztuki Nowoczesnej** twice each, once with the skill (photos, a spec that passes
`check_spec.py`, the checks of section 4) and once with a one-paragraph brief and the same
Sonnet builder. Score both with `art-director` by section 5 (photo first, same anchors, the
pairwise order-swap rule), using `tools/shots.sh --set=first` for the solo flat and silhouette
shots. Record scores and triangle counts per landmark in `docs/landmarks/<slug>.md`. Needs the
reference photos in `refs/` and a Mac or GPU run, so it waits for the first hero thread that has them.
