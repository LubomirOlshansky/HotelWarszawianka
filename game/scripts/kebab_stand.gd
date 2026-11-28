extends RefCounted
## The 2D kebab stand's rules (plan doc "First 10 minutes: Tajny klient", "The 2D kebab stand"):
## the one owner of the kebab mini-game, for the opening at KEBAB U KEMALA today and the Tapczan
## crawl's kebab leg and Kebabulo's MLASK reviews later. There is never a second copy: a new stand
## is a row in data/kebab_stand.json and its words in dialogue.json.
##
## The order, in phases: HELLO (the owner's line), DISH (four photo panels on the board), SAUCE
## (three bottles), WHO ("Dla kogo?": for me / for a mate with a camera; a stand may skip it),
## BUILD (about 5 s: shave, fill, roll), POUR (the one skill beat: hold to pour, let go in the
## green; too little is dry, too much is sauce on your jacket; never a fail, and with auto-pour
## in DOSTĘP it pours itself to the middle of the green), PAY (BLIP; the VIP kebab for the camera
## is on the house), DONE (WYJDŹ). Two tap toys: the tip jar (2 zł, once, the owner's blessing)
## and the DŻEMINI flyer.
##
## Pure: no nodes, no drawing (kebab_stand_ui.gd draws it and passes the touch); the owner of the
## run (tajny_klient.gd) reads `result()` at the end, spends the price and keeps the picks.
## check_kebab_stand.gd plays it.
##
## Words: dialogue.json group "kebab_stand", a stand's own tag ("kemal_hello") before the shared
## one ("hello"). Menus: data/kebab_stand.json.

const PATH := "res://data/kebab_stand.json"
const WORDS_PATH := "res://data/dialogue.json"
const GROUP := "kebab_stand"

enum Phase {HELLO, DISH, SAUCE, WHO, BUILD, POUR, PAY, DONE}

## How long the owner's hello stays before the board (a tap skips it), the order is built, the
## BLIP terminal thinks, and an auto run waits on DONE (s).
const HELLO_S := 2.6
const BUILD_S := 5.0
const PAY_S := 1.6
const AUTO_DONE_S := 1.2
## A press shorter than this is a tap, not a pour (s).
const TAP_S := 0.08
## The tip toy's price (zł).
const TIP := 2

var id := "kemal"
var stand: Dictionary = {}
var ask_who := true
var auto_pour := false
## The autopilot's thumb: every pick is the first, the pour lands in the middle of the green.
var auto_play := false

var phase := Phase.HELLO
## Seconds in this phase.
var t := 0.0
var dish := 0
var sauce := 0
var cam := false
## The sauce poured (a share of the gauge; 1.0 its top) and the verdict once let go: "" while
## pouring, "good", "dry" or "jacket".
var level := 0.0
var pour := ""
var tipped := false
## The owner's line now (a tag of `say`; "" none) and how long it has been up.
var line := ""
var line_t := 0.0
var picks: Array[String] = []

var _held := 0.0
var _poured := false

static var _data: Dictionary = {}
static var _words: Dictionary = {}


func _init(stand_id := "kemal", who := true) -> void:
	id = stand_id
	stand = stand_of(stand_id)
	ask_who = who
	_say("hello")


# --- the data ---------------------------------------------------------------------------------------

static func data() -> Dictionary:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {}
	return _data


static func stand_of(stand_id: String) -> Dictionary:
	return (data().get("stands", {}) as Dictionary).get(stand_id, {})


## The id of a stand's dish `i` ("bun", "wrap", "box", "xxl"), "bun" when there is none.
static func dish_id(stand_id: String, i: int) -> String:
	var ds: Array = stand_of(stand_id).get("dishes", [])
	return str((ds[i] as Dictionary).get("id", "bun")) if i >= 0 and i < ds.size() else "bun"


## A line [Polish, English] of the group: the stand's own tag ("kemal_hello") first, then the
## shared one; [tag, tag] when neither is there (check_kebab_stand fails on that).
static func say(tag: String, words := "kemal") -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
		if d is Dictionary:
			for l: Variant in (d as Dictionary).get(GROUP, []):
				if l is Array and (l as Array).size() >= 3 and l[2] is Dictionary:
					_words[str((l[2] as Dictionary).get("only", ""))] = [str(l[0]), str(l[1])]
	if _words.has(words + "_" + tag):
		return _words[words + "_" + tag]
	return _words.get(tag, [tag, tag])


## The tag every `say` of this script and the view may ask, for the check.
static func has_words(tag: String, words := "kemal") -> bool:
	say("")
	return _words.has(words + "_" + tag) or _words.has(tag)


func dishes() -> Array:
	return stand.get("dishes", [])


func sauces() -> Array:
	return stand.get("sauces", [])


func green() -> Vector2:
	var g: Array = (stand.get("pour", {}) as Dictionary).get("green", [0.55, 0.8])
	return Vector2(float(g[0]), float(g[1]))


func spill() -> float:
	return float((stand.get("pour", {}) as Dictionary).get("spill", 1.15))


func words() -> String:
	return str(stand.get("words", id))


## What the order costs (zł): the dish's price, nothing for the camera's VIP kebab.
func price() -> int:
	if cam or dishes().is_empty():
		return 0
	return int(dishes()[clampi(dish, 0, dishes().size() - 1)].get("price", 0))


## The pour's verdict for a level (pure): under the green is dry, over it the jacket.
static func judge(lvl: float, g: Vector2) -> String:
	if lvl < g.x:
		return "dry"
	if lvl > g.y:
		return "jacket"
	return "good"


## The run's outcome for its owner: {dish, sauce, cam, pour, price, tipped}.
func result() -> Dictionary:
	return {"dish": dish, "sauce": sauce, "cam": cam, "pour": pour if pour != "" else "good", "price": price(),
			"tipped": tipped}


# --- the play ---------------------------------------------------------------------------------------

func _go(p: Phase) -> void:
	phase = p
	t = 0.0
	match p:
		Phase.DISH:
			_say("menu")
		Phase.SAUCE:
			_say("sauce")
		Phase.WHO:
			_say("who")
		Phase.BUILD:
			_say("hot" if _sauce_id() == "hot" else ("vip" if cam else "build"))
		Phase.POUR:
			level = 0.0
			pour = ""
			_poured = false
			_held = 0.0
			_say("pour")
		Phase.PAY:
			_say("pay_cam" if cam else "pay")
		Phase.DONE:
			_say("paid_cam" if cam else "paid")


func _say(tag: String) -> void:
	line = tag
	line_t = 0.0


func _sauce_id() -> String:
	if sauces().is_empty():
		return ""
	return str(sauces()[clampi(sauce, 0, sauces().size() - 1)].get("id", ""))


## The hello skipped by a tap.
func tap_hello() -> void:
	if phase == Phase.HELLO:
		_go(Phase.DISH)


## A pick on the board, a bottle or "Dla kogo?" (index from 0). False when this phase has none.
func pick(i: int) -> bool:
	match phase:
		Phase.DISH:
			if i < 0 or i >= dishes().size():
				return false
			dish = i
			picks.append(str(dishes()[i].get("id", i)))
			_go(Phase.SAUCE)
		Phase.SAUCE:
			if i < 0 or i >= sauces().size():
				return false
			sauce = i
			picks.append(_sauce_id())
			_go(Phase.WHO if ask_who else Phase.BUILD)
		Phase.WHO:
			if i < 0 or i > 1:
				return false
			cam = i == 1
			picks.append("cam" if cam else "self")
			_go(Phase.BUILD)
		_:
			return false
	return true


## The tip jar: 2 zł once, the owner's blessing (the view asks the wallet first).
func tip() -> bool:
	if tipped or phase == Phase.DONE:
		return false
	tipped = true
	_say("tip")
	return true


## The DŻEMINI flyer on the glass: the owner's line about the rival.
func flyer() -> void:
	_say("flyer")


## The way out, once it is done. True when the stand may close.
func leave() -> bool:
	return phase == Phase.DONE


## One frame: `holding` is the finger down (the pour's only input).
func tick(dt: float, holding: bool) -> void:
	t += dt
	line_t += dt
	match phase:
		Phase.HELLO:
			if t >= HELLO_S:
				_go(Phase.DISH)
		Phase.DISH, Phase.SAUCE, Phase.WHO:
			if auto_play and t >= 0.8:
				pick(0)
		Phase.BUILD:
			if t >= BUILD_S:
				_go(Phase.POUR)
		Phase.POUR:
			_pour(dt, holding)
		Phase.PAY:
			if t >= PAY_S:
				_go(Phase.DONE)
		Phase.DONE:
			pass


func _pour(dt: float, holding: bool) -> void:
	if pour != "":
		if t >= 1.2:
			_go(Phase.PAY)
		return
	var g := green()
	var auto := auto_pour or auto_play
	if auto:
		# The middle of the green, after a breath so the bottle is seen to tip.
		holding = t >= 0.5 and level < (g.x + g.y) * 0.5
		if t >= 0.5 and not holding:
			_let_go()
			return
	var speed := float(sauces()[clampi(sauce, 0, sauces().size() - 1)].get("speed", 0.5)) if not sauces().is_empty() else 0.5
	if holding:
		_held += dt
		if _held >= TAP_S:
			_poured = true
			level += speed * dt
			if level >= spill():
				level = spill()
				_let_go()
	elif _poured:
		_let_go()
	else:
		_held = 0.0


func _let_go() -> void:
	pour = judge(level, green())
	t = 0.0
	_say("pour_" + pour)


## The run's place for the stats and the log: "dish/sauce/who pour".
func summary() -> String:
	return "%s %s" % ["/".join(picks), pour]
