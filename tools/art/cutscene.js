// Intro: postacie od tyłu na balkonie. Mała Jania (jania.js w skali dziecka) i jej tata Maciej:
// srebrzysty królik w białym kitlu, jedno ucho stoi, drugie opada. Po 2 klatki: stoi, oddech (1 px w górę).
process.env.JANIA_K = "0.82";
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const jania = require("./jania.js");
const FUR = P.hueRamp(4, { hue: 222, shift: 24, sat: 0.08, light: [0.34, 0.72] });
const COAT = P.hueRamp(4, { hue: 210, shift: 18, sat: 0.12, light: [0.6, 0.94] });
const TOP = { light: [0, -0.62, 0.78] };

// Maciej: o.mug (kubek w prawej łapie), o.armUp (prawa łapa w górze, zawiesza model), o.sit (siedzi: wózek),
// o.front (przodem: twarz, okulary, rozpięty kitel, łapy na balkoniku)
function maciej(f, o = {}) {  // proporcje jak Jania od tyłu (duża głowa, małe ciało), x1.15, w kitlu
  let b = new P.Buf(40, 64);
  const bob = f ? -1 : 0, S = (prims, r, opt) => P.solid(b, prims, r, { ...TOP, ...opt });
  const INKC = [26, 22, 34];
  if (!o.sit) S([P.ell(15, 60, 3.6, 1.8), P.ell(25, 60, 3.6, 1.8)], FUR, { dark: 0.85 });     // stopy
  const right = o.armUp ? P.cap(28, 33 + bob, 32, 15, 2.6, 2.4) : o.front ? P.cap(28, 33 + bob, 32, 43, 2.6, 2.4) : P.cap(28, 33 + bob, 30, o.sit ? 41 : 47, 2.6, 2.4);
  const left = o.front ? P.cap(12, 33 + bob, 8, 43, 2.6, 2.4) : P.cap(12, 33 + bob, 10, o.sit ? 41 : 47, 2.6, 2.4);
  S([left, right], COAT, { dark: 0.82 });                                                    // rękawy
  const pr = o.armUp ? [32, 13] : o.front ? [32, 44] : [30, o.sit ? 42 : 48], pl = o.front ? [8, 44] : [10, o.sit ? 42 : 48];
  S([P.ell(pl[0], pl[1], 2.2, 2), P.ell(pr[0], pr[1], 2.2, 2)], FUR);                        // łapki
  S([P.cap(20, 32 + bob, 20, o.sit ? 46 : 55, 7.5, 9.5)], COAT);                             // kitel
  if (o.front) {  // rozpięty kitel: niebieska koszula w dekolcie, guziki
    for (let y = 31; y < 47; y++) { const d = Math.min(3, (y - 31) >> 2); for (let x = 20 - d; x <= 20 + d; x++) b.pset(x, y + bob, [196, 214, 236]); }
    const TIE = [[146, 44, 104], [104, 28, 74]];
    for (const [x, y, c] of [[19, 31, 1], [20, 31, 1], [21, 31, 1], [19, 32, 0], [20, 32, 0], [21, 32, 1]]) b.pset(x, y + bob, TIE[c]); // węzeł
    for (let y = 33; y < 44; y++) { const w = y < 37 ? 0 : 1; for (let x = 20 - w; x <= 20 + w; x++) b.pset(x, y + bob, TIE[x > 20 ? 1 : 0]); } // klinga
    b.pset(19, 44 + bob, TIE[1]); b.pset(20, 44 + bob, TIE[0]); b.pset(21, 44 + bob, TIE[1]); b.pset(20, 45 + bob, TIE[1]); // szpic
    for (let y = 48; y < 56; y += 3) b.pset(20, y, COAT[0]);
  } else if (!o.sit) for (let y = 48; y < 58; y++) b.pset(20, y, COAT[0]);                   // rozcięcie z tyłu
  if (!o.front) for (let x = 13; x <= 27; x++) b.pset(x, 44, COAT[1]);                       // pasek
  S([P.ell(20, 30.5 + bob, 6, 2.4)], COAT, { dark: 0.9 });                                   // kołnierz
  S([P.cap(16, 16 + bob, 15.2, 6 + bob, 2.5, 2.8), P.cap(24, 16 + bob, 24.6, 9.5 + bob, 2.5, 2.6)], FUR); // ucho stoi; drugie ma lustrzaną nasadę
  S([P.ell(20, 22 + bob, 9.5, 7.5), P.ell(13.5, 24.5 + bob, 3.6, 3), P.ell(26.5, 24.5 + bob, 3.6, 3)], FUR, { ambient: 0.5 });
  S([P.ell(28, 9.6 + bob, 4.2, 2.4, 0.42)], FUR, { dark: 0.9 });                             // ...zgina się wysoko, płat opada na bok
  if (o.front) {  // twarz: jasny pyszczek, oczy w okularach, nosek
    S([P.ell(20, 27 + bob, 4.5, 2.6)], LIGHT);
    for (const ex of [15, 23]) {
      for (const [dx, dy] of [[0, -1], [1, -1], [-1, 0], [2, 0], [-1, 1], [2, 1], [0, 2], [1, 2]]) b.pset(ex + dx, 22 + dy + bob, INKC); // obręcz
      b.pset(ex, 22 + bob, [92, 54, 30]); b.pset(ex + 1, 22 + bob, [92, 54, 30]); b.pset(ex, 23 + bob, [40, 24, 18]); b.pset(ex + 1, 23 + bob, [40, 24, 18]);
    }
    b.pset(18, 22 + bob, INKC); b.pset(19, 22 + bob, INKC); b.pset(20, 22 + bob, INKC); b.pset(21, 22 + bob, INKC); // mostek
    b.pset(19, 26 + bob, [176, 118, 128]); b.pset(20, 26 + bob, [176, 118, 128]);           // nos
  } else { b.pset(11, 23 + bob, INKC); b.pset(29, 23 + bob, INKC); }                        // zauszniki od tyłu
  b = P.smoothEdge(b);  // sprzęt dorysowany po wygładzeniu: cienkie rurki zostają
  if (o.walker) {  // balkonik na szerokość Macieja: rączki pod łapkami, poprzeczka, cztery nogi
    const M = [196, 202, 214], D = [132, 140, 158], T = [40, 38, 48];
    for (let x = 7; x <= 33; x++) { b.pset(x, 45, M); b.pset(x, 46, D); b.pset(x, 54, D); }
    for (const lx of [7, 32]) for (let y = 45; y < 63; y++) { b.pset(lx, y, M); b.pset(lx + 1, y, D); }
    for (const lx of [7, 32]) { for (let y = 43; y < 46; y++) { b.pset(lx, y, T); b.pset(lx + 1, y, T); } b.pset(lx, 63, T); b.pset(lx + 1, 63, T); }
    S([P.ell(8, 44, 2.2, 2), P.ell(32, 44, 2.2, 2)], FUR);                                    // łapki na rączkach
  }
  if (o.chair) {  // wózek od tyłu: oparcie zasłania plecy, rączki, wąskie duże koła po bokach
    const M = P.hueRamp(3, { hue: 220, shift: 16, sat: 0.12, light: [0.42, 0.78] }), T = [40, 38, 48];
    for (let y = 35; y < 52; y++) for (let x = 13; x <= 27; x++) b.pset(x, y, y < 37 ? [70, 84, 120] : [52, 62, 96]);
    for (const hx of [12, 28]) { for (let y = 31; y < 53; y++) b.pset(hx, y, M[2]); for (let y = 29; y < 32; y++) b.pset(hx, y, T); }
    for (const wx of [6, 34]) S([P.ell(wx, 48, 2.6, 11)], [T, [64, 62, 74], [84, 82, 94]]);
    for (const wx of [6, 34]) for (let y = 39; y < 58; y++) b.pset(wx, y, M[1]);
    for (let x = 6; x <= 34; x++) b.pset(x, 53, M[1]);
  }
  return ink(b);
}
// Maciej z profilu (patrzy w prawo), kubek trzymany oburącz przed sobą; para rysowana w grze
function maciejSide(f) {
  const b = new P.Buf(40, 64), bob = f ? -1 : 0, S = (prims, r, opt) => P.solid(b, prims, r, { ...TOP, ...opt });
  const INKC = [26, 22, 34];
  S([P.ell(17, 60, 4.5, 1.8), P.ell(22, 60, 4.5, 1.8)], FUR, { dark: 0.85 });                // stopy
  S([P.cap(18, 34 + bob, 25, 41 + bob, 2.4, 2.2)], COAT, { dark: 0.8 });                     // dalsza ręka
  S([P.ell(26.5, 40.5 + bob, 2, 1.8)], FUR, { dark: 0.85 });
  S([P.cap(18, 32 + bob, 18, 55, 7, 8.5)], COAT);                                            // kitel
  for (let y = 48; y < 58; y++) b.pset(13, y, COAT[1]);                                       // rozcięcie z tyłu
  S([P.ell(18.5, 30.5 + bob, 5.5, 2.4)], COAT, { dark: 0.9 });                               // kołnierz
  S([P.cap(15.5, 16 + bob, 14, 6 + bob, 2.5, 2.8)], FUR, { dark: 0.85 });                    // ucho stoi (dalsze)
  S([P.cap(18.5, 16 + bob, 19.2, 9.5 + bob, 2.4, 2.5)], FUR);                                // ucho złamane: nasada za głową
  S([P.ell(18.5, 22 + bob, 8.2, 7.4), P.ell(24.5, 24.5 + bob, 4.2, 3.2)], FUR, { ambient: 0.5 }); // głowa i pyszczek
  S([P.ell(26, 25.2 + bob, 3, 2)], LIGHT);
  S([P.ell(22.4, 9.6 + bob, 4.2, 2.4, 0.38)], FUR, { dark: 0.9 });                          // ...wysoko zgięte, płat opada do przodu
  for (const [dx, dy] of [[0, -1], [1, -1], [-1, 0], [2, 0], [-1, 1], [2, 1], [0, 2], [1, 2]]) b.pset(23 + dx, 22 + dy + bob, INKC); // szkło
  b.pset(23, 22 + bob, [92, 54, 30]); b.pset(24, 22 + bob, [92, 54, 30]); b.pset(23, 23 + bob, [40, 24, 18]); b.pset(24, 23 + bob, [40, 24, 18]);
  for (let x = 18; x < 22; x++) b.pset(x, 21 + bob, INKC);                                   // zausznik
  b.pset(29, 24 + bob, [176, 118, 128]); b.pset(28, 27 + bob, [120, 80, 90]); b.pset(27, 27 + bob, [120, 80, 90]); // nos, pyszczek
  for (let y = 0; y < 5; y++) for (let x = 0; x < 4; x++) b.pset(26 + x, 36 + y + bob, y === 0 ? [206, 212, 224] : [240, 242, 248]); // kubek
  b.pset(30, 37 + bob, [206, 212, 224]); b.pset(30, 38 + bob, [206, 212, 224]); b.pset(26, 39 + bob, [190, 90, 70]); b.pset(27, 39 + bob, [190, 90, 70]);
  S([P.cap(19, 34 + bob, 24, 41 + bob, 2.6, 2.4)], COAT);                                    // bliższa ręka
  S([P.ell(25.5, 40.5 + bob, 2.2, 2)], FUR);
  return ink(P.smoothEdge(b));
}
const flip = (src) => { const o = new P.Buf(src.w, src.h); for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) o.px[y * src.w + x] = src.px[y * src.w + src.w - 1 - x]; return o; };
const LIGHT = P.hueRamp(3, { hue: 220, shift: 12, sat: 0.08, light: [0.7, 0.9] });
// Jania w różnym wieku: jania.js z inną skalą (dziecko 0.82, nastolatka 0.95)
function janiaAt(k) {
  process.env.JANIA_K = String(k);
  delete require.cache[require.resolve("./jania.js")];
  return require("./jania.js").frames;
}
// przycina klatki do wspólnego prostokąta i pakuje w pasek
function strip(frames) {
  let x0 = 99, y0 = 99, x1 = 0, y1 = 0;
  for (const f of frames) { const q = P.bounds(f); x0 = Math.min(x0, q.x); y0 = Math.min(y0, q.y); x1 = Math.max(x1, q.x + q.w); y1 = Math.max(y1, q.y + q.h); }
  return P.pack(frames.map((f) => P.crop(f, x0, y0 - 1, x1 - x0, y1 - y0 + 1)), { cols: frames.length, pad: 0 });
}
// mała Jania siedzi na podłodze przodem, zeszyt na kolanach, pisze ołówkiem (2 klatki)
function sitting(fr, f) {
  const b = P.crop(fr, 0, 0, fr.w, fr.h), INKC = [18, 12, 22];
  for (let y = 36; y < b.h; y++) for (let x = 0; x < b.w; x++) b.px[y * b.w + x] = 0;   // nogi pod zeszytem
  for (const fx of [8, 27]) for (let y = 34; y < 39; y++) for (let x = fx - 3; x <= fx + 3; x++) {  // stopy na boki
    const e = ((x - fx) / 3.4) ** 2 + ((y - 36.5) / 2.2) ** 2;
    if (e <= 1) b.pset(x, y, e > 0.55 ? INKC : [244, 222, 190]);
  }
  for (let y = 30; y < 38; y++) for (let x = 10; x < 26; x++) {                           // otwarty zeszyt
    const edge = y === 30 || y === 37 || x === 10 || x === 25, spine = x === 17 || x === 18;
    b.pset(x, y, edge ? INKC : spine ? [196, 200, 214] : y % 2 ? [236, 240, 248] : [210, 218, 236]);
  }
  for (let x = 19; x < 19 + f; x++) b.pset(x, 34, [120, 130, 160]);                       // świeża linijka pisma
  const px = 20 + f, py = 33, JR = require("./jania.js").R;                               // cała ręka od ramienia do zeszytu
  const arm = new P.Buf(b.w, b.h);
  P.solid(arm, [P.cap(23.8, 26, px + 0.5, py - 0.5, 2, 1.7)], JR.fur, TOP);
  P.solid(arm, [P.ell(px, py, 2.2, 1.9)], JR.cream, TOP);
  const ai = ink(arm);
  const INKP = P.col(INKC);
  for (let y = 0; y < b.h; y++) for (let x = 0; x < b.w; x++) {  // obrys ręki tylko na zeszycie i od zewnątrz: na tułowiu ręka z niego wyrasta
    const c = ai.get(x + 1, y + 1);
    if (!(c >>> 24)) continue;
    if ((c >>> 0) === (INKP >>> 0) && y < 30 && (b.px[y * b.w + x] >>> 24)) continue;
    b.px[y * b.w + x] = c;
  }
  for (let k = 0; k < 7; k++) {  // czerwony długopis w łapce: grot na kartce, trzon wystaje skośnie nad łapkę
    const x = px - 1 + Math.floor(k * 0.5), y = py + 2 - k;
    if (k > 0) { b.pset(x - 1, y, INKC); b.pset(x + 1, y, INKC); }
    b.pset(x, y, k === 0 ? [40, 30, 40] : k > 4 ? [150, 24, 34] : [226, 60, 56]);
  }
  b.pset(px + 2, py - 5, INKC);
  return b;
}
const jbb = P.bounds(jania.frames[16]);
const jb = (f) => P.crop(jania.frames[16 + (f ? 7 : 0)], jbb.x, jbb.y - 1, jbb.w, jbb.h + 1);  // rząd 2 = tył; 7. kolumna = oddech
// obserwatorium po drugiej stronie jeziora: białe, odnowione, kopuła otwarta, gruby teleskop wystaje przez szczelinę
function observatory(closed = false, empty = false) {  // closed: teleskop wyjęty, okna i drzwi zabite deskami; empty: odnowione, kopuła otwarta i pusta (żuraw wstawia teleskop)
  const b = new P.Buf(80, 64);
  const white = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.12, light: [0.52, 0.94] });
  const steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.14, light: [0.3, 0.78] });
  const night = [26, 30, 52], warm = [255, 214, 128], warmD = [214, 150, 80];
  for (let y = 38; y < 64; y++) for (let x = 6; x < 75; x++) b.pset(x, y, white[x < 8 || x > 72 ? 1 : 2]);  // ściany: symetrycznie, ciemniejsze narożniki
  for (let x = 4; x < 77; x++) { b.pset(x, 35, white[3]); b.pset(x, 36, white[2]); b.pset(x, 37, white[1]); }  // gzyms
  const dome = new P.Buf(80, 64);
  P.solid(dome, [P.ell(40, 35, 17, 16)], white, { light: [-0.5, -0.7, 0.5] });                               // kopuła: tylko półkula nad dachem
  for (let y = 0; y < 35; y++) for (let x = 0; x < 80; x++) { const u = dome.get(x, y); if (u >>> 24) b.px[y * 80 + x] = u; }
  for (let y = 18; y < 35; y++) for (let x = 35; x <= 45; x++) if (((x - 40) / 17) ** 2 + ((y - 35) / 16) ** 2 <= 1) b.pset(x, y, night); // otwarta szczelina
  if (!closed && !empty) {
    P.solid(b, [P.cap(40, 31, 55, 11, 2.4, 5.2)], steel, { light: [-0.5, -0.7, 0.5] });                      // teleskop: stożek rozszerza się ku obiektywowi
    P.solid(b, [P.cap(55, 11, 56.5, 9, 5.4, 5.4)], white, { light: [-0.5, -0.7, 0.5] });                     // pierścień obiektywu
  }
  for (const wx of [10, 20, 52, 62]) {                                                                       // okna: świecą się albo są ciemne
    for (let y = 43; y < 50; y++) for (let x = wx; x < wx + 7; x++) b.pset(x, y, steel[1]);
    for (let y = 44; y < 49; y++) for (let x = wx + 1; x < wx + 6; x++) b.pset(x, y, closed ? night : y > 46 ? warmD : warm);
    for (let y = 44; y < 49; y++) b.pset(wx + 3, y, steel[1]);
  }
  for (let y = 50; y < 64; y++) for (let x = 35; x < 46; x++) b.pset(x, y, x === 35 || x === 45 || y === 50 ? steel[1] : steel[2]); // drzwi
  if (!closed) { b.pset(43, 57, warm); for (let x = 38; x < 43; x++) b.pset(x, 48, warm); }                  // klamka, lampka nad drzwiami
  const WOOD = [[138, 106, 72], [168, 132, 90], [70, 50, 38]];
  const plank = (x0, y0, x1, y1) => {  // deska 2 px: jasny wierzch, ciemny spód
    const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0));
    for (let i = 0; i <= n; i++) { const x = Math.round(x0 + (x1 - x0) * i / n), y = Math.round(y0 + (y1 - y0) * i / n); b.pset(x, y, WOOD[1]); b.pset(x, y + 1, WOOD[0]); b.pset(x, y + 2, WOOD[2]); }
  };
  if (closed) {
    for (const wx of [10, 20, 52, 62]) { plank(wx - 1, 43, wx + 7, 43); plank(wx - 1, 47, wx + 7, 47); }
    plank(34, 51, 46, 61); plank(34, 59, 46, 51); plank(34, 55, 46, 55);
  }
  for (let x = 32; x < 49; x++) b.pset(x, 63, white[1]);                                                    // schodek
  return ink(P.smoothEdge(b));  // gładka sylwetka przed obrysem: bez ząbków na kopule i tubusie
}
// żurawie i auta: żółte z czarnym (referencje autora), skala: drzwi obserwatorium 14 px = ok. 2 m
const YEL = [[250, 196, 44], [222, 156, 26], [156, 100, 22]], BLK = [32, 30, 36], GRY = [96, 98, 108];
// żuraw wieżowy: kratownicowa wieża na czarnej podstawie, kabina, wysięgnik w prawo, przeciwwysięgnik z balastem,
// iglica z odciągami. Wózek, lina i hak rysuje gra. Podstawa wieży w (40, 128), wysięgnik na y 18–22.
function crane() {
  const W = 190, G = 128, b = new P.Buf(W, G + 2);
  const line = (x0, y0, x1, y1, c) => { const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)); for (let i = 0; i <= n; i++) b.pset(Math.round(x0 + (x1 - x0) * i / n), Math.round(y0 + (y1 - y0) * i / n), c); };
  line(40, 2, 12, 18, GRY); line(40, 2, 120, 18, GRY);                                   // odciągi
  for (let y = 30; y < G - 8; y += 8) { line(37, y, 44, y + 4, YEL[0]); line(44, y + 4, 37, y + 8, YEL[0]); } // wieża: kratownica
  for (let y = 26; y < G - 8; y++) { b.pset(36, y, YEL[1]); b.pset(37, y, YEL[2]); b.pset(44, y, YEL[1]); b.pset(45, y, YEL[2]); }
  line(32, G, 36, G - 8, BLK); line(49, G, 45, G - 8, BLK); line(32, G, 49, G - 8, BLK); line(49, G, 32, G - 8, BLK); // podstawa
  for (let x = 30; x <= 51; x++) { b.pset(x, G, BLK); b.pset(x, G + 1, BLK); }
  for (let x = 34; x <= 47; x++) b.pset(x, G - 8, BLK);
  line(36, 18, 40, 2, YEL[1]); line(45, 18, 41, 2, YEL[1]); line(37, 12, 44, 12, YEL[1]); line(38, 7, 43, 7, YEL[1]); // iglica
  for (const [x0, x1] of [[4, 34], [46, 186]]) {                                           // wysięgniki: pasy i krzyżulce
    for (let x = x0; x <= x1; x++) { b.pset(x, 18, YEL[0]); b.pset(x, 22, YEL[2]); }
    for (let x = x0; x < x1; x += 6) { line(x, 22, x + 3, 18, YEL[1]); line(x + 3, 18, x + 6, 22, YEL[1]); }
  }
  line(186, 18, 186, 22, YEL[1]);
  for (let y = 23; y < 30; y++) for (let x = 4; x < 16; x++) b.pset(x, y, y === 23 ? [120, 122, 132] : GRY); // balast
  for (let y = 16; y < 28; y++) for (let x = 33; x < 48; x++) b.pset(x, y, y < 18 ? YEL[0] : YEL[1]);       // kabina
  for (let y = 19; y < 23; y++) for (let x = 41; x < 46; x++) b.pset(x, y, [60, 84, 110]);
  for (let x = 34; x < 47; x++) { b.pset(x, 28, BLK); b.pset(x, 29, BLK); }                            // obrotnica
  return b;
}
// wywrotka z boku (w prawo): żółta skrzynia w pasy, kabina z szybą, czarne koła z żółtymi felgami; 60x30
function truck() {
  const b = new P.Buf(62, 31);
  for (let y = 20; y < 25; y++) for (let x = 4; x < 60; x++) b.pset(x, y, y < 22 ? [84, 82, 90] : [60, 58, 66]); // podwozie
  for (let y = 4; y < 21; y++) { const x0 = 2 + Math.floor((y - 4) / 4), x1 = 37 - Math.floor((y - 4) / 8); for (let x = x0; x < x1; x++) b.pset(x, y, y === 4 ? YEL[0] : (((x - (y >> 1)) % 8) + 8) % 8 < 4 ? YEL[0] : YEL[1]); } // skrzynia: skośne pasy przez całą skrzynię
  for (let y = 6; y < 23; y++) for (let x = 39; x < 57; x++) { const nose = x > 52 && y < 12 + (x - 52); if (!nose) b.pset(x, y, y > 18 ? YEL[1] : YEL[0]); } // kabina
  for (let y = 8; y < 14; y++) for (let x = 43; x < 52; x++) b.pset(x, y, x > 48 ? [96, 150, 170] : [60, 84, 110]); // szyba
  for (let y = 17; y < 24; y++) for (let x = 56; x < 60; x++) b.pset(x, y, YEL[1]);                       // zderzak
  for (const wx of [13, 47]) for (let y = 18; y < 31; y++) for (let x = wx - 7; x <= wx + 7; x++) {  // nadkola (koła rysuje gra)
    if (Math.hypot(x - wx, y - 24.5) <= 7.2 && y < 25) b.pset(x, y, BLK);
  }
  for (let y = 1; y < 22; y++) { b.pset(37, y, y < 3 ? [150, 152, 160] : [70, 72, 80]); b.pset(38, y, y < 3 ? [190, 192, 200] : [120, 122, 132]); } // rura wydechowa za kabiną
  return ink(b);
}
// koło wywrotki: opona z bieżnikiem, żółta felga, 4 śruby; 4 klatki obrotu co 22,5° (wzór powtarza się co 90°)
function wheel(f) {
  const b = new P.Buf(13, 13), a0 = f * Math.PI / 8;
  for (let y = 0; y < 13; y++) for (let x = 0; x < 13; x++) {
    const dx = x - 6, dy = y - 6, d = Math.hypot(dx, dy);
    if (d > 6.4) continue;
    let c = d < 2.6 ? YEL[0] : d < 3.5 ? YEL[2] : BLK;
    const a = Math.atan2(dy, dx) - a0, m = ((a % (Math.PI / 4)) + Math.PI / 4) % (Math.PI / 4);
    if (d >= 4.6 && m < 0.24) c = [74, 72, 82];                                           // bieżnik
    b.pset(x, y, c);
  }
  for (let k = 0; k < 4; k++) { const a = a0 + k * Math.PI / 2; b.pset(Math.round(6 + Math.cos(a) * 1.8), Math.round(6 + Math.sin(a) * 1.8), YEL[2]); } // śruby
  b.pset(6, 6, [90, 60, 20]);
  return P.outline(b, [18, 12, 22]);
}
// teleskop wyjęty z kopuły: leżący stożek z pierścieniem obiektywu (wisi na linie żurawia)
function scope() {
  const b = new P.Buf(34, 14), steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.14, light: [0.3, 0.78] });
  const white = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.12, light: [0.52, 0.94] });
  P.solid(b, [P.cap(3, 7, 26, 7, 2.4, 5)], steel, TOP);
  P.solid(b, [P.cap(27, 7, 29, 7, 5.3, 5.3)], white, TOP);
  return P.outline(P.smoothEdge(b), [18, 12, 22], { corners: true });
}
// drzwi balkonowe zamknięte, takie same jak w pokoju (jasne drewno, 4 szybki, ceglasta płycina);
// od strony balkonu szybki świecą ciepło, bo w mieszkaniu pali się światło
function door() {
  const b = new P.Buf(36, 83);
  const FRAME = [192, 166, 107], FRAME_D = [163, 121, 75], PANEL = [170, 102, 72], PANEL_D = [127, 65, 49];
  const glow = [[236, 196, 120], [250, 222, 150]], HANDLE = [236, 200, 90];
  for (let y = 0; y < 83; y++) for (let x = 0; x < 36; x++) b.pset(x, y, x > 33 || y > 80 ? FRAME_D : FRAME);
  for (const [px, py] of [[5, 6], [19, 6], [5, 29], [19, 29]])                                   // 4 szybki jak w pokoju
    for (let y = py; y < py + 20; y++) for (let x = px; x < px + 12; x++)
      b.pset(x, y, y > py + 16 && (x + y) % 2 ? glow[0] : glow[1]);
  for (const [px, py] of [[5, 6], [19, 6], [5, 29], [19, 29]]) for (let k = 0; k < 5; k++) b.pset(px + 4 + k, py + 9 - k, [255, 240, 196]); // odblask
  for (let y = 55; y < 77; y++) for (let x = 5; x < 31; x++) b.pset(x, y, y === 55 ? [201, 201, 156] : PANEL);               // płycina
  for (let x = 5; x < 31; x++) b.pset(x, 76, PANEL_D);
  for (const [x, y] of [[30, 48], [31, 48], [31, 49], [31, 50]]) b.pset(x, y, HANDLE);           // klamka
  return b;
}
const out = process.argv[2];
// --- montaż: postacie w kolejnych scenach
const kid = janiaAt(0.82), teen = janiaAt(0.95);
P.save(strip([flip(maciejSide(0)), flip(maciejSide(1))]), out + "/cut_maciej_mug.png");
P.save(strip([maciej(0, { armUp: true }), maciej(1, { armUp: true })]), out + "/cut_maciej_hang.png");
P.save(strip([maciej(0, { front: true, walker: true }), maciej(1, { front: true, walker: true })]), out + "/cut_maciej_front.png");
P.save(strip([maciej(0, { sit: true, chair: true }), maciej(1, { sit: true, chair: true })]), out + "/cut_maciej_sit.png");
const kidPaw = janiaAt(0.82) && require("./jania.js").frame(0, 0, { paw: [20, 36] });
P.save(strip([sitting(kidPaw, 0), sitting(kidPaw, 1)]), out + "/cut_jania_sit.png");
P.save(strip([kid[6], kid[7]]), out + "/cut_jania_joy.png");
P.save(strip([teen[16], teen[23]]), out + "/cut_teen_back.png");
const T = (janiaAt(0.95), require("./jania.js"));
P.save(strip([0, 1, 2, 3, 4].map((f) => T.frame(1, f, { carry: true }))), out + "/cut_teen_walk.png");
P.save(observatory(), out + "/cut_observatory.png");
P.save(observatory(true), out + "/cut_observatory_closed.png");
P.save(observatory(false, true), out + "/cut_observatory_empty.png");
P.save(crane(), out + "/cut_crane.png");
P.save(truck(), out + "/cut_truck.png");
P.save(P.pack([0, 1, 2, 3].map(wheel), { cols: 4, pad: 0 }), out + "/cut_wheel.png");
P.save(scope(), out + "/cut_scope.png");
P.save(door(), out + "/cut_door.png");
const pk = (fr) => P.pack(fr, { cols: fr.length, pad: 0 });
P.save(pk([jb(0), jb(1)]), out + "/cut_jania_back.png");
P.save(pk([maciej(0), maciej(1)]), out + "/cut_maciej_back.png");
P.save(P.sheet([{ buf: jb(0), scale: 4, label: "JANIA" }, { buf: maciej(0), scale: 4, label: "MACIEJ" }, { buf: maciej(1), scale: 4, label: "ODDECH" }]), __dirname + "/_cut_chars.png");
