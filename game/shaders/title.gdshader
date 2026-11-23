shader_type canvas_item;
// The title screen's backdrop (title.gd): a dusk sky with a striped setting sun,
// a Warsaw skyline against it (the Palace of Culture in the middle, Varso and a
// few towers), and a neon perspective grid. Still: nothing moves (F 2026-11-23: no animation on
// the loading screen, the rolling road included).

uniform float aspect = 1.7778;
// Height of the horizon from the top, as a share of the screen.
uniform float horizon = 0.64;

const vec3 INDIGO = vec3(0.035, 0.02, 0.11);
const vec3 PURPLE = vec3(0.2, 0.06, 0.36);
const vec3 MAGENTA = vec3(0.78, 0.16, 0.55);
const vec3 ORANGE = vec3(1.0, 0.5, 0.36);
const vec3 SUN_TOP = vec3(1.0, 0.9, 0.42);
const vec3 SUN_BOTTOM = vec3(1.0, 0.24, 0.62);
const vec3 SILHOUETTE = vec3(0.09, 0.03, 0.17);
const vec3 GRID = vec3(1.0, 0.2, 0.75);

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float box(vec2 p, float x0, float x1, float top, float hz) {
	return step(x0, p.x) * step(p.x, x1) * step(hz - top, p.y);
}

// 1 inside the skyline: x in screen heights from the centre, y from the top.
float skyline(vec2 p, float hz) {
	float s = 0.0;
	// The Palace of Culture, seen from Marszałkowska, drawn from the game's model
	// (landmarks.gd) in metres: base and wings, the four corner towers to 67 m, the
	// shaft to 139 m with its pinnacles, the clock tier, the lantern, the crown and the
	// gilded spire to 237 m. Heights at 0.00146 screen per metre, widths a little wider.
	float cx = 0.03;
	float x = p.x - cx;
	float k = 0.00146;
	float kw = 0.0021;
	s = max(s, box(vec2(x, p.y), -133.0 * kw, 133.0 * kw, 18.0 * k, hz));
	for (int i = 0; i < 2; i++) {
		float side = i == 0 ? -1.0 : 1.0;
		vec2 q = vec2(x * side, p.y);
		s = max(s, box(q, 70.0 * kw, 121.0 * kw, 24.0 * k, hz));     // corner pavilions
		s = max(s, box(q, 44.0 * kw, 68.0 * kw, 30.0 * k, hz));      // annexes
		s = max(s, box(q, 0.0, 36.0 * kw, 67.0 * k, hz));            // first tier
		s = max(s, box(q, 21.5 * kw, 30.5 * kw, 73.0 * k, hz));      // corner tower crown
		s = max(s, box(q, 24.9 * kw, 27.1 * kw, 82.0 * k, hz));      // its pinnacle
		s = max(s, box(q, 33.6 * kw, 35.2 * kw, 74.0 * k, hz));      // outer pinnacle
		s = max(s, box(q, 0.0, 22.0 * kw, 139.0 * k, hz));           // the shaft
		s = max(s, box(q, 17.8 * kw, 21.2 * kw, 153.0 * k, hz));     // shaft pinnacles
		s = max(s, box(q, 0.0, 12.5 * kw, 143.0 * k, hz));           // plinth
		s = max(s, box(q, 0.0, 8.5 * kw, 168.0 * k, hz));            // clock tier
		s = max(s, box(q, 6.5 * kw, 8.3 * kw, 177.0 * k, hz));       // its pinnacles
		s = max(s, box(q, 0.0, 6.3 * kw, 188.0 * k, hz));            // lantern
		for (int j = 0; j < 3; j++) {
			float px = 66.0 + float(j) * 26.0;
			s = max(s, box(q, (px - 0.8) * kw, (px + 0.8) * kw, 28.0 * k, hz)); // wing pinnacles
		}
	}
	// The crown narrows from the lantern, then the spire to its point.
	float up = (hz - p.y) / k;
	if (up > 188.0 && up < 203.0 && abs(x) < mix(6.0, 2.4, (up - 188.0) / 15.0) * kw) {
		s = 1.0;
	}
	if (up >= 200.0 && up < 237.0 && abs(x) < mix(1.8, 0.15, (up - 200.0) / 37.0) * kw + 0.0012) {
		s = 1.0;
	}
	// Varso: a tall tower with a needle, left of the Palace.
	s = max(s, box(p, -0.52, -0.46, 0.25, hz));
	if (p.x > -0.493 && p.x < -0.487 && p.y > hz - 0.34) {
		s = 1.0;
	}
	// The other towers: a few glass slabs and blocks along the horizon.
	s = max(s, box(p, -0.43, -0.37, 0.15, hz));
	s = max(s, box(p, -0.36, -0.3, 0.19, hz));
	s = max(s, box(p, -0.3, -0.22, 0.09, hz));
	s = max(s, box(p, 0.25, 0.32, 0.17, hz));
	s = max(s, box(p, 0.33, 0.37, 0.12, hz));
	s = max(s, box(p, 0.38, 0.46, 0.21, hz));
	s = max(s, box(p, 0.47, 0.55, 0.08, hz));
	s = max(s, box(p, -0.75, -0.55, 0.05, hz));
	s = max(s, box(p, 0.56, 0.8, 0.04, hz));
	return s;
}

void fragment() {
	vec2 uv = UV;
	float hz = horizon;
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y);
	vec3 col;
	if (uv.y < hz) {
		float t = uv.y / hz;
		col = mix(INDIGO, PURPLE, smoothstep(0.0, 0.55, t));
		col = mix(col, MAGENTA, smoothstep(0.5, 0.85, t));
		col = mix(col, ORANGE, smoothstep(0.86, 1.0, t));
		// Stars in the upper sky.
		vec2 cell = floor(uv * vec2(aspect, 1.0) * 180.0);
		float h = hash(cell);
		if (h > 0.996 && t < 0.55) {
			col += vec3(0.9, 0.85, 1.0) * (0.5 + 0.5 * sin(h * 50.0)) * (1.0 - t / 0.55);
		}
		// The sun, striped across its lower half.
		vec2 c = vec2(0.03, hz - 0.25);
		float r = 0.235;
		float d = length(p - c);
		col += vec3(1.0, 0.3, 0.6) * exp(-max(d - r, 0.0) * 7.0) * 0.3;
		if (d < r) {
			float k = (p.y - c.y) / r;
			vec3 sun = mix(SUN_TOP, SUN_BOTTOM, smoothstep(-0.9, 0.9, k));
			bool gap = false;
			if (k > -0.1) {
				float band = fract(k * 5.0);
				gap = band < mix(0.06, 0.5, (k + 0.1) / 1.1);
			}
			if (!gap) {
				col = sun;
			}
		}
		if (skyline(p, hz) > 0.5) {
			col = SILHOUETTE * (0.8 + 0.5 * t);
		}
	} else {
		// The grid floor: depth from the screen row, lines in world space.
		float t = (uv.y - hz) / (1.0 - hz);
		col = mix(vec3(0.13, 0.03, 0.22), vec3(0.02, 0.0, 0.05), smoothstep(0.0, 1.0, t));
		float z = 1.0 / max(t, 0.002);
		float wx = (uv.x - 0.5) * aspect * z * 2.2;
		float wz = z * 0.9;
		float lx = (0.5 - abs(fract(wx) - 0.5)) / max(fwidth(wx), 1e-5);
		float lz = (0.5 - abs(fract(wz) - 0.5)) / max(fwidth(wz), 1e-5);
		float line = max(1.0 - smoothstep(0.0, 1.4, lx), 1.0 - smoothstep(0.0, 1.4, lz));
		float fade = smoothstep(0.0, 0.25, t);
		col += GRID * line * fade;
		col += GRID * 0.12 * line * (1.0 - fade);
		// Haze on the horizon.
		col += MAGENTA * exp(-t * 9.0) * 0.55;
	}
	// The horizon line itself.
	col += vec3(1.0, 0.55, 0.8) * exp(-abs(uv.y - hz) * 260.0) * 0.8;
	COLOR = vec4(col, COLOR.a);
}
