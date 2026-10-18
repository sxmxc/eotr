shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.025, 0.045, 0.065, 1.0);
uniform vec4 rim_color : source_color = vec4(0.48, 0.85, 0.84, 0.65);
uniform float outline_pixels = 7.0;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * outline_pixels;
	float surround = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		surround = max(surround, texture(TEXTURE, UV + vec2(cos(angle), sin(angle)) * step_uv).a);
	}
	float inner = texture(TEXTURE, UV + vec2(-1.0, -1.0) * step_uv * 0.65).a;
	vec3 pigment = mix(tex.rgb, rim_color.rgb, (1.0 - inner) * rim_color.a * 0.55);
	pigment = mix(pigment, vec3(1.0), hit_flash);
	float edge = max(0.0, surround - tex.a);
	vec3 rgb = mix(outline_color.rgb, pigment, tex.a);
	COLOR = vec4(rgb * tint.rgb, max(tex.a, edge * outline_color.a) * tint.a);
}
