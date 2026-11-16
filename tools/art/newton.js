// Teleskop Newtona na balkon: tuba z celownicą i wyciągiem z referencji autora (codixel: kwantyzacja w pełnym
// rozmiarze, resize mode, logo zamalowane), montaż paralaktyczny i statyw dorysowane kodem.
// Eksport: buf (bez nocnego przyciemnienia – robi to balcony.js przez savePieces).
const P = require(process.env.CODIXEL || "./pixel.js");
const { ink } = require("./kit.js");
function newton() {
  const { tube45 } = require("./kit.js");
  const s = new P.Buf(72, 96);
  const blk = [[22, 22, 28], [44, 44, 52], [70, 70, 80]], sil = P.hueRamp(3, { hue: 220, shift: 10, sat: 0.06, light: [0.45, 0.85] });
  const tubeR = P.hueRamp(4, { hue: 232, shift: 22, sat: 0.34, light: [0.44, 0.9] }), blk4 = [blk[0], blk[1], blk[1], blk[2]];
  // statyw: nogi o równych schodkach 1:2 (tylna ciemniejsza), półka na akcesoria
  s.rect(35, 64, 37, 94, sil[0]);
  s.line(33, 64, 20, 90, sil[2], 2); s.line(38, 64, 51, 90, sil[2], 2);
  s.rect(26, 80, 46, 81, sil[0]);
  s.rect(18, 90, 23, 93, blk[1]); s.rect(50, 90, 55, 93, blk[1]);
  slab0(s, 30, 58, 42, 64, blk);
  // montaż paralaktyczny: oś, pręt pod 45° i przeciwwaga
  slab0(s, 31, 44, 41, 58, blk); s.rect(32, 45, 34, 57, blk[2]);
  tube45(s, 31, 52, -11, 0, 1, sil); tube45(s, 31, 52, -14, -10, 4, blk4);
  // tuba pod 45°: dno, obejmy, szukacz i wyciąg na górnej stronie, ciemny wlot
  tube45(s, 36, 28, 1, 11, 3, blk4); tube45(s, 46, 22, 0, 2, 4, sil);
  tube45(s, 28, 52, -8, -6, 10, blk4); tube45(s, 28, 52, -6, 30, 11, tubeR);
  for (const st of [4, 18]) tube45(s, 28, 52, st, st + 1, 12, blk4);
  tube45(s, 28, 52, 28, 30, 12, blk4); tube45(s, 28, 52, 30, 30, 9, [blk[0], blk[0], blk[0], blk[0]]);
  return P.trim(ink(s));
}
function slab0(s, x0, y0, x1, y1, r) { s.rect(x0, y0, x1, y1, r[1]); s.rect(x0, y0, x1, y0 + 1, r[2]); s.rect(x0, y1 - 1, x1, y1, r[0]); }
module.exports = { newton };
if (require.main === module) P.save(P.sheet([{ buf: newton(), scale: 5 }]), process.argv[2]);
