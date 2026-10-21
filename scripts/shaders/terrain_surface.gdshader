shader_type canvas_item;
render_mode unshaded;
varying vec2 world_position;
varying vec4 tint;
float pigment(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	float a = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(cell + vec2(1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	tint = COLOR;
}
void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	// Broad, quiet pigment variation; no procedural grain or gameplay randomness.
	float weathering = pigment(world_position * 0.018);
	float deposits = pigment(world_position * 0.055 + vec2(7.0));
	stone.rgb *= mix(0.83, 1.08, weathering) * mix(0.96, 1.02, deposits);
	// Broad mineral staining sits inside the painted material, never on its alpha.
	stone.rgb = mix(stone.rgb, stone.rgb * vec3(1.08, 1.01, 0.90), smoothstep(0.5, 0.9, deposits) * 0.32);
	// Only plum pigment receives a low-frequency crack-light breath.
	float plum = smoothstep(0.025, 0.10, stone.r - stone.g) * smoothstep(0.02, 0.08, stone.b - stone.g);
	float pulse = 0.035 + 0.025 * sin(TIME * 1.7 + world_position.y * 0.018);
	stone.rgb += vec3(0.65, 0.12, 0.43) * plum * pulse;
	COLOR = stone * tint;
}
