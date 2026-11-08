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
const ORDER = ["body", "ears", "head", "lop"];
Canvas.prototype.front = function (a, b) { return ORDER.indexOf(a) > ORDER.indexOf(b) && ORDER.indexOf(b) >= 0; };

const ell = (cx, cy, rx, ry) => (x, y) => ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1;
const sup = (cx, cy, rx, ry, e = 2.6) => (x, y) => Math.abs((x - cx) / rx) ** e + Math.abs((y - cy) / ry) ** e <= 1; // zaokrąglony prostokąt
const cap = (ax, ay, bx, by, r) => (x, y) => { const vx = bx - ax, vy = by - ay, t = Math.max(0, Math.min(1, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy))); return (x - ax - t * vx) ** 2 + (y - ay - t * vy) ** 2 <= r * r; };
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
// okrąg 1 px (algorytm punktu środkowego): czysta obręcz bez podwójnych pikseli
function ring(c, cx, cy, r, col) {
  let x = r, y = 0, e = 1 - r;
  while (x >= y) {
    for (const [a, b] of [[x, y], [y, x], [-y, x], [-x, y], [-x, -y], [-y, -x], [y, -x], [x, -y]]) c.set(cx + a, cy + b, col);
    y++; if (e < 0) e += 2 * y + 1; else { x--; e += 2 * (y - x) + 1; }
  }
}

function maciej(blink = false) {
  const c = new Canvas();
  const fur = ramp(3, { hue: 224, shift: 22, sat: 0.1, light: [0.5, 0.78] });
  const furD = ramp(3, { hue: 228, shift: 20, sat: 0.1, light: [0.4, 0.64] });
  const light = ramp(2, { hue: 220, shift: 12, sat: 0.08, light: [0.8, 0.9] });
  const coat = ramp(3, { hue: 212, shift: 16, sat: 0.1, light: [0.74, 0.96] });
  const shirt = ramp(2, { hue: 208, shift: 14, sat: 0.42, light: [0.46, 0.62] });
  const pinkE = ramp(2, { hue: 352, shift: 10, sat: 0.22, light: [0.62, 0.74] });
  c.add("coat", sup(CX, 97, 38, 28, 2.2), coat, { group: "body" });
  c.add("collar", (x, y) => y > 67 && y < 76 && Math.abs(x - CX) < 21, coat, { group: "body", raw: true }); // ramiona tuż pod policzkami
  c.add("shirt", (x, y) => y > 70 && Math.abs(x - CX) < (y - 70) * 0.45 + 2.5, shirt, { group: "body", flat: true, raw: true });
  c.add("earL", cap(35, 36, 31, 8, 5.5), fur, { group: "ears" });
  c.add("earLi", cap(34.6, 33, 31.6, 13, 2.4), pinkE, { group: "ears", flat: true });
  c.add("head", or(sup(CX, 52, 23, 18, 2.4), ell(31, 62, 11, 9), ell(57, 62, 11, 9)), fur, { group: "head" });
  c.add("muzzle", or(ell(40, 63, 6.5, 5.2), ell(48, 63, 6.5, 5.2)), light, { group: "head", flat: true });
  c.add("lop", or(cap(52, 37, 56, 23, 5), cap(56, 23, 66, 27, 5), cap(66, 27, 69, 41, 4.6)), furD, { group: "lop" }); // drugie ucho złamane: wstaje i opada na bok
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
  for (let x = 58; x < 66; x++) c.set(x, 80, coat[0]);                      // kieszeń i długopisy
  for (let y = 75; y < 80; y++) { c.set(60, y, [70, 110, 200]); c.set(62, y, [210, 70, 60]); }
  return c.render();
}

function jania(blink = false) {
  const c = new Canvas();
  const fur = ramp(3, { hue: 24, shift: 26, sat: 0.72, light: [0.44, 0.66] });
  const cream = ramp(2, { hue: 34, shift: 14, sat: 0.5, light: [0.78, 0.9] });
  const denim = ramp(3, { hue: 214, shift: 22, sat: 0.48, light: [0.34, 0.58] });
  const pink = ramp(2, { hue: 352, shift: 10, sat: 0.6, light: [0.66, 0.8] });
  c.add("body", sup(CX, 100, 28, 26, 2.2), fur, { group: "body" });
  c.add("chest", ell(CX, 80, 9, 7), cream, { group: "body", flat: true });
  c.add("bib", (x, y) => y >= 79 && Math.abs(x - CX) <= 13, denim, { group: "body", raw: true });
  c.add("straps", (x, y) => y >= 72 && y < 80 && Math.abs(Math.abs(x - CX) - 12) <= 1, denim, { group: "body", flat: true, raw: true });
  c.add("ears", cap(37.5, 46, 34.5, 18, 6), fur, { group: "ears", mirror: true });
  c.add("earsi", cap(37, 42, 34.8, 24, 2), pink, { group: "ears", flat: true, mirror: true });
  c.add("head", or(sup(CX, 59, 19, 15, 2.4), ell(33, 66, 9, 7), ell(55, 66, 9, 7)), fur, { group: "head" });
  c.add("muzzle", or(ell(40, 68, 5.5, 4.4)), cream, { group: "head", flat: true, mirror: true });
  for (const ex of [33, 51]) eye(c, ex, 56, 5, 7, [34, 20, 18], null, blink ? fur[1] : null);
  for (const [x, y] of [[29, 64], [30, 64], [31, 64]]) { c.set(x, y, pink[0]); c.set(mir(x), y, pink[0]); } // rumieńce
  for (const [x, y] of [[42, 64], [43, 64], [42, 65], [43, 65]]) { c.set(x, y, pink[0]); c.set(mir(x), y, pink[0]); } // nosek
  for (const [x, y] of [[43, 66], [42, 67], [41, 67]]) { c.set(x, y, fur[0]); c.set(mir(x), y, fur[0]); } // pyszczek
  for (const x of [41, 42]) for (let y = 68; y < 71; y++) { c.set(x, y, y === 70 ? [222, 214, 202] : [252, 248, 240]); c.set(mir(x), y, y === 70 ? [222, 214, 202] : [252, 248, 240]); } // dwa siekacze
  for (let y = 68; y < 71; y++) { c.set(43, y, [196, 184, 172]); c.set(44, y, [196, 184, 172]); }
  for (const x of [31, 32, 55, 56]) c.set(x, 81, [255, 214, 92]);            // guziki
  return c.render();
}

// arkusz 2 klatek: otwarte oczy, mrugnięcie (oddech robi okienko dialogu przesunięciem o 1 px)
const M = maciej(), J = jania();
P.save(P.pack([J, jania(true)], { cols: 2, pad: 0 }), OUT + "/portrait_jania.png");
P.save(P.pack([M, maciej(true)], { cols: 2, pad: 0 }), OUT + "/portrait_maciej.png");
P.save(P.sheet([{ buf: J, scale: 4, label: "JANIA" }, { buf: M, scale: 4, label: "MACIEJ" }, { buf: J, scale: 1 }, { buf: M, scale: 1 }]), __dirname + "/_portraits.png");
console.log("edge J", JSON.stringify(P.edgeCheck(J)).slice(0, 120), "M", JSON.stringify(P.edgeCheck(M)).slice(0, 120));
