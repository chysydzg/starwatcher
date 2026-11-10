"""Builds game/sfx/*.ogg: the sound design from GDD chapter 22, for what the game has in Stage 1.

One-shots come from earshot's shipped bank (sounds made in code, checked by measurement); the rest is written here
with earshot.forge.dsp (modal resonators, filtered noise, rooms). No recorded audio anywhere.
Run: python tools/sfx/make_sfx.py <earshot src folder> [names...]   (needs numpy, scipy, ffmpeg on PATH)
Names limit which files are written (e.g. `clank engine_start`); without them every file is rebuilt.
"""
import os, subprocess, sys, tempfile, wave

import numpy as np

sys.path.insert(0, sys.argv[1] if len(sys.argv) > 1 else os.environ.get('EARSHOT_SRC', ''))
from earshot.forge import bank, dsp  # noqa: E402

SR = dsp.SR
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'game', 'sfx')


ONLY = set(sys.argv[2:])


def save(name, y, peak_db=-3.0, loop=False):
    if ONLY and name not in ONLY:
        return
    y = np.asarray(y, np.float64)
    if y.ndim == 1:
        y = np.stack([y, y], 1)
    y = y / (np.abs(y).max() + 1e-12) * 10 ** (peak_db / 20)
    if not loop:
        y = dsp.fade(y, 0.0005, 0.01)
    pcm = (np.clip(y, -1, 1) * 32767).astype('<i2')
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        w = os.path.join(tmp, 'x.wav')
        with wave.open(w, 'wb') as f:
            f.setnchannels(2), f.setsampwidth(2), f.setframerate(SR)
            f.writeframes(pcm.tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'libvorbis', '-q:a', '5',
                        os.path.join(OUT, name + '.ogg')], check=True)
    assert np.isfinite(y).all() and len(y) > 0, name
    print(f'{name}: {len(y) / SR:.2f} s{" loop" if loop else ""}')


def b(sound, **kw):
    y, _ = bank.render(sound, seed=kw.pop('seed', 1), **kw)
    return y


def seamless(y, xf=1.0):
    """loop: the last `xf` seconds are crossfaded into the start, so the end runs straight into the beginning"""
    n = int(xf * SR)
    head, body, tail = y[:n], y[n:-n] if n else y, y[-n:]
    k = np.sqrt(np.linspace(0, 1, n))[:, None] if y.ndim == 2 else np.sqrt(np.linspace(0, 1, n))
    return np.concatenate([head * k + tail * k[::-1], body])


def drops(seconds, r, rate, f_lo, f_hi, decay, gain_db=(-30, -6)):
    """raindrops / splashes / crackles: short noise bursts band-passed at random centres (no ringing: rings read
    as bubbles under water)"""
    y = np.zeros(dsp.n_of(seconds))
    for t in np.sort(r.uniform(0, seconds, int(rate * seconds))):
        burst = dsp.noise(decay * 5, r) * dsp.env_exp(decay * 5, decay, 0.0003)
        d = dsp.svf(burst, r.uniform(f_lo, f_hi), q=0.8, mode='band')
        dsp.place(y, d * 10 ** (r.uniform(*gain_db) / 20), t)
    return y


def am(seconds, r, rate, depth):
    """slow random amplitude movement (wind, waves)"""
    w = dsp.wander(seconds, r, rate=rate, octaves=2)
    w = (w - w.min()) / (np.ptp(w) + 1e-9)
    return 1 - depth + depth * w


# ------------------------------------------------------------------ telescope and table
def lens_click():  # sweet spot: a light lens snapping into its seat, a small metal detent under it
    return dsp.stack([(b('click/snap'), 0, 0), (b('hover_tick/detent'), 0.003, -8)], peak_db=-1)


def pencil(r, seconds=0.42):  # graphite scribbling: back-and-forth strokes, each a rough friction burst
    t = dsp.t_of(dsp.n_of(seconds))
    n = dsp.svf(dsp.noise(seconds, r, 'white'), 2600, q=1.6, mode='band')
    strokes = np.abs(np.sin(2 * np.pi * 7 * t)) ** 1.5  # the hand going back and forth
    grit = np.repeat(r.uniform(0.2, 1.0, len(t) // 60 + 1), 60)[:len(t)]  # paper grain under the tip
    e = dsp.env_curve([(0, 0), (0.02, 1), (seconds - 0.08, 0.9), (seconds, 0)], seconds)
    return dsp.room(dsp.butter(n * strokes * grit * e, 'low', 6000), r, rt60=0.12, wet=0.05)


def paper(r, seconds=0.8):  # unwrapping a parcel: dense crinkle crackles in two handfuls
    y = drops(seconds, r, 260, 1500, 9000, 0.0012, (-26, -4)) * dsp.env_curve(
        [(0, 0), (0.05, 1), (0.3, 0.4), (0.42, 1), (0.7, 0.5), (seconds, 0)], seconds)
    return dsp.room(y, r, rt60=0.15, wet=0.06)


def chord(notes, sound='mallet/celesta', step=0.0):
    return dsp.stack([(b(sound, pitch=p, seed=i + 1), i * step, -2 * i) for i, p in enumerate(notes)], peak_db=-1)


def space_hum(r, seconds=24.0):  # "szum kosmosu": dark rumbling noise and slow detuned drones, nothing insect-high
    hum = dsp.butter(dsp.noise(seconds, r, 'brown'), 'low', 500) * am(seconds, r, 0.06, 0.5)
    t = dsp.t_of(dsp.n_of(seconds))
    drone = sum(np.sin(2 * np.pi * f * t + 0.3 * np.sin(2 * np.pi * 0.05 * t + k)) * a
                for k, (f, a) in enumerate([(55, 1), (82.6, 0.6), (110.3, 0.35), (164.7, 0.2)]))
    y = 0.6 * hum / np.abs(hum).max() + 0.3 * drone / np.abs(drone).max()
    return seamless(dsp.stereo(y, r, width=0.6))


def lens_slide(r, seconds=4.0):  # moving the tube: soft mechanical slide, brushed metal
    n = dsp.svf(dsp.noise(seconds, r, 'pink'), 1400, q=1.5, mode='band')
    rumble = dsp.butter(dsp.noise(seconds, r, 'brown'), 'low', 180)
    return seamless(dsp.stereo(n * am(seconds, r, 3, 0.4) + 0.5 * rumble / np.abs(rumble).max(), r, 0.2))


# ------------------------------------------------------------------ computer (AstroOS on the CRT)
def crt_on(r):  # relay click and soft thump, the degauss coil's decaying mains buzz, static, the tube's whine
    t = dsp.t_of(dsp.n_of(1.6))
    thump = np.sin(2 * np.pi * 60 * t) * np.exp(-t / 0.05) * 0.6
    saw = 2 * (t * 100 % 1) - 1  # rectified mains: rich 100 Hz buzz
    buzz = dsp.butter(saw, 'low', 1800) * np.exp(-t / 0.45) * (1 + 0.3 * np.sin(2 * np.pi * 7 * t))
    static = dsp.butter(dsp.noise(1.6, r), 'high', 2000) * np.exp(-t / 0.15) * 0.15
    whine = np.sin(2 * np.pi * 15734 * t) * np.clip((t - 0.2) / 0.5, 0, 1) * 0.04
    y = thump + 0.7 * buzz + static + whine
    dsp.place(y, b('click/snap').mean(1) * 0.6, 0.0)
    return dsp.room(y, r, rt60=0.25, wet=0.12)


def crt_hum(r, seconds=10.0):  # idle tower: fan, mains hum, faint tube whine, a few HDD seeks
    t = dsp.t_of(dsp.n_of(seconds))
    fan = dsp.butter(dsp.noise(seconds, r, 'pink'), 'low', 1200) * 0.5
    hum = 0.25 * np.sin(2 * np.pi * 50 * t) + 0.1 * np.sin(2 * np.pi * 100 * t)
    whine = 0.012 * np.sin(2 * np.pi * 15734 * t)
    y = fan / np.abs(fan).max() + hum + whine
    for s in r.uniform(1, seconds - 1, 3):  # HDD: quiet rhythmic ticks of the head, under the fan
        for k in range(r.integers(3, 6)):
            dsp.place(y, b('hover_tick/mid', seed=k + 1).mean(1) * 0.08, s + k * 0.05)
    return seamless(y, 0.5)


def floppy(r):  # saving to a 3.5" disk: the drive's clack, a short motor whir, the head stepping in quick ticks
    y = np.zeros(dsp.n_of(1.1))
    dsp.place(y, b('knock/plastic').mean(1) * 0.8, 0.0)
    t = dsp.t_of(dsp.n_of(0.7))
    whir = (np.sin(2 * np.pi * 300 * t) * 0.3 + dsp.butter(dsp.noise(0.7, r), 'low', 1500)) * np.sin(np.pi * t / 0.7)
    dsp.place(y, whir * 0.15, 0.12)
    for k in range(10):  # rhythmic ticking of the head (reads like the GDD's "stukanie głowicy")
        dsp.place(y, b('hover_tick/mid', seed=k + 1).mean(1) * 0.5, 0.2 + k * 0.05 + (0.15 if k > 5 else 0))
    return dsp.room(y, r, rt60=0.2, wet=0.08)


def step(r, i):  # króliczek na drewnianej podłodze: miękka łapka (futro tłumi), głuchy stuk deski, bez dźwięczenia
    def pad(gain):  # jedno dotknięcie łapy: krótki, ciemny szum zamiast rezonansu (rezonans brzmiał jak kalimba)
        n = dsp.noise(0.08, r, 'pink') * dsp.env_exp(0.08, 0.018, 0.003)
        knock = dsp.svf(dsp.noise(0.03, r), r.uniform(1100, 1500), q=1.0, mode='band') * dsp.env_exp(0.03, 0.005, 0.001)
        out = np.zeros(dsp.n_of(0.08))
        out += dsp.butter(n, 'low', 650)
        dsp.place(out, knock * 0.12, 0.0)
        return out * gain
    y = np.zeros(dsp.n_of(0.25))
    dsp.place(y, pad(1.0), 0.0)
    dsp.place(y, pad(0.45), r.uniform(0.02, 0.035))  # palce łapy chwilę po pięcie
    return dsp.room(y, r, rt60=0.2, wet=0.08)


def door_knock(r):  # kurier puka do drzwi: trzy stuknięcia knykciem w drewniane drzwi (ciemniej niż klocek, z ramą pod spodem)
    from earshot.forge.recipes import knock
    p = dict(knock.FAMILY['knock'][0])
    p.update(f1=230.0, body=-4.0, body_f=90.0, body_ms=18.0, room=0.25, rt=0.35)
    y = np.zeros((dsp.n_of(0.8), 2))
    for i, (t, g) in enumerate([(0.0, 1.0), (0.17, 0.8), (0.34, 0.9)]):
        dsp.place(y, knock.render(p, dsp.rng(10 + i)) * g, t)
    return y


def scan_hum(seconds=2.0):  # wykrywacz w okularze: miękkie buczenie pulsujące 3 razy/s (pitch_scale w grze przyspiesza puls)
    t = dsp.t_of(dsp.n_of(seconds))
    tone = np.sin(2 * np.pi * 140 * t) + 0.35 * np.sin(2 * np.pi * 280 * t) + 0.08 * np.sin(2 * np.pi * 420 * t)
    pulse = 0.35 + 0.65 * np.sin(np.pi * 3 * t) ** 2  # całkowita liczba pulsów i okresów w pętli: brak szwu
    return tone * pulse


def detect(r):  # „pyk-pyk”: dwa krótkie, ciepłe bipy sonaru – coś wykryte
    t = dsp.t_of(dsp.n_of(0.07))
    blip = np.sin(2 * np.pi * 1760 * t) * np.exp(-t / 0.018) + 0.3 * np.sin(2 * np.pi * 3520 * t) * np.exp(-t / 0.008)
    y = np.zeros(dsp.n_of(0.3))
    dsp.place(y, blip, 0.0)
    dsp.place(y, blip * 0.8, 0.09)
    return dsp.room(y, r, rt60=0.3, wet=0.15)


def key(i):  # Cherry MX Brown / buckling spring: soft deep clicks, takes alternate
    return b('fit/key/thock' if i % 2 == 0 else 'fit/key/medium', seed=i + 1)


def modem(r):  # short handshake when sending a report: dial tone, three DTMF digits, answer tone, chirp, a burst of data
    parts, t = [], lambda s: dsp.t_of(dsp.n_of(s))
    tt = t(0.25)
    parts.append(0.4 * (np.sin(2 * np.pi * 350 * tt) + np.sin(2 * np.pi * 440 * tt)))
    dtmf = {'1': (697, 1209), '4': (770, 1209), '8': (852, 1336)}
    for d in '481':
        tt = t(0.07)
        lo, hi = dtmf[d]
        parts += [0.4 * (np.sin(2 * np.pi * lo * tt) + np.sin(2 * np.pi * hi * tt)), np.zeros(dsp.n_of(0.04))]
    tt = t(0.35)  # answer tone with a phase reversal
    parts.append(0.5 * np.sin(2 * np.pi * 2100 * tt + np.pi * (np.floor(tt / 0.18) % 2)))
    tt = t(0.25)
    parts.append(0.35 * (np.sin(2 * np.pi * (980 + 400 * np.sin(2 * np.pi * 7 * tt)) * tt) + np.sin(2 * np.pi * 1650 * tt)))
    data = dsp.svf(dsp.noise(0.45, r), 1800, q=0.8, mode='band')
    data *= (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 9 * t(0.45)))) * np.linspace(1, 0, dsp.n_of(0.45)) ** 0.5
    parts.append(0.6 * data / np.abs(data).max())
    y = np.concatenate(parts)
    y = dsp.butter(dsp.butter(y, 'high', 300), 'low', 3400)  # telephone line
    return dsp.room(np.tanh(1.5 * y), r, rt60=0.2, wet=0.12)


def thunder(r):  # grzmot w oddali: narasta i toczy się kilka razy, długi ogon
    dur = 6.0
    t = dsp.t_of(dsp.n_of(dur))
    rolls = sum(np.exp(-((t - c) / w) ** 2) * g for c, w, g in [(0.6, 0.5, 1.0), (1.5, 0.6, 0.85), (2.6, 0.8, 0.7), (3.8, 1.0, 0.45)])
    rumble = dsp.butter(dsp.noise(dur, r, 'brown'), 'low', 120)
    rumble = rumble / np.abs(rumble).max() * rolls * np.clip(t / 0.4, 0, 1)
    body = dsp.butter(dsp.noise(dur, r, 'pink'), 'low', 600)
    body = body / np.abs(body).max() * rolls * 0.35 * np.exp(-t / 2.0)
    y = rumble * 1.4 + body
    return dsp.room(y, r, rt60=2.2, wet=0.35)


# ------------------------------------------------------------------ weather and nature
def rain(r, room, seconds=20.0):
    if room:  # muffled drops on the window and the roof
        bed = dsp.butter(dsp.noise(seconds, r, 'pink'), 'low', 1500) * am(seconds, r, 0.15, 0.3)
        y = bed / np.abs(bed).max() * 0.5 + drops(seconds, r, 60, 300, 900, 0.012, (-34, -14))
        y = dsp.butter(y, 'low', 2500)
    else:  # crisp rain on the lake and pings on the metal railing
        bed = dsp.butter(dsp.noise(seconds, r, 'white'), 'high', 900) * am(seconds, r, 0.2, 0.25)
        y = bed / np.abs(bed).max() * 0.35 + drops(seconds, r, 220, 1500, 5000, 0.004, (-36, -10))
        y += drops(seconds, r, 6, 2500, 4200, 0.06, (-30, -18))  # railing
    return seamless(dsp.stereo(y, r, width=0.8))


def parasol(r, kind='a', seconds=20.0):  # deszcz na rozpiętym parasolu: gęste stuknięcia o napięty materiał, krople ściekające z brzegu
    lo, hi = (700, 2000) if kind == 'a' else (400, 1200)
    y = drops(seconds, r, 140, lo, hi, 0.006, (-34, -10))  # krople o materiał: krótkie, suche, bez dzwonienia
    for t in np.sort(r.uniform(0, seconds, int(90 * seconds))):  # membrana: miękkie "tup" pod każdą kroplą
        th = dsp.svf(dsp.noise(0.04, r) * dsp.env_exp(0.04, 0.008, 0.0005), r.uniform(160, 260), q=1.2, mode='band')
        dsp.place(y, th * 10 ** (r.uniform(-30, -16 if kind == 'b' else -22) / 20), t)
    y += drops(seconds, r, 3, 500, 1100, 0.03, (-26, -16))  # ciężkie krople spływające z brzegu na deski
    bed = dsp.butter(dsp.noise(seconds, r, 'pink'), 'band', (500, 4000)) * am(seconds, r, 0.2, 0.25)
    y += bed / np.abs(bed).max() * 0.12
    return seamless(dsp.stereo(y, r, width=0.6))


def lake(r, seconds=30.0):  # water lapping the shore, wind in the reeds
    swell = dsp.butter(dsp.noise(seconds, r, 'brown'), 'low', 400)
    t = dsp.t_of(dsp.n_of(seconds))
    waves = 0.6 + 0.4 * np.sin(2 * np.pi * t / 3.0) ** 2
    lap = swell / np.abs(swell).max() * waves
    wind = dsp.air(seconds, r, center=700, flutter=0.4, rate=0.5) * 0.3 * am(seconds, r, 0.07, 0.8)
    return seamless(dsp.stereo(dsp.butter(lap, 'low', 1600) + wind, r, width=0.9), 2.0)


def owl(r):  # tawny owl far over the lake: "hoo ... hu-hoooo", breathy, with a little wavering
    def hoot(seconds, f0, f1):
        t = dsp.t_of(dsp.n_of(seconds))
        f = np.linspace(f0, f1, len(t)) * (1 + 0.012 * np.sin(2 * np.pi * 9 * t))
        ph = 2 * np.pi * np.cumsum(f) / SR
        tone = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
        breath = dsp.svf(dsp.noise(seconds, r), f0 * 1.5, q=2, mode='band') * 0.35
        return (tone + breath) * np.sin(np.pi * t / seconds) ** 1.5
    y = np.zeros(dsp.n_of(2.4))
    dsp.place(y, hoot(0.5, 420, 390), 0.0)
    dsp.place(y, hoot(0.18, 400, 400), 1.05)
    dsp.place(y, hoot(0.9, 430, 380), 1.3)
    return dsp.room(dsp.butter(y, 'low', 1500), r, rt60=1.6, size=0.9, wet=0.5)


def crickets(r, seconds=12.0):  # summer: pulse trains on a 4.6 kHz carrier, a few insects at different rates
    y = np.zeros(dsp.n_of(seconds))
    t = dsp.t_of(dsp.n_of(0.05))
    for k in range(4):
        f, rate, g = r.uniform(4300, 5000), r.uniform(1.4, 2.6), r.uniform(0.4, 1)
        for s in np.arange(r.uniform(0, 1), seconds, 1 / rate):
            for p in range(3):
                dsp.place(y, g * np.sin(2 * np.pi * f * t) * np.sin(np.pi * t / 0.05) ** 2 * 0.3, s + p * 0.06)
    return seamless(dsp.stereo(dsp.room(y, r, rt60=0.8, wet=0.35), r, width=0.9), 0.5)


def frogs(r, seconds=12.0):  # spring: a chorus of peepers (short rising whistles) and a few deep croaks
    y = np.zeros(dsp.n_of(seconds))
    tp = dsp.t_of(dsp.n_of(0.12))
    for k in range(6):
        f0, rate, g = r.uniform(2600, 3200), r.uniform(0.8, 1.6), r.uniform(0.3, 1)
        ph = 2 * np.pi * np.cumsum(np.linspace(f0, f0 * 1.12, len(tp))) / SR
        peep = np.sin(ph) * np.sin(np.pi * tp / 0.12) ** 2
        for s in np.arange(r.uniform(0, 1), seconds, 1 / rate):
            dsp.place(y, peep * g * 0.3, s + r.uniform(-0.05, 0.05))
    tc = dsp.t_of(dsp.n_of(0.35))
    for s in np.sort(r.uniform(0, seconds - 0.5, 7)):
        f = r.uniform(180, 260)
        pulses = np.sin(2 * np.pi * 12 * tc).clip(0) ** 2
        c = dsp.svf(np.tanh(2 * np.sin(2 * np.pi * f * tc)), 650, q=2) * pulses * np.sin(np.pi * tc / 0.35)
        dsp.place(y, c * r.uniform(0.3, 0.7), s)
    return seamless(dsp.stereo(dsp.room(y, r, rt60=1.0, wet=0.4), r, width=0.9), 0.5)


def leaves(r, seconds=12.0):  # autumn: dry leaves skittering in separate gusts, crisp crackles, quiet between
    y = np.zeros(dsp.n_of(seconds))
    for s in np.sort(r.uniform(0, seconds - 1.2, 6)):
        d = r.uniform(0.4, 1.1)
        gust = dsp.svf(dsp.noise(d, r), 4500, q=0.6, mode='band') * 0.15 + drops(d, r, 120, 2000, 8000, 0.0015, (-24, -6))
        dsp.place(y, gust * dsp.env_curve([(0, 0), (d * 0.3, 1), (d, 0)], d), s)
    return seamless(dsp.stereo(y, r, width=0.9), 1.0)


def frost(r, seconds=12.0):  # winter: almost silence, a cold breeze and a rare squeak of frost (stick-slip)
    y = dsp.air(seconds, r, center=400, flutter=0.2, rate=0.3) * 0.15
    for s in r.uniform(1, seconds - 1, 3):
        d = r.uniform(0.15, 0.3)
        t = dsp.t_of(dsp.n_of(d))
        slips = (np.sin(2 * np.pi * np.cumsum(np.linspace(380, 520, len(t))) / SR) > 0.7).astype(float)
        dsp.place(y, dsp.svf(slips - slips.mean(), 1400, q=1.2) * np.sin(np.pi * t / d) * 0.25, s)
    return seamless(dsp.stereo(y, r, width=0.8), 1.0)


# ------------------------------------------------------------------ intro: wywrotka zabiera teleskop
def clank(r, kind='b'):  # ciężki stalowy tubus spada na stalową skrzynię wywrotki: pełny metal o metal, głuche uderzenie
    # bez długiego dzwonienia (to brzmiało jak rura): gęste, krótko gasnące mody masywnej stali + dudnienie blachy skrzyni
    def hit(g, seed, size=1.0):
        q = dsp.rng(seed)
        t = dsp.t_of(dsp.n_of(1.2))
        modes = sum(q.uniform(0.3, 1.0) * np.sin(2 * np.pi * f * t + q.uniform(0, 6.28)) * np.exp(-t / (0.02 + 18.0 / f))
                    for f in np.sort(q.uniform(180, 3200, 36)) / size)
        boom = np.sin(2 * np.pi * 86 / size * t) * np.exp(-t / 0.22) * 1.4                    # skrzynia: niska blacha
        thump = dsp.butter(dsp.noise(1.2, q, 'pink'), 'low', 260) * np.exp(-t / 0.07) * 2.2
        crack = dsp.svf(dsp.noise(1.2, q), 2600, q=0.7, mode='band') * np.exp(-t / 0.012) * 0.8
        return (modes * 0.35 + boom + thump + crack) * g
    y = np.zeros(dsp.n_of(1.6))
    dsp.place(y, hit(1.0, 31), 0.0)
    if kind == 'b':
        dsp.place(y, hit(0.3, 32, 1.1), 0.09)                                                    # krótkie odbicie
    y = dsp.butter(y, 'low', 5000)                                                               # z daleka (balkon)
    return dsp.room(y, r, rt60=0.7, wet=0.18)


def diesel(rate, r, clatter=0.35):
    """silnik wysokoprężny: zapłony w rytmie `rate` (Hz na próbkę) – niskie pchnięcie wydechu, szum, klekot wtrysku"""
    n = len(rate)
    phase = np.cumsum(rate) / SR
    fires = np.nonzero(np.diff(np.floor(phase)) > 0)[0]
    shots = []
    for k in range(4):
        q = dsp.rng(50 + k)
        t = dsp.t_of(dsp.n_of(0.09))
        thump = np.sin(2 * np.pi * q.uniform(48, 62) * t) * np.exp(-t / 0.035)
        puff = dsp.butter(dsp.noise(0.09, q, 'pink'), 'low', 420) * np.exp(-t / 0.025) * 0.8
        tick = dsp.svf(dsp.noise(0.09, q), q.uniform(2500, 3600), q=1.2, mode='band') * np.exp(-t / 0.004) * clatter
        shots.append(thump + puff + tick)
    y = np.zeros(n + dsp.n_of(0.1))
    for i in fires:
        dsp.place(y, shots[int(r.uniform(0, 3.999))] * r.uniform(0.8, 1.1), i / SR)
    y = y[:n]
    return y + dsp.butter(dsp.noise(n / SR, r, 'pink'), 'low', 160) * 0.25  # dudnienie rury


def engine_start(r, seconds=1.5):  # rozrusznik obraca wał (ciężkie "czug-czug" sprężania i cichy warkot), diesel łapie
    n = dsp.n_of(seconds)
    t = dsp.t_of(n)
    crank = 0.75
    rate = np.interp(t, [0, crank, crank + 0.25, crank + 0.6, seconds], [5.5, 6.5, 28, 15, 13])
    lit = np.clip((t - crank) / 0.05, 0, 1)
    y = diesel(rate, r, clatter=0.0) * (0.45 + 0.55 * lit)  # przed zapłonem te same pchnięcia, tylko słabsze
    body = dsp.svf(dsp.noise(seconds, r, 'pink'), 240, q=0.7, mode='band')
    y += body * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(rate) / SR) ** 2) * 0.6 * lit
    ph = 2 * np.pi * np.cumsum(110 * (1 - 0.2 * np.clip(np.sin(2 * np.pi * 6.0 * t), 0, 1) ** 3)) / SR
    whirr = dsp.butter(sum(np.sin(k * ph) / k for k in range(1, 6)), "low", 900) * 0.3 * (1 - lit)
    y = (y + whirr) * np.interp(t, [0, seconds - 0.2, seconds], [1, 1, 0])  # przechodzi w truck_drive
    return dsp.room(y, r, rt60=0.5, wet=0.1)


def truck_drive(r, seconds=7.5):  # wywrotka rusza, zmienia bieg, jedzie w prawo i cichnie w oddali
    n = dsp.n_of(seconds)
    t = dsp.t_of(n)
    rate = np.interp(t, [0, 1.5, 1.7, 2.6, seconds], [13, 30, 21, 27, 27]) * (1 + 0.03 * dsp.wander(seconds, r, rate=1.5, octaves=2))
    y = diesel(rate, r, clatter=0.5)
    body = dsp.svf(dsp.noise(seconds, r, 'pink'), 240, q=0.7, mode='band')  # szum silnika pod zapłonami, nie same "tyk-tyk"
    y += body * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(rate) / SR) ** 2) * 0.6
    y += dsp.svf(dsp.noise(seconds, r, 'pink'), 700, q=0.6, mode='band') * 0.12 * np.clip(t / 2.5, 0, 1)  # opony po żwirze
    far = np.clip((t - 2.5) / (seconds - 2.5), 0, 1)
    y = y * (1 - far) + dsp.butter(y, 'low', 450) * far  # w oddali giną wysokie
    y *= np.interp(t, [0, 2.5, seconds - 0.4, seconds], [1, 1, 0.16, 0])
    y = dsp.room(y, r, rt60=0.6, wet=0.1)
    m = y.mean(1) if y.ndim == 2 else y
    m = m[:n] if len(m) >= n else np.pad(m, (0, n - len(m)))
    pan = np.interp(t, [0, 2.5, seconds], [0.0, 0.25, 0.85])  # od środka w prawo, tam gdzie odjeżdża
    a = (pan + 1) * np.pi / 4
    return np.stack([m * np.cos(a), m * np.sin(a)], 1)


# ------------------------------------------------------------------ przeprowadzka: remont obserwatorium
def hammer(r, kind='c'):  # młotek wbija gwóźdź: stalowy obuch o stalowy łebek (jasne, krótkie dzwonienie), pod spodem stuk deski
    from earshot.forge.recipes import knock
    p = dict(knock.FAMILY['knock'][0])
    p.update(f1=360.0, body=-6.0, body_f=140.0, body_ms=10.0, room=0.3, rt=0.4)
    y = np.zeros((dsp.n_of(0.7), 2))
    dsp.place(y, knock.render(p, dsp.rng(71)) * (0.6 if kind == 'c' else 0.45), 0.0)
    if kind == 'e':  # sam stuk w deskę (bez dzwonienia stali)
        return y / max(1e-9, np.abs(y).max())
    t = dsp.t_of(dsp.n_of(0.5))
    q = dsp.rng(72)
    ring = {'c': 0.09, 'd': 0.16, 'f': 0.025}[kind]  # stal o stal: kilka niezharmonizowanych modów, krótko gaśnie
    lo, hi, amp = (1500, 4000, 0.45) if kind == 'f' else (2200, 7000, 1.0)  # f: głuchy, krótki brzęk gwoździa
    tink = sum(q.uniform(0.4, 1.0) * np.sin(2 * np.pi * f * t) * np.exp(-t / ring) for f in q.uniform(lo, hi, 10))
    click = dsp.svf(dsp.noise(0.5, q), 4000, q=0.8, mode='band') * np.exp(-t / 0.003)
    tink = (tink / max(1e-9, np.abs(tink).max()) * amp + click * 0.6) * 1.1
    dsp.place(y, np.stack([tink, tink], 1), 0.0)
    return y


def site_work(r, seconds=12.0, kind='b'):  # plac budowy z daleka: klekoczący agregat, piła/wiertarka (szum, nie ton), czasem stuk
    n = dsp.n_of(seconds)
    t = dsp.t_of(n)
    y = diesel(np.full(n, 28.0) * (1 + 0.03 * dsp.wander(seconds, r, rate=0.7, octaves=2)), r, clatter=0.45)
    y += dsp.svf(dsp.noise(seconds, r, 'pink'), 160, q=0.8, mode='band') * 0.6
    for t0, dur in [(1.2, 1.6), (5.0, 2.2), (8.6, 1.4)]:                       # piła: szum pasmowy z drganiem zębów
        k = (t > t0) & (t < t0 + dur)
        env = np.zeros(n)
        env[k] = np.sin(np.pi * (t[k] - t0) / dur) ** 0.3
        saw = dsp.butter(dsp.noise(seconds, r), 'band', (900, 3200)) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 47 * t)))
        y += saw * env * 0.35
    if kind == 'c':  # daleki stuk młotków w nieregularnym rytmie
        for t0 in np.sort(r.uniform(0, seconds - 0.7, 14)):
            h = hammer(r, 'c')
            dsp.place(y, h.mean(1) * 0.25, t0)
    y = dsp.butter(y, 'low', 5000)
    return seamless(dsp.room(y, r, rt60=0.8, wet=0.2))


# ------------------------------------------------------------------ intro: szpital
def beep(seconds=0.14):  # monitor serca: krótki, czysty pisk ok. 960 Hz z miękkim wejściem
    t = dsp.t_of(dsp.n_of(seconds))
    tone = np.sin(2 * np.pi * 960 * t) + 0.18 * np.sin(2 * np.pi * 1920 * t)
    return tone * np.clip(t / 0.004, 0, 1) * np.clip((seconds - t) / 0.03, 0, 1)


def flatline(seconds=3.6):  # zatrzymanie: ten sam ton, ciągły, gaśnie na końcu
    t = dsp.t_of(dsp.n_of(seconds))
    return beep(seconds) * np.clip((seconds - t) / 0.6, 0, 1)


def main():
    r = dsp.rng(7)
    save('ding', b('mallet/celesta', pitch='G6'))
    save('lens_click', lens_click())
    save('focus_tick', b('hover_tick/detent'), -10)
    save('star_glass', b('pro_hover_tick/glass'), -14)
    save('pencil', pencil(r), -8)
    save('chimes', b('mallet/up4'))
    save('miss', b('tap/finger'), -16)
    save('meteor', b('whoosh_fast/whistle'), -6)
    save('click', b('click/soft'), -8)
    for i in range(3):
        save(f'key{i}', key(i), -8)
    save('crt_on', crt_on(r), -6)
    for i in range(4):
        save(f'step{i}', step(r, i), -10)
    save('scan_hum', scan_hum(), -8, loop=True)
    save('detect', detect(r), -6)
    save('knock', door_knock(r), -4)
    save('floppy', floppy(r), -8)
    save('modem', modem(r), -6)
    save('thunder', thunder(r), -3)
    save('tick', b('fit/tick/domino'), -12)
    save('chord', chord(['C6', 'E6', 'G6', 'C7'], step=0.04))
    save('pop', b('pro_pop/bloop'), -8)
    save('switch', b('fit/snap/switch_flip'), -6)
    save('paper', paper(r), -8)
    save('owl', owl(r), -10)
    save('amb_space', space_hum(r), -12, loop=True)
    save('lens_slide', lens_slide(r), -14, loop=True)
    save('crt_hum', crt_hum(r), -18, loop=True)
    save('rain_room', rain(r, True), -10, loop=True)
    save('rain_balcony', rain(r, False), -8, loop=True)
    save('lake', lake(r), -12, loop=True)
    for name, fn in [('spring', frogs), ('summer', crickets), ('autumn', leaves), ('winter', frost)]:
        save('season_' + name, fn(r), -16, loop=True)
    save('clank', clank(r), -4)
    save('engine_start', engine_start(r), -4)
    save('truck_drive', truck_drive(r), -4)
    save('beep', beep(), -6)
    save('flatline', flatline(), -6)
    save('rain_parasol', parasol(dsp.rng(7)), -8, loop=True)  # ten sam, który earshot sprawdził (z +3.2)
    save('hammer', hammer(dsp.rng(1), 'e'), -3)  # earshot: 'a hammer hitting a nail' 61% vs drewniany klocek, z +2,4
    save('site_work', site_work(dsp.rng(9), kind='c'), -8, loop=True)


if __name__ == '__main__':
    main()
