// The tunnel cutaway (F, 2026-11-08). While the car drives in a tunnel, the ground over the
// tunnel round it opens, so the tunnel's road, its walls and the car show as in a cut model
// instead of a silhouette through the grass. Shared by ground.gdshader (the ground and its paths),
// foliage.gdshader (trees and trunks), fixture.gdshader (lamps, benches, bins), glow.gdshader (the
// lamps' halos) and building.gdshader (a building over the tunnel, the Copernicus Science
// Centre's, is cut through likewise; the tunnel's own walls stay out of the occlusion ghost).
//
// main.gd (`_update_tunnel_cut`; the materials: map_builder.gd `cut_materials`) sends the car's
// ground point, the cut's radius, the car's floor height and the camera's forward, and the tunnel's centre line near the car as
// TUNNEL_SEGS chords (a.xz, b.xz) with each one's left and right reach: to just inside the side
// walls, whose tops stand at the ground, so the walls close the cut's sides.
//
// Branch-free on purpose (the Adreno 6xx budget, tools/check_shader_budget.gd: every if, ternary,
// && / || and call costs in fragment(), straight maths, step() and mix() don't): one six-chord loop
// with no branch in it, and the callers test its result once with all().
const int TUNNEL_SEGS = 6;
const float TUNNEL_CUT_OVER = 2.5;
// The car's x, z, the cut's radius (0: off) and the car's floor height.
uniform vec4 tunnel_cut = vec4(0.0, 0.0, 0.0, -10000.0);
// The camera's forward (world; orthographic, so every view ray runs this way).
uniform vec3 tunnel_view = vec3(0.0, -1.0, 0.0);
uniform vec4 tunnel_seg[6];
uniform vec2 tunnel_reach[6];
// The tunnel's own side walls: TUNNEL_WALL_BAND m past the cut's edge, under TUNNEL_WALL_TOP m over
// the floor, out to TUNNEL_WALL_GROW m past its radius (where the slot looks along the tunnel).
const float TUNNEL_WALL_BAND = 1.0;
const float TUNNEL_WALL_TOP = 12.0;
const float TUNNEL_WALL_GROW = 20.0;

// For the point `wp`: x < 0 where it stands in the way of the tunnel's floor round the car (over
// the corridor, or, on the camera's side, on a view ray that comes down to the floor inside it within
// the cut's radius: that opens the near side too when the camera looks across a narrow, deep tube,
// which showed only its far wall); y < TUNNEL_WALL_BAND on the tunnel's own walls round the cut.
// Both are 1e4 while the cut is shut. How far outside the corridor, across it, in metres.
vec2 tunnel_test(vec3 wp) {
	// Where the view ray through wp comes down to the car's floor height.
	vec2 hit = wp.xz + tunnel_view.xz * ((wp.y - tunnel_cut.w) / max(-tunnel_view.y, 0.1));
	float at = 1e4;
	float down = 1e4;
	for (int k = 0; k < TUNNEL_SEGS; k++) {
		vec2 a = tunnel_seg[k].xy;
		vec2 ab = tunnel_seg[k].zw - a;
		float inv = inversesqrt(max(dot(ab, ab), 1e-4));
		vec2 ap = wp.xz - a;
		vec2 hp = hit - a;
		vec2 u = vec2(dot(ap, ab), dot(hp, ab)) * inv * inv;
		vec2 lat = vec2(ab.x * ap.y - ab.y * ap.x, ab.x * hp.y - ab.y * hp.x) * inv;  // right is +
		vec2 by = max(-lat - tunnel_reach[k].x, lat - tunnel_reach[k].y);
		vec2 on = step(vec2(-0.05), u) * step(u, vec2(1.05));
		at = min(at, mix(1e4, by.x, on.x));
		down = min(down, mix(1e4, by.y, on.y));
	}
	float open = step(1e-3, tunnel_cut.z);
	float cut = mix(1e4, min(at, down), open * step(distance(hit, tunnel_cut.xy), tunnel_cut.z));
	float wall = mix(1e4, at, open * step(distance(wp.xz, tunnel_cut.xy), tunnel_cut.z + TUNNEL_WALL_GROW)
			* step(wp.y, tunnel_cut.w + TUNNEL_WALL_TOP));
	return vec2(cut, wall);
}

// For a multimesh instance standing on the ground (a tree's crown or trunk, a lamp, a bench): its
// vertex collapsed to a point when its foot `origin` (MODEL_MATRIX[3]) stands over the cut, so it
// draws nothing (vertex stage only).
vec3 tunnel_hide(vec3 vertex, vec3 origin) {
	float gone = step(tunnel_test(origin).x, -1e-4) * step(tunnel_cut.w + TUNNEL_CUT_OVER, origin.y);
	return vertex * (1.0 - gone);
}
