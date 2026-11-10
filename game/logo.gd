extends Node2D
## Wybór logo obserwatorium (po przeprowadzce, przed Etapem 2): pięć znaków z GDD, wybór raz na zawsze.
## Potem Etap 2 w świecie (world.gd z Game.stage = 2).

const LOGOS := [
	["carrot", "Astro-Carrot", "Marchewka z płomieniem rakiety. Uroczo i przytulnie."],
	["rabbit", "Rabbit-Orbit", "Królik w pierścieniu orbity. Profesjonalne retro."],
	["paws", "Paws & Stars", "Łapka z błyszczącą gwiazdą. Ciepło i przyjaźnie."],
	["crest", "Cosmic Crest", "Mosiężna tarcza z księżycem. Elegancko i klasycznie."],
	["void", "Deep Void", "Czarna dziura z dyskiem. Nowocześnie, sci-fi."],
]

var _ui: CanvasLayer
var _name: Label
var _desc: Label
var _row: HBoxContainer
var _ask: VBoxContainer
var _pick := 0
var _fade: ColorRect


func _ready() -> void:
	name = "Logo"
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RenderingServer.set_default_clear_color(Color("0e0c1e"))
	var cam := Camera2D.new()
	cam.position = Vector2(320, 180)
	add_child(cam)
	var stars := Node2D.new()  # migoczące gwiazdy w tle
	stars.draw.connect(func():
		for i in 70:
			var p := Vector2((i * 97 + 13) % 680 - 20, (i * 53 + 7) % 380 - 10)
			stars.draw_rect(Rect2(p, Vector2.ONE), Color(1, 0.96, 0.85, 0.3 + 0.5 * absf(sin(Time.get_ticks_msec() / 900.0 + i * 1.7)))))
	stars.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(stars)
	get_tree().process_frame.connect(stars.queue_redraw)
	_ui = CanvasLayer.new()
	add_child(_ui)
	var title := Label.new()
	title.text = "LOGO OBSERWATORIUM"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffe9b0"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(640, 20)
	title.position = Vector2(0, 40)
	_ui.add_child(title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 12)
	_row.position = Vector2(48, 96)
	_ui.add_child(_row)
	for i in LOGOS.size():
		var b := Button.new()
		b.icon = Game.tex("logo_" + LOGOS[i][0])
		b.expand_icon = true
		b.custom_minimum_size = Vector2(104, 106)  # logo 48x49 w skali 2
		b.add_theme_constant_override("icon_max_width", 96)
		b.focus_entered.connect(_show.bind(i))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_confirm.bind(i))
		_row.add_child(b)
	_name = _label(232, Color("ffe9b0"))
	_desc = _label(256, Color("d8d0e8"))
	var note := _label(300, Color("8a80a8"))
	note.text = "Logo trafi na budynki, rakiety i kitle. Wybierasz raz."
	_ask = VBoxContainer.new()
	_ask.position = Vector2(232, 286)
	_ask.custom_minimum_size = Vector2(176, 0)
	_ask.visible = false
	_ui.add_child(_ask)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.cover(_fade)
	_ui.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)
	_row.get_child(0).grab_focus.call_deferred()


func _label(y: float, c: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(640, 20)
	l.position = Vector2(0, y)
	l.add_theme_color_override("font_color", c)
	_ui.add_child(l)
	return l


func _show(i: int) -> void:
	_pick = i
	_name.text = LOGOS[i][1]
	_desc.text = LOGOS[i][2]


## potwierdzenie: „Tego nie da się zmienić”
func _confirm(i: int) -> void:
	_show(i)
	Game.sfx("click")
	for b in _row.get_children():
		b.disabled = true
	for c in _ask.get_children():
		c.queue_free()
	var q := Label.new()
	q.text = "Tego nie da się zmienić. Na pewno?"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ask.add_child(q)
	var yes := Button.new()
	yes.text = "TAK, " + LOGOS[i][1].to_upper()
	yes.pressed.connect(_choose)
	_ask.add_child(yes)
	var no := Button.new()
	no.text = "WRÓĆ"
	no.pressed.connect(_back)
	_ask.add_child(no)
	_ask.visible = true
	yes.grab_focus.call_deferred()


func _back() -> void:
	_ask.visible = false
	for b in _row.get_children():
		b.disabled = false
	_row.get_child(_pick).grab_focus()


func _choose() -> void:
	_ask.visible = false
	Game.sfx("tadam", 1.0, -6.0)
	Game.logo = LOGOS[_pick][0]
	Game.start_stage(2)
	Game.save_game()
	await create_tween().tween_property(_fade, "color:a", 1.0, 0.8).finished
	get_tree().change_scene_to_file("res://game/world.tscn")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back") and _ask.visible:
		_back()
