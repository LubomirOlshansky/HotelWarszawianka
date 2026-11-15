- The city's trees are no longer one shape: limes, maples, chestnuts, planes, robinias, oaks, birches, poplars, willows, spruces and pines each have their own silhouette, and the city shows a golden late autumn: most crowns gold or straw, about one in five bare and warm brown, the oaks russet and the conifers green.

## Backlog
- fixed: all trees looked the same (F, 2026-11-15): every crown was one 20-face icosahedron with a random autumn colour; now an icosphere bent into the kind's silhouette in the shader, with six limbs inside, three leaf states (full, thin straw-gold, bare warm brown; solid, a stylised golden late autumn) and a colour per kind, no new draw call
- found: the GUGiK scan's crown radius follows the tree's height (no tree narrower than a quarter of its height), so the scan cannot tell a poplar from a lime; kinds are guessed by place until the map data names them (step T1: OSM genus, rows, parks, willows by the water)
- found: no tree has a real kind yet: OpenStreetMap names one for about 4 % (623 of 15,555 nearby) and Warsaw's tree inventory is out of the cloud's reach
- found: the season stands at mid-November (`tree_season`, a shader global, so the prebuilt city follows it too); the season module (step S1) will set it from the game's date
- found: cost on Pole Mokotowskie (cloud probe, High, by day with shadows): draw calls 131 to 133, triangles 0.70 M to 1.09 M (main pass 0.48 M, shadow pass 0.39 M); the Mac frame time is owed at the next build gate (docs/WORKFLOW.md), the phone's in PHONE-CHECK 14u; Low drops the branches (`tiers.gd` tree_limbs); checked on both city paths, the prebuilt one re-baked
- found: the far sectors' tree blobs still take their November colours at the bake (step T4 recolours them at load)

## Roadmap
- adds: "Trees and seasons (docs/design/trees-and-seasons.md): T-fix kinds, silhouettes and leaf states (this), T1 kinds in the map data, S1 the season module and setting, T4 trees by season, then the ground, snow and winter, Christmas, the rink, storms and dated nights"
