shader_type canvas_item;
render_mode unshaded;
uniform float burst : hint_range(0.0, 1.0) = 0.0;
uniform vec4 accent : source_color = vec4(0.25, 0.85, 1.0, 1.0);
void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.2, 3.0);
	float r = length(p);
	float angle = atan(p.y, p.x);
	float orbit = 0.58 + 0.025 * sin(angle * 3.0 + TIME * 2.0);
	float ring = exp(-abs(r - orbit) * 52.0);
	float ribbon = exp(-abs(r - (0.45 + 0.08 * sin(angle * 2.0 - TIME * 2.8))) * 42.0);
	float arc = pow(0.5 + 0.5 * sin(angle * 2.0 + TIME * 2.4), 3.0);
	float well = exp(-r * r * 8.0) * 0.48;
	float flare = exp(-abs(r - (0.25 + burst * 0.7)) * 15.0) * burst;
	vec3 color = mix(vec3(0.045, 0.012, 0.12), accent.rgb, clamp(ring + ribbon + flare, 0.0, 1.0));
	color += accent.rgb * (ring * 0.6 + flare);
	COLOR = vec4(color, clamp(well + ring * (0.45 + arc * 0.45) + ribbon * 0.55 + flare, 0.0, 0.95)) * COLOR;
}
