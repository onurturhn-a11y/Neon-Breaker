shader_type canvas_item;

// Source sheets contain a dark presentation background. Keep the artwork while
// fading only the near-black sheet background out of the runtime sprite.
uniform float dark_cutoff = 0.025;
uniform float edge_softness = 0.075;

void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float brightness = max(sample_color.r, max(sample_color.g, sample_color.b));
	float background_mask = smoothstep(dark_cutoff, dark_cutoff + edge_softness, brightness);
	COLOR = vec4(sample_color.rgb, sample_color.a * background_mask) * COLOR;
}
