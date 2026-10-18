shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.25, 0.8, 0.78, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.0, 3.4);
	float r = length(p);
	float shadow = (1.0 - smoothstep(0.3, 1.02, r)) * 0.65;
	float halo = exp(-r * r * 3.5) * 0.2;
	float ring = (1.0 - smoothstep(0.016, 0.045, abs(r - 0.78))) * 0.5;
	float pulse = 0.9 + 0.1 * sin(TIME * 2.0);
	vec3 rgb = mix(vec3(0.008, 0.012, 0.02), accent.rgb, clamp((ring + halo) * pulse, 0.0, 1.0));
	COLOR = vec4(rgb, max(shadow, ring * 0.7)) * COLOR;
}
