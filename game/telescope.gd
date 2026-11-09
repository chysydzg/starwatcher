extends Control
## Okular teleskopu balkonowego (GDD 9): skanowanie → namierzenie (PPM) → wyostrzanie (kółko: balans w przód i w tył)
## → łączenie gwiazd (klikanie świecących gwiazd po kolei) → zapis do Dziennika. Meteory, kometa, deszcz.

signal closed
signal discovered
signal all_done

enum S { SCAN, FOCUS, CONNECT, FULL, RESULT }
const C := Vector2(320, 180)
const R := 172.0
const STAR_SCALE := 3.0          # rozstaw gwiazd konstelacji na ekranie
const FOCUS_STEP := 0.02         # jeden ząbek kółka
# stary wariant: soczewka z opóźnieniem i pływający ostry punkt (do powrotu, jeśli pasek się nie sprawdzi)
# const FOCUS_STEP := 0.05
# const FOCUS_LAG := 3.0
const FOCUS_SWAY := 0.045        # bujanie znacznika na pasku ostrości (Stabilizacja Obrazu je tłumi)
const BAR_K := 200.0             # px paska na jednostkę ostrości
const SHARP := 96                # od tej jakości soczewka „klika”

var sky_size := Vector2(1200, 700)  # Newton: większe niebo (więcej obiektów)
var is_telescope := true
var hide_hud := true
var state := S.SCAN
var cam := sky_size / 2
var aim := C
var zoom := 1.0
var t := 0.0
var targets := []
var target := {}
var hovered := {}
var f := 0.5
# var f_goal := 0.5        # stary wariant: dokąd kręci gracz, soczewka dochodzi z opóźnieniem
var idle_focus := 0.0
var sharp_t := 0.0
var lit := {}                    # zaznaczone gwiazdy aktualnej konstelacji
var bursts := []                 # rozbłyski po kliknięciu gwiazdy
var shake := 0.0
var slide: AudioStreamPlayer  # szmer przesuwanych soczewek, głośniej przy szybkim obrocie
var _notch := 0      # ząbek pierścienia ostrości (klik zębatki przy każdym)
var _prev_cam := Vector2.ZERO
var ring_a := 0.0  # kąt radełka pierścienia (rysowany)
var meteor := {}
var next_meteor := 0.0
var clouds := []
var result := {}
var center_msg := ""
var center_t := 0.0
var _sky_tex: ImageTexture
var _frame_tex: ImageTexture
var _rng := RandomNumberGenerator.new()
var _last_mouse := Vector2.ZERO
var _mouse_aim := C  # tam chce celownik gracz; sam celownik dochodzi tam z oporem (steer)
var hum: AudioStreamPlayer  # buczenie wykrywacza: szybsze i głośniejsze bliżej ukrytego obiektu
var _all_told := false
var _sh := Vector2.ZERO


func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	zoom = 1.0 / 1.3 if Game.has("newton") else 1.0  # Newton: pole widzenia +30%
	if Game.has("newton"):
		sky_size = Vector2(1700, 900)
	_rng.seed = Game.day * 977
	_build_sky()
	_build_frame()
	_place_targets()
	next_meteor = _meteor_gap()
	Game.loop("amb_space", -8.0)
	slide = AudioStreamPlayer.new()
	slide.stream = Game.looped("lens_slide")
	slide.bus = "SFX"
	slide.volume_db = -60.0
	add_child(slide)
	slide.play()
	hum = AudioStreamPlayer.new()
	hum.stream = Game.looped("scan_hum")
	hum.bus = "SFX"
	hum.volume_db = -60.0
	add_child(hum)
	hum.play()
	_prev_cam = cam  # bez tego pierwsza klatka liczy skok od (0, 0) i słychać szum
	if Game.rain:  # chmury zasłaniają obiekty; w burzy jest ich dużo i są gęste
		for i in (16 if Game.storm else 8) * int(sky_size.x / 1200.0):
			clouds.append([Vector2(_rng.randf_range(0, sky_size.x), _rng.randf_range(0, sky_size.y)), _rng.randf_range(90, 170), _rng.randf() * TAU])
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_last_mouse = get_global_mouse_position()
	aim = C
	_check_all_done()


func _meteor_gap() -> float:
	return _rng.randf_range(Game.METEOR_INTERVAL.x, Game.METEOR_INTERVAL.y) / (1.25 if Game.has("plakat") else 1.0)


# ---------------------------------------------------------------- generowanie nieba i okularu
func _build_sky() -> void:
	var img := Image.create(int(sky_size.x), int(sky_size.y), false, Image.FORMAT_RGBA8)
	for y in int(sky_size.y):
		img.fill_rect(Rect2i(0, y, int(sky_size.x), 1), Color("0a0d24").lerp(Color("15193f"), float(y) / sky_size.y))
	for i in 900:
		var p := Vector2i(_rng.randi_range(0, int(sky_size.x) - 1), _rng.randi_range(0, int(sky_size.y) - 1))
		var k := _rng.randf()
		img.set_pixelv(p, Color(0.42, 0.45, 0.66) if k < 0.7 else Color(0.62, 0.64, 0.82))  # tło przygaszone: cele mają się wyróżniać
	_sky_tex = ImageTexture.create_from_image(img)


func _build_frame() -> void:
	var img := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	var ring := Color("5d6478") if Game.has("newton") else Color("b08a3c")
	var ring_d := ring.darkened(0.45)
	for y in 360:
		for x in 640:
			var d := Vector2(x, y).distance_to(C)
			if d > R + 13:
				img.set_pixel(x, y, Color("0d0a16"))
			elif d > R + 12:
				img.set_pixel(x, y, ring_d.darkened(0.4))
			elif d > R:
				img.set_pixel(x, y, ring.lightened(0.15) if d < R + 2 else (ring if d < R + 4 else ring_d))
	if not Game.has("czyszczacy"):  # brudna soczewka: kurz jak natrysk – ziarniste skupiska drobinek, gęste w środku, rzadkie na brzegach
		for i in 10:
			var c0 := C + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0, R - 30)
			var rx := _rng.randf_range(14, 46)
			var ry := rx * _rng.randf_range(0.3, 1.0)
			var rot := _rng.randf() * PI
			for n in int(rx * ry * _rng.randf_range(0.5, 1.1)):
				var g := Vector2(_rng.randfn(0.0, 0.45), _rng.randfn(0.0, 0.45))
				var q := (c0 + Vector2(g.x * rx, g.y * ry).rotated(rot)).floor()
				if q.distance_to(C) < R - 1:
					img.set_pixelv(Vector2i(q), Color(0.62, 0.57, 0.48, clampf(0.85 - g.length() * 0.45, 0.25, 0.8)))
		for i in 320:  # pojedyncze pyłki po całej soczewce
			var q := Vector2i(C + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(4, R - 4))
			img.set_pixelv(q, Color(0.66, 0.6, 0.5, _rng.randf_range(0.3, 0.65)))
	if not Game.has("achromat"):  # pęknięcie „pajączek”: punkt uderzenia, promienie i poszarpane pierścienie (tylko kawałek soczewki)
		var hit := C + Vector2(92, -66)
		var spokes := []
		var a0 := _rng.randf() * TAU
		for k in 15:
			var pts := [hit]
			var a := a0 + k * TAU / 15.0 + _rng.randf_range(-0.15, 0.15)
			var ln := _rng.randf_range(38, 78)
			var r0 := 0.0
			while r0 < ln:
				r0 += _rng.randf_range(6, 11)
				a += _rng.randf_range(-0.12, 0.12)
				pts.append(hit + Vector2.from_angle(a) * r0)
			spokes.append(pts)
		var lines := []
		for sp in spokes:
			for j in sp.size() - 1:
				lines.append([sp[j], sp[j + 1], 2 if j < 2 else 1])
		for rg in [2, 4, 6]:  # pierścienie łączą sąsiednie promienie na tej samej odległości
			for k in spokes.size():
				var a: Array = spokes[k]
				var b: Array = spokes[(k + 1) % spokes.size()]
				if a.size() > rg and b.size() > rg and _rng.randf() < 0.75:
					var mid: Vector2 = (a[rg] + b[rg]) / 2.0 + Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3))
					lines.append([a[rg], mid, 1])
					lines.append([mid, b[rg], 1])
		for l in lines:
			var n := int(l[0].distance_to(l[1])) + 1
			for i in n:
				var q: Vector2 = l[0].lerp(l[1], float(i) / n).floor()
				for w in l[2]:
					var o := Vector2i(q + Vector2(w, 0))
					if Vector2(o).distance_to(C) < R - 1:
						img.set_pixelv(o, Color(0.9, 0.95, 1.0, 0.8))
				var sh := Vector2i(q + Vector2(l[2], 1))
				if Vector2(sh).distance_to(C) < R - 1 and img.get_pixelv(sh).a < 0.5:
					img.set_pixelv(sh, Color(0.02, 0.02, 0.06, 0.45))
		for i in 40:  # skruszone szkło w miejscu uderzenia
			var q := Vector2i(hit + Vector2(_rng.randfn(0, 2.5), _rng.randfn(0, 2.5)))
			img.set_pixelv(q, Color(0.95, 0.98, 1.0, 0.85))
	_frame_tex = ImageTexture.create_from_image(img)


func _place_targets() -> void:
	var used := [sky_size / 2 + Vector2(-120, 30)]  # pierwszy cel blisko startowego widoku
	var first := true
	for id in Game.visible_objects():
		var p: Vector2 = used[0] if first else Vector2.ZERO
		if not first:
			for tries in 60:
				p = Vector2(_rng.randf_range(150, sky_size.x - 150), _rng.randf_range(130, sky_size.y - 130))
				if used.all(func(u): return u.distance_to(p) > 190):
					break
			used.append(p)
		first = false
		var info := Game.obj_info(id)
		var tg := {"id": id, "pos": p, "info": info, "sweet": _rng.randf_range(0.3, 0.7), "done": Game.tonight.has(id), "phase": _rng.randf() * TAU,
			"f0": _rng.randf_range(0.18, 0.38) * (1 if _rng.randf() < 0.5 else -1)}  # rozostrzenie: z daleka obiekt już jest nieostry
		if info.cat in ["nebula", "deep"]:
			tg.width = 0.014  # mgławice: węższy zakres ostrości
		if id == "comet":
			tg.vel = Vector2.from_angle(_rng.randf() * TAU) * 8.0
		targets.append(tg)
	cam = sky_size / 2


# ---------------------------------------------------------------- geometria
func to_screen(p: Vector2) -> Vector2:
	return C + (p - cam) * zoom


func to_sky(s: Vector2) -> Vector2:
	return cam + (s - C) / zoom


## opór celownika: tani teleskop chodzi ciężko i z opóźnieniem; statyw, montaż, kursor i mikro-ruchy go „smarują”
func steer() -> float:
	return 2.2 * (1.6 if Game.has("statyw") else 1.0) * (1.6 if Game.has("montaz") else 1.0) * (1.3 if Game.has("kursor1") else 1.0) * (1.5 if Game.has("mikro") else 1.0)


func wobble() -> Vector2:
	var a := 4.5 * (0.6 if Game.has("statyw") else 1.0) * (0.0 if Game.has("mikro") else 1.0)
	return Vector2(sin(t * 1.3) + 0.4 * sin(t * 3.1), cos(t * 1.7)) * a


func star_points(tg: Dictionary) -> Array:
	var pts: Array = tg.info.pts
	var mid := Vector2.ZERO
	for q in pts:
		mid += Vector2(q[0], q[1])
	mid /= pts.size()
	var out := []
	for q in pts:
		out.append(to_screen(tg.pos) + (Vector2(q[0], q[1]) - mid) * STAR_SCALE * zoom)
	return out


func hit_radius(tg: Dictionary) -> float:
	var r := 20.0
	if tg.info.has("pts"):
		for p in star_points(tg):
			r = maxf(r, p.distance_to(to_screen(tg.pos)) + 12.0)
	return r * (1.2 if Game.has("kursor1") else 1.0) * (1.35 if Game.has("montaz") else 1.0)


## 0..1: jak blisko celownik jest najbliższego nieodkrytego obiektu (radar SYGNAŁ i buczenie)
func proximity() -> float:
	var near := 0.0
	for tg in targets:
		if not tg.done:
			near = maxf(near, clampf(1.0 - (aim + wobble()).distance_to(to_screen(tg.pos)) / 160.0, 0.0, 1.0))
	return near


func hover_target() -> Dictionary:
	var a := aim + wobble()
	var best := {}
	var bd := 1e9
	for tg in targets:
		if tg.done:
			continue
		var d := a.distance_to(to_screen(tg.pos))
		if d < hit_radius(tg) and d < bd:
			bd = d
			best = tg
	return best


func quality() -> int:
	# stary wariant:
	# var w: float = target.get("width", 0.02) * _lens()
	# var d := absf(f - sweet_now())
	# var q := 100.0 - maxf(0.0, d - w / 2.0) * 230.0
	var q := 100.0 - maxf(0.0, absf(focus_offset()) - green()) * 250.0
	if Game.rain and _clouded(target.pos):
		q = minf(q, 45)
	return int(clampf(q, 10, 100))


func _clouded(p: Vector2) -> bool:
	return clouds.any(func(c): return p.distance_to(c[0]) < c[1] * 0.6)


func speed_mult() -> float:
	return (1.2 if Game.has("kawa") else 1.0) * (1.1 if Game.has("radio") else 1.0)


# ---------------------------------------------------------------- logika
func _process(dt: float) -> void:
	t += dt
	shake = maxf(0.0, shake - dt)
	ring_a = lerpf(ring_a, f * TAU * 1.5, minf(1.0, dt * 14.0))  # pierścień ostrości nadąża płynnie za kółkiem
	center_t -= dt
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mouse := get_global_mouse_position()
	if mouse.distance_to(_last_mouse) > 0.5:
		_mouse_aim = mouse
		_last_mouse = mouse
	if Game.pad and mv.length() > 0.2:
		_mouse_aim = aim + mv * 220.0 * speed_mult() * minf(1.0, steer() / 8.0) * dt
	aim = aim.lerp(_mouse_aim, 1.0 - exp(-steer() * dt))
	var off := aim - C
	if off.length() > R - 6:
		aim = C + off.limit_length(R - 6)
		off = aim - C
	if state == S.SCAN:
		var edge := R * 0.55  # im dalej od środka, tym szybciej obraca się teleskop
		if off.length() > edge:
			cam += off.normalized() * (off.length() - edge) / (R - edge) * 420.0 * speed_mult() * dt / zoom
		if not Game.pad:
			cam += mv * 260.0 * speed_mult() * dt / zoom
		if not Game.has("naped"):
			cam.x += 1.5 * dt
		var h := hover_target()
		if Game.has("naped") and not h.is_empty():  # napęd: wykryty obiekt sam wjeżdża na środek, celownik zostaje na nim
			var k := 1.0 - exp(-2.5 * dt)
			cam = cam.lerp(h.pos, k)
			aim = aim.lerp(C, k)
			_mouse_aim = aim
		if not h.is_empty() and hovered != h:
			Game.sfx("detect", 1.0, -4.0)  # pyknięcie: coś wykryte
		hovered = h
	for c in clouds:
		c[0].x = fposmod(c[0].x + 6.0 * dt, sky_size.x)
	for tg in targets:
		if tg.has("vel") and not tg.done:
			tg.pos = (tg.pos + tg.vel * dt).clamp(Vector2(140, 140), sky_size - Vector2(140, 140))
	cam = cam.clamp(Vector2(R, R) / zoom, sky_size - Vector2(R, R) / zoom)  # okular nigdy nie wychodzi poza niebo (inaczej brzegi tekstury rysują się jako linie)
	var near := proximity() if state == S.SCAN and hovered.is_empty() else 0.0
	hum.volume_db = lerpf(hum.volume_db, -30.0 + 30.0 * near if near > 0.02 else -60.0, minf(1.0, dt * 6.0))
	hum.pitch_scale = 0.8 + 0.9 * near  # wyżej = szybsze pulsowanie
	var speed := cam.distance_to(_prev_cam) / maxf(dt, 0.001) * zoom
	_prev_cam = cam
	slide.volume_db = lerpf(slide.volume_db, -46.0 + 30.0 * clampf(speed / 300.0, 0.0, 1.0), minf(1.0, dt * 8.0))
	if state == S.FOCUS and int(f * 50.0) != _notch:
		_notch = int(f * 50.0)
		Game.sfx("focus_tick", _rng.randf_range(0.92, 1.08), -6.0)
	if state == S.FOCUS:
		var fin := Input.get_action_strength("focus_in") - Input.get_action_strength("focus_out")
		if absf(fin) > 0.1:
			f = clampf(f + fin * 0.25 * dt, 0.0, 1.0)
			idle_focus = 0.0
		idle_focus += dt
		if target.id == "comet":  # kometa ucieka: trzeba ją trzymać w celowniku
			cam = cam.lerp(target.pos, dt * 0.6)
			if (aim + wobble()).distance_to(to_screen(target.pos)) > 30:
				f = clampf(f + 0.1 * dt * signf(f - target.sweet + 0.001), 0.0, 1.0)
		else:
			cam = cam.lerp(target.pos, minf(1.0, dt * 10.0))
		if Game.has("auto2") or (Game.has("auto1") and idle_focus > 1.0):
			f = move_toward(f, target.sweet, dt * 0.3)
		# f = lerpf(f, f_goal, 1.0 - exp(-FOCUS_LAG * _lens() * dt))  # stary wariant
		var auto := Game.has("auto1") or Game.has("auto2")
		if auto and quality() >= SHARP:  # bez autofokusu trzeba samemu trafić kliknięciem
			sharp_t += dt
			if sharp_t > 0.35 and idle_focus > 0.3:
				_after_focus()
		else:
			sharp_t = 0.0
	if Game.has("meteory") and state != S.FULL:
		next_meteor -= dt
		if next_meteor <= 0 and meteor.is_empty():
			next_meteor = _meteor_gap()
			var a0 := _rng.randf() * TAU  # start za krawędzią okularu, lot w stronę środka
			meteor = {"pos": to_sky(C + Vector2.from_angle(a0) * (R + 70)), "vel": -Vector2.from_angle(a0 + _rng.randf_range(-0.35, 0.35)) * 70.0 / zoom, "t": 0.0}
			Game.sfx("meteor", 1.0, -10.0)
		if not meteor.is_empty():
			meteor.t += dt
			meteor.pos += meteor.vel * dt
			if meteor.t > Game.METEOR_WINDOW:
				meteor = {}
	for b in bursts:
		b.t += dt
	bursts = bursts.filter(func(b): return b.t < 0.5)
	if not result.is_empty():
		result.t -= dt
		if result.t <= 0:
			result = {}
	queue_redraw()


## stary wariant: ostry punkt pływał („seeing”)
# func sweet_now() -> float:
# 	return target.get("sweet", 0.5) + 0.035 / (_lens() * _lens()) * sin(t * 0.9 + target.get("phase", 0.0))


## znacznik na pasku: ustawienie pierścienia minus ostry punkt, plus bujanie powietrza
func focus_offset() -> float:
	var ph: float = target.get("phase", 0.0)
	return f - target.get("sweet", 0.5) + FOCUS_SWAY * _calm() * (0.7 * sin(t * 2.1 + ph) + 0.3 * sin(t * 3.7 + ph * 2.0))


## połowa zielonego pola (Czyste Soczewki i radio je poszerzają, brudna soczewka zwęża)
func green() -> float:
	return target.get("width", 0.02) * 1.5 * (1.0 + (0.3 if Game.has("czyste1") else 0.0) + (0.3 if Game.has("czyste2") else 0.0)) * (1.1 if Game.has("radio") else 1.0) * (1.0 if Game.has("czyszczacy") else 0.8)


## siła bujania znacznika (Stabilizacja Obrazu I i II)
func _calm() -> float:
	return 1.0 - (0.25 if Game.has("stab1") else 0.0) - (0.25 if Game.has("stab2") else 0.0)


# func _lens() -> float:  # stary wariant
# 	return (1.0 + (0.15 if Game.has("czyste1") else 0.0) + (0.25 if Game.has("czyste2") else 0.0)) * (1.1 if Game.has("radio") else 1.0)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_RIGHT:
				if state in [S.FOCUS, S.CONNECT]:
					_leave()
				else:
					_lock_or_confirm()
			MOUSE_BUTTON_LEFT:
				if state == S.CONNECT:
					_click_star()
				elif state == S.RESULT:
					state = S.SCAN
				else:
					_lock_or_confirm()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if state == S.FOCUS:
					f = clampf(f + (FOCUS_STEP if e.button_index == MOUSE_BUTTON_WHEEL_UP else -FOCUS_STEP), 0.0, 1.0)
					idle_focus = 0.0
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		if state in [S.FOCUS, S.CONNECT]:
			_leave()
		elif state != S.FULL:
			close()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("confirm") or (Game.pad and e.is_action_pressed("interact")):
		if state == S.CONNECT:
			_click_star()
		else:
			_lock_or_confirm()
		get_viewport().set_input_as_handled()
	elif state == S.SCAN and Game.has("szukacz") and (e.is_action_pressed("prev_obj") or e.is_action_pressed("next_obj")):
		_jump(1 if e.is_action_pressed("next_obj") else -1)
		get_viewport().set_input_as_handled()


## wyjście z obiektu bez utraty postępu: wracając, gracz zastaje ostrość i połączone gwiazdy jak je zostawił
func _leave() -> void:
	target.saved = {"f": f, "lit": lit.duplicate(), "connect": state == S.CONNECT}
	state = S.SCAN
	target = {}


func _jump(dir: int) -> void:
	var open := targets.filter(func(tg): return not tg.done)
	if open.is_empty():
		return
	open.sort_custom(func(a, b): return a.pos.x < b.pos.x)
	var i := 0
	for k in open.size():
		if open[k].pos.x > cam.x + 5:
			i = k
			break
	i = posmod(i + (0 if dir > 0 else -2), open.size())
	create_tween().tween_property(self, "cam", open[i].pos, 0.35).set_trans(Tween.TRANS_SINE)


func _lock_or_confirm() -> void:
	match state:
		S.SCAN:
			if not meteor.is_empty() and (aim + wobble()).distance_to(to_screen(meteor.pos)) < 28:
				var r := Game.meteor_caught()
				meteor = {}
				Game.ding(1.5)
				_show("Meteor złapany!", "+%d PW  %s" % [r.pw, "zapisany na dysk" if r.saved else "dysk pełny"])
				discovered.emit()
				return
			var tg := hover_target()
			if tg.is_empty():
				return
			target = tg
			f = clampf(tg.sweet + tg.f0, 0.0, 1.0)  # tak samo nieostry jak z daleka
			idle_focus = 0.0
			sharp_t = 0.0
			state = S.FOCUS
			if tg.has("saved"):  # powrót do obiektu: ostrość i połączone gwiazdy jak przed wyjściem
				f = tg.saved.f
				if tg.saved.connect:
					lit = tg.saved.lit.duplicate()
					state = S.CONNECT
				tg.erase("saved")
			_notch = int(f * 50.0)  # pierwszy klik zębatki dopiero, gdy gracz pokręci
		S.FOCUS:
			if quality() < 20:
				_center("Za rozmyte")
				return
			_after_focus()
		S.RESULT:
			state = S.SCAN


func _after_focus() -> void:
	Game.sfx("lens_click")  # klik przeskakującej soczewki i ciepły „ding”
	Game.ding(1.0)
	if target.info.has("pts"):
		lit.clear()
		state = S.CONNECT
		aim = C
		if Game.has("samoistne"):
			for i in target.info.pts.size():
				lit[i] = true
			_finish()
	else:
		_finish()


func _click_star() -> void:
	var pts := star_points(target)
	for i in pts.size():
		if lit.has(i):
			continue
		if (aim + wobble()).distance_to(pts[i]) < 11:
			lit[i] = true
			bursts.append({"p": pts[i], "t": 0.0})
			shake = 0.12
			Game.sfx("pencil", _rng.randf_range(0.9, 1.1), -4.0)
			Game.ding(1.0 + lit.size() * 0.12)
			if lit.size() == pts.size():
				Game.sfx("chimes")
				_finish()
			return
	Game.sfx("miss", 1.0, -8.0)  # gwiazda spoza sekwencji: cicho, bez kary


func _finish(replace := false) -> void:
	var q := quality()
	var pts: int = target.info.pts.size() if target.info.has("pts") else 0
	var gained := Game.record(target.id, q, pts, replace)
	if gained < 0:
		state = S.FULL
		_full_dialog()
		return
	target.done = true
	Game.sfx("floppy")  # zapis odkrycia na dyskietkę
	discovered.emit()
	var info: Dictionary = target.info
	_show(("Znak zodiaku: " if info.cat == "zodiac" else "Odkryto: ") + info.name, "jakość %d%%   +%d PW" % [q, gained])
	target = {}


func _check_all_done() -> void:
	if _all_told or targets.is_empty() or targets.any(func(tg): return not tg.done):
		return
	_all_told = true
	_center("„Chyba odkryłam już wszystko na dziś.”", 5.0)
	all_done.emit()


func _show(a: String, b: String) -> void:
	result = {"a": a, "b": b, "t": 2.2}  # napis znika sam; teleskopem można ruszać od razu
	state = S.SCAN
	_check_all_done()


func _center(s: String, dur := 2.5) -> void:
	center_msg = s
	center_t = dur


func _full_dialog() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(190, 140)
	box.custom_minimum_size = Vector2(260, 0)
	add_child(box)
	var l := Label.new()
	l.text = "BŁĄD: BRAK MIEJSCA NA DYSKU!\nOdrzucić badanie czy zastąpić starsze?"
	l.add_theme_color_override("font_color", Color("ff8a8a"))
	box.add_child(l)
	for pair in [["ODRZUĆ BADANIE", false], ["ZASTĄP NAJSTARSZE", true]]:
		var b := Button.new()
		b.text = pair[0]
		box.add_child(b)
		b.pressed.connect(func():
			box.queue_free()
			if pair[1]:
				_finish(true)
			else:
				target = {}
				state = S.SCAN)
	box.get_child(1).grab_focus.call_deferred()


func tired() -> void:
	_center("Jania ziewa... Koniec obserwacji na dziś.", 2.0)
	get_tree().create_timer(1.8).timeout.connect(close)


func close() -> void:
	Game.loop("amb_space", -INF)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): closed.emit(); queue_free())


# ---------------------------------------------------------------- rysowanie
## ramka 1 px z pełnych prostokątów (draw_rect bez wypełnienia potrafi zgubić bok)
func _frame(r: Rect2, c: Color) -> void:
	_px(r.position.x, r.position.y, r.size.x, 1, c)
	_px(r.position.x, r.end.y - 1, r.size.x, 1, c)
	_px(r.position.x, r.position.y, 1, r.size.y, c)
	_px(r.end.x - 1, r.position.y, 1, r.size.y, c)


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _text(p: Vector2, s: String, c: Color, center := false) -> void:
	var x := p.x - (Game.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x / 2.0 if center else 0.0)
	draw_string(Game.font, Vector2(roundf(x) + 1, p.y + 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0, 0, 0, 0.8 * c.a))
	draw_string(Game.font, Vector2(roundf(x), p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


## jasny punkt z połyskiem w 4 strony (od światła)
func _glint(p: Vector2, col: Color, sz: float, a := 1.0) -> void:
	p = p.floor()
	var rad := sz * 1.5  # duże, jasne punkty
	for k in 3:
		draw_circle(p, rad * (1.6 - k * 0.45), Color(col, 0.12 * a * (k + 1)))
	var arm := int(rad * 2.2)
	for i in range(1, arm):
		var fa := a * (1.0 - float(i) / arm)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			_px(p.x + d.x * i, p.y + d.y * i, 1, 1, Color(col.lightened(0.4), fa))
	_px(p.x - 2, p.y - 1, 5, 3, Color(col.lightened(0.6), a))
	_px(p.x - 1, p.y - 2, 3, 5, Color(col.lightened(0.6), a))
	_px(p.x - 1, p.y - 1, 3, 3, Color(1, 1, 1, a))


func _edge_glow(dir: Vector2, col: Color, a: float) -> void:
	for k in 4:
		draw_circle((C + dir * (R - 4 - k * 8)).floor(), 20.0 - k * 4.0, Color(col, a * (1.0 - k * 0.22)))


func _check(p: Vector2) -> void:  # ✓ przy zbadanym obiekcie
	const CHECK := ["......##", ".....##.", "##..##..", ".####...", "..##...."]
	for y in CHECK.size():
		for x in CHECK[y].length():
			if CHECK[y][x] == "#":
				_px(p.x + x - 1, p.y + y, 3, 2, Color("0d0a16"))  # obrys
	for y in CHECK.size():
		for x in CHECK[y].length():
			if CHECK[y][x] == "#":
				_px(p.x + x, p.y + y, 1, 1, Color("6affa0"))


func _draw() -> void:
	_sh = Vector2(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2)) if shake > 0 else Vector2.ZERO
	if _sh == Vector2.ZERO and not meteor.is_empty() and meteor.t < 1.2:  # meteor: okular drży, czas reagować
		_sh = Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 1))  # lekki wstrząs po kliknięciu gwiazdy
	draw_set_transform(_sh)
	var half := Vector2(R, R)
	draw_texture_rect_region(_sky_tex, Rect2(C - half, half * 2), Rect2(cam - half / zoom, half * 2 / zoom))
	for tg in targets:
		var s := to_screen(tg.pos)
		if s.distance_to(C) < R + 60:
			_draw_target(tg, s)
	for c in clouds:  # kłęby: ciemne, gęste, z jaśniejszym wierzchem; zasłaniają gwiazdy pod spodem
		var s := to_screen(c[0])
		for k in 7:
			var o := Vector2(cos(c[2] + k * 0.9) * c[1] * 0.38, sin(c[2] + k * 1.3) * c[1] * 0.18) * zoom
			var rad: float = c[1] * (0.42 - k * 0.025) * zoom
			draw_circle((s + o).floor(), rad, Color(0.2, 0.2, 0.28, 0.75))
			draw_circle((s + o + Vector2(0, -rad * 0.25)).floor(), rad * 0.7, Color(0.3, 0.3, 0.38, 0.6))  # wierzch podświetlony Księżycem
	if not meteor.is_empty():
		var s := to_screen(meteor.pos)
		var a: float = 1.0 - meteor.t / Game.METEOR_WINDOW
		for i in 18:
			_px(s.x - meteor.vel.x * 0.06 * i, s.y - meteor.vel.y * 0.06 * i, 2, 2, Color(1, 0.95, 0.8, a * (1.0 - i / 18.0)))
		_glint(s, Color("fff3c4"), 3.0, a)
	for b in bursts:
		draw_arc(b.p, 4 + b.t * 40, 0, TAU, 24, Color(1, 0.85, 0.4, 1.0 - b.t * 2), 1.0)
	if Game.rain and not Game.has("parasol"):  # deszcz na soczewce (parasol balkonowy go zatrzymuje)
		draw_circle(C, R, Color(0.08, 0.1, 0.22, 0.45 if Game.storm else 0.3))
		var slant := 0.18 + 0.1 * sin(t * 0.7)  # skos zmienia się z porywami
		for i in (420 if Game.storm else 220):  # gęste smugi; każda ma swoją prędkość, a po każdym spadku nowe miejsce i długość
			var fall := (t * (190.0 + fmod(i * 37.7, 160.0)) + i * 41.0) / (R * 2.0 + 40.0)
			var h := absi(hash(Vector2i(i, floori(fall))))
			var y := C.y - R - 20.0 + (fall - floorf(fall)) * (R * 2.0 + 40.0)
			var x := C.x - R + float(h % int(R * 2.0))
			var ln := 6.0 + float(h / 7 % 9)
			var top := Vector2(x, y).floor()
			var end := top + Vector2(-ln * slant, ln).round()
			if top.distance_to(C) < R - 4 and end.distance_to(C) < R - 4:
				draw_line(top, end, Color(0.72, 0.8, 1.0, 0.16 + float(h % 4) * 0.06), 1.0)
	for tg in targets:  # delikatna poświata przy krawędzi soczewki w stronę nieodkrytych obiektów
		var ts := to_screen(tg.pos)
		if not tg.done and ts.distance_to(C) > R - 12:
			var col := Color(1, 0.6, 0.2) if tg.id == "comet" else Color(1, 1, 1)
			_edge_glow((ts - C).normalized(), col, 0.09 + 0.04 * sin(t * 2.5 + tg.phase))
	if not meteor.is_empty() and to_screen(meteor.pos).distance_to(C) > R - 12:  # meteor: mocne, pomarańczowe, pulsuje
		_edge_glow((to_screen(meteor.pos) - C).normalized(), Color(1, 0.55, 0.15), 0.3 + 0.12 * sin(t * 14.0))
	if Game.lightning > 0.0:  # piorun (błyska sky_fx balkonu) rozświetla całe niebo w okularze
		draw_circle(C, R, Color(0.85, 0.9, 1.0, 0.55 * Game.lightning))
	draw_texture(_frame_tex, Vector2.ZERO)
	var ring := Color("5d6478") if Game.has("newton") else Color("b08a3c")
	for i in 60:  # radełko pierścienia ostrości obraca się razem z kółkiem myszy
		var dir := Vector2.from_angle(i * TAU / 60.0 + ring_a)
		for k in range(5, 12):
			var q := (C + dir * (R + k)).floor()
			_px(q.x, q.y, 2, 1, ring.lightened(0.3) if k < 7 else ring.darkened(0.5))
	_draw_crosshair()
	draw_set_transform(Vector2.ZERO)
	_draw_panels()


func _draw_target(tg: Dictionary, s: Vector2) -> void:
	var info: Dictionary = tg.info
	var col := Color(info.get("col", "fff0b0"))
	var focused: bool = state in [S.FOCUS, S.CONNECT] and tg == target
	var hov: bool = state == S.SCAN and tg == hovered
	if hov:  # najechany obiekt drży i mocniej świeci
		s += Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 1))
	var pulse := 0.75 + 0.25 * sin(t * 2.5 + tg.phase)
	if tg.done:
		_check(s + Vector2(14, -22))
		if info.has("pts"):
			var c2 := Color(0.55, 0.85, 0.65, 0.55)
			var pts := star_points(tg)
			for e in info.edges:
				draw_line(pts[e[0]], pts[e[1]], Color(1, 0.8, 0.4, 0.3))
			for p in pts:
				_px(p.x - 1, p.y - 1, 2, 2, c2)
			return
		pulse = 1.0  # Księżyc, mgławice, planety: po odkryciu ostre, w pełnej postaci
	var blur := 0.0
	if focused and state == S.FOCUS:
		blur = absf(focus_offset())
	elif not tg.done and not (focused and state == S.CONNECT):
		blur = absf(tg.f0) if not tg.has("saved") else absf(tg.saved.f - tg.sweet)  # z daleka nieostry, tak jak po namierzeniu
	var a := pulse * (1.25 if hov else 1.0)
	if blur > 0.03:  # rozmyta plama: im dalej od balansu, tym większa i bledsza
		var r := 4.0 + blur * 70.0
		var pts := star_points(tg) if info.has("pts") else [s]
		for p in pts:
			for k in 3:
				draw_circle(p, r * (1.0 - k * 0.3), Color(col, (0.09 + k * 0.07) * (1.2 - blur * 1.5)))
		return
	match info.cat:
		"moon":
			var r := 26.0 * zoom
			for k in 3:
				draw_circle(s, r + 10 - k * 3, Color(1, 0.95, 0.75, 0.06 * (k + 1)))
			draw_circle(s, r, Color("f4e8c0"))
			for c in [[Vector2(-8, -5), 5], [Vector2(7, 7), 6], [Vector2(4, -11), 3], [Vector2(-11, 9), 3]]:
				draw_circle(s + c[0] * zoom, c[1] * zoom, Color("dacb9c"))
			var ph := Game.moon_phase()
			if ph != 4:
				var sh := (ph - 4) / 4.0
				draw_circle(s + Vector2(sh * r * 1.6 + (r * 0.3 if ph < 4 else -r * 0.3), 0), r * 0.98, Color("0c1030"))
			if not focused:
				_glint(s + Vector2(r * 0.6, -r * 0.6), Color.WHITE, 2.0, a)
		"nebula":
			for k in 12:
				var o := Vector2(sin(k * 2.4) * 13, cos(k * 1.7) * 9) * zoom
				draw_circle(s + o, (12 - k * 0.6) * zoom, Color(col, 0.16 * a))
			_glint(s, col, 3.5, a)
		"planet":
			var r := (10.0 if tg.id == "jowisz" else 6.0) * zoom
			draw_circle(s, r + 4, Color(col, 0.15 * a))
			draw_circle(s, r, col)
			if tg.id == "jowisz":
				for k in [-4, 1, 5]:
					_px(s.x - r + 2, s.y + k * zoom, r * 2 - 4, 2, Color("a8704a"))
				for k in 3:
					_px(s.x + (18 + k * 8) * zoom * (1 if k % 2 else -1), s.y, 2, 2, Color.WHITE)
			_glint(s + Vector2(-r * 0.4, -r * 0.4), Color.WHITE, 1.5, a)
		"deep":
			if tg.id == "albireo":
				_glint(s + Vector2(-4, 0), Color("ffcf6b"), 3.5, a)
				_glint(s + Vector2(5, 2), Color("8ab8ff"), 2.8, a)
			else:
				draw_set_transform(s + _sh, -0.4, Vector2(1.0, 0.45))  # spłaszczona, pochylona galaktyka
				for k in 6:
					draw_circle(Vector2.ZERO, (20 - k * 3) * zoom, Color(col, 0.13 * a))
				draw_set_transform(_sh)
				_glint(s, Color.WHITE, 3.0, a)
		"comet":
			var dir: Vector2 = -tg.vel.normalized()
			for k in 26:
				draw_circle(s + dir * k * 2.6 * zoom, (4.5 - k * 0.15) * zoom, Color(0.7, 0.9, 1.0, 0.45 - k * 0.016))
			_glint(s, Color.WHITE, 3.5, a)
		_:
			var pts := star_points(tg)
			if state == S.CONNECT and focused:
				for e in info.edges:
					if lit.has(e[0]) and lit.has(e[1]):
						draw_line(pts[e[0]], pts[e[1]], Color("ffcf6b"), 1.0)
				for i in pts.size():
					var on: bool = lit.has(i)
					var near := (aim + wobble()).distance_to(pts[i]) < 11
					_glint(pts[i], Color("ffcf6b") if on else col, 4.5 if near and not on else 3.5, 1.0 if on else (0.7 + 0.3 * sin(t * 4.0 + i)))
			else:
				for i in pts.size():
					_glint(pts[i], col, 3.0 if focused else 2.6, a * (0.85 + 0.15 * sin(t * 3.0 + i)))


func _draw_crosshair() -> void:
	var p := (aim + wobble()).floor()
	var over := state == S.SCAN and not hovered.is_empty()
	if state == S.CONNECT and not target.is_empty():
		over = star_points(target).any(func(q): return q.distance_to(aim) < 10.0)
	if over:  # nad obiektem / gwiazdą celownik wyraźnie drży
		p += Vector2(sin(t * 47.0), cos(t * 53.0)).round() * 2.0
	var c := Color(0.9, 0.95, 1.0, 0.85)
	if state == S.SCAN and not hovered.is_empty():
		c = Color("ffcf6b")
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_line(p + d * 5, p + d * 11, c)
	_px(p.x, p.y, 1, 1, c)


func _draw_panels() -> void:
	var dim := Color("8a90c0")
	_text(Vector2(10, 318), "DYSK %d/%d" % [Game.stored().size(), Game.storage_cap()], dim)
	_text(Vector2(10, 340), "NOC %d:%02d" % [floori(Game.night_left / 60.0), int(Game.night_left) % 60], Color("ff9a6a") if Game.night_left < 40 else dim)
	# prawy panel: odkryte tej nocy
	_text(Vector2(500, 24), "ODKRYTE", Color("ffcf6b"))
	var y := 48.0
	for tg in targets:
		if tg.done and y <= 250:
			_text(Vector2(500, y), tg.info.name.split(" – ")[0].left(15), Color("6affa0"))
			_check(Vector2(622, y - 11))
			y += 18
	var mets: int = Game.today.get("meteors_n", 0)
	if mets > 0 and y <= 250:  # złapane meteory tej nocy (zapisane na dysku, sprzedaje się je na Giełdzie)
		_text(Vector2(500, y), "Meteor" + (" x%d" % mets if mets > 1 else ""), Color("6affa0"))
		_check(Vector2(622, y - 11))
	if state == S.SCAN:
		_text(Vector2(500, 272), "SYGNAŁ", dim)
		var near := proximity()
		for i in 6:
			_px(560 + i * 11, 300 - i * 3, 8, 6 + i * 3, Color("6affa0") if near > i / 6.0 else Color("2a2a40"))
	if state == S.FOCUS:
		var q := quality()
		# pasek pod celem, w środku okularu – wzrok zostaje na gwiazdach
		var label := "OSTROŚĆ %d%%" % q
		_text(Vector2(floorf(320 - Game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x / 2), 262), label, Color("ffcf6b") if q >= SHARP else Color("f4ecdc"))
		# stary wariant: pasek jakości + pozycja pierścienia
		# _px(254, 268, 132, 8, Color("2a2a40"))
		# _px(254, 268, 1.32 * q, 8, Color("6affa0") if q >= SHARP else Color("8aa8ff"))
		# _px(254 + 132 * f - 1, 265, 3, 14, Color("f4ecdc"))
		var g := roundf(green() * BAR_K)
		_px(229, 267, 182, 12, Color("0a0a16"))
		_px(230, 268, 180, 10, Color("2a2a40"))
		_px(320 - g, 268, g * 2, 10, Color("6affa0") if q >= SHARP else Color("2f8a5a"))
		_px(clampf(roundf(320 + focus_offset() * BAR_K), 230, 409) - 1, 264, 3, 18, Color("f4ecdc"))  # znacznik
	# komunikaty na środku (samouczek: okienko Tutorial przy pierwszym wejściu)
	if center_t > 0:  # komunikat na środku okularu, bez ramki (tekst z obrysem)
		var x := roundf(320 - Game.font.get_string_size(center_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x / 2.0)
		for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_string(Game.font, Vector2(x, 186) + d, center_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.03, 0.02, 0.06, minf(center_t, 1.0)))
		draw_string(Game.font, Vector2(x, 186), center_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(1, 0.95, 0.82, minf(center_t, 1.0)))
	if not result.is_empty():
		var w := maxf(Game.font.get_string_size(result.a, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x, Game.font.get_string_size(result.b, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x) + 24
		_px(320 - w / 2, 262, w, 46, Color(0.06, 0.05, 0.1, 0.95))
		_frame(Rect2(floorf(320 - w / 2), 262, w, 46), Color("ffcf6b"))
		_text(Vector2(320, 281), result.a, Color("ffcf6b"), true)
		_text(Vector2(320, 300), result.b, Color("6affa0"), true)
