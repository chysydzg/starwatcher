// Sala szpitalna (koniec intro) – ta sama perspektywa co pokój Jani: 640x360, top-down 3/4, ściana do y 112,
// podłoga niżej, czapy ścian po brzegach. Kolory niebiesko-białe (referencja autora: sala nocą).
// Po prawej łóżko wezgłowiem do ściany, szafka nocna z lampką, monitor serca na stojaku, wózek inwalidzki;
// po lewej drzwi, kanapa, stolik, szafka z telewizorem, kwiatek. Szyba okna przezroczysta: noc, gwiazdy i deszcz
// rysuje gra. Meble to osobne obiekty (sortowanie po podstawie, hospital_layout.json), Maciej w łóżku osobno.
// Uruchom: node hospital.js <katalog wyjściowy>
const { P, slab, obj, shadow, light, piece, savePieces } = require("./kit.js");
const W = 640, H = 360, WALL = 112;
const r = (n, o) => P.hueRamp(n, o);
const C = {
  wall: r(3, { hue: 200, shift: 12, sat: 0.22, light: [0.76, 0.9] }),
  lower: r(3, { hue: 202, shift: 14, sat: 0.32, light: [0.5, 0.66] }),
  floor: r(4, { hue: 206, shift: 12, sat: 0.18, light: [0.62, 0.8] }),
  white: r(4, { hue: 210, shift: 14, sat: 0.14, light: [0.66, 0.96] }),
  steel: r(4, { hue: 218, shift: 16, sat: 0.12, light: [0.36, 0.74] }),
  blue: r(4, { hue: 208, shift: 20, sat: 0.42, light: [0.36, 0.7] }),
  sheet: r(3, { hue: 204, shift: 12, sat: 0.3, light: [0.72, 0.9] }),
  dark: r(3, { hue: 222, shift: 16, sat: 0.3, light: [0.1, 0.26] }),
  green: r(4, { hue: 140, shift: 30, sat: 0.4, light: [0.24, 0.52] }),
  warm: r(3, { hue: 42, shift: 14, sat: 0.8, light: [0.66, 0.86] }),
  fur: r(3, { hue: 220, shift: 10, sat: 0.03, light: [0.6, 0.86] }), // siwy
};
const b = new P.Buf(W, H);
// noc: wszystko chłodniej i ciemniej (lampka i ciepłe piksele zostają, żeby świeciły)
const night = (buf) => { for (let i = 0; i < buf.px.length; i++) { const c = buf.px[i]; if (!c) continue; const [R, G, B] = P.unpack(c); if (R > B + 40) continue; buf.px[i] = P.col([R * 0.58, G * 0.66, B * 0.84].map(Math.round)); } };

// ---- podłoga: płytki 32x16, cienka fuga, co trzecia płytka odrobinę ciemniejsza
for (let y = WALL; y < 348; y++) for (let x = 0; x < W; x++) {
  const tx = Math.floor((x + (Math.floor((y - WALL) / 16) % 2) * 16) / 32), ty = Math.floor((y - WALL) / 16);
  let c = C.floor[(tx + ty) % 3 === 0 ? 2 : 3];
  if ((y - WALL) % 16 === 0 || (x + (ty % 2) * 16) % 32 === 0) c = C.floor[1];
  b.pset(x, y, c);
}
// ---- ściana: jasna góra, niebieska lamperia, biała listwa odbojowa, cień pod ścianą
slab(b, 0, 0, W, 74, C.wall, 0.75, 0.55);
slab(b, 0, 74, W, 106, C.lower, 0.6, 0.45);
b.rect(0, 74, W, 77, C.white[3]); b.rect(0, 77, W, 78, C.white[1]);
slab(b, 0, 106, W, WALL, C.lower, 0.25, 0.1);
slab(b, 0, WALL, W, WALL + 4, C.floor, 0.2, 0.4);
const cap = (x0, y0, x1, y1) => b.rect(x0, y0, x1, y1, [30, 38, 58]);
cap(0, 0, W, 10); b.rect(0, 10, W, 11, [52, 64, 92]);
cap(0, 0, 12, H); cap(628, 0, W, H); cap(0, 348, W, H); b.rect(12, 348, 628, 349, [52, 64, 92]);
// ---- świetlówka nad łóżkiem
obj(b, 470, 30, 84, 6, (s) => { slab(s, 0, 0, 84, 6, C.white, 1, 0.8); s.rect(2, 4, 82, 6, [255, 255, 255]); });
for (let y = 36; y < 70; y++) for (let x = 470; x < 554; x++) { const c = b.get(x, y); if (c) b.pset(x, y, P.mix(P.unpack(c), [236, 248, 255], 0.3 * (1 - (y - 36) / 34))); }
// ---- drzwi otwarte na korytarz (tędy wchodzi Jania)
obj(b, 56, 24, 50, 90, (s) => {
  slab(s, 0, 0, 50, 90, C.white, 0.7, 0.6);
  slab(s, 5, 5, 45, 90, C.dark, 0.9, 0.5);
  slab(s, 5, 70, 45, 90, C.steel, 0.35, 0.5);                    // podłoga korytarza w świetle
  slab(s, 5, 5, 11, 90, C.white, 0.55, 0.45);                    // skrzydło otwarte do środka
  s.rect(8, 44, 10, 48, C.steel[2]);
});
// ---- okno: biała rama, szprosy, parapet; szyba przezroczysta
obj(b, 296, 18, 92, 66, (s) => {
  slab(s, 0, 0, 92, 60, C.white, 0.85, 0.7);
  slab(s, 0, 58, 92, 66, C.white, 0.9, 0.55);
  s.rect(45, 4, 47, 56, C.white[2]);
  s.rect(4, 29, 88, 31, C.white[2]);
});
for (let y = 22; y < 74; y++) for (let x = 300; x < 384; x++) if (!(x >= 341 && x < 343) && !(y >= 47 && y < 49)) b.px[y * W + x] = 0;

// ---- zasłony po bokach okna
for (const cx of [282, 390]) obj(b, cx, 14, 14, 76, (s) => { slab(s, 0, 0, 14, 76, C.blue, 0.75, 0.5); for (const x of [4, 9]) s.rect(x, 2, x + 1, 76, C.blue[1]); });
b.rect(276, 12, 410, 14, C.steel[1]);
night(b);
// ---- światło: lampka nocna (ciepła plama), poświata okna na podłodze
light(b, (x, y) => { const d = Math.hypot((x - 444) / 54, (y - 128) / 34); return d < 1 ? (1 - d) * 1.6 : 0; }, [255, 214, 150], 0.22);
light(b, (x, y) => (y > WALL + 2 && y < 220 && x > 304 + (y - WALL) * 0.35 && x < 382 + (y - WALL) * 0.35 ? Math.min(1, (220 - y) / 40) : 0), [150, 190, 255], 0.12);

// ---- meble
shadow(b, 34, 128, 16, 4);
piece("plant", 128, [16, 112, 54, 132], (T) => obj(T, 20, 74, 30, 54, (s) => {
  slab(s, 7, 34, 23, 52, C.white, 0.85, 0.55); s.rect(6, 34, 24, 37, C.white[3]);
  for (const [x, y, rr] of [[10, 16, 7], [21, 12, 7], [15, 24, 7], [24, 24, 5], [6, 26, 5], [15, 7, 5]]) P.solid(s, [P.ell(x, y, rr, rr * 0.8)], C.green);
  s.line(15, 34, 10, 18, C.green[1]); s.line(15, 34, 21, 14, C.green[1]);
}));
shadow(b, 172, 136, 48, 5);
piece("sofa", 136, [122, 112, 222, 138], (T) => obj(T, 124, 92, 96, 44, (s) => {
  slab(s, 0, 0, 96, 16, C.blue, 0.7, 0.45);                       // oparcie
  slab(s, 0, 16, 96, 34, C.blue, 0.85, 0.6);                      // siedzisko z góry
  s.rect(47, 16, 49, 34, C.blue[1]);
  slab(s, 0, 4, 10, 36, C.blue, 0.6, 0.35); slab(s, 86, 4, 96, 36, C.blue, 0.6, 0.35); // podłokietniki
  slab(s, 0, 34, 96, 41, C.blue, 0.35, 0.2);                      // front
  s.rect(4, 41, 8, 44, C.dark[1]); s.rect(88, 41, 92, 44, C.dark[1]);
  slab(s, 14, 8, 30, 22, C.white, 0.9, 0.6);                      // poduszka
}));
shadow(b, 78, 272, 30, 5);  // stolik w lewym dolnym rogu, z dala od drogi Jani
piece("table", 272, [46, 254, 110, 274], (T) => obj(T, 50, 250, 56, 22, (s) => {
  slab(s, 0, 0, 56, 12, C.white, 0.95, 0.8); slab(s, 0, 12, 56, 15, C.white, 0.5, 0.4);
  s.rect(3, 15, 6, 22, C.steel[1]); s.rect(50, 15, 53, 22, C.steel[1]);
  slab(s, 34, 3, 42, 9, C.sheet, 0.8, 0.5);                       // gazeta
  P.solid(s, [P.ell(14, 6, 3, 2.4)], C.white); s.rect(13, 3, 16, 5, [150, 200, 230]); // kubek
}));
shadow(b, 256, 132, 28, 4);
piece("tv", 132, [228, 114, 284, 134], (T) => {
  obj(T, 230, 100, 52, 32, (s) => { slab(s, 0, 0, 52, 10, C.white, 0.95, 0.8); slab(s, 0, 10, 52, 30, C.white, 0.5, 0.4); s.rect(4, 17, 48, 18, C.white[1]); s.rect(24, 13, 28, 15, C.steel[2]); s.rect(24, 22, 28, 24, C.steel[2]); });
  obj(T, 234, 68, 44, 30, (s) => { slab(s, 0, 0, 44, 26, C.dark, 0.5, 0.4); slab(s, 2, 2, 42, 24, C.dark, 0.9, 0.7); for (let i = 0; i < 7; i++) s.pset(6 + i, 12 - i, C.dark[2]); s.rect(19, 26, 25, 30, C.dark[1]); });
});
shadow(b, 446, 142, 18, 4);
piece("nightstand", 142, [426, 120, 466, 144], (T) => {
  obj(T, 430, 108, 32, 34, (s) => { slab(s, 0, 0, 32, 9, C.white, 1, 0.85); slab(s, 0, 9, 32, 32, C.white, 0.5, 0.42); s.rect(3, 19, 29, 20, C.white[1]); s.rect(14, 14, 18, 16, C.steel[2]); s.rect(14, 24, 18, 26, C.steel[2]); });
  obj(T, 434, 88, 14, 22, (s) => { s.rect(6, 9, 8, 20, C.steel[1]); s.rect(2, 19, 12, 22, C.steel[1]); slab(s, 0, 0, 14, 10, C.warm, 0.9, 0.55); s.rect(1, 0, 13, 1, C.warm[2]); });
  obj(T, 451, 101, 7, 9, (s) => { slab(s, 0, 0, 7, 9, C.sheet, 0.9, 0.6); s.rect(1, 3, 6, 8, [150, 200, 236]); }); // szklanka wody
});
shadow(b, 512, 212, 46, 6);
piece("bed", 212, [466, 104, 560, 214], (T) => obj(T, 468, 82, 90, 130, (s) => {
  slab(s, 0, 0, 90, 30, C.white, 0.75, 0.55); s.rect(4, 4, 86, 6, C.white[3]); s.rect(4, 12, 86, 13, C.white[1]); // wezgłowie
  slab(s, 4, 26, 86, 120, C.sheet, 0.9, 0.7);                     // prześcieradło
  slab(s, 14, 26, 76, 46, C.white, 1, 0.75); s.rect(14, 26, 76, 27, C.white[3]); // poduszka
  s.rect(0, 30, 4, 118, C.steel[2]); s.rect(86, 30, 90, 118, C.steel[2]); // poręcze ramy
  slab(s, 0, 116, 90, 126, C.white, 0.6, 0.4); s.rect(4, 118, 86, 119, C.white[3]); // podnóżek
  for (const x of [4, 80]) s.rect(x, 126, x + 6, 130, C.dark[1]);  // kółka
}));
shadow(b, 576, 160, 16, 4);
piece("monitor", 160, [558, 140, 594, 162], (T) => {
  obj(T, 573, 96, 6, 58, (s) => { s.rect(2, 0, 4, 58, C.steel[2]); }, {});
  obj(T, 566, 152, 20, 6, (s) => { slab(s, 0, 0, 20, 6, C.steel, 0.5, 0.3); s.rect(0, 4, 3, 6, C.dark[1]); s.rect(17, 4, 20, 6, C.dark[1]); }, {}); // podstawa na kółkach
  obj(T, 558, 62, 36, 38, (s) => {
    slab(s, 0, 0, 36, 34, C.steel, 0.55, 0.45); s.rect(1, 0, 35, 1, C.steel[3]);
    s.rect(3, 3, 33, 23, [8, 20, 16]);                                                       // ekran (EKG rysuje gra)
    s.rect(5, 26, 9, 29, [90, 200, 120]); s.rect(12, 26, 16, 29, [220, 90, 80]); s.rect(20, 26, 31, 29, C.dark[1]);
  });
});
// wózek tyłem, jak na balkonie: oparcie, rączki, wąskie duże koła po bokach
shadow(b, 584, 282, 22, 4);
piece("wheelchair", 282, [562, 268, 606, 284], (T) => obj(T, 564, 250, 42, 32, (s) => {
  const M = P.hueRamp(3, { hue: 220, shift: 16, sat: 0.12, light: [0.42, 0.78] }), Tc = [40, 38, 48];
  for (const wx of [5, 36]) P.solid(s, [P.ell(wx, 20, 2.6, 11)], [Tc, [64, 62, 74], [84, 82, 94]], { light: [0, -0.62, 0.78] });
  for (const wx of [5, 36]) for (let y = 11; y < 30; y++) s.pset(wx, y, M[1]);
  for (let y = 7; y < 24; y++) for (let x = 12; x <= 29; x++) s.pset(x, y, y < 9 ? C.blue[3] : C.blue[1]);
  for (const hx of [11, 30]) { for (let y = 3; y < 25; y++) s.pset(hx, y, M[2]); for (let y = 1; y < 4; y++) s.pset(hx, y, Tc); }
  for (let x = 5; x <= 36; x++) s.pset(x, 25, M[1]);
}));

// kabel od monitora do łóżka
for (let k = 0; k <= 30; k++) { const t = k / 30; b.pset(Math.round(560 - t * 14), Math.round(100 + t * 26 + Math.sin(t * Math.PI) * 8), C.dark[1]); }
P.save(b, process.argv[2] + "/hospital.png");
savePieces(process.argv[2], "hospital", night);

// ---- Maciej leży: głowa na poduszce (widziana z góry, twarzą do nas), uszy rozłożone na poduszce, okulary,
// kołdra po pierś, łapy na kołdrze. Klatka 1: wdech (kołdra na piersi o 1 px wyżej i szersza).
// Maciej z portretu (portraits.js, maciej old) w skali ~0,55: lewe ucho proste, prawe zgięte z płatem, okrągłe
// okulary z dużymi oczami, jasny pyszczek; kołdra po brodę, nic poza głową nie wystaje.
// f: 0 wydech, 1 wdech (kołdra 1 px wyżej i szersza), 2 nie żyje (oczy zamknięte)
function maciej(f) {
  const m = new P.Buf(80, 100);
  const S = (prims, rr, opt) => P.solid(m, prims, rr, { light: [-0.6, -0.8, 0.5], ...opt });
  const pink = [[170, 140, 150], [196, 164, 172]];
  S([P.cap(35, 19, 33, 3, 3.1, 2.6)], C.fur);                                               // lewe ucho: proste
  S([P.cap(34.8, 17, 33.3, 6, 1.3, 1.1)], pink, { flat: true });
  S([P.cap(45, 19, 46.4, 11, 3.1, 2.8), P.cap(46.4, 10.5, 50.5, 12, 2.8, 2.4), P.cap(50.5, 12, 52.2, 15.6, 2.5, 1.5)], C.fur, { dark: 0.9 }); // prawe: zgina się wysoko, płat opada
  S([P.cap(45.2, 18, 46.2, 12, 1.3, 1.1)], pink, { flat: true });
  S([P.ell(40, 28, 12.6, 9.9), P.ell(33, 33, 6, 5), P.ell(47, 33, 6, 5)], C.fur);         // głowa z policzkami
  S([P.ell(37.8, 34.5, 3.6, 2.9), P.ell(42.2, 34.5, 3.6, 2.9)], [[214, 218, 226], [232, 236, 242], [246, 248, 252]]); // pyszczek
  const I = [26, 22, 34];
  for (const cx of [35, 45]) {                                                               // okulary i oczy
    for (let y = 22; y <= 32; y++) for (let x = cx - 5; x <= cx + 5; x++) { const d = Math.hypot(x - cx, y - 27); if (d > 3.6 && d <= 4.6) m.pset(x, y, I); }
    if (f === 2) { m.rect(cx - 2, 28, cx + 3, 29, [70, 72, 86]); m.pset(cx - 2, 27, [70, 72, 86]); m.pset(cx + 2, 27, [70, 72, 86]); }                               // zamknięte powieki
    else { m.rect(cx - 1, 25, cx + 2, 29, [44, 24, 18]); m.pset(cx - 1, 25, [232, 240, 255]); m.rect(cx, 27, cx + 2, 29, [124, 74, 40]); m.pset(cx + 1, 28, [44, 24, 18]); } // duże brązowe oczy z błyskiem
  }
  m.rect(39, 26, 41, 27, I);                                                                 // mostek
  m.rect(39, 31, 41, 32, [176, 118, 128]);                                                   // nos
  for (const [x, y] of [[29, 33], [28, 34], [51, 33], [52, 34]]) m.pset(x, y, [236, 238, 244]); // wąsy
  const up = f === 1 ? 1 : 0;
  const B = C.blue;
  slab(m, 4 - up, 37 - up, 76 + up, 98, B, 0.72, 0.5);                                       // kołdra po brodę
  m.rect(4 - up, 37 - up, 76 + up, 41 - up, C.white[3]); m.rect(4 - up, 41 - up, 76 + up, 42 - up, C.white[1]); // wywinięte prześcieradło
  for (let y = 56; y < 96; y += 14) m.rect(8, y, 72, y + 1, B[1]);                          // fałdy
  const o = require("./kit.js").ink(m); night(o); return o;
}
P.save(P.pack([maciej(0), maciej(1), maciej(2)], { cols: 3, pad: 0 }), process.argv[2] + "/hospital_maciej.png");
