shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform int variant = 0;
uniform vec4 accent : source_color = vec4(0.32, 0.86, 0.88, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = progress;
	float a = 0.0;
	float fade = sin(t * 3.14159);
	if (variant == 0) { // Barrier: six shield panels close into a hexagonal shell.
		float d = max(abs(p.x) * 0.866 + abs(p.y) * 0.5, abs(p.y));
		float radius = mix(0.9, 0.58, smoothstep(0.0, 0.35, t));
		a = exp(-abs(d - radius) * 65.0) * fade;
		a += (1.0 - smoothstep(radius - 0.03, radius, d)) * 0.1 * fade;
	} else if (variant == 1) { // Nano: staggered square cells assemble from bottom to top.
		vec2 grid = floor((p + 1.0) * 4.0);
		vec2 q = fract((p + 1.0) * 4.0) - 0.5;
		float border = exp(-abs(max(abs(q.x), abs(q.y)) - 0.36) * 40.0);
		float delay = (7.0 - grid.y) * 0.045 + mod(grid.x, 2.0) * 0.04;
		a = border * smoothstep(delay, delay + 0.08, t) * (1.0 - smoothstep(0.6, 1.0, t)) * (1.0 - smoothstep(0.55, 0.85, length(p)));
	} else if (variant == 2 || variant == 4 || variant == 5) { // Attunement, knowledge and echo: distinct orbital paths.
		for (int i = 0; i < 3; i++) {
			float angle = float(i) * 1.0472 + t * (variant == 5 ? -2.0 : 2.0);
			vec2 q = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * p;
			float ellipse = length(q * vec2(1.0, variant == 4 ? 4.0 : 2.3));
			a += exp(-abs(ellipse - 0.62 * (1.0 - t * 0.4)) * 55.0) * fade * 0.65;
		}
	} else { // Energy/adrenaline: upward ribbons or fast chevrons, never a radial burst.
		for (int i = 0; i < 5; i++) {
			float index = float(i);
			vec2 q = p - vec2((index - 2.0) * 0.23, 0.75 - t * 1.5 + sin(index * 2.0) * 0.2);
			float line = variant == 6 ? abs(q.y + abs(q.x) * 1.5) : abs(q.x + sin(q.y * 7.0 + index) * 0.03);
			a += exp(-line * 65.0) * (1.0 - smoothstep(0.08, variant == 6 ? 0.18 : 0.5, abs(q.y))) * fade;
		}
	}
	COLOR = vec4(accent.rgb, clamp(a, 0.0, 0.95)) * COLOR;
}
