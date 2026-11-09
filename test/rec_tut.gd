extends Node
# Nagrania do samouczków (game/art/tut/*.png) z prawdziwego renderu gry: klatki 320x180 obok siebie.
# Uruchamiać na komputerze z GPU (headless nie renderuje). Kursor AstroOS dorysowany (systemowego nie widać w nagraniu).
var frames := []
var arrow: Image


func screen() -> Image:
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func cursor(img: Image, p: Vector2, click := false) -> void:
	img.blend_rect(arrow, Rect2i(Vector2i.ZERO, arrow.get_size()), Vector2i(p))
	if click:  # błysk kliknięcia
		for a in 16:
			var q := Vector2i(p + Vector2.from_angle(a * TAU / 16) * 7)
			if Rect2i(Vector2i.ZERO, img.get_size()).has_point(q):
				img.set_pixelv(q, Color(1, 0.95, 0.6))


## klatka z kadru r; cur w współrzędnych ekranu
func grab(r: Rect2i, wait := 0.1, cur = null, click := false) -> void:
	await get_tree().create_timer(wait).timeout
	var img := screen().get_region(r)
	if cur != null:
		cursor(img, cur - Vector2(r.position), click)
	frames.append(img)


func glide(r: Rect2i, a: Vector2, b: Vector2, n := 8) -> void:
	for i in n:
		await grab(r, 0.08, a.lerp(b, (i + 1.0) / n))


func save(file: String) -> void:
	var out := Image.create(320 * frames.size(), 180, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		out.blit_rect(frames[i], Rect2i(0, 0, 320, 180), Vector2i(i * 320, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://game/art/tut"))
	out.save_png("res://game/art/tut/%s.png" % file)
	print("saved ", file, " frames ", frames.size())
	frames.clear()


func crop_at(p: Vector2) -> Rect2i:
	var c := (p - Vector2(160, 90)).round().clamp(Vector2.ZERO, Vector2(320, 180))
	return Rect2i(Vector2i(c), Vector2i(320, 180))


func button(os: Node, txt: String) -> Button:
	return os.body.find_children("*", "Button", true, false).filter(func(b): return b.text == txt)[0]


## Jania idzie (symulowane klawisze), aż warunek będzie spełniony
func walk(w: Node, r: Rect2i, actions: Array, done: Callable) -> void:
	for a in actions:
		Input.action_press(a)
	for i in 40:
		await grab(r)
		if done.call(w.body.position):
			break
	for a in actions:
		Input.action_release(a)


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor"]:  # samouczki nie zasłaniają nagrania
		Game.tips[k] = true
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
	# 3b) trudny początek: rozmyte obiekty, brudna, pęknięta soczewka
	tel.state = tel.S.SCAN
	tel.target = {}
	var open_t: Array = tel.targets.filter(func(x): return not x.done)
	tel.cam = open_t[0].pos + Vector2(40, 10) if not open_t.is_empty() else tel.cam
	tel.aim = tel.C + Vector2(30, 40)
	tel._mouse_aim = tel.aim
	for i in 12:
		await grab(Rect2i(160, 90, 320, 180))
	save("tel_hard")
	# 3c) meteory: przelatuje meteor, celownik na nim, złapany
	Game.science["meteory"] = true
	var mpos: Vector2 = tel.C + Vector2(60, -20)
	tel.meteor = {"pos": tel.to_sky(mpos + Vector2(-120, -60)), "vel": Vector2(120, 60) / tel.zoom, "t": 0.0}
	var rm := Rect2i(160, 90, 320, 180)
	for i in 10:
		tel._mouse_aim = (tel.C + Vector2(-40, 30)).lerp(tel.to_screen(tel.meteor.pos), (i + 1) / 10.0)
		await grab(rm, 0.07)
	tel.aim = tel.to_screen(tel.meteor.pos)
	tel._mouse_aim = tel.aim
	tel._lock_or_confirm()
	for i in 10:
		await grab(rm)
	save("meteor1")
	# 3d) w trakcie łączenia gwiazd: PPM wychodzi, meteor złapany, powrót do konstelacji z zachowanymi gwiazdami
	var c2: Array = tel.targets.filter(func(x): return x.info.has("pts") and not x.done)
	if not c2.is_empty():
		var tc: Dictionary = c2[0]
		tel.cam = tc.pos
		tel.target = tc
		tel.f = tc.sweet
		tel.lit = {0: true, 1: true}
		tel.state = tel.S.CONNECT
		for i in 6:
			await grab(rm)
		tel._leave()
		tel.meteor = {"pos": tel.to_sky(tel.C + Vector2(-140, 40)), "vel": Vector2(110, -40) / tel.zoom, "t": 0.0}
		for i in 8:
			tel._mouse_aim = tel.aim.lerp(tel.to_screen(tel.meteor.pos), (i + 1) / 8.0)
			await grab(rm, 0.07)
		tel.aim = tel.to_screen(tel.meteor.pos)
		tel._mouse_aim = tel.aim
		tel._lock_or_confirm()
		for i in 6:
			await grab(rm)
		tel.aim = tel.to_screen(tc.pos)
		tel._mouse_aim = tel.aim
		for i in 4:
			await grab(rm)
		tel._lock_or_confirm()  # wraca do konstelacji: dwie gwiazdy dalej połączone
		for i in 8:
			await grab(rm)
	save("meteor2")
	Game.science.erase("meteory")
	tel.close()
	await get_tree().create_timer(0.5).timeout
	# 4) pokój: Jania podchodzi do komputera i go włącza
	w._enter("room", true)
	w.busy = false
	for e in [["Kasjopeja", "const", 92], ["Lew", "zodiac", 74]]:
		Game._id_seq += 1
		Game.journal.append({"uid": Game._id_seq, "id": "x", "name": e[0], "cat": e[1], "quality": e[2], "base": 30.0, "day": Game.day, "sold": false})
	w.body.position = Vector2(420, 250)
	await get_tree().create_timer(0.3).timeout
	var rw := crop_at(Vector2(390, 180))
	await walk(w, rw, ["move_up", "move_left"], func(p): return p.y < 170)
	for i in 6:
		await grab(rw)
	w._interact("komputer")
	for i in 10:  # włączony komputer: pulpit z ikonami (lewa górna część ekranu)
		await grab(Rect2i(0, 0, 320, 180))
	save("pc_walk")
	var os = w.viewport
	# 5) pulpit: kursor na Giełdę
	var rd := Rect2i(0, 22, 320, 180)
	await glide(rd, Vector2(220, 170), Vector2(56, 120), 10)
	await grab(rd, 0.1, Vector2(56, 120), true)
	Game.tips.chart = {"moon": true}
	os._launch("gielda")
	for i in 8:
		await grab(rd, 0.1, Vector2(56, 120))
	save("pc_desk")
	# 6) legenda: kursor zaznacza drugą kategorię (samo klikanie, osobno od wykresu)
	var box: CheckBox = os.legend_rows.filter(func(row): return row[1] == "zodiac")[0][0]
	var at: Vector2 = box.global_position + Vector2(40, 10)
	var rl := Rect2i(0, 180, 320, 180)
	await glide(rl, Vector2(150, 330), at, 8)
	box.button_pressed = true
	await grab(rl, 0.1, at, true)
	for i in 4:
		await grab(rl, 0.1, at)
	for i in 12:  # kamera jedzie od legendy do wykresu po prawej
		var k := (1.0 - cos(PI * (i + 1) / 12.0)) / 2.0
		await grab(Rect2i(roundi(314 * k), 180, 320, 180), 0.08, at)
	for i in 10:
		await grab(Rect2i(314, 180, 320, 180))
	save("pc_chart")
	# 7) sprzedaż: wiersze (góra) + suma i przyciski (dół), Zaznacz wszystkie, potem WYŚLIJ RAPORT
	var sell := func(cur: Vector2, click := false) -> void:
		await get_tree().create_timer(0.1).timeout
		var img := screen()
		var pic := Image.create(320, 180, false, Image.FORMAT_RGBA8)
		pic.fill(img.get_pixel(300, 150))
		pic.blit_rect(img, Rect2i(0, 80, 280, 64), Vector2i(4, 0))
		pic.blit_rect(img, Rect2i(448, 62, 184, 116), Vector2i(68, 64))
		cursor(pic, cur - Vector2(448, 62) + Vector2(68, 64), click)
		frames.append(pic)
	var all_b := button(os, "Zaznacz wszystkie").get_global_rect().get_center()
	var send_b := button(os, "WYŚLIJ RAPORT").get_global_rect().get_center()
	for i in 6:
		await sell.call(Vector2(470, 180).lerp(all_b, (i + 1) / 6.0))
	button(os, "Zaznacz wszystkie").pressed.emit()
	await sell.call(all_b, true)
	for i in 5:
		await sell.call(all_b)
	for i in 5:
		await sell.call(all_b.lerp(send_b, (i + 1) / 5.0))
	await sell.call(send_b, true)  # nagranie kończy się na kliknięciu WYŚLIJ RAPORT
	button(os, "WYŚLIJ RAPORT").pressed.emit()
	save("pc_sell")
	# 8) Badania: pulpit, kursor na ikonę, drzewko, odblokowanie umiejętności
	os._close_app()
	Game.pw = 60
	var rb := Rect2i(0, 180, 320, 180)
	await glide(rb, Vector2(220, 300), Vector2(56, 250), 8)
	await grab(rb, 0.1, Vector2(56, 250), true)
	os._launch("badania")
	var rt := Rect2i(160, 42, 320, 180)
	var node_i: int = range(os.nodes.size()).filter(func(i): return os.nodes[i][1][0] == "nawyk1")[0]
	var node_p: Vector2 = os.nodes[node_i][0] + Vector2(0, 42)  # body drzewka zaczyna się 42 px niżej
	await glide(rt, Vector2(400, 200), node_p, 8)
	for i in 4:
		await grab(rt, 0.1, node_p)
	os.hover = node_i
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	os._tree_input(ev)
	os.hover = -1
	await grab(rt, 0.1, node_p, true)
	for i in 10:
		await grab(rt, 0.1, node_p)
	save("pc_tree")
	# 9) sklep: ikona Retro-Tech, KUP, paczka w pokoju
	os._close_app()
	Game.money = 100
	var rs := Rect2i(0, 100, 320, 180)
	await glide(rs, Vector2(220, 260), Vector2(56, 186), 8)
	await grab(rs, 0.1, Vector2(56, 186), true)
	os.shop_cat = 0
	os._launch("sklep")
	for i in 6:
		await grab(rs, 0.1, Vector2(56, 186))
	save("shop_desk")
	var rk := Rect2i(110, 46, 320, 180)
	var kup: Vector2 = button(os, "KUP").get_global_rect().get_center()
	await glide(rk, Vector2(330, 200), kup, 8)
	button(os, "KUP").pressed.emit()
	await grab(rk, 0.1, kup, true)
	for i in 12:
		await grab(rk, 0.1, kup)
	save("shop_buy")
	os.close()  # kurier puka, paczka pojawia się w kłębie dymu
	var rp := crop_at(Vector2(330, 200))
	for i in 14:
		await grab(rp)
	await walk(w, rp, ["move_down", "move_left"], func(_p): return w._nearest() == "paczka")
	for i in 5:
		await grab(rp)
	w._interact("paczka")
	for i in 14:
		await grab(rp)
	save("shop_parcel")
	Game.quit()
