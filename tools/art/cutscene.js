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
  const b = new P.Buf(40, 64), bob = f ? -1 : 0, S = (prims, r, opt) => P.solid(b, prims, r, { ...TOP, ...opt });
  const INKC = [26, 22, 34];
  if (!o.sit) S([P.ell(15, 60, 3.6, 1.8), P.ell(25, 60, 3.6, 1.8)], FUR, { dark: 0.85 });     // stopy
  const right = o.armUp ? P.cap(28, 33 + bob, 32, 15, 2.6, 2.4) : o.front ? P.cap(28, 33 + bob, 32, 43, 2.6, 2.4) : P.cap(28, 33 + bob, 30, o.sit ? 41 : 47, 2.6, 2.4);
  const left = o.front ? P.cap(12, 33 + bob, 8, 43, 2.6, 2.4) : P.cap(12, 33 + bob, 10, o.sit ? 41 : 47, 2.6, 2.4);
  S([left, right], COAT, { dark: 0.82 });                                                    // rękawy
  const pr = o.armUp ? [32, 13] : o.front ? [32, 44] : [30, o.sit ? 42 : 48], pl = o.front ? [8, 44] : [10, o.sit ? 42 : 48];
  S([P.ell(pl[0], pl[1], 2.2, 2), P.ell(pr[0], pr[1], 2.2, 2)], FUR);                        // łapki
  S([P.cap(20, 32 + bob, 20, o.sit ? 46 : 55, 7.5, 9.5)], COAT);                             // kitel
  if (o.front) {  // rozpięty kitel: niebieska koszula w dekolcie, guziki
    for (let y = 31; y < 46; y++) { const d = Math.min(3, (y - 31) >> 2); for (let x = 20 - d; x <= 20 + d; x++) b.pset(x, y + bob, [92, 138, 190]); }
    for (let y = 47; y < 56; y += 3) b.pset(20, y, COAT[0]);
  } else if (!o.sit) for (let y = 48; y < 58; y++) b.pset(20, y, COAT[0]);                   // rozcięcie z tyłu
  if (!o.front) for (let x = 13; x <= 27; x++) b.pset(x, 44, COAT[1]);                       // pasek
  S([P.ell(20, 30.5 + bob, 6, 2.4)], COAT, { dark: 0.9 });                                   // kołnierz
  S([P.cap(16, 16 + bob, 15.2, 6 + bob, 2.5, 2.8)], FUR);                                    // ucho stoi
  S([P.ell(20, 22 + bob, 9.5, 7.5), P.ell(13.5, 24.5 + bob, 3.6, 3), P.ell(26.5, 24.5 + bob, 3.6, 3)], FUR, { ambient: 0.5 });
  S([P.cap(24, 16 + bob, 26, 7 + bob, 2.4, 2.5), P.cap(26, 7 + bob, 31, 9 + bob, 2.5, 2.4), P.cap(31, 9 + bob, 32, 15 + bob, 2.4, 2.1)], FUR, { dark: 0.9 }); // ucho złamane
  if (o.front) {  // twarz: jasny pyszczek, oczy w okularach, nosek
    S([P.ell(20, 27 + bob, 4.5, 2.6)], LIGHT);
    for (const ex of [15, 23]) {
      for (const [dx, dy] of [[0, -1], [1, -1], [-1, 0], [2, 0], [-1, 1], [2, 1], [0, 2], [1, 2]]) b.pset(ex + dx, 22 + dy + bob, INKC); // obręcz
      b.pset(ex, 22 + bob, [92, 54, 30]); b.pset(ex + 1, 22 + bob, [92, 54, 30]); b.pset(ex, 23 + bob, [40, 24, 18]); b.pset(ex + 1, 23 + bob, [40, 24, 18]);
    }
    b.pset(18, 22 + bob, INKC); b.pset(19, 22 + bob, INKC); b.pset(20, 22 + bob, INKC); b.pset(21, 22 + bob, INKC); // mostek
    b.pset(19, 26 + bob, [176, 118, 128]); b.pset(20, 26 + bob, [176, 118, 128]);           // nos
  } else { b.pset(11, 23 + bob, INKC); b.pset(29, 23 + bob, INKC); }                        // zauszniki od tyłu
  if (o.mug) {  // kubek w łapie (para rysowana w grze)
    for (let y = 43; y < 48; y++) for (let x = 31; x < 35; x++) b.pset(x, y, y === 43 ? [214, 220, 230] : [236, 240, 246]);
    b.pset(35, 44, [214, 220, 230]); b.pset(35, 45, [214, 220, 230]); b.pset(31, 46, [190, 90, 70]); b.pset(32, 46, [190, 90, 70]);
  }
  return ink(P.smoothEdge(b));
}
const LIGHT = P.hueRamp(3, { hue: 220, shift: 12, sat: 0.08, light: [0.7, 0.9] });
// wózek inwalidzki od tyłu: oparcie, rączki, duże koła (z tyłu widać je wąsko)
function wheelchair() {
  const b = new P.Buf(40, 44), M = P.hueRamp(3, { hue: 220, shift: 16, sat: 0.12, light: [0.42, 0.78] }), T = [40, 38, 48];
  for (const wx of [4, 35]) { P.solid(b, [P.ell(wx, 30, 3, 12)], [T, [64, 62, 74], [84, 82, 94]], TOP); for (let y = 20; y < 41; y++) b.pset(wx, y, M[1]); }
  for (let y = 10; y < 32; y++) for (let x = 9; x < 31; x++) b.pset(x, y, y < 12 ? [70, 84, 120] : [52, 62, 96]);  // oparcie
  for (const hx of [8, 31]) { for (let y = 4; y < 34; y++) b.pset(hx, y, M[2]); for (let y = 2; y < 6; y++) b.pset(hx, y, T); } // rurki i rączki
  for (let x = 8; x < 32; x++) b.pset(x, 34, M[1]);
  return ink(b);
}
// balkonik (chodzik) przodem: rama z rączkami i cztery nogi z gumowymi stopkami
function walker() {
  const b = new P.Buf(46, 26), M = [196, 202, 214], D = [132, 140, 158], T = [40, 38, 48];
  for (let x = 2; x < 44; x++) { b.pset(x, 2, M); b.pset(x, 3, D); }
  for (const lx of [2, 42]) for (let y = 2; y < 25; y++) { b.pset(lx, y, M); b.pset(lx + 1, y, D); }
  for (const lx of [9, 35]) for (let y = 4; y < 25; y++) b.pset(lx, y, D);
  for (let x = 2; x < 44; x++) b.pset(x, 14, D);
  for (const lx of [2, 42]) { for (let y = 1; y < 5; y++) { b.pset(lx, y, T); b.pset(lx + 1, y, T); } b.pset(lx, 25, T); b.pset(lx + 1, 25, T); }
  return b;
}
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
  const px = 22 + f, py = 31;                                                               // ołówek pisze
  for (let k = 0; k < 4; k++) b.pset(px + k, py - k, k === 3 ? [236, 140, 150] : [240, 200, 80]);
  b.pset(px - 1, py + 1, [60, 52, 60]);
  return b;
}
const jbb = P.bounds(jania.frames[16]);
const jb = (f) => P.crop(jania.frames[16 + (f ? 7 : 0)], jbb.x, jbb.y - 1, jbb.w, jbb.h + 1);  // rząd 2 = tył; 7. kolumna = oddech
// obserwatorium po drugiej stronie jeziora: białe, odnowione, kopuła otwarta, gruby teleskop wystaje przez szczelinę
function observatory() {
  const b = new P.Buf(80, 64);
  const white = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.12, light: [0.52, 0.94] });
  const steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.14, light: [0.3, 0.78] });
  const night = [26, 30, 52], warm = [255, 214, 128], warmD = [214, 150, 80];
  for (let y = 38; y < 64; y++) for (let x = 6; x < 75; x++) b.pset(x, y, white[x < 12 ? 3 : x > 68 ? 1 : 2]);  // ściany
  for (let x = 4; x < 77; x++) { b.pset(x, 35, white[3]); b.pset(x, 36, white[2]); b.pset(x, 37, white[1]); }  // gzyms
  const dome = new P.Buf(80, 64);
  P.solid(dome, [P.ell(40, 35, 17, 16)], white, { light: [-0.5, -0.7, 0.5] });                               // kopuła: tylko półkula nad dachem
  for (let y = 0; y < 35; y++) for (let x = 0; x < 80; x++) { const u = dome.get(x, y); if (u >>> 24) b.px[y * 80 + x] = u; }
  for (let y = 18; y < 35; y++) for (let x = 35; x <= 45; x++) if (((x - 40) / 17) ** 2 + ((y - 35) / 16) ** 2 <= 1) b.pset(x, y, night); // otwarta szczelina
  P.solid(b, [P.cap(40, 31, 55, 11, 2.4, 5.2)], steel, { light: [-0.5, -0.7, 0.5] });                        // teleskop: stożek rozszerza się ku obiektywowi
  P.solid(b, [P.cap(55, 11, 56.5, 9, 5.4, 5.4)], white, { light: [-0.5, -0.7, 0.5] });                       // pierścień obiektywu
  for (const wx of [10, 20, 52, 62]) {                                                                       // okna: świeci się
    for (let y = 43; y < 50; y++) for (let x = wx; x < wx + 7; x++) b.pset(x, y, steel[1]);
    for (let y = 44; y < 49; y++) for (let x = wx + 1; x < wx + 6; x++) b.pset(x, y, y > 46 ? warmD : warm);
    for (let y = 44; y < 49; y++) b.pset(wx + 3, y, steel[1]);
  }
  for (let y = 50; y < 64; y++) for (let x = 35; x < 46; x++) b.pset(x, y, x === 35 || x === 45 || y === 50 ? steel[1] : steel[2]); // drzwi
  b.pset(43, 57, warm); for (let x = 38; x < 43; x++) b.pset(x, 48, warm);                                   // klamka, lampka nad drzwiami
  for (let x = 32; x < 49; x++) b.pset(x, 63, white[1]);                                                    // schodek
  return ink(P.smoothEdge(b));  // gładka sylwetka przed obrysem: bez ząbków na kopule i tubusie
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
P.save(strip([maciej(0, { mug: true }), maciej(1, { mug: true })]), out + "/cut_maciej_mug.png");
P.save(strip([maciej(0, { armUp: true }), maciej(1, { armUp: true })]), out + "/cut_maciej_hang.png");
P.save(strip([maciej(0, { front: true }), maciej(1, { front: true })]), out + "/cut_maciej_front.png");
P.save(strip([maciej(0, { sit: true }), maciej(1, { sit: true })]), out + "/cut_maciej_sit.png");
P.save(wheelchair(), out + "/cut_wheelchair.png");
P.save(walker(), out + "/cut_walker.png");
P.save(strip([sitting(kid[0], 0), sitting(kid[0], 1)]), out + "/cut_jania_sit.png");
P.save(strip([kid[6], kid[7]]), out + "/cut_jania_joy.png");
P.save(strip([teen[16], teen[23]]), out + "/cut_teen_back.png");
P.save(strip([teen[8], teen[9], teen[10], teen[11], teen[12]]), out + "/cut_teen_walk.png");
P.save(observatory(), out + "/cut_observatory.png");
P.save(door(), out + "/cut_door.png");
const pk = (fr) => P.pack(fr, { cols: fr.length, pad: 0 });
P.save(pk([jb(0), jb(1)]), out + "/cut_jania_back.png");
P.save(pk([maciej(0), maciej(1)]), out + "/cut_maciej_back.png");
P.save(P.sheet([{ buf: jb(0), scale: 4, label: "JANIA" }, { buf: maciej(0), scale: 4, label: "MACIEJ" }, { buf: maciej(1), scale: 4, label: "ODDECH" }]), __dirname + "/_cut_chars.png");
