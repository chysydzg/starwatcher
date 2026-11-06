# Dodaje polskie znaki do Pixel Operator (CC0): składa je z istniejących glifów i pikselowych znaków diakrytycznych.
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
src, dst = sys.argv[1], sys.argv[2]
f = TTFont(src); g = f['glyf']; cm = f.getBestCmap(); hm = f['hmtx']
U = 100  # 1 piksel czcionki
def bbox(n):
    gl = g[n]; gl.recalcBounds(g); return gl.xMin, gl.yMin, gl.xMax, gl.yMax
def rect(pen, x0, y0, x1, y1):
    pen.moveTo((x0, y0)); pen.lineTo((x0, y1)); pen.lineTo((x1, y1)); pen.lineTo((x1, y0)); pen.closePath()
def make(ch, base, marks, accent=None, acc_off=(0, 0)):
    bn = cm[ord(base)]; pen = TTGlyphPen(g)
    g[bn].draw(pen, g)
    if accent:
        g[accent].draw(TransformPen(pen, (1, 0, 0, 1) + acc_off), g)
    for r in marks: rect(pen, *r)
    name = 'uni%04X' % ord(ch)
    g[name] = pen.glyph(); hm[name] = hm[bn]
    for t in f['cmap'].tables:
        if t.isUnicode(): t.cmap[ord(ch)] = name
def acute_off(base, ref_base, ref_comp):  # przesunięcie akcentu jak w gotowym glifie (np. ó), wyrównane do środka litery
    comp = [c for c in g[cm[ord(ref_comp)]].components if c.glyphName == 'acute'][0]
    b, r = bbox(cm[ord(base)]), bbox(cm[ord(ref_base)])
    dx = round(((b[0] + b[2]) - (r[0] + r[2])) / 2 / U) * U
    return (comp.x + dx, comp.y + (b[3] - r[3]))
for ch, base in [('ń', 'n'), ('ś', 's'), ('ź', 'z'), ('ć', 'c'), ('Ń', 'N'), ('Ś', 'S'), ('Ź', 'Z'), ('Ć', 'C')]:
    x0, y0, x1, y1 = bbox(cm[ord(base)]); cx = round((x0 + x1) / 2 / U - 0.5) * U  # kreska: 2 piksele po skosie (odróżnia ź od ż)
    make(ch, base, [(cx, y1 + U, cx + U, y1 + 2 * U), (cx + U, y1 + 2 * U, cx + 2 * U, y1 + 3 * U)])
for ch, base in [('ż', 'z'), ('Ż', 'Z')]:
    x0, y0, x1, y1 = bbox(cm[ord(base)]); cx = round((x0 + x1) / 2 / U - 0.5) * U
    make(ch, base, [(cx, y1 + U, cx + U, y1 + 2 * U)])
for ch, base in [('ą', 'a'), ('ę', 'e'), ('Ą', 'A'), ('Ę', 'E')]:
    x0, y0, x1, y1 = bbox(cm[ord(base)])
    make(ch, base, [(x1 - 2 * U, -U, x1 - U, 0), (x1 - U, -2 * U, x1, -U)])
x0, y0, x1, y1 = bbox(cm[ord('l')])
make('ł', 'l', [(x0 - U, 4 * U, x0, 5 * U), (x0 + U, 5 * U, x0 + 2 * U, 6 * U)])
x0, y0, x1, y1 = bbox(cm[ord('L')])
make('Ł', 'L', [(x0 + U, 5 * U, x0 + 2 * U, 6 * U), (x0 - U, 3 * U, x0, 4 * U)])
f.setGlyphOrder(list(g.glyphOrder))
f['maxp'].numGlyphs = len(g.glyphOrder)
f.save(dst)
print("ok", dst)
