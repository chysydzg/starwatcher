extends Node
# Test dymny Etapu 1: noc → teleskop → zapis → sen → dzień → komputer → sprzedaż → zakupy → zapis/odczyt.
func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	get_tree().root.add_child(load("res://game/world.tscn").instantiate())
	for i in 30: await get_tree().process_frame
	var w = get_tree().root.get_node("World")
	assert(w.name == "World", "world loaded")
	w._enter("balcony", true)
	assert(Game._loops["music/night"].playing and Game._loops["music/night"].stream.loop, "night loop on balcony")
	w._interact("teleskop")
	for i in 20: await get_tree().process_frame
	var tel = w.viewport
	assert(tel != null and tel.is_telescope, "telescope opened")
	assert(tel.steer() < 3.0 and tel.hum != null, "bez ulepszeń celownik chodzi ciężko, wykrywacz buczy")
	print("targets: ", tel.targets.map(func(x): return x.id))
	for tg in tel.targets.duplicate():
		tel.cam = tg.pos
		tel.aim = tel.C
		tel.state = tel.S.SCAN
		tel._lock_or_confirm()
		assert(tel.state == tel.S.FOCUS, "locked " + tg.id)
		tel.f_goal = 0.0 if tel.f > 0.5 else 1.0
		var f0: float = tel.f
		tel._process(0.05)
		assert(tel.f != f0 and absf(tel.f - tel.f_goal) > 0.15, "soczewka nadąża za kółkiem z opóźnieniem")
		tel.f = tg.sweet
		tel._after_focus()
		if tg.info.has("pts"):
			for p in tel.star_points(tg):
				tel.aim = p
				tel.t = 0.0
				tel._click_star()
		tel.state = tel.S.SCAN
	print("journal: ", Game.journal.size(), " pw: ", Game.pw, " stored: ", Game.stored().size())
	assert(Game.journal.size() == min(tel.targets.size(), 5), "recorded up to storage cap")
	tel.close()
	await get_tree().create_timer(0.8).timeout
	assert(w.viewport == null, "telescope closed")
	w._enter("room", true)
	assert(Game._loops["music/day"].playing, "day loop in room")
	for k in ["lampa", "lampka"]:
		w._interact(k)
		assert(not w.lamps[k].on and w.lamps[k].light.energy == 0.0, "lamp switches off")
		w._interact(k)
		assert(w.lamps[k].on and w.lamps[k].light.energy > 0.0, "lamp switches on")
	w._sleep()
	await get_tree().create_timer(0.3).timeout
	assert(not Game.night and Game.day == 2, "morning of day 2")
	var next: Button = w.top.find_children("*", "Button", true, false).filter(func(x): return x.text == "KOLEJNY DZIEŃ")[0]
	next.pressed.emit()  # w trakcie animacji: pierwszy klik tylko ją pomija
	await get_tree().create_timer(1.5).timeout
	assert(is_instance_valid(next) and w.busy, "first click skips the summary animation")
	assert(not Game._loops["music/night"].playing, "wyciszona pętla zatrzymuje się po przenikaniu")
	next.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not is_instance_valid(next), "second click starts the day")
	w.busy = false
	w._interact("komputer")
	for i in 5: await get_tree().process_frame
	var os = w.viewport
	for id in ["dziennik", "gielda", "sklep", "badania", "pomoc"]:
		os._launch(id)
		await get_tree().process_frame
	os.jpage = 2  # dzień 2: strona 1 = dziś, strona 2 = wczorajsza noc z podsumowaniem
	os._launch("dziennik")
	await get_tree().process_frame
	var jl: Array = os.body.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert(jl.any(func(x): return x.begins_with("Dzień 1 · Poniedziałek")) and jl.any(func(x): return x.contains("w pamięci")), "dziennik: wpisy z dnia 1")
	assert(jl.any(func(x): return x.begins_with("Podsumowanie:") and not x.contains("dzień trwa")), "dziennik: podsumowanie dnia 1")
	os._close_app()
	var earned := Game.sell(Game.stored())
	print("sold for $", earned, " money=", Game.money)
	Game.pw += 200
	for r in Game.SCIENCE:
		if Game.can_buy_science(r) == "ok":
			Game.buy_science(r)
	for r in Game.SHOP:
		if Game.can_buy_shop(r) == "ok":
			Game.buy_shop(r)
	print("science: ", Game.science.keys(), " pending: ", Game.pending)
	os.close()
	Game.start_night()
	print("parcels after nightfall: ", Game.parcels, " night len ", Game.night_length())
	Game.unpack_all()
	Game.save_game()
	var before := JSON.stringify([Game.day, Game.money, Game.pw, Game.journal.size(), Game.science.size(), Game.shop.size()])
	Game.new_game()
	assert(Game.load_game(), "load")
	var after := JSON.stringify([Game.day, Game.money, Game.pw, Game.journal.size(), Game.science.size(), Game.shop.size()])
	assert(before == after, "save roundtrip " + before + " vs " + after)
	print("visible tonight: ", Game.visible_objects())
	w._refresh()
	w._interact("drzwi")
	await get_tree().create_timer(1.0).timeout
	print("location: ", Game.location)
	# kolizje: Jania idzie w łóżko z prawej strony i musi się zatrzymać na jego krawędzi
	w._enter("room", true)
	w.busy = false
	w.body.position = Vector2(140, 150)
	for i in 60:
		w.body.velocity = Vector2(-144, 0)
		w.body.move_and_slide()
		await get_tree().physics_frame
	print("przy łóżku x=", w.body.position.x, " interakcja: ", w._nearest())
	assert(w.body.position.x > 100 and w._nearest() == "lozko", "bed collider + side reach")
	# raport poranny: wysłany w nocy, wypłacony po śnie; oferta instytutu sprzedaje od razu
	Game.journal.append({"uid": 9999, "id": "orion", "name": "Orion", "cat": "const", "quality": 90, "base": 30.0, "day": Game.day, "sold": false})
	var m0 := Game.money
	Game.send_report([Game.journal[-1]])
	assert(Game.money == m0 and not Game.stored().any(func(e): return e.uid == 9999), "raport czeka do rana")
	var pid: String = Game.SHOP.filter(func(r): return not Game.shop.has(r[0]))[0][0]
	Game.parcels = [pid]  # paczka nieodebrana: otwiera się sama, gdy Jania idzie spać
	var sm := Game.sleep()
	assert(Game.shop.has(pid) and Game.parcels.is_empty() and sm.opened.size() == 1 and Game.history[-1] == sm, "paczka otwarta przy śnie")
	assert(Game.money > m0 and Game.analysis.uids.is_empty(), "wypłata rano")
	Game.journal.append({"uid": 9998, "id": "lew", "name": "Lew", "cat": "zodiac", "quality": 80, "base": 50.0, "day": Game.day, "sold": false})
	Game.offer = {"uid": 9998, "who": "Test", "price": 123}
	var m1 := Game.money
	assert(Game.accept_offer() == 123 and Game.money == m1 + 123 and Game.offer_entry().is_empty(), "oferta")
	Game.settings.vol.SFX = 99
	Game.apply_settings()
	assert(Game.settings.vol.SFX == 10, "głośność z pliku ustawień przycięta do 0–10")
	Game.settings.vol.SFX = 8
	Game.apply_settings()
	print("TEST OK")
	FileAccess.open("res://debug_shots/test_result.txt", FileAccess.WRITE).store_string("TEST OK")  # wynik czytelny po wyjściu z gry
	Game.quit()
