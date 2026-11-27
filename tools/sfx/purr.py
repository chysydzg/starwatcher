# Mruczenie kota (Józek po pogłaskaniu): ciąg krótkich impulsów szumu ~25 Hz (wydech) i ~22 Hz (wdech),
# każdy impuls to stłumiony „klap” krtani przefiltrowany dolnoprzepustowo, oddech moduluje głośność.
# earshot: 'a cat purring contentedly' plausible z +2.9, AudioSet Purr 0.44 (wersja z miękkimi impulsami i oddechem wypadła gorzej: z +2.6, bez Purr).
import numpy as np, scipy.signal as ss, scipy.io.wavfile as wf, sys
sr = 48000
rng = np.random.default_rng(7)
out = np.zeros(int(sr * 2.6))
t0 = 0.05
for phase, (dur, rate, gain) in enumerate([(1.05, 25.5, 1.0), (0.85, 22.0, 0.6), (1.0, 25.0, 0.95)][:2] + [(0.0, 0, 0)]):
    if dur == 0: break
    n = int(dur * rate)
    for k in range(n):
        t = t0 + k / rate + rng.normal(0, 0.0012)
        env = np.sin(np.pi * (k + 0.5) / n) ** 0.7 * gain
        L = int(0.03 * sr)
        burst = rng.normal(0, 1, L) * np.exp(-np.arange(L) / (0.006 * sr))
        i = int(t * sr)
        out[i:i + L] += burst[:len(out) - i] * env
    t0 += dur + 0.12
b, a = ss.butter(4, 380 / (sr / 2), "low"); out = ss.lfilter(b, a, out)
b, a = ss.butter(2, 40 / (sr / 2), "high"); out = ss.lfilter(b, a, out)
bp = ss.lfilter(*ss.butter(2, [600 / (sr / 2), 1400 / (sr / 2)], "band"), rng.normal(0, 1, len(out))) * 0.015  # lekki „chrapliwy” szum nosa
out = out + bp * (np.abs(out) > 0.02 * np.abs(out).max())
fade = np.ones(len(out)); fade[-int(0.08 * sr):] = np.linspace(1, 0, int(0.08 * sr)); out *= fade
out = out / np.abs(out).max() * 10 ** (-3 / 20)
wf.write(sys.argv[1], sr, (out * 32767).astype(np.int16))
print("ok", len(out) / sr)
