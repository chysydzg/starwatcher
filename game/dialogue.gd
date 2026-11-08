extends CanvasLayer
## Okienko dialogu (tak w całej grze): rozmówca po lewej (portret + imię), tekst pojawia się litera po literze
## z cichym stukaniem, w prawym dolnym rogu [Spacja] / [A]. Spacja: najpierw pokazuje cały tekst, potem dalej.

signal finished

const WHO := {"jania": ["Jania", "portrait_jania"], "jania_adult": ["Jania", "portrait_jania_adult"], "maciej": ["Maciej", "portrait_maciej"], "maciej_old": ["Maciej", "portrait_maciej_old"]}
## linia z "cry": true bierze portret ze łzami (portrait_<kto>_cry)
const CPS := 30.0              # liter na sekundę
const PORT := Rect2(12, 228, 104, 104)
const TEXT := Rect2(122, 228, 506, 124)
var lines := []                # [{"who": "jania", "text": "..."}]
var _i := -1
var _shown := 0.0
var _t := 0.0
var _box := Control.new()
var _label := Label.new()


func play(l: Array) -> CanvasLayer:
	lines = l
	return self


func _ready() -> void:
	layer = 15
	_box.size = Vector2(640, 360)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.draw.connect(_draw_box)
	add_child(_box)
	_label.position = TEXT.position + Vector2(12, 10)
	_label.size = Vector2(TEXT.size.x - 24, TEXT.size.y - 30)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING  # zawijanie od razu, bez skakania słów
	_label.add_theme_color_override("font_color", Color("f4ecdc"))
	add_child(_label)
	_next()


func done() -> bool:
	return _shown >= _label.get_total_character_count()


func _next() -> void:
	_i += 1
	if _i >= lines.size():
		finished.emit()
		queue_free()
		return
	_label.text = lines[_i].text
	_shown = 0.0
	_label.visible_characters = 0


func _process(dt: float) -> void:
	_t += dt
	var total := _label.get_total_character_count()
	if _shown < total:
		var before := int(_shown)
		_shown = minf(total, _shown + dt * CPS)
		for k in range(before, int(_shown)):
			if not _label.text[k] in " ,.?!—–-":  # stuknięcie przy każdej literze
				Game.sfx("tick", randf_range(1.25, 1.55), -24.0)
		_label.visible_characters = int(_shown)
	_box.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("confirm") and not e.is_echo():
		get_viewport().set_input_as_handled()
		if done():
			_next()
		else:
			_shown = _label.get_total_character_count()
			_label.visible_characters = -1


func _draw_box() -> void:
	if _i < 0 or _i >= lines.size():
		return
	var who: Array = WHO[lines[_i].who]
	Game.metal(_box, PORT)
	var inner := PORT.grow(-6)
	_box.draw_rect(inner, Color("1c2440"))
	_box.draw_rect(Rect2(inner.position.x, inner.end.y - 30, inner.size.x, 30), Color("232c4c"))  # ciemniejsze tło portretu u dołu
	# portret żyje: oddech (cały biust 1 px w dół, dół przycięty ramką) i mrugnięcie co ok. 3,4 s
	var d := 1 if fmod(_t, 2.6) > 1.5 else 0
	var blink := 88 if fmod(_t + 0.7, 3.4) < 0.14 else 0
	var pos := (inner.position + (inner.size - Vector2(88, 88)) / 2).floor() + Vector2(0, 2 + d)
	var tex: String = who[1] + ("_cry" if lines[_i].get("cry", false) else "")
	_box.draw_texture_rect_region(Game.tex(tex), Rect2(pos, Vector2(88, 88 - d)), Rect2(blink, 0, 88, 88 - d))
	var plate := Rect2(PORT.position.x, PORT.end.y - 2, PORT.size.x, 24)
	var cap := Game.keycap(_box, plate, false)
	_box.draw_string(Game.font, Vector2(cap.position.x, cap.position.y + 13).floor(), who[0], HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, Game.FS, Color("1a1626"))
	Game.metal(_box, TEXT)
	if done() and fmod(_t, 1.6) < 1.1:  # podpowiedź miga spokojnie, gdy tekst skończony
		var k := Game.key("advance")
		var w := Game.font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
		_box.draw_string(Game.font, Vector2(TEXT.end.x - w - 12, TEXT.end.y - 10).floor(), k, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("ffcf6b"))
