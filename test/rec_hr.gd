extends "res://test/rec_tut.gd"
# Nagranie samouczka „Zespół” (Etap 2, po przyjściu Józka): zakładka HR, koszt i zysk, cecha i tryb, zatrudnianie. Na komputerze z GPU.


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.logo = "paws"
	Game.start_stage(2)
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor", "tut_edycja", "tut_widmo", "tut_dlug", "tut_hr", "stage2_intro", "arbjooze"]:
		Game.tips[k] = true
	Game.shop["st_obs"] = true
	Game.shop["st_analiza"] = true
	Game.shop["st_obs2"] = true
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	Game.hire(Game.candidates[0])
	w._enter("room", true)
	w.busy = false
	w._interact("komputer")
	await get_tree().create_timer(1.0).timeout
	var os = w.viewport
	var m := Vector2i(Game.margin)
	# 1) pulpit, potem zakładka HR
	var top := Rect2i(m, Vector2i(320, 180))
	for i in 6:
		await grab(top, 0.1, Vector2(200, 150) + Game.margin)
	os._launch("zespol")
	for i in 10:
		await grab(top)
	save("hr_open")
	# 2) koszt i zysk (prawa strona tabeli) z bilansem na dole
	var right := Rect2i(m + Vector2i(320, 160), Vector2i(320, 180))
	for i in 16:
		await grab(right, 0.12)
	save("hr_table")
	# 3) dymek cechy, potem klik w tryb (zmiana na następny)
	var tl: Label = os.body.find_children("*", "Label", true, false).filter(func(l): return Game.TRAITS.values().any(func(t): return t[0] == l.text))[0]
	var at: Vector2 = tl.get_global_rect().get_center()
	var mid := crop_at(at + Vector2(120, 30))
	get_viewport().warp_mouse(at)
	for i in 14:
		await grab(mid, 0.12, at)
	var mb: Button = os.body.find_children("*", "Button", true, false).filter(func(b): return b.text in ["Obserwacje", "Raporty", "Sprzęt"])[1]
	var bc: Vector2 = mb.get_global_rect().get_center()
	await glide(mid, at, bc, 8)
	await grab(mid, 0.1, bc, true)
	mb.pressed.emit()
	await get_tree().process_frame
	for i in 8:
		await grab(mid, 0.12, bc)
	save("hr_mode")
	# 4) kandydat: zielony ZATRUDNIJ
	var hb: Button = os.body.find_children("*", "Button", true, false).filter(func(b): return b.text == "ZATRUDNIJ")[0]
	var hc: Vector2 = hb.get_global_rect().get_center()
	var low := crop_at(hc + Vector2(60, -20))
	await glide(low, hc + Vector2(-80, 40), hc, 8)
	await grab(low, 0.1, hc, true)
	hb.pressed.emit()
	for i in 10:
		await grab(low, 0.12, hc)
	save("hr_hire")
	Game.quit()
