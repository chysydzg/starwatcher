extends Node
# Zrzuty przeprowadzki (render na GPU): co 2 s zrzut, spacja co 1 s (dialogi idą dalej); potem wybór logo
# (zrzut, spacja = wybór, spacja = TAK) i Etap 2: przyjście Arbjooze (zrzuty co 2 s).
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


func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://debug_shots/%s.png" % name)


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	var m: Node = load("res://game/moving.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().process_frame
	get_tree().current_scene = m  # zmiany scen (logo, świat) zastępują scenkę, nie ten test
	for k in 50:
		await get_tree().create_timer(1.0).timeout
		if m == null or not is_instance_valid(m) or m.ended:
			break
		await space()
		await get_tree().create_timer(1.0).timeout
		shot("mv_%02d" % k)
	await get_tree().create_timer(1.5).timeout
	shot("lg_0")
	await space()  # wybór pierwszego logo
	await get_tree().create_timer(0.5).timeout
	shot("lg_1")
	await space()  # TAK
	for k in 14:
		await get_tree().create_timer(2.0).timeout
		shot("e2_%02d" % k)
		await space()
	Game.quit()
