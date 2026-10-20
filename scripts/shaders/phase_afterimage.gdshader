shader_type canvas_item;
render_mode unshaded;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float row = floor(UV.y * 36.0);
	float breakup = fract(sin(row * 65.18) * 4358.13);
	float keep = 1.0 - smoothstep(0.2 + breakup * 0.5, 0.4 + breakup * 0.5, dissolve);
	vec3 pigment = mix(ink.rgb * vec3(0.45, 0.85, 0.95), vec3(0.2, 0.7, 0.75), 0.22);
	COLOR = vec4(pigment * tint.rgb, ink.a * tint.a * keep * (1.0 - dissolve));
}
