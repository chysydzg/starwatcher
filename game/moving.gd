extends "res://game/cutscene.gd"
## Przeprowadzka (koniec Etapu 1, GDD 12 „Pierwszy Duży Krok”): pokój i pakowanie, psy z U-Howl (Lili i Myszka)
## pukają i rozmawiają z Janią, ciężarówka jedzie wokół jeziora o zachodzie, plac pod starym szarym budynkiem,
## remont w szybkich ujęciach (co ujęcie inna pora dnia, raz deszcz), żuraw wstawia teleskop, finał nocą z szyldem.
## Korzysta z narzędzi intro (cutscene.gd): sceny w `sc`, efekty w `fx`, dialogi, pomijanie przytrzymaniem.

const TRUCK_Y := 176.0                 # ten sam brzeg co wywrotka z intro (dół kół na linii jeziora)
const VIEW_CAM := Vector2(190, 168)    # zoom 2: cały budynek z odbiciem w wodzie, żuraw mieści się w kadrze
const REPAIR_AT := Vector2(147, 162)   # cut_repair_k (repair.js) leży dokładnie na szarym budynku z balcony_view
const SIGN_AT := Vector2(236, 174)     # szyld na dwóch słupkach na brzegu, na prawo od budynku
## pora dnia: niebo (góra, dół), mnożnik koloru widoku, kolor odbicia w wodzie, słońce (x, y; 0 = brak)
const TOD := {
	"dawn": [Color("4a4a8a"), Color("f0a8a0"), Color(1.2, 1.0, 1.05), Vector3(0.35, 0.3, 0.45), Vector2(70, 120)],
	"noon": [Color("78a8e0"), Color("c8e0f4"), Color(1.9, 2.0, 1.7), Vector3(0.45, 0.62, 0.8), Vector2(300, 40)],
	"rain": [Color("4a5060"), Color("8a909e"), Color(1.25, 1.3, 1.35), Vector3(0.3, 0.34, 0.4), Vector2.ZERO],
	"sunset": [Color("3a2a6a"), Color("f4a060"), Color(1.25, 0.95, 0.82), Vector3(0.4, 0.28, 0.3), Vector2(330, 120)],
	"dusk": [Color("141838"), Color("5a3e70"), Color(0.95, 0.9, 1.05), Vector3(0.18, 0.16, 0.3), Vector2.ZERO],
	"night": [Color("060814"), Color("1a1e40"), Color.WHITE, Vector3(0.11, 0.15, 0.3), Vector2.ZERO],
}
var truck_x := -80.0                   # lewy brzeg ciężarówki (scena drogi i placu)
var truck_moving := false
var tint := Color.WHITE                # mnożnik koloru bieżącej pory dnia (ciężarówka, żuraw)
var puffs := []                        # spaliny: [pozycja wylotu w chwili wydmuchu, czas]


func _ready() -> void:
	add_child(cam)
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	fade.color = Color.BLACK
	Game.cover(fade)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)
	skip_ui.draw.connect(_draw_skip)
	ui.add_child(skip_ui)
	fx.draw.connect(func(): if fx_draw.is_valid(): fx_draw.call())
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	Game.loop("music/moving", -8.0, "Music")  # utwór autora (moving_out.mp3), zmasterowany na -16 LUFS jak pozostałe
	_run()


func _run() -> void:
	for build in [_pack, _road, _site, _repair, _finale]:
		sc = Node2D.new()
		add_child(sc)
		move_child(sc, 0)
		st = 0.0
		_cues.clear()
		mirror_extra = []
		truck_moving = false
		puffs.clear()
		await build.call()
		await create_tween().tween_property(fade, "color:a", 1.0, 0.6).finished
		if fx.is_inside_tree():
			remove_child(fx)
		sc.queue_free()
		tick = Callable()
		fx_draw = Callable()
	_end()


func _show() -> void:
	add_child(fx)
	await create_tween().tween_property(fade, "color:a", 0.0, 0.8).finished


func _say_lines(lines: Array, on_line := Callable()) -> void:
	var d = preload("res://game/dialogue.gd").new().play(lines)
	if on_line.is_valid():
		d.line_shown.connect(on_line)
	add_child(d)
	await d.finished


## psy: arkusz 10x3 klatek 44x64 (dogs.js), stopy na `foot`. Przód: machanie 0-3, chód 4-5, karton 6, karton-chód 7-8;
## bok +10: machanie 10-13, chód 14-17, karton-chód 18-19; tył +20: machanie 20-23, chód 24-25
const WAG_SEQ := [0, 1, 2, 3, 2, 1]
func _dog(name: String, x: float, foot: float, sorter: Node2D) -> Sprite2D:
	var s := _spr("cut_" + name, Vector2.ZERO, sorter, 10)
	s.vframes = 3
	s.offset = Vector2(-4, -64)
	s.position = Vector2(x, foot)
	s.set_meta("walking", false)
	s.set_meta("carry", false)
	return s


## stojący pies macha ogonem (z kartonem w łapach stoi spokojnie)
func _idle(s: Sprite2D, phase: float) -> void:
	if not s.get_meta("walking"):
		s.frame = 6 if s.get_meta("carry") else WAG_SEQ[int((st + phase) * 9.0) % WAG_SEQ.size()]


## idzie do `to`: w górę ekranu tyłem do kamery, w dół przodem, w bok profilem; na miejscu staje przodem
func _walk(s: Sprite2D, to: Vector2, speed: float, carry := false) -> void:
	var from := s.position
	s.set_meta("walking", true)
	s.set_meta("carry", carry)
	var tw := create_tween()
	var dur := from.distance_to(to) / speed
	tw.tween_method(func(u: float):
		s.position = from.lerp(to, u).floor()
		var side := absf(to.x - from.x) > absf(to.y - from.y)
		var k := int(u * dur * 8.0)
		if side:
			s.flip_h = to.x < from.x
			s.frame = (18 + k % 2) if carry else 14 + k % 4
		elif to.y < from.y:
			s.frame = 24 + k % 2
		else:
			s.frame = (7 + k % 2) if carry else 4 + k % 2
		if k % 2 == 0 and _cue("st%d_%d" % [s.get_instance_id(), k], 0.0):
			Game.sfx("step%d" % (k % 4), randf_range(1.2, 1.4), -18.0), 0.0, 1.0, dur)
	await tw.finished
	s.set_meta("walking", false)
	s.flip_h = false


# ---------------------------------------------------------------- 1. pokój: pakowanie, psy z U-Howl pukają
func _pack() -> void:
	var so := _room()
	for p in [[Vector2(250, 250)], [Vector2(274, 262)], [Vector2(230, 270)], [Vector2(420, 250)]]:  # kartony do wyniesienia
		var b := _spr("parcel", p[0], so)
		b.offset = Vector2(0, -19)
	var lug := _spr("luggage", Vector2(504, 334), so)
	lug.offset = Vector2(0, -40)
	var j := _spr("jania", Vector2(310, 262), so, 8)
	j.vframes = 3
	j.offset = Vector2(0, -54)
	var haha := _spr("cut_haha", Vector2(320, 194))  # nad głową Jani, nad meblami
	haha.visible = false
	var lili := _dog("lili", 330, 420, so)
	var mysz := _dog("myszka", 372, 420, so)
	_cam(Vector2(330, 250))  # postacie w górnej połowie kadru: dół zasłania okienko dialogu
	tick = func():
		j.frame = 6 if haha.visible else 7 if fmod(st, 2.6) > 1.5 else 0
		haha.position.y = 194.0 - (1.0 if fmod(st, 0.3) < 0.15 else 0.0)  # śmiech podskakuje
		_idle(lili, 0.0)
		_idle(mysz, 0.4)
	await _show()
	await get_tree().create_timer(0.8).timeout
	Game.sfx("knock")
	await get_tree().create_timer(1.0).timeout
	_walk(lili, Vector2(350, 266), 46.0)
	await _walk(mysz, Vector2(392, 270), 40.0)
	await _say_lines([
		{"who": "myszka", "text": "Jestem Myszka, a to Lili! Nie przejmuj się nią, to nasz rodzinny głupol!"},
		{"who": "lili", "text": "Sama jesteś głupol!"},
		{"who": "jania_laugh", "text": "Haha, przesłodkie jesteście! Jestem Jania, wszystko już spakowane. Proszę tylko ostrożnie z teleskopem!"},
		{"who": "myszka", "text": "Pani będzie spokojna, damy radę! Nie takie rzeczy się woziło!"},
		{"who": "lili", "text": "I gdzie z tym jedziemy?"},
		{"who": "jania", "text": "Na drugą stronę jeziora. Do starego obserwatorium."},
	], func(l: Dictionary): haha.visible = l.who == "jania_laugh")
	for b in so.get_children():  # psy biorą kartony
		if b is Sprite2D and b.texture == Game.tex("parcel"):
			b.visible = false
	lili.set_meta("carry", true)  # psy biorą kartony: stoją z nimi chwilę
	mysz.set_meta("carry", true)
	Game.sfx("paper", 1.0, -10.0)
	await get_tree().create_timer(0.5).timeout
	_walk(lili, Vector2(350, 420), 50.0, true)
	await _walk(mysz, Vector2(392, 420), 46.0, true)


# ---------------------------------------------------------------- 2. droga wokół jeziora o zachodzie
func _road() -> void:
	_scenery(sc, "sunset")
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(250, 150)
	truck_x = -90.0
	truck_moving = true
	tick = func(): truck_x = -90.0 + st * 34.0
	fx_draw = _draw_truck
	Game.sfx("truck_drive", 1.0, -8.0)
	await _show()
	await get_tree().create_timer(6.5).timeout


# ---------------------------------------------------------------- 3. plac: stary szary budynek z kopułą
func _site() -> void:
	_scenery(sc, "sunset")
	_cam(Vector2(210, 200))  # budynek nad okienkiem dialogu
	truck_x = 120.0
	tick = func():
		truck_moving = st < 2.4
		truck_x = 120.0 + 106.0 * smoothstep(0.0, 2.4, st)  # dojeżdża i staje przy budynku
	fx_draw = _draw_truck
	await _show()
	await get_tree().create_timer(2.6).timeout
	await _say_lines([
		{"who": "myszka", "text": "Na pewno tutaj? Ten budynek się rozpada."},
		{"who": "jania", "text": "Tak, na pewno. To stare obserwatorium mojego ojca. Chcę je odbudować."},
		{"who": "lili", "text": "No to do roboty! Chętnie pomożemy!"},
	])


# ---------------------------------------------------------------- 4. remont: szybkie ujęcia przez czerń, co ujęcie inna pora
## dnia (raz pada), coraz mniej desek, biała farba, okna, drzwi; na końcu żuraw opuszcza teleskop w kopułę
const SHOTS := [["dawn", 0], ["noon", 1], ["rain", 2], ["sunset", 3], ["dusk", 4], ["night", 5]]
var shot_t := 0.0
var next_hit := 0.0
var hammering := false
func _repair() -> void:
	_cam(VIEW_CAM)
	Game.loop("site_work", -6.0)
	tick = func():
		shot_t += get_process_delta_time()
		if hammering and shot_t > next_hit:  # młotki w nierównym rytmie, czasem dwa szybko po sobie
			Game.sfx("hammer", randf_range(0.85, 1.15), randf_range(-4.0, 0.0))
			next_hit = shot_t + (0.14 if randf() < 0.25 else randf_range(0.3, 0.55))
	for i in SHOTS.size():
		var shot := Node2D.new()
		sc.add_child(shot)
		_scenery(shot, SHOTS[i][0], "cut_repair_%d" % SHOTS[i][1], REPAIR_AT)
		Game.loop("rain_balcony", -12.0 if SHOTS[i][0] == "rain" else -INF)
		shot_t = 0.0
		next_hit = 0.25
		hammering = i < 5
		if i == 0:
			await _show()
		else:
			await create_tween().tween_property(fade, "color:a", 0.0, 0.25).finished
		await get_tree().create_timer(1.6).timeout
		await create_tween().tween_property(fade, "color:a", 1.0, 0.25).finished
		shot.queue_free()
	hammering = false
	var shot := Node2D.new()  # noc: żuraw opuszcza teleskop w otwartą kopułę
	sc.add_child(shot)
	_scenery(shot, "night", "cut_repair_5", REPAIR_AT)
	_spr("cut_crane", Vector2(88, 80), shot).modulate = Color(0.78, 0.78, 0.9)
	shot_t = 0.0
	fx_draw = _draw_crane
	await create_tween().tween_property(fade, "color:a", 0.0, 0.25).finished
	await get_tree().create_timer(4.4).timeout
	Game.loop("site_work", -INF)


## hak żurawia nad kopułą (x 187) opuszcza wiszący teleskop aż do szczeliny
func _draw_crane() -> void:
	var tx := 187.0
	var hy := lerpf(110.0, 146.0, smoothstep(0.4, 3.4, shot_t))
	var dim := Color(0.78, 0.78, 0.9)
	var dark := Color(0.12, 0.12, 0.16)
	var at := Vector2(tx - 17, hy + 5).floor()
	fx.draw_rect(Rect2(tx - 3, 102, 7, 2), dark)                      # wózek pod wysięgnikiem
	fx.draw_line(Vector2(tx, 104), Vector2(tx, hy), dark, 1.0)        # lina
	fx.draw_rect(Rect2(tx - 2, hy, 5, 3), Color(0.66, 0.5, 0.16))     # zblocze haka
	fx.draw_line(Vector2(tx, hy + 3), at + Vector2(8, 4), dark, 1.0)  # zawiesia
	fx.draw_line(Vector2(tx, hy + 3), at + Vector2(27, 3), dark, 1.0)
	fx.draw_texture(Game.tex("cut_scope"), at, dim)
	mirror_extra = [[Game.tex("cut_crane"), Rect2(), Vector2(88, 80), dim], [Game.tex("cut_scope"), Rect2(), at, dim]]
	if _cue("clank", 3.4):  # teleskop siada w kopule
		Game.sfx("clank", 1.0, -10.0)


# ---------------------------------------------------------------- 5. finał: noc, teleskop na miejscu, szyld „OBSERWATORIUM”
func _finale() -> void:
	_scenery(sc, "night", "cut_repair_6", REPAIR_AT - Vector2(0, 12))
	var board := _spr("cut_sign", SIGN_AT, null, 3)
	mirror_extra = [[board.texture, Rect2(0, 0, 118, 34), SIGN_AT]]
	_cam(Vector2(248, 200))  # budynek i szyld nad okienkiem dialogu, pod nimi odbicie
	tick = func():  # szyld łapie po kilku mrugnięciach, potem żarówki migają na zmianę
		var on := st > 2.4 or (st > 1.2 and fmod(st, 0.33) < 0.18)
		board.frame = (1 + int(st * 3.0) % 2) if on else 0
		mirror_extra[0][1] = Rect2(board.frame * 118, 0, 118, 34)
		if _cue("buzz", 1.2):
			Game.sfx("switch", 1.0, -8.0)
	await _show()
	await get_tree().create_timer(3.4).timeout
	await _say_lines([
		{"who": "lili", "text": "I elegancko! Wszystko działa! Wooof!"},
		{"who": "myszka", "text": "Powodzenia, Jania! Pamiętaj, że na nas możesz liczyć! Auuuuuuuuuu!"},
		{"who": "jania", "text": "Dziękuję Wam! Tata byłby ze mnie dumny..."},
	])
	await get_tree().create_timer(1.0).timeout


## widok przez jezioro o danej porze dnia: niebo, słońce, gwiazdy; widok z szarym budynkiem (balcony_view)
## albo bez niego (balcony_view_cut) z budynkiem `building` w `at`; odbicie budynku i mirror_extra w wodzie
func _scenery(parent: Node, tod: String, building := "", at := Vector2.ZERO) -> void:
	var d: Array = TOD[tod]
	tint = d[2]
	var sky := Node2D.new()
	sky.draw.connect(func():
		for i in 16:
			sky.draw_rect(Rect2(-320, i * 14 - 40, 1280, 14), (d[0] as Color).lerp(d[1], i / 15.0))
		var sun: Vector2 = d[4]
		if sun != Vector2.ZERO:
			sky.draw_circle(sun, 26, Color(1, 0.85, 0.6, 0.3))
			sky.draw_circle(sun, 13, Color("ffe0a0") if tod != "noon" else Color("fff2c0"))
		if tod in ["sunset", "dusk"]:  # pierwsze gwiazdy pojawiają się powoli
			for i in 24:
				var p := Vector2((i * 97) % 600 + 20, (i * 37) % 90 + 6)
				sky.draw_rect(Rect2(p, Vector2.ONE), Color(1, 0.96, 0.85, clampf(st * 0.15 - i * 0.02 + (0.6 if tod == "dusk" else 0.0), 0.0, 0.8))))
	parent.add_child(sky)
	if tod == "night":
		parent.add_child(preload("res://game/sky_fx.gd").new())  # gwiazdy jak z balkonu
	var view := _spr("balcony_view" if building.is_empty() else "balcony_view_cut", Vector2.ZERO, parent)
	view.modulate = tint
	var items := func(): return mirror_extra
	if not building.is_empty():
		var b := _spr(building, at, parent)
		b.modulate = tint
		items = func(): return [[b.texture, Rect2(), at, tint]] + mirror_extra
	_mirror(parent, items, d[3])
	if tod == "rain":
		var rain = preload("res://game/sky_fx.gd").new()
		rain.raining = true
		rain.front = true
		parent.add_child(rain)


## ciężarówka U-Howl z obracającymi się kołami (cut_wheel), spalinami z rury z tyłu i odbiciem w jeziorze
func _draw_truck() -> void:
	var pos := Vector2(floorf(truck_x), TRUCK_Y + (1.0 if truck_moving and fmod(st, 0.2) < 0.1 else 0.0))
	_draw_exhaust_puffs(pos + Vector2(0, 26), 0.12 if truck_moving else 0.3)
	fx.draw_texture(Game.tex("cut_uhowl"), pos, tint)
	var wf := int(truck_x / 2.43) % 4 if truck_moving else 0
	mirror_extra = [[Game.tex("cut_uhowl"), Rect2(), pos, tint]]
	for wx in [7, 41]:
		var src := Rect2(wf * 15, 0, 15, 15)
		fx.draw_texture_rect_region(Game.tex("cut_wheel"), Rect2(pos + Vector2(wx, 18), Vector2(15, 15)), src, tint)
		mirror_extra.append([Game.tex("cut_wheel"), src, pos + Vector2(wx, 18), tint])


## spaliny z małej rury z tyłu: pikselowe kłęby (bez półprzezroczystości) zostają w powietrzu tam, gdzie wyleciały,
## dryfują w lewo i w górę, rosną, jaśnieją i rozpadają się w kratkę
func _draw_exhaust_puffs(pipe: Vector2, every: float) -> void:
	if puffs.is_empty() or st - puffs[-1][1] >= every:
		puffs.append([pipe, st])
	puffs = puffs.filter(func(p): return st - p[1] < 1.2)
	for i in puffs.size():
		var age: float = st - puffs[i][1]
		var p: Vector2 = (puffs[i][0] + Vector2(-5.0 * age - 1.0 - (i % 3), -10.0 * age)).floor()
		var r := 1 if age < 0.2 else 2 if age < 0.6 else 3
		var c := Color8(70, 70, 80) if age < 0.25 else Color8(104, 104, 114) if age < 0.7 else Color8(136, 136, 146)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) + absi(dy) > r + (1 if r > 1 else 0):
					continue  # zaokrąglone rogi kłębu
				if age > 0.9 and (dx + dy) % 2 != 0:
					continue  # rozpada się w kratkę
				fx.draw_rect(Rect2(p + Vector2(dx, dy), Vector2.ONE), c * Color(tint.r, tint.g, tint.b, 1.0))


func _end() -> void:
	if ended:
		return
	ended = true
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	Game.hush()  # muzyka, plac budowy i deszcz (także przy pominięciu)
	Game.stage_done = true
	Game.save_game()
	var ui := CanvasLayer.new()
	ui.layer = 30
	add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	Game.cover(bg)
	ui.add_child(bg)
	var l := Label.new()
	l.text = "PIERWSZY DUŻY KROK\n\nKoniec Etapu 1.\nEtap 2: Małe Centrum Naukowe, wkrótce."
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(640, 120)
	l.position = Vector2(0, 120)
	ui.add_child(l)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var b := Button.new()
	b.text = "DO MENU"
	b.position = Vector2(280, 250)
	b.pressed.connect(func(): get_tree().change_scene_to_file("res://game/menu.tscn"))
	ui.add_child(b)
	b.grab_focus.call_deferred()
