shader_type canvas_item;

// Breathe only the existing plum light inside the portal/obelisk silhouette.
uniform float energy : hint_range(0.0, 0.9) = 0.0;

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	float region = smoothstep(0.72, 0.77, UV.x) * (1.0 - smoothstep(0.82, 0.86, UV.x));
	float magic = smoothstep(0.08, 0.28, paint.r - paint.g) * smoothstep(0.04, 0.18, paint.b - paint.g);
	COLOR.rgb *= 1.0 + energy * magic * region;
}
