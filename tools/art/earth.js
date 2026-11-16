// Ziemia do zakładki Orbita w AstroOS (Etap 2): kula 96x96 z kontynentami z szumu, czapami lodu, chmurami,
// światłem z lewej góry i niebieską poświatą atmosfery; mały satelita (panele i korpus) do rysowania na orbitach.
const P = require(process.env.CODIXEL);
const out = process.argv[2];
const S = 100, C = 49.5, RAD = 44;
const b = new P.Buf(S, S);
const ocean = P.hueRamp(5, { hue: 214, shift: 24, sat: 0.7, light: [0.18, 0.62] });
const land = P.hueRamp(5, { hue: 100, shift: 40, sat: 0.5, light: [0.16, 0.56] });
const desert = P.hueRamp(5, { hue: 38, shift: 20, sat: 0.45, light: [0.28, 0.7] });
const L = [-0.55, -0.45, 0.7];
for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
  const dx = (x - C) / RAD, dy = (y - C) / RAD, r2 = dx * dx + dy * dy;
  if (r2 > 1) { const r = Math.sqrt(r2); if (r < 1.06) b.pset(x, y, [130, 190, 255]); continue; }  // atmosfera
  const dz = Math.sqrt(1 - r2);
  const lit = Math.max(0, dx * L[0] + dy * L[1] + dz * L[2]);
  const lon = Math.atan2(dx, dz) + 0.6, lat = Math.asin(dy);
  const n = P.fbm(lon * 1.6 + 10, lat * 2.2 + 4, 4, 7);
  const v = 0.12 + lit * 0.88;
  let ramp = ocean;
  if (n > 0.58) ramp = Math.abs(lat) < 0.45 && n > 0.68 ? desert : land;
  let c = ramp[P.band(v, ramp.length, x, y)];
  if (Math.abs(lat) > 1.15) c = [Math.round(200 * v + 50), Math.round(210 * v + 45), Math.round(230 * v + 25)];  // lód
  const cl = P.fbm(lon * 3 + 50, lat * 5, 3, 3);
  if (cl > 0.62) c = P.mix(Array.isArray(c) ? c : P.unpack(c).slice(0, 3), [250, 252, 255], Math.min(1, (cl - 0.62) * 6) * (0.4 + 0.6 * v));
  b.pset(x, y, c);
}
P.save(P.outline(b, [10, 12, 30]), out + "/earth.png");
const s = new P.Buf(11, 7);  // satelita: korpus i dwa panele
s.rect(4, 2, 7, 5, [230, 232, 240]); s.rect(5, 0, 6, 2, [180, 184, 196]);
for (const x0 of [0, 7]) s.rect(x0, 2, x0 + 4, 5, [60, 100, 200]);
s.rect(0, 3, 11, 4, [40, 70, 160]); s.rect(4, 2, 7, 5, [230, 232, 240]);
P.save(s, out + "/sat.png");
P.save(P.sheet([{ buf: b, scale: 3 }, { buf: s, scale: 8 }]), __dirname + "/_earth.png");
console.log("earth.png sat.png");
