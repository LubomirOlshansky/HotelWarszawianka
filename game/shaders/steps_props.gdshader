shader_type spatial;
// Schodki nad Wisłą, Phase D (2026-11-19): the little things beside the steps' sitters (picnic
// blankets, bottles and cans, speakers, backpacks, a pizza box) as ONE MultiMesh of unit boxes.
// INSTANCE_CUSTOM.rgb is each one's paint (sRGB), INSTANCE_CUSTOM.a its glow (a speaker's LED: 1,
// lit only when the city's lights are on). Under the street lamps they catch the light like the
// people do (actor.gdshader).

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"

varying vec3 tint;
varying float glow;
varying vec3 world_pos;

void vertex() {
	vec3 paint = INSTANCE_CUSTOM.rgb;
	tint = srgb_to_linear(paint);
	glow = INSTANCE_CUSTOM.a;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 0.75;
	SPECULAR = 0.3;
	EMISSION = (tint * glow * 3.0 + tint * lamp_light(world_pos.xz) * 1.4) * lights_on;
}
