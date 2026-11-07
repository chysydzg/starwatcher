extends Node2D
## Animacje widoku z balkonu (gra i menu): migoczące gwiazdy, odbicie księżyca, refleksy na wodzie,
## girlanda na balustradzie, deszcz. Rysowane piksel po pikselu na tle balcony.png (640x360).

const MOON := Vector2(492, 74)
const LAKE := Vector2i(214, 264)   # pas wody widoczny nad poręczą
var t := 0.0
var raining := false
var front := false        # warstwa przed rekwizytami: tylko ulewa (przyciemnienie, krople, rozbryzgi)
var meteors := true       # spadające gwiazdy tylko gdy noc ma meteory (zapowiedź eventu)
var comet := false        # kometa widoczna na niebie, zanim podejdzie się do teleskopu
var _splash := []
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
	if raining and front:
		for i in 14:
			_drops.append(Vector3(_rng.randf_range(0, 700), _rng.randf_range(-20, 0), _rng.randf_range(0.7, 1.3)))
	for i in range(_drops.size() - 1, -1, -1):
		var d: Vector3 = _drops[i]
		d += Vector3(-70, 360, 0) * d.z * dt
		_drops[i] = d
		var floor_y := 300.0 + fmod(i * 37.0, 56.0)  # krople spadają na różną głębokość podłogi
		if d.y > floor_y:
			if _rng.randf() < 0.5:
				_splash.append([Vector2(d.x, d.y), 0.0])
			_drops.remove_at(i)
	for sp in _splash:
		sp[1] += dt
	_splash = _splash.filter(func(sp): return sp[1] < 0.25)
	if shooting.is_empty() and meteors and _rng.randf() < dt / 4.0 and not raining:
		shooting = {"p": Vector2(_rng.randi_range(200, 600), _rng.randi_range(10, 70)), "t": 0.0}
	if not shooting.is_empty():
		shooting.t += dt
		if shooting.t > 0.9:
			shooting = {}
	queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _draw() -> void:
	if front:
		_draw_rain()
		return
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
			_px(MOON.x - floori(w / 2.0) + off, row, w, 1, Color(0.97, 0.91, 0.7, (0.75 - d / 80.0) * dim))
	for i in 24:  # refleksy na wodzie
		var x := fposmod(i * 53.0 + t * (3 + i % 3), 560.0) + 80.0
		var y := float(LAKE.x + 3 + (i * 7) % (LAKE.y - LAKE.x - 4))
		_px(x, y, 3 + i % 3, 1, Color(0.6, 0.7, 0.95, 0.5 * maxf(0.0, sin(t * 1.3 + i))))
	# girlanda na poręczy
	for x in range(80, 640):
		var sag := 3.0 * sin(PI * fposmod(x - 80.0, 22.0) / 22.0)
		_px(x, 262 + sag, 1, 1, Color("1a1426"))
		if (x - 84) % 8 == 0:
			var c := Color("ffd27a") if floori(x / 8.0) % 2 else Color("ff9a6a")
			c.a = 0.6 + 0.4 * sin(t * 2.0 + x * 0.4)
			_px(x, 263 + sag, 1, 2, c)
			_px(x - 1, 264 + sag, 3, 1, Color(c, c.a * 0.25))
	if comet and not raining:  # kometa: jasna głowa i długi warkocz
		var hp := Vector2(180, 46)
		for i in 26:
			_px(hp.x + i * 2, hp.y - i * 0.6, 1 + int(i < 6), 1, Color(0.8, 0.9, 1.0, 0.7 * (1.0 - i / 26.0)))
		_px(hp.x - 1, hp.y - 1, 3, 3, Color(1, 1, 0.95, 0.9 + 0.1 * sin(t * 6.0)))


## ulewa: przyciemnione, sine powietrze, ukośne smugi deszczu, rozbryzgi i kręgi na jeziorze
func _draw_rain() -> void:
	if not raining:
		return
	_px(0, 0, 640, 360, Color(0.12, 0.16, 0.3, 0.32))
	for d in _drops:
		_px(d.x, d.y, 1, 7, Color(0.75, 0.82, 1.0, 0.55 * d.z))
		_px(d.x + 1, d.y - 2, 1, 3, Color(0.75, 0.82, 1.0, 0.25 * d.z))
	for sp in _splash:
		var k: float = sp[1] / 0.25
		var c := Color(0.8, 0.88, 1.0, 0.7 * (1.0 - k))
		_px(sp[0].x - 2 - k * 3, sp[0].y - k * 2, 1, 1, c)
		_px(sp[0].x + 2 + k * 3, sp[0].y - k * 2, 1, 1, c)
		_px(sp[0].x, sp[0].y - 1 - k * 4, 1, 1, c)
	for i in 14:  # kręgi na wodzie
		var ph := fmod(t * 1.7 + i * 0.37, 1.0)
		var x := float((i * 83) % 560 + 80)
		var y := float(LAKE.x + 4 + (i * 11) % (LAKE.y - LAKE.x - 6))
		_px(x - ph * 5, y, ph * 10 + 1, 1, Color(0.75, 0.85, 1.0, 0.45 * (1.0 - ph)))
