extends Node3D
## The 3D screen at Złote Tarasy, moved and squared off from F's photos (2026-11-11: "this screen in
## the game is a curve, maybe it has an L shape on the edge of the building, maybe you put it in the
## wrong place"): the big LED screen wraps Skylight's south-east corner over the street entrance, an
## L of two flat faces, a wide one facing the station and the crossing (south-east) and a narrower
## return facing Emilii Plater (east-north-east), from about 11.5 to 25 m up (F's photos, refs/skylight
## 06: the "WOW" panels' place). Its anamorphic loop floats out of the frame: a tabby cat leaning
## out (F's photo), the game's own promo (AROUND WARSAW over a skyline), and the NOSE. agency's promo
## (F asked for it by name). No real brand is on it.
## Two quads along the corner (flat, each with its own normal: the shader's parallax keeps each face
## a window of its own, which is the corner trick of the real screens): one mesh, one material, one
## draw call. All the looks are in shaders/led_screen.gdshader, which follows a ray into a little
## box so the walls and layers parallax with the viewer. Built at runtime on both city paths (it
## isn't in the sector scenes), like skwer_zlota.gd.

const Pixel := preload("res://scripts/pixel_font.gd")

## Skylight's outline at its south-east corner (centrum.json "Skylight"): the south-east end of the
## curved south face, the corner, and a point on the straight east end. Walked so the screen's right
## is the viewer's right (from the south-east).
const WALL := [Vector2(-1367.7, 433.4), Vector2(-1354.6, 423.5), Vector2(-1357.65, 415.03)]
## Each face's offset off the wall: the wide face is the chord of a curve that bulges 1 m past it,
## and both clear Skylight's glazed belt (stepped out ~0.4 m at 20-33 m).
const OFFSETS := [1.6, 0.8]
const BOTTOM := 11.5        # metres above the ground at the corner: over the lobby's 5 m canopy
const HEIGHT := 13.5        # the box's height (to 25 m)
const MARGIN := 2.6         # the mesh below the box, for what hangs out of it
const SHADER := "res://shaders/led_screen.gdshader"
## The words the screen shows, one line each: the game's title (two lines), the agency's mark.
const LINES := ["AROUND", "WARSAW", "NOSE."]

var map: Node3D
var length := 0.0
var corner := 0.0           # metres along the screen to the corner (the wide face's length)
var mesh_instance: MeshInstance3D


## The corner's three points pushed out (the faces' offset lines met at the corner) and each face's
## outward normal.
static func outline() -> Array:
	var a: Vector2 = WALL[0]
	var c: Vector2 = WALL[1]
	var b: Vector2 = WALL[2]
	var da := (c - a).normalized()
	var db := (b - c).normalized()
	var na := Vector2(-da.y, da.x)
	var nb := Vector2(-db.y, db.x)
	var a2: Vector2 = a + na * float(OFFSETS[0])
	var b2: Vector2 = b + nb * float(OFFSETS[1])
	# The corner: where the two offset lines cross.
	var c2: Variant = Geometry2D.line_intersects_line(a2, da, b2, -db)
	var corner: Vector2 = c2 if c2 != null else c + (na + nb).normalized() * float(OFFSETS[0])
	return [[a2, corner, b2], [na, nb]]


func build() -> void:
	var o := outline()
	var pts: Array = o[0]
	var norms: Array = o[1]
	var ground: float = map.ground_height(WALL[1].x, WALL[1].y) if map != null else 0.0
	var y0 := ground + BOTTOM - MARGIN
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := 0.0
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var s1 := s + p0.distance_to(p1)
		var n: Vector2 = norms[i]
		var v := [
			[Vector3(p0.x, y0, p0.y), Vector2(s, -MARGIN)],
			[Vector3(p1.x, y0, p1.y), Vector2(s1, -MARGIN)],
			[Vector3(p1.x, y0 + MARGIN + HEIGHT, p1.y), Vector2(s1, HEIGHT)],
			[Vector3(p0.x, y0 + MARGIN + HEIGHT, p0.y), Vector2(s, HEIGHT)]]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3(n.x, 0, n.y))
			st.set_uv(v[k][1])
			st.add_vertex(v[k][0])
		if i == 0:
			corner = s1
		s = s1
	length = s
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TarasyScreen"
	mesh_instance.mesh = st.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.custom_aabb = AABB(Vector3(-1372, y0, 410), Vector3(20, MARGIN + HEIGHT, 28))
	var tex := _words_texture()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("size", Vector2(length, HEIGHT))
	mat.set_shader_parameter("margin", MARGIN)
	mat.set_shader_parameter("corner", corner)
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mat.set_shader_parameter("line_px", float(Pixel.LINE))
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	print("tarasy_screen: %.1f m x %.1f m (corner at %.1f m) at y %.1f, corner (%.1f, %.1f)" % [length, HEIGHT, corner, y0 + MARGIN,
			(pts[1] as Vector2).x, (pts[1] as Vector2).y])


## The words as one image (red channel = lit): a line of the font a row of LINE texels, each line
## centred, one pixel of the font a texel; a texel of padding at the top.
func _words_texture() -> ImageTexture:
	var wide := 0
	for l: String in LINES:
		wide = maxi(wide, Pixel.width(l))
	var img := Image.create_empty(wide + 4, LINES.size() * Pixel.LINE + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for i in LINES.size():
		var l: String = LINES[i]
		Pixel.draw(img, l, (img.get_width() - Pixel.width(l)) / 2, 1 + i * Pixel.LINE, Color.WHITE)
	return ImageTexture.create_from_image(img)
