extends Node3D
## The city objects plan, step 4 (docs/design/drivable-city-build.md item 5): `--colliders`, what
## the car sees. Every collider of the city that carries a solid class (map_builder.gd's
## `Solid_<class>` bodies on both city paths, the edge roadworks, the dressing scripts' bodies)
## gets a translucent skin in the colour of the answer its class is planned to get
## (solidity.gd `planned`, the research's verdicts in game/data/object_palette.json): hard red,
## smash yellow, push blue, ride green; the invisible pocket walls magenta. The map's edge walls
## (200 m boxes) are left out. For tools/shots.sh sets in street sweeps and for F.
##
## A test flag (main.gd; a release build reads no flags, release.gd): nothing of it is loaded
## otherwise. The streamed sectors arrive and leave as the car drives, and a prebuilt sector's
## collider pieces one a frame, so every SCAN s it skins the shapes it has not seen yet, under the
## shape itself (they go with their sector). Unshaded, no depth write, pulled PULL m towards the
## camera so a skin on a drawn wall doesn't flicker in it.

const Solidity := preload("res://scripts/solidity.gd")

const SCAN := 0.5
const PULL := 0.06
## Colour and opacity per planned answer; pockets on their own.
const TINTS := {
	"H": Color(0.95, 0.12, 0.10, 0.32),
	"S": Color(1.0, 0.85, 0.05, 0.5),
	"P": Color(0.15, 0.45, 1.0, 0.5),
	"R": Color(0.2, 0.85, 0.3, 0.45),
	"G": Color(0.7, 0.7, 0.7, 0.3),
}
const POCKET := Color(1.0, 0.1, 0.9, 0.75)
## The buildings' walls are most of the city's colliders: fainter, so the rest reads over them.
const FAINT := [&"building", &"lod2"]
const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color;
uniform float pull;
void vertex() {
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	v.xyz += normalize(-v.xyz) * pull;
	POSITION = PROJECTION_MATRIX * v;
}
void fragment() {
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
}
"""

## The shapes skinned so far (and the bodies' count, for the log line).
var skinned := 0
var _t := SCAN
var _shader: Shader
var _mats := {}


func _ready() -> void:
	_shader = Shader.new()
	_shader.code = SHADER
	print("colliders: the collider view is on (hard red, smash yellow, push blue, ride green, pockets magenta)")


func _process(delta: float) -> void:
	_t += delta
	if _t < SCAN:
		return
	_t = 0.0
	for n in get_tree().root.find_children("*", "StaticBody3D", true, false):
		if n is AnimatableBody3D or not n.has_meta(&"solid"):
			continue
		var cls := StringName(str(n.get_meta(&"solid")))
		if cls == &"edge" and str(n.name) == "Edges":
			continue
		for c in n.get_children():
			if c is CollisionShape3D and not c.has_meta(&"_skin"):
				c.set_meta(&"_skin", true)
				var skin := _skin((c as CollisionShape3D).shape, cls)
				if skin != null:
					c.add_child(skin)
					skinned += 1


## A shape's skin in its class's colour, or null for a shape it doesn't draw.
func _skin(shape: Shape3D, cls: StringName) -> MeshInstance3D:
	var mesh: Mesh
	if shape is ConcavePolygonShape3D:
		var faces := (shape as ConcavePolygonShape3D).get_faces()
		if faces.is_empty():
			return null
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = faces
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh = am
	elif shape is BoxShape3D:
		var bm := BoxMesh.new()
		bm.size = (shape as BoxShape3D).size
		mesh = bm
	else:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _material(cls)
	return mi


func _material(cls: StringName) -> ShaderMaterial:
	if _mats.has(cls):
		return _mats[cls]
	var tint: Color = POCKET if cls == &"pocket" else TINTS.get(Solidity.planned(cls), TINTS["H"])
	if cls in FAINT:
		tint.a *= 0.5
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("pull", PULL)
	m.render_priority = 1
	_mats[cls] = m
	return m
