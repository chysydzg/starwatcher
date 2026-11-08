// Portrety do okienek dialogu (88x88, przezroczyste tło). Z referencji autora: Maciej (zdjęcie z profilu,
// srebrzysty), Jania (zdjęcie rudej królicy z półki). Zdjęcie → mediana 3x3 → 9 kolorów → przemalowana paleta,
// potem kodem: ubranie, okulary, oko, opadnięte ucho Macieja, siekacze Jani.
const P = require(process.env.CODIXEL);
const OUT = process.argv[2] || ".";
function pix(file, w, n) {
  const b = P.resize(P.trim(P.load(file), 0), w), o = new P.Buf(b.w, b.h);
  const md = (a) => a.sort((p, q) => p - q)[a.length >> 1];
  for (let y = 0; y < b.h; y++) for (let x = 0; x < b.w; x++) {
    const u = b.get(x, y); if ((u >>> 24) < 128) continue;
    const ch = [[], [], []];
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const q = b.get(x + dx, y + dy); if ((q >>> 24) < 128) continue; ch[0].push(q & 255); ch[1].push((q >> 8) & 255); ch[2].push((q >> 16) & 255); }
    o.pset(x, y, [md(ch[0]), md(ch[1]), md(ch[2])]);
  }
  return P.smoothEdge(P.cleanup(P.quantize(o, n, { dither: false }).buf, { tol: 20 }));
}
function recolor(b, fn) {
  const o = new P.Buf(b.w, b.h);
  for (let y = 0; y < b.h; y++) for (let x = 0; x < b.w; x++) { const u = b.get(x, y); if ((u >>> 24) < 128) continue; o.pset(x, y, fn(...P.toHsl([u & 255, (u >> 8) & 255, (u >> 16) & 255]))); }
  return o;
}
const blit = (dst, src, x0, y0) => { for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) { const u = src.get(x, y); if ((u >>> 24) >= 128) dst.pset(x0 + x, y0 + y, u); } };
const INK = [26, 22, 34];
const denim = P.hueRamp(4, { hue: 214, shift: 26, sat: 0.5, light: [0.26, 0.6] });
const coat = P.hueRamp(4, { hue: 210, shift: 20, sat: 0.12, light: [0.62, 0.95] });
const shirt = P.hueRamp(3, { hue: 205, shift: 16, sat: 0.45, light: [0.42, 0.66] });

// --- Jania (mała): głowa 34 px szer., ogrodniczki
const jh = recolor(pix(__dirname + "/ref/jania_head.png", 34, 9), (h, s, l) => P.hsl(26 + (l - 0.5) * 20, Math.min(0.85, s * 1.9 + 0.25), l));
const J = new P.Buf(88, 88);
const jx = 30, jy = 88 - jh.h - 12;
P.solid(J, [P.ell(46, 92, 22, 16)], P.hueRamp(4, { hue: 25, shift: 26, sat: 0.72, light: [0.42, 0.74] }));  // ramiona
for (let y = 78; y < 88; y++) for (let x = 32; x < 60; x++) J.pset(x, y, y === 78 ? denim[3] : denim[2]); // śliniak ogrodniczek
for (const sx of [33, 57]) for (let y = 74; y < 88; y++) { J.pset(sx, y, denim[1]); J.pset(sx + 1, y, denim[1]); }  // szelki
for (const sx of [33, 57]) { J.pset(sx, 80, [255, 214, 92]); J.pset(sx + 1, 80, [255, 214, 92]); }  // guziki
blit(J, jh, jx, jy);
// siekacze: dwa białe ząbki pod noskiem (nos ze zdjęcia: 57% szer., 93% wys. głowy)
const nx = Math.round(jx + 0.57 * jh.w), ny = Math.round(jy + 0.9 * jh.h);
J.pset(nx, ny - 2, [214, 120, 128]); J.pset(nx - 1, ny - 2, [190, 96, 106]); J.pset(nx + 1, ny - 2, [190, 96, 106]);  // nosek
const jex = Math.round(jx + 0.375 * jh.w), jey = Math.round(jy + 0.61 * jh.h);  // oko
for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 0; dx++) J.pset(jex + dx, jey + dy, [42, 24, 22]);
J.pset(jex, jey - 1, [250, 244, 236]);
for (const dx of [-1, 1]) for (let y = ny; y < ny + 3; y++) J.pset(nx + dx, y, y === ny + 2 ? [214, 206, 196] : [250, 246, 238]);
for (let y = ny; y < ny + 3; y++) J.pset(nx, y, [190, 178, 168]);
// --- Maciej: głowa z profilu 38 px, opadnięte drugie ucho, okulary, kitel
const mh = recolor(pix(__dirname + "/ref/maciej_head.png", 38, 9), (h, s, l) => P.hsl(222 - (l - 0.4) * 30, 0.08, Math.min(0.86, l * 0.92)));
const M = new P.Buf(88, 88);
const mx = 26, my = 88 - mh.h - 10;
const furM = P.hueRamp(4, { hue: 222, shift: 24, sat: 0.08, light: [0.3, 0.7] });
P.solid(M, [P.ell(46, 102, 36, 32)], coat);                                   // kitel
for (let y = 74; y < 88; y++) { const d = (y - 74) >> 1; for (let x = 44 - d; x <= 46 + d; x++) M.pset(x, y, shirt[1]); } // koszula w dekolcie
for (let y = 74; y < 88; y++) { const d = (y - 74) >> 1; M.pset(43 - d, y, coat[0]); M.pset(47 + d, y, coat[0]); }      // klapy
blit(M, mh, mx, my);
// opadnięte ucho: leży wzdłuż boku głowy od czubka w dół (drugie stoi, jak na zdjęciu)
P.solid(M, [P.cap(mx + 15, my + 20, mx + 9, my + 40, 4.2, 5.2), P.cap(mx + 9, my + 40, mx + 7, my + 58, 5.2, 4)], furM, { light: [-0.5, -0.6, 0.6] });
for (let t = 0; t <= 1; t += 0.02) { const x = Math.round(mx + 13 - 6 * t), y = Math.round(my + 24 + 32 * t); M.pset(x, y, furM[0]); }  // fałda ucha
// oko: brązowe tęczówki z odblaskiem, okrągłe okulary z zausznikiem
const ex = Math.round(mx + 0.54 * mh.w), ey = Math.round(my + 0.64 * mh.h);
for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) M.pset(ex + dx, ey + dy, [104, 62, 34]);
M.pset(ex, ey, [44, 24, 16]); M.pset(ex + 1, ey, [44, 24, 16]); M.pset(ex - 1, ey - 1, [250, 244, 230]);
for (let a = 0; a < 64; a++) M.pset(Math.round(ex + 0.5 + Math.cos(a / 64 * 6.283) * 4.5), Math.round(ey + Math.sin(a / 64 * 6.283) * 4.5), INK);
for (let x = mx + 14; x < ex - 4; x++) M.pset(x, ey - 1 - Math.round((x - mx - 14) * 0.08), INK);  // zausznik do tyłu
for (let x = ex + 5; x < ex + 8; x++) M.pset(x, ey - 1, INK);                                      // mostek
M.pset(ex + 3, ey - 3, [236, 244, 255]);  // błysk na szkle
const out = (b, r) => P.selout(b, r[1], INK);
const Jo = out(J, P.hueRamp(4, { hue: 25, shift: 26, sat: 0.72, light: [0.3, 0.6] })), Mo = out(M, furM);
P.save(Jo, OUT + "/portrait_jania.png"); P.save(Mo, OUT + "/portrait_maciej.png");
P.save(P.sheet([{ buf: Jo, scale: 4, label: "JANIA" }, { buf: Mo, scale: 4, label: "MACIEJ" }, { buf: Jo, scale: 1 }, { buf: Mo, scale: 1 }]), __dirname + "/_portraits.png");
