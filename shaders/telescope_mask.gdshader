shader_type canvas_item;
// Okrągła maska okularu teleskopu: czarne tło poza kołem, miękka krawędź, obręcz, winieta i celownik.

uniform float radius = 90.0;
uniform float softness = 4.0;
uniform vec2 resolution = vec2(384.0, 216.0);
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.01, 1.0);
uniform vec4 rim_color : source_color = vec4(0.45, 0.5, 0.65, 0.9);
uniform vec4 crosshair_color : source_color = vec4(0.6, 0.7, 0.9, 0.35);

void fragment() {
	vec2 p = UV * resolution - resolution * 0.5;
	float d = length(p);
	float outside = smoothstep(radius - softness, radius + 1.0, d);
	float inner = smoothstep(radius * 0.6, radius, d) * 0.45;
	float rim = (1.0 - smoothstep(0.0, 1.5, abs(d - radius))) * rim_color.a;
	float cross = 0.0;
	bool vertical = abs(p.x) < 0.6 && abs(p.y) < radius && abs(p.y) > 10.0;
	bool horizontal = abs(p.y) < 0.6 && abs(p.x) < radius && abs(p.x) > 10.0;
	if (vertical || horizontal) {
		cross = crosshair_color.a * (1.0 - outside);
	}
	vec3 rgb = tint.rgb;
	float a = max(outside, inner);
	if (cross > 0.001) {
		rgb = crosshair_color.rgb;
		a = max(a, cross);
	}
	if (rim > 0.001) {
		rgb = mix(rgb, rim_color.rgb, rim);
		a = max(a, rim);
	}
	COLOR = vec4(rgb, a);
}
