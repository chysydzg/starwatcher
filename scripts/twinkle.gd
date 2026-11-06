extends Node2D
## Migoczące gwiazdy rysowane nad tłem (prostokąt "area", z pominięciem okolicy księżyca).

@export var count := 40
@export var area := Rect2(2, 2, 380, 84)
@export var avoid := Vector2(300, 40)
@export var avoid_radius := 32.0

var _stars: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	while _stars.size() < count:
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if p.distance_to(avoid) < avoid_radius:
			continue
		_stars.append({"pos": p.floor(), "phase": rng.randf_range(0.0, TAU), "speed": rng.randf_range(1.5, 4.0)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		var a: float = 0.2 + 0.8 * (0.5 + 0.5 * sin(_t * s["speed"] + s["phase"]))
		draw_rect(Rect2(s["pos"], Vector2.ONE), Color(1.0, 1.0, 1.0, a))
