extends SceneTree
## The checks' shared stand-ins (tech-debt TD-11, game/tools/fakes.gd) stay true to the game and stay shared.
##
##   A the arguments: every function of a stand-in that the game's own script has too (Fakes.Hud and hud.gd,
##     Fakes.Dialogue and dialogue.gd, Fakes.Bubbles and bubbles.gd, Fakes.Wallet and wallet.gd, Fakes.Calls and
##     missions.gd, Fakes.FlatMap and map_builder.gd, Fakes.Car and car.gd) takes as many arguments as the game's,
##     as many of them with a default, of the same types, and answers with the same type; the same for a signal.
##     A function a stand-in has and the game's script does not is one of the stand-in's own (OWN) or a problem
##     (the game's was renamed or taken out). So a new parameter on `hud.toast` fails this step, with the
##     function's name, and is put right in one place;
##   B no private copies: no script under res://tools writes its own class with a function of the HUD's (a toast,
##     a card, a note, the status line, the context button, the minimap's route or pins), or one that speaks
##     (`say`, `say_ambient`, `say_reaction`: the dialogue's and the bubbles'), or one of the map's (a height, a
##     roof, a tunnel, the shore, the map's edge), unless the class extends one of fakes.gd's. A class that does
##     extend one may add a function the game's script has and the stand-in has not (a shore, the map's edge:
##     the game asks a map for those only when it has them, so the shared flat map must not): that function
##     must take the game's arguments too, read from its line (an argument written `name := value` has the type of
##     its value, as the engine gives it). The private ones still left are named in LEFT
##     with the reason; a name there that is no longer a private stand-in gives a `fakes: WARN` line (the
##     step's row warns until the name is taken off the list: the change that moved the class is not held up
##     by this list);
##   C the stand-ins remember what they are given: the HUD's toasts, small toasts, notes and cards in both
##     languages and in step; the card's owner and a press; the dialogue's lines with their group, tag, class
##     and key, what `say` and `line` answer, `count`; the bubbles' budget (`ok`, `allows`, `muted`); the flat
##     map's answers and what it must not have.
##
##   godot --headless --path game --script res://tools/check_fakes.gd

const Fakes := preload("res://tools/fakes.gd")
const Chatter := preload("res://scripts/chatter.gd")

## A stand-in's name, and the game's script it stands for.
const PAIRS := [
	["Hud", "res://scripts/hud.gd"],
	["Dialogue", "res://scripts/dialogue.gd"],
	["Bubbles", "res://scripts/bubbles.gd"],
	["Wallet", "res://scripts/wallet.gd"],
	["Calls", "res://scripts/missions.gd"],
	["FlatMap", "res://scripts/map_builder.gd"],
	["Car", "res://scripts/car.gd"],
	["BuilderMap", "res://scripts/map_builder.gd"],
	["Radio", "res://scripts/radio.gd"],
	["Sfx", "res://scripts/sfx.gd"],
	["CitySounds", "res://scripts/city_sounds.gd"],
	["Walkers", "res://scripts/pedestrians.gd"],
	["Tape", "res://scripts/tape.gd"],
]
## The engine's own functions a script may give (`_init`, `_ready`...): a stand-in's and the game's need not
## take the same. Every other function whose name begins with `_` is compared when the game's script has it
## too (the builders call map_builder.gd's `_solid` and `_roof_triangle`), and is a helper of the stand-in's
## when it has not.
const VIRTUALS := ["_init", "_ready", "_process", "_physics_process", "_enter_tree", "_exit_tree", "_notification",
		"_input", "_unhandled_input", "_draw", "_to_string", "_get", "_set", "_get_property_list"]
## The functions that are a stand-in's own (a check calls them; the game's script has no such function).
const OWN := {
	"Hud": ["press"],
	"Dialogue": ["count", "forget"],
	"Calls": ["put"],
}
## The functions that make a class a stand-in for the HUD, and for the dialogue or the bubbles.
const HUD_MARKS := ["toast", "ambient_toast", "show_note", "show_card", "show_side_card", "show_call", "show_status",
		"show_pill", "show_banner", "show_challenge", "set_minimap_route", "set_minimap_pois", "set_minimap_dots",
		"set_quest_dots"]
const TALK_MARKS := ["say", "say_ambient", "say_reaction"]
## The functions that make a class a stand-in for the map (map_builder.gd).
const MAP_MARKS := ["ground_height", "terrain_height", "deck_height", "tunnel_height", "roof_height", "top_height",
		"in_tunnel", "shore_distance", "in_map", "sunk_floor", "tunnel_floor_under"]
## The functions that make a class a stand-in for the radio, the sound effects, the city's sounds, the walkers
## and the tape (radio.gd, sfx.gd, city_sounds.gd, pedestrians.gd, tape.gd; group 3).
const SOUND_MARKS := ["announce", "tune", "station_index", "next_locked", "unlock_track", "host_moment", "play_at",
		"soften_engine", "add_crowd"]
const WALKER_MARKS := ["set_stop", "clear_stop", "set_scene", "clear_scene", "startle", "stamp"]
## The functions only a map the builders see has (map_builder.gd's own, which landmarks.gd, the place scripts and
## the facade kit call; group 3): a class with one of them stands in for that map even with no height.
const BUILDER_MARKS := ["_solid", "_roof_triangle", "_grid_height", "platform_top"]
## The private stand-ins still left, by file. The racer work has its checks in hand (2026-11-13): each moves
## to fakes.gd with that work's next change to the check.
const LEFT := {
	"check_police.gd": ["FakeHud", "FakeBubbles", "FakeMap", "FakeRadio"],
	"check_crazy_drivers.gd": ["FakeBubbles", "FakeMap", "FakeSfx"],
	"check_ladder.gd": ["FakeMap"],
	"check_race_cuts.gd": ["FakeMap"],
	"check_race_links.gd": ["FakeMap"],
	"check_street_meet.gd": ["FakeMap", "PlayMap"],
	"race_bench.gd": ["FakeMap"],
}
## The types a function's line can name that the engine reports by the same word.
const PLAIN_TYPES := ["bool", "int", "float", "String", "Vector2", "Vector3", "Rect2", "Color", "Dictionary", "Array",
		"PackedFloat32Array", "PackedVector2Array", "PackedVector3Array", "Callable"]
const TOOLS := "res://tools"

var _facts := 0
var _problems := 0


func _initialize() -> void:
	var a := _arguments()
	var b := _private_copies()
	_maps()
	_remember()
	_group3()
	if _problems == 0:
		var named := 0
		for f: String in LEFT:
			named += (LEFT[f] as Array).size()
		print("check_fakes: OK (%d facts: %d functions and %d signals of %d stand-ins take the game's arguments; %d scripts under tools read, %d functions a check adds to a stand-in compared, %d private stand-ins left of the %d named)" % [
				_facts, a[0], a[1], PAIRS.size(), b[0], b[2], b[1], named])
		quit(0)
	else:
		print("check_fakes: FAILED (%d of %d facts)" % [_problems, _facts])
		quit(1)


func _ok(fact: bool, what: String) -> void:
	_facts += 1
	if not fact:
		_problems += 1
		print("problem: %s" % what)


# --- A: the arguments ------------------------------------------------------------------------

## [functions compared, signals compared].
func _arguments() -> Array:
	var functions := 0
	var signals := 0
	var consts: Dictionary = (Fakes as GDScript).get_script_constant_map()
	for pair: Array in PAIRS:
		var who := String(pair[0])
		var path := String(pair[1])
		var fake := consts.get(who) as GDScript
		var real := load(path) as GDScript
		_ok(fake != null, "A fakes.gd has no class %s" % who)
		_ok(real != null, "A %s did not load" % path)
		if fake == null or real == null:
			continue
		var theirs := {}
		for m: Dictionary in real.get_script_method_list():
			theirs[String(m["name"])] = m
		# A script that does not compile loads with no functions: one line for it, not one for each function.
		_ok(not theirs.is_empty(), "A %s loaded with no functions (it does not compile?): nothing of Fakes.%s was compared" % [path.get_file(), who])
		if theirs.is_empty():
			continue
		var own: Array = OWN.get(who, [])
		var seen_own := {}
		for m: Dictionary in fake.get_script_method_list():
			var name := String(m["name"])
			if name.begins_with("@") or name in VIRTUALS:  # a property's getter, or the engine's own
				continue
			if name.begins_with("_") and not theirs.has(name):  # the stand-in's helper
				continue
			if not theirs.has(name):
				seen_own[name] = true
				_ok(name in own, "A Fakes.%s.%s: %s has no such function (renamed or taken out? a stand-in's own function is named in OWN)" % [
						who, name, path.get_file()])
				continue
			functions += 1
			_ok(not (name in own), "A Fakes.%s.%s is named as the stand-in's own, and %s has it too" % [who, name, path.get_file()])
			var diff := _differs(m, theirs[name])
			_ok(diff == "", "A Fakes.%s.%s does not take what %s's does: %s" % [who, name, path.get_file(), diff])
		for name: String in own:
			_ok(seen_own.has(name), "A OWN names Fakes.%s.%s, which the stand-in does not have" % [who, name])
		var their_signals := {}
		for s: Dictionary in real.get_script_signal_list():
			their_signals[String(s["name"])] = s
		for s: Dictionary in fake.get_script_signal_list():
			var name := String(s["name"])
			signals += 1
			if not their_signals.has(name):
				_ok(false, "A Fakes.%s's signal %s: %s has no such signal" % [who, name, path.get_file()])
				continue
			var mine: Array = s["args"]
			var other: Array = their_signals[name]["args"]
			_ok(mine.size() == other.size(), "A Fakes.%s's signal %s carries %d values, %s's %d" % [who, name, mine.size(), path.get_file(), other.size()])
	_ok(functions >= 45, "A only %d functions compared (the stand-ins had 57 of the game's on 2026-11-13)" % functions)
	return [functions, signals]


## "" when the stand-in's function `mine` takes and answers what the game's `other` does, else what differs.
func _differs(mine: Dictionary, other: Dictionary) -> String:
	var a: Array = mine["args"]
	var b: Array = other["args"]
	if a.size() != b.size():
		return "%d arguments, the game's %d" % [a.size(), b.size()]
	var da: Array = mine["default_args"]
	var db: Array = other["default_args"]
	if da.size() != db.size():
		return "%d arguments with a default, the game's %d" % [da.size(), db.size()]
	# The defaults themselves (group 3): a call that leaves one out gets the game's value, so the stand-in records
	# what the game would have been given (`unlock_track(n)` is an egg's).
	for i in da.size():
		var same: bool = typeof(da[i]) == typeof(db[i]) and (da[i] == db[i] or (da[i] is float and is_nan(da[i]) and is_nan(db[i])))
		if not same:
			var k := a.size() - da.size() + i
			return "argument %d (%s) defaults to %s, the game's (%s) to %s" % [k + 1, a[k]["name"], var_to_str(da[i]), b[k]["name"], var_to_str(db[i])]
	for i in a.size():
		if int(a[i]["type"]) != int(b[i]["type"]):
			return "argument %d (%s) is %s, the game's (%s) %s" % [i + 1, a[i]["name"], type_string(int(a[i]["type"])),
					b[i]["name"], type_string(int(b[i]["type"]))]
	if int(mine["return"]["type"]) != int(other["return"]["type"]):
		return "answers %s, the game's %s" % [type_string(int(mine["return"]["type"])), type_string(int(other["return"]["type"]))]
	return ""


# --- B: no private copies --------------------------------------------------------------------

## [scripts read, private stand-ins left].
func _private_copies() -> Array:
	var head := RegEx.create_from_string("^class\\s+(\\w+)(?:\\s+extends\\s+([\\w.]+))?\\s*:")
	var inner_extends := RegEx.create_from_string("^\\textends\\s+([\\w.]+)")
	var function := RegEx.create_from_string("^\\tfunc\\s+(\\w+)\\s*\\(")
	var files: Array[String] = []
	for f in DirAccess.get_files_at(TOOLS):
		if f.ends_with(".gd") and f != "fakes.gd":
			files.append(f)
	files.sort()
	_ok(files.size() >= 100, "B only %d scripts under %s" % [files.size(), TOOLS])
	var left := 0
	var added := 0
	var found := {}
	for f in files:
		var lines := FileAccess.get_file_as_string("%s/%s" % [TOOLS, f]).split("\n")
		# The file's classes: name -> [what it extends, its functions].
		var classes := {}
		var i := 0
		while i < lines.size():
			var m := head.search(lines[i])
			if m == null:
				i += 1
				continue
			var base := m.get_string(2)
			var functions: Array[String] = []
			var heads := {}
			var j := i + 1
			while j < lines.size() and (lines[j].begins_with("\t") or lines[j].strip_edges() == ""):
				var e := inner_extends.search(lines[j])
				if e != null and base == "":
					base = e.get_string(1)
				var fn := function.search(lines[j])
				if fn != null:
					functions.append(fn.get_string(1))
					heads[fn.get_string(1)] = lines[j]
				j += 1
			classes[m.get_string(1)] = [base, functions, heads]
			i = j
		for name: String in classes:
			var marks: Array[String] = []
			for fn: String in classes[name][1]:
				if fn in HUD_MARKS or fn in TALK_MARKS or fn in MAP_MARKS or fn in SOUND_MARKS or fn in WALKER_MARKS or fn in BUILDER_MARKS:
					marks.append(fn)
			var of := _shared_class(name, classes)
			if of != "":
				added += _added(f, name, of, classes[name][2])
				continue
			if marks.is_empty():
				continue
			found["%s:%s" % [f, name]] = true
			var allowed: Array = LEFT.get(f, [])
			if name in allowed:
				left += 1
			else:
				_ok(false, "B %s writes its own stand-in %s (%s): take fakes.gd's, and extend it for what only this check needs" % [
						f, name, ", ".join(marks)])
	for f: String in LEFT:
		for name: String in LEFT[f]:
			_facts += 1
			if not found.has("%s:%s" % [f, name]):
				print("fakes: WARN LEFT names %s in %s, which is no longer a private stand-in: take it off the list in check_fakes.gd" % [name, f])
	return [files.size(), left, added]


## The class of fakes.gd that the class extends, itself or through another class of its file ("" if none).
func _shared_class(name: String, classes: Dictionary) -> String:
	var hops := 0
	var at := name
	while classes.has(at) and hops < 8:
		var base := String(classes[at][0])
		if base.begins_with("Fakes."):
			return base.trim_prefix("Fakes.")
		at = base
		hops += 1
	return ""


## A class that extends fakes.gd's `of`: each function it adds (one the stand-in has not) that the game's
## script has too must take the game's arguments, as its line `heads[name]` writes them. A function the
## stand-in has is held by the engine (an override must take what its parent's takes) and by part A.
## Answers how many such functions were compared.
func _added(file: String, cls: String, of: String, heads: Dictionary) -> int:
	var path := ""
	for pair: Array in PAIRS:
		if String(pair[0]) == of:
			path = String(pair[1])
	var fake := ((Fakes as GDScript).get_script_constant_map().get(of)) as GDScript
	if path == "" or fake == null:
		return 0
	var mine := {}
	for m: Dictionary in fake.get_script_method_list():
		mine[String(m["name"])] = true
	var n := 0
	for m: Dictionary in (load(path) as GDScript).get_script_method_list():
		var name := String(m["name"])
		if not heads.has(name) or mine.has(name) or name == "_init":
			continue
		n += 1
		var diff := _line_differs(String(heads[name]), m)
		_ok(diff == "", "B %s's %s (it extends Fakes.%s) adds %s, which %s has too, and does not take what the game's does: %s" % [
				file, cls, of, name, path.get_file(), diff])
	return n


## "" when the function written on `line` takes and answers what the game's `other` does, else what differs.
## The count of arguments and of defaults always; a type where the line names a plain one.
func _line_differs(line: String, other: Dictionary) -> String:
	var open := line.find("(")
	var close := line.rfind(")")
	if open < 0 or close < open:
		return "its line could not be read (keep the function's head on one line)"
	var args: Array[String] = []
	var depth := 0
	var word := ""
	for c in line.substr(open + 1, close - open - 1):
		if c in "([{":
			depth += 1
		elif c in ")]}":
			depth -= 1
		if c == "," and depth == 0:
			args.append(word.strip_edges())
			word = ""
		else:
			word += c
	if word.strip_edges() != "":
		args.append(word.strip_edges())
	var b: Array = other["args"]
	if args.size() != b.size():
		return "%d arguments, the game's %d" % [args.size(), b.size()]
	var defaults := 0
	for i in args.size():
		var eq := args[i].find("=")
		if eq >= 0:
			defaults += 1
		var colon := args[i].find(":")
		if colon < 0:
			continue  # no type written: the engine takes anything
		var type := ""
		if eq >= 0 and colon == eq - 1:
			type = _literal_type(args[i].substr(eq + 1).strip_edges())  # `:=`: the type the engine works out
		else:
			type = args[i].substr(colon + 1, (eq if eq >= 0 else args[i].length()) - colon - 1).strip_edges()
		var theirs := type_string(int(b[i]["type"]))
		if type in PLAIN_TYPES and theirs in PLAIN_TYPES and type != theirs:
			return "argument %d (%s) is %s, the game's (%s) %s" % [i + 1, args[i].substr(0, colon).strip_edges(), type, b[i]["name"], theirs]
	if defaults != (other["default_args"] as Array).size():
		return "%d arguments with a default, the game's %d" % [defaults, (other["default_args"] as Array).size()]
	var arrow := line.find("->", close)
	if arrow >= 0:
		var answers := line.substr(arrow + 2).strip_edges().trim_suffix(":").strip_edges()
		var theirs := type_string(int(other["return"]["type"]))
		if answers in PLAIN_TYPES and theirs in PLAIN_TYPES and answers != theirs:
			return "answers %s, the game's %s" % [answers, theirs]
	return ""


## The type the engine gives an argument written `name := value`, read from the value ("" when it is not a
## plain literal: then the argument is not compared).
func _literal_type(value: String) -> String:
	if value in ["true", "false"]:
		return "bool"
	if value.begins_with("\"") or value.begins_with("'"):
		return "String"
	if value.trim_prefix("-") in ["INF", "NAN"]:
		return "float"
	if value.trim_prefix("-").is_valid_int():
		return "int"
	if value.trim_prefix("-").is_valid_float():
		return "float"
	for type in ["Vector2", "Vector3", "Rect2", "Color", "Callable", "PackedFloat32Array", "PackedVector2Array",
			"PackedVector3Array"]:
		if value.begins_with(type + "("):
			return type
	if value.begins_with("{"):
		return "Dictionary"
	if value.begins_with("["):
		return "Array"
	return ""


# --- C: the stand-ins remember what they are given -------------------------------------------

class Owner:
	var pressed: Array[int] = []
	func card_pressed(i: int) -> void:
		pressed.append(i)


func _remember() -> void:
	var hud := Fakes.Hud.new()
	hud.toast("Raz", "One")
	hud.toast("Dwa")
	hud.toast("Trzy", "Three", 4)
	_ok(hud.toasts == ["Raz", "Dwa", "Trzy"] and hud.toasts_en == ["One", "", "Three"], "C the toasts and their English: %s / %s" % [hud.toasts, hud.toasts_en])
	hud.ambient_toast("Mały", "Small")
	hud.ambient_toast("Drugi")
	_ok(hud.ambient == ["Mały", "Drugi"] and hud.ambient_en == ["Small", ""] and hud.toasts.size() == 3,
			"C the small toasts and their English, apart from the toasts: %s / %s" % [hud.ambient, hud.ambient_en])
	hud.show_note("Odkryto: Powiśle", "Nad rzeką", Color.RED)
	hud.show_note("KASETA", "2012", Color.BLUE, 3)
	_ok(hud.notes == ["Odkryto: Powiśle: Nad rzeką", "KASETA: 2012"] and hud.note_titles == ["Odkryto: Powiśle", "KASETA"]
			and hud.note_texts == ["Nad rzeką", "2012"], "C the notes, their titles and texts: %s / %s / %s" % [hud.notes, hud.note_titles, hud.note_texts])
	_ok(hud.card == "" and not hud.card_showing() and not hud.cards_up() and hud.shown == 0 and hud.cards.is_empty(), "C a new HUD has a card up")
	hud.show_card("Karta", "Tekst", PackedStringArray(["TAK|YES", "NIE|NO"]), Color.GREEN, true, "Card", "Text", true)
	_ok(hud.card == "Karta" and hud.body == "Tekst" and hud.buttons == 2 and hud.button_words == PackedStringArray(["TAK|YES", "NIE|NO"])
			and hud.button_words_en == PackedStringArray(["YES", "NO"]) and hud.low and hud.stacked and not hud.side
			and hud.card_en == "Card" and hud.body_en == "Text" and hud.accent == Color.GREEN and hud.card_showing() and hud.cards_up(),
			"C a card: %s / %s / %s" % [hud.card, hud.body, hud.button_words])
	var owner := Owner.new()
	var heard: Array[int] = []
	hud.card_pressed.connect(func(i: int) -> void: heard.append(i))
	hud.press(1)
	_ok(heard == [1] and hud.broadcast == 1 and owner.pressed.is_empty(), "C a press with no owner goes to every listener: %s" % [heard])
	hud.own_card(owner)
	hud.press(0)
	_ok(owner.pressed == [0] and heard == [1] and hud.card_is(owner) and not hud.card_is(self), "C a press goes to the card's owner only: %s / %s" % [owner.pressed, heard])
	hud.show_side_card("Druga", "Obok", PackedStringArray(["OK"]), Color.WHITE, "Second", "Beside", false, "mati")
	_ok(hud.card == "Druga" and hud.side and hud.face == "mati" and not hud.low and not hud.card_is(owner) and hud.shown == 2
			and hud.cards == ["Karta", "Druga"], "C a side card takes the first one's place and its owner: %s, cards %s" % [hud.card, hud.cards])
	hud.show_call("Mati", "Przyjedź", Color.WHITE, "Come over", "mati")
	_ok(hud.card.contains("MATI") and hud.buttons == 2 and hud.shown == 3 and hud.cards.size() == 3 and hud.cards[2] == hud.card,
			"C a call is a card too: %s, cards %s" % [hud.card, hud.cards])
	hud.hide_card()
	_ok(hud.card == "" and hud.buttons == 0 and not hud.card_showing() and hud.cards.size() == 3, "C the card taken down: '%s', cards %s" % [hud.card, hud.cards])
	hud.notebook_changed()
	hud.notebook_changed()
	_ok(hud.notebook_changes == 2, "C the notebook's mark asked for twice: %d" % hud.notebook_changes)
	hud.free()

	var d := Fakes.Dialogue.new()
	_ok(d.say(self, "Mati", "mati", "hello") == [] and d.said == ["mati:hello"], "C a new dialogue's `say` answers [] and remembers the line: %s" % [d.said])
	d.say_words = ["Cześć", "Hi"]
	var words := d.say(self, "Mati", "mati", "bye", 3.0, Color.RED, 2.0, true)
	_ok(words == ["Cześć", "Hi"], "C `say` answers `say_words`: %s" % [words])
	d.say_ambient(self, "Pies", "dog_walkers", "horn")
	d.say_reaction(self, "Kierowca", "drivers", "bump", 4.0, Color.WHITE, 2.6, false, "bump")
	_ok(d.said == ["mati:hello", "mati:bye", "dog_walkers:horn", "drivers:bump"] and d.groups == ["mati", "mati", "dog_walkers", "drivers"]
			and d.tags == ["hello", "bye", "horn", "bump"] and d.speakers == ["Mati", "Mati", "Pies", "Kierowca"],
			"C the lines, their groups, tags and speakers in step: %s / %s / %s / %s" % [d.said, d.groups, d.tags, d.speakers])
	_ok(d.kinds == [Chatter.QUEST, Chatter.QUEST, Chatter.AMBIENT, Chatter.REACTION] and d.keys == ["", "", "", "bump"],
			"C each line's class and key: %s / %s" % [d.kinds, d.keys])
	_ok(d.hows.size() == 4 and d.hows[1] == [3.0, Color.RED, 2.0, true] and d.anchors.size() == 4, "C how a line was said: %s" % [d.hows])
	_ok(d.line("mati", "hello") == ["…", "…"] and d.line("mati", "card", true) == ["…", "…"] and d.line_asks == ["mati:hello", "mati:card"]
			and d.line_prefers == [false, true] and d.said.size() == 4, "C `line` answers the words and remembers the ask, apart from what was said: %s" % [d.line_asks])
	_ok(d.count("mati", "hello") == 2 and d.count("mati", "bye") == 1 and d.count("mati", "card") == 1 and d.count("mati", "") == 0
			and d.count("dog_walkers", "horn") == 1, "C `count`: a line said and taken as words counts twice, one never said not at all")
	d.no_lines = true
	_ok(d.line("mati", "hello") == [], "C `no_lines`: the bag is empty")
	d.forget()
	_ok(d.said.is_empty() and d.groups.is_empty() and d.tags.is_empty() and d.kinds.is_empty() and d.keys.is_empty() and d.anchors.is_empty()
			and d.speakers.is_empty() and d.hows.is_empty() and d.line_asks.is_empty() and d.line_prefers.is_empty() and d.count("mati", "hello") == 0
			and d.say_words == ["Cześć", "Hi"], "C `forget` empties every record and keeps the words `say` answers")
	d.free()

	var b := Fakes.Bubbles.new()
	_ok(b.say(self, "Mati", "Cześć", "Hi", 2.0, Color.RED) and b.allows(Chatter.AMBIENT) and not b.muted(), "C a new bubbles' budget lets a line out")
	_ok(b.say_ambient(self, "Pies", "Hau") and b.say_reaction(self, "Kierowca", "Ej!", "Hey!", 4.0, Color.WHITE, 2.6, "bump"),
			"C the ambient and the reaction bubble show")
	_ok(b.said == ["Cześć", "Hau", "Ej!"] and b.kinds == [Chatter.QUEST, Chatter.AMBIENT, Chatter.REACTION] and b.keys == ["", "", "bump"]
			and b.durations == [2.0, 4.0, 4.0] and b.colours[0] == Color.RED, "C the bubbles, their classes and keys in step: %s / %s / %s" % [b.said, b.kinds, b.keys])
	b.ok = false
	b.mute = true
	_ok(not b.say(self, "Mati", "Nie") and not b.say_ambient(self, "Pies", "Nie") and not b.allows(Chatter.QUEST) and b.muted()
			and b.said.size() == 3, "C a budget that refuses: nothing shows and nothing is remembered: %s" % [b.said])
	b.free()


## C, the maps: the flat map is flat and has no shore or edge.
func _maps() -> void:
	var map := Fakes.FlatMap.new()
	_ok(map.ground_height(3.0, -4.0) == 0.0 and map.terrain_height(3.0, -4.0) == 0.0 and map.deck_height(2, 3.0, -4.0) == 0.0
			and map.tunnel_height(1, 3.0, -4.0) == 0.0 and map.top_height(3.0, -4.0) == 0.0 and map.top_height(3.0, -4.0, 2.0) == 0.0
			and not map.in_tunnel(3.0, -4.0, -5.0), "C the flat map is not flat, or has a tunnel")
	_ok(map.roof_height(3.0, -4.0) == -1000.0, "C a new flat map has a roof over a point: %.1f" % map.roof_height(3.0, -4.0))
	map.roof_level = -INF
	_ok(map.roof_height(3.0, -4.0) == -INF, "C `roof_level` is not what `roof_height` answers: %.1f" % map.roof_height(3.0, -4.0))
	# The game asks a map for its shore and its edge only when it has them (landmarks.gd, lane_graph.gd): a
	# flat map that had them would change what every check on it plays.
	_ok(not map.has_method("shore_distance") and not map.has_method("in_map") and not ("bounds" in map),
			"C the flat map has a shore or an edge (`shore_distance`, `in_map`, `bounds`): a check that needs one adds it in its own class")
	map.free()


## C, group 3: the builders' map, the radio, the sound effects, the city's sounds, the walkers and the tape.
func _group3() -> void:
	var map := Fakes.BuilderMap.new()
	_ok(map.ground_height(3.0, -4.0) == 0.0 and map.terrain_height(3.0, -4.0) == 0.0 and map._grid_height(3.0, -4.0) == 0.0
			and is_nan(map.platform_top(3.0, -4.0)) and is_nan(map.tunnel_floor_under(3.0, -4.0)),
			"C the builders' map is not flat, or has a platform or a tunnel under a point")
	_ok(not map._sunk.is_empty() and map.sunk_floor(1.0e6, 1.0e6) == INF, "C the builders' map has no sunken places, or one far off the map")
	var sk: Dictionary = map._sunk[0]
	var ring: PackedVector2Array = sk["ring"]
	var mid := Vector2.ZERO
	for q in ring:
		mid += q
	mid /= float(ring.size())
	var floor_y := map.sunk_floor(mid.x, mid.y)
	_ok(not Geometry2D.is_point_in_polygon(mid, ring) or (floor_y < 0.0 and floor_y > -10.0),
			"C the first sunken place's floor is not under the flat ground: %.2f" % floor_y)
	map._solid(&"wall", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3.UP]))
	map._roof_triangle(Vector3.ZERO, Vector3.ONE, Vector3.UP, true)
	_ok(map._wall_faces.size() == 3 and map.roof_tris == 1 and map.data.is_empty() and float(map._terrain["step"]) == 10.0,
			"C the builders' map keeps the colliders and roof triangles it is handed: %d faces, %d roof triangles" % [map._wall_faces.size(), map.roof_tris])
	# A FlatMap's decks, roofs, tunnels, shore and edge would answer `has_method` where the builders' map must not.
	var flat_only := ["deck_height", "tunnel_height", "roof_height", "top_height", "in_tunnel", "shore_distance", "in_map"]
	var has: Array[String] = []
	for m: String in flat_only:
		if map.has_method(m):
			has.append(m)
	_ok(has.is_empty(), "C the builders' map has what only a FlatMap may have: %s" % [has])
	map.free()

	var radio := Fakes.Radio.new()
	_ok(radio.station == -1 and radio.next_locked() == 1 and radio.station_index("mordor_fm") == -1, "C a new radio is on, or has a track open, or knows a station")
	radio.stations = {"mordor_fm": 3}
	radio.tune(radio.station_index("mordor_fm"))
	radio.announce("Uwaga", "Attention")
	radio.announce("Dwa")
	_ok(radio.station == 3 and radio.tuned == [3] and radio.said == ["Uwaga", "Dwa"] and radio.subtitles == ["Attention", ""],
			"C the radio's station, tunes and words in step: %d / %s / %s / %s" % [radio.station, radio.tuned, radio.said, radio.subtitles])
	radio.open = {1: true, 2: true}
	_ok(radio.next_locked() == 3 and radio.unlock_track(3, "cassette") and not radio.unlock_track(3) and radio.next_locked() == 4
			and radio.unlocks == [[3, "cassette"], [3, "egg"]], "C the tracks: the next locked one, opened once, every ask kept: %s" % [radio.unlocks])
	_ok(radio.host_moment() and radio.host_moment(4.0) and radio.moments == 2, "C the host's moment is refused, or not counted")
	radio.moment_ok = false
	_ok(not radio.host_moment() and radio.moments == 3, "C `moment_ok` is not what the host's moment answers")
	radio.free()

	var sfx := Fakes.Sfx.new()
	sfx.play_at("horn", Vector3(1, 0, 2))
	sfx.play_at("crash", Vector3.ZERO, -6.0)
	sfx.soften_engine(10.0)
	_ok(sfx.played == [["horn", Vector3(1, 0, 2)], ["crash", Vector3.ZERO]] and sfx.softened == 1,
			"C the sounds played at a place, and the engine softened: %s / %d" % [sfx.played, sfx.softened])
	sfx.free()
	var sounds := Fakes.CitySounds.new()
	sounds.add_crowd("thump_0", "thump", Vector3.ZERO, func() -> bool: return true)
	_ok(sounds.crowds == ["thump_0"], "C the city's crowds asked for: %s" % [sounds.crowds])
	sounds.free()
	var walkers := Fakes.Walkers.new()
	walkers.set_stop(2, Vector3(1, 0, 1), 0.0, Color.RED, 0.5)
	walkers.set_scene(0, Vector3(5, 0, 5), 1.0, Color.BLUE, 0.2)
	walkers.set_scene(1, Vector3(6, 0, 5), 1.0, Color.BLUE, 0.2)
	walkers.clear_scene(0)
	_ok(walkers.stops == {2: Vector3(1, 0, 1)} and walkers.scenes == {1: Vector3(6, 0, 5)} and walkers.startle(Vector2.ZERO, 8.0) == 0
			and walkers.startled == 1, "C the figures at the stops and the scenes, apart, and the startles: %s / %s / %d" % [walkers.stops, walkers.scenes, walkers.startled])
	walkers.clear_stop(2)
	_ok(walkers.stops.is_empty(), "C a stop's figure not taken away")
	walkers.free()
	var tape := Fakes.Tape.new()
	tape.stamp("t_palac_2020")
	tape.stamp("t_most", 20261114)
	_ok(tape.stamped == ["t_palac_2020", "t_most"], "C the then cards stamped: %s" % [tape.stamped])
	tape.free()
