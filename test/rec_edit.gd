extends "res://test/rec_tut.gd"
# Nagranie samouczka edycji pokoiku (Etap 2): Tab, przenoszenie mebla, obrót. Na komputerze z GPU.


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.logo = "paws"
	Game.start_stage(2)
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor", "tut_edycja", "stage2_intro", "arbjooze"]:
		Game.tips[k] = true
	Game.shop["rakieta"] = true
	Game.shop["dywan"] = true
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	w._enter("pokoik", true)
	w.body.position = Vector2(300, 286)
	await get_tree().create_timer(0.8).timeout
	# 1) Tab: tryb edycji, na dole skrót sterowania
	var r := Rect2i(160, 200, 320, 180)  # z paskiem trybu edycji na dole
	for i in 6:
		await grab(r)
	w._edit_toggle()
	for i in 10:
		await grab(r)
	save("edit_tab")
	# 2) pufa: podświetlenie, podniesienie, czerwony w złym miejscu, położenie w dobrym
	var pufa := "room_pufa"
	var it: Dictionary = w.decor_items[pufa]
	var c0: Vector2 = it.s.position + Vector2(it.s.texture.get_size().x / 2, -10)
	var rm := crop_at(c0 + Vector2(90, -20))
	await glide(rm, c0 + Vector2(120, -60), c0, 6)
	w.hover_item = pufa
	it.s.modulate = Color(1.25, 1.25, 1.25)
	await grab(rm, 0.1, c0, true)
	w.held = pufa
	w.held_from = [0, 0, false]
	it.grab = c0 - it.s.position
	var path := [Vector2(40, -40), Vector2(80, -90), Vector2(130, -40), Vector2(180, -10)]
	var prev := Vector2.ZERO
	for q in path:
		for k in 5:
			var off: Vector2 = prev.lerp(q, (k + 1) / 5.0).round()
			Game.decor[pufa] = [off.x, off.y, false]
			w._apply_decor(pufa)
			it.s.modulate = Color(1.15, 1.15, 1.15) if w._decor_ok(pufa) else Color(1.5, 0.55, 0.55)
			await grab(rm, 0.08, c0 + off)
		prev = q
	it.s.modulate = Color.WHITE
	w.held = ""
	await grab(rm, 0.1, c0 + prev, true)
	for i in 6:
		await grab(rm, 0.1, c0 + prev)
	save("edit_move")
	# 3) rakieta: Q/E odbija ją w miejscu
	var rk := "pokoik_rakieta"
	var ri: Dictionary = w.decor_items[rk]
	var rc: Vector2 = ri.s.position + Vector2(14, -30)
	var rr := crop_at(rc)
	w.hover_item = rk
	ri.s.modulate = Color(1.25, 1.25, 1.25)
	for f in [false, true, false, true]:
		for i in 5:
			await grab(rr, 0.1, rc)
		Game.decor[rk] = [0, 0, f]
		w._apply_decor(rk)
	save("edit_flip")
	Game.quit()
