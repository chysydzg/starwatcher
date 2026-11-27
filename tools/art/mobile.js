// Model układu słonecznego z podstawówki (składany z tatą): obręcz na nitce, Słońce w środku, 5 planet na nitkach
// krąży wokół. 24 klatki obrotu w poziomym pasku. Duży (intro: tata wiesza model) i mały (wisi w pokoju i w pokoiku).
const { P, R, INK } = require("./kit.js");
const out = process.argv[2];
const N = 24;
const PL = [[[200, 160, 112], 0.6], [[106, 154, 224], 0.8], [[208, 106, 74], 0.6], [[224, 192, 112], 1], [[138, 192, 216], 0.8]];
const STRING = [216, 208, 192], RING = [176, 168, 144];
function frame(f, s) {  // s: promień obręczy X; reszta w proporcji
  const rx = s, ry = Math.max(3, Math.round(s * 0.24)), drop = Math.round(s * 0.38), pr = Math.max(1.6, s * 0.17);
  const W = 2 * rx + 2 * Math.ceil(pr) + 6, H = drop + 2 * ry + Math.ceil(pr) * 2 + 8, cx = Math.floor(W / 2), cy = ry + 2;
  const pts = PL.map(([col, k], i) => {
    const a = f / N * Math.PI * 2 + i * Math.PI * 2 / PL.length;
    return { x: Math.round(cx + Math.cos(a) * rx), y: Math.round(cy + Math.sin(a) * ry), z: Math.sin(a), col, r: pr * k };
  });
  const shade = (c) => [c.map((v) => Math.round(v * 0.55)), c.map((v) => Math.round(v * 0.8)), c, c.map((v) => Math.round(v + (255 - v) * 0.45))];
  const sy = cy + Math.round(drop * 0.6) + Math.round(pr * 1.4);
  const bodies = (list, sun) => {  // kule z obrysem (osobna warstwa, żeby obrys nie pogrubiał nitek i obręczy)
    const L = new P.Buf(W, H);
    for (const p of list) P.solid(L, [P.ell(p.x, p.y + drop, p.r, p.r)], shade(p.col), { light: [-0.5, -0.6, 0.6] });
    if (sun) P.solid(L, [P.ell(cx, sy, pr * 1.4, pr * 1.4)], R.gold, { light: [-0.5, -0.6, 0.6] });
    return P.outline(L, INK);
  };
  const b = new P.Buf(W + 2, H + 2);
  const line = (x, y0, y1) => { for (let y = y0; y < y1; y++) b.pset(x + 1, y + 1, STRING); };
  const back = pts.filter((p) => p.z < 0), front = pts.filter((p) => p.z >= 0);
  back.forEach((p) => line(p.x, p.y, p.y + drop));
  b.sprite(bodies(back, false), 0, 0);                           // planety za obręczą
  for (let a = 0; a < Math.PI * 2; a += 0.01) b.pset(Math.round(cx + Math.cos(a) * rx) + 1, Math.round(cy + Math.sin(a) * ry) + 1, RING);
  line(cx, 0, sy);                                               // nitka przez środek do Słońca
  front.forEach((p) => line(p.x, p.y, p.y + drop));
  b.sprite(bodies(front, true), 0, 0);                           // Słońce i planety przed obręczą
  return b;
}
for (const [name, s] of [["solar_mobile", 26], ["solar_mobile_small", 15]]) {
  const fr = Array.from({ length: N }, (_, f) => frame(f, s));
  P.save(P.pack(fr, { cols: N, pad: 0 }), `${out}/${name}.png`);
  if (name === "solar_mobile") P.save(P.sheet(fr.slice(0, 6).map((buf) => ({ buf, scale: 6 })), { cols: 6 }), __dirname + "/_mobile.png");
  console.log(name, fr[0].w, fr[0].h);
}
