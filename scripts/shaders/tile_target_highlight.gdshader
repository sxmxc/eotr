shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// Lost Century-friendly accent that won't blend with resource yellows.
uniform vec4 HighlightColor : source_color = vec4(0.52, 0.33, 0.54, 1.0);
uniform float PulseSpeed : hint_range(0.1, 5.0) = 1.35;
uniform float MinAlpha : hint_range(0.0, 1.0) = 0.02;
uniform float MaxAlpha : hint_range(0.0, 1.0) = 0.8;
uniform float EdgeFeather : hint_range(0.0, 0.2) = 0.06;

void fragment() {
	// Use the sprite's texture alpha (hex mask).
	float mask = texture(TEXTURE, UV).a;

	// Feathered edge based on alpha.
	float fw = fwidth(mask);
	float edge_mask = smoothstep(0.0, EdgeFeather + fw, mask) * (1.0 - smoothstep(1.0 - (EdgeFeather + fw), 1.0, mask));

	float pulse = sin(TIME * PulseSpeed) * 0.5 + 0.5; // 0..1
	float base_alpha = mix(MinAlpha, MaxAlpha, pulse) * mask;
	float alpha = max(base_alpha, edge_mask * (MaxAlpha * 0.65));

	COLOR = vec4(HighlightColor.rgb, 1.0) * alpha;
}
