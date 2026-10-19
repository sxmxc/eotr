shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.8, 0.55, 1.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 pigment = texture(TEXTURE, UV);
	float light = max(pigment.r, max(pigment.g, pigment.b));
	float saturation = light - min(pigment.r, min(pigment.g, pigment.b));
	vec3 color = accent.rgb * mix(0.18, 1.0, light);
	color = mix(color, vec3(1.0, 0.96, 0.82), smoothstep(0.65, 0.95, light) * (1.0 - smoothstep(0.1, 0.45, saturation)));
	COLOR = vec4(mix(pigment.rgb, color, strength), pigment.a) * tint;
}
