extends Node
## Debug: odpala scenę testową i zapisuje zrzut nocy i dnia do debug_shots/. Do usunięcia.
func _ready() -> void:
	var s: Node = load("res://artstyle_test/artstyle_test.tscn").instantiate()
	add_child(s)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/artstyle_night.png")
	s._set_night(false)
	await get_tree().create_timer(1.6).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/artstyle_day.png")
	get_tree().quit()
