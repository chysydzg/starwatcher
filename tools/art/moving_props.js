// Przeprowadzka: ciężarówka U-Howl (bok, przodem w prawo; ten sam obrys kół co wywrotka – koła rysuje gra z cut_wheel)
// i stos bagaży w pokoju (prawy dolny róg; pojawia się, gdy Etap 2 jest gotowy).
const { P, R, slab, ink } = require("./kit.js");
const out = process.argv[2];
const UH = P.hueRamp(4, { hue: 20, shift: 22, sat: 0.78, light: [0.36, 0.66] });
const WH = P.hueRamp(3, { hue: 40, shift: 12, sat: 0.25, light: [0.72, 0.92] });
const DARK = [40, 36, 46];

{ // ---- ciężarówka 46x24 (skala: drzwi obserwatorium 14 px = 2 m): kontener z napisem U-HOWL i psim logo, kabina z prawej
  const s = new P.Buf(46, 24);
  slab(s, 0, 1, 31, 19, WH, 0.95, 0.6);                      // kontener
  s.rect(0, 1, 31, 2, WH[2]);
  s.rect(0, 13, 31, 16, UH[2]); s.rect(0, 16, 31, 17, UH[1]);  // pomarańczowy pas
  P.text(s, 1, 4, "U-HOWL", UH[1]);
  P.solid(s, [P.ell(28, 7, 2.6, 2.4)], P.hueRamp(3, { hue: 30, shift: 16, sat: 0.5, light: [0.36, 0.6] }));  // logo: psia głowa
  s.rect(26, 4, 31, 5, UH[2]); s.pset(27, 7, DARK); s.pset(29, 7, DARK);
  s.rect(0, 17, 2, 18, [96, 98, 108]);                       // rura wydechowa z tyłu (spaliny rysuje gra)
  slab(s, 31, 6, 45, 19, UH, 0.95, 0.55);                    // kabina
  s.rect(31, 6, 41, 7, UH[3]);
  s.rect(36, 8, 45, 12, [150, 196, 230]); s.rect(36, 8, 45, 9, [200, 228, 246]);  // szyba aż do przodu (przednia szyba)
  s.rect(33, 9, 34, 18, UH[0]);                              // drzwi
  s.rect(44, 13, 46, 15, [255, 230, 140]);                   // reflektor
  s.rect(43, 16, 46, 19, [120, 124, 136]);                   // zderzak
  P.save(ink(s), out + "/cut_uhowl.png");
}
{ // ---- małe koło ciężarówki (11x11 z obrysem), 4 klatki obrotu: opona z bieżnikiem, jasna felga
  const fr = [0, 1, 2, 3].map((f) => {
    const b = new P.Buf(9, 9), a0 = f * Math.PI / 8;
    for (let y = 0; y < 9; y++) for (let x = 0; x < 9; x++) {
      const d = Math.hypot(x - 4, y - 4);
      if (d > 4.4) continue;
      let c = d < 1.8 ? [236, 236, 240] : d < 2.6 ? [150, 154, 166] : [40, 36, 46];
      const a = Math.atan2(y - 4, x - 4) - a0, m = ((a % (Math.PI / 2)) + Math.PI / 2) % (Math.PI / 2);
      if (d >= 3.2 && m < 0.35) c = [84, 82, 92];
      b.pset(x, y, c);
    }
    b.pset(4, 4, [90, 90, 100]);
    return P.outline(b, [18, 12, 22]);
  });
  P.save(P.pack(fr, { cols: 4, pad: 0 }), out + "/cut_wheel_s.png");
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
{ // ---- „HA HA” nad głową Jani w scenie (jasne litery z ciemnym cieniem)
  const s = new P.Buf(20, 13);
  for (const [t, x, y] of [["HA", 0, 0], ["HA", 9, 7]]) { P.text(s, x + 1, y + 1, t, [60, 30, 30]); P.text(s, x, y, t, [255, 236, 170]); }
  P.save(s, out + "/cut_haha.png");
}
console.log("cut_uhowl.png cut_wheel_s.png luggage.png cut_haha.png");
