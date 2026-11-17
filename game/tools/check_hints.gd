extends SceneTree
## First hour step 6 (docs/design/onboarding-hints.md): the hints in play (hints.gd), the loading
## tips on the title (title.gd) and the spotlight (hud.gd), without the map.
## - the words: every hint in both languages, eight words at most; every tip twelve at most;
## - `decide` on made-up facts: nothing in a chase, a scripted moment or under a card; "stop in the
##   ring" on the way into a ring too fast, twice at most; "reverse" after STALL_HINT s stuck, once;
##   HELI on a roof call by car; the climb pad on the first flight until it is used; "land" near
##   the person; the minimap after the first pay, GAP s apart, never once the map was opened;
##   each hint goes when its thing is done or after LIFE s;
## - the save's [intro] round trip, and `done_tags` on a fixture wallet;
## - the title: the tips load, a new one every TIP_EVERY s while the city builds, none after it
##   (the last stays), the done ones last, the line clear of NOWA GRA at the phone's sizes;
## - the DEV page: six taps on the version do nothing, the seventh opens it, then one tap does;
##   our A/B switches are there and on no tab; Experimental quality shows only once it opened;
## - the spotlight on each target at the phone's sizes: its words inside the safe area and off
##   the thing it rings, and gone with `spotlight_off` and `clear_all`.
##   godot --headless --path game --script res://tools/check_hints.gd

const Hints := preload("res://scripts/hints.gd")
const Messages := preload("res://scripts/messages.gd")
const Title := preload("res://scripts/title.gd")
const Hud := preload("res://scripts/hud.gd")
const Wallet := preload("res://scripts/wallet.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")
## The A/B switches that live on the DEV page only (the Fable critique's list).
const DEV_KEYS := ["camera", "handling", "lane_assist", "zones", "collide", "soft_fences", "chatter", "perf"]
const SCREENS := [Vector2i(2532, 1170), Vector2i(1334, 750), Vector2i(1280, 720), Vector2i(2868, 1320)]

var _problems := 0
var _facts := 0


func _expect(ok: bool, what: String) -> void:
	_facts += 1
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_words()
	_decide()
	_map_coach()
	_save()
	await _title()
	await _spotlight()
	await _dev()
	if _problems == 0:
		print("check_hints: OK (%d facts: %d hints, %d tips, the rules, the save, the title at %d sizes, the spotlight at %d sizes, the DEV page)" % [
				_facts, Hints.IDS.size(), _tip_count(), SCREENS.size(), SCREENS.size()])
		quit(0)
	else:
		print("check_hints: FAILED (%d of %d facts)" % [_problems, _facts])
		quit(1)


func _tip_count() -> int:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(Hints.FILE))
	return ((d as Dictionary).get("tips", []) as Array).size() if d is Dictionary else 0


func _words() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(Hints.FILE))
	_expect(d is Dictionary, "tips.json parses")
	if not d is Dictionary:
		return
	var hints: Dictionary = (d as Dictionary).get("hints", {})
	for id: String in Hints.IDS + Hints.MAP_IDS:
		_expect(hints.has(id), "hint %s has words" % id)
		var w: Dictionary = hints.get(id, {})
		for lang in ["pl", "en"]:
			var text := str(w.get(lang, ""))
			_expect(text != "" and text.split(" ", false).size() <= 8, "hint %s (%s) is 1 to 8 words: \"%s\"" % [id, lang, text])
		_expect(Hints.TARGETS.has(id) or id in Hints.MAP_IDS, "hint %s has a target" % id)
	var tips: Array = (d as Dictionary).get("tips", [])
	_expect(tips.size() >= 12, "at least 12 tips (%d)" % tips.size())
	var jokes := 0
	for t: Dictionary in tips:
		for lang in ["pl", "en"]:
			var text := str(t.get(lang, ""))
			_expect(text != "" and text.split(" ", false).size() <= 12, "tip (%s) is 1 to 12 words: \"%s\"" % [lang, text])
		if str(t.get("tag", "")) == "":
			jokes += 1
	_expect(jokes * 2 <= tips.size() - jokes, "two game facts or more to each joke (%d jokes of %d)" % [jokes, tips.size()])


## Free driving, nothing going on.
func _free(more := {}) -> Dictionary:
	var f := {"context": Messages.FREE, "card": false, "flying": false, "speed": 10.0, "stalled": 0.0, "in_ring": false,
			"heli_call": false, "heli_shown": true, "climbed": false, "land_near": false, "earned": false, "map_open": false}
	f.merge(more, true)
	return f


func _decide() -> void:
	var h := Hints.new()
	# Nothing in a chase or a scripted moment, nor under a card.
	for ctx in [Messages.CHASE, Messages.FOCUS]:
		_expect(h.tick(0.2, _free({"context": ctx, "in_ring": true, "speed": 12.0}), null) == "", "no hint in context %d" % ctx)
	_expect(h.tick(0.2, _free({"card": true, "stalled": 5.0}), null) == "", "no hint under a card")
	# The ring: on the way in too fast, during a job (QUEST); twice at most.
	h.tick(0.2, _free({"context": Messages.QUEST}), null)
	_expect(h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 12.0}), null) == "stop", "stop on the way into a ring at 43 km/h")
	_expect(h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 12.0}), null) == "" and h.current == "stop", "the stop hint stays while the car is fast in the ring")
	h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 0.5}), null)
	_expect(h.current == "", "the stop hint goes once the car stands")
	h.tick(0.2, _free({"context": Messages.QUEST}), null)
	_expect(h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 8.0}), null) == "stop", "stop the second time")
	h.tick(0.2, _free({"context": Messages.QUEST}), null)
	h.tick(0.2, _free({"context": Messages.QUEST}), null)
	_expect(h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 8.0}), null) == "", "no stop hint the third time")
	_expect(h.tick(0.2, _free({"context": Messages.QUEST, "in_ring": true, "speed": 3.0}), null) == "", "no stop hint for a slow car")
	# Stuck: hold BRAKE to reverse, once, after STALL_HINT s.
	h = Hints.new()
	_expect(h.tick(0.2, _free({"stalled": Hints.STALL_HINT - 0.5}), null) == "", "no reverse hint before %.0f s" % Hints.STALL_HINT)
	_expect(h.tick(0.2, _free({"stalled": Hints.STALL_HINT}), null) == "reverse", "reverse after %.0f s stuck" % Hints.STALL_HINT)
	h.tick(0.2, _free({"stalled": 0.0}), null)
	_expect(h.current == "", "the reverse hint goes once the car moves")
	_expect(h.tick(0.2, _free({"stalled": 6.0}), null) == "", "the reverse hint shows once")
	# A roof call by car: HELI, once; gone at take-off.
	h = Hints.new()
	_expect(h.tick(0.2, _free({"heli_call": true, "heli_shown": false}), null) == "", "no HELI hint while the chip is hidden")
	_expect(h.tick(0.2, _free({"heli_call": true}), null) == "heli", "HELI on a roof call by car")
	h.tick(0.2, _free({"heli_call": true, "flying": true, "climbed": true}), null)
	_expect(h.current == "", "the HELI hint goes at the take-off")
	_expect(h.did.has("flown"), "the flight is noted")
	# The first flight: the climb pad until it is used; then "land" near the person.
	h = Hints.new()
	_expect(h.tick(0.2, _free({"flying": true}), null) == "climb", "the climb pad on the first flight")
	h.tick(0.2, _free({"flying": true, "climbed": true}), null)
	_expect(h.current == "", "the climb hint goes once the pad is used")
	_expect(h.tick(0.2, _free({"flying": true}), null) == "", "the climb hint shows once")
	_expect(h.tick(0.2, _free({"flying": true, "land_near": true}), null) == "land", "land by the person, near")
	h.tick(0.2, _free({"flying": true, "land_near": false}), null)
	_expect(h.current == "", "the land hint goes at the pick-up")
	# The minimap: after the first pay, in free driving, GAP s after the last hint; never once the
	# map was opened; gone when it opens.
	h = Hints.new()
	_expect(h.tick(0.2, _free(), null) == "", "no minimap hint before any pay")
	_expect(h.tick(0.2, _free({"earned": true, "context": Messages.QUEST}), null) == "", "no minimap hint during a job")
	_expect(h.tick(0.2, _free({"earned": true}), null) == "minimap", "the minimap after the first pay")
	h.tick(0.2, _free({"earned": true, "map_open": true}), null)
	_expect(h.current == "" and h.did.has("map"), "the minimap hint goes when the map opens")
	h = Hints.new()
	h.tick(0.2, _free({"stalled": 4.0}), null)  # reverse
	h.tick(0.2, _free(), null)
	_expect(h.tick(0.2, _free({"earned": true}), null) == "", "the minimap hint waits %.0f s after another" % Hints.GAP)
	for i in int(Hints.GAP / 0.2) + 1:
		h.tick(0.2, _free(), null)
	_expect(h.tick(0.2, _free({"earned": true}), null) == "minimap", "the minimap hint after %.0f s" % Hints.GAP)
	h = Hints.new()
	h.tick(0.2, _free({"map_open": true}), null)
	_expect(h.tick(0.2, _free({"earned": true}), null) == "", "no minimap hint once the map was opened")
	# The minimap also after MINIMAP_DRIVE_S s of free driving with no pay yet; never in FOCUS or
	# under a card; twice at most.
	h = Hints.new()
	_expect(h.decide(_free({"drive_s": Hints.MINIMAP_DRIVE_S - 1.0})) == "", "no minimap hint at 59 s of driving")
	_expect(h.decide(_free({"drive_s": Hints.MINIMAP_DRIVE_S})) == "minimap", "the minimap hint at 60 s of free driving, unpaid")
	_expect(h.decide(_free({"drive_s": 90.0, "context": Messages.FOCUS})) == "", "no minimap hint in FOCUS at 90 s")
	_expect(h.decide(_free({"drive_s": 90.0, "card": true})) == "", "no minimap hint under a card at 90 s")
	_expect(h.decide(_free({"drive_s": 90.0, "map_open": true, "context": Messages.CHASE})) == "", "no minimap hint in a chase at 90 s")
	h = Hints.new()
	var ticks := int(Hints.MINIMAP_DRIVE_S / 0.2)
	var got := ""
	for i in ticks - 2:
		got = h.tick(0.2, _free({"driving": true}), null)
	_expect(got == "", "tick: no minimap hint just before 60 s of driving")
	for i in 6:
		got = h.tick(0.2, _free({"driving": true}), null)
		if got != "":
			break
	_expect(got == "minimap", "tick sums the driving: the minimap hint at 60 s")
	h = Hints.new()
	for i in ticks + 5:
		h.tick(0.2, _free({"driving": true, "context": Messages.QUEST}), null)
	_expect(h.current == "" and h.shown_log.is_empty(), "a job's driving does not count towards the minimap hint")
	h = Hints.new()
	h.seen["minimap"] = 1
	_expect(h.decide(_free({"earned": true})) == "minimap", "the minimap hint shows a second time if the map stayed shut")
	h.seen["minimap"] = 2
	_expect(h.decide(_free({"earned": true})) == "", "the minimap hint shows twice at most")
	# A hint goes after LIFE s, and at once when a chase begins.
	h = Hints.new()
	h.tick(0.2, _free({"stalled": 4.0}), null)
	for i in int(Hints.LIFE / 0.2) + 1:
		h.tick(0.2, _free({"stalled": 4.0}), null)
	_expect(h.current == "", "a hint goes after %.0f s" % Hints.LIFE)
	h = Hints.new()
	h.tick(0.2, _free({"flying": true}), null)
	h.tick(0.2, _free({"flying": true, "context": Messages.CHASE}), null)
	_expect(h.current == "", "a hint goes when a chase begins")


## The full map's coach marks: one at a time, in order, each gone when its thing is done, once,
## the save keys, the replay.
func _map_coach() -> void:
	var h := Hints.new()
	var all := {"scrollable": true, "has_place": true}
	_expect(h.decide_map({"scrollable": true, "has_place": true, "cards": true}) == "", "no coach mark under the ≡ cards")
	_expect(h.decide_map({"scrollable": false, "has_place": false}) == "map_hold", "a short list and no place: only the hold")
	_expect(h.map_tick(0.1, all) == "map_list", "the first coach mark: scroll the list")
	_expect(h.map_tick(0.1, all) == "map_list", "it stays until the list is scrolled")
	_expect(h.map_tick(0.1, {"scrollable": true, "has_place": true, "did_scroll": true}) == "map_hold", "scrolled: the hold comes next")
	_expect(h.map_tick(0.1, {"scrollable": true, "has_place": true, "did_hold": true}) == "map_pin", "held: the pin comes next")
	_expect(h.map_tick(0.1, {"scrollable": true, "has_place": true, "did_pin": true}) == "", "pinned: none left")
	_expect(h.dirty and int(h.seen.get("map_list", 0)) == 1 and int(h.seen.get("map_pin", 0)) == 1, "each shown once is counted")
	h.map_reset()
	_expect(h.map_tick(0.1, all) == "", "never again once all three were shown")
	var intro := {}
	h.save_to(intro)
	_expect(intro.has("hint_map_list") and intro.has("hint_map_hold") and intro.has("hint_map_pin"), "the [intro] keys of the coach marks: %s" % intro)
	var back := Hints.new()
	back.load_from(intro)
	_expect(back.map_tick(0.1, all) == "", "a loaded save does not coach again")
	# A mark nobody did gives way after COACH_LIFE s.
	h = Hints.new()
	h.map_tick(0.1, all)
	var after := ""
	for i in int(Hints.COACH_LIFE / 0.5) + 2:
		after = h.map_tick(0.5, all)
	_expect(after == "map_hold", "an ignored coach mark gives way after %.0f s (%s)" % [Hints.COACH_LIFE, after])
	# The "?": every mark again, once each, the save untouched.
	var played: Array[String] = []
	var rf := {"scrollable": true, "has_place": true, "replay": true, "did_scroll": true, "did_hold": true, "did_pin": true}
	back.dirty = false
	for i in 8:
		var id := back.map_tick(0.1, rf)
		if id != "" and not id in played:
			played.append(id)
	_expect(played == ["map_list", "map_hold", "map_pin"], "the replay plays all three in order (%s)" % [played])
	_expect(not back.dirty, "a replay does not touch the save")
	_expect(back.map_tick(0.1, rf) == "", "the replay ends after the third")


func _save() -> void:
	var h := Hints.new()
	h.tick(0.2, _free({"stalled": 4.0, "map_open": true}), null)
	_expect(h.dirty, "a hint shown marks the save dirty")
	var intro := {}
	h.save_to(intro)
	_expect(not h.dirty and int(intro.get("hint_reverse", 0)) == 1 and intro.has("hint_map"), "the [intro] keys: %s" % intro)
	var back := Hints.new()
	back.load_from(intro)
	_expect(back.tick(0.2, _free({"stalled": 4.0}), null) == "", "a loaded save does not show the reverse hint again")
	_expect(back.did.has("map"), "a loaded save remembers the map")
	var w := Wallet.new()
	w.persistent = false
	_expect(Hints.done_tags(w).is_empty(), "a fresh wallet has done nothing")
	w.intro = intro
	w.ladder = {"halina": 1}
	var tags := Hints.done_tags(w)
	_expect(tags.has("map") and tags.has("raced") and not tags.has("flown"), "done_tags: %s" % tags)
	w.free()


func _title() -> void:
	for screen: Vector2i in SCREENS:
		var vp := SubViewport.new()
		vp.size = screen
		vp.disable_3d = true
		root.add_child(vp)
		var t: CanvasLayer = Title.new()
		vp.add_child(t)
		await process_frame
		var tag := "title %dx%d" % [screen.x, screen.y]
		_expect(t.tips.size() >= 12, "%s: the tips load (%d)" % [tag, t.tips.size()])
		var first: String = t.tip_text()
		_expect(first != "", "%s: a tip shows while the city builds" % tag)
		t._process(Title.TIP_EVERY + 0.1)
		_expect(t.tip_text() != first, "%s: a new tip after %.0f s" % [tag, Title.TIP_EVERY])
		# The widest tip stays clear of NOWA GRA in the corner.
		var widest := 0.0
		for i in t.tips.size():
			t.next_tip()
			var l := t.get("_tip") as Label
			var w := ThemeDB.fallback_font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
			widest = maxf(widest, w)
			var nb := (t.get("_new_btn") as Control)
			var words := Rect2(l.position.x + (l.size.x - w) * 0.5, l.position.y, w, l.size.y)
			var corner := Rect2(nb.position, nb.size)
			_expect(not words.intersects(corner), "%s: the tip \"%s\" runs under NOWA GRA" % [tag, l.text])
			_expect(l.get_theme_font_size("font_size") >= 10, "%s: the tip \"%s\" at %d px" % [tag, l.text, l.get_theme_font_size("font_size")])
		# Done tags last.
		t.set_done(PackedStringArray(["flown", "raced"]))
		var order: Array = t.tips
		var seen_done := false
		var ok := true
		for i in range(1, order.size()):
			var is_done: bool = str(order[i].get("tag", "")) in ["flown", "raced"]
			if seen_done and not is_done:
				ok = false
			seen_done = seen_done or is_done
		_expect(ok, "%s: the tips about things done come last" % tag)
		# Ready: the last tip stays.
		t.set_ready()
		var last: String = t.tip_text()
		t._process(Title.TIP_EVERY * 2.0)
		_expect(t.tip_text() == last and last != "", "%s: the last tip stays under TAP TO DRIVE" % tag)
		vp.queue_free()
		await process_frame


func _spotlight() -> void:
	for screen: Vector2i in SCREENS:
		var vp := SubViewport.new()
		vp.size = screen
		vp.disable_3d = true
		root.add_child(vp)
		var hud: CanvasLayer = Hud.new()
		vp.add_child(hud)
		hud.setup_minimap({"areas": [], "roads": [], "bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
		await process_frame
		var safe: Rect2 = hud.safe_rect()
		var words := "Trzymaj HAMULEC, żeby cofnąć i jeszcze"
		for target in ["minimap", "heli", "climb", "brake", "car"]:
			hud.set_flying(target == "climb")
			hud.spotlight(target, words)
			await process_frame
			var tag := "spotlight %s at %dx%d" % [target, screen.x, screen.y]
			var r: Rect2 = hud.spotlight_target_rect()
			var label: Rect2 = hud.spotlight_label_rect()
			_expect(r.has_area(), "%s: the target is on screen" % tag)
			_expect(safe.grow(1.0).encloses(label), "%s: the words %s inside the safe area %s" % [tag, label, safe])
			if target != "car":
				_expect(not label.intersects(r.grow(-2.0)), "%s: the words %s cover the target %s" % [tag, label, r])
			_expect(hud.spotlight_target() == target and hud.spotlight_words() == words, "%s: up" % tag)
		hud.spotlight_off()
		_expect(hud.spotlight_target() == "", "spotlight_off takes it down")
		hud.spotlight("car", words, 1.0)
		hud._process(1.2)
		_expect(hud.spotlight_target() == "", "the spotlight goes by itself after its life")
		hud.spotlight("minimap", words)
		hud.clear_all()
		_expect(hud.spotlight_target() == "", "clear_all takes the spotlight down")
		vp.queue_free()
		await process_frame


func _dev() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var panel: Control = SettingsPanel.new()
	panel.pt = 3.0
	vp.add_child(panel)
	panel.open({"controls": 1, "follow": true, "traffic": 1, "quality": 0, "auto": "High", "master": 1.0, "music": 1.0,
			"effects": 1.0, "fps": 0, "weather": 0, "time": 0})
	await process_frame
	var exp: Button = panel._groups["quality"][SettingsPanel.QUALITY.size() - 1]
	_expect(not exp.visible, "DEV: Experimental quality is hidden before DEV")
	_expect(str(panel._subtitle.text).ends_with(SettingsPanel.version()), "DEV: the version under the title (%s)" % panel._subtitle.text)
	for i in SettingsPanel.DEV_TAPS - 1:
		_expect(not panel.dev_tap(), "DEV: tap %d does not open it" % (i + 1))
	_expect(panel.dev_tap() and panel._tab == SettingsPanel.DEV_PAGE, "DEV: the seventh tap opens it")
	_expect(exp.visible, "DEV: Experimental quality shows once DEV opened")
	var dev_page: Control = panel._pages[SettingsPanel.DEV_PAGE]
	for key: String in DEV_KEYS:
		var b: Button = panel._groups[key][0]
		_expect(dev_page.is_ancestor_of(b), "DEV: %s is on the DEV page" % key)
		for t in SettingsPanel.TABS.size():
			_expect(not panel._pages[t].is_ancestor_of(b), "DEV: %s is not on tab %d" % [key, t])
	_expect(dev_page.is_ancestor_of(dev_page.find_child("bench", true, false)), "DEV: TEST is on the DEV page")
	panel.set_tab(0)
	_expect(panel.dev_tap() and panel._tab == SettingsPanel.DEV_PAGE, "DEV: one tap opens it again in the same run")
	vp.queue_free()
	await process_frame
	# --settings-tab=7 and =8 ask for a page past the tabs before the panel is built (main.gd's
	# start): the panel must open on that page, not on the last tab.
	for page: int in [SettingsPanel.TIPS_PAGE, SettingsPanel.DEV_PAGE]:
		var early := SubViewport.new()
		early.size = Vector2i(2532, 1170)
		early.disable_3d = true
		root.add_child(early)
		var p2: Control = SettingsPanel.new()
		p2.pt = 3.0
		p2.set_tab(page)
		early.add_child(p2)
		p2.open({"controls": 1, "follow": true, "traffic": 1, "quality": 0, "auto": "High", "master": 1.0, "music": 1.0,
				"effects": 1.0, "fps": 0, "weather": 0, "time": 0})
		await process_frame
		_expect(p2._tab == page and p2._pages[page].visible, "DEV: page %d asked for before the build opens on it" % page)
		if page == SettingsPanel.DEV_PAGE:
			_expect(p2.dev_on and p2._groups["quality"][SettingsPanel.QUALITY.size() - 1].visible, "DEV: asked for before the build, DEV is on")
		early.queue_free()
		await process_frame
