// Psy z U-Howl do scenki przeprowadzki: Lili (york) i Myszka (czarna z podpalaniem). Klatka 36x54 jak Jania,
// pomarańczowe ogrodniczki i czapeczki firmy. Arkusz 8x2: rząd 0 przód [stoi, chód1, chód2, oddech, niesie, niesie-chód1,
// niesie-chód2, -], rząd 1 bok w prawo [stoi, chód 1-4, niesie-chód 1-2, -]. Lili ma wystający różowy język.
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const FW = 36, FH = 54, CX = 17.5;
const UH = P.hueRamp(4, { hue: 20, shift: 22, sat: 0.78, light: [0.36, 0.66] });
const UHV = P.hueRamp(2, { hue: 16, shift: 12, sat: 0.7, light: [0.28, 0.38] });
const BOX = P.hueRamp(3, { hue: 34, shift: 14, sat: 0.42, light: [0.5, 0.72] });
const CREAM = [250, 236, 206], EYE = [30, 20, 18], SHINE = [250, 244, 236], NOSE = [26, 20, 22], TONGUE = [236, 120, 140];
const DOGS = {
  lili: { K: 0.92, head: P.hueRamp(4, { hue: 34, shift: 22, sat: 0.5, light: [0.38, 0.7] }), body: P.hueRamp(3, { hue: 30, shift: 14, sat: 0.1, light: [0.46, 0.66] }),
    muz: P.hueRamp(2, { hue: 38, shift: 12, sat: 0.45, light: [0.7, 0.82] }), ears: "up", tongue: true },
  myszka: { K: 1.08, head: P.hueRamp(4, { hue: 224, shift: 12, sat: 0.12, light: [0.1, 0.3] }), body: P.hueRamp(3, { hue: 224, shift: 12, sat: 0.12, light: [0.12, 0.28] }),
    muz: P.hueRamp(2, { hue: 40, shift: 10, sat: 0.08, light: [0.74, 0.88] }), tan: P.hueRamp(2, { hue: 32, shift: 14, sat: 0.45, light: [0.6, 0.74] }), ears: "lop" },
};
const TOP = { light: [0, -0.62, 0.78] };

function frame(d, dir, f, carry) {
  const K = d.K, X = (x) => (x - 16) * K + CX, Y = (y) => 54 - 2 - (48 - y) * K; // stopy na dole klatki
  const E = (x, y, rx, ry) => P.ell(X(x), Y(y), rx * K, ry * K);
  const C = (ax, ay, bx, by, ra, rb = ra) => P.cap(X(ax), Y(ay), X(bx), Y(by), ra * K, rb * K);
  const b = new P.Buf(FW - 2, FH - 3); b.ox = 1; b.oy = 1;
  const S = (prims, ramp, o) => P.solid(b, prims, ramp, { ...(dir === 1 ? {} : TOP), ...o });
  const sym = (dd, y, c) => { b.pset(17 - dd, y, c); b.pset(18 + dd, y, c); };
  const fill = (cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = 1; x <= 34; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
  const box = (x0, y0, w, h) => { // karton z taśmą
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) b.pset(x0 + x, y0 + y, y < 2 ? BOX[2] : x === Math.floor(w / 2) || x === Math.floor(w / 2) - 1 ? [200, 170, 110] : BOX[1]);
  };
  if (dir === 0) {
    const walk = f === 1 || f === 2, bob = walk ? -1 : 0, st = f === 1 ? 1 : f === 2 ? -1 : 0;
    S([E(11, 45 - Math.max(st, 0), 3.6, 2), E(21, 45 - Math.max(-st, 0), 3.6, 2)], d.muz);       // stopy
    S([C(12, 39, 12, 43, 3.2), C(20, 39, 20, 43, 3.2), E(16, 35 + bob, 7.4, 6.4)], UH);       // nogawki i brzuch
    if (!carry) {
      S([C(8, 30 + bob, 7, 37 + st, 2.1, 1.9), C(24, 30 + bob, 25, 37 - st, 2.1, 1.9)], d.body);
      S([E(7, 38 + st + bob, 2, 1.7), E(25, 38 - st + bob, 2, 1.7)], d.muz);
    }
    const by = Math.round(Y(30 + bob));
    for (let dd = 0; dd < 4; dd++) for (let y = by; y < by + 5; y++) sym(dd, y, y === by + 4 ? UH[1] : UH[3]);
    sym(3, by, CREAM);
    fill(CX, Y(28.4 + bob), 6, 3, d.body[1]);
    for (const y of [by - 2, by - 1]) sym(3, y, UH[2]);
    if (d.ears === "up") S([C(10, 18 + bob, 5, 6 + bob, 3.2, 1), C(22, 18 + bob, 27, 6 + bob, 3.2, 1)], d.head); // sterczące, w bok
    S([E(16, 21 + bob, 9, 7.4), E(10, 24 + bob, 3.6, 3), E(22, 24 + bob, 3.6, 3)], d.head, { ambient: 0.5 });
    if (d.ears === "lop") S([C(8.5, 18 + bob, 7, 28 + bob, 2.8, 2.2), C(23.5, 18 + bob, 25, 28 + bob, 2.8, 2.2)], d.head, { dark: 0.85 }); // opadają po bokach
    const ey = Math.round(Y(20 + bob)), ny = Math.round(Y(23.4 + bob));
    fill(CX, Y(25 + bob), 4.4, 2.6, d.muz[1]);
    if (d.tan) { sym(4, ey - 2, d.tan[1]); sym(5, ey - 2, d.tan[1]); sym(6, ey + 3, d.tan[0]); sym(7, ey + 2, d.tan[0]); }
    if (f === 3 && false) { } else for (const dd of [4, 5]) for (let y = ey; y < ey + 3; y++) sym(dd, y, EYE);
    b.pset(13, ey, SHINE); b.pset(22, ey, SHINE);
    sym(0, ny, NOSE); sym(1, ny, NOSE); sym(0, ny + 1, NOSE);
    if (d.tongue) { sym(0, ny + 2, TONGUE); sym(0, ny + 3, TONGUE); b.pset(17, ny + 4, TONGUE); b.pset(18, ny + 4, TONGUE); }
    else { sym(1, ny + 2, [70, 64, 66]); sym(2, ny + 2, [70, 64, 66]); }
    // czapeczka: kopuła i daszek
    const cy = Math.round(Y(14.4 + bob));
    for (let dd = 0; dd < 6; dd++) for (let y = cy - 3 + (dd > 3 ? 1 : 0) + (dd > 4 ? 1 : 0); y <= cy; y++) sym(dd, y, y === cy - 3 + (dd > 3 ? 1 : 0) + (dd > 4 ? 1 : 0) ? UH[3] : UH[2]);
    for (let dd = 0; dd < 7; dd++) sym(dd, cy + 1, UHV[1]);
    sym(0, cy - 1, CREAM);
    if (carry) { // karton trzymany przed sobą oburącz
      box(9, Math.round(Y(29 + bob)), 18, 11);
      S([E(9, 34 + bob, 2, 1.7), E(23, 34 + bob, 2, 1.7)], d.muz);
    }
  } else {
    const walkF = f >= 1, ph = (f - 1) % 4, sb = walkF && (ph === 1 || ph === 3) ? -1 : 0;
    const near = !walkF ? 17 : [20, 15.5, 11, 15.5][ph], far = !walkF ? 13 : [11, 15.5, 20, 15.5][ph];
    S([C(14.5, 39 + sb, far, 43, 2.1)], UH, { dark: 0.75 });
    S([E(far + 1.6, 45, 3.2, 1.4)], d.muz, { dark: 0.8 });
    S([E(15, 35 + sb, 6.4, 6.4)], UH);
    S([C(15.5, 39 + sb, near, 43, 2.3)], UH);
    S([E(near + 1.8, 45, 3.4, 1.5)], d.muz);
    S([E(16, 28.6 + sb, 4.6, 2.6)], d.body);
    if (d.ears === "up") S([C(13, 17 + sb, 9, 6 + sb, 3, 1)], d.head);
    S([E(15, 21 + sb, 7.5, 7), E(21, 23.5 + sb, 4.4, 3.2)], d.head);
    if (d.ears === "lop") S([C(12, 18 + sb, 11, 28 + sb, 2.8, 2.2)], d.head, { dark: 0.85 });
    fill(X(22), Y(25 + sb), 3.4, 2.2, d.muz[1]);
    const ey = Math.round(Y(19.8 + sb)), ex = Math.round(X(18.5)), nx = Math.round(X(25)), ny = Math.round(Y(23 + sb));
    for (let y = ey; y < ey + 3; y++) { b.pset(ex, y, EYE); b.pset(ex + 1, y, EYE); }
    b.pset(ex, ey, SHINE);
    if (d.tan) { b.pset(ex, ey - 2, d.tan[1]); b.pset(ex + 1, ey - 2, d.tan[1]); }
    b.pset(nx, ny, NOSE); b.pset(nx - 1, ny, NOSE); b.pset(nx, ny + 1, NOSE);
    if (d.tongue) { b.pset(nx - 2, ny + 2, TONGUE); b.pset(nx - 2, ny + 3, TONGUE); b.pset(nx - 1, ny + 3, TONGUE); }
    const cy = Math.round(Y(14.6 + sb)), cx0 = Math.round(X(9.5));  // czapeczka, daszek do przodu
    for (let x = 0; x < 11; x++) for (let y = cy - (x > 1 && x < 9 ? 3 : 2); y <= cy; y++) b.pset(cx0 + x, y, y <= cy - 2 ? UH[3] : UH[2]);
    for (let x = 9; x < 15; x++) b.pset(cx0 + x, cy + 1, UHV[1]);
    if (carry) {
      box(Math.round(X(18)), Math.round(Y(28 + sb)), 12, 10);
      S([E(26, 33 + sb, 2, 1.7)], d.muz);
    } else {
      const sw = !walkF ? 0 : [-3, 0, 3, 0][ph];
      S([C(16, 30 + sb, 16 + sw, 37 + sb, 2.1, 1.9)], d.body);
      S([E(16 + sw, 38 + sb, 2, 1.7)], d.muz);
    }
  }
  return ink(b);
}
function breath(src, split = 40) {
  const o = new P.Buf(src.w, src.h);
  for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) o.px[y * src.w + x] = y >= split ? src.px[y * src.w + x] : y > 0 ? src.px[(y - 1) * src.w + x] : 0;
  return o;
}
const out = process.argv[2];
const sheets = [];
for (const [name, d] of Object.entries(DOGS)) {
  const fr = [frame(d, 0, 0), frame(d, 0, 1), frame(d, 0, 2), breath(frame(d, 0, 0)), frame(d, 0, 0, true), frame(d, 0, 1, true), frame(d, 0, 2, true), new P.Buf(FW, FH),
    frame(d, 1, 0), frame(d, 1, 1), frame(d, 1, 2), frame(d, 1, 3), frame(d, 1, 4), frame(d, 1, 1, true), frame(d, 1, 3, true), new P.Buf(FW, FH)];
  P.save(P.pack(fr, { cols: 8, pad: 0 }), `${out}/cut_${name}.png`);
  sheets.push(...fr.slice(0, 7).map((b) => ({ buf: b, scale: 4 })), ...fr.slice(8, 15).map((b) => ({ buf: b, scale: 4 })));
}
P.save(P.sheet(sheets, { cols: 7 }), __dirname + "/_dogs_sprites.png");
console.log("cut_lili.png cut_myszka.png", FW, FH);
