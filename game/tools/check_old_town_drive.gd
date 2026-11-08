extends SceneTree
## The Old Town drive (F, 2026-11-08: "after finish test the old city with the autopilot"): the
## real car script (car.gd) in the real city (the sectors round the route, built from their files,
## or the prebuilt sector scenes with --prebuilt), steered like the point-to-steer stick towards
## each next waypoint, gas at THROTTLE, no traffic, round the Old Town in legs: Plac Zamkowy,
## Świętojańska past the Cathedral and the Jesuit church, across the Rynek round the Syrenka,
## Nowomiejska, out by the Barbakan onto Podwale and round the walls back to Plac Zamkowy, then
## along the Międzymurze between the walls. The waypoints are open ground at least 3 m from every
## mapped house, LoD2 footprint, city wall, wall, fence and landmark outline and 1 m from every
## flight of steps longer than a doorstep (a clearance search over centrum.json and lod2.json, 2026-11-08).
## A leg fails if the car sits under STALL m/s for more than STALL_TIME s, needs an unstick, or
## does not reach its last waypoint within its time (its length at SLOWEST m/s, plus 10 s).
## Prints one line per leg and `check_old_town_drive: OK`, or the failures and exit 1.
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_old_town_drive.gd [-- --prebuilt --verbose]

const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const INDEX_JSON := "res://map/index.json"
const INDEX_SCENE := "res://map/index.res"

## [name, [x, z, x, z, ...]] (game metres), each leg starting where the last one ended.
const LEGS := [
	["Plac Zamkowy to Świętojańska", [-699.5, -1479.5, -699.5, -1487.5, -699.5, -1495.5, -699.5, -1503.5, -699.5, -1511.5, -699.5, -1519.5, -699.5, -1527.5, -699.5, -1535.5, -699.5, -1543.5, -698.5, -1551.5, -698.5, -1559.5, -700.5, -1567.5, -706.5, -1574.5, -712.5, -1581.5, -718.5, -1587.5, -723.5, -1594.5, -728.5, -1601.5, -731.5, -1609.5, -737.5, -1616.5, -743.5, -1623.5, -749.5, -1629.5, -755.5, -1635.5, -762.5, -1640.5, -766.5, -1642.5]],
	["Świętojańska to Rynek", [-766.5, -1642.5, -770.5, -1649.5, -776.5, -1655.5, -782.5, -1662.5, -787.5, -1669.5, -793.5, -1675.5, -798.5, -1682.5, -799.5, -1690.5, -799.5, -1698.5, -799.5, -1706.5, -799.5, -1714.5, -793.5, -1721.5, -787.5, -1727.5, -784.5, -1734.5]],
	["Rynek to Rynek north corner", [-784.5, -1734.5, -784.5, -1742.5, -784.5, -1750.5, -790.5, -1757.5, -796.5, -1763.5, -802.5, -1769.5, -808.5, -1775.5, -812.5, -1782.5, -814.5, -1784.5]],
	["Rynek north corner to Nowomiejska", [-814.5, -1784.5, -820.5, -1778.5, -826.5, -1772.5, -832.5, -1766.5, -838.5, -1760.5, -846.5, -1757.5, -854.5, -1757.5, -862.5, -1758.5, -868.5, -1764.5, -874.5, -1770.5, -879.5, -1777.5, -885.5, -1784.5, -891.5, -1791.5, -893.5, -1796.5]],
	["Nowomiejska to Podwale at the Barbakan", [-893.5, -1796.5, -889.5, -1789.5, -884.5, -1782.5, -878.5, -1775.5, -872.5, -1768.5, -866.5, -1761.5, -859.5, -1756.5, -851.5, -1756.5, -844.5, -1752.5, -838.5, -1746.5, -832.5, -1740.5, -826.5, -1734.5, -820.5, -1728.5, -814.5, -1722.5, -808.5, -1716.5, -802.5, -1710.5, -800.5, -1702.5, -800.5, -1694.5, -800.5, -1686.5, -800.5, -1678.5, -806.5, -1671.5, -812.5, -1665.5, -818.5, -1659.5, -824.5, -1653.5, -831.5, -1647.5, -837.5, -1641.5, -843.5, -1635.5, -849.5, -1629.5, -856.5, -1624.5, -863.5, -1619.5, -869.5, -1613.5, -875.5, -1607.5, -881.5, -1601.5, -888.5, -1595.5, -894.5, -1589.5, -898.5, -1582.5, -904.5, -1576.5, -911.5, -1572.5, -919.5, -1572.5, -925.5, -1578.5, -931.5, -1584.5, -937.5, -1590.5, -943.5, -1596.5, -949.5, -1603.5, -954.5, -1610.5, -959.5, -1617.5, -963.5, -1624.5, -967.5, -1631.5, -972.5, -1638.5, -977.5, -1645.5, -982.5, -1652.5, -988.5, -1659.5, -993.5, -1666.5, -997.5, -1673.5, -999.5, -1681.5, -1004.5, -1688.5, -1007.5, -1696.5, -1007.5, -1704.5, -1007.5, -1712.5, -1007.5, -1720.5, -1006.5, -1728.5, -1004.5, -1736.5, -1001.5, -1744.5, -999.5, -1752.5, -995.5, -1760.5, -992.5, -1768.5, -988.5, -1775.5, -984.5, -1782.5, -980.5, -1790.5, -976.5, -1798.5, -972.5, -1806.5, -968.5, -1813.5, -964.5, -1821.5, -962.5, -1829.5, -962.5, -1832.5]],
	["Podwale at the Barbakan to Podwale west", [-962.5, -1832.5, -962.5, -1824.5, -966.5, -1817.5, -970.5, -1809.5, -974.5, -1802.5, -978.5, -1794.5, -982.5, -1787.5, -985.5, -1779.5, -989.5, -1772.5, -993.5, -1764.5, -997.5, -1756.5, -1000.5, -1748.5, -1002.5, -1740.5, -1003.5, -1737.5]],
	["Podwale west to Podwale south", [-1003.5, -1737.5, -1005.5, -1729.5, -1007.5, -1721.5, -1007.5, -1713.5, -1007.5, -1705.5, -1007.5, -1697.5, -1005.5, -1689.5, -1000.5, -1682.5, -997.5, -1674.5, -994.5, -1666.5, -988.5, -1659.5, -982.5, -1652.5, -977.5, -1645.5, -972.5, -1638.5, -968.5, -1631.5, -963.5, -1624.5, -959.5, -1617.5, -955.5, -1610.5, -951.5, -1603.5, -951.5, -1595.5, -951.5, -1592.5]],
	["Podwale south to Plac Zamkowy west", [-951.5, -1592.5, -943.5, -1589.5, -937.5, -1583.5, -931.5, -1577.5, -925.5, -1571.5, -917.5, -1570.5, -909.5, -1570.5, -901.5, -1570.5, -893.5, -1571.5, -885.5, -1571.5, -877.5, -1570.5, -870.5, -1565.5, -863.5, -1560.5, -856.5, -1556.5, -849.5, -1551.5, -842.5, -1547.5, -835.5, -1543.5, -828.5, -1539.5, -821.5, -1535.5, -814.5, -1531.5, -807.5, -1527.5, -800.5, -1521.5, -799.5, -1520.5]],
	["Plac Zamkowy west to the Międzymurze's south end", [-799.5, -1520.5, -806.5, -1526.5, -813.5, -1530.5, -820.5, -1534.5, -827.5, -1538.5, -835.5, -1542.5, -842.5, -1546.5, -849.5, -1551.5, -856.5, -1556.5, -863.5, -1560.5, -869.5, -1566.5, -872.5, -1569.5]],
	["the Międzymurze's south end to the Międzymurze's north end", [-872.5, -1569.5, -880.5, -1571.5, -888.5, -1575.5, -894.5, -1581.5, -900.5, -1587.5, -906.5, -1593.5, -912.5, -1600.5, -918.5, -1606.5, -925.5, -1612.5, -931.5, -1618.5, -937.5, -1624.5, -941.5, -1631.5, -944.5, -1639.5, -949.5, -1646.5, -953.5, -1654.5, -957.5, -1661.5, -959.5, -1669.5, -954.5, -1676.5, -947.5, -1682.5, -941.5, -1688.5, -934.5, -1694.5, -927.5, -1699.5, -921.5, -1705.5, -916.5, -1712.5, -918.5, -1720.5, -924.5, -1727.5, -930.5, -1733.5, -936.5, -1739.5, -942.5, -1745.5, -950.5, -1748.5]],
]
const REACH := 200.0
const THROTTLE := 0.45
const STALL := 1.0
const STALL_TIME := 2.0
const SLOWEST := 2.5
## The car aims at the first waypoint more than LOOK m away (a pure-pursuit driver, so it never
## orbits a waypoint it can't turn tight enough for); the leg's last one counts within NEAR m.
const LOOK := 9.0
const NEAR := 5.0

var prebuilt := false
var verbose := false
var map: Node3D
var car: CharacterBody3D
var _frames := 0
var _leg := -1
var _wp := 0
var _t := 0.0
var _stalled := 0.0
var _worst := 0.0
var _limit := 0.0
var _unsticks := 0
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
		var rect := Rect2(key.x * MapBuilder.SECTOR, key.y * MapBuilder.SECTOR, MapBuilder.SECTOR, MapBuilder.SECTOR).grow(REACH)
		var near := false
		for leg: Array in LEGS:
			var pts: Array = leg[1]
			for i in range(0, pts.size(), 2):
				near = near or rect.has_point(Vector2(pts[i], pts[i + 1]))
		if not near:
			continue
		var r: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
				if prebuilt else map.build_sector(key)
		map.add_child(r)
		n += 1
	if not prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	print("check_old_town_drive: %d sectors %s in %d ms" % [n, "loaded" if prebuilt else "built", Time.get_ticks_msec() - t0])


## The car (on the first physics frame: in _initialize it is not in the tree yet), then the first leg.
func _start() -> void:
	var first: Array = LEGS[0][1]
	car = Car.new()
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	car.global_position = Vector3(first[0], map.ground_height(first[0], first[1]), first[1])
	car.throttle = THROTTLE
	_next_leg()


func _next_leg() -> bool:
	_leg += 1
	if _leg >= LEGS.size():
		return false
	var pts: Array = LEGS[_leg][1]
	var length := 0.0
	for i in range(2, pts.size(), 2):
		length += Vector2(pts[i] - pts[i - 2], pts[i + 1] - pts[i - 1]).length()
	_limit = length / SLOWEST + 10.0
	# Each leg starts on its first waypoint at rest, facing the second (so a leg's verdict does not
	# hang on how the last one ended).
	car.global_position = Vector3(pts[0], map.ground_height(pts[0], pts[1]), pts[1])
	car.rotation.y = atan2(-(pts[2] - pts[0]), -(pts[3] - pts[1]))
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	_wp = 1
	_t = 0.0
	_stalled = 0.0
	_worst = 0.0
	_unsticks = int(car.unsticks)
	return true


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _frames < 3 or _leg >= LEGS.size():
		return false
	if car == null:
		_start()
		return false
	var pts: Array = LEGS[_leg][1]
	var p := Vector2(car.global_position.x, car.global_position.z)
	var last := pts.size() / 2 - 1
	while _wp < last and p.distance_to(Vector2(pts[_wp * 2], pts[_wp * 2 + 1])) < LOOK:
		_wp += 1
	if _wp == last and p.distance_to(Vector2(pts[_wp * 2], pts[_wp * 2 + 1])) < NEAR:
		_wp += 1
	_t += dt
	var v := Vector2(car.vel.x, car.vel.z).length()
	_stalled = _stalled + dt if v < STALL and _t > 1.5 else 0.0
	_worst = maxf(_worst, _stalled)
	var done := _wp >= pts.size() / 2
	if not done:
		var aim := Vector2(pts[_wp * 2], pts[_wp * 2 + 1]) - p
		car.target_dir = Vector3(aim.x, 0.0, aim.y).normalized()
		car.throttle = THROTTLE
	if verbose and _frames % 30 == 0:
		print("   %s t=%.1f at %.1f, %.1f  %.1f m/s  wp %d/%d%s" % [LEGS[_leg][0], _t, p.x, p.y, v, _wp, pts.size() / 2,
				_touching()])
	if not done and _t < _limit and _worst <= STALL_TIME:
		return false
	var why: Array[String] = []
	if not done:
		why.append("reached waypoint %d of %d in %.0f s" % [_wp, pts.size() / 2, _t])
	if _worst > STALL_TIME:
		why.append("stalled under %.0f m/s for %.1f s" % [STALL, _worst])
	if int(car.unsticks) > _unsticks:
		why.append("unstuck %d×" % (int(car.unsticks) - _unsticks))
	print("%s %s: %.0f s, at %.0f, %.0f%s" % ["FAIL" if not why.is_empty() else "ok  ", LEGS[_leg][0], _t, p.x, p.y,
			"" if why.is_empty() else " · " + ", ".join(why)])
	if not why.is_empty():
		_failures += 1
	if _next_leg():
		return false
	if _failures == 0:
		print("check_old_town_drive: OK")
	else:
		print("check_old_town_drive: %d of %d legs fail" % [_failures, LEGS.size()])
	quit(1 if _failures > 0 else 0)
	return false


## What the car is touching (verbose): each collider's node name and the contact point.
func _touching() -> String:
	var out := ""
	for i in car.get_slide_collision_count():
		var c := car.get_slide_collision(i)
		var o := c.get_collider() as Node
		var q := c.get_position()
		out += "  touching %s at %.1f, %.1f, %.1f" % [o.name if o != null else "?", q.x, q.y, q.z]
	return out
