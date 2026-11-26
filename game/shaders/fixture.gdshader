shader_type spatial;
// Street lamps: vertex-coloured boxes whose head (UV.x = 1, map_builder.gd) glows
// when the city's lights are on, in the colour of the lamp's own light
// (INSTANCE_CUSTOM.rgb: sodium orange or LED white, from the baked light map). Parts marked
// UV.x = 2 glow in their own colour instead (Krakowskie Przedmieście's Christmas chandeliers:
// green glass and gold beads, map_builder.gd _kp_lamp_mesh).

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/tunnel_cut.gdshaderinc"

global uniform float lights_on;

varying float head;
varying vec3 lamp;

void vertex() {
	head = UV.x;
	lamp = INSTANCE_CUSTOM.rgb;
	// The tunnel cutaway: a lamp standing over the opened ground goes with it.
	VERTEX = tunnel_hide(VERTEX, MODEL_MATRIX[3].xyz);
}

void fragment() {
	ALBEDO = srgb_to_linear(COLOR.rgb);
	ROUGHNESS = 0.7;
	SPECULAR = 0.5;
	if (lights_on > 0.001 && head > 1.5) {
		EMISSION = srgb_to_linear(COLOR.rgb) * 1.5 * lights_on;
	} else if (lights_on > 0.001 && head > 0.5) {
		EMISSION = lamp * 2.6 * lights_on;
	}
}
