shader_type canvas_item;
render_mode unshaded;

uniform float transparency : hint_range(0.0, 1.0) = 0.0;
uniform int strike_style = 0;
uniform vec4 ink_color : source_color = vec4(0.04, 0.22, 0.27, 1.0);
uniform vec4 core_color : source_color = vec4(0.9, 1.0, 0.96, 1.0);

void fragment() {
	// Broad inked bands along the native Line2D; no noisy scrolling sprite sheet.
	float curl = sin(UV.x * 18.0 - TIME * 9.0) * 0.055;
	float edge = abs(UV.y - 0.5 + curl);
	if (strike_style == 2) {
		edge = min(abs(UV.y - 0.27 + curl), abs(UV.y - 0.73 - curl)) * 1.8;
	}
	float mask = 1.0 - smoothstep(0.32, 0.46, edge);
	float body = 1.0 - smoothstep(0.23, 0.32, edge);
	float core = 1.0 - smoothstep(0.06, 0.13, edge);
	vec3 pigment = mix(ink_color.rgb, COLOR.rgb, body);
	pigment = mix(pigment, core_color.rgb, core);
	COLOR = vec4(pigment, COLOR.a * mask * (1.0 - transparency));
}
