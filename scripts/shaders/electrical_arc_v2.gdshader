shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float transparency : hint_range(0.0, 1.0);
uniform vec2 speed = vec2(1.000000, 0.000000);
uniform vec2 scroll_direction = vec2(1.00000, 1.00000);
uniform sampler2D base_texture : source_color, repeat_enable;



void fragment() {
// Input:11
	vec4 input_color = COLOR;
// FloatParameter:10
	float input_transparency = transparency;
// Input:6
	float input_time = TIME;
// Vector2Parameter:8
	vec2 input_speed = speed;


// VectorOp:7
	vec2 scroll = vec2(input_time) * input_speed;

// UVFunc:5
	vec2 uv_scroll = scroll * scroll_direction + UV;

	vec4 out_texture = texture(base_texture, uv_scroll);

// SmoothStep:9
	float out_smooth = 1.00000;
	float smoothed = smoothstep(input_transparency, out_smooth, out_texture.x);
	
// VectorOp:12
	vec3 out_color = vec3(input_color.xyz) * vec3(smoothed);
	
// Output:0
	COLOR.rgb = out_color;


}
