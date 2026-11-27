extends "res://game/cutscene.gd"
## Scenki satelity (Etap 2). "build": budowa pierwszego satelity na rusztowaniu, widok z boku, szybkie ujęcia przez
## czerń jak remont obserwatorium (co ujęcie inna pora dnia, satelita coraz bardziej złożony); zespół nosi białe
## blachy, podaje je sobie na drabinie i stuka młotkami, w tle ramię robota i fragment żurawia.
## "launch": start rakiety z pierwszym satelitą (odliczanie, płomień, dym) i wejście satelity na orbitę Ziemi.
## Tryb i nazwę satelity podaje Game.cut_arg; po scence wraca świat. Grafika: tools/art/satscene.js, dźwięki: tools/sfx/sat_sfx.py.

const TOD := preload("res://game/moving.gd").TOD
const TINT := {"dawn": Color(1, 0.9, 0.92), "noon": Color.WHITE, "rain": Color(0.78, 0.8, 0.88), "sunset": Color(1, 0.84, 0.74), "dusk": Color(0.62, 0.62, 0.82)}
const SHOTS := ["dawn", "noon", "rain", "sunset", "dusk"]  # ujęcie k: satelita sb_sat_k
const GROUND := 330.0
const LV := [264.0, 188.0]
const FALLBACK := ["bobr", "borsuk", "ges", "kot"]
var crew := []        # {s: Sprite2D, a, b, y, x, dir, carry, wait, work_end}
var flying := []      # blachy podawane w górę drabiny: [od, do, start]
var sparks := []      # [punkt, czas]
var next_ratchet := 2.0
var tod := "dawn"
var puffs := []       # dym startu: [pozycja, prędkość, wiek]


func _ready() -> void:
	add_child(cam)
	cam.position = Vector2(320, 180)
	_screen()
	fx.draw.connect(func(): if fx_draw.is_valid(): fx_draw.call())
	if Game.cut_arg.begins_with("launch"):
		await _launch(Game.cut_arg.trim_prefix("launch:"))
	else:
		await _build()
	await create_tween().tween_property(fade, "color:a", 1.0, 0.6).finished
	_end()


func _end() -> void:
	if ended:
		return
	ended = true
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	Game.hush()
	Game.cut_arg = ""
	get_tree().change_scene_to_file("res://game/world.tscn")


func _show() -> void:
	add_child(fx)
	await create_tween().tween_property(fade, "color:a", 0.0, 0.8).finished


## niebo w pasach (jak w przeprowadzce) na cały ekran
func _sky(parent: Node, key: String) -> void:
	var n := Node2D.new()
	parent.add_child(n)
	n.draw.connect(func():
		var c: Array = TOD[key]
		for k in 12:
			n.draw_rect(Rect2(-340, -80 + k * 34, 1320, 35), (c[0] as Color).lerp(c[1], k / 11.0)))


# ---------------------------------------------------------------- budowa
func _build() -> void:
	sc = Node2D.new()
	add_child(sc)
	Game.loop("site_work", -10.0)
	tick = _build_tick
	fx_draw = _build_fx
	for k in SHOTS.size():
		tod = SHOTS[k]
		var shot := _site(k)
		Game.loop("rain_balcony", -12.0 if tod == "rain" else -INF)
		if k == 0:
			await _show()
		else:
			await create_tween().tween_property(fade, "color:a", 0.0, 0.25).finished
		await get_tree().create_timer(2.4).timeout
		if k < SHOTS.size() - 1:
			await create_tween().tween_property(fade, "color:a", 1.0, 0.25).finished
			shot.queue_free()
			crew.clear()
			flying.clear()
	Game.loop("site_work", -INF)
	Game.loop("rain_balcony", -INF)
	crew.clear()
	_site_final()
	Game.sfx("tadam", 1.0, -6.0)
	await get_tree().create_timer(3.0).timeout


## plac montażowy: niebo, fragment żurawia, ramię robota, satelita w etapie k, rusztowanie z przodu, ekipa
func _site(k: int) -> Node2D:
	var shot := Node2D.new()
	sc.add_child(shot)
	_sky(shot, tod)
	var tint: Color = TINT[tod]
	_spr("cut_crane", Vector2(482, 40), shot).modulate = tint * Color(0.55, 0.55, 0.65)  # fragment żurawia w tle
	var arm := _spr("sb_arm", Vector2(14, GROUND - 120), shot, 3)
	arm.modulate = tint * Color(0.7, 0.7, 0.78)
	arm.set_meta("arm", true)
	_spr("sb_ground", Vector2(-320, GROUND - 1), shot).modulate = tint
	_spr("sb_sat_%d" % k, Vector2(255, GROUND - 151), shot).modulate = tint
	_spr("sb_scaffold", Vector2(-1, -1), shot).modulate = tint
	var kinds: Array = Game.staff.filter(func(p): return p.kind != "cat").map(func(p): return p.kind)
	kinds.append_array(FALLBACK)
	# [od x, do x, stopy y, koniec przy satelicie (praca), start]
	var routes := [[40.0, 140.0, GROUND, 140.0, 60.0], [160.0, 246.0, LV[0], 246.0, 170.0], [394.0, 480.0, LV[1], 394.0, 470.0], [400.0, 600.0, GROUND, 400.0, 560.0]]
	for i in routes.size():
		var r: Array = routes[i]
		var s := _spr("worker_" + kinds[i], Vector2.ZERO, shot, 4)
		s.modulate = tint
		crew.append({"s": s, "a": r[0], "b": r[1], "y": r[2], "x": r[4], "dir": signf(r[3] - r[4]), "carry": true, "wait": randf() * 0.5, "work": r[3], "hit": 0.0})
	return shot


## gotowy satelita na stojaku, ekipa zeszła, wieczór; napis o starcie
func _site_final() -> void:
	tod = "dusk"
	for c in sc.get_children():
		c.queue_free()
	var shot := Node2D.new()
	sc.add_child(shot)
	_sky(shot, tod)
	_spr("sb_ground", Vector2(-320, GROUND - 1), shot).modulate = TINT.dusk
	_spr("sb_sat_4", Vector2(255, GROUND - 151), shot).modulate = Color(0.85, 0.85, 1)
	fx_draw = func(): _caption("Satelita gotowy! Start rakiety za 2 dni.")
	create_tween().tween_property(fade, "color:a", 0.0, 0.3)


func _build_tick() -> void:
	var dt := get_process_delta_time()
	for c in crew:
		var s: Sprite2D = c.s
		s.frame = int(st * 6.0 + c.a) % 4  # merdanie / kołysanie jak w laboratorium
		if c.wait > 0.0:
			c.wait -= dt
			if absf(c.x - c.work) < 1.0 and st > c.hit:  # przy satelicie: stuka młotkiem w blachę
				c.hit = st + randf_range(0.28, 0.5)
				Game.sfx("metal_hit", randf_range(0.85, 1.2), randf_range(-14.0, -8.0))
				sparks.append([Vector2(c.work + c.dir * 6.0, c.y - 30), st])
		else:
			c.x = move_toward(c.x, c.b if c.dir > 0 else c.a, 34.0 * dt)
			if is_equal_approx(c.x, c.a) or is_equal_approx(c.x, c.b):
				var at_work: bool = absf(c.x - c.work) < 1.0
				c.wait = 1.4 if at_work else 0.5
				c.carry = not at_work
				c.dir = -c.dir
				if not at_work and c.y == GROUND and c.a < 100.0 and crew.size() > 1:  # podaje blachę koledze na drabinie
					flying.append([Vector2(c.x, c.y - 66), Vector2(crew[1].a, crew[1].y - 66), st])
		var bob := 1.0 if c.wait <= 0.0 and fmod(st * 4.0 + c.a, 1.0) < 0.5 else 0.0
		s.position = Vector2(roundf(c.x) - 22, c.y - 64 - bob)
		s.flip_h = c.dir < 0
	for n in sc.find_children("*", "Sprite2D", true, false):
		if n.has_meta("arm"):
			n.frame = int(st / 1.2) % 3
	if st > next_ratchet:  # klucz z grzechotką gdzieś na rusztowaniu
		next_ratchet = st + randf_range(2.0, 3.5)
		Game.sfx("ratchet", randf_range(0.9, 1.1), -14.0)
	sparks = sparks.filter(func(p): return st - p[1] < 0.12)
	flying = flying.filter(func(f): return st - f[2] < 0.6)


func _build_fx() -> void:
	var plate := Game.tex("sb_plate")
	for c in crew:
		if c.carry and c.wait <= 0.0:  # blacha nad głową
			fx.draw_texture(plate, Vector2(roundf(c.x) - 10, c.y - 72), TINT[tod])
	for f in flying:
		var u := clampf((st - f[2]) / 0.5, 0.0, 1.0)
		var p: Vector2 = (f[0] as Vector2).lerp(f[1], u) + Vector2(0, -sin(u * PI) * 18.0)
		fx.draw_texture(plate, p.floor() - Vector2(10, 4), TINT[tod])
	for p in sparks:  # iskry z blachy
		for k in 5:
			var d: Vector2 = Vector2.from_angle(k * 1.3 + p[1] * 7.0) * (2.0 + (st - p[1]) * 40.0)
			fx.draw_rect(Rect2((p[0] + d).floor(), Vector2.ONE), Color("fff2a0"))
	if tod == "rain":
		for i in 90:
			var x := fposmod(i * 37.0 - st * 120.0, 680.0) - 20.0
			var y := fposmod(i * 53.0 + st * 420.0, 380.0) - 10.0
			fx.draw_rect(Rect2(floorf(x), floorf(y), 1, 4), Color(0.75, 0.8, 0.95, 0.5))


## napis na dole ekranu z obrysem (jak komunikaty w okularze)
func _caption(text: String) -> void:
	var w := Game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
	var p := Vector2(roundf(320 - w / 2), 52)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		fx.draw_string(Game.font, p + d, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.06, 0.04, 0.1))
	fx.draw_string(Game.font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("ffcf6b"))


# ---------------------------------------------------------------- start rakiety
func _launch(sat_name: String) -> void:
	sc = Node2D.new()
	add_child(sc)
	tod = "dawn"
	_sky(sc, tod)
	_spr("sb_ground", Vector2(-320, GROUND - 1), sc).modulate = TINT.dawn
	_spr("sb_tower", Vector2(368, GROUND - 221), sc).modulate = TINT.dawn
	var rocket := _spr("sb_rocket", Vector2(322, GROUND - 161), sc)
	var flame := _spr("sb_flame", Vector2(331, GROUND - 12), sc, 3)
	flame.visible = false
	sc.move_child(flame, rocket.get_index())
	var lifted := [false]
	tick = func():
		var dt := get_process_delta_time()
		var up := maxf(0.0, st - 3.6)
		rocket.position.y = GROUND - 161 - 14.0 * up * up * up
		flame.position.y = rocket.position.y + 149
		flame.frame = int(st * 18.0) % 3
		if st > 3.0 and not lifted[0]:  # zapłon
			lifted[0] = true
			flame.visible = true
			Game.sfx("rocket", 1.0, -2.0)
		if lifted[0] and st < 6.5:  # dym rozchodzi się po płycie
			for k in 2:
				puffs.append([Vector2(343, GROUND - 4), Vector2(randf_range(-90, 90), randf_range(-30, -5)), 0.0])
		for p in puffs:
			p[0] += p[1] * dt
			p[1] *= 0.97
			p[2] += dt
		puffs = puffs.filter(func(p): return p[2] < 2.4)
		cam.position = Vector2(320, 180) + (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 2.0 if lifted[0] and st < 5.0 else Vector2.ZERO)
	fx_draw = func():
		for p in puffs:  # kłęby dymu: rosną i jaśnieją, potem znikają
			var r := 4 + int(p[2] * 9.0)
			Game.disc(fx, (p[0] as Vector2).floor(), r, Color(0.86, 0.84, 0.9, clampf(1.0 - p[2] / 2.4, 0.0, 0.8)))
		var n := int(st / 0.9)
		if st < 3.0:  # odliczanie
			_caption(["3", "2", "1", "1"][mini(n, 3)] + "...")
		elif st < 4.2:
			_caption("Start!")
	await _show()
	for i in 3:
		await get_tree().create_timer(0.9).timeout
		Game.sfx("tick", 1.0, -4.0)
	await get_tree().create_timer(4.6).timeout
	await create_tween().tween_property(fade, "color:a", 1.0, 0.4).finished
	# orbita: Ziemia, satelita rozkłada panele i wchodzi na orbitę
	sc.queue_free()
	puffs.clear()
	sc = Node2D.new()
	add_child(sc)
	st = 0.0
	cam.position = Vector2(320, 180)
	var earth := Vector2(430, 250)
	tick = Callable()
	fx_draw = func():
		for i in 120:
			fx.draw_rect(Rect2((i * 97) % 680 - 20, (i * 53) % 380 - 10, 1, 1), Color(1, 1, 1, 0.35 + 0.35 * sin(st * 2.0 + i)))
		fx.draw_texture_rect_region(Game.tex("os/earth"), Rect2(earth - Vector2(153, 153), Vector2(306, 306)), Rect2(int(st * 4.0) % 32 * 102, 0, 102, 102))
		var u := smoothstep(0.0, 3.2, st)
		var a := lerpf(PI * 1.05, PI * 1.55, u)
		var p := earth + Vector2(cos(a) * 250.0, sin(a) * 120.0)
		fx.draw_texture(Game.tex("sb_sat_open"), p.floor() - Vector2(31, 12))
		if st > 3.2:
			_caption("Satelita %s na orbicie!" % sat_name)
	await create_tween().tween_property(fade, "color:a", 0.0, 0.4).finished
	await get_tree().create_timer(3.2).timeout
	Game.sfx("music/sting_win", 1.0, -4.0, "Music")
	await get_tree().create_timer(3.0).timeout
