shader_type canvas_item;
render_mode unshaded;
varying vec2 world_position;
varying vec4 tint;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	tint = COLOR;
}
void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	// Broad, quiet pigment variation; no procedural grain or gameplay randomness.
	float weathering = sin(world_position.x * 0.013 + world_position.y * 0.009) * 0.035;
	stone.rgb *= 1.0 + weathering;
	// Only plum pigment receives a low-frequency crack-light breath.
	float plum = smoothstep(0.025, 0.10, stone.r - stone.g) * smoothstep(0.02, 0.08, stone.b - stone.g);
	float pulse = 0.035 + 0.025 * sin(TIME * 1.7 + world_position.y * 0.018);
	stone.rgb += vec3(0.65, 0.12, 0.43) * plum * pulse;
	COLOR = stone * tint;
}
