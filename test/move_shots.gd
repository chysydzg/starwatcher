extends Node
# Zrzuty przeprowadzki (render na GPU): co 2 s zrzut, spacja co 1 s (dialogi idą dalej), na końcu karta Etapu 2.
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


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	var m: Node = load("res://game/moving.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	for k in 50:
		await get_tree().create_timer(1.0).timeout
		if m.ended:  # karta końca: spacja wcisnęłaby DO MENU i zmiana sceny usunęłaby ten test
			get_viewport().get_texture().get_image().save_png("res://debug_shots/mv_end.png")
			break
		await space()
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("res://debug_shots/mv_%02d.png" % k)
	Game.quit()
