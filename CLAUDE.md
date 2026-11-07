# Star Watcher – zasady projektu

## Teksty w grze
- **Monolog wewnętrzny Jani**: wszystko, co Jania mówi lub myśli (reakcje na przedmioty – plakat, kubek, łóżko itd.),
  pokazuje się **nad jej głową, bez ramki i bez paddingu** – sam tekst z obrysem 1 px (`world.gd: _say()`).
  Nigdy jako powiadomienie ani okienko.
- Powiadomienia (paczki, zakupy, nowy dzień): **na środku ekranu, jedno pod drugim, bez ramek** (`_toast()`).
- Komunikaty w okularze teleskopu: na środku, bez ramki; tylko podpowiedzi samouczka mają ramkę na dole.

## Czcionki (3 kroje, zawsze w rozmiarach z siatką 1:1 – inaczej kreski są nierówne)
- UI: Pixel Operator (CC0) z dorysowanymi polskimi znakami (`tools/fonts/pl.py`) – 16 px (`Game.FS`).
- Komputer (AstroOS): VT323 – 20 px (`Game.OS_FS`); 25 px tam, gdzie tekst ma być idealnie równy.
- Nagłówki: Press Start 2P – 8 / 16 / 24 px (`Game.TITLE_FS`).

## Grafika
- Pixel art generowany kodem (codixel, `tools/art/*.js`); referencje od autora służą do kolorów/kształtu.
- Ramki HUD: cienka stal (`_metal`), przyciski jak klawisze klawiatury (`_key`).

## Dźwięk
- Efekty i pętle tła: `game/sfx/*.ogg` generuje `tools/sfx/make_sfx.py` (bank i dsp earshot, wszystko liczone kodem) –
  zmieniać skrypt, nie pliki. W grze: `Game.sfx()` (jednorazowe), `Game.loop()` (pętle), magistrale Music / SFX /
  Ambient z głośnością w Ustawieniach.
- Muzyka: `music/compose.py` → `game/music/day.ogg` (pokój) i `night.ogg` (balkon), grane przez `Game.loop("music/…")`.
- Odtwarzacze Ogg: w tweenach żadnych lambd łapiących odtwarzacz (trzyma odtwarzanie → wyciek przy wyjściu); wychodzić
  przez `Game.quit()`.
