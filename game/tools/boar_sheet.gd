extends SceneTree
## The boar alone from six sides on a neutral floor, one PNG each, for a model check (F's flying-boar
## Reel, 2026-11-26). Needs a renderer (xvfb), not --headless:
##   godot --path game --resolution 640x640 --script res://tools/boar_sheet.gd -- --out=DIR [--wings=feathers|none] [--fly]

var out := "user://boar_sheet"
var wings := Boar.Wings.FEATHERS
var fly := false
var rig: Dictionary
var cam: Camera3D
var frame := 0
var views := [["front3q", 35.0, 12.0], ["side", 90.0, 6.0], ["back3q", 150.0, 18.0], ["front", 0.0, 4.0],
	["top", 60.0, 62.0], ["behind_high", 180.0, 28.0]]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a == "--wings=none":
			wings = Boar.Wings.NONE
		elif a == "--wings=feathers":
			wings = Boar.Wings.FEATHERS
		elif a == "--fly":
			fly = true
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#9fb6c9")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#b8c4d0")
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	world.add_child(sun)
	sun.look_at_from_position(Vector3(3, 5, 4), Vector3.ZERO, Vector3.UP)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#8d8a82")
	floor.material_override = fm
	world.add_child(floor)
	rig = Boar.build(wings)
	world.add_child(rig["root"])
	if fly:
		(rig["root"] as Node3D).position.y = 0.6
		Boar.pose_fly(rig, 0.07)
	else:
		Boar.pose_trot(rig, 0.0, 0.0)
	cam = Camera3D.new()
	cam.fov = 32.0
	world.add_child(cam)
	_place(0)


func _place(i: int) -> void:
	var v: Array = views[i]
	var yaw := deg_to_rad(float(v[1]))
	var pitch := deg_to_rad(float(v[2]))
	var d := 4.6
	var look := Vector3(0, 0.75 if fly else 0.55, 0)
	var eye := look + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * d
	cam.look_at_from_position(eye, look, Vector3.UP)


func _process(_dt: float) -> bool:
	frame += 1
	# Each view gets 4 frames to settle; the last one is saved.
	var i := frame / 4
	if frame % 4 == 3:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/%02d_%s.png" % [out, i, views[i][0]])
		if i + 1 >= views.size():
			print("boar_sheet: OK")
			return true
		_place(i + 1)
	return false
