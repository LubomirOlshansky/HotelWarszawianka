"""Racer AI step 5 (docs/design/race-ai.md 5.4): the race links, ways through the city with a real
shape that a racer can take and the lane graph lacks: alleys, courtyards, car parks, driveways.

The lane graph has no service roads. This walks the map's service ways (OpenStreetMap
highway=service: yards, car park aisles, alleys, driveways) from a mouth on one street to a mouth
on another and keeps a way that saves a racer at least SAVE_MIN metres over the best road route
between the two junctions. A link runs from junction A (a racer comes to it on any street) along
the street out of A to the first mouth (at most MOUTH_REACH m), through the yard, out of the second
mouth and along that street to junction B, where it joins B's roads like a shortcut
(race_cuts.gd). Its points lie on the right-hand lane of the streets and on the service way's
middle in between.

A link must be drivable: a corridor CLEAR_HALF m to each side of its yard part free of buildings,
walls, fences, hedges, steps, rails, platforms, trees, lamps, parked cars and the like, no step in
the terrain, nothing that goes onto a bridge or into a garage ramp. That is what the map knows. The
proof is the player's own car driving it in the built city (game/tools/check_lane_drive.gd
--links, then --proofs here: tools/race_links.sh): a link without a proof that matches its points
is never handed to a racer (race_cuts.gd), and one the car could not drive keeps why (`refused`).

Racer AI step 5b (5.5): the wrong-way hops (kind "wrong"). A hop is one block of a one-way street
driven against its way: from the junction at the street's end back to the junction at its start,
along the lane on the racer's right, HOP_MAX m at most. Only small one-way streets (HOP_KINDS): never one carriageway of a road with another the other way beside it, a ring, a
slip road, a bridge, a tunnel or a street with tram rails. It must save a racer what a link must.
Only a rival that dares takes one (ladder.gd `hops`: Seba and Mike), and only when the street is
empty (traffic.gd `_hop_clear`). The player's car proves it like any link.

Writes game/data/race_links.json: per link its two junctions' positions (so a re-bake that moves
node ids keeps it), its points, the narrowest width of its yard part, its kind (yard: mostly
through a yard; park: mostly along car park aisles), the metres it saves, and a hash of its points
(`id`) that the proof records. A proof (or refusal) recorded earlier for the same id is kept.

Usage:
    python3 -I tools/race_links.py [--map=game/map/centrum.json] [--terrain=game/map/terrain.json]
        [--out=game/data/race_links.json] [--svg=build/race_links.svg] [--proofs=FILE]
--proofs=FILE takes the proof drive's result (check_lane_drive.gd --links --write=FILE: the ids
that passed get their proof, those that failed lose it). tools/race_links.sh runs both.
Run it again after a centrum.json re-bake, then the proof (check_race_links.gd fails when links
no longer resolve or lack a proof).
"""
import hashlib
import heapq
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from race_cuts import Grid, inside, seg_dist, seg_seg, ring, arg, POINTS, DATA_RADIUS, BLOCK_AREAS, BLOCK_LINES  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOUTH_REACH = 45.0   # metres of street from a junction to a yard's mouth (and from the other mouth to the next)
MOUTH_SNAP = 1.0     # a service way's point this close to a street's centreline is a mouth
MIN_YARD = 15.0      # metres of yard at least (shorter: a driveway across a pavement)
MAX_LEN = 320.0      # metres of link at most
SAVE_MIN = 15.0      # metres saved over the best road route, at least, as a racer counts a link
CUT_COST = 1.15      # race_cuts.gd COST and GAIN
CUT_GAIN = 12.0
SAVE_RATIO = 1.2     # the road route at least this × the link
REACH = 1200.0       # road search radius (m)
CLEAR_HALF = 1.3     # half the corridor checked in the yard (the car is 1.8 m wide)
STEP_MAX = 1.0       # terrain off the straight slope between two points 4 m apart (m)
SLOPE_MAX = 0.12
LEVEL_MAX = 0.7      # the ground along a link off the straight between its ends' heights (m)
GARAGE_KEEP = 18.0   # no yard point this close to a garage ramp's door (R9)
EDGE_POINT = 4.0     # the points of a link are about this far apart
HOP_MAX = 150.0      # metres of one-way street driven the wrong way, at most (race-ai.md, question 3)
HOP_MIN = 45.0       # ... and at least (shorter: a slip or a gap in a median)
HOP_KINDS = {"residential": 2, "living_street": 2, "unclassified": 2, "tertiary": 1}  # the kind: its lanes at most
HOP_TWIN = 45.0      # a way of the same name running the other way this close: a dual carriageway
HOP_BEND = 0.8       # rad a hop's street may turn in all (more: a ring or a slip road)
HOP_TRIM = 6.0       # a hop's points begin and end this far inside the street's lanes
HOP_EXIT = 1.75      # rad a hop may turn into the road it joins (race_cuts.gd EXIT_TURN)
HOP_RAIL = 6.0       # no tram rail this close to the street's middle


def main():
	data = json.load(open(arg("map", os.path.join(ROOT, "game/map/centrum.json"))))
	terrain_path = arg("terrain", os.path.join(ROOT, "game/map/terrain.json"))
	terrain = json.load(open(terrain_path)) if os.path.exists(terrain_path) else None
	out_path = arg("out", os.path.join(ROOT, "game/data/race_links.json"))
	old_proof = {}
	old_refused = {}
	if os.path.exists(out_path):
		for l in json.load(open(out_path)).get("links", []):
			if l.get("proof"):
				old_proof[l["id"]] = l["proof"]
			if l.get("refused"):
				old_refused[l["id"]] = l["refused"]
	proofs = arg("proofs", "")
	if proofs:
		run = json.load(open(proofs))
		for lid in run.get("passed", []):
			old_proof[lid] = lid
			old_refused.pop(lid, None)
		for lid, why in run.get("failed", {}).items():
			old_proof.pop(lid, None)
			old_refused[lid] = why
		print("race_links: proofs from %s: %d passed, %d failed" % (proofs, len(run.get("passed", [])), len(run.get("failed", {}))))

	def height(x, z):
		if terrain is None:
			return 0.0
		fx = (x - terrain["x0"]) / terrain["step"]
		fz = (z - terrain["z0"]) / terrain["step"]
		i = max(0, min(terrain["nx"] - 2, int(fx)))
		j = max(0, min(terrain["nz"] - 2, int(fz)))
		u, v = max(0.0, min(1.0, fx - i)), max(0.0, min(1.0, fz - j))
		h = terrain["h"]
		nx = terrain["nx"]
		a, b = h[j * nx + i], h[j * nx + i + 1]
		c, d = h[(j + 1) * nx + i], h[(j + 1) * nx + i + 1]
		return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v

	g = data["graph"]
	flat = g["nodes"]
	nodes = [(flat[k], flat[k + 1]) for k in range(0, len(flat) - 1, 2)]
	scc = g["scc"]
	edges = g["edges"]
	out = [[] for _ in nodes]
	epts = []      # per edge, its points
	ecum = []      # per edge, metres along it at each point
	usable = []    # per edge: on the ground, open, in the core
	for i, e in enumerate(edges):
		p = ring(e["p"])
		c = [0.0]
		for k in range(1, len(p)):
			c.append(c[-1] + math.hypot(p[k][0] - p[k - 1][0], p[k][1] - p[k - 1][1]))
		epts.append(p)
		ecum.append(c)
		ok = not e.get("br", 0) and e.get("tn", -1) < 0 and not e.get("cf", 0) and scc[e["a"]] and scc[e["b"]]
		usable.append(ok)
		if e.get("cf", 0):
			continue  # (the tunnels are driven: lane_graph.gd TUNNELS_DRIVEN)
		out[e["a"]].append((e["b"], c[-1]))

	def lane_point(i, s):
		"""The point s m along edge i, on its right-hand (first) lane."""
		p, c = epts[i], ecum[i]
		k = 0
		while k + 2 < len(c) and c[k + 1] < s:
			k += 1
		seg = max(c[k + 1] - c[k], 1e-6)
		t = max(0.0, min(1.0, (s - c[k]) / seg))
		x = p[k][0] + (p[k + 1][0] - p[k][0]) * t
		z = p[k][1] + (p[k + 1][1] - p[k][1]) * t
		dx, dz = (p[k + 1][0] - p[k][0]) / seg, (p[k + 1][1] - p[k][1]) / seg
		o = float(edges[i]["o"])
		# Right of the way: Godot's x right, z down the map (south), so right of (dx, dz) is (-dz, dx).
		return (x - dz * o, z + dx * o)

	# Where each street's centreline runs: for the mouths.
	egrid = Grid()
	for i, p in enumerate(epts):
		if not usable[i]:
			continue
		for k in range(len(p) - 1):
			a, b = p[k], p[k + 1]
			egrid.add_box(min(a[0], b[0]) - 1, min(a[1], b[1]) - 1, max(a[0], b[0]) + 1, max(a[1], b[1]) + 1, (i, k))

	def on_edges(q):
		"""[(edge, s)] for every usable edge whose centreline passes within MOUTH_SNAP of q."""
		found = {}
		for (i, k) in egrid.near(q[0] - 1, q[1] - 1, q[0] + 1, q[1] + 1):
			a, b = epts[i][k], epts[i][k + 1]
			dd = seg_dist(q, a, b)
			if dd <= MOUTH_SNAP:
				L = max(math.hypot(b[0] - a[0], b[1] - a[1]), 1e-6)
				t = max(0.0, min(1.0, ((q[0] - a[0]) * (b[0] - a[0]) + (q[1] - a[1]) * (b[1] - a[1])) / (L * L)))
				s = ecum[i][k] + L * t
				if i not in found or dd < found[i][1]:
					found[i] = (s, dd)
		return [(i, v[0]) for i, v in found.items()]

	# What blocks a car (as race_cuts.py, but for a yard: roads are fine, it is one).
	polys = Grid()
	for b in data["buildings"] + data["landmarks"]:
		r = ring(b["p"])
		if len(r) >= 3:
			xs, zs = [q[0] for q in r], [q[1] for q in r]
			polys.add_box(min(xs), min(zs), max(xs), max(zs), r)
	for a in data["areas"]:
		if a["k"] in BLOCK_AREAS:
			r = ring(a["p"])
			xs, zs = [q[0] for q in r], [q[1] for q in r]
			polys.add_box(min(xs), min(zs), max(xs), max(zs), r)
	lines = Grid()
	segs = [ring(l["p"]) for l in data["lines"] if l["k"] in BLOCK_LINES]
	for key in ("walls", "steps", "rails", "platforms", "citywalls"):
		for l in data.get(key, []):
			if isinstance(l, dict) and "p" in l:
				segs.append(ring(l["p"]))
	for r in segs:
		for k in range(len(r) - 1):
			a, b = r[k], r[k + 1]
			lines.add_box(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]), (a, b))
	points = Grid()
	for key, (stride, rad) in POINTS.items():
		arr = data.get(key, [])
		for k in range(0, len(arr) - 1, stride):
			x, z = arr[k], arr[k + 1]
			points.add_box(x - rad, z - rad, x + rad, z + rad, (x, z, rad))
	for name in ("park_details", "street_details", "monuments"):
		path = os.path.join(ROOT, "game/data/%s.json" % name)
		if not os.path.exists(path):
			continue
		for it in json.load(open(path)).get("items", []):
			rad = DATA_RADIUS.get(it[0], 1.5)
			points.add_box(it[1] - rad, it[2] - rad, it[1] + rad, it[2] + rad, (it[1], it[2], rad))
	# Parked cars, for the kind (a link mostly beside them runs along car park aisles).
	cars = Grid()
	arr = data.get("parked", [])
	for k in range(0, len(arr) - 1, 4):
		cars.add_box(arr[k], arr[k + 1], arr[k], arr[k + 1], (arr[k], arr[k + 1]))
	garages = data.get("garages", [])
	gdoors = [(garages[k][0], garages[k][1]) for k in range(len(garages))] if garages and isinstance(garages[0], list) else []

	def blocked(a, b):
		"""Why a car can't drive the yard's piece a-b, or ''."""
		L = math.hypot(b[0] - a[0], b[1] - a[1])
		if L < 0.05:
			return ""
		ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
		nx, nz = -uz, ux
		pad = CLEAR_HALF + 3
		x0, z0 = min(a[0], b[0]) - pad, min(a[1], b[1]) - pad
		x1, z1 = max(a[0], b[0]) + pad, max(a[1], b[1]) + pad
		near_polys = list(polys.near(x0, z0, x1, z1))
		ha, hb = height(*a), height(*b)
		if L > 4.0 and abs(hb - ha) / L > SLOPE_MAX:
			return "slope"
		s = 0.0
		while s <= L:
			cx, cz = a[0] + ux * s, a[1] + uz * s
			if abs(height(cx, cz) - (ha + (hb - ha) * s / L)) > STEP_MAX:
				return "step"
			for o in (-CLEAR_HALF, 0.0, CLEAR_HALF):
				q = (cx + nx * o, cz + nz * o)
				for poly in near_polys:
					if inside(q, poly):
						return "building"
			s += 1.0
		for (c, d) in lines.near(x0, z0, x1, z1):
			if seg_seg(a, b, c, d) < CLEAR_HALF - 0.2:
				return "line"
		for (x, z, rad) in points.near(x0, z0, x1, z1):
			if seg_dist((x, z), a, b) < rad + CLEAR_HALF - 0.3:
				return "object"
		for (x, z) in gdoors:
			if seg_dist((x, z), a, b) < GARAGE_KEEP:
				return "garage"
		return ""

	# The service ways as a graph of their points.
	key = lambda q: (round(q[0], 1), round(q[1], 1))
	vpos = {}
	adj = {}
	vwidth = {}
	aisle = {}
	for r in data["roads"]:
		if r["k"] != "service" or r.get("bridge"):
			continue
		p = ring(r["p"])
		w = float(r.get("w", 3.5))
		one = bool(r.get("oneway"))
		for k in range(len(p) - 1):
			a, b = key(p[k]), key(p[k + 1])
			if a == b:
				continue
			vpos[a] = p[k]
			vpos[b] = p[k + 1]
			L = math.hypot(p[k + 1][0] - p[k][0], p[k + 1][1] - p[k][1])
			adj.setdefault(a, []).append((b, L, w))
			if not one:
				adj.setdefault(b, []).append((a, L, w))
	print("race_links: %d service points" % len(vpos))

	# Mouths: service points on a street's centreline. Per point, the edges (and s) it lies on.
	mouths = {}
	for v, q in vpos.items():
		hits = on_edges(q)
		if hits:
			mouths[v] = hits

	def roads_from(a):
		dist = {a: 0.0}
		heap = [(0.0, a)]
		while heap:
			d, n = heapq.heappop(heap)
			if d > dist.get(n, math.inf) or d > REACH:
				continue
			for m, w in out[n]:
				nd = d + w
				if nd < dist.get(m, math.inf):
					dist[m] = nd
					heapq.heappush(heap, (nd, m))
		return dist

	road_cache = {}
	best = {}   # (A, B) -> link
	why = {}
	for m1, hits1 in mouths.items():
		# Ways into the yard: the street h out of junction A, the mouth within MOUTH_REACH of A.
		entries = [(h, s) for (h, s) in hits1 if s <= MOUTH_REACH and usable[h]]
		if not entries:
			continue
		# Through the yard: the service graph from m1, never back onto a street's centreline but at
		# the far mouth.
		dist = {m1: 0.0}
		prev = {}
		narrow = {m1: 99.0}
		heap = [(0.0, m1)]
		while heap:
			d, v = heapq.heappop(heap)
			if d > dist.get(v, math.inf) or d > MAX_LEN:
				continue
			if v != m1 and v in mouths:
				continue  # a mouth ends the yard part
			for (u, L, w) in adj.get(v, ()):
				nd = d + L
				if nd < dist.get(u, math.inf):
					dist[u] = nd
					prev[u] = v
					narrow[u] = min(narrow[v], w)
					heapq.heappush(heap, (nd, u))
		for m2, hits2 in mouths.items():
			if m2 == m1 or m2 not in dist or dist[m2] < MIN_YARD:
				continue
			# Out of the yard: the street k into junction B, the mouth within MOUTH_REACH of B.
			exits = [(k, s) for (k, s) in hits2 if usable[k] and ecum[k][-1] - s <= MOUTH_REACH]
			if not exits:
				continue
			yard = [m2]
			while yard[-1] != m1:
				yard.append(prev[yard[-1]])
			yard.reverse()
			for (h, s1) in entries:
				A = edges[h]["a"]
				for (k, s2) in exits:
					B = edges[k]["b"]
					if A == B or k == h:
						continue
					# The same street on both sides (in at one mouth, out at the next, back on it):
					# the road is the shorter way.
					if edges[k]["a"] == A and edges[k]["b"] == edges[h]["b"]:
						continue
					total = s1 + dist[m2] + (ecum[k][-1] - s2)
					if total > MAX_LEN:
						continue
					if A not in road_cache:
						road_cache[A] = roads_from(A)
					road = road_cache[A].get(B, REACH * 1.5)
					# Worth it as a racer counts it (race_cuts.gd: a metre of a link is COST metres
					# of road, and it must save GAIN m on top).
					if road - total * CUT_COST - CUT_GAIN < SAVE_MIN or road < total * SAVE_RATIO:
						continue
					pair = (A, B)
					if pair in best and best[pair]["len"] <= total:
						continue
					best[pair] = {"A": A, "B": B, "h": h, "s1": s1, "k": k, "s2": s2, "yard": yard,
						"len": total, "save": road - total, "w": narrow[m2]}

	links = []
	seen_yards = {}
	for pair, c in sorted(best.items(), key=lambda kv: -kv[1]["save"]):
		ypts = [vpos[v] for v in c["yard"]]
		w = ""
		for k in range(len(ypts) - 1):
			w = blocked(ypts[k], ypts[k + 1])
			if w:
				break
		if not w:
			for k in range(len(ypts)):
				if any(math.hypot(ypts[k][0] - x, ypts[k][1] - z) < GARAGE_KEEP for (x, z) in gdoors):
					w = "garage"
					break
		why[w or "ok"] = why.get(w or "ok", 0) + 1
		if w:
			continue
		# The points: the street out of A from its lanes' start to the mouth, the yard, the street
		# into B from the mouth to its lanes' end. About EDGE_POINT m apart.
		h, k = c["h"], c["k"]
		pts = []
		s = float(edges[h]["s0"])
		while s < c["s1"]:
			pts.append(lane_point(h, s))
			s += EDGE_POINT
		for q in ypts:
			if pts and math.hypot(q[0] - pts[-1][0], q[1] - pts[-1][1]) < 1.0:
				continue
			pts.append(q)
		s = c["s2"] + EDGE_POINT
		end = float(edges[k]["s1"])
		while s < end:
			pts.append(lane_point(k, s))
			s += EDGE_POINT
		if c["s2"] < end - 1.0:
			pts.append(lane_point(k, end))
		# Densify long pieces so the curve through them stays on the way.
		dense = [pts[0]]
		for q in pts[1:]:
			p0 = dense[-1]
			L = math.hypot(q[0] - p0[0], q[1] - p0[1])
			n = int(L // (EDGE_POINT * 2))
			for j in range(1, n + 1):
				t = j / (n + 1)
				dense.append((p0[0] + (q[0] - p0[0]) * t, p0[1] + (q[1] - p0[1]) * t))
			dense.append(q)
		# A rival drives a link at the height between its two ends (traffic.gd `_place`): the ground
		# along it may not leave that line by more than LEVEL_MAX.
		cum = [0.0]
		for j in range(1, len(dense)):
			cum.append(cum[-1] + math.hypot(dense[j][0] - dense[j - 1][0], dense[j][1] - dense[j - 1][1]))
		h0, h1 = height(*dense[0]), height(*dense[-1])
		if any(abs(height(*q) - (h0 + (h1 - h0) * cum[j] / max(cum[-1], 0.01))) > LEVEL_MAX for j, q in enumerate(dense)):
			why["level"] = why.get("level", 0) + 1
			why["ok"] -= 1
			continue
		flatp = []
		for q in dense:
			flatp += [round(q[0], 1), round(q[1], 1)]
		# One link per yard path: two junction pairs through the same yard keep the bigger saving.
		ykey = (c["yard"][0], c["yard"][-1])
		if ykey in seen_yards:
			continue
		seen_yards[ykey] = True
		an, bn = nodes[c["A"]], nodes[c["B"]]
		lid = hashlib.sha1(json.dumps([round(an[0], 1), round(an[1], 1), round(bn[0], 1), round(bn[1], 1), flatp]).encode()).hexdigest()[:12]
		parked = sum(1 for v in c["yard"] if any(True for _ in cars.near(vpos[v][0] - 6, vpos[v][1] - 6, vpos[v][0] + 6, vpos[v][1] + 6)))
		links.append({
			"id": lid,
			"a": [round(an[0], 1), round(an[1], 1)], "b": [round(bn[0], 1), round(bn[1], 1)],
			"kind": "park" if parked * 2 > len(c["yard"]) else "yard",
			"w": round(c["w"], 1), "len": round(c["len"], 1), "save": round(c["save"]),
			"p": flatp, "proof": old_proof.get(lid, ""), "refused": old_refused.get(lid, ""),
		})
	# Racer AI step 5b: the wrong-way hops, one block of a one-way street against its way.
	ends = set((e["a"], e["b"]) for e in edges)
	taken = set((round(l["a"][0], 1), round(l["a"][1], 1), round(l["b"][0], 1), round(l["b"][1], 1)) for l in links)
	rails = Grid()
	for t in data.get("trams", []):
		r = ring(t["p"])
		for k in range(len(r) - 1):
			a, b = r[k], r[k + 1]
			rails.add_box(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]), (a, b))

	def heading(i):
		p = epts[i]
		L = max(math.hypot(p[-1][0] - p[0][0], p[-1][1] - p[0][1]), 1e-6)
		return ((p[-1][0] - p[0][0]) / L, (p[-1][1] - p[0][1]) / L)

	def middle(i):
		p, c = epts[i], ecum[i]
		half = c[-1] * 0.5
		k = 0
		while k + 2 < len(c) and c[k + 1] < half:
			k += 1
		t = (half - c[k]) / max(c[k + 1] - c[k], 1e-6)
		return (p[k][0] + (p[k + 1][0] - p[k][0]) * t, p[k][1] + (p[k + 1][1] - p[k][1]) * t)

	by_name = {}
	for i, e in enumerate(edges):
		if e.get("name"):
			by_name.setdefault(e["name"], []).append(i)
	ins = [[] for _ in nodes]
	outs = [[] for _ in nodes]
	for j, f in enumerate(edges):
		ins[f["b"]].append((j, f))
		outs[f["a"]].append((j, f))
	hop_why = {}
	hops = 0
	for i, e in enumerate(edges):
		if (e["b"], e["a"]) in ends or not usable[i] or int(e["n"]) > HOP_KINDS.get(e["k"], 0):
			continue
		total = ecum[i][-1]
		if total < HOP_MIN or total > HOP_MAX:
			continue
		w = ""
		p = epts[i]
		bend = 0.0
		for k in range(1, len(p) - 1):
			a0 = math.atan2(p[k][1] - p[k - 1][1], p[k][0] - p[k - 1][0])
			a1 = math.atan2(p[k + 1][1] - p[k][1], p[k + 1][0] - p[k][0])
			bend += abs((a1 - a0 + math.pi) % (2 * math.pi) - math.pi)
		mid = middle(i)
		hx, hz = heading(i)
		if bend > HOP_BEND:
			w = "bend"
		if not w:
			for j in by_name.get(e.get("name", ""), ()):
				if j == i:
					continue
				ox, oz = heading(j)
				if hx * ox + hz * oz < -0.7 and any(seg_dist(mid, epts[j][k], epts[j][k + 1]) < HOP_TWIN for k in range(len(epts[j]) - 1)):
					w = "twin"
					break
		if not w:
			for (a, b) in rails.near(mid[0] - HOP_RAIL - 60, mid[1] - HOP_RAIL - 60, mid[0] + HOP_RAIL + 60, mid[1] + HOP_RAIL + 60):
				if any(seg_dist(q, a, b) < HOP_RAIL for q in p):
					w = "rails"
					break
		A, B = e["b"], e["a"]  # the hop runs from the street's end to its start
		if not w and not any(f["b"] == A and j != i and f.get("tn", -1) < 0 and not f.get("cf", 0) for j, f in ins[A]):
			w = "no way in"  # (only the street itself comes to its end: the next block is one-way too)
		if not w:
			# A road out of its start that the hop can join (race_cuts.gd EXIT_TURN).
			back = (p[0][0] - p[1][0], p[0][1] - p[1][1])
			ok = False
			for j, f in outs[B]:
				q = epts[j]
				if j == i or f.get("cf", 0) or len(q) < 2:
					continue
				turn = abs((math.atan2(q[1][1] - q[0][1], q[1][0] - q[0][0]) - math.atan2(back[1], back[0]) + math.pi) % (2 * math.pi) - math.pi)
				if turn <= HOP_EXIT:
					ok = True
			if not ok:
				w = "no way on"
		if not w:
			if A not in road_cache:
				road_cache[A] = roads_from(A)
			road = road_cache[A].get(B, REACH * 1.5)
			if road - total * CUT_COST - CUT_GAIN < SAVE_MIN or road < total * SAVE_RATIO:
				w = "no gain"
		pts = []
		if not w:
			# Its points: from the street's lanes' end back to their start, along its first lane
			# (the one by its left edge: on the right of a car that drives it the wrong way).
			# (HOP_TRIM m short at each end: the turn in and the turn out get that much more room.)
			s = float(e["s1"]) - HOP_TRIM
			s0 = float(e["s0"]) + HOP_TRIM
			while s > s0:
				pts.append(lane_point(i, s))
				s -= EDGE_POINT
			if s0 < float(e["s1"]) - HOP_TRIM:
				pts.append(lane_point(i, s0))
			if len(pts) < 2:
				w = "short"
		if not w:
			cum = [0.0]
			for j in range(1, len(pts)):
				cum.append(cum[-1] + math.hypot(pts[j][0] - pts[j - 1][0], pts[j][1] - pts[j - 1][1]))
			h0, h1 = height(*pts[0]), height(*pts[-1])
			if any(abs(height(*q) - (h0 + (h1 - h0) * cum[j] / max(cum[-1], 0.01))) > LEVEL_MAX for j, q in enumerate(pts)):
				w = "level"
		an, bn = nodes[A], nodes[B]
		if not w and (round(an[0], 1), round(an[1], 1), round(bn[0], 1), round(bn[1], 1)) in taken:
			w = "a link there"
		hop_why[w or "ok"] = hop_why.get(w or "ok", 0) + 1
		if w:
			continue
		flatp = []
		for q in pts:
			flatp += [round(q[0], 1), round(q[1], 1)]
		lid = hashlib.sha1(json.dumps(["wrong", round(an[0], 1), round(an[1], 1), round(bn[0], 1), round(bn[1], 1), flatp]).encode()).hexdigest()[:12]
		links.append({
			"id": lid,
			"a": [round(an[0], 1), round(an[1], 1)], "b": [round(bn[0], 1), round(bn[1], 1)],
			"kind": "wrong",
			"w": round(float(e["lw"]) * int(e["n"]), 1), "len": round(total, 1), "save": round(road - total),
			"p": flatp, "proof": old_proof.get(lid, ""), "refused": old_refused.get(lid, ""),
			"name": e.get("name", ""),
		})
		hops += 1
	print("race_links: %d wrong-way hops; rejected: %s" % (hops, ", ".join("%s %d" % (k, v) for k, v in sorted(hop_why.items()) if k != "ok")))
	links.sort(key=lambda l: (l["a"], l["b"]))
	with open(out_path, "w") as f:
		f.write('{"_note": "Racer AI steps 5 and 5b: race links through yards, car parks and alleys, and wrong-way hops along one-way streets (kind wrong), junction a to junction b along points p (x, z). Made by tools/race_links.py from centrum.json; proof is set when the player\'s car drove it (check_lane_drive.gd --links), refused says why it could not. Do not edit by hand.",\n"links": [\n')
		f.write(",\n".join(json.dumps(l, ensure_ascii=False) for l in links))
		f.write("\n]}\n")
	proven = sum(1 for l in links if l["proof"])
	refused = sum(1 for l in links if l["refused"])
	print("race_links: %d mouths, %d junction pairs, %d links (%d proven, %d refused by the drive, %d not driven yet) -> %s; rejected: %s" % (
		len(mouths), len(best), len(links), proven, refused, len(links) - proven - refused, os.path.relpath(out_path, ROOT),
		", ".join("%s %d" % (k, v) for k, v in sorted(why.items()) if k != "ok")))
	svg = arg("svg", "")
	if svg:
		x0, z0, x1, z1 = data["bounds"]
		with open(svg, "w") as f:
			f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%f %f %f %f" style="background:#111">' % (x0, z0, x1 - x0, z1 - z0))
			for e in edges:
				p = e["p"]
				f.write('<polyline fill="none" stroke="#555" stroke-width="3" points="%s"/>' % " ".join("%.0f,%.0f" % (p[k], p[k + 1]) for k in range(0, len(p) - 1, 2)))
			for l in links:
				p = l["p"]
				f.write('<polyline fill="none" stroke="%s" stroke-width="4" points="%s"/>' % ("#ff9a3c" if l["kind"] == "wrong" else "#4fd8ff", " ".join("%.1f,%.1f" % (p[k], p[k + 1]) for k in range(0, len(p) - 1, 2))))
			f.write("</svg>")


if __name__ == "__main__":
	main()
