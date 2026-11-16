# Muzyka – stan prac

Dwie pętle tła, **inspirowane** (nie kopie) wzorcami od autora (mp3 dołączone w czacie, nie trzymamy ich w repo):
dzień gra w pokoju, noc na balkonie (`game/world.gd: _music_to`, przenikanie 1 s, głośność `MUSIC_DB`).

| | dzień (`music/day`) | noc (`music/night`) |
|---|---|---|
| tempo, tonacja | 92 BPM, D-dur | 60 BPM, e-moll (eolski) |
| pętla | 32 takty, 83,48 s (A–B–A'–C) | 24 takty, 96,00 s (A–B–A') |
| prowadzi | flet, odpowiada wibrafon; w C harfa | pozytywka w dużej sali, w B niski flet |
| pod spodem | EP z „lo-fi” przesunięciem, finger bass + sinus, miękkie bębny 12-bit | pad, EP z chorusem, kontrabas + sinus, rim i ciche hi-haty |

Menu główne (`music/menu`, wzorzec: menu.mp3 od autora): 90 BPM, h-moll, 24 takty (64 s, A–B–A'); okaryna prowadzi,
gęste arpeggio celesty, w powrocie celesta dubluje temat i dochodzi cichy puls chip. Earshot: „uplifting / celebratory”
jak wzorzec („playful / celebratory”), ale ciemniej (1,1 kHz wobec 3,3 kHz) – celowo w stylu pętli dnia i nocy.

Intro (`music/intro`, cutscenka po NOWEJ GRZE, wzorzec: cutscene.mp3 od autora): 64 BPM, g-moll, 16 taktów (60 s, A–B);
w A pozytywka prowadzi temat nad harfą, w B odpowiada miękkie pianino; bez perkusji, cicho pod tekstem (-18 LUFS).
Earshot: „a music box melody”, „sad and melancholic” (z +3,6), jak wzorzec („solo piano”, „sad and melancholic”);
jaśniej od wzorca (761 Hz wobec 467 Hz).

Przeprowadzka (`music/moving`, cutscenka końca Etapu 1, wzorzec: moving_out.mp3 od autora, ~145 BPM, E-dur,
radosne ukulele / funk, pizzicato, marimba, pozytywka): 145 BPM, E-dur, 40 taktów (66 s, A–B–A'–C–A''), pętla.
Marimba prowadzi temat, gitara nylonowa bije jak ukulele, w B odpowiada pizzicato, w A' dzwonki dublują temat i dochodzą
klaskania, w C pozytywka nad perkusją w pół-tempie. Akordy 6/9 zamiast maj7 pod tematem (bez tarcia sekund).
Dźwięki i barwy z tego samego banku co pozostałe pętle, ten sam miks (szyna, taśma, winyl, bębny 12-bit).

## Etap 2 (`compose_s2.py`; wzorce od autora: day2.mp3, night2.mp3, build.mp3, w repo ich nie trzymamy)
| | laboratorium, dzień (`day2`) | kopuła, noc (`night2`) | urządzanie pokoiku (`build`) |
|---|---|---|---|
| tempo, tonacja | 78 BPM, G-dur | 66 BPM, a-moll | 132 BPM, C-dur |
| pętla | 32 takty, 98,5 s (A–B–A'–C) | 24 takty, 87,3 s (A–B–A') | 24 takty, 43,6 s (A–B–A') |
| prowadzi | flet nad ósemkami pizzicato, w B celesta | pianino elektryczne z echem, w B wibrafon, dzwonki na końcach fraz | fortepian staccato, w B celesta, w A' dzwonki i klaskanie |
| wzorzec (earshot) | kwartet, pizzicato, flet, „romantic” | rozmarzone EP, szklana harfa, dzwonki, bez pulsu | fortepian i celesta, „SNES”, od smutku do nadziei |
| odczyt (earshot) | „romantic” z +3,3, „cheerful cozy daytime” z +3,2; CLAP 0,73 do wzorca | „dreamy” z +2,9, „sad and melancholic” z +3,4; CLAP 0,75; ciemniej (514 Hz wobec 778 Hz) | „playful” z +3,8, „work montage” z +3,7; CLAP 0,36 – żwawiej niż wzorzec; autor zatwierdził ten utwór bez zmian |

Przerywniki dzień/noc (`sting_dawn` G-dur, `sting_dusk` C-dur, 120 BPM, 2 takty, ~4 s + wybrzmienie): harfa przebiega w górę,
celesta i dzwonki kończą jasnym akordem toniki, triangel. Earshot: „a bright magical success jingle” z +4,1 / +4,2.
W grze (`world.gd: _sky_anim`): na początku zmierzchu / świtu muzyka cichnie przez 1,2 s, gra przerywnik (`STING_DB`),
a po animacji nieba nowy motyw wchodzi przez 3 s pod przyciskiem KONTYNUUJ. Etap 1 zostaje przy `day` / `night`.
Tryb edycji pokoiku (Tab, `world.gd: _edit_toggle`): motyw pory dnia cichnie, `build` gra w pętli; po wyjściu wraca motyw dnia albo nocy. Cutscenka przeprowadzki (z remontem) gra wciąż `moving`.
Wszystko na -16 LUFS jak pozostałe pętle.

## Jak to powstaje
- `compose.py` (skill music-production) pisze `song.json` – każda nuta jest w skrypcie.
- Render na komputerze autora: `music\render.cmd rN` (FluidSynth + bank MS Basic, `C:\Users\tomas\.music-skill`).
  Wynik: `music/<day|night>/render_rN/loop.ogg` → kopiowany do `game/music/day.ogg` / `night.ogg`.
- Odsłuch maszynowy: earshot (`C:\Users\tomas\.earshot`), `Claude outputs\listen.cmd rN` porównuje z wzorcami.

## Pomiary wzorców (moje skrypty + earshot)
- dzień: ~96 BPM, H-dur, −20,5 LUFS, mało góry (jasność 1,2 kHz), szeroka stereofonia (side/mid −6 dB);
  earshot: pozytywka, pizzicato, „romantic / melancholic”.
- noc: ~58 BPM (116 w połowie), centrum D, −22,8 LUFS, bardzo równa dynamika (LRA 3 LU), mocny dół;
  earshot: „sad and melancholic”, „dreamy and ethereal”, new-age.

## Nikt jeszcze nie słuchał
Liczby earshot to odczyt modeli (CLAP/AST), nie odsłuch. Ocena na ucho należy do autora.
MS Basic (MIT) – przy publikacji dodać jego linię podziękowań z THIRD_PARTY.md skilla.
