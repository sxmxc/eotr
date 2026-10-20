shader_type canvas_item;
render_mode unshaded;
// Existing material API; a quiet ink veil replaces seven procedural noise octaves.
uniform float radius = 1.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform vec4 effect_color : source_color = vec4(0.251, 0.0, 0.0, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.25, 1.0) * max(radius, 0.001);
	float motion = sin(TIME * speed * 0.3) * 0.012;
	float veil = smoothstep(0.15 + motion, max(effect_color.a, 0.18), length(p));
	COLOR = vec4(effect_color.rgb * 0.22, veil) * COLOR;
}
