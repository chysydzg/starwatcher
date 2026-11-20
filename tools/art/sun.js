// Słońce do scenek (pikselowe jak księżyc z balcony.js): płaska tarcza z ciemniejszym rantem, jasny środek i korona
// z krótkich promieni. Poświatę (przezroczystą) dorysowuje gra. sun.png (zachód) i sun_noon.png (południe), 48x48. node sun.js <out>
const { P } = require("./kit.js");
for (const [name, cols] of [["sun", [[240, 120, 70], [255, 170, 90], [255, 214, 140], [255, 240, 200]]],
                            ["sun_noon", [[240, 190, 80], [255, 220, 120], [255, 240, 170], [255, 252, 225]]]]) {
  const b = new P.Buf(48, 48), C = 23.5;
  for (let i = 0; i < 8; i++) {                                      // promienie co 45° (czyste linie): długie w pionie i poziomie, krótsze po skosie
    const a = i * Math.PI / 4, len = i % 2 ? 20 : 22;
    for (let r = 15; r < len; r++) b.pset(Math.round(C + Math.cos(a) * r), Math.round(C + Math.sin(a) * r), cols[r < 18 ? 1 : 0]);
  }
  for (let y = 0; y < 48; y++) for (let x = 0; x < 48; x++) {
    const d = Math.hypot(x - C, y - C);
    if (d < 13.5) b.pset(x, y, cols[d > 12.2 ? 0 : d > 10.5 ? 1 : d > 6 ? 2 : 3]);
  }
  P.save(b, process.argv[2] + `/${name}.png`);
}
