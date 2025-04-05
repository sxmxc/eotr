shader_type canvas_item;

const int MAX_HEXES = 64;
uniform int num_active_hexes;
uniform vec2 active_hex_centers[MAX_HEXES];

uniform vec2 hex_size = vec2(120.0, 140.0);
uniform vec2 grid_offset = vec2(0.0, 0.0);
uniform float q_scaling = 1.49;
varying vec2 frag_pos;

void vertex() {
    frag_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // Flag to determine if the current fragment is within any hexagon
    bool insideHex = false;
    for (int i = 0; i < num_active_hexes; i++) {
        // Use grid_offset if needed (for overall grid positioning)
        vec2 hex_center = active_hex_centers[i] + grid_offset;
        vec2 delta = frag_pos - hex_center;

        // Convert to hexagonal cube coordinates with scaling adjustment
        float q = delta.x / (hex_size.x * 0.75) * q_scaling;
        float r = (delta.y - (delta.x / sqrt(3.0))) / (hex_size.y / 2.0);
        float s = -q - r;

        // Check if the fragment is within the hexagon
        float max_distance = max(max(abs(q), abs(r)), abs(s));
        if (max_distance <= 1.0) {
            insideHex = true;
            break;
        }
    }

    vec4 texture_color = texture(TEXTURE, UV);

    // Discard fragments with low alpha
    if (texture_color.a < 0.1) {
        discard;
    }

    // Apply a fixed red highlight mix if inside any hex
    if (insideHex) {
        COLOR = mix(texture_color, vec4(1.0, 0.0, 0.0, 1.0), 0.5);
    } else {
        COLOR = texture_color;
    }
}