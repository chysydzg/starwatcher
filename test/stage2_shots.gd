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
	Game.tips["tut_hr"] = true  # samouczki z nagraniami oglądają rec_hr / rec_dlug; tu gra nie staje w pauzie
	Game.tips["tut_dlug"] = true
	Game.tips["tut_orbita"] = true
	var w: Node = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child.call_deferred(w)
	await get_tree().process_frame
	get_tree().current_scene = w
	for k in 14:
		await get_tree().create_timer(1.5).timeout
		shot("e2_%02d" % k)
		await space()
	for c in ["polka", "dywan", "girlanda", "plakat_saturn", "rakieta", "pluszak"]:
		Game.shop[c] = true
	w._refresh()
	Game.tips["tut_edycja"] = true
	w._enter("pokoik", true)
	await get_tree().create_timer(1.0).timeout
	shot("e2_pokoik")
	# tryb edycji: podnieś pufę, przesuń, odbij szafkę nocną (lampka idzie za nią)
	w.busy = false  # test: bez otwartych okienek
	w.jania.set_meta("walking", true)  # Tab w trakcie chodzenia: Jania staje (bez tupania)
	w._edit_toggle()
	assert(w.editing)
	for i in 2: await get_tree().process_frame
	assert(not w.jania.get_meta("walking"), "w trybie budowania Jania nie chodzi")
	for k in w.decor_items:  # domyślne miejsca są poprawne (okno i drzwi wolne)
		if w.decor_items[k].s.visible:
			assert(w._decor_ok(k), "domyślne miejsce OK: " + k)
	Game.decor["room_wardrobe"] = [-400, 0, false]  # szafa pod oknem: okno zasłonięte, nie wolno
	w._apply_decor("room_wardrobe")
	assert(not w._decor_ok("room_wardrobe"), "mebel nie zasłania okna")
	Game.decor["room_wardrobe"] = [0, 0, false]
	w._apply_decor("room_wardrobe")
	assert(w.props.radio.get_parent() == w.props.pokoik_skrzynka, "radio stoi na skrzynce w pokoiku")
	assert(Game._loops["music/build"].playing, "tryb edycji: motyw build")
	w.hover_item = "room_pufa"
	w.held = "room_pufa"
	w.held_from = [0, 0, false]
	Game.decor["room_pufa"] = [200, -40, false]
	w._apply_decor("room_pufa")
	print("pufa ok at +200,-40: ", w._decor_ok("room_pufa"))
	Game.decor["room_pufa"] = [-20, -200, false]
	w._apply_decor("room_pufa")
	assert(not w._decor_ok("room_pufa"))  # na ścianie
	w._edit_cancel()
	assert(Game.decor["room_pufa"] == [0, 0, false])
	Game.decor["room_nightstand"] = [300, 60, true]
	w._apply_decor("room_nightstand")
	print("lampka light ", w.own_lights[0].position, " spots lozko ", w._spots().get("lampka"))
	print("decor at pufa: ", w._decor_at(w.decor_items["room_pufa"].s.position + Vector2(20, -8)))
	await get_tree().create_timer(0.5).timeout
	shot("e2_edit")
	w._edit_toggle()
	await get_tree().create_timer(1.3).timeout
	assert(not Game._loops["music/build"].playing, "po edycji build milknie")
	print("EDIT MUSIC OK")
	Game.decor = {}
	for k in w.decor_items:
		w._apply_decor(k)
	w._enter("room", true)
	Game.money = 20000
	Game.pw = 20000
	for id in ["spektro", "orbitalna", "filtr_x", "mentoring", "kalibracja", "katalog"]:
		Game.science[id] = true
	for id in ["antena", "st_obs", "st_analiza", "ekspres", "legowisko", "montaz_sat", "pogoda", "nas"]:
		Game.shop[id] = true
	Game.build_sat(false)
	Game.hire(Game.candidates[0])
	Game.hire(Game.candidates[0])
	Game.staff[0].report = "saturn"
	Game.staff[2].report = "uran"
	Game.changed.emit()
	await get_tree().create_timer(0.5).timeout
	shot("e2_report")
	w._worker_desk(2)  # zgłoszenie pracownika: okienko rozmowy z jego portretem
	await get_tree().create_timer(1.2).timeout
	var dlg: Array = w.get_children().filter(func(n): return n.get("lines") != null)
	assert(dlg.size() == 1 and dlg[0].lines[0].has("portrait"), "zgłoszenie w oknie dialogu z portretem")
	shot("e2_report_dialog")
	dlg[0].queue_free()
	w.busy = false
	Game.reports.clear()
	w._interact("komputer")
	await get_tree().create_timer(1.0).timeout
	for a in ["zespol", "orbita", "badania", "sklep", "pomoc", "gielda"]:
		w.viewport._launch(a)
		await get_tree().create_timer(0.6).timeout
		shot("e2_os_" + a)
	w.viewport.close()
	await get_tree().create_timer(0.5).timeout
	Game.reports = ["saturn"]
	Game.start_night()
	w._enter("room", true)
	await get_tree().create_timer(2.0).timeout
	shot("e2_noc")
	Game.tips["tut_tel"] = true
	Game.tips["tut_widmo"] = true
	w._interact("teleskop")
	await get_tree().create_timer(1.5).timeout
	shot("e2_tel")
	var tel = w.viewport
	for tg in tel.targets:  # namierz pierwszy obiekt z analizą widmową i pokaż pasek widma
		if Game.spectral(tg.info.cat):
			tel.target = tg
			tel.cam = tg.pos
			tel.f = tg.sweet
			tel.state = tel.S.FOCUS
			await get_tree().create_timer(0.5).timeout
			shot("e2_tel_focus")
			tel._after_focus()
			await get_tree().create_timer(0.6).timeout
			shot("e2_tel_widmo")
			break
	tel.close()
	await get_tree().create_timer(0.5).timeout
	w._enter("pokoik", true)
	await get_tree().create_timer(2.0).timeout
	shot("e2_noc_pokoik")
	# zmiana pory: muzyka cichnie, gra przerywnik, potem wchodzi motyw Etapu 2 (day2 / night2), stare pętle milczą
	w.busy = false
	w._sky_anim(true, func(): pass)
	await get_tree().create_timer(1.5).timeout
	assert(Game._loops["music/night2"].volume_db < -20.0, "noc cichnie pod przerywnikiem")
	await get_tree().create_timer(5.5).timeout
	assert(Game._loops["music/day2"].playing and Game._loops["music/day2"].volume_db > -10.0, "dzień 2 po przerywniku")
	assert(not Game._loops.has("music/day") or not Game._loops["music/day"].playing, "pętla Etapu 1 milczy")
	# pensje bez pieniędzy: konto na minusie, po 3 porankach strajk, po 6 odejście (Józek zostaje)
	Game.money = 0
	var n0: int = Game.staff.size()
	for k in Game.STRIKE_DAYS:
		Game._staff_morning([])
	assert(Game.money < 0 and not Game.working(Game.staff[0]), "bez wypłaty zespół nie pracuje")
	for k in Game.QUIT_DAYS - Game.STRIKE_DAYS:
		Game._staff_morning([])
	assert(Game.staff.size() == 1 and Game.staff[0].kind == "cat" and n0 > 1, "nieopłaceni odchodzą, Józek zostaje")
	Game.money = 99999
	Game._staff_morning([])
	assert(Game.working(Game.staff[0]), "po wypłacie znów pracuje")
	print("MUSIC S2 OK")
	Game.quit()
