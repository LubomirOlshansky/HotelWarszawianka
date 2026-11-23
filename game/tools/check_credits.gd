extends SceneTree
## DEMO 3j (the TestFlight gate): the release build strips the testing flags, and the credits
## and licences page says what the build is made of.
##   - release.gd: a release build reads no flags (with "--" or without), a debug build reads the
##     user args, or the engine's list when a launcher swallowed the "--";
##   - credits.gd names OpenStreetMap with ODbL 1.0, GUGiK, the trees' CC BY 4.0, the add-ons' MIT licences
##     and Godot; every add-on folder that ships (addons/*, minus the export's exclude filter) is
##     in credits.gd ADDONS and named on the page, and nothing in ADDONS is missing from addons/;
##   - every radio track in data/radio.json is on the page, with a licence that is not "unknown";
##   - CREDITS.md (the repo's list) names the same data licences and add-ons;
##   - the settings card's DŹWIĘK → LICENCJE opens the page (6), its title says O GRZE, every tab
##     goes back, and the page keeps the card's size (check_hud measures it at phone sizes).
## Prints the findings, then `check_credits: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_credits.gd

const Release := preload("res://scripts/release.gd")
const Credits := preload("res://scripts/credits.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")

var problems: Array[String] = []


func _initialize() -> void:
	_check_release()
	_check_text()
	_check_addons()
	_check_radio()
	_check_repo_credits()
	await _check_panel()
	if problems.is_empty():
		print("check_credits: OK")
		quit(0)
	else:
		for p in problems:
			print("  " + p)
		print("check_credits: %d problem(s)" % problems.size())
		quit(1)


func _check_release() -> void:
	var user := PackedStringArray(["--at=1,2", "--nosave"])
	var all := PackedStringArray(["--path", "game", "--at=1,2", "--nosave"])
	var none := PackedStringArray()
	var cases := [
		[user, all, true, user, "debug, after --"],
		[none, all, true, all, "debug, -- swallowed"],
		[user, all, false, none, "release, after --"],
		[none, all, false, none, "release, -- swallowed"],
	]
	for c in cases:
		var got := Release.pick(c[0], c[1], c[2])
		if got != c[3]:
			problems.append("release.gd %s: %s, wanted %s" % [c[4], got, c[3]])
	print("release flags: %d cases" % cases.size())


func _check_text() -> void:
	var t := Credits.text()
	for need in ["OpenStreetMap", "(ODbL) 1.0", "Główny Urząd Geodezji i Kartografii", "CC BY 4.0", "MIT", "Godot Engine",
			"LoD2"]:
		if not need in t:
			problems.append("the credits page lacks \"%s\"" % need)
	print("credits: %d sections, %d characters" % [Credits.sections().size(), t.length()])


func _check_addons() -> void:
	var excluded := _export_excludes()
	var shipped: Array[String] = []
	var dir := DirAccess.open("res://addons")
	for d in dir.get_directories():
		if not "addons/%s/*" % d in excluded:
			shipped.append(d)
	var t := Credits.text()
	for d in shipped:
		if not Credits.ADDONS.has(d):
			problems.append("add-on %s ships in the build but is not in credits.gd ADDONS" % d)
		elif not String(Credits.ADDONS[d]) in t:
			problems.append("add-on %s (%s) is not named on the credits page" % [d, Credits.ADDONS[d]])
	for d in Credits.ADDONS:
		if not d in shipped:
			problems.append("credits.gd ADDONS names %s, which does not ship" % d)
	print("add-ons shipped: %s" % ", ".join(shipped))


## The export presets' exclude filters, split ("addons/nw_android_export/*", ...).
func _export_excludes() -> PackedStringArray:
	var out := PackedStringArray()
	var cfg := ConfigFile.new()
	if cfg.load("res://export_presets.cfg") != OK:
		problems.append("export_presets.cfg not readable")
		return out
	for s in cfg.get_sections():
		if cfg.has_section_key(s, "exclude_filter"):
			for f in String(cfg.get_value(s, "exclude_filter")).split(","):
				out.append(f.strip_edges())
	return out


func _check_radio() -> void:
	var tracks := Credits.tracks()
	if tracks.is_empty():
		problems.append("no radio tracks read from data/radio.json")
	var t := Credits.text()
	for tr in tracks:
		if String(tr["licence"]).strip_edges() in ["", "unknown"]:
			problems.append("radio track %s has no licence (not cleared for a release)" % tr["title"])
		if not String(tr["title"]) in t:
			problems.append("radio track %s is not on the credits page" % tr["title"])
	print("radio tracks: %d, all licensed" % tracks.size())


func _check_repo_credits() -> void:
	var f := FileAccess.open("res://../CREDITS.md", FileAccess.READ)
	if f == null:
		print("CREDITS.md: not beside the project (skipped)")
		return
	var md := f.get_as_text()
	for need in ["ODbL", "GUGiK", "CC BY 4.0", "Phantom Camera", "beehave", "Dialogue Manager", "Debug Draw"]:
		if not need in md:
			problems.append("CREDITS.md lacks \"%s\"" % need)
	print("CREDITS.md: in step")


func _check_panel() -> void:
	var panel := SettingsPanel.new()
	panel.pt = 3.0
	panel.safe = Rect2(0, 0, 2532, 1170)
	root.add_child(panel)
	await process_frame
	panel.open({"controls": 0, "master": 1.0, "music": 1.0, "effects": 1.0})
	await process_frame
	var size_before: Rect2 = panel.card_rect()
	var buttons: Dictionary = panel.button_rects()
	panel.set_page("general")
	await process_frame
	var about := panel.find_child("credits", true, false) as Button
	if about == null:
		problems.append("the OGÓLNE tab has no LICENCJE button")
	else:
		about.pressed.emit()
		await process_frame
		var page := panel.find_child("credits_page", true, false) as Control
		if page == null or not page.is_visible_in_tree():
			problems.append("LICENCJE did not show the credits page")
		var title := String((panel.get("_title") as Label).text)
		if title != "O GRZE":
			problems.append("the credits page's title is %s, not O GRZE" % title)
		if not panel.card_rect().size.is_equal_approx(size_before.size):
			problems.append("the card changed size on the credits page: %s -> %s" % [size_before.size, panel.card_rect().size])
		panel.set_page("game")
		await process_frame
		if page != null and page.is_visible_in_tree():
			problems.append("a tab did not leave the credits page")
	print("settings card: %d buttons, LICENCJE opens the credits page" % buttons.size())
	panel.queue_free()
