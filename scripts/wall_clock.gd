extends Node2D
## Zegar analogowy: wskazówki rysowane z czasu gry (GameState.minutes).

const HAND_COLOR := Color("3e3146")


func _ready() -> void:
	GameState.time_changed.connect(func(_m: float) -> void: queue_redraw())


func _draw() -> void:
	var minutes: float = GameState.minutes
	var hour_angle := deg_to_rad(fmod(minutes, 720.0) / 720.0 * 360.0 - 90.0)
	var min_angle := deg_to_rad(fmod(minutes, 60.0) / 60.0 * 360.0 - 90.0)
	draw_line(Vector2.ZERO, Vector2(cos(hour_angle), sin(hour_angle)) * 3.5, HAND_COLOR, 1.0)
	draw_line(Vector2.ZERO, Vector2(cos(min_angle), sin(min_angle)) * 5.5, HAND_COLOR, 1.0)
