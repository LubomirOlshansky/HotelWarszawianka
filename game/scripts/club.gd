extends Node3D
## Inside the club (F's ask 2026-11-06, option A of docs/design/secret-rave.md): after the door,
## a cutaway room in the city's own isometric look, the walls on two sides and a black void
## round it, like a diorama. The camera leaves the car (main.gd `_update_camera` reads `inside`,
## `centre`, `view_size`), the HUD steps aside for the room's own panel, the car waits at the
## door (its process off).
##
## The room (about ROOM.x × ROOM.y m, far off the map at PLACE so nothing of the city is in view):
## a concrete floor and two walls with a pillar grid (the power-station look of Berlin-style
## clubs), the DJ booth on a riser under a truss, speaker stacks, the bar with lit bottles, the
## cloakroom, a queue for the toilets, a sofa in the chill corner, the lit WYJŚCIE door. Forty-odd
## dancers in black bob on the beat; beams, lasers and a strobe come down from the truss (the
## rave rig's light pose, the city's glow material). Now and then the lights turn red and the
## DJ jokes about the sprinklers (a nod to a famous film's blood rave, no blood: `club_red`).
##
## People to tap (their lines in data/dialogue.json): the DJ (`club_dj`), Mati (`club_ziomek`),
## the bartender (`club_bar`), Pan Kołek, a tall vampire hunter in a long coat and sunglasses
## who insists he is only here for the music (`club_kolek`, our own parody character), and the
## crowd (`club_crowd`: the techno scene, Lusterko's after, Berlin, phones). TAŃCZ: tap on the
## beat (the ring on the button pulses at BPM); eight in a row earn respect (DANCE_PAY, up to
## DANCE_MAX times a visit, on the patio too). WYJDŹ goes back to the car. The club's own loop
## plays (MUSIC_SALA), the radio ducked under it and tuned to MORDOR FM for when you leave.
##
## The jungle (F, 2026-11-06; one palm left in the right corner since 2026-11-08): vines from the
## trusses and walls, big leaves round the booth, all in the room's one mesh. PATIO (the green-lit door behind the bar) goes out to the
## patio, its own cutaway next door (PATIO_AT): a tenement courtyard with a deck, red deck
## chairs, trees full of fairy lights, garlands, a mirror ball whose rays turn, the bar kiosk and
## a small DJ; lighter music there (MUSIC_PATIO; the radio waits on PÓŁNOC FM); the barmaid, the patio's DJ and the crowd to tap (`club_patio*`). SALA goes back in.
##
## Cost: three draw calls in the room (its mesh, the dancers, the lights), three on the patio
## (its mesh, its crowd, the same lights moved there); the city is out of view. Both are built
## once, on the first visit (about 13k triangles together).

const Lang := preload("res://scripts/lang.gd")

## The music (F, 2026-11-08): two short loops of our own (tools/make_club_loops.py), the room's
## techno at BPM and the patio's house at PATIO_BPM; the radio is ducked under them while inside.
## TAŃCZ counts the beat from the loop's playback position, so the beat ring is on the music.
const MUSIC_SALA := "res://audio/club/smola_sala.wav"
const MUSIC_PATIO := "res://audio/club/smola_patio.wav"
const MUSIC_DB := -6.0
const PATIO_MUSIC_DB := -9.0
## The radio's duck while the club's own music plays.
const RADIO_DUCK_DB := -60.0
const Models := preload("res://scripts/models.gd")
const Rave := preload("res://scripts/rave.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Access := preload("res://scripts/access.gd")

## Where the room stands: far past the map's edge.
const PLACE := Vector3(9000.0, 0.0, 9000.0)
## The floor, x across, y deep (m); the walls' height.
const ROOM := Vector2(24.0, 16.0)
const WALL_H := 6.0
## The camera: the view's height (m) and its yaw (degrees: from the open corner).
const VIEW := 21.0
const YAW := 45.0
const DANCERS := 44
const BPM := 132.0
## The dance: a tap within this many seconds of a beat counts; STREAK in a row pays.
const BEAT_WINDOW := 0.13
const STREAK := 8
const DANCE_PAY := 15
const DANCE_MAX := 3
## The red lights: every RED_GAP s for RED_LONG s.
const RED_GAP := Vector2(35.0, 55.0)
const RED_LONG := 6.0
const VIOLET := Color("#b44cff")
## The truss tower in the middle of the floor (F's photo).
const TRUSS := Vector2(0.0, 4.0)
const TAP_R := 1.6
## The patio (F, 2026-11-06, from photos of a tenement courtyard club garden): its own cutaway
## next to the room, PATIO.x × PATIO.y m, tenement walls PATIO_H high on two sides.
const PATIO_AT := PLACE + Vector3(70.0, 0.0, 0.0)
const PATIO := Vector2(20.0, 15.0)
const PATIO_H := 10.0
const PATIO_VIEW := 23.0
const PATIO_CROWD := 26
const PATIO_BPM := 112.0
## The mirror ball (patio local).
const BALL := Vector3(2.0, 4.4, 0.0)
## The patio door in the left wall (local z).
const PATIO_DOOR_Z := -4.6

signal left

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var radio: Node
var _music: AudioStreamPlayer
var _streams := {}
## The radio's duck before we went in (put back on the way out).
var _radio_duck := 0.0
## The view's camera (main.gd's), for taps.
var cam: Camera3D
var log_on := false

var inside := false
var centre := PLACE + Vector3(0, 1.2, 0)
var view_size := VIEW
var yaw := YAW
## The people one can tap: [name, group, local position].
var people: Array = []
var danced := 0
var streak := 0
var title_pl := "SMOŁA"
var title_en := "SMOŁA"
## Where one is: "sala" (the room) or "patio".
var area := "sala"
## The patio's people one can tap, as `people`.
var patio_people: Array = []

var _built := false
var _room: MeshInstance3D
var _dancers: MultiMeshInstance3D
var _lights: MultiMeshInstance3D
var _floor: Array[Vector3] = []
var _clock := 0.0
var _red_in := 40.0
var _red_t := 0.0
var _dance_t := 0.0
var _ui: CanvasLayer
var _title: Label
var _who: Label
## F 2026-11-11: the speaker's small face beside their line (Portraits.badge); none for the crowd.
var _face: Control
var _line: Label
var _line_en: Label
var _talk: PanelContainer
var _beat: Control
var _dance_btn: Button
var _rng := RandomNumberGenerator.new()
var _patio: MeshInstance3D
var _crowd: MultiMeshInstance3D
var _crowd_at: Array[Vector3] = []
var _patio_btn: Button
var _sala_btn: Button
var _mordor_i := -1


# --- the room -------------------------------------------------------------------------------

## The room's static mesh: floor, walls, pillars, the booth, bar, cloakroom, sofa, the door, the
## void under it all, and Pan Kołek (he never moves). Local frame: the floor's middle at the
## origin, the back wall at -Z, the left wall at -X, the open sides +X and +Z (towards the camera).
static func room_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var concrete := Color("#323a46")
	var dark := Color("#1a1f27")
	var black := Color("#0d0d10")
	var steel := Color("#4a4a52")
	# The void: a black slab far round the room, then the floor.
	Models.box(st, Vector3(0, -0.6, 0), Vector3(400, 1.0, 400), Color("#020203"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(ROOM.x, 0.2, ROOM.y), Color("#29282d"), Models.FIXED)
	# The walls (back -Z, left -X), panels and pillars.
	Models.box(st, Vector3(0, WALL_H * 0.5, -hz - 0.2), Vector3(ROOM.x + 0.8, WALL_H, 0.4), concrete, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.2, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, ROOM.y), concrete, Models.FIXED)
	for i in 6:
		var x := -hx + 2.0 + i * 4.0
		Models.box(st, Vector3(x, WALL_H * 0.5, -hz + 0.05), Vector3(0.5, WALL_H, 0.3), dark, Models.FIXED)
	for i in 4:
		var z := -hz + 2.0 + i * 4.0
		Models.box(st, Vector3(-hx + 0.05, WALL_H * 0.5, z), Vector3(0.3, WALL_H, 0.5), dark, Models.FIXED)
	for p: Vector2 in [Vector2(-4, -1), Vector2(4, -1), Vector2(-4, 4), Vector2(4, 4)]:
		Models.box(st, Vector3(p.x, WALL_H * 0.5, p.y), Vector3(0.6, WALL_H, 0.6), concrete, Models.FIXED)
	_photo_look(st)
	# The riser, booth, stacks and truss at the back wall's middle.
	Models.box(st, Vector3(0, 0.3, -hz + 2.0), Vector3(8.0, 0.6, 3.4), dark, Models.FIXED)
	Models.box(st, Vector3(0, 1.1, -hz + 2.2), Vector3(2.8, 1.0, 0.9), black, Models.FIXED)
	Models.box(st, Vector3(0, 1.35, -hz + 2.68), Vector3(2.7, 0.08, 0.04), VIOLET, Models.LIT_SIGN)
	for side in [-1.0, 1.0]:
		Models.box(st, Vector3(side * 3.0, 1.8, -hz + 1.6), Vector3(1.3, 2.4, 1.1), black, Models.FIXED)
		Models.box(st, Vector3(side * 3.0, 1.4, -hz + 2.16), Vector3(0.8, 0.8, 0.02), steel, Models.FIXED)
		Models.box(st, Vector3(side * 3.0, 2.5, -hz + 2.16), Vector3(0.6, 0.6, 0.02), steel, Models.FIXED)
	Models.box(st, Vector3(0, 5.4, -hz + 3.0), Vector3(14.0, 0.25, 0.25), steel, Models.FIXED)
	Models.box(st, Vector3(0, 5.4, 2.0), Vector3(14.0, 0.25, 0.25), steel, Models.FIXED)
	# The bar along the left wall, its bottles lit.
	Models.box(st, Vector3(-hx + 1.6, 0.55, 1.5), Vector3(1.0, 1.1, 7.0), dark, Models.FIXED)
	Models.box(st, Vector3(-hx + 1.6, 1.12, 1.5), Vector3(1.1, 0.06, 7.1), steel, Models.FIXED)
	Models.box(st, Vector3(-hx + 0.35, 2.2, 1.5), Vector3(0.3, 0.08, 6.0), steel, Models.FIXED)
	var bottles := [Color("#3ad8ff"), Color("#ff3ad0"), Color("#f2d34a"), Color("#7ad66a")]
	for i in 14:
		Models.box(st, Vector3(-hx + 0.35, 2.42, -1.2 + i * 0.42), Vector3(0.12, 0.36, 0.12), bottles[i % 4], Models.LIT_SIGN)
	# The cloakroom by the door (front left), the sofa (front right), the toilets' doors.
	Models.box(st, Vector3(-hx + 1.0, 0.6, hz - 2.0), Vector3(1.6, 1.2, 2.6), dark, Models.FIXED)
	for i in 6:
		Models.box(st, Vector3(-hx + 0.3, 1.9, hz - 3.0 + i * 0.4), Vector3(0.2, 0.9, 0.3), [black, Color("#5a2a6a"), dark][i % 3], Models.FIXED)
	Models.box(st, Vector3(hx - 2.5, 0.35, -hz + 1.6), Vector3(3.4, 0.7, 1.2), Color("#5a2a6a"), Models.FIXED)
	Models.box(st, Vector3(hx - 2.5, 0.9, -hz + 1.1), Vector3(3.4, 0.6, 0.3), Color("#5a2a6a"), Models.FIXED)
	for i in 2:
		Models.box(st, Vector3(hx - 7.0 + i * 1.6, 1.1, -hz + 0.02), Vector3(1.0, 2.2, 0.06), steel, Models.FIXED)
	Models.box(st, Vector3(hx - 6.2, 2.5, -hz + 0.05), Vector3(2.4, 0.3, 0.04), Color("#3ad8ff"), Models.LIT_SIGN)
	# The way out: a door in the left wall at the front, its lit sign.
	Models.box(st, Vector3(-hx + 0.02, 1.2, hz - 5.0), Vector3(0.06, 2.4, 1.4), Color("#2a5a3a"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.06, 2.75, hz - 5.0), Vector3(0.04, 0.3, 1.4), Color("#3aff7a"), Models.LIT_SIGN)
	# Pan Kołek by the front-right pillar: a long black coat, a pale face, sunglasses.
	var k := Vector3(5.2, 0, 4.6)
	Models.box(st, k + Vector3(0, 0.95, 0), Vector3(0.62, 1.9, 0.42), Color("#0b0b0d"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.08, 0), Vector3(0.28, 0.3, 0.28), Color("#8a6a52"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.12, 0.15), Vector3(0.3, 0.07, 0.03), Color("#050505"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.26, 0), Vector3(0.3, 0.06, 0.3), Color("#0b0b0d"), Models.FIXED)
	_jungle(st)
	# The way to the patio: an open door in the left wall behind the bar, warm light beyond it.
	Models.box(st, Vector3(-hx + 0.02, 1.25, PATIO_DOOR_Z), Vector3(0.06, 2.5, 1.6), Color("#ffcf7a"), Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 0.06, 2.85, PATIO_DOOR_Z), Vector3(0.04, 0.32, 1.6), Color("#7ad66a"), Models.LIT_SIGN)
	return st.commit()


## The room from F's photo of the real floor (2026-11-08): concrete gone blue in a cyan wash, the
## acoustic panels hung under the ceiling along the walls (only there, or they would hide the
## floor from the camera), a cyan line along the walls' top, red LED bars upright on the back and
## left walls, and the truss tower standing in the middle of the floor.
static func _photo_look(st: SurfaceTool) -> void:
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var panel := Color("#1d4656")
	var cyan := Color("#3ad8ff")
	var red := Color("#ff2a2a")
	var steel := Color("#7a7f88")
	for i in 11:
		Models.box(st, Vector3(-hx + 1.4 + i * 2.1, WALL_H - 0.5, -hz + 0.9), Vector3(1.6, 0.14, 1.1), panel, Models.FIXED)
	for i in 7:
		Models.box(st, Vector3(-hx + 0.9, WALL_H - 0.5, -hz + 3.2 + i * 2.0), Vector3(1.1, 0.14, 1.5), panel, Models.FIXED)
	Models.box(st, Vector3(0, WALL_H - 0.06, -hz + 0.02), Vector3(ROOM.x, 0.08, 0.04), cyan, Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 0.02, WALL_H - 0.06, 0), Vector3(0.04, 0.08, ROOM.y), cyan, Models.LIT_SIGN)
	for x: float in [-hx + 4.0, hx - 9.0]:
		Models.box(st, Vector3(x, 2.4, -hz + 0.03), Vector3(0.12, 3.6, 0.04), red, Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 0.03, 2.4, 2.5), Vector3(0.04, 3.6, 0.12), red, Models.LIT_SIGN)
	# The truss tower: four chords and a zig-zag of braces on each face, floor to the trusses.
	var c := TRUSS
	for s: Vector2 in [Vector2(-0.2, -0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2), Vector2(0.2, 0.2)]:
		Models.box(st, Vector3(c.x + s.x, WALL_H * 0.5, c.y + s.y), Vector3(0.05, WALL_H, 0.05), steel, Models.FIXED)
	for k in 12:
		var y := 0.25 + k * 0.48
		Models.box(st, Vector3(c.x, y, c.y - 0.2), Vector3(0.4, 0.04, 0.04), steel, Models.FIXED)
		Models.box(st, Vector3(c.x, y, c.y + 0.2), Vector3(0.4, 0.04, 0.04), steel, Models.FIXED)
		Models.box(st, Vector3(c.x - 0.2, y + 0.24, c.y), Vector3(0.04, 0.04, 0.4), steel, Models.FIXED)
		Models.box(st, Vector3(c.x + 0.2, y + 0.24, c.y), Vector3(0.04, 0.04, 0.4), steel, Models.FIXED)


## The jungle inside (F, 2026-11-06, from a photo of a jungle-dressed booth): palms by the
## pillars and in the corners, vines hanging from the trusses and over the booth, big leaves
## along the walls and round the riser, ferns in pots. Low poly: tilted boxes, deep greens.
static func _jungle(st: SurfaceTool) -> void:
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var greens := [Color("#1f5a2a"), Color("#2c7a34"), Color("#3f8f3a"), Color("#17482a"), Color("#4fa04a")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	# One palm, in the right corner by the sofa (F, 2026-11-08: the others went).
	_palm(st, Vector3(hx - 1.2, 0, -hz + 3.4), 4.2, rng, greens)
	# Vines: from the two trusses and the back wall's top, swaying lengths, a leaf every half metre.
	for z: float in [-hz + 3.0, 2.0]:
		for i in 9:
			var x := -6.6 + i * 1.65 + rng.randf_range(-0.3, 0.3)
			_vine(st, Vector3(x, 5.3, z), rng.randf_range(1.2, 2.8), rng, greens)
	for i in 12:
		_vine(st, Vector3(-hx + 0.6 + i * 1.9, WALL_H - 0.1, -hz + 0.25), rng.randf_range(1.0, 3.2), rng, greens)
	for i in 7:
		var vz := -hz + 1.5 + i * 2.0
		if absf(vz - PATIO_DOOR_Z) > 1.2:
			_vine(st, Vector3(-hx + 0.25, WALL_H - 0.1, vz), rng.randf_range(1.0, 2.6), rng, greens)
	# Big leaves in front of the riser and the stacks (the booth in the green), ferns in pots.
	for i in 11:
		var x := -4.6 + i * 0.92
		var yaw := rng.randf_range(-0.5, 0.5)
		_leaf(st, Vector3(x, 0.8, -hz + 3.75), Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.55), Vector3(0.55, 0.04, 1.1), greens[i % 5])
	for p: Vector3 in [Vector3(hx - 4.8, 0, -hz + 1.0), Vector3(-hx + 2.6, 0, -2.4), Vector3(-hx + 2.6, 0, 5.4), Vector3(hx - 0.8, 0, -2.0)]:
		Models.box(st, p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7), Color("#2a2a30"), Models.FIXED)
		for j in 7:
			var a := TAU * j / 7.0
			_leaf(st, p + Vector3(cos(a) * 0.4, 0.95, sin(a) * 0.4), Basis(Vector3.UP, -a + PI * 0.5) * Basis(Vector3.RIGHT, 0.7), Vector3(0.3, 0.03, 0.9), greens[(j + 1) % 5])


## A palm: a leaning trunk of rings, a crown of eight drooping fronds.
static func _palm(st: SurfaceTool, at: Vector3, h: float, rng: RandomNumberGenerator, greens: Array) -> void:
	var lean := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
	Models.box(st, at + Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.8), Color("#2a2a30"), Models.FIXED)
	var rings := int(h / 0.4)
	for i in rings:
		var y := 0.5 + i * 0.4
		Models.box(st, at + lean * y + Vector3(0, y + 0.2, 0), Vector3(0.24, 0.38, 0.24), Color("#6b4a32") if i % 2 == 0 else Color("#5a3d2a"), Models.FIXED)
	var top := at + lean * (h + 0.5) + Vector3(0, h + 0.5, 0)
	for j in 8:
		var a := TAU * j / 8.0 + rng.randf() * 0.4
		var b := Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, -0.35 - rng.randf() * 0.35)
		_leaf(st, top + b * Vector3(0.9, 0, 0), b, Vector3(1.9, 0.04, 0.42), greens[j % 5])
		_leaf(st, top + b * Vector3(1.9, -0.25, 0), b * Basis(Vector3.FORWARD, -0.6), Vector3(0.6, 0.04, 0.3), greens[(j + 2) % 5])


## A vine: a thin stem down from `top`, a leaf every half metre, alternate sides.
static func _vine(st: SurfaceTool, top: Vector3, length: float, rng: RandomNumberGenerator, greens: Array) -> void:
	Models.box(st, top - Vector3(0, length * 0.5, 0), Vector3(0.04, length, 0.04), Color("#2f4a24"), Models.FIXED)
	var n := int(length / 0.45)
	for i in n:
		var side := 1.0 if i % 2 == 0 else -1.0
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, side * 0.6)
		_leaf(st, top - Vector3(0, 0.3 + i * 0.45, 0) + b * Vector3(0.12 * side, 0, 0), b, Vector3(0.26, 0.03, 0.18), greens[i % 5])


## A box turned by `b` (Models.box is axis-aligned): eight corners through the basis.
static func _leaf(st: SurfaceTool, centre: Vector3, b: Basis, size: Vector3, colour: Color, part := Models.FIXED) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := n * h[axis]
			var q := [c - u - v, c + u - v, c + u + v, c - u + v]
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			var wn := (b * n).normalized()
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(wn)
				st.set_uv(Vector2(part, 0.0))
				st.add_vertex(centre + b * (q[k] as Vector3))


## The patio's static mesh (local frame: the floor's middle at the origin, tenement walls at -Z
## and -X, open towards the camera): a cobbled yard with a wooden deck, white tenement walls
## with windows (some lit) and balconies, the door back into the room, three trees full of
## fairy lights, garlands of bulbs, a mirror ball, the bar kiosk, red deck chairs under a truss,
## a small DJ table in the plants.
static func patio_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := PATIO.x * 0.5
	var hz := PATIO.y * 0.5
	var plaster := Color("#cfc8ba")
	var trim := Color("#b8b0a2")
	var glass := Color("#1a1f2c")
	var warm := Color("#ffe3a0")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1313
	Models.box(st, Vector3(0, -0.6, 0), Vector3(400, 1.0, 400), Color("#020203"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(PATIO.x, 0.2, PATIO.y), Color("#45444a"), Models.FIXED)
	for i in 10:
		Models.box(st, Vector3(-hx + 1.0 + i * 2.0, 0.01, 0), Vector3(0.05, 0.02, PATIO.y), Color("#3a393f"), Models.FIXED)
	# The deck on the right half, planks.
	Models.box(st, Vector3(hx * 0.5, 0.06, 1.0), Vector3(hx - 0.4, 0.12, PATIO.y - 4.0), Color("#6b4a32"), Models.FIXED)
	for i in 12:
		Models.box(st, Vector3(0.6 + i * 0.8, 0.125, 1.0), Vector3(0.03, 0.01, PATIO.y - 4.0), Color("#523826"), Models.FIXED)
	# The tenement walls, a cornice, windows in rows, two balconies on the back wall.
	Models.box(st, Vector3(0, PATIO_H * 0.5, -hz - 0.3), Vector3(PATIO.x + 1.2, PATIO_H, 0.6), plaster, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.3, PATIO_H * 0.5, 0), Vector3(0.6, PATIO_H, PATIO.y), plaster, Models.FIXED)
	Models.box(st, Vector3(0, PATIO_H + 0.15, -hz - 0.25), Vector3(PATIO.x + 1.4, 0.3, 0.8), trim, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.25, PATIO_H + 0.15, 0), Vector3(0.8, 0.3, PATIO.y), trim, Models.FIXED)
	for floor_i in 3:
		var y := 3.6 + floor_i * 2.6
		for i in 7:
			var x := -hx + 1.8 + i * 2.7
			var lit := rng.randf() < 0.3
			Models.box(st, Vector3(x, y, -hz + 0.01), Vector3(1.1, 1.7, 0.04), warm if lit else glass, Models.LIT_WINDOW if lit else Models.FIXED)
			Models.box(st, Vector3(x, y - 0.95, -hz + 0.06), Vector3(1.3, 0.1, 0.14), trim, Models.FIXED)
		for i in 5:
			var z := -hz + 2.0 + i * 2.8
			var lit := rng.randf() < 0.3
			Models.box(st, Vector3(-hx + 0.01, y, z), Vector3(0.04, 1.7, 1.1), warm if lit else glass, Models.LIT_WINDOW if lit else Models.FIXED)
			Models.box(st, Vector3(-hx + 0.06, y - 0.95, z), Vector3(0.14, 0.1, 1.3), trim, Models.FIXED)
	for x: float in [-hx + 4.5, -hx + 15.3]:
		Models.box(st, Vector3(x, 5.6, -hz + 0.45), Vector3(2.0, 0.12, 0.9), trim, Models.FIXED)
		Models.box(st, Vector3(x, 6.05, -hz + 0.88), Vector3(2.0, 0.8, 0.04), Color("#1c1c20"), Models.FIXED)
	# The door back into the room (back wall, left), lit, its green sign.
	Models.box(st, Vector3(-hx + 3.0, 1.25, -hz + 0.02), Vector3(1.6, 2.5, 0.06), Color("#b44cff"), Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 3.0, 2.85, -hz + 0.06), Vector3(1.6, 0.32, 0.04), Color("#7ad66a"), Models.LIT_SIGN)
	# The bar kiosk on the left wall: a timber box, a warm lit front, a lit shelf.
	Models.box(st, Vector3(-hx + 1.3, 1.3, 2.0), Vector3(2.2, 2.6, 4.2), Color("#5a3d2a"), Models.FIXED)
	Models.box(st, Vector3(-hx + 2.42, 1.05, 2.0), Vector3(0.05, 0.25, 4.0), warm, Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 2.42, 1.9, 2.0), Vector3(0.05, 0.7, 3.6), Color("#ffb85a"), Models.LIT_SIGN)
	Models.box(st, Vector3(-hx + 2.6, 1.0, 2.0), Vector3(0.5, 0.08, 4.2), Color("#3a2a1e"), Models.FIXED)
	# Trees with fairy lights (three), on the cobbles.
	for p: Vector3 in [Vector3(-3.0, 0, -3.0), Vector3(1.5, 0, -4.6), Vector3(-1.6, 0, 3.2)]:
		Models.box(st, p + Vector3(0, 1.6, 0), Vector3(0.28, 3.2, 0.28), Color("#4a3426"), Models.FIXED)
		Models.box(st, p + Vector3(0, 3.6, 0), Vector3(2.4, 1.6, 2.4), Color("#21402a"), Models.FIXED)
		Models.box(st, p + Vector3(0.3, 4.6, -0.2), Vector3(1.7, 1.0, 1.7), Color("#2a5232"), Models.FIXED)
		for j in 46:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.4, 1.3)
			var y := rng.randf_range(2.7, 5.1)
			var d := p + Vector3(cos(a) * r, y, sin(a) * r)
			Models.box(st, d, Vector3(0.09, 0.09, 0.09), warm, Models.LIT_SIGN)
		for j in 12:
			var y := 0.4 + j * 0.2
			var a := j * 1.2
			Models.box(st, p + Vector3(cos(a) * 0.17, y, sin(a) * 0.17), Vector3(0.07, 0.07, 0.07), warm, Models.LIT_SIGN)
	# Two poles at the front, garlands of bulbs from the walls to them.
	for pole: Vector3 in [Vector3(hx - 0.6, 0, hz - 0.6), Vector3(-hx + 4.0, 0, hz - 0.6)]:
		Models.box(st, pole + Vector3(0, 2.6, 0), Vector3(0.12, 5.2, 0.12), Color("#2a2a30"), Models.FIXED)
	for g: Array in [[Vector3(-hx, 5.0, -hz + 3.0), Vector3(hx - 0.6, 5.0, hz - 0.6)], [Vector3(-hx + 6.0, 5.4, -hz), Vector3(-hx + 4.0, 5.0, hz - 0.6)],
			[Vector3(hx - 2.0, 5.4, -hz), Vector3(hx - 0.6, 5.0, hz - 0.6)], [Vector3(-hx, 5.2, 4.0), Vector3(hx - 0.6, 5.0, hz - 0.6)]]:
		var a: Vector3 = g[0]
		var b: Vector3 = g[1]
		var n := int(a.distance_to(b) / 0.7)
		for i in n + 1:
			var t := float(i) / n
			var q := a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.8, 0)
			Models.box(st, q, Vector3(0.12, 0.14, 0.12), Color("#fff1c4") if i % 3 else Color("#ffd27a"), Models.LIT_SIGN)
	# The mirror ball on its wire, and its spots on the walls (still; the rays move).
	Models.box(st, BALL + Vector3(0, 0.8, 0), Vector3(0.02, 1.6, 0.02), Color("#2a2a30"), Models.FIXED)
	Models.box(st, BALL, Vector3(0.62, 0.62, 0.62), Color("#d8dce6"), Models.LIT_WINDOW)
	_leaf(st, BALL, Basis(Vector3.UP, PI * 0.25) * Basis(Vector3.RIGHT, PI * 0.25), Vector3(0.6, 0.6, 0.6), Color("#aab0c0"), Models.FIXED)
	for i in 70:
		var on_back := i % 2 == 0
		var y := rng.randf_range(1.5, 8.5)
		if on_back:
			Models.box(st, Vector3(rng.randf_range(-hx, hx), y, -hz + 0.05), Vector3(0.1, 0.1, 0.02), Color("#f2f4ff"), Models.LIT_SIGN)
		else:
			Models.box(st, Vector3(-hx + 0.05, y, rng.randf_range(-hz, hz)), Vector3(0.02, 0.1, 0.1), Color("#f2f4ff"), Models.LIT_SIGN)
	# The deck: a truss on four legs over red deck chairs and two low tables.
	for c: Vector2 in [Vector2(1.0, -3.0), Vector2(hx - 0.8, -3.0), Vector2(1.0, 5.0), Vector2(hx - 0.8, 5.0)]:
		Models.box(st, Vector3(c.x, 2.0, c.y), Vector3(0.22, 4.0, 0.22), Color("#8a8a92"), Models.FIXED)
	for z: float in [-3.0, 5.0]:
		Models.box(st, Vector3((1.0 + hx - 0.8) * 0.5, 4.0, z), Vector3(hx - 1.6, 0.22, 0.22), Color("#8a8a92"), Models.FIXED)
	for x: float in [1.0, hx - 0.8]:
		Models.box(st, Vector3(x, 4.0, 1.0), Vector3(0.22, 0.22, 8.0), Color("#8a8a92"), Models.FIXED)
	for i in 8:
		var c := Vector3(2.2 + (i % 4) * 2.0, 0.12, 2.2 + (i / 4) * 2.4)
		var b := Basis(Vector3.UP, rng.randf_range(-0.3, 0.3))
		_leaf(st, c + b * Vector3(0, 0.45, 0), b * Basis(Vector3.RIGHT, 0.7), Vector3(0.62, 0.05, 1.2), Color("#c8372d"))
		_leaf(st, c + b * Vector3(0, 0.25, 0.35), b * Basis(Vector3.RIGHT, -0.9), Vector3(0.66, 0.05, 0.7), Color("#6b4a32"))
	for t: Vector3 in [Vector3(4.2, 0.12, 3.4), Vector3(8.2, 0.12, 3.4)]:
		Models.box(st, t + Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.7), Color("#3a2a1e"), Models.FIXED)
		Models.box(st, t + Vector3(0.1, 0.62, 0), Vector3(0.08, 0.22, 0.08), Color("#ffb85a"), Models.LIT_SIGN)
	# The DJ table at the back right, in plants.
	Models.box(st, Vector3(hx - 4.0, 0.5, -hz + 1.5), Vector3(2.2, 1.0, 0.9), Color("#1c1c20"), Models.FIXED)
	Models.box(st, Vector3(hx - 4.0, 1.02, -hz + 1.45), Vector3(1.6, 0.04, 0.5), Color("#3ad8ff"), Models.LIT_SIGN)
	var greens := [Color("#1f5a2a"), Color("#2c7a34"), Color("#3f8f3a"), Color("#17482a"), Color("#4fa04a")]
	# One palm, in the right corner behind the DJ table (F, 2026-11-08).
	_palm(st, Vector3(hx - 1.2, 0, -hz + 1.2), 2.8, rng, greens)
	return st.commit()


## The patio's lights: rays from the mirror ball turning slowly, warm white, one soft violet cone
## up onto the ball (the room's light count: the same MultiMesh moves here).
static func patio_lights(t: float) -> Array:
	var out: Array = []
	var n := Rave.BEAMS + Rave.LASERS
	for i in n:
		var a := TAU * i / n + t * 0.35
		var down := -0.25 - 0.45 * float(i % 3) / 2.0
		var dir := Vector3(cos(a), down, sin(a)).normalized()
		out.append([Rave._aim(BALL, dir, 0.06, 7.0), Color(1.0, 0.95, 0.85) * 0.35])
	out.append([Rave._aim(BALL - Vector3(0, 3.6, 0), Vector3.UP, 1.2, 3.3), Color("#b44cff") * 0.5])
	return out


func _build(world: Node3D) -> void:
	_built = true
	_rng.randomize()
	_room = MeshInstance3D.new()
	_room.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_room.name = "ClubRoom"
	_room.mesh = room_mesh()
	_room.material_override = Models.material()
	_room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_room.position = PLACE
	world.add_child(_room)
	var dmat := Models.material().duplicate() as ShaderMaterial
	dmat.set_shader_parameter("walk", 0.0)
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_custom_data = true
	InstanceBuffers.prepare(dm)
	dm.mesh = Models.person_mesh()
	dm.instance_count = DANCERS + 4
	InstanceBuffers.whiten(dm)
	_dancers = MultiMeshInstance3D.new()
	_dancers.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_dancers.multimesh = dm
	_dancers.material_override = dmat
	_dancers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dancers.position = PLACE
	world.add_child(_dancers)
	var hz := ROOM.y * 0.5
	var hx := ROOM.x * 0.5
	var frng := RandomNumberGenerator.new()
	frng.seed = 4242
	var clothes := [Color("#1a1a1e"), Color("#232327"), Color("#141416"), Color("#2e2e34"), Color("#1a1a1e"), Color("#3ad8ff"), Color("#ff3ad0")]
	while _floor.size() < DANCERS:
		var p := Vector3(frng.randf_range(-7.5, 7.5), frng.randf(), frng.randf_range(-hz + 4.4, hz - 2.0))
		var clear := true
		for q: Vector2 in [Vector2(-4, -1), Vector2(4, -1), Vector2(-4, 4), Vector2(4, 4), Vector2(5.2, 4.6), TRUSS]:
			if Vector2(p.x, p.z).distance_to(q) < 0.9:
				clear = false
		if clear:
			dm.set_instance_custom_data(_floor.size(), Color(clothes[frng.randi() % 7], 0.25))
			_floor.append(p)
	# The DJ, Mati (front of the floor, his violet shirt), the bartender, the cloakroom lady.
	var named := [
		["DJ", "club_dj", Vector3(0, 0.6, -hz + 1.6), Color("#141416")],
		["Mati", "club_ziomek", Vector3(1.5, 0, 0.8), Color("#7a3aa8")],
		["Barman", "club_bar", Vector3(-hx + 0.9, 0, 0.5), Color("#e8e2d6")],
		["Szatnia", "club_crowd", Vector3(-hx + 0.6, 0, hz - 2.0), Color("#a83a3a")],
	]
	people.clear()
	for i in named.size():
		var row: Array = named[i]
		dm.set_instance_custom_data(DANCERS + i, Color(row[3], 0.25))
		var face := 0.0 if i == 0 else (PI * 0.5 if i >= 2 else PI)
		dm.set_instance_transform(DANCERS + i, Transform3D(Basis(Vector3.UP, face), row[2]))
		people.append([row[0], row[1], row[2]])
	people.append(["Pan Kołek", "club_kolek", Vector3(5.2, 0, 4.6)])
	for i in 6:
		people.append(["", "club_crowd", _floor[i * 7]])
	# The lights from the truss: the rave rig's pose, turned to hang down over the floor.
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader")
	mat.render_priority = 1
	mat.set_shader_parameter("lift", 0.0)
	mat.set_shader_parameter("strength", 1.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Rave.cone_mesh()
	mm.instance_count = Rave.BEAMS + Rave.LASERS + 1
	_lights = MultiMeshInstance3D.new()
	_lights.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_lights.multimesh = mm
	_lights.material_override = mat
	_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lights.position = PLACE
	world.add_child(_lights)
	_build_patio(world)
	_build_ui()
	_show(false)


## The patio's mesh and its crowd (a MultiMesh of its own: chatting, swaying, a few dancing),
## the barmaid and the patio's DJ.
func _build_patio(world: Node3D) -> void:
	_patio = MeshInstance3D.new()
	_patio.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_patio.name = "ClubPatio"
	_patio.mesh = patio_mesh()
	_patio.material_override = Models.material()
	_patio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_patio.position = PATIO_AT
	world.add_child(_patio)
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_custom_data = true
	InstanceBuffers.prepare(dm)
	dm.mesh = Models.person_mesh()
	dm.instance_count = PATIO_CROWD + 2
	InstanceBuffers.whiten(dm)
	_crowd = MultiMeshInstance3D.new()
	_crowd.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_crowd.multimesh = dm
	_crowd.material_override = _dancers.material_override
	_crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crowd.position = PATIO_AT
	world.add_child(_crowd)
	var frng := RandomNumberGenerator.new()
	frng.seed = 5151
	var clothes := [Color("#e8e2d6"), Color("#3a5a8a"), Color("#c8372d"), Color("#1a1a1e"), Color("#7ad66a"), Color("#f2d34a"), Color("#ff8ac0"), Color("#5a3d2a")]
	var hx := PATIO.x * 0.5
	var hz := PATIO.y * 0.5
	while _crowd_at.size() < PATIO_CROWD:
		var p := Vector3(frng.randf_range(-hx + 3.2, hx - 1.0), frng.randf(), frng.randf_range(-hz + 2.6, hz - 1.0))
		var clear := true
		for q: Vector2 in [Vector2(-3.0, -3.0), Vector2(1.5, -4.6), Vector2(-1.6, 3.2)]:
			if Vector2(p.x, p.z).distance_to(q) < 1.0:
				clear = false
		if p.x > 1.6 and p.z > 1.4 and p.z < 6.0:
			clear = false
		if clear:
			dm.set_instance_custom_data(_crowd_at.size(), Color(clothes[frng.randi() % clothes.size()], 0.25))
			_crowd_at.append(p)
	var named := [
		["Barmanka", "club_patio_bar", Vector3(-hx + 3.0, 0, 2.0), Color("#f2d34a"), PI * 0.5],
		["DJ na patio", "club_patio_dj", Vector3(hx - 4.0, 0, -hz + 0.9), Color("#7a3aa8"), 0.0],
	]
	patio_people.clear()
	for i in named.size():
		var row: Array = named[i]
		dm.set_instance_custom_data(PATIO_CROWD + i, Color(row[3], 0.25))
		dm.set_instance_transform(PATIO_CROWD + i, Transform3D(Basis(Vector3.UP, row[4]), row[2]))
		patio_people.append([row[0], row[1], row[2]])
	for i in 6:
		patio_people.append(["", "club_patio", _crowd_at[i * 4]])


func _build_ui() -> void:
	var pt: float = hud.pt if hud != null else 1.0
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _box(Color(0.03, 0.03, 0.04, 0.85), VIOLET))
	top.position = Vector2(16, 16) * pt
	_ui.add_child(top)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", int(16 * pt))
	_title.add_theme_color_override("font_color", VIOLET)
	top.add_child(_title)
	_talk = PanelContainer.new()
	_talk.add_theme_stylebox_override("panel", _box(Color(0.03, 0.03, 0.04, 0.9), VIOLET))
	_talk.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_talk.position = Vector2(16 * pt, 0)
	_talk.custom_minimum_size = Vector2(360, 0) * pt
	_talk.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(_talk)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * pt))
	_talk.add_child(row)
	_face = Portraits.badge(40 * pt)
	row.add_child(_face)
	var v := VBoxContainer.new()
	row.add_child(v)
	_who = Label.new()
	_who.add_theme_font_size_override("font_size", int(13 * pt))
	_who.add_theme_color_override("font_color", VIOLET)
	v.add_child(_who)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.x = 340 * pt
	_line.add_theme_font_size_override("font_size", int(14 * pt))
	v.add_child(_line)
	_line_en = Label.new()
	_line_en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_en.custom_minimum_size.x = 340 * pt
	_line_en.add_theme_font_size_override("font_size", int(11 * pt))
	_line_en.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	v.add_child(_line_en)
	var buttons := HBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.add_theme_constant_override("separation", int(10 * pt))
	_ui.add_child(buttons)
	_dance_btn = _button(buttons, "TAŃCZ", "dance", pt)
	_dance_btn.pressed.connect(_on_dance)
	_patio_btn = _button(buttons, "PATIO", "patio", pt)
	_patio_btn.pressed.connect(go_patio)
	_sala_btn = _button(buttons, "SALA", "inside", pt)
	_sala_btn.pressed.connect(go_sala)
	var out := _button(buttons, "WYJDŹ", "leave", pt)
	out.pressed.connect(leave)
	_beat = Control.new()
	_beat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat.draw.connect(_draw_beat)
	_dance_btn.add_child(_beat)
	_beat.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport().get_visible_rect().size
	_talk.position.y = vp.y - 16 * pt
	buttons.position = vp - Vector2(16, 16) * pt


func _button(parent: Node, pl: String, en: String, pt: float) -> Button:
	if hud != null and hud.has_method("_chip"):
		var b: Button = hud._chip(parent, pl, en, VIOLET)
		b.custom_minimum_size = Vector2(96, 52) * pt
		return b
	var c := Button.new()
	c.text = pl
	c.custom_minimum_size = Vector2(96, 52) * pt
	parent.add_child(c)
	return c


static func _box(bg: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(2)
	s.set_content_margin_all(10)
	return s


func _draw_beat() -> void:
	var ph := fmod(_beat_time() * _bpm() / 60.0, 1.0)
	var a := 1.0 - ph
	_beat.draw_rect(Rect2(Vector2.ZERO, _beat.size).grow(-2.0 - ph * 6.0), Color(VIOLET, a * 0.9), false, 3.0)
	if streak > 0:
		_beat.draw_string(ThemeDB.fallback_font, Vector2(4, 14), "×%d" % streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


# --- going in and out -----------------------------------------------------------------------

## In: the room built (once) in `world`, shown, the radio on MORDOR FM, the panel up.
func enter(world: Node3D, pl: String, en: String, mordor: int) -> void:
	if not _built:
		_build(world)
	title_pl = pl
	title_en = en
	_title.text = "%s · w środku / inside" % pl
	danced = 0
	streak = 0
	_red_in = _rng.randf_range(RED_GAP.x, RED_GAP.y)
	inside = true
	_mordor_i = mordor
	_go("sala")
	_say(people[0])
	_log("in: %s" % pl)


## Out to the patio: the yard, the mirror ball, lighter music, the room's kick through the wall.
func go_patio() -> void:
	if inside and area != "patio":
		_go("patio")
		_say(patio_people[0])
		_log("patio")


## Back into the room from the patio.
func go_sala() -> void:
	if inside and area != "sala":
		_go("sala")
		_say(people[0])
		_log("sala")


func _go(where: String) -> void:
	area = where
	var patio := where == "patio"
	centre = (PATIO_AT if patio else PLACE) + Vector3(0, 1.2, 0)
	view_size = PATIO_VIEW if patio else VIEW
	_title.text = "%s · %s" % [title_pl, "patio" if patio else "w środku / inside"]
	_lights.position = PATIO_AT if patio else PLACE
	_show(true)
	_music_on(MUSIC_PATIO if patio else MUSIC_SALA)
	if radio != null:
		var want := _mordor_i
		if patio and radio.has_method("polnoc_index") and int(radio.polnoc_index()) >= 0:
			want = int(radio.polnoc_index())
		if want >= 0 and int(radio.station) != want:
			radio.tune(want)


func leave() -> void:
	if not inside:
		return
	inside = false
	_show(false)
	_music_on("")
	area = "sala"
	_log("out (danced %d)" % danced)
	left.emit()


## The club's loop `path` (looped forward, from its start) with the radio ducked under it; ""
## stops it and gives the radio back. Silent headless.
func _music_on(path: String) -> void:
	if radio != null and "duck_db" in radio:
		if path != "" and _music == null:
			_radio_duck = float(radio.duck_db)
		radio.duck_db = RADIO_DUCK_DB if path != "" else _radio_duck
	if DisplayServer.get_name() == "headless":
		return
	if _music == null:
		_music = AudioStreamPlayer.new()
		_music.bus = &"SFX"
		add_child(_music)
	if path == "":
		_music.stop()
		_music.stream = null
		return
	if not _streams.has(path):
		if not ResourceLoader.exists(path):
			return
		var w := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		_streams[path] = w
	_music.stream = _streams[path]
	_music.volume_db = PATIO_MUSIC_DB if path == MUSIC_PATIO else MUSIC_DB
	_music.play()


## The music's time in seconds (the loop's playback position, so the beat is on the music);
## the frame clock when nothing plays (headless, the checks).
func _beat_time() -> float:
	if _music != null and _music.playing:
		return _music.get_playback_position() + AudioServer.get_time_since_last_mix()
	return _clock


func _bpm() -> float:
	return PATIO_BPM if area == "patio" else BPM


func _show(on: bool) -> void:
	var patio := area == "patio"
	_room.visible = on and not patio
	_dancers.visible = on and not patio
	_patio.visible = on and patio
	_crowd.visible = on and patio
	_lights.visible = on
	_ui.visible = on
	_talk.visible = false
	_patio_btn.visible = not patio
	_sala_btn.visible = patio


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside or dt <= 0.0:
		return
	_clock += dt
	_pose_lights()
	_dance_t -= dt
	if _dance_t <= 0.0:
		_dance_t = 1.0 / 15.0
		if area == "patio":
			_sway()
		else:
			_dance()
	_beat.queue_redraw()
	if area == "patio":
		return
	_red_in -= dt
	if _red_in <= 0.0 and _red_t <= 0.0:
		_red_t = RED_LONG
		_red_in = _rng.randf_range(RED_GAP.x, RED_GAP.y)
		_say(["DJ", "club_red", people[0][2]])
	_red_t = maxf(0.0, _red_t - dt)


## The lights in the room: BEAMS cones from the two trusses down onto the floor, swinging on the
## beat; LASERS from the booth fanning over the heads; the strobe from the ceiling (none with
## `calm`). All red while the "sprinklers" go off.
static func room_lights(t: float, calm: bool, red: bool) -> Array:
	var out: Array = []
	var beat := t * BPM / 60.0
	var cols := [Color("#b44cff"), Color("#3ad8ff"), Color("#ff3ad0"), Color("#ffffff"), Color("#3ad8ff"), Color("#b44cff")]
	for i in Rave.BEAMS:
		var back := i < Rave.BEAMS / 2
		var k := i % (Rave.BEAMS / 2)
		var base := Vector3(-5.0 + k * 5.0, 5.3, -ROOM.y * 0.5 + 3.0 if back else 2.0)
		var sway := sin(beat * PI * 0.25 + k * 1.3 + (0.0 if back else 2.0)) * 0.5
		var tilt := cos(beat * PI * 0.125 + k) * 0.35
		var dir := Vector3(sin(sway), -1.0, sin(tilt) + (0.25 if back else -0.1)).normalized()
		out.append([Rave._aim(base, dir, 0.9, 5.6), Color(1, 0.05, 0.08) if red else cols[i] * 0.8])
	for i in Rave.LASERS:
		var a := (float(i) / (Rave.LASERS - 1) - 0.5) * 1.2 + sin(beat * PI * 0.5) * 0.3
		var dir := Vector3(sin(a), 0.02 + 0.05 * sin(beat * PI + i), cos(a)).normalized()
		var c := Color(1, 0.05, 0.08) if red else Color(0.2, 1.0, 0.35) * (0.35 if calm else 0.9)
		out.append([Rave._aim(Vector3(0, 2.3, -ROOM.y * 0.5 + 2.8), dir, 0.05, 13.0), c])
	var flash := 0.0
	if not calm and not red:
		flash = 1.0 if fmod(beat * 0.5, 1.0) < 0.12 else 0.0
	out.append([Rave._aim(Vector3(0, 5.4, 1.0), Vector3.DOWN, 4.0, 5.4), Color(1, 1, 1) * flash])
	return out


func _pose_lights() -> void:
	var mm := _lights.multimesh
	var pose := patio_lights(_clock) if area == "patio" else room_lights(_clock, Access.calm, _red_t > 0.0)
	for i in pose.size():
		mm.set_instance_transform(i, pose[i][0])
		mm.set_instance_color(i, pose[i][1])


func _dance() -> void:
	var dm := _dancers.multimesh
	var beat := _beat_time() * BPM / 60.0
	for i in _floor.size():
		var f := _floor[i]
		var ph := fmod(beat + f.y * 0.3, 1.0)
		var hop := 0.12 * (1.0 - absf(ph * 2.0 - 1.0))
		var yaw_i := PI + sin(beat * PI * 0.5 + f.y * 6.0) * 0.4
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw_i), Vector3(f.x, hop, f.z)))
	var nod := 0.05 * absf(sin(beat * PI))
	dm.set_instance_transform(DANCERS, Transform3D(Basis.IDENTITY, people[0][2] + Vector3(0, nod, 0)))
	var zh := 0.1 * (1.0 - absf(fmod(beat, 1.0) * 2.0 - 1.0))
	dm.set_instance_transform(DANCERS + 1, Transform3D(Basis(Vector3.UP, PI + sin(beat) * 0.3), people[1][2] + Vector3(0, zh, 0)))


## The patio's crowd: most chat and sway slowly in small turns, every third one dances.
func _sway() -> void:
	var dm := _crowd.multimesh
	var beat := _beat_time() * PATIO_BPM / 60.0
	for i in _crowd_at.size():
		var f := _crowd_at[i]
		var dancer := i % 3 == 0
		var ph := fmod(beat + f.y, 1.0)
		var hop := (0.08 if dancer else 0.02) * (1.0 - absf(ph * 2.0 - 1.0))
		var yaw_i := f.y * TAU + sin(beat * PI * (0.5 if dancer else 0.12) + f.y * 6.0) * (0.5 if dancer else 0.25)
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw_i), Vector3(f.x, hop, f.z)))


# --- taps -----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not inside or cam == null:
		return
	var at := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			leave()
		elif event.keycode == KEY_SPACE:
			_on_dance()
		return
	if at == Vector2.INF:
		return
	var who := pick(at)
	if who >= 0:
		_say(_here()[who])
		get_viewport().set_input_as_handled()


## The person under screen point `at` (the view's pixels): the nearest within TAP_R m of the ray
## at chest height, or -1.
func pick(at: Vector2) -> int:
	var vp := cam.get_viewport()
	var scale := Vector2(vp.get_visible_rect().size) / get_viewport().get_visible_rect().size
	var p := at * scale
	var from := cam.project_ray_origin(p)
	var dir := cam.project_ray_normal(p)
	var best := -1
	var best_d := TAP_R
	var list := _here()
	var origin := PATIO_AT if area == "patio" else PLACE
	for i in list.size():
		var c: Vector3 = origin + (list[i][2] as Vector3) + Vector3(0, 1.2, 0)
		var t := (c - from).dot(dir)
		var d := (from + dir * t).distance_to(c)
		if d < best_d:
			best_d = d
			best = i
	return best


## The people one can tap where one is.
func _here() -> Array:
	return patio_people if area == "patio" else people


func _say(person: Array) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.line(String(person[1]))
	if l.is_empty():
		return
	_who.text = String(person[0]) if String(person[0]) != "" else Lang.pick("Ktoś z tłumu", "Someone in the crowd")
	_line.text = Lang.pick(String(l[0]), String(l[1]))  # one language on screen (lang.gd)
	_line_en.text = ""
	_line_en.visible = false
	Portraits.set_badge(_face, String(person[0]), VIOLET)
	_talk.visible = true
	_talk.reset_size()
	var vp := get_viewport().get_visible_rect().size
	_talk.position.y = vp.y - _talk.size.y - 16.0 * (hud.pt if hud != null else 1.0)


## TAŃCZ: a tap near a beat keeps the streak, else it starts again; STREAK in a row pays.
func _on_dance() -> void:
	var off := beat_offset(_beat_time(), _bpm())
	if off <= BEAT_WINDOW:
		streak += 1
	else:
		streak = 0
	if streak >= STREAK:
		streak = 0
		if danced < DANCE_MAX and wallet != null:
			danced += 1
			wallet.pay(0, DANCE_PAY, "club_dance")
			_say(["Mati", "club_dance", people[1][2]])
			_log("dance paid (%s, %d)" % [area, danced])
		elif danced >= DANCE_MAX:
			_say(["Mati", "club_dance", people[1][2]])


## On the beat (for the check): seconds from `t` to the nearest beat.
static func beat_offset(t: float, bpm := BPM) -> float:
	var beat := t * bpm / 60.0
	return absf(beat - roundf(beat)) * 60.0 / bpm


func _log(text: String) -> void:
	if log_on:
		print("club: " + text)
