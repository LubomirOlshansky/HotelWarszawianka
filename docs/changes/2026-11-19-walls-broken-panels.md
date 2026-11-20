- A smashed fence throws bits of what it is made of (leaves from a green fence, light sheet from a hoarding), and in the panel-fence test build a fence you drive through now falls: a railing panel lies on the ground away from the car, a wire net loses its mesh between the posts and a hedge is cut to a low stump, and they stay so until the city repairs them out of sight.

## Backlog
- fixed: W6 of the walls look (docs/design/walls-true-to-life.md 7): the broken panels shown on the `panels` look (`panel_states.gd`, `panel.gdshader` states), still broken after a sector leaves and comes back, stood up by `repair_near` and rule B; the debris colour and the smash sound picked by the looks row's `debris` (the palette's `debris` table)
- found: under every look, 484 `green_fence` lines now throw leaves and sound like a hedge, and 4 `hoarding` lines throw light sheet and sound like metal (their rows' `debris`; before W6 metal and wood)
- found: on a RenderingDevice a buffer write made inside `buffer_get_data_async`'s answer is accepted and lost (Godot 4.7.2, Mobile): `panel_states.gd` defers its writes

## Roadmap
- ticked: "Left: walls, fences and rails that look real": the W6 part of "Fences and hedges as see-through instanced panels that fall when broken" (the six panel rows fall, tear or are cut to a stub behind `barrier_look` `panels`; W5 the other light rows; the line stays open)
