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
	w._interact("teleskop")
	for i in 20: await get_tree().process_frame
	var tel = w.viewport
	assert(tel != null and tel.is_telescope, "telescope opened")
	print("targets: ", tel.targets.map(func(x): return x.id))
	for tg in tel.targets.duplicate():
		tel.cam = tg.pos
		tel.aim = tel.C
		tel.state = tel.S.SCAN
		tel._lock_or_confirm()
		assert(tel.state == tel.S.FOCUS, "locked " + tg.id)
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
	w._sleep()
	await get_tree().create_timer(0.3).timeout
	assert(not Game.night and Game.day == 2, "morning of day 2")
	w.busy = false
	w._interact("komputer")
	for i in 5: await get_tree().process_frame
	var os = w.viewport
	for tb in 5:
		os.tab = tb
		os._rebuild()
		await get_tree().process_frame
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
	print("TEST OK")
	get_tree().quit()
