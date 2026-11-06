extends Node2D
## Świat Etapu 1: pokój Jani (top-down 3/4) i balkon (widok zza pleców), Jania, dzień/noc, HUD,
## interakcje, przejścia, pauza, podsumowanie dnia. Viewporty: telescope.gd i astroos.gd.
## Meble i rekwizyty to osobne sprite'y sortowane po podstawie (y), kolizje z ich „stopek” z *_layout.json.

const NIGHT_TINT := Color(0.34, 0.38, 0.64)
const SPEED := 144.0
const ROOM_WALK := Rect2(14, 122, 612, 224)
const BALCONY_WALK := Rect2(20, 318, 610, 42)
const REACH := 24.0   # jak blisko obiektu (od jego krawędzi) trzeba stanąć
const ROOM_SPOTS := {"komputer": [Rect2(334, 104, 94, 48), "Komputer"], "lozko": [Rect2(12, 96, 88, 100), "Łóżko"],
	"drzwi": [Rect2(518, 104, 46, 18), "Drzwi na balkon"], "szafa": [Rect2(568, 104, 62, 24), "Szafa"],
	"plakat": [Rect2(248, 104, 32, 18), "Plakat"], "model": [Rect2(132, 104, 34, 18), "Model Układu Słonecznego"],
	"paczka": [Rect2(488, 126, 26, 12), "Paczka"], "radio": [Rect2(572, 312, 48, 22), "Radio"]}
const BALCONY_SPOTS := {"wroc": [Rect2(0, 300, 66, 60), "Wróć do pokoju"], "teleskop": [Rect2(214, 326, 70, 22), "Teleskop"],
	"krzeslo": [Rect2(416, 330, 34, 16), "Krzesło"], "skrzynka": [Rect2(472, 330, 32, 14), "Kubek"], "kwiatek": [Rect2(564, 330, 36, 16), "Kwiatek"]}

var room: Node2D
var balcony: Node2D
var room_sort: Node2D
var balcony_sort: Node2D
var sky_fx: Node2D
var jania: Sprite2D
var body: CharacterBody2D
var modulate_node: CanvasModulate
var lights: Array[PointLight2D] = []
var pc_light: PointLight2D
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
	jania.centered = false  # offset liczony od lewego-górnego rogu klatki: stopy = pozycja ciała
	jania.offset = Vector2(-18, -52)
	body = CharacterBody2D.new()  # pozycja ciała = stopy Jani
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(26, 8)  # szerokość sylwetki Jani
	body.add_child(shape)
	body.add_child(jania)
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
	daynight.flat = true  # rozpoczęcie nocy: metalowy przycisk z Księżycem w lewym dolnym rogu
	daynight.position = Vector2(4, 320)
	daynight.custom_minimum_size = Vector2(36, 36)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		daynight.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	daynight.draw.connect(func():
		var down := daynight.is_hovered() or daynight.button_pressed  # najechanie = wciśnięty przycisk
		_metal(daynight, Rect2(Vector2.ZERO, daynight.size), down)
		daynight.draw_texture(Game.tex("os/ui_moon"), Vector2(8, 8) + (Vector2.ONE if down else Vector2.ZERO)))
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
		# kolider = cały obrys obiektu (bez 1 px obrysu): przez mebel nie da się przejść ani wejść w niego
		var sz := s.texture.get_size()
		feet[where].append(Rect2(p.x + 1, p.y + 1, sz.x - 2, sz.y - 3))
	return sorter


## kolidery: stopki obiektów + ściany wokół obszaru chodzenia (warstwa 1 pokój, 2 balkon)
func _colliders(where: String, root: Node2D) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 2 if where == "balcony" else 1
	sb.collision_mask = 0
	root.add_child(sb)
	var a: Rect2 = BALCONY_WALK if where == "balcony" else ROOM_WALK
	var walls := [Rect2(a.position.x - 40, a.position.y - 40, a.size.x + 80, 40), Rect2(a.position.x - 40, a.end.y, a.size.x + 80, 40),
		Rect2(a.position.x - 40, a.position.y, 40, a.size.y), Rect2(a.end.x, a.position.y, 40, a.size.y)]
	for r in feet[where] + walls:
		var cs := CollisionShape2D.new()
		cs.shape = RectangleShape2D.new()
		cs.shape.size = r.size
		cs.position = r.get_center()
		sb.add_child(cs)


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
	_colliders("room", room)
	for l in [[Vector2(114, 88), "ffc070", 1.0, 1.1], [Vector2(412, 82), "ffc070", 0.9, 0.9], [Vector2(363, 82), "c8e4ff", 1.0, 0.9],
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
	pc_light = lights.pop_at(2)  # monitor świeci też w dzień i migocze razem z obrazem – sterowany w _process


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
	_colliders("balcony", balcony)
	props.thermos = _sprite("thermos", Vector2(497, 298) - crate.position, crate)


func _refresh() -> void:
	props.lcd.visible = Game.has("lcd")
	props.poster.visible = Game.has("plakat")
	props.radio.visible = Game.has("radio")
	props.parcel.visible = not Game.parcels.is_empty()
	props.pillow.visible = Game.has("poduszka")
	props.thermos.visible = Game.has("termos")
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
	busy = true
	var o := Control.new()
	o.size = Vector2(640, 360)
	top.add_child(o)
	var k := {"t": 0.0}
	o.draw.connect(func(): _draw_dusk(o, k.t))
	var tw := create_tween()
	tw.tween_method(func(v): k.t = v; o.queue_redraw(), 0.0, 1.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		var b := Button.new()
		b.text = "KONTYNUUJ"
		b.position = Vector2(260, 318)
		b.custom_minimum_size = Vector2(120, 30)
		o.add_child(b)
		b.grab_focus()
		b.pressed.connect(func():
			o.queue_free()
			busy = false
			_start_night()))


func _draw_dusk(o: Control, t: float) -> void:
	var sky := Color("8cc8f0").lerp(Color("f0a070"), clampf(t * 2.0, 0, 1)).lerp(Color("141a40"), clampf(t * 2.0 - 1.0, 0, 1))
	o.draw_rect(Rect2(0, 0, 640, 360), sky)
	o.draw_rect(Rect2(0, 236, 640, 40), Color(1, 0.7, 0.45, 0.45 * sin(t * PI)))  # łuna nad horyzontem
	for i in 60:  # gwiazdy wychodzą po zmroku
		var a := clampf(t * 3.0 - 2.0 - (i % 5) * 0.1, 0, 1)
		o.draw_rect(Rect2((i * 97) % 640, (i * 53) % 230, 1, 1), Color(1, 0.95, 0.85, a))
	var c := Vector2(320, 286)
	var sun := (c + Vector2.from_angle(lerpf(-PI / 2, 0.3, t)) * Vector2(260, 220)).floor()  # Słońce zachodzi łukiem
	o.draw_circle(sun, 26, Color(1, 0.85, 0.4, 0.25))
	o.draw_circle(sun, 18, Color("ffd86a"))
	var m := clampf((t - 0.35) / 0.65, 0, 1)
	if m > 0:  # Księżyc wschodzi łukiem z drugiej strony
		var moon := (c + Vector2.from_angle(lerpf(PI, PI * 1.5, m)) * Vector2(260, 220)).floor()
		o.draw_circle(moon, 15, Color("f4ecc8"))
		o.draw_circle(moon + Vector2(6, -4), 13, sky)
	var ground := Color("4a7a3a").lerp(Color("0c0a14"), t)
	var pts := PackedVector2Array([Vector2(0, 360)])
	for x in range(0, 641, 16):
		pts.append(Vector2(x, 280 + 8 * sin(x * 0.012) + 5 * sin(x * 0.031)).floor())
	pts.append(Vector2(640, 360))
	o.draw_colored_polygon(pts, ground)
	if t > 0.75:
		var s := "Zapada noc"
		_txt_on(o, Vector2(320 - _w(s) / 2, 170).floor(), s, Color(0.96, 0.93, 0.86, (t - 0.75) * 4.0))


func _txt_on(n: CanvasItem, p: Vector2, s: String, c: Color) -> void:
	n.draw_string(Game.font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


func _start_night() -> void:
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
	if body.get_parent():
		body.get_parent().remove_child(body)
	(balcony_sort if where == "balcony" else room_sort).add_child(body)
	body.collision_mask = 2 if where == "balcony" else 1  # kolizje tylko z aktualną sceną
	if where == "balcony":
		body.position = Vector2(64, 340)
		face = 1
		flip = false
	elif not instant:
		body.position = Vector2(541, 136)
		face = 0
	elif body.position == Vector2.ZERO:
		body.position = Vector2(300, 220)
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
	pc_light.energy = (1.1 if Game.night else 0.45) * (0.86 + 0.08 * sin(t * 2.1) + 0.04 * sin(t * 13.0) + (0.12 if fmod(t, 7.0) < 2.5 else 0.0))
	hud.queue_redraw()


func _move(dt: float) -> void:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var walking := v.length() > 0.1
	jania.set_meta("walking", walking)
	if not walking:
		return
	idle_t = 0.0
	body.velocity = v.normalized() * SPEED
	body.move_and_slide()  # ślizga się wzdłuż mebli i ścian
	if absf(v.x) >= absf(v.y):
		face = 1
		flip = v.x < 0
	else:
		face = 0 if v.y > 0 else 2


func _animate(dt: float) -> void:
	idle_t += dt
	happy_t -= dt
	var frame := 0
	var walking: bool = jania.get_meta("walking", false)
	if walking:
		frame = 1 + int(t * 14.0) % 4 if face == 1 else 1 + int(t * 10.0) % 2
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
	var best := ""
	var best_d := 1e9
	for k in sp:
		if (k == "paczka" and Game.parcels.is_empty()) or (k == "radio" and not Game.has("radio")):
			continue
		var r: Rect2 = sp[k][0]
		var d := body.position.distance_to(body.position.clamp(r.position, r.end))
		if d < REACH and d < best_d:
			best_d = d
			best = k
	return best


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
	var rows := []  # [opis, kwota, przyrostek] – tylko to, co faktycznie zebraliśmy
	if s.get("sales_n", 0) > 0:
		rows.append(["Odkrycia x%d" % s.sales_n, s.sales, "$"])
	if s.get("meteors_n", 0) > 0:
		rows.append(["Meteory x%d" % s.meteors_n, s.meteors, "$"])
	if s.get("pw", 0) > 0:
		rows.append(["Punkty Wiedzy", s.pw, "PW"])
	var h := 40 + maxi(rows.size(), 1) * 24 + 24
	var p := _panel(Vector2(380, h))
	p.position = Vector2(130, 308 - h)
	var title := Label.new()
	title.text = "PODSUMOWANIE · " + s.calendar
	title.position = Vector2(14, 8)
	title.add_theme_color_override("font_color", Color("ffcf6b"))
	p.add_child(title)
	if rows.is_empty():
		var l := Label.new()
		l.text = "Spokojny dzień – bez nowych wpływów."
		l.position = Vector2(14, 36)
		p.add_child(l)
	for i in rows.size():
		var a := Label.new()
		a.text = rows[i][0]
		a.position = Vector2(14, 36 + i * 24)
		var v := Label.new()
		v.position = Vector2(220, 36 + i * 24)
		v.size = Vector2(146, 20)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_theme_color_override("font_color", Color("ffcf6b") if rows[i][2] == "$" else Color("6affa0"))
		v.text = ""
		a.modulate.a = 0.0
		p.add_child(a)
		p.add_child(v)
		var fmt: String = "+$%d" if rows[i][2] == "$" else "+%d PW"
		var tw := create_tween()  # wiersz pojawia się, a kwota „nabija się” od zera
		tw.tween_interval(0.3 + 0.8 * i)
		tw.tween_property(a, "modulate:a", 1.0, 0.15)
		tw.tween_method(func(x): v.text = fmt % int(x), 0.0, float(rows[i][1]), 0.6)
		tw.tween_callback(Game.ding.bind(1.0 + 0.15 * i))
	var fc := Label.new()
	fc.text = "Prognoza na noc: " + s.forecast
	fc.position = Vector2(14, h - 28)
	fc.add_theme_color_override("font_color", Color("a8b0d0"))
	p.add_child(fc)
	var ok := Button.new()
	ok.text = "KOLEJNY DZIEŃ"
	ok.custom_minimum_size = Vector2(150, 30)
	ok.position = Vector2(245, 316)
	p.get_parent().add_child(ok)
	ok.grab_focus.call_deferred()
	ok.pressed.connect(func():
		p.get_parent().queue_free()
		body.position = Vector2(56, 210)
		face = 0
		_enter("room", true)
		busy = false
		tired_told = false
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
	if not Game.has("lcd"):
		_pc_screen(n)
	if Game.night:
		n.draw_circle(Vector2(208, 37), 4, Color("f8e9b4"))
		for lamp in [Rect2(107, 83, 14, 8), Rect2(407, 75, 10, 7)]:
			_px(n, lamp.position.x, lamp.position.y, lamp.size.x, lamp.size.y, Color("ffe6a0"))


## miniatura pulpitu AstroOS na monitorze CRT: niebo, wzgórze, płynące chmurki, okienko i kursor
func _pc_screen(n: Node2D) -> void:
	var r := Rect2(353, 73, 20, 17)
	_px(n, r.position.x, r.position.y, r.size.x, 10, Color("6aa8f4"))
	_px(n, r.position.x, r.position.y + 10, r.size.x, 7, Color("6cc83a"))
	_px(n, r.position.x, r.position.y + 9, 12, 2, Color("8ad84a"))
	for k in 2:
		_px(n, r.position.x + fposmod(t * 1.5 + k * 11.0, r.size.x - 3), r.position.y + 2 + k * 3, 3, 1, Color("f4f8ff"))
	if fmod(t, 7.0) < 2.5:  # otwarte okno programu
		_px(n, r.position.x + 5, r.position.y + 3, 11, 9, Color("f4f4f8"))
		_px(n, r.position.x + 5, r.position.y + 3, 11, 2, Color("2a5ad8"))
		for k in 3:
			_px(n, r.position.x + 7, r.position.y + 6 + k * 2, 4 + (k * 3 + int(t * 2.0)) % 5, 1, Color("8a8aa0"))
	_px(n, r.position.x, r.position.y, r.size.x, 1, Color("dcdce4"))
	_px(n, r.position.x + 2 + int(t * 3.0) % 14, r.position.y + 8 + int(t * 1.3) % 6, 1, 2, Color.WHITE)  # kursor
	_px(n, r.position.x, r.position.y + fposmod(t * 6.0, r.size.y), r.size.x, 1, Color(1, 1, 1, 0.18))  # przebiegająca linia CRT


## ramka z polerowanej stali z nitami (styl przyrządu naukowego); inset = ciemny „wyświetlacz” w środku
func _metal(n: CanvasItem, r: Rect2, pressed := false, inset := false) -> void:
	var hi := Color("d8e0ee")
	var lo := Color("2a3044")
	n.draw_rect(r.grow(1), Color("120e1a"))
	n.draw_rect(r, Color("5e6884") if pressed else Color("6c7692"))
	n.draw_rect(Rect2(r.position, Vector2(r.size.x, floorf(r.size.y / 2))), Color("66708c") if pressed else Color("7e88a4"))  # połysk
	n.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), lo if pressed else hi)
	n.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), lo if pressed else hi)
	n.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), hi if pressed else lo)
	n.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), hi if pressed else lo)
	for c in [r.position + Vector2(2, 2), Vector2(r.end.x - 4, r.position.y + 2), Vector2(r.position.x + 2, r.end.y - 4), r.end - Vector2(4, 4)]:
		n.draw_rect(Rect2(c, Vector2(2, 2)), Color("e8eef8"))  # nity
		n.draw_rect(Rect2(c + Vector2.ONE, Vector2.ONE), Color("3a4258"))
	if inset:
		var d := Rect2(r.position + Vector2(6, 5), r.size - Vector2(12, 10))
		n.draw_rect(d, Color("10141f"))
		n.draw_rect(Rect2(d.position, Vector2(d.size.x, 1)), Color("05070c"))
		n.draw_rect(Rect2(d.position.x, d.end.y - 1, d.size.x, 1), Color("8a94ae"))


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
	_metal(n, Rect2(4, 4, 112, 50), false, true)
	_txt(Vector2(14, 25), "$ %d" % Game.money, Color("ffcf6b"))
	_txt(Vector2(14, 44), "PW %d" % Game.pw, Color("6affa0"))
	var cal := Game.calendar()
	_metal(n, Rect2(620 - _w(cal), 4, _w(cal) + 16, 30), false, true)
	_txt(Vector2(628 - _w(cal), 25), cal, Color("c8c4e8"))
	if Game.night:  # pasek pozostałego czasu nocy
		var frac := Game.night_left / Game.night_length()
		_metal(n, Rect2(492, 36, 144, 30), false, true)
		_txt(Vector2(502, 57), "NOC %d:%02d" % [int(Game.night_left) / 60, int(Game.night_left) % 60], Color("c8c4e8"))
		n.draw_rect(Rect2(576, 46, 50, 8), Color("2a2a40"))
		n.draw_rect(Rect2(576, 46, 50 * frac, 8), Color("8aa8ff") if frac > 0.2 else Color("ff9a6a"))
	var y := 90.0 if Game.night else 58.0
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
		var label: String = Game.key("interact") + " " + _spots()[k][1]
		var w := _w(label)
		var p := (body.position + Vector2(-w / 2, -60)).floor()
		p.x = clampf(p.x, 6, 634 - w)
		n.draw_rect(Rect2(p.x - 4, p.y - 16, w + 8, 21), Color(0.1, 0.08, 0.15, 0.9))
		_txt(p, label, Color("ffcf6b"))
	if tip != "":
		var w := _w(tip)
		n.draw_rect(Rect2(320 - w / 2 - 6, 332, w + 12, 22), Color(0.1, 0.08, 0.15, 0.9))
		_txt(Vector2(320 - w / 2, 349), tip, Color("f4ecdc"))
