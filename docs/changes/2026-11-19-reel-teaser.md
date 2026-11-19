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

## Ride-hail cars and a fuller rainy evening (teaser 2 final)

- seen: Podwózka, the app taxi, now drives an electric crossover and the city taxi a hybrid liftback; a few more of them on the main streets; Pasaż Wiecha has people out in the evening, and the rain thins the streets less now that everyone has an umbrella.
- fixed: F (20:19 UTC) asked for Uber/Bolt-like cars (a Tesla Model Y and a Toyota Prius, as
  parodies, no marques) and more people on the pasaż. `Models.spec("crossover")` and
  `spec("liftback")` replace the hatch and saloon in the taxi family (same parts, so the morph and the
  draw calls are unchanged); traffic.gd's taxi share 10 % → 14 %. crowds.gd `WIECHA_NIGHT`: three
  `pub`-curve sites by Zodiak, on the square and in the middle of the pasaż; `RAIN_OUT` 0.6 (was 0.35
  for the street, 0.3 for the pubs). Owner: crowds.gd's sites, models.gd's taxi family.
- cost: no new draw call; up to 36 more crowd figures near Pasaż Wiecha in the evening.

## Trams and a bus on cue for videos

- seen: nothing in a normal game; video shots can now have a tram and a bus pass a chosen spot.
- fixed: F (21:07 UTC): "run the tram and the bus on one video". `--promo-at=X,Z[,T]` (main.gd
  `_promo_traffic`, dev_flags.gd) uses trams.gd `place_near` (as the first scene does) and
  traffic.gd `add_bus`. Owner: the trams' and traffic's own placement calls, no new system.
