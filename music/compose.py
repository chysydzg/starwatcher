"""Builds music/day/song.json and music/night/song.json (music-production/v1).

Original loops for Star Watcher: SNES-style sampled instruments (dark, low-passed, short echo) with a lo-fi
groove (swung sixteenths, soft drums, tape wobble, vinyl). Inspired by the user's references only in tempo,
mode, density and tonal balance; every note here is written fresh.
Run: python compose.py <path to music-production/scripts>
"""
import json, os, sys

sys.path.insert(0, sys.argv[1] if len(sys.argv) > 1 else os.environ.get('MUSIC_SCRIPTS', ''))
from musiclib import expression  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))

# rootless mid-register voicings (MIDI); bass roots in octave 1-2
VOICE = {
    'Dmaj7': [54, 57, 61, 64], 'F#m7': [52, 57, 61, 64], 'Gmaj7': [55, 59, 62, 69], 'Gmaj9': [59, 62, 66, 69],
    'A7sus4': [55, 59, 62, 64], 'A7': [55, 59, 61, 66], 'Bm7': [50, 54, 57, 62], 'Bm9': [50, 54, 57, 64],
    'Em7': [52, 55, 59, 62], 'Em9': [52, 55, 59, 62], 'F#7': [52, 58, 62], 'B7': [57, 63, 66],
    'A13': [55, 61, 66, 71], 'Cmaj9': [52, 59, 62, 67], 'Am9': [60, 64, 67, 71], 'B7sus4': [57, 64, 66],
    'D69': [54, 59, 64, 69], 'A9': [55, 59, 61, 64], 'A': [57, 61, 64], 'F#7sus4': [52, 59, 61], 'F#m7b5': [52, 57, 60],
    # g-moll (intro)
    'Gm9': [58, 62, 65, 69], 'Ebmaj7': [55, 58, 63, 67], 'Bbmaj7': [57, 62, 65, 69], 'Bbmaj7/D': [57, 62, 65, 69],
    'F': [57, 60, 65], 'Fsus4': [58, 60, 65], 'Gm7': [58, 62, 65, 67], 'Cm9': [51, 55, 58, 62], 'Cm7': [51, 55, 58, 63],
    'D7sus4': [55, 57, 60, 62], 'D7': [54, 57, 60, 62],
    # E-dur (przeprowadzka)
    'E6': [56, 59, 61, 66], 'C#m7': [52, 56, 59, 61], 'A6': [61, 64, 66, 71], 'B7sus4': [54, 57, 59, 64],
    'B7': [57, 61, 63, 66], 'G#m7': [54, 56, 59, 63], 'F#m7': [52, 57, 61, 64], 'E6/G#': [56, 59, 61, 66],
}
ROOT = {'D': 38, 'E': 40, 'F#': 42, 'G': 43, 'A': 45, 'B': 35, 'C': 36, 'Eb': 39, 'Bb': 34, 'F': 41, 'C#': 37, 'G#': 44}


def root_of(sym):
    if '/' in sym:
        return ROOT[sym.split('/')[1]]
    return ROOT[sym[:2]] if sym[:2] in ROOT else ROOT[sym[0]]


class Song:
    def __init__(self, title, bpm, bars, sections, brief, tail=4):
        self.p = {'schema': 'music-production/v1', 'title': title, 'version': '1.0.r1', 'brief': brief,
                  'clock': {'bars': bars, 'meter': [4, 4], 'tempo': [[0, bpm]], 'tail_seconds': tail},
                  'sections': sections, 'tracks': [], 'harmony': [], 'loop': {'start_bar': 0},
                  'mix': {'chain': 'bus', 'target_lufs': -16, 'dynamics': 'glue',
                          'wow_flutter': {'wow_cents': 4, 'wow_hz': 0.5, 'flutter_cents': 1, 'flutter_hz': 7}}}
        self.t = {}

    def track(self, ident, role, mix, program=0, engine='soundfont', drums=False, **extra):
        t = {'id': ident, 'name': ident, 'role': role, 'engine': engine, 'drums': drums, 'program': program,
             'bank': 0, 'range': [0, 127], 'notes': [], 'performance': {'notes': {}, 'cc': []},
             'mix': dict({'level_mode': 'peak' if drums else 'active_rms', 'pan': 0, 'eq': [],
                          'automation': [], 'reverb_db': None, 'delay_db': None}, **mix)}
        t.update(extra)
        self.p['tracks'].append(t)
        self.t[ident] = t
        return t

    def note(self, ident, on, dur, pitch, vel, gate=1.0):
        t = self.t[ident]
        nid = f'{ident}_{len(t["notes"]):04d}'
        t['notes'].append({'id': nid, 'on': round(on, 4), 'duration': round(dur, 4), 'pitch': pitch})
        t['performance']['notes'][nid] = {'velocity': vel, 'timing_ms': 0, 'gate': gate}

    def line(self, ident, bar, cells, vel=80):
        for b, d, p in cells:
            self.note(ident, bar * 4 + b, d, p, vel + (6 if b == 0 else 0))

    def chords(self, prog):
        """prog: list of bars, each a list of (beat, symbol)."""
        for bar, items in enumerate(prog):
            for beat, sym in items:
                self.p['harmony'].append({'bar': bar + 1, 'beat': beat, 'symbol': sym.replace('D69', 'D6')})

    def save(self, sub):
        expression.apply(self.p, {'vinyl': None, 'pad': None}, seed=7)
        d = os.path.join(HERE, sub)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, 'song.json'), 'w', encoding='utf-8') as f:
            json.dump(self.p, f, indent=1)


def spans(items):
    """[(beat, sym)] in one bar -> [(start, length, sym)]"""
    out = []
    for k, (b, s) in enumerate(items):
        end = items[k + 1][0] if k + 1 < len(items) else 4
        out.append((b, end - b, s))
    return out


def vinyl(s, bars):
    s.track('vinyl', 'effect', {'level_dbfs': -44, 'level_mode': 'peak', 'highpass': 300, 'lowpass': 6000},
            engine='noise')
    s.t['vinyl']['notes'].append({'id': 'vinyl_0000', 'on': 0, 'duration': bars * 4, 'pitch': 60,
                                  'articulation': 'vinyl'})
    s.t['vinyl']['performance']['notes']['vinyl_0000'] = {'velocity': 70, 'timing_ms': 0, 'gate': 1}


# ---------------------------------------------------------------- DAY: D major, 92 BPM, 32 bars (~83 s)
def day():
    A = [[(0, 'Dmaj7')], [(0, 'F#m7')], [(0, 'Gmaj7')], [(0, 'A7sus4'), (2, 'A7')],
         [(0, 'Bm7')], [(0, 'F#m7')], [(0, 'Em9')], [(0, 'A9')]]
    B = [[(0, 'Gmaj7')], [(0, 'F#m7')], [(0, 'Em7')], [(0, 'A7')],
         [(0, 'Gmaj7')], [(0, 'F#m7'), (2, 'B7')], [(0, 'Em9')], [(0, 'A7sus4'), (2, 'A7')]]
    C = [[(0, 'Bm9')], [(0, 'Gmaj9')], [(0, 'Em9')], [(0, 'F#7')],
         [(0, 'Bm9')], [(0, 'Gmaj7')], [(0, 'Em7')], [(0, 'A7sus4'), (2, 'A7')]]
    prog = A + B + A + C
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'flute theme over I-iii-IV-V'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'vibes answer, flute rests'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme returns, vibes double an octave down'},
           {'id': 'c', 'start_bar': 24, 'bars': 8, 'intent': 'breakdown: harp arpeggios, low flute, light drums'}]
    s = Song('Star Watcher - Dzien', 92, 32, sec,
             'Daytime room loop. SNES-style samples, lo-fi groove, chill. Foreground: flute; vibes answer.')
    s.chords(prog)
    SW = {'ratio': 0.57, 'unit': 0.25}
    s.track('flute', 'melody', {'level_dbfs': -20, 'highpass': 200, 'lowpass': 12000, 'reverb_db': -14,
                                'eq': [[3000, 4]],
                                'delay': {'beats': 0.75, 'feedback': 0.3, 'send_db': -15, 'lowpass': 3000,
                                          'ping_pong': True},
                                'pan': 0.1}, program=73,
            performance_extra=None)
    s.track('vibes', 'countermelody', {'level_dbfs': -22, 'highpass': 180, 'lowpass': 12000, 'reverb_db': -13,
                                       'eq': [[3500, 3]], 'pan': -0.5}, program=11)
    s.track('keys', 'harmony', {'level_dbfs': -26, 'highpass': 100, 'lowpass': 7000, 'reverb_db': -16,
                                'eq': [[250, -3]], 'effects': [{'type': 'chorus', 'depth': 0.6}],
                                'pan': 0.45, 'wow_flutter': {'wow_cents': 9, 'wow_hz': 0.6}}, program=4)
    s.track('harp', 'texture', {'level_dbfs': -26, 'highpass': 150, 'lowpass': 10000, 'reverb_db': -12,
                                'pan': -0.6}, program=46)
    s.track('bass', 'bass', {'level_dbfs': -22, 'highpass': 35, 'lowpass': 1800}, program=33)
    # MS Basic's finger bass has little fundamental: a sine an octave down carries the low end (ref: 25% < 120 Hz)
    s.track('sub', 'bass', {'level_dbfs': -31, 'highpass': 25, 'lowpass': 300}, engine='synth',
            synth={'preset': 'sub_bass'})
    s.track('drums', 'drums', {'level_dbfs': -17, 'highpass': 40, 'lowpass': 14000, 'reverb_db': -20,
                               'effects': [{'type': 'bitcrush', 'bits': 12, 'downsample': 2, 'mix': 0.6}],
                               'saturate': 0.2}, drums=True)
    for k in ('flute', 'vibes', 'keys', 'harp', 'bass', 'drums'):
        s.t[k].pop('performance_extra', None)
        if k in ('keys', 'bass', 'drums', 'harp'):
            s.t[k]['performance']['swing'] = SW
    s.t['keys']['mix']['duck'] = {'by': 'drums', 'keys': [36], 'depth_db': 3, 'attack_ms': 5, 'hold_ms': 30,
                                  'release_ms': 180}

    theme = [
        [(1, .5, 78), (1.5, .5, 81), (2, 1.5, 85), (3.5, .5, 83)],
        [(0, 1, 81), (1, .75, 78), (1.75, 1.25, 76), (3, 1, 73)],
        [(.5, .5, 74), (1, .5, 78), (1.5, .5, 81), (2, 2, 83)],
        [(0, .75, 81), (.75, .75, 79), (1.5, .5, 76), (2, 2, 73)],
        [(1, .5, 78), (1.5, .5, 81), (2, 1, 86), (3, 1, 85)],
        [(0, 1.5, 81), (1.5, .5, 78), (2, 2, 76)],
        [(0, .5, 79), (.5, .5, 78), (1, 1, 76), (2, .5, 74), (2.5, 1.5, 78)],
        [(0, 1, 79), (1, 1, 76), (2, 2, 73)],
    ]
    theme2_end = [[(0, .5, 79), (.5, .5, 81), (1, 1, 83), (2, .5, 81), (2.5, 1.5, 78)],
                  [(0, 1.5, 76), (1.5, .5, 79), (2, 2, 73)]]
    answer = [
        [(0, .5, 71), (.5, .5, 74), (1, .5, 78), (1.5, 1, 79), (2.75, .25, 78), (3, 1, 74)],
        [(0, .5, 73), (.5, .5, 76), (1, .5, 81), (1.5, 1.5, 78), (3, 1, 76)],
        [(0, .5, 71), (.5, .5, 74), (1, .5, 78), (1.5, 1, 79), (2.75, .25, 78), (3, 1, 76)],
        [(0, 1, 73), (1, .5, 76), (1.5, .5, 79), (2, 2, 78)],
        [(0, .5, 83), (.5, .5, 81), (1, .5, 78), (1.5, 1.5, 79), (3, 1, 74)],
        [(0, 1, 81), (1, 1, 76), (2, 1, 75), (3, 1, 78)],
        [(0, .5, 79), (.5, .5, 78), (1, 1, 76), (2, 1, 71), (3, 1, 74)],
        [(0, 2, 76), (2, .5, 74), (2.5, .5, 76), (3, 1, 73)],
    ]
    low = [
        [(0, 3, 73), (3, 1, 74)], [(0, 3, 78), (3, .5, 76), (3.5, .5, 74)], [(0, 2, 71), (2, 2, 78)],
        [(0, 2, 76), (2, 2, 70)], [(0, 3, 71), (3, 1, 73)], [(0, 2, 74), (2, 2, 78)],
        [(0, 2, 79), (2, 1, 76), (3, 1, 74)], [(0, 2, 74), (2, 1.5, 73), (3.5, .5, 76)],
    ]
    for i, cells in enumerate(theme):
        s.line('flute', i, cells, 78)
    for i, cells in enumerate(theme[:6] + theme2_end):
        s.line('flute', 16 + i, cells, 82)
        s.line('vibes', 16 + i, [(b, d, p - 12) for b, d, p in cells], 64)
    for i, cells in enumerate(answer):
        s.line('vibes', 8 + i, cells, 80)
    for i, cells in enumerate(low):
        s.line('flute', 24 + i, [(b, d, p - 12 if p > 74 else p) for b, d, p in cells], 72)

    for bar, items in enumerate(prog):
        sec_c = bar >= 24
        for b, ln, sym in spans(items):
            v = VOICE[sym]
            on = bar * 4 + b
            if sec_c:  # breakdown: one soft held chord per span
                for p in v:
                    s.note('keys', on, ln, p, 52, 0.95)
            else:  # lo-fi comp: hit, then a pushed re-strike on the "and"
                for p in v:
                    s.note('keys', on, min(1.5, ln), p, 66, 0.9)
                if ln >= 4:
                    for p in v[1:]:
                        s.note('keys', on + 2.5, 1.25, p, 54, 0.85)
            r = root_of(sym)
            if ln >= 4:
                bl = [(0, 1.5, r), (1.75, .25, r + 12), (2.5, 1, r + 7), (3.5, .5, r + (5 if bar % 2 else 10))]
            else:
                bl = [(0, 1.5, r), (1.5, .5, r + 7)]
            for bb, d, p in bl:
                s.note('bass', on + bb, d, p, 82 if bb == 0 else 66, 0.9)
            s.note('sub', on, ln - .05, r - 12 if r > 40 else r, 90)
            if sec_c:  # harp: swung sixteenth arpeggio up two octaves
                tones = sorted(set(v + [x + 12 for x in v]))
                steps = int(ln / .5)
                for k in range(steps):
                    s.note('harp', on + k * .5, min(.75, ln - k * .5), tones[k % len(tones)] + 12, 70 - 6 * (k % 2), 1.0)

    for bar in range(32):
        o = bar * 4
        light = 24 <= bar < 28
        if not light:
            for b, vel in ((0, 92), (1.75, 60), (2.5, 84)):
                s.note('drums', o + b, .2, 36, vel)
        for b in (1, 3):
            s.note('drums', o + b, .2, 37 if bar >= 24 else 38, 70 if bar >= 24 else 84)
        for k in range(8):
            s.note('drums', o + k * .5, .1, 42, 68 if k % 2 == 0 else 52)
        if bar % 4 == 3:
            s.note('drums', o + 3.75, .1, 38, 40)
        if bar == 31:
            for b, p in ((3, 45), (3.5, 43)):
                s.note('drums', o + b, .3, p, 70)
    vinyl(s, 32)
    s.save('day')


# ---------------------------------------------------------------- NIGHT: E aeolian, 60 BPM, 24 bars (~96 s)
def night():
    A = [[(0, 'Em9')], [(0, 'Cmaj9')], [(0, 'Em9')], [(0, 'Cmaj9')],
         [(0, 'Am9')], [(0, 'Bm7')], [(0, 'Cmaj9')], [(0, 'B7sus4'), (2, 'B7')]]
    B = [[(0, 'Cmaj9')], [(0, 'D69')], [(0, 'Bm7')], [(0, 'Em9')],
         [(0, 'Cmaj9')], [(0, 'D69')], [(0, 'F#m7b5')], [(0, 'B7sus4'), (2, 'B7')]]
    prog = A + B + A[:7] + [[(0, 'Bm7'), (2, 'B7')]]  # D before the seam: Em9 follows
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'music box stars over Em9-A13'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'low flute, drums thin, no kick'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'music box returns higher, V leads back to i'}]
    s = Song('Star Watcher - Noc', 60, 24, sec,
             'Night balcony loop. SNES-style samples, deep warm bass, sparse music box in a wide hall, dreamy and melancholic.',
             tail=8)  # hall + long echo need the longer tail
    s.chords(prog)
    SW = {'ratio': 0.58, 'unit': 0.25}
    s.track('musicbox', 'melody', {'level_dbfs': -22, 'highpass': 300, 'lowpass': 6000, 'reverb_db': -8,
                                   'space': 'hall',
                                   'delay': {'beats': 1.5, 'feedback': 0.4, 'send_db': -12, 'lowpass': 2500,
                                             'ping_pong': True},
                                   'pan': 0.15}, program=10)
    s.track('flute', 'melody', {'level_dbfs': -21, 'highpass': 180, 'lowpass': 5000, 'reverb_db': -10,
                                'space': 'hall', 'pan': -0.2}, program=73)
    s.track('keys', 'harmony', {'level_dbfs': -26, 'highpass': 100, 'lowpass': 6000, 'reverb_db': -12,
                                'effects': [{'type': 'chorus', 'depth': 0.7}], 'pan': -0.4, 'wow_flutter': {'wow_cents': 10, 'wow_hz': 0.45}}, program=4)
    s.track('pad', 'texture', {'level_dbfs': -27, 'highpass': 120, 'lowpass': 5000, 'reverb_db': -8, 'pan': 0.35,
                               'effects': [{'type': 'chorus', 'depth': 0.8}]},
            program=89)  # GM warm pad: a sampled pad, as a SNES pad would be
    s.track('sub', 'bass', {'level_dbfs': -20, 'highpass': 25, 'lowpass': 400}, engine='synth',
            synth={'preset': 'sub_bass'})
    s.track('bass', 'bass', {'level_dbfs': -26, 'highpass': 50, 'lowpass': 1200}, program=32)
    s.track('drums', 'drums', {'level_dbfs': -20, 'highpass': 40, 'lowpass': 10000, 'reverb_db': -20,
                               'effects': [{'type': 'bitcrush', 'bits': 12, 'downsample': 2, 'mix': 0.6}]},
            drums=True)
    for k in ('keys', 'drums', 'bass'):
        s.t[k]['performance']['swing'] = SW

    mb = [
        [(0, .5, 83), (.5, .5, 78), (1, 1.5, 79), (3, .5, 81), (3.5, .5, 83)],
        [(0, 2, 86), (2, .5, 83), (2.5, 1.5, 78)],
        [(0, .5, 83), (.5, .5, 78), (1, 1, 79), (2, .5, 74), (2.5, 1.5, 76)],
        [(0, 2.5, 78), (3, .5, 76), (3.5, .5, 78)],
        [(0, 1.5, 79), (1.5, .5, 83), (2, 2, 86)],
        [(0, 1, 86), (1, 1, 83), (2, 2, 78)],
        [(0, .5, 76), (.5, .5, 79), (1, 1.5, 83), (2.5, .5, 81), (3, 1, 79)],
        [(0, 2, 76), (2, 1, 75), (3, 1, 78)],
    ]
    mb2_end = [[(0, .5, 88), (.5, .5, 86), (1, 1, 83), (2, 2, 79)], [(0, 2, 78), (2, 1, 75), (3, 1, 71)]]
    fl = [
        [(0, 1.5, 67), (1.5, .5, 71), (2, 2, 74)], [(0, 1, 76), (1, 1, 74), (2, 2, 71)],
        [(0, 1.5, 69), (1.5, .5, 71), (2, 2, 66)], [(0, 3, 67), (3, 1, 71)],
        [(0, 1.5, 74), (1.5, .5, 76), (2, 2, 79)], [(0, 1, 78), (1, 1, 76), (2, 2, 74)],
        [(0, 1.5, 72), (1.5, .5, 69), (2, 2, 64)], [(0, 2, 64), (2, 2, 63)],
    ]
    for i, cells in enumerate(mb):
        s.line('musicbox', i, cells, 74)
    for i, cells in enumerate(mb[:6] + mb2_end):
        s.line('musicbox', 16 + i, [(b, d, p + (12 if i in (0, 1) else 0)) for b, d, p in cells], 70)
    for i, cells in enumerate(fl):
        s.line('flute', 8 + i, cells, 70)

    pad_open = {}
    for bar, items in enumerate(prog):
        for b, ln, sym in spans(items):
            v = VOICE[sym]
            on = bar * 4 + b
            for p in v:
                held = pad_open.get(p)
                if held and abs(held['on'] + held['duration'] - on) < 1e-6:
                    held['duration'] = round(held['duration'] + ln, 4)  # tie the common tone
                else:
                    s.note('pad', on, ln, p, 60)
                    held = s.t['pad']['notes'][-1]
                pad_open[p] = held
                s.note('keys', on, min(1.75, ln), p, 58, 0.9)
            r = root_of(sym) - 12 if root_of(sym) > 40 else root_of(sym)
            s.note('sub', on, ln - .05, r, 90)
            bl = [(0, 2.5, r + 12), (3, .5, r + 19), (3.5, .5, r + 12)] if ln >= 4 else [(0, 1.75, r + 12)]
            for bb, d, p in bl:
                s.note('bass', on + bb, d, p, 72 if bb == 0 else 58, 0.9)

    for bar in range(24):
        o = bar * 4
        thin = 8 <= bar < 16
        if not thin:
            for b, vel in ((0, 74), (2.5, 60)):
                s.note('drums', o + b, .2, 36, vel)
        for b in (1, 3):
            s.note('drums', o + b, .2, 37, 56)
        for k in range(8):  # soft eighth hats; the B section keeps only the quarters
            if thin and k % 2:
                continue
            s.note('drums', o + k * .5, .08, 42, 38 if k % 2 == 0 else 28)
        if bar % 8 == 7:
            s.note('drums', o + 3.5, .4, 46, 44)
    vinyl(s, 24)
    s.save('night')


# ---------------------------------------------------------------- MENU: h-moll, 90 BPM, 24 takty (64 s)
def menu():
    A = [[(0, 'Bm7')], [(0, 'Gmaj7')], [(0, 'Dmaj7')], [(0, 'A7sus4'), (2, 'A')],
         [(0, 'Bm7')], [(0, 'Gmaj7')], [(0, 'Dmaj7')], [(0, 'A')]]
    B = [[(0, 'Em9')], [(0, 'F#7sus4'), (2, 'F#7')], [(0, 'Bm7')], [(0, 'Gmaj7')],
         [(0, 'Em9')], [(0, 'F#7')], [(0, 'Gmaj7')], [(0, 'A')]]
    prog = A + B + A[:7] + [[(0, 'A'), (2, 'A13')]]  # B w ostatnim takcie: Bm7 po szwie nie jest obcy
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'title theme on ocarina over a busy celesta arpeggio'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'answer: longer notes, minor iv and V'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme returns, celesta doubles it, chip arpeggio joins'}]
    s = Song('Star Watcher - Menu', 90, 24, sec,
             'Title screen loop. SNES-style samples like the day/night loops, livelier and brighter: '
             'ocarina lead, dense celesta arpeggios, a quiet chip pulse in the return.')
    s.chords(prog)
    SW = {'ratio': 0.56, 'unit': 0.25}
    s.track('lead', 'melody', {'level_dbfs': -19, 'highpass': 220, 'lowpass': 9000, 'reverb_db': -14, 'eq': [[3000, 2]],
                               'delay': {'beats': 0.75, 'feedback': 0.3, 'send_db': -16, 'lowpass': 3500, 'ping_pong': True}},
            program=79)
    s.track('celesta', 'texture', {'level_dbfs': -25, 'highpass': 140, 'lowpass': 9000, 'reverb_db': -12, 'pan': -0.35},
            program=8)
    s.track('keys', 'harmony', {'level_dbfs': -27, 'highpass': 100, 'lowpass': 6000, 'reverb_db': -16, 'pan': 0.35,
                                'eq': [[250, -3]], 'effects': [{'type': 'chorus', 'depth': 0.5}]}, program=4)
    s.track('strings', 'texture', {'level_dbfs': -31, 'highpass': 150, 'lowpass': 5000, 'reverb_db': -10, 'pan': 0.15},
            program=48)
    s.track('bass', 'bass', {'level_dbfs': -21, 'highpass': 35, 'lowpass': 2000}, program=33)
    s.track('sub', 'bass', {'level_dbfs': -29, 'highpass': 25, 'lowpass': 300}, engine='synth', synth={'preset': 'sub_bass'})
    s.track('chip', 'texture', {'level_dbfs': -32, 'highpass': 300, 'lowpass': 7000, 'pan': 0.3}, engine='synth',
            synth={'preset': 'chip_pulse25'})
    s.track('drums', 'drums', {'level_dbfs': -17, 'highpass': 40, 'lowpass': 14000, 'reverb_db': -20,
                               'effects': [{'type': 'bitcrush', 'bits': 12, 'downsample': 2, 'mix': 0.5}], 'saturate': 0.2},
            drums=True)
    for k in ('keys', 'bass', 'drums', 'celesta', 'chip'):
        s.t[k]['performance']['swing'] = SW
    theme = [
        [(0, .5, 78), (.5, .5, 81), (1, 1, 83), (2, .5, 81), (2.5, .5, 78), (3, 1, 74)],
        [(0, .75, 83), (.75, .75, 81), (1.5, .5, 79), (2, 2, 78)],
        [(0, .5, 76), (.5, .5, 78), (1, 1, 81), (2, .5, 85), (2.5, 1.5, 86)],
        [(0, 1, 86), (1, 1, 81), (2, 2, 76)],
        [(0, .5, 78), (.5, .5, 81), (1, 1, 83), (2, .5, 86), (2.5, .5, 85), (3, 1, 83)],
        [(0, .75, 86), (.75, .75, 83), (1.5, .5, 79), (2, 2, 83)],
        [(0, .5, 81), (.5, .5, 78), (1, .5, 76), (1.5, .5, 74), (2, 1, 73), (3, 1, 76)],
        [(0, 3, 73), (3, .5, 76), (3.5, .5, 78)],
    ]
    answer = [
        [(0, 1.5, 79), (1.5, .5, 78), (2, 2, 76)], [(0, 2, 83), (2, 2, 82)], [(0, 1, 81), (1, 1, 78), (2, 2, 74)],
        [(0, 1.5, 79), (1.5, .5, 81), (2, 2, 83)], [(0, 1, 86), (1, 1, 83), (2, 1, 79), (3, 1, 78)],
        [(0, 2, 82), (2, 1, 78), (3, 1, 73)], [(0, 1.5, 74), (1.5, .5, 76), (2, 2, 78)], [(0, 2, 76), (2, 1, 73), (3, 1, 69)],
    ]
    for i, cells in enumerate(theme):
        s.line('lead', i, cells, 80)
        s.line('lead', 16 + i, cells, 84)
        s.line('celesta', 16 + i, [(b, min(d, 1.0), p + 12) for b, d, p in cells], 56)
    for i, cells in enumerate(answer):
        s.line('lead', 8 + i, cells, 76)
    for bar, items in enumerate(prog):
        for b, ln, sym in spans(items):
            v = VOICE[sym]
            on = bar * 4 + b
            for p in v:
                s.note('keys', on, min(1.5, ln), p, 60, 0.9)
                s.note('strings', on, ln, p, 50)
            tones = sorted(set(v + [x + 12 for x in v]))
            seq = tones + tones[-2:0:-1]  # w górę i w dół: gęste, „tytułowe” szesnastki
            for k in range(int(ln / .25)):
                if bar < 16 or k % 2:  # w powrocie celesta gra temat, arpeggio zostaje rzadsze
                    s.note('celesta', on + k * .25, .25, seq[k % len(seq)] + 12, 58 - 8 * (k % 2), 0.9)
                if bar >= 16 and k % 2 == 0:
                    s.note('chip', on + k * .25, .2, seq[k % len(seq)], 70, 0.8)
            r = root_of(sym)
            for k in range(int(ln / .5)):  # bas ósemkami: pęd, ale miękko
                s.note('bass', on + k * .5, .45, r + (12 if k % 4 == 2 else 0), 82 if k % 2 == 0 else 64, 0.85)
            s.note('sub', on, ln - .05, r - 12 if r > 40 else r, 90)
    for bar in range(24):
        o = bar * 4
        for b, vel in ((0, 92), (1.5, 64), (2.5, 84)):
            s.note('drums', o + b, .2, 36, vel)
        for b in (1, 3):
            s.note('drums', o + b, .2, 38, 86)
        for k in range(16):
            s.note('drums', o + k * .25, .08, 42, 62 if k % 4 == 0 else (48 if k % 2 == 0 else 36))
        if bar % 8 == 7:
            for b, p in ((3, 45), (3.25, 43), (3.5, 41), (3.75, 41)):
                s.note('drums', o + b, .2, p, 72)
    vinyl(s, 24)
    s.p['tracks'][-1]['mix']['level_dbfs'] = -48  # ledwie słyszalne trzaski: menu ma być czystsze
    s.save('menu')


# ---------------------------------------------------------------- INTRO (cutscenka): g-moll, 64 BPM, 16 taktów (60 s)
def intro():
    A = [[(0, 'Gm9')], [(0, 'Ebmaj7')], [(0, 'Bbmaj7')], [(0, 'Fsus4'), (2, 'F')],
         [(0, 'Gm7')], [(0, 'Ebmaj7')], [(0, 'Cm9')], [(0, 'D7sus4'), (2, 'D7')]]
    B = [[(0, 'Ebmaj7')], [(0, 'Bbmaj7/D')], [(0, 'Cm7')], [(0, 'Gm7')],
         [(0, 'Ebmaj7')], [(0, 'F')], [(0, 'Cm9')], [(0, 'D7sus4'), (2, 'D7')]]
    prog = A + B
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'memory: music box theme over harp, father and daughter under the stars'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'answer on soft piano, harp opens up, back to the theme'}]
    s = Song('Star Watcher - Intro', 64, 16, sec,
             'Cutscene bed under dialogue (text, no voices): slow, soft, steady. Inspired by the user reference '
             '(solo piano / harp / music box, melancholic, G minor, ~64 BPM) only in mode, tempo and colour.')
    s.p['mix']['target_lufs'] = -18
    s.chords(prog)
    s.track('box', 'melody', {'level_dbfs': -20, 'highpass': 300, 'lowpass': 6000, 'reverb_db': -10, 'pan': -0.15,
                              'delay': {'beats': 0.75, 'feedback': 0.25, 'send_db': -18, 'lowpass': 3000, 'ping_pong': True}},
            program=10)
    s.track('piano', 'melody', {'level_dbfs': -19, 'highpass': 90, 'lowpass': 5000, 'reverb_db': -11, 'pan': 0.1}, program=0)
    s.track('harp', 'texture', {'level_dbfs': -27, 'highpass': 90, 'lowpass': 6000, 'reverb_db': -10, 'pan': 0.5}, program=46)
    s.track('pad', 'texture', {'level_dbfs': -31, 'highpass': 110, 'lowpass': 3500, 'reverb_db': -8, 'pan': -0.45}, program=48)
    s.track('bass', 'bass', {'level_dbfs': -25, 'highpass': 35, 'lowpass': 1200}, program=32)
    A_mel = [
        [(0, 1, 74), (1, 1, 70), (2, 1.5, 72), (3.5, .5, 74)], [(0, 3, 67), (3, 1, 70)],
        [(0, 1, 69), (1, 1, 70), (2, 1, 74), (3, 1, 77)], [(0, 3, 72), (3, 1, 69)],
        [(0, 1, 74), (1, 1, 70), (2, 1, 72), (3, 1, 74)], [(0, 1.5, 75), (1.5, .5, 74), (2, 2, 70)],
        [(0, 1, 72), (1, 1, 74), (2, 2, 75)], [(0, 2, 74), (2, 2, 66)],
    ]
    B_mel = [
        [(0, 2, 67), (2, 1, 70), (3, 1, 74)], [(0, 3, 77), (3, 1, 74)], [(0, 2, 75), (2, 1, 74), (3, 1, 72)], [(0, 4, 70)],
        [(0, 1, 67), (1, 1, 70), (2, 1, 74), (3, 1, 79)], [(0, 2, 77), (2, 2, 72)],
        [(0, 1, 75), (1, 1, 74), (2, 1, 72), (3, 1, 70)], [(0, 2, 69), (2, 2, 66)],
    ]
    for i, cells in enumerate(A_mel):
        s.line('box', i, [(b, d, p + 12) for b, d, p in cells], 66)
    for i, cells in enumerate(B_mel):
        s.line('piano', 8 + i, cells, 62)
    for bar, items in enumerate(prog):
        for b, ln, sym in spans(items):
            v = VOICE[sym]
            on = bar * 4 + b
            for p in v:
                s.note('pad', on, ln, p, 46)
            r = root_of(sym)
            arp = [r + 12] + v + [v[1] + 12]
            for k in range(int(ln / .5)):  # harfa ósemkami w górę; w B gęściej i głośniej
                if bar >= 8 or k % 2 == 0:
                    s.note('harp', on + k * .5, min(1.0, 64 - on - k * .5), arp[k % len(arp)], (48 if bar >= 8 else 46) - 6 * (k % 2), 0.9)
            s.note('bass', on, min(ln, 2) - .1, r, 70)
            if ln == 4:
                s.note('bass', on + 2, 1.9, r + 7, 56)
    vinyl(s, 16)
    s.p['tracks'][-1]['mix']['level_dbfs'] = -48
    s.save('intro')


# ---------------------------------------------------------------- PRZEPROWADZKA (cutscenka): E-dur, 145 BPM, 40 taktów (~66 s)
def moving():
    """Wzorzec autora (moving_out.mp3): radosne ukulele / funk, pizzicato, marimba, pozytywka, ~145 BPM, E-dur.
    Tu wszystko w stylu pętli gry: sample SNES, miękkie bębny 12-bit, lekki swing, taśma i winyl."""
    A = [[(0, 'E6')], [(0, 'C#m7')], [(0, 'A6')], [(0, 'B7sus4'), (2, 'B7')],
         [(0, 'E6')], [(0, 'G#m7')], [(0, 'A6'), (2, 'F#m7')], [(0, 'B7')]]
    B = [[(0, 'A6')], [(0, 'G#m7')], [(0, 'F#m7')], [(0, 'B7')],
         [(0, 'A6')], [(0, 'G#m7'), (2, 'C#m7')], [(0, 'F#m7')], [(0, 'B7sus4'), (2, 'B7')]]
    C = [[(0, 'C#m7')], [(0, 'G#m7')], [(0, 'A6')], [(0, 'E6/G#')],
         [(0, 'F#m7')], [(0, 'G#m7')], [(0, 'F#m7')], [(0, 'B7')]]
    prog = A + B + A + C + A
    sec = [{'id': 'a', 'start_bar': 0, 'bars': 8, 'intent': 'packing up: marimba theme over strummed nylon (ukulele role)'},
           {'id': 'b', 'start_bar': 8, 'bars': 8, 'intent': 'pizzicato answer, IV-iii-ii-V, drums tighten'},
           {'id': 'a2', 'start_bar': 16, 'bars': 8, 'intent': 'theme back, glockenspiel doubles, handclaps: the truck rolls'},
           {'id': 'c', 'start_bar': 24, 'bars': 8, 'intent': 'bridge: music box over half-time drums, a warm look back'},
           {'id': 'a3', 'start_bar': 32, 'bars': 8, 'intent': 'full theme with pizzicato counterline, turnaround to the loop'}]
    s = Song('Star Watcher - Przeprowadzka', 145, 40, sec,
             'Moving-day cutscene bed (text dialogue, no voices). Inspired by the user reference only in tempo, key, '
             'mood and instrument roles (cheerful ukulele/funk, pizzicato, marimba, music box); SNES-style samples '
             'and lo-fi glue like the other game loops.')
    s.chords(prog)
    SW = {'ratio': 0.58, 'unit': 0.5}
    s.track('marimba', 'melody', {'level_dbfs': -19, 'highpass': 200, 'lowpass': 8000, 'reverb_db': -15, 'pan': -0.1,
                                  'delay': {'beats': 0.75, 'feedback': 0.22, 'send_db': -20, 'lowpass': 3500, 'ping_pong': True}},
            program=12)
    s.track('pizz', 'melody', {'level_dbfs': -21, 'highpass': 150, 'lowpass': 7000, 'reverb_db': -12, 'pan': 0.3}, program=45)
    s.track('glock', 'texture', {'level_dbfs': -28, 'highpass': 400, 'lowpass': 9000, 'reverb_db': -12, 'pan': 0.35}, program=9)
    s.track('box', 'melody', {'level_dbfs': -21, 'highpass': 300, 'lowpass': 6000, 'reverb_db': -10, 'pan': -0.2}, program=10)
    s.track('uke', 'harmony', {'level_dbfs': -25.5, 'highpass': 180, 'lowpass': 7000, 'reverb_db': -18, 'pan': 0.4,
                               'eq': [[300, -3]]}, program=24)
    s.track('keys', 'harmony', {'level_dbfs': -30, 'highpass': 100, 'lowpass': 5000, 'reverb_db': -16, 'pan': -0.35,
                                'eq': [[250, -3]], 'effects': [{'type': 'chorus', 'depth': 0.5}]}, program=4)
    s.track('bass', 'bass', {'level_dbfs': -23, 'highpass': 35, 'lowpass': 2000}, program=33)  # analyze r1: bas -2 dB pod tematem
    s.track('sub', 'bass', {'level_dbfs': -26,  # r1: dół 11,7 dB pod lofi
                             'highpass': 25, 'lowpass': 300}, engine='synth', synth={'preset': 'sub_bass'})
    s.track('drums', 'drums', {'level_dbfs': -17, 'highpass': 40, 'lowpass': 13000, 'reverb_db': -20,
                               'effects': [{'type': 'bitcrush', 'bits': 12, 'downsample': 2, 'mix': 0.5}], 'saturate': 0.2},
            drums=True)
    for k in ('uke', 'bass', 'drums', 'marimba', 'pizz', 'glock'):
        s.t[k]['performance']['swing'] = SW
    theme = [
        [(0, .5, 71), (.5, .5, 73), (1, .5, 76), (1.5, 1, 75), (2.5, .5, 73), (3, 1, 71)],
        [(0, .5, 68), (.5, .5, 71), (1, 1, 73), (2, .5, 76), (2.5, 1.5, 73)],
        [(0, .5, 69), (.5, .5, 71), (1, .5, 73), (1.5, .5, 76), (2, 1, 80), (3, .5, 78), (3.5, .5, 76)],
        [(0, 1.5, 78), (1.5, .5, 76), (2, 1, 75), (3, 1, 71)],
        [(0, .5, 71), (.5, .5, 73), (1, .5, 76), (1.5, 1, 78), (2.5, .5, 76), (3, 1, 80)],
        [(0, .75, 78), (.75, .75, 75), (1.5, .5, 71), (2, 2, 75)],
        [(0, .5, 73), (.5, .5, 76), (1, 1, 81), (2, .5, 78), (2.5, .5, 76), (3, 1, 73)],
        [(0, 2, 75), (2, .5, 71), (2.5, .5, 73), (3, 1, 75)],
    ]
    answer = [
        [(0, 1, 76), (1, 1, 73), (2, 2, 69)], [(0, 1, 75), (1, 1, 71), (2, 2, 68)],
        [(0, 1, 73), (1, .5, 69), (1.5, .5, 73), (2, 2, 76)], [(0, 1.5, 75), (1.5, .5, 73), (2, 2, 71)],
        [(0, 1, 76), (1, 1, 80), (2, 2, 81)], [(0, 1, 80), (1, 1, 78), (2, 2, 76)],
        [(0, 1, 78), (1, 1, 76), (2, 1, 73), (3, 1, 69)], [(0, 2, 71), (2, 1, 75), (3, 1, 78)],
    ]
    bridge = [
        [(0, 2, 76), (2, 1, 73), (3, 1, 71)], [(0, 2, 71), (2, 2, 75)], [(0, 1, 73), (1, 1, 76), (2, 2, 80)],
        [(0, 3, 78), (3, 1, 76)], [(0, 2, 73), (2, 1, 76), (3, 1, 78)], [(0, 3, 80), (3, 1, 78)],
        [(0, 1, 81), (1, 1, 80), (2, 1, 78), (3, 1, 76)], [(0, 2, 75), (2, 2, 71)],
    ]
    counter = [  # A3: pizzicato odpowiada w przerwach tematu, oktawę niżej
        [(2.5, .5, 64), (3, .5, 66), (3.5, .5, 68)], [(2.5, .5, 64), (3, 1, 61)], [(2.5, .5, 64), (3, 1, 66)],
        [(2, .5, 63), (2.5, .5, 66), (3, 1, 69)], [(2.5, .5, 68), (3, .5, 66), (3.5, .5, 64)], [(2.5, .5, 63), (3, 1, 66)],
        [(3, .5, 64), (3.5, .5, 66)], [(2, .5, 63), (2.5, .5, 66), (3, .5, 69), (3.5, .5, 71)],
    ]
    for i in range(8):
        s.line('marimba', i, theme[i], 80)
        s.line('pizz', 8 + i, answer[i], 78)
        s.line('marimba', 16 + i, theme[i], 84)
        s.line('glock', 16 + i, [(b, min(d, 1.0), p + 12) for b, d, p in theme[i]], 58)
        s.line('box', 24 + i, [(b, d, p + 12) for b, d, p in bridge[i]], 70)
        s.line('marimba', 32 + i, theme[i], 86)
        s.line('glock', 32 + i, [(b, min(d, 1.0), p + 12) for b, d, p in theme[i]], 54)
        s.line('pizz', 32 + i, counter[i], 70)
    for bar, items in enumerate(prog):
        bridge_bar = 24 <= bar < 32
        for b, ln, sym in spans(items):
            v = VOICE[sym]
            on = bar * 4 + b
            for p in v:
                s.note('keys', on, ln - .1, p, 52 if bridge_bar else 46)
            # ukulele (gitara nylonowa): bicie D . D U . U D U, w moście tylko na raz i trzy
            hits = [(0, 84), (2, 76)] if bridge_bar else [(0, 82), (1, 70), (1.5, 58), (2.5, 62), (3, 74), (3.5, 58)]
            for hb, vel in hits:
                if b <= hb < b + ln:
                    for k, p in enumerate(sorted(v)):
                        s.note('uke', bar * 4 + hb + k * .02, .4, p + 12 if p < 60 else p, vel - 4 * k, 0.8)
            r = root_of(sym)
            pattern = [(0, 0, 86), (1.5, 12, 66), (2, 7, 78), (3, 0, 72), (3.5, 10 if 'B7' in sym else 12, 60)]
            for pb, iv, vel in pattern:  # podskakujący bas: pryma, oktawa, kwinta, przejście
                if b <= pb < b + ln and (not bridge_bar or pb in (0, 2)):
                    s.note('bass', bar * 4 + pb, .45, r + iv - (12 if r + iv > 52 else 0), vel, 0.85)
            s.note('sub', on, ln - .05, r - 12 if r > 40 else r, 88)
    for bar in range(40):
        o = bar * 4
        sec_id = 'a' if bar < 8 else 'b' if bar < 16 else 'a2' if bar < 24 else 'c' if bar < 32 else 'a3'
        if sec_id == 'c':  # pół-tempo: stopa na raz, werbel na trzy
            s.note('drums', o, .2, 36, 86)
            s.note('drums', o + 2, .2, 38, 74)
            for k in range(4):
                s.note('drums', o + k, .08, 42, 46)
        else:
            for b, vel in ((0, 94), (1.5, 62), (2.5, 84)):
                s.note('drums', o + b, .2, 36, vel)
            for b in (1, 3):
                s.note('drums', o + b, .2, 37 if sec_id == 'a' else 38, 78 if sec_id == 'a' else 86)
                if sec_id in ('a2', 'a3'):
                    s.note('drums', o + b, .15, 39, 70)
            for k in range(8):
                s.note('drums', o + k * .5, .08, 42, 60 if k % 2 == 0 else 42)
            if sec_id == 'a3':
                for k in range(8):
                    s.note('drums', o + k * .5 + .25, .08, 54, 40)
        if bar % 8 == 7:
            for b, p in ((3, 47), (3.25, 45), (3.5, 43), (3.75, 41)):
                s.note('drums', o + b, .2, p, 74)
    vinyl(s, 40)
    s.p['tracks'][-1]['mix']['level_dbfs'] = -48
    s.save('moving')


if __name__ == '__main__':
    day()
    night()
    menu()
    intro()
    moving()
    print('ok')
