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
