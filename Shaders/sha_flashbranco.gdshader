
shader_type canvas_item;

uniform float intensidade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 cor_original = texture(TEXTURE, UV);
	vec3 cor_rgb = mix(cor_original.rgb, vec3(1.0), intensidade);
	vec4 cor_saida = vec4(cor_rgb, cor_original.a);

	COLOR = cor_saida;
}
