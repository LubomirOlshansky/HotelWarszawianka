class_name TenementTrim
extends RefCounted
## Dobra and Tamka's tenements (Powiśle street by street, 2026-11-02): what a plain LoD2 wall
## lacks between its window grid and the sky. On a pre-war tenement's wall (R4 type 1) this adds
## a stepped cornice along the top edge, and along the bottom edge a string course at the first
## floor and, on a wall that faces the street, a run of shop-glass bays under a fascia board. Pure
## geometry into the walls' own tile meshes (the same material: no draw call is added, no
## collision, no roof-grid cell). Load time only, shared by both city paths; every seed comes
## from a place, never an index (check_streaming's identity). Spec docs/landmarks/specs/dobra_tamka.md.

const CORNICE_DEPTH := 0.38     ## m, the cornice's top step out of the wall
const CORNICE_FOOT := 0.18      ## m, its lower step
const CORNICE_H := 0.7          ## m, both steps together
const COURSE_AT := 3.9          ## m, the first-floor string course over the foot of the wall
const COURSE_DEPTH := 0.12
const COURSE_H := 0.3
const MIN_WALL_H := 8.0         ## m, a lower wall takes no string course
const MIN_EDGE := 2.5           ## m, a shorter edge takes none
const SHOP_MIN_EDGE := 5.0      ## m, a shorter wall has no shop front
const SHOP_BAY := 3.4           ## m, one shop-glass bay and its pier
const SHOP_PIER := 1.0          ## m, the wall left between two panes
const SHOP_SILL := 0.55
const SHOP_TOP := 3.3
const FASCIA_TOP := 3.85
const GLASS := Color("#34444e")
const GLASS_LIT := Color("#6f6a52")  ## every fifth pane: a lit window of a shop that is open
const FASCIA_SEEDS := [Color("#4a3f38"), Color("#3c4a45"), Color("#4d3a3f"), Color("#33404f"), Color("#5a4c39")]

## Tamka from F's photos (2026-11-08, docs/powisle-tamka.md): the post-war blocks' balconies,
## stacked in columns on the street walls, a slab and a dark steel rail; and a ground floor faced in
## another material (Tamka 16's red brick). `style` keys: "balc" (rail colour), "base" (ground-floor
## colour), "shops" (false: no shop front), "crenel" (Tamka 10/12's attic of small square openings).
const BALC_BAY := 3.6           ## m, a balcony column every second bay of this
const BALC_W := 2.3
const BALC_DEEP := 0.95
const BALC_FIRST := 3.4         ## m, the first balcony's slab over the foot
const FLOOR := 2.9              ## m, one storey
const BALC_TOP_GAP := 2.2       ## m, no balcony nearer the top of the wall than this
const RAIL_H := 1.0
const BASE_TOP := 3.9           ## m, the faced ground floor's top
const CRENEL_W := 0.7
const CRENEL_H := 0.55
const CRENEL_STEP := 2.2

## Counts for the build's report: cornice edges, shop fronts, triangles added.
static var balconies := 0
static var cornices := 0
static var shops := 0
static var triangles := 0


## Appends one wall triangle's trim to `out` ("pos", "nrm", "col" as plain Arrays). The triangle is
## `a`, `b`, `c`, its wall faces `n` (horizontal, unit), `plaster` is its house's colour and
## `street` whether the wall faces a street close by. A triangle takes the cornice on a horizontal top
## edge (the third corner under it), the string course and shop front on a bottom edge (the third
## corner 3 m or more over it; the foot may follow a slope).
static func wall(out: Dictionary, a: Vector3, b: Vector3, c: Vector3, n: Vector3, plaster: Color, street: bool,
		style := {}) -> void:
	var v: Array[Vector3] = [a, b, c]
	for i in 3:
		var p := v[i]
		var q := v[(i + 1) % 3]
		var o := v[(i + 2) % 3]
		var length := Vector2(q.x - p.x, q.z - p.z).length()
		if length < MIN_EDGE:
			continue
		if absf(p.y - q.y) < 0.02 and o.y < p.y - 0.5:
			if style.has("crenel") and street:
				_crenels(out, p, q, n, Color(style["crenel"]))
			else:
				_cornice(out, p, q, n, plaster)
		elif o.y > maxf(p.y, q.y) + 3.0:
			var wall_h := o.y - maxf(p.y, q.y)
			_course(out, p, q, n, plaster, wall_h)
			if style.has("base") and street:
				_ledge(out, p, q, n, 0.0, BASE_TOP, 0.05, Color(style["base"]))
			if street and length >= SHOP_MIN_EDGE and bool(style.get("shops", true)):
				_shop(out, p, q, n, plaster)
			if style.has("balc") and street and length >= BALC_W + 1.0:
				_balconies(out, p, q, n, plaster, Color(style["balc"]), wall_h)


## The cornice: two steps, each a front face and a top face, running past both ends by its depth
## so it closes the corner where a second wall's cornice meets it.
static func _cornice(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, plaster: Color) -> void:
	var tone := plaster.lightened(0.14)
	_ledge(out, p, q, n, -CORNICE_H, -CORNICE_H * 0.5, CORNICE_FOOT, tone.darkened(0.06))
	_ledge(out, p, q, n, -CORNICE_H * 0.5, 0.0, CORNICE_DEPTH, tone)
	cornices += 1


## The first-floor string course: a thin ledge round the house at COURSE_AT over the foot.
static func _course(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, plaster: Color, wall_h: float) -> void:
	if wall_h < MIN_WALL_H:
		return
	_ledge(out, p, q, n, COURSE_AT, COURSE_AT + COURSE_H, COURSE_DEPTH, plaster.lightened(0.08))


## A shop front on the ground floor: dark panes between piers, a fascia board over them.
static func _shop(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, plaster: Color) -> void:
	var length := Vector2(q.x - p.x, q.z - p.z).length()
	var along := Vector3(q.x - p.x, 0.0, q.z - p.z) / length
	var bays := maxi(1, roundi((length - 1.2) / SHOP_BAY))
	var step := (length - 1.2) / bays
	var seed := fposmod((p.x + q.x) * 0.0913 + (p.z + q.z) * 0.0571, 1.0)
	var inside := (p + q) * 0.5 - n * 2.0
	var off := n * 0.06
	for k in bays:
		var u0 := 0.6 + step * k + SHOP_PIER * 0.5
		var u1 := 0.6 + step * (k + 1) - SHOP_PIER * 0.5
		if u1 - u0 < 0.8:
			continue
		var f0 := u0 / length
		var f1 := u1 / length
		var glass := GLASS_LIT if fposmod(seed * 7.0 + float(k) * 0.37, 1.0) < 0.2 else GLASS
		var lo0 := p.lerp(q, f0) + Vector3.UP * SHOP_SILL + off
		var lo1 := p.lerp(q, f1) + Vector3.UP * SHOP_SILL + off
		var rise := Vector3.UP * (SHOP_TOP - SHOP_SILL)
		RoofDress._tri2(out, lo0, lo1, lo1 + rise, glass, glass, glass, inside)
		RoofDress._tri2(out, lo0, lo1 + rise, lo0 + rise, glass, glass, glass, inside)
		triangles += 2
	# the fascia board over the whole front, a little proud of the panes
	var fascia: Color = FASCIA_SEEDS[int(seed * 100.0) % FASCIA_SEEDS.size()]
	var f_lo := Vector3.UP * (SHOP_TOP + 0.05) + n * 0.1
	var f_hi := Vector3.UP * FASCIA_TOP + n * 0.1
	var pa := p + along * 0.3
	var qa := q - along * 0.3
	RoofDress._tri2(out, pa + f_lo, qa + f_lo, qa + f_hi, fascia, fascia, fascia, inside)
	RoofDress._tri2(out, pa + f_lo, qa + f_hi, pa + f_hi, fascia, fascia, fascia, inside)
	triangles += 2
	shops += 1


## One ledge along p-q: a front face from `h0` to `h1` over the edge (each end at its own height,
## so a sloped foot carries it), `depth` out of the wall, and its top face. It runs past both
## ends by its depth.
static func _ledge(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, h0: float, h1: float, depth: float,
		colour: Color) -> void:
	var length := Vector2(q.x - p.x, q.z - p.z).length()
	var along := Vector3(q.x - p.x, 0.0, q.z - p.z) / length
	var slope := (q.y - p.y) / length
	var a := p - along * depth - Vector3.UP * slope * depth
	var b := q + along * depth + Vector3.UP * slope * depth
	var shift := n * depth
	var lo_a := a + Vector3.UP * h0 + shift
	var lo_b := b + Vector3.UP * h0 + shift
	var hi_a := a + Vector3.UP * h1 + shift
	var hi_b := b + Vector3.UP * h1 + shift
	var inside := (p + q) * 0.5 - n * 2.0 + Vector3.UP * (h0 + h1) * 0.5
	RoofDress._tri2(out, lo_a, lo_b, hi_b, colour, colour, colour, inside)
	RoofDress._tri2(out, lo_a, hi_b, hi_a, colour, colour, colour, inside)
	# the top face, from the front's top edge back to the wall
	var wa := a + Vector3.UP * h1
	var wb := b + Vector3.UP * h1
	var top := colour.lightened(0.06)
	var below := inside - Vector3.UP * 3.0
	RoofDress._tri2(out, hi_a, hi_b, wb, top, top, top, below)
	RoofDress._tri2(out, hi_a, wb, wa, top, top, top, below)
	triangles += 4


## Balconies up a street wall (Tamka's post-war blocks, F's photos): a column of them every second
## BALC_BAY along the edge (one in the middle on a narrow wall), from BALC_FIRST up a storey at a
## time to BALC_TOP_GAP under the top; each a slab (front and top) and a dark rail (front and ends).
static func _balconies(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, plaster: Color, rail: Color,
		wall_h: float) -> void:
	var length := Vector2(q.x - p.x, q.z - p.z).length()
	var along := Vector3(q.x - p.x, 0.0, q.z - p.z) / length
	var bays := maxi(1, floori(length / BALC_BAY))
	var step := length / bays
	var slab := plaster.darkened(0.12)
	var seed := fposmod((p.x + q.x) * 0.0713 + (p.z + q.z) * 0.0457, 1.0)
	var first := 0 if seed < 0.5 else 1
	if bays == 1:
		first = 0
	var top := minf(p.y, q.y) + wall_h - BALC_TOP_GAP
	for k in range(first, bays, 2):
		var mid := step * (k + 0.5)
		var u0 := mid - BALC_W * 0.5
		var u1 := mid + BALC_W * 0.5
		if u0 < 0.3 or u1 > length - 0.3:
			continue
		var y := BALC_FIRST
		while p.lerp(q, mid / length).y + y + RAIL_H < top:
			var a := p + along * u0 + Vector3.UP * (y + (q.y - p.y) * u0 / length)
			var b := p + along * u1 + Vector3.UP * (y + (q.y - p.y) * u0 / length)
			_slab_rail(out, a, b, n, slab, rail)
			balconies += 1
			y += FLOOR


## One balcony from wall points a-b (the slab's top at their height): the slab's front and top,
## the rail's front and its two ends.
static func _slab_rail(out: Dictionary, a: Vector3, b: Vector3, n: Vector3, slab: Color, rail: Color) -> void:
	var o := n * BALC_DEEP
	var t := Vector3.UP * 0.16
	var inside := (a + b) * 0.5 - n * 2.0
	RoofDress._tri2(out, a + o - t, b + o - t, b + o, slab, slab, slab, inside)
	RoofDress._tri2(out, a + o - t, b + o, a + o, slab, slab, slab, inside)
	var up := slab.lightened(0.05)
	RoofDress._tri2(out, a + o, b + o, b, up, up, up, inside - Vector3.UP * 3.0)
	RoofDress._tri2(out, a + o, b, a, up, up, up, inside - Vector3.UP * 3.0)
	var r := Vector3.UP * RAIL_H
	RoofDress._tri2(out, a + o, b + o, b + o + r, rail, rail, rail, inside)
	RoofDress._tri2(out, a + o, b + o + r, a + o + r, rail, rail, rail, inside)
	RoofDress._tri2(out, a, a + o, a + o + r, rail, rail, rail, (a + b) * 0.5 + r * 0.5)
	RoofDress._tri2(out, a, a + o + r, a + r, rail, rail, rail, (a + b) * 0.5 + r * 0.5)
	RoofDress._tri2(out, b, b + o, b + o + r, rail, rail, rail, (a + b) * 0.5 + r * 0.5)
	RoofDress._tri2(out, b, b + o + r, b + r, rail, rail, rail, (a + b) * 0.5 + r * 0.5)
	triangles += 12


## Tamka 10/12's attic (F's photo): a plain parapet band with a row of small dark square openings
## under the top edge instead of a cornice.
static func _crenels(out: Dictionary, p: Vector3, q: Vector3, n: Vector3, dark: Color) -> void:
	var length := Vector2(q.x - p.x, q.z - p.z).length()
	var along := Vector3(q.x - p.x, 0.0, q.z - p.z) / length
	var inside := (p + q) * 0.5 - n * 2.0
	var off := n * 0.04
	var count := floori((length - 1.0) / CRENEL_STEP)
	if count < 1:
		return
	var start := (length - (count - 1) * CRENEL_STEP) * 0.5
	for k in count:
		var u := start + k * CRENEL_STEP
		var lo := p + along * (u - CRENEL_W * 0.5) + Vector3.UP * (-0.95) + off
		var lo2 := p + along * (u + CRENEL_W * 0.5) + Vector3.UP * (-0.95) + off
		var h := Vector3.UP * CRENEL_H
		RoofDress._tri2(out, lo, lo2, lo2 + h, dark, dark, dark, inside)
		RoofDress._tri2(out, lo, lo2 + h, lo + h, dark, dark, dark, inside)
		triangles += 2
	cornices += 1
