// Balkon – widok z boku/zza pleców, 640x360. Niebo nocne wypalone w PNG; migotanie, odbicie księżyca i girlandę dorysowuje Godot.
const { P, R, slab, obj, shadow, piece, savePieces } = require("./kit.js");
const W = 640, H = 360, SHORE = 210, RAIL = 266, DECK = 302;
const b = new P.Buf(W, H);

// ---- niebo
const skyCols = [[14, 16, 44], [20, 26, 66], [30, 38, 92], [44, 50, 112], [66, 62, 128], [92, 76, 136]];
P.sky(b, { cols: [...skyCols].reverse(), y0: 0, y1: SHORE });
// poświata księżyca
const MX = 492, MY = 74;
for (let y = 0; y < SHORE; y++)
  for (let x = 380; x < 610; x++) {
    const d = Math.hypot(x - MX, y - MY);
    if (d < 70 && P.bt(x, y) < (70 - d) / 70 * 0.75) b.pset(x, y, P.mix(P.unpack(b.get(x, y)), [120, 130, 190], 0.35));
  }
const rs = P.rng(11);
for (let i = 0; i < 260; i++) {
  const x = Math.floor(rs() * W), y = Math.floor(rs() * (SHORE - 50)), k = rs();
  if (Math.hypot(x - MX, y - MY) < 30) continue;
  const c = k < 0.5 ? [150, 150, 200] : k < 0.75 ? [230, 226, 250] : k < 0.88 ? [255, 236, 170] : [180, 210, 255];
  b.pset(x, y, c);
  if (k > 0.97) for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) b.pset(x + dx, y + dy, P.mix(c, skyCols[1], 0.5));
}
// księżyc z kraterami
P.solid(b, [P.ell(MX, MY, 22, 22)], P.hueRamp(5, { hue: 48, shift: 25, sat: 0.55, light: [0.55, 0.9] }), { ambient: 0.5 });
for (const [cx, cy, r] of [[484, 66, 4], [500, 82, 5], [496, 62, 2], [478, 82, 3], [507, 70, 2]])
  for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) if (x * x + y * y <= r * r) b.pset(cx + x, cy + y, P.mix(P.unpack(b.get(cx + x, cy + y)), [180, 150, 110], 0.35));

// ---- góry (dwa plany) i las na drugim brzegu
const ridge = (y0, amp, s, cols, haze) => {
  for (let x = 0; x < W; x++) {
    const top = y0 - amp * P.fbm(x * 0.008, 0.5, 4, s);
    for (let y = Math.floor(top); y < SHORE; y++) {
      const v = 0.85 - (y - top) / 50;
      b.pset(x, y, P.mix(P.unpack(cols[P.band(v, cols.length, x, y)]), skyCols[4], haze));
    }
  }
};
const hill = P.hueRamp(4, { hue: 236, shift: 25, sat: 0.3, light: [0.22, 0.42] });
ridge(166, 56, 3, hill, 0.3);
ridge(194, 30, 8, P.hueRamp(4, { hue: 210, shift: 30, sat: 0.32, light: [0.1, 0.24] }), 0.04);
const pine = P.hueRamp(4, { hue: 170, shift: 40, sat: 0.3, light: [0.1, 0.3] });
for (let x = 4, i = 0; x < W; x += 6 + (i * 7) % 5, i++) {
  if (x > 140 && x < 230) continue; // miejsce na budynek
  P.conifer(b, { x, base: SHORE - 4, h: 14 + (i * 13) % 12, rx: 4 + (i % 3), cols: pine, bark: [[20, 18, 30], [30, 24, 40]], seed: i });
}
// ---- opuszczony budynek z małą kopułą (przyszłe laboratorium)
obj(b, 150, 165, 74, 42, (s) => {
  const g = P.hueRamp(4, { hue: 230, shift: 20, sat: 0.12, light: [0.12, 0.3] });
  slab(s, 4, 16, 70, 42, g, 0.5, 0.3, { grain: 0.15, sx: 0.3, sy: 0.3 });
  slab(s, 2, 13, 72, 17, g, 0.75, 0.6, { grain: 0 });
  P.solid(s, [P.ell(37, 13, 13, 11)], g, { ambient: 0.4 });
  s.rect(24, 13, 51, 17, g[2]); s.rect(36, 3, 39, 13, [16, 14, 24]);
  for (const x of [10, 22, 46, 58]) s.rect(x, 22, x + 6, 30, [12, 12, 20]);
  s.rect(22, 25, 28, 26, g[3]); s.rect(31, 30, 43, 42, [12, 12, 20]); s.rect(56, 34, 72, 42, pine[1]);
  const plank = [70, 58, 56], plank2 = [52, 44, 46];
  for (const x of [10, 22, 46, 58]) { s.rect(x - 1, 23, x + 7, 25, plank); s.rect(x - 1, 27, x + 7, 28, plank2); s.line(x, 29, x + 6, 22, plank2); } // zabite deskami okna
  s.rect(30, 33, 44, 35, plank); s.rect(30, 38, 44, 39, plank2); s.line(31, 41, 43, 31, plank); // zabite drzwi
}, { lit: [60, 64, 90], shade: [10, 10, 18] });

// ---- drugi brzeg: wąski pas trawy pod lasem + piaszczysta plaża (jak nad jeziorem na zdjęciu)
const sand = P.hueRamp(3, { hue: 38, shift: 22, sat: 0.28, light: [0.3, 0.5] });
for (let x = 0; x < W; x++) {
  const top = SHORE - 6 + Math.round(1.2 * Math.sin(x * 0.05) + 0.8 * Math.sin(x * 0.17));
  const wide = 5 + Math.round(2 * Math.sin(x * 0.03 + 1)); // plaża raz szersza, raz węższa
  for (let y = top; y < top + 2; y++) b.pset(x, y, [26, 44, 40]);
  for (let y = top + 2; y < SHORE + 4; y++) b.pset(x, y, y < top + 2 + wide ? sand[y === top + 2 ? 2 : 1] : sand[0]); // suchy / mokry piasek
}
// ---- jezioro: odbicie brzegu + pasy fal
P.reflect(b, { y0: SHORE + 4, y1: DECK, t: 0, T: 1, cols: [[30, 42, 90], [18, 26, 60]], keep: 0.55, falloff: 0.01, squash: 1.2 });
for (let y = SHORE + 5; y < DECK; y++) for (let x = 0; x < W; x++) if (P.fbm(x * 0.03, y * 0.8, 2, 4) > 0.62) b.pset(x, y, P.mix(P.unpack(b.get(x, y)), [90, 110, 170], 0.3));

const lake = b.px.slice(); // do pominięcia jeziora w nocnym przyciemnianiu
// ---- ściana budynku i otwarte drzwi balkonowe (ciepłe światło z pokoju)
slab(b, 0, 150, 78, DECK, R.beige, 0.5, 0.35, { grain: 0.06, sx: 0.2, sy: 0.2 });
for (let y = 156; y < DECK; y += 8) b.rect(0, y, 78, y + 1, R.beige[1]);
obj(b, 14, 214, 46, DECK - 214, (s) => {
  slab(s, 0, 0, 46, DECK - 214, R.woodL, 0.67, 0.67); // sama framuga, drzwi otwarte do środka
  slab(s, 5, 5, 41, DECK - 214, R.gold, 1, 0.6);
});

// ---- balustrada (malowane drewno, jak w Twoim szkicu)
const paint = P.hueRamp(3, { hue: 40, shift: 25, sat: 0.18, light: [0.5, 0.86] });
for (let x = 78; x < W; x += 11) slab(b, x, RAIL + 6, x + 4, DECK - 4, paint, 0.75, 0.45, { grain: 0 });
for (let x = 78; x < W; x += 110) slab(b, x, RAIL - 4, x + 8, DECK, paint, 0.85, 0.5, { grain: 0 });
slab(b, 78, RAIL, W, RAIL + 6, paint, 0.95, 0.55, { grain: 0 });
b.rect(78, RAIL, W, RAIL + 1, [250, 248, 236]); // księżycowy połysk na poręczy
slab(b, 78, DECK - 6, W, DECK - 2, paint, 0.6, 0.35, { grain: 0 });

// ---- podłoga balkonu: deski coraz szersze ku dołowi (perspektywa)
for (let y = DECK, row = 0, h = 4; y < H; y += h, row++, h = Math.min(h + 1, 9))
  for (let yy = y; yy < Math.min(y + h, H); yy++)
    for (let x = 0; x < W; x++) {
      const seam = (x + row * 53) % 120 === 0;
      let c = R.wood[P.hash(row, Math.floor((x + row * 53) / 120), 7) > 0.65 ? 1 : 2];
      if (yy === y) c = R.wood[3];
      if (yy === y && P.hash(x >> 3, row, 5) > 0.6) c = [236, 220, 200]; // odblask księżyca na krawędziach desek
      if (yy === y + h - 1 || seam) c = R.wood[0];
      b.pset(x, yy, c);
    }
for (let x = 0; x < W; x++) b.pset(x, DECK, R.wood[0]);

// ---- rekwizyty: tani teleskop, leżak z kocem, skrzynka z kubkiem, roślina
shadow(b, 254, 340, 22, 3);
{ // teleskop: referencja użytkownika → piksele (codixel: kwantyzacja w pełnym rozmiarze, potem resize mode)
  const ref = P.load(__dirname + "/scope_ref.png");
  for (let i = 0; i < ref.px.length; i++) { // usuń półprzezroczyste piksele i brązowy cień pod statywem
    const [r, g, bb] = P.unpack(ref.px[i]), y = Math.floor(i / ref.w);
    if ((ref.px[i] >>> 24) < 220 || (y > ref.h * 0.85 && r > bb + 15 && r < 140)) ref.px[i] = 0;
  }
  const q = P.quantize(P.trim(ref), 9).buf;
  const sp = P.smoothEdge(P.cleanup(P.resize(q, 54, null, { mode: true }), { tol: 20 }));
  const t = P.trim(require("./kit.js").ink(sp));
  piece("telescope", 341, [230, 332, 280, 346], (T) => T.sprite(t, 226, 341 - t.h));
}
shadow(b, 432, 340, 18, 3);
piece("chair", 341, [416, 330, 450, 346], (T) => obj(T, 418, 302, 30, 38, (s) => { // proste drewniane krzesło z boku; siedzisko na wysokości bioder Jani
  s.rect(8, 16, 10, 38, R.wood[0]); s.rect(26, 20, 28, 38, R.wood[0]);  // dalsze nogi
  s.rect(3, 0, 6, 38, R.wood[2]); s.rect(22, 20, 25, 38, R.wood[2]);    // tylna noga z oparciem, przednia noga
  s.rect(2, 0, 8, 7, R.wood[2]); s.rect(2, 0, 8, 1, R.wood[3]);         // jedna deska oparcia
  slab(s, 2, 17, 28, 21, R.wood, 1, 0.67);                              // siedzisko
  slab(s, 9, 14, 23, 18, R.red, 0.9, 0.6);                              // złożony koc
}));
shadow(b, 488, 338, 14, 3);
piece("crate", 339, [472, 330, 504, 344], (T) => obj(T, 474, 312, 28, 26, (s) => {
  slab(s, 0, 8, 28, 26, R.woodL, 0.6, 0.35, { grain: 0.1 }); s.rect(0, 16, 28, 17, R.woodL[1]);
  slab(s, 9, 0, 17, 9, R.red, 0.75, 0.45, { grain: 0 }); s.rect(17, 2, 19, 6, R.red[2]); s.rect(10, 0, 16, 1, [80, 40, 30]);
}));
shadow(b, 580, 340, 16, 4);
piece("plant", 341, [564, 330, 600, 346], (T) => obj(T, 562, 280, 36, 60, (s) => {
  slab(s, 8, 36, 28, 60, R.red, 0.75, 0.4, { grain: 0.05 }); s.rect(7, 36, 29, 39, R.red[4]);
  s.line(18, 38, 12, 22, R.green[0], 2); s.line(18, 38, 24, 20, R.green[0], 2);
  for (const [x, y, r] of [[18, 30, 9], [10, 32, 7], [26, 31, 7], [14, 18, 7], [24, 17, 6], [7, 22, 5], [30, 24, 5]]) P.solid(s, [P.ell(x, y, r, r * 0.85)], R.green);
}));

// ---- noc: przyciemnienie pierwszego planu (balkon jest sceną nocną) + ciepła poświata z drzwi
const tint = (buf, bg) => {
  for (let y = 150; y < H; y++)
    for (let x = 0; x < W; x++) {
      if (!(buf.px[y * W + x] >>> 24)) continue;
      if (bg && x >= 78 && (y < RAIL || buf.px[y * W + x] === lake[y * W + x])) continue; // niebo i jezioro są już nocne
      const c = P.unpack(buf.get(x, y));
      if (bg && x >= 19 && x < 55 && y >= 219 && y < DECK) continue; // światło w drzwiach
      const n = [c[0] * 0.42 + 6, c[1] * 0.46 + 8, c[2] * 0.7 + 22];
      const g = Math.max(0, 1 - Math.hypot((x - 40) / 150, (y - 300) / 70)); // światło z pokoju
      const m = P.bt(x, y) < g * 1.4 ? Math.min(1, g * 1.2) : g * 0.6;
      buf.pset(x, y, P.mix(n, [c[0] * 0.9 + 20, c[1] * 0.75 + 10, c[2] * 0.5], m));
    }
};
tint(b, true);
P.save(b, process.argv[2] + "/balcony.png");
savePieces(process.argv[2], "balcony", (buf) => tint(buf, false));
console.log("balcony.png");
