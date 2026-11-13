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
##     (`say`, `say_ambient`, `say_reaction`: the dialogue's and the bubbles'), unless the class extends one of
##     fakes.gd's. The ones still left are named in LEFT with the reason; a name there that is no longer a
##     private stand-in gives a `fakes: WARN` line (the step's row warns until the name is taken off the
##     list: the change that moved the class is not held up by this list);
##   C the stand-ins remember what they are given: the HUD's toasts, small toasts, notes and cards in both
##     languages and in step; the card's owner and a press; the dialogue's lines with their group, tag, class
##     and key, what `say` and `line` answer, `count`; the bubbles' budget (`ok`, `allows`, `muted`).
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
]
## The functions that are a stand-in's own (a check calls them; the game's script has no such function).
const OWN := {
	"Hud": ["press"],
	"Dialogue": ["count", "forget"],
}
## The functions that make a class a stand-in for the HUD, and for the dialogue or the bubbles.
const HUD_MARKS := ["toast", "ambient_toast", "show_note", "show_card", "show_side_card", "show_call", "show_status",
		"show_pill", "show_banner", "show_challenge", "set_minimap_route", "set_minimap_pois", "set_minimap_dots",
		"set_quest_dots"]
const TALK_MARKS := ["say", "say_ambient", "say_reaction"]
## The private stand-ins still left, by file: the racer work has these checks in hand (2026-11-13); each
## moves to fakes.gd with that work's next change to the check.
const LEFT := {
	"check_police.gd": ["FakeHud", "FakeBubbles"],
	"check_crazy_drivers.gd": ["FakeBubbles"],
}
const TOOLS := "res://tools"

var _facts := 0
var _problems := 0


func _initialize() -> void:
	var a := _arguments()
	var b := _private_copies()
	_remember()
	if _problems == 0:
		var named := 0
		for f: String in LEFT:
			named += (LEFT[f] as Array).size()
		print("check_fakes: OK (%d facts: %d functions and %d signals of %d stand-ins take the game's arguments; %d scripts under tools read, %d private stand-ins left of the %d named)" % [
				_facts, a[0], a[1], PAIRS.size(), b[0], b[1], named])
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
		var own: Array = OWN.get(who, [])
		var seen_own := {}
		for m: Dictionary in fake.get_script_method_list():
			var name := String(m["name"])
			if name.begins_with("_") or name.begins_with("@"):  # a helper, or a property's getter
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
	_ok(functions >= 40, "A only %d functions compared (the stand-ins had 51 of the game's on 2026-11-13)" % functions)
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
			var j := i + 1
			while j < lines.size() and (lines[j].begins_with("\t") or lines[j].strip_edges() == ""):
				var e := inner_extends.search(lines[j])
				if e != null and base == "":
					base = e.get_string(1)
				var fn := function.search(lines[j])
				if fn != null:
					functions.append(fn.get_string(1))
				j += 1
			classes[m.get_string(1)] = [base, functions]
			i = j
		for name: String in classes:
			var marks: Array[String] = []
			for fn: String in classes[name][1]:
				if fn in HUD_MARKS or fn in TALK_MARKS:
					marks.append(fn)
			if marks.is_empty() or _shared(name, classes):
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
	return [files.size(), left]


## Whether the class extends one of fakes.gd's, itself or through another class of its file.
func _shared(name: String, classes: Dictionary) -> bool:
	var hops := 0
	var at := name
	while classes.has(at) and hops < 8:
		var base := String(classes[at][0])
		if base.begins_with("Fakes."):
			return true
		at = base
		hops += 1
	return false


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
