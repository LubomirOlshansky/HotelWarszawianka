class_name Portraits
extends RefCounted
## The callers' faces for the phone view and the quest cards (hud.gd show_call, show_side_card's
## `face`). A face is res://art/portraits/<key>.png (256 px, the 2026-11-10 portrait set), the
## key being the caller's first name in lower case without Polish letters ("Mrożulo" ->
## mrozulo). A caller without art yet gets null, and the HUD draws the fallback: their initial on a disc in the activity's colour, so every
## call looks finished before its portrait lands (F 2026-11-10).

const DIR := "res://art/portraits/"
## A name whose face file has a longer key (the only Kuba who calls is the padel one).
const ALIAS := {"kuba": "kuba_padel"}

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
