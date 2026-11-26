# House types: varied standard houses (plan)

F, 2026-11-26: "a lot of the standard homes look the same ... classify the homes, fronts and roofs
and make a global change". Research doc: https://claude.ai/artifact/Rq5dHQe1k6osXxeJUf8ET5
(measured on main 31e9442, reviewed by Fable: go with changes). This file is the build plan.
Named landmarks, photo fronts (`photo_fronts.json`) and modelled street blocks keep their own
looks; nothing here models a building, so the modelling stop is untouched.

## What is wrong today (measured)

- `map_builder.gd _building_type` gives an ordinary house one of 3 drawn types by OSM kind and
  height only: 4,082 tenements (10-26 m), 1,683 slabs (26 m+ or a long bar, about half of all
  wall area), 468 offices. Muranów's 1950s blocks get 383 kamienica fronts; Wola 666.
- `building.gdshader typed_facade` draws each type with one fixed rhythm; the seed moves spacing
  by about 20 %. Every generic ground floor (`facade()`) has shop windows.
- Wall colour: LoD2 walls take one of 12 light beiges (`bake_gugik.py FACADES`), or an OSM
  colour (31 % of buildings, mostly flat greys `#666666`, `gray`, `#999999`) mixed 70 % in.
- Street lists already dress some places, each with its own palette: Nowy Świat, Powiśle,
  Tamka, Aleja Jana Pawła II, the Old Town (`TENEMENTS`), `_district_roof`.
- Windows have no `fwidth` fade (they shimmer when the camera moves); LoD2 walls have no base
  or under-cornice shading.
- Shader budget (`check_shader_budget`, the Adreno 6xx link limit): 503 of 505. Branches,
  `return`s, `?:`, `&&`, `||` and calls count; array indexing and texture reads do not.

## Rules every phase keeps

- One owner: `game/scripts/house_types.gd` (pure, static) decides a house's type, zone and
  palette; `game/data/house_types.json` holds zones, palettes and the rhythm table. The street
  lists above move into it with a stated precedence (photo front > landmark skin > street list >
  zone > OSM colour > generic). No private palette elsewhere.
- Load time only, shared by both city paths (runtime and prebuilt). No re-bake of `centrum.json`
  until phase 4.
- 0 new draw calls. Shader budget may not rise above today's 503; phase 2 must lower it.
- Every phase: `tools/verify.sh --quick` + the new check, before/after shots of the shot boxes
  on both city paths, bench before/after (Mac in the cloud numbers; A56 and iPhone when F allows
  device runs). One PR per phase, through the audit thread.

## Shot boxes (judging, not a pilot area)

The rule is global, so it is judged in small boxes that each hold one problem:

| Box | Where | What it shows |
| --- | --- | --- |
| A Hoża/Wilcza | pre-war kamienice, perimeter blocks with courtyards | tenement rhythm, palettes, courtyards |
| B Muranów | 1950s Lachert blocks, hipped roofs | the worst misclassification today |
| C Za Żelazną Bramą | 1960s-70s slabs and point blocks | half of all wall area |
| D Plac Konstytucji | MDM socrealism | the hardest type (arcades, attic) |
| E Ząbkowska | Praga brick tenements | palette-only type |
| F Powiśle (Tamka) | existing street-list dress | must not regress |

Each box: day and night, runtime and `--prebuilt`, one helicopter shot from above.

## Types and rhythms

A type is a rhythm (how the facade is drawn) plus a zone palette (wall, trim, roof colours) plus
small switches (shop share, loggias, balconies, clutter). 8 rhythms give the 15 Warsaw types.

| # | Type | Rhythm | Palette | Where |
| --- | --- | --- | --- | --- |
| 0 | generic | `facade()` as today | default | low and unknown buildings |
| 1 | kamienica, 1880-1914 | R1 tenement | ochre, grey, cream render | Śródmieście Płd., Koszyki |
| 2 | Praga brick kamienica | R1 tenement | red-brown brick, light bands | Praga |
| 3 | modernist kamienica, 1925-39 | R2 interwar | smooth cream, white | Powiśle, Mokotowska |
| 4 | Old Town rebuild | R0 oldtown (as today) | Old Town pastels | Stare/Nowe Miasto |
| 5 | MDM socrealism | R3 socreal | sandstone, grey stone | Marszałkowska, Pl. Konstytucji |
| 6 | Muranów 1950s | R4 plain post-war | pinkish grey, ochre | Muranów |
| 7 | post-thaw modernism | R5 grid frame | white, pastel infill | Ściana Wschodnia, Mirów |
| 8 | wielka płyta, as built | R6 panel | grey concrete | estates |
| 9 | docieplony blok | R6 panel | white with colour blocks | most estates today |
| 10 | point block | R6 panel, square plan | as 8 / 9 | Za Żelazną Bramą |
| 11 | PRL office, pavilion | R7 ribbon (as T_OFFICE) | spandrel greys | Marszałkowska, Świętokrzyska |
| 12 | 1990s postmodern | R7 ribbon + glass bays | granite, green glass | Grzybowska, Prosta |
| 13 | developer 2005-26 | R5 grid frame, big panes | white + anthracite | Wola, Powiśle |
| 14 | glass tower | curtain wall (as today) | glass | over 55 m |
| 15 | factory brick | R1 with no shops, tall windows | red brick | Wola, Koneser |

Encoding (one helper in `house_types.gd`, one macro in the shader): UV2.x = 1 + (T + 0.96 × seed)
/ 16 for T = 0..15; landmarks stay at 2 and up; the Old Town's square flag stays in its seed's
upper half. Decode sites to change together: `typed_facade` dispatch, `roof_surface` (line
~1048), `_roof_dress`, `_powisle_house`, `_tenement_facades`, the OSM path at
`map_builder.gd:9759`.

## How a house gets its type

1. Zone: `house_types.json` "zones" (about 20 polygons in map metres, drawn from Warsaw's
   building history over the ortho; `districts.json` is too coarse) give a default type, the
   allowed types with weights, a wall palette, a roof palette, and whether the palette replaces
   grey OSM colours (`grey_override`, default true).
2. Floor height = eave height ÷ levels. Eave = area-weighted median of the wall tops already in
   the walls' UV2.y (not the ridge: a pitched roof adds 3-5 m). Levels = round((h - 1) / 3.3)
   where the bake derived h from levels (8,021 of 12,873 sit on that grid), else unknown.
   ≥ 3.6 m pre-war (1, 2, 5, 15), ≤ 3.05 m post-war housing (6-10), between: the zone default.
3. Shape: courtyard perimeter (the block has an inner ring) points to pre-war; a long bar to a
   slab; a near-square plan over 15 floors to a point block (10).
4. OSM tags when present win: `building:material=brick` (2 or 15), `start_date`, `roof:shape`;
   a real (non-grey) `building:colour` keeps its colour.
5. A seeded weighted pick inside the zone's allowed set. The seed is the building's place (never
   an index), so the runtime and prebuilt paths agree.
6. Lookup fix: the LoD2 run finds its OSM house by a wall-triangle centroid nudged inward, not
   the bounding-box centre (which lands in the courtyard of U- and L-shaped houses).

Ground truth: the 425 photo fronts carry `style` (classic, plain, fins, ribbon, glass), `gf`
(ground floor height) and wall colour. `tools/check_house_types.py` (verify step `housetypes`,
quick) runs the classifier on them (as if they were plain) and fails below the recorded score;
it also checks the JSON (zones valid and inside the map, palettes parse, weights sum).

## Phases (after the Fable review of 2026-11-26)

Fable: "go, with a re-cut". Phase 1 keeps today's encoding (no shader edit); the 16-slot
encoding moves to phase 2a, where the shader first needs it.

| PR | Scope | Time |
| --- | --- | --- |
| 1 | census + sorting and colour, old encoding, no shader edit | 2-2.5 days |
| 2a | 16-row encoding + flat parametric facade + window fade + base band | 3 days |
| 2b | night windows, stairwells, clutter, shop share (after a device bench of 2a) | 1.5 days |
| 3 | roofs by type (`roof_dress.gd`, extend `check_roof_dress`) | 1 day |
| 4 | levels and tags in the bake, photo check per zone (Mac) | 1 day |

### PR 1: sorting and colour

- New: `game/scripts/house_types.gd` (pure, static), `game/data/house_types.json` (written by
  `tools/house_zones.py`), `game/tools/check_house_types.gd` (verify step `housetypes`, quick:
  JSON, rules, photo-front scores per class, an OSM-rule estimate per zone). The game's own count
  is the build's `house types:` line.
- `map_builder.gd`: `_typed_lod2` and the OSM path (`_osm_house_type`) ask HouseTypes and keep
  today's drawn rhythm 1-3 (`typed_seed` unchanged); `_building_type` stays as the "typed at
  all" gate and for `_powisle_house`. The street lists (Nowy Świat, Powiśle, Tamka, Aleja Jana
  Pawła II, the Old Town) keep their palettes and types on both paths, and walls
  `_tenement_facades` painted are never repainted; moving their palettes into the JSON is TD-37.
- OSM colour: a coloured tag stays; an empty or mid-grey one (not white, not black) gives way.
- Floor height only on LoD2 runs: on the OSM-only path UV2.y is `h` itself, so the rule would
  be circular. Plant boxes (UV2.y -1) are skipped. OSM tags other than `c` wait for PR 4 (the
  baked buildings carry only h, mh, c, rc, kind, name, p).
- Recolouring keeps the bake's base gradient (bottom 6 m to 0.88) and the alpha (glass flag).
- No roof recolour on LoD2 roofs: they are ortho-sampled and `roof_surface` picks the material
  from that colour. OSM-path roofs only.
- Both `CITY_INPUTS` lists (`bake_city.gd`, `check_map_data.py`) gain the new script and JSON,
  or stale prebuilt sectors pass the check.
- Rows in `systems.md` and `extending.md`, one change note.
- Shots: boxes A-F day and night, runtime and `--prebuilt`, before and after; one Old Town and
  one photo-front street as "must not change". Checks: `verify.sh --quick`, `check_map_data.py`,
  `roofdress`, `tenementtrim`, `oldtownroofs`, `sites`. Bench before/after (no change expected).
- Phone only: whether the palettes read at phone size and brightness.

### PR 2a: one parametric facade

- UV2.x = 1 + (T + 0.96 x seed) / 16 for T = 1..15; generic stays in [0, 1). Change every reader
  together: dispatch (~1135), `roof_surface` (~1048), `_roof_dress` (~11793, else new types get
  chimneys or metal coping), `_powisle_house`, `OLD_TOWN_TYPE` (~11549, 11888).
- One flat facade function reading `uniform vec4` arrays indexed by type (16 rows); fallback a
  small data texture if Adreno 6xx dislikes dynamic uniform indexing. Arrays set after the
  prebuilt material swap (`main.gd` ~7237 and the lite swap) as well as at ~1430.
- Window fade by `fwidth`, base band, shadow under the cornice. Budget target 450 or less.
- Update `decisions.md` (line ~50) and tech-debt TD-9, which this changes.
- Phone only: the Adreno 6xx link and frame time on the A56 and Nothing Phone.

### PR 2b: night life and clutter

- Shop share per type, lit stairwell columns, blue TV flicker in a few panel windows, dishes,
  AC boxes, flower boxes, laundry. Only after the 2a device bench; Low quality drops clutter.

### PR 3: roofs by type

- `roof_dress.gd`: lift rooms and vents on slabs and point blocks, antennas and dishes on
  post-war roofs, skylights on offices. Triangles before/after, helicopter shots.

### PR 4: the bake (Mac)

- `bake_osm.py` writes levels, `building:material`, `start_date`, `roof:shape`; full chain,
  `check_map_data.py` counts; 20 houses per zone against street photos.

## Cheap extra wins (re-ranked by the review)

1. **Ground-floor life by zone** (keep, cheapest): the shop share in the type row (2b) plus
   `storefronts.gd` sign density per zone.
2. **Parked cars by zone** (new, half a day): thin or densify the existing `parked` list per zone
   (estates full, the Old Town empty). No new mesh.
3. **Night windows per type** (keep, part of 2b).
4. **Podwórka** (keep, re-scoped, 2.5-3 days): yards already have trees, benches, bins, parked
   cars and playground surfaces. Start with trzepaki, bin shelters and the playground kit
   (`park_props_play.gd`) on existing playground surfaces, through the `street_details` /
   `park_details` pattern (about one draw call per 512 m cell in view).
5. **Minor-road tint by zone** at build time (half a day, no shader cost) instead of a ground
   shader change (ground is at 225 of 260 and has no zone).

## Risks

| Risk | Guard |
| --- | --- |
| A wrong type looks worse than a generic one | zones + photo-front score + phase 4 photo check |
| Too much colour reads as a toy | palettes from photo-front colours and Warsaw photos, saturation cap in the check |
| GPU-bound Androids lose fps from the parametric facade | bench before/after; Low quality keeps the rhythm table but drops clutter and fade |
| Budget over 505 breaks the building shader on Adreno 6xx | `check_shader_budget` in verify; phase 2 must lower it |
| Prebuilt and runtime paths disagree | seeds from place; shots both paths; `bake_city` site check |
| Street-list looks (Nowy Świat, Tamka, Powiśle) regress | box F; precedence table; their geometry untouched |
