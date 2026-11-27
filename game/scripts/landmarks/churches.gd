extends "res://scripts/landmarks/common.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the churches: the church kit
## (CHURCHES) and every church built from photos. Moved as it was from the one big file.
## landmarks.gd is the class the game makes; every file of game/scripts/landmarks/ is one link of
## its base chain (facade_kit.gd, common.gd, then the areas in the order of landmarks.gd's `extends`
## chain), so code here may use this file, common.gd and the facade kit, never another area: a
## helper two areas need goes to common.gd.


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

## Three named buildings brought from skins (or LoD2 alone) to models, each to its spec in
## docs/landmarks/specs/ (trojca.md, zacheta.md, prezydencki.md). Measured in a cloud thread from
## the OpenStreetMap outlines, GUGiK's LoD2 heights and the user's photo of Zachęta (with the
## church's dome beside it); the values the specs mark *(photo check)* wait for the Mac's photos.
##
## Holy Trinity (Kościół Ewangelicko-Augsburski Świętej Trójcy, Szymon Bogumił Zug, 1777-1781),
## rebuilt 2026-11-14 from street photos (Mapillary: the north-west portico and the drum close up,
## the dome and lantern from Plac Piłsudskiego) and LoD2 (spec trojca.md): a white rotunda on a
## Greek cross. The lower drum is rusticated (horizontal courses) with tall round-arched windows,
## two in each quarter; a dentilled band; the upper drum banded too, with eight framed oculi
## (over each portico and on the diagonals) between small round paterae; the entablature and a
## cornice. On each arm a portico of four fluted Doric columns, a triglyph frieze and a pediment
## with a lunette, a door under a gilt glory in an arched niche behind. A low copper dome with
## small dormers, a glazed lantern of piers on a collar, an overhanging cornice, a ribbed cap, a
## knob and a cross (58 m). The drum's rings turn with the arms, so a flat facet faces each
## window. The drum's centre and radius are a circle fitted to its mapped outline; the arms'
## faces are the outline's.
const TROJCA := Vector2(-854.6, -508.6)
const TROJCA_TURN := -24.6      # degrees: the arm towards the square (ENE)
const TROJCA_R := 16.7
## Each arm: its turn from TROJCA_TURN and how far its portico's front stands from the centre.
const TROJCA_ARMS := [[0.0, 21.8], [90.0, 24.1], [180.0, 21.7], [270.0, 21.3]]
## The dome's profile over the drum's cornice: [radius, height above ground] (LoD2: 29.4 m at
## r 15, 34.1 m at r 11, 36.9 m at r 8, the lantern's foot 37.9 m).
const TROJCA_DOME := [[16.6, 26.6], [15.6, 29.0], [14.0, 31.6], [11.5, 34.0], [8.5, 36.4], [5.6, 37.5]]
const TROJCA_WHITE := Color("#e9e7e1")
const TROJCA_GROOVE := Color("#bdb9af")
const TROJCA_PLINTH := Color("#a9a59d")
const TROJCA_COPPER := Color("#79a796")
const TROJCA_COPPER_DARK := Color("#557f72")
const TROJCA_ROOF := Color("#6d7377")
const TROJCA_GLASS := Color("#3c4a52")
const TROJCA_DOOR := Color("#4a3a2e")
const TROJCA_GOLD := Color("#c9a24a")


func _find_trojca() -> void:
	_add_site("trojca", [_circle(TROJCA, 25.5, 24)])


## A ring round the drum's centre turned with the arms: with n = 32 a flat facet faces each arm,
## each diagonal and every 11.25 degrees between.
func _trojca_ring(r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var t := deg_to_rad(TROJCA_TURN)
	for k in n:
		out.append(TROJCA + Vector2.from_angle(t + TAU * (k + 0.5) / n) * r)
	return out


func _build_trojca(_site: Dictionary) -> void:
	var c := TROJCA
	var r := TROJCA_R
	_g = _ground_under(_circle(c, r, 8))
	var g := _g
	var none := Color(0, 0, 0, 0)
	var light := TROJCA_WHITE.lightened(0.06)
	var apo := r * cos(PI / 32.0)   # the facets' distance from the centre
	# plinth, the rusticated lower drum, the dentilled band, the upper drum, the entablature
	_prism(_trojca_ring(r + 0.3, 32), g - 0.5, g + 1.0, TROJCA_PLINTH, TROJCA_PLINTH, M_STONE, M_STONE)
	_prism(_trojca_ring(r, 32), g + 1.0, g + 13.0, TROJCA_WHITE, none, M_STONE)
	_prism(_trojca_ring(r + 0.18, 32), g + 12.75, g + 13.0, TROJCA_GROOVE, none, M_STONE)
	_prism(_trojca_ring(r + 0.32, 32), g + 13.0, g + 13.9, light, light, M_STONE, M_STONE)
	_prism(_trojca_ring(r, 32), g + 13.9, g + 24.4, TROJCA_WHITE, none, M_STONE)
	_prism(_trojca_ring(r + 0.15, 32), g + 24.4, g + 25.0, light, none, M_STONE)
	_prism(_trojca_ring(r + 0.1, 32), g + 25.0, g + 25.8, TROJCA_WHITE, none, M_STONE)
	_prism(_trojca_ring(r + 0.6, 32), g + 25.8, g + 26.6, light, TROJCA_COPPER_DARK, M_STONE, M_STONE)
	# the courses: a shadow line every 2.4 m below, every 1.5 m above (the oculi's frames cover them)
	for y: float in [3.4, 5.8, 8.2, 10.6, 16.4, 17.9, 21.4, 22.9]:
		_prism(_trojca_ring(r + 0.02, 32), g + y, g + y + 0.16, TROJCA_GROOVE, none, M_STONE)
	var t0 := deg_to_rad(TROJCA_TURN)
	# two arched windows in each quarter, 11.25 degrees either side of the diagonal
	for q in 4:
		for off: float in [33.75, 56.25]:
			var d := Vector2.from_angle(t0 + deg_to_rad(90.0 * q + off))
			var along := Vector2(-d.y, d.x)
			var p := c + d * apo
			_arch_panel(p, along, d, 1.75, g + 2.2, g + 9.6, light, 0.04, M_STONE)
			_arch_panel(p, along, d, 1.4, g + 2.5, g + 9.6, TROJCA_GLASS, 0.08, _lit(90.0 * q + off, 2.5))
			var kp := p + d * 0.1
			_prism(PackedVector2Array([kp - along * 0.3, kp + along * 0.3, kp + along * 0.3 + d * 0.25,
					kp - along * 0.3 + d * 0.25]), g + 10.6, g + 11.6, light, light, M_STONE, M_STONE)
	# eight oculi, over each portico and on the diagonals: a framed round window, a patera above
	# and below, on a raised panel
	for k in 8:
		var d := Vector2.from_angle(t0 + deg_to_rad(45.0 * k))
		var along := Vector2(-d.y, d.x)
		var p := c + d * apo
		_prism(PackedVector2Array([p - along * 2.0, p + along * 2.0, p + along * 2.0 + d * 0.14,
				p - along * 2.0 + d * 0.14]), g + 15.2, g + 24.3, light, none, M_STONE)
		var o := Vector3(d.x, 0.0, d.y)
		var at := Vector3(p.x, g + 19.6, p.y)
		_disc(at + o * 0.16, o, 2.05, 12, TROJCA_GROOVE)
		_disc(at + o * 0.2, o, 1.8, 12, light)
		_mode = _lit(45.0 * k, 19.6)
		_disc(at + o * 0.24, o, 1.45, 12, TROJCA_GLASS)
		_mode = M_STONE
		for dy: float in [-2.75, 2.75]:
			_disc(at + o * 0.2 + Vector3.UP * dy, o, 0.42, 6, TROJCA_GROOVE)
	# the dome, its small dormers on the lower slope
	_mode = M_STONE
	for k in TROJCA_DOME.size() - 1:
		var a: Array = TROJCA_DOME[k]
		var b: Array = TROJCA_DOME[k + 1]
		var col := TROJCA_COPPER.lerp(TROJCA_COPPER.lightened(0.1), float(k) / TROJCA_DOME.size())
		_frustum(_trojca_ring(a[0], 32), g + float(a[1]), _trojca_ring(b[0], 32), g + float(b[1]), col)
	for k in 8:
		_o = c
		_a = Vector2.from_angle(t0 + deg_to_rad(22.5 + 45.0 * k))
		_b = Vector2(-_a.y, _a.x)
		_lbox(15.0, 0.0, 0.5, 0.5, g + 29.0, g + 30.6, TROJCA_COPPER_DARK, M_STONE, none)
		_mode = _lit(float(k), 29.5)
		_wall(_w(15.52, -0.3), _w(15.52, 0.3), g + 29.5, g + 30.3, _a, TROJCA_GLASS)
		_mode = M_STONE
		_gable(15.5, 14.3, 0.0, 0.55, g + 30.6, 0.5, TROJCA_COPPER_DARK, TROJCA_COPPER_DARK, false)
	# lantern: a collar, the glazed drum between eight piers, an overhanging cornice, the ribbed
	# cap, a knob and the cross
	_prism(_trojca_ring(5.0, 16), g + 37.3, g + 39.6, TROJCA_COPPER_DARK, TROJCA_COPPER_DARK, M_STONE, M_STONE)
	_prism(_trojca_ring(5.15, 16), g + 39.6, g + 39.9, TROJCA_COPPER_DARK.darkened(0.2), none, M_STONE)
	_prism(_trojca_ring(4.4, 16), g + 39.6, g + 47.6, TROJCA_COPPER, none, M_MONUMENT)
	for k in 8:
		_o = c
		_a = Vector2.from_angle(t0 + deg_to_rad(45.0 * k))
		_b = Vector2(-_a.y, _a.x)
		_lbox(4.45, 0.0, 0.3, 0.32, g + 39.9, g + 47.6, TROJCA_COPPER_DARK, M_STONE, none)
	_prism(_trojca_ring(5.3, 16), g + 47.6, g + 48.4, TROJCA_COPPER_DARK, none, M_STONE)
	_mode = M_STONE
	_frustum(_trojca_ring(5.3, 16), g + 48.4, _trojca_ring(3.7, 16), g + 49.7, TROJCA_COPPER)
	_frustum(_trojca_ring(3.7, 16), g + 49.7, _trojca_ring(1.7, 16), g + 50.9, TROJCA_COPPER.lightened(0.05))
	_frustum(_trojca_ring(1.7, 16), g + 50.9, _trojca_ring(0.35, 16), g + 51.7, TROJCA_COPPER.lightened(0.1), TROJCA_COPPER)
	_prism(_circle(c, 0.45, 6), g + 51.7, g + 52.6, TROJCA_GOLD, TROJCA_GOLD, M_STONE, M_STONE)
	_o = c
	_a = Vector2.from_angle(t0)
	_b = Vector2(-_a.y, _a.x)
	_lbox(0.0, 0.0, 0.11, 0.11, g + 52.6, g + 57.0, TROJCA_GOLD, M_STONE, TROJCA_GOLD)
	_lbox(0.0, 0.0, 0.11, 0.8, g + 55.4, g + 55.64, TROJCA_GOLD, M_STONE, TROJCA_GOLD)
	# arms: the vestibule with its door under a gilt glory, the stylobate, four fluted Doric
	# columns, the entablature with triglyphs, the pediment with a lunette under a grey roof
	var ring := _circle(c, r + 0.3, 32)
	for arm: Array in TROJCA_ARMS:
		_o = c
		_a = Vector2.from_angle(t0 + deg_to_rad(float(arm[0])))
		_b = Vector2(-_a.y, _a.x)
		var face: float = arm[1]
		var back := face - 4.2
		_lbox((r - 2.0 + back) * 0.5, 0.0, (back - r + 2.0) * 0.5, 6.0, g - 0.5, g + 15.0, TROJCA_WHITE, M_STONE, TROJCA_ROOF)
		_mode = M_STONE
		_arch_panel(_w(back, 0.0), _b, _a, 2.3, g + 1.1, g + 6.4, TROJCA_WHITE.darkened(0.12), 0.04, M_STONE)
		_wall(_w(back + 0.08, -1.2), _w(back + 0.08, 1.2), g + 1.1, g + 5.0, _a, TROJCA_DOOR)
		_arch_cap(Vector3(_w(back + 0.08, 0.0).x, g + 6.4, _w(back + 0.08, 0.0).y), Vector3(_a.x, 0.0, _a.y), 1.6, 8, TROJCA_GOLD)
		for k in 3:
			_lbox(back + 2.1, 0.0, 2.1 + 0.3 * (2 - k), 6.8 + 0.3 * (2 - k), g - 0.5 + 0.0 * k, g + 0.4 + 0.35 * k,
					TROJCA_PLINTH, M_STONE, TROJCA_PLINTH.lightened(0.1))
		for v: float in [-5.0, -1.85, 1.85, 5.0]:
			_column(face - 0.9, v, 0.68, g + 1.1, g + 12.0, TROJCA_WHITE)
		_lbox(back + 2.2, 0.0, 2.2, 6.4, g + 12.0, g + 12.9, light, M_STONE, none)
		_lbox(back + 2.2, 0.0, 2.15, 6.35, g + 12.9, g + 14.1, TROJCA_WHITE, M_STONE, none)
		for k in 7:
			var v := -5.0 + float(k) * 5.0 / 3.0
			_lbox(face + 0.21, v, 0.06, 0.25, g + 12.95, g + 14.05, TROJCA_GROOVE, M_STONE, none)
		_lbox(back + 2.4, 0.0, 2.4, 6.7, g + 14.1, g + 15.0, light, M_STONE, TROJCA_ROOF)
		_gable(face + 0.2, r - 2.0, 0.0, 6.7, g + 15.0, 3.0, TROJCA_WHITE, TROJCA_ROOF, false)
		_mode = M_STONE
		var lun := _w(face + 0.25, 0.0)
		_arch_cap(Vector3(lun.x, g + 15.35, lun.y), Vector3(_a.x, 0.0, _a.y), 1.5, 6, light)
		_mode = _lit(float(arm[0]), 15.4)
		_arch_cap(Vector3(lun.x + _a.x * 0.04, g + 15.45, lun.y + _a.y * 0.04), Vector3(_a.x, 0.0, _a.y), 1.2, 6, TROJCA_GLASS)
		_mode = M_STONE
		var arm_ring := _rect((r - 2.0 + face) * 0.5, 0.0, (face - r + 2.0) * 0.5, 7.4)
		var merged := Geometry2D.merge_polygons(ring, arm_ring)
		if not merged.is_empty():
			ring = _largest(merged)
	_collide(ring)


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

## The Church of the Holy Cross (Kościół Świętego Krzyża; Bellotti's baroque facade, 1679-1696) on
## Krakowskie Przedmieście: the nave stays LoD2's (a kept skin); the model adds the street
## front, a central block with four giant columns and statues on the entablature, an upper
## storey and a pediment, between two square towers with belfries and copper onion helms
## with lanterns and crosses. Spec docs/landmarks/specs/krzyz.md.
## Frame: origin at the front's south end on the outline, u north along the front (31 m),
## +v out of it to the street (east); the towers reach back to v -8.7.
const KRZYZ := Vector2(-456.1, -510.0)
const KRZYZ_AXIS := Vector2(-0.323, -0.946)
const KRZYZ_MID := 15.65
const KRZYZ_WALL := Color("#eee7d3")   # F's photo T09-02: whiter than first guessed
const KRZYZ_TRIM := Color("#f1ebdc")
const KRZYZ_BASE := Color("#bdb39c")
const KRZYZ_COPPER := Color("#5a8a78")
const KRZYZ_GOLD := Color("#c9a24a")
const KRZYZ_DOOR := Color("#3a3d40")
const KRZYZ_DOOR_WOOD := Color("#6e4228")   # photo 2: the oak doors
const KRZYZ_PORTAL := Color("#b9ad94")     # the portal columns (photo 1: grey stone)
const KRZYZ_BLACK := Color("#1f2226")      # the Sursum corda plinth
const KRZYZ_BRONZE := Color("#3d3f3b")


func _build_krzyz(_site: Dictionary) -> void:
	_o = KRZYZ
	_a = KRZYZ_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (0.946, -0.323): out of the front, to the street
	var m := KRZYZ_MID
	_g = map.terrain_height(_w(m, 1.0).x, _w(m, 1.0).y)
	var g := _g
	_mode = M_STONE
	for cu: float in [4.4, 2.0 * m - 4.4]:
		_krzyz_tower(cu)
	# From the photos (refs/sw_krzyz 1-2): NO giant portico. The front between the towers is a flat
	# two-storey baroque wall with paired pilasters; a small portal under a pediment on two
	# columns in the middle, pedimented windows in the lower storey, a very tall round-headed
	# window and capped windows in the upper one, a cornice, and a curved, stepped attic with the
	# gilt cross. In front a stone balustrade the whole width with the steps in the middle, and the
	# black "Sursum corda" plinth with the bronze Christ carrying the cross beside the portal.
	_lbox(m, 0.125, 6.75, 0.225, g - 0.6, g + 10.0, KRZYZ_WALL, M_STONE, KRZYZ_WALL)
	_lbox(m, 0.3, 6.95, 0.35, g + 10.0, g + 11.0, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_lbox(m, 0.3, 6.75, 0.3, g + 11.0, g + 19.0, KRZYZ_WALL, M_MONUMENT, KRZYZ_WALL)
	_lbox(m, 0.3, 7.0, 0.5, g - 0.6, g + 1.6, KRZYZ_BASE, M_STONE, KRZYZ_BASE.lightened(0.05))
	_lbox(m, 0.5, 7.2, 0.7, g + 19.0, g + 20.0, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	# paired pilasters
	for pu: float in [-6.4, -5.5, -2.9, 2.9, 5.5, 6.4]:
		_lbox(m + pu, 0.5, 0.32, 0.3, g + 1.6, g + 19.0, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	# windows: lower pedimented pair, upper capped pair, the great round-headed one
	_mode = M_GLASS
	for wu: float in [-4.2, 4.2]:
		_wall(_w(m + wu - 0.8, 0.42), _w(m + wu + 0.8, 0.42), g + 3.0, g + 7.0, _b, KRZYZ_DOOR)
		_wall(_w(m + wu - 0.8, 0.42), _w(m + wu + 0.8, 0.42), g + 12.4, g + 16.6, _b, KRZYZ_DOOR)
	_arch_panel(_w(m, 0.42), _a, _b, 1.5, g + 11.8, g + 15.6, KRZYZ_DOOR, 0.03, M_GLASS)
	for u: float in [-5.8, 5.8]:
		_wall(_w(m + u - 0.6, 0.42), _w(m + u + 0.6, 0.42), g + 1.8, g + 5.0, _b, KRZYZ_DOOR_WOOD)
	_mode = M_STONE
	for wu: float in [-4.2, 4.2]:
		_lbox(m + wu, 0.5, 1.1, 0.2, g + 7.0, g + 7.4, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
		_lbox(m + wu, 0.5, 0.7, 0.2, g + 7.4, g + 7.9, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
		_lbox(m + wu, 0.5, 1.1, 0.2, g + 16.6, g + 17.1, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	# the portal: the great door, two columns, entablature and a small pediment
	_mode = M_GLASS
	_wall(_w(m - 1.3, 0.4), _w(m + 1.3, 0.4), g + 1.6, g + 6.0, _b, KRZYZ_DOOR_WOOD)
	_mode = M_STONE
	for pu: float in [-1.9, 1.9]:
		_column(m + pu, 1.9, 0.38, g + 1.2, g + 6.2, KRZYZ_PORTAL)
	_lbox(m, 1.5, 2.7, 1.5, g + 6.2, g + 7.0, KRZYZ_WALL, M_STONE, KRZYZ_TRIM)
	var kp := _a
	var kq := _b
	_a = kq
	_b = kp
	_gable(2.9, 0.6, m, 2.9, g + 7.0, 1.5, KRZYZ_WALL, KRZYZ_PORTAL)
	_a = kp
	_b = kq
	_lbox(m, 1.6, 2.7, 1.6, g - 0.6, g + 1.2, KRZYZ_BASE, M_STONE, KRZYZ_BASE.lightened(0.05))
	for k in 2:
		_lbox(m, 3.7 + 0.5 * k, 3.0 - 0.3 * k, 0.4 + 0.5 * k, g - 0.6, g + 0.8 - 0.4 * k, KRZYZ_BASE, M_STONE,
				KRZYZ_BASE.lightened(0.04))
	# the balustrade across the front, open at the steps
	for side: float in [-1.0, 1.0]:
		_lbox(m + side * (m + 2.1) * 0.5, 4.8, (m - 2.7) * 0.5, 0.22, g, g + 1.0, KRZYZ_BASE.lightened(0.05), M_STONE, KRZYZ_TRIM)
	# the curved, stepped attic and the gilt cross
	var ka := _a
	var kb := _b
	_lbox(m, 0.4, 4.2, 0.6, g + 20.0, g + 21.0, KRZYZ_WALL, M_STONE, KRZYZ_TRIM)
	_lbox(m, 0.4, 3.0, 0.6, g + 21.0, g + 22.0, KRZYZ_WALL, M_STONE, KRZYZ_TRIM)
	_lbox(m, 0.4, 1.6, 0.6, g + 22.0, g + 22.9, KRZYZ_WALL, M_STONE, KRZYZ_TRIM)
	for su: float in [-1.0, 1.0]:
		_lbox(m + su * 5.3, 0.4, 0.6, 0.5, g + 20.0, g + 21.6, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_lbox(m, 0.4, 0.15, 0.15, g + 22.9, g + 25.8, KRZYZ_GOLD, M_STONE, KRZYZ_GOLD)
	_lbox(m, 0.4, 0.7, 0.15, g + 24.2, g + 24.6, KRZYZ_GOLD, M_STONE, KRZYZ_GOLD)
	_a = ka
	_b = kb
	# "Sursum corda": the black plinth and the bronze Christ with the cross (photo 1)
	_lbox(m - 5.2, 5.6, 0.9, 0.9, g - 0.3, g + 2.4, KRZYZ_BLACK, M_STONE, KRZYZ_BLACK.lightened(0.04))
	_lbox(m - 5.2, 5.6, 0.4, 0.3, g + 2.4, g + 5.0, KRZYZ_BRONZE, M_STONE, KRZYZ_BRONZE.lightened(0.05))
	var x0 := _w(m - 5.7, 5.5)
	var x1 := _w(m - 4.6, 5.9)
	_beam(Vector3(x0.x, g + 2.6, x0.y), Vector3(x1.x, g + 5.9, x1.y), 0.28, KRZYZ_BRONZE)
	_collide(_rect(m - 5.2, 5.6, 0.9, 0.9))
	# the car meets the stylobate and the columns
	_collide(_rect(m, 1.5, 6.9, 1.4))


## One of the two towers: plinth, shaft with a window band, cornice, belfry between corner
## piers, then the copper helm: an octagonal drum, the onion swell, the lantern, a cap and a
## gilt ball and cross (48.5 m to the tip).
func _krzyz_tower(cu: float) -> void:
	var g := _g
	var cv := -4.2
	_lbox(cu, cv, 4.55, 4.75, g - 0.6, g + 1.6, KRZYZ_BASE, M_STONE, KRZYZ_BASE.lightened(0.05))
	_lbox(cu, cv, 4.3, 4.5, g + 1.6, g + 13.0, KRZYZ_WALL, M_STONE, KRZYZ_WALL)
	_lbox(cu, cv, 4.55, 4.75, g + 13.0, g + 13.8, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_lbox(cu, cv, 4.3, 4.5, g + 13.8, g + 22.0, KRZYZ_WALL, M_STONE, KRZYZ_WALL)
	for qu: float in [-1.0, 1.0]:  # corner pilasters up both stages (photo 2)
		for qv: float in [-1.0, 1.0]:
			_lbox(cu + qu * 4.0, cv + qv * 4.2, 0.55, 0.55, g + 1.6, g + 22.0, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_mode = M_GLASS
	_wall(_w(cu - 0.8, 0.33), _w(cu + 0.8, 0.33), g + 16.4, g + 20.4, _b, KRZYZ_DOOR)
	_wall(_w(cu - 0.8, -8.73), _w(cu + 0.8, -8.73), g + 16.4, g + 20.4, -_b, KRZYZ_DOOR)
	_mode = M_STONE
	_lbox(cu, cv, 4.7, 4.9, g + 22.0, g + 22.8, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_lbox(cu, cv, 4.5, 4.7, g + 22.8, g + 23.4, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	# the belfry: open arches (the monument shader's windows) between four corner piers
	_lbox(cu, cv, 3.6, 3.8, g + 23.4, g + 31.4, KRZYZ_WALL, M_MONUMENT, KRZYZ_WALL)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(cu + su * 3.5, cv + sv * 3.7, 0.55, 0.55, g + 23.4, g + 31.4, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	_lbox(cu, cv, 4.1, 4.3, g + 31.4, g + 32.3, KRZYZ_TRIM, M_STONE, KRZYZ_TRIM)
	# the helm
	var c := _w(cu, cv)
	_mode = M_STONE
	# F's front photo (T09-02, 2026-11-08): no big onion but an octagonal copper lantern with
	# arched openings, a bell roof, a small bulb and a slim needle to the gilt ball and cross
	_prism(_circle(c, 3.0, 8), g + 32.3, g + 36.5, KRZYZ_COPPER, KRZYZ_COPPER, M_MONUMENT, M_STONE)
	var prof := [[3.4, 36.5], [3.2, 37.2], [2.0, 38.4], [0.7, 39.2], [1.1, 39.9], [0.3, 40.8]]
	for k in prof.size() - 1:
		_frustum(_circle(c, float(prof[k][0]), 8), g + float(prof[k][1]), _circle(c, float(prof[k + 1][0]), 8),
				g + float(prof[k + 1][1]), KRZYZ_COPPER.lightened(0.03 * k), KRZYZ_COPPER)
	_frustum(_circle(c, 0.22, 6), g + 40.8, _circle(c, 0.06, 6), g + 45.0, KRZYZ_COPPER, KRZYZ_COPPER)
	_lbox(cu, cv, 0.3, 0.3, g + 45.0, g + 45.6, KRZYZ_GOLD, M_STONE, KRZYZ_GOLD)
	_lbox(cu, cv, 0.18, 0.18, g + 45.6, g + 48.6, KRZYZ_GOLD, M_STONE, KRZYZ_GOLD)
	_lbox(cu, cv, 0.7, 0.18, g + 47.2, g + 47.6, KRZYZ_GOLD, M_STONE, KRZYZ_GOLD)


## St Alexander's church (Kościół Świętego Aleksandra; Chrystian Piotr Aigner's rotunda of
## 1818-1825 in the middle of Plac Trzech Krzyży, given towers in the 1890s, burnt in 1944 and
## rebuilt in Aigner's form without them). Rebuilt 2026-11-13 from Mapillary photos (refs/aleksander,
## never shipped), F's photos (top-50 T23) and the GUGiK LoD2 heights (eaves 13.8 m, upper drum 18.9 m, dome 25.7 m).
## Spec docs/landmarks/specs/aleksander.md. White plaster, copper-flashed cornices, a green copper dome:
## - a stepped stone podium round the whole church;
## - a tall blank lower drum (no windows) with a string course and a dentilled cornice in line
##   with the porticoes' entablature, then a plain set-back band;
## - a lower, set-back upper drum where round-headed windows alternate with blind arched niches,
##   its own cornice, a plain attic ring and the low dome with a small cross on top (no lantern);
## - a portico of six Corinthian columns on each end of the long axis (one more column on each
##   side behind the corner ones), a pediment with a cross, a cella front with a big door and two
##   side doors, small windows in the cella block's sides, and steps down to the square.
## Frame: origin at the rotunda's centre, u along the long axis to the north (Nowy Świat), +v east.
const ALEKS := Vector2(-110.8, 541.7)
const ALEKS_AXIS := Vector2(-0.232, -0.973)
const ALEKS_R := 11.3            ## the lower drum (a circle fitted to the outline's arcs)
const ALEKS_UP_R := 10.2         ## the upper drum
const ALEKS_HALF := 6.4          ## the porticoes' half width (the outline)
const ALEKS_ENDS := [18.0, -17.4]
const ALEKS_PODIUM := 0.8        ## the podium's top above the street
const ALEKS_FLOOR := 1.4         ## the porticoes' floor
const ALEKS_WALL := Color("#f1f0eb")    ## white plaster (F's photos: white, not cream)
const ALEKS_TRIM := Color("#faf9f5")    ## cornices, columns, surrounds
const ALEKS_NICHE := Color("#dedcd4")   ## the blind niches' shade
const ALEKS_BASE := PAL_PALE_CONCRETE    ## the plinth band
const ALEKS_LEDGE := Color("#7aa892")   ## the copper flashing on the cornices' tops (the aerial)
const ALEKS_STEP := PAL_GREY_STONE    ## granite steps and podium
const ALEKS_COPPER := PAL_PATINA_COPPER  ## the dome's green copper
const ALEKS_ROOF := Color("#5f8a76")    ## the porticoes' copper roofs
const ALEKS_DARK := PAL_GLASS_DARK
const ALEKS_DOOR := PAL_OAK
const ALEKS_IRON := PAL_IRON    ## the crosses (they read dark against the sky)
## The dome over the attic: [radius, height above the street] (LoD2: apex 25.7 m).
const ALEKS_DOME := [[9.6, 20.0], [9.1, 20.9], [8.0, 21.9], [6.4, 22.9], [4.5, 23.8], [2.4, 24.6], [0.7, 25.0]]
## A portico's column spots across it (v) and the return columns' setback from the front.
const ALEKS_COLS := [-5.75, -3.45, -1.15, 1.15, 3.45, 5.75]
const ALEKS_RETURN := 2.3


func _find_aleksander() -> void:
	var outline := _landmark("Kościół Świętego Aleksandra")
	if outline.size() >= 3:
		_add_site("aleksander", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "aleksander":
			sites[-1]["ring"] = outline


## A ring of n points round the rotunda, turned with the long axis: face k's middle sits at the
## local angle k * TAU / n from u (so faces line up with the porticoes and the windows).
func _aleks_ring(r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var ang := TAU * (k + 0.5) / n
		out.append(ALEKS + (_a * cos(ang) + _b * sin(ang)) * r)
	return out


func _build_aleksander(_site: Dictionary) -> void:
	_o = ALEKS
	_a = ALEKS_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var c := ALEKS
	var r := ALEKS_R
	var ru := ALEKS_UP_R
	_g = _ground_under(_circle(c, r, 8))
	var g := _g
	var none := Color(0, 0, 0, 0)
	var p := g + ALEKS_PODIUM
	var fl := g + ALEKS_FLOOR
	var face_c := cos(PI / 24.0)  # a 24-gon's face distance over its vertex radius
	_mode = M_STONE
	# the podium: a step all round, then the platform the church stands on
	_prism(_aleks_ring(r + 2.3, 24), g - 0.5, g + 0.4, ALEKS_STEP, ALEKS_STEP.lightened(0.04), M_STONE, M_STONE)
	_prism(_aleks_ring(r + 1.4, 24), g + 0.4, p, ALEKS_STEP, ALEKS_STEP.lightened(0.07), M_STONE, M_STONE)
	# the lower drum: a plinth band, the blank wall, a string course, the dentilled cornice in two
	# tiers, then the plain set-back band and its cap
	_prism(_aleks_ring(r + 0.15, 24), p - 0.1, p + 0.9, ALEKS_BASE, none, M_STONE)
	_prism(_aleks_ring(r, 24), p + 0.9, g + 11.0, ALEKS_WALL, none, M_STONE)
	# small square vents in the plinth band, two to a face, clear of the porticoes
	_mode = M_GLASS
	for k in 24:
		if k % 12 <= 2 or k % 12 >= 10:
			continue
		var va := TAU * k / 24.0
		var vo := _a * cos(va) + _b * sin(va)
		var vt := Vector2(vo.y, -vo.x)
		var vp := c + vo * ((r + 0.15) * face_c + 0.03)
		for dt: float in [-0.6, 0.6]:
			_wall(vp + vt * (dt - 0.18), vp + vt * (dt + 0.18), p + 0.3, p + 0.66, vo, ALEKS_DARK)
	_mode = M_STONE
	_prism(_aleks_ring(r + 0.08, 24), g + 9.7, g + 9.95, ALEKS_TRIM, none, M_STONE)
	_prism(_aleks_ring(r + 0.25, 24), g + 11.0, g + 11.4, ALEKS_TRIM, none, M_STONE)
	_prism(_aleks_ring(r + 0.55, 24), g + 11.4, g + 11.9, ALEKS_TRIM, ALEKS_LEDGE, M_STONE, M_STONE)
	_prism(_aleks_ring(r - 0.3, 24), g + 11.9, g + 13.6, ALEKS_WALL, none, M_STONE)
	_prism(_aleks_ring(r - 0.15, 24), g + 13.6, g + 13.8, ALEKS_TRIM, ALEKS_LEDGE, M_STONE, M_STONE)
	# the upper drum, its cornice and the plain attic ring
	_prism(_aleks_ring(ru, 24), g + 13.8, g + 18.0, ALEKS_WALL, none, M_STONE)
	_prism(_aleks_ring(ru + 0.45, 24), g + 18.0, g + 18.9, ALEKS_TRIM, ALEKS_LEDGE, M_STONE, M_STONE)
	_prism(_aleks_ring(ru - 0.6, 24), g + 18.9, g + 20.0, ALEKS_WALL, none, M_STONE)
	# round-headed windows on the even faces, blind niches on the odd ones; none on the axis,
	# where the pediments stand in front of the upper drum
	for k in 24:
		if k % 12 == 0:
			continue
		var ang := TAU * k / 24.0
		var out := _a * cos(ang) + _b * sin(ang)
		var along := Vector2(out.y, -out.x)
		var at := c + out * (ru * face_c)
		if k % 2 == 0:
			_arch_panel(at, along, out, 1.0, g + 14.4, g + 16.3, ALEKS_TRIM, 0.04, M_STONE)
			_arch_panel(at, along, out, 0.72, g + 14.6, g + 16.3, ALEKS_DARK, 0.08, M_GLASS)
		else:
			_arch_panel(at, along, out, 0.8, g + 14.5, g + 16.3, ALEKS_NICHE, 0.04, M_STONE)
	# the dome, lighter toward the top, then the cross on a small pedestal
	_mode = M_STONE
	for k in ALEKS_DOME.size() - 1:
		var da: Array = ALEKS_DOME[k]
		var db: Array = ALEKS_DOME[k + 1]
		var col := ALEKS_COPPER.lerp(ALEKS_COPPER.lightened(0.15), float(k) / ALEKS_DOME.size())
		var top := ALEKS_COPPER.lightened(0.15) if k == ALEKS_DOME.size() - 2 else none
		_frustum(_aleks_ring(da[0], 24), g + float(da[1]), _aleks_ring(db[0], 24), g + float(db[1]), col, top)
	_prism(_circle(c, 0.35, 6), g + 24.9, g + 25.6, ALEKS_IRON, ALEKS_IRON, M_STONE, M_STONE)
	_lbox(0.0, 0.0, 0.09, 0.09, g + 25.6, g + 28.2, ALEKS_IRON, M_STONE, ALEKS_IRON)
	_lbox(0.0, 0.0, 0.09, 0.6, g + 27.2, g + 27.42, ALEKS_IRON, M_STONE, ALEKS_IRON)
	# the two porticoes
	var ring := _aleks_ring(r + 2.3, 24)
	for end: float in ALEKS_ENDS:
		var sgn := signf(end)
		var face := absf(end)
		var back := face - 4.8           # the cella front
		var root := r - 1.5              # where the cella block meets the drum
		var hv := ALEKS_HALF
		# the cella front's doors first, so its wall stays whole behind them
		var du := sgn * (back + 0.08)
		_mode = M_STONE
		_wall(_w(du, sgn * 1.75), _w(du, -sgn * 1.75), fl, fl + 6.6, _a * sgn, ALEKS_TRIM)
		_mode = M_GLASS
		_wall(_w(du + sgn * 0.04, sgn * 1.3), _w(du + sgn * 0.04, -sgn * 1.3), fl, fl + 5.9, _a * sgn, ALEKS_DOOR)
		for dv: float in [-4.6, 4.6]:
			_wall(_w(du, dv + sgn * 0.6), _w(du, dv - sgn * 0.6), fl, fl + 3.2, _a * sgn, ALEKS_DOOR)
		# small windows, two up, in the cella block's side walls
		for side: float in [-1.0, 1.0]:
			var sv := side * (hv - 0.3 + 0.06)
			var su := sgn * (back - 1.4)
			for wy: float in [3.6, 7.0]:
				_wall(_w(su - 0.35, sv), _w(su + 0.35, sv), g + wy, g + wy + 1.1, _b * side, ALEKS_DARK)
		_mode = M_STONE
		# the cella block, the floor and the steps down to the square
		_lbox(sgn * (root + back) * 0.5, 0.0, (back - root) * 0.5, hv - 0.3, p - 0.2, g + 9.9, ALEKS_WALL, M_STONE)
		# the south portico has a broad flight in front; the north one (the ground falls toward
		# Nowy Świat) stands on a white base wall with a flight down each side (F's photos)
		var front := sgn < 0.0
		var reach := 1.8 if front else 0.3
		_lbox(sgn * (back + face + 0.3) * 0.5, 0.0, (face + 0.3 - back) * 0.5, hv + 0.3, g - 0.5, fl,
				ALEKS_STEP if front else ALEKS_WALL, M_STONE, ALEKS_STEP.lightened(0.08))
		var flight := [[0.3, 0.8, 1.0], [0.8, 1.3, 0.6], [1.3, 1.8, 0.25]]
		for st: Array in flight:
			var s0 := float(st[0])
			var s1 := float(st[1])
			if front:
				_lbox(sgn * (face + (s0 + s1) * 0.5), 0.0, (s1 - s0) * 0.5, hv + 0.3, g - 0.5, g + float(st[2]), ALEKS_STEP, M_STONE, ALEKS_STEP.lightened(0.05))
			else:
				for side: float in [-1.0, 1.0]:
					_lbox(sgn * (face - 1.6), side * (hv + 0.3 + (s0 + s1) * 0.5 - 0.3), 1.9, (s1 - s0) * 0.5,
							g - 0.5, g + float(st[2]), ALEKS_STEP, M_STONE, ALEKS_STEP.lightened(0.05))
		# the antae at the cella front's corners, then the columns: six across, one more each side
		for side: float in [-1.0, 1.0]:
			_lbox(sgn * (back + 0.2), side * 5.75, 0.2, 0.45, fl, g + 9.9, ALEKS_TRIM, M_STONE)
		for v: float in ALEKS_COLS:
			kit_column(sgn * (face - 0.75), v, fl, g + 9.9, ALEKS_TRIM, 0.46, Order.CORINTHIAN)
		for v: float in [ALEKS_COLS[0], ALEKS_COLS[-1]]:
			kit_column(sgn * (face - 0.75 - ALEKS_RETURN), v, fl, g + 9.9, ALEKS_TRIM, 0.46, Order.CORINTHIAN)
		# the entablature (architrave and frieze, then the cornice), the pediment and its cross
		var e0 := root
		var e1 := face + 0.05
		_lbox(sgn * (e0 + e1) * 0.5, 0.0, (e1 - e0) * 0.5, hv + 0.05, g + 9.9, g + 11.2, ALEKS_TRIM, M_STONE)
		_lbox(sgn * (e0 + e1 + 0.25) * 0.5, 0.0, (e1 + 0.25 - e0) * 0.5, hv + 0.3, g + 11.2, g + 11.9, ALEKS_TRIM, M_STONE, ALEKS_TRIM.darkened(0.1))
		# the pediment roof stops against a plain block over the cella's back, as high as the band
		_gable(sgn * (face + 0.2), sgn * (root + 1.6), 0.0, hv + 0.3, g + 11.9, 3.3, ALEKS_WALL, ALEKS_ROOF, true)
		_lbox(sgn * (root + 0.8), 0.0, 0.8, hv - 1.2, g + 11.9, g + 13.8, ALEKS_WALL, M_STONE, ALEKS_LEDGE)
		_lbox(sgn * (face + 0.05), 0.0, 0.08, 0.08, g + 15.2, g + 16.9, ALEKS_IRON, M_STONE, ALEKS_IRON)
		_lbox(sgn * (face + 0.05), 0.0, 0.08, 0.45, g + 16.2, g + 16.38, ALEKS_IRON, M_STONE, ALEKS_IRON)
		var arm := _rect(sgn * (root + face + reach) * 0.5, 0.0, (face + reach - root) * 0.5, hv + (0.3 if front else 1.8))
		var merged := Geometry2D.merge_polygons(ring, arm)
		if not merged.is_empty():
			ring = _largest(merged)
	_collide(ring)


## The Jesuit church (Sanktuarium Matki Bożej Łaskawej, Świętojańska 10, next to the Cathedral):
## the whole church as a model that replaces the LoD2 mass (the SKINS entry has `model`).
## Rebuilt 2026-11-13 from F's four photos (the stepped front by day and by night, the front
## looking up, the tower's helm), two Mapillary photos and the LoD2 heights (nave eaves 22.8 m,
## nave ridge 34 m, presbytery ridge 31 m, aisle 14 m, tower decagon r 3.2 to 45 m and its helm
## to 56 m, a turret over the presbytery to 38 m). Spec docs/landmarks/specs/jezuici.md.
## Dusty pink plaster, cream trim, dark roofs, green copper:
## - the nave (u 7.9 to 20.45) with a steep roof, a lower presbytery behind, a sacristy at the back;
## - the front: a tall tier of four giant pilasters with carved capitals, then three narrower
##   tiers (each a window between pilasters, a cornice and scroll buttresses either side), cream
##   pinnacles with gold balls and a gold cross; an arched portal under a small pediment;
## - the aisle along the street end (u 0 to 7.9, its front the wing 4.5 m forward): pilasters, a
##   statue niche, a door, windows, a hipped roof;
## - the side wall toward the Cathedral: pilasters on the outline's bumps, tall arched windows;
##   clerestory windows over the aisle on the other side;
## - the tower: a decagon with corner pilasters, arched openings, a green copper helm, a lantern,
##   an onion cap with a gold ball and cross; the turret on the presbytery's ridge.
## Frame: origin at the wing's NW corner, u along Świętojańska to the south-east, +v out to the street.
const JEZ := Vector2(-764.2, -1648.3)
const JEZ_AXIS := Vector2(0.685, 0.729)
const JEZ_FRONT := -4.47            ## the main front's face in v (the nave block starts behind its slab, at -4.9)
const JEZ_U0 := 7.9                 ## the nave's west wall (over the aisle)
const JEZ_U1 := 20.45               ## the nave's east wall (the outline's pilaster bumps)
const JEZ_MID := 14.18
const JEZ_BACK := -37.0             ## the presbytery's back wall
const JEZ_PRES := -29.0             ## where the lower presbytery roof begins
const JEZ_EAVE := 22.8
const JEZ_TRIM := Color("#efe6d2")   ## the cream pilasters and surrounds (F's photos)
const JEZ_PINK := Color("#dd8f82")   ## the dusty pink plaster (F's day photos)
const JEZ_ROOF := Color("#6a4d44")   ## the dark roofs (F's photos)
const JEZ_TOWER := Vector2(6.3, -32.0)    ## the tower's decagon (LoD2), local u, v
const JEZ_TURRET := Vector2(14.18, -32.6) ## the turret on the presbytery's ridge (LoD2 13.2, -32.1)


## A ring of n points round a local centre, the first on the u axis: the tower's decagon (LoD2).
func _jez_ring(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var ang := TAU * k / n
		out.append(_w(c.x + r * cos(ang), c.y + r * sin(ang)))
	return out


## A cream pinnacle on a cornice: a small square shaft and a gold ball.
func _jez_pinnacle(u: float, v: float, y: float, h: float) -> void:
	_lbox(u, v, 0.26, 0.26, y, y + h, JEZ_TRIM, M_STONE)
	_prism(_circle(_w(u, v), 0.3, 6), y + h, y + h + 0.5, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)


## A gable roof whose ridge runs along v (the nave's): `_gable` in the swapped frame.
func _jez_roof(vf: float, vb: float, cu: float, hu: float, y: float, h: float, face: Color, back: bool) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, face, JEZ_ROOF, back)
	_a = ka
	_b = kb


## An arched opening on each face of a decagon (or every other face): cream surround, dark pane.
func _jez_openings(c: Vector2, r: float, y0: float, spring: float, hw: float, every: int, trim: bool) -> void:
	var cw := _w(c.x, c.y)
	for k in 10:
		if k % every != 0:
			continue
		var fang := TAU * (k + 0.5) / 10.0
		var fout := _a * cos(fang) + _b * sin(fang)
		var falong := Vector2(fout.y, -fout.x)
		var fat := cw + fout * (r * cos(PI / 10.0))
		if trim:
			_arch_panel(fat, falong, fout, hw + 0.22, y0 - 0.2, spring, JEZ_TRIM, 0.05, M_STONE)
		_arch_panel(fat, falong, fout, hw, y0, spring, PAL_GLASS_DARK, 0.09, M_GLASS)


## A stack of decagon frustums [radius, height over the ground] round a local centre.
func _jez_stack(c: Vector2, rings: Array, col: Color) -> void:
	for k in rings.size() - 1:
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		_frustum(_jez_ring(c, float(ra[0]), 10), _g + float(ra[1]), _jez_ring(c, float(rb[0]), 10), _g + float(rb[1]), col, col)


func _build_jezuici(site: Dictionary) -> void:
	var m := JEZ_MID
	var to := JEZ + JEZ_AXIS.normalized() * 21.0
	kit_front(JEZ, to)
	var outline: PackedVector2Array = site["zone"][0]
	_g = _ground_under(outline)
	var g := _g
	var e := g + JEZ_EAVE
	_mode = M_STONE
	# --- the masses: nave, presbytery, sacristy, the aisle along the street end, the west strip
	_prism(_rect((JEZ_U0 + JEZ_U1) * 0.5, (-4.9 + JEZ_BACK) * 0.5, (JEZ_U1 - JEZ_U0) * 0.5, (JEZ_BACK + 4.9) * -0.5),
			g - 0.5, e, JEZ_PINK, JEZ_ROOF, M_STONE, M_STONE)
	_prism(_rect(15.3, -39.25, 5.15, 2.25), g - 0.5, g + 15.0, JEZ_PINK, JEZ_ROOF, M_STONE, M_STONE)
	_hip(15.3, -39.25, 5.15, 2.25, g + 15.0, 2.0, JEZ_ROOF)
	_prism(_rect(3.95, -18.6, 3.95, 18.6), g - 0.5, g + 14.0, JEZ_PINK, JEZ_ROOF, M_STONE, M_STONE)
	_hip(3.95, -18.6, 4.15, 18.8, g + 14.0, 2.6, JEZ_ROOF)
	_prism(_rect(-2.0, -28.0, 2.0, 9.2), g - 0.5, g + 13.0, JEZ_PINK, JEZ_ROOF, M_STONE, M_STONE)
	_hip(-2.0, -28.0, 2.15, 9.35, g + 13.0, 1.6, JEZ_ROOF)
	# the roofs: the nave's steep gable to 34 m, the presbytery's lower one to 31 m, eaves cornices
	_jez_roof(-4.9, JEZ_PRES, m, (JEZ_U1 - JEZ_U0) * 0.5 + 0.35, e + 0.55, 10.6, JEZ_PINK, false)
	_jez_roof(JEZ_BACK - 0.3, JEZ_PRES - 0.2, m, (JEZ_U1 - JEZ_U0) * 0.5 + 0.35, e + 0.55, 7.6, JEZ_PINK, false)
	_prism(_rect(m, (-4.9 + JEZ_BACK) * 0.5, (JEZ_U1 - JEZ_U0) * 0.5 + 0.35, (JEZ_BACK + 4.9) * -0.5 + 0.3),
			e, e + 0.55, JEZ_TRIM, JEZ_ROOF, M_STONE, M_STONE)
	# --- the front: four tiers, each narrower, each with its cornice and scroll buttresses
	kit_face(JEZ_FRONT)
	kit_wall(JEZ_U0, JEZ_U1, g - 0.2, g + 14.0, JEZ_PINK)
	kit_wall(m - 4.1, m + 4.1, g + 13.9, g + 22.4, JEZ_PINK)
	kit_wall(m - 2.6, m + 2.6, g + 22.3, g + 28.4, JEZ_PINK)
	kit_wall(m - 1.6, m + 1.6, g + 28.3, g + 33.2, JEZ_PINK)
	kit_ledge(JEZ_U0, JEZ_U1, g - 0.2, 1.1, PAL_GREY_STONE, 0.16)
	# tier 1: the giant order, carved capitals, a string course, the cornice
	for du: float in [-5.75, -2.35, 2.35, 5.75]:
		kit_pilaster(m + du, g + 0.8, g + 13.5, JEZ_TRIM, 1.0, 0.2)
		_kbox(m + du - 0.75, m + du + 0.75, JEZ_FRONT - 0.04, JEZ_FRONT + 0.34, g + 12.3, g + 13.1, JEZ_TRIM)
	kit_ledge(JEZ_U0, JEZ_U1, g + 6.6, 0.4, JEZ_TRIM, 0.14)
	kit_cornice(JEZ_U0, JEZ_U1, g + 14.0, JEZ_TRIM, 0.6, 1.2)
	for wu: float in [m - 4.05, m + 4.05]:
		kit_window(wu, g + 2.3, 2.4, Win.FRAMED, JEZ_TRIM, PAL_GLASS_DARK, 0.55)
		kit_window(wu, g + 8.2, 3.2, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.65)
	kit_door(m, g + 1.1, 4.6, 1.1, JEZ_TRIM, PAL_OAK, true)
	kit_pediment(m, 1.7, g + 6.2, 1.0, JEZ_TRIM, JEZ_ROOF, 0.45, JEZ_PINK.darkened(0.15))
	kit_window(m, g + 8.0, 4.6, Win.PEDIMENT, JEZ_TRIM, PAL_GLASS_DARK, 0.85)
	# tier 2
	for du2: float in [-3.65, 3.65]:
		kit_pilaster(m + du2, g + 14.6, g + 22.0, JEZ_TRIM, 0.9, 0.2)
	kit_window(m, g + 16.2, 4.0, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.9)
	kit_cornice(m - 4.1, m + 4.1, g + 22.4, JEZ_TRIM, 0.55, 1.1)
	# tier 3
	for du3: float in [-2.2, 2.2]:
		kit_pilaster(m + du3, g + 23.0, g + 28.0, JEZ_TRIM, 0.7, 0.18)
	kit_window(m, g + 24.2, 2.8, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.6)
	kit_cornice(m - 2.6, m + 2.6, g + 28.4, JEZ_TRIM, 0.5, 1.0)
	# tier 4 and its small pediment, the cross
	kit_window(m, g + 29.5, 2.2, Win.PLAIN, JEZ_TRIM, PAL_GLASS_DARK, 0.5)
	kit_pediment(m, 1.8, g + 33.2, 2.2, JEZ_TRIM, JEZ_ROOF, 0.4)
	_lbox(m, JEZ_FRONT + 0.3, 0.07, 0.07, g + 35.2, g + 38.2, PAL_GOLD, M_STONE, PAL_GOLD)
	_lbox(m, JEZ_FRONT + 0.3, 0.5, 0.07, g + 36.6, g + 36.85, PAL_GOLD, M_STONE, PAL_GOLD)
	# the scroll buttresses: steps from one tier's cornice up to the next tier's wall
	var steps := [[6.25, 5.5, 14.6, 15.6], [5.5, 4.9, 15.6, 17.4], [4.9, 4.2, 17.4, 19.6],
			[4.1, 3.5, 22.9, 24.0], [3.5, 2.9, 24.0, 26.2], [2.6, 2.1, 28.9, 30.2]]
	for st: Array in steps:
		for sg: float in [-1.0, 1.0]:
			var ua := m + sg * float(st[0])
			var ub := m + sg * float(st[1])
			_kbox(minf(ua, ub), maxf(ua, ub), JEZ_FRONT - 0.04, JEZ_FRONT + 0.5, g + float(st[2]), g + float(st[3]), JEZ_TRIM)
	# the pinnacles with gold balls on the cornices
	for pe: Array in [[6.0, 14.6], [3.9, 22.9], [2.4, 28.9]]:
		for sg2: float in [-1.0, 1.0]:
			_jez_pinnacle(m + sg2 * float(pe[0]), JEZ_FRONT + 0.4, g + float(pe[1]), 1.6)
	# --- the wing (the aisle's front, 4.5 m forward of the main front)
	kit_face(0.03)
	kit_ledge(0.0, 7.9, g - 0.2, 1.1, PAL_GREY_STONE, 0.16)
	for wp: float in [0.5, 7.4]:
		kit_pilaster(wp, g + 0.8, g + 13.4, JEZ_TRIM, 0.8, 0.16)
	kit_cornice(0.0, 7.9, g + 13.4, JEZ_TRIM, 0.55, 0.9)
	kit_door(5.5, g + 1.1, 2.8, 0.65, JEZ_TRIM, PAL_OAK, false)
	kit_window(2.8, g + 2.2, 2.0, Win.FRAMED, JEZ_TRIM, PAL_GLASS_DARK, 0.55)
	# the statue niche over the window (the photos), and the arched window beside it
	_arch_panel(_w(2.8, 0.03), _a, _b, 0.8, g + 6.0, g + 8.4, JEZ_TRIM, 0.05, M_STONE)
	_arch_panel(_w(2.8, 0.03), _a, _b, 0.58, g + 6.2, g + 8.4, JEZ_PINK.darkened(0.25), 0.09, M_STONE)
	_lbox(2.8, 0.25, 0.22, 0.18, g + 6.3, g + 8.7, JEZ_TRIM, M_STONE)
	kit_window(5.5, g + 7.6, 3.2, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.6)
	# --- the side wall toward the Cathedral: pilasters on the outline's bumps, tall arched windows
	var ax := JEZ_AXIS.normalized()
	var bx := Vector2(-ax.y, ax.x)  # the front frame's v, kept: kit_front below turns the frame
	var fa := kit_front(JEZ + ax * JEZ_U1 + bx * -4.9, JEZ + ax * JEZ_U1 + bx * JEZ_BACK)
	kit_face(0.0)
	kit_ledge(0.0, fa, g - 0.2, 1.0, PAL_GREY_STONE, 0.14)
	for k in 6:
		kit_pilaster(0.4 + 6.0 * k, g + 0.8, e - 0.2, JEZ_TRIM, 1.2, 0.2)
	for k2 in 5:
		kit_window(3.4 + 6.0 * k2, g + 3.0, 2.4, Win.FRAMED, JEZ_TRIM, PAL_GLASS_DARK, 0.6)
		kit_window(3.4 + 6.0 * k2, g + 10.5, 5.6, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.9)
	kit_ledge(0.0, fa, g + 8.4, 0.4, JEZ_TRIM, 0.12)
	# --- the clerestory over the aisle: the nave's west wall from the aisle's roof to the eaves
	kit_front(JEZ + ax * JEZ_U0 + bx * JEZ_PRES, JEZ + ax * JEZ_U0 + bx * -4.9)
	kit_face(0.0)
	for k3 in 4:
		kit_window(3.0 + 6.0 * k3, g + 17.4, 3.4, Win.ARCHED, JEZ_TRIM, PAL_GLASS_DARK, 0.75)
	kit_ledge(0.0, JEZ_PRES * -1.0 - 4.9, g + 16.7, 0.35, JEZ_TRIM, 0.12)
	# back in the front's frame for the tower and turret
	kit_front(JEZ, to)
	# --- the tower: a decagon r 3.2 from the ground (it rises out of the aisle), pilasters, openings, helm
	var tc := JEZ_TOWER
	var tw := _w(tc.x, tc.y)
	_mode = M_STONE
	_prism(_jez_ring(tc, 3.2, 10), g - 0.5, g + 44.0, JEZ_PINK, JEZ_PINK, M_STONE, M_STONE)
	for k in 10:
		var va := TAU * k / 10.0
		_lbox(tc.x + 3.24 * cos(va), tc.y + 3.24 * sin(va), 0.22, 0.22, g + 14.5, g + 44.0, JEZ_TRIM, M_STONE)
	_prism(_jez_ring(tc, 3.35, 10), g + 22.5, g + 23.0, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_prism(_jez_ring(tc, 3.35, 10), g + 33.0, g + 33.5, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_prism(_jez_ring(tc, 3.5, 10), g + 44.0, g + 44.5, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_prism(_jez_ring(tc, 3.3, 10), g + 44.5, g + 45.0, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_jez_openings(tc, 3.2, g + 25.5, g + 29.6, 0.45, 2, true)
	_jez_openings(tc, 3.2, g + 35.8, g + 39.8, 0.62, 1, true)
	# the green helm: a flared lip, a waist, the cream lantern with dark openings, the onion cap, ball and cross
	_jez_stack(tc, [[3.0, 45.0], [3.55, 46.7], [2.7, 48.3], [1.7, 50.0]], PAL_PATINA_COPPER)
	_prism(_jez_ring(tc, 1.35, 10), g + 50.0, g + 53.0, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_jez_openings(tc, 1.35, g + 50.6, g + 52.0, 0.32, 2, false)
	_jez_stack(tc, [[1.7, 53.0], [1.55, 54.0], [0.9, 55.0], [0.3, 55.9]], PAL_PATINA_COPPER)
	_prism(_circle(tw, 0.3, 6), g + 55.9, g + 56.6, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)
	_lbox(tc.x, tc.y, 0.07, 0.07, g + 56.6, g + 59.2, PAL_GOLD, M_STONE, PAL_GOLD)
	_lbox(tc.x, tc.y, 0.45, 0.07, g + 57.8, g + 58.05, PAL_GOLD, M_STONE, PAL_GOLD)
	# --- the turret on the presbytery's ridge: a green base, a cream lantern, a green cap, ball and cross
	var uc := JEZ_TURRET
	var uw := _w(uc.x, uc.y)
	_jez_stack(uc, [[2.6, 28.4], [2.6, 31.0], [1.8, 32.6]], PAL_PATINA_COPPER)
	_prism(_jez_ring(uc, 1.55, 10), g + 32.6, g + 36.0, JEZ_TRIM, JEZ_TRIM, M_STONE, M_STONE)
	_jez_openings(uc, 1.55, g + 33.2, g + 34.8, 0.32, 2, false)
	_frustum(_jez_ring(uc, 1.9, 10), g + 36.0, _jez_ring(uc, 0.3, 10), g + 38.6, PAL_PATINA_COPPER, PAL_PATINA_COPPER)
	_prism(_circle(uw, 0.28, 6), g + 38.6, g + 39.2, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)
	_lbox(uc.x, uc.y, 0.06, 0.06, g + 39.2, g + 41.4, PAL_GOLD, M_STONE, PAL_GOLD)
	_lbox(uc.x, uc.y, 0.38, 0.06, g + 40.2, g + 40.4, PAL_GOLD, M_STONE, PAL_GOLD)
	_collide(outline)


## The Field Cathedral of the Polish Army (Katedra Polowa Wojska Polskiego, ul. Długa 13/15, the
## former Piarist church, 1701-1735 by Karol Bay and Józef Fontana, rebuilt after 1945): the whole
## church as a model that replaces the old kit church (`church_katedra_polowa`, built by
## `_build_church` until 2026-11-14) and the LoD2 mass inside the outline. From F's photos (the
## front by day, the 1840s painting of the square, the oblique with the Uprising Monument) and the
## LoD2 heights (pediment 21.5 m with the statue, nave ridge 17 to 24 m, towers to 35 m with the
## spires, wings 13 m, chapels 6 m, a roof turret at 23 m). Spec docs/landmarks/specs/katedra_polowa.md.
## Cream-white plaster, sandstone bases, green copper:
## - the front: four giant pilasters with big capitals in two pairs, a broken entablature, a
##   triangular pediment with a pedestal and the statue of the Virgin; between the pairs a tall
##   arch over a stained-glass window, two free columns and a bronze door under a small pediment;
## - two low wings either side, each an arched door, an arched window over a balustrade, a cornice,
##   a scroll rising to the main front and an urn;
## - two square belfries behind the pediment (louvred arch, oculus, cornice) with green copper
##   bulb caps and needle spires with gold balls and iron crosses;
## - the roofs: a gable over the front block, a lower one over the nave and presbytery, hips on the
##   wings and chapels, a lantern on the ridge; plain side walls with pilasters and arched windows.
## Frame: origin at the front line (the giant pilasters' face), u across (the front's mirror axis),
## +v out to Długa. The main wall stands at v = -0.8; the pilasters stand 0.8 m out of it.
const KATP_O := Vector2(-1175.4, -1655.8)
const KATP_AXIS := Vector2(-0.6247, 0.7809)
const KATP_FACE := -0.8
const KATP_WALL := Color("#ece6d6")    ## the cream-white plaster (F's day photo)
const KATP_TRIM := Color("#f2eee2")    ## the pilasters, cornices and surrounds
const KATP_BASE := Color("#cfc19b")    ## the sandstone plinth and pedestals
const KATP_RECESS := Color("#d9d2c0")  ## the shadowed arch field
const KATP_STATUE := Color("#c9c6bc")  ## the weathered stone of the statue
const KATP_LOUVRE := Color("#3b5a4e")  ## the belfries' green louvres


## A gable roof whose ridge runs along v: `_gable` in the swapped frame, in the church's copper.
func _katp_roof(vf: float, vb: float, cu: float, hu: float, y: float, h: float, back: bool) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, KATP_WALL, PAL_PATINA_COPPER, back)
	_a = ka
	_b = kb


## An arched dark panel on a belfry's or wall's side: trim surround, dark pane. `at` is the world
## foot centre, `out` the wall's outward normal.
func _katp_side_arch(at: Vector2, out: Vector2, hw: float, y0: float, spring: float) -> void:
	var along := Vector2(out.y, -out.x)
	_arch_panel(at, along, out, hw + 0.2, y0 - 0.2, spring, KATP_TRIM, 0.03, M_STONE)
	_arch_panel(at, along, out, hw, y0, spring, KATP_LOUVRE, 0.07, M_STONE)


func _build_katedra_polowa(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var g := _g
	var f := KATP_FACE
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	kit_front(KATP_O, KATP_O + KATP_AXIS * 10.0)
	var wo := _o
	var wa := _a
	var wb := _b
	# --- the masses (the whole footprint): front block, nave and presbytery, wings, chapels, apse
	_prism(_rect(0.0, (f - 17.0) * 0.5, 9.4, (17.0 + f) * -0.5), g - 0.5, g + 17.4, KATP_WALL, none, M_STONE, M_STONE)
	_prism(_rect(0.0, -27.25, 9.4, 10.25), g - 0.5, g + 14.0, KATP_WALL, none, M_STONE, M_STONE)
	for sg: float in [-1.0, 1.0]:
		_prism(_rect(sg * 11.6, -8.95, 2.2, 8.05), g - 0.5, g + 10.3, KATP_WALL, none, M_STONE, M_STONE)
		_hip(sg * 11.6, -8.95, 2.35, 8.2, g + 10.3, 3.0, PAL_PATINA_COPPER)
		_prism(_rect(sg * 11.25, -33.75, 1.85, 3.75), g - 0.5, g + 6.5, KATP_WALL, none, M_STONE, M_STONE)
		_hip(sg * 11.25, -33.75, 2.0, 3.9, g + 6.5, 1.8, PAL_PATINA_COPPER)
	_prism(_rect(0.0, -38.65, 9.6, 1.15), g - 0.5, g + 12.0, KATP_WALL, none, M_STONE, M_STONE)
	_hip(0.0, -38.65, 9.75, 1.3, g + 12.0, 1.1, PAL_PATINA_COPPER)
	# the roofs: the front block's gable behind the pediment (ridge 23.4 m), the nave's lower one
	_katp_roof(-4.4, -17.0, 0.0, 9.75, g + 17.9, 5.5, true)
	_katp_roof(-37.6, -17.0, 0.0, 9.75, g + 14.0, 4.2, false)
	_prism(_rect(0.0, (f - 17.0) * 0.5, 9.75, (17.0 + f) * -0.5 + 0.3), g + 17.4, g + 17.95, KATP_TRIM, PAL_PATINA_COPPER, M_STONE, M_STONE)
	_prism(_rect(0.0, -27.25, 9.75, 10.55), g + 14.0, g + 14.5, KATP_TRIM, PAL_PATINA_COPPER, M_STONE, M_STONE)
	# --- the front: plinth, steps, the two pairs of giant pilasters, the entablature
	kit_face(f)
	kit_ledge(-9.4, 9.4, g - 0.2, 0.9, KATP_BASE, 0.9)
	_kbox(-4.9, 4.9, 0.1, 1.5, g - 0.2, g + 0.3, KATP_BASE)
	_kbox(-3.4, 3.4, 1.5, 2.4, g - 0.2, g + 0.12, KATP_BASE)
	for sg2: float in [-1.0, 1.0]:
		for cu: float in [5.6, 8.3]:
			var u := sg2 * cu
			_kbox(u - 1.2, u + 1.2, f - 0.04, f + 0.95, g + 0.7, g + 3.0, KATP_BASE.lightened(0.05))
			kit_pilaster(u, g + 3.0, g + 15.2, KATP_TRIM, 2.0, 0.8)
			_kbox(u - 1.3, u + 1.3, f - 0.04, f + 1.0, g + 13.7, g + 15.2, KATP_TRIM.darkened(0.03))
	kit_ledge(-9.6, 9.6, g + 15.2, 0.9, KATP_TRIM, 0.95)
	kit_ledge(-9.4, 9.4, g + 16.1, 0.9, KATP_WALL.darkened(0.03), 0.2)
	kit_cornice(-9.4, 9.4, g + 17.4, KATP_TRIM, 0.55, 1.3)
	# the pediment with its relief, the pedestal and the statue of the Virgin above it
	kit_pediment(0.0, 7.2, g + 17.95, 2.8, KATP_TRIM, KATP_TRIM.darkened(0.08), 0.9, PAL_CREAM_STONE.darkened(0.1))
	_kbox(-1.3, 1.3, -1.7, -0.4, g + 19.0, g + 23.3, KATP_TRIM)
	_kbox(-1.6, 1.6, -1.9, -0.2, g + 23.3, g + 23.7, KATP_TRIM)
	for sg3: float in [-1.0, 1.0]:
		for st: Array in [[1.3, 2.7, 19.6, 21.1], [2.7, 3.8, 18.9, 20.0]]:
			var ua := sg3 * float(st[0])
			var ub := sg3 * float(st[1])
			_kbox(minf(ua, ub), maxf(ua, ub), -1.6, -0.3, g + float(st[2]), g + float(st[3]), KATP_TRIM)
	var sc := _w(0.0, -1.05)
	_frustum(_circle(sc, 0.55, 6), g + 23.7, _circle(sc, 0.3, 6), g + 25.7, KATP_STATUE)
	_prism(_circle(sc, 0.22, 6), g + 25.7, g + 26.2, KATP_STATUE, KATP_STATUE, M_STONE, M_STONE)
	_lbox(0.0, -1.05, 1.0, 0.1, g + 24.9, g + 25.2, KATP_STATUE)
	# the central bay: the big arch with its shadowed field, the stained-glass window, two free
	# columns carrying the ledge stubs, the bronze door under its small pediment
	_arch_panel(_w(0.0, f), _a, _b, 4.25, g + 9.4, g + 10.5, KATP_TRIM, 0.09, M_STONE)
	_arch_panel(_w(0.0, f), _a, _b, 3.65, g + 9.9, g + 10.5, KATP_RECESS, 0.14, M_STONE)
	kit_window(0.0, g + 6.2, 5.3, Win.ARCHED, KATP_TRIM, PAL_GLASS_BLUE, 1.15)
	for sg4: float in [-1.0, 1.0]:
		kit_column(sg4 * 3.7, -0.1, g + 0.7, g + 9.5, KATP_TRIM, 0.38)
		kit_ledge(minf(sg4 * 2.8, sg4 * 4.7), maxf(sg4 * 2.8, sg4 * 4.7), g + 9.5, 0.9, KATP_TRIM, 1.0)
	kit_door(0.0, g + 0.7, 3.0, 1.1, KATP_TRIM, PAL_BRONZE, false)
	kit_pediment(0.0, 1.9, g + 4.5, 0.9, KATP_TRIM, KATP_TRIM.darkened(0.06), 0.4)
	# --- the wings: plinth, arched door, balustrade and arched window, cornice, scroll, urn
	kit_face(-0.9)
	for sg5: float in [-1.0, 1.0]:
		var lo := minf(sg5 * 9.4, sg5 * 13.8)
		var hi := maxf(sg5 * 9.4, sg5 * 13.8)
		var uw := sg5 * 10.8
		kit_ledge(lo, hi, g - 0.2, 0.9, KATP_BASE, 0.3)
		kit_door(uw, g + 0.7, 2.8, 0.8, KATP_TRIM, PAL_BRONZE, true)
		kit_attic(uw - 1.3, uw + 1.3, g + 4.0, KATP_TRIM, 0.8)
		kit_window(uw, g + 5.0, 3.0, Win.ARCHED, KATP_TRIM, PAL_GLASS_DARK, 1.0)
		kit_cornice(lo, hi, g + 10.3, KATP_TRIM, 0.45, 0.7)
		kit_pilaster(sg5 * 13.45, g + 1.0, g + 10.0, KATP_TRIM, 0.7, 0.35)
		for sv: Array in [[9.4, 10.4, 13.4], [10.4, 11.4, 12.3], [11.4, 12.5, 11.6]]:
			var va := sg5 * float(sv[0])
			var vb := sg5 * float(sv[1])
			_kbox(minf(va, vb), maxf(va, vb), -1.4, -0.5, g + 10.75, g + float(sv[2]), KATP_TRIM)
		var ur := _w(sg5 * 13.45, -1.0)
		_lbox(sg5 * 13.45, -1.0, 0.4, 0.4, g + 10.75, g + 12.0, KATP_TRIM)
		_frustum(_circle(ur, 0.22, 6), g + 12.0, _circle(ur, 0.55, 6), g + 13.1, KATP_TRIM)
		_frustum(_circle(ur, 0.55, 6), g + 13.1, _circle(ur, 0.2, 6), g + 14.3, KATP_TRIM)
	# --- the two belfries behind the pediment: base block, louvred arch, oculus, cornice, copper
	# bulb cap, needle spire, gold ball and iron cross
	var vc := -7.6
	var vfront := vc + 2.75
	for sg6: float in [-1.0, 1.0]:
		var uc := sg6 * 6.7
		_lbox(uc, vc, 2.9, 3.3, g + 17.0, g + 20.3, KATP_WALL, M_STONE, KATP_TRIM)
		_lbox(uc, vc, 3.1, 3.5, g + 20.3, g + 20.8, KATP_TRIM)
		_lbox(uc, vc, 2.35, 2.75, g + 20.8, g + 26.2, KATP_WALL)
		for cx: float in [-1.0, 1.0]:
			for cz: float in [-1.0, 1.0]:
				_lbox(uc + cx * 2.35, vc + cz * 2.75, 0.3, 0.3, g + 20.8, g + 26.0, KATP_TRIM)
		_lbox(uc, vc, 2.7, 3.1, g + 26.0, g + 26.6, KATP_TRIM)
		kit_face(vfront)
		kit_window(uc, g + 21.5, 2.6, Win.ARCHED, KATP_TRIM, KATP_LOUVRE, 0.75)
		kit_attic(uc - 1.3, uc + 1.3, g + 20.8, KATP_TRIM, 0.7)
		var oc := _w(uc, vfront + 0.1)
		var on := Vector3(_b.x, 0.0, _b.y)
		_disc(Vector3(oc.x, g + 25.1, oc.y), on, 0.75, 8, KATP_TRIM)
		_disc(Vector3(oc.x, g + 25.1, oc.y) + on * 0.03, on, 0.5, 8, PAL_GLASS_DARK)
		for sd: float in [-1.0, 1.0]:
			_katp_side_arch(_w(uc + sd * 2.35, vc), wa * sd, 0.7, g + 21.5, g + 23.2)
		_katp_side_arch(_w(uc, vc - 2.75), -wb, 0.7, g + 21.5, g + 23.2)
		var tc := Vector2(uc, vc)
		_jez_stack(tc, [[3.0, 26.6], [3.15, 27.4], [2.5, 28.2], [1.25, 28.9], [0.75, 29.3]], PAL_PATINA_COPPER)
		_frustum(_jez_ring(tc, 0.75, 10), g + 29.3, _jez_ring(tc, 0.1, 10), g + 34.8, PAL_PATINA_COPPER, PAL_PATINA_COPPER)
		_prism(_circle(_w(uc, vc), 0.28, 6), g + 34.8, g + 35.4, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)
		_lbox(uc, vc, 0.06, 0.06, g + 35.4, g + 38.0, PAL_IRON, M_STONE, PAL_IRON)
		_lbox(uc, vc, 0.4, 0.06, g + 36.5, g + 36.8, PAL_IRON, M_STONE, PAL_IRON)
	# --- the nave's side walls: plinth, pilasters, arched windows, a cornice (plain beyond that)
	var side := func(from: Vector2, to: Vector2) -> void:
		var wl := kit_front(from, to)
		kit_face(0.0)
		kit_ledge(0.0, wl, g - 0.2, 0.9, KATP_BASE, 0.2)
		for k in 4:
			kit_pilaster(0.8 + 6.3 * k, g + 0.9, g + 13.6, KATP_TRIM, 0.9, 0.25)
		for k2 in 3:
			kit_window(4.0 + 6.3 * k2, g + 4.5, 5.0, Win.ARCHED, KATP_TRIM, PAL_GLASS_DARK, 0.9)
		kit_cornice(0.0, wl, g + 14.0, KATP_TRIM, 0.4, 0.6)
	side.call(wo + wa * 9.4 + wb * -17.0, wo + wa * 9.4 + wb * -37.5)
	side.call(wo + wa * -9.4 + wb * -37.5, wo + wa * -9.4 + wb * -17.0)
	# --- the lantern on the nave's ridge
	kit_front(KATP_O, KATP_O + KATP_AXIS * 10.0)
	kit_lantern(0.0, -32.0, g + 18.2, 5.0, 1.25, KATP_TRIM, PAL_PATINA_COPPER, PAL_GLASS_DARK, 8)
	_collide(outline)


## The Capuchin church (Kościół Przemienienia Pańskiego, ul. Miodowa 13, Kapucyni, 1683-1692 by
## Tylman van Gameren, front 1750s by Jakub Fontana, rebuilt after 1944): the whole church as a model
## that replaces the old kit church (`church_kapucyni`, built by `_build_church` until 2026-11-14)
## and the LoD2 mass inside the outline. From F's Commons photo of the front and the long wall
## (top-50 set, 100-kosciol-kapucynow-exterior-2), Mapillary 360 views of the front and the OSM
## outline (29 points, 21.7 m wide, 31 m deep). Spec docs/landmarks/specs/kapucyni.md.
## Warm cream plaster, a salmon-pink front pavilion, green copper:
## - the front: a narrow pavilion in salmon with two pairs of cream pilasters, an arched window
##   with a stone balcony over the portal, an inscription band, an entablature and a triangular
##   pediment with a pedestal and a cross, urn finials on its feet; a landing with steps and
##   balustrades in front;
## - two low cream wings either side with a cornice and a scroll up to the pavilion, a statue on
##   a pedestal on the right one;
## - the nave behind: cream walls with tall arched windows over a lower aisle, a hipped green
##   copper roof with an iron cross; aisles and the sacristy as one low mass with a cornice.
## Frame: origin at the front's east end, u across (+u to the viewer's right), +v out to Miodowa;
## the main wall stands at v = 0.8 and the pilasters 1.0 m out of it.
const KAP_O := Vector2(-958.7, -1428.0)
const KAP_A := Vector2(-0.7275, -0.6861)
const KAP_C := 10.85                   ## the front's mirror axis (u)
const KAP_WALL := Color("#ecdfb4")     ## the warm cream plaster of the body
const KAP_TRIM := Color("#e8d6aa")     ## pilasters, cornices, surrounds
const KAP_PINK := Color("#d8806a")     ## the salmon front
const KAP_INSCR := Color("#e4c3a6")    ## the inscription band on the frieze
const KAP_BASE := Color("#b9b2a2")     ## steps, plinth, balustrades
const KAP_ROOF := Color("#76a592")     ## the pale green copper of the roofs


## An iron cross (staff and arm) standing on y.
func _kap_cross(u: float, v: float, y: float, h: float) -> void:
	_lbox(u, v, 0.07, 0.07, y, y + h, PAL_IRON, M_STONE, PAL_IRON)
	_lbox(u, v, 0.45, 0.07, y + h * 0.62, y + h * 0.62 + 0.12, PAL_IRON, M_STONE, PAL_IRON)


## A gable roof whose ridge runs along v (the pavilion's): `_gable` in the swapped frame.
func _kap_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float, face: Color) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, face, KAP_ROOF, false)
	_a = ka
	_b = kb


func _build_kapucyni(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var g := _g
	var c := KAP_C
	var f := 0.8
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	kit_front(KAP_O, KAP_O + KAP_A * 10.0)
	# --- the low mass: the whole footprint (aisles, wings, sacristy, apse) with a straight front
	var low := PackedVector2Array()
	for p: Vector2 in outline:
		var l := _local(p)
		if l.y > -0.5:
			l.y = 0.0
		var w := _w(l.x, l.y)
		if low.is_empty() or low[low.size() - 1].distance_to(w) > 0.05:
			low.append(w)
	var plinth := _largest(Geometry2D.offset_polygon(low, 0.25, Geometry2D.JOIN_MITER))
	_prism(plinth, g - 0.6, g + 1.0, KAP_BASE, none, M_STONE, M_STONE)
	_prism(low, g + 0.9, g + 7.4, KAP_WALL, KAP_ROOF, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(low, 0.35, Geometry2D.JOIN_MITER)), g + 7.0, g + 7.5, KAP_TRIM, KAP_ROOF, M_STONE, M_STONE)
	# --- the nave: cream walls to the eaves, the hipped copper roof, the cornice
	_lbox(c, -16.0, 9.35, 13.5, g + 7.4, g + 12.5, KAP_WALL, M_STONE, KAP_WALL)
	_prism(_rect(c, -16.0, 9.75, 13.9), g + 12.4, g + 12.9, KAP_TRIM, none, M_STONE, M_STONE)
	_hip(c, -16.0, 9.85, 14.0, g + 12.9, 5.0, KAP_ROOF)
	_kap_cross(c, -19.5, g + 17.8, 2.4)
	# --- the two wings and the pavilion block
	for sg: float in [-1.0, 1.0]:
		var wu := c + sg * 7.9
		_lbox(wu, -2.0, 4.95, 2.2, g + 7.4, g + 8.4, KAP_WALL, M_STONE, KAP_ROOF)
	_lbox(c, -3.0, 4.85, 3.9, g + 7.4, g + 11.7, KAP_WALL, M_STONE, none)
	_kap_gable(f - 0.05, -9.0, c, 4.95, g + 11.6, 3.3, KAP_PINK)
	# --- the front: landing, steps, balustrades
	kit_face(f)
	kit_ledge(c - 6.1, c + 6.1, g - 0.2, 1.3, KAP_BASE, 2.2)
	kit_cornice(c - 6.1, c + 6.1, g + 1.1, KAP_BASE.lightened(0.05), 0.25, 2.45)
	for k in 4:
		kit_ledge(c - 3.4 - 0.1 * k, c + 3.4 + 0.1 * k, g - 0.2, 0.3 + 0.3 * float(3 - k), KAP_BASE, 2.2 + 0.55 * float(k + 1))
	for sg1: float in [-1.0, 1.0]:
		var ub := c + sg1 * 5.3
		_kbox(ub - 0.18, ub + 0.18, f + 0.2, f + 2.35, g + 1.35, g + 2.3, KAP_BASE.lightened(0.04))
		var uc := c + sg1 * 3.75
		_kbox(uc - 0.12, uc + 0.12, f + 2.2, f + 3.65, g + 0.6, g + 1.5, KAP_BASE)
		for pu: float in [3.9, 4.4, 4.9]:
			_kbox(c + sg1 * pu - 0.05, c + sg1 * pu + 0.05, f + 2.2, f + 2.3, g + 1.35, g + 2.2, KAP_BASE.lightened(0.1))
	# --- the pavilion's front: pink fields, two pairs of pilasters, portal, window, entablature
	_kbox(c - 4.85, c + 4.85, f - 0.05, f + 0.05, g + 1.1, g + 10.0, KAP_PINK)
	for sg2: float in [-1.0, 1.0]:
		for pu2: float in [2.3, 4.15]:
			var u := c + sg2 * pu2
			_kbox(u - 0.55, u + 0.55, f - 0.04, f + 0.55, g + 1.1, g + 2.4, KAP_TRIM.darkened(0.04))
			kit_pilaster(u, g + 2.4, g + 10.0, KAP_TRIM, 0.85, 0.5)
		_kbox(c + sg2 * 3.2 - 0.3, c + sg2 * 3.2 + 0.3, f - 0.04, f + 0.12, g + 3.0, g + 8.2, KAP_PINK.darkened(0.08))
	kit_ledge(c - 4.9, c + 4.9, g + 10.0, 0.65, KAP_TRIM, 0.7)
	_kbox(c - 4.0, c + 4.0, f + 0.3, f + 0.38, g + 10.65, g + 11.35, KAP_INSCR)
	kit_cornice(c - 4.85, c + 4.85, g + 11.9, KAP_TRIM, 0.45, 1.1)
	kit_door(c, g + 1.1, 3.4, 1.0, KAP_TRIM, PAL_OAK, false)
	kit_window(c, g + 5.7, 3.9, Win.ARCHED, KAP_TRIM, PAL_GLASS_DARK, 0.95)
	kit_balcony(c, g + 5.7, 1.2, Balcony.STONE, KAP_TRIM, KAP_TRIM, 0.7)
	# the pediment: salmon field, stone raking cornice, a cartouche, urns on its feet, the cross
	kit_pediment(c, 4.6, g + 12.35, 3.1, KAP_PINK, KAP_TRIM.darkened(0.05), 0.75, KAP_PINK.darkened(0.1))
	var cart := _w(c, f + 0.8)
	_disc(Vector3(cart.x, g + 13.9, cart.y), Vector3(_b.x, 0.0, _b.y), 0.5, 8, KAP_TRIM)
	_kbox(c - 0.55, c + 0.55, f - 0.5, f + 0.2, g + 15.25, g + 16.1, KAP_TRIM)
	_kbox(c - 0.35, c + 0.35, f - 0.35, f + 0.05, g + 16.1, g + 17.0, KAP_TRIM)
	_kap_cross(c, f - 0.15, g + 17.0, 2.1)
	for sg3: float in [-1.0, 1.0]:
		var ur := _w(c + sg3 * 4.9, f + 0.4)
		_lbox(c + sg3 * 4.9, f + 0.4, 0.35, 0.35, g + 12.4, g + 13.3, KAP_TRIM)
		_frustum(_circle(ur, 0.2, 6), g + 13.3, _circle(ur, 0.45, 6), g + 14.2, KAP_TRIM)
		_prism(_circle(ur, 0.12, 6), g + 14.2, g + 14.7, KAP_TRIM, KAP_TRIM, M_STONE, M_STONE)
	# --- the wings: cream plinth line, door or niche, cornice, the scroll up to the pavilion
	kit_face(0.0)
	for sg4: float in [-1.0, 1.0]:
		var lo := minf(c + sg4 * 4.85, c + sg4 * 10.85)
		var hi := maxf(c + sg4 * 4.85, c + sg4 * 10.85)
		var uw := c + sg4 * 8.1
		kit_cornice(lo, hi, g + 8.4, KAP_TRIM, 0.4, 0.8)
		kit_window(uw, g + 3.4, 2.4, Win.ARCHED, KAP_TRIM, PAL_GLASS_DARK, 0.7)
		for sv: Array in [[4.85, 5.7, 11.3], [5.7, 6.6, 10.3], [6.6, 7.5, 9.5]]:
			var va := c + sg4 * float(sv[0])
			var vb := c + sg4 * float(sv[1])
			_kbox(minf(va, vb), maxf(va, vb), -0.3, 1.0, g + 8.8, g + float(sv[2]), KAP_TRIM)
	# the statue on its pedestal on the wing to the right of the pavilion
	var sp := _w(c + 7.0, 0.1)
	_lbox(c + 7.0, 0.1, 0.5, 0.5, g + 8.5, g + 10.0, KAP_TRIM)
	_frustum(_circle(sp, 0.42, 6), g + 10.0, _circle(sp, 0.25, 6), g + 12.0, PAL_GREY_STONE)
	_prism(_circle(sp, 0.2, 6), g + 12.0, g + 12.5, PAL_GREY_STONE, PAL_GREY_STONE, M_STONE, M_STONE)
	# --- the long walls: aisle windows and the nave's tall arched windows, east and west
	var e0 := _w(c - 9.35, -29.5)  # the nave's wall ends, read before the frame moves
	var e1 := _w(c - 9.35, -2.5)
	var w0 := _w(c + 9.35, -2.5)
	var w1 := _w(c + 9.35, -29.5)
	var b0 := _w(c + 9.35, -29.5)
	var b1 := _w(c - 9.35, -29.5)
	var side := func(from: Vector2, to: Vector2) -> void:
		var wl := kit_front(from, to)
		kit_face(0.0)
		for k in 4:
			var vu := wl * (0.14 + 0.24 * float(k))
			kit_window(vu, g + 8.4, 3.3, Win.ARCHED, KAP_TRIM, PAL_GLASS_DARK, 0.8)
		for k2 in 5:
			kit_pilaster(wl * (0.04 + 0.23 * float(k2)), g + 8.0, g + 12.0, KAP_TRIM, 0.7, 0.2)
	side.call(e0, e1)
	side.call(w0, w1)
	# the aisle walls: low windows round the footprint's long straight stretches
	var aisle := func(from: Vector2, to: Vector2) -> void:
		var wl := kit_front(from, to)
		kit_face(0.0)
		var n := int(wl / 6.2)
		for k in n:
			kit_window(wl * (float(k) + 0.5) / float(n), g + 2.2, 3.2, Win.ARCHED, KAP_TRIM, PAL_GLASS_DARK, 0.7)
		kit_ledge(0.0, wl, g + 1.0, 0.3, KAP_BASE, 0.15)
	aisle.call(outline[13], outline[12])
	# --- the back wall of the nave: two arched windows under the cornice
	var back := kit_front(b0, b1)
	kit_face(0.0)
	kit_window(back * 0.5, g + 8.6, 3.4, Win.ARCHED, KAP_TRIM, PAL_GLASS_DARK, 1.0)
	_collide(outline)


## The Church of the Immaculate Conception (Kościół Niepokalanego Poczęcia NMP, "Res Sacra Miser",
## Krakowskie Przedmieście 62; in the refectory of Kazanowski's palace since 1664, its front
## classicist), a narrow church whose front looks west over Skwer Hoovera to the street, between
## the white Dom Polonii (north) and a lower convent wing (south). The whole church as a model
## that replaces the old kit church (`church_niepokalanego`, built by `_build_church` until
## 2026-11-14: a tower and an onion it never had) and the LoD2 mass. From four Mapillary 360s of
## 2026 taken from the square (one straight onto the front; refs/res_sacra_miser, never shipped),
## the OSM outline (8.8 m front, 18.3 m deep, the door bay 0.75 m deep between the columns) and
## GUGiK's LoD2 (over the front's ground: cornice 12.2, the stepped attic to 14.8; nave eaves 12,
## ridge 14.8; a lower chancel behind the outline to v -24.5, eaves 6.5, hip to 11.4).
## Spec docs/landmarks/specs/niepokalanego.md.
## - the apricot front in two storeys: a lower order with two Tuscan columns before the recessed
##   door bay (the door, a fanlight lunette over it), lesenes on the corners, an inscription
##   panel and a cornice; an upper storey with a slightly proud middle field between pilaster
##   strips and a tall arched window with a keystone, a frieze panel, the dentilled top cornice;
## - the stepped attic in four tiers over the cornice and the iron cross on it;
## - behind it the nave under a low grey sheet-metal gable (kept under the attic) with its east wall, and the
##   lower chancel under a hipped roof.
## Frame: origin at the front's north end on the outline, u along the front to the south (+u to
## the viewer's right), +v out to the square (west).
const NP_O := Vector2(-655.8, -1243.3)
const NP_TO := Vector2(-652.7, -1235.1)
const NP_C := 4.5                      ## the front's mirror axis (u): the door, the window, the cross
const NP_W := 8.77                     ## the front's width
const NP_WALL := Color("#e8c19f")      ## the apricot plaster (photos: warm, a little pink)
const NP_TRIM := Color("#f0d3b6")      ## columns, cornices, surrounds
const NP_SHADE := Color("#d8ac8a")     ## recessed panels
const NP_BASE := Color("#b9b2a2")      ## plinth and steps
const NP_ROOF := Color("#7c7f84")      ## grey sheet metal
const NP_DOOR := Color("#4a3b36")      ## the dark wooden door


## GUGiK models the church and the whole convent block east of it as ONE LoD2 building (its
## centre lies outside the outline, so the site does not drop it): cut that building down to
## 0.2 m over the front's ground inside the church and its chancel. The ring stays 0.3 m inside
## the walls shared with Dom Polonii (north) and the convent wing (south), so their walls keep
## their full height.
func _np_tops() -> void:
	var a := (NP_TO - NP_O).normalized()
	var b := Vector2(-a.y, a.x)
	var ring := PackedVector2Array()
	for q: Vector2 in [Vector2(0.6, -0.1), Vector2(8.8, -0.1), Vector2(9.4, -12.6), Vector2(9.95, -22.4), Vector2(2.0, -24.25), Vector2(1.4, -13.1)]:
		ring.append(NP_O + a * q.x + b * q.y)
	lod2_tops.append([ring, 0.2, NP_O + a * NP_C + b])


## A gable roof whose ridge runs along v (the nave's): `_gable` in the swapped frame.
func _np_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, NP_WALL, NP_ROOF, true)
	_a = ka
	_b = kb


func _build_niepokalanego(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(NP_O, NP_TO)
	var c := NP_C
	var wd := NP_W
	var gp := _w(c, 1.0)
	_g = map.terrain_height(gp.x, gp.y)  # the front's ground; the plot falls 1.2 m to the back
	var g := _g
	var none := Color(0, 0, 0, 0)
	var trim := NP_TRIM
	_mode = M_STONE
	# --- the body: the outline with its front wall moved back to the door bay's (v -0.75)
	var body := _lpoly([[0.0, -0.75], [8.78, -0.75], [9.35, -12.29], [9.63, -17.85], [0.91, -18.26]])
	_prism(body, g - 1.6, g + 12.0, NP_WALL, none, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(body, 0.2, Geometry2D.JOIN_MITER)), g + 11.8, g + 12.15, trim, none, M_STONE, M_STONE)
	# --- the nave's low gable roof (ridge along v) and its east gable wall
	_np_gable(-1.0, -18.15, 4.7, 4.6, g + 12.1, 2.0)
	# --- the chancel behind the outline (LoD2): a lower block under a hipped roof
	_lbox(5.95, -21.3, 4.25, 3.15, g - 1.6, g + 6.5, NP_WALL, M_STONE, none)
	_prism(_rect(5.95, -21.3, 4.45, 3.35), g + 6.3, g + 6.65, trim, none, M_STONE, M_STONE)
	_hip(5.95, -21.3, 4.45, 3.35, g + 6.65, 4.7, NP_ROOF)
	# --- the front, lower storey: the two piers either side of the door bay, the upper wall
	_kbox(0.0, 3.35, -0.75, 0.0, g - 0.4, g + 6.1, NP_WALL)
	_kbox(5.65, wd, -0.75, 0.0, g - 0.4, g + 6.1, NP_WALL)
	_kbox(0.0, wd, -0.75, 0.0, g + 6.0, g + 12.0, NP_WALL)
	kit_face(0.0)
	kit_ledge(0.0, 3.35, g - 0.3, 0.6, NP_BASE, 0.12)
	kit_ledge(5.65, wd, g - 0.3, 0.6, NP_BASE, 0.12)
	for lu: float in [0.4, wd - 0.4]:
		kit_pilaster(lu, g + 0.3, g + 5.9, trim, 0.7, 0.1)
	# the door bay: a step, the door, the fanlight lunette over it
	_kbox(3.35, 5.65, -0.75, 0.25, g - 0.4, g + 0.15, NP_BASE)
	kit_face(-0.75)
	kit_door(c, g + 0.15, 2.45, 0.68, trim, NP_DOOR, false)
	var at := _w(c, -0.75)
	_arch_panel(at, _a, _b, 0.92, g + 3.25, g + 3.3, trim, 0.03, M_STONE)
	_arch_panel(at, _a, _b, 0.76, g + 3.3, g + 3.35, PAL_GLASS_DARK, 0.06, _lit(c, g + 3.3))
	# the two Tuscan columns before the bay, carrying the architrave
	for sg: float in [-1.0, 1.0]:
		kit_column(c + sg * 1.45, -0.15, g + 0.15, g + 5.95, trim, 0.36)
	# the lower entablature: architrave, the inscription panel, the cornice
	kit_face(0.0)
	kit_ledge(0.0, wd, g + 5.95, 0.4, trim, 0.1)
	_kbox(1.9, 7.1, -0.02, 0.04, g + 6.55, g + 6.95, NP_SHADE)
	_kbox(0.0, wd, -0.1, 0.16, g + 7.1, g + 7.25, trim)
	_kbox(-0.1, wd + 0.1, -0.1, 0.42, g + 7.25, g + 7.6, trim)
	# --- the upper storey: the proud middle field, pilaster strips, the arched window
	_kbox(1.7, 7.3, -0.05, 0.12, g + 7.6, g + 11.35, NP_WALL)
	kit_face(0.12)
	for pu: float in [1.95, 7.05]:
		kit_pilaster(pu, g + 7.6, g + 11.35, trim, 0.46, 0.08)
	for sg2: float in [-1.0, 1.0]:
		kit_pilaster(c + sg2 * 1.4, g + 7.6, g + 9.9, trim, 0.36, 0.06)
	var wa := _w(c, 0.12)
	_arch_panel(wa, _a, _b, 1.0, g + 8.0, g + 10.0, trim, 0.03, M_STONE)
	_arch_panel(wa, _a, _b, 0.74, g + 8.1, g + 10.0, PAL_GLASS_DARK, 0.07, _lit(c, g + 8.1))
	_kbox(c - 0.17, c + 0.17, 0.1, 0.32, g + 10.75, g + 11.15, trim)  # the keystone
	_kbox(c - 0.95, c + 0.95, 0.1, 0.3, g + 7.85, g + 8.0, trim)  # the sill
	_kbox(1.75, 7.25, 0.08, 0.16, g + 11.4, g + 11.65, NP_SHADE)  # the frieze panel
	# the top cornice: a dentil band and the slab
	_kbox(0.0, wd, -0.1, 0.24, g + 11.65, g + 11.85, trim.darkened(0.05))
	_kbox(-0.2, wd + 0.2, -0.2, 0.55, g + 11.85, g + 12.3, trim)
	# --- the stepped attic: four tiers with copings, the cross on the top one
	var tiers: Array = [[0.15, wd - 0.15, 12.3, 13.05], [0.95, wd - 0.95, 13.05, 13.55], [1.7, wd - 1.7, 13.55, 14.05], [2.45, wd - 2.45, 14.05, 14.75]]
	for t: Array in tiers:
		_kbox(float(t[0]), float(t[1]), -0.95, 0.0, g + float(t[2]), g + float(t[3]) - 0.1, NP_WALL)
		_kbox(float(t[0]) - 0.08, float(t[1]) + 0.08, -1.0, 0.08, g + float(t[3]) - 0.1, g + float(t[3]), trim)
	_kbox(c - 0.3, c + 0.3, -0.75, -0.15, g + 14.75, g + 15.1, trim)
	_kap_cross(c, -0.45, g + 15.1, 1.7)
	_collide(outline)


## The Pentecostal church (Kościół Zielonoświątkowy, Sienna), a modernist hall of the 1950s on a
## corner of Sienna: a brick ground floor under a cream plastered upper volume that oversails it on
## a pier at the entrance, groups of three tall cream fins on its end walls, a flat roof, a tall
## brick stair block beside the entrance. The whole building as a model that replaces the old kit
## church (`church_zielonoswiatkowy`, built by `_build_church` until 2026-11-14: a gabled "modern"
## church box). From Mapillary photos of 2021 taken along Sienna and the side street (refs/
## zielonoswiatkowy, never shipped), the OSM outline and GUGiK's LoD2 (flat roofs: the hall 12, the
## east wing 9.4, the stair block 14). Spec docs/landmarks/specs/zielonoswiatkowy.md.
## Frame: origin at the outline's centre, u along the building (axis (-0.3881, 0.9216)), +v to the
## hall's side; the hall is the half with v over 6, the lower wing the other.
const ZL_O := Vector2(-1890.1, 331.7)
const ZL_A := Vector2(-0.3881, 0.9216)
const ZL_BRICK := Color("#8f4a36")     ## the dark red brick of the ground floor and the stair block
const ZL_CREAM := Color("#e2d6bf")     ## the cream plaster of the upper volume
const ZL_FIN := Color("#ece3d0")       ## the fins and the copings, a shade paler
const ZL_ROOF := Color("#8e8f8c")      ## the flat roofs


## The windows and the fin groups on every edge of `ring` longer than 4 m, between y0 and y1
## (absolute): a fin group of three ribs at a quarter and three quarters of an edge longer than
## 9 m, square windows every 2.6 m on the storeys at `rows` (absolute sills) clear of the fins.
func _zl_dress(ring: PackedVector2Array, y0: float, y1: float, rows: Array, fins: bool) -> void:
	var n := ring.size()
	var keep := _mode
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		var l := p.distance_to(q)
		if l < 4.0:
			continue
		var d := (q - p) / l
		var out := _out(ring, p, q)
		var spots: Array[float] = []
		if fins and l > 9.0:
			spots = [l * 0.25, l * 0.75]
			for s: float in spots:
				for k in 3:
					var c := p + d * (s + (k - 1) * 0.6) + out * 0.2
					_mode = M_STONE
					_prism(_circle(c, 0.24, 4), y0 + 0.4, y1 - 0.5, ZL_FIN, ZL_FIN, M_STONE, M_STONE)
		var t := 1.6
		while t < l - 1.4:
			var clear := true
			for s2: float in spots:
				if absf(t - s2) < 1.6:
					clear = false
			if clear:
				for r in rows:
					var y := float(r)
					_mode = _lit(t + p.x, y)
					_wall(p + d * (t - 0.6) + out * 0.05, p + d * (t + 0.6) + out * 0.05, y, y + 1.5, out, PAL_GLASS_DARK)
			t += 2.6
	_mode = keep


func _build_zielonoswiatkowy(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(ZL_O, ZL_O + ZL_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var hall_half := _lpoly([[-40.0, 6.0], [40.0, 6.0], [40.0, 30.0], [-40.0, 30.0]])
	var wing_half := _lpoly([[-40.0, -30.0], [40.0, -30.0], [40.0, 6.0], [-40.0, 6.0]])
	var hall := _largest(Geometry2D.intersect_polygons(outline, hall_half))
	var wing := _largest(Geometry2D.intersect_polygons(outline, wing_half))
	# --- the hall: a brick ground floor, the cream volume to 12, a coping, the flat roof
	_prism(hall, g - 1.0, g + 4.0, ZL_BRICK, none, M_STONE)
	_prism(hall, g + 4.0, g + 12.0, ZL_CREAM, ZL_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(hall, g + 11.7, 0.4, ZL_FIN, 0.12)
	kit_ledge_ring(hall, g + 3.85, 0.3, ZL_FIN, 0.2)
	_zl_dress(hall, g + 4.0, g + 12.0, [g + 5.3, g + 8.5], true)
	_zl_dress(hall, g, g + 4.0, [g + 1.3], false)
	# --- the lower wing: the same two materials, flat roof at 9.4
	_prism(wing, g - 1.0, g + 3.6, ZL_BRICK, none, M_STONE)
	_prism(wing, g + 3.6, g + 9.4, ZL_CREAM, ZL_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(wing, g + 9.1, 0.4, ZL_FIN, 0.12)
	_zl_dress(wing, g + 3.6, g + 9.4, [g + 5.2, g + 7.4], false)
	_zl_dress(wing, g, g + 3.6, [g + 1.2], false)
	# --- the tall brick stair block by the entrance, a slit window up it
	_kbox(-21.2, -16.8, 6.0, 10.2, g - 1.0, g + 14.0, ZL_BRICK)
	_kbox(-21.3, -16.7, 5.9, 10.3, g + 13.7, g + 14.1, ZL_FIN)
	_kbox(-19.3, -18.7, 10.2, 10.26, g + 4.5, g + 12.5, PAL_GLASS_DARK, _lit(-19.0, g + 4.5))
	# --- the entrance under the oversailing upper volume: its pier and the dark glazed doors
	_kbox(-24.6, -23.9, 4.2, 4.9, g - 1.0, g + 4.0, ZL_FIN)
	var e0 := _w(-22.4, 1.2)
	var e1 := _w(-19.2, 4.2)
	_mode = M_STONE
	_wall(e0, e1, g, g + 2.6, (e1 - e0).orthogonal().normalized() * -1.0, PAL_DARK_DOOR)
	_collide(outline)


## The Church of Divine Mercy and St Faustina (Kościół pw. Miłosierdzia Bożego i Świętej Faustyny,
## Żytnia; the Sisters of Our Lady of Mercy, where St Faustina entered in 1925), a plain white
## plastered church in the sisters' convent on Żytnia. The whole church as a model that replaces
## the old kit church (`church_miloserdzie`, built by `_build_church` until 2026-11-14: a "modern"
## box with a pyramid tower). From Mapillary photos of 2017 and 2025 taken along Żytnia (refs/
## miloserdzie, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the nave's eaves
## 8.3, its low ridge 10.3; the low annexes along the street and the south side 4.3; the slim
## bell tower to 20 with a dome to 25; the three-storey house at the east end 12.5 with a hip).
## Spec docs/landmarks/specs/miloserdzie.md.
## - the slim square white bell tower at the street corner: a plain shaft, a cornice, an open
##   arched lantern stage, a cornice, a small grey dome and a cross;
## - the nave under a low grey gable, its street wall carrying the big mural in the flag's white and
##   red (a flat panel); the low annex in front of it with the door under a little tiled porch roof;
## - the sisters' white house at the east end under a dark tiled hip, two rows of windows a side.
## Frame: origin at the outline's centre, u along the church to the east (the house), +v to the
## south; the street (Żytnia) runs along the north side (-v).
const FA_O := Vector2(-2748.8, -692.9)
const FA_A := Vector2(-0.2703, -0.9628)
const FA_WALL := Color("#ecebe6")      ## the white plaster (photos: a cool white)
const FA_TRIM := Color("#f4f3ef")      ## cornices, piers
const FA_ROOF := Color("#9a4034")      ## the nave's red tiles (Commons photos 2026-11-14; was grey)
const FA_TILE := Color("#8c3b31")      ## the house's red tiles (Commons photos)
const FA_DOME := Color("#6f9584")      ## the tower's green copper dome (Commons photos)
const FA_RED := Color("#c23a3a")       ## the mural's red
const FA_MURAL := Color("#5d5f63")     ## the mural's dark figures and emblem
const FA_BASE := Color("#8a5040")      ## the brick plinth of the street annex


func _build_miloserdzie(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(FA_O, FA_O + FA_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the nave: walls to 8.3, a low gable along u to 10.3
	var nave := _rect(-4.3, -0.15, 15.3, 4.65)  # u -19.6..11, v -4.8..4.5
	_prism(nave, g - 1.0, g + 8.3, FA_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 7.95, 0.35, FA_TRIM, 0.15)
	_gable(-19.6, 11.0, -0.15, 4.95, g + 8.3, 2.0, FA_WALL, FA_ROOF, true)
	# the nave's tall windows on the south side and the west end (the street side has the mural)
	kit_face(4.5)
	for wu: float in [-15.0, -9.5, -4.0, 1.5, 7.0]:
		_kbox(wu - 0.65, wu + 0.65, 4.45, 4.55, g + 4.9, g + 7.4, PAL_GLASS_DARK, _lit(wu, g + 4.9))
	# --- the mural on the street wall over the annex: white-red flag field, emblem, figures
	_kbox(-6.0, 5.0, -4.84, -4.8, g + 4.3, g + 7.8, FA_WALL.darkened(0.04))
	_kbox(-5.2, -1.2, -4.9, -4.84, g + 4.6, g + 5.9, FA_RED)
	_kbox(-3.9, -2.4, -4.94, -4.84, g + 4.6, g + 7.4, FA_MURAL)
	_kbox(0.3, 4.2, -4.9, -4.84, g + 4.6, g + 7.5, FA_MURAL.lightened(0.25))
	# --- the low annexes: along the street (north), the south side and its porch
	var north := _lpoly([[-7.15, -8.3], [11.0, -8.3], [11.0, -4.8], [-7.15, -4.8]])
	_prism(north, g - 1.0, g + 4.3, FA_WALL, FA_ROOF.lightened(0.1), M_STONE, M_STONE)
	_kbox(-7.15, 11.0, -8.42, -8.3, g - 1.0, g + 0.9, FA_BASE)
	kit_face(-8.3)
	for du: float in [-3.0, 3.5]:
		_kbox(du - 0.6, du + 0.6, -8.36, -8.3, g + 0.0, g + 2.4, PAL_DARK_DOOR)
	_kbox(1.6, 5.4, -9.6, -8.3, g + 2.6, g + 2.8, FA_TRIM)
	for wn: float in [-5.5, -1.0, 6.0, 9.0]:
		_kbox(wn - 0.45, wn + 0.45, -8.36, -8.3, g + 1.5, g + 3.0, PAL_GLASS_DARK, _lit(wn, g + 1.5))
	var south := _lpoly([[-11.0, 4.5], [11.0, 4.5], [11.0, 7.2], [3.1, 7.2], [3.1, 9.25], [-0.65, 9.25], [-0.65, 7.2], [-11.0, 7.2]])
	_prism(south, g - 1.0, g + 4.3, FA_WALL, FA_ROOF.lightened(0.1), M_STONE, M_STONE)
	# --- the sisters' house at the east end: three storeys, a dark tiled hip
	_kbox(11.0, 19.7, -8.3, 6.4, g - 1.0, g + 11.0, FA_WALL)
	kit_ledge_ring(_rect(15.35, -0.95, 4.35, 7.35), g + 10.7, 0.3, FA_TRIM, 0.25)
	_hip(15.35, -0.95, 4.6, 7.6, g + 11.0, 2.4, FA_TILE)
	for sv: float in [-1.0, 1.0]:
		kit_face(-8.3 if sv < 0.0 else 6.4)
		for hu: float in [12.9, 17.8]:
			for hy: float in [4.2, 7.6]:
				_kbox(hu - 0.55, hu + 0.55, _face - 0.03, _face + 0.03, g + hy, g + hy + 1.5, PAL_GLASS_DARK, _lit(hu * sv, g + hy))
	for hv: float in [-5.0, 3.0]:
		for hy2: float in [1.0, 4.2, 7.6]:
			_kbox(19.67, 19.73, hv - 0.55, hv + 0.55, g + hy2, g + hy2 + 1.5, PAL_GLASS_DARK, _lit(hv, g + hy2))
	# --- the bell tower at the street corner: shaft, lantern stage, dome, cross
	var tu := -9.225
	var tv := -6.975
	_lbox(tu, tv, 2.075, 1.975, g - 1.0, g + 18.0, FA_WALL, M_STONE, none)
	_lbox(tu, tv, 2.25, 2.15, g + 18.0, g + 18.4, FA_TRIM, M_STONE, FA_TRIM)
	kit_face(-8.95)
	_disc(Vector3(_w(tu, -8.98).x, g + 16.4, _w(tu, -8.98).y), Vector3(-_b.x, 0.0, -_b.y), 0.5, 10, PAL_DARK_STEEL)
	for pu: float in [-1.0, 1.0]:
		for pv: float in [-1.0, 1.0]:
			_lbox(tu + pu * 1.3, tv + pv * 1.2, 0.35, 0.35, g + 18.4, g + 21.1, FA_WALL, M_STONE, none)
	_lbox(tu, tv, 0.9, 0.85, g + 18.4, g + 21.1, CHURCH_DARK, M_STONE, none)
	_lbox(tu, tv, 1.85, 1.75, g + 21.0, g + 21.4, FA_WALL, M_STONE, none)
	_lbox(tu, tv, 2.0, 1.9, g + 21.4, g + 21.8, FA_TRIM, M_STONE, FA_TRIM)
	var tc := _w(tu, tv)
	_frustum(_circle(tc, 1.6, 8), g + 21.8, _circle(tc, 1.35, 8), g + 22.9, FA_DOME)
	_frustum(_circle(tc, 1.35, 8), g + 22.9, _circle(tc, 0.35, 8), g + 24.3, FA_DOME.lightened(0.06))
	_kap_cross(tu, tv, g + 24.3, 1.6)
	_collide(outline)


## The parish church of the Child Jesus (Kościół parafialny pw. Dzieciątka Jezus, by the Child Jesus
## hospital between Lindleya and Oczki), a red-brick neo-Gothic hall church. The whole church as a
## model that replaces the old kit church (`church_dzieciatka`, built by `_build_church` until
## 2026-11-14: a beige "modern" box with a pyramid tower on the wrong, east end). From Mapillary
## photos of 2019-2026 taken from Lindleya, Oczki and Chałubińskiego (refs/dzieciatka, never shipped),
## the OSM outline and GUGiK's LoD2 (over the ground: the nave's eaves 11 and its one big gable
## ridge 18; the tower's eaves 23 and its roof 28; the short transepts' eaves 8 and ridges 12.7;
## the chancel's eaves 11.3, ridge 15 and its three-sided east end; the low annexes 3.3 to 6.6, the
## sacristy 9.5). Spec docs/landmarks/specs/dzieciatka.md.
## - the tower stands in the middle of the WEST front, 0.7 m proud: a pointed portal over steps,
##   a tall lancet, two string courses, a belfry with two louvred lancets a side and an oculus
##   over them, a brick eaves band, four corner pinnacles and a green copper hipped roof with a cross;
## - the nave and aisles under one steep dark green roof (45 degrees), buttresses and tall lancets
##   in cream plastered recesses, a corbelled eaves band;
## - two short transepts with stepped gables filled with cream blind lancets, a big lancet below;
## - the lower chancel with a three-sided east end, low lean-to annexes north and south, the
##   flat sacristy at the east end.
## Frame: origin at the nave's north-west corner area, u along the church to the east (the chancel),
## +v to the south; the front faces -u (west).
const DZ_O := Vector2(-1842.0, 980.0)
const DZ_A := Vector2(0.9353, -0.3539)
const DZ_C := 4.875                    ## the church's axis (v): the tower, the portal, the ridges
const DZ_BRICK := Color("#a5482f")     ## the red brick (photos: warm, a little orange)
const DZ_BRICK_LT := Color("#b65c40")  ## bands, buttress caps, the portal's frame
const DZ_CREAM := Color("#e4d6b6")     ## the plastered recesses and blind panels
const DZ_ROOF := Color("#4f6b5c")      ## the nave's dark green copper
const DZ_COPPER := Color("#6e9a86")    ## the tower's paler verdigris
const DZ_BASE := Color("#8e8a82")      ## the granite plinth and steps
const DZ_DOOR := Color("#3b2e2a")      ## the dark oak doors


## A pointed recess with its pane: the cream field `hw` + 0.25 wide, the glass `hw` inside it,
## 4 cm apart (`_wall` drops a later wall within 3 cm of an earlier one in its plane).
func _dz_lancet(u: float, v: float, along: Vector2, out: Vector2, hw: float, y0: float, spring: float,
		field := DZ_CREAM) -> void:
	var at := _w(u, v)
	_lancet_panel(at, along, out, hw + 0.25, y0 - 0.2, spring, field, 0.03, M_STONE)
	_lancet_panel(at, along, out, hw, y0, spring, PAL_GLASS_DARK, 0.07, _lit(u + v, y0))


## A gable roof whose ridge runs along v (a transept's): `_gable` in the swapped frame.
func _dz_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, DZ_BRICK, DZ_ROOF, false)
	_a = ka
	_b = kb


## A transept's front: the wall's big lancet and the stepped gable over the roof, five steps a
## side with a cream blind lancet in each of the three middle ones. `vf` is the face, `s` its
## outward sign in v.
func _dz_transept_front(vf: float, s: float, g: float) -> void:
	var cu := 12.45
	var hu := 3.05
	var out := _b * s
	_dz_lancet(cu, vf, _a, out, 0.85, g + 2.5, g + 5.7)
	# the steps: boxes standing 0.15 m out of the face, each 0.6 m narrower a side and 0.95 m higher
	var v0 := vf + s * 0.15
	var v1 := vf - s * 0.35
	for k in 5:
		var hw := hu + 0.1 - k * 0.6
		var y0 := g + 8.0 + k * 0.95
		_kbox(cu - hw, cu + hw, minf(v0, v1), maxf(v0, v1), y0 if k > 0 else g + 7.6, y0 + 0.95, DZ_BRICK)
		_kbox(cu - hw - 0.05, cu - hw + 0.45, minf(v0, v1) - 0.05, maxf(v0, v1) + 0.05, y0 + 0.85, y0 + 1.05, DZ_BRICK_LT)
		_kbox(cu + hw - 0.45, cu + hw + 0.05, minf(v0, v1) - 0.05, maxf(v0, v1) + 0.05, y0 + 0.85, y0 + 1.05, DZ_BRICK_LT)
	for d: float in [-1.0, 0.0, 1.0]:
		_lancet_panel(_w(cu + d * 1.1, v0), _a, out, 0.32, g + 8.4, g + (10.9 if d == 0.0 else 10.0), DZ_CREAM, 0.03, M_STONE)


## A buttress on a long wall at u, standing `s` (outward sign in v) out of the face at vf.
func _dz_buttress(u: float, vf: float, s: float, g: float, top: float) -> void:
	var a := vf
	_kbox(u - 0.35, u + 0.35, minf(a, a + s * 0.75), maxf(a, a + s * 0.75), g - 1.0, g + top - 1.8, DZ_BRICK)
	_kbox(u - 0.38, u + 0.38, minf(a, a + s * 0.8), maxf(a, a + s * 0.8), g + top - 1.8, g + top - 1.6, DZ_BRICK_LT)
	_kbox(u - 0.3, u + 0.3, minf(a, a + s * 0.42), maxf(a, a + s * 0.42), g + top - 1.6, g + top, DZ_BRICK)


func _build_dzieciatka(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(DZ_O, DZ_O + DZ_A)
	var c := DZ_C
	var gp := _w(-3.0, c)
	_g = map.terrain_height(gp.x, gp.y)  # the street's ground before the tower (14.5; the plot is flat)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the nave and aisles: one box, a plinth, the corbelled eaves band, one steep gable roof
	var nave := _rect(10.0, c, 9.6, 7.075)  # u 0.4..19.6, v -2.2..11.95
	_prism(nave, g - 1.0, g + 11.0, DZ_BRICK, none, M_STONE)
	kit_ledge_ring(nave, g - 1.0, 1.6, DZ_BASE, 0.1)
	kit_ledge_ring(nave, g + 10.3, 0.7, DZ_BRICK_LT, 0.18)
	_gable(0.4, 19.6, c, 7.45, g + 11.0, 7.0, DZ_BRICK, DZ_ROOF, true)
	# the side walls: buttresses and lancets in cream recesses (two bays west of the transepts,
	# one east of them, its sill over the annex roofs)
	for s: float in [-1.0, 1.0]:
		var vf := c + s * 7.075
		for bu: float in [0.75, 4.95]:
			_dz_buttress(bu, vf, s, g, 9.4)
		for wu: float in [2.85, 7.1]:
			_dz_lancet(wu, vf, _a, _b * s, 0.7, g + 3.0, g + 8.0)
		_dz_lancet(17.55, vf, _a, _b * s, 0.7, g + 5.2, g + 8.2)
	# the west wall either side of the tower: an aisle lancet each, a corner buttress
	for wv: float in [0.0, 9.75]:
		_dz_lancet(0.4, wv, -_b, -_a, 0.6, g + 3.2, g + 7.6)
	for cv: float in [-2.2, 11.95]:
		_kbox(-0.35, 0.4, cv - 0.35, cv + 0.35, g - 1.0, g + 8.5, DZ_BRICK)
		_kbox(-0.4, 0.4, cv - 0.4, cv + 0.4, g + 8.5, g + 8.7, DZ_BRICK_LT)
	# --- the transepts: u 9.4..15.5, out to v -3.8 and 13.65, eaves 8, ridge 12.7
	_kbox(9.4, 15.5, -3.8, -2.2, g - 1.0, g + 8.0, DZ_BRICK)
	_kbox(9.4, 15.5, 11.95, 13.65, g - 1.0, g + 8.0, DZ_BRICK)
	_dz_gable(-3.6, 1.5, 12.45, 3.25, g + 8.0, 4.7)
	_dz_gable(13.45, 8.2, 12.45, 3.25, g + 8.0, 4.7)
	_dz_transept_front(-3.8, -1.0, g)
	_dz_transept_front(13.65, 1.0, g)
	# --- the chancel: narrower and lower, a three-sided east end under its own roof
	var ch := _lpoly([[19.6, 0.9], [28.0, 0.9], [31.5, 3.0], [31.5, 6.75], [28.0, 8.85], [19.6, 8.85]])
	_prism(ch, g - 1.0, g + 11.3, DZ_BRICK, none, M_STONE)
	kit_ledge_ring(ch, g + 10.7, 0.6, DZ_BRICK_LT, 0.15)
	_gable(28.0, 19.6, c, 4.2, g + 11.3, 3.7, DZ_BRICK, DZ_ROOF, false)
	var apex := _w(28.0, c)
	var a3 := Vector3(apex.x, g + 15.0, apex.y)
	var eaves: Array = [[28.0, c - 4.2], [31.75, 2.85], [31.75, 6.9], [28.0, c + 4.2]]
	for k in 3:
		var p: Vector2 = _w(float(eaves[k][0]), float(eaves[k][1]))
		var q: Vector2 = _w(float(eaves[k + 1][0]), float(eaves[k + 1][1]))
		var pa := Vector3(p.x, g + 11.3, p.y)
		var pb := Vector3(q.x, g + 11.3, q.y)
		var n := (pb - pa).cross(a3 - pa).normalized()
		if n.y < 0.0:
			n = -n
		_tri(pa, pb, a3, n, DZ_ROOF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	for s2: float in [-1.0, 1.0]:
		for wu2: float in [22.0, 25.6]:
			_dz_lancet(wu2, c + s2 * 3.975, _a, _b * s2, 0.55, g + 6.9, g + 9.3)
	# --- the low annexes: north along the transept and chancel, south by the chancel, the sacristy
	var north := _lpoly([[15.5, -4.1], [27.6, -4.1], [27.6, 0.9], [19.6, 0.9], [19.6, -2.2], [15.5, -2.2]])
	_prism(north, g - 1.0, g + 3.4, DZ_BRICK, none, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(north, 0.25, Geometry2D.JOIN_MITER)), g + 3.4, g + 3.75, DZ_BRICK_LT, DZ_ROOF, M_STONE, M_STONE)
	var south := _lpoly([[19.6, 8.85], [27.6, 8.85], [27.1, 11.9], [19.6, 11.95]])
	_prism(south, g - 1.0, g + 4.4, DZ_BRICK, none, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(south, 0.25, Geometry2D.JOIN_MITER)), g + 4.4, g + 4.75, DZ_BRICK_LT, DZ_ROOF, M_STONE, M_STONE)
	_kbox(31.4, 35.4, 0.7, 9.3, g - 1.0, g + 9.2, DZ_BRICK)
	kit_ledge_ring(_rect(33.4, 5.0, 2.0, 4.3), g + 8.7, 0.5, DZ_BRICK_LT, 0.15)
	_hip(33.4, 5.0, 2.15, 4.45, g + 9.2, 0.8, DZ_ROOF)
	for su: float in [-1.0, 1.0]:
		_dz_lancet(33.4, c + (-4.175 if su < 0.0 else 4.425), _a, _b * su, 0.45, g + 3.0, g + 6.0)
		_dz_lancet(23.5, c + (-8.975 if su < 0.0 else 7.075), _a, _b * su, 0.4, g + 0.9, g + 2.3)
	# --- the tower: u -0.6..4.6, v 2.05..7.95, walls to 23, the copper hip to 28 and a cross
	var tw := _rect(2.0, c, 2.6, 2.95)
	_prism(tw, g - 1.0, g + 23.0, DZ_BRICK, none, M_STONE)
	kit_ledge_ring(tw, g - 1.0, 1.7, DZ_BASE, 0.1)
	for sy: float in [11.6, 16.9]:
		kit_ledge_ring(tw, g + sy, 0.35, DZ_BRICK_LT, 0.12)
	kit_ledge_ring(tw, g + 22.4, 0.6, DZ_BRICK_LT, 0.22)
	_hip(2.0, c, 2.85, 3.2, g + 23.0, 5.0, DZ_COPPER)
	_kap_cross(2.0, c, g + 27.9, 2.1)
	for pu: float in [-0.45, 4.45]:
		for pv: float in [2.2, 7.55]:
			_pinnacle(pu, pv, 0.55, g + 23.0, 3.2, DZ_BRICK)
	# the west corner buttresses, stepped
	for bv: float in [2.05, 7.95]:
		_kbox(-1.3, -0.6, bv - 0.35, bv + 0.35, g - 1.0, g + 9.6, DZ_BRICK)
		_kbox(-1.35, -0.6, bv - 0.4, bv + 0.4, g + 9.6, g + 9.8, DZ_BRICK_LT)
		_kbox(-0.95, -0.6, bv - 0.3, bv + 0.3, g + 9.8, g + 11.6, DZ_BRICK)
	# the portal: steps, a lighter brick frame, the pointed door; the tall lancet over it
	for k in 3:
		_kbox(-1.6 - 0.45 * (2 - k), -0.6, c - 1.9 + 0.25 * k, c + 1.9 - 0.25 * k, g - 0.6, g + 0.05 + 0.15 * k, DZ_BASE)
	# the tall cream recess of the lower stage (photo from Lindleya's south end): the door at its
	# foot, the lancet window over it; the stepped gable standing on the string course above
	var pt := _w(-0.6, c)
	_lancet_panel(pt, -_b, -_a, 1.35, g + 0.4, g + 8.6, DZ_CREAM, 0.03, M_STONE)
	_lancet_panel(pt, -_b, -_a, 0.95, g + 0.4, g + 2.6, DZ_DOOR, 0.08, M_STONE)
	_lancet_panel(pt, -_b, -_a, 0.8, g + 4.7, g + 8.6, PAL_GLASS_DARK, 0.08, _lit(-0.6, g + 4.7))
	for k2 in 4:
		var sw := 2.45 - 0.5 * k2
		_kbox(-0.95, -0.6, c - sw, c + sw, g + 11.95 + 0.95 * k2, g + 12.9 + 0.95 * k2, DZ_BRICK)
		_kbox(-1.0, -0.6, c - sw - 0.05, c - sw + 0.4, g + 12.8 + 0.95 * k2, g + 13.0 + 0.95 * k2, DZ_BRICK_LT)
		_kbox(-1.0, -0.6, c + sw - 0.4, c + sw + 0.05, g + 12.8 + 0.95 * k2, g + 13.0 + 0.95 * k2, DZ_BRICK_LT)
	for d3: float in [-1.0, 0.0, 1.0]:
		_lancet_panel(_w(-0.95, c + d3 * 1.05), -_b, -_a, 0.3, g + 12.3, g + (14.6 if d3 == 0.0 else 13.7), DZ_CREAM, 0.03, M_STONE)
	# the belfry: two louvred lancets on every face, an oculus over them
	var faces: Array = [[-0.6, c, -_b, -_a], [4.6, c, _b, _a], [2.0, c - 2.95, _a, -_b], [2.0, c + 2.95, _a, _b]]
	for f: Array in faces:
		var along: Vector2 = f[2]
		var out: Vector2 = f[3]
		var fc := _w(float(f[0]), float(f[1]))
		for d2: float in [-1.0, 1.0]:
			_lancet_panel(fc + along * d2 * 1.0, along, out, 0.6, g + 17.4, g + 19.6, DZ_BRICK_LT, 0.04, M_STONE)
			_lancet_panel(fc + along * d2 * 1.0, along, out, 0.42, g + 17.6, g + 19.6, CHURCH_DARK, 0.09, M_STONE)
		var oc := fc + out * 0.06
		_disc(Vector3(oc.x, g + 21.5, oc.y), Vector3(out.x, 0.0, out.y), 0.55, 10, DZ_CREAM)
	_collide(outline)


## St Charles Borromeo (Kościół św. Karola Boromeusza, ul. Chłodna 21; Henryk Marconi, 1841-49,
## rebuilt after 1944), a cream classicist basilica between Chłodna and Elektoralna. The whole
## church as a model that replaces the old kit church (`church_karol`, built by `_build_church`
## until 2026-11-14: a beige box with a kit tower). From Mapillary photos of 2019-2026 taken along
## Elektoralna and from the Chłodna corner (refs/karol, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the nave and its clerestory 16 with a low ridge 17; the aisles
## and the west block 10 to 11; the transept 10.5 to 11; the apse 11 and its half dome to 14).
## Spec docs/landmarks/specs/karol.md.
## - the west front on Chłodna: a pedimented portal and a tall round-headed window between
##   pilasters, the nave's pediment over it and the two slim towers on its corners (a square
##   shaft, an arched belfry with corner urns, an octagonal arcaded lantern, a small grey dome
##   and a cross; neither is in OSM or LoD2, placed from the photos);
## - the nave's clerestory with round-headed windows, the lower aisles with pilasters and the
##   tall relief panels between them over a grey plinth;
## - the transept with a pediment, a pedimented door and a lunette at each end;
## - the semicircular apse to Elektoralna with pilasters, a cornice and a grey-green half dome;
##   the nave's east pediment over it with a little arched bell-cote and a cross.
## Frame: origin by the crossing's west side, u along the church to the east (the apse), +v to
## the south; the front faces -u (west).
const KB_O := Vector2(-2151.7, -460.7)
const KB_A := Vector2(0.8643, -0.5029)
const KB_C := -0.1                     ## the church's axis (v): the portal, the ridges, the apse
const KB_WALL := Color("#e6d6a8")      ## the warm cream plaster (photos)
const KB_TRIM := Color("#f1e9cf")      ## pilasters, cornices, pediments
const KB_RELIEF := Color("#d3c296")    ## the shadowed relief panels and recesses
const KB_ROOF := Color("#70757a")      ## the grey sheet roofs
const KB_DOME := Color("#5f6f68")      ## the apse's dark grey-green half dome
const KB_TOWER_ROOF := Color("#7d8287") ## the towers' small grey domes
const KB_BASE := Color("#a29d91")      ## the grey stone plinth
const KB_DOOR := Color("#4a3a30")      ## the dark wooden doors


## Turns the kit frame so that +v points out of one side of the church (0 south, 1 west, 2 north,
## 3 east) and kit_pilaster, kit_door and kit_pediment work on it: a point (u, v) of the church's
## frame is then (v, -u), (-u, -v) or (-v, u) in the turned one.
func _kb_turn(side: int) -> void:
	var b := Vector2(-KB_A.y, KB_A.x)
	match side:
		0:
			_a = KB_A
		1:
			_a = b
		2:
			_a = -KB_A
		_:
			_a = -b
	_b = Vector2(-_a.y, _a.x)


## A round-headed window on the turned frame's face: a trim surround and the pane 4 cm over it.
func _kb_arch_win(u: float, y0: float, spring: float, hw: float) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.2, y0 - 0.15, spring, KB_TRIM, 0.03, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, spring, PAL_GLASS_DARK, 0.07, _lit(u + _face, y0))


## An octagon of radius `r` round c whose faces look along the church's axes (so arches sit
## flat on them): corners at 22.5 degrees off the axes.
func _kb_oct(c: Vector2, r: float) -> PackedVector2Array:
	var b := Vector2(-KB_A.y, KB_A.x)
	var ring := PackedVector2Array()
	for k in 8:
		var ang := PI * (k + 0.5) / 4.0
		ring.append(c + (KB_A * cos(ang) + b * sin(ang)) * r)
	return ring


## One of the two west towers at (tu, tv) of the church's frame, from its foot on the west block
## (y0) to the cross: shaft, belfry with an arched opening a side and corner urns, an octagonal
## lantern with four arches, a small dome and a cross.
func _kb_tower(tu: float, tv: float, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var hw := 1.6
	_lbox(tu, tv, hw, hw, g + 9.0, g + 20.0, KB_WALL, M_STONE, none)
	_lbox(tu, tv, hw + 0.18, hw + 0.18, g + 19.6, g + 20.1, KB_TRIM, M_STONE, KB_TRIM)
	_lbox(tu, tv, hw - 0.15, hw - 0.15, g + 20.1, g + 24.0, KB_WALL, M_STONE, none)
	_lbox(tu, tv, hw + 0.05, hw + 0.05, g + 23.6, g + 24.1, KB_TRIM, M_STONE, KB_TRIM)
	var c := _w(tu, tv)
	var a := KB_A
	var b := Vector2(-KB_A.y, KB_A.x)
	for s: float in [-1.0, 1.0]:
		# the belfry's arch on all four faces
		_arch_panel(c + a * ((hw - 0.15) * s), b, a * s, 0.6, g + 20.6, g + 22.6, CHURCH_DARK, 0.03, M_STONE)
		_arch_panel(c + b * ((hw - 0.15) * s), a, b * s, 0.6, g + 20.6, g + 22.6, CHURCH_DARK, 0.03, M_STONE)
		for t: float in [-1.0, 1.0]:
			_pinnacle(tu + s * 1.35, tv + t * 1.35, 0.32, g + 24.1, 0.9, KB_TRIM)
	# the octagonal lantern, its four arches, the dome and the cross
	_frustum(_kb_oct(c, 1.05), g + 24.1, _kb_oct(c, 1.05), g + 26.9, KB_WALL)
	for s2: float in [-1.0, 1.0]:
		_arch_panel(c + a * (0.97 * s2), b, a * s2, 0.3, g + 24.6, g + 26.0, CHURCH_DARK, 0.04, M_STONE)
		_arch_panel(c + b * (0.97 * s2), a, b * s2, 0.3, g + 24.6, g + 26.0, CHURCH_DARK, 0.04, M_STONE)
	_frustum(_kb_oct(c, 1.2), g + 26.9, _kb_oct(c, 1.1), g + 27.2, KB_TRIM)
	_frustum(_kb_oct(c, 1.1), g + 27.2, _kb_oct(c, 0.7), g + 28.2, KB_TOWER_ROOF)
	_frustum(_kb_oct(c, 0.7), g + 28.2, _kb_oct(c, 0.12), g + 28.9, KB_TOWER_ROOF.lightened(0.06))
	_kap_cross(tu, tv, g + 28.9, 1.4)


func _build_karol(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(KB_O, KB_O + KB_A)
	_g = _ground_under(outline)
	var g := _g
	var c := KB_C
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the masses: nave with its clerestory, aisles, the west block, the transept
	var nave := _lpoly([[-13.3, c - 4.7], [23.6, c - 4.7], [23.6, c + 4.7], [-13.3, c + 4.7]])
	_prism(nave, g - 1.0, g + 15.8, KB_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 15.3, 0.5, KB_TRIM, 0.22)
	_gable(-13.3, 23.6, c, 4.95, g + 15.8, 1.6, KB_TRIM, KB_ROOF, true)
	var rings: Array[PackedVector2Array] = []
	for s: float in [-1.0, 1.0]:
		var aisle := _rect(4.4, c + s * 6.55, 12.7, 1.85)  # u -8.3..17.1, out to v 8.4
		_prism(aisle, g - 1.0, g + 10.3, KB_WALL, KB_ROOF.lightened(0.08), M_STONE, M_STONE)
		rings.append(aisle)
	var west := _rect(-10.8, c, 2.5, 6.5)  # u -13.3..-8.3, v -6.6..6.4
	_prism(west, g - 1.0, g + 10.3, KB_WALL, KB_ROOF.lightened(0.08), M_STONE, M_STONE)
	var tran := _rect(20.4, -0.3, 3.3, 10.7)  # u 17.1..23.7, v -11..10.4
	_prism(tran, g - 1.0, g + 10.8, KB_WALL, none, M_STONE)
	rings.append(west)
	rings.append(tran)
	for i in rings.size():
		kit_ledge_ring(rings[i], g - 1.0, 2.0, KB_BASE, 0.08)
		# the bands stop under the flat tops (10.3), the west block's 5 cm under the aisles'
		kit_ledge_ring(rings[i], g + [9.85, 9.85, 9.8, 10.4][i], 0.4, KB_TRIM, 0.2)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(-11.0, 10.4, 20.4, 3.5, g + 10.8, 1.5, KB_TRIM, KB_ROOF, true)
	_a = ka
	_b = kb
	# --- the apse: a half ring of eight walls, its cornice and the half dome
	var ac := _w(23.7, c)
	var half := PackedVector2Array()
	var half_out := PackedVector2Array()
	for k in 9:
		var ang := -PI * 0.5 + PI * k / 8.0
		var d := KB_A * cos(ang) + Vector2(-KB_A.y, KB_A.x) * sin(ang)
		half.append(ac + d * 4.9)
		half_out.append(ac - KB_A * 0.06 + d * 5.15)  # its hidden back 6 cm off the apse wall's
	_prism(half, g - 1.0, g + 11.4, KB_WALL, none, M_STONE)
	_frustum(half_out, g + 11.4, half_out, g + 11.8, KB_TRIM, none)
	_frustum(half_out, g - 1.0, half_out, g + 0.9, KB_BASE, none)
	var r0 := half
	var y0 := g + 11.8
	for step: Array in [[0.86, 13.1], [0.6, 14.1], [0.15, 14.6]]:
		var r1 := PackedVector2Array()
		for p: Vector2 in half:
			r1.append(ac + (p - ac) * float(step[0]))
		_frustum(r0, y0, r1, g + float(step[1]), KB_DOME, KB_DOME if float(step[0]) < 0.2 else none)
		r0 = r1
		y0 = g + float(step[1])
	var bb := Vector2(-KB_A.y, KB_A.x)
	for k2 in range(1, 8):
		var d2 := (half[k2] - ac).normalized()
		var t2 := Vector2(-d2.y, d2.x)
		_wall(ac + d2 * 5.0 - t2 * 0.3, ac + d2 * 5.0 + t2 * 0.3, g + 0.9, g + 11.4, d2, KB_TRIM)
	for k3 in range(1, 7):
		var am := -PI * 0.5 + PI * (k3 + 0.5) / 8.0
		var dm := KB_A * cos(am) + bb * sin(am)
		_arch_panel(ac + dm * 4.806, Vector2(-dm.y, dm.x), dm, 0.5, g + 3.0, g + 7.4, KB_RELIEF, 0.04, M_STONE)
	# --- the side walls: pilasters, the relief panels between them, clerestory windows
	for side: int in [0, 2]:
		_kb_turn(side)
		var sg := 1.0 if side == 0 else -1.0
		# in the turned frame: u' = sg * u, the face v' = sg * v
		kit_face(sg * (c + sg * 8.4))
		for pu: float in [-8.0, -4.6, -1.2, 2.2, 5.6, 9.0, 12.4, 16.8]:
			_kbox(sg * pu - 0.3, sg * pu + 0.3, _face - 0.04, _face + 0.14, g + 1.0, g + 9.9, KB_TRIM)
		for ru: float in [-6.3, -2.9, 0.5, 3.9, 7.3, 10.7, 14.6]:
			_kbox(sg * ru - 0.45, sg * ru + 0.45, _face - 0.02, _face + 0.06, g + 3.2, g + 7.6, KB_RELIEF)
			_kbox(sg * ru - 0.3, sg * ru + 0.3, _face - 0.02, _face + 0.1, g + 0.0, g + 0.7, PAL_GLASS_DARK)
		kit_face(sg * (c + sg * 4.7))
		for cu: float in [-10.6, -6.3, -2.9, 0.5, 3.9, 7.3, 10.7, 14.6]:
			_arch_panel(_w(sg * cu, _face), _a, _b, 0.65, g + 11.4, g + 13.6, PAL_GLASS_DARK, 0.05, _lit(cu, g + 11.4))
		# the transept's end: pilasters, a pedimented door, a lunette, the pediment's tympanum
		kit_face(sg * (-0.3 + sg * 10.7))
		var tu := sg * 20.4
		for pt: float in [-3.1, -1.5, 1.5, 3.1]:
			_kbox(tu + pt - 0.28, tu + pt + 0.28, _face - 0.04, _face + 0.14, g + 1.0, g + 10.4, KB_TRIM)
		kit_door(tu, g + 0.3, 3.2, 0.8, KB_TRIM, KB_DOOR)
		kit_pediment(tu, 1.35, g + 3.75, 0.8, KB_TRIM, KB_TRIM.darkened(0.08), 0.3)
		_kb_arch_win(tu, g + 6.0, g + 7.4, 0.95)
	# --- the west front: pilasters, the portal, the tall window over it
	_kb_turn(1)
	kit_face(13.3)
	for pv: float in [-4.6, -2.2, 2.0, 4.4]:
		kit_pilaster(pv + c, g + 1.0, g + 9.9, KB_TRIM, 0.7, 0.16)
	kit_door(c, g + 0.3, 4.2, 1.05, KB_TRIM, KB_DOOR, true)
	kit_pediment(c, 1.9, g + 5.2, 1.0, KB_TRIM, KB_TRIM.darkened(0.08), 0.35)
	_kb_arch_win(c, g + 10.6, g + 13.4, 1.2)
	_kbox(c - 4.9, c + 4.9, 13.26, 13.46, g + 15.0, g + 15.7, KB_TRIM)
	# --- the east pediment over the apse and its little bell-cote
	_kb_turn(3)
	kit_face(23.6)
	_kbox(-c - 0.7, -c + 0.7, 22.9, 23.68, g + 17.0, g + 19.0, KB_WALL)
	_arch_panel(_w(-c, 23.68), _a, _b, 0.4, g + 17.5, g + 18.4, CHURCH_DARK, 0.04, M_STONE)
	_kbox(-c - 0.85, -c + 0.85, 22.75, 23.8, g + 19.0, g + 19.3, KB_TRIM)
	kit_front(KB_O, KB_O + KB_A)
	_kap_cross(23.3, c, g + 19.3, 1.3)
	# --- the two west towers on the front's corners
	for tv: float in [c - 4.9, c + 4.9]:
		_kb_tower(-11.75, tv, g)
	_collide(outline)


## The parish church of Our Lady of Jerusalem (Kościół Matki Bożej Jerozolimskiej, ul. Łazienkowska,
## across the street from the Legia stadium), a banded red-and-yellow brick church in a former
## barracks complex. The whole church as a model that replaces the old kit church
## (`church_jerozolimska`, built by `_build_church` until 2026-11-14: a box with a spire, its
## front turned away from the street). From Mapillary photos of 2018-2024 along Łazienkowska
## (refs/jerozolimska, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the
## street block's eaves 15 and its ridge 19 along the street; the nave's eaves 13.6 and ridge 19.6;
## the lower chancel 10.3 and 17; the aisles 5.5 to 7; the north-east block 10; the bell tower
## in the next block west, its base 16.5, its top 22.3 to 23.4). Spec docs/landmarks/specs/jerozolimska.md.
## - the street front: a long brick block under a grey roof along the street, a portico of seven
##   stone columns on two steps before it with a flat brick-topped entablature, a round-headed
##   portal and a row of round-headed windows over the portico;
## - the nave behind it under a steep grey gable, its clerestory windows over the lean-to aisles;
##   the lower chancel and the polygonal north apse; the low blocks round the back yard;
## - the square red-brick bell tower 40 m west on the corner of the next block (in LoD2, cut at
##   12 m under the model's tower): a yellow band, two round-headed openings a side, a corbelled
##   top, a low pyramid roof and a cross.
## Frame: origin at the street front's west corner, u along the street to the east, +v to the
## street (south); the front faces +v.
const JZ_O := Vector2(969.9, 1346.0)
const JZ_A := Vector2(0.9962, 0.0870)
const JZ_C := 12.3                     ## the nave's axis (u): the portal, the ridges, the apse
const JZ_TU := -32.5                   ## the bell tower's centre (u, v)
const JZ_TV := -3.0
const JZ_BRICK := Color("#a9553a")     ## the red brick (photos: warm, a little orange)
const JZ_YELLOW := Color("#c99a5e")    ## the yellow brick bands and corbels
const JZ_STONE := Color("#d8d2c4")     ## the portico's stone columns and steps
const JZ_ROOF := Color("#767a7e")      ## the grey sheet roofs
const JZ_DOOR := Color("#3e302a")      ## the dark doors


## The bell tower's LoD2 cut 12 m over the ground (`lod2_tops`): the next block's LoD2 carries
## the tower; the model's tower stands on the cut.
func _jz_tops() -> void:
	var b := Vector2(-JZ_A.y, JZ_A.x)
	var ring := PackedVector2Array()
	for c: Vector2 in [Vector2(-5.4, -5.4), Vector2(5.4, -5.4), Vector2(5.4, 5.4), Vector2(-5.4, 5.4)]:
		ring.append(JZ_O + JZ_A * (JZ_TU + c.x) + b * (JZ_TV + c.y))
	lod2_tops.append([ring, 12.0, JZ_O + JZ_A * JZ_TU + b * JZ_TV])


## A round-headed window on the current front at u: a yellow brick surround and the pane.
func _jz_arch(u: float, y0: float, spring: float, hw: float) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.2, y0 - 0.15, spring, JZ_YELLOW, 0.03, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, spring, PAL_GLASS_DARK, 0.07, _lit(u + _face, y0))


## Turns the frame so +v points out of a side (0 street/south, 1 west, 2 north, 3 east):
## a point (u, v) is then (u, v), (v, -u), (-u, -v) or (-v, u).
func _jz_turn(side: int) -> void:
	var b := Vector2(-JZ_A.y, JZ_A.x)
	_a = [JZ_A, b, -JZ_A, -b][side]
	_b = Vector2(-_a.y, _a.x)


func _build_jerozolimska(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(JZ_O, JZ_O + JZ_A)
	_g = _ground_under(outline)
	var g := _g
	var c := JZ_C
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the street block: walls to 15, a gable roof along the street to 19
	var front := _rect(12.65, -3.75, 12.65, 3.75)  # u 0..25.3, v -7.5..0
	_prism(front, g - 1.0, g + 15.0, JZ_BRICK, none, M_STONE)
	kit_ledge_ring(front, g + 14.4, 0.5, JZ_YELLOW, 0.15)
	_gable(0.0, 25.3, -3.75, 3.9, g + 15.0, 4.0, JZ_BRICK, JZ_ROOF, true)
	# --- the nave (u 6.1..18.5) to the chancel, and the chancel to the apse
	var ka := _a
	var kb := _b
	_prism(_lpoly([[6.1, -22.5], [18.5, -22.5], [18.5, -7.5], [6.1, -7.5]]), g + 5.0, g + 13.6, JZ_BRICK, none, M_STONE)
	_prism(_lpoly([[6.3, -34.6], [18.3, -34.6], [18.3, -22.5], [6.3, -22.5]]), g - 1.0, g + 10.3, JZ_BRICK, none, M_STONE)
	_a = kb
	_b = ka
	_gable(-22.5, -7.5, c, 6.35, g + 13.6, 6.0, JZ_BRICK, JZ_ROOF, false)
	_gable(-34.6, -22.5, c, 6.15, g + 10.3, 6.7, JZ_BRICK, JZ_ROOF, false)
	_a = ka
	_b = kb
	# the apse: half an octagon round (c, -34.6), walls to 9.5, a roof to a point at 13.2
	var ac := _w(c - 0.9, -34.6)
	var bb := Vector2(-JZ_A.y, JZ_A.x)
	var half := PackedVector2Array()
	for k in 5:
		var ang := PI * k / 4.0
		half.append(ac + (JZ_A * cos(ang) - bb * sin(ang)) * 4.1)
	_prism(half, g - 1.0, g + 9.5, JZ_BRICK, none, M_STONE)
	var tip := PackedVector2Array()
	for p: Vector2 in half:
		tip.append(ac + (p - ac) * 0.12)
	_frustum(half, g + 9.5, tip, g + 13.2, JZ_ROOF, JZ_ROOF)
	# --- the low blocks: the aisles, the west block, the north-east block (flat, grey tops)
	for blk: Array in [[0.0, 6.1, -30.0, -7.5, 6.5], [18.5, 25.2, -30.0, -7.5, 6.5],
			[-0.5, 6.3, -38.2, -30.0, 7.5], [17.1, 25.3, -46.4, -30.0, 10.0]]:
		var r := _lpoly([[blk[0], blk[2]], [blk[1], blk[2]], [blk[1], blk[3]], [blk[0], blk[3]]])
		_prism(r, g - 1.0, g + float(blk[4]), JZ_BRICK, JZ_ROOF.lightened(0.08), M_STONE, M_STONE)
		kit_ledge_ring(r, g + float(blk[4]) - 0.45, 0.4, JZ_YELLOW, 0.12)
	# --- the street front: bands, the portal and the windows over the portico
	kit_face(0.0)
	_kbox(0.0, 25.3, -0.02, 0.1, g + 6.6, g + 7.0, JZ_YELLOW)
	_kbox(0.0, 25.3, -0.02, 0.1, g + 11.8, g + 12.1, JZ_YELLOW)
	for wu: float in [3.2, 7.4, 12.3, 17.2, 21.4]:
		_jz_arch(wu, g + 8.0, g + 10.4, 0.7)
	kit_door(c, g + 0.6, 3.8, 1.1, JZ_YELLOW, JZ_DOOR, true)
	for du: float in [5.0, 19.6]:
		kit_door(du, g + 0.6, 2.8, 0.7, JZ_YELLOW, JZ_DOOR, true)
	# the portico: two steps, seven stone columns, the entablature and its brick top
	_kbox(2.6, 22.0, -0.04, 2.9, g - 1.0, g + 0.3, JZ_STONE.darkened(0.06))
	_kbox(3.0, 21.6, -0.04, 2.5, g + 0.3, g + 0.6, JZ_STONE)
	kit_colonnade(3.6, 21.0, 7, 2.0, g + 0.6, g + 5.3, JZ_STONE, 0.3)
	_kbox(3.0, 21.6, -0.04, 2.5, g + 5.3, g + 5.9, JZ_STONE)
	_kbox(2.9, 21.7, -0.04, 2.6, g + 5.9, g + 6.5, JZ_BRICK, M_STONE)
	# --- the nave's and the chancel's sides: clerestory and side windows
	for side: int in [1, 3]:
		_jz_turn(side)
		var s := -1.0 if side == 1 else 1.0
		# turned: west (1) u' = v, face v' = -u; east (3) u' = -v, face v' = u
		kit_face(-6.1 if side == 1 else 18.5)
		for nv: float in [-10.0, -13.7, -17.4, -21.0]:
			_jz_arch(-s * nv, g + 8.6, g + 11.6, 0.6)
		kit_face(-0.0 if side == 1 else 25.2)
		for av: float in [-11.0, -16.0, -21.0, -26.0]:
			_jz_arch(-s * av, g + 1.6, g + 4.0, 0.55)
	_jz_turn(2)
	kit_face(34.6)
	_jz_arch(-c, g + 11.0, g + 13.6, 0.9)  # the chancel's north gable over the apse
	kit_front(JZ_O, JZ_O + JZ_A)
	_collide(outline)
	# --- the bell tower in the next block west: its base, the shaft, the belfry, roof and cross
	var tc := _w(JZ_TU, JZ_TV)
	_g = map.terrain_height(tc.x, tc.y)
	var gt := _g
	# the base from the ground (inside the next block below its 12 m cut, so it stands on something)
	_lbox(JZ_TU, JZ_TV, 5.0, 5.0, gt - 1.0, gt + 16.5, JZ_BRICK, M_STONE, JZ_ROOF.lightened(0.08))
	_lbox(JZ_TU, JZ_TV, 5.12, 5.12, gt + 16.0, gt + 16.45, JZ_YELLOW, M_STONE, none)
	_lbox(JZ_TU, JZ_TV, 4.0, 4.0, gt + 16.5, gt + 22.0, JZ_BRICK, M_STONE, none)
	_lbox(JZ_TU, JZ_TV, 4.15, 4.15, gt + 21.6, gt + 22.3, JZ_YELLOW, M_STONE, JZ_YELLOW)
	for side2: int in 4:
		_jz_turn(side2)
		var p := Vector2(JZ_TU, JZ_TV)
		var lu: float = [p.x, p.y, -p.x, -p.y][side2]
		var lv: float = [p.y, -p.x, -p.y, p.x][side2]
		kit_face(lv + 4.0)
		for d: float in [-1.3, 1.3]:
			_arch_panel(_w(lu + d, _face), _a, _b, 0.55, gt + 18.2, gt + 20.4, CHURCH_DARK, 0.04, M_STONE)
	kit_front(JZ_O, JZ_O + JZ_A)
	_hip(JZ_TU, JZ_TV, 4.15, 4.15, gt + 22.3, 1.1, JZ_ROOF)
	_kap_cross(JZ_TU, JZ_TV, gt + 23.3, 2.2)
	_g = g


## The church of St Brother Albert and St Andrew (Kościół św. Brata Alberta i św. Andrzeja
## Apostoła, the artists' church on Plac Teatralny, Senatorska 29), a classicist front on the
## square: a giant portico of four white columns and a pediment over the yellow church front,
## between two white three-storey wings under red mansard roofs with dormers. The whole frontage
## as a model that replaces the old kit church (`church_alberta`, built by `_build_church` until
## 2026-11-14: a "modern" box with a pyramid, its front at the block's end). From Mapillary
## photos of 2014-2022 across Plac Teatralny and Senatorska (refs/alberta, never shipped), the
## OSM outline and GUGiK's LoD2 (over the ground: the wings' eaves 10 and their flat tops 16.4;
## the middle block's pediment ridge 15.5, running back over the church). Spec
## docs/landmarks/specs/alberta.md.
## Frame: origin at the front's north-west corner, u along the front to the south-east, +v out
## of the front to the square; the block runs back to v -17.5.
const BA_O := Vector2(-1087.3, -1107.4)
const BA_A := Vector2(0.808, -0.589)
const BA_C := 20.75                    ## the portico's axis (u)
const BA_WHITE := Color("#eeebe3")     ## the wings' white plaster
const BA_YELLOW := Color("#d8c07a")    ## the church front behind the columns
const BA_COLUMN := Color("#f5f3ee")    ## the columns, the entablature and the pediment
const BA_TILE := Color("#9c4a36")      ## the red mansard tiles
const BA_ROOF := Color("#6f7276")      ## the middle block's grey sheet roof
const BA_BASE := Color("#b9b4a8")      ## the plinth and steps


## One wing (u0..u1): walls to 10, a mansard to a flat top at 16.4, dormers on the front
## slope, the arcade of the ground floor and two rows of windows on the front and the back.
func _ba_wing(u0: float, u1: float, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var r := _lpoly([[u0, -17.4], [u1, -17.4], [u1, 0.0], [u0, 0.0]])
	_prism(r, g - 1.0, g + 10.0, BA_WHITE, none, M_STONE)
	kit_ledge_ring(r, g - 1.0, 1.4, BA_BASE, 0.06)
	kit_ledge_ring(r, g + 9.6, 0.4, BA_COLUMN, 0.25)
	var top := _lpoly([[u0 + 1.2, -13.6], [u1 - 1.2, -13.6], [u1 - 1.2, -3.8], [u0 + 1.2, -3.8]])
	_frustum(r, g + 10.0, top, g + 16.4, BA_TILE, BA_TILE.darkened(0.08))
	var cols: Array = []
	var u := u0 + 1.6
	while u < u1 - 1.0:
		cols.append(u)
		u += 2.7
	for s: float in [1.0, -1.0]:
		var vf := 0.0 if s > 0.0 else -17.4
		for cu: float in cols:
			# the ground floor's arches, two rows of windows over them
			_arch_panel(_w(cu, vf), _a * s, _b * s, 0.75, g + 0.4, g + 2.6, CHURCH_DARK, 0.04, M_STONE)
			for wy: float in [4.0, 7.0]:
				_mode = _lit(cu * s, g + wy)
				_wall(_w(cu - 0.55 * s, vf + 0.05 * s), _w(cu + 0.55 * s, vf + 0.05 * s), g + wy, g + wy + 1.7, _b * s, PAL_GLASS_DARK)
			_mode = M_STONE
			# a dormer on the slope: a small box and its little gable
			var dv := -1.0 if s > 0.0 else -16.4
			_kbox(cu - 0.5, cu + 0.5, minf(dv, dv - 1.6 * s), maxf(dv, dv - 1.6 * s), g + 11.0, g + 12.9, BA_WHITE)
			_mode = _lit(cu + vf, g + 11.8)
			_wall(_w(cu - 0.32 * s, dv + 0.02 * s), _w(cu + 0.32 * s, dv + 0.02 * s), g + 11.9, g + 12.6, _b * s, PAL_GLASS_DARK)
			_mode = M_STONE
	# the end walls: two windows a storey
	for e: float in [u0, u1]:
		var out := -_a if e == u0 else _a
		for ev: float in [-12.0, -5.4]:
			for ey: float in [4.0, 7.0]:
				_mode = _lit(ev + e, g + ey)
				_wall(_w(e, ev - 0.55) + out * 0.05, _w(e, ev + 0.55) + out * 0.05, g + ey, g + ey + 1.7, out, PAL_GLASS_DARK)
	_mode = M_STONE


func _build_alberta(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(BA_O, BA_O + BA_A)
	_g = _ground_under(outline)
	var g := _g
	var c := BA_C
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_ba_wing(0.0, 14.0, g)
	_ba_wing(27.5, 41.7, g)
	# --- the middle block: the yellow church front, the grey gable running back from the pediment
	var mid := _lpoly([[14.0, -18.2], [27.5, -18.2], [27.5, 0.0], [14.0, 0.0]])
	_prism(mid, g - 1.0, g + 11.2, BA_YELLOW, none, M_STONE)
	kit_ledge_ring(mid, g - 1.0, 1.4, BA_BASE, 0.06)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(2.4, -18.2, c, 6.9, g + 11.2, 4.4, BA_COLUMN, BA_ROOF, true)
	_a = ka
	_b = kb
	# the portico: three steps, four columns, the entablature over them back to the wall
	_kbox(14.4, 27.1, -0.04, 3.4, g - 1.0, g + 0.2, BA_BASE)
	_kbox(14.8, 26.7, -0.04, 3.0, g + 0.2, g + 0.45, BA_BASE.lightened(0.05))
	kit_colonnade(16.2, 25.3, 4, 1.9, g + 0.45, g + 10.3, BA_COLUMN, 0.5, Order.CORINTHIAN)
	_kbox(14.3, 27.2, -0.04, 2.4, g + 10.3, g + 11.2, BA_COLUMN)
	_kbox(c - 3.5, c + 3.5, 2.38, 2.44, g + 12.0, g + 12.6, BA_YELLOW.darkened(0.1))  # the tympanum's inscription band
	# the church front behind the columns: the portal, a window over it, two niches
	kit_face(0.0)
	kit_door(c, g + 0.45, 4.6, 1.3, BA_COLUMN, PAL_DARK_DOOR, true)
	_arch_panel(_w(c, 0.0), _a, _b, 0.9, g + 6.0, g + 8.2, PAL_GLASS_DARK, 0.05, _lit(c, g + 6.0))
	for nu: float in [c - 3.1, c + 3.1]:
		_arch_panel(_w(nu, 0.0), _a, _b, 0.55, g + 1.2, g + 4.0, BA_YELLOW.darkened(0.12), 0.04, M_STONE)
	_collide(outline)


## The Evangelical Reformed church (Kościół Ewangelicko-Reformowany, al. Solidarności 74; Adolf
## Loewe, 1866-80), a cream neo-Gothic hall church with one tall tower over its front and the
## openwork grey spire Warsaw knows it by. The whole church as a model that replaces the old kit
## church (`church_reformowany`, built by `_build_church` until 2026-11-14: a brick box with a
## pyramid, its front at the far end). From Mapillary photos of 2022-2025 along al. Solidarności
## (refs/reformowany, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the
## nave's eaves 13 and its ridge 20.3; the tower's top 31 and the spire's tip 52; the chancel
## 16; the low vestry 4.5). Spec docs/landmarks/specs/reformowany.md.
## - the front to the avenue: a pointed portal, a rose window, the gable with its pinnacles,
##   two slim corner turrets, the tower rising from behind the gable with tall belfry lancets,
##   four corner pinnacles and the octagonal grey spire with dark openwork slits and a cross;
## - the nave under one grey roof, buttresses and tall lancets along both sides; the three-sided
##   chancel at the north end and the low vestry behind it.
## Frame: origin at the front's east corner, u along the church to the north-west, +v across it;
## the front faces -u (to the avenue).
const RF_O := Vector2(-1749.5, -1082.9)
const RF_A := Vector2(-0.448, -0.894)
const RF_C := 9.9                      ## the church's axis (v): the tower, the portal, the ridge
const RF_WALL := Color("#ddcb98")      ## the cream-yellow brick and render (photos)
const RF_TRIM := Color("#ece2c4")      ## pinnacles, frames, the rose window's ring
const RF_ROOF := Color("#686d72")      ## the grey roof
const RF_SPIRE := Color("#8d969c")     ## the spire's grey metal
const RF_BASE := Color("#9b958a")      ## the plinth


## A pointed window on the wall at (u, v) looking `out`, along `along`: a trim field and the pane.
func _rf_lancet(u: float, v: float, along: Vector2, out: Vector2, hw: float, y0: float, spring: float) -> void:
	var at := _w(u, v)
	_lancet_panel(at, along, out, hw + 0.2, y0 - 0.15, spring, RF_TRIM, 0.03, M_STONE)
	_lancet_panel(at, along, out, hw, y0, spring, PAL_GLASS_DARK, 0.07, _lit(u + v, y0))


func _build_reformowany(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(RF_O, RF_O + RF_A)
	_g = _ground_under(outline)
	var g := _g
	var c := RF_C
	var none := Color(0, 0, 0, 0)
	var b := Vector2(-RF_A.y, RF_A.x)
	_mode = M_STONE
	# --- the nave: one box, a plinth, a band under the eaves, one gable roof along u
	var nave := _rect(21.5, c, 20.0, 9.6)  # u 1.5..41.5, v 0.3..19.5
	_prism(nave, g - 1.0, g + 13.0, RF_WALL, none, M_STONE)
	kit_ledge_ring(nave, g - 1.0, 1.6, RF_BASE, 0.08)
	kit_ledge_ring(nave, g + 12.5, 0.5, RF_TRIM, 0.18)
	_gable(1.5, 41.5, c, 9.85, g + 13.0, 7.3, RF_WALL, RF_ROOF, true)
	# buttresses and lancets on both long sides
	for s: float in [-1.0, 1.0]:
		var vf := c + s * 9.6
		for bu: float in [1.9, 6.6, 11.3, 16.0, 20.7, 25.4, 30.1, 34.8, 39.5]:
			_kbox(bu - 0.4, bu + 0.4, minf(vf, vf + s * 0.9), maxf(vf, vf + s * 0.9), g - 1.0, g + 11.0, RF_WALL)
			_kbox(bu - 0.3, bu + 0.3, minf(vf, vf + s * 0.5), maxf(vf, vf + s * 0.5), g + 11.0, g + 13.6, RF_TRIM)
		for wu: float in [9.0, 13.6, 18.3, 23.0, 27.7, 32.4, 37.1]:
			_rf_lancet(wu, vf, RF_A, b * s, 0.8, g + 3.5, g + 9.5)
	# --- the chancel: three sides past the nave's end, walls to 12, a low roof to 16
	var ac := _w(41.5, c)
	var ring := PackedVector2Array()
	for k in 4:
		var ang := -PI * 0.5 + PI * k / 3.0
		ring.append(ac + (RF_A * cos(ang) + b * sin(ang)) * 6.0)
	_prism(ring, g - 1.0, g + 12.0, RF_WALL, none, M_STONE)
	var tip := PackedVector2Array()
	for p: Vector2 in ring:
		tip.append(ac + (p - ac) * 0.15)
	_frustum(ring, g + 12.0, tip, g + 16.0, RF_ROOF, RF_ROOF)
	for k2 in range(3):
		var am := -PI * 0.5 + PI * (k2 + 0.5) / 3.0
		var dm := RF_A * cos(am) + b * sin(am)
		var pm := ac + dm * 6.0 * cos(PI / 6.0)
		_lancet_panel(pm, Vector2(-dm.y, dm.x), dm, 0.7, g + 3.5, g + 8.5, PAL_GLASS_DARK, 0.06, _lit(float(k2), g + 3.5))
	# the low vestry behind the chancel
	_prism(_lpoly([[44.0, 1.5], [48.5, 1.5], [48.5, 18.0], [44.0, 18.0]]), g - 1.0, g + 4.5, RF_WALL, RF_ROOF.lightened(0.08), M_STONE, M_STONE)
	# --- the front: the portal, the rose window, a lancet pair, the gable's pinnacles, two turrets
	var fo := -RF_A
	_lancet_panel(_w(1.5, c), b, fo, 1.75, g + 0.65, g + 4.2, RF_TRIM, 0.03, M_STONE)
	_lancet_panel(_w(1.5, c), b, fo, 1.25, g + 0.0, g + 3.6, PAL_DARK_DOOR, 0.12, M_STONE)
	_disc(Vector3(_w(1.4, c).x, g + 9.0, _w(1.4, c).y), Vector3(fo.x, 0.0, fo.y), 2.0, 12, RF_TRIM)
	_disc(Vector3(_w(1.36, c).x, g + 9.0, _w(1.36, c).y), Vector3(fo.x, 0.0, fo.y), 1.6, 12, PAL_GLASS_DARK)
	for lv: float in [c - 5.0, c + 5.0]:
		_rf_lancet(1.5, lv, b, fo, 0.7, g + 3.5, g + 8.8)
	_pinnacle(1.2, c, 0.6, g + 20.0, 2.4, RF_TRIM)
	for tv: float in [0.3, 19.5]:
		_lbox(1.5, tv, 0.9, 0.9, g - 1.0, g + 15.5, RF_WALL, M_STONE, none)
		_pinnacle(1.5, tv, 1.6, g + 15.5, 4.0, RF_TRIM)
	# --- the tower over the front: the shaft from the roof, belfry lancets, corner pinnacles
	var tu := 6.75
	_lbox(tu, c, 2.4, 2.4, g + 13.0, g + 30.0, RF_WALL, M_STONE, none)
	kit_ledge_ring(_rect(tu, c, 2.4, 2.4), g + 29.4, 0.6, RF_TRIM, 0.15)
	for s2: float in [-1.0, 1.0]:
		_rf_lancet(tu, c + s2 * 2.4, RF_A, b * s2, 0.55, g + 23.0, g + 27.0)
		_rf_lancet(tu + s2 * 2.4, c, b, RF_A * s2, 0.55, g + 23.0, g + 27.0)
		for t: float in [-1.0, 1.0]:
			_pinnacle(tu + s2 * 2.15, c + t * 2.15, 0.6, g + 30.0, 4.2, RF_TRIM)
	# the octagonal openwork spire: three rings, dark slits on its lower faces, a cross
	var tc := _w(tu, c)
	var oct := func(r: float) -> PackedVector2Array:
		var o := PackedVector2Array()
		for k3 in 8:
			var an := PI * (k3 + 0.5) / 4.0
			o.append(tc + (RF_A * cos(an) + b * sin(an)) * r)
		return o
	_frustum(oct.call(2.2), g + 30.0, oct.call(1.5), g + 38.0, RF_SPIRE)
	_frustum(oct.call(1.5), g + 38.0, oct.call(0.12), g + 51.0, RF_SPIRE.lightened(0.05), RF_SPIRE)
	for k4 in 4:
		var an2 := PI * k4 / 2.0
		var dn := RF_A * cos(an2) + b * sin(an2)
		var sl := tc + dn * 1.9
		_wall(sl - Vector2(-dn.y, dn.x) * 0.2, sl + Vector2(-dn.y, dn.x) * 0.2, g + 31.0, g + 36.0, dn, CHURCH_DARK)
	_kap_cross(tu, c, g + 51.0, 1.8)
	_collide(outline)


## The church of the Nativity of the Virgin Mary on Leszno (Kościół Narodzenia NMP, al.
## Solidarności 80), a salmon-pink Baroque church with white pilasters, its three-storey front to
## the avenue and a small copper clock turret over the pediment. The whole church as a model that
## replaces the old kit church (`church_narodzenia`, built by `_build_church` until 2026-11-14: a
## beige box with a helm tower, its front on the north end). From Mapillary photos of 2020 and
## 2022 along al. Solidarności (one straight onto the front, refs/narodzenia, never shipped), the
## OSM outline and GUGiK's LoD2 (over the ground: the nave's eaves 16.5 and ridge 22; the front's
## pediment 23; the turret's top 30; the aisles 8; the lower chancel 15 and 19; the back wings 8).
## Spec docs/landmarks/specs/narodzenia.md.
## - the front: a full-width ground storey with paired pilasters and a pedimented door, a
##   nave-wide storey with the tall round-headed window, an attic with three arched windows
##   between scrolls, the pediment, and behind it the turret: a balustrade with urns, a
##   green clock stage with a clock a side, a little dome and a spire with the cross;
## - the nave under a red tile roof, pilasters and round-headed windows over the lean-to aisles;
## - the lower chancel with its own gable, the low wings either side of it.
## Frame: origin at the front's south-west corner, u from the front (south-south-east, to the
## avenue) back to the chancel, v across; the front faces -u.
const NR_O := Vector2(-1971.4, -955.6)
const NR_A := Vector2(-0.4656, -0.8850)
const NR_C := 12.0                     ## the church's axis (v): the door, the turret, the ridges
const NR_WALL := Color("#d49885")      ## the salmon-pink plaster (photos)
const NR_TRIM := Color("#efe7da")      ## the white pilasters, cornices, frames
const NR_ROOF := Color("#a3553f")      ## the red tile roofs
const NR_COPPER := Color("#5f8a78")    ## the turret's green copper
const NR_BASE := Color("#a39a8e")      ## the grey plinth
const NR_DOOR := Color("#4a3a30")      ## the dark wooden door


## Turns the kit frame so that +v points out of one side of the church (0 the v = 24 side,
## 1 the front, 2 the v = 0 side, 3 the back), as `_kb_turn` does for St Charles: a point (u, v)
## of the church's frame is then (u, v), (v, -u), (-u, -v) or (-v, u) in the turned one.
func _nr_turn(side: int) -> void:
	var b := Vector2(-NR_A.y, NR_A.x)
	match side:
		0:
			_a = NR_A
		1:
			_a = b
		2:
			_a = -NR_A
		_:
			_a = -b
	_b = Vector2(-_a.y, _a.x)


## A round-headed window on the turned frame's face: a white frame and the pane over it.
func _nr_win(u: float, y0: float, spring: float, hw: float) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.2, y0 - 0.2, spring, NR_TRIM, 0.03, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, spring, PAL_GLASS_DARK, 0.07, _lit(u + _face, y0))


## An octagon of radius r round c with faces along the church's axes.
func _nr_oct(c: Vector2, r: float) -> PackedVector2Array:
	var b := Vector2(-NR_A.y, NR_A.x)
	var ring := PackedVector2Array()
	for k in 8:
		var ang := PI * (k + 0.5) / 4.0
		ring.append(c + (NR_A * cos(ang) + b * sin(ang)) * r)
	return ring


## A pilaster on the turned frame's face: one white box (the kit's three-box one costs too much
## at this count).
func _nr_pil(u: float, y0: float, y1: float, w: float, proud: float) -> void:
	_kbox(u - w * 0.5, u + w * 0.5, _face - 0.04, _face + proud, y0, y1, NR_TRIM)


func _build_narodzenia(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(NR_O, NR_O + NR_A)
	_g = _ground_under(outline)
	var g := _g
	var c := NR_C
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the masses: nave, aisles with the front's wide ground storey, chancel, back wings
	var nave := _lpoly([[0.0, 4.0], [23.0, 4.0], [23.0, 20.0], [0.0, 20.0]])
	_prism(nave, g - 1.0, g + 16.5, NR_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 15.95, 0.5, NR_TRIM, 0.2)
	_gable(0.6, 23.0, c, 8.2, g + 16.5, 5.5, NR_WALL, NR_ROOF, true)
	var rings: Array[PackedVector2Array] = [nave]
	for av: Array in [[0.0, 4.0], [20.0, 24.0]]:
		var aisle := _lpoly([[1.4, av[0]], [23.0, av[0]], [23.0, av[1]], [1.4, av[1]]])
		_prism(aisle, g - 1.0, g + 8.3, NR_WALL, NR_ROOF.lightened(0.06), M_STONE, M_STONE)
		kit_ledge_ring(aisle, g + 7.75, 0.4, NR_TRIM, 0.15)
		rings.append(aisle)
		var fr := _lpoly([[0.0, av[0]], [1.4, av[0]], [1.4, av[1]], [0.0, av[1]]])
		_prism(fr, g - 1.0, g + 10.5, NR_WALL, NR_ROOF.lightened(0.06), M_STONE, M_STONE)
	var chancel := _lpoly([[23.0, 6.5], [32.9, 6.5], [32.9, 17.5], [23.0, 17.5]])
	_prism(chancel, g - 1.0, g + 15.0, NR_WALL, none, M_STONE)
	kit_ledge_ring(chancel, g + 14.5, 0.45, NR_TRIM, 0.18)
	_gable(32.9, 23.0, c, 5.7, g + 15.0, 4.0, NR_WALL, NR_ROOF, false)
	rings.append(chancel)
	for wv: Array in [[0.0, 6.5], [17.5, 25.6]]:
		var wing := _lpoly([[23.05, wv[0]], [32.9, wv[0]], [32.9, wv[1]], [23.05, wv[1]]])
		_prism(wing, g - 1.0, g + 8.0, NR_WALL.lightened(0.04), NR_ROOF.lightened(0.1), M_STONE, M_STONE)
		rings.append(wing)
	for i in rings.size():
		# the plinths' tops 4 cm apart where the blocks meet
		kit_ledge_ring(rings[i], g - 1.0, 1.7 - 0.04 * i, NR_BASE, 0.06)
	# --- the front (turned: u' = v, the face at u = 0)
	_nr_turn(1)
	kit_face(0.0)
	# the ground storey across the whole front, its cornice at 10.5
	_kbox(-0.15, 24.15, -0.05, 0.25, g + 10.2, g + 10.75, NR_TRIM)
	for pv: float in [0.45, 3.55, 4.75, 7.6, 16.4, 19.25, 20.45, 23.55]:
		_nr_pil(pv, g + 0.7, g + 10.2, 0.7, 0.14)
	kit_door(c, g + 0.0, 4.0, 1.1, NR_TRIM, NR_DOOR)
	kit_pediment(c, 1.7, g + 4.25, 0.9, NR_TRIM, NR_TRIM.darkened(0.08), 0.3)
	for wv2: float in [2.0, 22.0]:
		_nr_win(wv2, g + 3.0, g + 6.2, 0.75)
	for wv3: float in [6.2, 17.8]:
		_nr_win(wv3, g + 3.0, g + 6.8, 0.7)
	# the nave-wide middle storey, its cornice at 16.5, the tall window
	_kbox(3.85, 20.15, -0.05, 0.25, g + 16.1, g + 16.6, NR_TRIM)
	for pv2: float in [4.5, 7.4, 16.6, 19.5]:
		_nr_pil(pv2, g + 10.75, g + 16.1, 0.65, 0.12)
	_nr_win(c, g + 11.4, g + 14.4, 1.3)
	# the attic over the nave's eaves: three arched windows, two scrolls, the pediment
	_kbox(6.5, 17.5, -1.0, 0.0, g + 16.0, g + 20.0, NR_WALL)
	for pv3: float in [6.9, 17.1]:
		_nr_pil(pv3, g + 16.6, g + 20.0, 0.6, 0.12)
	_nr_win(c, g + 17.0, g + 18.7, 0.85)
	for wv4: float in [9.2, 14.8]:
		_nr_win(wv4, g + 17.4, g + 18.6, 0.4)
	for s: float in [-1.0, 1.0]:
		var sv := c + s * 6.3
		_kbox(minf(sv, sv + s * 1.7), maxf(sv, sv + s * 1.7), -0.8, 0.1, g + 16.6, g + 17.3, NR_TRIM)
		_kbox(minf(sv, sv + s * 0.8), maxf(sv, sv + s * 0.8), -0.8, 0.1, g + 17.3, g + 18.3, NR_TRIM)
		var dc := _w(sv + s * 1.3, 0.16)
		_disc(Vector3(dc.x, g + 17.75, dc.y), Vector3(_b.x, 0.0, _b.y), 0.45, 8, NR_TRIM.darkened(0.06))
	kit_pediment(c, 5.8, g + 20.0, 3.0, NR_TRIM, NR_ROOF, 0.35)
	# --- the sides: pilasters and round-headed windows on the aisles and the nave over them
	for side: int in [0, 2]:
		_nr_turn(side)
		var sg := 1.0 if side == 0 else -1.0
		kit_face(sg * (12.0 + sg * 12.0))
		for pu: float in [2.6, 8.0, 13.4, 18.8]:
			_nr_pil(sg * pu, g + 0.7, g + 7.75, 0.6, 0.12)
		for wu: float in [5.3, 10.7, 16.1, 21.0]:
			_nr_win(sg * wu, g + 2.4, g + 5.4, 0.75)
		kit_face(sg * (12.0 + sg * 8.0))
		for pu2: float in [1.0, 6.0, 11.0, 16.0, 21.4]:
			_nr_pil(sg * pu2, g + 8.3, g + 15.95, 0.6, 0.12)
		for wu2: float in [3.5, 8.5, 13.5, 18.7]:
			_nr_win(sg * wu2, g + 10.2, g + 13.6, 0.95)
		kit_face(sg * (12.0 + sg * 5.5))
		for wu3: float in [26.0, 30.0]:
			_nr_win(sg * wu3, g + 4.0, g + 9.0, 0.8)
	# --- the back: the chancel's gable end, an oculus, the wings' windows
	_nr_turn(3)
	kit_face(32.9)
	_nr_win(-c, g + 4.0, g + 9.5, 1.0)
	var oc := _w(-c, 32.97)
	_disc(Vector3(oc.x, g + 16.4, oc.y), Vector3(_b.x, 0.0, _b.y), 0.9, 10, NR_TRIM)
	for wv5: float in [3.2, 21.5]:
		_kbox(-wv5 - 0.6, -wv5 + 0.6, 32.88, 32.96, g + 2.5, g + 4.8, PAL_GLASS_DARK, _lit(wv5, g + 2.5))
		_kbox(-wv5 - 0.6, -wv5 + 0.6, 32.88, 32.96, g + 5.4, g + 7.2, PAL_GLASS_DARK, _lit(wv5 + 1.0, g + 5.4))
	kit_front(NR_O, NR_O + NR_A)
	# --- the clock turret behind the pediment: base, balustrade and urns, clock stage, dome, spire
	var tu := 2.6
	_lbox(tu, c, 1.9, 1.9, g + 19.0, g + 22.3, NR_WALL, M_STONE, none)
	_lbox(tu, c, 2.05, 2.05, g + 22.3, g + 22.95, NR_TRIM, M_STONE, NR_TRIM.darkened(0.05))
	for s2: float in [-1.0, 1.0]:
		for t: float in [-1.0, 1.0]:
			_pinnacle(tu + s2 * 1.8, c + t * 1.8, 0.35, g + 22.95, 0.9, NR_TRIM)
	var tc := _w(tu, c)
	var bb := Vector2(-NR_A.y, NR_A.x)
	_frustum(_nr_oct(tc, 1.45), g + 22.95, _nr_oct(tc, 1.45), g + 26.5, NR_COPPER.darkened(0.15))
	for s3: float in [-1.0, 1.0]:
		for dd: Vector2 in [NR_A * s3, bb * s3]:
			var fp := tc + dd * 1.36
			_arch_panel(fp, Vector2(-dd.y, dd.x), dd, 0.35, g + 23.3, g + 24.4, CHURCH_DARK, 0.03, M_STONE)
			var cp := tc + dd * 1.4
			_disc(Vector3(cp.x, g + 25.6, cp.y), Vector3(dd.x, 0.0, dd.y), 0.45, 10, NR_TRIM)
	_frustum(_nr_oct(tc, 1.6), g + 26.5, _nr_oct(tc, 1.6), g + 26.8, NR_TRIM)
	_frustum(_nr_oct(tc, 1.5), g + 26.8, _nr_oct(tc, 1.0), g + 27.7, NR_COPPER)
	_frustum(_nr_oct(tc, 1.0), g + 27.7, _nr_oct(tc, 0.3), g + 28.3, NR_COPPER.lightened(0.05))
	_frustum(_nr_oct(tc, 0.3), g + 28.3, _nr_oct(tc, 0.05), g + 30.3, NR_COPPER, NR_COPPER)
	_kap_cross(tu, c, g + 30.3, 1.1)
	_collide(outline)


## The Basilians' Greek Catholic church of the Dormition (Cerkiew Zaśnięcia Matki Bożej, Miodowa
## 16), the classicist church hall behind the Basilian monastery's street wing; its front shows on
## Miodowa as the wing's middle under a pediment with a cross (part of the monastery's building,
## not of this model). The hall as a model that replaces the old kit church (`church_cerkiew`,
## built by `_build_church` until 2026-11-14 with an onion dome the church never had). From the
## Mapillary 360s of 2026 along Miodowa (refs/cerkiew, never shipped: they show the street
## front; the hall stands in the courtyards and is unphotographed), the OSM outline and GUGiK's
## LoD2 (over the ground: the eaves 21, the ridge 26.4, the polygonal east end 20 to 23.5).
## Spec docs/landmarks/specs/cerkiew.md.
## - a plain white hall under a grey gable roof, pilasters and tall round-headed windows a side;
## - its west gable over the street wing's roof with an oculus and a cross;
## - the polygonal east end under a low roof.
## Frame: origin at the hall's west corner by the street wing, u along the hall away from Miodowa,
## v across.
const BZ_O := Vector2(-1034.4, -1518.1)
const BZ_A := Vector2(0.569, -0.822)
const BZ_C := 7.9                      ## the hall's axis (v)
const BZ_WALL := Color("#ebe5d7")      ## the white-cream plaster (the street front's)
const BZ_TRIM := Color("#f5f1e8")      ## pilasters, frames
const BZ_ROOF := Color("#5d6268")      ## the grey sheet roof


func _build_cerkiew(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(BZ_O, BZ_O + BZ_A)
	_g = _ground_under(outline)
	var g := _g
	var c := BZ_C
	var none := Color(0, 0, 0, 0)
	var b := Vector2(-BZ_A.y, BZ_A.x)
	_mode = M_STONE
	# --- the hall: walls to 16.5, one gable roof, a plinth
	var hall := _lpoly([[0.0, 0.0], [18.0, 0.0], [18.0, 15.8], [0.0, 15.8]])
	_prism(hall, g - 1.0, g + 21.0, BZ_WALL, none, M_STONE)
	kit_ledge_ring(hall, g + 20.5, 0.5, BZ_TRIM, 0.18)
	kit_ledge_ring(hall, g - 1.0, 1.6, BZ_WALL.darkened(0.12), 0.06)
	_gable(0.0, 18.0, c, 8.1, g + 21.0, 5.4, BZ_WALL, BZ_ROOF, true)
	# --- the polygonal east end: walls to 16, a low roof to 20
	var east := _lpoly([[18.0, 0.0], [21.2, 0.0], [24.3, 3.5], [24.4, 11.8], [21.4, 15.4], [18.0, 15.5]])
	_prism(east, g - 1.0, g + 19.9, BZ_WALL, none, M_STONE)
	kit_ledge_ring(east, g + 19.4, 0.45, BZ_TRIM, 0.16)
	var ec := _w(19.5, c)
	# the frustum wants the ring the other way round from the outline's
	var ring := PackedVector2Array()
	var tip := PackedVector2Array()
	for k in range(east.size() - 1, -1, -1):
		ring.append(east[k])
		tip.append(ec + (east[k] - ec) * 0.25)
	_frustum(ring, g + 19.9, tip, g + 23.5, BZ_ROOF, BZ_ROOF)
	# --- the sides: pilasters, tall round-headed windows
	for s: float in [-1.0, 1.0]:
		var vf := c + s * 7.9
		var out := b * s
		for pu: float in [0.6, 6.0, 12.0, 17.4]:
			_kbox(pu - 0.35, pu + 0.35, minf(vf, vf + s * 0.14), maxf(vf, vf + s * 0.14), g + 0.6, g + 20.5, BZ_TRIM)
		for wu: float in [3.3, 9.0, 14.7]:
			var at := _w(wu, vf)
			_arch_panel(at, BZ_A, out, 1.0, g + 9.3, g + 15.6, BZ_TRIM, 0.03, M_STONE)
			_arch_panel(at, BZ_A, out, 0.8, g + 9.5, g + 15.6, PAL_GLASS_DARK, 0.07, _lit(wu + vf, g + 9.5))
	# --- the west gable over the street wing: an oculus, the cross
	var wo := -BZ_A
	var oc := _w(-0.05, c)
	_disc(Vector3(oc.x, g + 23.4, oc.y), Vector3(wo.x, 0.0, wo.y), 1.2, 10, BZ_TRIM)
	var oc2 := _w(-0.1, c)
	_disc(Vector3(oc2.x, g + 23.4, oc2.y), Vector3(wo.x, 0.0, wo.y), 0.9, 10, PAL_GLASS_DARK)
	_kap_cross(0.3, c, g + 26.4, 1.6)
	_collide(outline)


## The parish church of Our Lady of Częstochowa (Kościół Matki Bożej Częstochowskiej, ul. Zagórna
## 5, Powiśle), a 1960s modernist church: a steep green copper A-frame roof that comes down almost
## to the ground at the front, a glazed triangular front with the doors under a canopy, and the
## twin concrete pylons with the bells and the tall cross before it. The whole church as a model
## that replaces the old kit church (`church_czestochowska`, built by `_build_church` until
## 2026-11-14: a beige box with a pyramid tower). From Mapillary photos of 2026 on Zagórna (the
## front from 68 m, the side wall close up; refs/czestochowska, never shipped), the OSM outline
## and GUGiK's LoD2 (over the ground: the A-frame's ridge 15; the pylons 22.5; the side walls
## about 6 under the roof's eaves; the flat back block 8). Spec docs/landmarks/specs/czestochowska.md.
## Frame: origin at the front's middle by the pylons, u from the front (south-east, to Zagórna)
## back, v across; the front faces -u.
const MC_O := Vector2(1142.0, 880.0)
const MC_A := Vector2(-0.6402, -0.7682)
const MC_WALL := Color("#c8c5be")      ## the grey render of the side walls (photos)
const MC_COPPER := Color("#7fa290")    ## the pale green copper roof
const MC_CONCRETE := Color("#6f7172")  ## the pylons and the roof's edges
const MC_FRAME := Color("#b39a5c")     ## the gold window frames
const MC_LIGHT := Color("#e9e6df")     ## the cross, the canopy


func _build_czestochowska(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(MC_O, MC_O + MC_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var b := Vector2(-MC_A.y, MC_A.x)
	_mode = M_STONE
	# --- the front A-frame: the roof from the ground to the ridge, its concrete edge, the glass
	_gable(-2.0, 6.2, 0.0, 8.2, g + 0.3, 14.7, MC_CONCRETE, MC_COPPER, true)
	_gable(-2.06, -2.0, 0.0, 7.3, g + 0.9, 13.1, PAL_GLASS_DARK, PAL_GLASS_DARK, false)
	_kbox(-2.3, -2.0, -8.4, 8.4, g - 1.0, g + 0.3, MC_CONCRETE)
	# the doors and their canopy at the foot of the glass
	_kbox(-3.4, -2.0, -5.0, 5.0, g - 1.0, g + 3.1, MC_WALL)
	_kbox(-3.46, -3.4, -4.4, 4.4, g + 0.1, g + 2.7, PAL_GLASS_DARK)
	_kbox(-4.4, -2.0, -5.6, 5.6, g + 3.1, g + 3.45, MC_LIGHT)
	_kbox(-6.0, -3.4, -6.0, 6.0, g - 1.0, g + 0.15, MC_WALL.darkened(0.08))
	# --- the nave: side walls to 6, the roof to the ridge, rows of gold-framed windows
	var nave := _lpoly([[6.0, -11.0], [30.0, -11.0], [30.0, 11.0], [6.0, 11.0]])
	_prism(nave, g - 1.0, g + 6.0, MC_WALL, none, M_STONE)
	_gable(6.0, 30.0, 0.0, 11.3, g + 6.0, 9.5, MC_WALL, MC_COPPER, true)
	for s2: float in [-1.0, 1.0]:
		var vf := s2 * 11.0
		for wu: float in [9.0, 14.5, 20.0, 25.5]:
			for wy: float in [1.2, 3.7]:
				_kbox(wu - 2.0, wu + 2.0, minf(vf, vf + s2 * 0.05), maxf(vf, vf + s2 * 0.05), g + wy, g + wy + 1.5, MC_FRAME)
				_kbox(wu - 1.8, wu + 1.8, minf(vf, vf + s2 * 0.09), maxf(vf, vf + s2 * 0.09), g + wy + 0.15, g + wy + 1.35, PAL_GLASS_DARK, _lit(wu + vf, g + wy))
	# --- the flat back block
	var back := _lpoly([[30.05, -9.0], [41.4, -9.0], [41.4, 9.0], [30.05, 9.0]])
	_prism(back, g - 1.0, g + 8.0, MC_WALL, MC_CONCRETE.lightened(0.15), M_STONE, M_STONE)
	for wu2: float in [32.5, 36.0, 39.5]:
		for s3: float in [-1.0, 1.0]:
			_kbox(wu2 - 1.2, wu2 + 1.2, minf(s3 * 9.0, s3 * 9.06), maxf(s3 * 9.0, s3 * 9.06), g + 2.0, g + 6.0, PAL_GLASS_DARK, _lit(wu2 * s3, g + 2.0))
	# --- the twin pylons before the front, the bells between them, the emblem, the cross
	for s4: float in [-1.0, 1.0]:
		_kbox(-3.0, -2.0, minf(s4 * 0.6, s4 * 1.9), maxf(s4 * 0.6, s4 * 1.9), g + 3.45, g + 22.5, MC_CONCRETE)
	for by: float in [16.0, 18.0, 20.0]:
		_kbox(-2.75, -2.25, -0.6, 0.6, g + by, g + by + 0.25, MC_CONCRETE.darkened(0.15))
		_kbox(-2.7, -2.3, -0.35, 0.35, g + by + 0.25, g + by + 1.1, MC_FRAME.darkened(0.25))
	var em := _w(-3.05, 0.0)
	_disc(Vector3(em.x, g + 11.0, em.y), Vector3(-MC_A.x, 0.0, -MC_A.y), 0.9, 10, MC_LIGHT)
	_kbox(-2.6, -2.4, -0.1, 0.1, g + 21.0, g + 27.0, MC_LIGHT)
	_kbox(-2.6, -2.4, -1.0, 1.0, g + 24.6, g + 24.85, MC_LIGHT)
	_collide(outline)


## Holy Trinity church on Solec (Kościół Świętej Trójcy na Solcu, the site key still says Praga):
## a cream classicist church with a temple front and pediment towards the north-east, a short
## transept and a slim bell turret with a little bulb dome over the crossing. The whole church as a
## model that replaces the old kit church (`church_trojca_praga`, built by `_build_church` until
## 2026-11-14: a plain box). From Mapillary 360s of 2025 and 2026 on the avenue to the north-east
## (the front and the turret against the sky from 96 m; refs/trojca_praga, never shipped), the OSM
## outline and GUGiK's LoD2 (over the ground: the nave's eaves 14 and ridge 17; the transept's
## ridge 17.2; the turret's top 26.4; the chancel 16.5; the back wings 9).
## Spec docs/landmarks/specs/trojca_solec.md.
## Frame: origin at the front's middle, u from the front (north-east) back, v across; the front
## faces -u.
const SL_O := Vector2(1077.3, 252.8)
const SL_A := Vector2(-0.6905, 0.7234)
const SL_WALL := Color("#e2d6bc")      ## the cream plaster
const SL_TRIM := Color("#f2ecdf")      ## pilasters, cornice, pediment
const SL_ROOF := Color("#63696e")      ## the grey sheet roofs
const SL_DOME := Color("#5b6764")      ## the turret's dark dome
const SL_DOOR := Color("#4a3a30")


func _build_trojca_solec(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(SL_O, SL_O + SL_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var b := Vector2(-SL_A.y, SL_A.x)
	_mode = M_STONE
	# --- the masses: nave, transept, chancel, the low wings and the side annex
	var nave := _lpoly([[0.0, -4.6], [19.5, -4.6], [19.5, 4.6], [0.0, 4.6]])
	_prism(nave, g - 1.0, g + 14.1, SL_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 13.5, 0.5, SL_TRIM, 0.2)  # its top 5 cm under the transept's and 10 under the front's entablature
	_gable(0.0, 19.5, 0.0, 4.85, g + 14.1, 2.9, SL_WALL, SL_ROOF, false)
	var tran := _lpoly([[19.5, -7.5], [25.0, -7.5], [25.0, 7.5], [19.5, 7.5]])
	_prism(tran, g - 1.0, g + 14.1, SL_WALL, none, M_STONE)
	kit_ledge_ring(tran, g + 13.55, 0.5, SL_TRIM, 0.2)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(-7.5, 7.5, 22.25, 2.95, g + 14.1, 3.1, SL_WALL, SL_ROOF, true)
	_a = ka
	_b = kb
	var ch := _lpoly([[25.0, -4.0], [31.0, -4.0], [31.0, 4.0], [25.0, 4.0]])
	_prism(ch, g - 1.0, g + 13.5, SL_WALL, none, M_STONE)
	_gable(31.0, 25.0, 0.0, 4.2, g + 13.5, 3.0, SL_WALL, SL_ROOF, false)
	for wv: Array in [[-9.5, -4.0], [4.0, 9.5]]:
		_prism(_lpoly([[25.05, wv[0]], [31.0, wv[0]], [31.0, wv[1]], [25.05, wv[1]]]), g - 1.0, g + 9.0, SL_WALL, SL_ROOF.lightened(0.1), M_STONE, M_STONE)
	_prism(_lpoly([[6.0, 4.6], [10.0, 4.6], [10.0, 9.5], [6.0, 9.5]]), g - 1.0, g + 8.6, SL_WALL, SL_ROOF.lightened(0.1), M_STONE, M_STONE)
	kit_ledge_ring(nave, g - 1.0, 1.6, SL_WALL.darkened(0.15), 0.06)
	# --- the temple front: four pilasters, the entablature, the pediment, the door, a window
	_sl_turn(1)
	kit_face(0.0)
	for pv: float in [-4.1, -1.6, 1.6, 4.1]:
		_kbox(pv - 0.35, pv + 0.35, -0.04, 0.16, g + 0.6, g + 12.6, SL_TRIM)
	_kbox(-4.75, 4.75, -0.04, 0.3, g + 12.6, g + 14.1, SL_TRIM)
	kit_pediment(0.0, 5.0, g + 14.1, 2.9, SL_TRIM, SL_ROOF, 0.35)
	kit_door(0.0, g + 0.0, 4.2, 1.0, SL_TRIM, SL_DOOR, true)
	var wa := _w(0.0, 0.0)
	_arch_panel(wa, _a, _b, 0.9, g + 6.6, g + 10.2, SL_TRIM, 0.03, M_STONE)
	_arch_panel(wa, _a, _b, 0.7, g + 6.8, g + 10.2, PAL_GLASS_DARK, 0.07, _lit(1.0, g + 6.8))
	kit_front(SL_O, SL_O + SL_A)
	# --- the sides: tall round-headed windows between pilasters
	for s: float in [-1.0, 1.0]:
		var vf := s * 4.6
		var out := b * s
		for pu: float in [0.8, 6.4, 12.6, 19.0]:
			_kbox(pu - 0.3, pu + 0.3, minf(vf, vf + s * 0.12), maxf(vf, vf + s * 0.12), g + 0.6, g + 13.6, SL_TRIM)
		for wu: float in [3.6, 15.8]:
			_arch_panel(_w(wu, vf), SL_A, out, 0.9, g + 5.0, g + 10.5, SL_TRIM, 0.03, M_STONE)
			_arch_panel(_w(wu, vf), SL_A, out, 0.7, g + 5.2, g + 10.5, PAL_GLASS_DARK, 0.07, _lit(wu + vf, g + 5.2))
		var te := _w(22.25, s * 7.5)
		_arch_panel(te, SL_A, out, 1.0, g + 5.0, g + 10.8, PAL_GLASS_DARK, 0.06, _lit(s, g + 5.0))
	# --- the bell turret over the crossing: base, belfry arches, bulb dome, spire, cross
	var tu := 22.3
	_lbox(tu, 0.0, 1.5, 1.5, g + 15.0, g + 21.0, SL_WALL, M_STONE, none)
	_lbox(tu, 0.0, 1.65, 1.65, g + 21.0, g + 21.4, SL_TRIM, M_STONE, SL_TRIM.darkened(0.05))
	var tc := _w(tu, 0.0)
	for dd: Vector2 in [SL_A, -SL_A, b, -b]:
		_arch_panel(tc + dd * 1.5, Vector2(-dd.y, dd.x), dd, 0.45, g + 18.2, g + 20.0, CHURCH_DARK, 0.03, M_STONE)
	var ring := func(r: float) -> PackedVector2Array:
		var o := PackedVector2Array()
		for k in 8:
			var an := PI * (k + 0.5) / 4.0
			o.append(tc + (SL_A * cos(an) + b * sin(an)) * r)
		return o
	_frustum(ring.call(1.2), g + 21.4, ring.call(1.45), g + 22.6, SL_DOME)
	_frustum(ring.call(1.45), g + 22.6, ring.call(0.5), g + 23.9, SL_DOME)
	_frustum(ring.call(0.5), g + 23.9, ring.call(0.06), g + 25.6, SL_DOME.lightened(0.05), SL_DOME)
	_kap_cross(tu, 0.0, g + 25.6, 1.0)
	_collide(outline)


## Turns the kit frame round SL_A as `_kb_turn` does round KB_A (1: +v out of the front).
func _sl_turn(side: int) -> void:
	var b := Vector2(-SL_A.y, SL_A.x)
	match side:
		0:
			_a = SL_A
		1:
			_a = b
		2:
			_a = -SL_A
		_:
			_a = -b
	_b = Vector2(-_a.y, _a.x)


## St Augustine's church (Kościół św. Augustyna, ul. Nowolipki 18; Józef Pius Dziekoński,
## 1891-96), a red clinker-brick neo-Romanesque basilica whose 70 m tower on the front's corner
## was Warsaw's tallest when built and the one thing left standing over the ghetto's ruins in
## 1945. The whole church as a model that replaces the old kit church (`church_augustyn`, built by
## `_build_church` until 2026-11-14: a brick box with a pyramid tower, its front at the far end).
## No open street photo faces it from the cloud; built from the church's published description
## (Wikipedia: the three-nave basilica, the two-storey front with three arcades, six niches, a
## large rose and a pediment, paired roses in the clerestory, triple windows in the aisles, the
## tower to 70 m with a 5.1 m cross on a 1.35 m ball), the OSM outline and GUGiK's LoD2 (over the
## ground: the tower 68.5; the nave's eaves 22.5 and ridge 26.5; the aisles 9.5 to 14; a stair
## turret 40). Spec docs/landmarks/specs/augustyn.md.
## Frame: origin at the front's middle on the south-east end, u along the church to the
## north-west apse, v across; the front faces -u; the tower stands at v -11.
const AU_O := Vector2(-2399.2, -1142.5)
const AU_A := Vector2(-0.4297, -0.9030)
const AU_BRICK := Color("#b9583b")     ## the orange-red brick (photos)
const AU_STONE := Color("#d7c3a0")     ## the beige stone details
const AU_DARKSTONE := Color("#8a4a38") ## the brown-red stone bands
const AU_ROOF := Color("#5e6266")      ## the grey roofs
const AU_SPIRE := Color("#5f9580")     ## the green copper of the spire and turrets (photos)


## A lean-to roof over an aisle: from the outer wall's top (v_out, y_out) up to the nave wall
## (v_in, y_in) between u0 and u1, with its two end triangles.
func _au_lean(u0: float, u1: float, v_out: float, v_in: float, y_out: float, y_in: float, col: Color) -> void:
	var at := func(u: float, v: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var b := Vector2(-AU_A.y, AU_A.x)
	var side := signf(v_out - v_in)
	var n := (Vector3(b.x, 0.0, b.y) * side * (y_in - y_out) + Vector3.UP * absf(v_out - v_in)).normalized()
	var none := Vector2(-1, -1)
	_quad(at.call(u0, v_out, y_out), at.call(u1, v_out, y_out), at.call(u1, v_in, y_in), at.call(u0, v_in, y_in), n, col)
	for e: Array in [[u0, -1.0], [u1, 1.0]]:
		var eu: float = e[0]
		var en := Vector3(AU_A.x, 0.0, AU_A.y) * float(e[1])
		_tri(at.call(eu, v_out, y_out), at.call(eu, v_in, y_out), at.call(eu, v_in, y_in), en, AU_BRICK, none, none, none, -1.0, false)


func _build_augustyn(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(AU_O, AU_O + AU_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var b := Vector2(-AU_A.y, AU_A.x)
	_mode = M_STONE
	# --- the nave and choir under one roof, the aisles with lean-tos, the apse
	var nave := _lpoly([[0.0, -7.0], [61.0, -7.0], [61.0, 7.0], [0.0, 7.0]])
	_prism(nave, g - 1.0, g + 22.5, AU_BRICK, none, M_STONE)
	kit_ledge_ring(nave, g + 22.0, 0.5, AU_STONE, 0.18)
	_gable(0.0, 61.0, 0.0, 7.2, g + 22.5, 4.2, AU_BRICK, AU_ROOF, true)
	var rings: Array[PackedVector2Array] = [nave]
	for s: float in [-1.0, 1.0]:
		var u0 := 11.2 if s < 0.0 else 1.0
		var aisle := _lpoly([[u0, s * 7.0], [59.0, s * 7.0], [59.0, s * 15.0], [u0, s * 15.0]])
		_prism(aisle, g - 2.5, g + 9.5, AU_BRICK, none, M_STONE)
		kit_ledge_ring(aisle, g + 9.0, 0.45, AU_STONE, 0.15)
		_au_lean(11.0 if s > 0.0 else u0, 59.0, s * 15.0, s * 7.0, g + 9.5, g + 14.0, AU_ROOF.lightened(0.05))
		rings.append(aisle)
	var ac := _w(61.0, 0.0)
	var half := PackedVector2Array()
	for k in 7:
		var ang := -PI * 0.5 + PI * k / 6.0
		half.append(ac + (AU_A * cos(ang) + b * sin(ang)) * 6.8)
	_prism(half, g - 1.0, g + 19.0, AU_BRICK, none, M_STONE)
	var tip := PackedVector2Array()
	for p: Vector2 in half:
		tip.append(ac + (p - ac) * 0.2)
	_frustum(half, g + 19.0, tip, g + 24.0, AU_ROOF, AU_ROOF)
	for i in rings.size():
		kit_ledge_ring(rings[i], g - 2.5, 3.5 - 0.04 * i, AU_DARKSTONE, 0.07)
	# --- the sides: paired roses in the clerestory, triple round-headed windows in the aisles
	for s2: float in [-1.0, 1.0]:
		var vc := s2 * 7.0
		var vs := s2 * 15.0
		var out := b * s2
		for bu: float in [15.0, 21.0, 27.0, 33.0, 39.0, 45.0, 51.0, 57.0]:
			for du: float in [-1.2, 1.2]:
				var rp := _w(bu + du, vc + s2 * 0.04)
				_disc(Vector3(rp.x, g + 18.0, rp.y), Vector3(out.x, 0.0, out.y), 0.85, 8, AU_STONE)
				var rp2 := _w(bu + du, vc + s2 * 0.08)
				_disc(Vector3(rp2.x, g + 18.0, rp2.y), Vector3(out.x, 0.0, out.y), 0.6, 8, PAL_GLASS_DARK)
			for du2: float in [-1.0, 0.0, 1.0]:
				_arch_panel(_w(bu + du2, vs), AU_A, out, 0.35, g + 3.0, g + 6.4, PAL_GLASS_DARK, 0.05, _lit(bu + du2 + vs, g + 3.0))
			_kbox(bu + 2.6, bu + 3.4, minf(vs, vs + s2 * 0.5), maxf(vs, vs + s2 * 0.5), g - 2.5, g + 9.0, AU_BRICK)
	# --- the front: three arcades of the portico, six niches, the great rose, the pediment
	var fo := -AU_A
	_kbox(-1.6, 0.0, -6.0, 6.0, g - 1.0, g + 7.5, AU_BRICK)
	_kbox(-1.75, -1.55, -6.2, 6.2, g + 7.5, g + 8.1, AU_STONE)
	for av: float in [-3.6, 0.0, 3.6]:
		_arch_panel(_w(-1.6, av), b, fo, 1.35, g + 0.0, g + 5.2, CHURCH_DARK, 0.02, M_STONE)
	for nv: float in [-4.5, -2.7, -0.9, 0.9, 2.7, 4.5]:
		_arch_panel(_w(0.0, nv), b, fo, 0.55, g + 9.0, g + 11.0, AU_STONE, 0.04, M_STONE)
	var rc := _w(-0.04, 0.0)
	_disc(Vector3(rc.x, g + 16.0, rc.y), Vector3(fo.x, 0.0, fo.y), 3.2, 14, AU_STONE)
	var rc2 := _w(-0.08, 0.0)
	_disc(Vector3(rc2.x, g + 16.0, rc2.y), Vector3(fo.x, 0.0, fo.y), 2.6, 14, PAL_GLASS_DARK)
	_kbox(-0.2, 0.0, -7.3, 7.3, g + 21.9, g + 22.6, AU_STONE)
	_kap_cross(0.3, 0.0, g + 26.7, 2.2)
	# the slim corner turrets of the front gable, with little green spires
	for s4: float in [-1.0, 1.0]:
		var cc := _w(-0.3, s4 * 7.0)
		var r8 := PackedVector2Array()
		for k6 in 8:
			var an6 := PI * (k6 + 0.5) / 4.0
			r8.append(cc + (AU_A * cos(an6) + b * sin(an6)) * 0.75)
		_frustum(r8, g + 8.1, r8, g + 24.5, AU_BRICK)
		var r8t := PackedVector2Array()
		for p3: Vector2 in r8:
			r8t.append(cc + (p3 - cc) * 0.1)
		_frustum(r8, g + 24.5, r8t, g + 27.5, AU_SPIRE, AU_SPIRE)
	# the chapel annex on the front's other side
	var fr := _lpoly([[1.0, 7.0], [11.0, 7.0], [11.0, 15.0], [1.0, 15.0]])
	_prism(fr, g + 9.5, g + 12.3, AU_BRICK, AU_ROOF.lightened(0.1), M_STONE, M_STONE)
	# --- the tower on the front's corner: shaft, two stages, the belfry arcades, the spire
	var tu := 7.0
	var tv := -11.0
	_lbox(tu, tv, 4.0, 4.0, g - 1.0, g + 34.0, AU_BRICK, M_STONE, none)
	kit_ledge_ring(_rect(tu, tv, 4.0, 4.0), g + 13.0, 0.45, AU_STONE, 0.12)
	kit_ledge_ring(_rect(tu, tv, 4.0, 4.0), g + 24.0, 0.45, AU_STONE, 0.12)
	_lbox(tu, tv, 4.25, 4.25, g + 34.0, g + 34.7, AU_STONE, M_STONE, AU_STONE.darkened(0.06))
	_lbox(tu, tv, 3.4, 3.4, g + 34.7, g + 47.0, AU_BRICK, M_STONE, none)
	_lbox(tu, tv, 3.65, 3.65, g + 47.0, g + 47.6, AU_STONE, M_STONE, AU_STONE.darkened(0.06))
	var tc := _w(tu, tv)
	for dd: Vector2 in [AU_A, -AU_A, b, -b]:
		var al := Vector2(-dd.y, dd.x)
		for k2: float in [-1.15, 0.0, 1.15]:
			_arch_panel(tc + dd * 3.4 + al * k2, al, dd, 0.42, g + 39.0, g + 44.5, CHURCH_DARK, 0.03, M_STONE)
		_arch_panel(tc + dd * 4.0, al, dd, 0.5, g + 26.0, g + 30.5, CHURCH_DARK, 0.03, M_STONE)
		_disc(Vector3((tc + dd * 4.03).x, g + 18.5, (tc + dd * 4.03).y), Vector3(dd.x, 0.0, dd.y), 0.9, 8, AU_STONE)
	# the small top stage with its arched openings, then the octagonal green spire
	_lbox(tu, tv, 2.6, 2.6, g + 47.6, g + 52.0, AU_BRICK, M_STONE, none)
	for dd2: Vector2 in [AU_A, -AU_A, b, -b]:
		var al2 := Vector2(-dd2.y, dd2.x)
		for k4: float in [-0.8, 0.8]:
			_arch_panel(tc + dd2 * 2.6 + al2 * k4, al2, dd2, 0.32, g + 48.4, g + 50.8, CHURCH_DARK, 0.03, M_STONE)
	_lbox(tu, tv, 2.8, 2.8, g + 52.0, g + 52.5, AU_STONE, M_STONE, AU_STONE.darkened(0.06))
	for s3: float in [-1.0, 1.0]:
		for t: float in [-1.0, 1.0]:
			_pinnacle(tu + s3 * 3.2, tv + t * 3.2, 0.7, g + 47.6, 2.4, AU_STONE)
	var oc8 := func(r: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for k5 in 8:
			var an5 := PI * (k5 + 0.5) / 4.0
			ring.append(tc + (AU_A * cos(an5) + b * sin(an5)) * r)
		return ring
	_frustum(oc8.call(2.5), g + 52.5, oc8.call(0.12), g + 63.4, AU_SPIRE, AU_SPIRE)
	_lbox(tu, tv, 0.6, 0.6, g + 63.4, g + 64.6, Color("#c9a64a"), M_STONE, Color("#c9a64a"))
	_kap_cross(tu, tv, g + 64.6, 5.1)
	# --- the small stair turret by the choir
	var st := _w(50.0, 6.0)
	var oct := PackedVector2Array()
	for k3 in 8:
		var an := PI * (k3 + 0.5) / 4.0
		oct.append(st + (AU_A * cos(an) + b * sin(an)) * 1.3)
	_frustum(oct, g + 14.0, oct, g + 34.0, AU_BRICK)
	var otip := PackedVector2Array()
	for p2: Vector2 in oct:
		otip.append(st + (p2 - st) * 0.1)
	_frustum(oct, g + 34.0, otip, g + 40.0, AU_SPIRE, AU_SPIRE)
	_collide(outline)


## The Basilian monastery's street wing (Klasztor Bazylianów, Miodowa 16), the classicist front
## of the monastery whose middle is the front of the Basilians' church (`church_cerkiew`, the
## hall in the courtyard behind it): a white four-storey wing along Miodowa under a grey hipped
## roof, a rusticated ground floor, the middle risalit with four giant pilasters, three arched
## doors and a low pediment with a cross, and the two back wings round the church's hall. A model
## that replaces the plain OpenStreetMap block (building 1825; no landmark until 2026-11-14). From
## the Mapillary 360s of 2026 along Miodowa (refs/cerkiew, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the wing's eaves 17.4 and ridge 20; the pediment 19.4; the back
## wings 16 to 21; the low annex 4.4). Spec docs/landmarks/specs/bazylianie.md.
## Frame: origin at the street front's east corner, u along Miodowa west, v out of the front (the
## kit's way round: the building is at v < 0).
const BM_O := Vector2(-1047.48, -1518.78)
const BM_A := Vector2(0.822, 0.568)
const BM_WALL := Color("#ebe5d7")      ## the white-cream plaster (the church's front, the same)
const BM_TRIM := Color("#f5f1e8")      ## pilasters, cornices, frames
const BM_RUST := Color("#ddd5c4")      ## the rusticated ground floor
const BM_ROOF := Color("#5d6268")      ## the grey sheet roofs
const BM_DOOR := Color("#4b3c31")      ## the dark wood doors


func _build_bazylianie(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(BM_O, BM_O + BM_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the street wing: walls to 17.4, a cornice under the eaves, the hipped roof to 20
	var wing := _lpoly([[0.0, -6.87], [39.39, -6.87], [39.39, 0.0], [0.0, 0.0]])
	_prism(wing, g - 1.0, g + 17.4, BM_WALL, none, M_STONE)
	kit_ledge_ring(wing, g + 16.85, 0.45, BM_TRIM, 0.25)
	_hip(19.695, -3.435, 19.695, 3.435, g + 17.4, 2.6, BM_ROOF)
	# --- the back wings round the church's hall, their hipped roofs; the low annex
	_kbox(35.69, 39.28, -9.65, -6.9, g - 1.0, g + 16.8, BM_WALL)
	_kbox(0.59, 3.39, -9.6, -6.9, g - 1.0, g + 16.8, BM_WALL)
	_prism(_lpoly([[27.14, -20.0], [35.79, -20.0], [35.79, -6.9], [27.14, -6.9]]), g - 1.0, g + 16.8, BM_WALL, none, M_STONE)
	_hip(31.465, -13.45, 4.325, 6.55, g + 16.8, 3.0, BM_ROOF)
	_prism(_lpoly([[3.29, -22.0], [11.04, -22.0], [11.04, -6.9], [3.29, -6.9]]), g - 1.0, g + 16.8, BM_WALL, none, M_STONE)
	_hip(7.165, -14.45, 3.875, 7.55, g + 16.8, 3.0, BM_ROOF)
	_kbox(27.1, 34.99, -24.8, -20.05, g - 1.0, g + 4.4, BM_WALL.darkened(0.05))
	# --- the street front: the rusticated ground floor, string courses, panes in every bay
	# (each side's bands run on into the risalit and a few centimetres past the corner, so no end
	# of them lies in a wall's plane)
	var sides: Array = [[-0.06, 11.3, [1.5, 4.2, 6.9, 9.6]], [26.88, 39.45, [28.6, 31.6, 34.6, 37.6]]]
	for sd: Array in sides:
		var u0: float = sd[0]
		var u1: float = sd[1]
		_kbox(u0, u1, -0.02, 0.06, g - 1.0, g + 4.3, BM_RUST)
		kit_face(0.06)
		kit_bands(u0, u1, g - 1.0, g + 4.3, 0.75, BM_RUST)
		kit_face(0.0)
		kit_panes(sd[2], [g + 1.0], 1.3, 2.3, PAL_GLASS_DARK, 0.11)
		kit_panes(sd[2], [g + 5.6, g + 9.8], 1.3, 2.5, PAL_GLASS_DARK, 0.05)
		kit_panes(sd[2], [g + 13.7], 1.3, 1.9, PAL_GLASS_DARK, 0.05)
		for sy: float in [5.45, 9.65, 13.55]:
			kit_ledge(u0, u1, g + sy, 0.15, BM_TRIM, 0.12)
		kit_ledge(u0, u1, g + 4.3, 0.3, BM_TRIM, 0.16)
	# --- the risalit: stands 0.35 out, giant pilasters on a rusticated base, three arched doors,
	# its own cornice and the low pediment with the cross
	var r0 := 11.19
	var r1 := 26.99
	_kbox(r0, r1, -0.02, 0.35, g - 1.0, g + 17.4, BM_WALL)
	_kbox(r0 - 0.15, r1 + 0.15, -0.6, 0.6, g + 17.4, g + 17.75, BM_TRIM)
	kit_face(0.35)
	kit_bands(r0, r1, g - 1.0, g + 4.3, 0.75, BM_WALL)
	kit_ledge(r0, r1, g + 4.3, 0.3, BM_TRIM, 0.16)
	for pu: float in [11.7, 16.6, 21.6, 26.5]:
		_kbox(pu - 0.45, pu + 0.45, 0.33, 0.52, g + 4.6, g + 16.9, BM_TRIM)
		_kbox(pu - 0.55, pu + 0.55, 0.33, 0.6, g + 16.9, g + 17.4, BM_TRIM)
	for bu: float in [14.15, 19.1, 24.05]:
		kit_face(0.4)
		kit_door(bu, g, 3.6, 0.95 if bu == 19.1 else 0.8, BM_TRIM, BM_DOOR, true)
		kit_face(0.35)
		for wy: Array in [[5.6, 2.6], [9.8, 2.4], [13.7, 1.9]]:
			var sy: float = wy[0]
			var hh: float = wy[1]
			kit_panes([bu], [g + sy], 1.4, hh, PAL_GLASS_DARK, 0.05)
			_kbox(bu - 0.95, bu + 0.95, 0.3, 0.5, g + sy + hh + 0.1, g + sy + hh + 0.35, BM_TRIM)
	kit_face(0.0)
	# the pediment's slopes run back 3 m into the hipped roof, under its ridge
	kit_face(-3.0)
	kit_pediment(19.09, 8.05, g + 17.75, 1.8, BM_TRIM, BM_ROOF, 3.6)
	kit_face(0.0)
	_kap_cross(19.09, 0.3, g + 19.55, 1.6)
	# --- the ends and the back wings' outer walls: panes, so no side is a blank box
	# (each wall from p to q with its outside on the left, three rows of panes at the fractions)
	var rows: Array = [g + 5.6, g + 9.8, g + 13.7]
	var walls: Array = [
		[Vector2(39.39, 0.0), Vector2(39.39, -6.87), [0.5]],
		[Vector2(0.0, -6.87), Vector2(0.0, 0.0), [0.5]],
		[Vector2(35.79, -6.9), Vector2(35.79, -20.0), [0.35, 0.6, 0.85]],
		[Vector2(3.29, -22.0), Vector2(3.29, -6.9), [0.2, 0.47, 0.73]],
		[Vector2(35.79, -20.0), Vector2(27.14, -20.0), [0.3, 0.7]],
		[Vector2(11.04, -22.0), Vector2(3.29, -22.0), [0.3, 0.7]],
	]
	for wl: Array in walls:
		var p: Vector2 = wl[0]
		var q: Vector2 = wl[1]
		var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
		var cols: Array = []
		for f: float in wl[2]:
			cols.append(f * n)
		kit_panes(cols, rows, 1.2, 2.2, PAL_GLASS_DARK, 0.05)
		kit_front(BM_O, BM_O + BM_A)
	_collide(outline)


## The Dominican priory (Klasztor Ojców Dominikanów, Freta 10) beside St Hyacinth's: the cream
## plastered wings round the cloister garth on the New Town's slope to the river. A model that
## replaces the plain OpenStreetMap block (building 3005; no landmark until 2026-11-14). From a
## Mapillary photo of 2020 in the passage by the west wing (refs/dominikanie, never shipped: pale
## yellow plaster, a rusticated ground floor under a cornice band, plain windows), the OSM outline
## and GUGiK's LoD2 (absolute heights, the ground falling from about 0 to -4 to the north-east: the
## long wing's eaves 13 and ridge 17.3, its outer gallery 8.6 to 10 and the cloister walk 10 to 7.4
## under lean-tos, the east wing's eaves 7.8 and ridge 13, the low west range 4.5).
## Spec docs/landmarks/specs/dominikanie.md.
## Frame: origin at the long wing's west corner by the church, u along the wing east, v across
## (to the cloister and the river).
const DK_O := Vector2(-989.0, -1957.1)
const DK_A := Vector2(0.704, -0.710)
const DK_WALL := Color("#e6d4a6")      ## the pale yellow plaster (photo)
const DK_TRIM := Color("#efe4c4")      ## cornices, bands
const DK_RUST := Color("#d9c590")      ## the rusticated ground floor
const DK_ROOF := Color("#97594a")      ## the red-brown roofs (St Hyacinth's)


## A lean-to roof between u0 and u1 in the current frame: from the outer edge (v_out, y_out) up to
## the wall it leans on (v_in, y_in), with its two end triangles in `wall`.
func _dk_lean(u0: float, u1: float, v_out: float, v_in: float, y_out: float, y_in: float, wall: Color, roof: Color) -> void:
	var at := func(u: float, v: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var side := signf(v_out - v_in)
	var n := (Vector3(_b.x, 0.0, _b.y) * side * (y_in - y_out) + Vector3.UP * absf(v_out - v_in)).normalized()
	var none := Vector2(-1, -1)
	_quad(at.call(u0, v_out, y_out), at.call(u1, v_out, y_out), at.call(u1, v_in, y_in), at.call(u0, v_in, y_in), n, roof)
	for e: Array in [[u0, -1.0], [u1, 1.0]]:
		var eu: float = e[0]
		var en := Vector3(_a.x, 0.0, _a.y) * float(e[1])
		_tri(at.call(eu, v_out, y_out), at.call(eu, v_in, y_out), at.call(eu, v_in, y_in), en, wall, none, none, none, -1.0, false)


## One wall of the priory from p to q (local metres), its outside on the left of p→q: a pane every
## `step` metres on each sill height in `rows` (absolute), `proud` off the wall. Puts the priory's frame back.
func _dk_side(p: Vector2, q: Vector2, step: float, rows: Array, h: float, proud := 0.05) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var k := maxi(1, floori(n / step))
	var cols: Array = []
	for i in k:
		cols.append((float(i) + 0.5) * n / float(k))
	kit_panes(cols, rows, 1.15, h, PAL_GLASS_DARK, proud)
	kit_front(DK_O, DK_O + DK_A)


func _build_dominikanie(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(DK_O, DK_O + DK_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the long wing: walls to 13, its gable roof to 17.3 (gables at both ends)
	var wing := _lpoly([[0.0, 5.0], [62.0, 5.0], [62.0, 13.8], [0.0, 13.8]])
	_prism(wing, g - 1.0, 13.0, DK_WALL, none, M_STONE)
	kit_ledge_ring(wing, 12.55, 0.45, DK_TRIM, 0.2)
	_gable(0.0, 62.0, 9.4, 4.4, 13.0, 4.3, DK_WALL, DK_ROOF, true)
	# --- the outer gallery along the north-west side under a lean-to (8.6 to 10)
	_prism(_lpoly([[0.0, 0.0], [46.5, 0.0], [46.5, 5.02], [0.0, 5.02]]), g - 1.0, 8.6, DK_WALL, none, M_STONE)
	_dk_lean(0.0, 46.5, -0.25, 5.0, 8.6, 10.2, DK_WALL, DK_ROOF)
	# --- the cloister walk on the garth side under a lean-to (10 down to 7.4)
	_prism(_lpoly([[13.0, 13.78], [46.5, 13.78], [46.5, 21.0], [13.0, 21.0]]), g - 1.0, 7.4, DK_WALL, none, M_STONE)
	_dk_lean(13.0, 46.5, 21.25, 13.8, 7.4, 10.2, DK_WALL, DK_ROOF)
	# --- the low west range round the church's chancel
	_kbox(5.3, 13.0, 13.85, 21.0, g - 1.0, 5.5, DK_WALL.darkened(0.04))
	_kbox(4.5, 13.0, 21.05, 31.7, g - 1.0, 4.5, DK_WALL.darkened(0.04))
	# --- the east wing down the slope: walls to 7.8, its gable roof to 13 along v
	var east := _lpoly([[46.52, -21.4], [61.5, -21.4], [61.5, 34.0], [46.52, 34.0]])
	_prism(east, g - 1.0, 7.8, DK_WALL, none, M_STONE)
	kit_ledge_ring(east, 7.4, 0.4, DK_TRIM, 0.18)
	kit_front(_w(54.01, -21.4), _w(54.01, 34.0))
	_gable(0.0, 55.4, 0.0, 7.49, 7.8, 5.2, DK_WALL, DK_ROOF, true)
	kit_front(DK_O, DK_O + DK_A)
	# --- the rusticated ground floor and the band over it on the gallery's outer side
	for s: Array in [[Vector2(46.5, 0.0), Vector2(0.0, 0.0)]]:
		var p: Vector2 = s[0]
		var q: Vector2 = s[1]
		var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
		_kbox(-0.05, n + 0.05, -0.02, 0.06, g - 1.0, 3.6, DK_RUST)
		kit_face(0.06)
		kit_bands(-0.05, n + 0.05, g - 1.0, 3.6, 0.7, DK_RUST)
		kit_face(0.0)
		kit_ledge(-0.08, n + 0.08, 3.6, 0.3, DK_TRIM, 0.14)
		kit_front(DK_O, DK_O + DK_A)
	# --- panes on every side (three storeys on the long wing, two on the east wing and the walks)
	# (the long wing's west end stands against the church's buildings: no panes there)
	_dk_side(Vector2(46.5, 0.0), Vector2(0.0, 0.0), 3.4, [0.9], 2.2, 0.12)
	_dk_side(Vector2(46.5, 0.0), Vector2(0.0, 0.0), 3.4, [4.9], 2.2)
	_dk_side(Vector2(46.5, 5.0), Vector2(0.0, 5.0), 3.4, [10.3], 1.6)
	_dk_side(Vector2(62.0, 13.8), Vector2(62.0, 5.0), 3.0, [9.0], 2.0)
	_dk_side(Vector2(5.3, 13.8), Vector2(13.0, 13.8), 3.0, [6.2, 9.0], 2.0)
	_dk_side(Vector2(13.0, 21.0), Vector2(46.5, 21.0), 3.4, [0.5, 3.8], 2.0)
	_dk_side(Vector2(13.0, 13.8), Vector2(46.5, 13.8), 3.4, [10.5], 1.6)
	_dk_side(Vector2(61.5, 34.0), Vector2(61.5, 14.0), 3.3, [-2.2, 1.2, 4.6], 2.0)
	_dk_side(Vector2(61.5, 5.0), Vector2(61.5, -21.4), 3.3, [1.2, 4.6], 2.0)
	_dk_side(Vector2(46.52, 21.0), Vector2(46.52, 34.0), 3.3, [-2.2, 1.2, 4.6], 2.0)
	_dk_side(Vector2(46.52, -21.4), Vector2(46.52, -0.7), 3.3, [1.2, 4.6], 2.0)
	_dk_side(Vector2(61.5, -21.4), Vector2(46.52, -21.4), 3.6, [1.2, 4.6], 2.0)
	_dk_side(Vector2(46.52, 34.0), Vector2(61.5, 34.0), 3.6, [-2.2, 1.2, 4.6], 2.0)
	# --- the doors: the gallery's and the east wing's
	kit_front(_w(46.5, 0.0), _w(0.0, 0.0))
	kit_face(0.12)
	kit_door(23.0, -0.3, 3.0, 0.9, DK_TRIM, Color("#5a4232"), true)
	kit_face(0.0)
	kit_front(DK_O, DK_O + DK_A)
	_collide(outline)


## The house of the Franciscan Sisters of the Family of Mary (Zgromadzenie Sióstr Franciszkanek
## Rodziny Maryi): a long low classicist house in warm peach plaster, banded all over, its street
## end with tall blind windows under small attic windows, a granite plinth and dark hipped roofs;
## the taller middle block of two storeys and a low annex on its west side. A model that replaces
## the plain OpenStreetMap block (building 3328; no landmark until 2026-11-14). From two Mapillary
## photos of 2020 on the street at its north end (refs/rodziny, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the end wings' eaves 6.4 and ridges 9.4, the middle block's
## eaves 9.4 and ridge 11.4, the annex 5.4). Spec docs/landmarks/specs/rodziny_maryi.md.
## Frame: origin at the street end's west corner, u along that end, v along the house away from the
## street.
const RM_O := Vector2(-2631.6, -759.0)
const RM_A := Vector2(0.934, -0.356)
const RM_WALL := Color("#e6c2a2")      ## the warm peach plaster (photos)
const RM_PANEL := Color("#d9b292")     ## the blind windows' recesses
const RM_TRIM := Color("#efd9c3")      ## cornice, sills
const RM_BASE := Color("#b5a48f")      ## the granite plinth
const RM_ROOF := Color("#4d5257")      ## the dark sheet roofs


## One wall of the house from p to q (local metres), its outside on the left of p→q: panes every
## `step` metres on each sill height in `rows` (absolute), `w` by `h`. Puts the house's frame back.
func _rm_side(p: Vector2, q: Vector2, step: float, rows: Array, w: float, h: float) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var k := maxi(1, floori(n / step))
	var cols: Array = []
	for i in k:
		cols.append((float(i) + 0.5) * n / float(k))
	kit_panes(cols, rows, w, h, PAL_GLASS_DARK, 0.05)
	kit_front(RM_O, RM_O + RM_A)


func _build_rodziny_maryi(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(RM_O, RM_O + RM_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the two end wings: walls to 21, hipped roofs to 24
	for wing: Array in [[0.0, 13.0], [34.5, 49.4]]:
		var v0: float = wing[0]
		var v1: float = wing[1]
		var r := _lpoly([[0.05, v0], [13.55, v0], [13.55, v1], [0.05, v1]])
		_prism(r, g - 1.0, g + 6.4, RM_WALL, none, M_STONE)
		kit_ledge_ring(r, g + 6.0, 0.4, RM_TRIM, 0.2)
		kit_ledge_ring(r, g - 1.0, 1.6, RM_BASE, 0.06)
		_hip(6.8, (v0 + v1) * 0.5, 6.75, (v1 - v0) * 0.5, g + 6.4, 3.0, RM_ROOF)
	# --- the middle block: two storeys, walls to 24, a hipped roof to 26; the low annex west
	var mid := _lpoly([[-0.9, 12.95], [14.5, 12.95], [14.5, 34.55], [-0.9, 34.55]])
	_prism(mid, g - 1.0, g + 9.4, RM_WALL, none, M_STONE)
	kit_ledge_ring(mid, g + 9.0, 0.4, RM_TRIM, 0.2)
	kit_ledge_ring(mid, g - 1.0, 1.65, RM_BASE, 0.06)
	kit_ledge_ring(mid, g + 4.4, 0.25, RM_TRIM, 0.1)
	_hip(6.8, 23.75, 7.7, 10.8, g + 9.4, 2.0, RM_ROOF)
	_kbox(-4.0, -0.85, 18.7, 28.3, g - 1.0, g + 5.4, RM_WALL.darkened(0.04))
	# --- the street end: banded plaster, five tall blind windows, small attic windows over them
	kit_front(_w(13.55, 0.0), _w(0.05, 0.0))
	kit_face(0.0)
	kit_bands(0.0, 13.5, g + 0.6, g + 5.9, 0.55, RM_WALL)
	for k in 5:
		var bu := 1.55 + 2.6 * float(k)
		_kbox(bu - 0.7, bu + 0.7, -0.05, 0.04, g + 1.1, g + 4.4, RM_PANEL)
		_kbox(bu - 0.85, bu + 0.85, -0.05, 0.16, g + 0.95, g + 1.1, RM_TRIM)
	kit_panes([1.55, 4.15, 6.75, 9.35, 11.95], [g + 4.9], 0.8, 0.75, PAL_GLASS_DARK, 0.05)
	kit_front(RM_O, RM_O + RM_A)
	# --- panes on the other sides: the end wings' long sides and far end, the middle's two storeys
	_rm_side(Vector2(0.05, 0.0), Vector2(0.05, 13.0), 2.6, [g + 1.3], 1.2, 2.6)
	_rm_side(Vector2(13.55, 13.0), Vector2(13.55, 0.0), 2.6, [g + 1.3], 1.2, 2.6)
	_rm_side(Vector2(0.05, 34.5), Vector2(0.05, 49.4), 2.6, [g + 1.3], 1.2, 2.6)
	_rm_side(Vector2(13.55, 49.4), Vector2(13.55, 34.5), 2.6, [g + 1.3], 1.2, 2.6)
	_rm_side(Vector2(0.05, 49.4), Vector2(13.55, 49.4), 2.6, [g + 1.3], 1.2, 2.6)
	_rm_side(Vector2(-0.9, 28.3), Vector2(-0.9, 34.55), 2.6, [g + 1.2, g + 5.2], 1.2, 2.4)
	_rm_side(Vector2(-0.9, 12.95), Vector2(-0.9, 18.7), 2.6, [g + 1.2, g + 5.2], 1.2, 2.4)
	_rm_side(Vector2(-0.9, 18.7), Vector2(-0.9, 28.3), 2.6, [g + 5.8], 1.2, 2.2)
	_rm_side(Vector2(14.5, 34.55), Vector2(14.5, 12.95), 2.7, [g + 1.2, g + 5.2], 1.2, 2.4)
	_rm_side(Vector2(-4.0, 18.7), Vector2(-4.0, 28.3), 3.2, [g + 1.2], 1.2, 2.4)
	_collide(outline)


## The Pallottine house on Skaryszewska 12 (Klasztor pallotynów), a 1930s modernist block in a
## beige textured render: flat roofs at four heights, white ribbon windows, the low west block
## with its terraces and planters under a setback top storey, and the east block whose upper floor
## oversails a recessed ground floor. A model that replaces the plain OpenStreetMap block (building
## 3045; no landmark until 2026-11-14). From a Mapillary photo of 2019 across Skaryszewska
## (refs/pallotyni, never shipped), the OSM outline and GUGiK's LoD2 (over the lowest ground: the
## west block 9.9, its setback storey 12.4, the east block 11.6 and its top 13.8).
## Spec docs/landmarks/specs/pallotyni.md.
## Frame: origin at the street front's west corner, u along Skaryszewska east, v into the block.
const PL_O := Vector2(1748.0, -1711.3)
const PL_A := Vector2(0.829, 0.560)
const PL_WALL := Color("#d8cba2")      ## the beige textured render (photo)
const PL_FRAME := Color("#f2f0ea")     ## the white window frames and copings
const PL_ROOF := Color("#8c8b86")      ## the flat roofs
const PL_DARK := Color("#6d6a62")      ## the recessed ground floor's shadow


## One wall from p to q (local metres), its outside on the left of p→q: a white frame band and a
## ribbon of panes from y0 to y1 (absolute), the panes `step` metres apart, from fraction t0 to t1
## of the wall. Puts the house's frame back.
func _pl_ribbon(p: Vector2, q: Vector2, y0: float, y1: float, t0 := 0.0, t1 := 1.0, step := 1.3) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var u0 := n * t0 + 0.3
	var u1 := n * t1 - 0.3
	if u1 - u0 > 1.0:
		_kbox(u0 - 0.12, u1 + 0.12, -0.02, 0.05, y0 - 0.12, y1 + 0.12, PL_FRAME)
		var k := maxi(1, floori((u1 - u0) / step))
		var cols: Array = []
		for i in k:
			cols.append(u0 + (float(i) + 0.5) * (u1 - u0) / float(k))
		kit_panes(cols, [y0], (u1 - u0) / float(k) - 0.12, y1 - y0, PAL_GLASS_DARK, 0.08)
	kit_front(PL_O, PL_O + PL_A)


func _build_pallotyni(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(PL_O, PL_O + PL_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the west block to 9.9 with a coping, its setback top storey to 12.4
	var west := _lpoly([[-7.51, 15.33], [0.0, 0.0], [21.3, 0.0], [21.3, 3.52], [29.52, 3.52], [29.52, 15.85],
			[12.7, 15.8], [12.66, 20.17], [15.71, 20.04], [15.62, 23.84], [-3.02, 23.76], [-6.13, 17.9]])
	_prism(west, g - 1.0, g + 9.9, PL_WALL, PL_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(west, g + 9.9, 0.25, PL_FRAME, 0.08)
	_lbox(13.0, 11.75, 8.0, 3.75, g + 9.9, g + 12.4, PL_WALL, M_STONE, PL_ROOF)
	# --- the east block: the upper floors to 11.6 over a ground floor set back 0.8 from the street,
	# its top storey to 13.8
	var east_up := _lpoly([[29.56, 0.0], [51.15, 0.0], [51.15, 6.23], [48.24, 6.39], [48.35, 15.49], [45.44, 15.64],
			[45.61, 24.1], [29.57, 23.95]])
	var east_low := _lpoly([[29.56, 0.8], [50.35, 0.8], [50.35, 6.23], [48.24, 6.39], [48.35, 15.49], [45.44, 15.64],
			[45.61, 24.1], [29.57, 23.95]])
	_prism(east_low, g - 1.0, g + 4.4, PL_WALL.darkened(0.06), none, M_STONE)
	_prism(east_up, g + 4.4, g + 11.6, PL_WALL, PL_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(east_up, g + 11.6, 0.25, PL_FRAME, 0.08)
	_lbox(38.925, 12.25, 9.275, 5.75, g + 11.6, g + 13.8, PL_WALL, M_STONE, PL_ROOF)
	# --- ribbon windows: the west block's low band and its setback storey, the east block's two
	# floors on the street; bands on the other sides
	_pl_ribbon(Vector2(21.3, 0.0), Vector2(0.0, 0.0), g + 2.4, g + 4.9, 0.0, 0.75)
	_pl_ribbon(Vector2(21.0, 8.0), Vector2(5.0, 8.0), g + 10.4, g + 11.8)
	_pl_ribbon(Vector2(51.15, 0.0), Vector2(29.56, 0.0), g + 5.6, g + 8.0, 0.1, 1.0)
	_pl_ribbon(Vector2(50.35, 0.8), Vector2(29.56, 0.8), g + 1.6, g + 3.6, 0.05, 0.75)
	_pl_ribbon(Vector2(29.52, 3.52), Vector2(21.3, 3.52), g + 2.4, g + 4.9)
	_pl_ribbon(Vector2(51.15, 6.23), Vector2(51.15, 0.0), g + 5.6, g + 8.0)
	_pl_ribbon(Vector2(48.35, 15.49), Vector2(48.24, 6.39), g + 5.6, g + 8.0)
	_pl_ribbon(Vector2(45.61, 24.1), Vector2(45.44, 15.64), g + 5.6, g + 8.0)
	_pl_ribbon(Vector2(29.57, 23.95), Vector2(45.61, 24.1), g + 2.0, g + 4.2)
	_pl_ribbon(Vector2(29.57, 23.95), Vector2(45.61, 24.1), g + 5.6, g + 8.0)
	_pl_ribbon(Vector2(-3.02, 23.76), Vector2(15.62, 23.84), g + 2.0, g + 4.2)
	_pl_ribbon(Vector2(-3.02, 23.76), Vector2(15.62, 23.84), g + 5.6, g + 7.8)
	_pl_ribbon(Vector2(-7.51, 15.33), Vector2(-6.13, 17.9), g + 2.0, g + 4.2)
	_pl_ribbon(Vector2(0.0, 0.0), Vector2(-7.51, 15.33), g + 2.0, g + 4.2)
	_pl_ribbon(Vector2(0.0, 0.0), Vector2(-7.51, 15.33), g + 5.6, g + 7.8)
	# the terrace's planters along the west block's street edge
	for k in 7:
		var pu := 6.5 + 2.2 * float(k)
		_kbox(pu - 0.6, pu + 0.6, 0.15, 0.7, g + 10.15, g + 10.55, PL_DARK)
		_kbox(pu - 0.45, pu + 0.45, 0.25, 0.6, g + 10.55, g + 11.2, Color("#5f7a45"))
	_collide(outline)


## St Anthony of Padua's church of the Franciscans (Kościół św. Antoniego Padewskiego, Senatorska
## 31; 1679-1682, front 1757, rebuilt after 1944): a white plastered Baroque church under steep
## orange-red tile roofs, hipped at the chancel and the transept ends, a slim slate-grey octagonal
## turret with a green copper double onion and lantern riding the ridge past the crossing, low
## aisles and sacristies under green lean-to roofs, the two-storey classicist front with a porch and
## a pediment with an oculus, the octagonal chapel north of it under a red tile roof and lantern,
## and the low arcaded cloister wings enclosing the cross square in front. A model that replaces the
## kit church. From 15 Commons photos (refs/churches/st_anthony_senatorska, reference only, never
## shipped), the OSM outline and GUGiK's LoD2 (over the ground: the nave's eaves 16 and ridge 22.5,
## the transept's ridge 20, the aisles 9.5, the chapel 9 with its roof to 12.8, the cloister
## wings 6). Spec docs/landmarks/specs/antoniego.md.
## Frame: origin by the nave's front, u along the church from the front (u = -2) to the chancel
## (u = 40.5), v to its north (the chapel's side).
const AN_O := Vector2(-1211.2, -978.4)
const AN_A := Vector2(0.7251, 0.6886)
const AN_WALL := Color("#f0ece2")      ## the white plaster (photos)
const AN_TRIM := Color("#e0d9ca")      ## cornices, pilasters, ledges
const AN_ROOF := Color("#c4603d")      ## the orange-red tiles
const AN_COPPER := Color("#5f8f7e")    ## the green copper onions and lean-to roofs
const AN_SLATE := Color("#4c5156")     ## the turret's slate-grey octagon
const AN_DOOR := Color("#3a2f28")      ## doors and the cloister's dark arches


## Panes along a wall from p to q (local metres), its outside on the left of p→q: a round-headed
## look (a pane and a narrower one on it) every `step` metres, sill at y (absolute), `w` by `h`.
## Puts the church's frame back.
func _an_side(p: Vector2, q: Vector2, step: float, y: float, w: float, h: float, t0 := 0.0, t1 := 1.0) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var u0 := n * t0
	var u1 := n * t1
	var k := maxi(1, floori((u1 - u0) / step))
	var cols: Array = []
	for i in k:
		cols.append(u0 + (float(i) + 0.5) * (u1 - u0) / float(k))
	kit_panes(cols, [y], w, h, PAL_GLASS_DARK, 0.05)
	kit_panes(cols, [y + h], w * 0.6, w * 0.3, PAL_GLASS_DARK, 0.05)
	kit_front(AN_O, AN_O + AN_A)


func _build_antoniego(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(AN_O, AN_O + AN_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the nave and chancel: walls to 16, the roof to 22.5, a gable on the front, hipped at the
	# chancel end
	var nave := _lpoly([[-2.0, -10.5], [40.5, -10.5], [40.5, 3.5], [-2.0, 3.5]])
	_prism(nave, g - 1.0, g + 16.0, AN_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 15.5, 0.5, AN_TRIM, 0.25)
	_gable(-2.0, 33.5, -3.5, 7.0, g + 16.0, 6.5, AN_ROOF, AN_ROOF, true)
	_hip(33.5, -3.5, 7.0, 6.8, g + 16.0, 6.2, AN_ROOF)  # a little inside the gable's slopes
	# --- the transept across it: walls to 16, a hipped roof to 20
	_prism(_rect(23.0, -14.1, 3.5, 3.6), g - 1.0, g + 16.0, AN_WALL, none, M_STONE)
	_prism(_rect(23.0, 5.4, 3.5, 1.9), g - 1.0, g + 16.0, AN_WALL, none, M_STONE)
	_hip(23.0, -5.2, 3.5, 12.5, g + 16.0, 4.0, AN_ROOF)
	# --- the low aisles and sacristies under green lean-to roofs
	_lbox(9.25, -11.7, 10.25, 1.2, g - 1.0, g + 7.6, AN_WALL)
	_dk_lean(-1.0, 19.5, -12.9, -10.5, g + 7.6, g + 9.6, AN_WALL, AN_COPPER)
	_lbox(10.1, 4.5, 9.4, 1.0, g - 1.0, g + 7.6, AN_WALL)
	_dk_lean(0.7, 19.5, 5.5, 3.5, g + 7.6, g + 9.4, AN_WALL, AN_COPPER)
	_lbox(33.5, -14.4, 7.0, 3.9, g - 1.0, g + 6.0, AN_WALL)
	_dk_lean(26.5, 40.5, -18.3, -10.5, g + 6.0, g + 8.2, AN_WALL, AN_COPPER)
	_lbox(34.1, 5.5, 7.6, 2.0, g - 1.0, g + 6.4, AN_WALL)
	_dk_lean(26.5, 41.7, 7.5, 3.5, g + 6.4, g + 8.0, AN_WALL, AN_COPPER)
	# --- the turret on the ridge: a slate octagon, a green onion, the lantern and a second onion
	var tc := _w(28.5, -3.5)
	_prism(_circle(tc, 1.55, 8), g + 20.0, g + 26.2, AN_SLATE, none, M_STONE)
	kit_ledge_ring(_circle(tc, 1.55, 8), g + 26.0, 0.25, AN_SLATE.lightened(0.1), 0.12)
	_frustum(_circle(tc, 1.6, 8), g + 26.25, _circle(tc, 2.0, 8), g + 27.1, AN_COPPER)
	_frustum(_circle(tc, 2.0, 8), g + 27.1, _circle(tc, 1.1, 8), g + 28.3, AN_COPPER)
	_frustum(_circle(tc, 1.1, 8), g + 28.3, _circle(tc, 0.55, 8), g + 28.9, AN_COPPER)
	_prism(_circle(tc, 0.6, 8), g + 28.9, g + 30.5, AN_DOOR, none, M_STONE)
	_frustum(_circle(tc, 0.7, 8), g + 30.5, _circle(tc, 0.95, 8), g + 31.1, AN_COPPER)
	_frustum(_circle(tc, 0.95, 8), g + 31.1, _circle(tc, 0.12, 8), g + 32.4, AN_COPPER)
	_kap_cross(28.5, -3.5, g + 32.4, 1.8)
	for k in 4:  # the quatrefoil openings on the slate octagon
		var ang := TAU * (float(k) * 2.0 + 1.0) / 8.0
		var d := Vector2.from_angle(ang)
		var c3 := Vector3(tc.x + d.x * 1.48, g + 24.6, tc.y + d.y * 1.48)
		_disc(c3, Vector3(d.x, 0.0, d.y), 0.45, 6, AN_DOOR)
	# --- the front: two storeys, pilasters, a porch with a balustrade, a tall arched window, the
	# pediment with its oculus and cross
	kit_front(_w(-2.0, -12.9), _w(-2.0, 6.1))
	kit_face(0.0)
	kit_ledge(0.0, 19.0, g + 9.6, 0.6, AN_TRIM, 0.2)
	for pu: float in [2.6, 5.6, 13.2, 16.2]:
		kit_pilaster(pu, g, g + 9.6, AN_TRIM, 0.8, 0.15)
	for pu: float in [4.0, 14.8]:
		kit_pilaster(pu, g + 10.2, g + 15.5, AN_TRIM, 0.8, 0.15)
	kit_panes([9.4], [g + 10.6], 1.8, 3.4, PAL_GLASS_DARK, 0.05)
	kit_panes([9.4], [g + 14.0], 1.1, 0.6, PAL_GLASS_DARK, 0.05)
	kit_pediment(9.4, 7.3, g + 16.0, 6.1, AN_WALL, AN_ROOF, 0.35)
	var oc := _w(9.4, 0.4)
	_disc(Vector3(oc.x, g + 18.6, oc.y), Vector3(_b.x, 0.0, _b.y), 0.9, 8, PAL_GLASS_DARK)
	_kbox(5.9, 12.9, 0.0, 3.4, g - 0.5, g + 6.6, AN_WALL)
	_kbox(5.7, 13.1, -0.05, 3.6, g + 6.6, g + 7.0, AN_TRIM)
	kit_face(3.4)
	kit_door(9.4, g, 5.0, 1.5, AN_TRIM, AN_DOOR, true)
	kit_attic(5.9, 12.9, g + 7.0, AN_TRIM, 0.9)
	kit_face(0.0)
	kit_column(6.3, 3.8, g, g + 6.6, AN_TRIM, 0.3)
	kit_column(12.5, 3.8, g, g + 6.6, AN_TRIM, 0.3)
	kit_front(AN_O, AN_O + AN_A)
	_kap_cross(-2.2, -3.5, g + 22.3, 2.0)
	# --- windows: the nave's tall round-headed ones over the aisles, the chancel's, the transept
	# ends' big ones, small oval-ish ones at the chancel end
	_an_side(Vector2(0.7, 3.5), Vector2(19.5, 3.5), 4.7, g + 10.6, 1.4, 3.4)
	_an_side(Vector2(19.5, -10.5), Vector2(-1.0, -10.5), 5.0, g + 10.6, 1.4, 3.4)
	_an_side(Vector2(26.5, 3.5), Vector2(40.5, 3.5), 4.7, g + 9.6, 1.4, 4.0)
	_an_side(Vector2(40.5, -10.5), Vector2(26.5, -10.5), 4.7, g + 9.6, 1.4, 4.0)
	_an_side(Vector2(26.5, -17.7), Vector2(19.5, -17.7), 7.0, g + 7.0, 2.0, 5.2)
	_an_side(Vector2(19.5, 7.3), Vector2(26.5, 7.3), 7.0, g + 7.0, 2.0, 5.2)
	_an_side(Vector2(40.5, 3.5), Vector2(40.5, -10.5), 4.6, g + 11.0, 0.9, 0.9)
	_an_side(Vector2(40.5, -10.5), Vector2(40.5, -18.3), 3.9, g + 1.8, 1.0, 2.2)
	_an_side(Vector2(41.7, 7.5), Vector2(41.7, 3.5), 4.0, g + 1.8, 1.0, 2.2)
	_an_side(Vector2(40.5, -18.3), Vector2(26.5, -18.3), 3.5, g + 1.8, 1.0, 2.2)
	_an_side(Vector2(26.5, 7.5), Vector2(41.7, 7.5), 3.8, g + 1.8, 1.0, 2.2)
	_an_side(Vector2(19.5, -12.9), Vector2(-1.0, -12.9), 4.1, g + 2.0, 1.0, 2.6)
	# --- the link wing north of the front and the octagonal chapel at its end
	_lbox(4.75, 12.25, 4.25, 6.75, g - 1.0, g + 7.0, AN_WALL)
	_hip(4.75, 12.25, 4.25, 6.75, g + 7.0, 1.8, AN_ROOF)
	_an_side(Vector2(9.0, 19.0), Vector2(9.0, 5.5), 3.4, g + 2.0, 1.0, 2.4)
	_an_side(Vector2(0.5, 5.5), Vector2(0.5, 19.0), 3.4, g + 2.0, 1.0, 2.4)
	var ch := _circle(_w(4.3, 24.3), 5.8, 8)
	_prism(ch, g - 1.0, g + 9.0, AN_WALL, none, M_STONE)
	kit_ledge_ring(ch, g + 8.6, 0.4, AN_TRIM, 0.2)
	_pyramid(_ring_out(ch, 0.25), g + 9.0, g + 12.8, AN_ROOF)
	var cc := _w(4.3, 24.3)
	_prism(_circle(cc, 0.7, 8), g + 11.6, g + 13.6, AN_WALL, none, M_STONE)
	_frustum(_circle(cc, 0.85, 8), g + 13.6, _circle(cc, 0.1, 8), g + 15.0, AN_DOOR)
	for k in 8:
		if k == 6:
			continue
		var a := ch[(k + 1) % 8]
		var b := ch[k]
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 3.4], 1.0, 2.4, PAL_GLASS_DARK, 0.05)
	kit_front(AN_O, AN_O + AN_A)
	# --- the cloister wings round the cross square in front, and their end pavilions on the street
	_lbox(-11.9, 16.75, 12.4, 2.05, g - 1.0, g + 5.0, AN_WALL)
	_hip(-11.9, 16.75, 12.4, 2.05, g + 5.0, 1.3, AN_ROOF)
	_lbox(-1.7, -17.45, 1.2, 4.55, g - 1.0, g + 6.0, AN_WALL)  # the gate wall south of the front
	_hip(-1.7, -17.45, 1.2, 4.55, g + 6.0, 0.9, AN_ROOF)
	_lbox(-13.5, -23.75, 10.5, 1.75, g - 1.0, g + 5.0, AN_WALL)
	_hip(-13.5, -23.75, 10.5, 1.75, g + 5.0, 1.3, AN_ROOF)
	for pv: float in [16.75, -24.4]:
		_lbox(-27.15, pv, 3.1, 2.9, g - 1.0, g + 6.0, AN_WALL)
		_hip(-27.15, pv, 3.1, 2.9, g + 6.0, 2.2, AN_ROOF)
	for wing: Array in [[Vector2(-0.5, 14.7), Vector2(-24.3, 14.7)], [Vector2(-24.0, -22.0), Vector2(-3.0, -22.0)]]:
		var p0: Vector2 = wing[0]
		var p1: Vector2 = wing[1]
		kit_front(AN_O, AN_O + AN_A)
		var ln := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var k := floori(ln / 3.2)
		for i in k:  # the cloister's dark open arches on the square
			var au := (float(i) + 0.5) * ln / float(k)
			_wall(_w(au - 0.95, 0.04), _w(au + 0.95, 0.04), g + 0.1, g + 3.4, _b, AN_DOOR)
	kit_front(AN_O, AN_O + AN_A)
	_collide(outline)


## The church of Sts Peter and Paul (Kościół Świętych Apostołów Piotra i Pawła na Koszykach,
## Nowogrodzka 51 at Emilii Plater; Józef Pius Dziekoński, 1886-1890s, rebuilt after 1944): a sand
## stucco neo-Renaissance basilica, its tall flat front with three deep arched porches, a rose
## window under a gable and two slim corner towers with arched belfries and small domes; over the
## crossing a tall drum with arched windows and a green copper dome and lantern; a low transept
## with pedimented ends, low wings either side of a rounded apse. A model that replaces the kit
## church (whose front was on the wrong end). From 14 Commons photos
## (refs/churches/sts_peter_paul_nowogrodzka, reference only, never shipped), the OSM outline
## (building 79) and GUGiK's LoD2 (over the ground: the nave's eaves 17.5 and ridge 23.5, the
## towers 30.5, the drum 28.5, the dome 42.5 and its lantern 48.5, the apse 22, the wings 11).
## Spec docs/landmarks/specs/piotr_pawel.md.
## Frame: origin at the outline's centre, u from the apse (u = -33) to the front (u = 24.5), v to
## the left of that.
const SPP_O := Vector2(-1128.8, 830.2)
const SPP_A := Vector2(-0.9412, 0.3379)
const SPP_WALL := Color("#e2d8c2")      ## the pale cool stucco (3D Tiles rework 2026-11-26)
const SPP_TRIM := Color("#ece5d4")      ## pilasters, cornices, ledges: cream stone
const SPP_ROOF := Color("#86a898")      ## the patina-green copper roofs (paler than the dome)
const SPP_COPPER := Color("#6f9e8c")    ## the green copper dome and caps
const SPP_DARK := Color("#3b3732")      ## doors, porch recesses, belfry openings


## A gabled roof whose ridge runs along v (the transept arms): eaves at u0 and u1 (y), the ridge
## `rise` above them at the middle, from v0 to v1. The end triangles are the pediments' (kit).
func _pp_ridge_roof(u0: float, u1: float, v0: float, v1: float, y: float, rise: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var um := (u0 + u1) * 0.5
	var at := func(u: float, v: float, yy: float) -> Vector3:
		var q := _w(u, v)
		return Vector3(q.x, yy, q.y)
	for e: float in [u0, u1]:
		var sg := signf(e - um)
		var n := (Vector3(_a.x, 0.0, _a.y) * sg * rise + Vector3.UP * absf(e - um)).normalized()
		_quad(at.call(e, v0, y), at.call(e, v1, y), at.call(um, v1, y + rise), at.call(um, v0, y + rise), n, col)
	_mode = keep


## Panes along a wall from p to q (local metres), its outside on the left of p→q: one every
## `step` metres, sill at y (absolute), `w` by `h`, with a narrower pane on top for a round
## head. Puts the church's frame back.
func _pp_side(p: Vector2, q: Vector2, step: float, y: float, w: float, h: float) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var k := maxi(1, floori(n / step))
	var cols: Array = []
	for i in k:
		cols.append((float(i) + 0.5) * n / float(k))
	kit_panes(cols, [y], w, h, PAL_GLASS_DARK, 0.05)
	if h > w * 1.5:
		kit_panes(cols, [y + h], w * 0.6, w * 0.3, PAL_GLASS_DARK, 0.05)
	kit_front(SPP_O, SPP_O + SPP_A)


func _build_piotr_pawel(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(SPP_O, SPP_O + SPP_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the nave with its aisles under one low roof: walls to 17.5, the ridge 23.5
	var nave := _lpoly([[-4.5, -11.3], [24.5, -11.3], [24.5, 11.3], [-4.5, 11.3]])
	_prism(nave, g - 1.0, g + 17.5, SPP_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 17.0, 0.5, SPP_TRIM, 0.25)
	kit_ledge_ring(nave, g - 1.0, 1.6, SPP_TRIM.darkened(0.12), 0.08)
	_gable(24.5, -4.5, 0.0, 11.3, g + 17.5, 6.0, SPP_WALL, SPP_ROOF, true)
	# --- the crossing and the transept: flat-topped to 18.5, pediments on the arms' ends
	_lbox(-11.5, 0.0, 7.5, 11.3, g - 1.0, g + 18.5, SPP_WALL, M_STONE, SPP_ROOF)
	for s: float in [-1.0, 1.0]:
		_prism(_rect(-11.0, s * 13.15, 4.0, 2.15), g - 1.0, g + 18.5, SPP_WALL, none, M_STONE)
	# each arm's gable roof along its own axis: eaves 18.5, ridge 22 (3D Tiles rework)
	_pp_ridge_roof(-15.0, -7.0, -15.3, 15.3, g + 18.5, 3.5, SPP_ROOF)
	var cross := _lpoly([[-19.0, -11.3], [-15.0, -11.3], [-15.0, -15.3], [-7.0, -15.3], [-7.0, -11.3], [-4.0, -11.3],
			[-4.0, 11.3], [-7.0, 11.3], [-7.0, 15.3], [-15.0, 15.3], [-15.0, 11.3], [-19.0, 11.3]])
	kit_ledge_ring(cross, g + 17.9, 0.5, SPP_TRIM, 0.2)
	for e: Array in [[Vector2(-7.0, -15.3), Vector2(-15.0, -15.3)], [Vector2(-15.0, 15.3), Vector2(-7.0, 15.3)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(SPP_O, SPP_O + SPP_A)
		kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		kit_pediment(4.0, 4.4, g + 18.5, 3.5, SPP_WALL, SPP_ROOF, 0.4)
		kit_panes([4.0], [g + 5.0], 2.0, 6.0, PAL_GLASS_DARK, 0.05)
		kit_panes([4.0], [g + 11.0], 1.2, 0.6, PAL_GLASS_DARK, 0.05)
	kit_front(SPP_O, SPP_O + SPP_A)
	# --- the low wings beside the apse and the rounded apse with its roof
	for s: float in [-1.0, 1.0]:
		_prism(_rect(-22.9, s * 10.1, 4.1, 4.9), g - 1.0, g + 11.0, SPP_WALL, none, M_STONE)
		_hip(-22.9, s * 10.1, 4.1, 4.9, g + 11.0, 2.5, SPP_ROOF)  # green hip rising to 13.5
	var apse: Array = [[-19.0, -5.5]]
	for k in 7:
		var ang := -PI * 0.5 - PI * float(k) / 6.0
		apse.append([-27.5 + 5.5 * cos(ang), 5.5 * sin(ang)])
	apse.append([-19.0, 5.5])
	var ap := _lpoly(apse)
	_prism(ap, g - 1.0, g + 18.0, SPP_WALL, none, M_STONE)
	kit_ledge_ring(ap, g + 17.6, 0.4, SPP_TRIM, 0.2)
	_pyramid(ap, g + 18.0, g + 22.5, SPP_ROOF)
	# --- the drum: 16 sides to 28.5 with arched windows, the dome to 42.5, the lantern and cross
	var dc := _w(-11.5, 0.0)
	var drum := _circle(dc, 7.0, 16)
	_prism(drum, g + 18.5, g + 28.5, SPP_WALL, none, M_STONE)
	kit_ledge_ring(drum, g + 28.0, 0.5, SPP_TRIM, 0.3)
	for k in 8:
		var a := drum[(2 * k + 1) % 16]
		var b := drum[2 * k]
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 21.0], 1.2, 4.0, PAL_GLASS_DARK, 0.05)
		kit_panes([ln * 0.5], [g + 25.0], 0.7, 0.4, PAL_GLASS_DARK, 0.05)
	kit_front(SPP_O, SPP_O + SPP_A)
	# the balustrade ring: plinth and rail slabs with a pier on every drum corner, 1.3 m
	kit_ledge_ring(drum, g + 28.5, 0.2, SPP_TRIM, 0.3)
	kit_ledge_ring(drum, g + 29.5, 0.2, SPP_TRIM, 0.3)
	for pv: Vector2 in drum:
		_prism(_square(pv, 0.2), g + 28.5, g + 29.8, SPP_TRIM, SPP_TRIM, M_STONE)
	_frustum(_circle(dc, 7.1, 16), g + 28.5, _circle(dc, 7.0, 16), g + 31.0, SPP_COPPER)  # near-vertical foot: a broad cap
	_frustum(_circle(dc, 7.0, 16), g + 31.0, _circle(dc, 6.4, 16), g + 33.0, SPP_COPPER)
	_frustum(_circle(dc, 6.4, 16), g + 33.0, _circle(dc, 4.9, 16), g + 37.2, SPP_COPPER)
	_frustum(_circle(dc, 4.9, 16), g + 37.2, _circle(dc, 2.7, 16), g + 40.6, SPP_COPPER)
	_frustum(_circle(dc, 2.7, 16), g + 40.6, _circle(dc, 1.0, 16), g + 42.4, SPP_COPPER)
	_prism(_circle(dc, 0.95, 8), g + 42.4, g + 45.4, SPP_TRIM, none, M_STONE)
	_frustum(_circle(dc, 1.1, 8), g + 45.4, _circle(dc, 0.1, 8), g + 47.2, SPP_COPPER)
	_kap_cross(-11.5, 0.0, g + 47.2, 1.8)
	# --- the two corner towers: square shafts to 23.5, arched belfries to 28, small domes
	for s: float in [-1.0, 1.0]:
		var tv := s * 9.9
		_lbox(23.0, tv, 1.65, 1.6, g - 1.0, g + 23.5, SPP_WALL)
		kit_ledge_ring(_rect(23.0, tv, 1.65, 1.6), g + 23.2, 0.3, SPP_TRIM, 0.15)
		var tc := _w(23.0, tv)
		var bel := _circle(tc, 1.45, 8)
		_prism(bel, g + 23.5, g + 27.8, SPP_WALL, none, M_STONE)
		kit_ledge_ring(bel, g + 27.5, 0.3, SPP_TRIM, 0.15)
		for k in 4:
			var a := bel[(2 * k + 1) % 8]
			var b := bel[2 * k]
			var ln := kit_front(a, b)
			kit_panes([ln * 0.5], [g + 24.2], 0.6, 2.6, SPP_DARK, 0.05)
		kit_front(SPP_O, SPP_O + SPP_A)
		_frustum(_circle(tc, 1.5, 8), g + 27.8, _circle(tc, 0.15, 8), g + 29.8, SPP_COPPER)
		_kap_cross(23.0, tv, g + 29.8, 1.2)
	# --- the front: pilasters, three deep arched porches, niches, the rose window, the gable
	kit_front(_w(24.5, 11.3), _w(24.5, -11.3))
	kit_face(0.0)
	kit_ledge(0.0, 22.6, g + 9.0, 0.5, SPP_TRIM, 0.2)
	for pu: float in [3.6, 8.4, 14.2, 19.0]:
		kit_pilaster(pu, g, g + 17.0, SPP_TRIM, 0.9, 0.18)
	kit_door(11.3, g, 8.2, 2.1, SPP_TRIM, SPP_DARK, true)
	kit_door(6.0, g, 6.6, 1.4, SPP_TRIM, SPP_DARK, true)
	kit_door(16.6, g, 6.6, 1.4, SPP_TRIM, SPP_DARK, true)
	kit_panes([6.0, 16.6], [g + 10.8], 0.9, 2.2, SPP_DARK, 0.05)
	kit_panes([6.0, 16.6], [g + 14.4], 0.8, 0.8, PAL_GLASS_DARK, 0.05)
	var rc := _w(11.3, 0.06)
	_disc(Vector3(rc.x, g + 13.6, rc.y), Vector3(_b.x, 0.0, _b.y), 1.7, 12, PAL_GLASS_DARK)
	kit_pediment(11.3, 6.2, g + 17.5, 4.4, SPP_WALL, SPP_ROOF, 0.35)
	_kbox(4.0, 18.6, 0.0, 2.6, g - 1.0, g + 0.15, SPP_TRIM.darkened(0.12))  # the steps
	kit_front(SPP_O, SPP_O + SPP_A)
	_kap_cross(24.7, 0.0, g + 21.9, 1.8)
	# --- windows on the nave's sides (tall round-headed below, round ones high), the wings, apse
	_pp_side(Vector2(21.3, -11.3), Vector2(-4.0, -11.3), 4.2, g + 3.0, 1.4, 5.2)
	_pp_side(Vector2(-4.0, 11.3), Vector2(21.3, 11.3), 4.2, g + 3.0, 1.4, 5.2)
	_pp_side(Vector2(21.3, -11.3), Vector2(-4.0, -11.3), 4.2, g + 12.2, 1.1, 1.1)
	_pp_side(Vector2(-4.0, 11.3), Vector2(21.3, 11.3), 4.2, g + 12.2, 1.1, 1.1)
	_pp_side(Vector2(-19.0, -15.0), Vector2(-27.0, -15.0), 2.7, g + 3.0, 1.1, 3.4)
	_pp_side(Vector2(-27.0, 15.0), Vector2(-19.0, 15.0), 2.7, g + 3.0, 1.1, 3.4)
	for k in 6:
		var a := ap[k + 1]
		var b := ap[k + 2]
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 8.0], 1.0, 4.4, PAL_GLASS_DARK, 0.05)
	kit_front(SPP_O, SPP_O + SPP_A)
	_collide(outline)


## The co-cathedral of Our Lady of Victory (Konkatedra Matki Bożej Zwycięskiej, Grochowska 365,
## Kamionek; 1929-1938, plastered after the war): a cream-white modernist church, its tall flat front
## block with pale yellow strips, a big round window in a yellow frame under a coat of arms and three
## doors, lower flat-topped wings either side with slit windows; the nave under a low red tile roof
## between lower aisles, a tall round apse with long slit windows at the east end, a small domed
## chapel by the front and low annexes. A model that replaces the kit church (two brick spires it
## never had). From 16 Commons photos (refs/churches/our_lady_of_victory_grochowska, reference only,
## never shipped), the OSM outline (building 82) and GUGiK's LoD2 (over the ground: the nave's
## eaves 22 and ridge 25, the aisles 15 to 17, the apse 27, the chapel 9.3, the south annex 8.4).
## The wooden bell tower in the old graveyard is not part of the outline and is left out.
## Spec docs/landmarks/specs/zwycieska.md.
## Frame: origin at the outline's centre, u from the front (u = -15.2) to the apse (u = 40.8), v
## to its left (north-east).
const ZW_O := Vector2(1970.9, -1373.1)
const ZW_A := Vector2(0.0905, -0.9959)
const ZW_WALL := Color("#ece6d4")      ## the cream-white plaster (photos)
const ZW_STRIP := Color("#e4cd84")     ## the pale yellow strips, frames and arches
const ZW_ROOF := Color("#b65a3c")      ## the red tiles
const ZW_FLAT := Color("#8f8b84")      ## the flat roofs
const ZW_DOME := Color("#8b6b58")      ## the chapel's brown copper dome
const ZW_DOOR := Color("#5b3326")      ## the wooden doors


## Panes along a wall from p to q (local metres), its outside on the left of p→q: one every
## `step` metres, sill at y (absolute), `w` by `h`. Puts the church's frame back.
func _zw_side(p: Vector2, q: Vector2, step: float, y: float, w: float, h: float) -> void:
	var n := kit_front(_w(p.x, p.y), _w(q.x, q.y))
	var k := maxi(1, floori(n / step))
	var cols: Array = []
	for i in k:
		cols.append((float(i) + 0.5) * n / float(k))
	kit_panes(cols, [y], w, h, PAL_GLASS_DARK, 0.05)
	kit_front(ZW_O, ZW_O + ZW_A)


func _build_zwycieska(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(ZW_O, ZW_O + ZW_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the front block to 26 and its wings to 13, flat-topped
	_lbox(-9.1, -4.0, 6.1, 6.0, g - 1.0, g + 26.0, ZW_WALL, M_STONE, ZW_FLAT)
	kit_ledge_ring(_rect(-9.1, -4.0, 6.1, 6.0), g + 25.7, 0.3, ZW_WALL.darkened(0.04), 0.12)
	_lbox(-9.1, 7.25, 6.1, 5.45, g - 1.0, g + 13.0, ZW_WALL, M_STONE, ZW_FLAT)
	_lbox(-9.1, -13.9, 6.1, 4.1, g - 1.0, g + 13.0, ZW_WALL, M_STONE, ZW_FLAT)
	# --- the nave: walls to 22, a low red roof to 25; the aisles to 15 under lean-tos to 17
	var nave := _lpoly([[-3.2, -10.0], [34.0, -10.0], [34.0, 2.0], [-3.2, 2.0]])
	_prism(nave, g - 1.0, g + 22.0, ZW_WALL, none, M_STONE)
	kit_ledge_ring(nave, g + 21.7, 0.3, ZW_WALL.darkened(0.04), 0.15)
	_gable(34.0, -3.2, -4.0, 6.0, g + 22.0, 3.0, ZW_WALL, ZW_ROOF, false)
	_lbox(15.4, -12.9, 18.6, 3.1, g - 1.0, g + 15.0, ZW_WALL)
	_dk_lean(-3.2, 34.0, -16.0, -10.0, g + 15.0, g + 17.0, ZW_WALL, ZW_ROOF)
	_lbox(19.0, 4.9, 15.0, 3.1, g - 1.0, g + 15.0, ZW_WALL)
	_dk_lean(4.0, 34.0, 8.0, 2.0, g + 15.0, g + 17.0, ZW_WALL, ZW_ROOF)
	# --- the east end: the tall round apse to 27 and the blocks either side of it
	var ac := _w(35.3, -4.0)
	var apse := _circle(ac, 5.5, 16)
	_prism(apse, g - 1.0, g + 27.0, ZW_WALL, none, M_STONE)
	kit_ledge_ring(apse, g + 26.7, 0.3, ZW_WALL.darkened(0.04), 0.15)
	_pyramid(apse, g + 27.0, g + 28.2, ZW_FLAT)
	_kap_cross(35.3, -4.0, g + 28.2, 1.4)
	for k in 8:  # the long slit windows round it, east half
		var a := apse[(2 * k + 1) % 16]
		var b := apse[2 * k]
		if _local((a + b) * 0.5).x < 35.5:
			continue
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 6.0], 0.6, 16.0, PAL_GLASS_DARK, 0.05)
	kit_front(ZW_O, ZW_O + ZW_A)
	_lbox(36.5, 6.0, 3.5, 3.4, g - 1.0, g + 20.0, ZW_WALL, M_STONE, ZW_FLAT)
	_lbox(36.5, -13.0, 3.5, 3.0, g - 1.0, g + 20.0, ZW_WALL, M_STONE, ZW_FLAT)
	# --- the low annex on the south with its yellow arches, and the domed chapel by the front
	_lbox(9.0, -20.75, 7.0, 3.75, g - 1.0, g + 8.4, ZW_WALL, M_STONE, ZW_FLAT)
	kit_front(_w(16.0, -24.5), _w(2.0, -24.5))
	for k in 4:
		var au := 1.75 + 3.5 * float(k)
		kit_door(au, g, 4.2, 1.1, ZW_STRIP, PAL_GLASS_DARK, true)
	kit_front(ZW_O, ZW_O + ZW_A)
	var cc := _w(0.5, 6.3)
	var chap := _circle(cc, 3.6, 8)
	_prism(chap, g - 1.0, g + 6.6, ZW_WALL, none, M_STONE)
	kit_ledge_ring(chap, g + 6.3, 0.3, ZW_STRIP, 0.12)
	_frustum(_circle(cc, 3.7, 8), g + 6.6, _circle(cc, 2.6, 8), g + 8.4, ZW_DOME)
	_frustum(_circle(cc, 2.6, 8), g + 8.4, _circle(cc, 0.4, 8), g + 9.3, ZW_DOME)
	_kap_cross(0.5, 6.3, g + 9.3, 1.0)
	# --- the front: yellow strips, the round window in its frame, the arms, three doors, a cross
	kit_front(_w(-15.2, -18.0), _w(-15.2, 12.7))
	kit_face(0.0)
	for pu: float in [8.25, 11.0, 17.0, 19.75]:
		kit_pilaster(pu, g + 0.2, g + 25.6, ZW_STRIP, 0.45, 0.06)
	var rc := _w(14.0, 0.1)
	var nrm := Vector3(_b.x, 0.0, _b.y)
	_disc(Vector3(rc.x, g + 14.0, rc.y), nrm, 2.9, 12, ZW_STRIP)
	var rc2 := _w(14.0, 0.16)
	_disc(Vector3(rc2.x, g + 14.0, rc2.y), nrm, 2.4, 12, PAL_GLASS_DARK)
	_kbox(13.3, 14.7, -0.02, 0.18, g + 19.6, g + 22.0, ZW_STRIP)  # the coat of arms
	_kbox(10.9, 17.1, -0.02, 0.14, g + 3.6, g + 4.0, ZW_STRIP)
	for du: float in [12.3, 14.0, 15.7]:
		kit_door(du, g, 3.4, 0.75 if du != 14.0 else 0.85, ZW_STRIP, ZW_DOOR)
	_kbox(9.5, 18.5, 0.0, 3.0, g - 1.0, g + 0.2, ZW_FLAT.lightened(0.15))  # the steps
	kit_panes([3.8, 24.4], [g + 3.5], 0.5, 7.5, PAL_GLASS_DARK, 0.05)
	kit_front(ZW_O, ZW_O + ZW_A)
	_kap_cross(-14.6, -4.0, g + 26.0, 2.6)
	# --- windows: the nave's over the aisles, the aisles', the wings', the front block's sides
	_zw_side(Vector2(-3.0, 2.0), Vector2(34.0, 2.0), 4.1, g + 17.6, 1.4, 3.6)
	_zw_side(Vector2(34.0, -10.0), Vector2(-3.0, -10.0), 4.1, g + 17.6, 1.4, 3.6)
	_zw_side(Vector2(4.0, 8.0), Vector2(33.0, 8.0), 4.1, g + 3.0, 1.2, 8.0)
	_zw_side(Vector2(33.0, -16.0), Vector2(-3.0, -16.0), 4.0, g + 3.0, 1.2, 8.0)
	_zw_side(Vector2(-15.2, 12.7), Vector2(-3.0, 12.7), 6.0, g + 4.0, 0.5, 6.0)
	_zw_side(Vector2(-3.0, -18.0), Vector2(-15.2, -18.0), 6.0, g + 4.0, 0.5, 6.0)
	_collide(outline)


## The Pallottines' church of Christ the King of Peace (Kościół Chrystusa Króla Pokoju,
## Skaryszewska 12, Praga; parish of St Vincent Pallotti) with the Our Lady of Częstochowa chapel
## in front of it: the small cream chapel with white quoins, a big dark cross and a door under its
## gable on the street; a slim white bell tower with an arched lantern at its left corner and a
## little white turret on its ridge; behind it the square church under a big brown metal pyramid
## roof with an octagonal arched lantern, a dome and two crosses; low flat-roofed parish wings
## round it. A model that replaces the plain OpenStreetMap block (building 3051, "Kaplica pw.
## Matki Boskiej Częstochowskiej"; no landmark until 2026-11-14). From 7 Commons photos
## (refs/churches/pallottines_skaryszewska, reference only, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the wings 9.5, the church's eaves 14.5 and its roof 20.5 with
## the lantern to 23, the chapel's eaves 9.6 and ridge 12.4). Spec docs/landmarks/specs/chrystusa_krola.md.
## Frame: origin at the outline's centre, u from the street (Skaryszewska, u = -16.8) into the
## block, v to its left.
const CK_O := Vector2(1725.1, -1677.5)
const CK_A := Vector2(0.607, 0.795)
const CK_CREAM := Color("#eedfb4")     ## the chapel's cream plaster (photos)
const CK_WHITE := Color("#f3f0e8")     ## quoins, the tower, the turret
const CK_WING := Color("#e6dcc4")      ## the parish wings
const CK_ROOF := Color("#7c6a4b")      ## the church's brown metal roof
const CK_TILE := Color("#8a8a84")      ## the chapel's and wings' grey roofs
const CK_DARK := Color("#3f3c38")      ## the lantern, the cross, the door


func _build_chrystusa_krola(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(CK_O, CK_O + CK_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the low parish wings round the church: the whole outline to 9.5, flat
	_prism(outline, g - 1.0, g + 9.5, CK_WING, CK_TILE, M_STONE, M_STONE)
	kit_ledge_ring(outline, g + 9.3, 0.2, CK_WHITE, 0.08)
	# --- the church: a square to 14.5 under a brown pyramid to 20.5, a band of windows round it
	var ch := _rect(3.5, 0.5, 9.0, 9.0)
	_prism(ch, g + 9.0, g + 14.5, CK_WING, none, M_STONE)
	_hip(3.5, 0.5, 9.0, 9.0, g + 14.5, 6.0, CK_ROOF)
	for e: Array in [[Vector2(-5.5, -8.5), Vector2(-5.5, 9.5)], [Vector2(12.5, -8.5), Vector2(-5.5, -8.5)],
			[Vector2(12.5, 9.5), Vector2(12.5, -8.5)], [Vector2(-5.5, 9.5), Vector2(12.5, 9.5)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(CK_O, CK_O + CK_A)
		kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		kit_panes([2.25, 6.75, 11.25, 15.75], [g + 10.4], 3.6, 3.0, PAL_GLASS_DARK, 0.05)
	kit_front(CK_O, CK_O + CK_A)
	# the lantern: an octagon with arched openings, a dome and two crosses
	var lc := _w(3.5, 0.5)
	var lan := _circle(lc, 1.6, 8)
	_prism(lan, g + 19.4, g + 22.0, CK_DARK, none, M_STONE)
	for k in 4:
		var a := lan[(2 * k + 1) % 8]
		var b := lan[2 * k]
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 20.0], 0.6, 1.6, CK_WHITE.darkened(0.5), 0.04)
	kit_front(CK_O, CK_O + CK_A)
	_frustum(_circle(lc, 1.75, 8), g + 22.0, _circle(lc, 0.2, 8), g + 23.3, CK_DARK)
	_kap_cross(3.5, 0.5, g + 23.3, 2.2)
	_kap_cross(5.2, 0.5, g + 19.2, 2.6)
	# --- the chapel on the street: walls to 9.6 a little proud of the wings, a gable to 12.4
	var cp := _rect(-12.5, 1.15, 4.3, 5.95)
	_prism(cp, g - 1.0, g + 9.6, CK_CREAM, none, M_STONE)
	_gable(-16.8, -8.2, 1.15, 5.95, g + 9.6, 2.8, CK_CREAM, CK_TILE, true)
	kit_front(_w(-16.8, -4.8), _w(-16.8, 7.1))
	kit_face(0.0)
	kit_pilaster(0.35, g, g + 9.5, CK_WHITE, 0.7, 0.08)
	kit_pilaster(11.55, g, g + 9.5, CK_WHITE, 0.7, 0.08)
	kit_ledge(-0.2, 12.1, g + 9.3, 0.35, CK_WHITE, 0.2)
	kit_door(5.95, g, 3.2, 1.1, CK_WHITE, CK_DARK)
	kit_panes([3.6, 8.3], [g + 6.0], 0.5, 0.9, PAL_GLASS_DARK, 0.05)
	_kbox(9.55, 9.85, 0.0, 0.25, g + 0.3, g + 5.9, CK_DARK)  # the big cross by the door
	_kbox(8.6, 10.8, 0.0, 0.25, g + 4.2, g + 4.5, CK_DARK)
	kit_front(CK_O, CK_O + CK_A)
	_kap_cross(-16.9, 1.15, g + 12.4, 1.2)
	# the little white turret on the chapel's ridge at its back
	_lbox(-9.2, 1.15, 0.8, 0.8, g + 11.0, g + 14.2, CK_WHITE)
	_frustum(_rect(-9.2, 1.15, 0.95, 0.95), g + 14.2, _rect(-9.2, 1.15, 0.1, 0.1), g + 15.2, CK_DARK)
	_kap_cross(-9.2, 1.15, g + 15.2, 1.0)
	# --- the slim white bell tower at the chapel's left corner: shaft, arched lantern, cap, cross
	_lbox(-15.5, -5.85, 1.35, 1.15, g - 1.0, g + 18.5, CK_WHITE)
	kit_ledge_ring(_rect(-15.5, -5.85, 1.35, 1.15), g + 18.3, 0.25, CK_WHITE.darkened(0.06), 0.12)
	var tc := _w(-15.5, -5.85)
	var bel := _circle(tc, 1.05, 8)
	_prism(bel, g + 18.5, g + 20.8, CK_WHITE, none, M_STONE)
	for k in 4:
		var a := bel[(2 * k + 1) % 8]
		var b := bel[2 * k]
		var ln := kit_front(a, b)
		kit_panes([ln * 0.5], [g + 18.9], 0.45, 1.4, CK_DARK, 0.04)
	kit_front(CK_O, CK_O + CK_A)
	_frustum(_circle(tc, 1.15, 8), g + 20.8, _circle(tc, 0.15, 8), g + 22.0, CK_DARK)
	_kap_cross(-15.5, -5.85, g + 22.0, 1.4)
	# --- windows on the wings
	for e: Array in [[Vector2(-8.25, -15.23), Vector2(-5.76, -6.79)], [Vector2(12.05, -21.88), Vector2(-8.25, -15.23)],
			[Vector2(9.94, 20.93), Vector2(26.21, 15.11)], [Vector2(-3.46, 8.81), Vector2(0.64, 20.75)],
			[Vector2(26.21, 15.11), Vector2(22.27, 3.79)], [Vector2(21.12, 0.02), Vector2(19.13, -5.78)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(CK_O, CK_O + CK_A)
		var ln := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var n := maxi(1, floori(ln / 2.6))
		var cols: Array = []
		for i in n:
			cols.append((float(i) + 0.5) * ln / float(n))
		kit_panes(cols, [g + 1.2, g + 5.2], 1.4, 2.4, PAL_GLASS_DARK, 0.05)
	kit_front(CK_O, CK_O + CK_A)
	_collide(outline)


## The Baptist church on Waliców (Kościół Chrześcijan Baptystów, Waliców 25; 1970s, among the
## Wola tower blocks): a modernist box, its blank light grey upper storey of fair-faced concrete
## overhanging a glazed ground floor set back under it, a big dark cross on the front and the line
## "PRAWDĘ I POKÓJ MIŁUJCIE - MÓWI PAN NIEBIOS" along its foot (here a dark band). A model that
## replaces the plain OpenStreetMap block (building 7442; no landmark until 2026-11-14). From 8
## Commons photos (refs/churches/baptist_walicow, reference only, never shipped), the OSM outline
## and GUGiK's LoD2 (over the ground: the flat top at 8.6). The four-storey extension at the back
## (building site in 2025) is left out. Spec docs/landmarks/specs/baptysci.md.
## Frame: origin at the outline's centre, u along the front (toward Chłodna's end at -u), v to
## the north; the front with the cross faces Waliców (-v).
const BP_O := Vector2(-2255.3, -359.0)
const BP_A := Vector2(0.265, 0.964)
const BP_WALL := Color("#d6d4cc")      ## the light grey concrete (photos)
const BP_BASE := Color("#8e8b84")      ## the ground floor's piers and frames
const BP_DARK := Color("#4e3628")      ## the cross
const BP_ROOF := Color("#9a978f")      ## the flat roof


func _build_baptysci(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(BP_O, BP_O + BP_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# --- the glazed ground floor set back under the box, the box overhanging it
	_prism(_rect(4.0, 0.0, 11.0, 9.0), g - 1.0, g + 3.3, BP_BASE, none, M_STONE)
	var box := _rect(4.0, 0.0, 12.0, 10.0)
	_prism(box, g + 3.3, g + 8.6, BP_WALL, BP_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(box, g + 8.6, 0.2, BP_WALL.lightened(0.05), 0.04)
	for e: Array in [[Vector2(15.0, -9.0), Vector2(-7.0, -9.0)], [Vector2(-7.0, 9.0), Vector2(15.0, 9.0)],
			[Vector2(-7.0, -9.0), Vector2(-7.0, 9.0)], [Vector2(15.0, 9.0), Vector2(15.0, -9.0)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(BP_O, BP_O + BP_A)
		var ln := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var n := maxi(1, floori(ln / 1.9))
		var cols: Array = []
		for i in n:
			cols.append((float(i) + 0.5) * ln / float(n))
		kit_panes(cols, [g + 0.3], ln / float(n) - 0.25, 2.6, PAL_GLASS_DARK, 0.04)
	# --- the front on Waliców: the cross, the line of lettering
	kit_front(BP_O, BP_O + BP_A)
	kit_front(_w(16.0, -10.0), _w(-8.0, -10.0))
	kit_face(0.0)
	_kbox(15.2, 15.6, 0.0, 0.12, g + 4.6, g + 8.0, BP_DARK)
	_kbox(14.1, 16.7, 0.0, 0.12, g + 6.7, g + 7.1, BP_DARK)
	_kbox(1.5, 22.5, 0.0, 0.06, g + 3.75, g + 4.05, BP_BASE.darkened(0.25))
	kit_front(BP_O, BP_O + BP_A)
	_collide(outline)


## St Barbara's chapel (Kaplica pw. św. Barbary, Koszyki, by Sts Peter and Paul on Nowogrodzka /
## Emilii Plater): a red brick chapel under a steep dark roof with gables at both ends and a low
## lean annex on its north side. A model that replaces the plain OpenStreetMap block (building
## 1521; no landmark until 2026-11-14). From two Commons photos (refs/churches/st_barbara_koszyki,
## reference only, never shipped; trees and the fence hide most of it), the OSM outline and GUGiK's
## LoD2 (over the ground: the eaves 8.9, the ridge 11.9, the annex 3.2). Spec docs/landmarks/specs/barbara.md.
## Frame: origin at the outline's centre, u along the chapel, v to its left.
const SB_O := Vector2(-1102.0, 874.5)
const SB_A := Vector2(0.342, 0.940)
const SB_BRICK := Color("#a4553f")     ## the red brick (photos)
const SB_STONE := Color("#cfc6b4")     ## copings, sills, the plinth
const SB_ROOF := Color("#4b4d50")      ## the dark roof


func _build_barbara(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(SB_O, SB_O + SB_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var body := _rect(0.07, -0.15, 7.63, 4.52)
	_prism(body, g - 1.0, g + 8.9, SB_BRICK, none, M_STONE)
	kit_ledge_ring(body, g - 1.0, 1.5, SB_STONE, 0.08)
	kit_ledge_ring(body, g + 8.6, 0.3, SB_STONE, 0.15)
	_gable(7.7, -7.56, -0.15, 4.52, g + 8.9, 3.0, SB_BRICK, SB_ROOF, true)
	_lbox(0.07, 5.92, 7.6, 1.48, g - 1.0, g + 3.2, SB_BRICK, M_STONE, SB_ROOF)
	# --- the long sides' tall windows, the gable ends' round windows, the door at the west end
	for e: Array in [[Vector2(7.7, -4.67), Vector2(-7.56, -4.67)], [Vector2(-7.56, 7.4), Vector2(7.7, 7.4)],
			[Vector2(-7.56, 4.38), Vector2(7.7, 4.38)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(SB_O, SB_O + SB_A)
		var ln := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var high := p0.y > 4.0 and p0.y < 5.0
		var low := p0.y > 7.0
		var sill := g + (4.4 if high else (0.8 if low else 1.8))
		var tall := 3.6 if high else (1.8 if low else 3.2)
		kit_panes([ln * 0.2, ln * 0.5, ln * 0.8], [sill], 1.2, tall, PAL_GLASS_DARK, 0.05)
		if not low:
			kit_panes([ln * 0.2, ln * 0.5, ln * 0.8], [sill + tall], 0.7, 0.35, PAL_GLASS_DARK, 0.05)
	for e: Array in [[Vector2(7.7, 4.38), Vector2(7.7, -4.67)], [Vector2(-7.56, -4.67), Vector2(-7.56, 4.38)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(SB_O, SB_O + SB_A)
		var ln := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var c := _w(ln * 0.5, 0.06)
		_disc(Vector3(c.x, g + 9.9, c.y), Vector3(_b.x, 0.0, _b.y), 0.8, 8, PAL_GLASS_DARK)
		kit_panes([ln * 0.3, ln * 0.7], [g + 2.4], 1.1, 3.6, PAL_GLASS_DARK, 0.05)
		if p0.x < 0.0:
			kit_door(ln * 0.5, g, 3.4, 1.0, SB_STONE, Color("#4a3328"), true)
	kit_front(SB_O, SB_O + SB_A)
	_kap_cross(-7.7, -0.15, g + 11.9, 1.2)
	_collide(outline)


## The Missionaries' house on Krakowskie Przedmieście (Dom Księży Misjonarzy, Krakowskie
## Przedmieście 1/3, by the Holy Cross church; 18th century, rebuilt after 1944; the University's
## Faculty of Philosophy uses the street wing): a long three-storey ochre front of 17 bays over a
## white rusticated ground floor with arched gates and shop doors, capped windows on the first
## floor, a white cornice and a grey roof with a row of white gabled dormers; a wing runs down
## Karowa. A model that replaces the plain OpenStreetMap block (building 7141; no landmark until
## 2026-11-14). From 8 Commons photos (refs/churches/missionaries_krakowskie_przedmiescie_1,
## reference only, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the eaves
## about 12.5, the ridge about 16). The back wing (building 5803) stays the plain block.
## Spec docs/landmarks/specs/misjonarze.md.
## Frame: origin at the house's inner corner, u toward the church, v to the north-west; the front
## on Krakowskie Przedmieście faces -v. The street wing's front is skewed 3.5 degrees from that,
## so it gets its own frame from its two front corners (MS_F0 by the church, MS_F1 at Karowa).
const MS_O := Vector2(-515.5, -564.0)
const MS_A := Vector2(0.288, 0.958)
const MS_F0 := Vector2(-469.18, -549.9)
const MS_F1 := Vector2(-483.29, -588.21)
const MS_WALL := Color("#d7c08a")      ## the ochre plaster (photos)
const MS_WHITE := Color("#e9e4d6")     ## the ground floor, cornice, window caps, dormers
const MS_ROOF := Color("#5b5d60")      ## the grey roof
const MS_DOOR := Color("#4b3a2e")      ## the gates' leaves


func _build_misjonarze(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(MS_O, MS_O + MS_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_prism(outline, g - 1.0, g + 12.5, MS_WALL, none, M_STONE)
	# --- the Karowa wing's hipped roof, its foot under the street wing's roof
	_hip(-7.1, -4.0, 7.25, 22.0, g + 12.5, 3.3, MS_ROOF)
	# --- the street wing in its own frame: v out to the street, the wing from v 0 back to -14.4
	var ln := kit_front(MS_F0, MS_F1)
	_gable(-0.3, ln + 0.3, -7.2, 7.45, g + 12.5, 3.5, MS_WALL, MS_ROOF, true)
	kit_face(0.0)
	_kbox(0.0, ln, -0.05, 0.1, g - 1.0, g + 4.2, MS_WHITE)
	kit_face(0.1)
	kit_bands(0.0, ln, g, g + 4.0, 0.7, MS_WHITE)
	kit_ledge(-0.1, ln + 0.1, g + 4.0, 0.3, MS_WHITE, 0.2)
	kit_ledge(0.0, ln, g + 7.9, 0.15, MS_WHITE, 0.1)
	kit_face(0.0)
	kit_cornice(0.0, ln, g + 12.1, MS_WHITE, 0.4, 0.55)
	var bay := ln / 17.0
	var cols: Array = []
	for i in 17:
		cols.append((float(i) + 0.5) * bay)
	kit_panes(cols, [g + 5.0], 1.15, 2.3, PAL_GLASS_DARK, 0.05)
	kit_panes(cols, [g + 9.0], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	for c: float in cols:
		_kbox(c - 0.85, c + 0.85, 0.0, 0.22, g + 7.45, g + 7.65, MS_WHITE)
	kit_face(0.1)
	var shop: Array = []
	for i in 17:
		if i in [1, 4, 8, 12, 15]:
			kit_door(cols[i], g, 3.4 if i == 8 else 2.9, 1.3 if i == 8 else 0.85, MS_WHITE, MS_DOOR, true)
		else:
			shop.append(cols[i])
	kit_panes(shop, [g + 0.9], 1.1, 2.1, PAL_GLASS_DARK, 0.05)
	kit_face(0.0)
	# --- eleven white dormers on the street roof, each a box with a small gable over its window
	for k in 11:
		var du := (float(k) + 0.5) * ln / 11.0
		_kbox(du - 0.8, du + 0.8, -4.2, -1.6, g + 12.8, g + 14.5, MS_WHITE)
		kit_face(-1.6)
		kit_panes([du], [g + 13.0], 0.8, 1.15, PAL_GLASS_DARK, 0.04)
		var p0 := _w(du, -4.2)
		var p1 := _w(du, -1.45)
		kit_front(p0, p1)
		_gable(2.75, 0.0, 0.0, 0.9, g + 14.5, 0.75, MS_WHITE, MS_ROOF, false)
		kit_front(MS_F0, MS_F1)
	# --- windows on the other walls: the Karowa side, the courtyard sides, the north end
	for e: Array in [[Vector2(-13.95, -36.25), Vector2(-14.27, 17.95)], [Vector2(0.29, -24.24), Vector2(27.61, -25.85)],
			[Vector2(0.0, -2.0), Vector2(0.29, -24.24)], [Vector2(-14.27, 17.95), Vector2(-0.13, 17.82)]]:
		var p0: Vector2 = e[0]
		var p1: Vector2 = e[1]
		kit_front(MS_O, MS_O + MS_A)
		var le := kit_front(_w(p0.x, p0.y), _w(p1.x, p1.y))
		var n := maxi(1, floori(le / 2.6))
		var cs: Array = []
		for i in n:
			cs.append((float(i) + 0.5) * le / float(n))
		kit_panes(cs, [g + 1.0, g + 5.0, g + 9.0], 1.1, 2.0, PAL_GLASS_DARK, 0.05)
	kit_front(MS_O, MS_O + MS_A)
	_collide(outline)


## The Missionaries' house on Radna (Dom Księży Misjonarzy św. Wincentego a Paulo, Radna 14,
## Powiśle; with the Miraculous Medal chapel): a five-storey cream front of nine bays on Radna
## over a rusticated ground floor with round-headed windows, the portal in the middle under a blue
## niche with the white Virgin and a balcony, a cornice and a low roof; behind it, a one-storey
## block round the courtyard holds the chapel, its tall leaded windows on the back wall. A model that
## replaces the plain OpenStreetMap block (building 2279; no landmark until 2026-11-14). From 7
## Commons photos (refs/churches/missionaries_radna_14, reference only, never shipped), the OSM
## outline and GUGiK's LoD2 (over the ground: the front wing's eaves 18.6, its ridge 20.6, the
## back block 7). Spec docs/landmarks/specs/misjonarze_radna.md.
## Frame: origin at the front's east corner, u along Radna to the west, v back into the block; the
## front faces Radna (-v).
const MR_O := Vector2(-53.0, -747.2)
const MR_A := Vector2(-0.888, 0.459)
const MR_WALL := Color("#e8dcb8")      ## the cream plaster (photos)
const MR_BASE := Color("#cbbd9c")      ## the rusticated ground floor
const MR_TRIM := Color("#efe9da")      ## cornices, the portal
const MR_ROOF := Color("#6a6460")      ## the low roof
const MR_NICHE := Color("#7fb3c8")     ## the blue niche behind the Virgin
const MR_DOOR := Color("#5a3a26")      ## the oak door


func _build_misjonarze_radna(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(MR_O, MR_O + MR_A)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var front := _rect(12.32, 6.35, 12.32, 6.4)
	_prism(front, g - 1.0, g + 18.6, MR_WALL, none, M_STONE)
	_gable(0.0, 24.64, 6.35, 6.4, g + 18.6, 2.0, MR_WALL, MR_ROOF, true)
	_prism(_rect(12.2, 18.9, 11.95, 6.25), g - 1.0, g + 7.0, MR_WALL, MR_ROOF.lightened(0.15), M_STONE, M_STONE)
	# --- the front on Radna
	var ln := kit_front(_w(24.64, -0.05), _w(0.0, -0.05))
	kit_face(0.0)
	_kbox(0.0, ln, -0.05, 0.1, g - 1.0, g + 4.5, MR_BASE)
	kit_face(0.1)
	kit_bands(0.0, ln, g, g + 4.3, 0.55, MR_BASE)
	kit_ledge(-0.1, ln + 0.1, g + 4.3, 0.35, MR_TRIM, 0.25)
	kit_face(0.0)
	kit_cornice(0.0, ln, g + 18.2, MR_TRIM, 0.4, 0.6)
	var bay := ln / 9.0
	var cols: Array = []
	for i in 9:
		cols.append((float(i) + 0.5) * bay)
	kit_panes(cols, [g + 5.3, g + 8.5, g + 11.7, g + 14.9], 1.2, 2.0, PAL_GLASS_DARK, 0.05)
	kit_face(0.2)
	for i in 9:
		if i == 4:
			continue
		kit_door(cols[i], g + 0.9, 3.0, 0.7, MR_TRIM, PAL_GLASS_DARK, true)
	# the portal: pilasters, the oak door, the blue niche with the Virgin, the balcony over it
	var c: float = cols[4]
	_kbox(c - 1.6, c + 1.6, 0.1, 0.35, g - 0.2, g + 3.6, MR_TRIM)
	kit_face(0.35)
	kit_door(c, g, 3.0, 0.9, MR_TRIM, MR_DOOR)
	_kbox(c - 0.7, c + 0.7, 0.1, 0.16, g + 3.65, g + 5.4, MR_NICHE)
	_kbox(c - 0.22, c + 0.22, 0.16, 0.4, g + 3.75, g + 5.05, MR_TRIM)
	_kbox(c - 2.0, c + 2.0, 0.0, 1.1, g + 6.1, g + 6.35, MR_TRIM)
	_kbox(c - 2.0, c + 2.0, 1.0, 1.1, g + 6.35, g + 7.3, MR_BASE.darkened(0.35))
	kit_face(0.0)
	# --- the courtyard side of the front wing, over the back block's roof
	kit_front(MR_O, MR_O + MR_A)
	var lb := kit_front(_w(0.0, 12.75), _w(24.64, 12.75))
	var cb: Array = []
	for i in 9:
		cb.append((float(i) + 0.5) * lb / 9.0)
	kit_panes(cb, [g + 8.5, g + 11.7, g + 14.9], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	# --- the chapel's tall leaded windows on the back block's back wall
	kit_front(MR_O, MR_O + MR_A)
	var lc := kit_front(_w(0.29, 25.15), _w(23.9, 25.15))
	kit_panes([lc * 0.2, lc * 0.4, lc * 0.6, lc * 0.8], [g + 1.6], 1.6, 3.8, Color("#2f3b3a"), 0.05)
	kit_front(MR_O, MR_O + MR_A)
	_collide(outline)


## The Capuchin monastery (Klasztor Ojców Kapucynów, Miodowa 13 / Kapucyńska, beside the church of
## the Transfiguration; 1680s-1690s, rebuilt after 1944): three-storey ranges in pale yellow plaster
## round a courtyard under hipped green copper roofs, plain rows of windows, a white cornice. A
## model that replaces the plain OpenStreetMap block (building 821; no landmark until 2026-11-14).
## From 12 Commons photos (refs/churches/capuchins_miodowa; 06-09 and 11 show the monastery from
## Kapucyńska and the W-Z route, reference only, never shipped), the OSM outline and GUGiK's LoD2.
## Spec docs/landmarks/specs/kapucyni_klasztor.md.
## The ranges stand at three angles, so each roof has its own frame: KK_O1/KK_A1 along the north
## range's outer wall (origin at its west corner, +v into the building), KK_O2/KK_A2 along the east
## range (origin at its south corner, -v inward), KK_O3/KK_A3 along the south range (origin at its
## west corner, -v inward).
const KK_O1 := Vector2(-1025.7, -1410.4)
const KK_A1 := Vector2(0.8453, -0.5343)
const KK_O2 := Vector2(-990.3, -1383.3)
const KK_A2 := Vector2(0.6097, -0.7926)
const KK_O3 := Vector2(-1018.4, -1397.6)
const KK_A3 := Vector2(0.8912, 0.4535)
const KK_WALL := Color("#ecdcae")      ## the pale yellow plaster (photos)
const KK_WHITE := Color("#f1ece0")     ## cornice, plinth band
const KK_ROOF := Color("#86a993")      ## green copper


func _build_kapucyni_klasztor(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(KK_O1, KK_O1 + KK_A1)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var eave := g + 11.5
	_prism(outline, g - 1.0, eave, KK_WALL, KK_ROOF.darkened(0.1), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.35, KK_WHITE, 0.35, 0.35)
	kit_ledge_ring(outline, g - 1.0, 1.6, KK_WHITE, 0.06)
	# --- the hipped roofs, one per range
	_hip(17.75, 4.5, 17.95, 4.7, eave, 4.2, KK_ROOF)          # north range
	_hip(-5.1, 2.05, 5.3, 7.1, eave, 4.6, KK_ROOF)           # the west block
	kit_front(KK_O2, KK_O2 + KK_A2)
	_hip(12.95, -5.5, 13.1, 5.6, eave, 4.2, KK_ROOF)         # east range
	kit_front(KK_O3, KK_O3 + KK_A3)
	_hip(15.75, -5.1, 15.9, 5.5, eave, 4.2, KK_ROOF)         # south range
	# --- windows on three floors round every wall long enough for one
	var n := outline.size()
	for k in n:
		var a := outline[(k + 1) % n]
		var b := outline[k]
		var ln := kit_front(a, b)
		if ln < 3.0:
			continue
		var m := maxi(1, floori(ln / 3.0))
		var cols: Array = []
		for i in m:
			cols.append((float(i) + 0.5) * ln / float(m))
		kit_panes(cols, [g + 1.2, g + 4.8, g + 8.3], 1.1, 1.8, PAL_GLASS_DARK, 0.05)
	kit_front(KK_O1, KK_O1 + KK_A1)
	_collide(outline)


## The Franciscan Sisters of the Cross' house on Piwna (Dom Zakonny Sióstr Franciszkanek Służebnic
## Krzyża, Piwna 9/11; the old Augustinian monastery by St Martin's, rebuilt after 1944): ochre
## plaster ranges round the church's chancel, three rows of windows on Piwna with the stone portal
## under its cartouche, hipped tile roofs. St Martin's tower stands in this block on Piwna and is
## the church's own model (`_build_marcin`). A model that replaces the plain OpenStreetMap block
## (building 1676; no landmark until 2026-11-14). From 9 Commons photos
## (refs/churches/franciscan_sisters_piwna, reference only, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the eaves about 10.5, the ridges about 15).
## Spec docs/landmarks/specs/franciszkanki_piwna.md.
## Frame: origin at the front's north corner on Piwna, u along Piwna to the south-east, +v into
## the block; the front faces Piwna (-v).
const FS_O := Vector2(-772.0, -1582.8)
const FS_A := Vector2(0.6253, 0.7804)
const FS_WALL := Color("#e2b86c")      ## the ochre plaster (photos)
const FS_STONE := Color("#d8cfbd")     ## the portal, window surrounds, cornice
const FS_ROOF := Color("#9a5040")      ## tile (a default: no photo shows the roofs)
const FS_DOOR := Color("#3b3430")      ## the gate's leaves


func _build_franciszkanki_piwna(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(FS_O, FS_O + FS_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 10.5
	_prism(outline, g - 1.0, eave, FS_WALL, FS_ROOF.darkened(0.1), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.3, FS_STONE, 0.3, 0.3)
	_hip(10.5, 4.6, 14.85, 5.5, eave, 4.4, FS_ROOF)      # the range on Piwna
	_hip(12.9, 26.0, 7.5, 17.7, eave, 4.5, FS_ROOF)      # the long range behind
	_hip(1.5, 34.95, 4.0, 8.95, eave, 3.5, FS_ROOF)      # the back range
	# --- the front on Piwna: three rows of windows (none where the tower stands), the portal
	var ln := kit_front(_w(25.25, -0.65), _w(-4.17, 0.25))
	kit_face(0.0)
	var cols: Array = []
	for i in 10:
		var c := 1.4 + float(i) * 2.75
		var u_frame := 25.25 - c
		if u_frame > -1.2 and u_frame < 7.2:
			continue
		if absf(c - 12.4) < 1.5:
			continue
		cols.append(c)
	kit_panes(cols, [g + 1.6, g + 8.0], 1.1, 1.7, PAL_GLASS_DARK, 0.05)
	for c: float in cols:
		_kbox(c - 0.75, c + 0.75, 0.0, 0.1, g + 4.75, g + 6.75, FS_STONE)
	kit_face(0.1)
	kit_panes(cols, [g + 4.9], 1.1, 1.7, PAL_GLASS_DARK, 0.05)
	kit_face(0.0)
	_kbox(10.6, 14.2, 0.0, 0.3, g - 0.2, g + 4.6, FS_STONE)
	kit_face(0.3)
	kit_door(12.4, g, 3.6, 1.1, FS_STONE, FS_DOOR, true)
	_kbox(11.8, 13.0, 0.0, 0.12, g + 4.8, g + 6.0, FS_STONE)
	kit_face(0.0)
	kit_ledge(0.0, ln, g + 0.3, 0.3, FS_STONE, 0.08)
	# --- windows on the other walls long enough for them
	var n := outline.size()
	for k in n:
		kit_front(FS_O, FS_O + FS_A)
		var a := outline[(k + 1) % n]
		var b := outline[k]
		var le := kit_front(a, b)
		if le < 4.0 or (k >= 21 and k <= 25):
			continue
		var m := maxi(1, floori(le / 3.0))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_panes(cs, [g + 1.6, g + 4.9, g + 8.0], 1.0, 1.6, PAL_GLASS_DARK, 0.05)
	kit_front(FS_O, FS_O + FS_A)
	_collide(outline)


## Sala św. Faustyny (the St Faustina hall of St James' parish, Ochota, by Plac Narutowicza): a
## low red brick hall from the 1990s with a row of steep gabled bays between brick piers, each
## gable with a louvre, and a round-arched porch with a curved dark roof over the oak door. A model
## that replaces the plain OpenStreetMap block (building 5693; no landmark until 2026-11-14). From
## one Commons photo (refs/churches/sala_faustyny, reference only, never shipped), the OSM outline
## (8 m over the ground). Spec docs/landmarks/specs/sala_faustyny.md.
## Frame: origin at the outline's middle, u east (+x), v south (+z); the gables and the porch face
## south (+v), to the parish yard.
const SF_O := Vector2(-2794.0, 1570.0)
const SF_BRICK := Color("#b0503a")     ## the red brick (photo)
const SF_ROOF := Color("#4e4f52")      ## the dark sheet roofs
const SF_STONE := Color("#c9c1b0")     ## the porch's tympanum, copings
const SF_DOOR := Color("#5a3826")      ## the oak door


func _build_sala_faustyny(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(SF_O, SF_O + Vector2(1.0, 0.0))
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 5.0
	_prism(outline, g - 1.0, eave, SF_BRICK, SF_ROOF.lightened(0.1), M_STONE, M_STONE)
	# --- the row of steep gabled bays, ridges running north-south (a frame along +v)
	kit_front(SF_O, SF_O + Vector2(0.0, 1.0))  # u' = v, v' = -u
	for cu: float in [-10.5, -3.85, 3.9]:
		_gable(6.6, -7.4, -cu, 3.1, eave, 3.0, SF_BRICK, SF_ROOF, true)
	kit_front(SF_O, SF_O + Vector2(1.0, 0.0))
	# louvres in the gables on the south side
	kit_front(_w(-14.0, 6.6), _w(12.0, 6.6))
	kit_face(0.0)
	for cu: float in [-10.5, -3.85, 3.9]:
		var c := cu + 14.0
		_kbox(c - 0.35, c + 0.35, 0.0, 0.08, eave + 0.6, eave + 1.9, Color("#2a2a2c"))
		kit_panes([c], [g + 1.6], 0.5, 2.6, PAL_GLASS_DARK, 0.05)
	# --- the porch: a brick box with the round-arched door and a low dark roof
	kit_front(SF_O, SF_O + Vector2(1.0, 0.0))
	_lbox(11.6, 6.3, 2.4, 1.8, g - 1.0, g + 4.2, SF_BRICK, M_STONE, SF_BRICK)
	_gable(14.2, 9.0, 6.3, 1.95, g + 4.2, 1.0, SF_ROOF, SF_ROOF, true)
	kit_front(_w(9.2, 8.1), _w(14.0, 8.1))
	kit_face(0.0)
	kit_door(2.4, g, 3.2, 0.85, SF_STONE, SF_DOOR, true)
	kit_front(SF_O, SF_O + Vector2(1.0, 0.0))
	_collide(outline)


## The Visitation Sisters' convent (Klasztor Sióstr Wizytek, Krakowskie Przedmieście 34, behind
## their church; 1650s-1730s, it came through 1944): four two-storey ranges round a closed
## courtyard under steep hipped roofs, the long range on Karowa, the garden side over the
## escarpment. A model that replaces the plain OpenStreetMap block (building 12626; no landmark
## until 2026-11-15). The massing is GUGiK's LoD2 (over the ground: the eaves about 8, the
## ridges about 14.5; the courtyard about 16 x 22 m, a flat cloister walk on its west side). No
## street photo shows the convent (it stands behind the church and its garden wall), so the
## plaster, the roof colour and the window rows are defaults until photos arrive
## (docs/QUESTIONS.md). Spec docs/landmarks/specs/wizytki_klasztor.md.
## Frame: origin at the west range's corner by the church, u to the north-west along it (u 27 is
## the range on Karowa), +v to the east-north-east, towards the escarpment.
const WK_O := Vector2(-444.1, -813.3)
const WK_A := Vector2(-0.518, -0.856)
const WK_WALL := Color("#e8dcc2")      ## light plaster (a default, the church's tone)
const WK_WHITE := Color("#f2ede2")     ## cornice, plinth band
const WK_ROOF := Color("#9a5545")      ## tile (a default)


func _build_wizytki_klasztor(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(WK_O, WK_O + WK_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 8.0
	var court := _rect(7.0, 26.75, 8.0, 11.25)
	_prism(outline, g - 1.0, eave, WK_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_cap_holes(outline, [court], eave, WK_ROOF.darkened(0.25))
	kit_cornice_ring(outline, eave - 0.3, WK_WHITE, 0.3, 0.3)
	kit_ledge_ring(outline, g - 1.0, 1.2, WK_WHITE, 0.06)
	# --- the courtyard: walls facing in, the ground floor's arcade of windows above
	var n := court.size()
	for k in n:
		var a := court[k]
		var b := court[(k + 1) % n]
		_wall(a, b, g - 0.6, eave, -_out(court, a, b), WK_WALL, 0.0)
	# --- the hipped roofs, one per range (LoD2 ridges)
	_hip(13.5, 7.75, 13.5, 7.75, eave, 6.5, WK_ROOF)       # the west range, by the church
	_hip(-7.0, 10.5, 7.0, 3.9, eave, 3.4, WK_ROOF)         # its short link to the south
	_hip(-15.0, 29.5, 7.0, 15.5, eave, 6.5, WK_ROOF)       # the south range
	_hip(21.0, 26.0, 6.0, 26.0, eave, 6.0, WK_ROOF)        # the range on Karowa
	_hip(-2.0, 45.0, 29.0, 7.0, eave, 6.5, WK_ROOF)        # the garden range over the escarpment
	# --- two rows of windows round every outer wall long enough for one
	var m := outline.size()
	for k in m:
		var ln := kit_front(outline[(k + 1) % m], outline[k])
		if ln < 3.0:
			continue
		var c := maxi(1, floori(ln / 3.2))
		var cols: Array = []
		for i in c:
			cols.append((float(i) + 0.5) * ln / float(c))
		kit_panes(cols, [g + 1.2, g + 4.7], 1.1, 1.8, PAL_GLASS_DARK, 0.05)
	# --- and on the courtyard walls, facing in
	for k in n:
		var a := court[k]
		var b := court[(k + 1) % n]
		var ln := kit_front(a, b)
		if _b.dot(-_out(court, a, b)) < 0.0:
			ln = kit_front(b, a)
		var c := maxi(1, floori(ln / 3.2))
		var cols: Array = []
		for i in c:
			cols.append((float(i) + 0.5) * ln / float(c))
		kit_panes(cols, [g + 1.2, g + 4.7], 1.1, 1.8, PAL_GLASS_DARK, 0.05)
	kit_front(WK_O, WK_O + WK_A)
	_collide(outline)


## The Franciscan Reformati friary beside St Anthony of Padua's (Klasztor Reformatów, Senatorska
## 31; 1680s, rebuilt after 1944): four ranges round a closed courtyard on the church's north-east
## side, between the church and the street, under red tile hipped roofs. A model that replaces the
## plain OpenStreetMap block (building 12816, unnamed `monastery`). The massing is GUGiK's LoD2
## (over the ground: the eaves about 9, the ridges about 13; the courtyard about 18 x 14 m). The
## church's 15 Commons photos (refs/churches/st_anthony_senatorska) show the complex in white
## plaster under orange-red tiles, but none shows the friary's own outer walls, so it takes the
## church's colours and plain window rows (defaults, docs/QUESTIONS.md). Spec
## docs/landmarks/specs/reformaci_klasztor.md.
## Frame: origin at the block's west corner, u to the south-east along the range by the street, +v
## to the north-east.
const RFM_O := Vector2(-1193.3, -1001.9)
const RFM_A := Vector2(0.6655, -0.7464)
const RFM_WALL := Color("#f0ece2")      ## white plaster (the church's, photos)
const RFM_TRIM := Color("#e0d9ca")      ## cornice, plinth band
const RFM_ROOF := Color("#c4603d")      ## orange-red tiles (the church's, photos)


func _build_reformaci_klasztor(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(RFM_O, RFM_O + RFM_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 9.0
	var court := _rect(13.0, 17.5, 9.0, 7.0)
	_prism(outline, g - 1.0, eave, RFM_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_cap_holes(outline, [court], eave, RFM_ROOF.darkened(0.25))
	kit_cornice_ring(outline, eave - 0.3, RFM_TRIM, 0.3, 0.3)
	kit_ledge_ring(outline, g - 1.0, 1.2, RFM_TRIM, 0.06)
	# --- the courtyard: walls facing in
	var n := court.size()
	for k in n:
		var a := court[k]
		var b := court[(k + 1) % n]
		_wall(a, b, g - 0.6, eave, -_out(court, a, b), RFM_WALL, 0.0)
	# --- the hipped roofs, one per range (LoD2 ridges)
	_hip(16.0, 5.25, 20.0, 5.25, eave, 4.0, RFM_ROOF)      # the range by the street
	_hip(16.0, 30.2, 20.0, 5.7, eave, 4.0, RFM_ROOF)       # the range by the church
	_hip(0.0, 17.5, 3.9, 7.5, eave, 3.0, RFM_ROOF)         # the short north-west range
	_hip(29.2, 17.7, 6.9, 17.7, eave, 4.0, RFM_ROOF)       # the long south-east range
	# --- two rows of windows round every outer wall long enough for one
	var m := outline.size()
	for k in m:
		var ln := kit_front(outline[(k + 1) % m], outline[k])
		if ln < 3.0:
			continue
		var c := maxi(1, floori(ln / 3.4))
		var cols: Array = []
		for i in c:
			cols.append((float(i) + 0.5) * ln / float(c))
		kit_panes(cols, [g + 1.4, g + 5.0], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	# --- and on the courtyard walls, facing in
	for k in n:
		var a := court[k]
		var b := court[(k + 1) % n]
		var ln := kit_front(a, b)
		if _b.dot(-_out(court, a, b)) < 0.0:
			ln = kit_front(b, a)
		var c := maxi(1, floori(ln / 3.4))
		var cols: Array = []
		for i in c:
			cols.append((float(i) + 0.5) * ln / float(c))
		kit_panes(cols, [g + 1.4, g + 5.0], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	kit_front(RFM_O, RFM_O + RFM_A)
	_collide(outline)


## The Field Cathedral's presbytery (plebania of Katedra Polowa Wojska Polskiego, Długa 13/15):
## a three-storey house in pale cream plaster that stands against the cathedral's north side, its
## front on Długa a step ahead of the church's, with stucco window surrounds, a balcony over the
## arched door and a gabled roof along the street. A model that replaces the plain OpenStreetMap
## block (building 1833; no landmark until 2026-11-15). From two street photos on Długa
## (Mapillary, refs/churches/plebania_katedra_polowa, reference only, never shipped; trees hide
## the upper floors), the OSM outline and GUGiK's LoD2 (over the ground: the eaves about 12.8,
## the ridge about 17.3). The roof colour and the back walls are defaults (docs/QUESTIONS.md).
## Spec docs/landmarks/specs/plebania_katedra_polowa.md.
## Frame: origin at the front's corner by the cathedral, u to the north-east along Długa, +v to
## the south-east, into the block; the front faces Długa (-v).
const PLK_O := Vector2(-1165.3, -1665.4)
const PLK_A := Vector2(0.624, -0.781)
const PLK_WALL := Color("#e8dcc0")      ## pale cream plaster (photos)
const PLK_TRIM := Color("#f3ece0")      ## window surrounds, cornice, string courses
const PLK_ROOF := Color("#6f8d7e")      ## green copper like the cathedral's (a default)
const PLK_DOOR := Color("#4a3426")      ## the oak door


func _build_plebania_katedra_polowa(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(PLK_O, PLK_O + PLK_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 12.8
	_prism(outline, g - 1.0, eave, PLK_WALL, PLK_ROOF.darkened(0.2), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.45, PLK_TRIM, 0.45, 0.4)
	kit_ledge_ring(outline, g - 1.0, 1.3, PLK_TRIM.darkened(0.06), 0.06)
	_gable(22.75, -0.28, 7.58, 7.75, eave, 4.5, PLK_WALL, PLK_ROOF, true)
	# --- the front on Długa: three rows of seven windows, framed, the balcony over the door
	var ln := kit_front(_w(22.65, -0.17), _w(0.0, 0.0))
	kit_face(0.0)
	var cols: Array = []
	for i in 7:
		cols.append(1.9 + float(i) * (ln - 3.8) / 6.0)
	var mid: float = cols[3]
	kit_ledge(0.0, ln, g + 4.6, 0.25, PLK_TRIM, 0.1)
	kit_ledge(0.0, ln, g + 8.7, 0.25, PLK_TRIM, 0.1)
	for c: float in cols:
		for row: Array in [[g + 1.4, 1.8], [g + 5.3, 2.4], [g + 9.3, 1.9]]:
			var y0: float = row[0]
			var h: float = row[1]
			if c == mid and y0 < g + 2.0:
				continue
			_kbox(c - 0.75, c + 0.75, 0.0, 0.08, y0 - 0.2, y0 + h + 0.2, PLK_TRIM)
	kit_face(0.08)
	for c: float in cols:
		if c != mid:
			kit_panes([c], [g + 1.4], 1.1, 1.8, PAL_GLASS_DARK, 0.05)
	kit_panes(cols, [g + 5.3], 1.1, 2.4, PAL_GLASS_DARK, 0.05)
	kit_panes(cols, [g + 9.3], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	for c: float in cols:
		_kbox(c - 0.85, c + 0.85, 0.0, 0.18, g + 7.9, g + 8.1, PLK_TRIM)   # the first floor's hoods
	kit_face(0.0)
	# the arched door in its stone portal, and the balcony over it on two brackets
	_kbox(mid - 1.4, mid + 1.4, 0.0, 0.25, g - 0.2, g + 4.0, PLK_TRIM)
	kit_face(0.25)
	kit_door(mid, g, 3.4, 0.95, PLK_TRIM.darkened(0.08), PLK_DOOR, true)
	kit_face(0.0)
	_kbox(mid - 2.2, mid + 2.2, -1.0, 0.0, g + 4.75, g + 5.0, PLK_TRIM)
	_kbox(mid - 2.2, mid + 2.2, -1.0, -0.9, g + 5.0, g + 5.95, PLK_DOOR.darkened(0.3))
	for s: float in [-1.6, 1.6]:
		_kbox(mid + s - 0.15, mid + s + 0.15, -0.9, 0.0, g + 4.1, g + 4.75, PLK_TRIM)
	# --- two rows of windows on the other walls (not the one against the cathedral)
	kit_front(PLK_O, PLK_O + PLK_A)
	var n := outline.size()
	for k in n:
		if k == 1 or k == 2 or k == 3:
			continue
		kit_front(PLK_O, PLK_O + PLK_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 4.0:
			continue
		var m := maxi(1, floori(le / 3.2))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_panes(cs, [g + 1.4, g + 5.3, g + 9.3], 1.1, 1.9, PAL_GLASS_DARK, 0.05)
	kit_front(PLK_O, PLK_O + PLK_A)
	_collide(outline)


## St Augustine's presbytery (plebania of the parish of św. Augustyna, Nowolipki, south of the
## church): a two-storey post-war house under a flat roof with a raised middle block, its entrance
## in a recess on the west side. A model that replaces the plain OpenStreetMap block (building
## 1192; no landmark until 2026-11-15). The massing is GUGiK's LoD2 (over the ground: the roof
## about 8, the middle block about 10). No street photo shows the house (none on Mapillary or
## Panoramax within 45 m; the church's 11 Commons photos face the church), so the plaster, the
## windows and the door are defaults until photos arrive (docs/QUESTIONS.md).
## Spec docs/landmarks/specs/plebania_augustyn.md.
## Frame: origin at the house's south corner, u to the north-north-east along its east side,
## +v to the west-north-west.
const AUP_O := Vector2(-2406.0, -1124.2)
const AUP_A := Vector2(0.466, 0.884)
const AUP_WALL := Color("#e3dccd")      ## light plaster (a default)
const AUP_TRIM := Color("#cfc7b6")      ## copings, plinth (a default)
const AUP_ROOF := Color("#77736c")      ## the flat roof's felt
const AUP_DOOR := Color("#4a3a2c")      ## the door (a default)


func _build_plebania_augustyn(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(AUP_O, AUP_O + AUP_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var top := g + 8.0
	_prism(outline, g - 1.0, top, AUP_WALL, AUP_ROOF, M_STONE, M_STONE)
	kit_cornice_ring(outline, top - 0.3, AUP_TRIM, 0.4, 0.15)
	kit_ledge_ring(outline, g - 1.0, 1.0, AUP_TRIM, 0.05)
	# the raised middle block (LoD2: about 2 m over the roof)
	var mid := _rect(5.0, 7.6, 5.0, 3.4)
	_prism(mid, top, top + 2.0, AUP_WALL, AUP_ROOF.darkened(0.08), M_STONE, M_STONE)
	kit_cornice_ring(mid, top + 1.75, AUP_TRIM, 0.25, 0.1)
	# --- two rows of windows round every wall long enough for one
	var n := outline.size()
	for k in n:
		kit_front(AUP_O, AUP_O + AUP_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 3.0:
			continue
		var m := maxi(1, floori(le / 3.0))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_panes(cs, [g + 1.3, g + 4.6], 1.2, 1.6, PAL_GLASS_DARK, 0.05)
	# --- the door at the back of the recess on the west side
	kit_front(AUP_O, AUP_O + AUP_A)
	kit_front(_w(4.5, 11.41), _w(7.36, 11.34))
	kit_face(0.0)
	kit_door(1.43, g, 2.4, 0.6, AUP_TRIM, AUP_DOOR)
	kit_front(AUP_O, AUP_O + AUP_A)
	_collide(outline)


## The house of the Sister Disciples of the Divine Master (Dom Sióstr Uczennic Boskiego Mistrza,
## Żytnia, Wola): a five-storey 1990s convent in red brick, each column of windows set in a cream
## plaster strip, the entrance in a recess on the street front and the chapel's raised hipped
## block in the middle of the roof. A model that replaces the plain OpenStreetMap block (building
## 2846; no landmark until 2026-11-15). From seven Mapillary photos along the street to its north,
## Żytnia (refs/churches/uczennice_boskiego_mistrza, reference only, never shipped), the OSM outline and
## GUGiK's LoD2 (over the ground: the roof about 19, the chapel block's ridge about 23). The back
## walls and the chapel block's colour are defaults (docs/QUESTIONS.md).
## Spec docs/landmarks/specs/uczennice_boskiego_mistrza.md.
## Frame: origin at the front's west corner, u to the east along the street, +v to the south,
## into the block; the front faces the street (-v).
const UBM_O := Vector2(-2919.2, -669.7)
const UBM_A := Vector2(0.973, -0.231)
const UBM_BRICK := Color("#a5503a")     ## the red brick (photos)
const UBM_CREAM := Color("#e9dfc6")     ## the plaster strips round the windows (photos)
const UBM_CAP := Color("#7e3d2e")       ## the brick coping
const UBM_ROOF := Color("#6d6a66")      ## the flat roof and the chapel block's sheet roof (a default)
const UBM_DOOR := Color("#3a3533")      ## the entrance's glass and frames


func _build_uczennice_boskiego_mistrza(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(UBM_O, UBM_O + UBM_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var top := g + 19.0
	_prism(outline, g - 1.0, top, UBM_BRICK, UBM_ROOF, M_STONE, M_STONE)
	kit_cornice_ring(outline, top - 0.5, UBM_CAP, 0.6, 0.12)
	# the chapel's raised block on the roof, under a low hipped roof (LoD2)
	var chapel := _rect(23.0, 19.25, 5.8, 6.6)
	_prism(chapel, top - 0.2, g + 21.0, UBM_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_hip(23.0, 19.25, 6.0, 6.8, g + 21.0, 2.0, UBM_ROOF)
	# --- every wall: a cream strip behind each column of windows, wide windows on the ground floor
	var n := outline.size()
	for k in n:
		kit_front(UBM_O, UBM_O + UBM_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 3.0:
			continue
		var m := maxi(1, floori(le / 3.3))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_face(0.0)
		for c: float in cs:
			_kbox(c - 0.85, c + 0.85, -0.02, 0.04, g + 3.8, top - 1.2, UBM_CREAM)
		kit_face(0.04)
		kit_panes(cs, [g + 4.6, g + 8.0, g + 11.4, g + 14.8], 1.1, 1.8, PAL_GLASS_DARK, 0.04)
		kit_face(0.0)
		kit_panes(cs, [g + 0.9], 1.7, 2.1, PAL_GLASS_DARK, 0.05)
		kit_ledge(0.0, le, g + 3.4, 0.3, UBM_CAP, 0.08)
	# --- the entrance at the back of the recess on the street
	kit_front(UBM_O, UBM_O + UBM_A)
	kit_front(_w(16.73, 3.97), _w(20.93, 4.04))
	kit_face(0.0)
	kit_door(2.1, g, 2.8, 1.3, UBM_CAP, UBM_DOOR)
	kit_front(UBM_O, UBM_O + UBM_A)
	_collide(outline)


## The Generalate of the Congregation of the Servants of Jesus (Dom Generalny Zgromadzenia Sióstr
## Sług Jezusa, Sewerynów, Śródmieście): a six-storey house in ochre plaster on its street, tall windows in
## even rows, a plain band over the ground floor and the entrance under a small metal canopy, a
## hipped roof and a wing into the yard. A model that replaces the plain OpenStreetMap block
## (building 835; no landmark until 2026-11-15). From two Mapillary photos up the street (2020,
## refs/churches/sluzki_dom_generalny, reference only, never shipped), the OSM outline and GUGiK's
## LoD2 (over the ground: the eaves about 19.5, the ridge about 23). The roof colour and the yard
## walls are defaults (docs/QUESTIONS.md). Spec docs/landmarks/specs/sluzki_dom_generalny.md.
## Frame: origin at the front's south corner, u to the north-north-west along the street, +v to
## the east-north-east, into the block; the front faces the street (-v).
const SLJ_O := Vector2(-206.4, -500.9)
const SLJ_A := Vector2(-0.400, -0.917)
const SLJ_WALL := Color("#e3c48e")      ## the ochre plaster (photos)
const SLJ_TRIM := Color("#efe2c4")      ## window reveals, bands, cornice
const SLJ_ROOF := Color("#6b6c6c")      ## sheet roof (a default)
const SLJ_DOOR := Color("#5a4632")      ## the wooden door


func _build_sluzki_dom_generalny(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(SLJ_O, SLJ_O + SLJ_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 19.5
	_prism(outline, g - 1.0, eave, SLJ_WALL, SLJ_ROOF.darkened(0.2), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.45, SLJ_TRIM, 0.45, 0.35)
	kit_ledge_ring(outline, g - 1.0, 1.2, SLJ_WALL.darkened(0.12), 0.05)
	_hip(14.15, 8.85, 14.15, 8.85, eave, 3.5, SLJ_ROOF)      # the range on the street
	_hip(23.7, 22.2, 4.8, 7.45, eave, 3.0, SLJ_ROOF)         # the wing into the yard
	# --- every wall: six rows of tall windows, a band over the ground floor
	var rows := [g + 1.3, g + 4.7, g + 8.0, g + 11.3, g + 14.6]
	var n := outline.size()
	for k in n:
		kit_front(SLJ_O, SLJ_O + SLJ_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 3.0:
			continue
		var m := maxi(1, floori(le / 2.9))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_ledge(0.0, le, g + 3.6, 0.35, SLJ_TRIM, 0.08)
		kit_panes(cs, rows, 1.15, 2.0, PAL_GLASS_DARK, 0.05)
		kit_panes(cs, [g + 17.4], 1.15, 1.4, PAL_GLASS_DARK, 0.05)
	# --- the entrance near the south corner, under its metal canopy
	kit_front(SLJ_O, SLJ_O + SLJ_A)
	kit_front(_w(6.29, 0.34), _w(28.26, 0.0))
	kit_face(0.0)
	kit_door(1.6, g, 2.6, 0.75, SLJ_TRIM, SLJ_DOOR)
	_kbox(0.5, 2.7, -1.1, 0.0, g + 2.95, g + 3.1, Color("#3c3e40"))
	kit_front(SLJ_O, SLJ_O + SLJ_A)
	_collide(outline)


## The house of the Sisters of Our Lady of Mercy on Żytnia (Zgromadzenie Sióstr Matki Bożej
## Miłosierdzia, Żytnia 3/9, Wola), the range on the street west of St Faustina's shrine: four
## storeys of red brick over a pale plinth, each column of windows in a white strip, the white
## stone portal with its little gable and a low gabled roof. A model that replaces the plain
## OpenStreetMap block (building 2785, an unnamed `religious` building; no landmark until
## 2026-11-15). From six Mapillary photos on Żytnia (2020-2021, refs/churches/wola_2785, reference
## only, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the eaves about 15.5,
## the ridge about 18). The roof colour and the yard walls are defaults (docs/QUESTIONS.md).
## Spec docs/landmarks/specs/siostry_milosierdzia_zytnia.md.
## Frame: origin at the front's west corner, u to the east along Żytnia, +v to the south, into the
## block; the front faces Żytnia (-v).
const MBM_O := Vector2(-2813.5, -695.3)
const MBM_A := Vector2(0.965, -0.262)
const MBM_BRICK := Color("#a24f3a")     ## the red brick (photos)
const MBM_WHITE := Color("#ebe8e1")     ## the window strips and the portal (photos)
const MBM_PLINTH := Color("#c9c8c2")    ## the pale plinth (photos)
const MBM_ROOF := Color("#5f6163")      ## sheet roof (a default)
const MBM_DOOR := Color("#5b3d2a")      ## the wooden door


func _build_siostry_milosierdzia_zytnia(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(MBM_O, MBM_O + MBM_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 15.5
	_prism(outline, g - 1.0, eave, MBM_BRICK, MBM_ROOF.darkened(0.2), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.4, MBM_BRICK.darkened(0.2), 0.4, 0.2)
	kit_ledge_ring(outline, g - 1.0, 2.5, MBM_PLINTH, 0.06)
	_gable(41.6, 0.0, 8.1, 8.2, eave, 2.5, MBM_BRICK, MBM_ROOF, true)
	# --- every wall: a white strip behind each column of windows, barred windows in the plinth
	var n := outline.size()
	for k in n:
		kit_front(MBM_O, MBM_O + MBM_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 3.0:
			continue
		var m := maxi(1, floori(le / 3.3))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_face(0.06)
		for c: float in cs:
			_kbox(c - 0.8, c + 0.8, -0.02, 0.04, g + 1.6, eave - 1.0, MBM_WHITE)
		kit_face(0.1)
		kit_panes(cs, [g + 2.0, g + 5.4, g + 8.8, g + 12.1], 1.1, 2.0, PAL_GLASS_DARK, 0.04)
		kit_face(0.06)
		kit_panes(cs, [g + 0.2], 0.9, 0.7, PAL_GLASS_DARK, 0.04)
	# --- the white stone portal in the middle of the front, under its little gable
	kit_front(MBM_O, MBM_O + MBM_A)
	kit_face(-0.51)
	_kbox(18.3, 23.4, -0.25, 0.0, g - 0.5, g + 4.6, MBM_WHITE)
	kit_face(-0.76)
	kit_door(20.85, g, 3.0, 0.9, MBM_WHITE.darkened(0.08), MBM_DOOR, true)
	# the gable over it: a frame along the portal's axis (u' out of the wall, v' along u)
	kit_front(_w(20.85, 0.0), _w(20.85, -1.0))
	_gable(0.8, 0.0, 0.0, 2.6, g + 4.6, 1.4, MBM_WHITE, MBM_WHITE.darkened(0.1), false)
	kit_front(MBM_O, MBM_O + MBM_A)
	_collide(outline)

## The rest of the Sisters of Our Lady of Mercy's convent round St Faustina's shrine (Zgromadzenie
## Sióstr Matki Bożej Miłosierdzia, Żytnia 3/9, Wola): the house on the street east of the church
## (OSM 4468), the long wing that runs north from it (4469) and the house north of the church
## (10477), unnamed `religious` buildings. Their roofs are irregular (hips and gables at several
## heights), so the mass stays GUGiK's LoD2 in a skin: white plaster like the church's (photos of
## the shrine, refs/churches/faustina_zytnia, and two Mapillary photos on Żytnia, reference only,
## never shipped) under the church's grey roofs. The church is `church_miloserdzie`, the brick range
## on the street `church_siostry_milosierdzia_zytnia`. Spec docs/landmarks/specs/faustyna_klasztor.md.
const FKL_AT := [Vector2(-2735.0, -713.0), Vector2(-2718.0, -700.0), Vector2(-2760.0, -658.0)]  ## one point inside each outline
const FKL_WALL := Color("#ece9e2")      ## white plaster (the shrine's, photos)
const FKL_ROOF := Color("#606366")      ## grey sheet roofs (the church's, photos)

## The two houses of the Sisters of Charity's grounds north of their convent on Tamka, by Zaułek Ku
## Szarytkom (OSM 2380, the tall one with a steep gable roof, and 2379, the low one east of it;
## unnamed `religious` buildings). No photo shows them: the street photos near them look along Tamka,
## and the convent's Commons photos (refs/churches/szarytki_tamka, reference only, never shipped)
## show the ranges round the courtyard. Provisional: the mass stays GUGiK's LoD2 in the convent's
## white plaster and green copper (`szarytki`'s skin), until a photo of them turns up. Spec
## docs/landmarks/specs/szarytki_zaulek.md.
const SZZ_AT := [Vector2(66.0, -262.0), Vector2(100.0, -278.0)]  ## one point inside each outline

## Dom Parafialny im. Prymasa Tysiąclecia, St Barbara's parish house on Świętej Barbary (OSM
## building 1525, the only named one of these blocks): a pale yellow plastered house along the
## street's west side, its back block taller. Its outline is ragged (18 corners) and its LoD2 has
## two heights, so the mass stays GUGiK's LoD2 in a skin: yellow plaster from three Mapillary
## photos along Świętej Barbary (2020, refs/churches/dom_parafialny_barbara, reference only, never
## shipped), which show it only at a slant behind trees, under a grey roof (a default). Spec
## docs/landmarks/specs/dom_parafialny_barbara.md.
const DPB_AT := Vector2(-1166.0, 740.0)      ## inside the outline
const DPB_WALL := Color("#e6d49e")           ## pale yellow plaster (photos)
const DPB_ROOF := Color("#6c6a66")           ## grey roof, a default

## Dom przy kościele Świętej Trójcy na Solcu (Holy Trinity parish's house, Powiśle): OSM building 1000,
## `religious`, beside Holy Trinity on Solec, Powiśle. Its mass stays the map's block in a skin in the colours of
## Holy Trinity church on Solec (`church_trojca_praga`, SL_*): no open photo within 45 m, so it is provisional.
## Spec docs/landmarks/specs/solec_dom.md.
const SLD_AT := Vector2(1079.7, 297.8)
const SLD_WALL := Color("#e2d6bc")
const SLD_ROOF := Color("#63696e")

## Dom zakonny Księży Misjonarzy (the back wing of the Missionaries' house, Krakowskie Przedmieście): OSM building 5803,
## `monastery`, behind the Missionaries' house by Holy Cross, Krakowskie Przedmieście. Its mass stays the map's block in a skin in the colours of
## the Missionaries' house on Krakowskie Przedmieście (`church_misjonarze`, MS_*): no open photo reaches the yard behind the street wing, so it is provisional.
## Spec docs/landmarks/specs/misjonarze_tyl.md.
const MST_AT := Vector2(-519.4, -546.9)
const MST_WALL := Color("#d7c08a")
const MST_ROOF := Color("#5b5d60")

## Plebania parafii Narodzenia NMP (the presbytery of the Nativity church on Leszno, Wola): OSM building 10100,
## `presbytery`, behind the Nativity church on Leszno, Wola. Its mass stays the map's block in a skin in the colours of
## the Nativity of the Virgin Mary church on Leszno (`church_narodzenia`, NR_*): one Mapillary photo within 45 m faces it at a steep slant from 42 m (2022), too far and too slanted to read, so it is provisional.
## Spec docs/landmarks/specs/plebania_leszno.md.
const PLS_AT := Vector2(-1991.4, -975.4)
const PLS_WALL := Color("#d49885")
const PLS_ROOF := Color("#a3553f")

## The low house east of the Franciscan Sisters of the Family of Mary's convent (OSM building 10482,
## `religious`, unnamed, Wola), at the street corner beside the long banded house
## (`church_rodziny_maryi`, RM_*). Its mass stays the map's block in a skin: the convent's warm peach
## plaster (RM_WALL) under green copper, from Mapillary photos along the street (2020-2021,
## refs/churches/religious_10482, reference only, never shipped), which show a low pavilion with a
## green hipped roof behind the iron railings and gate pavilions. Spec
## docs/landmarks/specs/rodziny_maryi_pawilon.md.
const RMP_AT := Vector2(-2595.0, -765.0)
const RMP_WALL := Color("#e6c2a2")
const RMP_ROOF := Color("#7f9e86")

## The parish house of Our Lady of Częstochowa on Zagórna (OSM building 2197, `presbytery`,
## unnamed, Powiśle): the block joined to the back of the 1960s church (`church_czestochowska`, MC_*).
## Its mass stays the map's block in a skin: the church's grey render (MC_WALL) from two Mapillary
## photos at its south-west corner (2026, refs/churches/plebania_2197, reference only, never shipped),
## which show the grey wall with gold window frames, the gilt Mass-times cross and the stair down;
## the roof is a grey default. Spec docs/landmarks/specs/plebania_zagorna.md.
const PZG_AT := Vector2(1145.0, 846.0)
const PZG_WALL := Color("#c8c5be")
const PZG_ROOF := Color("#6c6a66")

## The Pallottine fathers' house on Skaryszewska (OSM building 3049, `monastery`, unnamed, Praga):
## the tall block at the north corner of the Christ the King church's plot (`church_chrystusa_krola`,
## CK_*). Its mass stays the map's block (17.5 m) in a skin in the parish wings' plaster and grey roof
## (CK_WING, CK_TILE). No open photo faces it (one Mapillary photo within 45 m, looking away), so
## it is provisional. Spec docs/landmarks/specs/pallotyni_dom.md.
const PDM_AT := Vector2(1745.0, -1650.0)
const PDM_WALL := Color("#e6dcc4")
const PDM_ROOF := Color("#8a8a84")

## The presbytery of Christ the King on Skaryszewska (Plebania, OSM building 6054, Praga, the
## Pallottines' parish): a low house at the west corner of the church's block (`church_chrystusa_krola`,
## CK_*), beside the cream chapel on the street. Its mass stays the map's block in a skin in the parish
## wings' plaster and grey roof (CK_WING, CK_TILE), from eight Mapillary photos along Skaryszewska
## (2026, refs/churches/plebania_6054, reference only, never shipped), which show the chapel's front
## and the iron fence and gate beside it; the house itself stands behind the fence. Spec
## docs/landmarks/specs/plebania_pallotynow.md.
const PPL_AT := Vector2(1709.0, -1676.0)
const PPL_WALL := Color("#e6dcc4")
const PPL_ROOF := Color("#8a8a84")

## The presbytery of Our Lady of Victory (Plebania, OSM building 394, Praga, 43 m from the church):
## a two-storey house behind iron railings on a stone wall. Its mass stays the map's block in a skin:
## cream plaster from two Mapillary photos down the street (2015, refs/churches/plebania_394,
## reference only, never shipped), which show its end wall over the railings and trees; the roof is
## a grey default. Spec docs/landmarks/specs/plebania_zwycieskiej.md.
const PZW_AT := Vector2(1928.0, -1366.0)
const PZW_WALL := Color("#e6d9b5")
const PZW_ROOF := Color("#6c6a66")


## The presbytery of St Florian's cathedral (Plebania katedry św. Floriana, Floriańska, Praga):
## an L of two plastered houses behind the cathedral. The range on Floriańska, three tall storeys
## under a gable roof, white plaster over a beige rusticated ground floor with round-headed
## windows, small caps over the upper windows and a cornice; its wing into the yard, three lower
## storeys in cream plaster with plain windows, ends in a low flat-roofed block. A model that
## replaces the plain OpenStreetMap block (building 899, `presbytery`; no landmark until
## 2026-11-15). From five Mapillary photos (2019 and 2020, refs/churches/plebania_florian,
## reference only, never shipped), the OSM outline and GUGiK's LoD2 (over the ground: the range's
## eaves about 13.9 and ridge 16, the wing's eaves 12.1 and ridge 13.9, the low block 10.8). The
## roof colour is a default (docs/QUESTIONS.md). Spec docs/landmarks/specs/plebania_florian.md.
## Frame: origin at the street front's west corner, u to the east along Floriańska, +v into the
## block (north-north-west); the street front faces -v.
const PFL_O := Vector2(525.0, -1990.5)
const PFL_A := Vector2(0.9845, 0.1753)
const PFL_WALL := Color("#ece6d8")      ## the range's white plaster (photos)
const PFL_BASE := Color("#d8c8a6")      ## the beige rusticated ground floor (photos)
const PFL_WING := Color("#e8d8ad")      ## the yard wing's cream plaster (photos)
const PFL_TRIM := Color("#f4f1ea")      ## window frames, caps, bands, cornice
const PFL_ROOF := Color("#55504c")      ## dark sheet roofs (a default)
const PFL_DOOR := Color("#6a4a30")      ## the wooden doors (photos)


## The church house at Kłopotowskiego 18 (Praga, a block south of St Florian's), the one with
## the "Okno Życia" window of life by its door: four storeys on the street, white plaster over a
## cream rusticated ground floor on a grey plinth, a grey stone door surround under a dark canopy,
## an iron balcony over the window of life, a hipped roof; a lower wing runs into the yard. A
## model that replaces the plain OpenStreetMap block (building 8886, `religious`, unnamed; no
## landmark until 2026-11-15). From eight Mapillary photos along Kłopotowskiego (2020 to 2026,
## refs/churches/klopotowskiego_8886, reference only, never shipped), the OSM outline and GUGiK's
## LoD2 (over the ground: the street range's eaves about 13.2 and ridge 17, the wing's roof 13 to
## 15). The roof colour and the yard walls are defaults (docs/QUESTIONS.md). Spec
## docs/landmarks/specs/klopotowskiego_18.md.
## Frame: origin at the street front's west corner, u to the east-south-east along
## Kłopotowskiego, +v into the block; the street front faces -v.
const K18_O := Vector2(531.8, -1805.0)
const K18_A := Vector2(0.8193, -0.5604)
const K18_WALL := Color("#ecebe6")      ## white plaster over the ground floor (photos)
const K18_BASE := Color("#e4dcbc")      ## the cream rusticated ground floor (photos)
const K18_PLINTH := Color("#9b9d9b")    ## the grey plinth (photos)
const K18_STONE := Color("#a9aba8")     ## the door's grey stone surround (photos)
const K18_TRIM := Color("#f5f4f0")      ## window caps, bands, cornice
const K18_FRAME := Color("#4e3a2c")     ## the dark brown window frames (photos)
const K18_ROOF := Color("#5d5f60")      ## sheet roof (a default)
const K18_DOOR := Color("#5b3528")      ## the brown door (photos)


## The monastery block beside Our Lady of Victory (Kamionek, Praga Południe), east of the
## co-cathedral: a five-storey plastered range under a red tile gable roof with two chimneys, a
## short projection into the yard. A model that replaces the plain OpenStreetMap block (building
## 1334, `monastery`, unnamed; no landmark until 2026-11-15) from the OSM outline and GUGiK's LoD2
## (over the ground: the eaves about 15.9, the ridge 17.9 along the range). **Provisional, no
## photo**: no open street photo reaches it, so the plaster, the tiles, the windows and the door
## follow the church next door (docs/QUESTIONS.md). Spec docs/landmarks/specs/zwycieska_klasztor.md.
## Frame: origin at the north front's west corner, u to the east along the range, +v to the south
## into the yard; the front faces north (-v), towards Grochowska.
const ZWK_O := Vector2(2016.9, -1370.6)
const ZWK_A := Vector2(0.9933, 0.1158)
const ZWK_WALL := Color("#e6dfcc")      ## cream plaster (a default, the church's tone)
const ZWK_TRIM := Color("#f2eee3")      ## bands, cornice, window reveals
const ZWK_ROOF := Color("#b0583b")      ## red tiles (a default, the church's)
const ZWK_DOOR := Color("#5b3326")      ## the wooden door (a default, the church's)


## The convent range on Żytnia's south side, opposite the Wolność corner, between St Faustina's
## convent and the Family of Mary sisters' church (unnamed `religious` building 4473, Wola): two
## storeys of cream plaster on a red brick plinth, a rusticated ground floor with barred windows,
## a band, upper windows with sills and caps, a cornice and a grey gable roof. A model that
## replaces the plain OpenStreetMap block (no landmark until 2026-11-15). From four Mapillary
## photos along Żytnia and one across the Wolność corner (2020 and 2025,
## refs/churches/rodziny_maryi_dom, reference only, never shipped), the OSM outline and GUGiK's
## LoD2 (over the ground: the eaves about 7.8, the ridge 9.8). The yard side is a default
## (docs/QUESTIONS.md). Spec docs/landmarks/specs/zytnia_dom_zakonny.md.
## Frame: origin at the street front's west corner on Wolność, u to the east-south-east along
## Żytnia, +v to the south into the block; the front faces north (-v), onto the street.
const ZYT_O := Vector2(-2699.1, -732.6)
const ZYT_A := Vector2(0.9307, -0.3657)
const ZYT_WALL := Color("#e9d8b2")      ## the cream plaster (photos)
const ZYT_BRICK := Color("#8b4a36")     ## the red brick plinth (photos)
const ZYT_TRIM := Color("#f1e8d2")      ## sills, caps, band, cornice
const ZYT_FRAME := Color("#6a3f2a")     ## the brown window frames (photos)
const ZYT_ROOF := Color("#55585c")      ## grey sheet roof (photos)


func _build_zytnia_dom_zakonny(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(ZYT_O, ZYT_O + ZYT_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 7.8
	_prism(outline, g - 1.0, eave, ZYT_WALL, ZYT_ROOF.darkened(0.1), M_STONE, M_STONE)
	kit_cornice_ring(outline, eave - 0.1, ZYT_TRIM, 0.4, 0.3)
	_gable(-0.2, 40.0, 4.0, 4.3, eave, 2.0, ZYT_WALL, ZYT_ROOF, true)
	# --- every wall: the brick plinth, the rusticated ground floor, a band, two rows of windows
	var n := outline.size()
	for k in n:
		kit_front(ZYT_O, ZYT_O + ZYT_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 2.6:
			continue
		var m := maxi(1, floori(le / 3.2))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		_kbox(0.0, le, 0.0, 0.06, g - 1.0, g + 1.0, ZYT_BRICK)
		for yb: float in [g + 1.9, g + 2.7]:
			_kbox(0.0, le, 0.0, 0.03, yb, yb + 0.06, ZYT_WALL.darkened(0.12))
		kit_ledge(0.0, le, g + 3.6, 0.25, ZYT_TRIM, 0.1)
		kit_panes(cs, [g + 1.3], 1.3, 1.7, PAL_DARK_DOOR, 0.05)
		kit_panes(cs, [g + 1.35], 1.15, 1.6, PAL_GLASS_DARK, 0.07)
		kit_panes(cs, [g + 4.6], 1.3, 2.0, ZYT_FRAME, 0.04)
		kit_panes(cs, [g + 4.7], 1.1, 1.8, PAL_GLASS_DARK, 0.06)
		kit_panes(cs, [g + 4.45], 1.6, 0.14, ZYT_TRIM, 0.11)
		kit_panes(cs, [g + 6.75], 1.5, 0.18, ZYT_TRIM, 0.1)
	kit_front(ZYT_O, ZYT_O + ZYT_A)
	_collide(outline)


## The long range inside the block behind the convent range on Żytnia (unnamed `religious`
## building 10480, Wola), south of `church_zytnia_dom_zakonny`, its north wall on the yard between
## them: two storeys under a low grey roof, a lower annex at its east end. A model that replaces
## the plain OpenStreetMap block (no landmark until 2026-11-15) from the OSM outline and GUGiK's
## LoD2 (over the ground: the eaves about 6.4, the roof to 8). **Provisional, no photo**: no open
## photo reaches the yard, so its walls follow the street range in front (the same cream plaster
## on a brick plinth, barred ground-floor windows, capped upper windows; docs/QUESTIONS.md).
## Spec docs/landmarks/specs/zytnia_dom_zakonny_tyl.md.
## Frame: origin at the north wall's west corner, u to the east-north-east, +v to the south; the
## north wall faces the yard (-v).
const ZYB_O := Vector2(-2679.6, -701.0)
const ZYB_A := Vector2(0.9514, -0.3084)


func _build_zytnia_dom_zakonny_tyl(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(ZYB_O, ZYB_O + ZYB_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 6.4
	var main := _largest(Geometry2D.intersect_polygons(outline, _rect(25.9, 4.2, 27.9, 4.5)))
	var east := _largest(Geometry2D.intersect_polygons(outline, _rect(60.15, 4.2, 6.35, 4.5)))
	_prism(main, g - 1.0, eave, ZYT_WALL, ZYT_ROOF.darkened(0.1), M_STONE, M_STONE)
	_prism(east, g - 1.0, g + 5.2, ZYT_WALL, ZYT_ROOF.lightened(0.1), M_STONE, M_STONE)
	kit_cornice_ring(main, eave - 0.1, ZYT_TRIM, 0.35, 0.3)
	_gable(-0.2, 53.8, 4.2, 4.6, eave, 1.6, ZYT_WALL, ZYT_ROOF, true)
	# --- every wall: the brick plinth, the rusticated ground floor, a band, two rows of windows
	var n := outline.size()
	for k in n:
		kit_front(ZYB_O, ZYB_O + ZYB_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 2.6:
			continue
		var m := maxi(1, floori(le / 3.2))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		_kbox(0.0, le, 0.0, 0.06, g - 1.0, g + 0.9, ZYT_BRICK)
		for yb: float in [g + 1.6, g + 2.3]:
			_kbox(0.0, le, 0.0, 0.03, yb, yb + 0.06, ZYT_WALL.darkened(0.12))
		kit_ledge(0.0, le, g + 3.0, 0.25, ZYT_TRIM, 0.1)
		kit_panes(cs, [g + 1.1], 1.3, 1.6, PAL_DARK_DOOR, 0.05)
		kit_panes(cs, [g + 1.15], 1.15, 1.5, PAL_GLASS_DARK, 0.07)
		kit_panes(cs, [g + 3.7], 1.3, 1.8, ZYT_FRAME, 0.04)
		kit_panes(cs, [g + 3.8], 1.1, 1.6, PAL_GLASS_DARK, 0.06)
		kit_panes(cs, [g + 3.55], 1.6, 0.14, ZYT_TRIM, 0.11)
		kit_panes(cs, [g + 5.55], 1.5, 0.18, ZYT_TRIM, 0.1)
	kit_front(ZYB_O, ZYB_O + ZYB_A)
	_collide(outline)


## The small octagonal chapel at the north-west corner of St Florian's cathedral close, by the
## fence on Floriańska (unnamed `chapel`, OSM building 6848, Praga): red brick walls about 3.6 m
## high under a brick cornice, and a dark slate bell roof that flares at the eaves, with a small
## finial. A model that replaces the plain OpenStreetMap block (no landmark until 2026-11-15).
## From eight Mapillary photos on Floriańska (2018-2020, refs/churches/kaplica_florianska,
## reference only, never shipped): five show it beside the cathedral's front, behind the brick
## fence with its niched posts. GUGiK has no LoD2 for it. The door and the side away from the
## street are defaults (docs/QUESTIONS.md). Spec docs/landmarks/specs/kaplica_florianska.md.
const KFL_BRICK := Color("#9b4535")     ## the red brick (photos, like the cathedral's)
const KFL_DARK := Color("#7e3528")      ## the cornice's darker brick
const KFL_SLATE := Color("#3b3d42")     ## the dark slate bell roof (photos)
const KFL_DOOR := Color("#3a2a22")


## `ring` grown or shrunk by `s` about its centre.
func _kfl_scaled(ring: PackedVector2Array, s: float) -> PackedVector2Array:
	var c := _centre(ring)
	var out := PackedVector2Array()
	for p in ring:
		out.append(c + (p - c) * s)
	return out


func _build_kaplica_florianska(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_o = _centre(outline)
	_a = Vector2(1.0, 0.0)
	_b = Vector2(0.0, 1.0)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var eave := g + 3.6
	_prism(outline, g - 0.8, eave, KFL_BRICK, Color(0, 0, 0, 0), M_STONE)
	# the plinth and the cornice: two darker brick rings
	kit_ledge_ring(outline, g - 0.8, 1.2, KFL_DARK, 0.06)
	kit_ledge_ring(outline, eave - 0.45, 0.45, KFL_DARK, 0.14)
	# the bell roof: flared at the eaves, swelling, then drawn in to the finial
	var r0 := _kfl_scaled(outline, 1.12)
	var r1 := _kfl_scaled(outline, 1.0)
	var r2 := _kfl_scaled(outline, 0.78)
	var r3 := _kfl_scaled(outline, 0.42)
	_frustum(r0, eave, r1, eave + 0.7, KFL_SLATE)
	_frustum(r1, eave + 0.7, r2, eave + 2.0, KFL_SLATE.lightened(0.04))
	_frustum(r2, eave + 2.0, r3, eave + 3.0, KFL_SLATE)
	_pyramid(r3, eave + 3.0, eave + 3.6, KFL_SLATE.lightened(0.04))
	# the finial: a slim shaft with a small ball
	var c := _centre(outline)
	_prism(_circle(c, 0.07, 4), eave + 3.5, eave + 4.4, KFL_SLATE, KFL_SLATE, M_STONE, M_STONE)
	_frustum(_circle(c, 0.12, 6), eave + 4.1, _circle(c, 0.2, 6), eave + 4.25, KFL_SLATE.lightened(0.1), KFL_SLATE.lightened(0.1))
	# a door on the side towards the cathedral (east), a default: no photo shows it
	var n := outline.size()
	var best := 0
	for k in n:
		if _out(outline, outline[k], outline[(k + 1) % n]).dot(Vector2(1.0, 0.0)) > _out(outline, outline[best], outline[(best + 1) % n]).dot(Vector2(1.0, 0.0)):
			best = k
	var le := kit_front(outline[(best + 1) % n], outline[best])
	kit_door(le * 0.5, g, 2.3, 0.55, KFL_DARK, KFL_DOOR, true)
	_o = c
	_a = Vector2(1.0, 0.0)
	_b = Vector2(0.0, 1.0)
	_collide(outline)

## A small flat-roofed yard chapel from LoD2 and its OSM outline, for the unnamed `chapel`
## buildings inside blocks that no photo reaches: plastered walls on a grey plinth to `h` over the
## ground, a coping, tall narrow windows along every wall at least 4 m long, an arched door in the
## middle of the wall nearest `door_out`, and a small cross on the roof. **Provisional**: every
## part of it is a default until a photo turns up (docs/QUESTIONS.md).
func _flat_chapel(outline: PackedVector2Array, h: float, wall: Color, door_out: Vector2) -> void:
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var top := g + h
	_prism(outline, g - 0.8, top, wall, PAL_ROOF_GRAVEL, M_STONE, M_STONE)
	kit_ledge_ring(outline, g - 0.8, 1.2, PAL_GREY_STONE, 0.05)
	kit_ledge_ring(outline, top - 0.3, 0.45, wall.lightened(0.15), 0.12)
	var n := outline.size()
	var door := 0
	for k in n:
		var dk := _out(outline, outline[k], outline[(k + 1) % n]).dot(door_out) * outline[k].distance_to(outline[(k + 1) % n])
		var db := _out(outline, outline[door], outline[(door + 1) % n]).dot(door_out) * outline[door].distance_to(outline[(door + 1) % n])
		if dk > db:
			door = k
	for k in n:
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 4.0:
			continue
		var m := maxi(1, floori(le / 2.6))
		var cs: Array = []
		for i in m:
			var u := (float(i) + 0.5) * le / float(m)
			if k == door and absf(u - le * 0.5) < 1.4:
				continue
			cs.append(u)
		kit_panes(cs, [g + 1.4], 0.9, 2.6, wall.darkened(0.25), 0.04)
		kit_panes(cs, [g + 1.5], 0.7, 2.4, PAL_GLASS_DARK, 0.06)
		if k == door:
			kit_door(le * 0.5, g, 2.6, 0.75, wall.lightened(0.15), PAL_DARK_DOOR, true)
	# the cross on the roof, over the door's end
	var c := _centre(outline)
	var dl := kit_front(outline[(door + 1) % n], outline[door])
	_kbox(dl * 0.5 - 0.07, dl * 0.5 + 0.07, -1.6, -1.46, top, top + 1.6, PAL_IRON)
	_kbox(dl * 0.5 - 0.45, dl * 0.5 + 0.45, -1.6, -1.46, top + 0.95, top + 1.09, PAL_IRON)
	_collide(outline)
	_o = c



## The yard chapel behind Łucka 2/4/6, off Żelazna (unnamed `chapel`, OSM building 7458, Wola):
## a single storey about 5.3 m tall under a flat roof (GUGiK's LoD2), in a pale plaster. A model
## that replaces the plain OpenStreetMap block (no landmark until 2026-11-15). **Provisional, no
## photo**: no open street photo reaches the yard (refs/churches/kaplica_zelazna is empty), so the
## walls, windows, door and cross are `_flat_chapel`'s defaults; the door faces the houses on
## Łucka (docs/QUESTIONS.md). Spec docs/landmarks/specs/kaplica_lucka.md.
const KLU_WALL := Color("#e4dccb")      ## pale plaster, a default


func _build_kaplica_lucka(site: Dictionary) -> void:
	_flat_chapel(site["outline"], 5.3, KLU_WALL, Vector2(0.3, 0.95))


## The yard chapel behind Hoża 55 (unnamed `chapel`, OSM building 8734, Śródmieście Południowe): a
## long single storey about 5.8 m tall under a flat roof (GUGiK's LoD2), its short north end
## towards Hoża. A model that replaces the plain OpenStreetMap block (no landmark until
## 2026-11-15). **Provisional, no photo**: the twelve street photos within 45 m look along Hoża
## and none faces the yard (refs/churches/kaplica_8734 is empty), so the walls, windows, door and
## cross are `_flat_chapel`'s defaults (docs/QUESTIONS.md). Spec docs/landmarks/specs/kaplica_hoza.md.
const KHZ_WALL := Color("#ddd6c8")      ## pale grey-cream plaster, a default


func _build_kaplica_hoza(site: Dictionary) -> void:
	_flat_chapel(site["outline"], 5.8, KHZ_WALL, Vector2(-0.356, -0.935))


func _build_zwycieska_klasztor(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(ZWK_O, ZWK_O + ZWK_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var eave := g + 15.9
	_prism(outline, g - 1.0, eave, ZWK_WALL, none, M_STONE)
	kit_cornice_ring(outline, eave - 0.1, ZWK_TRIM, 0.45, 0.35)
	kit_ledge_ring(outline, g - 1.0, 1.5, ZWK_WALL.darkened(0.15), 0.06)
	_gable(-0.3, 36.1, 8.6, 9.05, eave, 2.0, ZWK_WALL, ZWK_ROOF, true)
	# the yard projection's roof: a small gable running into the yard, its ridge under the range's
	kit_front(_w(17.9, 13.0), _w(17.9, 14.0))
	_gable(0.0, 5.6, 0.0, 4.85, eave, 1.6, ZWK_WALL, ZWK_ROOF, true)
	kit_front(ZWK_O, ZWK_O + ZWK_A)
	# two chimneys (LoD2)
	_kbox(22.0, 23.2, 4.6, 6.6, eave, eave + 3.6, ZWK_WALL.darkened(0.08))
	_kbox(31.0, 32.2, 13.4, 15.2, eave, eave + 3.2, ZWK_WALL.darkened(0.08))
	# --- every wall: five rows of windows, a band over the ground floor
	var rows := [g + 1.2, g + 4.3, g + 7.4, g + 10.5, g + 13.6]
	var n := outline.size()
	for k in n:
		kit_front(ZWK_O, ZWK_O + ZWK_A)
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 2.6:
			continue
		var m := maxi(1, floori(le / 2.9))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_ledge(0.0, le, g + 3.6, 0.3, ZWK_TRIM, 0.08)
		kit_panes(cs, rows, 1.4, 1.95, ZWK_TRIM, 0.03)
		kit_panes(cs, rows, 1.15, 1.75, PAL_GLASS_DARK, 0.06)
	# --- the door in the middle of the north front
	kit_front(ZWK_O, ZWK_O + ZWK_A)
	kit_front(_w(34.53, 0.0), _w(0.0, 0.0))
	kit_face(0.06)
	kit_door(34.53 - 17.3, g, 2.8, 0.8, ZWK_TRIM, ZWK_DOOR)
	kit_face(0.0)
	kit_front(ZWK_O, ZWK_O + ZWK_A)
	_collide(outline)


func _build_klopotowskiego_18(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(K18_O, K18_O + K18_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var e_r := g + 13.2   # the street range's eaves
	var e_w := g + 13.4   # the yard wing's roof (LoD2's lean-to, built flat at its mean)
	var rng := _largest(Geometry2D.intersect_polygons(outline, _rect(10.9, 6.95, 11.5, 7.15)))
	var wing := _largest(Geometry2D.intersect_polygons(outline, _rect(19.5, 28.0, 4.5, 14.0)))
	_prism(rng, g - 1.0, e_r, K18_WALL, none, M_STONE)
	_prism(wing, g - 1.0, e_w, K18_WALL, K18_ROOF.lightened(0.1), M_STONE, M_STONE)
	kit_cornice_ring(rng, e_r - 0.1, K18_TRIM, 0.4, 0.35)
	_hip(10.7, 6.95, 10.95, 7.2, e_r, 3.8, K18_ROOF)
	# --- every wall: a cream rusticated ground floor on a grey plinth, white upper floors
	var rows := [g + 4.6, g + 7.6, g + 10.6]
	var n := outline.size()
	for k in n:
		kit_front(K18_O, K18_O + K18_A)
		var mid := (outline[k] + outline[(k + 1) % n]) * 0.5 - K18_O
		var mv := mid.dot(Vector2(-K18_A.y, K18_A.x))
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 2.6:
			continue
		var street := mv < 0.6
		var m := maxi(1, floori(le / 3.3))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		_kbox(0.0, le, 0.0, 0.05, g - 1.0, g + 0.7, K18_PLINTH)
		_kbox(0.0, le, 0.0, 0.04, g + 0.7, g + 3.7, K18_BASE)
		for yb: float in [g + 1.45, g + 2.2, g + 2.95]:
			_kbox(0.0, le, 0.04, 0.06, yb, yb + 0.06, K18_BASE.darkened(0.1))
		kit_ledge(0.0, le, g + 3.7, 0.25, K18_TRIM, 0.1)
		kit_panes(cs, rows, 1.5, 2.1, K18_FRAME, 0.03)
		kit_panes(cs, rows, 1.25, 1.9, PAL_GLASS_DARK, 0.06)
		if not street:
			kit_panes(cs, [g + 1.3], 1.25, 1.8, PAL_GLASS_DARK, 0.06)
	# --- the street front: the door at u 8 in its grey surround under the canopy, the window of
	# life beside it under the balcony, tall barred windows either side
	kit_front(K18_O, K18_O + K18_A)
	kit_front(_w(21.44, 0.0), _w(0.0, 0.0))
	var lu := 21.44
	for wu: float in [2.0, 4.6, 11.4, 14.6, 17.8]:
		kit_panes([lu - wu], [g + 1.2], 1.6, 2.2, K18_FRAME, 0.07)
		kit_panes([lu - wu], [g + 1.3], 1.4, 2.0, PAL_GLASS_DARK, 0.09)
		kit_panes([lu - wu], [g + 3.5], 1.9, 0.2, K18_TRIM, 0.1)
	_kbox(lu - 12.3, lu - 10.5, 0.0, 0.08, g + 3.45, g + 3.7, Color("#c8372d"))  # the red "Okno Życia" band
	_kbox(lu - 9.3, lu - 6.7, 0.0, 0.12, g, g + 2.9, K18_STONE)
	kit_face(0.12)
	kit_door(lu - 8.0, g, 2.7, 0.65, K18_STONE, K18_DOOR)
	_kbox(lu - 9.6, lu - 6.4, 0.0, 0.9, g + 2.95, g + 3.25, Color("#3a3634"))
	kit_face(0.0)
	kit_balcony(lu - 11.4, g + 4.6, 0.9, Balcony.IRON, Color("#2e2c2b"), K18_TRIM, 0.6)
	kit_front(K18_O, K18_O + K18_A)
	_collide(outline)


func _build_plebania_florian(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	kit_front(PFL_O, PFL_O + PFL_A)
	_g = _ground_under(outline)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var e_r := g + 13.9   # the range's eaves
	var e_w := g + 12.1   # the wing's eaves
	var e_l := g + 10.8   # the low block's flat roof
	var rng := _largest(Geometry2D.intersect_polygons(outline, _rect(15.0, 5.9, 16.5, 6.95)))
	var wing := _largest(Geometry2D.intersect_polygons(outline, _rect(14.5, 28.05, 8.5, 15.25)))
	var low := _largest(Geometry2D.intersect_polygons(outline, _rect(14.5, 46.5, 8.5, 3.2)))
	_prism(rng, g - 1.0, e_r, PFL_WALL, none, M_STONE)
	_prism(wing, g - 1.0, e_w, PFL_WING, none, M_STONE)
	_prism(low, g - 1.0, e_l, PFL_WING, PFL_ROOF.lightened(0.15), M_STONE, M_STONE)
	kit_cornice_ring(rng, e_r - 0.1, PFL_TRIM, 0.4, 0.35)
	kit_cornice_ring(wing, e_w - 0.1, PFL_TRIM, 0.3, 0.25)
	_gable(-0.3, 29.95, 6.4, 6.75, e_r, 2.1, PFL_WALL, PFL_ROOF, true)
	# the wing's ridge runs into the yard: a frame with u' along +v from the range's back
	kit_front(_w(14.55, 12.8), _w(14.55, 13.8))
	_gable(0.0, 30.6, 0.0, 6.95, e_w, 1.8, PFL_WING, PFL_ROOF, true)
	# --- every wall: the range has a rusticated ground floor, round-headed windows on the street,
	# capped windows above; the wing and the low block have plain rows
	var n := outline.size()
	for k in n:
		kit_front(PFL_O, PFL_O + PFL_A)
		var mid := (outline[k] + outline[(k + 1) % n]) * 0.5 - PFL_O
		var mv := mid.dot(Vector2(-PFL_A.y, PFL_A.x))
		var street := mv < 0.6
		var le := kit_front(outline[(k + 1) % n], outline[k])
		if le < 2.6:
			continue
		var m := maxi(1, floori(le / 2.7))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		if mv < 12.9:
			_kbox(0.0, le, 0.0, 0.05, g - 1.0, g + 4.4, PFL_BASE)
			for yb: float in [g + 1.0, g + 2.2, g + 3.4]:
				_kbox(0.0, le, 0.05, 0.07, yb, yb + 0.07, PFL_BASE.darkened(0.12))
			kit_ledge(0.0, le, g + 4.4, 0.3, PFL_TRIM, 0.12)
			kit_panes(cs, [g + 5.5, g + 9.3], 1.6, 2.7, PFL_TRIM, 0.03)
			kit_panes(cs, [g + 5.65, g + 9.45], 1.2, 2.4, PAL_GLASS_DARK, 0.06)
			kit_panes(cs, [g + 8.2, g + 12.0], 1.8, 0.25, PFL_TRIM, 0.09)
			if street:
				for c: float in cs:
					var pu := (_w(c, 0.0) - PFL_O).dot(PFL_A)
					if absf(pu - 3.0) > 1.4 and absf(pu - 9.0) > 1.6:
						kit_face(0.07)
						kit_door(c, g + 0.9, 2.7, 0.6, PFL_TRIM, PAL_GLASS_DARK, true)
						kit_face(0.0)
			else:
				kit_panes(cs, [g + 1.3], 1.1, 2.0, PAL_GLASS_DARK, 0.08)
		elif mv < 43.4:
			kit_panes(cs, [g + 1.2, g + 4.9, g + 8.6], 1.5, 2.15, PFL_TRIM, 0.03)
			kit_panes(cs, [g + 1.35, g + 5.05, g + 8.75], 1.2, 1.85, PAL_GLASS_DARK, 0.06)
		else:
			kit_panes(cs, [g + 1.3, g + 5.0], 1.2, 1.8, PAL_GLASS_DARK, 0.05)
	# --- the doors on Floriańska: a plain one near the west corner and the round-headed main door
	kit_front(PFL_O, PFL_O + PFL_A)
	kit_front(_w(29.66, 0.0), _w(0.0, 0.0))
	kit_face(0.07)
	kit_door(29.66 - 3.0, g, 2.6, 0.7, PFL_TRIM, PFL_DOOR)
	kit_door(29.66 - 9.0, g, 3.4, 0.85, PFL_TRIM, PFL_DOOR, true)
	kit_front(PFL_O, PFL_O + PFL_A)
	_collide(outline)


const SZT_WALL := Color("#e9e7e0")           ## white plaster (photos 01, 03, 11)
const SZT_ROOF := Color("#7c9171")           ## dull green copper (photos 01, 02)
const SZT_TURRET := Vector2(57.0, -162.0)    ## where the south range meets the west one (a default: photo 02)
const SZT_RIDGE := 8.4                       ## LoD2's ridge there (absolute y)


func _build_szarytki(_site: Dictionary) -> void:
	_o = SZT_TURRET
	_a = Vector2(1.0, 0.0)
	_b = Vector2(0.0, 1.0)
	_g = SZT_RIDGE - 14.0
	var keep := _mode
	_mode = M_STONE
	var y := SZT_RIDGE - 0.6
	var copper := SZT_ROOF.lightened(0.08)
	# the square base astride the ridge, the white drum with its openings, the onion, the cross
	_lbox(0.0, 0.0, 1.0, 1.0, y, y + 1.4, copper)
	kit_lantern(0.0, 0.0, y + 1.4, 2.6, 0.75, SZT_WALL, copper, PAL_GLASS_DARK, 8)
	var c := _w(0.0, 0.0)
	var top := y + 1.4 + 2.6 * 0.7 + 0.15
	_frustum(_circle(c, 0.55, 8), top, _circle(c, 0.95, 8), top + 0.7, copper)
	_frustum(_circle(c, 0.95, 8), top + 0.7, _circle(c, 0.25, 8), top + 1.6, copper)
	_prism(_circle(c, 0.08, 4), top + 1.6, top + 2.6, copper, copper, M_STONE, M_STONE)
	_lbox(0.0, 0.0, 0.32, 0.05, top + 2.2, top + 2.3, copper)
	_mode = keep


## The Seventh-day Adventist church on Foksal 8 (Kościół Adwentystów Dnia Siódmego; the hall is
## inside a four-storey pale yellow house set back behind a front garden and a fence): the mass
## stays GUGiK's LoD2 (OSM building 5399, unnamed) in its yellow plaster; the street front's
## arched gate at its west end, the two iron balconies at its east end and the white band where
## the church's name runs over the ground floor are ours. From F's 5 Commons photos
## (refs/churches/adwentysci_foksal, reference only, never shipped). Spec
## docs/landmarks/specs/adwentysci.md.
## Frame: origin at the front's east corner, u to the west along Foksal, +v out of the front.
const ADW_AT := Vector2(-82.0, -48.0)        ## inside the outline
const ADW_E := Vector2(-70.3, -42.5)         ## the front's east corner
const ADW_W := Vector2(-92.2, -34.6)         ## the front's west corner

const ADW_TRIM := Color("#f2ecd9")           ## the gate's surround, the band, the cornice
const ADW_DOOR := Color("#4a2c22")           ## the gate's dark brown leaves (photo 03)
const ADW_IRON := Color("#2a2a2c")


func _build_adwentysci(_site: Dictionary) -> void:
	var ln := kit_front(ADW_E, ADW_W)
	_g = _ground_under(_outline_at(ADW_AT))
	var g := _g
	var keep := _mode
	_mode = M_STONE
	kit_face(0.12)
	# the gate at the west end: a light arched surround and the dark leaves
	_kbox(ln - 3.4, ln - 0.6, 0.12, 0.22, g, g + 4.0, ADW_TRIM)
	kit_face(0.22)
	kit_door(ln - 2.0, g, 3.3, 0.85, ADW_TRIM, ADW_DOOR, true)
	# the band over the ground floor where the church's name runs (the letters are not built)
	kit_face(0.12)
	kit_ledge(5.0, ln - 5.0, g + 3.9, 0.45, ADW_TRIM, 0.06)
	# the two iron balconies at the east end, on the first and second floors
	for y: float in [g + 4.6, g + 7.9]:
		kit_balcony(2.0, y, 1.3, Balcony.IRON, ADW_IRON, ADW_TRIM, 0.9)
	_mode = keep


## The Elizabethan sisters' provincial house (Dom Prowincjalny Sióstr Elżbietanek, OSM building
## named so, in the block between Piekarska, Piwna and Podwale, behind St Martin's): a two-storey
## range along the Podwale gardens with a taller block at its west end and a rounded east end
## (read as the chapel's apse, a default). No photo shows it (F's 12 Commons photos of Piekarska
## show the street fronts in front of it, not this range), so the colours are defaults, parked in
## docs/QUESTIONS.md. The mass stays GUGiK's LoD2 (eaves about 8.5 m, ridge 11, the west block
## 14) in its skin; LoD2 has nothing over the rounded end, so that is ours: a half drum to the
## eaves under a half cone. Spec docs/landmarks/specs/elzbietanki.md.
const ELZ_AT := Vector2(-830.0, -1578.0)     ## inside the outline (the main range)
const ELZ_WALL := Color("#e2cfa6")           ## pale ochre plaster (a default, the Old Town's tone)
const ELZ_ROOF := Color("#a4553f")           ## red tiles (a default, as the Old Town's roofs)
const ELZ_APSE := Vector2(-821.5, -1587.1)   ## the rounded end's centre (the outline's arc)
const ELZ_AXIS := Vector2(0.709, -0.705)     ## out of the range through the rounded end
const ELZ_TRIM := Color("#f1ebdd")
const ELZ_IRON := Color("#2a2a2c")


func _build_elzbietanki(_site: Dictionary) -> void:
	_g = _ground_under(_outline_at(ELZ_AT))
	var g := _g
	var keep := _mode
	_mode = M_STONE
	# a whole drum and cone: the half inside the range is hidden in LoD2's mass
	var r := 2.9
	var drum := _circle(ELZ_APSE, r, 14)
	_prism(drum, g - 0.3, g + 7.6, ELZ_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
	var eave := _circle(ELZ_APSE, r + 0.25, 14)
	_frustum(drum, g + 7.45, eave, g + 7.75, ELZ_TRIM)
	_frustum(eave, g + 7.75, _circle(ELZ_APSE, 0.2, 14), g + 10.6, ELZ_ROOF)
	# a white plinth and two rows of narrow windows round the outer half
	_frustum(_circle(ELZ_APSE, r + 0.08, 14), g - 0.3, _circle(ELZ_APSE, r + 0.08, 14), g + 0.6, ELZ_TRIM)
	var side := Vector2(-ELZ_AXIS.y, ELZ_AXIS.x)
	for k: int in [-1, 0, 1]:
		var t := float(k) * 0.75
		var n := ELZ_AXIS * cos(t) + side * sin(t)
		var c := ELZ_APSE + n * (r + 0.04)
		var tg := Vector2(-n.y, n.x)
		for y0: float in [g + 1.4, g + 4.6]:
			_wall(c - tg * 0.42, c + tg * 0.42, y0, y0 + 2.0, n, PAL_GLASS_DARK)
	# a small iron cross on the cone's tip
	_prism(_circle(ELZ_APSE, 0.07, 4), g + 10.4, g + 12.0, ELZ_IRON, ELZ_IRON, M_STONE, M_STONE)
	_o = ELZ_APSE
	_a = side
	_b = ELZ_AXIS
	_lbox(0.0, 0.0, 0.32, 0.05, g + 11.3, g + 11.42, ELZ_IRON)
	_mode = keep


## The Nożyk Synagogue (Synagoga Nożyków, ul. Twarda 6; Karol and Leandro Marconi, 1898-1902;
## burnt 1944, rebuilt 1977-1983; Warsaw's only pre-war synagogue still standing), a cream
## neo-Romanesque house of prayer in its courtyard south of Plac Grzybowski. The whole building as
## a model that replaces the old kit church (`church_nozykow`, built by `_build_church` until
## 2026-11-14: its front on the wrong, east end, a grid of windows and a CROSS on the gable) and
## the LoD2 mass. From F's three photos (refs/_f/warsaw-needed-photos/top-50/T33: one
## straight onto the front, two from its south-west; never shipped), the OSM outline and GUGiK's
## LoD2 (over the front's ground: the front block's eaves 12, its hip ridge 14.4; the nave's gable
## ridge 15; the aisles' lean-tos 9.9 to 11.2; the 1923 choir 12 to 13.2). Spec
## docs/landmarks/specs/nozyk.md.
## - the front looks WEST over the courtyard: a three-bay middle risalit (0.5 m proud) between two
##   tall pylons with zinc urns, under a gable with a corbel-arch (Lombard) frieze, a roundel with
##   the Star of David and a ball finial; below it the arched door at the top of a flight of
##   steps between two arched windows, two little domed turrets and the Tablets of the Law over the
##   door, four tall windows between colonnettes and two arched windows above;
## - the two wings either side: a rusticated ground floor with one arched window, two tall
##   windows and a triple arched light upstairs, a cornice with corner acroteria;
## - behind: the front block under a hip, the nave's gable roof running back to the east, the two
##   aisles under lean-tos with arched windows in two storeys between lesenes, the narrow stair
##   halls behind the wings and the 1923 choir at the east end (the 1980s wing of the Jewish
##   Community behind it stays LoD2's).
## Frame: origin at the front's north end on the wings' line, u along the front to the south
## (+u to the viewer's right), +v out to the courtyard (west).
const NZ_O := Vector2(-1579.14, -238.72)
const NZ_A := Vector2(0.0926, 0.9957)
const NZ_W := 23.12                    ## the front's width (u)
const NZ_C := 11.67                    ## the risalit's mirror axis (u): door, roundel, gable
const NZ_WALL := Color("#e7d4a4")      ## the cream-yellow plaster (photos: warm sand)
const NZ_TRIM := Color("#efe1b8")      ## cornices, surrounds, colonnettes
const NZ_ORN := Color("#d6bd86")       ## the carved bands and hoods, a shade deeper
const NZ_PLINTH := Color("#d8bd82")    ## the plinth, a deeper ochre
const NZ_ROOF := Color("#7d8486")      ## grey sheet metal
const NZ_ZINC := Color("#8c9694")      ## the urns and the finial
## The 1980s wing of the Jewish Community east of the synagogue (its OSM outline): it stays the
## map's (LoD2), though its centre lies in the site's zone.
const NZ_WING := [[-1545.4, -225.0], [-1547.5, -224.8], [-1546.5, -234.8], [-1550.8, -234.4], [-1550.9, -236.8],
		[-1549.6, -236.9], [-1549.8, -239.1], [-1540.4, -240.0], [-1540.2, -237.9], [-1538.6, -221.1],
		[-1543.2, -220.8], [-1544.9, -220.7]]


func _nz_wing_ring() -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Array in NZ_WING:
		out.append(Vector2(float(q[0]), float(q[1])))
	return out


## The front frame again, after a side wall moved it.
func _nz_home() -> void:
	kit_front(NZ_O, NZ_O + NZ_A)


## A gable roof whose ridge runs along v (the nave's): `_gable` in the swapped frame.
func _nz_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, NZ_WALL, NZ_ROOF, true)
	_a = ka
	_b = kb


## A lean-to roof over an aisle: one sloped quad from the outer eave (u `uo`, height yo) up to
## the nave's wall (u `ui`, height yi), from v0 to v1.
func _nz_lean(uo: float, ui: float, v0: float, v1: float, yo: float, yi: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var s := signf(ui - uo)
	var n := (Vector3.UP * absf(ui - uo) - Vector3(_a.x, 0.0, _a.y) * s * (yi - yo)).normalized()
	var p0 := _w(uo, v0)
	var p1 := _w(uo, v1)
	var p2 := _w(ui, v1)
	var p3 := _w(ui, v0)
	_quad(Vector3(p0.x, yo, p0.y), Vector3(p1.x, yo, p1.y), Vector3(p2.x, yi, p2.y), Vector3(p3.x, yi, p3.y), n, NZ_ROOF)
	_mode = keep


## A sloped band on the face (a raking cornice) from (u0, y0) to (u1, y1), `t` tall, standing
## from v `vb` out to `vf`: its front, top and underside.
func _nz_rake(u0: float, y0: float, u1: float, y1: float, vb: float, vf: float, t: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var at := func(u: float, v: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var out := Vector3(_b.x, 0.0, _b.y)
	var up := (Vector3.UP * absf(u1 - u0) - Vector3(_a.x, 0.0, _a.y) * signf(u1 - u0) * (y1 - y0)).normalized()
	_quad(at.call(u0, vf, y0), at.call(u1, vf, y1), at.call(u1, vf, y1 + t), at.call(u0, vf, y0 + t), out, col)
	_quad(at.call(u0, vf, y0 + t), at.call(u1, vf, y1 + t), at.call(u1, vb, y1 + t), at.call(u0, vb, y0 + t), up, col.lightened(0.04))
	_quad(at.call(u0, vf, y0), at.call(u1, vf, y1), at.call(u1, vb, y1), at.call(u0, vb, y0), -up, col.darkened(0.1))
	_mode = keep


## Rustication: a flat groove line (2 tris) every `step` metres between y0 and y1 on the face.
func _nz_bands(u0: float, u1: float, y0: float, y1: float, step: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var line := NZ_WALL.darkened(0.13)
	var y := y0 + step
	while y + 0.09 < y1:
		_wall(_w(u0, _face + 0.03), _w(u1, _face + 0.03), y, y + 0.09, _b, line)
		y += step
	_mode = keep


## An arched window on the face at u: the pane `hw` half wide from the sill up to the spring and
## its round head, in a trim surround and (when `hood`) a carved hood round that. The layers stand
## 4 cm apart (more than `_wall`'s 3 cm coplanar cut, which would drop the later ones) and in
## front of the rustication's grooves.
func _nz_arch(u: float, sill: float, spring: float, hw: float, hood: bool) -> void:
	var at := _w(u, _face)
	if hood:
		_arch_panel(at, _a, _b, hw + 0.38, sill - 0.12, spring, NZ_ORN, 0.07, M_STONE)
	_arch_panel(at, _a, _b, hw + 0.18, sill - 0.12, spring, NZ_TRIM, 0.11, M_STONE)
	_arch_panel(at, _a, _b, hw, sill, spring, PAL_GLASS_DARK, 0.15, _lit(u, sill))
	_kbox(u - hw - 0.3, u + hw + 0.3, _face - 0.02, _face + 0.24, sill - 0.2, sill - 0.06, NZ_TRIM)  # the sill


## A side face from `from` to `to` (its outside on the left of that direction), `len` long, its
## cornice at `top` (absolute): plinth, rustication to the belt, the belt, an arched window at
## each `wins` spot on both storeys, lesenes at `les`, and (when `cornice`) a cornice ledge (the
## front block's ends have the ring cornice already).
func _nz_side(from: Vector2, to: Vector2, top: float, wins: Array, les: Array, upper_sill: float, cornice := true) -> void:
	var g := _g
	var len := kit_front(from, to)
	kit_face(0.0)
	kit_ledge(0.0, len, g - 0.5, 1.4, NZ_PLINTH, 0.06)
	_nz_bands(0.0, len, g + 0.9, g + 5.35, 0.5)
	kit_ledge(0.0, len, g + 5.35, 0.4, NZ_TRIM, 0.14)
	for lu: float in les:
		kit_pilaster(lu, g + 0.9, top - 0.45, NZ_WALL.lightened(0.05), 0.9, 0.18)
	for wu: float in wins:
		_nz_arch(wu, g + 1.9, g + 3.5, 0.62, true)
		_nz_arch(wu, upper_sill, upper_sill + 1.6, 0.55, false)
	if cornice:
		kit_ledge(0.0, len, top - 0.45, 0.45, NZ_TRIM, 0.32)


## A zinc urn on a pedestal at u, v, standing on y.
func _nz_urn(u: float, v: float, y: float) -> void:
	var c := _w(u, v)
	_lbox(u, v, 0.32, 0.32, y, y + 0.35, NZ_TRIM)
	_frustum(_circle(c, 0.16, 8), y + 0.35, _circle(c, 0.38, 8), y + 0.75, NZ_ZINC)
	_frustum(_circle(c, 0.38, 8), y + 0.75, _circle(c, 0.22, 8), y + 1.05, NZ_ZINC)
	_frustum(_circle(c, 0.22, 8), y + 1.05, _circle(c, 0.05, 8), y + 1.3, NZ_ZINC.lightened(0.08))


func _build_nozyk(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_nz_home()
	var c := NZ_C
	var wd := NZ_W
	var gp := _w(c, 3.0)
	_g = map.terrain_height(gp.x, gp.y)  # the courtyard before the front (the plot falls 0.5 m to the east)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var trim := NZ_TRIM
	var wall := NZ_WALL
	_mode = M_STONE
	# --- the masses: the front block, the stair halls behind the wings, the aisles, the nave, the choir
	_kbox(0.0, wd, -8.2, 0.0, g - 1.0, g + 12.0, wall)
	_prism(_lpoly([[0.58, -8.2], [6.67, -8.2], [6.67, -11.42], [0.58, -11.42]]), g - 1.0, g + 9.0, wall, none, M_STONE)
	_prism(_lpoly([[16.67, -8.2], [22.58, -8.2], [22.58, -11.42], [16.67, -11.42]]), g - 1.0, g + 9.04, wall, none, M_STONE)
	_prism(_lpoly([[2.99, -11.42], [6.67, -11.42], [6.67, -27.9], [4.53, -27.94], [2.02, -27.97], [2.03, -26.97], [3.13, -26.97]]),
			g - 1.0, g + 9.88, wall, none, M_STONE)
	_prism(_lpoly([[16.67, -11.42], [20.36, -11.42], [20.43, -29.38], [16.67, -29.83]]), g - 1.0, g + 9.86, wall, none, M_STONE)
	_kbox(6.67, 16.67, -28.6, -8.2, g - 1.0, g + 12.4, wall)
	var choir := _lpoly([[6.93, -27.85], [16.77, -29.6], [16.79, -30.22], [6.93, -32.14]])
	_prism(choir, g - 1.0, g + 12.0, wall, none, M_STONE)
	_pyramid(choir, g + 12.0, g + 13.2, NZ_ROOF)
	# --- the roofs: the front block's hip, the nave's gable (its front triangle is the risalit's
	# gable), the four lean-tos
	_hip(wd * 0.5, -4.1, wd * 0.5, 4.1, g + 12.0, 2.4, NZ_ROOF)
	_nz_gable(0.5, -28.6, c, 5.0, g + 12.4, 2.6)
	_nz_lean(0.58, 6.67, -8.2, -11.42, g + 9.0, g + 11.2)
	_nz_lean(2.99, 6.67, -11.42, -27.9, g + 9.88, g + 11.2)
	_nz_lean(22.58, 16.67, -8.2, -11.42, g + 9.04, g + 11.2)
	_nz_lean(20.4, 16.67, -11.42, -29.6, g + 9.86, g + 11.2)
	# the cornices round the front block and along the nave's walls over the lean-tos
	kit_cornice_ring(_lpoly([[0.0, 0.0], [wd, 0.0], [wd, -8.2], [0.0, -8.2]]), g + 11.6, trim, 0.4, 0.42)
	_kbox(6.52, 16.82, -28.6, -8.2, g + 12.05, g + 12.4, trim)
	# --- the front: the wings (rusticated ground floor, two storeys of windows)
	kit_face(0.0)
	for wing: Array in [[0.0, 6.67, 4.2], [16.67, wd, 19.15]]:
		var u0: float = wing[0]
		var u1: float = wing[1]
		var wc: float = wing[2]
		kit_ledge(u0, u1, g - 0.5, 1.4, NZ_PLINTH, 0.06)
		_nz_bands(u0, u1, g + 0.9, g + 5.35, 0.5)
		kit_ledge(u0 - 0.1, u1, g + 5.35, 0.4, trim, 0.16)
		_nz_arch(wc, g + 1.9, g + 3.5, 0.62, true)
		# upstairs: two tall windows over a panel band, a triple arched light in an arcade
		kit_ledge(wc - 1.35, wc + 1.35, g + 6.05, 0.22, NZ_ORN, 0.1)
		for s: float in [-0.75, 0.75]:
			kit_window(wc + s, g + 6.4, 2.1, Win.SILL, trim, PAL_GLASS_DARK, 0.38)
		kit_ledge(wc - 1.35, wc + 1.35, g + 9.15, 0.2, trim, 0.12)
		_kbox(wc - 1.3, wc + 1.3, -0.02, 0.06, g + 9.35, g + 10.85, NZ_ORN)
		for s2: float in [-0.75, 0.0, 0.75]:
			var at := _w(wc + s2, 0.06)
			_arch_panel(at, _a, _b, 0.25, g + 9.55, g + 10.1, PAL_GLASS_DARK, 0.03, _lit(wc + s2, g + 9.55))
		# the corner lesene and the acroterion over the cornice
		var cu := u0 + 0.45 if u0 < 1.0 else u1 - 0.45
		kit_pilaster(cu, g + 5.75, g + 11.2, wall.lightened(0.05), 0.9, 0.1)
		_kbox(cu - 0.6, cu + 0.6, -0.6, 0.3, g + 12.0, g + 12.45, trim)
		_arch_panel(_w(cu, 0.3), _a, _b, 0.5, g + 12.45, g + 12.45, trim, 0.01, M_STONE)
	# --- the pylons either side of the risalit, with their urns
	for pu: float in [7.17, 16.17]:
		_kbox(pu - 0.5, pu + 0.5, -0.5, 0.8, g - 0.5, g + 12.1, wall)
		kit_face(0.8)
		kit_ledge(pu - 0.5, pu + 0.5, g - 0.5, 1.4, NZ_PLINTH, 0.04)
		_nz_bands(pu - 0.5, pu + 0.5, g + 0.9, g + 5.35, 0.5)
		kit_ledge(pu - 0.55, pu + 0.55, g + 5.35, 0.4, trim, 0.1)
		_kbox(pu - 0.62, pu + 0.62, -0.5, 0.95, g + 12.1, g + 12.6, trim)
		_nz_urn(pu, 0.25, g + 12.6)
	# --- the risalit: the ground floor with the door and its steps
	kit_face(0.5)
	_kbox(7.67, 15.67, -0.5, 0.5, g - 0.5, g + 12.4, wall)
	kit_ledge(7.67, 15.67, g - 0.5, 1.4, NZ_PLINTH, 0.06)
	_nz_bands(7.67, 9.9, g + 0.9, g + 5.35, 0.5)
	_nz_bands(13.44, 15.67, g + 0.9, g + 5.35, 0.5)
	kit_ledge(7.67, 15.67, g + 5.35, 0.4, trim, 0.16)
	for k in 4:
		var d := 2.1 - 0.45 * float(k)
		_kbox(c - 2.3 + 0.12 * float(k), c + 2.3 - 0.12 * float(k), 0.5, 0.5 + d, g - 0.3, g + 0.25 * float(k + 1), PAL_PALE_CONCRETE)
	var door := _w(c, 0.5)
	_arch_panel(door, _a, _b, 1.45, g + 1.0, g + 3.6, NZ_ORN, 0.07, M_STONE)
	_arch_panel(door, _a, _b, 1.12, g + 1.0, g + 3.6, trim, 0.11, M_STONE)
	_arch_panel(door, _a, _b, 0.86, g + 1.0, g + 3.45, PAL_OAK, 0.15, M_STONE)
	for s3: float in [-2.75, 2.75]:
		_nz_arch(c + s3, g + 1.9, g + 3.5, 0.62, true)
	# over the door: the Tablets of the Law between two small domed turrets on corbels, a low rail
	_kbox(c - 1.55, c + 1.55, 0.5, 0.78, g + 5.75, g + 6.15, trim)
	_arch_panel(_w(c, 0.5), _a, _b, 0.5, g + 5.75, g + 6.75, trim, 0.22, M_STONE)
	_arch_panel(_w(c, 0.5), _a, _b, 0.36, g + 5.85, g + 6.75, PAL_GREY_STONE, 0.27, M_STONE)
	for s4: float in [-1.72, 1.72]:
		var tu := c + s4
		_lbox(tu, 0.72, 0.2, 0.22, g + 3.7, g + 4.6, trim)
		_lbox(tu, 0.78, 0.28, 0.28, g + 4.6, g + 6.5, trim)
		var tc := _w(tu, 0.78)
		_frustum(_circle(tc, 0.3, 8), g + 6.5, _circle(tc, 0.09, 8), g + 7.05, trim)
	# upstairs: four tall windows between colonnettes over a sill band, the carved frieze
	kit_ledge(7.67, 15.67, g + 6.1, 0.22, NZ_ORN, 0.1)
	for wu: float in [c - 2.75, c - 0.85, c + 0.85, c + 2.75]:
		kit_window(wu, g + 6.4, 2.1, Win.SILL, trim, PAL_GLASS_DARK, 0.47)
	for cu2: float in [7.95, c - 1.85, c - 1.65, c + 1.65, c + 1.85, 15.39]:
		kit_pilaster(cu2, g + 6.3, g + 8.95, trim, 0.2, 0.14)
	kit_ledge(7.67, 15.67, g + 8.95, 0.45, NZ_ORN, 0.12)
	# the two arched windows in the gable storey and the roundel with the Star of David
	for s5: float in [-2.75, 2.75]:
		_nz_arch(c + s5, g + 9.65, g + 10.0, 0.45, true)
	var rc := _w(c, 0.53)
	var out3 := Vector3(_b.x, 0.0, _b.y)
	_disc(Vector3(rc.x, g + 11.1, rc.y), out3, 1.75, 16, NZ_ORN)
	var rc2 := _w(c, 0.58)
	_disc(Vector3(rc2.x, g + 11.1, rc2.y), out3, 1.42, 16, trim)
	var along := Vector3(_a.x, 0.0, _a.y)
	for k2 in 2:
		var sc := _w(c, 0.63 + 0.04 * float(k2))  # the second triangle 4 cm proud: the two overlap
		var pts: Array[Vector3] = []
		for j in 3:
			var ang := PI * 0.5 + PI * float(k2) + TAU * float(j) / 3.0
			pts.append(Vector3(sc.x, g + 11.1, sc.y) + along * cos(ang) * 0.85 + Vector3.UP * sin(ang) * 0.85)
		_tri(pts[0], pts[1], pts[2], out3, NZ_ORN.darkened(0.12), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# the gable: raking cornices, the corbel-arch frieze under them, the ball finial on the apex
	var apex := g + 15.0
	for sd: float in [-1.0, 1.0]:
		var eu := c + sd * 4.0
		_nz_rake(eu, g + 12.62, c, apex - 0.3, 0.4, 0.82, 0.35, trim)
		for k3 in 8:
			var t := (float(k3) + 0.6) / 8.6
			var bu := lerpf(eu, c, t)
			var by := lerpf(g + 12.62, apex - 0.3, t)
			_kbox(bu - 0.13, bu + 0.13, 0.45, 0.66, by - 0.5, by - 0.05, trim)
	_lbox(c, 0.45, 0.32, 0.32, apex - 0.2, apex + 0.45, trim)
	var fc := _w(c, 0.45)
	_frustum(_circle(fc, 0.14, 8), apex + 0.45, _circle(fc, 0.08, 8), apex + 1.0, NZ_ZINC)
	_frustum(_circle(fc, 0.08, 8), apex + 1.0, _circle(fc, 0.3, 8), apex + 1.28, NZ_ZINC)
	_frustum(_circle(fc, 0.3, 8), apex + 1.28, _circle(fc, 0.05, 8), apex + 1.7, NZ_ZINC.lightened(0.08))
	_lbox(c, 0.45, 0.03, 0.03, apex + 1.7, apex + 2.1, PAL_IRON)
	# --- the sides of the front block, the stair halls, the aisles
	# (each side's own frame: its outside on the left of from -> to; north is u = 0)
	_nz_side(_w(0.0, -8.2), _w(0.0, 0.0), g + 12.0, [4.1], [], g + 6.4, false)
	_nz_home()
	_nz_side(_w(wd, 0.0), _w(wd, -8.2), g + 12.0, [4.1], [], g + 6.4, false)
	_nz_home()
	_nz_side(_w(0.58, -11.42), _w(0.58, -8.2), g + 9.0, [1.6], [], g + 5.9)
	_nz_home()
	_nz_side(_w(22.58, -8.2), _w(22.58, -11.42), g + 9.04, [1.6], [], g + 5.9)
	_nz_home()
	# the aisles: lesenes where LoD2 has them (v -14.5, -20.6, -26.8), a window in each bay
	_nz_side(_w(2.99, -27.95), _w(2.99, -11.42), g + 9.88, [4.18, 10.53, 15.13], [1.13, 7.38, 13.48], g + 6.2)
	_nz_home()
	_nz_side(_w(20.36, -11.42), _w(20.43, -29.38), g + 9.86, [1.4, 6.0, 12.35], [3.03, 9.13, 15.38], g + 6.2)
	_nz_home()
	_collide(outline)


## The Dominican church of St Hyacinth (Kościół św. Jacka, ul. Freta 8/10, 1603-1639, front and
## tower rebuilt in the 1750s and again after 1944): the whole church as a model that replaces the
## old kit church (`church_jacek`, built by `_build_church` until 2026-11-14) and the LoD2 mass
## inside the outline (43 points: the church, the tower, the dome chapel and the tenement wing
## beside it). From F's Commons photos (E23: the front, the portal; top-50 set) and the OSM
## outline. Spec docs/landmarks/specs/jacek.md.
## White plaster, a stepped front with a gable, a tall tower with a dark bell stage:
## - the front: a screen wall with a porch and a pediment over the door, double pilasters, a big
##   arched window with an iron rail, a gable with a slit window and three statues, scrolls down
##   to the aisle, two obelisks on the aisle;
## - the tower on the right: two stages, a cornice, a dark slate bell stage with a bulge, a belt,
##   an onion and a patina spire with a cross; a round bay at its foot;
## - behind: the nave (arched clerestory windows, a red-brown gable roof), lower aisles, the round
##   dome chapel at the back left, and the pink three-storey tenement wing to the right.
## Frame: origin at the front's NE end, u along the front (+u to the viewer's right, towards the
## tower), +v out to Freta; the front wall stands at v = 0.35, the aisles' at v = 0.
const JAC_O := Vector2(-989.0, -1957.1)
const JAC_A := Vector2(-0.6763, 0.7366)
const JAC_C := 17.4                    ## the front's mirror axis (u)
const JAC_TC := 27.0                   ## the tower's centre (u)
const JAC_WALL := Color("#e9e5d6")     ## the white plaster
const JAC_TRIM := Color("#f1eee2")     ## pilasters, cornices, surrounds
const JAC_ROOF := Color("#97594a")     ## the nave's red-brown sheet roof
const JAC_LEAD := Color("#7d8480")     ## the aisles' lead-grey flat roofs
const JAC_SLATE := Color("#4c5654")    ## the tower's dark bell stage
const JAC_PINK := Color("#d9a898")     ## the tenement beside the tower
const JAC_BASE := Color("#b9b2a2")     ## plinths


## A statue on a pedestal: u, v on the local plan, standing on y, `h` tall in all.
func _jac_statue(u: float, v: float, y: float, h: float) -> void:
	var c := _w(u, v)
	_lbox(u, v, 0.4, 0.4, y, y + 0.6, JAC_TRIM)
	_frustum(_circle(c, 0.34, 6), y + 0.6, _circle(c, 0.2, 6), y + h * 0.82, PAL_GREY_STONE)
	_prism(_circle(c, 0.17, 6), y + h * 0.82, y + h, PAL_GREY_STONE, PAL_GREY_STONE, M_STONE, M_STONE)


## A ring of `n` points round a local spot, its flats facing the frame's axes.
func _jac_ring(u: float, v: float, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var t := TAU * (float(k) + 0.5) / float(n)
		out.append(_w(u + cos(t) * r, v + sin(t) * r))
	return out


## A dome of `n` sides on a local spot: four stepped rings from radius r at y up to a cap.
func _jac_dome(u: float, v: float, r: float, y: float, h: float, col: Color, n: int) -> void:
	var c := _w(u, v)
	var prof: Array = [[1.0, 0.0], [0.93, 0.3], [0.74, 0.62], [0.42, 0.88], [0.14, 1.0]]
	for k in prof.size() - 1:
		var a: Array = prof[k]
		var b: Array = prof[k + 1]
		_frustum(_circle(c, r * float(a[0]), n), y + h * float(a[1]), _circle(c, r * float(b[0]), n), y + h * float(b[1]), col)
	_cap(_circle(c, r * 0.14, n), y + h, col.lightened(0.08))


## A gable roof whose ridge runs along v (the nave's): `_gable` in the swapped frame.
func _jac_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float, face: Color, roof: Color) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, face, roof, true)
	_a = ka
	_b = kb


## The front frame again, after a wall of another direction moved it.
func _jac_home() -> void:
	kit_front(JAC_O, JAC_O + JAC_A * 10.0)


func _build_jacek(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var g := _g
	var c := JAC_C
	var f := 0.35
	var none := Color(0, 0, 0, 0)
	var trim := JAC_TRIM
	_mode = M_STONE
	_jac_home()
	# --- the two masses: the church (u up to 31.5) and the tenement wing beside the tower
	var church := _largest(Geometry2D.intersect_polygons(outline, _lpoly([[-9.0, 0.3], [31.5, 0.3], [31.5, -40.0], [-9.0, -40.0]])))
	var wings := Geometry2D.intersect_polygons(outline, _lpoly([[31.5, 0.6], [75.0, 0.6], [75.0, -40.0], [31.5, -40.0]]))
	var plinth := _largest(Geometry2D.offset_polygon(church, 0.25, Geometry2D.JOIN_MITER))
	_prism(plinth, g - 0.6, g + 1.0, JAC_BASE, none, M_STONE, M_STONE)
	_prism(church, g + 0.9, g + 7.7, JAC_WALL, JAC_LEAD, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(church, 0.3, Geometry2D.JOIN_MITER)), g + 7.3, g + 7.9, trim, JAC_LEAD, M_STONE, M_STONE)
	# --- the nave: white walls to the eaves, the red-brown gable roof (ridge along v)
	_lbox(c, -16.2, 8.7, 15.2, g + 7.7, g + 11.8, JAC_WALL, M_STONE, none)
	_prism(_rect(c, -16.2, 8.95, 15.4), g + 11.6, g + 12.1, trim, none, M_STONE, M_STONE)
	_jac_gable(-0.9, -31.4, c, 8.95, g + 12.1, 2.7, JAC_WALL, JAC_ROOF)
	_kap_cross(c, -30.0, g + 14.6, 2.2)
	# --- the front: plinth, the screen wall in two storeys, scrolls, gable
	kit_face(f)
	_kbox(8.4, 26.4, -0.9, f + 0.2, g - 0.2, g + 1.1, JAC_BASE)
	_kbox(8.7, 26.1, -0.9, f, g + 1.0, g + 8.4, JAC_WALL)
	kit_cornice(8.6, 26.2, g + 8.4, trim, 0.5, 0.9)
	_kbox(12.5, 22.3, -0.9, f, g + 8.9, g + 14.3, JAC_WALL)
	kit_cornice(12.3, 22.5, g + 13.9, trim, 0.45, 0.8)
	for st: Array in [[8.7, 9.9, 10.6], [9.9, 11.2, 12.0], [11.2, 12.5, 13.4]]:
		_kbox(float(st[0]), float(st[1]), -0.9, f - 0.05, g + 8.9, g + float(st[2]), JAC_WALL)
		_kbox(float(st[0]), float(st[1]), -0.9, f + 0.2, g + float(st[2]) - 0.25, g + float(st[2]), trim)
	# pilasters: the double pair at the left, one each side of the porch, ionic heads
	for pu: float in [9.4, 10.9]:
		kit_pilaster(pu, g + 1.1, g + 8.4, trim, 0.85, 0.35)
		kit_pilaster(pu, g + 8.9, g + 13.9, trim, 0.85, 0.3)
	kit_pilaster(13.1, g + 1.1, g + 8.4, trim, 0.8, 0.35)
	kit_pilaster(21.7, g + 1.1, g + 8.4, trim, 0.8, 0.35)
	kit_pilaster(13.1, g + 8.9, g + 13.9, trim, 0.7, 0.3)
	# the great arched window over the porch, its iron rail, the panel round it
	_kbox(c - 3.6, c + 3.6, f, f + 0.06, g + 9.0, g + 14.2, JAC_WALL.darkened(0.03))
	kit_window(c, g + 9.8, 3.7, Win.ARCHED, trim, PAL_GLASS_DARK, 2.0)
	kit_balcony(c, g + 9.8, 2.0, Balcony.PARAPET, PAL_IRON, PAL_IRON, 0.5)
	# the gable: a pediment, a slit window, the apex statue and one on each foot
	kit_pediment(c, 4.9, g + 14.3, 2.7, JAC_WALL, trim.darkened(0.04), 0.5, none)
	_kbox(c - 0.45, c + 0.45, f + 0.5, f + 0.56, g + 14.8, g + 16.1, PAL_GLASS_DARK)
	_jac_statue(c, 0.0, g + 17.0, 1.9)
	_jac_statue(c - 3.6, f + 0.2, g + 14.3, 1.7)
	_jac_statue(c + 3.6, f + 0.2, g + 14.3, 1.7)
	# the blind niche left of the porch
	kit_window(11.8, g + 1.3, 3.0, Win.ARCHED, trim, JAC_WALL.darkened(0.1), 0.45)
	# --- the porch: a low gabled box with the door and its plaque
	_kbox(14.2, 20.6, -0.9, f + 1.3, g - 0.1, g + 6.2, JAC_WALL)
	_kbox(14.2, 20.6, -0.9, f + 1.3, g - 0.15, g + 0.3, JAC_BASE)
	kit_face(f + 0.85)
	kit_cornice(14.0, 20.8, g + 5.9, trim, 0.45, 0.65)
	kit_pediment(c, 3.4, g + 6.4, 2.0, JAC_WALL.lightened(0.02), trim.darkened(0.04), 0.45, none)
	kit_face(f + 1.3)
	kit_door(c, g + 0.1, 3.2, 0.9, trim, PAL_IRON, false)
	for sg: float in [-1.0, 1.0]:
		_kbox(c + sg * 1.2 - 0.14, c + sg * 1.2 + 0.14, f + 1.25, f + 1.4, g + 0.1, g + 3.5, trim)
	_kbox(c - 0.9, c + 0.9, f + 1.3, f + 1.36, g + 4.2, g + 4.9, PAL_BRONZE)
	kit_face(f)
	# --- the aisles beside the front: a cornice, the scroll bases, two obelisks, urns
	kit_face(0.0)
	kit_cornice(0.0, 8.7, g + 7.7, trim, 0.5, 0.8)
	_kbox(2.0, 6.4, -2.2, -0.2, g + 7.9, g + 10.9, JAC_WALL)
	_kbox(1.8, 6.6, -2.4, -0.1, g + 10.7, g + 11.0, trim)
	_pinnacle(3.2, -1.3, 1.1, g + 11.0, 4.1, trim)
	_pinnacle(5.2, -1.3, 1.1, g + 11.0, 4.3, trim)
	kit_window(3.4, g + 2.2, 3.0, Win.ARCHED, trim, PAL_GLASS_DARK, 0.7)
	kit_pilaster(1.0, g + 1.1, g + 7.7, trim, 0.8, 0.2)
	kit_pilaster(7.9, g + 1.1, g + 7.7, trim, 0.8, 0.2)
	# --- the round bay at the tower's foot
	var bay := _w(25.3, -0.2)
	_prism(_circle(bay, 1.85, 8), g + 0.9, g + 3.6, JAC_WALL, JAC_LEAD, M_STONE, M_STONE)
	_prism(_circle(bay, 2.0, 8), g + 3.4, g + 3.8, trim, JAC_LEAD, M_STONE, M_STONE)
	# --- the tower: two stages, a cornice, the dark bell stage and the spire
	var tv := -4.075
	_lbox(JAC_TC, tv, 4.5, 4.425, g + 0.9, g + 10.1, JAC_WALL, M_STONE, none)
	_kbox(JAC_TC - 4.8, JAC_TC + 4.8, -8.8, f + 0.3, g - 0.6, g + 1.0, JAC_BASE)
	_prism(_rect(JAC_TC, tv, 4.85, 4.775), g + 10.1, g + 10.7, trim, none, M_STONE, M_STONE)
	_lbox(JAC_TC, tv, 4.3, 4.225, g + 10.7, g + 18.4, JAC_WALL, M_STONE, none)
	_prism(_rect(JAC_TC, tv, 4.85, 4.775), g + 18.4, g + 19.3, trim, JAC_SLATE, M_STONE, M_STONE)
	# the faces read before the frame moves: NE, SW and the front
	var ne0 := _w(JAC_TC - 4.5, -8.5)
	var ne1 := _w(JAC_TC - 4.5, f)
	var sw0 := _w(JAC_TC + 4.5, f)
	var sw1 := _w(JAC_TC + 4.5, -8.5)
	kit_face(f)
	for pu2: float in [JAC_TC - 3.9, JAC_TC + 3.9]:
		kit_pilaster(pu2, g + 1.0, g + 10.1, trim, 1.0, 0.3)
		kit_pilaster(pu2, g + 10.7, g + 18.4, trim, 0.9, 0.25)
	kit_window(JAC_TC, g + 5.0, 1.7, Win.FRAMED, trim, PAL_GLASS_DARK, 0.55)
	kit_door(JAC_TC + 1.6, g + 1.0, 2.7, 0.7, trim, PAL_IRON, true)
	kit_window(JAC_TC, g + 11.9, 3.2, Win.ARCHED, trim, PAL_GLASS_DARK, 0.9)
	var tface := func(from: Vector2, to: Vector2) -> void:
		var wl := kit_front(from, to)
		kit_face(0.0)
		kit_window(wl * 0.5, g + 11.9, 3.2, Win.ARCHED, trim, PAL_GLASS_DARK, 0.9)
		kit_window(wl * 0.5, g + 4.6, 2.4, Win.ARCHED, trim, PAL_GLASS_DARK, 0.6)
	tface.call(ne0, ne1)
	tface.call(sw0, sw1)
	_jac_home()
	# the bell stage: a dark swelling drum, a belt, an onion, a patina spire and a cross
	var prof: Array = [[19.3, 2.9, 0], [20.3, 3.1, 0], [22.0, 3.25, 0], [23.4, 2.75, 0], [23.9, 3.0, 1], [24.3, 1.4, 0], [25.2, 1.45, 2], [26.2, 0.8, 2]]
	for k in prof.size() - 1:
		var a: Array = prof[k]
		var b: Array = prof[k + 1]
		var col := JAC_SLATE if int(b[2]) == 0 else (JAC_SLATE.lightened(0.1) if int(b[2]) == 1 else PAL_PATINA_COPPER)
		_frustum(_jac_ring(JAC_TC, tv, float(a[1]), 8), g + float(a[0]), _jac_ring(JAC_TC, tv, float(b[1]), 8), g + float(b[0]), col)
	_frustum(_jac_ring(JAC_TC, tv, 0.8, 8), g + 26.2, _jac_ring(JAC_TC, tv, 0.2, 8), g + 28.3, PAL_PATINA_COPPER, PAL_PATINA_COPPER)
	_kap_cross(JAC_TC, tv, g + 28.3, 1.9)
	# the louvres and the shell on the four faces of the bell stage
	for fc: Array in [[0.0, 1.0], [0.0, -1.0], [1.0, 0.0], [-1.0, 0.0]]:
		var lu := JAC_TC + float(fc[0]) * 3.05
		var lv := tv + float(fc[1]) * 3.05
		_lbox(lu, lv, 0.04 + 0.5 * absf(float(fc[1])), 0.04 + 0.5 * absf(float(fc[0])), g + 19.9, g + 21.5, PAL_IRON)
	# --- the dome chapel behind the left aisle: a drum with a green dome and a cross
	var cc := _w(-1.0, -18.8)
	_prism(_circle(cc, 3.6, 12), g + 0.9, g + 8.6, JAC_WALL, none, M_STONE, M_STONE)
	_prism(_circle(cc, 3.8, 12), g + 8.3, g + 8.8, trim, none, M_STONE, M_STONE)
	_jac_dome(-1.0, -18.8, 3.7, g + 8.8, 2.7, PAL_PATINA_COPPER, 12)
	_kap_cross(-1.0, -18.8, g + 11.5, 1.6)
	# --- the nave's long wall, east side: tall arched windows over the aisle
	var n0 := _w(c - 8.7, -30.5)
	var n1 := _w(c - 8.7, -2.0)
	var nw := kit_front(n0, n1)
	kit_face(0.0)
	for k in 4:
		kit_window(nw * (0.12 + 0.25 * float(k)), g + 8.5, 2.9, Win.ARCHED, trim, PAL_GLASS_DARK, 0.65)
	# the aisle's wall below it, east
	var a0 := _w(0.0, -12.4)
	var a1 := _w(0.0, -0.6)
	kit_front(a0, a1)
	kit_face(0.0)
	kit_window(3.0, g + 2.2, 3.0, Win.ARCHED, trim, PAL_GLASS_DARK, 0.7)
	kit_window(9.0, g + 2.2, 3.0, Win.ARCHED, trim, PAL_GLASS_DARK, 0.7)
	# the back wall: a tall arched window under the cornice
	var r0 := _w(c + 8.7, -31.4)
	var r1 := _w(c - 8.7, -31.4)
	var rw := kit_front(r0, r1)
	kit_face(0.0)
	kit_window(rw * 0.5, g + 5.0, 5.2, Win.ARCHED, trim, PAL_GLASS_DARK, 1.1)
	_jac_home()
	# --- the tenement wing: pink walls, storey bands, a hipped red-tile roof over the front block
	for k in wings.size():
		var piece: PackedVector2Array = wings[k]
		if piece.size() < 3:
			continue
		_prism(piece, g + 0.0, g + 11.2, JAC_PINK, PAL_ROOF_TILE, M_STONE, M_STONE)
	_hip(41.0, -18.4, 10.05, 12.9, g + 11.2, 3.3, PAL_ROOF_TILE)
	kit_face(-5.8)
	kit_ledge(31.5, 50.5, g + 3.3, 0.3, trim, 0.1)
	kit_ledge(31.5, 50.5, g + 6.6, 0.3, trim, 0.1)
	kit_cornice(31.5, 50.5, g + 10.6, trim, 0.5, 0.5)
	kit_panes([33.4, 36.0, 38.6, 41.2, 43.8, 46.4, 49.0], [g + 1.1, g + 4.0, g + 7.2], 1.3, 1.8, PAL_GLASS_DARK, 0.05)
	kit_face(0.0)
	kit_ledge(50.5, 57.2, g + 3.3, 0.3, trim, 0.1)
	kit_ledge(50.5, 57.2, g + 6.6, 0.3, trim, 0.1)
	kit_panes([52.3, 54.9], [g + 1.1, g + 4.0, g + 7.2], 1.3, 1.8, PAL_GLASS_DARK, 0.05)
	_collide(outline)


## St Martin's church (Kościół św. Marcina, the former Augustinians', now the Franciscan Sisters
## Servants of the Cross) at Piwna 9/11: the Gothic church of the 14th-15th c., remodelled in the
## 1740s-1760s (front by Karol Bay), burnt in 1944 and rebuilt 1952-1959. Rebuilt here 2026-11-14 as
## the whole building, from F's Piwna photos (old-town E13: the tower over Piwna from Plac Zamkowy),
## his Plac Zamkowy and drone photos (the nave's side and roofs, the gable end), three Mapillary
## photos and GUGiK's LoD2 (heights, the tower's place), refs/sw_marcin (never shipped):
## - a long, tall nave in warm ochre plaster under a steep green copper roof, a gable to Piwna
##   (pilasters, a great arched window, an oculus, a cross) and a hip at the east end;
## - lower aisles and chapels on both sides under flat copper roofs, clerestory windows over them;
## - the lower front on Piwna: a two-storey front with pilasters, an arched portal, a cornice and a
##   curved attic with a statue in a niche, low wings either side (the outline's front);
## - the tower beside the chancel, in the monastery (LoD2 places it 18 m south of the nave's axis):
##   a brick Gothic shaft, two ochre stages with corner pilasters and arched openings, a cornice,
##   a green copper bell dome, an open lantern, a small bulb and a spire with a cross (~42 m).
## Frame: origin at the kit's front point on Piwna, u along the front (+u towards the tower, south),
## +v out to Piwna; the nave runs back to v = -55.
const MAR_O := Vector2(-822.8, -1556.1)
const MAR_A := Vector2(0.6866, 0.7270)
const MAR_C := 0.0                     ## the nave's axis (u)
const MAR_NV := -11.9                  ## the nave's front wall (v), the gable to Piwna
const MAR_TU := 18.25                  ## the tower's centre (u, v), LoD2's shaft
const MAR_TV := -52.4
const MAR_WALL := Color("#e6c98e")     ## the warm ochre plaster
const MAR_TRIM := Color("#f1e3c0")     ## pilasters, cornices, surrounds
const MAR_ROOF := Color("#6f9e90")     ## the green copper of the roofs and the dome
const MAR_BRICK := Color("#9a5a46")    ## the tower's Gothic brick below the stages
const MAR_BASE := Color("#b9b2a2")     ## plinths
const MAR_LANTERN := Color("#5f7672")  ## the lantern's darker copper


## The front frame again, after a wall of another direction moved it.
func _mar_home() -> void:
	kit_front(MAR_O, MAR_O + MAR_A * 10.0)


## The LoD2 tower inside the monastery's block, cut 12 m over the ground (`lod2_tops`): the
## model's own tower stands over it (its shaft is a little wider than LoD2's chamfered one).
func _marcin_tops() -> void:
	var b := Vector2(-MAR_A.y, MAR_A.x)
	var ring := PackedVector2Array()
	for c: Vector2 in [Vector2(-3.9, -3.7), Vector2(3.9, -3.7), Vector2(3.9, 3.7), Vector2(-3.9, 3.7)]:
		ring.append(MAR_O + MAR_A * (MAR_TU + c.x) + b * (MAR_TV + c.y))
	lod2_tops.append([ring, 12.0, MAR_O + MAR_A * MAR_TU + b * MAR_TV])


## A gable roof whose ridge runs along v (the nave's), no back triangle: `_gable` swapped.
func _mar_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, MAR_WALL, MAR_ROOF, false)
	_a = ka
	_b = kb


## A round-headed window on the current front at u: a trim surround and a dark pane, flat on the
## face (two arch panels, a dozen triangles; the church has thirty of them).
func _mar_arch(u: float, y0: float, h: float, hw: float, glass := PAL_GLASS_DARK) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.25, y0 - 0.25, y0 + h - hw, MAR_TRIM, 0.04, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, y0 + h - hw, glass, 0.08, _lit(u, y0))


## The windows and pilasters of one face of the tower, `from` to `to` (plan corners, outside on
## the left).
func _mar_tower_face(from: Vector2, to: Vector2, g: float) -> void:
	var w := kit_front(from, to)
	var c := w * 0.5
	kit_face(0.0)
	for pu: float in [0.45, w - 0.45]:
		_kbox(pu - 0.45, pu + 0.45, -0.02, 0.16, g + 12.2, g + 26.4, MAR_TRIM)
	for pu: float in [c - 1.9, c + 1.9]:
		_kbox(pu - 0.25, pu + 0.25, -0.02, 0.1, g + 20.3, g + 26.4, MAR_TRIM)
	_mar_arch(c, g + 15.6, 2.8, 0.6)
	_mar_arch(c, g + 21.4, 3.4, 0.75, PAL_IRON)


func _build_marcin(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var g := _g
	var c := MAR_C
	var plan: PackedVector2Array = _simplify(outline, 0.6)
	var none := Color(0, 0, 0, 0)
	var trim := MAR_TRIM
	_mode = M_STONE
	_mar_home()
	# plan points of the fronts, read in the home frame before kit_front moves it
	var f0 := _w(11.1, -1.9)
	var f1 := _w(1.4, 0.0)
	var l0 := _w(-1.4, -3.1)
	var l1 := _w(-2.4, -9.1)
	# --- the masses: the low front on Piwna, the aisles and chapels behind, both from the outline
	var front := _largest(Geometry2D.intersect_polygons(plan, _lpoly([[-14.0, 2.0], [14.0, 2.0], [14.0, MAR_NV], [-14.0, MAR_NV]])))
	var body := _largest(Geometry2D.intersect_polygons(plan, _lpoly([[-14.0, MAR_NV], [14.0, MAR_NV], [14.0, -60.0], [-14.0, -60.0]])))
	_prism(_largest(Geometry2D.offset_polygon(plan, 0.25, Geometry2D.JOIN_MITER)), g - 0.6, g + 0.9, MAR_BASE, none, M_STONE, M_STONE)
	_prism(front, g + 0.8, g + 8.6, MAR_WALL, MAR_ROOF, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(front, 0.3, Geometry2D.JOIN_MITER)), g + 8.2, g + 8.8, trim, MAR_ROOF, M_STONE, M_STONE)
	_prism(body, g + 0.8, g + 12.7, MAR_WALL, MAR_ROOF, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(body, 0.3, Geometry2D.JOIN_MITER)), g + 12.3, g + 12.9, trim, MAR_ROOF, M_STONE, M_STONE)
	# --- the nave: walls over the aisles to the eaves, a cornice, the steep copper roof
	_lbox(c, -33.45, 7.3, 21.55, g + 12.6, g + 21.3, MAR_WALL, M_STONE, none)
	_prism(_rect(c, -33.45, 7.6, 21.85), g + 21.1, g + 21.6, trim, none, M_STONE, M_STONE)
	_mar_gable(MAR_NV + 0.3, -48.2, c, 7.6, g + 21.6, 5.0)
	# the hip at the east end: two side slopes and the end slope up to the ridge's end
	var ap: Vector2 = _w(c, -48.2)
	var apex := Vector3(ap.x, g + 26.6, ap.y)
	var eaves: Array[Vector3] = []
	for q: Vector2 in [Vector2(c - 7.6, -48.2), Vector2(c - 7.6, -55.3), Vector2(c + 7.6, -55.3), Vector2(c + 7.6, -48.2)]:
		var e := _w(q.x, q.y)
		eaves.append(Vector3(e.x, g + 21.6, e.y))
	for k in 3:
		var n := (eaves[k + 1] - eaves[k]).cross(apex - eaves[k]).normalized()
		if n.y < 0.0:
			n = -n
		_tri(eaves[k], eaves[k + 1], apex, n, MAR_ROOF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_kap_cross(c, MAR_NV + 0.3, g + 26.6, 2.0)
	# --- the gable front over Piwna: pilasters, the great window, the cornice, oculus, urns
	kit_face(MAR_NV)
	for pu: float in [c - 6.9, c - 3.3, c + 3.3, c + 6.9]:
		kit_pilaster(pu, g + 8.8, g + 21.1, trim, 0.9, 0.25)
	kit_cornice(c - 7.3, c + 7.3, g + 21.1, trim, 0.5, 0.7)
	_mar_arch(c, g + 12.2, 6.6, 1.5)
	kit_ledge(c - 7.3, c + 7.3, g + 11.2, 0.35, trim, 0.15)
	var gc := _w(c, MAR_NV + 0.35)
	_disc(Vector3(gc.x, g + 23.3, gc.y), Vector3(_b.x, 0.0, _b.y), 0.75, 10, PAL_GLASS_DARK)
	for s: float in [-1.0, 1.0]:
		_pinnacle(c + s * 7.0, MAR_NV + 0.2, 0.7, g + 21.6, 1.7, trim)
		_kbox(c + s * 7.0 - 0.6, c + s * 7.0 + 0.6, MAR_NV - 0.2, MAR_NV + 0.5, g + 8.8, g + 9.6, trim)
	# --- the lower front on Piwna: the forward run of the outline, its portal and attic
	var fw := kit_front(f1, f0)
	var fc := fw * 0.5
	kit_face(0.0)
	_kbox(-0.2, fw + 0.2, -0.3, 0.25, g - 0.2, g + 1.0, MAR_BASE)
	for pu: float in [0.5, fc - 2.2, fc + 2.2, fw - 0.5]:
		kit_pilaster(pu, g + 1.0, g + 8.2, trim, 0.8, 0.22)
	kit_cornice(0.0, fw, g + 8.2, trim, 0.45, 0.6)
	# the portal: an arched door in a frame with a small segmental hood
	_kbox(fc - 1.7, fc + 1.7, -0.05, 0.3, g + 0.9, g + 5.6, trim)
	kit_face(0.3)
	kit_door(fc, g + 0.9, 4.0, 1.05, trim, PAL_OAK, true)
	kit_pediment(fc, 1.9, g + 5.6, 0.9, trim, MAR_ROOF, 0.35, none)
	kit_face(0.0)
	for wu: float in [1.9, fw - 1.9]:
		_mar_arch(wu, g + 2.4, 3.0, 0.55)
		kit_window(wu, g + 6.0, 1.2, Win.FRAMED, trim, PAL_GLASS_DARK, 0.45)
	# the curved attic over the portal: a stepped, scrolled screen with a niche and a statue
	_kbox(fc - 2.6, fc + 2.6, -0.4, 0.0, g + 8.6, g + 11.2, MAR_WALL)
	for st: Array in [[2.6, 3.6, 9.4], [3.6, 4.4, 8.9]]:
		for sg: float in [-1.0, 1.0]:
			var a0 := fc + sg * float(st[0])
			var a1 := fc + sg * float(st[1])
			_kbox(minf(a0, a1), maxf(a0, a1), -0.4, 0.0, g + 8.6, g + float(st[2]) - 0.2, MAR_WALL)
			_kbox(minf(a0, a1), maxf(a0, a1), -0.45, 0.12, g + float(st[2]) - 0.2, g + float(st[2]), trim)
	kit_cornice(fc - 2.6, fc + 2.6, g + 11.2, trim, 0.35, 0.4)
	kit_pediment(fc, 2.4, g + 11.6, 1.2, MAR_WALL, MAR_ROOF, 0.3, trim.darkened(0.06))
	_mar_arch(fc, g + 8.9, 2.0, 0.55, MAR_WALL.darkened(0.18))
	_jac_statue(fc, 0.35, g + 9.0, 1.7)
	_kap_cross(fc, 0.0, g + 12.8, 1.4)
	# the notch and the set-back wing left of it: plain plaster, two windows, the cornice
	_mar_home()
	var lw := kit_front(_w(-10.4, -7.5), _w(-6.2, -7.7))
	kit_face(0.0)
	kit_window(lw * 0.5, g + 3.0, 2.4, Win.FRAMED, trim, PAL_GLASS_DARK, 0.55)
	kit_front(l1, l0)
	kit_face(0.0)
	kit_window(3.0, g + 3.0, 2.4, Win.FRAMED, trim, PAL_GLASS_DARK, 0.55)
	_mar_home()
	# --- the north side: the aisle's arched windows, the nave's clerestory over its roof
	var nw := kit_front(_w(-11.5, -54.5), _w(-11.5, -13.0))
	kit_face(0.0)
	for k in 6:
		var u := nw * (0.08 + 0.168 * float(k))
		_mar_arch(u, g + 4.2, 5.0, 0.85)
		if k < 5:
			_kbox(u + nw * 0.084 - 0.3, u + nw * 0.084 + 0.3, -0.02, 0.15, g + 0.9, g + 12.3, trim)
	_mar_home()
	for side: float in [-1.0, 1.0]:
		var a := _w(c + side * 7.3, -53.5 if side < 0.0 else -13.5)
		var b := _w(c + side * 7.3, -13.5 if side < 0.0 else -53.5)
		var cw := kit_front(a, b)
		kit_face(0.0)
		for k in 6:
			_mar_arch(cw * (0.09 + 0.164 * float(k)), g + 14.2, 5.0, 0.9)
		_mar_home()
	# the east end: a tall arched window over the chapels' roof
	var e0 := _w(c + 7.3, -55.0)
	var e1 := _w(c - 7.3, -55.0)
	var ew := kit_front(e0, e1)
	kit_face(0.0)
	_mar_arch(ew * 0.5, g + 14.0, 5.6, 1.2)
	_mar_home()
	# --- the tower: brick shaft, two ochre stages, cornice, bell dome, lantern, bulb, spire
	var tu := MAR_TU
	var tv := MAR_TV
	_lbox(tu, tv, 3.6, 3.4, g - 0.6, g + 12.0, MAR_BRICK, M_STONE, none)
	_lbox(tu, tv, 3.6, 3.4, g + 12.0, g + 26.4, MAR_WALL, M_STONE, none)
	_prism(_rect(tu, tv, 3.75, 3.55), g + 11.8, g + 12.2, trim, none, M_STONE, M_STONE)
	_prism(_rect(tu, tv, 3.75, 3.55), g + 19.8, g + 20.3, trim, none, M_STONE, M_STONE)
	_prism(_rect(tu, tv, 4.1, 3.9), g + 26.4, g + 27.1, trim, MAR_ROOF, M_STONE, M_STONE)
	var corners := [_w(tu - 3.6, tv + 3.4), _w(tu + 3.6, tv + 3.4), _w(tu + 3.6, tv - 3.4), _w(tu - 3.6, tv - 3.4)]
	for k in 4:
		_mar_tower_face(corners[k], corners[(k + 1) % 4], g)
	_mar_home()
	# the bell dome: [radius, height over the ground], octagonal, then the lantern and the bulb
	var dome: Array = [[3.8, 27.1], [4.0, 28.0], [3.7, 29.4], [2.9, 30.6], [1.6, 31.5], [1.1, 31.9]]
	for k in dome.size() - 1:
		var p: Array = dome[k]
		var q: Array = dome[k + 1]
		_frustum(_jac_ring(tu, tv, float(p[0]), 8), g + float(p[1]), _jac_ring(tu, tv, float(q[0]), 8), g + float(q[1]), MAR_ROOF)
	_prism(_jac_ring(tu, tv, 1.1, 8), g + 31.9, g + 34.0, MAR_LANTERN, none, M_STONE, M_STONE)
	for fc2: Array in [[0.0, 1.0], [0.0, -1.0], [1.0, 0.0], [-1.0, 0.0]]:
		_lbox(tu + float(fc2[0]) * 1.0, tv + float(fc2[1]) * 1.0, 0.04 + 0.3 * absf(float(fc2[1])), 0.04 + 0.3 * absf(float(fc2[0])), g + 32.2, g + 33.5, PAL_IRON)
	var bulb: Array = [[1.35, 34.0], [1.35, 34.2], [1.5, 34.8], [1.15, 35.6], [0.45, 36.3], [0.18, 36.8]]
	for k in bulb.size() - 1:
		var p: Array = bulb[k]
		var q: Array = bulb[k + 1]
		_frustum(_jac_ring(tu, tv, float(p[0]), 8), g + float(p[1]), _jac_ring(tu, tv, float(q[0]), 8), g + float(q[1]), MAR_ROOF)
	_frustum(_jac_ring(tu, tv, 0.18, 6), g + 36.8, _jac_ring(tu, tv, 0.07, 6), g + 40.2, MAR_ROOF, MAR_ROOF)
	_prism(_jac_ring(tu, tv, 0.26, 6), g + 37.7, g + 38.2, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)
	_kap_cross(tu, tv, g + 40.2, 1.7)
	_collide(outline)


## The Pauline church of the Holy Spirit (Kościół św. Ducha, the Paulines') at Długa 3, where Freta
## meets Długa and Nowomiejska by the Barbican: built 1707-1717 (Józef Piola and Józef Szymon
## Bellotti), burnt in 1944 and rebuilt by 1956. Rebuilt here 2026-11-14 as the whole building from
## Mapillary photos (the front from Freta and Mostowa, the Długa side with both towers' caps and
## the chapel's pediment, the lower front's niches and portal; refs/sw_ducha, never shipped) and
## GUGiK's LoD2 (heights over the ground: towers' walls 26.9, their caps to 35.5, front cornice
## 20.6, pediment 25.5, nave eaves 20.6 and ridge 25.0, chapels 12.2-12.4, the Częstochowa chapel's
## gable 14-15):
## - a cream two-storey front between two towers: paired pilasters, an arched portal with a
##   segmental hood, statues in niches, a full entablature, an arched window over it and a
##   triangular pediment with an oculus, a ball and a cross;
## - two square towers flush with the front: plain shafts with small windows, a belfry stage with
##   corner pilasters, an arched opening and a round clock window on each face, a cornice with
##   urns, a green copper bell cap, an open lantern, a small bulb and a spire with a cross;
## - the tall nave under a green copper roof (gable to the front, hip at the east), arched
##   clerestory windows between lesenes over the chapels;
## - on the Długa side the chapels under a copper lean-to and the Częstochowa chapel (1746) with
##   its gable and pediment to Długa; the monastery's wings close the other side and the back.
## Frame: origin at the kit's front point, u along the front (+u to the Długa side), +v out of the
## front towards the Barbican.
const DU_O := Vector2(-1005.6, -1848.8)
const DU_A := Vector2(-0.8491, -0.5283)
const DU_C := -0.15                    ## the front's and the nave's axis (u)
const DU_NV := -5.3                    ## the towers' and front block's back (v), where the nave starts
const DU_TOWERS := [8.65, -9.0]        ## the towers' centres (u), LoD2's shafts
const DU_TV := -2.9
const DU_WALL := Color("#ece2c6")      ## the cream plaster
const DU_TRIM := Color("#f6f0de")      ## pilasters, cornices, surrounds
const DU_ROOF := Color("#72a490")      ## the pale green copper of the roofs
const DU_CAP := Color("#5b8a78")       ## the towers' darker copper caps
const DU_BASE := Color("#b8b1a0")      ## plinths


## The front frame again, after a wall of another direction moved it.
func _du_home() -> void:
	kit_front(DU_O, DU_O + DU_A * 10.0)


## A round-headed window or niche on the current front at u: a trim surround and a dark pane,
## flat on the face (two arch panels).
func _du_arch(u: float, y0: float, h: float, hw: float, glass := PAL_GLASS_DARK) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.25, y0 - 0.25, y0 + h - hw, DU_TRIM, 0.04, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, y0 + h - hw, glass, 0.08, _lit(u, y0) if glass == PAL_GLASS_DARK else M_STONE)


## A gable roof whose ridge runs along v (the nave's): `_gable` in the swapped frame, no back.
func _du_gable(vf: float, vb: float, cu: float, hu: float, y: float, h: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, DU_WALL, DU_ROOF, false)
	_a = ka
	_b = kb


## One face of a tower, `from` to `to` (plan corners, outside on the left): small windows on the
## shaft, then the belfry's corner pilasters, its arched opening and the round clock window.
func _du_tower_face(from: Vector2, to: Vector2, g: float, front: bool) -> void:
	var w := kit_front(from, to)
	var c := w * 0.5
	kit_face(0.0)
	for pu: float in [0.35, w - 0.35]:
		_kbox(pu - 0.35, pu + 0.35, -0.02, 0.14, g + 21.2, g + 26.4, DU_TRIM)
	_du_arch(c, g + 22.0, 3.3, 0.72, PAL_IRON)
	var oc := _w(c, 0.06)
	_disc(Vector3(oc.x, g + 26.05, oc.y), Vector3(_b.x, 0.0, _b.y), 0.4, 8, DU_TRIM.darkened(0.12))
	if front:
		kit_window(c, g + 16.2, 1.5, Win.FRAMED, DU_TRIM, PAL_GLASS_DARK, 0.45)
		var o2 := _w(c, 0.06)
		_disc(Vector3(o2.x, g + 18.9, o2.y), Vector3(_b.x, 0.0, _b.y), 0.35, 8, PAL_GLASS_DARK)
	else:
		kit_window(c, g + 9.6, 1.2, Win.FRAMED, DU_TRIM, PAL_GLASS_DARK, 0.4)
		var o3 := _w(c, 0.06)
		_disc(Vector3(o3.x, g + 15.6, o3.y), Vector3(_b.x, 0.0, _b.y), 0.4, 8, PAL_GLASS_DARK)


## One tower at u = tu: the shaft, its ledge and cornice rings, the four faces, the urns, the bell
## cap, the open lantern, the bulb, the spire and the cross.
func _du_tower(tu: float, g: float) -> void:
	var tv := DU_TV
	var none := Color(0, 0, 0, 0)
	_lbox(tu, tv, 2.1, 2.45, g + 0.6, g + 26.9, DU_WALL, M_STONE, none)
	_prism(_rect(tu, tv, 2.22, 2.57), g + 12.0, g + 12.5, DU_TRIM, none, M_STONE, M_STONE)
	_prism(_rect(tu, tv, 2.3, 2.65), g + 20.6, g + 21.2, DU_TRIM, none, M_STONE, M_STONE)
	_prism(_rect(tu, tv, 2.45, 2.8), g + 26.9, g + 27.5, DU_TRIM, DU_CAP, M_STONE, M_STONE)
	var corners := [_w(tu - 2.1, tv + 2.45), _w(tu + 2.1, tv + 2.45), _w(tu + 2.1, tv - 2.45), _w(tu - 2.1, tv - 2.45)]
	for k in 4:
		_du_tower_face(corners[k], corners[(k + 1) % 4], g, k == 0)
	_du_home()
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_pinnacle(tu + cu * 1.95, tv + cv * 2.3, 0.4, g + 27.5, 1.1, DU_TRIM)
	# the bell cap: [radius, height over the ground], octagonal, then the lantern, bulb and spire
	var cap: Array = [[2.0, 27.5], [2.12, 28.1], [1.9, 29.0], [1.35, 29.8], [0.85, 30.3]]
	for k in cap.size() - 1:
		var p: Array = cap[k]
		var q: Array = cap[k + 1]
		_frustum(_jac_ring(tu, tv, float(p[0]), 8), g + float(p[1]), _jac_ring(tu, tv, float(q[0]), 8), g + float(q[1]), DU_CAP)
	_prism(_jac_ring(tu, tv, 0.82, 8), g + 30.3, g + 32.3, DU_TRIM, none, M_STONE, M_STONE)
	for f: Array in [[0.0, 1.0], [0.0, -1.0], [1.0, 0.0], [-1.0, 0.0]]:
		_lbox(tu + float(f[0]) * 0.8, tv + float(f[1]) * 0.8, 0.04 + 0.22 * absf(float(f[1])), 0.04 + 0.22 * absf(float(f[0])), g + 30.6, g + 31.9, PAL_IRON)
	var bulb: Array = [[1.0, 32.3], [1.0, 32.5], [0.9, 33.1], [0.5, 33.8], [0.14, 34.4]]
	for k in bulb.size() - 1:
		var p: Array = bulb[k]
		var q: Array = bulb[k + 1]
		_frustum(_jac_ring(tu, tv, float(p[0]), 8), g + float(p[1]), _jac_ring(tu, tv, float(q[0]), 8), g + float(q[1]), DU_CAP)
	_frustum(_jac_ring(tu, tv, 0.14, 6), g + 34.4, _jac_ring(tu, tv, 0.05, 6), g + 36.0, DU_CAP, DU_CAP)
	_prism(_jac_ring(tu, tv, 0.22, 6), g + 34.8, g + 35.2, PAL_GOLD, PAL_GOLD, M_STONE, M_STONE)
	_kap_cross(tu, tv, g + 36.0, 1.4)


func _build_duch(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var g := _g
	var c := DU_C
	var plan: PackedVector2Array = _simplify(outline, 0.6)
	var none := Color(0, 0, 0, 0)
	var trim := DU_TRIM
	_mode = M_STONE
	_du_home()
	# --- the masses: the body behind the front (chapels, aisles, sacristy) from the outline
	var body := _largest(Geometry2D.intersect_polygons(plan, _lpoly([[-14.0, DU_NV], [14.0, DU_NV], [14.0, -50.0], [-14.0, -50.0]])))
	_prism(_largest(Geometry2D.offset_polygon(plan, 0.25, Geometry2D.JOIN_MITER)), g - 0.6, g + 0.9, DU_BASE, none, M_STONE, M_STONE)
	_prism(body, g + 0.8, g + 12.3, DU_WALL, DU_ROOF, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(body, 0.3, Geometry2D.JOIN_MITER)), g + 11.9, g + 12.5, trim, DU_ROOF, M_STONE, M_STONE)
	# the chapels' copper lean-to on the Długa side, from the eaves up against the nave
	var lean := [Vector2(11.0, DU_NV), Vector2(11.0, -28.4), Vector2(5.95, -28.4), Vector2(5.95, DU_NV)]
	var ys := [g + 12.5, g + 12.5, g + 14.4, g + 14.4]
	var lp: Array[Vector3] = []
	for k in 4:
		var p: Vector2 = _w(lean[k].x, lean[k].y)
		lp.append(Vector3(p.x, ys[k], p.y))
	var ln := (lp[1] - lp[0]).cross(lp[3] - lp[0]).normalized()
	if ln.y < 0.0:
		ln = -ln
	_quad(lp[0], lp[1], lp[2], lp[3], ln, DU_ROOF)
	# --- the front block between the towers and the towers themselves
	_lbox(c, -2.875, 6.75, 2.425, g + 0.6, g + 20.6, DU_WALL, M_STONE, DU_ROOF)
	for tu: float in DU_TOWERS:
		_du_tower(tu, g)
	_du_home()
	# --- the nave: walls over the chapels to the eaves, a cornice, the copper roof with its hip
	var nc := -0.3
	_lbox(nc, -22.1, 6.2, 16.8, g + 12.0, g + 20.6, DU_WALL, M_STONE, none)
	_prism(_rect(nc, -22.1, 6.5, 17.1), g + 20.4, g + 20.9, trim, none, M_STONE, M_STONE)
	_du_gable(-0.9, -33.2, nc, 6.5, g + 20.9, 4.1)
	var ap: Vector2 = _w(nc, -33.2)
	var apex := Vector3(ap.x, g + 25.0, ap.y)
	var eaves: Array[Vector3] = []
	for q: Vector2 in [Vector2(nc - 6.5, -33.2), Vector2(nc - 6.5, -39.2), Vector2(nc + 6.5, -39.2), Vector2(nc + 6.5, -33.2)]:
		var e := _w(q.x, q.y)
		eaves.append(Vector3(e.x, g + 20.9, e.y))
	for k in 3:
		var n := (eaves[k + 1] - eaves[k]).cross(apex - eaves[k]).normalized()
		if n.y < 0.0:
			n = -n
		_tri(eaves[k], eaves[k + 1], apex, n, DU_ROOF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# the clerestory: five arched windows a side between lesenes, over the chapels' roofs
	for side: float in [-1.0, 1.0]:
		var a := _w(nc + side * 6.2, -36.5 if side < 0.0 else -7.5)
		var b := _w(nc + side * 6.2, -7.5 if side < 0.0 else -36.5)
		var cw := kit_front(a, b)
		kit_face(0.0)
		for k in 5:
			_du_arch(cw * (0.1 + 0.2 * float(k)), g + 15.0, 4.4, 0.85)
		for k in 4:
			_kbox(cw * (0.2 + 0.2 * float(k)) - 0.3, cw * (0.2 + 0.2 * float(k)) + 0.3, -0.02, 0.12, g + 14.4, g + 20.4, trim)
		_du_home()
	# the east end over the sacristy: an oculus under the hip
	var e0 := _w(nc - 6.2, -38.9)
	var e1 := _w(nc + 6.2, -38.9)
	var ew := kit_front(e0, e1)
	kit_face(0.0)
	var eo := _w(ew * 0.5, 0.06)
	_disc(Vector3(eo.x, g + 16.6, eo.y), Vector3(_b.x, 0.0, _b.y), 1.0, 10, PAL_GLASS_DARK)
	_du_home()
	# --- the front: two storeys of paired pilasters, the portal, niches, window and pediment
	kit_face(-0.45)
	kit_ledge(-11.4, 11.0, g + 0.6, 0.6, DU_BASE, 0.2)
	for pu: float in [c - 5.95, c - 5.05, c - 2.6, c - 1.7, c + 1.7, c + 2.6, c + 5.05, c + 5.95]:
		kit_pilaster(pu, g + 1.2, g + 11.9, trim, 0.7, 0.2)
		_kbox(pu - 0.3, pu + 0.3, -0.49, -0.29, g + 13.4, g + 20.2, trim)
	for tu: float in DU_TOWERS:
		for s: float in [-1.0, 1.0]:
			kit_pilaster(tu + s * 1.75, g + 1.2, g + 11.9, trim, 0.7, 0.16)
	kit_cornice(-11.0, 10.6, g + 12.3, trim, 0.45, 0.5)
	kit_ledge(c - 6.6, c + 6.6, g + 12.75, 0.7, DU_WALL.darkened(0.04), 0.1)
	kit_cornice(c - 6.75, c + 6.75, g + 20.6, trim, 0.5, 0.6)
	# the portal: an arched door in a frame under a segmental hood, a plaque over it
	_kbox(c - 1.35, c + 1.35, -0.45, -0.15, g + 0.9, g + 6.0, trim)
	kit_face(-0.15)
	kit_door(c, g + 1.0, 4.2, 0.95, trim, PAL_OAK, true)
	kit_pediment(c, 1.6, g + 6.0, 0.8, trim, DU_ROOF, 0.35, none)
	_kbox(c - 0.7, c + 0.7, -0.15, -0.08, g + 7.6, g + 8.5, PAL_IRON)
	kit_face(-0.45)
	# niches with statues either side of the portal and of the upper window
	for s: float in [-1.0, 1.0]:
		_du_arch(c + s * 3.85, g + 3.0, 3.0, 0.6, DU_WALL.darkened(0.2))
		_jac_statue(c + s * 3.85, -0.2, g + 3.1, 2.0)
		_du_arch(c + s * 3.85, g + 15.0, 2.8, 0.55, DU_WALL.darkened(0.2))
		_jac_statue(c + s * 3.85, -0.2, g + 15.1, 1.9)
	_du_arch(c, g + 14.2, 4.8, 1.1)
	# the pediment with its oculus, the ball and the cross
	kit_pediment(c, 6.85, g + 21.1, 4.4, DU_WALL, DU_ROOF, 0.45, trim.darkened(0.05))
	var po := _w(c, 0.08)
	_disc(Vector3(po.x, g + 22.5, po.y), Vector3(_b.x, 0.0, _b.y), 0.55, 8, PAL_GLASS_DARK)
	_frustum(_jac_ring(c, -0.2, 0.35, 8), g + 25.4, _jac_ring(c, -0.2, 0.42, 8), g + 25.8, DU_CAP)
	_frustum(_jac_ring(c, -0.2, 0.42, 8), g + 25.8, _jac_ring(c, -0.2, 0.15, 8), g + 26.3, DU_CAP)
	_kap_cross(c, -0.2, g + 26.3, 1.5)
	# --- the Długa side: the chapels' arched windows between lesenes, the Częstochowa chapel
	var dw := kit_front(_w(11.0, -6.0), _w(11.0, -28.2))
	kit_face(0.0)
	for k in 4:
		_du_arch(dw * (0.125 + 0.25 * float(k)), g + 4.0, 4.6, 0.75)
	for k in 3:
		_kbox(dw * (0.25 + 0.25 * float(k)) - 0.3, dw * (0.25 + 0.25 * float(k)) + 0.3, -0.02, 0.12, g + 0.9, g + 11.9, trim)
	_du_home()
	# the chapel (1746): walls to its cornice, a copper gable roof across, the pediment to Długa
	_du_home()
	_gable(11.7, 5.95, -33.65, 5.25, g + 12.5, 2.6, DU_WALL, DU_ROOF, false)
	var cw2 := kit_front(_w(11.7, -28.4), _w(11.7, -38.9))
	kit_face(0.0)
	for pu: float in [0.45, 2.6, cw2 - 2.6, cw2 - 0.45]:
		kit_pilaster(pu, g + 1.0, g + 11.9, trim, 0.7, 0.18)
	_du_arch(cw2 * 0.5, g + 4.2, 5.4, 1.0)
	var tri0 := _w(cw2 * 0.5, 0.04)
	_disc(Vector3(tri0.x, g + 13.4, tri0.y), Vector3(_b.x, 0.0, _b.y), 0.5, 8, trim.darkened(0.08))
	_du_home()
	# --- the monastery side: the courtyard's arched windows (the wings close the rest)
	var mw := kit_front(_w(-11.7, -26.0), _w(-11.7, -12.8))
	kit_face(0.0)
	for k in 3:
		_du_arch(mw * (0.18 + 0.32 * float(k)), g + 4.0, 4.6, 0.75)
	_du_home()
	_collide(outline)


## The Church of the Holiest Saviour (Kościół Najświętszego Zbawiciela; Józef Dziekoński and
## Józef Piotrowski, 1901-1911) on the south side of Plac Zbawiciela, its front to the north,
## to the square. Rebuilt 2026-11-13 from F's ten photos (front, both obliques, the side with the
## chapel dome, two aerials) and Mapillary panoramas (refs/zbawiciela, never shipped). White
## plaster, grey stone portal columns, pale verdigris roofs, dark green spires:
## - the front block (16.6 m wide, projecting before the towers): a portal of four grey columns
##   under a pediment, statue niches and round windows either side, paired pilasters; over the
##   entablature the tall round-headed window with mullions, then a stepped attic with a niche,
##   a small pediment and a cross;
## - two towers (the mapped centres): a square shaft to the front's cornice, a balustrade with
##   urns, a square stage with paired arched openings, a cornice with urns, an octagonal belfry,
##   a dark green bell cap, a lantern, a bulb and a needle spire to the cross (about 70 m;
##   the photos put the front's cornice near 30 m and the towers a little over twice that);
## - gabled nave and transept roofs, the transept ends with a tall arched window and a gable,
##   a square lantern over the crossing (the mapped 35 m part) and the low domed chapel behind the
##   east transept arm (the side photo and both aerials).
## Frame: origin at the front's middle, u east along the front, +v out of it to the north.
const ZB_O := Vector2(-417.6, 1612.3)
const ZB_NAVE_AT := Vector2(-417.6, 1625.0)
const ZB_TOWER_AT := [Vector2(-427.4, 1621.7), Vector2(-408.9, 1621.7)]
const ZB_TOWER_U := 9.0
const ZB_TOWER_V := -9.4
const ZB_CROSSING := Vector2(0.0, -29.7)   ## the mapped 35 m square over the crossing
const ZB_CHAPEL := Vector2(11.6, -41.6)    ## the domed chapel behind the east transept arm
const ZB_WALL := Color("#efebe2")    ## white plaster
const ZB_TRIM := Color("#f8f5ee")
const ZB_BASE := Color("#a9a7a1")
const ZB_COLUMN := Color("#8f959c")  ## the portal's grey stone columns
const ZB_ROOF := Color("#7fb59b")    ## the roofs' pale verdigris (the aerials)
const ZB_SPIRE := Color("#3e5f52")   ## the towers' dark green caps and spires
const ZB_DARK := Color("#3a3d40")
const ZB_NICHE := Color("#c9c6bf")
## Night lighting (F's street-by-street, 2026-11-02): lit gilt, floodlamps, stained glass.
const ZB_LIT_GOLD := Color("#e8c05a")

const ZB_STAINED := Color("#7a5226")
## Floodlamps on the paving, [u, v] in the front's frame: the porch's steps and sides, the towers'
## fronts and outer faces, the transept's ends.
const ZB_FLOODS := [[-3.5, 3.4], [3.5, 3.4], [-8.6, 2.4], [8.6, 2.4], [-11.0, -3.9], [11.0, -3.9],
		[-14.4, -9.4], [14.4, -9.4], [-20.2, -29.0], [20.2, -29.0], [-6.0, -52.0], [6.0, -52.0]]
## A tower's bell cap and its spire above the belfry: [radius, height above ground].
const ZB_CAP := [[2.8, 49.3], [2.75, 50.6], [2.2, 52.0], [1.3, 53.2], [0.75, 53.8]]
const ZB_BULB := [[0.9, 56.8], [1.05, 57.6], [0.7, 58.6], [0.3, 59.2]]


func _find_zbawiciela() -> void:
	var nave := _outline_at(ZB_NAVE_AT)
	if nave.size() < 3:
		return
	var zone: Array = [_largest(Geometry2D.offset_polygon(nave, 3.0, Geometry2D.JOIN_MITER))]
	for at: Vector2 in ZB_TOWER_AT:
		var t := _outline_at(at)
		if t.size() >= 3:
			zone.append(_largest(Geometry2D.offset_polygon(t, 3.0, Geometry2D.JOIN_MITER)))
	_add_site("zbawiciela", zone)
	if not sites.is_empty() and sites[-1]["key"] == "zbawiciela":
		sites[-1]["outline"] = nave


## A round-headed opening in the church's white frame: a trim surround and the pane (dark glass,
## or stained glass that glows at night with `mode` M_LAMP).
func _zb_arch(at: Vector2, along: Vector2, out: Vector2, hw: float, y0: float, spring: float, glass: Color,
		mode := M_GLASS) -> void:
	_arch_panel(at, along, out, hw + 0.28, y0 - 0.25, spring, ZB_TRIM, 0.04, M_STONE)
	_arch_panel(at, along, out, hw, y0, spring, glass, 0.08, mode)


## A pediment on the front's plane: its triangle at v = vf facing +v, slopes back to vb, centred
## on u = cu, half width hu (`_gable` in the swapped frame).
func _zb_pediment(vf: float, vb: float, cu: float, hu: float, y: float, h: float, face: Color, roof: Color) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(vf, vb, cu, hu, y, h, face, roof, false)
	_a = ka
	_b = kb


## A stack of octagonal rings [radius, height] from y = g: a bell cap, a bulb, a dome.
func _zb_rings(c: Vector2, rings: Array, col: Color) -> void:
	var g := _g
	for k in rings.size() - 1:
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		_frustum(_circle(c, ra[0], 8), g + float(ra[1]), _circle(c, rb[0], 8), g + float(rb[1]), col, col)


func _build_zbawiciela(site: Dictionary) -> void:
	_o = ZB_O
	_a = Vector2.RIGHT
	_b = Vector2.UP  # out of the front, to the north
	var outline: PackedVector2Array = _simplify(site["outline"], 0.6)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var cos8 := cos(PI / 8.0)  # an octagon's face distance over its vertex radius
	_mode = M_STONE
	# --- the body from the mapped outline: plinth, a windowed storey to the eaves, a cornice that
	# closes the top under the gabled roofs
	var plinth := _largest(Geometry2D.offset_polygon(outline, 0.3, Geometry2D.JOIN_MITER))
	_prism(plinth, g - 0.6, g + 1.5, ZB_BASE, ZB_BASE.lightened(0.05), M_STONE, M_STONE)
	_prism(outline, g + 1.5, g + 23.0, ZB_WALL, none, M_STONE)
	var cornice := _largest(Geometry2D.offset_polygon(outline, 0.5, Geometry2D.JOIN_MITER))
	_prism(cornice, g + 23.0, g + 24.0, ZB_TRIM, ZB_WALL.darkened(0.08), M_STONE, M_STONE)
	# the nave's gable (its ridge along v, behind the front block to the apse) and the transept's
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(-5.0, -47.5, 0.0, 8.0, g + 24.0, 9.5, ZB_WALL, ZB_ROOF, true)
	_a = ka
	_b = kb
	_gable(18.3, -19.2, -29.2, 6.7, g + 24.0, 8.0, ZB_WALL, ZB_ROOF, true)
	# the transept ends: a tall arched window, a small one in the gable, a cross on the apex
	for e: Array in [[18.35, 1.0], [-19.25, -1.0]]:
		var eu: float = e[0]
		var sd: float = e[1]
		_zb_arch(_w(eu, -29.2), _b, _a * sd, 2.1, g + 8.5, g + 17.5, ZB_STAINED.darkened(0.45), M_LAMP)
		_zb_arch(_w(eu, -29.2), _b, _a * sd, 0.75, g + 26.0, g + 28.6, ZB_DARK)
		for pv: float in [-31.9, -26.5]:
			_lbox(eu + sd * 0.15, pv, 0.2, 0.35, g + 1.5, g + 23.0, ZB_TRIM, M_STONE, ZB_TRIM)
		_lbox(eu - sd * 0.3, -29.2, 0.12, 0.12, g + 32.0, g + 34.4, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
		_lbox(eu - sd * 0.3, -29.2, 0.12, 0.6, g + 33.4, g + 33.7, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	# the side walls' tall round-headed windows between pilasters: the nave between the towers and
	# the transept, the transept arms' fronts and backs, the choir's free west side
	var glass := ZB_STAINED.darkened(0.45)
	for sd: float in [-1.0, 1.0]:
		for v: float in [-16.0, -19.6]:
			_zb_arch(_w(sd * 7.95, v), _b, _a * sd, 1.0, g + 7.5, g + 16.5, glass, M_LAMP)
		for u: float in [11.0, 15.2]:
			_zb_arch(_w(sd * u, -22.35 if sd > 0.0 else -21.85), _a, _b, 1.0, g + 7.5, g + 16.5, glass, M_LAMP)
			if sd < 0.0:
				_zb_arch(_w(sd * u, -36.15), _a, -_b, 1.0, g + 7.5, g + 16.5, glass, M_LAMP)
		for pv: float in [-14.2, -17.8, -21.4]:
			_lbox(sd * 7.95, pv, 0.12, 0.3, g + 1.5, g + 23.0, ZB_TRIM, M_STONE, ZB_TRIM)
	for v: float in [-40.0, -44.2]:
		_zb_arch(_w(-7.15, v), _b, -_a, 0.9, g + 7.5, g + 15.5, glass, M_LAMP)
	_zb_arch(_w(-1.0, -51.0), _a, -_b, 0.9, g + 7.5, g + 15.5, glass, M_LAMP)
	# --- the front block, before the towers: plinth, two storeys, a cornice
	_lbox(0.0, -2.65, 8.5, 3.15, g - 0.6, g + 1.5, ZB_BASE, M_STONE, ZB_BASE.lightened(0.05))
	_lbox(0.0, -2.65, 8.3, 2.95, g + 1.5, g + 29.5, ZB_WALL, M_STONE, ZB_WALL)
	_lbox(0.0, -2.65, 8.55, 3.2, g + 15.5, g + 17.0, ZB_TRIM, M_STONE, ZB_TRIM)
	_lbox(0.0, -2.65, 8.7, 3.35, g + 29.5, g + 30.6, ZB_TRIM, M_STONE, ZB_WALL.darkened(0.06))
	# the portal: a podium, four grey columns, an entablature and a pediment over the door
	_lbox(0.0, 0.9, 4.4, 0.6, g - 0.6, g + 1.5, ZB_BASE, M_STONE, ZB_BASE.lightened(0.05))
	for k in 3:  # steps up to the podium
		_lbox(0.0, 1.75 + 0.5 * k, 3.6, 0.25, g - 0.6, g + 1.5 - 0.5 * (k + 1), ZB_BASE, M_STONE,
				ZB_BASE.lightened(0.04))
	_zb_arch(_w(0.0, 0.3), _a, _b, 1.5, g + 1.5, g + 7.6, ZB_DARK)
	for u: float in [-3.6, -2.6, 2.6, 3.6]:
		_column(u, 0.9, 0.36, g + 1.5, g + 10.2, ZB_COLUMN)
	_lbox(0.0, 0.85, 4.3, 0.55, g + 10.2, g + 11.1, ZB_TRIM, M_STONE, ZB_TRIM)
	_zb_pediment(1.4, 0.3, 0.0, 4.3, g + 11.1, 2.3, ZB_TRIM, ZB_WALL.darkened(0.1))
	# the side bays: a statue niche (Peter, Paul), a round window over it
	for sd: float in [-1.0, 1.0]:
		_zb_arch(_w(sd * 6.1, 0.3), _a, _b, 0.75, g + 2.8, g + 7.4, ZB_NICHE, M_STONE)
		_lbox(sd * 6.1, 0.55, 0.32, 0.25, g + 2.9, g + 7.2, ZB_TRIM, M_STONE, ZB_TRIM)
		_mode = M_STONE
		var oc := _w(sd * 6.1, 0.36)
		_disc(Vector3(oc.x, g + 12.4, oc.y), Vector3(_b.x, 0.0, _b.y), 1.05, 10, ZB_TRIM)
		var oi := _w(sd * 6.1, 0.42)
		_disc(Vector3(oi.x, g + 12.4, oi.y), Vector3(_b.x, 0.0, _b.y), 0.8, 10, ZB_DARK)
	# pilasters: the ground storey's pairs and corners, the upper storey's pairs round the window
	for u: float in [-7.9, -5.0, -4.3, 4.3, 5.0, 7.9]:
		_lbox(u, 0.42, 0.28, 0.12, g + 1.5, g + 15.5, ZB_TRIM, M_STONE, ZB_TRIM)
		_lbox(u, 0.42, 0.28, 0.12, g + 17.0, g + 29.5, ZB_TRIM, M_STONE, ZB_TRIM)
	# the tall round-headed window with its mullions and transom (stained glass at night)
	_zb_arch(_w(0.0, 0.3), _a, _b, 2.7, g + 18.4, g + 25.2, ZB_STAINED.darkened(0.45), M_LAMP)
	for u: float in [-0.9, 0.9]:
		_lbox(u, 0.45, 0.09, 0.08, g + 18.4, g + 27.6, ZB_TRIM, M_STONE, ZB_TRIM)
	_lbox(0.0, 0.45, 2.7, 0.08, g + 22.6, g + 22.8, ZB_TRIM, M_STONE, ZB_TRIM)
	# the stepped attic: a wide step, a narrow one with a niche, a small pediment and the cross;
	# statues at the cornice's corners, urns on the steps
	_lbox(0.0, -2.2, 5.4, 2.0, g + 30.6, g + 34.4, ZB_WALL, M_STONE, ZB_WALL.darkened(0.06))
	_lbox(0.0, -2.2, 5.7, 2.2, g + 34.4, g + 34.9, ZB_TRIM, M_STONE, ZB_TRIM)
	_lbox(0.0, -2.2, 3.2, 1.8, g + 34.9, g + 38.2, ZB_WALL, M_STONE, ZB_WALL.darkened(0.06))
	_zb_arch(_w(0.0, -0.4), _a, _b, 0.8, g + 35.4, g + 37.0, ZB_NICHE, M_STONE)
	_zb_pediment(-0.35, -4.0, 0.0, 3.4, g + 38.2, 1.7, ZB_TRIM, ZB_ROOF)
	_lbox(0.0, -1.6, 0.13, 0.13, g + 39.6, g + 43.2, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	_lbox(0.0, -1.6, 0.75, 0.13, g + 42.0, g + 42.35, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 7.6, -0.2, 0.42, 0.42, g + 30.6, g + 31.2, ZB_TRIM, M_STONE, ZB_TRIM)
		_lbox(sd * 7.6, -0.2, 0.26, 0.24, g + 31.2, g + 33.4, ZB_NICHE, M_STONE, ZB_NICHE)
		_pinnacle(sd * 4.6, -0.6, 0.6, g + 34.9, 1.6, ZB_TRIM)
	# --- the two towers
	for sd: float in [-1.0, 1.0]:
		var tu := sd * ZB_TOWER_U
		var tv := ZB_TOWER_V
		var c := _w(tu, tv)
		_lbox(tu, tv, 4.2, 4.2, g - 0.6, g + 1.5, ZB_BASE, M_STONE, ZB_BASE.lightened(0.05))
		_lbox(tu, tv, 4.0, 4.0, g + 1.5, g + 29.5, ZB_WALL, M_STONE, ZB_WALL)
		for cu: float in [-1.0, 1.0]:
			for cv: float in [-1.0, 1.0]:
				_lbox(tu + cu * 3.85, tv + cv * 3.85, 0.4, 0.4, g + 1.5, g + 29.5, ZB_TRIM, M_STONE, ZB_TRIM)
		# windows on the shaft's visible front (outside the front block) and outer side
		for y: Array in [[g + 9.0, g + 13.0], [g + 19.5, g + 24.5]]:
			_zb_arch(_w(tu + sd * 1.9, tv + 4.0), _a, _b, 0.65, y[0], y[1], ZB_DARK)
			_zb_arch(_w(tu + sd * 4.0, tv), _b, _a * sd, 0.65, y[0], y[1], ZB_DARK)
			_zb_arch(_w(tu, tv - 4.0), _a, -_b, 0.65, y[0], y[1], ZB_DARK)
		_lbox(tu, tv, 4.45, 4.45, g + 29.5, g + 30.7, ZB_TRIM, M_STONE, ZB_TRIM)
		_lbox(tu, tv, 4.15, 4.15, g + 30.7, g + 31.5, ZB_TRIM, M_STONE, ZB_TRIM)
		for cu: float in [-1.0, 1.0]:
			for cv: float in [-1.0, 1.0]:
				_pinnacle(tu + cu * 3.8, tv + cv * 3.8, 0.7, g + 31.5, 2.2, ZB_TRIM)
		# the square stage: paired arched openings on every face, corner pilasters
		_lbox(tu, tv, 3.3, 3.3, g + 31.0, g + 41.0, ZB_WALL, M_STONE, ZB_WALL)
		for cu: float in [-1.0, 1.0]:
			for cv: float in [-1.0, 1.0]:
				_lbox(tu + cu * 3.2, tv + cv * 3.2, 0.38, 0.38, g + 31.5, g + 41.0, ZB_TRIM, M_STONE, ZB_TRIM)
		for o: float in [-1.05, 1.05]:
			_zb_arch(_w(tu + o, tv + 3.3), _a, _b, 0.55, g + 33.0, g + 38.4, ZB_DARK)
			_zb_arch(_w(tu + o, tv - 3.3), _a, -_b, 0.55, g + 33.0, g + 38.4, ZB_DARK)
			_zb_arch(_w(tu + 3.3, tv + o), _b, _a, 0.55, g + 33.0, g + 38.4, ZB_DARK)
			_zb_arch(_w(tu - 3.3, tv + o), _b, -_a, 0.55, g + 33.0, g + 38.4, ZB_DARK)
		_lbox(tu, tv, 3.8, 3.8, g + 41.0, g + 42.0, ZB_TRIM, M_STONE, ZB_TRIM)
		for cu: float in [-1.0, 1.0]:
			for cv: float in [-1.0, 1.0]:
				_pinnacle(tu + cu * 3.3, tv + cv * 3.3, 0.55, g + 42.0, 1.8, ZB_TRIM)
		# the octagonal belfry with an arched opening on four faces
		_prism(_circle(c, 2.7, 8), g + 42.0, g + 48.5, ZB_WALL, none, M_STONE)
		var fd := 2.7 * cos8
		_zb_arch(_w(tu, tv + fd), _a, _b, 0.45, g + 43.6, g + 46.8, ZB_DARK)
		_zb_arch(_w(tu, tv - fd), _a, -_b, 0.45, g + 43.6, g + 46.8, ZB_DARK)
		_zb_arch(_w(tu + fd, tv), _b, _a, 0.45, g + 43.6, g + 46.8, ZB_DARK)
		_zb_arch(_w(tu - fd, tv), _b, -_a, 0.45, g + 43.6, g + 46.8, ZB_DARK)
		_prism(_circle(c, 3.05, 8), g + 48.5, g + 49.3, ZB_TRIM, ZB_TRIM, M_STONE, M_STONE)
		# the dark green bell cap, the lantern, the bulb and the needle spire to the cross
		_zb_rings(c, ZB_CAP, ZB_SPIRE)
		_prism(_circle(c, 0.75, 8), g + 53.8, g + 56.4, ZB_SPIRE.lightened(0.08), none, M_STONE)
		_prism(_circle(c, 0.95, 8), g + 56.4, g + 56.8, ZB_SPIRE, ZB_SPIRE, M_STONE, M_STONE)
		_zb_rings(c, ZB_BULB, ZB_SPIRE)
		_frustum(_circle(c, 0.32, 6), g + 59.2, _circle(c, 0.05, 6), g + 66.2, ZB_SPIRE, ZB_SPIRE)
		_prism(_circle(c, 0.3, 6), g + 66.0, g + 66.7, ZB_LIT_GOLD, ZB_LIT_GOLD, M_LAMP, M_LAMP)
		_lbox(tu, tv, 0.1, 0.1, g + 66.7, g + 69.6, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
		_lbox(tu, tv, 0.1, 0.6, g + 68.4, g + 68.7, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	# --- the square lantern over the crossing: windows on four faces, a verdigris cap, a cross
	var xu := ZB_CROSSING.x
	var xv := ZB_CROSSING.y
	_lbox(xu, xv, 2.8, 2.8, g + 30.0, g + 36.5, ZB_WALL, M_STONE, ZB_WALL)
	_zb_arch(_w(xu, xv + 2.8), _a, _b, 0.6, g + 32.4, g + 34.8, ZB_DARK)
	_zb_arch(_w(xu, xv - 2.8), _a, -_b, 0.6, g + 32.4, g + 34.8, ZB_DARK)
	_zb_arch(_w(xu + 2.8, xv), _b, _a, 0.6, g + 32.4, g + 34.8, ZB_DARK)
	_zb_arch(_w(xu - 2.8, xv), _b, -_a, 0.6, g + 32.4, g + 34.8, ZB_DARK)
	_lbox(xu, xv, 3.1, 3.1, g + 36.5, g + 37.1, ZB_TRIM, M_STONE, ZB_TRIM)
	var xc := _w(xu, xv)
	_zb_rings(xc, [[3.2, 37.1], [2.9, 38.4], [1.8, 39.8], [0.6, 40.6]], ZB_ROOF)
	_prism(_circle(xc, 0.5, 8), g + 40.6, g + 42.0, ZB_WALL, none, M_STONE)
	_frustum(_circle(xc, 0.7, 8), g + 42.0, _circle(xc, 0.1, 8), g + 43.2, ZB_ROOF, ZB_ROOF)
	_lbox(xu, xv, 0.1, 0.1, g + 43.2, g + 45.6, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	_lbox(xu, xv, 0.5, 0.1, g + 44.6, g + 44.9, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	# --- the low chapel behind the east transept arm with its dome, drum and lantern
	var cu0 := ZB_CHAPEL.x
	var cv0 := ZB_CHAPEL.y
	_lbox(cu0, cv0, 4.4, 5.0, g - 0.6, g + 1.5, ZB_BASE, M_STONE, ZB_BASE.lightened(0.05))
	_lbox(cu0, cv0, 4.2, 4.8, g + 1.5, g + 10.6, ZB_WALL, M_STONE, ZB_WALL)
	_zb_arch(_w(cu0 + 4.2, cv0), _b, _a, 0.8, g + 4.0, g + 8.4, ZB_STAINED.darkened(0.45), M_LAMP)
	_zb_arch(_w(cu0, cv0 - 4.8), _a, -_b, 0.8, g + 4.0, g + 8.4, ZB_STAINED.darkened(0.45), M_LAMP)
	_lbox(cu0, cv0, 4.5, 5.1, g + 10.6, g + 11.3, ZB_TRIM, M_STONE, ZB_WALL.darkened(0.06))
	var cc := _w(cu0, cv0)
	_prism(_circle(cc, 3.1, 8), g + 11.3, g + 13.3, ZB_WALL, none, M_STONE)
	_zb_rings(cc, [[3.4, 13.3], [3.2, 14.7], [2.6, 15.9], [1.6, 16.9], [0.6, 17.3]], ZB_ROOF)
	_prism(_circle(cc, 0.6, 8), g + 17.3, g + 18.6, ZB_WALL, none, M_STONE)
	_frustum(_circle(cc, 0.8, 8), g + 18.6, _circle(cc, 0.1, 8), g + 19.6, ZB_ROOF, ZB_ROOF)
	_lbox(cu0, cv0, 0.08, 0.08, g + 19.6, g + 21.2, ZB_LIT_GOLD, M_LAMP, ZB_LIT_GOLD)
	# --- night: lanterns at the portal's pilasters, stained round windows, floodlamps
	_mode = M_LAMP
	for sd: float in [-1.0, 1.0]:
		var lw := _w(sd * 6.1, 0.48)
		_disc(Vector3(lw.x, g + 12.4, lw.y), Vector3(_b.x, 0.0, _b.y), 0.62, 8, ZB_STAINED)
	for u: float in [-7.9, -4.65, 4.65, 7.9]:
		_lbox(u, 0.7, 0.12, 0.12, g + 5.6, g + 6.3, ZB_LAMP, M_LAMP, ZB_LAMP)
	for f: Array in ZB_FLOODS:
		_lbox(f[0], f[1], 0.3, 0.3, g - 0.1, g + 0.3, ZB_LAMP, M_LAMP, ZB_LAMP)
	_mode = M_STONE
	# the car meets the walls
	_collide(outline)
	_collide(_rect(0.0, -2.65, 8.5, 3.15))
	for sd: float in [-1.0, 1.0]:
		_collide(_rect(sd * ZB_TOWER_U, ZB_TOWER_V, 4.2, 4.2))
	_collide(_rect(0.0, 1.6, 4.4, 1.6))
	_collide(_rect(cu0, cv0, 4.4, 5.0))


# --- Centrum Nauki Kopernik ---------------------------------------------------------------------

## All Saints (Kościół Wszystkich Świętych; Marconi and Dziekoński, 1861–1892) on Plac Grzybowski.
## Rebuilt 2026-11-26 as one model replacing LoD2: the two-storey portal screen, twin bell-capped
## towers, open arcades and the full Latin-cross church under copper roofs and a crossing dome.
## Sources: Google Photorealistic 3D Tiles, Street View, the 2026-11-06 photo report and LoD2
## heights, as gathered in docs/landmarks/specs/wszystkich.md.
## The frame starts at the front middle: u runs west-south-west and +v runs into the church.
const WSZ := Vector2(-1410.12, -159.08)
const WSZ_U := Vector2(-0.9238, 0.3829)
const WSZ_V := Vector2(0.3829, 0.9238)
const WSZ_FACE := -0.001  ## The front plane faces -v in the shared spandrel helper.
const WSZ_PORTALS := [Vector3(-6.6, 1.3, 5.5), Vector3(0.0, 2.4, 7.2), Vector3(6.6, 1.3, 5.5)]  ## Axis, half-width, spring.
const WSZ_PORTAL_BACK := 0.61
const WSZ_WALL := Color("#c6b186")
const WSZ_TRIM := Color("#d6c9a6")
const WSZ_BASE := Color("#b5aa8e")
const WSZ_COPPER := Color("#96b8a4")  ## pale copper (3D Tiles; the game light reads it darker)
const WSZ_DARK := Color("#3a3d40")
const WSZ_GOLD := Color("#c9a24a")
const WSZ_RELIEF := Color("#8f8466")
const WSZ_NO_CAP := Color(0, 0, 0, 0)


## Build the whole church on the terrain datum at the front middle, with collision at the outline
## and the steps and arcades that extend into the square.
func _build_wszystkich(site: Dictionary) -> void:
	_wsz_body_frame()
	_g = map.terrain_height(WSZ.x, WSZ.y)
	_mode = M_STONE
	_wsz_nave()
	_wsz_transept()
	_wsz_drum()
	_wsz_chancel()
	_wsz_sanctuary()
	_wsz_screen()
	_wsz_steps()
	for side: float in [-1.0, 1.0]:
		_wsz_tower(side * 14.8)
		_wsz_arcade(side)
	_collide(site["zone"][0])


## Restore the plan axes after working on an outward-facing facade.
func _wsz_body_frame() -> void:
	_o = WSZ
	_a = WSZ_U.normalized()
	_b = WSZ_V.normalized()
	kit_face(0.0)


## Convert a local plan point and height above the church datum into a mesh vertex.
func _wsz_point(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, _g + y, p.y)


## Give the portal and arcade arches masonry depth, using the same six segments as the spandrel.
func _wsz_arch_reveal(u: float, hw: float, y0: float, spring: float, back: float) -> void:
	_wall(_w(u - hw, WSZ_FACE), _w(u - hw, back), _g + y0, _g + spring, _a, WSZ_TRIM)
	_wall(_w(u + hw, WSZ_FACE), _w(u + hw, back), _g + y0, _g + spring, -_a, WSZ_TRIM)
	var prev := Vector2(u + hw, spring)
	for k in range(1, 7):
		var ang := PI * k / 6.0
		var next := Vector2(u + cos(ang) * hw, spring + sin(ang) * hw)
		var a := _wsz_point(prev.x, WSZ_FACE, prev.y)
		var b := _wsz_point(next.x, WSZ_FACE, next.y)
		var c := _wsz_point(next.x, back, next.y)
		var d := _wsz_point(prev.x, back, prev.y)
		var normal := (b - a).cross(d - a).normalized()
		_quad(a, b, c, d, normal, WSZ_TRIM)


## Build the facade's two orders, with pairs of pilasters on the same four axes in each storey.
func _wsz_screen() -> void:
	kit_front(WSZ, WSZ + WSZ_U * 20.0)
	kit_face(-0.60)
	for opening: Vector3 in WSZ_PORTALS:
		# Emit the glass first so wall clipping keeps it in front of the kit door.
		var at := _w(opening.x, -0.5)
		var along := _a * opening.y
		_mode = M_GLASS
		_wall(at - along, at + along, _g + 1.2, _g + opening.z, _b, WSZ_DARK)
		_arch_cap(_wsz_point(opening.x, -0.5, opening.z), Vector3(_b.x, 0.0, _b.y), opening.y, 6, WSZ_DARK)
		_mode = M_STONE
		kit_door(opening.x, _g + 1.2, opening.z + opening.y - 1.2, opening.y, WSZ_TRIM, WSZ_DARK, true)
	kit_face(-1.76)
	kit_ledge(-10.9, 10.9, _g + 10.5, 0.68, WSZ_TRIM, 2.04)
	# The projecting slab meets the tower bands.
	kit_ledge(-10.45, 10.45, _g + 11.18, 0.32, WSZ_TRIM, 2.36)
	kit_ledge(-10.9, 10.9, _g + 20.2, 0.48, WSZ_TRIM, 2.07)
	kit_ledge(-10.9, 10.9, _g + 20.68, 0.32, WSZ_TRIM, 2.28)
	kit_face(-WSZ_FACE)
	for u: float in [-8.8, -4.4, 4.4, 8.8]:
		for offset: float in [-0.37, 0.37]:
			var axis := u + offset
			kit_ledge(axis - 0.3, axis + 0.3, _g + 1.23, 8.91, WSZ_TRIM, 0.35)
			kit_ledge(axis - 0.35, axis + 0.35, _g + 10.14, 0.33, WSZ_TRIM, 0.41)
			kit_pilaster(axis, _g + 11.53, _g + 20.17, WSZ_TRIM, 0.6, 0.35)
	_arch_panel(_w(0.0, _face), _a, _b, 1.8, _g + 13.0, _g + 17.4, WSZ_DARK, 0.085, M_GLASS)
	for u: float in [-2.3, 2.3]:
		kit_column(u, 0.22, _g + 12.76, _g + 19.2, WSZ_TRIM, 0.26)
	kit_ledge(-2.66, 2.66, _g + 12.55, 0.21, WSZ_TRIM, 0.48)
	kit_pediment(0.0, 2.65, _g + 19.2, 0.82, WSZ_TRIM, WSZ_TRIM, 0.59)
	for u: float in [-6.6, 6.6]:
		kit_window(u, _g + 13.8, 3.6, Win.FRAMED, WSZ_TRIM, WSZ_DARK, 0.8)
		kit_pediment(u, 1.2, _g + 17.62, 0.55, WSZ_TRIM, WSZ_TRIM, 0.32)
	for side: float in [-1.0, 1.0]:
		for tier in 3:
			var u := side * (10.35 - 0.24 * tier)
			var hw := 0.62 - 0.1 * tier
			kit_ledge(u - hw, u + hw, _g + 11.5 + 0.55 * tier, 0.55, WSZ_TRIM, 0.54)
	# A second, inset gable leaves the sloped stone trim visible around the field.
	kit_face(-1.8)
	kit_pediment(0.0, 10.9, _g + 20.68, 3.82, WSZ_TRIM, WSZ_COPPER, 2.21)
	kit_face(0.40)
	kit_pediment(0.0, 9.94, _g + 21.0, 3.17, WSZ_WALL, WSZ_WALL, 0.045)
	_disc(_wsz_point(0.0, 0.49, 22.47), Vector3(_b.x, 0.0, _b.y), 0.91, 16, WSZ_RELIEF)
	_wsz_body_frame()
	_ubox(-10.9, 10.9, 0.0, 1.8, _g - 1.2, _g + 1.2, WSZ_BASE, M_STONE, WSZ_BASE)
	_ubox(-10.9, 10.9, WSZ_PORTAL_BACK, 1.8, _g + 1.18, _g + 10.52, WSZ_WALL)
	_wsz_portals()
	_ubox(-10.9, 10.9, WSZ_FACE, 1.8, _g + 11.5, _g + 20.2, WSZ_WALL)
	_wsz_cross(0.0, 0.32, 24.5, 27.0, 0.09, 0.65)


## Build the three cutouts and the half-metre reveals in front of the door leaves.
func _wsz_portals() -> void:
	var last := -10.9
	for opening: Vector3 in WSZ_PORTALS:
		var left := opening.x - opening.y
		var right := opening.x + opening.y
		_wall(_w(last, WSZ_FACE), _w(left, WSZ_FACE), _g + 1.2, _g + 10.5, -_b, WSZ_WALL)
		_arch(left, right, WSZ_FACE, _g + opening.z, _g + 10.5, WSZ_WALL)
		_wsz_arch_reveal(opening.x, opening.y, 1.2, opening.z, WSZ_PORTAL_BACK)
		last = right
	_wall(_w(last, WSZ_FACE), _w(10.9, WSZ_FACE), _g + 1.2, _g + 10.5, -_b, WSZ_WALL)


## Form five treads from the square up to the portal sill and collide their street footprint.
func _wsz_steps() -> void:
	for k in 5:
		_ubox(-9.0, 9.0, -3.0 + 0.6 * k, 0.0, _g - 0.55, _g + 0.24 * (k + 1),
				WSZ_BASE, M_STONE, WSZ_BASE)
	_collide(_urect(-9.0, 9.0, -3.0, 0.0))


## Build one of the paired tower shafts, with the cornices separating its three square stages.
func _wsz_tower(u: float) -> void:
	var c := Vector2(u, 3.9)
	var centre := _wl(c)
	var street := -_b
	var flank := _a
	kit_front(centre, centre + flank * 8.0)
	for course: Vector3 in [Vector3(4.35, 11.18, 11.5), Vector3(4.1, 19.5, 20.0),
			Vector3(3.98, 27.0, 27.5), Vector3(4.03, 35.2, 35.65), Vector3(4.2, 35.65, 36.0)]:
		kit_face(0.04 - course.x)
		kit_ledge(-course.x, course.x, _g + course.y, course.z - course.y, WSZ_TRIM, 2.0 * course.x - 0.04)
	for out: Vector2 in [street, flank, -street, -flank]:
		kit_front(centre, centre + Vector2(out.y, -out.x) * 8.0)
		kit_face(3.9)
		# The screen and nave cover both lower courses on the inward face.
		if out.dot(flank) * signf(u) > -0.9:
			for offset: float in [-3.4, 3.4]:
				var behind_nave := out.dot(street) < -0.9 and offset * u > 0.0
				if not behind_nave:
					kit_ledge(offset - 0.27, offset + 0.27, _g + 1.22, 9.93, WSZ_TRIM, 0.19)
				kit_ledge(offset - 0.27, offset + 0.27, _g + 11.5, 7.98, WSZ_TRIM, 0.19)
		if out.dot(street) > 0.9 or out.dot(flank) * signf(u) > 0.9:
			var normal := Vector3(_b.x, 0.0, _b.y)
			_disc(_wsz_point(0.0, _face + 0.045, 15.0), normal, 1.16, 12, WSZ_TRIM)
			_mode = M_GLASS
			_disc(_wsz_point(0.0, _face + 0.085, 15.0), normal, 1.0, 12, WSZ_DARK)
			_mode = M_STONE
		kit_face(3.7)
		for offset: float in [-3.18, 3.18]:
			kit_ledge(offset - 0.26, offset + 0.26, _g + 20.03, 6.95, WSZ_TRIM, 0.19)
		kit_face(3.735)
		kit_window(0.0, _g + 21.8, 3.7, Win.PLAIN, WSZ_TRIM, WSZ_DARK, 0.8)
		_mode = _lit(0.0, _g + 21.8)
		_arch_cap(_wsz_point(0.0, _face + 0.05, 25.5), Vector3(_b.x, 0.0, _b.y), 0.8, 4, WSZ_DARK)
		_mode = M_STONE
		kit_face(3.55)
		for offset: float in [-3.15, -2.44, 2.44, 3.15]:
			kit_ledge(offset - 0.25, offset + 0.25, _g + 27.53, 7.65, WSZ_TRIM, 0.23)
		kit_face(3.565)
		kit_door(0.0, _g + 29.0, 5.5, 1.3, WSZ_TRIM, WSZ_DARK, true)
	_wsz_body_frame()
	_lbox(u, c.y, 4.03, 4.03, _g - 1.2, _g + 1.2, WSZ_BASE, M_STONE, WSZ_BASE)
	_prism(_rect(u, c.y, 3.9, 3.9), _g + 1.2, _g + 20.0, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	_prism(_rect(u, c.y, 3.7, 3.7), _g + 20.0, _g + 27.5, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	_prism(_rect(u, c.y, 3.55, 3.55), _g + 27.5, _g + 36.0, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	_wsz_tower_urns(c)
	_wsz_tower_lantern(c)
	_wsz_tower_cap(c)
	_wsz_tower_top(c)


## Anchor a small stacked stone urn to each corner of the belfry cornice.
func _wsz_tower_urns(c: Vector2) -> void:
	for du: float in [-3.52, 3.52]:
		for dv: float in [-3.52, 3.52]:
			_lbox(c.x + du, c.y + dv, 0.35, 0.35, _g + 36.0, _g + 36.28, WSZ_TRIM)
			_lbox(c.x + du, c.y + dv, 0.25, 0.25, _g + 36.28, _g + 37.16, WSZ_TRIM)
			_lbox(c.x + du, c.y + dv, 0.29, 0.29, _g + 37.16, _g + 37.5, WSZ_TRIM)


## Alternate stone piers and eight tall dark arches on the sixteen-sided lantern.
func _wsz_tower_lantern(c: Vector2) -> void:
	var centre := _wl(c)
	var ring := _circle(centre, 2.9, 16)
	_prism(ring, _g + 36.0, _g + 43.0, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	kit_ledge_ring(ring, _g + 36.0, 0.45, WSZ_TRIM, 0.12)
	_wsz_lantern_panels(ring, 2, 0.47, 36.65, 41.75, M_STONE, 0.26)
	kit_ledge_ring(ring, _g + 43.0, 0.5, WSZ_TRIM, 0.23)


## Put arches on the facets themselves, leaving every group of facets divided by a stone pilaster.
func _wsz_lantern_panels(ring: PackedVector2Array, group: int, hw: float, sill: float, spring: float,
		mode: float, pilaster: float) -> void:
	for k in ring.size():
		var p := ring[k]
		var q := ring[(k + 1) % ring.size()]
		var at := (p + q) * 0.5
		var along := (q - p).normalized()
		var out := _out(ring, p, q)
		if k % group == 0:
			kit_front(q, p)
			var mid := p.distance_to(q) * 0.5
			kit_ledge(mid - pilaster, mid + pilaster, _g + sill - 0.34, spring + hw - sill + 0.61, WSZ_TRIM, 0.21)
		else:
			_arch_panel(at, along, out, hw, _g + sill, _g + spring, WSZ_DARK, 0.045, mode)
	_wsz_body_frame()


## Join a curved copper profile with open frustums so the stacked rings share their edges.
func _wsz_ring_stack(centre: Vector2, sides: int, profile: Array[Vector2], col: Color) -> void:
	var ring := _circle(centre, profile[0].x, sides)
	for k in range(1, profile.size()):
		var next := _circle(centre, profile[k].x, sides)
		_frustum(ring, _g + profile[k - 1].y, next, _g + profile[k].y, col)
		ring = next


## Shape the copper bell with a flared lower lip and an ogee shoulder under the finial lantern.
func _wsz_tower_cap(c: Vector2) -> void:
	_wsz_ring_stack(_wl(c), 16, [Vector2(3.1, 43.5), Vector2(2.93, 44.05), Vector2(2.53, 44.85),
			Vector2(1.77, 46.2), Vector2(1.1, 47.52), Vector2(0.9, 48.5)], WSZ_COPPER)


## Finish the tower with its four-opening lantern, copper cap, gilt ball and cross.
func _wsz_tower_top(c: Vector2) -> void:
	var centre := _wl(c)
	var ring := _circle(centre, 0.8, 8)
	_prism(_circle(centre, 0.92, 16), _g + 48.5, _g + 48.7, WSZ_TRIM, WSZ_TRIM, M_STONE)
	_prism(ring, _g + 48.7, _g + 51.5, WSZ_TRIM, WSZ_NO_CAP, M_STONE)
	_wsz_lantern_panels(ring, 2, 0.23, 49.08, 50.53, M_STONE, 0.12)
	_wsz_ring_stack(centre, 8, [Vector2(0.95, 51.5), Vector2(0.59, 51.97), Vector2(0.19, 52.25)], WSZ_COPPER)
	_wsz_ring_stack(centre, 8, [Vector2(0.18, 52.25), Vector2(0.32, 52.51),
			Vector2(0.28, 52.74), Vector2(0.08, 52.88)], WSZ_GOLD)
	_wsz_cross(c.x, c.y, 52.88, 55.0, 0.07, 0.55)


## Make the cross arms butt against the staff so their front faces share an edge.
func _wsz_cross(u: float, v: float, foot: float, top: float, half: float, reach: float) -> void:
	_lbox(u, v, half, half, _g + foot, _g + top, WSZ_GOLD)
	var arm := lerpf(foot, top, 0.63)
	_ubox(u - reach, u - half, v - half, v + half, _g + arm - half, _g + arm + half, WSZ_GOLD)
	_ubox(u + half, u + reach, v - half, v + half, _g + arm - half, _g + arm + half, WSZ_GOLD)


## Raise the side walls with a darker continuous plinth and a moulded cornice at the eaves.
func _wsz_body(u0: float, u1: float, v0: float, v1: float, eave: float) -> void:
	var ring := _urect(u0, u1, v0, v1)
	_prism(ring, _g - 1.2, _g + eave, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	_ubox(u0 - 0.15, u1 + 0.15, v0 + 0.04, v1 - 0.04, _g - 1.21, _g + 1.2, WSZ_BASE, M_STONE, WSZ_BASE)
	var frieze := maxf(eave - 1.0, 14.56)
	var back := _w(0.0, v1)
	kit_front(back, back + _a * 20.0)
	# Each solid course spans the plan below the roof.
	kit_face(0.08)
	kit_ledge(u0 - 0.21, u1 + 0.21, _g + frieze, eave - 0.32 - frieze, WSZ_TRIM, v1 - v0 - 0.12)
	kit_face(0.04)
	kit_ledge(u0 - 0.3, u1 + 0.3, _g + eave - 0.32, 0.32, WSZ_TRIM, v1 - v0 - 0.04)
	_wsz_body_frame()


## Build the long nave and pilaster bays between the front towers and the crossing transept.
func _wsz_nave() -> void:
	_wsz_body(-15.5, 15.5, 1.8, 48.3, 17.0)
	_wsz_side_bays(17.0, [8.0, 16.0, 24.0, 32.0, 40.0, 48.0], [12.0, 20.0, 28.0, 36.0, 44.0])
	_wsz_nave_roof()


## Carry the nave's bay treatment onto the chancel, lowering the cornice to its own eave.
func _wsz_side_bays(eave: float, piers: Array[float], windows: Array[float]) -> void:
	for side: float in [-1.0, 1.0]:
		var start := _w(15.5 * side, 0.0)
		kit_front(start, start + _b * side * 40.0)
		for v in piers:
			var u := v * side
			kit_ledge(u - 0.33, u + 0.33, _g + 1.23, eave - 2.59, WSZ_TRIM, 0.19)
			kit_ledge(u - 0.38, u + 0.38, _g + eave - 1.36, 0.33, WSZ_TRIM, 0.26)
		for v in windows:
			var u := v * side
			_arch_panel(_w(u, 0.0), _a, _b, 1.1, _g + 8.0, _g + 12.9, WSZ_DARK, 0.085, M_GLASS)
			kit_ledge(u - 1.31, u + 1.31, _g + 7.63, 0.19, WSZ_TRIM, 0.25)
			kit_pediment(u, 1.38, _g + 14.13, 0.39, WSZ_TRIM, WSZ_TRIM, 0.12)
		_wsz_body_frame()


## Lay a planar copper face with its normal facing skyward. A repeated final vertex makes a hip.
func _wsz_roof_face(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	if c == d:
		var uv := Vector2(-1.0, -1.0)
		_tri(a, b, c, normal, WSZ_COPPER, uv, uv, uv, -1.0)
	else:
		_quad(a, b, c, d, normal, WSZ_COPPER)


## Pitch the copper nave up from its front hip to the ridge and into the transept's north valley.
func _wsz_nave_roof() -> void:
	var hip_foot := 1.8
	var hip_peak := 10.0
	var ridge_front := _wsz_point(0.0, hip_peak, 26.0)
	var ridge_crossing := _wsz_point(0.0, 55.95, 26.0)
	var cheek_end := lerpf(48.3, 55.95, 0.1)
	var shoulder := lerpf(hip_foot, hip_peak, (21.0 - 17.0) / 9.0)
	var crest := lerpf(hip_foot, hip_peak, (24.5 - 17.0) / 9.0)
	var front_left := _wsz_point(-15.5, hip_foot, 17.0)
	var front_right := _wsz_point(15.5, hip_foot, 17.0)
	_wsz_roof_face(front_left, front_right, ridge_front, ridge_front)
	for side: float in [-1.0, 1.0]:
		var u := 15.5 * side
		_wsz_roof_face(_wsz_point(u, hip_foot, 17.0), _wsz_point(u, cheek_end, 17.0), ridge_crossing, ridge_front)
		# The smaller copper roof behind the pediment ends where it meets the nave hip.
		var edge := _wsz_point(10.9 * side, hip_foot, 21.0)
		var valley := _wsz_point(10.9 * side, shoulder, 21.0)
		_wsz_roof_face(edge, valley, _wsz_point(0.0, crest, 24.5), _wsz_point(0.0, hip_foot, 24.5))
		var uv := Vector2(-1.0, -1.0)
		var normal := Vector3(_a.x * side, 0.0, _a.y * side)
		_tri(_wsz_point(10.9 * side, hip_foot, 17.0), edge, valley, normal, WSZ_WALL, uv, uv, uv, -1.0)
		var low := _wsz_point(u, 48.3, 16.0)
		var high := _wsz_point(u, 48.3, 17.0)
		var end := _wsz_point(u, cheek_end, 17.0)
		_tri(low, high, end, normal, WSZ_WALL, uv, uv, uv, -1.0)


## Cross the nave ridge with the gabled transept, dressing the two ends in a two-tier order.
func _wsz_transept() -> void:
	_wsz_body(-20.8, 20.8, 48.3, 63.6, 16.0)
	_gable(-20.8, 20.8, 55.95, 7.65, _g + 16.0, 10.0, WSZ_WALL, WSZ_COPPER)
	for side: float in [-1.0, 1.0]:
		var centre := _w(20.8 * side, 55.95)
		kit_front(centre, centre + _b * side * 15.3)
		kit_ledge(-7.66, 7.66, _g + 5.08, 0.44, WSZ_TRIM, 0.24)
		for v: float in [49.1, 52.1, 59.8, 62.8]:
			var u := (v - 55.95) * side
			kit_ledge(u - 0.32, u + 0.32, _g + 1.23, 3.85, WSZ_TRIM, 0.26)
			kit_ledge(u - 0.4, u + 0.4, _g + 5.55, 9.02, WSZ_TRIM, 0.31)
			kit_ledge(u - 0.47, u + 0.47, _g + 14.57, 0.43, WSZ_TRIM, 0.37)
		_arch_panel(_w(0.0, 0.0), _a, _b, 1.5, _g + 6.0, _g + 11.5, WSZ_DARK, 0.085, M_GLASS)
		kit_face(-0.05)
		kit_pediment(0.0, 7.65, _g + 15.62, 10.35, WSZ_TRIM, WSZ_TRIM, 0.28)
		kit_face(0.22)
		kit_pediment(0.0, 7.31, _g + 16.0, 9.56, WSZ_WALL, WSZ_WALL, 0.045)
		_wsz_body_frame()


## Sit the windowed crossing drum on a copper skirt through the intersecting roof slopes.
func _wsz_drum() -> void:
	var centre := _w(0.0, 56.0)
	var ring := _circle(centre, 5.6, 24)
	_prism(ring, _g + 18.0, _g + 24.0, WSZ_COPPER, WSZ_NO_CAP, M_STONE)
	_prism(ring, _g + 24.0, _g + 33.0, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	kit_ledge_ring(ring, _g + 24.0, 0.32, WSZ_TRIM, 0.12)
	_wsz_lantern_panels(ring, 3, 0.5, 27.0, 29.9, M_GLASS, 0.28)
	kit_ledge_ring(ring, _g + 33.0, 0.5, WSZ_TRIM, 0.31)
	_wsz_dome(centre)
	_wsz_dome_lantern(centre)


## Form the dome from sixteen-sided rings and follow every second seam with a raised rib.
func _wsz_dome(centre: Vector2) -> void:
	var profile: Array[Vector2] = [Vector2(5.8, 33.5), Vector2(5.54, 34.62),
			Vector2(4.65, 36.32), Vector2(3.2, 37.73), Vector2(1.4, 38.5)]
	_wsz_ring_stack(centre, 16, profile, WSZ_COPPER)
	var ring := _circle(centre, profile[0].x, 16)
	for k in range(1, profile.size()):
		var next := _circle(centre, profile[k].x, 16)
		for rib in range(0, 16, 2):
			var p := ring[rib]
			var q := next[rib]
			var foot := Vector3(p.x, _g + profile[k - 1].y, p.y)
			var head := Vector3(q.x, _g + profile[k].y, q.y)
			var side := Vector3.UP.cross(head - foot).normalized() * 0.06
			var crest0 := foot + Vector3.UP * 0.06
			var crest1 := head + Vector3.UP * 0.06
			# The raised copper fold shares its underside with the dome skin.
			for edge: Vector3 in [side, -side]:
				var normal := ((head - foot).cross(crest0 - foot - edge)).normalized()
				_quad(foot + edge, head + edge, crest1, crest0, normal * signf(normal.y),
						WSZ_COPPER.lightened(0.11))
		ring = next


## Crown the dome with its octagonal lantern, arched windows, small copper cap and gilt cross.
func _wsz_dome_lantern(centre: Vector2) -> void:
	var ring := _circle(centre, 1.4, 8)
	_prism(_circle(centre, 1.53, 16), _g + 38.5, _g + 38.72, WSZ_TRIM, WSZ_TRIM, M_STONE)
	_prism(ring, _g + 38.72, _g + 41.5, WSZ_WALL, WSZ_NO_CAP, M_STONE)
	for k in ring.size():
		var p := ring[k]
		var q := ring[(k + 1) % ring.size()]
		var mid := kit_front(q, p) * 0.5
		kit_face(0.035)
		kit_window(mid, _g + 39.05, 1.48, Win.PLAIN, WSZ_TRIM, WSZ_DARK, 0.29)
		_mode = _lit(mid, _g + 39.05)
		_arch_cap(_wsz_point(mid, 0.085, 40.53), Vector3(_b.x, 0.0, _b.y), 0.29, 4, WSZ_DARK)
		_mode = M_STONE
	_wsz_body_frame()
	kit_ledge_ring(ring, _g + 41.27, 0.23, WSZ_TRIM, 0.14)
	_wsz_ring_stack(centre, 8, [Vector2(1.52, 41.5), Vector2(1.15, 42.04), Vector2(0.11, 42.42)], WSZ_COPPER)
	_wsz_cross(0.0, 56.0, 42.42, 44.0, 0.065, 0.42)


## Finish the body after the transept with a lower pitched ridge and a hip over the rear wall.
func _wsz_chancel() -> void:
	_wsz_body(-15.5, 15.5, 63.6, 77.3, 15.0)
	_wsz_side_bays(15.0, [64.1, 70.45, 76.8], [67.28, 73.62])
	var ridge_join := _wsz_point(0.0, lerpf(55.95, 63.6, 0.2), 24.0)
	var ridge_back := _wsz_point(0.0, 71.0, 24.0)
	for side: float in [-1.0, 1.0]:
		var u := 15.5 * side
		_wsz_roof_face(_wsz_point(u, 63.6, 15.0), _wsz_point(u, 77.3, 15.0), ridge_back, ridge_join)
	_wsz_roof_face(_wsz_point(-15.5, 77.3, 15.0), _wsz_point(15.5, 77.3, 15.0), ridge_back, ridge_back)


## Close the sanctuary's low rear projection with stone walls and a small copper hip.
func _wsz_sanctuary() -> void:
	# Flat UVs keep the large rear slab in the monument palette without patterned windows.
	_mode = M_MONUMENT
	_quad(_wsz_point(-7.1, 80.4, -1.2), _wsz_point(6.6, 80.4, -1.2),
			_wsz_point(6.6, 80.4, 10.0), _wsz_point(-7.1, 80.4, 10.0),
			Vector3(_b.x, 0.0, _b.y), WSZ_WALL)
	_mode = M_STONE
	for u: float in [-7.1, 6.6]:
		_wall(_w(u, 77.3), _w(u, 80.4), _g - 1.2, _g + 10.0, _a * signf(u), WSZ_WALL)
	_ubox(-7.25, 6.75, 77.35, 80.55, _g - 1.21, _g + 1.2, WSZ_BASE, M_STONE, WSZ_BASE)
	kit_ledge_ring(_urect(-7.1, 6.6, 77.51, 80.4), _g + 9.62, 0.38, WSZ_TRIM, 0.16)
	_hip(-0.25, 78.85, 7.01, 1.71, _g + 10.0, 2.0, WSZ_COPPER)


## Run five open arches out from a tower, with a paved gallery behind the rusticated piers.
func _wsz_arcade(side: float) -> void:
	var u0 := minf(side * 18.7, side * 38.7)
	var u1 := u0 + 20.0
	_ubox(u0, u1, 0.0, 4.5, _g - 1.2, _g + 0.03, WSZ_BASE, M_STONE, WSZ_BASE)
	_ubox(u0, u1, 4.23, 4.5, _g, _g + 7.2, WSZ_WALL)
	# The gallery stays open in front. Its recessed inner face gives the arches their depth in shade.
	_wall(_w(u0 + 0.06, 4.19), _w(u1 - 0.06, 4.19), _g + 0.03, _g + 7.12, -_b, WSZ_DARK)
	for bay in 5:
		var u := u0 + 2.0 + 4.0 * bay
		_arch(u - 1.45, u + 1.45, WSZ_FACE, _g + 5.0, _g + 7.2, WSZ_WALL)
		_wsz_arch_reveal(u, 1.45, 0.03, 5.0, 0.82)
	for k in 6:
		var u := u0 + 4.0 * k
		var left := maxf(u - 0.55, u0)
		var right := minf(u + 0.55, u1)
		_ubox(left, right, WSZ_FACE, 0.82, _g + 0.03, _g + 7.18, WSZ_WALL)
	var canopy := _urect(u0 - 0.08, u1 + 0.08, -0.18, 4.61)
	_soffit(canopy, _g + 7.2, WSZ_WALL)
	kit_front(WSZ, WSZ + WSZ_U * 20.0)
	kit_face(0.04 - 4.61)
	kit_ledge(u0 - 0.08, u1 + 0.08, _g + 7.2, 0.48, WSZ_TRIM, 4.75)
	kit_face(0.04 - 4.7)
	kit_ledge(u0 - 0.17, u1 + 0.17, _g + 7.68, 0.32, WSZ_TRIM, 4.9)
	kit_face(-WSZ_FACE)
	for k in 6:
		var u := u0 + 4.0 * k
		var left := maxf(u - 0.55, u0)
		var right := minf(u + 0.55, u1)
		for band in 4:
			var y := 0.26 + 1.14 * band
			kit_ledge(left + 0.035, right - 0.035, _g + y, 0.95, WSZ_TRIM, 0.094)
	_wsz_body_frame()
	_hip((u0 + u1) * 0.5, 2.23, 10.17, 2.47, _g + 8.0, 1.5, WSZ_COPPER)
	_collide(_urect(u0, u1, 0.0, 4.5))


## The Visitationists' church (Kościół Wizytek, św. Józefa Oblubieńca; Karol Bay 1728-1733, the
## front by Ephraim Schröger 1756-1761) on Krakowskie Przedmieście, its front to the west, to the
## street and Cardinal Wyszyński's statue. Rebuilt 2026-11-14 as the whole building (it replaces
## LoD2; the 2026-11-01 model had put the front on the wrong, east end) from F's straight-on photo
## of the front and his close-up of the turret, 14 Panoramax views from the street and the square
## (refs/wizytki_far, never shipped) and GUGiK's LoD2 (heights over the ground: the front's lower
## cornice 9.4, upper cornice 18.6, its crown 25.3; nave eaves 18.6, ridge 25.2 with a hip at the
## east; aisles 9.6; chancel to 14; the south wing to 15). Spec docs/landmarks/specs/wizytki.md.
## - the cream two-storey front: a lower order of six pairs of Corinthian columns over the whole
##   24 m (the middle four pairs on a forward block), blind arched niches with medallions, the
##   iron-black door, a balcony and an arched window over it; an upper order of four pairs with
##   statues of bishops in niches and a great arched window, a broken pediment; concave sweeps
##   with urns on both storeys; a crown with a statue group in a niche, four saints on the
##   cornice, angels on scrolled corners, a ball and the cross;
## - the nave under a steep red tile roof with an east hip, cream walls with arched clerestory
##   windows between lesenes, the aisles' lean-to roofs, arched windows below; the lower chancel
##   under its own tile roof; the south wing by the university's house;
## - the copper turret over the nave's east end: an open arched stage, a bell cap, an onion, a
##   small lantern, a ball and a cross.
## Frame: origin at the front's middle on the main wall line, u along the front (to the north),
## +v into the church (east-north-east). The front itself is built in the swapped frame
## (`_wiz_front`): u' = WIZ_FM - u, v' = -v (out to the street).
const WIZ := Vector2(-474.2, -782.6)
const WIZ_AXIS := Vector2(-0.527, -0.850)
const WIZ_FM := 12.1                    ## the front's half width; its middle in the front frame
const WIZ_WALL := Color("#ead9b8")      ## the cream plaster (photos: warm, a little peach)
const WIZ_TRIM := Color("#f3e9d4")      ## columns, cornices, surrounds
const WIZ_SHADE := Color("#d9c6a2")     ## niches and relief panels
const WIZ_BASE := Color("#bdb19a")      ## plinths
const WIZ_TILE := Color("#a3553f")      ## the red tile roofs
const WIZ_COPPER := Color("#5f9884")    ## the turret's green copper
const WIZ_DOOR := Color("#2c2d2f")      ## the iron-clad door


## The body frame: u along the front, +v into the church.
func _wiz_home() -> void:
	kit_front(WIZ, WIZ + WIZ_AXIS.normalized() * 10.0)


## The front frame: u' from the north end of the front to the south, v' out to the street.
func _wiz_front() -> void:
	var a := WIZ_AXIS.normalized()
	kit_front(WIZ + a * WIZ_FM, WIZ - a * WIZ_FM)


## A round-headed window or niche on the current face at u: a trim surround and a pane.
func _wiz_arch(u: float, y0: float, h: float, hw: float, glass := PAL_GLASS_DARK) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.22, y0 - 0.22, y0 + h - hw, WIZ_TRIM, 0.04, M_STONE)
	_arch_panel(at, _a, _b, hw, y0, y0 + h - hw, glass, 0.08, _lit(u, y0) if glass == PAL_GLASS_DARK else M_STONE)


## A stone urn on its pedestal at u, v (current frame), standing on y, `h` tall in all.
func _wiz_urn(u: float, v: float, y: float, h: float) -> void:
	var c := _w(u, v)
	_lbox(u, v, 0.32, 0.32, y, y + h * 0.22, WIZ_TRIM)
	_frustum(_circle(c, 0.16, 6), y + h * 0.22, _circle(c, 0.34, 6), y + h * 0.55, WIZ_SHADE.lightened(0.1))
	_frustum(_circle(c, 0.34, 6), y + h * 0.55, _circle(c, 0.12, 6), y + h * 0.75, WIZ_SHADE.lightened(0.1))
	_frustum(_circle(c, 0.16, 6), y + h * 0.75, _circle(c, 0.02, 6), y + h, WIZ_TRIM)


## A concave sweep on the front (current frame): the plan-flat profile `pts` ([u, y over the
## ground] from its foot on the low side round to its top against the wall), filled down to
## `foot`, from v0 (back) to v1 (its face): the face, the back and the curved top.
func _wiz_sweep(pts: Array, foot: float, v0: float, v1: float) -> void:
	var g := _g
	var poly := PackedVector2Array()
	poly.append(Vector2(float(pts[-1][0]), foot))
	for p: Array in pts:
		poly.append(Vector2(float(p[0]), g + float(p[1])))
	var idx := Geometry2D.triangulate_polygon(poly)
	var nf := Vector3(_b.x, 0.0, _b.y)
	var none := Vector2(-1, -1)
	for i in range(0, idx.size(), 3):
		var q: Array[Vector3] = []
		for k in 3:
			var s := poly[idx[i + k]]
			var w1 := _w(s.x, v1)
			q.append(Vector3(w1.x, s.y, w1.y))
		_tri(q[0], q[1], q[2], nf, WIZ_WALL, none, none, none, -1.0)
		var b: Array[Vector3] = []
		for k in 3:
			var s := poly[idx[i + k]]
			var w0 := _w(s.x, v0)
			b.append(Vector3(w0.x, s.y, w0.y))
		_tri(b[0], b[1], b[2], -nf, WIZ_WALL, none, none, none, -1.0)
	for k in pts.size() - 1:
		var p0 := Vector2(float(pts[k][0]), g + float(pts[k][1]))
		var p1 := Vector2(float(pts[k + 1][0]), g + float(pts[k + 1][1]))
		var a0 := _w(p0.x, v0)
		var a1 := _w(p0.x, v1)
		var b1 := _w(p1.x, v1)
		var b0 := _w(p1.x, v0)
		var along := Vector3(_a.x, 0.0, _a.y) * (p1.x - p0.x) + Vector3.UP * (p1.y - p0.y)
		var n := along.cross(nf).normalized()
		if n.y < 0.0:
			n = -n
		_quad(Vector3(a0.x, p0.y, a0.y), Vector3(a1.x, p0.y, a1.y), Vector3(b1.x, p1.y, b1.y), Vector3(b0.x, p1.y, b0.y), n, WIZ_TRIM)


## One side of the nave from v_from to v_to on the wall at u = `wu` (outside on the left of the
## run): arched clerestory windows between lesenes, the aisle's arched windows at the given v
## (on the aisle wall at u = `au`).
func _wiz_side(wu: float, au: float, v_from: float, v_to: float, aisle: Array) -> void:
	var g := _g
	var up := kit_front(_w(wu, v_from), _w(wu, v_to))
	kit_face(0.0)
	for k in 4:
		_wiz_arch(up * (0.125 + 0.25 * float(k)), g + 12.2, 4.4, 0.8)
	for k in 5:
		_kbox(up * 0.25 * float(k) - 0.3, up * 0.25 * float(k) + 0.3, -0.02, 0.12, g + 9.9, g + 18.3, WIZ_TRIM)
	_wiz_home()
	var ap := kit_front(_w(au, v_from), _w(au, v_to))
	kit_face(0.0)
	for v: float in aisle:
		var t := absf(v - v_from)
		_wiz_arch(t, g + 3.0, 4.2, 0.75)
	for k in 6:
		var pu := ap * float(k) / 5.0
		_kbox(pu - 0.3, pu + 0.3, -0.02, 0.14, g + 0.6, g + 9.2, WIZ_TRIM)
	_wiz_home()


func _build_wizytki(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var none := Color(0, 0, 0, 0)
	var trim := WIZ_TRIM
	_wiz_home()
	var fp := _w(0.0, -4.0)
	_g = map.terrain_height(fp.x, fp.y)
	var g := _g
	_mode = M_STONE
	# --- the masses: aisles and the north chapel to the aisles' cornice, the nave above them
	var low := _lpoly([[-11.2, 0.0], [11.0, 0.0], [11.0, 26.2], [12.6, 26.2], [12.6, 30.8], [10.4, 30.8],
			[10.4, 35.0], [-11.2, 35.0]])
	_prism(low, g - 0.6, g + 9.6, WIZ_WALL, WIZ_TILE, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(low, 0.25, Geometry2D.JOIN_MITER)), g - 0.6, g + 0.6, WIZ_BASE, none, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(low, 0.3, Geometry2D.JOIN_MITER)), g + 9.2, g + 9.8, trim, none, M_STONE, M_STONE)
	# the aisles' lean-to roofs, from their cornice up against the nave
	for s: float in [-1.0, 1.0]:
		var e0 := _w(s * 11.2, 0.2)
		var e1 := _w(s * 11.2, 35.0)
		var r1 := _w(s * 7.2, 35.0)
		var r0 := _w(s * 7.2, 0.2)
		var lp: Array[Vector3] = [Vector3(e0.x, g + 9.8, e0.y), Vector3(e1.x, g + 9.8, e1.y),
				Vector3(r1.x, g + 11.4, r1.y), Vector3(r0.x, g + 11.4, r0.y)]
		var ln := (lp[1] - lp[0]).cross(lp[3] - lp[0]).normalized()
		if ln.y < 0.0:
			ln = -ln
		_quad(lp[0], lp[1], lp[2], lp[3], ln, WIZ_TILE)
	# the nave: walls to the eaves, a cornice, the steep tile roof, the hip at the east end
	_lbox(0.0, 17.6, 7.2, 17.6, g + 9.0, g + 18.6, WIZ_WALL, M_STONE, none)
	_prism(_rect(0.0, 17.6, 7.5, 17.9), g + 18.3, g + 18.8, trim, none, M_STONE, M_STONE)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(-0.3, 28.0, 0.0, 7.6, g + 18.8, 6.4, WIZ_WALL, WIZ_TILE, false)
	_a = ka
	_b = kb
	var ap := _w(0.0, 28.0)
	var apex := Vector3(ap.x, g + 25.2, ap.y)
	var eaves: Array[Vector3] = []
	for q: Vector2 in [Vector2(-7.6, 28.0), Vector2(-7.6, 35.5), Vector2(7.6, 35.5), Vector2(7.6, 28.0)]:
		var e := _w(q.x, q.y)
		eaves.append(Vector3(e.x, g + 18.8, e.y))
	for k in 3:
		var n := (eaves[k + 1] - eaves[k]).cross(apex - eaves[k]).normalized()
		if n.y < 0.0:
			n = -n
		_tri(eaves[k], eaves[k + 1], apex, n, WIZ_TILE, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# the chancel: lower walls, its own tile roof along the church's axis
	var chancel := _lpoly([[-10.6, 35.0], [10.4, 35.0], [10.3, 48.4], [-4.0, 48.4], [-3.9, 42.5], [-10.6, 42.5]])
	_prism(chancel, g - 0.6, g + 9.4, WIZ_WALL, WIZ_TILE, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(chancel, 0.25, Geometry2D.JOIN_MITER)), g + 9.0, g + 9.6, trim, none, M_STONE, M_STONE)
	_a = kb
	_b = ka
	_gable(35.0, 48.6, 3.15, 7.45, g + 9.6, 4.4, WIZ_WALL, WIZ_TILE, true)
	_a = ka
	_b = kb
	# the south wing by the university's house, under a tile hip
	_prism(_rect(-15.55, 28.95, 4.35, 6.95), g - 0.6, g + 10.8, WIZ_WALL, WIZ_TILE, M_STONE, M_STONE)
	_prism(_rect(-15.55, 28.95, 4.6, 7.2), g + 10.4, g + 11.0, trim, none, M_STONE, M_STONE)
	_hip(-15.55, 28.95, 4.6, 7.2, g + 11.0, 4.2, WIZ_TILE)
	# --- the sides: clerestory and aisle windows; north from the front back, south likewise
	_wiz_side(7.2, 11.0, 34.0, 1.0, [33.0, 21.0, 14.0, 6.0])
	_wiz_side(-7.2, -11.2, 1.0, 34.0, [6.0, 13.0, 19.5])
	# --- the turret over the nave's east end: an open arched stage, the bell cap, an onion
	var tv := 29.5
	var tc := _w(0.0, tv)
	_prism(_jac_ring(0.0, tv, 1.45, 8), g + 22.0, g + 25.0, WIZ_COPPER, none, M_STONE, M_STONE)
	_prism(_jac_ring(0.0, tv, 0.95, 8), g + 25.0, g + 27.6, PAL_IRON, none, M_STONE, M_STONE)
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_lbox(cu * 1.0, tv + cv * 1.0, 0.24, 0.24, g + 25.0, g + 27.6, WIZ_COPPER, M_STONE, none)
	var cap: Array = [[1.55, 27.6], [1.9, 28.0], [1.6, 28.7], [0.95, 29.3], [0.7, 29.6], [1.05, 30.2],
			[1.05, 30.6], [0.6, 31.3], [0.3, 31.6]]
	for k in cap.size() - 1:
		var p: Array = cap[k]
		var q: Array = cap[k + 1]
		_frustum(_jac_ring(0.0, tv, float(p[0]), 8), g + float(p[1]), _jac_ring(0.0, tv, float(q[0]), 8), g + float(q[1]), WIZ_COPPER)
	_prism(_jac_ring(0.0, tv, 0.3, 6), g + 31.6, g + 32.3, WIZ_COPPER, none, M_STONE, M_STONE)
	_frustum(_jac_ring(0.0, tv, 0.36, 6), g + 32.3, _jac_ring(0.0, tv, 0.08, 6), g + 32.8, WIZ_COPPER)
	_frustum(_circle(tc, 0.2, 6), g + 32.8, _circle(tc, 0.22, 6), g + 33.05, PAL_GOLD)
	_frustum(_circle(tc, 0.22, 6), g + 33.05, _circle(tc, 0.05, 6), g + 33.3, PAL_GOLD)
	_kap_cross(0.0, tv, g + 33.3, 1.4)
	# --- the front (its own frame): two storeys of paired columns, sweeps, the crown
	_wiz_front()
	var m := WIZ_FM
	# the lower wall over the whole width; the forward block of the middle four pairs to the top
	_kbox(m - 12.1, m + 12.1, -0.2, 1.0, g - 0.6, g + 8.9, WIZ_WALL)
	_kbox(m - 8.2, m + 8.2, -0.2, 2.0, g - 0.6, g + 18.0, WIZ_WALL)
	kit_face(1.0)
	kit_ledge(m - 12.3, m + 12.3, g - 0.6, 1.7, WIZ_BASE, 0.3)
	kit_face(2.0)
	kit_ledge(m - 8.4, m + 8.4, g - 0.6, 1.7, WIZ_BASE, 0.3)
	# the lower order: pairs of Corinthian columns, the outer ones on the back plane
	for x: float in [2.2, 3.2, 6.4, 7.4]:
		for s: float in [-1.0, 1.0]:
			kit_column(m + s * x, 2.45, g + 1.1, g + 7.4, trim, 0.4, Order.CORINTHIAN)
	for x: float in [10.6, 11.6]:
		for s: float in [-1.0, 1.0]:
			kit_column(m + s * x, 1.45, g + 1.1, g + 7.4, trim, 0.4, Order.CORINTHIAN)
	# its entablature and cornice, breaking forward over the middle block
	_kbox(m - 12.3, m + 12.3, 0.9, 2.0, g + 7.4, g + 8.9, trim)
	_kbox(m - 8.3, m + 8.3, 1.9, 2.95, g + 7.4, g + 8.9, trim)
	_kbox(m - 12.6, m + 12.6, 0.7, 2.35, g + 8.9, g + 9.4, trim)
	_kbox(m - 8.6, m + 8.6, 1.9, 3.25, g + 8.9, g + 9.4, trim)
	# blind arched niches with medallions over them between the pairs
	for s: float in [-1.0, 1.0]:
		kit_face(2.0)
		_wiz_arch(m + s * 4.8, g + 2.4, 3.3, 0.72, WIZ_SHADE)
		var md := _w(m + s * 4.8, 2.08)
		_disc(Vector3(md.x, g + 6.55, md.y), Vector3(_b.x, 0.0, _b.y), 0.42, 8, WIZ_SHADE)
		kit_face(1.0)
		_wiz_arch(m + s * 9.0, g + 2.4, 3.3, 0.72, WIZ_SHADE)
		var mo := _w(m + s * 9.0, 1.08)
		_disc(Vector3(mo.x, g + 6.55, mo.y), Vector3(_b.x, 0.0, _b.y), 0.42, 8, WIZ_SHADE)
	# the middle bay: the iron door in its frame, the balcony, an arched window, a cartouche
	kit_face(2.0)
	_kbox(m - 1.3, m + 1.3, 1.96, 2.12, g + 1.1, g + 3.4, trim)
	kit_face(2.12)
	kit_door(m, g + 0.0, 3.0, 0.95, trim, WIZ_DOOR)
	kit_face(2.0)
	kit_balcony(m, g + 4.3, 1.05, Balcony.STONE, trim, trim, 0.45)
	kit_window(m, g + 4.4, 1.6, Win.ARCHED, trim, PAL_GLASS_DARK, 0.72)
	_kbox(m - 0.8, m + 0.8, 1.96, 2.1, g + 6.5, g + 7.3, WIZ_SHADE)
	# pedestals over the lower cornice: the upper columns' and the outer urns'
	for x: float in [2.7, 6.9]:
		for s: float in [-1.0, 1.0]:
			_kbox(m + s * x - 1.05, m + s * x + 1.05, 1.9, 2.95, g + 9.4, g + 10.3, trim)
	for s: float in [-1.0, 1.0]:
		_kbox(m + s * 11.1 - 0.95, m + s * 11.1 + 0.95, 0.8, 2.0, g + 9.4, g + 10.2, trim)
		for x: float in [10.6, 11.6]:
			_wiz_urn(m + s * x, 1.4, g + 10.2, 1.7)
	# the lower sweeps: from the upper storey's side down to the urns' pedestals
	for s: float in [-1.0, 1.0]:
		var sw: Array = []
		for p: Array in [[10.2, 9.4], [10.2, 9.9], [9.4, 10.4], [8.8, 11.2], [8.45, 12.2], [8.2, 13.4]]:
			sw.append([m + s * float(p[0]), float(p[1])])
		_wiz_sweep(sw, g + 9.4, 0.4, 1.4)
	# the upper order: four pairs, statues of bishops in niches, the great window
	kit_face(2.0)
	for x: float in [2.2, 3.2, 6.4, 7.4]:
		for s: float in [-1.0, 1.0]:
			kit_column(m + s * x, 2.4, g + 10.3, g + 16.8, trim, 0.36, Order.CORINTHIAN)
	for s: float in [-1.0, 1.0]:
		_wiz_arch(m + s * 4.8, g + 11.4, 3.0, 0.6, WIZ_SHADE)
		_jac_statue(m + s * 4.8, 2.25, g + 11.5, 2.3)
		var rp := _w(m + s * 4.8, 2.08)
		_disc(Vector3(rp.x, g + 15.6, rp.y), Vector3(_b.x, 0.0, _b.y), 0.4, 8, WIZ_SHADE)
	_wiz_arch(m, g + 10.9, 3.4, 0.82)
	_kbox(m - 1.25, m + 1.25, 1.96, 2.25, g + 14.75, g + 15.0, trim)
	_kbox(m - 0.75, m + 0.75, 1.96, 2.12, g + 15.2, g + 16.3, WIZ_SHADE)
	# its entablature, the cornice and a broken pediment over the middle
	_kbox(m - 8.4, m + 8.4, 1.9, 2.85, g + 16.8, g + 18.0, trim)
	_kbox(m - 8.7, m + 8.7, 1.7, 3.15, g + 18.0, g + 18.5, trim)
	kit_face(2.4)
	kit_pediment(m, 2.6, g + 18.5, 1.1, trim, trim.darkened(0.08), 0.5, WIZ_SHADE)
	# the upper storey's urns and the four saints on the cornice
	for s: float in [-1.0, 1.0]:
		for x: float in [6.4, 7.4]:
			_wiz_urn(m + s * x, 2.5, g + 18.5, 1.9)
		for x: float in [2.0, 3.4]:
			_jac_statue(m + s * x, 2.75, g + 18.5, 2.3)
	# --- the crown: sweeps up from the cornice, a wall with pilasters and a niche for the group,
	# the scrolled corners with angels, the ball and the cross
	_kbox(m - 4.3, m + 4.3, 0.6, 2.0, g + 18.0, g + 23.0, WIZ_WALL)
	for s: float in [-1.0, 1.0]:
		var cs: Array = []
		for p: Array in [[6.3, 18.5], [6.3, 18.9], [5.5, 19.3], [4.9, 19.9], [4.55, 20.8], [4.3, 22.0]]:
			cs.append([m + s * float(p[0]), float(p[1])])
		_wiz_sweep(cs, g + 18.5, 0.8, 1.8)
	kit_face(2.0)
	for x: float in [-3.7, -1.5, 1.5, 3.7]:
		kit_pilaster(m + x, g + 18.5, g + 23.0, trim, 0.55, 0.14)
	_wiz_arch(m, g + 19.6, 3.0, 0.68, WIZ_SHADE)
	for x: float in [-0.3, 0.3]:
		_jac_statue(m + x, 2.2, g + 19.65, 2.0)
	_kbox(m - 4.5, m + 4.5, 1.7, 2.4, g + 23.0, g + 23.4, trim)
	for s: float in [-1.0, 1.0]:
		_kbox(m + s * 3.5 - 1.0, m + s * 3.5 + 1.0, 1.4, 2.5, g + 23.4, g + 23.9, trim)
		_jac_statue(m + s * 3.5, 1.95, g + 23.9, 1.6)
	_kbox(m - 0.55, m + 0.55, 1.5, 2.3, g + 23.4, g + 25.0, trim)
	_kbox(m - 0.75, m + 0.75, 1.4, 2.4, g + 25.0, g + 25.3, trim)
	var bc := _w(m, 1.9)
	_frustum(_circle(bc, 0.2, 6), g + 25.3, _circle(bc, 0.3, 6), g + 25.55, PAL_GOLD)
	_frustum(_circle(bc, 0.3, 6), g + 25.55, _circle(bc, 0.08, 6), g + 25.85, PAL_GOLD)
	_kap_cross(m, 1.9, g + 25.85, 1.7)
	_wiz_home()
	# the car meets the walls and the front's columns
	_collide(outline)


## St Anne's church (Kościół św. Anny; Aigner's classical front, 1786-1788) at the start of
## Krakowskie Przedmieście: the nave stays LoD2's (a kept skin); the model adds the front, a
## stone plinth, flanking wings with window storeys, a central block with a portico of four
## Corinthian-style columns under a pediment and a gilt cross, and trims Kubicki's free-standing
## bell tower (the separate square building to the north: cornices, corner pilasters,
## louvres, a cornice over the octagon and a gilt cross). Spec docs/landmarks/specs/anna.md.
## Frame: origin at the front's north end on the outline, u south along the front (25.5 m),
## +v out of it to the street (west).
const ANNA := Vector2(-689.3, -1358.2)
const ANNA_AXIS := Vector2(0.245, 0.969)
const ANNA_MID := 12.75
const ANNA_WALL := Color("#e9dfc6")
const ANNA_TRIM := Color("#f4eedd")
const ANNA_BASE := Color("#b9ae96")
const ANNA_ROOF := Color("#6f5a4e")
const ANNA_GOLD := Color("#c9a24a")
const ANNA_DOOR := Color("#3a3d40")
const ANNA_CAP := Color("#e3d09a")        # the Corinthian capitals (photo 1: gilded cream)
const ANNA_NICHE := Color("#dccfae")      # the niches and the arched relief
const ANNA_STATUE := Color("#f3f0e8")     # the white statues
const ANNA_DOOR_WOOD := Color("#7c4a2a")  # the great door (photo 1: reddish oak)
const ANNA_COPPER := Color("#6e9c8b")     # the tower's copper (photo 2)


func _build_anna(_site: Dictionary) -> void:
	_o = ANNA
	_a = ANNA_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (-0.969, 0.245): out of the front, to the street (west)
	var m := ANNA_MID
	_g = map.terrain_height(_w(m, 2.0).x, _w(m, 2.0).y)
	var g := _g
	_mode = M_STONE
	# From the photos (refs/st_anne 1-2): one cream front plane 25.5 m wide on a plinth, framed by
	# corner pilasters at u = m +- 11.8, a giant Corinthian order of four columns (m +- 3.9 and
	# +- 7.9, 1.6 m thick, shafts 9 m) under a heavy entablature and a wide pediment with a round
	# emblem; between the columns pedimented niches with white statues (m +- 5.9 and +- 9.7), small
	# side doors at m +- 5.9, in the middle bay a plain wall with a round-arched relief over the
	# great door under its own little two-column porch. Behind the pediment a stepped attic.
	_lbox(m, 0.3, m + 0.2, 0.4, g - 0.6, g + 1.3, ANNA_BASE, M_STONE, ANNA_BASE.lightened(0.05))
	_lbox(m, 0.0, 12.9, 0.4, g + 1.3, g + 6.2, ANNA_WALL, M_STONE, ANNA_WALL)
	_lbox(m, 0.0, 12.9, 0.4, g + 6.2, g + 13.4, ANNA_WALL, M_MONUMENT, ANNA_WALL)
	_lbox(m, 0.2, 13.1, 0.55, g + 13.4, g + 14.4, ANNA_TRIM, M_STONE, ANNA_TRIM)
	for su: float in [-1.0, 1.0]:  # the corner pilasters
		_lbox(m + su * 11.8, 0.55, 0.9, 0.35, g + 1.3, g + 12.2, ANNA_TRIM, M_STONE, ANNA_TRIM)
		_lbox(m + su * 11.8, 0.55, 1.15, 0.45, g + 12.2, g + 13.4, ANNA_CAP, M_STONE, ANNA_CAP)
	# the niches: a recess, a white statue, a small pediment over
	for nu: float in [-9.7, -5.9, 5.9, 9.7]:
		_lbox(m + nu, 0.43, 0.8, 0.05, g + 4.0, g + 8.6, ANNA_NICHE, M_STONE, ANNA_NICHE)
		_lbox(m + nu, 0.6, 0.38, 0.22, g + 4.2, g + 6.5, ANNA_STATUE, M_STONE, ANNA_STATUE)
		_lbox(m + nu, 0.6, 0.2, 0.2, g + 6.5, g + 7.5, ANNA_STATUE, M_STONE, ANNA_STATUE)
		_lbox(m + nu, 0.5, 1.2, 0.2, g + 8.6, g + 9.0, ANNA_TRIM, M_STONE, ANNA_TRIM)
		_lbox(m + nu, 0.5, 0.8, 0.2, g + 9.0, g + 9.45, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_mode = M_GLASS
	for du: float in [-5.9, 5.9]:
		_wall(_w(m + du - 0.7, 0.42), _w(m + du + 0.7, 0.42), g + 1.3, g + 4.0, _b, ANNA_DOOR)
	_mode = M_STONE
	# the middle bay: the arched relief, the inscription slab, the great door in its porch
	_arch_panel(_w(m, 0.42), _a, _b, 3.5, g + 8.4, g + 8.9, ANNA_NICHE, 0.03, M_STONE)
	_lbox(m, 0.45, 2.2, 0.05, g + 5.2, g + 7.2, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_mode = M_GLASS
	_wall(_w(m - 1.4, 0.43), _w(m + 1.4, 0.43), g + 1.3, g + 5.0, _b, ANNA_DOOR_WOOD)
	_mode = M_STONE
	for pu: float in [-1.8, 1.8]:
		_column(m + pu, 1.5, 0.3, g + 1.3, g + 5.4, ANNA_TRIM)
	_lbox(m, 1.2, 2.5, 1.3, g + 5.4, g + 6.0, ANNA_TRIM, M_STONE, ANNA_TRIM)
	# the giant order: a stylobate, then the four columns with capitals and the entablature
	_lbox(m, 1.6, 9.3, 1.6, g - 0.6, g + 1.3, ANNA_BASE, M_STONE, ANNA_BASE.lightened(0.05))
	for k in 2:
		_lbox(m, 3.4 + 0.5 * k, 3.0 - 0.3 * k, 0.4 + 0.5 * k, g - 0.6, g + 0.95 - 0.5 * k, ANNA_BASE, M_STONE,
				ANNA_BASE.lightened(0.04))
	for u: float in [-7.9, -3.9, 3.9, 7.9]:
		_column(m + u, 1.6, 0.8, g + 1.3, g + 10.8, ANNA_TRIM)
		_lbox(m + u, 1.6, 1.1, 1.1, g + 10.8, g + 12.3, ANNA_CAP, M_STONE, ANNA_CAP)
	_lbox(m, 1.6, 9.6, 1.5, g + 12.3, g + 13.7, ANNA_WALL, M_STONE, ANNA_TRIM)
	_lbox(m, 1.6, 9.9, 1.7, g + 13.7, g + 14.4, ANNA_TRIM, M_STONE, ANNA_TRIM)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(3.3, 0.2, m, 9.8, g + 14.4, 3.7, ANNA_WALL, ANNA_ROOF)
	_a = ka
	_b = kb
	var oc := _w(m, 3.35)
	_disc(Vector3(oc.x, g + 16.2, oc.y), Vector3(_b.x, 0.0, _b.y), 0.9, 8, ANNA_DOOR)
	# the stepped attic behind the pediment (photo 2), then the gilt cross
	_lbox(m, -1.4, 7.0, 1.5, g + 14.4, g + 18.2, ANNA_WALL, M_STONE, ANNA_WALL)
	_lbox(m, -1.4, 7.3, 1.7, g + 18.2, g + 18.8, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_lbox(m, -1.6, 3.4, 1.2, g + 18.8, g + 20.8, ANNA_WALL, M_STONE, ANNA_WALL)
	_lbox(m, -1.6, 3.7, 1.4, g + 20.8, g + 21.4, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_lbox(m, -1.6, 0.15, 0.15, g + 21.4, g + 24.1, ANNA_GOLD, M_STONE, ANNA_GOLD)
	_lbox(m, -1.6, 0.7, 0.15, g + 22.6, g + 23.0, ANNA_GOLD, M_STONE, ANNA_GOLD)
	# the car meets the steps and the stylobate
	_collide(_rect(m, 3.9, 3.0, 0.4))
	_collide(_rect(m, 1.6, 9.3, 1.6))
	_anna_tower()


## The bell tower's trim (the square building north of the church, about 10.4 m a side, 25 m
## high, with a copper octagon to 33.8 m): a stone plinth, a string course, corner pilasters,
## dark louvres, a heavy cornice, then a ring and a gilt cross over the octagon.
func _anna_tower() -> void:
	_o = Vector2(-689.275, -1379.575)
	_a = Vector2(0.985, -0.174).normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(_o.x, _o.y)
	var g := _g
	_mode = M_STONE
	var h := 5.35  # half the square's side, a little out of the wall
	_lbox(0.0, 0.0, h + 0.3, h + 0.3, g - 0.6, g + 1.4, ANNA_BASE, M_STONE, ANNA_BASE.lightened(0.05))
	_lbox(0.0, 0.0, h + 0.15, h + 0.15, g + 11.6, g + 12.2, ANNA_TRIM, M_STONE, ANNA_TRIM)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(su * (h - 0.2), sv * (h - 0.2), 0.55, 0.55, g + 1.4, g + 24.0, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_mode = M_GLASS
	for side: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var fa := _w(side.x * (h + 0.1) - side.y * 1.0, side.y * (h + 0.1) + side.x * 1.0)
		var fb := _w(side.x * (h + 0.1) + side.y * 1.0, side.y * (h + 0.1) - side.x * 1.0)
		_wall(fa, fb, g + 15.0, g + 21.0, Vector2(side.x * _a.x + side.y * _b.x, side.x * _a.y + side.y * _b.y), ANNA_DOOR)
	_mode = M_STONE
	_lbox(0.0, 0.0, h + 0.5, h + 0.5, g + 24.0, g + 25.1, ANNA_TRIM, M_STONE, ANNA_TRIM)
	_lbox(0.0, 0.0, h + 0.3, h + 0.3, g + 23.2, g + 24.0, ANNA_WALL, M_STONE, ANNA_WALL)
	# The observation terrace (F, 2026-11-01): a stone balustrade round the cornice's edge, a post
	# at each corner, 1.1 m high over the walking level at g + 25.1 (the visitors stand inside it,
	# crowds.gd DECKS `anna_deck`, 5 m from the centre).
	for su: float in [-1.0, 1.0]:
		_lbox(su * (h + 0.38), 0.0, 0.12, h + 0.5, g + 25.1, g + 26.2, ANNA_TRIM, M_STONE, ANNA_TRIM)
		_lbox(0.0, su * (h + 0.38), h + 0.5, 0.12, g + 25.1, g + 26.2, ANNA_TRIM, M_STONE, ANNA_TRIM)
		for sv: float in [-1.0, 1.0]:
			_lbox(su * (h + 0.38), sv * (h + 0.38), 0.2, 0.2, g + 25.1, g + 26.7, ANNA_WALL, M_STONE, ANNA_WALL)
	var c := _w(0.0, 0.0)
	# photo 2: an octagonal belfry in cream with arched louvres under a copper dome and lantern
	_prism(_circle(c, 2.9, 8), g + 25.1, g + 30.0, ANNA_WALL, ANNA_WALL, M_STONE, M_STONE)
	for k in 8:
		var ang := TAU * float(k) / 8.0 + TAU / 16.0
		var out := Vector2(cos(ang), sin(ang))
		_arch_panel(c + out * 2.68, Vector2(-out.y, out.x), out, 0.55, g + 26.5, g + 28.3, ANNA_DOOR, 0.03, M_GLASS)
	_frustum(_circle(c, 3.5, 8), g + 30.0, _circle(c, 3.2, 8), g + 30.6, ANNA_TRIM, ANNA_TRIM)
	_frustum(_circle(c, 3.2, 8), g + 30.6, _circle(c, 0.5, 8), g + 34.4, ANNA_COPPER, ANNA_COPPER)
	_prism(_circle(c, 0.5, 8), g + 34.4, g + 35.6, ANNA_COPPER, ANNA_COPPER, M_STONE, M_STONE)
	_lbox(0.0, 0.0, 0.14, 0.14, g + 35.6, g + 38.0, ANNA_GOLD, M_STONE, ANNA_GOLD)
	_lbox(0.0, 0.0, 0.55, 0.14, g + 36.8, g + 37.2, ANNA_GOLD, M_STONE, ANNA_GOLD)


## St John's Archcathedral (Archikatedra św. Jana Chrzciciela, Old Town): the nave stays the
## kept LoD2 mass in brick; the model adds the front, a stepped brick gable over the nave end
## with a tall pointed window, a pointed portal porch and pinnacles on the buttresses.
## Spec docs/landmarks/specs/archikatedra.md.
## Frame: origin at the front's west corner (outline point (-741.3, -1633.0)), u along the 27.6 m
## front, +v out of it (south-west). Heights are estimates (no photo here).
const ARCH := Vector2(-741.3, -1633.0)
const ARCH_AXIS := Vector2(0.685, 0.729)
const ARCH_MID := 13.8
const ARCH_BRICK := Color("#9a4b38")
const ARCH_TRIM := Color("#c8b393")
const ARCH_ROOF := Color("#5e3a30")
const ARCH_GLASS := Color("#262a2e")
const ARCH_GOLD := Color("#c9a24a")
const ARCH_COPPER := Color("#6f9a8a")   # photo 3: the ridge lantern's weathered copper
const CATH_SPLAY := Color("#e8e1d2")    # the window splays (photo 1: white plaster)
const CATH_PANEL := Color("#e3dccf")    # the gable's cream panels
## The nave roof (F, 2026-11-09, photos E06-E08): the LoD2 mass is a flat slab to about 18.5 m over
## the ground; a steep copper gable stands on it, eaves 0.7 m under the slab's top so the slab is
## hidden inside, ridge along the nave's axis (u 14.2, half width 14.2 m, from the front gable
## back to the tower at v -46).
## The roof is sheet copper gone green, not tile (2026-11-14: photo 3 shows the seamed copper sheets
## round the ridge turret, the orthophoto the whole roof grey-green; it was red-brown tile #85402f).
const CATH_COPPER_ROOF := Color("#829a8f")
const CATH_EAVE := 17.8
const CATH_RISE := 11.2
const CATH_NAVE_U := 14.2
const CATH_NAVE_BACK := -46.0


func _build_archikatedra(_site: Dictionary) -> void:
	_o = ARCH
	_a = ARCH_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (-0.729, 0.685): out of the front, to the street
	var m := ARCH_MID
	_g = map.terrain_height(_w(m, 2.0).x, _w(m, 2.0).y)
	var g := _g
	# the portal porch: a brick block with a stone plinth, a dark pointed opening, a gable
	_lbox(m, 1.1, 4.6, 1.6, g - 0.6, g + 1.0, ARCH_TRIM, M_STONE, ARCH_TRIM.lightened(0.04))
	_lbox(m, 1.0, 4.4, 1.4, g + 1.0, g + 8.5, ARCH_BRICK, M_GOTHIC, ARCH_BRICK)
	_mode = M_GLASS
	_wall(_w(m - 1.5, 2.43), _w(m + 1.5, 2.43), g + 1.2, g + 5.4, _b, ARCH_GLASS)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_mode = M_STONE
	_gable(2.45, 2.3, m, 1.5, g + 5.4, 2.6, ARCH_GLASS, ARCH_GLASS, false)
	_gable(2.4, -0.2, m, 4.4, g + 8.5, 3.0, ARCH_BRICK, ARCH_ROOF)
	_a = ka
	_b = kb
	# From the photos (refs/archikatedra 1-2): the front is a brick wall 16 m high with three tall
	# pointed windows in white splays (the middle one narrower and taller), two deep buttresses
	# beside the portal, and a stone frieze of emblems under a stepped gable of six levels: brick
	# shafts rising in steps of 3.3 m, 2.2 m apart, cream panels each with a blind lancet between
	# them, a cross on the top pair.
	var body_top := 16.0
	_lbox(m, 0.55, 13.3, 0.8, g - 0.55, g + body_top, ARCH_BRICK, M_GOTHIC, ARCH_BRICK)
	_lbox(m, 0.55, 14.2, 1.05, g + body_top, g + body_top + 1.2, ARCH_TRIM, M_STONE, ARCH_TRIM)
	for bu: float in [m - 5.5, m + 5.5]:
		_lbox(bu, 1.1, 1.3, 0.9, g - 0.45, g + 14.2, ARCH_BRICK, M_GOTHIC, ARCH_TRIM)
		_lbox(bu, 1.1, 1.45, 1.05, g + 14.2, g + 14.7, ARCH_TRIM, M_STONE, ARCH_TRIM)
	# the three pointed windows: dark glass in a pale splay, a stone sill
	_mode = M_GLASS
	for wu: float in [m - 9.0, m, m + 9.0]:
		var ww := 1.15 if absf(wu - m) < 1.0 else 1.0
		var top := 14.2 if absf(wu - m) < 1.0 else 13.4
		_arch_panel(_w(wu, 1.34), _a, _b, ww, g + 3.6, g + top - ww - 0.2, ARCH_GLASS, 0.08, M_GLASS)
		_arch_panel(_w(wu, 1.34), _a, _b, ww + 0.45, g + 3.3, g + top - ww - 0.2, CATH_SPLAY, 0.05, M_STONE)
	_mode = M_STONE
	# the stepped gable: six levels, the outer one the full width
	var base := g + body_top + 1.2
	var tops := [4.4, 7.7, 11.0, 14.3, 17.6, 20.9]
	for i in 6:
		var hw := 13.0 - 2.2 * float(i)
		var ty: float = base + float(tops[i])
		_lbox(m, 0.4, hw, 0.8, base - 0.1, ty, CATH_PANEL, M_STONE, ARCH_BRICK)
		for sgn: float in [-1.0, 1.0]:
			_lbox(m + sgn * hw, 0.62, 0.45, 0.62, base - 0.1, ty, ARCH_BRICK, M_GOTHIC, ARCH_BRICK)
			_pinnacle(m + sgn * hw, 0.62, 0.9, ty, 1.5, ARCH_BRICK)
			# the blind lancet in the panel outside this shaft's neighbour
			if i < 5:
				var lu := m + sgn * (hw - 1.1)
				_arch_panel(_w(lu, 1.2), _a, _b, 0.5, base + 1.2, base + float(tops[i]) - 1.9, ARCH_BRICK.lightened(0.25), 0.03, M_STONE)
	_arch_panel(_w(m, 1.2), _a, _b, 0.6, base + 6.0, base + float(tops[5]) - 2.4, ARCH_BRICK.lightened(0.25), 0.03, M_STONE)
	# the cross on the top step
	var cy := base + float(tops[5]) + 0.3
	_lbox(m, 0.62, 0.14, 0.14, g + body_top + 1.2 + 20.9, g + body_top + 1.2 + 24.4, ARCH_GOLD, M_STONE, ARCH_GOLD)
	_lbox(m, 0.62, 0.7, 0.14, cy + 2.0, cy + 2.4, ARCH_GOLD, M_STONE, ARCH_GOLD)
	# the lantern on the roof ridge behind (photo 3): an octagonal copper bell turret with a
	# pointed cap, a ball and a cross
	# The nave roof: a steep copper gable over the LoD2 slab, the ridge along the nave (see CATH_*)
	var eave := g + CATH_EAVE
	var ridge := eave + CATH_RISE
	var fa := _a
	var fb := _b
	_a = fb
	_b = fa
	_gable(-1.0, CATH_NAVE_BACK, CATH_NAVE_U, 14.2, eave, CATH_RISE, ARCH_BRICK, CATH_COPPER_ROOF, true)
	_a = fa
	_b = fb
	# a stone ridge cap and the ridge's end blocks
	_lbox(CATH_NAVE_U, (-1.0 + CATH_NAVE_BACK) * 0.5, 0.22, absf(CATH_NAVE_BACK + 1.0) * 0.5, ridge - 0.05, ridge + 0.25, ARCH_TRIM, M_STONE, ARCH_TRIM)
	var tc := _w(CATH_NAVE_U, -20.0)
	_prism(_circle(tc, 0.9, 8), g - 0.6, ridge + 0.2, ARCH_BRICK, ARCH_BRICK, M_STONE, M_STONE)  # the shaft inside the nave, so the turret stands on something
	_prism(_circle(tc, 0.95, 8), ridge + 0.2, ridge + 4.2, ARCH_COPPER, ARCH_COPPER, M_STONE, M_STONE)
	_frustum(_circle(tc, 1.25, 8), ridge + 4.2, _circle(tc, 0.12, 8), ridge + 7.2, ARCH_COPPER, ARCH_COPPER)
	_lbox_at(tc, 0.07, ridge + 7.2, ridge + 9.0, ARCH_GOLD)
	_collide(_rect(m, 1.0, 4.4, 1.4))


# --- Krakowskie Przedmieście from photos (2026-11-02; first pass K1-K5 2026-11-01) -------------

const KARM := Vector2(-598.9, -1042.4)  # the front's north end, 2.2 m out from the outline's line onto its centre risalit
const KARM_AXIS := Vector2(0.507, 0.862)
const KARM_MID := 13.0

const KARM_SAND := Color("#c9b78c")
const KARM_OCHRE := Color("#b39a62")
const KARM_TRIM := Color("#d8c9a2")
const KARM_GLOBE := Color("#5e9e8a")
const KARM_ROOF := Color("#7d8a7c")


## The Carmelite church's front (Kościół Wniebowzięcia NMP i św. Józefa; Fontana and Szreger,
## 1761-1781), photos 24-25: the nave stays LoD2's (a kept skin); the model is the two-storey
## sandstone front. Below: two pairs of engaged Tuscan columns round the big door, pilasters at
## the ends, two round-headed side doors. Above, set back behind a balustraded balcony: a temple
## front of four free-standing Corinthian columns with a big arched window, two statues in
## niches, a straight entablature and an attic with sculpture groups, crowned by a green copper
## globe with a gilt finial; a lantern turret with round openings and a green cap either side.
## Frame: origin at the front's north end, u south along the front (26 m), +v out of it (west).
func _build_karmelici(_site: Dictionary) -> void:
	_o = KARM
	_a = KARM_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var m := KARM_MID
	_g = map.terrain_height(_w(m, 1.5).x, _w(m, 1.5).y)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_lbox(m, -0.8, 13.3, 1.5, g - 0.6, g + 1.0, KARM_OCHRE, M_STONE, KARM_OCHRE.lightened(0.05))
	_lbox(m, -1.1, 13.0, 1.4, g + 1.0, g + 9.2, KARM_SAND, M_STONE, KARM_SAND)
	for sd: float in [-1.0, 1.0]:
		for u: float in [2.4, 3.9]:  # the paired engaged columns round the door
			_column(m + sd * u, 0.45, 0.42, g + 1.0, g + 9.2, KARM_TRIM)
		for u: float in [8.4, 12.4]:  # pilasters
			_lbox(m + sd * u, 0.4, 0.45, 0.3, g + 1.0, g + 9.2, KARM_TRIM, M_STONE, KARM_TRIM)
	_lbox(m, -0.6, 13.3, 1.9, g + 9.2, g + 10.3, KARM_TRIM, M_STONE, KARM_TRIM)  # the entablature
	# the doors: the big one in the middle, a round-headed one each side
	_kp_arch_open(m, 0.35, g + 1.0, g + 5.4, 1.5, KP_WOOD)
	for sd: float in [-1.0, 1.0]:
		_kp_arch_open(m + sd * 6.2, 0.35, g + 1.0, g + 3.9, 0.85, KP_WOOD)
		_kp_arch_open(m + sd * 10.4, 0.35, g + 4.6, g + 7.0, 0.7, KP_DARK)
	for k in 3:  # three steps down to the street
		_lbox(m, 1.0 + 0.5 * k, 4.4 - 0.5 * k, 0.5 + 0.5 * (2 - k), g - 0.6, g + 0.15 + 0.35 * (2 - k), KARM_OCHRE,
				M_STONE, KARM_OCHRE.lightened(0.04))
	# the upper storey: the wall set back, the balcony and its balustrade before it
	_lbox(m, -1.5, 8.2, 1.5, g + 10.3, g + 18.0, KARM_SAND, M_STONE, KARM_SAND)
	_kp_balustrade(-7.6 + m, 1.1, 7.6 + m, 1.1, g + 10.3, 1.0, KARM_TRIM, 2.5)
	for u: float in [-5.4, -1.9, 1.9, 5.4]:
		_column(m + u, 0.4, 0.4, g + 10.3, g + 17.0, KARM_TRIM)
	_kp_arch_open(m, 0.05, g + 11.6, g + 14.6, 1.3, KP_DARK)  # the big window
	for sd: float in [-1.0, 1.0]:  # the niches and their statues
		_kp_arch_open(m + sd * 3.65, 0.05, g + 11.6, g + 14.4, 0.75, KARM_OCHRE.darkened(0.25))
		_kp_figure(m + sd * 3.65, 0.25, g + 11.7, 2.4, KARM_TRIM.lightened(0.05))
	_lbox(m, -1.0, 8.3, 2.0, g + 17.0, g + 18.0, KARM_TRIM, M_STONE, KARM_TRIM)
	# the attic, its sculpture groups, the copper globe and the gilt finial
	_lbox(m, -1.3, 6.4, 1.6, g + 18.0, g + 19.6, KARM_SAND, M_STONE, KARM_SAND)
	for u: float in [-7.6, -3.0, 3.0, 7.6]:
		_lbox(m + u, 0.3, 0.45, 0.4, g + 18.0, g + 19.0, KARM_TRIM, M_STONE, KARM_TRIM)
		_kp_figure(m + u, 0.3, g + 19.0, 1.8, KARM_TRIM)
	var c := _w(m, -0.3)
	_frustum(_circle(c, 0.6, 10), g + 19.6, _circle(c, 1.25, 10), g + 20.6, KARM_GLOBE)
	_frustum(_circle(c, 1.25, 10), g + 20.6, _circle(c, 0.9, 10), g + 21.8, KARM_GLOBE)
	_frustum(_circle(c, 0.9, 10), g + 21.8, _circle(c, 0.25, 10), g + 22.4, KARM_GLOBE, KARM_GLOBE)
	_lbox(m, -0.3, 0.1, 0.1, g + 22.4, g + 24.6, KP_GOLD, M_STONE, KP_GOLD)
	_lbox(m, -0.3, 0.5, 0.1, g + 23.6, g + 23.85, KP_GOLD, M_STONE, KP_GOLD)
	# the lantern turrets either side of the upper storey: a square drum with round openings,
	# a green cap and a small finial
	for sd: float in [-1.0, 1.0]:
		var u := m + sd * 10.6
		_lbox(u, -0.6, 1.6, 1.0, g + 10.3, g + 14.6, KARM_SAND, M_STONE, KARM_SAND)
		_lbox(u, -0.6, 1.75, 1.15, g + 14.6, g + 15.1, KARM_TRIM, M_STONE, KARM_TRIM)
		var t := _w(u, -0.6)
		var nb := Vector3(_b.x, 0.0, _b.y)
		_disc(Vector3(_w(u, 0.45).x, g + 12.5, _w(u, 0.45).y), nb, 0.55, 8, KP_DARK)
		_frustum(_circle(t, 1.3, 8), g + 15.1, _circle(t, 0.35, 8), g + 17.0, KARM_GLOBE, none)
		_prism(_circle(t, 0.35, 8), g + 17.0, g + 17.5, KARM_GLOBE, KARM_GLOBE, M_STONE, M_STONE)
		_lbox(u, -0.6, 0.06, 0.06, g + 17.5, g + 18.6, KP_GOLD, M_STONE, KP_GOLD)
	_collide(_rect(m, 1.5, 4.4, 1.0))


# --- Zamek Ostrogskich and the Chopin Institute (Tamka 41) -----------------------------------

## The parish church of St Thérèse of the Child Jesus (Kościół św. Teresy od Dzieciątka Jezus,
## Powiśle, Tamka): rebuilt 2026-11-13 from F's photos (a corner view from Tamka, the Flisac
## visualisation). A light cream plastered hall under a grey-green gable roof: tall round-headed
## windows with a lattice over plain panels, a round window in the front gable over a big arched
## porch, a green copper gutter line, a slim copper-capped stair tower at the street corner, a
## lower chapel at the choir end and the parish house behind. Not brick, as the first (photoless)
## model had it. The whole mapped outline is replaced; the massing follows it. Spec
## docs/landmarks/specs/teresy.md.
## Frame: origin at the outline's centre, u along the nave (axis 50 degrees), +v to the right
## of it; the nave is u -10..21.8, v -7.8..14.3, the front gable at u +21.8 (towards Tamka).
const TERESY := Vector2(369.93, -579.04)
const TERESY_AXIS := Vector2(0.6428, 0.7660)
const TERESY_BRICK := Color("#e4dbb8")      # the plaster (the name is from the first model)
const TERESY_BRICK_LOW := Color("#d9d0ac")  # the lower blocks and the panels under the windows
const TERESY_TILE := Color("#5f6c66")       # the roof's grey-green
const TERESY_TRIM := Color("#efe8cf")
const TERESY_DARK := Color("#343a40")
const TERESY_GOLD := Color("#c9a24a")
const TERESY_COPPER := Color("#6f9d88")     # the gutter line and the spire
const TERESY_DOOR := Color("#5b3626")
const TERESY_EAVES := 12.6
const TERESY_RISE := 7.0
const TERESY_WINDOWS := [-5.6, -0.2, 5.2, 10.6, 16.0]


func _find_teresy() -> void:
	var outline := _landmark("Parafia Świętej Teresy od Dzieciątka Jezus")
	if outline.size() >= 3:
		_add_site("teresy", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "teresy":
			sites[-1]["ring"] = outline


## A round-headed window on the nave's side wall at `face` (v), standing out of it towards
## `sgn` (+1: the +v wall): a trim frame, dark lattice glass, a plain panel under the sill.
func _teresy_window(face: float, sgn: float, u: float, y0: float, w: float, h: float) -> void:
	var out := _b * sgn
	var n3 := Vector3(out.x, 0.0, out.y)
	var arch := y0 + h - w * 0.5
	var keep := _mode
	# the panel under the sill and the frame
	_mode = M_STONE
	_wall(_w(u - w * 0.5 - 0.1, face + sgn * 0.04), _w(u + w * 0.5 + 0.1, face + sgn * 0.04), y0 - 3.0, y0 - 0.15, out, TERESY_BRICK_LOW)
	_wall(_w(u - w * 0.5 - 0.3, face + sgn * 0.05), _w(u + w * 0.5 + 0.3, face + sgn * 0.05), y0 - 0.15, arch, out, TERESY_TRIM)
	var cf := _w(u, face + sgn * 0.05)
	_arch_cap(Vector3(cf.x, arch, cf.y), n3, w * 0.5 + 0.3, 8, TERESY_TRIM)
	# the glass, a lattice of thin bars over it
	_mode = _pane_at(u, y0)
	_wall(_w(u - w * 0.5, face + sgn * 0.08), _w(u + w * 0.5, face + sgn * 0.08), y0, arch, out, TERESY_DARK)
	var cg := _w(u, face + sgn * 0.08)
	_arch_cap(Vector3(cg.x, arch, cg.y), n3, w * 0.5, 8, TERESY_DARK)
	_mode = M_STONE
	var bar := TERESY_DARK.lightened(0.18)
	for k in [-0.25, 0.25]:
		_wall(_w(u + w * k - 0.03, face + sgn * 0.12), _w(u + w * k + 0.03, face + sgn * 0.12), y0, arch + w * 0.4, out, bar)
	for yy in [y0 + h * 0.3, y0 + h * 0.58, arch]:
		_wall(_w(u - w * 0.5, face + sgn * 0.12), _w(u + w * 0.5, face + sgn * 0.12), yy, yy + 0.07, out, bar)
	_mode = keep


func _build_teresy(_site: Dictionary) -> void:
	_o = TERESY
	_a = TERESY_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(4.2, 3.25, 17.6, 11.0))
	var g := _g
	var wall := TERESY_BRICK
	var none := Color(0, 0, 0, 0)
	var eaves := g + TERESY_EAVES
	# the nave: a low plinth, cream plaster walls to the eaves, a green copper gutter line over a cornice
	_lbox(5.9, 3.25, 15.9, 11.05, g - 0.6, g + 1.0, TERESY_TRIM.darkened(0.14), M_STONE, TERESY_TRIM)
	_lbox(5.9, 3.25, 15.8, 10.95, g + 1.0, eaves - 0.5, wall, M_STONE, TERESY_TILE)
	_lbox(5.9, 3.25, 15.9, 11.05, eaves - 0.5, eaves - 0.1, TERESY_COPPER, M_STONE, TERESY_COPPER)
	_lbox(5.9, 3.25, 15.95, 11.1, eaves - 0.1, eaves + 0.3, TERESY_TRIM, M_STONE, TERESY_TILE)
	# the steep gable roof, the front gable's face in plaster
	_gable(21.95, -10.0, 3.25, 11.4, eaves + 0.3, TERESY_RISE, wall, TERESY_TILE)
	# the lower annex at the choir end and the polygonal chapel on the north side
	_lbox(-11.7, 5.8, 1.7, 8.5, g - 0.6, g + 6.5, TERESY_BRICK_LOW, M_STONE, TERESY_TILE)
	var chapel := PackedVector2Array([_w(-9.8, -7.9), _w(-10.0, -9.8), _w(-7.0, -11.9), _w(-3.0, -10.6),
			_w(-1.4, -7.6), _w(-1.4, -7.9)])
	_prism(chapel, g - 0.6, g + 7.5, TERESY_BRICK_LOW, none, M_STONE, M_STONE)
	_frustum(chapel, g + 7.5, _shrink_ring(chapel, 0.6), g + 9.0, TERESY_TILE, TERESY_TILE)
	# the parish house behind the nave: plaster, a window storey, a hipped roof
	_lbox(-3.25, 21.6, 7.55, 7.4, g - 0.6, g + 8.0, TERESY_BRICK_LOW, M_MONUMENT, TERESY_TILE)
	_lbox(-3.25, 21.6, 7.75, 7.6, g + 8.0, g + 8.5, TERESY_TRIM, M_STONE, TERESY_TRIM)
	_hip(-3.25, 21.6, 7.75, 7.6, g + 8.5, 3.6, TERESY_TILE)
	# the tall round-headed windows along both sides, and the corner piers
	for sd: float in [-1.0, 1.0]:
		var face := 3.25 + sd * 11.05
		for u: float in TERESY_WINDOWS:
			_teresy_window(face, sd, u, g + 4.0, 1.9, 7.3)
		for cu: float in [-9.9, 21.7]:
			_lbox(cu, 3.25 + sd * 10.8, 0.7, 0.45, g - 0.6, eaves - 0.1, TERESY_TRIM, M_STONE, TERESY_TRIM)
	# the front: a stepped plinth, the big arched porch with a dark recess and a smaller arch in it,
	# a round window with a trim ring over it, corner piers, a gilt cross at the apex
	var fa := Vector3(_a.x, 0.0, _a.y)
	_mode = M_STONE
	var porch := _w(21.97, 3.25)
	_wall(_w(21.96, 3.25 - 3.4), _w(21.96, 3.25 + 3.4), g + 0.4, g + 6.6, _a, TERESY_TRIM.darkened(0.05))
	_arch_cap(Vector3(porch.x, g + 6.6, porch.y), fa, 3.4, 10, TERESY_TRIM.darkened(0.05))
	_mode = _pane_at(1.0, 2.0)
	_wall(_w(21.99, 3.25 - 2.9), _w(21.99, 3.25 + 2.9), g + 0.9, g + 6.4, _a, TERESY_DARK.darkened(0.15))
	_arch_cap(Vector3(porch.x, g + 6.4, porch.y) + fa * 0.03, fa, 2.9, 10, TERESY_DARK.darkened(0.15))
	_mode = M_STONE
	_wall(_w(22.02, 3.25 - 1.5), _w(22.02, 3.25 + 1.5), g + 0.9, g + 5.0, _a, TERESY_DOOR)
	for k in 3:
		_lbox(22.6 + 0.5 * k, 3.25, 0.5, 3.9 - 0.3 * k, g - 0.6, g + 0.8 - 0.3 * k, TERESY_TRIM.darkened(0.12), M_STONE, TERESY_TRIM)
	var oc := _w(21.99, 3.25)
	_disc(Vector3(oc.x, g + 15.0, oc.y), fa, 2.1, 14, TERESY_TRIM.darkened(0.08))
	_mode = _pane_at(3.0, 4.0)
	_disc(Vector3(oc.x, g + 15.0, oc.y) + fa * 0.03, fa, 1.65, 14, TERESY_DARK)
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_lbox(22.1, 3.25 + sd * 10.6, 0.4, 0.8, g - 0.6, eaves + 0.3, TERESY_TRIM, M_STONE, TERESY_TRIM)
	_lbox(22.0, 3.25, 0.15, 0.15, g + 19.6, g + 22.6, TERESY_GOLD, M_STONE, TERESY_GOLD)
	_lbox(22.0, 3.25, 0.18, 0.7, g + 21.0, g + 21.3, TERESY_GOLD, M_STONE, TERESY_GOLD)
	# the side door by the front corner (brown, under a small hood, three steps)
	_wall(_w(18.6, 3.25 - 11.1), _w(20.4, 3.25 - 11.1), g + 0.3, g + 2.9, -_b, TERESY_DOOR)
	_lbox(19.5, 3.25 - 11.3, 1.2, 0.35, g + 2.9, g + 3.2, TERESY_TRIM, M_STONE, TERESY_TRIM)
	for k in 3:
		_lbox(19.5, 3.25 - 11.4 - 0.3 * k, 1.3, 0.3, g - 0.6, g + 0.45 - 0.15 * k, TERESY_TRIM.darkened(0.12), M_STONE, TERESY_TRIM)
	# the stair tower at the street corner: a cream shaft with louvres, a copper spire and a cross
	_lbox(15.9, 3.25 + 11.4, 1.7, 1.5, g - 0.6, g + 20.4, wall, M_STONE, wall)
	_lbox(15.9, 3.25 + 11.4, 1.9, 1.7, g + 20.2, g + 21.0, TERESY_TRIM, M_STONE, TERESY_TRIM)
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_wall(_w(14.8, 3.25 + 11.4 + sd * 1.52), _w(17.0, 3.25 + 11.4 + sd * 1.52), g + 15.4, g + 19.2, _b * sd, TERESY_DARK)
		_wall(_w(15.9 + sd * 1.72, 3.25 + 11.4 - 0.9), _w(15.9 + sd * 1.72, 3.25 + 11.4 + 0.9), g + 15.4, g + 19.2, _a * sd, TERESY_DARK)
	_pyramid(_rect(15.9, 3.25 + 11.4, 1.95, 1.75), g + 21.0, g + 30.0, TERESY_COPPER)
	_lbox(15.9, 3.25 + 11.4, 0.12, 0.12, g + 30.0, g + 32.2, TERESY_GOLD, M_STONE, TERESY_GOLD)
	_lbox(15.9, 3.25 + 11.4, 0.12, 0.55, g + 31.2, g + 31.5, TERESY_GOLD, M_STONE, TERESY_GOLD)
	# the car stops at the walls
	_collide(_rect(5.9, 3.25, 15.9, 11.05))
	_collide(_rect(-3.25, 21.6, 7.55, 7.4))
	_collide(chapel)


## A ring pulled in towards its centre by `d` metres (a roof's inner ring).
func _shrink_ring(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := _centre(ring)
	var out := PackedVector2Array()
	for p in ring:
		var dir := p - c
		out.append(p - dir.normalized() * minf(d, dir.length() * 0.9))
	return out


# --- Stadion Leguminy (Legia's ground, Łazienkowska) -----------------------------------------

## --- The church kit (F, 2026-11-01: "all the churches should be designed with best practices") ---
## One builder for the parish churches that had no model of their own (spec
## docs/landmarks/specs/churches.md, rules in docs/design/churches.md). Each church is found by
## the OpenStreetMap outline under its `at` point and read as a long box (found offline, a
## constant: the box's front-end middle `o`, the way out `out`, half length `L`, half width
## `W`, `fill` = outline area / box area). The front is the end nearest a street. Built by the
## rules every church here follows:
##   * orientation: the entrance faces the street, the apse (the outline's far end) the other way;
##   * the body is the mapped outline on a plinth, a windowed storey and a cornice, so every
##     transept, aisle and apse the map has stays;
##   * one steep gabled nave roof along the long axis, pitch by style (gothic steepest);
##   * a facade with a portal, steps, a window or a rose above it and a pediment or a gable;
##   * towers by count: one on the axis or two flanking, a shaft, a belfry with dark louvres
##     and a cap by type (helm, dome, pyramid, spire, onion, ridge turret); every cap is
##     crowned with a gilt cross;
##   * buttresses (gothic) and lesenes (baroque, romanesque) along the long walls.
## Heights, towers and caps are estimates (no photos in the cloud): the Mac photo check waits in
## QUESTIONS. All in the city's one building surface: no new material or draw call.
const CHURCH_STYLES := {
	"baroque": {"eave": 1.1, "pitch": 0.62, "tower": 2.3, "lesene": true, "buttress": false},
	"neoclassical": {"eave": 1.1, "pitch": 0.45, "tower": 2.0, "lesene": true, "buttress": false},
	"romanesque": {"eave": 1.25, "pitch": 0.6, "tower": 2.6, "lesene": true, "buttress": false},
	"neogothic": {"eave": 1.4, "pitch": 1.0, "tower": 3.0, "lesene": false, "buttress": true},
	"modern": {"eave": 0.95, "pitch": 0.4, "tower": 2.4, "lesene": false, "buttress": false},
	"orthodox": {"eave": 1.1, "pitch": 0.5, "tower": 0.0, "lesene": true, "buttress": false},
}
const CHURCH_TRIM := Color("#ece4d2")
const CHURCH_BASE := Color("#a39b8a")
const CHURCH_DARK := Color("#3a3d40")
const CHURCH_GOLD := Color("#c9a24a")
const CHURCH_COPPER := Color("#6f8c80")
## A cap's profile: [radius / tower half-width, height / tower half-width], from the belfry up.
const CHURCH_CAPS := {
	"helm": [[1.0, 0.0], [1.2, 0.9], [0.5, 2.6], [0.32, 3.0]],
	"dome": [[1.0, 0.0], [1.08, 0.4], [0.85, 1.2], [0.42, 1.9], [0.3, 2.2]],
	"onion": [[1.0, 0.0], [1.4, 0.9], [1.1, 1.9], [0.4, 3.1], [0.12, 3.9]],
}
const CHURCHES := [
	{"key": "church_sw_marcin", "at": Vector2(-801.1, -1577.0), "o": Vector2(-822.8, -1556.1), "out": Vector2(-0.7270, 0.6866), "L": 27.8, "W": 11.6,
			"fill": 0.86, "style": "baroque", "wall": "#e6d8b8", "roof": "#8a5a44", "towers": 0, "cap": "turret"},
	{"key": "church_kapucyni", "at": Vector2(-978.6, -1420.2), "o": Vector2(-967.4, -1438.7), "out": Vector2(0.6149, -0.7886), "L": 16.5, "W": 13.4,
			"fill": 0.88, "style": "baroque", "wall": "#e2d3b0", "roof": "#7a5a48", "towers": 0, "cap": "none"},
	{"key": "church_niepokalanego", "at": Vector2(-642.8, -1242.9), "o": Vector2(-654.5, -1239.1), "out": Vector2(-0.9519, 0.3064), "L": 9.2, "W": 4.4,
			"fill": 0.97, "style": "baroque", "wall": "#e7dcc4", "roof": "#6f8a7c", "towers": 1, "cap": "helm"},
	{"key": "church_katedra_polowa", "at": Vector2(-1165.4, -1648.4), "o": Vector2(-1175.4, -1655.8), "out": Vector2(-0.7809, -0.6247), "L": 20.2, "W": 13.8,
			"fill": 0.83, "style": "baroque", "wall": "#e4d7b6", "roof": "#6f8a7c", "towers": 2, "cap": "dome"},
	{"key": "church_duch", "at": Vector2(-1013.7, -1834.9), "o": Vector2(-1005.6, -1848.8), "out": Vector2(0.5283, -0.8491), "L": 22.0, "W": 12.0,
			"fill": 0.89, "style": "baroque", "wall": "#e9e0c8", "roof": "#7b5a4a", "towers": 1, "cap": "helm"},
	{"key": "church_jacek", "at": Vector2(-988.8, -1933.8), "o": Vector2(-974.1, -1949.7), "out": Vector2(0.6805, -0.7328), "L": 35.0, "W": 16.0,
			"fill": 0.83, "style": "baroque", "wall": "#e3d3ae", "roof": "#8a5a44", "towers": 2, "cap": "helm"},
	{"key": "church_antoniego", "at": Vector2(-1193.0, -976.1), "o": Vector2(-1234.0, -998.3), "out": Vector2(-0.7251, -0.6886), "L": 36.0, "W": 28.6,
			"fill": 0.43, "style": "baroque", "wall": "#e5d9bd", "roof": "#7a5a48", "towers": 1, "cap": "helm"},
	{"key": "church_alberta", "at": Vector2(-1074.4, -1127.9), "o": Vector2(-1058.3, -1139.9), "out": Vector2(0.8077, -0.5896), "L": 21.5, "W": 9.2,
			"fill": 0.95, "style": "modern", "wall": "#e8e1d2", "roof": "#6b4f45", "towers": 1, "cap": "pyramid"},
	{"key": "church_reformowany", "at": Vector2(-1755.4, -1115.8), "o": Vector2(-1763.5, -1131.3), "out": Vector2(-0.4551, -0.8904), "L": 25.6, "W": 10.9,
			"fill": 0.84, "style": "romanesque", "wall": "#a9553f", "roof": "#725f58", "towers": 1, "cap": "pyramid"},
	{"key": "church_jerozolimska", "at": Vector2(983.6, 1333.5), "o": Vector2(985.0, 1300.7), "out": Vector2(0.0905, -0.9959), "L": 23.3, "W": 14.4,
			"fill": 0.77, "style": "neogothic", "wall": "#a44b38", "roof": "#6e5d58", "towers": 1, "cap": "spire"},
	{"key": "church_zielonoswiatkowy", "at": Vector2(-1893.9, 324.7), "o": Vector2(-1902.4, 350.9), "out": Vector2(-0.3881, 0.9216), "L": 24.3, "W": 16.6,
			"fill": 0.71, "style": "modern", "wall": "#e6e0d2", "roof": "#6a5a52", "towers": 0, "cap": "none"},
	{"key": "church_dzieciatka", "at": Vector2(-1826.5, 978.4), "o": Vector2(-1806.5, 971.8), "out": Vector2(0.9353, -0.3539), "L": 18.7, "W": 9.3,
			"fill": 0.74, "style": "modern", "wall": "#ddd6c8", "roof": "#6a6560", "towers": 1, "cap": "pyramid"},
	{"key": "church_narodzenia", "at": Vector2(-1966.9, -973.5), "o": Vector2(-1975.7, -990.6), "out": Vector2(-0.4758, -0.8795), "L": 16.5, "W": 13.1,
			"fill": 0.95, "style": "baroque", "wall": "#e3d6b8", "roof": "#7a5a48", "towers": 1, "cap": "helm"},
	{"key": "church_karol", "at": Vector2(-2145.5, -464.5), "o": Vector2(-2127.0, -475.4), "out": Vector2(0.8643, -0.5029), "L": 21.2, "W": 10.7,
			"fill": 0.74, "style": "baroque", "wall": "#e5d8b8", "roof": "#7a5a48", "towers": 1, "cap": "helm"},
	{"key": "church_augustyn", "at": Vector2(-2419.7, -1182.2), "o": Vector2(-2430.0, -1202.4), "out": Vector2(-0.4548, -0.8906), "L": 33.9, "W": 18.6,
			"fill": 0.77, "style": "romanesque", "wall": "#b0603f", "roof": "#725f58", "towers": 1, "cap": "pyramid"},
	{"key": "church_miloserdzie", "at": Vector2(-2748.1, -688.9), "o": Vector2(-2754.0, -711.9), "out": Vector2(-0.2703, -0.9628), "L": 19.7, "W": 9.1,
			"fill": 0.76, "style": "modern", "wall": "#e8e2d4", "roof": "#6a5a52", "towers": 1, "cap": "pyramid"},
	{"key": "church_piotr_pawel", "at": Vector2(-1118.0, 825.3), "o": Vector2(-1097.4, 819.0), "out": Vector2(0.9412, -0.3379), "L": 29.8, "W": 16.6,
			"fill": 0.73, "style": "neogothic", "wall": "#a44b38", "roof": "#6e5d58", "towers": 1, "cap": "spire"},
	{"key": "church_trojca_praga", "at": Vector2(1062.7, 268.0), "o": Vector2(1077.3, 252.8), "out": Vector2(0.6905, -0.7234), "L": 15.5, "W": 8.4,
			"fill": 0.63, "style": "neoclassical", "wall": "#e7dfcb", "roof": "#6f7a76", "towers": 0, "cap": "none"},
	{"key": "church_czestochowska", "at": Vector2(1126.9, 859.8), "o": Vector2(1148.1, 878.9), "out": Vector2(0.7634, 0.6459), "L": 22.3, "W": 13.1,
			"fill": 0.63, "style": "modern", "wall": "#e6dfcf", "roof": "#6a5a52", "towers": 1, "cap": "pyramid"},
	{"key": "church_zwycieska", "at": Vector2(1966.0, -1382.0), "o": Vector2(1963.6, -1358.3), "out": Vector2(-0.0905, 0.9959), "L": 28.2, "W": 18.7,
			"fill": 0.75, "style": "neogothic", "wall": "#a8503c", "roof": "#6e5d58", "towers": 2, "cap": "spire"},
	{"key": "church_cerkiew", "at": Vector2(-1021.4, -1523.2), "o": Vector2(-1027.9, -1513.5), "out": Vector2(-0.5623, 0.8269), "L": 12.2, "W": 7.9,
			"fill": 0.96, "style": "orthodox", "wall": "#ece4d2", "roof": "#4a6a5a", "towers": 0, "cap": "onion"},
	{"key": "church_bazylianie", "at": Vector2(-1029.8, -1510.2), "o": Vector2(-1031.3, -1507.6), "out": Vector2(-0.568, 0.822), "L": 39.4, "W": 6.9,
			"fill": 0.9, "style": "neoclassical", "wall": "#ebe5d7", "roof": "#5d6268", "towers": 0, "cap": "none"},
	{"key": "church_dominikanie", "at": Vector2(-961.0, -1965.0), "o": Vector2(-972.6, -1973.6), "out": Vector2(-0.710, -0.704), "L": 62.0, "W": 13.8,
			"fill": 0.8, "style": "baroque", "wall": "#e6d4a6", "roof": "#97594a", "towers": 0, "cap": "none"},
	{"key": "church_rodziny_maryi", "at": Vector2(-2617.0, -739.0), "o": Vector2(-2625.3, -761.4), "out": Vector2(-0.356, -0.934), "L": 13.5, "W": 49.4,
			"fill": 0.9, "style": "neoclassical", "wall": "#e6c2a2", "roof": "#4d5257", "towers": 0, "cap": "none"},
	{"key": "church_siostry_milosierdzia_zytnia", "at": Vector2(-2790.0, -692.0), "o": Vector2(-2813.5, -695.3), "out": Vector2(-0.262, -0.965), "L": 41.6, "W": 16.2,
			"fill": 0.9, "style": "modern", "wall": "#a24f3a", "roof": "#5f6163", "towers": 0, "cap": "none"},
	{"key": "church_klopotowskiego_18", "at": Vector2(548.0, -1806.0), "o": Vector2(531.8, -1805.0), "out": Vector2(-0.560, -0.819), "L": 21.4, "W": 41.9,
			"fill": 0.9, "style": "neoclassical", "wall": "#ecebe6", "roof": "#5d5f60", "towers": 0, "cap": "none"},
	{"key": "church_plebania_florian", "at": Vector2(534.0, -1963.0), "o": Vector2(525.0, -1990.5), "out": Vector2(0.175, -0.985), "L": 29.7, "W": 48.1,
			"fill": 0.9, "style": "neoclassical", "wall": "#ece6d8", "roof": "#55504c", "towers": 0, "cap": "none"},
	{"key": "church_zwycieska_klasztor", "at": Vector2(2034.0, -1361.0), "o": Vector2(2016.9, -1370.6), "out": Vector2(0.116, -0.993), "L": 35.9, "W": 18.4,
			"fill": 0.9, "style": "neoclassical", "wall": "#e6dfcc", "roof": "#b0583b", "towers": 0, "cap": "none"},
	{"key": "church_zytnia_dom_zakonny", "at": Vector2(-2680.0, -736.0), "o": Vector2(-2699.1, -732.6), "out": Vector2(-0.366, -0.931), "L": 39.8, "W": 8.0,
			"fill": 0.9, "style": "neoclassical", "wall": "#e9d8b2", "roof": "#55585c", "towers": 0, "cap": "none"},
	{"key": "church_zytnia_dom_zakonny_tyl", "at": Vector2(-2650.0, -705.0), "o": Vector2(-2679.6, -701.0), "out": Vector2(-0.308, -0.951), "L": 66.2, "W": 8.5,
			"fill": 0.9, "style": "neoclassical", "wall": "#e9d8b2", "roof": "#55585c", "towers": 0, "cap": "none"},
	{"key": "church_kaplica_florianska", "at": Vector2(459.3, -1999.7), "o": Vector2(459.3, -1999.7), "out": Vector2(-1.0, 0.0), "L": 6.2, "W": 6.3,
			"fill": 0.9, "style": "neogothic", "wall": "#9b4535", "roof": "#3b3d42", "towers": 0, "cap": "none"},
	{"key": "church_kaplica_lucka", "at": Vector2(-2257.0, 72.4), "o": Vector2(-2263.0, 68.5), "out": Vector2(0.337, 0.942), "L": 8.8, "W": 11.4,
			"fill": 0.9, "style": "modern", "wall": "#e4dccb", "roof": "#b9b7b1", "towers": 0, "cap": "none"},
	{"key": "church_kaplica_hoza", "at": Vector2(-1008.9, 1027.6), "o": Vector2(-1007.9, 1019.2), "out": Vector2(-0.356, -0.935), "L": 18.7, "W": 5.9,
			"fill": 0.9, "style": "modern", "wall": "#ddd6c8", "roof": "#b9b7b1", "towers": 0, "cap": "none"},
	{"key": "church_sluzki_dom_generalny", "at": Vector2(-203.0, -515.0), "o": Vector2(-206.4, -500.9), "out": Vector2(-0.917, 0.400), "L": 28.3, "W": 29.6,
			"fill": 0.9, "style": "neoclassical", "wall": "#e3c48e", "roof": "#6b6c6c", "towers": 0, "cap": "none"},
	{"key": "church_uczennice_boskiego_mistrza", "at": Vector2(-2890.0, -650.0), "o": Vector2(-2919.2, -669.7), "out": Vector2(-0.231, -0.973), "L": 37.5, "W": 41.5,
			"fill": 0.9, "style": "modern", "wall": "#a5503a", "roof": "#6d6a66", "towers": 0, "cap": "none"},
	{"key": "church_plebania_augustyn", "at": Vector2(-2405.0, -1115.0), "o": Vector2(-2406.0, -1124.2), "out": Vector2(0.884, -0.466), "L": 14.6, "W": 18.5,
			"fill": 0.9, "style": "modern", "wall": "#e3dccd", "roof": "#77736c", "towers": 0, "cap": "none"},
	{"key": "church_plebania_katedra_polowa", "at": Vector2(-1152.6, -1669.6), "o": Vector2(-1165.3, -1665.4), "out": Vector2(-0.781, -0.624), "L": 23.0, "W": 15.2,
			"fill": 0.9, "style": "neoclassical", "wall": "#e8dcc0", "roof": "#6f8d7e", "towers": 0, "cap": "none"},
	{"key": "church_reformaci_klasztor", "at": Vector2(-1170.0, -1001.0), "o": Vector2(-1193.3, -1001.9), "out": Vector2(-0.7464, -0.6655), "L": 36.0, "W": 36.0,
			"fill": 0.9, "style": "baroque", "wall": "#f0ece2", "roof": "#c4603d", "towers": 0, "cap": "none"},
	{"key": "church_wizytki_klasztor", "at": Vector2(-444.8, -828.1), "o": Vector2(-458.1, -836.4), "out": Vector2(-0.518, -0.856), "L": 52.0, "W": 56.0,
			"fill": 0.9, "style": "baroque", "wall": "#e8dcc2", "roof": "#9a5545", "towers": 0, "cap": "none"},
	{"key": "church_sala_faustyny", "at": Vector2(-2795.0, 1570.0), "o": Vector2(-2794.0, 1577.0), "out": Vector2(0.0, 1.0), "L": 27.0, "W": 14.0,
			"fill": 0.9, "style": "modern", "wall": "#b0503a", "roof": "#4e4f52", "towers": 0, "cap": "none"},
	{"key": "church_franciszkanki_piwna", "at": Vector2(-780.1, -1560.9), "o": Vector2(-765.2, -1574.8), "out": Vector2(0.7804, -0.6253), "L": 29.4, "W": 44.0,
			"fill": 0.9, "style": "baroque", "wall": "#e2b86c", "roof": "#9a5040", "towers": 0, "cap": "none"},
	{"key": "church_kapucyni_klasztor", "at": Vector2(-1010.6, -1414.6), "o": Vector2(-1010.8, -1419.8), "out": Vector2(-0.5343, -0.8453), "L": 35.4, "W": 9.0,
			"fill": 0.9, "style": "baroque", "wall": "#ecdcae", "roof": "#86a993", "towers": 0, "cap": "none"},
	{"key": "church_misjonarze_radna", "at": Vector2(-66.4, -747.0), "o": Vector2(-63.9, -741.6), "out": Vector2(0.459, 0.888), "L": 24.6, "W": 25.2,
			"fill": 0.9, "style": "neoclassical", "wall": "#e8dcb8", "roof": "#6a6460", "towers": 0, "cap": "none"},
	{"key": "church_misjonarze", "at": Vector2(-517.5, -570.7), "o": Vector2(-476.1, -569.1), "out": Vector2(0.958, -0.288), "L": 41.0, "W": 14.4,
			"fill": 0.9, "style": "baroque", "wall": "#d7c08a", "roof": "#5b5d60", "towers": 0, "cap": "none"},
	{"key": "church_barbara", "at": Vector2(-1102.0, 874.5), "o": Vector2(-1100.2, 865.8), "out": Vector2(0.940, -0.342), "L": 15.3, "W": 9.0,
			"fill": 0.9, "style": "neogothic", "wall": "#a4553f", "roof": "#4b4d50", "towers": 0, "cap": "none"},
	{"key": "church_baptysci", "at": Vector2(-2254.2, -355.1), "o": Vector2(-2251.1, -369.6), "out": Vector2(0.964, -0.265), "L": 24.0, "W": 20.0,
			"fill": 0.9, "style": "modern", "wall": "#d6d4cc", "roof": "#9a978f", "towers": 0, "cap": "none"},
	{"key": "church_chrystusa_krola", "at": Vector2(1729.0, -1673.0), "o": Vector2(1715.0, -1688.0), "out": Vector2(-0.607, -0.795), "L": 20.0, "W": 12.0,
			"fill": 0.8, "style": "modern", "wall": "#eedfb4", "roof": "#7c6a4b", "towers": 1, "cap": "none"},
	{"key": "church_pallotyni", "at": Vector2(1761.0, -1687.0), "o": Vector2(1760.6, -1702.8), "out": Vector2(0.560, -0.829), "L": 51.2, "W": 24.1,
			"fill": 0.8, "style": "modern", "wall": "#d8cba2", "roof": "#8c8b86", "towers": 0, "cap": "none"},
	{"key": "church_nozykow", "at": Vector2(-1569.1, -228.0), "o": Vector2(-1546.1, -229.5), "out": Vector2(0.9975, -0.0712), "L": 16.4, "W": 11.6,
			"fill": 0.78, "style": "romanesque", "wall": "#d9c9a3", "roof": "#6f7a76", "towers": 0, "cap": "none"},
]


func _find_churches() -> void:
	for ch: Dictionary in CHURCHES:
		var outline := _outline_at(ch["at"])
		if outline.size() < 3:
			continue
		var zone: Array = [_largest(Geometry2D.offset_polygon(outline, 3.0, Geometry2D.JOIN_MITER))]
		# The Community's wing east of the Nożyk Synagogue reaches into the zone: keep it the map's.
		_add_site(ch["key"], zone, [_nz_wing_ring()] if ch["key"] == "church_nozykow" else [])
		if not sites.is_empty() and sites[-1]["key"] == ch["key"]:
			sites[-1]["outline"] = outline
			if ch["key"] == "church_sw_marcin":
				_marcin_tops()  # the LoD2 tower in the monastery's block, under the model's tower
			elif ch["key"] == "church_jerozolimska":
				_jz_tops()  # the bell tower is LoD2 in the next block: cut it under the model's tower
			elif ch["key"] == "church_niepokalanego":
				_np_tops()  # the church is part of the convent's one LoD2 run: cut it under the model


func _near_any(spots: Array[Vector2], p: Vector2, r: float) -> bool:
	for q in spots:
		if q.distance_to(p) < r:
			return true
	return false


func _church_spec(key: String) -> Dictionary:
	for ch: Dictionary in CHURCHES:
		if ch["key"] == key:
			return ch
	return {}


func _build_church(site: Dictionary) -> void:
	if site["key"] == "church_zwycieska":
		_build_zwycieska(site)  # the whole 1930s co-cathedral from photos, front to Grochowska, not the kit church
		return
	if site["key"] == "church_piotr_pawel":
		_build_piotr_pawel(site)  # the whole basilica, its dome and two front towers from photos, front to the west
		return
	if site["key"] == "church_antoniego":
		_build_antoniego(site)  # the whole Franciscan church, its turret, chapel and cloister from photos
		return
	if site["key"] == "church_katedra_polowa":
		_build_katedra_polowa(site)  # the whole cathedral from photos, not the kit church
		return
	if site["key"] == "church_kapucyni":
		_build_kapucyni(site)  # the whole Capuchin church from photos, not the kit church
		return
	if site["key"] == "church_jacek":
		_build_jacek(site)  # the whole St Hyacinth's church from photos, not the kit church
		return
	if site["key"] == "church_sw_marcin":
		_build_marcin(site)  # the whole St Martin's church and its tower from photos, not the kit church
		return
	if site["key"] == "church_duch":
		_build_duch(site)  # the whole Holy Spirit church and its two towers from photos, not the kit church
		return
	if site["key"] == "church_niepokalanego":
		_build_niepokalanego(site)  # the whole Res Sacra Miser church from photos, not the kit church
		return
	if site["key"] == "church_nozykow":
		_build_nozyk(site)  # the whole Nożyk Synagogue from photos, front to the west, not the kit church
		return
	if site["key"] == "church_dzieciatka":
		_build_dzieciatka(site)  # the whole brick Child Jesus church from photos, tower to the west, not the kit church
		return
	if site["key"] == "church_augustyn":
		_build_augustyn(site)  # the whole brick basilica and its 70 m tower
		return
	if site["key"] == "church_trojca_praga":
		_build_trojca_solec(site)  # Holy Trinity on Solec: temple front and crossing turret, from photos
		return
	if site["key"] == "church_czestochowska":
		_build_czestochowska(site)  # the modernist A-frame church and its pylons, from photos
		return
	if site["key"] == "church_siostry_milosierdzia_zytnia":
		_build_siostry_milosierdzia_zytnia(site)  # the Sisters of Our Lady of Mercy's house on Żytnia, from photos and LoD2
		return
	if site["key"] == "church_plebania_florian":
		_build_plebania_florian(site)  # St Florian's presbytery on Floriańska, from photos and LoD2
		return
	if site["key"] == "church_klopotowskiego_18":
		_build_klopotowskiego_18(site)  # the church house with the window of life on Kłopotowskiego, from photos and LoD2
		return
	if site["key"] == "church_zwycieska_klasztor":
		_build_zwycieska_klasztor(site)  # the monastery block beside Our Lady of Victory, from LoD2 (provisional)
		return
	if site["key"] == "church_zytnia_dom_zakonny":
		_build_zytnia_dom_zakonny(site)  # the convent range on Żytnia's south side, from photos and LoD2
		return
	if site["key"] == "church_zytnia_dom_zakonny_tyl":
		_build_zytnia_dom_zakonny_tyl(site)  # the range behind the convent on Żytnia, from LoD2 (provisional)
		return
	if site["key"] == "church_kaplica_florianska":
		_build_kaplica_florianska(site)  # the octagonal brick chapel with its slate bell roof, from photos
		return
	if site["key"] == "church_kaplica_lucka":
		_build_kaplica_lucka(site)  # the flat-roofed yard chapel behind Łucka, provisional
		return
	if site["key"] == "church_kaplica_hoza":
		_build_kaplica_hoza(site)  # the flat-roofed yard chapel behind Hoża 55, provisional
		return
	if site["key"] == "church_sluzki_dom_generalny":
		_build_sluzki_dom_generalny(site)  # the Servants of Jesus' generalate, from photos and LoD2
		return
	if site["key"] == "church_uczennice_boskiego_mistrza":
		_build_uczennice_boskiego_mistrza(site)  # the Sister Disciples' brick convent on Żytnia, from photos and LoD2
		return
	if site["key"] == "church_plebania_augustyn":
		_build_plebania_augustyn(site)  # St Augustine's presbytery from LoD2 (defaults until photos)
		return
	if site["key"] == "church_plebania_katedra_polowa":
		_build_plebania_katedra_polowa(site)  # the Field Cathedral's presbytery on Długa, from photos and LoD2
		return
	if site["key"] == "church_reformaci_klasztor":
		_build_reformaci_klasztor(site)  # the Reformati friary by St Anthony's from LoD2 (the church's colours)
		return
	if site["key"] == "church_wizytki_klasztor":
		_build_wizytki_klasztor(site)  # the Visitation sisters' convent from LoD2 (defaults until photos)
		return
	if site["key"] == "church_sala_faustyny":
		_build_sala_faustyny(site)  # the St Faustina hall in Ochota, from a photo
		return
	if site["key"] == "church_franciszkanki_piwna":
		_build_franciszkanki_piwna(site)  # the Franciscan Sisters' house on Piwna, from photos and LoD2
		return
	if site["key"] == "church_kapucyni_klasztor":
		_build_kapucyni_klasztor(site)  # the Capuchin monastery on Miodowa, from photos and LoD2
		return
	if site["key"] == "church_misjonarze_radna":
		_build_misjonarze_radna(site)  # the Missionaries' house on Radna, from photos and LoD2
		return
	if site["key"] == "church_misjonarze":
		_build_misjonarze(site)  # the Missionaries' house on Krakowskie Przedmieście, from photos and LoD2
		return
	if site["key"] == "church_barbara":
		_build_barbara(site)  # St Barbara's brick chapel on Koszyki, from photos and LoD2
		return
	if site["key"] == "church_baptysci":
		_build_baptysci(site)  # the Baptists' modernist box on Waliców, from photos
		return
	if site["key"] == "church_chrystusa_krola":
		_build_chrystusa_krola(site)  # the Pallottines' church and its chapel on Skaryszewska, from photos
		return
	if site["key"] == "church_pallotyni":
		_build_pallotyni(site)  # the Pallottines' 1930s modernist house on Skaryszewska
		return
	if site["key"] == "church_rodziny_maryi":
		_build_rodziny_maryi(site)  # the Franciscan sisters' long peach house
		return
	if site["key"] == "church_dominikanie":
		_build_dominikanie(site)  # the Dominican priory's wings round the cloister
		return
	if site["key"] == "church_bazylianie":
		_build_bazylianie(site)  # the Basilian monastery's street wing with the church's front
		return
	if site["key"] == "church_cerkiew":
		_build_cerkiew(site)  # the Basilians' church hall without the kit's onion dome
		return
	if site["key"] == "church_narodzenia":
		_build_narodzenia(site)  # the whole Baroque church and its clock turret, from photos
		return
	if site["key"] == "church_reformowany":
		_build_reformowany(site)  # the whole neo-Gothic church with its openwork spire, from photos
		return
	if site["key"] == "church_alberta":
		_build_alberta(site)  # the whole classicist front on Plac Teatralny, its portico and the two wings, from photos
		return
	if site["key"] == "church_jerozolimska":
		_build_jerozolimska(site)  # the whole brick church on Łazienkowska, its portico and its bell tower, from photos
		return
	if site["key"] == "church_karol":
		_build_karol(site)  # the whole cream classicist church on Chłodna, its two west towers and the apse, from photos
		return
	if site["key"] == "church_zielonoswiatkowy":
		_build_zielonoswiatkowy(site)  # the whole modernist Pentecostal hall from photos, not the kit church
		return
	if site["key"] == "church_miloserdzie":
		_build_miloserdzie(site)  # the whole white Divine Mercy church and its bell tower from photos, not the kit church
		return
	var ch := _church_spec(site["key"])
	if ch.is_empty():
		return
	var style: Dictionary = CHURCH_STYLES[ch["style"]]
	_o = ch["o"]
	_b = ch["out"]
	_a = Vector2(-_b.y, _b.x)
	var outline: PackedVector2Array = _simplify(site["outline"], 0.6)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var w_half: float = ch["W"]
	var l_half: float = ch["L"]
	var wall := Color(ch["wall"])
	var roof := Color(ch["roof"])
	var trim := CHURCH_TRIM if wall.get_luminance() > 0.55 else wall.lightened(0.28)
	var brick := wall.get_luminance() < 0.5
	var eave := clampf(w_half * float(style["eave"]), 7.5, 15.0)
	var rise := w_half * float(style["pitch"])
	_mode = M_STONE
	# The body: plinth, a windowed storey, a cornice with the flat deck behind the gable.
	var plinth := _largest(Geometry2D.offset_polygon(outline, 0.3, Geometry2D.JOIN_MITER))
	_prism(plinth, g - 0.6, g + 1.2, CHURCH_BASE, CHURCH_BASE.lightened(0.05), M_STONE, M_STONE)
	_prism(outline, g + 1.2, g + eave, wall, none, M_MONUMENT)
	var cornice := _largest(Geometry2D.offset_polygon(outline, 0.45, Geometry2D.JOIN_MITER))
	_prism(cornice, g + eave, g + eave + 0.7, trim, roof.lerp(Color("#76726e"), 0.45), M_STONE, M_STONE)
	# The nave's roof: a gable along the long axis over the box (a narrower one where the plan
	# is a cross, so the transepts' flat decks stay below it).
	var nave_w: float = w_half if float(ch["fill"]) >= 0.8 else w_half * 0.62
	var y_roof := g + eave + 0.7
	_church_roof(nave_w, l_half, y_roof, rise, wall, roof)
	# Lesenes (baroque, romanesque) or buttresses (gothic) along the long walls.
	if bool(style["lesene"]) or bool(style["buttress"]):
		var placed: Array[Vector2] = []
		var n := outline.size()
		for i in n:
			var p := outline[i]
			var q := outline[(i + 1) % n]
			var e := q - p
			var elen := e.length()
			if elen < 6.0 or absf(e.normalized().dot(_b)) < 0.94:
				continue
			var out := _out(outline, p, q)
			var cnt := int(elen / 4.8)
			for k in range(1, cnt + 1):
				var m := p + e * (float(k) / (cnt + 1))
				var lm := _local(m + out * 0.22)
				if lm.y > -1.5 or _near_any(placed, lm, 1.2):
					continue  # the front has its own pilasters; never two on one spot
				placed.append(lm)
				if bool(style["buttress"]):
					_lbox(lm.x, lm.y, 0.3, 0.3, g + 0.9, g + eave - 1.5, trim, M_STONE, trim)
					_lbox(lm.x + out.dot(_a) * 0.1, lm.y, 0.22, 0.22, g + eave - 1.5, g + eave - 0.2, trim, M_STONE, trim)
				else:
					_lbox(lm.x, lm.y, 0.2, 0.2, g + 0.9, g + eave, trim, M_STONE, trim)
	# The front: a portal with steps, a window above it, pilasters at the corners.
	_church_front(ch, style, g, eave, w_half, trim, wall, roof, brick)
	# The towers.
	var ts := clampf(w_half * 0.3, 2.0, 3.6)
	var tw: int = ch["towers"]
	var ht := clampf(eave * float(style["tower"]), eave + 4.0, 34.0)
	var tv := 0.2 - ts
	var spots: Array[float] = []
	if tw == 1:
		spots.append(0.0)
	elif tw >= 2:
		spots.append(-(w_half - ts - 0.15))
		spots.append(w_half - ts - 0.15)
	for tu: float in spots:
		_church_tower(tu, tv, ts, g, ht, ch, wall, trim, roof)
		_collide(_rect(tu, tv, ts, ts))
	if ch["cap"] == "turret":
		_church_tower(0.0, -2.0 * l_half * 0.28, 1.1, g, eave + rise + 2.0, ch, wall, trim, roof, true)
	if ch["cap"] == "onion":
		_church_onion(g, eave + rise + 0.7, l_half, ch)
	if tw == 0 and ch["cap"] != "onion":
		_lbox(0.0, -0.6, 0.14, 0.14, g + eave + rise, g + eave + rise + 3.4, CHURCH_GOLD, M_STONE, CHURCH_GOLD)
		_lbox(0.0, -0.6, 0.7, 0.14, g + eave + rise + 2.2, g + eave + rise + 2.5, CHURCH_GOLD, M_STONE, CHURCH_GOLD)
	_collide(outline)


## The nave's gable roof along the long axis: front and back gable triangles in the wall's
## colour, two slopes. In the swapped frame `_gable` expects (see _build_zbawiciela).
func _church_roof(hw: float, l_half: float, y: float, rise: float, wall: Color, roof: Color) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(0.05, -2.0 * l_half + 0.05, 0.0, hw, y, rise, wall, roof, true)
	_a = ka
	_b = kb


func _church_front(ch: Dictionary, style: Dictionary, g: float, eave: float, hw: float, trim: Color, wall: Color,
		roof: Color, brick: bool) -> void:
	_mode = M_STONE
	var pw := clampf(hw * 0.2, 1.1, 2.0)
	# Corner pilasters and a string course under the gable.
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * (hw - 0.62), 0.12, 0.4, 0.14, g + 1.05, g + eave, trim, M_STONE, trim)
	_lbox(0.0, 0.1, hw + 0.2, 0.18, g + eave - 0.6, g + eave + 0.2, trim, M_STONE, trim)
	# The portal: a dark door, a hood on two jambs, steps.
	_mode = M_GLASS
	_wall(_w(-pw, 0.08), _w(pw, 0.08), g + 1.2, g + 1.2 + pw * 2.6, _b, CHURCH_DARK)
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * (pw + 0.18), 0.2, 0.18, 0.2, g + 1.0, g + 1.2 + pw * 2.6, trim, M_STONE, trim)
	_lbox(0.0, 0.25, pw + 0.5, 0.3, g + 1.2 + pw * 2.6, g + 1.5 + pw * 2.6, trim, M_STONE, trim)
	for k in 3:
		_lbox(0.0, 0.9 + 0.5 * k, pw + 0.6 - 0.25 * k, 0.5 + 0.5 * (2 - k), g - 0.6, g + 0.1 + 0.4 * (2 - k), CHURCH_BASE, M_STONE,
				CHURCH_BASE.lightened(0.04))
	# A window (a rose in the gable for gothic and romanesque) over the portal.
	var wy := g + eave * 0.62
	if ch["style"] == "neogothic" or ch["style"] == "romanesque":
		var rose := _w(0.0, 0.1)
		_disc(Vector3(rose.x, g + eave + 1.6, rose.y), Vector3(_b.x, 0.0, _b.y), minf(hw * 0.28, 2.0), 12, CHURCH_DARK)
	_mode = M_GLASS
	_wall(_w(-0.6, 0.09), _w(0.6, 0.09), wy, wy + 3.0, _b, CHURCH_DARK)
	_mode = M_STONE


func _church_tower(tu: float, tv: float, ts: float, g: float, ht: float, ch: Dictionary, wall: Color, trim: Color,
		roof: Color, small := false) -> void:
	var none := Color(0, 0, 0, 0)
	var c := _w(tu, tv)
	_mode = M_STONE
	if not small:
		_lbox(tu, tv, ts + 0.2, ts + 0.2, g - 0.6, g + 1.2, CHURCH_BASE, M_STONE, CHURCH_BASE.lightened(0.05))
	var y0 := g + (1.2 if not small else ht - 2.0)
	_prism(_rect(tu, tv, ts, ts), y0, g + ht, wall, none, M_MONUMENT)
	_lbox(tu, tv, ts + 0.3, ts + 0.3, g + ht, g + ht + 0.7, trim, M_STONE, trim)
	# The belfry: a stage of dark louvres between corner piers, then its own cornice.
	var bh := maxf(ts * 1.5, 3.0)
	var by := g + ht + 0.7
	_lbox(tu, tv, ts - 0.2, ts - 0.2, by, by + bh, wall, M_STONE, wall)
	_mode = M_GLASS
	for sd: float in [-1.0, 1.0]:
		_wall(_w(tu - ts * 0.55, tv + sd * (ts - 0.18)), _w(tu + ts * 0.55, tv + sd * (ts - 0.18)), by + 0.6, by + bh - 0.5, _b * sd, CHURCH_DARK)
		_wall(_w(tu + sd * (ts - 0.18), tv - ts * 0.55), _w(tu + sd * (ts - 0.18), tv + ts * 0.55), by + 0.6, by + bh - 0.5, _a * sd, CHURCH_DARK)
	_mode = M_STONE
	_lbox(tu, tv, ts + 0.1, ts + 0.1, by + bh, by + bh + 0.5, trim, M_STONE, trim)
	var cy := by + bh + 0.5
	var cap: String = ch["cap"]
	if small:
		cap = "helm"
	var top := cy
	if CHURCH_CAPS.has(cap):
		var prof: Array = CHURCH_CAPS[cap]
		for k in prof.size() - 1:
			var da: Array = prof[k]
			var db: Array = prof[k + 1]
			var col := CHURCH_COPPER if cap != "onion" else CHURCH_GOLD
			col = col.lerp(col.lightened(0.12), float(k) / prof.size())
			_frustum(_circle(c, ts * float(da[0]), 8), cy + ts * float(da[1]), _circle(c, ts * float(db[0]), 8), cy + ts * float(db[1]), col)
		top = cy + ts * float((prof[prof.size() - 1] as Array)[1])
	elif cap == "spire":
		_frustum(_circle(c, ts * 0.95, 8), cy, _circle(c, 0.12, 8), cy + ts * 6.5, CHURCH_COPPER)
		top = cy + ts * 6.5
	else:  # pyramid (and the default): four steep faces
		_frustum(_rect(tu, tv, ts + 0.15, ts + 0.15), cy, _rect(tu, tv, 0.1, 0.1), cy + ts * 3.0, roof.darkened(0.1))
		top = cy + ts * 3.0
	_lbox(tu, tv, 0.12, 0.12, top, top + 3.0, CHURCH_GOLD, M_STONE, CHURCH_GOLD)
	_lbox(tu, tv, 0.55, 0.12, top + 1.7, top + 2.0, CHURCH_GOLD, M_STONE, CHURCH_GOLD)


## A Orthodox church's onion dome: a drum on the ridge's middle, a gold onion and a cross.
func _church_onion(g: float, y: float, l_half: float, ch: Dictionary) -> void:
	var c := _w(0.0, -l_half)
	var r := clampf(float(ch["W"]) * 0.32, 1.6, 3.0)
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_prism(_circle(c, r, 8), g + y - 0.7, g + y + r * 1.2, Color(ch["wall"]), none, M_MONUMENT)
	var prof: Array = CHURCH_CAPS["onion"]
	var base := g + y + r * 1.2
	for k in prof.size() - 1:
		var da: Array = prof[k]
		var db: Array = prof[k + 1]
		_frustum(_circle(c, r * float(da[0]), 8), base + r * float(da[1]), _circle(c, r * float(db[0]), 8), base + r * float(db[1]), CHURCH_GOLD.lerp(CHURCH_GOLD.lightened(0.15), float(k) / prof.size()))
	var top := base + r * float((prof[prof.size() - 1] as Array)[1])
	_lbox(0.0, -l_half, 0.1, 0.1, top, top + 2.6, CHURCH_GOLD, M_STONE, CHURCH_GOLD)
	_lbox(0.0, -l_half, 0.5, 0.1, top + 1.5, top + 1.75, CHURCH_GOLD, M_STONE, CHURCH_GOLD)


# --- Praga: St Florian's cathedral and Bazar Różyckiego (2026-11-02, photo reports) ----------

## St Florian's cathedral (Katedra św. Michała Archanioła i św. Floriana, Józef Pius Dziekoński,
## 1888-1904, rebuilt 1947-72): the neo-Gothic red-brick basilica whose two 75 m spires are
## Praga's mark across the river. Built from the Mac's photo report (docs/landmarks/photo-reports/
## st_florian.md: 3 Commons photos and the GUGiK orthophoto) on the mapped outline. Spec
## docs/landmarks/specs/florian.md. Frame: origin at the front's middle between the towers'
## outlines, u across the front, +v out of it (west-north-west, to Plac Weteranów 1863 roku and
## Al. Solidarności); the body runs back to the apse at v -68.6. Ground from the outline.
const FL_O := Vector2(434.89, -1980.8)
const FL_A := Vector2(-0.5232, 0.8522)
const FL_OSM := "Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana Męczennika"
const FL_BRICK := Color("#a4472e")
const FL_BRICK_DARK := Color("#8e3c28")
const FL_TRIM := Color("#e9e3d3")
const FL_BASE := Color("#a8a08e")
const FL_SLATE := Color("#4a524f")
const FL_COPPER := Color("#5e8e76")
const FL_DARK := Color("#2e3236")
const FL_GOLD := Color("#c9a24a")
const FL_STAINED := Color("#6a4a2a")
const FL_LAMP := Color("#ffd29a")    # the warm floodlamps on the paving (photo 5)
const FL_CYAN := Color("#9fe4ff")    # the spires' cool light (photo 5)
const FL_WHITE := Color("#eceae4")   # St Michael on the forecourt
const FL_TOWER_U := 10.95            # the towers' centres (OSM outlines 6.8 x 8.6 m)
const FL_TOWER_HU := 3.4
const FL_TOWER_HV := 4.3
const FL_FRONT := 4.0                # the front wall between the towers
const FL_NAVE_HU := 7.4              # the clerestory's half width
const FL_AISLE := 13.0               # the aisles' eave
const FL_EAVE := 24.0                # the nave's eave
const FL_RIDGE := 35.0               # the nave's ridge (OSM height)
const FL_SHAFT := 33.0               # the towers' brick shafts
const FL_BELFRY := 42.0              # the white-trimmed belfry's top
const FL_SPIRE := 71.0               # the copper spires' tips
const FL_CROSS := 75.0               # the gilt crosses' tops (OSM height, report "~75 m")
const FL_CROSSING := -37.0           # the transept's middle (v), the flèche over it
const FL_TRANSEPT := Vector2(-43.0, -31.0)
const FL_APSE := [[7.4, -60.6], [6.6, -64.4], [3.9, -67.6], [0.0, -68.6], [-3.9, -67.6], [-6.6, -64.4], [-7.4, -60.6]]
const FL_MICHAEL_V := 12.0           # the statue on the forecourt, on the axis (spot: QUESTIONS)
## Floodlamps in the paving, [u, v]: the front, the towers' outer faces, the transept's ends.
const FL_FLOODS := [[-4.5, 6.0], [4.5, 6.0], [-10.9, 6.2], [10.9, 6.2], [-15.6, 0.0], [15.6, 0.0],
		[-21.0, -37.0], [21.0, -37.0]]


func _find_florian() -> void:
	var outline := _landmark(FL_OSM)
	if outline.size() >= 3:
		_add_site("florian", [outline])


func _build_florian(site: Dictionary) -> void:
	_o = FL_O
	_a = FL_A.normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front
	var outline: PackedVector2Array = _simplify((site["zone"] as Array)[0], 0.6)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var plinth := _largest(Geometry2D.offset_polygon(outline, 0.3, Geometry2D.JOIN_MITER))
	_prism(plinth, g - 0.6, g + 1.2, FL_BASE, FL_BASE.lightened(0.05), M_STONE, M_STONE)
	# body: the clerestory from the front to the apse, the aisles, the transept, the apse
	var back := -60.6
	_prism(_rect(0.0, (FL_FRONT + back) * 0.5, FL_NAVE_HU, (FL_FRONT - back) * 0.5), g + 1.2, g + FL_EAVE, FL_BRICK, none, M_GOTHIC)
	for sd: float in [-1.0, 1.0]:
		_prism(_rect(sd * 10.75, -17.65, 3.35, 13.35), g + 1.2, g + FL_AISLE, FL_BRICK, none, M_GOTHIC)
		_prism(_rect(sd * 13.0, -51.8, 5.6, 8.8), g + 1.2, g + FL_AISLE, FL_BRICK, none, M_GOTHIC)
	var tc := (FL_TRANSEPT.x + FL_TRANSEPT.y) * 0.5
	var th := (FL_TRANSEPT.y - FL_TRANSEPT.x) * 0.5
	_prism(_rect(0.0, tc, 19.2, th), g + 1.2, g + FL_EAVE, FL_BRICK, none, M_GOTHIC)
	var apse := PackedVector2Array()
	for p: Array in FL_APSE:
		apse.append(_w(p[0], p[1]))
	_prism(apse, g + 1.2, g + FL_EAVE, FL_BRICK, none, M_GOTHIC)
	# cornices in white stone at the eaves
	_prism(_rect(0.0, (FL_FRONT + back) * 0.5 - 0.1, FL_NAVE_HU + 0.25, (FL_FRONT - back) * 0.5 + 0.15), g + FL_EAVE - 0.7,
			g + FL_EAVE, FL_TRIM, none, M_STONE)
	_prism(_rect(0.0, tc, 19.45, th + 0.2), g + FL_EAVE - 0.68, g + FL_EAVE - 0.02, FL_TRIM, none, M_STONE)
	# roofs: the nave's long gable, the transept's cross gable, the apse's half cone, the aisles' lean-tos
	_fl_nave_roof(back, g)
	_gable(19.2, -19.2, tc, th, g + FL_EAVE, FL_RIDGE - FL_EAVE, FL_BRICK, FL_SLATE.lightened(0.04))
	var apex := Vector3(_w(0.0, back).x, g + FL_RIDGE, _w(0.0, back).y)
	for i in apse.size() - 1:
		var p0 := Vector3(apse[i].x, g + FL_EAVE, apse[i].y)
		var p1 := Vector3(apse[i + 1].x, g + FL_EAVE, apse[i + 1].y)
		var n := (p1 - p0).cross(apex - p0).normalized()
		var mid := (apse[i] + apse[i + 1]) * 0.5
		if Vector2(n.x, n.z).dot(mid - _w(0.0, back)) < 0.0:
			n = -n
		_tri(p0, p1, apex, n, FL_SLATE, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	for sd: float in [-1.0, 1.0]:
		_fl_lean(sd * 14.1, sd * FL_NAVE_HU, -30.95, -4.3, g)
		_fl_lean(sd * 18.6, sd * FL_NAVE_HU, back, FL_TRANSEPT.x, g, true)
	# buttresses with stone pinnacles along the aisles
	for sd: float in [-1.0, 1.0]:
		for v: float in [-9.6, -15.0, -20.4, -25.8]:
			_lbox(sd * 14.45, v, 0.35, 0.45, g + 1.2, g + FL_AISLE - 1.5, FL_BRICK_DARK, M_STONE, FL_TRIM)
			_pinnacle(sd * 14.45, v, 0.7, g + FL_AISLE - 1.5, 3.4, FL_TRIM)
		for v: float in [-46.5, -52.0, -57.5]:
			_lbox(sd * 18.95, v, 0.35, 0.45, g + 1.2, g + FL_AISLE - 1.5, FL_BRICK_DARK, M_STONE, FL_TRIM)
			_pinnacle(sd * 18.95, v, 0.7, g + FL_AISLE - 1.5, 3.4, FL_TRIM)
	# the small turrets at the transept's corners (photo 6)
	for sd: float in [-1.0, 1.0]:
		for v: float in [FL_TRANSEPT.x, FL_TRANSEPT.y]:
			var c := _w(sd * 19.4, v + (0.2 if v > tc else -0.2))
			_prism(_circle(c, 1.0, 8), g + 1.2, g + FL_EAVE + 2.0, FL_BRICK, none, M_STONE)
			_prism(_circle(c, 1.2, 8), g + FL_EAVE + 2.0, g + FL_EAVE + 2.5, FL_TRIM, none, M_STONE)
			_frustum(_circle(c, 1.15, 8), g + FL_EAVE + 2.5, _circle(c, 0.08, 8), g + FL_EAVE + 7.0, FL_SLATE)
	# the flèche over the crossing
	var fc := _w(0.0, FL_CROSSING)
	_prism(_circle(fc, 1.3, 8), g + FL_RIDGE - 2.5, g + FL_RIDGE + 3.0, FL_COPPER.darkened(0.1), none, M_STONE)
	_frustum(_circle(fc, 1.5, 8), g + FL_RIDGE + 3.0, _circle(fc, 0.08, 8), g + FL_RIDGE + 14.0, FL_COPPER)
	_lbox(0.0, FL_CROSSING, 0.1, 0.1, g + FL_RIDGE + 14.0, g + FL_RIDGE + 16.2, FL_GOLD, M_STONE, FL_GOLD)
	_lbox(0.0, FL_CROSSING, 0.45, 0.1, g + FL_RIDGE + 15.2, g + FL_RIDGE + 15.45, FL_GOLD, M_STONE, FL_GOLD)
	_fl_front(g)
	for sd: float in [-1.0, 1.0]:
		_fl_tower(sd * FL_TOWER_U, sd, g)
	_fl_michael(g)
	# night: the floodlamps on the paving and the rose's stained glass
	_mode = M_LAMP
	for f: Array in FL_FLOODS:
		_lbox(f[0], f[1], 0.3, 0.3, g - 0.1, g + 0.3, FL_LAMP, M_LAMP, FL_LAMP)
	var rose := _w(0.0, FL_FRONT + 0.16)
	_disc(Vector3(rose.x, g + 17.5, rose.y), Vector3(_b.x, 0.0, _b.y), 2.4, 12, FL_STAINED)
	_mode = M_STONE
	_collide(outline)
	_collide(_rect(0.0, FL_MICHAEL_V, 1.0, 1.0))


## The nave's gable along v from the front to the apse (in the swapped frame `_gable` expects).
func _fl_nave_roof(back: float, g: float) -> void:
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(FL_FRONT, back, 0.0, FL_NAVE_HU + 0.2, g + FL_EAVE, FL_RIDGE - FL_EAVE, FL_BRICK, FL_SLATE, false)
	_a = ka
	_b = kb


## An aisle's lean-to roof from its eave at u_out (FL_AISLE) up to the clerestory at u_in, from
## v0 to v1; `end` closes the v0 end with a brick triangle (the choir's open end).
func _fl_lean(u_out: float, u_in: float, v0: float, v1: float, g: float, end := false) -> void:
	var y0 := g + FL_AISLE
	var y1 := g + FL_AISLE + 5.0
	var po := _w(u_out, v0)
	var pi := _w(u_in, v0)
	var qo := _w(u_out, v1)
	var qi := _w(u_in, v1)
	var a := Vector3(po.x, y0, po.y)
	var b := Vector3(qo.x, y0, qo.y)
	var c := Vector3(qi.x, y1, qi.y)
	var d := Vector3(pi.x, y1, pi.y)
	var side := _a * signf(u_out)
	var n := (Vector3(side.x, 0.0, side.y) * 5.0 + Vector3.UP * absf(u_out - u_in)).normalized()
	_mode = M_STONE
	_quad(a, b, c, d, n, FL_SLATE.lightened(0.06))
	if end:
		var e := Vector3(pi.x, y0, pi.y)
		_tri(a, e, d, Vector3(-_b.x, 0.0, -_b.y), FL_BRICK, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A pointed (lancet) opening on a plane: from u0 to u1 along `along` at the plane point `at`
## (the opening's middle at the sill), facing `out`, from y0 to the springing y1 and a point
## `peak` metres above it.
func _fl_lancet(at: Vector2, along: Vector2, hw: float, y0: float, y1: float, peak: float, out: Vector2, col: Color) -> void:
	var l := at - along * hw
	var r := at + along * hw
	var n := Vector3(out.x, 0.0, out.y)
	_quad(Vector3(l.x, y0, l.y), Vector3(r.x, y0, r.y), Vector3(r.x, y1, r.y), Vector3(l.x, y1, l.y), n, col)
	_tri(Vector3(l.x, y1, l.y), Vector3(r.x, y1, r.y), Vector3(at.x, y1 + peak, at.y), n, col,
			Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The front between the towers: the porch with the pointed main portal under a stone gable,
## the string course, the rose window in a stone ring, a row of five lancets under the gable,
## and pinnacles at the gable's foot (photo 4).
func _fl_front(g: float) -> void:
	var out := _b
	# the porch: brick, a stone plinth, the pointed portal, a stone wimperg (gable) over it
	_lbox(0.0, FL_FRONT + 0.6, 3.2, 0.6, g + 1.2, g + 9.5, FL_BRICK, M_STONE, FL_TRIM)
	_lbox(0.0, FL_FRONT + 0.65, 3.4, 0.65, g - 0.6, g + 1.2, FL_BASE, M_STONE, FL_BASE.lightened(0.05))
	_mode = M_STONE
	_fl_lancet(_w(0.0, FL_FRONT + 1.23), _a, 2.3, g + 1.2, g + 6.4, 2.6, out, FL_TRIM)
	_mode = M_GLASS
	_fl_lancet(_w(0.0, FL_FRONT + 1.27), _a, 1.8, g + 1.2, g + 6.2, 2.1, out, FL_DARK)
	_mode = M_STONE
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(FL_FRONT + 1.2, FL_FRONT, 0.0, 3.2, g + 9.5, 4.2, FL_TRIM, FL_TRIM, false)
	_a = ka
	_b = kb
	_pinnacle(-3.0, FL_FRONT + 0.6, 0.6, g + 9.5, 3.4, FL_TRIM)
	_pinnacle(3.0, FL_FRONT + 0.6, 0.6, g + 9.5, 3.4, FL_TRIM)
	for k in 3:  # steps up to the portal
		_lbox(0.0, FL_FRONT + 1.6 + 0.5 * k, 3.6 - 0.3 * k, 0.5 + 0.5 * (2 - k), g - 0.6, g + 0.1 + 0.35 * (2 - k), FL_BASE,
				M_STONE, FL_BASE.lightened(0.04))
	# the string courses and the rose
	_lbox(0.0, FL_FRONT + 0.12, FL_NAVE_HU, 0.14, g + 12.4, g + 13.0, FL_TRIM, M_STONE, FL_TRIM)
	var rose := _w(0.0, FL_FRONT + 0.06)
	_disc(Vector3(rose.x, g + 17.5, rose.y), Vector3(out.x, 0.0, out.y), 3.4, 16, FL_TRIM)
	var dark := _w(0.0, FL_FRONT + 0.11)
	_mode = M_GLASS
	_disc(Vector3(dark.x, g + 17.5, dark.y), Vector3(out.x, 0.0, out.y), 2.9, 16, FL_DARK)
	# five lancets in a row in the gable, rising to the middle
	for k in 5:
		var u := -4.4 + 2.2 * k
		var top := 26.4 + (2 - absi(k - 2)) * 0.9
		_fl_lancet(_w(u, FL_FRONT + 0.05), _a, 0.55, g + 24.6, g + top, 0.9, out, FL_DARK)
	_mode = M_STONE
	# pinnacles at the gable's foot and a cross on its apex
	for sd: float in [-1.0, 1.0]:
		_pinnacle(sd * (FL_NAVE_HU - 0.2), FL_FRONT - 0.2, 1.0, g + FL_EAVE, 5.0, FL_TRIM)
	_lbox(0.0, FL_FRONT - 0.4, 0.12, 0.12, g + FL_RIDGE - 0.4, g + FL_RIDGE + 2.8, FL_TRIM, M_STONE, FL_TRIM)
	_lbox(0.0, FL_FRONT - 0.4, 0.6, 0.12, g + FL_RIDGE + 1.6, g + FL_RIDGE + 1.9, FL_TRIM, M_STONE, FL_TRIM)


## A tower at u `tu` (`sd` the side, -1 or +1): the brick shaft with corner buttresses, a side
## portal and a tall lancet, the white-trimmed belfry with twin lancets on each face, four
## gables and four corner pinnacles round the foot of the octagonal copper spire with its
## lucarnes, a gilt ball and cross (photos 4 and 6).
func _fl_tower(tu: float, sd: float, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var hu := FL_TOWER_HU
	var hv := FL_TOWER_HV
	var c := _w(tu, 0.0)
	_lbox(tu, 0.0, hu + 0.3, hv + 0.3, g - 0.6, g + 1.2, FL_BASE, M_STONE, FL_BASE.lightened(0.05))
	_prism(_rect(tu, 0.0, hu, hv), g + 1.2, g + FL_SHAFT, FL_BRICK, none, M_GOTHIC)
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			if cv < 0.0 and cu * sd < 0.0:
				continue  # the inner back corner stands in the nave
			var bu := tu + cu * (hu + 0.1)
			var bv := cv * (hv + 0.1)
			_lbox(bu, bv, 0.5, 0.5, g + 1.2, g + FL_SHAFT - 4.0, FL_BRICK_DARK, M_STONE, FL_TRIM)
			_pinnacle(bu, bv, 0.9, g + FL_SHAFT - 4.0, 4.6, FL_TRIM)
	for y: float in [12.4, 24.0]:
		_lbox(tu, 0.0, hu + 0.15, hv + 0.15, g + y, g + y + 0.6, FL_TRIM, M_STONE, FL_TRIM)
	# the side portal and the tall lancets on the front and the outer face
	var front := _b
	var side := _a * sd
	_mode = M_GLASS
	_fl_lancet(_w(tu, hv + 0.04), _a, 1.2, g + 1.2, g + 5.6, 1.4, front, FL_DARK)
	_fl_lancet(_w(tu, hv + 0.04), _a, 0.8, g + 14.5, g + 21.0, 1.2, front, FL_DARK)
	_fl_lancet(_w(tu + sd * (hu + 0.04), 0.0), _b, 0.8, g + 14.5, g + 21.0, 1.2, side, FL_DARK)
	_mode = M_STONE
	# the belfry: a white band, brick between trim, twin lancets on each face, a parapet
	_lbox(tu, 0.0, hu + 0.25, hv + 0.25, g + FL_SHAFT - 0.4, g + FL_SHAFT + 0.4, FL_TRIM, M_STONE, FL_TRIM)
	_prism(_rect(tu, 0.0, hu, hv), g + FL_SHAFT + 0.4, g + FL_BELFRY, FL_BRICK, none, M_STONE)
	for f in 4:
		var nrm: Vector2 = [_b, -_b, _a, -_a][f]
		var along: Vector2 = [_a, _a, _b, _b][f]
		var reach := hv if f < 2 else hu
		var span := hu if f < 2 else hv
		var mid := c + nrm * (reach + 0.04)
		_fl_lancet(mid, along, span - 0.4, g + FL_SHAFT + 1.0, g + FL_BELFRY - 2.6, 1.8, nrm, FL_TRIM)
		_mode = M_GLASS
		for s2: float in [-1.0, 1.0]:
			_fl_lancet(mid + nrm * 0.03 + along * s2 * span * 0.38, along, span * 0.26, g + FL_SHAFT + 1.4, g + FL_BELFRY - 3.0,
					1.2, nrm, FL_DARK)
		_mode = M_STONE
	_lbox(tu, 0.0, hu + 0.3, hv + 0.3, g + FL_BELFRY, g + FL_BELFRY + 0.8, FL_TRIM, M_STONE, FL_TRIM)
	var y := g + FL_BELFRY + 0.8
	# four gables round the spire's foot, then the corner pinnacles
	_gable(tu + hu, tu - hu, 0.0, hv - 0.4, y, 4.2, FL_BRICK, FL_SLATE)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(hv, -hv, tu, hu - 0.4, y, 4.2, FL_BRICK, FL_SLATE)
	_a = ka
	_b = kb
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_pinnacle(tu + cu * (hu - 0.05), cv * (hv - 0.05), 1.0, y, 6.4, FL_TRIM)
	# the octagonal copper spire, four lucarnes on it, the gilt ball and the cross
	var r0 := minf(hu, hv) * 0.95
	var sy := g + FL_SPIRE
	_frustum(_circle(c, r0, 8), y, _circle(c, 0.12, 8), sy, FL_COPPER)
	var ly := y + 8.0
	var lr := r0 * (1.0 - (ly - y) / (sy - y)) + 0.1
	for f in 4:
		var d: Vector2 = [_b, -_b, _a, -_a][f]
		var lc := _local(c + d * lr)
		_lbox(lc.x, lc.y, 0.42, 0.42, ly, ly + 1.5, FL_COPPER.darkened(0.12), M_STONE, FL_COPPER)
		_pyramid(_rect(lc.x, lc.y, 0.5, 0.5), ly + 1.5, ly + 2.5, FL_COPPER.lightened(0.06))
	_prism(_circle(c, 0.38, 6), sy - 0.3, sy + 0.45, FL_GOLD, FL_GOLD, M_STONE, M_STONE)
	_lbox(tu, 0.0, 0.12, 0.12, sy + 0.45, g + FL_CROSS, FL_GOLD, M_STONE, FL_GOLD)
	_lbox(tu, 0.0, 0.7, 0.12, g + FL_CROSS - 1.6, g + FL_CROSS - 1.3, FL_GOLD, M_STONE, FL_GOLD)
	# night: the spire's cool light from the belfry's parapet corners
	_mode = M_LAMP
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_lbox(tu + cu * (hu - 0.6), cv * (hv - 0.6), 0.16, 0.16, y, y + 0.35, FL_CYAN, M_LAMP, FL_CYAN)
	_mode = M_STONE
	_collide(_rect(tu, 0.0, hu + 0.3, hv + 0.3))


## St Michael on the forecourt (photo 5): a white figure with spread wings and a raised spear on a
## stone pedestal, on the axis before the porch (the spot is parked in QUESTIONS).
func _fl_michael(g: float) -> void:
	var v := FL_MICHAEL_V
	var none := Color(0, 0, 0, 0)
	_lbox(0.0, v, 0.95, 0.95, g - 0.4, g + 0.5, FL_BASE, M_STONE, FL_BASE.lightened(0.05))
	_lbox(0.0, v, 0.7, 0.7, g + 0.5, g + 2.6, FL_TRIM, M_STONE, FL_TRIM)
	var c := _w(0.0, v)
	_frustum(_circle(c, 0.45, 6), g + 2.6, _circle(c, 0.3, 6), g + 4.3, FL_WHITE, none)
	_prism(_circle(c, 0.2, 6), g + 4.3, g + 4.75, FL_WHITE, FL_WHITE, M_STONE, M_STONE)
	for sd: float in [-1.0, 1.0]:  # the wings, raised behind the shoulders
		_lbox(sd * 0.5, v - 0.25, 0.32, 0.06, g + 3.5, g + 5.2, FL_WHITE, M_STONE, FL_WHITE)
	_lbox(0.42, v + 0.15, 0.05, 0.05, g + 3.2, g + 5.9, FL_WHITE.darkened(0.25), M_STONE, FL_WHITE)  # the spear
