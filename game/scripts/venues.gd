extends RefCounted
## The venue owner (docs/design/drift-narodowy.md 0b.4 D1a, critique-drift.md section 4: "only the
## stadium joins"): the scenes off the map that take the player out of the city (a room far away from
## it, with its own camera and sound). Each joins with `add(name, inside, view, sound_mode)`; main.gd
## asks the owner, not each scene, in `_update_camera` (`view`, its first line), `_sound_mode`,
## `_toggle_vehicle` and `_free_block` (`inside_name`).
##
## Only the drift stadium (drift_stadium.gd) has joined. The club, the lounge, the padel hall and THE
## TAPCZAN are still OR'd by hand in main.gd; each moves here when its own thread next touches it
## (tapczan first, it has the shape): docs/architecture/tech-debt.md TD-39.

## [name, inside: Callable() -> bool, view: Callable(cam, pitch, dt) -> bool, sound_mode].
var _venues: Array = []


## A venue joins: `inside_test` says the player is in it now; `place_view` places the camera while
## inside (true: placed); `mode` is sfx.gd's `mode` there ("foot" in a room; "car" for a scene that is
## driven).
func add(venue: String, inside_test: Callable, place_view: Callable, mode := "foot") -> void:
	_venues.append([venue, inside_test, place_view, mode])


## A scene that has `inside()` and `view(cam, pitch, dt)` joins under `venue` and is handed back
## (null stays null and joins nothing), so main.gd's build joins it in one line.
func join(venue: String, scene: Node, mode := "foot") -> Node:
	if scene != null:
		add(venue, Callable(scene, "inside"), Callable(scene, "view"), mode)
	return scene


## The venue the player is in ("" for none).
func inside_name() -> String:
	for v: Array in _venues:
		if (v[1] as Callable).call():
			return str(v[0])
	return ""


## The camera, placed by the venue the player is in (false: nobody placed it).
func view(cam: Camera3D, pitch: float, dt: float) -> bool:
	for v: Array in _venues:
		if (v[1] as Callable).call():
			return bool((v[2] as Callable).call(cam, pitch, dt))
	return false


## sfx.gd's mode inside a venue ("" outside them all).
func sound_mode() -> String:
	for v: Array in _venues:
		if (v[1] as Callable).call():
			return str(v[3])
	return ""
