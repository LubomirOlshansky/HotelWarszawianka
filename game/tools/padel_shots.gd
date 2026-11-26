extends SceneTree
## Stills of the arcade padel match with a timed human (padel_match.gd, docs/design/critique-padel.md).
## A bot taps on the ring with a 45 ms error, the way a decent hand would, and the screen is saved at
## the moments worth looking at: the how-to card and the warm-up (a fresh run opens with them), the ring
## open, closing, the CZYSTO hit, a long rally.
## Needs a renderer (never --headless):
##   godot --path game --resolution 1170x540 --script res://tools/padel_shots.gd -- [--out=DIR] [--hour=H] [--max=N]
## Writes DIR/padel_NN_what.png (default ../shots/padel, gitignored) and prints one line a still.

const PadelSim := preload("res://scripts/padel_sim.gd")
const PadelMatch := preload("res://scripts/padel_match.gd")

var match_node: Node
var out := "../shots/padel"
var hour := 14.7
var max_shots := 12
var _frame := 0
var _shots := 0
var _noise := 0.0
var _ball_n := -1
var _rng := RandomNumberGenerator.new()
var _seen := {}
var _last_shot_t := -10.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--max="):
			max_shots = int(a.substr(6))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join(out))
	_rng.seed = 11
	match_node = PadelMatch.new()
	root.add_child(match_node)
	match_node.auto_play = false


func _process(_dt: float) -> bool:
	_frame += 1
	if _frame == 2:
		match_node.enter({"partner": "Kuba", "rivals": ["Prezes", "Zbyszek"], "hour": hour, "seed": 5})
	if _frame < 3:
		return false
	var sim: PadelSim = match_node.sim
	if sim == null or not match_node.inside:
		quit(0)
		return true
	var me := sim.players[0]
	# The how-to card first (a fresh run shows it), then a tap starts the warm-up.
	if match_node._howto:
		if _frame > 50:
			_grab("howto", sim)
		if _frame > 70:
			match_node._start_warmup()
		return false
	if sim.warming() and sim.phase == PadelSim.Phase.PLAY and sim.cue_left() < 0.12 and sim.cue_left() > 0.04:
		_grab("warmup_ring", sim)
	if match_node._warm_end_t >= 0.0 and match_node._t - match_node._warm_end_t > 0.3:
		_grab("warmup_done", sim)
	if sim.phase == PadelSim.Phase.PLAY:
		if sim.rally_hits != _ball_n:
			_ball_n = sim.rally_hits
			_noise = _rng.randfn(0.0, 0.045)
		if sim.cue_at >= 0.0 and me.swing < 0.0 and sim.time >= sim.cue_at - PadelSim.LEAD + _noise:
			sim.press(PadelSim.Shot.DRIVE)
	elif sim.phase == PadelSim.Phase.SERVE and sim.server == 0 and sim.phase_t > 0.5:
		sim.press(PadelSim.Shot.DRIVE)
	# The moments.
	var left := sim.cue_left()
	if sim.phase == PadelSim.Phase.PLAY and left < INF and not sim.warming():
		if left < 0.5 and left > 0.35:
			_grab("ring_open", sim)
		elif left < 0.12 and left > 0.05:
			_grab("ring_closing", sim)
	if match_node._ring_flash > 0.85:
		_grab("clean_flash" if not sim.warming() else "warmup_clean", sim)
	if sim.phase == PadelSim.Phase.PLAY and sim.rally_hits >= 8:
		_grab("rally", sim)
	if match_node._tell > 0.6 and match_node._tell_s != "":
		_grab("tell", sim)
	if match_node._callout_t > 0.0 and String(match_node._callout).begins_with("GEM") or sim.phase == PadelSim.Phase.GAME:
		_grab("game", sim)
	if _shots >= max_shots or _frame > 60 * 400:
		quit(0)
	return false


func _grab(what: String, sim: PadelSim) -> void:
	if _seen.has(what) or sim.time - _last_shot_t < 0.4:
		return
	_seen[what] = true
	_last_shot_t = sim.time
	_shots += 1
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://").path_join(out).path_join("padel_%02d_%s.png" % [_shots, what])
	img.save_png(path)
	print("padel_shots: %s at %.1f s (rally %d)" % [path.get_file(), sim.time, sim.rally_hits])
