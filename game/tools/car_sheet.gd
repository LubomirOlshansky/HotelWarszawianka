extends SceneTree
## The car turntable: every shop car (models.gd PLAYER_BODIES) from five sides on one PNG sheet,
## alone on a grey floor, so a builder and F can check the garage's cars without a city run.
##
##   godot --path game --resolution 640x360 --script res://tools/car_sheet.gd -- [--out=PATH]
##       [--paint=#d8432f] [--stripe=#f4efe4] [--cars=hatch,tt,...] [--wing] [--mix]
## --mix: each car in a different paint of the garage's (MIX), to see them as a line-up.
##
## Rows: one car each (upgrades.gd ORDER's cars); columns: front three-quarter, side, rear
## three-quarter, the game's high view from behind, straight down. Needs a renderer (xvfb-run on
## Linux), never --headless. Writes ../shots/car_sheet.png by default and prints its path.

const Models := preload("res://scripts/models.gd")
const Upgrades := preload("res://scripts/upgrades.gd")

const TILE := Vector2i(420, 280)
## --mix's paints and stripes (garage.gd PAINTS' colours).
const MIX := {"hatch": ["#d8432f", "#f4efe4"], "tt": ["#1f2024", "#c9ccd1"], "bolonez": ["#5aa83a", "#f4efe4"],
		"paszat": ["#2f72c8", "#f4efe4"], "mjata": ["#c4161c", "#f4efe4"], "kadilak": ["#8ea6c8", "#c9ccd1"],
		"gr86": ["#eeeeea", "#1c1d21"], "porsza": ["#f2f0ea", "#1c1d21"], "mruczelago": ["#e3a2c8", "#f4efe4"]}
## [yaw (deg, 0 = from the front), pitch (deg, down), distance (m)] of each column.
const VIEWS := [[35.0, 14.0, 7.2], [90.0, 6.0, 7.4], [215.0, 18.0, 7.2], [165.0, 52.0, 9.5], [180.0, 89.0, 8.5]]


func _init() -> void:
	var out := "res://../shots/car_sheet.png"
	var paint := Color("#d8432f")
	var stripe := Color("#f4efe4")
	var wing := false
	var mix := false
	var cars: Array = []
	for c: Dictionary in Upgrades.CARS:
		cars.append(str(c["id"]))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--paint="):
			paint = Color(a.substr(8))
		elif a.begins_with("--stripe="):
			stripe = Color(a.substr(9))
		elif a.begins_with("--cars="):
			cars = Array(a.substr(7).split(","))
		elif a == "--wing":
			wing = true
		elif a == "--mix":
			mix = true
	_run.call_deferred(cars, paint, stripe, wing, out, mix)


func _run(cars: Array, paint: Color, stripe: Color, wing: bool, out: String, mix: bool) -> void:
	var vp := SubViewport.new()
	vp.size = TILE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#9aa3ad")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#c9d2dc")
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	vp.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mi.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#4a5057")
	fm.roughness = 0.9
	floor_mi.material_override = fm
	vp.add_child(floor_mi)
	var cam := Camera3D.new()
	cam.fov = 34.0
	vp.add_child(cam)
	var body_mat := StandardMaterial3D.new()
	body_mat.vertex_color_use_as_albedo = true
	body_mat.vertex_color_is_srgb = true
	body_mat.roughness = 0.35
	body_mat.metallic_specular = 0.7
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color("#fff6d8")
	head_mat.emission_enabled = true
	head_mat.emission = Color("#fff6d8")
	var tail_mat := StandardMaterial3D.new()
	tail_mat.albedo_color = Color("#d8261c")
	tail_mat.emission_enabled = true
	tail_mat.emission = Color("#b01810")
	var sheet := Image.create(TILE.x * VIEWS.size(), TILE.y * cars.size(), false, Image.FORMAT_RGBA8)
	for row in cars.size():
		var id := str(cars[row])
		# A body kind ("player_...") draws that body directly: candidate cars before they join the shop.
		var kind := id if id.begins_with("player_") else str(Models.PLAYER_BODIES.get(id, "player"))
		var pc := paint
		var sc := stripe
		if mix and MIX.has(id):
			pc = Color(str(MIX[id][0]))
			sc = Color(str(MIX[id][1]))
		var meshes := Models.player_meshes(Models.fin(pc, Models.HERO, 1.0), Models.fin(sc, Models.HERO, 0.3), kind, wing)
		var holder := Node3D.new()
		vp.add_child(holder)
		var mats: Array[Material] = [body_mat, head_mat, tail_mat]
		for i in 3:
			var mi := MeshInstance3D.new()
			mi.mesh = meshes[i]
			mi.material_override = mats[i]
			holder.add_child(mi)
		if kind == "player_tt":
			var sp := MeshInstance3D.new()
			sp.mesh = Models.tt_spoiler(Models.fin(pc, Models.HERO, 1.0))
			sp.material_override = body_mat
			sp.position.y = Models.SPOILER_LIFT
			holder.add_child(sp)
		for col in VIEWS.size():
			var v: Array = VIEWS[col]
			var yaw := deg_to_rad(float(v[0]))
			var pitch := deg_to_rad(float(v[1]))
			var d := float(v[2])
			# Yaw 0 looks at the nose (the car faces -Z): the camera stands at -Z.
			var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
			var target := Vector3(0.0, 0.6, 0.0)
			cam.global_position = target + dir * d
			if float(v[1]) > 85.0:
				cam.look_at_from_position(target + Vector3(0, d, 0.001), target, Vector3(0, 0, -1))
			else:
				cam.look_at(target, Vector3.UP)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(col * TILE.x, row * TILE.y))
		holder.queue_free()
		await process_frame
	var path := ProjectSettings.globalize_path(out) if out.begins_with("res://") else out
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	sheet.save_png(path)
	print("car_sheet: %d cars x %d views -> %s" % [cars.size(), VIEWS.size(), path])
	quit(0)
