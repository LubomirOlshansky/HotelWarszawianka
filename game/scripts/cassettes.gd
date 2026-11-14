extends Node
## The first-10 polish (docs/DEMO.md 6.2 "6:00: helicopter over the river: a cassette on the
## boulevard roof, a new song"; 6.3 "10 cassettes"): mixtapes lying on roofs, from
## `data/cassettes.json`. The first one, on the University Library's roof garden by the
## boulevards, is the guide's 6:00 beat (first10.gd points its arrow here).
##
## - **Where.** Each lies on a landmark's roof: the rescue's flat-roof spot of that landmark
##   (rescue_places.gd `roof_spot`, its highest flat spot), so a helicopter can come down to it.
## - **The prop.** One MeshInstance3D for all of them (one surface, one draw call; hidden once
##   every one is taken): a big pink cassette (CASSETTE m wide, so it reads from the helicopter's
##   height) with its label and reels, and a pink diamond over it (Models LIT_SIGN: it glows at
##   night), the Syrenki's marker in this card's colour. No collision, no shadow.
## - **The pickup.** Five times a second (CHECK_EVERY: nothing per frame) the vehicle is compared
##   with the cassettes not taken: within REACH m on the ground plane, and flying less than
##   FLY_REACH m over the roof (a car on the roof, which can't happen, within CAR_DY). The first
##   time: the save (wallet.gd `cassettes`: id -> day), +respect, the card and the next locked
##   PÓŁNOC FM track (radio.gd `unlock_track`, "cassette"), whose own toast follows.
## Cost: the 5 Hz look (`spent_usec`).

const Lang := preload("res://scripts/lang.gd")
const Districts := preload("res://scripts/districts.gd")
const Models := preload("res://scripts/models.gd")
const Access := preload("res://scripts/access.gd")

const DATA_PATH := "res://data/cassettes.json"
const CHECK_EVERY := 0.2
## The pickup: metres on the ground plane, and how far above the roof the helicopter may be.
const REACH := 9.0
const FLY_REACH := 16.0
const CAR_DY := 3.0
## The cassette's width (m) and the diamond's size and height over the roof (m).
const CASSETTE := 4.0
const MARKER_SIZE := 1.4
const MARKER_UP := 4.5
## The card's colour: a cassette's hot pink (not the Syrenki's teal or the notebook's yellow).
const COLOUR := Color("#ff5fa2")
const LABEL := Color("#f4efe4")
const REEL := Color("#2a2a2e")

## One per cassette: cassettes.json's fields plus `pos` (Vector3, INF until placed).
var entries: Array[Dictionary] = []
var by_id := {}
var respect := 10
var wallet: Node
var hud: CanvasLayer
var radio: Node
## The 3D world (main.gd `world`); null in the checks.
var world: Node3D
## The vehicle now: [position (Vector3), km/h, flying, altitude, away] (notebook.gd's probe).
var probe: Callable
var blip: Callable
var ready_ok := false
var spent_usec := 0
var _node: MeshInstance3D
var _t := 0.0


## Reads cassettes.json (no map). False if it is missing or does not parse.
func load_data() -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not json is Dictionary:
		push_error("cassettes: %s does not parse" % DATA_PATH)
		return false
	respect = int(json.get("respect", respect))
	entries.clear()
	by_id.clear()
	for c: Dictionary in json.get("cassettes", []):
		var e := c.duplicate(true)
		e["pos"] = Vector3.INF
		by_id[str(c["id"])] = entries.size()
		entries.append(e)
	ready_ok = true
	return true


## Each cassette on its landmark's roof (`roof_spot`: name -> Vector3, INF if none), then the mesh.
## Returns how many were placed; one without a roof is reported and left out.
func place_all(roof_spot: Callable) -> int:
	var n := 0
	for e in entries:
		var at: Vector3 = roof_spot.call(str(e["roof"]))
		if at == Vector3.INF:
			push_warning("cassettes: %s: no flat roof on %s" % [e["id"], e["roof"]])
			continue
		e["pos"] = at
		n += 1
		print("cassettes: %s on %s at %.0f, %.1f, %.0f" % [e["id"], e["roof"], at.x, at.y, at.z])
	_build()
	return n


## Where cassette `i` lies (Vector3.INF: not placed or unknown).
func at(i: int) -> Vector3:
	return entries[i]["pos"] if i >= 0 and i < entries.size() else Vector3.INF


func index_of(id: String) -> int:
	return by_id.get(id, -1)


func is_taken(id: String) -> bool:
	return wallet != null and wallet.cassettes.has(id)


## The pickup rule: the vehicle `flat` m from the cassette on the ground plane and `dy` m above it.
static func reached(flat: float, dy: float, flying: bool) -> bool:
	if flat >= REACH:
		return false
	if flying:
		return dy > -2.0 and dy < FLY_REACH
	return absf(dy) < CAR_DY


## The cassettes not taken, as one mesh (rebuilt after a pickup: a handful of boxes).
func _build() -> void:
	if world == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for e in entries:
		var p: Vector3 = e["pos"]
		if p == Vector3.INF or is_taken(str(e["id"])):
			continue
		any = true
		_cassette(st, p)
	if _node == null:
		_node = MeshInstance3D.new()
		_node.name = "Cassettes"
		_node.material_override = Models.material()
		_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(_node)
	_node.mesh = st.commit() if any else null
	_node.visible = any


## A cassette lying on the roof at `p` (a body, a label, two reels) and the diamond over it.
static func _cassette(st: SurfaceTool, p: Vector3) -> void:
	var w := CASSETTE
	var base := p + Vector3(0.0, 0.25, 0.0)
	Models.box(st, base, Vector3(w, 0.4, w * 0.62), COLOUR, Models.LIT_SIGN)
	Models.box(st, base + Vector3(0.0, 0.21, -w * 0.06), Vector3(w * 0.8, 0.03, w * 0.36), LABEL, Models.FIXED)
	for side in [-1.0, 1.0]:
		Models.box(st, base + Vector3(side * w * 0.2, 0.24, -w * 0.06), Vector3(w * 0.13, 0.04, w * 0.13), REEL, Models.FIXED)
	var cube := SurfaceTool.new()
	cube.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(cube, Vector3.ZERO, Vector3.ONE * MARKER_SIZE, COLOUR, Models.LIT_SIGN)
	var tilt := Basis(Vector3.RIGHT, atan(1.0 / sqrt(2.0))) * Basis(Vector3.FORWARD, PI * 0.25)
	st.append_from(cube.commit(), 0, Transform3D(tilt, p + Vector3(0.0, MARKER_UP, 0.0)))


func _process(dt: float) -> void:
	if not ready_ok or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var s: Array = probe.call()
	tick(s[0] as Vector3, bool(s[2]), bool(s[4]))
	spent_usec += Time.get_ticks_usec() - t0


## One look with the vehicle at `at` (`away`: the title screen or TEST · BENCH: nothing happens).
func tick(at: Vector3, flying := false, away := false) -> void:
	if away or wallet == null:
		return
	for e in entries:
		var p: Vector3 = e["pos"]
		if p == Vector3.INF or wallet.cassettes.has(e["id"]):
			continue
		if reached(Vector2(at.x - p.x, at.z - p.z).length(), at.y - p.y, flying):
			take(str(e["id"]))


## Cassette `id` taken: false if it was taken already (or is unknown). The save, the respect, the
## card, the blip and the buzz, and the next PÓŁNOC FM track (its toast is radio's).
func take(id: String) -> bool:
	if wallet == null or not by_id.has(id) or wallet.cassettes.has(id):
		return false
	var e: Dictionary = entries[by_id[id]]
	wallet.cassettes[id] = Districts.today()
	wallet.add_respect(respect)  # saves
	var name: Array = e.get("name", ["", ""])
	var line: Array = e.get("line", ["", ""])
	if hud != null:
		hud.show_note(Lang.pick("KASETA Z MUZYKĄ", "MIXTAPE"), "%s\n%s" % [Lang.pick(name[0], name[1]), Lang.pick(line[0], line[1])], COLOUR)
	if blip.is_valid():
		blip.call()
	Access.buzz(40, 0.4)
	var n := 0
	if radio != null:
		n = radio.next_locked()
		if n > 0:
			radio.unlock_track(n, "cassette")
	_build()
	print("cassettes: took %s (%d/%d), +%d respect, PÓŁNOC FM track %s" % [id, wallet.cassettes.size(), entries.size(), respect,
			str(n) if n > 0 else "none left"])
	return true
