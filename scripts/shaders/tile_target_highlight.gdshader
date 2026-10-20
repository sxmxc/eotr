shader_type canvas_item;
render_mode unshaded;
uniform vec4 HighlightColor : source_color = vec4(0.4, 0.85, 0.78, 1.0);
uniform float PulseSpeed = 1.35;
uniform float MinAlpha = 0.1;
uniform float MaxAlpha = 0.3;
uniform float OutlineWidth = 0.045;
uniform float HexSize = 64.0;
varying vec4 canvas_modulation;
void vertex() {
	canvas_modulation = COLOR;
}
void fragment() {
	// Use the actual atlas silhouette for both Sprite2D and batched TileMapLayer
	// vertices. Neither world vertices nor atlas UVs are local 0..1 tile space.
	float inside = smoothstep(0.25, 0.75, texture(TEXTURE, UV).a);
	vec2 px = TEXTURE_PIXEL_SIZE * max(OutlineWidth * HexSize, 1.0);
	float inner = min(min(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a), min(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
	float border = inside * (1.0 - smoothstep(0.3, 0.9, inner));
	float fill = mix(MinAlpha, MaxAlpha, 0.5 + 0.5 * sin(TIME * PulseSpeed));
	COLOR = vec4(HighlightColor.rgb, (fill * inside + (0.85 - fill) * border) * HighlightColor.a) * canvas_modulation;
}
