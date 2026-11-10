// Arbjooze (GDD: pierwszy pracownik): szarobury pręgowany kotek, biały pyszczek, pierś i „skarpetki”, zielone oczy,
// różowy nosek, biały kitel badacza. Lewa przednia łapka to proteza (tu: chwytak). Referencja autora: zdjęcie kota.
// Klatka 40x58, stopy na dole. Arkusz 5x2: rząd 0 przód [stoi, mruga, chód 1-2, macha chwytakiem],
// rząd 1 bok w prawo [stoi, chód 1-4]. Lewo = odbicie w grze (proteza zostaje na „bliższej” łapie).
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const FW = 40, FH = 58, CX = 19.5, K = 0.92, COLS = 5;
const TAB = P.hueRamp(4, { hue: 34, shift: 18, sat: 0.16, light: [0.2, 0.56] });      // szarobury
const STRIPE = [52, 44, 40];
const WHITE = P.hueRamp(3, { hue: 40, shift: 10, sat: 0.12, light: [0.8, 0.96] });     // futro
const COAT = P.hueRamp(3, { hue: 214, shift: 14, sat: 0.1, light: [0.74, 0.97] });     // kitel
const STEEL = P.hueRamp(3, { hue: 220, shift: 16, sat: 0.12, light: [0.56, 0.9] });
const EYE = [132, 200, 64], EYED = [70, 130, 40], PUPIL = [26, 20, 22], SHINE = [250, 250, 240], NOSE = [236, 150, 164], EARIN = [222, 160, 168];
const TOP = { light: [0, -0.62, 0.78] };

function frame(dir, walk, wave = false, blink = false) {
  const X = (x) => (x - 16) * K + CX, Y = (y) => FH - 2 - (48 - y) * K;
  const E = (x, y, rx, ry) => P.ell(X(x), Y(y), rx * K, ry * K);
  const C = (ax, ay, bx, by, ra, rb = ra) => P.cap(X(ax), Y(ay), X(bx), Y(by), ra * K, rb * K);
  const b = new P.Buf(FW - 2, FH - 3); b.ox = 1; b.oy = 1;
  const S = (prims, ramp, o) => P.solid(b, prims, ramp, { ...(dir === 1 ? {} : TOP), ...o });
  const L = Math.floor(CX), R = L + 1;
  const sym = (dd, y, c) => { b.pset(L - dd, y, c); b.pset(R + dd, y, c); };
  const walking = walk >= 0;
  const gripper = (x, y, open) => {  // proteza: stalowy mankiet i dwa haczyki szczypiec
    S([E(x, y, 2.2, 1.8)], STEEL);
    const px = Math.round(X(x)), py = Math.round(Y(y));
    for (const [dx, dy] of [[-2, 2], [-2, 3], [-1, 4], [2, 2], [2, 3], [1, 4]]) b.pset(px + (dx < 0 ? dx - (open ? 1 : 0) : dx + (open ? 1 : 0)), py + dy, STEEL[0]);
  };
  if (dir === 0) {
    const bob = walking ? -1 : 0, st = walk === 0 ? 1 : walk === 1 ? -1 : 0;
    S([C(20, 38 + bob, 28, 30 + bob, 1.7, 1.5)], TAB, { dark: 0.9 });                          // ogon zza kitla
    for (const [x, y] of [[23, 36], [26, 33]]) b.pset(Math.round(X(x)), Math.round(Y(y + bob)), STRIPE);
    S([E(11.5, 45 - Math.max(st, 0), 3.4, 1.9), E(20.5, 45 - Math.max(-st, 0), 3.4, 1.9)], WHITE);  // białe skarpetki
    S([C(12, 39, 12, 43, 2.8), C(20, 39, 20, 43, 2.8)], TAB);
    S([C(16, 29 + bob, 16, 40 + bob, 6.2, 7.6)], COAT);                                         // kitel
    for (let y = Math.round(Y(31 + bob)); y <= Math.round(Y(41 + bob)); y++) b.pset(L, y, COAT[0]);  // rozcięcie kitla
    for (let dd = 0; dd < 3; dd++) for (let y = Math.round(Y(27.5 + bob)); y < Math.round(Y(30.5 + bob)) - dd; y++) sym(dd, y, WHITE[2]);  // biała pierś w dekolcie
    for (let i = 0; i < 4; i++) { const y = Math.round(Y(28.6 + bob)) + i; sym(3 - Math.floor(i * 0.75), y, COAT[0]); }  // kołnierz kitla w serek
    S([C(8, 29 + bob, 7, 36 + st, 2.2, 2.0)], COAT);                                            // prawa ręka (rękaw) + biała łapka
    S([E(7, 37 + st + bob, 2, 1.7)], WHITE);
    if (wave) { S([C(24, 29 + bob, 27, 22 + bob, 2.2, 2.0)], COAT); gripper(27.4, 20.2 + bob, true); }
    else { S([C(24, 29 + bob, 25, 36 - st, 2.2, 2.0)], COAT); gripper(25, 37 - st + bob, false); }
    S([C(10.5, 17 + bob, 8.6, 8.5 + bob, 3.2, 0.6), C(21.5, 17 + bob, 23.4, 8.5 + bob, 3.2, 0.6)], TAB);  // uszy
    S([C(10.6, 15.5 + bob, 9.5, 11 + bob, 1.4, 0.3), C(21.4, 15.5 + bob, 22.5, 11 + bob, 1.4, 0.3)], [EARIN, EARIN, EARIN], { dark: 1 });
    S([E(16, 21 + bob, 9.4, 7.6), E(10.5, 24 + bob, 3.6, 3), E(21.5, 24 + bob, 3.6, 3)], TAB, { ambient: 0.5 });
    const top = Math.round(Y(15 + bob)), bot = Math.round(Y(28 + bob));
    for (let y = top; y <= bot; y++) {                                                          // biała łata: wąsko na czole, szeroko na pyszczku
      const u = (y - top) / (bot - top), w = Math.round(u < 0.45 ? 0.6 + u * 3 : 2 + (u - 0.45) * 6);
      for (let dd = 0; dd <= w; dd++) sym(dd, y, WHITE[u > 0.5 ? 2 : 1]);
    }
    for (const dd of [4, 6]) for (let y = Math.round(Y(13.6 + bob)); y < Math.round(Y(16.6 + bob)); y++) sym(dd, y, STRIPE);  // pręgi na czole
    for (const y of [Math.round(Y(22 + bob)), Math.round(Y(24 + bob))]) { sym(7, y, STRIPE); sym(8, y, STRIPE); }   // pręgi na policzkach
    const ey = Math.round(Y(19.5 + bob)), ny = Math.round(Y(23.6 + bob));
    for (const dd of [3, 4, 5]) for (let y = ey; y < ey + 3; y++) sym(dd, y, blink ? TAB[1] : y === ey + 2 ? EYED : EYE);
    if (blink) for (const dd of [3, 4, 5]) sym(dd, ey + 2, PUPIL);
    else { for (let y = ey; y < ey + 3; y++) sym(4, y, PUPIL); b.pset(L - 3, ey, SHINE); b.pset(R + 5, ey, SHINE); }
    sym(0, ny, NOSE); sym(1, ny, NOSE); sym(0, ny + 1, NOSE);
    sym(1, ny + 3, TAB[0]); sym(2, ny + 3, TAB[0]);
  } else {
    const sb = walking && (walk === 1 || walk === 3) ? -1 : 0;
    const near = !walking ? 17 : [20, 15.5, 11, 15.5][walk], far = !walking ? 13 : [11, 15.5, 20, 15.5][walk];
    S([C(10, 37 + sb, 3, 30 + sb, 1.7, 1.4)], TAB, { dark: 0.9 });                            // ogon w tył i w górę
    for (const [x, y] of [[7, 34], [5, 32]]) b.pset(Math.round(X(x)), Math.round(Y(y + sb)), STRIPE);
    S([C(14.5, 39 + sb, far, 43, 2.0)], TAB, { dark: 0.75 });
    S([E(far + 1.6, 45, 3.0, 1.4)], WHITE, { dark: 0.8 });
    S([C(15.5, 29 + sb, 15.5, 38 + sb, 5.2, 6.2)], COAT);
    S([C(15.5, 39 + sb, near, 43, 2.2)], TAB);
    S([E(near + 1.8, 45, 3.2, 1.5)], WHITE);
    S([C(13, 17 + sb, 11.5, 8.5 + sb, 3.0, 0.6), C(17.5, 16 + sb, 19, 8.5 + sb, 2.6, 0.6)], TAB);
    S([E(15, 21 + sb, 7.6, 7), E(21, 23.5 + sb, 4.2, 3.1)], TAB);
    S([E(22, 24.6 + sb, 3.2, 2.2)], WHITE, { dark: 1 });
    for (const x of [11, 13]) for (let y = Math.round(Y(14.6 + sb)); y < Math.round(Y(17.4 + sb)); y++) b.pset(Math.round(X(x)), y, STRIPE);
    const ey = Math.round(Y(19.4 + sb)), ex = Math.round(X(18.6)), nx = Math.round(X(25)), ny = Math.round(Y(22.6 + sb));
    for (let y = ey; y < ey + 3; y++) { b.pset(ex, y, y === ey + 2 ? EYED : EYE); b.pset(ex + 1, y, PUPIL); }
    b.pset(ex, ey, SHINE);
    b.pset(nx, ny, NOSE); b.pset(nx - 1, ny, NOSE);
    const sw = !walking ? 0 : [-3, 0, 3, 0][walk];
    S([C(16, 29 + sb, 17 + sw, 36 + sb, 2.1, 1.9)], COAT);                                     // bliższa łapa: rękaw i chwytak
    gripper(17.2 + sw, 37 + sb, false);
  }
  return ink(b);
}
const out = process.argv[2];
const front = [frame(0, -1), frame(0, -1, false, true), frame(0, 0), frame(0, 1), frame(0, -1, true)];
const side = [frame(1, -1), ...[0, 1, 2, 3].map((k) => frame(1, k))];
P.save(P.pack([...front, ...side], { cols: COLS, pad: 0 }), `${out}/arbjooze.png`);
P.save(P.sheet([...front, ...side].map((buf) => ({ buf, scale: 5 })), { cols: COLS }), __dirname + "/_cat.png");
console.log("arbjooze.png", FW, FH, COLS);
