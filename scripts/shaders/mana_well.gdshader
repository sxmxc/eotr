shader_type canvas_item;
render_mode unshaded;

float stroke(vec2 p, vec2 a, vec2 b, float width) {
	vec2 edge = b - a;
	float t = clamp(dot(p - a, edge) / dot(edge, edge), 0.0, 1.0);
	return 1.0 - smoothstep(width, width + 0.55, length(p - a - edge * t));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 64.0;
	float hex = max(abs(p.x) / 29.0, (abs(p.y) + abs(p.x) * 0.5) / 29.0);
	float mask = 1.0 - smoothstep(0.98, 1.0, hex);
	float r = length(p / vec2(22.0, 14.0));
	float breath = 0.5 + 0.5 * sin(TIME * 1.5);
	float pool = 1.0 - smoothstep(0.79, 0.91, r);
	float rim = exp(-abs(r - 1.0) * 42.0);
	float lip = exp(-abs(r - 0.79) * 50.0);
	float ripples = pow(0.5 + 0.5 * sin(r * 24.0 - TIME * 1.8), 8.0) * pool;
	float hex_rim = smoothstep(0.93, 0.96, hex) * mask;
	vec3 stone = vec3(0.11, 0.10, 0.21);
	vec3 water = mix(vec3(0.12, 0.07, 0.30), vec3(0.25, 0.29, 0.57), clamp(1.0 - r, 0.0, 1.0));
	vec3 color = mix(stone, water, pool);
	color += vec3(0.22, 0.31, 0.55) * ripples * (0.10 + breath * 0.05);
	color = mix(color, vec3(0.64, 0.59, 0.91), rim * 0.85 + hex_rim * 0.65);
	color += vec3(0.20, 0.30, 0.49) * lip * 0.6;
	// Edge runes remain visible beneath an occupying unit.
	float bolt = max(stroke(p, vec2(1.5, 16.5), vec2(-3.5, 22.0), 0.65), stroke(p, vec2(-3.5, 22.0), vec2(3.0, 21.0), 0.65));
	bolt = max(bolt, stroke(p, vec2(3.0, 21.0), vec2(-1.0, 27.0), 0.65));
	vec2 side = vec2(abs(p.x) - 25.0, p.y);
	float diamond = 1.0 - smoothstep(1.5, 2.2, abs(side.x) + abs(side.y));
	color = mix(color, vec3(0.79, 0.85, 1.0), max(bolt, diamond));
	COLOR = vec4(color, mask) * COLOR;
}
