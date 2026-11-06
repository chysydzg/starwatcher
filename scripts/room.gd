extends Node2D
## Pokój: pulsująca poświata monitora CRT.

@onready var glow: Sprite2D = $Props/Desk/Glow


func _ready() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
