extends SceneTree
## The full map's track and "?" marks (map_track.gd, F's map ask 2026-11-16), pure rules
## and the saved key, no map, no game. Checks that:
## - a pin that is a place is tracked and saved as one "track_<id>" key in the [intro] section, a
##   second `pin({})` lets it go and takes the key away, a rival's moving pin or a request is no
##   track, an id with odd characters is saved safely;
## - a saved key is found again among the lists the world offers (a stand, a "?") and let go of after
##   TRIES tries when it never comes; a pin put meanwhile cancels the wait;
## (The legend's filters and their kinds went with the minimal map, 2026-11-17: the QUESTS screen.)
## - the "?" marks: only the steps with a fixed place that are not ticked and not otherwise shown, in
##   the UNKNOWN layer, group "unknown"; the teaser lines exist in both languages; the pin a tap offers
##   has the vehicle's line.
##   godot --headless --path game --script res://tools/check_map_track.gd

const MapTrack := preload("res://scripts/map_track.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const Lines := preload("res://scripts/quest_lines.gd")

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_track()
	_unknown()
	if _problems == 0:
		print("check_map_track: OK")
		quit(0)
	else:
		print("check_map_track: %d problems" % _problems)
		quit(1)


func _place(id: String, group := "kebab") -> Dictionary:
	return Lines.entry(id, group, Lines.Line.CAR, "Stoisko", "Stand", Vector2(10, 20), Color.ORANGE)


func _track() -> void:
	var t := MapTrack.new()
	var intro := {"fs_kebab": 3, "hint_map": 1}
	t.load_from(intro)
	_expect(t.pending == "" and t.tracked == "" and not t.dirty, "a save with no track tracks nothing")
	_expect(t.pin(_place("kebab_573_-284")) and t.tracked == "kebab_573_-284" and t.dirty, "a place pinned is tracked")
	t.save_to(intro)
	_expect(intro.get("track_kebab_573_-284", 0) == 1 and intro.has("fs_kebab") and intro.has("hint_map") and not t.dirty,
			"saved as one track_ key, the rest of [intro] untouched (%s)" % [intro])
	_expect(not t.pin(_place("kebab_573_-284")), "the same pin again changes nothing")
	_expect(t.pin(_place("garage", "garage")), "another pin replaces it")
	t.save_to(intro)
	var keys := intro.keys().filter(func(k: String) -> bool: return k.begins_with("track_"))
	_expect(keys == ["track_garage"], "one track key at most (%s)" % [keys])
	_expect(t.pin({}) and t.tracked == "", "the second tap (the pin goes) lets the track go")
	t.save_to(intro)
	_expect(not intro.keys().any(func(k: String) -> bool: return k.begins_with("track_")), "the key is taken away")
	var rival := Lines.entry("rival", "rival", Lines.Line.CAR, "Rywal", "Rival", Vector2(1, 1), Color.RED)
	_expect(not t.pin(rival) and t.tracked == "", "a rival's moving pin is not kept")
	var ride := Lines.entry("ride", "ride", Lines.Line.CAR, "Łuber", "Ride", Vector2.INF, Color.TEAL, "ride")
	_expect(not t.pin(ride), "a request is not kept")
	_expect(MapTrack.clean("kebab 12/3.5") == "kebab_12_3_5", "an id is cleaned for the save (%s)" % MapTrack.clean("kebab 12/3.5"))
	# Saved, then found again.
	var saved := {"track_unknown_garage": 1}
	var u := MapTrack.new()
	u.load_from(saved)
	_expect(u.pending == "unknown_garage" and u.tracked == "unknown_garage", "the save's track waits to be found")
	var offered := [[_place("kebab_1_2")], [MapTrack.entry_of("garage", Vector2(5, 6))]]
	var e := u.resolve(offered)
	_expect(e.get("id", "") == "unknown_garage" and u.pending == "", "found again among the lists (a '?' too)")
	_expect(not u.pin(e) and not u.dirty, "putting it back is no change to save")
	var w := MapTrack.new()
	w.load_from({"track_gone": 1})
	for i in MapTrack.TRIES - 1:
		w.resolve([[_place("other")]])
	_expect(w.pending == "gone", "still waiting before the last try")
	w.resolve([[_place("other")]])
	_expect(w.pending == "", "let go after %d tries" % MapTrack.TRIES)
	var x := MapTrack.new()
	x.load_from({"track_waiting": 1})
	x.pin(_place("kebab_9_9"))
	_expect(x.pending == "" and x.resolve([[_place("waiting")]]).is_empty(), "a pin put meanwhile cancels the wait")


func _unknown() -> void:
	var places := {"garage": Vector2(1, 2), "heli": Vector2(3, 4), "race": Vector2(5, 6)}
	var m := MapTrack.unknown_marks({}, places, {})
	_expect(m.size() == 2 and m[0]["group"] == "unknown" and m[0]["layer"] == MapMarkers.Layer.UNKNOWN, "garage and heli only (%d)" % m.size())
	m = MapTrack.unknown_marks({"fs_garage": 12}, places, {})
	_expect(m.size() == 1 and m[0]["key"] == "heli", "a step done: its '?' goes")
	m = MapTrack.unknown_marks({}, places, {"garage": true})
	_expect(m.size() == 1 and m[0]["key"] == "heli", "a place shown otherwise: no '?'")
	m = MapTrack.unknown_marks({}, {"garage": Vector2.INF}, {})
	_expect(m.is_empty(), "no place yet: none")
	for id in MapTrack.PLACED:
		var w := MapTrack.teaser(id)
		_expect(w.size() == 2 and str(w[0]) != "unknown_" + id and str(w[1]) != "unknown_" + id and str(w[0]) != str(w[1]), "teaser %s in both languages: %s" % [id, w])
		_expect(str(w[1]).length() <= 60, "teaser %s is one short line" % id)
	var e := MapTrack.entry_of("heli", Vector2(3, 4))
	_expect(int(e["line"]) == Lines.Line.HELI and e["group"] == "unknown" and e["action"] == "" and MapTrack.keepable(e), "the heli's pin is on the HELI line and keepable")
	_expect(int(MapTrack.entry_of("garage", Vector2(1, 1))["line"]) == Lines.Line.CAR, "the garage's pin is on the car line")
