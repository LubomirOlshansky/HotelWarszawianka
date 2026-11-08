extends Node3D
## The 3D screen at Złote Tarasy (F, 2026-11-05, from his photos): the big LED screen that hangs on a
## box standing out in front of the Skylight tower over the glass entrance, an L in plan (the south
## face and a curved return), with anamorphic content that floats out of its frame (glowing
## flowers, a cat leaning out, a title). Ours is an original loop under a parody title (SCENA
## WARSZAWA); no real brand is on it.
## A strip of mesh along the block's mapped plate (landmarks.gd raises it to BLOCK_TOP in
## graphite): one mesh, one material, one draw call. All the looks are in shaders/led_screen.gdshader,
## which follows a ray into a little box so the walls and layers parallax with the viewer. Built at
## runtime on both city paths (it isn't in the sector scenes), like skwer_zlota.gd.

const Pixel := preload("res://scripts/pixel_font.gd")

## The block's south face and its curved west return (the plate over the glass entrance, 17 m up,
## which landmarks.gd raises to BLOCK_TOP), walked west to east so the screen's right is the viewer's
## right (world x east, z south): an L in plan, as in F's photos.
const WALL := [Vector2(-1409.0, 437.0), Vector2(-1403.0, 442.0), Vector2(-1396.0, 445.0),
		Vector2(-1389.0, 447.0), Vector2(-1382.0, 449.0), Vector2(-1375.0, 449.0), Vector2(-1368.0, 449.0)]
const OFFSET := 0.3         # off the block's wall
const BOTTOM := 17.3        # metres above the ground at the block: over the 17 m entrance roof
const HEIGHT := 20.2        # the box's height
const BLOCK_TOP := 38.0     # the block's roof, a little over the screen
const MARGIN := 2.6         # the mesh below the box, for what hangs out of it
const SHADER := "res://shaders/led_screen.gdshader"
const TITLE := ["SCENA", "WARSZAWA"]

var map: Node3D
var length := 0.0
var mesh_instance: MeshInstance3D


## The wall's total length, and the outward offset polyline the strip follows.
static func outline() -> Array:
	var pts: Array = []
	var norms: Array = []
	for i in WALL.size():
		var a: Vector2 = WALL[maxi(i - 1, 0)]
		var b: Vector2 = WALL[mini(i + 1, WALL.size() - 1)]
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		norms.append(n)
		pts.append(WALL[i] + n * OFFSET)
	return [pts, norms]


func build() -> void:
	var o := outline()
	var pts: Array = o[0]
	var norms: Array = o[1]
	var ground: float = map.ground_height(WALL[3].x, WALL[3].y) if map != null else 0.0
	var y0 := ground + BOTTOM - MARGIN
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := 0.0
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var s1 := s + p0.distance_to(p1)
		var n0: Vector2 = norms[i]
		var n1: Vector2 = norms[i + 1]
		var v := [
			[Vector3(p0.x, y0, p0.y), Vector3(n0.x, 0, n0.y), Vector2(s, -MARGIN)],
			[Vector3(p1.x, y0, p1.y), Vector3(n1.x, 0, n1.y), Vector2(s1, -MARGIN)],
			[Vector3(p1.x, y0 + MARGIN + HEIGHT, p1.y), Vector3(n1.x, 0, n1.y), Vector2(s1, HEIGHT)],
			[Vector3(p0.x, y0 + MARGIN + HEIGHT, p0.y), Vector3(n0.x, 0, n0.y), Vector2(s, HEIGHT)]]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(v[k][1])
			st.set_uv(v[k][2])
			st.add_vertex(v[k][0])
		s = s1
	length = s
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TarasyScreen"
	mesh_instance.mesh = st.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.custom_aabb = AABB(Vector3(-1415, y0, 432), Vector3(52, MARGIN + HEIGHT, 25))
	var tex := _title_texture()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("size", Vector2(length, HEIGHT))
	mat.set_shader_parameter("margin", MARGIN)
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	print("tarasy_screen: %.1f m x %.1f m at y %.1f" % [length, HEIGHT, y0 + MARGIN])


## The title as one image (red channel = lit): the two lines, one pixel of the font a texel.
func _title_texture() -> ImageTexture:
	var wide := 0
	for l: String in TITLE:
		wide = maxi(wide, Pixel.width(l))
	var img := Image.create_empty(wide + 4, TITLE.size() * Pixel.LINE + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for i in TITLE.size():
		var l: String = TITLE[i]
		Pixel.draw(img, l, (img.get_width() - Pixel.width(l)) / 2, 1 + i * Pixel.LINE, Color.WHITE)
	return ImageTexture.create_from_image(img)
