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
const SKIP_HOLD := 2.5     # tyle trzeba trzymać spację, żeby pominąć intro
var skip_t := 0.0          # jak długo trzymana
var skipping := -1.0       # od 0 do 1: wygaszanie po pominięciu, potem gra
var ended := false
var skip_ui := Node2D.new()  # Pomiń [Spacja] i pasek przytrzymania, prawy dolny róg
var skip_seen := -10.0     # kiedy ostatnio wciśnięto klawisz: napis pokazuje się tylko po nim


func _ready() -> void:
	_sprite("balcony_cut_wide", Vector2(-320, 0))  # szeroki ekran: balkon i jezioro dalej w obie strony
	_sprite("balcony_cut", Vector2.ZERO)
	add_child(preload("res://game/sky_fx.gd").new())  # gwiazdy i spadające gwiazdy
	var o := _sprite("cut_observatory", Vector2(146, 143))  # białe obserwatorium z otwartą kopułą
	_mirror(self, func(): return [[o.texture, Rect2(), o.position, o.modulate]])
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
	Game.cover(fade)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)
	skip_ui.draw.connect(_draw_skip)
	ui.add_child(skip_ui)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# intro rysowane w rozdzielczości okna: kamera przesuwa się i przybliża o piksele ekranu, nie o piksele gry
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
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
	tw.tween_callback(_montage)


func _end() -> void:
	if ended:  # pominięcie i naturalny koniec mogą przyjść oba
		return
	ended = true
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT  # gra: znów siatka 640x360
	Game.loop("music/intro", -INF)
	Game.loop("lake", -INF)
	Game.loop("rain_room", -INF)
	get_tree().change_scene_to_file("res://game/world.tscn")


# ---------------------------------------------------------------- montaż: lata mijają w krótkich scenach
const HOLD := 4.2                     # ile trwa jedna scena
const QUICK := 0.35                   # szybkie przejście przez czerń
const CLOSE := 4.6                     # finał: zbliżenie, żuraw wkłada teleskop do wywrotki; potem rusza i kamera się cofa
const PULL := 3.2                      # finał: odjazd kamery na balkon razem z odjeżdżającą wywrotką
const ENGINE_ON := 4.58                # finał: silnik łapie (koniec kręcenia rozrusznikiem)
const FINAL_CAM := Vector2(262, 250)   # finał: całe obserwatorium w lewym górnym rogu, tata i Jania, wywrotka
const BALCONY_CAM := Vector2(275, 255)  # zoom 2: obserwatorium i balkon w kadrze
var sc: Node2D                         # bieżąca scena montażu
var fx := Node2D.new()                 # efekty bieżącej sceny (para, deski, chmury)
var fx_draw := Callable()
var hold := HOLD                       # bieżąca scena może trwać dłużej (finał)
var _cues := {}                        # dźwięki sceny, które już zagrały
var mirrors := []                      # węzły odbić w jeziorze (odświeżane co klatkę)
var mirror_extra := []                 # ruchome obiekty sceny do odbicia: [tekstura, wycinek, lewy górny róg]
const AXIS := 212.0                    # oś odbić: linia brzegu jeziora
var tick := Callable()                 # animacja bieżącej sceny: tick(t_sceny)
var st := 0.0


func _exit_tree() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	if not fx.is_inside_tree():  # między scenami fx wisi poza drzewem
		fx.free()


func _montage() -> void:
	for c in get_children():  # scena z rozmową znika pod czernią
		if c is CanvasItem:
			c.visible = false
	fx.draw.connect(func(): if fx_draw.is_valid(): fx_draw.call())
	for build in [_sc_stars, _sc_mobile, _sc_day, _sc_rain, _sc_pc, _sc_coffee, _sc_board]:
		sc = Node2D.new()
		add_child(sc)
		st = 0.0
		hold = HOLD
		_cues.clear()
		mirror_extra = []
		build.call()
		add_child(fx)
		await create_tween().tween_property(fade, "color:a", 0.0, QUICK).finished
		await get_tree().create_timer(hold).timeout
		await create_tween().tween_property(fade, "color:a", 1.0, QUICK).finished
		remove_child(fx)
		sc.queue_free()
		tick = Callable()
		fx_draw = Callable()
		Game.loop("rain_balcony", -INF)
	await get_tree().create_timer(1.2).timeout
	await _hospital()
	_end()


# ---------------------------------------------------------------- szpital: ostatnia rozmowa
# sala w tej samej perspektywie co pokój (640x360, meble sortowane po podstawie, hospital_layout.json)
const GLASS := Rect2(300, 22, 84, 52)   # szyba okna (przezroczysta w tle)
const ECG := Rect2(562, 66, 28, 18)     # ekran monitora serca
const BEAT := 0.86                      # ok. 70 uderzeń na minutę
const NIGHT := Color(0.72, 0.78, 0.95)  # Jania w nocnym, niebieskim świetle sali
var alive := true
var flat_at := 0.0


func _hospital() -> void:
	sc = Node2D.new()
	add_child(sc)
	st = 0.0
	_cues.clear()
	var night := Node2D.new()  # za oknem: noc, gwiazdy, deszcz
	night.draw.connect(func(): _draw_window(night))
	sc.add_child(night)
	var sorter := _room("hospital")
	var bed: Sprite2D
	for s in sorter.get_children():
		if s.texture == Game.tex("hospital_bed"):
			bed = s
	var mc := _spr("hospital_maciej", Vector2(6, -120), bed, 3)  # wydech, wdech, nie żyje (oczy zamknięte)  # leży w łóżku: rysowany zaraz po nim
	var j := _spr("jania_sad", Vector2(70, 118), sorter, 8)  # smutna mina
	j.vframes = 3
	j.offset = Vector2(0, -54)  # pozycja = stopy (sortowanie)
	j.modulate = NIGHT
	cam.zoom = Vector2.ONE
	cam.position = Vector2(320, 180)
	fx_draw = _draw_ecg
	add_child(fx)
	tick = func():
		night.queue_redraw()  # deszcz za oknem
		if alive:
			mc.frame = 1 if fmod(st, 3.2) > 1.8 else 0
			if _cue("b%d" % int(st / BEAT), 0.0):
				Game.sfx("beep", 1.0, -20.0)
	Game.loop("rain_room", -13.0)  # lekki szum deszczu
	await create_tween().tween_property(fade, "color:a", 0.0, 0.8).finished
	await _go(j, Vector2(70, 160))  # wchodzi drzwiami
	var zoom := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	zoom.tween_property(cam, "zoom", Vector2(2, 2), 7.0)
	zoom.tween_property(cam, "position", Vector2(450, 140), 7.0)  # monitor, łóżko i Jania nad okienkiem dialogu
	await _go(j, Vector2(394, 160))  # podchodzi do łóżka
	await get_tree().create_timer(0.6).timeout
	var dlg = preload("res://game/dialogue.gd").new().play([
		{"who": "maciej_old", "text": "Córko, gdy odejdę proszę kontynuuj moje badania. Odbuduj obserwatorium, i znajdź ich... Byłem tak blisko."},
		{"who": "jania_adult", "text": "Tato ale Ty się nigdzie nie wybierasz!"},
		{"who": "maciej_old", "text": "Kocham Cie córeczko", "cry": true},
		{"who": "jania_adult", "text": "Ja Cie też tato.", "cry": true},
	])
	dlg.line_shown.connect(func(l): j.texture = Game.tex("jania_cry" if l.get("cry", false) else "jania_sad"))  # płacze razem z portretem
	add_child(dlg)
	await dlg.finished
	await get_tree().create_timer(1.0).timeout
	alive = false  # monitor: długi pisk i prosta linia
	flat_at = st
	mc.frame = 2
	Game.sfx("flatline", 1.0, -16.0)
	await get_tree().create_timer(3.0).timeout
	await get_tree().create_timer(1.2).timeout
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(cam, "position", Vector2(360, 110), 3.0)  # kadr na okno
	await _go(j, Vector2(342, 160))  # płacze, podchodzi do okna
	await _go(j, Vector2(342, 128))
	await get_tree().create_timer(1.0).timeout
	var last = preload("res://game/dialogue.gd").new().play([{"who": "jania_adult", "text": "Znajdę ich ojcze", "cry": true}])
	add_child(last)
	await last.finished
	await get_tree().create_timer(0.8).timeout
	await create_tween().tween_property(fade, "color:a", 1.0, 3.5).finished  # długie wygaszenie przed grą
	Game.loop("rain_room", -INF)
	remove_child(fx)
	sc.queue_free()
	tick = Callable()
	fx_draw = Callable()


## Jania idzie prosto do `to` (40 px/s) jak w grze: bokiem 4 klatki, przodem i tyłem 2; cicho tupta
func _go(j: Sprite2D, to: Vector2) -> void:
	var d := to - j.position
	var face := 1 if absf(d.x) > absf(d.y) else (0 if d.y > 0 else 2)
	j.flip_h = face == 1 and d.x < 0
	while j.position.distance_to(to) > 0.5:
		j.position = j.position.move_toward(to, 40.0 * get_process_delta_time())
		var f := 1 + int(st * 14.0) % 4 if face == 1 else 1 + int(st * 10.0) % 2
		if f != j.frame % 8 and (face != 1 or f in [1, 3]):
			Game.sfx("step%d" % (randi() % 4), randf_range(1.0, 1.1), -18.0)
		j.frame = face * 8 + f
		await get_tree().process_frame
	j.position = to
	j.frame = face * 8


## noc za oknem: granat, gwiazdy, ukośne smugi deszczu (przycięte do szyby)
func _draw_window(n: Node2D) -> void:
	var g := GLASS
	for i in 13:
		n.draw_rect(Rect2(g.position.x, g.position.y + i * 4, g.size.x, 4), Color("0c1430").lerp(Color("1c2a52"), i / 12.0))
	for s in [Vector2(4, 5), Vector2(15, 12), Vector2(30, 4), Vector2(37, 18), Vector2(9, 30), Vector2(24, 22), Vector2(33, 40), Vector2(52, 8), Vector2(61, 20), Vector2(70, 5), Vector2(78, 34), Vector2(57, 42)]:
		n.draw_rect(Rect2(g.position + s, Vector2.ONE), Color(1, 1, 0.9, 0.5 + 0.5 * absf(sin(t * 1.3 + s.x))))
	var wind := 0.25 + 0.15 * sin(t * 0.6)  # skos deszczu zmienia się z porywami
	for k in 40:  # deszcz nieregularny: każda kropla ma swoją prędkość, a po każdym spadku nowe miejsce, długość i jasność
		var fall := (t * (110.0 + fmod(k * 37.7, 90.0)) + k * 53.0) / g.size.y
		var h := absi(hash(Vector2i(k, floori(fall))))
		var y := (fall - floorf(fall)) * g.size.y
		var x := float(h % int(g.size.x))
		var col := Color(0.6, 0.72, 0.9, 0.3 + (h / 7 % 5) * 0.1)
		for d in 3 + h / 3 % 4:
			var p := (g.position + Vector2(fposmod(x + (y - d) * wind, g.size.x), y - d)).floor()
			if g.has_point(p):
				n.draw_rect(Rect2(p, Vector2.ONE), col)


## monitor serca: przesuwający się zapis EKG (zielony), po śmierci prosta linia
func _draw_ecg() -> void:
	var green := Color("5ae68a")
	for x in int(ECG.size.x):
		var at := st - (ECG.size.x - 1 - x) * 0.05  # 20 px na sekundę
		var y := 9.0
		if alive or at < flat_at:
			var ph := fmod(at, BEAT) / BEAT
			y = 9.0 - (2.0 if ph > 0.10 and ph < 0.14 else 0.0) + (2.0 if ph > 0.2 and ph < 0.23 else 0.0) \
				- (8.0 if ph >= 0.23 and ph < 0.26 else 0.0) + (4.0 if ph >= 0.26 and ph < 0.29 else 0.0) - (3.0 if ph > 0.45 and ph < 0.55 else 0.0)
		fx.draw_rect(Rect2(ECG.position + Vector2(x, y), Vector2.ONE), green.darkened(0.5 if x < ECG.size.x - 3 else 0.0))


func _spr(tex: String, pos: Vector2, parent: Node = null, frames := 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Game.tex(tex)
	s.centered = false
	s.position = pos
	s.hframes = frames
	(parent if parent else sc).add_child(s)
	return s


## oddech: dwie klatki co 2,6 s, każda postać w swoim rytmie
func _breathe(s: Sprite2D, phase: float) -> void:
	s.frame = 1 if fmod(st + phase, 2.6) > 1.5 else 0


## kadr sceny: zoom 2 (całe piksele), środek na akcji
func _cam(at: Vector2) -> void:
	cam.zoom = Vector2(2, 2)
	cam.position = at


func _balcony_night(rain := false) -> void:
	_spr("balcony_cut", Vector2.ZERO)
	var sky = preload("res://game/sky_fx.gd").new()
	sky.raining = rain
	sc.add_child(sky)
	var o := _spr("cut_observatory", Vector2(146, 143))
	_mirror(sc, func(): return [[o.texture, Rect2(), o.position, o.modulate]] + mirror_extra)
	_spr("cut_door", Vector2(19, 219))
	_cam(BALCONY_CAM)


## balkon za dnia: niebo, Słońce i chmury rysowane, widok i balkon rozjaśnione jak w świcie
func _balcony_day() -> void:
	var sky := Node2D.new()
	sky.draw.connect(func():
		for i in 12:
			sky.draw_rect(Rect2(0, i * 12, 640, 12), Color("78a8e0").lerp(Color("c8e0f4"), i / 11.0))
		sky.draw_circle(Vector2(520, 58), 22, Color(1, 0.95, 0.7, 0.25))
		sky.draw_circle(Vector2(520, 58), 12, Color("fff2c0"))
		for i in 4:  # chmury płyną powoli w prawo
			var cx := fposmod(60.0 + i * 170.0 + st * 6.0, 760.0) - 60.0
			for k in 3:
				sky.draw_circle(Vector2(cx + k * 12, 40.0 + i * 13 - (6 if k == 1 else 0)), 9.0 - (2 if k != 1 else 0), Color("f6f8fc")))
	sc.add_child(sky)
	var bright := Color(1.9, 2.0, 1.7)
	_spr("balcony_view_cut", Vector2.ZERO).modulate = bright
	for r in [Rect2(0, 255, 640, 105), Rect2(0, 140, 80, 115)]:  # balustrada, podłoga, ściana z drzwiami
		var s := _spr("balcony_cut", r.position)
		s.region_enabled = true
		s.region_rect = r
		s.modulate = Color(1.5, 1.5, 1.4)
	var o := _spr("cut_observatory", Vector2(146, 143))
	o.modulate = Color(1.25, 1.25, 1.2)
	_mirror(sc, func(): return [[o.texture, Rect2(), o.position, o.modulate]], Vector3(0.45, 0.62, 0.8))
	_spr("cut_door", Vector2(19, 219)).modulate = Color(1.2, 1.2, 1.15)
	_cam(BALCONY_CAM)


## pokój jak w grze: tło i meble według layoutu, sortowane po podstawie
func _room(prefix := "room") -> Node2D:
	_spr(prefix, Vector2.ZERO)
	var sorter := Node2D.new()
	sorter.y_sort_enabled = true
	sc.add_child(sorter)
	for p in Game.layout(prefix):
		var s := _spr(p.name, Vector2(p.x, p.base), sorter)
		s.offset = Vector2(0, p.y - p.base)
	return sorter


## postać w sortowaniu po stopach (pos = lewy górny róg, h = wysokość sprite'a)
func _actor(sorter: Node2D, tex: String, pos: Vector2, frames := 2) -> Sprite2D:
	var s := _spr(tex, pos, sorter, frames)
	var h: float = s.texture.get_height()
	s.position = pos + Vector2(0, h)
	s.offset = Vector2(0, -h)
	return s


## para nad kubkiem: trzy smużki wznoszą się i falują
func _steam(at: Vector2) -> void:
	for k in 3:
		var u := fmod(st * 0.8 + k / 3.0, 1.0)
		var p := at + Vector2(sin(st * 3.0 + k * 2.0) * 1.5, -u * 14.0)
		fx.draw_rect(Rect2(p.floor(), Vector2(1, 2)), Color(1, 1, 1, 0.55 * (1.0 - u)))


func _sc_stars() -> void:  # balkon nocą: tata z profilu patrzy na Janię, kubek w obu łapach; Jania pisze w zeszycie
	_balcony_night()
	_spr("balcony_telescope", Vector2(372, 293))
	var m := _spr("cut_maciej_mug", Vector2(304, 275), null, 2)
	var j := _spr("cut_jania_sit", Vector2(262, 298), null, 2)
	tick = func():
		_breathe(m, 0.0)
		j.frame = int(st * 3.0) % 2  # łapka z długopisem skrobie w miejscu
		if _cue("p%d" % int(st / 0.95), 0.3):  # spokojne skrobanie, z przerwami
			Game.sfx("pencil", randf_range(0.8, 0.9), -20.0)
	fx_draw = func(): _steam(m.position + Vector2(3, 34 - m.frame))


func _sc_mobile() -> void:  # pokój: tata na krześle wiesza układ słoneczny, Jania patrzy
	var so := _room()
	_spr("room_chair", Vector2(303, 193))
	var m := _spr("cut_maciej_hang", Vector2(305, 147), null, 2)  # stoi na siedzisku, łapa przy nitce
	var j := _actor(so, "cut_jania_joy", Vector2(244, 168))
	_cam(Vector2(300, 180))
	tick = func(): _breathe(m, 0.0); _breathe(j, 0.8)
	fx_draw = func():  # model: nitka z sufitu, obręcz, planety krążą wokół Słońca
		var c := Vector2(352, 162)  # tata trzyma lewy brzeg obręczy
		fx.draw_line(Vector2(c.x, 0), c, Color("d8d0c0"), 1.0)
		var pl := [[Color("c8a070"), 3.0], [Color("6a9ae0"), 4.0], [Color("d06a4a"), 3.0], [Color("e0c070"), 5.0], [Color("8ac0d8"), 4.0]]
		for k in pl.size():
			var a := st * 0.7 + k * TAU / pl.size()
			var p := c + Vector2(cos(a) * 26.0, 10.0 + sin(a) * 6.0)
			fx.draw_line(c + Vector2(cos(a) * 26.0, sin(a) * 6.0), p, Color("d8d0c0"), 1.0)
			fx.draw_circle(p.floor(), pl[k][1], pl[k][0])
		var ring := PackedVector2Array()
		for k in 33:
			ring.append(c + Vector2(cos(k * TAU / 32) * 26.0, sin(k * TAU / 32) * 6.0))
		fx.draw_polyline(ring, Color("b0a890"), 1.0)
		fx.draw_circle(c + Vector2(0, 12), 6.0, Color("ffd060"))


func _sc_day() -> void:  # balkon za dnia: oboje patrzą na drugi brzeg
	_balcony_day()
	_spr("balcony_telescope", Vector2(372, 293)).modulate = Color(1.4, 1.4, 1.35)
	var j := _spr("cut_jania_back", Vector2(283, 300), null, 2)
	var m := _spr("cut_maciej_back", Vector2(312, 274), null, 2)
	j.modulate = Color(1.15, 1.15, 1.1)
	m.modulate = Color(1.15, 1.15, 1.1)
	tick = func(): _breathe(m, 0.0); _breathe(j, 0.9)
	fx_draw = func():  # błyski na wodzie
		for i in 40:
			var y := 224 + (i * 37) % 36
			var x := floorf(fposmod(i * 89.0 + st * (4.0 + i % 5 * 2.0), 680.0) - 20.0)
			fx.draw_rect(Rect2(x, y, 3 + i % 3 * 2, 1), Color(1, 1, 1, 0.25 + 0.35 * maxf(0.0, sin(st * 1.7 + i * 2.3))))


func _sc_rain() -> void:  # balkon nocą w deszczu: tata stoi sam
	_balcony_night(true)
	var m := _spr("cut_maciej_back", Vector2(312, 274), null, 2)
	var front = preload("res://game/sky_fx.gd").new()
	front.raining = true
	front.front = true
	sc.add_child(front)
	Game.loop("rain_balcony", -12.0)
	tick = func(): _breathe(m, 0.0)


func _sc_pc() -> void:  # pokój: Jania przy komputerze, tata obok
	var so := _room()
	var j := _actor(so, "cut_teen_back", Vector2(362, 96))
	var m := _actor(so, "cut_maciej_back", Vector2(400, 82))
	j.position.y = 146
	_cam(Vector2(390, 120))
	tick = func(): _breathe(m, 0.0); _breathe(j, 1.1)
	fx_draw = func():  # monitor migocze
		fx.draw_rect(Rect2(350, 72, 24, 18), Color(0.55, 0.9, 1.0, 0.18 + 0.08 * sin(st * 9.0)))


func _sc_coffee() -> void:  # pokój: tata o balkoniku, starsza Jania niesie mu kawę w obu łapkach
	var so := _room()
	var m := _actor(so, "cut_maciej_front", Vector2(430, 118))
	var j := _actor(so, "cut_teen_walk", Vector2(250, 140), 5)
	_cam(Vector2(370, 160))
	tick = func():
		_breathe(m, 0.0)
		var x := minf(250.0 + st * 40.0, 404.0)  # podchodzi i staje przed balkonikiem
		j.position.x = x
		j.frame = 0 if x >= 404.0 else 1 + int(st * 8.0) % 4
		var foot := int(st * 4.0)  # cicho tupta: łapka co drugą klatkę chodu
		if x < 404.0 and _cue("s%d" % foot, 0.0):
			Game.sfx("step%d" % (foot % 4), randf_range(1.15, 1.3), -16.0)
	fx_draw = func(): _steam(j.position + Vector2(16, -j.texture.get_height() + 29 - (1 if j.frame % 2 == 0 and j.frame > 0 else 0)))


## finał: zbliżenie na zabite deskami obserwatorium, żuraw przenosi wyjęty teleskop na wywrotkę;
## kamera cofa się na balkon i zatrzymuje na tacie na wózku
func _sc_board() -> void:
	_balcony_night()
	for c in sc.get_children():  # zamiast działającego obserwatorium: zamknięte, bez teleskopu
		if c is Sprite2D and c.texture == Game.tex("cut_observatory"):
			c.texture = Game.tex("cut_observatory_closed")
	var dim := Color(0.78, 0.78, 0.9)  # noc: żółć przygaszona
	_spr("cut_crane", Vector2(88, 80)).modulate = dim
	var m := _feet("cut_maciej_sit", 300, 334)
	var j := _feet("jania", 342, 338, 8)
	j.vframes = 3
	j.frame = 16
	hold = CLOSE + PULL + 4.0
	tick = func():
		_breathe(m, 0.0)
		j.frame = 23 if fmod(st + 1.2, 2.6) > 1.5 else 16
		var u := smoothstep(CLOSE, CLOSE + PULL, st)
		cam.zoom = Vector2.ONE * 3.0 * pow(2.0 / 3.0, u)
		cam.position = Vector2(207, 151).lerp(FINAL_CAM, u)
		if _cue("clank", 3.78):  # teleskop ląduje w skrzyni
			Game.sfx("clank", 1.0, -14.0)
		if _cue("start", 3.88):  # rozrusznik, silnik łapie ok. 0,7 s później
			Game.sfx("engine_start", 1.0, -8.0)
		if _cue("drive", CLOSE):
			Game.sfx("truck_drive", 1.0, -8.0)
	fx_draw = _draw_site


## wózek żurawia jedzie znad kopuły nad wywrotkę, hak opuszcza teleskop do skrzyni (grubszy koniec wystaje),
## hak wraca w górę, a wywrotka z teleskopem odjeżdża w prawo
func _draw_site() -> void:
	var tx := lerpf(186.0, 245.0, smoothstep(0.5, 2.5, st))
	var hy := lerpf(135.0, 167.0, smoothstep(2.6, 3.8, st)) - 40.0 * smoothstep(3.9, 4.6, st)
	var drive := _drive(st)
	var shake := 1.0 if st > ENGINE_ON and fmod(st, 0.11) < 0.05 else 0.0  # silnik pracuje: wywrotka lekko drży
	var dim := Color(0.78, 0.78, 0.9)
	var dark := Color(0.12, 0.12, 0.16)
	var at := Vector2(tx - 17, (hy if st < 3.9 else 167.0 + shake) + 5).floor() + Vector2(drive, 0).floor()
	fx.draw_rect(Rect2(tx - 3, 102, 7, 2), dark)                      # wózek pod wysięgnikiem
	fx.draw_line(Vector2(tx, 104), Vector2(tx, hy), dark, 1.0)        # lina
	fx.draw_rect(Rect2(tx - 2, hy, 5, 3), Color(0.66, 0.5, 0.16))     # zblocze haka
	if st < 3.9:  # zawiesia, dopóki teleskop wisi
		fx.draw_line(Vector2(tx, hy + 3), at + Vector2(8, 4), dark, 1.0)
		fx.draw_line(Vector2(tx, hy + 3), at + Vector2(27, 3), dark, 1.0)
	fx.draw_texture(Game.tex("cut_scope"), at, dim)
	var truck := Vector2(226 + floorf(drive), 176 + shake)
	fx.draw_texture(Game.tex("cut_truck"), truck, dim)  # skrzynia zasłania dół teleskopu
	var wf := int(drive / 2.43) % 4  # koło r 6,2 px: klatka co 22,5° obrotu
	mirror_extra = [[Game.tex("cut_crane"), Rect2(), Vector2(88, 80), dim], [Game.tex("cut_scope"), Rect2(), at, dim], [Game.tex("cut_truck"), Rect2(), truck, dim]]
	for wx in [7, 41]:
		var src := Rect2(wf * 15, 0, 15, 15)
		fx.draw_texture_rect_region(Game.tex("cut_wheel"), Rect2(truck + Vector2(wx, 18), Vector2(15, 15)), src, dim)
		mirror_extra.append([Game.tex("cut_wheel"), src, truck + Vector2(wx, 18), dim])
	_draw_exhaust()


## dym z rury wydechowej za kabiną: pikselowe kłęby (bez półprzezroczystości) rosną, jaśnieją i rozpadają się w kratkę
func _draw_exhaust() -> void:
	if st < ENGINE_ON:
		return
	var every := 0.12
	for k in range(maxi(0, int((st - ENGINE_ON - 1.4) / every)), int((st - ENGINE_ON) / every) + 1):
		var born := ENGINE_ON + k * every
		var age := st - born
		if age < 0.0 or age > 1.4:
			continue
		var pipe := Vector2(226 + floorf(_drive(born)) + 38, 176)  # wylot rury (od momentu wydmuchu kłąb zostaje w powietrzu)
		var p := (pipe + Vector2(-6.0 * age - (k % 3), -12.0 * age)).floor()
		var r := 1 if age < 0.2 else 2 if age < 0.6 else 3
		var c := Color8(70, 70, 80) if age < 0.25 else Color8(104, 104, 114) if age < 0.7 else Color8(136, 136, 146)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) + absi(dy) > r + (1 if r > 1 else 0):
					continue  # zaokrąglone rogi kłębu
				if age > 1.0 and (dx + dy) % 2 != 0:
					continue  # rozpada się w kratkę
				fx.draw_rect(Rect2(p + Vector2(dx, dy), Vector2.ONE), c)


## dźwięk/zdarzenie sceny: raz, gdy czas sceny minie `at`
func _cue(key: String, at: float) -> bool:
	if st < at or _cues.has(key):
		return false
	_cues[key] = true
	return true


## wielki diesel: rusza powoli (12 px/s²), potem jedzie 30 px/s
func _drive(when: float) -> float:
	var td := maxf(0.0, when - CLOSE)
	return 6.0 * td * td if td < 2.5 else 37.5 + 30.0 * (td - 2.5)


## odbicie w jeziorze: obiekty z `items` rysowane do góry nogami pod linią brzegu, z falującym shaderem wody
func _mirror(parent: Node, items: Callable, tint := Vector3(0.11, 0.15, 0.3)) -> void:
	var m := Node2D.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/water_reflect.gdshader")
	mat.set_shader_parameter("tint", tint)
	m.material = mat
	m.draw.connect(func():
		for it in items.call():
			var tex: Texture2D = it[0]
			var src: Rect2 = it[1] if it[1] != Rect2() else Rect2(Vector2.ZERO, tex.get_size())
			var pos: Vector2 = it[2]
			var mod: Color = it[3] if it.size() > 3 else Color.WHITE
			# ujemna wysokość = odwrócone w pionie; dół obiektu ląduje tuż pod osią
			m.draw_texture_rect_region(tex, Rect2(pos.x, 2.0 * AXIS - pos.y - src.size.y, src.size.x, -src.size.y), src, mod))
	parent.add_child(m)
	mirrors.append(m)


## sprite stojący stopami na y (x = lewa krawędź)
func _feet(tex: String, x: float, bottom: float, frames := 2) -> Sprite2D:
	var s := _spr(tex, Vector2.ZERO, null, frames)
	s.position = Vector2(x, bottom - s.texture.get_height() / (3.0 if tex == "jania" else 1.0))
	return s


func _process(dt: float) -> void:
	t += dt
	st += dt
	if tick.is_valid():
		tick.call()
	fx.queue_redraw()
	mirrors = mirrors.filter(func(m): return is_instance_valid(m))
	for m in mirrors:
		m.queue_redraw()
	for c in chars:  # spokojny oddech, każde w swoim rytmie
		c[0].frame = 1 if fmod(t + c[1], 2.6) > 1.5 else 0
	obs.queue_redraw()
	top.queue_redraw()
	if skipping < 0.0:
		skip_t = skip_t + dt if Input.is_action_pressed("confirm") else 0.0
		if skip_t >= SKIP_HOLD:
			skipping = 0.0
	else:  # szybkie wygaszenie nad tym, co akurat robi scena, potem gra
		skipping += dt / 0.6
		fade.color.a = maxf(fade.color.a, minf(skipping, 1.0))
		if skipping >= 1.0:
			_end()
	skip_ui.queue_redraw()


func _input(e: InputEvent) -> void:
	if (e is InputEventKey or e is InputEventJoypadButton) and e.is_pressed():
		skip_seen = t


func _draw_skip() -> void:
	var a := 1.0 if skip_t > 0.0 else clampf(3.0 - (t - skip_seen), 0.0, 1.0)  # 2 s po klawiszu, potem gaśnie
	if a <= 0.0:
		return
	var talking := get_children().any(func(c): return c.has_signal("line_shown"))
	var msg := "Pomiń " + Game.key("advance")
	var w := Game.font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
	var p := Vector2(628 + Game.margin.x - w, 220.0 if talking else 350.0 + Game.margin.y).floor()  # prawy dolny róg ekranu; przy dialogu nad jego okienkiem
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		skip_ui.draw_string(Game.font, p + d, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.1, 0.08, 0.16, a))
	skip_ui.draw_string(Game.font, p, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.98, 0.95, 0.86, a))
	if skip_t > 0.0:  # pasek nad napisem
		var bar := Rect2(p.x, p.y - 20, floorf(w), 4)
		skip_ui.draw_rect(bar.grow(1), Color(0.1, 0.08, 0.16))
		skip_ui.draw_rect(Rect2(bar.position, Vector2(floorf(bar.size.x * minf(skip_t / SKIP_HOLD, 1.0)), 4)), Color("ffcf6b"))


func _draw_obs() -> void:
	for c in COMETS:  # komety suną powoli przez niebo: głowa i rozmyty warkocz
		var h: Vector2 = (c[0] + c[1] * t).floor()
		for k in 16:
			var dir: Vector2 = c[1]
			var q: Vector2 = (h - dir.normalized() * k * 1.4).floor()
			if k < 3 or (int(q.x) + int(q.y)) % 2 == 0:
				obs.draw_rect(Rect2(q, Vector2.ONE), Color(0.85, 0.92, 1.0, 0.75 - k * 0.045))
		obs.draw_rect(Rect2(h - Vector2.ONE, Vector2(2, 2)), Color(1, 1, 0.96))
	obs.draw_line(Vector2(217, 178), Vector2(217, 170), Color("aab4c8"), 1.0)  # maszt anteny na dachu
	var w := roundf(4.0 * cos(t * 0.7))  # czasza obraca się wokół masztu
	for k in range(-absi(int(w)), absi(int(w)) + 1):
		obs.draw_rect(Rect2(217 + k, 168 + floori(absi(k) / 2.0), 1, 1), Color("e8ecf4"))
	obs.draw_rect(Rect2(217 + signf(w) * 2, 166, 1, 2), Color("c8d0e0"))
	if fmod(t, 1.6) < 0.25:
		obs.draw_rect(Rect2(217, 165, 1, 1), Color("ff5a4a"))


func _draw_door() -> void:
	if door_a <= 0.0:
		return
	var msg := "Kochani, kolacja!"
	var p := Vector2(10, 204 - 4.0 * door_a).floor()
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		top.draw_string(Game.font, p + d, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.1, 0.08, 0.16, door_a))
	top.draw_string(Game.font, p, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(1, 0.95, 0.8, door_a))
