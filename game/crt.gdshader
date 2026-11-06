shader_type canvas_item;
// Bardzo subtelny efekt CRT (GDD 21): linie skanowania 5%, lekkie zakrzywienie przy krawędziach, bez aberracji.
uniform sampler2D screen: hint_screen_texture, filter_nearest;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	uv += c * dot(c, c) * 0.02;
	vec3 col = texture(screen, uv).rgb;
	float line = 0.95 + 0.05 * step(0.5, fract(FRAGCOORD.y / 2.0));
	float edge = smoothstep(0.52, 0.48, max(abs(c.x), abs(c.y)) + dot(c, c) * 0.02);
	COLOR = vec4(col * line * edge, 1.0);
}
