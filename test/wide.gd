extends Node
# Szeroki ekran (21:9, jak 3440x1440 w skali 1/2): menu, balkon w burzy z parasolem, pokój, okular – bez czarnych pasów.
func shot(label: String) -> void:
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/wide_%s.png" % label)


func _ready() -> void:
	get_window().size = Vector2i(1720, 720)
	Game.use_test_save()
	var m = load("res://game/menu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await shot("menu")
	m.queue_free()
	Game.new_game()
	for k in ["tut_tel", "tut_pc", "tut_shop", "start"]:
		Game.tips[k] = true
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	Game.rain = true
	Game.storm = true
	Game.shop["parasol"] = true
	w._refresh()
	await shot("balkon")
	w._interact("teleskop")
	await shot("okular")
	w.viewport.close()
	await get_tree().create_timer(0.4).timeout
	Game.rain = false
	Game.storm = false
	w._enter("room", true)
	w._refresh()
	await shot("pokoj")
	Game.quit()
