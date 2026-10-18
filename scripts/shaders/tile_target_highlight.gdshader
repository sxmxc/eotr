shader_type canvas_item;
render_mode unshaded;
uniform vec4 HighlightColor : source_color = vec4(0.4, 0.85, 0.78, 1.0);
uniform float PulseSpeed = 1.35;
uniform float MinAlpha = 0.1;
uniform float MaxAlpha = 0.3;
uniform float OutlineWidth = 0.045;
varying vec2 tile_uv;
void vertex() {
	// Atlas UVs address the sheet; the hex distance needs the local 32px quad.
	tile_uv = VERTEX / 32.0 + vec2(0.5);
}
void fragment() {
	vec2 p = abs(tile_uv - vec2(0.5));
	float distance = max(p.x, p.x * 0.5 + p.y * 0.8660254) - 0.43;
	float inside = 1.0 - smoothstep(0.0, 0.012, distance);
	float border = inside * smoothstep(-OutlineWidth, -OutlineWidth + 0.012, distance);
	float pulse = 0.85 + 0.15 * sin(TIME * PulseSpeed);
	COLOR = vec4(HighlightColor.rgb, (0.09 * inside + 0.72 * border) * pulse);
}
