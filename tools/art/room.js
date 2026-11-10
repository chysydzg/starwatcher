// Pokój Jani – jeden ekran 640x360, top-down 3/4. Kolory dzienne; noc robi Godot (CanvasModulate + światła).
const { P, R, slab, obj, shadow, light, piece, savePieces } = require("./kit.js");
const W = 640, H = 360, WALL = 112;
const b = new P.Buf(W, H);

// ---- podłoga: płaskie deski 9px, dwa tony + rzadkie sęki, ciemna fuga
for (let y = WALL; y < 348; y++) {
  const row = Math.floor((y - WALL) / 9), ry = (y - WALL) % 9;
  for (let x = 0; x < W; x++) {
    const seg = Math.floor((x + row * 41) / 104), seam = (x + row * 41) % 104 === 0;
    let c = R.floor[P.hash(row, seg, 3) > 0.7 ? 1 : 2];
    if (ry === 0) c = R.floor[3];
    if (ry === 8 || seam) c = R.floor[0];
    if (P.hash(x >> 2, row, 9) > 0.995 && ry > 2 && ry < 6) c = R.floor[1];
    b.pset(x, y, c);
  }
}
// ---- ściana: tapeta w gwiazdki, boazeria, listwa
slab(b, 0, 0, W, 82, R.teal, 0.55, 0.62, { grain: 0.05, sx: 0.02, sy: 0.02 });
for (let y = 16; y < 80; y += 12)
  for (let x = ((y / 12) % 2) * 9; x < W; x += 18) {
    b.pset(x, y, R.cream[1]); b.pset(x - 1, y, R.teal[3]); b.pset(x + 1, y, R.teal[3]); b.pset(x, y - 1, R.teal[3]); b.pset(x, y + 1, R.teal[3]);
  }
b.rect(0, 82, W, 108, R.woodL[2]);
for (let x = 0; x < W; x += 32) { b.rect(x + 4, 87, x + 28, 88, R.woodL[1]); b.rect(x + 4, 88, x + 5, 104, R.woodL[1]); b.rect(x + 5, 103, x + 28, 104, R.woodL[3]); b.rect(x + 27, 88, x + 28, 103, R.woodL[3]); }
b.rect(0, 82, W, 84, R.woodL[4]);
slab(b, 0, 106, W, WALL, R.wood, 0.35, 0.2, { grain: 0.05 });
slab(b, 0, WALL, W, WALL + 4, R.wood, 0.12, 0.3, { grain: 0 }); // cień pod ścianą
// ---- czapy ścian (widok z góry)
const cap = (x0, y0, x1, y1) => { b.rect(x0, y0, x1, y1, [58, 36, 58]); };
cap(0, 0, W, 10); b.rect(0, 10, W, 11, [86, 58, 82]);
cap(0, 0, 12, H); cap(628, 0, W, H); cap(0, 348, W, H); b.rect(12, 348, 628, 349, [86, 58, 82]);

// ---- dywan w gwiazdy
for (let y = 186; y < 290; y++)
  for (let x = 196; x < 410; x++) {
    const d = ((x - 303) / 86) ** 2 + ((y - 238) / 42) ** 2;
    if (d > 1) continue;
    let c = R.navy[P.band(0.55 - d * 0.25 + (P.fbm(x * 0.2, y * 0.2, 2, 9) - 0.5) * 0.2, 5, x, y)];
    if (d > 0.82) c = R.red[P.band(0.6 - (d - 0.82) * 2, 5, x, y)];
    else if (d > 0.76) c = R.gold[1];
    b.pset(x, y, c);
  }
for (const [sx, sy] of [[250, 220], [300, 210], [352, 228], [280, 252], [330, 258], [240, 245], [370, 250], [305, 236]]) {
  b.pset(sx, sy, R.gold[3]); b.pset(sx - 1, sy, R.gold[1]); b.pset(sx + 1, sy, R.gold[1]); b.pset(sx, sy - 1, R.gold[1]); b.pset(sx, sy + 1, R.gold[1]);
}

// ---- okno z zasłonami (szyba ciemnogranatowa; gwiazdy i księżyc dorysowuje Godot)
obj(b, 152, 22, 78, 60, (s) => {
  slab(s, 0, 0, 78, 3, R.wood, 0.3, 0.3, { grain: 0 });
  slab(s, 8, 4, 70, 54, R.woodL, 0.7, 0.55, { grain: 0.1 });
  slab(s, 11, 7, 67, 51, R.navy, 0.75, 0.35, { grain: 0.04 });
  s.rect(38, 7, 40, 51, R.woodL[3]); s.rect(11, 28, 67, 30, R.woodL[3]);
  for (let i = 0; i < 9; i++) { s.pset(15 + i, 20 - i, R.navy[4]); s.pset(45 + i, 46 - i, R.navy[4]); }
  slab(s, 0, 3, 10, 58, R.red, 0.65, 0.35, { tex: 1, grain: 0.4, sx: 0.9, sy: 0.05 });
  slab(s, 68, 3, 78, 58, R.red, 0.6, 0.3, { tex: 1, grain: 0.4, sx: 0.9, sy: 0.05 });
  slab(s, 6, 52, 72, 57, R.cream, 0.7, 0.3, { grain: 0 });
});
// ---- plakat z gwiazdozbiorem
obj(b, 250, 28, 28, 38, (s) => {
  slab(s, 0, 0, 28, 38, R.cream, 0.6, 0.45, { grain: 0.05 });
  slab(s, 2, 2, 26, 36, R.navy, 0.6, 0.3, { grain: 0.08 });
  const pts = [[6, 10], [11, 7], [17, 12], [22, 8], [19, 22], [8, 26]];
  for (let i = 0; i < pts.length - 1; i++) s.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], R.navy[4]);
  for (const [x, y] of pts) s.pset(x, y, R.gold[3]);
  s.rect(4, 30, 24, 32, R.gold[1]);
}, { lit: R.cream[1] });
// ---- półka z książkami
obj(b, 292, 40, 52, 22, (s) => {
  const cols = [R.red, R.teal, R.gold, R.green, R.purple, R.navy, R.red, R.beige];
  let x = 2;
  for (let i = 0; x < 46; i++) {
    const w = 3 + (i * 7) % 3, h = 11 + (i * 5) % 6, c = cols[i % cols.length];
    if (i === 6) { slab(s, x, 16 - 4, x + 9, 16, c, 0.6, 0.4, { grain: 0 }); x += 10; continue; } // leżąca
    slab(s, x, 16 - h, x + w, 16, c, 0.65, 0.45, { grain: 0 });
    s.rect(x, 16 - h + 2, x + w, 16 - h + 3, R.gold[2]);
    x += w;
  }
  slab(s, 0, 16, 52, 19, R.woodL, 0.7, 0.4, { grain: 0 });
  s.rect(4, 19, 6, 22, R.wood[1]); s.rect(46, 19, 48, 22, R.wood[1]);
});
// ---- model układu słonecznego z podstawówki (wisi na ścianie obok łóżka)
obj(b, 132, 12, 34, 50, (s) => {
  s.rect(17, 0, 18, 20, R.gray[2]);
  for (let a = 0; a < 6.28; a += 0.02) { s.pset(17 + Math.cos(a) * 15, 30 + Math.sin(a) * 6, R.beige[2]); s.pset(17 + Math.cos(a) * 9, 30 + Math.sin(a) * 3.6, R.beige[2]); }
  P.solid(s, [P.ell(17, 30, 4, 4)], R.gold);
  P.solid(s, [P.ell(3, 31, 2, 2)], R.red); P.solid(s, [P.ell(26, 32, 2.2, 2.2)], R.teal); P.solid(s, [P.ell(30, 27, 1.6, 1.6)], R.beige);
  P.solid(s, [P.ell(9, 27, 2.5, 2.5)], R.woodL); s.line(5, 28, 13, 26, R.beige[3]);
}, { outline: false });
shadow(b, 56, 190, 44, 6);
piece("bed", 190, [12, 96, 100, 196], (T) => {
// ---- łóżko z kołdrą „Gwiezdna Noc” (szersze, krótsze)
obj(T, 16, 74, 80, 116, (s) => {
  slab(s, 0, 0, 80, 26, R.wood, 0.65, 0.4); s.rect(4, 4, 76, 5, R.wood[3]); // wezgłowie
  for (const x0 of [5, 41]) { slab(s, x0, 22, x0 + 34, 38, R.cream, 0.9, 0.5); s.rect(x0, 22, x0 + 34, 23, R.cream[2]); }
  for (let y = 36; y < 104; y++)
    for (let x = 2; x < 78; x++) {
      const fold = Math.sin(y * 0.16 + x * 0.04) > 0.75 ? -0.12 : 0;
      s.pset(x, y, R.navy[P.band(0.62 - (y - 36) / 260 + fold - (x < 5 || x > 74 ? 0.3 : 0), 4, x, y, 0.18)]);
    }
  s.rect(2, 36, 78, 39, R.navy[3]);
  const rg = P.rng(5);
  for (let i = 0; i < 40; i++) { const x = 6 + Math.floor(rg() * 68), y = 42 + Math.floor(rg() * 58); s.pset(x, y, R.gold[2]); if (i % 6 === 0) { s.pset(x - 1, y, R.gold[0]); s.pset(x + 1, y, R.gold[0]); s.pset(x, y - 1, R.gold[0]); s.pset(x, y + 1, R.gold[0]); } }
  slab(s, 0, 102, 80, 114, R.wood, 0.5, 0.25); s.rect(2, 104, 78, 105, R.wood[3]);
});
});
shadow(b, 113, 128, 15, 4);
piece("nightstand", 128, [96, 108, 132, 146], (T) => {  // stopa niżej: Jania nie wkłada uszu w lampkę
// ---- szafka nocna: korpus, szuflada i lampka jako osobne obiekty z własnym obrysem
obj(T, 100, 98, 28, 30, (s) => { slab(s, 0, 0, 28, 8, R.woodL, 1, 1); slab(s, 0, 8, 28, 28, R.woodL, 0.33, 0.33); });
obj(T, 103, 110, 22, 7, (s) => { slab(s, 0, 0, 22, 7, R.woodL, 0.67, 0.67); s.rect(10, 3, 12, 4, R.gold[2]); });
obj(T, 103, 119, 22, 7, (s) => { slab(s, 0, 0, 22, 7, R.woodL, 0.67, 0.67); s.rect(10, 3, 12, 4, R.gold[2]); });
obj(T, 106, 82, 16, 19, (s) => { s.rect(7, 8, 9, 18, R.gray[1]); s.rect(3, 17, 13, 19, R.gray[1]); slab(s, 0, 0, 16, 9, R.gold, 0.85, 0.55); s.rect(1, 0, 15, 1, R.gold[2]); }, { lit: R.gold[1] });
});
shadow(b, 380, 134, 44, 5);
piece("desk", 134, [334, 104, 428, 138], (T) => {
// ---- biurko; CRT, blaszak, klawiatura, dyskietki i lampka to osobne obiekty
obj(T, 338, 92, 86, 42, (s) => {
  slab(s, 0, 0, 86, 20, R.woodL, 1, 1); slab(s, 0, 20, 86, 26, R.woodL, 0.33, 0.33);
  slab(s, 2, 26, 30, 40, R.woodL, 0.33, 0.33); slab(s, 80, 26, 84, 40, R.woodL, 0.3, 0.3);
});
for (const [y, h] of [[118, 6], [125, 7]]) obj(T, 340, y, 28, h, (s) => { slab(s, 0, 0, 28, h, R.woodL, 0.67, 0.67); s.rect(12, 2, 16, 3, R.gold[2]); }); // szuflady z obrysem, jak w szafce nocnej
obj(T, 350, 70, 26, 28, (s) => { // CRT 14"
  slab(s, 0, 0, 26, 26, R.beige, 0.67, 0.67); s.rect(1, 0, 25, 1, R.beige[3]);
  slab(s, 3, 3, 23, 20, R.screen, 0.2, 0.15); s.rect(4, 4, 8, 5, R.screen[2]);
  s.rect(20, 22, 22, 23, [120, 230, 120]); s.rect(6, 26, 20, 28, R.beige[1]);
});
obj(T, 380, 74, 14, 30, (s) => { slab(s, 0, 0, 14, 30, R.gray, 0.67, 0.67); s.rect(0, 0, 14, 1, R.gray[3]); s.rect(2, 6, 12, 8, R.gray[0]); s.rect(2, 11, 12, 12, R.gray[1]); s.pset(10, 26, [120, 230, 120]); });
obj(T, 352, 101, 22, 6, (s) => { slab(s, 0, 0, 22, 6, R.beige, 1, 1); for (let x = 1; x < 21; x += 2) { s.pset(x, 2, R.beige[1]); s.pset(x + 1, 4, R.beige[1]); } });
obj(T, 398, 102, 7, 6, (s) => { s.rect(0, 0, 7, 6, R.navy[3]); s.rect(1, 0, 5, 2, R.gray[3]); });
obj(T, 406, 74, 12, 28, (s) => { s.rect(5, 6, 7, 26, R.gray[1]); s.rect(2, 25, 10, 28, R.gray[1]); slab(s, 0, 0, 12, 8, R.gold, 0.85, 0.5); }, { lit: R.gold[1] });
});
piece("chair", 148, [356, 132, 390, 152], (T) => {
// ---- krzesło (widzimy oparcie)
obj(T, 360, 116, 26, 32, (s) => {
  slab(s, 2, 0, 24, 14, R.red, 0.6, 0.4, { grain: 0.1 }); s.rect(2, 0, 24, 1, R.red[4]);
  slab(s, 0, 14, 26, 22, R.wood, 0.55, 0.4, { grain: 0.1 });
  s.rect(2, 22, 5, 31, R.wood[1]); s.rect(21, 22, 24, 31, R.wood[1]);
});
});
shadow(b, 458, 124, 12, 4);
piece("plant", 126, [440, 110, 478, 130], (T) => {
// ---- roślina (monstera) w pomarańczowej doniczce
obj(T, 444, 76, 30, 50, (s) => {
  slab(s, 7, 30, 23, 48, R.red, 0.75, 0.45, { grain: 0.05 }); s.rect(6, 30, 24, 33, R.red[4]);
  for (const [x, y, r] of [[10, 14, 7], [21, 10, 7], [15, 22, 7], [24, 22, 5], [6, 24, 5], [15, 6, 5]]) P.solid(s, [P.ell(x, y, r, r * 0.8)], R.green);
  s.line(15, 30, 10, 16, R.green[1]); s.line(15, 30, 21, 12, R.green[1]);
});
});
shadow(b, 598, 124, 28, 4);
piece("wardrobe", 124, [568, 104, 630, 128], (T) => {
// ---- szafa na odzież: korpus + dwoje drzwi z własnym obrysem
obj(T, 572, 26, 54, 98, (s) => { slab(s, 0, 0, 54, 8, R.woodL, 1, 1); slab(s, 1, 8, 53, 92, R.woodL, 0.33, 0.33); slab(s, 0, 92, 54, 97, R.wood, 0.3, 0.3); });
for (const [x0, h] of [[576, 47], [600, 47]]) obj(T, x0, 37, 22, 80, (s) => {
  slab(s, 0, 0, 22, 80, R.woodL, 0.67, 0.67); s.rect(3, 4, 19, 5, R.woodL[3]); s.rect(3, 75, 19, 76, R.woodL[1]);
  s.rect(x0 < 590 ? 18 : 2, 36, x0 < 590 ? 20 : 4, 44, R.gold[2]);
});
});
// ---- drzwi balkonowe (przeszklone; poświata nocy z zewnątrz w Godot)
obj(b, 520, 26, 42, 88, (s) => {
  slab(s, 0, 0, 42, 88, R.woodL, 0.67, 0.67);
  for (const [x0, y0] of [[5, 5], [22, 5], [5, 28], [22, 28]]) {
    slab(s, x0, y0, x0 + 15, y0 + 20, R.navy, 0.8, 0.5);
    for (let i = 0; i < 6; i++) s.pset(x0 + 3 + i, y0 + 10 - i, R.navy[3]);
  }
  slab(s, 5, 54, 37, 82, R.woodL, 0.33, 0.33); s.rect(5, 54, 37, 55, R.woodL[3]);
  s.rect(34, 46, 38, 48, R.gold[2]); s.rect(36, 48, 38, 52, R.gold[1]);
});
// ---- pufa pod lewą ścianą, stos książek przy biurku
shadow(b, 38, 268, 22, 5);
piece("pufa", 270, [16,248,62,274], (T) => obj(T, 18, 238, 42, 32, (s) => P.solid(s, [P.ell(21, 18, 20, 12), P.ell(21, 12, 15, 9)], R.purple), { lit: R.purple[2] }));
piece("books", 130, [298,116,322,132], (T) => obj(T, 300, 114, 22, 16, (s) => {
  slab(s, 0, 9, 20, 15, R.red, 0.6, 0.4, { grain: 0 }); slab(s, 2, 4, 19, 9, R.teal, 0.6, 0.4, { grain: 0 }); slab(s, 1, 0, 17, 4, R.gold, 0.6, 0.4, { grain: 0 });
  s.rect(0, 11, 20, 12, R.cream[2]); s.rect(2, 6, 19, 7, R.cream[2]);
}));

// ---- gra światła: smuga z okna na podłodze, ciepłe plamy od lamp
light(b, (x, y) => (y > WALL + 2 && y < 250 && x > 174 + (y - WALL) * 0.55 && x < 236 + (y - WALL) * 0.55 ? Math.min(1, (250 - y) / 40) : 0), [255, 236, 190], 0.22);
light(b, (x, y) => { const d = Math.hypot((x - 114) / 46, (y - 112) / 30); return d < 1 ? (1 - d) * 1.6 : 0; }, [255, 200, 120], 0.2);
light(b, (x, y) => { const d = Math.hypot((x - 410) / 40, (y - 96) / 26); return d < 1 ? (1 - d) * 1.6 : 0; }, [255, 200, 120], 0.18);
// ---- lampa stojąca pod ścianą obok okna, karton z rupieciami, kosz z praniem
shadow(b, 236, 128, 9, 3);
piece("lamp", 128, [224,118,248,132], (T) => obj(T, 226, 72, 20, 56, (s) => {
  slab(s, 2, 0, 18, 12, R.cream, 0.85, 0.55, { grain: 0 }); s.rect(3, 0, 17, 1, R.cream[3]);
  s.rect(9, 12, 11, 52, R.gray[1]); slab(s, 4, 51, 16, 55, R.gray, 0.5, 0.3, { grain: 0 });
}, { lit: R.cream[1] }));
shadow(b, 596, 330, 22, 4);
piece("box", 330, [572,312,620,334], (T) => obj(T, 576, 296, 40, 34, (s) => {
  slab(s, 0, 0, 40, 10, R.beige, 0.7, 0.5, { grain: 0.06 }); slab(s, 0, 10, 40, 34, R.beige, 0.45, 0.3, { grain: 0.06 });
  s.rect(18, 0, 22, 10, R.beige[4]); s.rect(6, 16, 30, 18, R.beige[1]);
  P.solid(s, [P.ell(9, 3, 4, 3)], R.teal); s.rect(24, -1, 34, 3, R.gold[2]);
}, { lit: R.beige[2] }));
shadow(b, 46, 330, 16, 4);
piece("basket", 330, [28,314,64,334], (T) => obj(T, 30, 300, 32, 30, (s) => {
  slab(s, 0, 6, 32, 30, R.beige, 0.55, 0.35, { grain: 0.3, sx: 0.8, sy: 0.8 });
  P.solid(s, [P.ell(10, 6, 8, 5), P.ell(22, 5, 8, 5)], R.teal); P.solid(s, [P.ell(17, 3, 6, 3)], R.cream);
}));

P.save(b, process.argv[2] + "/room.png");
savePieces(process.argv[2], "room");
console.log("room.png");
