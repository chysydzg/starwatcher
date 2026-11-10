// Etap 2: pokoik Jani w obserwatorium (GDD 13: łóżko z kołdrą w gwiazdy, szafka, miejsce na kosmetyki).
// Osobny ekran 640x360, ta sama perspektywa i bryła co pokój z Etapu 1 (okno w 152, drzwi w 520 – do laboratorium),
// świeżo pomalowany na jasno; meble przyjechały z mieszkania: pokoik_layout.json bierze je z room_layout.json.
const fs = require("fs");
const { P, R, slab, obj, shadow, light } = require("./kit.js");
const W = 640, H = 360, WALL = 112;
const out = process.argv[2];
const b = new P.Buf(W, H);
const paint = P.hueRamp(3, { hue: 250, shift: 18, sat: 0.18, light: [0.7, 0.86] });   // jasny lawendowy tynk

for (let y = WALL; y < 348; y++) {  // podłoga: deski jak w starym pokoju
  const row = Math.floor((y - WALL) / 9), ry = (y - WALL) % 9;
  for (let x = 0; x < W; x++) {
    const seg = Math.floor((x + row * 41) / 104), seam = (x + row * 41) % 104 === 0;
    let c = R.floor[P.hash(row, seg, 3) > 0.7 ? 1 : 2];
    if (ry === 0) c = R.floor[3];
    if (ry === 8 || seam) c = R.floor[0];
    b.pset(x, y, c);
  }
}
slab(b, 0, 0, W, 82, paint, 0.75, 0.6, { grain: 0 });
for (let y = 18; y < 78; y += 14) for (let x = ((y / 14) % 2) * 11; x < W; x += 22) {  // gwiazdki z szablonu
  b.pset(x, y, R.gold[2]); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) b.pset(x + dx, y + dy, paint[0]);
}
b.rect(0, 82, W, 108, R.cream[1]);
for (let x = 0; x < W; x += 32) { b.rect(x + 4, 87, x + 28, 88, R.cream[0]); b.rect(x + 4, 88, x + 5, 104, R.cream[0]); b.rect(x + 5, 103, x + 28, 104, R.cream[2]); b.rect(x + 27, 88, x + 28, 103, R.cream[2]); }
b.rect(0, 82, W, 84, R.cream[2]);
slab(b, 0, 106, W, WALL, R.wood, 0.35, 0.2, { grain: 0.05 });
slab(b, 0, WALL, W, WALL + 4, R.wood, 0.12, 0.3, { grain: 0 });
const cap = (x0, y0, x1, y1) => b.rect(x0, y0, x1, y1, [58, 36, 58]);
cap(0, 0, W, 10); b.rect(0, 10, W, 11, [86, 58, 82]);
cap(0, 0, 12, H); cap(628, 0, W, H); cap(0, 348, W, H); b.rect(12, 348, 628, 349, [86, 58, 82]);
for (let y = 186; y < 290; y++) for (let x = 196; x < 410; x++) {  // dywan w gwiazdy
  const d = ((x - 303) / 86) ** 2 + ((y - 238) / 42) ** 2;
  if (d > 1) continue;
  let c = R.navy[P.band(0.55 - d * 0.25 + (P.fbm(x * 0.2, y * 0.2, 2, 9) - 0.5) * 0.2, 5, x, y)];
  if (d > 0.82) c = R.red[P.band(0.6 - (d - 0.82) * 2, 5, x, y)]; else if (d > 0.76) c = R.gold[1];
  b.pset(x, y, c);
}
for (const [sx, sy] of [[250, 220], [300, 210], [352, 228], [280, 252], [330, 258], [305, 236]]) { b.pset(sx, sy, R.gold[3]); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) b.pset(sx + dx, sy + dy, R.gold[1]); }
obj(b, 152, 22, 78, 60, (s) => {  // okno z zasłonami (geometria jak w pokoju)
  slab(s, 0, 0, 78, 3, R.wood, 0.3, 0.3, { grain: 0 });
  slab(s, 8, 4, 70, 54, R.woodL, 0.7, 0.55, { grain: 0.1 });
  slab(s, 11, 7, 67, 51, R.navy, 0.75, 0.35, { grain: 0.04 });
  s.rect(38, 7, 40, 51, R.woodL[3]); s.rect(11, 28, 67, 30, R.woodL[3]);
  slab(s, 0, 3, 10, 58, R.red, 0.65, 0.35, { tex: 1, grain: 0.4, sx: 0.9, sy: 0.05 });
  slab(s, 68, 3, 78, 58, R.red, 0.6, 0.3, { tex: 1, grain: 0.4, sx: 0.9, sy: 0.05 });
  slab(s, 6, 52, 72, 57, R.cream, 0.7, 0.3, { grain: 0 });
});
obj(b, 520, 26, 42, 88, (s) => {  // drzwi do laboratorium (szyby jak drzwi balkonowe)
  slab(s, 0, 0, 42, 88, R.woodL, 0.67, 0.67);
  for (const [x0, y0] of [[5, 5], [22, 5], [5, 28], [22, 28]]) { slab(s, x0, y0, x0 + 15, y0 + 20, R.navy, 0.8, 0.5); for (let i = 0; i < 6; i++) s.pset(x0 + 3 + i, y0 + 10 - i, R.navy[3]); }
  slab(s, 5, 54, 37, 82, R.woodL, 0.33, 0.33); s.rect(5, 54, 37, 55, R.woodL[3]);
  s.rect(34, 46, 38, 48, R.gold[2]); s.rect(36, 48, 38, 52, R.gold[1]);
});
obj(b, 300, 30, 30, 38, (s) => {  // zdjęcie: Jania z tatą na balkonie
  slab(s, 0, 0, 30, 38, R.gold, 0.7, 0.5, { grain: 0 }); slab(s, 2, 2, 28, 36, R.navy, 0.6, 0.3, { grain: 0 });
  s.rect(7, 18, 11, 34, [224, 120, 60]); s.rect(8, 14, 9, 18, [224, 120, 60]); s.rect(10, 14, 11, 18, [224, 120, 60]);
  s.rect(15, 16, 21, 34, [130, 110, 100]); s.pset(23, 7, R.gold[3]); s.pset(6, 9, R.gold[3]);
}, { lit: R.gold[1] });
for (const [x, y, rx, ry] of [[56, 190, 44, 6], [113, 128, 15, 4], [236, 128, 9, 3], [598, 124, 28, 4], [458, 124, 12, 4], [38, 268, 22, 5], [46, 330, 16, 4]]) shadow(b, x, y, rx, ry);
light(b, (x, y) => (y > WALL + 2 && y < 250 && x > 174 + (y - WALL) * 0.55 && x < 236 + (y - WALL) * 0.55 ? Math.min(1, (250 - y) / 40) : 0), [255, 236, 190], 0.22);
light(b, (x, y) => { const d = Math.hypot((x - 114) / 46, (y - 112) / 30); return d < 1 ? (1 - d) * 1.6 : 0; }, [255, 200, 120], 0.2);
P.save(b, out + "/pokoik.png");
const room = JSON.parse(fs.readFileSync(out + "/room_layout.json"));
const keep = ["room_bed", "room_nightstand", "room_lamp", "room_wardrobe", "room_plant", "room_pufa", "room_basket"];
fs.writeFileSync(out + "/pokoik_layout.json", JSON.stringify(room.filter((p) => keep.includes(p.name)), null, 1));
console.log("pokoik.png");
