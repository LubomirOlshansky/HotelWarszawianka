extends MultiMeshInstance3D
## Tyre marks: dark quads stamped under the rear wheels while the car slides or
## brakes hard, kept in a ring buffer so old marks give way to new ones.
## Two optional settings (Bokiem na Narodowym, the grey box: critique-drift.md section 4 and change 12);
## their defaults keep the city's marks as they were: `max_marks` (the ring's size; the stadium keeps
## 8,192, about 2,870 m of trail, the evening's runs), `along_velocity` (each mark lies along the wheel's
## path, not the body, so a drift's arcs read; the marks then abut, one every quad length, 0.70 m).

const MAX_MARKS := 1600
## Metres between two marks of one wheel: the city's, and along the path (the quad's length).
const STEP := 0.45
const STEP_ALONG := 0.70

var car: CharacterBody3D
var ground_height: Callable
## The ring's size; set before the node enters the tree.
var max_marks := MAX_MARKS
## Marks along the velocity (the wheel's path) instead of the car's heading.
var along_velocity := false
var _next := 0
var _last: Array[Vector3] = [Vector3.INF, Vector3.INF]


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(-0.14, 0, -0.35), Vector3(0.14, 0, -0.35), Vector3(0.14, 0, 0.35), Vector3(-0.14, 0, 0.35)]
	# Clockwise seen from above (Godot's front faces); UV.x is the ground shader's depth bias.
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(Color("#2f3135"))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.45, 7.0))
		st.add_vertex(corners[k])
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = st.commit()
	multimesh.instance_count = max_marks
	multimesh.visible_instance_count = 0


func _process(_dt: float) -> void:
	var sliding: bool = car.slip > 3.0 or (car.brakes_on and car.forward_speed > 8.0)
	if not sliding:
		_last = [Vector3.INF, Vector3.INF]
		return
	var heading := Basis(Vector3.UP, car.rotation.y)
	var gap := STEP
	if along_velocity and Vector2(car.vel.x, car.vel.z).length() > 0.5:
		heading = Basis(Vector3.UP, atan2(-car.vel.x, -car.vel.z))
		gap = STEP_ALONG
	for w in 2:
		var p: Vector3 = car.global_transform * Vector3(-0.78 if w == 0 else 0.78, 0.0, 1.3)
		if _last[w] != Vector3.INF and p.distance_to(_last[w]) < gap:
			continue
		# Along the path the marks are laid exactly a quad apart from the last one, so they abut
		# whatever the frame's distance (the city's keep the wheel's own point).
		if along_velocity and _last[w] != Vector3.INF and p.distance_to(_last[w]) < gap * 2.0:
			p = _last[w] + (p - _last[w]).normalized() * gap
		p.y = ground_height.call(p.x, p.z) + 0.02
		multimesh.set_instance_transform(_next, Transform3D(heading, p))
		_next = (_next + 1) % max_marks
		multimesh.visible_instance_count = mini(multimesh.visible_instance_count + 1, max_marks)
		_last[w] = p
