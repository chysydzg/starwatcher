shader_type canvas_item;
// Odbicie w jeziorze dla obiektów dorysowanych na tło balkonu (obserwatorium, żuraw, wywrotka).
// Rysowane do góry nogami pod linią brzegu, tylko na wodzie między brzegiem a balustradą: przeszklone
// (półprzezroczyste), rozmazane w pionie (smużenie) i falujące rzędami o całe piksele, jak w Kingdom.

uniform float clip_top = 214.0;      // pierwszy rząd wody (pod piaskiem)
uniform float clip_bottom = 261.0;   // tuż nad poręczą balustrady
uniform float clip_left = 78.0;      // na lewo jest ściana z drzwiami
uniform vec3 tint = vec3(0.11, 0.15, 0.3);
uniform float strength = 0.55;

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
	// fale: płynne, dwa nałożone przebiegi; przesunięcie o całe piksele, dalej od brzegu większe
	float wave = sin(p.y * 0.35 - TIME * 1.6) * 0.6 + sin(p.y * 0.9 + TIME * 2.6) * 0.4;
	vec2 uv = UV + vec2(floor(wave * (0.6 + 2.2 * d) + 0.5) * TEXTURE_PIXEL_SIZE.x, 0.0);
	// smużenie: kilka próbek w pionie zlanych w jedną – odbicie rozmazane jak w szkle wody, bez dziur
	vec4 acc = vec4(0.0);
	float wsum = 0.0;
	for (int k = -2; k <= 3; k++) {
		float w = 1.0 / (1.0 + abs(float(k)));
		vec4 s = texture(TEXTURE, uv + vec2(0.0, float(k) * (1.0 + 1.5 * d) * TEXTURE_PIXEL_SIZE.y));
		acc += vec4(s.rgb * s.a, s.a) * w;
		wsum += w;
	}
	acc /= wsum;
	if (acc.a < 0.01) {
		discard;
	}
	vec3 rgb = acc.rgb / acc.a * COLOR.rgb;
	float shine = 0.08 * step(0.92, sin(p.y * 1.7 + TIME * 3.0 + p.x * 0.02));  // jasna zmarszczka przesuwa się po odbiciu
	COLOR = vec4(mix(rgb * vec3(0.62, 0.7, 0.9), tint, 0.25 + 0.3 * d) + shine, acc.a * strength * (1.0 - 0.55 * d));
}
