extends Node2D
## Szachownica jako podloga, zeby bylo widac ruch kamery.

@export var tiles := 32
@export var tile_size := 64.0
@export var color_a := Color(0.16, 0.18, 0.22)
@export var color_b := Color(0.20, 0.22, 0.27)

func _draw() -> void:
	var half := tiles * tile_size * 0.5
	for x in tiles:
		for y in tiles:
			var c := color_a if (x + y) % 2 == 0 else color_b
			draw_rect(Rect2(x * tile_size - half, y * tile_size - half, tile_size, tile_size), c)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), Color(1, 0.8, 0.2), false, 4.0)
