shader_type spatial;
// The Jarmark Warszawski rides (jarmark_rides.gd): every turning part in one mesh. UV is the
// ride's axis (world x, z), UV2.x the kit's material code (M_LAMP 10 glows at night, 10.5 blue),
// UV2.y the ride: 0 the tower carousel's carrier (round, and up and down its mast on a 150 s
// cycle: 20 s loading at the bottom, 30 s up, 70 s at the top, 30 s down), 1 the Venetian
// carousel, 2.x a horse on it (bobbing, the fraction its phase), 3 the teacups, 4 the
// Christmas-tree carousel. 150 s divides the engine's 3600 s TIME rollover, so the cycle never jumps.

render_mode cull_disabled;

#include "res://shaders/common.gdshaderinc"

global uniform float lights_on;

const float CYCLE = 150.0;
const float LOAD = 20.0;
const float RISE = 30.0;
const float DROP = 18.9;   // jarmark.gd TOWER_DROP

varying float mode;

void vertex() {
	float ride = floor(UV2.y + 0.001);
	float phase = fract(UV2.y) * 6.2832;
	// The cycle starts 60 s in, so a fresh game (a trailer's first shot) finds the chairs up and turning.
	float tt = TIME + 60.0;
	float tau = mod(tt, CYCLE);
	// The tower stands still while it loads; its angle counts only the turning time.
	float run = floor(tt / CYCLE) * (CYCLE - LOAD) + max(tau - LOAD, 0.0);
	float up = smoothstep(LOAD, LOAD + RISE, tau) * (1.0 - smoothstep(CYCLE - RISE, CYCLE, tau));
	float tower = step(ride, 0.5);
	float speed = ride < 0.5 ? 1.05 : (ride < 2.5 ? 0.45 : (ride < 3.5 ? -0.6 : 0.5));
	float ang = mix(TIME * speed, run * speed, tower);
	float c = cos(ang);
	float s = sin(ang);
	vec2 r = VERTEX.xz - UV;
	VERTEX.xz = UV + vec2(c * r.x - s * r.y, s * r.x + c * r.y);
	NORMAL.xz = vec2(c * NORMAL.x - s * NORMAL.z, s * NORMAL.x + c * NORMAL.z);
	VERTEX.y -= tower * (1.0 - up) * DROP;
	VERTEX.y += step(1.5, ride) * step(ride, 2.5) * 0.22 * sin(TIME * 1.9 + phase);
	mode = UV2.x;
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	float lamp = step(9.99, mode) * step(mode, 10.99);
	vec3 glow = fract(mode) > 0.25 ? vec3(0.17, 0.34, 1.0) : col;
	EMISSION = glow * 2.4 * lamp * lights_on;
}
