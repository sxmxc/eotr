shader_type canvas_item;

uniform float outerRadius : hint_range(0.0, 5.0) = 1.0;
uniform float MainAlpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 vignette_color: source_color;

void fragment() {
	float x = abs(UV.x-.5)*2.0;
	float y = abs(UV.y-.5)*2.0;
	float v = clamp(length(vec2(x,y)) / max(outerRadius, 0.001), 0.0, 1.0);
	COLOR = vec4(vignette_color.rgb,v*MainAlpha*vignette_color.a) * COLOR;
}
