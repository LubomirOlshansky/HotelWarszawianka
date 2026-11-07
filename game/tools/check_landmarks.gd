extends SceneTree
## v0.8 landmarks, checked without looking: for every landmark, is it solid for the car
## (rays at bumper height from all round hit a wall near its outline), does the
## helicopter's roof grid hold its shape (tallest cell, the cells round the spire), does a
## tap from the camera find it, and where would a roof rescue on it land.
##   godot --headless --path game --script res://tools/check_landmarks.gd [-- --grid=OUT.png]
## --grid writes the landmarks' roof-grid cells (4 m, one colour per landmark, red = id)
## and their info (bounds) for tools/overlay_landmarks.py, which lays them over the
## orthophoto.

## Sites that are only ground-level dressing (no part over about 2 m): the heli test expects it to
## fly over them, not to be stopped. bulwary_basen (K7, 2026-11-02): the splash pool, its 0.3 m
## rim and fish on 0.55 m plinths, under 2 m in all.
## bazar (2026-11-02): Bazar Różyckiego's stalls and kiosks stand 2.5-3.4 m, under the 6 m floor the heli flies at.
## plac_centralny and its lamps (2026-11-05): the seat-wall, steps and lamp posts stand 1-5 m, under the heli's 6 m floor.
## monkey_love (2026-11-07): the garden cabins stand under 4 m.
## port_wtw, port_halls, port_basin (2026-11-07): Port Czerniakowski's boathouse and halls stand 3.6-5 m to the eaves, the moored boats under 2 m (masts are lines).
## Towarowa 22 is a quarter: its box's middle is the printing hall's open frame and the 28 m tanks
## block, under the heli's 45 m; its towers stand at the box's west edge and stop it there.
const FLY_OVER := ["monkey_love", "port_wtw", "port_halls", "port_basin", "bulwary_basen", "bazar", "towarowa22", "plac_centralny", "plac_centralny_lamps", "sunken", "underpass"]
## Monuments lower than the heli's 6 m floor (the monuments pass, part 2): it flies at this height
## instead, so their bronze and stone have to stop it.
const LOW_MONUMENTS := {"maly_powstaniec": 1.5, "starzynski": 2.5, "umschlagplatz": 2.5, "pomnik_wschod": 3.0}

var map: Node3D
var _frames := 0


func _initialize() -> void:
	# Loop 3c: the streamed city, every sector built from its file (the runtime path).
	map = load("res://scripts/sector_streamer.gd").open_whole(root, "--prebuilt" in OS.get_cmdline_user_args())


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	# Exit 1 on a failure, so tools/verify.sh and CI see it without reading the line.
	quit(0 if _check() == 0 else 1)
	return true


func _check() -> int:
	var space: PhysicsDirectSpaceState3D = map.get_world_3d().direct_space_state
	var missions: Node = load("res://scripts/missions.gd").new()
	missions.map = map
	var data: Dictionary = map.data
	var failures := 0
	for k in map.landmark_info.size():
		var info: Dictionary = map.landmark_info[k]
		if info["pl"] == "":
			continue  # a skin with no card (Królewska's block) is off the picking grid on purpose
		var c: Vector2 = info["centre"]
		# The tallest roof-grid cell near the centre, and what a tap straight down finds.
		var tallest := -INF
		var at := c
		var box: Rect2 = info["box"]
		for dz in range(0, int(box.size.y) + 1, 4):
			for dx in range(0, int(box.size.x) + 1, 4):
				var x := box.position.x + dx
				var z := box.position.y + dz
				if map.landmark_at(x, z) == k and map.roof_height(x, z) > tallest:
					tallest = map.roof_height(x, z)
					at = Vector2(x, z)
		c = at  # a site of several pieces (the bridge's towers): test at its tallest one
		var ground: float = map.terrain_height(c.x, c.y)
		# A tap from the game's camera angle (30° down) aimed just under the cell's top.
		var aim := Vector3(at.x, tallest - 1.0, at.y)
		var tap: int = map.pick_landmark(aim + Vector3(0.0, 500.0, 866.0), Vector3(0.0, -0.5, -0.866))
		# Hidden from the camera by a building in front (the PZU Tower behind Q22) or a
		# neighbour's roof in the cell next to it (BUW's east edge): a tap from straight above.
		var above := ""
		if tap != k:
			var hid := tap
			tap = map.pick_landmark(Vector3(at.x, tallest + 500.0, at.y), Vector3.DOWN)
			if tap == k:
				above = " (from above: %s in front)" % (map.landmark_info[hid]["name"] if hid >= 0 else "a neighbour's roof")
		# A car driving in from 12 directions (2 m steps at bumper height over the ground,
		# from 220 m out to the centre, or from past the site's far corner when it is bigger,
		# such as Arkadia's 300 m block): does a wall stop it before the middle?
		var reach := 220.0
		for corner in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			reach = maxf(reach, c.distance_to(corner) + 10.0)
		var hits := 0
		for d in 12:
			var dir := Vector2.from_angle(TAU * d / 12.0)
			var r := reach
			while r > 4.0:
				var p0 := c + dir * r
				var p1 := c + dir * (r - 2.0)
				var q := PhysicsRayQueryParameters3D.create(Vector3(p0.x, map.drive_height(p0.x, p0.y, 0.0) + 0.8, p0.y),
						Vector3(p1.x, map.drive_height(p1.x, p1.y, 0.0) + 0.8, p1.y))
				if not space.intersect_ray(q).is_empty():
					hits += 1
					break
				r -= 2.0
		print("%-22s tallest cell %5.1f m above ground at %s · tap finds %s · car rays stopped %d/12" % [
				info["name"], tallest - ground, at.round(), ("it" + above) if tap == k else "id %d" % tap, hits])
		# A bridge's pylon stands in the median between two carriageways: a car from along the
		# deck passes beside it, so Most Świętokrzyski needs fewer stopped rays.
		# A moored barge (barka_*, and the floating Dworzec Wodny) lies in the river: only the rays from the bank side meet a car's
		# way, the others start over the water (2026-11-02, the first CI map run: 7-8 of 12).
		var need := 6 if info["key"] == "swieto" else 10
		if str(info["key"]).begins_with("barka_") or info["key"] == "dworzec_wodny":
			need = 5  # Dworzec Wodny floats at the boulevard's edge like the barges
		if tap != k or hits < need:
			failures += 1
	# Roof rescues that the landmarks' outlines now give (missions.gd's own search).
	for l in data.get("landmarks", []):
		if l["name"] in ["Pałac Kultury i Nauki", "Rotunda PKO", "Varso Tower", "Złote Tarasy"]:
			var poly := PackedVector2Array()
			var flat: Array = l["p"]
			for i in range(0, flat.size() - 1, 2):
				poly.append(Vector2(flat[i], flat[i + 1]))
			var spot: Vector3 = missions._flat_roof(poly)
			if spot == Vector3.INF:
				print("roof rescue on %s: none (no flat roof 20 m up)" % l["name"])
			else:
				print("roof rescue on %s: %s, %d m up, landmark cell %d" % [l["name"], spot.round(),
						roundi(spot.y - map.ground_height(spot.x, spot.z)), map.landmark_at(spot.x, spot.z)])
	# The Palace's spire: the cells round it stand to its top, so the helicopter can't
	# fly through its base; the helicopter's own test (top_height over its radius).
	for l in map.landmark_info:
		if l["key"] == "palace":
			var best := -INF
			var spire := Vector2.ZERO
			var c: Vector2 = l["centre"]
			for dz in range(-80, 81, 2):
				for dx in range(-80, 81, 2):
					var h: float = map.roof_height(c.x + dx, c.y + dz)
					if h > best:
						best = h
						spire = Vector2(c.x + dx, c.y + dz)
			var g: float = map.terrain_height(spire.x, spire.y)
			print("Palace spire cell %s: top %.1f m above ground; heli top_height there at r=3: %.1f m; 12 m off: %.1f m" % [
					spire.round(), best - g, map.top_height(spire.x, spire.y, 3.0) - g, map.top_height(spire.x + 12.0, spire.y, 3.0) - g])
	missions.free()
	failures += _fly_checks()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--grid="):
			var img := Image.create(map._roof_nx, map._roof_nz, false, Image.FORMAT_RGBA8)
			for j in map._roof_nz:
				for i in map._roof_nx:
					var id: int = map._pick[j * map._roof_nx + i]
					if id > 0:
						img.set_pixel(i, j, Color8(id * 30, 255, 0, 255))
			img.save_png(arg.trim_prefix("--grid="))
			var meta := FileAccess.open(arg.trim_prefix("--grid=").get_basename() + ".json", FileAccess.WRITE)
			var names: Array = []
			for l in map.landmark_info:
				names.append([l["key"], l["name"], l["centre"].x, l["centre"].y])
			meta.store_string(JSON.stringify({"x0": map._roof_x0, "z0": map._roof_z0, "cell": map.ROOF_CELL, "landmarks": names}))
			print("grid written to ", arg.trim_prefix("--grid="))
	print("landmark check: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	return failures


## The helicopter (heli.gd, stepped by hand at 60 Hz) flies at 45 m straight at each
## landmark from 220 m out: it must be stopped before any cell whose top is over its
## skids; then it lands on open ground beside the landmark and must touch down there.
func _fly_checks() -> int:
	var Heli = load("res://scripts/heli.gd")
	var failures := 0
	for k in map.landmark_info.size():
		var info: Dictionary = map.landmark_info[k]
		var box: Rect2 = info["box"]
		var c: Vector2 = box.get_center()
		if info["key"] == "poniatowski":
			c = Vector2(935.0, -128.0)  # the west pair
		elif info["key"] == "swieto":
			c = Vector2(735.0, -896.0)  # the pylon at 45 m (the site is a long strip: its middle is open air)
		elif info["key"] == "arkady":
			c = Vector2(-560.0, -1606.0)  # the arcades' middle (the box holds the gardens: its middle is a lawn)
		if str(info["key"]).begins_with("bulwary_"):
			continue  # the boulevards' 3.6 m pavilions, 2.6 m containers and 25 cm decks: the heli hovers over them
		var heli: Node3D = Heli.new()
		heli.ground_height = map.ground_height
		heli.top_height = map.top_height
		heli.bounds = map.bounds
		root.add_child(heli)
		# Fly at half the landmark's height (45 m at most), so it has to stop at its walls.
		var top := 0.0
		var top_at := c
		for dz in range(0, int(box.size.y) + 1, 4):
			for dx in range(0, int(box.size.x) + 1, 4):
				var x := box.position.x + dx
				var z := box.position.y + dz
				if map.landmark_at(x, z) == k:
					var h: float = map.roof_height(x, z) - map.terrain_height(x, z)
					if h > top:
						top = h
						top_at = Vector2(x, z)
		if info["key"] in ["elektrownia", "stadion_pkp", "ostrogski", "mpw", "equator2", "bulwary_pawilony", "bulwary_bary", "umschlagplatz", "pomnik_wschod"]:
			c = top_at  # open yards, platforms, rows along the river (Ostrogski's courtyard between its two blocks), Umschlagplatz's open enclosure, the Eastern memorial's long low track: the box's middle is air, aim at the tallest cell
		var alt := clampf(top * 0.5, 6.0, 45.0)
		if info["key"] == "arkady":
			alt = 5.0  # the arcade wall stands 7.5 m over the Lower Garden; the castle's roofs in the box are higher
		elif info["key"] == "zamek":
			alt = 22.0  # the Clock Tower's thin helm (56 m) would lift the heli over the 25 m roofs into the yard
		elif info["key"] == "arkadia":
			alt = 12.0  # the sign tower's 49 m crown would lift the heli over the 21 m deck it aims at
		elif info["key"] == "tr":
			alt = 6.0  # a building site: the cranes are thin, the theatre's closed floors stand 9 m
		elif info["key"] == "sw_anna":
			alt = 8.0  # the bell tower's trim (38 m) stands in the box but away from the nave the heli aims at
		elif str(info["key"]).begins_with("church_"):
			alt = 6.0  # the kit's towers (25-34 m) stand at the front, away from the nave the heli aims at (eave 7.5 m and up)
		elif str(info["key"]).begins_with("barka_"):
			alt = 4.0  # the decks stand 6.6-6.7 m: at the 6 m floor the heli skims over the rail
		elif info["key"] == "dtc":
			alt = 10.0  # the 17.5 m stores share roof cells with the Eastern Wall's 70 m slabs behind them
		elif info["key"] == "syrenka_powisle" or info["key"] == "dworzec_wodny":
			alt = 3.0  # the statue stands 5 m, the water station's roof 4 m: a 6 m heli flies over them
		elif info["key"] == "underpass":
			alt = 35.0  # ground-level stairs; the way in from the east crosses Jerozolimskie's 25 m tenements
		elif info["key"] == "sowa":
			alt = 4.0  # the pavilion stands 7.6-8.5 m over its plinth; the 1950s block behind lifts the default
		elif info["key"] == "tarasy":
			alt = 15.0  # the wave stands 30 m; the towers in its box (110 m) would lift the heli over it
		elif LOW_MONUMENTS.has(info["key"]):
			alt = LOW_MONUMENTS[info["key"]]
		var dir := Vector2(1, 0.35).normalized()
		var start := c + dir * maxf(box.size.length() * 0.5 + 60.0, 160.0)
		heli.place(Vector3(start.x, map.ground_height(start.x, start.y) + alt, start.y), 0.0, alt)
		var inside := false
		var blocked := false
		for f in 900:
			var p: Vector3 = heli.global_position
			var to := Vector2(c.x - p.x, c.y - p.z)
			heli.input_dir = Vector3(to.x, 0, to.y).normalized() * 0.8
			heli._physics_process(1.0 / 60.0)
			blocked = blocked or heli.blocked
			var q: Vector3 = heli.global_position
			if map.roof_height(q.x, q.z) > q.y + 1.0:
				inside = true
		var stop: Vector3 = heli.global_position
		# Then down onto open ground: back off along the way it came until the ground is clear.
		var spot := Vector2(stop.x, stop.z)
		var g0: float = map.ground_height(spot.x, spot.y)
		while map.top_height(spot.x, spot.y, 3.0) > map.ground_height(spot.x, spot.y) + 0.5 and spot.distance_to(c) < 400.0:
			spot += dir * 4.0
		heli.place(Vector3(spot.x, map.ground_height(spot.x, spot.y) + 30.0, spot.y), 0.0, 30.0)
		heli.landing = true
		var landed := false
		for f in 900:
			heli._physics_process(1.0 / 60.0)
			if not heli.landing:
				landed = true  # heli.gd clears `landing` as it touches down
				break
		var ground: float = map.ground_height(spot.x, spot.y)
		# A site that is all ground-level dressing (FLY_OVER) has no wall to stop the heli: it must
		# fly over it (never inside) and land beside it, like any other.
		var over: bool = info["key"] in FLY_OVER
		var ok := (blocked != over) and not inside and landed and absf(heli.global_position.y - ground) < 0.6
		if not ok:
			print("  blocked %s, went inside %s, landed %s, skids %.2f m over the ground" % [blocked, inside, landed, heli.global_position.y - ground])
		print("%-22s heli at %d m: %s, stopped %d m from the middle, %d m up; landed beside it %d m from the middle: %s" % [
				info["name"], roundi(alt), ("blocked" if blocked else "NOT blocked") + (" (flown over by design)" if over else ""), roundi(Vector2(stop.x, stop.z).distance_to(c)),
				roundi(stop.y - g0), roundi(spot.distance_to(c)), "yes" if landed else "NO"])
		if not ok:
			failures += 1
		heli.free()
	return failures
