shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.32, 0.86, 0.88, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = clamp(progress, 0.0, 1.0);
	float a = 0.0;
	float fade = sin(t * 3.14159);
	if (variant == 0) { // Barrier: six shield panels close into a hexagonal shell.
		float d = max(abs(p.x) * 0.866 + abs(p.y) * 0.5, abs(p.y));
		float radius = mix(0.9, 0.58, smoothstep(0.0, 0.35, t));
		a = exp(-abs(d - radius) * 65.0) * fade;
		a += (1.0 - smoothstep(radius - 0.03, radius, d)) * 0.1 * fade;
	} else if (variant == 1) { // Chiseled ward plates assemble in staggered courses.
		float row = floor((p.y + 1.0) * 4.0);
		vec2 grid_uv = vec2((p.x + 1.0) * 3.0 + mod(row, 2.0) * 0.5, (p.y + 1.0) * 4.0);
		vec2 q = abs(fract(grid_uv) - 0.5);
		float plate = max(q.x * 0.85 + q.y * 0.25, q.y);
		float border = 1.0 - smoothstep(0.018, 0.055, abs(plate - 0.37));
		float delay = (7.0 - row) * 0.035;
		a = border * smoothstep(delay, delay + 0.08, t) * (1.0 - smoothstep(0.6, 1.0, t)) * (1.0 - smoothstep(0.55, 0.85, length(p)));
	} else if (variant == 2 || variant == 4 || variant == 5) { // Attunement, knowledge and echo: distinct orbital paths.
		for (int i = 0; i < 3; i++) {
			float angle = float(i) * 1.0472 + t * (variant == 5 ? -2.0 : 2.0);
			vec2 q = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * p;
			float ellipse = length(q * vec2(1.0, variant == 4 ? 4.0 : 2.3));
			a += exp(-abs(ellipse - 0.62 * (1.0 - t * 0.4)) * 55.0) * fade * 0.65;
		}
	} else if (variant == 7) { // Mend: paired leaf strokes climb around the wound.
		for (int i = 0; i < 3; i++) {
			float n = float(i);
			vec2 q = p - vec2(0.0, 0.5 - n * 0.28 - t * 0.42);
			float leaf = abs(abs(q.x) - 0.16 - q.y * 0.75);
			a += (1.0 - smoothstep(0.008, 0.032, leaf)) * (1.0 - smoothstep(0.04, 0.15, abs(q.y))) * fade;
		}
	} else { // Energy/adrenaline: upward ribbons or fast chevrons, never a radial burst.
		for (int i = 0; i < 5; i++) {
			float index = float(i);
			vec2 q = p - vec2((index - 2.0) * 0.23, 0.75 - t * 1.5 + sin(index * 2.0) * 0.2);
			float line = variant == 6 ? abs(q.y + abs(q.x) * 1.5) : abs(q.x + sin(q.y * 7.0 + index) * 0.03);
			a += exp(-line * 65.0) * (1.0 - smoothstep(0.08, variant == 6 ? 0.18 : 0.5, abs(q.y))) * fade;
		}
	}
	COLOR = vec4(mix(accent.rgb * 0.65, accent.rgb, clamp(a * 1.5, 0.0, 1.0)), clamp(a, 0.0, 0.85) * smoothstep(0.0, 0.04, t) * (1.0 - smoothstep(0.9, 1.0, t))) * COLOR;
}
