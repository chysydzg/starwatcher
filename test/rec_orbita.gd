extends "res://test/rec_tut.gd"
# Nagranie samouczka „Satelity” (Etap 2): zakładka Orbita, budowa, zadania na orbicie, burza słoneczna. Na komputerze z GPU.


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.logo = "paws"
	Game.start_stage(2)
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor", "tut_edycja", "tut_widmo", "tut_dlug", "tut_hr", "tut_orbita", "stage2_intro", "arbjooze", "sat_build_cut"]:
		Game.tips[k] = true
	Game.science["orbitalna"] = true
	Game.shop["antena"] = true
	Game.money = 9000
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	w._enter("room", true)
	w.busy = false
	w._interact("komputer")
	await get_tree().create_timer(1.0).timeout
	var os = w.viewport
	var m := Vector2i(Game.margin)
	var left := Rect2i(m, Vector2i(320, 180))
	var right := Rect2i(m + Vector2i(320, 60), Vector2i(320, 180))
	# 1) Orbita: Ziemia i puste sloty
	os._launch("orbita")
	for i in 14:
		await grab(right, 0.12)
	save("orb_open")
	# 2) budowa satelity badawczego (kursor na przycisku)
	var b: Button = os.body.find_children("*", "Button", true, false).filter(func(x): return x.text.begins_with("SATELITA BADAWCZY"))[0]
	var bc: Vector2 = b.get_global_rect().get_center()
	await glide(left, bc + Vector2(80, 60), bc, 8)
	await grab(left, 0.1, bc, true)
	b.pressed.emit()
	for i in 10:
		await grab(left, 0.12)
	save("orb_build")
	# 3) satelita na orbicie: zadania Nauka / AstroTV / Sat-Net
	Game.sats[0].left = 0
	os._rebuild()
	await get_tree().process_frame
	var tv: Button = os.body.find_children("*", "Button", true, false).filter(func(x): return x.text == "AstroTV")[0]
	var tc: Vector2 = tv.get_global_rect().get_center()
	await glide(left, tc + Vector2(-60, 40), tc, 8)
	await grab(left, 0.1, tc, true)
	tv.pressed.emit()
	await get_tree().process_frame
	for i in 10:
		await grab(left, 0.12, tc)
	save("orb_use")
	# 4) burza słoneczna: satelity przygaszone, ostrzeżenie
	Game.solar = true
	os._rebuild()
	for i in 14:
		await grab(left, 0.12)
	save("orb_storm")
	Game.quit()
