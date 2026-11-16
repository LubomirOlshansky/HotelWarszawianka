## Backlog
- fixed: TD-13 step 3: the active target's pin on the minimap and the full map is one mark in the map marker registry (main.gd `_put_target`); `hud.set_minimap_target` and the full map's copy of the target are gone, and the full map's pin is live while it is open
- fixed: a registry put that changes nothing is not a write, and a put drops only its own layer's view, so the target put every frame rebuilds nothing
- found: the edge arrow and its metres stay `hud.set_target` (a point on the screen, the camera's business); TD-13 step 4, road routes for every target, is left

## Roadmap
- ticked: "Architecture: marker registry (TD-13)", step 3 of 4
