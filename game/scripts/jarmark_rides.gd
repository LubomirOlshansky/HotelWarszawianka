extends "res://scripts/place.gd"
## The Jarmark Warszawski rides turning (F, 2026-11-20: "make them spin", for the trailer): the
## 38 m tower carousel's carrier going round and up and down its mast, the Venetian carousel with
## its horses bobbing, the teacups and the Christmas-tree carousel, with riders on all four. The
## bases, the mast and the stands are static (landmarks/jarmark.gd); this node adds what moves, on
## both city paths (it isn't in the sector scenes), like spire_motion.gd.
## One mesh, one material, one draw call, no per-frame script work: the parts are built by the same
## kit as the market (jarmark.gd `_jm_*_spin`) and every vertex carries its ride's axis (UV, world
## x and z) and its ride (UV2.y; its fraction a horse's phase), so shaders/jarmark_rides.gdshader
## turns each part about its own axis from TIME.

const Kit := preload("res://scripts/landmarks/jarmark.gd")
## The real market's object kit: with --promo-dress=jarmark its rides turn here instead of the old ones
## (jarmark_promo.gd builds their still parts and carves the old ones out of the city's sectors).
const JK := preload("res://scripts/landmarks/jarmark_kit.gd")
const Promo := preload("res://scripts/jarmark_promo.gd")
const SHADER := "res://shaders/jarmark_rides.gdshader"
## The rides, as the shader numbers them.
const TOWER := 0
const CAROUSEL := 1
const HORSE := 2
const TEACUPS := 3
const TREE_RIDE := 4
## The promo kit's tree carousel (1 rev in 50 s) and the kurant's crown (1 rev in 15 s).
const KIT_TREE := 5
const KURANT := 6
## The promo's M_LAMP gain (the shader's default is the city's 2.4): bulbs and lines, not blobs.
const PROMO_LAMP_GAIN := 1.35

var mesh_instance: MeshInstance3D


func build() -> void:
	var kit := Kit.new()
	kit.map = map
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	var promo := (ctx.get("promo_dress", PackedStringArray()) as PackedStringArray).has("jarmark")
	var batches: Array = []
	if promo:
		# The kit's rides (jarmark_kit.gd), on the grounds jarmark_promo.gd builds their still parts on.
		var yaw := Promo.KIT_YAW
		var w := func(at: Vector2) -> Vector2: return Kit._jm_world(at.x, at.y)
		# --promo-flyer (F's phone video, 2026-11-22): the chairs flown out as the real ride at full speed.
		var flyer := OS.get_cmdline_user_args().has("--promo-flyer")
		batches = [[TOWER, Kit.JM_TOWER, func() -> void: JK.tower_spin(kit, w.call(Kit.JM_TOWER), yaw, Promo.kit_ground(map, Kit.JM_TOWER, "tower"), true, JK.TOWER_TOP, flyer)],
				[CAROUSEL, Kit.JM_CAROUSEL, func() -> void: JK.venetian_spin(kit, w.call(Kit.JM_CAROUSEL), -1, yaw, Promo.kit_ground(map, Kit.JM_CAROUSEL, "carousel"))],
				[TEACUPS, Kit.JM_TEACUPS, func() -> void: JK.teacups_spin(kit, w.call(Kit.JM_TEACUPS), yaw, Promo.kit_ground(map, Kit.JM_TEACUPS, "teacups"))],
				[KIT_TREE, Kit.JM_TREE, func() -> void: JK.tree_ride_spin(kit, w.call(Kit.JM_TREE), yaw, Promo.kit_ground(map, Kit.JM_TREE, "tree"))],
				[KURANT, Kit.JM_KURANT, func() -> void: JK.kurant_spin(kit, w.call(Kit.JM_KURANT), yaw, Promo.kit_ground(map, Kit.JM_KURANT, "kurant"))]]
		for k in 12:
			batches.append([HORSE + float(k) / 12.0, Kit.JM_CAROUSEL,
					func() -> void: JK.venetian_spin(kit, w.call(Kit.JM_CAROUSEL), k, yaw, Promo.kit_ground(map, Kit.JM_CAROUSEL, "carousel"))])
	else:
		batches = [[TOWER, Kit.JM_TOWER, func() -> void: kit._jm_tower_spin(Kit.JM_TOWER)],
				[CAROUSEL, Kit.JM_CAROUSEL, func() -> void: kit._jm_carousel_spin(Kit.JM_CAROUSEL, -1)],
				[TEACUPS, Kit.JM_TEACUPS, func() -> void: kit._jm_teacups_spin(Kit.JM_TEACUPS)],
				[TREE_RIDE, Kit.JM_TREE_RIDE, func() -> void: kit._jm_tree_ride_spin(Kit.JM_TREE_RIDE)]]
		for k in 12:
			batches.append([HORSE + float(k) / 12.0, Kit.JM_CAROUSEL, func() -> void: kit._jm_carousel_spin(Kit.JM_CAROUSEL, k)])
	for b: Array in batches:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		kit.st = st
		(b[2] as Callable).call()
		var arr := st.commit_to_arrays()
		var axis := Kit._jm_world((b[1] as Vector2).x, (b[1] as Vector2).y)
		var ride := float(b[0])
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var u2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
		verts.append_array(vs)
		norms.append_array(arr[Mesh.ARRAY_NORMAL])
		cols.append_array(arr[Mesh.ARRAY_COLOR])
		var reach := 0.0
		for i in vs.size():
			uvs.append(axis)
			uv2s.append(Vector2(u2[i].x, ride))
			reach = maxf(reach, Vector2(vs[i].x, vs[i].z).distance_to(axis))
			lo.y = minf(lo.y, vs[i].y)
			hi.y = maxf(hi.y, vs[i].y)
		lo = Vector3(minf(lo.x, axis.x - reach), lo.y, minf(lo.z, axis.y - reach))
		hi = Vector3(maxf(hi.x, axis.x + reach), hi.y + 0.5, maxf(hi.z, axis.y + reach))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "JarmarkRides"
	mesh_instance.mesh = mesh
	# The carrier comes down TOWER_DROP from where it is built.
	lo.y -= Kit.TOWER_DROP
	mesh_instance.custom_aabb = AABB(lo, hi - lo)
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	if promo:
		mat.set_shader_parameter("lamp_gain", PROMO_LAMP_GAIN)
		mat.set_shader_parameter("zoom_dim", 0.35)
		for a: String in OS.get_cmdline_user_args():
			if a.begins_with("--promo-ride-t="):
				mat.set_shader_parameter("tower_t0", float(a.trim_prefix("--promo-ride-t=")))
	mesh_instance.material_override = mat
	part(mesh_instance)
	count = batches.size()
