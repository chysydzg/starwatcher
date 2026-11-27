// Ziemia do zakładki Orbita w AstroOS (Etap 2): kula 96x96 z kontynentami z szumu, czapami lodu, chmurami,
// światłem z lewej góry i niebieską poświatą atmosfery; mały satelita (panele i korpus) do rysowania na orbitach.
// Ziemia się kręci: F klatek obrotu w poziomym pasku, oś nachylona o 23,4° (jak prawdziwa), światło stoi w miejscu.
const P = require(process.env.CODIXEL);
const out = process.argv[2];
const S = 100, C = 49.5, RAD = 44;
const ocean = P.hueRamp(5, { hue: 214, shift: 24, sat: 0.7, light: [0.18, 0.62] });
const land = P.hueRamp(5, { hue: 100, shift: 40, sat: 0.5, light: [0.16, 0.56] });
const desert = P.hueRamp(5, { hue: 38, shift: 20, sat: 0.45, light: [0.28, 0.7] });
const L = [-0.55, -0.45, 0.7], F = 32, TILT = 23.4 * Math.PI / 180, TAU = Math.PI * 2;
const LANDN = P.tile((x, y) => P.fbm(x + 10, y, 4, 7), TAU * 1.6), CLOUDN = P.tile((x, y) => P.fbm(x + 50, y, 3, 3), TAU * 3);
function frame(f) {
  const b = new P.Buf(S, S);
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
    const dx = (x - C) / RAD, dy = (y - C) / RAD, r2 = dx * dx + dy * dy;
    if (r2 > 1) { const r = Math.sqrt(r2); if (r < 1.06) b.pset(x, y, [130, 190, 255]); continue; }  // atmosfera
    const dz = Math.sqrt(1 - r2);
    const lit = Math.max(0, dx * L[0] + dy * L[1] + dz * L[2]);
    const tx = dx * Math.cos(TILT) + dy * Math.sin(TILT), ty = -dx * Math.sin(TILT) + dy * Math.cos(TILT);  // układ osi Ziemi
    const lon = Math.atan2(tx, dz) + 0.6 + f / F * Math.PI * 2, lat = Math.asin(Math.max(-1, Math.min(1, ty)));
    const u = ((lon % TAU) + TAU) % TAU;
    const n = LANDN(u * 1.6, lat * 2.2 + 4);  // mapa kontynentów zawija się dookoła (bez szwu)
    const v = 0.12 + lit * 0.88;
    let ramp = ocean;
    if (n > 0.58) ramp = Math.abs(lat) < 0.45 && n > 0.68 ? desert : land;
    let c = ramp[P.band(v, ramp.length, x, y)];
    if (Math.abs(lat) > 1.15) c = [Math.round(200 * v + 50), Math.round(210 * v + 45), Math.round(230 * v + 25)];  // lód
    const cl = CLOUDN(((u + 0.4) % TAU) * 3, lat * 5);
    if (cl > 0.62) c = P.mix(Array.isArray(c) ? c : P.unpack(c).slice(0, 3), [250, 252, 255], Math.min(1, (cl - 0.62) * 6) * (0.4 + 0.6 * v));
    b.pset(x, y, c);
  }
  return P.outline(b, [10, 12, 30]);
}
const frames = Array.from({ length: F }, (_, f) => frame(f));
const b = frames[0];
P.save(P.pack(frames, { cols: F, pad: 0 }), out + "/earth.png");  // pasek F klatek obrotu
const s = new P.Buf(11, 7);  // satelita: korpus i dwa panele
s.rect(4, 2, 7, 5, [230, 232, 240]); s.rect(5, 0, 6, 2, [180, 184, 196]);
for (const x0 of [0, 7]) s.rect(x0, 2, x0 + 4, 5, [60, 100, 200]);
s.rect(0, 3, 11, 4, [40, 70, 160]); s.rect(4, 2, 7, 5, [230, 232, 240]);
P.save(s, out + "/sat.png");
P.save(P.sheet([...frames.filter((_, i) => i % 8 === 0).map((buf) => ({ buf, scale: 3 })), { buf: s, scale: 8 }]), __dirname + "/_earth.png");
console.log("earth.png sat.png");
