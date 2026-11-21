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
const SHADER := "res://shaders/jarmark_rides.gdshader"
## The rides, as the shader numbers them.
const TOWER := 0
const CAROUSEL := 1
const HORSE := 2
const TEACUPS := 3
const TREE_RIDE := 4

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
	var batches: Array = [[TOWER, Kit.JM_TOWER, func() -> void: kit._jm_tower_spin(Kit.JM_TOWER)],
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
	mesh_instance.material_override = mat
	part(mesh_instance)
	count = batches.size()
