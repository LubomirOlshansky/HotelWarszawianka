extends RefCounted
## The game's language (2026-11-02, F: "Polish or English, not two simultaneously"). The game
## used to show every text in Polish with its English under it or beside it; now the player
## picks ONE language, on the title screen or in Settings → DŹWIĘK → JĘZYK · Language, and every
## screen shows only that one. Text is still written as a pair (Polish, English): the HUD's
## entry points (hud.gd `toast`, `show_card`, `ticker`, ...) and the other text widgets call
## `pair` / `pick`, so the secondary label is simply never filled. A text with no English
## (a street, a place, a parody name, a song) shows as it is in both languages.
##   code      "pl" or "en": settings.gd keeps the choice (`lang`, "" until the player makes one,
##             then English).
##   pair      (pl, en) -> [shown, ""]: the second slot is always empty, so a caller that fills a
##             "gloss" label with it hides that label.
##   pick      (pl, en) -> the shown one, for a single label.
##   split     "POLSKI · ENGLISH" or "Polski\nEnglish" (older inline pairs) -> the shown half.

const PL := "pl"
const EN := "en"
const CODES := [PL, EN]
## What the language buttons say: each language in its own tongue.
const NAMES := {"pl": "POLSKI", "en": "ENGLISH"}

static var code := PL


static func is_en() -> bool:
	return code == EN


## The language of a player who has not chosen yet (F, 2026-11-08): English, on every phone.
static func device_code() -> String:
	return EN


## "" (never chosen) follows the device; anything else must be a known code.
static func resolve(saved: String) -> String:
	return saved if saved in CODES else device_code()


static func set_code(c: String) -> void:
	code = c if c in CODES else PL


## The text to show, from a Polish and an English one. No English: the Polish stands (names).
static func pick(pl: String, en: String) -> String:
	return en if code == EN and en != "" else pl


## [shown, ""]: for sinks with a main label and a gloss label under or beside it.
static func pair(pl: String, en: String) -> PackedStringArray:
	return PackedStringArray([pick(pl, en), ""])


## An inline pair "POLSKI · ENGLISH" (or split by `sep`): the half for the chosen language. A text
## without the separator is returned whole.
static func split(s: String, sep := " · ") -> String:
	if not sep in s:
		return s
	var at := s.find(sep)
	return s.substr(0, at) if code == PL else s.substr(at + sep.length())


## The stock words of the HUD's Polish-only mission titles ("WYŚCIG · A → B", "ODBIÓR"), for the
## status panel, which has no English title of its own. Names of jobs and services (KEBAB,
## SŁOIKI, PODWÓZKA, MLASK, Leżak) are the game's own words and stay.
const TITLE_WORDS := {
	"DO SZPITALA": "TO THE HOSPITAL", "NA CZASIE": "ON TREND", "TRZY MOSTY": "THREE BRIDGES",
	"ODBIÓR": "PICK-UP", "WYŚCIG": "RACE", "KOLEJKA": "QUEUE", "LIMITKA": "LIMITED DROP",
	"CZWARTY": "FOURTH PLAYER", "BAGAŻNIK": "BOOT", "LEŻAKI": "LEŻAKS", "PAKA": "BOOT", "META": "FINISH", "MOST ": "BRIDGE ",
}


## A Polish-only title in the chosen language (Polish: as it is).
static func title(s: String) -> String:
	if code != EN:
		return s
	for k: String in TITLE_WORDS:
		s = s.replace(k, TITLE_WORDS[k])
	return s
