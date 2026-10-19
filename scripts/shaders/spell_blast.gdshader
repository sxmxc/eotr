shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.24, 0.85, 1.0, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float t = clamp(progress, 0.0, 1.0);
	float release = smoothstep(0.0, 0.08, t);
	float fade = 1.0 - smoothstep(0.45, 1.0, t);
	float angle = atan(p.y, p.x);
	float radius = mix(0.08, 0.9, 1.0 - pow(1.0 - t, 3.0));
	// Angular pressure facets with gaps, not stacked circular rings.
	float facets = 0.86 + 0.08 * cos(angle * 6.0) + 0.04 * cos(angle * 3.0 + 0.8);
	float front = abs(r * facets - radius * 0.85);
	float gaps = smoothstep(-0.65, 0.3, cos(angle * 5.0 + 1.0));
	float ring = (1.0 - smoothstep(0.012, 0.04, front)) * gaps * fade;
	float second = (1.0 - smoothstep(0.0, 0.013, front)) * gaps * fade * 0.35;
	float rays = pow(max(0.0, cos(angle * 7.0 + 0.4)), 30.0) * exp(-abs(r - t * 0.95) * 22.0) * fade;
	float core = exp(-r * r * 35.0) * pow(1.0 - t, 3.0);
	if (variant == 1) { // Fracture pulse: radial cracks, interrupted ring and gold center.
		ring *= step(0.15, sin(angle * 7.0));
		rays += pow(max(0.0, cos(angle * 7.0 + sin(r * 35.0) * 0.3)), 35.0) * (1.0 - smoothstep(t * 0.7, t * 0.7 + 0.12, r)) * (1.0 - t);
	}
	if (variant == 2) { ring *= 0.4; core *= 1.8; rays *= 1.4; }
	float a = (ring + second + rays + core) * release;
	COLOR = vec4(mix(accent.rgb * 0.85, vec3(0.94, 0.98, 1.0), clamp(core + second, 0.0, 1.0)), clamp(a, 0.0, 0.95)) * COLOR;
}
