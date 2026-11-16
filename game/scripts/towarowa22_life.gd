extends "res://scripts/place.gd"
## Towarowa 22's street life (F, 2026-11-16, the playtest screenshot of the bare lot by Rondo
## Daszyńskiego): what the finished quarter's ground carries once the towers stand, from the
## developer's plan (docs/landmarks/specs/towarowa22.md): Nowa Wronia as a walking street with
## café terraces under the ground floors, Ogrody Towarowa (the old printing hall's frame over a
## garden, benches among the trees), the pavilion's café terrace, Park Słowa's benches round the
## oval path, planters, lamps and bike docks along Towarowa, and people (seated at the tables and
## on the benches, standing and chatting on the paving). The ground itself is the site's
## (skyline.gd, `_t22_ground`, 0.15-0.24 m over the terrain); this only dresses it.
## Static, in the actors' material through `pour`: one draw call per sector, no colliders (like
## the map's benches the pieces are drive-through). Strolling people are the crowd system's.
## Props are the shared ones (props.gd); nothing here names a brand.

const Props := preload("res://scripts/props.gd")

## The Towarowa 22 frame (skyline.gd T22_O, T22_A, T22_B): `u` along Towarowa's east carriageway
## (south-south-east), `v` across it (east-north-east).
const FRAME_O := Vector2(-2635.5, 470.0)
const FRAME_A := Vector2(0.4719, 0.8815)
const FRAME_B := Vector2(0.8815, -0.4719)
## The finished ground's height over the terrain (the lawn's 0.26 and the paving's 0.15-0.21 pass
## under it): pieces stand on it, not in it.
const LIFT := 0.27
## People are drawn a quarter larger than life: at the phone's isometric scale a true-size person is a few pixels.
const PERSON := 1.3
## Which way a piece's front faces, degrees from +u towards +v.
const FACES := {"+u": 0.0, "-u": 180.0, "+v": 90.0, "-v": -90.0}
const SHIRTS := ["#c8282a", "#2a62d1", "#f2c12e", "#f4f2ec", "#3a7d44", "#7a52b8", "#e8762a", "#2b2730",
	"#e8a6b8", "#4fb3c9", "#8a5a3c", "#d9d2c0"]
const TROUSERS := ["#2d3442", "#3b3f48", "#6b5a48", "#23262c", "#4a5568"]
const CANOPIES := ["#2f6b4f", "#f4f1de", "#c8282a", "#24324a", "#e8d36a", "#e07a5f"]

## Park Słowa's oval path (skyline.gd `_t22_park`: centre of T22_PARK, 30 x 18 m).
const PARK_C := Vector2(166.5, 250.0)

## [kind, u, v, face, extra]. cafe: extra = canopy index (+ a seated pair when odd); bench: extra =
## length (and a seated person on every second one); planter: flower colour; heater, lamp, dock:
## extra unused or n bikes; stand: extra = shirt index (a person standing, looking along `face`).
const ITEMS := [
	# Towarowa's frontage: lamps, planters between the benches, facing the road.
	["lamp", 26.0, 7.0, "-v", null], ["lamp", 62.0, 7.0, "-v", null], ["lamp", 98.0, 7.0, "-v", null],
	["lamp", 134.0, 7.0, "-v", null], ["lamp", 170.0, 7.0, "-v", null], ["lamp", 206.0, 7.0, "-v", null],
	["lamp", 242.0, 7.0, "-v", null],
	["planter", 38.0, 10.0, "-v", "#e8a6b8"], ["planter", 74.0, 10.0, "-v", "#f2c12e"],
	["planter", 110.0, 10.0, "-v", "#c8282a"], ["planter", 146.0, 10.0, "-v", "#f4f2ec"],
	["planter", 182.0, 10.0, "-v", "#e8762a"], ["planter", 218.0, 10.0, "-v", "#7a52b8"],
	["bench", 30.0, 11.5, "-v", 3.2], ["bench", 50.0, 11.5, "-v", 3.2], ["bench", 86.0, 11.5, "-v", 3.2],
	["bench", 122.0, 11.5, "-v", 3.2], ["bench", 158.0, 11.5, "-v", 3.2], ["bench", 194.0, 11.5, "-v", 3.2],
	["bench", 230.0, 11.5, "-v", 3.2],
	["dock", 42.0, 12.5, "+u", 6], ["dock", 212.0, 12.5, "+u", 6],
	# Nowa Wronia's café terraces: north side under the low blocks, south side under the tanks block
	# and Gutenberga's.
	["cafe", 112.0, 94.6, "+v", 0], ["cafe", 115.6, 94.6, "+v", 1], ["cafe", 119.2, 94.6, "+v", 2],
	["cafe", 202.0, 94.6, "+v", 3], ["cafe", 205.6, 94.6, "+v", 4], ["cafe", 209.2, 94.6, "+v", 5],
	["cafe", 226.0, 94.6, "+v", 1], ["cafe", 229.6, 94.6, "+v", 0],
	["cafe", 112.0, 105.6, "-v", 4], ["cafe", 115.6, 105.6, "-v", 5], ["cafe", 119.2, 105.6, "-v", 3],
	["cafe", 130.0, 105.6, "-v", 0], ["cafe", 133.6, 105.6, "-v", 2],
	["cafe", 212.0, 105.6, "-v", 2], ["cafe", 215.6, 105.6, "-v", 1], ["cafe", 219.2, 105.6, "-v", 4],
	["cafe", 240.0, 105.6, "-v", 5], ["cafe", 243.6, 105.6, "-v", 3],
	["heater", 123.0, 94.8, "+v", null], ["heater", 213.0, 94.8, "+v", null],
	["heater", 124.0, 105.4, "-v", null], ["heater", 224.0, 105.4, "-v", null],
	["lamp", 105.0, 100.5, "+v", null], ["lamp", 140.0, 100.5, "+v", null], ["lamp", 176.0, 100.5, "+v", null],
	["lamp", 200.0, 100.5, "+v", null], ["lamp", 236.0, 100.5, "+v", null], ["lamp", 270.0, 100.5, "+v", null],
	["planter", 150.0, 94.6, "+v", "#f2c12e"], ["planter", 168.0, 94.6, "+v", "#c8282a"],
	["planter", 186.0, 105.6, "-v", "#e8a6b8"], ["planter", 255.0, 94.6, "+v", "#f4f2ec"],
	["bench", 156.0, 106.0, "-v", 2.6], ["bench", 262.0, 106.0, "-v", 2.6],
	# People on the walking street: couples and friends chatting, a stroller or two stopped.
	["stand", 108.0, 100.0, "+u", 0], ["stand", 109.3, 101.2, "-u", 3], ["stand", 132.0, 99.4, "+v", 5],
	["stand", 146.0, 100.8, "+u", 8], ["stand", 147.2, 99.6, "+u", 2], ["stand", 164.0, 101.0, "-u", 6],
	["stand", 190.0, 100.0, "+u", 10], ["stand", 191.2, 101.4, "-v", 1], ["stand", 222.0, 100.2, "-u", 4],
	["stand", 247.0, 99.8, "+u", 7], ["stand", 248.3, 101.0, "-u", 11], ["stand", 266.0, 100.6, "+u", 9],
	# The towers' feet: a few waiting and meeting.
	["stand", 36.0, 13.5, "+v", 2], ["stand", 37.2, 14.3, "+v", 5], ["stand", 104.0, 13.0, "+u", 0],
	["stand", 168.0, 13.5, "-u", 8], ["stand", 226.0, 13.0, "+v", 6],
	# Ogrody Towarowa: benches between the trees under the hall's frame, people on the lawn.
	["bench", 131.0, 164.0, "+v", 3.0], ["bench", 158.0, 164.0, "+v", 3.0], ["bench", 184.0, 164.0, "+v", 3.0],
	["bench", 144.0, 182.0, "-v", 3.0], ["bench", 171.0, 182.0, "-v", 3.0],
	["planter", 121.0, 160.0, "-u", "#e8a6b8"], ["planter", 121.0, 186.0, "-u", "#f2c12e"],
	["planter", 195.0, 160.0, "+u", "#c8282a"], ["planter", 195.0, 186.0, "+u", "#f4f2ec"],
	["stand", 150.0, 173.0, "+u", 1], ["stand", 151.1, 174.0, "-u", 9], ["stand", 177.0, 176.0, "+v", 4],
	["stand", 140.0, 190.0, "-v", 10], ["stand", 188.0, 150.0, "+v", 7],
	# More of the walking street and the plazas: groups outside the cafés, people crossing.
	["stand", 117.0, 99.0, "+u", 4], ["stand", 118.2, 100.2, "-u", 7], ["stand", 125.0, 101.5, "+u", 1],
	["stand", 136.0, 98.8, "-u", 9], ["stand", 156.0, 100.0, "+u", 3], ["stand", 157.3, 101.1, "+v", 11],
	["stand", 172.0, 99.0, "-u", 0], ["stand", 182.0, 101.0, "+u", 6], ["stand", 207.0, 100.5, "+u", 2],
	["stand", 208.4, 99.5, "-u", 5], ["stand", 216.0, 101.2, "+v", 8], ["stand", 232.0, 100.0, "-u", 10],
	["stand", 238.0, 99.2, "+u", 3], ["stand", 256.0, 100.8, "-u", 1], ["stand", 274.0, 100.0, "+u", 7],
	["stand", 60.0, 30.0, "+u", 4], ["stand", 61.2, 31.0, "-u", 9], ["stand", 90.0, 70.0, "+v", 2],
	["stand", 134.0, 70.0, "-u", 6], ["stand", 160.0, 60.0, "+u", 0], ["stand", 190.0, 72.0, "-v", 11],
	["stand", 215.0, 98.0, "+u", 5], ["stand", 120.0, 214.0, "+u", 10], ["stand", 140.0, 214.5, "+u", 1],
	["stand", 160.0, 215.0, "-u", 8], ["stand", 188.0, 214.0, "+u", 3],
	# The pavilion's terrace on its south side.
	["cafe", 118.0, 220.8, "-v", 1], ["cafe", 121.6, 220.8, "-v", 2], ["cafe", 125.2, 220.8, "-v", 5],
	["cafe", 150.0, 220.8, "-v", 0], ["cafe", 153.6, 220.8, "-v", 4], ["cafe", 157.2, 220.8, "-v", 3],
	["cafe", 180.0, 220.8, "-v", 1], ["cafe", 183.6, 220.8, "-v", 2],
	["heater", 134.0, 220.6, "-v", null], ["heater", 168.0, 220.6, "-v", null],
	["lamp", 112.0, 222.0, "-v", null], ["lamp", 142.0, 222.0, "-v", null], ["lamp", 172.0, 222.0, "-v", null],
	["lamp", 198.0, 222.0, "-v", null],
	# Park Słowa: benches round the oval path (see _park_ring), a few people on the grass.
	["stand", 160.0, 238.0, "+u", 3], ["stand", 161.2, 239.0, "-u", 6], ["stand", 178.0, 262.0, "+v", 0],
	["stand", 150.0, 256.0, "+u", 11], ["stand", 196.0, 246.0, "-v", 5],
]


static func at(u: float, v: float) -> Vector2:
	return FRAME_O + FRAME_A * u + FRAME_B * v


## The yaw that turns a prop's -z front to `face` (FACES key).
static func yaw_of(face: String) -> float:
	var deg: float = FACES[face]
	var f := FRAME_A * cos(deg_to_rad(deg)) + FRAME_B * sin(deg_to_rad(deg))
	return atan2(-f.x, -f.y)


func _xf(u: float, v: float, yaw: float) -> Transform3D:
	var p := at(u, v)
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, map.ground_height(p.x, p.y) + LIFT, p.y))


func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item: Array in ITEMS:
		var xf := _xf(float(item[1]), float(item[2]), yaw_of(item[3]))
		match str(item[0]):
			"cafe":
				var k: int = item[4]
				Props.add_cafe_set(st, xf, Color(CANOPIES[k % CANOPIES.size()]))
				# Two chairs at local z = -0.6 and +0.6: people in two of three sets.
				if k % 4 != 3:
					_seated(st, xf, Vector3(0.0, 0.0, -0.6), k, false)
				if k % 4 != 1:
					_seated(st, xf, Vector3(0.0, 0.0, 0.6), k + 5, true)
			"bench":
				Props.add_long_bench(st, xf, float(item[4]))
				if count % 2 == 0:
					_seated(st, xf, Vector3(-0.5, 0.0, -0.05), count, false)
					if float(item[4]) > 2.8:
						_seated(st, xf, Vector3(0.45, 0.0, -0.05), count + 3, true)
			"planter":
				_bed(st, xf, Color(item[4]))
			"heater":
				Props.add_patio_heater(st, xf)
			"lamp":
				Props.add_park_lamp(st, xf)
			"dock":
				Props.add_bike_dock(st, xf, int(item[4]))
			"stand":
				_person(st, xf, int(item[4]), 1.0)
		count += 1
	_park_ring(st)
	pour(st.commit(), true, "Towarowa22Life")


## A raised bed (a stone kerb, a clipped hedge and a row of flowers, 3 m long): the quarter's planters.
func _bed(st: SurfaceTool, xf: Transform3D, flower: Color) -> void:
	var stone := Color("#bdb8ad")
	Props._xbox(st, xf, Vector3(0, 0.25, 0), Vector3(3.0, 0.5, 0.8), stone)
	Props._xbox(st, xf, Vector3(0, 0.62, 0), Vector3(2.7, 0.34, 0.6), Color("#4f7a3a"))
	for k in 5:
		Props._xbox(st, xf, Vector3((k - 2) * 0.55, 0.9, 0.0), Vector3(0.3, 0.26, 0.4), flower)
	count += 0


## One person (props.gd's, 84 triangles) at `xf`, shirt `k`, scaled `h` tall (1.0 standing).
func _person(st: SurfaceTool, xf: Transform3D, k: int, h: float) -> void:
	var m := Props.person(Color(SHIRTS[k % SHIRTS.size()]), Color(TROUSERS[k % TROUSERS.size()]))
	var b := xf.basis * Basis.from_scale(Vector3(PERSON, PERSON * h, PERSON))
	st.append_from(m, 0, Transform3D(b, xf.origin))


## A person sitting at a chair or on a bench: the standing figure squashed to 0.64 and set so the
## hips meet the seat (0.46 m); `flip` turns them to face the other way across the table.
func _seated(st: SurfaceTool, xf: Transform3D, off: Vector3, k: int, flip: bool) -> void:
	var f := xf
	f.origin += xf.basis * off + Vector3.UP * 0.1
	if flip:
		f.basis = xf.basis * Basis(Vector3.UP, PI)
	_person(st, f, k + 3, 0.64)


## Park Słowa's benches (and a lamp between each pair) just outside the oval path, facing in.
func _park_ring(st: SurfaceTool) -> void:
	for k in 8:
		var ang := TAU * (float(k) + 0.5) / 8.0
		var u := PARK_C.x + cos(ang) * 33.0
		var v := PARK_C.y + sin(ang) * 21.0
		var toward := Vector2(PARK_C.x - u, PARK_C.y - v)
		var f := FRAME_A * toward.x + FRAME_B * toward.y
		var xf := _xf(u, v, atan2(-f.x, -f.y))
		Props.add_long_bench(st, xf, 2.8)
		if k % 2 == 0:
			_seated(st, xf, Vector3(-0.4, 0.0, -0.05), k, false)
			_seated(st, xf, Vector3(0.4, 0.0, -0.05), k + 4, false)
		var lu := PARK_C.x + cos(ang + TAU / 16.0) * 34.5
		var lv := PARK_C.y + sin(ang + TAU / 16.0) * 22.5
		Props.add_park_lamp(st, _xf(lu, lv, 0.0))
		count += 2
