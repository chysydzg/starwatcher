// Remont starego budynku nad jeziorem (scenka przeprowadzki): ten sam szary budynek co w widoku z balkonu
// (balcony.js, obj w 150,165, 74x42), w kolejnych etapach. Sprite 76x44 stawiany w grze w (149, 164).
// 0 zabity deskami, 1 deski zdjęte z dwóch okien, 2 wszystkie okna oszklone, pół ściany pomalowane, drzwi bez desek,
// 3 cały biały, nowe drzwi, 4 jedno okno świeci, 5 wszystkie okna i lampka nad drzwiami.
const { P, obj } = require("./kit.js");
const out = process.argv[2];
const g = P.hueRamp(4, { hue: 230, shift: 20, sat: 0.12, light: [0.12, 0.3] });
const w = P.hueRamp(4, { hue: 214, shift: 22, sat: 0.12, light: [0.4, 0.66] });   // biała farba w nocnej palecie widoku
const pine = P.hueRamp(4, { hue: 170, shift: 40, sat: 0.3, light: [0.1, 0.3] });
const glass = [44, 58, 92], warm = [255, 214, 128], warmD = [214, 150, 80], dark = [12, 12, 20];
const plank = [70, 58, 56], plank2 = [52, 44, 46];
const WIN = [10, 22, 46, 58];
function stage(k) {
  const up = k >= 6 ? 12 : 0;  // 6: teleskop wystaje z kopuły, sprite wyższy o 12 px (w grze w 147, 150)
  const T = new P.Buf(80, 50 + up);
  obj(T, 3, 3 + up, 74, 42, (s) => {
    const paint = k >= 3 ? 74 : k >= 2 ? 37 : 0;  // malowanie od lewej
    const col = (x, ramp, gr) => (x < paint ? w : gr);
    P.solid(s, [P.ell(37, 13, 13, 11)], k >= 3 ? w : g, { ambient: 0.4 });
    for (let y = 16; y < 42; y++) for (let x = 4; x < 70; x++) s.pset(x, y, col(x, w, g)[x < 8 || x > 66 ? 1 : 2]);
    for (let y = 13; y < 17; y++) for (let x = 2; x < 72; x++) s.pset(x, y, col(x, w, g)[y === 13 ? 3 : 2]);
    s.rect(24, 13, 51, 17, (k >= 3 ? w : g)[2]); s.rect(36, 3, 39, 13, [16, 14, 24]);
    WIN.forEach((x, i) => {
      const lit = k >= 5 || (k === 4 && i === 1);
      const open = k >= 2 || (k === 1 && i < 2);
      s.rect(x, 22, x + 6, 30, open ? (lit ? warm : glass) : dark);
      if (open) { s.rect(x, 22, x + 6, 23, (x < paint ? w : g)[0]); s.rect(x + 3, 22, x + 4, 30, (x < paint ? w : g)[0]); if (lit) s.rect(x + 1, 27, x + 3, 30, warmD); }
      else { s.rect(x - 1, 23, x + 7, 25, plank); s.rect(x - 1, 27, x + 7, 28, plank2); s.line(x, 29, x + 6, 22, plank2); }
    });
    if (k >= 3) { s.rect(31, 30, 43, 42, [88, 96, 118]); s.rect(31, 30, 43, 31, [60, 66, 86]); s.pset(41, 36, warm); }  // nowe drzwi
    else s.rect(31, 30, 43, 42, dark);
    if (k < 2) { s.rect(30, 33, 44, 35, plank); s.rect(30, 38, 44, 39, plank2); s.line(31, 41, 43, 31, plank); }
    if (k >= 5) s.rect(34, 28, 40, 29, warm);                                        // lampka nad drzwiami
    if (k < 3) s.rect(56, 34, 72, 42, pine[1]);                                      // krzaki pod ścianą, wycięte przy malowaniu
  }, { lit: [60, 64, 90], shade: [10, 10, 18] });
  if (k >= 6) {  // teleskop w szczelinie kopuły: stożek ku obiektywowi, pierścień, czarny outline
    const steel = P.hueRamp(4, { hue: 222, shift: 20, sat: 0.14, light: [0.3, 0.72] });
    const t = new P.Buf(80, 62);
    P.solid(t, [P.cap(40, 24, 50, 9, 1.6, 3.2)], steel, { light: [-0.5, -0.7, 0.5] });
    P.solid(t, [P.cap(50, 9, 51, 7.5, 3.4, 3.4)], w, { light: [-0.5, -0.7, 0.5] });
    for (let y = 0; y < 62; y++) for (let x = 0; x < 80; x++) {  // tylko nad dachem kopuły i w szczelinie
      const c = t.get(x, y);
      if (c >>> 24 && (y < 17 || (x >= 39 && x <= 42 && y < 28))) T.pset(x, y, c);
    }
    for (let y = 1; y < 61; y++) for (let x = 1; x < 79; x++) {  // outline tuby tam, gdzie styka się z niebem
      if (T.get(x, y) >>> 24) continue;
      if ([[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => { const c = t.get(x + dx, y + dy); return c >>> 24 && y + dy < 17; })) T.pset(x, y, [10, 10, 18]);
    }
  }
  return T;
}
for (let k = 0; k <= 6; k++) P.save(stage(k), `${out}/cut_repair_${k}.png`);
P.save(P.sheet([0, 1, 2, 3, 4, 5, 6].map((k) => ({ buf: stage(k), scale: 4, label: "ETAP " + k })), { cols: 3 }), __dirname + "/_repair.png");
console.log("cut_repair_0..6");
