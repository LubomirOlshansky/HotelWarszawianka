shader_type spatial;
// The Warsaw Spire plaza's fountain jets (spire_motion.gd): every jet in one mesh. Each bobs a
// little about its foot (UV2.x, world y) with its own phase (UV2.y); white water, a cool glow at
// night like the plaza's underwater lamps (F's night photo).

render_mode cull_disabled, shadows_disabled;

global uniform float lights_on;

varying float up;

void vertex() {
	float foot = UV2.x;
	float s = 0.86 + 0.14 * sin(TIME * 2.1 + UV2.y) + 0.04 * sin(TIME * 7.3 + UV2.y * 3.0);
	VERTEX.y = foot + (VERTEX.y - foot) * s;
	up = UV.y;
}

void fragment() {
	float shimmer = 0.9 + 0.1 * sin(up * 9.0 - TIME * 12.0);
	ALBEDO = vec3(0.86, 0.93, 0.98) * shimmer;
	ROUGHNESS = 0.3;
	SPECULAR = 0.6;
	EMISSION = vec3(0.45, 0.7, 1.0) * 0.9 * lights_on;
}
