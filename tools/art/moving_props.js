// Przeprowadzka: ciężarówka U-Howl (bok, przodem w prawo; ten sam obrys kół co wywrotka – koła rysuje gra z cut_wheel)
// i stos bagaży w pokoju (prawy dolny róg; pojawia się, gdy Etap 2 jest gotowy).
const { P, R, slab, ink } = require("./kit.js");
const out = process.argv[2];
const UH = P.hueRamp(4, { hue: 20, shift: 22, sat: 0.78, light: [0.36, 0.66] });
const WH = P.hueRamp(3, { hue: 40, shift: 12, sat: 0.25, light: [0.72, 0.92] });
const DARK = [40, 36, 46];

{ // ---- ciężarówka 64x34: kontener z napisem U-HOWL i psim logo, kabina z prawej
  const s = new P.Buf(64, 34);
  slab(s, 1, 2, 45, 27, WH, 0.95, 0.6);                      // kontener
  s.rect(1, 2, 45, 3, WH[2]);
  s.rect(1, 18, 45, 22, UH[2]); s.rect(1, 22, 45, 23, UH[1]);  // pomarańczowy pas
  P.text(s, 4, 6, "U-HOWL", UH[1]);
  // logo: psia głowa w czapeczce
  P.solid(s, [P.ell(36, 11, 4.2, 3.8)], P.hueRamp(3, { hue: 30, shift: 16, sat: 0.5, light: [0.36, 0.6] }));
  for (const [x, y] of [[32, 7], [33, 6], [40, 7], [39, 6]]) s.pset(x, y, [120, 80, 50]);
  s.rect(33, 6, 40, 8, UH[2]); s.rect(38, 8, 42, 9, UH[1]);  // czapeczka z daszkiem
  s.pset(34, 11, DARK); s.pset(37, 11, DARK); s.rect(35, 13, 37, 14, DARK);
  s.rect(0, 25, 3, 27, [96, 98, 108]); s.rect(0, 25, 1, 26, [140, 142, 150]);  // rura wydechowa z tyłu (spaliny rysuje gra)
  slab(s, 45, 9, 62, 27, UH, 0.95, 0.55);                    // kabina
  s.rect(46, 9, 58, 10, UH[3]);
  s.rect(51, 12, 60, 18, [150, 196, 230]); s.rect(51, 12, 60, 13, [200, 228, 246]); // szyba
  s.rect(48, 13, 49, 26, UH[0]);                             // drzwi
  s.rect(52, 20, 55, 21, UH[0]);                             // klamka
  s.rect(61, 19, 63, 21, [255, 230, 140]);                   // reflektor
  s.rect(60, 23, 64, 28, [120, 124, 136]);                   // zderzak
  for (const wx of [7, 41]) for (let y = 19; y < 30; y++) for (let x = wx - 1; x < wx + 16; x++) if (Math.hypot(x - wx - 7, y - 26) < 8.5) s.pset(x, y, DARK); // nadkola
  P.save(ink(s), out + "/cut_uhowl.png");
}
{ // ---- bagaże: duża brązowa walizka stojąca, niebieska leżąca na zielonej torbie, karton z taśmą
  const s = new P.Buf(58, 40);
  P.solid(s, [P.ell(36, 31, 13, 7)], P.hueRamp(3, { hue: 140, shift: 24, sat: 0.4, light: [0.28, 0.5] })); // torba
  s.rect(30, 24, 42, 25, [60, 90, 60]);
  slab(s, 26, 14, 50, 26, P.hueRamp(3, { hue: 212, shift: 20, sat: 0.5, light: [0.36, 0.6] }), 0.9, 0.5); // walizka leżąca
  s.rect(26, 14, 50, 15, [150, 186, 230]); s.rect(35, 11, 41, 14, [60, 60, 70]); s.rect(36, 12, 40, 13, 0);
  slab(s, 4, 6, 24, 38, R.wood, 0.85, 0.45);                 // walizka stojąca
  s.rect(4, 6, 24, 7, R.wood[4]); s.rect(10, 2, 18, 6, [60, 50, 50]); s.rect(11, 3, 17, 5, 0);
  for (const y of [15, 28]) s.rect(4, y, 24, y + 2, [120, 80, 50]);
  for (const y of [15, 28]) s.rect(13, y, 15, y + 2, [230, 200, 110]);
  slab(s, 44, 26, 58, 40, R.beige, 0.7, 0.45);               // karton
  s.rect(44, 26, 58, 28, R.beige[3]); s.rect(50, 26, 52, 40, [200, 170, 110]);
  P.save(ink(s), out + "/luggage.png");
}
{ // ---- neon nad obserwatorium: różowe litery w ciemnej ramce (gra miga nim przy włączaniu)
  const t = "OBSERWATORIUM", w = P.textWidth(t) + 6, s = new P.Buf(w, 11);
  s.rect(0, 0, w, 11, [30, 24, 44]); s.rect(1, 1, w - 1, 10, [44, 34, 62]);
  P.text(s, 3, 3, t, [255, 120, 200]);
  P.save(ink(s), out + "/cut_neon.png");
}
{ // ---- „HA HA” nad głową Jani w scenie (jasne litery z ciemnym cieniem)
  const s = new P.Buf(20, 13);
  for (const [t, x, y] of [["HA", 0, 0], ["HA", 9, 7]]) { P.text(s, x + 1, y + 1, t, [60, 30, 30]); P.text(s, x, y, t, [255, 236, 170]); }
  P.save(s, out + "/cut_haha.png");
}
console.log("cut_uhowl.png luggage.png cut_neon.png");
