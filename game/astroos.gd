extends Control
## Komputer: AstroOS – pulpit z tapetą i ikonami; każdy program otwiera się w oknie na cały ekran
## (górny pasek systemu zostaje). Programy: Dziennik, Giełda, Retro-Tech, Drzewko Badań, POMOC.TXT (GDD 8).

signal closed
signal stage_complete

const HELP := """NOC (balkon)
• Teleskop: najedź celownikiem na świecący obiekt (zacznie drżeć) i kliknij PPM.
• Kółkiem myszy kręć w przód i w tył – szukasz balansu. Obraz najpierw się wyostrza, potem znowu rozmywa. Gdy jest ostry, soczewka sama „kliknie”.
• Konstelacje: klikaj świecące gwiazdy po kolei, aż połączą się w figurę.
• Odkryte obiekty mają znaczek. Zapis trafia na dysk – gdy się zapełni, kup dyskietki.
• Noc kończy się, gdy pasek czasu dobiegnie końca. Do łóżka trzeba dojść samemu.

DZIEŃ (komputer)
• Giełda: wyślij raport z odkryciami (także w nocy) – Centrum Naukowe zapłaci rano. Ceny zależą od popytu dnia – patrz wykres.
• Retro-Tech ($): sprzęt i komfort. Zakupy przychodzą kurierem.
• Drzewko Badań (PW): nowe obiekty na niebie i ułatwienia.
• Esc zamyka okno, drugie Esc wyłącza komputer.

CEL ETAPU: Manifest Naukowy (5000 PW) → Certyfikat Terenu ($5000) → min. 1 planeta → złota gwiazda INICJUJ ETAP 2 na pulpicie."""

const APPS := [["dziennik", "Dziennik"], ["gielda", "Giełda"], ["sklep", "Retro-Tech"], ["badania", "Badania"], ["pomoc", "POMOC.TXT"]]
const TITLES := {"dziennik": "Dziennik Odkryć", "gielda": "Giełda i Centrum Naukowe", "sklep": "Retro-Tech & Astro Store",
	"badania": "Badania", "pomoc": "POMOC.TXT – Notatnik"}
const BAR := 22            # górny pasek systemu
const TB := 20             # pasek tytułu okna
const INK := Color("1a1626")
const PATH_COL := [Color("2fb8e8"), Color("f4b830"), Color("a45ae8")]
const CAT_COL := {"moon": "f4e8b0", "const": "5ab0ff", "zodiac": "ff8a5a", "nebula": "e86ad8", "planet": "ffcf4a", "deep": "9a9aff", "comet": "6af0c8"}
const SHOP_ICONS := ["cat_optyka", "cat_komputer", "cat_pokoj"]
const SHOP_SHORT := ["Optyka", "Komputer", "Pokój"]
const GLYPHS := ["glyph_optyka", "glyph_analiza", "glyph_kosmos"]

var hide_hud := true
var app := ""              # otwarty program ("" = pulpit)
var bar: Control
var win: Control           # okno programu (pasek tytułu + treść)
var body: Control          # treść okna
var info: Label            # opis na dole okna
var selected := {}
var shop_cat := 0
var tab_hover := -1        # karta programu pod kursorem na pasku okna
var tabs_x := 0.0          # gdzie zaczynają się karty (zależy od długości tytułu)
var hover := -1            # węzeł drzewka pod kursorem
var nodes := []            # [pozycja, wiersz SCIENCE] drzewka
var t := 0.0


func _ready() -> void:
	size = Vector2(640, 360)
	theme = _make_theme()
	var wall := TextureRect.new()
	wall.texture = Game.tex("os/os_wallpaper")
	add_child(wall)
	var icons := Control.new()
	add_child(icons)
	var list := APPS.duplicate()
	if Game.stage_ready():
		list.append(["etap", "ETAP 2"])
	for i in list.size():
		var b := Button.new()
		b.flat = true
		b.icon = Game.tex("os/icon_" + list[i][0])
		b.text = list[i][1]
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.custom_minimum_size = Vector2(92, 64)
		b.position = Vector2(10, BAR + 4 + i * 66) if i < 5 else Vector2(106, BAR + 4)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color("fff2a0"))
		b.add_theme_color_override("font_outline_color", INK)
		b.add_theme_constant_override("outline_size", 3)
		for st in ["normal", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		for st in ["hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, _box(Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.7)))
		b.pressed.connect(_launch.bind(list[i][0]))
		icons.add_child(b)
	bar = Control.new()
	bar.size = Vector2(640, BAR)
	bar.draw.connect(_draw_bar)
	add_child(bar)
	bar.gui_input.connect(func(e):  # „Wyłącz” rysowane w pasku (przycisk z czcionką 20 px nie mieści się w 22 px)
		if e is InputEventMouseButton and e.pressed and e.position.x > 570:
			close())
	Game.changed.connect(bar.queue_redraw)
	var k := maxi(1, mini(get_window().size.x / 640, get_window().size.y / 360))  # gra skaluje się całkowicie
	var arrow := Game.img("os/ui_cursor")
	arrow.resize(arrow.get_width() * k, arrow.get_height() * k, Image.INTERPOLATE_NEAREST)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(arrow))



func _process(dt: float) -> void:
	t += dt
	if app in ["gielda", "badania"] and body:
		body.queue_redraw()


# ---------------------------------------------------------------- styl (jasne okna jak w starych systemach)
func _box(bg: Color, border: Color, w := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(w)
	s.set_content_margin_all(3)
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


func _make_theme() -> Theme:
	var th: Theme = Game.theme.duplicate()
	th.set_stylebox("normal", "Button", _box(Color("e4e4ea"), Color("6a6a80")))
	th.set_stylebox("hover", "Button", _box(Color("ffffff"), Color("2a5ad8")))
	th.set_stylebox("pressed", "Button", _box(Color("c8d4f0"), Color("2a5ad8")))
	th.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color("2a5ad8")))
	th.set_stylebox("disabled", "Button", _box(Color("cfd0d6"), Color("9a9aa8")))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		th.set_color(k, "Button", INK)
		th.set_color(k, "CheckBox", Color("d8f0e0"))
	th.set_color("font_disabled_color", "Button", Color("80808c"))
	for ic in ["checked", "unchecked"]:  # stan pokazuje tekst [x] / [ ]
		th.set_icon(ic, "CheckBox", ImageTexture.new())
	th.set_color("font_color", "Label", INK)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		th.set_stylebox(st, "CheckBox", _box(Color(1, 1, 1, 0.08) if st == "hover" else Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	return th


func _button(text: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(f)
	return b


func _label(parent: Node, text: String, pos: Vector2, col := INK, w := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if w > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(w, 0)
	parent.add_child(l)
	return l


func _scroll(parent: Node, r: Rect2) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.position = r.position
	sc.size = r.size
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_step = 20  # kółko przesuwa o cały wiersz – bez uciętych linii
	sc.get_v_scroll_bar().step = 20
	parent.add_child(sc)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(r.size.x - 10, 0)
	v.add_theme_constant_override("separation", 0)
	sc.add_child(v)
	return v


func _draw_bar() -> void:
	bar.draw_rect(Rect2(0, 0, 640, BAR), Color("dcdce4"))
	bar.draw_rect(Rect2(0, 0, 640, 1), Color.WHITE)
	bar.draw_rect(Rect2(0, BAR - 1, 640, 1), Color("4a4a5c"))
	bar.draw_rect(Rect2(572, 2, 64, 18), Color("f4f4f8"))
	bar.draw_rect(Rect2(572, 2, 64, 18), Color("4a4a5c"), false)
	bar.draw_string(Game.font, Vector2(572, 16), "Wyłącz", HORIZONTAL_ALIGNMENT_CENTER, 64, Game.FS, INK)
	bar.draw_texture_rect(Game.tex("os/icon_etap"), Rect2(4, 3, 16, 16), false)
	var os_name := "AstroOS XP" if Game.has("lcd") else "AstroOS"
	for dx in 2:  # pogrubienie: tekst dwa razy z przesunięciem o 1 px
		bar.draw_string(Game.font, Vector2(24 + dx, 16), os_name, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, INK)
	var x := 24 + Game.font.get_string_size(os_name, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 16
	for s in [["$ %d" % Game.money, Color("2a7a3a")], ["PW %d" % Game.pw, Color("6a3ac8")], [Game.calendar(), Color("3a3a50")]]:
		bar.draw_string(Game.font, Vector2(x, 16), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, s[1])
		x += Game.font.get_string_size(s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 16


# ---------------------------------------------------------------- okna
func _launch(id: String) -> void:
	Game.ding(1.4)
	if id == "etap":
		stage_complete.emit()
		close()
		return
	if win:
		win.queue_free()
	app = id
	win = Control.new()
	win.position = Vector2(0, BAR)
	win.size = Vector2(640, 360 - BAR)
	win.draw.connect(_draw_frame)
	add_child(win)
	win.gui_input.connect(func(e):
		if e is InputEventMouseMotion:
			var h := _tab_at(e.position)
			if h != tab_hover:
				tab_hover = h
				win.queue_redraw()
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if Rect2(616, 0, 24, TB).has_point(e.position):
				_close_app()
			elif _tab_at(e.position) >= 0 and APPS[_tab_at(e.position)][0] != app:
				_launch(APPS[_tab_at(e.position)][0]))
	_rebuild()


func _rebuild() -> void:
	if body:
		body.queue_free()
	body = Control.new()
	body.position = Vector2(0, TB)
	body.size = Vector2(640, 360 - BAR - TB)
	body.clip_contents = true
	win.add_child(body)
	info = null
	nodes.clear()
	call("_" + app)


func _tab_at(p: Vector2) -> int:
	if p.y > TB or p.x < tabs_x:
		return -1
	var i := int((p.x - tabs_x) / 24)
	return i if i < APPS.size() else -1


func _close_app() -> void:
	if not win:
		return
	win.queue_free()
	win = null
	body = null
	app = ""


func _draw_frame() -> void:
	win.draw_rect(Rect2(0, 0, 640, TB), Color("d6d6de"))
	win.draw_rect(Rect2(0, 0, 640, 1), Color.WHITE)
	win.draw_rect(Rect2(0, TB - 1, 640, 1), INK)
	for i in 2:  # dwa kwadraciki jak w starych oknach
		win.draw_rect(Rect2(4 + i * 16, 3, 12, 12), Color("f4f4f8"))
		win.draw_rect(Rect2(4 + i * 16, 3, 12, 12), Color("6a6a80"), false)
	win.draw_rect(Rect2(7, 6, 6, 6), Color("4a4a5c"))
	var title: String = TITLES[app]
	win.draw_string(Game.font, Vector2(46, 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, INK)
	tabs_x = 46 + Game.font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 10
	for i in APPS.size():  # karty programów: przełączanie bez wychodzenia na pulpit
		var r := Rect2(tabs_x + i * 24, 1, 22, TB - 2)
		var on: bool = APPS[i][0] == app
		win.draw_rect(r, Color.WHITE if on else (Color("ececf2") if i == tab_hover else Color("c4c4ce")))
		win.draw_rect(r, INK if on else Color("8a8a9c"), false)
		var ic := Game.tex("os/tab_" + APPS[i][0])
		win.draw_texture(ic, r.position + ((r.size - ic.get_size()) / 2).floor(), Color(1, 1, 1, 1.0 if on or i == tab_hover else 0.7))
	var x0 := tabs_x + APPS.size() * 24 + 8
	for k in 3:  # „uchwyt” paska tytułu
		win.draw_rect(Rect2(x0, 6 + k * 3, 610 - x0, 1), Color("8a8a9c"))
		win.draw_rect(Rect2(x0, 7 + k * 3, 610 - x0, 1), Color.WHITE)
	win.draw_rect(Rect2(618, 3, 16, 14), Color("e85a4a"))
	win.draw_rect(Rect2(618, 3, 16, 14), INK, false)
	win.draw_line(Vector2(622, 6), Vector2(630, 14), Color.WHITE, 2)
	win.draw_line(Vector2(630, 6), Vector2(622, 14), Color.WHITE, 2)


func _bg(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.size = body.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(r)


func _info(r: Rect2, col := INK) -> void:
	info = _label(body, "", r.position, col, r.size.x)


# ---------------------------------------------------------------- Dziennik (zeszyt w linie)
func _dziennik() -> void:
	_bg(Color("f4ecd2"))
	var lines := Control.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(func():
		for y in range(43, 322, 20):
			lines.draw_rect(Rect2(0, y, 640, 1), Color("b8c8e4"))
		lines.draw_rect(Rect2(36, 0, 1, 322), Color("e88a8a")))
	body.add_child(lines)
	var zod := Game.discovered.keys().filter(func(k): return Game.SKY.has(k) and Game.SKY[k].cat == "zodiac").size()
	_label(body, "Pamięć %d/%d · Odkryte obiekty %d · Zodiak %d/12 · Sprzedane %d" % [Game.stored().size(), Game.storage_cap(),
		Game.discovered.size(), zod, Game.journal.size() - Game.stored().size()], Vector2(44, 2), Color("2a3a8a"))
	_label(body, "%-30s%-15s%7s%8s%6s" % ["Obiekt", "Kategoria", "Jakość", "Wartość", "Dzień"], Vector2(44, 24), Color("8a3a3a"))
	_info(Rect2(44, 268, 590, 50), Color("2a3a8a"))
	var v := _scroll(body, Rect2(40, 44, 600, 220))
	for e in Game.stored():
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%-30s%-15s%6d%%%8s%6d" % [e.name.left(29), Game.CATS[e.cat].left(14), e.quality, "$%d" % Game.price(e).total, e.day]
		b.add_theme_stylebox_override("hover", _box(Color(1, 0.9, 0.4, 0.35), Color(0, 0, 0, 0)))
		b.mouse_entered.connect(func(): info.text = _breakdown(e))
		v.add_child(b)


func _breakdown(e: Dictionary) -> String:
	var p := Game.price(e)
	return "%s – gotowe do wysyłki.\nBazowa $%d × jakość %d%% × popyt ×%.2f × (1+bonusy %d%%) × instytut ×%.1f = $%d" % [
		e.name, p.base, p.quality, p.demand, int(p.bonus * 100), p.inst, p.total]


# ---------------------------------------------------------------- Giełda (ticker, wykres popytu, portfel)
func _gielda() -> void:
	if not Game.tips.has("chart"):  # pierwszy raz: pierwsza kategoria; potem pamiętamy wybór gracza
		Game.tips.chart = {Game.CATS.keys()[0]: true}
	body.draw.connect(_draw_market)
	_label(body, "NOTOWANIA", Vector2(6, 156), Color("ffcf4a"))
	var legend := VBoxContainer.new()
	legend.position = Vector2(4, 178)
	legend.add_theme_constant_override("separation", 0)
	body.add_child(legend)
	for c in Game.CATS:
		var cb := CheckBox.new()
		var d := _change(c)
		var txt := "%-12s%4d%4s" % [Game.CATS[c].left(12), int(round(_dem(-1, c) * 100)), ("+%d" if d >= 0 else "%d") % d]
		cb.button_pressed = Game.tips.chart.get(c, false)
		cb.text = ("[x] " if cb.button_pressed else "[ ] ") + txt
		cb.custom_minimum_size = Vector2(206, 20)
		for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			cb.add_theme_color_override(k, Color(CAT_COL[c]))
		cb.toggled.connect(func(on):
			Game.tips.chart[c] = on
			cb.text = ("[x] " if on else "[ ] ") + txt)
		legend.add_child(cb)
	_label(body, "PORTFEL ODKRYĆ", Vector2(6, 22), Color("ffcf4a"))
	var stored := Game.stored()
	if stored.is_empty():
		_label(body, "Nie ma nic do wysłania. Odkrycia z nocy pojawią się tutaj.", Vector2(6, 48), Color("8aa0b8"), 440)
		return
	_label(body, "    %-28s%7s%8s" % ["Obiekt", "Jakość", "Cena"], Vector2(6, 40), Color("6a8aa8"))
	var v := _scroll(body, Rect2(4, 60, 440, 80))  # 4 pełne wiersze, przewijanie co wiersz
	var total := _label(body, "", Vector2(460, 22), Color("6aff8a"))
	total.add_theme_font_size_override("font_size", Game.FS * 2)
	var sell := _button("WYŚLIJ RAPORT", func():
		Game.send_report(stored.filter(func(e): return selected.get(e.uid, false)))
		selected.clear()
		_rebuild())
	sell.position = Vector2(458, 70)
	sell.size = Vector2(174, 34)
	sell.add_theme_stylebox_override("normal", _box(Color("2ab85a"), Color("0a3a1a"), 2))
	sell.add_theme_stylebox_override("hover", _box(Color("4ad87a"), Color("0a3a1a"), 2))
	sell.add_theme_color_override("font_color", Color.WHITE)
	var update := func():
		var sum := 0
		for e in stored:
			sum += Game.price(e).total if selected.get(e.uid, false) else 0
		total.text = "$%d" % sum
		sell.disabled = sum == 0
	var checks := []
	var all := _button("Zaznacz wszystkie", func():
		for c in checks:
			c.button_pressed = true)
	all.position = Vector2(458, 112)
	all.size = Vector2(174, 22)
	body.add_child(all)
	body.add_child(sell)
	for e in stored:
		var cb := CheckBox.new()
		var txt := "%-28s%6d%%%8s" % [e.name.left(27), e.quality, "$%d" % Game.price(e).total]
		cb.text = ("[x] " if selected.get(e.uid, false) else "[ ] ") + txt
		cb.button_pressed = selected.get(e.uid, false)
		cb.custom_minimum_size.y = 20
		cb.toggled.connect(func(on):
			selected[e.uid] = on
			cb.text = ("[x] " if on else "[ ] ") + txt
			update.call())
		v.add_child(cb)
		checks.append(cb)
	update.call()
	if not Game.offer_entry().is_empty():
		_offer_popup()


func _offer_popup() -> void:
	var e := Game.offer_entry()
	var box := Panel.new()
	box.add_theme_stylebox_override("panel", _box(Color("10243a"), Color("ffcf4a"), 2))
	box.position = Vector2(120, 70)
	box.size = Vector2(400, 150)
	body.add_child(box)
	_label(box, "OFERTA SPECJALNA", Vector2(12, 8), Color("ffcf4a"))
	_label(box, "%s chce kupić „%s” (jakość %d%%) za $%d.\nNa giełdzie dostałbyś dziś $%d." % [Game.offer.who, e.name, e.quality, Game.offer.price, Game.price(e).total],
		Vector2(12, 32), Color("d8e8f8"), 376)
	var yes := _button("SPRZEDAJ  $%d" % Game.offer.price, func():
		Game.toast.emit("Sprzedano „%s”: +$%d" % [e.name, Game.accept_offer()], "good")
		Game.ding(1.3)
		_rebuild())
	yes.position = Vector2(12, 110)
	yes.size = Vector2(200, 28)
	yes.add_theme_stylebox_override("normal", _box(Color("2ab85a"), Color("0a3a1a"), 2))
	yes.add_theme_stylebox_override("hover", _box(Color("4ad87a"), Color("0a3a1a"), 2))
	yes.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(yes)
	var no := _button("Odrzuć", func():
		Game.offer = {}
		_rebuild())
	no.position = Vector2(276, 110)
	no.size = Vector2(112, 28)
	box.add_child(no)


func _dem(i: int, c: String) -> float:
	var hist: Array = Game.demand_log if not Game.demand_log.is_empty() else [Game.demand]
	return hist[i].get(c, 1.0) if i < 0 or i < hist.size() else 1.0


func _change(c: String) -> int:
	return int(round((_dem(-1, c) - (_dem(-2, c) if Game.demand_log.size() > 1 else 1.0)) * 100))


func _draw_market() -> void:
	var n := body
	n.draw_rect(Rect2(Vector2.ZERO, n.size), Color("0b1622"))
	# ticker: notowania przewijają się w pętli
	n.draw_rect(Rect2(0, 0, 640, 20), Color("050c14"))
	var items := []
	var cycle := 0.0
	for c in Game.CATS:
		var d := _change(c)
		var a := "%s %d " % [Game.CATS[c].to_upper(), int(round(_dem(-1, c) * 100))]
		var b := "%+d%%   " % d
		var wa := Game.font.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
		items.append([a, b, d >= 0, wa])
		cycle += wa + 10 + Game.font.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
	var x := -fposmod(t * 40.0, cycle)
	while x < 640:
		for it in items:
			n.draw_string(Game.font, Vector2(x, 15), it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("c8d8e8"))
			x += it[3]
			var col := Color("4ae87a") if it[2] else Color("ff5a4a")
			n.draw_colored_polygon(PackedVector2Array([Vector2(x, 13), Vector2(x + 8, 13), Vector2(x + 4, 7)] if it[2] else
				[Vector2(x, 7), Vector2(x + 8, 7), Vector2(x + 4, 13)]), col)
			n.draw_string(Game.font, Vector2(x + 10, 15), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, col)
			x += 10 + Game.font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
	n.draw_rect(Rect2(0, 151, 640, 1), Color("1e3248"))
	if not Game.analysis.uids.is_empty():  # raport czeka na poranną wypłatę
		n.draw_string(Game.font, Vector2(458, 144), "Raport (%d): wypłata rano" % Game.analysis.uids.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("ffcf4a"))
	# wykres popytu (indeks = mnożnik × 100): tylko zaznaczone kategorie
	var r := Rect2(230, 158, 404, 156)
	n.draw_rect(r, Color("101e2e"))
	var lo := 60.0
	var hi := 170.0
	for v in [70, 100, 130, 160]:
		var y: float = r.end.y - (v - lo) / (hi - lo) * r.size.y
		n.draw_rect(Rect2(r.position.x, y, r.size.x, 1), Color("1e3248") if v != 100 else Color("3a5a78"))
		n.draw_string(Game.font, Vector2(r.position.x + 2, y - 2), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("3a5a78"))
	var hist: Array = Game.demand_log
	if hist.size() < 2:
		n.draw_string(Game.font, r.position + Vector2(120, 80), "Za mało notowań", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("6a8aa8"))
		return
	var step := (r.size.x - 40) / (hist.size() - 1)
	for c in Game.CATS:
		if Game.tips.chart.get(c, false):
			_line(n, r, hist, c, step, lo, hi, Color(CAT_COL[c]), 2.0)
	n.draw_string(Game.font, Vector2(r.end.x - 116, r.end.y - 4), "dziś", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color("6a8aa8"))


func _line(n: Control, r: Rect2, hist: Array, c: String, step: float, lo: float, hi: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for k in hist.size():
		pts.append(Vector2(r.position.x + 30 + k * step, r.end.y - (hist[k].get(c, 1.0) * 100 - lo) / (hi - lo) * r.size.y))
	n.draw_polyline(pts, col, w)
	n.draw_rect(Rect2(pts[-1] - Vector2(2, 2), Vector2(5, 5)), col)


# ---------------------------------------------------------------- Retro-Tech (kategorie z ikonami, karty produktów)
func _sklep() -> void:
	_bg(Color("e6ecf6"))
	var side := ColorRect.new()
	side.color = Color("2a4a8a")
	side.size = Vector2(108, body.size.y)
	body.add_child(side)
	for i in 3:
		var b := Button.new()
		b.icon = Game.tex("os/" + SHOP_ICONS[i])
		b.text = SHOP_SHORT[i]
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.position = Vector2(6, 6 + i * 82)
		b.size = Vector2(96, 76)
		b.focus_mode = Control.FOCUS_NONE
		var on := i == shop_cat
		b.add_theme_stylebox_override("normal", _box(Color("e6ecf6") if on else Color("3a5aa0"), Color("ffcf4a") if on else Color("1a2a5a"), 2 if on else 1))
		b.add_theme_stylebox_override("hover", _box(Color("f4f8ff") if on else Color("4a6ab8"), Color("ffcf4a"), 2))
		for st in ["normal", "hover"]:
			b.get_theme_stylebox(st).content_margin_top = 8
		b.add_theme_color_override("font_color", INK if on else Color.WHITE)
		b.add_theme_color_override("font_hover_color", INK if on else Color.WHITE)
		b.pressed.connect(func(): shop_cat = i; _rebuild())
		body.add_child(b)
	_label(body, "$ %d" % Game.money, Vector2(10, 296), Color("ffcf4a"))
	_label(body, Game.SHOP_PATHS[shop_cat], Vector2(116, 2), Color("1a3a8a"))
	_info(Rect2(116, 274, 518, 46), Color("2a3a5a"))
	var sc := ScrollContainer.new()
	sc.position = Vector2(114, 24)
	sc.size = Vector2(524, 246)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	sc.add_child(grid)
	for r in Game.SHOP:
		if r[4] != shop_cat:
			continue
		var st: String = Game.can_buy_shop(r)
		if st == "hidden":
			continue
		grid.add_child(_card(r, st))


func _card(r: Array, st: String) -> Button:
	var c := Button.new()
	c.custom_minimum_size = Vector2(168, 74)
	c.focus_mode = Control.FOCUS_NONE
	var bg: Color = {"owned": Color("d8f4d8"), "ok": Color("ffffff"), "cost": Color("f4f0e8"), "req": Color("d4d6de")}[st]
	c.add_theme_stylebox_override("normal", _box(bg, Color("6a6a80")))
	c.add_theme_stylebox_override("hover", _box(bg.lightened(0.3), Color("2a5ad8"), 2))
	c.add_theme_stylebox_override("pressed", _box(Color("c8d4f0"), Color("2a5ad8"), 2))
	var title := _label(c, r[1], Vector2(6, 2), INK if st != "req" else Color("6a6a7a"), 132)
	title.max_lines_visible = 2
	_label(c, "T%d" % r[3], Vector2(144, 2), Color("8a8aa0"))
	var price := _label(c, "$%d" % r[2], Vector2(6, 52), Color("2a7a3a") if st == "ok" else (Color("c83a2a") if st == "cost" else Color("6a6a7a")))
	var tag: String = {"owned": "W drodze" if (r[0] in Game.pending or r[0] in Game.parcels) else "Posiadane", "ok": "KUP", "cost": "Za mało $", "req": "Zablokowane"}[st]
	var l := _label(c, tag, Vector2(0, 52), Color("1a5ad0") if st == "ok" else Color("4a8a4a") if st == "owned" else Color("7a7a8a"))
	l.size.x = 160
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if st == "owned":
		price.text = ""
	c.mouse_entered.connect(func(): info.text = _desc(r, Game.can_buy_shop(r), true))
	c.pressed.connect(func():
		if Game.can_buy_shop(r) == "ok":
			Game.buy_shop(r)
			Game.ding(1.2)
			_rebuild()
		else:
			info.text = _desc(r, Game.can_buy_shop(r), true))
	return c


func _desc(r: Array, st: String, is_shop: bool) -> String:
	var cost := ("$%d" if is_shop else "%d PW") % r[2]
	var why: String = {"owned": "Posiadane." if not (r[0] in Game.pending or r[0] in Game.parcels) else "W drodze – kurier dostarczy przy zmianie pory dnia.",
		"ok": "Kliknij, aby kupić.", "cost": "Za mało środków.", "req": "Wymaga: " + _name_of(r[5]),
		"tier": "Tier %d odblokuje się po %s." % [r[3], "3 węzłach z Tier 1" if r[3] == 2 else "4 węzłach z Tier 2"]}.get(st, "")
	return "%s  [%s]  %s\n%s" % [r[1], cost, why, r[6]]


func _name_of(id: String) -> String:
	for r in Game.SCIENCE + Game.SHOP:
		if r[0] == id:
			return r[1]
	return id


# ---------------------------------------------------------------- Drzewko Badań (węzły połączone liniami, dymek z opisem)
func _badania() -> void:
	body.draw.connect(_draw_tree)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	body.gui_input.connect(_tree_input)
	var groups := {}
	for r in Game.SCIENCE:
		var k: Vector2i = Vector2i(r[4], r[3])
		groups[k] = groups.get(k, []) + [r]
	for k in groups:
		var g: Array = groups[k]
		for i in g.size():
			nodes.append([Vector2(110 + k.x * 210 + (i - (g.size() - 1) / 2.0) * 58, 30 + k.y * 78), g[i]])


func _node_at(p: Vector2) -> int:
	for i in nodes.size():
		if Rect2(nodes[i][0] - Vector2(17, 17), Vector2(34, 34)).has_point(p):
			return i
	return -1


func _tree_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = _node_at(e.position)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and hover >= 0:
		var r: Array = nodes[hover][1]
		if Game.can_buy_science(r) == "ok":
			Game.buy_science(r)
			Game.ding(1.5)
			bar.queue_redraw()


func _parent(r: Array) -> Vector2:
	if r[5] != "":
		for n in nodes:
			if n[1][0] == r[5]:
				return n[0]
	for n in nodes:  # pierwszy węzeł tej ścieżki z poprzedniego tieru, inaczej korzeń
		if n[1][4] == r[4] and n[1][3] == r[3] - 1:
			return n[0]
	return Vector2(320, 30)


func _draw_tree() -> void:
	var n := body
	n.draw_rect(Rect2(Vector2.ZERO, n.size), Color("1c2140"))
	for x in range(0, 640, 24):
		n.draw_rect(Rect2(x, 0, 1, 322), Color("232a4e"))
	for y in range(0, 322, 24):
		n.draw_rect(Rect2(0, y, 640, 1), Color("232a4e"))
	for nd in nodes:  # linie: łokcie jak w drzewkach umiejętności
		var a := _parent(nd[1])
		var b: Vector2 = nd[0]
		var lit: bool = Game.science.has(nd[1][0])
		var col := Color("e8ecf8") if lit else Color("4a5276")
		var w := 2.0 if lit else 1.0
		if is_equal_approx(a.y, b.y):
			n.draw_line(a, b, col, w)
		else:
			var my := a.y + 30
			n.draw_polyline(PackedVector2Array([a, Vector2(a.x, my), Vector2(b.x, my), b]), col, w)
	# korzeń: Poziom Wiedzy (punkty do wydania)
	var root := Rect2(240, 4, 160, 54)
	n.draw_rect(root, Color("ffcf4a"))
	n.draw_rect(root, INK, false, 2)
	n.draw_string(Game.font, root.position + Vector2(15, 22), "Poziom Wiedzy", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)  # 25 px: równe kreski VT323
	n.draw_string(Game.font, root.position + Vector2(0, 46), "%d PW" % Game.pw, HORIZONTAL_ALIGNMENT_CENTER, root.size.x, 25, INK)
	for p in 3:
		n.draw_string(Game.font, Vector2(10 + p * 210, 313), Game.SCIENCE_PATHS[p], HORIZONTAL_ALIGNMENT_CENTER, 200, Game.FS, PATH_COL[p])
	for i in nodes.size():
		var c: Vector2 = nodes[i][0]
		var r: Array = nodes[i][1]
		var st: String = Game.can_buy_science(r)
		var base: Color = PATH_COL[r[4]]
		var fill: Color = {"owned": base, "ok": base, "cost": Color("50566e"), "req": Color("50566e"), "tier": Color("50566e")}.get(st, Color("50566e"))
		var rect := Rect2(c - Vector2(15, 15), Vector2(30, 30))
		if i == hover:  # pod kursorem węzeł lekko się powiększa
			rect = rect.grow(3)
		n.draw_rect(rect.grow(2), INK)
		n.draw_rect(rect, fill)
		n.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), fill.lightened(0.35))
		n.draw_rect(Rect2(rect.position.x, rect.end.y - 3, rect.size.x, 3), fill.darkened(0.3))
		var glyph := Game.tex("os/" + GLYPHS[r[4]])
		n.draw_texture(glyph, (rect.get_center() - Vector2(7, 7)).floor(), Color(1, 1, 1, 1.0 if st in ["owned", "ok"] else 0.45))
		if st == "ok":  # dostępne: pulsujące białe obramowanie
			n.draw_rect(rect.grow(4), Color(1, 1, 1, 0.5 + 0.5 * sin(t * 6.0)), false, 2)
		n.draw_string(Game.font, Vector2(c.x - 20, c.y + 33), "%d/1" % int(st == "owned"), HORIZONTAL_ALIGNMENT_CENTER, 40, Game.FS, Color("ffcf4a") if st == "owned" else Color("8a90b0"))
		if st in ["req", "tier"]:  # kłódka
			n.draw_rect(Rect2(c + Vector2(6, 6), Vector2(9, 7)), Color("c8c8d8"))
			n.draw_arc(c + Vector2(10.5, 6), 3, PI, TAU, 6, Color("c8c8d8"), 1.5)
	if hover >= 0:
		_tooltip(n, nodes[hover][0], nodes[hover][1])


func _tooltip(n: Control, at: Vector2, r: Array) -> void:
	var st: String = Game.can_buy_science(r)
	var w := 230.0
	var p := at + Vector2(26, -20)
	if p.x + w > 636:
		p.x = at.x - 26 - w
	p.y = clampf(p.y, 4, 322 - 150)
	var body_text: String = r[6]
	var why: String = _desc(r, st, false).get_slice("\n", 0).get_slice("]  ", 1)
	n.draw_rect(Rect2(p, Vector2(w, 146)).grow(2), Color("e8ecf8"))
	n.draw_rect(Rect2(p, Vector2(w, 146)), Color("243a6a"))
	n.draw_rect(Rect2(p, Vector2(w, 44)), Color("2f4f8f"))
	n.draw_multiline_string(Game.font, p + Vector2(6, 16), r[1], HORIZONTAL_ALIGNMENT_CENTER, w - 12, Game.FS, 2, Color.WHITE)
	n.draw_string(Game.font, p + Vector2(0, 60), "LVL %d/1 · Tier %d" % [int(st == "owned"), r[3]], HORIZONTAL_ALIGNMENT_CENTER, w, Game.FS, Color("a8b8d8"))
	n.draw_multiline_string(Game.font, p + Vector2(8, 80), body_text, HORIZONTAL_ALIGNMENT_CENTER, w - 16, Game.FS, 2, Color.WHITE)
	n.draw_string(Game.font, p + Vector2(0, 118), "%d PW" % r[2], HORIZONTAL_ALIGNMENT_CENTER, w, Game.FS, Color("ffcf4a") if st != "cost" else Color("ff6a5a"))
	n.draw_string(Game.font, p + Vector2(0, 138), why, HORIZONTAL_ALIGNMENT_CENTER, w, Game.FS, Color("8ae8a0") if st == "ok" else Color("c8c8d8"))


# ---------------------------------------------------------------- POMOC.TXT (konsola)
func _pomoc() -> void:
	_bg(Color("1f4a34"))
	var v := _scroll(body, Rect2(10, 6, 624, 312))
	var l := _label(v, "AstroOS – Pomoc\n(c) Centrum Naukowe. Wszelkie prawa zastrzeżone.\n\n" + HELP + "\n\n> _", Vector2.ZERO, Color("f0e6c0"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(604, 0)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		if app != "":
			_close_app()
		else:
			close()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)


func close() -> void:
	closed.emit()
	queue_free()
