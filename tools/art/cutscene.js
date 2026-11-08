// Intro: postacie od tyłu na balkonie. Mała Jania (jania.js w skali dziecka) i jej tata Maciej:
// srebrzysty królik w białym kitlu, jedno ucho stoi, drugie opada. Po 2 klatki: stoi, oddech (1 px w górę).
process.env.JANIA_K = "0.82";
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const jania = require("./jania.js");
const FUR = P.hueRamp(4, { hue: 222, shift: 24, sat: 0.08, light: [0.34, 0.72] });
const COAT = P.hueRamp(4, { hue: 210, shift: 18, sat: 0.12, light: [0.6, 0.94] });
const TOP = { light: [0, -0.62, 0.78] };

function maciej(f) {  // proporcje jak Jania od tyłu (duża głowa, małe ciało), x1.15, w kitlu
  const b = new P.Buf(40, 64), bob = f ? -1 : 0, S = (prims, r, o) => P.solid(b, prims, r, { ...TOP, ...o });
  S([P.ell(15, 60, 3.6, 1.8), P.ell(25, 60, 3.6, 1.8)], FUR, { dark: 0.85 });                 // stopy
  S([P.cap(12, 33 + bob, 10, 47, 2.6, 2.4), P.cap(28, 33 + bob, 30, 47, 2.6, 2.4)], COAT, { dark: 0.82 }); // rękawy
  S([P.ell(10, 48, 2.2, 2), P.ell(30, 48, 2.2, 2)], FUR);                                    // łapki
  S([P.cap(20, 32 + bob, 20, 55, 7.5, 9.5)], COAT);                                          // kitel
  for (let y = 48; y < 58; y++) b.pset(20, y, COAT[0]);                                      // rozcięcie z tyłu
  for (let x = 13; x <= 27; x++) b.pset(x, 44, COAT[1]);                                     // pasek
  S([P.ell(20, 30.5 + bob, 6, 2.4)], COAT, { dark: 0.9 });                                   // kołnierz
  S([P.cap(16, 16 + bob, 15.2, 6 + bob, 2.5, 2.8)], FUR);                                  // ucho stoi
  S([P.ell(20, 22 + bob, 9.5, 7.5), P.ell(13.5, 24.5 + bob, 3.6, 3), P.ell(26.5, 24.5 + bob, 3.6, 3)], FUR, { ambient: 0.5 });
  S([P.cap(24, 16 + bob, 26, 7 + bob, 2.4, 2.5), P.cap(26, 7 + bob, 31, 9 + bob, 2.5, 2.4), P.cap(31, 9 + bob, 32, 15 + bob, 2.4, 2.1)], FUR, { dark: 0.9 }); // ucho złamane: wstaje i opada na bok
  b.pset(11, 23 + bob, [26, 22, 34]); b.pset(29, 23 + bob, [26, 22, 34]);                    // zauszniki okularów
  return ink(P.smoothEdge(b));
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
P.save(observatory(), out + "/cut_observatory.png");
P.save(door(), out + "/cut_door.png");
const pk = (fr) => P.pack(fr, { cols: fr.length, pad: 0 });
P.save(pk([jb(0), jb(1)]), out + "/cut_jania_back.png");
P.save(pk([maciej(0), maciej(1)]), out + "/cut_maciej_back.png");
P.save(P.sheet([{ buf: jb(0), scale: 4, label: "JANIA" }, { buf: maciej(0), scale: 4, label: "MACIEJ" }, { buf: maciej(1), scale: 4, label: "ODDECH" }]), __dirname + "/_cut_chars.png");
