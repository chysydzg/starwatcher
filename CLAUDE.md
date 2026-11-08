# Star Watcher – zasady projektu

## Teksty w grze
- **Monolog wewnętrzny Jani**: wszystko, co Jania mówi lub myśli (reakcje na przedmioty – plakat, kubek, łóżko itd.),
  pokazuje się **nad jej głową, bez ramki i bez paddingu** – sam tekst z obrysem 1 px (`world.gd: _say()`).
  Nigdy jako powiadomienie ani okienko.
- Powiadomienia (paczki, zakupy, nowy dzień): **na środku ekranu, jedno pod drugim, bez ramek** (`_toast()`).
- Komunikaty w okularze teleskopu: na środku, bez ramki.

## Dialogi (zawsze w ten sposób, cała gra)
- Okienko dialogu `game/dialogue.gd` (`preload(...).new().play([{"who": "jania", "text": "..."}])`, sygnał `finished`):
  rozmówca **po lewej** (portret 88x88 `game/art/portrait_<kto>.png` w stalowej ramce + tabliczka z imieniem),
  tekst po prawej w ramce `Game.metal`.
- Tekst pojawia się litera po literze z cichym stukaniem przy każdej literze. Spacja / [A]: pierwsze naciśnięcie
  pokazuje cały tekst, następne zmienia okno; gdy tekst już się wypisał, wystarczy jedno. Podpowiedź `[Spacja]`
  (pad: `[A]`) miga w prawym dolnym rogu, gdy tekst jest pełny.
- Portrety: z referencji autora (zdjęcia) przez codixel, `tools/art/portraits.js`.

## Samouczki (zawsze w ten sposób)
- Okienko na kilka stron (`game/tutorial.gd`, `Game.tutorial_once`): na stronie jak najmniej tekstu + obraz albo
  nagranie z gry (`test/rec_tut.gd` → `game/art/tut/*.png`, klatki 320x180), na ostatniej stronie OK. Gra w pauzie.
- Pokazuje się raz (`Game.tips`), potem do obejrzenia w POMOC.TXT na komputerze.
- Teksty krótkie, bez półpauz/myślników (–, —), przyciski zgodne z wejściem: `{confirm}` itp. (mysz albo pad).
- Bez przegadanych opisów: podpisy i komunikaty możliwie krótkie.

## Praca przy limicie użycia
- Gdy zbliża się limit użycia: zapisać pracę, commit + push, i dokończyć następnego dnia.

## Czcionki (3 kroje, zawsze w rozmiarach z siatką 1:1 – inaczej kreski są nierówne)
- UI: Pixel Operator (CC0) z dorysowanymi polskimi znakami (`tools/fonts/pl.py`) – 16 px (`Game.FS`).
- Komputer (AstroOS): VT323 – 20 px (`Game.OS_FS`); 25 px tam, gdzie tekst ma być idealnie równy.
- Nagłówki: Press Start 2P – 8 / 16 / 24 px (`Game.TITLE_FS`).

## Grafika
- Pixel art generowany kodem (codixel, `tools/art/*.js`); referencje od autora służą do kolorów/kształtu.
- Ramki HUD: cienka stal (`_metal`), przyciski jak klawisze klawiatury (`_key`).
- **Symetria i czyste krawędzie (zawsze sprawdzać przed pokazaniem):** obiekty pixel-art są symetryczne lewa–prawa
  (o ile sam przedmiot nie jest asymetryczny), prostokąty mają proste boki i pełny 1 px outline na wszystkich
  czterech krawędziach. Żadnych przypadkowych wcięć, ząbków, „ściętych” rogów ani krzywizn (drzwi, nogi krzeseł,
  doniczki, ramki, przyciski, karty, X). Zaokrąglenie rogu tylko celowe i takie samo w każdym rogu.
  Sprawdzenie: powiększony podgląd każdego sprite'a/przycisku + automatyczny test symetrii i ciągłości outline'u.
- Efekty ekranu (CRT itp.) nie przesuwają pikseli: żadnego zakrzywiania ani próbkowania o ułamek piksela – to gubi
  outline i wygina proste krawędzie. Wolno tylko przyciemniać (linie skanowania, winieta).

## Dźwięk
- **Każda praca z dźwiękiem i muzyką: zawsze skille music-production (komponowanie/render) i earshot (odsłuch,
  porównanie z wzorcem autora, sprawdzenie efektów).** Earshot: `C:\Users\tomas\.earshot`, music: `C:\Users\tomas\.music-skill`.
- Efekty i pętle tła: `game/sfx/*.ogg` generuje `tools/sfx/make_sfx.py` (bank i dsp earshot, wszystko liczone kodem) –
  zmieniać skrypt, nie pliki. W grze: `Game.sfx()` (jednorazowe), `Game.loop()` (pętle), magistrale Music / SFX /
  Ambient z głośnością w Ustawieniach.
- Muzyka: `music/compose.py` → `game/music/day.ogg` (pokój) i `night.ogg` (balkon), grane przez `Game.loop("music/…")`.
- Odtwarzacze Ogg: w tweenach żadnych lambd łapiących odtwarzacz (trzyma odtwarzanie → wyciek przy wyjściu); wychodzić
  przez `Game.quit()`.
