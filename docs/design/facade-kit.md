# The facade kit and the palette

Item 4 of `docs/design/building-pipeline-review.md` (2026-11-13). Every landmark used to invent
its own windows, ledges, balconies and colours: 21 private window helpers, 1,852 different hex
colours. This is the shared set. A landmark is written in kit parts and palette names; what the
kit has no part for is built from the core as before, and becomes a kit part when a second
landmark needs it.

- Code: `game/scripts/facade_kit.gd`. `landmarks.gd` extends it, so a site calls everything here
  without a prefix. The split of `landmarks.gd` by site (item 5) moves sites, not the kit.
- No shader change: the kit is geometry in the materials that exist (`M_STONE`, `M_GLASS`,
  `M_PANE`, `M_LAMP`). The building shader stays at its Adreno budget.
- Proof tools: `game/tools/site_dump.gd` and `tools/site_parity.py` (below).

## 1. Layers of `facade_kit.gd`

| Layer | What | Names |
| --- | --- | --- |
| Core | material codes, one triangle / quad / wall / prism into the city surface, roof grid and picking grid | `M_*`, `S_*`, `_tri`, `_quad`, `_wall`, `_prism`, `_cap`, `_frustum`, `_pyramid` |
| Local frame | a front's own axes: u along the wall, v out of it, y up (absolute) | `_o`, `_a`, `_b`, `_w`, `_rect`, `_lbox`, `_column`, `_gable`, `_hip`, `_disc`, `_arch_panel` |
| Parts | whole facade elements with fixed proportions | `kit_*` |
| Palette | named colours | `PAL_*` |

## 2. Rules for a site

1. Set the frame once per front with `kit_front(from, to)`: u runs from `from` to `to`, v points
   out to the left of that direction (walk along the front with the street on your left). It
   returns the front's width. `kit_face(v)` says where the wall's surface is in v (0 by default);
   every part stands on that face.
2. Heights are absolute, as in `_lbox` and `_prism`: pass `g + 5.3`, not `5.3`.
3. Proportions belong to the kit. A part takes where it is, how big it is and its colours; sill
   depth, reveal, rail height and the night-light rule are not arguments. A front that needs
   another proportion needs a new style in the kit (one PR, with a look), not a private helper.
4. Colours come from the palette. A colour of the building's own (a brand red, a measured
   plaster from a photo) is a named constant of that site with a comment saying where it was
   measured; `lightened()` / `darkened()` of a palette colour are fine.
5. Parts first, walls after: a part stands a few centimetres proud of the face, so nothing
   z-fights; the kit's own parts never overlap each other in one plane.
6. No new `_xx_window`, `_xx_panes`, `_xx_balcony`, `_xx_ledge`, `_xx_cornice`, `_xx_pediment`,
   `_xx_column`, `_xx_pilaster` function in `landmarks.gd`: `tools/check_facade_kit.py` (verify
   step `facadekit`) counts them and fails when the count grows. The ones that exist are listed in
   its allowlist with what keeps each from the kit; the list only shrinks.

## 3. Parts

u, v in metres in the current frame; `f` is the face (`kit_face`). "Trim" is the pale stone or
plaster of sills, heads and frames; "glass" the pane. Triangles are per part, for the budget in
the spec.

### Walls and their horizontals

| Part | What it builds | Triangles |
| --- | --- | --- |
| `kit_wall(u0, u1, y0, y1, col)` | the wall slab of a front, 0.4 m thick, its front on the face | 10 |
| `kit_bands(u0, u1, y0, y1, step, col)` | rustication: a 3 cm groove line every `step` m between y0 and y1 | 10 each |
| `kit_ledge(u0, u1, y, h, col, proud := 0.08)` | a string course or sill band: a box `proud` out of the face, h tall, its foot at y | 10 |
| `kit_cornice(u0, u1, y, col, h := 0.5, proud := 1.0)` | the main cornice: a frieze band 0.14 m proud under y, the slab `proud` out and h tall on it, running 0.5 m past each end | 20 |
| `kit_ledge_ring(ring, y, h, col, proud := 0.08)` / `kit_cornice_ring(ring, y, col, h, proud)` | the same round a whole plan ring (free-standing blocks) | by edges |
| `kit_attic(u0, u1, y, col, h := 1.0, kind := Attic.BALUSTRADE)` | what stands on the cornice: `WALL` a plain parapet with a coping; `BALUSTRADE` plinth, shaded baluster field, rail, a pier every 3 m or so | 30 + 10 a pier |

### Verticals

| Part | What it builds | Triangles |
| --- | --- | --- |
| `kit_pilaster(u, y0, y1, col, w := 0.6, proud := 0.12)` | a flat pilaster on the face: shaft, a base and a capital block each a little wider and prouder | 30 |
| `kit_column(u, v, y0, y1, col, r := 0.4, order := Order.TUSCAN)` | a free column: `TUSCAN` square plinth, 8-sided shaft, square capital (`_column`); `CORINTHIAN` 6-sided shaft with a flared capital | 34 to 60 |
| `kit_colonnade(u0, u1, n, v, y0, y1, col, r, order)` | n columns evenly from u0 to u1; returns their u | n columns |

### Openings

| Part | What it builds | Triangles |
| --- | --- | --- |
| `kit_window(u, y, h, style, trim, glass := PAL_GLASS_DARK, hw := 0.7)` | one window, sill at y, pane h tall and 2·hw wide. Styles below. The pane is `M_PANE`: lit whole, by chance, at night | 10 to 60 |
| `kit_window_grid(u0, u1, bays, sills, h, style, trim, glass, hw, skip := [])` | a window in every bay (bay centres evenly between u0 and u1) on every sill height in `sills`; `h` a float or one per sill; `skip` holds `Vector2i(bay, floor)` to leave out. Returns the bay centres | bays × floors windows |
| `kit_panes(cols, rows, w, h, glass, proud := 0.05)` | flat lit panes with no surround, one quad each, for modern blocks with hundreds of windows (`cols` u centres, `rows` sill heights) | 2 each |
| `kit_shop_bay(u, y0, y1, hw, trim, glass)` | a ground-floor opening: dark glass from y0 to y1 and a lintel band over it | 20 |
| `kit_door(u, y, h, hw, trim, leaf, arched := false)` | a door leaf in a surround, a round head when `arched` | 20 to 30 |

Window styles (`Win`):

| Style | Surround | From |
| --- | --- | --- |
| `PLAIN` | none: the pane alone, 5 cm proud | |
| `SILL` | a sill | |
| `SILL_HEAD` | a sill and a flat head | Szpitalna 5, Kamienica Wedla |
| `FRAMED` | sill, head and two jambs | Kamienica pod Gigantami |
| `HOODED` | sill, and a deeper, wider head on the frame | pod Gigantami, first floor |
| `PEDIMENT` | sill, head and a small stepped pediment over it | Szpitalna 5, first floor |
| `ARCHED` | sill, head, and a stepped round head of glass and trim over the pane | Wedel, top storey |

Fixed proportions (all from the face f; hw the pane's half width; v ranges are out of the face):
pane box from f − 0.01 to f + 0.05. Sill: half width hw + 0.28, v from f − 0.09 to f + 0.21,
from y − 0.20 to y − 0.06. Head: half width hw + 0.20, v from f − 0.05 to f + 0.18, from
y + h + 0.05 to y + h + 0.22. Jambs: 0.10 square at hw + 0.08, centred on f + 0.02. Hood: half
width hw + 0.28, 0.18 half deep, to y + h + 0.30. Pediment: two more blocks on the head, half
widths hw + 0.12 and hw − 0.23, 0.12 and 0.16 tall. Arched: a pane hw·0.67 half wide and 0.30
tall on the pane, a trim block hw·0.86 half wide from y + h + 0.24 to y + h + 0.50. The code
(`kit_window`) is the reference; the boxes are drawn pane, jambs, sill, head, extras.

### Balconies

`kit_balcony(u, y, hw, kind, rail, slab, depth := 1.0)`: floor level with the sill at y.

| Kind | What |
| --- | --- |
| `IRON` | slab 0.20 thick under y − 0.06; a top rail at y + 0.85..0.92 on the front edge and both sides; a bar every 0.42 m or closer |
| `STONE` | slab 0.28 thick; a solid balustrade 1.0 high, 0.14 thick, on the front and both sides; two brackets under it |
| `PARAPET` | slab; a solid front wall 0.86 high with a coping, no sides (between piers) |

### Entrances and crowns

| Part | What it builds | Triangles |
| --- | --- | --- |
| `kit_pediment(u, hw, y, h, col, roof, depth := 0.45, relief := none)` | a triangular gable standing `depth` out of the face over u ± hw, its two roof slopes running back into the wall; a darker relief triangle inside when `relief` is opaque | 6 to 7 |
| `kit_portico(u, hw, y0, y1, n, col, roof, depth := 3.0, steps := 3, order := Order.TUSCAN)` | steps, n columns `depth` out, an entablature on them back to the wall, a pediment a quarter of the width tall | about 60 a column + 60 |
| `kit_lantern(u, v, y, h, r, wall, roof, glass := PAL_GLASS_DARK, sides := 8)` | a roof lantern: a `sides`-sided drum with a pane in each face, a ledge, a pointed cap and a finial | about 12 a side |

## 4. The palette

Thirty-three names. Each value is the most typical of the colours `landmarks.gd` already used for
that role (clustered in Lab over its 1,278 named colours, 2026-11-13), so taking a palette name
moves an existing model least.

| Name | Hex | For |
| --- | --- | --- |
| `PAL_WHITE_STONE` | `#ebe8df` | white plaster, pale stone, columns, trim |
| `PAL_CREAM_STONE` | `#e2d8c4` | cream plaster and stone |
| `PAL_SANDSTONE` | `#d9c3a0` | sandstone, warm plaster |
| `PAL_OCHRE` | `#d8b67a` | ochre plaster, yellow brick |
| `PAL_GREY_STONE` | `#a8a49c` | grey stone and render |
| `PAL_PALE_CONCRETE` | `#d4d0c6` | copings, pale concrete, paving stone |
| `PAL_WARM_GRANITE` | `#b9b2a2` | plinths and bases |
| `PAL_GREY_GRANITE` | `#8e8a82` | granite, grey bases |
| `PAL_DARK_GRANITE` | `#4a4744` | dark plinths, polished stone |
| `PAL_RED_BRICK` | `#a1503a` | red brick |
| `PAL_DARK_BRICK` | `#8a3a28` | dark and burnt brick |
| `PAL_BROWN_RENDER` | `#7a4a3d` | brown render and piers |
| `PAL_ROOF_GREY` | `#6d7470` | zinc and sheet roofs |
| `PAL_ROOF_PALE` | `#9a9c9c` | lead, pale sheet, flat roofs |
| `PAL_ROOF_DARK` | `#4d5256` | slate, tar, dark zinc |
| `PAL_ROOF_TILE` | `#a8503c` | red tile |
| `PAL_ROOF_GRAVEL` | `#b9b7b1` | gravel and pale membrane |
| `PAL_PATINA_COPPER` | `#6f9a8a` | green copper |
| `PAL_NEW_COPPER` | `#b26a3a` | brown copper |
| `PAL_IRON` | `#2a2c2f` | wrought iron, dark frames |
| `PAL_DARK_STEEL` | `#4a4e52` | steel, dark metal |
| `PAL_ALUMINIUM` | `#c3c7ca` | aluminium, pale rails and frames |
| `PAL_BRONZE` | `#4f4a40` | bronze statues, doors |
| `PAL_GOLD` | `#c9a24c` | gilding |
| `PAL_GLASS_DARK` | `#323a40` | windows of old houses |
| `PAL_GLASS_NAVY` | `#3e4d5a` | office glass, dark |
| `PAL_GLASS_STEEL` | `#5d717c` | office glass, mid |
| `PAL_GLASS_PALE` | `#8fa9b6` | pale curtain wall |
| `PAL_GLASS_BLUE` | `#4a74a6` | blue glass |
| `PAL_DARK_DOOR` | `#34393d` | painted doors and gates |
| `PAL_OAK` | `#5e432f` | wooden doors |
| `PAL_TIMBER` | `#a37a52` | decks, planks, pale wood |
| `PAL_SIGNAL_RED` | `#c8322e` | red paint |

The first kit PR adds the names and uses them in the kit's own defaults. The landmarks that
exist keep their colours (their look does not change in that PR); a landmark takes palette names
the next time it is reworked, with its look check.

## 5. Proving a change did nothing

`game/tools/site_dump.gd` builds every site alone, on flat ground from the committed map only,
and writes every vertex (position, normal, colour, uv, material code) to a folder.
`tools/site_parity.py BEFORE AFTER` compares two folders site by site:

- `same`: bit for bit. A move of code (the kit's core, the split by site) must give this for all
  1,212 sites.
- `near`: the same triangles in the same order, every number within `--eps`.
- `--unordered`: each triangle of one folder has a twin in the other (same colour, normal and
  material, corners within `--eps`), in any order. For a private helper replaced by a kit part:
  the part may draw its boxes in another order and move a sill a few centimetres (under the
  phone's pixel at any zoom), but may not add, drop or recolour anything.

```
mkdir -p /tmp/before /tmp/after
godot --headless --path game --script res://tools/site_dump.gd -- --out=/tmp/before
# ... change ...
godot --headless --path game --script res://tools/site_dump.gd -- --out=/tmp/after
python3 -I tools/site_parity.py /tmp/before /tmp/after
```

## 6. The sampler

`kit_sampler()` builds one street front and one free-standing pavilion that use every part and
style once. `check_mesh_quality` examines it like a site (z-fighting, floating parts, normals,
a triangle budget), so a kit part that flickers or hangs in the air fails CI. To look at it:

```
godot --path game -- --nosave --solo=kit_sampler --solo-look=lit --at=... --shots=30 --out=DIR
```

## 7. How the kit grows

The steps are in `docs/architecture/extending.md` ("Extending the facade kit") and the decision
in `docs/architecture/decisions.md`. In short: a missing part or style is added to the kit in the
landmark's own PR, with fixed proportions, a place in the sampler and a row in this file, and the
parity tools show that no other site moved. Changing an existing proportion or a palette value
moves every landmark that uses it, so it is a decision with before and after shots and F's look.
The shader gets no new look.

## 8. What comes next

- Landmarks move to the kit one by one, each when it is next reworked; the allowlist in
  `tools/check_facade_kit.py` is the worklist.
- New styles (a loggia, a bay window, a mansard with dormers, a shop front with an awning) join
  when a second landmark needs them.
- Item 5, the split of `landmarks.gd` by site, uses the same proof tools.
