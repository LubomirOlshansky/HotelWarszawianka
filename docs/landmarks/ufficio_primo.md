# Ufficio Primo (Wspólna 62): log

Spec: [specs/ufficio_primo.md](specs/ufficio_primo.md). Code: `_find_ufficio_primo`, `_build_ufficio_primo`,
`_up_face`, `_up_roof_lights`, `_up_dome` in `game/scripts/landmarks/srodmiescie.gd`.

- Built 2026-11-26 (object-modeler, Sonnet). 4016 triangles, budget 4200 (the spec's roof exception).
- The OSM block is unnamed: `tools/bake_sectors.py` SITE_AREAS got its box (without it the runtime sector
  path drew nothing; the headless mesh check does not see that).
- Facades: kit parts per face (kit_front, kit_window SILL, kit_panes, kit_door, kit_ledge); ledges, plinth and
  cornice are `kit_*_ring` so no two overlap at a corner. First-floor frames are solid trim boxes under panes
  standing 0.12 proud.
- Roof (build 1): dark membrane, pale parapet band, 36 roof lights, drum (16-sided) with 24 vents, three-frustum dome, 59 bubbles.

Fix rounds (2026-11-26, the lane session on Opus, from `tools/refs_compare.py`: 3D Tiles renders over the turntable):
- Round 1 (the sheet): dome bigger bubbles (2.1 m), paler; 12 roof lights a side nearly touching; cornice top grey. 4144 tris.
- Fable's workflow review scored it silhouette 4, roof 3, rhythm 3, colour 2, identity 3: the dome a pale pancake
  against a dark slate cap. Round 2: dome 6 m rise in five frustums, slate, a second staggered ring of 12 bubbles,
  roof lights 2.4 m wide with a tan frame round inset glass, 11 a side. 4328 tris, budget 4400.
- art-director (Opus, one sheet, photo first): **L2 PASS**: silhouette 4, roof 4, rhythm 3, colour 4, identity 4,
  ground 3. Its fixes applied: dome 7 m rise and #707785 (between the two judges' readings), grooves 0.15 m and
  darker, stone cooled to #d8d4c9, cornice slab 1.1 m. 4322 tris.
- City shot (2026-11-26): an older street-block model (blk_25911097, game/data/street_blocks) still stood in the
  outline and drew its own dome and roof lights over this one; the turntable builds the site alone and could not
  show it. `_find_blocks` skips it now (UP_BLOCK) and check_sites fails on any new landmark over a block.
- Phone-only: whether the grooves shimmer while driving, whether the guardians read as figures, the lit panes at night.

What still differs from the spec:
- Rustication grooves are flat quads through the core `_wall` (kit_bands' boxes would cost about 3,700 triangles).
- Roof lights 11 a side; the real roof also has lights set diagonally in the corner squares (not built); ducts not built.
- Bubbles are 6-sided low cones, drum and dome 16-sided to fit the budget.
- Door leaf stands on the plinth top (0.9 m), the plinth ring runs across the door.
- Statues are the `_kp_figure` coat-and-head figure, not a modelled bronze.
