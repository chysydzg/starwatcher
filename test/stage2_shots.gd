extends Node
# Zrzuty Etapu 2 (bez przeprowadzki): nowa gra od razu w obserwatorium, przyjście Arbjooze, potem noc w kopule.
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
	Game.logo = "paws"
	Game.start_stage(2)
	var w: Node = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child.call_deferred(w)
	await get_tree().process_frame
	get_tree().current_scene = w
	for k in 14:
		await get_tree().create_timer(1.5).timeout
		shot("e2_%02d" % k)
		await space()
	w._enter("pokoik", true)
	await get_tree().create_timer(1.0).timeout
	shot("e2_pokoik")
	Game.night = true  # noc w obserwatorium: oświetlenie i muzyka nocna
	w._enter("room", true)
	await get_tree().create_timer(2.0).timeout
	shot("e2_noc")
	w._enter("pokoik", true)
	await get_tree().create_timer(2.0).timeout
	shot("e2_noc_pokoik")
	Game.quit()
