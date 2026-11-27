extends RefCounted
## Models for everything that moves: the player's hatchback, traffic, taxis, vans, the city
## bus, tram cars, pedestrians, the rivals' cars, the police and city-guard cars, and the
## parked cars the map builder places. Fronts face -Z, like the player's car. Vertex UV.x
## picks how actor.gdshader colours a part: PAINT takes the instance paint, FIXED keeps the
## vertex colour, TROUSERS uses the palette; HEAD_LAMP, TAIL_LAMP, LIT_WINDOW and LIT_SIGN
## keep their colour and glow when the city's lights are on; BLINK (loop 1: the roadwork
## lamps) glows and blinks, UV.y shifting its beat (loop 2c: the police lamps take turns);
## HERO (the look loop: the player's car, car.gd) keeps its colour and lights from within at
## night by UV.y. headlight_pools() is the light the lamps throw on the road.
##
## Loop 2c (car models; the user asked for nicer cars): vehicles are no longer boxes but
## shaped pieces in a Shape: a body lofted from its side profile (a sloped bonnet, the nose,
## the rear deck), a glasshouse narrower at the roof, glass panes with pillars between them,
## six- or eight-sided wheels in dark arches with hub caps, bumpers, number plates, lamps
## and a grille, all flat-shaded. A traffic kind (one MultiMesh in traffic.gd) is one
## family mesh whose vertices carry up to four shapes of the same parts (family(): CUSTOM0
## to CUSTOM2, read by actor.gdshader), and the instance's custom alpha picks the shape: a
## hatch, a saloon, an estate and an SUV share one draw call. A part one shape doesn't
## have shrinks to a point in that shape (Shape.hide()).

const PixelFont := preload("res://scripts/pixel_font.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const PAINT := 0.0
const FIXED := 1.0
const TROUSERS := 2.0
const HEAD_LAMP := 3.0
const TAIL_LAMP := 4.0
const LIT_WINDOW := 5.0
const LIT_SIGN := 6.0
const BLINK := 7.0
const HERO := 8.0
## Road life (2026-11-26): a traffic car's dressing, drawn only in its mode (actor.gdshader DRESS;
## traffic.gd Driver.dress): 9 the driving school's L box, 10 a wedding car's ribbons and flowers.
const DRESS_L := 9.0
const DRESS_WEDDING := 10.0
## A BLINK lamp's UV.y at the hazard beat (actor.gdshader: over 9.5, all together at 1.4 Hz).
const HAZARD_BEAT := 10.0
const HAZARD := Color("#ffa51e")
## The Polish L sign: a blue square, a white L.
const L_BLUE := Color("#1f5fbf")
## Loop 2c: added to UV.x on a family mesh's vertices (actor.gdshader then reads CUSTOM0..2).
const MORPH := 16.0

const GLASS := Color("#34404e")
const TYRE := Color("#2a2a2e")
const HEADLIGHT := Color("#fff3c4")
const TAIL := Color("#b3241f")
const TRIM := Color("#3a3b3f")
## Loop 2c: the dark of a wheel arch, the hub caps, the grille and the number plates.
const WELL := Color("#121214")
const HUB := Color("#8c8f94")
const GRILLE := Color("#26282b")
const PLATE := Color("#eceae2")
## The parked cars' glass (map_builder.gd's old mesh; foliage.gdshader repaints red parked
## cars of an old bake by it, so the parked mesh keeps exactly this colour).
const PARKED_GLASS := Color("#5b6573")

## Loop 2c: traffic.gd's kinds (CAR, TAXI, VAN, BUS: one MultiMesh each) and the shapes each
## draws: its share of that kind's cars, the box it takes up (width, height, length: the
## lane spacing and the bodies near the player) and its paints. Red and orange belong to the
## player's car and the jobs (art bible, reserved colours), saturated blue to the police: no
## paint here is any of them. Warsaw's buses keep their red and yellow.
const TRAFFIC := [
	[
		{"name": "hatch", "share": 0.36, "size": Vector3(1.74, 1.5, 3.95),
			"paint": ["#e9e9e6", "#b8bcc0", "#6f7378", "#2f4566", "#6a7487", "#cdbb9a", "#4c6650", "#8a9470", "#5d6f8a", "#f2f2ee"]},
		{"name": "saloon", "share": 0.26, "size": Vector3(1.8, 1.45, 4.6),
			"paint": ["#2b2c2f", "#b8bcc0", "#24324a", "#6f7378", "#e9e9e6", "#4a4440", "#3d4b5c"]},
		{"name": "estate", "share": 0.22, "size": Vector3(1.8, 1.55, 4.65),
			"paint": ["#b8bcc0", "#e9e9e6", "#4c6650", "#2f4566", "#cdbb9a", "#6f7378", "#5b4f63"]},
		{"name": "suv", "share": 0.16, "size": Vector3(1.88, 1.78, 4.5),
			"paint": ["#2b2c2f", "#e9e9e6", "#6f7378", "#5d6b4e", "#24324a", "#8c8f94"]},
	],
	[
		{"name": "taxi", "share": 0.5, "size": Vector3(1.78, 1.7, 4.6),
			"paint": ["#f2f2ee", "#e9e9e6", "#d6d8da"]},
		{"name": "podwozka", "share": 0.5, "size": Vector3(1.92, 2.2, 4.75),
			"paint": ["#f2f2ee", "#1c1d20", "#6f7378", "#b8bcc0", "#e9e9e6", "#24324a"]},
		# City-life satire #1 (loud_cars.gd): never a random taxi (share 0); traffic.gd makes a
		# few of its cars loud ones in this shape. Loud paints, none of them the player's red
		# and orange or the police's blue: lime, acid yellow, violet, matte black, teal, pearl,
		# pink, mint.
		{"name": "supercar", "share": 0.0, "size": Vector3(1.98, 1.2, 4.55),
			"paint": ["#a6e22e", "#e8f03a", "#7b3fd1", "#1a1a1d", "#16a39a", "#f4f1ea", "#ff5fb4", "#7ef0c4"]},
		# Crazy drivers (traffic.gd CRAZY_*, docs/design/crazy-drivers.md): the Pasatini 1.9 TDJ,
		# never a random taxi (share 0); one at most in traffic, in Janusz paints (traffic.gd
		# PASAT_PAINT; these are the same).
		{"name": "pasatini", "share": 0.0, "size": Vector3(1.8, 1.55, 4.65),
			"paint": ["#1d1e21", "#3a3d42", "#2f3d33", "#2a3340", "#8c9096"]},
	],
	[
		{"name": "panel van", "share": 0.6, "size": Vector3(2.0, 2.45, 5.2),
			"paint": ["#f2f2ee", "#e9e9e6", "#d8d2c2", "#b8bcc0", "#2f4566", "#6a7487", "#4c6650"]},
		{"name": "box van", "share": 0.4, "size": Vector3(2.1, 2.8, 5.4),
			"paint": ["#f2f2ee", "#e9e9e6", "#d8d2c2", "#b8bcc0"]},
		# Road life stage 2 (F, 2026-11-23: "евакуатори з машинами на дорогах"): the laweta, a
		# tow truck with a flat platform, empty and with a car on it (_van(VAN_TOW), VAN_TOW_LOADED;
		# crash_scenes.gd's "Odholowanie" scene loads one). Never a random van (share 0): traffic.gd
		# makes TOW_CHANCE of its vans one with its own generator. The VAN family holds four shapes.
		{"name": "tow truck", "share": 0.0, "size": Vector3(2.24, 2.3, 6.6),
			"paint": ["#f2f2ee", "#e9e9e6", "#2b2c2f", "#d8d2c2"]},
		{"name": "tow truck loaded", "share": 0.0, "size": Vector3(2.24, 2.8, 6.6),
			"paint": ["#f2f2ee", "#e9e9e6", "#2b2c2f", "#d8d2c2"]},
	],
	[
		# Shape 0 the articulated bus (buses.gd's hub ring always takes it), shape 1 the solo bus.
		{"name": "bus", "share": 0.6, "size": Vector3(2.5, 3.2, 18.0), "paint": ["#ffffff"]},
		{"name": "solo bus", "share": 0.4, "size": Vector3(2.5, 3.2, 12.0), "paint": ["#ffffff"]},
		# Road life stage 3 (F, 2026-11-23): the fire engine (straż pożarna, bus_shape(BUS_FIRE)),
		# never a random bus (share 0): road_life.gd sends one on a call (traffic.gd add_fire_engine).
		{"name": "fire engine", "share": 0.0, "size": Vector3(2.5, 3.4, 8.4), "paint": ["#ffffff"]},
	],
]
## Loop 2c: the parked cars' paints (map_builder.gd picks one by the bake's index): traffic's
## old palette, the red one already slate as in traffic (the look loop).
const PARKED_PAINT := ["#e9e9e6", "#b8bcc0", "#6f7378", "#2b2c2f", "#2f4566", "#6a7487", "#24324a", "#cdbb9a", "#4c6650", "#f2f2ee"]
## Loop 2c, for loop 3g: the police car's and the city guards' paint (police.md section 9).
const POLICE_WHITE := Color("#f2f2ee")
## The patrol car's and van's silver paint (the real radiowozy are silver, not white).
const POLICE_SILVER := Color("#c3c8ce")
const GUARD_MUSTARD := Color("#e3b33a")
## The crash scenes: the ambulance's paint and its red band and lettering.
const AMBULANCE_YELLOW := Color("#f2cf1d")
const AMBULANCE_RED := Color("#d9262c")

static var _material: ShaderMaterial
static var _glow_material: ShaderMaterial
static var _umbrella: ArrayMesh


## Loop 2c: the triangles of a model before they become a mesh, flat-shaded, with each
## triangle's colour and part code. Families need the same parts in the same order in every
## shape; a part a shape doesn't have is drawn with hide() on, so its vertices land on one
## point. `xform` moves (or scales) everything added after it is set.
class Shape:
	extends RefCounted

	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	## Per triangle: 1 if its corners were swapped to face outwards, and 1 if it has an area
	## (family() takes each triangle's winding from a shape where it has one).
	var flip := PackedByteArray()
	var solid := PackedByteArray()
	var xform := Transform3D.IDENTITY
	var _hidden := false
	var _anchor := Vector3.ZERO
	## When set, the normal every triangle takes (quad_flat: one normal for a whole quad).
	var _flat := Vector3.ZERO

	## Leaves out what follows (it shrinks to `at`) until show().
	func hide(at: Vector3) -> void:
		_hidden = true
		_anchor = xform * at

	func show() -> void:
		_hidden = false

	## Hides what follows unless `keep`.
	func keep_if(keep: bool, at: Vector3) -> void:
		if keep:
			show()
		else:
			hide(at)

	## One triangle facing `out` (roughly); `f` is [colour, uv] (Models.fin()).
	func tri(a: Vector3, b: Vector3, c: Vector3, f: Array, out: Vector3) -> void:
		a = xform * a
		b = xform * b
		c = xform * c
		out = xform.basis * out
		var cr := (b - a).cross(c - a)
		var swap := cr.dot(out) > 0.0
		if swap:
			var t := b
			b = c
			c = t
			cr = -cr
		var has_area := cr.length_squared() > 1e-12
		# Godot's front faces are clockwise: (b - a) x (c - a) points away from the viewer.
		var n := -cr.normalized() if has_area else out.normalized()
		if _flat != Vector3.ZERO:
			n = _flat
		flip.append(1 if swap else 0)
		solid.append(1 if has_area else 0)
		var colour: Color = f[0]
		var part: Vector2 = f[1]
		for p: Vector3 in [a, b, c]:
			pos.append(_anchor if _hidden else p)
			nrm.append(n)
			col.append(colour)
			uv.append(part)

	## A convex quad a, b, c, d (in order round it).
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, f: Array, out: Vector3) -> void:
		tri(a, b, c, f, out)
		tri(a, c, d, f, out)

	## A quad that shades as one face (its two triangles share the diagonals' normal), so a
	## slightly twisted pane or panel does not split into two tones like a cut gem.
	func quad_flat(a: Vector3, b: Vector3, c: Vector3, d: Vector3, f: Array, out: Vector3) -> void:
		var n := (c - a).cross(d - b)
		if n.length_squared() < 1e-12:
			quad(a, b, c, d, f, out)
			return
		n = (xform.basis * n).normalized()
		if n.dot(xform.basis * out) < 0.0:
			n = -n
		_flat = n
		tri(a, b, c, f, out)
		tri(a, c, d, f, out)
		_flat = Vector3.ZERO

	## A box with outward faces; the bottom only if asked (nobody sees it).
	func box(centre: Vector3, size: Vector3, f: Array, bottom := false) -> void:
		var h := size * 0.5
		for axis in 3:
			for sgn: float in [-1.0, 1.0]:
				if axis == 1 and sgn < 0.0 and not bottom:
					continue
				var n := Vector3.ZERO
				n[axis] = sgn
				var u := Vector3.ZERO
				u[(axis + 1) % 3] = h[(axis + 1) % 3]
				var v := Vector3.ZERO
				v[(axis + 2) % 3] = h[(axis + 2) % 3]
				var c := centre + n * h[axis]
				quad(c - u - v, c + u - v, c + u + v, c - u + v, f, n)

	## A flat rectangle across x = `x` (a side), from y0 to y1 and z0 to z1, facing sgn.
	func side_rect(x: float, sgn: float, y0: float, y1: float, z0: float, z1: float, f: Array) -> void:
		quad(Vector3(x, y0, z0), Vector3(x, y0, z1), Vector3(x, y1, z1), Vector3(x, y1, z0), f, Vector3(sgn, 0, 0))

	## A shell lofted along the length: `profile` is the side view as (z, y) points going
	## round a convex outline, `half` the half-width at each point. `edges[i]` colours the
	## face from point i to i + 1 (null: none, as under the car), `side` both side faces
	## (empty: none).
	func loft(profile: PackedVector2Array, half: PackedFloat32Array, edges: Array, side: Array) -> void:
		var n := profile.size()
		var mid := Vector2.ZERO
		for q in profile:
			mid += q
		mid /= n
		for i in n:
			if edges[i] == null:
				continue
			var j := (i + 1) % n
			var a := profile[i]
			var b := profile[j]
			var e := (a + b) * 0.5 - mid
			quad(Vector3(-half[i], a.y, a.x), Vector3(half[i], a.y, a.x), Vector3(half[j], b.y, b.x),
					Vector3(-half[j], b.y, b.x), edges[i], Vector3(0.0, e.y, e.x))
		if side.is_empty():
			return
		for sgn: float in [-1.0, 1.0]:
			for k in range(1, n - 1):
				tri(Vector3(half[0] * sgn, profile[0].y, profile[0].x),
						Vector3(half[k] * sgn, profile[k].y, profile[k].x),
						Vector3(half[k + 1] * sgn, profile[k + 1].y, profile[k + 1].x), side, Vector3(sgn, 0, 0))

	## The face of a loft from point i to i + 1 as [c0, c1, c2, c3, out]: u runs across
	## (c0 -> c1, left to right), v along the profile (c0 -> c3).
	func edge_face(profile: PackedVector2Array, half: PackedFloat32Array, i: int) -> Array:
		var j := (i + 1) % profile.size()
		var a := profile[i]
		var b := profile[j]
		var mid := Vector2.ZERO
		for q in profile:
			mid += q
		mid /= profile.size()
		var e := (a + b) * 0.5 - mid
		return [Vector3(-half[i], a.y, a.x), Vector3(half[i], a.y, a.x), Vector3(half[j], b.y, b.x),
				Vector3(-half[j], b.y, b.x), Vector3(0.0, e.y, e.x)]

	## A four-point loft's side (sgn) as [c0, c1, c2, c3, out]: u runs along the bottom
	## (point 0 -> 3) and the top (1 -> 2), v from the bottom up.
	func side_face(profile: PackedVector2Array, half: PackedFloat32Array, sgn: float) -> Array:
		var p := func(k: int) -> Vector3: return Vector3(half[k] * sgn, profile[k].y, profile[k].x)
		return [p.call(0), p.call(3), p.call(2), p.call(1), Vector3(sgn, 0, 0)]

	## A pane laid on `face` (edge_face / side_face) over u0..u1, v0..v1, `lift` off it.
	func pane(face: Array, u0: float, u1: float, v0: float, v1: float, f: Array, lift := 0.012) -> void:
		var c0: Vector3 = face[0]
		var c1: Vector3 = face[1]
		var c2: Vector3 = face[2]
		var c3: Vector3 = face[3]
		var out: Vector3 = face[4]
		var at := func(u: float, v: float) -> Vector3: return c0.lerp(c1, u).lerp(c3.lerp(c2, u), v)
		var n := (c1 - c0).cross(c3 - c0)
		if n.length_squared() < 1e-10:
			n = (c2 - c3).cross(c3 - c0)
		n = n.normalized() if n.length_squared() > 1e-10 else out.normalized()
		if n.dot(out) < 0.0:
			n = -n
		var o := n * lift
		quad(at.call(u0, v0) + o, at.call(u1, v0) + o, at.call(u1, v1) + o, at.call(u0, v1) + o, f, out)

	## A wheel turning about x, its outer face towards sgn: a `sides`-gon tyre with a flat
	## bottom on the ground and a hub cap. No inner face (nobody sees it).
	func wheel(centre: Vector3, r: float, width: float, sides: int, sgn: float, tyre: Array, hub: Array) -> void:
		var xo := centre.x + sgn * width * 0.5
		var xi := centre.x - sgn * width * 0.5
		var ring: Array[Vector2] = []
		for k in sides:
			var a := deg_to_rad(270.0 - 180.0 / sides + 360.0 * k / sides)
			ring.append(Vector2(cos(a), sin(a)) * r)
		var at := func(x: float, k: int, scale: float) -> Vector3:
			var q: Vector2 = ring[k % sides] * scale
			return Vector3(x, centre.y + q.y, centre.z + q.x)
		for k in range(1, sides - 1):
			tri(at.call(xo, 0, 1.0), at.call(xo, k, 1.0), at.call(xo, k + 1, 1.0), tyre, Vector3(sgn, 0, 0))
		for k in sides:
			var q: Vector2 = (ring[k] + ring[(k + 1) % sides]) * 0.5
			quad(at.call(xi, k, 1.0), at.call(xo, k, 1.0), at.call(xo, k + 1, 1.0), at.call(xi, k + 1, 1.0), tyre,
					Vector3(0, q.y, q.x))
		var xh := xo + sgn * 0.012
		for k in range(1, sides - 1):
			tri(at.call(xh, 0, 0.55), at.call(xh, k, 0.55), at.call(xh, k + 1, 0.55), hub, Vector3(sgn, 0, 0))

	## The dark arch over a wheel on a side (x, facing sgn): the part of a circle round
	## (zc, yc) above the sill line, in `steps` pieces.
	func arch(x: float, sgn: float, zc: float, yc: float, r: float, sill: float, f: Array, steps := 4) -> void:
		var a0 := asin(clampf((sill - yc) / r, -1.0, 1.0))
		var pts: Array[Vector3] = []
		for k in steps + 1:
			var a := lerpf(a0, PI - a0, float(k) / steps)
			pts.append(Vector3(x, yc + sin(a) * r, zc + cos(a) * r))
		for k in range(1, steps):
			tri(pts[0], pts[k], pts[k + 1], f, Vector3(sgn, 0, 0))

	## The triangles so far as a plain mesh (no shapes).
	func mesh() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in pos.size():
			st.set_color(col[i])
			st.set_normal(nrm[i])
			st.set_uv(uv[i])
			st.add_vertex(pos[i])
		st.index()
		return st.commit()


## A colour and part for a Shape's faces: [colour, Vector2(part, UV.y)].
static func fin(colour: Color, part := FIXED, y := 0.0) -> Array:
	return [colour, Vector2(part, y)]


## The one material every model uses (cheap to batch, one shader to compile).
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/actor.gdshader")
	return _material


## An axis-aligned box with outward faces. `leg` marks pedestrian legs (+1 / -1).
static func box(st: SurfaceTool, centre: Vector3, size: Vector3, colour: Color, part := FIXED, leg := 0.0) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := centre + n * h[axis]
			var q := [c - u - v, c + u - v, c + u + v, c - u + v]
			# Godot's front faces are clockwise: (b - a) x (c - a) points away from the viewer.
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(n)
				st.set_uv(Vector2(part, leg))
				st.add_vertex(q[k])


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## The additive material for light on the road (glow.gdshader), shared by every
## vehicle; shown only at night (the game hides the nodes by day).
static func glow_material() -> ShaderMaterial:
	if _glow_material == null:
		_glow_material = ShaderMaterial.new()
		_glow_material.shader = load("res://shaders/glow.gdshader")
		_glow_material.render_priority = 1
	return _glow_material


## Headlight light on the road ahead of a vehicle whose front is `half_length`
## ahead of its origin (fronts face -Z): one soft fan the width of the car that
## widens and fades over `reach` metres, brightest a few metres ahead and dark at
## its edges; and a faint red glow behind. A grid of vertices carries the falloff
## in their colour's alpha (`peak` at its brightest; the look loop gives the player's car a
## stronger one). Flat, a little above the road; the shader lifts it over the road layers.
static func headlight_pools(half_length: float, spread := 0.6, reach := 13.0, tail := true, peak := 0.42) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var warm := Color(1.0, 0.84, 0.58)
	var y := 0.15
	var rings := 7
	var cols := 8
	var grid := []
	for i in rings + 1:
		var t := float(i) / rings
		var row := []
		var half_w := spread + 0.35 + t * reach * 0.3
		for j in cols + 1:
			var u := float(j) / cols * 2.0 - 1.0
			var p := Vector3(u * half_w, y, -half_length - 0.2 - t * reach)
			var along := smoothstep(0.0, 0.18, t) * pow(1.0 - t, 1.6)
			var across := 1.0 - u * u
			row.append([p, peak * along * across * across])
		grid.append(row)
	for i in rings:
		for j in cols:
			var a: Array = grid[i][j]
			var b: Array = grid[i][j + 1]
			var c: Array = grid[i + 1][j + 1]
			var d: Array = grid[i + 1][j]
			for v in [a, b, c, a, c, d]:
				_glow_vertex(st, v[0], Color(warm, v[1]))
	if tail:
		var red := Color(1.0, 0.08, 0.05)
		var centre := Vector3(0.0, y, half_length + 0.9)
		var n := 12
		for k in n:
			var a0 := TAU * k / n
			var a1 := TAU * (k + 1) / n
			_glow_vertex(st, centre, Color(red, 0.16))
			_glow_vertex(st, centre + Vector3(cos(a0) * 1.6, 0.0, sin(a0) * 1.3), Color(red, 0.0))
			_glow_vertex(st, centre + Vector3(cos(a1) * 1.6, 0.0, sin(a1) * 1.3), Color(red, 0.0))
	return st.commit()


static func _glow_vertex(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	st.set_normal(Vector3.UP)
	st.add_vertex(p)


# --- loop 2c: the vehicles -------------------------------------------------------------

## Loop 2c: one mesh holding up to four shapes with the same parts (the first is the mesh's
## own; the others go in CUSTOM0..2 as position and packed normal, see actor.gdshader). A
## shape's triangles keep the winding of the first shape in which they have an area.
static func family(shapes: Array) -> ArrayMesh:
	var base: Shape = shapes[0]
	var count := base.pos.size()
	var chans: Array[Shape] = []
	for k in 3:
		chans.append(shapes[k + 1] if k + 1 < shapes.size() else base)
	for s: Shape in shapes:
		if s.pos.size() != count:
			push_error("models: a family's shapes differ (%d vs %d vertices)" % [s.pos.size(), count])
			return base.mesh()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ch in 3:
		st.set_custom_format(ch, SurfaceTool.CUSTOM_RGBA_FLOAT)
	for t in count / 3:
		var canon := -1
		for s: Shape in shapes:
			if s.solid[t] == 1:
				if canon < 0:
					canon = s.flip[t]
				elif s.flip[t] != canon:
					push_warning("models: triangle %d faces the other way in one shape" % t)
		if canon < 0:
			canon = base.flip[t]
		for k in 3:
			for ch in 3:
				var s := chans[ch]
				var o := t * 3 + (k if s.flip[t] == canon or k == 0 else 3 - k)
				st.set_custom(ch, Color(s.pos[o].x, s.pos[o].y, s.pos[o].z, _pack_normal(s.nrm[o])))
			var o0 := t * 3 + (k if base.flip[t] == canon or k == 0 else 3 - k)
			st.set_color(base.col[o0])
			st.set_normal(base.nrm[o0])
			st.set_uv(Vector2(base.uv[o0].x + MORPH, base.uv[o0].y))
			st.add_vertex(base.pos[o0])
	st.index()
	return st.commit()


## A unit normal as one float: octahedral, 12 bits a coordinate (exact in a 32-bit float);
## actor.gdshader unpacks it.
static func _pack_normal(n: Vector3) -> float:
	var s := absf(n.x) + absf(n.y) + absf(n.z)
	if s < 1e-6:
		n = Vector3.UP
		s = 1.0
	var e := Vector2(n.x, n.y) / s
	if n.z < 0.0:
		e = Vector2((1.0 - absf(e.y)) * (1.0 if e.x >= 0.0 else -1.0), (1.0 - absf(e.x)) * (1.0 if e.y >= 0.0 else -1.0))
	var u := roundi((e.x * 0.5 + 0.5) * 4095.0)
	var v := roundi((e.y * 0.5 + 0.5) * 4095.0)
	return float(u * 4096 + v)


## The measurements of one body (metres; the front at -L/2): its length L and half-width W,
## the sill, the bumper tops front and back, the bonnet's front edge (nose, nose_in from
## the front), the windscreen's foot (cowl_z, cowl_y), the rear window's foot (belt_z,
## belt_y), the end of the rear deck (tail_y, tail_in), the roof (roof_y from roof_z0 to
## roof_z1), the glasshouse's half-width at its foot and at the roof (gw0, gw1), the wheels
## (r, axle_f, axle_r) and where the B pillar stands (bp, 0..1 along the side windows).
static func spec(name: String) -> Dictionary:
	var p := {"L": 4.0, "W": 0.87, "sill": 0.3, "bump_f": 0.54, "bump_r": 0.52, "nose": 0.8, "nose_in": 0.14,
			"cowl_z": -0.8, "cowl_y": 0.95, "belt_z": 1.7, "belt_y": 0.98, "tail_y": 0.96, "tail_in": 0.06,
			"roof_y": 1.48, "roof_z0": -0.15, "roof_z1": 1.5, "gw0": 0.83, "gw1": 0.7, "r": 0.3,
			"axle_f": -1.3, "axle_r": 1.25, "bp": 0.5, "rear_pane": true, "rails": false,
			"ws_v": Vector2(0.07, 0.93), "rw_v": Vector2(0.1, 0.92), "sp_v": Vector2(0.1, 0.9), "sides": 6}
	match name:
		"hatch":
			p.merge({"L": 3.95, "W": 0.86, "axle_f": -1.28, "axle_r": 1.24}, true)
		"saloon":
			p.merge({"L": 4.6, "W": 0.89, "bump_f": 0.52, "bump_r": 0.56, "nose": 0.78, "nose_in": 0.16,
					"cowl_z": -0.95, "cowl_y": 0.96, "belt_z": 1.18, "belt_y": 1.0, "tail_y": 1.0, "tail_in": 0.1,
					"roof_y": 1.43, "roof_z0": -0.22, "roof_z1": 0.68, "gw0": 0.85, "gw1": 0.7, "r": 0.31,
					"axle_f": -1.42, "axle_r": 1.38, "bp": 0.52}, true)
		"estate":
			p.merge({"L": 4.65, "W": 0.89, "bump_f": 0.52, "bump_r": 0.52, "nose": 0.78, "nose_in": 0.16,
					"cowl_z": -0.95, "cowl_y": 0.96, "belt_z": 2.2, "belt_y": 0.99, "tail_y": 0.97, "tail_in": 0.06,
					"roof_y": 1.47, "roof_z0": -0.22, "roof_z1": 2.02, "gw0": 0.85, "gw1": 0.72, "r": 0.31,
					"axle_f": -1.42, "axle_r": 1.4, "bp": 0.4, "rails": true}, true)
		"suv":
			p.merge({"L": 4.5, "W": 0.93, "sill": 0.46, "bump_f": 0.74, "bump_r": 0.74, "nose": 1.02, "nose_in": 0.14,
					"cowl_z": -0.9, "cowl_y": 1.13, "belt_z": 1.95, "belt_y": 1.16, "tail_y": 1.13, "tail_in": 0.06,
					"roof_y": 1.74, "roof_z0": -0.12, "roof_z1": 1.8, "gw0": 0.88, "gw1": 0.77, "r": 0.37,
					"axle_f": -1.4, "axle_r": 1.36, "bp": 0.46, "rails": true}, true)
		"panel van":
			p.merge({"L": 5.2, "W": 0.99, "sill": 0.4, "bump_f": 0.62, "bump_r": 0.56, "nose": 0.98, "nose_in": 0.16,
					"cowl_z": -1.8, "cowl_y": 1.12, "belt_z": 2.6, "belt_y": 1.12, "tail_y": 1.12, "tail_in": 0.0,
					"roof_y": 2.42, "roof_z0": -0.95, "roof_z1": 2.6, "gw0": 0.97, "gw1": 0.92, "r": 0.34,
					"axle_f": -1.72, "axle_r": 1.72, "bp": 0.17, "rear_pane": false,
					"ws_v": Vector2(0.05, 0.62), "rw_v": Vector2(0.55, 0.85), "sp_v": Vector2(0.3, 0.62)}, true)
		"box van":
			p.merge({"L": 5.4, "W": 0.99, "sill": 0.42, "bump_f": 0.64, "bump_r": 0.58, "nose": 0.98, "nose_in": 0.16,
					"cowl_z": -1.85, "cowl_y": 1.12, "belt_z": -0.42, "belt_y": 1.12, "tail_y": 1.0, "tail_in": 0.0,
					"roof_y": 2.08, "roof_z0": -1.22, "roof_z1": -0.55, "gw0": 0.97, "gw1": 0.9, "r": 0.34,
					"axle_f": -1.8, "axle_r": 1.75, "bp": 0.85, "rear_pane": false,
					"ws_v": Vector2(0.06, 0.9), "rw_v": Vector2(0.3, 0.8), "sp_v": Vector2(0.18, 0.88)}, true)
		"tow truck":
			# Road life stage 2: the box van's cab moved to the front of a 6.6 m chassis.
			p.merge({"L": 6.6, "W": 0.99, "sill": 0.42, "bump_f": 0.64, "bump_r": 0.5, "nose": 0.98, "nose_in": 0.16,
					"cowl_z": -2.45, "cowl_y": 1.12, "belt_z": -1.02, "belt_y": 1.1, "tail_y": 1.06, "tail_in": 0.0,
					"roof_y": 2.08, "roof_z0": -1.82, "roof_z1": -1.15, "gw0": 0.97, "gw1": 0.9, "r": 0.34,
					"axle_f": -2.4, "axle_r": 1.95, "bp": 0.85, "rear_pane": false,
					"ws_v": Vector2(0.06, 0.9), "rw_v": Vector2(0.3, 0.8), "sp_v": Vector2(0.18, 0.88)}, true)
		"player":
			# The player's hatch: shorter overhangs, a lower roof with more rake, wider.
			p.merge({"L": 4.0, "W": 0.9, "sill": 0.28, "bump_f": 0.5, "bump_r": 0.5, "nose": 0.79, "nose_in": 0.18,
					"cowl_z": -0.74, "cowl_y": 0.96, "belt_z": 1.66, "belt_y": 1.0, "tail_y": 0.98, "tail_in": 0.1,
					"roof_y": 1.44, "roof_z0": -0.06, "roof_z1": 1.42, "gw0": 0.85, "gw1": 0.69, "r": 0.32,
					"axle_f": -1.3, "axle_r": 1.3, "bp": 0.5, "sides": 8}, true)
		"player_tt":
			# G13: the shop's "Ołdi TT" (a parody of a certain Bavarian-Ingolstadt coupe): the
			# player's footprint (the collision box is shared) but a lower, wider, rounder
			# coupe, a short glasshouse, bigger wheels.
			p.merge({"L": 4.1, "W": 0.94, "sill": 0.22, "bump_f": 0.44, "bump_r": 0.46, "nose": 0.7, "nose_in": 0.26,
					"cowl_z": -0.5, "cowl_y": 0.88, "belt_z": 1.55, "belt_y": 0.92, "tail_y": 0.9, "tail_in": 0.18,
					"roof_y": 1.26, "roof_z0": 0.12, "roof_z1": 0.72, "gw0": 0.86, "gw1": 0.6, "r": 0.34,
					"axle_f": -1.28, "axle_r": 1.26, "bp": 0.55, "sides": 8}, true)
		# C1a/C1b (F 2026-11-27): the shop's meme cars, parodies with no badges, each within the
		# collision box's footprint (car.gd 1.8 x 4.0 m, bodies up to 4.45 long as the TT's 4.1).
		"player_lanos":
			# Dejwu Łanos: a small, upright, rounded three-box saloon with a short boot.
			p.merge({"L": 4.24, "W": 0.86, "sill": 0.3, "bump_f": 0.52, "bump_r": 0.55, "nose": 0.8, "nose_in": 0.2,
					"cowl_z": -0.74, "cowl_y": 0.96, "belt_z": 1.22, "belt_y": 1.0, "tail_y": 1.0, "tail_in": 0.12,
					"roof_y": 1.43, "roof_z0": -0.08, "roof_z1": 0.76, "gw0": 0.82, "gw1": 0.68, "r": 0.29,
					"axle_f": -1.3, "axle_r": 1.26, "bp": 0.5, "sides": 8}, true)
		"player_bolonez":
			# FSŁ Bolonez Karo: a long flat bonnet, an upright windscreen, a squared roof and a long
			# fastback hatch down to a cut-off tail; tall and boxy.
			p.merge({"L": 4.34, "W": 0.87, "sill": 0.31, "bump_f": 0.58, "bump_r": 0.58, "nose": 0.84, "nose_in": 0.08,
					"cowl_z": -0.55, "cowl_y": 1.0, "belt_z": 1.98, "belt_y": 1.05, "tail_y": 1.04, "tail_in": 0.03,
					"roof_y": 1.5, "roof_z0": -0.05, "roof_z1": 1.12, "gw0": 0.82, "gw1": 0.7, "r": 0.3,
					"axle_f": -1.3, "axle_r": 1.34, "bp": 0.44, "sides": 8, "ws_v": Vector2(0.08, 0.92),
					"rw_v": Vector2(0.08, 0.9)}, true)
		"player_paszat":
			# Paszat B5 TDI: a lowered estate, a long roof to an upright tailgate, roof rails.
			p.merge({"L": 4.45, "W": 0.88, "sill": 0.24, "bump_f": 0.5, "bump_r": 0.52, "nose": 0.76, "nose_in": 0.18,
					"cowl_z": -0.92, "cowl_y": 0.94, "belt_z": 2.02, "belt_y": 0.98, "tail_y": 0.96, "tail_in": 0.05,
					"roof_y": 1.39, "roof_z0": -0.22, "roof_z1": 1.86, "gw0": 0.84, "gw1": 0.71, "r": 0.3,
					"axle_f": -1.4, "axle_r": 1.36, "bp": 0.4, "rails": true, "sides": 8}, true)
		"player_szupra":
			# Tojota Szupra: a long, low, round nose, the cabin set back, a bubble roof, a short high
			# tail with the hoop wing (models.gd player_meshes adds it).
			p.merge({"L": 4.42, "W": 0.93, "sill": 0.2, "bump_f": 0.42, "bump_r": 0.52, "nose": 0.64, "nose_in": 0.3,
					"cowl_z": -0.28, "cowl_y": 0.86, "belt_z": 1.3, "belt_y": 0.93, "tail_y": 0.93, "tail_in": 0.16,
					"roof_y": 1.2, "roof_z0": 0.18, "roof_z1": 0.84, "gw0": 0.84, "gw1": 0.63, "r": 0.34,
					"axle_f": -1.36, "axle_r": 1.3, "bp": 0.62, "sides": 8}, true)
		"player_bawarka":
			# Bawarka Darka: a squat Bavarian-style two-door race coupe, low on big wheels, a long
			# bonnet, a short boot; the flares, splitter, skirts and the GT wing in player_meshes.
			p.merge({"L": 4.45, "W": 0.94, "sill": 0.17, "bump_f": 0.42, "bump_r": 0.48, "nose": 0.68, "nose_in": 0.22,
					"cowl_z": -0.55, "cowl_y": 0.9, "belt_z": 1.42, "belt_y": 0.96, "tail_y": 0.96, "tail_in": 0.14,
					"roof_y": 1.3, "roof_z0": 0.0, "roof_z1": 0.84, "gw0": 0.84, "gw1": 0.66, "r": 0.36,
					"axle_f": -1.38, "axle_r": 1.34, "bp": 0.58, "sides": 8}, true)
		"coupe":
			p.merge({"L": 4.4, "W": 0.92, "sill": 0.22, "bump_f": 0.44, "bump_r": 0.46, "nose": 0.66, "nose_in": 0.2,
					"cowl_z": -0.5, "cowl_y": 0.86, "belt_z": 1.75, "belt_y": 0.9, "tail_y": 0.9, "tail_in": 0.12,
					"roof_y": 1.22, "roof_z0": 0.15, "roof_z1": 0.85, "gw0": 0.84, "gw1": 0.66, "r": 0.31,
					"axle_f": -1.4, "axle_r": 1.42, "bp": 0.55, "rear_pane": true}, true)
		"supercar":
			# City-life satire #1 (loud_cars.gd): the loud supercar, no marque: low, wide, a long
			# nose, the cabin pushed back, a short glasshouse, big wheels (six-sided like the
			# rest of its family: the taxis' MultiMesh).
			p.merge({"L": 4.55, "W": 0.98, "sill": 0.16, "bump_f": 0.36, "bump_r": 0.42, "nose": 0.6, "nose_in": 0.28,
					"cowl_z": -0.35, "cowl_y": 0.78, "belt_z": 1.3, "belt_y": 0.84, "tail_y": 0.86, "tail_in": 0.1,
					"roof_y": 1.12, "roof_z0": 0.15, "roof_z1": 0.72, "gw0": 0.86, "gw1": 0.6, "r": 0.34,
					"axle_f": -1.42, "axle_r": 1.4, "bp": 0.62}, true)
		"liftback":
			# The city taxi (2026-11-19, F: "toyota prius"): Warsaw's taxis are mostly hybrid
			# liftbacks, no marque: a low wedge nose, a long raked windscreen, the roof's peak
			# forward, one long sloping rear pane down to a high, cut-off tail.
			p.merge({"L": 4.6, "W": 0.88, "sill": 0.3, "bump_f": 0.5, "bump_r": 0.6, "nose": 0.74, "nose_in": 0.18,
					"cowl_z": -1.02, "cowl_y": 0.92, "belt_z": 2.1, "belt_y": 1.03, "tail_y": 1.03, "tail_in": 0.04,
					"roof_y": 1.46, "roof_z0": -0.38, "roof_z1": 0.42, "gw0": 0.84, "gw1": 0.68, "r": 0.31,
					"axle_f": -1.4, "axle_r": 1.36, "bp": 0.5}, true)
		"crossover":
			# Łuber's car (2026-11-19, F: "tesla y"): an electric crossover, no marque: a smooth
			# rounded nose with no grille height, a tall body, a fastback roof falling in one curve
			# to a short tail.
			p.merge({"L": 4.75, "W": 0.95, "sill": 0.4, "bump_f": 0.62, "bump_r": 0.68, "nose": 0.9, "nose_in": 0.22,
					"cowl_z": -1.0, "cowl_y": 1.06, "belt_z": 2.12, "belt_y": 1.1, "tail_y": 1.1, "tail_in": 0.08,
					"roof_y": 1.64, "roof_z0": -0.2, "roof_z1": 0.72, "gw0": 0.9, "gw1": 0.72, "r": 0.37,
					"axle_f": -1.45, "axle_r": 1.45, "bp": 0.48}, true)
		"city car":
			p.merge({"L": 3.4, "W": 0.8, "sill": 0.3, "bump_f": 0.52, "bump_r": 0.52, "nose": 0.82, "nose_in": 0.14,
					"cowl_z": -0.85, "cowl_y": 0.98, "belt_z": 1.48, "belt_y": 1.0, "tail_y": 0.98, "tail_in": 0.04,
					"roof_y": 1.54, "roof_z0": -0.32, "roof_z1": 1.34, "gw0": 0.77, "gw1": 0.66, "r": 0.28,
					"axle_f": -1.08, "axle_r": 1.06, "bp": 0.48}, true)
	return p


## One body from spec(): the lofted lower body, the glasshouse, its panes, bumpers, plates,
## grille, lamps (`lamps` false: the player's car has its own), wheels in arches and roof
## rails. `paint` colours the body, `roof` the roof, `glass` the panes.
static func _vehicle(s: Shape, p: Dictionary, paint: Array, roof: Array = [], glass: Array = [], lamps := true) -> void:
	if roof.is_empty():
		roof = paint
	if glass.is_empty():
		glass = fin(GLASS)
	var trim := fin(TRIM)
	var L: float = p["L"]
	var W: float = p["W"]
	var sill: float = p["sill"]
	var hl := -L * 0.5
	var lower := _lower(p)
	var lw := _widths(lower, W)
	s.loft(lower, lw, [paint, paint, paint, paint, paint, paint, paint, null], paint)
	var gw0: float = p["gw0"]
	var gw1: float = p["gw1"]
	var roof_y: float = p["roof_y"]
	var house := PackedVector2Array([Vector2(p["cowl_z"], p["cowl_y"]), Vector2(p["roof_z0"], roof_y),
			Vector2(p["roof_z1"], roof_y), Vector2(p["belt_z"], p["belt_y"])])
	var hw := PackedFloat32Array([gw0, gw1, gw1, gw0])
	s.loft(house, hw, [paint, roof, paint, null], paint)
	# Glass: the windscreen and the rear window inside their frames, two side windows a side
	# with the B pillar between them (a van shows only the cab's).
	var ws: Vector2 = p["ws_v"]
	var rw: Vector2 = p["rw_v"]
	var sp: Vector2 = p["sp_v"]
	var bp: float = p["bp"]
	s.pane(s.edge_face(house, hw, 0), 0.06, 0.94, ws.x, ws.y, glass)
	s.pane(s.edge_face(house, hw, 2), 0.08, 0.92, 1.0 - rw.y, 1.0 - rw.x, glass)
	var mid_house := Vector3(0.0, (p["cowl_y"] + roof_y) * 0.5, (p["roof_z0"] + p["roof_z1"]) * 0.5)
	for sgn: float in [-1.0, 1.0]:
		var side := s.side_face(house, hw, sgn)
		s.pane(side, 0.05, bp - 0.035, sp.x, sp.y, glass)
		s.keep_if(p["rear_pane"], mid_house)
		s.pane(side, bp + 0.035, 0.95, sp.x, sp.y, glass)
		s.show()
	# Bumpers, plates, the grille.
	var bump_h := 0.22
	for e: float in [-1.0, 1.0]:
		s.box(Vector3(0.0, sill + bump_h * 0.5 - 0.05, -e * (hl + 0.1)), Vector3(W * 2.0 + 0.04, bump_h, 0.34), trim)
		var z := -e * (hl - 0.07 - 0.004)
		s.quad(Vector3(-0.26, sill - 0.01, z), Vector3(0.26, sill - 0.01, z), Vector3(0.26, sill + 0.1, z),
				Vector3(-0.26, sill + 0.1, z), fin(PLATE), Vector3(0, 0, e))
	var nose := s.edge_face(lower, lw, 1)
	s.pane(nose, 0.32, 0.68, 0.15, 0.75, fin(GRILLE))
	if lamps:
		s.pane(nose, 0.05, 0.27, 0.3, 0.9, fin(HEADLIGHT, HEAD_LAMP))
		s.pane(nose, 0.73, 0.95, 0.3, 0.9, fin(HEADLIGHT, HEAD_LAMP))
		var back := s.edge_face(lower, lw, 5)
		s.pane(back, 0.04, 0.25, 0.08, 0.7, fin(TAIL, TAIL_LAMP))
		s.pane(back, 0.75, 0.96, 0.08, 0.7, fin(TAIL, TAIL_LAMP))
	# Wheels in their arches.
	var r: float = p["r"]
	var sides: int = p["sides"]
	var wc := r * cos(PI / sides)
	var tyre_w := 0.24
	for z: float in [p["axle_f"], p["axle_r"]]:
		for sgn: float in [-1.0, 1.0]:
			s.arch(sgn * (W + 0.006), sgn, z, wc, r + 0.07, sill, fin(WELL))
			s.wheel(Vector3(sgn * (W + 0.02 - tyre_w * 0.5), wc, z), r, tyre_w, sides, sgn, fin(TYRE), fin(HUB))
	# Roof rails (estates and SUVs).
	s.keep_if(p["rails"], mid_house)
	var rail_len: float = p["roof_z1"] - p["roof_z0"] - 0.3
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * (gw1 - 0.1), roof_y + 0.035, (p["roof_z0"] + p["roof_z1"]) * 0.5 + 0.05),
				Vector3(0.06, 0.07, rail_len), trim)
	s.show()


## Loop 2c: traffic.gd's mesh for a kind (0 cars, 1 taxis, 2 vans, 3 the bus): a family of the
## shapes in TRAFFIC[kind], in that order.
static func traffic_mesh(kind: int) -> ArrayMesh:
	var paint := fin(Color.WHITE, PAINT)
	match kind:
		0:
			var shapes: Array = []
			for n: String in ["hatch", "saloon", "estate", "suv"]:
				var s := Shape.new()
				_vehicle(s, spec(n), paint)
				_dress(s, spec(n))
				shapes.append(s)
			return family(shapes)
		1:
			return family([_taxi(TAXI_CITY), _taxi(TAXI_APP), _taxi(TAXI_SUPERCAR), _taxi(TAXI_PASAT)])
		2:
			return family([_van(VAN_PANEL), _van(VAN_BOX), _van(VAN_TOW), _van(VAN_TOW_LOADED)])
	return bus_mesh()


## Road life (2026-11-26): a traffic car's two dressings, in every CAR shape (the family's parts
## match), shown by actor.gdshader only in their mode: the Elka's roof box (a blue box, a white L
## on its front and back) and a wedding car's white ribbons from the mirrors to the bonnet's nose,
## a bouquet on the nose and a bow on each mirror.
static func _dress(s: Shape, p: Dictionary) -> void:
	var L: float = p["L"]
	var W: float = p["W"]
	var roof_y: float = p["roof_y"]
	var rz := (float(p["roof_z0"]) + float(p["roof_z1"])) * 0.5
	var blue := fin(L_BLUE, DRESS_L)
	var white := fin(Color("#f4f4f0"), DRESS_L)
	s.box(Vector3(0.0, roof_y + 0.17, rz), Vector3(0.62, 0.32, 0.42), blue)
	for e: float in [-1.0, 1.0]:
		var z := rz + e * 0.215
		# Looking at that face, the viewer's right is +x * e: the stem on the left, the foot to the right.
		s.box(Vector3(-e * 0.06, roof_y + 0.18, z), Vector3(0.07, 0.24, 0.012), white)
		s.box(Vector3(e * 0.01, roof_y + 0.095, z), Vector3(0.21, 0.07, 0.012), white)
	var rib := fin(Color("#f8f8f4"), DRESS_WEDDING)
	var nose_y: float = p["nose"] + 0.03
	var nose_z := -L * 0.5 + 0.32
	var cowl_z: float = p["cowl_z"]
	var cowl_y: float = p["cowl_y"] + 0.03
	for sgn: float in [-1.0, 1.0]:
		var a := Vector3(sgn * (W - 0.06), cowl_y, cowl_z + 0.05)
		var b := Vector3(sgn * 0.05, nose_y, nose_z)
		var side := Vector3(0.0, 0.0, 0.09)
		s.quad(a - side, a + side, b + side, b - side, rib, Vector3.UP)
		s.box(Vector3(sgn * (W + 0.06), cowl_y + 0.03, cowl_z + 0.12), Vector3(0.14, 0.16, 0.1), rib)
	s.box(Vector3(0.0, nose_y + 0.07, nose_z), Vector3(0.38, 0.16, 0.28), fin(Color("#ffffff"), DRESS_WEDDING))
	s.box(Vector3(-0.08, nose_y + 0.17, nose_z - 0.03), Vector3(0.12, 0.08, 0.12), fin(Color("#f29bb8"), DRESS_WEDDING))
	s.box(Vector3(0.09, nose_y + 0.17, nose_z + 0.04), Vector3(0.12, 0.08, 0.12), fin(Color("#f29bb8"), DRESS_WEDDING))


## The city taxi (an invented livery: a white hybrid liftback with a yellow band of dark squares along
## the doors and a lit yellow roof sign) or Łuber, the app taxi (parodies.md 3.1: an electric crossover
## in its own paint with a phone standing on the roof, its screen lit). City-life satire #1
## (loud_cars.gd, 2026-11-02): `which` 2 is the loud supercar that shares the taxis' MultiMesh
## (no draw call of its own): a low, wide wedge with no badge and no marque, a carbon wing on
## two struts, four exhaust tips, black side intakes and a splitter. Every shape adds the same
## parts in the same order (family() morphs between them): the roof sign, the phone, the
## supercar's kit; a part another shape owns is hidden. Crazy drivers (2026-11-05): `which` 3 is
## the Pasatini 1.9 TDJ (a parody of a certain cult German estate, no badge): spec("estate") with
## its roof rails, a dark sun strip over the windscreen, a boot-lip spoiler on the roof's end and
## two chrome exhaust tips. The family then holds four shapes, the most it takes.
const TAXI_CITY := 0
const TAXI_APP := 1
const TAXI_SUPERCAR := 2
const TAXI_PASAT := 3
static func _taxi(which: int) -> Shape:
	var s := Shape.new()
	var city := which == TAXI_CITY
	var p := spec(["liftback", "crossover", "supercar", "estate"][which])
	_vehicle(s, p, fin(Color.WHITE, PAINT))
	var roof_y: float = p["roof_y"]
	var mid := Vector3(0.0, roof_y - 0.2, (p["roof_z0"] + p["roof_z1"]) * 0.5)
	var W: float = p["W"]
	var L: float = p["L"]
	var yellow := Color("#f3c72b")
	s.keep_if(city, mid)
	s.box(mid + Vector3(0.0, 0.31, -0.05), Vector3(0.72, 0.2, 0.3), fin(yellow, LIT_SIGN))
	s.box(mid + Vector3(0.0, 0.215, -0.05), Vector3(0.5, 0.03, 0.22), fin(GRILLE))
	var y0: float = p["belt_y"] - 0.3
	var z0: float = p["axle_f"] + 0.42
	var z1: float = p["axle_r"] - 0.42
	var squares := 8
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.01), sgn, y0, y0 + 0.17, z0, z1, fin(yellow))
		for k in squares:
			if k % 2 == 1:
				continue
			var za := lerpf(z0, z1, float(k) / squares)
			var zb := lerpf(z0, z1, float(k + 1) / squares)
			s.side_rect(sgn * (W + 0.018), sgn, y0 + 0.02, y0 + 0.15, za, zb, fin(Color("#1f1f22")))
	s.keep_if(which == TAXI_APP, mid)
	# The phone: an upright dark bezel, its screen lit both sides, a row of five dark stars.
	var phone := Vector3(0.0, roof_y + 0.28, mid.z + 0.1)
	s.box(phone, Vector3(0.08, 0.5, 0.32), fin(Color("#1f1f22")))
	for sgn: float in [-1.0, 1.0]:
		var x := sgn * 0.045
		s.side_rect(x, sgn, phone.y - 0.2, phone.y + 0.21, phone.z - 0.13, phone.z + 0.13, fin(Color("#e8f4ff"), LIT_SIGN))
		for k in 5:
			var zc := phone.z - 0.1 + k * 0.05
			s.side_rect(x + sgn * 0.004, sgn, phone.y - 0.15, phone.y - 0.11, zc - 0.016, zc + 0.016, fin(Color("#1f1f22")))
	# The supercar's kit (the rest of the body is spec("supercar")): carbon in TRIM's dark.
	var tail := Vector3(0.0, float(p["tail_y"]), L * 0.5)
	s.keep_if(which == TAXI_SUPERCAR, tail)
	var carbon := fin(Color("#1c1d20"))
	var tail_y: float = p["tail_y"]
	var sill: float = p["sill"]
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * 0.52, tail_y + 0.12, L * 0.5 - 0.42), Vector3(0.05, 0.26, 0.14), carbon)
	s.box(Vector3(0.0, tail_y + 0.27, L * 0.5 - 0.4), Vector3(W * 2.0 - 0.06, 0.05, 0.36), carbon)
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * (W - 0.03), tail_y + 0.2, L * 0.5 - 0.4), Vector3(0.03, 0.2, 0.42), carbon)
	for x: float in [-0.38, -0.22, 0.22, 0.38]:
		s.box(Vector3(x, sill + 0.06, L * 0.5 + 0.02), Vector3(0.12, 0.1, 0.12), fin(Color("#7d8086")))
		s.quad(Vector3(x - 0.04, sill + 0.025, L * 0.5 + 0.085), Vector3(x + 0.04, sill + 0.025, L * 0.5 + 0.085),
				Vector3(x + 0.04, sill + 0.095, L * 0.5 + 0.085), Vector3(x - 0.04, sill + 0.095, L * 0.5 + 0.085),
				fin(WELL), Vector3(0, 0, 1))
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.012), sgn, sill + 0.24, sill + 0.5, 0.45, 0.95, fin(GRILLE))
	s.box(Vector3(0.0, sill - 0.04, -L * 0.5 + 0.12), Vector3(W * 2.0 + 0.02, 0.04, 0.3), carbon)
	# The Pasatini's kit: sun strip, boot-lip spoiler, twin chrome tips.
	s.keep_if(which == TAXI_PASAT, tail)
	var dark := fin(Color("#141518"))
	var roof_z0: float = p["roof_z0"]
	var roof_z1: float = p["roof_z1"]
	s.box(Vector3(0.0, roof_y - 0.06, roof_z0 - 0.06), Vector3(float(p["gw1"]) * 2.0 - 0.04, 0.1, 0.16), dark)
	s.box(Vector3(0.0, roof_y + 0.03, roof_z1 + 0.04), Vector3(float(p["gw1"]) * 2.0, 0.05, 0.22), dark)
	for x: float in [-0.5, -0.36]:
		s.box(Vector3(x, sill + 0.06, L * 0.5 + 0.03), Vector3(0.1, 0.09, 0.14), fin(Color("#c9ccd1")))
	s.show()
	return s


## A panel van, or a box van (a short cab under a tall box that reaches over it), or (road life
## stage 2) the laweta: the box van's cab on a longer chassis carrying a flat aluminium platform
## with two ramp tips at the back, a headboard behind the cab and a yellow beacon bar on its roof
## (lit at night), empty or with a car on the platform (a hatch in TOW_LOAD_PAINT, the paint of the
## car crash_scenes.gd's "Odholowanie" loads, so the loaded truck takes over from that car without
## a jump). Every shape adds the same parts in the same order (family()); the box van's box and the
## tow's platform hide where they don't belong, and the car on the platform shrinks to a point
## (Shape.xform scaled to zero: _vehicle() shows its own parts again on its way).
const VAN_PANEL := 0
const VAN_BOX := 1
const VAN_TOW := 2
const VAN_TOW_LOADED := 3
const TOW_LOAD_PAINT := Color("#5d6f8a")
## The loaded car's place on the laweta (its origin: the middle of its wheels' footprint).
const TOW_LOAD_AT := Vector3(0.0, 1.27, 1.3)
const TOW_PLATFORM := Color("#a3a8ae")
const TOW_BEACON := Color("#ffc21a")
static func _van(which: int) -> Shape:
	var s := Shape.new()
	var boxed := which == VAN_BOX
	var tow := which >= VAN_TOW
	var p := spec("tow truck" if tow else "box van" if boxed else "panel van")
	var paint := fin(Color.WHITE, PAINT)
	_vehicle(s, p, paint)
	var L: float = p["L"]
	s.keep_if(boxed, Vector3(0.0, 1.0, 0.0))
	s.box(Vector3(0.0, 1.9, (-0.36 + L * 0.5) * 0.5), Vector3(2.08, 1.72, L * 0.5 + 0.36), paint, true)
	s.box(Vector3(0.0, 2.43, -0.8), Vector3(2.04, 0.66, 0.9), paint, true)
	s.box(Vector3(0.0, 1.03, (-0.36 + L * 0.5) * 0.5), Vector3(2.0, 0.06, L * 0.5 + 0.3), fin(TRIM))
	# The laweta's kit (spec("tow truck") is 6.6 m: the cab ends at z -1.0, the platform runs to
	# the tail and a little past it).
	s.keep_if(tow, Vector3(0.0, 1.1, 1.0))
	var z0 := -0.95
	var z1 := L * 0.5 + 0.12
	var top := TOW_LOAD_AT.y
	var alu := fin(TOW_PLATFORM)
	var dark := fin(Color("#3a3d42"))
	s.box(Vector3(0.0, top - 0.07, (z0 + z1) * 0.5), Vector3(2.24, 0.14, z1 - z0), alu, true)
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * 1.1, top + 0.03, (z0 + z1) * 0.5), Vector3(0.06, 0.08, z1 - z0), dark)
		# The ramp tips, sloping from the platform's end down towards the road.
		var x0 := sgn * 0.95 - 0.28
		var x1 := sgn * 0.95 + 0.28
		s.quad(Vector3(x0, top, z1), Vector3(x1, top, z1), Vector3(x1, top - 0.38, z1 + 0.42),
				Vector3(x0, top - 0.38, z1 + 0.42), alu, Vector3(0.0, 0.7, 0.7))
		# The yellow-and-black stripes on the platform's sides.
		s.side_rect(sgn * 1.125, sgn, top - 0.13, top - 0.03, z0 + 0.2, z1 - 0.2, fin(TOW_BEACON))
	# The headboard behind the cab: two posts and two bars.
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * 1.0, top + 0.5, z0 + 0.05), Vector3(0.09, 1.0, 0.09), dark)
	s.box(Vector3(0.0, top + 0.97, z0 + 0.05), Vector3(2.08, 0.08, 0.09), dark)
	s.box(Vector3(0.0, top + 0.55, z0 + 0.05), Vector3(2.08, 0.06, 0.06), dark)
	# The beacon bar on the cab's roof.
	var roof_y: float = p["roof_y"]
	var roof_mid := (float(p["roof_z0"]) + float(p["roof_z1"])) * 0.5
	s.box(Vector3(0.0, roof_y + 0.04, roof_mid), Vector3(1.3, 0.06, 0.24), dark)
	s.box(Vector3(0.0, roof_y + 0.12, roof_mid), Vector3(1.16, 0.12, 0.2), fin(TOW_BEACON, LIT_SIGN))
	s.show()
	# The car on the platform (shrunk to a point unless loaded).
	if which == VAN_TOW_LOADED:
		s.xform = Transform3D(Basis.IDENTITY, TOW_LOAD_AT)
	else:
		s.xform = Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, 1.1, 1.0))
	_vehicle(s, spec("hatch"), fin(TOW_LOAD_PAINT))
	s.xform = Transform3D.IDENTITY
	s.show()
	# Road life (2026-11-26): the hazard lamps at the four corners (traffic.gd Driver.hazard: the
	# dostawczak), dim amber lenses unless they flash.
	var W: float = p["W"]
	var lamp := fin(HAZARD, BLINK, HAZARD_BEAT)
	for e: float in [-1.0, 1.0]:
		for sgn: float in [-1.0, 1.0]:
			s.box(Vector3(sgn * (W - 0.02), float(p["sill"]) + 0.42, e * (L * 0.5 + 0.02)), Vector3(0.16, 0.14, 0.14), lamp)
	return s


## Warsaw's city buses, red below the windows and yellow above (the Rondo night photos,
## 2026-10-31; street photos at our stops, 2026-11-07): shape 0 the 18 m articulated bus, shape 1
## the 12 m solo bus that runs beside it on many lines (TRAFFIC's shares), one family in the BUS
## MultiMesh (+0 draw calls). A long dark window band (lit at night) with pillars, a big
## windscreen under a lit destination display, doors on the right, the air-conditioning box on the
## roof. The articulated bus: a front section (z -9 to 3), the black bellows (3 to 3.7) and a rear
## section (3.7 to 9) on its own axle, three doors (the rear one behind the bellows, clear of the
## axle). The solo bus: the front section alone (z -6 to 6) with its axles where a 12 m bus has
## them, a third door behind the rear axle, its own tail lamps and back window; the rear section's
## and the bellows' parts collapse out of sight. Its length is TRAFFIC's size.z (traffic.gd's
## LENGTH keeps the longest).
static func bus_mesh() -> ArrayMesh:
	return family([bus_shape(BUS_ARTIC), bus_shape(BUS_SOLO), bus_shape(BUS_FIRE)])


## The BUS family's shapes: the articulated bus, the solo bus and (road life stage 3) the fire
## engine, which hides every bus part (shrunk to a point by Shape.xform) and adds its own.
const BUS_ARTIC := 0
const BUS_SOLO := 1
const BUS_FIRE := 2
const FIRE_RED := Color("#c4161c")
## A Shape.xform that shrinks what follows to one point (a part this shape doesn't have, even one
## whose builder calls show() on its way).
static func gone(at: Vector3) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ZERO), at)


## One of the buses (bus_mesh) as a Shape, so traffic.gd's night signs can join it.
static func bus_shape(which: int) -> Shape:
	var solo := which == BUS_SOLO
	var fire := which == BUS_FIRE
	# The fire engine has none of the bus: every bus part goes to one point.
	var none := gone(Vector3(0.0, 1.5, 0.0)) if fire else Transform3D.IDENTITY
	var s := Shape.new()
	var red := fin(Color("#c8282a"))
	var yellow := fin(Color("#f2c12e"))
	var W := 1.25
	s.xform = none * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0 if solo or fire else -3.0))
	var lower := PackedVector2Array([Vector2(-5.96, 0.36), Vector2(-6.0, 0.6), Vector2(-5.98, 1.0),
			Vector2(-5.96, 1.04), Vector2(5.97, 1.15), Vector2(5.99, 1.15), Vector2(6.0, 0.6), Vector2(5.96, 0.36)])
	var lw := PackedFloat32Array([W, W, W, W, W, W, W, W])
	s.loft(lower, lw, [red, red, red, red, red, red, red, null], red)
	var house := PackedVector2Array([Vector2(-5.96, 1.04), Vector2(-5.82, 2.98), Vector2(5.97, 2.98), Vector2(5.97, 1.15)])
	var hw := PackedFloat32Array([W, W - 0.03, W - 0.03, W])
	s.loft(house, hw, [yellow, yellow, yellow, null], yellow)
	var glass := fin(GLASS, LIT_WINDOW)
	s.pane(s.edge_face(house, hw, 0), 0.04, 0.96, 0.03, 0.8, fin(GLASS))
	s.pane(s.edge_face(house, hw, 0), 0.12, 0.88, 0.84, 0.96, fin(Color("#f0c674"), LIT_SIGN))
	var bands := [Vector2(0.01, 0.12), Vector2(0.14, 0.33), Vector2(0.35, 0.52), Vector2(0.54, 0.73), Vector2(0.75, 0.96)]
	for sgn: float in [-1.0, 1.0]:
		var side := s.side_face(house, hw, sgn)
		for b: Vector2 in bands:
			s.pane(side, b.x, b.y, 0.28, 0.82, glass)
	# Doors on the right (+x): the front one ahead of the front axle and one mid-section.
	for z: float in [-5.0, -0.6]:
		s.side_rect(W + 0.014, 1.0, 0.42, 2.6, z - 0.6, z + 0.6, fin(Color("#2d3640")))
	s.box(Vector3(0.0, 3.12, 1.0), Vector3(1.7, 0.28, 3.2), fin(Color("#d9d4c8")))
	var nose := s.edge_face(lower, lw, 1)
	s.pane(nose, 0.05, 0.22, 0.25, 0.85, fin(HEADLIGHT, HEAD_LAMP))
	s.pane(nose, 0.78, 0.95, 0.25, 0.85, fin(HEADLIGHT, HEAD_LAMP))
	s.box(Vector3(0.0, 0.3, -5.92), Vector3(2.54, 0.2, 0.2), fin(TRIM))
	# The section's back end: tail lamps and a back window (the solo bus's own; on the
	# articulated bus they sit inside the bellows).
	var tail := s.edge_face(lower, lw, 5)
	s.pane(tail, 0.04, 0.18, 0.1, 0.9, fin(TAIL, TAIL_LAMP))
	s.pane(tail, 0.82, 0.96, 0.1, 0.9, fin(TAIL, TAIL_LAMP))
	s.pane(s.edge_face(house, hw, 2), 0.1, 0.9, 0.12, 0.5, fin(GLASS))
	var r := 0.48
	var wc := r * cos(PI / 6.0)
	# A 12 m bus's axles: 2.7 m behind its front, 3.4 m ahead of its back.
	for z: float in ([-3.3, 2.6] if solo else [-3.9, 3.4]):
		for sgn: float in [-1.0, 1.0]:
			s.arch(sgn * (W + 0.006), sgn, z, wc, r + 0.08, 0.36, fin(WELL))
			s.wheel(Vector3(sgn * (W + 0.02 - 0.15), wc, z), r, 0.3, 6, sgn, fin(TYRE), fin(HUB))
	# The third door: behind the solo bus's rear axle, or behind the articulated bus's bellows.
	s.xform = none
	var d3 := 4.25 if solo else 4.8
	s.side_rect(W + 0.014, 1.0, 0.42, 2.6, d3 - 0.6, d3 + 0.6, fin(Color("#2d3640")))
	# The rear section: its own lower and upper bodies with square ends, an axle.
	s.keep_if(not solo, Vector3(0.0, 1.5, 0.0))
	var rl := PackedVector2Array([Vector2(3.7, 0.36), Vector2(3.7, 1.15), Vector2(8.97, 1.15), Vector2(9.0, 0.6),
			Vector2(8.96, 0.36)])
	var rlw := PackedFloat32Array([W, W, W, W, W])
	s.loft(rl, rlw, [red, red, red, red, null], red)
	var rh := PackedVector2Array([Vector2(3.7, 1.15), Vector2(3.7, 2.98), Vector2(9.0, 2.98), Vector2(9.0, 1.15)])
	var rhw := PackedFloat32Array([W - 0.03, W - 0.03, W - 0.03, W - 0.03])
	s.loft(rh, rhw, [yellow, yellow, yellow, null], yellow)
	var rb := [Vector2(0.02, 0.2), Vector2(0.24, 0.46), Vector2(0.5, 0.72), Vector2(0.76, 0.97)]
	for sgn: float in [-1.0, 1.0]:
		var rside := s.side_face(rh, rhw, sgn)
		for b: Vector2 in rb:
			s.pane(rside, b.x, b.y, 0.28, 0.82, glass)
	var back := s.edge_face(rl, rlw, 2)
	s.pane(back, 0.04, 0.18, 0.1, 0.7, fin(TAIL, TAIL_LAMP))
	s.pane(back, 0.82, 0.96, 0.1, 0.7, fin(TAIL, TAIL_LAMP))
	s.pane(s.edge_face(rh, rhw, 2), 0.1, 0.9, 0.12, 0.5, fin(GLASS))
	s.box(Vector3(0.0, 0.3, 8.92), Vector3(2.54, 0.2, 0.2), fin(TRIM))
	for sgn: float in [-1.0, 1.0]:
		s.arch(sgn * (W + 0.006), sgn, 7.4, wc, r + 0.08, 0.36, fin(WELL))
		s.wheel(Vector3(sgn * (W + 0.02 - 0.15), wc, 7.4), r, 0.3, 6, sgn, fin(TYRE), fin(HUB))
	# The articulation: black bellows, a turntable plate and a roof cover across the gap.
	var bellows := fin(Color("#1c1d20"))
	s.box(Vector3(0.0, 1.95, 3.35), Vector3(2.3, 2.1, 0.8), bellows)
	s.box(Vector3(0.0, 0.62, 3.35), Vector3(2.3, 0.5, 0.8), fin(TRIM))
	s.show()
	s.xform = Transform3D.IDENTITY if fire else gone(Vector3(0.0, 1.5, 0.0))
	_fire_engine(s)
	s.xform = Transform3D.IDENTITY
	s.show()
	return s


## The fire engine (straż pożarna; a Polish GBA-style truck, no badge): 8.4 m, a red cab with a big
## windscreen and a white band, a red body with grey roller-shutter lockers on both sides, a silver
## ladder on the roof, a blue light bar on the cab and two blue beacons at the back (BLINK: with
## traffic.gd's lights on they flash as the police's do), headlamps, tail lamps, six wheels.
## Its front is -z.
static func _fire_engine(s: Shape) -> void:
	var red := fin(FIRE_RED)
	var white := fin(Color("#f2f2ee"))
	var W := 1.25
	# The cab and the body (the bottoms nobody sees), the chassis under them.
	s.box(Vector3(0.0, 0.95, -3.2), Vector3(2.5, 1.0, 2.0), red)
	s.box(Vector3(0.0, 2.2, -3.25), Vector3(2.46, 1.5, 1.9), red)
	s.box(Vector3(0.0, 1.85, 0.95), Vector3(2.5, 2.7, 6.5), red)
	s.box(Vector3(0.0, 0.45, 0.4), Vector3(2.2, 0.3, 7.4), fin(TRIM))
	# The cab's glass: the windscreen, a side window each side; the white band all round.
	s.quad(Vector3(-1.08, 1.62, -4.206), Vector3(1.08, 1.62, -4.206), Vector3(1.08, 2.78, -4.206),
			Vector3(-1.08, 2.78, -4.206), fin(GLASS), Vector3(0, 0, -1))
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W - 0.015), sgn, 1.72, 2.7, -4.05, -3.05, fin(GLASS))
		s.side_rect(sgn * (W + 0.006), sgn, 1.18, 1.36, -4.18, 4.18, white)
	s.quad(Vector3(-1.25, 1.18, -4.21), Vector3(1.25, 1.18, -4.21), Vector3(1.25, 1.36, -4.21),
			Vector3(-1.25, 1.36, -4.21), white, Vector3(0, 0, -1))
	# The lockers: three roller shutters a side, darker lines across them.
	var shutter := fin(Color("#b9bdc2"))
	var line := fin(Color("#8d9298"))
	for sgn: float in [-1.0, 1.0]:
		for z: Vector2 in [Vector2(-2.1, -0.25), Vector2(-0.05, 1.8), Vector2(2.0, 3.95)]:
			s.side_rect(sgn * (W + 0.012), sgn, 1.48, 3.0, z.x, z.y, shutter)
			for y: float in [1.9, 2.3, 2.7]:
				s.side_rect(sgn * (W + 0.018), sgn, y, y + 0.04, z.x, z.y, line)
	# The ladder: two rails and rungs on the roof, on two low stands.
	var alu := fin(Color("#c9ccd1"))
	for x: float in [-0.45, 0.45]:
		s.box(Vector3(x, 3.36, 1.0), Vector3(0.08, 0.08, 5.8), alu)
	for k in 9:
		s.box(Vector3(0.0, 3.36, -1.8 + k * 0.7), Vector3(0.9, 0.05, 0.06), alu)
	for z: float in [-1.4, 3.4]:
		s.box(Vector3(0.0, 3.26, z), Vector3(1.1, 0.12, 0.14), fin(TRIM))
	# The light bar on the cab's roof and the beacons at the back's top corners (blue, flashing).
	var blue := Color("#3d7bff")
	s.box(Vector3(0.0, 3.0, -3.6), Vector3(1.7, 0.08, 0.3), fin(TRIM))
	s.box(Vector3(-0.45, 3.1, -3.6), Vector3(0.7, 0.12, 0.26), fin(blue, BLINK, 0.0))
	s.box(Vector3(0.45, 3.1, -3.6), Vector3(0.7, 0.12, 0.26), fin(blue, BLINK, 0.5))
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * 1.05, 3.28, 4.05), Vector3(0.2, 0.16, 0.2), fin(blue, BLINK, 0.0 if sgn < 0.0 else 0.5))
	# The front: grille, headlamps, bumper; the back: tail lamps and its bumper.
	s.quad(Vector3(-0.62, 0.78, -4.208), Vector3(0.62, 0.78, -4.208), Vector3(0.62, 1.1, -4.208),
			Vector3(-0.62, 1.1, -4.208), fin(GRILLE), Vector3(0, 0, -1))
	for x: float in [-0.95, 0.95]:
		s.quad(Vector3(x - 0.2, 0.72, -4.209), Vector3(x + 0.2, 0.72, -4.209), Vector3(x + 0.2, 0.95, -4.209),
				Vector3(x - 0.2, 0.95, -4.209), fin(HEADLIGHT, HEAD_LAMP), Vector3(0, 0, -1))
		s.quad(Vector3(x - 0.18, 0.7, 4.205), Vector3(x + 0.18, 0.7, 4.205), Vector3(x + 0.18, 1.0, 4.205),
				Vector3(x - 0.18, 1.0, 4.205), fin(TAIL, TAIL_LAMP), Vector3(0, 0, 1))
	s.box(Vector3(0.0, 0.48, -4.28), Vector3(2.55, 0.26, 0.18), fin(TRIM))
	s.box(Vector3(0.0, 0.48, 4.25), Vector3(2.5, 0.22, 0.14), fin(TRIM))
	# The wheels: one axle under the cab, two at the back.
	var r := 0.5
	var wc := r * cos(PI / 6.0)
	for z: float in [-2.9, 2.0, 3.25]:
		for sgn: float in [-1.0, 1.0]:
			s.arch(sgn * (W + 0.006), sgn, z, wc, r + 0.08, 0.5, fin(WELL))
			s.wheel(Vector3(sgn * (W + 0.02 - 0.15), wc, z), r, 0.3, 6, sgn, fin(TYRE), fin(HUB))


## Loop 2c, for loop 3g: the police estate and the city guards' car in one family (police.md
## section 9): shape 0 the patrol car, a silver Toyota-Auris-style estate (its paint,
## POLICE_SILVER) in the real Polish livery: a blue band on the doors with "POLICJA" in the pixel
## font (readable only zoomed in), a blue-and-silver checker strip above and below it, a blue
## bonnet panel and a light bar whose blue and red lamps blink in turns (BLINK); shape 1 the
## guards' car, the same estate at 0.88 scale, mustard (GUARD_MUSTARD) with a dark red band and
## two amber lamps; shape 3 the patrol van, a silver VW-Crafter-style panel van (the "suka") with
## the same band over a dark skirt, a black mesh window behind the cab, a low front bar and two
## rear beacons.
## The crash scenes (crash_scenes.gd, 2026-11-01): shape 2 the ambulance (karetka), the panel
## van in AMBULANCE_YELLOW with a red band, "AMBULANS" in red above it and two blue lamps, so the
## scene's ambulance rides in the POLICE MultiMesh with the patrol car (+0 draw calls).
static func police_mesh() -> ArrayMesh:
	return family([_police(0), _police(1), _police(2), _police(3)])


## Shape `which` of the police family: 0 the patrol estate, 1 the guards' car, 2 the ambulance,
## 3 the patrol van. Every shape adds the same parts in the same order (family() morphs
## between them); a part another shape owns is hidden.
static func _police(which: int) -> Shape:
	var guard := which == 1
	var amb := which == 2
	var van := which == 3
	var liv := which == 0 or van
	var s := Shape.new()
	if guard:
		s.xform = Transform3D(Basis.from_scale(Vector3.ONE * 0.88), Vector3.ZERO)
	var p := spec("panel van" if (amb or van) else "estate")
	if not (amb or van):
		p.merge({"L": 4.7, "rails": false}, true)
	_vehicle(s, p, fin(Color.WHITE, PAINT))
	var W: float = p["W"]
	var L: float = p["L"]
	var roof_y: float = p["roof_y"]
	var bar := Vector3(0.0, roof_y + 0.04, -0.7 if van else -0.05)
	var mid := Vector3(0.0, roof_y - 0.2, 0.3)
	# The doors' band: from behind the front arch to before the rear one (the van's runs
	# nearly the whole side, higher up).
	var z0: float = p["axle_f"] + 0.42
	var z1: float = p["axle_r"] - 0.42
	var y0 := 0.44
	var y1 := 0.88
	if van:
		z0 = -L * 0.5 + 0.3
		z1 = L * 0.5 - 0.1
		y0 = 0.82
		y1 = 1.26
	var blue := fin(Color("#1f4fd8"))
	s.keep_if(liv, mid)
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.01), sgn, y0, y1, z0, z1, blue)
	# The van's dark lower skirt and the black mesh window behind the cab.
	s.keep_if(van, mid)
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.008), sgn, 0.44, 0.8, z0 + 0.2, z1 - 0.1, fin(Color("#2a2d33")))
		s.side_rect(sgn * (W + 0.008), sgn, 1.5, 2.08, -0.15, 1.75, fin(Color("#1d2025")))
	# The checker strip (szachownica) above and below the band: every other square blue.
	s.keep_if(liv, mid)
	var squares := 16
	for sgn: float in [-1.0, 1.0]:
		for ys: Vector2 in [Vector2(y1 + 0.02, y1 + 0.08), Vector2(y0 - 0.08, y0 - 0.02)]:
			for k in squares:
				if k % 2 == 1:
					continue
				var za := lerpf(z0, z1, float(k) / squares)
				var zb := lerpf(z0, z1, float(k + 1) / squares)
				s.side_rect(sgn * (W + 0.012), sgn, ys.x, ys.y, za, zb, blue)
	# The estate's blue bonnet panel (the real car's POLICJA bonnet).
	var lower := _lower(p)
	var lw := _widths(lower, W)
	s.keep_if(which == 0, mid)
	s.pane(s.edge_face(lower, lw, 2), 0.14, 0.86, 0.16, 0.86, blue)
	s.keep_if(guard, mid)
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.01), sgn, y0 + 0.08, y1 - 0.08, z0, z1, fin(Color("#7a2430")))
	# The ambulance's red band, low along the whole side between the arches.
	s.keep_if(amb, mid)
	for sgn: float in [-1.0, 1.0]:
		s.side_rect(sgn * (W + 0.01), sgn, 0.46, 0.6, z0 - 0.3, z1 + 0.3, fin(AMBULANCE_RED))
	# The light bar: a dark base, then the police's two lenses, the guards' one, the ambulance's.
	s.show()
	s.box(bar, Vector3(1.36, 0.07, 0.28), fin(GRILLE))
	s.keep_if(liv, mid)
	s.box(bar + Vector3(-0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#3d7bff"), BLINK, 0.0))
	s.box(bar + Vector3(0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#ff3b3b"), BLINK, 0.5))
	# The van's two rear beacons, blue, in turns.
	s.keep_if(van, mid)
	for sgn: float in [-1.0, 1.0]:
		s.box(Vector3(sgn * 0.8, roof_y + 0.1, 2.3), Vector3(0.14, 0.18, 0.14),
				fin(Color("#3d7bff"), BLINK, 0.0 if sgn < 0.0 else 0.5))
	# The guards' bar: two amber lamps, in one beat (a light bar, not a taxi's sign).
	s.keep_if(guard, mid)
	s.box(bar + Vector3(-0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#ffb21e"), BLINK, 0.0))
	s.box(bar + Vector3(0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#ffb21e"), BLINK, 0.0))
	# The ambulance's bar: two blue lamps taking turns.
	s.keep_if(amb, mid)
	s.box(bar + Vector3(-0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#3d7bff"), BLINK, 0.0))
	s.box(bar + Vector3(0.35, 0.08, 0.0), Vector3(0.6, 0.1, 0.24), fin(Color("#3d7bff"), BLINK, 0.5))
	# POLICJA on the band, both sides reading from the front of the letters (left side front
	# to back, right side back to front), 5 cm pixels.
	s.keep_if(liv, mid)
	_side_text(s, "POLICJA", W, (z0 + z1) * 0.5, (y0 + y1) * 0.5, fin(POLICE_WHITE))
	# AMBULANS in red above the ambulance's band, on the box behind the cab.
	s.keep_if(amb, mid)
	_side_text(s, "AMBULANS", W, (z0 + z1) * 0.5 + 0.3, 0.84, fin(AMBULANCE_RED))
	s.show()
	return s


## `text` in the pixel font (5 cm pixels) on both sides of a body of half-width W, centred at
## (zc, yc), reading from the front of the letters on each side.
static func _side_text(s: Shape, text: String, W: float, zc: float, yc: float, f: Array) -> void:
	var px := 0.05
	var wide := PixelFont.width(text) * px
	for sgn: float in [-1.0, 1.0]:
		# Seen from +x the text runs towards -z, from -x towards +z.
		var x := sgn * (W + 0.02)
		var start := zc + sgn * wide * 0.5
		var top := yc + 3.5 * px + PixelFont.BODY * px
		PixelFont.each_pixel(text, 0, func(col: int, row: int) -> void:
			var za := start - sgn * col * px
			var zb := za - sgn * px
			var yt := top - row * px
			s.side_rect(x, sgn, yt - px, yt, minf(za, zb), maxf(za, zb), f))


## Loop 2c: the parked cars' mesh (map_builder.gd, and main.gd for a city.scn baked before
## it): a small saloon in the new shape with few triangles (hundreds are in view; ~40 each,
## today's was 24). Plain vertex colours (foliage.gdshader multiplies them by the instance's
## paint): a white body, PARKED_GLASS glass, dark wheels.
static func parked_mesh() -> ArrayMesh:
	var s := Shape.new()
	var body := fin(Color.WHITE)
	var glass := fin(PARKED_GLASS)
	var lower := PackedVector2Array([Vector2(-2.08, 0.3), Vector2(-2.1, 0.6), Vector2(-1.94, 0.8),
			Vector2(-0.82, 0.93), Vector2(1.42, 0.96), Vector2(2.04, 0.92), Vector2(2.1, 0.32)])
	var lw := PackedFloat32Array([0.87, 0.87, 0.87, 0.87, 0.87, 0.87, 0.87])
	s.loft(lower, lw, [body, body, body, body, body, body, null], body)
	var house := PackedVector2Array([Vector2(-0.82, 0.93), Vector2(-0.12, 1.4), Vector2(1.18, 1.41), Vector2(1.42, 0.96)])
	var hw := PackedFloat32Array([0.83, 0.68, 0.68, 0.83])
	s.loft(house, hw, [glass, body, glass, null], glass)
	for z: float in [-1.35, 1.3]:
		for sgn: float in [-1.0, 1.0]:
			s.side_rect(sgn * 0.885, sgn, 0.0, 0.42, z - 0.32, z + 0.32, fin(TYRE))
	return s.mesh()


## Loop 2c: gives a prebuilt city's parked cars (city.scn, baked before loop 2c) this mesh:
## they all share one mesh resource, so its surface is replaced in place. Parked cars are
## the MultiMeshes drawn with the foliage material at sway 0.
static func renew_parked(nodes: Array[Node]) -> bool:
	for n in nodes:
		var mmi := n as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null or not mmi.material_override is ShaderMaterial:
			continue
		var mat := mmi.material_override as ShaderMaterial
		if mat.shader == null or not mat.shader.resource_path.ends_with("foliage.gdshader"):
			continue
		var sway: Variant = mat.get_shader_parameter("sway")
		if sway == null or float(sway) != 0.0:
			continue
		var old := mmi.multimesh.mesh as ArrayMesh
		if old == null:
			continue
		var fresh := parked_mesh()
		old.clear_surfaces()
		old.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fresh.surface_get_arrays(0))
		return true
	return false


## Loop 2c: the player's hatchback (car.gd): [body, head lamps, tail lamps] (three draw
## calls). The body takes `paint` and `stripes` (the hero part and its glow) and keeps its
## twin white stripes over the bonnet, the roof and the tailgate; black bumpers, a roof
## spoiler, round head lamps and light hub caps make it the one retro hot hatch in town.
## G13: `kind` "player" (the hatch) or "player_tt" (the shop's coupe, no roof spoiler); C1b: the
## meme cars "player_lanos", "player_bolonez", "player_paszat", "player_szupra" and "player_bawarka"
## (car.gd BODIES) wear their own kit (`_player_kit`) and lamps instead of the twin stripes; the
## Bawarka keeps Darek's silver and blue whatever the paint.
## `wing` (F 2026-11-24, bought at Mirek's: upgrades.gd LOOKS "wing"): a GT wing on two struts, its
## plate in the stripes' colour, in the body's one mesh (no new draw call).
## The shop's cars (upgrades.gd CARS ids) and their bodies here (car.gd, the garage's stage).
const PLAYER_BODIES := {"hatch": "player", "tt": "player_tt", "lanos": "player_lanos", "bolonez": "player_bolonez",
		"paszat": "player_paszat", "szupra": "player_szupra", "bawarka": "player_bawarka", "mjata": "player_mjata"}
static func player_meshes(paint: Array, stripes: Array, kind := "player", wing := false) -> Array[ArrayMesh]:
	if kind == "player_bike":
		return player_bike_meshes(paint, stripes)
	if SCULPT.has(kind):
		return _sculpt_meshes(kind, paint, stripes, wing)
	var s := Shape.new()
	var p := spec(kind)
	var classic := kind in ["player", "player_tt"]
	# The Bawarka wears Darek's own livery whatever paint is on the other cars: silver over a deep
	# blue (our own pattern, not any game's), its glow as the silver paint's.
	var blue := fin(Color("#1d3f8f"), HERO, 0.4)
	var sky := fin(Color("#5aa8e6"), HERO, 0.6)
	if kind == "player_bawarka":
		paint = fin(Color("#9aa3ae"), HERO, 1.1)
	var glass_c := Color("#2f3f52")
	_vehicle(s, p, paint, [], fin(glass_c), false)
	var lower := _lower(p)
	var W: float = p["W"]
	var L: float = p["L"]
	var lw := _widths(lower, W)
	var house := PackedVector2Array([Vector2(p["cowl_z"], p["cowl_y"]), Vector2(p["roof_z0"], p["roof_y"]),
			Vector2(p["roof_z1"], p["roof_y"]), Vector2(p["belt_z"], p["belt_y"])])
	var hw := PackedFloat32Array([p["gw0"], p["gw1"], p["gw1"], p["gw0"]])
	var gw1: float = p["gw1"]
	var roof_y: float = p["roof_y"]
	var tail_y: float = p["tail_y"]
	var tail_z: float = L * 0.5 - float(p["tail_in"])
	var r: float = p["r"]
	var trim := fin(TRIM)
	var black := fin(Color("#1c1d21"))
	if classic:
		# Twin stripes, 0.3 m wide either side of the middle: the bonnet, the roof, the tailgate.
		var stripe_x := [Vector2(0.1, 0.4), Vector2(-0.4, -0.1)]
		for face: Array in [s.edge_face(lower, lw, 2), s.edge_face(lower, lw, 4), s.edge_face(lower, lw, 5)]:
			for sx: Vector2 in stripe_x:
				s.pane(face, (sx.x + W) / (2.0 * W), (sx.y + W) / (2.0 * W), 0.0, 1.0, stripes, 0.01)
		var top := s.edge_face(house, hw, 1)
		for sx: Vector2 in stripe_x:
			s.pane(top, (sx.x + gw1) / (2.0 * gw1), (sx.y + gw1) / (2.0 * gw1), 0.0, 1.0, stripes, 0.01)
		var nose := s.edge_face(lower, lw, 1)
		for sx: Vector2 in stripe_x:
			s.pane(nose, (sx.x + W) / (2.0 * W), (sx.y + W) / (2.0 * W), 0.0, 1.0, stripes, 0.01)
		# A roof spoiler over the tailgate (no mirrors: at the 80 m view they'd be one pixel).
		if kind == "player":
			s.box(Vector3(0.0, roof_y - 0.01, p["roof_z1"] + 0.1), Vector3(1.3, 0.06, 0.3), trim)
		else:
			# The coupe's spoiler is a thin lip on the boot lid instead.
			s.box(Vector3(0.0, tail_y + 0.04, tail_z - 0.12), Vector3(1.5, 0.05, 0.22), trim)
			# F 2026-11-27 ("the TT must be there, nice models"): the round arches bulging out of the
			# flanks (a half-ring of paint over each wheel) and the polished round fuel cap.
			var rr: float = float(p["r"]) + 0.1
			var wy0: float = float(p["r"]) * cos(PI / 8.0)
			for z: float in [p["axle_f"], p["axle_r"]]:
				for sgn: float in [-1.0, 1.0]:
					for k in 5:
						var a := lerpf(0.15, PI - 0.15, (k + 0.5) / 5.0)
						s.box(Vector3(sgn * (W + 0.02), wy0 + sin(a) * rr, z + cos(a) * rr), Vector3(0.05, 0.1, 0.16), paint)
			var cap_at := Vector3(W + 0.035, float(p["belt_y"]) - 0.16, float(p["axle_r"]) - 0.05)
			s.box(cap_at, Vector3(0.02, 0.13, 0.13), fin(Color("#d4d7dc")))
	# The bought GT wing: on the hatch over the tailgate's top, on the others over the boot lid;
	# the Szupra and the Bawarka keep their own wings.
	if wing and kind not in ["player_szupra", "player_bawarka"]:
		var hatchy := kind in ["player", "player_bolonez", "player_paszat"]
		var wy: float = roof_y + 0.28 if hatchy else tail_y + 0.42
		var wz: float = float(p["roof_z1"]) + 0.02 if hatchy else tail_z - 0.3
		var foot: float = roof_y if hatchy else tail_y
		var span := W * 2.0 + 0.16
		for sgn: float in [-1.0, 1.0]:
			s.box(Vector3(sgn * 0.5, (foot + wy) * 0.5, wz), Vector3(0.07, wy - foot, 0.14), trim)
			s.box(Vector3(sgn * span * 0.5, wy + 0.06, wz), Vector3(0.04, 0.24, 0.5), trim)
		s.box(Vector3(0.0, wy + 0.03, wz), Vector3(span, 0.06, 0.46), stripes)
	# Hub caps over the plain wheels: light retro steel on the hatch and most, black steelies on the
	# Paszat, dark five-spoke race rims on the Szupra and the Bawarka.
	var cap := Color("#d8dadc")
	match kind:
		"player_paszat":
			cap = Color("#232427")
		"player_szupra":
			cap = Color("#b9bcc2")
		"player_bawarka":
			cap = Color("#3b3e45")
		"player_lanos":
			cap = Color("#a9adb3")
	var wc := r * cos(PI / 8.0)
	for z: float in [p["axle_f"], p["axle_r"]]:
		for sgn: float in [-1.0, 1.0]:
			var x := sgn * (W + 0.02 + 0.016)
			var ring: Array[Vector3] = []
			var cap_r := r * (0.62 if kind in ["player_szupra", "player_bawarka"] else 0.42)
			for k in 8:
				var a := TAU * (k + 0.5) / 8.0
				ring.append(Vector3(x, wc + sin(a) * cap_r, z + cos(a) * cap_r))
			for k in range(1, 7):
				s.tri(ring[0], ring[k], ring[k + 1], fin(cap), Vector3(sgn, 0, 0))
			if kind in ["player_szupra", "player_bawarka"]:
				# The rim's centre nut, so the big rim reads as a wheel and not a disc.
				s.box(Vector3(x + sgn * 0.01, wc, z), Vector3(0.02, 0.09, 0.09), fin(Color("#16171a")))
	var body := s.mesh()
	return [body, _player_heads(kind, lower, lw, W), _player_tails(kind, p, lower, lw, W)]


## The head lamps for `kind`: round octagons on the hatch and the TT, flat panes on the rest (their
## shapes are each car's face).
static func _player_heads(kind: String, lower: PackedVector2Array, lw: PackedFloat32Array, W: float) -> ArrayMesh:
	var heads := Shape.new()
	var face := heads.edge_face(lower, lw, 1)
	if kind in ["player", "player_tt"]:
		for sgn: float in [-1.0, 1.0]:
			var c := Vector3(sgn * 0.6, 0.0, 0.0)
			var c0: Vector3 = face[0]
			var c1: Vector3 = face[1]
			var c2: Vector3 = face[2]
			var c3: Vector3 = face[3]
			var u := (c.x + W) / (2.0 * W)
			var centre: Vector3 = c0.lerp(c1, u).lerp(c3.lerp(c2, u), 0.55)
			var n: Vector3 = (c1 - c0).cross(c3 - c0).normalized()
			if n.dot(Vector3(0, 0, -1)) < 0.0:
				n = -n
			var up := (c3 - c0).normalized()
			var right := Vector3.RIGHT
			var ring: Array[Vector3] = []
			for k in 8:
				var a := TAU * (k + 0.5) / 8.0
				ring.append(centre + n * 0.02 + right * cos(a) * 0.15 + up * sin(a) * 0.15)
			for k in range(1, 7):
				heads.tri(ring[0], ring[k], ring[k + 1], fin(Color.WHITE), n)
		return heads.mesh()
	# [u0, u1, v0, v1] of the left lamp on the nose (the right one mirrored).
	var box: Array = {"player_lanos": [0.05, 0.3, 0.35, 0.9], "player_bolonez": [0.04, 0.3, 0.3, 0.85],
			"player_paszat": [0.04, 0.3, 0.4, 0.92], "player_szupra": [0.04, 0.24, 0.55, 0.85],
			"player_bawarka": [0.05, 0.28, 0.5, 0.88]}.get(kind, [0.05, 0.27, 0.3, 0.9])
	for mirror: bool in [false, true]:
		var u0: float = 1.0 - float(box[1]) if mirror else float(box[0])
		var u1: float = 1.0 - float(box[0]) if mirror else float(box[1])
		if kind == "player_bawarka":
			# Two lamps a side in one housing (a twin-lamp face, no grille copied).
			var mid := (u0 + u1) * 0.5
			heads.pane(face, u0, mid - 0.01, box[2], box[3], fin(Color.WHITE), 0.02)
			heads.pane(face, mid + 0.01, u1, box[2], box[3], fin(Color.WHITE), 0.02)
		else:
			heads.pane(face, u0, u1, box[2], box[3], fin(Color.WHITE), 0.02)
	return heads.mesh()


## The tail lamps for `kind`, on the back and wrapping over the rear deck so the camera above sees
## them; the Szupra's are two round lamps a side.
static func _player_tails(kind: String, p: Dictionary, lower: PackedVector2Array, lw: PackedFloat32Array, W: float) -> ArrayMesh:
	var tails := Shape.new()
	var back := tails.edge_face(lower, lw, 5)
	var deck := tails.edge_face(lower, lw, 4)
	match kind:
		"player_szupra":
			var c0: Vector3 = back[0]
			var c1: Vector3 = back[1]
			var c2: Vector3 = back[2]
			var c3: Vector3 = back[3]
			var n := Vector3(0, 0, 1)
			var up := (c3 - c0).normalized()
			for u: float in [0.1, 0.25, 0.75, 0.9]:
				var centre: Vector3 = c0.lerp(c1, u).lerp(c3.lerp(c2, u), 0.5) + n * 0.02
				var ring: Array[Vector3] = []
				for k in 8:
					var a := TAU * (k + 0.5) / 8.0
					ring.append(centre + Vector3.RIGHT * cos(a) * 0.1 + up * sin(a) * 0.1)
				for k in range(1, 7):
					tails.tri(ring[0], ring[k], ring[k + 1], fin(Color.WHITE), n)
			tails.pane(deck, 0.05, 0.95, 0.9, 1.0, fin(Color.WHITE), 0.02)
		"player_bolonez", "player_paszat":
			# Tall lamps up the tailgate's sides (a hatch's and an estate's).
			tails.pane(back, 0.02, 0.2, 0.05, 0.9, fin(Color.WHITE), 0.02)
			tails.pane(back, 0.8, 0.98, 0.05, 0.9, fin(Color.WHITE), 0.02)
			tails.pane(deck, 0.02, 0.2, 0.75, 1.0, fin(Color.WHITE), 0.02)
			tails.pane(deck, 0.8, 0.98, 0.75, 1.0, fin(Color.WHITE), 0.02)
		_:
			tails.pane(back, 0.03, 0.3 if kind == "player_bawarka" else 0.26, 0.2, 0.75, fin(Color.WHITE), 0.02)
			tails.pane(back, 0.7 if kind == "player_bawarka" else 0.74, 0.97, 0.2, 0.75, fin(Color.WHITE), 0.02)
			tails.pane(deck, 0.03, 0.26, 0.72, 1.0, fin(Color.WHITE), 0.02)
			tails.pane(deck, 0.74, 0.97, 0.72, 1.0, fin(Color.WHITE), 0.02)
	return tails.mesh()


## The coffee run (coffee_run.gd): the player on a ROWERILO city bike, [body, head lamp, tail
## lamp] like the cars (three draw calls, the same material). Facing -Z, the rider's shirt is the
## hero paint (lit from within at night like the car), the helmet the stripes. The bike is drawn
## 1.6x life size: at the 80 m view a true 1.8 m bike is a few pixels, and the joke needs reading.
static func player_bike_meshes(paint: Array, stripes: Array) -> Array[ArrayMesh]:
	var k := 1.6
	var s := Shape.new()
	var tyre := fin(TYRE)
	var cream := fin(Color("#efe6cf"))
	var grey := fin(Color("#8a8d91"))
	var skin := fin(Color("#e2b48c"))
	var jeans := fin(Color("#33415c"))
	var black := fin(Color("#202024"))
	# Wheels: dark discs with light hubs, the cream step-through frame, mudguards, the basket.
	for z: float in [-0.55, 0.55]:
		s.box(Vector3(0, 0.34, z) * k, Vector3(0.07, 0.68, 0.68) * k, tyre)
		s.box(Vector3(0, 0.34, z) * k, Vector3(0.09, 0.18, 0.18) * k, grey)
		s.box(Vector3(0, 0.7, z) * k, Vector3(0.12, 0.04, 0.5) * k, cream)
	s.box(Vector3(0, 0.45, 0.0) * k, Vector3(0.07, 0.07, 1.0) * k, cream)
	s.box(Vector3(0, 0.62, -0.42) * k, Vector3(0.07, 0.5, 0.07) * k, cream)
	s.box(Vector3(0, 0.62, 0.2) * k, Vector3(0.07, 0.42, 0.07) * k, cream)
	s.box(Vector3(0, 0.88, -0.66) * k, Vector3(0.4, 0.26, 0.32) * k, grey)
	# A paper cup in the basket (the run's whole point) and the handlebar.
	s.box(Vector3(0.06, 1.06, -0.66) * k, Vector3(0.1, 0.14, 0.1) * k, fin(Color("#f4efe4")))
	s.box(Vector3(0.06, 1.14, -0.66) * k, Vector3(0.11, 0.03, 0.11) * k, fin(Color("#6b4a32")))
	s.box(Vector3(0, 1.02, -0.46) * k, Vector3(0.56, 0.04, 0.05) * k, black)
	s.box(Vector3(0, 0.9, 0.24) * k, Vector3(0.14, 0.05, 0.22) * k, black)
	# The rider: legs on the pedals, the shirt in the car's paint, arms to the bar, a helmet.
	s.box(Vector3(-0.11, 0.66, 0.06) * k, Vector3(0.14, 0.5, 0.16) * k, jeans)
	s.box(Vector3(0.11, 0.62, -0.04) * k, Vector3(0.14, 0.5, 0.16) * k, jeans)
	s.box(Vector3(0, 1.24, 0.12) * k, Vector3(0.44, 0.56, 0.28) * k, paint)
	for x: float in [-0.24, 0.24]:
		s.box(Vector3(x, 1.12, -0.17) * k, Vector3(0.1, 0.1, 0.5) * k, paint)
	s.box(Vector3(0, 1.64, 0.02) * k, Vector3(0.24, 0.24, 0.24) * k, skin)
	s.box(Vector3(0, 1.79, 0.04) * k, Vector3(0.3, 0.12, 0.34) * k, stripes)
	var body := s.mesh()
	var heads := Shape.new()
	heads.box(Vector3(0, 0.92, -0.83) * k, Vector3(0.12, 0.1, 0.04) * k, fin(Color.WHITE))
	var tails := Shape.new()
	tails.box(Vector3(0, 0.74, 0.82) * k, Vector3(0.12, 0.08, 0.04) * k, fin(Color.WHITE))
	return [body, heads.mesh(), tails.mesh()]


## The rivals' cars, one look each (style 0..5), all colours fixed (loop 2c: built from the
## same shapes as the traffic, none of them saturated red).
static func rival_mesh(style: int) -> ArrayMesh:
	var s := Shape.new()
	match style:
		0:  # Seba z Pragi: lowered purple coupe, a big wing, pink stripes
			var purple := fin(Color("#7b2fbf"))
			var p := spec("coupe")
			_vehicle(s, p, purple)
			var lower := _lower(p)
			var lw := _widths(lower, p["W"])
			var pink := fin(Color("#ff4fd8"))
			for face: Array in [s.edge_face(lower, lw, 2)]:
				for u: Vector2 in [Vector2(0.36, 0.45), Vector2(0.55, 0.64)]:
					s.pane(face, u.x, u.y, 0.0, 1.0, pink, 0.01)
			var tail_z: float = p["L"] * 0.5 - 0.3
			for x: float in [-0.7, 0.7]:
				s.box(Vector3(x, 1.02, tail_z), Vector3(0.08, 0.26, 0.1), fin(TYRE))
			s.box(Vector3(0.0, 1.16, tail_z + 0.04), Vector3(1.96, 0.06, 0.46), fin(Color("#1c1c1e")))
		1:  # Mordor Mike: grey company estate, dark glass, roof box
			var grey := fin(Color("#6d7480"))
			var p := spec("estate")
			_vehicle(s, p, grey, [], fin(Color("#1e2530")))
			s.box(Vector3(0.0, p["roof_y"] + 0.26, 0.55), Vector3(0.95, 0.36, 1.9), fin(Color("#202124")))
		2:  # Pani Halina: tiny mint two-tone hatch with a basket on the roof
			var p := spec("city car")
			_vehicle(s, p, fin(Color("#86d3b0")), fin(Color("#f4ead2")))
			var roof_y: float = p["roof_y"]
			s.box(Vector3(0.0, roof_y + 0.11, 0.35), Vector3(0.8, 0.22, 0.6), fin(Color("#c8a26a")))
			s.box(Vector3(0.18, roof_y + 0.26, 0.35), Vector3(0.24, 0.16, 0.24), fin(Color("#7fb24a")))
			s.box(Vector3(-0.16, roof_y + 0.25, 0.42), Vector3(0.22, 0.12, 0.16), fin(Color("#e8d9a8")))
		3:  # Słoik z Radomia: white van, a pickle-green stripe, mum's jars on the roof rack
			var p := spec("panel van")
			_vehicle(s, p, fin(Color("#f2f2ee")))
			var W: float = p["W"]
			for sgn: float in [-1.0, 1.0]:
				s.side_rect(sgn * (W + 0.01), sgn, 0.8, 1.0, -1.0, 2.5, fin(Color("#5a8f3c")))
			s.box(Vector3(0.0, 2.48, 0.6), Vector3(1.6, 0.06, 2.6), fin(TRIM))
			for k in 4:
				var jar := Vector3(-0.55 + k * 0.37, 2.67, 0.2 + (k % 2) * 0.6)
				s.box(jar, Vector3(0.24, 0.32, 0.24), fin(Color("#d9a441")))
				s.box(jar + Vector3(0, 0.19, 0), Vector3(0.26, 0.06, 0.26), fin(Color("#f0f0ea")))
		4:  # Taksiarz Zbyszek: long black saloon, yellow sign and chequer band
			var p := spec("saloon")
			p.merge({"L": 4.8, "axle_f": -1.5, "axle_r": 1.48}, true)
			_vehicle(s, p, fin(Color("#232428")))
			var W: float = p["W"]
			s.box(Vector3(0.0, p["roof_y"] + 0.13, 0.2), Vector3(0.8, 0.24, 0.34), fin(Color("#f3c72b"), LIT_SIGN))
			var y0: float = p["belt_y"] - 0.3
			var z0: float = p["axle_f"] + 0.42
			var z1: float = p["axle_r"] - 0.42
			for sgn: float in [-1.0, 1.0]:
				s.side_rect(sgn * (W + 0.01), sgn, y0, y0 + 0.17, z0, z1, fin(Color("#e8e4d8")))
				for k in 10:
					if k % 2 == 0:
						s.side_rect(sgn * (W + 0.018), sgn, y0 + 0.02, y0 + 0.15, lerpf(z0, z1, k / 10.0),
								lerpf(z0, z1, (k + 1) / 10.0), fin(Color("#f3c72b")))
		_:  # Bulwar Bartek: neon-green hatch, magenta wing, a speaker on the roof
			var p := spec("hatch")
			_vehicle(s, p, fin(Color("#7cff3a")))
			var roof_y: float = p["roof_y"]
			s.box(Vector3(0.0, roof_y + 0.18, 0.4), Vector3(0.7, 0.36, 0.5), fin(Color("#1c1c1e")))
			s.box(Vector3(0.0, roof_y + 0.18, 0.14), Vector3(0.36, 0.24, 0.02), fin(Color("#ff4fd8")))
			s.box(Vector3(0.0, roof_y + 0.01, p["roof_z1"] + 0.12), Vector3(1.6, 0.06, 0.36), fin(Color("#ff4fd8")))
	return s.mesh()


## The lower-body profile _vehicle() lofts for spec p (for laying panes on it).
static func _lower(p: Dictionary) -> PackedVector2Array:
	var hl: float = -p["L"] * 0.5
	return PackedVector2Array([Vector2(hl + 0.06, p["sill"]), Vector2(hl, p["bump_f"]),
			Vector2(hl + p["nose_in"], p["nose"]), Vector2(p["cowl_z"], p["cowl_y"]),
			Vector2(p["belt_z"], p["belt_y"]), Vector2(-hl - p["tail_in"], p["tail_y"]),
			Vector2(-hl, p["bump_r"]), Vector2(-hl - 0.06, p["sill"])])


static func _widths(profile: PackedVector2Array, w: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(profile.size())
	out.fill(w)
	return out


## F's ask (2026-11-07): people riding inside the trams and buses. Seated (and now and then
## standing) passengers painted just outside one window band of a vehicle's side face (`face`,
## Shape.side_face; the band from u0 to u1 of its length, the window from v0 to v1 of its height):
## a seat every PASSENGER_PITCH m, taken on about three in four by a hash of `seed` and the seat,
## each a pair of shoulders in a shirt colour, a head and hair; a stander's head sits higher. Not
## lit: at night they are dark shapes against the lit window. Part of the vehicle's own mesh, so
## +0 draw calls; 6 triangles a passenger, ~100 a tram car.
const PASSENGER_PITCH := 0.8
const PASSENGER_SHIRTS := ["#2f3e5c", "#8c2f2f", "#d9d2c0", "#3e5a3a", "#5a5a60", "#c97a2b", "#1f2024", "#7a8fa8",
		"#b54a6a", "#e6e1d3"]
const PASSENGER_SKIN := ["#e2b48c", "#c99a74", "#a77452", "#f0c9a5"]
const PASSENGER_HAIR := ["#2a1f18", "#4a3426", "#8a6a3c", "#bdbab2", "#141414"]


static func passengers(s: Shape, face: Array, u0: float, u1: float, v0: float, v1: float, seed: int) -> void:
	var c0: Vector3 = face[0]
	var c1: Vector3 = face[1]
	var c3: Vector3 = face[3]
	var length := c0.distance_to(c1)
	var height := c0.distance_to(c3)
	if length < 0.1 or height < 0.1:
		return
	var seats := int(floorf((u1 - u0) * length / PASSENGER_PITCH))
	var dv := (v1 - v0) / 0.51  # the shares below are of a tram's 0.51 window band
	for k in seats:
		var h := absi(hash(seed * 7919 + k * 104729))
		if h % 4 == 0:
			continue
		var u := u0 + (k + 0.5) * (u1 - u0) / float(seats)
		var hu := 0.2 / length
		var stand := 0.12 * dv if h % 7 == 0 else 0.0
		var shirt := fin(Color(PASSENGER_SHIRTS[(h >> 3) % PASSENGER_SHIRTS.size()]))
		var skin := fin(Color(PASSENGER_SKIN[(h >> 7) % PASSENGER_SKIN.size()]))
		var hair := fin(Color(PASSENGER_HAIR[(h >> 11) % PASSENGER_HAIR.size()]))
		s.pane(face, u - hu, u + hu, v0, v0 + 0.1 * dv + stand, shirt, 0.022)
		var hh := 0.11 / length
		s.pane(face, u - hh, u + hh, v0 + 0.1 * dv + stand, v0 + 0.2 * dv + stand, skin, 0.022)
		s.pane(face, u - hh * 1.1, u + hh * 1.1, v0 + 0.18 * dv + stand, v0 + 0.225 * dv + stand, hair, 0.024)


## A tram car about 10.5 m long; `cab` adds a driver's cab at -Z. Warsaw colours: a yellow
## body over a red skirt, a dark window band (lit at night) between the doors, a grey roof plate.
## The rear car (`rear`, turned round by the trams) shows red tail lamps at its cab. Loop 2c:
## built from the vehicles' shapes: the cab's big windscreen leans back over a rounded nose
## with a destination display above it, two doors a side, dark gangways where the cars join,
## an air-conditioning box on a cab car's roof and the pantograph on the middle car.
static func tram_mesh(cab: bool, rear := false) -> ArrayMesh:
	var s := Shape.new()
	var yellow := fin(Color("#f4c430"))
	var red := fin(Color("#c42f2a"))
	var dark := fin(Color("#2b2c2f"))
	var W := 1.2
	var hl := 5.25
	var nose := 0.22 if cab else 0.0
	var zf := -hl - nose
	var lower := PackedVector2Array([Vector2(-hl, 0.32), Vector2(zf, 0.62), Vector2(zf, 1.1), Vector2(hl, 1.1), Vector2(hl, 0.32)])
	var lw := _widths(lower, W)
	# The Rondo photos (2026-10-31): today's yellow tram has a black skirt and a red roof.
	var skirt := fin(Color("#1d1e20"))
	s.loft(lower, lw, [skirt, skirt, skirt, skirt, null], skirt)
	var house := PackedVector2Array([Vector2(zf, 1.1), Vector2(zf + (0.38 if cab else 0.0), 3.2), Vector2(hl, 3.2), Vector2(hl, 1.1)])
	var hw := PackedFloat32Array([W, W - 0.05, W - 0.05, W])
	s.loft(house, hw, [yellow, yellow, yellow, null], yellow)
	var front := s.edge_face(house, hw, 0)
	if cab:
		s.pane(front, 0.04, 0.96, 0.1, 0.78, fin(GLASS))
		s.pane(front, 0.15, 0.85, 0.83, 0.95, fin(Color("#f0c674"), LIT_SIGN))
		var face := s.edge_face(lower, lw, 1)
		for u: Vector2 in [Vector2(0.07, 0.24), Vector2(0.76, 0.93)]:
			s.pane(face, u.x, u.y, 0.35, 0.75, fin(TAIL, TAIL_LAMP) if rear else fin(HEADLIGHT, HEAD_LAMP))
		s.box(Vector3(0.0, 0.42, zf - 0.08), Vector3(0.5, 0.16, 0.2), dark)
	else:
		s.pane(front, 0.2, 0.8, 0.02, 0.92, dark)
	s.pane(s.edge_face(house, hw, 2), 0.2, 0.8, 0.08, 0.98, dark)
	# Doors and the windows between them, both sides.
	var doors := [-2.0, 2.7] if cab else [-2.6, 2.6]
	var mid: float = (doors[0] + doors[1]) * 0.5
	var panes := [Vector2(zf + 0.45, doors[0] - 0.75), Vector2(doors[0] + 0.75, mid - 0.06),
			Vector2(mid + 0.06, doors[1] - 0.75), Vector2(doors[1] + 0.75, hl - 0.3)]
	for sgn: float in [-1.0, 1.0]:
		var side := s.side_face(house, hw, sgn)
		for p: Vector2 in panes:
			s.pane(side, (p.x - zf) / (hl - zf), (p.y - zf) / (hl - zf), 0.27, 0.78, fin(GLASS, LIT_WINDOW))
			passengers(s, side, (p.x - zf) / (hl - zf), (p.y - zf) / (hl - zf), 0.27, 0.78,
					int(p.x * 10.0) + (31 if sgn > 0.0 else 0) + (7 if cab else 0) + (3 if rear else 0))
		for z: float in doors:
			s.side_rect(sgn * (W + 0.014), sgn, 0.42, 2.78, z - 0.65, z + 0.65, fin(Color("#3a4048")))
	for z: float in [-3.2, 3.2]:
		s.box(Vector3(0, 0.22, z), Vector3(2.0, 0.36, 1.8), fin(Color("#1c1c1e")))
	# The grey roof plate down a yellow roof, as before.
	s.box(Vector3(0.0, 3.25, 0.0), Vector3(2.2, 0.14, 2.0 * hl - 0.2), red)
	if cab:
		s.box(Vector3(0.0, 3.44, 1.2), Vector3(1.5, 0.3, 2.2), fin(Color("#8e8b85")))
	else:
		# Pantograph on the middle car.
		s.box(Vector3(0, 3.5, 0), Vector3(1.4, 0.08, 0.5), dark)
		s.box(Vector3(0, 3.75, 0), Vector3(0.1, 0.5, 0.1), dark)
		s.box(Vector3(0, 4.0, 0), Vector3(1.2, 0.06, 0.12), dark)
	return s.mesh()


## A pedestrian 1.75 m tall: trousers (palette), shirt (instance paint), skin, hair.
## A rain umbrella over a person (F, 2026-11-19, teaser 2: "model the people with umbrellas"):
## an eight-panel canopy in the instance's shirt colour (PAINT, alternate panels a shade darker,
## a darker underside) on a dark shaft in the right hand, in person_mesh's space. Drawn by
## umbrella_twin's MultiMesh from the people's own instance buffer, only while it rains.
static func umbrella_mesh() -> ArrayMesh:
	if _umbrella != null:
		return _umbrella
	var st := _begin()
	box(st, Vector3(0.22, 1.66, 0.06), Vector3(0.035, 0.9, 0.035), Color("#1c1c22"), FIXED)
	var top := Vector3(0.12, 2.24, 0.04)
	const R := 0.6
	const RIM := 2.02
	for k in 8:
		var a0 := TAU * k / 8.0
		var a1 := TAU * (k + 1) / 8.0
		var p0 := Vector3(top.x + cos(a0) * R, RIM, top.z + sin(a0) * R)
		var p1 := Vector3(top.x + cos(a1) * R, RIM, top.z + sin(a1) * R)
		var n := (p0 - top).cross(p1 - top).normalized()
		if n.y < 0.0:
			n = -n
		var shade := 1.0 if k % 2 == 0 else 0.82
		for face in [1.0, -1.0]:
			var tri: Array[Vector3] = [top, p0, p1]
			var fn: Vector3 = n * face
			if (tri[1] - tri[0]).cross(tri[2] - tri[0]).dot(fn) > 0.0:
				tri = [top, p1, p0]
			var c := Color(shade, shade, shade) if face > 0.0 else Color(0.45, 0.45, 0.45)
			for v in tri:
				st.set_color(c)
				st.set_normal(fn)
				st.set_uv(Vector2(PAINT, 0.0))
				st.add_vertex(v)
	box(st, top + Vector3(0, 0.05, 0), Vector3(0.04, 0.1, 0.04), Color("#1c1c22"), FIXED)
	_umbrella = st.commit()
	return _umbrella


## A hidden twin of a people MultiMeshInstance3D (already in the tree) that draws umbrella_mesh
## from the same instance buffer: send it the buffer the people get and call `rain_sync`. +1 draw
## call while it rains and people are shown, none otherwise.
static func umbrella_twin(src: MultiMeshInstance3D) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = umbrella_mesh()
	mm.instance_count = src.multimesh.instance_count
	mm.custom_aabb = src.multimesh.custom_aabb
	var mmi := MultiMeshInstance3D.new()
	mmi.name = src.name + "Umbrellas"
	mmi.multimesh = mm
	mmi.material_override = src.material_override
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.visible = false
	src.get_parent().add_child(mmi)
	return mmi


## Keeps an umbrella twin in step with its people: shown when they are and it rains, the same
## visible count and box. Sends `buf` too when given (whenever the people's buffer is sent, rain or
## not, so the umbrellas are in place the moment the rain starts).
static func rain_sync(twin: MultiMeshInstance3D, src: MultiMeshInstance3D, raining: bool, buf := PackedFloat32Array()) -> void:
	if twin == null:
		return
	var on := raining and src.visible and src.is_visible_in_tree()
	if not buf.is_empty():
		InstanceBuffers.send(twin.multimesh.get_rid(), buf)
	twin.multimesh.visible_instance_count = src.multimesh.visible_instance_count
	twin.multimesh.custom_aabb = src.multimesh.custom_aabb
	if twin.visible != on:
		twin.visible = on


static func person_mesh() -> ArrayMesh:
	var st := _begin()
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.11 * side, 0.43, 0), Vector3(0.17, 0.86, 0.22), Color.WHITE, TROUSERS, side)
	box(st, Vector3(0, 1.15, 0), Vector3(0.46, 0.62, 0.28), Color.WHITE, PAINT)
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.29 * side, 1.12, 0), Vector3(0.12, 0.56, 0.16), Color.WHITE, PAINT)
	box(st, Vector3(0, 1.58, 0), Vector3(0.26, 0.26, 0.26), Color("#e2b48c"))
	box(st, Vector3(0, 1.72, 0.02), Vector3(0.28, 0.08, 0.3), Color("#4a3426"))
	return st.commit()


# --- C1b v2: the sculpted shop cars (F 2026-11-27: "boring; model them like the real cars, the way
# GTA copies them") --------------------------------------------------------------------------------
# Each car is a table of cross-sections along its length (front at -Z): the lower body's
# [z, bottom y, shoulder y, crown y, half-width] (`lower`; the ring is the bottom edge, the widest
# point, the shoulder and the crown, so the nose and tail taper in plan and the arches bulge), and
# the glasshouse's [z, base y, roof y, base half-width, roof half-width, kind] (`house`; `kind`
# colours the piece to the next section: "ws" windscreen, "win" side glass under the roof, "pil" a
# painted pillar, "rq" a painted quarter with the roof, "rw" a rear window with painted sides,
# "rwg" glass all round). `shape` = [bottom inset, widest point's height share, shoulder inset,
# roof crown]. Decals hug the body (`_decal`), so liveries, strips and badges-without-badges follow
# its curves. Every car stays one body mesh plus the two lamp meshes (+0 draw calls).

## The shop cars' tables (see above). Wheels: [front axle z, rear axle z, radius, tyre width].
const SCULPT := {
	# v6 (F 2026-11-27, "the TT is modelled badly", "the shape is all different", photos of an 8J;
	# numbers from an art-director comparison with them): the
	# 8J coupe: 4.18 m, a 2.47 m wheelbase, a long low bonnet, a raked windscreen, a flat roof arc
	# falling as a fastback to a short high tail, a hard shoulder line, flared arches.
	"player_tt": {
		"shape": [0.9, 0.6, 0.88, 0.08], "wheels": [-1.19, 1.28, 0.34, 0.25],
		"lower": [[-2.09, 0.22, 0.66, 0.69, 0.56], [-2.03, 0.18, 0.7, 0.74, 0.63], [-1.85, 0.16, 0.76, 0.81, 0.85],
				[-1.5, 0.16, 0.82, 0.87, 0.89], [-1.19, 0.16, 0.85, 0.9, 0.9], [-0.82, 0.16, 0.91, 0.94, 0.88],
				[-0.1, 0.16, 0.93, 0.96, 0.87], [0.6, 0.16, 0.95, 0.98, 0.87], [1.28, 0.16, 0.97, 1.0, 0.9],
				[1.62, 0.18, 0.98, 1.01, 0.89], [1.92, 0.2, 0.97, 1.0, 0.84], [2.09, 0.3, 0.87, 0.89, 0.68]],
		"house": [[-0.82, 0.92, 0.92, 0.72, 0.72, "ws"], [-0.42, 0.92, 1.11, 0.74, 0.63, "ws"], [-0.1, 0.93, 1.23, 0.74, 0.58, "win"],
				[0.28, 0.94, 1.27, 0.74, 0.58, "win"], [0.8, 0.95, 1.22, 0.72, 0.56, "rw"], [1.25, 0.96, 1.08, 0.69, 0.54, "rw"],
				[1.62, 0.99, 0.99, 0.6, 0.6, ""]]},
	# v3: narrower (0.84), the real 2.52 m wheelbase, a faster windscreen, a short flat boot.
	"player_lanos": {
		"shape": [0.92, 0.5, 0.88, 0.04], "wheels": [-1.32, 1.2, 0.29, 0.2],
		"lower": [[-2.12, 0.33, 0.62, 0.66, 0.72], [-2.0, 0.29, 0.74, 0.77, 0.81], [-1.7, 0.28, 0.8, 0.82, 0.84],
				[-1.32, 0.28, 0.85, 0.86, 0.84], [-0.85, 0.28, 0.91, 0.93, 0.84], [0.2, 0.28, 0.95, 0.96, 0.84],
				[1.2, 0.28, 0.98, 0.99, 0.84], [1.55, 0.3, 0.99, 1.0, 0.83], [2.0, 0.35, 0.99, 1.01, 0.8],
				[2.12, 0.42, 0.9, 0.93, 0.72]],
		"house": [[-0.85, 0.93, 0.93, 0.81, 0.81, "ws"], [-0.12, 0.94, 1.43, 0.8, 0.66, "win"], [0.36, 0.95, 1.45, 0.81, 0.66, "pil"],
				[0.45, 0.96, 1.45, 0.81, 0.66, "win"], [0.85, 0.97, 1.42, 0.81, 0.65, "rw"], [1.55, 0.99, 0.99, 0.82, 0.82, ""]]},
	# v3: the Caro's real 2.51 m wheelbase and long rear overhang, narrow (0.83) on a track tucked
	# 9 cm inside the body (`wheels`' fifth value), lower belt and roof, the small third window.
	"player_bolonez": {
		"shape": [0.97, 0.42, 0.96, 0.02], "wheels": [-1.36, 1.15, 0.29, 0.2, 0.09],
		"lower": [[-2.17, 0.31, 0.74, 0.78, 0.81], [-2.02, 0.3, 0.78, 0.8, 0.83], [-1.36, 0.3, 0.85, 0.86, 0.83],
				[-0.55, 0.3, 0.92, 0.93, 0.83], [0.5, 0.3, 0.95, 0.96, 0.83], [1.15, 0.3, 0.96, 0.97, 0.83],
				[1.98, 0.32, 0.97, 0.98, 0.83], [2.17, 0.36, 0.95, 0.97, 0.81]],
		"house": [[-0.55, 0.93, 0.93, 0.8, 0.8, "ws"], [-0.02, 0.94, 1.41, 0.78, 0.68, "win"], [0.42, 0.95, 1.42, 0.79, 0.68, "pil"],
				[0.52, 0.95, 1.42, 0.79, 0.68, "win"], [0.92, 0.96, 1.41, 0.8, 0.68, "pil"], [1.0, 0.96, 1.41, 0.8, 0.68, "win"],
				[1.2, 0.97, 1.38, 0.8, 0.68, "rw"], [1.98, 0.98, 0.98, 0.81, 0.81, ""]]},
	# v3: the B5's 4.67 m and long nose, a blunt face, one bowed roof arc.
	"player_paszat": {
		"shape": [0.93, 0.5, 0.9, 0.04], "wheels": [-1.385, 1.318, 0.32, 0.22],
		"lower": [[-2.335, 0.3, 0.66, 0.7, 0.78], [-2.2, 0.24, 0.74, 0.77, 0.86], [-1.85, 0.23, 0.8, 0.82, 0.88],
				[-1.385, 0.23, 0.85, 0.86, 0.89], [-0.95, 0.23, 0.9, 0.91, 0.88], [0.3, 0.23, 0.95, 0.96, 0.88],
				[1.318, 0.23, 0.97, 0.98, 0.89], [1.95, 0.25, 0.97, 0.98, 0.88], [2.25, 0.29, 0.96, 0.97, 0.86],
				[2.335, 0.33, 0.92, 0.94, 0.82]],
		"house": [[-0.95, 0.92, 0.92, 0.84, 0.84, "ws"], [-0.33, 0.94, 1.38, 0.83, 0.68, "win"], [0.25, 0.96, 1.47, 0.84, 0.69, "pil"],
				[0.33, 0.96, 1.47, 0.84, 0.69, "win"], [1.05, 0.97, 1.46, 0.84, 0.69, "pil"], [1.13, 0.97, 1.455, 0.84, 0.69, "win"],
				[1.95, 0.97, 1.38, 0.84, 0.67, "rw"], [2.23, 0.97, 0.98, 0.84, 0.8, ""]]},
	# v3: the A80's bubble cabin moved forward with the hatch glass almost to the tail, the long
	# overhangs, a rounder nose, the coke-bottle plan (0.91 front arch, 0.86 door, 0.95 haunch).
	"player_szupra": {
		"shape": [0.9, 0.55, 0.85, 0.05], "wheels": [-1.27, 1.28, 0.33, 0.26],
		"lower": [[-2.26, 0.3, 0.56, 0.6, 0.74], [-2.1, 0.22, 0.64, 0.7, 0.86], [-1.7, 0.2, 0.72, 0.75, 0.91],
				[-1.27, 0.2, 0.78, 0.8, 0.91], [-0.66, 0.2, 0.84, 0.86, 0.86], [0.3, 0.2, 0.88, 0.89, 0.86],
				[0.9, 0.2, 0.91, 0.92, 0.92], [1.28, 0.2, 0.92, 0.93, 0.95], [1.75, 0.22, 0.93, 0.94, 0.93],
				[2.1, 0.28, 0.91, 0.93, 0.87], [2.26, 0.34, 0.84, 0.86, 0.8]],
		"house": [[-0.66, 0.86, 0.86, 0.8, 0.8, "ws"], [0.0, 0.87, 1.24, 0.77, 0.56, "win"], [0.4, 0.88, 1.275, 0.78, 0.56, "win"],
				[0.8, 0.89, 1.25, 0.79, 0.57, "rwg"], [1.3, 0.91, 1.09, 0.82, 0.66, "rwg"], [1.8, 0.93, 0.93, 0.86, 0.86, ""]]},
	# v3: an upright three-box coupe again (the E46's 1.0 m roof and flat boot), the short front
	# overhang, square flares over both axles.
	"player_bawarka": {
		"shape": [0.95, 0.45, 0.92, 0.03], "wheels": [-1.47, 1.26, 0.36, 0.3],
		"lower": [[-2.25, 0.15, 0.62, 0.66, 0.86], [-2.12, 0.14, 0.68, 0.71, 0.95], [-1.85, 0.14, 0.74, 0.76, 1.0],
				[-1.47, 0.14, 0.78, 0.8, 1.0], [-1.1, 0.14, 0.82, 0.84, 0.99], [-0.82, 0.14, 0.86, 0.88, 0.92],
				[0.4, 0.14, 0.9, 0.92, 0.92], [0.9, 0.14, 0.94, 0.95, 0.99], [1.26, 0.14, 0.96, 0.97, 1.0],
				[1.62, 0.16, 0.97, 0.98, 1.0], [2.12, 0.22, 0.97, 0.98, 0.93], [2.25, 0.28, 0.92, 0.94, 0.86]],
		"house": [[-0.82, 0.9, 0.9, 0.84, 0.84, "ws"], [-0.2, 0.92, 1.29, 0.82, 0.62, "win"], [0.3, 0.93, 1.31, 0.83, 0.62, "win"],
				[0.8, 0.94, 1.3, 0.84, 0.62, "rq"], [0.95, 0.95, 1.27, 0.85, 0.62, "rw"], [1.47, 0.97, 0.97, 0.86, 0.86, ""]]},
	# Candidates from F's photos (2026-11-27; F picks up to six for the shop). Parodies, no badges.
	# Lambordżini Mruczelago: a 4.6 m wedge, cab forward, the long engine deck, scoops, a wing.
	"player_mruczelago": {
		"shape": [0.9, 0.55, 0.85, 0.03], "wheels": [-1.3, 1.36, 0.35, 0.3],
		"lower": [[-2.3, 0.2, 0.4, 0.48, 0.82], [-2.15, 0.15, 0.5, 0.56, 0.94], [-1.7, 0.13, 0.6, 0.66, 0.98],
				[-1.3, 0.13, 0.68, 0.73, 1.0], [-0.9, 0.13, 0.74, 0.78, 0.97], [-0.55, 0.13, 0.78, 0.82, 0.95],
				[0.3, 0.13, 0.84, 0.86, 0.96], [0.9, 0.13, 0.88, 0.9, 1.0], [1.36, 0.13, 0.9, 0.93, 1.02],
				[1.8, 0.16, 0.9, 0.93, 1.0], [2.15, 0.22, 0.88, 0.9, 0.94], [2.3, 0.3, 0.82, 0.85, 0.86]],
		"house": [[-0.55, 0.82, 0.82, 0.86, 0.86, "ws"], [0.15, 0.85, 1.12, 0.8, 0.6, "win"], [0.7, 0.86, 1.12, 0.82, 0.6, "rq"],
				[1.0, 0.88, 1.05, 0.84, 0.66, "rq"], [2.0, 0.92, 0.92, 0.88, 0.88, ""]]},
	# Hondzia S660: the 3.4 m kei roadster, mid-engined, a black targa roof, buttresses behind.
	"player_hondzia": {
		"shape": [0.9, 0.5, 0.86, 0.03], "wheels": [-1.15, 1.14, 0.28, 0.19],
		"lower": [[-1.7, 0.25, 0.55, 0.6, 0.6], [-1.62, 0.2, 0.62, 0.66, 0.7], [-1.4, 0.18, 0.68, 0.72, 0.74],
				[-1.15, 0.18, 0.72, 0.75, 0.75], [-0.55, 0.18, 0.8, 0.82, 0.73], [0.4, 0.18, 0.84, 0.86, 0.73],
				[1.14, 0.18, 0.86, 0.88, 0.75], [1.5, 0.2, 0.86, 0.88, 0.73], [1.7, 0.28, 0.8, 0.82, 0.66]],
		"house": [[-0.55, 0.82, 0.82, 0.68, 0.68, "ws"], [-0.05, 0.84, 1.15, 0.66, 0.55, "win"], [0.45, 0.85, 1.15, 0.66, 0.55, "rq"],
				[0.9, 0.86, 1.0, 0.68, 0.6, "rq"], [1.3, 0.87, 0.87, 0.7, 0.7, ""]]},
	# Porsza 911 Kaczy Ogon: the classic rear-engined coupe (a backdated one), the front wings
	# standing above the bonnet with round lamps, one arc from the windscreen to the ducktail.
	"player_porsza": {
		"shape": [0.9, 0.5, 0.86, 0.06], "wheels": [-1.2, 1.07, 0.31, 0.24],
		"lower": [[-2.07, 0.25, 0.5, 0.45, 0.7], [-1.95, 0.2, 0.62, 0.52, 0.8], [-1.6, 0.2, 0.7, 0.6, 0.85],
				[-1.2, 0.2, 0.74, 0.66, 0.88], [-0.85, 0.2, 0.78, 0.76, 0.84], [-0.6, 0.2, 0.82, 0.84, 0.82],
				[0.4, 0.2, 0.85, 0.87, 0.82], [0.8, 0.2, 0.85, 0.88, 0.87], [1.07, 0.2, 0.84, 0.87, 0.9],
				[1.5, 0.22, 0.8, 0.82, 0.88], [1.85, 0.26, 0.72, 0.74, 0.82], [2.07, 0.32, 0.6, 0.62, 0.72]],
		"house": [[-0.6, 0.84, 0.84, 0.76, 0.76, "ws"], [-0.05, 0.86, 1.28, 0.74, 0.58, "win"], [0.3, 0.87, 1.32, 0.74, 0.58, "win"],
				[0.55, 0.87, 1.28, 0.75, 0.6, "rw"], [1.25, 0.85, 0.85, 0.8, 0.8, ""]]},
	# Tojota GieR 86: a long bonnet, the cabin set back, a short fastback deck with a lip.
	"player_gr86": {
		"shape": [0.9, 0.5, 0.88, 0.05], "wheels": [-1.29, 1.28, 0.33, 0.25],
		"lower": [[-2.13, 0.22, 0.5, 0.56, 0.74], [-2.03, 0.17, 0.6, 0.65, 0.86], [-1.75, 0.16, 0.68, 0.72, 0.9],
				[-1.29, 0.16, 0.74, 0.78, 0.92], [-0.7, 0.16, 0.8, 0.83, 0.88], [0.3, 0.16, 0.86, 0.88, 0.87],
				[1.0, 0.16, 0.9, 0.92, 0.91], [1.28, 0.16, 0.91, 0.93, 0.93], [1.7, 0.18, 0.92, 0.94, 0.91],
				[2.03, 0.24, 0.9, 0.92, 0.86], [2.13, 0.3, 0.84, 0.86, 0.78]],
		"house": [[-0.7, 0.83, 0.83, 0.8, 0.8, "ws"], [-0.05, 0.85, 1.24, 0.77, 0.58, "win"], [0.4, 0.86, 1.27, 0.77, 0.57, "win"],
				[0.8, 0.88, 1.22, 0.78, 0.58, "rq"], [1.0, 0.89, 1.16, 0.79, 0.6, "rw"], [1.6, 0.92, 0.92, 0.82, 0.82, ""]]},
	# Kadilak Bruhem: the 5.6 m American land yacht, three boxes, a formal vinyl roof, chrome.
	"player_kadilak": {
		"shape": [0.98, 0.5, 0.97, 0.01], "wheels": [-1.7, 1.37, 0.34, 0.24],
		"lower": [[-2.8, 0.3, 0.82, 0.85, 0.92], [-2.7, 0.26, 0.88, 0.9, 0.96], [-1.7, 0.26, 0.94, 0.95, 0.97],
				[-0.75, 0.26, 0.98, 0.99, 0.97], [0.5, 0.26, 1.0, 1.01, 0.97], [1.37, 0.26, 1.0, 1.01, 0.97],
				[2.6, 0.28, 1.0, 1.01, 0.97], [2.8, 0.32, 0.95, 0.97, 0.94]],
		"house": [[-0.75, 0.99, 0.99, 0.92, 0.92, "ws"], [-0.2, 1.0, 1.43, 0.88, 0.78, "win"], [0.45, 1.0, 1.44, 0.88, 0.78, "pil"],
				[0.55, 1.0, 1.44, 0.88, 0.78, "win"], [1.05, 1.01, 1.43, 0.88, 0.78, "rq"], [1.25, 1.01, 1.4, 0.88, 0.78, "rw"],
				[1.55, 1.01, 1.01, 0.9, 0.9, ""]]},
	# Porsza Bokser: the first mid-engined roadster, soft top up, the oval lamps on the wings.
	"player_bokser": {
		"shape": [0.9, 0.5, 0.86, 0.04], "wheels": [-1.21, 1.2, 0.31, 0.23],
		"lower": [[-2.16, 0.24, 0.45, 0.48, 0.7], [-2.05, 0.18, 0.55, 0.58, 0.84], [-1.7, 0.17, 0.64, 0.62, 0.88],
				[-1.21, 0.17, 0.72, 0.68, 0.9], [-0.7, 0.17, 0.8, 0.8, 0.86], [0.3, 0.17, 0.84, 0.85, 0.86],
				[1.2, 0.17, 0.88, 0.9, 0.9], [1.7, 0.2, 0.88, 0.9, 0.88], [2.05, 0.26, 0.84, 0.86, 0.82],
				[2.16, 0.32, 0.76, 0.78, 0.72]],
		"house": [[-0.7, 0.8, 0.8, 0.8, 0.8, "ws"], [-0.2, 0.82, 1.15, 0.76, 0.6, "win"], [0.35, 0.84, 1.24, 0.76, 0.6, "rq"],
				[0.85, 0.86, 1.1, 0.78, 0.62, "rw"], [1.25, 0.88, 0.88, 0.8, 0.8, ""]]},
	# Madża Mjata (F 2026-11-27 "where is the MX-5 cabrio"): the first small roadster, roof down:
	# 3.97 m, a 2.27 m wheelbase, low round nose, the cockpit open behind a framed windscreen
	# (the kit builds it, so no glasshouse here).
	"player_mjata": {
		"shape": [0.9, 0.5, 0.86, 0.04], "wheels": [-1.15, 1.11, 0.29, 0.21],
		"lower": [[-1.985, 0.3, 0.48, 0.5, 0.66], [-1.88, 0.22, 0.58, 0.61, 0.8], [-1.55, 0.2, 0.66, 0.68, 0.84],
				[-1.15, 0.2, 0.71, 0.73, 0.85], [-0.75, 0.2, 0.75, 0.77, 0.83], [-0.35, 0.2, 0.79, 0.81, 0.82],
				[0.4, 0.2, 0.83, 0.85, 0.82], [0.85, 0.2, 0.85, 0.86, 0.84], [1.11, 0.2, 0.86, 0.87, 0.85],
				[1.6, 0.22, 0.87, 0.88, 0.83], [1.88, 0.28, 0.86, 0.87, 0.79], [1.985, 0.34, 0.79, 0.81, 0.74]],
		"house": []},
}


## The lower body's half ring at section `st` (bottom, widest, shoulder, crown) as (x, y).
static func _ring(st: Array, shape: Array) -> Array[Vector2]:
	var w: float = st[4]
	var yb: float = st[1]
	var ys: float = st[2]
	return [Vector2(w * float(shape[0]), yb), Vector2(w, lerpf(yb, ys, float(shape[1]))), Vector2(w * float(shape[2]), ys),
			Vector2(0.0, float(st[3]))]


## The half-width of the ring at height `y` (0 above the crown, the bottom's below it).
static func _ring_x(ring: Array[Vector2], y: float) -> float:
	if y <= ring[0].y:
		return ring[0].x
	for k in ring.size() - 1:
		var a := ring[k]
		var b := ring[k + 1]
		if y <= b.y or k == ring.size() - 2:
			return lerpf(a.x, b.x, clampf((y - a.y) / maxf(b.y - a.y, 0.001), 0.0, 1.0))
	return 0.0


## The body's side at (z, y): its x, between the two sections round z.
static func _side_x(c: Dictionary, z: float, y: float) -> float:
	var lower: Array = c["lower"]
	var shape: Array = c["shape"]
	if z <= float(lower[0][0]):
		return _ring_x(_ring(lower[0], shape), y)
	for i in lower.size() - 1:
		var a: Array = lower[i]
		var b: Array = lower[i + 1]
		if z <= float(b[0]):
			var t := (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			return lerpf(_ring_x(_ring(a, shape), y), _ring_x(_ring(b, shape), y), t)
	return _ring_x(_ring(lower[lower.size() - 1], shape), y)


## The top surface's height at (z, x) (the shoulder to the crown), and the section's widest half.
static func _top_y(c: Dictionary, z: float, x: float) -> float:
	var lower: Array = c["lower"]
	var shape: Array = c["shape"]
	var at := func(st: Array) -> float:
		var r := _ring(st, shape)
		return lerpf(r[3].y, r[2].y, clampf(absf(x) / maxf(r[2].x, 0.01), 0.0, 1.0))
	if z <= float(lower[0][0]):
		return at.call(lower[0])
	for i in lower.size() - 1:
		var a: Array = lower[i]
		var b: Array = lower[i + 1]
		if z <= float(b[0]):
			var t := (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			return lerpf(at.call(a), at.call(b), t)
	return at.call(lower[lower.size() - 1])


## A decal on side `sgn`: the quad (z, y) a, b, c, d (in order round it) laid on the body in a
## grid of pieces, `lift` m off it, so it follows the flank's curve.
static func _decal(s: Shape, c: Dictionary, sgn: float, q: Array, f: Array, lift := 0.012, n := 6) -> void:
	var at := func(u: float, v: float) -> Vector3:
		var a: Vector2 = q[0]
		var b: Vector2 = q[1]
		var cc: Vector2 = q[2]
		var d: Vector2 = q[3]
		var p := a.lerp(b, u).lerp(d.lerp(cc, u), v)
		return Vector3(sgn * (_side_x(c, p.x, p.y) + lift), p.y, p.x)
	for i in n:
		for j in 2:
			var u0 := float(i) / n
			var u1 := float(i + 1) / n
			var v0 := j * 0.5
			var v1 := v0 + 0.5
			s.quad(at.call(u0, v0), at.call(u1, v0), at.call(u1, v1), at.call(u0, v1), f, Vector3(sgn, 0, 0))


## A decal on the top (bonnet, boot): x from x0 to x1, z from z0 to z1, laid on the top surface.
static func _top_decal(s: Shape, c: Dictionary, x0: float, x1: float, z0: float, z1: float, f: Array, lift := 0.012, n := 6) -> void:
	for i in n:
		var za := lerpf(z0, z1, float(i) / n)
		var zb := lerpf(z0, z1, float(i + 1) / n)
		var p := func(x: float, z: float) -> Vector3: return Vector3(x, _top_y(c, z, x) + lift, z)
		s.quad(p.call(x0, za), p.call(x1, za), p.call(x1, zb), p.call(x0, zb), f, Vector3.UP)


## A flat lamp or panel standing on the nose or the tail: centre `at`, `size` (x, y), facing `out`
## (tilted as the face is); `round` makes it an octagon.
static func _plate(s: Shape, at: Vector3, size: Vector2, out: Vector3, f: Array, round := false) -> void:
	var n := out.normalized()
	var right := Vector3.UP.cross(n).normalized() if absf(n.y) < 0.95 else Vector3.RIGHT
	var up := n.cross(right).normalized()
	if round:
		var ring: Array[Vector3] = []
		for k in 8:
			var a := TAU * (k + 0.5) / 8.0
			ring.append(at + right * cos(a) * size.x * 0.5 + up * sin(a) * size.y * 0.5)
		for k in range(1, 7):
			s.tri(ring[0], ring[k], ring[k + 1], f, n)
		return
	var hx := right * size.x * 0.5
	var hy := up * size.y * 0.5
	s.quad(at - hx - hy, at + hx - hy, at + hx + hy, at - hx + hy, f, n)


## The sculpted body of `kind` (SCULPT): the lower body lofted through its sections, the caps,
## the glasshouse by its kinds, the wheels in their arches. `paint` the body, `roof` the roof.
static func _sculpt(s: Shape, c: Dictionary, paint: Array, roof: Array, glass: Array, rim: Color) -> void:
	var lower: Array = c["lower"]
	var shape: Array = c["shape"]
	var rings: Array = []
	for st: Array in lower:
		rings.append(_ring(st, shape))
	for i in lower.size() - 1:
		var za: float = lower[i][0]
		var zb: float = lower[i + 1][0]
		var ra: Array[Vector2] = rings[i]
		var rb: Array[Vector2] = rings[i + 1]
		var cy := (float(lower[i][1]) + float(lower[i][3])) * 0.5
		for k in 3:
			for sgn: float in [-1.0, 1.0]:
				var a0 := Vector3(sgn * ra[k].x, ra[k].y, za)
				var a1 := Vector3(sgn * ra[k + 1].x, ra[k + 1].y, za)
				var b1 := Vector3(sgn * rb[k + 1].x, rb[k + 1].y, zb)
				var b0 := Vector3(sgn * rb[k].x, rb[k].y, zb)
				var mid := (a0 + a1 + b0 + b1) * 0.25
				s.quad_flat(a0, a1, b1, b0, paint, mid - Vector3(0.0, cy, mid.z))
	# The nose and the tail: a fan over each end's full ring.
	for e in [0, lower.size() - 1]:
		var r: Array[Vector2] = rings[e]
		var z: float = lower[e][0]
		var pts: Array[Vector3] = []
		for k in range(r.size() - 1, -1, -1):
			pts.append(Vector3(-r[k].x, r[k].y, z))
		for k in range(1, r.size()):
			pts.append(Vector3(r[k].x, r[k].y, z))
		var out := Vector3(0, 0, -1) if e == 0 else Vector3(0, 0, 1)
		for k in range(1, pts.size() - 1):
			s.tri(pts[0], pts[k], pts[k + 1], paint, out)
	# The glasshouse.
	var house: Array = c["house"]
	var crown: float = shape[3]
	for i in house.size() - 1:
		var a: Array = house[i]
		var b: Array = house[i + 1]
		var kind: String = a[5]
		var side_f: Array = glass if kind in ["ws", "win", "rwg"] else paint
		var top_f: Array = glass if kind in ["ws", "rw", "rwg"] else roof
		var ring := func(h: Array) -> Array[Vector2]:
			return [Vector2(h[3], h[1]), Vector2(h[4], h[2]), Vector2(0.0, float(h[2]) + (crown if float(h[2]) > float(h[1]) + 0.05 else 0.0))]
		var ra: Array[Vector2] = ring.call(a)
		var rb: Array[Vector2] = ring.call(b)
		for k in 2:
			for sgn: float in [-1.0, 1.0]:
				var p0 := Vector3(sgn * ra[k].x, ra[k].y, a[0])
				var p1 := Vector3(sgn * ra[k + 1].x, ra[k + 1].y, a[0])
				var q1 := Vector3(sgn * rb[k + 1].x, rb[k + 1].y, b[0])
				var q0 := Vector3(sgn * rb[k].x, rb[k].y, b[0])
				var mid := (p0 + p1 + q0 + q1) * 0.25
				var f: Array = side_f if k == 0 else top_f
				var out := mid - Vector3(0.0, float(a[1]) - 0.3, mid.z)
				s.quad_flat(p0, p1, q1, q0, f, out)
	# Wheels in their arches.
	var wl: Array = c["wheels"]
	var r: float = wl[2]
	var tw: float = wl[3]
	# A track narrower than the body (the Bolonez): the wheels tucked this far inside the arches.
	var inset: float = float(wl[4]) if wl.size() > 4 else 0.0
	var sides := 10
	var wc := r * cos(PI / sides)
	for z: float in [wl[0], wl[1]]:
		var sill := _side_bottom(c, z)
		# The arch stands just outside the flank's widest point over the wheel (the flank bulges
		# above the hub, so the arch's top would hide inside it at the hub's width).
		var w := 0.0
		for k in 6:
			w = maxf(w, _side_x(c, z, lerpf(sill, wc + r + 0.07, k / 5.0)))
			w = maxf(w, _side_x(c, z - r, lerpf(sill, wc + r + 0.07, k / 5.0)))
			w = maxf(w, _side_x(c, z + r, lerpf(sill, wc + r + 0.07, k / 5.0)))
		for sgn: float in [-1.0, 1.0]:
			s.arch(sgn * (w + 0.008), sgn, z, wc, r + 0.07, sill, fin(WELL), 6)
			s.wheel(Vector3(sgn * (w + 0.02 - tw * 0.5 - inset), wc, z), r, tw, sides, sgn, fin(TYRE), fin(rim))


## The lower body's bottom height at z.
static func _side_bottom(c: Dictionary, z: float) -> float:
	var lower: Array = c["lower"]
	for i in lower.size() - 1:
		if z <= float(lower[i + 1][0]):
			var t := (z - float(lower[i][0])) / maxf(float(lower[i + 1][0]) - float(lower[i][0]), 0.001)
			return lerpf(float(lower[i][1]), float(lower[i + 1][1]), t)
	return float(lower[lower.size() - 1][1])


## C1b v2: [body, heads, tails] of a sculpted shop car: the body, then each car's signature parts
## (its face, its tail, its kit), from photos of the real cars it parodies (no badges, no logos).
static func _sculpt_meshes(kind: String, paint: Array, stripes: Array, wing: bool) -> Array[ArrayMesh]:
	var c: Dictionary = SCULPT[kind]
	var s := Shape.new()
	var heads := Shape.new()
	var tails := Shape.new()
	var glass := fin(Color("#2f3f52"))
	var black := fin(Color("#1c1d21"))
	var chrome := fin(Color("#d4d7dc"))
	var trim := fin(TRIM)
	var lamp := fin(Color.WHITE)
	var blue := fin(Color("#1d3f8f"), HERO, 0.4)
	var sky := fin(Color("#5aa8e6"), HERO, 0.6)
	var roof := paint
	var rim := Color("#c9ccd1")
	if kind == "player_bawarka":
		paint = fin(Color("#a3abb6"), HERO, 1.1)
		roof = blue
		rim = Color("#d6d9de")
	match kind:
		"player_hondzia", "player_bokser":
			roof = fin(Color("#1c1d21"))
			rim = Color("#2a2b2f") if kind == "player_hondzia" else Color("#b9bcc2")
		"player_kadilak":
			roof = fin(Color(paint[0]).darkened(0.3), HERO, 1.0)
			rim = Color("#dfe2e6")
		"player_mruczelago":
			rim = Color("#a5a9b0")
		"player_gr86":
			rim = Color("#222326")
		"player_lanos":
			rim = Color("#a9adb3")
		"player_bolonez":
			rim = Color("#9a9da3")
		"player_tt":
			glass = fin(Color("#1e2632"))
		"player_paszat":
			# The lowered-TDI meme: silver alloys, dark glass.
			rim = Color("#c4c8ce")
			glass = fin(Color("#26303d"))
	_sculpt(s, c, paint, roof, glass, rim)
	# Mirrors at the windscreen's foot and a dark seal along the side windows' foot (the window
	# line reads from the 80 m camera, and every real car has both).
	var house: Array = c["house"]
	for sgn: float in ([-1.0, 1.0] if house.size() >= 2 else []):
		var h1: Array = house[1]
		var z_end: float = house[house.size() - 2][0]
		if kind == "player_tt":
			z_end = 0.8
		# The mirror sits on the door against the glass (a gap under it threw a shadow bar).
		s.box(Vector3(sgn * (maxf(float(h1[3]) + 0.07, _side_x(c, float(house[0][0]) + 0.24, float(h1[1])) + 0.05)), float(h1[1]) + 0.05, float(house[0][0]) + 0.24), Vector3(0.14, 0.1, 0.1), blue if kind == "player_bawarka" else chrome if kind == "player_tt" else paint)
		var ys := float(h1[1])
		_decal(s, c, sgn, [Vector2(float(house[0][0]) + 0.1, ys - 0.045), Vector2(z_end, float(house[house.size() - 2][1]) - 0.045),
				Vector2(z_end, float(house[house.size() - 2][1]) - 0.005), Vector2(float(house[0][0]) + 0.1, ys - 0.005)], black, 0.01, 6)
	var lower: Array = c["lower"]
	var zf: float = lower[0][0]
	var zr: float = lower[lower.size() - 1][0]
	match kind:
		"player_tt":
			# The 8J coupe (v6, from F's photos; no rings, no badge): the tall single-frame grille in a
			# chrome surround filling the face with the plate across it, lamps high on the nose's
			# corner facets sweeping back with their LED strips, corner intakes with round fogs and a
			# chrome bar, tails wrapping the corners, a diffuser with a pipe a side, the round alloy
			# fuel cap on the right haunch, the lip on the deck.
			_plate(s, Vector3(0.0, 0.45, -2.096), Vector2(0.74, 0.42), Vector3(0, 0, -1), chrome)
			_plate(s, Vector3(0.0, 0.45, -2.102), Vector2(0.68, 0.36), Vector3(0, 0, -1), black)
			for y: float in [0.33, 0.41, 0.49, 0.57]:
				_plate(s, Vector3(0.0, y, -2.106), Vector2(0.64, 0.01), Vector3(0, 0, -1), fin(Color("#55585e")))
			_plate(s, Vector3(0.0, 0.4, -2.11), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			for sgn: float in [-1.0, 1.0]:
				# The 8J lamp (TTS / TT RS): a big swept glass, inner end by the grille, outer end climbing
				# back into the wing; two round lenses inside, the LED "wave" along its lower edge.
				var ln := Vector3(sgn * 0.6, 0.22, -0.77)
				# Smoked glass, a step lighter than the paint, so the swept outline reads on a black car.
				var smoke := fin(Color("#454c57"))
				_plate(s, Vector3(sgn * 0.6, 0.625, -2.03), Vector2(0.29, 0.17), ln, smoke)
				_plate(s, Vector3(sgn * 0.73, 0.69, -1.905), Vector2(0.29, 0.16), ln, smoke)
				_plate(heads, Vector3(sgn * 0.57, 0.64, -2.042), Vector2(0.11, 0.11), ln, lamp, true)
				_plate(heads, Vector3(sgn * 0.68, 0.67, -1.972), Vector2(0.11, 0.11), ln, lamp, true)
				_plate(heads, Vector3(sgn * 0.6, 0.555, -2.042), Vector2(0.25, 0.03), ln, lamp)
				_plate(heads, Vector3(sgn * 0.73, 0.62, -1.915), Vector2(0.26, 0.03), ln, lamp)
				_plate(heads, Vector3(sgn * 0.81, 0.7, -1.85), Vector2(0.08, 0.05), ln, lamp)
				var inn := Vector3(sgn * 0.65, -0.14, -0.75)
				_plate(s, Vector3(sgn * 0.63, 0.35, -2.013), Vector2(0.25, 0.13), inn, black)
				_plate(s, Vector3(sgn * 0.68, 0.345, -1.976), Vector2(0.09, 0.09), inn, fin(Color("#d9dde2")), true)
				_plate(s, Vector3(sgn * 0.61, 0.35, -2.034), Vector2(0.2, 0.015), inn, chrome)
				_plate(s, Vector3(sgn * 0.48, 0.81, 2.1), Vector2(0.27, 0.13), Vector3(0, 0, 1), black)
				_plate(tails, Vector3(sgn * 0.48, 0.81, 2.104), Vector2(0.24, 0.1), Vector3(0, 0, 1), lamp)
				var tn := Vector3(sgn * 0.7, 0.24, 0.67)
				_plate(s, Vector3(sgn * 0.712, 0.812, 2.007), Vector2(0.26, 0.13), tn, black)
				_plate(tails, Vector3(sgn * 0.712, 0.812, 2.011), Vector2(0.23, 0.1), tn, lamp)
				_plate(s, Vector3(sgn * 0.42, 0.3, zr + 0.012), Vector2(0.12, 0.09), Vector3(0, 0, 1), chrome, true)
			_decal(s, c, 1.0, [Vector2(0.86, 0.8), Vector2(1.02, 0.8), Vector2(1.02, 0.92), Vector2(0.86, 0.92)], chrome, 0.016, 2)
			_plate(s, Vector3(0.0, 0.6, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.36, zr + 0.006), Vector2(1.0, 0.14), Vector3(0, 0, 1), black)
			# The deck lip is the active spoiler, its own mesh (tt_spoiler; car.gd raises it).
		"player_lanos":
			# The base 90s saloon (v3): black unpainted bumpers and mirrors, a black rub strip on the
			# doors, almond lamps (high outside, dropping inside), a three-slot grille, wedge tails
			# with the plate between them on the boot; the retired cab's roof-sign base.
			for e: float in [-1.0, 1.0]:
				var z := zf + 0.03 if e < 0.0 else zr - 0.03
				s.box(Vector3(0.0, 0.42, z), Vector3(1.5, 0.2, 0.14), black)
			_plate(s, Vector3(0.0, 0.62, zf - 0.008), Vector2(0.3, 0.09), Vector3(0, 0, -1), black)
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.24, 0.6, zf - 0.008), Vector2(0.14, 0.06), Vector3(0, 0, -1), black)
				_plate(heads, Vector3(sgn * 0.55, 0.7, zf + 0.04), Vector2(0.34, 0.12), Vector3(sgn * 0.35, 0.4, -1), lamp, true)
				_plate(heads, Vector3(sgn * 0.37, 0.66, zf + 0.01), Vector2(0.1, 0.08), Vector3(sgn * 0.2, 0.3, -1), lamp, true)
				_plate(tails, Vector3(sgn * 0.52, 0.84, zr + 0.01), Vector2(0.42, 0.14), Vector3(sgn * 0.15, 0.15, 1), lamp)
				_plate(tails, Vector3(sgn * 0.36, 0.8, zr + 0.012), Vector2(0.12, 0.07), Vector3(0, 0.15, 1), lamp)
				_decal(s, c, sgn, [Vector2(-0.85, 0.52), Vector2(1.0, 0.52), Vector2(1.0, 0.57), Vector2(-0.85, 0.57)], black)
			_plate(s, Vector3(0.0, 0.8, zr + 0.008), Vector2(0.44, 0.11), Vector3(0, 0.1, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.42, zf - 0.1), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			s.box(Vector3(0.0, 1.5, 0.25), Vector3(0.56, 0.08, 0.22), fin(Color("#2a2b2e")))
			s.box(Vector3(0.0, 1.6, 0.25), Vector3(0.5, 0.12, 0.16), fin(Color("#c9b779")))
		"player_bolonez":
			# The Caro (v3): thin wide lamps with a slim grille between, bumpers as big as a fridge
			# (flush with the sides), a black sill, a wide black side strip, the small third window,
			# wide tail blocks with the plate between, the black lip under the hatch glass.
			_plate(s, Vector3(0.0, 0.7, zf - 0.006), Vector2(0.5, 0.09), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.7, zf - 0.01), Vector2(0.46, 0.02), Vector3(0, 0, -1), chrome)
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.55, 0.7, zf - 0.006), Vector2(0.4, 0.15), Vector3(0, 0, -1), black)
				_plate(heads, Vector3(sgn * 0.55, 0.7, zf - 0.012), Vector2(0.36, 0.11), Vector3(0, 0, -1), lamp)
				_plate(s, Vector3(sgn * 0.55, 0.705, zr + 0.006), Vector2(0.46, 0.21), Vector3(0, 0, 1), black)
				_plate(tails, Vector3(sgn * 0.55, 0.705, zr + 0.012), Vector2(0.42, 0.17), Vector3(0, 0, 1), lamp)
				_decal(s, c, sgn, [Vector2(-1.9, 0.5), Vector2(1.95, 0.5), Vector2(1.95, 0.64), Vector2(-1.9, 0.64)], black)
				_decal(s, c, sgn, [Vector2(-1.0, 0.3), Vector2(0.9, 0.3), Vector2(0.9, 0.38), Vector2(-1.0, 0.38)], black)
				s.box(Vector3(sgn * 0.7, 0.24, 1.5), Vector3(0.18, 0.22, 0.02), black)
				_plate(s, Vector3(sgn * 0.55, 0.38, zf - 0.13), Vector2(0.13, 0.09), Vector3(0, 0, -1), fin(Color("#f4e7b0")), true)
			_plate(s, Vector3(0.0, 0.72, zr + 0.008), Vector2(0.44, 0.11), Vector3(0, 0, 1), fin(PLATE))
			s.box(Vector3(0.0, 0.99, 1.96), Vector3(1.5, 0.04, 0.08), black)
			for e: float in [-1.0, 1.0]:
				var z := zf - 0.04 if e < 0.0 else zr + 0.04
				s.box(Vector3(0.0, 0.42, z), Vector3(1.64, 0.26, 0.18), black)
			_plate(s, Vector3(0.0, 0.42, zf - 0.132), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
		"player_paszat":
			# The B5 estate (v3): one-piece lamps either side of a chrome grille, a blunt face, the
			# tails on the body's corners below the glass (wrapping round the sides), rails on feet,
			# a sun strip, dark rear glass, silver alloys, the tow hitch (the TDI's pipe turns down).
			_plate(s, Vector3(0.0, 0.64, zf - 0.006), Vector2(0.56, 0.14), Vector3(0, 0, -1), chrome)
			_plate(s, Vector3(0.0, 0.64, zf - 0.01), Vector2(0.5, 0.1), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.64, zf - 0.014), Vector2(0.5, 0.02), Vector3(0, 0, -1), chrome)
			_plate(s, Vector3(0.0, 0.42, zf - 0.006), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.3, zf - 0.006), Vector2(1.2, 0.1), Vector3(0, 0, -1), black)
			for sgn: float in [-1.0, 1.0]:
				_plate(heads, Vector3(sgn * 0.56, 0.66, zf + 0.03), Vector2(0.44, 0.17), Vector3(sgn * 0.3, 0.3, -1), lamp)
				_plate(tails, Vector3(sgn * 0.62, 0.84, zr + 0.01), Vector2(0.32, 0.3), Vector3(0, 0, 1), lamp)
				_decal(tails, c, sgn, [Vector2(2.18, 0.7), Vector2(2.3, 0.7), Vector2(2.3, 0.98), Vector2(2.18, 0.98)], lamp, 0.014, 2)
				for z: float in [-0.12, 1.78]:
					s.box(Vector3(sgn * 0.6, 1.475, z), Vector3(0.05, 0.05, 0.08), black)
				s.box(Vector3(sgn * 0.6, 1.51, 0.83), Vector3(0.04, 0.035, 1.98), trim)
				_decal(s, c, sgn, [Vector2(-1.9, 0.5), Vector2(2.0, 0.5), Vector2(2.0, 0.54), Vector2(-1.9, 0.54)], trim)
			_plate(s, Vector3(0.0, 0.62, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.36, zr + 0.006), Vector2(1.4, 0.12), Vector3(0, 0, 1), black)
			_plate(s, Vector3(0.0, 1.32, -0.45), Vector2(1.5, 0.08), Vector3(0, 0.6, -1), black)
			s.box(Vector3(0.0, 0.27, zr + 0.04), Vector3(0.08, 0.06, 0.1), black)
		"player_szupra":
			# The A80 (v3): big lamps in the round nose's corners, a wide low mouth with two side
			# intakes, the bonnet's vents, the hoop wing (thin uprights raked back, an arched blade
			# under the roof's height), the tail's dark oval panels with round lamps shrinking inward.
			_plate(s, Vector3(0.0, 0.35, zf - 0.006), Vector2(0.75, 0.2), Vector3(0, 0, -1), black, true)
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.58, 0.3, zf + 0.03), Vector2(0.2, 0.1), Vector3(sgn * 0.3, 0, -1), black)
				_plate(heads, Vector3(sgn * 0.5, 0.6, zf + 0.12), Vector2(0.45, 0.2), Vector3(sgn * 0.4, 0.5, -1), lamp, true)
				_plate(s, Vector3(sgn * 0.48, 0.74, zr + 0.008), Vector2(0.62, 0.17), Vector3(0, 0.1, 1), black, true)
				var lx := [0.66, 0.48, 0.32]
				var lr := [0.15, 0.12, 0.1]
				for k in 3:
					_plate(tails, Vector3(sgn * float(lx[k]), 0.74, zr + 0.016), Vector2(lr[k], lr[k]), Vector3(0, 0.1, 1), lamp, true)
				_top_decal(s, c, sgn * 0.18 - 0.07, sgn * 0.18 + 0.07, -1.5, -1.1, black, 0.012, 2)
			var wz := zr - 0.3
			var wy := 1.21
			for sgn: float in [-1.0, 1.0]:
				var foot := Vector3(sgn * 0.68, _top_y(c, wz - 0.06, 0.68), wz - 0.06)
				var top := Vector3(sgn * 0.68, wy - 0.02, wz + 0.06)
				var mid := (foot + top) * 0.5
				s.box(mid, Vector3(0.06, top.y - foot.y, 0.12), paint)
				s.box(Vector3(sgn * 0.53, wy, wz + 0.06), Vector3(0.5, 0.05, 0.26), paint)
			s.box(Vector3(0.0, wy + 0.04, wz + 0.06), Vector3(0.58, 0.05, 0.26), paint)
			_plate(s, Vector3(0.0, 0.52, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.34, zr + 0.006), Vector2(1.2, 0.1), Vector3(0, 0, 1), black)
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.42, 0.3, zr + 0.01), Vector2(0.11, 0.09), Vector3(0, 0, 1), chrome, true)
		"player_bawarka":
			# Darek's race coupe (v3, a Bavarian-style two-door, no badges, no kidney grille): twin
			# lamps a side, two low wide slots with a body-colour bar between, a wide low intake, a
			# short splitter, skirts, two bonnet vents, the GT wing on the boot lid; the livery is our
			# own: silver over deep blue below a line rising to the tail, a sky-blue edge, the blue
			# roof, two blue bands down the bonnet's left, 87 on the doors; L-shaped tails.
			for sgn: float in [-1.0, 1.0]:
				for u: float in [0.45, 0.7]:
					_plate(heads, Vector3(sgn * u, 0.57, zf + 0.05), Vector2(0.22, 0.14), Vector3(sgn * 0.3, 0.45, -1), lamp)
				_plate(s, Vector3(sgn * 0.16, 0.5, zf - 0.006), Vector2(0.24, 0.08), Vector3(0, 0, -1), black)
				_plate(tails, Vector3(sgn * 0.6, 0.82, zr + 0.01), Vector2(0.42, 0.14), Vector3(sgn * 0.25, 0.2, 1), lamp)
				_plate(tails, Vector3(sgn * 0.78, 0.7, zr - 0.01), Vector2(0.1, 0.18), Vector3(sgn * 0.4, 0.1, 1), lamp)
				_decal(s, c, sgn, [Vector2(-0.95, 0.18), Vector2(2.0, 0.18), Vector2(2.0, 0.86), Vector2(-0.95, 0.5)], blue, 0.012, 8)
				_decal(s, c, sgn, [Vector2(-0.95, 0.5), Vector2(2.0, 0.86), Vector2(2.0, 0.92), Vector2(-0.95, 0.56)], sky, 0.014, 8)
				_decal(s, c, sgn, [Vector2(-1.05, 0.45), Vector2(-0.9, 0.45), Vector2(-0.9, 0.66), Vector2(-1.05, 0.66)], black, 0.016, 1)
				_decal(s, c, sgn, [Vector2(-0.3, 0.42), Vector2(0.18, 0.42), Vector2(0.18, 0.76), Vector2(-0.3, 0.76)], fin(Color("#f2f2ee")), 0.018, 3)
				_digits(s, c, sgn, 0.59, -0.06, blue)
				s.box(Vector3(sgn * 0.98, 0.18, -0.1), Vector3(0.08, 0.1, 1.9), black)
				s.box(Vector3(sgn * 0.45, (0.97 + 1.28) * 0.5, zr - 0.2), Vector3(0.04, 0.31, 0.12), black)
				s.box(Vector3(sgn * 0.9, 1.3, zr - 0.15), Vector3(0.03, 0.18, 0.36), black)
				_plate(s, Vector3(sgn * 0.3, 0.26, zr + 0.01), Vector2(0.11, 0.09), Vector3(0, 0, 1), chrome, true)
				_top_decal(s, c, sgn * 0.18 - 0.14, sgn * 0.18 + 0.14, -1.25, -0.95, black, 0.014, 2)
			_plate(s, Vector3(0.0, 0.3, zf - 0.006), Vector2(1.3, 0.18), Vector3(0, 0, -1), black)
			s.box(Vector3(0.0, 0.1, zf - 0.04), Vector3(1.86, 0.04, 0.16), black)
			s.box(Vector3(0.0, 1.3, zr - 0.15), Vector3(1.8, 0.05, 0.3), black)
			s.box(Vector3(0.0, 1.335, zr - 0.02), Vector3(1.76, 0.02, 0.05), sky)
			_top_decal(s, c, -0.66, -0.46, zf + 0.12, -0.82, blue)
			_top_decal(s, c, -0.42, -0.36, zf + 0.12, -0.82, sky)
			_plate(s, Vector3(0.0, 0.5, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.3, zr + 0.006), Vector2(1.3, 0.14), Vector3(0, 0, 1), black)
		"player_mjata":
			# The roadster, roof down: the pop-up lamps raised (the meme's grin), the oval mouth, a
			# framed windscreen, the open cockpit (two seats, the wheel on the left, the soft top
			# folded behind), round mirrors on the doors, wide tails, one pipe on the right.
			var cabin := fin(Color("#1b1c1f"))
			var seat := fin(Color("#2b2a2c"))
			var ws_z0 := -0.36
			var ws_z1 := -0.02
			var ws_y0 := 0.82
			var ws_y1 := 1.16
			_top_decal(s, c, -0.7, 0.7, ws_z0 + 0.04, 0.82, cabin, 0.014, 4)
			for sgn: float in [-1.0, 1.0]:
				# The pop-up pods stand on the bonnet's front, their round lamps facing ahead.
				var px := sgn * 0.5
				var pz := -1.6
				var py := _top_y(c, pz, px)
				s.box(Vector3(px, py + 0.08, pz + 0.04), Vector3(0.34, 0.16, 0.26), paint)
				_plate(s, Vector3(px, py + 0.08, pz - 0.092), Vector2(0.3, 0.14), Vector3(0, 0, -1), black)
				_plate(heads, Vector3(px, py + 0.08, pz - 0.1), Vector2(0.13, 0.12), Vector3(0, 0, -1), lamp, true)
				# Small amber corners and a parking lamp at the mouth's sides.
				_plate(heads, Vector3(sgn * 0.52, 0.42, zf + 0.03), Vector2(0.2, 0.07), Vector3(sgn * 0.3, 0.1, -1), lamp)
				_decal(s, c, sgn, [Vector2(-1.6, 0.55), Vector2(-1.5, 0.55), Vector2(-1.5, 0.6), Vector2(-1.6, 0.6)], fin(Color("#e3902a")), 0.014, 1)
				# The wide tails at each corner, wrapping a little round the sides.
				_plate(tails, Vector3(sgn * 0.5, 0.68, zr + 0.012), Vector2(0.5, 0.14), Vector3(sgn * 0.2, 0.1, 1), lamp)
				# Seats: a cushion, a back raked behind, a headrest the camera sees.
				var sx := sgn * 0.36
				s.box(Vector3(sx, 0.9, 0.3), Vector3(0.44, 0.08, 0.42), seat)
				s.box(Vector3(sx, 1.0, 0.56), Vector3(0.44, 0.3, 0.1), seat)
				s.box(Vector3(sx, 1.2, 0.6), Vector3(0.24, 0.14, 0.08), seat)
				# A round mirror on each door, just behind the windscreen's foot.
				s.box(Vector3(sgn * 0.9, ws_y0 + 0.12, ws_z0 + 0.18), Vector3(0.1, 0.09, 0.05), paint)
				s.box(Vector3(sgn * 0.84, ws_y0 + 0.07, ws_z0 + 0.18), Vector3(0.08, 0.04, 0.04), black)
				# The windscreen's pillar on this side, a dark strip up the glass's edge.
				var pa := Vector3(sgn * 0.8, ws_y0, ws_z0)
				var pb := Vector3(sgn * 0.7, ws_y1, ws_z1)
				var inn := Vector3(-sgn * 0.05, 0.0, 0.0)
				s.quad(pa, pb, pb + inn, pa + inn, black, Vector3(0, 0.6, -1))
				s.quad(pa, pa + inn, pb + inn, pb, black, Vector3(0, -0.6, 1))
				s.quad(pa, pb, pb + Vector3(0, 0, 0.05), pa + Vector3(0, 0, 0.05), black, Vector3(sgn, 0, 0))
			# The windscreen: glass to the front, its dark back to the cockpit (both faces), the header.
			var a0 := Vector3(-0.8, ws_y0, ws_z0)
			var a1 := Vector3(0.8, ws_y0, ws_z0)
			var b1 := Vector3(0.7, ws_y1, ws_z1)
			var b0 := Vector3(-0.7, ws_y1, ws_z1)
			s.quad(a0, a1, b1, b0, glass, Vector3(0, 0.6, -1))
			s.quad(a0, b0, b1, a1, fin(Color("#23303e")), Vector3(0, -0.6, 1))
			s.box(Vector3(0.0, ws_y1 + 0.02, ws_z1 + 0.01), Vector3(1.44, 0.05, 0.06), black)
			s.box(Vector3(0.0, ws_y0 + 0.02, ws_z0 - 0.02), Vector3(1.62, 0.04, 0.08), black)
			# The wheel on the driver's (left, -x) side and the dash's top.
			s.box(Vector3(-0.36, 0.98, -0.02), Vector3(0.34, 0.3, 0.04), black)
			s.box(Vector3(0.0, 0.88, -0.2), Vector3(1.4, 0.08, 0.2), cabin)
			# The soft top folded behind the seats, under its black boot.
			s.box(Vector3(0.0, 0.92, 0.78), Vector3(1.42, 0.1, 0.24), cabin)
			# The oval mouth, the front plate over it, the rear plate, the pipe on the right.
			_plate(s, Vector3(0.0, 0.36, zf - 0.006), Vector2(0.64, 0.15), Vector3(0, -0.15, -1), black, true)
			_plate(s, Vector3(0.0, 0.4, zf - 0.012), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.6, zr + 0.008), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.45, 0.3, zr + 0.01), Vector2(0.09, 0.08), Vector3(0, 0, 1), chrome, true)
		"player_mruczelago":
			# The wedge: angular lamps on the nose's top corners, big black intakes, the plate low,
			# the side scoops behind the doors, louvres on the engine deck, hexagon-ish tails, the wing.
			for sgn: float in [-1.0, 1.0]:
				var x0 := minf(sgn * 0.5, sgn * 0.86)
				var x1 := maxf(sgn * 0.5, sgn * 0.86)
				_top_decal(s, c, x0, x1, -2.2, -1.95, black, 0.012, 2)
				_top_decal(heads, c, x0 + 0.04, x1 - 0.04, -2.17, -2.0, lamp, 0.02, 2)
				_plate(s, Vector3(sgn * 0.55, 0.3, -2.25), Vector2(0.5, 0.18), Vector3(sgn * 0.2, -0.1, -1), black)
				_decal(s, c, sgn, [Vector2(0.75, 0.5), Vector2(1.2, 0.5), Vector2(1.2, 0.82), Vector2(0.75, 0.7)], black, 0.014, 2)
				s.box(Vector3(sgn * 0.92, 0.98, 1.2), Vector3(0.1, 0.12, 0.5), black)
				_plate(s, Vector3(sgn * 0.6, 0.72, zr + 0.01), Vector2(0.48, 0.18), Vector3(0, 0.1, 1), black)
				_plate(tails, Vector3(sgn * 0.6, 0.72, zr + 0.015), Vector2(0.4, 0.12), Vector3(0, 0.1, 1), lamp)
				s.box(Vector3(sgn * 0.6, 1.08, 1.95), Vector3(0.06, 0.24, 0.16), paint)
			for k in 4:
				_top_decal(s, c, -0.5, 0.5, 1.3 + k * 0.18, 1.38 + k * 0.18, black, 0.014, 1)
			_plate(s, Vector3(0.0, 0.42, zf - 0.006), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.5, zr + 0.008), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.3, zr + 0.008), Vector2(1.3, 0.16), Vector3(0, 0, 1), black)
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.08, 0.3, zr + 0.014), Vector2(0.11, 0.1), Vector3(0, 0, 1), chrome, true)
			s.box(Vector3(0.0, 1.21, 1.95), Vector3(1.9, 0.05, 0.36), paint)
		"player_hondzia":
			# The kei roadster: a wide black mouth band, slim lamps on the corners, the black stripe
			# over the bonnet and the roof, buttresses, slim tails, a centre pipe.
			_plate(s, Vector3(0.0, 0.42, zf - 0.006), Vector2(0.86, 0.14), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.33, zf - 0.012), Vector2(0.42, 0.1), Vector3(0, 0, -1), fin(Color("#e6c400")))
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.48, 0.56, zf + 0.04), Vector2(0.34, 0.12), Vector3(sgn * 0.4, 0.3, -1), black)
				_plate(heads, Vector3(sgn * 0.48, 0.56, zf + 0.036), Vector2(0.3, 0.07), Vector3(sgn * 0.4, 0.3, -1), lamp)
				_plate(s, Vector3(sgn * 0.48, 0.72, zr + 0.01), Vector2(0.34, 0.1), Vector3(0, 0.1, 1), black)
				_plate(tails, Vector3(sgn * 0.48, 0.72, zr + 0.014), Vector2(0.3, 0.06), Vector3(0, 0.1, 1), lamp)
			_top_decal(s, c, -0.12, 0.12, zf + 0.06, -0.55, stripes)
			_top_decal(s, c, -0.12, 0.12, 1.3, zr - 0.05, stripes, 0.012, 2)
			_plate(s, Vector3(0.0, 0.5, zr + 0.006), Vector2(0.44, 0.1), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.3, zr + 0.01), Vector2(0.11, 0.09), Vector3(0, 0, 1), chrome, true)
		"player_porsza":
			# The classic: round lamps on the wings' fronts with chrome rings, amber corners, the
			# black lip, the side stripe, the ducktail, slim tails with a red bar, two pipes.
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.6, 0.64, -1.97), Vector2(0.24, 0.24), Vector3(0, 0.35, -1), chrome, true)
				_plate(heads, Vector3(sgn * 0.6, 0.64, -1.975), Vector2(0.19, 0.19), Vector3(0, 0.35, -1), lamp, true)
				_plate(s, Vector3(sgn * 0.5, 0.38, zf - 0.006), Vector2(0.18, 0.06), Vector3(0, 0, -1), fin(Color("#e3902a")))
				_decal(s, c, sgn, [Vector2(-1.45, 0.3), Vector2(1.3, 0.3), Vector2(1.3, 0.36), Vector2(-1.45, 0.36)], stripes)
				_plate(tails, Vector3(sgn * 0.58, 0.6, zr + 0.01), Vector2(0.24, 0.1), Vector3(sgn * 0.3, 0.1, 1), lamp)
				_plate(s, Vector3(sgn * 0.42, 0.26, zr + 0.01), Vector2(0.09, 0.08), Vector3(0, 0, 1), chrome, true)
			_plate(s, Vector3(0.0, 0.3, zf - 0.006), Vector2(1.2, 0.08), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.42, zf - 0.008), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.42, zr + 0.008), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(tails, Vector3(0.0, 0.6, zr + 0.01), Vector2(0.6, 0.04), Vector3(0, 0.1, 1), lamp)
			s.box(Vector3(0.0, 0.8, 1.86), Vector3(1.3, 0.06, 0.34), paint)
			_top_decal(s, c, -0.36, 0.36, 1.45, 1.7, black, 0.014, 2)
		"player_gr86":
			# The 86: a wide low black mesh mouth, slim lamps swept up the corners, the vents behind
			# the front wheels, wide tails joined by a black bar, two pipes, a lip on the deck.
			_plate(s, Vector3(0.0, 0.32, zf - 0.006), Vector2(0.9, 0.24), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.34, zf - 0.012), Vector2(0.44, 0.11), Vector3(0, 0, -1), fin(PLATE))
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.6, 0.6, zf + 0.09), Vector2(0.4, 0.13), Vector3(sgn * 0.55, 0.45, -1), black)
				_plate(heads, Vector3(sgn * 0.6, 0.6, zf + 0.086), Vector2(0.34, 0.08), Vector3(sgn * 0.55, 0.45, -1), lamp)
				_decal(s, c, sgn, [Vector2(-0.95, 0.45), Vector2(-0.8, 0.45), Vector2(-0.8, 0.62), Vector2(-0.95, 0.62)], black, 0.014, 1)
				_plate(s, Vector3(sgn * 0.56, 0.8, zr + 0.01), Vector2(0.46, 0.13), Vector3(sgn * 0.3, 0.15, 1), black)
				_plate(tails, Vector3(sgn * 0.56, 0.8, zr + 0.014), Vector2(0.4, 0.08), Vector3(sgn * 0.3, 0.15, 1), lamp)
				_plate(s, Vector3(sgn * 0.55, 0.26, zr + 0.01), Vector2(0.11, 0.1), Vector3(0, 0, 1), chrome, true)
			_plate(s, Vector3(0.0, 0.8, zr + 0.008), Vector2(0.6, 0.08), Vector3(0, 0.1, 1), black)
			_plate(s, Vector3(0.0, 0.56, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.3, zr + 0.006), Vector2(1.2, 0.12), Vector3(0, 0, 1), black)
			s.box(Vector3(0.0, _top_y(c, 2.0, 0.0) + 0.02, 2.0), Vector3(1.3, 0.04, 0.1), paint)
		"player_kadilak":
			# The land yacht: the chrome waterfall grille, square quad lamps with amber corners, the
			# bonnet ornament, chrome bumpers like park benches, a chrome rocker, tall tails in the
			# rear wings.
			_plate(s, Vector3(0.0, 0.68, zf - 0.006), Vector2(0.78, 0.32), Vector3(0, 0, -1), chrome)
			_plate(s, Vector3(0.0, 0.68, zf - 0.012), Vector2(0.7, 0.26), Vector3(0, 0, -1), black)
			for k in 7:
				_plate(s, Vector3(-0.3 + k * 0.1, 0.68, zf - 0.016), Vector2(0.02, 0.26), Vector3(0, 0, -1), chrome)
			s.box(Vector3(0.0, 0.88, zf + 0.12), Vector3(0.05, 0.08, 0.08), chrome)
			for sgn: float in [-1.0, 1.0]:
				for u: float in [0.5, 0.68]:
					_plate(heads, Vector3(sgn * u, 0.7, zf - 0.008), Vector2(0.16, 0.14), Vector3(0, 0, -1), lamp)
				_plate(s, Vector3(sgn * 0.86, 0.7, zf - 0.008), Vector2(0.12, 0.14), Vector3(0, 0, -1), fin(Color("#e3902a")))
				_decal(s, c, sgn, [Vector2(-2.6, 0.3), Vector2(2.6, 0.3), Vector2(2.6, 0.48), Vector2(-2.6, 0.48)], fin(Color("#aab0b8")), 0.012, 8)
				_decal(s, c, sgn, [Vector2(-2.6, 0.48), Vector2(2.6, 0.48), Vector2(2.6, 0.51), Vector2(-2.6, 0.51)], chrome, 0.014, 8)
				_plate(tails, Vector3(sgn * 0.86, 0.68, zr + 0.01), Vector2(0.14, 0.4), Vector3(0, 0, 1), lamp)
			for e: float in [-1.0, 1.0]:
				var z := zf - 0.05 if e < 0.0 else zr + 0.05
				s.box(Vector3(0.0, 0.4, z), Vector3(1.94, 0.2, 0.14), chrome)
				_plate(s, Vector3(0.0, 0.4, z + e * 0.072), Vector2(0.5, 0.11), Vector3(0, 0, e), fin(PLATE))
		"player_bokser":
			# The first roadster: oval lamps on the wings' fronts (amber inside), three front intakes,
			# the black soft top, oval-ish tails, a centre pipe, the deck's lip.
			for sgn: float in [-1.0, 1.0]:
				_plate(s, Vector3(sgn * 0.55, 0.53, -2.04), Vector2(0.38, 0.2), Vector3(sgn * 0.45, 0.6, -1), black, true)
				_plate(heads, Vector3(sgn * 0.57, 0.535, -2.044), Vector2(0.24, 0.15), Vector3(sgn * 0.45, 0.6, -1), lamp, true)
				_plate(s, Vector3(sgn * 0.62, 0.3, zf + 0.04), Vector2(0.28, 0.12), Vector3(sgn * 0.3, 0, -1), black)
				_plate(s, Vector3(sgn * 0.6, 0.7, zr + 0.01), Vector2(0.44, 0.17), Vector3(sgn * 0.3, 0.15, 1), black, true)
				_plate(tails, Vector3(sgn * 0.6, 0.7, zr + 0.014), Vector2(0.38, 0.12), Vector3(sgn * 0.3, 0.15, 1), lamp, true)
			_plate(s, Vector3(0.0, 0.3, zf - 0.006), Vector2(0.5, 0.12), Vector3(0, 0, -1), black)
			_plate(s, Vector3(0.0, 0.42, zf - 0.008), Vector2(0.5, 0.11), Vector3(0, 0, -1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.5, zr + 0.006), Vector2(0.5, 0.11), Vector3(0, 0, 1), fin(PLATE))
			_plate(s, Vector3(0.0, 0.28, zr + 0.01), Vector2(0.12, 0.1), Vector3(0, 0, 1), chrome, true)
			s.box(Vector3(0.0, _top_y(c, 1.95, 0.0) + 0.02, 1.95), Vector3(1.2, 0.04, 0.12), black)
	# The bought GT wing, on the cars that have no wing of their own (over the boot or the roof's end).
	if wing and kind not in ["player_szupra", "player_bawarka", "player_mruczelago"]:
		var hatchy := kind in ["player_bolonez", "player_paszat"]
		var wz: float = (float(c["house"][c["house"].size() - 2][0]) + 0.05) if hatchy else (zr - 0.3)
		var foot: float = float(c["house"][c["house"].size() - 2][2]) if hatchy else _top_y(c, zr - 0.3, 0.5)
		var wy := foot + 0.28
		var span := 1.9
		for sgn: float in [-1.0, 1.0]:
			s.box(Vector3(sgn * 0.5, (foot + wy) * 0.5, wz), Vector3(0.07, wy - foot, 0.14), trim)
			s.box(Vector3(sgn * span * 0.5, wy + 0.06, wz), Vector3(0.04, 0.24, 0.5), trim)
		s.box(Vector3(0.0, wy + 0.03, wz), Vector3(span, 0.06, 0.46), stripes)
	return [s.mesh(), heads.mesh(), tails.mesh()]


## The TT's active spoiler (F 2026-11-27: "a small spoiler that slides out", as on the 8J): a blade
## in the paint with a dark underside, lying flush on the deck's end; car.gd lifts it SPOILER_LIFT
## with speed. Its own small mesh in the body's material (+1 draw call, the TT only).
const SPOILER_LIFT := 0.08
static func tt_spoiler(paint: Array) -> ArrayMesh:
	var s := Shape.new()
	var y := _top_y(SCULPT["player_tt"], 1.88, 0.0)
	s.box(Vector3(0.0, y + 0.02, 1.88), Vector3(1.2, 0.03, 0.16), paint)
	s.box(Vector3(0.0, y - 0.01, 1.88), Vector3(1.12, 0.03, 0.12), fin(TRIM), true)
	return s.mesh()


## "87" as two seven-segment digits on a door (side `sgn`), centred on (y, z), laid on the body.
static func _digits(s: Shape, c: Dictionary, sgn: float, y: float, z: float, f: Array) -> void:
	var h := 0.12
	var w := 0.09
	var t := 0.026
	# A reader facing the right side (+x) reads from the tail to the nose (larger z first).
	var first := 0.065 * sgn
	var bar := func(z0: float, z1: float, y0: float, y1: float) -> void:
		_decal(s, c, sgn, [Vector2(z0, y0), Vector2(z1, y0), Vector2(z1, y1), Vector2(z0, y1)], f, 0.024, 1)
	for d in 2:
		var cz := z + (first if d == 0 else -first)
		# The digit's right edge (as read) is towards -z on the right side, +z on the left.
		var rz := cz - sgn * w * 0.5
		var lz := cz + sgn * w * 0.5
		bar.call(minf(lz, rz), maxf(lz, rz), y + h - t * 0.5, y + h + t * 0.5)
		bar.call(rz - t * 0.5, rz + t * 0.5, y - h, y + h)
		if d == 0:
			bar.call(minf(lz, rz), maxf(lz, rz), y - t * 0.5, y + t * 0.5)
			bar.call(minf(lz, rz), maxf(lz, rz), y - h - t * 0.5, y - h + t * 0.5)
			bar.call(lz - t * 0.5, lz + t * 0.5, y - h, y + h)
