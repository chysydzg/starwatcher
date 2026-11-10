extends Node2D
## Menu główne (splash): widok z balkonu Etapu 1, animowane niebo, STAR WATCHER, KONTYNUUJ/START/USTAWIENIA/WYJDŹ.

var _box: VBoxContainer
var _ui: CanvasLayer


func _ready() -> void:
	name = "Menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var cam := Camera2D.new()  # scena 640x360 na środku; szeroki ekran pokazuje więcej balkonu
	cam.position = Vector2(320, 180)
	add_child(cam)
	for k in [["balcony_wide", Vector2(-320, -60)], ["balcony", Vector2.ZERO]]:
		var bg := Sprite2D.new()
		bg.texture = Game.tex(k[0])
		bg.centered = false
		bg.position = k[1]
		add_child(bg)
	var fx := preload("res://game/sky_fx.gd").new()
	add_child(fx)
	var jania := Sprite2D.new()  # Jania na balkonie, tyłem, patrzy w niebo
	jania.texture = Game.tex("jania")
	jania.hframes = 8
	jania.vframes = 3
	jania.frame = 16  # tyłem (rząd 2, kolumna 0)
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
	Game.loop("music/menu", -8.0, "Music")  # motyw menu (music/compose.py: menu())


func _exit_tree() -> void:
	Game.loop("music/menu", -INF)


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
	if Game.load_game():  # po przeprowadzce, a przed wyborem logo: od razu wybór logo
		get_tree().change_scene_to_file("res://game/logo.tscn" if Game.stage_done and Game.stage == 1 else "res://game/world.tscn")


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
	get_tree().change_scene_to_file("res://game/cutscene.tscn")  # intro, potem gra


func _settings() -> void:
	_clear()
	Game.settings_ui(_box).grab_focus.call_deferred()
	_btn(_box, "WRÓĆ", _build)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		_build()
