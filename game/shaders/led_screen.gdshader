shader_type spatial;
// The big curved corner LED screen on Skylight at Złote Tarasy (tarasy_screen.gd): the "3D"
// anamorphic kind. The mesh is a strip along the tower's wall; UV is in metres (x along the
// screen, y up from the bottom of the box, with a margin below the box for what pops out).
// The picture is a little box seen through its front: a ray from the eye is followed into it, so
// the side walls show and each layer shifts with the viewer (real parallax: the flowers float in
// front of the frame, the cat's paws hang over its bottom edge). Three scenes of an original
// loop, wiped one into the next along the screen: the glowing flowers, the cat leaning out, the
// title. Unshaded and bright; at night it glows past the bloom threshold.

render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled, fog_disabled;

global uniform float lights_on;
global uniform float daylight;

uniform vec2 size = vec2(50.0, 17.0);     // the box in metres
uniform float margin = 2.6;               // the mesh below the box
uniform float bezel = 0.6;                // the frame round the box
uniform float depth = 3.2;                // the box's depth behind the glass
uniform sampler2D words : filter_nearest, repeat_disable;
uniform vec2 words_px = vec2(64.0, 24.0);  // the title texture in texels
uniform float words_m = 0.6;               // metres per texel

varying vec3 wpos;
varying vec3 wnorm;
varying vec2 mpos;

const float LOOP = 24.0;           // the whole loop
const vec3 SCENES = vec3(9.0, 8.0, 7.0);   // seconds of flowers, cat, title

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

// One petal in its own frame: base at the origin, pointing up, `len` long, `wid` half-wide.
vec4 petal(vec2 q, float len, float wid, vec3 base, vec3 tip, float soft) {
	float t = q.y / len;
	if (t < 0.0 || t > 1.0) {
		return vec4(0.0);
	}
	float w = wid * pow(sin(PI * pow(t, 0.7)), 0.85) * (1.0 - 0.15 * t);
	float a = cover(abs(q.x) - w, soft);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	float e = clamp(abs(q.x) / max(w, 1e-3), 0.0, 1.0);
	vec3 c = mix(base, tip, smoothstep(0.0, 0.85, t));
	c += (1.0 - e) * 0.22 * (1.0 - t * 0.6) * vec3(1.0, 0.85, 0.95);   // the lit midrib
	c = mix(c, tip * 1.25 + 0.08, smoothstep(0.78, 1.0, e) * 0.7);    // a bright rim
	return vec4(c, a);
}

// A flower: petals fanned over +-spread radians from straight up, outermost first.
vec4 flower(vec2 p, vec2 c, int n, float spread, float len, float wid, float bend, vec3 base, vec3 tip, float soft) {
	vec4 col = vec4(0.0);
	float half_n = ceil(float(n) * 0.5);
	for (int k = 0; k < 9; k++) {
		if (k >= n) {
			break;
		}
		float side = mod(float(k), 2.0) < 0.5 ? -1.0 : 1.0;
		float rank = floor(float(k) * 0.5);
		float f = 1.0 - rank / half_n;
		float ang = side * spread * f;
		vec2 q = rot(p - c, -ang);
		q.x -= side * bend * q.y * q.y * 0.05;
		float l = len * (0.78 + 0.22 * (1.0 - f));
		col = over(petal(q, l, wid * (0.9 + 0.2 * (1.0 - f)), base * (0.8 + 0.2 * (1.0 - f)), tip, soft), col);
	}
	return col;
}

// ---- the flowers scene -----------------------------------------------------------------

vec3 flowers_bg(vec2 p, float ts) {
	vec2 uv = p / size;
	vec3 c = mix(vec3(0.02, 0.0, 0.05), vec3(0.13, 0.03, 0.2), smoothstep(0.0, 1.0, uv.y * 0.9 + uv.x * 0.15));
	// A dark garden: slow blobs of leaf and a haze behind the flowers.
	float g = 0.5 + 0.5 * sin(p.x * 0.7 + sin(p.y * 0.9) * 2.0 + ts * 0.3);
	c += vec3(0.0, 0.08, 0.1) * g * smoothstep(0.55, 0.0, uv.y);
	c += vec3(0.25, 0.05, 0.3) * exp(-length((uv - vec2(0.5, 0.5)) * vec2(1.6, 1.0)) * 3.0) * 0.45;
	// Sparkles: little lights that blink.
	vec2 cell = floor(p * 0.9);
	float h = hash(cell);
	vec2 f = fract(p * 0.9) - 0.5;
	float tw = 0.5 + 0.5 * sin(ts * (1.5 + h * 3.0) + h * 40.0);
	c += vec3(1.0, 0.8, 1.0) * smoothstep(0.1, 0.0, length(f + (hash(cell + 7.0) - 0.5) * 0.5)) * step(0.72, h) * tw * 0.8;
	return c;
}

vec4 flowers_small(vec2 p, vec2 c, float s, vec3 base, vec3 tip, float soft) {
	return flower(p, c, 5, 1.05, 3.2 * s, 0.75 * s, 0.0, base, tip, soft);
}

vec4 scene_flowers(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	float soft = 0.07;
	vec4 col = base;
	float sway = sin(ts * 0.9) * 0.035;
	// Far: the dark garden and two small blue blossoms.
	if (depth < zexit) {
		vec2 p = m - r * depth;
		col = vec4(flowers_bg(p, ts), 1.0);
		col = over(flowers_small(p, vec2(17.0, 3.0), 1.0, vec3(0.2, 0.3, 1.0), vec3(0.2, 0.9, 1.0), soft * 1.3), col);
		col = over(flowers_small(p, vec2(44.5, 5.0), 1.2, vec3(0.35, 0.2, 0.95), vec3(0.95, 0.4, 1.0), soft * 1.3), col);
		col = over(flowers_small(p, vec2(30.5, 1.5), 0.8, vec3(0.1, 0.5, 1.0), vec3(1.0, 0.55, 0.3), soft * 1.3), col);
	}
	// Middle: the orange flower, in the glass.
	float z1 = 1.0;
	if (z1 < zexit) {
		vec2 p = m - r * z1;
		vec2 c = vec2(33.0, 2.0);
		vec2 q = rot(p - c, sway * 1.5);
		vec4 f = flower(q + c, c, 7, 1.0, 13.0 + 0.4 * sin(ts * 1.1), 3.1, 1.0, vec3(0.75, 0.2, 0.05), vec3(1.0, 0.55, 0.08), soft);
		float glow = exp(-length(p - c - vec2(0.0, 5.0)) * 0.13) * 0.35;
		col.rgb += vec3(1.0, 0.35, 0.05) * glow * col.a;
		col = over(f, col);
		// The stamens: tiny cyan lights in its heart.
		for (int i = 0; i < 6; i++) {
			float a = float(i) * 0.9 - 2.2;
			vec2 sp = c + vec2(sin(a) * 1.6, 4.2 + cos(a) * 1.1 + float(i % 2) * 0.5);
			col = over(vec4(vec3(0.5, 1.0, 1.0), cover(length(p - sp) - 0.28, soft)), col);
		}
	}
	// Near: the pink lotus, floating out in front of the frame.
	float z2 = -1.2;
	if (z2 < zexit || zexit <= 0.0) {
		vec2 p = m - r * z2;
		vec2 c = vec2(14.0, 0.9);
		float breathe = 1.0 + 0.025 * sin(ts * 1.3);
		vec2 q = rot(p - c, -sway) / breathe + c;
		float glow = exp(-length(q - c - vec2(0.0, 7.0)) * 0.1) * 0.4;
		vec4 back = flower(q, c + vec2(0.0, 0.3), 5, 1.2, 12.0, 3.4, 0.7, vec3(0.7, 0.05, 0.4), vec3(1.0, 0.25, 0.6), soft);
		vec4 front = flower(q, c, 7, 0.95, 14.0, 3.6, 0.5, vec3(0.9, 0.2, 0.55), vec3(1.0, 0.45, 0.75), soft);
		vec4 f = over(front, back);
		col.rgb += vec3(1.0, 0.2, 0.5) * glow * col.a;
		col = over(f, col);
		// A few seeds of light drifting up out of the lotus.
		for (int i = 0; i < 7; i++) {
			float fi = float(i);
			float life = fract(ts * 0.12 + fi * 0.143);
			vec2 sp = c + vec2(sin(fi * 2.3 + ts * 0.6) * 4.0, 6.0 + life * 13.0);
			col = over(vec4(vec3(1.0, 0.7, 0.9), cover(length(p - sp) - 0.2, soft) * (1.0 - life)), col);
		}
	}
	return col;
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

vec4 scene_cat(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	vec4 col = base;
	float soft = 0.07;
	if (depth < zexit) {
		vec2 p = m - r * depth;
		col = vec4(cat_bg(p, ts), 1.0);
		// Floating paw-print lights on the wall.
		for (int i = 0; i < 6; i++) {
			float fi = float(i);
			vec2 sp = vec2(5.0 + fi * 8.3, 3.0 + mod(fi * 5.7 + ts * 0.8, 15.0));
			col = over(vec4(vec3(0.9, 0.6, 1.0), cover(length(p - sp) - 0.35, soft) * 0.5), col);
		}
	}
	// The head leans out of the box: closer than the glass, tilting a little.
	float z1 = -0.9;
	if (z1 < zexit || zexit <= 0.0) {
		vec2 p = m - r * z1;
		vec2 c = vec2(24.5, 8.6);
		float lean = sin(ts * 0.7) * 0.07 - 0.05;
		vec2 q = rot(p - c, -lean) + c;
		col = over(cat_head(q + vec2(sin(ts * 0.7) * 0.4, 0.0), c, ts), col);
	}
	// The paws: over the bottom edge of the frame, well in front of it.
	float z2 = -2.8;
	vec2 pp = m - r * z2;
	float nudge = sin(ts * 1.4) * 0.35;
	col = over(cat_paw(pp, vec2(18.6, 0.4 + nudge)), col);
	col = over(cat_paw(pp, vec2(30.4, 0.4 - nudge)), col);
	return col;
}

// ---- the title scene -------------------------------------------------------------------

float words_at(vec2 p, vec2 c) {
	vec2 q = (p - c) / words_m;
	vec2 uv = vec2(q.x / words_px.x + 0.5, 0.5 - q.y / words_px.y);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(words, uv).r;
}

vec3 title_bg(vec2 p, float ts) {
	vec2 uv = p / size;
	vec3 c = mix(vec3(0.02, 0.03, 0.12), vec3(0.12, 0.04, 0.25), uv.y);
	// Two neon ribbons rolling through.
	float r1 = abs(p.y - (8.0 + 4.5 * sin(p.x * 0.18 + ts * 0.9)));
	float r2 = abs(p.y - (9.0 + 3.5 * sin(p.x * 0.14 - ts * 0.7 + 2.0)));
	c += vec3(0.1, 0.8, 1.0) * exp(-r1 * 1.6) * 0.55;
	c += vec3(1.0, 0.15, 0.75) * exp(-r2 * 1.3) * 0.6;
	return c;
}

vec4 scene_title(vec2 m, vec2 r, float zexit, float ts, vec4 base) {
	vec4 col = base;
	float soft = 0.07;
	if (depth < zexit) {
		vec2 p = m - r * depth;
		col = vec4(title_bg(p, ts), 1.0);
	}
	// The title pops out of the glass (z -1.6), its shadow lies on the ribbons behind.
	float z1 = -1.6;
	vec2 p1 = m - r * z1;
	vec2 c1 = vec2(25.0, 9.0 + 0.25 * sin(ts * 1.6));
	float wd = words_at(p1, c1);
	float sh = words_at(m - r * 1.0 + vec2(0.5, -0.5), c1);
	if (depth < zexit) {
		col.rgb *= 1.0 - 0.55 * sh;
	}
	vec3 txt = mix(vec3(1.0), vec3(0.75, 0.9, 1.0), smoothstep(5.0, 13.0, p1.y));
	col = over(vec4(txt, wd), col);
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
		col = scene_flowers(m, r, zexit, tt, base);
	} else if (tt < SCENES.x + SCENES.y) {
		col = scene_cat(m, r, zexit, tt - SCENES.x, base);
	} else {
		col = scene_title(m, r, zexit, tt - SCENES.x - SCENES.y, base);
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
