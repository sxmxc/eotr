shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform vec4 accent : source_color = vec4(1.0, 0.36, 0.08, 1.0);
void fragment() {
	vec2 p = UV;
	float t = clamp(progress, 0.0, 1.0);
	float heart = 0.0;
	float flame = 0.0;
	for (int i = 0; i < 5; i++) {
		float index = float(i);
		float y = 0.82 - p.y;
		float life = clamp((t - index * 0.025) / 0.85, 0.0, 1.0);
		float x = p.x - (0.25 + index * 0.125) - sin(y * 10.0 - life * 5.0 + index * 2.0) * y * 0.13;
		float height = (0.4 + 0.18 * sin(index * 2.1 + 0.3)) * smoothstep(0.0, 0.22, life);
		float width = max(0.005, (1.0 - y / max(height, 0.001)) * (0.055 + 0.018 * sin(index * 3.0)));
		float vertical = smoothstep(0.0, 0.06, y) * (1.0 - smoothstep(height - 0.04, height, y));
		flame += (1.0 - smoothstep(width, width + 0.014, abs(x))) * vertical;
		heart += (1.0 - smoothstep(width * 0.25, width * 0.5 + 0.006, abs(x))) * vertical;
	}
	float fade = sin(pow(t, 0.6) * 3.14159);
	COLOR = vec4(mix(accent.rgb * 0.75, vec3(1.0, 0.87, 0.48), clamp(heart, 0.0, 0.9)), clamp(flame * fade, 0.0, 0.88) * smoothstep(0.0, 0.06, t)) * COLOR;
}
