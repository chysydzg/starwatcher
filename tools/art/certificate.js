// Certyfikat Terenu (koniec Etapu 1): pergamin z podwójną złotą ramką, narożnikami w gwiazdki, wstęgą i lakową pieczęcią.
// Tekst dopisuje gra (czytelna czcionka), tu tylko papier i ozdoby. node certificate.js <out>
const { P, INK } = require("./kit.js");
const W = 300, H = 200, b = new P.Buf(W, H);
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
for (let x = 70; x < 230; x++) if (x % 4 !== 1) b.pset(x, 48, gold[1]);  // linia pod tytułem
for (let x = 40; x < 140; x++) b.pset(x, 170, paper[0]);                // linia podpisu
// wstęga za pieczęcią
for (let k = 0; k < 22; k++) for (let w = -3; w <= 3; w++) { b.pset(232 - Math.round(k * 0.4) + w, 160 + k, wax[w < -1 ? 1 : 2]); b.pset(248 + Math.round(k * 0.4) + w, 160 + k, wax[w < -1 ? 1 : 2]); }
for (let w = -3; w <= 3; w++) { b.pset(223 + w + 3, 181 - Math.abs(w), paper[3]); b.pset(257 + w - 3, 181 - Math.abs(w), paper[3]); }   // wcięcia końców wstęgi
// pieczęć: falisty brzeg, wypukła tarcza, gwiazda w środku
for (let y = -18; y <= 18; y++) for (let x = -18; x <= 18; x++) {
  const a = Math.atan2(y, x), r = Math.hypot(x, y), edge = 15 + 1.6 * Math.sin(a * 12);
  if (r > edge) continue;
  b.pset(240 + x, 158 + y, wax[r > edge - 1.2 ? 0 : r > 10.5 && r < 11.6 ? 1 : (x < -2 && y < -2 && r < 10) ? 3 : 2]);  // brzeg, rant, odblask z lewej u góry
}
for (let i = 0; i < 5; i++) {                                           // gwiazda pięcioramienna w laku
  const a0 = -Math.PI / 2 + i * 2 * Math.PI / 5;
  for (let r = 0; r <= 7; r++) { b.pset(Math.round(240 + Math.cos(a0) * r), Math.round(158 + Math.sin(a0) * r), wax[0]); }
}
P.save(b, process.argv[2] + "/certificate.png");
// ikona na pulpit (32x24): mini pergamin z pieczęcią
const ic = new P.Buf(32, 24);
for (let y = 0; y < 22; y++) for (let x = 0; x < 30; x++) ic.pset(x, y, paper[Math.min(x, y, 29 - x, 21 - y) < 2 ? 1 : 3]);
for (let x = 3; x < 27; x++) { ic.pset(x, 2, gold[2]); ic.pset(x, 19, gold[2]); }
for (let y = 2; y < 20; y++) { ic.pset(3, y, gold[2]); ic.pset(26, y, gold[2]); }
for (let x = 8; x < 22; x += 1) if (x % 3) ic.pset(x, 7, paper[0]);
for (let x = 8; x < 18; x += 1) if (x % 3) ic.pset(x, 11, paper[0]);
for (let y = -4; y <= 4; y++) for (let x = -4; x <= 4; x++) if (x * x + y * y <= 17) ic.pset(22 + x, 17 + y, wax[x + y < -2 ? 3 : 2]);
P.save(P.outline(ic, INK), process.argv[2] + "/certificate_icon.png");
