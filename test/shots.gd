extends Node
# Zrzuty kontrolne (render na prawdziwym GPU): menu, balkon nocą, okular, pokój w dzień i w nocy, AstroOS.
func shot(label: String) -> void:
	await get_tree().create_timer(0.7).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/sw_%s.png" % label)

func tut_pages(w: Node, id: String) -> void:
	for n in w.get_children():
		if n.get("id") == id:
			for i in n.TUTORIALS[id].pages.size():
				await shot("tut_%s_%d" % [id, i + 1])
				n._next.pressed.emit()


func _ready() -> void:
	Game.use_test_save()
	var m = load("res://game/menu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await shot("menu")
	m._settings()
	await shot("menu_ustawienia")
	m.queue_free()
	Game.new_game()
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	w.body.position.x = 300
	await shot("balkon")
	w.body.position = Vector2(250, 330)  # za teleskopem: sortowanie głębi
	await shot("balkon_glebia")
	w._interact("teleskop")
	await tut_pages(w, "tel")
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
	if tel.target.is_empty():  # cel mógł nie zdążyć „drżeć” pod celownikiem – blokujemy ręcznie
		tel.target = tg
		tel.state = tel.S.FOCUS
	tel.f = tg.sweet + 0.14
	await shot("okular_fokus")
	tel.f = tg.sweet
	tel._after_focus()
	var pts = tel.star_points(tg)
	for k in mini(2, pts.size() - 1):  # niebo jest losowe: gwiazdozbiory mają różną liczbę gwiazd
		tel.aim = pts[k]
		tel._click_star()
	tel.aim = pts[-1]
	await shot("okular_laczenie")
	tel.close()
	await get_tree().create_timer(0.5).timeout
	w._enter("room", true)
	await tut_pages(w, "pc")
	w.body.position = Vector2(372, 128)  # za krzesłem
	await shot("pokoj_noc")
	Game.journal.append({"uid": 99, "id": "kasjopeja", "name": "Kasjopeja", "cat": "const", "quality": 92, "base": 25.0, "day": 1, "sold": false})
	Game.analysis.uids.append(99)  # raport poranny do podsumowania
	Game.parcels = ["statyw"]  # nieodebrana paczka otwiera się przy śnie
	for r in Game.SHOP.slice(0, 12):  # dużo zakupów: lista podsumowania się przewija
		Game.today.bought = Game.today.get("bought", []) + [["Zakup: " + r[1], r[2], "$"]]
	w._sleep()
	await get_tree().create_timer(2.5).timeout  # kwoty nabijają się
	await shot("podsumowanie")
	w.top.get_child(w.top.get_child_count() - 1).queue_free()
	w._sky_anim(true, func(): pass)
	await get_tree().create_timer(3.2).timeout
	await shot("swit")
	w.dusk_o.queue_free()
	Game.tutorial(w, "shop")
	await tut_pages(w, "shop")
	w.busy = false
	w._enter("room", true)
	w._apply_phase(true)
	w.body.position = Vector2(380, 160)
	await shot("pokoj_dzien")
	w._interact("komputer")
	w.viewport._close_app()
	await shot("os_pulpit")
	for id in ["dziennik", "gielda", "sklep", "badania", "pomoc"]:
		if id == "badania":  # jak na zrzucie autora: dwa węzły kupione, szara gałąź biegnie tym samym odcinkiem
			Game.science.stab1 = true
			Game.science.stab2 = true
		w.viewport._launch(id)
		if id == "gielda" and not Game.stored().is_empty():  # podgląd okazyjnej oferty
			Game.offer = {"uid": Game.stored()[0].uid, "who": "Instytut Astronomii w Gwiaździnie", "price": 45}
			w.viewport._rebuild()
		if id == "badania":
			w.viewport.hover = 4
		await shot("os_" + id)
		if id == "dziennik":
			w.viewport.jpage = 2
			w.viewport._rebuild()
			await shot("os_dziennik_dzien1")
		if id == "badania":
			w.viewport.hover = -1
			w.viewport.stage_hover = 1
			await shot("os_badania_etap")
	w.viewport.close()
	await get_tree().create_timer(0.3).timeout
	w._say("Kiedyś narysuję własną mapę nieba.")
	w._toast("Rozpakowano: Używany Statyw Drewniany", "good")
	w._toast("Rozpakowano: Modem Dial-Up 56k", "good")
	await shot("monolog")
	Game.night = true
	Game.rain = true
	w._enter("balcony", true)
	w._apply_phase(true)
	w._refresh()
	await shot("deszcz")
	# burza, Newton i parasol na balkonie, potem okular w burzy
	Game.storm = true
	Game.shop["newton"] = true
	Game.shop["parasol"] = true
	w._refresh()
	w.flash_next = 0.62  # piorun tuż przed zrzutem (shot czeka 0,7 s)
	await shot("burza_balkon")
	w._interact("teleskop")
	await get_tree().create_timer(1.0).timeout
	await shot("burza_okular")
	w.viewport.close()
	await get_tree().create_timer(0.4).timeout
	Game.shop.erase("parasol")
	Game.shop["czyszczacy"] = true
	w._interact("teleskop")
	await get_tree().create_timer(1.0).timeout
	await shot("burza_okular_bez_parasola")
	w.viewport.close()
	await get_tree().create_timer(0.4).timeout
	w._enter("room", true)  # burza widziana z pokoju: błysk i piorun w szybach
	w._apply_phase(true)
	w._refresh()
	w.flash_next = 0.62  # piorun tuż przed zrzutem (shot czeka 0,7 s)
	await shot("burza_pokoj")
	Game.storm = false
	Game.shop.erase("newton")
	Game.shop.erase("czyszczacy")
	# pokój: monitor LCD, paczka w dymie po wyjściu z komputera
	Game.night = false
	Game.rain = false
	Game.shop["lcd"] = true
	w._enter("room", true)
	w._apply_phase(true)
	w._refresh()
	w._interact("komputer")  # AstroOS XP: bogatsza tapeta i ikony
	await get_tree().create_timer(0.6).timeout
	await shot("os_xp_pulpit")
	w.viewport.close()
	await get_tree().create_timer(0.4).timeout
	Game.parcels.append("statyw")
	Game.arriving = true
	w._parcel_arrives()
	await get_tree().create_timer(0.95).timeout  # kłąb gęsty, paczki jeszcze nie ma
	await shot("paczka_dym")
	await get_tree().create_timer(0.9).timeout
	await shot("paczka_dym2")
	Game.shop.erase("lcd")
	Game.parcels.clear()
	w._refresh()
	w.yawned = false
	w._yawn()
	await get_tree().create_timer(0.3).timeout
	await shot("ziewanie")
	Game.rain = false
	Game.night = false
	w._enter("room", true)
	w._apply_phase(true)
	w._refresh()
	w._toggle_phase()
	await get_tree().create_timer(1.8).timeout
	await shot("zmierzch")
	await get_tree().create_timer(2.0).timeout
	await shot("noc_kontynuuj")
	Game.quit()
