shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.24, 0.85, 1.0, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float t = progress;
	float angle = atan(p.y, p.x);
	float radius = mix(0.08, 0.9, 1.0 - pow(1.0 - t, 3.0));
	float ring = exp(-abs(r - radius) * 50.0) * (1.0 - t);
	float second = exp(-abs(r - radius * 0.6) * 70.0) * (1.0 - t) * 0.55;
	float rays = pow(max(0.0, cos(angle * 11.0 + r * 4.0)), 24.0) * exp(-abs(r - t * 0.95) * 14.0) * (1.0 - t);
	float core = exp(-r * r * 35.0) * pow(1.0 - t, 3.0);
	if (variant == 1) { // Fracture pulse: radial cracks, interrupted ring and gold center.
		ring *= step(0.15, sin(angle * 7.0));
		rays += pow(max(0.0, cos(angle * 7.0 + sin(r * 35.0) * 0.3)), 35.0) * (1.0 - smoothstep(t * 0.7, t * 0.7 + 0.12, r)) * (1.0 - t);
	}
	if (variant == 2) { ring *= 0.4; core *= 1.8; rays *= 1.4; }
	float a = ring + second + rays + core;
	COLOR = vec4(mix(accent.rgb, vec3(1.0, 0.94, 0.65), core), clamp(a, 0.0, 1.0)) * COLOR;
}
