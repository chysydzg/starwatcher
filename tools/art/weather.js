// Ikony prognozy pogody do podsumowania dnia (24x20, w grze x2): pogodnie (Słońce jak na ekranie zmierzchu:
// tarcza z odblaskiem i poświatą), deszcz (chmura z kroplami), burza (ciemna chmura, krople i piorun).
const { P, INK } = require("./kit.js");
const out = process.argv[2];
const W = 24, H = 20;
const disc = (b, cx, cy, r, col) => { for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r) b.pset(x, y, col); };
function sun() {
  const b = new P.Buf(W, H);
  disc(b, 12, 10, 9, [255, 196, 120]);              // poświata (jak pierścienie przy Słońcu w grze)
  disc(b, 12, 10, 7, [255, 224, 138]);              // tarcza ffe08a
  disc(b, 10, 8, 3, [255, 250, 220]);               // odblask
  return P.outline(b, INK);
}
function cloud(dark) {
  const b = new P.Buf(W, H), g = dark ? P.hueRamp(4, { hue: 230, shift: 14, sat: 0.12, light: [0.3, 0.62] }) : P.hueRamp(4, { hue: 214, shift: 16, sat: 0.1, light: [0.62, 0.95] });
  P.solid(b, [P.ell(8, 9, 5, 4), P.ell(14, 7, 6, 5), P.ell(18, 10, 4, 3), P.cap(5, 11, 20, 11, 2, 2)], g, { light: [-0.4, -0.8, 0.5] });
  return b;
}
function rain(storm) {
  const c = cloud(storm), b = new P.Buf(W, H);
  for (const [x, y] of [[6, 14], [11, 15], [16, 14], [20, 15]]) { b.pset(x, y, [120, 180, 255]); b.pset(x - 1, y + 1, [120, 180, 255]); b.pset(x - 2, y + 2, [90, 150, 230]); }  // krople ukośnie
  if (storm) for (const [x, y] of [[14, 12], [13, 13], [12, 14], [13, 14], [14, 14], [15, 14], [14, 15], [13, 16], [12, 17], [11, 18]]) b.pset(x, y, [255, 214, 74]);  // piorun
  const o = P.outline(c, INK), r = new P.Buf(W + 2, H + 2);
  r.sprite(o, 0, 0);
  r.sprite(b, 1, 1);
  return r;
}
P.save(sun(), out + "/weather_sun.png");
P.save(rain(false), out + "/weather_rain.png");
P.save(rain(true), out + "/weather_storm.png");
P.save(P.sheet([sun(), rain(false), rain(true)].map((buf) => ({ buf, scale: 8 }))), __dirname + "/_weather.png");
console.log("weather_*");
