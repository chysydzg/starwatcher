extends RefCounted
## Star Watcher – proceduralny pixel art Etapu 1 (top-down 3/4, płótno 640x360).
## Rysowane w kolorach dnia; noc robi CanvasModulate + światła w scenie.
## Każdy obraz jest też zapisywany jako PNG, żeby dało się go poprawiać ręcznie w Aseprite.

const W := 640
const H := 360
const INK := Color("2a1f3d")


static func img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


static func r(im: Image, x: int, y: int, w: int, h: int, col) -> void:
	var rr := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height()))
	if rr.size.x > 0 and rr.size.y > 0:
		im.fill_rect(rr, Color(col))


static func p(im: Image, x: int, y: int, col) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, Color(col))


static func ell(im: Image, cx: int, cy: int, rx: int, ry: int, col) -> void:
	for i in range(-rx, rx + 1):
		for j in range(-ry, ry + 1):
			if float(i * i) / (rx * rx + 0.5) + float(j * j) / (ry * ry + 0.5) <= 1.0:
				p(im, cx + i, cy + j, col)


static func outline(im: Image) -> Image:
	var src: Image = im.duplicate()
	var w := im.get_width()
	var h := im.get_height()
	for x in w:
		for y in h:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.5:
					im.set_pixel(x, y, INK)
					break
	return im


static func shore_x(y: float) -> float:
	return 486.0 + 8.0 * sin(y * 0.05) + 4.0 * sin(y * 0.13)


static func far_y(x: float) -> float:
	return 54.0 + 6.0 * sin(x * 0.08) + 3.0 * sin(x * 0.21)


static func is_water(x: int, y: int) -> bool:
	return x > shore_x(y) and not (y < far_y(x) and x > shore_x(y) + 18)


# ---------------------------------------------------------------- tło
static func ground() -> Image:
	var im := img(W, H)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# dach kamienicy wokół pokoju
	for y in range(0, H, 6):
		var off := 5 if (y / 6) % 2 else 0
		for x in range(-off, 412, 10):
			r(im, x, y, 10, 6, "8a4b3c"); r(im, x + 1, y, 7, 1, "a35c48")
			r(im, x, y + 5, 10, 1, "6a3a30"); r(im, x + 9, y, 1, 6, "6a3a30")
	# teren na zewnątrz: nasz brzeg, jezioro, drugi brzeg
	for y in H:
		for x in range(408, W):
			var col := "5f9a4a"
			var sx := shore_x(y)
			if is_water(x, y):
				col = "2f6fae" if (y / 4 + x / 23) % 7 else "2a64a0"
				if not is_water(x - 2, y) or not is_water(x, y - 2) or not is_water(x, y + 2):
					col = "6aa6d8"
			elif x > sx - 4 and x <= sx or (x > sx and y >= far_y(x) - 3):
				col = "d8b77a"
			elif x > sx:
				col = "4e8a46"
			p(im, x, y, col)
	for i in 160:  # kępki trawy i kwiatki (wiosna)
		var x := rng.randi_range(410, W - 1)
		var y := rng.randi_range(0, H - 1)
		if is_water(x, y) or is_water(x + 3, y): continue
		p(im, x, y, "79b45a"); p(im, x + 1, y - 1, "79b45a"); p(im, x + 2, y, "4e8340")
		if i % 9 == 0: p(im, x + 1, y - 2, ["f2d24a", "f0a0c8", "ffffff"][i % 3])
	# ściana frontowa kamienicy pod pokojem
	r(im, 0, 330, 408, 30, "9a5040")
	for y in range(330, H, 5):
		r(im, 0, y, 408, 1, "7a3c30")
		for x in range((y / 5 % 2) * 6, 408, 12): r(im, x, y, 1, 5, "7a3c30")
	for wx in [96, 250]:
		r(im, wx - 2, 336, 24, 20, "6e4330"); r(im, wx, 338, 20, 16, "ffcf6b"); r(im, wx + 9, 338, 2, 16, "6e4330")
	# podłoga z desek
	for row in range(0, 226, 7):
		var y := 96 + row
		r(im, 40, y, 360, 7, "b0784a"); r(im, 40, y, 360, 1, "c48b58"); r(im, 40, y + 6, 360, 1, "8a5a36")
		var seam := 40 + rng.randi_range(0, 60)
		while seam < 400:
			r(im, seam, y, 1, 6, "8a5a36")
			seam += rng.randi_range(50, 90)
		p(im, rng.randi_range(44, 396), y + 3, "8a5a36")
	r(im, 40, 96, 360, 3, "8a5a36")  # cień pod ścianą
	# ściana tylna (front widoczny w 3/4)
	r(im, 40, 40, 360, 56, "c98f6a")
	for x in range(44, 400, 8): r(im, x, 40, 1, 48, "b97f5c")
	for x in range(48, 400, 16):
		for y in range(46, 86, 10): p(im, x, y + (x / 16) % 2 * 5, "dfa680")
	r(im, 40, 88, 360, 8, "7a4a32"); r(im, 40, 88, 360, 1, "9a6440")
	# okno z zasłonkami
	r(im, 136, 46, 60, 40, "e8d8b8"); r(im, 140, 49, 52, 33, "4a7ac0")
	for i in 10: p(im, 146 + i, 60 - i, "7aa8e0"); p(im, 170 + i, 76 - i, "7aa8e0")
	r(im, 165, 49, 2, 33, "e8d8b8"); r(im, 140, 64, 52, 2, "e8d8b8")
	r(im, 132, 46, 6, 40, "c0504a"); r(im, 194, 46, 6, 40, "c0504a")
	r(im, 132, 46, 6, 1, "e06a5e"); r(im, 194, 46, 6, 1, "e06a5e")
	r(im, 134, 84, 64, 3, "d8c8a8")
	# plakat z gwiazdami
	r(im, 212, 50, 28, 32, "e8dcc0"); r(im, 214, 52, 24, 28, "1d2a5a")
	var pts := [Vector2i(217, 58), Vector2i(223, 55), Vector2i(229, 61), Vector2i(233, 57), Vector2i(226, 70), Vector2i(219, 74)]
	for i in pts.size() - 1:
		var a: Vector2i = pts[i]
		var b: Vector2i = pts[i + 1]
		for t in 8: p(im, int(lerp(a.x, b.x, t / 8.0)), int(lerp(a.y, b.y, t / 8.0)), "4a5a9a")
	for q in pts: p(im, q.x, q.y, "ffd84a")
	# dywan
	r(im, 196, 206, 132, 66, "6a3a6a"); r(im, 199, 209, 126, 60, "3f5fa0")
	for x in range(203, 322, 6): r(im, x, 212, 3, 2, "e8c86a"); r(im, x, 264, 3, 2, "e8c86a")
	ell(im, 262, 239, 18, 10, "e8c86a"); ell(im, 262, 239, 15, 8, "3f5fa0"); ell(im, 262, 239, 4, 3, "ffd84a")
	# ściany od góry (grube czapy)
	r(im, 32, 32, 376, 8, "3d2a3a"); r(im, 32, 32, 376, 1, "5a4058")
	r(im, 32, 32, 8, 298, "3d2a3a"); r(im, 400, 32, 8, 298, "3d2a3a")
	r(im, 32, 322, 376, 8, "3d2a3a"); r(im, 32, 322, 376, 1, "5a4058")
	r(im, 400, 198, 8, 36, "b0784a"); r(im, 400, 198, 8, 1, "8a5a36")  # próg drzwi balkonowych
	# balkon: deski + barierka tylna i boczna
	r(im, 408, 146, 108, 156, "a8744a")
	for x in range(408, 516, 6): r(im, x, 146, 1, 156, "86593a"); p(im, x + 3, 146 + (x * 7) % 150, "86593a")
	r(im, 408, 146, 108, 2, "86593a")
	r(im, 408, 300, 108, 6, "6e4330")
	r(im, 408, 132, 108, 3, "c08452"); r(im, 408, 135, 108, 1, "86593a")
	for x in range(410, 516, 8): r(im, x, 135, 2, 11, "9a6440")
	r(im, 512, 132, 4, 168, "9a6440"); r(im, 512, 132, 1, 168, "c08452")
	ell(im, 122, 152, 9, 3, Color(0, 0, 0, 0.18))  # cień modelu układu słonecznego
	return im


# ---------------------------------------------------------------- obiekty
static func bed() -> Image:
	var im := img(60, 86)
	r(im, 2, 1, 56, 15, "8a5034"); r(im, 2, 1, 56, 2, "a8643e"); r(im, 2, 1, 4, 15, "6e3e28"); r(im, 54, 1, 4, 15, "6e3e28")
	r(im, 5, 15, 50, 60, "16204a")
	r(im, 9, 16, 42, 12, "f4ead8"); r(im, 9, 26, 42, 2, "d8c8b0"); r(im, 29, 17, 1, 9, "d8c8b0")
	r(im, 6, 27, 48, 48, "1f2a5a"); r(im, 6, 27, 48, 3, "2c3a78")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 34:  # "Gwiezdna Noc": drobne żółte pikselowe gwiazdki
		var x := rng.randi_range(8, 51)
		var y := rng.randi_range(31, 72)
		p(im, x, y, "ffd84a")
		if i % 6 == 0:
			p(im, x - 1, y, "e8b83a"); p(im, x + 1, y, "e8b83a"); p(im, x, y - 1, "e8b83a"); p(im, x, y + 1, "e8b83a")
	r(im, 2, 74, 56, 8, "7a4630"); r(im, 2, 74, 56, 1, "a0603c"); r(im, 3, 82, 3, 3, "5a3020"); r(im, 54, 82, 3, 3, "5a3020")
	return outline(im)


static func mobile() -> Image:  # model układu słonecznego z podstawówki
	var im := img(34, 30)
	r(im, 16, 0, 1, 8, "8a8070")
	ell(im, 16, 15, 14, 6, "c8b890"); ell(im, 16, 15, 13, 5, Color(0, 0, 0, 0))
	ell(im, 16, 15, 8, 3, "c8b890"); ell(im, 16, 15, 7, 2, Color(0, 0, 0, 0))
	ell(im, 16, 14, 3, 3, "ffcf4a"); p(im, 15, 13, "fff0a0")
	p(im, 8, 14, "c0503a"); p(im, 24, 16, "4a8ad8"); p(im, 25, 16, "4a8ad8")
	r(im, 3, 16, 3, 2, "e0b070"); r(im, 2, 17, 5, 1, "c8a060")  # planeta z pierścieniem
	r(im, 28, 13, 2, 2, "d89060")
	return im


static func desk() -> Image:  # biurko + szary blaszak + żółtawy CRT 14" + lampka
	var im := img(84, 68)
	r(im, 2, 35, 80, 14, "a8703f"); r(im, 2, 35, 80, 1, "c08452")
	r(im, 2, 49, 80, 12, "8e5a3a"); r(im, 4, 51, 26, 8, "7a4a30"); r(im, 15, 54, 4, 1, "e8c86a")
	r(im, 3, 61, 4, 5, "6e4330"); r(im, 77, 61, 4, 5, "6e4330")
	r(im, 13, 1, 32, 4, "ece2b4")
	r(im, 13, 5, 32, 31, "e0d39a"); r(im, 41, 5, 4, 31, "b8ab78"); r(im, 13, 34, 32, 2, "b8ab78")
	r(im, 17, 8, 22, 20, "1c2f2a"); r(im, 18, 9, 4, 1, "3a5a50")
	r(im, 24, 36, 10, 2, "b8ab78")
	p(im, 39, 31, "6ad06a")
	r(im, 49, 13, 15, 4, "c0c0c8"); r(im, 49, 17, 15, 28, "a0a0a8"); r(im, 61, 17, 3, 28, "7c7c88")
	r(im, 51, 22, 9, 2, "2a2a30"); r(im, 51, 27, 9, 1, "7c7c88"); r(im, 51, 30, 9, 1, "7c7c88")
	r(im, 15, 39, 26, 6, "d8d0b0"); r(im, 15, 44, 26, 1, "a8a080")
	for x in range(17, 39, 3): p(im, x, 41, "a8a080"); p(im, x + 1, 43, "a8a080")
	r(im, 70, 22, 9, 6, "e8c86a"); r(im, 71, 21, 7, 1, "f4dc8a"); r(im, 74, 28, 1, 10, "5a5a68"); r(im, 71, 38, 7, 3, "5a5a68")
	return outline(im)


static func chair() -> Image:
	var im := img(22, 28)
	r(im, 2, 1, 18, 12, "8e5a3a"); r(im, 2, 1, 18, 2, "a8703f"); r(im, 4, 5, 14, 1, "7a4a30"); r(im, 4, 9, 14, 1, "7a4a30")
	r(im, 2, 13, 18, 8, "a8703f"); r(im, 2, 20, 18, 2, "7a4a30")
	r(im, 3, 22, 3, 5, "6e4330"); r(im, 16, 22, 3, 5, "6e4330")
	return outline(im)


static func wardrobe() -> Image:  # szafka na odzież
	var im := img(52, 76)
	r(im, 1, 1, 50, 8, "b8804e"); r(im, 1, 1, 50, 1, "d09a62")
	r(im, 1, 9, 50, 60, "a86a40"); r(im, 25, 11, 2, 56, "7a4a30")
	r(im, 4, 12, 19, 52, "b07446"); r(im, 29, 12, 19, 52, "b07446")
	p(im, 22, 38, "e8c86a"); p(im, 29, 38, "e8c86a")
	r(im, 1, 67, 50, 6, "7a4a30"); r(im, 3, 73, 4, 2, "5a3020"); r(im, 45, 73, 4, 2, "5a3020")
	return outline(im)


static func telescope() -> Image:  # tani teleskop na aluminiowym statywie
	var im := img(36, 46)
	for i in 16:
		p(im, 15 - i / 2, 28 + i, "b0b0b8"); p(im, 18 + i / 2, 28 + i, "b0b0b8"); p(im, 16, 28 + i / 3 * 3 / 3, "8a8a98")
	r(im, 16, 28, 2, 12, "8a8a98")
	r(im, 13, 25, 8, 4, "5d6478")
	for i in 22:
		var x := 4 + i
		var y := 30 - i * 9 / 10
		r(im, x, y - 3, 1, 6, "dfe4ee"); p(im, x, y - 3, "ffffff"); p(im, x, y + 2, "98a0b8")
	r(im, 25, 7, 5, 8, "2a2a36"); r(im, 23, 9, 2, 5, "c8a050")
	r(im, 2, 28, 4, 4, "3a3a48"); p(im, 3, 29, "6a7088")
	return outline(im)


static func crate() -> Image:  # skrzynka z kubkiem gorącej czekolady
	var im := img(20, 24)
	r(im, 1, 7, 18, 5, "c08452"); r(im, 1, 12, 18, 10, "9a6440"); r(im, 1, 16, 18, 1, "7a4a30")
	r(im, 7, 1, 6, 8, "c0504a"); r(im, 7, 1, 6, 1, "e07060"); r(im, 8, 2, 4, 1, "5a3020"); r(im, 13, 3, 2, 3, "c0504a")
	return outline(im)


static func front_rail() -> Image:
	var im := img(110, 24)
	r(im, 1, 1, 108, 4, "c08452"); r(im, 1, 4, 108, 1, "86593a")
	for x in range(3, 108, 8): r(im, x, 5, 2, 15, "9a6440")
	r(im, 1, 14, 108, 2, "9a6440")
	return outline(im)


static func lamp_post() -> Image:
	var im := img(14, 48)
	r(im, 3, 1, 8, 2, "3a3a48"); r(im, 2, 3, 10, 9, "3a3a48"); r(im, 4, 4, 6, 7, "ffe08a")
	r(im, 6, 12, 2, 32, "3a3a48"); r(im, 4, 43, 6, 3, "3a3a48")
	return outline(im)


static func tree(kind: int) -> Image:  # 0 = liściaste, 1 = świerk
	var im := img(34, 42)
	if kind == 0:
		r(im, 15, 26, 4, 14, "6e4330")
		ell(im, 17, 16, 15, 13, "3f7a3a"); ell(im, 15, 13, 12, 10, "4f9a4a"); ell(im, 12, 10, 6, 5, "6ab45a")
	else:
		r(im, 15, 32, 4, 8, "6e4330")
		for i in 4:
			var w := 4 + i * 4
			r(im, 17 - w, 4 + i * 7, w * 2, 8, "2f6a40"); r(im, 17 - w, 4 + i * 7, w, 6, "3f8a50")
	return outline(im)


static func ruin() -> Image:  # opuszczony budynek z małą kopułą (przyszłe laboratorium)
	var im := img(68, 56)
	r(im, 2, 20, 64, 8, "8a8a98"); r(im, 2, 28, 64, 26, "6a6a78"); r(im, 2, 52, 64, 2, "4a4a58")
	ell(im, 34, 18, 13, 11, "a0a8b8"); r(im, 20, 20, 30, 10, Color(0, 0, 0, 0))
	r(im, 21, 18, 26, 3, "8a8a98"); r(im, 33, 8, 3, 10, "3a3a48")
	for wx in [7, 19, 43, 55]:
		r(im, wx, 34, 7, 9, "2a2a36")
	r(im, 19, 37, 7, 2, "8a6a4a"); r(im, 43, 35, 7, 2, "8a6a4a")
	r(im, 30, 40, 8, 14, "3a3a48")
	for i in 12: p(im, 3 + i % 4, 30 + i * 2, "4f8a4a"); p(im, 62 - i % 3, 32 + i * 2, "4f8a4a")
	return outline(im)


# ---------------------------------------------------------------- Jania
const FUR := "e07a3a"
const FUR_D := "b65a26"
const FUR_L := "f29a58"
const CREAM := "f7dcc0"
const PINK := "f2a0a0"
const DENIM := "3f6fb0"
const DENIM_D := "2c5290"


## Arkusz 4 klatki x 3 kierunki (dół, bok w prawo, góra), klatka 20x30.
## Klatki: 0 stoi, 1-2 chód, 3 mrugnięcie.
static func jania_sheet() -> Image:
	var sheet := img(80, 90)
	for d in 3:
		for f in 4:
			sheet.blend_rect(jania(d, f), Rect2i(0, 0, 20, 30), Vector2i(f * 20, d * 30))
	return sheet


static func round_head(im: Image, x: int, y: int) -> void:  # obcina rogi głowy 12x10
	for q in [Vector2i(x, y), Vector2i(x + 11, y), Vector2i(x, y + 9), Vector2i(x + 11, y + 9)]:
		im.set_pixel(q.x, q.y, Color(0, 0, 0, 0))


static func jania(dir: int, f: int) -> Image:
	var im := img(20, 30)
	var walk := f == 1 or f == 2
	var by := -1 if walk else 0   # lekki podskok przy chodzie
	var lf := -1 if f == 1 else 0  # lewa stopa uniesiona
	var rf := -1 if f == 2 else 0
	if dir == 0:  # przodem
		r(im, 5, 1 + by, 3, 10, FUR); r(im, 6, 3 + by, 1, 7, PINK)                  # ucho stojące
		r(im, 12, 6 + by, 4, 3, FUR); r(im, 15, 8 + by, 3, 7, FUR); r(im, 16, 9 + by, 1, 5, PINK)  # ucho opadnięte
		r(im, 4, 9 + by, 12, 10, FUR); r(im, 5, 8 + by, 10, 1, FUR); r(im, 4, 9 + by, 12, 1, FUR_L)
		r(im, 6, 14 + by, 8, 5, CREAM); r(im, 5, 18 + by, 10, 1, FUR_D); round_head(im, 4, 9 + by)
		if f == 3:
			r(im, 6, 13 + by, 2, 1, INK); r(im, 12, 13 + by, 2, 1, INK)
		else:
			r(im, 6, 12 + by, 2, 2, INK); r(im, 12, 12 + by, 2, 2, INK); p(im, 6, 12 + by, "ffffff"); p(im, 12, 12 + by, "ffffff")
		r(im, 9, 15 + by, 2, 1, PINK); p(im, 5, 15 + by, PINK); p(im, 14, 15 + by, PINK)
		r(im, 5, 19, 10, 2, "f4f0e8")
		r(im, 6, 20, 8, 4, DENIM); p(im, 6, 20, "ffd84a"); p(im, 13, 20, "ffd84a")
		r(im, 5, 23, 10, 4, DENIM); r(im, 9, 24, 2, 3, DENIM_D); r(im, 5, 26, 10, 1, DENIM_D)
		r(im, 3, 19 + rf, 2, 6, FUR); r(im, 15, 19 + lf, 2, 6, FUR); p(im, 3, 25 + rf, CREAM); p(im, 16, 25 + lf, CREAM)
		r(im, 5, 27 + lf, 4, 1, DENIM_D); r(im, 11, 27 + rf, 4, 1, DENIM_D)
		r(im, 4, 28 + lf, 5, 2, FUR); r(im, 11, 28 + rf, 5, 2, FUR); r(im, 4, 29 + lf, 5, 1, FUR_D); r(im, 11, 29 + rf, 5, 1, FUR_D)
	elif dir == 1:  # bokiem (w prawo; lewo = odbicie lustrzane)
		r(im, 9, 1 + by, 3, 10, FUR); r(im, 10, 3 + by, 1, 7, PINK)
		r(im, 5, 8 + by, 4, 3, FUR); r(im, 3, 10 + by, 3, 7, FUR); p(im, 4, 11 + by, PINK)
		r(im, 6, 9 + by, 10, 10, FUR); r(im, 15, 13 + by, 3, 5, CREAM); r(im, 6, 9 + by, 10, 1, FUR_L)
		r(im, 11, 15 + by, 6, 3, CREAM); p(im, 17, 14 + by, PINK); r(im, 6, 18 + by, 10, 1, FUR_D); p(im, 6, 9 + by, Color(0, 0, 0, 0)); p(im, 6, 18 + by, Color(0, 0, 0, 0))
		if f == 3: r(im, 12, 13 + by, 2, 1, INK)
		else: r(im, 12, 12 + by, 2, 2, INK); p(im, 12, 12 + by, "ffffff")
		r(im, 7, 19, 8, 2, "f4f0e8"); r(im, 8, 20, 6, 7, DENIM); r(im, 8, 26, 6, 1, DENIM_D)
		r(im, 5, 23, 2, 3, "fffaf0"); p(im, 4, 24, "fffaf0")                      # ogonek
		var sw := 1 if f == 1 else (-1 if f == 2 else 0)
		r(im, 10 + sw, 20, 3, 6, FUR); p(im, 10 + sw, 25, CREAM)
		r(im, 8 - sw, 27, 4, 3, FUR); r(im, 11 + sw, 27, 5, 3, FUR); r(im, 11 + sw, 29, 5, 1, FUR_D); r(im, 8 - sw, 29, 4, 1, FUR_D)
	else:  # tyłem
		r(im, 12, 1 + by, 3, 10, FUR); r(im, 13, 3 + by, 1, 7, FUR_D)
		r(im, 4, 6 + by, 4, 3, FUR); r(im, 2, 8 + by, 3, 7, FUR)
		r(im, 4, 9 + by, 12, 10, FUR); r(im, 5, 8 + by, 10, 1, FUR); r(im, 4, 9 + by, 12, 1, FUR_L); r(im, 5, 18 + by, 10, 1, FUR_D); round_head(im, 4, 9 + by)
		r(im, 5, 19, 10, 4, "f4f0e8")
		for i in 4: p(im, 6 + i, 19 + i, DENIM); p(im, 13 - i, 19 + i, DENIM)
		r(im, 5, 23, 10, 4, DENIM); r(im, 5, 26, 10, 1, DENIM_D); r(im, 9, 23, 2, 4, DENIM_D)
		r(im, 8, 23, 4, 3, "fffaf0")                                                 # ogonek
		r(im, 3, 19 + lf, 2, 6, FUR); r(im, 15, 19 + rf, 2, 6, FUR)
		r(im, 5, 27 + lf, 4, 1, DENIM_D); r(im, 11, 27 + rf, 4, 1, DENIM_D)
		r(im, 4, 28 + lf, 5, 2, FUR_D); r(im, 11, 28 + rf, 5, 2, FUR_D)
	return outline(im)


# ---------------------------------------------------------------- font 3x5 (HUD)
const FONT := {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
	"E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
	"I": "111010010010111", "J": "001001001101010", "K": "101110100110101", "L": "100100100100111",
	"M": "101111111101101", "N": "110101101101101", "O": "010101101101010", "P": "110101110100100",
	"Q": "010101101110011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
	"U": "101101101101111", "V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
	"Y": "101101010010010", "Z": "111001010100111", "0": "111101101101111", "1": "010110010010111",
	"2": "110001010100111", "3": "110001010001110", "4": "101101111001001", "5": "111100110001110",
	"6": "011100111101111", "7": "111001010010010", "8": "111101111101111", "9": "111101111001110",
	"$": "011110010011110", ":": "000010000010000", ".": "000000000000010", "-": "000000111000000",
	"[": "110100100100110", "]": "011001001001011", "!": "010010010000010", "/": "001001010100100",
	" ": "000000000000000",
}
const ACCENT := {"Ą": ["A", 2, 5], "Ć": ["C", 2, -1], "Ę": ["E", 2, 5], "Ł": ["L", 1, 2], "Ń": ["N", 2, -1],
	"Ó": ["O", 2, -1], "Ś": ["S", 2, -1], "Ź": ["Z", 2, -1], "Ż": ["Z", 1, -1]}


## Rysuje tekst piksel po pikselu na CanvasItem (z cieniem). Zwraca szerokość.
static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color, shadow := true) -> int:
	var x := int(pos.x)
	var y := int(pos.y)
	for ch in s.to_upper():
		var mark = null
		if ACCENT.has(ch):
			mark = ACCENT[ch]
			ch = mark[0]
		var g: String = FONT.get(ch, FONT[" "])
		for i in 15:
			if g[i] == "1":
				if shadow: ci.draw_rect(Rect2(x + i % 3, y + i / 3 + 1, 1, 1), INK)
				ci.draw_rect(Rect2(x + i % 3, y + i / 3, 1, 1), col)
		if mark:
			if shadow: ci.draw_rect(Rect2(x + mark[1], y + mark[2] + 1, 1, 1), INK)
			ci.draw_rect(Rect2(x + mark[1], y + mark[2], 1, 1), col)
		x += 4
	return x - int(pos.x)
