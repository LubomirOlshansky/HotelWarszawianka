- Every target now shows its way by road on the minimap and the full map: a rescue, a tour stop, a quest picked on the map or the guide's next place, not only kebab orders and races.

## Backlog
- fixed: TD-13 step 4 (the last): `target_route.gd` keeps the road route to the registry's active target in the HUD's route slot whenever its activity draws none (one lane-graph search per goal, a moving goal again after 40 m and 3 s, none in the air); the full map's dotted line follows the route when it ends at the target
- found: the edge arrow still points straight at the goal; a road arrow is parked in QUESTIONS.md ("Should the edge arrow follow the road?")

## Roadmap
- ticked: "Architecture: marker registry (TD-13)", step 4 of 4 (done)
