extends Control
## Beer pong at THE TAPCZAN's table (F's ask 2026-11-24, docs/design/tapczan-pub.md): the view and
## the touch. The rules, the ball and the rivals' throws are beer_pong_sim.gd; this node draws the
## table from behind the player's end (a fixed perspective drawn in 2D: the table, two triangles of
## red cups, the rival behind the far end, the ball and its shadow) and reads the slingshot.
##
## Touch: put a finger down anywhere, pull back (down) and to the side, let go: the further back,
## the harder; pulled left, the ball goes right (a slingshot). While pulling, the ball in the hand
## sways with the drinks (sim `sway`), and for the first two throws a dotted arc shows where it goes
## (without the sway). The ball then flies along the sim's path; on a rim it spins round once before
## it drops or pops out. Then the rival throws (two balls, the same rules). Two hits in a turn: the
## balls come back. Every cup they take is a drink: the hand sways more. The end: WYGRANA (the stake
## in złoty) or PRZEGRANA, then JESZCZE RAZ (again) or DO BARU (back to the room). PODDAJ SIĘ (top
## right) gives up. Keys: none needed (a mouse drag works as a finger on the Mac).
##
## Cost: 2D only, redrawn while something moves (a few hundred primitives); the aim's arc is
## traced into one reused array; nothing is allocated per frame.

const Sim := preload("res://scripts/beer_pong_sim.gd")
const Room := preload("res://scripts/tapczan_room.gd")
const Lang := preload("res://scripts/lang.gd")
const UiKit := preload("res://scripts/ui_kit.gd")

## The view: the eye (table frame: the player's edge at z 0, the top at y 0) and its pitch (rad).
const EYE := Vector3(0.0, 2.0, -1.4)
const PITCH := 0.62
## The focal length and the horizon's row as shares of the screen's height.
const FOCAL := 1.5
const MID := 0.45
## The cups are drawn this much larger than the sim's (readability at phone size; the rims' rule is the sim's).
const CUP_DRAW := 1.2
## The ball's flight: path points per second (the sim keeps one every two steps at 120 Hz).
const PATH_RATE := 60.0
const SPIN_S := 0.8
const SAY_S := 1.1
const RIVAL_WAIT := 0.9
## The shortest pull (px at pt 1) that throws; the pull for full power and full side (shares of h, w).
const MIN_PULL := 14.0
const FULL_PULL := 0.34
const FULL_SIDE := 0.22
const AUTO_AIM := 0.7

const FELT := Color("#121214")
const EDGE_C := Color("#f2f2ea")
const CUP := Color("#d4282e")
const CUP_D := Color("#9a1c22")
const BALL := Color("#fbf7ee")
const WALL := Color("#2a1a14")
const WALL_D := Color("#1a100c")
const ARC := Color(1.0, 0.82, 0.25, 0.9)

## won, the stake paid (0 when lost), the drinks it cost.
signal finished(won: bool, stake: int, drinks: int)
## The view went away (DO BARU, or a test run's end).
signal closed

var pt := 1.0
var auto_play := false
var log_on := false
var rival_id := ""
var sim: Sim
var stake := 0

enum Stage { AIM, FLY, SPIN, SAY, RIVAL, OVER }
var stage := Stage.AIM
var _rival: Dictionary = {}
var _clock := 0.0
var _t := 0.0
## The flight on screen: the sim's path, who threw (0 player, 1 rival), the result.
var _path := PackedVector3Array()
var _flight_by := 0
var _result: Dictionary = {}
var _pulling := false
var _pull_from := Vector2.ZERO
var _pull_to := Vector2.ZERO
var _aim := PackedVector3Array()
var _banner := ""
var _quip := ""
var _paid := false
var _quit_rect := Rect2()
var _again_rect := Rect2()
var _done_rect := Rect2()
var _font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_font = ThemeDB.fallback_font


## A game against rival `id` (data/tapczan.json "rivals").
func start(id: String, r: Dictionary) -> void:
	rival_id = id
	_rival = r
	stake = int(r.get("stake", 0))
	sim = Sim.new()
	sim.skill = float(r.get("skill", 0.5))
	sim.late_skill = float(r.get("late_skill", -1.0))
	stage = Stage.AIM
	_t = 0.0
	_paid = false
	_path.resize(0)
	_banner = Room.say("your_turn")
	_quip = _line_of("hello")
	visible = true
	queue_redraw()
	_log("start vs %s (skill %.2f, stake %d)" % [id, sim.skill, stake])


func _line_of(key: String) -> String:
	var lines: Array = _rival.get(key, [])
	if lines.is_empty():
		return ""
	var l: Array = lines[sim.rng.randi() % lines.size()]
	return Lang.pick(str(l[0]), str(l[1]))


# --- the view ------------------------------------------------------------------------------------

## A table point (x, y, z) on the screen.
func project(p: Vector3) -> Vector2:
	var s := size
	var d := p - EYE
	var fwd := Vector3(0.0, -sin(PITCH), cos(PITCH))
	var up := Vector3(0.0, cos(PITCH), sin(PITCH))
	var z := maxf(d.dot(fwd), 0.05)
	var f := FOCAL * s.y
	return Vector2(s.x * 0.5 + d.x * f / z, s.y * MID - d.dot(up) * f / z)


## The screen radius of `r` m at table point `p`.
func _scale_at(p: Vector3, r: float) -> float:
	var d := p - EYE
	return r * FOCAL * size.y / maxf(d.dot(Vector3(0.0, -sin(PITCH), cos(PITCH))), 0.05)


## A point of a throw in the table's frame: the rival throws from the far end.
static func _shown(p: Vector3, by: int) -> Vector3:
	return p if by == 0 else Vector3(-p.x, p.y, Sim.L - p.z)


func _draw() -> void:
	if sim == null:
		return
	var s := size
	# The pub behind: the wall, warm lamps, the rival.
	draw_rect(Rect2(Vector2.ZERO, s), WALL)
	draw_rect(Rect2(0, s.y * 0.62, s.x, s.y * 0.38), WALL_D)
	for i in 5:
		var lx := s.x * (0.1 + i * 0.2)
		draw_circle(Vector2(lx, s.y * 0.06), s.y * 0.05, Color(1.0, 0.75, 0.4, 0.18))
		draw_circle(Vector2(lx, s.y * 0.06), s.y * 0.015, Color(1.0, 0.85, 0.55))
	_draw_rival()
	# The table.
	var hw := Sim.W * 0.5
	var quad := PackedVector2Array([project(Vector3(-hw, 0, 0)), project(Vector3(hw, 0, 0)),
			project(Vector3(hw, 0, Sim.L)), project(Vector3(-hw, 0, Sim.L))])
	draw_colored_polygon(quad, FELT)
	draw_polyline(PackedVector2Array([quad[0], quad[1], quad[2], quad[3], quad[0]]), EDGE_C, 2.0 * pt)
	draw_line(project(Vector3(0, 0, 0)), project(Vector3(0, 0, Sim.L)), Color(EDGE_C, 0.5), 1.5 * pt)
	draw_line(project(Vector3(-hw, 0, Sim.L * 0.5)), project(Vector3(hw, 0, Sim.L * 0.5)), Color(EDGE_C, 0.5), 1.5 * pt)
	# The cups, far first: the rival's (as the player sees them), then the player's own.
	for c: Vector2 in sim.cups[1]:
		_draw_cup(Vector3(c.x, 0, c.y))
	var mine: Array = sim.cups[0]
	for i in range(mine.size() - 1, -1, -1):
		var c: Vector2 = mine[i]
		_draw_cup(_shown(Vector3(c.x, 0, c.y), 1))
	# The aim: the band and the dotted arc.
	if stage == Stage.AIM and _pulling:
		var hand := project(_hand())
		draw_line(hand, _pull_to, Color(1, 1, 1, 0.5), 3.0 * pt)
		if sim.throws < 2:
			for i in range(2, _aim.size(), 3):
				draw_circle(project(_aim[i]), 3.0 * pt, ARC)
	# The ball: in the hand, or in flight with its shadow.
	var ball := Vector3.INF
	if stage == Stage.AIM:
		ball = _hand()
	elif stage == Stage.FLY or stage == Stage.SPIN:
		ball = _ball_now()
	if ball != Vector3.INF:
		var shadow := project(Vector3(ball.x, 0.0, ball.z))
		if absf(ball.x) < hw and ball.z > 0.0 and ball.z < Sim.L:
			draw_circle(shadow, _scale_at(Vector3(ball.x, 0, ball.z), Sim.BALL_R) * 1.1, Color(0, 0, 0, 0.45))
		var r := maxf(_scale_at(ball, Sim.BALL_R), 2.5 * pt)
		draw_circle(project(ball), r, BALL)
		draw_circle(project(ball) - Vector2(r, r) * 0.3, r * 0.35, Color(1, 1, 1))
	_draw_text()


func _draw_cup(p: Vector3) -> void:
	var r := _scale_at(p, Sim.CUP_R * CUP_DRAW)
	var top := project(p + Vector3(0, Sim.CUP_H, 0))
	var base := project(p)
	var rb := r * 0.75
	draw_colored_polygon(PackedVector2Array([top + Vector2(-r, 0), top + Vector2(r, 0), base + Vector2(rb, 0), base + Vector2(-rb, 0)]), CUP)
	draw_rect(Rect2(base + Vector2(-rb, -r * 0.4), Vector2(rb * 2.0, r * 0.4)), CUP_D)
	draw_set_transform(top, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, r, EDGE_C)
	draw_circle(Vector2.ZERO, r * 0.82, Color("#e8c46a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rival() -> void:
	# Behind the far end, waist at the table: sized to the screen so the head stays under the banner.
	var h := size.y * 0.16
	var feet := project(Vector3(0.0, 0.0, Sim.L + 0.3)) + Vector2(0, 0.62 * h)
	var col := Color("#7a3a5a")
	match rival_id:
		"sommelier":
			col = Color("#5a1a2a")
		"office":
			col = Color("#e8e8ee")
		"first":
			col = Color("#c86aa8")
	var bounce := 0.02 * h * sin(_clock * 2.0)
	draw_rect(Rect2(feet + Vector2(-0.22 * h, -1.45 * h + bounce), Vector2(0.44 * h, 0.85 * h)), col)
	draw_circle(feet + Vector2(0, -1.65 * h + bounce), 0.14 * h, Color("#d8a888"))
	if rival_id == "first":
		draw_circle(feet + Vector2(0, -1.75 * h + bounce), 0.13 * h, Color("#e8e0d0"))  # the perm
	elif rival_id == "sommelier":
		draw_rect(Rect2(feet + Vector2(-0.12 * h, -1.42 * h + bounce), Vector2(0.24 * h, 0.5 * h)), Color("#2a1a12"))  # the apron
	elif rival_id == "office":
		draw_rect(Rect2(feet + Vector2(-0.03 * h, -1.42 * h + bounce), Vector2(0.06 * h, 0.4 * h)), Color("#3a5a9a"))  # the tie


func _draw_text() -> void:
	var s := size
	var big := int(22 * pt)
	var mid := int(15 * pt)
	var small := int(12 * pt)
	var cups := Room.pair("cups")
	var cups_s := Lang.pick(str(cups[0]), str(cups[1])) % [sim.cups[0].size(), sim.cups[1].size()]
	draw_string_outline(_font, Vector2(16 * pt, 30 * pt), cups_s, HORIZONTAL_ALIGNMENT_LEFT, -1, mid, 4 * pt, Color.BLACK)
	draw_string(_font, Vector2(16 * pt, 30 * pt), cups_s, HORIZONTAL_ALIGNMENT_LEFT, -1, mid, UiKit.GOLD)
	var dr := Room.say("drinks", [sim.drinks])
	draw_string(_font, Vector2(16 * pt, 50 * pt), dr, HORIZONTAL_ALIGNMENT_LEFT, -1, small, UiKit.HEAT if sim.drinks > 0 else UiKit.SUB)
	# The banner and the rival's quip in the left column (the table and the rival hold the middle).
	var col_w := s.x * 0.34
	var bx := 16 * pt
	if _banner != "":
		draw_multiline_string_outline(_font, Vector2(bx, s.y * 0.36), _banner, HORIZONTAL_ALIGNMENT_LEFT, col_w, big, -1, 5 * pt, Color.BLACK)
		draw_multiline_string(_font, Vector2(bx, s.y * 0.36), _banner, HORIZONTAL_ALIGNMENT_LEFT, col_w, big, -1, UiKit.INK)
	if _quip != "":
		var qy := s.y * 0.36 + (big + 8 * pt) * ceilf(_font.get_string_size(_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x / col_w) + 6 * pt
		draw_multiline_string_outline(_font, Vector2(bx, qy), _quip, HORIZONTAL_ALIGNMENT_LEFT, col_w, mid, -1, 4 * pt, Color.BLACK)
		draw_multiline_string(_font, Vector2(bx, qy), _quip, HORIZONTAL_ALIGNMENT_LEFT, col_w, mid, -1, UiKit.SUB)
	if stage != Stage.OVER:
		_quit_rect = _text_button(Vector2(s.x - 16 * pt, 16 * pt), Room.say("give_up"), false, true)
	else:
		var c := Vector2(s.x * 0.5, s.y * 0.8)
		_again_rect = _text_button(c - Vector2(8 * pt, 0), Room.say("again"), true, true)
		_done_rect = _text_button(c + Vector2(8 * pt, 0), Room.say("done"), false, false)


## A drawn button: right-aligned at `at` when `right`, else left-aligned; returns its rect.
func _text_button(at: Vector2, text: String, gold: bool, right: bool) -> Rect2:
	var fs := int(15 * pt)
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28 * pt
	var r := Rect2(at - Vector2(w if right else 0.0, 0), Vector2(w, 44 * pt))
	draw_rect(r, UiKit.GOLD if gold else UiKit.RAISED)
	draw_rect(r, UiKit.EDGE_STRONG, false, 1.5 * pt)
	draw_string(_font, r.position + Vector2(14 * pt, 29 * pt), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.ON_GOLD if gold else UiKit.INK)
	return r


# --- the aim -------------------------------------------------------------------------------------

## The ball in the hand: the release point, swaying with the drinks.
func _hand() -> Vector3:
	var sw := sim.sway(_clock)
	return Sim.RELEASE + Vector3(sw.x * 0.25, 0.0, 0.0)


## The slingshot's pull as the sim's (lateral, power).
func _pull_aim() -> Vector2:
	var d := _pull_to - _pull_from
	return Vector2(clampf(-d.x / (size.x * FULL_SIDE), -1.0, 1.0), clampf(d.y / (size.y * FULL_PULL), 0.0, 1.0))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			if _quit_rect.has_point(e.position) and stage != Stage.OVER:
				_end(false)
			elif stage == Stage.OVER:
				if _again_rect.has_point(e.position):
					start(rival_id, _rival)
				elif _done_rect.has_point(e.position):
					_close()
			elif stage == Stage.AIM and sim.turn == 0:
				_pulling = true
				_pull_from = e.position
				_pull_to = e.position
		elif _pulling:
			_pulling = false
			_pull_to = e.position
			if (_pull_to - _pull_from).length() > MIN_PULL * pt and _pull_to.y > _pull_from.y:
				var a := _pull_aim()
				_throw(a.x, a.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _pulling:
		_pull_to = (event as InputEventScreenDrag).position
		var a := _pull_aim()
		if sim.throws < 2:
			sim.predict(a.x, a.y, _aim)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		if stage == Stage.OVER:
			_close()
		else:
			_end(false)
		get_viewport().set_input_as_handled()


## The player's throw with the slingshot's `lateral` and `power`.
func _throw(lateral: float, power: float) -> void:
	var r := sim.throw_player(lateral, power, _clock)
	if r.is_empty():
		return
	_fly(r, 0)
	_log("throw %d: lat %.2f pow %.2f -> %s, cups %d:%d" % [sim.throws, lateral, power, r["result"], sim.cups[0].size(), sim.cups[1].size()])


func _fly(r: Dictionary, by: int) -> void:
	_result = r
	_flight_by = by
	_path = r["path"]
	_t = 0.0
	stage = Stage.FLY
	_banner = ""


## The ball's place now along the flight (or round the rim while it spins).
func _ball_now() -> Vector3:
	if _path.is_empty():
		return Vector3.INF
	if stage == Stage.SPIN:
		var at: Vector3 = _result["at"]
		var a := _t / SPIN_S * TAU * 1.5
		var rr := Sim.CUP_R * (1.0 - 0.3 * _t / SPIN_S)
		return _shown(Vector3(at.x + cos(a) * rr, Sim.CUP_H + 0.01, at.z + sin(a) * rr), _flight_by)
	var i := mini(int(_t * PATH_RATE), _path.size() - 1)
	return _shown(_path[i], _flight_by)


# --- the frame -----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not visible or sim == null:
		return
	_clock += dt
	_t += dt
	match stage:
		Stage.AIM:
			if sim.turn == 1:
				stage = Stage.RIVAL
				_t = 0.0
			elif auto_play and _t > AUTO_AIM:
				_auto_throw()
		Stage.FLY:
			if _t * PATH_RATE >= _path.size() - 1:
				if bool(_result.get("rim", false)):
					stage = Stage.SPIN
					_t = 0.0
				else:
					_said()
		Stage.SPIN:
			if _t >= SPIN_S:
				_said()
		Stage.SAY:
			if _t >= SAY_S:
				if sim.winner >= 0:
					_end(sim.winner == 0)
				else:
					stage = Stage.AIM if sim.turn == 0 else Stage.RIVAL
					_t = 0.0
					_banner = Room.say("your_turn") if sim.turn == 0 else ""
		Stage.RIVAL:
			if _banner == "":
				var nm: Array = _rival.get("short", [rival_id, rival_id])
				_banner = Room.say("their_turn", [Lang.pick(str(nm[0]), str(nm[1]))])
			if _t >= RIVAL_WAIT:
				var r := sim.throw_rival()
				if not r.is_empty():
					_fly(r, 1)
					_log("rival: %s, cups %d:%d, drinks %d" % [r["result"], sim.cups[0].size(), sim.cups[1].size(), sim.drinks])
	queue_redraw()


## The throw has landed: the banner says what it did, the quip and the events after it.
func _said() -> void:
	stage = Stage.SAY
	_t = 0.0
	var ev: Array = _result.get("events", [])
	var first := str(ev[0]) if not ev.is_empty() else "miss"
	_banner = Room.say(first)
	if _flight_by == 1:
		_quip = _line_of("hit" if first in ["cup", "rim_in", "bounce"] else "miss")
	for e: String in ev:
		match e:
			"drink":
				_banner = Room.say("drink_up")
			"rerack":
				_banner += " · " + Room.say("rerack")
			"late":
				_quip = _line_of("late")
			"balls_back":
				_banner = Room.say("balls_back")


## A test run's throw: at a standing cup, a little off.
func _auto_throw() -> void:
	var c: Vector2 = sim.cups[1][sim.rng.randi() % sim.cups[1].size()]
	var a := Sim.aim_at(c)
	_throw(a.x + sim.rng.randfn(0.0, 0.06), a.y + sim.rng.randfn(0.0, 0.03))


func _end(won: bool) -> void:
	stage = Stage.OVER
	_pulling = false
	_banner = Room.say("won", [stake]) if won else Room.say("lost")
	_quip = _line_of("lose" if won else "win")
	if not _paid:
		_paid = true
		finished.emit(won, stake if won else 0, sim.drinks)
	_log("over: %s" % ("won" if won else "lost"))
	if auto_play:
		get_tree().create_timer(1.5).timeout.connect(_close)
	queue_redraw()


func _close() -> void:
	visible = false
	_pulling = false
	closed.emit()


func _log(text: String) -> void:
	if log_on:
		print("pong: " + text)
