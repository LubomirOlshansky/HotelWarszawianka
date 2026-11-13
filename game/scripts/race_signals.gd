extends RefCounted
## Racer AI step 6a (docs/design/race-ai.md 6.1, "A racer should also look as if it is thinking"):
## a rival's lights in a race. Brake lights before a corner, an indicator before a turn, a pass or
## a yard, a flash of the headlights behind a slower car, the hazard lights while it backs out of
## a blocked street or its satnav thinks again after a wrong turn, and a wobble of the body on a
## mistake. They are read from what the traffic driver does (traffic.gd's Driver: `accel_now`,
## `held_up`, `wrong_t`, its way on, its sideways move), so a light never lies about the car, and
## how early, how often and whether at all is the rival's own (ladder.gd `indicate`, `flash`):
## Halina indicates three seconds ahead, Mike late, Seba never; Seba flashes at once, Halina and
## Słoik never. Nothing here changes how the car drives.
##
## `tick` is pure (a State, the driver, the lane graph: check_race_signals.gd plays it without a
## scene); `build` makes the four lamp meshes on a rival's node and `show` switches them
## (rivals.gd). One shared unshaded material, a mesh shown only while its lamp is lit: a braking
## rival costs one draw call more, an indicating one another every other half second.

const RaceLine := preload("res://scripts/race_line.gd")

## Brake lights: on from this pull (m/s²: lifting off is not braking) and for BRAKE_HOLD s after,
## and while it stands (under STAND m/s).
const BRAKE_FROM := -2.0
const BRAKE_HOLD := 0.25
const STAND := 0.3
## An indicator blinks BLINK_ON of every BLINK s, from the moment it comes on. A turn is indicated
## when the way on leaves the street's own direction by TURN_MIN rad or more (a shortcut or a yard:
## CUT_MIN, measured to the far end of the first piece of its curve), from `indicate` seconds
## before the junction at its speed and never less than TURN_LEAST m; a sideways move (a lane
## change, a pass out and back in) from SIDE_MIN m of it still to go, held SIDE_HOLD s at least so
## that it blinks once.
const BLINK := 0.7
const BLINK_ON := 0.55
const TURN_MIN := 0.45
const CUT_MIN := 0.2
const TURN_LEAST := 10.0
const SIDE_MIN := 0.5
const SIDE_HOLD := 0.6
## The headlight flash: two flashes of FLASH_ON s with FLASH_OFF s between, then not again for
## FLASH_AGAIN s.
const FLASH_ON := 0.12
const FLASH_OFF := 0.12
const FLASH_AGAIN := 3.5
## A mistake: the body swings WOBBLE_RAD each way, WOBBLE_HZ times a second, dying out over
## WOBBLE_S s. A phone call (rivals.gd): a slow weave of WEAVE_RAD.
const WOBBLE_RAD := 0.14
const WOBBLE_HZ := 2.2
const WOBBLE_S := 0.9
const WEAVE_RAD := 0.06
const WEAVE_HZ := 0.8
## The lamps' colours.
const RED := Color("#ff2418")
const AMBER := Color("#ffa51e")
const WHITE := Color("#fff6d8")

static var _material: StandardMaterial3D


## A rival's lights now, and what `tick` remembers between frames.
class State:
	var brake := false
	var left := false
	var right := false
	var flash := false
	## The body's swing (rad, + to the left as a yaw): a mistake's wobble, a phone call's weave.
	var yaw := 0.0
	## For the checks and the race log: how often each came on.
	var brakes := 0
	var indications := 0
	var flashes := 0
	var hazards := 0
	var _brake_hold := 0.0
	var _blink_t := 0.0
	var _side := 0
	var _side_hold := 0.0
	var _hazard := false
	var _flash_t := -1.0
	var _flash_wait := 0.0
	var _mistakes := 0
	var _wobble_t := 0.0
	var _weave_t := 0.0
	var _weave_s := 0.0

	## An indicator or the hazards are on (between blinks too).
	func indicating() -> bool:
		return _hazard or _side != 0

	## A slow weave for `seconds` (the phone call).
	func weave(seconds: float) -> void:
		_weave_t = seconds
		_weave_s = seconds

	## Everything off (the race is over).
	func clear() -> void:
		brake = false
		left = false
		right = false
		flash = false
		yaw = 0.0
		_side = 0
		_hazard = false
		_flash_t = -1.0
		_wobble_t = 0.0
		_weave_t = 0.0


## The side driver `d`'s way on turns to at the end of its street (-1 left, 1 right, 0 straight
## on or no way on): the next street's direction against its own, a shortcut's or a yard's by
## where its curve first leads. A U-turn is a turn to the left.
static func turn_side(d, graph) -> int:
	if d.next_edge < 0 or d.conn.size() < 4:
		return 0
	var e: int = d.edge
	if d.next_edge == graph.e_reverse[e] and not d.on_cut:
		return -1
	var here: Vector2 = graph.direction(e, graph.e_s1[e])
	var there: Vector2
	var least := TURN_MIN
	if d.on_cut:
		there = (d.conn[3] - d.conn[0]).normalized()
		least = CUT_MIN
	else:
		there = graph.direction(d.next_edge, graph.e_s0[d.next_edge])
	if absf(here.angle_to(there)) < least:
		return 0
	return 1 if there.dot(RaceLine.right(here)) > 0.0 else -1


## The side driver `d` is moving over to on its street (-1 left, 1 right, 0 not): out for a pass,
## back in from one, a lane change. A block across the player's line and a slide are not indicated.
static func move_side(d) -> int:
	if d.in_conn or d.block_t > 0.0 or d.daze > 0.0:
		return 0
	var to: float = d.pass_off if d.pass_t > 0.0 and not d.pass_back else d.off_target
	if absf(to - d.off) < SIDE_MIN:
		return 0
	return 1 if to > d.off else -1


## A frame of rival `d`'s lights into `st`: `traits` is its racer stats (ladder.gd: `indicate` the
## seconds of warning, 0 never; `flash` the seconds held up before it flashes, 0 never).
static func tick(st: State, d, graph, traits: Dictionary, dt: float) -> void:
	# Brake lights.
	var braking: bool = d.accel_now <= BRAKE_FROM or (d.v < STAND and d.back == 0)
	if braking:
		if st._brake_hold <= 0.0 and not st.brake:
			st.brakes += 1
		st._brake_hold = BRAKE_HOLD
	else:
		st._brake_hold -= dt
	st.brake = st._brake_hold > 0.0
	# Indicators: the hazards, else a sideways move, else the turn ahead.
	var hazard: bool = d.back != 0 or d.wrong_t > 0.0
	var warn := float(traits.get("indicate", 0.0))
	var side := 0
	if not hazard and warn > 0.0:
		side = move_side(d)
		if side != 0:
			st._side_hold = SIDE_HOLD
		elif st._side_hold > 0.0 and st._side != 0 and not d.in_conn:
			st._side_hold -= dt
			side = st._side
		else:
			st._side_hold = 0.0
			var turn := turn_side(d, graph)
			if turn != 0 and (d.in_conn or graph.e_s1[d.edge] - d.s <= maxf(TURN_LEAST, d.v * warn)):
				side = turn
	if hazard != st._hazard or side != st._side:
		st._blink_t = 0.0
		if hazard and not st._hazard:
			st.hazards += 1
		elif side != 0 and not hazard:
			st.indications += 1
	else:
		st._blink_t += dt
	st._hazard = hazard
	st._side = side
	var lit := fmod(st._blink_t, BLINK) < BLINK * BLINK_ON
	st.left = lit and (hazard or side < 0)
	st.right = lit and (hazard or side > 0)
	# The headlight flash.
	st._flash_wait -= dt
	var impatience := float(traits.get("flash", 0.0))
	if st._flash_t < 0.0 and impatience > 0.0 and d.held_up >= impatience and st._flash_wait <= 0.0:
		st._flash_t = 0.0
		st.flashes += 1
	if st._flash_t >= 0.0:
		st.flash = st._flash_t < FLASH_ON or st._flash_t >= FLASH_ON + FLASH_OFF
		st._flash_t += dt
		if st._flash_t >= FLASH_ON * 2.0 + FLASH_OFF:
			st._flash_t = -1.0
			st._flash_wait = FLASH_AGAIN
			st.flash = false
	else:
		st.flash = false
	# The body: a mistake's wobble, a call's weave.
	if d.mistakes > st._mistakes:
		st._wobble_t = WOBBLE_S
	st._mistakes = d.mistakes
	st.yaw = 0.0
	if st._wobble_t > 0.0:
		st._wobble_t -= dt
		st.yaw = WOBBLE_RAD * sin((WOBBLE_S - st._wobble_t) * TAU * WOBBLE_HZ) * maxf(st._wobble_t, 0.0) / WOBBLE_S
	elif st._weave_t > 0.0:
		st._weave_t -= dt
		st.yaw = WEAVE_RAD * sin((st._weave_s - st._weave_t) * TAU * WEAVE_HZ) * sin(PI * clampf(st._weave_t / st._weave_s, 0.0, 1.0))


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.vertex_color_use_as_albedo = true
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material


## The lamps of a car `size` (width, height, length; its front faces -Z, +X is its right): a node
## "signals" with four meshes, "brake", "left", "right" and "flash", all hidden. Bigger than a real
## car's lamps: they are read from the game's height, on a phone.
static func build(size: Vector3) -> Node3D:
	var out := Node3D.new()
	out.name = "signals"
	var hw := size.x * 0.5
	var hl := size.z * 0.5
	var y := minf(size.y * 0.42, 0.8)
	# Brake: a lamp at each rear corner and the high strip between them.
	var brake := [
		[Vector3(-hw + 0.3, y, hl + 0.03), Vector3(0.56, 0.26, 0.1)],
		[Vector3(hw - 0.3, y, hl + 0.03), Vector3(0.56, 0.26, 0.1)],
		[Vector3(0.0, minf(size.y * 0.78, y + 0.55), hl - 0.12), Vector3(0.7, 0.1, 0.1)],
	]
	out.add_child(_lamp("brake", brake, RED))
	for sgn: float in [-1.0, 1.0]:
		# An indicator: the front and the rear corner, wrapped round it, and one on the wing.
		var x := sgn * (hw + 0.02)
		var boxes := [
			[Vector3(x - sgn * 0.14, y + 0.02, -hl - 0.02), Vector3(0.36, 0.26, 0.3)],
			[Vector3(x - sgn * 0.14, y + 0.3, hl + 0.02), Vector3(0.36, 0.24, 0.3)],
			[Vector3(x, y + 0.12, -hl * 0.35), Vector3(0.1, 0.16, 0.34)],
		]
		out.add_child(_lamp("left" if sgn < 0.0 else "right", boxes, AMBER))
	var flash := [
		[Vector3(-hw + 0.36, y, -hl - 0.04), Vector3(0.6, 0.28, 0.1)],
		[Vector3(hw - 0.36, y, -hl - 0.04), Vector3(0.6, 0.28, 0.1)],
	]
	out.add_child(_lamp("flash", flash, WHITE))
	return out


static func _lamp(name: String, boxes: Array, colour: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(colour)
	for b: Array in boxes:
		var c: Vector3 = b[0]
		var h: Vector3 = b[1] * 0.5
		for axis in 3:
			for sgn: float in [-1.0, 1.0]:
				var n := Vector3.ZERO
				n[axis] = sgn
				var u := Vector3.ZERO
				u[(axis + 1) % 3] = h[(axis + 1) % 3]
				var v := Vector3.ZERO
				v[(axis + 2) % 3] = h[(axis + 2) % 3]
				var o := c + n * h[axis]
				var quad := [o - u - v, o + u - v, o + u + v, o - u + v]
				if sgn < 0.0:
					quad.reverse()
				for k: int in [0, 1, 2, 0, 2, 3]:
					st.set_normal(n)
					st.add_vertex(quad[k])
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = st.commit()
	mi.material_override = material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


## The lamps of `signals` (`build`) as `st` has them, or all off when `st` is null.
static func show(signals: Node3D, st: State) -> void:
	signals.get_node("brake").visible = st != null and st.brake
	signals.get_node("left").visible = st != null and st.left
	signals.get_node("right").visible = st != null and st.right
	signals.get_node("flash").visible = st != null and st.flash
