// Scenki satelity (Etap 2): budowa na rusztowaniu (widok z boku) i start rakiety. Rusztowanie, satelita w 5 etapach,
// blacha do noszenia, ramię robota (3 pozy), betonowy plac, rakieta z wieżą startową, płomień (3 klatki), rozłożona satelita.
const { P, R, INK, slab, obj } = require("./kit.js");
const out = process.argv[2];
const W = 640, H = 360, GROUND = 330, LV = [264, 188];
const steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.14, light: [0.3, 0.78] });
const white = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.12, light: [0.6, 0.96] });
const yel = [[250, 196, 44], [222, 156, 26], [156, 100, 22]];
const gold = R.gold, cell = P.hueRamp(4, { hue: 226, shift: 18, sat: 0.6, light: [0.2, 0.55] });
const sheet = [];
const save = (b, name) => { P.save(b, `${out}/${name}.png`); sheet.push({ buf: b, label: name.replace("sb_", "").toUpperCase(), scale: b.w > 200 ? 1 : 3 }); };

// ---- plac: beton z liniami i odpływem (dół ekranu)
{
  const b = new P.Buf(W + 640, 30);
  slab(b, 0, 0, b.w, 30, steel, 0.62, 0.42);
  for (let x = 0; x < b.w; x++) b.pset(x, 0, steel[3]);
  for (let x = 8; x < b.w; x += 64) for (let y = 1; y < 30; y++) b.pset(x, y, steel[1]);  // dylatacje płyt
  for (let x = 0; x < b.w; x += 24) for (let k = 0; k < 12; k++) b.pset(x + k, 6, yel[1]);    // przerywana żółta linia
  save(b, "sb_ground");
}
// ---- rusztowanie: dwie wieże z rur, deski na dwóch poziomach, drabiny, poręcze (przezroczyste tło)
{
  const b = new P.Buf(W, H);
  const tube = (x0, y0, x1, y1) => { const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)); for (let i = 0; i <= n; i++) { const x = Math.round(x0 + (x1 - x0) * i / n), y = Math.round(y0 + (y1 - y0) * i / n); b.pset(x, y, steel[2]); b.pset(x + 1, y, steel[1]); } };
  for (const [a, c] of [[150, 250], [390, 490]]) {
    for (const x of [a, c]) tube(x, LV[1] - 46, x, GROUND);
    for (const y of [LV[0], LV[1], LV[1] - 46]) tube(a, y - 20, c, y - 20);          // poręcze
    for (const y of [LV[0], LV[1]]) { tube(a, y, c, y + 76 - 2); }                   // ukośne stężenia
    for (const y of LV) { slab(b, a - 4, y, c + 6, y + 6, R.woodL, 0.85, 0.5, { grain: 0 }); for (let x = a - 4; x < c + 6; x++) b.pset(x, y + 6, R.wood[0]); }
    for (let k = 0; k < 2; k++) { const lx = k ? c - 18 : a + 10, y0 = LV[k], y1 = k ? LV[0] : GROUND; for (const x of [lx, lx + 10]) tube(x, y0, x, y1); for (let y = y0 + 6; y < y1; y += 9) tube(lx, y, lx + 10, y); }  // drabiny
  }
  save(P.outline(b, INK), "sb_scaffold");
}
// ---- satelita: 5 etapów (0 rama, 1 pół blach, 2 pełny korpus, 3 folia i jedno skrzydło, 4 dwa skrzydła i antena); stojak
function sat(k) {
  const b = new P.Buf(128, 150), x0 = 32, y0 = 50, w = 64, h = 70;
  slab(b, 52, 120, 76, 150, steel, 0.5, 0.3);                                                       // stojak
  for (let x = 40; x < 88; x++) { b.pset(x, 120, steel[3]); b.pset(x, 121, steel[2]); }
  if (k >= 1) slab(b, x0, k >= 2 ? y0 : y0 + h / 2, x0 + w, y0 + h, white, 0.95, 0.6);          // blachy korpusu
  for (const [ax, ay, bx, by] of [[x0, y0, x0 + w, y0], [x0, y0 + h - 1, x0 + w, y0 + h - 1], [x0, y0, x0, y0 + h], [x0 + w - 1, y0, x0 + w - 1, y0 + h], [x0 + w / 2, y0, x0 + w / 2, y0 + h]])
    for (let i = 0; i <= Math.max(bx - ax, by - ay); i++) b.pset(ax + (bx > ax ? i : 0), ay + (by > ay ? i : 0), steel[k >= 2 ? 1 : 2]);  // rama / łączenia blach
  if (k >= 1) for (let y = (k >= 2 ? y0 : y0 + h / 2) + 4; y < y0 + h; y += 10) for (let x = x0 + 4; x < x0 + w; x += 8) b.pset(x, y, steel[1]);  // nity
  if (k >= 3) { slab(b, x0, y0 + h - 14, x0 + w, y0 + h, gold, 0.95, 0.5); for (let x = x0; x < x0 + w; x += 5) b.pset(x, y0 + h - 8, gold[0]); }  // złota folia
  const wing = (wx) => { slab(b, wx, y0 + 4, wx + 14, y0 + h - 4, cell, 0.8, 0.5); for (let y = y0 + 4; y < y0 + h - 4; y += 6) for (let x = wx; x < wx + 14; x++) b.pset(x, y, steel[2]); };  // złożony panel
  if (k >= 3) wing(x0 - 16);
  if (k >= 4) { wing(x0 + w + 2); P.solid(b, [P.ell(64, 34, 14, 5)], white, { light: [-0.4, -0.8, 0.4] }); for (let y = 38; y < y0; y++) b.pset(64, y, steel[1]); b.pset(64, 26, R.red[2]); }  // czasza anteny
  return P.outline(b, INK);
}
for (let k = 0; k <= 4; k++) save(sat(k), `sb_sat_${k}`);
// ---- blacha do noszenia
{ const b = new P.Buf(18, 8); slab(b, 0, 0, 18, 8, white, 1, 0.65); b.pset(2, 2, steel[1]); b.pset(15, 2, steel[1]); b.pset(2, 5, steel[1]); b.pset(15, 5, steel[1]); save(P.outline(b, INK), "sb_plate"); }
// ---- ramię robota: podstawa i dwa segmenty, 3 pozy (rysowane z kapsuł, jasnoszare z żółtymi przegubami)
function arm(a1, a2) {
  const b = new P.Buf(110, 120), bx = 40, by = 112;
  slab(b, 24, 104, 58, 120, steel, 0.5, 0.3);
  const ex = bx + Math.cos(a1) * 46, ey = by - 8 + Math.sin(a1) * 46, tx = ex + Math.cos(a2) * 38, ty = ey + Math.sin(a2) * 38;
  P.solid(b, [P.cap(bx, by - 8, ex, ey, 6, 5)], white, { light: [-0.4, -0.8, 0.4] });
  P.solid(b, [P.cap(ex, ey, tx, ty, 4.5, 3.5)], white, { light: [-0.4, -0.8, 0.4] });
  for (const [x, y, r] of [[bx, by - 8, 6], [ex, ey, 5]]) P.solid(b, [P.ell(x, y, r, r)], P.hueRamp(3, { hue: 44, sat: 0.8, light: [0.45, 0.75] }));
  for (const d of [-3, 3]) for (let i = 0; i < 6; i++) b.pset(Math.round(tx + Math.cos(a2) * i + Math.cos(a2 + Math.PI / 2) * d), Math.round(ty + Math.sin(a2) * i + Math.sin(a2 + Math.PI / 2) * d), steel[1]);  // chwytak
  return P.outline(b, INK);
}
save(P.pack([arm(-1.2, -0.2), arm(-1.0, 0.25), arm(-1.35, -0.55)], { cols: 3, pad: 0 }), "sb_arm");
// ---- rakieta (bok): owiewka, biały korpus z czarnymi pasami, stateczniki, dysza
{
  const b = new P.Buf(40, 160), cx = 20;
  slab(b, 12, 30, 28, 140, white, 0.98, 0.7);
  for (let y = 0; y < 30; y++) { const r = 8 * Math.sqrt(y / 30); for (let x = Math.round(cx - r); x < Math.round(cx + r); x++) b.pset(x, y, white[y < 6 ? 3 : 2]); }  // owiewka
  for (const y of [48, 92, 120]) for (let x = 12; x < 28; x++) { b.pset(x, y, INK); b.pset(x, y + 1, INK); }
  for (let y = 60; y < 80; y++) b.pset(16, y, R.red[2]);
  for (const s of [-1, 1]) for (let y = 120; y < 146; y++) { const wdt = Math.round((y - 120) / 3); for (let i = 0; i < wdt; i++) b.pset(s < 0 ? 11 - i : 28 + i, y, R.red[y > 140 ? 1 : 2]); }  // stateczniki
  slab(b, 14, 140, 26, 150, steel, 0.5, 0.25);
  save(P.outline(b, INK), "sb_rocket");
}
// ---- wieża startowa: kratownica z ramionami
{
  const b = new P.Buf(70, 220);
  for (const x of [8, 34]) for (let y = 0; y < 220; y++) { b.pset(x, y, R.red[2]); b.pset(x + 1, y, R.red[1]); }
  for (let y = 4; y < 220; y += 14) { for (let x = 8; x < 36; x++) b.pset(x, y, R.red[1]); for (let i = 0; i < 14; i++) b.pset(9 + Math.round(i * 25 / 14), y + i, R.red[0]); }
  for (const y of [60, 130]) slab(b, 36, y, 66, y + 5, steel, 0.6, 0.4);  // ramiona serwisowe
  save(P.outline(b, INK), "sb_tower");
}
// ---- płomień silnika: 3 klatki
{
  const fr = [0, 1, 2].map((f) => { const b = new P.Buf(24, 56), c = [[255, 250, 220], [255, 214, 90], [255, 140, 40], [220, 70, 30]];
    for (let y = 0; y < 56; y++) { const r = (5 + 5 * Math.sin(y / 56 * Math.PI)) * (1 + 0.15 * Math.sin(y * 0.7 + f * 2)); for (let x = 0; x < 24; x++) { const d = Math.abs(x - 11.5) / r; if (d < 1) b.pset(x, y, c[Math.min(3, Math.floor(d * 2 + y / 30))]); } }
    return b; });
  save(P.pack(fr, { cols: 3, pad: 0 }), "sb_flame");
}
// ---- satelita na orbicie: rozłożone panele
{
  const b = new P.Buf(60, 22);
  slab(b, 22, 4, 38, 18, white, 1, 0.6); slab(b, 22, 14, 38, 18, gold, 0.9, 0.5);
  for (const x0 of [1, 40]) { slab(b, x0, 7, x0 + 19, 15, cell, 0.85, 0.5); for (let x = x0; x < x0 + 19; x += 5) for (let y = 7; y < 15; y++) b.pset(x, y, steel[2]); }
  for (let x = 20; x < 22; x++) b.pset(x, 11, steel[1]); for (let x = 38; x < 40; x++) b.pset(x, 11, steel[1]);
  P.solid(b, [P.ell(30, 3, 5, 2)], white);
  save(P.outline(b, INK), "sb_sat_open");
}
P.save(P.sheet(sheet, { cols: 4 }), __dirname + "/_satscene.png");
console.log("satscene ok");
