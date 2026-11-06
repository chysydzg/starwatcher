extends Node2D
## Świat Etapu 1: pokój Jani (top-down 3/4) i balkon (widok zza pleców), Jania, dzień/noc, HUD,
## interakcje, przejścia, pauza, podsumowanie dnia. Viewporty: telescope.gd i astroos.gd.
## Meble i rekwizyty to osobne sprite'y sortowane po podstawie (y), kolizje z ich „stopek” z *_layout.json.

const NIGHT_TINT := Color(0.34, 0.38, 0.64)
const SPEED := 72.0
const ROOM_WALK := Rect2(26, 122, 588, 220)
const BALCONY_WALK := Rect2(36, 318, 572, 36)
const ROOM_SPOTS := {"komputer": [Vector2(404, 152), 22, "Komputer"], "lozko": [Vector2(56, 206), 26, "Łóżko"],
	"drzwi": [Vector2(541, 128), 22, "Drzwi na balkon"], "szafa": [Vector2(598, 136), 22, "Szafa"],
	"plakat": [Vector2(264, 128), 18, "Plakat"], "model": [Vector2(149, 128), 16, "Model Układu Słonecznego"],
	"paczka": [Vector2(500, 146), 20, "Paczka"], "radio": [Vector2(596, 344), 22, "Radio"]}
const BALCONY_SPOTS := {"wroc": [Vector2(44, 336), 24, "Wróć do pokoju"], "teleskop": [Vector2(214, 340), 20, "Teleskop"],
	"krzeslo": [Vector2(433, 352), 16, "Krzesło"], "skrzynka": [Vector2(488, 350), 14, "Kubek"], "kwiatek": [Vector2(582, 352), 16, "Kwiatek"]}

var room: Node2D
var balcony: Node2D
var room_sort: Node2D
var balcony_sort: Node2D
var sky_fx: Node2D
var jania: Sprite2D
var modulate_node: CanvasModulate
var lights: Array[PointLight2D] = []
var glow: Node2D
var props := {}
var feet := {"room": [], "balcony": []}
var hud: Node2D
var ui: CanvasLayer
var top: CanvasLayer
var crt: ColorRect
var fade: ColorRect
var daynight: Button
var viewport: Control = null
var face := 0
var flip := false
var t := 0.0
var idle_t := 0.0
var happy_t := 0.0
var busy := false
var tired_told := false
var ency_acc := 0.0
var toasts := []
var tip := ""


func _ready() -> void:
	name = "World"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	RenderingServer.set_default_clear_color(Color("1a1426"))
	jania = Sprite2D.new()
	jania.texture = Game.tex("jania")
	jania.hframes = 7
	jania.vframes = 3
	jania.offset = Vector2(-18, -52)
	_build_room()
	_build_balcony()
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	glow = Node2D.new()
	glow.draw.connect(_draw_glow)
	_layer(1).add_child(glow)
	ui = _layer(5)
	crt = ColorRect.new()
	crt.size = Vector2(640, 360)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt.material = ShaderMaterial.new()
	crt.material.shader = load("res://game/crt.gdshader")
	_layer(8).add_child(crt)
	var hud_layer := _layer(10)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud)
	hud_layer.add_child(hud)
	daynight = Button.new()
	daynight.position = Vector2(548, 30)
	daynight.custom_minimum_size = Vector2(86, 0)
	daynight.focus_mode = Control.FOCUS_NONE
	daynight.pressed.connect(_toggle_phase)
	hud_layer.add_child(daynight)
	top = _layer(20)
	fade = ColorRect.new()
	fade.color = Color("1a1426")
	fade.size = Vector2(640, 360)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fade)
	Game.toast.connect(_toast)
	Game.changed.connect(_refresh)
	_enter(Game.location, true)
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)
	if Game.day == 1 and Game.night and not Game.tips.has("start"):
		Game.tips.start = true
		_tip("Pierwsza noc. Podejdź do teleskopu od strony okularu i naciśnij " + Game.key("interact") + ".")


func _layer(n: int) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.layer = n
	add_child(l)
	return l


func _sprite(tex_name: String, pos: Vector2, parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Game.tex(tex_name)
	s.centered = false
	s.position = pos
	parent.add_child(s)
	return s


## tło + sortowane obiekty z layoutu; zwraca węzeł sortujący (Jania trafia do niego)
func _scene(where: String, root: Node2D) -> Node2D:
	_sprite(where, Vector2.ZERO, root)
	var sorter := Node2D.new()
	sorter.y_sort_enabled = true
	root.add_child(sorter)
	for p in Game.layout(where):
		var s := Sprite2D.new()
		s.texture = Game.tex(p.name)
		s.centered = false
		s.position = Vector2(p.x, p.base)        # sortowanie po podstawie obiektu
		s.offset = Vector2(0, p.y - p.base)
		sorter.add_child(s)
		props[p.name] = s
		var f: Array = p.foot
		feet[where].append(Rect2(f[0], f[1], f[2] - f[0], f[3] - f[1]))
	return sorter


func _build_room() -> void:
	room = Node2D.new()
	add_child(room)
	room_sort = _scene("room", room)
	var desk: Sprite2D = props.room_desk
	_sprite("sticky_note", Vector2(386, 103) - desk.position, desk)  # karteczka: Teleskop → Dysk → Komputer
	props.lcd = _lcd_patch(desk)
	props.poster = _sprite("poster_iwtb", Vector2(26, 32), room.get_child(0))
	props.radio = _sprite("radio", Vector2(588, 285) - props.room_box.position, props.room_box)
	props.parcel = Sprite2D.new()
	props.parcel.texture = Game.tex("parcel")
	props.parcel.position = Vector2(489, 136)
	props.parcel.offset = Vector2(0, -24)
	props.parcel.centered = false
	room_sort.add_child(props.parcel)
	feet.room.append(Rect2(488, 126, 26, 12))
	for l in [[Vector2(114, 88), "ffc070", 1.0, 1.1], [Vector2(412, 82), "ffc070", 0.9, 0.9], [Vector2(363, 84), "6affa0", 0.7, 0.5],
			[Vector2(191, 60), "8aa8ff", 0.6, 1.4], [Vector2(172, 218), "ffd890", 0.9, 1.3], [Vector2(541, 70), "8aa8ff", 0.4, 1.0]]:
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(0.5, 0.0)
		g.gradient = Gradient.new()
		g.gradient.set_color(0, Color.WHITE)
		g.gradient.set_color(1, Color(1, 1, 1, 0))
		var p := PointLight2D.new()
		p.texture = g
		p.texture_scale = l[3]
		p.color = Color(l[1])
		p.set_meta("e", l[2])
		p.position = l[0]
		room.add_child(p)
		lights.append(p)


## LCD stoi w miejscu CRT: tło za nim odtwarzam z kolumny obok monitora (ściana + blat biurka)
func _lcd_patch(desk: Sprite2D) -> Sprite2D:
	var bg := Game.img("room")
	var dk := Game.img("room_desk")
	var dpos := Vector2i(desk.position + desk.offset)
	var img := Image.create(32, 34, false, Image.FORMAT_RGBA8)
	for y in 34:
		var q := Vector2i(346, 67 + y) - dpos
		var c := bg.get_pixel(346, 67 + y)
		if q.x >= 0 and q.y >= 0 and q.x < dk.get_width() and q.y < dk.get_height() and dk.get_pixelv(q).a > 0.5:
			c = dk.get_pixelv(q)
		img.fill_rect(Rect2i(0, y, 32, 1), c)
	img.blend_rect(Game.img("lcd"), Rect2i(0, 0, 30, 33), Vector2i(1, 1))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	s.position = Vector2(347, 67) - desk.position  # dzieci sprite'a nie dziedziczą offsetu
	desk.add_child(s)
	return s


func _build_balcony() -> void:
	balcony = Node2D.new()
	add_child(balcony)
	balcony_sort = _scene("balcony", balcony)
	sky_fx = preload("res://game/sky_fx.gd").new()
	balcony.add_child(sky_fx)
	balcony.move_child(sky_fx, 1)  # nad tłem, pod rekwizytami
	var chair: Sprite2D = props.balcony_chair
	props.pillow = _sprite("pillow", Vector2(426, 313) - chair.position, chair)
	var crate: Sprite2D = props.balcony_crate
	props.thermos = _sprite("thermos", Vector2(497, 298) - crate.position, crate)


func _refresh() -> void:
	props.lcd.visible = Game.has("lcd")
	props.poster.visible = Game.has("plakat")
	props.radio.visible = Game.has("radio")
	props.parcel.visible = not Game.parcels.is_empty()
	props.pillow.visible = Game.has("poduszka")
	props.thermos.visible = Game.has("termos")
	daynight.text = "NOC " + Game.key("daynight")
	crt.visible = Game.settings.crt
	sky_fx.raining = Game.rain


# ---------------------------------------------------------------- fazy i miejsca
func _apply_phase(instant := false) -> void:
	var col := NIGHT_TINT if Game.night and Game.location == "room" else Color.WHITE
	for l in lights:
		var e: float = l.get_meta("e") if Game.night else 0.0
		if instant:
			l.energy = e
		else:
			create_tween().tween_property(l, "energy", e, 1.5)
	if instant:
		modulate_node.color = col
	else:
		create_tween().tween_property(modulate_node, "color", col, 1.5)
	_refresh()


func _toggle_phase() -> void:
	if Game.night or busy or viewport:
		return
	Game.start_night()
	tired_told = false
	_toast("Zapada noc. Niebo rozbłyska gwiazdami.", "info")
	if Game.rain:
		_toast("Pada deszcz – chmury zasłaniają część nieba.", "info")
	_apply_phase()


func _enter(where: String, instant := false) -> void:
	Game.location = where
	room.visible = where == "room"
	balcony.visible = where == "balcony"
	if jania.get_parent():
		jania.get_parent().remove_child(jania)
	(balcony_sort if where == "balcony" else room_sort).add_child(jania)
	if where == "balcony":
		jania.position = Vector2(64, 340)
		face = 1
		flip = false
	elif not instant:
		jania.position = Vector2(541, 136)
		face = 0
	elif jania.position == Vector2.ZERO:
		jania.position = Vector2(300, 220)
	_apply_phase(true)


func _go(where: String) -> void:
	busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.3)
	tw.tween_callback(func(): _enter(where))
	tw.tween_property(fade, "color:a", 0.0, 0.3)
	tw.tween_callback(func(): busy = false)


# ---------------------------------------------------------------- pętla
func _process(dt: float) -> void:
	t += dt
	if Game.night:
		Game.night_left = maxf(0.0, Game.night_left - dt)
		if Game.has("encyklopedia"):
			ency_acc += 0.5 * mini(Game.discovered.size(), 20) * dt
			if ency_acc >= 1.0:
				Game.add_pw(floorf(ency_acc))
				ency_acc -= floorf(ency_acc)
		if Game.night_left <= 0.0 and not tired_told:
			tired_told = true
			_toast("Jania ziewa... Pora iść spać.", "info")
			if viewport and viewport.has_method("tired"):
				viewport.tired()
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i].t -= dt
		if toasts[i].t <= 0:
			toasts.remove_at(i)
	if viewport == null and not busy:
		_move(dt)
	_animate(dt)
	daynight.visible = not Game.night and viewport == null and not busy
	glow.queue_redraw()
	hud.queue_redraw()


func _move(dt: float) -> void:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var walking := v.length() > 0.1
	jania.set_meta("walking", walking)
	if not walking:
		return
	idle_t = 0.0
	var step := v.normalized() * SPEED * dt
	_try(Vector2(step.x, 0))
	_try(Vector2(0, step.y))
	if absf(v.x) >= absf(v.y):
		face = 1
		flip = v.x < 0
	else:
		face = 0 if v.y > 0 else 2


func _try(d: Vector2) -> void:
	var np := jania.position + d
	var box := Rect2(np - Vector2(6, 3), Vector2(12, 4))  # stopy Jani
	var area := BALCONY_WALK if Game.location == "balcony" else ROOM_WALK
	if not area.encloses(box):
		return
	for b in feet[Game.location]:
		if b.intersects(box):
			return
	jania.position = np


func _animate(dt: float) -> void:
	idle_t += dt
	happy_t -= dt
	var frame := 0
	var walking: bool = jania.get_meta("walking", false)
	if walking:
		frame = 1 + int(t * 9.0) % 4 if face == 1 else 1 + int(t * 7.0) % 2
	elif happy_t > 0:
		face = 0
		frame = 6
	elif face == 0:
		var c := fmod(idle_t, 9.0)  # idle: mrugnięcie, a co jakiś czas ucho opada i Jania podnosi je łapką
		if c > 6.0 and c < 6.6:
			frame = 4
		elif c >= 6.6 and c < 7.6:
			frame = 5
		elif fmod(idle_t, 3.2) < 0.12:
			frame = 3
	elif Game.location == "balcony" and face == 1 and idle_t > 0.8 and viewport == null:
		face = 2  # na balkonie po chwili odwraca się do nieba
	jania.frame = face * 7 + frame
	jania.flip_h = flip and face == 1


func _spots() -> Dictionary:
	return BALCONY_SPOTS if Game.location == "balcony" else ROOM_SPOTS


func _nearest() -> String:
	var sp := _spots()
	for k in sp:
		if (k == "paczka" and Game.parcels.is_empty()) or (k == "radio" and not Game.has("radio")):
			continue
		if jania.position.distance_to(sp[k][0]) < sp[k][1]:
			return k
	return ""


func _unhandled_input(e: InputEvent) -> void:
	if busy or viewport:
		return
	if e.is_action_pressed("back") or e.is_action_pressed("pause"):
		_pause()
	elif e.is_action_pressed("daynight"):
		if Game.night:
			_toast("Noc trwa. Do łóżka trzeba dojść samemu.", "info")
		else:
			_toggle_phase()
	elif e.is_action_pressed("interact"):
		_interact(_nearest())


func _interact(k: String) -> void:
	match k:
		"teleskop":
			if not Game.night:
				_say("Za jasno. Wrócę w nocy.")
			elif Game.night_left <= 0:
				_say("Oczy same mi się zamykają... Pora spać.")
			else:
				face = 1
				flip = false
				_open(preload("res://game/telescope.gd").new())
		"komputer":
			_open(preload("res://game/astroos.gd").new())
		"drzwi":
			if Game.night:
				_go("balcony")
			else:
				_say("Za dnia na balkonie nic nie zobaczę. Wrócę w nocy.")
		"wroc":
			_go("room")
		"lozko":
			if Game.night:
				_sleep()
			else:
				_say("Jeszcze nie pora spać.")
		"paczka":
			Game.unpack_all()
		"szafa":
			_say("Moje ogrodniczki. Najwygodniejsze na świecie.")
		"plakat":
			_say("Kiedyś narysuję własną mapę nieba.")
		"model":
			_say("Model z podstawówki. Saturn trzyma się na taśmie.")
		"radio":
			_say("Trochę jazzu do liczenia gwiazd.")
		"krzeslo":
			_say("Chwila odpoczynku z widokiem na jezioro.")
		"skrzynka":
			_say("Gorąca czekolada. Najlepsze paliwo astronomki." if Game.has("termos") else "Pusty kubek. Przydałby się termos.")
		"kwiatek":
			_say("Rośnie jak na drożdżach.")


func _say(s: String) -> void:
	_toast("„%s”" % s, "say")


func _open(v: Control) -> void:
	viewport = v
	ui.add_child(v)
	v.closed.connect(func(): viewport = null; _refresh())
	if v.has_signal("discovered"):
		v.discovered.connect(func(): happy_t = 1.6; idle_t = 0.0)
	if v.has_signal("all_done"):
		v.all_done.connect(func(): _say("Chyba odkryłam już wszystko na dziś."))
	if v.has_signal("stage_complete"):
		v.stage_complete.connect(_stage_complete)


# ---------------------------------------------------------------- sen i podsumowanie dnia
func _sleep() -> void:
	busy = true
	var s := Game.sleep()
	var p := _panel(Vector2(400, 290))
	var lines := [["PODSUMOWANIE DNIA %d" % s.day, ""], [s.calendar, ""],
		["Odkrycia sprzedane (Centrum) x%d" % s.get("sales_n", 0), "+$%d" % s.get("sales", 0)],
		["Meteory x%d" % s.get("meteors_n", 0), "+$%d" % s.get("meteors", 0)],
		["RAZEM", "+$%d" % (s.get("sales", 0) + s.get("meteors", 0))],
		["Punkty Wiedzy", "+%d PW" % s.get("pw", 0)], ["", ""],
		["Prognoza na noc: " + s.forecast, ""], ["Autozapis wykonany.", ""]]
	for i in lines.size():
		var row := HBoxContainer.new()
		row.position = Vector2(14, 10 + i * 24)
		row.size = Vector2(372, 20)
		var a := Label.new()
		a.text = lines[i][0]
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == 0 or i == 4:
			a.add_theme_color_override("font_color", Color("ffcf6b"))
		var b := Label.new()
		b.text = lines[i][1]
		b.add_theme_color_override("font_color", Color("6affa0"))
		row.add_child(a)
		row.add_child(b)
		row.modulate.a = 0.0
		p.add_child(row)
		create_tween().tween_property(row, "modulate:a", 1.0, 0.2).set_delay(0.15 * i)  # kwoty „nabijają się” po kolei
	var ok := Button.new()
	ok.text = "DZIEŃ DOBRY! " + Game.key("interact")
	ok.position = Vector2(226, 250)
	p.add_child(ok)
	ok.grab_focus.call_deferred()
	ok.pressed.connect(func():
		p.get_parent().queue_free()
		jania.position = Vector2(56, 210)
		face = 0
		_enter("room", true)
		busy = false
		tired_told = false
		if not Game.tips.has("day"):
			Game.tips.day = true
			_tip("Przy komputerze sprzedasz odkrycia i kupisz ulepszenia. Noc: " + Game.key("daynight") + ".")
		_toast("Nowy dzień! " + Game.calendar(), "info"))


func _panel(sz: Vector2) -> Panel:
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.1, 0.7)
	dim.size = Vector2(640, 360)
	top.add_child(dim)
	var p := Panel.new()
	p.size = sz
	p.position = ((Vector2(640, 360) - sz) / 2).floor()
	dim.add_child(p)
	return p


func _pause() -> void:
	get_tree().paused = true
	var p := _panel(Vector2(240, 196))
	var root: Control = p.get_parent()
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	box.position = Vector2(14, 8)
	box.custom_minimum_size = Vector2(212, 0)
	p.add_child(box)
	var close := func():
		get_tree().paused = false
		root.queue_free()
	var title := Label.new()
	title.text = "[ PAUZA ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var add := func(txt: String, cb: Callable) -> Button:
		var b := Button.new()
		b.text = txt
		b.pressed.connect(cb)
		box.add_child(b)
		return b
	add.call("WRÓĆ DO GRY", close).grab_focus.call_deferred()
	add.call("ZAPISZ GRĘ", func(): Game.save_game(); _toast("Zapisano grę.", "good"))
	var crt_b: Button = add.call("EFEKT CRT: " + ("SUBTELNY" if Game.settings.crt else "WYŁ."), func(): pass)
	crt_b.pressed.connect(func():
		Game.settings.crt = not Game.settings.crt
		Game.apply_settings()
		crt_b.text = "EFEKT CRT: " + ("SUBTELNY" if Game.settings.crt else "WYŁ.")
		_refresh())
	add.call("PEŁNY EKRAN", func(): Game.settings.fullscreen = not Game.settings.fullscreen; Game.apply_settings())
	add.call("ZAPISZ I WYJDŹ DO MENU", func():
		Game.save_game()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://game/menu.tscn"))
	root.gui_input.connect(func(ev): if ev.is_action_pressed("back"): close.call())


func _stage_complete() -> void:
	busy = true
	Game.stage_done = true
	Game.save_game()
	var p := _panel(Vector2(560, 190))
	var l := Label.new()
	l.text = "„PIERWSZY DUŻY KROK”\n\nJania pakuje teleskop w folię bąbelkową. Ciężarówka U-Howl\nwiezie ją nad jezioro, do starego budynku z kopułą.\n\nKoniec Etapu 1. Etap 2: Małe Centrum Naukowe – wkrótce."
	l.position = Vector2(14, 10)
	p.add_child(l)
	var b := Button.new()
	b.text = "DO MENU"
	b.position = Vector2(460, 154)
	b.pressed.connect(func(): get_tree().change_scene_to_file("res://game/menu.tscn"))
	p.add_child(b)
	b.grab_focus.call_deferred()


# ---------------------------------------------------------------- komunikaty
func _toast(text: String, kind: String) -> void:
	toasts.push_front({"text": text, "kind": kind, "t": 4.0})
	if toasts.size() > 4:
		toasts.pop_back()


func _tip(s: String) -> void:
	tip = s
	get_tree().create_timer(9.0).timeout.connect(func(): if tip == s: tip = "")


# ---------------------------------------------------------------- rysowanie: poświaty i HUD
func _px(n: CanvasItem, x: float, y: float, w: float, h: float, c: Color) -> void:
	n.draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _draw_glow() -> void:
	if Game.location != "room" or viewport:
		return
	var n := glow
	var panes := [Rect2(163, 29, 27, 21), Rect2(192, 29, 27, 21), Rect2(163, 52, 27, 21), Rect2(192, 52, 27, 21),
		Rect2(525, 31, 15, 20), Rect2(542, 31, 15, 20), Rect2(525, 54, 15, 20), Rect2(542, 54, 15, 20)]
	for i in panes.size():
		var r: Rect2 = panes[i]
		if Game.night:
			_px(n, r.position.x, r.position.y, r.size.x, r.size.y, Color("141a40"))
			for k in 4:
				var a := 0.4 + 0.6 * absf(sin(t * (0.7 + k * 0.3) + i * 1.7 + k))
				_px(n, r.position.x + 2 + (k * 7 + i * 5) % int(r.size.x - 3), r.position.y + 2 + (k * 5 + i * 3) % int(r.size.y - 3), 1, 1, Color(1, 0.95, 0.8, a))
		else:
			_px(n, r.position.x, r.position.y, r.size.x, r.size.y, Color("8cc8f0"))
			_px(n, r.position.x, r.position.y + r.size.y - 5, r.size.x, 5, Color("a8d8f4"))
			var cx := fposmod(t * 2.0 + i * 11.0, r.size.x + 10) - 6
			_px(n, r.position.x + clampf(cx, 0, r.size.x - 6), r.position.y + 5, mini(6, int(r.size.x)), 2, Color("f4f8ff"))
	if Game.night:
		n.draw_circle(Vector2(208, 37), 4, Color("f8e9b4"))
		if not Game.has("lcd"):  # ekran CRT AstroOS
			for k in 3:
				_px(n, 355, 75 + (k * 5 + int(t * 2.0)) % 14, 6 + (k * 5 + int(t)) % 9, 1, Color("6affa0", 0.85))
			if fmod(t, 1.0) < 0.5:
				_px(n, 368, 86, 2, 2, Color("6affa0"))
		for lamp in [Rect2(107, 83, 14, 8), Rect2(407, 75, 10, 7)]:
			_px(n, lamp.position.x, lamp.position.y, lamp.size.x, lamp.size.y, Color("ffe6a0"))


func _txt(p: Vector2, s: String, c: Color) -> void:
	hud.draw_string(Game.font, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0, 0, 0, 0.6 * c.a))
	hud.draw_string(Game.font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


func _w(s: String) -> float:
	return Game.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x


func _draw_hud() -> void:
	var n := hud
	if viewport and viewport.get("hide_hud"):
		return
	var bg := Color(0.1, 0.08, 0.15, 0.9)
	n.draw_rect(Rect2(6, 6, 104, 42), bg)
	_txt(Vector2(12, 23), "$ %d" % Game.money, Color("ffcf6b"))
	_txt(Vector2(12, 42), "PW %d" % Game.pw, Color("6affa0"))
	var cal := Game.calendar()
	n.draw_rect(Rect2(628 - _w(cal), 6, _w(cal) + 6, 22), bg)
	_txt(Vector2(631 - _w(cal), 23), cal, Color("c8c4e8"))
	if Game.night:  # pasek pozostałego czasu nocy
		var frac := Game.night_left / Game.night_length()
		n.draw_rect(Rect2(500, 30, 134, 20), bg)
		_txt(Vector2(504, 46), "NOC %d:%02d" % [int(Game.night_left) / 60, int(Game.night_left) % 60], Color("c8c4e8"))
		n.draw_rect(Rect2(578, 36, 52, 8), Color("2a2a40"))
		n.draw_rect(Rect2(578, 36, 52 * frac, 8), Color("8aa8ff") if frac > 0.2 else Color("ff9a6a"))
	var y := 74.0
	for tt in toasts:
		var col: Color = {"good": Color("6affa0"), "info": Color("f4ecdc"), "say": Color("ffcf6b"), "bad": Color("ff8a8a")}[tt.kind]
		var w := _w(tt.text) + 10
		col.a = clampf(tt.t, 0, 1)
		n.draw_rect(Rect2(634 - w, y - 16, w, 21), Color(0.1, 0.08, 0.15, 0.85 * col.a))
		_txt(Vector2(639 - w, y), tt.text, col)
		y += 23
	if viewport:
		return
	var k := _nearest()
	if k != "" and not busy:
		var label: String = Game.key("interact") + " " + _spots()[k][2]
		var w := _w(label)
		var p := (jania.position + Vector2(-w / 2, -60)).floor()
		p.x = clampf(p.x, 6, 634 - w)
		n.draw_rect(Rect2(p.x - 4, p.y - 16, w + 8, 21), Color(0.1, 0.08, 0.15, 0.9))
		_txt(p, label, Color("ffcf6b"))
		var first := {"komputer": "Komputer: sprzedaż odkryć, sklep i drzewko badań.", "teleskop": "Teleskop: szukaj świecących obiektów na niebie."}
		if first.has(k) and not Game.tips.has("near_" + k):
			Game.tips["near_" + k] = true
			_tip(first[k])
	if tip != "":
		var w := _w(tip)
		n.draw_rect(Rect2(320 - w / 2 - 6, 332, w + 12, 22), Color(0.1, 0.08, 0.15, 0.9))
		_txt(Vector2(320 - w / 2, 349), tip, Color("f4ecdc"))
