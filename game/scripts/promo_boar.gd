extends Node3D
## PROMO ONLY (F, 2026-11-26: "for the reels, model the dzik, then flying around the Palac Kultury i
## Nauki in vertical view, the dzik with wings"; round 2: "stylish dzik in my game's style, real
## wings, funny, viral, views from the height, Złote Tarasy, 10-13 s"). The winged boar (boar.gd)
## and two striped piglets fly round the Palace of Culture under main.gd's camera turned perspective.
## One shot a run, cut together afterwards (/mnt/project-files/boar-reel/PLAN-v2.md):
##   unbonk  0-1 s    the nose disc at the lens, pulling back to the face, the Palace behind
##   chase   1-4 s    behind and above, flying ENE from over Złote Tarasy towards the Palace
##   orbit   4-6.8 s  beside it at the clock's height, a quarter round the tower
##   wide    6.8-9.3  high south of Złote Tarasy (out of Varso's shadow) looking NE: the family flies
##                    in from the sunlit Palace towards the lens, faces lit
##   selfie  9.3-12   ahead of it looking back, then it speeds up into the lens (the bonk)
## --promo-boar=SHOT[,skip=S][,nopiglets] (dev_flags.gd). BOAR_OVR='{"key": value}' overrides a
## shot's numbers for framing rounds.

## The Palace's tower axis (world x/z); ground 16.8 m, shaft top ~146 m, spire tip 236 m.
const PKIN := Vector2(-1214.0, 247.0)
## The boar is built 1.35 m long; the promo shows it at 2.5 m so it reads in the sky.
const SCALE := 1.85

## Shot numbers. Path: from/to (world x, height over the ground, z) over the shot's length `len` (s);
## camera in the boar's frame (fwd, side +right, up) from cam0 to cam1, and the look point (fwd, up).
const SHOTS := {
	# Fable (round 3): a three-quarter face, 1 m above, wings open, the gold Palace behind (the boar
	# flies SW away from it, towards the lens, lit by the low SW sun).
	"unbonk": {"len": 1.2, "from": [-1296.0, 112.0, 310.0], "to": [-1318.0, 110.0, 326.0],
		"cam0": [3.4, -1.7, 1.0], "cam1": [6.5, -2.6, 1.6], "look": [0.3, 0.7], "fov0": 55.0, "fov1": 55.0},
	"chase": {"len": 3.2, "from": [-1440.0, 80.0, 420.0], "to": [-1350.0, 108.0, 348.0],
		"cam0": [-11.0, 1.5, 6.0], "cam1": [-10.0, 1.0, 6.0], "look": [16.0, -4.5], "fov0": 55.0, "fov1": 55.0},
	"orbit": {"len": 3.0, "r": 40.0, "h": 150.0, "a0": 300.0, "a1": 345.0,
		"cam0": [-1.0, -11.0, 3.5], "cam1": [1.0, -11.0, 3.5], "look": [0.0, -0.5], "fov0": 48.0, "fov1": 48.0, "blend": 0.18},
	# F (2026-11-26): further back, the whole of Złote Tarasy and Złota 44 in, less sky. ~700 m from
	# the Palace, 270 m up, south of Varso (out of its shadow), 23 degrees down.
	"wide": {"len": 2.6, "eye": [-1650.0, 270.0, 800.0], "target": [-1300.0, 30.0, 360.0],
		"from": [-1606.4, 255.0, 745.2], "to": [-1632.6, 262.0, 778.1], "fov0": 60.0, "fov1": 58.0},
	"selfie": {"len": 2.6, "from": [-1170.0, 150.0, 190.0], "to": [-1120.0, 156.0, 150.0],
		"cam0": [4.0, 0.4, 1.8], "cam1": [4.0, 0.4, 1.8], "look": [0.0, 0.3], "fov0": 62.0, "fov1": 62.0,
		"bonk": 1.8},
}

var shot_name := "chase"
var shot: Dictionary
var skip := 4.0
var age := 0.0
var main: Node
var ground := 0.0
var boar: Dictionary
var piglets: Array[Dictionary] = []
var _pos := Vector3.ZERO
var _fwd := Vector3.FORWARD
var _side := Vector3.RIGHT
var _cam_hold := Vector3.ZERO  ## the selfie camera's last place before the bonk


static func parse(opts: String) -> Dictionary:
	var o := {"shot": "chase", "skip": 4.0, "piglets": true}
	for p in opts.split(",", false):
		if SHOTS.has(p):
			o["shot"] = p
		elif p.begins_with("skip="):
			o["skip"] = float(p.trim_prefix("skip="))
		elif p == "nopiglets":
			o["piglets"] = false
	return o


func setup(m: Node, opts: String) -> void:
	main = m
	var o := parse(opts)
	skip = o["skip"]
	shot_name = o["shot"]
	shot = (SHOTS[shot_name] as Dictionary).duplicate(true)
	var ovr: Variant = JSON.parse_string(OS.get_environment("BOAR_OVR")) if OS.has_environment("BOAR_OVR") else null
	if ovr is Dictionary:
		shot.merge(ovr, true)
	ground = main.map.ground_height(PKIN.x, PKIN.y)
	boar = Boar.build(Boar.Wings.FEATHERS)
	add_child(boar["root"])
	_rim(boar["root"], 1.0)
	if o["piglets"]:
		for i in 2:
			var p := Boar.build(Boar.Wings.FEATHERS, true)
			add_child(p["root"])
			piglets.append(p)
	_fly(0.0)


## A cool rim from behind-above and a warm fill from the front that ride with the boar, so it pops
## from the city at dusk (Fable: rim #9fc4ff).
func _rim(n: Node3D, k: float) -> void:
	var rim := OmniLight3D.new()
	rim.light_color = Color("#9fc4ff")
	rim.light_energy = 1.6 * k
	rim.omni_range = 2.2
	rim.position = Vector3(0.0, 1.5, -0.9)
	n.add_child(rim)
	var fill := OmniLight3D.new()
	fill.light_color = Color(1.0, 0.88, 0.74)
	fill.light_energy = 0.5 * k
	fill.omni_range = 2.4
	fill.position = Vector3(0.0, 0.9, 1.6)
	n.add_child(fill)


func _t() -> float:
	return maxf(0.0, age - skip)


func _v(a: Array) -> Vector3:
	return Vector3(a[0], ground + float(a[1]), a[2])


## Where the boar is at shot time t, and which way it flies.
func _path(t: float) -> Array:
	var len: float = shot["len"]
	var f := clampf(t / len, 0.0, 1.2)
	if shot.has("r"):
		var a := deg_to_rad(lerpf(float(shot["a0"]), float(shot["a1"]), f))
		var r: float = shot["r"]
		var p := Vector3(PKIN.x + cos(a) * r, ground + float(shot["h"]) + 1.5 * sin(t * 1.4), PKIN.y + sin(a) * r)
		var d := Vector3(-sin(a), 0.0, cos(a)) * signf(float(shot["a1"]) - float(shot["a0"]))
		return [p, d]
	var p0 := _v(shot["from"])
	var p1 := _v(shot["to"])
	if shot_name == "selfie":
		f = minf(f, float(shot["bonk"]) / len)  # the camera stops at the bonk; so does the cruise
	var p := p0.lerp(p1, f)
	if shot_name == "selfie" and t > float(shot["bonk"]):
		# The bonk: it speeds up straight at the lens.
		var u := t - float(shot["bonk"])
		# It stops with its nose at the lens (4 m ahead, the nose ~2 m in front of its middle).
		p += (p1 - p0).normalized() * minf(14.0 * u * u, 1.0)
	return [p, (p1 - p0).normalized()]


func _fly(t: float) -> void:
	var pd := _path(t)
	_pos = pd[0]
	var d: Vector3 = pd[1]
	_fwd = Vector3(d.x, 0.0, d.z).normalized()
	_side = _fwd.cross(Vector3.UP).normalized()
	var b := Basis.looking_at(-d, Vector3.UP)  # local +z along the flight, nose up or down with it
	b = Basis(_fwd, 0.08 * sin(t * 1.7)) * b
	(boar["root"] as Node3D).global_transform = Transform3D(b.scaled(Vector3.ONE * SCALE), _pos)
	Boar.pose_fly(boar, t)
	# The piglets trail in a V, behind and below, beating faster.
	for i in piglets.size():
		var s := -1.0 if i == 0 else 1.0
		var off := -_fwd * (3.0 + 0.3 * sin(t * 2.0 + s)) + _side * (1.4 * s) + Vector3.UP * (0.1 + 0.25 * sin(t * 3.1 + s))
		(piglets[i]["root"] as Node3D).global_transform = Transform3D(b.scaled(Vector3.ONE * SCALE * 0.42), _pos + off)
		Boar.pose_fly(piglets[i], t + 0.13 * float(i + 1), 4.2)


func _process(dt: float) -> void:
	age += dt
	_fly(_t())


## main.gd calls this in place of the free camera. Returns the look point (the streaming focus).
func place_camera(cam: Camera3D) -> Vector3:
	var t := _t()
	var f := smoothstep(0.0, 1.0, clampf(t / float(shot["len"]), 0.0, 1.0))
	var eye: Vector3
	var look: Vector3
	if shot.has("eye"):
		# A fixed high camera, drifting a little; the family crosses close in front of it.
		eye = _v(shot["eye"]) + Vector3(2.0, 0.6, -1.0) * f
		look = _v(shot["target"])
	else:
		var c0: Array = shot["cam0"]
		var c1: Array = shot["cam1"]
		var c := Vector3(lerpf(c0[0], c1[0], f), lerpf(c0[1], c1[1], f), lerpf(c0[2], c1[2], f))
		eye = _pos + _fwd * c.x + _side * c.y + Vector3.UP * c.z
		var lk: Array = shot["look"]
		look = _pos + _fwd * float(lk[0]) + Vector3.UP * float(lk[1])
		if shot.has("blend"):
			look = look.lerp(Vector3(PKIN.x, look.y, PKIN.y), float(shot["blend"]))
		if shot_name == "selfie":
			if t <= float(shot["bonk"]):
				_cam_hold = eye
			else:
				eye = _cam_hold  # the camera stops; the boar keeps coming
				look = _pos + Vector3.UP * 0.9
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = lerpf(float(shot["fov0"]), float(shot["fov1"]), f)
	cam.near = 0.05
	cam.far = 4000.0
	cam.global_transform = Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)
	return look
