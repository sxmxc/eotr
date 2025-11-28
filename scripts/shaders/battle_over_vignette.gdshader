shader_type canvas_item;
render_mode unshaded;

uniform float radius : hint_range(0.0, 1.5) = 0.75;
uniform float softness : hint_range(0.0, 1.0) = 0.35;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
uniform float noise_amount : hint_range(0.0, 1.0) = 0.05;
uniform float noise_speed : hint_range(0.0, 10.0) = 2.0;

// Simple hash-based noise for subtle motion in the vignette edge.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Compensate for aspect so the vignette remains circular.
	vec2 centered = uv - vec2(0.5);
	centered.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float dist = length(centered);

	float edge = smoothstep(radius, radius - softness, dist);

	float t = TIME * noise_speed;
	float n = hash(floor(uv * vec2(640.0, 360.0) + t));
	n = (n - 0.5) * 2.0; // range [-1, 1]

	float noisy_edge = clamp(edge * (1.0 + n * noise_amount), 0.0, 1.0);

	COLOR = vignette_color;
	COLOR.a *= noisy_edge;
}
