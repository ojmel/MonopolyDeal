shader_type spatial;

uniform sampler2D fur_texture;
uniform float fur_length = 100;  // Controls how far the fur sticks out
uniform int fur_layers = 2000;     // Number of fur layers for depth
uniform vec4 fur_color = vec4(0.0, 0.0, 0.0, 1.0);
void vertex() {
    // Calculate the offset for each layer
    float layer_factor = float(INSTANCE_CUSTOM.x) / float(fur_layers);
    VERTEX -= NORMAL * fur_length * layer_factor;  // Displace vertices along normals
}

void fragment() {
    // Sample the texture
    vec4 base_color = texture(fur_texture, UV);

    // Blend the fur color with the base color
    ALBEDO = fur_color.rgb;

    // Make outer layers more transparent for a fading fur effect
    float alpha_factor = 1.0 - (float(4) / float(fur_layers));
    ALPHA = base_color.a * alpha_factor;

    // Enable transparency
    if (ALPHA < 0.1) {
        discard;
    }
}


//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
