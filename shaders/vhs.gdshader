shader_type canvas_item;
// Filtr VHS / CRT nakładany na cały ekran (ColorRect w CanvasLayer).
// Parametry do zabawy w Inspectorze (ShaderMaterial).

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.12;
uniform float aberration : hint_range(0.0, 3.0) = 0.6;   // przesunięcie kanałów RGB w pikselach
uniform float noise_strength : hint_range(0.0, 1.0) = 0.04;
uniform float wobble : hint_range(0.0, 3.0) = 0.5;       // drżenie linii w pikselach
uniform float roll_strength : hint_range(0.0, 1.0) = 0.35; // przesuwający się pas zakłóceń
uniform float vignette : hint_range(0.0, 1.0) = 0.3;
uniform float bleed : hint_range(0.0, 1.0) = 0.2;       // rozmycie koloru w poziomie
uniform vec2 resolution = vec2(384.0, 216.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	vec2 px = 1.0 / resolution;
	float line = floor(uv.y * resolution.y);

	// drżenie poszczególnych linii
	float wob = (hash(vec2(line, floor(t * 14.0))) - 0.5) * wobble * px.x;
	// pas zakłóceń przesuwający się z dołu do góry
	float band_pos = fract(uv.y + t * 0.07);
	float band = smoothstep(0.0, 0.06, abs(band_pos - 0.5));
	float roll = (1.0 - band) * roll_strength * 4.0 * px.x * hash(vec2(line, 3.0));
	uv.x += (wob + roll) * intensity;

	// aberracja chromatyczna
	float ab = aberration * px.x * intensity;
	float r = texture(screen_tex, uv + vec2(ab, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(ab, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// poziome "rozlewanie" koloru jak na taśmie
	vec3 left = texture(screen_tex, uv - vec2(px.x, 0.0)).rgb;
	col = mix(col, (col + left) * 0.5, bleed * intensity);

	// scanlines (co druga linia ciemniejsza)
	float scan = (mod(line, 2.0) < 1.0) ? 1.0 : 1.0 - scanline_strength * intensity;
	col *= scan;

	// szum
	float n = hash(uv * resolution + vec2(t * 60.0, t * 17.0));
	col += (n - 0.5) * noise_strength * intensity;

	// lekkie odbarwienie i ciepły ton
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), 0.08 * intensity);
	col *= vec3(1.03, 1.0, 1.05);

	// winieta
	vec2 vc = uv - 0.5;
	col *= 1.0 - vignette * intensity * dot(vc, vc) * 2.2;

	COLOR = vec4(col, 1.0);
}
