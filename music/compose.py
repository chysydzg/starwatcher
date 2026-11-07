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
    'D69': [54, 59, 64, 69], 'A9': [55, 59, 61, 64], 'F#m7b5': [52, 57, 60],
}
ROOT = {'D': 38, 'E': 40, 'F#': 42, 'G': 43, 'A': 45, 'B': 35, 'C': 36}


def root_of(sym):
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


if __name__ == '__main__':
    day()
    night()
    print('ok')
