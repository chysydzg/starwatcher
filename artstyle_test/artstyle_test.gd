extends Node2D
## Star Watcher – scena testowa artstyle'u: pokój Jani + balkon nad jeziorem (Etap 1), top-down 3/4.
## WSAD/strzałki/lewa gałka – ruch · E/A – akcja · N – dzień/noc

const Art := preload("res://artstyle_test/art.gd")
const NIGHT := Color(0.34, 0.40, 0.66)
const SPEED := 70.0
const MOON_REF := Vector2(578, 214)

var t := 0.0
var night := true
var face := 0          # 0 dół, 1 bok, 2 góra
var flip := false
var toast := ""
var toast_t := 0.0
var clock := 23 * 60 + 40.0
var day := 1
var jania: Sprite2D
var modulate_node: CanvasModulate
var lights: Array[PointLight2D] = []
var fx_lit: Node2D
var fx_glow: Node2D
var hud: Node2D

# obszary chodzenia i przeszkody (stopy Jani)
var walk_areas := [Rect2(44, 100, 352, 218), Rect2(396, 202, 18, 28), Rect2(412, 150, 96, 142)]
var blockers := [Rect2(46, 96, 60, 72), Rect2(246, 96, 84, 34), Rect2(340, 96, 52, 18),
	Rect2(268, 134, 22, 14), Rect2(450, 196, 28, 12), Rect2(476, 256, 20, 12)]
var spots := {"TELESKOP": Vector2(462, 214), "ASTROOS": Vector2(286, 150), "ŁÓŻKO": Vector2(76, 176), "SZAFA": Vector2(366, 122)}


func _ready() -> void:
	var w := get_window()
	w.content_scale_size = Vector2i(640, 360)
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	if not Engine.is_embedded_in_editor():
		w.size = Vector2i(1280, 720)
		w.move_to_center()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	RenderingServer.set_default_clear_color(Art.INK)

	var pngs := {}  # nazwa -> Image (zapisywane do assets/ do ręcznej edycji)
	pngs.ground = Art.ground()
	_sprite(pngs.ground, Vector2.ZERO, self)
	fx_lit = _fx(_draw_lit, false)
	var world := Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var objs := {"bed": [Art.bed(), Vector2(45, 81)], "desk": [Art.desk(), Vector2(244, 61)],
		"chair": [Art.chair(), Vector2(267, 120)], "wardrobe": [Art.wardrobe(), Vector2(339, 37)],
		"telescope": [Art.telescope(), Vector2(444, 168)], "crate": [Art.crate(), Vector2(475, 246)],
		"front_rail": [Art.front_rail(), Vector2(407, 283)], "lamp_post": [Art.lamp_post(), Vector2(434, 304)],
		"tree_a": [Art.tree(0), Vector2(410, -12)], "tree_b": [Art.tree(0), Vector2(446, 8)],
		"pine_a": [Art.tree(1), Vector2(520, -10)], "pine_b": [Art.tree(1), Vector2(612, 14)],
		"ruin": [Art.ruin(), Vector2(548, -2)], "mobile": [Art.mobile(), Vector2(106, 98)]}
	for k in objs:
		pngs[k] = objs[k][0]
		var s := _sprite(objs[k][0], objs[k][1], world)
		if k == "mobile":  # wisi nad podłogą: sortuj po cieniu na podłodze
			s.offset.y -= 54
			s.position.y += 54
	pngs.jania = Art.jania_sheet()
	jania = Sprite2D.new()
	jania.texture = ImageTexture.create_from_image(pngs.jania)
	jania.hframes = 4
	jania.vframes = 3
	jania.offset = Vector2(-10, -29)
	jania.position = Vector2(200, 190)
	world.add_child(jania)
	fx_glow = _fx(_draw_glow, true)

	modulate_node = CanvasModulate.new()
	modulate_node.color = NIGHT
	add_child(modulate_node)
	for l in [[Vector2(278, 82), "6affa0", 0.9, 0.5], [Vector2(318, 86), "ffc070", 1.1, 1.0],
			[Vector2(166, 120), "8aa8ff", 0.6, 1.3], [Vector2(440, 140), "ffc070", 0.8, 0.9],
			[Vector2(495, 140), "ffc070", 0.8, 0.9], [Vector2(441, 312), "ffd890", 1.2, 1.4],
			[Vector2(484, 252), "ff9a6a", 0.5, 0.4]]:
		lights.append(_light(l[0], Color(l[1]), l[2], l[3]))

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud.bind(hud))
	layer.add_child(hud)
	_save_pngs.call_deferred(pngs)


func _sprite(im: Image, top_left: Vector2, parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(im)
	s.centered = false
	s.offset = Vector2(0, -im.get_height())  # pozycja = podstawa obiektu (do y-sort)
	s.position = top_left + Vector2(0, im.get_height())
	parent.add_child(s)
	return s


func _fx(cb: Callable, unshaded: bool) -> Node2D:
	var n := Node2D.new()
	n.draw.connect(cb.bind(n))
	if unshaded:
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		n.material = m
	add_child(n)
	return n


func _light(pos: Vector2, col: Color, energy: float, size: float) -> PointLight2D:
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(0.5, 0.0)
	g.gradient = Gradient.new()
	g.gradient.set_color(0, Color.WHITE)
	g.gradient.set_color(1, Color(1, 1, 1, 0))
	var l := PointLight2D.new()
	l.texture = g
	l.texture_scale = size
	l.color = col
	l.energy = energy
	l.set_meta("energy", energy)
	l.position = pos
	add_child(l)
	return l


func _save_pngs(pngs: Dictionary) -> void:
	var dir := "res://artstyle_test/assets/"
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return
	for k in pngs:
		pngs[k].save_png(dir + k + ".png")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_E):
		_interact()
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_N:
		_set_night(not night)


func _nearest_spot() -> String:
	for k in spots:
		if jania.position.distance_to(spots[k]) < 26:
			return k
	return ""


func _interact() -> void:
	match _nearest_spot():
		"ŁÓŻKO":
			if night:
				day += 1
			_set_night(not night)
			_toast("AUTOZAPIS. DZIEŃ %d" % day if not night else "NADCHODZI NOC")
		"TELESKOP": _toast("VIEWPORT TELESKOPU - KOLEJNY KROK")
		"ASTROOS": _toast("ASTROOS V1.0 - KOLEJNY KROK")
		"SZAFA": _toast("GARDEROBA - KOLEJNY KROK")


func _set_night(v: bool) -> void:
	night = v
	clock = 23 * 60 + 40.0 if night else 8 * 60.0
	var tw := create_tween().set_parallel()
	tw.tween_property(modulate_node, "color", NIGHT if night else Color.WHITE, 1.2)
	for l in lights:
		tw.tween_property(l, "energy", l.get_meta("energy") if night else 0.0, 1.2)


func _toast(s: String) -> void:
	toast = s
	toast_t = 2.5


func _process(dt: float) -> void:
	t += dt
	clock += dt * 2.0
	toast_t -= dt
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	v += Vector2(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	v = v.limit_length(1.0)
	if v != Vector2.ZERO:
		_move(Vector2(v.x, 0) * SPEED * dt)
		_move(Vector2(0, v.y) * SPEED * dt)
		if absf(v.x) > absf(v.y):
			face = 1
			flip = v.x < 0
		else:
			face = 0 if v.y > 0 else 2
	var frame := 0
	if v != Vector2.ZERO:
		frame = 1 + int(t * 8.0) % 2
	elif face == 0 and fmod(t, 3.2) < 0.12:
		frame = 3
	jania.frame = face * 4 + frame
	jania.flip_h = flip and face == 1
	for n in [fx_lit, fx_glow, hud]:
		n.queue_redraw()


func _move(d: Vector2) -> void:
	var np := jania.position + d
	var feet := Rect2(np - Vector2(5, 2), Vector2(10, 3))
	var inside := false
	for a in walk_areas:
		if a.encloses(feet):
			inside = true
	if not inside:
		return
	for b in blockers:
		if b.intersects(feet):
			return
	jania.position = np


# --- efekty rysowane pikselami (całkowite współrzędne) ---

func _px(n: CanvasItem, x: float, y: float, w: float, h: float, c: Color) -> void:
	n.draw_rect(Rect2(floori(x), floori(y), w, h), c)


func _draw_lit(n: Node2D) -> void:  # podlega oświetleniu: zmarszczki na wodzie, para z kubka
	for i in 30:
		var x := 490.0 + fposmod(i * 37.0 + t * (3 + i % 3), 150.0)
		var y := 60.0 + (i * 53) % 300
		if Art.is_water(int(x), int(y)) and Art.is_water(int(x) + 5, int(y)):
			_px(n, x, y, 4 + i % 3, 1, Color(1, 1, 1, 0.35 * maxf(0.0, sin(t * 1.4 + i))))
	for i in 3:
		var k := fmod(t * 0.6 + i / 3.0, 1.0)
		_px(n, 485 + sin(k * 6.0 + i) * 2.0, 246 - k * 14.0, 1, 1, Color(1, 1, 1, 0.6 * (1.0 - k)))


func _draw_glow(n: Node2D) -> void:  # świeci samo (niezależnie od nocy)
	# ekran CRT AstroOS
	var sx := 261
	var sy := 70
	for i in 4:
		var ly := sy + 2 + (i * 4 + int(t * 2.0)) % 16
		_px(n, sx + 2, ly, 4 + (i * 5 + int(t)) % 12, 1, Color("6affa0", 0.85))
	if fmod(t, 1.0) < 0.5:
		_px(n, sx + 16, sy + 16, 2, 2, Color("6affa0"))
	_px(n, 280, 91, 1, 1, Color("6affa0") if fmod(t, 0.7) < 0.35 else Color("2a6a3a"))
	# girlanda na barierce balkonu
	for x in range(409, 512):
		var sag := 3.0 * sin(PI * fposmod(x - 409.0, 17.0) / 17.0)
		_px(n, x, 136 + sag, 1, 1, Art.INK)
		if (x - 413) % 6 == 0:
			var c := Color("ffd27a") if (x / 6) % 2 else Color("ff9a6a")
			c.a = 0.55 + 0.45 * sin(t * 2.0 + x * 0.5)
			_px(n, x, 137 + sag, 1, 2, c)
	if not night:
		for i in 12:  # odblaski słońca na wodzie
			var x := 500.0 + fposmod(i * 41.0 + t * 5.0, 136.0)
			var y := 70.0 + (i * 71) % 280
			if Art.is_water(int(x), int(y)):
				_px(n, x, y, 3, 1, Color(1, 1, 1, 0.8 * maxf(0.0, sin(t * 2.0 + i * 1.7))))
		return
	# gwiazdy i księżyc w oknie
	for i in 14:
		var a := 0.4 + 0.6 * absf(sin(t * (0.8 + i % 4 * 0.4) + i))
		var q := Vector2(141 + (i * 29) % 50, 50 + (i * 17) % 31)
		if absf(q.x - 166) > 1 and absf(q.y - 65) > 1:
			_px(n, q.x, q.y, 1, 1, Color(1, 0.96, 0.8, a))
	n.draw_circle(Vector2(182, 56), 4, Color("f8e9b4"))
	_px(n, 180, 55, 1, 1, Color("d9c38e"))
	# odbicie księżyca na jeziorze
	for row in range(-20, 21, 2):
		var wdt := int((12.0 - absf(row) * 0.45) + 3.0 * sin(t * 1.7 + row * 0.6))
		var off := int(2.0 * sin(t * 1.1 + row * 0.9))
		if wdt > 1:
			_px(n, MOON_REF.x - wdt / 2 + off, MOON_REF.y + row, wdt, 1, Color(0.97, 0.91, 0.70, 0.9 - absf(row) / 30.0))
	# gwiazdy odbite w wodzie
	for i in 22:
		var q := Vector2(496 + (i * 47) % 140, 70 + (i * 97) % 285)
		if Art.is_water(int(q.x), int(q.y)) and q.distance_to(MOON_REF) > 24:
			_px(n, q.x, q.y, 1, 1, Color(1, 0.96, 0.8, 0.5 * absf(sin(t * 1.3 + i))))


func _draw_hud(n: Node2D) -> void:
	n.draw_rect(Rect2(6, 6, 96, 21), Color(Art.INK, 0.85))
	n.draw_rect(Rect2(7, 7, 94, 1), Color("4a3f6a"))
	Art.text(n, Vector2(11, 10), "$", Color("ffcf6b"))
	Art.text(n, Vector2(19, 10), "120", Color("f4ecdc"))
	Art.text(n, Vector2(45, 10), "PW", Color("6affa0"))
	Art.text(n, Vector2(55, 10), "35", Color("f4ecdc"))
	var m := int(clock) % (24 * 60)
	Art.text(n, Vector2(11, 18), "DZIEŃ %d  %02d:%02d" % [day, m / 60, m % 60], Color("9aa0d0"))
	var hint := "WSAD RUCH  E AKCJA  N DZIEŃ/NOC"
	Art.text(n, Vector2(634 - hint.length() * 4, 350), hint, Color(1, 1, 1, 0.6))
	var spot := _nearest_spot()
	if spot != "":
		var label := "[E] " + spot
		var x := jania.position.x - label.length() * 2
		n.draw_rect(Rect2(x - 3, jania.position.y - 44, label.length() * 4 + 5, 10), Color(Art.INK, 0.85))
		Art.text(n, Vector2(x, jania.position.y - 42), label, Color("ffcf6b"))
	if toast_t > 0.0:
		var w := toast.length() * 4 + 10
		n.draw_rect(Rect2(320 - w / 2, 330, w, 13), Color(Art.INK, 0.9))
		Art.text(n, Vector2(325 - w / 2, 334), toast, Color("f4ecdc"))
