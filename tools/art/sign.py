# Szyld „OBSERWATORIUM” na finał przeprowadzki: tablica na dwóch słupkach przy brzegu, różowy neon (Press Start 2P 8 px,
# siatka 1:1) z ciemną poświatą, żarówki w ramce. Arkusz 3 klatek (hframes 3): 0 zgaszony, 1 i 2 świeci (żarówki na zmianę).
import sys
from PIL import Image, ImageDraw, ImageFont
font, out = sys.argv[1], sys.argv[2]
T = "OBSERWATORIUM"
f = ImageFont.truetype(font, 8)
tw = int(f.getlength(T))
mask = Image.new("1", (tw, 8))
ImageDraw.Draw(mask).text((0, 0), T, font=f, fill=1)
W, BH, LEG = tw + 14, 20, 14
H = BH + LEG
INK, STEEL, STEEL_D, BOARD = (10, 10, 18, 255), (110, 118, 142, 255), (66, 72, 94, 255), (28, 22, 42, 255)
def frame(k):
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    for lx in (14, W - 17):  # słupki (symetrycznie)
        d.rectangle([lx, BH - 1, lx + 2, H - 1], fill=INK)
        d.rectangle([lx + 1, BH - 1, lx + 1, H - 2], fill=STEEL_D)
    d.rectangle([0, 0, W - 1, BH - 1], fill=INK)
    d.rectangle([1, 1, W - 2, BH - 2], fill=STEEL)
    d.rectangle([1, BH - 3, W - 2, BH - 2], fill=STEEL_D)
    d.rectangle([3, 3, W - 4, BH - 4], fill=INK)
    d.rectangle([4, 4, W - 5, BH - 5], fill=BOARD)
    x0, y0 = (W - tw) // 2, 6
    core = (255, 150, 220, 255) if k else (86, 54, 82, 255)
    glow = (140, 46, 116, 255)
    if k:  # poświata: 1 px wokół liter
        for y in range(8):
            for x in range(tw):
                if mask.getpixel((x, y)):
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        p = (x0 + x + dx, y0 + y + dy)
                        if 4 <= p[0] < W - 4 and 4 <= p[1] < BH - 4 and im.getpixel(p) == BOARD:
                            im.putpixel(p, glow)
    for y in range(8):
        for x in range(tw):
            if mask.getpixel((x, y)):
                im.putpixel((x0 + x, y0 + y), core)
    for i, x in enumerate(range(3, W - 3, 4)):  # żarówki w górnej i dolnej listwie ramki
        on = k and (i + k) % 2 == 0
        for y in (1, BH - 3):
            im.putpixel((x, y), (255, 222, 140, 255) if on else (70, 60, 50, 255))
    return im
sheet = Image.new("RGBA", (W * 3, H))
for k in range(3):
    sheet.paste(frame(k), (W * k, 0))
sheet.save(out + "/cut_sign.png")
print("cut_sign.png", W, H, "text", tw)
