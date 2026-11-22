extends "res://scripts/place.gd"
## The 3D screen at Złote Tarasy, moved and squared off from F's photos (2026-11-11: "this screen in
## the game is a curve, maybe it has an L shape on the edge of the building, maybe you put it in the
## wrong place"): the big LED screen wraps Skylight's south-east corner over the street entrance, an
## L of flat faces. F, 2026-11-21 (screenshots, the place drawn in red): the old wide face along the
## curved south face sat behind the grey block over the entrance and read as cut off, so the wide
## face now runs the whole straight east face on Emilii Plater, flush with the wall from the corner
## to the tower's north end, with a short return round the corner onto the curve (south-east), from
## about 11.5 to 25 m up. Its anamorphic loop floats out of the frame: a tabby cat leaning
## out (F's photo), the game's own promo (AROUND WARSAW over a skyline), and the NOSE. agency's promo
## (F asked for it by name). No real brand is on it.
## Two quads along the corner (flat, each with its own normal: the shader's parallax keeps each face
## a window of its own, which is the corner trick of the real screens): one mesh, one material, one
## draw call. All the looks are in shaders/led_screen.gdshader, which follows a ray into a little
## box so the walls and layers parallax with the viewer. Built at runtime on both city paths (it
## isn't in the sector scenes), like skwer_zlota.gd.

const Pixel := preload("res://scripts/pixel_font.gd")

## Skylight's outline at its south-east corner (centrum.json "Skylight"), walked so the screen's
## right is the viewer's right (from the south-east): three points on the curved south face (the
## return, stopping short of the grey block over the entrance, which hid the screen's old wide face
## from the street; F, 2026-11-21: "out of the visible area"), the corner, and the north end of the
## straight east face on Emilii Plater (F drew it there: the wide face runs to the end of the tower).
## F's second look (2026-11-22, "move right but cut left"): the return keeps the curve's whole
## visible stretch, from the grey block's east edge (-1367.7, 433.4) round to the corner.
const WALL := [Vector2(-1367.7, 433.4), Vector2(-1360.2, 429.0), Vector2(-1356.6, 425.7),
		Vector2(-1354.6, 423.5), Vector2(-1361.9, 403.2)]
## Which point of WALL is the tower's corner (the return ends there, the wide face begins).
const CORNER_AT := 3
## How far each WALL point is pushed off the wall: the curve's points clear its bulge between them and
## Skylight's glazed belt (stepped out ~0.4 m at 20-33 m); the straight east face less. The corner's
## entry is unused (CORNER_OFFSETS).
const OFFSETS := [1.0, 1.2, 1.2, 1.2, 0.8]
## The corner point pushes out along the two neighbouring faces' offset lines instead (their offsets).
const CORNER_OFFSETS := [1.2, 0.8]
const BOTTOM := 11.5        # metres above the ground at the corner: over the lobby's 5 m canopy
const HEIGHT := 13.5        # the box's height (to 25 m)
const MARGIN := 2.6         # the mesh below the box, for what hangs out of it
const SHADER := "res://shaders/led_screen.gdshader"
## The words the screen shows, one line each: the game's title (two lines), the agency's mark.
const LINES := ["AROUND", "WARSAW", "NOSE."]

var length := 0.0
var corner := 0.0           # metres along the screen to the corner (the return's length)
var mesh_instance: MeshInstance3D


## The corner's three points pushed out (the faces' offset lines met at the corner) and each face's
## outward normal.
static func outline() -> Array:
	var segs := WALL.size() - 1
	var dirs: Array[Vector2] = []
	var norms: Array[Vector2] = []
	for i in segs:
		var d := ((WALL[i + 1] as Vector2) - (WALL[i] as Vector2)).normalized()
		dirs.append(d)
		norms.append(Vector2(-d.y, d.x))
	var pts: Array[Vector2] = []
	for i in WALL.size():
		var w: Vector2 = WALL[i]
		if i == 0:
			pts.append(w + norms[0] * float(OFFSETS[0]))
		elif i == segs:
			pts.append(w + norms[segs - 1] * float(OFFSETS[segs]))
		elif i == CORNER_AT:
			# The corner: where the two faces' offset lines cross.
			var a2: Vector2 = w + norms[i - 1] * float(CORNER_OFFSETS[0])
			var b2: Vector2 = w + norms[i] * float(CORNER_OFFSETS[1])
			var x: Variant = Geometry2D.line_intersects_line(a2, dirs[i - 1], b2, dirs[i])
			var q: Vector2 = w + (norms[i - 1] + norms[i]).normalized() * float(CORNER_OFFSETS[0])
			if x != null:
				q = x
			pts.append(q)
		else:
			pts.append(w + (norms[i - 1] + norms[i]).normalized() * float(OFFSETS[i]))
	return [pts, norms]


func build() -> void:
	var o := outline()
	var pts: Array = o[0]
	var norms: Array = o[1]
	var at: Vector2 = pts[CORNER_AT]
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
		if i == CORNER_AT - 1:
			corner = s1
		s = s1
	length = s
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TarasyScreen"
	mesh_instance.mesh = st.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q: Vector2 in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	mesh_instance.custom_aabb = AABB(Vector3(lo.x - 1.0, y0, lo.y - 1.0), Vector3(hi.x - lo.x + 2.0, MARGIN + HEIGHT, hi.y - lo.y + 2.0))
	var tex := words_texture()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("size", Vector2(length, HEIGHT))
	mat.set_shader_parameter("margin", MARGIN)
	# The scenes centre on the wider of the two sides of the corner, the tail and the Palace on the other.
	var wide_last := length - corner > corner
	mat.set_shader_parameter("hero", corner + (length - corner) * 0.5 if wide_last else corner * 0.5)
	mat.set_shader_parameter("aside", corner * 0.5 if wide_last else corner + (length - corner) * 0.5)
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mat.set_shader_parameter("line_px", float(Pixel.LINE))
	mesh_instance.material_override = mat
	part(mesh_instance)
	print("tarasy_screen: %.1f m x %.1f m (corner at %.1f m) at y %.1f, corner (%.1f, %.1f)" % [length, HEIGHT, corner, y0 + MARGIN,
			at.x, at.y])


## The words as one image (red channel = lit): a line of the font a row of LINE texels, each line
## centred, one pixel of the font a texel; a texel of padding at the top.
static func words_texture() -> ImageTexture:
	var wide := 0
	for l: String in LINES:
		wide = maxi(wide, Pixel.width(l))
	var img := Image.create_empty(wide + 4, LINES.size() * Pixel.LINE + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for i in LINES.size():
		var l: String = LINES[i]
		Pixel.draw(img, l, (img.get_width() - Pixel.width(l)) / 2, 1 + i * Pixel.LINE, Color.WHITE)
	return ImageTexture.create_from_image(img)
