extends Node
# Zrzuty kontrolne (render na prawdziwym GPU): menu, balkon nocą, okular, pokój w dzień i w nocy, AstroOS.
func shot(label: String) -> void:
	await get_tree().create_timer(0.7).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/sw_%s.png" % label)

func _ready() -> void:
	Game.use_test_save()
	var m = load("res://game/menu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await shot("menu")
	m.queue_free()
	Game.new_game()
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	w.jania.position.x = 300
	await shot("balkon")
	w.jania.position = Vector2(250, 330)  # za teleskopem: sortowanie głębi
	await shot("balkon_glebia")
	w._interact("teleskop")
	await get_tree().create_timer(0.5).timeout
	var tel = w.viewport
	tel.aim = tel.C + Vector2(-60, 40)
	await shot("okular_skan")
	var tg = tel.targets[1]
	tel.cam = tg.pos + Vector2(30, 10)
	await get_tree().create_timer(0.1).timeout
	tel.aim = tel.to_screen(tg.pos)
	await shot("okular_hover")
	tel._lock_or_confirm()
	tel.f = tg.sweet + 0.14
	await shot("okular_fokus")
	tel.f = tg.sweet
	tel._after_focus()
	var pts = tel.star_points(tg)
	for k in 3:
		tel.aim = pts[k]
		tel._click_star()
	tel.aim = pts[3]
	await shot("okular_laczenie")
	tel.close()
	await get_tree().create_timer(0.5).timeout
	w._enter("room", true)
	w.jania.position = Vector2(372, 128)  # za krzesłem
	await shot("pokoj_noc")
	Game.journal.append({"uid": 99, "id": "kasjopeja", "name": "Kasjopeja", "cat": "const", "quality": 92, "base": 25.0, "day": 1, "sold": false})
	w._sleep()
	await shot("podsumowanie")
	w.top.get_child(w.top.get_child_count() - 1).queue_free()
	w.busy = false
	w._enter("room", true)
	w._apply_phase(true)
	w.jania.position = Vector2(380, 160)
	await shot("pokoj_dzien")
	w._interact("komputer")
	w.viewport.tab = 1
	w.viewport._rebuild()
	await shot("astroos_gielda")
	w.viewport.tab = 3
	w.viewport._rebuild()
	await shot("astroos_drzewko")
	get_tree().quit()
