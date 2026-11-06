extends Node
## Star Watcher – stan gry, dane Etapu 1 (z GDD v2.0), ekonomia, zapis, sterowanie.
## Autoload „Game”. Wszystkie liczby balansu są w stałych poniżej (GDD rozdz. 5, 11, 25).

signal changed            # pieniądze / PW / stan – odśwież HUD
signal toast(text: String, kind: String)

var SAVE := "user://savegame.json"
var SAVE_BAK := "user://savegame.bak.json"
const ART := "res://game/art/"
const FS := 20               # rozmiar fontu VT323 (natywna siatka 8 px na znak)

# ---------------------------------------------------------------- balans (GDD 25)
const NIGHT_BASE := 240.0
const NIGHT_MAX := 390.0
const METEOR_INTERVAL := Vector2(40, 60)
const METEOR_WINDOW := 3.5
const RAIN_CHANCE := 0.20
const COMET_NIGHTS := 3
const COMET_MIN_Q := 70
const COMET_GAP := 8
const SEASONS := ["Wiosna", "Lato", "Jesień", "Zima"]
const CATS := {"moon": "Księżyc", "const": "Konstelacje", "zodiac": "Znaki zodiaku", "nebula": "Mgławice",
	"planet": "Planety", "deep": "Głębokie niebo", "comet": "Komety"}
const MOON_PHASES := ["Nów", "Przybywający sierp", "Pierwsza kwadra", "Przybywający garb", "Pełnia",
	"Ubywający garb", "Ostatnia kwadra", "Ubywający sierp"]

# ---------------------------------------------------------------- niebo Etapu 1 (GDD 5 i 11)
# kształty konstelacji: punkty (px nieba) + krawędzie; gracz klika punkty w kolejności [1]→[2]→…
const SKY := {
	"wielki_woz": {"name": "Wielki Wóz", "cat": "const", "req": "", "pts": [[0, 6], [12, 3], [23, 7], [33, 12], [35, 25], [51, 28], [54, 14]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]], "bonus": 8, "price": 22},
	"pas_oriona": {"name": "Pas Oriona", "cat": "const", "req": "", "pts": [[0, 12], [13, 7], [26, 1]], "edges": [[0, 1], [1, 2]], "bonus": 8, "price": 18},
	"kasjopeja": {"name": "Kasjopeja", "cat": "const", "req": "", "pts": [[0, 2], [10, 15], [21, 6], [32, 17], [43, 3]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4]], "bonus": 8, "price": 25},
	"trojkat": {"name": "Trójkąt Letni", "cat": "const", "req": "podstawowe", "pts": [[0, 22], [24, 0], [36, 28]], "edges": [[0, 1], [1, 2], [2, 0]], "bonus": 8, "price": 16},
	"maly_woz": {"name": "Mały Wóz", "cat": "const", "req": "podstawowe", "pts": [[0, 0], [9, 6], [16, 11], [25, 13], [27, 24], [40, 26], [40, 14]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]], "bonus": 8, "price": 26},
	"strzala": {"name": "Strzała", "cat": "const", "req": "podstawowe", "pts": [[0, 12], [11, 9], [22, 5], [29, 0]], "edges": [[0, 1], [1, 2], [2, 3]], "bonus": 8, "price": 15},
	"labedz": {"name": "Łabędź", "cat": "const", "req": "podstawowe", "pts": [[18, 0], [18, 14], [18, 30], [0, 11], [36, 17]], "edges": [[0, 1], [1, 2], [3, 1], [1, 4]], "bonus": 15, "price": 32},
	"perseusz": {"name": "Perseusz", "cat": "const", "req": "podstawowe", "pts": [[0, 0], [8, 9], [14, 18], [24, 22], [20, 33], [32, 30]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [3, 5]], "bonus": 15, "price": 36},
	"rak": {"name": "Rak", "cat": "zodiac", "req": "podstawowe", "season": 0, "pts": [[12, 0], [12, 12], [0, 24], [24, 27]], "edges": [[0, 1], [1, 2], [1, 3]], "bonus": 20, "price": 45},
	"lew": {"name": "Lew", "cat": "zodiac", "req": "podstawowe", "season": 0, "pts": [[6, 8], [0, 0], [10, 0], [14, 12], [34, 15], [40, 8], [27, 6]], "edges": [[1, 0], [0, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]], "bonus": 20, "price": 55},
	"panna": {"name": "Panna", "cat": "zodiac", "req": "podstawowe", "season": 0, "pts": [[0, 0], [12, 8], [22, 14], [16, 28], [36, 20]], "edges": [[0, 1], [1, 2], [2, 3], [2, 4]], "bonus": 20, "price": 50},
	"waga": {"name": "Waga", "cat": "zodiac", "req": "podstawowe", "season": 1, "pts": [[14, 0], [0, 14], [28, 12], [6, 28]], "edges": [[0, 1], [1, 2], [2, 0], [1, 3]], "bonus": 20, "price": 45},
	"skorpion": {"name": "Skorpion", "cat": "zodiac", "req": "podstawowe", "season": 1, "pts": [[0, 0], [8, 6], [12, 16], [14, 28], [22, 36], [34, 36], [40, 28]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6]], "bonus": 20, "price": 60},
	"strzelec": {"name": "Strzelec", "cat": "zodiac", "req": "podstawowe", "season": 1, "pts": [[0, 10], [12, 0], [24, 6], [26, 20], [12, 24], [36, 16]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [2, 5]], "bonus": 20, "price": 52},
	"m42": {"name": "Mgławica Oriona", "cat": "nebula", "req": "obloki", "pw": 30, "price": 160, "col": "ff7aa8"},
	"m57": {"name": "Mgławica Pierścień", "cat": "nebula", "req": "obloki", "pw": 30, "price": 140, "col": "7ad8ff"},
	"m1": {"name": "Mgławica Kraba", "cat": "nebula", "req": "obloki", "pw": 30, "price": 180, "col": "ffb07a"},
	"mars": {"name": "Mars", "cat": "planet", "req": "planety", "pw": 60, "price": 110, "col": "e0603a"},
	"wenus": {"name": "Wenus", "cat": "planet", "req": "planety", "pw": 60, "price": 90, "col": "f4e3b0"},
	"jowisz": {"name": "Jowisz", "cat": "planet", "req": "planety", "pw": 60, "price": 140, "col": "d8a878"},
	"albireo": {"name": "Albireo (gwiazda podwójna)", "cat": "deep", "req": "gleb_pole", "pw": 80, "price": 300, "col": "8ab8ff"},
	"m31": {"name": "Galaktyka Andromedy", "cat": "deep", "req": "gleb_pole", "pw": 120, "price": 375, "col": "d8c8ff"},
}

# ---------------------------------------------------------------- drzewko naukowe PW (GDD 11)
const SCIENCE := [
	["czyste1", "Czyste Soczewki I", 10, 1, 0, "", "Wyostrzanie +15%."],
	["czyste2", "Czyste Soczewki II", 25, 1, 0, "czyste1", "Wyostrzanie +25% (łącznie +40%)."],
	["kursor1", "Precyzyjny Kursor I", 40, 1, 0, "", "Przyciąganie celownika do gwiazd +20%."],
	["nawyk1", "Nawyk Notowania I", 15, 1, 1, "", "+1 PW za każdy zaznaczony punkt."],
	["nawyk2", "Nawyk Notowania II", 35, 1, 1, "nawyk1", "+2 PW za punkt (łącznie +3)."],
	["kawa", "Nocna Kawa", 50, 1, 1, "", "Celownik porusza się o 20% szybciej."],
	["podstawowe", "Podstawowe Gwiazdozbiory", 20, 1, 2, "", "Proste układy 3-4 gwiazd i znaki zodiaku pory roku."],
	["meteory", "Szybkie Spadające Gwiazdy", 60, 1, 2, "podstawowe", "Na niebie przelatują meteory: +25 PW."],
	["linie", "Linie Kartograficzne", 100, 2, 0, "", "Podpowiedź zarysu konstelacji."],
	["mikro", "Pokrętło Mikro-Ruchów", 180, 2, 0, "linie", "Usuwa drgania celownika."],
	["auto1", "Autofokus DIY I", 350, 2, 0, "", "Wyostrza sam po 1 s zatrzymania celownika."],
	["pamiec1", "Pamięć Fotograficzna I", 120, 2, 1, "", "+10% PW ze wszystkich źródeł."],
	["pamiec2", "Pamięć Fotograficzna II", 250, 2, 1, "pamiec1", "Kolejne +15% PW."],
	["encyklopedia", "Encyklopedia Astronomiczna", 300, 2, 1, "", "+0,5 PW/s nocy za każdy odkryty obiekt (maks. 20)."],
	["obloki", "Głębokie Obłoki Gazu", 150, 2, 2, "podstawowe", "Mgławice i pył kosmiczny (2x PW)."],
	["kometa", "Kometa Okresowa", 280, 2, 2, "", "Kometa widoczna przez 3 noce: +150 PW."],
	["planety", "Sąsiednie Planety", 450, 2, 2, "obloki", "Mars, Wenus, Jowisz – co noc gdzie indziej."],
	["samoistne", "Samoistne Łączenie Gwiazd", 600, 3, 0, "", "Jedno kliknięcie łączy całą figurę."],
	["auto2", "Autofokus DIY II", 850, 3, 0, "samoistne", "Autofokus natychmiast."],
	["wzor", "Wzór Empiryczny", 700, 3, 1, "", "+1 PW za każdy zarobiony $."],
	["notatki", "Udostępnianie Notatek", 1000, 3, 1, "", "+50% wszystkich PW."],
	["gleb_pole", "Głębokie Pole Obserwacji", 900, 3, 2, "", "Gwiazdy podwójne i odległe galaktyki."],
	["manifest", "Manifest Naukowy „Nasze Miejsce w Kosmosie”", 5000, 3, 2, "planety", "Odblokowuje Certyfikat Terenu w sklepie."],
]
const SCIENCE_PATHS := ["Skanowanie i Optyka", "Analiza i Metodologia", "Kartografia i Kosmos"]

# ---------------------------------------------------------------- sklep Retro-Tech & Astro (GDD 11)
const SHOP := [
	["statyw", "Używany Statyw Drewniany", 20, 1, 0, "", "Drgania celownika -40%."],
	["czyszczacy", "Zestaw Czyszczący Optykę", 45, 1, 0, "", "Usuwa kurz z soczewki."],
	["modem", "Modem Dial-Up 56k", 30, 1, 1, "", "Wysyłanie raportów -40% czasu."],
	["dd", "Paczka Dyskietek 3.5\" DD", 30, 1, 1, "", "+5 slotów (10)."],
	["hd", "Paczka Dyskietek 3.5\" HD", 75, 1, 1, "dd", "+10 slotów (20)."],
	["poduszka", "Wygodna Poduszka na Balkon", 80, 1, 2, "", "Noc +1 minuta."],
	["achromat", "Szklana Soczewka Achromatyczna", 150, 2, 0, "czyszczacy", "Naprawia pękniętą szybkę. Wartość +20%."],
	["montaz", "Ręczny Montaż Paralaktyczny", 280, 2, 0, "statyw", "Płynniej, przyciąganie +35%."],
	["pudelko", "Plastikowe Pudełko na Dyskietki", 120, 2, 1, "hd", "+10 slotów (30)."],
	["vga", "Karta Graficzna VGA", 200, 2, 1, "modem", "Wartość sprzedaży +20%."],
	["astrotax", "Program „Astro-Tax 1.0”", 350, 2, 1, "dd", "+15% $ za sprzedany układ."],
	["lcd", "Monitor LCD 19\" + Nowy Komputer", 600, 2, 1, "", "AstroOS XP. Wartość +25%."],
	["termos", "Termos z Gorącą Czekoladą", 180, 2, 2, "", "Noc +1,5 minuty."],
	["plakat", "Plakat „I Want to Believe”", 150, 2, 2, "", "Komety i meteory +25% częściej."],
	["materac", "Ergonomiczny Materac", 250, 2, 2, "poduszka", "+50 PW na start każdej nocy."],
	["newton", "Teleskop Zwierciadlany Newtona", 750, 3, 0, "", "Pole widzenia +30%. Cena bazowa +50%."],
	["naped", "Napęd Elektryczny do Montażu", 1200, 3, 0, "montaz", "Teleskop sam podąża za niebem."],
	["usb", "Zewnętrzna Stacja Dyskietek USB", 50, 3, 1, "lcd", "Dyskietki działają z nowym komputerem."],
	["hdd", "Zewnętrzny Dysk HDD 5400 RPM", 300, 3, 1, "lcd", "+50 slotów."],
	["ide", "Dysk HDD w Macierzy IDE", 650, 3, 1, "hdd", "+100 slotów, +5% za serie."],
	["isdn", "Szerokopasmowe Łącze ISDN", 1000, 3, 1, "vga", "Sprzedaż natychmiast."],
	["licencja", "Licencja Niezależnego Badacza", 1200, 3, 1, "astrotax", "Zagraniczne instytuty: x2 za rzadkie układy i planety."],
	["radio", "Radio Lampowe z Muzyką Jazzową", 600, 3, 2, "", "+10% szybkości akcji w minigrach."],
	["certyfikat", "Certyfikat Terenu pod Bazy Kosmiczne", 5000, 3, 2, "manifest", "Działka nad jeziorem. Warunek Etapu 2."],
]
const SHOP_PATHS := ["Hardware i Optyka", "Komputer i Biurko", "Pokój i Komfort Jani"]

# ---------------------------------------------------------------- stan
var day := 1
var night := true
var night_left := NIGHT_BASE
var money := 0
var pw := 0
var science := {}          # id -> true
var shop := {}             # id -> true (rozpakowane, działa)
var pending := []          # zamówione, dojdą przy zmianie fazy
var parcels := []          # dostarczone, czekają na rozpakowanie
var journal := []          # wpisy Dziennika (nieprzesłane i sprzedane)
var discovered := {}       # id obiektu -> true (Encyklopedia, „zbadane” na niebie)
var moon_done := {}        # faza -> true
var tonight := {}          # obiekty zapisane tej nocy
var demand := {}           # kategoria -> mnożnik popytu dnia
var today := {}            # podsumowanie dnia
var rain := false
var rain_next := false
var comet := {"left": 0, "gap": 0, "seed": 0}
var tips := {}
var location := "balcony"
var stage_done := false
var settings := {"fullscreen": false, "crt": true}
var pad := false           # ostatnie urządzenie: pad?
var font: FontFile
var font_big: FontFile
var _ding: AudioStreamWAV
var theme: Theme
var _textures := {}
var _id_seq := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_theme()
	_make_ding()
	_load_settings()
	get_tree().set_auto_accept_quit(false)


# ---------------------------------------------------------------- zasoby
## krótki, ciepły „ding” generowany w kodzie (pełna oprawa audio w późniejszym etapie)
func _make_ding() -> void:
	var rate := 22050
	var n := int(rate * 0.4)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / rate
		var v := (sin(TAU * 1568.0 * tt) * 0.6 + sin(TAU * 2352.0 * tt) * 0.25) * exp(-tt * 9.0) * minf(1.0, tt * 400.0)
		data.encode_s16(i * 2, int(v * 11000))
	_ding = AudioStreamWAV.new()
	_ding.format = AudioStreamWAV.FORMAT_16_BITS
	_ding.mix_rate = rate
	_ding.data = data


func ding(pitch := 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _ding
	p.pitch_scale = pitch
	p.volume_db = -12.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func layout(prefix: String) -> Array:
	var d = JSON.parse_string(FileAccess.get_file_as_string(ART + prefix + "_layout.json"))
	return d if d is Array else []


func img(file: String) -> Image:
	return tex(file).get_image()


func tex(file: String) -> Texture2D:
	if not _textures.has(file):
		var path := ART + file + ".png"
		# shortcut: PNG czytane wprost z pliku (zawsze świeże, bez czekania na import edytora); przed eksportem przejść na load()
		var im := Image.new()
		im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		_textures[file] = ImageTexture.create_from_image(im)
	return _textures[file]


func _setup_theme() -> void:
	var path := "res://game/fonts/VT323-Regular.ttf"
	font = load(path) if ResourceLoader.exists(path) else FontFile.new()
	if not ResourceLoader.exists(path):
		font.load_dynamic_font(path)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE  # VT323 przy 20 px = 1 piksel na piksel
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font_big = font
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = FS
	var flat := func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(1)
		s.set_content_margin_all(3)
		return s
	theme.set_stylebox("normal", "Button", flat.call(Color("2a2340"), Color("4a3f6a")))
	theme.set_stylebox("hover", "Button", flat.call(Color("3a3058"), Color("ffcf6b")))
	theme.set_stylebox("pressed", "Button", flat.call(Color("1a1426"), Color("ffcf6b")))
	theme.set_stylebox("focus", "Button", flat.call(Color(0, 0, 0, 0), Color("ffcf6b")))
	theme.set_stylebox("disabled", "Button", flat.call(Color("1e1a2a"), Color("2e2840")))
	theme.set_color("font_color", "Button", Color("f4ecdc"))
	theme.set_color("font_hover_color", "Button", Color("ffcf6b"))
	theme.set_color("font_disabled_color", "Button", Color("6a6080"))
	theme.set_color("font_color", "Label", Color("f4ecdc"))
	theme.set_stylebox("panel", "Panel", flat.call(Color(0.1, 0.08, 0.15, 0.94), Color("4a3f6a")))
	theme.set_stylebox("panel", "PanelContainer", flat.call(Color(0.1, 0.08, 0.15, 0.94), Color("4a3f6a")))
	get_tree().root.theme = theme
	# CanvasLayer przerywa dziedziczenie motywu: nadaj go każdej kontrolce najwyższego poziomu
	get_tree().node_added.connect(func(n): if n is Control and n.theme == null and not (n.get_parent() is Control): n.theme = theme)


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT, JOY_BUTTON_DPAD_LEFT], "move_right": [KEY_D, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT],
		"move_up": [KEY_W, KEY_UP, JOY_BUTTON_DPAD_UP], "move_down": [KEY_S, KEY_DOWN, JOY_BUTTON_DPAD_DOWN],
		"interact": [KEY_E, JOY_BUTTON_A], "back": [KEY_ESCAPE, JOY_BUTTON_B], "pause": [JOY_BUTTON_START],
		"daynight": [KEY_N, JOY_BUTTON_Y], "confirm": [KEY_SPACE, KEY_ENTER, JOY_BUTTON_A],
		"prev_obj": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER], "next_obj": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
		"focus_in": [KEY_X], "focus_out": [KEY_Z],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.25)
		for k in map[a]:
			var ev: InputEvent
			if k < 32:  # przyciski pada mają małe numery, klawisze – duże
				ev = InputEventJoypadButton.new()
				ev.button_index = k
			else:
				ev = InputEventKey.new()
				ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_up", JOY_AXIS_LEFT_Y, -1.0],
			["move_down", JOY_AXIS_LEFT_Y, 1.0], ["focus_in", JOY_AXIS_RIGHT_X, 1.0], ["focus_out", JOY_AXIS_RIGHT_X, -1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.4):
		pad = true
	elif e is InputEventKey or e is InputEventMouseButton or (e is InputEventMouseMotion and e.relative.length() > 2):
		pad = false


## podpowiedź przycisku zgodna z urządzeniem
func key(action: String) -> String:
	var k := {"interact": ["E", "A"], "back": ["ESC", "B"], "daynight": ["N", "Y"], "confirm": ["LPM", "A"], "focus": ["KÓŁKO", "(R)"], "prev_next": ["Q/E", "LB/RB"]}
	return "[%s]" % k[action][1 if pad else 0]


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if get_tree().current_scene and get_tree().current_scene.name == "World":
			save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and get_tree().current_scene and get_tree().current_scene.name == "World":
		save_game()


# ---------------------------------------------------------------- reguły
func has(id: String) -> bool:
	return science.has(id) or shop.has(id)


func season() -> int:
	return int((day - 1) / 7) % 4


func calendar() -> String:
	return "Dzień %d · %s, rok %d" % [day, SEASONS[season()], int((day - 1) / 28) + 1]


func moon_phase() -> int:
	return (day + 3) % 8  # pierwsza noc: pełnia


func night_length() -> float:
	return minf(NIGHT_BASE + (60.0 if has("poduszka") else 0.0) + (90.0 if has("termos") else 0.0), NIGHT_MAX)


func storage_cap() -> int:
	var c := 5
	for p in [["dd", 5], ["hd", 10], ["pudelko", 10], ["hdd", 50], ["ide", 100]]:
		if has(p[0]):
			c += p[1]
	return c


func stored() -> Array:
	return journal.filter(func(j): return not j.sold)


func pw_mult() -> float:
	return (1.0 + (0.10 if has("pamiec1") else 0.0) + (0.15 if has("pamiec2") else 0.0)) * (1.5 if has("notatki") else 1.0)


func add_pw(amount: float) -> int:
	var v := int(round(amount * pw_mult()))
	pw += v
	today.pw = today.get("pw", 0) + v
	changed.emit()
	return v


## obiekty widoczne tej nocy (zależne od drzewka, pory roku, fazy Księżyca, komety)
func visible_objects() -> Array:
	var out := []
	if not moon_done.has(moon_phase()) and moon_phase() != 0:
		out.append("moon")
	for id in SKY:
		var o: Dictionary = SKY[id]
		if o.req != "" and not has(o.req):
			continue
		if o.has("season") and o.season != season() % 2:  # shortcut: Etap 1 = wiosna i lato
			continue
		out.append(id)
	if comet.left > 0:
		out.append("comet")
	return out


func obj_info(id: String) -> Dictionary:
	if id == "moon":
		return {"name": "Księżyc – " + MOON_PHASES[moon_phase()], "cat": "moon", "pw": 10, "price": 12}
	if id == "comet":
		return {"name": "Kometa Okresowa C/%d" % (2026 + comet.seed % 9), "cat": "comet", "pw": 150, "price": 520}
	var o: Dictionary = SKY[id].duplicate()
	if o.has("pts"):
		o.pw = o.pts.size() + o.bonus
	return o


func is_rare(entry: Dictionary) -> bool:
	return entry.cat in ["zodiac", "planet", "deep", "comet", "nebula"]


## wycena wg GDD: bazowa x jakość x popyt x (1 + bonusy) x instytut; zwraca rozbicie
func price(entry: Dictionary) -> Dictionary:
	var base: float = entry.base * (1.5 if has("newton") else 1.0)
	var bonus := 0.0
	for p in [["achromat", 0.20], ["lcd", 0.25], ["vga", 0.20], ["astrotax", 0.15]]:
		if has(p[0]):
			bonus += p[1]
	var inst := 2.0 if has("licencja") and is_rare(entry) else 1.0
	var dem: float = demand.get(entry.cat, 1.0)
	var total: float = base * entry.quality / 100.0 * dem * (1.0 + bonus) * inst
	return {"base": base, "quality": entry.quality, "demand": dem, "bonus": bonus, "inst": inst, "total": int(round(total))}


## zapis obserwacji do Dziennika; zwraca zdobyte PW albo -1 gdy brak miejsca
func record(id: String, quality: int, points := 0, replace_oldest := false) -> int:
	var info := obj_info(id)
	var s := stored()
	if s.size() >= storage_cap():
		if not replace_oldest:
			return -1
		journal.erase(s[0])
	_id_seq += 1
	journal.append({"uid": _id_seq, "id": id, "name": info.name, "cat": info.cat, "quality": quality, "base": float(info.price), "day": day, "sold": false})
	tonight[id] = true
	discovered[id] = true
	if id == "moon":
		moon_done[moon_phase()] = true
	if id == "comet":
		comet.left = 0
		comet.gap = COMET_GAP
	var gained: float = info.pw
	if points > 0:
		gained += points * ((1 if has("nawyk1") else 0) + (2 if has("nawyk2") else 0))
	return add_pw(gained)


func sell(entries: Array) -> int:
	var sum := 0
	for e in entries:
		sum += price(e).total
		e.sold = true
	money += sum
	today.sales = today.get("sales", 0) + sum
	today.sales_n = today.get("sales_n", 0) + entries.size()
	if has("wzor"):
		pw += sum  # Wzór Empiryczny: +1 PW za każdy $
		today.pw = today.get("pw", 0) + sum
	changed.emit()
	return sum


func meteor_caught() -> Array:
	var cash := randi_range(10, 20)
	money += cash
	today.meteors = today.get("meteors", 0) + cash
	today.meteors_n = today.get("meteors_n", 0) + 1
	return [add_pw(25), cash]


func can_buy_science(row: Array) -> String:
	if science.has(row[0]):
		return "owned"
	if row[5] != "" and not science.has(row[5]):
		return "req"
	var tier1 := SCIENCE.filter(func(r): return r[3] == 1 and science.has(r[0])).size()
	var tier2 := SCIENCE.filter(func(r): return r[3] == 2 and science.has(r[0])).size()
	if row[3] == 2 and tier1 < 3 or row[3] == 3 and tier2 < 4:
		return "tier"
	return "ok" if pw >= row[2] else "cost"


func buy_science(row: Array) -> void:
	pw -= row[2]
	science[row[0]] = true
	if row[0] == "kometa" and comet.left == 0:
		comet = {"left": COMET_NIGHTS, "gap": 0, "seed": randi()}
	changed.emit()
	toast.emit("Odblokowano: " + row[1], "good")


func can_buy_shop(row: Array) -> String:
	if shop.has(row[0]) or row[0] in pending or row[0] in parcels:
		return "owned"
	if row[0] == "certyfikat" and not science.has("manifest"):
		return "hidden"
	if row[5] != "" and not has(row[5]):
		return "req"
	return "ok" if money >= row[2] else "cost"


func buy_shop(row: Array) -> void:
	money -= row[2]
	pending.append(row[0])
	changed.emit()
	toast.emit("Zamówiono: %s. Kurier przyjdzie przy zmianie pory dnia." % row[1], "info")


func unpack_all() -> void:
	for id in parcels:
		shop[id] = true
	if not parcels.is_empty():
		toast.emit("Rozpakowano: " + ", ".join(parcels.map(func(i): return _shop_name(i))), "good")
	parcels.clear()
	changed.emit()


func _shop_name(id: String) -> String:
	for r in SHOP:
		if r[0] == id:
			return r[1]
	return id


func _deliver() -> void:
	unpack_all()  # nierozpakowane paczki rozpakowują się same przy kolejnej zmianie fazy
	parcels = pending.duplicate()
	pending.clear()
	if not parcels.is_empty():
		toast.emit("Kurier zostawił paczkę pod drzwiami!", "info")


func stage_ready() -> bool:
	return science.has("manifest") and shop.has("certyfikat") and discovered.keys().any(func(k): return SKY.has(k) and SKY[k].cat == "planet")


# ---------------------------------------------------------------- pętla dnia
func start_night() -> void:
	night = true
	night_left = night_length()
	tonight.clear()
	rain = rain_next
	_deliver()
	if has("materac"):
		add_pw(50)
	changed.emit()


## „Idź spać”: zwraca dane do Podsumowania Dnia, przechodzi w poranek i robi autozapis
func sleep() -> Dictionary:
	var summary := today.duplicate()
	summary.day = day
	summary.calendar = calendar()
	day += 1
	night = false
	location = "room"
	today = {}
	if comet.left > 0:
		comet.left -= 1
		if comet.left == 0:
			comet.gap = COMET_GAP
	elif has("kometa"):
		comet.gap -= 1
		if comet.gap <= 0 and randf() < (1.25 if has("plakat") else 1.0) * 0.6:
			comet = {"left": COMET_NIGHTS, "gap": 0, "seed": randi()}
	rain_next = randf() < RAIN_CHANCE
	summary.forecast = "deszcz – słaba widoczność" if rain_next else "pogodnie"
	_roll_demand()
	_deliver()
	save_game()
	return summary


func _roll_demand() -> void:
	demand.clear()
	var cats := CATS.keys()
	cats.shuffle()
	for i in randi_range(1, 2):
		demand[cats[i]] = snappedf(randf_range(1.2, 1.6), 0.05)
	demand[cats[3]] = snappedf(randf_range(0.7, 0.9), 0.05)


func new_game() -> void:
	day = 1
	night = true
	night_left = night_length()
	money = 0
	pw = 0
	for d in [science, shop, discovered, moon_done, tonight, tips, demand, today]:
		d.clear()
	pending.clear()
	parcels.clear()
	journal.clear()
	rain = false
	rain_next = false
	comet = {"left": 0, "gap": 0, "seed": 0}
	location = "balcony"
	stage_done = false
	_roll_demand()


# ---------------------------------------------------------------- zapis
const SAVED := ["day", "night", "night_left", "money", "pw", "science", "shop", "pending", "parcels", "journal", "discovered",
	"moon_done", "tonight", "demand", "today", "rain", "rain_next", "comet", "tips", "location", "stage_done", "_id_seq"]


func has_save() -> bool:
	return FileAccess.file_exists(SAVE) or FileAccess.file_exists(SAVE_BAK)


func save_game() -> void:
	var d := {}
	for k in SAVED:
		d[k] = get(k)
	if FileAccess.file_exists(SAVE):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(SAVE_BAK))
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> bool:
	for path in [SAVE, SAVE_BAK]:  # kopia zapasowa na wypadek uszkodzenia pliku
		if not FileAccess.file_exists(path):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for k in SAVED:
				if d.has(k):
					set(k, d[k])
			day = int(day)
			money = int(money)
			pw = int(pw)
			_id_seq = int(_id_seq)
			moon_done = _int_keys(moon_done)
			changed.emit()
			return true
	return false


func _int_keys(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		o[int(k)] = d[k]
	return o


func _load_settings() -> void:
	var f := "user://settings.json"
	if FileAccess.file_exists(f):
		var d = JSON.parse_string(FileAccess.get_file_as_string(f))
		if d is Dictionary:
			settings.merge(d, true)
	apply_settings()


func apply_settings() -> void:
	get_window().mode = Window.MODE_FULLSCREEN if settings.fullscreen else Window.MODE_WINDOWED
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


# testy piszą do osobnego pliku, zapis gracza zostaje nietknięty
func use_test_save() -> void:
	SAVE = "user://test_save.json"
	SAVE_BAK = "user://test_save.bak.json"
