shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float glow = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		glow += texture(TEXTURE, UV + vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * 5.0).a;
	}
	glow = max(0.0, glow / 8.0 - tex.a);
	vec3 light = mix(tex.rgb, vec3(0.6, 0.85, 1.0), 0.2);
	vec3 rgb = mix(light * 0.75, tex.rgb * 1.25, tex.a);
	COLOR = vec4(rgb * tint.rgb, max(tex.a, glow * 0.45) * tint.a);
}
