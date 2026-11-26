- Each kind of Warsaw house now has its own front: tall windows with surrounds and a heavy cornice on the kamienice, a two-storey shop floor at MDM, small plain windows on Muranów, panel joints and stacks of loggias on the slabs, ribbon glass on the PRL offices and big windows over loggias on the new builds.

## Backlog
- fixed: Muranów's 1950s blocks, the estates and the new builds all drawn with the same three window patterns
- fixed: far-away upper-floor windows fade to their average colour instead of breaking into single pixels (the ground floor does not fade yet)
- fixed: the building shader sat at 503 of the Adreno budget of 505 (check_shader_budget on main); it is now at 380
- found: the const HOUSE_* tables are indexed per pixel; their cost on Adreno 6xx and Mali is only measurable on a phone (bench before and after owed)

## Roadmap
- adds: "House types: PR 2b night windows and facade clutter, 3 roofs by type, 4 levels in the bake"
