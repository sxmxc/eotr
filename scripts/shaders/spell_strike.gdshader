shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.65, 0.95, 1.0, 1.0);
float stroke(vec2 p, float slope, float width) {
	return (1.0 - smoothstep(width, width + 0.025, abs(p.y - p.x * slope))) * (1.0 - smoothstep(0.6, 0.95, abs(p.x)));
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = progress;
	float a = 0.0;
	if (variant == 0) { // Jab: narrow punch line and four blunt impact wedges.
		a = stroke(p - vec2(mix(-0.35, 0.25, t), 0.0), 0.0, 0.055) * (1.0 - t);
		a += exp(-length(p * vec2(1.0, 0.7)) * 14.0) * (1.0 - t);
	} else if (variant == 1) { // Chrono: crossing strikes with separated delayed clock ticks.
		a = stroke(p, 0.65, 0.025) * (1.0 - t);
		a += stroke(p, -0.65, 0.025) * smoothstep(0.15, 0.3, t) * (1.0 - t);
		float angle = atan(p.y, p.x);
		a += pow(abs(cos(angle * 6.0)), 24.0) * exp(-abs(length(p) - 0.62) * 70.0) * sin(t * 3.14159);
	} else if (variant == 2) { // Phase: long diagonal cut with two displaced afterimages.
		a = stroke(p, -0.8, 0.022) * (1.0 - t);
		a += (stroke(p + vec2(0.0, t * 0.22), -0.8, 0.012) + stroke(p - vec2(0.0, t * 0.22), -0.8, 0.012)) * (1.0 - t) * 0.5;
	} else if (variant == 3) { // Sever: vertical break with escaping gold fragments.
		a = exp(-abs(p.x + sin(p.y * 18.0) * 0.025) * 85.0) * (1.0 - smoothstep(0.5, 0.95, abs(p.y))) * (1.0 - t);
		vec2 q = vec2(abs(p.x) - t * 0.55, p.y);
		a += exp(-abs(q.x) * 60.0) * pow(max(0.0, cos(q.y * 28.0)), 12.0) * (1.0 - t);
	} else { // Overload / diminishing returns: angular spokes, not a curved bolt.
		float angle = atan(p.y, p.x);
		float spokes = pow(max(0.0, cos(angle * (variant == 4 ? 5.0 : 9.0))), 18.0);
		a = spokes * exp(-abs(length(p) - t * 0.85) * 18.0) * (1.0 - t);
		a += exp(-length(p) * 18.0) * (1.0 - t);
	}
	COLOR = vec4(mix(accent.rgb, vec3(1.0), clamp(a - 0.5, 0.0, 0.5)), clamp(a, 0.0, 1.0)) * COLOR;
}
