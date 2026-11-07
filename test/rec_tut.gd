extends Node
# Nagrania do samouczków (game/art/tut/*.png) z prawdziwego renderu gry: klatki 320x180 obok siebie.
# Uruchamiać na komputerze z GPU (headless nie renderuje).
var frames := []


func grab(r: Rect2i, wait := 0.1) -> void:
	await get_tree().create_timer(wait).timeout
	frames.append(get_viewport().get_texture().get_image().get_region(r))


func save(file: String) -> void:
	var out := Image.create(320 * frames.size(), 180, false, frames[0].get_format())
	for i in frames.size():
		out.blit_rect(frames[i], Rect2i(0, 0, 320, 180), Vector2i(i * 320, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://game/art/tut"))
	out.save_png("res://game/art/tut/%s.png" % file)
	print("saved ", file, " frames ", frames.size())
	frames.clear()


func crop_at(p: Vector2) -> Rect2i:
	var c := (p - Vector2(160, 90)).round().clamp(Vector2.ZERO, Vector2(320, 180))
	return Rect2i(Vector2i(c), Vector2i(320, 180))


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.tips.tut_tel = true  # samouczki nie zasłaniają nagrania
	Game.tips.tut_pc = true
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	w._enter("balcony", true)
	w._interact("teleskop")
	await get_tree().create_timer(0.6).timeout
	var tel = w.viewport
	# najmniejsza konstelacja: cała mieści się w kadrze
	var cands: Array = tel.targets.filter(func(x): return x.info.has("pts"))
	var spread := func(x):
		var sp: Array = tel.star_points(x)
		var lo: Vector2 = sp[0]
		var hi: Vector2 = sp[0]
		for p in sp:
			lo = lo.min(p)
			hi = hi.max(p)
		return (hi - lo).length()
	cands.sort_custom(func(a, b): return spread.call(a) < spread.call(b))
	var tg: Dictionary = cands[0]
	# 1) celownik podjeżdża do obiektu, drży, gracz namierza
	tel.cam = tg.pos - Vector2(60, 25)
	tel.aim = tel.C + Vector2(-70, -40)
	tel._mouse_aim = tel.aim
	var ts: Vector2 = tel.to_screen(tg.pos)
	var r := crop_at((tel.aim + ts) / 2.0)
	for i in 14:
		tel._mouse_aim = (tel.C + Vector2(-70, -40)).lerp(ts, (i + 1) / 14.0)
		await grab(r)
	for i in 12:
		await grab(r)
	tel._lock_or_confirm()
	for i in 6:
		await grab(r)
	save("tel1")
	# 2) ostrość: kółko prowadzi znacznik do zielonego pola, klik w dobrym momencie
	tel.target = tg
	tel.state = tel.S.FOCUS
	tel.f = tg.sweet + 0.16
	await get_tree().create_timer(0.6).timeout
	var r2 := Rect2i(160, 104, 320, 180)
	for i in 3:
		await grab(r2)
	for i in 8:
		tel.f -= tel.FOCUS_STEP
		Game.sfx("focus_tick")
		await grab(r2, 0.15)
	for i in 20:
		await grab(r2)
		if i > 4 and absf(tel.focus_offset()) < tel.green() * 0.6:
			break
	tel._lock_or_confirm()
	for i in 6:
		await grab(r2)
	save("tel2")
	# 3) łączenie gwiazd po kolei
	var pts: Array = tel.star_points(tel.target)
	var mid := Vector2.ZERO
	for p in pts:
		mid += p
	var r3 := crop_at(mid / pts.size())
	var prev: Vector2 = tel.aim
	for p in pts:
		for k in 5:
			tel.aim = prev.lerp(p, (k + 1) / 5.0)
			tel._mouse_aim = tel.aim
			await grab(r3, 0.08)
		tel.aim = p
		tel._click_star()
		await grab(r3)
		prev = p
	for i in 10:
		await grab(r3)
	save("tel3")
	tel.close()
	await get_tree().create_timer(0.5).timeout
	# 4) Giełda: zaznaczenie odkryć i WYŚLIJ RAPORT (wiersze + przycisk złożone w jeden kadr)
	w._enter("room", true)
	w.busy = false
	for e in [["Kasjopeja", "const", 92], ["Księżyc – pełnia", "moon", 80], ["Lew", "zodiac", 74]]:
		Game._id_seq += 1
		Game.journal.append({"uid": Game._id_seq, "id": "x", "name": e[0], "cat": e[1], "quality": e[2], "base": 30.0, "day": Game.day, "sold": false})
	w._interact("komputer")
	await get_tree().create_timer(0.6).timeout
	var os = w.viewport
	os._launch("gielda")
	for sel in [false, true]:
		for e in Game.stored():
			os.selected[e.uid] = sel
		os._rebuild()
		await get_tree().create_timer(0.4).timeout
		var img := get_viewport().get_texture().get_image()
		var pic := Image.create(320, 180, false, img.get_format())
		pic.fill(img.get_pixel(300, 150))  # tło okna Giełdy
		pic.blit_rect(img, Rect2i(0, 80, 280, 84), Vector2i(4, 0))  # zaznaczone odkrycia
		pic.blit_rect(img, Rect2i(448, 62, 184, 96), Vector2i(68, 84))  # suma i WYŚLIJ RAPORT
		for i in 8:
			frames.append(pic)
	save("pc1")
	# 5) Badania: dostępne umiejętności pulsują
	Game.pw = 60
	os._launch("badania")
	await get_tree().create_timer(0.4).timeout
	for i in 12:
		await grab(Rect2i(160, 42, 320, 180))
	save("pc2")
	os.close()
	Game.quit()
