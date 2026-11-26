extends Node
## The road route to the active target (TD-13 step 4, docs/architecture/map-markers.md): every
## target the maps pin (the marker registry's TARGET mark, main.gd `_put_target`) gets the dotted
## way there by road on the minimap and the full map, not only the ones whose activity draws its
## own (jobs.gd's deliveries, the street races, Łuber; those keep theirs and this one steps
## aside while one is on). Before it, a rescue, a tour stop, a quest pin or the guide's next place
## had only the straight edge arrow, through blocks and against one-way streets.
##
## It only reads the registry and the HUD's car (`minimap_car`, `minimap_heading`, `flying`) and
## writes the HUD's route slot under the owner "target" (hud.gd `set_minimap_route`), so it needs
## no wiring but its node (main.gd `_build_side_jobs`). In the air there is no road route (the
## helicopter flies straight). The search (LaneGraph.distances_to, ~6-11 ms on the cloud CPU) runs
## once per goal; a goal that moves (a rival's pin) is searched again only after it has moved
## REGOAL_M and REGOAL_S have passed, and between searches the line is walked again from the car
## every RouteLine.REFRESH s (no search), so it follows a wrong turn.

const RouteLine := preload("res://scripts/route_line.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")

## The owner name on the HUD's route slot.
const OWNER := "target"
## A goal further than this from every road (m) gets no route (the straight arrow and pin only).
const SNAP_M := 60.0
## A goal that moved more than this (m) since its search is searched again...
const REGOAL_M := 40.0
## ...but not more often than this (s).
const REGOAL_S := 3.0

var hud: Node
var graph: LaneGraph
var _line: RouteLine
## The goal of the last search (INF: none) and the time since it.
var _goal := Vector2.INF
var _since := 0.0
## How many searches so far (a check reads it).
var searches := 0


func _init(the_hud: Node = null, lane_graph: LaneGraph = null) -> void:
	hud = the_hud
	graph = lane_graph
	name = "target_route"
	if graph != null:
		_line = RouteLine.new(graph)


func _process(dt: float) -> void:
	tick(dt)


## One step: the route to the registry's target from the HUD's car, or none.
func tick(dt: float) -> void:
	if hud == null or _line == null:
		return
	var markers: MapMarkers = hud.markers
	var at := markers.target()
	var other: bool = not (hud.minimap_route() as PackedVector2Array).is_empty() and hud.minimap_route_owner() != OWNER
	if at == Vector2.INF or bool(hud.flying) or other:
		_off()
		return
	_since += dt
	if _goal == Vector2.INF or (at.distance_to(_goal) > REGOAL_M and _since >= REGOAL_S) or at.distance_to(_goal) > 400.0:
		if not _search(at):
			_off()
			_goal = at  # no road near: don't search again until it moves
			return
	if _line.update(hud.minimap_car(), hud.minimap_heading(), dt):
		hud.set_minimap_route(_line.points, markers.target_colour(), OWNER)


## The search to the goal's nearest lane point; false when no road is near it.
func _search(at: Vector2) -> bool:
	_goal = at
	_since = 0.0
	var hit := graph.snap(at, SNAP_M, Vector2.ZERO, true)
	if hit.is_empty():
		return false
	searches += 1
	var t0 := Time.get_ticks_usec()
	_line.to_lane(int(hit[0]), float(hit[2]), at)
	print("target route: search %d to %d,%d in %.1f ms" % [searches, roundi(at.x), roundi(at.y), (Time.get_ticks_usec() - t0) / 1000.0])
	return true


func _off() -> void:
	if _line != null and _line.active():
		_line.clear()
	_goal = Vector2.INF
	if hud != null:
		hud.clear_minimap_route(OWNER)
