// Based on https://godotshaders.com/shader/screen-smoke-fog/
shader_type canvas_item;
render_mode blend_mix;

// Stuff related to camera position and offsets
uniform vec2 camera_position;
uniform vec2 camera_offset;
uniform float camera_position_speed: 	hint_range(0.0, 1.0) 	= 0.025;
uniform float camera_offset_speed: 		hint_range(0.0, 1.0) 	= 0.025;

// Uniforms for customization
uniform sampler2D noise_texture_1 : 	repeat_enable;
uniform sampler2D noise_texture_2 : 	repeat_enable;
uniform float noise_blend :				hint_range(0.0, 1.0) 	= 1.0;
uniform float noise_speed_1 :			hint_range(0.0, 1.0) 	= 1.0;
uniform float noise_speed_2 :			hint_range(0.0, 1.0) 	= 1.0;
uniform vec2 noise_dir_1 										= vec2(1.0,+1.0);
uniform vec2 noise_dir_2										= vec2(1.0,-1.0);
uniform vec3 smoke_color : 				source_color 			= vec3(0.8);
uniform float density : 				hint_range(0.0, 1.0) 	= 1.0;

varying vec2 world_pos;
varying vec4 fog_modulation;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	fog_modulation = COLOR;
}
void fragment() {
	// Sample continuous world coordinates, never atlas UVs that repeat per hex.
	vec2 p = world_pos / 850.0;
	float a = texture(noise_texture_1, p + TIME * vec2(0.012, -0.008)).r;
	float b = texture(noise_texture_2, p * 1.8 + TIME * vec2(-0.009, 0.011)).r;
	float cloud = smoothstep(0.22, 0.82, a * 0.7 + b * 0.3);
	vec3 mist = mix(vec3(0.003, 0.006, 0.012), vec3(0.012, 0.022, 0.038), cloud);
	// Use alpha only: floor pigments and outlines never appear in the fog.
	float mask = smoothstep(0.01, 0.3, texture(TEXTURE, UV).a);
	COLOR = vec4(mist, density * mask * fog_modulation.a);
}
