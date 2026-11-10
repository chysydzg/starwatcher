// Portrety do okienek dialogu (88x88, przezroczyste tło), pixel art od zera.
// Zasady z referencji autora (pixelartowe króliki): czysty 1 px ciemny obrys bez ząbków, głowa szeroka i zaokrąglona,
// policzki rozszerzają ją u dołu, głowa siedzi wprost na ramionach (bez szyi), uszy jak zaokrąglone prostokąty
// z jaśniejszym środkiem, duże proste oczy z białym odblaskiem, jasny pyszczek, mały nosek, płaskie 2–3 tony na
// materiał, światło z góry (cieniowanie symetryczne). Kształty z masek (każda część wygładzona osobno),
// lustrzane względem środka; wyjątki to celowo asymetryczne opadnięte ucho Macieja i długopisy w kieszeni.
const P = require(process.env.CODIXEL);
const OUT = process.argv[2] || ".";
const W = 88, H = 88, CX = 44;           // oś symetrii między pikselem 43 i 44
const INK = [30, 22, 36];

class Canvas {
  constructor() { this.part = new Array(W * H).fill(null); this.col = new Array(W * H).fill(null); this.parts = {}; }
  // kształt z funkcji (środki pikseli), maska wygładzona osobno; mirror = lustro względem osi
  add(name, inside, ramp, o = {}) {
    let m = new Uint8Array(W * H);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      const px = x + 0.5, py = y + 0.5;
      if (inside(px, py) || (o.mirror && inside(2 * CX - px, py))) m[y * W + x] = 1;
    }
    if (!o.raw) m = P.smoothMask(m, W, H);
    for (let i = 0; i < W * H; i++) if (m[i]) { this.part[i] = name; this.col[i] = null; }
    this.parts[name] = { ramp, group: o.group || name, flat: o.flat };
  }
  set(x, y, c, name = "_") { if (x >= 0 && y >= 0 && x < W && y < H) { this.part[y * W + x] = name; this.col[y * W + x] = c; } }
  render() {
    const b = new P.Buf(W, H), at = (x, y) => (x < 0 || y < 0 || x >= W || y >= H ? null : this.part[y * W + x]);
    const grp = (n) => (n === null ? null : (this.parts[n] || { group: n }).group);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      const n = at(x, y); if (n === null) continue;
      if (this.col[y * W + x]) { b.pset(x, y, this.col[y * W + x]); continue; }
      const p = this.parts[n], r = p.ramp;
      let k = 1;  // płaskie pasma: cień u dołu i po bokach (2 px), blask u góry (2 px)
      if (!p.flat) {
        const out = (dx, dy) => at(x + dx, y + dy) !== n;
        if (out(0, 2) || out(0, 1) || out(-2, 0) || out(2, 0)) k = 0;
        else if ((out(0, -2) || out(0, -1)) && r.length > 2) k = 2;
      }
      b.pset(x, y, r[Math.min(k, r.length - 1)]);
    }
    // obrys: zewnętrzny 1 px (4-sąsiedztwo) + wewnętrzny między grupami (uszy/głowa/tułów)
    const ink = new Uint8Array(W * H);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      const n = at(x, y), g = grp(n);
      if (n === null) { if ([[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => at(x + dx, y + dy) !== null)) ink[y * W + x] = 1; continue; }
      if ((this.parts[n] || {}).line === false) continue;
      for (const [dx, dy] of [[0, 1], [1, 0], [-1, 0], [0, -1]]) {
        const m = at(x + dx, y + dy), gm = grp(m);
        if (m !== null && gm !== g && this.front(g, gm)) { ink[y * W + x] = 1; break; }
      }
    }
    for (let i = 0; i < W * H; i++) if (ink[i]) b.px[i] = P.col(INK);
    return b;
  }
}
// kolejność warstw grup: obrys wewnętrzny rysuje część z przodu
const ORDER = ["body", "ears", "head", "lop", "cap"];
Canvas.prototype.front = function (a, b) { return ORDER.indexOf(a) > ORDER.indexOf(b) && ORDER.indexOf(b) >= 0; };

const ell = (cx, cy, rx, ry) => (x, y) => ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1;
const sup = (cx, cy, rx, ry, e = 2.6) => (x, y) => Math.abs((x - cx) / rx) ** e + Math.abs((y - cy) / ry) ** e <= 1; // zaokrąglony prostokąt
const cap = (ax, ay, bx, by, r) => (x, y) => { const vx = bx - ax, vy = by - ay, t = Math.max(0, Math.min(1, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy))); return (x - ax - t * vx) ** 2 + (y - ay - t * vy) ** 2 <= r * r; };
const rell = (cx, cy, rx, ry, a) => (x, y) => { const c = Math.cos(a), s = Math.sin(a), u = (x - cx) * c + (y - cy) * s, v = -(x - cx) * s + (y - cy) * c; return (u / rx) ** 2 + (v / ry) ** 2 <= 1; };
const or = (...f) => (x, y) => f.some((g) => g(x, y));
const and = (...f) => (x, y) => f.every((g) => g(x, y));
const ramp = (n, o) => P.hueRamp(n, o);

// oko: ciemny owal z białym odblaskiem (lustrzane pary rysuje wywołujący)
function eye(c, ex, ey, w, h, dark, iris, closed = null) {
  if (closed) {  // mrugnięcie: powieka w kolorze sierści i kreska rzęs
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) c.set(ex + x, ey + y, closed);
    for (let x = 0; x < w; x++) c.set(ex + x, ey + h - 2, dark);
    return;
  }
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const corner = (x === 0 || x === w - 1) && (y === 0 || y === h - 1);
    if (!corner) c.set(ex + x, ey + y, iris && y > 0 && y < h - 1 && x > 0 && x < w - 1 && y >= h / 2 - 1 ? iris : dark);
  }
  c.set(ex + 1, ey + 1, [255, 252, 244]); c.set(ex + 1, ey + 2, [255, 252, 244]);
}
const mir = (x) => 2 * CX - 1 - x;
// płacz: łza spływa spod zewnętrznego kącika oka, smutne brwi (wewnętrzny koniec wyżej)
function tears(c, eyes, ey, h, len, brow) {
  const T = [[156, 210, 255], [96, 158, 236]];
  for (const [ex, w] of eyes) {
    const outer = ex < CX ? ex : ex + w - 1;
    for (let k = 0; k < len; k++) { c.set(outer, ey + h + k, T[k % 3 === 2 ? 1 : 0]); }
    c.set(outer, ey + h + len, T[1]); c.set(outer + (ex < CX ? -1 : 1), ey + h + len - 1, T[0]);   // kropla
    const inner = ex < CX ? ex + w - 1 : ex, dir = ex < CX ? -1 : 1;
    for (let k = 0; k < 4; k++) c.set(inner + dir * k, brow - 2 + Math.floor(k / 2), [40, 26, 30]);
  }
}
// okrąg 1 px (algorytm punktu środkowego): czysta obręcz bez podwójnych pikseli
function ring(c, cx, cy, r, col) {
  let x = r, y = 0, e = 1 - r;
  while (x >= y) {
    for (const [a, b] of [[x, y], [y, x], [-y, x], [-x, y], [-x, -y], [-y, -x], [y, -x], [x, -y]]) c.set(cx + a, cy + b, col);
    y++; if (e < 0) e += 2 * y + 1; else { x--; e += 2 * (y - x) + 1; }
  }
}

function maciej(blink = false, cry = false, old = false) {
  const c = new Canvas();
  // old: lata później (szpital) – siwe, prawie białe futro
  const fur = ramp(3, old ? { hue: 220, shift: 10, sat: 0.03, light: [0.58, 0.82] } : { hue: 224, shift: 22, sat: 0.1, light: [0.5, 0.78] });
  const furD = ramp(3, old ? { hue: 224, shift: 10, sat: 0.03, light: [0.48, 0.7] } : { hue: 228, shift: 20, sat: 0.1, light: [0.4, 0.64] });
  const light = ramp(2, { hue: 220, shift: 12, sat: 0.08, light: old ? [0.9, 0.97] : [0.8, 0.9] });
  const coat = ramp(3, old ? { hue: 204, shift: 14, sat: 0.32, light: [0.56, 0.76] } : { hue: 212, shift: 16, sat: 0.1, light: [0.74, 0.96] }); // old: koszula szpitalna
  const shirt = ramp(2, { hue: 210, shift: 10, sat: 0.4, light: [0.8, 0.88] });
  const pinkE = ramp(2, { hue: 352, shift: 10, sat: 0.22, light: [0.62, 0.74] });
  c.add("coat", sup(CX, 97, 38, 28, 2.2), coat, { group: "body" });
  c.add("collar", (x, y) => y > 67 && y < 76 && Math.abs(x - CX) < 21, coat, { group: "body", raw: true }); // ramiona tuż pod policzkami
  c.add("shirt", (x, y) => y > 70 && Math.abs(x - CX) < (y - 70) * 0.45 + 2.5, shirt, { group: "body", flat: true, raw: true });
  // krawat: wąski węzeł, klinga lekko się rozszerza, szpiczasty koniec
  const tw = (y) => (y < 74 ? 2 : y < 77 ? 1.5 : y < 84 ? 1.5 + (y - 77) * 0.32 : 3.7 - (y - 84) * 1.2);
  if (!old) c.add("tie", (x, y) => y > 70.5 && y < 87 && Math.abs(x - CX) < tw(y), ramp(2, { hue: 322, shift: 12, sat: 0.55, light: [0.3, 0.42] }), { group: "body", raw: true });
  if (!old) for (let x = 42; x < 46; x++) c.set(x, 73, [96, 28, 70]);                 // dół węzła
  c.add("earL", cap(35, 36, 31, 8, 5.5), fur, { group: "ears" });
  c.add("earLi", cap(34.6, 33, 31.6, 13, 2.4), pinkE, { group: "ears", flat: true });
  c.add("earR", cap(53, 36, 55.6, 21, 5.5), fur, { group: "ears" });      // drugie ucho: nasada lustrzana do lewego, za głową
  c.add("earRi", cap(53.4, 33, 55.4, 22, 2.4), pinkE, { group: "ears", flat: true });
  c.add("lop", or(cap(55.6, 20, 63, 23, 5), cap(63, 23, 66, 29.5, 4.6)), furD, { group: "ears" }); // zgina się wysoko, krótki płat opada
  c.add("head", or(sup(CX, 52, 23, 18, 2.4), ell(31, 62, 11, 9), ell(57, 62, 11, 9)), fur, { group: "head" });
  c.add("muzzle", or(ell(40, 63, 6.5, 5.2), ell(48, 63, 6.5, 5.2)), light, { group: "head", flat: true });
  // oczy (brązowe), okulary okrągłe, nos, pyszczek, wąsy
  for (const ex of [31, 53]) eye(c, ex, 48, 5, 6, [44, 24, 18], [124, 74, 40], blink ? fur[1] : null);  // środek oka = środek szkła
  for (const ocx of [33, 55]) ring(c, ocx, 51, 6, INK);                     // okrągłe okulary, obręcz 1 px
  for (let x = 41; x <= 46; x++) c.set(x, 50, INK);                          // mostek
  for (let x = 20; x < 26; x++) c.set(x, 49 - Math.floor((26 - x) / 3), INK); // zauszniki
  for (let x = 62; x < 68; x++) c.set(x, 49 - Math.floor((x - 62) / 3), INK);
  c.set(30, 46, [232, 240, 255]); c.set(52, 46, [232, 240, 255]);           // błysk na szkle
  for (const [x, y] of [[42, 58], [43, 58], [44, 58], [45, 58], [43, 59], [44, 59]]) c.set(x, y, [176, 118, 128]); // nos
  for (const [x, y] of [[43, 60], [44, 60], [43, 61], [44, 61], [42, 62], [41, 62], [45, 62], [46, 62]]) c.set(x, y, furD[0]); // pyszczek
  for (const s of [0, 1]) for (let k = 0; k < 9; k++) {                     // wąsy, lustrzanie
    const x = 34 - k, y1 = 61 - Math.floor(k / 4), y2 = 64 + Math.floor(k / 4);
    c.set(s ? mir(x) : x, y1, light[1]); c.set(s ? mir(x) : x, y2, light[1]);
  }
  for (let y = 71; y < 88; y++) { const d = Math.floor((y - 71) * 0.45) + 3; c.set(CX - 1 - d, y, coat[0]); c.set(CX + d, y, coat[0]); } // brzegi klap
  if (!old) for (let x = 58; x < 66; x++) c.set(x, 80, coat[0]);                      // kieszeń i długopisy
  if (!old) for (let y = 75; y < 80; y++) { c.set(60, y, [70, 110, 200]); c.set(62, y, [210, 70, 60]); }
  if (old) {
    const W = [104, 108, 122];                                                 // zmarszczki: krótkie łuki, lustrzanie
    const wr = [[39, 38], [40, 37], [41, 37], [42, 37], [43, 37],                                           // czoło
      [23, 52], [24, 53], [23, 55], [24, 55], [36, 66], [37, 67], [37, 68]];                                  // kurze łapki, bruzda przy pyszczku
    for (const [x, y] of wr) { c.set(x, y, W); c.set(mir(x), y, W); }
    // przy oczach: szkła mają środki 33 i 55, więc druga strona to przesunięcie o 22, nie lustro względem CX
    for (const [x, y] of [[29, 59], [30, 60], [31, 60], [32, 60], [33, 60], [34, 60], [35, 60], [36, 59]]) { c.set(x, y, W); c.set(x + 22, y, W); } // worki pod oczami
    for (const [x, y] of [[28, 43], [29, 42], [30, 42], [31, 41], [32, 41], [33, 41], [34, 41], [35, 41], [36, 42], [37, 42], [38, 43], [30, 43], [32, 42], [34, 42]]) { c.set(x, y, [246, 248, 252]); c.set(x + 22, y, [246, 248, 252]); } // krzaczaste białe brwi
  }
  if (cry) tears(c, [[31, 5], [53, 5]], 48, 6, 8, 43);
  return c.render();
}

function jania(blink = false, cry = false, adult = false) {
  const c = new Canvas();
  const fur = ramp(3, { hue: 24, shift: 26, sat: 0.72, light: [0.44, 0.66] });
  const cream = ramp(2, { hue: 34, shift: 14, sat: 0.5, light: [0.78, 0.9] });
  const denim = ramp(3, { hue: 214, shift: 22, sat: 0.48, light: [0.34, 0.58] });
  const pink = ramp(2, { hue: 352, shift: 10, sat: 0.6, light: [0.66, 0.8] });
  c.add("body", sup(CX, 100, 28, 26, 2.2), fur, { group: "body" });
  c.add("chest", ell(CX, 80, 9, 7), cream, { group: "body", flat: true });
  c.add("bib", (x, y) => y >= 79 && Math.abs(x - CX) <= 13, denim, { group: "body", raw: true });
  c.add("straps", (x, y) => y >= 72 && y < 80 && Math.abs(Math.abs(x - CX) - 12) <= 1, denim, { group: "body", flat: true, raw: true });
  const top = adult ? 9 : 18;  // dorosła: dłuższe uszy, smuklejsza głowa, mniejsze policzki
  c.add("ears", cap(37.5, 46, 34.5, top, 6), fur, { group: "ears", mirror: true });
  c.add("earsi", cap(37, 42, 34.8, top + 6, 2), pink, { group: "ears", flat: true, mirror: true });
  c.add("head", adult ? or(sup(CX, 59, 17, 16, 2.4), ell(34, 67, 7, 6), ell(54, 67, 7, 6)) : or(sup(CX, 59, 19, 15, 2.4), ell(33, 66, 9, 7), ell(55, 66, 9, 7)), fur, { group: "head" });
  c.add("muzzle", or(ell(40, 68, 5.5, 4.4)), cream, { group: "head", flat: true, mirror: true });
  const eh = adult ? 6 : 7;
  for (const ex of [33, 51]) eye(c, ex, 56, 5, eh, [34, 20, 18], null, blink ? fur[1] : null);
  if (adult && !blink) for (const [x, y] of [[32, 56], [31, 55]]) { c.set(x, y, [34, 20, 18]); c.set(mir(x), y, [34, 20, 18]); } // rzęsy
  if (cry) tears(c, [[33, 5], [51, 5]], 56, eh, 7, 53);
  for (const [x, y] of [[29, 64], [30, 64], [31, 64]]) { c.set(x, y, pink[0]); c.set(mir(x), y, pink[0]); } // rumieńce
  for (const [x, y] of [[42, 64], [43, 64], [42, 65], [43, 65]]) { c.set(x, y, pink[0]); c.set(mir(x), y, pink[0]); } // nosek
  for (const [x, y] of [[43, 66], [42, 67], [41, 67]]) { c.set(x, y, fur[0]); c.set(mir(x), y, fur[0]); } // pyszczek
  for (const x of [41, 42]) for (let y = 68; y < 71; y++) { c.set(x, y, y === 70 ? [222, 214, 202] : [252, 248, 240]); c.set(mir(x), y, y === 70 ? [222, 214, 202] : [252, 248, 240]); } // dwa siekacze
  for (let y = 68; y < 71; y++) { c.set(43, y, [196, 184, 172]); c.set(44, y, [196, 184, 172]); }
  for (const x of [31, 32, 55, 56]) c.set(x, 81, [255, 214, 92]);            // guziki
  return c.render();
}


// ---- psy z U-Howl (przeprowadzka): ogrodniczki i czapeczki firmy w kolorze pomarańczowym, kremowe „U” na czapce
const UH = ramp(3, { hue: 20, shift: 18, sat: 0.78, light: [0.42, 0.62] });      // pomarańcz U-Howl
const UHV = ramp(2, { hue: 16, shift: 12, sat: 0.7, light: [0.3, 0.4] });        // daszek
const CREAM = [250, 236, 206];
const tri = (ax, ay, bx, by, cx, cy) => (x, y) => { const s = (px, py, qx, qy, rx, ry) => (px - rx) * (qy - ry) - (qx - rx) * (py - ry); const d1 = s(x, y, ax, ay, bx, by), d2 = s(x, y, bx, by, cx, cy), d3 = s(x, y, cx, cy, ax, ay); return !((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0)); };
function overalls(c, top = 79) {
  c.add("bib", (x, y) => y >= top && Math.abs(x - CX) <= 13, UH, { group: "body", raw: true });
  c.add("straps", (x, y) => y >= top - 8 && y < top && Math.abs(Math.abs(x - CX) - 12) <= 1, UH, { group: "body", flat: true, raw: true });
  for (const x of [31, 32, 55, 56]) c.set(x, top + 2, CREAM);                  // guziki
  for (let x = 40; x < 48; x++) c.set(x, top + 5, UH[0]);                       // kieszonka
}
function hat(c, cy, rx) {  // czapeczka z daszkiem, przodem: kopuła i daszek, kremowe U na środku
  c.add("cap", and(sup(CX, cy, rx, 8, 2.2), (x, y) => y <= cy + 1), UH, { group: "cap" });
  c.add("visor", ell(CX, cy + 2, rx + 3, 2.6), UHV, { group: "cap", flat: true });
  for (const [x, y] of [[-2, -5], [-2, -4], [-2, -3], [-2, -2], [-1, -1], [0, -1], [1, -2], [1, -3], [1, -4], [1, -5]]) c.set(CX + x, cy + y, CREAM);
}
function lili(blink = false) {  // york: złota grzywka, wielkie sterczące uszy, czarne oczka, różowy język na środku
  const c = new Canvas();
  const gold = ramp(3, { hue: 34, shift: 20, sat: 0.48, light: [0.42, 0.64] });
  const goldL = ramp(2, { hue: 38, shift: 12, sat: 0.45, light: [0.7, 0.82] });
  const silver = ramp(3, { hue: 30, shift: 14, sat: 0.1, light: [0.48, 0.66] });
  const earIn = ramp(2, { hue: 18, shift: 10, sat: 0.4, light: [0.34, 0.44] });
  c.add("body", sup(CX, 101, 26, 25, 2.2), silver, { group: "body" });
  overalls(c, 80);
  c.add("ears", tri(32, 50, 22, 50, 15, 18), gold, { group: "ears", mirror: true });
  c.add("earsi", tri(29, 46, 23, 46, 19, 27), earIn, { group: "ears", flat: true, mirror: true });
  c.add("head", or(sup(CX, 58, 19, 16, 2.4), ell(31, 66, 9, 8), ell(57, 66, 9, 8), ell(25, 60, 3.5, 6), ell(63, 60, 3.5, 6)), gold, { group: "head" });
  c.add("muzzle", ell(CX, 67, 8.5, 6), goldL, { group: "head", flat: true });
  for (const ex of [33, 51]) eye(c, ex, 56, 4, 5, [28, 18, 16], null, blink ? gold[1] : null);
  for (let y = 61; y < 65; y++) for (let x = 41; x < 47; x++) if (!((x === 41 || x === 46) && (y === 61 || y === 64))) c.set(x, y, [26, 20, 22]); // czarny nos
  c.set(42, 62, [110, 100, 104]);
  for (const x of [40, 41, 46, 47]) c.set(x, 66, gold[0]);                       // pyszczek
  for (let y = 66; y < 73; y++) for (let x = 42; x < 46; x++) if (!(y === 72 && (x === 42 || x === 45))) c.set(x, y, y === 66 ? [196, 80, 96] : [236, 120, 140]); // język wypada na środku
  for (let y = 68; y < 72; y++) c.set(43, y, [214, 96, 116]);
  for (const [x, y] of [[26, 49], [27, 48], [61, 49], [60, 48], [37, 47], [50, 47]]) c.set(x, y, goldL[1]); // kosmyki
  hat(c, 41, 14);
  return c.render();
}
function myszka(blink = false) {  // czarna z podpalaniem: opadające czarne uszy, rude brwi, siwy pyszczek, biała pierś
  const c = new Canvas();
  const blk = ramp(3, { hue: 224, shift: 12, sat: 0.12, light: [0.12, 0.26] });
  const tan = ramp(2, { hue: 32, shift: 14, sat: 0.45, light: [0.62, 0.74] });
  const grey = ramp(2, { hue: 40, shift: 10, sat: 0.08, light: [0.74, 0.88] });
  c.add("body", sup(CX, 100, 30, 26, 2.2), blk, { group: "body" });
  c.add("chest", ell(CX, 79, 10, 7), grey, { group: "body", flat: true });
  overalls(c, 80);
  c.add("head", or(sup(CX, 56, 21, 18, 2.4), ell(31, 64, 10, 9), ell(57, 64, 10, 9)), blk, { group: "head" });
  c.add("lop", or(cap(28, 43, 23, 62, 5.2), cap(60, 43, 65, 62, 5.2)), blk, { group: "lop" }); // opadające uszy po bokach
  c.add("cheek", or(ell(33, 66, 4.5, 4), ell(55, 66, 4.5, 4)), tan, { group: "head", flat: true });
  c.add("muzzle", or(ell(41, 66, 5.5, 4.8), ell(47, 66, 5.5, 4.8)), grey, { group: "head", flat: true });
  c.add("brow", or(ell(33, 48, 3.5, 2.2), ell(55, 48, 3.5, 2.2)), tan, { group: "head", flat: true, raw: true });
  for (const ex of [31, 52]) eye(c, ex, 52, 5, 6, [34, 22, 18], [104, 66, 36], blink ? blk[1] : null);
  for (let y = 59; y < 64; y++) for (let x = 40; x < 48; x++) if (!((x === 40 || x === 47) && (y === 59 || y === 63))) c.set(x, y, [24, 22, 26]); // nos
  c.set(42, 60, [120, 120, 130]); c.set(43, 60, [120, 120, 130]);
  for (const [x, y] of [[43, 64], [44, 64], [43, 65], [44, 65], [42, 66], [41, 67], [45, 66], [46, 67]]) c.set(x, y, [70, 64, 66]); // pyszczek
  hat(c, 40, 15);
  return c.render();
}
// arkusz 2 klatek: otwarte oczy, mrugnięcie (oddech robi okienko dialogu przesunięciem o 1 px)
const M = maciej(), J = jania(), A = jania(false, false, true);
P.save(P.pack([J, jania(true)], { cols: 2, pad: 0 }), OUT + "/portrait_jania.png");
P.save(P.pack([M, maciej(true)], { cols: 2, pad: 0 }), OUT + "/portrait_maciej.png");
P.save(P.pack([maciej(false, true), maciej(true, true)], { cols: 2, pad: 0 }), OUT + "/portrait_maciej_cry.png");
P.save(P.pack([maciej(false, false, true), maciej(true, false, true)], { cols: 2, pad: 0 }), OUT + "/portrait_maciej_old.png");
P.save(P.pack([maciej(false, true, true), maciej(true, true, true)], { cols: 2, pad: 0 }), OUT + "/portrait_maciej_old_cry.png");
P.save(P.pack([A, jania(true, false, true)], { cols: 2, pad: 0 }), OUT + "/portrait_jania_adult.png");
P.save(P.pack([jania(false, true, true), jania(true, true, true)], { cols: 2, pad: 0 }), OUT + "/portrait_jania_adult_cry.png");
P.save(P.pack([lili(), lili(true)], { cols: 2, pad: 0 }), OUT + "/portrait_lili.png");
P.save(P.pack([myszka(), myszka(true)], { cols: 2, pad: 0 }), OUT + "/portrait_myszka.png");
P.save(P.sheet([{ buf: lili(), scale: 4, label: "LILI" }, { buf: myszka(), scale: 4, label: "MYSZKA" }, { buf: J, scale: 4, label: "JANIA" }]), __dirname + "/_dogs.png");
P.save(P.sheet([{ buf: J, scale: 4, label: "JANIA" }, { buf: M, scale: 4, label: "MACIEJ" }, { buf: J, scale: 1 }, { buf: M, scale: 1 }]), __dirname + "/_portraits.png");
console.log("edge J", JSON.stringify(P.edgeCheck(J)).slice(0, 120), "M", JSON.stringify(P.edgeCheck(M)).slice(0, 120));
