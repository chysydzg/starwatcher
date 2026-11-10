// Psy z U-Howl do scenki przeprowadzki: Lili (york, mała jak Jania) i Myszka (duża, czarna z podpalaniem).
// Klatka 44x64 (stopy na dole), pomarańczowe ogrodniczki i czapeczki firmy, ogon wystaje ze spodni i macha.
// Arkusz 10x2: rząd 0 przód [machanie 0-3, chód 1-2, niesie, niesie-chód 1-2, -],
//              rząd 1 bok w prawo [machanie 0-3, chód 1-4, niesie-chód 1-2]. Gra odtwarza machanie 0,1,2,3,2,1.
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const FW = 44, FH = 64, CX = 21.5, COLS = 10;
const UH = P.hueRamp(4, { hue: 20, shift: 22, sat: 0.78, light: [0.36, 0.66] });
const UHV = P.hueRamp(2, { hue: 16, shift: 12, sat: 0.7, light: [0.28, 0.38] });
const BOX = P.hueRamp(3, { hue: 34, shift: 14, sat: 0.42, light: [0.5, 0.72] });
const CREAM = [250, 236, 206], EYE = [30, 20, 18], SHINE = [250, 244, 236], NOSE = [26, 20, 22], TONGUE = [236, 120, 140];
const DOGS = {
  lili: { K: 0.88, head: P.hueRamp(4, { hue: 24, shift: 22, sat: 0.52, light: [0.3, 0.64] }), body: P.hueRamp(3, { hue: 30, shift: 14, sat: 0.1, light: [0.46, 0.66] }),
    muz: P.hueRamp(2, { hue: 34, shift: 12, sat: 0.45, light: [0.66, 0.8] }), ears: "up", tongue: true, tail: "short" },
  myszka: { K: 1.28, head: P.hueRamp(4, { hue: 224, shift: 12, sat: 0.12, light: [0.1, 0.3] }), body: P.hueRamp(3, { hue: 224, shift: 12, sat: 0.12, light: [0.12, 0.28] }),
    muz: P.hueRamp(2, { hue: 40, shift: 10, sat: 0.08, light: [0.74, 0.88] }), tan: P.hueRamp(2, { hue: 32, shift: 14, sat: 0.45, light: [0.6, 0.74] }), ears: "lop", tail: "long" },
};
const TOP = { light: [0, -0.62, 0.78] };
const WAG = [-1, -0.6, 0.6, 1];  // z przodu ogon zawsze wystaje zza bioder, raz z jednej, raz z drugiej strony

// dir 0 przód / 1 bok; walk: -1 stoi, 0..3 faza chodu; wag: -1..1 wychylenie ogona
function frame(d, dir, walk, carry, wag) {
  const K = d.K, X = (x) => (x - 16) * K + CX, Y = (y) => FH - 2 - (48 - y) * K;
  const E = (x, y, rx, ry) => P.ell(X(x), Y(y), rx * K, ry * K);
  const C = (ax, ay, bx, by, ra, rb = ra) => P.cap(X(ax), Y(ay), X(bx), Y(by), ra * K, rb * K);
  const b = new P.Buf(FW - 2, FH - 3); b.ox = 1; b.oy = 1;
  const S = (prims, ramp, o) => P.solid(b, prims, ramp, { ...(dir === 1 ? {} : TOP), ...o });
  const L = Math.floor(CX), Rr = L + 1, px = (s) => Math.max(1, Math.round(s * K)); // piksele skalowane z psem
  const sym = (dd, y, c) => { b.pset(L - dd, y, c); b.pset(Rr + dd, y, c); };
  const fill = (cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = 1; x <= FW - 2; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
  const box = (x0, y0, w, h) => { // karton z taśmą
    x0 = Math.round(x0); y0 = Math.round(y0); w = Math.round(w); h = Math.round(h);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) b.pset(x0 + x, y0 + y, y < 2 ? BOX[2] : x === Math.floor(w / 2) || x === Math.floor(w / 2) - 1 ? [200, 170, 110] : BOX[1]);
  };
  const tailR = d.tail === "long" ? 1.5 : 1.7, tailL = d.tail === "long" ? 9 : 6;
  if (dir === 0) {
    const walking = walk >= 0, bob = walking ? -1 : 0, st = walk === 0 ? 1 : walk === 1 ? -1 : 0;
    // ogon za ciałem: wychodzi ze spodni nad biodrem i wychyla się na boki
    const tx = 16 + wag * 12.8, ty = 37 - tailL * 0.6 * (1 - 0.3 * Math.abs(wag));  // koniec ogona za łapką, nie za ręką
    S([C(16, 36 + bob, tx, ty + bob, tailR, tailR * 0.8)], d.tail === "long" ? d.body : d.head, { dark: 0.9 });
    S([E(11, 45 - Math.max(st, 0), 3.6, 2), E(21, 45 - Math.max(-st, 0), 3.6, 2)], d.muz);       // stopy
    S([C(12, 39, 12, 43, 3.2), C(20, 39, 20, 43, 3.2), E(16, 35 + bob, 7.4, 6.4)], UH);       // nogawki i brzuch
    if (!carry) {
      S([C(8, 30 + bob, 7, 37 + st, 2.1, 1.9), C(24, 30 + bob, 25, 37 - st, 2.1, 1.9)], d.body);
      S([E(7, 38 + st + bob, 2, 1.7), E(25, 38 - st + bob, 2, 1.7)], d.muz);
    }
    const by = Math.round(Y(30 + bob)), bw = px(4);
    for (let dd = 0; dd < bw; dd++) for (let y = by; y < by + px(5); y++) sym(dd, y, y === by + px(5) - 1 ? UH[1] : UH[3]);
    sym(bw - 1, by, CREAM);
    fill(CX, Y(28.4 + bob), 6 * K, 3 * K, d.body[1]);
    for (let y = by - px(2); y < by; y++) sym(bw - 1, y, UH[2]);
    if (d.ears === "up") S([C(10.5, 17 + bob, 6.8, 8 + bob, 3.0, 0.8), C(21.5, 17 + bob, 25.2, 8 + bob, 3.0, 0.8)], d.head);
    S([E(16, 21 + bob, 9, 7.4), E(10, 24 + bob, 3.6, 3), E(22, 24 + bob, 3.6, 3)], d.head, { ambient: 0.5 });
    if (d.ears === "lop") S([C(9.5, 16 + bob, 6.5, 20 + bob, 2.4, 1.8), C(22.5, 16 + bob, 25.5, 20 + bob, 2.4, 1.8)], d.head, { dark: 0.85 });
    const ey = Math.round(Y(20 + bob)), ny = Math.round(Y(23.4 + bob)), e0 = px(4), eh = px(3);
    fill(CX, Y(25 + bob), 4.4 * K, 2.6 * K, d.muz[1]);
    if (d.tan) { for (const dd of [e0, e0 + 1]) sym(dd, ey - 2, d.tan[1]); sym(e0 + 2, ey + eh, d.tan[0]); sym(e0 + 3, ey + eh - 1, d.tan[0]); }
    for (const dd of [e0, e0 + 1]) for (let y = ey; y < ey + eh; y++) sym(dd, y, EYE);
    b.pset(L - e0 - 1, ey, SHINE); b.pset(Rr + e0, ey, SHINE);
    sym(0, ny, NOSE); sym(1, ny, NOSE); sym(0, ny + 1, NOSE);
    if (K > 1.1) { sym(2, ny, NOSE); sym(1, ny + 1, NOSE); }
    if (d.tongue) { sym(0, ny + 2, TONGUE); sym(0, ny + 3, TONGUE); }
    else { sym(1, ny + 3, [70, 64, 66]); sym(2, ny + 3, [70, 64, 66]); }
    // czapeczka: kopuła i daszek (szerokość z głową)
    const cy = Math.round(Y(14.4 + bob)), cw = px(6), ch = px(3);
    for (let dd = 0; dd < cw; dd++) { const top = cy - ch + (dd >= cw - 2 ? 1 : 0) + (dd === cw - 1 ? 1 : 0); for (let y = top; y <= cy; y++) sym(dd, y, y === top ? UH[3] : UH[2]); }
    for (let dd = 0; dd < cw + 1; dd++) sym(dd, cy + 1, UHV[1]);
    sym(0, cy - 1, CREAM);
    if (carry) { // karton obejmowany oburącz: ręce po bokach, łapki na bocznych ściankach kartonu
      S([C(8, 30 + bob, 7.6, 34 + bob, 2.1, 1.9), C(24, 30 + bob, 24.4, 34 + bob, 2.1, 1.9)], d.body);
      box(X(8.4), Y(29 + bob), 15.2 * K, 11 * K);
      S([E(7.9, 35 + bob, 1.6, 2), E(24.1, 35 + bob, 1.6, 2)], d.muz);
    }
  } else {
    const walking = walk >= 0, sb = walking && (walk === 1 || walk === 3) ? -1 : 0;
    const near = !walking ? 17 : [20, 15.5, 11, 15.5][walk], far = !walking ? 13 : [11, 15.5, 20, 15.5][walk];
    // ogon z tyłu spodni, macha góra-dół
    const ta = (d.tail === "long" ? 0.55 : 1.0) + wag * 0.35;
    S([C(9.5, 37 + sb, 9.5 - Math.cos(ta) * tailL, 37 + sb - Math.sin(ta) * tailL, tailR, tailR * 0.8)], d.tail === "long" ? d.body : d.head, { dark: 0.9 });
    S([C(14.5, 39 + sb, far, 43, 2.1)], UH, { dark: 0.75 });
    S([E(far + 1.6, 45, 3.2, 1.4)], d.muz, { dark: 0.8 });
    S([E(15, 35 + sb, 6.4, 6.4)], UH);
    S([C(15.5, 39 + sb, near, 43, 2.3)], UH);
    S([E(near + 1.8, 45, 3.4, 1.5)], d.muz);
    S([E(16, 28.6 + sb, 4.6, 2.6)], d.body);
    if (d.ears === "up") S([C(13, 16 + sb, 11, 8.5 + sb, 2.8, 0.8)], d.head);
    S([E(15, 21 + sb, 7.5, 7), E(21, 23.5 + sb, 4.4, 3.2)], d.head);
    if (d.ears === "lop") S([C(12, 16 + sb, 10.5, 20.5 + sb, 2.4, 1.8)], d.head, { dark: 0.85 });
    fill(X(22), Y(25 + sb), 3.4 * K, 2.2 * K, d.muz[1]);
    const ey = Math.round(Y(19.8 + sb)), ex = Math.round(X(18.5)), nx = Math.round(X(25)), ny = Math.round(Y(23 + sb)), eh = px(3);
    for (let y = ey; y < ey + eh; y++) { b.pset(ex, y, EYE); b.pset(ex + 1, y, EYE); }
    b.pset(ex, ey, SHINE);
    if (d.tan) { b.pset(ex, ey - 2, d.tan[1]); b.pset(ex + 1, ey - 2, d.tan[1]); }
    b.pset(nx, ny, NOSE); b.pset(nx - 1, ny, NOSE); b.pset(nx, ny + 1, NOSE);
    if (d.tongue) { b.pset(nx - 2, ny + 2, TONGUE); b.pset(nx - 2, ny + 3, TONGUE); }
    const cy = Math.round(Y(14.6 + sb)), cx0 = Math.round(X(9.5)), cw = px(11), ch = px(3);  // czapeczka, daszek do przodu
    for (let x = 0; x < cw; x++) for (let y = cy - (x > 1 && x < cw - 2 ? ch : ch - 1); y <= cy; y++) b.pset(cx0 + x, y, y <= cy - ch + 1 ? UH[3] : UH[2]);
    for (let x = cw - 2; x < cw + px(4); x++) b.pset(cx0 + x, cy + 1, UHV[1]);
    if (carry) { // z boku: karton przed sobą, bliższa ręka obejmuje go od dołu
      box(X(18), Y(28 + sb), 12 * K, 10 * K);
      S([C(16, 30 + sb, 19, 37 + sb, 2.1, 1.9)], d.body);
      S([E(20.5, 37.4 + sb, 2, 1.6)], d.muz);
    } else {
      const sw = !walking ? 0 : [-3, 0, 3, 0][walk];
      S([C(16, 30 + sb, 16 + sw, 37 + sb, 2.1, 1.9)], d.body);
      S([E(16 + sw, 38 + sb, 2, 1.7)], d.muz);
    }
  }
  return ink(b);
}
const out = process.argv[2];
const sheets = [];
for (const [name, d] of Object.entries(DOGS)) {
  const front = [...WAG.map((w) => frame(d, 0, -1, false, w)), frame(d, 0, 0, false, -0.8), frame(d, 0, 1, false, 0.8),
    frame(d, 0, -1, true, 0.8), frame(d, 0, 0, true, -0.8), frame(d, 0, 1, true, 0.8), new P.Buf(FW, FH)];
  const side = [...WAG.map((w) => frame(d, 1, -1, false, w)), ...[0, 1, 2, 3].map((k) => frame(d, 1, k, false, k % 2 ? 0.4 : -0.4)),
    frame(d, 1, 1, true, 0.4), frame(d, 1, 3, true, -0.4)];
  P.save(P.pack([...front, ...side], { cols: COLS, pad: 0 }), `${out}/cut_${name}.png`);
  sheets.push(...front.slice(0, 9).map((b) => ({ buf: b, scale: 3 })), ...side.slice(0, 9).map((b) => ({ buf: b, scale: 3 })));
}
P.save(P.sheet(sheets, { cols: 9 }), __dirname + "/_dogs_sprites.png");
console.log("cut_lili.png cut_myszka.png", FW, FH, COLS);
