extends SceneTree
## Loop MW-6 (docs/design/vision.md 4.4): KASETA, the time tape (tape.gd), headless, from the
## committed map data (map/centrum.json; index.json if that is missing) for the places:
##   - the 20 then cards: Polish and English lines, each at most 70 characters, a year from 2010,
##     a place in places.json that the notebook puts on the map;
##   - each spot's ghost: 3 to 24 boxes, built as one mesh of one surface (one draw call) with
##     the buildings' shader in a material of its own, no shadow, hidden until the tape plays;
##     its boxes within 250 m of the spot;
##   - the ghost is built only within 150 m of a spot, kept to 200 m, dropped past it, and none
##     is built anywhere else (a walk over the map's grid: every point with a ghost is within 150 m
##     of its spot, or 200 m of one built on the way in);
##   - the context button (KASETA) within 40 m, slow, on the ground; not flying, not fast;
##   - a play shows the ghost and logs `tape: n ... ghost ok`; the first play pays +15 respect and
##     stamps the card, the second pays nothing; the ghost hides again after it has faded;
##   - the ghost's dither: the share kept follows the fade (0 when hidden, KEEP at full).
## Prints `check_tape: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_tape.gd [-- --verbose]

const Sfx := preload("res://scripts/sfx.gd")
const Tape := preload("res://scripts/tape.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Wallet := preload("res://scripts/wallet.gd")
const HudScript := preload("res://scripts/hud.gd")
const Fakes := preload("res://tools/fakes.gd")
const MAX_PL := 70

var problems: Array[String] = []
var verbose := false


## The shared HUD, with the context button's priority rule as hud.gd has it (`pill_free_for`).
class TapeHud extends Fakes.Hud:
	func pill_free_for(who: String) -> bool:
		return pill == "" or HudScript.pill_outranks(who, pill)


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		path = "res://map/index.json"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		print("check_tape: no map data (%s)" % path)
		quit(1)
		return
	var book: Notebook = Notebook.new()
	root.add_child(book)
	book.setup(data)
	var places := {}
	for p: Dictionary in book.places:
		places[str(p["id"])] = p["at"]
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var hud := TapeHud.new()
	root.add_child(hud)
	var tape: Tape = Tape.new()
	tape.wallet = wallet
	tape.hud = hud
	root.add_child(tape)
	if not tape.setup(places):
		print("check_tape: no data/then_cards.json")
		quit(1)
		return
	# No sound in the check: with a real audio driver (the Mac) the rewind's playbacks outlived
	# the player and leaked a WAV and two playbacks at exit. The rewind is an interface sound of
	# the one-shot door now (Sfx.ui), which never plays a name without a stream.
	Sfx.ui_add("rewind", null, -80.0)
	_check_cards(tape, book)
	var most := _check_ghosts(tape)
	var built := _check_reach(tape, data)
	_check_play(tape, wallet, hud)
	var n := tape.spots.size()
	tape.free()
	hud.free()
	wallet.free()
	book.free()
	# Let the ghosts queued for deletion go before quitting.
	for _i in 3:
		await process_frame
	if problems.is_empty():
		print("check_tape: OK (%d then cards placed, ghosts of 3-%d boxes, one draw call each, built only within %d m: %d points of the grid walk had one)" % [
				n, most, int(Tape.BUILD_REACH), built])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_tape: %d problems" % problems.size())
		quit(1)


func _check_cards(tape: Tape, book: Notebook) -> void:
	if tape.spots.size() != 20:
		problems.append("%d then cards, want 20" % tape.spots.size())
	for s in tape.spots:
		var id := str(s["id"])
		var line: Array = s.get("line", [])
		if line.size() != 2 or str(line[0]) == "" or str(line[1]) == "":
			problems.append("%s: no Polish and English line" % id)
		elif str(line[0]).length() > MAX_PL:
			problems.append("%s: the Polish line is %d characters" % [id, str(line[0]).length()])
		if int(s.get("year", 0)) < 2010:
			problems.append("%s: the year %s is before 2010 (the user's answer 3)" % [id, s.get("year")])
		if not book.by_id.has(str(s["place"])):
			problems.append("%s: its place %s isn't in places.json" % [id, s["place"]])
		elif s["at"] == Vector2.INF:
			problems.append("%s: not placed" % id)


func _check_ghosts(tape: Tape) -> int:
	var most := 0
	for i in tape.spots.size():
		var s := tape.spots[i]
		var id := str(s["id"])
		var boxes := Tape.ghost_boxes(id)
		most = maxi(most, boxes.size())
		if boxes.size() < 3 or boxes.size() > Tape.MAX_BOXES:
			problems.append("%s: %d ghost boxes (3 to %d)" % [id, boxes.size(), Tape.MAX_BOXES])
		for b: Array in boxes:
			if Vector2(float(b[0]), float(b[1])).length() > 250.0:
				problems.append("%s: a box %.0f m from its spot" % [id, Vector2(float(b[0]), float(b[1])).length()])
			if float(b[2]) <= 0.0 or float(b[3]) <= 0.0 or float(b[4]) <= 0.0:
				problems.append("%s: a box of no size %s" % [id, b])
		var mesh := tape.ghost_mesh(i)
		if mesh.get_surface_count() != 1:
			problems.append("%s: the ghost has %d surfaces (one draw call wants one)" % [id, mesh.get_surface_count()])
		elif mesh.surface_get_array_len(0) != mini(boxes.size(), Tape.MAX_BOXES) * 36:
			problems.append("%s: %d vertices for %d boxes" % [id, mesh.surface_get_array_len(0), boxes.size()])
		if verbose:
			print("  %d %s: %d boxes at %.0f, %.0f" % [i + 1, id, boxes.size(), s["at"].x, s["at"].y])
	return most


## The ghost appears only near a spot: a 50 m grid walk over the map, row by row.
func _check_reach(tape: Tape, data: Dictionary) -> int:
	var b: Array = data["bounds"]
	var with_ghost := 0
	for zi in range(int(b[1]), int(b[3]), 50):
		var z := float(zi)
		var xs := range(int(b[0]), int(b[2]), 50)
		if (zi / 50) % 2 == 1:
			xs.reverse()
		for xi: int in xs:
			var p := Vector3(float(xi), 0.0, z)
			tape.tick(p, 40.0, false, false)
			if tape.near < 0:
				continue
			with_ghost += 1
			var d := Vector2(p.x, p.z).distance_to(tape.spots[tape.near]["at"])
			if d > Tape.DROP_REACH + 0.5:
				problems.append("a ghost (%s) %.0f m from its spot at %.0f, %.0f" % [tape.spots[tape.near]["id"], d, p.x, p.z])
			if tape.ghost == null or tape.ghost.visible:
				problems.append("ghost %s: not built hidden at %.0f, %.0f" % [tape.spots[tape.near]["id"], p.x, p.z])
			elif tape.ghost.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				problems.append("ghost %s casts a shadow" % tape.spots[tape.near]["id"])
		# Off the map between rows: nothing.
	tape.tick(Vector3(100000.0, 0.0, 100000.0), 0.0, false, false)
	if tape.near >= 0:
		problems.append("a ghost is still built 100 km away")
	return with_ghost


func _check_play(tape: Tape, wallet: Wallet, hud: TapeHud) -> void:
	var i := tape.index_of("t_defilad_2012")
	var at: Vector2 = tape.spots[i]["at"]
	var p := Vector3(at.x + 10.0, 0.0, at.y)
	tape.tick(p, 40.0, false, false)
	if hud.pill_shown("tape"):
		problems.append("the KASETA button at 40 km/h")
	tape.tick(p, 3.0, true, false)
	if hud.pill_shown("tape"):
		problems.append("the KASETA button in the helicopter")
	tape.tick(p, 3.0, false, false)
	if not hud.pill_shown("tape"):
		problems.append("no KASETA button 10 m from %s, slow" % tape.spots[i]["id"])
	tape.tick(Vector3(at.x + 60.0, 0.0, at.y), 3.0, false, false)
	if hud.pill_shown("tape"):
		problems.append("the KASETA button 60 m away")
	tape.tick(p, 3.0, false, false)
	var before := wallet.respect
	tape.on_context("tape")
	if not tape.playing() or tape.ghost == null or not tape.ghost.visible:
		problems.append("the tape didn't play from the button")
	if wallet.respect - before != Tape.RESPECT or not wallet.tapes.has("t_defilad_2012"):
		problems.append("the first play paid %d respect (want %d) and stamped %s" % [wallet.respect - before, Tape.RESPECT, wallet.tapes])
	if hud.notes.is_empty() or not str(hud.note_titles[-1]).begins_with("KASETA · 2012"):
		problems.append("no then card shown (%s)" % [hud.notes])
	# The dither follows the fade: nothing kept at the start, KEEP at full.
	var keep0 := _kept(tape)
	for k in 120:
		tape._play_frame(1.0 / 30.0)
	var keep_full := _kept(tape)
	if keep0 > 0.02 or absf(keep_full - Tape.KEEP) > 0.02:
		problems.append("the ghost's kept share %.2f at the start, %.2f at full (want 0, %.2f)" % [keep0, keep_full, Tape.KEEP])
	for k in int(Tape.SHOW_S * 30.0) + 30:
		tape._play_frame(1.0 / 30.0)
	if tape.playing() or tape.ghost.visible:
		problems.append("the ghost still shows after %.0f s" % Tape.SHOW_S)
	var mid := wallet.respect
	tape.play(i)
	if wallet.respect != mid:
		problems.append("the second play paid again")


## The share of pixels the ghost keeps now (ghost.gdshaderinc: 1 - fade, ghost_keep 0).
func _kept(tape: Tape) -> float:
	var m: ShaderMaterial = tape.get("_mat")
	var occ: Vector4 = m.get_shader_parameter("occluder")
	var at: Vector2 = tape.spots[tape.near]["at"]
	var side := (at.y - occ.y) * occ.w
	var x := clampf((-side - 1.0) / 3.0, 0.0, 1.0)
	var fade := x * x * (3.0 - 2.0 * x)
	return 1.0 - fade
