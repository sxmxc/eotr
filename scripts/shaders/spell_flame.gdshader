shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform vec4 accent : source_color = vec4(1.0, 0.36, 0.08, 1.0);
void fragment() {
	vec2 p = UV;
	float t = progress;
	float flame = 0.0;
	for (int i = 0; i < 5; i++) {
		float index = float(i);
		float y = 0.82 - p.y;
		float x = p.x - (0.25 + index * 0.125) - sin(y * 12.0 + t * 9.0 + index * 2.0) * y * 0.08;
		float height = 0.4 + 0.18 * sin(index * 2.1 + 0.3);
		float width = max(0.005, (1.0 - y / height) * 0.075);
		flame += (1.0 - smoothstep(width, width + 0.025, abs(x))) * smoothstep(0.0, 0.06, y) * (1.0 - smoothstep(height - 0.04, height, y));
	}
	float fade = sin(pow(t, 0.6) * 3.14159);
	COLOR = vec4(mix(accent.rgb, vec3(1.0, 0.92, 0.38), clamp(flame - 0.5, 0.0, 0.7)), clamp(flame * fade, 0.0, 0.9)) * COLOR;
}
