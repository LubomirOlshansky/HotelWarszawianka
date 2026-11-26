- Ordinary houses look lived in: post-war blocks have lit stairwells and the odd flickering TV at night, and by day there are air conditioners by the windows, flower boxes on old sills, laundry and satellite dishes on the balconies.

## Backlog
- fixed: the typed houses (house types 2a) were tidy to the point of empty, and their night windows didn't show stairwells or TVs
- found: owed before any store or beta build, from the audits of house types 2a and PR 3 (#1092, #1098):
  - a phone bench before and after on the iPhone and a weaker Android: the const facade rows are read per pixel, and the ~39k roof-furniture triangles also go into the shadow pass
  - the runtime-path city build time before and after on the Mac (roof furniture placement loops over the baked box tops)
  - the re-bake chain on main plus a `--prebuilt` look
- found: the clutter is painted in the facade (no geometry), so it is flat up close; Low quality turns it off (`tiers.gd` house_clutter)

## Roadmap
- ticks: "House types: PR 2b night life and clutter" (building.gdshader only, budget 379 of 505, no draw call or triangle added)
