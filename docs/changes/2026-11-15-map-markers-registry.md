## Backlog
- fixed: TD-13 step 1, the map marker registry (`map_markers.gd`): the street jobs' places, the round-up's pins, the garage, the "?" marks and the final's start are declared once and the minimap and the full map read the same list; the job places and the round-up no longer write one shared list (the last writer wiped the other's)
- found: the final's start marker (`set_minimap_final`) had not been drawn since the main line's star took its place; it is kept in the registry, not drawn
- found: TD-13 steps 2 to 4 left: the questline badges, the main line's star and quest focus; the active target and the arrow; road routes for every target

## Roadmap
- ticked: "Architecture: marker registry (TD-13)", step 1 of 4
