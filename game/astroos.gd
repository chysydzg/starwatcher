extends Control
## Komputer: AstroOS v1.0 (CRT, zieleń na czerni) / AstroOS XP (po zakupie LCD).
## Zakładki: Dziennik Odkryć, Giełda i Centrum, Retro-Tech Store, Drzewko Badań, POMOC.TXT (GDD 8).

signal closed
signal stage_complete

const HELP := """POMOC.TXT – AstroOS v1.0

NOC (balkon)
• Teleskop: najedź celownikiem na świecący obiekt (zacznie drżeć) i kliknij PPM.
• Kółkiem myszy kręć w przód i w tył – szukasz balansu. Obraz najpierw się wyostrza, potem znowu rozmywa. Gdy jest ostry, soczewka sama „kliknie”.
• Konstelacje: klikaj świecące gwiazdy po kolei, aż połączą się w figurę.
• Odkryte obiekty mają ✓. Zapis trafia na dysk – gdy się zapełni, kup dyskietki.
• Noc kończy się, gdy pasek czasu dobiegnie końca. Do łóżka trzeba dojść samemu.

DZIEŃ (komputer)
• Giełda: sprzedaj odkrycia Centrum Naukowemu. Ceny zależą od popytu dnia.
• Retro-Tech ($): sprzęt i komfort. Zakupy przychodzą kurierem.
• Drzewko Badań (PW): nowe obiekty na niebie i ułatwienia.
• Noc zaczniesz przyciskiem NOC w prawym górnym rogu.

CEL ETAPU: Manifest Naukowy (5000 PW) → Certyfikat Terenu ($5000) → min. 1 planeta → złoty przycisk INICJUJ."""

var hide_hud := true
var tab := 0
var xp := false
var body: Control
var detail: Label
var header: Label
var selected := {}
var uploading := false
var c_text := Color("7dffb0")
var c_dim := Color("3f8a5a")
var c_hi := Color("ffe080")


func _ready() -> void:
	size = Vector2(640, 360)
	xp = Game.has("lcd")
	if xp:
		c_text = Color("1a2a4a")
		c_dim = Color("6a7a9a")
		c_hi = Color("1a5ad0")
	theme = _make_theme()
	var bg := Panel.new()
	bg.size = size
	add_child(bg)
	var bar := ColorRect.new()
	bar.color = Color("2a5ad8") if xp else Color("10301c")
	bar.size = Vector2(640, 22)
	add_child(bar)
	header = Label.new()
	header.position = Vector2(6, 0)
	header.add_theme_color_override("font_color", Color.WHITE if xp else c_text)
	add_child(header)
	var x := Button.new()
	x.text = "X"
	x.position = Vector2(614, 0)
	x.focus_mode = Control.FOCUS_NONE
	x.pressed.connect(close)
	add_child(x)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(4, 24)
	tabs.add_theme_constant_override("separation", 2)
	add_child(tabs)
	for i in 5:
		var b := Button.new()
		b.text = ["Dziennik", "Giełda", "Retro-Tech", "Drzewko Badań", "POMOC.TXT"][i]
		b.pressed.connect(func(): tab = i; _rebuild())
		tabs.add_child(b)
	if Game.stage_ready():
		var g := Button.new()
		g.text = "★ INICJUJ ETAP 2"
		g.add_theme_color_override("font_color", Color("ffcf4a"))
		g.pressed.connect(func(): stage_complete.emit(); close())
		tabs.add_child(g)
	body = Control.new()
	body.position = Vector2(4, 52)
	body.size = Vector2(632, 238)
	add_child(body)
	var line := ColorRect.new()
	line.color = c_dim
	line.position = Vector2(4, 292)
	line.size = Vector2(632, 1)
	add_child(line)
	detail = Label.new()
	detail.position = Vector2(8, 294)
	detail.size = Vector2(624, 64)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(detail)
	Game.changed.connect(_header)
	_header()
	tab = 1 if not Game.night and not Game.stored().is_empty() else 0
	_rebuild()
	tabs.get_child(tab).grab_focus.call_deferred()
	if not Game.tips.has("astro"):
		Game.tips.astro = true
		tab = 4
		_rebuild()


func _make_theme() -> Theme:
	var th: Theme = Game.theme.duplicate()
	var flat := func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(1)
		s.set_content_margin_all(2)
		return s
	var base := Color("e8ecf4") if xp else Color("06100a")
	th.set_stylebox("panel", "Panel", flat.call(base, Color("6a8ac8") if xp else Color("1f5a32")))
	th.set_stylebox("normal", "Button", flat.call(Color("d8e0f0") if xp else Color("0c2014"), c_dim))
	th.set_stylebox("hover", "Button", flat.call(Color("f4f8ff") if xp else Color("163a24"), c_hi))
	th.set_stylebox("focus", "Button", flat.call(Color(0, 0, 0, 0), c_hi))
	th.set_stylebox("pressed", "Button", flat.call(Color("b8c8e8") if xp else Color("1f5a32"), c_hi))
	th.set_stylebox("disabled", "Button", flat.call(Color("d0d4dc") if xp else Color("08140c"), Color("a0a8b8") if xp else Color("16301e")))
	th.set_color("font_color", "Button", c_text)
	th.set_color("font_hover_color", "Button", c_hi)
	th.set_color("font_disabled_color", "Button", c_dim)
	th.set_color("font_color", "Label", c_text)
	th.set_color("font_color", "CheckBox", c_text)
	return th


func _header() -> void:
	header.text = "%s   ·   $ %d   ·   PW %d   ·   %s" % ["AstroOS XP" if xp else "AstroOS v1.0", Game.money, Game.pw, Game.calendar()]


func _clear() -> void:
	for c in body.get_children():
		c.queue_free()


func _label(parent: Node, text: String, col := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if col.a > 0:
		l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _scroll() -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size = body.size
	body.add_child(sc)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(620, 0)
	v.add_theme_constant_override("separation", 1)
	sc.add_child(v)
	return v


func _rebuild() -> void:
	_clear()
	detail.text = ""
	match tab:
		0: _journal()
		1: _market()
		2: _tree(Game.SHOP, Game.SHOP_PATHS, true)
		3: _tree(Game.SCIENCE, Game.SCIENCE_PATHS, false)
		4:
			var l := _label(_scroll(), HELP)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(600, 0)


# ---------------------------------------------------------------- 1. Dziennik Odkryć
func _journal() -> void:
	var v := _scroll()
	var zod := Game.discovered.keys().filter(func(k): return Game.SKY.has(k) and Game.SKY[k].cat == "zodiac").size()
	_label(v, "Pamięć %d/%d · Odkryte obiekty %d · Zodiak %d/12 · Sprzedane %d" % [
		Game.stored().size(), Game.storage_cap(), Game.discovered.size(), zod, Game.journal.size() - Game.stored().size()], c_hi)
	if Game.stored().is_empty():
		_label(v, "\nBrak nieprzesłanych odkryć. Wieczorem wyjdź na balkon do teleskopu.")
	for e in Game.stored():
		var p := Game.price(e)
		var b := Button.new()
		b.text = "%-28s %-14s %3d%%  ~$%-5d dz.%d" % [e.name.left(28), Game.CATS[e.cat], e.quality, p.total, e.day]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): detail.text = _breakdown(e))
		b.focus_entered.connect(func(): detail.text = _breakdown(e))
		v.add_child(b)


func _breakdown(e: Dictionary) -> String:
	var p := Game.price(e)
	return "%s – gotowe do wysyłki.\nBazowa $%d × jakość %d%% × popyt ×%.2f × (1+bonusy %d%%) × instytut ×%.1f = $%d" % [
		e.name, p.base, p.quality, p.demand, int(p.bonus * 100), p.inst, p.total]


# ---------------------------------------------------------------- 2. Giełda i Centrum Naukowe
func _market() -> void:
	var v := _scroll()
	var trend := "Trendy dnia: "
	for c in Game.CATS:
		var m: float = Game.demand.get(c, 1.0)
		if m != 1.0:
			trend += "%s %s×%.2f   " % [Game.CATS[c], "▲" if m > 1 else "▼", m]
	_label(v, trend, c_hi)
	if Game.night:
		_label(v, "\nCentrum Naukowe zamknięte do rana. Odkrycia czekają bezpiecznie na dysku.")
		return
	var stored := Game.stored()
	if stored.is_empty():
		_label(v, "\nNie ma nic do wysłania.")
		return
	var row := HBoxContainer.new()
	v.add_child(row)
	var all := Button.new()
	all.text = "Zaznacz wszystkie"
	row.add_child(all)
	var send := Button.new()
	row.add_child(send)
	var checks := []
	var update := func():
		var sum := 0
		var n := 0
		for e in stored:
			if selected.get(e.uid, false):
				sum += Game.price(e).total
				n += 1
		send.text = "Wyślij Raport (%d) → Centrum Naukowe  +$%d" % [n, sum]
		send.disabled = n == 0 or uploading
	all.pressed.connect(func():
		for i in stored.size():
			selected[stored[i].uid] = true
			checks[i].button_pressed = true
		update.call())
	for e in stored:
		var cb := CheckBox.new()
		var txt := "%-28s jakość %3d%%   $%d" % [e.name.left(28), e.quality, Game.price(e).total]
		cb.button_pressed = selected.get(e.uid, false)
		cb.text = ("[x] " if cb.button_pressed else "[ ] ") + txt
		cb.toggled.connect(func(on): selected[e.uid] = on; cb.text = ("[x] " if on else "[ ] ") + txt; update.call(); detail.text = _breakdown(e))
		v.add_child(cb)
		checks.append(cb)
	send.pressed.connect(func(): _upload(stored.filter(func(e): return selected.get(e.uid, false))))
	update.call()


func _upload(list: Array) -> void:
	uploading = true
	var dur := 0.0 if Game.has("isdn") else 4.0 * (0.6 if Game.has("modem") else 1.0)
	var bar := ProgressBar.new()
	bar.position = Vector2(150, 140)
	bar.size = Vector2(340, 14)
	bar.show_percentage = false
	body.add_child(bar)
	var l := _label(body, "Łączenie z Centrum Naukowym... ATDT 0-700-ASTRO", c_hi)
	l.position = Vector2(150, 122)
	var tw := create_tween()
	tw.tween_method(func(x): bar.value = x; detail.text = "Przesłano %d B / %d B" % [int(x * 14.4), 1440], 0.0, 100.0, dur)
	tw.tween_callback(func():
		var sum := Game.sell(list)
		uploading = false
		selected.clear()
		Game.toast.emit("Raport przyjęty! +$%d" % sum, "good")
		_rebuild()
		detail.text = "Sukces: Centrum Naukowe przelało $%d." % sum)


# ---------------------------------------------------------------- 3/4. Drzewka (sklep $ i badania PW)
func _tree(rows: Array, paths: Array, is_shop: bool) -> void:
	var sc := ScrollContainer.new()
	sc.size = body.size
	body.add_child(sc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	sc.add_child(h)
	for pi in 3:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(206, 0)
		col.add_theme_constant_override("separation", 1)
		h.add_child(col)
		_label(col, paths[pi], c_hi)
		var last_tier := 0
		for r in rows:
			if r[4] != pi:
				continue
			var st: String = Game.can_buy_shop(r) if is_shop else Game.can_buy_science(r)
			if st == "hidden":
				continue
			if r[3] != last_tier:
				last_tier = r[3]
				_label(col, "TIER %d" % r[3], c_dim)
			var b := Button.new()
			b.custom_minimum_size = Vector2(206, 0)
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var mark: String = {"owned": "✓ ", "ok": "• ", "cost": "  ", "req": "  ", "tier": "  "}[st]
			b.text = mark + r[1]
			if st == "owned":
				b.add_theme_color_override("font_color", c_dim)
			if r[0] in ["manifest", "certyfikat"]:
				b.add_theme_color_override("font_color", Color("ffcf4a") if not xp else Color("b07800"))
			var info := func(): detail.text = _desc(r, st, is_shop)
			b.focus_entered.connect(info)
			b.mouse_entered.connect(info)
			b.pressed.connect(func():
				var now: String = Game.can_buy_shop(r) if is_shop else Game.can_buy_science(r)
				if now == "ok":
					if is_shop:
						Game.buy_shop(r)
					else:
						Game.buy_science(r)
					_rebuild()
				else:
					detail.text = _desc(r, now, is_shop))
			col.add_child(b)


func _desc(r: Array, st: String, is_shop: bool) -> String:
	var cost := ("$%d" if is_shop else "%d PW") % r[2]
	var why: String = {"owned": "Posiadane." if not (r[0] in Game.pending or r[0] in Game.parcels) else "W drodze – kurier dostarczy przy zmianie pory dnia.",
		"ok": "Kliknij, aby kupić.", "cost": "Za mało środków.", "req": "Wymaga: " + _name_of(r[5]),
		"tier": "Tier %d odblokuje się po %s." % [r[3], "3 węzłach z Tier 1" if r[3] == 2 else "4 węzłach z Tier 2"]}[st]
	return "%s   [%s]\n%s   %s" % [r[1], cost, r[6], why]


func _name_of(id: String) -> String:
	for r in Game.SCIENCE + Game.SHOP:
		if r[0] == id:
			return r[1]
	return id


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("back"):
		close()
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and e.keycode >= KEY_1 and e.keycode <= KEY_5:
		tab = e.keycode - KEY_1
		_rebuild()


func close() -> void:
	if uploading:
		return
	closed.emit()
	queue_free()
