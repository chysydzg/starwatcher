extends Control
## Okular teleskopu balkonowego (GDD 9): skanowanie → namierzenie (PPM) → wyostrzanie (kółko: balans w przód i w tył)
## → łączenie gwiazd (klikanie świecących gwiazd po kolei) → zapis do Dziennika. Meteory, kometa, deszcz.

signal closed
signal discovered
signal all_done

enum S { SCAN, FOCUS, CONNECT, FULL, RESULT }
const C := Vector2(320, 180)
const R := 172.0
const SKY_SIZE := Vector2(1200, 700)
const STAR_SCALE := 3.0          # rozstaw gwiazd konstelacji na ekranie
const FOCUS_STEP := 0.06         # jeden ząbek kółka
const SHARP := 96                # od tej jakości soczewka „klika”

var is_telescope := true
var hide_hud := true
var state := S.SCAN
var cam := SKY_SIZE / 2
var aim := C
var zoom := 1.0
var t := 0.0
var targets := []
var target := {}
var hovered := {}
var f := 0.5
var idle_focus := 0.0
var sharp_t := 0.0
var lit := {}                    # zaznaczone gwiazdy aktualnej konstelacji
var bursts := []                 # rozbłyski po kliknięciu gwiazdy
var shake := 0.0
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
var _all_told := false
var _sh := Vector2.ZERO


func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	zoom = 1.0 / 1.3 if Game.has("newton") else 1.0  # Newton: pole widzenia +30%
	_rng.seed = Game.day * 977
	_build_sky()
	_build_frame()
	_place_targets()
	next_meteor = _meteor_gap()
	if Game.rain:
		for i in 6:
			clouds.append([Vector2(_rng.randf_range(0, SKY_SIZE.x), _rng.randf_range(0, SKY_SIZE.y)), _rng.randf_range(60, 120)])
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_last_mouse = get_global_mouse_position()
	aim = C
	_check_all_done()


func _meteor_gap() -> float:
	return _rng.randf_range(Game.METEOR_INTERVAL.x, Game.METEOR_INTERVAL.y) / (1.25 if Game.has("plakat") else 1.0)


func tut() -> int:
	return int(Game.tips.get("tut", 0))


func tut_next(step: int) -> void:
	if tut() == step:
		Game.tips.tut = step + 1


# ---------------------------------------------------------------- generowanie nieba i okularu
func _build_sky() -> void:
	var img := Image.create(int(SKY_SIZE.x), int(SKY_SIZE.y), false, Image.FORMAT_RGBA8)
	for y in int(SKY_SIZE.y):
		img.fill_rect(Rect2i(0, y, int(SKY_SIZE.x), 1), Color("0a0d24").lerp(Color("15193f"), float(y) / SKY_SIZE.y))
	for i in 900:
		var p := Vector2i(_rng.randi_range(0, int(SKY_SIZE.x) - 1), _rng.randi_range(0, int(SKY_SIZE.y) - 1))
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
			if d > R + 7:
				img.set_pixel(x, y, Color("0d0a16"))
			elif d > R:
				img.set_pixel(x, y, ring if d < R + 3 else ring_d)
	if not Game.has("achromat"):  # popękana szybka w narożniku
		var p := C + Vector2(104, -100)
		for seg in [[Vector2(0, 0), Vector2(-28, 16)], [Vector2(-28, 16), Vector2(-40, 34)], [Vector2(0, 0), Vector2(-10, 28)]]:
			for i in 30:
				var q: Vector2 = p + seg[0].lerp(seg[1], i / 30.0)
				if q.distance_to(C) < R:
					img.set_pixelv(Vector2i(q), Color(0.85, 0.9, 1.0, 0.3))
	if not Game.has("czyszczacy"):
		for i in 20:
			img.set_pixelv(Vector2i(C + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(20, R - 8)), Color(0.7, 0.65, 0.55, 0.4))
	_frame_tex = ImageTexture.create_from_image(img)


func _place_targets() -> void:
	var used := [SKY_SIZE / 2 + Vector2(-120, 30)]  # pierwszy cel blisko startowego widoku
	var first := true
	for id in Game.visible_objects():
		var p: Vector2 = used[0] if first else Vector2.ZERO
		if not first:
			for tries in 60:
				p = Vector2(_rng.randf_range(150, SKY_SIZE.x - 150), _rng.randf_range(130, SKY_SIZE.y - 130))
				if used.all(func(u): return u.distance_to(p) > 190):
					break
			used.append(p)
		first = false
		var info := Game.obj_info(id)
		var tg := {"id": id, "pos": p, "info": info, "sweet": _rng.randf_range(0.3, 0.7), "done": Game.tonight.has(id), "phase": _rng.randf() * TAU}
		if info.cat in ["nebula", "deep"]:
			tg.width = 0.035  # mgławice: węższy zakres ostrości
		if id == "comet":
			tg.vel = Vector2.from_angle(_rng.randf() * TAU) * 8.0
		targets.append(tg)
	cam = SKY_SIZE / 2


# ---------------------------------------------------------------- geometria
func to_screen(p: Vector2) -> Vector2:
	return C + (p - cam) * zoom


func to_sky(s: Vector2) -> Vector2:
	return cam + (s - C) / zoom


func wobble() -> Vector2:
	var a := 2.5 * (0.6 if Game.has("statyw") else 1.0) * (0.0 if Game.has("mikro") else 1.0)
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
	var r := 26.0
	if tg.info.has("pts"):
		for p in star_points(tg):
			r = maxf(r, p.distance_to(to_screen(tg.pos)) + 12.0)
	return r * (1.2 if Game.has("kursor1") else 1.0) * (1.35 if Game.has("montaz") else 1.0)


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
	var w: float = target.get("width", 0.05)
	var d := absf(f - target.get("sweet", 0.5))
	var q := 100.0 - maxf(0.0, d - w / 2.0) * 230.0
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
	center_t -= dt
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mouse := get_global_mouse_position()
	if mouse.distance_to(_last_mouse) > 0.5:
		aim = mouse
		_last_mouse = mouse
	if Game.pad and mv.length() > 0.2:
		aim += mv * 220.0 * speed_mult() * dt
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
		cam = cam.clamp(Vector2(R, R) / zoom, SKY_SIZE - Vector2(R, R) / zoom)
		var h := hover_target()
		if not h.is_empty() and hovered != h:
			tut_next(0)
		hovered = h
	for c in clouds:
		c[0].x = fposmod(c[0].x + 6.0 * dt, SKY_SIZE.x)
	for tg in targets:
		if tg.has("vel") and not tg.done:
			tg.pos = (tg.pos + tg.vel * dt).clamp(Vector2(140, 140), SKY_SIZE - Vector2(140, 140))
	if state == S.FOCUS:
		var fin := Input.get_action_strength("focus_in") - Input.get_action_strength("focus_out")
		if absf(fin) > 0.1:
			f = clampf(f + fin * 0.5 * dt * _lens(), 0.0, 1.0)
			idle_focus = 0.0
		idle_focus += dt
		if target.id == "comet":  # kometa ucieka: trzeba ją trzymać w celowniku
			cam = cam.lerp(target.pos, dt * 0.6)
			if (aim + wobble()).distance_to(to_screen(target.pos)) > 30:
				f = clampf(f + 0.1 * dt * signf(f - target.sweet + 0.001), 0.0, 1.0)
		else:
			cam = cam.lerp(target.pos, minf(1.0, dt * 10.0))
		if Game.has("auto2") or (Game.has("auto1") and idle_focus > 1.0):
			f = move_toward(f, target.sweet, dt * 0.9)
		if quality() >= SHARP:
			sharp_t += dt
			if sharp_t > 0.35 and idle_focus > 0.3:  # ostro i gracz przestał kręcić → dalej
				_after_focus()
		else:
			sharp_t = 0.0
	if Game.has("meteory") and state != S.FULL:
		next_meteor -= dt
		if next_meteor <= 0 and meteor.is_empty():
			next_meteor = _meteor_gap()
			meteor = {"pos": to_sky(C + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(30, 110)), "vel": Vector2.from_angle(_rng.randf_range(2.3, 2.8)) * 45.0, "t": 0.0}
		if not meteor.is_empty():
			meteor.t += dt
			meteor.pos += meteor.vel * dt
			if meteor.t > Game.METEOR_WINDOW:
				meteor = {}
	for b in bursts:
		b.t += dt
	bursts = bursts.filter(func(b): return b.t < 0.5)
	if state == S.RESULT:
		result.t -= dt
		if result.t <= 0:
			state = S.SCAN
			_check_all_done()
	queue_redraw()


func _lens() -> float:
	return (1.0 + (0.15 if Game.has("czyste1") else 0.0) + (0.25 if Game.has("czyste2") else 0.0)) * (1.1 if Game.has("radio") else 1.0)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_RIGHT:
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
					f = clampf(f + (FOCUS_STEP if e.button_index == MOUSE_BUTTON_WHEEL_UP else -FOCUS_STEP) * _lens(), 0.0, 1.0)
					idle_focus = 0.0
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		if state in [S.FOCUS, S.CONNECT]:
			state = S.SCAN
			target = {}
		elif state != S.FULL:
			close()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("confirm") or (Game.pad and e.is_action_pressed("interact")):
		if state == S.CONNECT:
			_click_star()
		else:
			_lock_or_confirm()
		get_viewport().set_input_as_handled()
	elif state == S.SCAN and (e.is_action_pressed("prev_obj") or e.is_action_pressed("next_obj")):
		_jump(1 if e.is_action_pressed("next_obj") else -1)
		get_viewport().set_input_as_handled()


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
				_show("Meteor złapany!", "+%d PW  +$%d" % r)
				discovered.emit()
				return
			var tg := hover_target()
			if tg.is_empty():
				return
			target = tg
			f = clampf(tg.sweet + (0.3 if _rng.randf() < 0.5 else -0.3), 0.0, 1.0)
			idle_focus = 0.0
			sharp_t = 0.0
			state = S.FOCUS
			tut_next(1)
		S.FOCUS:
			if quality() < 20:
				_center("Za rozmyte – pokręć kółkiem w przód i w tył")
				return
			_after_focus()
		S.RESULT:
			state = S.SCAN


func _after_focus() -> void:
	Game.ding(1.0)  # klik przeskakującej soczewki
	tut_next(2)
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
			Game.ding(1.0 + lit.size() * 0.12)
			if lit.size() == pts.size():
				_finish()
			return


func _finish(replace := false) -> void:
	var q := quality()
	var pts: int = target.info.pts.size() if target.info.has("pts") else 0
	var gained := Game.record(target.id, q, pts, replace)
	if gained < 0:
		state = S.FULL
		_full_dialog()
		return
	target.done = true
	tut_next(3)
	if pts > 0:
		Game.tips.tut_connect = true
	discovered.emit()
	var info: Dictionary = target.info
	_show(("Znak zodiaku: " if info.cat == "zodiac" else "Odkryto: ") + info.name, "jakość %d%%   +%d PW   → Dziennik" % [q, gained])
	target = {}


func _check_all_done() -> void:
	if _all_told or targets.is_empty() or targets.any(func(tg): return not tg.done):
		return
	_all_told = true
	_center("„Chyba odkryłam już wszystko na dziś.”", 5.0)
	all_done.emit()


func _show(a: String, b: String) -> void:
	result = {"a": a, "b": b, "t": 2.2}
	state = S.RESULT


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
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): closed.emit(); queue_free())


# ---------------------------------------------------------------- rysowanie
func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _text(p: Vector2, s: String, c: Color, center := false) -> void:
	var x := p.x - (Game.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x / 2.0 if center else 0.0)
	draw_string(Game.font, Vector2(roundf(x) + 1, p.y + 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0, 0, 0, 0.8 * c.a))
	draw_string(Game.font, Vector2(roundf(x), p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


## jasny punkt z połyskiem w 4 strony (od światła)
func _glint(p: Vector2, col: Color, sz: float, a := 1.0) -> void:
	p = p.floor()
	var size := sz * 1.5  # duże, jasne punkty
	for k in 3:
		draw_circle(p, size * (1.6 - k * 0.45), Color(col, 0.12 * a * (k + 1)))
	var arm := int(size * 2.2)
	for i in range(1, arm):
		var fa := a * (1.0 - float(i) / arm)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			_px(p.x + d.x * i, p.y + d.y * i, 1, 1, Color(col.lightened(0.4), fa))
	_px(p.x - 2, p.y - 1, 5, 3, Color(col.lightened(0.6), a))
	_px(p.x - 1, p.y - 2, 3, 5, Color(col.lightened(0.6), a))
	_px(p.x - 1, p.y - 1, 3, 3, Color(1, 1, 1, a))


func _check(p: Vector2) -> void:  # ✓ przy zbadanym obiekcie
	var c := Color("6affa0")
	for q in [[0, 3], [1, 4], [2, 5], [3, 4], [4, 3], [5, 2], [6, 1], [7, 0]]:
		_px(p.x + q[0], p.y + q[1], 2, 2, Color(0, 0, 0, 0.7))
		_px(p.x + q[0], p.y + q[1] - 1, 1, 2, c)


func _draw() -> void:
	_sh = Vector2(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2)) if shake > 0 else Vector2.ZERO  # lekki wstrząs po kliknięciu gwiazdy
	draw_set_transform(_sh)
	var half := Vector2(R, R)
	draw_texture_rect_region(_sky_tex, Rect2(C - half, half * 2), Rect2(cam - half / zoom, half * 2 / zoom))
	for tg in targets:
		var s := to_screen(tg.pos)
		if s.distance_to(C) < R + 60:
			_draw_target(tg, s)
	for c in clouds:
		var s := to_screen(c[0])
		for k in 4:
			draw_circle(s + Vector2(k * 16 - 24, sin(k) * 6), c[1] * 0.35 * zoom, Color(0.05, 0.05, 0.1, 0.6))
	if not meteor.is_empty():
		var s := to_screen(meteor.pos)
		var a: float = 1.0 - meteor.t / Game.METEOR_WINDOW
		for i in 18:
			_px(s.x - meteor.vel.x * 0.06 * i, s.y - meteor.vel.y * 0.06 * i, 2, 2, Color(1, 0.95, 0.8, a * (1.0 - i / 18.0)))
		_glint(s, Color("fff3c4"), 3.0, a)
	for b in bursts:
		draw_arc(b.p, 4 + b.t * 40, 0, TAU, 24, Color(1, 0.85, 0.4, 1.0 - b.t * 2), 1.0)
	draw_texture(_frame_tex, Vector2.ZERO)
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
		var c2 := Color(0.55, 0.85, 0.65, 0.55)
		if info.has("pts"):
			var pts := star_points(tg)
			for e in info.edges:
				draw_line(pts[e[0]], pts[e[1]], Color(1, 0.8, 0.4, 0.3))
			for p in pts:
				_px(p.x - 1, p.y - 1, 2, 2, c2)
		else:
			draw_circle(s, 6, Color(c2, 0.4))
		_check(s + Vector2(14, -22))
		return
	var blur := 0.0
	if focused and state == S.FOCUS:
		blur = absf(f - tg.sweet)
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
				if Game.has("linie"):
					for e in info.edges:
						if not (lit.has(e[0]) and lit.has(e[1])):
							draw_dashed_line(pts[e[0]], pts[e[1]], Color(0.6, 0.8, 1.0, 0.3), 1.0, 3.0)
				for i in pts.size():
					var on: bool = lit.has(i)
					var near := (aim + wobble()).distance_to(pts[i]) < 11
					_glint(pts[i], Color("ffcf6b") if on else col, 4.5 if near and not on else 3.5, 1.0 if on else (0.7 + 0.3 * sin(t * 4.0 + i)))
			else:
				for i in pts.size():
					_glint(pts[i], col, 3.0 if focused else 2.6, a * (0.85 + 0.15 * sin(t * 3.0 + i)))


func _draw_crosshair() -> void:
	var p := (aim + wobble()).floor()
	var c := Color(0.9, 0.95, 1.0, 0.85)
	if state == S.SCAN and not hovered.is_empty():
		c = Color("ffcf6b")
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_line(p + d * 5, p + d * 11, c)
	_px(p.x, p.y, 1, 1, c)


func _draw_panels() -> void:
	var dim := Color("8a90c0")
	# lewy panel: stan i sterowanie
	var title: String = {S.SCAN: "SKANOWANIE", S.FOCUS: "WYOSTRZANIE", S.CONNECT: "ŁĄCZENIE", S.FULL: "PAMIĘĆ PEŁNA", S.RESULT: "ZAPISANO"}[state]
	_text(Vector2(10, 24), title, Color("ffcf6b"))
	var lines := []
	match state:
		S.SCAN:
			lines = [["PPM", "namierz"], ["Q/E", "następny cel"], ["WSAD", "obróć"], ["ESC", "wyjście"]]
		S.FOCUS:
			lines = [["KÓŁKO", "ostrość"], ["PPM", "zapisz"], ["ESC", "wróć"]]
		S.CONNECT:
			lines = [["LPM", "gwiazda"], ["ESC", "wróć"]]
	if Game.pad:
		lines = lines.map(func(l): return [{"PPM": "A", "LPM": "A", "KÓŁKO": "(R)", "Q/E": "LB/RB", "WSAD": "(L)", "ESC": "B"}.get(l[0], l[0]), l[1]])
	for i in lines.size():
		_text(Vector2(10, 52 + i * 20), "[%s]" % lines[i][0], Color("f4ecdc"))
		_text(Vector2(62 if lines[i][0].length() < 4 else 74, 52 + i * 20), lines[i][1], dim)
	_text(Vector2(10, 318), "DYSK %d/%d" % [Game.stored().size(), Game.storage_cap()], dim)
	_text(Vector2(10, 340), "NOC %d:%02d" % [int(Game.night_left) / 60, int(Game.night_left) % 60], Color("ff9a6a") if Game.night_left < 40 else dim)
	# prawy panel: lista obiektów na dziś
	_text(Vector2(500, 24), "DZIŚ NA NIEBIE", Color("ffcf6b"))
	var y := 48.0
	for tg in targets:
		if y > 250:
			break
		var nm: String = tg.info.name.split(" – ")[0].left(15)
		_text(Vector2(500, y), nm, Color("6affa0") if tg.done else Color("f4ecdc"))
		if tg.done:
			_check(Vector2(622, y - 11))
		y += 18
	if state == S.SCAN:
		_text(Vector2(500, 272), "SYGNAŁ", dim)
		var near := 0.0
		for tg in targets:
			if not tg.done:
				near = maxf(near, clampf(1.0 - (aim + wobble()).distance_to(to_screen(tg.pos)) / 160.0, 0.0, 1.0))
		for i in 6:
			_px(560 + i * 11, 300 - i * 3, 8, 6 + i * 3, Color("6affa0") if near > i / 6.0 else Color("2a2a40"))
	if state == S.FOCUS:
		var q := quality()
		_text(Vector2(500, 272), "OSTROŚĆ %d%%" % q, Color("ffcf6b") if q >= SHARP else Color("f4ecdc"))
		_px(500, 280, 132, 10, Color("2a2a40"))
		_px(500, 280, 1.32 * q, 10, Color("6affa0") if q >= SHARP else Color("8aa8ff"))
		_px(500 + 132 * f - 1, 276, 3, 18, Color("f4ecdc"))  # pozycja pierścienia
	# tutorial i komunikaty na środku
	var msg := ""
	match state:
		S.SCAN:
			if tut() == 0:
				msg = "Najedź na świecący obiekt"
			elif tut() == 1 and not hovered.is_empty():
				msg = "Kliknij PPM, aby go namierzyć"
		S.FOCUS:
			if tut() <= 2:
				msg = "Kręć kółkiem w przód i w tył – szukaj ostrości"
		S.CONNECT:
			if not Game.tips.has("tut_connect"):
				msg = "Zaznacz ciąg gwiazd – klikaj je po kolei"
	if center_t > 0:
		msg = center_msg
	if msg != "":
		var w := Game.font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
		_px(320 - w / 2 - 8, 318, w + 16, 24, Color(0.05, 0.04, 0.1, 0.88))  # tutorial na dole okularu
		draw_rect(Rect2(320 - w / 2 - 8, 318, w + 16, 24), Color("ffcf6b"), false)
		_text(Vector2(320, 336), msg, Color("f4ecdc"), true)
	if state == S.RESULT:
		var w := maxf(Game.font.get_string_size(result.a, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x, Game.font.get_string_size(result.b, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x) + 24
		_px(320 - w / 2, 262, w, 46, Color(0.06, 0.05, 0.1, 0.95))
		draw_rect(Rect2(320 - w / 2, 262, w, 46), Color("ffcf6b"), false)
		_text(Vector2(320, 281), result.a, Color("ffcf6b"), true)
		_text(Vector2(320, 300), result.b, Color("6affa0"), true)
