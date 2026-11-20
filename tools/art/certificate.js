// Certyfikat Terenu (koniec Etapu 1): pergamin z podwójną złotą ramką, narożnikami w gwiazdki i złotym Saturnem
// (ten sam co na plakacie w pokoiku) zamiast pieczęci.
// Tekst dopisuje gra (czytelna czcionka), tu tylko papier i ozdoby. node certificate.js <out>
const { P, INK, saturn } = require("./kit.js");
const W = 380, H = 250, b = new P.Buf(W, H);
const paper = P.hueRamp(4, { hue: 40, shift: 12, sat: 0.4, light: [0.7, 0.93] });
const gold = P.hueRamp(4, { hue: 42, shift: 20, sat: 0.7, light: [0.34, 0.78] });
const wax = P.hueRamp(4, { hue: 356, shift: 16, sat: 0.62, light: [0.26, 0.6] });
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {           // papier: jaśniejszy środek, ciemniejsze brzegi (płaskie pasy)
  const e = Math.min(x, y, W - 1 - x, H - 1 - y), n = P.noise(x * 0.3, y * 0.9);
  b.pset(x, y, paper[e < 2 ? 0 : e < 6 ? 1 : e < 9 || n > 0.82 ? 2 : 3]);   // włókna papieru: rzadkie, poziome drobinki
}
const frame = (m, c) => { for (let x = m; x < W - m; x++) { b.pset(x, m, c); b.pset(x, H - 1 - m, c); } for (let y = m; y < H - m; y++) { b.pset(m, y, c); b.pset(W - 1 - m, y, c); } };
frame(10, gold[0]); frame(11, gold[2]); frame(12, gold[3]); frame(13, gold[1]); frame(16, gold[1]);           // podwójna ramka ze złotym połyskiem
for (const [cx, cy] of [[12, 12], [W - 13, 12], [12, H - 13], [W - 13, H - 13]]) {   // narożniki: gwiazdki
  for (let y = -5; y <= 5; y++) for (let x = -5; x <= 5; x++) if (x * x + y * y <= 26) b.pset(cx + x, cy + y, paper[3]);   // tarcza pod gwiazdką
  for (let k = -6; k <= 6; k++) { b.pset(cx + k, cy, gold[Math.abs(k) < 3 ? 3 : 1]); b.pset(cx, cy + k, gold[Math.abs(k) < 3 ? 3 : 1]); }
  for (let k = -3; k <= 3; k++) { b.pset(cx + k, cy + k, gold[2]); b.pset(cx + k, cy - k, gold[2]); }
  b.pset(cx, cy, [255, 250, 220]);
}
for (let x = 100; x < 280; x++) if (x % 4 !== 1) b.pset(x, 56, gold[1]);  // linia pod tytułem
for (let x = 46; x < 170; x++) b.pset(x, 214, paper[0]);                // linia podpisu
// pieczęć: złoty Saturn w ciemnej obwódce, wokół drobne gwiazdki
for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) saturn(b, 312 + dx, 196 + dy, 15, 30, 8, gold[0], gold[0], gold[0]);
saturn(b, 312, 196, 15, 30, 8, gold[2], gold[1], gold[3]);
for (let a = 0; a < 6.28; a += 0.02) { const x = Math.round(312 + Math.cos(a) * 30), y = Math.round(196 + Math.sin(a) * 8); if (Math.sin(a) > 0) b.pset(x, y + 1, gold[1]); }  // cień pod przednim pierścieniem
for (const [x, y] of [[276, 176], [348, 180], [284, 216], [342, 218], [312, 172]]) { b.pset(x, y, gold[2]); b.pset(x - 1, y, gold[1]); b.pset(x + 1, y, gold[1]); b.pset(x, y - 1, gold[1]); b.pset(x, y + 1, gold[1]); }
P.save(b, process.argv[2] + "/certificate.png");
// ikona na pulpit (32x24): mini pergamin z pieczęcią
const ic = new P.Buf(32, 24);
for (let y = 0; y < 22; y++) for (let x = 0; x < 30; x++) ic.pset(x, y, paper[Math.min(x, y, 29 - x, 21 - y) < 2 ? 1 : 3]);
for (let x = 3; x < 27; x++) { ic.pset(x, 2, gold[2]); ic.pset(x, 19, gold[2]); }
for (let y = 2; y < 20; y++) { ic.pset(3, y, gold[2]); ic.pset(26, y, gold[2]); }
for (let x = 8; x < 22; x += 1) if (x % 3) ic.pset(x, 7, paper[0]);
for (let x = 8; x < 18; x += 1) if (x % 3) ic.pset(x, 11, paper[0]);
saturn(ic, 22, 16, 4, 7, 2, gold[2], gold[1], gold[0]);  // mini Saturn jak na certyfikacie
P.save(P.outline(ic, INK), process.argv[2] + "/certificate_icon.png");
