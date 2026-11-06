extends Node2D
## Animacje widoku z balkonu (gra i menu): migoczące gwiazdy, odbicie księżyca, refleksy na wodzie,
## girlanda na balustradzie, deszcz. Rysowane piksel po pikselu na tle balcony.png (640x360).

const MOON := Vector2(492, 74)
const LAKE := Vector2i(214, 264)   # pas wody widoczny nad poręczą
var t := 0.0
var raining := false
var shooting := {}
var _stars := []
var _drops := []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	for i in 70:
		var p := Vector2(_rng.randi_range(80, 636), _rng.randi_range(4, 150))
		if p.distance_to(MOON) > 34:
			_stars.append([p, _rng.randf() * TAU, _rng.randf_range(0.7, 2.0), _rng.randf() < 0.2])


func _process(dt: float) -> void:
	t += dt
	if raining:
		for i in 5:
			_drops.append(Vector2(_rng.randf_range(0, 680), -4))
	for i in range(_drops.size() - 1, -1, -1):
		_drops[i] += Vector2(-50, 230) * dt
		if _drops[i].y > 352:
			_drops.remove_at(i)
	if shooting.is_empty() and _rng.randf() < dt / 9.0 and not raining:
		shooting = {"p": Vector2(_rng.randi_range(200, 600), _rng.randi_range(10, 70)), "t": 0.0}
	if not shooting.is_empty():
		shooting.t += dt
		if shooting.t > 0.9:
			shooting = {}
	queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _draw() -> void:
	var dim := 0.35 if raining else 1.0
	for s in _stars:
		var a: float = (0.3 + 0.7 * absf(sin(t * s[2] + s[1]))) * dim
		var c := Color(1, 0.96, 0.82, a)
		_px(s[0].x, s[0].y, 1, 1, c)
		if s[3] and a > 0.8:
			c.a = (a - 0.8) * 4.0
			for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				_px(s[0].x + o.x, s[0].y + o.y, 1, 1, c)
	if not shooting.is_empty():
		var head: Vector2 = shooting.p + Vector2(-90, 40) * shooting.t
		for i in 10:
			_px(head.x + i * 2, head.y - i, 1, 1, Color(1, 0.97, 0.85, (1.0 - i / 10.0) * (1.0 - shooting.t)))
	# odbicie księżyca: poszarpane, falujące kreski
	for row in range(LAKE.x + 2, LAKE.y, 2):
		var d := float(row - LAKE.x)
		var w := int(14.0 - d * 0.12 + 3.0 * sin(t * 1.6 + d * 0.5))
		var off := int(2.0 * sin(t * 1.1 + d * 0.8))
		if w > 1:
			_px(MOON.x - w / 2 + off, row, w, 1, Color(0.97, 0.91, 0.7, (0.75 - d / 80.0) * dim))
	for i in 24:  # refleksy na wodzie
		var x := fposmod(i * 53.0 + t * (3 + i % 3), 560.0) + 80.0
		var y := float(LAKE.x + 3 + (i * 7) % (LAKE.y - LAKE.x - 4))
		_px(x, y, 3 + i % 3, 1, Color(0.6, 0.7, 0.95, 0.5 * maxf(0.0, sin(t * 1.3 + i))))
	# girlanda na poręczy
	for x in range(80, 640):
		var sag := 3.0 * sin(PI * fposmod(x - 80.0, 22.0) / 22.0)
		_px(x, 262 + sag, 1, 1, Color("1a1426"))
		if (x - 84) % 8 == 0:
			var c := Color("ffd27a") if (x / 8) % 2 else Color("ff9a6a")
			c.a = 0.6 + 0.4 * sin(t * 2.0 + x * 0.4)
			_px(x, 263 + sag, 1, 2, c)
			_px(x - 1, 264 + sag, 3, 1, Color(c, c.a * 0.25))
	for d in _drops:
		_px(d.x, d.y, 1, 4, Color(0.7, 0.78, 1.0, 0.5))
