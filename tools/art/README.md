# Generator grafiki Star Watcher

Grafika powstaje w kodzie (Node.js + biblioteka `pixel.js` ze skilla codixel).

    set CODIXEL=ścieżka\do\codixel\core\pixel.js
    node jania.js ..\..\game\art
    node room.js ..\..\game\art
    node balcony.js ..\..\game\art
    node props.js ..\..\game\art

- `kit.js` – rampy kolorów, obrys, cienie, światło, obiekty sortowane (`*_layout.json`)
- `room.js` – pokój (tło + meble jako osobne PNG z podstawą i kolizją)
- `balcony.js` – balkon nocą (tło + rekwizyty), teleskop z `scope_ref.png`
- `jania.js` – arkusz Jani 7x3 klatek 36x54
- `props.js` – rekwizyty po zakupach (LCD, plakat, radio, poduszka, termos, paczka)
