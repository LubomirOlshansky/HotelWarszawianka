extends Node
## "Kino objazdowe" · the travelling cinema (docs/design/kino-tour.md; F's ask 2026-11-07: a
## director friend made an abstract arthouse film about Warsaw and asks you to drive him round the
## central cinemas to get it screened; on the way he jokes about niche cinema).
##
## Wiktor "Mgła" Pustelnik phones (14:00-23:00, once the player has driven a while, then every
## CALL_COOL s): ODBIERZ, then JADĘ puts a beacon on Plac Zbawiciela, where he waits with the only
## 35 mm copy of "Warszawa. Wjazd w pustkę" (3 h 40 min, one take, Rondo Dmowskiego as a pigeon
## sees it). Then four cinemas from south to north: Amondo (Żurawia), Atlantic (Chmielna), the
## Kinoteka in the Palace, Kino Muranów (Andersa). At each, stop in the ring: he goes in to pitch and
## a card gives the manager's answer and his comeback (three no's, one half-yes); Muranów says yes,
## the premiere is tonight.
##
## On the way: TAŚMA, the copy rides loose on the back seat, five frames; every hit scratches one
## (no fail: at none left it is "experimental cinema now"). Each leg he films one UJĘCIE through the
## window, an optional bonus: a long take (15 s at 5-40 km/h without a hit), a static shot (5 s
## standing still), reverse chronology (20 m in reverse) and the rush (4 s over 60 km/h). Between
## them, every BANTER s, a line about niche cinema (data/dialogue.json `kino_wiktor`, parody names
## only: Gaspar Nojé, Paolo Sorrentello, Béla Tartak, Lars von Tramwaj).
##
## Pay *guess*: PAY_BASE - PAY_FRAME a lost frame, + PAY_SHOT a shot, RESPECT; the ✕ drops it.
## Cost: nothing per frame while idle but a timer; during the tour one beacon and a status line.

const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

## Cinema red (Muranów's letters), not the jobs' orange, the rides' teal or the boat race's blue.
const COLOUR := Color("#e0453a")
const DARK := Color("#3a1f2a")
const NAME := "Kino objazdowe"
const NAME_EN := "The travelling cinema"
const SPEAKER := "Wiktor"
const FILM := "Warszawa. Wjazd w pustkę"
const FILM_EN := "Warsaw. Enter the Roundabout"

## The call: 14:00-23:00, after FIRST_CALL s of play, then every CALL_COOL s; the card's life.
const HOURS := [14.0, 23.0]
const FIRST_CALL := 480.0
const CALL_COOL := 1800.0
const CARD_LIFE := 12.0
## The whole tour gives up after this long (s) without finishing.
const PLAY_LIMIT := 2400.0
const ARRIVE := StopAssist.RING
const ARRIVE_KMH := StopAssist.STOP_SPEED * 3.6
const HOLD := 1.0
## The film copy and the hits that scratch it.
const FRAMES := 5
const BUMP_FREE := 3.0       # m/s: a softer touch leaves no scratch
const BUMP_WAIT := 1.2       # s between two scratches
## Banter: a line every BANTER s (a range) while driving with him.
const BANTER := Vector2(16.0, 24.0)
## Pay *guess*.
const PAY_BASE := 220
const PAY_FRAME := 20
const PAY_SHOT := 25
const RESPECT := 60
const RESPECT_FRAME := 8

## The pickup and the four cinemas: where the car stops (on the carriageway), the door, the name,
## the pitch card (title, the manager's answer, Wiktor's comeback; Polish and English) and the shot
## asked for on the leg that leads there (none for the pickup).
const PICKUP := {"at": Vector2(-416.4, 1594.7), "name": "Plac Zbawiciela"}
const STOPS := [
	{"id": "amondo", "at": Vector2(-550.7, 605.2), "name": "Kino Amondo", "street": "Żurawia",
		"shot": "long",
		"title": "AMONDO: „40 MIEJSC I JEDNA KANAPA”", "title_en": "AMONDO: \"40 SEATS AND ONE SOFA\"",
		"body": "Kierowniczka: „Kochany, mamy czterdzieści miejsc i jedną kanapę. Trzy godziny czterdzieści? Ludzie tu przychodzą na wino.”\nWiktor: „Wino też trwa. Tylko szybciej się kończy.” Odmowa.",
		"body_en": "The manager: \"Darling, we have forty seats and one sofa. Three hours forty? People come here for the wine.\"\nWiktor: \"Wine lasts too. It just ends sooner.\" A no."},
	{"id": "atlantic", "at": Vector2(-758.6, 334.2), "name": "Kino Atlantic", "street": "Chmielna",
		"shot": "static",
		"title": "ATLANTIC: „U NAS JEST FABUŁA”", "title_en": "ATLANTIC: \"WE SHOW STORIES\"",
		"body": "Pan z kasy: „Puszczamy filmy, w których coś się dzieje. Gdzie tu jest fabuła?”\nWiktor: „Fabuła to przemoc wobec obrazu.” Pan z kasy proponuje mu popcorn na pocieszenie. Odmowa.",
		"body_en": "The box office man: \"We show films where something happens. Where's the story?\"\nWiktor: \"Story is violence against the image.\" He's offered popcorn as comfort. A no."},
	{"id": "kinoteka", "at": Vector2(-1183.0, 331.0), "name": "Kinoteka", "street": "Pałac Kultury",
		"shot": "reverse",
		"title": "KINOTEKA: „ŚRODA, 3:00 W NOCY”", "title_en": "KINOTEKA: \"WEDNESDAY, 3 A.M.\"",
		"body": "Programista: „Mamy festiwal. Możemy cię wcisnąć w środę o trzeciej w nocy, sala 7, ta bez klimy.”\nWiktor: „Trzecia w nocy to jedyna uczciwa godzina dla kina.” Prawie tak. Jedziemy dalej.",
		"body_en": "The programmer: \"Festival week. We can squeeze you in on Wednesday at 3 a.m., screen 7, the one with no air con.\"\nWiktor: \"3 a.m. is the only honest hour for cinema.\" Almost a yes. Drive on."},
	{"id": "muranow", "at": Vector2(-1614.0, -1237.0), "name": "Kino Muranów", "street": "Andersa",
		"shot": "rush",
		"title": "MURANÓW: „PUSZCZAMY DZIŚ!”", "title_en": "MURANÓW: \"WE SCREEN IT TONIGHT!\"",
		"body": "Kierowniczka pod fontanną: „Trzy czterdzieści, jeden ujęcie, gołąb? Biorę. Dziś o 21:00, po pokazie rozmowa z twórcą.”\nWiktor płacze w szalik. Pod girlandami już stoi kolejka w beretach.",
		"body_en": "The manager by the fountain: \"Three forty, one take, a pigeon? I'm in. Tonight at 9 p.m., a Q&A after.\"\nWiktor cries into his scarf. Under the festoons a queue in berets is already forming."},
]
## The shots he asks for: the status line's hint and how much of it is needed.
const SHOTS := {
	"long": ["Ujęcie: długie, 15 s przy 5-40 km/h", "Shot: a long take, 15 s at 5-40 km/h", 15.0],
	"static": ["Ujęcie: statyczne, stój 5 s", "Shot: a static one, stand still 5 s", 5.0],
	"reverse": ["Ujęcie: na wstecznym 20 m", "Shot: 20 m in reverse", 20.0],
	"rush": ["Ujęcie: pęd, 4 s ponad 60 km/h", "Shot: the rush, 4 s over 60 km/h", 4.0],
}

enum State { IDLE, RING, OFFER, TO_PICKUP, LEG, PITCH, DONE }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var map: Node3D
var car: Node3D
var log_on := false
var autopilot := false
## Nothing else on, on the ground (main.gd).
var free_now: Callable = func() -> bool: return true
## [position, speed km/h, flying, forward speed m/s].
var vehicle: Callable
var clock: Callable = func() -> float: return 12.0
## Testing aids: calls at any hour.
var force_hours := false

var state := State.IDLE
## The next stop's index into STOPS while on a leg or pitching.
var stop := 0
var frames := FRAMES
var shots_done: Array[String] = []
var _t := 0.0
var _session := 0.0
var _tour_t := 0.0
var _next_call := FIRST_CALL
var _hold := 0.0
var _bump_wait := 0.0
var _banter := 20.0
var _shot_t := 0.0
var _last_pos := Vector3.INF
var _beacon: Node3D
var _rng := RandomNumberGenerator.new()
var _result: Dictionary = {}


func setup(world: Node3D) -> void:
	_rng.randomize()
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, DARK)
	_beacon.visible = false
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func() -> void:
		if state in [State.TO_PICKUP, State.LEG]:
			_quit(true))
	if car != null and car.has_signal("bumped"):
		car.bumped.connect(on_bump)


func busy() -> bool:
	return state != State.IDLE and state != State.RING


## Idle: not ringing, not touring (the questline may start now: story_quests.gd).
func idle() -> bool:
	return state == State.IDLE


## Met in person on Plac Zbawiciela (the quest map's start, story_quests.gd): the tour starts, and
## Wiktor gets in as soon as the car stands by him.
func meet() -> bool:
	if state != State.IDLE:
		return false
	_log("met Wiktor on Plac Zbawiciela")
	start()
	return true


func has_target() -> bool:
	return state == State.TO_PICKUP or state == State.LEG


func target_position() -> Vector3:
	var at: Vector2 = PICKUP["at"] if state == State.TO_PICKUP else STOPS[stop]["at"]
	return Vector3(at.x, _ground(at), at.y)


func target_colour() -> Color:
	return COLOUR


## The stop assist's spot (main.gd `_stop_assist`): the ring the car glides into.
func stop_spot() -> Vector3:
	return target_position()


func last_result() -> Dictionary:
	return _result


func _ground(at: Vector2) -> float:
	return map.ground_height(at.x, at.y) if map != null else 0.0


func _process(dt: float) -> void:
	_t += dt
	_session += dt
	_bump_wait = maxf(0.0, _bump_wait - dt)
	match state:
		State.IDLE:
			_idle_tick()
		State.RING, State.OFFER:
			if _t > CARD_LIFE:
				hud.hide_card()
				_reset(CALL_COOL * 0.5)
			elif autopilot and _t > 1.5:
				_on_card(0)
		State.TO_PICKUP, State.LEG:
			_tour_t += dt
			_drive_tick(dt)
		State.PITCH, State.DONE:
			if autopilot and _t > 2.5:
				_on_card(0)


func _idle_tick() -> void:
	if _session < _next_call or int(_session * 2.0) == int((_session - get_process_delta_time()) * 2.0):
		return
	if vehicle.is_valid() and bool(vehicle.call()[2]):
		return
	var h: float = clock.call()
	if not force_hours and (h < HOURS[0] or h >= HOURS[1]):
		return
	if not free_now.call():
		return
	ring()


# --- the call --------------------------------------------------------------------------------------

## Wiktor phones.
func ring() -> bool:
	if state != State.IDLE:
		return false
	state = State.RING
	_t = 0.0
	hud.show_side_card("📞 WIKTOR DZWONI", "Kumpel reżyser. Beret, szalik w upał i jedyna kopia swojego filmu na 35 mm.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "Wiktor is calling",
			"Your director friend. A beret, a scarf in the heat and the only 35 mm copy of his film.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


func _offer() -> void:
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("WIKTOR: „ZAWIEZIESZ MNIE?”",
			"„Skończyłem! „%s”: trzy czterdzieści, jedno ujęcie, rondo oczami gołębia. Objedziemy kina, Amondo, Atlantic, Kinotekę, Muranów. Ktoś to musi puścić. Czekam na Zbawiciela.”" % FILM,
			PackedStringArray(["JADĘ|ON MY WAY", "NIE DZIŚ|NOT TODAY"]), COLOUR, "Wiktor: \"Will you drive me?\"",
			"\"It's done! '%s': three forty, one take, the roundabout as a pigeon sees it. We do the cinemas, Amondo, Atlantic, Kinoteka, Muranów. Somebody has to screen it. I'm on Plac Zbawiciela.\"" % FILM_EN)


func _on_card(i: int) -> void:
	match state:
		State.RING:
			hud.hide_card()
			if i == 0:
				_offer()
			else:
				_reset(CALL_COOL)
		State.OFFER:
			hud.hide_card()
			if i == 0:
				start()
			else:
				_reset(CALL_COOL)
		State.PITCH:
			hud.hide_card()
			stop += 1
			_leg()
		State.DONE:
			hud.hide_card()
			_reset(CALL_COOL)


## The tour starts: to Plac Zbawiciela for Wiktor (or straight on when the car is there).
func start() -> void:
	state = State.TO_PICKUP
	_t = 0.0
	_tour_t = 0.0
	_hold = 0.0
	stop = 0
	frames = FRAMES
	shots_done.clear()
	_result = {}
	var at: Vector2 = PICKUP["at"]
	_beacon.visible = true
	_beacon.place(Vector3(at.x, _ground(at), at.y), ARRIVE - 0.5, true, true)
	hud.toast("Po Wiktora na plac Zbawiciela", "Pick Wiktor up on Plac Zbawiciela")
	_log("to the pickup")


# --- driving -----------------------------------------------------------------------------------------

func _drive_tick(dt: float) -> void:
	if _tour_t > PLAY_LIMIT:
		_quit(false)
		return
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var kmh: float = v[1]
	var flying: bool = v[2]
	var at: Vector2 = PICKUP["at"] if state == State.TO_PICKUP else STOPS[stop]["at"]
	var d := Vector2(p.x, p.z).distance_to(at)
	if state == State.LEG:
		_shot_tick(dt, p, kmh, float(v[3]) if v.size() > 3 else 0.0)
		_banter_tick(dt)
	_status(d)
	if not flying and d < ARRIVE and kmh < ARRIVE_KMH:
		_hold += dt
		if _hold >= HOLD:
			_hold = 0.0
			if state == State.TO_PICKUP:
				_picked_up()
			else:
				_pitch()
	else:
		_hold = 0.0
	_last_pos = p


func _picked_up() -> void:
	state = State.LEG
	stop = 0
	_banter = 6.0
	_shot_t = 0.0
	dialogue.say(car, SPEAKER, "kino_wiktor", "hello", 4.5, COLOUR, 2.4, true)
	hud.toast("Wiktor wsiada z puszką filmu. Taśma na tylnym siedzeniu: jedź gładko", "Wiktor gets in with the film can. The reel's on the back seat: drive smooth")
	_aim()
	_log("picked up")


## On to the next stop (or the end after the last).
func _leg() -> void:
	if stop >= STOPS.size():
		_reset(CALL_COOL)
		return
	state = State.LEG
	_t = 0.0
	_shot_t = 0.0
	_banter = 8.0
	_aim()


func _aim() -> void:
	var at: Vector2 = STOPS[stop]["at"]
	_beacon.visible = true
	_beacon.place(Vector3(at.x, _ground(at), at.y), ARRIVE - 0.5, true, false)
	var shot: String = STOPS[stop]["shot"]
	if shot != "" and not shots_done.has(shot):
		hud.toast(String(SHOTS[shot][0]), String(SHOTS[shot][1]))


func _status(d: float) -> void:
	var tape := "%d/%d" % [frames, FRAMES]
	var hint := "Wiktor czeka z filmem: %s" % PICKUP["name"]
	var hint_en := "Wiktor waits with the film: %s" % PICKUP["name"]
	var progress := 0.0
	if state == State.LEG:
		var shot: String = STOPS[stop]["shot"]
		if shots_done.has(shot):
			hint = "Ujęcie jest! Taśma %s" % tape
			hint_en = "Got the shot! Reel %s" % tape
		else:
			hint = "%s · Taśma %s" % [SHOTS[shot][0], tape]
			hint_en = "%s · Reel %s" % [SHOTS[shot][1], tape]
			progress = clampf(_shot_t / float(SHOTS[shot][2]), 0.0, 1.0)
	if state == State.LEG:
		hint = "%s · %s" % [STOPS[stop]["name"], hint]
		hint_en = "%s · %s" % [STOPS[stop]["name"], hint_en]
	hud.show_status(NAME, "%d/%d" % [mini(stop + (1 if state == State.LEG else 0), STOPS.size()), STOPS.size()], "%d m" % roundi(d),
			hint, progress, COLOUR, "", {}, hint_en)


## The leg's shot: a timer or a distance that fills while the player drives the way he asks.
func _shot_tick(dt: float, p: Vector3, kmh: float, forward: float) -> void:
	var shot: String = STOPS[stop]["shot"]
	if shot == "" or shots_done.has(shot):
		return
	var need: float = SHOTS[shot][2]
	match shot:
		"long":
			_shot_t = _shot_t + dt if kmh >= 5.0 and kmh <= 40.0 else 0.0
		"static":
			# Not at the stop itself: the point is to stop for the city.
			_shot_t = _shot_t + dt if kmh < 2.0 else 0.0
		"reverse":
			if forward < -0.8 and _last_pos != Vector3.INF:
				_shot_t += Vector2(p.x - _last_pos.x, p.z - _last_pos.z).length()
		"rush":
			_shot_t = _shot_t + dt if kmh > 60.0 else 0.0
	if _shot_t >= need:
		shots_done.append(shot)
		_shot_t = need
		hud.toast("CIĘCIE! Mamy to ujęcie (+%d zł na końcu)" % PAY_SHOT, "CUT! That's the shot (+%d zł at the end)" % PAY_SHOT)
		dialogue.say(car, SPEAKER, "kino_wiktor", "shot_" + shot, 4.0, COLOUR, 2.4, true)
		Access.buzz(40, 0.4)
		_banter = maxf(_banter, 8.0)
		_log("shot %s done" % shot)


func _banter_tick(dt: float) -> void:
	_banter -= dt
	if _banter > 0.0:
		return
	_banter = _rng.randf_range(BANTER.x, BANTER.y)
	dialogue.say(car, SPEAKER, "kino_wiktor", "", 5.0, COLOUR, 2.4)


## A hit on the way: a scratch on the reel (main.gd wires car.bumped here).
func on_bump(_collider: Object, speed: float) -> void:
	if state != State.LEG or speed < BUMP_FREE or _bump_wait > 0.0:
		return
	_bump_wait = BUMP_WAIT
	if STOPS[stop]["shot"] == "long":
		_shot_t = 0.0
	if frames <= 0:
		return
	frames -= 1
	Access.buzz(90, 0.9)
	if frames == 0:
		dialogue.say(car, SPEAKER, "kino_wiktor", "ruined", 4.5, COLOUR, 2.4, true)
		hud.toast("Taśma: ostatnia klatka porysowana. „Teraz to kino eksperymentalne”", "The reel: the last frame scratched. \"Now it's experimental cinema\"")
	else:
		dialogue.say(car, SPEAKER, "kino_wiktor", "bump", 3.5, COLOUR, 2.4, true)
		hud.toast("Rysa na taśmie! Zostało %d z %d klatek" % [frames, FRAMES], "A scratch on the reel! %d of %d frames left" % [frames, FRAMES])
	_banter = maxf(_banter, 6.0)
	_log("bump: %d frames left" % frames)


# --- the cinemas -----------------------------------------------------------------------------------

func _pitch() -> void:
	var s: Dictionary = STOPS[stop]
	state = State.PITCH
	_t = 0.0
	_beacon.visible = false
	hud.hide_status()
	_log("pitch at %s" % s["id"])
	if stop == STOPS.size() - 1:
		_premiere()
		return
	hud.show_card(String(s["title"]), String(s["body"]), PackedStringArray(["JEDZIEMY DALEJ|DRIVE ON"]), COLOUR, false,
			String(s["title_en"]), String(s["body_en"]))


## Muranów says yes: the premiere tonight, the pay.
func _premiere() -> void:
	state = State.DONE
	var s: Dictionary = STOPS[stop]
	var lost := FRAMES - frames
	var pay := maxi(0, PAY_BASE - PAY_FRAME * lost) + PAY_SHOT * shots_done.size()
	var respect := maxi(0, RESPECT - RESPECT_FRAME * lost)
	if wallet != null:
		wallet.pay(pay, respect, "kino_tour")
	var scratches := "Rysy na taśmie? „Zamierzone.”" if lost > 0 else "Taśma czysta jak sumienie debiutanta."
	var scratches_en := "Scratches on the reel? \"Intended.\"" if lost > 0 else "The reel is as clean as a debut's conscience."
	hud.show_card(String(s["title"]), "%s\n%s  +%d zł  +%d szacunu · ujęcia %d/%d" % [s["body"], scratches, pay, respect, shots_done.size(), STOPS.size()],
			PackedStringArray(["BRAWO!|BRAVO!"]), COLOUR, false, String(s["title_en"]),
			"%s\n%s  +%d zł  +%d respect · shots %d/%d" % [s["body_en"], scratches_en, pay, respect, shots_done.size(), STOPS.size()])
	_result = {"pay": pay, "respect": respect, "frames": frames, "shots": shots_done.size(), "time": _tour_t}
	_log("premiere: %d zł, %d respect, %d frames, %d shots, %.0f s" % [pay, respect, frames, shots_done.size(), _tour_t])


func _quit(by_player: bool) -> void:
	hud.hide_status()
	hud.hide_card()
	_beacon.visible = false
	if by_player:
		hud.toast("Wiktor wysiada: „Kino nie lubi pośpiechu.”", "Wiktor gets out: \"Cinema doesn't like a rush.\"")
	_reset(CALL_COOL)
	_log("quit")


func _reset(cool: float) -> void:
	state = State.IDLE
	_t = 0.0
	_beacon.visible = false
	_next_call = _session + cool


func _log(msg: String) -> void:
	if log_on:
		print("kino: " + msg)
