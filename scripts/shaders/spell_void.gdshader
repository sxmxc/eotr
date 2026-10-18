shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.72, 0.25, 0.95, 1.0);
float diamond(vec2 p) { return abs(p.x) + abs(p.y) * 0.6; }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = progress;
	float r = length(p);
	float angle = atan(p.y, p.x);
	float shards = 0.0;
	for (int i = 0; i < 7; i++) {
		float a = float(i) * 0.8976 + t * 0.5;
		float radius = mix(0.9, 0.06, t);
		vec2 center = vec2(cos(a), sin(a)) * radius;
		shards += (1.0 - smoothstep(0.035, 0.065, diamond(p - center))) * sin(t * 3.14159);
	}
	float opening = sin(t * 3.14159) * (variant == 1 ? 0.45 : 0.3);
	float boundary = exp(-abs(r - opening) * 65.0);
	float dark = (1.0 - smoothstep(opening - 0.04, opening, r)) * 0.9;
	if (variant == 2) { // Fracture: exactly three suspended shards, no black hole.
		shards = 0.0;
		for (int i = 0; i < 3; i++) {
			vec2 c = vec2((float(i) - 1.0) * 0.4, sin(t * 6.0 + float(i)) * 0.12);
			shards += (1.0 - smoothstep(0.08, 0.11, diamond((p - c) * vec2(1.0, 0.55)))) * sin(t * 3.14159);
		}
		dark = 0.0; boundary = 0.0;
	}
	if (variant == 3) { // Rift: vertical aperture instead of circular implosion.
		float edge = abs(p.x) / max(opening * 0.45, 0.001) + abs(p.y) * 1.2;
		boundary = exp(-abs(edge - 1.0) * 20.0) * sin(t * 3.14159);
		dark = (1.0 - smoothstep(0.9, 1.0, edge)) * sin(t * 3.14159);
	}
	float a = clamp(dark + boundary + shards, 0.0, 1.0);
	COLOR = vec4(mix(vec3(0.008, 0.002, 0.02), accent.rgb, clamp(boundary + shards, 0.0, 1.0)), a) * COLOR;
}
