extends CanvasLayer
## Samouczek: okienko na kilka stron (mało tekstu + nagranie z gry), pokazywane raz (Game.tips),
## potem do otwarcia w POMOC.TXT na komputerze. Gra stoi w pauzie, dopóki gracz nie kliknie OK.

const TUTORIALS := {
	"tel": {"title": "Teleskop", "pages": [
		{"img": "tut/tel1", "text": "Odkrywaj obiekty na niebie, żeby zdobywać PW i $. Zbliż celownik do obiektu, a gdy zacznie drgać, wciśnij {confirm}."},
		{"img": "tut/tel2", "text": "Wyostrz obiekt, a dostaniesz za niego więcej $. {focus}, aż znacznik trafi w zielone pole, i wciśnij {confirm}."},
		{"img": "tut/tel3", "text": "Niektóre obiekty, np. konstelacje, trzeba odsłonić. Zaznacz po kolei jasno świecące gwiazdy {confirm}."},
		{"img": "tut/tel_hard", "text": "Na początku gry odkrywanie gwiazd będzie trudne, lecz z czasem nauczysz się umiejętności, które to ułatwią."},
	]},
	"pc": {"title": "Komputer", "pages": [
		{"img": "tut/pc_walk", "text": "Aby sprzedawać odkrycia i zdobywać nowe umiejętności, podejdź do komputera i wciśnij {interact}."},
		{"img": "tut/pc_desk", "text": "Wybierz Giełdę, żeby sprzedać odkrycia."},
		{"img": "tut/pc_chart", "text": "Zaznacz kategorię, a wykres pokaże, co opłaca się dziś sprzedać. Masz ograniczoną przestrzeń na dysku, więc dobrze zaplanuj sprzedaż swoich obiektów."},
		{"img": "tut/pc_sell", "text": "Zaznacz odkrycia pojedynczo lub przyciskiem Zaznacz wszystkie, potem wyślij raport. Pieniądze z Giełdy przychodzą codziennie rano."},
		{"img": "tut/pc_tree", "text": "Punkty wiedzy wydajesz w Badaniach. Wybierz podświetloną umiejętność i wciśnij {confirm}."},
	]},
	"shop": {"title": "Sklep", "pages": [
		{"img": "tut/shop_desk", "text": "W Retro-Tech kupisz sprzęt, który ułatwia obserwacje. Wybierz go na pulpicie."},
		{"img": "tut/shop_buy", "text": "Kliknij KUP przy przedmiocie."},
		{"img": "tut/shop_parcel", "text": "Gdy wyłączysz komputer, kurier zapuka i zostawi paczkę. Podejdź do niej i wciśnij {interact}, żeby ją otworzyć."},
	]},
	"widmo": {"title": "Analiza widmowa", "pages": [
		{"img": "tut/spec_bar", "text": "Po wyostrzeniu planety, mgławicy, galaktyki albo czarnej dziury pojawia się widmo. Ciemne kreski to linie absorpcyjne."},
		{"img": "tut/spec_hold", "text": "Celownikiem w poziomie przesuwasz wzorzec (białe znaczniki). Trzymaj go na liniach, aż zielony pasek się zapełni. Linie dryfują!"},
		{"img": "tut/spec_done", "text": "Udana analiza: odkrycie warte więcej $ i PW. Gdy czas minie albo wciśniesz {leave}, zapis idzie bez widma."},
	]},
	"edycja": {"title": "Twój pokój", "pages": [
		{"img": "tut/edit_tab", "text": "Pokój możesz urządzić po swojemu. Wciśnij {edit}, żeby przejść w tryb edycji."},
		{"img": "tut/edit_move", "text": "Kliknij mebel, żeby go podnieść, i kliknij jeszcze raz w nowym miejscu. Czerwony znaczy, że tam się nie zmieści."},
		{"img": "tut/edit_flip", "text": "{prev_next} obraca mebel. Nowe ozdoby kupisz w sklepie, w dziale Pokój."},
	]},
	"hr": {"title": "Zespół", "pages": [
		{"img": "tut/hr_open", "text": "Józek to Twój pierwszy pracownik. Zespołem zarządzasz w komputerze, w zakładce HR i Zespół."},
		{"img": "tut/hr_table", "text": "Koszt to pensja płacona co rano. Zysk to to, co pracownik daje w swoim trybie. Na dole widać bilans całego zespołu."},
		{"img": "tut/hr_mode", "text": "Najedź na cechę, żeby zobaczyć jej opis. Kliknij tryb, żeby przenieść pracownika do innej pracy."},
		{"img": "tut/hr_hire", "text": "Kandydaci zmieniają się codziennie. Zatrudnienie jest darmowe, ale każdy potrzebuje stanowiska ze sklepu (Biuro)."},
	]},
	"dlug": {"title": "Konto na minusie", "pages": [
		{"img": "tut/dlug_hud", "text": "Pensje zespołu schodzą codziennie rano. Gdy zabraknie pieniędzy, konto spada poniżej zera, a kwota robi się czerwona."},
		{"img": "tut/dlug_strike", "text": "Po 3 dniach bez wypłaty pracownicy przestają pracować (czerwone $? nad głową), po 6 dniach odchodzą. Sprzedaj odkrycia na Giełdzie, żeby wyjść na plus."},
	]},
	"meteor": {"title": "Meteory", "pages": [
		{"img": "tut/meteor1", "text": "Gdy przelatuje meteor, okular drży. Najedź na niego celownikiem i wciśnij {confirm}, zanim zniknie."},
		{"img": "tut/meteor2", "text": "Łączysz gwiazdy? {leave} wychodzi z konstelacji, a ona zostaje tak, jak ją zostawisz. Złap meteor i wróć do niej."},
	]},
}
const FW := 320  # klatka nagrania 320x180, klatki obok siebie w jednym PNG
const FH := 180

var id := ""
var page := 0
var _was_paused := false
var _f := 0
var _title: Label
var _text: Label
var _pic := AtlasTexture.new()
var _back: Button
var _next: Button


func setup(tut_id: String) -> CanvasLayer:
	id = tut_id
	return self


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.1, 0.75)
	Game.cover(dim)
	add_child(dim)
	var p := Panel.new()
	p.position = Vector2(140, 8) + Game.margin  # dim zaczyna się w -margin
	p.size = Vector2(360, 344)  # tekst do 4 linii
	dim.add_child(p)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_override("font", Game.font_title)
	_title.add_theme_font_size_override("font_size", Game.TITLE_FS)
	_title.add_theme_color_override("font_color", Color("ffcf6b"))
	p.add_child(_title)
	var border := ColorRect.new()
	border.color = Color("0a0a16")
	border.position = Vector2(19, 31)
	border.size = Vector2(FW + 2, FH + 2)
	p.add_child(border)
	var pic := TextureRect.new()
	pic.texture = _pic
	pic.position = Vector2(20, 32)
	pic.size = Vector2(FW, FH)
	p.add_child(pic)
	_text = Label.new()
	_text.position = Vector2(20, 220)
	_text.custom_minimum_size = Vector2(FW, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(_text)
	_back = _button(p, "WSTECZ", Vector2(20, 306), func(): _turn(-1))
	_next = _button(p, "DALEJ", Vector2(240, 306), func(): _turn(1))
	create_tween().set_loops().tween_callback(_tick).set_delay(0.12)
	_show()


func _button(p: Control, txt: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.custom_minimum_size = Vector2(100, 26)
	b.pressed.connect(cb)
	p.add_child(b)
	return b


func _pages() -> Array:
	return TUTORIALS[id].pages


func _show() -> void:
	var pg: Dictionary = _pages()[page]
	_title.text = "%s  %d/%d" % [TUTORIALS[id].title.to_upper(), page + 1, _pages().size()]
	_text.text = pg.text.replace("{confirm}", Game.key("confirm")).replace("{interact}", Game.key("interact")).replace("{leave}", Game.key("leave")).replace("{edit}", Game.key("edit")).replace("{prev_next}", Game.key("prev_next")).replace("{focus}", "Wychylaj prawy drążek" if Game.pad else "Kręć kółkiem myszy")
	_pic.atlas = Game.tex(pg.img)
	_f = 0
	_tick()
	_back.visible = page > 0
	_next.text = "OK" if page == _pages().size() - 1 else "DALEJ"
	_next.grab_focus.call_deferred()


func _tick() -> void:
	var n := maxi(1, floori(_pic.atlas.get_width() / float(FW)))
	_pic.region = Rect2(mini(_f, n - 1) * FW, 0, FW, FH)  # ostatnia klatka trzyma się chwilę, potem od nowa
	_f = (_f + 1) % (n + 10)


func _turn(d: int) -> void:
	if page + d >= _pages().size():
		Game.sfx("click")
		get_tree().paused = _was_paused
		queue_free()
		return
	page = clampi(page + d, 0, _pages().size() - 1)
	Game.sfx("paper", 1.0, -8.0)
	_show()
