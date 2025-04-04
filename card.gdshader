shader_type spatial;

void vertex() {
	UV=vec2(133,23);
	// Called for every vertex the material is visible on.
}


uniform sampler2D albedo_texture;
uniform vec2 uv_scale = vec2(1.0, 1.0); // Controls how much the texture scales

void fragment() {
    vec2 uv = FRAGCOORD.xy;  // Scale the UVs for tiling or stretching
    vec4 tex_color = texture(albedo_texture, uv); 
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
}
//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
