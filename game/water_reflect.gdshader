shader_type canvas_item;
// Odbicie w jeziorze dla obiektów dorysowanych na tło balkonu (obserwatorium, żuraw, wywrotka).
// Rysowane do góry nogami pod linią brzegu; fale przesuwają rzędy o całe piksele, przezroczystość
// przez dither (bez półprzezroczystych pikseli), tylko na wodzie między brzegiem a balustradą.

uniform float clip_top = 214.0;      // pierwszy rząd wody (pod piaskiem)
uniform float clip_bottom = 261.0;   // tuż nad poręczą balustrady
uniform float clip_left = 78.0;      // na lewo jest ściana z drzwiami
uniform vec3 tint = vec3(0.11, 0.15, 0.3);
uniform float strength = 0.7;

varying vec2 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(wp);
	if (p.y < clip_top || p.y > clip_bottom || p.x < clip_left) {
		discard;
	}
	float d = clamp((p.y - clip_top) / (clip_bottom - clip_top), 0.0, 1.0);
	float off = floor(sin(p.y * 0.8 + TIME * 2.3) * (0.6 + 1.6 * d) + 0.5);  // fala: całe piksele, dalej od brzegu mocniej
	vec4 c = texture(TEXTURE, UV + vec2(off * TEXTURE_PIXEL_SIZE.x, 0.0)) * COLOR;
	float a = c.a * strength * (1.0 - 0.65 * d);
	if (mod(p.y + floor(TIME * 2.0 + p.x * 0.07), 6.0) < 1.0) {
		a *= 0.35;  // jaśniejsze pasma zmarszczek przerywają odbicie
	}
	float bayer = (mod(p.x, 2.0) * 2.0 + mod(p.y + floor(mod(p.x, 4.0) / 2.0), 2.0) + 0.5) / 4.0;
	if (a < bayer) {
		discard;
	}
	COLOR = vec4(mix(c.rgb * vec3(0.55, 0.62, 0.85), tint, 0.3 + 0.3 * d), 1.0);
}
