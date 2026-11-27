extends Node
# Zrzuty scenek satelity (budowa na rusztowaniu, start rakiety) – na komputerze z GPU; headless tylko sprawdza skrypt.
func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://debug_shots/%s.png" % name)


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.start_stage(2)
	for mode in ["build", "launch:SW-1"]:
		Game.cut_arg = mode
		var s: Node = load("res://game/sat_scene.tscn").instantiate()
		get_tree().root.add_child(s)
		for k in 7:
			await get_tree().create_timer(2.0).timeout
			shot("sat_%s_%d" % [mode.left(5).trim_suffix(":"), k])
		s.ended = true  # bez przejścia do świata
		s.queue_free()
		await get_tree().create_timer(0.3).timeout
	print("SAT SCENES OK")
	Game.quit()
