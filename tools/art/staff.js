// Pracownicy obserwatorium (Etap 2): dla każdego zwierzaka portret do rozmów i działu HR (portrait_w_<id>.png,
// 2 klatki 88x88: oczy otwarte, mrugnięcie) oraz sprite przy biurku (worker_<id>.png, 4 klatki 44x64 przodem).
// Jeden opis gatunku steruje jednym i drugim: te same kolory, uszy, znaczenia, okulary, czapka. Wszyscy w kitlach.
// Styl jak portraits.js (maski, obrys 1 px, płaskie tony) i dogs.js (bryły P.solid, światło z góry).
// node staff.js <out>
const { P, Canvas, ell, sup, cap, rell, or, tri, eye, ring, mir, ramp, CX, INK } = require("./portraits.js");
const { ink } = require("./kit.js");
const out = process.argv[2] || ".";

const R = (n, [hue, sat, l0, l1]) => ramp(n, { hue, shift: n > 2 ? 18 : 10, sat, light: [l0, l1] });
const COAT = ramp(3, { hue: 214, shift: 14, sat: 0.1, light: [0.72, 0.96] });
const COAT4 = ramp(4, { hue: 214, shift: 16, sat: 0.08, light: [0.6, 0.95] });
const EYE = [30, 20, 18], SHINE = [255, 252, 244], NOSE = [26, 20, 22], MOUTH = [86, 66, 70], PINK = [236, 150, 164];
const WHITE = [40, 0.1, 0.84, 0.96], CREAM = [38, 0.3, 0.78, 0.92];
const HATS = { red: [356, 0.6, 0.4, 0.62], blue: [216, 0.5, 0.36, 0.6], green: [140, 0.4, 0.32, 0.54], yellow: [44, 0.7, 0.5, 0.74], plum: [300, 0.3, 0.34, 0.54] };

// ---- gatunki. fur / light / dark: [hue, sat, l0, l1]; ears: point big lop round small long tuft none;
// mark: blaze cheeks mask stripes patch siam lemur disc tabby face; nose: dog cat small pig big teeth beak wide turtle;
// eyes: dot cat big sleepy; glasses: round square; hat: [typ, kolor] typ = cap beret bow
const S = {
  // pieski
  pies_shiba: { fur: [28, 0.62, 0.4, 0.68], ears: "point", mark: "cheeks", nose: "dog", tail: "curl", tongue: true },
  pies_beagle: { fur: [26, 0.5, 0.3, 0.54], ears: "lop", mark: "blaze", nose: "dog", tail: "long", hat: ["cap", "blue"] },
  pies_pudel: { fur: [36, 0.16, 0.66, 0.9], light: [36, 0.12, 0.8, 0.94], ears: "lop", nose: "dog", tail: "short", pouf: true, glasses: "round" },
  pies_husky: { k: 1.04, fur: [220, 0.1, 0.34, 0.6], ears: "point", mark: "lemur", nose: "dog", tail: "long", iris: [120, 190, 240] },
  pies_mops: { sh: "ball", k: 0.86, chub: 1.15, fur: [38, 0.36, 0.56, 0.8], dark: [30, 0.2, 0.14, 0.26], ears: "lop", mark: "siam", nose: "dog", tail: "curl", light: [30, 0.2, 0.2, 0.3], darkEars: true },
  pies_jamnik: { k: 0.84, chub: 1.1, fur: [20, 0.5, 0.2, 0.42], light: [30, 0.5, 0.56, 0.7], ears: "lop", nose: "dog", tail: "long", hat: ["beret", "red"] },
  // liski
  lis: { fur: [22, 0.74, 0.36, 0.64], ears: "big", mark: "cheeks", nose: "small", tail: "long" },
  lis_polarny: { fur: [214, 0.1, 0.62, 0.9], light: [214, 0.06, 0.86, 0.97], ears: "point", mark: "cheeks", nose: "small", tail: "long", glasses: "square" },
  // kotki
  kot_rudy: { sh: "cat", k: 0.9, whisk: true, tailUp: true, fur: [26, 0.7, 0.42, 0.7], ears: "point", mark: "tabby", nose: "cat", eyes: "cat", iris: [132, 200, 64], tail: "long" },
  kot_czarny: { sh: "cat", k: 0.9, whisk: true, tailUp: true, fur: [250, 0.12, 0.1, 0.26], light: [250, 0.1, 0.2, 0.32], ears: "point", nose: "cat", eyes: "cat", iris: [250, 208, 70], tail: "long", hat: ["bow", "red"] },
  kot_syjam: { sh: "cat", k: 0.9, whisk: true, tailUp: true, fur: [38, 0.3, 0.68, 0.88], dark: [24, 0.3, 0.16, 0.3], ears: "point", mark: "siam", nose: "cat", eyes: "cat", iris: [110, 180, 240], tail: "long", darkEars: true, light: [24, 0.3, 0.2, 0.32] },
  // łasicowate, szop, borsuk
  borsuk: { chub: 1.15, k: 0.96, fur: [220, 0.05, 0.8, 0.96], dark: [220, 0.06, 0.1, 0.2], ears: "small", mark: "stripes", nose: "dog", tail: "short", body: [220, 0.05, 0.3, 0.5] },
  lasica: { head: "tri", sh: "slim", k: 0.84, fur: [24, 0.55, 0.36, 0.62], ears: "small", mark: "face", nose: "small", tail: "long" },
  kuna: { head: "tri", sh: "slim", k: 0.9, fur: [24, 0.45, 0.24, 0.48], light: [42, 0.5, 0.74, 0.88], ears: "point", mark: "face", nose: "small", tail: "long", glasses: "round" },
  wydra: { head: "flat", sh: "slim", k: 0.96, whisk: true, fur: [26, 0.3, 0.24, 0.46], light: [32, 0.22, 0.62, 0.78], ears: "small", mark: "face", nose: "big", tail: "long" },
  szop: { chub: 1.1, fur: [230, 0.08, 0.4, 0.66], dark: [230, 0.1, 0.1, 0.2], ears: "round", mark: "mask", nose: "small", tail: "long" },
  // gryzonie i spółka
  wombat: { head: "ball", sh: "ball", k: 0.98, chub: 1.2, fur: [28, 0.14, 0.34, 0.56], ears: "tuft", nose: "big", tail: "none", bigMuz: true, light: [30, 0.14, 0.5, 0.66] },
  kapibara: { head: "block", sh: "block", k: 1.04, chub: 1.15, eyeY: 47, fur: [28, 0.44, 0.32, 0.56], ears: "top", nose: "big", eyes: "sleepy", tail: "none", bigMuz: true, light: [28, 0.4, 0.44, 0.62], hat: ["cap", "yellow"] },
  bobr: { sh: "ball", k: 0.92, chub: 1.15, paddle: true, fur: [20, 0.4, 0.2, 0.42], light: [30, 0.3, 0.5, 0.66], ears: "small", nose: "teeth", tail: "short" },
  wiewiorka: { sh: "cat", k: 0.84, bushy: true, fur: [16, 0.7, 0.32, 0.58], ears: "tuft", mark: "face", nose: "small", tail: "long" },
  jez: { head: "tri", sh: "ball", k: 0.84, chub: 1.1, fur: [32, 0.3, 0.66, 0.86], ears: "small", nose: "small", tail: "none", spikes: [28, 0.3, 0.16, 0.36], muz: false },
  swinka: { head: "ball", sh: "ball", k: 0.96, chub: 1.25, hoof: true, fur: [352, 0.5, 0.7, 0.88], ears: "fold", nose: "pig", tail: "curl", earIn: [352, 0.5, 0.56, 0.7], muz: false },
  lemur: { sh: "cat", k: 0.9, fur: [220, 0.06, 0.46, 0.7], dark: [220, 0.08, 0.08, 0.18], ears: "round", mark: "lemur", nose: "small", eyes: "dot", iris: [240, 150, 40], tail: "ring" },
  mis: { sh: "ball", k: 1.06, chub: 1.12, fur: [26, 0.45, 0.22, 0.46], light: [32, 0.4, 0.56, 0.72], ears: "round", nose: "dog", tail: "none" },
  // króliki (biały zostaje wolny: unikat do późniejszej scenki)
  krolik: { fur: [32, 0.36, 0.5, 0.76], ears: "long", nose: "cat", tail: "none" },
  krolik_czarny: { fur: [250, 0.1, 0.12, 0.3], light: [250, 0.08, 0.24, 0.36], ears: "long", nose: "cat", tail: "none" },
  // ptaki
  papuga: { k: 0.88, bird: true, fur: [128, 0.6, 0.34, 0.6], light: [50, 0.8, 0.6, 0.8], head: "round", ears: "none", nose: "beak", beak: [[40, 0.1, 0.2, 0.4], "hook"], crest: [356, 0.7, 0.42, 0.6], mark: "disc", muz: false, tail: "none", chest: "fur" },
  golab: { k: 0.84, bird: true, fur: [220, 0.1, 0.48, 0.72], head: "round", ears: "none", nose: "beak", beak: [[30, 0.2, 0.3, 0.5], "small"], muz: false, tail: "none", iris: [240, 130, 40], collar: [150, 0.4, 0.4, 0.6], chest: "fur" },
  ges: { k: 1.0, bird: true, neck: true, fur: [40, 0.08, 0.84, 0.97], head: "round", ears: "none", nose: "beak", beak: [[28, 0.8, 0.5, 0.68], "flat"], muz: false, tail: "none", chest: "fur" },
  kura: { k: 0.86, bird: true, fur: [28, 0.5, 0.42, 0.68], head: "round", ears: "none", nose: "beak", beak: [[42, 0.8, 0.52, 0.72], "small"], crest: [356, 0.7, 0.42, 0.6], wattle: true, muz: false, tail: "none", chest: "fur" },
  sowa: { k: 0.92, chub: 1.15, bird: true, fur: [28, 0.36, 0.3, 0.56], light: [38, 0.3, 0.74, 0.9], head: "round", ears: "tuft", nose: "beak", beak: [[40, 0.5, 0.5, 0.7], "small"], mark: "disc", eyes: "big", iris: [250, 200, 60], muz: false, tail: "none", glasses: "round", chest: "fur" },
  // gady i płazy
  zolw: { k: 0.9, fur: [100, 0.36, 0.36, 0.6], head: "narrow", ears: "none", nose: "turtle", muz: false, tail: "none", shell: [130, 0.3, 0.2, 0.4], glasses: "round", chest: "fur" },
  ropucha: { k: 0.9, chub: 1.2, fur: [80, 0.36, 0.3, 0.52], light: [60, 0.36, 0.66, 0.82], head: "wide", ears: "none", nose: "wide", eyes: "big", iris: [240, 190, 60], muz: false, tail: "none", warts: true },
};

// ================================================================ PORTRET 88x88
function portrait(id, blink) {
  const s = S[id], c = new Canvas();
  const fur = R(3, s.fur), light = R(2, s.light || WHITE), dark = s.dark ? R(3, s.dark) : null;
  const flat = (r) => [r[1] || r[0], r[1] || r[0]];
  c.add("body", sup(CX, 101, 27, 25, 2.2), COAT, { group: "body" });
  c.add("chest", tri(CX - 9, 75, CX + 9, 75, CX, 92), s.chest === "fur" ? flat(fur) : light, { group: "body", flat: true });
  if (s.collar) c.add("collar", ell(CX, 76, 9, 3), flat(R(2, s.collar)), { group: "body", flat: true });
  for (let y = 76; y < 92; y++) { const d = Math.round((y - 75) * 9 / 17); c.set(CX - 10 + d, y, COAT[0]); c.set(mir(CX - 10 + d), y, COAT[0]); }  // klapy
  for (let x = 58; x < 66; x++) c.set(x, 84, COAT[0]);                                                 // kieszonka
  if (s.shell) c.add("ears", sup(CX, 72, 26, 14, 2.2), R(3, s.shell), { group: "ears" });               // skorupa za karkiem
  if (s.spikes) {  // jeż: ostre kolce dookoła głowy (ząb piły), jaśniejsze końcówki
    const saw = (x, y, k) => { const a = Math.atan2(y - 56, x - CX), r = Math.hypot((x - CX) / 1.1, y - 56), t = Math.abs(((a * 11 / Math.PI) % 2 + 2) % 2 - 1); return y < 72 && r < k + 9 * t; };
    c.add("spk", (x, y) => saw(x, y, 21), R(3, s.spikes), { group: "ears", raw: true });
    c.add("spk2", (x, y) => saw(x, y, 13) && !saw(x, y, 11.5), [[150, 124, 96], [150, 124, 96]], { group: "ears", flat: true, raw: true });
  }
  const earR = s.darkEars ? dark : fur, earIn = R(2, s.earIn || [350, 0.4, 0.66, 0.78]);
  const E = (name, f, r, o = {}) => c.add(name, f, r, { group: "ears", mirror: true, ...o });
  if (s.ears === "point") { E("ears", tri(32, 44, 20, 46, 22, 24), earR); E("earsi", tri(30, 43, 23, 44, 24, 30), earIn, { flat: true }); }
  if (s.ears === "big") { E("ears", tri(35, 44, 17, 48, 19, 16), earR); E("earsi", tri(32, 43, 21, 45, 22, 24), dark ? flat(dark) : [[44, 30, 36], [44, 30, 36]], { flat: true }); }
  if (s.ears === "round") { E("ears", ell(25, 41, 7.5, 7.5), earR); E("earsi", ell(25, 42, 4, 4), earIn, { flat: true }); }
  if (s.ears === "small") E("ears", s.head === "flat" ? ell(22, 52, 4.5, 4.5) : s.head === "tri" ? ell(27, 44, 5, 5) : ell(26, 44, 5, 5), earR);
  if (s.ears === "top") E("ears", ell(31, 37, 4.5, 4), earR);                                          // kapibara: małe uszy na czubku
  if (s.ears === "fold") { E("ears", tri(34, 46, 16, 42, 24, 30), earR); E("earsi", tri(30, 44, 20, 42, 25, 35), earIn, { flat: true }); }
  if (s.ears === "tuft") E("ears", tri(33, 43, 21, 44, 20, 27), earR);
  if (s.ears === "long" || s.ears === "longlop") {
    c.add("ears", cap(34, 42, 31, 13, 5.5), fur, { group: "ears" }); c.add("earsi", cap(34, 39, 31.5, 16, 2.3), earIn, { group: "ears", flat: true });
    if (s.ears === "long") { c.add("ears2", cap(54, 42, 57, 13, 5.5), fur, { group: "ears" }); c.add("earsi2", cap(54, 39, 56.5, 16, 2.3), earIn, { group: "ears", flat: true }); }
  }
  if (s.crest) c.add("ears", or(ell(38, 38, 4, 6), ell(44, 35, 4, 7), ell(50, 38, 4, 6)), R(3, s.crest), { group: "ears" });
  const HEAD = { round: ell(CX, 57, 20, 19), narrow: sup(CX, 56, 16, 18, 2.4), wide: or(sup(CX, 61, 24, 14, 2.6), ell(31, 47, 8, 8), ell(57, 47, 8, 8)),
    block: sup(CX, 57, 17, 21, 3.4),                                             // kapibara: wysoki, kanciasty łeb
    flat: or(sup(CX, 61, 24, 13, 2.3), ell(CX, 54, 17, 12)),                     // wydra: szeroki, spłaszczony
    ball: ell(CX, 58, 24, 19),                                                   // wombat, świnka: kula
    tri: or(ell(CX, 54, 19, 14), tri(CX - 17, 58, CX + 17, 58, CX, 78)) };       // kuna, łasica, jeż: pyszczek w szpic
  c.add("head", HEAD[s.head] || or(sup(CX, 57, 21, 17, 2.3), ell(30, 66, 10, 8), ell(58, 66, 10, 8)), fur, { group: "head" });
  if (s.pouf) c.add("pouf", or(ell(CX, 39, 12, 7), ell(36, 41, 6, 5), ell(52, 41, 6, 5)), fur, { group: "cap" });   // pudel: czupryna
  if (s.ears === "lop") c.add("lop", or(cap(27, 43, 20, 58, 5.5), cap(61, 43, 68, 58, 5.5)), s.darkEars ? dark : R(3, [s.fur[0], s.fur[1], s.fur[2] * 0.75, s.fur[3] * 0.8]), { group: "lop" });
  if (s.ears === "longlop") c.add("lop", cap(57, 42, 68, 60, 5.5), fur, { group: "lop" });
  const H = (name, f, r) => c.add(name, f, r, { group: "head", flat: true });
  // znaczenia
  let lid = fur[1];
  if (s.mark === "blaze") H("blaze", (x, y) => { const u = (y - 44) / 30; return u >= 0 && u <= 1 && Math.abs(x - CX) <= (u < 0.45 ? 1 + u * 6 : 3.7 + (u - 0.45) * 22); }, light);
  if (s.mark === "cheeks") H("cheek", or(ell(28, 66, 9, 7), ell(60, 66, 9, 7)), light);
  if (s.mark === "face") H("face", ell(CX, 63, 13, 10), light);
  if (s.mark === "mask") { H("brow", or(ell(33, 49, 8, 4), ell(55, 49, 8, 4)), light); H("mask", or(rell(32, 55, 10, 5.5, 0.2), rell(56, 55, 10, 5.5, -0.2)), flat(dark)); lid = dark[1]; }
  if (s.mark === "stripes") { H("stripe", or(sup(33, 52, 5, 13, 2.2), sup(55, 52, 5, 13, 2.2)), flat(dark)); lid = dark[1]; }
  if (s.mark === "siam") { H("siam", ell(CX, 60, 13, 11), flat(dark)); lid = dark[1]; }
  if (s.mark === "lemur") { H("face", or(ell(CX, 62, 15, 11), ell(33, 54, 9, 8), ell(55, 54, 9, 8)), light); if (dark) { H("patch", or(ell(33, 55, 6, 5.5), ell(55, 55, 6, 5.5)), flat(dark)); lid = dark[1]; } else lid = light[1]; }
  if (s.mark === "disc") { H("disc", or(ell(34, 55, 10.5, 10.5), ell(54, 55, 10.5, 10.5)), light); lid = light[1]; }
  if (s.mark === "tabby") for (const [x, y] of [[33, 43], [33, 44], [33, 45], [36, 42], [36, 43], [36, 44], [24, 60], [25, 60], [26, 60], [24, 64], [25, 64], [26, 64]]) { c.set(x, y, fur[0]); c.set(mir(x), y, fur[0]); }
  const big = s.head === "block" ? sup(CX, 66, 13, 10, 3) : s.head === "flat" ? or(ell(37, 66, 9, 6.5), ell(51, 66, 9, 6.5)) : sup(CX, 65, 11, 7.5, 2.4);
  if (s.muz !== false) H("muzzle", s.bigMuz || s.head === "flat" ? big : s.head === "tri" ? ell(CX, 68, 6, 6) : or(ell(41, 66, 5.5, 4.8), ell(47, 66, 5.5, 4.8)), light);
  if (s.head === "tri" && s.muz === false) H("snoutj", ell(CX, 70, 5, 5), light);
  if (s.whisk) for (let k = 0; k < 8; k++) for (const y0 of [64, 68]) { const x = 30 - k, y = y0 + (y0 === 64 ? -1 : 1) * Math.floor(k / 3); c.set(x, y, [240, 236, 226]); c.set(mir(x), y, [240, 236, 226]); }
  if (s.warts) for (const [x, y] of [[26, 58], [27, 62], [24, 66], [38, 53], [30, 70]]) { c.set(x, y, fur[0]); c.set(mir(x), y, fur[0]); }
  // oczy
  const iris = s.iris || null, ey = s.eyeY || (s.head === "wide" ? 44 : s.head === "tri" ? 50 : 52), nd = s.head === "tri" ? 5 : s.head === "block" ? 2 : 0;
  if (s.eyes === "cat") for (const ex of [30, 51]) {
    if (blink) { for (let x = 0; x < 7; x++) c.set(ex + x, 57, EYE); continue; }
    for (let y = 0; y < 7; y++) for (let x = 0; x < 7; x++) if (!((x === 0 || x === 6) && (y === 0 || y === 6))) c.set(ex + x, 53 + y, iris);
    for (let y = 54; y < 59; y++) c.set(ex + 3, y, NOSE);
    c.set(ex + 1, 54, SHINE); c.set(ex + 1, 55, SHINE);
  } else if (s.eyes === "big") for (const ox of [33, 54]) {
    const oy = ey + 3;
    for (let y = -4; y <= 4; y++) for (let x = -4; x <= 4; x++) if (x * x + y * y <= 18) c.set(ox + x, oy + y, blink ? lid : x * x + y * y <= 4 ? NOSE : iris);
    if (blink) for (let x = -4; x <= 4; x++) c.set(ox + x, oy + 1, EYE); else c.set(ox - 2, oy - 2, SHINE);
    ring(c, ox, oy, 5, s.head === "wide" ? fur[0] : INK);
  } else for (const ex of [31, 52]) eye(c, ex, s.eyes === "sleepy" ? ey + 2 : ey, 5, s.eyes === "sleepy" ? 4 : 6, EYE, s.eyes === "sleepy" ? null : iris, blink ? lid : null);
  // nos i pyszczek (nd: niżej przy pyszczku w szpic)
  const set0 = c.set.bind(c), addH = H;
  c.set = (x, y, col, n) => set0(x, y + nd, col, n);
  const px = (pts, col) => { for (const [x, y] of pts) c.set(x, y, col); };
  const mouth = [[43, 66], [44, 66], [43, 67], [44, 67], [42, 68], [41, 68], [45, 68], [46, 68]];
  if (s.nose === "dog") { for (let y = 61; y < 65; y++) for (let x = 40; x < 48; x++) if (!((x === 40 || x === 47) && (y === 61 || y === 64))) c.set(x, y, NOSE); px([[42, 62], [43, 62]], [120, 120, 130]); px(mouth.map(([x, y]) => [x, y - 1]), MOUTH); if (s.tongue) px([[43, 68], [44, 68], [43, 69], [44, 69], [43, 70], [44, 70]], PINK); }
  if (s.nose === "cat") { for (let y = 63; y < 66; y++) for (let x = 41; x < 47; x++) if (!(y === 65 && (x === 41 || x === 46))) c.set(x, y, PINK); px(mouth, MOUTH); }
  if (s.nose === "small") { for (let y = 62; y < 65; y++) for (let x = 41; x < 47; x++) if (!(y === 64 && (x === 41 || x === 46))) c.set(x, y, NOSE); px([[42, 62]], [120, 120, 130]); px(mouth.map(([x, y]) => [x, y - 1]), MOUTH); }
  if (s.nose === "big") { H("nose", sup(CX, 61 + nd, s.head === "block" ? 9 : 6.5, 3.6, 2.4), [NOSE, NOSE]); px([[40, 59], [41, 59]], [110, 110, 120]); px([[43, 65], [44, 65], [43, 66], [44, 66], [42, 67], [41, 67], [45, 67], [46, 67]], MOUTH); }
  if (s.nose === "teeth") { for (let y = 61; y < 64; y++) for (let x = 41; x < 47; x++) c.set(x, y, NOSE); px([[43, 64], [44, 64], [42, 65], [41, 65], [45, 65], [46, 65]], MOUTH); for (let y = 66; y < 70; y++) for (let x = 41; x < 47; x++) c.set(x, y, x === 43 || x === 44 ? (x === 43 ? [250, 246, 232] : [226, 220, 200]) : [250, 246, 232]); for (let y = 66; y < 70; y++) { c.set(40, y, INK); c.set(47, y, INK); } for (let x = 41; x < 47; x++) c.set(x, 70, INK); for (let y = 66; y < 70; y++) c.set(44, y, [200, 190, 170]); }
  if (s.nose === "pig") { H("snout", ell(CX, 64, 8.5, 5.5), [[226, 130, 150], [226, 130, 150]]); for (const x of [40, 41, 46, 47]) for (let y = 62; y < 66; y++) c.set(x, y, [150, 70, 90]); px([[42, 71], [43, 72], [44, 72], [45, 71]], [150, 70, 90]); }
  if (s.nose === "turtle") { px([[41, 60], [46, 60]], [40, 60, 40]); for (let x = 34; x < 54; x++) c.set(x, 66 + (x < 37 || x > 50 ? -1 : 0), [40, 60, 40]); }
  if (s.nose === "wide") { px([[40, 58], [47, 58]], fur[0]); for (let x = 25; x < 63; x++) c.set(x, 66 + (x < 29 || x > 58 ? -1 : 0), [40, 44, 30]); H("lip", (x, y) => y > 67 && ell(CX, 66, 17, 7)(x, y), light); }
  if (s.nose === "beak") {
    const [bc, kind] = s.beak, br = R(3, bc);
    const f = kind === "flat" ? ell(CX, 65, 9.5, 5) : kind === "hook" ? or(ell(CX, 63, 7, 6.5), tri(CX - 5, 66, CX + 5, 66, CX, 76)) : tri(CX - 6, 60, CX + 6, 60, CX, 70);
    if (s.wattle) c.add("wattle", ell(CX, 71, 3.5, 5), R(3, s.crest), { group: "cap" });
    c.add("beak", f, br, { group: "cap" });
    if (kind === "flat") { for (let x = 37; x < 51; x++) c.set(x, 66, br[0]); px([[41, 62], [46, 62]], br[0]); }
    if (kind === "hook") px([[40, 62], [47, 62]], [120, 120, 130]);
  }
  c.set = set0;
  // okulary i czapki
  if (s.glasses === "round") { for (const ox of [33, 54]) ring(c, ox, 55, 7, INK); for (let x = 41; x <= 46; x++) c.set(x, 54, INK); for (let x = 20; x < 26; x++) { c.set(x, 53 - Math.floor((26 - x) / 3), INK); c.set(mir(x), 53 - Math.floor((26 - x) / 3), INK); } px([[29, 50], [50, 50]], [232, 240, 255]); }
  if (s.glasses === "square") { for (const x0 of [26, 47]) { for (let x = x0; x < x0 + 15; x++) { c.set(x, 49, INK); c.set(x, 61, INK); } for (let y = 49; y < 62; y++) { c.set(x0, y, INK); c.set(x0 + 14, y, INK); } c.set(x0 + 2, 51, [232, 240, 255]); } for (let x = 41; x < 47; x++) c.set(x, 53, INK); }
  if (s.hat) {
    const hr = R(3, HATS[s.hat[1]]);
    if (s.hat[0] === "cap") { c.add("cap", (x, y) => y < 43 && ell(CX, 43, 16, 11)(x, y), hr, { group: "cap" }); c.add("brim", sup(CX, 44, 19, 2.6, 2), [hr[0], hr[0]], { group: "cap", flat: true }); }
    if (s.hat[0] === "beret") { c.add("cap", rell(CX + 2, 38, 16, 6.5, -0.12), hr, { group: "cap" }); px([[46, 30], [46, 31], [47, 30]], hr[0]); }
    if (s.hat[0] === "bow") c.add("cap", or(tri(60, 40, 51, 34, 51, 46), tri(60, 40, 69, 34, 69, 46), ell(60, 40, 2.5, 2.5)), hr, { group: "cap" });
  }
  return c.render();
}

// ================================================================ SPRITE 44x64 (przodem, 4 klatki: ogon / kołysanie)
const FW = 44, FH = 64, SX = 21.5, WAG = [-1, -0.6, 0.6, 1];
function sprite(id, wag) {
  const s = S[id], K = s.k || 0.92, ch = s.chub || 1, fur = R(4, s.fur), light = R(2, s.light || WHITE), dark = s.dark ? R(4, s.dark) : null, body = s.body ? R(4, s.body) : fur;
  const X = (x) => (x - 16) * K + SX, Y = (y) => FH - 2 - (48 - y) * K;
  const E = (x, y, rx, ry) => P.ell(X(x), Y(y), rx * K, ry * K), C = (ax, ay, bx, by, ra, rb = ra) => P.cap(X(ax), Y(ay), X(bx), Y(by), ra * K, rb * K);
  const b = new P.Buf(FW - 2, FH - 3); b.ox = 1; b.oy = 1;
  const So = (prims, r, o) => P.solid(b, prims, r, { light: [0, -0.62, 0.78], ...o });
  const L = Math.floor(SX), Rr = L + 1, sym = (d, y, c) => { b.pset(L - d, y, c); b.pset(Rr + d, y, c); };
  const fill = (cx, cy, rx, ry, c) => { for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = 1; x <= FW - 2; x++) if (((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1) b.pset(x, y, c); };
  const feet = s.nose === "beak" ? R(2, s.beak[0]) : light;
  // ogon za ciałem
  if (s.tailUp) So([C(20, 40, 27 + wag, 36, 1.3), C(27 + wag, 36, 27 + wag * 2, 27, 1.3, 1.1)], body, { dark: 0.9 });            // kot: cienki ogon w górę
  else if (s.bushy) So([C(22, 40, 28, 32, 3.2), E(27 + wag, 25, 4.4, 5.6)], body, { dark: 0.92 });                                // wiewiórka: kita nad ramieniem
  else if (s.paddle) So([E(16 + wag * 3, 44.5, 5.5, 2.6)], R(4, [24, 0.2, 0.14, 0.3]));                                            // bóbr: płaski ogon
  else if (s.tail === "long" || s.tail === "ring") So([C(16, 36, 16 + wag * 12.8, 31.6, 1.6, 1.3)], s.tail === "ring" ? R(4, s.dark) : body, { dark: 0.9 });
  else if (s.tail === "short") So([C(16, 36, 16 + wag * 9, 33.4, 1.7, 1.4)], body, { dark: 0.9 });
  if (s.tail === "curl") So([E(16 + wag * 2 + 9, 33, 2.4, 2.4)], body, { dark: 0.9 });
  if (s.shell) So([E(16, 35, 10.5, 8.5)], R(4, s.shell));
  if (s.bird) { for (const x of [12.5, 19.5]) { So([C(x, 41, x, 45, 0.8)], feet); So([E(x, 45.6, 2.6, 1)], feet); } }   // ptaki: cienkie nóżki
  else So([E(11, 45, 3.6, 2), E(21, 45, 3.6, 2)], s.hoof ? R(2, [20, 0.2, 0.2, 0.34]) : feet);
  So(s.bird ? [E(16, 35.5, 7.4 * ch, 7)] : [C(12, 39, 12, 43, 3.2), C(20, 39, 20, 43, 3.2), E(16, 35, 7.4 * ch, 6.4)], COAT4);
  if (s.neck) So([C(16, 30, 16, 25, 2.6)], fur);
  So([C(8, 30, 7, 37, 2.1, 1.9), C(24, 30, 25, 37, 2.1, 1.9)], COAT4);                                   // rękawy kitla
  So([E(7, 38, 2, 1.7), E(25, 38, 2, 1.7)], s.nose === "beak" ? fur : light);
  const by = Math.round(Y(30));
  for (let d = 0; d < 2; d++) for (let y = by; y < by + 4 - d * 2; y++) sym(d, y, s.chest === "fur" ? fur[2] : light[1]);       // dekolt
  for (let y = by + 4; y < by + 10; y++) b.pset(L + 1, y, COAT4[1]);                                     // zapięcie
  fill(SX, Y(28.4), 6 * K, 3 * K, body[1]);
  if (s.spikes) { const sp = R(4, s.spikes); So([E(16, 20, 12, 10)], sp); for (let a = 0; a < 9; a++) { const an = Math.PI * (1 + a / 8); b.pset(Math.round(X(16 + Math.cos(an) * 12.6)), Math.round(Y(20 + Math.sin(an) * 10.6)), sp[1]); } }
  const earR = s.darkEars ? dark : fur;
  if (s.ears === "point") So([C(10.5, 17, 7.4, 9.5, 3.0, 0.8), C(21.5, 17, 24.6, 9.5, 3.0, 0.8)], earR);
  if (s.ears === "big") So([C(10.5, 17, 6.4, 6.5, 3.2, 0.8), C(21.5, 17, 25.6, 6.5, 3.2, 0.8)], earR);
  if (s.ears === "round") So([E(8.6, 15, 3.2, 3.2), E(23.4, 15, 3.2, 3.2)], earR);
  if (s.ears === "small") So(s.sh === "slim" ? [E(10.4, 17, 2, 2), E(21.6, 17, 2, 2)] : [E(8.4, 15.6, 2.3, 2.3), E(23.6, 15.6, 2.3, 2.3)], earR);
  if (s.ears === "top") So([E(11.5, 12.6, 1.8, 1.8), E(20.5, 12.6, 1.8, 1.8)], earR);
  if (s.ears === "fold") So([C(9, 15.5, 5.6, 17.5, 2.6, 1.2), C(23, 15.5, 26.4, 17.5, 2.6, 1.2)], earR, { dark: 0.9 });
  if (s.ears === "tuft") So([C(10.5, 17, 8, 10.5, 2.4, 0.6), C(21.5, 17, 24, 10.5, 2.4, 0.6)], earR);
  if (s.ears === "long" || s.ears === "longlop") { So([C(12, 15, 11.4, 3, 2.3, 2.7)], fur); if (s.ears === "long") So([C(20, 15, 20.6, 3, 2.3, 2.7)], fur); }
  if (s.crest) So([E(13.5, 13.6, 1.6, 2.2), E(16, 12.6, 1.6, 2.6), E(18.5, 13.6, 1.6, 2.2)], R(4, s.crest));
  const hy = s.neck ? -4 : 0;
  const hd = s.sh === "cat" ? [E(16, 21.6, 8, 6.4)] : s.sh === "slim" ? [E(16, 21.4, 6.8, 6.2), E(16, 24.6, 4.4, 3.4)] : s.sh === "block" ? [C(16, 18.5, 16, 23.5, 7, 7.6)] : s.sh === "ball" ? [E(16, 21, 10, 8.2)] :
    s.neck ? [E(16, 17, 7, 6.6)] : s.head === "round" ? [E(16, 21, 8.6, 8)] : s.head === "narrow" ? [E(16, 21, 7.2, 7.8)] : s.head === "wide" ? [E(16, 22.5, 10, 6.2), E(11, 16.5, 3.2, 3.2), E(21, 16.5, 3.2, 3.2)] : [E(16, 21, 9, 7.4), E(10, 24, 3.6, 3), E(22, 24, 3.6, 3)];
  So(hd, fur, { ambient: 0.5 });
  if (s.pouf) So([E(16, 14.4, 5, 3)], fur);
  if (s.ears === "lop") So([C(9.5, 16, 6.5, 21, 2.4, 1.8), C(22.5, 16, 25.5, 21, 2.4, 1.8)], s.darkEars ? dark : fur, { dark: 0.8 });
  if (s.ears === "longlop") So([C(21, 15, 25.5, 23, 2.3, 2)], fur, { dark: 0.85 });
  const wide = s.head === "wide", ey = Math.round(Y((wide ? 15.6 : s.sh === "block" ? 17.6 : 20) + hy)), ny = Math.round(Y((s.sh === "slim" ? 24.6 : 23.4) + hy)), e0 = s.sh === "slim" ? 3 : s.sh === "ball" || s.sh === "block" ? 5 : 4, eh = 3;
  // znaczenia
  if (s.mark === "blaze") { for (let y = Math.round(Y(15)); y < ny; y++) sym(0, y, light[1]); fill(SX, Y(25), 5 * K, 3 * K, light[1]); }
  if (s.mark === "cheeks") { fill(X(9.6), Y(24.6), 3.2, 2.4, light[1]); fill(X(22.4), Y(24.6), 3.2, 2.4, light[1]); }
  if (s.mark === "face" || s.mark === "lemur") fill(SX, Y(23.6), 6.4 * K, 4.4 * K, light[1]);
  if (s.mark === "disc") { fill(X(12.2), Y(20.6), 3.6, 3.6, light[1]); fill(X(19.8), Y(20.6), 3.6, 3.6, light[1]); }
  if (s.mark === "siam") fill(SX, Y(22.6), 5.6 * K, 4.6 * K, dark[1]);
  if (s.mark === "mask") for (let d = 2; d < 8; d++) for (let y = ey - 1; y < ey + eh + 1; y++) sym(d, y, dark[1]);
  if (s.mark === "stripes") for (let d = 3; d < 7; d++) for (let y = Math.round(Y(15.5)); y < ey + eh + 2; y++) sym(d, y, dark[1]);
  if (s.mark === "lemur" && dark) for (let d = 3; d < 7; d++) for (let y = ey - 1; y < ey + eh + 1; y++) sym(d, y, dark[1]);
  if (s.mark === "tabby") { sym(2, Math.round(Y(15.5)), fur[0]); sym(4, Math.round(Y(15.2)), fur[0]); sym(8, ny, fur[0]); }
  if (s.muz !== false && s.mark !== "siam") fill(SX, Y(s.sh === "block" ? 24 : 25), (s.sh === "block" ? 6.4 : s.bigMuz ? 5.6 : s.sh === "slim" ? 3.4 : 4.4) * K, (s.sh === "block" ? 4.2 : s.bigMuz ? 3.4 : 2.6) * K, light[1]);
  if (s.whisk) for (const d of [7, 8, 9]) { sym(d, ny + 1, [240, 236, 226]); if (d > 7) sym(d, ny + 3, [240, 236, 226]); }
  // oczy
  const big = s.eyes === "big", ic = s.iris || EYE;
  if (big) { for (const d of [e0 - 1, e0, e0 + 1, e0 + 2]) for (let y = ey - 1; y < ey + eh; y++) sym(d, y, ic); for (const d of [e0, e0 + 1]) for (let y = ey; y < ey + 2; y++) sym(d, y, EYE); }
  else if (s.eyes === "sleepy") for (const d of [e0, e0 + 1]) { sym(d, ey + 1, EYE); sym(d, ey + 2, EYE); }
  else { for (const d of [e0, e0 + 1]) for (let y = ey; y < ey + eh; y++) sym(d, y, s.eyes === "cat" ? (d === e0 + 1 && false ? ic : EYE) : EYE); if (s.eyes === "cat" || s.iris) { sym(e0 + 1, ey + 1, ic); sym(e0 + 1, ey + 2, ic); } b.pset(L - e0 - 1, ey, SHINE); b.pset(Rr + e0, ey, SHINE); }
  // nos, dziób
  const nc = s.nose === "cat" ? PINK : s.nose === "pig" ? [200, 100, 124] : NOSE;
  if (s.nose === "beak") { const br = R(2, s.beak[0]), k = s.beak[1]; const w = k === "flat" ? 3 : k === "hook" ? 2 : 1; for (let d = 0; d < w; d++) for (let y = ny; y < ny + (k === "flat" ? 2 : 3) - (k === "flat" ? 0 : d); y++) sym(d, y, y === ny ? br[1] : br[0]); if (k === "hook") sym(0, ny + 3, br[0]); if (s.wattle) { sym(0, ny + 3, R(2, s.crest)[1]); sym(0, ny + 4, R(2, s.crest)[0]); } }
  else if (s.nose === "pig") { for (let d = 0; d < 4; d++) for (let y = ny - 1; y < ny + 3; y++) if (!(d === 3 && (y === ny - 1 || y === ny + 2))) sym(d, y, [226, 130, 150]); sym(1, ny, [150, 70, 90]); sym(1, ny + 1, [150, 70, 90]); }
  else if (s.nose === "turtle") { for (let d = 0; d < 4; d++) sym(d, ny + 2, [40, 60, 40]); }
  else if (s.nose === "wide") { for (let d = 0; d < 7; d++) sym(d, ny + 1, [40, 44, 30]); for (let d = 0; d < 5; d++) sym(d, ny + 2, light[1]); }
  else { sym(0, ny, nc); if (s.nose !== "cat") sym(1, ny, nc); sym(0, ny + 1, s.nose === "big" || s.nose === "dog" ? nc : MOUTH); if (s.nose === "big") { sym(1, ny + 1, nc); sym(2, ny, nc); } sym(1, ny + 3, MOUTH); sym(2, ny + 3, MOUTH);
    if (s.nose === "teeth") { sym(0, ny + 3, [250, 246, 232]); sym(0, ny + 4, [250, 246, 232]); }
    if (s.tongue) { sym(0, ny + 3, PINK); sym(0, ny + 4, PINK); } }
  // okulary, czapka
  if (s.glasses) { const g = [40, 34, 50]; for (let d = e0 - 2; d <= e0 + 3; d++) { sym(d, ey - 2, g); sym(d, ey + eh + 1, g); } for (let y = ey - 1; y <= ey + eh; y++) { sym(e0 - 2, y, g); sym(e0 + 3, y, g); } sym(0, ey, g); sym(1, ey, g); }
  if (s.hat) { const hr = R(3, HATS[s.hat[1]]), cy = Math.round(Y(14.6));
    if (s.hat[0] === "cap") { for (let d = 0; d < 6; d++) for (let y = cy - 3 + (d >= 4 ? 1 : 0) + (d === 5 ? 1 : 0); y <= cy; y++) sym(d, y, y <= cy - 2 ? hr[2] : hr[1]); for (let d = 0; d < 7; d++) sym(d, cy + 1, hr[0]); }
    if (s.hat[0] === "beret") { for (let d = -1; d < 7; d++) for (let y = cy - 2 + (d >= 5 ? 1 : 0); y <= cy; y++) { b.pset(Rr + d, y, y === cy - 2 ? hr[2] : hr[1]); if (d < 5) b.pset(L - d, y, y === cy - 2 ? hr[2] : hr[1]); } b.pset(Rr, cy - 3, hr[0]); }
    if (s.hat[0] === "bow") { for (const [dx, dy] of [[0, 0], [-1, -1], [-1, 0], [-1, 1], [1, -1], [1, 0], [1, 1], [-2, -1], [-2, 1], [2, -1], [2, 1]]) b.pset(Rr + 5 + dx, cy + 1 + dy, dx === 0 ? hr[0] : hr[1]); } }
  return ink(P.rimLight(b, fur, { dir: [0, -1] }));
}

// ================================================================ zapis
const ids = Object.keys(S), sheetP = [], sheetS = [];
for (const id of ids) {
  const p0 = portrait(id, false);
  P.save(P.pack([p0, portrait(id, true)], { cols: 2, pad: 0 }), `${out}/portrait_w_${id}.png`);
  const fr = WAG.map((g) => sprite(id, S[id].tail === "none" ? 0 : g));
  P.save(P.pack(fr, { cols: 4, pad: 0 }), `${out}/worker_${id}.png`);
  sheetP.push({ buf: p0, scale: 2, label: id.toUpperCase() });
  sheetS.push({ buf: fr[0], scale: 3, label: id.toUpperCase() });
}
P.save(P.sheet(sheetP, { cols: 9 }), __dirname + "/_staff_portraits.png");
P.save(P.sheet(sheetS, { cols: 12 }), __dirname + "/_staff_sprites.png");
console.log(ids.length, "pracowników");
