// Etap 2: pokoik Jani w obserwatorium (GDD 13: łóżko z kołdrą w gwiazdy, szafka, miejsce na kosmetyki).
// Osobny ekran 640x360, ta sama perspektywa i bryła co pokój z Etapu 1 (okno w 152, drzwi w 520 – do laboratorium),
// świeżo pomalowany na jasno; meble przyjechały z mieszkania: pokoik_layout.json bierze je z room_layout.json.
const fs = require("fs");
const { P, R, slab, obj, light, piece, savePieces, saturn } = require("./kit.js");
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
piece("dywan_duzy", 0, [196, 186, 410, 290], (T) => {  // duży dywan w gwiazdy: osobny element, da się go przesunąć w trybie edycji
  for (let y = 186; y < 290; y++) for (let x = 196; x < 410; x++) {
    const d = ((x - 303) / 86) ** 2 + ((y - 238) / 42) ** 2;
    if (d > 1) continue;
    let c = R.navy[P.band(0.55 - d * 0.25 + (P.fbm(x * 0.2, y * 0.2, 2, 9) - 0.5) * 0.2, 5, x, y)];
    if (d > 0.82) c = R.red[P.band(0.6 - (d - 0.82) * 2, 5, x, y)]; else if (d > 0.76) c = R.gold[1];
    T.pset(x, y, c);
  }
  for (const [sx, sy] of [[250, 220], [300, 210], [352, 228], [280, 252], [330, 258], [305, 236]]) { T.pset(sx, sy, R.gold[3]); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) T.pset(sx + dx, sy + dy, R.gold[1]); }
});
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
// meble da się przestawiać (tryb edycji): bez cieni wpieczonych w podłogę i bez plamy światła lampki
light(b, (x, y) => (y > WALL + 2 && y < 250 && x > 174 + (y - WALL) * 0.55 && x < 236 + (y - WALL) * 0.55 ? Math.min(1, (250 - y) / 40) : 0), [255, 236, 190], 0.22);
P.save(b, out + "/pokoik.png");

// ---- ozdoby ze sklepu (kategoria Pokój): pokazują się po otwarciu paczki, potem do przestawienia w trybie edycji
piece("polka", 124, [380, 112, 420, 124], (T) => obj(T, 380, 72, 40, 52, (s) => {  // półka z atlasami nieba
  slab(s, 0, 0, 40, 52, R.woodL, 0.7, 0.5); slab(s, 3, 3, 37, 49, R.wood, 0.4, 0.3);
  for (const y of [3, 19, 35]) {
    s.rect(3, y + 13, 37, y + 15, R.woodL[2]);
    let x = 5;
    for (let k = 0; x < 34; k++) { const w = 3 + (k * 7 % 3), h = 9 + (k * 5 % 4); s.rect(x, y + 13 - h, x + w, y + 13, [R.red[2], R.navy[3], R.gold[2], [80, 140, 90]][k % 4]); x += w + 1; }
  }
}));
piece("dywan", 0, [400, 240, 480, 272], (T) => {  // okrągły dywanik w gwiazdki (leży pod wszystkim)
  for (let y = 236; y < 276; y++) for (let x = 396; x < 484; x++) {
    const d = ((x - 440) / 42) ** 2 + ((y - 256) / 18) ** 2;
    if (d > 1) continue;
    T.pset(x, y, d > 0.8 ? [196, 120, 160] : d > 0.7 ? [236, 200, 220] : [150, 90, 140]);
  }
  for (const [x, y] of [[424, 252], [452, 258], [440, 248], [432, 262], [458, 250]]) { T.pset(x, y, R.gold[3]); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) T.pset(x + dx, y + dy, R.gold[1]); }
});
piece("girlanda", 0, [16, 12, 110, 32], (T) => {  // girlanda gwiazdek nad łóżkiem (wisi na ścianie)
  for (let x = 16; x < 110; x++) T.pset(x, Math.round(16 + 7 * Math.sin((x - 16) / 94 * Math.PI)), [60, 50, 60]);
  for (let x = 22; x < 108; x += 12) { const y = Math.round(18 + 7 * Math.sin((x - 16) / 94 * Math.PI)); for (const [dx, dy] of [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) T.pset(x + dx, y + dy + 1, (x / 12) % 2 < 1 ? [255, 230, 140] : [255, 190, 210]); }
});
piece("plakat_saturn", 0, [246, 28, 278, 70], (T) => obj(T, 246, 28, 32, 42, (s) => {  // plakat z Saturnem
  slab(s, 0, 0, 32, 42, [[20, 22, 50], [30, 34, 70], [40, 46, 90]], 0.6, 0.4, { grain: 0 });
  saturn(s, 16, 18, 7, 13, 3.5, [240, 214, 150], [214, 180, 120], [250, 236, 190]);
  s.rect(6, 33, 26, 35, [250, 236, 190]); for (const [x, y] of [[4, 4], [27, 8], [6, 26], [25, 28]]) s.pset(x, y, [255, 255, 255]);
}, { lit: R.gold[2] }));
piece("rakieta", 236, [466, 224, 494, 236], (T) => obj(T, 466, 176, 28, 60, (s) => {  // model rakiety na podstawce
  slab(s, 4, 52, 24, 60, R.wood, 0.6, 0.4);
  P.solid(s, [P.cap(14, 10, 14, 42, 2.5, 5)], P.hueRamp(4, { hue: 214, shift: 20, sat: 0.08, light: [0.55, 0.95] }), { light: [-0.5, -0.7, 0.5] });
  s.rect(12, 0, 16, 8, R.red[2]); s.rect(13, 0, 15, 2, R.red[3]); s.rect(6, 36, 9, 48, R.red[2]); s.rect(19, 36, 22, 48, R.red[2]);
  s.rect(12, 18, 16, 22, [120, 190, 240]); s.rect(11, 48, 17, 52, R.gray[1]);
  for (let y = 12; y < 52; y++) { s.pset(23, y, R.gray[1]); s.pset(27, y, R.gray[1]); if (y % 6 === 0) s.rect(23, y, 28, y + 1, R.gray[2]); }  // wieża startowa z prawej (widać obrót Q/E)
  s.rect(17, 24, 23, 25, R.gray[2]);
}));
piece("pluszak", 216, [118, 206, 136, 216], (T) => obj(T, 118, 196, 18, 20, (s) => {  // pluszowy kotek (szarobury, różowy nosek)
  const fur = [[96, 84, 76], [130, 116, 104], [160, 146, 132]];
  slab(s, 2, 6, 16, 20, fur, 0.7, 0.5, { grain: 0 }); s.rect(2, 2, 5, 6, fur[1]); s.rect(13, 2, 16, 6, fur[1]);
  s.rect(6, 12, 12, 20, [236, 232, 220]); s.pset(6, 9, [100, 170, 60]); s.pset(11, 9, [100, 170, 60]); s.pset(9, 11, [236, 140, 160]);
}));
savePieces(out, "pokoik");
const room = JSON.parse(fs.readFileSync(out + "/room_layout.json"));
const keep = ["room_bed", "room_nightstand", "room_lamp", "room_wardrobe", "room_plant", "room_pufa", "room_basket"];
const lay = room.filter((p) => keep.includes(p.name)).map((p) => ({ ...p, kind: "floor" }));
const KIND = { dywan: "rug", dywan_duzy: "rug", girlanda: "wall", plakat_saturn: "wall" };
for (const p of JSON.parse(fs.readFileSync(out + "/pokoik_layout.json"))) {
  const k = p.name.replace("pokoik_", "");
  lay.push({ ...p, opt: k === "dywan_duzy" ? "" : k, kind: KIND[k] || "floor", nocol: !!KIND[k] });  // duży dywan jest od początku
}
fs.writeFileSync(out + "/pokoik_layout.json", JSON.stringify(lay, null, 1));
console.log("pokoik.png");
