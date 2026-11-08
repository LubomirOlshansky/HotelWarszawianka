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
// walls, whose tops stand at the ground, so the walls close the cut's sides. Only uniform tests
// while the cut is shut (everywhere but in a tunnel); a six-chord loop for the points near it.
const int TUNNEL_SEGS = 6;
const float TUNNEL_CUT_OVER = 2.5;
// The car's x, z, the cut's radius (0: off) and the car's floor height.
uniform vec4 tunnel_cut = vec4(0.0, 0.0, 0.0, -10000.0);
// The camera's forward (world; orthographic, so every view ray runs this way).
uniform vec3 tunnel_view = vec3(0.0, -1.0, 0.0);
uniform vec4 tunnel_seg[6];
uniform vec2 tunnel_reach[6];

// How far the map point `p` lies outside the corridor, across it (m; < 0 inside).
float tunnel_across(vec2 p) {
	float out_by = 1e4;
	for (int k = 0; k < TUNNEL_SEGS; k++) {
		vec2 a = tunnel_seg[k].xy;
		vec2 ab = tunnel_seg[k].zw - a;
		vec2 ap = p - a;
		float l2 = max(dot(ab, ab), 1e-4);
		float u = dot(ap, ab) / l2;
		float lat = (ab.x * ap.y - ab.y * ap.x) * inversesqrt(l2);  // right of the line is +
		if (u > -0.05 && u < 1.05) {
			out_by = min(out_by, max(-lat - tunnel_reach[k].x, lat - tunnel_reach[k].y));
		}
	}
	return out_by;
}

// Where the view ray through `wp` comes down to the car's floor height (map x, z).
vec2 tunnel_floor_hit(vec3 wp) {
	return wp.xz + tunnel_view.xz * ((wp.y - tunnel_cut.w) / max(-tunnel_view.y, 0.1));
}

// True where the point `wp`, more than `over` m over the car's floor, stands in the way of the
// tunnel's floor round the car: over the corridor, or (on the camera's side) on a view ray that
// comes down to the floor inside it within the cut's radius of the car. That second part opens
// the near side too when the camera looks across a narrow, deep tube, which showed only its far
// wall; the near wall goes with it (building.gdshader), so the ray reaches the road.
bool tunnel_in(vec3 wp, float over) {
	if (tunnel_cut.z <= 0.0 || wp.y < tunnel_cut.w + over) {
		return false;
	}
	vec2 hit = tunnel_floor_hit(wp);
	if (distance(hit, tunnel_cut.xy) > tunnel_cut.z) {
		return false;
	}
	return tunnel_across(hit) < 0.0 || tunnel_across(wp.xz) < 0.0;
}

// True where the ground at `wp` lies over the tunnel near the car (its road and floor stay).
bool tunnel_open(vec3 wp) {
	return tunnel_in(wp, TUNNEL_CUT_OVER);
}

// True on the tunnel's own side walls round the cut (TUNNEL_WALL_BAND m past its edge, under the
// ground, a little past the cut's ends too, where the slot looks along the tunnel):
// building.gdshader keeps them out of the occlusion ghost, which took the walls between the car
// and the camera for a building in the way and dithered them away (PT-43's blue chequered blob:
// the sky seen through the wall).
const float TUNNEL_WALL_BAND = 1.0;
const float TUNNEL_WALL_TOP = 12.0;
const float TUNNEL_WALL_GROW = 20.0;
bool tunnel_wall(vec3 wp) {
	return tunnel_cut.z > 0.0 && wp.y < tunnel_cut.w + TUNNEL_WALL_TOP
			&& distance(wp.xz, tunnel_cut.xy) < tunnel_cut.z + TUNNEL_WALL_GROW
			&& tunnel_across(wp.xz) < TUNNEL_WALL_BAND;
}

// For a multimesh instance standing on the ground (a tree's crown or trunk, a lamp): its vertex
// collapsed to a point when its foot `origin` (MODEL_MATRIX[3]) stands over the cut, so it draws
// nothing (one test a vertex, nothing while the cut is shut).
vec3 tunnel_hide(vec3 vertex, vec3 origin) {
	return tunnel_open(origin) ? vec3(0.0) : vertex;
}
