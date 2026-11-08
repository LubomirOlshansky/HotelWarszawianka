class_name LoadYield
extends RefCounted
## The loading bar's frames (F, 2026-11-08: "the loading animation lags"; on a Nothing Phone the
## build's steps took 1.8-4.5 s each, so the title froze for seconds between two frames).
## The build runs on the main thread, so the title (bar, prompt) only moves in the frames the
## build lets through. `tick` is the one place to let one through: a long setup calls
## `await LoadYield.tick("what")` between its parts or every few loop turns, and it shows a frame
## when `GAP_MS` have passed since the last one. Off (a plain return) unless main.gd turns it on
## for the title's build: test runs and the game at play build as before.
const GAP_MS := 12
## Slices over this are printed ("loading bar: slice ...") so a phone's log names the next call to split.
const SLOW_MS := 150
static var on := false
static var _last_ms := 0


## Start the clock of a build under the title.
static func begin() -> void:
	on = true
	_last_ms = Time.get_ticks_msec()


static func finish() -> void:
	on = false


## A frame was shown by someone else (main.gd's own steps): the clock starts again.
static func mark() -> void:
	_last_ms = Time.get_ticks_msec()


## A frame for the title, if the last one was GAP_MS or more ago. `what` names the work just done.
static func tick(what: String = "") -> void:
	if not on:
		return
	var now := Time.get_ticks_msec()
	if now - _last_ms < GAP_MS:
		return
	if now - _last_ms >= SLOW_MS and what != "":
		print("loading bar: slice %d ms, up to %s" % [now - _last_ms, what])
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	await tree.process_frame
	_last_ms = Time.get_ticks_msec()
