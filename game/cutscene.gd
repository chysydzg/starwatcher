extends Node2D
## Intro po NOWEJ GRZE: kamera od Księżyca i komet cofa się do balkonu, mała Jania i tata Maciej stoją tyłem
## i patrzą w gwiazdy. Rozmowa w okienkach dialogu, potem pukanie i „Kochani, kolacja!” na drzwiach, i gra.

const LINES := [
	{"who": "jania", "text": "Tato, czy tam na niebie są inne planety, na których jest życie?"},
	{"who": "maciej", "text": "Na pewno. Czuję, córeczko, że niedługo je odkryjemy w swoim obserwatorium."},
]
const MOON := Vector2(492, 74)
const COMETS := [[Vector2(96, 30), Vector2(4.0, 1.2)], [Vector2(330, 18), Vector2(2.6, 0.9)]]  # start, px/s
var t := 0.0
var door_a := 0.0          # napis na drzwiach
var cam := Camera2D.new()
var fade := ColorRect.new()
var chars := []            # [sprite, przesunięcie fazy oddechu]
var obs := Node2D.new()    # komety i antena obserwatorium (obracająca się czasza)
var top := Node2D.new()    # napis na drzwiach nad wszystkim


func _ready() -> void:
	_sprite("balcony", Vector2.ZERO)
	add_child(preload("res://game/sky_fx.gd").new())  # gwiazdy i spadające gwiazdy
	_sprite("cut_observatory", Vector2(147, 144))      # białe obserwatorium z otwartą kopułą
	_sprite("cut_door", Vector2(19, 219))              # drzwi balkonowe zamknięte
	obs.draw.connect(_draw_obs)
	add_child(obs)
	_sprite("balcony_telescope", Vector2(372, 293))
	for c in [["cut_jania_back", Vector2(283, 300), 0.0], ["cut_maciej_back", Vector2(312, 274), 0.9]]:
		var s := _sprite(c[0], c[1])
		s.hframes = 2
		chars.append([s, c[2]])
	top.draw.connect(_draw_door)
	add_child(top)
	add_child(cam)
	cam.zoom = Vector2(4, 4)
	cam.position = MOON + Vector2(-10, 6)
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	fade.color = Color.BLACK
	fade.size = Vector2(640, 360)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Game.loop("music/intro", -12.0, "Music")
	Game.loop("lake", -16.0)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.5)
	tw.tween_interval(2.0)  # chwila na Księżyc, gwiazdy i komety
	tw.tween_method(_pull_back, 0.0, 1.0, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.8)
	tw.tween_callback(_talk)


func _sprite(tex: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Game.tex(tex)
	s.centered = false
	s.position = pos
	add_child(s)
	return s


## kamera cofa się od Księżyca do całego balkonu (zoom wykładniczo, żeby ruch był równy)
func _pull_back(u: float) -> void:
	cam.zoom = Vector2.ONE * pow(4.0, 1.0 - u)
	cam.position = (MOON + Vector2(-10, 6)).lerp(Vector2(320, 180), u)


func _talk() -> void:
	var d = preload("res://game/dialogue.gd").new().play(LINES)
	d.finished.connect(_dinner)
	add_child(d)


func _dinner() -> void:
	Game.sfx("knock")
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(self, "door_a", 1.0, 0.4)
	tw.tween_interval(2.6)
	tw.tween_property(fade, "color:a", 1.0, 1.5)
	tw.tween_callback(_end)


func _end() -> void:
	Game.loop("music/intro", -INF)
	Game.loop("lake", -INF)
	get_tree().change_scene_to_file("res://game/world.tscn")


func _process(dt: float) -> void:
	t += dt
	for c in chars:  # spokojny oddech, każde w swoim rytmie
		c[0].frame = 1 if fmod(t + c[1], 2.6) > 1.5 else 0
	obs.queue_redraw()
	top.queue_redraw()


func _draw_obs() -> void:
	for c in COMETS:  # komety suną powoli przez niebo: głowa i rozmyty warkocz
		var h: Vector2 = (c[0] + c[1] * t).floor()
		for k in 16:
			var dir: Vector2 = c[1]
			var q: Vector2 = (h - dir.normalized() * k * 1.4).floor()
			if k < 3 or (int(q.x) + int(q.y)) % 2 == 0:
				obs.draw_rect(Rect2(q, Vector2.ONE), Color(0.85, 0.92, 1.0, 0.75 - k * 0.045))
		obs.draw_rect(Rect2(h - Vector2.ONE, Vector2(2, 2)), Color(1, 1, 0.96))
	obs.draw_line(Vector2(218, 179), Vector2(218, 171), Color("aab4c8"), 1.0)  # maszt anteny na dachu
	var w := roundf(4.0 * cos(t * 0.7))  # czasza obraca się wokół masztu
	for k in range(-absi(int(w)), absi(int(w)) + 1):
		obs.draw_rect(Rect2(218 + k, 169 + floori(absi(k) / 2.0), 1, 1), Color("e8ecf4"))
	obs.draw_rect(Rect2(218 + signf(w) * 2, 167, 1, 2), Color("c8d0e0"))
	if fmod(t, 1.6) < 0.25:
		obs.draw_rect(Rect2(218, 166, 1, 1), Color("ff5a4a"))


func _draw_door() -> void:
	if door_a <= 0.0:
		return
	var msg := "Kochani, kolacja!"
	var p := Vector2(10, 204 - 4.0 * door_a).floor()
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		top.draw_string(Game.font, p + d, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.1, 0.08, 0.16, door_a))
	top.draw_string(Game.font, p, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(1, 0.95, 0.8, door_a))
