extends "res://scripts/place.gd"
## Schodki nad Wisłą Phase B item 4 (F, 2026-11-19): food on the upper promenade by the steps, beside
## Pawilon 512: an ice-cream cart under a striped umbrella ("LODY U SYRENKI") and a food truck
## ("ZAPIEKANKI Z BULWARU"), both parodies (no brand; Syrenka is the city's own mermaid), each with
## its vendor standing at the hatch. The queues are not here: a static mesh cannot know the hour, so
## boulevard_life.gd's `standers` (city_life.gd's guests) queue at the hatches in the evening.
## Built at runtime on both city paths as a place: one mesh poured in the actors' material, no draw
## call of its own. Nothing here is solid (the promenade is a walk, not a road).
##
## The steps' frame (boulevard_life.gd's C, A, N): `u` along the river, `v` towards the water. Both
## stand at v about -15 with their hatches facing the water (N), the walkers' side.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const Pixel := preload("res://scripts/pixel_font.gd")
const Blvd := preload("res://scripts/boulevard_life.gd")

## Where the two stand (frame u, v): on the plaza at the promenade's east end, beyond the lamp row and
## the benches, hatches to the water; see boulevard_life.gd STANDERS for their queues.
const CART_AT := Vector2(104.0, -19.0)
const TRUCK_AT := Vector2(92.0, -19.2)
const CREAM := Color("#f4efe2")
const PINK := Color("#e8749a")
const RED := Color("#b8322a")
const NAVY := Color("#1d2a4a")
const STEEL := Color("#9aa0a6")
const DARK := Color("#2a2420")
const INK := Color("#8f2a22")

var _st: SurfaceTool
var _basis: Basis
var _o: Vector3


func build() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Local axes of a piece: x along the river (A), y up, z away from the water, so -z (the hatch)
	# faces N.
	_basis = Basis(Vector3(Blvd.A.x, 0, Blvd.A.y), Vector3.UP, Vector3(-Blvd.N.x, 0, -Blvd.N.y))
	_cart(CART_AT)
	_truck(TRUCK_AT)
	pour(_st.commit(), true, "BulwarFood")


## Sets the local frame at the frame's (u, v) on the ground.
func _place(uv: Vector2) -> void:
	var p := Blvd.at(uv.x, uv.y)
	_o = Vector3(p.x, map.ground_height(p.x, p.y), p.y)


## A box in the local frame: centre `c`, size `s`.
func _b(c: Vector3, s: Vector3, colour: Color, part := Props.FIXED) -> void:
	Props.obox(_st, _o + _basis * c, _basis, s, colour, part)
	count += 1


## A line of pixel text on a local -z face at z, `cx` its centre x, `ytop` its top, lit at night.
func _text(text: String, cx: float, ytop: float, z: float, px: float, colour: Color) -> void:
	var w := Pixel.width(text) * px
	var origin := _o + _basis * Vector3(cx + w * 0.5, ytop, z - 0.01)
	var right := -_basis.x
	Pixel.add_quads(_st, text, origin, right, Vector3.DOWN, px, colour, Models.LIT_SIGN)


## A person standing at local `c` facing -z, in their own colours (Props.person).
func _person(c: Vector3, shirt: Color, trousers: Color) -> void:
	_st.append_from(Props.person(shirt, trousers), 0, Transform3D(_basis, _o + _basis * c))
	count += 1


## The ice-cream cart: a white box on two wheels with a glass lid, a pink-and-cream striped umbrella
## on a pole, the name on its front and the vendor behind it.
func _cart(uv: Vector2) -> void:
	_place(uv)
	var tyre := Models.TYRE
	_b(Vector3(0, 0.22, 0), Vector3(1.4, 0.16, 0.7), DARK)
	_b(Vector3(0, 0.6, 0), Vector3(1.5, 0.64, 0.8), CREAM)
	_b(Vector3(0, 1.0, 0), Vector3(1.4, 0.12, 0.7), Color("#bfe3ee"))
	for x in [-0.82, 0.82]:
		_b(Vector3(x, 0.24, 0.0), Vector3(0.08, 0.48, 0.48), tyre)
	_b(Vector3(0, 0.85, 0.55), Vector3(1.0, 0.04, 0.04), STEEL)
	# The name on a navy board across the front.
	_b(Vector3(0, 0.62, -0.42), Vector3(1.36, 0.34, 0.03), NAVY)
	_text("LODY U SYRENKI", 0.0, 0.74, -0.44, 0.021, Color("#fff3c4"))
	# The umbrella: a pole at the back corner and six stripes.
	_b(Vector3(0.62, 1.4, 0.25), Vector3(0.05, 2.0, 0.05), STEEL)
	for k in 6:
		_b(Vector3((k - 2.5) * 0.37 + 0.3, 2.36, 0.25), Vector3(0.37, 0.06, 2.1), PINK if k % 2 == 0 else CREAM)
	# A cone with a scoop on the umbrella's top.
	_b(Vector3(0.3, 2.5, 0.25), Vector3(0.14, 0.22, 0.14), Color("#d9a441"))
	_b(Vector3(0.3, 2.68, 0.25), Vector3(0.22, 0.2, 0.22), PINK)
	_person(Vector3(0.0, 0.0, 0.75), Color("#f4f4f0"), Color("#2d3442"))


## The food truck: a hollow cream box with a red band, a hatch with a striped awning and a counter, a
## dark cab at the +u end on four wheels, the name above the hatch and the vendor inside.
func _truck(uv: Vector2) -> void:
	_place(uv)
	var cx := -0.3
	var w := 3.6
	# The floor, roof, back and the two ends; the front has the hatch left open.
	_b(Vector3(cx, 0.7, 0), Vector3(w - 0.3, 0.1, 1.7), DARK)
	_b(Vector3(cx, 2.95, 0), Vector3(w, 0.1, 2.0), CREAM)
	_b(Vector3(cx, 1.725, 0.95), Vector3(w, 2.35, 0.1), Color("#3b3430"))
	for x in [-2.1, 1.5]:
		_b(Vector3(x, 1.725, 0), Vector3(0.1, 2.35, 2.0), CREAM)
	# The front: the red band under the hatch, the cream above it and the pillars.
	_b(Vector3(cx, 0.925, -0.95), Vector3(w, 0.75, 0.1), RED)
	_b(Vector3(cx, 2.625, -0.95), Vector3(w, 0.55, 0.1), CREAM)
	for x in [-1.65, 1.05]:
		_b(Vector3(x, 1.825, -0.95), Vector3(0.9, 1.05, 0.1), CREAM)
	_text("ZAPIEKANKI Z BULWARU", cx, 2.85, -1.0, 0.04, INK)
	# The counter and the awning.
	_b(Vector3(-0.3, 1.32, -1.18), Vector3(2.1, 0.06, 0.4), STEEL)
	for k in 5:
		_b(Vector3(-0.3 + (k - 2) * 0.42, 2.0, -1.3), Vector3(0.42, 0.05, 0.7), RED if k % 2 == 0 else CREAM)
	# The cab, the wheels, a vent on the roof.
	_b(Vector3(2.15, 1.35, 0), Vector3(1.2, 1.5, 1.9), Color("#2f3a4a"))
	_b(Vector3(2.15, 1.7, -0.96), Vector3(1.0, 0.6, 0.04), Color("#9bc3d6"))
	_b(Vector3(0.9, 0.5, 0), Vector3(3.9, 0.4, 1.8), DARK)
	for x in [-1.4, 1.5, 2.4]:
		for z in [-0.98, 0.98]:
			_b(Vector3(x, 0.42, z), Vector3(0.84, 0.84, 0.22), Models.TYRE)
	_b(Vector3(-1.1, 3.15, 0.1), Vector3(0.9, 0.3, 0.7), STEEL)
	# Inside: the vendor behind the counter, a griddle.
	_b(Vector3(-0.8, 1.05, 0.2), Vector3(1.0, 0.8, 0.5), STEEL)
	_person(Vector3(0.3, 0.75, 0.35), Color("#c8282a"), Color("#2d3442"))
