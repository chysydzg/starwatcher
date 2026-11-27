// Etap 2: laboratorium w odnowionym obserwatorium nad jeziorem (GDD 13) – jeden ekran 640x360, ta sama perspektywa
// co pokój (top-down 3/4, ściana do y 112), ale wnętrze białe i industrialne: płytki, panele, rury pod sufitem,
// szafy serwerowe, spektrograf, stanowisko komputerowe, duży teleskop na platformie, biurko Arbjooze, podium ze
// starym teleskopem z balkonu. Okno (x 152) i drzwi wejściowe (x 520) mają geometrię pokoju: szyby, ekran komputera
// i światła z world.gd pasują bez zmian. Drzwi po lewej prowadzą do pokoiku Jani (pokoik.js).
const fs = require("fs");
const { tube45, P, R, INK, slab, obj, shadow, light, piece, savePieces } = require("./kit.js");
const W = 640, H = 360, WALL = 112;
const out = process.argv[2];
const b = new P.Buf(W, H);
const tile = P.hueRamp(4, { hue: 210, shift: 12, sat: 0.06, light: [0.62, 0.9] });
const wallW = P.hueRamp(3, { hue: 210, shift: 12, sat: 0.06, light: [0.8, 0.95] });
const steelB = P.hueRamp(4, { hue: 210, shift: 18, sat: 0.16, light: [0.32, 0.64] });
const steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.1, light: [0.36, 0.84] });
const white = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.08, light: [0.6, 0.96] });
const dark = P.hueRamp(4, { hue: 226, shift: 16, sat: 0.14, light: [0.12, 0.34] });
const LED = [[120, 240, 140], [255, 200, 90], [110, 190, 255]];

// ---- podłoga: jasne płytki 20x12 z fugą
for (let y = WALL; y < 348; y++) for (let x = 0; x < W; x++) {
  const ty = Math.floor((y - WALL) / 12), ry = (y - WALL) % 12, rx = (x + (ty % 2) * 10) % 20;
  let c = tile[P.hash(ty, Math.floor((x + (ty % 2) * 10) / 20), 3) > 0.94 ? 2 : 3];
  if (ry === 0 || rx === 0) c = tile[1];
  if (ry === 1) c = tile[3];
  b.pset(x, y, c);
}
// ---- ściana: białe panele, szary cokół, kanał wentylacyjny i rury pod sufitem
slab(b, 0, 0, W, 100, wallW, 0.8, 0.6, { grain: 0 });
for (let x = 0; x < W; x += 40) b.rect(x, 24, x + 1, 100, wallW[0]);                              // łączenia paneli
b.rect(0, 58, W, 61, steelB[2]); b.rect(0, 61, W, 62, steelB[1]);                               // pas na ścianie
slab(b, 0, 100, W, 108, steel, 0.5, 0.4, { grain: 0 });                                          // cokół
slab(b, 0, 106, W, WALL, R.gray, 0.35, 0.2, { grain: 0 });
slab(b, 0, WALL, W, WALL + 4, tile, 0.2, 0.4, { grain: 0 });
slab(b, 0, 12, W, 22, steel, 0.85, 0.45, { grain: 0 });                                          // kanał wentylacyjny
for (let x = 20; x < W; x += 60) { b.rect(x, 12, x + 2, 22, steel[0]); b.rect(x + 2, 22, x + 3, 25, steel[0]); }
b.rect(0, 23, W, 25, [196, 120, 70]); b.rect(0, 23, W, 24, [226, 160, 110]);                      // miedziana rura
const cap = (x0, y0, x1, y1) => b.rect(x0, y0, x1, y1, [58, 36, 58]);
cap(0, 0, W, 10); b.rect(0, 10, W, 11, [86, 58, 82]);
cap(0, 0, 12, H); cap(628, 0, W, H); cap(0, 348, W, H); b.rect(12, 348, 628, 349, [86, 58, 82]);
// ---- żółto-czarny pas bezpieczeństwa wokół platformy teleskopu, stalowa platforma z nitami
for (let y = 190; y < 302; y++) for (let x = 372; x < 568; x++) {
  const d = ((x - 470) / 94) ** 2 + ((y - 246) / 48) ** 2;
  if (d > 1) continue;
  let c;
  if (d > 0.86) c = Math.floor((x + y) / 5) % 2 ? [250, 200, 50] : [40, 36, 46];
  else if (d > 0.8) c = steel[0];
  else { c = steel[P.band(0.62 - (y - 204) / 260, 4, x, y)]; if (Math.round(x + y * 2) % 22 === 0 && d < 0.7) c = steel[1]; }
  b.pset(x, y, c);
}
for (let a = 0; a < 6.28; a += 0.26) b.pset(Math.round(470 + Math.cos(a) * 80), Math.round(246 + Math.sin(a) * 39), steel[3]);
// ---- okno (geometria jak w pokoju: szyby rysuje world.gd), biała rama, bez zasłon
obj(b, 152, 22, 78, 60, (s) => {
  slab(s, 6, 2, 72, 56, white, 0.8, 0.6, { grain: 0 });
  slab(s, 11, 7, 67, 51, R.navy, 0.75, 0.35, { grain: 0 });
  s.rect(38, 7, 40, 51, white[3]); s.rect(11, 28, 67, 30, white[3]);
  slab(s, 3, 52, 75, 57, steel, 0.8, 0.5, { grain: 0 });
});
// ---- drzwi do pokoiku Jani (ciepłe drewno, gwiazdka na tabliczce) i tablica z obliczeniami
obj(b, 24, 26, 40, 88, (s) => {
  slab(s, 0, 0, 40, 88, R.woodL, 0.7, 0.55);
  slab(s, 5, 6, 35, 40, R.woodL, 0.45, 0.4); slab(s, 5, 46, 35, 82, R.woodL, 0.45, 0.4);
  s.rect(12, 18, 28, 28, R.cream[2]); s.rect(19, 20, 21, 26, R.gold[2]); s.rect(16, 22, 24, 24, R.gold[2]);   // tabliczka z gwiazdką
  s.rect(31, 46, 35, 48, R.gold[2]);
});
obj(b, 80, 30, 60, 40, (s) => {
  slab(s, 0, 0, 60, 40, steel, 0.7, 0.5, { grain: 0 }); slab(s, 2, 2, 58, 36, [[226, 232, 240], [240, 244, 250], [252, 252, 255]], 0.8, 0.6, { grain: 0 });
  const ink = [60, 80, 160], red = [200, 70, 70];
  s.line(6, 8, 20, 8, ink); s.line(6, 13, 26, 13, ink); s.line(6, 18, 16, 18, red); s.line(32, 8, 52, 26, ink);
  for (let a = 0; a < 6.28; a += 0.1) s.pset(Math.round(44 + Math.cos(a) * 7), Math.round(17 + Math.sin(a) * 4), ink);
  s.pset(44, 17, red); s.line(6, 26, 24, 26, ink); s.rect(10, 36, 50, 38, steel[1]);
}, { lit: steel[2] });
// ---- drzwi wejściowe (geometria i szyby jak drzwi balkonowe w pokoju), stalowe
obj(b, 520, 26, 42, 88, (s) => {
  slab(s, 0, 0, 42, 88, steel, 0.7, 0.5);
  for (const [x0, y0] of [[5, 5], [22, 5], [5, 28], [22, 28]]) {
    slab(s, x0, y0, x0 + 15, y0 + 20, R.navy, 0.8, 0.5);
    for (let i = 0; i < 6; i++) s.pset(x0 + 3 + i, y0 + 10 - i, R.navy[3]);
  }
  slab(s, 5, 54, 37, 82, steel, 0.4, 0.35); s.rect(5, 54, 37, 55, steel[3]);
  s.rect(4, 62, 38, 66, [250, 200, 50]);                                                           // żółty pas
  s.rect(34, 46, 38, 48, steel[0]); s.rect(36, 48, 38, 52, steel[0]);
});
b.rect(512, 112, 570, 118, [80, 84, 96]); b.rect(513, 113, 569, 117, [110, 116, 130]);              // wycieraczka

// ---- stanowisko komputerowe: biały stół laboratoryjny; CRT, blaszak, klawiatura i lampka w miejscach z pokoju
shadow(b, 380, 134, 44, 5);
piece("desk", 134, [334, 104, 428, 138], (T) => {
  obj(T, 338, 92, 86, 42, (s) => {
    slab(s, 0, 0, 86, 20, white, 1, 0.9); slab(s, 0, 20, 86, 26, white, 0.33, 0.33);
    slab(s, 2, 26, 30, 40, steel, 0.5, 0.35); slab(s, 80, 26, 84, 40, steel, 0.4, 0.3);
  });
  for (const [y, h] of [[118, 6], [125, 7]]) obj(T, 340, y, 28, h, (s) => { slab(s, 0, 0, 28, h, steel, 0.67, 0.67); s.rect(10, 2, 18, 3, steel[3]); });
  obj(T, 350, 70, 26, 28, (s) => {
    slab(s, 0, 0, 26, 26, R.beige, 0.67, 0.67); s.rect(1, 0, 25, 1, R.beige[3]);
    slab(s, 3, 3, 23, 20, R.screen, 0.2, 0.15); s.rect(4, 4, 8, 5, R.screen[2]);
    s.rect(20, 22, 22, 23, [120, 230, 120]); s.rect(6, 26, 20, 28, R.beige[1]);
  });
  obj(T, 380, 74, 14, 30, (s) => { slab(s, 0, 0, 14, 30, R.gray, 0.67, 0.67); s.rect(0, 0, 14, 1, R.gray[3]); s.rect(2, 6, 12, 8, R.gray[0]); s.rect(2, 11, 12, 12, R.gray[1]); s.pset(10, 26, [120, 230, 120]); });
  obj(T, 352, 101, 22, 6, (s) => { slab(s, 0, 0, 22, 6, R.beige, 1, 1); for (let x = 1; x < 21; x += 2) { s.pset(x, 2, R.beige[1]); s.pset(x + 1, 4, R.beige[1]); } });
  obj(T, 398, 102, 7, 6, (s) => { s.rect(0, 0, 7, 6, R.navy[3]); s.rect(1, 0, 5, 2, R.gray[3]); });
  obj(T, 406, 74, 12, 28, (s) => { s.rect(5, 6, 7, 26, steel[1]); s.rect(2, 25, 10, 28, steel[1]); slab(s, 0, 0, 12, 8, steel, 0.85, 0.5); }, { lit: steel[2] });
});
piece("chair", 148, [356, 132, 390, 152], (T) => {  // krzesło biurowe na kółkach
  obj(T, 360, 116, 26, 32, (s) => {
    slab(s, 2, 0, 24, 14, dark, 0.7, 0.45); s.rect(2, 0, 24, 1, dark[3]);
    slab(s, 0, 14, 26, 20, dark, 0.55, 0.4);
    s.rect(12, 20, 14, 28, steel[1]); s.rect(4, 28, 22, 30, steel[1]); s.pset(4, 31, dark[0]); s.pset(21, 31, dark[0]);
  });
});
// ---- szafy serwerowe z mrugającymi diodami
shadow(b, 470, 124, 32, 4);
piece("racks", 124, [440, 108, 502, 128], (T) => {
  for (const x0 of [442, 472]) obj(T, x0, 30, 28, 94, (s) => {
    slab(s, 0, 0, 28, 6, dark, 0.9, 0.8); slab(s, 0, 6, 28, 94, dark, 0.45, 0.3);
    for (let y = 10; y < 88; y += 8) { s.rect(3, y, 25, y + 6, dark[1]); s.rect(3, y, 25, y + 1, dark[2]); s.pset(5, y + 3, LED[(y + x0) % 3]); s.pset(8, y + 3, LED[(Math.floor(y / 8) + 1) % 3]); s.rect(14, y + 2, 23, y + 4, dark[0]); }
  });
});
// ---- spektrograf: szara szafa z ekranem widma, pokrętła, kable do ściany
shadow(b, 270, 126, 30, 4);
piece("spectro", 126, [242, 110, 300, 130], (T) => {
  obj(T, 244, 66, 54, 60, (s) => {
    slab(s, 0, 0, 54, 10, steel, 0.95, 0.8); slab(s, 0, 10, 54, 60, steel, 0.5, 0.35);
    slab(s, 6, 14, 48, 32, dark, 0.3, 0.2);
    for (let x = 8; x < 46; x++) { const c = P.hsl(280 - (x - 8) * 7, 0.7, 0.55); s.pset(x, 28, c); s.pset(x, 29, c); }  // tęcza widma
    for (let x = 8; x < 46; x++) s.pset(x, Math.round(22 - 6 * Math.exp(-(((x - 30) / 4) ** 2)) - 2 * Math.exp(-(((x - 16) / 3) ** 2))), [120, 240, 140]);
    for (const x of [10, 20, 30, 40]) { P.solid(s, [P.ell(x + 2, 42, 3, 3)], R.gray); s.pset(x + 2, 40, R.gray[0]); }
    s.rect(6, 50, 48, 54, dark[1]); s.pset(44, 52, LED[0]); s.pset(40, 52, LED[1]);
  });
});
// mały teleskop na trójnogu w buforze 30x50: nogi o równych schodkach 1:2, tuba pod 45° z obejmą i osłoną
const scopeOn = (s, ramp) => {
  s.line(15, 26, 5, 46, steel[1]); s.line(15, 26, 25, 46, steel[1]); s.rect(15, 26, 16, 48, steel[1]);
  s.rect(4, 46, 7, 48, steel[0]); s.rect(24, 46, 27, 48, steel[0]);
  s.rect(13, 20, 18, 26, steel[1]);
  tube45(s, 7, 23, -1, 0, 3, steel); tube45(s, 7, 23, 0, 12, 4, ramp); tube45(s, 7, 23, 3, 4, 5, steel); tube45(s, 7, 23, 12, 16, 5, steel);
};
// ---- duży teleskop na kolumnie: biała tuba skierowana w górę, w stronę szczeliny kopuły
shadow(b, 470, 262, 24, 6);
piece("telescope", 262, [452, 254, 488, 266], (T) => {
  obj(T, 452, 196, 36, 70, (s) => {
    slab(s, 8, 18, 28, 68, steel, 0.6, 0.35);
    s.rect(8, 18, 28, 20, steel[3]);
    slab(s, 2, 62, 34, 70, steel, 0.5, 0.3);
    slab(s, 4, 2, 10, 24, steel, 0.7, 0.45); slab(s, 26, 2, 32, 24, steel, 0.7, 0.45);
    s.rect(14, 40, 22, 44, [255, 214, 92]);
  });
  const tube = new P.Buf(640, 360);
  // tuba dokładnie pod 45°: tylna cela, biała tuba z obejmami, osłona przeciwrosowa z ciemnym wlotem, szukacz
  tube45(tube, 472, 180, 6, 7, 6, steel, -1); tube45(tube, 472, 180, 14, 15, 6, steel, -1);  // wsporniki szukacza
  tube45(tube, 490, 218, -4, 2, 11, steel, -1);
  tube45(tube, 490, 218, 2, 56, 15, white, -1);
  for (const st of [8, 32]) tube45(tube, 490, 218, st, st + 2, 17, steel, -1);
  tube45(tube, 490, 218, 56, 70, 18, steel, -1);
  tube45(tube, 490, 218, 69, 70, 15, [dark[0], dark[0], dark[0], dark[0]], -1);
  tube45(tube, 476, 184, 0, 16, 3, steel, -1);
  tube45(tube, 476, 184, 16, 18, 4, dark, -1);
  T.sprite(P.outline(tube, [18, 12, 22], { corners: true }), -1, -1);
});
// ---- biurko Arbjooze: biały stolik laboratoryjny, mała klawiatura, kubek mleczka, notatki; obok teleskop pomocniczy
shadow(b, 168, 300, 34, 5);
piece("catdesk", 300, [134, 280, 202, 304], (T) => {
  obj(T, 136, 266, 64, 36, (s) => {
    slab(s, 0, 0, 64, 14, white, 1, 0.9); slab(s, 0, 14, 64, 20, white, 0.33, 0.33);
    slab(s, 2, 20, 6, 34, steel, 0.4, 0.3); slab(s, 58, 20, 62, 34, steel, 0.4, 0.3);
  });
  obj(T, 146, 270, 18, 6, (s) => { slab(s, 0, 0, 18, 6, R.beige, 1, 1); for (let x = 1; x < 17; x += 2) { s.pset(x, 2, R.beige[1]); s.pset(x + 1, 4, R.beige[1]); } });
  obj(T, 174, 262, 8, 10, (s) => { slab(s, 0, 0, 8, 10, [[230, 230, 236], [244, 244, 250], [255, 255, 255]], 0.8, 0.5); s.rect(1, 1, 7, 3, [250, 246, 236]); });
  obj(T, 184, 268, 12, 8, (s) => { s.rect(0, 0, 12, 8, R.cream[2]); s.rect(2, 2, 10, 3, R.gray[1]); s.rect(2, 5, 8, 6, R.gray[1]); });
});
shadow(b, 226, 300, 12, 3);
piece("aux", 300, [216, 292, 238, 304], (T) => {
  obj(T, 212, 252, 30, 50, (s) => {
    scopeOn(s, white);
  });
});
// ---- lobby: podium ze starym teleskopem z balkonu (pamiątka)
shadow(b, 322, 336, 28, 4);
piece("podium", 336, [300, 326, 344, 338], (T) => {
  obj(T, 298, 304, 48, 32, (s) => {
    slab(s, 0, 0, 48, 10, white, 1, 0.9); slab(s, 2, 10, 46, 32, steel, 0.6, 0.35);
    s.rect(14, 18, 34, 24, R.gold[2]); s.rect(16, 20, 32, 22, R.gold[0]);
  });
  T.sprite(require("./kit.js").cheapScope(), 303, 264);  // ten sam co na balkonie, bez nocnego przyciemnienia
});

// ---- elementy kupowane w Etapie 2 (layout: "opt" = id zakupu; pokazują się po otwarciu paczki)
const deskAt = (T, x0, y0, extra) => {  // biały stolik laboratoryjny 64x36 (jak biurko Arbjooze)
  obj(T, x0, y0, 64, 36, (s) => {
    slab(s, 0, 0, 64, 14, white, 1, 0.9); slab(s, 0, 14, 64, 20, white, 0.33, 0.33);
    slab(s, 2, 20, 6, 34, steel, 0.4, 0.3); slab(s, 58, 20, 62, 34, steel, 0.4, 0.3);
  });
  extra(T);
};
const auxScope = (T, x0, y0, hue) => obj(T, x0, y0, 30, 50, (s) => {  // mały teleskop na trójnogu
  scopeOn(s, P.hueRamp(4, { hue, shift: 20, sat: 0.5, light: [0.34, 0.66] }));
});
const logbook = (T, x, y) => obj(T, x, y, 14, 8, (s) => { s.rect(0, 0, 14, 8, R.cream[2]); s.rect(7, 0, 8, 8, R.cream[0]); s.rect(2, 2, 6, 3, R.gray[1]); s.rect(9, 4, 12, 5, R.gray[1]); });
for (const [k, x0, y0, hue] of [["st_obs1", 20, 150, 200], ["st_obs2", 20, 236, 140]]) {  // stanowiska obserwacyjne (Tryb 1)
  piece(k, y0 + 41, [x0, y0 + 20, x0 + 96, y0 + 41], (T) => deskAt(T, x0 + 2, y0 + 4, (T) => { logbook(T, x0 + 12, y0 + 8); auxScope(T, x0 + 66, y0 - 8, hue); }));
}
for (const [k, x0, y0] of [["st_an1", 384, 296], ["st_an2", 476, 296]]) {  // biurka analityków (Tryb 2): monitor, wydruki, kubek
  piece(k, y0 + 41, [x0, y0 + 20, x0 + 66, y0 + 41], (T) => deskAt(T, x0 + 2, y0 + 4, (T) => {
    obj(T, x0 + 8, y0 - 10, 20, 18, (s) => { slab(s, 0, 0, 20, 14, dark, 0.6, 0.4); s.rect(2, 2, 18, 12, [40, 70, 110]); for (let x = 3; x < 17; x++) s.pset(x, 7 - Math.round(2 * Math.sin(x * 0.7)), [120, 240, 140]); s.rect(8, 14, 12, 18, steel[1]); });  // wykres w ekranie (y 5..9, ekran 2..11)
    obj(T, x0 + 34, y0 + 4, 16, 8, (s) => { s.rect(0, 0, 16, 8, [250, 250, 252]); for (let y = 2; y < 7; y += 2) s.rect(2, y, 13, y + 1, R.gray[1]); });
    obj(T, x0 + 54, y0 + 2, 6, 7, (s) => { s.rect(0, 0, 6, 7, R.red[2]); s.rect(1, 0, 5, 1, [90, 50, 30]); });
  }));
}
piece("st_ws1", 192, [560, 172, 626, 192], (T) => {  // warsztat techniczny (Tryb 3): blat, imadło, tablica z narzędziami
  obj(T, 562, 120, 62, 26, (s) => {
    slab(s, 0, 0, 62, 26, steelB, 0.6, 0.4); for (let x = 4; x < 60; x += 4) for (let y = 4; y < 24; y += 4) s.pset(x, y, steelB[0]);
    const tools = [[6, 6, 8, 18, R.red[2]], [4, 4, 10, 7, R.gray[1]], [16, 8, 18, 20, R.gold[2]], [26, 6, 34, 9, R.gray[2]], [29, 9, 31, 20, R.wood[1]],
      [42, 6, 44, 20, steel[1]], [40, 18, 46, 21, steel[0]], [52, 8, 56, 12, [250, 200, 50]]];
    for (const [x0, y0, x1, y1] of tools) s.rect(x0 - 1, y0 - 1, x1 + 1, y1 + 1, INK);  // obrys narzędzi: odcinają się od blachy
    for (const [x0, y0, x1, y1, c] of tools) s.rect(x0, y0, x1, y1, c);
  });
  obj(T, 562, 150, 62, 40, (s) => {
    slab(s, 0, 0, 62, 12, R.woodL, 1, 0.9); slab(s, 0, 12, 62, 18, R.woodL, 0.33, 0.33);
    slab(s, 2, 18, 8, 40, steel, 0.4, 0.3); slab(s, 54, 18, 60, 40, steel, 0.4, 0.3); slab(s, 8, 22, 54, 26, steel, 0.4, 0.3);
    s.rect(40, 2, 52, 8, steel[1]); s.rect(44, 0, 48, 2, steel[2]);
  });
});
piece("ekspres", 124, [300, 108, 330, 124], (T) => {  // ekspres do kawy na szafce przy ścianie
  obj(T, 300, 92, 30, 32, (s) => { slab(s, 0, 0, 30, 6, white, 1, 0.9); slab(s, 0, 6, 30, 32, white, 0.4, 0.3); s.rect(14, 12, 16, 28, steel[0]); });
  obj(T, 304, 70, 22, 24, (s) => {
    slab(s, 0, 0, 22, 24, dark, 0.7, 0.4); s.rect(3, 3, 19, 7, steel[2]); s.rect(9, 9, 13, 13, steel[1]);
    s.rect(7, 16, 15, 22, [240, 240, 244]); s.rect(8, 17, 14, 19, [110, 70, 40]); s.pset(17, 4, LED[0]);
  });
});
piece("legowisko", 318, [242, 304, 276, 318], (T) => {  // okrągłe legowisko dla Arbjooze
  for (let y = 300; y < 320; y++) for (let x = 240; x < 280; x++) {
    const d = ((x - 259.5) / 19) ** 2 + ((y - 310) / 9) ** 2;
    if (d <= 1) T.pset(x, y, d > 0.55 ? (y < 308 ? [190, 120, 150] : [160, 96, 128]) : [236, 210, 220]);
  }
  for (let x = 252; x < 268; x++) T.pset(x, 308, [214, 186, 198]);
});
piece("nas", 124, [502, 112, 518, 124], (T) => obj(T, 502, 80, 16, 44, (s) => {  // macierz NAS obok szaf serwerowych
  slab(s, 0, 0, 16, 44, dark, 0.5, 0.3); for (let y = 4; y < 40; y += 6) { s.rect(2, y, 14, y + 4, dark[1]); s.pset(3, y + 2, LED[(y / 6) % 3 | 0]); }
}));
piece("pogoda", 60, [300, 50, 330, 60], (T) => obj(T, 300, 28, 30, 22, (s) => {  // ekran pogody kosmicznej na ścianie
  slab(s, 0, 0, 30, 22, dark, 0.7, 0.4); s.rect(2, 2, 28, 20, [20, 26, 50]);
  P.solid(s, [P.ell(9, 11, 4, 4)], P.hueRamp(3, { hue: 40, shift: 16, sat: 0.9, light: [0.5, 0.75] }));
  for (let a = -0.8; a < 0.8; a += 0.1) s.pset(Math.round(9 + Math.cos(a) * 9), Math.round(11 + Math.sin(a) * 6), [255, 150, 60]);
  s.rect(22, 6, 26, 7, LED[0]); s.rect(22, 10, 26, 11, LED[1]); s.rect(22, 14, 24, 15, LED[0]);
}, { lit: steel[2] }));
piece("montaz", 178, [148, 158, 206, 178], (T) => {  // stanowisko montażu satelitów: stół i satelita w budowie
  obj(T, 148, 148, 58, 30, (s) => { slab(s, 0, 0, 58, 10, white, 1, 0.9); slab(s, 0, 10, 58, 16, white, 0.33, 0.33); slab(s, 2, 16, 6, 30, steel, 0.4, 0.3); slab(s, 52, 16, 56, 30, steel, 0.4, 0.3); });
  obj(T, 162, 126, 30, 26, (s) => {
    s.rect(10, 6, 20, 20, [220, 224, 232]); s.rect(10, 6, 20, 8, [250, 250, 255]); s.rect(14, 1, 16, 6, steel[1]); s.rect(12, 0, 18, 1, R.gold[2]);
    for (const x0 of [0, 21]) { s.rect(x0, 9, x0 + 9, 17, [50, 80, 170]); for (let x = x0 + 2; x < x0 + 9; x += 2) s.rect(x, 9, x + 1, 17, [80, 120, 220]); }
    s.rect(9, 12, 21, 14, steel[0]); s.rect(10, 20, 20, 26, steel[1]);
  });
});

light(b, (x, y) => (y > WALL + 2 && y < 250 && x > 174 + (y - WALL) * 0.55 && x < 236 + (y - WALL) * 0.55 ? Math.min(1, (250 - y) / 40) : 0), [255, 246, 220], 0.14);
P.save(b, out + "/base.png");
savePieces(out, "base");
const lay = JSON.parse(fs.readFileSync(out + "/base_layout.json"));
const room = JSON.parse(fs.readFileSync(out + "/room_layout.json"));
lay.push(room.find((p) => p.name === "room_box"));  // karton z rzeczami z przeprowadzki (na nim radio)
const OPT = { st_obs1: "st_obs", st_obs2: "st_obs2", st_an1: "st_analiza", st_an2: "st_analiza2", st_ws1: "st_warsztat",
  ekspres: "ekspres", legowisko: "legowisko", nas: "nas", pogoda: "pogoda", montaz: "montaz_sat" };
for (const p of lay) {
  const k = p.name.replace("base_", "");
  if (OPT[k]) p.opt = OPT[k];
  if (["telescope", "podium", "aux", "legowisko", "st_obs1", "st_obs2", "st_an1", "st_an2", "st_ws1", "montaz"].includes(k)) p.footcol = true;  // kolider tylko pod stopą (da się przejść za)
  if (k === "pogoda") p.nocol = true;
}
fs.writeFileSync(out + "/base_layout.json", JSON.stringify(lay, null, 1));
console.log("base.png", lay.length, "obiektów");
