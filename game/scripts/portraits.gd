class_name Portraits
extends RefCounted
## The callers' faces for the phone view and the quest cards (hud.gd show_call, show_side_card's
## `face`). A face is res://art/portraits/<key>.png (256 px, the 2026-11-10 portrait set), the
## key being the caller's first name in lower case without Polish letters ("Mrożulo" ->
## mrozulo). A caller without art yet gets null, and the HUD draws the fallback: their initial on a disc in the activity's colour, so every
## call looks finished before its portrait lands (F 2026-11-10).
## F 2026-11-11: the same small face sits beside every quest and police line too (bubbles.gd, the
## Senatorek talk panel in lounge.gd, the club's in club.gd), so a line says who is speaking at a
## glance, not by a name alone; `paint` draws it for all of them and the phone call view.

const DIR := "res://art/portraits/"
## A name whose face file has a longer key (the only Kuba who calls is the padel one).
const ALIAS := {"kuba": "kuba_padel"}

## Speakers that are not a person (the sat-nav, a lift, the player, a crowd): their lines keep the
## name only, no face. Compared on `key` (first word, plain, lower case).
const NO_FACE := ["ty", "you", "nawigacja", "start", "kebab", "podwozka", "winda", "lift",
		"goscie", "guests", "ktos", "someone"]

static var _cache := {}


## The face for `who` ("Ivan", "Darek „Bawarka”", "+33 · Claire"), or null when there is no art.
static func face(who: String) -> Texture2D:
	var k := key(who)
	k = String(ALIAS.get(k, k))
	if k == "":
		return null
	if not _cache.has(k):
		var path := DIR + k + ".png"
		_cache[k] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[k]


## True when `who` gets a face beside their lines (a person with a name), false for "" and NO_FACE.
static func has_face(who: String) -> bool:
	var k := key(who)
	return k != "" and not k in NO_FACE


## A round face of radius `r` at `mid` on `ci`: the portrait cut to a circle, or the initial on a
## disc in the accent; a ring in the accent round it (`ring` px wide). `alpha` fades it with its
## bubble. Draw from `ci`'s draw signal or _draw (CanvasItem draw calls).
static func paint(ci: CanvasItem, mid: Vector2, r: float, tex: Texture2D, letter: String, accent: Color,
		ring: float, alpha := 1.0) -> void:
	if tex != null:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 40:
			var d := Vector2.from_angle(TAU * i / 40.0)
			pts.append(mid + d * r)
			uvs.append(Vector2(0.5, 0.5) + d * 0.5)
		ci.draw_colored_polygon(pts, Color(1, 1, 1, alpha), uvs, tex)
	else:
		ci.draw_circle(mid, r, Color(accent.darkened(0.55), alpha), true, -1.0, true)
		var font := ThemeDB.fallback_font
		var size := roundi(r * 1.05)
		var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var y := mid.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
		ci.draw_string(font, Vector2(mid.x - w.x * 0.5, y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				Color(accent.lightened(0.35), alpha))
	ci.draw_arc(mid, r, 0.0, TAU, 48, Color(accent, alpha), ring, true)


## A small face for a talk panel (lounge.gd, club.gd): a Control `px` pixels square that paints
## the face of whoever `set_badge` last named, hidden for a speaker without one.
static func badge(px: float) -> Control:
	var c := Control.new()
	c.name = "face"
	c.custom_minimum_size = Vector2.ONE * px
	c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # 256 px drawn small
	c.set_meta("who", "")
	c.set_meta("accent", Color.WHITE)
	c.draw.connect(func() -> void:
		var who := String(c.get_meta("who"))
		paint(c, c.size * 0.5, minf(c.size.x, c.size.y) * 0.5 - 1.0, face(who), initial(who),
				c.get_meta("accent"), maxf(1.5, c.size.x / 18.0)))
	c.visible = false
	return c


## Points a badge at `who` (`accent` its ring and fallback disc); hides it for a speaker without a face.
static func set_badge(c: Control, who: String, accent: Color) -> void:
	c.set_meta("who", who)
	c.set_meta("accent", accent)
	c.visible = has_face(who)
	c.queue_redraw()


## The file key: the first word made only of letters, lower case, Polish letters plain.
static func key(who: String) -> String:
	for word in who.split(" ", false):
		var w := plain(word).to_lower()
		var out := ""
		for ch in w:
			if (ch >= "a" and ch <= "z") or ch == "_":
				out += ch
		if out.length() >= 2:
			return out
	return ""


## The fallback's letter: the first letter of the name (after any "+33 ·").
static func initial(who: String) -> String:
	for ch in who:
		if ch.to_upper() != ch.to_lower():
			return ch.to_upper()
	return "?"


static func plain(s: String) -> String:
	const FROM := "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"
	const TO := "acelnoszzACELNOSZZ"
	var out := ""
	for ch in s:
		var i := FROM.find(ch)
		out += TO[i] if i >= 0 else ch
	return out
