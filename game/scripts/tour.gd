extends "res://scripts/activity.gd"
## A guided tour, the activity kit's first activity (tech-debt TD-1's pilot). A guest phones (or
## is met in person), the player picks them up and drives them round a list of stops. At each
## stop a card says what happens there; the last one ends the tour with the pay, after a question
## when the tour has one. On the way each leg asks for one optional shot (a way of driving), and
## every hit costs a little.
##
## The two tours are data, one file each (`load_data`):
##   - data/kino_tour.json: "Kino objazdowe" (docs/design/kino-tour.md; F's ask 2026-11-07).
##     Wiktor, a director friend, with the only 35 mm copy of his film; four cinemas from south
##     to north; a hit scratches one of the reel's five frames.
##   - data/dekalog_tour.json: "Dekalog na kółkach" (docs/design/dekalog-tour.md; F's ask
##     2026-11-07). Claire, a film student from Lyon; six places where the Dekalog was filmed,
##     ending on the Inflancka estate with her question; a hit costs her patience.
## Until the kit they were two scripts of 479 and 541 lines, the second a near copy of the first.
##
## A leg's shot, by its `kind`: `long` (so long at 5-40 km/h without a hit), `static` (standing
## still), `reverse` (metres in reverse), `fast` (seconds over 60 km/h), `tunnel` (through the
## tunnel in the data), and two judged on arrival: `quiet` (no hit on the leg) and `in_time`
## (there within so many seconds).
##
## Pay *guess*: base - a hit's price for each hit + a shot's bonus for each shot; the ✕ drops it.
## Cost: nothing per frame while idle but a timer; during the tour one beacon and a status line.

enum Stage { TO_PICKUP, LEG, STOP, ASK, DONE }

## The car counts as stopped in the ring below this speed, after HOLD s there.
const ARRIVE_KMH := StopAssist.STOP_SPEED * 3.6
const HOLD := 1.0
const BUMP_FREE := 3.0       # m/s: a softer touch costs nothing
const BUMP_WAIT := 1.2       # s between two counted hits
## Every kind of shot a tour's data may ask for (the header says what each is).
const KINDS := ["long", "static", "reverse", "fast", "tunnel", "quiet", "in_time"]
## The shots that fill while driving; the others are judged on arrival.
const FILLING := ["long", "static", "reverse", "fast", "tunnel"]

## The tour's data file, as read (`configure`).
var data: Dictionary = {}
var stops: Array = []
var shots: Dictionary = {}
var words: Dictionary = {}
var pay: Dictionary = {}

var stage := Stage.TO_PICKUP
## The next stop's index into `stops` while on a leg or at a stop.
var stop := 0
## Hits counted so far, never more than `bump_max`.
var bumps := 0
var bump_max := 0
var shots_done: Array[String] = []
## The answer picked at the last stop's question (-1: none, or the tour has no question).
var answer := -1
var _leg_t := 0.0
var _leg_hit := false
var _hold := 0.0
var _bump_wait := 0.0
var _banter := 20.0
var _banter_range := Vector2(16.0, 24.0)
var _shot_t := 0.0
var _last_pos := Vector3.INF
var _rng := RandomNumberGenerator.new()
var _result: Dictionary = {}


## The data of the tour `id` ("kino", "dekalog"): data/<id>_tour.json. {} when it can't be read.
static func load_data(id: String) -> Dictionary:
	var path := "res://data/%s_tour.json" % id
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("tour: %s is missing or is not a JSON object" % path)
		return {}
	return parsed


## A spot in the data ([x, z]) as a point on the map.
static func spot(v: Variant) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


## Takes the tour's data; before `setup`.
func configure(d: Dictionary) -> void:
	data = d
	tag = str(d.get("id", "tour"))
	colour = Color(str(d.get("colour", "#ffffff")))
	dark = Color(str(d.get("dark", "#000000")))
	var h: Array = d.get("hours", [0.0, 24.0])
	hours = Vector2(float(h[0]), float(h[1]))
	first_call = float(d.get("first_call", first_call))
	call_cool = float(d.get("call_cool", call_cool))
	play_limit = float(d.get("play_limit", 0.0))
	var b: Array = d.get("banter", [16.0, 24.0])
	_banter_range = Vector2(float(b[0]), float(b[1]))
	stops = d.get("stops", [])
	shots = d.get("shots", {})
	words = d.get("words", {})
	pay = d.get("pay", {})
	bump_max = int(d.get("bump_max", 0))


func setup(world: Node3D) -> void:
	super(world)
	_rng.randomize()
	if car != null and car.has_signal("bumped"):
		car.bumped.connect(on_bump)


func pickup_at() -> Vector2:
	return spot(data["pickup"]["at"])


func stop_at(i: int) -> Vector2:
	return spot(stops[i]["at"])


## The tour's name: [Polish, English].
func title() -> Array:
	return data.get("name", ["", ""])


func last_result() -> Dictionary:
	return _result


# --- the kit's hooks -----------------------------------------------------------------------------

func _call_card() -> Dictionary:
	return data.get("call", {})


func _offer_card() -> Dictionary:
	return data.get("offer", {})


func _met_words() -> String:
	return str(data["pickup"].get("met", "met in person"))


func _quit_words() -> Array:
	return words.get("quit", [])


func grounded() -> Array:
	return words.get("no_fly", []) if busy() else []


func _tick(dt: float) -> void:
	_bump_wait = maxf(0.0, _bump_wait - dt)


## The tour starts: to the pickup (or straight on when the car is there).
func _begin() -> void:
	stage = Stage.TO_PICKUP
	_hold = 0.0
	stop = 0
	bumps = 0
	answer = -1
	shots_done.clear()
	_result = {}
	set_target(pickup_at(), true)
	_toast(data["pickup"]["toast"])
	_log("to the pickup")


func _card_pressed(index: int) -> void:
	match stage:
		Stage.STOP:
			stop += 1
			_leg()
		Stage.ASK:
			_finale(clampi(index, 0, (data["answers"] as Array).size() - 1))
		Stage.DONE:
			finish()


# --- driving -------------------------------------------------------------------------------------

func _run_tick(dt: float) -> void:
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var kmh: float = v[1]
	var flying: bool = v[2]
	var at := pickup_at() if stage == Stage.TO_PICKUP else stop_at(stop)
	var d := Vector2(p.x, p.z).distance_to(at)
	if stage == Stage.LEG:
		_leg_t += dt
		_shot_tick(dt, p, kmh, float(v[3]) if v.size() > 3 else 0.0)
		_banter_tick(dt)
	_status(d)
	if not flying and d < arrive and kmh < ARRIVE_KMH:
		_hold += dt
		if _hold >= HOLD:
			_hold = 0.0
			if stage == Stage.TO_PICKUP:
				_picked_up()
			else:
				_arrive()
	else:
		_hold = 0.0
	_last_pos = p


func _picked_up() -> void:
	stage = Stage.LEG
	stop = 0
	_banter = 6.0
	_begin_leg()
	_say("hello", 4.5)
	_toast(data["pickup"]["in"])
	_aim()
	_log("picked up")


## On to the next stop.
func _leg() -> void:
	if stop >= stops.size():
		finish()
		return
	stage = Stage.LEG
	_t = 0.0
	_banter = 8.0
	_begin_leg()
	_aim()


func _begin_leg() -> void:
	_leg_t = 0.0
	_leg_hit = false
	_shot_t = 0.0


func _aim() -> void:
	set_target(stop_at(stop), false)
	var shot := _shot()
	if shot != "" and not shots_done.has(shot):
		_toast(shots[shot]["hint"])


## The shot the leg to `stop` asks for ("" for none).
func _shot() -> String:
	return str(stops[stop].get("shot", ""))


func _kind(shot: String) -> String:
	return str(shots[shot].get("kind", shot)) if shots.has(shot) else ""


func _need(shot: String) -> float:
	return float(shots[shot].get("need", 1.0))


## The status line: who waits at the pickup; on a leg the stop, the shot asked for and how far
## it is filled.
func _status(d: float) -> void:
	var hint: Array = _fill(data["pickup"]["status"], {"name": data["pickup"]["name"]})
	var progress := 0.0
	if stage == Stage.LEG:
		var s: Dictionary = stops[stop]
		var shot := _shot()
		var keys := {"name": s["name"], "episode": s.get("episode", ""), "tape": "%d/%d" % [bump_max - bumps, bump_max]}
		if shot == "":
			hint = _fill(words["status_leg"], keys)
		elif shots_done.has(shot):
			hint = _fill(words["status_got"], keys)
		else:
			var pl := keys.duplicate()
			var en := keys.duplicate()
			pl["shot"] = shots[shot]["hint"][0]
			en["shot"] = shots[shot]["hint"][1]
			hint = [str(words["status_shot"][0]).format(pl), str(words["status_shot"][1]).format(en)]
			match _kind(shot):
				"long", "static", "reverse", "fast":
					progress = clampf(_shot_t / _need(shot), 0.0, 1.0)
				"in_time":
					progress = clampf(1.0 - _leg_t / _need(shot), 0.0, 1.0)
	status(str(title()[0]), "%d/%d" % [mini(stop + (1 if stage == Stage.LEG else 0), stops.size()), stops.size()],
			"%d m" % roundi(d), hint, progress)


## The leg's shot: a timer or a distance that fills while the player drives the way asked.
## `quiet` and `in_time` are judged on arrival (`_arrive`).
func _shot_tick(dt: float, p: Vector3, kmh: float, forward: float) -> void:
	var shot := _shot()
	if shot == "" or shots_done.has(shot):
		return
	var kind := _kind(shot)
	match kind:
		"long":
			_shot_t = _shot_t + dt if kmh >= 5.0 and kmh <= 40.0 else 0.0
		"static":
			# Not at the stop itself: the point is to stop for the city.
			_shot_t = _shot_t + dt if kmh < 2.0 else 0.0
		"reverse":
			if forward < -0.8 and _last_pos != Vector3.INF:
				_shot_t += Vector2(p.x - _last_pos.x, p.z - _last_pos.z).length()
		"fast":
			_shot_t = _shot_t + dt if kmh > 60.0 else 0.0
		"tunnel":
			if in_tunnel(p):
				_shot_t = _need(shot)
	if kind in FILLING and _shot_t >= _need(shot):
		_got(shot)


## Inside the tour's tunnel (the data's `tunnel`: the line between its two portals, a width, a
## depth): near the line, away from the portals' ramps, below the street.
func in_tunnel(p: Vector3) -> bool:
	if not data.has("tunnel"):
		return false
	var line: Array = data["tunnel"]["line"]
	var a := spot(line[0])
	var b := spot(line[1])
	var q := Vector2(p.x, p.z)
	var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	if t < 0.2 or t > 0.8:
		return false
	if q.distance_to(a.lerp(b, t)) > float(data["tunnel"]["width"]):
		return false
	return p.y < _ground(q) - float(data["tunnel"]["deep"]) or map == null


func _got(shot: String) -> void:
	shots_done.append(shot)
	_shot_t = _need(shot)
	_toast(_fill(words["got"], {"pay": int(pay["shot"])}))
	_say("shot_" + shot, 4.0)
	Access.buzz(40, 0.4)
	_banter = maxf(_banter, 8.0)
	_log("shot %s done" % shot)


func _banter_tick(dt: float) -> void:
	_banter -= dt
	if _banter > 0.0:
		return
	_banter = _rng.randf_range(_banter_range.x, _banter_range.y)
	dialogue.say(car, str(data["speaker"]), str(data["lines"]), "", 5.0, colour, 2.4)


## A hit on the way (the car's `bumped`): one more against the pay, and the leg is no longer quiet.
func on_bump(_collider: Object, speed: float) -> void:
	if phase != Phase.RUN or stage != Stage.LEG or speed < BUMP_FREE or _bump_wait > 0.0:
		return
	_bump_wait = BUMP_WAIT
	_leg_hit = true
	if _kind(_shot()) == "long":
		_shot_t = 0.0
	if bumps >= bump_max:
		return
	bumps += 1
	Access.buzz(90, 0.9)
	if bumps == bump_max and words.has("bump_last"):
		_say(str(words.get("bump_last_tag", "bump")), 4.5)
		_toast(words["bump_last"])
	else:
		_say("bump", 3.5)
		_toast(_fill(words["bump"], {"left": bump_max - bumps, "max": bump_max, "cost": int(pay["bump"])}))
	_banter = maxf(_banter, 6.0)
	_log("bump: %d of %d" % [bumps, bump_max])


# --- the stops -----------------------------------------------------------------------------------

func _arrive() -> void:
	var s: Dictionary = stops[stop]
	var shot := _shot()
	if shot != "" and not shots_done.has(shot):
		var kind := _kind(shot)
		if kind == "quiet" and not _leg_hit:
			_got(shot)
		elif kind == "in_time" and _leg_t <= _need(shot):
			_got(shot)
	stage = Stage.STOP
	clear_target()
	hide_status()
	_log("stop at %s" % s["id"])
	if stop < stops.size() - 1:
		show_card(s["title"], s["body"], PackedStringArray([str(words["drive_on"])]))
	elif data.has("answers"):
		stage = Stage.ASK
		var buttons := PackedStringArray()
		for a: Dictionary in data["answers"]:
			buttons.append(str(a["button"]))
		show_card(s["title"], s["body"], buttons)
	else:
		_finale(-1)


## The last stop: the pay and the end card (after the answer `i` when the tour asks a question).
func _finale(i: int) -> void:
	stage = Stage.DONE
	answer = i
	var s: Dictionary = stops[stop]
	var amount := maxi(0, int(pay["base"]) - int(pay["bump"]) * bumps) + int(pay["shot"]) * shots_done.size()
	var respect := maxi(0, int(pay["respect"]) - int(pay["respect_bump"]) * bumps)
	if wallet != null:
		wallet.pay(amount, respect, str(data.get("pay_kind", tag)))
	var of: int = shots.size() if str(data.get("shots_of", "stops")) == "shots" else stops.size()
	var body: Array = []
	for lang in 2:
		var mark: Array = words.get("mark_bumped" if bumps > 0 else "mark_clean", ["", ""])
		var reply := str(data["answers"][i]["reply"][lang]) if i >= 0 else ""
		body.append(str(words["end"][lang]).format({"body": s["body"][lang], "reply": reply, "mark": mark[lang],
				"pay": amount, "respect": respect, "shots": shots_done.size(), "of": of}))
	show_card(s["title"], body, PackedStringArray([str(words["end_button"])]))
	_result = {"pay": amount, "respect": respect, "bumps": bumps, "shots": shots_done.size(), "answer": i, "time": _run_t}
	_log("done: %d zł, %d respect, %d hits, %d shots, answer %d, %.0f s" % [amount, respect, bumps, shots_done.size(), i, _run_t])


# --- words ---------------------------------------------------------------------------------------

## A [Polish, English] pair with its {keys} filled in.
func _fill(pair: Array, keys: Dictionary) -> Array:
	return [str(pair[0]).format(keys), str(pair[1]).format(keys)]


func _toast(pair: Array) -> void:
	hud.toast(str(pair[0]), str(pair[1]))


## The guest speaks a line of the tour's group with this tag, over what else is said.
func _say(line_tag: String, seconds: float) -> void:
	dialogue.say(car, str(data["speaker"]), str(data["lines"]), line_tag, seconds, colour, 2.4, true)
