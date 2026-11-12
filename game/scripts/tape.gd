extends Node3D
## Loop MW-6 (docs/design/vision.md 4.4): KASETA, the time tape. The 20 then cards of
## `data/then_cards.json` (2010 to today: the user's answer 3), each at its notebook place.
## Within BUTTON_REACH m of a spot, driving slowly, the context button reads KASETA · time
## tape; a tap plays it: the VHS overlay for VHS_S s (vhs.gdshader, main.gd), a tape-rewind
## sound (made here, no file), a dithered ghost of the place as it was fades in (a few boxes,
## at most MAX_BOXES, from `ghost_boxes`: the cards' `ghost` notes) and the then card shows.
## The first time: +RESPECT respect and the card's stamp in the notebook (wallet.gd `tapes`,
## the notebook's KASETA page); egg_book.gd hears it (E36, E37).
##
## Cost: the ghost of the nearest spot is built (one MeshInstance3D, its boxes in one surface)
## only within BUILD_REACH m of it and freed past DROP_REACH; it is hidden (0 draw calls) until
## the tape plays and again when the ghost has faded out, so the city gets at most +1 draw call
## and only near a spot. The material is the buildings' own shader (building.gdshader, a
## material of its own: no new shader, Open Question 8's default) with its occlusion-ghost dither
## turned on everywhere: `ghost_fade` held at a constant by the occluder (`_ghost_params`), so
## a share of the pixels stays, and that share fades in and out. No shadow. The nearest-spot
## check runs twice a second; per frame only while a ghost fades.

const Lang := preload("res://scripts/lang.gd")
const Sfx := preload("res://scripts/sfx.gd")

signal played(card_id: String)

const CARDS_PATH := "res://data/then_cards.json"
const BUTTON_REACH := 40.0
const BUILD_REACH := 150.0
const DROP_REACH := 200.0
const SLOW_KMH := 12.0
const CHECK_EVERY := 0.5
const VHS_S := 6.0
const SHOW_S := 24.0
const FADE_S := 1.5
## The share of the ghost's pixels that stay once it has faded in.
const KEEP := 0.45
const RESPECT := 15
const MAX_BOXES := 24
## building.gdshader's plain material code (M_MEMBRANE: flat, a faint lift of noise).
const MODE := 11.0
const COLOURS := [Color("#e4ecf4"), Color("#a8cde6"), Color("#c9c2d8"), Color("#7d8a9c"), Color("#ffd9a8")]
const TAPE_COLOUR := Color("#ff1a8c")

## The spots: then_cards.json's fields plus `at` (Vector2: the place's point; INF if unknown) and `n`.
var spots: Array[Dictionary] = []
var by_id := {}
var wallet: Node
var hud: CanvasLayer
## map_builder.gd (ground_height).
var map: Node3D
## [position, km/h, flying, away] (main.gd).
var probe: Callable
## main.gd: the VHS overlay on for `seconds` (then back to the setting).
var vhs: Callable
## egg_book.gd: told of each play (`tape_played`), with the state from `state`.
var book: Node
var state: Callable
var blip: Callable
## --tape-log: a `tape:` line per play and per ghost built.
var log_on := false
var spent_usec := 0
var ready_ok := false
## The spot whose ghost is built (-1: none), the ghost and its boxes.
var near := -1
var ghost: MeshInstance3D
var ghost_boxes_n := 0
var _mat: ShaderMaterial
var _t := 0.0
## The spot playing (-1), seconds since it started, and the share of the ghost shown now.
var _playing := -1
var _play_t := 0.0
var _shown := 0.0
var _pill_up := false


## Reads then_cards.json. False if missing.
func load_cards() -> bool:
	if not FileAccess.file_exists(CARDS_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARDS_PATH))
	if not json is Dictionary:
		push_error("tape: %s does not parse" % CARDS_PATH)
		return false
	spots.clear()
	by_id.clear()
	for c: Dictionary in json.get("then_cards", []):
		var spot := c.duplicate(true)
		spot["at"] = Vector2.INF
		spot["n"] = spots.size() + 1
		by_id[str(c["id"])] = spots.size()
		spots.append(spot)
	return true


## Puts the spots on the map (`places`: notebook.gd's id -> Vector2).
func setup(places: Dictionary) -> bool:
	if spots.is_empty() and not load_cards():
		return false
	var placed := 0
	for s in spots:
		if places.has(str(s["place"])):
			s["at"] = places[str(s["place"])]
			placed += 1
	_mat = ShaderMaterial.new()
	_mat.shader = GpuQuirks.building_shader()
	_mat.set_shader_parameter("fade_radius", 0.0)
	_mat.set_shader_parameter("occlusion_radius", 100000.0)
	_mat.set_shader_parameter("ghost_keep", 0.0)
	Sfx.ui_add("rewind", rewind_sound(), -9.0)
	ready_ok = true
	print("tape: %d then cards, %d placed" % [spots.size(), placed])
	return true


## The spot for `key`: a card id, or its number from 1. -1 if none.
func index_of(key: String) -> int:
	if by_id.has(key):
		return by_id[key]
	if key.is_valid_int() and int(key) >= 1 and int(key) <= spots.size():
		return int(key) - 1
	return -1


# --- the ghosts --------------------------------------------------------------------------

## The boxes of a card's ghost, in metres from its place's point: [x, z, width (x), height,
## depth (z), base above the ground, yaw in degrees, colour index]. Simple shapes after the
## card's `ghost` note; at most MAX_BOXES.
static func ghost_boxes(id: String) -> Array:
	var b: Array = []
	match id:
		"t_defilad_2012":  # a big screen on a scaffold frame, a row of white tents, crowd barriers
			b.append([0, -30, 26, 12, 1.2, 6, 0, 1])
			for x in [-12, 12]:
				b.append([x, -30, 1.2, 6, 1.2, 0, 0, 3])
			for i in 5:
				b.append([-24 + i * 12, 4, 7, 3.5, 7, 0, 0, 0])
			for i in 8:
				b.append([-28 + i * 8, -16, 6.5, 1.1, 0.4, 0, 0, 2])
		"t_muzeum_2020":  # a fenced site, two tower cranes, a two-storey concrete frame
			b += _fence(Vector2.ZERO, 40, 30)
			b += _crane(Vector2(-14, -8), 42, 28, 30)
			b += _crane(Vector2(16, 10), 36, 24, 200)
			b.append([0, 0, 30, 0.6, 20, 4, 0, 3])
			b.append([0, 0, 30, 0.6, 20, 8, 0, 3])
			for c in [[-14, -9], [14, -9], [-14, 9], [14, 9]]:
				b.append([c[0], c[1], 0.8, 8, 0.8, 0, 0, 3])
		"t_palac_2020":  # the new tower west of the Palace as a bare core with a crane
			b.append([-170, 70, 14, 130, 14, 0, 0, 3])
			b += _crane(Vector2(-170, 70), 30, 26, 60, 130)
		"t_stadion_2010":  # the old bowl's rim, a half-built ring of masts, three cranes
			for i in 12:
				var a := TAU * i / 12.0
				b.append([cos(a) * 110, sin(a) * 90, 60, 9, 12, 0, -rad_to_deg(a) + 90, 2])
			for i in 6:
				var a := TAU * (i + 0.5) / 12.0
				b.append([cos(a) * 118, sin(a) * 98, 1.6, 40, 1.6, 0, 0, 3])
			b += _crane(Vector2(-40, 20), 46, 32, 30)
			b += _crane(Vector2(50, -30), 42, 28, 160)
			b += _crane(Vector2(10, 60), 38, 26, 260)
		"t_stadion_metro_2014":  # a fenced station dig, site huts, barriers
			b += _fence(Vector2.ZERO, 36, 18)
			b.append([0, 0, 30, 0.4, 12, -0.2, 0, 3])
			for i in 3:
				b.append([-14 + i * 7, 14, 6, 2.6, 2.5, 0, 0, 0])
			for i in 4:
				b.append([-12 + i * 8, -12, 6, 1.1, 0.4, 0, 0, 2])
		"t_swietokrzyska_2012":  # the street closed by site fences, a long trench, a crane, huts
			b.append([0, -7, 90, 2.4, 0.3, 0, 0, 0])
			b.append([0, 7, 90, 2.4, 0.3, 0, 0, 0])
			b.append([0, 0, 80, 0.3, 8, -0.1, 0, 3])
			b += _crane(Vector2(20, 0), 40, 26, 100)
			for i in 3:
				b.append([-30 + i * 7, 12, 6, 2.6, 2.5, 0, 0, 2])
		"t_rotunda_2017":  # a ring of site fence round a bare round roof on posts
			for i in 10:
				var a := TAU * i / 10.0
				b.append([cos(a) * 19, sin(a) * 19, 12, 2.2, 0.3, 0, -rad_to_deg(a) + 90, 0])
			b.append([0, 0, 22, 0.8, 22, 6, 0, 2])
			b.append([0, 0, 22, 0.8, 22, 6, 45, 2])
			for c in [[-7, -7], [7, -7], [-7, 7], [7, 7]]:
				b.append([c[0], c[1], 0.6, 6, 0.6, 0, 0, 3])
		"t_syreni_2016":  # the pavilion lit, a queue along the path, a door lamp
			b.append([0, 0, 22, 5, 11, 0, 0, 4])
			b.append([12, 4, 0.5, 3, 0.5, 0, 0, 4])
			b += _figures(Vector2(14, 6), Vector2(1, 0.4), 12, 0)
		"t_daszynskiego_2010":  # low boxes and flat car parks round the roundabout
			for c in [[-60, -55, 40, 10, 24], [55, -60, 30, 8, 30], [-65, 50, 34, 9, 22], [60, 55, 44, 7, 26],
					[0, -90, 26, 12, 18], [-95, 0, 20, 8, 30]]:
				b.append([c[0], c[1], c[2], c[3], c[4], 0, 0, 2])
			for c in [[30, -95], [95, 10], [-20, 92]]:
				b.append([c[0], c[1], 34, 0.3, 22, 0, 0, 3])
		"t_centralny_2011":  # scaffolding on the hall's glass walls, plywood tunnels at the doors
			for x in [-22, 22]:
				b.append([x, -24, 40, 14, 1.4, 0, 0, 3])
				b.append([x, -24, 40, 0.4, 2.2, 7, 0, 0])
			for i in 3:
				b.append([-18 + i * 18, -30, 4, 3, 10, 0, 0, 4])
		"t_cnk_2010":  # site fence, one crane, the planetarium's sphere as a bare frame
			b += _fence(Vector2.ZERO, 70, 50)
			b += _crane(Vector2(-20, 10), 44, 30, 40)
			for yaw in [0, 60, 120]:
				b.append([22, -12, 18, 18, 0.8, 1, yaw, 3])
		"t_fontanny_2010":  # grass and paths only, no basins, a few benches
			b.append([0, 0, 70, 0.15, 4, 0, 0, 0])
			b.append([0, 0, 4, 0.15, 50, 0, 0, 0])
			for i in 6:
				b.append([-26 + i * 10, 6 if i % 2 == 0 else -6, 2, 0.9, 0.7, 0, 0, 3])
		"t_koszyki_2014":  # the two side wings and the arcade wall, a crane between
			b.append([-22, 0, 10, 12, 40, 0, 0, 2])
			b.append([22, 0, 10, 12, 40, 0, 0, 2])
			b.append([0, -20, 44, 10, 1.5, 0, 0, 2])
			b += _crane(Vector2(0, 4), 36, 24, 90)
		"t_gwardii_2016":  # boarded windows, a fence along the front, an empty forecourt
			b.append([0, 18, 50, 2.2, 0.3, 0, 0, 0])
			b.append([-25, 9, 0.3, 2.2, 18, 0, 0, 0])
			b.append([25, 9, 0.3, 2.2, 18, 0, 0, 0])
			for i in 6:
				b.append([-20 + i * 8, 0.5, 4, 3, 0.4, 2, 0, 3])
		"t_elektrownia_2015":  # the brick halls dark, the yard fenced, no terraces
			b += _fence(Vector2.ZERO, 50, 36)
			b.append([30, -10, 3.5, 42, 3.5, 0, 0, 3])
			b.append([-6, -6, 30, 12, 16, 0, 0, 3])
		"t_schodki_2014":  # no steps yet: a grassy bank, bushes, a plain road by the water
			b.append([0, 0, 60, 1.2, 14, 0, 0, 1])
			b.append([0, -14, 70, 0.2, 7, 0, 0, 3])
			for i in 8:
				b.append([-28 + i * 8, 4 + (i % 3) * 2, 3, 2.2, 3, 1, 0, 1])
		"t_bulwary_2018":  # three scooters lying in a row on the promenade
			for i in 3:
				b.append([-4 + i * 4, 0, 1.2, 0.2, 0.5, 0.05, 20 + i * 25, 0])
				b.append([-4 + i * 4 + 0.6, 0.5, 1.1, 0.12, 0.12, 0.1, 20 + i * 25, 3])
		"t_rowerilo_2012":  # a dock of the first season's bikes and three waiting figures
			b.append([0, 0, 14, 0.8, 0.3, 0, 0, 3])
			for i in 8:
				b.append([-6 + i * 1.7, 0.9, 0.5, 1.0, 1.8, 0, 0, 1])
			b += _figures(Vector2(9, 2), Vector2(1, 0.2), 3, 2)
		"t_wiralek_2024":  # a long queue down Chmielna, one in five with a phone up
			b += _figures(Vector2(-2, 0), Vector2(-1, 0.1), 15, 0)
			for i in 3:
				b.append([-2 - (2 + i * 5) * 1.2, (2 + i * 5) * 0.12, 0.3, 0.5, 0.1, 1.8, 0, 4])
		"t_glon_2015":  # the café's fascia in brown, two tables outside
			b.append([0, -2, 8, 1.2, 0.4, 3.2, 0, 3])
			for x in [-2.5, 2.5]:
				b.append([x, 1.5, 1, 0.8, 1, 0, 0, 0])
				b.append([x - 0.9, 1.5, 0.5, 0.5, 0.5, 0, 0, 2])
				b.append([x + 0.9, 1.5, 0.5, 0.5, 0.5, 0, 0, 2])
	return b


## A fence round a w x d rectangle centred on `c` (four boxes).
static func _fence(c: Vector2, w: float, d: float) -> Array:
	return [[c.x, c.y - d * 0.5, w, 2.2, 0.3, 0, 0, 0], [c.x, c.y + d * 0.5, w, 2.2, 0.3, 0, 0, 0],
			[c.x - w * 0.5, c.y, 0.3, 2.2, d, 0, 0, 0], [c.x + w * 0.5, c.y, 0.3, 2.2, d, 0, 0, 0]]


## A tower crane: a mast `h` m high on `base` m, a jib `jib` m long turned `yaw` degrees.
static func _crane(c: Vector2, h: float, jib: float, yaw: float, base := 0.0) -> Array:
	var dir := Vector2(cos(deg_to_rad(yaw)), -sin(deg_to_rad(yaw)))
	var mid := c + dir * (jib * 0.5 - 6.0)
	return [[c.x, c.y, 1.6, h, 1.6, base, 0, 4], [mid.x, mid.y, jib, 1.2, 1.2, base + h, yaw, 4]]


## `n` standing figures from `from` along `dir`, 1.2 m apart (colour `col`).
static func _figures(from: Vector2, dir: Vector2, n: int, col: int) -> Array:
	var out: Array = []
	for i in n:
		var p := from + dir * 1.2 * i
		out.append([p.x, p.y, 0.55, 1.7, 0.4, 0, 0, col])
	return out


## The ghost's mesh for spot `i` (at its place, on the ground), building.gdshader's attributes:
## UV the wall coordinates (roofs -1), UV2 the material code and the box top.
func ghost_mesh(i: int) -> ArrayMesh:
	var s := spots[i]
	var at: Vector2 = s["at"]
	var boxes := ghost_boxes(str(s["id"]))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for bx: Array in boxes.slice(0, MAX_BOXES):
		var c := at + Vector2(float(bx[0]), float(bx[1]))
		var y: float = (map.ground_height(c.x, c.y) if map != null else 0.0) + float(bx[5])
		_box(st, Vector3(c.x, y, c.y), Vector3(float(bx[2]), float(bx[3]), float(bx[4])), deg_to_rad(float(bx[6])),
				COLOURS[clampi(int(bx[7]), 0, COLOURS.size() - 1)])
	return st.commit()


## A box standing on `base` (its bottom's centre), turned `yaw` about the vertical.
static func _box(st: SurfaceTool, base: Vector3, size: Vector3, yaw: float, col: Color) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var h := size * 0.5
	var centre := base + Vector3(0, h.y, 0)
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var q := [n * h[axis] - u - v, n * h[axis] + u - v, n * h[axis] + u + v, n * h[axis] - u + v]
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			var wall := axis != 1
			for k in [0, 1, 2, 0, 2, 3]:
				var lp: Vector3 = q[k]
				st.set_color(col)
				st.set_normal(basis * n)
				# Walls: metres along and up (the shader's wall coordinates); tops: -1 (plain).
				st.set_uv(Vector2(absf(lp.x + lp.z) , lp.y + h.y) if wall else Vector2(-1.0, -1.0))
				st.set_uv2(Vector2(MODE, size.y))
				st.add_vertex(centre + basis * lp)


func _build_ghost(i: int) -> void:
	_drop_ghost()
	near = i
	ghost = MeshInstance3D.new()
	ghost.name = "TapeGhost"
	ghost.mesh = ghost_mesh(i)
	ghost.material_override = _mat
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.visible = false
	ghost_boxes_n = mini(ghost_boxes(str(spots[i]["id"])).size(), MAX_BOXES)
	add_child(ghost)
	if log_on:
		print("tape: ghost built for %d %s (%d boxes), hidden until played" % [i + 1, spots[i]["id"], ghost_boxes_n])


func _drop_ghost() -> void:
	if ghost != null:
		ghost.queue_free()
		ghost = null
	near = -1
	ghost_boxes_n = 0


## The occlusion-ghost uniforms that dither the whole mesh, `show` (0..KEEP) of its pixels kept:
## ghost_fade (ghost.gdshaderinc) is held at 1 - show everywhere (the occluder is set so every
## fragment is the same small distance "behind" it), ghost_keep 0: a pixel stays when its Bayer
## threshold is over the fade; the lit faces' glow keeps `show` of itself.
func _ghost_params(show: float) -> void:
	if _mat == null or near < 0:
		return
	var at: Vector2 = spots[near]["at"]
	var fade := clampf(1.0 - show, 0.0, 1.0)
	# smoothstep(1, 4, x) = fade: x from the inverse of 3t² - 2t³.
	var lo := 0.0
	var hi := 1.0
	for k in 24:
		var t := (lo + hi) * 0.5
		if t * t * (3.0 - 2.0 * t) < fade:
			lo = t
		else:
			hi = t
	var x := 1.0 + 3.0 * (lo + hi) * 0.5
	const EPS := 0.0001
	# side = (world z - occluder y) * EPS = -x within 0.03 over the spot's 300 m.
	_mat.set_shader_parameter("occluder", Vector4(at.x, at.y + x / EPS, 0.0, EPS))
	_mat.set_shader_parameter("ghost_keep", 0.0)


# --- the frame ---------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not ready_ok:
		return
	var t0 := Time.get_ticks_usec()
	if _playing >= 0:
		_play_frame(dt)
	_t += dt
	if _t >= CHECK_EVERY and probe.is_valid():
		_t = 0.0
		var s: Array = probe.call()
		tick(s[0], float(s[1]), bool(s[2]), bool(s[3]))
	spent_usec += Time.get_ticks_usec() - t0


## One check: the nearest spot's ghost built or dropped, the context button up or down.
func tick(pos: Vector3, kmh: float, flying: bool, away: bool) -> void:
	var p := Vector2(pos.x, pos.z)
	var best := -1
	var best_d := INF
	for i in spots.size():
		var at: Vector2 = spots[i]["at"]
		if at == Vector2.INF:
			continue
		var d := p.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = i
	best_d = sqrt(best_d)
	if best >= 0 and best_d < BUILD_REACH and best != near and _playing < 0:
		_build_ghost(best)
	elif near >= 0 and _playing < 0 and (best != near or best_d > DROP_REACH):
		if best_d > DROP_REACH or best != near:
			_drop_ghost()
	var want := not away and not flying and best >= 0 and best_d < BUTTON_REACH and kmh < SLOW_KMH and _playing < 0
	_set_pill(want)


func _set_pill(on: bool) -> void:
	if hud == null:
		return
	if on and not hud.pill_shown("tape") and hud.pill_free_for("tape"):
		hud.show_pill("KASETA", "time tape", "tape")
		_pill_up = true
	elif not on and hud.pill_shown("tape"):
		hud.hide_pill()
		_pill_up = false


## The context button: KASETA pressed (hud.gd context_pressed).
func on_context(owner: String) -> void:
	if owner != "tape" or near < 0:
		return
	hud.hide_pill()
	play(near)


## Plays the tape at spot `i`: the ghost, the VHS, the sound, the card; the first time the reward.
func play(i: int) -> void:
	if i < 0 or i >= spots.size():
		return
	var s := spots[i]
	if near != i or ghost == null:
		_build_ghost(i)
	_playing = i
	_play_t = 0.0
	_shown = 0.0
	_ghost_params(0.0)
	ghost.visible = true
	if vhs.is_valid():
		vhs.call(VHS_S)
	Sfx.ui("rewind")
	var id := str(s["id"])
	var line: Array = s["line"]
	var first: bool = wallet != null and not wallet.tapes.has(id)
	if first:
		stamp(id)
		wallet.pay(0, RESPECT)
	if hud != null:
		hud.show_note("%s · %d%s" % [Lang.pick("KASETA", "TAPE"), int(s["year"]), " · +%d ★" % RESPECT if first else ""], Lang.pick(line[0], line[1]), TAPE_COLOUR)
	if blip.is_valid() and first:
		blip.call()
	print("tape: %d %s ghost ok (%d boxes)%s" % [i + 1, id, ghost_boxes_n, ", first time: +%d respect" % RESPECT if first else ""])
	played.emit(id)
	if book != null and state.is_valid():
		book.tape_played(id, state.call())


## Marks then card `id` played (its stamp in the notebook): the tape, or an egg's reward (E38).
func stamp(id: String, date := 0) -> void:
	if wallet == null or wallet.tapes.has(id):
		return
	var d := Time.get_date_dict_from_system()
	wallet.tapes[id] = date if date > 0 else int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
	wallet.save()
	if hud != null:
		hud.notebook_changed()


func _play_frame(dt: float) -> void:
	_play_t += dt
	var show := KEEP
	if _play_t < FADE_S:
		show = KEEP * _play_t / FADE_S
	elif _play_t > SHOW_S - FADE_S:
		show = KEEP * clampf((SHOW_S - _play_t) / FADE_S, 0.0, 1.0)
	if absf(show - _shown) > 0.004 or _play_t >= SHOW_S:
		_shown = show
		_ghost_params(show)
	if _play_t >= SHOW_S:
		_playing = -1
		if ghost != null:
			ghost.visible = false


func playing() -> bool:
	return _playing >= 0


func played_total() -> int:
	var n := 0
	for s in spots:
		n += int(wallet != null and wallet.tapes.has(str(s["id"])))
	return n


## The tape-rewind sound, made once: 1.3 s of a fast warbling whir rising in pitch with tape
## flutter and hiss, the click of the stop at the end (mono, 22.05 kHz, 16 bit; seeded noise).
static func rewind_sound() -> AudioStreamWAV:
	const RATE := 22050
	const LEN := 1.3
	var n := int(RATE * LEN)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2012
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / LEN
		var f := 260.0 + 1500.0 * k * k + 40.0 * sin(TAU * 11.0 * t)
		phase += f / RATE
		var saw := fmod(phase, 1.0) * 2.0 - 1.0
		var hiss := rng.randf_range(-1.0, 1.0)
		var env := minf(1.0, t / 0.05) * (1.0 - smoothstep(0.92, 0.97, k))
		var v := (saw * 0.28 + hiss * 0.12) * env
		if k > 0.97:
			v += rng.randf_range(-1.0, 1.0) * 0.6 * exp(-(t - LEN * 0.97) * 160.0)
		data.encode_s16(i * 2, clampi(int(v * 32767.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
