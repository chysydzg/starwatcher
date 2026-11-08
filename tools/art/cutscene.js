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
  S([P.cap(24, 16 + bob, 29, 19 + bob, 2.4, 2.7), P.cap(29, 19 + bob, 30.5, 29 + bob, 2.7, 2.2)], FUR, { dark: 0.9 }); // ucho opada
  b.pset(11, 23 + bob, [26, 22, 34]); b.pset(29, 23 + bob, [26, 22, 34]);                    // zauszniki okularów
  return ink(b);
}
const jbb = P.bounds(jania.frames[16]);
const jb = (f) => P.crop(jania.frames[16 + (f ? 7 : 0)], jbb.x, jbb.y - 1, jbb.w, jbb.h + 1);  // rząd 2 = tył; 7. kolumna = oddech
const out = process.argv[2];
const pk = (fr) => P.pack(fr, { cols: fr.length, pad: 0 });
P.save(pk([jb(0), jb(1)]), out + "/cut_jania_back.png");
P.save(pk([maciej(0), maciej(1)]), out + "/cut_maciej_back.png");
P.save(P.sheet([{ buf: jb(0), scale: 4, label: "JANIA" }, { buf: maciej(0), scale: 4, label: "MACIEJ" }, { buf: maciej(1), scale: 4, label: "ODDECH" }]), __dirname + "/_cut_chars.png");
