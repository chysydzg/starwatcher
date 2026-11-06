// Rekwizyty pojawiające się po zakupach / zdarzeniach (osobne PNG, nakładane w Godot).
const { P, R, slab, obj, ink } = require("./kit.js");
const out = process.argv[2] + "/";
const night = (buf) => { // balkon jest nocny: to samo przyciemnienie co w balcony.js
  for (let i = 0; i < buf.px.length; i++) if (buf.px[i] >>> 24) { const c = P.unpack(buf.px[i]); buf.px[i] = P.col([c[0] * 0.42 + 6, c[1] * 0.46 + 8, c[2] * 0.7 + 22]); }
  return buf;
};
const one = (w, h, draw, name, o = {}) => { const b = new P.Buf(w + 2, h + 3); obj(b, 1, 1, w, h, draw, o); P.save(o.night ? night(b) : b, out + name + ".png"); };

one(22, 16, (s) => { // paczka kurierska
  slab(s, 0, 0, 22, 6, R.beige, 1, 1); slab(s, 0, 6, 22, 16, R.beige, 0.67, 0.67);
  s.rect(9, 0, 13, 16, R.gold[1]); s.rect(0, 6, 22, 7, R.beige[1]); s.rect(3, 9, 8, 12, [240, 240, 240]); s.rect(4, 10, 7, 11, R.red[1]);
}, "parcel", { lit: R.beige[2] });
one(7, 7, (s) => { slab(s, 0, 0, 7, 7, R.gold, 1, 1); s.rect(1, 2, 6, 3, R.red[2]); s.pset(3, 4, R.navy[2]); s.rect(1, 5, 5, 6, R.red[2]); }, "sticky_note", { lit: R.gold[2] });
one(26, 34, (s) => { // plakat „I Want to Believe”
  slab(s, 0, 0, 26, 34, R.navy, 0.4, 0.15); s.rect(0, 26, 26, 34, [30, 50, 36]);
  P.solid(s, [P.ell(13, 12, 8, 2.6)], R.gray); P.solid(s, [P.ell(13, 10, 4, 2)], R.green);
  for (let y = 15; y < 26; y++) { const w = (y - 14) * 0.6; s.rect(13 - w, y, 13 + w + 1, y + 1, P.mix([220, 240, 160], [30, 50, 36], (y - 15) / 14)); }
  for (const x of [4, 8, 12, 16, 20]) s.rect(x, 29, x + 3, 30, [230, 230, 220]);
}, "poster_iwtb", { lit: R.gray[2] });
one(16, 12, (s) => { // radio lampowe
  slab(s, 0, 0, 16, 12, R.wood, 0.67, 0.67); s.rect(1, 0, 15, 1, R.wood[3]);
  slab(s, 2, 2, 9, 10, R.beige, 0.67, 0.67); for (let y = 3; y < 10; y += 2) s.rect(2, y, 9, y + 1, R.beige[1]);
  s.rect(11, 3, 14, 6, R.gold[1]); s.rect(11, 8, 14, 10, R.gold[0]);
}, "radio");
one(28, 30, (s) => { // monitor LCD 19" (zastępuje CRT)
  slab(s, 0, 0, 28, 20, R.gray, 0.33, 0.33); slab(s, 2, 2, 26, 18, R.navy, 0.67, 0.4); s.rect(3, 3, 9, 4, [150, 190, 255]);
  s.rect(12, 20, 16, 26, R.gray[1]); s.rect(7, 26, 21, 29, R.gray[1]); s.pset(24, 18, [120, 230, 120]);
}, "lcd");
one(22, 8, (s) => { slab(s, 0, 0, 22, 8, R.teal, 1, 0.33); s.rect(2, 2, 20, 3, R.cream[2]); }, "pillow", { night: true, lit: R.teal[2] });
one(6, 14, (s) => { slab(s, 0, 2, 6, 14, R.red, 0.67, 0.67); s.rect(1, 0, 5, 2, R.gray[2]); s.rect(0, 6, 6, 7, R.cream[2]); }, "thermos", { night: true, lit: R.red[2] });
console.log("props ok");
