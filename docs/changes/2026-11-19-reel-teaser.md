- A new synthwave Around Warsaw logo and a five-second teaser for Instagram.

## Backlog
- found: the full trailer still waits on its Mac re-render at 60 fps (draft PRs #640/#655)

## Roadmap
- added: "Social teaser (Reels 5 s) and the synthwave logo"

## Umbrellas in the rain (teaser 2)

- seen: in the rain every pedestrian and every crowd figure walks under an umbrella in the colour of their shirt.
- fixed: F's teaser 2 (Warsaw at 3 a.m. in the rain) asked for "people going with umbrellas".
  `Models.umbrella_mesh` is an eight-panel canopy on a shaft; `Models.umbrella_twin` draws it from
  the people's own instance buffer (pedestrians.gd, every crowds.gd cell and its walkers), shown only
  while `weather.amount > 0.2`. Owner: the people's own scripts (pedestrians, crowds), no new system.
- cost: +1 draw call per shown people MultiMesh while it rains (the walkers, plus each visible crowd
  cell), none when dry. Bench in the rain on the Mac before merge.
