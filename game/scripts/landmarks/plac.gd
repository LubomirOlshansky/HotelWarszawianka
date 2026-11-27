extends "res://scripts/landmarks/muranow.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Plac Piłsudskiego and Plac
## Małachowskiego: Muzeum Narodowe's model, Hotel Europejski, the Tomb, the Metropolitan, Zachęta,
## the Presidential Palace. Moved as it was from the one big file. landmarks.gd is the class the
## game makes; every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd,
## common.gd, then the areas in the order of landmarks.gd's `extends` chain), so code here may use
## this file, common.gd and the facade kit, never another area: a helper two areas need goes to
## common.gd.


# --- Muzeum Narodowe (the landmarks loop; a real model since the museum and Plac loop) ----------

## The museum's building (1927-1938) at the east end of Al. Jerozolimskie, mapped as one
## outline round the courtyards (with the army museum in its wings). The landmarks loop kept the
## LoD2 or OpenStreetMap model in its stone (`skin_at`); the museum and Plac Piłsudskiego loop
## (2026-10-31) builds it (`_build_muzeum`): the outline straightened (`_simplify`), and its
## courtyards (the hull's pieces outside it, over MUZEUM_COURT m²) join the zone, since the LoD2
## model's centre falls in one.
const MUZEUM := Vector2(24.0, 251.0)  # inside its wings (its outline's centre is a courtyard)
const MUZEUM_STONE := Color("#cdbfa1")  # photos 1-4: warm sandstone, a little yellower than before
const MUZEUM_ROOF := Color("#8f8b84")
const MUZEUM_COPPER := Color("#8fae9f")   # the entrance block's pale green copper roof (photo 4)
const MUZEUM_DOORS := Color("#25262a")
const MUZEUM_IRON := Color("#1d1e21")     # the forecourt fence and gate (photos 1, 3, 4)
const MUZEUM_POLE := Color("#e8e8e4")
const MUZEUM_BANNER := Color("#3a4496")   # the museum's blue banners (own design; no sponsor logos)
const MUZEUM_COURT := 1000.0
func _find_muzeum() -> void:
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 20 or float(bld["h"]) < 10.0 or not _box_of([q]).has_point(MUZEUM):
			continue
		if Geometry2D.is_point_in_polygon(MUZEUM, q):
			var ring := _simplify(q, 1.0)
			var zone: Array = [q]
			var courts: Array[PackedVector2Array] = []
			for piece in Geometry2D.clip_polygons(Geometry2D.convex_hull(ring), ring):
				if absf(_area(piece)) > MUZEUM_COURT:
					courts.append(piece)
					zone.append(piece)
			_add_site("muzeum", zone)
			if not sites.is_empty() and sites[-1]["key"] == "muzeum":
				sites[-1]["ring"] = ring
				sites[-1]["h"] = maxf(float(bld["h"]), MUZEUM_WINGS)
				sites[-1]["courts"] = courts
			return


# --- Muzeum Narodowe and Plac Piłsudskiego (the museum and Plac loop, 2026-10-31) ----------------

## The museum's raised entrance block stands at the back of its forecourt (Dziedziniec im.
## Stanisława Lorentza, the courtyard open to Al. Jerozolimskie): the middle of that wall and the
## building's own axis along the avenue (east); its back is MUZEUM_AXIS turned a quarter (south).
const MUZEUM_DOOR := Vector2(-2.95, 276.7)
const MUZEUM_AXIS := Vector2(0.964, -0.267)
## The army museum's tank and field gun: on the east courtyard's lawn between its pool and the
## east block (map areas), lined up with that wall.
const MUZEUM_TANK := Vector2(53.8, 211.0)
const MUZEUM_GUN := Vector2(56.5, 233.0)
const MUZEUM_YARD_DIR := Vector2(-0.276, -0.961)
## Plac part 2: the heights are estimates (OpenStreetMap tags the wings building:levels=4,
## which the bake turns into 14.2 m at 3.3 m a storey; the museum's galleries are taller storeys).
const MUZEUM_TOP := 25.0           # the entrance block's parapet (estimate; was 20 m)
const MUZEUM_WINGS := 18.5         # the wings' parapet (estimate: four storeys of about 4.4 m)
const MUZEUM_PLINTH := Color("#a99f8b")
const MUZEUM_GLASS := Color("#3b424b")
const ARMY_OLIVE := Color("#5a6141")
const ARMY_TRACK := Color("#2f302b")
const ARMY_PAD := Color("#9a968d")


## Muzeum Narodowe: Tadeusz Tołwiński's stripped-classical block in pale stone. The mapped
## outline straightened, on a darker plinth, to its wings' height (MUZEUM_WINGS) with a parapet; tall narrow
## window bays in a steady rhythm on every front; at the back of the forecourt the raised
## entrance block (MUZEUM_TOP) with its recessed glazed portal behind four square piers under a
## lintel, two tall bays either side, and steps; on the east courtyard's lawn the army museum's
## hardware: a tank and a field gun on concrete pads.
func _build_muzeum(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var h: float = site["h"]
	var light := MUZEUM_STONE.lightened(0.07)
	var base := Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER)
	if not base.is_empty():
		_prism(base[0], g - 0.6, g + 1.3, MUZEUM_PLINTH, MUZEUM_PLINTH, M_STONE, M_STONE)
	_prism(ring, g - 0.6, g + h, MUZEUM_STONE, MUZEUM_ROOF, M_STONE, M_STONE)
	_parapet(ring, g + h, 1.0, light)
	# The entrance block, in the forecourt's frame (u east along the avenue, v to the back).
	_o = MUZEUM_DOOR
	_a = MUZEUM_AXIS
	_b = Vector2(-_a.y, _a.x)
	var block := _rect(0.0, 7.0, 12.0, 9.5)
	_bays(ring, 2.0, h - 2.2, 4.4, 1.3, MUZEUM_GLASS, _rect(0.0, 7.0, 12.5, 10.0))
	_muzeum_piers(ring, g + 1.3, g + h, 4.4, light, _rect(0.0, 7.0, 12.5, 10.0))
	_prism(block, g - 0.6, g + MUZEUM_TOP, MUZEUM_STONE, MUZEUM_COPPER, M_STONE, M_STONE)
	_parapet(block, g + MUZEUM_TOP, 1.0, light)
	var front := -_b
	_mode = M_GLASS
	_wall(_w(-6.5, -2.56), _w(6.5, -2.56), g, g + 12.5, front, MUZEUM_GLASS)
	for u in [-9.6, 9.6]:
		_wall(_w(u - 0.65, -2.56), _w(u + 0.65, -2.56), g + 2.0, g + MUZEUM_TOP - 2.5, front, MUZEUM_GLASS, 0.1)
	for u in [-4.875, -1.625, 1.625, 4.875]:
		_lbox(u, -3.5, 0.55, 0.55, g, g + 12.5, light, M_STONE, light)
	_lbox(0.0, -3.4, 7.0, 0.95, g + 12.5, g + 13.6, light, M_STONE, light)
	_lbox(0.0, -6.0, 8.5, 3.5, g - 0.6, g + 0.4, MUZEUM_PLINTH, M_STONE, MUZEUM_PLINTH)
	_lbox(0.0, -7.1, 9.5, 1.3, g - 0.6, g + 0.15, MUZEUM_PLINTH, M_STONE, MUZEUM_PLINTH)
	_lbox(0.0, -8.3, 10.5, 1.2, g - 0.6, g - 0.05, MUZEUM_PLINTH, M_STONE, MUZEUM_PLINTH)
	_muzeum_doors(g)
	_muzeum_forecourt(g)
	_collide(ring)
	_collide(_rect(0.0, -2.5, 7.0, 1.6))
	_muzeum_sign(ring, g + h + 1.0)
	# The army museum's hardware on the lawn of the east courtyard, beside its pool, noses north.
	_tank(MUZEUM_TANK, MUZEUM_YARD_DIR)
	_field_gun(MUZEUM_GUN, MUZEUM_YARD_DIR.rotated(-0.5))


## The museum's lit roof sign (F's night photo from Rondo de Gaulle'a, 2026-11-26; Street View and
## the 3D Tiles render agree): built white letters on the west wing's roof, set back from its
## parapet over the north end of the front that faces the rondo, so they read from the Palm down
## Al. Jerozolimskie: the wave mark (the museum's logo kept as a plain stylised zigzag wave, not
## the real mark) and MUZEUM NARODOWE in serif capitals (the institution's own name, like
## Filharmonia Narodowa's). White by day, glowing at night (M_LAMP), on a dark steel rail and posts.
const MUZEUM_SIGN_FROM := Vector2(-213.9, 238.5)  # the Palm: the sign faces it
const MUZEUM_SIGN_CAP := 1.65      # the letters' cap height (photo: a third of a window bay's pitch)
const MUZEUM_SIGN_START := 7.0     # from the front's north corner to the wave's left edge
const MUZEUM_SIGN_BACK := 1.4      # behind the parapet's face
const MUZEUM_SIGN_LIFT := 0.45     # the letters' foot over the parapet's top
const MUZEUM_SIGN_WHITE := Color("#f4f6f8")
const MUZEUM_SIGN_STEEL := Color("#2c2e31")


func _muzeum_sign(ring: PackedVector2Array, top: float) -> void:
	# The longest straight front facing the Palm.
	var best := -1.0
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var out := Vector2.ZERO
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		var o := _out(ring, p, q)
		var facing := o.dot((MUZEUM_SIGN_FROM - (p + q) * 0.5).normalized())
		var score := p.distance_to(q) * facing
		if facing > 0.5 and score > best:
			best = score
			a = p
			b = q
			out = o
	if best < 30.0:
		return
	# Read left to right from outside: start at the end that is on the left seen from the Palm.
	var right := Vector2(out.y, -out.x)  # the viewer's right, facing -out
	if (b - a).dot(right) < 0.0:
		var t := a
		a = b
		b = t
	right = (b - a).normalized()
	var r3 := Vector3(right.x, 0.0, right.y)
	var h := MUZEUM_SIGN_CAP
	var foot := top + MUZEUM_SIGN_LIFT
	var base := a + right * MUZEUM_SIGN_START - out * MUZEUM_SIGN_BACK
	var o3 := Vector3(base.x, foot, base.y)
	# The wave: a zigzag of four peaks drawn twice, one line inside the other (an outline, as the
	# real mark is), 1.7 caps high and 2.6 wide.
	var wave_w := 2.6 * h
	var wave_h := 1.7 * h
	# Each stroke a little deeper than the last (their front faces must not share a plane).
	var depth := Vector3(out.x, 0.0, out.y) * -0.035
	for inset: float in [0.0, 0.17]:
		var prev := Vector3.ZERO
		for k in 9:
			var x := inset * h + float(k) / 8.0 * (wave_w - 2.0 * inset * h)
			var y := (wave_h - inset * h) if k % 2 == 0 else inset * h
			var pt := o3 + r3 * x + Vector3.UP * (y - 0.05 * h)
			if k > 0:
				var nudge := depth * float(k % 2) + depth * (2.0 if inset > 0.0 else 0.0)
				_beam(prev + nudge, pt + nudge, h * 0.09, MUZEUM_SIGN_WHITE, false, M_LAMP)
			prev = pt
	var word_at := o3 + r3 * (wave_w + 0.9 * h) + Vector3.UP * 0.2 * h
	var length := wave_w + 0.9 * h + _serif_word("MUZEUM NARODOWE", word_at, r3, h, MUZEUM_SIGN_WHITE)
	# The steel: a rail under the letters and one behind them, on posts every 3 m down to the roof.
	var back := -out * 0.35
	for y: float in [foot - 0.1, foot + 0.9 * h]:
		var p0 := base + back
		var p1 := base + back + right * length
		_beam(Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), 0.12, MUZEUM_SIGN_STEEL, false)
	var n := ceili(length / 3.0)
	for k in n + 1:
		var p := base + back + right * length * float(k) / n
		# Thinner than the rails, so no post face lies in a rail's face (z-fighting).
		_beam(Vector3(p.x, top - 1.0, p.y), Vector3(p.x, foot + 0.9 * h + 0.06, p.y), 0.09, MUZEUM_SIGN_STEEL, false)


## The wings' stone piers (photos 1-4 of refs/muzeum_narodowe: tall square pilasters between the
## window strips, every second storey-strip, under a deep cornice): one on every bay boundary of
## each straight run, 1 m wide and 0.5 m proud, from `y0` to `y1`; none where `skip` (the block in
## front of that wall) covers the foot. Same rhythm as `_bays`, so each strip sits between two.
func _muzeum_piers(ring: PackedVector2Array, y0: float, y1: float, step: float, col: Color,
		skip: PackedVector2Array) -> void:
	var keep := _mode
	_mode = M_STONE
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var n := floori((length - 1.5) / step)
		if n < 1:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var t0 := (length - n * step) * 0.5
		for k in n + 1:
			var c := a + e * (t0 + k * step)
			if skip.size() >= 3 and Geometry2D.is_point_in_polygon(c + out * 0.3, skip):
				continue
			var q := PackedVector2Array([c - e * 0.5 - out * 0.1, c + e * 0.5 - out * 0.1,
					c + e * 0.5 + out * 0.5, c - e * 0.5 + out * 0.5])
			_prism(q, y0, y1 - 0.5, col, col.lightened(0.05), M_STONE, M_STONE)
	_mode = keep


## The entrance's three dark doors in the recessed wall behind the piers (photo 3: three tall black
## doors, the middle one under the banner strip), local frame already set to the block's.
func _muzeum_doors(g: float) -> void:
	for u in [-3.25, 0.0, 3.25]:
		_wall(_w(u - 1.1, -2.58), _w(u + 1.1, -2.58), g + 0.4, g + 5.2, -_b, MUZEUM_DOORS)


## The forecourt (photos 1, 3, 4): the black spear-topped iron fence across its mouth with the gate
## standing open in the middle, six flagpoles with blue banners in front of the steps, and the
## fountain pool in the court. In the block's frame the mouth is v = -62.7, between the wings
## (u -22 .. 24.7); the court is a pedestrian forecourt, the fence closes it to cars but for the gate.
func _muzeum_forecourt(g: float) -> void:
	var vf := -62.7
	var u0 := -22.0
	var u1 := 24.7
	var gate := 3.6
	var u := u0
	var fence := MUZEUM_IRON
	var keep := _mode
	while u <= u1 + 0.01:
		if absf(u - 1.35) > gate:
			var gy: float = map.terrain_height(_w(u, vf).x, _w(u, vf).y)
			_lbox(u, vf, 0.07, 0.07, gy - 0.1, gy + 2.2, fence, M_STONE, fence)
			if int(round((u - u0) / 1.2)) % 5 == 0:
				_lbox(u, vf, 0.16, 0.16, gy - 0.1, gy + 2.5, fence, M_STONE, fence)
		u += 1.2
	for seg in [Vector2(u0, 1.35 - gate), Vector2(1.35 + gate, u1)]:
		var p0 := _w(seg.x, vf)
		var p1 := _w(seg.y, vf)
		var y0: float = map.terrain_height(p0.x, p0.y)
		var y1: float = map.terrain_height(p1.x, p1.y)
		_beam(Vector3(p0.x, y0 + 2.0, p0.y), Vector3(p1.x, y1 + 2.0, p1.y), 0.08, fence)
		_beam(Vector3(p0.x, y0 + 0.4, p0.y), Vector3(p1.x, y1 + 0.4, p1.y), 0.08, fence)
		_collide(_rect((seg.x + seg.y) * 0.5, vf, (seg.y - seg.x) * 0.5, 0.15))
	# the gate's two open leaves, swung in
	for side in [-1.0, 1.0]:
		var hinge: float = 1.35 + side * gate
		_lbox(hinge, vf, 0.2, 0.2, g - 0.1, g + 2.6, fence, M_STONE, fence)
		_wall(_w(hinge, vf + 0.5), _w(hinge, vf + 3.0), g, g + 2.2, _w(1.0, 0.0) - _w(0.0, 0.0), fence)
	# six flagpoles in a row before the steps, a banner hung from each
	var k := 0
	for fu in [-9.0, -5.4, -1.8, 1.8, 5.4, 9.0]:
		var base := _w(fu, -13.0)
		var by: float = map.terrain_height(base.x, base.y)
		_beam(Vector3(base.x, by, base.y), Vector3(base.x, by + 11.0, base.y), 0.14, MUZEUM_POLE)
		_mode = M_STONE
		var col := MUZEUM_BANNER if k % 2 == 0 else MUZEUM_BANNER.lightened(0.12)
		_wall(_w(fu + 0.07, -13.0), _w(fu + 1.0, -13.0), by + 6.5, by + 10.6, -_b, col)
		_wall(_w(fu + 1.0, -13.0), _w(fu + 0.07, -13.0), by + 6.5, by + 10.6, _b, col)
		k += 1
	_mode = keep


## A tank on show (a hull on its tracks, an eight-sided turret, the gun), on a pad; `dir` its nose.
func _tank(c: Vector2, dir: Vector2) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_o = c
	_a = dir
	_b = Vector2(-dir.y, dir.x)
	_lbox(0.0, 0.0, 4.0, 2.4, g - 0.3, g + 0.15, ARMY_PAD, M_STONE, ARMY_PAD)
	for v in [-1.45, 1.45]:
		_lbox(0.0, v, 3.4, 0.4, g + 0.15, g + 1.1, ARMY_TRACK, M_STONE, ARMY_TRACK)
	_lbox(-0.1, 0.0, 3.1, 1.1, g + 0.5, g + 1.55, ARMY_OLIVE, M_STONE, ARMY_OLIVE.darkened(0.08))
	var turret := _circle(_w(-0.4, 0.0), 1.15, 8)
	_prism(turret, g + 1.55, g + 2.3, ARMY_OLIVE.lightened(0.04), ARMY_OLIVE, M_STONE, M_STONE)
	var muzzle := _w(4.3, 0.0)
	var root := _w(0.6, 0.0)
	_beam(Vector3(root.x, g + 1.9, root.y), Vector3(muzzle.x, g + 2.0, muzzle.y), 0.2, ARMY_OLIVE.darkened(0.25))
	_collide(_rect(0.0, 0.0, 3.4, 1.9))


## A field gun on show: the carriage and its shield, two wheels, the barrel raised, the split trail.
func _field_gun(c: Vector2, dir: Vector2) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_o = c
	_a = dir
	_b = Vector2(-dir.y, dir.x)
	_lbox(-0.6, 0.0, 3.0, 1.7, g - 0.3, g + 0.15, ARMY_PAD, M_STONE, ARMY_PAD)
	_lbox(0.0, 0.0, 0.7, 0.6, g + 0.6, g + 1.1, ARMY_OLIVE, M_STONE, ARMY_OLIVE)
	_lbox(0.45, 0.0, 0.06, 0.95, g + 0.7, g + 1.9, ARMY_OLIVE.darkened(0.1), M_STONE, ARMY_OLIVE)
	for v in [-0.95, 0.95]:
		_lbox(0.0, v, 0.6, 0.1, g + 0.15, g + 1.35, ARMY_TRACK, M_STONE, ARMY_TRACK)
	var root := _w(0.2, 0.0)
	var muzzle := _w(3.4, 0.0)
	_beam(Vector3(root.x, g + 1.05, root.y), Vector3(muzzle.x, g + 2.0, muzzle.y), 0.17, ARMY_OLIVE.darkened(0.25))
	for v in [-1.0, 1.0]:
		var p0 := _w(-0.4, v * 0.3)
		var p1 := _w(-3.2, v * 1.0)
		_beam(Vector3(p0.x, g + 0.75, p0.y), Vector3(p1.x, g + 0.25, p1.y), 0.16, ARMY_OLIVE.darkened(0.15))


## Plac Piłsudskiego's edges: Hotel Europejski (its mapped outline) and the Tomb of the Unknown
## Soldier (built at its place, like Sigismund's Column; its zone the mapped outline, which
## drops the hundred tiny 3D parts it is mapped in).
## Hotel Europejski (Enrico Marconi, 1857-1877; restored and reopened in 2018), rebuilt from
## photos (F, 2026-11-03: the Krakowskie Przedmieście front square on, the north-east corner close
## up, two aerials; with refs/krakowskie 28-29 and the GUGiK LoD2 heights). Spec
## docs/landmarks/specs/europejski.md. Cream stone all round: a rusticated ground floor of tall
## round-arched shop windows; three floors above, the first with pedimented windows over
## balustrade panels, the second with capped windows, the third small; at each rounded corner a
## bow-front of Corinthian columns in two tiers with curved balconies and arched windows; the main
## cornice, a balustrade attic, and set back behind it the dark louvred glass roof storey with its
## rounded ends; an inner courtyard under a glass roof. The plan is the outline's four straight
## fronts (OSM) with the corners rounded at EURO_R; edge 0 is Krakowskie Przedmieście (east),
## 1 the south front, 2 Plac Piłsudskiego's side (west), 3 Ossolińskich (north).
const EURO_CORNERS := [Vector2(-615.39, -913.99), Vector2(-587.82, -854.59),
		Vector2(-673.81, -833.85), Vector2(-688.95, -895.68)]  # the fronts' lines meeting (NE, SE, SW, NW)
const EURO_R := 6.5        # the bow-fronts' radius (front photo: ~13 m pavilions on a 65 m front)
const EURO_SEGS := 5       # facets per bow (a column on every joint)
const EURO_PAV := 13.0     # each corner pavilion's reach along a front, from the corner
const EURO_BAY := 3.6      # the window bays between the pavilions (11 on Krakowskie)
const EURO_WING := 14.0    # the wings' depth round the courtyard
const EURO_GF := 7.2       # the rusticated ground floor's top (LoD2: eaves ~20 m, roof storey ~25 m)
const EURO_T1 := 12.4      # the first floor's top: the lower column tier's entablature
const EURO_T2 := 13.4      # the second balcony, the upper tier's foot
const EURO_CORNICE := 19.4
const EURO_TOP := 20.0     # the cornice's top, the attic's foot
const EURO_ATTIC := 21.5
const EURO_ROOF := 25.0    # the roof storey's top
const EURO_COURT := 8.5    # the courtyard's glass roof
const EUROPEJSKI_WALL := Color("#eeeae0")  # photo 29 (refs/krakowskie) and F's photos
const EUROPEJSKI_BASE := Color("#e4dfd2")
const EUROPEJSKI_TRIM := Color("#f6f3ea")
const EUROPEJSKI_SHADE := Color("#cfc8b8")
const EUROPEJSKI_ROOF := Color("#262b2b")   # the louvres
const EUROPEJSKI_LEAD := Color("#8d918e")
const EUROPEJSKI_ZINC := Color("#66746f")  # the roof storey's top (F's aerial: green-grey)
const EUROPEJSKI_COURT := Color("#a39d92")  # the courtyard (F's aerial: pale, paved and glazed)
const EUROPEJSKI_GLASS := Color("#3a3f47")
const EUROPEJSKI_SHOP := Color("#4a4036")
const EUROPEJSKI_GOLD := Color(1.0, 0.8, 0.45)
const EUROPEJSKI_WORD := "HOTEL EUROPEJSKI"
const EUROPEJSKI_H := EURO_TOP  # the far skyline and the checks
## The Tomb: the middle of its arcade, the arcade's long axis (south), its piers along it.
const GROB := Vector2(-865.75, -768.7)
const GROB_AXIS := Vector2(-0.2425, -0.970)
const GROB_PIERS := [-5.55, -1.85, 1.85, 5.55]
const GROB_ROW := 2.98            # each row of piers this far from the axis
const GROB_STONE := Color("#ddd3bf")
const GROB_GRANITE := Color("#7f7c78")
const GROB_BRONZE := Color("#4f4a40")
const GROB_FLAME := Color("#ffb04a")
func _find_plac() -> void:
	var euro := _landmark("Hotel Europejski")
	if euro.size() >= 3:
		_add_site("europejski", [euro])
		if not sites.is_empty() and sites[-1]["key"] == "europejski":
			sites[-1]["ring"] = _euro_ring(0.0)
			sites[-1]["raw"] = euro
	var grob := _landmark("Grób Nieznanego Żołnierza")
	if grob.size() >= 3:
		var grown := Geometry2D.offset_polygon(grob, 1.0, Geometry2D.JOIN_MITER)
		_add_site("grob", [grown[0] if not grown.is_empty() else grob])
	_find_plac2()
	# Plac Piłsudskiego from photos (2026-11-02): the monuments and masts on the square.
	_find_plac_photos()


## The inward normal of front e (from corner e to e + 1).
func _euro_in(e: int) -> Vector2:
	var a: Vector2 = EURO_CORNERS[e % 4]
	var b: Vector2 = EURO_CORNERS[(e + 1) % 4]
	var t := (b - a).normalized()
	var n := Vector2(-t.y, t.x)
	var mid := (EURO_CORNERS[0] + EURO_CORNERS[1] + EURO_CORNERS[2] + EURO_CORNERS[3]) * 0.25
	return n if n.dot(mid - (a + b) * 0.5) > 0.0 else -n


## Front e's length, corner to corner.
func _euro_len(e: int) -> float:
	return (EURO_CORNERS[e % 4] as Vector2).distance_to(EURO_CORNERS[(e + 1) % 4])


## How far from corner i the bow meets the straight fronts (its tangent points, inset 0).
func _euro_tan(i: int) -> float:
	var c: Vector2 = EURO_CORNERS[i % 4]
	var u1 := ((EURO_CORNERS[(i + 3) % 4] as Vector2) - c).normalized()
	var u2 := ((EURO_CORNERS[(i + 1) % 4] as Vector2) - c).normalized()
	return EURO_R / tan(absf(u1.angle_to(u2)) * 0.5)


## A point on front e, u metres from its corner, moved d metres in (out when d < 0).
func _euro_pt(e: int, u: float, d: float) -> Vector2:
	var a: Vector2 = EURO_CORNERS[e % 4]
	var t := ((EURO_CORNERS[(e + 1) % 4] as Vector2) - a).normalized()
	return a + t * u + _euro_in(e) * d


## Corner i's bow at inset d: EURO_SEGS + 1 points from front i - 1's side to front i's. Every
## inset shares the bow's centre, so the rings stay concentric with the same corner count.
func _euro_arc(i: int, d: float) -> PackedVector2Array:
	var c: Vector2 = EURO_CORNERS[i % 4]
	var n1 := _euro_in(i + 3)
	var n2 := _euro_in(i)
	var u1 := ((EURO_CORNERS[(i + 3) % 4] as Vector2) - c).normalized()
	var u2 := ((EURO_CORNERS[(i + 1) % 4] as Vector2) - c).normalized()
	var half := absf(u1.angle_to(u2)) * 0.5
	var centre := c + (u1 + u2).normalized() * EURO_R / sin(half)
	var r := maxf(EURO_R - d, 0.6)
	var cd := c + (n1 + n2) * d / (1.0 + n1.dot(n2))
	var p1 := cd + u1 * r / tan(half)
	var p2 := cd + u2 * r / tan(half)
	var a1 := (p1 - centre).angle()
	var da := wrapf((p2 - centre).angle() - a1, -PI, PI)
	var out := PackedVector2Array()
	for k in EURO_SEGS + 1:
		out.append(centre + Vector2.from_angle(a1 + da * k / EURO_SEGS) * r)
	return out


## The whole plan at inset d (out when d < 0): the four bows joined by the straight fronts.
func _euro_ring(d: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for i in 4:
		ring.append_array(_euro_arc(i, d))
	return ring


## Corner i's pavilion as a path at inset d: from front i - 1's pavilion end round the bow to
## front i's.
func _euro_path(i: int, d: float) -> PackedVector2Array:
	var path := PackedVector2Array([_euro_pt(i + 3, _euro_len(i + 3) - EURO_PAV, d)])
	path.append_array(_euro_arc(i, d))
	path.append(_euro_pt(i, EURO_PAV, d))
	return path


## A segment's outward normal (away from the plan's middle).
func _euro_out(a: Vector2, b: Vector2) -> Vector2:
	var t := (b - a).normalized()
	var n := Vector2(t.y, -t.x)
	var mid := (EURO_CORNERS[0] + EURO_CORNERS[1] + EURO_CORNERS[2] + EURO_CORNERS[3]) * 0.25
	return n if n.dot((a + b) * 0.5 - mid) > 0.0 else -n


## A balcony along a path: the slab (front and top) `deep` out from the wall at y, and its
## balustrade near the slab's edge (a pale rail and plinth, darker between: the balusters' shade).
func _euro_balcony(i: int, y: float, deep: float) -> void:
	var wall := _euro_path(i, 0.0)
	var edge := _euro_path(i, -deep)
	var rail := _euro_path(i, -deep + 0.08)
	_mode = M_STONE
	for j in wall.size() - 1:
		var out := _euro_out(wall[j], wall[j + 1])
		var n := Vector3.UP
		_quad(Vector3(wall[j].x, y + 0.28, wall[j].y), Vector3(wall[j + 1].x, y + 0.28, wall[j + 1].y),
				Vector3(edge[j + 1].x, y + 0.28, edge[j + 1].y), Vector3(edge[j].x, y + 0.28, edge[j].y), n, EUROPEJSKI_TRIM)
		_wall(edge[j], edge[j + 1], y, y + 0.28, out, EUROPEJSKI_TRIM.darkened(0.04))
		for s: float in [1.0, -1.0]:
			_wall(rail[j], rail[j + 1], y + 0.28, y + 0.42, out * s, EUROPEJSKI_TRIM)
			_wall(rail[j], rail[j + 1], y + 0.42, y + 1.0, out * s, EUROPEJSKI_SHADE)
			_wall(rail[j], rail[j + 1], y + 1.0, y + 1.15, out * s, EUROPEJSKI_TRIM.lightened(0.04))


## A column on a plan spot: a hexagonal shaft and a flared (Corinthian) capital.
func _euro_column(p: Vector2, y0: float, y1: float, r: float) -> void:
	var none := Color(0, 0, 0, 0)
	_prism(_circle(p, r, 6), y0, y1 - 0.5, EUROPEJSKI_TRIM, none, M_STONE)
	_mode = M_STONE
	_frustum(_circle(p, r, 6), y1 - 0.5, _circle(p, r * 1.7, 6), y1, EUROPEJSKI_TRIM.lightened(0.05), EUROPEJSKI_TRIM)


## A face in the current front's frame: u0..u1, y0..y1 (absolute), v out from the wall.
func _euro_face(u0: float, u1: float, y0: float, y1: float, v: float, col: Color, mode := M_STONE) -> void:
	_mode = mode
	_wall(_w(u0, v), _w(u1, v), y0, y1, _b, col, 0.0 if mode != M_GLASS else 0.75 - (u1 - u0) * 0.5)
	_mode = M_STONE


## A ledge (a sill, a window cap) in the front's frame: its face `deep` out and its top.
func _euro_ledge(u0: float, u1: float, y0: float, y1: float, deep: float, col: Color) -> void:
	_euro_face(u0, u1, y0, y1, deep, col)
	var a := _w(u0, 0.0)
	var b := _w(u1, 0.0)
	var c := _w(u1, deep)
	var d := _w(u0, deep)
	_quad(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(c.x, y1, c.y), Vector3(d.x, y1, d.y), Vector3.UP, col.lightened(0.04))


## A window with its surround in the front's frame (the pane `hw` half wide).
func _euro_window(cu: float, y0: float, y1: float, hw: float) -> void:
	_euro_face(cu - hw - 0.18, cu + hw + 0.18, y0 - 0.18, y1 + 0.1, 0.04, EUROPEJSKI_TRIM)
	_euro_face(cu - hw, cu + hw, y0, y1, 0.08, EUROPEJSKI_GLASS, M_GLASS)


## A round-headed opening with its surround on a plan spot (`along` the wall, `out` from it).
func _euro_arched(at: Vector2, along: Vector2, out: Vector2, hw: float, y0: float, spring: float, glass: Color) -> void:
	_arch_panel(at, along, out, hw + 0.22, y0, spring, EUROPEJSKI_TRIM, 0.04, M_STONE)
	_arch_panel(at, along, out, hw, y0, spring, glass, 0.08, M_GLASS)
	_mode = M_STONE


func _build_europejski(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", site["ring"])
	var ring := _euro_ring(0.0)
	_g = _ground_under(raw)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# Bows first: their columns, windows and balconies stand off the walls drawn after them.
	for i in 4:
		var arc := _euro_arc(i, 0.0)
		var cols := _euro_arc(i, -0.55)
		for k in arc.size():
			_euro_column(cols[k], g + EURO_GF + 1.15, g + EURO_T1, 0.32)
			_euro_column(cols[k], g + EURO_T2 + 1.15, g + EURO_CORNICE, 0.34)
		for k in arc.size() - 1:
			var mid := (arc[k] + arc[k + 1]) * 0.5
			var along := (arc[k + 1] - arc[k]).normalized()
			var out := _euro_out(arc[k], arc[k + 1])
			_euro_arched(mid, along, out, 0.5, g + EURO_GF + 1.4, g + EURO_T1 - 1.6, EUROPEJSKI_GLASS)
			_euro_arched(mid, along, out, 0.5, g + EURO_T2 + 1.4, g + EURO_CORNICE - 3.2, EUROPEJSKI_GLASS)
			if k == EURO_SEGS / 2:
				_euro_arched(mid, along, out, 0.75, g + 0.3, g + 4.4, EUROPEJSKI_SHOP)
		_euro_balcony(i, g + EURO_GF, 1.0)
		_euro_balcony(i, g + EURO_T1 + 0.05, 0.8)
	# The fronts, each in its own frame: u from its corner, +v out of the wall.
	for e in 4:
		var length := _euro_len(e)
		_o = EURO_CORNERS[e]
		_a = ((EURO_CORNERS[(e + 1) % 4] as Vector2) - _o).normalized()
		_b = -_euro_in(e)
		# the pavilions' straight parts: paired columns at the inner end, an arched window per storey
		for end in 2:
			var t := _euro_tan(e if end == 0 else e + 1)
			var s := 1.0 if end == 0 else -1.0
			var u0 := 0.0 if end == 0 else length
			var inner := u0 + s * EURO_PAV
			for du: float in [0.6, 1.5]:
				var p := _w(inner - s * du, 0.55)
				_euro_column(p, g + EURO_GF + 1.15, g + EURO_T1, 0.32)
				_euro_column(p, g + EURO_T2 + 1.15, g + EURO_CORNICE, 0.34)
			var cw := (u0 + s * t + inner - s * 2.0) * 0.5
			var at := _w(cw, 0.0)
			_euro_arched(at, _a, _b, 0.65, g + EURO_GF + 1.4, g + EURO_T1 - 1.5, EUROPEJSKI_GLASS)
			_euro_arched(at, _a, _b, 0.65, g + EURO_T2 + 1.4, g + EURO_CORNICE - 3.1, EUROPEJSKI_GLASS)
			_euro_arched(at, _a, _b, 0.95, g + 0.3, g + 4.4, EUROPEJSKI_SHOP)
		# the window bays between the pavilions
		var span := length - 2.0 * EURO_PAV
		var n := maxi(int(round(span / EURO_BAY)), 1)
		var bay := span / n
		for k in n:
			var cu := EURO_PAV + (k + 0.5) * bay
			if (k - n / 2) % 2 == 0:  # the ground floor: tall arched shop windows, doors between
				_euro_arched(_w(cu, 0.0), _a, _b, 1.15, g + 0.3, g + 4.5, EUROPEJSKI_SHOP)
			else:
				_euro_window(cu, g + 0.3, g + 3.6, 0.6)
				_euro_window(cu, g + 4.6, g + 5.6, 0.55)
			# the first floor: a balustrade panel, the window, its cap and pediment
			_euro_ledge(cu - 1.05, cu + 1.05, g + EURO_GF + 0.3, g + EURO_GF + 1.1, 0.16, EUROPEJSKI_TRIM)
			_euro_window(cu, g + EURO_GF + 1.3, g + EURO_T1 - 1.4, 0.62)
			_euro_ledge(cu - 0.95, cu + 0.95, g + EURO_T1 - 1.25, g + EURO_T1 - 1.05, 0.2, EUROPEJSKI_TRIM)
			var p0 := _w(cu - 0.95, 0.12)
			var p1 := _w(cu + 0.95, 0.12)
			var p2 := _w(cu, 0.12)
			var yb := g + EURO_T1 - 1.05
			_tri(Vector3(p0.x, yb, p0.y), Vector3(p1.x, yb, p1.y), Vector3(p2.x, yb + 0.6, p2.y), Vector3(_b.x, 0.0, _b.y),
					EUROPEJSKI_TRIM, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			# the second floor's capped window, the third's small one
			_euro_window(cu, g + EURO_T2 + 0.6, g + EURO_T2 + 2.7, 0.58)
			_euro_ledge(cu - 0.9, cu + 0.9, g + EURO_T2 + 2.85, g + EURO_T2 + 3.05, 0.2, EUROPEJSKI_TRIM)
			_euro_window(cu, g + EURO_T2 + 4.0, g + EURO_T2 + 5.1, 0.5)
		# the attic's dies at the bay joints and the pavilions' ends
		for k in n + 1:
			_lbox(EURO_PAV + k * bay, -0.15, 0.22, 0.22, g + EURO_TOP, g + EURO_ATTIC, EUROPEJSKI_TRIM, M_STONE, EUROPEJSKI_TRIM)
		if e == 0:  # Krakowskie Przedmieście: the name over the middle bays
			var mu := length * 0.5
			_euro_face(mu - 4.2, mu + 4.2, g + EURO_T1 + 0.05, g + EURO_T2 - 0.05, 0.1, EUROPEJSKI_BASE)
			var k := 7.2 / Neon.length_of(EUROPEJSKI_WORD)
			var at := _w(mu, -0.25)
			var yk := g + (EURO_T1 + EURO_T2) * 0.5 - 0.5 * k * Neon.ROW_H * Neon.PIXEL
			signs.append([EUROPEJSKI_WORD, Vector3(at.x, yk, at.y), Vector3(_b.x, 0.0, _b.y), k, EUROPEJSKI_GOLD])
	# The walls: the ground floor's rusticated courses, the stone above, the string courses.
	var courses := 6
	for k in courses:
		var y0 := g - 0.6 + (EURO_GF + 0.6) * k / courses
		var y1 := g - 0.6 + (EURO_GF + 0.6) * (k + 1) / courses
		_prism(ring, y0, y1, EUROPEJSKI_BASE.darkened(0.06 if k % 2 == 0 else 0.0), none, M_STONE)
	_prism(ring, g + EURO_GF, g + EURO_CORNICE, EUROPEJSKI_WALL, none, M_STONE)
	_prism(_euro_ring(-0.25), g + EURO_GF - 0.25, g + EURO_GF, EUROPEJSKI_TRIM, none, M_STONE)
	_prism(_euro_ring(-0.2), g + EURO_T1, g + EURO_T1 + 0.3, EUROPEJSKI_TRIM, none, M_STONE)
	_prism(_euro_ring(-0.3), g + EURO_CORNICE - 0.7, g + EURO_CORNICE, EUROPEJSKI_TRIM.darkened(0.03), none, M_STONE)
	# The main cornice and the roof round the courtyard.
	var court := _euro_ring(EURO_WING)
	_prism(_euro_ring(-0.7), g + EURO_CORNICE, g + EURO_TOP, EUROPEJSKI_TRIM.lightened(0.04), none, M_STONE)
	_mode = M_STONE
	_cap_holes(_euro_ring(-0.7), [court], g + EURO_TOP, EUROPEJSKI_LEAD)
	# The balustrade attic: plinth, the balusters' shade, rail.
	var attic := _euro_ring(0.15)
	_parapet(attic, g + EURO_TOP, 0.3, EUROPEJSKI_TRIM)
	_parapet(_euro_ring(0.3), g + EURO_TOP + 0.3, EURO_ATTIC - EURO_TOP - 0.55, EUROPEJSKI_SHADE)
	_parapet(attic, g + EURO_ATTIC - 0.25, 0.25, EUROPEJSKI_TRIM.lightened(0.04))
	# The roof storey: dark louvred glass set back behind the attic, its top curving in.
	var louvre0 := _euro_ring(1.7)
	var louvre1 := _euro_ring(3.0)
	_mode = M_GLASS
	_prism(louvre0, g + EURO_TOP, g + EURO_ROOF - 1.3, EUROPEJSKI_ROOF, none, M_GLASS)
	_mode = M_STONE
	_frustum(louvre0, g + EURO_ROOF - 1.3, _euro_ring(2.2), g + EURO_ROOF - 0.5, EUROPEJSKI_ROOF.lightened(0.04))
	_frustum(_euro_ring(2.2), g + EURO_ROOF - 0.5, louvre1, g + EURO_ROOF, EUROPEJSKI_ROOF.lightened(0.08))
	var inner := _euro_ring(EURO_WING - 1.8)
	_cap_holes(louvre1, [inner], g + EURO_ROOF, EUROPEJSKI_ZINC)
	# The courtyard: its walls face in (stone with windows), the glass roof low over it.
	for j in inner.size():
		var a := inner[j]
		var b := inner[(j + 1) % inner.size()]
		_mode = M_GLASS
		_wall(a, b, g + EURO_TOP, g + EURO_ROOF, -_euro_out(a, b), EUROPEJSKI_ROOF)
	for j in court.size():
		var a := court[j]
		var b := court[(j + 1) % court.size()]
		_mode = M_MONUMENT
		_wall(a, b, g + EURO_COURT, g + EURO_TOP, -_euro_out(a, b), EUROPEJSKI_WALL)
	_mode = M_STONE
	_cap(court, g + EURO_COURT, EUROPEJSKI_COURT)
	_collide(raw)  # the mapped outline: the car meets the facade where the map's pavement ends


# --- TR Warszawa's building site ----------------------------------------------------------

## The Tomb of the Unknown Soldier: the three arches left of the Saxon Palace's colonnade (blown
## up in 1944). A granite platform, two rows of four stone piers, round arches on both long
## faces, the entablature and its cornice over them; under the middle arch the tomb slab with
## wreaths and the eternal flame (it glows at night) on the square's side.
func _build_grob(_site: Dictionary) -> void:
	_o = GROB
	_a = GROB_AXIS
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(GROB.x, GROB.y)
	var g := _g
	var light := GROB_STONE.lightened(0.06)
	_lbox(0.0, 0.0, 7.6, 4.4, g - 0.5, g + 0.3, GROB_GRANITE, M_STONE, GROB_GRANITE)
	for v: float in [-GROB_ROW, GROB_ROW]:
		for u: float in GROB_PIERS:
			_lbox(u, v, 0.65, 0.65, g + 0.3, g + 5.0, GROB_STONE, M_STONE, GROB_STONE)
			_lbox(u, v, 0.8, 0.8, g + 5.0, g + 5.35, light, M_STONE, light)
		# The arches between the piers, on the row's outer face.
		var face := v + signf(v) * 0.65
		for k in GROB_PIERS.size() - 1:
			_arch(float(GROB_PIERS[k]) + 0.65, float(GROB_PIERS[k + 1]) - 0.65, face, g + 3.6, g + 5.35, GROB_STONE)
	_lbox(0.0, 0.0, 6.3, 3.75, g + 5.35, g + 7.3, GROB_STONE, M_STONE, GROB_STONE.darkened(0.08))
	_lbox(0.0, 0.0, 6.55, 4.0, g + 7.3, g + 7.65, light, M_STONE, light.darkened(0.1))
	# The tomb, its wreaths, the flame in its bronze bowl.
	_lbox(0.0, 0.0, 1.2, 0.8, g + 0.3, g + 0.55, GROB_GRANITE.darkened(0.3), M_STONE, GROB_GRANITE.darkened(0.3))
	_lbox(-0.75, -0.95, 0.3, 0.3, g + 0.3, g + 0.6, Color("#c8323a"), M_STONE, Color("#c8323a"))
	_lbox(0.75, -0.95, 0.3, 0.3, g + 0.3, g + 0.6, Color("#f1efe8"), M_STONE, Color("#f1efe8"))
	var bowl := _w(0.0, -1.9)
	_prism(_circle(bowl, 0.35, 6), g + 0.3, g + 1.0, GROB_BRONZE, GROB_BRONZE, M_STONE, M_STONE)
	_mode = M_LAMP
	_pyramid(_circle(bowl, 0.26, 4), g + 1.0, g + 1.75, GROB_FLAME)
	_mode = M_STONE
	_collide(_rect(0.0, 0.0, 6.3, 3.7))


# --- Plac Piłsudskiego, part 2 (2026-10-31) ---------------------------------------------------

## The square's other edges. The Metropolitan (its mapped outline; it wore the towers' fin skin
## since the landmarks loop) and Hotel Wiktoria (the parody name of the 1976 hotel on Królewska,
## mapped as an outline only: GUGiK's LoD2 draws it, OpenStreetMap has no building there) are
## models; the Królewska edge's blocks keep their LoD2 or OpenStreetMap shapes in their own
## stone (`skin_at`). Heights: the Metropolitan's are the mapped parts' (building:levels);
## the hotel's are estimates (docs/DEVELOPMENT.md says which).
##
## The Metropolitan (Foster + Partners, 2003): three seven-storey blocks round a circular
## courtyard, joined over three passages; the curved fronts are glass behind close vertical
## granite fins; the seventh storey stands back; a round fountain in the courtyard's floor.
const METRO_COURT := Vector2(-800.3, -932.0)   # the courtyard's centre (the blocks' inner arcs)
const METRO_COURT_R := 25.4
## The three passages into the courtyard: the middles of the bridges mapped over them (6.6 m up).
const METRO_GATES := [Vector2(-806.8, -900.0), Vector2(-826.5, -949.5), Vector2(-775.2, -947.6)]
## The three blocks' plant rooms (the mapped 23.1-27.4 m parts), by their middles.
const METRO_BLOCKS := [Vector2(-832.6, -921.6), Vector2(-804.6, -963.0), Vector2(-775.4, -909.0)]
const METRO_H := 20.8          # the fin walls' top (mapped: six storeys)
const METRO_RING_H := 24.1     # the seventh storey (mapped), METRO_SETBACK behind the fins
const METRO_TOP_H := 27.4      # the plant rooms (mapped)
const METRO_SETBACK := 2.0
const METRO_GATE_H := 6.6
const METRO_GATE_W := 6.0
const METRO_FIN_STEP := 1.8    # the fins: one every 1.8 m round the fronts, 0.34 m thick, 0.9 m deep
const METRO_FIN_W := 0.34
const METRO_FIN_D := 0.9
const METRO_GRANITE := Color("#bfb8ac")
const METRO_GLASS := Color("#5d6c73")
const METRO_ROOF := Color("#9a9a96")
const METRO_PAVING := Color("#aaa59c")
const METRO_GATE := Color("#2a2d30")
const METRO_POOL := Color("#47606c")
const METRO_JET := Color("#e4eff2")
## Hotel Wiktoria (parody of the 1970s Sofitel Victoria): two white modernist volumes on a glazed
## base. The long slab runs along the Królewska front (the north edge of its outline), eight floors
## of bronze-tinted windows each in a shadowed niche between white fins; the wing at the square's
## end runs back at six floors; the glazed base is set back under them, with a terrace slab at the
## first-floor level over the whole outline and a dark canopy at the entrance; a plant room on the
## slab. No sign text: the real brand's name is not used.
const WIK_BASE_H := 6.5           # the glazed base and the terrace over it (photos)
const WIK_FLOOR_H := 3.0          # a floor of the white volumes
const WIK_SLAB_ROWS := 8          # window floors of the long slab
const WIK_WING_ROWS := 6          # and of the wing at the square's end
const WIK_SLAB_D := 17.0          # the slab's depth: an estimate (a double-loaded hotel floor)
const WIK_WING_W := 19.0          # the wing's width: an estimate
const WIK_PITCH := 3.0            # the window bay
const WIK_WHITE := Color("#e8e7e1")
const WIK_WINDOW := Color("#7a5a38")
const WIK_GLASS_BASE := Color("#44535a")
const WIK_CANOPY := Color("#3b3d3e")
const WIK_ROOF := Color("#8d8c88")
## The Królewska edge, kept as LoD2 (or OpenStreetMap) draws it but in its own stone: by name
## (the landmark outlines). Dom bez Kantów is a model of its own since 2026-11-15: the whole block
## on the square's south-east corner, Królewska 2 included (`_build_bez_kantow`).
## `mode` M_MONUMENT draws tall windows between piers, a value under 1 the city's plain windows
## with that seed (Dom bez Kantów's modernist rows).
const PLAC_SKINS := [
	{"key": "bez_kantow", "osm": "Dom Bez Kantów", "mode": 0.37, "wall": "#d3cec2", "roof": "#85837e", "model": true},
	{"key": "departament", "osm": "Departament Wojskowej Służby Zdrowia", "mode": M_MONUMENT, "wall": "#dccfb2", "roof": "#7c7871"},
]


func _find_plac2() -> void:
	var metro := _landmark("Metropolitan")
	if metro.size() >= 3:
		_add_site("metropolitan", [metro])
		if not sites.is_empty() and sites[-1]["key"] == "metropolitan":
			sites[-1]["ring"] = _simplify(metro, 0.4)
	var hotel := _landmark("Sofitel Victoria")
	if hotel.size() >= 3:
		_add_site("wiktoria", [hotel])
		if not sites.is_empty() and sites[-1]["key"] == "wiktoria":
			sites[-1]["ring"] = _simplify(hotel, 0.8)
	for t: Dictionary in PLAC_SKINS:
		var outline := _landmark(t["osm"])
		if outline.size() < 3:
			continue
		# Dom bez Kantów is the whole block now (2026-11-15, `_build_bez_kantow`): its OSM outline is
		# only the east and south-east wings, LoD2 has the west and north wings apart, so the site's
		# zone is our own solid outline of the ring and replaces all of them.
		if t["key"] == "bez_kantow":
			_add_site("bez_kantow", [_krl_ring(false)])
			if not sites.is_empty() and sites[-1]["key"] == "bez_kantow":
				sites[-1]["courts"] = [_krl_ring(true)] as Array[PackedVector2Array]
			continue
		_add_site(t["key"], [outline])
		# `model`: the whole building is a model now (it replaces LoD2); the entry keeps its place in
		# the site order (tap ids) and its wall colour for the skyline (tower_colour)
		if t.get("model", false):
			continue
		if not sites.is_empty() and sites[-1]["key"] == t["key"]:
			sites[-1]["skin"] = {"mode": M_MONUMENT_FLOOD if FLOODLIT_SITES.has(t["key"]) and t["mode"] == M_MONUMENT else t["mode"], "wall": Color(t["wall"]), "roof": Color(t["roof"])}


## The Metropolitan: the outline's fronts in glass (M_GLASS) behind granite fins standing out
## from the ground to the parapet; the courtyard's wall in glass with painted fins (S_FINS: seen
## only from above); dark openings where the three passages go through, under a granite lintel;
## a flat roof with a parapet; the seventh storey set back, the three plant rooms on top; in the
## courtyard the paving and the round fountain with its jets.
func _build_metropolitan(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var court := _circle(METRO_COURT, METRO_COURT_R, 40)
	_prism(ring, g - 0.6, g + METRO_H, METRO_GLASS, none, M_GLASS)
	_inside_wall(court, g - 0.6, g + METRO_H, METRO_GLASS, M_SKIN + S_FINS / 16.0)
	_mode = M_STONE
	_cap_holes(ring, [court], g + METRO_H, METRO_ROOF)
	_parapet(ring, g + METRO_H, 0.9, METRO_GRANITE)
	_parapet(court, g + METRO_H, 0.9, METRO_GRANITE)
	# The passages: where each meets the outer front and the courtyard.
	var doors := PackedVector2Array()
	for gate: Vector2 in METRO_GATES:
		var d := (gate - METRO_COURT).normalized()
		var t := Vector2(-d.y, d.x)
		var p := _exit_point(ring, METRO_COURT, d, 120.0)
		doors.append(p)
		var half := METRO_GATE_W * 0.5
		_mode = M_STONE
		_wall(p + d * 0.45 - t * half, p + d * 0.45 + t * half, g - 0.6, g + METRO_GATE_H, d, METRO_GATE)
		_wall(p + d * 0.95 - t * (half + 0.6), p + d * 0.95 + t * (half + 0.6), g + METRO_GATE_H, g + METRO_GATE_H + 0.9, d, METRO_GRANITE)
		var q := METRO_COURT + d * (METRO_COURT_R - 0.3)
		_wall(q - t * half, q + t * half, g - 0.6, g + METRO_GATE_H, -d, METRO_GATE)
	_fins(ring, g - 0.6, g + METRO_H + 0.9, METRO_FIN_STEP, METRO_FIN_W, METRO_FIN_D, METRO_GRANITE, doors,
			METRO_GATE_W * 0.5 + 0.8)
	# The seventh storey, set back from the fins and from the courtyard.
	var upper := _largest(Geometry2D.offset_polygon(ring, -METRO_SETBACK, Geometry2D.JOIN_MITER))
	var court2 := _circle(METRO_COURT, METRO_COURT_R + METRO_SETBACK, 40)
	# the seventh storey and the plant rooms are silver metal over a glazed band (photo 2026-11-07)
	var light := Color("#aab5ba")
	if upper.size() >= 3:
		_prism(upper, g + METRO_H, g + METRO_RING_H, light, none, M_GLASS)
		_inside_wall(court2, g + METRO_H, g + METRO_RING_H, light, M_GLASS)
		_mode = M_STONE
		_cap_holes(upper, [court2], g + METRO_RING_H, METRO_ROOF.lightened(0.05))
		_parapet(upper, g + METRO_RING_H, 0.6, METRO_GRANITE)
		# The plant rooms: each block's outer part, inside a wedge round its middle.
		var inner := _largest(Geometry2D.offset_polygon(ring, -6.0, Geometry2D.JOIN_MITER))
		var core := _circle(METRO_COURT, METRO_COURT_R + 10.0, 24)
		for mid: Vector2 in METRO_BLOCKS:
			var d := (mid - METRO_COURT).normalized()
			var wedge := PackedVector2Array([METRO_COURT, METRO_COURT + d.rotated(-0.45) * 120.0,
					METRO_COURT + d * 120.0, METRO_COURT + d.rotated(0.45) * 120.0])
			for piece in Geometry2D.intersect_polygons(inner, wedge):
				for part in Geometry2D.clip_polygons(piece, core):
					if absf(_area(part)) > 40.0:
						_prism(_simplify(part, 0.4), g + METRO_RING_H, g + METRO_TOP_H, light.lightened(0.08), METRO_ROOF,
								M_GLASS, M_STONE)
	# The courtyard: its paving, the round fountain and its jets.
	var gc: float = map.terrain_height(METRO_COURT.x, METRO_COURT.y)
	_mode = M_STONE
	_cap(court, gc + 0.04, METRO_PAVING)
	_prism(_circle(METRO_COURT, 7.0, 24), gc - 0.2, gc + 0.22, METRO_GRANITE, METRO_POOL, M_STONE, M_STONE)
	for k in 8:
		var j := METRO_COURT + Vector2.from_angle(TAU * k / 8.0) * 4.2
		_beam(Vector3(j.x, gc + 0.22, j.y), Vector3(j.x, gc + 1.7, j.y), 0.14, METRO_JET)
	_collide(ring)


## A wall round the inside of a ring (a courtyard), facing its middle, in `mode`.
func _inside_wall(ring: PackedVector2Array, y0: float, y1: float, col: Color, mode: float) -> void:
	var keep := _mode
	_mode = mode
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		_wall(a, b, y0, y1, -_out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## Where a ray from `c` along `d` last crosses a ring (its outer front), within `reach`.
func _exit_point(ring: PackedVector2Array, c: Vector2, d: Vector2, reach: float) -> Vector2:
	var best := c + d * reach
	var far := -1.0
	for i in ring.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(c, c + d * reach, ring[i], ring[(i + 1) % ring.size()])
		if hit != null and (hit as Vector2).distance_to(c) > far:
			far = (hit as Vector2).distance_to(c)
			best = hit
	return best


## Vertical fins standing `depth` out from a ring's walls, one every `step` metres along it,
## `w` thick, from y0 to y1, with a top; none within `gap` of a point in `skip` (a doorway).
func _fins(ring: PackedVector2Array, y0: float, y1: float, step: float, w: float, depth: float, col: Color,
		skip: PackedVector2Array, gap: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var next := step * 0.5   # where the next fin stands, from the start of the current edge
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 0.01:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		while next <= length:
			var p := a + e * next
			next += step
			var clear := true
			for s in skip:
				if p.distance_to(s) < gap:
					clear = false
					break
			if not clear:
				continue
			var p0 := p - e * w * 0.5
			var p1 := p + e * w * 0.5
			var q0 := p0 + out * depth
			var q1 := p1 + out * depth
			_wall(p0, q0, y0, y1, -e, col)
			_wall(q0, q1, y0, y1, out, col)
			_wall(q1, p1, y0, y1, e, col)
			_quad(Vector3(p0.x, y1, p0.y), Vector3(q0.x, y1, q0.y), Vector3(q1.x, y1, q1.y), Vector3(p1.x, y1, p1.y),
					Vector3.UP, col.lightened(0.06))
		next -= length
	_mode = keep


## Hotel Wiktoria: the podium over the whole outline in dark glass under a stone fascia, the
## slab along the Królewska front in ribbon windows, a parapet and a plant room on it.
func _build_wiktoria(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The frame: u east along the longest front facing north (Królewska), v south into the plot.
	_a = Vector2.RIGHT
	var longest := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if _out(ring, a, b).y < -0.7 and a.distance_to(b) > longest:
			longest = a.distance_to(b)
			_a = (b - a).normalized() * (1.0 if b.x >= a.x else -1.0)
	_b = Vector2(-_a.y, _a.x)
	_o = _centre(ring)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in ring:
		lo = lo.min(_local(q))
		hi = hi.max(_local(q))
	var y_base := g + WIK_BASE_H
	var inner := _largest(Geometry2D.offset_polygon(ring, -0.4, Geometry2D.JOIN_MITER))
	if inner.size() < 3:
		inner = ring
	# The glazed base, set back 1.2 m under the white volumes (they overhang it), and the terrace
	# slab at the first-floor level over the whole outline.
	var base := _largest(Geometry2D.offset_polygon(inner, -1.2, Geometry2D.JOIN_MITER))
	_prism(base if base.size() >= 3 else inner, g - 0.6, y_base, WIK_GLASS_BASE, none, M_GLASS)
	_cap(inner, y_base, WIK_WHITE.darkened(0.06))
	# The entrance canopy at the west end of the Królewska front: a dark slab on two piers.
	_kbox(lo.x + 3.0, lo.x + 21.0, lo.y - 4.5, lo.y + 0.5, g + 4.6, g + 5.3, WIK_CANOPY)
	for pu in [lo.x + 4.0, lo.x + 20.0]:
		_kbox(pu - 0.25, pu + 0.25, lo.y - 4.2, lo.y - 3.7, g, g + 4.6, WIK_CANOPY)
	# The two white volumes: the long slab along Królewska (eight floors) and the wing at the
	# square's end running back (six floors).
	var slab_rect := PackedVector2Array([_wl(Vector2(lo.x - 2.0, lo.y - 2.0)), _wl(Vector2(hi.x + 2.0, lo.y - 2.0)),
			_wl(Vector2(hi.x + 2.0, lo.y + WIK_SLAB_D)), _wl(Vector2(lo.x - 2.0, lo.y + WIK_SLAB_D))])
	var wing_rect := PackedVector2Array([_wl(Vector2(hi.x - WIK_WING_W, lo.y + WIK_SLAB_D - 1.0)), _wl(Vector2(hi.x + 2.0, lo.y + WIK_SLAB_D - 1.0)),
			_wl(Vector2(hi.x + 2.0, hi.y + 2.0)), _wl(Vector2(hi.x - WIK_WING_W, hi.y + 2.0))])
	for vol: Array in [[slab_rect, WIK_SLAB_ROWS, wing_rect], [wing_rect, WIK_WING_ROWS, slab_rect]]:
		var rows_n: int = vol[1]
		var roof_y := y_base + 1.2 + WIK_FLOOR_H * float(rows_n)
		for piece in Geometry2D.intersect_polygons(inner, vol[0]):
			if absf(_area(piece)) < 150.0:
				continue
			var poly := _simplify(piece, 0.6)
			_prism(poly, y_base, roof_y, WIK_WHITE, WIK_ROOF, M_STONE, M_STONE)
			_wik_faces(poly, vol[2], y_base, roof_y, rows_n)
			if rows_n == WIK_SLAB_ROWS:
				var c := _local(_centre(poly))
				_prism(_rect(c.x + 8.0, c.y, 9.0, 4.0), roof_y, roof_y + 3.2, WIK_ROOF.lightened(0.08),
						WIK_ROOF, M_STONE, M_STONE)
	_collide(ring)


## The windows of one white volume's fronts: a window of
## bronze-tinted glass every WIK_PITCH metres on each floor, white fins between them and a sill under
## each, so every window sits in a shadowed niche (the real facade's deep panel reveals); a thin
## parapet. Short fronts (the blank end walls, under 20 m) and fronts hidden inside the other volume get the parapet only.
func _wik_faces(poly: PackedVector2Array, other: PackedVector2Array, y0: float, y1: float, rows_n: int) -> void:
	for k in poly.size():
		var p := poly[k]
		var q := poly[(k + 1) % poly.size()]
		var le := p.distance_to(q)
		if le < 0.8:
			continue
		var out := _out(poly, p, q)
		if (Vector2(-(q - p).y, (q - p).x)).dot(out) < 0.0:
			var tmp := p
			p = q
			q = tmp
		var mid := (p + q) * 0.5
		# a front standing inside the other volume is hidden: no windows on it
		var on_ring := not Geometry2D.is_point_in_polygon(mid + out * 1.5, other)
		kit_front(p, q)
		kit_face(0.0)
		if on_ring and le >= 20.0:
			var m := maxi(1, roundi(le / WIK_PITCH))
			var step := le / float(m)
			var cs: Array = []
			var rows: Array = []
			for i in m:
				cs.append((float(i) + 0.5) * step)
			for r in rows_n:
				rows.append(y0 + 1.2 + WIK_FLOOR_H * float(r))
			kit_panes(cs, rows, step - 1.1, 1.5, WIK_WINDOW, 0.04)
			for i in m + 1:
				var fu := float(i) * step
				_kbox(maxf(fu - 0.18, 0.0), minf(fu + 0.18, le), 0.0, 0.3, y0, y1, WIK_WHITE.darkened(0.04))
			for yr in rows:
				kit_ledge(0.0, le, float(yr) - 0.25, 0.2, WIK_WHITE, 0.3)
		kit_cornice(0.0, le, y1, WIK_WHITE, 0.3, 0.35)


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

## Zachęta (Stefan Szyller, 1898-1900): the white gallery on Plac Małachowskiego, its front to the
## east. A rusticated ground floor over a basement band, the upper floor of tall windows, a cornice
## and a balustrade; the end pavilions stand forward under acroteria; in the middle two pylons
## frame two giant columns before three doors, the attic with ARTIBVS over them and a pediment
## full of sculpture; steps between two candelabra. Behind, the top-lit halls under glass.
## Frame: u along the front from its north end (u < 0) to the church's side, +v out of the front.
const ZACHETA := Vector2(-833.4, -593.3)
const ZACHETA_AXIS := Vector2(0.3339, 0.9426)
const ZACHETA_BACK := -45.0
const ZACHETA_HU := Vector2(-24.0, 23.0)   # the front's ends (u)
const ZACHETA_WIN := [-20.4, -17.0, -13.4, -9.8, 9.8, 13.4, 17.0, 20.4]
const ZACHETA_DOORS := [-4.2, 0.0, 4.1]
const ZACHETA_WHITE := Color("#ebeae4")
const ZACHETA_BASE := Color("#d4d3cd")
const ZACHETA_COLUMN := Color("#b9bab5")
const ZACHETA_GLASS := Color("#3d4850")
const ZACHETA_DOOR := Color("#4a3328")
const ZACHETA_ROOF := Color("#8d9092")
const ZACHETA_SKY := Color("#9fb0b8")
const ZACHETA_SCULPT := Color("#f4f3ee")
const ZACHETA_IRON := Color("#2f3331")


func _find_zacheta() -> void:
	var outline := _landmark("Zachęta")
	if outline.size() >= 3:
		_add_site("zacheta", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "zacheta":
			sites[-1]["ring"] = outline


func _build_zacheta(site: Dictionary) -> void:
	_o = ZACHETA
	_a = ZACHETA_AXIS.normalized()
	_b = Vector2(_a.y, -_a.x)
	var u0 := ZACHETA_HU.x
	var u1 := ZACHETA_HU.y
	var body := _rect((u0 + u1) * 0.5, ZACHETA_BACK * 0.5, (u1 - u0) * 0.5, -ZACHETA_BACK * 0.5)
	_g = _ground_under(body)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var light := ZACHETA_WHITE.lightened(0.05)
	# windows and doors first, so the walls behind them stay whole (they stand 7 cm proud)
	_mode = M_GLASS
	for u: float in ZACHETA_WIN:
		# the outer pair sit in the end pavilions, which stand 0.5 m forward
		var f := 0.57 if absf(u) > 20.0 else 0.07
		_wall(_w(u - 0.75, f), _w(u + 0.75, f), g + 4.2, g + 7.2, _b, ZACHETA_GLASS)
		_wall(_w(u - 0.8, f), _w(u + 0.8, f), g + 9.6, g + 13.0, _b, ZACHETA_GLASS)
		_wall(_w(u - 0.55, f), _w(u + 0.55, f), g + 0.7, g + 1.9, _b, ZACHETA_GLASS)
	for u: float in ZACHETA_DOORS:
		_wall(_w(u - 0.8, 0.07), _w(u + 0.8, 0.07), g + 9.6, g + 13.0, _b, ZACHETA_GLASS)
	_mode = M_STONE
	for u: float in ZACHETA_DOORS:
		_wall(_w(u - 0.95, 0.07), _w(u + 0.95, 0.07), g + 1.8, g + 6.8, _b, ZACHETA_DOOR)
	# body: the front in plain stone (its windows are its own), the other faces in M_MONUMENT
	var corners := [_w(u0, ZACHETA_BACK), _w(u1, ZACHETA_BACK), _w(u1, 0.0), _w(u0, 0.0)]
	var outs := [-_b, _a, _b, -_a]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		_wall(a, b, g - 0.5, g + 3.0, outs[i], ZACHETA_BASE.darkened(0.06))
		_wall(a, b, g + 3.0, g + 8.2, outs[i], ZACHETA_BASE)
		_mode = M_STONE if i == 2 else M_MONUMENT
		_wall(a, b, g + 8.2, g + 15.3, outs[i], ZACHETA_WHITE)
		_mode = M_STONE
	var band := _largest(Geometry2D.offset_polygon(body, 0.18, Geometry2D.JOIN_MITER))
	_prism(band, g + 8.2, g + 8.8, light, light, M_STONE, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(body, 0.5, Geometry2D.JOIN_MITER))
	_prism(eave, g + 14.6, g + 15.3, light, ZACHETA_ROOF, M_STONE, M_STONE)
	_parapet(body, g + 15.3, 1.3, ZACHETA_WHITE)
	# end pavilions: forward 0.5 m, an attic, an acroterion
	for p: Vector2 in [Vector2(u0 + 2.9, 0.0), Vector2(u1 - 2.9, 0.0)]:
		_lbox(p.x, 0.25, 2.9, 0.25, g - 0.5, g + 3.0, ZACHETA_BASE.darkened(0.06), M_STONE, ZACHETA_BASE)
		_lbox(p.x, 0.25, 2.9, 0.25, g + 3.0, g + 15.3, ZACHETA_WHITE, M_STONE, light)
		_lbox(p.x, -0.6, 2.4, 1.1, g + 15.3, g + 17.4, ZACHETA_WHITE, M_STONE, light)
		_pyramid(_rect(p.x, -0.6, 1.0, 0.7), g + 17.4, g + 19.2, ZACHETA_SCULPT)
	# pylons, columns on pedestals, the entablature, the ARTIBVS attic, the pediment
	for s: float in [-1.0, 1.0]:
		_lbox(s * 7.0, 0.6, 1.6, 0.6, g - 0.5, g + 17.0, ZACHETA_WHITE, M_STONE, light)
		_lbox(s * 2.2, 1.6, 0.9, 0.9, g - 0.5, g + 3.4, ZACHETA_BASE, M_STONE, ZACHETA_BASE.lightened(0.05))
		_column(s * 2.2, 1.6, 0.62, g + 3.4, g + 15.2, ZACHETA_COLUMN)
		# a candelabrum on its pedestal before each pylon
		_lbox(s * 7.0, 3.0, 0.7, 0.7, g - 0.5, g + 2.2, ZACHETA_BASE, M_STONE, ZACHETA_BASE)
		_lbox(s * 7.0, 3.0, 0.14, 0.14, g + 2.2, g + 5.6, ZACHETA_IRON, M_STONE, ZACHETA_IRON)
		_lbox(s * 7.0, 3.0, 0.7, 0.12, g + 5.0, g + 5.2, ZACHETA_IRON, M_STONE, ZACHETA_IRON)
		for k: float in [-0.7, 0.0, 0.7]:
			_mode = M_LAMP
			_prism(_rect(s * 7.0 + k, 3.0, 0.16, 0.16), g + 5.2 if k != 0.0 else g + 5.6, g + 5.6 if k != 0.0 else g + 6.0,
					Color("#f3e3b0"), Color("#f3e3b0"), M_LAMP, M_LAMP)
			_mode = M_STONE
	_lbox(0.0, 1.0, 8.6, 1.5, g + 15.2, g + 16.4, light, M_STONE, light)
	_lbox(0.0, 0.9, 8.6, 1.3, g + 16.4, g + 18.4, ZACHETA_WHITE, M_STONE, light)
	_lbox(0.0, 1.0, 9.6, 1.5, g + 18.4, g + 18.8, light, M_STONE, light)
	var keep_a := _a
	var keep_b := _b
	# The pediment faces +v: swap the frame so _gable's u runs out of the front.
	_a = keep_b
	_b = -keep_a
	_gable(2.5, -6.0, 0.0, 9.6, g + 18.8, 4.2, ZACHETA_WHITE, ZACHETA_ROOF)
	_a = keep_a
	_b = keep_b
	# the tympanum's sculpture: a tall group in the middle, lower groups to the corners
	for grp: Array in [[0.0, 1.3, 3.1], [-2.8, 1.2, 1.9], [2.8, 1.2, 1.9], [-5.6, 1.1, 0.9], [5.6, 1.1, 0.9]]:
		_lbox(grp[0], 2.65, grp[1], 0.2, g + 18.8, g + 18.8 + float(grp[2]), ZACHETA_SCULPT, M_STONE, ZACHETA_SCULPT)
	_beam(Vector3(_w(-9.8, 2.85).x, g + 18.75, _w(-9.8, 2.85).y), Vector3(_w(0.0, 2.85).x, g + 23.1, _w(0.0, 2.85).y), 0.45, light)
	# (the right one 6 cm further out: the two meet at the apex, and coplanar faces flicker)
	_beam(Vector3(_w(9.8, 2.91).x, g + 18.75, _w(9.8, 2.91).y), Vector3(_w(0.0, 2.91).x, g + 23.1, _w(0.0, 2.91).y), 0.45, light)
	# steps
	for k in 4:
		_lbox(0.0, (4.0 - k) * 0.5, 6.0, (4.0 - k) * 0.5, g - 0.5, g + 0.45 * (k + 1), ZACHETA_BASE, M_STONE,
				ZACHETA_BASE.lightened(0.04))
	# the halls behind: a raised block and its glass roof
	_lbox(-1.0, -22.0, 10.0, 14.0, g + 15.3, g + 19.0, ZACHETA_WHITE, M_STONE, none)
	_mode = M_GLASS_ROOF
	_frustum(_rect(-1.0, -22.0, 10.0, 14.0), g + 19.0, _rect(-1.0, -22.0, 0.3, 4.3), g + 23.8, ZACHETA_SKY, ZACHETA_SKY)
	_mode = M_STONE
	_collide(site["ring"])
	# the steps, the columns and the candelabra stand in front of the mapped outline
	_collide(_rect(0.0, 2.0, 7.8, 2.0))
	for s: float in [-1.0, 1.0]:
		_collide(_rect(s * 7.0, 3.0, 0.7, 0.7))


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

const PREZ := Vector2(-514.0, -1005.5)
const PREZ_AXIS := Vector2(-0.9089, 0.4170)
## Stone, roof and forecourt colours from the v2 parts table.
const PREZ_WALL := Color("#efe9da")
const PREZ_BASE := Color("#ddd6c4")
const PREZ_ROOF := Color("#7d8a87")
const PREZ_SLATE := Color("#7a7f84")  # mid grey, as the 3D Tiles views read it (Codex had #4a4e52, near black on the sheet)
const PREZ_PAVILION_ROOF := Color("#6b7275")
const PREZ_ARCH := Color("#4d4a42")
const PREZ_STATUES := Color("#e4ded0")
const PREZ_BRONZE := Color("#3a403c")
const PREZ_GRANITE := Color("#24262a")
const PREZ_LION := Color("#e6e0d2")
const PREZ_BOLLARD := Color("#ece6d8")
const PREZ_CHAIN := Color("#2a2c2e")
const PREZ_IRON := Color("#1f2224")
const PREZ_LANTERN := Color("#ffd9a0")
const PREZ_PLAQUE := Color("#f3ead6")
const PREZ_FLAG_WHITE := Color("#f2f2f2")
const PREZ_FLAG_RED := Color("#c8102e")
const PREZ_FRONT_U := 94.0
const PREZ_STATUE_U := 70.0
const PREZ_WING_EAVE := 10.5
const PREZ_WING_RISE := 4.2
const PREZ_BAY := 3.6


func _find_prezydencki() -> void:
	var outline := _landmark("Pałac Prezydencki")
	if outline.size() < 3:
		return
	# The zone is the hull: the LoD2 model is one run round the forecourt, its centre in it.
	_add_site("prezydencki", [Geometry2D.convex_hull(outline)])
	if not sites.is_empty() and sites[-1]["key"] == "prezydencki":
		sites[-1]["ring"] = outline


## Presidential Palace, spec v2 (2026-11-27), a whole model around the mapped forecourt.
## Builds the main block and risalit, both wings and street pavilions, and the forecourt's
## monument, lions, bollards and inner gate. The existing hull replaces the LoD2 mass.
func _build_prezydencki(site: Dictionary) -> void:
	_prez_frame()
	var court := _w(40.0, 0.0)
	_g = map.terrain_height(court.x, court.y)
	_mode = M_STONE
	_prez_main()
	_prez_annex()
	_prez_risalit()
	_prez_wing(84.0, -40.5, -25.5, -25.5)
	_prez_wing(88.0, 23.0, 40.0, 23.0)
	_prez_pavilion(84.0, -41.1, -24.9, -24.9)
	_prez_pavilion(88.0, 23.0, 40.6, 23.0)
	_prez_bollards()
	for v: float in [-11.0, -7.0, 7.0, 11.0]:
		_prez_lion(v)
	_prez_inner_fence()
	_prez_sentries()
	_prez_statue_base()
	_prez_horse_rider()
	_prez_plaques()
	_collide(site["ring"])


## Restores the site axes after a facade pass. +u points to the street and -v to the north.
func _prez_frame() -> void:
	_o = PREZ
	_a = PREZ_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	kit_face(0.0)


## The base and the upper walls share a seam. Each footing follows the lowest ground on its edge.
func _prez_masonry(ring: PackedVector2Array, base: float, top: float, detailed: Array[int]) -> void:
	for i in ring.size():
		var from := ring[i]
		var to := ring[(i + 1) % ring.size()]
		var out := _out(ring, from, to)
		_mode = M_STONE
		_wall(from, to, _prez_footing(from, to), _g + base, out, PREZ_BASE)
		# Monument mode supplies windows on the outside walls. The authored fronts use plain stone.
		_mode = M_STONE if i in detailed else M_MONUMENT
		_wall(from, to, _g + base, _g + top, out, PREZ_WALL)
	_mode = M_STONE


## Sink the bottom of a wall below grade on the palace's downhill garden side.
func _prez_footing(from: Vector2, to: Vector2) -> float:
	var low := _g - 0.6
	var n := maxi(1, ceili(from.distance_to(to) / 8.0))
	for i in n + 1:
		var p := from.lerp(to, float(i) / n)
		low = minf(low, map.terrain_height(p.x, p.y) - 0.3)
	return low


## Three floors and an attic above the main block's rusticated base, under a broad hipped top.
func _prez_main() -> void:
	var ring := _urect(-25.0, 0.0, -41.0, 42.0)
	var from := _w(0.0, 42.0)
	var to := _w(0.0, -41.0)
	kit_front(from, to)
	# Fifteen bays per side fit between the risalit and the outer end. The panes share sill courses.
	for span: Vector2 in [Vector2(0.0, 28.0), Vector2(56.0, 83.0)]:
		var visible := Vector2(19.0, 28.0) if span.x == 0.0 else Vector2(56.0, 67.5)
		kit_bands(visible.x, visible.y, _g, _g + 4.0, 0.98, PREZ_BASE)
		var bays: Array[float] = []
		var exposed: Array[float] = []
		for i in 15:
			var u := lerpf(span.x, span.y, (i + 0.5) / 15.0)
			bays.append(u)
			if u >= visible.x and u <= visible.y:
				exposed.append(u)
		kit_panes(exposed, [_g + 1.0], 0.95, 2.1, PREZ_ARCH, 0.075)
		kit_panes(exposed, [_g + 4.55], 1.05, 2.7, PAL_GLASS_DARK)
		kit_panes(exposed, [_g + 8.0], 1.05, 2.2, PAL_GLASS_DARK)
		kit_panes(bays, [_g + 10.95], 1.0, 1.75, PAL_GLASS_DARK)
		kit_panes(bays, [_g + 13.55], 0.85, 0.95, PAL_GLASS_DARK)
		for sill: float in [4.35, 7.8]:
			kit_ledge(visible.x, visible.y, _g + sill, 0.13, PREZ_WALL)
		for sill: float in [10.75, 13.35]:
			kit_ledge(span.x, span.y, _g + sill, 0.13, PREZ_WALL)
		var pilaster := 22.4 if span.x == 0.0 else 61.4
		kit_pilaster(pilaster, _g + 4.18, _g + 13.21, PREZ_WALL, 0.42, 0.16)
		kit_face(0.14)
		kit_attic(span.x + 0.16, span.y - 0.1, _g + 15.5, PREZ_WALL, 1.0, Attic.WALL)
		kit_face(0.0)
	_prez_frame()
	_prez_masonry(ring, 4.0, 15.5, [1])
	kit_cornice_ring(ring, _g + 15.05, PREZ_WALL, 0.45, 0.4)
	_prez_roof(ring, _rect(-12.5, 0.5, 7.0, 35.5), _g + 15.5, _g + 20.5, PREZ_ROOF)
	for v: float in [-21.0, 24.0]:
		_lbox(-15.0, v, 0.4, 0.75, _g + 20.49, _g + 21.25, PREZ_ROOF.lightened(0.12))


## The low garden annex joins the south end of the main block under its own hip.
func _prez_annex() -> void:
	var ring := _urect(-25.0, -14.0, 42.0, 50.0)
	_prism(ring, _prez_footing(ring[3], ring[0]), _g + 12.0, PREZ_WALL, Color(0, 0, 0, 0), M_MONUMENT)
	kit_cornice_ring(ring, _g + 11.6, PREZ_WALL, 0.4, 0.3)
	_prez_roof(ring, _rect(-19.5, 46.0, 1.65, 0.15), _g + 12.0, _g + 15.0, PREZ_ROOF)


## Both long wings use the same cadence on their courtyard faces and carry flat slate dormers.
func _prez_wing(length: float, v0: float, v1: float, court_v: float) -> void:
	var ring := _urect(0.0, length, v0, v1)
	var faces_positive_v := court_v == v1
	var from := _w(0.0 if faces_positive_v else length, court_v)
	var to := _w(length if faces_positive_v else 0.0, court_v)
	var width := kit_front(from, to)
	var count := floori(width / PREZ_BAY)
	var first := (width - (count - 1) * PREZ_BAY) * 0.5
	_prez_wing_gf(width, first, count)
	_prez_wing_upper(width, first, count)
	_prez_wing_lanterns(first, count)
	_prez_frame()
	_prez_masonry(ring, 4.2, PREZ_WING_EAVE, [2 if faces_positive_v else 0])
	kit_cornice_ring(ring, _g + 10.03, PREZ_WALL, 0.47, 0.45)
	_prez_wing_roof(length, v0, v1, court_v)


## The arches sit forward of the rustication so the horizontal grooves are behind the surrounds.
func _prez_wing_gf(width: float, first: float, count: int) -> void:
	kit_bands(0.04, width - 0.04, _g, _g + 4.2, 1.04, PREZ_BASE)
	for i in count:
		var u := first + i * PREZ_BAY
		kit_round_window(_w(u, 0.035), _a, _b, _g + 0.85, _g + 2.75, 0.7, PREZ_BASE.lightened(0.09))


## Individual heads and sills alternate with paired sash panes on continuous stone courses.
func _prez_wing_upper(width: float, first: float, count: int) -> void:
	kit_ledge(0.04, width - 0.04, _g + 4.38, 0.12, PREZ_WALL, 0.11)
	kit_ledge(0.04, width - 0.04, _g + 7.38, 0.15, PREZ_WALL, 0.11)
	kit_ledge(0.04, width - 0.04, _g + 9.9, 0.1, PREZ_WALL, 0.13)
	for i in count:
		var u := first + i * PREZ_BAY
		if i % 3 == 0:
			kit_window(u, _g + 4.7, 2.3, Win.SILL_HEAD, PREZ_WALL, PAL_GLASS_DARK, 0.65)
		else:
			kit_panes([u - 0.35, u + 0.35], [_g + 4.7], 0.6, 2.3, PAL_GLASS_DARK)
		if i % 3 == 1:
			kit_window(u, _g + 7.75, 1.9, Win.SILL_HEAD, PREZ_WALL, PAL_GLASS_DARK, 0.65)
		else:
			kit_panes([u - 0.35, u + 0.35], [_g + 7.75], 0.6, 1.9, PAL_GLASS_DARK)


## A shallow four-sided wall fixture with a dark iron hood over its warm, emissive glass.
func _prez_wing_lanterns(first: float, count: int) -> void:
	for i in range(0, count - 1, 2):
		var u := first + (i + 0.5) * PREZ_BAY
		var glass := _rect(u, 0.12, 0.12, 0.15)
		var hood := _rect(u, 0.12, 0.15, 0.15)
		_prism(glass, _g + 2.35, _g + 2.72, PREZ_LANTERN, Color(0, 0, 0, 0), M_LAMP)
		_pyramid(hood, _g + 2.72, _g + 2.85, PREZ_IRON)


## The dormers follow the central run of the hip, with their cheeks buried up the slope.
func _prez_wing_roof(length: float, v0: float, v1: float, court_v: float) -> void:
	var half_width := (v1 - v0) * 0.5
	var shoulder := half_width - 0.15
	var ridge := _rect(length * 0.5, (v0 + v1) * 0.5, length * 0.5 - shoulder, 0.15)
	_prez_roof(_urect(0.0, length, v0, v1), ridge, _g + PREZ_WING_EAVE,
			_g + PREZ_WING_EAVE + PREZ_WING_RISE, PREZ_SLATE)
	var inward := signf((v0 + v1) * 0.5 - court_v)
	var setback := 2.4
	var roof_y := _g + PREZ_WING_EAVE + PREZ_WING_RISE * setback / shoulder
	var from := _w(0.0 if inward < 0.0 else length, court_v + inward * setback)
	var to := _w(length if inward < 0.0 else 0.0, court_v + inward * setback)
	kit_front(from, to)
	var count := floori((length - half_width - 9.6) / (2.0 * PREZ_BAY)) + 1
	for i in count:
		var u := 9.6 + i * 2.0 * PREZ_BAY
		var front_left := _prez_point(u - 0.6, 0.0, roof_y + 1.0)
		var front_right := _prez_point(u + 0.6, 0.0, roof_y + 1.0)
		var back_left := _prez_point(u - 0.6, -2.0, roof_y + 1.0)
		var back_right := _prez_point(u + 0.6, -2.0, roof_y + 1.0)
		var foot := roof_y - 0.03
		var cheek := PREZ_SLATE.lightened(0.18)
		var along := Vector3(_a.x, 0.0, _a.y)
		_wall(_w(u - 0.6, 0.0), _w(u + 0.6, 0.0), foot, roof_y + 1.0, _b, cheek)
		_tri(front_left, back_left, _prez_point(u - 0.6, 0.0, foot), -along, cheek,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		_tri(front_right, back_right, _prez_point(u + 0.6, 0.0, foot), along, cheek,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		_quad(front_left, front_right, back_right, back_left, Vector3.UP, PREZ_SLATE.lightened(0.09))
		kit_panes([u], [roof_y + 0.18], 0.8, 0.58, PAL_GLASS_DARK)
	_prez_frame()


## A hip with roof UVs so the palace floodlight shader lights the walls below it.
func _prez_roof(eaves: PackedVector2Array, ridge: PackedVector2Array, y0: float, y1: float, col: Color) -> void:
	for i in eaves.size():
		var j := (i + 1) % eaves.size()
		var a := Vector3(eaves[i].x, y0, eaves[i].y)
		var b := Vector3(eaves[j].x, y0, eaves[j].y)
		var c := Vector3(ridge[j].x, y1, ridge[j].y)
		var d := Vector3(ridge[i].x, y1, ridge[i].y)
		var n := (b - a).cross(d - a).normalized()
		_quad(a, b, c, d, n if n.y > 0.0 else -n, col)
	_cap(ridge, y1, col)


## The pavilions continue the wings with two bays on the court and gables ending at the street.
func _prez_pavilion(start: float, v0: float, v1: float, court_v: float) -> void:
	var end := start + 8.0
	var ring := _urect(start, end, v0, v1)
	var faces_positive_v := court_v == v1
	var from := _w(start if faces_positive_v else end, court_v)
	var to := _w(end if faces_positive_v else start, court_v)
	kit_front(from, to)
	_prez_wing_gf(8.0, 2.2, 2)
	_prez_wing_upper(8.0, 2.2, 2)
	_prez_wing_lanterns(2.2, 2)
	_prez_frame()
	_prez_pavilion_front(end, v0, v1)
	_prez_masonry(ring, 4.2, 12.7, [1, 2 if faces_positive_v else 0])
	kit_cornice_ring(ring, _g + 12.0, PREZ_WALL, 0.7, 0.45)
	_gable(end, start - 0.05, (v0 + v1) * 0.5, (v1 - v0) * 0.5 + 0.35,
			_g + 12.7, 3.2, PREZ_WALL, PREZ_PAVILION_ROOF, true)


## The street temple front has pilasters rising past the three balcony bays to a plain tympanum.
func _prez_pavilion_front(end: float, v0: float, v1: float) -> void:
	var width := kit_front(_w(end, v1), _w(end, v0))
	var mid := width * 0.5
	kit_bands(0.04, width - 0.04, _g, _g + 4.2, 1.04, PREZ_BASE)
	kit_face(0.035)
	kit_door(mid, _g + 0.12, 3.34, 0.9, PREZ_BASE.lightened(0.09), PREZ_ARCH, true)
	kit_face(0.0)
	for x: float in [-2.65, 2.65]:
		kit_round_window(_w(mid + x, 0.035), _a, _b, _g + 0.85, _g + 2.75, 0.7, PREZ_BASE.lightened(0.09))
	for x: float in [-4.25, -1.35, 1.35, 4.25]:
		kit_pilaster(mid + x, _g + 4.15, _g + 11.66, PREZ_WALL, 0.72, 0.19)
	kit_ledge(mid - 4.85, mid + 4.85, _g + 11.65, 0.38, PREZ_WALL, 0.27)
	# The balcony's back overlaps the pilasters, which join it to the wall.
	kit_balcony(mid, _g + 4.69, 3.5, Balcony.IRON, PREZ_IRON, PREZ_WALL, 0.84)
	for x: float in [-6.1, -2.65, 0.0, 2.65, 6.1]:
		kit_panes([mid + x], [_g + 4.75], 1.18, 2.65, PAL_GLASS_DARK)
		kit_panes([mid + x], [_g + 8.4], 1.18, 2.08, PAL_GLASS_DARK)
	kit_pediment(mid, mid + 0.35, _g + 12.7, 3.2, PREZ_WALL, PREZ_PAVILION_ROOF, 0.38)
	_prez_frame()


## Seven dark arches under engaged Corinthian columns, with the centre of the balustrade stepped out.
func _prez_risalit() -> void:
	var ring := _urect(0.0, 1.2, -14.0, 14.0)
	kit_front(_w(1.2, 14.0), _w(1.2, -14.0))
	kit_bands(0.03, 27.97, _g, _g + 4.0, 0.98, PREZ_BASE)
	for u: float in [2.0, 6.0, 10.0, 14.0, 18.0, 22.0, 26.0]:
		_arch_panel(_w(u, 0.035), _a, _b, 1.22, _g + 0.12, _g + 2.4, PREZ_WALL, 0.03, M_STONE)
		_arch_panel(_w(u, 0.035), _a, _b, 1.1, _g + 0.2, _g + 2.4, PREZ_ARCH, 0.07, M_GLASS)
		kit_panes([u], [_g + 5.3], 1.4, 3.15, PAL_GLASS_DARK)
		kit_panes([u], [_g + 9.75], 1.4, 2.65, PAL_GLASS_DARK)
		kit_panes([u], [_g + 13.58], 1.1, 0.95, PAL_GLASS_DARK)
	kit_ledge(0.03, 27.97, _g + 4.0, 0.23, PREZ_WALL, 0.38)
	# The shafts remain engaged in the masonry at this depth.
	for u: float in [2.5, 7.1, 11.7, 16.3, 20.9, 25.5]:
		kit_column(u, 0.25, _g + 4.2, _g + 15.4, PREZ_WALL, 0.5, Order.CORINTHIAN)
	kit_cornice_ring(ring, _g + 15.78, PREZ_WALL, 0.62, 0.32)
	kit_face(0.08)
	kit_attic(0.06, 27.94, _g + 16.4, PREZ_WALL)
	_prez_frame()
	_prez_masonry(ring, 4.0, 16.4, [1])
	# The risalit roof ties the crown back into the main roof slope.
	_cap(_urect(-1.2, 1.2, -14.0, 14.0), _g + 16.36, PREZ_ROOF)
	_prez_figures()
	_prez_flags()


## Stone figures on low square plinths accent the columns and the outer balustrade.
func _prez_figures() -> void:
	for v: float in [-38.0, -27.0, -11.5, -6.9, -2.3, 2.3, 6.9, 11.5, 27.0, 38.0]:
		var central := absf(v) < 14.0
		var u := 1.26 if central else 0.12
		var y := _g + (17.4 if central else 16.5)
		_lbox(u, v, 0.28, 0.29, y, y + 0.5, PREZ_WALL)
		_frustum(_rect(u, v, 0.2, 0.22), y + 0.5, _rect(u + 0.03, v, 0.15, 0.16),
				y + 1.98, PREZ_STATUES, PREZ_STATUES)
		_lbox(u + 0.06, v, 0.105, 0.11, y + 1.98, y + 2.4, PREZ_STATUES)


## Twin poles carry Polish flags in two horizontal bands, visible from either side.
func _prez_flags() -> void:
	for v: float in [-4.0, 4.0]:
		var foot := _g + 17.39
		var u := 1.06
		_beam(_prez_point(u, v, foot), _prez_point(u, v, foot + 6.0), 0.085, PREZ_FLAG_WHITE, false)
		_two_sided(_prez_point(u, v, foot + 5.32), _prez_point(u, v + 1.8, foot + 5.32),
				_prez_point(u, v + 1.8, foot + 5.87), _prez_point(u, v, foot + 5.87), PREZ_FLAG_WHITE)
		_two_sided(_prez_point(u, v, foot + 4.77), _prez_point(u, v + 1.8, foot + 4.77),
				_prez_point(u, v + 1.8, foot + 5.32), _prez_point(u, v, foot + 5.32), PREZ_FLAG_RED)


## Square bollards and three-segment chains replace the street fence and keep the entrance open.
func _prez_bollards() -> void:
	for row: Array in [[-25.0, -22.5, -18.0, -13.5, -9.0], [9.0, 13.5, 18.0, 22.5]]:
		for i in row.size():
			var v: float = row[i]
			_lbox(PREZ_FRONT_U, v, 0.225, 0.225, _g - 0.6, _g + 1.1, PREZ_BOLLARD)
			if i == 0:
				continue
			var prev: float = row[i - 1]
			var a := _prez_point(PREZ_FRONT_U, prev + 0.2, _g + 0.92)
			var b := _prez_point(PREZ_FRONT_U, lerpf(prev, v, 0.28), _g + 0.67)
			var c := _prez_point(PREZ_FRONT_U, lerpf(prev, v, 0.72), _g + 0.67)
			var d := _prez_point(PREZ_FRONT_U, v - 0.2, _g + 0.92)
			_beam(a, b, 0.058, PREZ_CHAIN, false)
			_beam(b, c, 0.058, PREZ_CHAIN, false)
			_beam(c, d, 0.058, PREZ_CHAIN, false)
		var first: float = row.front()
		var last: float = row.back()
		_collide(_urect(PREZ_FRONT_U - 0.17, PREZ_FRONT_U + 0.17, first, last))


## Each reclining lion faces the street, with its paws and tail lying on the long plinth.
func _prez_lion(v: float) -> void:
	var u := PREZ_FRONT_U
	var y := _g + 1.6
	var ring := _rect(u, v, 1.4, 0.65)
	_prism(_rect(u, v, 1.36, 0.61), _g - 0.65, y - 0.16, PREZ_BOLLARD, Color(0, 0, 0, 0))
	_prism(ring, y - 0.16, y, PREZ_LION, PREZ_LION)
	_frustum(_prez_oval_ring(u - 0.33, v, 0.875, 0.42), y,
			_prez_oval_ring(u - 0.23, v, 0.76, 0.31), y + 0.67, PREZ_LION, PREZ_LION)
	_frustum(_prez_oval_ring(u + 0.41, v, 0.37, 0.42), y + 0.2,
			_prez_oval_ring(u + 0.5, v, 0.36, 0.33), y + 0.98, PREZ_LION.darkened(0.07), PREZ_LION)
	_lbox(u + 0.81, v, 0.25, 0.24, y + 0.62, y + 1.01, PREZ_LION)
	_lbox(u + 1.04, v, 0.13, 0.154, y + 0.63, y + 0.81, PREZ_LION.lightened(0.04))
	for side: float in [-1.0, 1.0]:
		_lbox(u + 0.79, v + 0.235 * side, 0.405, 0.11, y, y + 0.23, PREZ_LION)
		_pyramid(_rect(u + 0.65, v + 0.18 * side, 0.073, 0.065), y + 0.97, y + 1.09, PREZ_LION)
	_beam(_prez_point(u - 1.08, v - 0.24, y + 0.35), _prez_point(u - 0.84, v - 0.49, y + 0.09), 0.11, PREZ_LION)
	_beam(_prez_point(u - 0.88, v - 0.49, y + 0.08), _prez_point(u - 0.29, v - 0.38, y + 0.07), 0.11, PREZ_LION)
	_collide(ring)


## The inner railings meet the wings and stop at dressed stone piers on either side of the drive.
func _prez_inner_fence() -> void:
	var u := 22.0
	for span: Vector2 in [Vector2(-25.53, -5.44), Vector2(5.44, 23.03)]:
		for h: float in [0.45, 2.38]:
			_beam(_prez_point(u, span.x, _g + h), _prez_point(u, span.y, _g + h), 0.085, PREZ_IRON, false)
		var posts := ceili((span.y - span.x) / 2.2)
		for i in posts:
			var v := lerpf(span.x, span.y, (i + 0.5) / posts)
			_prism(_rect(u, v, 0.047, 0.047), _g - 0.55, _g + 2.49, PREZ_IRON, Color(0, 0, 0, 0))
			_mode = M_GOLD
			_pyramid(_rect(u, v, 0.061, 0.061), _g + 2.49, _g + 2.6, PAL_GOLD)
			_mode = M_STONE
			if i == posts - 1:
				continue
			var picket := lerpf(span.x, span.y, float(i + 1) / posts)
			_two_sided(_prez_point(u, picket - 0.028, _g + 0.45), _prez_point(u, picket + 0.028, _g + 0.45),
					_prez_point(u, picket + 0.028, _g + 2.4), _prez_point(u, picket - 0.028, _g + 2.4), PREZ_IRON)
		_collide(_urect(u - 0.14, u + 0.14, span.x, span.y))
	for v: float in [-5.5, 5.5]:
		_lbox(u, v, 0.5, 0.5, _g - 0.7, _g + 0.38, PREZ_BASE)
		_lbox(u, v, 0.4, 0.41, _g + 0.38, _g + 3.14, PREZ_WALL)
		_lbox(u, v, 0.51, 0.5, _g + 3.14, _g + 3.4, PREZ_WALL)
		_collide(_rect(u, v, 0.5, 0.5))


## Two small sentry boxes stand just inside the open gate below grey pyramid roofs.
func _prez_sentries() -> void:
	for v: float in [-7.0, 7.0]:
		var ring := _rect(20.0, v, 0.7, 0.7)
		kit_front(_w(20.7, v + 0.7), _w(20.7, v - 0.7))
		kit_door(0.7, _g + 0.03, 1.83, 0.27, PREZ_WALL, PREZ_IRON)
		_prez_frame()
		_prism(ring, _g - 0.65, _g + 2.14, PREZ_WALL, Color(0, 0, 0, 0), M_MONUMENT)
		_pyramid(_rect(20.0, v, 0.77, 0.77), _g + 2.14, _g + 2.6, PREZ_PAVILION_ROOF)
		_collide(ring)


## Two low cream information panels stand on iron legs at the street side of the monument.
func _prez_plaques() -> void:
	for v: float in [-3.0, 3.0]:
		for dv: float in [-0.44, 0.44]:
			_lbox(88.0, v + dv, 0.055, 0.055, _g - 0.55, _g + 0.66, PREZ_IRON)
		_lbox(88.0, v, 0.055, 0.6, _g + 0.66, _g + 1.56, PREZ_PLAQUE, M_LAMP)


## The polished granite pedestal has a stepped foot and a lighter cap over its inscription band.
func _prez_statue_base() -> void:
	var u := PREZ_STATUE_U
	_lbox(u, 0.0, 2.6, 1.5, _g - 0.68, _g + 0.32, PREZ_GRANITE.lightened(0.09))
	_lbox(u, 0.0, 2.34, 1.3, _g + 0.32, _g + 3.9, PREZ_GRANITE)
	_lbox(u, 0.0, 2.48, 1.42, _g + 3.9, _g + 4.2, PREZ_GRANITE.lightened(0.14))
	_mode = M_STONE
	_wall(_w(u + 2.37, 0.73), _w(u + 2.37, -0.73), _g + 3.08, _g + 3.36, _a, PREZ_GRANITE.darkened(0.2))
	_collide(_rect(u, 0.0, 2.6, 1.5))


## The horse walks toward the street with one bent foreleg. The rider holds the sword low ahead.
func _prez_horse_rider() -> void:
	var u := PREZ_STATUE_U
	var y := _g + 4.2
	var bronze := PREZ_BRONZE
	var belly := _prez_oval_ring(u - 0.24, 0.0, 0.97, 0.33)
	var barrel := _prez_oval_ring(u - 0.27, 0.0, 1.06, 0.42)
	_frustum(belly, y + 0.99, barrel, y + 1.37, bronze)
	_frustum(barrel, y + 1.37, _prez_oval_ring(u - 0.27, 0.0, 0.89, 0.29), y + 1.84, bronze, bronze)
	for side: float in [-1.0, 1.0]:
		var v := side * 0.26
		var hoof := u - 0.85 - side * 0.28
		var hock := _prez_point(u - 1.04, v, y + 0.57)
		_beam(_prez_point(u - 0.94, v, y + 1.37), hock, 0.25, bronze)
		_beam(hock, _prez_point(hoof, v, y + 0.06), 0.13, bronze)
		_lbox(hoof, v, 0.1, 0.08, y, y + 0.11, bronze)
	var knee := _prez_point(u + 0.76, -0.24, y + 0.69)
	_beam(_prez_point(u + 0.51, -0.24, y + 1.34), knee, 0.21, bronze)
	_beam(knee, _prez_point(u + 0.97, -0.24, y + 0.34), 0.13, bronze)
	_beam(_prez_point(u + 0.44, 0.24, y + 1.36), _prez_point(u + 0.31, 0.24, y + 0.07), 0.17, bronze)
	_lbox(u + 0.31, 0.24, 0.105, 0.09, y, y + 0.11, bronze)
	var crest := _prez_oval_ring(u + 0.88, 0.0, 0.22, 0.18)
	_frustum(_prez_oval_ring(u + 0.56, 0.0, 0.47, 0.29), y + 1.28, crest, y + 2.44, bronze)
	_frustum(_prez_oval_ring(u + 1.21, 0.0, 0.25, 0.13), y + 1.88,
			_prez_oval_ring(u + 1.0, 0.0, 0.25, 0.19), y + 2.38, bronze, bronze)
	for v: float in [-0.13, 0.13]:
		_beam(_prez_point(u + 0.87, v, y + 2.29), _prez_point(u + 0.81, v, y + 2.61), 0.085, bronze)
	var tail := _prez_point(u - 1.35, 0.04, y + 0.86)
	_beam(_prez_point(u - 1.13, 0.0, y + 1.67), tail, 0.19, bronze)
	_beam(tail, _prez_point(u - 1.28, 0.18, y + 0.29), 0.14, bronze)
	var tunic := _prez_oval_ring(u - 0.26, 0.0, 0.23, 0.27)
	_frustum(tunic, y + 1.65, _prez_oval_ring(u - 0.22, 0.0, 0.17, 0.2), y + 1.98, bronze)
	_frustum(_prez_oval_ring(u - 0.22, 0.0, 0.17, 0.2), y + 1.98,
			_prez_oval_ring(u - 0.21, 0.0, 0.21, 0.28), y + 2.67, bronze, bronze)
	_frustum(_prez_oval_ring(u - 0.17, 0.0, 0.095, 0.095), y + 2.62,
			_prez_oval_ring(u - 0.13, 0.0, 0.15, 0.14), y + 2.83, bronze)
	_prism(_prez_oval_ring(u - 0.12, 0.0, 0.15, 0.14), y + 2.83, y + 3.15, bronze, bronze)
	for side: float in [-1.0, 1.0]:
		var v := side * 0.35
		var rider_knee := _prez_point(u + 0.11, v, y + 1.56)
		_beam(_prez_point(u - 0.27, v * 0.7, y + 1.86), rider_knee, 0.23, bronze)
		_beam(rider_knee, _prez_point(u - 0.04, v, y + 1.15), 0.13, bronze)
	_beam(_prez_point(u - 0.21, 0.2, y + 2.55), _prez_point(u + 0.77, 0.16, y + 2.11), 0.15, bronze)
	var hand := _prez_point(u + 0.28, -0.5, y + 2.14)
	_beam(_prez_point(u - 0.21, -0.21, y + 2.53), hand, 0.15, bronze)
	_beam(hand, _prez_point(u + 1.65, -0.59, y + 1.76), 0.056, bronze.lightened(0.12))


## Eight-point horizontal rings keep the animal silhouettes faceted at game scale.
func _prez_oval_ring(u: float, v: float, hu: float, hv: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for i in 8:
		var angle := TAU * i / 8.0
		ring.append(_w(u + hu * cos(angle), v + hv * sin(angle)))
	return ring


## A Palace-frame plan point lifted to an absolute height for beams and flag panels.
func _prez_point(u: float, v: float, y: float) -> Vector3:
	var pos := _w(u, v)
	return Vector3(pos.x, y, pos.y)

# --- Plac Piłsudskiego from photos (2026-11-02) ----------------------------------------------------

## The square's monuments and masts, from the reference set F's Mac gathered (refs/pilsudskiego/:
## 6 Commons photos and the GUGiK ortho; docs/landmarks/photo-reports/pilsudskiego.md), in place
## of the generic OSM pieces (tools/bake_monuments.py SKIP). Spec docs/landmarks/specs/plac_pilsudskiego.md.
## The paving's chequer is the ground shader's (`plac_at`). No humour on any of them.
## Pomnik Ofiar Tragedii Smoleńskiej 2010 (2018): a polished black stone stair seen from the side,
## sheer on the west, stepped down to the east, ~10 m tall, 4 m deep, 6 m long, on a low base of
## glass and water. The spot is the ortho's (OSM (-761, -736)).
const SMOLENSK := Vector2(-765.0, -737.0)
const SMOLENSK_BLACK := Color("#1e1e22")
const SMOLENSK_GLASS := Color("#2b3a42")
## Józef Piłsudski (Tadeusz Łodziana, 1995): the marshal in a greatcoat, both hands on the sabre, on
## a rough granite block; OSM's spot (in the ortho's censored part), facing the square.
const PILSUDSKI := Vector2(-673.3, -817.8)
## Lech Kaczyński (2021): a standing bronze on a stepped pedestal of dark granite, which OSM maps
## as two 2.5 m "buildings" (x -681.7..-672.3, z -768..-756.7) beside its statue node (-671.3,
## -762.7); the model replaces them. The report read a statue's shadow at (-745, -823): that is
## the Papal Cross's (OSM (-738, -817)).
const KACZYNSKI := Vector2(-677.0, -762.3)
const PLAC_CENTRE := Vector2(-780.0, -800.0)
const PLAC_BRONZE := Color("#4a4f46")
const PLAC_GRANITE := Color("#8f8d88")
const PLAC_DARK_GRANITE := Color("#2e3032")
## The masts round the paved field (photo 1: about ten thin poles), five along each long side.
const PLAC_MASTS := [Vector2(-832.0, -863.0), Vector2(-806.0, -864.0), Vector2(-780.0, -864.5), Vector2(-754.0, -865.0),
		Vector2(-741.0, -864.0), Vector2(-832.0, -741.0), Vector2(-806.0, -740.5), Vector2(-786.0, -740.0),
		Vector2(-744.0, -739.5), Vector2(-724.0, -739.0)]
const PLAC_MAST_H := 14.0


func _find_plac_photos() -> void:
	_add_site("smolensk", [_circle(SMOLENSK, 7.4, 12)])
	_add_site("pilsudski", [_circle(PILSUDSKI, 2.2, 10)])
	_add_site("kaczynski", [_circle(KACZYNSKI, 6.6, 12)])
	var zones: Array = []
	for p: Vector2 in PLAC_MASTS:
		zones.append(_circle(p, 0.4, 6))
	_add_site("plac_maszty", zones)
	_find_plac_centralny()


## The frame of a statue on `at` facing the square: +v towards it.
func _plac_frame(at: Vector2) -> void:
	_o = at
	_b = (PLAC_CENTRE - at).normalized()
	_a = Vector2(_b.y, -_b.x)


func _build_smolensk(_site: Dictionary) -> void:
	_o = SMOLENSK
	_a = Vector2(0.0, -1.0)  # u north along its 6 m length
	_b = Vector2(1.0, 0.0)   # +v east, where the steps come down
	_g = map.terrain_height(SMOLENSK.x, SMOLENSK.y)
	var g := _g
	_mode = M_STONE
	_lbox(0.0, 0.0, 4.5, 3.6, g - 0.4, g + 0.25, SMOLENSK_GLASS, M_STONE, SMOLENSK_GLASS.lightened(0.15))
	_lbox(0.0, 0.0, 3.4, 2.4, g + 0.25, g + 0.3, SMOLENSK_BLACK, M_STONE, Color("#4c6670"))  # the water film
	var steps := 8
	var rise := 9.7 / steps
	for k in steps:  # sheer at v = -2, each step 0.5 m shorter towards the east
		var v1 := 2.0 - 0.5 * k
		_lbox(0.0, (-2.0 + v1) * 0.5, 3.0, (v1 + 2.0) * 0.5, g + 0.3 + rise * k, g + 0.3 + rise * (k + 1),
				SMOLENSK_BLACK, M_STONE, SMOLENSK_BLACK.lightened(0.06))
	_collide(_rect(0.0, 0.0, 7.0, 7.0))  # a car keeps clear of the base (the check tests from its tallest cell, 4 m off the middle)


func _build_pilsudski(_site: Dictionary) -> void:
	_plac_frame(PILSUDSKI)
	_g = map.terrain_height(PILSUDSKI.x, PILSUDSKI.y)
	var g := _g
	_mode = M_STONE
	_lbox(0.0, 0.0, 1.6, 1.6, g - 0.3, g + 0.25, PLAC_GRANITE.darkened(0.1), M_STONE, PLAC_GRANITE)
	# the rough block, a little uneven, the lettering panel and the two eagle badges
	_frustum(_rect(0.0, 0.0, 1.3, 1.25), g + 0.25, _rect(0.05, 0.0, 1.15, 1.1), g + 3.1, PLAC_GRANITE, PLAC_GRANITE.lightened(0.05))
	_lbox(0.0, 1.2, 0.8, 0.04, g + 1.6, g + 2.4, PLAC_GRANITE.lightened(0.18), M_STONE, PLAC_GRANITE)
	for su: float in [-1.0, 1.0]:
		_lbox(su * 1.05, 1.12, 0.22, 0.06, g + 2.5, g + 2.95, PLAC_BRONZE, M_STONE, PLAC_BRONZE)
	_kp_figure(0.0, 0.0, g + 3.1, 3.4, PLAC_BRONZE)
	_lbox(0.0, 0.45, 0.05, 0.05, g + 3.1, g + 4.8, PLAC_BRONZE, M_STONE, PLAC_BRONZE)  # the sabre under his hands
	_lbox(0.0, 0.38, 0.22, 0.12, g + 4.7, g + 4.9, PLAC_BRONZE, M_STONE, PLAC_BRONZE)
	_collide(_rect(0.0, 0.0, 1.6, 1.6))


func _build_kaczynski(_site: Dictionary) -> void:
	_plac_frame(KACZYNSKI)
	_g = map.terrain_height(KACZYNSKI.x, KACZYNSKI.y)
	var g := _g
	_mode = M_STONE
	_lbox(0.0, 0.0, 4.8, 5.4, g - 0.3, g + 0.8, PLAC_DARK_GRANITE, M_STONE, PLAC_DARK_GRANITE.lightened(0.08))
	_lbox(0.0, 0.0, 3.4, 3.9, g + 0.8, g + 1.65, PLAC_DARK_GRANITE, M_STONE, PLAC_DARK_GRANITE.lightened(0.1))
	_lbox(0.0, 0.0, 2.0, 2.3, g + 1.65, g + 2.5, PLAC_DARK_GRANITE, M_STONE, PLAC_DARK_GRANITE.lightened(0.12))
	_kp_figure(0.0, 0.0, g + 2.5, 3.6, PLAC_BRONZE)
	_collide(_rect(0.0, 0.0, 4.8, 5.4))


func _build_plac_masts(_site: Dictionary) -> void:
	_mode = M_STONE
	for p: Vector2 in PLAC_MASTS:
		_g = map.terrain_height(p.x, p.y)
		var g := _g
		_prism(_circle(p, 0.28, 6), g - 0.3, g + 0.6, PLAC_GRANITE, PLAC_GRANITE, M_STONE, M_STONE)
		_frustum(_circle(p, 0.13, 6), g + 0.6, _circle(p, 0.08, 6), g + PLAC_MAST_H, Color("#9a9c9e"), Color("#9a9c9e"))
		_prism(_circle(p, 0.2, 6), g + PLAC_MAST_H, g + PLAC_MAST_H + 0.4, Color("#f4eedc"), Color("#f4eedc"), M_LAMP, M_LAMP)
		_o = p
		_a = Vector2(1.0, 0.0)
		_b = Vector2(0.0, 1.0)
		_collide(_rect(0.0, 0.0, 0.3, 0.3))


# --- Plac Centralny (F's photos, 2026-11-05; the tribune and the field's place, 2026-11-08) ---------

func _find_plac_centralny() -> void:
	_pcz_frame()
	var f := PCZ_FIELD
	_add_site("plac_centralny", [_rect(f.get_center().x, f.get_center().y, f.size.x * 0.5, f.size.y * 0.5)])
	_add_site("trybuna", [_rect(-2.0, 2.8, 12.6, 7.4)])
	var zones: Array = []
	for l: Array in PCZ_LAMPS:
		zones.append(_circle(_pcz_world(l[0], l[1]), 0.8, 6))
	_add_site("plac_centralny_lamps", zones)


# --- Dom bez Kantów and Królewska 2: the block on the square's south-east corner (2026-11-15) ---

## The long block between Królewska, the street along the square's east side, Tokarzewskiego-
## Karaszewicza and Krakowskie Przedmieście, round a courtyard (F's photos 2026-11-15, an
## orthophoto of the roofs; spec docs/landmarks/specs/bez_kantow.md). Two buildings stand in it:
## Dom bez Kantów (1933-35, the Ministry of Military Affairs' housing block, six storeys of pale
## sandstone over an arcade, every corner rounded: OpenStreetMap's outline holds its south-east
## wings) and, west of it, the cream plaster block of Królewska 2 (four storeys over a high
## rusticated arcade, the bowed corner on the square, LoD2's west and north wings). LoD2 draws
## only those two wings and a low strip for the east one; the whole ring is ours and replaces it.
## The frame is the block's own: s along the Królewska front (east-north-east), t north into the
## block, both in metres from the south-west corner of its bounding rectangle.
const KRL_O := Vector2(-650.7, -731.2)
const KRL_U := Vector2(0.9698, -0.2437)
const KRL_N := Vector2(-0.2437, -0.9698)
## The sandstone wings start where OpenStreetMap's outline of Dom bez Kantów meets the cream block:
## on the Królewska front at s 27.5, on the Tokarzewskiego-Karaszewicza front at s 69.3.
const KRL_SOUTH_AT := 27.5
const KRL_NORTH_AT := 69.3
const KRL_COURT := Rect2(22.0, 17.5, 56.0, 35.5)   # the courtyard: s 22..78, t 17.5..53 (LoD2's inner walls, the orthophoto)
const KRL_E_A := 21.8          # the cream block's eave over the ground (four storeys over the arcade)
const KRL_E_B := 25.9          # Dom bez Kantów's eave (LoD2's wings reach 22 to 26 m)
const KRL_PLASTER := Color("#e9e2cf")
const KRL_PLASTER_BASE := Color("#e4ddcb")
const KRL_STONE_A := Color("#d6c8a8")
const KRL_ASHLAR := Color("#dac9a2")
const KRL_STONE_B := Color("#cdbb94")
const KRL_GLASS := Color("#323a40")
const KRL_FRAME := Color("#ece7da")
const KRL_ROOF := Color("#6d7470")
## The outer outline in the block's frame (s, t): the south-west and north-west corners are the cream
## block's (LoD2), the rest is OpenStreetMap's outline of Dom bez Kantów (its rounded corners).
const KRL_OUTER := [
	[0.0, 8.0], [0.9, 4.7], [3.0, 2.3], [5.7, 0.8], [8.0, 0.0],
	[98.5, 0.8], [101.9, 1.6], [103.2, 2.3], [105.3, 4.5], [106.0, 5.8], [106.6, 8.7], [106.7, 10.0],
	[98.5, 58.7], [97.9, 62.2], [97.2, 64.9], [96.8, 66.3], [95.5, 68.8], [94.4, 69.8], [91.2, 71.4], [87.5, 71.6],
	[7.0, 71.9], [4.9, 71.4], [2.0, 69.9], [0.5, 67.7], [0.0, 64.9]]


## A point in the block's own frame, in the world.
func _krl_w(s: float, t: float) -> Vector2:
	return KRL_O + KRL_U * s + KRL_N * t


func _krl_st(p: Vector2) -> Vector2:
	var d := p - KRL_O
	return Vector2(d.dot(KRL_U), d.dot(KRL_N))


## The outer outline (`court` false) or the courtyard's (true), world metres.
func _krl_ring(court: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	if court:
		var r := KRL_COURT
		for q: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			out.append(_krl_w(q.x, q.y))
		return out
	for q: Array in KRL_OUTER:
		out.append(_krl_w(q[0], q[1]))
	return out


## Whether a point of the block (frame metres) is Dom bez Kantów's sandstone: the south front from
## s 27.5 on, the east wing, the north front from s 69.3 on.
func _krl_sandstone(st: Vector2) -> bool:
	if st.y < KRL_COURT.position.y + 5.0:
		return st.x >= KRL_SOUTH_AT
	if st.y > KRL_COURT.end.y - 5.0:
		return st.x >= KRL_NORTH_AT
	return st.x >= KRL_COURT.end.x - 5.0


func _krl_poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(_krl_w(q[0], q[1]))
	return out


## The whole block from the outline, the courtyard and the two storey heights.
func _build_bez_kantow(_site: Dictionary) -> void:
	var outer := _krl_ring(false)
	_g = _ground_under(outer)
	var g := _g
	_mode = M_STONE
	# the roofs: the cream block at its eave, Dom bez Kantów at its own (the courtyard is left open)
	var cream := _largest(Geometry2D.intersect_polygons(outer, _krl_poly([[-1.0, -1.0], [KRL_SOUTH_AT, -1.0], [KRL_SOUTH_AT, 35.0],
			[KRL_NORTH_AT, 35.0], [KRL_NORTH_AT, 80.0], [-1.0, 80.0]])))
	var stone := _largest(Geometry2D.intersect_polygons(outer, _krl_poly([[KRL_SOUTH_AT, -1.0], [120.0, -1.0], [120.0, 80.0],
			[KRL_NORTH_AT, 80.0], [KRL_NORTH_AT, 35.0], [KRL_SOUTH_AT, 35.0]])))
	_cap(cream, g + KRL_E_A, KRL_ROOF)
	_cap(stone, g + KRL_E_B, KRL_ROOF)
	# where the sandstone wings stand over the cream ones: a step in the eave, facing west
	var west := -KRL_U
	_wall(_krl_w(KRL_SOUTH_AT, 0.0), _krl_w(KRL_SOUTH_AT, KRL_COURT.position.y), g + KRL_E_A, g + KRL_E_B, west, KRL_ASHLAR)
	_wall(_krl_w(KRL_NORTH_AT, KRL_COURT.end.y), _krl_w(KRL_NORTH_AT, 71.9), g + KRL_E_A, g + KRL_E_B, west, KRL_ASHLAR)
	_krl_faces(outer, false)
	_krl_faces(_krl_ring(true), true)
	_collide(outer)


## Every edge of a ring as a front: the walls, the arcade, the rows of panes, the string courses
## and the cornice. `court` faces turn into the courtyard and are plainer.
func _krl_faces(ring: PackedVector2Array, court: bool) -> void:
	var g := _g
	var n := ring.size()
	for k in n:
		var p := ring[k]
		var q := ring[(k + 1) % n]
		if p.distance_to(q) < 0.8:
			continue
		var out := _out(ring, p, q)
		if court:
			out = -out
		if (Vector2(-(q - p).y, (q - p).x)).dot(out) < 0.0:
			var tmp := p
			p = q
			q = tmp
		var mid := _krl_st((p + q) * 0.5)
		var sandstone := _krl_sandstone(mid)
		var e := g + (KRL_E_B if sandstone else KRL_E_A)
		var wall := KRL_ASHLAR if sandstone else KRL_PLASTER
		var stone := KRL_STONE_B if sandstone else KRL_STONE_A
		var base := KRL_ASHLAR.lightened(0.04) if sandstone else KRL_PLASTER_BASE
		# the walls: the ground floor in its paler base, then the upper floors; everything stands on them
		_wall(p, q, g - 1.0, g + 6.3, out, base)
		_wall(p, q, g + 6.3, e, out, wall)
		var le := kit_front(p, q)
		kit_face(0.0)
		var rows: Array = [g + 7.9, g + 11.0, g + 14.1, g + 17.2, g + 20.3] if sandstone else [g + 7.7, g + 10.9, g + 14.1, g + 17.3]
		var m := maxi(1, roundi(le / (3.4 if court else 3.1)))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		if court:
			kit_panes(cs, [g + 1.3, g + 4.4] + rows, 1.3, 2.0, KRL_GLASS, 0.05)
			kit_cornice(0.0, le, e, stone, 0.4, 0.6)
			continue
		# ground floor: the pale base (walled above), a string course over it, the arches along every front
		kit_ledge(0.0, le, g + 6.3, 0.35, stone, 0.2)
		var na := maxi(1, roundi(le / 6.0))
		var hw := minf(1.6, le / float(na) * 0.3)
		for i in na:
			_arch_win(_w((float(i) + 0.5) * le / float(na), 0.0), _a, _b, hw, g + 0.5, g + 4.3, KRL_GLASS)
		# the upper floors: a pale frame behind each pane, a sill band under each row
		kit_panes(cs, rows, 1.5, 2.2, KRL_FRAME, 0.04)
		kit_panes(cs, rows, 1.2, 1.9, KRL_GLASS, 0.07)
		for yr in rows:
			kit_ledge(0.0, le, float(yr) - 0.25, 0.18, stone, 0.12)
		if sandstone:
			kit_ledge(0.0, le, g + 13.0, 0.4, stone, 0.25)  # the heavy string course under the third floor
			kit_panes(cs, [g + 24.2], 0.9, 0.45, KRL_GLASS, 0.05)  # the slit windows of the attic
		elif le < 8.0:
			# small stone balustrades under the first floor's windows on the bowed corner
			for cu in cs:
				_kbox(float(cu) - 1.0, float(cu) + 1.0, 0.0, 0.4, g + 7.0, g + 7.85, stone.lightened(0.05))
		kit_cornice(0.0, le, e, stone, 0.5, 0.9)
