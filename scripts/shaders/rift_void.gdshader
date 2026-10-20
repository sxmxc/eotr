shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 uv = SCREEN_UV - vec2(0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect / (1672.0 / 941.0);
	uv *= 0.96;
	uv += vec2(sin(TIME * 0.013), cos(TIME * 0.009)) * 0.003;
	COLOR = texture(TEXTURE, uv + vec2(0.5));
	COLOR.rgb *= 0.76;
}
