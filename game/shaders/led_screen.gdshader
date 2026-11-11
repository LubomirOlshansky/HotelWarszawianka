shader_type spatial;
// The big L-shaped corner LED screen on Skylight at Złote Tarasy (tarasy_screen.gd): the "3D"
// anamorphic kind. The mesh is two flat faces round the tower's corner (the wide one facing the
// station, then the return facing Emilii Plater); UV is in metres (x along the screen, continuous
// round the corner at `corner`, y up from the bottom of the box, with a margin below the box for
// what pops out). The picture is a little box seen through its front: a ray from the eye is
// followed into it, so the side walls show and each layer shifts with the viewer (real parallax:
// the cat's head leans out past the glass, its paws hang over the bottom edge). Three scenes of an
// original loop, wiped one into the next along the screen (F, 2026-11-11): the tabby cat leaning
// out, the game's own promo (AROUND WARSAW over a sunset skyline with the Palace) and the NOSE.
// agency's blue blocky mark popping out of a light box. Unshaded and bright; at night it glows
// past the bloom threshold. Branchless where it can be: it counts against the Adreno budget.

render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled, fog_disabled;

global uniform float lights_on;
global uniform float daylight;

uniform vec2 size = vec2(25.0, 13.5);     // the box in metres
uniform float margin = 2.6;               // the mesh below the box
uniform float corner = 16.5;              // metres along the screen to the corner (the wide face's end)
uniform float bezel = 0.6;                // the frame round the box
uniform float depth = 3.2;                // the box's depth behind the glass
uniform sampler2D words : filter_nearest, repeat_disable;
uniform vec2 words_px = vec2(39.0, 35.0);  // the words texture in texels
uniform float line_px = 11.0;              // texels from one line of the words to the next

varying vec3 wpos;
varying vec3 wnorm;
varying vec2 mpos;

const float LOOP = 24.0;           // the whole loop
const vec3 SCENES = vec3(9.0, 8.0, 7.0);   // seconds of cat, promo, NOSE.
const float CAT_K = 0.62;          // the cat is drawn at this scale of its own design

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	mpos = UV;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float cover(float d, float w) {
	return 1.0 - smoothstep(-w, w, d);
}

// Approximate signed distance to an ellipse.
float sd_ell(vec2 p, vec2 r) {
	float k0 = length(p / r);
	float k1 = length(p / (r * r));
	return k0 * (k0 - 1.0) / max(k1, 1e-4);
}

// A over B, straight alpha.
vec4 over(vec4 a, vec4 b) {
	float o = a.a + b.a * (1.0 - a.a);
	return vec4((a.rgb * a.a + b.rgb * b.a * (1.0 - a.a)) / max(o, 1e-4), o);
}

// One line (`row`) of the words texture centred on c, `mpt` metres a texel; 0 outside it.
float words_at(vec2 p, vec2 c, float row, float mpt) {
	vec2 q = (p - c) / mpt;
	vec2 uv = vec2(q.x / words_px.x + 0.5, (1.0 + (row + 0.5) * line_px - q.y) / words_px.y);
	float inside = step(abs(q.x), 0.5 * words_px.x) * step(abs(q.y), 0.5 * line_px);
	return texture(words, uv).r * inside;
}

// ---- the cat scene ---------------------------------------------------------------------

vec3 cat_bg(vec2 p, float ts) {
	vec2 uv = p / size;
	vec3 c = mix(vec3(0.05, 0.03, 0.12), vec3(0.2, 0.1, 0.35), uv.y);
	// A spotlit wall with soft diagonal bands moving across.
	float b = 0.5 + 0.5 * sin((p.x + p.y * 0.6) * 0.35 - ts * 0.8);
	c += vec3(0.15, 0.06, 0.22) * b * 0.6;
	c += vec3(0.5, 0.3, 0.7) * exp(-length((uv - vec2(0.5, 0.55)) * vec2(1.4, 1.0)) * 3.2) * 0.4;
	return c;
}

vec4 cat_head(vec2 p, vec2 c, float ts) {
	vec2 q = p - c;
	float soft = 0.08;
	vec3 fur = vec3(0.82, 0.5, 0.2);
	vec3 dark = vec3(0.32, 0.16, 0.07);
	vec4 col = vec4(0.0);
	// The ears, outer and inner.
	for (int i = 0; i < 2; i++) {
		float s = i == 0 ? -1.0 : 1.0;
		vec2 e = rot(q - vec2(s * 4.1, 3.9), s * -0.5);
		float d = sd_ell(e, vec2(2.0, 3.2));
		float ei = sd_ell(rot(q - vec2(s * 4.0, 3.9), s * -0.5), vec2(1.1, 2.2));
		col = over(vec4(fur * 0.8, cover(d, soft)), col);
		col = over(vec4(vec3(0.95, 0.55, 0.6), cover(ei, soft) * 0.9), col);
	}
	// The chest and the head.
	float chest = sd_ell(q - vec2(0.0, -4.4), vec2(8.2, 5.2));
	col = over(vec4(fur * 0.75, cover(chest, soft)), col);
	float head = sd_ell(q, vec2(6.4, 5.1));
	float hs = clamp(length(q / vec2(6.4, 5.1)), 0.0, 1.0);
	vec3 hc = fur * (1.12 - 0.35 * hs * hs);
	// The tabby: dark bars on the brow and the cheeks, a pale muzzle.
	float bars = smoothstep(0.55, 0.75, sin(q.x * 3.4 + abs(q.x) * 0.4)) * smoothstep(1.4, 3.2, q.y) * smoothstep(5.0, 3.2, q.y);
	float cheek = smoothstep(0.7, 0.9, sin(q.y * 4.5 + abs(q.x) * 1.2)) * smoothstep(2.4, 3.8, abs(q.x)) * smoothstep(-0.5, -2.0, -q.y - 0.2);
	hc = mix(hc, dark, max(bars, cheek * 0.8) * 0.8);
	hc = mix(hc, vec3(0.97, 0.9, 0.8), smoothstep(1.9, 0.6, length(q * vec2(0.8, 1.0) - vec2(0.0, -2.0))) * 0.9);
	col = over(vec4(hc, cover(head, soft)), col);
	// The eyes, with slit pupils; a blink every few seconds.
	float blink = 1.0 - smoothstep(0.0, 0.1, abs(fract(ts / 3.7) - 0.5) - 0.46) * 0.0;
	float lid = fract(ts / 3.7) > 0.96 ? 0.12 : 1.0;
	for (int i = 0; i < 2; i++) {
		float s = i == 0 ? -1.0 : 1.0;
		vec2 e = vec2(q.x - s * 2.5, (q.y - 0.7) / lid);
		float d = sd_ell(e, vec2(1.45, 1.1));
		vec3 iris = mix(vec3(0.95, 0.9, 0.2), vec3(0.3, 0.8, 0.25), smoothstep(-0.9, 0.2, d));
		col = over(vec4(iris, cover(d, soft)), col);
		float pu = sd_ell(e - vec2(s * -0.1, 0.0), vec2(0.28, 0.95));
		col = over(vec4(vec3(0.02), cover(pu, soft)), col);
		col = over(vec4(vec3(1.0), cover(length(e - vec2(-0.4, 0.4)) - 0.2, soft)), col);
	}
	// The nose and mouth, the whiskers.
	col = over(vec4(vec3(0.95, 0.45, 0.55), cover(sd_ell(q - vec2(0.0, -0.9), vec2(0.7, 0.5)), soft)), col);
	float mouth = abs(length(vec2(abs(q.x) - 0.75, q.y + 1.9)) - 0.85);
	mouth = q.y < -1.2 && abs(q.x) < 1.9 ? mouth : 9.0;
	col = over(vec4(vec3(0.25, 0.1, 0.1), cover(mouth - 0.06, soft)), col);
	for (int w = 0; w < 3; w++) {
		float fw = float(w);
		for (int i = 0; i < 2; i++) {
			float s = i == 0 ? -1.0 : 1.0;
			vec2 o = vec2(s * 2.6, -1.3 - fw * 0.35);
			float a = s * (0.15 + fw * 0.16) * -1.0 - 0.12 * s * 0.0;
			vec2 u = rot(vec2(q.x * s - 2.6, q.y + 1.3 + fw * 0.35), a * s);
			float d = abs(u.y + 0.15 * u.x) - 0.04;
			float len = u.x > 0.0 && u.x < 5.2 ? d : 9.0;
			col = over(vec4(vec3(1.0, 0.95, 0.95), cover(len, soft) * 0.8), col);
		}
	}
	return col;
}

vec4 cat_paw(vec2 p, vec2 c) {
	vec2 q = p - c;
	float soft = 0.08;
	vec4 col = vec4(vec3(0.85, 0.52, 0.22), cover(sd_ell(q, vec2(2.3, 3.2)), soft));
	float toes = smoothstep(0.08, 0.0, abs(abs(q.x * 0.9) - 0.0)) * step(0.4, q.y) * step(q.y, 2.6);
	toes += smoothstep(0.1, 0.0, abs(abs(q.x) - 0.9)) * step(0.3, q.y) * step(q.y, 2.5);
	col.rgb = mix(col.rgb, vec3(0.45, 0.22, 0.1), clamp(toes, 0.0, 1.0));
	// The pad, a pink bean.
	col = over(vec4(vec3(0.95, 0.5, 0.6), cover(sd_ell(q - vec2(0.0, -0.8), vec2(1.15, 0.95)), soft)), col);
	col.rgb *= 0.8 + 0.3 * smoothstep(-3.0, 3.0, q.y);
	return col;
}

// The tail, standing up round the corner on the return face: a tabby stroke that sways.
vec4 cat_tail(vec2 p, float ts) {
	float tx = corner + (size.x - corner) * 0.45;
	float x = tx + 1.4 * sin(p.y * 0.42 + ts * 1.5) * smoothstep(0.6, 6.0, p.y);
	float top = 8.6 + 0.6 * sin(ts * 0.9);
	float d = max(abs(p.x - x) - 0.6 * (1.0 - 0.25 * smoothstep(2.0, top, p.y)), p.y - top);
	vec3 fur = mix(vec3(0.82, 0.5, 0.2), vec3(0.34, 0.17, 0.07), step(0.62, fract(p.y * 0.55)));
	return vec4(fur * (0.8 + 0.3 * step(x, p.x)), cover(d, 0.08));
}

vec4 scene_cat(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	vec4 col = base;
	float soft = 0.07;
	vec2 c = vec2(corner * 0.5, size.y * 0.49);
	if (depth < zexit) {
		vec2 p = m - r * depth;
		col = vec4(cat_bg(p, ts), 1.0);
		// Floating paw-print lights on the wall.
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			vec2 sp = vec2(2.5 + fi * size.x * 0.2, 2.0 + mod(fi * 5.7 + ts * 0.8, size.y - 3.0));
			col = over(vec4(vec3(0.9, 0.6, 1.0), cover(length(p - sp) - 0.3, soft) * 0.5), col);
		}
		// The tail, a little in front of the back wall.
		col = over(cat_tail(m - r * (depth - 0.8), ts), col);
	}
	// The head leans out of the box: closer than the glass, tilting a little.
	vec2 p1 = m - r * -0.9;
	float lean = sin(ts * 0.7) * 0.07 - 0.05;
	vec2 q = rot(p1 - c, -lean) / CAT_K + c;
	col = over(cat_head(q + vec2(sin(ts * 0.7) * 0.4, 0.0), c, ts), col);
	// The paws: over the bottom edge of the frame, well in front of it.
	vec2 pp = (m - r * -2.8 - c) / CAT_K + c;
	float nudge = sin(ts * 1.4) * 0.35;
	col = over(cat_paw(pp, c + vec2(-5.9, -8.2 + nudge)), col);
	col = over(cat_paw(pp, c + vec2(5.9, -8.2 - nudge)), col);
	return col;
}

// ---- the game's promo ------------------------------------------------------------------

// A sunset over a skyline, the Palace of Culture standing on the return face.
vec3 promo_bg(vec2 p, float ts) {
	vec2 uv = p / size;
	vec3 c = mix(vec3(0.03, 0.03, 0.14), vec3(0.34, 0.08, 0.36), smoothstep(0.05, 1.0, 1.0 - uv.y * 0.8));
	// The striped low sun.
	float sd = length(p - vec2(corner * 0.5, 3.2));
	float bands = max(step(0.3, fract(p.y * 0.8 - ts * 0.15)), step(5.5, p.y));
	vec3 sun = mix(vec3(1.0, 0.25, 0.5), vec3(1.0, 0.85, 0.35), smoothstep(1.0, 8.0, p.y));
	c = mix(c, sun, cover(sd - 6.0, 0.1) * bands);
	// Two neon ribbons rolling through.
	float r1 = abs(p.y - (8.5 + 2.5 * sin(p.x * 0.25 + ts * 0.9)));
	c += vec3(0.1, 0.8, 1.0) * exp(-r1 * 1.8) * 0.45;
	// The skyline: blocks, and the Palace's steps and spire.
	float h = 1.6 + 2.4 * hash(vec2(floor(p.x / 1.7), 3.0));
	float d = abs(p.x - (corner + (size.x - corner) * 0.5));
	float pal = 0.6 + 3.6 * step(d, 2.6) + 2.6 * step(d, 1.6) + 2.0 * step(d, 1.0) + 1.4 * step(d, 0.5) + 2.2 * step(d, 0.1);
	h = max(h, pal);
	float win = step(0.62, hash(floor(p * vec2(2.5, 3.0)))) * step(0.45, fract(p.x * 2.5)) * step(0.4, fract(p.y * 3.0));
	vec3 sil = vec3(0.07, 0.03, 0.16) + vec3(1.0, 0.75, 0.4) * win * 0.55;
	return mix(c, sil, step(p.y, h));
}

vec4 scene_promo(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	vec4 col = base;
	float back = step(depth, zexit);
	vec2 p = m - r * depth;
	col = mix(col, vec4(promo_bg(p, ts), 1.0), back);
	// AROUND over WARSAW, popped out of the glass with a dark extrusion; their shadow on the wall.
	float bob = 0.2 * sin(ts * 1.6);
	vec2 ca = vec2(corner * 0.5, 9.4 + bob);
	vec2 cw = vec2(corner * 0.5, 5.0 - bob);
	vec2 sh = p + vec2(-0.5, 0.5);
	col.rgb *= 1.0 - 0.5 * back * max(words_at(sh, ca, 0.0, 0.42), words_at(sh, cw, 1.0, 0.42));
	vec2 pe = m - r * -1.0;
	vec2 pf = m - r * -1.5;
	col = over(vec4(vec3(0.05, 0.25, 0.45), words_at(pe, ca, 0.0, 0.42)), col);
	col = over(vec4(vec3(0.4, 0.03, 0.25), words_at(pe, cw, 1.0, 0.42)), col);
	vec3 white = mix(vec3(1.0), vec3(0.6, 0.95, 1.0), smoothstep(8.0, 11.0, pf.y));
	col = over(vec4(white, words_at(pf, ca, 0.0, 0.42)), col);
	col = over(vec4(vec3(1.0, 0.35, 0.8), words_at(pf, cw, 1.0, 0.42)), col);
	return col;
}

// ---- the NOSE. agency's mark -----------------------------------------------------------

vec4 scene_nose(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	vec4 col = base;
	// A light box: pale walls, a soft blue glow sweeping the back.
	float wall = step(zexit, depth) * step(0.001, zexit);
	col.rgb = mix(col.rgb, mix(vec3(0.62, 0.7, 0.88), vec3(0.95, 0.97, 1.0), 1.0 - zexit / depth), wall);
	float back = step(depth, zexit);
	vec2 p = m - r * depth;
	vec3 bg = mix(vec3(0.97, 0.98, 1.0), vec3(0.8, 0.86, 0.97), smoothstep(0.0, size.y, p.y));
	bg = mix(bg, vec3(0.62, 0.74, 1.0), exp(-abs(p.x - mod(ts * 6.0, size.x + 8.0) + 4.0) * 0.35) * 0.35);
	col = mix(col, vec4(bg, 1.0), back);
	// The blocky blue word pops out of the glass and stays out, an extrusion behind it.
	vec2 c = vec2(corner * 0.5, size.y * 0.5 + 0.2 * sin(ts * 1.3));
	float zf = -0.4 - 1.6 * smoothstep(0.0, 1.2, ts);
	col.rgb *= 1.0 - 0.35 * back * words_at(p + vec2(-0.7, 0.7), c, 2.0, 0.6);
	for (int k = 0; k < 4; k++) {
		float f = float(k) / 3.0;
		vec2 pk = m - r * mix(0.3, zf, f);
		vec3 blue = mix(vec3(0.03, 0.08, 0.42), vec3(0.1, 0.32, 1.0), f * f);
		col = over(vec4(blue, words_at(pk, c, 2.0, 0.6)), col);
	}
	return col;
}

// ---- the box ---------------------------------------------------------------------------

vec3 wall_colour(float z, bool top, bool bottom) {
	float k = 1.0 - clamp(z / depth, 0.0, 1.0);
	vec3 side = mix(vec3(0.25, 0.1, 0.7), vec3(0.75, 0.45, 1.0), k);
	if (top) {
		return mix(vec3(0.2, 0.45, 0.95), vec3(0.8, 0.9, 1.0), k);
	}
	if (bottom) {
		return mix(vec3(0.25, 0.2, 0.7), vec3(0.6, 0.5, 1.0), k);
	}
	return side;
}

void fragment() {
	vec3 N = normalize(wnorm);
	vec3 T = normalize(cross(vec3(0.0, 1.0, 0.0), N));
	vec3 V = normalize(INV_VIEW_MATRIX[3].xyz - wpos);
	float vn = max(dot(V, N), 0.12);
	vec2 r = vec2(dot(V, T), V.y * 0.4) / vn;   // metres sideways per metre of depth, towards the eye (up/down eased: the game's camera looks down)
	vec2 m = mpos;
	vec2 lo = vec2(bezel, bezel);
	vec2 hi = size - vec2(bezel);
	bool inner = all(greaterThanEqual(m, lo)) && all(lessThanEqual(m, hi));

	vec4 base = vec4(0.0);
	float zexit = 0.0;
	if (inner) {
		// Where the ray leaves the box, and through which wall.
		vec2 inv = 1.0 / (abs(r) + vec2(1e-4));
		float tx = r.x > 0.0 ? (m.x - lo.x) * inv.x : (hi.x - m.x) * inv.x;
		float ty = r.y > 0.0 ? (m.y - lo.y) * inv.y : (hi.y - m.y) * inv.y;
		zexit = min(tx, ty);
		if (zexit < depth) {
			bool via_y = ty < tx;
			bool top = via_y && r.y < 0.0;
			bool bottom = via_y && r.y > 0.0;
			base = vec4(wall_colour(zexit, top, bottom), 1.0);
		}
	} else if (m.y >= 0.0) {
		// The frame: brushed metal with the screen's edge lit violet.
		float edge = min(min(m.x - 0.0, size.x - m.x), min(m.y, size.y - m.y));
		vec3 metal = mix(vec3(0.3, 0.32, 0.4), vec3(0.62, 0.64, 0.75), smoothstep(0.0, bezel, edge));
		vec3 led = vec3(0.45, 0.35, 1.0) * smoothstep(bezel * 0.55, bezel * 0.95, edge) * 1.1;
		base = vec4(metal * 0.8 + led, 1.0);
	}

	// Which scene each point of the screen shows: a wipe runs along the screen.
	float u = m.x / size.x;
	float tt = mod(TIME - u * 0.9 + LOOP, LOOP);
	vec4 col;
	if (tt < SCENES.x) {
		col = scene_cat(m, r, zexit, tt, base);
	} else if (tt < SCENES.x + SCENES.y) {
		col = scene_promo(m, r, zexit, tt - SCENES.x, base);
	} else {
		col = scene_nose(m, r, zexit, tt - SCENES.x - SCENES.y, base);
	}
	// The seam of the wipe: a bright flash line.
	float seam = min(min(abs(tt), abs(tt - SCENES.x)), min(abs(tt - SCENES.x - SCENES.y), abs(tt - LOOP)));
	col.rgb += vec3(0.7, 0.8, 1.0) * smoothstep(0.12, 0.0, seam) * col.a;

	// An LED panel: a faint pixel grid, brighter at night (past the bloom threshold).
	vec2 g = abs(fract(m * 1.6) - 0.5);
	float grid = 1.0 - 0.12 * smoothstep(0.38, 0.5, max(g.x, g.y));
	float gain = (0.92 + 0.75 * lights_on) * mix(grid, 1.0, 0.3);
	if (col.a < 0.5) {
		discard;
	}
	ALBEDO = pow(max(col.rgb, vec3(0.0)), vec3(2.2)) * gain;
}
