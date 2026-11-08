// Jania – ruda królica w dżinsowych ogrodniczkach. Klatka 36x54.
// Przód i tył: geometria symetryczna względem środka klatki, światło z góry (symetryczne).
// Arkusz 7x3: rząd 0 przód [stoi, chód1, chód2, mrug, ucho opada, łapka podnosi ucho, radość],
// rząd 1 bok (w prawo) [stoi, chód 1-4], rząd 2 tył [stoi, chód1, chód2].
const P = require(process.env.CODIXEL);
const { ink } = require("./kit.js");
const K = +(process.env.JANIA_K || 1.1), FW = 36, FH = 54, CX = 17.5; // projekt w siatce 32x48 (środek x=16), skalowany x1.1
const X = (x) => (x - 16) * K + CX, Y = (y) => y * K;
const E = (x, y, rx, ry) => P.ell(X(x), Y(y), rx * K, ry * K);
const C = (ax, ay, bx, by, ra, rb = ra) => P.cap(X(ax), Y(ay), X(bx), Y(by), ra * K, rb * K);

const R = {
  fur: P.hueRamp(4, { hue: 25, shift: 26, sat: 0.72, light: [0.42, 0.74] }),
  cream: P.hueRamp(3, { hue: 34, shift: 16, sat: 0.5, light: [0.66, 0.88] }),
  denim: P.hueRamp(4, { hue: 214, shift: 26, sat: 0.5, light: [0.26, 0.6] }),
  pink: P.hueRamp(2, { hue: 352, shift: 10, sat: 0.55, light: [0.64, 0.8] }),
};
const EYE = [42, 24, 22], SHINE = [250, 244, 236], BTN = [255, 214, 92], MOUTH = [120, 50, 40];
const TOP = { light: [0, -0.62, 0.78] }; // światło z góry → cieniowanie symetryczne

// o.paw: prawa łapka przodem w punkcie [x, y] (pisze); o.carry: z boku obie łapki przed sobą, kubek
function frame(dir, f, o = {}) {
  const b = new P.Buf(FW - 2, FH - 3);
  b.ox = 1; b.oy = 1;
  const S = (prims, ramp, o) => P.solid(b, prims, ramp, { ...(dir === 1 ? {} : TOP), ...o });
  const sym = (d, y, c) => { b.pset(17 - d, y, c); b.pset(18 + d, y, c); }; // para pikseli d od środka
  const fill = (cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = 1; x <= 34; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
  const walk = f === 1 || f === 2, bob = walk ? -1 : 0, st = f === 1 ? 1 : f === 2 ? -1 : 0;

  if (dir === 0 || dir === 2) {
    const back = dir === 2, droop = !back && (f === 4 || f === 5), pawUp = !back && f === 5;
    S([E(11, 44 - Math.max(st, 0), 4, 2.2), E(21, 44 - Math.max(-st, 0), 4, 2.2)], R.cream, back ? { dark: 0.85 } : {});
    S([C(12, 39, 12, 42, 3.2), C(20, 39, 20, 42, 3.2), E(16, 35 + bob, 7, 6)], R.denim);
    const rp = o.paw || (pawUp ? [26, 16] : [25, 37 - st]);
    S([C(8, 30 + bob, 7, 37 + st, 2.1, 1.9), C(24, 30 + bob, rp[0], rp[1] + (o.paw || pawUp ? 0 : bob), 2.1, 1.9)], R.fur);
    S([E(7, 38 + st + bob, 2.1, 1.8), E(rp[0], rp[1] + 1 + (o.paw || pawUp ? 0 : bob), 2.1, 1.8)], R.cream);
    const by = Math.round(Y(30 + bob));
    if (back) S([E(16, 39 + bob, 2.6, 2.4)], R.cream);
    else {
      for (let d = 0; d < 4; d++) for (let y = by; y < by + 5; y++) sym(d, y, y === by + 4 ? R.denim[1] : R.denim[3]);
      sym(3, by, BTN); sym(0, by + 2, R.denim[2]); sym(1, by + 2, R.denim[2]);
    }
    fill(CX, Y(28.4 + bob), 6, 3, R.fur[1]); // szyja (szersza)
    // szelki przez ramiona: z tyłu krzyżują się do środka pasa, z przodu idą z karczka w górę pod brodę
    if (back) for (let i = 0; i < 7; i++) sym(Math.max(0, 4 - Math.floor(i * 0.7)), by - 2 + i, R.denim[1]);
    else for (const y of [by - 2, by - 1]) { sym(3, y, R.denim[2]); }
    // uszy: symetryczne; prawe opada w klatkach 4-5
    S([C(12, 15 + bob, 11.4, 3 + bob, 2.3, 2.7)], R.fur);
    if (droop) S([C(20, 15, 23, 11, 2.3, 2.6), C(23, 11, 28, 16, 2.6, 2.1)], R.fur);
    else S([C(20, 15 + bob, 20.6, 3 + bob, 2.3, 2.7)], R.fur);
    if (!back) {
      S([C(11.9, 13 + bob, 11.6, 5.5 + bob, 0.9, 1.2)], R.pink);
      if (!droop) S([C(20.1, 13 + bob, 20.4, 5.5 + bob, 0.9, 1.2)], R.pink);
    }
    S([E(16, 21 + bob, 9, 7.2), E(10, 23 + bob, 3.5, 3), E(22, 23 + bob, 3.5, 3)], R.fur, { ambient: 0.5 });
    if (!back) {
      const hy = Y(21.5 + bob);
      fill(CX, hy, 7.4, 5, R.fur[2]);                 // jasna buzia
      fill(CX, Y(25.2 + bob), 4.6, 2.6, R.cream[1]);  // pyszczek
      fill(CX, Y(24.3 + bob), 3.2, 1, R.cream[2]);
      const ey = Math.round(Y(19.5 + bob)), ny = Math.round(Y(23 + bob));
      if (f === 6) { // radość: oczy ^ ^, otwarty uśmiech
        for (const [d, dy] of [[3, 2], [4, 1], [5, 1], [6, 2]]) sym(d, ey + dy, EYE);
        sym(0, ny + 1, MOUTH); sym(1, ny + 1, MOUTH); sym(0, ny + 2, R.pink[0]); sym(2, ny, MOUTH);
      } else {
        sym(4, ey + 3, R.cream[2]); sym(5, ey + 3, R.cream[2]);
        if (f === 3) { sym(4, ey + 2, EYE); sym(5, ey + 2, EYE); }
        else for (const d of [4, 5]) for (let y = ey; y < ey + 3; y++) sym(d, y, EYE);
        if (f !== 3) { b.pset(12, ey, SHINE); b.pset(22, ey, SHINE); }
        sym(0, ny + 1, MOUTH); sym(1, ny + 2, MOUTH); sym(2, ny + 2, MOUTH); sym(3, ny + 1, MOUTH); // uśmiech: ʌ pod noskiem, kąciki w górę
      }
      sym(0, ny, R.pink[0]);
      sym(6, ey + 4, R.pink[1]); sym(7, ey + 4, R.pink[1]); // rumieńce
      if (pawUp) S([E(26, 16, 2.1, 1.8)], R.cream);
    }
  } else { // ---- bok, patrzy w prawo
    // chód z boku: 4 fazy (kontakt, przejście, kontakt drugą nogą, przejście); stopy jak u królika – długie, płaskie
    const ph = f - 1, sb = ph === 1 || ph === 3 ? -1 : 0;
    const near = f === 0 ? 17 : [20, 15.5, 11, 15.5][ph], far = f === 0 ? 13 : [11, 15.5, 20, 15.5][ph];
    const nearUp = ph === 1 ? 1 : 0, farUp = ph === 3 ? 1 : 0;
    S([C(14.5, 39 + sb, far, 43 - farUp, 2.1)], R.denim, { dark: 0.75 });
    S([E(far + 1.6, 45 - farUp, 3.6, 1.5)], R.cream, { dark: 0.8 });
    S([E(15, 35 + sb, 6, 6.2)], R.denim);
    S([E(9, 37 + sb, 2.6, 2.6)], R.cream);
    S([C(15.5, 39 + sb, near, 43 - nearUp, 2.3)], R.denim);
    S([E(near + 1.8, 45 - nearUp, 3.9, 1.6)], R.cream);
    const hb = sb;
    S([E(16, 28.6 + hb, 4.6, 2.6)], R.fur);
    S([C(12, 15 + hb, 9, 3 + hb, 2.2, 2.6)], R.fur, { dark: 0.8 });
    S([C(14, 15 + hb, 15, 3 + hb, 2.3, 2.8)], R.fur);
    S([C(14.4, 13 + hb, 14.9, 5 + hb, 0.8, 1.2)], R.pink);
    S([E(16, 21 + hb, 7.5, 7), E(21, 23 + hb, 4, 3.2)], R.fur);
    fill(X(21.6), Y(25 + hb), 3.4, 2.4, R.cream[1]);
    const ey = Math.round(Y(19.5 + hb)), ex = Math.round(X(18.5));
    for (let y = ey; y < ey + 3; y++) { b.pset(ex, y, EYE); b.pset(ex + 1, y, EYE); }
    b.pset(ex, ey, SHINE); b.pset(ex, ey + 3, R.cream[2]); b.pset(ex + 1, ey + 3, R.cream[2]);
    const nx = Math.round(X(24)), ny = Math.round(Y(23 + hb));
    b.pset(nx, ny, R.pink[0]); b.pset(nx - 1, ny + 1, MOUTH); b.pset(nx - 2, ny + 2, MOUTH); b.pset(nx - 3, ny + 1, MOUTH);
    b.pset(Math.round(X(19)), ey + 4, R.pink[1]);
    if (o.carry) {  // kubek trzymany oburącz przed sobą: dalsza łapka za kubkiem, bliższa z przodu
      const mx = Math.round(X(21.4)), my = Math.round(Y(31 + hb));
      S([C(15, 30 + hb, 22, 32 + hb, 2, 1.8)], R.fur, { dark: 0.75 });
      S([E(23.6, 32.6 + hb, 1.8, 1.6)], R.cream, { dark: 0.8 });
      for (let y = 0; y < 4; y++) for (let x = 0; x < 3; x++) b.pset(mx + x, my + y, y === 0 ? [206, 212, 224] : [240, 242, 248]);
      b.pset(mx + 3, my + 1, [206, 212, 224]); b.pset(mx + 3, my + 2, [206, 212, 224]);
      S([C(16, 30 + hb, 20, 34 + hb, 2.1, 1.9)], R.fur);
      S([E(21, 34.4 + hb, 1.9, 1.7)], R.cream);
    } else {
      const sw = f === 0 ? 0 : [-3, 0, 3, 0][ph]; // ręka w przeciwfazie do bliższej nogi
      S([C(16, 30 + hb, 16 + sw, 37 + hb, 2.1, 1.9)], R.fur);
      S([E(16 + sw, 38 + hb, 2, 1.8)], R.cream);
    }
  }
  return ink(P.rimLight(b, R.fur, { dir: dir === 1 ? [-1, -1] : [0, -1] }));
}

// oddech (kolumna 7): klatka spoczynkowa z górą ciała uniesioną o 1 px; stopy zostają, rząd w pasie się powiela
function breath(src, split = 40) {
  const o = new P.Buf(src.w, src.h);
  for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) o.px[y * src.w + x] = src.px[(y < split - 1 ? y + 1 : y) * src.w + x];
  return o;
}
const ROWS = [[0, 7], [1, 5], [2, 3]], COLS = 8;
const frames = [];
for (const [dir, n] of ROWS) for (let f = 0; f < COLS; f++) frames.push(f === 7 ? breath(frame(dir, 0)) : f < n ? frame(dir, f) : new P.Buf(FW, FH));
module.exports = { frames, frame, breath, FW, FH, COLS, R };

if (require.main === module) {
  P.save(P.pack(frames, { cols: COLS, pad: 0 }), process.argv[2] + "/jania.png");
  console.log("jania.png", FW, FH, COLS);
}
