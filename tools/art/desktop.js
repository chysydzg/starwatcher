// AstroOS: tapeta (zielone wzgórze pod niebem), ikony pulpitu, ikony kategorii sklepu, glify drzewka badań.
const { P, R, slab, ink } = require("./kit.js");
const out = process.argv[2] + "/";
const W = 640, H = 360;

// ---------------------------------------------------------------- tapeta
const wall = new P.Buf(W, H);
P.sky(wall, { y0: 0, y1: H, cols: [[163, 194, 243], [123, 169, 240], [83, 144, 238], [49, 122, 233]], dither: 0.3 }); // kolory zmierzone z referencji
// cumulusy: kępy kulistych „puchów” z płaską, chłodniejszą podstawą (oświetlone z lewej-góry)
const CL = [[150, 186, 238], [196, 217, 246], [234, 241, 250], [255, 255, 255]];
const cloud = (cx, base, w, seed) => {
  const r = P.rng(seed), prims = [], s = new P.Buf(W, H);
  for (let i = 0; i < 5 + w / 8; i++) { const x = cx + (r() - 0.5) * w, rr = 8 + r() * w * 0.32 * (1 - 0.7 * Math.abs(x - cx) / w); prims.push(P.ell(x, base - rr * 0.6, rr * 1.2, rr)); }
  P.solid(s, prims, CL, { light: [-0.5, -0.8, 0.6], ambient: 0.45 });
  for (let i = 0; i < s.px.length; i++) if (s.px[i] >>> 24 && (i / W | 0) > base) s.px[i] = 0;
  for (let x = 0; x < W; x++) if (s.get(x, base) >>> 24) s.pset(x, base, CL[0]); // płaska podstawa
  wall.sprite(s, 0, 0);
};
// cirrusy: pęki cienkich, półprzezroczystych smug wysoko na niebie
for (const [x0, y0, len, sd] of [[230, 40, 120, 1], [40, 74, 80, 2], [400, 60, 90, 3]]) {
  const r = P.rng(sd);
  for (let j = 0; j < 7; j++) {
    const dy = j * 3 + r() * 2, dx = r() * 20, l = len * (0.5 + r() * 0.5);
    for (let k = 0; k < l; k++) { const u = k / l; P.blend(wall, x0 + dx + k, Math.round(y0 + dy - k * 0.3 + 4 * Math.sin(u * 3)), [240, 246, 252], 0.55 * Math.sin(u * Math.PI)); }
  }
}
for (const [cx, base, w, sd] of [[110, 104, 46, 3], [330, 130, 60, 5], [520, 120, 80, 7], [610, 70, 40, 9], [450, 196, 50, 13], [580, 208, 90, 15], [250, 206, 60, 17], [60, 214, 36, 19]]) cloud(cx, base, w, sd);
// daleki, niebieskawy grzbiet po prawej (głębia)
const far = (x) => 238 - 14 * Math.exp(-(((x - 560) / 60) ** 2)) - 8 * Math.exp(-(((x - 470) / 40) ** 2));
const farC = P.hueRampFrom([[120, 140, 190], [150, 170, 214], [180, 198, 234]], 3);
for (let x = 0; x < W; x++) for (let y = Math.floor(far(x)); y < H; y++) wall.pset(x, y, farC[P.band(0.7 - (y - far(x)) / 30, 3, x, y, 0.2)]);
// główne wzgórze: łagodny łuk, światło z lewej-góry, jasne pasy „przeczesanej” trawy
const hill = (x) => 268 - 80 * Math.exp(-(((x - 230) / 290) ** 2)) + 0.02 * x;
const G = P.hueRamp(5, { hue: 84, shift: 26, sat: 0.66, light: [0.2, 0.52] });
for (let x = 0; x < W; x++) {
  const top = Math.floor(hill(x)), slope = hill(x + 1) - hill(x - 1);
  for (let y = top; y < H; y++) {
    const d = (y - top) / (H - top);
    const v = 0.72 - slope * 0.35 - d * 0.4 - Math.max(0, x - 380) / 900 + 0.06 * Math.sin((x * 0.6 + y * 2.2) * 0.02) + (P.fbm(x * 0.012, y * 0.04, 2, 7) - 0.5) * 0.1;
    wall.pset(x, y, G[P.band(v, 5, x, y, 0.16)]);
  }
}
// pierwszy plan: ciemniejsza łąka z kępkami i kwiatkami
const fg = (x) => 318 + 6 * Math.sin(x * 0.017) + 4 * Math.sin(x * 0.041);
for (let x = 0; x < W; x++) for (let y = Math.floor(fg(x)); y < H; y++) wall.pset(x, y, G[P.band(0.42 - (y - fg(x)) / 90 + (P.fbm(x * 0.05, y * 0.1, 2, 9) - 0.5) * 0.3, 5, x, y, 0.2)]);
P.grass(wall, { x0: 0, x1: W, count: 900, ground: (x) => fg(x) + 2, hmin: 2, hmax: 6, cols: [G[1], G[2], G[3]].map(P.unpack), seed: 5 });
const rnd = P.rng(11);
for (let i = 0; i < 70; i++) {
  const x = Math.floor(rnd() * W), y = Math.floor(fg(x) + 4 + rnd() * (H - fg(x) - 4));
  wall.pset(x, y, rnd() < 0.7 ? [250, 226, 90] : [250, 250, 240]);
}
P.save(wall, out + "os_wallpaper.png");

// ---------------------------------------------------------------- ikony (32x32, czarny obrys)
const icon = (name, w, h, draw) => { const s = new P.Buf(w, h); draw(s); P.save(ink(s), out + name + ".png"); };
const WHITE = [248, 248, 244], PAPER = [236, 228, 200], BLUE = R.navy, DARK = [30, 30, 46];

icon("icon_dziennik", 26, 30, (s) => { // notes z gwiazdą
  slab(s, 0, 0, 26, 30, R.red, 0.6, 0.35); s.rect(3, 0, 5, 30, R.red[0]);
  slab(s, 7, 4, 23, 26, R.cream, 0.95, 0.7);
  for (let y = 9; y < 25; y += 4) s.rect(9, y, 21, y + 1, [168, 186, 214]);
  s.poly([[15, 5], [17, 10], [22, 10], [18, 13], [19, 18], [15, 15], [11, 18], [12, 13], [8, 10], [13, 10]], R.gold[2]);
});
icon("icon_gielda", 30, 28, (s) => { // monitor z wykresem świecowym
  slab(s, 0, 0, 30, 28, R.gray, 0.85, 0.6);
  s.rect(2, 2, 28, 24, [14, 26, 40]);
  for (let x = 3; x < 28; x += 5) s.rect(x, 3, x + 1, 23, [26, 44, 64]);
  const c = [[5, 16, 20, 0], [10, 12, 17, 1], [15, 13, 16, 0], [20, 8, 13, 1], [25, 5, 10, 1]];
  for (const [x, a, b, up] of c) { s.rect(x - 1, a, x + 2, b, up ? [90, 230, 120] : [240, 90, 80]); s.rect(x, a - 2, x + 1, b + 2, up ? [90, 230, 120] : [240, 90, 80]); }
  s.line(4, 20, 26, 5, [250, 220, 90]);
});
icon("icon_sklep", 30, 28, (s) => { // karton z taśmą i metką
  slab(s, 0, 0, 30, 8, R.beige, 1, 0.9); slab(s, 0, 8, 30, 28, R.beige, 0.6, 0.45);
  s.rect(12, 0, 18, 28, R.gold[1]); s.rect(0, 8, 30, 9, R.beige[0]);
  s.rect(3, 14, 11, 23, WHITE); s.rect(4, 16, 10, 17, R.navy[2]); s.rect(4, 19, 8, 20, R.navy[2]);
  s.rect(21, 16, 27, 22, R.red[2]); s.rect(23, 18, 25, 20, WHITE);
});
icon("icon_badania", 30, 28, (s) => { // trzy węzły drzewka połączone liniami
  s.line(15, 8, 6, 22, [230, 236, 250], 2); s.line(15, 8, 24, 22, [230, 236, 250], 2);
  const node = (x, y, r) => { slab(s, x - 5, y - 5, x + 5, y + 5, r, 1, 0.55); s.rect(x - 2, y - 2, x + 2, y + 2, WHITE); };
  node(15, 6, R.gold); node(6, 21, P.hueRamp(3, { hue: 190, shift: 16, sat: 0.7, light: [0.35, 0.7] })); node(24, 21, R.purple);
});
icon("icon_pomoc", 24, 30, (s) => { // kartka tekstowa z „?”
  slab(s, 0, 0, 24, 30, R.cream, 1, 0.8); s.poly([[17, 0], [24, 7], [17, 7]], R.cream[0]);
  for (let y = 15; y < 27; y += 3) s.rect(3, y, 20, y + 1, [150, 150, 160]);
  for (const [x, y] of [[9, 3], [10, 2], [11, 2], [12, 2], [13, 3], [13, 4], [12, 5], [11, 6], [11, 7], [11, 10]]) s.rect(x, y, x + 1, y + 2, BLUE[1]);
});
icon("icon_etap", 30, 30, (s) => { // złota gwiazda ETAP 2
  const pts = []; for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, r = i % 2 ? 6 : 15; pts.push([15 + Math.cos(a) * r, 16 + Math.sin(a) * r]); }
  s.poly(pts, R.gold[1]); s.poly(pts.map(([x, y]) => [15 + (x - 15) * 0.55 - 1, 16 + (y - 16) * 0.55 - 2]), R.gold[2]);
});
// kategorie sklepu (24x24)
icon("cat_optyka", 24, 22, (s) => { // teleskop na trójnogu
  s.line(4, 21, 12, 12, R.wood[1], 2); s.line(20, 21, 12, 12, R.wood[1], 2); s.line(12, 21, 12, 12, R.wood[0], 1);
  s.line(3, 13, 20, 3, R.gray[1], 5); s.line(3, 12, 19, 3, R.gray[3], 1); s.rect(19, 0, 23, 6, R.navy[2]);
});
icon("cat_komputer", 22, 20, (s) => { // sam kwadratowy monitor
  slab(s, 0, 0, 22, 20, R.beige, 0.95, 0.6); s.rect(3, 3, 19, 15, [20, 40, 70]);
  s.rect(5, 5, 12, 6, [120, 200, 255]); s.rect(5, 8, 16, 9, [120, 200, 255]); s.rect(5, 11, 10, 12, [120, 200, 255]);
  s.rect(16, 17, 19, 18, [90, 230, 120]);
});
icon("cat_pokoj", 22, 24, (s) => { // lampka na stoliku
  s.poly([[6, 0], [16, 0], [20, 9], [2, 9]], R.gold[2]); s.rect(2, 8, 20, 9, R.gold[0]); s.rect(6, 0, 16, 1, R.cream[2]);
  s.rect(10, 9, 12, 14, R.gray[1]); s.rect(7, 14, 15, 15, R.gray[0]);
  slab(s, 0, 15, 22, 18, R.wood, 0.9, 0.7); s.rect(2, 18, 4, 24, R.wood[0]); s.rect(18, 18, 20, 24, R.wood[0]);
});
// małe ikony kart na pasku okna (16 px): ikony pulpitu zmniejszone z zachowaniem najczęstszego koloru
for (const id of ["dziennik", "gielda", "sklep", "badania", "pomoc"]) {
  const big = P.load(out + "icon_" + id + ".png");
  P.save(P.resize(big, 16, Math.round(16 * big.h / big.w), { mode: true }), out + "tab_" + id + ".png");
}
// glify węzłów drzewka (białe, 14x14, bez obrysu – tło węzła rysuje Godot)
const glyph = (name, draw) => { const s = new P.Buf(14, 14); draw(s); const o = new P.Buf(15, 15); for (let i = 0; i < s.px.length; i++) if (s.px[i] >>> 24) o.pset((i % 14) + 1, ((i / 14) | 0) + 1, [20, 20, 40]); o.sprite(s, 0, 0); P.save(o, out + name + ".png"); };
glyph("glyph_optyka", (s) => { s.ring(7, 7, 5.5, 1.6, WHITE); s.blob(7, 7, 2, WHITE); s.line(10, 10, 13, 13, WHITE, 2); }); // lupa/soczewka
glyph("glyph_analiza", (s) => { s.rect(5, 0, 9, 2, WHITE); s.rect(5, 2, 7, 6, WHITE); s.rect(7, 2, 9, 6, WHITE); s.poly([[4, 6], [10, 6], [14, 13], [0, 13]], WHITE); }); // kolba
glyph("glyph_kosmos", (s) => { s.blob(7, 7, 4.5, WHITE); s.line(0, 10, 14, 4, WHITE, 1); }); // planeta z pierścieniem
