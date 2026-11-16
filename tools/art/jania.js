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
const TEAR = [150, 200, 240], EYE = [42, 24, 22], SHINE = [250, 244, 236], BTN = [255, 214, 92], MOUTH = [120, 50, 40];
const TOP = { light: [0, -0.62, 0.78] }; // światło z góry → cieniowanie symetryczne

// o.paw: prawa łapka przodem w punkcie [x, y] (pisze); o.carry: z boku obie łapki przed sobą, kubek
function frame(dir, f, o = {}) {
  const b = new P.Buf(FW - 2, FH - 3);
  b.ox = 1; b.oy = 1;
  const S = (prims, ramp, o) => P.solid(b, prims, ramp, { ...(dir === 1 ? {} : TOP), ...o });
  const sym = (d, y, c) => { b.pset(17 - d, y, c); b.pset(18 + d, y, c); }; // para pikseli d od środka
  const fill = (cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = 1; x <= 34; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
  // o.walk = k (0..7): pełny cykl chodu – kontakt, dół, przejście, góra (x2). Ciało buja się góra-dół, stopa w wykroku
  // odrywa się łukiem, ręce idą w przeciwfazie do nóg, a uszy i ogonek spóźniają się o klatkę (follow-through).
  const k = o.walk, W = k != null, BOB = [1, 2, 1, 0, 1, 2, 1, 0], LIFT = [0, 0, 0, 0, 1, 3, 3.6, 1.6];  // bujanie tylko w dół: czubki uszu leżą w górnym rzędzie klatki
  const walk = W || f === 1 || f === 2, bob = W ? BOB[k] : walk ? -1 : 0, st = W ? 0 : f === 1 ? 1 : f === 2 ? -1 : 0;
  const lag = W ? BOB[(k + 7) % 8] : bob;                       // uszy: bujanie z poprzedniej klatki
  const lL = W ? LIFT[k] : Math.max(st, 0), lR = W ? LIFT[(k + 4) % 8] : Math.max(-st, 0);
  const sw = W ? Math.cos(k * Math.PI / 4) : 0;                 // +1: lewa noga w wykroku → prawa ręka z przodu

  if (dir === 0 || dir === 2) {
    const back = dir === 2, droop = !back && (f === 4 || f === 5), pawUp = !back && f === 5;
    // stopa w powietrzu jest mniejsza (dalej od ziemi), ta w wykroku odrobinę większa
    const foot = (x, l, fwd) => E(x + (l > 1 ? (x < 16 ? 0.8 : -0.8) : 0), 44 - l, l > 1 ? 3.4 : fwd ? 4.3 : 4, l > 1 ? 2 : 2.2);
    S([foot(11, lL, W && sw > 0.5), foot(21, lR, W && sw < -0.5)], R.cream, back ? { dark: 0.85 } : {});
    S([C(12, 39, 12, 42 - lL * 0.7, 3.2), C(20, 39, 20, 42 - lR * 0.7, 3.2), E(16, 35 + bob, 7, 6)], R.denim);
    const rp = o.paw || (pawUp ? [26, 16] : o.yawn === 2 ? [19, 26] : [25 + (W ? 0.4 * sw : 0), 37 - st + 1.6 * sw]); // ziewanie: łapka idzie do buzi
    const la = [7 - (W ? 0.4 * sw : 0), 37 + st - 1.6 * sw];
    S([C(8, 30 + bob, la[0], la[1], 2.1, 1.9), C(24, 30 + bob, rp[0], rp[1] + (o.paw || pawUp ? 0 : bob), 2.1, 1.9)], R.fur);
    S([E(la[0], la[1] + 1 + bob, 2.1, 1.8), E(rp[0], rp[1] + 1 + (o.paw || pawUp ? 0 : bob), 2.1, 1.8)], R.cream);
    const by = Math.round(Y(30 + bob));
    if (back) S([E(16, 39 + lag, 2.6, 2.4)], R.cream);
    else {
      for (let d = 0; d < 4; d++) for (let y = by; y < by + 5; y++) sym(d, y, y === by + 4 ? R.denim[1] : R.denim[3]);
      sym(3, by, BTN); sym(0, by + 2, R.denim[2]); sym(1, by + 2, R.denim[2]);
    }
    fill(CX, Y(28.4 + bob), 6, 3, R.fur[1]); // szyja (szersza)
    // szelki przez ramiona: z tyłu krzyżują się do środka pasa, z przodu idą z karczka w górę pod brodę
    if (back) for (let i = 0; i < 7; i++) sym(Math.max(0, 4 - Math.floor(i * 0.7)), by - 2 + i, R.denim[1]);
    else for (const y of [by - 2, by - 1]) { sym(3, y, R.denim[2]); }
    // uszy: symetryczne; prawe opada w klatkach 4-5
    const ex = 0;  // końce uszu rozchylają się, gdy głowa opada szybciej niż one
    S([C(12, 15 + bob, 11.4 - ex, 3 + lag, 2.3, 2.7)], R.fur);
    if (droop) S([C(20, 15, 23, 11, 2.3, 2.6), C(23, 11, 28, 16, 2.6, 2.1)], R.fur);
    else S([C(20, 15 + bob, 20.6 + ex, 3 + lag, 2.3, 2.7)], R.fur);
    if (!back) {
      S([C(11.9, 13 + bob, 11.6 - ex, 5.5 + lag, 0.9, 1.2)], R.pink);
      if (!droop) S([C(20.1, 13 + bob, 20.4 + ex, 5.5 + lag, 0.9, 1.2)], R.pink);
    }
    S([E(16, 21 + bob, 9, 7.2), E(10, 23 + bob, 3.5, 3), E(22, 23 + bob, 3.5, 3)], R.fur, { ambient: 0.5 });
    if (!back) {
      const hy = Y(21.5 + bob);
      fill(CX, hy, 7.4, 5, R.fur[2]);                 // jasna buzia
      fill(CX, Y(25.2 + bob), 4.6, 2.6, R.cream[1]);  // pyszczek
      fill(CX, Y(24.3 + bob), 3.2, 1, R.cream[2]);
      const ey = Math.round(Y(19.5 + bob)), ny = Math.round(Y(23 + bob));
      if (o.yawn) { // ziewanie: oczy zaciśnięte; 1 – szeroko otwarta buzia, 2 – łapka zasłania usta, 3 – senne oczy
        if (o.yawn === 3) for (const d of [4, 5]) sym(d, ey + 2, EYE);
        else for (const [d, dy] of [[3, 1], [4, 2], [5, 2], [6, 1]]) sym(d, ey + dy, EYE);
        if (o.yawn === 1) { for (const d of [0, 1]) for (let y = ny + 1; y <= ny + 4; y++) sym(d, y, MOUTH); sym(0, ny + 4, R.pink[0]); sym(2, ny + 2, MOUTH); sym(2, ny + 3, MOUTH); }
        else if (o.yawn === 3) { sym(0, ny + 1, MOUTH); sym(1, ny + 1, MOUTH); }
      } else if (f === 6) { // radość: oczy ^ ^, otwarty uśmiech
        for (const [d, dy] of [[3, 2], [4, 1], [5, 1], [6, 2]]) sym(d, ey + dy, EYE);
        sym(0, ny + 1, MOUTH); sym(1, ny + 1, MOUTH); sym(0, ny + 2, R.pink[0]); sym(2, ny, MOUTH);
      } else if (o.sad) { // smutek (szpital): brwi uniesione do środka, oczy w dół, usta w podkówkę; o.cry: łza
        for (const [d, dy] of [[3, -3], [4, -2], [5, -2], [6, -1]]) sym(d, ey + dy, R.fur[0]);
        for (const d of [4, 5]) for (let y = ey + 1; y < ey + 3; y++) sym(d, y, EYE);
        if (o.cry) sym(4, ey + 3, TEAR);
        sym(0, ny + 1, MOUTH); sym(1, ny + 1, MOUTH); sym(2, ny + 2, MOUTH);
      } else {
        sym(4, ey + 3, R.cream[2]); sym(5, ey + 3, R.cream[2]);
        if (f === 3) { sym(4, ey + 2, EYE); sym(5, ey + 2, EYE); }
        else for (const d of [4, 5]) for (let y = ey; y < ey + 3; y++) sym(d, y, EYE);
        if (f !== 3) { b.pset(12, ey, SHINE); b.pset(22, ey, SHINE); }
        sym(0, ny + 1, MOUTH); sym(1, ny + 2, MOUTH); sym(2, ny + 2, MOUTH); sym(3, ny + 1, MOUTH); // uśmiech: ʌ pod noskiem, kąciki w górę
      }
      sym(0, ny, R.pink[0]);
      if (!o.sad) { sym(6, ey + 4, R.pink[1]); sym(7, ey + 4, R.pink[1]); } // rumieńce
      if (pawUp) S([E(26, 16, 2.1, 1.8)], R.cream);
      if (o.yawn === 2) S([E(18.5, 25.5 + bob, 2.6, 2.2)], R.cream); // łapka na ustach
    }
  } else { // ---- bok, patrzy w prawo
    // chód z boku: 4 fazy (kontakt, przejście, kontakt drugą nogą, przejście); stopy jak u królika – długie, płaskie
    const ph = f - 1, sb = W ? bob : ph === 1 || ph === 3 ? -1 : 0;
    // stopa: 5 klatek na ziemi (jedzie równo do tyłu), 3 w powietrzu (łuk do przodu)
    const FX = [20.5, 18, 15.5, 13, 10.5, 11.5, 15.5, 19.5], FU = [0, 0, 0, 0, 0, 2, 3, 1.4];
    const near = W ? FX[k] : f === 0 ? 17 : [20, 15.5, 11, 15.5][ph], far = W ? FX[(k + 4) % 8] : f === 0 ? 13 : [11, 15.5, 20, 15.5][ph];
    const nearUp = W ? FU[k] : ph === 1 ? 1 : 0, farUp = W ? FU[(k + 4) % 8] : ph === 3 ? 1 : 0;
    const swS = W ? -(near - 15.5) * 0.75 : f === 0 ? 0 : [-3, 0, 3, 0][ph]; // ręka w przeciwfazie do bliższej nogi
    if (W) {  // dalsza ręka: widać ją, gdy wychodzi przed albo za tułów
      S([C(15.5, 30 + sb, 15.5 - swS, 36.5 + sb, 2, 1.8)], R.fur, { dark: 0.75 });
      S([E(15.5 - swS, 37.5 + sb, 1.9, 1.7)], R.cream, { dark: 0.8 });
    }
    S([C(14.5, 39 + sb, far, 43 - farUp, 2.1)], R.denim, { dark: 0.75 });
    S([E(far + 1.6, 45 - farUp, 3.6, 1.5)], R.cream, { dark: 0.8 });
    S([E(15, 35 + sb, 6, 6.2)], R.denim);
    S([E(9, 37 + (W ? lag : sb), 2.6, 2.6)], R.cream);
    S([C(15.5, 39 + sb, near, 43 - nearUp, 2.3)], R.denim);
    S([E(near + 1.8, 45 - nearUp, 3.9, 1.6)], R.cream);
    const hb = sb;
    S([E(16, 28.6 + hb, 4.6, 2.6)], R.fur);
    const eb = W ? -1 + 0.6 * (lag - bob) : 0;  // w biegu uszy kładą się lekko do tyłu i sprężynują
    S([C(12, 15 + hb, 9 + eb, 3 + (W ? lag : hb), 2.2, 2.6)], R.fur, { dark: 0.8 });
    S([C(14, 15 + hb, 15 + eb, 3 + (W ? lag : hb), 2.3, 2.8)], R.fur);
    S([C(14.4, 13 + hb, 14.9 + eb * 0.8, 5 + (W ? lag : hb), 0.8, 1.2)], R.pink);
    S([E(16, 21 + hb, 7.5, 7), E(21, 23 + hb, 4, 3.2)], R.fur);
    fill(X(21.6), Y(25 + hb), 3.4, 2.4, R.cream[1]);
    const ey = Math.round(Y(19.5 + hb)), ex = Math.round(X(18.5));
    const nx = Math.round(X(24)), ny = Math.round(Y(23 + hb));
    if (o.sad) { // smutek: powieka w dół, brew uniesiona z przodu, kącik ust w dół; o.cry: łza
      for (let y = ey + 1; y < ey + 3; y++) { b.pset(ex, y, EYE); b.pset(ex + 1, y, EYE); }
      b.pset(ex - 1, ey - 1, R.fur[0]); b.pset(ex, ey - 2, R.fur[0]); b.pset(ex + 1, ey - 2, R.fur[0]);
      if (o.cry) { b.pset(ex, ey + 3, TEAR); b.pset(ex, ey + 4, TEAR); }
      b.pset(nx, ny, R.pink[0]); b.pset(nx - 1, ny + 2, MOUTH); b.pset(nx - 2, ny + 2, MOUTH); b.pset(nx - 3, ny + 3, MOUTH);
    } else {
      for (let y = ey; y < ey + 3; y++) { b.pset(ex, y, EYE); b.pset(ex + 1, y, EYE); }
      b.pset(ex, ey, SHINE); b.pset(ex, ey + 3, R.cream[2]); b.pset(ex + 1, ey + 3, R.cream[2]);
      b.pset(nx, ny, R.pink[0]); b.pset(nx - 1, ny + 1, MOUTH); b.pset(nx - 2, ny + 2, MOUTH); b.pset(nx - 3, ny + 1, MOUTH);
      b.pset(Math.round(X(19)), ey + 4, R.pink[1]);
    }
    if (o.carry) {  // kubek trzymany oburącz przed sobą: dalsza łapka za kubkiem, bliższa z przodu
      const mx = Math.round(X(21.4)), my = Math.round(Y(31 + hb));
      S([C(15, 30 + hb, 22, 32 + hb, 2, 1.8)], R.fur, { dark: 0.75 });
      S([E(23.6, 32.6 + hb, 1.8, 1.6)], R.cream, { dark: 0.8 });
      for (let y = 0; y < 4; y++) for (let x = 0; x < 3; x++) b.pset(mx + x, my + y, y === 0 ? [206, 212, 224] : [240, 242, 248]);
      b.pset(mx + 3, my + 1, [206, 212, 224]); b.pset(mx + 3, my + 2, [206, 212, 224]);
      S([C(16, 30 + hb, 20, 34 + hb, 2.1, 1.9)], R.fur);
      S([E(21, 34.4 + hb, 1.9, 1.7)], R.cream);
    } else {
      S([C(16, 30 + hb, 16 + swS, 37 + hb - Math.abs(swS) * 0.2, 2.1, 1.9)], R.fur);
      S([E(16 + swS, 38 + hb - Math.abs(swS) * 0.2, 2, 1.8)], R.cream);
    }
  }
  return ink(P.rimLight(b, R.fur, { dir: dir === 1 ? [-1, -1] : [0, -1] }));
}

// oddech (kolumna 7): klatka spoczynkowa z górą ciała opuszczoną o 1 px (wydech); stopy zostają, jeden rząd w pasie
// znika. W dół, nie w górę: obrys czubków uszu leży w górnym rzędzie klatki i nie może z niej wyjechać.
function breath(src, split = 40) {
  const o = new P.Buf(src.w, src.h);
  for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) o.px[y * src.w + x] = y >= split ? src.px[y * src.w + x] : y > 0 ? src.px[(y - 1) * src.w + x] : 0;
  return o;
}
const ROWS = [[0, 7], [1, 5], [2, 3]], COLS = 8;
const frames = [];
for (const [dir, n] of ROWS) for (let f = 0; f < COLS; f++) frames.push(f === 7 ? breath(frame(dir, 0)) : f < n ? frame(dir, f) : new P.Buf(FW, FH));
module.exports = { frames, frame, breath, FW, FH, COLS, R };

if (require.main === module) {
  P.save(P.pack(frames, { cols: COLS, pad: 0 }), process.argv[2] + "/jania.png");
  // chód: 8 klatek na kierunek (rzędy: przód, bok, tył)
  const wf = [0, 1, 2].flatMap((d) => [...Array(8)].map((_, k) => frame(d, 0, { walk: k })));
  P.save(P.pack(wf, { cols: 8, pad: 0 }), process.argv[2] + "/jania_walk.png");
  for (const d of [0, 1, 2]) require("fs").writeFileSync(process.argv[2] + `/_walk${d}.gif`, P.gif(wf.slice(d * 8, d * 8 + 8).map((b) => { const g = new P.Buf(b.w, b.h); g.rect(0, 0, b.w, b.h, [200, 190, 170]); g.sprite(b, 0, 0); return g; }), { delay: 60, scale: 5 }));
  P.save(P.sheet(wf.map((b, i) => ({ buf: b, label: "" + (i % 8) })), { cols: 8, scale: 4 }), process.argv[2] + "/_walk_sheet.png");
  // ziewanie na koniec nocy (world.gd): 3 klatki przodem
  P.save(P.pack([1, 2, 3].map((k) => frame(0, 0, { yawn: k })), { cols: 3, pad: 0 }), process.argv[2] + "/jania_yawn.png");
  // szpital: ten sam arkusz ze smutną miną, bez łez (jania_sad) i z łzami, gdy płacze razem z portretem (jania_cry)
  for (const [name, o] of [["jania_sad", { sad: true }], ["jania_cry", { sad: true, cry: true }]]) {
    const sh = [];
    for (const [dir, n] of ROWS) for (let f = 0; f < COLS; f++) sh.push(f === 7 ? breath(frame(dir, 0, o)) : f < n ? frame(dir, f, o) : new P.Buf(FW, FH));
    P.save(P.pack(sh, { cols: COLS, pad: 0 }), process.argv[2] + "/" + name + ".png");
  }
  console.log("jania.png", FW, FH, COLS);
}
