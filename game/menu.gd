extends Node2D
## Menu główne (splash): widok z balkonu Etapu 1, animowane niebo, STAR WATCHER, KONTYNUUJ/START/USTAWIENIA/WYJDŹ.

var _box: VBoxContainer
var _ui: CanvasLayer


func _ready() -> void:
	name = "Menu"
	var bg := Sprite2D.new()
	bg.texture = Game.tex("balcony")
	bg.centered = false
	add_child(bg)
	var fx := preload("res://game/sky_fx.gd").new()
	add_child(fx)
	var jania := Sprite2D.new()  # Jania na balkonie, tyłem, patrzy w niebo
	jania.texture = Game.tex("jania")
	jania.hframes = 7
	jania.vframes = 3
	jania.frame = 14
	jania.position = Vector2(300, 296)
	jania.centered = false
	add_child(jania)
	_ui = CanvasLayer.new()
	add_child(_ui)
	var title := Label.new()
	title.text = "STAR WATCHER"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("ffe9b0"))
	title.add_theme_color_override("font_shadow_color", Color("1a1426"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.position = Vector2(46, 24)
	_ui.add_child(title)
	_box = VBoxContainer.new()
	_box.position = Vector2(48, 104)
	_box.custom_minimum_size = Vector2(176, 0)
	_box.add_theme_constant_override("separation", 4)
	_ui.add_child(_box)
	_build()


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()


func _build() -> void:
	_clear()
	var first: Button
	if Game.has_save():
		first = _btn(_box, "KONTYNUUJ", _continue)
	var s := _btn(_box, "START", _start)
	_btn(_box, "USTAWIENIA", _settings)
	_btn(_box, "WYJDŹ", Game.quit)
	(first if first else s).grab_focus.call_deferred()


func _continue() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file("res://game/world.tscn")


func _start() -> void:
	if Game.has_save():
		_clear()
		var l := Label.new()
		l.text = "Nadpisać zapisaną grę?"
		_box.add_child(l)
		_btn(_box, "TAK, NOWA GRA", _new_game).grab_focus.call_deferred()
		_btn(_box, "WRÓĆ", _build)
	else:
		_new_game()


func _new_game() -> void:
	Game.new_game()
	Game.save_game()
	get_tree().change_scene_to_file("res://game/world.tscn")


func _settings() -> void:
	_clear()
	var fs := _btn(_box, "", func(): pass)
	var crt := _btn(_box, "", func(): pass)
	var vol := {"Music": "MUZYKA", "SFX": "EFEKTY", "Ambient": "OTOCZENIE"}  # osobne głośności (GDD), 4 stopnie
	var vb := {}
	for bus in vol:
		vb[bus] = _btn(_box, "", func(): Game.settings[bus] = (int(Game.settings[bus]) + 3) % 4; Game.apply_settings(); Game.sfx("pop"))
	var refresh := func():
		fs.text = "PEŁNY EKRAN: " + ("TAK" if Game.settings.fullscreen else "NIE")
		crt.text = "EFEKT CRT: " + ("SUBTELNY" if Game.settings.crt else "WYŁ.")
		for bus in vol:
			vb[bus].text = vol[bus] + ": " + ["WYŁ.", "33%", "66%", "100%"][int(Game.settings[bus])]
	for bus in vol:
		vb[bus].pressed.connect(refresh)
	fs.pressed.connect(func(): Game.settings.fullscreen = not Game.settings.fullscreen; Game.apply_settings(); refresh.call())
	crt.pressed.connect(func(): Game.settings.crt = not Game.settings.crt; Game.apply_settings(); refresh.call())
	refresh.call()
	_btn(_box, "WRÓĆ", _build)
	fs.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		_build()
