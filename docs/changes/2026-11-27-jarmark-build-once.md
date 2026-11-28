- The city around the Christmas market loads faster: the market is no longer built again whole for every part of the map it touches.

## Backlog
- fixed: the Jarmark site took 20-23 s of sector s_-2_1's 30 s build (4 cores) and was rebuilt whole in every sector it reached. Two causes, both fixed with identical output: facade_kit's `_wall` compared every new wall with every earlier wall of the site (O(n²); now a 4 m grid of nearby walls), and each sector built every market part although it keeps only its own tiles (now a part that reaches none of them is skipped). Cloud timings (headless, 1 core): the market alone 31 s -> 6.0 s; its two sectors 31 + 31 s -> 2.8 + 4.9 s with every kept triangle the same; all landmark sites 117 s -> 89 s, byte-identical triangles
- found: the chalets still cost ~3 s of the market's 6 s (7,500 walls); kit instancing would cut that but changes how the market's mesh is merged, left for later if the sector build is still slow on the phone
- found: phone bench near the Palace (Plac Defilad) owed before the next store build

## Roadmap
- adds: "Performance: sector builds under budget near the Jarmark (bench by the Palace on iPhone and A56)"
