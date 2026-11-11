extends RefCounted
## The chatter budget (docs/GAMEPLAY_PLAN.md 0.2, F 2026-11-03: "when I'm driving and getting
## stuck, each second a few or more dialogs ... not every collision makes a comment"). About 25
## scripts speak through bubbles.gd and hud.toast, each with its own cooldown; this is the one
## budget they all go through, so the screen talks only when it has something to say.
##
## Every line has a class: QUEST (jobs, rides, rescues, rivals, the guide, easter eggs), POLICE,
## REACTION (someone reacting to the player: a driver's shout, a near miss, a dog walker at a horn,
## a cyclist in the bike lane) and AMBIENT (crowds, packs, bus stops, the city's chatter).
##
## - QUEST and POLICE always show; they still count as "a new bubble" for the rate cap and take
##   the room of an ambient or reaction bubble when two are up (bubbles.gd).
## - REACTION and AMBIENT: at most MAX_ON_SCREEN up, at least gap() s after the last new bubble,
##   none above MUTE_KMH (G16), none while the car struggles (pinned, pressing into something,
##   stalled, the stuck offer up) and for QUIET_AFTER s after.
## - REACTION: one in REACTION_WINDOW s; a reaction to a bump only for a hit of BUMP_MIN_KMH or
##   more; a near miss at most once in NEAR_MISS_GAP s.
## - AMBIENT also waits while a card (a job's, a ride's, the full map) is up.
## - Toasts (hud.gd ambient_toast): flavour toasts are dropped while quiet.
## - The context (messages.gd, set by hud.gd each frame, docs/design/hud-messages.md): while a quest
##   runs no AMBIENT line; in a chase or a scripted moment no REACTION either, and one bubble at a
##   time (`max_on_screen`): the quest's newest line takes the place of the one before.
##
## The setting (Settings → ŚWIAT → Gadatliwość miasta, settings.gd `chatter`): Mało / Średnio
## (default) / Dużo picks the gap (GAPS). Pure state on its own clock: tools/check_chatter.gd
## drives it with tick() and no game.

const Access := preload("res://scripts/access.gd")

enum {QUEST, POLICE, REACTION, AMBIENT}

## Seconds between two new bubbles for each level: Mało, Średnio (the default), Dużo.
const GAPS := [8.0, 4.0, 2.5]
const LEVEL_NAMES := ["few", "some", "lots"]
const DEFAULT_LEVEL := 1
const MAX_ON_SCREEN := 2
const MUTE_KMH := 40.0
const QUIET_AFTER := 5.0
const REACTION_WINDOW := 20.0
const BUMP_MIN_KMH := 15.0
## A bump's reaction (a driver's shout) comes in the same moment as the hit: the hit counts this long.
const HIT_MEMORY := 0.6
const NEAR_MISS_GAP := 60.0

## Reading time (F 2026-11-05: "messages disappear too fast, I don't have time to read"): how long
## a line stays up is its length, not a fixed few seconds. READ_BASE s to notice it, then
## READ_PER_CHAR per character (about 16 characters a second, slow enough for a glance at a phone
## while driving), never under READ_MIN or over READ_MAX; large text (access.gd) adds its scale.
const READ_BASE := 1.4
const READ_PER_CHAR := 0.065
const READ_MIN := 3.0
const READ_MAX := 11.0

var level := DEFAULT_LEVEL
## messages.gd's context now: 0 free roam, 1 a quest, 2 a chase, 3 a scripted moment (hud.gd sets it).
var context := 0
var clock := 0.0
## The player's speed now (km/h) and whether a card is up; set by tick().
var kmh := 0.0
var cards := false
## How many lines were let through and dropped, by class (tools/check_chatter.gd, the bench log).
var shown := [0, 0, 0, 0]
var dropped := [0, 0, 0, 0]

var _last_new := -INF
var _reaction_at := -INF
var _near_miss_at := -INF
var _quiet_until := -INF
var _hit_at := -INF
var _hit_kmh := 0.0


## Seconds a line of `text` (all of it, English gloss included) needs to be read.
static func read_time(text: String) -> float:
	var t := READ_BASE + text.length() * READ_PER_CHAR
	return clampf(t * Access.text_scale, READ_MIN, READ_MAX * Access.text_scale)


## How many bubbles may be up at once: MAX_ON_SCREEN, one in a chase or a scripted moment.
func max_on_screen() -> int:
	return 1 if context >= 2 else MAX_ON_SCREEN


func gap() -> float:
	return GAPS[clampi(level, 0, GAPS.size() - 1)]


## Moves the clock on; `struggling` is the car's state this frame (car.gd struggling(), the stuck
## offer), `speed_kmh` the player's speed, `cards_up` whether a card is on screen.
func tick(dt: float, struggling := false, speed_kmh := 0.0, cards_up := false) -> void:
	clock += dt
	sense(struggling, speed_kmh, cards_up)


## The game's state now, without moving the clock (bubbles.gd asks before each line, so a line in
## the frame the car got pinned already keeps quiet).
func sense(struggling: bool, speed_kmh: float, cards_up: bool) -> void:
	kmh = speed_kmh
	cards = cards_up
	if struggling:
		_quiet_until = clock + QUIET_AFTER


## True while the car is struggling and for QUIET_AFTER s after.
func quiet() -> bool:
	return clock < _quiet_until


## The player's car hit something at `speed_kmh` (car.gd bumped).
func hit(speed_kmh: float) -> void:
	if clock - _hit_at > HIT_MEMORY or speed_kmh > _hit_kmh:
		_hit_kmh = speed_kmh
	_hit_at = clock


## Whether a line of `kind` may show now, with `on_screen` bubbles already up (not counting one
## it replaces). `key` narrows a reaction: "bump" (needs a hard enough hit just now) or
## "near_miss" (once a minute). Nothing is recorded: call take() when the line really shows.
func allows(kind: int, on_screen := 0, key := "") -> bool:
	if kind == QUEST or kind == POLICE:
		return true
	if (context >= 1 and kind == AMBIENT) or (context >= 2 and kind == REACTION):
		return false
	if quiet() or kmh > MUTE_KMH or on_screen >= max_on_screen():
		return false
	if clock - _last_new < gap():
		return false
	if kind == AMBIENT:
		return not cards
	# REACTION
	if clock - _reaction_at < REACTION_WINDOW:
		return false
	if key == "bump" and (clock - _hit_at > HIT_MEMORY or _hit_kmh < BUMP_MIN_KMH):
		return false
	if key == "near_miss" and clock - _near_miss_at < NEAR_MISS_GAP:
		return false
	return true


## allows() and, when it does, takes the slot; counts both outcomes.
func take(kind: int, on_screen := 0, key := "") -> bool:
	if not allows(kind, on_screen, key):
		dropped[kind] += 1
		return false
	shown[kind] += 1
	_last_new = clock
	if kind == REACTION:
		_reaction_at = clock
		if key == "near_miss":
			_near_miss_at = clock
	return true


## A flavour toast (hud.gd ambient_toast) may show: not while quiet.
func toast_ok() -> bool:
	return not quiet()


func summary() -> String:
	return "chatter %s: shown q%d p%d r%d a%d, dropped r%d a%d" % [LEVEL_NAMES[clampi(level, 0, 2)],
			shown[QUEST], shown[POLICE], shown[REACTION], shown[AMBIENT], dropped[REACTION], dropped[AMBIENT]]
