shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.65, 0.83, 0.25, 1.0);
float line_distance(vec2 p, vec2 a, vec2 b) {
	vec2 v = b - a;
	return length(p - a - v * clamp(dot(p - a, v) / max(dot(v, v), 0.00001), 0.0, 1.0));
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = clamp(progress, 0.0, 1.0);
	float r = length(p);
	float angle = atan(p.y, p.x);
	float growth = smoothstep(0.02, 0.6, t);
	float cracks = 0.0;
	float ink = 0.0;
	// Deliberate capillaries split once; no arbitrary polar sine web.
	for (int i = 0; i < 5; i++) {
		float a = float(i) * 1.2566 + 0.4;
		vec2 dir = vec2(cos(a), sin(a));
		vec2 side = vec2(-dir.y, dir.x);
		vec2 joint = dir * 0.3 + side * 0.07;
		vec2 tip = dir * (0.6 + 0.09 * sin(float(i) * 3.0));
		float d = min(line_distance(p, vec2(0.0), joint * min(growth * 2.0, 1.0)), line_distance(p, joint, mix(joint, tip, max(growth * 2.0 - 1.0, 0.0))));
		d = min(d, line_distance(p, joint, joint + (dir * 0.18 - side * 0.2) * max(growth * 2.0 - 1.0, 0.0)));
		cracks = max(cracks, 1.0 - smoothstep(0.005, 0.018, d));
		ink = max(ink, 1.0 - smoothstep(0.02, 0.05, d));
	}
	float drops = 0.0;
	for (int i = 0; i < 5; i++) {
		float index = float(i);
		vec2 center = vec2(sin(index * 7.0) * 0.55, -0.3 + t * 0.75 - index * 0.09);
		drops += exp(-length((p - center) * vec2(1.0, 0.5)) * 65.0);
	}
	float pool = (1.0 - smoothstep(0.2, 0.55, length(p * vec2(1.0, 2.0)))) * 0.15;
	float a = (ink * (variant == 1 ? 0.8 : 0.5) + drops + pool * 0.35) * smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.55, 1.0, t));
	COLOR = vec4(mix(vec3(0.11, 0.07, 0.13), accent.rgb, clamp(cracks * 0.85 + drops, 0.0, 1.0)), clamp(a, 0.0, 0.88)) * COLOR;
}
