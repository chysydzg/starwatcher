extends Node
# Zrzuty intro (render na GPU): Księżyc, cofanie kamery, balkon, dialogi, napis na drzwiach.
func shot(label: String) -> void:
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://debug_shots/cut_%s.png" % label)


func space() -> void:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_SPACE
	e.keycode = KEY_SPACE
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	get_tree().root.add_child.call_deferred(load("res://game/cutscene.tscn").instantiate())
	await wait(2.4)
	await shot("1_ksiezyc")
	await wait(3.4)
	await shot("2_cofanie")
	await wait(4.6)
	await shot("3_balkon")
	await wait(0.9)
	await shot("4_pisze")
	await wait(2.6)
	await shot("5_jania")
	await space()
	await wait(3.2)
	await shot("6_maciej")
	await space()
	await wait(1.6)
	await shot("7_kolacja")
	Game.quit()
