extends "res://scripts/place.gd"
## The big LED screen on Arkadia's sign tower, over the plaza entrance (F's night photos,
## 2026-11-21: a wide screen on the tower's base, the shops' signs above it): it plays the game's
## own promo, AROUND WARSAW over a synthwave sunset, the same scene as Złote Tarasy's corner screen
## (tarasy_screen.gd, shaders/led_screen.gdshader with `only_scene` 1), scaled to this smaller
## screen. One flat quad, one material, one draw call; skyline.gd's Arkadia tower builds the dark
## box it hangs on. Built at runtime on both city paths, like tarasy_screen.gd.

const TarasyScreen := preload("res://scripts/tarasy_screen.gd")
const Pixel := preload("res://scripts/pixel_font.gd")

## The screen's middle on the tower's plaza (south) face, its width, and how far it stands off
## the tower's centre (the box in skyline.gd's _arkadia_tower, ARKADIA_TOWER + (1.2, 6.2)).
const TOWER := Vector2(-2779.0, -2466.0)
const CENTRE := Vector2(1.2, 6.85)  # off TOWER: the box's front (6.8) plus a few centimetres
const WIDTH := 13.0
const BOTTOM := 4.8         # metres above the ground: over the entrance's doors
const HEIGHT := 7.8
const MARGIN := 1.2         # the mesh below the box, for what hangs out of it

var mesh_instance: MeshInstance3D


func build() -> void:
	var c := TOWER + CENTRE
	var ground: float = map.ground_height(c.x, c.y) if map != null else 0.0
	var y0 := ground + BOTTOM - MARGIN
	var p0 := c - Vector2(WIDTH * 0.5, 0.0)
	var p1 := c + Vector2(WIDTH * 0.5, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v := [
		[Vector3(p0.x, y0, p0.y), Vector2(0.0, -MARGIN)],
		[Vector3(p1.x, y0, p1.y), Vector2(WIDTH, -MARGIN)],
		[Vector3(p1.x, y0 + MARGIN + HEIGHT, p1.y), Vector2(WIDTH, HEIGHT)],
		[Vector3(p0.x, y0 + MARGIN + HEIGHT, p0.y), Vector2(0.0, HEIGHT)]]
	for k in [0, 2, 1, 0, 3, 2]:
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(v[k][1])
		st.add_vertex(v[k][0])
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ArkadiaScreen"
	mesh_instance.mesh = st.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.custom_aabb = AABB(Vector3(p0.x - 1.0, y0, c.y - 1.0), Vector3(WIDTH + 2.0, MARGIN + HEIGHT, 2.0))
	var tex := TarasyScreen.words_texture()
	var mat := ShaderMaterial.new()
	mat.shader = load(TarasyScreen.SHADER)
	mat.set_shader_parameter("size", Vector2(WIDTH, HEIGHT))
	mat.set_shader_parameter("margin", MARGIN)
	mat.set_shader_parameter("hero", WIDTH * 0.5)
	mat.set_shader_parameter("aside", WIDTH * 0.82)  # the Palace on the skyline, right of the sun
	mat.set_shader_parameter("depth", 2.2)
	mat.set_shader_parameter("bezel", 0.4)
	mat.set_shader_parameter("only_scene", 1)
	# The words fill most of the screen's width (Tarasy's are 0.42 m a texel on a 30 m screen).
	var wide := 0
	for l: String in ["AROUND", "WARSAW"]:
		wide = maxi(wide, Pixel.width(l))
	mat.set_shader_parameter("words_mpt", minf(0.42, WIDTH * 0.62 / float(wide)))
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mat.set_shader_parameter("line_px", float(Pixel.LINE))
	mesh_instance.material_override = mat
	part(mesh_instance)
	print("arkadia_screen: %.1f m x %.1f m at y %.1f, middle (%.1f, %.1f)" % [WIDTH, HEIGHT, y0 + MARGIN, c.x, c.y])
