extends Node2D
## Świat Etapu 1: pokój Jani (top-down 3/4) i balkon (widok zza pleców), Jania, dzień/noc, HUD,
## interakcje, przejścia, pauza, podsumowanie dnia. Viewporty: telescope.gd i astroos.gd.
## Meble i rekwizyty to osobne sprite'y sortowane po podstawie (y), kolizje z ich „stopek” z *_layout.json.

const NIGHT_TINT := Color(0.34, 0.38, 0.64)
const SPEED := 144.0
const ROOM_WALK := Rect2(14, 122, 612, 224)
const BALCONY_WALK := Rect2(20, 318, 610, 42)
const MUSIC_DB := -8.0  # pętle są masterowane na -16 LUFS
const CLOUDS := [Vector4(0, 33, 22, 3), Vector4(150, 40, 30, 4), Vector4(300, 34, 18, 3), Vector4(430, 57, 26, 3), Vector4(560, 45, 20, 3)]  # x, y, szer., wys.
const BREATH := 2.6       # rytm oddechu Jani: dół BREATH_DOWN s, potem góra
const BREATH_DOWN := 1.5
const SEASON_LOOPS := ["season_spring", "season_summer", "season_autumn", "season_winter"]  # kolejność jak Game.SEASONS
const REACH := 24.0   # jak blisko obiektu (od jego krawędzi) trzeba stanąć
const ROOM_SPOTS := {"komputer": Rect2(334, 104, 94, 48), "lozko": Rect2(12, 96, 88, 100), "drzwi": Rect2(518, 104, 46, 18),
	"szafa": Rect2(568, 104, 62, 24), "plakat": Rect2(248, 104, 32, 18), "model": Rect2(132, 104, 34, 18),
	"paczka": Rect2(291, 234, 26, 12), "radio": Rect2(572, 312, 48, 22), "lampa": Rect2(224, 118, 24, 14), "lampka": Rect2(96, 108, 36, 24),
	"bagaze": Rect2(500, 296, 62, 38)}
## Etap 2 (base.js): ta sama bryła co pokój (biurko, łóżko, drzwi, szafa i karton w tych samych miejscach),
## nowe: duży teleskop na platformie, biurko Arbjooze, podium ze starym teleskopem z balkonu
const BASE_SPOTS := {"komputer": Rect2(334, 104, 94, 48), "drzwi": Rect2(518, 104, 46, 18), "pokoik": Rect2(24, 104, 40, 18),
	"paczka": Rect2(291, 234, 26, 12), "radio": Rect2(572, 312, 48, 22), "teleskop": Rect2(440, 226, 60, 40),
	"arbjooze": Rect2(134, 266, 68, 38), "podium": Rect2(296, 312, 52, 28), "spektrograf": Rect2(242, 104, 58, 26),
	"serwery": Rect2(440, 104, 62, 24), "tablica": Rect2(80, 104, 60, 14)}
## pokoik Jani w Etapie 2 (pokoik.js): łóżko, szafka i szafa w miejscach z pokoju, drzwi do laboratorium
const POKOIK_SPOTS := {"lozko": Rect2(12, 96, 88, 100), "drzwi": Rect2(518, 104, 46, 18), "szafa": Rect2(568, 104, 62, 24),
	"lampa": Rect2(224, 118, 24, 14), "lampka": Rect2(96, 108, 36, 24)}
const ROOM_LIGHTS := [[Vector2(114, 88), "ffc070", 1.0, 1.1], [Vector2(412, 82), "ffc070", 0.9, 0.9], [Vector2(363, 82), "c8e4ff", 1.0, 0.9],
	[Vector2(191, 60), "8aa8ff", 0.6, 1.4], [Vector2(236, 78), "ffd890", 0.9, 1.3], [Vector2(541, 70), "8aa8ff", 0.4, 1.0]]
## laboratorium nocą: chłodne światło nad teleskopem, lampka i monitor na biurku, okno, zielone diody szaf, drzwi
const LAB_LIGHTS := [[Vector2(470, 170), "e8f0ff", 0.7, 1.8], [Vector2(412, 82), "e8f0ff", 0.9, 0.9], [Vector2(363, 82), "c8e4ff", 1.0, 0.9],
	[Vector2(191, 60), "8aa8ff", 0.6, 1.4], [Vector2(472, 80), "8affb0", 0.5, 1.0], [Vector2(541, 70), "8aa8ff", 0.4, 1.0]]
const CAT_DESK := Vector2(168, 284)  # stopy Arbjooze za jego biurkiem (biurko zasłania nogi)
## biurka pozostałych pracowników (lewy górny róg biurka): lewa ściana i pod platformą teleskopu
const DESKS := [Vector2(30, 200), Vector2(30, 290), Vector2(384, 296), Vector2(476, 296)]
const BALCONY_SPOTS := {"wroc": Rect2(0, 300, 66, 60), "teleskop": Rect2(214, 326, 70, 22), "krzeslo": Rect2(416, 330, 34, 16),
	"skrzynka": Rect2(472, 330, 32, 14), "kwiatek": Rect2(564, 330, 36, 16)}

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
var lamps := {}  # spot -> {"light", "on"}: lampka nocna i lampa stojąca, włączane ręcznie
var _step_frame := -1  # klatka chodu, przy której ostatnio był krok
var owl_t := 20.0  # odległe pohukiwanie sowy nad jeziorem, co jakiś czas nocą
var glow: Node2D
var props := {}
var feet := {"room": [], "balcony": [], "pokoik": []}
var pokoik: Node2D        # Etap 2: osobny pokoik Jani (location „pokoik”)
var pokoik_sort: Node2D
var hud: Node2D
var ui: CanvasLayer
var top: CanvasLayer
var crt: ColorRect
var fade: ColorRect
var viewport: Control = null
var face := 0
var flip := false
var t := 0.0
var idle_t := 0.0
var happy_t := 0.0
var dusk_o: Control       # nakładka zmierzchu (odświeżana co klatkę – migotanie gwiazd)
var speech := {}          # monolog Jani: {text, t}
var rain_front: Node2D    # krople deszczu przed rekwizytami balkonu
var busy := false
var tired_told := false
var ency_acc := 0.0
var parasol_under := false  # Jania pod parasolem w deszczu: krople bębnią o materiał
var flash_next := 3.0     # burza w nocy: następny piorun (balkon, okna pokoju i okular błyskają razem)
var yawn_t := -1.0         # ziewanie (koniec nocy): >= 0 trwa; jania_yawn.png – 3 klatki przodem
var yawned := false
const YAWN := 2.2
const TIRED := "Późno już, nie mam sił.\nPora spać."
var toasts := []
var tip := ""
var base := false          # Etap 2: wnętrze obserwatorium zamiast pokoju (ten sam układ, inne tło i meble)
var cat: Sprite2D          # Arbjooze (arbjooze.png: 5x3 klatek 40x58; przód 0-4, bok 5-9, protezy 10-13)
var cat_wave := false
var workers := []          # [biurko, sprite] pracowników 2-5 (worker_<rodzaj>.png, 4 klatki machania)


func _ready() -> void:
	name = "World"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	RenderingServer.set_default_clear_color(Color("1a1426"))
	jania = Sprite2D.new()
	jania.texture = Game.tex("jania")
	jania.hframes = 8  # kolumna 7: klatka oddechu
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
	base = Game.stage >= 2
	_build_room()
	_build_balcony()
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	glow = Node2D.new()
	glow.draw.connect(_draw_glow)
	_layer(1).add_child(glow)
	ui = _layer(5)
	crt = ColorRect.new()
	Game.cover(crt)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt.material = ShaderMaterial.new()
	crt.material.shader = load("res://game/crt.gdshader")
	_layer(8).add_child(crt)
	var hud_layer := _layer(10)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud)
	hud_layer.add_child(hud)
	top = _layer(20)
	fade = ColorRect.new()
	fade.color = Color("1a1426")
	Game.cover(fade)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fade)
	var cam := Camera2D.new()  # świat 640x360 na środku; na szerokim ekranie po bokach widać więcej balkonu
	cam.position = Vector2(320, 180)
	add_child(cam)
	Game.toast.connect(_toast)
	Game.changed.connect(_refresh)
	_enter(Game.location, true)
	var first: bool = Game.day == 1 and Game.night and not Game.tips.has("start")  # zaraz po intro
	create_tween().tween_property(fade, "color:a", 0.0, 2.5 if first else 0.6)
	if first:
		Game.tips.start = true
		_tip("Pierwsza noc. Podejdź do teleskopu od strony okularu i naciśnij " + Game.key("interact") + ".")
	if base and not Game.tips.has("arbjooze"):
		_arbjooze_arrives()


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
	if FileAccess.file_exists(Game.ART + where + "_wide.png"):  # szeroki ekran: tło dalej w obie strony
		_sprite(where + "_wide", Vector2(-320, -60), root)
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
		if p.name in ["balcony_newton", "balcony_parasol"]:  # stoją tam, gdzie teleskop: jego kolider wystarczy
			continue
		# kolider = cały obrys obiektu (bez 1 px obrysu): przez mebel nie da się przejść ani wejść w niego
		var sz := s.texture.get_size()
		feet[where if feet.has(where) else "room"].append(Rect2(p.x + 1, p.y + 1, sz.x - 2, sz.y - 3))  # laboratorium Etapu 2 = „room”
	return sorter


## kolidery: stopki obiektów + ściany wokół obszaru chodzenia (warstwa 1 pokój, 2 balkon)
func _colliders(where: String, root: Node2D) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = {"balcony": 2, "pokoik": 4}.get(where, 1)
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
	room_sort = _scene("base" if base else "room", room)
	var desk: Sprite2D = props.base_desk if base else props.room_desk
	_sprite("sticky_note", Vector2(386, 103) - desk.position, desk)  # karteczka: Teleskop → Dysk → Komputer
	props.lcd = _lcd_patch(desk)
	props.poster = _sprite("poster_iwtb", Vector2(354, 24), room.get_child(0))  # nad komputerem, widoczny
	props.radio = _sprite("radio", Vector2(588, 285) - props.room_box.position, props.room_box)
	props.luggage = Sprite2D.new()  # walizki do przeprowadzki: prawy dolny róg, gdy Etap 2 gotowy
	props.luggage.texture = Game.tex("luggage")
	props.luggage.position = Vector2(504, 334)
	props.luggage.offset = Vector2(0, -40)
	props.luggage.centered = false
	room_sort.add_child(props.luggage)
	props.parcel = Sprite2D.new()
	props.parcel.texture = Game.tex("parcel")
	props.parcel.position = Vector2(292, 244)  # na środku pokoju, na dywanie
	props.parcel.offset = Vector2(0, -24)
	props.parcel.centered = false
	room_sort.add_child(props.parcel)
	if base:
		cat = Sprite2D.new()
		cat.texture = Game.tex("arbjooze")
		cat.hframes = 5
		cat.vframes = 3
		cat.centered = false
		cat.offset = Vector2(-20, -56)
		cat.position = CAT_DESK
		cat.visible = Game.tips.has("arbjooze")
		cat.set_meta("walking", false)
		room_sort.add_child(cat)
	_colliders("room", room)
	if base:
		for d in DESKS:
			var wd := _sprite("base_catdesk", Vector2(d.x, d.y + 41), room_sort)  # sortowanie po podstawie biurka
			wd.offset = Vector2(0, -41)
			var w := Sprite2D.new()
			w.centered = false
			w.hframes = 4
			w.offset = Vector2(-22, -62)
			w.position = d + Vector2(33, 24)
			room_sort.add_child(w)
			workers.append([wd, w])
		_place_workers()
	for l in (LAB_LIGHTS if base else ROOM_LIGHTS):
		lights.append(_light(room, l))
	pc_light = lights[2]
	# shortcut: stan lamp nie trafia do zapisu (po wczytaniu włączone), dopisać do save_game, gdy lampy na coś wpłyną
	if base:
		_build_pokoik()
	else:
		lamps = {"lampka": {"light": lights[0], "on": true}, "lampa": {"light": lights[4], "on": true}}
	lights.erase(pc_light)  # monitor świeci też w dzień i migocze razem z obrazem – sterowany w _process


func _light(parent: Node, l: Array) -> PointLight2D:
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
	parent.add_child(p)
	return p


## Etap 2: pokoik Jani za drzwiami laboratorium – łóżko (sen), lampka nocna i lampa stojąca jak w starym pokoju
func _build_pokoik() -> void:
	pokoik = Node2D.new()
	add_child(pokoik)
	pokoik_sort = _scene("pokoik", pokoik)
	_colliders("pokoik", pokoik)
	var own := [ROOM_LIGHTS[0], ROOM_LIGHTS[3], ROOM_LIGHTS[4], ROOM_LIGHTS[5]].map(func(l): return _light(pokoik, l))
	lights.append_array(own)
	lamps = {"lampka": {"light": own[0], "on": true}, "lampa": {"light": own[2], "on": true}}


## LCD stoi w miejscu CRT: tło za nim odtwarzam z kolumny obok monitora (ściana + blat biurka)
func _lcd_patch(desk: Sprite2D) -> Sprite2D:
	var bg := Game.img("base" if base else "room")
	var dk := Game.img("base_desk" if base else "room_desk")
	var dpos := Vector2i(desk.position + desk.offset)
	var img := Image.create(32, 33, false, Image.FORMAT_RGBA8)  # do wiersza 99: wiersz 100 to górny obrys klawiatury
	for y in 33:
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
	rain_front = preload("res://game/sky_fx.gd").new()
	rain_front.front = true  # ulewa przed rekwizytami: przyciemnienie, smugi, rozbryzgi
	balcony.add_child(rain_front)
	_colliders("balcony", balcony)


func _refresh() -> void:
	props.lcd.visible = Game.has("lcd")
	props.poster.visible = Game.has("plakat")
	props.radio.visible = Game.has("radio")
	props.parcel.visible = not Game.parcels.is_empty() and not Game.arriving
	props.luggage.visible = Game.stage == 1 and Game.stage_ready() and not Game.stage_done
	if base:
		_place_workers()
	if Game.stage == 2 and not Game.tips.has("stage2_done") and Game.stage2_goals().all(func(g): return g[1]):
		Game.tips.stage2_done = true
		_toast("Cel Etapu 2 osiągnięty! Wielka Rozbudowa (Etap 3) już wkrótce.", "good")
	if props.luggage.visible and not Game.tips.has("luggage"):
		Game.tips.luggage = true
		_toast("Walizki spakowane. Czas na przeprowadzkę!", "good")
	props.balcony_telescope.visible = not Game.has("newton")
	props.balcony_newton.visible = Game.has("newton")
	props.balcony_parasol.visible = Game.has("parasol")
	crt.visible = Game.settings.crt
	sky_fx.raining = Game.rain
	rain_front.raining = Game.rain
	rain_front.storm = Game.storm and Game.night
	sky_fx.meteors = Game.has("meteory")
	sky_fx.comet = Game.comet.left > 0
	_ambience()


## dźwięki otoczenia z GDD 22: deszcz (inny w pokoju i na balkonie), jezioro i pora roku nad jeziorem nocą
func _ambience() -> void:
	var bal := Game.location == "balcony"
	Game.loop("rain_room", -12.0 if Game.rain and not bal else -INF)
	Game.loop("rain_balcony", (-3.0 if Game.storm else -8.0) if Game.rain and bal else -INF)
	Game.loop("lake", -10.0 if bal else -INF)
	for i in SEASON_LOOPS.size():
		var on := Game.night and not Game.rain and i == Game.season()
		Game.loop(SEASON_LOOPS[i], (-14.0 if bal else -26.0) if on else -INF)  # w pokoju cicho, zza okna


func _exit_tree() -> void:
	Game.hush()


# ---------------------------------------------------------------- fazy i miejsca
func _apply_phase(instant := false) -> void:
	var col := NIGHT_TINT if Game.night and Game.location != "balcony" else Color.WHITE
	for l in lights:
		var e: float = l.get_meta("e") if Game.night else 0.0
		for k in lamps:
			if l == lamps[k].light:
				e = _lamp_e(k)
		if instant:
			l.energy = e
		else:
			create_tween().tween_property(l, "energy", e, 1.5)
	if instant:
		modulate_node.color = col
	else:
		create_tween().tween_property(modulate_node, "color", col, 1.5)
	_refresh()


## drzwi balkonu za dnia: zmierzch, a po nim od razu na balkon
func _toggle_phase() -> void:
	if Game.night or busy or viewport:
		return
	busy = true
	_sky_anim(false, func():
		_start_night()
		if base:
			_enter("room", true)  # noc w obserwatorium: zostaje w środku, muzyka nocna
		else:
			_go("balcony"))


## okienko z pytaniem Tak/Nie (kursor widać, bo busy)
func _ask(q: String, yes: Callable) -> void:
	busy = true
	var p := _panel(Vector2(260, 92))
	var l := Label.new()
	l.text = q
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(260, 20)
	l.position = Vector2(0, 16)
	p.add_child(l)
	var close := func(): p.get_parent().queue_free(); busy = false
	for i in 2:
		var b := Button.new()
		b.text = ["TAK", "NIE"][i]
		b.position = Vector2(30 + i * 110, 50)
		b.custom_minimum_size = Vector2(90, 26)
		b.pressed.connect(func():
			close.call()
			if i == 0:
				yes.call())
		p.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
		else:
			b.shortcut = Shortcut.new()  # ESC = NIE
			var ev := InputEventAction.new()
			ev.action = "back"
			ev.pressed = true
			b.shortcut.events = [ev]


## zmierzch (dawn = false: Słońce zachodzi, wschodzi Księżyc) albo świt (odwrotnie); potem KONTYNUUJ → then
func _sky_anim(dawn: bool, then: Callable) -> void:
	var o := Control.new()
	Game.cover(o)
	top.add_child(o)
	dusk_o = o
	var k := {"u": 0.0}
	o.draw.connect(func(): _draw_dusk(o, 1.0 - k.u if dawn else k.u, k.u, dawn))
	o.create_tween().set_loops().tween_callback(o.queue_redraw).set_delay(1.0 / 30.0)  # woda, chmury i gwiazdy żyją cały czas
	var tw := o.create_tween()  # ginie razem z okienkiem
	tw.tween_method(func(v): k.u = v, 0.0, 1.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		var b := Button.new()
		b.text = "KONTYNUUJ"
		b.position = Vector2(260, 318) + Game.margin
		b.custom_minimum_size = Vector2(120, 30)
		o.add_child(b)
		b.grab_focus()
		b.pressed.connect(func():
			o.queue_free()
			busy = false
			then.call()))


## zmierzch: niebo w pasmach, chmury podświetlone od dołu, Słońce z poświatą zachodzi łukiem,
## Księżyc wschodzi z drugiej strony, odbicia w jeziorze, wzgórza z lasem, wychodzą gwiazdy
func _draw_dusk(o: Control, prog: float, u: float, dawn: bool) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dusk := clampf(prog * 2.0, 0, 1)
	var night := clampf(prog * 2.0 - 1.0, 0, 1)
	var sky_top := Color("4a8ad8").lerp(Color("3a3a78"), dusk).lerp(Color("0a0c24"), night)
	var hor := Color("a8d8f4").lerp(Color("ff9a5a"), dusk).lerp(Color("2a2650"), night)
	o.draw_set_transform(Game.margin)  # rysunek w układzie sceny 640x360, ekran może być szerszy
	var lx := -Game.margin.x
	var vw := Game.view.x
	o.draw_rect(Rect2(lx, -Game.margin.y, vw, Game.view.y), Color("0a0c24").lerp(sky_top, 0.5))
	for i in 12:  # 12 pasm koloru jak w pixel arcie (bez gładkiego gradientu)
		o.draw_rect(Rect2(lx, i * 20, vw, 20), sky_top.lerp(hor, pow(i / 11.0, 1.6)))
	for i in 90:  # gwiazdy z migotaniem
		var a := clampf(prog * 3.0 - 1.9 - (i % 7) * 0.08, 0, 1) * (0.6 + 0.4 * sin(Time.get_ticks_msec() / 300.0 + i))
		o.draw_rect(Rect2((i * 97) % 640, (i * 53) % 200, 1 + int(i % 11 == 0), 1 + int(i % 11 == 0)), Color(1, 0.95, 0.85, a))
	var c := Vector2(320, 252)
	var sun := (c + Vector2.from_angle(lerpf(-PI / 2, 0.3, prog)) * Vector2(250, 200)).floor()
	if dawn:  # o świcie Słońce wschodzi po przeciwnej stronie niż zachodziło
		sun.x = 640 - sun.x
	for k in 3:  # poświata Słońca w trzech pierścieniach, lekko pulsuje
		o.draw_circle(sun, 22 + k * 10 + roundf(sin(now * 2.0 + k) * 1.5), Color(1, 0.8, 0.45, 0.16 - k * 0.04))
	o.draw_circle(sun, 15, Color("ffe08a").lerp(Color("ff8a4a"), dusk))
	o.draw_circle(sun + Vector2(-4, -4), 6, Color(1, 1, 0.9, 0.6))
	var m := clampf((prog - 0.35) / 0.65, 0, 1)
	if m > 0:  # Księżyc wschodzi tam, gdzie potem wisi nad balkonem (492, 74)
		var moon := Vector2(lerpf(660, 492, m), 74 + 190 * (1.0 - sin(m * PI / 2))).floor()
		o.draw_circle(moon, 24, Color(0.9, 0.9, 1, 0.08 * m))
		o.draw_circle(moon, 13, Color("f4ecc8"))
		for q in [Vector2(-4, 3), Vector2(3, -5), Vector2(4, 4)]:
			o.draw_rect(Rect2(moon + q, Vector2(2, 2)), Color("d8ceaa"))
	for i in 4:  # chmury: płaskie pasma, spód podświetlony zachodem
		var cx := floorf(fposmod(60.0 + i * 170.0 + prog * 30.0 + now * (6.0 + i % 2 * 3.0), 760.0) - 60.0)
		var cy := 70.0 + (i % 2) * 40.0 + i * 8.0
		var body_c := Color("e8f0fa").lerp(Color("7a5a88"), dusk).lerp(Color("1a1838"), night)
		o.draw_rect(Rect2(cx, cy, 70, 6), body_c)
		o.draw_rect(Rect2(cx + 12, cy - 5, 36, 5), body_c)
		o.draw_rect(Rect2(cx + 4, cy + 6, 60, 2), Color("ffb070").lerp(Color("2a2246"), night))
	# ten sam widok co z balkonu (góry, las, laboratorium, jezioro), rozjaśniony za dnia i ciepły o zmierzchu
	o.draw_texture(Game.tex("balcony_view_wide"), Vector2(-320, -60), Color(1.9, 2.0, 1.7).lerp(Color(1.7, 1.15, 0.95), dusk).lerp(Color.WHITE, night))
	var glint := Color("f4f8ff").lerp(Color("ffc890"), dusk).lerp(Color("c8d0ff"), night)
	for i in 60:  # fale: krótkie błyski dryfujące po jeziorze
		var y := 224 + (i * 37) % 132
		var x := floorf(fposmod(i * 89.0 + now * (4.0 + i % 5 * 2.0), 680.0) - 20.0)
		var a := (0.25 + 0.4 * maxf(0.0, sin(now * 1.7 + i * 2.3))) * (0.6 + y / 360.0)
		o.draw_rect(Rect2(x, y, 3 + i % 4 * 2, 1), Color(glint, a))
	for body_pos in [[sun, Color("ffd890"), sun.y < 214], [Vector2(lerpf(660, 492, m), 0), Color("f4ecc8"), m > 0.3]]:
		if body_pos[2]:  # odbicie Słońca / Księżyca: drgające kreski pod nim
			for r in 14:
				var w := 6.0 + 6.0 * absf(sin(now * 3.0 + r * 1.3)) - r * 0.2
				o.draw_rect(Rect2(floorf(body_pos[0].x - w / 2), 226 + r * 6, floorf(w), 1), Color(body_pos[1], 0.8 - r * 0.045))
	if Game.rain if dawn else Game.rain_next:  # deszcz tej nocy (zmierzch) albo tej, która minęła (świt)
		o.draw_rect(Rect2(lx, -Game.margin.y, vw, Game.view.y), Color(0.12, 0.14, 0.22, 0.3))
		for i in 140:
			var p := Vector2(fposmod(i * 53.3 - now * 40.0, 700.0) - 30.0, fposmod(now * (260.0 + i % 5 * 30.0) + i * 37.0, 400.0) - 20.0).floor()
			o.draw_line(p, p + Vector2(-3, 11), Color(0.75, 0.82, 1.0, 0.25 + i % 3 * 0.08), 1.0)
	if u > 0.75:
		var a := (u - 0.75) * 4.0
		_outlined(o, Game.font_title, 16, 100, "Nowy dzień" if dawn else "Zapada noc", a)
		if dawn:
			_outlined(o, Game.font, Game.FS, 124, Game.day_name(), a)


## napis na środku z obrysem 1 px (czytelny i na jasnym niebie, i na nocnym)
func _outlined(o: CanvasItem, f: Font, fs: int, y: float, msg: String, a: float) -> void:
	var p := Vector2(320 - f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / 2, y).floor()
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		o.draw_string(f, p + d, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.08, 0.16, a))
	o.draw_string(f, p, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.98, 0.95, 0.86, a))


func _txt_on(n: CanvasItem, p: Vector2, s: String, c: Color) -> void:
	n.draw_string(Game.font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


func _start_night() -> void:
	Game.start_night()
	tired_told = false
	yawned = false
	_toast("Zapada noc. Niebo rozbłyska gwiazdami.", "info")
	if Game.rain:
		_toast("Burza z piorunami. Widoczność mocno utrudniona." if Game.storm else "Pada deszcz. Widoczność utrudniona.", "info")
	_apply_phase()


func _enter(where: String, instant := false) -> void:
	Game.location = where
	room.visible = where == "room"
	balcony.visible = where == "balcony"
	if pokoik:
		pokoik.visible = where == "pokoik"
	if body.get_parent():
		body.get_parent().remove_child(body)
	{"balcony": balcony_sort, "pokoik": pokoik_sort}.get(where, room_sort).add_child(body)
	body.collision_mask = {"balcony": 2, "pokoik": 4}.get(where, 1)  # kolizje tylko z aktualną sceną
	if where == "balcony":
		body.position = Vector2(64, 340)
		face = 1
		flip = false
	elif not instant:
		body.position = Vector2(44, 136) if base and where == "room" else Vector2(541, 136)  # z pokoiku: przy jego drzwiach
		face = 0
	elif body.position == Vector2.ZERO:
		body.position = Vector2(300, 220)
	_apply_phase(true)
	if where == "room" and Game.tips.has("tut_tel"):  # po pierwszej nocy przy teleskopie: jak sprzedawać i się rozwijać
		Game.tutorial_once(self, "pc")
	var night_music := where == "balcony" or (base and Game.night)  # Etap 2: noc spędza się w kopule
	Game.loop("music/day", MUSIC_DB if not night_music else -INF, "Music")  # pokój: dzień, balkon: noc
	Game.loop("music/night", MUSIC_DB if night_music else -INF, "Music")


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
	var pointer: bool = busy or (viewport != null and (not viewport.get("is_telescope") or viewport.get("dialog") != null))  # kursor tylko w okienkach, AstroOS i oknie wyboru w okularze
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pointer else Input.MOUSE_MODE_HIDDEN
	if viewport or busy:  # przy komputerze, teleskopie i okienkach Jania stoi (inaczej tupanie gra dalej)
		jania.set_meta("walking", false)
	_storm(dt)
	var under: bool = Game.location == "balcony" and Game.rain and Game.has("parasol") and (
		(viewport != null and viewport.get("is_telescope")) or jania.position.distance_to(props.balcony_parasol.position) < 70.0)
	if under != parasol_under:
		parasol_under = under
		Game.loop("rain_parasol", (-2.0 if Game.storm else -6.0) if under else -INF)
	if Game.night:
		Game.night_left = maxf(0.0, Game.night_left - dt)
		if Game.has("encyklopedia") and Game.night_left > 0.0:  # tylko póki trwa noc, nie do snu
			ency_acc += 0.5 * mini(Game.discovered.size(), 20) * dt
			if ency_acc >= 1.0:
				Game.add_pw(floorf(ency_acc))
				ency_acc -= floorf(ency_acc)
		if Game.night_left <= 0.0 and not tired_told:
			tired_told = true
			if viewport and viewport.has_method("tired"):
				viewport.tired()  # ziewnie po zamknięciu teleskopu (closed)
			elif viewport == null:
				_yawn()
	if is_instance_valid(dusk_o):
		dusk_o.queue_redraw()
	if Game.night and Game.location == "balcony" and not Game.rain:
		owl_t -= dt
		if owl_t <= 0.0:
			owl_t = randf_range(25.0, 60.0)
			Game.sfx("owl", randf_range(0.95, 1.05), -14.0)
	if not speech.is_empty():
		speech.t -= dt
		if speech.t <= 0:
			speech = {}
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i].t -= dt
		if toasts[i].t <= 0:
			toasts.remove_at(i)
	if viewport == null and not busy:
		_move()
	_animate(dt)
	if Game.stage >= 2:
		Game.staff_tick(dt)
		for i in workers.size():  # pracownicy machają ogonami, każdy w swoim rytmie
			workers[i][1].frame = [0, 1, 2, 3, 2, 1][int((t + i * 0.7) * 6.0) % 6] if fmod(t + i * 1.9, 5.0) < 1.0 else 0
	if cat and not cat.get_meta("walking"):  # Arbjooze stoi przodem i czasem mruga; macha chwytakiem na powitanie
		cat.flip_h = false
		var mode: int = int(Game.staff[0].mode) if not Game.staff.is_empty() and Game.tips.has("arbjooze") else 0
		var tool: int = [0, 10, 11, 12][mode]  # proteza do pracy: lupa (obserwacje), rysik (raporty), młoteczek (sprzęt)
		if mode > 0 and fmod(t, 14.0) > 11.0:
			tool = 13  # przerwa: kubeczek z mleczkiem
		cat.frame = 4 if cat_wave else (tool if tool > 0 else (1 if fmod(t + 1.3, 4.2) < 0.15 else 0))
	glow.queue_redraw()
	pc_light.energy = (1.1 if Game.night else 0.45) * (0.86 + 0.08 * sin(t * 2.1) + 0.04 * sin(t * 13.0) + (0.12 if fmod(t, 7.0) < 2.5 else 0.0))
	hud.queue_redraw()


func _move() -> void:
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
	if yawn_t >= 0.0:  # ziewa: przeciąga się z otwartą buzią, potem zasłania usta łapką
		yawn_t += dt
		var yawning: bool = yawn_t < YAWN and not jania.get_meta("walking", false)
		jania.texture = Game.tex("jania_yawn" if yawning else "jania")
		jania.hframes = 3 if yawning else 8
		jania.vframes = 1 if yawning else 3
		if yawning:
			jania.flip_h = false
			jania.frame = 0 if yawn_t < 0.5 else (1 if yawn_t < 1.7 else 2)
			return
		yawn_t = -1.0
	var frame := 0
	var walking: bool = jania.get_meta("walking", false)
	if walking:
		frame = 1 + int(t * 14.0) % 4 if face == 1 else 1 + int(t * 10.0) % 2
	elif happy_t > 0:
		face = 0
		frame = 6
	elif face == 0:
		var c := fmod(idle_t, BREATH * 4)  # idle: mrugnięcie, a co jakiś czas ucho opada i Jania podnosi je łapką –
		if c > BREATH * 2 and c < BREATH * 2 + 0.5:  # zawsze w dolnej fazie oddechu, żeby go nie rwać
			frame = 4
		elif c >= BREATH * 2 + 0.5 and c < BREATH * 2 + BREATH_DOWN:
			frame = 5
		elif fmod(idle_t, BREATH * 2) < 0.12:
			frame = 3
	elif Game.location == "balcony" and face == 1 and idle_t > 0.8 and viewport == null:
		face = 2  # na balkonie po chwili odwraca się do nieba
	if frame == 0 and not walking and fmod(idle_t, BREATH) > BREATH_DOWN:
		frame = 7  # spokojny oddech: góra ciała unosi się o 1 px
	if walking and frame != _step_frame and (face != 1 or frame in [1, 3]):
		Game.sfx("step%d" % (randi() % 4), randf_range(0.92, 1.08), -12.0)  # miękkie łapki na drewnie
	_step_frame = frame if walking else -1
	jania.frame = face * 8 + frame
	jania.flip_h = flip and face == 1


func _spots() -> Dictionary:
	if base and Game.location == "room":
		var d := BASE_SPOTS.duplicate()
		for i in workers.size():
			if workers[i][0].visible:
				d["pracownik%d" % (i + 1)] = Rect2(DESKS[i].x, DESKS[i].y + 4, 66, 38)
		return d
	return {"balcony": BALCONY_SPOTS, "pokoik": POKOIK_SPOTS}.get(Game.location, BASE_SPOTS if base else ROOM_SPOTS)


func _nearest() -> String:
	var sp := _spots()
	var best := ""
	var best_d := 1e9
	for k in sp:
		if (k == "paczka" and not props.parcel.visible) or (k == "radio" and not Game.has("radio")) or (k == "bagaze" and not props.luggage.visible):
			continue
		var r: Rect2 = sp[k]
		var d := body.position.distance_to(body.position.clamp(r.position, r.end))
		if d < REACH and d < best_d:
			best_d = d
			best = k
	return best


## panel kodów do testów: Ctrl + LPM + PPM. Tylko w buildzie debug (eksport release go nie ma).
## shortcut: chroni go tylko OS.is_debug_build(); przed wydaniem usunąć _input i _cheats razem z tym komentarzem
func _input(e: InputEvent) -> void:
	if not OS.is_debug_build() or busy or viewport:
		return
	if e is InputEventMouseButton and e.pressed and e.ctrl_pressed \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		get_viewport().set_input_as_handled()
		_cheats()


func _cheats() -> void:
	busy = true
	var p := _panel(Vector2(240, 214))
	var box := VBoxContainer.new()
	box.position = Vector2(14, 8)
	box.custom_minimum_size = Vector2(212, 0)
	p.add_child(box)
	var title := Label.new()
	title.text = "KODY (TEST)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var close := func():
		p.get_parent().queue_free()
		busy = false
	var add := func(text: String, f: Callable):
		var b := Button.new()
		b.text = text
		b.pressed.connect(f)
		box.add_child(b)
		return b
	add.call("+1000 $", func(): Game.money += 1000; Game.changed.emit())
	add.call("+1000 PW", func(): Game.pw += 1000; Game.changed.emit())
	add.call("+10000 $ I +10000 PW", func(): Game.money += 10000; Game.pw += 10000; Game.changed.emit())
	if Game.stage == 1:
		add.call("NASTĘPNY ETAP (SCENKA)", func():  # zawsze: spełnia wymagania i odpala przeprowadzkę
			Game.science["manifest"] = true
			Game.shop["certyfikat"] = true
			Game.discovered["mars"] = true
			Game.save_game()
			Game.hush()
			get_tree().change_scene_to_file("res://game/moving.tscn"))
	var c: Button = add.call("ZAMKNIJ", close)
	c.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if busy or viewport:
		return
	if e.is_action_pressed("back") or e.is_action_pressed("pause"):
		_pause()
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
				Game.tutorial_once(self, "tel")
		"komputer":
			_open(preload("res://game/astroos.gd").new())
		"pokoik":
			_go("pokoik")
		"drzwi":
			if Game.location == "pokoik":
				_go("room")
			elif Game.night and base:
				_say("Noc. Teleskop w kopule czeka.")
			elif Game.night:
				_go("balcony")
			else:
				_ask("Czy zmienić porę dnia?", _toggle_phase)
		"wroc":
			_go("room")
		"lozko":
			if Game.night:
				_sleep()
			else:
				_say("Jeszcze nie pora spać.")
		"bagaze":
			_ask("Rozpocząć przeprowadzkę nad jezioro?", func():
				Game.save_game()
				Game.hush()  # muzyka i otoczenie pokoju milkną, scenka ma swój utwór
				get_tree().change_scene_to_file("res://game/moving.tscn"))
		"paczka":
			Game.sfx("paper")
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
			_say("Pusty kubek po czekoladzie.")
		"kwiatek":
			_say("Rośnie jak na drożdżach.")
		"arbjooze":
			_cat_desk()
		"pracownik1", "pracownik2", "pracownik3", "pracownik4":
			_worker_desk(int(k.right(1)))
		"spektrograf":
			_say("Spektrograf. Rozszczepi światło gwiazd na tęczę.")
		"serwery":
			_say("Szafy z danymi. Mruczą jak Arbjooze.")
		"tablica":
			_say("Obliczenia z wczoraj. Chyba się zgadzają.")
		"podium":
			_say("Mój stary teleskop z balkonu. Od niego wszystko się zaczęło.")
		"lampa", "lampka":
			Game.sfx("switch")
			lamps[k].on = not lamps[k].on
			lamps[k].light.energy = _lamp_e(k)  # pstryczek działa od razu, bez przenikania


## pracownicy 2-5 przy swoich biurkach (zatrudnieni w AstroOS); puste biurka czekają na kolejnych
func _place_workers() -> void:
	for i in workers.size():
		var has_one := i + 1 < Game.staff.size()
		workers[i][0].visible = has_one
		workers[i][1].visible = has_one
		if has_one:
			workers[i][1].texture = Game.tex("worker_" + Game.staff[i + 1].kind)


## pracownik przy biurku: zgłoszenie [!] albo tryb pracy i krótka rozmowa
func _worker_desk(i: int) -> void:
	var p: Dictionary = Game.staff[i]
	if p.report != "":
		var id: String = p.report
		p.report = ""
		Game.reports.append(id)
		_toast("%s: Szefowo, w nocy coś błysnęło! To chyba %s." % [p.name, Game.SKY[id].name], "info")
		_toast("Niepotwierdzony sygnał: %s. Nocą sprawdź go teleskopem." % Game.SKY[id].name, "info")
		return
	busy = true
	var pn := _panel(Vector2(300, 112))
	var close := func(): pn.get_parent().queue_free(); busy = false
	var l := Label.new()
	l.text = "%s · %s" % [p.name, Game.MODES[int(p.mode) - 1]]
	l.position = Vector2(14, 10)
	pn.add_child(l)
	for m in 3:
		var b := Button.new()
		b.text = "TRYB %d" % (m + 1)
		b.position = Vector2(14 + m * 92, 40)
		b.custom_minimum_size = Vector2(86, 26)
		b.disabled = int(p.mode) == m + 1
		b.pressed.connect(func():
			p.mode = m + 1
			close.call()
			_toast("%s: %s." % [p.name, Game.MODES[m]], "info"))
		pn.add_child(b)
		if m == 0:
			b.grab_focus.call_deferred()
	var x := Button.new()
	x.text = "ZAMKNIJ"
	x.position = Vector2(14, 78)
	x.custom_minimum_size = Vector2(272, 24)
	x.pressed.connect(close)
	pn.add_child(x)


## biurko Arbjooze: najpierw zgłoszenie [!], potem menu: tryb pracy, pogłaskanie, rozmowa
func _cat_desk() -> void:
	var me: Dictionary = Game.staff[0] if not Game.staff.is_empty() else {}
	if me.is_empty():
		return
	if me.report != "":
		var id: String = me.report
		me.report = ""
		Game.reports.append(id)
		await _talk([{"who": "arbjooze", "text": "Szefowo! Podczas nocnego skanowania zauważyłem dziwny błysk... To chyba %s! Sprawdzisz dziś w nocy?" % Game.SKY[id].name},
			{"who": "jania", "text": "Niepotwierdzony sygnał. Dziś w nocy go namierzę."}])
		_toast("Niepotwierdzony sygnał: %s. Nocą sprawdź go teleskopem." % Game.SKY[id].name, "info")
		return
	busy = true
	var p := _panel(Vector2(300, 150))
	var close := func(): p.get_parent().queue_free(); busy = false
	var l := Label.new()
	l.text = "Arbjooze · %s" % Game.MODES[int(me.mode) - 1]
	l.position = Vector2(14, 10)
	p.add_child(l)
	for m in 3:
		var b := Button.new()
		b.text = "TRYB %d" % (m + 1)
		b.position = Vector2(14 + m * 92, 40)
		b.custom_minimum_size = Vector2(86, 26)
		b.disabled = int(me.mode) == m + 1
		b.pressed.connect(func():
			me.mode = m + 1
			close.call()
			_toast("Arbjooze: %s." % Game.MODES[m], "info"))
		p.add_child(b)
	for i in 2:
		var b := Button.new()
		b.text = ["POGŁASZCZ", "ROZMOWA"][i]
		b.position = Vector2(14 + i * 138, 80)
		b.custom_minimum_size = Vector2(132, 26)
		b.pressed.connect(func():
			close.call()
			if i == 0:
				cat_wave = true
				Game.tips.petted = true
				_toast("Mrrrr... Arbjooze mruczy z zadowolenia.", "good")
				await get_tree().create_timer(1.2).timeout
				cat_wave = false
			else:
				_talk([[{"who": "arbjooze", "text": "Szefowo! Mleczko wypite, notatki gotowe. Gwiazdy mogą przychodzić."}],
					[{"who": "arbjooze", "text": "Ta proteza to chwytak. Mam jeszcze lupę, młoteczek i kubeczek. Na każdą okazję!"}],
					[{"who": "arbjooze", "text": "W nocy pilnuję pomocniczego teleskopu. Kocie oczy widzą więcej."}],
					[{"who": "arbjooze", "text": "Wypłata co siedem dni, pamiętam! Ale pracuję dla gwiazd."}]][randi() % 4]))
		p.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
	var x := Button.new()
	x.text = "ZAMKNIJ"
	x.position = Vector2(14, 116)
	x.custom_minimum_size = Vector2(272, 24)
	x.pressed.connect(close)
	p.add_child(x)


## dialog w świecie: okienko z portretem, Jania stoi
func _talk(lines: Array) -> void:
	busy = true
	var d = preload("res://game/dialogue.gd").new().play(lines)
	add_child(d)
	await d.finished
	busy = false


## Arbjooze idzie do `to`: najpierw w pionie (przodem), potem w poziomie (bokiem)
func _cat_walk(to: Vector2) -> void:
	cat.set_meta("walking", true)
	for leg in [Vector2(cat.position.x, to.y), to]:
		var from := cat.position
		var dur := from.distance_to(leg) / 60.0
		if dur <= 0.0:
			continue
		var side := absf(leg.x - from.x) > 0.5
		cat.flip_h = side and leg.x < from.x
		var tw := create_tween()
		tw.tween_method(func(u: float):
			cat.position = from.lerp(leg, u).floor()
			var k := int(u * dur * 8.0)
			cat.frame = (6 + k % 4) if side else (2 + k % 2), 0.0, 1.0, dur)
		await tw.finished
	cat.set_meta("walking", false)


## Etap 2, pierwszy dzień: pukanie, wchodzi Arbjooze w kitlu, wita się chwytakiem i zostaje pierwszym pracownikiem
func _arbjooze_arrives() -> void:
	busy = true
	await get_tree().create_timer(1.6).timeout
	Game.sfx("knock")
	await get_tree().create_timer(1.0).timeout
	cat.position = Vector2(541, 124)
	cat.visible = true
	face = 1
	flip = body.position.x > 541
	await _cat_walk(Vector2(clampf(body.position.x + (60.0 if body.position.x < 480 else -60.0), 40, 600), maxf(body.position.y, 140)))
	flip = cat.position.x < body.position.x
	cat_wave = true
	Game.sfx("click")
	var d = preload("res://game/dialogue.gd").new().play([
		{"who": "arbjooze", "text": "Dzień dobry! Arbjooze, do usług. Słyszałem, że szukacie kogoś do patrzenia w gwiazdy?"},
		{"who": "jania_laugh", "text": "Kotek w kitlu! I to z chwytakiem!"},
		{"who": "arbjooze", "text": "Moja proteza. Mam też lupę, młoteczek i kubeczek na mleczko. Na każdą okazję!"},
		{"who": "jania", "text": "Witaj w zespole, Arbjooze. Twoje biurko już na Ciebie czeka."},
		{"who": "arbjooze", "text": "Dziękuję, Szefowo! Biorę się do pracy."},
	])
	d.line_shown.connect(func(l: Dictionary): cat_wave = false; happy_t = 1.6 if l.who == "jania_laugh" else 0.0)
	add_child(d)
	await d.finished
	await _cat_walk(CAT_DESK)
	Game.tips.arbjooze = true
	Game.save_game()
	busy = false
	_toast("Nowy pracownik: Arbjooze!", "good")


## koniec nocy: Jania ziewa raz (zwrócona przodem)
func _yawn() -> void:
	if yawned:
		return
	yawned = true
	yawn_t = 0.0
	face = 0
	idle_t = 0.0
	_say(TIRED)


## kurier: pukanie do drzwi, po chwili paczka na środku pokoju w kłębie dymu
var knocking := false  # paczka w drodze: ukryta do chwili, aż zasłoni ją dym


func _parcel_arrives() -> void:
	Game.sfx("knock")
	await get_tree().create_timer(0.7).timeout
	if Game.location != "room":
		knocking = false
		Game.arriving = false
		_refresh()
		return
	var puff := CPUParticles2D.new()  # duży obłok pikselowego dymu: najpierw kłąb, z niego wyłania się paczka
	puff.position = props.parcel.position + Vector2(13, -12)
	puff.amount = 90
	puff.one_shot = true
	puff.explosiveness = 0.85
	puff.lifetime = 1.6
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 14.0
	puff.direction = Vector2.UP
	puff.spread = 180.0
	puff.initial_velocity_min = 8.0
	puff.initial_velocity_max = 34.0
	puff.gravity = Vector2(0, -12)
	puff.damping_min = 10.0
	puff.damping_max = 22.0
	puff.scale_amount_min = 4.0
	puff.scale_amount_max = 8.0
	puff.color_ramp = Gradient.new()
	puff.color_ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	puff.color_ramp.colors = PackedColorArray([Color(0.95, 0.93, 0.9, 1.0), Color(0.86, 0.84, 0.86, 0.85), Color(0.72, 0.7, 0.76, 0.0)])
	room.add_child(puff)  # nad sorterem: zasłania paczkę, póki kłąb jest gęsty
	puff.emitting = true
	puff.finished.connect(puff.queue_free)
	Game.sfx("paper", 1.3, -10.0)
	await get_tree().create_timer(0.45).timeout  # paczka pojawia się dopiero w gęstym kłębie
	knocking = false
	Game.arriving = false
	_refresh()
	props.parcel.modulate.a = 0.0
	create_tween().tween_property(props.parcel, "modulate:a", 1.0, 0.8)


## włączona lampa świeci też w dzień, słabiej
func _lamp_e(k: String) -> float:
	var l: PointLight2D = lamps[k].light
	return ((l.get_meta("e") if Game.night else 0.5) if lamps[k].on else 0.0)


## monolog wewnętrzny Jani: tekst nad jej głową, bez ramki (patrz CLAUDE.md)
func _say(s: String) -> void:
	speech = {"text": s, "t": 3.5}


func _open(v: Control) -> void:
	viewport = v
	ui.add_child(v)
	v.closed.connect(func():
		viewport = null
		if Game.arriving and not knocking:  # kurier puka dopiero, gdy Jania odejdzie od komputera
			knocking = true
			_parcel_arrives()
		if tired_told and Game.night_left <= 0.0:
			_yawn()
		_refresh()
		if Game.night and not v.get("is_telescope") and not Game.tips.has("hint_bed"):
			Game.tips.hint_bed = true
			_tip("Aby zakończyć dzień, skorzystaj z łóżka."))
	if v.has_signal("discovered"):
		v.discovered.connect(func(): happy_t = 1.6; idle_t = 0.0)


# ---------------------------------------------------------------- sen i podsumowanie dnia
func _sleep() -> void:
	busy = true
	if Game.has("encyklopedia") and Game.night_left > 0.0:  # spanie przed końcem nocy: Encyklopedia dolicza resztę PW/s
		Game.add_pw(floorf(ency_acc + 0.5 * mini(Game.discovered.size(), 20) * Game.night_left))
		ency_acc = 0.0
		Game.night_left = 0.0
	var s := Game.sleep()
	var rows := []  # [opis, kwota, „$”/„PW”, znak] – tylko to, co faktycznie się wydarzyło
	if s.get("sales_n", 0) > 0:
		rows.append(["Odkrycia x%d" % s.sales_n, s.sales, "$", 1])
	if s.get("pw", 0) > 0:
		rows.append(["Punkty Wiedzy", s.pw, "PW", 1])
	for b in s.get("bought", []):
		rows.append([b[0], b[1], b[2], -1])
	for n in s.get("opened", []):
		rows.append(["Paczka: " + n, 0, "", 0])
	rows.append_array(s.get("extra", []))  # Etap 2: zespół, pensje, satelity
	const VIS := 10  # więcej wierszy (dużo zakupów): przewijanie zamiast ucinania okna
	var h := 52 + clampi(rows.size(), 1, VIS) * 18 + 46
	var p := _panel(Vector2(400, h))
	p.position = Vector2(120, floorf((360 - h - 40) / 2.0)) + Game.margin  # okienko na środku, przycisk tuż pod nim
	var title := Label.new()
	title.text = "PODSUMOWANIE · " + s.calendar
	title.position = Vector2(14, 10)
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", Game.TITLE_FS)
	title.add_theme_color_override("font_color", Color("ffcf6b"))
	p.add_child(title)
	if rows.is_empty():
		var l := Label.new()
		l.text = "Spokojny dzień – bez nowych wpływów."
		l.position = Vector2(14, 34)
		p.add_child(l)
	var sc := ScrollContainer.new()
	sc.position = Vector2(14, 34)
	sc.size = Vector2(386, mini(rows.size(), VIS) * 18)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var list := Control.new()
	list.custom_minimum_size = Vector2(372, rows.size() * 18)
	sc.add_child(list)
	var delay := 0.3
	var anims: Array[Tween] = []  # należą do panelu: giną razem z nim
	var finals := []  # [opis, kwota, tekst końcowy] – pokazywane od razu, gdy gracz pominie animację
	for i in rows.size():
		var r: Array = rows[i]
		var a := Label.new()
		a.text = r[0].left(34)
		a.position = Vector2(0, i * 18)
		a.modulate.a = 0.0
		var v := Label.new()
		v.position = Vector2(236, i * 18)
		v.size = Vector2(136, 18)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_theme_color_override("font_color", Color("a8d8f4") if r[3] == 0 else Color("ff8a7a") if r[3] < 0 else (Color("ffcf6b") if r[2] == "$" else Color("6affa0")))
		list.add_child(a)
		list.add_child(v)
		var fmt: String = ("otwarta" if r[0].begins_with("Paczka") else "") if r[3] == 0 else ("+" if r[3] > 0 else "-") + ("$%d" if r[2] == "$" else "%d PW")
		finals.append([a, v, fmt if r[3] == 0 else fmt % r[1]])
		var tw := p.create_tween()  # wiersz pojawia się, a kwota „nabija się” od zera
		anims.append(tw)
		tw.tween_interval(delay)
		tw.tween_callback(sc.ensure_control_visible.bind(v))  # lista sama przewija się za nabijanymi kwotami
		tw.tween_property(a, "modulate:a", 1.0, 0.12)
		if r[3] == 0:
			tw.tween_callback(v.set_text.bind(fmt))
			delay += 0.35
			continue
		var step := maxf(1.0, r[1] / 8.0)  # terkot licznika: ~8 tyknięć na wiersz
		var last := [0]
		tw.tween_method(func(x: float):
			if int(x / step) != last[0]:
				last[0] = int(x / step)
				Game.sfx("tick", 1.0, -8.0)
			v.text = fmt % int(x), 0.0, float(r[1]), 0.5 if r[3] > 0 else 0.25)
		if r[3] > 0:
			tw.tween_callback(Game.ding.bind(1.0 + 0.15 * i))
		delay += 0.7 if r[3] > 0 else 0.35
	var line := ColorRect.new()
	line.color = Color("4a3f6a")
	line.position = Vector2(14, h - 42)
	line.size = Vector2(372, 1)
	p.add_child(line)
	var total := Label.new()
	total.text = "Stan konta:  $%d   ·   %d PW" % [Game.money, Game.pw]
	total.position = Vector2(14, h - 38)
	total.modulate.a = 0.0
	p.add_child(total)
	anims.append(p.create_tween())
	anims[-1].tween_property(total, "modulate:a", 1.0, 0.3).set_delay(delay)
	anims[-1].tween_callback(Game.sfx.bind("chord"))  # mocniejszy akord przy sumie
	var fc := Label.new()
	fc.text = "Prognoza na noc: " + s.forecast
	fc.position = Vector2(14, h - 22)
	fc.add_theme_color_override("font_color", Color("a8b0d0"))
	p.add_child(fc)
	var ok := Button.new()
	ok.text = "KOLEJNY DZIEŃ"
	ok.custom_minimum_size = Vector2(150, 26)
	ok.position = Vector2(245 + Game.margin.x, p.position.y + h + 8)
	p.get_parent().add_child(ok)
	ok.grab_focus.call_deferred()
	ok.pressed.connect(func():
		if anims.any(func(tw: Tween): return tw.is_running()):  # pierwszy klik w trakcie animacji tylko pokazuje wynik
			for tw: Tween in anims:
				tw.kill()
			for e: Array in finals:
				e[0].modulate.a = 1.0
				e[1].text = e[2]
			total.modulate.a = 1.0
			Game.sfx("chord")
			return
		p.get_parent().queue_free()
		_sky_anim(true, func():  # świt: Księżyc zachodzi, wschodzi Słońce
			body.position = Vector2(56, 210)
			face = 0
			_enter("pokoik" if base else "room", true)  # budzi się w swoim łóżku
			tired_told = false
			yawned = false
			_toast("Nowy dzień! " + Game.calendar(), "info")
			Game.tutorial_once(self, "shop")))


func _panel(sz: Vector2) -> Panel:
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.1, 0.7)
	Game.cover(dim)
	top.add_child(dim)
	var p := Panel.new()
	p.size = sz
	p.position = ((Vector2(640, 360) - sz) / 2).floor() + Game.margin  # dzieci dim: dim zaczyna się w -margin
	dim.add_child(p)
	return p


func _pause() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := _panel(Vector2(240, 250))
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
	var back: Button = add.call("WRÓĆ DO GRY", close)
	back.grab_focus.call_deferred()
	back.shortcut = Shortcut.new()  # ESC (i Start na padzie) zamyka pauzę, gdziekolwiek jest fokus
	back.shortcut.events = ["back", "pause"].map(func(a):
		var ev := InputEventAction.new()
		ev.action = a
		ev.pressed = true
		return ev)
	add.call("ZAPISZ GRĘ", func(): Game.save_game(); _toast("Zapisano grę.", "good"))
	Game.settings_ui(box, _refresh)  # ten sam blok ustawień co w menu głównym: suwaki głośności, CRT, ekran
	add.call("ZAPISZ I WYJDŹ DO MENU", func():
		Game.save_game()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://game/menu.tscn"))


# ---------------------------------------------------------------- komunikaty
func _toast(text: String, kind: String) -> void:
	toasts.push_back({"text": text, "kind": kind, "t": 4.0})  # kolejne pod spodem, na środku ekranu
	Game.sfx("pop", 1.0, -10.0)
	if toasts.size() > 5:
		toasts.pop_front()


## burza nocą: co 6–12 s piorun z samej góry nieba do drugiego brzegu jeziora, grzmot chwilę później
func _storm(dt: float) -> void:
	if not (Game.storm and Game.night):
		Game.lightning = 0.0
		return
	Game.lightning = maxf(0.0, Game.lightning - dt * 2.5)
	flash_next -= dt
	if flash_next > 0.0:
		return
	flash_next = randf_range(6.0, 12.0)
	Game.lightning = 1.0
	var p := Vector2(randf_range(120.0, 600.0), -Game.margin.y - 2.0)
	var b := PackedVector2Array([p])
	while p.y < 206.0:  # zygzak w dół, z lekkim znoszeniem w bok
		p += Vector2(randf_range(-9.0, 9.0), randf_range(8.0, 16.0))
		b.append(p)
	Game.bolt = b
	get_tree().create_timer(randf_range(0.4, 1.4)).timeout.connect(Game.sfx.bind("thunder", randf_range(0.9, 1.1), -4.0 if Game.location == "balcony" else -12.0))


func _tip(s: String) -> void:
	tip = s
	get_tree().create_timer(9.0).timeout.connect(func(): if tip == s: tip = "")


# ---------------------------------------------------------------- rysowanie: poświaty i HUD
func _px(n: CanvasItem, x: float, y: float, w: float, h: float, c: Color) -> void:
	n.draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func _draw_glow() -> void:
	if Game.location == "balcony" or viewport:
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
			for c in CLOUDS:  # jedno wspólne niebo przesuwa się w prawo jak rolka; szyby tylko je wycinają
				var cr: Rect2 = Rect2(fposmod(c.x + t * 3.0, 640.0) - 40.0, c.y, c.z, c.w).intersection(r)
				if cr.has_area():
					_px(n, cr.position.x, cr.position.y, cr.size.x, cr.size.y, Color("f4f8ff"))
	if Game.lightning > 0.0:  # burza: szyby jaśnieją, w szybach widać piorun
		for r in panes:
			_px(n, r.position.x, r.position.y, r.size.x, r.size.y, Color(0.8, 0.86, 1.0, 0.6 * Game.lightning))
		for i in Game.bolt.size() - 1:
			var a := _pane_pt(Game.bolt[i])
			var bb := _pane_pt(Game.bolt[i + 1])
			for k in 6:
				var q := a.lerp(bb, k / 6.0).floor()
				if panes.any(func(r): return r.has_point(q)):
					_px(n, q.x, q.y, 1, 1, Color(1, 1, 1, Game.lightning))
	var at_pc := Game.location == "room"  # komputer i lampka na biurku tylko w pokoju / laboratorium
	if at_pc and Game.has("lcd"):
		_lcd_screen(n)
	elif at_pc:
		_pc_screen(n)
	if Game.rain:  # deszcz spływa po szybach
		for i in panes.size():
			var r: Rect2 = panes[i]
			for k in 3:
				var yy := fposmod(t * 40.0 + k * 9.0 + i * 5.0, r.size.y - 3)
				_px(n, r.position.x + 2 + (k * 7 + i * 3) % int(r.size.x - 3), r.position.y + yy, 1, 3, Color(0.85, 0.92, 1.0, 0.6))
	if Game.night:
		n.draw_circle(Vector2(208, 37), 4, Color("f8e9b4"))
		if at_pc:
			_px(n, 407, 75, 10, 7, Color("ffe6a0") if not base else Color("e8f0ff"))  # klosz lampki na biurku
	if lamps.lampka.on and (Game.location == "pokoik" or not base):  # klosz lampki nocnej świeci, gdy jest włączona
		_px(n, 107, 83, 14, 8, Color("ffe6a0"))


## punkt pioruna z nieba balkonu w oknie pokoju (lewe okno; ta sama burza, mniejsza skala)
func _pane_pt(p: Vector2) -> Vector2:
	return Vector2(163.0 + (p.x - 120.0) / 480.0 * 56.0, 29.0 + (p.y + 20.0) / 226.0 * 44.0)


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
	# kineskop: wyraźne linie skanowania, wędrujący jasny pas, lekkie migotanie i poświata luminoforu wokół szkła
	for y in range(1, int(r.size.y), 2):
		_px(n, r.position.x, r.position.y + y, r.size.x, 1, Color(0, 0, 0.05, 0.28))
	_px(n, r.position.x, r.position.y + fposmod(t * 6.0, r.size.y), r.size.x, 2, Color(1, 1, 1, 0.22))
	_px(n, r.position.x, r.position.y, r.size.x, r.size.y, Color(0.6, 0.9, 1.0, 0.04 + 0.03 * sin(t * 37.0)))
	_px(n, r.position.x - 1, r.position.y - 1, r.size.x + 2, 1, Color(0.5, 0.8, 1.0, 0.25))
	_px(n, r.position.x - 1, r.end.y, r.size.x + 2, 1, Color(0.5, 0.8, 1.0, 0.25))


## ekran monitora LCD: pulpit AstroOS XP „na wyższym poziomie” – więcej kolorów (pasma nieba z ditheringiem,
## wzgórza w dwóch planach, słońce z poświatą), płynne ruchy (chmury i kursor), okno z gradientem
func _lcd_screen(n: Node2D) -> void:
	var r := Rect2(351, 71, 24, 16)
	var sky := [Color("2a4ad8"), Color("3a6ae8"), Color("4a8af0"), Color("6aa8f4"), Color("8ac4f8"), Color("aad8fa")]
	for y in int(r.size.y):
		var k := y * 6.0 / 11.0
		for x in int(r.size.x):  # dithering między pasmami
			var i := mini(int(k + (0.5 if (x + y) % 2 == 0 else 0.0)), 5)
			_px(n, r.position.x + x, r.position.y + y, 1, 1, sky[i])
	n.draw_circle(r.position + Vector2(19, 3), 2.5, Color(1, 0.95, 0.7, 0.35))
	_px(n, r.position.x + 18, r.position.y + 2, 2, 2, Color("fff4c0"))
	for k in 2:  # chmury suną piksel po pikselu
		var cx := floorf(fposmod(t * 4.0 + k * 13.0, r.size.x + 6.0)) - 6.0
		for q in [[0, 1, 5, 1], [1, 0, 3, 1]]:
			var cr := Rect2(r.position.x + cx + q[0], r.position.y + 3 + k * 3 + q[1], q[2], q[3]).intersection(r)
			if cr.has_area():
				_px(n, cr.position.x, cr.position.y, cr.size.x, cr.size.y, Color("f8fcff"))
	for x in int(r.size.x):  # wzgórza: dalsze niebieskawe, bliższe soczyście zielone z jasną krawędzią
		var far := int(10.0 + 1.5 * sin(x * 0.45))
		var near := int(12.0 + 1.2 * sin(x * 0.3 + 2.0))
		_px(n, r.position.x + x, r.position.y + far, 1, r.size.y - far, Color("5aa078"))
		_px(n, r.position.x + x, r.position.y + near, 1, r.size.y - near, Color("4ab83a"))
		_px(n, r.position.x + x, r.position.y + near, 1, 1, Color("8ae85a"))
	if fmod(t, 9.0) < 4.0:  # okno programu z gradientowym paskiem tytułu
		var w := Rect2(r.position.x + 4, r.position.y + 3, 13, 9)
		_px(n, w.position.x, w.position.y, w.size.x, w.size.y, Color("f4f6fc"))
		for x in int(w.size.x):
			_px(n, w.position.x + x, w.position.y, 1, 2, Color("1a4ad8").lerp(Color("6ab0ff"), x / w.size.x))
		_px(n, w.end.x - 2, w.position.y, 1, 1, Color("ff6a5a"))
		for k in 3:
			_px(n, w.position.x + 2, w.position.y + 4 + k * 2, 3 + (k * 3 + int(t * 2.0)) % 7, 1, [Color("4a8ae8"), Color("e8a83a"), Color("5ac85a")][k])
	var cur := r.position + Vector2(4 + 15 * (0.5 + 0.5 * sin(t * 0.9)), 4 + 8 * (0.5 + 0.5 * sin(t * 1.3 + 1.0)))
	_px(n, cur.x, cur.y, 1, 3, Color.WHITE)  # kursor sunie płynnie po krzywej
	_px(n, cur.x + 1, cur.y + 1, 1, 1, Color.WHITE)
	_px(n, r.position.x, r.position.y, r.size.x, 1, Color(1, 1, 1, 0.35))  # połysk matrycy



## tekst z ciemnym obrysem 1 px (bez tła) – powiadomienia i monolog
func _otxt(n: CanvasItem, p: Vector2, s: String, c: Color) -> void:
	var o := Color(0.05, 0.03, 0.08, c.a)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		n.draw_string(Game.font, p + d, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, o)
	n.draw_string(Game.font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


func _txt(p: Vector2, s: String, c: Color) -> void:
	hud.draw_string(Game.font, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0, 0, 0, 0.6 * c.a))
	hud.draw_string(Game.font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, c)


func _wrap(s: String, width: float) -> Array:
	var out := []
	for para in s.split("\n"):  # „\n” wymusza nową linię (np. po zdaniu)
		out.append("")
		for word in para.split(" "):
			var cand: String = (out[-1] + " " + word).strip_edges()
			if _w(cand) > width and out[-1] != "":
				out.append(word)
			else:
				out[-1] = cand
	return out


func _w(s: String) -> float:
	return Game.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x


func _draw_hud() -> void:
	var n := hud
	if viewport and viewport.get("hide_hud"):
		return
	var lt := -Game.margin  # rogi ekranu (szeroki ekran: dalej niż scena 640x360)
	var rt := Vector2(Game.margin.x, -Game.margin.y)
	Game.metal(n, Rect2(lt + Vector2(4, 4), Vector2(92, 40)))
	_txt(lt + Vector2(11, 21), "$ %d" % Game.money, Color("ffcf6b"))
	_txt(lt + Vector2(11, 37), "PW %d" % Game.pw, Color("6affa0"))
	var cal := Game.calendar()
	Game.metal(n, Rect2(rt + Vector2(622 - _w(cal), 4), Vector2(_w(cal) + 14, 24)))
	_txt(rt + Vector2(629 - _w(cal), 21), cal, Color("c8c4e8"))
	if Game.night:  # pasek pozostałego czasu nocy
		var frac := Game.night_left / Game.night_length()
		Game.metal(n, Rect2(rt + Vector2(500, 32), Vector2(136, 24)))
		_txt(rt + Vector2(507, 49), "NOC %d:%02d" % [floori(Game.night_left / 60.0), int(Game.night_left) % 60], Color("c8c4e8"))
		n.draw_rect(Rect2(rt + Vector2(572, 41), Vector2(56, 6)), Color("2a2a40"))
		n.draw_rect(Rect2(rt + Vector2(572, 41), Vector2(56 * frac, 6)), Color("8aa8ff") if frac > 0.2 else Color("ff9a6a"))
	var y := 72.0
	for tt in toasts:  # powiadomienia: środek ekranu, jedno pod drugim, bez ramek
		var col: Color = {"good": Color("6affa0"), "info": Color("f4ecdc"), "say": Color("ffcf6b"), "bad": Color("ff8a8a")}[tt.kind]
		col.a = clampf(tt.t, 0, 1)
		_otxt(n, Vector2(320 - _w(tt.text) / 2, y).floor(), tt.text, col)
		y += 18
	if viewport:
		return
	if base and Game.location == "room":  # zgłoszenia [!] nad głowami zespołu
		var heads := [cat.position + Vector2(0, -60)] if cat and cat.visible else [Vector2.ZERO]
		for w in workers:
			heads.append(w[1].position + Vector2(0, -62))
		for i in mini(heads.size(), Game.staff.size()):
			if Game.staff[i].report == "" or heads[i] == Vector2.ZERO:
				continue
			var bp: Vector2 = (heads[i] + Vector2(-9, -18 - (2.0 if fmod(t + i, 0.8) < 0.4 else 0.0))).floor()
			n.draw_rect(Rect2(bp - Vector2(1, 1), Vector2(20, 18)), Color("1a1426"))
			n.draw_rect(Rect2(bp, Vector2(18, 16)), Color("ffcf4a"))
			_txt_on(n, bp + Vector2(5, 13), "!", Color("1a1426"))
	if not speech.is_empty():  # monolog Jani nad głową
		var lines := _wrap(speech.text, 200)
		for i in lines.size():
			var c := Color("fff2d0", clampf(speech.t * 2.0, 0, 1))
			_otxt(n, (body.position + Vector2(-_w(lines[i]) / 2, -58 - (lines.size() - 1 - i) * 16)).floor().clamp(Vector2(4, 16), Vector2(636 - _w(lines[i]), 356)), lines[i], c)
	var k := _nearest()
	if k != "" and not busy and speech.is_empty():
		var label: String = Game.key("interact").trim_prefix("[").trim_suffix("]")  # sam klawisz, bez opisu obiektu
		var r := Rect2((body.position + Vector2(-(_w(label) + 14) / 2, -80)).floor(), Vector2(_w(label) + 14, 24))
		r.position = r.position.clamp(Vector2(4, 4), Vector2(636, 356) - r.size)
		var cap := Game.keycap(n, r, false)
		_txt_on(n, (cap.position + Vector2((cap.size.x - _w(label)) / 2, 13)).floor(), label, Color("1a1426"))
	if tip != "":
		var w := _w(tip)
		n.draw_rect(Rect2(320 - w / 2 - 6, 332, w + 12, 22), Color(0.1, 0.08, 0.15, 0.9))
		_txt(Vector2(320 - w / 2, 349), tip, Color("f4ecdc"))
