// Wspólne narzędzia scen: krótkie rampy (hue-shift), płaskie bryły z jednym światłem, czarny obrys.
const P = require(process.env.CODIXEL);

// rampa, której za duże indeksy biorą ostatni kolor (krótsze rampy bez przepisywania rysunków)
const ramp = (n, o) => new Proxy(P.hueRamp(n, o), { get: (a, k) => (typeof k === "string" && /^\d+$/.test(k) ? a[Math.min(+k, a.length - 1)] : a[k]) });
const R = {
  floor: ramp(4, { hue: 26, shift: 16, sat: 0.42, light: [0.28, 0.56] }),
  wood: ramp(4, { hue: 24, shift: 36, sat: 0.5, light: [0.24, 0.56] }),
  woodL: ramp(4, { hue: 30, shift: 34, sat: 0.46, light: [0.36, 0.7] }),
  teal: ramp(3, { hue: 188, shift: 26, sat: 0.3, light: [0.38, 0.58] }),
  navy: ramp(4, { hue: 228, shift: 30, sat: 0.45, light: [0.12, 0.36] }),
  gold: ramp(3, { hue: 46, shift: 18, sat: 0.8, light: [0.5, 0.78] }),
  red: ramp(4, { hue: 4, shift: 26, sat: 0.55, light: [0.3, 0.6] }),
  cream: ramp(3, { hue: 40, shift: 18, sat: 0.35, light: [0.66, 0.9] }),
  beige: ramp(4, { hue: 46, shift: 20, sat: 0.3, light: [0.48, 0.82] }),
  gray: ramp(4, { hue: 230, shift: 18, sat: 0.1, light: [0.32, 0.74] }),
  green: ramp(4, { hue: 118, shift: 36, sat: 0.45, light: [0.22, 0.55] }),
  purple: ramp(4, { hue: 268, shift: 28, sat: 0.35, light: [0.2, 0.46] }),
  screen: ramp(3, { hue: 150, shift: 18, sat: 0.55, light: [0.14, 0.55] }),
};
const INK = [18, 12, 22];
const BAND = 0.18; // wąski pas ditheru tylko na granicy dwóch tonów

// prostokąt cieniowany pionowo od vTop do vBot; grain > 0 tylko tam, gdzie faktura ma sens
function slab(b, x0, y0, x1, y1, ramp, vTop, vBot, o = {}) {
  const g = o.tex ? o.grain ?? 0 : 0, sx = o.sx ?? 0.08, sy = o.sy ?? 0.5, seed = o.seed ?? 1;
  for (let y = y0; y < y1; y++)
    for (let x = x0; x < x1; x++) {
      const u = y1 - y0 > 1 ? (y - y0) / (y1 - y0 - 1) : 0;
      const v = P.lerp(vTop, vBot, u) + (g ? 0.4 * (P.fbm(x * sx, y * sy, 2, seed) - 0.5) * g * 2 : 0);
      b.pset(x, y, ramp[P.band(v, ramp.length, x, y, BAND)]);
    }
}

// czarny obrys: 1px z narożnikami + dodatkowy piksel u dołu (ciężar, „osadzenie” na podłodze)
function ink(s) {
  const o = P.outline(s, INK, { corners: true }), out = new P.Buf(o.w, o.h + 1);
  out.sprite(o, 0, 0);
  const ic = P.col(INK);
  for (let x = 0; x < o.w; x++)
    for (let y = o.h - 1; y >= 0; y--)
      if (o.px[y * o.w + x] === ic) { if (y >= o.h - 3) out.px[(y + 1) * o.w + x] ||= ic; break; } // tylko pod spodem obiektu
  return out;
}

function obj(dst, x, y, w, h, draw, o = {}) {
  const s = new P.Buf(w, h);
  draw(s);
  dst.sprite(o.outline === false ? s : ink(s), x - 1, y - 1);
}

// cień rzucony na podłogę: jeden płaski, ciemniejszy ton (bez szumu)
function shadow(b, cx, cy, rx, ry, k = 0.35) {
  for (let y = Math.floor(cy - ry); y <= cy + ry; y++)
    for (let x = Math.floor(cx - rx); x <= cx + rx; x++)
      if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1) {
        const c = b.get(x, y);
        if (c) b.pset(x, y, P.mix(P.unpack(c), [34, 18, 44], k));
      }
}

// plama światła (okno, lampa): rozjaśnia i ociepla, z ostrą krawędzią jak w grach pixel-art
function light(b, inside, col = [255, 230, 170], k = 0.28) {
  for (let y = 0; y < b.h; y++)
    for (let x = 0; x < b.w; x++) {
      const a = inside(x, y);
      const m = a > 0.6 ? k : a > 0.25 ? k * 0.5 : 0; // dwa ostre stopnie zamiast szumu
      if (m) { const c = b.get(x, y); if (c) b.pset(x, y, P.mix(P.unpack(c), col, m)); }
    }
}

// osobne obiekty sceny (sortowanie głębi w Godot): rysowane na pełnym płótnie, zapisywane przycięte + layout.json
const pieces = [];
function piece(name, base, foot, draw) {
  const T = new P.Buf(640, 360);
  draw(T);
  pieces.push({ name, base, foot, buf: T });
}
function savePieces(dir, prefix, post) {
  const layout = [];
  for (const p of pieces) {
    if (post) post(p.buf);
    const bd = P.bounds(p.buf);
    P.save(P.crop(p.buf, bd.x, bd.y, bd.w, bd.h), `${dir}/${prefix}_${p.name}.png`);
    layout.push({ name: `${prefix}_${p.name}`, x: bd.x, y: bd.y, base: p.base, foot: p.foot });
  }
  require("fs").writeFileSync(`${dir}/${prefix}_layout.json`, JSON.stringify(layout, null, 1));
  pieces.length = 0;
}

module.exports = { P, R, INK, slab, obj, ink, shadow, light, ramp, BAND, piece, savePieces };
