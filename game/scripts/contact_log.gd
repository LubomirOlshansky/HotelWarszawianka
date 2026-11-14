extends RefCounted
## The city objects plan, step 3 (docs/design/drivable-city-build.md, item 1): the contact log.
## What the car touched, how hard, and on which street, one line per contact episode, so a stop
## has a name ("a fence on Hoża took 80 % of the speed") and a street a number (contacts per km).
##
## Pure: no node, no scene. Its owner calls `observe(car, dt)` once a physics frame, BEFORE the
## car's own step (the SceneTree's physics_frame signal in main.gd, a check's `_physics_process`):
## it reads the slide collisions and the velocity the car's last step left, so the game run and the
## check (game/tools/check_lane_drive.gd) write the same lines from the same frames. It changes
## nothing on the car. main.gd makes one only for `--contacts=FILE` (release builds read no flags,
## release.gd); tools/drive_report.py reads the files.
##
## An episode runs from the first frame touching anything until FREE s with no contact (and at
## least WATCH s, unless the next contact comes first). Its class is the `solid` meta of the body
## pressed hardest on the first frame (solidity.gd's classes, `game/data/object_palette.json`), or
## `traffic`, `tram`, `train` for the moving bodies of traffic.gd, trams.gd, trains.gd; anything
## else is `unknown` and the line names the body (the plan wants none). Fields (tab separated):
##   contact  t (s since the log began)  x z (m)  class  in (m/s going in)  low (the lowest speed
##   within WATCH s)  angle (deg, 0 grazing, 90 head-on: the velocity against the summed normal)
##   dur (s in contact)  street (the owner's `street_at`)  flags: dead_stop (lost DEAD_SHARE of the
##   speed and at least DEAD_LOST m/s within DEAD_TIME s), unstick (car.gd turned it out of a pin),
##   water (the car rolled into the water), tow (the owner's `mark("tow")`: the game's tows, the
##   check's own)  also (other classes touched)
## and one `drive` line a street leg (street, m, s, fast: the seconds above FAST of its limit), for
## the km and the share of time at speed. `tag` (the check's route name) joins every line as route=.

## An episode ends after this long with no contact (s); its lowest speed is watched this long.
const FREE := 0.25
const WATCH := 1.0
## A dead stop: at least DEAD_SHARE of the speed and DEAD_LOST m/s gone within DEAD_TIME s.
const DEAD_SHARE := 0.6
const DEAD_LOST := 5.0
const DEAD_TIME := 0.3
## The street under the car is asked this often (s) for the drive legs.
const STREET_EVERY := 0.25
## "At speed": above this share of the street's limit.
const FAST := 0.8
## A flag given after an episode closed still joins it this long after (s): a tow comes later.
const LATE := 15.0

## (x: float, z: float) -> Array [street name, limit in m/s]: the owner's street finder.
var street_at: Callable = func(_x: float, _z: float) -> Array: return ["", 0.0]
## Joins every line as route=TAG when not empty (the check's route name).
var tag := ""
## Every line written, in order.
var lines := PackedStringArray()
## Print each line as it is written (the check's stdout).
var echo := false
## The episodes so far by class (for a summary), and the unknown bodies' paths.
var counts := {}
var unknown: Array[String] = []

var _file: FileAccess
var _t := 0.0
var _prev_vel := Vector3.ZERO
var _seen := false
var _ep := {}
var _last := {}
var _unsticks := -1
var _leg := {}
var _street_wait := 0.0
var _pos := Vector3.ZERO
var _wet := false


## Writes the lines to `path` as well (each flushed at once, so a killed run keeps them).
func open(path: String) -> bool:
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_error("contact_log: cannot write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	return true


## Once a physics frame, before the car's step. `car` is car.gd's CharacterBody3D.
func observe(car: CharacterBody3D, dt: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	_t += dt
	var vel := Vector3(car.vel.x, 0.0, car.vel.z)
	var speed := vel.length()
	var p := car.global_position
	_pos = p
	if not _seen:
		_seen = true
		_prev_vel = vel
		_unsticks = int(car.unsticks)
		_wet = car.in_water
	_drive(p, speed, dt)
	var hits := car.get_slide_collision_count()
	if hits > 0:
		var into := _prev_vel
		var n := Vector3.ZERO
		var best := INF
		var main_cls := ""
		var body := ""
		var classes := {}
		for k in hits:
			var c := car.get_slide_collision(k)
			var nk := c.get_normal()
			nk.y = 0.0
			n += nk
			var who: Object = c.get_collider()
			var cls := class_of(who)
			classes[cls] = true
			var press := into.dot(nk.normalized()) if nk.length() > 0.01 else 0.0
			if press < best:
				best = press
				main_cls = cls
				body = str((who as Node).get_path()) if who is Node and cls == "unknown" else ""
		if _ep.is_empty() or (_t - float(_ep["seen"]) > FREE):
			_close()
			var angle := 0.0
			if n.length() > 0.01 and into.length() > 0.1:
				angle = rad_to_deg(asin(clampf(-into.normalized().dot(n.normalized()), 0.0, 1.0)))
			var st: Array = street_at.call(p.x, p.z)
			_ep = {"t": _t, "x": p.x, "z": p.z, "cls": main_cls, "in": into.length(), "low": speed,
					"low3": speed, "angle": angle, "street": str(st[0]), "flags": {}, "also": {},
					"seen": _t, "touch": 0.0, "body": body}
		else:
			_ep["seen"] = _t
		_ep["touch"] = float(_ep["touch"]) + dt
		for cls: String in classes:
			if cls != _ep["cls"]:
				_ep["also"][cls] = true
	if not _ep.is_empty():
		var age := _t - float(_ep["t"])
		if age <= WATCH:
			_ep["low"] = minf(float(_ep["low"]), speed)
		if age <= DEAD_TIME:
			_ep["low3"] = minf(float(_ep["low3"]), speed)
		if _t - float(_ep["seen"]) > FREE and age >= WATCH:
			_close()
	if int(car.unsticks) != _unsticks:
		_unsticks = int(car.unsticks)
		mark("unstick")
	if car.in_water != _wet:
		_wet = car.in_water
		if _wet:
			mark("water")
	_prev_vel = vel


## A flag for the open episode, else the last one if it ended under LATE s ago, else a line of
## its own (`event`, no class: nothing was touched).
func mark(flag: String) -> void:
	if not _ep.is_empty():
		_ep["flags"][flag] = true
	elif not _last.is_empty() and _t - float(_last["seen"]) < LATE:
		# The last episode is written already: a line of its own that names it.
		_write("event\tt=%.2f\tflag=%s\tof=%.2f\tclass=%s\tstreet=%s" % [_t, flag, float(_last["t"]), _last["cls"], _last["street"]])
	else:
		var st: Array = street_at.call(_pos.x, _pos.z)
		_write("event\tt=%.2f\tflag=%s\tx=%.1f\tz=%.1f\tstreet=%s" % [_t, flag, _pos.x, _pos.z, st[0]])


## The open episode and the street leg written out (the end of a route, of a run).
func flush() -> void:
	_close()
	_end_leg()


## A new car or a route's start: the episode and the leg end; the clock goes on.
func reset() -> void:
	flush()
	_seen = false
	_last = {}


## The file closed (the lines stay in `lines`).
func close() -> void:
	flush()
	if _file != null:
		_file.close()
		_file = null


## A collider's class: its "solid" meta (solidity.gd), the moving traffic's, or "unknown".
static func class_of(who: Object) -> String:
	if who == null or not is_instance_valid(who):
		return "unknown"
	if who.has_meta(&"solid"):
		return str(who.get_meta(&"solid"))
	if who is AnimatableBody3D:
		var n: Node = (who as Node).get_parent()
		for _i in 3:
			if n == null:
				break
			var s: Script = n.get_script() as Script
			var path := s.resource_path if s != null else ""
			if path.ends_with("/traffic.gd"):
				return "traffic"
			if path.ends_with("/trams.gd"):
				return "tram"
			if path.ends_with("/trains.gd"):
				return "train"
			n = n.get_parent()
	return "unknown"


## The street names a lane graph's edges go by in the log: the edge's name, or "(unnamed KIND)" with
## its OpenStreetMap kind (a ramp, a link road), as tools/road_objects.py names them. `graph` is the
## map data's "graph" (its "edges" in the lane graph's order), read before the index is packed.
static func street_names(graph: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for e: Dictionary in graph.get("edges", []):
		var name := str(e.get("name", ""))
		out.append(name if name != "" else "(unnamed %s)" % str(e.get("k", "road")))
	return out


## One line split into its fields ({"kind": "contact", "t": "12.35", ...}), for the checks.
static func parse(line: String) -> Dictionary:
	var parts := line.split("\t")
	var out := {"kind": parts[0]}
	for i in range(1, parts.size()):
		var kv := parts[i].split("=", true, 1)
		if kv.size() == 2:
			out[kv[0]] = kv[1]
	return out


func _close() -> void:
	if _ep.is_empty():
		return
	var flags: Array = (_ep["flags"] as Dictionary).keys()
	var v_in := float(_ep["in"])
	if v_in - float(_ep["low3"]) >= DEAD_LOST and float(_ep["low3"]) <= v_in * (1.0 - DEAD_SHARE):
		flags.push_front("dead_stop")
	flags.sort()
	var also: Array = (_ep["also"] as Dictionary).keys()
	also.sort()
	var cls := str(_ep["cls"])
	counts[cls] = int(counts.get(cls, 0)) + 1
	var line := "contact\tt=%.2f\tx=%.1f\tz=%.1f\tclass=%s\tin=%.1f\tlow=%.1f\tangle=%.0f\tdur=%.2f\tstreet=%s\tflags=%s" % [
			float(_ep["t"]), float(_ep["x"]), float(_ep["z"]), cls, v_in, float(_ep["low"]), float(_ep["angle"]),
			float(_ep["touch"]), _ep["street"], ",".join(flags)]
	if not also.is_empty():
		line += "\talso=" + ",".join(also)
	if cls == "unknown":
		line += "\tbody=" + str(_ep["body"])
		unknown.append(str(_ep["body"]))
	_write(line)
	_last = _ep
	_ep = {}


## The drive legs: metres and seconds per street, asked every STREET_EVERY s.
func _drive(p: Vector3, speed: float, dt: float) -> void:
	_street_wait -= dt
	if _leg.is_empty() or _street_wait <= 0.0:
		_street_wait = STREET_EVERY
		var st: Array = street_at.call(p.x, p.z)
		if _leg.is_empty() or str(st[0]) != str(_leg["street"]):
			_end_leg()
			_leg = {"street": str(st[0]), "limit": float(st[1]), "m": 0.0, "s": 0.0, "fast": 0.0, "at": p}
		else:
			_leg["limit"] = float(st[1])
	var last: Vector3 = _leg["at"]
	_leg["m"] = float(_leg["m"]) + Vector2(p.x - last.x, p.z - last.z).length()
	_leg["at"] = p
	_leg["s"] = float(_leg["s"]) + dt
	if float(_leg["limit"]) > 0.0 and speed > FAST * float(_leg["limit"]):
		_leg["fast"] = float(_leg["fast"]) + dt


func _end_leg() -> void:
	if _leg.is_empty():
		return
	if float(_leg["s"]) > 0.0:
		_write("drive\tt=%.2f\tstreet=%s\tm=%.1f\ts=%.2f\tfast=%.2f\tlimit=%.1f" % [_t, _leg["street"], float(_leg["m"]),
				float(_leg["s"]), float(_leg["fast"]), float(_leg["limit"])])
	_leg = {}


func _write(line: String) -> void:
	if tag != "":
		line += "\troute=" + tag
	lines.append(line)
	if echo:
		print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()
