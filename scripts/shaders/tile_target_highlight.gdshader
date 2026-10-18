shader_type canvas_item;
render_mode unshaded;
uniform vec4 HighlightColor : source_color = vec4(0.4, 0.85, 0.78, 1.0);
uniform float PulseSpeed = 1.35;
uniform float MinAlpha = 0.1;
uniform float MaxAlpha = 0.3;
uniform float OutlineWidth = 0.045;
varying vec2 tile_uv;
varying vec4 canvas_modulation;
void vertex() {
	// Atlas UVs address the sheet; the hex distance needs the local 32px quad.
	tile_uv = VERTEX / 32.0 + vec2(0.5);
	canvas_modulation = COLOR;
}
void fragment() {
	vec2 p = abs(tile_uv - vec2(0.5));
	// The 32 x 32 board hex has vertices (0,+/-16), (+/-16,+/-8).
	float distance = max(p.x, p.x * 0.5 + p.y) - 0.48;
	float inside = 1.0 - smoothstep(0.0, 0.012, distance);
	float border = inside * smoothstep(-OutlineWidth, -OutlineWidth + 0.012, distance);
	float fill = mix(MinAlpha, MaxAlpha, 0.5 + 0.5 * sin(TIME * PulseSpeed));
	COLOR = vec4(HighlightColor.rgb, (fill * inside + (1.0 - fill) * border) * HighlightColor.a) * canvas_modulation;
}
