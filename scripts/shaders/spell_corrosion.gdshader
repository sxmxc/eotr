shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.65, 0.83, 0.25, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = progress;
	float r = length(p);
	float angle = atan(p.y, p.x);
	float crawl = sin(angle * 6.0 + r * 16.0) + 0.5 * sin(angle * 11.0 - r * 9.0);
	float cracks = exp(-abs(crawl) * 8.0) * smoothstep(0.04, 0.18, r) * (1.0 - smoothstep(t * 0.85, t * 0.85 + 0.1, r));
	float drops = 0.0;
	for (int i = 0; i < 5; i++) {
		float index = float(i);
		vec2 center = vec2(sin(index * 7.0) * 0.55, -0.3 + t * 0.75 - index * 0.09);
		drops += exp(-length((p - center) * vec2(1.0, 0.5)) * 65.0);
	}
	float pool = (1.0 - smoothstep(0.2, 0.55, length(p * vec2(1.0, 2.0)))) * 0.15;
	float a = (cracks * (variant == 1 ? 1.0 : 0.5) + drops + pool) * sin(t * 3.14159);
	COLOR = vec4(mix(vec3(0.15, 0.05, 0.19), accent.rgb, clamp(cracks + drops, 0.0, 1.0)), clamp(a, 0.0, 0.95)) * COLOR;
}
