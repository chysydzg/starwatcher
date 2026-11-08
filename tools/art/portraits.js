// Portrety do okienek dialogu (88x88, przezroczyste tło), rysowane od zera pixel artem.
// Zdjęcia autora służą tylko za wzór: kolory, proporcje (duża okrągła głowa, puszyste policzki, jasna obwódka oka).
// Maciej: srebrzysty, lewe ucho stoi, prawe opada wzdłuż policzka, brązowe oczy, okrągłe okulary, biały kitel.
// Jania (dziecko, mniejsza w kadrze): ruda, kremowy pyszczek, oba uszy w górę, dwa siekacze, dżinsowe ogrodniczki.
const P = require(process.env.CODIXEL);
const OUT = process.argv[2] || ".";
const L = { light: [-0.5, -0.62, 0.6] };  // jedno światło z lewej u góry
const INK = [24, 20, 32];
const ramp = (n, o) => P.hueRamp(n, o);
const S = (b, prims, r, o = {}) => P.solid(b, prims, r, { ...L, ...o });
const E = P.ell, C = P.cap;
const fillEll = (b, cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = Math.floor(cx - rx); x <= cx + rx; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
const line = (b, ax, ay, bx, by, c) => { const n = Math.max(Math.abs(bx - ax), Math.abs(by - ay)); for (let i = 0; i <= n; i++) b.pset(Math.round(ax + (bx - ax) * i / n), Math.round(ay + (by - ay) * i / n), c); };

// oko: obwódka (jasna sierść), tęczówka, źrenica, dwa odblaski
function eye(b, x, y, iris, ring) {
  fillEll(b, x, y, 4.2, 4.8, ring);
  fillEll(b, x, y, 3, 3.6, iris[1]);
  fillEll(b, x, y + 0.6, 2, 2.6, iris[0]);
  b.pset(x - 1, y - 2, [250, 246, 238]); b.pset(x - 2, y - 2, [250, 246, 238]); b.pset(x - 1, y - 1, [250, 246, 238]);
  b.pset(x + 1, y + 2, iris[2]);
}

function maciej() {
  const b = new P.Buf(88, 88);
  const fur = ramp(5, { hue: 224, shift: 26, sat: 0.1, light: [0.28, 0.8] });
  const coat = ramp(4, { hue: 212, shift: 18, sat: 0.12, light: [0.66, 0.96] });
  const shirt = ramp(3, { hue: 208, shift: 18, sat: 0.4, light: [0.4, 0.64] });
  const inner = ramp(3, { hue: 350, shift: 16, sat: 0.18, light: [0.5, 0.7] });
  const iris = [[46, 24, 16], [118, 70, 38], [170, 112, 64]];
  S(b, [E(44, 66, 7, 5)], fur);                                               // krótka szyja
  S(b, [E(44, 98, 42, 28)], coat);                                            // kitel: szerokie ramiona tuż pod głową
  for (let y = 70; y < 88; y++) { const d = (y - 70) >> 1; for (let x = 44 - d - 2; x <= 44 + d + 2; x++) b.pset(x, y, shirt[1]); }
  for (let y = 70; y < 88; y++) { const d = (y - 70) >> 1; b.pset(42 - d - 2, y, coat[1]); b.pset(46 + d + 2, y, coat[1]); } // klapy
  for (let y = 74; y < 88; y++) b.pset(44, y, shirt[0]);                        // guziki koszuli w linii
  for (let x = 60; x < 68; x++) b.pset(x, 80, coat[1]);                         // kieszeń na piersi
  for (let y = 75; y < 80; y++) { b.pset(63, y, [70, 110, 200]); b.pset(65, y, [210, 70, 60]); } // długopisy
  S(b, [C(33, 30, 26, 2, 5.6, 4.4)], fur);                                    // ucho stoi
  S(b, [C(32.6, 28, 26.6, 6, 2.6, 2)], inner);
  S(b, [E(44, 46, 22, 19), E(29, 56, 10, 8.5), E(59, 56, 10, 8.5)], fur);     // głowa z puszystymi policzkami
  S(b, [C(54, 29, 64, 31, 3.6, 4.6), C(64, 31, 70, 42, 4.6, 5.4), C(70, 42, 70, 58, 5.4, 4.6)], fur, { dark: 0.85 }); // ucho opada wzdłuż policzka
  line(b, 59, 30, 66, 34, fur[1]); line(b, 66, 34, 68, 43, fur[1]); line(b, 68, 43, 68, 56, fur[1]); // fałda ucha
  fillEll(b, 44, 60, 9, 6, fur[3]);                                           // jaśniejszy pyszczek
  fillEll(b, 44, 63, 6, 3.4, fur[4]);
  eye(b, 34, 46, iris, fur[3]); eye(b, 54, 46, iris, fur[3]);
  for (const [x, y] of [[34, 46], [54, 46]])                                  // okrągłe okulary
    for (let a = 0; a < 80; a++) b.pset(Math.round(x + Math.cos(a / 80 * 6.283) * 7), Math.round(y + Math.sin(a / 80 * 6.283) * 7), INK);
  line(b, 41, 45, 47, 45, INK);                                               // mostek
  line(b, 27, 45, 22, 43, INK); line(b, 61, 45, 65, 43, INK);                 // zauszniki
  b.pset(31, 41, [236, 244, 255]); b.pset(51, 41, [236, 244, 255]);            // błysk na szkle
  fillEll(b, 44, 56, 2.6, 1.6, [168, 120, 130]); b.pset(43, 55, [206, 160, 168]); // nos
  line(b, 44, 58, 44, 60, fur[0]); line(b, 44, 60, 41, 62, fur[0]); line(b, 44, 60, 47, 62, fur[0]); // pyszczek Y
  for (const s of [-1, 1]) { line(b, 44 + s * 8, 60, 44 + s * 20, 57, fur[4]); line(b, 44 + s * 8, 62, 44 + s * 20, 63, fur[4]); } // wąsy
  return P.selout(b, fur[1], INK);
}

function jania() {
  const b = new P.Buf(88, 88);
  const fur = ramp(5, { hue: 24, shift: 28, sat: 0.72, light: [0.34, 0.74] });
  const cream = ramp(3, { hue: 34, shift: 16, sat: 0.5, light: [0.7, 0.9] });
  const denim = ramp(4, { hue: 214, shift: 26, sat: 0.5, light: [0.28, 0.6] });
  const pink = ramp(3, { hue: 350, shift: 12, sat: 0.55, light: [0.58, 0.82] });
  const iris = [[30, 18, 16], [64, 36, 28], [120, 80, 60]];
  S(b, [E(44, 100, 32, 26), E(44, 69, 6, 4)], fur);                           // ramiona tuż pod głową, krótka szyja
  S(b, [E(44, 79, 8, 5)], cream);                                             // kremowa pierś
  for (let y = 80; y < 88; y++) for (let x = 31; x <= 57; x++) b.pset(x, y, y === 80 ? denim[3] : denim[2]); // śliniak
  for (let y = 83; y < 88; y++) for (let x = 39; x <= 49; x++) b.pset(x, y, denim[1]);                   // kieszonka
  for (const x of [31, 32, 56, 57]) for (let y = 76; y < 81; y++) b.pset(x, y, denim[1]);                // szelki
  for (const x of [32, 56]) { b.pset(x, 82, [255, 214, 92]); b.pset(x - 1 + (x > 44 ? 1 : 0), 82, [255, 214, 92]); }
  S(b, [C(36, 34, 31, 10, 4.6, 3.8), C(52, 34, 57, 10, 4.6, 3.8)], fur);      // uszy (mniejsza głowa: dziecko)
  S(b, [C(35.6, 32, 31.6, 13, 2.2, 1.6), C(52.4, 32, 56.4, 13, 2.2, 1.6)], pink);
  S(b, [E(44, 50, 18, 16), E(33, 58, 8, 6.5), E(55, 58, 8, 6.5)], fur);       // głowa, policzki
  fillEll(b, 44, 61, 8, 5, cream[1]);                                         // pyszczek
  fillEll(b, 44, 63, 5.5, 3, cream[2]);
  eye(b, 36, 50, iris, cream[0]); eye(b, 52, 50, iris, cream[0]);
  fillEll(b, 29, 57, 2.4, 1.4, pink[1]); fillEll(b, 59, 57, 2.4, 1.4, pink[1]); // rumieńce
  fillEll(b, 44, 58, 2.2, 1.4, pink[0]); b.pset(43, 57, pink[2]);             // nosek
  line(b, 44, 60, 44, 61, fur[0]); line(b, 44, 61, 42, 62, fur[0]); line(b, 44, 61, 46, 62, fur[0]);
  for (const x of [42, 43, 45, 46]) for (let y = 63; y < 66; y++) b.pset(x, y, y === 65 ? [220, 212, 200] : [252, 248, 240]); // dwa siekacze
  for (let y = 63; y < 66; y++) b.pset(44, y, [196, 186, 176]);
  for (const s of [-1, 1]) line(b, 44 + s * 7, 61, 44 + s * 17, 59, cream[2]);  // wąsiki
  return P.selout(b, fur[1], INK);
}

const M = maciej(), J = jania();
P.save(J, OUT + "/portrait_jania.png"); P.save(M, OUT + "/portrait_maciej.png");
P.save(P.sheet([{ buf: J, scale: 4, label: "JANIA" }, { buf: M, scale: 4, label: "MACIEJ" }, { buf: J, scale: 1 }, { buf: M, scale: 1 }]), __dirname + "/_portraits.png");
