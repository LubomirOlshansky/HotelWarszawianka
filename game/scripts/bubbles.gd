extends Control
## Speech bubbles and name tags over things in the world, drawn in the HUD layer
## (full resolution, above the pixel-art view, so they need no 3D transparency).
##
## Anyone can talk: pass a Node3D (the bubble follows it) or a Callable that returns
## a world position. A line is Polish with an optional English subtitle; it types
## itself out, stays a few seconds and fades. One bubble per speaker: a new line
## replaces the old one. Off-screen speakers are pinned to the screen edge with the
## tail pointing their way.
##
##   bubbles.say(rival_node, "Seba z Pragi", "Ej, kierowniku!", "Hey, boss!")
##   bubbles.tag(rival_node, "Seba z Pragi", Color("#b45cff"))
##
## Loop 2e: sized in points (the line 15 pt, the English 13, names 11), in the HUD's card
## recipe (a near-black violet card, ink text, the speaker's name in their colour), and placed
## clear of every rect the HUD has on screen (hud.gd `panel_rects`: the top row, the minimap and
## the wallet, the pedals, the radio ticker, cards, toasts, the status) inside the safe area
## under the top row; a bubble that finds no free spot above or below where it wanted to be
## keeps that spot (`overlaps` counts them, for tools/check_hud.gd).

const Lang := preload("res://scripts/lang.gd")
const Access := preload("res://scripts/access.gd")
const Chatter := preload("res://scripts/chatter.gd")

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

## World position -> screen pixels; set by the game (camera and pixel scale).
var project: Callable
## Loop 2e: pixels per point (the HUD's).
var pt := 1.0

const TYPE_RATE := 42.0      # characters per second
const FADE := 0.35
## Loop 2e: sizes in points.
const LINE_SIZE := 15.0
const SUB_SIZE := 13.0
const NAME_SIZE := 11.0
const WIDTH := 220.0
## A bubble that finds no room at WIDTH tries again this narrow (more lines, less wide), then
## this wide (fewer lines, to fit a low gap); with no room at all it waits (its clock stopped)
## up to MAX_WAIT seconds, then the line is dropped.
const NARROW := 150.0
const WIDE := 320.0
const MAX_WAIT := 6.0
const PAD := 8.0
const TAIL := 10.0
## PT-9: the longest tail, in points: a bubble that had to move away from its speaker still points at it.
const REACH := 150.0
## The HUD's card recipe (hud.gd CARD_BG) and its text colours.
const CARD_BG := Color(0.07, 0.06, 0.1, 0.94)
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")

var _bubbles: Array[Dictionary] = []
var _tags: Array[Dictionary] = []
var _panel: StyleBoxFlat
var _tag_box: StyleBoxFlat
## Loop 2e: where each bubble went in the last layout, and how many found no room (waiting).
var rects: Array[Rect2] = []
var overlaps := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = StyleBoxFlat.new()
	_panel.bg_color = CARD_BG
	_panel.border_color = Color(1, 1, 1, 0.3)
	_panel.set_border_width_all(maxi(1, roundi(1.0 * pt)))
	_panel.set_corner_radius_all(roundi(8.0 * pt))
	_tag_box = StyleBoxFlat.new()
	_tag_box.bg_color = CARD_BG
	_tag_box.set_corner_radius_all(roundi(4.0 * pt))


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


## Shows `line` (and an English `subtitle`) over `anchor` for `seconds` after it has
## typed out. `height` lifts the tail above a Node3D anchor's origin. `kind` is the line's class in
## the chatter budget (chatter.gd: QUEST by default, POLICE, REACTION, AMBIENT) and `key` narrows a
## reaction ("bump", "near_miss"). Returns whether it shows.
func say(anchor: Variant, speaker: String, line: String, subtitle := "", seconds := 4.0,
		accent := Color("#ffd23f"), height := 2.6, kind := Chatter.QUEST, key := "") -> bool:
	if quiet_all:
		return false
	var replacing := is_talking(anchor)
	_sense()
	if not chatter.take(kind, count() - (1 if replacing else 0), key):
		return false
	accent = Access.tint(accent)  # colour-safe (access.gd)
	line = Lang.pick(line, subtitle)  # one language (lang.gd)
	subtitle = ""
	hush(anchor)
	_make_room()
	var typing := line.length() / TYPE_RATE
	var b := {"anchor": anchor, "speaker": speaker, "line": line, "sub": subtitle, "age": 0.0,
			"life": typing + maxf(seconds, Chatter.read_time(line + subtitle)), "typing": typing, "accent": accent, "height": height, "kind": kind}
	b["wide"] = _measure(b, WIDTH)
	_bubbles.append(b)
	queue_redraw()
	return true


## Phase 0.2: a quest or police line jumps the rate cap but not the two on screen: with two up, the
## oldest ambient or reaction bubble goes (else the oldest of all).
func _make_room() -> void:
	if _bubbles.size() < Chatter.MAX_ON_SCREEN:
		return
	var drop := 0
	for i in _bubbles.size():
		if int(_bubbles[i].get("kind", Chatter.QUEST)) >= Chatter.REACTION:
			drop = i
			break
	_bubbles.remove_at(drop)


## Ambient chatter (crowds, dog walkers, bus stops...) keeps quiet while the player drives
## faster than AMBIENT_MUTE_KMH; quest, police and rival lines use `say` and always show.
## Phase 0.2: the whole budget is chatter.gd's (its MUTE_KMH is this).
const AMBIENT_MUTE_KMH := Chatter.MUTE_KMH

## Gives the player's speed in km/h (main.gd); unset means never muted.
var kmh: Callable
## Phase 0.2: true while the car struggles (main.gd: car.gd struggling() or the stuck offer up);
## ambient and reaction lines are dropped then and for Chatter.QUIET_AFTER s after.
var struggle: Callable
## Phase 0.2: true while a card (a job's, a ride's, the full map) is up; ambient lines wait.
var cards_up: Callable
## The one chatter budget (chatter.gd); its level is the setting (settings.gd `chatter`).
var chatter := Chatter.new()
## A focused moment (street_meet.gd's drag, PT-49): every speaker waits; nothing new shows.
var quiet_all := false


func muted() -> bool:
	return kmh.is_valid() and float(kmh.call()) > AMBIENT_MUTE_KMH


## Whether a line of `kind` (chatter.gd) would show now; the dialogue asks before it uses a line up.
## A refusal counts as dropped (chatter.gd `dropped`, the summary).
func allows(kind: int, key := "") -> bool:
	_sense()
	if chatter.allows(kind, count(), key):
		return true
	chatter.dropped[kind] += 1
	return false


## The budget's view of the game now: struggling, speed, a card up (the callables main.gd sets).
func _sense() -> void:
	chatter.sense(struggle.is_valid() and bool(struggle.call()),
			float(kmh.call()) if kmh.is_valid() else 0.0, cards_up.is_valid() and bool(cards_up.call()))


## `say` for ambient chatter: dropped while the player drives fast (G16), while the car struggles,
## while a card is up, or inside the budget's gap (chatter.gd).
func say_ambient(anchor: Variant, speaker: String, line: String, subtitle := "", seconds := 4.0,
		accent := Color("#ffd23f"), height := 2.6) -> bool:
	return say(anchor, speaker, line, subtitle, seconds, accent, height, Chatter.AMBIENT)


## `say` for someone reacting to the player (a shout, a near miss, a horn): one in
## Chatter.REACTION_WINDOW s, and none while the car struggles.
func say_reaction(anchor: Variant, speaker: String, line: String, subtitle := "", seconds := 4.0,
		accent := Color("#ffd23f"), height := 2.6, key := "") -> bool:
	return say(anchor, speaker, line, subtitle, seconds, accent, height, Chatter.REACTION, key)


## A bubble's size with its text wrapped `width` points wide: {size, name_h, line_h}.
func _measure(b: Dictionary, width: float) -> Dictionary:
	var font := ThemeDB.fallback_font
	var w := width * pt
	var line_size := font.get_multiline_string_size(b["line"], HORIZONTAL_ALIGNMENT_LEFT, w, _px(LINE_SIZE))
	var sub_size := Vector2.ZERO
	if b["sub"] != "":
		sub_size = font.get_multiline_string_size(b["sub"], HORIZONTAL_ALIGNMENT_LEFT, w, _px(SUB_SIZE))
	var name_h := font.get_height(_px(NAME_SIZE)) if b["speaker"] != "" else 0.0
	var name_w := font.get_string_size(String(b["speaker"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, _px(NAME_SIZE)).x
	var size := Vector2(maxf(line_size.x, maxf(sub_size.x, name_w)),
			name_h + line_size.y + (sub_size.y + 2.0 * pt if b["sub"] != "" else 0.0)) + Vector2.ONE * PAD * pt * 2.0
	return {"size": size, "name_h": name_h, "line_h": line_size.y}


## Removes the bubble over `anchor`, if any.
func hush(anchor: Variant) -> void:
	for i in range(_bubbles.size() - 1, -1, -1):
		if _same(_bubbles[i]["anchor"], anchor):
			_bubbles.remove_at(i)
	queue_redraw()


## Anchors can be nodes or callables; == between the two kinds is an error.
static func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


func clear() -> void:
	_bubbles.clear()
	queue_redraw()


## How many bubbles are up.
func count() -> int:
	return _bubbles.size()


func is_talking(anchor: Variant) -> bool:
	for b in _bubbles:
		if _same(b["anchor"], anchor):
			return true
	return false


## A small name label that stays over `anchor` until untag(); hidden while it talks.
func tag(anchor: Variant, text: String, colour: Color, height := 2.6) -> void:
	colour = Access.tint(colour)  # colour-safe (access.gd)
	for t in _tags:
		if _same(t["anchor"], anchor):
			t["text"] = text
			t["colour"] = colour
			return
	_tags.append({"anchor": anchor, "text": text, "colour": colour, "height": height})


func untag(anchor: Variant) -> void:
	for i in range(_tags.size() - 1, -1, -1):
		if _same(_tags[i]["anchor"], anchor):
			_tags.remove_at(i)


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	chatter.clock += dt
	_sense()
	if _bubbles.is_empty() and _tags.is_empty():
		return
	for i in range(_bubbles.size() - 1, -1, -1):
		var b := _bubbles[i]
		if b.get("waiting", false):
			b["waited"] = float(b.get("waited", 0.0)) + dt
		else:
			b["age"] = float(b["age"]) + dt
		if b["age"] >= b["life"] or float(b.get("waited", 0.0)) > MAX_WAIT \
				or (b["anchor"] is Object and not is_instance_valid(b["anchor"])):
			_bubbles.remove_at(i)
	queue_redraw()


func _where(anchor: Variant, height: float) -> Vector3:
	if anchor is Callable:
		return (anchor as Callable).call()
	if anchor is Node3D and is_instance_valid(anchor):
		return (anchor as Node3D).global_position + Vector3(0, height, 0)
	return Vector3.INF


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_paint()
	spent_usec += Time.get_ticks_usec() - t0


## The HUD's rects on screen now (empty without a HUD).
func _hud_rects() -> Array[Rect2]:
	var hud := get_parent()
	var out: Array[Rect2] = []
	if hud != null and hud.has_method("panel_rects"):
		out.assign(hud.panel_rects())
	return out


## Where bubbles may go: inside the safe area under the HUD's top row.
func _area() -> Rect2:
	var hud := get_parent()
	if hud != null and hud.has_method("bubble_area"):
		return hud.bubble_area()
	return get_viewport_rect().grow(-8.0 * pt)


## Loop 2e: where every bubble goes this frame: [bubble, speaker on screen, rect] each. Two
## speakers close together: the later bubble steps up (or down) out of the earlier one's way;
## every bubble keeps clear of the HUD's rects.
func layout() -> Array:
	var out := []
	rects.clear()
	overlaps = 0
	if not project.is_valid():
		return out
	var area := _area()
	var placed := _hud_rects()
	for b in _bubbles:
		var p := _where(b["anchor"], b["height"])
		if p == Vector3.INF:
			continue
		var at: Vector2 = project.call(p)
		var m: Dictionary = b["wide"]
		var found := _clear(_place(m["size"], at, area), placed, area)
		# No room as it is: wrapped narrower it may fit beside what's in the way, wider it may
		# fit a low gap.
		for alt in [["narrow", NARROW], ["widest", WIDE]]:
			if found[1]:
				break
			if not b.has(alt[0]):
				b[alt[0]] = _measure(b, alt[1])
			var other := _clear(_place(b[alt[0]]["size"], at, area), placed, area)
			if other[1]:
				found = other
				m = b[alt[0]]
		b["waiting"] = not found[1]
		if not found[1]:
			overlaps += 1
			continue
		var rect: Rect2 = found[0]
		placed.append(rect)
		rects.append(rect)
		out.append([b, at, rect, m])
	return out


func _paint() -> void:
	if not project.is_valid():
		return
	var font := ThemeDB.fallback_font
	var hud_rects := _hud_rects()
	var area := _area()
	for t in _tags:
		if is_talking(t["anchor"]):
			continue
		var p := _where(t["anchor"], t["height"])
		if p == Vector3.INF:
			continue
		var at: Vector2 = project.call(p)
		var fs := _px(NAME_SIZE)
		var text: String = t["text"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(at - Vector2(w * 0.5 + 4.0 * pt, font.get_height(fs) + 9.0 * pt), Vector2(w + 8.0 * pt, font.get_height(fs) + 4.0 * pt))
		if not area.encloses(box) or _first_hit(box, hud_rects, 0.0).has_area():
			continue  # off screen, or under the HUD
		draw_style_box(_tag_box, box)
		draw_string(font, box.position + Vector2(4.0 * pt, 2.0 * pt + font.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, t["colour"])
	for item in layout():
		_draw_bubble(item[0], font, item[1], item[2], item[3])


## The first rect in `list` that `r` (grown by `gap`) touches, or an empty one.
static func _first_hit(r: Rect2, list: Array[Rect2], gap: float) -> Rect2:
	for o in list:
		if r.grow(gap).intersects(o):
			return o
	return Rect2()


## Where a bubble of `size` wants to be: centred over its speaker, kept inside the area.
func _place(size: Vector2, at: Vector2, area: Rect2) -> Rect2:
	var tail := TAIL * pt
	var rect := Rect2(at - Vector2(size.x * 0.5, size.y + tail), size)
	rect.position.x = clampf(rect.position.x, area.position.x, area.end.x - size.x)
	rect.position.y = clampf(rect.position.y, area.position.y, area.end.y - size.y - tail)
	if rect.grow(4.0 * pt).has_point(at):
		# Pushed down over its speaker (near the top of the screen): beside it instead.
		var right := at.x + tail * 1.6
		var left := at.x - tail * 1.6 - size.x
		rect.position.x = right if right + size.x < area.end.x or left < area.position.x else left
		rect.position.y = clampf(at.y - size.y * 0.5, area.position.y, area.end.y - size.y)
	return rect


## Loop 2e: the nearest free spot for `rect`: where it is, or moved up or down past whatever it
## covers, or first beside the thing in its way (left or right) and then up or down; always
## inside the area. Returns [rect, found]; when nothing is free, [the rect as it was, false].
func _clear(rect: Rect2, placed: Array[Rect2], area: Rect2) -> Array:
	var gap := 4.0 * pt
	var first := _first_hit(rect, placed, gap)
	if not first.has_area():
		return [rect, true]
	var best := rect
	var best_d := INF
	for x: float in [rect.position.x, first.end.x + gap, first.position.x - gap - rect.size.x]:
		if x < area.position.x or x + rect.size.x > area.end.x:
			continue
		for dir: float in [-1.0, 1.0]:
			var r := Rect2(Vector2(x, rect.position.y), rect.size)
			for i in 10:
				var hit := _first_hit(r, placed, gap)
				if not hit.has_area():
					var d := absf(r.position.y - rect.position.y) + absf(x - rect.position.x)
					if d < best_d:
						best_d = d
						best = r
					break
				r.position.y = hit.position.y - gap - r.size.y if dir < 0.0 else hit.end.y + gap
				if r.position.y < area.position.y or r.end.y > area.end.y:
					break
	return [best, best_d < INF]


## PT-9: the tail of a bubble at `rect` for a speaker at `at`: [foot, outward direction, tip].
## It leaves the edge facing the speaker (the lower edge, unless the bubble had to move beside
## it) and runs all the way to the speaker, up to REACH points (a bubble kept clear of the HUD
## used to get a stub of 22 pt that ended in the air away from its car); further, it points the
## way and stops there.
func tail_geometry(at: Vector2, rect: Rect2) -> Array:
	var inner := rect.grow(-10.0 * pt)
	var out := Vector2(0, 1)
	var foot := Vector2(clampf(at.x, inner.position.x, inner.end.x), rect.end.y - 1.0 * pt)
	if at.y < rect.end.y and at.x > rect.end.x:
		out = Vector2(1, 0)
		foot = Vector2(rect.end.x - 1.0 * pt, clampf(at.y, inner.position.y, inner.end.y))
	elif at.y < rect.end.y and at.x < rect.position.x:
		out = Vector2(-1, 0)
		foot = Vector2(rect.position.x + 1.0 * pt, clampf(at.y, inner.position.y, inner.end.y))
	elif at.y < rect.position.y:
		# The bubble sits below its speaker (kept clear of the HUD): the tail goes up.
		out = Vector2(0, -1)
		foot = Vector2(clampf(at.x, inner.position.x, inner.end.x), rect.position.y + 1.0 * pt)
	var tip := foot + (at - foot).limit_length(REACH * pt)
	if (tip - foot).dot(out) < 3.0 * pt:
		tip = foot + out * TAIL * pt
	return [foot, out, tip]


## How far the tail's tip is from the speaker (0 when it reaches); for tools/check_hud.gd.
func tail_gap(at: Vector2, rect: Rect2) -> float:
	return (tail_geometry(at, rect)[2] as Vector2).distance_to(at)


func _draw_bubble(b: Dictionary, font: Font, at: Vector2, rect: Rect2, m: Dictionary) -> void:
	var age: float = b["age"]
	var alpha := clampf((float(b["life"]) - age) / FADE, 0.0, 1.0) * clampf(age / 0.12, 0.0, 1.0)
	var size: Vector2 = m["size"]
	var geo := tail_geometry(at, rect)
	var foot: Vector2 = geo[0]
	var tip: Vector2 = geo[2]
	var out: Vector2 = geo[1]
	var side := Vector2(-out.y, out.x) * 5.0 * pt
	draw_colored_polygon(PackedVector2Array([foot - side * 1.3, foot + side * 1.3, tip + (tip - foot).normalized() * 1.2 * pt]),
			Color(1, 1, 1, 0.3 * alpha))
	# The style box draws at once, so one shared box can change alpha per bubble.
	_panel.bg_color.a = CARD_BG.a * alpha
	_panel.border_color.a = 0.3 * alpha
	draw_style_box(_panel, rect)
	draw_colored_polygon(PackedVector2Array([foot - side, foot + side, tip]), Color(CARD_BG, CARD_BG.a * alpha))
	var pad := PAD * pt
	var y := rect.position.y + pad
	var x := rect.position.x + pad
	var w := size.x - pad * 2.0
	var accent: Color = b["accent"]
	if b["speaker"] != "":
		var fs := _px(NAME_SIZE)
		draw_string(font, Vector2(x, y + font.get_ascent(fs)), b["speaker"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(accent.lerp(Color.WHITE, 0.15), alpha))
		y += float(m["name_h"])
	var line: String = b["line"]
	var ls := _px(LINE_SIZE)
	if age < float(b["typing"]):
		_draw_typing(font, Vector2(x, y), line, int(age * TYPE_RATE), w + 1.0, ls, Color(INK, alpha))
	else:
		draw_multiline_string(font, Vector2(x, y + font.get_ascent(ls)), line, HORIZONTAL_ALIGNMENT_LEFT, w + 1.0, ls, -1, Color(INK, alpha))
	y += float(m["line_h"]) + 2.0 * pt
	if b["sub"] != "" and age >= float(b["typing"]) * 0.5:
		var ss := _px(SUB_SIZE)
		draw_multiline_string(font, Vector2(x, y + font.get_ascent(ss)), b["sub"], HORIZONTAL_ALIGNMENT_LEFT, w + 1.0, ss, -1, Color(SUB, alpha))


## PT-9: the first `n` characters of `line`, on the lines of the WHOLE line. Wrapping only the typed
## prefix moved a half-typed word down to the next line and back, so a bubble showed words cut off
## and jumping about; here every word stays where it will end up.
func _draw_typing(font: Font, top: Vector2, line: String, n: int, width: float, size: int, colour: Color) -> void:
	var para := TextParagraph.new()
	para.add_string(line, font, size)
	para.width = width
	var y := top.y
	for i in para.get_line_count():
		var r := para.get_line_range(i)
		var shown := clampi(n - r.x, 0, r.y - r.x)
		if shown > 0:
			draw_string(font, Vector2(top.x, y + para.get_line_ascent(i)), line.substr(r.x, shown), HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
		y += para.get_line_size(i).y
