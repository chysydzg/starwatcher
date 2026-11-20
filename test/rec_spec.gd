extends "res://test/rec_tut.gd"
# Nagranie samouczka analizy widmowej (Etap 2): widmo, trzymanie wzorca na dryfujących liniach, udana analiza. Na komputerze z GPU.


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.logo = "paws"
	Game.start_stage(2)
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor", "tut_edycja", "tut_widmo", "stage2_intro", "arbjooze"]:
		Game.tips[k] = true
	Game.science["spektro"] = true
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	Game.start_night()
	w._enter("room", true)
	w.busy = false
	w._interact("teleskop")
	await get_tree().create_timer(1.5).timeout
	var tel = w.viewport
	var tg: Dictionary = {}
	for x in tel.targets:
		if Game.spectral(x.info.cat):
			tg = x
			break
	tel.target = tg
	tel.cam = tg.pos
	tel.f = tg.sweet
	tel.state = tel.S.FOCUS
	await get_tree().create_timer(0.4).timeout
	tel._after_focus()
	var r := Rect2i(160, 168, 320, 180)  # obiekt u góry, widmo i paski na dole
	var aim_at := func(v: float): tel.aim.x = tel.C.x + v / 0.45 * (tel.R - 6)
	# 1) widmo i dryfujące linie, wzorzec daleko
	for i in 14:
		aim_at.call(-0.4)
		await grab(r, 0.1)
	save("spec_bar")
	# 2) wzorzec dojeżdża i trzyma się linii, pasek się zapełnia
	var v := -0.4
	for i in 30:
		v = move_toward(v, tel.spec.goal, 0.05)
		aim_at.call(v)
		await grab(r, 0.08)
		if tel.state != tel.S.SPECTRUM:
			break
	save("spec_hold")
	# 3) wynik
	for i in 10:
		await grab(r, 0.12)
	save("spec_done")
	Game.quit()
