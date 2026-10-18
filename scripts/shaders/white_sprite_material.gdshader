shader_type canvas_item;
varying vec4 flash_modulation;

void vertex() {
	flash_modulation = COLOR;
}

void fragment() {
	// Incoming COLOR already includes texture alpha and CanvasItem fading.
	COLOR.rgb = flash_modulation.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
