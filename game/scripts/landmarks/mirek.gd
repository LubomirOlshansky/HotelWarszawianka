extends "res://scripts/landmarks/karowa.gd"
## Warsztat u Mirka, Mirek's tuning workshop on Grzybowska (F, 2026-11-24: "a real garage on
## Grzybowska, on an empty plot, really cool, like a pimp-my-ride show, supercars and stripped cars
## beside it, something meme-y, lit up"; spec docs/landmarks/specs/warsztat_mirka.md). An invented
## business on a real street, on the empty plot on Grzybowska's south side between Q22 and the
## slab at number 61 (OpenStreetMap: grass and trees, no building). One link of landmarks.gd's base
## chain (TD-10): it uses this file, common.gd and the facade kit, never another area. garage.gd
## owns the game side (SPOT is this frame's WM_FORECOURT, check_garage.gd holds them together).
##
## The frame: u along Grzybowska's eastbound carriageway (WM_A, west to east), v away from it into
## the plot (south-east); WM_O is the carriageway's middle. What stands there, the road side first:
##  - the forecourt (concrete, v 9.8-21) with a glowing blue bay in front of the open door: where
##    the car stops and Mirek asks (garage.gd); the driveway is the mapped service stub at u 9;
##  - the hall (u -17..5, v 21..35, 6.6 m): graphite ribbed cladding, three roller doors in hazard
##    frames: the left one shut and tagged, the other two open and lit, a two-post lift behind each
##    under strip lights (a blue hatchback being tuned, a stripped shell); a black fascia with blue
##    LED edges and WARSZTAT U MIRKA in pink neon; a chequered parapet;
##  - on the roof, the meme: a little cream hatchback parked up there, nose to the street, and
##    ZROBI SIĘ! ("it'll get done!", every Warsaw mechanic's promise) in yellow neon beside it;
##  - the yard to the west: two lowered supercars (lime and orange) with pink and cyan underglow,
##    a stripped car on axle stands (no wheels, no bonnet, a red door on a primer body, the engine
##    out on a pallet), the Bawarka (F's meme: "BMWs that drink oil") bonnet up in its own puddle
##    with a pyramid of oil cans and OLEJ DO BAWARKI in yellow neon, tyre stacks, oil drums;
##    CHIP TUNING in cyan neon on the west wall, seen by the traffic coming along Grzybowska;
##  - two floodlight masts over the forecourt.
## Everything is the city's building surface (+0 draw calls); every light is M_LAMP (its colour by
## day, glowing at night); the words are the landmark neon MultiMesh's (night only).

const WM_O := Vector2(-1731.8, -253.45)
const WM_A := Vector2(0.8650, -0.5018)
## The middle of the forecourt in front of the open door: garage.gd SPOT.
const WM_FORECOURT := Vector2(-6.0, 14.0)
## The hall: u0, u1, v0 (the front), v1 (the back), and its height.
const WM_HALL := [-17.0, 5.0, 21.0, 35.0]
const WM_H := 6.6
## The doors: [u0, u1, how] ("shut", "open"), 4.4 m tall.
const WM_DOORS := [[-14.0, -9.0, "shut"], [-7.5, -2.5, "open"], [-1.0, 4.0, "open"]]
## The two lifts inside, behind the open doors: [u, v].
const WM_LIFTS := [Vector2(-5.0, 28.0), Vector2(1.5, 28.0)]
## F 2026-11-24 ("memes about tuning: BMWs that drink oil, chip tuning"): the Bawarka (the game's
## parody of the Bavarian saloon) in the yard, bonnet up, in its own puddle of oil: [u, v, heading].
const WM_BAWARKA := Vector3(-23.5, 23.8, 90.0)
const WM_DOOR_H := 4.4
## The whole site (the zone, no trees in it): forecourt, yard, hall.
const WM_PLOT := [-31.0, 11.0, 9.5, 36.5]
## The supercars: [u, v, heading (degrees from -v, towards the road, + turns to +u), body, glow].
const WM_SUPERCARS := [[-26.3, 16.0, -18.0, Color("#73e62e"), Color(1.0, 0.25, 0.75)],
		[-21.4, 17.2, -10.0, Color("#ff6a14"), Color(0.2, 0.9, 1.0)]]
const WM_WRECK := Vector3(-24.0, 28.5, 75.0)
const WM_ROOF_CAR := Vector3(-11.0, 23.3, 25.0)

const WM_WALL := Color("#363b46")
const WM_RIB := Color("#474d5a")
const WM_ROOF := Color("#3b3d42")
const WM_INSIDE := Color("#c5c9cf")
const WM_FLOOR := Color("#7d8794")
const WM_CONCRETE := Color("#6a6b6d")
const WM_DOOR := Color("#8d929b")
const WM_SLAT := Color("#6d727b")
const WM_HAZARD := Color("#ffc21a")
const WM_BLACK := Color("#141417")
const WM_WHITE := Color("#ecebe6")
const WM_BOARD := Color("#12151d")
const WM_BLUE := Color("#5aa0ff")  # garage.gd GARAGE_COLOUR: the bay, the door's frame, the fascia's edges
const WM_PINK := Color(1.0, 0.25, 0.7)
const WM_CYAN := Color(0.2, 0.9, 1.0)
const WM_YELLOW := Color(1.0, 0.85, 0.15)
const WM_WARM := Color(1.0, 0.92, 0.75)
const WM_TYRE := Color("#1c1c1f")
const WM_GLASS := Color("#1a2230")
const WM_PRIMER := Color("#8e8a80")
const WM_RUST := Color("#7a4a2c")


func _wm_frame() -> void:
	_o = WM_O
	_a = WM_A.normalized()
	_b = Vector2(-_a.y, _a.x)


## A point of the frame in map metres (check_garage.gd: SPOT is WM_FORECOURT's).
static func mr_world(u: float, v: float) -> Vector2:
	var a := WM_A.normalized()
	return WM_O + a * u + Vector2(-a.y, a.x) * v


func _find_warsztat_mirka() -> void:
	_wm_frame()
	var plot := _urect(WM_PLOT[0], WM_PLOT[1], WM_PLOT[2], WM_PLOT[3])
	_add_site("warsztat_mirka", [plot])
	tree_free.append([plot, 0.0, _box_of([plot])])
	parked_free.append([plot, _box_of([plot])])


func _build_warsztat_mirka(_site: Dictionary) -> void:
	_wm_frame()
	var g := _mean_ground(_urect(WM_HALL[0], WM_HALL[1], WM_HALL[2], WM_HALL[3]))
	_g = g
	_mode = M_STONE
	_wm_ground(g)
	_wm_hall(g)
	_wm_front(g)
	_wm_inside(g)
	_wm_roof(g)
	for c: Array in WM_SUPERCARS:
		_wm_supercar(Vector2(c[0], c[1]), float(c[2]), g, c[3], c[4])
	_wm_wreck(g)
	_wm_bawarka(g)
	_wm_yard(g)
	_wm_masts(g)
	# The words (night neon): the fascia, the west wall (the traffic along Grzybowska sees it), the roof.
	_usign("WARSZTAT U MIRKA", -6.0, WM_HALL[2], g + 4.95, -_b, 13.0, 1.05, WM_PINK)
	_usign("CHIP TUNING", WM_HALL[0] + 0.2, 28.0, g + 3.15, -_a, 7.6, 1.25, WM_CYAN)
	_usign("OLEJ DO BAWARKI", WM_BAWARKA.x, 21.2, g + 2.55, -_b, 5.6, 0.7, WM_YELLOW)
	_usign("ZROBI SIĘ!", -4.2, WM_HALL[2] + 1.05, g + WM_H + 1.05, -_b, 6.2, 0.95, WM_YELLOW)
	# The car stops on the forecourt; the hall, the yard's cars and the stripped one are solid.
	_collide(_urect(WM_HALL[0], WM_HALL[1], WM_HALL[2], WM_HALL[3]))
	for c: Array in WM_SUPERCARS:
		_collide(_wm_ring(Vector2(c[0], c[1]), float(c[2]), 2.3, 1.0))
	_collide(_wm_ring(Vector2(WM_WRECK.x, WM_WRECK.y), WM_WRECK.z, 2.1, 0.95))
	_collide(_wm_ring(Vector2(WM_BAWARKA.x, WM_BAWARKA.y), WM_BAWARKA.z, 2.4, 0.95))
	_mode = M_STONE


# --- small kit ---------------------------------------------------------------------------------

## A box turned in the plan: centre `c` (u, v), heading `deg` (0: its length along -v, towards the
## road; + turns towards +u), half length `hl`, half width `hw`.
func _wm_ring(c: Vector2, deg: float, hl: float, hw: float) -> PackedVector2Array:
	var d := Vector2(sin(deg_to_rad(deg)), -cos(deg_to_rad(deg)))
	var e := Vector2(-d.y, d.x)
	var out := PackedVector2Array()
	for k: Vector2 in [d * hl - e * hw, d * hl + e * hw, -d * hl + e * hw, -d * hl - e * hw]:
		out.append(_w(c.x + k.x, c.y + k.y))
	return out


func _wm_box(c: Vector2, deg: float, hl: float, hw: float, y0: float, y1: float, col: Color, mode := M_STONE, top := Color(0, 0, 0, 0)) -> void:
	_prism(_wm_ring(c, deg, hl, hw), y0, y1, col, top if top.a > 0.0 else col.darkened(0.12), mode, mode)


## A point `along` metres ahead of `c` and `side` to its right (heading `deg`), in (u, v).
static func _wm_at(c: Vector2, deg: float, along: float, side: float) -> Vector2:
	var d := Vector2(sin(deg_to_rad(deg)), -cos(deg_to_rad(deg)))
	return c + d * along + Vector2(-d.y, d.x) * side


## One flat quad on the front's plane (v), facing the road (-v): u0..u1, y0..y1.
func _wm_face(u0: float, u1: float, v: float, y0: float, y1: float, col: Color, mode := M_STONE) -> void:
	var keep := _mode
	_mode = mode
	var p0 := _w(u0, v)
	var p1 := _w(u1, v)
	var n := Vector3(-_b.x, 0.0, -_b.y)
	_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y), n, col)
	_mode = keep


## A flat strip on the ground (painted or lit), out of the roof grid.
func _wm_paint(u0: float, u1: float, v0: float, v1: float, y: float, col: Color, mode := M_STONE) -> void:
	_no_roof = true
	_ubox(u0, u1, v0, v1, y, y + 0.03, col, mode, col)
	_no_roof = false


## A tyre stack (`n` tyres) on a spot, an eight-sided column with a lighter rim on top.
func _wm_tyres(u: float, v: float, y: float, n: int) -> void:
	var c := _w(u, v)
	_prism(_circle(c, 0.36, 8), y, y + 0.24 * n, WM_TYRE, WM_TYRE.lightened(0.12), M_STONE, M_STONE)


# --- the parts -----------------------------------------------------------------------------------

## The concrete of the forecourt and the yard, the parking lines, the glowing bay at the door.
func _wm_ground(g: float) -> void:
	_no_roof = true
	_ubox(WM_PLOT[0] + 1.0, WM_PLOT[1] - 1.0, WM_PLOT[2] + 0.3, WM_HALL[2], g - 0.35, g + 0.05, WM_CONCRETE, M_STONE, WM_CONCRETE)
	_ubox(WM_PLOT[0] + 1.0, WM_HALL[0], WM_HALL[2], WM_PLOT[3] - 1.0, g - 0.35, g + 0.05, WM_CONCRETE.darkened(0.06), M_STONE, WM_CONCRETE.darkened(0.06))
	_no_roof = false
	var y := g + 0.05
	# The yard's three bays (white lines), the supercars in two of them.
	for u: float in [-28.9, -23.9, -18.9]:
		_wm_paint(u - 0.07, u + 0.07, 12.0, 20.0, y, WM_WHITE)
	# The bay at the open door, in the garage's blue, glowing at night: where Mirek asks.
	var f: Vector2 = WM_FORECOURT
	for e: Array in [[f.x - 3.0, f.x + 3.0, f.y - 3.4, f.y - 3.0], [f.x - 3.0, f.x + 3.0, f.y + 3.0, f.y + 3.4],
			[f.x - 3.0, f.x - 2.6, f.y - 3.0, f.y + 3.0], [f.x + 2.6, f.x + 3.0, f.y - 3.0, f.y + 3.0]]:
		_wm_paint(e[0], e[1], e[2], e[3], y, WM_BLUE, M_LAMP)
	# Three chevrons from the bay to the door.
	for k in 3:
		var v0 := f.y + 4.2 + 0.9 * k
		_wm_paint(f.x - 1.4, f.x + 1.4, v0, v0 + 0.4, y, WM_BLUE, M_LAMP)


## The hall's walls and their ribs (the front is `_wm_front`).
func _wm_hall(g: float) -> void:
	var u0: float = WM_HALL[0]
	var u1: float = WM_HALL[1]
	var v0: float = WM_HALL[2]
	var v1: float = WM_HALL[3]
	var top := g + WM_H - 0.3
	_ubox(u0, u1, v1 - 0.3, v1, g - 0.5, top, WM_WALL)
	_ubox(u0, u0 + 0.3, v0 + 0.3, v1 - 0.3, g - 0.5, top, WM_WALL)
	_ubox(u1 - 0.3, u1, v0 + 0.3, v1 - 0.3, g - 0.5, top, WM_WALL)
	# The front: the wall between the open doors, a lintel over each.
	var from := u0
	for d: Array in WM_DOORS:
		if str(d[2]) != "open":
			continue
		_ubox(from, d[0], v0, v0 + 0.3, g - 0.5, top, WM_WALL)
		_ubox(d[0], d[1], v0, v0 + 0.3, g + WM_DOOR_H, top, WM_WALL)
		from = d[1]
	_ubox(from, u1, v0, v0 + 0.3, g - 0.5, top, WM_WALL)
	# The cladding's ribs on the side walls (the west one faces the traffic).
	var v := v0 + 1.2
	while v < v1 - 0.6:
		_ubox(u0 - 0.08, u0, v - 0.05, v + 0.05, g, top, WM_RIB)
		_ubox(u1, u1 + 0.08, v - 0.05, v + 0.05, g, top, WM_RIB)
		v += 1.4
	# A dark board behind CHIP TUNING on the west wall, edged in cyan.
	_ubox(u0 - 0.14, u0 - 0.08, 24.0, 32.0, g + 2.7, g + 4.8, WM_BOARD)
	for yy: float in [g + 2.62, g + 4.8]:
		_ubox(u0 - 0.16, u0 - 0.1, 24.0, 32.0, yy, yy + 0.08, WM_CYAN, M_LAMP)


## The front: the doors in their frames, the shut one's tag, the open ones in blue LED frames,
## the fascia and its LED edges.
func _wm_front(g: float) -> void:
	var vf: float = WM_HALL[2] - 0.04
	for d: Array in WM_DOORS:
		var u0: float = d[0]
		var u1: float = d[1]
		# Hazard posts either side, black and yellow in 0.4 m blocks.
		for s: float in [u0 - 0.3, u1]:
			for k in 11:
				_ubox(s, s + 0.3, vf - 0.12, vf + 0.3, g + 0.4 * k, g + 0.4 * (k + 1), WM_HAZARD if k % 2 == 0 else WM_BLACK)
		_ubox(u0 - 0.3, u1 + 0.3, vf - 0.12, vf + 0.3, g + WM_DOOR_H, g + WM_DOOR_H + 0.25, WM_HAZARD)
		match str(d[2]):
			"shut":
				_wm_shutter(u0, u1, g, g + WM_DOOR_H, vf)
				# The tag: three sprayed bands across the shutter.
				_wm_face(u0 + 0.4, u1 - 1.1, vf - 0.07, g + 1.1, g + 1.55, WM_PINK.darkened(0.15))
				_wm_face(u0 + 0.9, u1 - 0.3, vf - 0.07, g + 1.55, g + 2.05, WM_CYAN.darkened(0.2))
				_wm_face(u0 + 0.2, u1 - 1.8, vf - 0.07, g + 2.05, g + 2.4, WM_YELLOW.darkened(0.1))
			"open":
				# Its frame in the garage's blue (glowing at night).
				for s2: float in [u0, u1 - 0.12]:
					_ubox(s2, s2 + 0.12, vf - 0.16, vf + 0.3, g, g + WM_DOOR_H, WM_BLUE, M_LAMP)
				_ubox(u0, u1, vf - 0.16, vf + 0.3, g + WM_DOOR_H - 0.12, g + WM_DOOR_H, WM_BLUE, M_LAMP)
				# The rolled-up shutter's drum under the lintel.
				_ubox(u0, u1, vf + 0.3, vf + 0.9, g + WM_DOOR_H - 0.55, g + WM_DOOR_H, WM_SLAT)
	# The fascia: a black board with blue LED edges.
	var fu0: float = WM_HALL[0] + 0.8
	var fu1: float = WM_HALL[1] - 0.8
	_ubox(fu0, fu1, vf - 0.3, vf, g + 4.75, g + 6.25, WM_BOARD)
	for y: float in [g + 4.7, g + 6.22]:
		_ubox(fu0, fu1, vf - 0.34, vf - 0.26, y, y + 0.08, WM_BLUE, M_LAMP)


## A roller shutter between y0 and y1: grey with darker slats every 0.35 m.
func _wm_shutter(u0: float, u1: float, y0: float, y1: float, v: float) -> void:
	_ubox(u0, u1, v, v + 0.1, y0, y1, WM_DOOR)
	var y := y0 + 0.3
	while y < y1 - 0.1:
		_wm_face(u0, u1, v - 0.03, y, y + 0.05, WM_SLAT)
		y += 0.35


## Inside, seen through the open doors: the light lining, the floor, the strip lights, two
## two-post lifts (a blue hatchback being tuned; a stripped shell, no wheels, no bonnet, its doors
## off), a red tool chest and an engine on a stand.
func _wm_inside(g: float) -> void:
	var u0: float = WM_HALL[0] + 0.3
	var u1: float = WM_HALL[1] - 0.3
	var v0: float = WM_HALL[2] + 0.3
	var v1: float = WM_HALL[3] - 0.3
	var top := g + WM_H - 0.3
	_no_roof = true
	_ubox(u0, u1, v0, v1, g, g + 0.03, WM_FLOOR, M_STONE, WM_FLOOR)
	_ubox(u0, u1, v1 - 0.06, v1, g, top, WM_INSIDE)
	_soffit(_urect(u0, u1, v0, v1), top, WM_INSIDE.darkened(0.25))
	for u: float in [-6.4, -3.6, 0.3, 2.7]:
		_ubox(u - 0.07, u + 0.07, v0 + 1.0, v1 - 1.0, top - 0.12, top - 0.04, WM_WARM, M_LAMP)
	_no_roof = false
	for c: Vector2 in WM_LIFTS:
		_wm_lift(c, g)
	_wm_hatch(WM_LIFTS[0], 0.0, g + 1.63, Color("#2f72c8"))
	_wm_hatch(WM_LIFTS[1], 0.0, g + 1.63, WM_PRIMER, false)
	# The tool chest and the engine stand.
	_ubox(-10.8, -9.2, v1 - 0.9, v1 - 0.1, g, g + 1.15, Color("#c62f2a"), M_STONE, Color("#2a2a2e"))
	_ubox(-1.0, 0.0, 31.5, 32.3, g, g + 0.55, WM_BLACK)
	_ubox(-0.95, -0.05, 31.55, 32.25, g + 0.55, g + 1.25, Color("#5c6068"))


## A two-post lift: yellow posts on black feet, the arms under the car at 1.6 m.
func _wm_lift(c: Vector2, g: float) -> void:
	for s: float in [-1.75, 1.75]:
		_ubox(c.x + s - 0.18, c.x + s + 0.18, c.y - 0.2, c.y + 0.2, g, g + 3.9, WM_HAZARD)
		_ubox(c.x + s - 0.25, c.x + s + 0.25, c.y - 0.3, c.y + 0.3, g, g + 0.12, WM_BLACK)
		_ubox(minf(c.x + s, c.x) - 0.05, maxf(c.x + s, c.x) + 0.05, c.y - 0.8, c.y - 0.7, g + 1.58, g + 1.68, WM_BLACK)
		_ubox(minf(c.x + s, c.x) - 0.05, maxf(c.x + s, c.x) + 0.05, c.y + 0.7, c.y + 0.8, g + 1.58, g + 1.68, WM_BLACK)


## The roof: the slab, the chequered parapet on the front, low parapets round the rest, two
## air-conditioning boxes, and the meme car parked up there with its nose to the street.
func _wm_roof(g: float) -> void:
	var u0: float = WM_HALL[0]
	var u1: float = WM_HALL[1]
	var v0: float = WM_HALL[2]
	var v1: float = WM_HALL[3]
	var y := g + WM_H
	_ubox(u0 - 0.2, u1 + 0.2, v0 - 0.2, v1 + 0.2, y - 0.3, y, WM_ROOF)
	_ubox(u0 - 0.2, u1 + 0.2, v0 - 0.2, v0 + 0.1, y, y + 0.6, WM_BLACK)
	_ubox(u0 - 0.2, u0 + 0.1, v0 + 0.1, v1 + 0.2, y, y + 0.45, WM_WALL)
	_ubox(u1 - 0.1, u1 + 0.2, v0 + 0.1, v1 + 0.2, y, y + 0.45, WM_WALL)
	_ubox(u0 + 0.1, u1 - 0.1, v1 - 0.1, v1 + 0.2, y, y + 0.45, WM_WALL)
	# The chequer: two rows of 0.3 m squares on the front parapet's face.
	var k := 0
	var u := u0 - 0.2
	while u < u1 + 0.19:
		var w := minf(0.3, u1 + 0.2 - u)
		_wm_face(u, u + w, v0 - 0.25, y + (0.3 if k % 2 == 0 else 0.0), y + (0.6 if k % 2 == 0 else 0.3), WM_WHITE)
		u += w
		k += 1
	# Racing stripes down the roof (the building is tuned too), read from the camera above.
	_no_roof = true
	for su: Array in [[-9.4, -7.9], [-6.9, -5.4]]:
		_ubox(su[0], su[1], v0 + 0.15, v1 - 0.15, y, y + 0.03, WM_HAZARD, M_STONE, WM_HAZARD)
	_no_roof = false
	_ubox(-1.0, 1.4, 31.0, 33.0, y, y + 1.1, Color("#9aa0a8"))
	_ubox(-14.5, -12.5, 30.0, 31.6, y, y + 0.9, Color("#9aa0a8"))
	# The meme: a little cream hatchback, its front wheels at the edge, and ZROBI SIĘ! on two posts.
	var rc := Vector2(WM_ROOF_CAR.x, WM_ROOF_CAR.y)
	_wm_hatch(rc, WM_ROOF_CAR.z, y, Color("#e6d8b8"))
	for s: float in [-7.2, -1.2]:
		_ubox(s - 0.06, s + 0.06, v0 + 0.55, v0 + 0.67, y, y + 1.1, WM_BLACK)
	_ubox(-7.4, -1.0, v0 + 0.67, v0 + 0.75, y + 0.95, y + 2.1, WM_BOARD)


## A hatchback (the ones on the lifts, the one on the roof): a box body, a tapered cabin, four
## wheels, its lamps; heading `deg` (0: nose to -v), wheels' bottom at `y`. Not `whole`: stripped
## (no wheels, the engine bay open, a rusty door), the shell on the second lift.
func _wm_hatch(c: Vector2, deg: float, y: float, body: Color, whole := true) -> void:
	var wy := y
	_wm_box(c, deg, 1.85, 0.82, wy + 0.25, wy + 0.85, body)
	var low := _wm_ring(_wm_at(c, deg, -0.25, 0.0), deg, 1.2, 0.78)
	var high := _wm_ring(_wm_at(c, deg, -0.35, 0.0), deg, 0.85, 0.66)
	_frustum(low, wy + 0.85, high, wy + 1.4, WM_GLASS, body.darkened(0.05))
	if not whole:
		_wm_box(_wm_at(c, deg, 1.35, 0.0), deg, 0.45, 0.7, wy + 0.84, wy + 0.87, WM_BLACK)
		_wm_box(_wm_at(c, deg, 0.0, 0.83), deg, 0.5, 0.02, wy + 0.3, wy + 0.8, WM_RUST)
		return
	for a: float in [-1.2, 1.2]:
		for s: float in [-0.78, 0.78]:
			_wm_box(_wm_at(c, deg, a, s), deg, 0.3, 0.1, wy, wy + 0.6, WM_TYRE)
	# Lamps: white at the nose, red at the tail.
	for s: float in [-0.55, 0.55]:
		_wm_box(_wm_at(c, deg, 1.86, s), deg, 0.03, 0.14, wy + 0.6, wy + 0.75, WM_WARM, M_LAMP)
		_wm_box(_wm_at(c, deg, -1.86, s), deg, 0.03, 0.14, wy + 0.6, wy + 0.75, Color(1.0, 0.15, 0.1), M_LAMP)


## A lowered supercar on its spot: a wedge body, a low glass bubble, side scoops, a rear wing,
## fat wheels, headlights, and an underglow pad (glows at night).
func _wm_supercar(c: Vector2, deg: float, g: float, body: Color, glow: Color) -> void:
	var y := g + 0.05
	_no_roof = true
	_prism(_wm_ring(c, deg, 2.5, 1.2), y, y + 0.035, glow, glow, M_LAMP, M_LAMP)
	_no_roof = false
	# The body: a low tub, the nose lower than the tail.
	_wm_box(_wm_at(c, deg, -0.5, 0.0), deg, 1.8, 1.0, y + 0.18, y + 0.78, body)
	_frustum(_wm_ring(_wm_at(c, deg, 1.75, 0.0), deg, 0.55, 1.0), y + 0.18, _wm_ring(_wm_at(c, deg, 1.6, 0.0), deg, 0.5, 0.92),
			y + 0.55, body, body.darkened(0.08))
	var low := _wm_ring(_wm_at(c, deg, -0.2, 0.0), deg, 1.15, 0.85)
	var high := _wm_ring(_wm_at(c, deg, -0.45, 0.0), deg, 0.6, 0.6)
	_frustum(low, y + 0.78, high, y + 1.12, WM_GLASS, WM_GLASS.lightened(0.1))
	# The side scoops (black) and the wing on two struts.
	for s: float in [-1.0, 1.0]:
		_wm_box(_wm_at(c, deg, -0.6, s * 1.0), deg, 0.45, 0.03, y + 0.3, y + 0.65, WM_BLACK)
		_wm_box(_wm_at(c, deg, -2.0, s * 0.6), deg, 0.06, 0.04, y + 0.78, y + 1.15, WM_BLACK)
	_wm_box(_wm_at(c, deg, -2.05, 0.0), deg, 0.22, 0.95, y + 1.15, y + 1.22, WM_BLACK)
	for a: float in [-1.45, 1.35]:
		for s: float in [-0.92, 0.92]:
			_wm_box(_wm_at(c, deg, a, s), deg, 0.36, 0.16, y, y + 0.68, WM_TYRE)
	for s: float in [-0.65, 0.65]:
		_wm_box(_wm_at(c, deg, 2.27, s), deg, 0.04, 0.2, y + 0.42, y + 0.5, WM_WARM, M_LAMP)
	_wm_box(_wm_at(c, deg, -2.31, 0.0), deg, 0.02, 0.85, y + 0.6, y + 0.66, Color(1.0, 0.15, 0.1), M_LAMP)


## The stripped car: a primer shell on four axle stands, no wheels, no bonnet (the engine bay a
## black hole), one red door; its engine on a pallet beside it, its wheels stacked by the wall.
func _wm_wreck(g: float) -> void:
	var c := Vector2(WM_WRECK.x, WM_WRECK.y)
	var deg := WM_WRECK.z
	var y := g + 0.05
	for a: float in [-1.2, 1.2]:
		for s: float in [-0.6, 0.6]:
			_wm_box(_wm_at(c, deg, a, s), deg, 0.12, 0.12, y, y + 0.55, Color("#b3302a"))
	_wm_box(c, deg, 2.0, 0.85, y + 0.55, y + 1.05, WM_PRIMER)
	_wm_box(_wm_at(c, deg, 1.4, 0.0), deg, 0.55, 0.7, y + 1.0, y + 1.06, WM_BLACK)
	_wm_box(_wm_at(c, deg, -0.1, 0.86), deg, 0.55, 0.02, y + 0.6, y + 1.0, Color("#c62f2a"))
	_wm_box(_wm_at(c, deg, -0.2, -0.86), deg, 0.5, 0.02, y + 0.62, y + 0.98, WM_RUST)
	var low := _wm_ring(_wm_at(c, deg, -0.35, 0.0), deg, 1.2, 0.8)
	var high := _wm_ring(_wm_at(c, deg, -0.45, 0.0), deg, 0.85, 0.66)
	_frustum(low, y + 1.05, high, y + 1.55, WM_GLASS.lightened(0.15), WM_PRIMER)
	# The engine on its pallet, the bonnet leaning on the wall.
	var e := _wm_at(c, deg, 1.0, 2.0)
	_wm_box(e, deg, 0.6, 0.5, y, y + 0.14, Color("#a07a4e"))
	_wm_box(e, deg, 0.35, 0.3, y + 0.14, y + 0.75, Color("#4a4d52"))
	_ubox(WM_HALL[0] - 0.25, WM_HALL[0] - 0.05, 30.5, 31.9, g + 0.05, g + 1.5, WM_PRIMER)


## The Bawarka (F's meme: "BMWs that drink oil"): a dark saloon with the twin grille, bonnet up,
## standing in a black puddle, a pyramid of oil cans beside it and, on two posts towards the road,
## a board with OLEJ DO BAWARKI (oil for the Bavarian) in yellow neon.
func _wm_bawarka(g: float) -> void:
	var c := Vector2(WM_BAWARKA.x, WM_BAWARKA.y)
	var deg := WM_BAWARKA.z
	var y := g + 0.05
	var body := Color("#1f2a44")
	_no_roof = true
	_prism(_circle(_w(_wm_at(c, deg, 1.4, 0.2).x, _wm_at(c, deg, 1.4, 0.2).y), 1.25, 10), y, y + 0.035, Color("#0b0b0e"), Color("#0b0b0e"))
	_no_roof = false
	_wm_box(c, deg, 2.35, 0.9, y + 0.25, y + 0.85, body)
	var low := _wm_ring(_wm_at(c, deg, -0.3, 0.0), deg, 1.3, 0.85)
	var high := _wm_ring(_wm_at(c, deg, -0.4, 0.0), deg, 0.85, 0.72)
	_frustum(low, y + 0.85, high, y + 1.38, WM_GLASS, body.darkened(0.1))
	for a: float in [-1.5, 1.5]:
		for s: float in [-0.86, 0.86]:
			_wm_box(_wm_at(c, deg, a, s), deg, 0.33, 0.11, y, y + 0.66, WM_TYRE)
	# The twin grille, chrome-edged, and the bonnet propped up over the open bay.
	for s: float in [-0.2, 0.2]:
		_wm_box(_wm_at(c, deg, 2.36, s), deg, 0.03, 0.16, y + 0.5, y + 0.78, Color("#c9ccd2"))
		_wm_box(_wm_at(c, deg, 2.38, s), deg, 0.02, 0.11, y + 0.54, y + 0.74, WM_BLACK)
	_wm_box(_wm_at(c, deg, 1.45, 0.0), deg, 0.75, 0.75, y + 0.84, y + 0.87, WM_BLACK)
	_wm_box(_wm_at(c, deg, 0.68, 0.0), deg, 0.04, 0.84, y + 0.86, y + 1.85, body.lightened(0.05))
	for s: float in [-0.6, 0.6]:
		_wm_box(_wm_at(c, deg, 2.36, s), deg, 0.03, 0.17, y + 0.6, y + 0.72, WM_WARM, M_LAMP)
	# The oil cans: a pyramid of yellow 5-litre cans by the front wheel.
	var k := _wm_at(c, deg, 1.9, 1.6)
	for row: Array in [[0.0, [-0.36, -0.12, 0.12, 0.36]], [0.34, [-0.24, 0.0, 0.24]], [0.68, [-0.12, 0.12]], [1.02, [0.0]]]:
		for o: float in row[1]:
			var p := _wm_at(k, deg, 0.0, o)
			_ubox(p.x - 0.1, p.x + 0.1, p.y - 0.13, p.y + 0.13, y + float(row[0]), y + float(row[0]) + 0.32, WM_YELLOW.darkened(0.08))
	# The board towards the road.
	for s: float in [-3.0, 3.0]:
		_ubox(c.x + s - 0.06, c.x + s + 0.06, 21.55, 21.67, g, g + 3.4, WM_BLACK)
	_ubox(c.x - 3.1, c.x + 3.1, 21.67, 21.75, g + 2.35, g + 3.4, WM_BOARD)


## The yard's clutter: tyre stacks along the west wall, oil drums, a pile of wheels by the wreck.
func _wm_yard(g: float) -> void:
	var y := g + 0.05
	for t: Array in [[-17.65, 22.0, 5], [-17.65, 22.8, 4], [-18.45, 22.4, 3], [-17.65, 33.6, 5], [-18.45, 33.6, 4],
			[-26.5, 30.6, 4], [-27.3, 31.2, 3]]:
		_wm_tyres(t[0], t[1], y, t[2])
	for d: Array in [[-18.0, 25.2, Color("#2f6fd0")], [-18.0, 25.9, Color("#c62f2a")], [-18.7, 25.55, Color("#2f6fd0")]]:
		_prism(_circle(_w(d[0], d[1]), 0.29, 8), y, y + 0.9, d[2], (d[2] as Color).darkened(0.25), M_STONE, M_STONE)


## Two floodlight masts at the hall's front corners, their lit heads over the forecourt.
func _wm_masts(g: float) -> void:
	for m: Vector2 in [Vector2(WM_HALL[0] - 0.6, WM_HALL[2] - 0.6), Vector2(WM_HALL[1] + 0.6, WM_HALL[2] - 0.6)]:
		_ubox(m.x - 0.09, m.x + 0.09, m.y - 0.09, m.y + 0.09, g, g + 7.6, Color("#4a4e56"))
		_ubox(m.x - 0.6, m.x + 0.6, m.y - 0.75, m.y + 0.05, g + 7.5, g + 7.85, WM_BLACK)
		_ubox(m.x - 0.55, m.x + 0.55, m.y - 0.7, m.y, g + 7.42, g + 7.5, WM_WARM, M_LAMP)
