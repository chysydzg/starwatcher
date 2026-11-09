// Teleskop Newtona na balkon: tuba z celownicą i wyciągiem z referencji autora (codixel: kwantyzacja w pełnym
// rozmiarze, resize mode, logo zamalowane), montaż paralaktyczny i statyw dorysowane kodem.
// Eksport: buf (bez nocnego przyciemnienia – robi to balcony.js przez savePieces).
const P = require(process.env.CODIXEL || "./pixel.js");
const { ink } = require("./kit.js");
function newton() {
  const ref = P.resize(P.load(__dirname + "/out/newton_ref.png"), 500, 500);
  const q = P.quantize(P.trim(P.removeBg(ref, { tol: 10, erode: 1 })), 12).buf;
  const tube = P.smoothEdge(P.cleanup(P.resize(q, 64, null, { mode: true }), { tol: 20 }));
  for (let y = 0; y < tube.h; y++) for (let x = 0; x < tube.w; x++) if (y > 0.5 * x + 22.5) tube.px[y * tube.w + x] = 0; // tylko tuba
  const s = new P.Buf(70, 92);
  const blk = [[22, 22, 28], [44, 44, 52], [70, 70, 80]], sil = P.hueRamp(3, { hue: 220, shift: 10, sat: 0.06, light: [0.45, 0.85] });
  // statyw: trzy srebrne nogi do podłogi (tylna ciemniejsza)
  s.line(38, 64, 37, 90, sil[0], 2);
  s.line(34, 63, 18, 90, sil[2], 2); s.line(35, 63, 19, 90, sil[1], 1);
  s.line(42, 63, 58, 90, sil[2], 2); s.line(43, 63, 59, 90, sil[1], 1);
  s.line(24, 80, 52, 80, sil[0], 1); // półka na akcesoria
  slab0(s, 32, 58, 46, 64, blk); // głowica statywu
  // montaż: oś deklinacji, pręt i przeciwwaga
  slab0(s, 34, 44, 44, 58, blk); s.rect(35, 45, 37, 57, blk[2]);
  s.line(36, 54, 24, 70, sil[2], 1);
  slab0(s, 19, 68, 28, 75, blk); s.rect(20, 69, 27, 70, blk[2]);
  s.sprite(tube, 3, 0);
  return P.trim(ink(s));
}
function slab0(s, x0, y0, x1, y1, r) { s.rect(x0, y0, x1, y1, r[1]); s.rect(x0, y0, x1, y0 + 1, r[2]); s.rect(x0, y1 - 1, x1, y1, r[0]); }
module.exports = { newton };
if (require.main === module) P.save(P.sheet([{ buf: newton(), scale: 5 }]), process.argv[2]);
