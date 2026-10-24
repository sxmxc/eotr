shader_type canvas_item;
render_mode unshaded;

uniform vec4 shade : source_color = vec4(0.018, 0.029, 0.052, 1.0);
uniform float edge_strength : hint_range(0.0, 1.0) = 0.40;
uniform float menu_strength : hint_range(0.0, 1.0) = 0.64;

void fragment() {
	vec2 edge = abs(UV * 2.0 - 1.0);
	float vignette = smoothstep(0.42, 1.22, length(edge * vec2(0.78, 0.9)));
	float menu = 1.0 - smoothstep(0.20, 0.62, UV.x);
	float alpha = 1.0 - (1.0 - edge_strength * vignette) * (1.0 - menu_strength * menu);
	COLOR *= vec4(shade.rgb, alpha * shade.a);
}
