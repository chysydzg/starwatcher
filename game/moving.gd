extends "res://game/cutscene.gd"
## Przeprowadzka (koniec Etapu 1, GDD 12 „Pierwszy Duży Krok”): pokój i pakowanie, psy z U-Howl (Lili i Myszka)
## pukają i rozmawiają z Janią, ciężarówka jedzie wokół jeziora o zachodzie, plac pod starym obserwatorium,
## remont (deski, młotki, skrzynie), finał nocą z neonem. Pierwsza wersja do poprawek z autorem.
## Korzysta z narzędzi intro (cutscene.gd): sceny w `sc`, efekty w `fx`, dialogi, pomijanie przytrzymaniem.

const TRUCK_Y := 176.0                 # ten sam brzeg co wywrotka z intro (dół kół na linii jeziora)
const SITE_CAM := Vector2(207, 151)    # zbliżenie na obserwatorium (zoom 3), jak w finale intro
const OBS := Vector2(146, 143)
const DUSK := Color(1.25, 0.95, 0.82)  # zachód słońca: cieplej
var truck_x := -80.0                   # lewy brzeg ciężarówki (scena drogi i placu)
var truck_moving := false


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


func _say_lines(lines: Array) -> void:
	var d = preload("res://game/dialogue.gd").new().play(lines)
	add_child(d)
	await d.finished


## psy w pokoju: arkusz 10x2 klatek 44x64 (dogs.js), stopy na `foot`. Przód: machanie 0-3, chód 4-5, karton 6,
## karton-chód 7-8; bok +10: machanie 10-13, chód 14-17, karton-chód 18-19
const WAG_SEQ := [0, 1, 2, 3, 2, 1]
func _dog(name: String, x: float, foot: float, sorter: Node2D) -> Sprite2D:
	var s := _spr("cut_" + name, Vector2.ZERO, sorter, 10)
	s.vframes = 2
	s.offset = Vector2(-4, -64)
	s.position = Vector2(x, foot)
	s.set_meta("walking", false)
	s.set_meta("carry", false)
	return s


## stojący pies macha ogonem (z kartonem w łapach stoi spokojnie)
func _idle(s: Sprite2D, phase: float) -> void:
	if not s.get_meta("walking"):
		s.frame = 6 if s.get_meta("carry") else WAG_SEQ[int((st + phase) * 9.0) % WAG_SEQ.size()]


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
	var lili := _dog("lili", 330, 420, so)
	var mysz := _dog("myszka", 372, 420, so)
	_cam(Vector2(330, 250))  # postacie w górnej połowie kadru: dół zasłania okienko dialogu
	tick = func():
		j.frame = 7 if fmod(st, 2.6) > 1.5 else 0
		_idle(lili, 0.0)
		_idle(mysz, 0.4)
	await _show()
	await get_tree().create_timer(0.8).timeout
	Game.sfx("knock")
	await get_tree().create_timer(1.0).timeout
	_walk(lili, Vector2(350, 266), 46.0)
	await _walk(mysz, Vector2(392, 270), 40.0)
	await _say_lines([
		{"who": "lili", "text": "Dzień dobry! U-Howl, przeprowadzki z pazurem!"},
		{"who": "myszka", "text": "Jestem Myszka, a to Lili. Ona zawsze tak wystawia język."},
		{"who": "lili", "text": "Bo lubię swoją pracę!"},
		{"who": "jania", "text": "Jania, miło mi. Wszystko spakowane. Tylko teleskop proszę bardzo ostrożnie."},
		{"who": "myszka", "text": "Spokojnie. Wieźliśmy już fortepian i jednego wielbłąda."},
		{"who": "lili", "text": "A dokąd jedziemy?"},
		{"who": "jania", "text": "Nad jezioro. Do starego budynku z kopułą."},
	])
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
	_dusk()
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(250, 150)
	truck_x = -90.0
	truck_moving = true
	tick = func(): truck_x = -90.0 + st * 34.0
	fx_draw = _draw_truck
	Game.sfx("truck_drive", 1.0, -8.0)
	await _show()
	await get_tree().create_timer(6.5).timeout


# ---------------------------------------------------------------- 3. plac: zaniedbany budynek z kopułą
func _site() -> void:
	_dusk()
	cam.zoom = Vector2(3, 3)
	cam.position = SITE_CAM
	truck_x = 120.0
	tick = func():
		truck_moving = st < 2.4
		truck_x = 120.0 + 106.0 * smoothstep(0.0, 2.4, st)  # dojeżdża i staje przy budynku
	fx_draw = _draw_truck
	await _show()
	await get_tree().create_timer(2.6).timeout
	await _say_lines([
		{"who": "myszka", "text": "To tutaj? Trochę tu... przewiewnie."},
		{"who": "jania", "text": "Tata zawsze mówił, że kiedyś będzie tu nasze obserwatorium."},
		{"who": "lili", "text": "No to do roboty! Deski, szyby, młotki!"},
	])


# ---------------------------------------------------------------- 4. remont: deski z okien, młotki, skrzynie, odnowiona kopuła
var obs_spr: Sprite2D
func _repair() -> void:
	_dusk()
	cam.zoom = Vector2(3, 3)
	cam.position = SITE_CAM
	truck_x = 226.0
	tick = func():
		for k in 6:  # stukanie młotkiem, nierówno
			if _cue("h%d" % k, 0.8 + k * 0.55 + (k % 2) * 0.2):
				Game.sfx("knock", randf_range(1.5, 1.9), -12.0)
		if _cue("open", 4.2):  # deski zdjęte, nowe szyby i kopuła
			obs_spr.texture = Game.tex("cut_observatory")
			Game.sfx("chimes", 1.0, -8.0)
	fx_draw = func():
		_draw_truck()
		_draw_workers()
		_draw_boards()
	await _show()
	await get_tree().create_timer(6.5).timeout


## malutkie postacie przy budynku: Lili (złota głowa), Myszka (czarna) i Jania (ruda) noszą skrzynie od ciężarówki
func _draw_workers() -> void:
	var door := 200.0
	var tr := truck_x + 8.0
	for i in 3:
		var u := fmod(st * 0.28 + i * 0.33, 1.0)
		var go := u < 0.5  # do budynku ze skrzynią, potem wraca
		var k := u * 2.0 if go else (1.0 - u) * 2.0
		var x := floorf(lerpf(tr, door, k))
		var y := 205.0 - (1.0 if int(st * 6.0 + i) % 2 == 0 else 0.0)
		var head: Color = [Color("c8a060"), Color("2a2c34"), Color("e07a3a")][i]
		fx.draw_rect(Rect2(x, y - 3, 2, 3), Color("e8743a") if i < 2 else Color("3a5a9a"))  # ogrodniczki
		fx.draw_rect(Rect2(x, y - 5, 2, 2), head)
		if go:
			fx.draw_rect(Rect2(x + (1 if tr > door else -2), y - 4, 3, 2), Color("c8a46a"))  # skrzynia


## deski odpadają z okien w pierwszych sekundach
func _draw_boards() -> void:
	for i in 5:
		var t0 := 0.9 + i * 0.6
		var a := st - t0
		if a < 0.0 or a > 1.0:
			continue
		var p := Vector2(176 + i * 9, 186 + 30.0 * a * a).floor()
		fx.draw_rect(Rect2(p, Vector2(4, 1)), Color("8a6a4a"))


# ---------------------------------------------------------------- 5. finał: noc, neon „OBSERWATORIUM”
func _finale() -> void:
	_balcony_night()
	cam.zoom = Vector2(3, 3)
	cam.position = SITE_CAM + Vector2(0, -8)
	var neon := _spr("cut_neon", Vector2(158, 128))
	neon.modulate.a = 0.0
	tick = func():  # neon łapie po kilku mrugnięciach
		var on := st > 2.4 or (st > 1.2 and fmod(st, 0.33) < 0.18)
		neon.modulate = Color(1.3, 1.1, 1.3, 1.0) if on else Color(0.5, 0.45, 0.6, 0.6 if st > 1.0 else 0.0)
		if _cue("buzz", 1.2):
			Game.sfx("switch", 1.0, -8.0)
	await _show()
	await get_tree().create_timer(3.4).timeout
	await _say_lines([
		{"who": "lili", "text": "Ojej. Świeci się!"},
		{"who": "myszka", "text": "Powodzenia, Jania. Jakby co, U-Howl przyjedzie znowu."},
		{"who": "jania", "text": "Dziękuję. Tato... udało się."},
	])
	await get_tree().create_timer(1.0).timeout


## zachód słońca nad jeziorem: ciepłe niebo, nisko słońce, pierwsze gwiazdy, widok z balkonu bez balkonu
func _dusk() -> void:
	var sky := Node2D.new()
	sky.draw.connect(func():
		for i in 16:
			sky.draw_rect(Rect2(-320, i * 14 - 40, 1280, 14), Color("3a2a6a").lerp(Color("f4a060"), i / 15.0))
		sky.draw_circle(Vector2(520, 196), 26, Color(1, 0.8, 0.5, 0.3))
		sky.draw_circle(Vector2(520, 196), 13, Color("ffd890"))
		for i in 24:  # pierwsze gwiazdy pojawiają się powoli
			var p := Vector2((i * 97) % 600 + 20, (i * 37) % 90 + 6)
			sky.draw_rect(Rect2(p, Vector2.ONE), Color(1, 0.96, 0.85, clampf(st * 0.15 - i * 0.02, 0.0, 0.8))))
	sc.add_child(sky)
	_spr("balcony_view_cut", Vector2.ZERO).modulate = DUSK
	obs_spr = _spr("cut_observatory_closed", OBS)  # zabity deskami, dopóki remont go nie otworzy
	obs_spr.modulate = DUSK
	_mirror(sc, func(): return [[obs_spr.texture, Rect2(), OBS, DUSK]] + mirror_extra, Vector3(0.4, 0.28, 0.3))


## ciężarówka U-Howl z obracającymi się kołami (cut_wheel) i odbiciem w jeziorze
func _draw_truck() -> void:
	var pos := Vector2(floorf(truck_x), TRUCK_Y + (1.0 if truck_moving and fmod(st, 0.2) < 0.1 else 0.0))
	fx.draw_texture(Game.tex("cut_uhowl"), pos, DUSK)
	var wf := int(truck_x / 2.43) % 4 if truck_moving else 0
	mirror_extra = [[Game.tex("cut_uhowl"), Rect2(), pos, DUSK]]
	for wx in [7, 41]:
		var src := Rect2(wf * 15, 0, 15, 15)
		fx.draw_texture_rect_region(Game.tex("cut_wheel"), Rect2(pos + Vector2(wx, 18), Vector2(15, 15)), src, DUSK)
		mirror_extra.append([Game.tex("cut_wheel"), src, pos + Vector2(wx, 18), DUSK])


func _end() -> void:
	if ended:
		return
	ended = true
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	Game.loop("music/moving", -INF)
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
