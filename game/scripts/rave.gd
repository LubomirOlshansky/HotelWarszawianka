extends Node3D
## Sekretny rave (F's ask 2026-11-06, docs/design/secret-rave.md): Warsaw's secret techno raves.
##
## **The rig.** On rave nights (Thursday to Saturday, 22:00-06:00, the game clock) one of three
## night spots has a rave: under the Poniatowski viaduct by the boulevard, in an old depot past
## the tracks in Praga, in a hall by the railway towards Ochota (SPOTS; one per weekend, the next
## after each rave the player gets into). It is a DJ booth with speaker stacks and a truss, a
## crowd of dancers bobbing on the beat, and the lights: six moving beams into the sky, a laser
## fan over the crowd and a strobe cone (one MultiMesh in the city's additive glow material, so
## only the lit look shows it). By day, Friday to Sunday 12:00-20:00, the day spot on the Praga
## beach has a day rave: the booth and a crowd in colour, no lights. A techno thump (city
## sounds' `thump`) plays by the active spot; the crowd talks (`rave_crowd`, tags night/day).
##
## **The quest.** On a rave night with nothing else on, the pirate host LEKTI breaks into MORDOR
## FM (`rave_lekti`: the invite and the night's password, PASSWORDS); on another station the
## regular host only passes on the rumour (`rave_rumour`). A minute later Ziomek calls (ZIOMEK
## DZWONI, ODBIERZ / ODRZUĆ, then JADĘ! / NIE DZIŚ): pick him up at his block (the dashed
## pickup ring, 400-900 m away); he tunes the radio to MORDOR FM and leads you to a meeting point
## (the arrow says "???": he knows only that much), where a hooded man gives the spot
## (`rave_meet`); drive there and stop at the door: the bouncer asks three questions (QUESTIONS;
## at a secret rave one is the password LEKTI said), three right answers get you both in, the
## first wrong one gets "Nie tym razem. Wróć później." Ziomek's lines: `rave_ziomek` (tags board,
## board_smola, ride, meet, go, go_smola, door_ok, door_out, abort). ✕ gives up (Ziomek takes the night bus). The calls (missions.gd) are paused
## while it runs.
##
## Cost: idle, a 0.25 s timer; while a spot is active and near, four draw calls (the lights'
## MultiMesh, the dancers' MultiMesh, the booth, the DJ's strip is in the booth), the lights
## moved every frame (14 instances), the dancers at 15 Hz within DANCE_R.
##
## Flags (main.gd): --rave-call (LEKTI speaks and Ziomek rings at once), --rave=on (the night
## spot's rave on at any hour), --rave=day (the day rave on at any hour), --rave-spot=ID (which
## night spot), --rave=0 (none of it), --rave-log.

const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const Notebook := preload("res://scripts/notebook.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const HOST := "LEKTI"
const FRIEND := "Ziomek"
const COLOUR := Color("#b44cff")        ## the quest's colour: rave violet
const PICK_COLOUR := Color("#ffc23a")   ## Ziomek waiting (the rides' amber)
const BUBBLE := Color("#c58cff")

## The rave spots: [lat, lon] of the floor's middle; `where` finishes "Dziś gramy ..." / "Tonight
## we play ...". The last one is the day rave's.
const SPOTS := [
	{"id": "wiadukt", "name": "Pod wiaduktem", "ll": [52.2343, 21.0388], "night": true,
			"where": ["pod wiaduktem Poniatowskiego", "under the Poniatowski viaduct"]},
	{"id": "zajezdnia", "name": "Zajezdnia za torami", "ll": [52.2522, 21.0420], "night": true,
			"where": ["w starej zajezdni za torami na Pradze", "in the old depot past the tracks in Praga"]},
	{"id": "hala", "name": "Hala przy torach", "ll": [52.2265, 20.9935], "night": true,
			"where": ["w hali przy torach na Ochocie", "in the hall by the tracks towards Ochota"]},
	{"id": "plaza", "name": "Rave na plaży", "ll": [52.2378, 21.0437], "night": false,
			"where": ["na plaży po praskiej stronie", "on the Praga-side beach"]},
]
## Ziomek's block (story_quests.gd's start spot, F 2026-11-07): Osiedle Za Żelazną Bramą, the
## big slab blocks by Hala Mirowska; drive there in the evening and he comes out to talk.
const HOME_LL := [52.2366, 20.9983]
## Smoła, the club on Smolna (places.json `smola`): Ziomek's other night out, the Berlin-style door.
const SMOLA := {"id": "smola", "name": "Smoła", "ll": [52.2333, 21.0268]}
## The door's questions (three a night, shuffled; "pw" is the password LEKTI gave, asked only at a
## secret rave): [question], the right answer, two wrong ones; each [Polish, English].
const QUESTIONS := [
	{"id": "who", "q": ["Kto dziś gra?", "Who's playing tonight?"], "right": ["Nie wiem. Przyszedłem tańczyć.", "No idea. I came to dance."],
			"wrong": [["Ten, co ma milion obserwujących", "The one with a million followers"], ["Chwila, sprawdzę w telefonie", "Hang on, I'll check my phone"]]},
	{"id": "how_many", "q": ["Ilu was jest?", "How many of you?"], "right": ["Dwóch.", "Two."],
			"wrong": [["Sześciu, reszta parkuje", "Six, the rest are parking"], ["Dwóch plus wieczór kawalerski", "Two plus a stag do"]]},
	{"id": "before", "q": ["Byłeś tu kiedyś?", "Been here before?"], "right": ["Raz. Nie pamiętam wyjścia.", "Once. Don't remember leaving."],
			"wrong": [["Nie, ale widziałem rolkę", "No, but I saw a reel"], ["W Berlinie. To prawie to samo", "In Berlin. Same thing, really"]]},
	{"id": "phone", "q": ["Co robisz w środku z telefonem?", "What do you do with your phone inside?"], "right": ["Nic. Aparat pod naklejką.", "Nothing. Camera under a sticker."],
			"wrong": [["Relację na żywo!", "A live story!"], ["Zdjęcia DJ-a, dla mamy", "Photos of the DJ, for my mum"]]},
	{"id": "drink", "q": ["Co pijesz?", "What are you drinking?"], "right": ["Wodę.", "Water."],
			"wrong": [["Sześć szotów na start", "Six shots to start"], ["A co mi postawisz?", "What are you buying?"]]},
	{"id": "till", "q": ["Do której zostajesz?", "How long are you staying?"], "right": ["Do końca. Albo do poniedziałku.", "Till the end. Or till Monday."],
			"wrong": [["Do dwunastej, jutro wcześnie wstaję", "Till midnight, early start tomorrow"], ["Aż mi się znudzi", "Until I get bored"]]},
	{"id": "smile", "q": ["Czemu się uśmiechasz?", "Why are you smiling?"], "right": ["Bo słyszę bas.", "Because I can hear the bass."],
			"wrong": [["Kolega mówił, że tak trzeba", "My mate said I should"], ["Ćwiczyłem przed lustrem", "I practised in the mirror"]]},
	{"id": "kind", "q": ["Jakie techno lubisz?", "What kind of techno do you like?"], "right": ["Takie, którego nie umiem nazwać.", "The kind I can't put a name to."],
			"wrong": [["Wszystko, co leci w radiu", "Whatever's on the radio"], ["Techno to jest ten house, tak?", "Techno's the same as house, right?"]]},
]
## Right answers that let you in: all three. The first wrong one ends it: "Nie tym razem. Wróć
## później." (F, 2026-11-06).
const DOOR_PASS := 3
## The night's password: one of these, in LEKTI's line and on the door's card.
const PASSWORDS := ["BETON", "SYRENA", "MGŁA", "TRAMWAJ ZERO", "PRAGA 97", "BAS", "NEON", "PERON"]

## Rave nights: the night's day (crowds.gd night_day) Thursday to Saturday, these hours.
const NIGHT_HOURS := Vector2(22.0, 6.0)
const NIGHT_DAYS := [4, 5, 6]
## LEKTI's window: from the evening to the small hours of a rave night.
const TEASE_HOURS := Vector2(19.0, 4.0)
## The day rave: Friday to Sunday afternoons (the fixed looks are "always Friday").
const DAY_HOURS := Vector2(12.0, 20.0)
const DAY_DAYS := [5, 6, 7]

## LEKTI: free-play seconds before his first line, then after a declined or finished night.
const FIRST_TEASE := Vector2(150.0, 300.0)
const NEXT_TEASE := Vector2(900.0, 1500.0)
## Ziomek rings this long after LEKTI; the ringing card waits RING_LIFE s.
const CALL_AFTER := Vector2(30.0, 75.0)
const RING_LIFE := 25.0
## Where Ziomek waits: a ground road this far from the player.
const PICK_FROM := 400.0
const PICK_TO := 900.0
## The meeting point: this far from the rave, on the player's side of it.
const MEET_FROM := 350.0
const MEET_TO := 650.0
## Stopping: within these metres of the ring, under STOP_KMH, for HOLD s.
const PICK_R := 7.0
const MEET_R := 9.0
const DOOR_R := 12.0
const STOP_KMH := 9.0
const HOLD := 0.8
## Ziomek talks every TALK_GAP s in the car.
const TALK_GAP := Vector2(9.0, 13.0)
## Pay: Ziomek's share of the fare and respect (half the fare when the door says no).
const PAY := 150
const RESPECT := 40
## The ticket inside (F, 2026-11-06: "to enter you have to pay cash"): cash only, at the door.
const ENTRY := 50
## The door waits this long for an answer, then turns you away (never a quest stuck at the door).
const DOOR_LIFE := 90.0
const RESULT_LIFE := 12.0

## The rig: drawn within RIG_FAR m of the view's focus (the beams show over the skyline), the
## dancers move within DANCE_R m, the crowd talks within TALK_R m, the toast within NOTICE_R m.
const RIG_FAR := 1400.0
const DANCE_R := 260.0
const TALK_R := 70.0
const NOTICE_R := 220.0
const CROWD_GAP := Vector2(14.0, 22.0)
const BPM := 132.0
const BEAMS := 6
const LASERS := 8
const DANCERS := 46
## LEKTI's voice clips (lekti_<n>.ogg per rave_lekti line, pw_<word>.ogg per password), their
## level on the SFX bus and the pause between the line and the password.
const VOICE_DIR := "res://audio/rave/"
const VOICE_DB := -2.0
const VOICE_GAP := 0.35
const BEAM_LEN := 70.0
const LASER_LEN := 34.0
## The floor in front of the booth: dancers within this radius of the spot's middle.
const FLOOR_R := 9.0
const TICK := 0.25

enum State { IDLE, WAIT_CALL, RING, OFFER, PICKUP, MEET, DRIVE, DOOR, RESULT }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var missions: Node
var map: Node3D
var graph: LaneGraph
var radio: Node
var city_sounds: Node
## [position, km/h, flying] of the player's vehicle.
var vehicle: Callable
## The view's focus (the rig is drawn near it).
var focus: Callable
## {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## True when nothing else is on (main.gd).
var free_now: Callable
## Into the club's room (main.gd `_enter_club`: club.gd), with its title [pl, en].
var enter_club: Callable
var log_on := false
## The quest's timers run (off in test runs but for the flags).
var auto := true
## --rave=on / --rave=day: that rave on at any hour.
var force := ""
var origin := [52.234, 21.024]

var state := State.IDLE
var tease_in := 0.0
var call_in := 0.0
## The spots found on the map: SPOTS' keys plus at: Vector3 (the floor), door: {at: Vector3 (on
## the road), e, s}, face: the booth's yaw (its back to the door's road, the floor beyond it).
var spots: Array[Dictionary] = []
## The night spot this weekend (index into spots), the day spot.
var night_spot := 0
var day_spot := -1
## The spot drawn now (-1 none) and how ("night" / "day").
var active := -1
var active_mode := ""
## The quest: password, heard (LEKTI's line on air), quest spot, pickup, meet.
var password := ""
var heard := false
var quest_spot := -1
var pickup := {}
var meet := {}
## "rave" (after LEKTI, the secret spot) or "smola" (the club); the next call's kind.
var kind := ""
var next_kind := "smola"
## Ziomek's block on the map: a kerb ({at, side, street...}), or {}.
var home := {}
## Smoła found on the map: {at: Vector3, door: kerb}, or {}.
var smola := {}
## The door: the three questions ([q, answers: [[pl, en]] ×3, right index]), the one asked now
## and how many were right.
var quiz: Array = []
var quiz_i := 0
var quiz_right := 0
var rejected := 0
var raves := 0
var last_pay := {}

var _rng := RandomNumberGenerator.new()
var _tick := 0.0
var _clock := 0.0
var _hold_t := 0.0
var _ring_t := 0.0
var _talk_t := 0.0
var _result_t := 0.0
var _door_t := 0.0
var _crowd_t := 0.0
var _dance_t := 0.0
var _noticed := false
var _calls_were := false
var _mordor := -1

var _rig: Node3D
var _lights: MultiMeshInstance3D
var _dancers: MultiMeshInstance3D
var _booth: MeshInstance3D
var _pick: Node3D
var _meet_mark: Node3D
var _floor: Array[Vector3] = []
var spent_usec := 0
var _voice: AudioStreamPlayer
var _voice_queue: Array[AudioStream] = []


func setup(world: Node3D, seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	tease_in = _rng.randf_range(FIRST_TEASE.x, FIRST_TEASE.y)
	if graph != null:
		spots = find_spots(graph, map, origin)
	for i in spots.size():
		if not bool(spots[i]["night"]):
			day_spot = i
	if graph != null:
		smola = find_club(graph, map, origin)
		home = kerb_near(graph, Notebook.project(origin, float(HOME_LL[0]), float(HOME_LL[1])), 120.0)
	var nights := night_spots()
	if not nights.is_empty():
		night_spot = nights[_rng.randi() % nights.size()]
	if radio != null and radio.has_method("station_index"):
		_mordor = radio.station_index("mordor_fm")
	_build_rig(world)
	_pick = Beacon.new()
	world.add_child(_pick)
	_pick.setup(PICK_COLOUR, Color("#16161a"))
	_pick.pattern = Beacon.Pattern.DASHED
	_pick.visible = false
	_meet_mark = Beacon.new()
	world.add_child(_meet_mark)
	_meet_mark.setup(COLOUR, Color("#26232c"))
	_meet_mark.waving = false
	_meet_mark.visible = false
	if hud != null:
		hud.card_pressed.connect(_on_card)
		hud.abort_pressed.connect(func() -> void:
			if state in [State.PICKUP, State.MEET, State.DRIVE]:
				_give_up())
	if city_sounds != null:
		for i in spots.size():
			var k := i
			city_sounds.add_crowd("rave_" + String(spots[i]["id"]), "thump", spots[i]["at"],
					func() -> bool: return active == k)
	var names := PackedStringArray()
	for s in spots:
		names.append("%s %d,%d" % [s["id"], roundi(s["at"].x), roundi(s["at"].z)])
	_log("%d spots (%s); this weekend %s; LEKTI in %.0f s" % [spots.size(), ", ".join(names),
			spots[night_spot]["id"] if not spots.is_empty() else "-", tease_in])


# --- the rules (static: check_rave.gd runs them) -------------------------------------------------

## The weekday whose night `hour` belongs to (01:00 Saturday is Friday's night).
static func night_day(hour: float, weekday: int) -> int:
	return (weekday + 5) % 7 + 1 if hour < 12.0 else weekday


## Within hours [from, to) that may wrap past midnight.
static func in_hours(hour: float, h: Vector2) -> bool:
	return (hour >= h.x and hour < h.y) if h.x < h.y else (hour >= h.x or hour < h.y)


## A night rave is on at this time.
static func night_on(hour: float, weekday: int) -> bool:
	return in_hours(hour, NIGHT_HOURS) and night_day(hour, weekday) in NIGHT_DAYS


## LEKTI may invite now.
static func tease_on(hour: float, weekday: int) -> bool:
	return in_hours(hour, TEASE_HOURS) and night_day(hour, weekday) in NIGHT_DAYS


## The day rave is on at this time.
static func day_on(hour: float, weekday: int) -> bool:
	return in_hours(hour, DAY_HOURS) and weekday in DAY_DAYS


## The door's three words: the password and two others, shuffled.
static func door_choices(pw: String, rng: RandomNumberGenerator) -> PackedStringArray:
	var others: Array = PASSWORDS.filter(func(p: String) -> bool: return p != pw)
	var out: Array = [pw]
	while out.size() < 3 and not others.is_empty():
		out.append(others.pop_at(rng.randi() % others.size()))
	for k in range(out.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t = out[k]
		out[k] = out[j]
		out[j] = t
	return PackedStringArray(out)


## The door's pay: [złoty, respect], in or turned away.
static func pay_for(inside: bool) -> Array:
	return [PAY, RESPECT] if inside else [PAY / 2, 0]


## The door's three questions for the night: at a secret rave the password and two others, at
## Smoła three of the rest; each [question [pl, en], answers [[pl, en] ×3] shuffled, right index].
static func door_quiz(pw: String, rng: RandomNumberGenerator) -> Array:
	var pool: Array = QUESTIONS.duplicate()
	var picked: Array = []
	if pw != "":
		var words := door_choices(pw, rng)
		var answers: Array = []
		for w in words:
			answers.append([w, w])
		picked.append([["Hasło?", "Password?"], answers, words.find(pw)])
	while picked.size() < 3 and not pool.is_empty():
		var q: Dictionary = pool.pop_at(rng.randi() % pool.size())
		var answers: Array = [q["right"], q["wrong"][0], q["wrong"][1]]
		for k in range(2, 0, -1):
			var j := rng.randi() % (k + 1)
			var t = answers[k]
			answers[k] = answers[j]
			answers[j] = t
		picked.append([q["q"], answers, answers.find(q["right"])])
	for k in range(picked.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t = picked[k]
		picked[k] = picked[j]
		picked[j] = t
	return picked


## How the door ends with `right` answers: "in" with all three, else "out".
static func door_result(right: int) -> String:
	return "in" if right >= DOOR_PASS else "out"


## Smoła on this map: its door the nearest ground road within 120 m, or {}.
static func find_club(g: LaneGraph, m: Node3D, org: Array) -> Dictionary:
	var ll: Array = SMOLA["ll"]
	var at := Notebook.project(org, float(ll[0]), float(ll[1]))
	var door := kerb_near(g, at, 120.0)
	if door.is_empty():
		return {}
	var y: float = m.terrain_height(at.x, at.y) if m != null and m.has_method("terrain_height") else 0.0
	return {"id": "smola", "name": SMOLA["name"], "at": Vector3(at.x, y, at.y), "door": door}


## The spots on this map: each SPOTS entry projected from [lat, lon], its door the nearest ground
## road (no tunnel, bridge or deck) within 160 m; the booth faces the door. Spots without a road
## are left out. The booth stands with its back to the road, the floor away from it.
static func find_spots(g: LaneGraph, m: Node3D, org: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in SPOTS:
		var ll: Array = s["ll"]
		var at := Notebook.project(org, float(ll[0]), float(ll[1]))
		var door := kerb_near(g, at, 160.0)
		if door.is_empty():
			continue
		var y: float = m.terrain_height(at.x, at.y) if m != null and m.has_method("terrain_height") else 0.0
		var d: Vector3 = door["at"]
		var spot := s.duplicate(true)
		spot["at"] = Vector3(at.x, y, at.y)
		spot["door"] = door
		spot["face"] = atan2(at.x - d.x, at.y - d.z)  # the booth's back to the road, the floor away from it
		out.append(spot)
	return out


## The kerb lane of the ground road nearest `q` within `reach` m: {at: Vector3, e, s, yaw,
## side: Vector3 (the footway beside it)}, or {}.
static func kerb_near(g: LaneGraph, q: Vector2, reach: float) -> Dictionary:
	var best := {}
	var best_d := INF
	for r: float in [0.0, 40.0, 80.0, 120.0]:
		if r > reach:
			break
		for k in (1 if r == 0.0 else 8):
			var p: Vector2 = q + Vector2(r, 0).rotated(TAU * k / 8.0)
			var h: Array = g.snap(p, 60.0, Vector2.ZERO, false, true, true)
			if h.is_empty():
				continue
			var e: int = h[0]
			if g.e_dk[e] >= 0 or g.e_tn[e] >= 0 or g.e_bridge[e] != 0 or g.e_s1[e] - g.e_s0[e] < 14.0:
				continue
			var s := clampf(float(h[2]), g.e_s0[e] + 6.0, g.e_s1[e] - 6.0)
			var d := g.point_at(e, s).distance_to(q)
			if d < best_d and d <= reach:
				best_d = d
				var lane := g.e_lanes[e] - 1
				var lo := g.lane_offset(e, lane)
				var c := g.point_at(e, s, lo + 0.4)
				var side := g.point_at(e, s, lo + g.e_lw[e] * 0.5 + 1.4)
				var dir := g.direction(e, s)
				var y := g.height(e, s)
				best = {"at": Vector3(c.x, y, c.y), "e": e, "s": s, "yaw": atan2(dir.x, dir.y),
						"side": Vector3(side.x, y, side.y), "street": g.e_name[e]}
		if not best.is_empty():
			break
	return best


## A kerb `lo`..`hi` m from `from`, preferring the direction `toward` (a unit vector, or zero
## for any): {} if none in `tries`.
static func kerb_ring(g: LaneGraph, from: Vector2, lo: float, hi: float, toward: Vector2, rng: RandomNumberGenerator, tries := 30) -> Dictionary:
	for k in tries:
		var dir := Vector2.UP.rotated(rng.randf_range(-PI, PI))
		if toward != Vector2.ZERO:
			dir = toward.rotated(rng.randf_range(-0.7, 0.7))
		var q := from + dir * rng.randf_range(lo, hi)
		var kerb := kerb_near(g, q, 60.0)
		if not kerb.is_empty():
			var d := Vector2(kerb["at"].x, kerb["at"].z).distance_to(from)
			if d >= lo * 0.75 and d <= hi * 1.25:
				return kerb
	return {}


## The lights at time `t` (s): BEAMS beams, LASERS lasers, then the strobe, as [Transform3D,
## Color] each, in the rig's frame (the booth at the origin facing +Z). The beams swing on the
## beat in two mirrored banks, the lasers fan over the floor, the strobe flashes at most 2.2 times
## a second (none with `calm`: Access.calm, no flashing).
static func light_pose(t: float, calm: bool) -> Array:
	var out: Array = []
	var beat := t * BPM / 60.0
	var cols := [Color("#b44cff"), Color("#3ad8ff"), Color("#ff3ad0"), Color("#ffffff"), Color("#3ad8ff"), Color("#b44cff")]
	for i in BEAMS:
		var side := -1.0 if i < BEAMS / 2 else 1.0
		var k := i % (BEAMS / 2)
		var base := Vector3(side * (2.2 + k * 1.1), 4.6, -0.6)
		var sway := sin(beat * PI * 0.25 + k * 0.9) * 0.55 * side
		var tilt := 0.35 + 0.25 * sin(beat * PI * 0.125 + k * 1.7)
		var dir := Vector3(sin(sway) * cos(tilt) * 0.0 + sin(sway), cos(tilt), sin(tilt) * 0.9).normalized()
		out.append([_aim(base, dir, 2.4, BEAM_LEN), cols[i] * 0.85])
	for i in LASERS:
		var a := (float(i) / (LASERS - 1) - 0.5) * 1.3 + sin(beat * PI * 0.5) * 0.35
		var dir := Vector3(sin(a), -0.08 + 0.1 * sin(beat * PI + i), cos(a)).normalized()
		var on := 0.0 if calm else 1.0
		out.append([_aim(Vector3(0, 3.4, 0.2), dir, 0.08, LASER_LEN), Color(0.2, 1.0, 0.35) * (0.9 * on + 0.35 * (1.0 - on))])
	var flash := 0.0
	if not calm:
		var ph := fmod(beat * 0.5, 1.0)  # one flash every second beat: 1.1 a second at 132 bpm
		flash = 1.0 if ph < 0.12 else 0.0
	out.append([_aim(Vector3(0, 11.0, 6.0), Vector3.DOWN, 5.5, 11.0), Color(1, 1, 1) * flash])
	return out


## A cone from `base` along `dir`: radius `width` × the mesh's, `length` long.
static func _aim(base: Vector3, dir: Vector3, width: float, length: float) -> Transform3D:
	var up := dir.normalized()
	var x := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(up).normalized()
	return Transform3D(Basis(x * width, up * length, z * width), base)


# --- meshes ---------------------------------------------------------------------------------

## The light cone: unit length along +Y, radius 0.12 at its base to 1.0 at its far end, open,
## its vertex alpha fading from the base (the glow shader's brightness) to nothing.
static func cone_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 10
	var rings := [[0.0, 0.12, 0.5], [0.35, 0.45, 0.22], [1.0, 1.0, 0.0]]
	for r in rings.size() - 1:
		var a: Array = rings[r]
		var b: Array = rings[r + 1]
		for i in n:
			var t0 := TAU * i / n
			var t1 := TAU * (i + 1) / n
			var p := [Vector3(cos(t0) * a[1], a[0], sin(t0) * a[1]), Vector3(cos(t1) * a[1], a[0], sin(t1) * a[1]),
					Vector3(cos(t1) * b[1], b[0], sin(t1) * b[1]), Vector3(cos(t0) * b[1], b[0], sin(t0) * b[1])]
			var c := [a[2], a[2], b[2], b[2]]
			for q in [0, 1, 2, 0, 2, 3]:
				st.set_color(Color(1, 1, 1, c[q]))
				st.set_uv(Vector2(0.5, p[q].y))
				st.add_vertex(p[q])
	return st.commit()


## The DJ booth: a black table with a lit strip, two speaker stacks, a truss over it. Local frame:
## the crowd's side is +Z, the origin on the ground.
static func booth_mesh() -> ArrayMesh:
	var st := Models._begin()
	var black := Color("#141417")
	var grey := Color("#3a3a40")
	Models.box(st, Vector3(0, 0.5, 0), Vector3(2.6, 1.0, 0.9), black, Models.FIXED)
	Models.box(st, Vector3(0, 0.75, 0.47), Vector3(2.5, 0.08, 0.04), Color("#b44cff"), Models.LIT_SIGN)
	Models.box(st, Vector3(0, 1.04, 0), Vector3(1.6, 0.08, 0.6), grey, Models.FIXED)
	for side in [-1.0, 1.0]:
		Models.box(st, Vector3(side * 2.3, 1.2, 0), Vector3(1.1, 2.4, 1.0), black, Models.FIXED)
		Models.box(st, Vector3(side * 2.3, 0.75, 0.51), Vector3(0.7, 0.7, 0.02), grey, Models.FIXED)
		Models.box(st, Vector3(side * 2.3, 1.75, 0.51), Vector3(0.5, 0.5, 0.02), grey, Models.FIXED)
		Models.box(st, Vector3(side * 3.6, 2.4, -0.6), Vector3(0.18, 4.8, 0.18), grey, Models.FIXED)
	Models.box(st, Vector3(0, 4.7, -0.6), Vector3(7.4, 0.2, 0.2), grey, Models.FIXED)
	return st.commit()


func _build_rig(world: Node3D) -> void:
	_rig = Node3D.new()
	_rig.name = "Rave"
	_rig.visible = false
	world.add_child(_rig)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader")
	mat.render_priority = 1
	mat.set_shader_parameter("lift", 0.0)
	mat.set_shader_parameter("strength", 1.6)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cone_mesh()
	mm.instance_count = BEAMS + LASERS + 1
	_lights = MultiMeshInstance3D.new()
	_lights.name = "Lights"
	_lights.multimesh = mm
	_lights.material_override = mat
	_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lights.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rig.add_child(_lights)
	_booth = MeshInstance3D.new()
	_booth.name = "Booth"
	_booth.mesh = booth_mesh()
	_booth.material_override = Models.material()
	_booth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_booth.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rig.add_child(_booth)
	var dmat := Models.material().duplicate() as ShaderMaterial
	dmat.set_shader_parameter("walk", 0.0)
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_custom_data = true
	InstanceBuffers.prepare(dm)
	dm.mesh = Models.person_mesh()
	dm.instance_count = DANCERS + 1
	InstanceBuffers.whiten(dm)
	_dancers = MultiMeshInstance3D.new()
	_dancers.name = "Dancers"
	_dancers.multimesh = dm
	_dancers.material_override = dmat
	_dancers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dancers.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rig.add_child(_dancers)
	# The floor: dancers on a disc in front of the booth, a gap of 2.5 m before it; the DJ last.
	var frng := RandomNumberGenerator.new()
	frng.seed = 7311
	_floor.clear()
	for i in DANCERS:
		var a := frng.randf_range(-PI * 0.62, PI * 0.62)
		var r := sqrt(frng.randf()) * FLOOR_R
		_floor.append(Vector3(sin(a) * r, frng.randf(), 3.0 + cos(a) * r))


## The dancers' clothes: black and grey at night (a few neon), colours by day.
func _dress(day: bool) -> void:
	var dm := _dancers.multimesh
	var frng := RandomNumberGenerator.new()
	frng.seed = 911 if day else 377
	var night := [Color("#1a1a1e"), Color("#232327"), Color("#2e2e34"), Color("#141416"), Color("#1a1a1e"), Color("#3ad8ff"), Color("#ff3ad0")]
	var sun := [Color("#f2d34a"), Color("#4ab8f2"), Color("#f27a4a"), Color("#ffffff"), Color("#7ad66a"), Color("#e86ab4"), Color("#f2f2e6")]
	for i in DANCERS:
		var c: Color = (sun if day else night)[frng.randi() % 7]
		var tr := 0.25 if not day else float(frng.randi() % 4) / 4.0
		dm.set_instance_custom_data(i, Color(c.r, c.g, c.b, tr))
	dm.set_instance_custom_data(DANCERS, Color(0.08, 0.08, 0.09, 0.25))


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	_clock += dt
	if _rig.visible and _lights.visible:
		_pose_lights()
	_tick += dt
	if _tick >= TICK:
		step(_tick)
		_tick = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func _pose_lights() -> void:
	var mm := _lights.multimesh
	var pose := light_pose(_clock, Access.calm)
	for i in pose.size():
		mm.set_instance_transform(i, pose[i][0])
		mm.set_instance_color(i, pose[i][1])


## The slow part, every TICK s.
func step(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var kmh: float = v[1]
	_rig_tick(dt)
	match state:
		State.IDLE:
			if auto and _free() and _tease_window():
				tease_in -= dt
				if tease_in <= 0.0:
					# Ziomek's nights take turns: Smoła (he rings straight away), then a secret rave
					# (LEKTI first).
					if next_kind == "smola" and not smola.is_empty():
						if not ring("smola"):
							tease_in = 15.0
					else:
						tease()
		State.WAIT_CALL:
			if _free():
				call_in -= dt
				if call_in <= 0.0 and not ring():
					call_in = 15.0
		State.RING, State.OFFER:
			_ring_t += dt
			if _ring_t > RING_LIFE:
				hud.hide_card()
				hud.toast("Nieodebrane połączenie: %s" % FRIEND, "Missed call: %s" % FRIEND)
				_reset()
		State.PICKUP:
			var p: Vector3 = pickup["at"]
			_status("ZIOMEK · pod blokiem", "Zatrzymaj się przy Zimku", "Stop by Ziomek", at, p, PICK_COLOUR)
			if _arrived(dt, at, kmh, p, PICK_R):
				_board()
		State.MEET:
			_talk(dt, "ride")
			_status("??? · punkt zborny", "Ziomek prowadzi. Jedź za strzałką", "Ziomek leads. Follow the arrow", at, meet["at"], COLOUR, "???")
			if _arrived(dt, at, kmh, meet["at"], MEET_R):
				_reveal()
		State.DRIVE:
			_talk(dt, "go" if kind == "rave" else "go_smola")
			var dest := _dest()
			var what := "sekretny rave" if kind == "rave" else "selekcja"
			_status("%s · %s" % [String(dest["name"]).to_upper(), what], "Zatrzymaj się przy bramce", "Stop at the door", at, dest["door"]["at"], COLOUR)
			if _arrived(dt, at, kmh, dest["door"]["at"], DOOR_R):
				_door()
		State.DOOR:
			# No answer for DOOR_LIFE s (or a card that never got a place): the bouncer gives up on you.
			_door_t += dt
			if _door_t > DOOR_LIFE:
				hud.hide_card()
				_log("door: no answer in %.0f s" % DOOR_LIFE)
				_enter("out")
		State.RESULT:
			_result_t += dt
			if _result_t > RESULT_LIFE:
				hud.hide_card()
				_finish()


func _free() -> bool:
	return free_now.is_valid() and bool(free_now.call()) and not spots.is_empty()


func _now() -> Dictionary:
	return clock.call() if clock.is_valid() else {"hour": 1.5, "weekday": 6}


func _tease_window() -> bool:
	var c := _now()
	return tease_on(float(c["hour"]), int(c["weekday"]))


func busy() -> bool:
	return state in [State.PICKUP, State.MEET, State.DRIVE, State.DOOR]


func has_target() -> bool:
	return state in [State.PICKUP, State.MEET, State.DRIVE]


func target_position() -> Vector3:
	match state:
		State.PICKUP:
			return pickup["at"]
		State.MEET:
			return meet["at"]
		State.DRIVE:
			return _dest()["door"]["at"]
	return Vector3.ZERO


func target_colour() -> Color:
	return PICK_COLOUR if state == State.PICKUP else COLOUR


## The arrow's label: "???" on the way to the meeting point (Ziomek knows only that).
func target_label(metres: int) -> String:
	return "???" if state == State.MEET else "%d m" % metres


func _status(title: String, hint: String, hint_en: String, at: Vector3, to: Vector3, colour: Color, dist := "") -> void:
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)))
	hud.show_status(title, "", dist if dist != "" else "%d m" % m, hint, _hold_t / HOLD, colour, "", {}, hint_en)


func _arrived(dt: float, at: Vector3, kmh: float, to: Vector3, r: float) -> bool:
	if Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)) <= r and kmh < STOP_KMH:
		_hold_t += dt
	else:
		_hold_t = 0.0
	if _hold_t >= HOLD:
		_hold_t = 0.0
		return true
	return false


# --- the rig --------------------------------------------------------------------------------

## Which spot is on now, drawn near the view: the quest's from the meeting point on, else the
## weekend's on a rave night, the day spot on a day-rave afternoon, or what --rave= forces.
func _rig_tick(dt: float) -> void:
	var c := _now()
	var hour := float(c["hour"])
	var wd := int(c["weekday"])
	var want := -1
	var mode := ""
	if state in [State.DRIVE, State.DOOR, State.RESULT] and kind == "rave" and quest_spot >= 0:
		want = quest_spot
		mode = "night"
	elif force == "on" or (force == "" and night_on(hour, wd)):
		want = night_spot
		mode = "night"
	elif force == "day" or (force == "" and day_on(hour, wd)):
		want = day_spot
		mode = "day"
	if want >= 0 and want < spots.size():
		var f: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
		var s: Dictionary = spots[want]
		var d := Vector2(f.x, f.z).distance_to(Vector2(s["at"].x, s["at"].z))
		if d > RIG_FAR:
			want = -1
	else:
		want = -1
	if want < 0:
		mode = ""
	if want != active or mode != active_mode:
		active = want
		active_mode = mode if want >= 0 else ""
		_rig.visible = active >= 0
		if active >= 0:
			var s: Dictionary = spots[active]
			_rig.global_transform = Transform3D(Basis(Vector3.UP, float(s["face"])), s["at"])
			_lights.visible = active_mode == "night"
			_dress(active_mode == "day")
			_dance(0.0, true)
		_log("rig: %s" % ("%s (%s)" % [spots[active]["id"], active_mode] if active >= 0 else "off"))
	if active < 0:
		return
	var f2: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var near := Vector2(f2.x, f2.z).distance_to(Vector2(spots[active]["at"].x, spots[active]["at"].z))
	_dancers.visible = near < DANCE_R * 2.0
	if near < DANCE_R:
		_dance(dt, false)
	if near < TALK_R and dialogue != null:
		_crowd_t -= dt
		if _crowd_t <= 0.0:
			_crowd_t = _rng.randf_range(CROWD_GAP.x, CROWD_GAP.y)
			var p := spots[active]["at"] as Vector3
			var spot := p + Basis(Vector3.UP, float(spots[active]["face"])) * _floor[_rng.randi() % _floor.size()] * Vector3(1, 0, 1)
			dialogue.say_ambient(spot, "", "rave_crowd", active_mode, 3.6, BUBBLE, 2.3)
	if not _noticed and active_mode == "night" and state == State.IDLE and near < NOTICE_R and hud != null:
		_noticed = true
		hud.toast("Ktoś tu robi imprezę… Słuchaj MORDOR FM", "Someone's throwing a party here… Listen to MORDOR FM")


## The dancers bob on the beat (a hop on every beat, a sway), the DJ behind the table nods.
func _dance(dt: float, now: bool) -> void:
	_dance_t -= dt
	if not now and _dance_t > 0.0:
		return
	_dance_t = 1.0 / 15.0
	var dm := _dancers.multimesh
	var beat := _clock * BPM / 60.0
	var amp := 0.06 if active_mode == "day" else 0.13
	for i in _floor.size():
		var f := _floor[i]
		var ph := fmod(beat + f.y * 0.3, 1.0)
		var hop := amp * (1.0 - absf(ph * 2.0 - 1.0))
		var yaw := PI + sin(beat * PI * 0.5 + f.y * 6.0) * 0.35 - atan2(f.x, f.z) * 0.3
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), Vector3(f.x, hop, f.z)))
	var nod := 0.04 * absf(sin(beat * PI))
	dm.set_instance_transform(DANCERS, Transform3D(Basis(Vector3.UP, 0.0), Vector3(0, nod, -0.9)))


# --- the quest ------------------------------------------------------------------------------

## LEKTI on MORDOR FM: the invite and the password (heard), or the regular host's rumour on
## another station. True if something went on air.
func tease() -> bool:
	if spots.is_empty() or state != State.IDLE:
		return false
	password = PASSWORDS[_rng.randi() % PASSWORDS.size()]
	quest_spot = night_spot
	kind = "rave"
	next_kind = "smola"
	heard = false
	state = State.WAIT_CALL
	call_in = _rng.randf_range(CALL_AFTER.x, CALL_AFTER.y)
	var on := false
	if radio != null and dialogue != null and int(radio.station) >= 0:
		var mordor := int(radio.station) == _mordor
		var l: Array = dialogue.line("rave_lekti" if mordor else "rave_rumour")
		if not l.is_empty():
			radio.announce(String(l[0]).replace("{pw}", password), String(l[1]).replace("{pw}", password))
			heard = mordor
			on = true
			if mordor:
				_speak(voice_files(dialogue.lines.get("rave_lekti", []).find(l), password))
	_log("tease: %s, password %s, %s; Ziomek rings in %.0f s" % ["LEKTI on MORDOR FM" if heard else ("the rumour" if on else "radio off"),
			password, spots[quest_spot]["id"], call_in])
	return on


## LEKTI's voice (ElevenLabs Creator, the MORDOR FM announcer voice, docs/design/secret-rave.md):
## the files for line `i` of `rave_lekti` and the password `pw`, in play order; empty for a line
## without a clip. Every line and every password has one (check_rave).
static func voice_files(i: int, pw: String) -> PackedStringArray:
	if i < 0:
		return PackedStringArray()
	var slug := pw.to_lower().replace(" ", "_").replace("ł", "l")
	return PackedStringArray([VOICE_DIR + "lekti_%d.ogg" % (i + 1), VOICE_DIR + "pw_%s.ogg" % slug])


## Plays `files` one after another on the SFX bus, the radio's music dipped under them (the
## ticker shows the same words). Silent headless and without the files.
func _speak(files: PackedStringArray) -> void:
	if files.is_empty() or DisplayServer.get_name() == "headless":
		return
	var streams: Array[AudioStream] = []
	var total := 0.0
	for f in files:
		if not ResourceLoader.exists(f):
			return
		var st: AudioStream = load(f)
		streams.append(st)
		total += st.get_length() + VOICE_GAP
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		_voice.bus = &"SFX"
		_voice.volume_db = VOICE_DB
		add_child(_voice)
	if radio != null and radio.has_method("voice_moment"):
		radio.voice_moment(total + 0.6)
	_voice_queue = streams
	_next_voice()


func _next_voice() -> void:
	if _voice_queue.is_empty():
		return
	_voice.stream = _voice_queue.pop_front()
	_voice.play()
	if not _voice_queue.is_empty():
		get_tree().create_timer(_voice.stream.get_length() + VOICE_GAP).timeout.connect(_next_voice, CONNECT_ONE_SHOT)


## The phone rings (--rave-call too): `k` "smola" for the club night, else the secret rave
## (after LEKTI's line, or straight away with --rave-call). False with no spots or while busy.
func ring(k := "") -> bool:
	if spots.is_empty() or graph == null or state not in [State.IDLE, State.WAIT_CALL]:
		return false
	if k == "smola" and not smola.is_empty():
		kind = "smola"
		next_kind = "rave"
		password = ""
	elif kind != "rave":
		kind = "rave"
		next_kind = "smola"
		password = PASSWORDS[_rng.randi() % PASSWORDS.size()]
		quest_spot = night_spot
	state = State.RING
	_ring_t = 0.0
	hud.show_side_card("📞 ZIOMEK DZWONI", "Kumpel z osiedla. Zawsze na czarno, zawsze wie, gdzie jest impreza, zanim ktokolwiek o niej usłyszy.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "Ziomek is calling",
			"Your mate from the estate. Always in black, always knows where the party is before anyone's heard of it.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


## Met in person at his block (story_quests.gd: he came out, the player said WCHODZĘ): no call, no
## pickup; he gets in and the night goes on as after a pickup (the meeting point, the door).
func meet_in_person() -> bool:
	if spots.is_empty() or graph == null or state not in [State.IDLE, State.WAIT_CALL] or not vehicle.is_valid():
		return false
	if state == State.IDLE or kind != "rave":
		password = PASSWORDS[_rng.randi() % PASSWORDS.size()]
		heard = false
	kind = "rave"
	next_kind = "smola"
	quest_spot = night_spot
	var p: Vector3 = vehicle.call()[0]
	pickup = {"at": p, "side": p, "street": home.get("street", "")}
	_calls_were = missions.paused if missions != null else false
	if missions != null:
		missions.paused = true
	_log("met Ziomek in person at his block")
	_board()
	return true


## Idle: no call ringing, no night under way (a questline may start now).
func idle() -> bool:
	return state in [State.IDLE, State.WAIT_CALL]


## He asks: the pickup at his block; JADĘ! / NIE DZIŚ.
func _offer() -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var from := Vector2((v[0] as Vector3).x, (v[0] as Vector3).z)
	pickup = kerb_ring(graph, from, PICK_FROM, PICK_TO, Vector2.ZERO, _rng)
	if pickup.is_empty():
		pickup = kerb_ring(graph, from, 150.0, PICK_TO * 1.5, Vector2.ZERO, _rng)
	if pickup.is_empty():
		hud.hide_card()
		_reset()
		return
	state = State.OFFER
	_ring_t = 0.0
	var street: String = pickup["street"] if String(pickup["street"]) != "" else "osiedlu"
	var street_en: String = pickup["street"] if String(pickup["street"]) != "" else "the estate"
	var pl := "„Słyszałeś Lektiego na Mordorze? Sekretny rave, dziś w nocy! Ja wiem, jak tam trafić. Zgarniesz mnie spod bloku na %s? Tylko nikomu ani słowa.”" % street
	var en := "\"Did you hear Lekti on Mordor? A secret rave, tonight! I know how to get there. Pick me up from my block on %s? Not a word to anyone.\"" % street_en
	if kind == "smola":
		pl = "„Siema! Jedziemy na Smołę? Selekcja jak w Berlinie, ale ja mam patent: mów mało, patrz w dal. Zgarniesz mnie spod bloku na %s?”" % street
		en = "\"Hey! Shall we hit Smoła? The door's Berlin-strict, but I've got a system: say little, stare into the distance. Pick me up from my block on %s?\"" % street_en
	elif not heard:
		pl = "„Siema! Lekti robi dziś sekretny rave. Ja wiem, jak tam trafić. Zgarniesz mnie spod bloku na %s? Hasło? Trzeba było słuchać MORDOR FM…”" % street
		en = "\"Hey! Lekti's throwing a secret rave tonight. I know how to get there. Pick me up from my block on %s? The password? You should've listened to MORDOR FM…\"" % street_en
	hud.show_side_card("📞 ZIOMEK", pl, PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TONIGHT"]), COLOUR, FRIEND, en)
	_log("offer: Ziomek on %s at %d,%d" % [street_en, roundi(pickup["at"].x), roundi(pickup["at"].z)])


func _on_card(i: int) -> void:
	match state:
		State.RING:
			if i == 0:
				_offer()
			else:
				hud.hide_card()
				hud.toast("Odrzucono. Ziomek pójdzie sam. Na czarno.", "Declined. Ziomek will go alone. In black.")
				_reset()
		State.OFFER:
			hud.hide_card()
			if i == 0:
				accept()
			else:
				hud.toast("„Dobra. Ale jak będą o tym mówić w poniedziałek, to nie płacz.”", "\"Fine. But when they're talking about it on Monday, don't cry.\"")
				_reset()
		State.DOOR:
			_answer(i)
		State.RESULT:
			hud.hide_card()
			var go_in := i == 0 and String(last_pay.get("result", "")) != "out" and enter_club.is_valid()
			var t := ["SMOŁA", "SMOŁA"] if kind == "smola" else ["SEKRETNY RAVE", "SECRET RAVE"]
			_finish()
			if go_in and wallet != null and not wallet.spend(ENTRY):
				go_in = false
				hud.toast("Za mało gotówki. Bramkarz wskazuje bankomat… trzy ulice dalej.", "Not enough cash. The bouncer points to a cash machine… three streets away.")
				_log("door: no cash for the %d zł ticket" % ENTRY)
			if go_in:
				_log("door: paid %d zł cash" % ENTRY)
				enter_club.call(t[0], t[1])


## JADĘ!: Ziomek waiting at his block (the dashed ring, waving).
func accept() -> void:
	if pickup.is_empty():
		return
	_calls_were = missions.paused if missions != null else false
	if missions != null:
		missions.paused = true
	var side: Vector3 = pickup["side"]
	_pick.place(Vector3(side.x, pickup["at"].y, side.z), PICK_R, true, true)
	_pick.visible = true
	state = State.PICKUP
	_hold_t = 0.0
	hud.toast("Jedź po Ziomka", "Go and pick up Ziomek")
	_log("accepted: to the pickup")


## Ziomek in: the radio to MORDOR FM, the meeting point between here and the rave.
func _board() -> void:
	_pick.visible = false
	if radio != null and _mordor >= 0 and int(radio.station) != _mordor:
		radio.tune(_mordor)
	if kind == "smola":
		state = State.DRIVE
		_talk_t = 2.0
		_hold_t = 0.0
		_say("board_smola")
		_log("boarded; to Smoła")
		return
	var s: Dictionary = spots[quest_spot]
	var at: Vector3 = pickup["at"]
	var rave := Vector2(s["at"].x, s["at"].z)
	var toward := (Vector2(at.x, at.z) - rave).normalized()
	meet = kerb_ring(graph, rave, MEET_FROM, MEET_TO, toward, _rng)
	if meet.is_empty():
		meet = kerb_ring(graph, rave, 200.0, MEET_TO * 1.6, Vector2.ZERO, _rng)
	if meet.is_empty():
		_reveal()
		return
	var side: Vector3 = meet["side"]
	_meet_mark.place(Vector3(side.x, meet["at"].y, side.z), MEET_R, true, true)
	_meet_mark.visible = true
	state = State.MEET
	_talk_t = 2.0
	_say("board")
	_log("boarded; meeting point at %d,%d, %.0f m from the rave" % [roundi(meet["at"].x), roundi(meet["at"].z),
			Vector2(meet["at"].x, meet["at"].z).distance_to(rave)])


## The hooded man at the meeting point gives the spot.
func _reveal() -> void:
	var s: Dictionary = spots[quest_spot]
	var w: Array = s["where"]
	if dialogue != null and not meet.is_empty():
		var l: Array = dialogue.line("rave_meet")
		if not l.is_empty():
			var side: Vector3 = meet["side"]
			if dialogue.bubbles != null:
				dialogue.bubbles.say(side, "Kaptur", String(l[0]).replace("{where}", w[0]), String(l[1]).replace("{where}", w[1]),
						5.0, COLOUR, 2.4)
	hud.toast("Lokalizacja: %s" % w[0], "Location: %s" % w[1])
	_meet_mark.visible = false
	state = State.DRIVE
	_talk_t = 4.0
	_hold_t = 0.0
	_log("revealed: %s" % s["id"])


## At the door: the bouncer's three questions, one card each (door_quiz).
func _door() -> void:
	state = State.DOOR
	hud.hide_status()
	quiz = door_quiz(password if kind == "rave" else "", _rng)
	quiz_i = 0
	quiz_right = 0
	_ask()


func _ask() -> void:
	var q: Array = quiz[quiz_i]
	var buttons := PackedStringArray()
	for a: Array in q[1]:
		buttons.append("%s|%s" % [a[0], a[1]])
	# The answers stacked (Autopilot 2026-11-06: three answers in one row made the card too wide
	# to place on a 16:9 screen, and the door waited for ever).
	# Only the question on the card: short enough for a 16:9 screen too.
	hud.show_card("SELEKCJA %d/%d" % [quiz_i + 1, quiz.size()], "„%s”" % q[0][0], buttons, COLOUR, false,
			"THE DOOR %d/%d" % [quiz_i + 1, quiz.size()], "\"%s\"" % q[0][1], true)
	_door_t = 0.0
	_log("door %d: %s" % [quiz_i + 1, q[0][1]])


## An answer on the door's card: the next question, or the verdict after the last.
func _answer(i: int) -> void:
	if quiz.is_empty():
		return
	if i != int(quiz[quiz_i][2]):
		hud.hide_card()
		_enter("out")
		return
	quiz_right += 1
	quiz_i += 1
	if quiz_i < quiz.size():
		_ask()
		return
	hud.hide_card()
	_enter(door_result(quiz_right))


## The verdict: "in" (all three right), "out" (a wrong answer: "Nie tym razem. Wróć później.",
## Ziomek's plan C, half the fare); the pay.
func _enter(result: String) -> void:
	var p := pay_for(result == "in")
	last_pay = {"zl": p[0], "respect": p[1], "result": result, "right": quiz_right}
	if wallet != null:
		wallet.pay(p[0], p[1], "rave")
	_say("door_ok" if result == "in" else "door_out")
	var place: String = "Smoła" if kind == "smola" else "rave"
	var pl := ""
	var en := ""
	match result:
		"in":
			raves += 1
			pl = "%d na 3. Bramkarz kiwa głową, Ziomek znika w tłumie. Na odchodne: „Dzięki! Za kurs %d zł. Widzimy się o świcie.” +%d szacunku." % [quiz_right, p[0], p[1]]
			en = "%d out of 3. The bouncer nods, Ziomek vanishes into the crowd. On his way: \"Thanks! %d zł for the ride. See you at sunrise.\" +%d respect." % [quiz_right, p[0], p[1]]
		_:
			rejected += 1
			pl = "Bramkarz patrzy na ciebie trzy długie sekundy. „Nie tym razem. Wróć później.” Ziomek wzdycha: „Kebab i do domu. Plan C.” Płaci za kurs %d zł." % p[0]
			en = "The bouncer looks at you for three long seconds. \"Not this time. Come back later.\" Ziomek sighs: \"A kebab and home. Plan C.\" He pays %d zł for the ride." % p[0]
	state = State.RESULT
	_result_t = 0.0
	var title := ("SMOŁA" if kind == "smola" else "SEKRETNY RAVE") if result != "out" else "NIE DZIŚ"
	var title_en := ("SMOŁA" if kind == "smola" else "SECRET RAVE") if result != "out" else "NOT TONIGHT"
	if result != "out" and enter_club.is_valid():
		pl += " " + entry_note()[0]
		en += " " + entry_note()[1]
	var buttons := PackedStringArray(["OK"]) if result == "out" or not enter_club.is_valid() else PackedStringArray(["PŁACĘ %d ZŁ|PAY %d ZŁ CASH" % [ENTRY, ENTRY], "POTEM|LATER"])
	hud.show_card(title, pl, buttons, COLOUR, false, title_en, en)
	_log("%s: %s, %d/3 right, +%d zł +%d respect" % [place, result, quiz_right, p[0], p[1]])


## The door's cash line under the result: the ticket, cash only, the card machine a joke.
static func entry_note() -> Array:
	return ["Bilet: %d zł. Tylko gotówka, terminal „chwilowo nie działa” od 2019." % ENTRY,
			"Ticket: %d zł. Cash only, the card machine has been \"temporarily down\" since 2019." % ENTRY]


## Where the quest drives now: the secret spot or Smoła.
func _dest() -> Dictionary:
	if kind == "smola":
		return smola
	return spots[quest_spot]


func _give_up() -> void:
	hud.hide_status()
	_say("abort")
	hud.toast("Ziomek łapie nocny autobus", "Ziomek catches the night bus")
	_log("gave up")
	_finish()


## Back to free play: the calls back on, next weekend's spot, LEKTI later.
func _finish() -> void:
	_pick.visible = false
	_meet_mark.visible = false
	hud.hide_status()
	if missions != null:
		missions.paused = _calls_were
	if state == State.RESULT and kind == "rave":
		var nights := night_spots()
		if not nights.is_empty():
			night_spot = nights[(nights.find(night_spot) + 1) % nights.size()]
	_reset()


func _reset() -> void:
	state = State.IDLE
	pickup = {}
	meet = {}
	password = ""
	quest_spot = -1
	kind = ""
	quiz = []
	_hold_t = 0.0
	tease_in = _rng.randf_range(NEXT_TEASE.x, NEXT_TEASE.y)
	_log("LEKTI again in %.0f s" % tease_in)


## The night spots' indices.
func night_spots() -> Array[int]:
	var out: Array[int] = []
	for i in spots.size():
		if bool(spots[i]["night"]):
			out.append(i)
	return out


func _talk(dt: float, tag: String) -> void:
	_talk_t -= dt
	if _talk_t <= 0.0:
		_talk_t = _rng.randf_range(TALK_GAP.x, TALK_GAP.y)
		_say(tag)


## Ziomek's line (dialogue.json `rave_ziomek`, tag) over the car (he's in it).
func _say(tag: String) -> void:
	if dialogue == null:
		return
	var anchor := func() -> Vector3:
		var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
		return v[0]
	dialogue.say(anchor, FRIEND, "rave_ziomek", tag, 4.2, BUBBLE, 2.2)


func _log(text: String) -> void:
	if log_on:
		print("rave: " + text)
