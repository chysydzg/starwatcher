"""Etap 2: music/day2, music/night2, music/build (pętle) i music/sting_dawn, music/sting_dusk (przerywniki dzień/noc).

Wzorce autora (ref_day2.mp3, ref_night2.mp3, ref_build.mp3, nie trzymamy ich w repo) dają tylko tempo, tryb, gęstość
i role instrumentów; każda nuta jest napisana od nowa, w stylu pętli gry (sample SNES, miękkie bębny 12-bit, taśma, winyl).
Run: python compose_s2.py <path to music-production/scripts>
"""
from compose import Song, spans, vinyl, root_of

# rootless voicings (MIDI), mid register; osobno na utwór, bo ten sam symbol bywa różnie ułożony pod różne melodie
DV = {'G6': [55, 59, 62, 64], 'Em7': [55, 59, 62, 64], 'Cmaj9': [52, 59, 62, 67], 'D7sus4': [55, 57, 60, 62],
      'D7': [54, 57, 60, 62], 'Bm7': [54, 57, 62, 66], 'Am7': [55, 60, 64, 67]}                       # G-dur
NV = {'Am7': [55, 60, 64, 67], 'Fmaj9': [57, 60, 64, 67], 'Cmaj9': [55, 59, 62, 64], 'G6': [52, 55, 59, 62],
      'Dm7': [53, 57, 60, 62], 'E7sus4': [52, 57, 59, 62], 'Em7': [55, 59, 62, 64]}                     # a-moll
BV = {'C6': [52, 55, 57, 60], 'Am7': [55, 60, 64, 67], 'F6': [57, 60, 62, 65], 'G7sus4': [53, 55, 60, 62],
      'G7': [53, 55, 59, 62], 'Em7': [55, 59, 62, 64], 'Fmaj9': [57, 60, 64, 67], 'Dm7': [53, 57, 60, 64],
      'A7': [55, 61, 64, 67]}                                                                            # C-dur
SV = {'G': [55, 59, 62, 67], 'Cadd9': [60, 64, 67, 74]}                                                  # przerywniki
LOFI = {'level_dbfs': -17, 'highpass': 40, 'lowpass': 12000, 'reverb_db': -20,
        'effects': [{'type': 'bitcrush', 'bits': 12, 'downsample': 2, 'mix': 0.55}], 'saturate': 0.2}


def comp(s, prog, fn, V):
    for bar, items in enumerate(prog):
        for b, ln, sym in spans(items):
            fn(bar, bar * 4 + b, ln, sym, V[sym], root_of(sym))


def held(s, track, prog, vel, V, top=None):
    """sustained chords; common tones tie across chord changes (no re-attack)"""
    open_ = {}
    def f(bar, on, ln, sym, v, r):
        for p in v if top is None else v[-top:]:
            h = open_.get(p)
            if h and abs(h['on'] + h['duration'] - on) < 1e-6:
                h['duration'] = round(h['duration'] + ln, 4)
            else:
                s.note(track, on, ln, p, vel)
                h = s.t[track]['notes'][-1]
            open_[p] = h
    comp(s, prog, f, V)


# ---------------------------------------------------------------- DZIEŃ 2: G-dur, 78 BPM, 32 takty (~98 s)
def day2():
    """Wzorzec: kwartet smyczkowy, pizzicato, flet, romantycznie (earshot), e-moll/G-dur, wolny puls ~74 BPM.
    Tu: pizzicato niesie ósemki jak klawisze w pętli dnia, flet śpiewa temat, celesta odpowiada, smyczki pod spodem."""
    A = [[(0, 'G6')], [(0, 'Em7')], [(0, 'Cmaj9')], [(0, 'D7sus4'), (2, 'D7')],
         [(0, 'G6')], [(0, 'Bm7')], [(0, 'Cmaj9')], [(0, 'Am7'), (2, 'D7')]]
    B = [[(0, 'Em7')], [(0, 'Cmaj9')], [(0, 'G6')], [(0, 'Bm7')],
         [(0, 'Em7')], [(0, 'Am7')], [(0, 'Cmaj9')], [(0, 'D7sus4'), (2, 'D7')]]
    C = [[(0, 'Cmaj9')], [(0, 'Bm7')], [(0, 'Am7')], [(0, 'G6')],
         [(0, 'Cmaj9')], [(0, 'Bm7')], [(0, 'Am7')], [(0, 'D7sus4'), (2, 'D7')]]
    prog = A + B + A + C
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'flute theme over pizzicato eighths'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'celesta answers, strings swell, flute rests'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme back, celesta doubles an octave up'},
           {'id': 'c', 'start_bar': 24, 'bars': 8, 'intent': 'breakdown: strings and pizzicato, low flute, a stop-down'}]
    s = Song('Star Watcher - Laboratorium (dzien)', 78, 32, sec,
             'Stage 2 daytime lab loop. Inspired by the user reference only in tempo, mode and instrument roles '
             '(string quartet, pizzicato, flute, celesta); SNES-style samples and lo-fi glue like the day loop.')
    s.chords(prog)
    SW = {'ratio': 0.56, 'unit': 0.25}
    s.track('flute', 'melody', {'level_dbfs': -20, 'highpass': 200, 'lowpass': 11000, 'reverb_db': -13, 'eq': [[3000, 3]],
                                'delay': {'beats': 0.75, 'feedback': 0.28, 'send_db': -16, 'lowpass': 3000, 'ping_pong': True},
                                'pan': 0.1}, program=73)
    s.track('celesta', 'countermelody', {'level_dbfs': -23, 'highpass': 200, 'lowpass': 10000, 'reverb_db': -12,
                                         'pan': -0.45}, program=8)
    s.track('pizz', 'harmony', {'level_dbfs': -24, 'highpass': 140, 'lowpass': 7000, 'reverb_db': -14, 'pan': 0.4},
            program=45)
    s.track('strings', 'texture', {'level_dbfs': -29, 'highpass': 110, 'lowpass': 5000, 'reverb_db': -10, 'pan': -0.2},
            program=48)
    s.track('bass', 'bass', {'level_dbfs': -23, 'highpass': 35, 'lowpass': 1600}, program=32)
    s.track('sub', 'bass', {'level_dbfs': -31, 'highpass': 25, 'lowpass': 300}, engine='synth', synth={'preset': 'sub_bass'})
    s.track('drums', 'drums', dict(LOFI, level_dbfs=-19), drums=True)
    for k in ('bass', 'drums'):
        s.t[k]['performance']['swing'] = SW

    theme = [
        [(0, .5, 74), (.5, .5, 76), (1, 1, 78), (2, .5, 79), (2.5, 1.5, 74)],
        [(0, 1, 71), (1, .5, 74), (1.5, .5, 76), (2, 2, 79)],
        [(0, .5, 79), (.5, .5, 78), (1, 1, 76), (2, 1, 74), (3, 1, 71)],
        [(0, 1.5, 72), (1.5, .5, 74), (2, 2, 69)],
        [(0, .5, 74), (.5, .5, 76), (1, 1, 78), (2, .5, 79), (2.5, .5, 81), (3, 1, 83)],
        [(0, 1.5, 81), (1.5, .5, 78), (2, 2, 74)],
        [(0, .5, 76), (.5, .5, 79), (1, 1, 83), (2, .5, 81), (2.5, 1.5, 79)],
        [(0, 1, 76), (1, 1, 72), (2, 1.5, 74), (3.5, .5, 78)],
    ]
    end2 = [[(0, .5, 76), (.5, .5, 78), (1, 1, 79), (2, 2, 83)], [(0, 2, 81), (2, 1, 78), (3, 1, 74)]]
    answer = [
        [(0, .5, 83), (.5, .5, 79), (1, .5, 76), (1.5, 1.5, 78), (3, 1, 79)],
        [(0, .5, 81), (.5, .5, 79), (1, .5, 76), (1.5, 1.5, 74), (3, 1, 76)],
        [(0, .5, 78), (.5, .5, 79), (1, .5, 81), (1.5, 1.5, 83), (3, 1, 86)],
        [(0, 2, 86), (2, 1, 83), (3, 1, 81)],
        [(0, .5, 79), (.5, .5, 83), (1, 1.5, 86), (2.5, .5, 83), (3, 1, 79)],
        [(0, 1, 84), (1, 1, 83), (2, 1, 81), (3, 1, 79)],
        [(0, 1.5, 79), (1.5, .5, 76), (2, 2, 83)],
        [(0, 2, 81), (2, 1, 78), (3, 1, 74)],
    ]
    low = [[(0, 3, 64), (3, 1, 62)], [(0, 4, 66)], [(0, 2, 64), (2, 2, 67)], [(0, 3, 66), (3, 1, 67)],
           [(0, 3, 67), (3, 1, 69)], [(0, 2, 66), (2, 2, 62)], [(0, 4, 64)], [(0, 2, 67), (2, 2, 69)]]
    for i, c in enumerate(theme):
        s.line('flute', i, c, 78)
    for i, c in enumerate(theme[:6] + end2):
        s.line('flute', 16 + i, c, 82)
        s.line('celesta', 16 + i, [(b, d, p + 12) for b, d, p in c if b in (0, 1, 2)], 58)  # celesta: tylko akcenty na ćwierćnutach
    for i, c in enumerate(answer):
        s.line('celesta', 8 + i, c, 76)
    for i, c in enumerate(low):
        s.line('flute', 24 + i, c, 70)

    held(s, 'strings', prog, 56, DV)

    def under(bar, on, ln, sym, v, r):
        brk = bar >= 24
        tones = sorted(p + 12 if p < 57 else p for p in v)
        if brk:  # breakdown: pizzicato w ćwierćnutach; takt 27: stop-down (dwie ćwierćnuty ciszy)
            for k in range(int(ln)):
                if bar == 27 and on + k - bar * 4 >= 2:
                    continue
                s.note('pizz', on + k, .5, tones[k % len(tones)], 64 - 6 * (k % 2), .6)
        else:
            order = [0, 2, 1, 3, 0, 2, 1, 3]
            for k in range(int(ln / .5)):
                s.note('pizz', on + k * .5, .25, tones[order[k] % len(tones)], 70 if k % 2 == 0 else 56, .55)
        rr = r - 12 if r > 40 else r
        if not (bar == 27):
            line = [(0, 1.5, r), (1.5, .5, r + 7), (2, 1.5, r + 12), (3.5, .5, r + 7)] if ln >= 4 else [(0, 1.5, r), (1.5, .5, r + 7)]
            for b, d, p in line:
                s.note('bass', on + b, d, p, 80 if b == 0 else 64, .85)
            s.note('sub', on, ln - .05, rr, 88)
    comp(s, prog, under, DV)

    for bar in range(32):
        o = bar * 4
        brk = bar >= 24
        if bar == 27:
            s.note('drums', o, .2, 36, 70)
            continue
        if not brk:
            for b, vel in ((0, 80), (2.5, 58)):
                s.note('drums', o + b, .2, 36, vel)
        for b in (1, 3):
            s.note('drums', o + b, .2, 37, 60 if brk else 70)
        for k in range(8):  # marakasy w ósemkach, w a2 dochodzą ciche hi-haty na ćwierćnutach
            s.note('drums', o + k * .5, .1, 70, 44 if k % 2 == 0 else 30)
            if 16 <= bar < 24 and k % 2 == 0:
                s.note('drums', o + k * .5, .1, 42, 40)
        if bar % 8 == 7 and not brk:
            s.note('drums', o + 3.5, .2, 38, 46)
            s.note('drums', o + 3.75, .2, 38, 54)
    vinyl(s, 32)
    s.save('day2')


# ---------------------------------------------------------------- NOC 2: a-moll, 66 BPM, 24 takty (~87 s)
def night2():
    """Wzorzec: rozmarzone pianino elektryczne, szklana harfa, pojedyncze dzwonki, bez stałego pulsu, C-dur/a-moll,
    pod koniec cichy bit lo-fi (earshot). Tu: EP prowadzi rzadki temat, smyczkowy pad szklany, dzwonki na końcach fraz;
    bit wchodzi dopiero w B, a pierwsza część jest bez perkusji (kopuła nocą)."""
    A = [[(0, 'Am7')], [(0, 'Fmaj9')], [(0, 'Cmaj9')], [(0, 'G6')],
         [(0, 'Am7')], [(0, 'Fmaj9')], [(0, 'Dm7')], [(0, 'E7sus4')]]
    B = [[(0, 'Fmaj9')], [(0, 'Em7')], [(0, 'Dm7')], [(0, 'Cmaj9')],
         [(0, 'Fmaj9')], [(0, 'Em7')], [(0, 'Dm7')], [(0, 'E7sus4')]]
    prog = A + B + A
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'electric piano theme over a glassy pad, no drums'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'vibes answer, EP arpeggios, a soft lo-fi beat enters'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme an octave up, bells close the phrases, beat fades out'}]
    s = Song('Star Watcher - Kopula (noc)', 66, 24, sec,
             'Stage 2 night loop in the dome. Inspired by the user reference only in mood, mode and instrument roles '
             '(dreamy electric piano, glass pad, bells); SNES-style samples and lo-fi glue like the night loop.', tail=6)
    s.chords(prog)
    SW = {'ratio': 0.58, 'unit': 0.25}
    s.track('ep', 'melody', {'level_dbfs': -20, 'highpass': 120, 'lowpass': 7000, 'reverb_db': -9, 'space': 'hall',
                             'effects': [{'type': 'chorus', 'depth': 0.6}],
                             'delay': {'beats': 1.5, 'feedback': 0.38, 'send_db': -13, 'lowpass': 2500, 'ping_pong': True},
                             'wow_flutter': {'wow_cents': 9, 'wow_hz': 0.45}}, program=4)
    s.track('vibes', 'countermelody', {'level_dbfs': -23, 'highpass': 200, 'lowpass': 8000, 'reverb_db': -9,
                                       'space': 'hall', 'pan': -0.4}, program=11)
    s.track('bells', 'texture', {'level_dbfs': -29, 'highpass': 500, 'lowpass': 9000, 'reverb_db': -6, 'space': 'hall',
                                 'pan': 0.45}, program=9)
    s.track('arp', 'harmony', {'level_dbfs': -28, 'highpass': 120, 'lowpass': 6000, 'reverb_db': -10, 'pan': 0.3,
                               'effects': [{'type': 'chorus', 'depth': 0.7}]}, program=4)
    s.track('pad', 'texture', {'level_dbfs': -28, 'highpass': 120, 'lowpass': 5000, 'reverb_db': -8, 'pan': -0.25,
                               'effects': [{'type': 'chorus', 'depth': 0.8}]}, program=92)  # GM bowed glass pad
    s.track('sub', 'bass', {'level_dbfs': -22, 'highpass': 25, 'lowpass': 400}, engine='synth', synth={'preset': 'sub_bass'})
    s.track('drums', 'drums', dict(LOFI, level_dbfs=-23, lowpass=9000), drums=True)
    for k in ('arp', 'drums'):
        s.t[k]['performance']['swing'] = SW

    theme = [
        [(0, 1.5, 76), (1.5, .5, 74), (2, 2, 72)],
        [(0, 1, 69), (1, 1, 72), (2, 2, 76)],
        [(0, 1.5, 79), (1.5, .5, 76), (2, 2, 74)],
        [(0, 3, 71), (3, 1, 74)],
        [(0, 1.5, 76), (1.5, .5, 74), (2, 1, 72), (3, 1, 71)],
        [(0, 1, 69), (1, 1, 72), (2, 1, 76), (3, 1, 74)],
        [(0, 2, 76), (2, 1, 74), (3, 1, 72)],
        [(0, 2, 71), (2, 2, 69)],
    ]
    answer = [
        [(1, 1, 81), (2, 2, 79)], [(0, 2, 79), (2, 2, 74)], [(0, 1, 77), (1, 1, 76), (2, 2, 72)], [(0, 4, 76)],
        [(1, 1, 81), (2, 1, 84), (3, 1, 84)], [(0, 2, 79), (2, 2, 76)],
        [(0, 1, 77), (1, 1, 76), (2, 1, 74), (3, 1, 72)], [(0, 4, 71)],
    ]
    for i, c in enumerate(theme):
        s.line('ep', i, c, 70)
        s.line('ep', 16 + i, [(b, d, p + 12) for b, d, p in c], 64)
    for i, c in enumerate(answer):
        s.line('vibes', 8 + i, c, 70)
    for bar, b, p in ((1, 3, 88), (3, 2.5, 86), (5, 3, 88), (7, 2, 83), (19, 3, 91), (21, 2.5, 88), (23, 2, 88)):
        s.note('bells', bar * 4 + b, 2, p, 60)

    held(s, 'pad', prog, 54, NV)

    def under(bar, on, ln, sym, v, r):
        rr = r - 12 if r > 40 else r
        s.note('sub', on, ln - .05, rr, 84)
        if 8 <= bar < 16:  # B: EP w miękkich ósemkach w górę akordu
            tones = sorted(p + 12 for p in v)
            for k in range(8):
                s.note('arp', on + k * .5, .5, tones[k % len(tones)], 56 - 8 * (k % 2), .9)
        else:
            s.note('arp', on, 1.5, v[0], 50, .9)
            for p in v[1:]:
                s.note('arp', on + .02, 1.5, p, 46, .9)
    comp(s, prog, under, NV)

    for bar in range(8, 22):  # cichy bit w B i na początku a2, potem wybrzmiewa
        o = bar * 4
        soft = bar >= 20
        s.note('drums', o, .2, 36, 52 if not soft else 40)
        s.note('drums', o + 2.5, .2, 36, 40)
        for b in (1, 3):
            s.note('drums', o + b, .2, 37, 46 if not soft else 34)
        for k in range(8):
            s.note('drums', o + k * .5, .08, 42, 32 if k % 2 == 0 else 22)
    vinyl(s, 24)
    s.save('night2')


# ---------------------------------------------------------------- REMONT: C-dur, 132 BPM, 24 takty (~44 s)
def build():
    """Wzorzec: fortepian i pianino elektryczne, celesta, „SNES” (z +2,8), od melancholii do nadziei, ~132 BPM, C-dur.
    Tu: skoczny fortepian staccato prowadzi, celesta odpowiada, bas w synkopach, bębny 12-bit z klaskaniem w a2."""
    A = [[(0, 'C6')], [(0, 'Am7')], [(0, 'F6')], [(0, 'G7sus4'), (2, 'G7')],
         [(0, 'C6')], [(0, 'Em7')], [(0, 'Fmaj9')], [(0, 'G7')]]
    B = [[(0, 'Fmaj9')], [(0, 'Em7')], [(0, 'Dm7')], [(0, 'G7')],
         [(0, 'Fmaj9')], [(0, 'Em7'), (2, 'A7')], [(0, 'Dm7')], [(0, 'G7sus4'), (2, 'G7')]]
    prog = A + B + A
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'bouncy staccato piano theme: work starts'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'celesta answers over piano stabs, drums tighten'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme back with celesta and claps: almost done'}]
    s = Song('Star Watcher - Remont', 132, 24, sec,
             'Renovation montage bed under hammer sounds. Inspired by the user reference only in tempo, mode and '
             'instrument roles (piano, electric piano, celesta, hopeful); SNES-style samples and lo-fi glue.')
    s.chords(prog)
    SW = {'ratio': 0.57, 'unit': 0.25}
    s.track('piano', 'melody', {'level_dbfs': -19, 'highpass': 150, 'lowpass': 7000, 'reverb_db': -15, 'pan': 0.05,
                                'delay': {'beats': 0.75, 'feedback': 0.2, 'send_db': -21, 'lowpass': 3500, 'ping_pong': True}},
            program=0)
    s.track('celesta', 'countermelody', {'level_dbfs': -22, 'highpass': 220, 'lowpass': 9000, 'reverb_db': -12,
                                         'pan': -0.4}, program=8)
    s.track('glock', 'texture', {'level_dbfs': -29, 'highpass': 400, 'lowpass': 10000, 'reverb_db': -12, 'pan': 0.35},
            program=9)
    s.track('keys', 'harmony', {'level_dbfs': -28, 'highpass': 100, 'lowpass': 5000, 'reverb_db': -16, 'pan': 0.4,
                                'eq': [[250, -3]], 'effects': [{'type': 'chorus', 'depth': 0.5}]}, program=4)
    s.track('bass', 'bass', {'level_dbfs': -22, 'highpass': 35, 'lowpass': 2000}, program=33)
    s.track('sub', 'bass', {'level_dbfs': -28, 'highpass': 25, 'lowpass': 300}, engine='synth', synth={'preset': 'sub_bass'})
    s.track('drums', 'drums', dict(LOFI), drums=True)
    for k in ('keys', 'bass', 'drums', 'piano', 'celesta'):
        s.t[k]['performance']['swing'] = SW

    theme = [
        [(0, .5, 72), (.5, .5, 76), (1, .5, 79), (2, .5, 81), (2.5, .5, 79), (3, 1, 76)],
        [(0, .5, 72), (.5, .5, 76), (1, 1, 79), (2.5, .5, 76), (3, .5, 74), (3.5, .5, 72)],
        [(0, .5, 74), (.5, .5, 77), (1, .5, 81), (2, .5, 84), (2.5, .5, 81), (3, 1, 77)],
        [(0, 1.5, 79), (1.5, .5, 77), (2, .5, 74), (2.5, .5, 71), (3, 1, 74)],
        [(0, .5, 72), (.5, .5, 76), (1, .5, 79), (2, .5, 81), (2.5, .5, 79), (3, 1, 76)],
        [(0, .5, 71), (.5, .5, 74), (1, 1, 79), (2.5, .5, 83), (3, 1, 81)],
        [(0, .5, 81), (.5, .5, 79), (1, .5, 77), (1.5, .5, 76), (2, 1, 77), (3, 1, 81)],
        [(0, 1, 79), (1, .5, 77), (1.5, .5, 74), (2, 1, 71), (3, 1, 74)],
    ]
    answer = [
        [(0, .5, 84), (.5, .5, 81), (1, 1, 77), (2, .5, 81), (2.5, 1.5, 84)],
        [(0, .5, 83), (.5, .5, 79), (1, 1, 76), (2, 2, 79)],
        [(0, .5, 81), (.5, .5, 77), (1, 1, 74), (2, .5, 77), (2.5, .5, 81), (3, 1, 84)],
        [(0, 2, 83), (2, 1, 79), (3, 1, 77)],
        [(0, .5, 84), (.5, .5, 81), (1, 1, 77), (2, .5, 81), (2.5, 1.5, 84)],
        [(0, 1, 83), (1, 1, 79), (2, 1, 85), (3, 1, 83)],
        [(0, 1, 81), (1, 1, 77), (2, 1, 74), (3, 1, 77)],
        [(0, 2, 79), (2, 1, 77), (3, 1, 74)],
    ]
    for i, c in enumerate(theme):
        for b, d, p in c:
            s.note('piano', i * 4 + b, d, p, 84 if b == 0 else 74, .6)
            s.note('piano', 64 + i * 4 + b, d, p, 88 if b == 0 else 78, .6)
        s.line('celesta', 16 + i, [(b, d, p + 12) for b, d, p in c if b in (0, 1, 2, 3)], 56)
        s.line('glock', 16 + i, [(b, d, p + 12) for b, d, p in c if b == 0], 60)
    for i, c in enumerate(answer):
        s.line('celesta', 8 + i, c, 76)

    def under(bar, on, ln, sym, v, r):
        rr = r - 12 if r > 40 else r
        b_sec = 8 <= bar < 16
        for k in range(int(ln)):  # klawisze na „i”: offbeaty; w B fortepian dokłada krótkie akordy
            for p in v:
                s.note('keys', on + k + .5, .25, p, 54, .7)
                if b_sec and k % 2 == 1:
                    s.note('piano', on + k + .5, .25, p + 12, 58, .5)
        line = [(0, .75, r), (1.5, .5, r + 7), (2, .5, r + 12), (2.5, .5, r + 7), (3.5, .5, r)] if ln >= 4 else \
            [(0, .75, r), (1.5, .5, r + 7)]
        for b, d, p in line:
            s.note('bass', on + b, d, p, 84 if b == 0 else 68, .8)
        s.note('sub', on, ln - .05, rr, 86)
    comp(s, prog, under, BV)

    for bar in range(24):
        o = bar * 4
        for b, vel in ((0, 90), (1.5, 62), (2, 80)):
            s.note('drums', o + b, .2, 36, vel)
        for b in (1, 3):
            s.note('drums', o + b, .2, 38, 78)
            if bar >= 16:
                s.note('drums', o + b, .2, 39, 64)
        for k in range(8):
            s.note('drums', o + k * .5, .1, 42, 62 if k % 2 == 0 else 46)
        if bar % 8 == 7:
            for b, p in ((3, 45), (3.25, 43), (3.5, 41), (3.75, 41)):
                s.note('drums', o + b, .2, p, 72)
    vinyl(s, 24)
    s.save('build')


# ---------------------------------------------------------------- PRZERYWNIKI dzień/noc (one-shot, bez pętli)
def sting(name, title, chord, root, harp, top, sparkle):
    """2 takty 120 BPM: harfa przebiega w górę, celesta i dzwonki kończą jasnym akordem, triangel i miękka stopa."""
    s = Song(title, 120, 2, [{'id': 'a', 'start_bar': 0, 'bars': 2, 'intent': 'bright sting into the next theme'}],
             'One-shot day/night transition sting: cheerful, lifting, ends on a decaying tonic chord.', tail=3)
    del s.p['loop']
    s.p['harmony'] = [{'bar': 1, 'beat': 0, 'symbol': chord}]
    s.track('harp', 'texture', {'level_dbfs': -22, 'highpass': 150, 'lowpass': 10000, 'reverb_db': -10, 'pan': -0.3},
            program=46)
    s.track('celesta', 'melody', {'level_dbfs': -19, 'highpass': 220, 'lowpass': 10000, 'reverb_db': -10, 'pan': 0.2,
                                  'delay': {'beats': 0.75, 'feedback': 0.25, 'send_db': -18, 'lowpass': 4000,
                                            'ping_pong': True}}, program=8)
    s.track('glock', 'texture', {'level_dbfs': -26, 'highpass': 400, 'lowpass': 10000, 'reverb_db': -9, 'pan': 0.4}, program=9)
    s.track('strings', 'texture', {'level_dbfs': -27, 'highpass': 140, 'lowpass': 6000, 'reverb_db': -9}, program=48)
    s.track('pizz', 'bass', {'level_dbfs': -24, 'highpass': 35, 'lowpass': 3000}, program=45)
    s.track('drums', 'drums', dict(LOFI, level_dbfs=-22), drums=True)
    for k, p in enumerate(harp):  # przebieg harfy szesnastkami
        s.note('harp', k * .25, 2.5 - k * .25, p, 60 + 4 * k)
    for b, d, p, vel in top:
        s.note('celesta', b, d, p, vel)
    for b, d, p in sparkle:
        s.note('glock', b, d, p, 72)
    for p in SV[chord]:
        s.note('strings', 2, 3.5, p, 62)
    s.note('pizz', 2, 1.5, root, 84)
    s.note('pizz', 2, 1.5, root + 12, 70)
    s.note('drums', 2, .3, 36, 72)
    s.note('drums', 2, 1, 81, 70)  # triangel
    for k in range(8):
        s.note('drums', k * .25, .1, 70, 24 + 5 * k)  # marakasy rosną do akcentu
    s.save(name)


if __name__ == '__main__':
    day2()
    night2()
    build()
    sting('sting_dawn', 'Star Watcher - Swit', 'G', 43,
          [67, 71, 74, 79, 83, 86],
          [(1.5, .5, 79, 74), (2, 3, 83, 84)], [(1.5, .5, 86), (2, 3, 91)])
    sting('sting_dusk', 'Star Watcher - Zmierzch', 'Cadd9', 36,
          [60, 64, 67, 72, 76, 79],
          [(0, .25, 84, 70), (.25, .25, 83, 66), (.5, .25, 79, 70), (.75, .25, 76, 66),
           (1, .25, 77, 72), (1.25, .25, 81, 76), (1.5, .5, 84, 80), (2, 3, 88, 86)],
          [(2, 3, 91), (2.5, 2.5, 84)])
    sting('sting_win', 'Star Watcher - Wszystko odkryte', 'Cadd9', 36,  # fanfara: wszystko na niebie skatalogowane
          [60, 64, 67, 72, 76, 79, 84, 88],
          [(0, .25, 72, 72), (.25, .25, 76, 74), (.5, .25, 79, 78), (.75, .25, 84, 82),
           (1, .5, 83, 76), (1.5, .5, 86, 84), (2, 3, 88, 92)],
          [(1, .25, 91), (1.5, .25, 95), (2, 3, 96)])
    print('ok')
