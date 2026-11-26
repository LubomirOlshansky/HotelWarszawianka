# Mansjonaria (Plac Zamkowy at Świętojańska): log

Spec: [specs/mansjonaria.md](specs/mansjonaria.md). Site key `mansjonaria` (`old_town.gd`
`_find_mansjonaria`, `_build_mansjonaria`, `_mansjonaria_dormer`).

## 2026-11-26: street block to model (cloud thread, F's "fix this building and roof")

- Before: street block 101331240's fronts on LoD2's mass; LoD2 read the ground-floor buttresses
  as walls leaning out the whole height, the roof broken round them.
- References: F's photo of the oak (the house on the left), Google 3D Tiles (6 orbits and the top,
  local refs only).
- After: L2 model, 2458 triangles (budget 2700): the plan without buttresses to a 12.4 m eave,
  three sloped buttresses and the north corner one, a brick-arched door, kit windows on three
  fronts (hooded on the first floor), a cream cornice, a steep red hip roof, six wide zinc
  dormers (after the compare sheet: they were small plastered ones), two white chimneys.
  The block is skipped in `fronts.gd` (`MANSJONARIA_BLOCK`).
- Checks: `check_spec` OK; `check_mesh_quality` 0 defects; turntable and the compare sheet
  looked at; city shot from the square.
