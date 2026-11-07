shader_type canvas_item;
// Bardzo subtelny efekt CRT (GDD 21): linie skanowania 5% i lekkie przyciemnienie przy brzegu.
// Bez zakrzywiania obrazu: przesunięcie o ułamek piksela gubiło outline i wyginało proste krawędzie pixel artu.
uniform sampler2D screen: hint_screen_texture, filter_nearest;
void fragment() {
	vec3 col = texture(screen, SCREEN_UV).rgb;
	float line = 0.95 + 0.05 * step(0.5, fract(FRAGCOORD.y / 2.0));
	vec2 c = SCREEN_UV - 0.5;
	float edge = 1.0 - 0.12 * smoothstep(0.3, 0.5, max(abs(c.x), abs(c.y)));
	COLOR = vec4(col * line * edge, 1.0);
}
