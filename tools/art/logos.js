// Logo obserwatorium (GDD: Sklep kosmetyczny, „Logo firmy kosmicznej”): pięć uroczych, pixel-artowych znaków 48x48,
// symetrycznych tam, gdzie motyw na to pozwala. Gracz wybiera jedno raz, po przeprowadzce (logo.gd).
const { P, R, ink } = require("./kit.js");
const out = process.argv[2];
const S = 46;
const L = { light: [-0.5, -0.7, 0.5] };
const orange = P.hueRamp(4, { hue: 24, shift: 24, sat: 0.85, light: [0.36, 0.66] });
const leaf = P.hueRamp(4, { hue: 112, shift: 30, sat: 0.55, light: [0.26, 0.56] });
const flame = [[255, 236, 150], [255, 180, 70], [230, 96, 40]];
const sky = P.hueRamp(4, { hue: 200, shift: 20, sat: 0.6, light: [0.48, 0.82] });
const fur = P.hueRamp(4, { hue: 30, shift: 20, sat: 0.4, light: [0.42, 0.78] });
const brass = P.hueRamp(4, { hue: 42, shift: 22, sat: 0.6, light: [0.32, 0.72] });
const moon = P.hueRamp(3, { hue: 210, shift: 16, sat: 0.12, light: [0.7, 0.94] });
const pink = P.hueRamp(4, { hue: 340, shift: 20, sat: 0.45, light: [0.5, 0.8] });
const disk = P.hueRamp(4, { hue: 30, shift: 30, sat: 0.9, light: [0.4, 0.78] });
const mirror = (s) => { for (let y = 0; y < S; y++) for (let x = 0; x < S / 2; x++) s.px[y * S + S - 1 - x] = s.px[y * S + x]; };  // lewa połowa → prawa

function carrot() {  // marchewka-rakieta: czubek w górę, liście jak stateczniki, płomień na dole
  const s = new P.Buf(S, S);
  for (const sx of [-1, 1]) P.solid(s, [P.cap(23 + sx * 6, 28, 23 + sx * 12, 36, 2.6, 1.6)], leaf, L);  // stateczniki-liście
  P.solid(s, [P.cap(22.5, 6, 22.5, 30, 2.0, 8.5)], orange, L);
  for (const y of [13, 19, 25]) for (let x = 18; x < 23; x++) s.pset(x, y, orange[1]);                  // bruzdy marchewki
  for (let y = 36; y < 45; y++) for (let x = 16; x < 30; x++) {                                          // płomień: trzy pasma od środka
    const d = Math.abs(x - 22.5) / (7 - (y - 36) * 0.75);
    if (d < 1) s.pset(x, y, flame[d < 0.35 ? 0 : d < 0.7 ? 1 : 2]);
  }
  mirror(s);
  s.pset(20, 9, [255, 236, 200]); s.pset(20, 10, [255, 236, 200]);                                         // blik (celowo tylko z lewej)
  return ink(s);
}
function rabbit() {  // głowa królika wpisana w jasnoniebieski pierścień orbity, mała planeta na pierścieniu
  const s = new P.Buf(S, S);
  for (let a = 0; a < 6.283; a += 0.01) for (const r of [19, 20, 21]) s.pset(Math.round(22.5 + Math.cos(a) * r), Math.round(22.5 + Math.sin(a) * r), sky[r === 20 ? 2 : 1]);
  P.solid(s, [P.ell(22.5, 26, 9, 8), P.cap(18, 19, 16, 6, 2.6, 2.4)], fur, L);
  for (let y = 9; y < 18; y++) s.pset(17, y, pink[2]);                                                    // wnętrze ucha
  mirror(s);
  for (const x of [18, 27]) { s.pset(x, 25, R.navy[0]); s.pset(x, 24, R.navy[0]); }                       // oczy
  s.pset(22, 28, pink[1]); s.pset(23, 28, pink[1]);
  P.solid(s, [P.ell(39, 9, 3.2, 3.2)], P.hueRamp(3, { hue: 18, shift: 16, sat: 0.6, light: [0.45, 0.7] }), L);  // planeta na orbicie
  return ink(s);
}
function paw() {  // łapka z czteroramienną błyszczącą gwiazdą w poduszce
  const s = new P.Buf(S, S);
  P.solid(s, [P.ell(22.5, 30, 12, 10)], pink, L);
  for (const [x, y] of [[10, 17], [17, 9]]) P.solid(s, [P.ell(x, y, 4.6, 5.4)], pink, L);
  mirror(s);
  for (let i = -7; i <= 7; i++) {                                                                          // gwiazda: ramiona zwężają się ku końcom
    const w = Math.max(0, 2 - Math.floor(Math.abs(i) / 3));
    for (let k = -w; k <= w; k++) { s.pset(22 + i, 30 + k, [255, 244, 190]); s.pset(23 + i, 30 + k, [255, 244, 190]); s.pset(22 + k, 30 + i, [255, 244, 190]); s.pset(23 + k, 30 + i, [255, 244, 190]); }
  }
  for (const [x, y] of [[22, 30], [23, 30], [22, 29], [23, 29]]) s.pset(x, y, [255, 255, 255]);
  return ink(s);
}
function crest() {  // mosiężna tarcza z sierpem księżyca i kropkowaną trajektorią satelity
  const s = new P.Buf(S, S);
  for (let y = 2; y < 44; y++) {
    const half = y < 30 ? 19 : 19 * Math.sqrt(Math.max(0, 1 - ((y - 30) / 14) ** 2));
    for (let x = Math.round(22.5 - half); x <= Math.round(22.5 + half) - 1; x++) s.pset(x, y, brass[y < 4 || Math.abs(x - 22.5) > half - 2 ? 1 : 2]);
  }
  mirror(s);
  const c = new P.Buf(S, S);
  P.solid(c, [P.ell(20, 22, 9, 9)], moon, L);
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) if (c.get(x, y) >>> 24 && Math.hypot(x - 24.5, y - 19.5) > 8) s.pset(x, y, P.unpack(c.get(x, y)));  // sierp
  for (let a = 3.6; a < 6.0; a += 0.22) s.pset(Math.round(22.5 + Math.cos(a) * 15), Math.round(30 + Math.sin(a) * 8), brass[3]);
  s.rect(33, 21, 37, 24, [220, 230, 240]); s.rect(31, 22, 33, 23, sky[1]); s.rect(37, 22, 39, 23, sky[1]);  // satelita z panelami
  return ink(s);
}
function voidHole() {  // czarna dziura: płaski dysk akrecyjny za nią, zakrzywiony pierścień światła, pas dysku przed nią
  const s = new P.Buf(S, S);
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
    const d = Math.hypot((x - 22.5) / 21, (y - 22.5) / 5);
    if (d < 1) s.pset(x, y, disk[Math.min(3, Math.floor((1 - d) * 5))]);                                 // dysk (tył)
    const r = Math.hypot(x - 22.5, y - 22.5);
    if (r < 12.5 && r >= 10.5) s.pset(x, y, disk[r < 11.5 ? 3 : 2]);                                      // światło zakrzywione wokół
    if (r < 10.5) s.pset(x, y, [10, 8, 16]);                                                              // horyzont zdarzeń
  }
  for (let y = 21; y < 25; y++) for (let x = 0; x < S; x++) {                                              // pas dysku przed dziurą
    const d = Math.abs(x - 22.5) / 21;
    if (d < 1) s.pset(x, y, disk[y === 21 ? 3 : Math.min(3, Math.floor((1 - d) * 4))]);
  }
  mirror(s);
  return ink(s);
}
const all = { carrot: carrot(), rabbit: rabbit(), paws: paw(), crest: crest(), void: voidHole() };
for (const [k, b] of Object.entries(all)) P.save(b, `${out}/logo_${k}.png`);
P.save(P.sheet(Object.entries(all).map(([k, b]) => ({ buf: b, scale: 5, label: k.toUpperCase() })), { cols: 5 }), __dirname + "/_logos.png");
console.log("logo_*.png");
