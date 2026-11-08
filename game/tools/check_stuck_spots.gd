extends SceneTree
## PT bug log (docs/PLAYTEST.md): the spots where a playtest found the car stopping dead, driven
## again by the real car script (car.gd) in the real city (the sectors round the spots, built from
## their files, or the prebuilt sector scenes with --prebuilt), gas held, no steering, no traffic.
## Each spot is a start, a heading and a speed; the car fails it if it sits under STALL m/s for
## more than STALL_TIME s, needs an unstick, or ends under its share of the start speed.
##
## PT-1 (2026-11-02): at 24-30 m/s the car stopped dead on Marszałkowska's west kerb line north of
## the start. It had driven inside Centrum's 0.9 m tram platform (not solid, so the car rode in the
## slab) and hit the shelter on it end on; brushing the fence along the kerb cost 1.2/s of its whole
## speed. Fixed: platforms that high are solid at their edges away from roads (map_builder.gd
## SOLID_PLATFORM, PLATFORM_ROAD_CLEAR) and
## the scrape scales with how hard the car presses in (car.gd SCRAPE_PRESS).
##
## PT-4 (2026-11-02): hard stops on Marszałkowska by Rondo Dmowskiego, among the underpass stairs;
## after the roundabout's rebuild (site `rondo`) the lanes up to the ring drive clean.
##
## PT-2 and PT-5 (2026-11-02): suspects from the Autopilot runs (a block NE of Plac Defilad, the side
## streets west of Marszałkowska). Not reproduced: ~680 straight lines (every 40 m, both ways, both
## areas, 12 m/s with the gas held) along the real road centrelines stop only at dead ends and
## road ends, and kerb-hugging lines stop only at the walls and houses past the kerb. The agent's
## stops there were off-route wandering into courtyards and gated service roads. Six lines
## along the main streets stay as guards.
##
## (Head on into the platform's 3 m end the car stops, as at any wall, and is turned out.)
##
## PT-7 (2026-11-02): by the curved glass corner of Chmielna and Bracka (Zgoda's end) a car held
## towards Krucza, sliding along the block's front, caught its front corner in a 3 m notch where two
## buildings meet (-630,186) and in the 0.5 m slit and 0.3 m step between the glass building and
## Jabłkowski's (-596,190): pinned, turned out, pinned again, towed. The playtest's camera ghosted
## the building, so the frames showed no wall. Fixed: low collider walls across slits and small
## notches and a taper in front of small steps (map_builder.gd `_bridge_pockets`). These spots
## steer like the point-to-steer stick held one way (an 8th field: the compass heading held).
##
## PT-17 (2026-11-03): following the KASETA arrow by car at Plac Dąbrowskiego, the playtest car went
## back and forth on Jasna's east pavement for 70 s until the tow. Jasna's facade there (by the
## square's corner) has a 24 m bay 2.3 m deep between two rounded piers 2 m proud: a car whose
## stick points into the block slid along the bay into one pier, was turned out along the wall into
## the other, and so on. Fixed: bays up to 30 m wide and 2.5 m deep get a wall across the mouth too
## (map_builder.gd BAY_MOUTH, BAY_DEPTH). 4 spots slide along it both ways (all 4 fail on the old map).
##
## PT-18 (2026-11-03): under the Trasa Łazienkowska, Solec's ramp up to the Trasa (deck group 7)
## crosses Solec 5 m up. On the ramp, where it turns west over Solec, the mapped guard rail comes
## in pieces 0.9 m apart with the parapet 0.5 m behind: a car sliding along it put its front corner
## in a gap and caught the next piece's end, pinned at (1307, 959) (the playtest's 1.6 s stop at
## (1308, 960)). Under the ramp, its pier stood 2 m off Solec's west kerb: a car on the kerb lane
## drifting 5° west hit it head on. Fixed: guard rail gaps under 1.5 m on a deck get a shallow V behind the rail line (lanes cut through stay clear)
## (map_builder.gd GUARD_JOIN), and piers keep 2 m more room beside a main road wherever their
## slide finds it (tools/bake_structures.py PIER_ROADSIDE; 44 of 359 piers moved 1-2 m). All but
## the last spot fail on the old map; a car that leaves Solec 3 m or more onto the verge can still
## meet the pier, as at any pier.
##
## PT-44 (2026-11-08, Autopilot hunt 2): on Trasa W-Z by the Stare Miasto tram stop the car went
## 57 to 0 km/h in 0.2 s at (-589, -1421), nothing seen touching it. On the pavement south of the
## carriageway a retaining wall turns solid in mid-run (where its step passes 0.6 m) with a square
## end on its line at (-587.2, -1421.6); a car half over the low ground beside it met that end
## 0.2 m off its middle, further in than the corner slip's reach. Across the road, the mapped
## tram shelter's corner (-600, -1404.8), 1.1 m past the kerb, stopped a car 0.7 m over the kerb the
## same way. Fixed: a fixed thing's end met nose on that a sidestep of at most 1.1 m clears slips the
## car past (car.gd SLIP_WIDE). The first and third spots fail on the old car; the second (the low
## strip beside the wall) guards against a fix that walls the strip.
##
## PT-45 (2026-11-08, same run): 26 to 1 km/h in 1 s in the W-Z tunnel's west part (-742, -1404),
## the car hidden in every frame. Not reproduced: 16 lines through the tunnel both ways, 7.5 m/s
## and the gas held, drive clean (glancing touches of the walls only); the most likely cause is a
## traffic car met in the tube (G17 lets the car through after 1.5 s, the crawl the log saw).
## Three lines stay as guards. These spots start on the tunnel's floor (a 9th field), not the
## street above it.
##
## Prints one line per spot and `check_stuck_spots: OK`, or the failures and exit 1. ~10 s on the Mac.
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_stuck_spots.gd [-- --prebuilt --verbose]

const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const INDEX_JSON := "res://map/index.json"
const INDEX_SCENE := "res://map/index.res"

## [x, z, compass heading, start speed m/s, seconds, the share of the start speed kept at the end, what,
## optional: the compass heading the stick points to (point-to-steer, held; null for none),
## optional: true to start on a tunnel's floor].
const SPOTS := [
	[-1013.0, -45.0, -20.0, 27.0, 4.0, 0.9, "PT-1 Marszałkowska, the left lane along Centrum's tram-stop fence"],
	[-1013.0, -45.0, -25.0, 27.0, 3.0, 0.85, "PT-1 Marszałkowska, drifting 5° into the tram-stop fence"],
	[-1001.2, -5.0, -20.0, 27.0, 4.0, 0.8, "PT-1 Marszałkowska, the left side clipping the tram platform's north tip"],
	[-1025.0, -45.0, -20.0, 27.0, 4.0, 0.9, "PT-1 Marszałkowska, the tram tracks west of the platform"],
	[-1025.0, -45.0, -12.0, 27.0, 4.0, 0.5, "PT-1 Marszałkowska, off the tram tracks into the platform's side (the dead stop on the shelter)"],
	[-797.9, 527.0, -20.0, 25.0, 1.8, 0.8, "PT-4 Marszałkowska north to Rondo Dmowskiego, the inner lane past the south-east stairs"],
	[-795.0, 526.0, -20.0, 25.0, 1.8, 0.8, "PT-4 Marszałkowska north to Rondo Dmowskiego, the middle lane"],
	[-792.2, 525.0, -20.0, 25.0, 1.8, 0.8, "PT-4 Marszałkowska north to Rondo Dmowskiego, the kerb lane"],
	[-874.9, 395.1, 160.0, 25.0, 1.8, 0.8, "PT-4 Marszałkowska south to Rondo Dmowskiego, past the north-west stairs"],
	[-730.0, -250.0, -4.0, 12.0, 2.5, 0.8, "PT-2 Mazowiecka north of Plac Defilad"],
	[-413.0, -332.0, 75.0, 12.0, 2.5, 0.8, "PT-2 Świętokrzyska towards Nowy Świat"],
	[-387.0, -187.0, 168.0, 12.0, 2.5, 0.8, "PT-2 Nowy Świat, the pedestrian-street stretch"],
	[-359.0, -68.0, 164.0, 12.0, 2.5, 0.8, "PT-2 Nowy Świat south"],
	[-2225.0, 30.0, -21.0, 12.0, 2.5, 0.8, "PT-5 Żelazna, west of Marszałkowska"],
	[-2365.0, 288.0, -97.0, 12.0, 2.5, 0.8, "PT-5 Prosta, west of Marszałkowska"],
	[-616.0, 180.0, 253.0, 7.0, 3.0, 0.0, "PT-7 west along Chmielna's block, the stick into it past the notch at Zgoda", 230.0],
	[-620.0, 181.0, 253.0, 7.0, 3.0, 0.0, "PT-7 west along Chmielna's block, the stick south-west past the notch", 200.0],
	[-612.0, 176.0, 78.0, 7.0, 3.0, 0.0, "PT-7 Chmielna east, the stick to Krucza along the glass corner (the slit)", 150.0],
	[-606.0, 180.0, 110.0, 7.0, 3.0, 0.0, "PT-7 across the Chmielna square to Krucza, along the glass corner", 150.0],
	[-936.5, -298.0, 157.0, 7.0, 3.0, 0.0, "PT-17 Jasna south from Plac Dąbrowskiego, the stick into the bay", 120.0],
	[-936.5, -298.0, 157.0, 12.0, 3.0, 0.0, "PT-17 Jasna south, faster, the stick south-east", 135.0],
	[-930.0, -283.0, 337.0, 7.0, 3.0, 0.0, "PT-17 Jasna's pavement north to the square, the stick north-north-east", 30.0],
	[-930.0, -283.0, 337.0, 7.0, 3.0, 0.0, "PT-17 Jasna's pavement north, the stick north-east (to the BUW tape)", 60.0],
	[1327.0, 980.0, 330.0, 10.0, 5.0, 0.0, "PT-18 up Solec's ramp to the Trasa, the stick west-north-west along the rail", 300.0],
	[1333.5, 1004.0, 347.0, 10.0, 5.0, 0.5, "PT-18 from the ramp's foot, the stick west-north-west", 300.0],
	[1332.0, 1000.0, 345.0, 10.0, 5.0, 0.8, "PT-18 up the ramp, the stick west round the turn", 260.0],
	[1311.0, 985.0, 342.0, 10.0, 4.0, 0.5, "PT-18 Solec north under the ramp, the kerb lane drifting 5° west past its pier"],
	[1312.5, 985.0, 338.0, 10.0, 4.0, 0.5, "PT-18 Solec north under the ramp, drifting 9° west"],
	[1305.0, 985.0, 342.0, 10.0, 4.0, 0.5, "PT-18 Solec's west verge north, west of the pier"],
	# Smooth roads round 4 (F, 2026-11-05): through the U-turn's opening in the Marszałkowska tram
	# median at Złota, from the southbound mouth onto the northbound carriageway, the stick to the
	# north-north-east: no kerb, nose or rail end on the way (the car speeds up all the way).
	[-962.0, 139.3, 100.0, 6.0, 2.5, 1.0, "Smooth roads 4: the U-turn through Marszałkowska's tram median at Złota", 30.0],
	[-625.0, -1420.5, 88.0, 16.0, 3.0, 0.8, "PT-44 W-Z east, the pavement by Stare Miasto's stop, half over the low ground into the wall's solid end"],
	[-625.0, -1419.5, 83.0, 16.0, 3.0, 0.8, "PT-44 W-Z east, onto the low strip beside the wall"],
	[-545.0, -1411.5, -97.0, 16.0, 3.0, 0.8, "PT-44 W-Z west, drifting over the kerb into the tram shelter's corner"],
	[-700.0, -1401.5, -86.0, 7.5, 3.0, 0.8, "PT-45 the W-Z tunnel west, the inner lane", null, true],
	[-700.0, -1404.0, -86.0, 7.5, 3.0, 0.8, "PT-45 the W-Z tunnel west, the outer lane", null, true],
	[-790.0, -1396.5, 86.0, 7.5, 3.0, 0.8, "PT-45 the W-Z tunnel east", null, true],
]
## Sectors within this of a spot are loaded.
const REACH := 300.0
const STALL := 3.0
const STALL_TIME := 0.5

var prebuilt := false
var verbose := false
var map: Node3D
var car: CharacterBody3D
var _frames := 0
var _i := -1
var _t := 0
var _stalled := 0.0
var _worst := 0.0
var _v0 := 0.0
var _failures := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--prebuilt":
			prebuilt = true
		elif a == "--verbose":
			verbose = true
	var t0 := Time.get_ticks_msec()
	if prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
		root.add_child(map)
	else:
		map = MapBuilder.new()
		root.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	var n := 0
	for k: Array in map.index_data["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := Rect2(key.x * MapBuilder.SECTOR, key.y * MapBuilder.SECTOR, MapBuilder.SECTOR, MapBuilder.SECTOR)
		var near := false
		for s: Array in SPOTS:
			near = near or rect.grow(REACH).has_point(Vector2(s[0], s[1]))
		if not near:
			continue
		var r: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
				if prebuilt else map.build_sector(key)
		map.add_child(r)
		n += 1
	if not prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	print("check_stuck_spots: %d sectors %s in %d ms%s" % [n, "loaded" if prebuilt else "built", Time.get_ticks_msec() - t0,
			"" if prebuilt else ", %d pocket walls, %d guard rail gaps closed" % [map.pocket_walls, map.guard_joins]])


func _next() -> bool:
	if car != null:
		car.queue_free()
	_i += 1
	if _i >= SPOTS.size():
		return false
	var s: Array = SPOTS[_i]
	car = Car.new()
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	car.global_position = Vector3(s[0], map.ground_height(s[0], s[1]), s[1])
	if s.size() > 8 and s[8]:
		car.global_position.y = map.tunnel_floor_under(s[0], s[1])
	car.rotation.y = -deg_to_rad(float(s[2]))
	car.vel = -car.global_transform.basis.z * float(s[3])
	car.forward_speed = float(s[3])
	car.throttle = 1.0
	if s.size() > 7 and s[7] != null:
		var aim := deg_to_rad(float(s[7]))
		car.target_dir = Vector3(sin(aim), 0.0, -cos(aim))
	_v0 = float(s[3])
	_t = 0
	_stalled = 0.0
	_worst = 0.0
	return true


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if car == null:
		return not _next()
	_t += 1
	var s: Array = SPOTS[_i]
	var v := Vector2(car.vel.x, car.vel.z).length()
	_stalled = _stalled + dt if v < STALL else 0.0
	_worst = maxf(_worst, _stalled)
	if verbose and _t % 15 == 0:
		print("   t=%.2f at %.1f, %.1f  %.1f m/s%s" % [_t * dt, car.global_position.x, car.global_position.z, v,
				"  touching" if car.get_slide_collision_count() > 0 else ""])
	if _t * dt < float(s[4]):
		return false
	var why: Array[String] = []
	if _worst > STALL_TIME:
		why.append("stalled under %.0f m/s for %.1f s" % [STALL, _worst])
	if int(car.unsticks) > 0:
		why.append("unstuck %d×" % int(car.unsticks))
	if v < _v0 * float(s[5]):
		why.append("ended at %.1f m/s, under %.0f %% of %.0f" % [v, float(s[5]) * 100.0, _v0])
	var p := car.global_position
	print("%s %s: %.1f → %.1f m/s, at %.0f, %.0f%s  (--at=%.0f,%.0f --heading=%.0f)" % [
			"FAIL" if not why.is_empty() else "ok  ", s[6], _v0, v, p.x, p.z,
			"" if why.is_empty() else " · " + ", ".join(why), s[0], s[1], s[2]])
	if not why.is_empty():
		_failures += 1
	if _next():
		return false
	if _failures == 0:
		print("check_stuck_spots: OK")
	else:
		print("check_stuck_spots: %d of %d spots fail" % [_failures, SPOTS.size()])
	quit(1 if _failures > 0 else 0)
	return false
