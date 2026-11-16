extends RefCounted

const Lang := preload("res://scripts/lang.gd")
## The in-game credits and licences (DEMO 3j, WORKFLOW "TestFlight": the credits and licences
## screen; Settings → DŹWIĘK → LICENCJE). The same facts as CREDITS.md, in the player's words:
## the open data the city is built from (OpenStreetMap ODbL, GUGiK, the trees' CC BY 4.0), the
## engine and the add-ons shipped in the build, and every radio track with its licence line from
## data/radio.json, so a song added with tools/add_music.py shows up here without an edit.
## tools/check_credits.gd keeps this list, the add-on folders and radio.json in step.

## One block per section: [Polish heading, English heading, [lines]]. A line is "Polish · English"
## where the two differ (the pair is split by " ‖ ", lang.gd `split`), or one line where it is a name or
## a licence.
const DATA := [
	["Mapa", "Map data", [
		"© OpenStreetMap contributors",
		"Open Database License (ODbL) 1.0 · openstreetmap.org/copyright",
		"Ulice, budynki, drzewa, latarnie, woda, nazwy ‖ roads, buildings, trees, lamps, water, names",
	]],
	["GUGiK", "Polish geodetic office", [
		"Źródło danych: Główny Urząd Geodezji i Kartografii · geoportal.gov.pl",
		"Budynki 3D (LoD2), teren (NMT), ortofotomapa ‖ 3D buildings, terrain, aerial photo",
		"Modele drzew 3D (LoD1): CC BY 4.0, uproszczone ‖ 3D trees: CC BY 4.0, simplified",
	]],
	["Gra", "The game", [
		"Around Warsaw: darmowa gra fanów ‖ a free fan game",
		"Kod, modele, dźwięki, muzyka i teksty: wszelkie prawa zastrzeżone ‖ code, art, sound, music, text: all rights reserved",
		"Marki w grze to parodie ‖ brands in the game are parodies",
	]],
	["Silnik", "Engine and add-ons", [
		"Godot Engine: MIT · godotengine.org/license",
		"Phantom Camera (Marcus Skov): MIT",
		"beehave (bitbrain and contributors): MIT",
		"Dialogue Manager (Nathan Hoad and contributors): MIT",
		"Debug Draw (HardPixel): MIT",
		"PostHog for Godot (PostHog): MIT · anonimowe statystyki ‖ anonymous stats",
	]],
]

## The add-on folders under addons/ that ship in the build, each named in DATA's engine section
## (nw_android_export is the project's own export plugin, left out of the export).
const ADDONS := {
	"phantom_camera": "Phantom Camera",
	"beehave": "beehave",
	"dialogue_manager": "Dialogue Manager",
	"debug_draw": "Debug Draw",
	"posthog": "PostHog",
}


## Every section to show, the radio's tracks last: [[pl, en, [lines]], ...].
static func sections(radio_path: String = "res://data/radio.json") -> Array:
	var out: Array = DATA.duplicate(true)
	var lines: Array = []
	for t in tracks(radio_path):
		lines.append("%s · %s: %s (%s)" % [t["station"], t["title"], t["artist"], t["licence"]])
	out.append(["Radio", "Music", lines])
	return out


## The radio's tracks as {station, title, artist, licence}, read from radio.json (radio.gd's file).
static func tracks(radio_path: String = "res://data/radio.json") -> Array:
	var out: Array = []
	var f := FileAccess.open(radio_path, FileAccess.READ)
	if f == null:
		return out
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		return out
	for s in (data as Dictionary).get("stations", []):
		for t in (s as Dictionary).get("tracks", []):
			var licence := String((t as Dictionary).get("licence", "unknown"))
			out.append({
				"station": String(s.get("name", "?")),
				"title": String(t.get("title", "?")),
				"artist": String(t.get("artist", "?")),
				"licence": licence.replace("own: synthesised by ", Lang.pick("własna, ", "own, ")),
			})
	return out


## All the text, one string (the check searches it).
static func text() -> String:
	var parts: PackedStringArray = []
	for s in sections():
		parts.append("%s · %s" % [s[0], s[1]])
		for l in s[2]:
			parts.append(String(l).replace(" ‖ ", " · "))
	return "\n".join(parts)
