shader_type canvas_item;
// The pixel-art finish of the full-screen 2D scenes drawn in code (palm_tasting_ui.gd; F 2026-11-26
// "the pixel style ... but with more pixels", after the isometric pixel-city reference). Runs on the
// TextureRect that shows the low-resolution scene viewport, scaled up a whole number of times with
// nearest filtering. Per scene pixel:
//   - ink: where a pixel differs strongly from its left or upper neighbour, it becomes the darker of
//     the two, darkened again: a one-pixel outline in the shape's own hue (never black), on every
//     silhouette but not on the soft shade steps inside a form;
//   - levels: each channel stepped to `levels` (no dither: flat fills stay flat), so the gradients
//     (sky, glows, haze, shadows) turn into a few clean bands, as in hand-made pixel art.
// Cost: five texture reads a fragment over the screen while the scene is up (the city's 3D is off).

uniform vec2 px = vec2(384.0, 216.0);  // the scene viewport's size in pixels
uniform float levels = 20.0;
uniform float edge = 0.22;             // colour distance that counts as a silhouette
uniform float ink = 0.5;              // how dark the outline is against the darker side

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 cell = floor(UV * px);
	vec2 t = 1.0 / px;
	vec2 uv = (cell + 0.5) * t;
	vec3 c = texture(TEXTURE, uv).rgb;
	vec3 l = texture(TEXTURE, uv - vec2(t.x, 0.0)).rgb;
	vec3 u = texture(TEXTURE, uv - vec2(0.0, t.y)).rgb;
	float dl = cell.x > 0.0 ? distance(c, l) : 0.0;
	float du = cell.y > 0.0 ? distance(c, u) : 0.0;
	if (max(dl, du) > edge) {
		vec3 n = dl > du ? l : u;
		vec3 dark = luma(n) < luma(c) ? n : c;
		c = dark * ink;
	}
	float lv = levels - 1.0;
	c = floor(c * lv + 0.5) / lv;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
