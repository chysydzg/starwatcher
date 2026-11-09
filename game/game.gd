extends Node
## Star Watcher – stan gry, dane Etapu 1 (z GDD v2.0), ekonomia, zapis, sterowanie.
## Autoload „Game”. Wszystkie liczby balansu są w stałych poniżej (GDD rozdz. 5, 11, 25).

signal changed            # pieniądze / PW / stan – odśwież HUD
signal toast(text: String, kind: String)

var SAVE := "user://savegame.json"
var SAVE_BAK := "user://savegame.bak.json"
const ART := "res://game/art/"
const FS := 16               # Pixel Operator (UI): siatka 100/1600 em – przy 16 px piksel czcionki = piksel ekranu
const OS_FS := 20            # VT323 w komputerze (AstroOS)
const TITLE_FS := 8          # Press Start 2P na nagłówki: siatka 125/1000 em – rozmiary 8, 16, 24

# ---------------------------------------------------------------- balans (GDD 25)
const NIGHT_BASE := 60.0   # jedna minuta: krótka, gęsta noc
const METEOR_INTERVAL := Vector2(40, 60)
const METEOR_WINDOW := 3.5
const RAIN_CHANCE := 0.20
const STORM_CHANCE := 0.35  # część deszczowych nocy to burza z piorunami
const COMET_NIGHTS := 3
const COMET_GAP := 8
const SEASONS := ["Wiosna", "Lato", "Jesień", "Zima"]
const WEEKDAYS := ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"]  # dzień 1 = poniedziałek
const CATS := {"moon": "Księżyc", "const": "Konstelacje", "zodiac": "Znaki zodiaku", "nebula": "Mgławice",
	"planet": "Planety", "deep": "Głębokie niebo", "comet": "Komety", "meteor": "Meteory"}
const MARKET_CATS := ["moon", "const", "zodiac", "nebula", "planet", "deep", "comet"]  # meteory: stała cena, bez notowań
const MOON_PHASES := ["Nów", "Przybywający sierp", "Pierwsza kwadra", "Przybywający garb", "Pełnia",
	"Ubywający garb", "Ostatnia kwadra", "Ubywający sierp"]

# ---------------------------------------------------------------- niebo Etapu 1 (GDD 5 i 11)
# kształty konstelacji: punkty (px nieba) + krawędzie; gracz klika punkty w kolejności [1]→[2]→…
var SKY := {  # uzupełniane w _ready() pulą gwiazdozbiorów z CONSTELLATIONS
	"wielki_woz": {"name": "Wielki Wóz", "cat": "const", "req": "", "pts": [[0, 6], [12, 3], [23, 7], [33, 12], [35, 25], [51, 28], [54, 14]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]], "bonus": 8, "price": 22},
	"pas_oriona": {"name": "Pas Oriona", "cat": "const", "req": "", "pts": [[0, 12], [13, 7], [26, 1]], "edges": [[0, 1], [1, 2]], "bonus": 8, "price": 18},
	"kasjopeja": {"name": "Kasjopeja", "cat": "const", "req": "", "pts": [[0, 2], [10, 15], [21, 6], [32, 17], [43, 3]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4]], "bonus": 8, "price": 25},
	"trojkat": {"name": "Trójkąt Letni", "cat": "const", "req": "podstawowe", "pts": [[0, 22], [24, 0], [36, 28]], "edges": [[0, 1], [1, 2], [2, 0]], "bonus": 8, "price": 16},
	"maly_woz": {"name": "Mały Wóz", "cat": "const", "req": "podstawowe", "pts": [[0, 0], [9, 6], [16, 11], [25, 13], [27, 24], [40, 26], [40, 14]], "edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]], "bonus": 8, "price": 26},
	"strzala": {"name": "Strzała", "cat": "const", "req": "", "pts": [[0, 12], [11, 9], [22, 5], [29, 0]], "edges": [[0, 1], [1, 2], [2, 3]], "bonus": 8, "price": 15},
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

# pula gwiazdozbiorów nieba północnego (kształty uproszczone): [id, nazwa, wymaganie albo pora roku zodiaku,
# „x,y x,y …”, łańcuchy krawędzi „0-1-2 2-3”]. Co noc losuje się kilka – najpierw te jeszcze nieodkryte.
const CONSTELLATIONS := [
	["korona", "Korona Północna", "", "0,10 6,3 14,0 22,1 29,5 33,12", "0-1-2-3-4-5"],
	["lutnia", "Lutnia", "", "8,0 4,10 14,9 2,22 12,22", "0-1-2-0 1-3-4-2"],
	["delfin", "Delfin", "", "0,6 6,0 12,5 6,11 4,22", "0-1-2-3-0 3-4"],
	["trojkat_gw", "Trójkąt", "", "0,14 22,0 26,8", "0-1-2-0"],
	["orion", "Orion", "podstawowe", "13,0 0,8 26,10 8,26 13,27 18,28 4,46 28,44", "0-1-3-4-5-2-0 3-6 5-7"],
	["cefeusz", "Cefeusz", "podstawowe", "0,30 0,14 10,0 20,14 20,30", "0-1-2-3-4-0 1-3"],
	["smok", "Smok", "podstawowe", "40,0 48,4 46,12 38,8 30,16 22,22 14,18 8,26 0,34", "0-1-2-3-0 3-4-5-6-7-8"],
	["andromeda", "Andromeda", "podstawowe", "0,20 12,14 24,8 36,0 16,26", "0-1-2-3 1-4"],
	["pegaz", "Pegaz", "podstawowe", "0,0 24,0 24,22 0,22 36,30 44,26", "0-1-2-3-0 2-4-5"],
	["woznica", "Woźnica", "podstawowe", "12,0 24,8 22,22 4,24 0,10", "0-1-2-3-4-0"],
	["wolarz", "Wolarz", "podstawowe", "12,0 4,10 20,12 8,24 18,26 14,38", "0-1-3-5-4-2-0"],
	["herkules", "Herkules", "podstawowe", "6,10 20,8 22,20 8,22 34,2 34,30 0,0 0,34", "0-1-2-3-0 1-4 2-5 0-6 3-7"],
	["orzel", "Orzeł", "podstawowe", "0,0 8,8 14,12 20,16 28,24 20,30 6,20", "0-1-2-3-4 2-5 2-6"],
	["wezownik", "Wężownik", "podstawowe", "10,0 0,14 2,32 20,34 22,14", "0-1-2-3-4-0"],
	["wielki_pies", "Wielki Pies", "podstawowe", "10,0 12,8 4,16 16,22 24,30 8,32", "0-1-2 1-3-4 3-5"],
	["maly_pies", "Mały Pies", "podstawowe", "0,10 14,4 18,0", "0-1-2"],
	["zajac", "Zając", "podstawowe", "0,0 12,6 24,4 10,18 24,20", "0-1-2-4-3-1"],
	["jednorozec", "Jednorożec", "podstawowe", "0,20 10,14 20,10 30,0 22,22", "0-1-2-3 2-4"],
	["rys", "Ryś", "podstawowe", "0,30 8,22 14,16 22,12 30,6 40,0", "0-1-2-3-4-5"],
	["zyrafa", "Żyrafa", "podstawowe", "0,30 6,18 10,8 20,0 16,20", "0-1-2-3 1-4"],
	["lisek", "Lisek", "podstawowe", "0,8 12,4 24,0", "0-1-2"],
	["jaszczurka", "Jaszczurka", "podstawowe", "0,0 8,6 4,12 12,18 6,26 14,32", "0-1-2-3-4-5"],
	["zrebie", "Źrebię", "podstawowe", "0,0 10,2 12,10 2,8", "0-1-2-3-0"],
	["warkocz", "Warkocz Bereniki", "podstawowe", "0,0 14,2 14,18", "0-1-2"],
	["psy_gonczy", "Psy Gończe", "podstawowe", "0,0 14,8 22,14", "0-1-2"],
	["maly_lew", "Mały Lew", "podstawowe", "0,10 12,4 20,8", "0-1-2"],
	["kruk", "Kruk", "podstawowe", "0,4 18,0 20,16 4,18", "0-1-2-3-0"],
	["puchar", "Puchar", "podstawowe", "0,0 16,0 14,12 2,12 8,20", "0-3-4-2-1"],
	["hydra", "Hydra", "podstawowe", "0,4 6,0 10,6 4,8 16,14 26,18 34,26 44,28 52,36", "0-1-2-3-0 2-4-5-6-7-8"],
	["wieloryb", "Wieloryb", "podstawowe", "36,0 44,4 42,12 34,10 26,16 14,14 4,20 0,30 12,32 18,24", "0-1-2-3-0 3-4-5-6-7-8-9-5"],
	["erydan", "Erydan", "podstawowe", "0,0 10,6 6,14 16,20 12,30 24,34", "0-1-2-3-4-5"],
	["tarcza", "Tarcza", "podstawowe", "0,0 10,2 12,12 2,14", "0-1-2-3-0"],
	["waz", "Wąż", "podstawowe", "0,30 6,20 10,12 18,8 22,0 28,4", "0-1-2-3-4-5"],
	["sekstant", "Sekstant", "podstawowe", "0,0 12,10 2,16", "0-1-2"],
	["ryby_pd", "Ryba Południowa", "podstawowe", "0,6 10,0 22,2 30,8 20,12", "0-1-2-3-4-0"],
	["golebica", "Gołębica", "podstawowe", "0,4 10,0 20,6 26,14", "0-1-2-3"],
	# zodiak: liczba = pora roku (0 wiosna, 1 lato, 2 jesień, 3 zima); co noc tylko jeden znak
	["koziorozec", "Koziorożec", 2, "0,0 10,18 24,24 40,18 44,4 22,8", "0-1-2-3-4-5-0"],
	["wodnik", "Wodnik", 2, "0,0 10,6 22,4 26,14 18,24 30,30", "0-1-2-3-4 3-5"],
	["ryby", "Ryby", 2, "0,0 10,12 20,24 34,20 48,16 54,10 50,4 44,10", "0-1-2-3-4-5-6-7-4"],
	["baran", "Baran", 3, "0,10 14,4 24,0 28,4", "0-1-2-3"],
	["byk", "Byk", 3, "0,0 10,10 16,16 22,12 34,4 18,26", "0-1-2-3-4 2-5"],
	["bliznieta", "Bliźnięta", 3, "0,0 4,14 8,30 14,0 18,14 22,30", "0-1-2 3-4-5 0-3"],
]

func _build_sky() -> void:
	for c in CONSTELLATIONS:
		var pts := []
		for p in c[3].split(" "):
			pts.append([int(p.get_slice(",", 0)), int(p.get_slice(",", 1))])
		var edges := []
		for chain in c[4].split(" "):
			var ids: Array = Array(chain.split("-")).map(func(v): return int(v))
			for i in ids.size() - 1:
				edges.append([ids[i], ids[i + 1]])
		var zod: bool = c[2] is int
		var o := {"name": c[1], "cat": "zodiac" if zod else "const", "req": "podstawowe" if zod else c[2], "pts": pts, "edges": edges,
			"bonus": 20 if zod else 8, "price": (40 if zod else 12) + pts.size() * (2 if zod else 3)}
		if zod:
			o.season = c[2]
		SKY[c[0]] = o


# ---------------------------------------------------------------- drzewko naukowe PW (GDD 11)
const SCIENCE := [
	["stab1", "Stabilizacja Obrazu I", 10, 1, 0, "", "Znacznik ostrości buja się o 25% słabiej."],
	["stab2", "Stabilizacja Obrazu II", 25, 1, 0, "stab1", "Bujanie słabsze o kolejne 25%."],
	["kursor1", "Precyzyjny Kursor I", 40, 1, 0, "", "Przyciąganie celownika do gwiazd +20%."],
	["nawyk1", "Nawyk Notowania I", 15, 1, 1, "", "+1 PW za każdy zaznaczony punkt."],
	["nawyk2", "Nawyk Notowania II", 35, 1, 1, "nawyk1", "+2 PW za punkt (łącznie +3)."],
	["kawa", "Nocna Kawa", 50, 1, 1, "", "Celownik porusza się o 20% szybciej."],
	["podstawowe", "Podstawowe Gwiazdozbiory", 20, 1, 2, "", "Proste układy 3-4 gwiazd i znaki zodiaku pory roku."],
	["meteory", "Szybkie Spadające Gwiazdy", 60, 1, 2, "podstawowe", "Na niebie przelatują meteory: +25 PW."],
	["mikro", "Pokrętło Mikro-Ruchów", 180, 2, 0, "", "Usuwa drgania celownika."],
	["czyste1", "Czyste Soczewki I", 120, 2, 0, "", "Zielone pole ostrości szersze o 30%."],
	["czyste2", "Czyste Soczewki II", 220, 2, 0, "czyste1", "Zielone pole szersze o kolejne 30%."],
	["pamiec1", "Pamięć Fotograficzna I", 120, 2, 1, "", "+10% PW ze wszystkich źródeł."],
	["pamiec2", "Pamięć Fotograficzna II", 250, 2, 1, "pamiec1", "Kolejne +15% PW."],
	["instytuty", "Oferty Instytutów", 200, 2, 1, "", "Każdego ranka 30% szans, że instytut zechce kupić jedno odkrycie za 150% ceny."],
	["encyklopedia", "Encyklopedia Astronomiczna", 300, 2, 1, "", "+0,5 PW/s nocy za każdy odkryty obiekt (maks. 20)."],
	["obloki", "Głębokie Obłoki Gazu", 150, 2, 2, "podstawowe", "Mgławice i pył kosmiczny (2x PW)."],
	["kometa", "Kometa Okresowa", 280, 2, 2, "", "Kometa widoczna przez 3 noce: +150 PW."],
	["planety", "Sąsiednie Planety", 450, 2, 2, "obloki", "Mars, Wenus, Jowisz – co noc gdzie indziej."],
	["samoistne", "Samoistne Łączenie Gwiazd", 600, 3, 0, "", "Jedno kliknięcie łączy całą figurę."],
	["szukacz", "Automatyczne Wyszukiwanie", 450, 3, 0, "", "Q/E przeskakuje między obiektami na niebie."],
	["auto1", "Autofokus DIY I", 500, 3, 0, "", "Wyostrza sam po 1 s bez kręcenia."],
	["auto2", "Autofokus DIY II", 850, 3, 0, "auto1", "Autofokus natychmiast."],
	["wzor", "Wzór Empiryczny", 700, 3, 1, "", "+1 PW za każdy zarobiony $."],
	["notatki", "Udostępnianie Notatek", 1000, 3, 1, "", "+50% wszystkich PW."],
	["kolekcjonerzy", "Oferty Kolekcjonerów", 600, 3, 1, "instytuty", "Każdego ranka 20% szans na kolekcjonera, który płaci 250% ceny za jedno odkrycie."],
	["gleb_pole", "Głębokie Pole Obserwacji", 900, 3, 2, "", "Gwiazdy podwójne i odległe galaktyki."],
	["manifest", "Manifest Naukowy „Nasze Miejsce w Kosmosie”", 5000, 3, 2, "planety", "Pozwala kupić działkę pod własne Centrum Naukowe."],
]
const SCIENCE_PATHS := ["Skanowanie i Optyka", "Analiza i Metodologia", "Kartografia i Kosmos"]

# ---------------------------------------------------------------- sklep Retro-Tech & Astro (GDD 11)
const SHOP := [
	["statyw", "Używany Statyw Drewniany", 20, 1, 0, "", "Drgania celownika -40%."],
	["czyszczacy", "Zestaw Czyszczący Optykę", 45, 1, 0, "", "Czyści brudną soczewkę: wyraźny obraz i szersze pole ostrości."],
	["modem", "Modem Dial-Up 56k", 30, 1, 1, "", "Wartość odkryć +10%."],
	["dd", "Paczka Dyskietek 3.5\" DD", 30, 1, 1, "", "+5 slotów (10)."],
	["hd", "Paczka Dyskietek 3.5\" HD", 75, 1, 1, "dd", "+10 slotów (20)."],
	["achromat", "Szklana Soczewka Achromatyczna", 150, 2, 0, "czyszczacy", "Naprawia pękniętą szybkę. Wartość +20%."],
	["montaz", "Ręczny Montaż Paralaktyczny", 280, 2, 0, "statyw", "Płynniej, przyciąganie +35%."],
	["pudelko", "Plastikowe Pudełko na Dyskietki", 120, 2, 1, "hd", "+10 slotów (30)."],
	["vga", "Karta Graficzna VGA", 200, 2, 1, "modem", "Wartość sprzedaży +20%."],
	["astrotax", "Program „Astro-Tax 1.0”", 350, 2, 1, "dd", "+15% $ za sprzedany układ."],
	["lcd", "Monitor LCD 19\" + Nowy Komputer", 600, 2, 1, "", "AstroOS XP. Wartość +25%."],
	["parasol", "Parasol Balkonowy", 450, 2, 2, "", "Osłania teleskop: deszcz nie zalewa soczewki."],
	["plakat", "Plakat „I Want to Believe”", 150, 2, 2, "", "Komety i meteory +25% częściej."],
	["materac", "Ergonomiczny Materac", 250, 2, 2, "", "+50 PW na start każdej nocy."],
	["newton", "Teleskop Zwierciadlany Newtona", 750, 3, 0, "", "+10 obiektów na niebie, pole widzenia +30%, cena +50%."],
	["naped", "Napęd Elektryczny do Montażu", 1200, 3, 0, "montaz", "Teleskop sam podąża za wykrytym obiektem i trzyma go w kadrze."],
	["usb", "Zewnętrzna Stacja Dyskietek USB", 50, 3, 1, "lcd", "Dyskietki działają z nowym komputerem."],
	["hdd", "Zewnętrzny Dysk HDD 5400 RPM", 300, 3, 1, "lcd", "+50 slotów."],
	["ide", "Dysk HDD w Macierzy IDE", 650, 3, 1, "hdd", "+100 slotów, +5% za serie."],
	["isdn", "Szerokopasmowe Łącze ISDN", 1000, 3, 1, "vga", "Raport wypłacany od razu, bez czekania do rana."],
	["licencja", "Licencja Niezależnego Badacza", 1200, 3, 1, "astrotax", "Zagraniczne instytuty: x2 za rzadkie układy i planety."],
	["radio", "Radio Lampowe z Muzyką Jazzową", 600, 3, 2, "", "+10% szybkości akcji w minigrach."],
	["certyfikat", "Certyfikat Terenu pod Bazy Kosmiczne", 5000, 3, 2, "manifest", "Działka nad jeziorem – tu powstanie Twoje Centrum Naukowe (Etap 2)."],
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
var parcels := []          # dostarczone, czekają na rozpakowanie
var journal := []          # wpisy Dziennika: wszystkie odkrycia (w pamięci, sprzedane, nadpisane) – historia na stronach
var history := []          # podsumowania minionych dni (to, co pokazało okienko PODSUMOWANIE)
var discovered := {}       # id obiektu -> true (Encyklopedia, „zbadane” na niebie)
var moon_done := {}        # faza -> true
var tonight := {}          # obiekty zapisane tej nocy
var demand := {}           # kategoria -> mnożnik popytu dnia
var demand_log := []       # popyt z ostatnich dni (wykres Giełdy)
var sky_tonight := []      # wylosowane obiekty tej nocy
var analysis := {"uids": [], "left": 0.0}  # raport poranny: odkrycia wysłane do Centrum, wypłata rano (po śnie)
var offer := {}            # okazyjna oferta instytutu / kolekcjonera na jedno odkrycie (ważna do końca dnia)
var today := {}            # podsumowanie dnia
var rain := false
var rain_next := false
var storm := false          # burza: ulewa, pioruny, gęste chmury
var storm_next := false
var lightning := 0.0        # jasność błysku pioruna (burza), 0..1
var arriving := false       # kupiona paczka: kurier zapuka, gdy Jania odejdzie od komputera
var comet := {"left": 0, "gap": 0, "seed": 0}
var tips := {}
var location := "balcony"
var stage_done := false
var settings := {"fullscreen": false, "crt": true, "vol": {"Music": 8, "SFX": 8, "Ambient": 8}}  # głośności 0–10 (GDD: osobne suwaki)
var pad := false           # ostatnie urządzenie: pad?
var font: FontFile          # UI
var font_os: FontFile       # komputer
var font_title: FontFile    # nagłówki
var _sfx := {}    # nazwa -> AudioStream (game/sfx/*.ogg, tools/sfx/make_sfx.py)
var _loops := {}  # nazwa -> AudioStreamPlayer pętli tła
var _fades := {}  # nazwa -> Tween
var theme: Theme
var _textures := {}
var _id_seq := 0
var view := Vector2(640, 360)    # widoczny obszar (szeroki ekran: więcej niż 640x360, piksele dalej całe)
var margin := Vector2.ZERO       # o ile scena 640x360 jest przesunięta od lewego górnego rogu ekranu


func _ready() -> void:
	_build_sky()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_theme()
	for bus in ["Music", "SFX", "Ambient"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	_load_settings()
	get_tree().set_auto_accept_quit(false)
	get_tree().root.size_changed.connect(_cursor)
	get_tree().root.size_changed.connect(_fit)
	_cursor.call_deferred()
	_fit.call_deferred()


# ---------------------------------------------------------------- zasoby
func _stream(file: String) -> AudioStream:
	if not _sfx.has(file):
		var path := "res://game/" + (file if "/" in file else "sfx/" + file) + ".ogg"  # "music/day" albo efekt z sfx/
		_sfx[file] = load(path) if ResourceLoader.exists(path) else AudioStreamOggVorbis.load_from_file(path)
	return _sfx[file]


## jednorazowy efekt (oprawa z GDD rozdz. 22)
func sfx(file: String, pitch := 1.0, db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _stream(file)
	p.pitch_scale = pitch
	p.volume_db = db
	p.bus = "SFX"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func looped(file: String) -> AudioStreamOggVorbis:
	var s: AudioStreamOggVorbis = _stream(file).duplicate()
	s.loop = true
	return s


func ding(pitch := 1.0) -> void:
	sfx("ding", pitch, -6.0)


## pętla tła (deszcz, jezioro, szum kosmosu…) płynnie do `db`; db = -INF wycisza i zatrzymuje
func loop(file: String, db: float, bus := "Ambient") -> void:
	var p: AudioStreamPlayer = _loops.get(file)
	if p == null:
		if db == -INF:
			return
		p = AudioStreamPlayer.new()
		p.stream = looped(file)
		p.bus = bus
		p.volume_db = -50.0
		add_child(p)
		_loops[file] = p
	if not p.playing and db != -INF:
		p.play()
	if _fades.has(file):
		_fades[file].kill()  # stare wyciszanie nie zatrzyma ponownie włączonej pętli
	var tw := create_tween()
	_fades[file] = tw
	tw.tween_property(p, "volume_db", -50.0 if db == -INF else db, 0.8)
	if db == -INF:
		tw.tween_callback(p.stop)  # bez lambdy: lambda trzymała odtwarzanie Ogg (wyciek przy wyjściu)


## wycisza wszystkie pętle tła (wyjście ze świata do menu)
func hush() -> void:
	for file: String in _loops.keys():
		loop(file, -INF)


## wyjście z gry: zapis, potem zwolnienie dźwięków (odtwarzanie Ogg zwalnia się z opóźnieniem, inaczej silnik
## zgłasza wyciek przy zamknięciu) i dopiero wtedy quit
func quit() -> void:
	var world := get_tree().root.get_node_or_null("World")
	if world:
		save_game()
		world.queue_free()
	for p: AudioStreamPlayer in _loops.values():
		p.queue_free()
	_loops.clear()
	_fades.clear()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()


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


func _font(file: String) -> FontFile:
	var path := "res://game/fonts/" + file
	var f: FontFile = load(path) if ResourceLoader.exists(path) else FontFile.new()
	if not ResourceLoader.exists(path):
		f.load_dynamic_font(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


func _setup_theme() -> void:
	font = _font("PixelOperatorPL.ttf")  # Pixel Operator (CC0) z dorysowanymi polskimi znakami
	font_os = _font("VT323-Regular.ttf")
	font_title = _font("PressStart2P-Regular.ttf")
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
	# suwak głośności: ciemny rowek, złote wypełnienie, gałka jak mały klawisz (pełny obrys 1 px)
	var track: StyleBoxFlat = flat.call(Color("1a1426"), Color("4a3f6a"))
	track.set_content_margin_all(2)
	theme.set_stylebox("slider", "HSlider", track)
	var fill: StyleBoxFlat = flat.call(Color("c8a24a"), Color("4a3f6a"))
	fill.set_content_margin_all(2)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	for k in ["grabber", "grabber_highlight"]:
		var im := Image.create(8, 14, false, Image.FORMAT_RGBA8)
		im.fill(Color("ffcf6b") if k == "grabber_highlight" else Color("e8e0cc"))
		for x in 8:
			im.set_pixel(x, 0, Color("1a1426"))
			im.set_pixel(x, 13, Color("1a1426"))
		for y in 14:
			im.set_pixel(0, y, Color("1a1426"))
			im.set_pixel(7, y, Color("1a1426"))
		theme.set_icon(k, "HSlider", ImageTexture.create_from_image(im))
	get_tree().root.theme = theme
	# CanvasLayer przerywa dziedziczenie motywu: nadaj go każdej kontrolce najwyższego poziomu
	get_tree().node_added.connect(func(n): if n is Control and n.theme == null and not (n.get_parent() is Control): n.theme = theme)
	get_tree().node_added.connect(func(n): if n is CanvasLayer: n.offset = margin)  # UI 640x360 zawsze na środku ekranu


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT, JOY_BUTTON_DPAD_LEFT], "move_right": [KEY_D, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT],
		"move_up": [KEY_W, KEY_UP, JOY_BUTTON_DPAD_UP], "move_down": [KEY_S, KEY_DOWN, JOY_BUTTON_DPAD_DOWN],
		"interact": [KEY_E, JOY_BUTTON_A], "back": [KEY_ESCAPE, JOY_BUTTON_B], "pause": [JOY_BUTTON_START],
		"confirm": [KEY_SPACE, KEY_ENTER, JOY_BUTTON_A],
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
	var k := {"interact": ["E", "A"], "back": ["ESC", "B"], "confirm": ["LPM", "A"], "advance": ["Spacja", "A"], "focus": ["KÓŁKO", "(R)"], "prev_next": ["Q/E", "LB/RB"], "leave": ["PPM", "B"]}
	return "[%s]" % k[action][1 if pad else 0]


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and get_tree().current_scene and get_tree().current_scene.name == "World":
		save_game()


# ---------------------------------------------------------------- reguły
func has(id: String) -> bool:
	return science.has(id) or shop.has(id)


func season() -> int:
	return season_of(day)


func season_of(d: int) -> int:
	return floori((d - 1) / 7.0) % 4


func calendar() -> String:
	return "Dzień %d · %s, rok %d" % [day, SEASONS[season()], floori((day - 1) / 28.0) + 1]


func day_name(d := day) -> String:
	return "%s, %s, rok %d" % [WEEKDAYS[(d - 1) % 7], SEASONS[season_of(d)], floori((d - 1) / 28.0) + 1]


func moon_phase() -> int:
	return (day + 3) % 8  # pierwsza noc: pełnia


func night_length() -> float:
	return NIGHT_BASE


func storage_cap() -> int:
	var c := 5
	for p in [["dd", 5], ["hd", 10], ["pudelko", 10], ["hdd", 50], ["ide", 100]]:
		if has(p[0]):
			c += p[1]
	return c


func stored() -> Array:
	return journal.filter(func(j): return not j.sold and not j.get("lost", false) and not analysis.uids.has(j.uid))


func pw_mult() -> float:
	return (1.0 + (0.10 if has("pamiec1") else 0.0) + (0.15 if has("pamiec2") else 0.0)) * (1.5 if has("notatki") else 1.0)


func add_pw(amount: float) -> int:
	var v := int(round(amount * pw_mult()))
	pw += v
	today.pw = today.get("pw", 0) + v
	changed.emit()
	return v


## obiekty widoczne tej nocy: Księżyc, wylosowany zestaw (_roll_sky) i kometa
func visible_objects() -> Array:
	var out := []
	if not moon_done.has(moon_phase()) and moon_phase() != 0:
		out.append("moon")
	out.append_array(sky_tonight.filter(func(id): return SKY.has(id) and (SKY[id].req == "" or has(SKY[id].req))))
	if comet.left > 0:
		out.append("comet")
	return out


## losuje niebo nocy: kilka zwykłych gwiazdozbiorów, jeden znak zodiaku pory roku i po jednym obiekcie
## z odblokowanych kategorii; nieodkryte mają pierwszeństwo, więc każda noc przynosi coś nowego
func _roll_sky() -> void:
	var pick := func(ids: Array, n: int) -> Array:
		var fresh := ids.filter(func(id): return not discovered.has(id))
		var old := ids.filter(func(id): return discovered.has(id))
		fresh.shuffle()
		old.shuffle()
		return (fresh + old).slice(0, n)
	var open := SKY.keys().filter(func(id): return SKY[id].req == "" or has(SKY[id].req))
	sky_tonight = pick.call(open.filter(func(id): return SKY[id].cat == "const"), 5 if has("podstawowe") else 4)
	sky_tonight += pick.call(open.filter(func(id): return SKY[id].cat == "zodiac" and SKY[id].season == season()), 1)
	for cat in ["nebula", "planet", "deep"]:
		sky_tonight += pick.call(open.filter(func(id): return SKY[id].cat == cat), 1)
	if has("newton"):  # większy teleskop: 10 obiektów więcej
		sky_tonight += pick.call(open.filter(func(id): return SKY[id].cat in ["const", "zodiac", "nebula"] and not sky_tonight.has(id)), 10)


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
	for p in [["achromat", 0.20], ["lcd", 0.25], ["vga", 0.20], ["astrotax", 0.15], ["modem", 0.10]]:
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
		s[0].lost = true  # nadpisany w pamięci, ale zostaje w historii Dziennika
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
		e.paid = price(e).total
		sum += e.paid
		e.sold = true
	money += sum
	today.sales = today.get("sales", 0) + sum
	today.sales_n = today.get("sales_n", 0) + entries.size()
	if has("wzor"):
		pw += sum  # Wzór Empiryczny: +1 PW za każdy $
		today.pw = today.get("pw", 0) + sum
	changed.emit()
	return sum


## raport do Centrum: można wysłać o każdej porze, pieniądze przychodzą rano (z ISDN od razu)
func send_report(entries: Array) -> void:
	for e in entries:
		analysis.uids.append(e.uid)
	if has("isdn"):
		toast.emit("Raport przyjęty: +$%d" % _pay_report(), "good")
	else:
		toast.emit("Raport wysłany (%d). Centrum zapłaci rano." % entries.size(), "info")
	changed.emit()


func _pay_report() -> int:
	var sum := sell(journal.filter(func(j): return analysis.uids.has(j.uid))) if not analysis.uids.is_empty() else 0
	analysis.uids.clear()
	return sum


const OFFER_FROM := {"instytuty": ["Instytut Astronomii w Gwiaździnie", "Obserwatorium Nad Jeziorem", "Akademia Nieba Północnego"],
	"kolekcjonerzy": ["Kolekcjoner pan Zenon", "Antykwariat „Gwiazdozbiór”", "Pani Halina, miłośniczka komet"]}

## okazyjna oferta na jedno nieprzesłane odkrycie (szansa z badań „Oferty …”)
func _roll_offer() -> void:
	offer = {}
	var s := stored()
	if s.is_empty():
		return
	for o in [["kolekcjonerzy", 0.20, 2.5], ["instytuty", 0.30, 1.5]]:
		if has(o[0]) and randf() < o[1]:
			var e: Dictionary = s.pick_random()
			offer = {"uid": e.uid, "who": OFFER_FROM[o[0]].pick_random(), "price": int(round(price(e).total * o[2]))}
			return


func offer_entry() -> Dictionary:
	var hit := stored().filter(func(j): return not offer.is_empty() and j.uid == offer.uid)
	return hit[0] if not hit.is_empty() else {}


func accept_offer() -> int:
	var e := offer_entry()
	var sum: int = offer.price
	e.sold = true
	money += sum
	today.sales = today.get("sales", 0) + sum
	today.sales_n = today.get("sales_n", 0) + 1
	offer = {}
	changed.emit()
	return sum


## złapany meteor: +25 PW i wpis na dysku (sprzedaje się na Giełdzie); bez miejsca na dysku tylko PW
func meteor_caught() -> Dictionary:
	var saved := stored().size() < storage_cap()
	if saved:
		_id_seq += 1
		journal.append({"uid": _id_seq, "id": "meteor", "name": "Meteor", "cat": "meteor", "quality": 100, "base": 15.0, "day": day, "sold": false})
	today.meteors_n = today.get("meteors_n", 0) + 1
	return {"pw": add_pw(25), "saved": saved}


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
	today.bought = today.get("bought", []) + [["Badanie: " + row[1], row[2], "PW"]]
	science[row[0]] = true
	if row[0] == "kometa" and comet.left == 0:
		comet = {"left": COMET_NIGHTS, "gap": 0, "seed": randi()}
	changed.emit()
	toast.emit("Odblokowano: " + row[1], "good")


func can_buy_shop(row: Array) -> String:
	if shop.has(row[0]) or row[0] in parcels:
		return "owned"
	if row[0] == "certyfikat" and not science.has("manifest"):
		return "hidden"
	if row[5] != "" and not has(row[5]):
		return "req"
	return "ok" if money >= row[2] else "cost"


func buy_shop(row: Array) -> void:
	money -= row[2]
	today.bought = today.get("bought", []) + [["Zakup: " + row[1], row[2], "$"]]
	parcels.append(row[0])
	arriving = true  # kurier zapuka, gdy Jania wyłączy komputer
	changed.emit()
	toast.emit("Kupiono: %s. Kurier już jedzie." % row[1], "info")


func unpack_all(quiet := false) -> void:
	for id in parcels:
		shop[id] = true
	for id in parcels if not quiet else []:  # każdy przedmiot osobno: napisy układają się jeden pod drugim
		toast.emit("Rozpakowano: " + _shop_name(id), "good")
	parcels.clear()
	changed.emit()


func _shop_name(id: String) -> String:
	for r in SHOP:
		if r[0] == id:
			return r[1]
	return id


func stage_ready() -> bool:
	return science.has("manifest") and shop.has("certyfikat") and discovered.keys().any(func(k): return SKY.has(k) and SKY[k].cat == "planet")


# ---------------------------------------------------------------- pętla dnia
func start_night() -> void:
	night = true
	night_left = night_length()
	tonight.clear()
	_roll_sky()
	rain = rain_next
	storm = storm_next
	if has("materac"):
		add_pw(50)
	changed.emit()


## „Idź spać”: zwraca dane do Podsumowania Dnia, przechodzi w poranek i robi autozapis
func sleep() -> Dictionary:
	_pay_report()  # raport poranny: wypłata trafia do podsumowania dnia
	today.opened = parcels.map(_shop_name)  # paczka spod drzwi otwiera się sama, gdy Jania idzie spać
	unpack_all(true)
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
	storm_next = rain_next and randf() < STORM_CHANCE
	summary.forecast = "burza z piorunami – prawie nic nie widać" if storm_next else ("deszcz – słaba widoczność" if rain_next else "pogodnie")
	_roll_demand()
	_roll_offer()
	history.append(summary)
	save_game()
	return summary


func _roll_demand() -> void:
	demand.clear()
	var cats := MARKET_CATS.duplicate()
	cats.shuffle()
	for i in randi_range(1, 2):
		demand[cats[i]] = snappedf(randf_range(1.2, 1.6), 0.05)
	demand[cats[3]] = snappedf(randf_range(0.7, 0.9), 0.05)
	demand_log.append(demand.duplicate())
	if demand_log.size() > 14:
		demand_log.pop_front()


func new_game() -> void:
	day = 1
	night = true
	night_left = night_length()
	money = 0
	pw = 0
	for d in [science, shop, discovered, moon_done, tonight, tips, demand, today]:
		d.clear()
	parcels.clear()
	journal.clear()
	history.clear()
	rain = false
	rain_next = false
	storm = false
	storm_next = false
	arriving = false
	comet = {"left": 0, "gap": 0, "seed": 0}
	location = "balcony"
	stage_done = false
	demand_log.clear()
	analysis = {"uids": [], "left": 0.0}
	offer = {}
	_roll_sky()
	for i in 8:  # rynek ma historię sprzed pierwszego dnia gry
		_roll_demand()


# ---------------------------------------------------------------- zapis
const SAVED := ["day", "night", "night_left", "money", "pw", "science", "shop", "parcels", "journal", "discovered",
	"moon_done", "tonight", "demand", "demand_log", "sky_tonight", "analysis", "offer", "today", "rain", "rain_next", "storm", "storm_next", "comet", "tips", "location", "stage_done", "_id_seq", "history"]


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
			parcels.append_array(d.get("pending", []))  # zapis sprzed natychmiastowych paczek
			day = int(day)
			money = int(money)
			pw = int(pw)
			_id_seq = int(_id_seq)
			moon_done = _int_keys(moon_done)
			if sky_tonight.is_empty():  # zapis sprzed losowania nieba
				_roll_sky()
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
	for bus in ["Music", "SFX", "Ambient"]:
		settings.vol[bus] = clampi(int(settings.vol.get(bus, 8)), 0, 10)  # plik ustawień mógł być edytowany ręcznie
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(settings.vol[bus] / 10.0))
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


## samouczek (game/tutorial.gd) pokazany raz; potem tylko z POMOC.TXT
func tutorial_once(host: Node, id: String) -> void:
	if not tips.has("tut_" + id):
		tips["tut_" + id] = true
		tutorial(host, id)


func tutorial(host: Node, id: String) -> void:
	host.add_child(preload("res://game/tutorial.gd").new().setup(id))


## szeroki / wysoki ekran: scena 640x360 na środku, dookoła widać więcej świata (albo tło), nigdy czarnych pasów
func _fit() -> void:
	view = get_tree().root.get_visible_rect().size
	margin = ((view - Vector2(640, 360)) / 2.0).floor()
	for l in get_tree().root.find_children("*", "CanvasLayer", true, false):
		l.offset = margin
	for c in get_tree().get_nodes_in_group("cover"):
		cover(c)


## prostokąt na cały ekran (zaciemnienie, wygaszenie, CRT) w warstwie przesuniętej o margin
func cover(c: Control) -> void:
	c.position = -margin
	c.size = view
	if not c.is_in_group("cover"):
		c.add_to_group("cover")


## kursor w stylu AstroOS, skalowany jak gra (całkowicie); w samej grze świat go chowa
func _cursor() -> void:
	var k := maxi(1, mini(floori(get_window().size.x / 640.0), floori(get_window().size.y / 360.0)))
	var arrow := img("os/ui_cursor")
	arrow.resize(arrow.get_width() * k, arrow.get_height() * k, Image.INTERPOLATE_NEAREST)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(arrow))


## ustawienia (menu główne i pauza – ten sam blok): pełny ekran, CRT i suwaki głośności
func settings_ui(box: Container, on_change := Callable()) -> Control:
	var first: Control
	var toggle := func(opt: String, label: String, on_txt: String, off_txt: String) -> Button:
		var b := Button.new()
		var txt := func(): b.text = label + ": " + (on_txt if settings[opt] else off_txt)
		txt.call()
		b.pressed.connect(func():
			settings[opt] = not settings[opt]
			apply_settings()
			txt.call()
			if on_change.is_valid():
				on_change.call())
		box.add_child(b)
		return b
	first = toggle.call("fullscreen", "PEŁNY EKRAN", "WŁĄCZONY", "WYŁĄCZONY")
	toggle.call("crt", "EFEKT CRT", "WŁĄCZONY", "WYŁĄCZONY")
	for bus in ["Music", "SFX", "Ambient"]:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = {"Music": "MUZYKA", "SFX": "EFEKTY", "Ambient": "OTOCZENIE"}[bus]
		l.custom_minimum_size = Vector2(84, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 10
		sl.step = 1
		sl.value = settings.vol[bus]
		sl.custom_minimum_size = Vector2(110, 20)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.value_changed.connect(func(v: float):
			settings.vol[bus] = int(v)
			apply_settings()
			if bus != "Music":
				sfx("tick", 1.0, -6.0))  # słychać od razu, jak głośno będą efekty
		row.add_child(sl)
		box.add_child(row)
	return first


# testy piszą do osobnego pliku, zapis gracza zostaje nietknięty
func use_test_save() -> void:
	SAVE = "user://test_save.json"
	SAVE_BAK = "user://test_save.bak.json"


## cienka ramka z polerowanej stali (styl przyrządu); inset = ciemny „wyświetlacz” w środku
func metal(n: CanvasItem, r: Rect2) -> void:
	n.draw_rect(r.grow(1), Color("120e1a"))
	n.draw_rect(r, Color("6c7692"))
	n.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("d8e0ee"))
	n.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color("aab4c8"))
	n.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Color("2a3044"))
	n.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Color("2a3044"))
	var d := r.grow(-3)  # wpuszczone okienko na tekst
	n.draw_rect(d, Color("10141f"))
	n.draw_rect(Rect2(d.position, Vector2(d.size.x, 1)), Color("05070c"))


## przycisk jak klawisz klawiatury: zaokrąglone rogi, widoczny bok; wciśnięty = wierzch opada
func keycap(n: CanvasItem, r: Rect2, down: bool) -> Rect2:
	round_rect(n, r, Color("120e1a"))
	round_rect(n, r.grow(-1), Color("3a4258"))
	var cap := Rect2(r.position + Vector2(3, 2 + (2 if down else 0)), r.size - Vector2(6, 8))
	round_rect(n, cap, Color("7a84a0") if down else Color("8e98b2"))
	n.draw_rect(Rect2(cap.position + Vector2(1, 0), Vector2(cap.size.x - 2, 1)), Color("d8e0ee"))
	return cap


func round_rect(n: CanvasItem, r: Rect2, c: Color) -> void:
	n.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, r.size.y), c)
	n.draw_rect(Rect2(r.position.x, r.position.y + 1, r.size.x, r.size.y - 2), c)
