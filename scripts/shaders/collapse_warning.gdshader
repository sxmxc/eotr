shader_type canvas_item;
render_mode unshaded;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float breath = 0.68 + 0.15 * sin(TIME * 2.6);
	float fracture = smoothstep(-0.75, -0.4, sin(world_position.x * 0.26 + world_position.y * 0.15));
	COLOR *= vec4(vec3(1.0), breath * mix(0.22, 1.0, fracture));
}
